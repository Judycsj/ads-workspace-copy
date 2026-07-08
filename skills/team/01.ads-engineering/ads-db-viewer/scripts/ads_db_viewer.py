#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "requests>=2.0.0",
# ]
# ///

from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import re
import sys
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


QUERY_COMMAND = "paidads.backend_admin.database_viewer"
METADATA_COMMAND = "paidads.backend_admin.get_database_viewer_metadata"

DATABASES = {
    "DATABASE_ADS": 1,
    "ADS": 1,
    "DATABASE_ARCHIVE": 2,
    "ARCHIVE": 2,
    "DATABASE_BUYER_SEGMENT": 3,
    "BUYER_SEGMENT": 3,
    "DATABASE_SRM": 4,
    "SRM": 4,
    "DATABASE_BUYER_SEGMENT_BY_REGION": 5,
    "BUYER_SEGMENT_BY_REGION": 5,
    "DATABASE_ADS_MARKETING": 6,
    "ADS_MARKETING": 6,
    "DATABASE_REBATE": 7,
    "REBATE": 7,
}


def find_helper_dir() -> Path:
    skill_dir = Path(__file__).resolve().parents[1]
    roots: list[Path] = []

    env_root = os.environ.get("SRA_TOOLKIT_DIR")
    if env_root:
        roots.append(Path(env_root).expanduser())

    for parent in [skill_dir, *skill_dir.parents]:
        roots.append(parent / "sra-toolkit")
        if parent.name == "sra-toolkit":
            roots.append(parent)

    for root in roots:
        helper_dir = root / "skills" / "sp-spex-api" / "scripts"
        if helper_dir.exists():
            return helper_dir

    raise RuntimeError(
        "Cannot find sp-spex-api helper scripts. Set SRA_TOOLKIT_DIR to the sra-toolkit repo."
    )


sys.path.insert(0, str(find_helper_dir()))

from spex_api_call import call_spex, resolve_sdu_and_key  # noqa: E402
from spex_auth import load_auth_token, load_permission_obj, normalize_token  # noqa: E402


def load_ads_workspace_gateway_token() -> str | None:
    cred_path = Path.home() / ".config" / "sra" / "credentials.json"
    try:
        data = json.loads(cred_path.read_text())
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None
    token = data.get("spex_http_gateway", {}).get("bearer_token", "")
    if isinstance(token, str) and token.strip():
        return normalize_token(token)
    return None


def load_token(cli_token: str | None) -> str:
    if cli_token:
        return normalize_token(cli_token)
    try:
        return load_auth_token(None).value
    except ValueError:
        token = load_ads_workspace_gateway_token()
        if token:
            return token
        raise


def normalize_database(value: str | int | None) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    raw = str(value).strip()
    if not raw:
        return None
    if raw.isdigit():
        return int(raw)
    key = raw.upper().replace("-", "_")
    if key in DATABASES:
        return DATABASES[key]
    raise ValueError(f"unknown database: {value!r}")


def make_header(region: str, operator: str, request_id: str | None = None) -> dict[str, str]:
    return {
        "request_id": request_id or f"ads-db-viewer-{int(time.time())}-{uuid.uuid4().hex[:8]}",
        "region": region.upper(),
        "operator": operator,
    }


def parse_fields(values: list[str] | None) -> list[str]:
    fields: list[str] = []
    for value in values or []:
        for item in value.split(","):
            item = item.strip()
            if item:
                fields.append(item)
    return fields


def parse_filter(value: str) -> dict[str, str]:
    if "=" not in value:
        raise ValueError(f"filter must be name=value: {value!r}")
    name, exact = value.split("=", 1)
    name = name.strip()
    exact = exact.strip()
    if not name:
        raise ValueError("filter name is empty")
    return {"name": name, "value": exact}


def parse_range_filter(value: str) -> dict[str, str]:
    if "=" not in value or ".." not in value:
        raise ValueError(f"range filter must be name=low..high: {value!r}")
    name, bounds = value.split("=", 1)
    low, high = bounds.split("..", 1)
    name = name.strip()
    if not name:
        raise ValueError("range filter name is empty")
    return {"name": name, "low": low.strip(), "high": high.strip()}


def parse_filters(args: argparse.Namespace) -> list[dict[str, Any]]:
    filters: list[dict[str, Any]] = []
    if getattr(args, "filters_json", None):
        loaded = json.loads(args.filters_json)
        if not isinstance(loaded, list):
            raise ValueError("--filters-json must be a JSON list")
        filters.extend(loaded)
    for value in getattr(args, "filter", None) or []:
        filters.append(parse_filter(value))
    for value in getattr(args, "range", None) or []:
        filters.append(parse_range_filter(value))
    return filters


def project_records(records: list[dict[str, Any]], fields: list[str]) -> list[dict[str, Any]]:
    if not fields:
        return records
    return [{field: record.get(field) for field in fields if field in record} for record in records]


class DBViewerClient:
    def __init__(self, token: str, permission_obj: str, timeout: int):
        self.token = token
        self.permission_obj = permission_obj
        self.timeout = timeout
        self.resolved: dict[tuple[str, str], tuple[str, str]] = {}

    def call(self, command: str, env: str, region: str, payload: dict[str, Any]) -> dict[str, Any]:
        cache_key = (command, env)
        if cache_key not in self.resolved:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.resolved[cache_key] = resolve_sdu_and_key(
                    cmd=command,
                    token=self.token,
                    env=env,
                    cli_sdu=None,
                    cli_service_key=None,
                    caller_spex_service=None,
                    caller_permission_obj=self.permission_obj,
                    timeout=self.timeout,
                )

        sdu, service_key = self.resolved[cache_key]
        resp = call_spex(
            cmd=command,
            country_code=region.lower(),
            payload=payload,
            token=self.token,
            sdu=sdu,
            service_key=service_key,
            env=env,
            timeout=self.timeout,
        )
        sp_error = (resp.headers.get("x-sp-error") or "").strip()
        if sp_error and sp_error != "0":
            sp_msg = (resp.headers.get("x-sp-errmsg") or "").strip()
            raise RuntimeError(f"SPEX error {sp_error}: {sp_msg}")
        resp.raise_for_status()
        try:
            return resp.json()
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"gateway returned non-JSON response: {resp.text[:200]}") from exc


def make_client(args: argparse.Namespace) -> DBViewerClient:
    return DBViewerClient(
        token=load_token(getattr(args, "token", None)),
        permission_obj=load_permission_obj(getattr(args, "permission_obj", None)),
        timeout=args.timeout,
    )


def build_metadata_payload(args: argparse.Namespace) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "header": make_header(args.region, args.operator, getattr(args, "request_id", None)),
    }
    if args.table:
        payload["table_name"] = args.table
    if args.table_example:
        payload["table_name_example"] = args.table_example
    database = normalize_database(args.database)
    if database is not None:
        payload["database"] = database
    return payload


def build_query_payload(args: argparse.Namespace) -> tuple[dict[str, Any], list[str]]:
    limit = int(args.limit)
    if limit <= 0 or limit > args.max_limit:
        raise ValueError(f"limit must be in [1,{args.max_limit}]")
    if args.offset < 0:
        raise ValueError("offset must be >= 0")
    if not args.table and not args.table_example:
        raise ValueError("--table or --table-example is required")

    payload: dict[str, Any] = {
        "header": make_header(args.region, args.operator, getattr(args, "request_id", None)),
        "filters": parse_filters(args),
        "limit": limit,
        "offset": args.offset,
    }
    if args.table:
        payload["table_name"] = args.table
    if args.table_example:
        payload["table_name_example"] = args.table_example
    database = normalize_database(args.database)
    if database is not None:
        payload["database"] = database
    if args.total_only:
        payload["total_only"] = True
    return payload, parse_fields(args.fields)


def parse_records(data: dict[str, Any], fields: list[str]) -> None:
    raw_records = data.get("records")
    if isinstance(raw_records, str):
        records = json.loads(raw_records or "[]")
    elif isinstance(raw_records, list):
        records = raw_records
    else:
        records = []
    data["records"] = project_records(records, fields)


def dump_json(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))


def cmd_db_enum(_: argparse.Namespace) -> int:
    dump_json(
        {
            "DATABASE_ADS": 1,
            "DATABASE_ARCHIVE": 2,
            "DATABASE_BUYER_SEGMENT": 3,
            "DATABASE_SRM": 4,
            "DATABASE_BUYER_SEGMENT_BY_REGION": 5,
            "DATABASE_ADS_MARKETING": 6,
            "DATABASE_REBATE": 7,
        }
    )
    return 0


def cmd_metadata(args: argparse.Namespace) -> int:
    client = make_client(args)
    payload = build_metadata_payload(args)
    data = client.call(METADATA_COMMAND, args.env, args.region, payload)
    if args.search:
        pattern = re.compile(args.search, re.IGNORECASE)
        rows = data.get("data", [])
        if isinstance(rows, list):
            data["data"] = [
                row for row in rows if pattern.search(json.dumps(row, ensure_ascii=False))
            ]
    dump_json({"ok": True, "env": args.env, "region": args.region, "data": data})
    return 0


def cmd_query(args: argparse.Namespace) -> int:
    client = make_client(args)
    payload, fields = build_query_payload(args)
    data = client.call(QUERY_COMMAND, args.env, args.region, payload)
    parse_records(data, fields)
    dump_json({"ok": True, "env": args.env, "region": args.region, "data": data})
    return 0


def json_response(handler: BaseHTTPRequestHandler, status: int, payload: dict[str, Any]) -> None:
    body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
    handler.send_response(status)
    handler.send_header("content-type", "application/json; charset=utf-8")
    handler.send_header("content-length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def read_json_body(handler: BaseHTTPRequestHandler) -> dict[str, Any]:
    length = int(handler.headers.get("content-length") or "0")
    raw = handler.rfile.read(length) if length else b"{}"
    payload = json.loads(raw)
    if not isinstance(payload, dict):
        raise ValueError("JSON body must be an object")
    return payload


class DBViewerHTTPServer(ThreadingHTTPServer):
    def __init__(self, address: tuple[str, int], args: argparse.Namespace):
        super().__init__(address, DBViewerHTTPHandler)
        self.args = args
        self.client = make_client(args)


class DBViewerHTTPHandler(BaseHTTPRequestHandler):
    server: DBViewerHTTPServer

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def do_GET(self) -> None:
        if self.path.split("?", 1)[0] == "/health":
            json_response(self, 200, {"ok": True})
            return
        json_response(self, 404, {"ok": False, "error": "unsupported path"})

    def do_POST(self) -> None:
        try:
            request = read_json_body(self)
            env = str(request.get("env") or self.server.args.env).lower()
            region = str(request.get("region") or self.server.args.region).upper()
            operator = str(request.get("operator") or self.server.args.operator)
            request_id = request.get("request_id")

            common = argparse.Namespace(
                env=env,
                region=region,
                operator=operator,
                request_id=request_id,
                table=request.get("table_name"),
                table_example=request.get("table_name_example"),
                database=request.get("database"),
            )
            path = self.path.split("?", 1)[0]
            if path == "/metadata":
                payload = build_metadata_payload(common)
                data = self.server.client.call(METADATA_COMMAND, env, region, payload)
                json_response(self, 200, {"ok": True, "env": env, "region": region, "data": data})
                return

            if path == "/query":
                limit = int(request.get("limit", 1))
                if limit <= 0 or limit > self.server.args.max_limit:
                    raise ValueError(f"limit must be in [1,{self.server.args.max_limit}]")
                payload = {
                    "header": make_header(region, operator, request_id),
                    "filters": request.get("filters") or [],
                    "limit": limit,
                    "offset": int(request.get("offset", 0)),
                }
                if common.table:
                    payload["table_name"] = common.table
                if common.table_example:
                    payload["table_name_example"] = common.table_example
                database = normalize_database(common.database)
                if database is not None:
                    payload["database"] = database
                if request.get("total_only"):
                    payload["total_only"] = True
                data = self.server.client.call(QUERY_COMMAND, env, region, payload)
                fields = [str(field) for field in request.get("fields") or [] if str(field)]
                parse_records(data, fields)
                json_response(self, 200, {"ok": True, "env": env, "region": region, "data": data})
                return

            json_response(self, 404, {"ok": False, "error": "unsupported path"})
        except Exception as exc:  # noqa: BLE001
            json_response(self, 400, {"ok": False, "error": str(exc)})


def cmd_serve(args: argparse.Namespace) -> int:
    server = DBViewerHTTPServer((args.host, args.port), args)
    print(f"ads_db_viewer listening on http://{args.host}:{args.port}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--env", default="live", choices=["live", "test", "uat"])
    parser.add_argument("--region", default="SG")
    parser.add_argument("--operator", default=f"{os.environ.get('USER', 'codex')}@shopee.com")
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--token", help="Override Space bearer token; otherwise use SRA/SMC credentials.")
    parser.add_argument(
        "--permission-obj",
        help="Override sp_spex_api.permission_obj for SPEX privilege lookup.",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Ads DB Viewer live metadata/query helper")
    sub = parser.add_subparsers(dest="command", required=True)

    db_enum = sub.add_parser("db-enum", help="Print backendadmin DB Viewer database enum values")
    db_enum.set_defaults(func=cmd_db_enum)

    metadata = sub.add_parser("metadata", help="Fetch DB Viewer metadata")
    add_common(metadata)
    metadata.add_argument("--table", help="Unique table name from DB Viewer metadata")
    metadata.add_argument("--table-example", help="Physical/example table name, e.g. ads_account_tab_00000000")
    metadata.add_argument("--database", help="Database enum value or name, e.g. 1 or ADS")
    metadata.add_argument("--request-id")
    metadata.add_argument("--search", help="Regex filter applied locally to metadata rows")
    metadata.set_defaults(func=cmd_metadata)

    query = sub.add_parser("query", help="Query a small live DB sample")
    add_common(query)
    query.add_argument("--table", help="Unique table name from DB Viewer metadata")
    query.add_argument("--table-example", help="Physical/example table name, e.g. ads_account_tab_00000000")
    query.add_argument("--database", help="Database enum value or name, e.g. 1 or ADS")
    query.add_argument("--filter", action="append", help="Exact filter: name=value. Repeatable.")
    query.add_argument("--range", action="append", help="Range filter: name=low..high. Repeatable.")
    query.add_argument("--filters-json", help='Raw DB Viewer filters JSON, e.g. [{"name":"userid","value":"1"}]')
    query.add_argument("--fields", nargs="*", help="Field projection, comma-separated or space-separated")
    query.add_argument("--limit", type=int, default=1)
    query.add_argument("--max-limit", type=int, default=10)
    query.add_argument("--offset", type=int, default=0)
    query.add_argument("--total-only", action="store_true")
    query.add_argument("--request-id")
    query.set_defaults(func=cmd_query)

    serve = sub.add_parser("serve", help="Start a localhost HTTP proxy")
    add_common(serve)
    serve.add_argument("--host", default="127.0.0.1")
    serve.add_argument("--port", type=int, default=18080)
    serve.add_argument("--max-limit", type=int, default=10)
    serve.set_defaults(func=cmd_serve)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
