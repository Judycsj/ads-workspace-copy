#!/usr/bin/env python3
"""Run PERSONAL_PRESTO queries for text2da using local user config."""

from __future__ import annotations

import argparse
import csv
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable, Sequence


CONFIG_PATH = Path.home() / ".config" / "text2da" / "config.json"
REEXEC_ENV = "TEXT2DA_PERSONAL_PRESTO_REEXEC"
REQUIRED_CONFIG_FIELDS = (
    "python_bin",
    "personal_token",
    "end_user",
    "presto_queue",
    "idc_region",
    "priority",
)


class ConfigError(Exception):
    """Raised when the local config is missing or invalid."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run personal-account Presto SQL for text2da.",
    )
    sql_group = parser.add_mutually_exclusive_group(required=True)
    sql_group.add_argument("--sql", help="SQL text to execute")
    sql_group.add_argument(
        "--sql-file",
        help="Path to a UTF-8 SQL file to execute",
    )
    parser.add_argument(
        "--format",
        default="table",
        choices=("table", "json", "csv"),
        help="Output format",
    )
    parser.add_argument(
        "--output",
        help="Output file path; required when --format=csv",
    )
    parser.add_argument("--queue", help="Override presto queue")
    parser.add_argument("--idc-region", help="Override IDC region")
    parser.add_argument("--priority", help="Override query priority")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate config and print effective settings without executing",
    )
    args = parser.parse_args()

    if args.format == "csv" and not args.output:
        parser.error("--output is required when --format=csv")
    if args.format != "csv" and args.output:
        parser.error("--output is only supported when --format=csv")

    return args


def resolve_sql(args: argparse.Namespace) -> str:
    if args.sql is not None:
        return args.sql

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

    return sql


def load_config(path: Path) -> dict[str, str]:
    if not path.exists():
        raise ConfigError(
            f"Config file not found: {path}. Create it from references/config.example.json."
        )

    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        raise ConfigError(f"Config file is not valid JSON: {exc}") from exc

    if not isinstance(data, dict):
        raise ConfigError("Config file must contain a JSON object.")

    missing = [field for field in REQUIRED_CONFIG_FIELDS if not str(data.get(field, "")).strip()]
    if missing:
        raise ConfigError(
            "Config file is missing required field(s): " + ", ".join(sorted(missing))
        )

    config: dict[str, str] = {}
    for field in REQUIRED_CONFIG_FIELDS:
        value = data[field]
        if not isinstance(value, str):
            raise ConfigError(f"Config field '{field}' must be a string.")
        config[field] = value.strip()

    python_bin = Path(config["python_bin"]).expanduser()
    if not python_bin.exists():
        raise ConfigError(f"Configured python_bin does not exist: {python_bin}")
    config["python_bin"] = str(python_bin)

    return config


def build_effective_config(args: argparse.Namespace, config: dict[str, str]) -> dict[str, str]:
    effective = dict(config)
    if args.queue:
        effective["presto_queue"] = args.queue
    if args.idc_region:
        effective["idc_region"] = args.idc_region
    if args.priority:
        effective["priority"] = args.priority
    return effective


def mask_secret(value: str) -> str:
    if not value:
        return "<empty>"
    if len(value) <= 4:
        return "*" * len(value)
    return value[:2] + "*" * (len(value) - 4) + value[-2:]


def current_python() -> Path:
    return Path(sys.prefix).resolve()


def ensure_configured_python(config: dict[str, str]) -> None:
    if os.environ.get(REEXEC_ENV) == "1":
        return

    configured_bin = Path(config["python_bin"])
    # Compare venv roots via the directory structure, without resolving the
    # interpreter binary itself: tools like uv create venvs whose python binary
    # symlinks to a shared base interpreter, so dereferencing the binary can make
    # distinct venvs look identical.
    if configured_bin.parent.parent.resolve() == current_python():
        return

    env = os.environ.copy()
    env[REEXEC_ENV] = "1"
    completed = subprocess.run(
        [str(configured_bin), __file__, *sys.argv[1:]],
        env=env,
        check=False,
    )
    raise SystemExit(completed.returncode)


def import_dataservice() -> tuple[Any, Any, Any, Any]:
    try:
        from dataservice.body import Body, PersonalPayload
        from dataservice.query_configuration import QueryConfiguration
        from dataservice.sdk import Client
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "dataservice is not available in the active interpreter. "
            "Update config.json python_bin to a Python environment with dataservice installed."
        ) from exc

    return Body, PersonalPayload, QueryConfiguration, Client


def fetch_rows(sql: str, config: dict[str, str]) -> list[Any]:
    Body, PersonalPayload, QueryConfiguration, Client = import_dataservice()

    client = (
        Client()
        .create()
        .queryPattern(QueryConfiguration.QueryPattern.PERSONAL_PRESTO)
        .env(QueryConfiguration.Env.LIVE)
        .personalToken(config["personal_token"])
        .endUser(config["end_user"])
    )

    body = Body(
        personalPayload=PersonalPayload(
            sql=sql,
            prestoQueue=config["presto_queue"],
            starRocksQueue="",
            idcRegion=config["idc_region"],
            priority=config["priority"],
        )
    )

    rows: list[Any] = []
    for shard in client.personalCall(body):
        rows.extend(list(shard))
    return rows


def row_to_serializable(row: Any) -> Any:
    if hasattr(row, "_asdict"):
        return row._asdict()
    if isinstance(row, dict):
        return dict(row)
    if isinstance(row, (list, tuple)):
        return list(row)
    return row


def normalize_rows(rows: Iterable[Any]) -> list[Any]:
    return [row_to_serializable(row) for row in rows]


def render_json(rows: Sequence[Any]) -> str:
    return json.dumps(list(rows), indent=2, ensure_ascii=False)


def render_table(rows: Sequence[Any]) -> str:
    if not rows:
        return "(0 rows)"

    first = rows[0]
    if isinstance(first, dict):
        headers = [str(header) for header in first.keys()]
        table_rows = [
            [format_cell(row.get(header, "")) for header in first.keys()]
            for row in rows
        ]
    elif isinstance(first, list):
        headers = [f"col_{index + 1}" for index in range(len(first))]
        table_rows = [[format_cell(cell) for cell in row] for row in rows]
    else:
        headers = ["value"]
        table_rows = [[format_cell(row)] for row in rows]

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


def write_csv(rows: Sequence[Any], output_path: Path) -> None:
    if not rows:
        output_path.write_text("")
        return

    first = rows[0]
    if isinstance(first, dict):
        headers = list(first.keys())
        with output_path.open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=headers)
            writer.writeheader()
            for row in rows:
                writer.writerow({key: row.get(key, "") for key in headers})
        return

    if isinstance(first, list):
        headers = [f"col_{index + 1}" for index in range(len(first))]
        with output_path.open("w", newline="") as handle:
            writer = csv.writer(handle)
            writer.writerow(headers)
            writer.writerows(rows)
        return

    with output_path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["value"])
        for row in rows:
            writer.writerow([row])


def dry_run_payload(args: argparse.Namespace, config: dict[str, str]) -> dict[str, Any]:
    sql_source = args.sql_file if args.sql_file else "inline"
    return {
        "config_path": str(CONFIG_PATH),
        "python_bin": config["python_bin"],
        "end_user": config["end_user"],
        "personal_token": mask_secret(config["personal_token"]),
        "presto_queue": config["presto_queue"],
        "idc_region": config["idc_region"],
        "priority": config["priority"],
        "format": args.format,
        "output": args.output,
        "sql": args.sql,
        "sql_file": args.sql_file,
        "sql_source": sql_source,
        "reexec_needed": str(Path(config["python_bin"]).parent.parent.resolve() != current_python()),
    }


def main() -> int:
    args = parse_args()

    try:
        sql = resolve_sql(args)
        config = build_effective_config(args, load_config(CONFIG_PATH))
    except ConfigError as exc:
        print(f"Configuration error: {exc}", file=sys.stderr)
        return 2

    if args.dry_run:
        print(json.dumps(dry_run_payload(args, config), indent=2, ensure_ascii=False))
        return 0

    ensure_configured_python(config)

    try:
        rows = normalize_rows(fetch_rows(sql, config))
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 3
    except Exception as exc:  # pragma: no cover - protects the CLI from SDK errors
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
