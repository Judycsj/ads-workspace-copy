#!/usr/bin/env python3
"""Run read-only ClickHouse queries for ads-text2da."""

from __future__ import annotations

import argparse
import base64
import csv
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Mapping, Sequence


DEFAULT_SG_URL = "https://clickhouse-office-only-ytl.data-infra.shopee.io"
DEFAULT_US_VA2_URL = "https://clickhouse-office-only-us-va2.data-infra.shopee.io"
CONFIG_PATH = Path.home() / ".config" / "text2da" / "config.json"
LEGACY_ROI3_CONFIG_PATH = Path.home() / ".config" / "ads-workspace" / "roi3-clickhouse.json"
DATASUITE_CONFIG_DIR = Path.home() / ".config" / "sra" / "data-studio"
DATASUITE_CREDENTIALS_PATH = DATASUITE_CONFIG_DIR / "credentials.json"
DATASUITE_COOKIE_PATH = DATASUITE_CONFIG_DIR / "cookies.json"
DATA_STUDIO_BASE_URL = "https://datasuite.shopee.io"
DATASUITE_ADHOC_API_PREFIX = "/datastudio/api/v1/execution/adhoc"
DATASUITE_ASSET_API_PREFIX = "/datastudio/api/v1/asset"
DATASUITE_CLICKHOUSE_ENGINE_TYPE = 34
DATASUITE_DEFAULT_RESULT_LIMIT = 100000
DATASUITE_POLL_INTERVAL_SECONDS = 2.0
DATASUITE_POLL_MAX_RETRIES = 150
NULL_PLACEHOLDER = "%null%"
READ_ONLY_START = re.compile(r"^(select|with|show|describe|desc|explain)\b", re.IGNORECASE)
FORBIDDEN_SQL = re.compile(
    r"\b(insert|update|delete|drop|truncate|alter|create|merge|replace|grant|revoke|attach|detach|rename|optimize)\b",
    re.IGNORECASE,
)
DATASUITE_STRING_COLUMNS = {"grass_date", "data_date", "grass_region", "exp_tag"}
DATASUITE_HEADERS = {
    "Accept": "*/*",
    "Content-Type": "application/json",
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/145.0.0.0 Safari/537.36"
    ),
}


class ConfigError(Exception):
    """Raised when local ClickHouse config or SQL is not usable."""


class DataSuiteAuthError(RuntimeError):
    """Raised when DataSuite cookies are expired or rejected."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run read-only ClickHouse SQL for ads-text2da.")
    sql_group = parser.add_mutually_exclusive_group(required=True)
    sql_group.add_argument("--sql", help="SQL text to execute")
    sql_group.add_argument("--sql-file", help="Path to a UTF-8 SQL file to execute")
    parser.add_argument("--cluster", default="sg", choices=("sg", "us_va2", "us", "br"))
    parser.add_argument("--config", default=str(CONFIG_PATH))
    parser.add_argument("--format", default="table", choices=("table", "json", "csv"))
    parser.add_argument("--output", help="Output file path; required when --format=csv")
    parser.add_argument("--timeout-seconds", type=float, help="Override ClickHouse HTTP timeout")
    parser.add_argument("--datasuite-project", default="", help="DataSuite project_code for ClickHouse fallback")
    parser.add_argument("--datasuite-hadoop-account", default="", help="DataSuite hadoop-account header override")
    parser.add_argument("--datasuite-idc-region", default="", help="DataSuite idcRegion override, for example SG")
    parser.add_argument("--datasuite-cluster-name", default="", help="ClickHouse clusterName for DataSuite fallback")
    parser.add_argument("--datasuite-result-limit", type=int, default=DATASUITE_DEFAULT_RESULT_LIMIT)
    parser.add_argument("--dry-run", action="store_true", help="Validate config and SQL without executing")
    args = parser.parse_args()
    if args.format == "csv" and not args.output:
        parser.error("--output is required when --format=csv")
    if args.format != "csv" and args.output:
        parser.error("--output is only supported when --format=csv")
    return args


def resolve_sql(args: argparse.Namespace) -> str:
    if args.sql is not None:
        sql = args.sql
    else:
        sql_path = Path(args.sql_file).expanduser()
        if not sql_path.exists():
            raise ConfigError(f"SQL file not found: {sql_path}")
        if not sql_path.is_file():
            raise ConfigError(f"SQL file path is not a file: {sql_path}")

        try:
            sql = sql_path.read_text(encoding="utf-8")
        except OSError as exc:
            raise ConfigError(f"Could not read SQL file {sql_path}: {exc}") from exc

        if not sql.strip():
            raise ConfigError(f"SQL file is empty: {sql_path}")

    if not sql.strip():
        raise ConfigError("SQL is empty.")

    validate_read_only_sql(sql)
    return sql


def strip_sql_comments(sql: str) -> str:
    without_blocks = re.sub(r"/\*.*?\*/", " ", sql, flags=re.S)
    return "\n".join(line.split("--", 1)[0] for line in without_blocks.splitlines())


def validate_read_only_sql(sql: str) -> None:
    cleaned = strip_sql_comments(sql).strip()
    if not READ_ONLY_START.search(cleaned):
        raise ConfigError("ClickHouse runner only supports read-only SQL starting with SELECT/WITH/SHOW/DESCRIBE/EXPLAIN.")
    if FORBIDDEN_SQL.search(cleaned):
        raise ConfigError("ClickHouse runner refuses mutation or DDL keywords in SQL.")


def read_config_file(path: Path | None) -> dict[str, Any]:
    if path is None or not path.exists():
        return {}
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        raise ConfigError(f"ClickHouse config is not valid JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigError("ClickHouse config must contain a JSON object.")
    return data


def normalized_cluster(cluster: str) -> str:
    if cluster in {"us", "br"}:
        return "us_va2"
    return "sg"


def default_url_for_cluster(cluster: str) -> str:
    return DEFAULT_US_VA2_URL if normalized_cluster(cluster) == "us_va2" else DEFAULT_SG_URL


def cluster_file_config(data: dict[str, Any], cluster: str) -> dict[str, Any]:
    clusters = data.get("clusters")
    if isinstance(clusters, dict):
        value = clusters.get(normalized_cluster(cluster)) or clusters.get(cluster) or {}
        if not isinstance(value, dict):
            raise ConfigError(f"ClickHouse cluster config for {cluster} must be an object.")
        return value
    return data


def text2da_clickhouse_config(data: dict[str, Any], cluster: str) -> dict[str, Any]:
    clickhouse_config = data.get("clickhouse")
    if isinstance(clickhouse_config, dict):
        return cluster_file_config(clickhouse_config, cluster)
    if clickhouse_config is not None:
        raise ConfigError("Config field 'clickhouse' must be an object.")
    if any(key in data for key in ("auth", "username", "password", "clusters", "url", "timeout_seconds")):
        return cluster_file_config(data, cluster)
    return {}


def auth_from_mapping(data: Mapping[str, Any]) -> str:
    auth = str(data.get("auth") or "").strip()
    username = str(data.get("username") or "").strip()
    password = str(data.get("password") or "").strip()
    if not auth and username and password:
        auth = f"{username}:{password}"
    return auth


def load_config(
    path: Path | str | None = CONFIG_PATH,
    cluster: str = "sg",
    env: Mapping[str, str] | None = None,
    legacy_config_path: Path | str | None = LEGACY_ROI3_CONFIG_PATH,
) -> dict[str, Any]:
    env = env if env is not None else os.environ
    cluster_key = normalized_cluster(cluster)
    primary_path = Path(path).expanduser() if path is not None else None
    legacy_path = Path(legacy_config_path).expanduser() if legacy_config_path is not None else None
    file_config = text2da_clickhouse_config(read_config_file(primary_path), cluster_key)
    if not file_config and legacy_path != primary_path:
        file_config = cluster_file_config(read_config_file(legacy_path), cluster_key)

    if cluster_key == "us_va2":
        env_auth = env.get("TEXT2DA_CLICKHOUSE_US_AUTH") or env.get("CLICKHOUSE_US_AUTH")
        env_url = env.get("TEXT2DA_CLICKHOUSE_US_URL") or env.get("CLICKHOUSE_US_URL")
    else:
        env_auth = env.get("TEXT2DA_CLICKHOUSE_AUTH") or env.get("CLICKHOUSE_SG_AUTH") or env.get("ROI3_CLICKHOUSE_AUTH")
        env_url = env.get("TEXT2DA_CLICKHOUSE_URL") or env.get("CLICKHOUSE_SG_URL") or env.get("ROI3_CLICKHOUSE_URL")

    url = env_url or str(file_config.get("url") or "").strip() or default_url_for_cluster(cluster_key)
    auth = env_auth or auth_from_mapping(file_config)
    if not auth:
        raise ConfigError(
            "ClickHouse config not found. Add a clickhouse section to ~/.config/text2da/config.json. "
            "For temporary overrides only, set TEXT2DA_CLICKHOUSE_AUTH / CLICKHOUSE_SG_AUTH / ROI3_CLICKHOUSE_AUTH. "
            "The username should include the cluster suffix, for example UserName-ClusterName."
        )
    timeout = file_config.get("timeout_seconds", 30)
    return {"url": url, "auth": auth, "timeout_seconds": float(timeout)}


def load_clickhouse_config(
    env: Mapping[str, str] | None = None,
    config_path: Path | str | None = CONFIG_PATH,
    legacy_config_path: Path | str | None = LEGACY_ROI3_CONFIG_PATH,
    cluster: str = "sg",
) -> dict[str, Any]:
    return load_config(
        path=config_path,
        cluster=cluster,
        env=env,
        legacy_config_path=legacy_config_path,
    )


def build_effective_config(args: argparse.Namespace, config: dict[str, Any]) -> dict[str, Any]:
    effective = dict(config)
    if args.timeout_seconds is not None:
        effective["timeout_seconds"] = args.timeout_seconds
    return effective


def mask_secret(value: str) -> str:
    if not value:
        return "<empty>"
    if len(value) <= 4:
        return "*" * len(value)
    return value[:2] + "*" * (len(value) - 4) + value[-2:]


def sql_with_json_each_row(sql: str) -> str:
    stripped = sql.strip().rstrip(";")
    if re.search(r"\bFORMAT\s+\w+\s*$", stripped, flags=re.IGNORECASE):
        return stripped
    return stripped + "\nFORMAT JSONEachRow"


def sql_without_trailing_format(sql: str) -> str:
    stripped = sql.strip().rstrip(";")
    return re.sub(r"\s+\bFORMAT\s+\w+\s*$", "", stripped, flags=re.IGNORECASE)


def clickhouse_cluster_name_from_sql(sql: str) -> str:
    cleaned = strip_sql_comments(sql)
    match = re.search(
        r"\bcluster\s*\(\s*'((?:\\.|[^'])+)'",
        cleaned,
        flags=re.IGNORECASE | re.DOTALL,
    )
    if not match:
        return ""
    return match.group(1).replace("\\'", "'").replace("\\\\", "\\")


def load_datasuite_credentials(path: Path | str = DATASUITE_CREDENTIALS_PATH) -> dict[str, Any]:
    credentials_path = Path(path).expanduser()
    if not credentials_path.exists():
        return {}
    try:
        data = json.loads(credentials_path.read_text())
    except json.JSONDecodeError as exc:
        raise ConfigError(f"DataSuite credentials file is not valid JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigError("DataSuite credentials file must contain a JSON object.")
    section = data.get("data-studio", {})
    if section is None:
        return {}
    if not isinstance(section, dict):
        raise ConfigError("DataSuite credentials field 'data-studio' must be an object.")
    return section


def default_idc_region_for_cluster(cluster: str) -> str:
    return "USEast" if normalized_cluster(cluster) == "us_va2" else "SG"


def build_datasuite_clickhouse_config(args: argparse.Namespace, sql: str) -> dict[str, Any]:
    credentials = load_datasuite_credentials()
    project_code = str(
        getattr(args, "datasuite_project", "")
        or credentials.get("project_code")
        or ""
    ).strip()
    hadoop_account = str(
        getattr(args, "datasuite_hadoop_account", "")
        or credentials.get("hadoop_account")
        or ""
    ).strip()
    idc_region = str(
        getattr(args, "datasuite_idc_region", "")
        or credentials.get("idc_region")
        or default_idc_region_for_cluster(getattr(args, "cluster", "sg"))
    ).strip()
    cluster_name = str(
        getattr(args, "datasuite_cluster_name", "")
        or clickhouse_cluster_name_from_sql(sql)
        or ""
    ).strip()

    if not project_code:
        raise ConfigError(
            "DataSuite ClickHouse fallback needs a project_code. Pass --datasuite-project "
            "or configure ~/.config/sra/data-studio/credentials.json."
        )
    if not hadoop_account:
        raise ConfigError(
            "DataSuite ClickHouse fallback needs a hadoop_account. Pass --datasuite-hadoop-account "
            "or configure ~/.config/sra/data-studio/credentials.json."
        )
    if not cluster_name:
        raise ConfigError(
            "DataSuite ClickHouse fallback needs a ClickHouse clusterName. Pass --datasuite-cluster-name "
            "or use SQL with cluster('cluster_name', ...)."
        )

    return {
        "base_url": DATA_STUDIO_BASE_URL,
        "project_code": project_code,
        "hadoop_account": hadoop_account,
        "idc_region": idc_region,
        "cluster_name": cluster_name,
        "result_limit": int(getattr(args, "datasuite_result_limit", DATASUITE_DEFAULT_RESULT_LIMIT)),
        "request_timeout_seconds": float(getattr(args, "timeout_seconds", None) or 30),
        "poll_interval_seconds": DATASUITE_POLL_INTERVAL_SECONDS,
        "poll_max_retries": DATASUITE_POLL_MAX_RETRIES,
    }


def find_sra_datasuite_scripts_dir() -> Path | None:
    current = Path(__file__).resolve()
    for parent in current.parents:
        candidate = parent / "sra-toolkit" / "skills" / "sra-ds-sql-query" / "scripts"
        if candidate.exists():
            return candidate
    return None


def load_datasuite_cookies(force_refresh: bool = False) -> dict[str, str]:
    scripts_dir = find_sra_datasuite_scripts_dir()
    if scripts_dir is not None:
        inserted = False
        try:
            scripts_dir_text = str(scripts_dir)
            if scripts_dir_text not in sys.path:
                sys.path.insert(0, scripts_dir_text)
                inserted = True
            from cookie_extractor import get_cookies  # type: ignore

            cookies = get_cookies(force_refresh=force_refresh)
            if isinstance(cookies, dict) and cookies:
                return {str(key): str(value) for key, value in cookies.items()}
        except Exception:
            if force_refresh:
                raise
        finally:
            if inserted:
                try:
                    sys.path.remove(scripts_dir_text)
                except ValueError:
                    pass

    if DATASUITE_COOKIE_PATH.exists():
        try:
            data = json.loads(DATASUITE_COOKIE_PATH.read_text())
        except json.JSONDecodeError as exc:
            raise ConfigError(f"DataSuite cookies file is not valid JSON: {exc}") from exc
        if isinstance(data, dict) and data:
            return {str(key): str(value) for key, value in data.items()}

    raise ConfigError(
        "DataSuite ClickHouse fallback could not load cookies. Log in to https://datasuite.shopee.io "
        "or configure ~/.config/sra/data-studio/refresh_token."
    )


def datasuite_cookie_header(cookies: Mapping[str, str]) -> str:
    return "; ".join(f"{key}={value}" for key, value in cookies.items())


def datasuite_headers(config: Mapping[str, Any], cookies: Mapping[str, str]) -> dict[str, str]:
    base_url = str(config["base_url"]).rstrip("/")
    headers = dict(DATASUITE_HEADERS)
    headers.update(
        {
            "hadoop-account": str(config["hadoop_account"]),
            "studio-project-code": str(config["project_code"]),
            "Origin": base_url,
            "Referer": f"{base_url}/studio?project_code={config['project_code']}",
            "Cookie": datasuite_cookie_header(cookies),
        }
    )
    csrf_token = cookies.get("CSRF-TOKEN")
    if csrf_token:
        headers["x-csrf-token"] = csrf_token
    return headers


def datasuite_api_json(
    method: str,
    path: str,
    config: Mapping[str, Any],
    cookies: Mapping[str, str],
    *,
    params: Mapping[str, Any] | None = None,
    payload: Mapping[str, Any] | None = None,
    timeout: float | None = None,
) -> dict[str, Any]:
    base_url = str(config["base_url"]).rstrip("/")
    query = urllib.parse.urlencode(params or {})
    url = f"{base_url}{path}"
    if query:
        url = f"{url}?{query}"
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    if method.upper() == "POST" and body is None:
        body = b""
    request = urllib.request.Request(
        url,
        data=body,
        headers=datasuite_headers(config, cookies),
        method=method.upper(),
    )
    try:
        with urllib.request.urlopen(
            request,
            timeout=timeout or float(config["request_timeout_seconds"]),
        ) as response:
            raw = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        if exc.code == 401:
            raise DataSuiteAuthError(f"DataSuite HTTP 401: {detail}") from exc
        raise RuntimeError(f"DataSuite HTTP {exc.code}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"DataSuite request failed: {exc}") from exc

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"DataSuite returned non-JSON response: {raw[:500]}") from exc
    if not isinstance(data, dict):
        raise RuntimeError(f"DataSuite response was not a JSON object: {data!r}")
    return data


def datasuite_create_temp_query(config: Mapping[str, Any], cookies: Mapping[str, str]) -> int:
    response = datasuite_api_json(
        "POST",
        f"{DATASUITE_ASSET_API_PREFIX}/createTempQuery",
        config,
        cookies,
        params={
            "assetName": "ads-text2da ClickHouse",
            "projectCode": config["project_code"],
        },
        timeout=15,
    )
    if not response.get("success"):
        raise RuntimeError(
            f"DataSuite createTempQuery failed: code={response.get('code')}, "
            f"message={response.get('message')}"
        )
    asset_id = response.get("data")
    if not asset_id:
        raise RuntimeError(f"DataSuite createTempQuery did not return assetId: {response}")
    return int(asset_id)


def datasuite_submit_clickhouse(
    sql: str,
    config: Mapping[str, Any],
    cookies: Mapping[str, str],
    asset_id: int,
) -> int:
    line_count = sql.count("\n") + 1
    payload: dict[str, Any] = {
        "selectedCode": sql,
        "codeContent": sql,
        "selectedRange": {
            "startLineNumber": 1,
            "startColumn": 1,
            "endLineNumber": line_count,
            "endColumn": 1,
            "selectionStartLineNumber": line_count + 1,
            "selectionStartColumn": 1,
            "positionLineNumber": 1,
            "positionColumn": 1,
        },
        "parameter": [],
        "assetId": asset_id,
        "postTaskCommand": [],
        "preTaskCommand": [],
        "sparkSQLConfig": {"sparkVersion": "3.x", "sparkSqlResources": []},
        "idcRegion": config["idc_region"],
        "clickhouseConfig": {"clusterName": config["cluster_name"]},
        "starRocksConfig": {},
        "executionEngineType": DATASUITE_CLICKHOUSE_ENGINE_TYPE,
    }
    response = datasuite_api_json(
        "POST",
        f"{DATASUITE_ADHOC_API_PREFIX}/submit",
        config,
        cookies,
        payload=payload,
        timeout=30,
    )
    if not response.get("success"):
        raise RuntimeError(
            f"DataSuite ClickHouse submit failed: code={response.get('code')}, "
            f"message={response.get('message')}"
        )
    execution_id = response.get("data", {}).get("executionId")
    if execution_id is None:
        raise RuntimeError(f"DataSuite ClickHouse submit did not return executionId: {response}")
    return int(execution_id)


def datasuite_wait_for_completion(
    execution_id: int,
    config: Mapping[str, Any],
    cookies: Mapping[str, str],
) -> None:
    logs: list[str] = []
    for _ in range(int(config["poll_max_retries"])):
        response = datasuite_api_json(
            "GET",
            f"{DATASUITE_ADHOC_API_PREFIX}/log",
            config,
            cookies,
            params={"executionId": execution_id, "sqlIndex": 0, "offset": 0},
            timeout=15,
        )
        if not response.get("success"):
            raise RuntimeError(
                f"DataSuite ClickHouse log failed: code={response.get('code')}, "
                f"message={response.get('message')}"
            )
        data = response.get("data") or {}
        status = data.get("status")
        log_content = str(data.get("logContent") or "").strip()
        if log_content:
            logs.append(log_content)
            logs = logs[-50:]
        if status == 20:
            return
        if data.get("logEnd") and status != 20:
            raise RuntimeError(
                f"DataSuite ClickHouse execution failed (executionId={execution_id}, status={status})\n"
                + "\n".join(logs)
            )
        time.sleep(float(config["poll_interval_seconds"]))
    raise TimeoutError(
        f"DataSuite ClickHouse execution timed out (executionId={execution_id})"
    )


def datasuite_get_results(
    execution_id: int,
    config: Mapping[str, Any],
    cookies: Mapping[str, str],
) -> dict[str, Any]:
    response = datasuite_api_json(
        "GET",
        f"{DATASUITE_ADHOC_API_PREFIX}/result/v2",
        config,
        cookies,
        params={
            "executionId": execution_id,
            "sqlIndex": 0,
            "limit": config["result_limit"],
        },
        timeout=60,
    )
    if not response.get("success"):
        raise RuntimeError(
            f"DataSuite ClickHouse result failed: code={response.get('code')}, "
            f"message={response.get('message')}"
        )
    data = response.get("data", response)
    if not isinstance(data, dict):
        raise RuntimeError(f"DataSuite ClickHouse result data is not an object: {data!r}")
    return data


def convert_datasuite_value(column: str, value: Any, column_type: str = "") -> Any:
    if value is None or value == NULL_PLACEHOLDER:
        return None
    if column in DATASUITE_STRING_COLUMNS:
        return str(value)
    text = str(value)
    upper_type = column_type.upper()
    is_numeric_type = any(
        token in upper_type
        for token in ("INT", "LONG", "FLOAT", "DOUBLE", "DECIMAL", "NUMBER")
    )
    if is_numeric_type:
        try:
            if any(char in text for char in (".", "e", "E")):
                return float(text)
            return int(text)
        except ValueError:
            return value
    return value


def datasuite_result_to_rows(result: Mapping[str, Any]) -> list[dict[str, Any]]:
    headers = result.get("header") or []
    body = result.get("body") or []
    column_types = result.get("columnTypes") or []
    if not isinstance(headers, list) or not isinstance(body, list):
        raise RuntimeError(f"DataSuite result missing header/body arrays: {result}")

    rows: list[dict[str, Any]] = []
    for raw_row in body:
        if not isinstance(raw_row, list):
            raise RuntimeError(f"DataSuite result body row is not an array: {raw_row!r}")
        row: dict[str, Any] = {}
        for index, header in enumerate(headers):
            column = str(header)
            column_type = str(column_types[index]) if index < len(column_types) else ""
            value = raw_row[index] if index < len(raw_row) else None
            row[column] = convert_datasuite_value(column, value, column_type)
        rows.append(row)
    return rows


def _fetch_rows_via_datasuite_once(sql: str, config: Mapping[str, Any], cookies: Mapping[str, str]) -> list[dict[str, Any]]:
    query_sql = sql_without_trailing_format(sql)
    asset_id = datasuite_create_temp_query(config, cookies)
    execution_id = datasuite_submit_clickhouse(query_sql, config, cookies, asset_id)
    print(
        f"DataSuite ClickHouse submitted executionId={execution_id} "
        f"project={config['project_code']} cluster={config['cluster_name']}",
        file=sys.stderr,
    )
    datasuite_wait_for_completion(execution_id, config, cookies)
    return datasuite_result_to_rows(datasuite_get_results(execution_id, config, cookies))


def fetch_rows_via_datasuite_clickhouse(sql: str, config: Mapping[str, Any]) -> list[dict[str, Any]]:
    try:
        cookies = load_datasuite_cookies(force_refresh=False)
        return _fetch_rows_via_datasuite_once(sql, config, cookies)
    except DataSuiteAuthError:
        cookies = load_datasuite_cookies(force_refresh=True)
        return _fetch_rows_via_datasuite_once(sql, config, cookies)


def run_clickhouse_sql(sql: str, config: dict[str, Any]) -> str:
    auth_header = base64.b64encode(str(config["auth"]).encode("utf-8")).decode("ascii")
    request = urllib.request.Request(
        str(config["url"]),
        data=sql_with_json_each_row(sql).encode("utf-8"),
        headers={
            "Authorization": f"Basic {auth_header}",
            "Content-Type": "text/plain; charset=utf-8",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=float(config["timeout_seconds"])) as response:
            return response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"ClickHouse HTTP {exc.code}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"ClickHouse request failed: {exc}") from exc


def parse_json_each_row(raw: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        value = json.loads(line)
        if not isinstance(value, dict):
            raise RuntimeError("ClickHouse JSONEachRow output contained a non-object row.")
        rows.append(value)
    return rows


def fetch_rows(sql: str, config: dict[str, Any]) -> list[dict[str, Any]]:
    return parse_json_each_row(run_clickhouse_sql(sql, config))


def fetch_rows_with_fallback(sql: str, args: argparse.Namespace) -> list[dict[str, Any]]:
    direct_error: Exception | None = None
    try:
        direct_config = build_effective_config(
            args,
            load_config(Path(args.config), cluster=args.cluster),
        )
    except ConfigError as exc:
        direct_config = None
        direct_error = exc

    if direct_config is not None:
        try:
            return fetch_rows(sql, direct_config)
        except RuntimeError as exc:
            direct_error = exc
            print(
                f"Direct ClickHouse unavailable ({exc}); trying DataSuite ClickHouse.",
                file=sys.stderr,
            )

    try:
        datasuite_config = build_datasuite_clickhouse_config(args, sql)
        if direct_config is None:
            print(
                f"Direct ClickHouse config unavailable ({direct_error}); trying DataSuite ClickHouse.",
                file=sys.stderr,
            )
        return fetch_rows_via_datasuite_clickhouse(sql, datasuite_config)
    except ConfigError as exc:
        raise ConfigError(
            f"ClickHouse query could not start. Direct ClickHouse error: {direct_error}. "
            f"DataSuite ClickHouse config error: {exc}. "
            "Hive/Presto fallback is disabled for ClickHouse runner."
        ) from exc
    except Exception as exc:
        raise RuntimeError(
            f"ClickHouse query failed. Direct ClickHouse error: {direct_error}. "
            f"DataSuite ClickHouse error: {exc}. "
            "Hive/Presto fallback is disabled for ClickHouse runner."
        ) from exc


def render_json(rows: Sequence[dict[str, Any]]) -> str:
    return json.dumps(list(rows), indent=2, ensure_ascii=False)


def render_table(rows: Sequence[dict[str, Any]]) -> str:
    if not rows:
        return "(0 rows)"
    headers = [str(header) for header in rows[0].keys()]
    table_rows = [[format_cell(row.get(header, "")) for header in headers] for row in rows]
    widths = [len(header) for header in headers]
    for row in table_rows:
        for index, cell in enumerate(row):
            widths[index] = max(widths[index], len(cell))

    def join_line(parts: Sequence[str]) -> str:
        return " | ".join(part.ljust(widths[index]) for index, part in enumerate(parts))

    separator = "-+-".join("-" * width for width in widths)
    lines = [join_line(headers), separator]
    lines.extend(join_line(row) for row in table_rows)
    lines.append(f"({len(rows)} rows)")
    return "\n".join(lines)


def format_cell(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False)
    return str(value)


def write_csv(rows: Sequence[dict[str, Any]], output_path: Path) -> None:
    if not rows:
        output_path.write_text("")
        return

    headers = list(rows[0].keys())
    with output_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=headers)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in headers})


def dry_run_payload(args: argparse.Namespace, config: dict[str, Any], sql: str) -> dict[str, Any]:
    return {
        "mode": "direct_clickhouse",
        "config_path": str(Path(args.config).expanduser()),
        "cluster": normalized_cluster(args.cluster),
        "url": config["url"],
        "auth": mask_secret(str(config["auth"])),
        "timeout_seconds": config["timeout_seconds"],
        "format": args.format,
        "output": args.output,
        "sql": args.sql,
        "sql_file": args.sql_file,
        "sql_source": args.sql_file if args.sql_file else "inline",
        "sql_preview": strip_sql_comments(sql).strip().splitlines()[0][:120],
    }


def datasuite_dry_run_payload(args: argparse.Namespace, config: Mapping[str, Any], sql: str) -> dict[str, Any]:
    return {
        "mode": "datasuite_clickhouse",
        "config_path": str(Path(args.config).expanduser()),
        "cluster": normalized_cluster(args.cluster),
        "datasuite_project": config["project_code"],
        "datasuite_hadoop_account": config["hadoop_account"],
        "datasuite_idc_region": config["idc_region"],
        "datasuite_cluster_name": config["cluster_name"],
        "datasuite_result_limit": config["result_limit"],
        "format": args.format,
        "output": args.output,
        "sql": args.sql,
        "sql_file": args.sql_file,
        "sql_source": args.sql_file if args.sql_file else "inline",
        "sql_preview": strip_sql_comments(sql).strip().splitlines()[0][:120],
    }


def main() -> int:
    args = parse_args()
    try:
        sql = resolve_sql(args)
    except ConfigError as exc:
        print(f"Configuration error: {exc}", file=sys.stderr)
        return 2

    if args.dry_run:
        try:
            config = build_effective_config(
                args,
                load_config(Path(args.config), cluster=args.cluster),
            )
            print(json.dumps(dry_run_payload(args, config, sql), indent=2, ensure_ascii=False))
            return 0
        except ConfigError:
            try:
                config = build_datasuite_clickhouse_config(args, sql)
            except ConfigError as exc:
                print(f"Configuration error: {exc}", file=sys.stderr)
                return 2
            print(json.dumps(datasuite_dry_run_payload(args, config, sql), indent=2, ensure_ascii=False))
            return 0

    try:
        rows = fetch_rows_with_fallback(sql, args)
    except ConfigError as exc:
        print(f"Configuration error: {exc}", file=sys.stderr)
        return 2
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 3
    except Exception as exc:
        print(f"Query execution failed: {exc}", file=sys.stderr)
        return 4

    if args.format == "json":
        print(render_json(rows))
        return 0
    if args.format == "csv":
        output_path = Path(args.output).expanduser()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        write_csv(rows, output_path)
        print(f"Wrote {len(rows)} rows to {output_path}")
        return 0
    print(render_table(rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
