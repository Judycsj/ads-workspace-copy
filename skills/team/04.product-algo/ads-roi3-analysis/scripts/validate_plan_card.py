# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pyyaml>=6.0",
# ]
# ///
"""Validate a ROI3 analysis plan card."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

import yaml


QUESTION_TYPES = {"校验", "读数", "诊断", "探索", "评估", "决策"}
LEVERS = {"发多少", "发给谁", "怎么发", "怎么控"}
LAYERS = {"效果指标层", "控制器层", "模型层", "策略层", "数据口径层"}
EVIDENCE = {"AB实验", "观测对比", "线上trace", "模型外推"}
VALUE_METRICS = {"advv", "broad_gmv", "platform_gmv", "guardrail", "cost_ratio"}
AUDIENCES = {"自己", "PM", "老板"}
REPORT_VERSIONS = {"全量版", "决策版", "三句话版"}
TRACKS = {"快速", "标准", "完整"}

REQUIRED_PATHS = [
    ("decision",),
    ("question",),
    ("axes", "question_type"),
    ("axes", "layer"),
    ("axes", "evidence"),
    ("scope", "time_window"),
    ("scope", "regions"),
    ("caliber", "value_metric"),
    ("audience",),
    ("output", "report_version"),
    ("output", "archive_path"),
    ("route", "entry_id"),
    ("track",),
]


def get_path(data: dict[str, Any], path: tuple[str, ...]) -> Any:
    cur: Any = data
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return None
        cur = cur[key]
    return cur


def is_blank(value: Any, *, allow_placeholders: bool = False) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        text = value.strip()
        if allow_placeholders and text.startswith("<") and text.endswith(">"):
            return False
        return not text or (text.startswith("<") and text.endswith(">"))
    if isinstance(value, list):
        return not value
    return False


def check_enum(
    errors: list[str],
    label: str,
    value: Any,
    allowed: set[str],
    *,
    allow_placeholders: bool = False,
) -> None:
    if is_blank(value, allow_placeholders=allow_placeholders):
        return
    if allow_placeholders and isinstance(value, str) and value.startswith("<") and value.endswith(">"):
        return
    if value not in allowed:
        errors.append(f"{label}={value!r} not in {sorted(allowed)}")


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError("plan card must be a YAML mapping")
    return data


def validate(data: dict[str, Any], *, allow_placeholders: bool = False) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    for path in REQUIRED_PATHS:
        value = get_path(data, path)
        if is_blank(value, allow_placeholders=allow_placeholders):
            errors.append(f"missing required field: {'.'.join(path)}")

    axes = data.get("axes") or {}
    caliber = data.get("caliber") or {}
    output = data.get("output") or {}

    check_enum(errors, "axes.question_type", axes.get("question_type"), QUESTION_TYPES, allow_placeholders=allow_placeholders)
    check_enum(errors, "axes.lever", axes.get("lever"), LEVERS, allow_placeholders=allow_placeholders)
    check_enum(errors, "axes.layer", axes.get("layer"), LAYERS, allow_placeholders=allow_placeholders)
    check_enum(errors, "axes.evidence", axes.get("evidence"), EVIDENCE, allow_placeholders=allow_placeholders)
    check_enum(errors, "caliber.value_metric", caliber.get("value_metric"), VALUE_METRICS, allow_placeholders=allow_placeholders)
    check_enum(errors, "audience", data.get("audience"), AUDIENCES, allow_placeholders=allow_placeholders)
    check_enum(errors, "output.report_version", output.get("report_version"), REPORT_VERSIONS, allow_placeholders=allow_placeholders)
    check_enum(errors, "track", data.get("track"), TRACKS, allow_placeholders=allow_placeholders)

    question_type = axes.get("question_type")
    if question_type in {"探索", "评估", "决策"} and is_blank(axes.get("lever"), allow_placeholders=allow_placeholders):
        errors.append("axes.lever is required for 探索/评估/决策")
    if question_type in {"诊断", "校验"} and is_blank(axes.get("layer"), allow_placeholders=allow_placeholders):
        errors.append("axes.layer is required for 诊断/校验")
    if caliber.get("multi_caliber") is not True and data.get("audience") == "老板":
        warnings.append("老板 audience usually needs caliber.multi_caliber=true for high-stakes decisions")
    if data.get("track") == "完整" and is_blank(get_path(data, ("hypothesis", "kill_criteria")), allow_placeholders=allow_placeholders):
        errors.append("hypothesis.kill_criteria is required for 完整 track")

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan_card", type=Path)
    parser.add_argument("--allow-placeholders", action="store_true", help="Allow <...> template placeholders.")
    args = parser.parse_args()

    try:
        data = load_yaml(args.plan_card)
        errors, warnings = validate(data, allow_placeholders=args.allow_placeholders)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    for warning in warnings:
        print(f"WARN: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: {args.plan_card}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
