#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "PyYAML>=6.0",
# ]
# ///
"""Analyze Ads AB experiment reports exported from sp-ab get-report.py.

The script intentionally accepts loose JSON shapes because AB report exports vary:
- sp-ab legacy JSON: {"data": {"header": "...", "body": [...], "relative": [...]}}
- row JSON: [{"abtest_group": "...", "metric": ...}, ...]
- nested row JSON: {"rows": [...]}, {"data": {"rows": [...]}}
"""

from __future__ import annotations

import argparse
import ast
import json
import math
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import yaml


DEFAULT_NOISE_BAND_PCT = 0.5


@dataclass
class MetricResult:
    name: str
    segment: dict[str, str]
    value_pct: float | None
    direction: str
    movement: str
    meets_expectation: bool | None
    unit: str = "%"
    guardrail_status: str | None = None
    diagnostic: bool = False
    decision_role: str = "secondary"
    notes: list[str] = field(default_factory=list)
    daily: dict[str, Any] = field(default_factory=dict)
    market_gap_pct: float | None = None


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    if not isinstance(data, dict):
        raise ValueError(f"Config must be a YAML object: {path}")
    return data


def load_json(path: Path | None) -> Any:
    if path is None:
        return None
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def normalize_key(key: Any) -> str:
    return re.sub(r"[^a-z0-9]+", "", str(key).strip().lower())


def row_key_map(row: dict[str, Any]) -> dict[str, str]:
    return {normalize_key(k): k for k in row.keys()}


def get_ci(row: dict[str, Any], names: Iterable[str], default: Any = None) -> Any:
    key_map = row_key_map(row)
    for name in names:
        key = key_map.get(normalize_key(name))
        if key is not None:
            return row.get(key)
    return default


def parse_pipe_rows(header: str, rows: list[str]) -> list[dict[str, str]]:
    headers = [h.strip() for h in header.split("||")]
    parsed: list[dict[str, str]] = []
    for row in rows:
        values = [v.strip() for v in str(row).split("||")]
        parsed.append(dict(zip(headers, values)))
    return parsed


def find_row_list(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list) and all(isinstance(x, dict) for x in payload):
        return payload
    if not isinstance(payload, dict):
        return []

    preferred_keys = ("rows", "records", "items", "list", "result")
    for key in preferred_keys:
        value = payload.get(key)
        if isinstance(value, list) and all(isinstance(x, dict) for x in value):
            return value
        if isinstance(value, dict):
            nested = find_row_list(value)
            if nested:
                return nested

    data = payload.get("data")
    if isinstance(data, dict):
        nested = find_row_list(data)
        if nested:
            return nested

    for value in payload.values():
        if isinstance(value, dict):
            nested = find_row_list(value)
            if nested:
                return nested
    return []


def parse_report(payload: Any) -> dict[str, list[dict[str, Any]]]:
    """Return absolute and relative rows from known AB report JSON shapes."""
    if isinstance(payload, dict):
        data = payload.get("data")
        if isinstance(data, dict) and data.get("header"):
            header = str(data.get("header") or "")
            absolute = parse_pipe_rows(header, data.get("body") or [])
            relative = parse_pipe_rows(header, data.get("relative") or [])
            return {"absolute": absolute, "relative": relative}

    rows = find_row_list(payload)
    return {"absolute": rows, "relative": []}


def parse_number(value: Any) -> float | None:
    if value is None:
        return None
    if isinstance(value, bool):
        return float(value)
    if isinstance(value, (int, float)):
        if math.isnan(float(value)) or math.isinf(float(value)):
            return None
        return float(value)
    text = str(value).strip()
    if not text or text in {"-", "--", "null", "None", "nan", "NaN"}:
        return None
    text = text.replace(",", "").replace("％", "%")
    text = re.sub(r"^\+", "", text)
    if text.endswith("%"):
        text = text[:-1].strip()
    try:
        return float(text)
    except ValueError:
        match = re.search(r"[-+]?\d+(?:\.\d+)?", text)
        return float(match.group(0)) if match else None


def parse_uplift_pct(value: Any, scale: str = "auto") -> float | None:
    number = parse_number(value)
    if number is None:
        return None
    raw = str(value).strip() if value is not None else ""
    if raw.endswith("%") or raw.endswith("％"):
        return number
    if scale == "fraction":
        return number * 100
    if scale == "percent":
        return number
    if abs(number) <= 1:
        return number * 100
    return number


class FormulaEvaluator(ast.NodeVisitor):
    def __init__(self, row: dict[str, Any], scale: str, value_mode: str = "uplift"):
        self.row = row
        self.scale = scale
        self.value_mode = value_mode

    def visit_Expression(self, node: ast.Expression) -> float:
        return self.visit(node.body)

    def visit_BinOp(self, node: ast.BinOp) -> float:
        left = self.visit(node.left)
        right = self.visit(node.right)
        if isinstance(node.op, ast.Add):
            return left + right
        if isinstance(node.op, ast.Sub):
            return left - right
        if isinstance(node.op, ast.Mult):
            return left * right
        if isinstance(node.op, ast.Div):
            return left / right if right != 0 else math.nan
        raise ValueError("Unsupported formula operator")

    def visit_UnaryOp(self, node: ast.UnaryOp) -> float:
        value = self.visit(node.operand)
        if isinstance(node.op, ast.USub):
            return -value
        if isinstance(node.op, ast.UAdd):
            return value
        raise ValueError("Unsupported unary operator")

    def visit_Name(self, node: ast.Name) -> float:
        value = get_ci(self.row, [node.id])
        parsed = parse_number(value) if self.value_mode == "number" else parse_uplift_pct(value, self.scale)
        if parsed is None:
            raise ValueError(f"Missing formula input: {node.id}")
        return parsed

    def visit_Constant(self, node: ast.Constant) -> float:
        if isinstance(node.value, (int, float)):
            return float(node.value)
        raise ValueError("Unsupported formula constant")

    def generic_visit(self, node: ast.AST) -> float:
        raise ValueError(f"Unsupported formula syntax: {type(node).__name__}")


def eval_formula(formula: str, row: dict[str, Any], scale: str, value_mode: str = "uplift") -> float | None:
    try:
        tree = ast.parse(formula, mode="eval")
        value = FormulaEvaluator(row, scale, value_mode=value_mode).visit(tree)
        if math.isnan(value) or math.isinf(value):
            return None
        return value
    except Exception:
        return None


def direct_metric_value(row: dict[str, Any], metric: dict[str, Any], scale: str) -> float | None:
    names = [metric.get("name", "")]
    names.extend(metric.get("aliases") or [])
    if metric.get("source_metric"):
        names.append(metric.get("source_metric"))
    names.extend(metric.get("source_aliases") or [])
    value = get_ci(row, names)
    return parse_uplift_pct(value, scale)


def metric_value(row: dict[str, Any], metric: dict[str, Any], scale: str, allow_formula: bool = True) -> float | None:
    parsed = direct_metric_value(row, metric, scale)
    if parsed is not None:
        return parsed
    formula = metric.get("formula")
    if formula and allow_formula:
        return eval_formula(str(formula), row, scale)
    return None


def dimension_fields(row: dict[str, Any], config: dict[str, Any]) -> set[str]:
    selectors = config.get("selectors") or {}
    fields = {
        selectors.get("group_field", "abtest_group"),
        "ab_group",
        "abtest_group",
        "group_name",
        "ab_group_prefix",
        "abtest_region",
        "region",
        "country",
        "pricing_type",
    }
    fields.update(selectors.get("date_fields") or [])
    fields.update(selectors.get("segment_fields") or [])
    for key, value in row.items():
        key_norm = normalize_key(key)
        if key_norm.endswith("tier") or key_norm in {"targetfeature", "mainproducttype", "cardtype", "vouchertype"}:
            fields.add(key)
        elif parse_number(value) is None:
            fields.add(key)
    return {f for f in fields if f}


def dimensions_compatible(source: dict[str, Any], candidate: dict[str, Any], config: dict[str, Any]) -> bool:
    group_fields = {"ab_group", "abtest_group", "group_name", "ab_group_prefix"}
    for field_name in dimension_fields(source, config):
        if field_name in group_fields:
            continue
        source_value = get_ci(source, [field_name])
        candidate_value = get_ci(candidate, [field_name])
        if source_value in (None, "") or candidate_value in (None, ""):
            continue
        if str(source_value) != str(candidate_value):
            return False
    return True


def group_value(row: dict[str, Any], config: dict[str, Any]) -> str:
    selectors = config.get("selectors") or {}
    group_field = selectors.get("group_field", "abtest_group")
    return str(get_ci(row, [group_field, "ab_group", "abtest_group"], ""))


def is_control_row(row: dict[str, Any]) -> bool:
    labels = " ".join(str(get_ci(row, [name], "")) for name in ("group_name", "ab_group_prefix")).lower()
    return any(token in labels for token in ("control", "base", "baseline"))


def find_absolute_pair(
    row: dict[str, Any],
    absolute_rows: list[dict[str, Any]],
    config: dict[str, Any],
) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    treatment_group = group_value(row, config)
    treatment_candidates = [
        candidate
        for candidate in absolute_rows
        if group_value(candidate, config) == treatment_group and dimensions_compatible(row, candidate, config)
    ]
    treatment = treatment_candidates[0] if treatment_candidates else None
    if treatment is None:
        return None, None

    control_candidates = [
        candidate
        for candidate in absolute_rows
        if group_value(candidate, config) != treatment_group and dimensions_compatible(row, candidate, config)
    ]
    preferred = [candidate for candidate in control_candidates if is_control_row(candidate)]
    control = (preferred or control_candidates or [None])[0]
    return treatment, control


def ratio_uplift_from_absolute(
    row: dict[str, Any],
    metric: dict[str, Any],
    absolute_rows: list[dict[str, Any]],
    config: dict[str, Any],
) -> float | None:
    formula = metric.get("formula")
    if not formula or not absolute_rows:
        return None
    treatment, control = find_absolute_pair(row, absolute_rows, config)
    if not treatment or not control:
        return None
    treatment_value = eval_formula(str(formula), treatment, "percent", value_mode="number")
    control_value = eval_formula(str(formula), control, "percent", value_mode="number")
    if treatment_value is None or control_value in (None, 0):
        return None
    return (treatment_value / control_value - 1) * 100


def absolute_diff_pct_points_from_absolute(
    row: dict[str, Any],
    metric: dict[str, Any],
    absolute_rows: list[dict[str, Any]],
    config: dict[str, Any],
) -> float | None:
    source_metric = metric.get("source_metric") or metric.get("name")
    if not source_metric or not absolute_rows:
        return None
    treatment, control = find_absolute_pair(row, absolute_rows, config)
    if not treatment or not control:
        return None

    names = [source_metric]
    names.extend(metric.get("source_aliases") or metric.get("aliases") or [])
    treatment_value = parse_number(get_ci(treatment, names))
    control_value = parse_number(get_ci(control, names))
    if treatment_value is None or control_value is None:
        return None
    return (treatment_value - control_value) * 100


def metric_value_from_context(
    row: dict[str, Any],
    metric: dict[str, Any],
    scale: str,
    allow_formula: bool,
    absolute_rows: list[dict[str, Any]],
    config: dict[str, Any],
) -> float | None:
    if metric.get("formula_mode") == "ratio_uplift":
        ratio_value = ratio_uplift_from_absolute(row, metric, absolute_rows, config)
        if ratio_value is not None:
            return ratio_value
    if metric.get("formula_mode") == "absolute_diff_pct_points":
        diff_value = absolute_diff_pct_points_from_absolute(row, metric, absolute_rows, config)
        if diff_value is not None:
            return diff_value
    direct = direct_metric_value(row, metric, scale)
    if direct is not None:
        return direct
    formula = metric.get("formula")
    if formula and allow_formula:
        return eval_formula(str(formula), row, scale)
    return None


def selected_metrics(config: dict[str, Any]) -> list[dict[str, Any]]:
    exp_type = (config.get("experiment") or {}).get("type", "traffic")
    metrics_cfg = config.get("metrics") or {}

    if metrics_cfg.get("core"):
        core = list(metrics_cfg.get("core") or [])
    elif exp_type == "bidding":
        core = list(metrics_cfg.get("bidding_core") or [])
    elif exp_type == "voucher" and metrics_cfg.get("voucher_core"):
        core = list(metrics_cfg.get("voucher_core") or [])
    else:
        core = list(metrics_cfg.get("traffic_core") or [])

    guardrails: list[dict[str, Any]] = []
    for metric in metrics_cfg.get("guardrail") or []:
        applies = metric.get("applies_to")
        if applies and exp_type not in applies:
            continue
        item = dict(metric)
        item["guardrail"] = True
        guardrails.append(item)

    return core + guardrails


def segment_for_row(row: dict[str, Any], config: dict[str, Any]) -> dict[str, str]:
    selectors = config.get("selectors") or {}
    fields = [selectors.get("group_field", "abtest_group")]
    fields.extend(selectors.get("segment_fields") or [])
    segment: dict[str, str] = {}
    for field_name in fields:
        value = get_ci(row, [field_name])
        if value not in (None, ""):
            segment[field_name] = str(value)
    return segment


def segment_matches_scope(row: dict[str, Any], metric: dict[str, Any], config: dict[str, Any]) -> bool:
    scope = metric.get("scope")
    if scope not in {"overall", "target_pricing_type", "both", None}:
        return True
    pricing = str(get_ci(row, ["pricing_type"], "")).strip()
    if not pricing:
        return True
    target = {str(x) for x in (config.get("experiment") or {}).get("target_pricing_types") or []}
    overall_values = {"overall", "all", "total", "ALL", "Overall"}
    if scope == "overall":
        return pricing in overall_values
    if scope == "target_pricing_type":
        return pricing in target
    if scope == "both":
        return pricing in overall_values or pricing in target
    return True


def choose_analysis_rows(parsed: dict[str, list[dict[str, Any]]]) -> list[dict[str, Any]]:
    return parsed["relative"] or parsed["absolute"]


def direction_ok(value: float | None, direction: str, noise: float) -> bool | None:
    if value is None:
        return None
    if direction == "increase":
        return value > noise
    if direction == "decrease":
        return value < -noise
    if direction == "non_decrease":
        return value >= -noise
    if direction == "non_increase":
        return value <= noise
    if direction == "flat":
        return abs(value) <= noise
    return None


def base_movement(value: float | None, noise: float) -> str:
    if value is None:
        return "INCONCLUSIVE"
    if abs(value) < noise:
        return "FLAT"
    return "UP_CONFIDENT" if value > 0 else "DOWN_CONFIDENT"


def find_date_value(row: dict[str, Any], config: dict[str, Any]) -> str | None:
    selectors = config.get("selectors") or {}
    for field_name in selectors.get("date_fields") or ["grass_date", "date", "dt"]:
        value = get_ci(row, [field_name])
        if value not in (None, ""):
            return str(value)
    return None


def same_segment(left: dict[str, str], row: dict[str, Any], config: dict[str, Any]) -> bool:
    row_segment = segment_for_row(row, config)
    for key, value in left.items():
        if key not in row_segment:
            continue
        if row_segment[key] != value:
            return False
    return True


def daily_stats(
    rows: list[dict[str, Any]],
    absolute_rows: list[dict[str, Any]],
    metric: dict[str, Any],
    result_segment: dict[str, str],
    config: dict[str, Any],
    cumulative_value: float | None,
) -> dict[str, Any]:
    if not rows:
        return {}
    analysis = config.get("analysis") or {}
    noise = float(analysis.get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    scale = analysis.get("relative_value_scale", "auto")
    allow_formula = bool(metric.get("guardrail") or metric.get("allow_relative_formula"))
    values: list[tuple[str, float]] = []
    for row in rows:
        date_value = find_date_value(row, config)
        if not date_value or not same_segment(result_segment, row, config):
            continue
        value = metric_value_from_context(
            row,
            metric,
            scale,
            allow_formula=allow_formula,
            absolute_rows=absolute_rows,
            config=config,
        )
        if value is not None:
            values.append((date_value, value))

    values = sorted(values, key=lambda x: x[0])
    if not values:
        return {}

    sign = 1 if (cumulative_value or 0) >= 0 else -1
    aligned = [v for _, v in values if abs(v) < noise or v * sign > 0]
    consistency = len(aligned) / len(values)
    abs_sum = sum(abs(v) for _, v in values)
    max_day = max(values, key=lambda x: abs(x[1]))
    dominance = (abs(max_day[1]) / abs_sum * 100) if abs_sum else 0.0

    dod_jump = None
    if len(values) >= 2:
        prev = values[-2][1]
        last = values[-1][1]
        denom = max(abs(prev), noise)
        dod_jump = abs(last - prev) / denom * 100

    return {
        "days": len(values),
        "values": [{"date": d, "uplift_pct": v} for d, v in values],
        "direction_consistency": consistency,
        "single_day": {"date": max_day[0], "uplift_pct": max_day[1], "dominance_pct": dominance},
        "day_over_day_jump_pct": dod_jump,
    }


def adjust_movement_with_daily(movement: str, stats: dict[str, Any], config: dict[str, Any]) -> str:
    if movement in {"FLAT", "INCONCLUSIVE"}:
        return movement
    if not stats:
        return "INCONCLUSIVE"

    analysis = config.get("analysis") or {}
    min_consistency = float(analysis.get("min_direction_consistency", 0.6))
    jump_threshold = float(analysis.get("day_over_day_jump_pct", 30))
    dominance_threshold = float(analysis.get("single_day_dominance_pct", 50))

    dominance = ((stats.get("single_day") or {}).get("dominance_pct")) or 0
    if dominance >= dominance_threshold:
        return "SINGLE_DAY_DRIVEN"

    consistency = stats.get("direction_consistency")
    jump = stats.get("day_over_day_jump_pct")
    volatile = False
    if consistency is not None and consistency < min_consistency:
        volatile = True
    if jump is not None and jump >= jump_threshold:
        volatile = True
    if volatile:
        return "UP_VOLATILE" if movement.startswith("UP") else "DOWN_VOLATILE"
    return movement


def guardrail_status(result: MetricResult, metric: dict[str, Any], noise: float) -> str | None:
    if not metric.get("guardrail"):
        return None
    value = result.value_pct
    if value is None:
        return "UNKNOWN"

    name = metric.get("name")
    if metric.get("fail_decrease_pp") is not None:
        threshold = float(metric.get("fail_decrease_pp"))
        if value < -threshold:
            return "FAIL"
        if value < -noise:
            return "PASS_UNSTABLE"
        return "PASS"

    if metric.get("fail_decrease_pct") is not None:
        threshold = float(metric.get("fail_decrease_pct"))
        if value < -threshold:
            return "FAIL"
        if value < 0:
            return "PASS_UNSTABLE"
        return "PASS_UNSTABLE" if result.movement in {"UP_VOLATILE", "DOWN_VOLATILE", "SINGLE_DAY_DRIVEN"} else "PASS"

    if name == "bad_query_rate":
        fail_threshold = float(metric.get("fail_deterioration_pct", 1.0))
        if value > fail_threshold:
            return "FAIL"
        if value > noise:
            return "DISCUSS"
        return "PASS_UNSTABLE" if result.movement.endswith("VOLATILE") else "PASS"

    if "pass_min" in metric:
        pass_min = float(metric.get("pass_min", 0))
        if value > pass_min:
            if abs(value - pass_min) <= noise:
                return "PASS_UNSTABLE"
            return "PASS_UNSTABLE" if result.movement in {"UP_VOLATILE", "DOWN_VOLATILE", "SINGLE_DAY_DRIVEN"} else "PASS"
        if abs(value - pass_min) <= noise:
            return "DISCUSS"
        return "FAIL"

    ok = result.meets_expectation
    if ok is None:
        return "UNKNOWN"
    if ok:
        return "PASS_UNSTABLE" if result.movement in {"UP_VOLATILE", "DOWN_VOLATILE", "SINGLE_DAY_DRIVEN"} else "PASS"
    if value is not None and abs(value) <= noise:
        return "DISCUSS"
    return "FAIL"


def find_market_gap(
    result: MetricResult,
    metric: dict[str, Any],
    rows: list[dict[str, Any]],
    config: dict[str, Any],
) -> float | None:
    selectors = config.get("selectors") or {}
    group_field = selectors.get("group_field", "abtest_group")
    baseline_values = {str(v) for v in selectors.get("market_baseline_values") or []}
    if not baseline_values:
        return None
    scale = (config.get("analysis") or {}).get("relative_value_scale", "auto")
    allow_formula = bool(metric.get("guardrail") or metric.get("allow_relative_formula"))
    for row in rows:
        group = str(get_ci(row, [group_field], ""))
        if group not in baseline_values:
            continue
        row_segment = segment_for_row(row, config)
        compatible = True
        for key, value in result.segment.items():
            if key == group_field or key not in row_segment:
                continue
            if row_segment[key] != value:
                compatible = False
                break
        if not compatible:
            continue
        baseline_value = metric_value(row, metric, scale, allow_formula=allow_formula)
        if baseline_value is not None and result.value_pct is not None:
            return result.value_pct - baseline_value
    return None


def analyze(config: dict[str, Any], report_payload: Any, daily_payload: Any | None) -> dict[str, Any]:
    parsed = parse_report(report_payload)
    daily_parsed = parse_report(daily_payload) if daily_payload is not None else {"absolute": [], "relative": []}
    rows = choose_analysis_rows(parsed)
    daily_rows = choose_analysis_rows(daily_parsed)
    period_uses_relative = bool(parsed.get("relative"))

    analysis_cfg = config.get("analysis") or {}
    noise = float(analysis_cfg.get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    scale = analysis_cfg.get("relative_value_scale", "auto")

    results: list[MetricResult] = []
    for metric in selected_metrics(config):
        direction = metric.get("direction", "increase")
        matched = 0
        allow_formula = (not period_uses_relative) or bool(metric.get("guardrail") or metric.get("allow_relative_formula"))
        for row in rows:
            if not segment_matches_scope(row, metric, config):
                continue
            value = metric_value_from_context(
                row,
                metric,
                scale,
                allow_formula=allow_formula,
                absolute_rows=parsed.get("absolute") or [],
                config=config,
            )
            if value is None:
                continue
            matched += 1
            segment = segment_for_row(row, config)
            movement = base_movement(value, noise)
            stats = daily_stats(daily_rows, daily_parsed.get("absolute") or [], metric, segment, config, value)
            movement = adjust_movement_with_daily(movement, stats, config)
            result = MetricResult(
                name=str(metric.get("name")),
                segment=segment,
                value_pct=value,
                direction=direction,
                movement=movement,
                meets_expectation=direction_ok(value, direction, noise),
                unit=str(metric.get("unit", "%")),
                diagnostic=bool(metric.get("diagnostic")),
                decision_role=str(metric.get("decision_role", "diagnostic" if metric.get("diagnostic") else "secondary")),
                daily=stats,
            )
            result.guardrail_status = guardrail_status(result, metric, noise)
            gap = find_market_gap(result, metric, rows, config)
            if gap is not None:
                result.market_gap_pct = gap
                if abs(gap) > noise:
                    result.notes.append(f"单桶与大盘差异 {gap:+.2f}pp，超过 {noise:.2f}% 噪声带")
            results.append(result)

        if matched == 0 and metric.get("required"):
            results.append(
                MetricResult(
                    name=str(metric.get("name")),
                    segment={},
                    value_pct=None,
                    direction=direction,
                    movement="INCONCLUSIVE",
                    meets_expectation=None,
                    unit=str(metric.get("unit", "%")),
                    guardrail_status="UNKNOWN" if metric.get("guardrail") else None,
                    diagnostic=bool(metric.get("diagnostic")),
                    decision_role=str(metric.get("decision_role", "diagnostic" if metric.get("diagnostic") else "secondary")),
                    notes=["required metric missing from report"],
                )
            )

    annotate_advv_999(results, config)
    annotate_bidding_tail_bucket_tradeoff(results, config)
    annotate_traffic_rev_advv_balance(results, config)
    return build_report(config, results, parsed, daily_parsed)


def annotate_advv_999(results: list[MetricResult], config: dict[str, Any]) -> None:
    noise = float((config.get("analysis") or {}).get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    advv_results = [r for r in results if r.name in {"advv_cost", "advv"} and r.value_pct is not None]
    advv_999_results = [r for r in results if r.name in {"advv_999", "advv_cost_999"} and r.value_pct is not None]
    advv_per_imp_results = [r for r in results if r.name in {"advv_per_imp", "advv per imp"} and r.value_pct is not None]
    advv_999_per_imp_results = [
        r for r in results if r.name in {"advv_999_per_imp", "advv_cost_999_per_imp"} and r.value_pct is not None
    ]

    for advv in advv_results:
        counterpart = next((r for r in advv_999_results if r.segment == advv.segment), None)
        if counterpart is None:
            continue
        raw = advv.value_pct
        clipped = counterpart.value_pct
        if raw is None or clipped is None:
            continue
        if abs(raw) <= noise:
            advv.notes.append(f"advv_999={clipped:+.2f}%，raw ADVV 本身在噪声带内")
        elif abs(clipped) <= noise:
            advv.notes.append(f"advv_999={clipped:+.2f}% 在噪声带内，raw ADVV={raw:+.2f}% 可能受尾部样本拉动")
            counterpart.notes.append(f"raw ADVV={raw:+.2f}% 但 advv_999 在噪声带内，用于提示 ADVV 波动风险")
        elif raw * clipped > 0:
            ratio = abs(clipped) / max(abs(raw), noise)
            if ratio < 0.5:
                advv.notes.append(f"advv_999={clipped:+.2f}% 同向但幅度明显更小，raw ADVV 可能有尾部放大")
            else:
                advv.notes.append(f"advv_999={clipped:+.2f}% 与 raw ADVV 同向，ADVV 变化更可信")
        else:
            advv.notes.append(f"advv_999={clipped:+.2f}% 与 raw ADVV={raw:+.2f}% 背离，需要检查 ADVV 波动来源")

    for advv_per_imp in advv_per_imp_results:
        counterpart = next((r for r in advv_999_per_imp_results if r.segment == advv_per_imp.segment), None)
        if counterpart is None:
            continue
        raw = advv_per_imp.value_pct
        clipped = counterpart.value_pct
        if raw is None or clipped is None:
            continue
        if abs(raw) <= noise:
            advv_per_imp.notes.append(f"advv_999_per_imp={clipped:+.2f}%，raw advv per imp 本身在噪声带内")
        elif abs(clipped) <= noise:
            advv_per_imp.notes.append(
                f"advv_999_per_imp={clipped:+.2f}% 在噪声带内，raw advv per imp={raw:+.2f}% 可能受尾部样本拉动"
            )
            counterpart.notes.append(
                f"raw advv per imp={raw:+.2f}% 但 advv_999_per_imp 在噪声带内，用于提示 per-imp ADVV 波动风险"
            )
        elif raw * clipped > 0:
            ratio = abs(clipped) / max(abs(raw), noise)
            if ratio < 0.5:
                advv_per_imp.notes.append(
                    f"advv_999_per_imp={clipped:+.2f}% 同向但幅度明显更小，raw advv per imp 可能有尾部放大"
                )
            else:
                advv_per_imp.notes.append(
                    f"advv_999_per_imp={clipped:+.2f}% 与 raw advv per imp 同向，per-imp ADVV 变化更可信"
                )
        else:
            advv_per_imp.notes.append(
                f"advv_999_per_imp={clipped:+.2f}% 与 raw advv per imp={raw:+.2f}% 背离，需要检查 per-imp ADVV 波动来源"
            )


def annotate_bidding_tail_bucket_tradeoff(results: list[MetricResult], config: dict[str, Any]) -> None:
    if (config.get("experiment") or {}).get("type") != "bidding":
        return

    noise = float((config.get("analysis") or {}).get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    by_segment: dict[tuple[tuple[str, str], ...], list[MetricResult]] = {}
    for result in results:
        key = tuple(sorted(result.segment.items()))
        by_segment.setdefault(key, []).append(result)

    primary_names = {"cpm", "advv_per_imp", "advv per imp"}
    constraint_names = {
        "fulfilled_rev_pct_1d",
        "underbid_rev_pct_1d",
        "overbid_rev_pct_1d",
        "no_gmv_rev_pct_1d",
    }
    secondary_names = {"rev_usd", "net_rev_after_rebate", "advv_cost", "advv"}

    for segment_results in by_segment.values():
        primary = [r for r in segment_results if r.name in primary_names and r.value_pct is not None]
        constraints = [r for r in segment_results if r.name in constraint_names and r.value_pct is not None]
        secondary = [r for r in segment_results if r.name in secondary_names and r.value_pct is not None]
        if not secondary:
            continue

        primary_improved = bool(primary) and any((r.value_pct or 0) > noise for r in primary)
        primary_regressed = any((r.value_pct or 0) < -noise for r in primary)
        constraint_failed = any(
            ((r.name == "fulfilled_rev_pct_1d" and (r.value_pct or 0) < -noise)
             or (r.name != "fulfilled_rev_pct_1d" and (r.value_pct or 0) > noise))
            for r in constraints
        )

        secondary_positive = [r for r in secondary if (r.value_pct or 0) > noise]
        secondary_negative = [r for r in secondary if (r.value_pct or 0) < -noise]

        if secondary_positive and (not primary_improved or primary_regressed or constraint_failed):
            note = "尾号实验 raw rev/ADVV 收益可能来自抢 imp 或桶间 cannibalization，需优先以 cpm、advv per imp 和客户约束判断"
            for result in secondary_positive:
                if note not in result.notes:
                    result.notes.append(note)

        if secondary_negative and not primary_regressed and not constraint_failed:
            note = "该指标为辅助收益/抢量诊断项；若单位效率和客户约束健康，不应单独作为 RED 依据"
            for result in secondary_negative:
                if note not in result.notes:
                    result.notes.append(note)


def annotate_traffic_rev_advv_balance(results: list[MetricResult], config: dict[str, Any]) -> None:
    exp_type = (config.get("experiment") or {}).get("type", "traffic")
    if exp_type not in {"traffic", "model", "recall"}:
        return

    analysis = config.get("analysis") or {}
    noise = float(analysis.get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    gap_threshold = float(analysis.get("rev_advv_gap_risk_pct", noise))
    min_consistency = float(analysis.get("min_direction_consistency", 0.6))

    by_segment: dict[tuple[tuple[str, str], ...], list[MetricResult]] = {}
    for result in results:
        key = tuple(sorted(result.segment.items()))
        by_segment.setdefault(key, []).append(result)

    rev_names = {"ads_revenue_usd", "rev", "rev_usd", "revenue_usd"}
    advv_names = {"advv_cost_1d", "advv", "advv_cost"}

    for segment_results in by_segment.values():
        rev = next((r for r in segment_results if r.name in rev_names and r.value_pct is not None), None)
        advv = next((r for r in segment_results if r.name in advv_names and r.value_pct is not None), None)

        for result in [r for r in (rev, advv) if r is not None]:
            annotate_positive_day_count(result, noise, min_consistency)

        if rev is None or advv is None or rev.value_pct is None or advv.value_pct is None:
            continue

        gap = rev.value_pct - advv.value_pct
        if rev.value_pct > noise and advv.value_pct <= noise:
            note = (
                f"rev={rev.value_pct:+.2f}% 正向但 advv={advv.value_pct:+.2f}% 未同步明显正向，"
                "存在超收风险"
            )
        elif rev.value_pct > noise and advv.value_pct > noise and gap > gap_threshold:
            note = f"rev uplift 比 advv 高 {gap:+.2f}pp，存在超收风险，需要确认是否超收"
        else:
            note = ""

        if note:
            for result in (rev, advv):
                if note not in result.notes:
                    result.notes.append(note)


def annotate_positive_day_count(result: MetricResult, noise: float, min_consistency: float) -> None:
    values = [item.get("uplift_pct") for item in (result.daily.get("values") or [])]
    values = [float(v) for v in values if v is not None]
    if not values:
        return

    positive_days = sum(1 for value in values if value > noise)
    total_days = len(values)
    note = f"by-day 正向天数 {positive_days}/{total_days}"
    if note not in result.notes:
        result.notes.append(note)

    if result.value_pct is not None and result.value_pct > noise and positive_days / total_days < min_consistency:
        risk_note = "整体正向但 by-day 正向天数未达到大部分天正向，可能由单日拉动"
        if risk_note not in result.notes:
            result.notes.append(risk_note)
        if result.movement == "UP_CONFIDENT":
            result.movement = "UP_VOLATILE"


def build_report(
    config: dict[str, Any],
    results: list[MetricResult],
    parsed: dict[str, list[dict[str, Any]]],
    daily_parsed: dict[str, list[dict[str, Any]]],
) -> dict[str, Any]:
    core = [r for r in results if r.guardrail_status is None and not r.diagnostic]
    diagnostic = [r for r in results if r.guardrail_status is None and r.diagnostic]
    guardrails = [r for r in results if r.guardrail_status is not None]

    red_reasons: list[str] = []
    yellow_reasons: list[str] = []

    strong_decision_roles = {"primary", "constraint"}
    noise = float((config.get("analysis") or {}).get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    for r in core:
        if r.meets_expectation is False and r.value_pct is not None:
            if abs(r.value_pct) >= noise:
                if r.decision_role in strong_decision_roles:
                    red_reasons.append(f"{r.name} 不符合预期 ({fmt_value(r.value_pct, r.unit)})")
                else:
                    yellow_reasons.append(
                        f"{r.name} 辅助收益指标不符合预期 ({fmt_value(r.value_pct, r.unit)})"
                    )
            else:
                yellow_reasons.append(f"{r.name} 未形成明确收益")
        if r.movement in {"UP_VOLATILE", "DOWN_VOLATILE", "SINGLE_DAY_DRIVEN", "INCONCLUSIVE"}:
            if r.movement == "SINGLE_DAY_DRIVEN" and r.decision_role in strong_decision_roles:
                red_reasons.append(f"{r.name} 由单日拉动，不满足大部分天正向要求")
            else:
                yellow_reasons.append(f"{r.name} 状态 {r.movement}")
        if any("超收风险" in note for note in r.notes):
            yellow_reasons.append(f"{r.name} rev/advv 关系存在超收风险")
        if any("未达到大部分天正向" in note for note in r.notes):
            yellow_reasons.append(f"{r.name} by-day 未达到大部分天正向")
        if r.market_gap_pct is not None and abs(r.market_gap_pct) > noise:
            yellow_reasons.append(f"{r.name} 单桶 vs 大盘差异明显")

    for r in guardrails:
        if r.guardrail_status == "FAIL":
            red_reasons.append(f"{r.name} guardrail FAIL ({fmt_value(r.value_pct, r.unit)})")
        elif r.guardrail_status in {"DISCUSS", "PASS_UNSTABLE", "UNKNOWN"}:
            yellow_reasons.append(f"{r.name} guardrail {r.guardrail_status}")

    if red_reasons:
        status = "RED"
        action = "建议暂停扩大流量，先确认指标口径和异常日期贡献。"
    elif yellow_reasons:
        status = "YELLOW"
        action = "建议继续观察并补充 by-day / 分桶解释，暂不机械通过。"
    else:
        status = "GREEN"
        action = "核心指标和 guardrail 当前符合预期，可以继续跟踪或进入下一步评审。"

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "experiment": config.get("experiment") or {},
        "analysis": config.get("analysis") or {},
        "input_rows": {
            "period_absolute": len(parsed.get("absolute") or []),
            "period_relative": len(parsed.get("relative") or []),
            "daily_absolute": len(daily_parsed.get("absolute") or []),
            "daily_relative": len(daily_parsed.get("relative") or []),
        },
        "summary": {
            "status": status,
            "action": action,
            "red_reasons": dedupe(red_reasons),
            "yellow_reasons": dedupe(yellow_reasons),
        },
        "core_metrics": [result_to_dict(r) for r in core],
        "diagnostic_metrics": [result_to_dict(r) for r in diagnostic],
        "guardrails": [result_to_dict(r) for r in guardrails],
    }


def dedupe(items: list[str]) -> list[str]:
    seen = set()
    output = []
    for item in items:
        if item not in seen:
            seen.add(item)
            output.append(item)
    return output


def result_to_dict(result: MetricResult) -> dict[str, Any]:
    return {
        "name": result.name,
        "segment": result.segment,
        "uplift_pct": result.value_pct,
        "unit": result.unit,
        "direction": result.direction,
        "movement": result.movement,
        "meets_expectation": result.meets_expectation,
        "guardrail_status": result.guardrail_status,
        "diagnostic": result.diagnostic,
        "decision_role": result.decision_role,
        "daily": result.daily,
        "market_gap_pct": result.market_gap_pct,
        "notes": result.notes,
    }


def fmt_value(value: float | None, unit: str = "%") -> str:
    if value is None:
        return "N/A"
    if unit == "pp":
        return f"{value:+.2f}pp"
    return f"{value:+.2f}%"


def fmt_pct(value: float | None) -> str:
    return fmt_value(value, "%")


def fmt_segment(segment: dict[str, str]) -> str:
    if not segment:
        return "overall"
    return ", ".join(f"{k}={v}" for k, v in segment.items())


def md_cell(value: Any) -> str:
    if value is None or value == "":
        return "-"
    text = str(value).replace("\n", "<br>")
    return text.replace("|", "\\|")


def render_summary_table(summary: dict[str, Any]) -> list[str]:
    rows = [
        ("状态", f"**{summary.get('status', 'UNKNOWN')}**"),
        ("建议动作", summary.get("action", "-")),
        ("RED 原因", "<br>".join(summary.get("red_reasons") or []) or "-"),
        ("YELLOW 原因", "<br>".join(summary.get("yellow_reasons") or []) or "-"),
    ]
    lines = ["| 项目 | 内容 |", "|------|------|"]
    for key, value in rows:
        lines.append(f"| {md_cell(key)} | {md_cell(value)} |")
    return lines


def render_metric_table(items: list[dict[str, Any]], include_guardrail: bool = False) -> list[str]:
    if include_guardrail:
        lines = ["| 指标 | 角色 | 分组 | uplift | 方向 | 状态 | Guardrail | 说明 |"]
        lines.append("|------|------|------|--------|------|------|-----------|------|")
    else:
        lines = ["| 指标 | 角色 | 分组 | uplift | 方向 | 状态 | 符合预期 | 说明 |"]
        lines.append("|------|------|------|--------|------|------|----------|------|")

    for item in items:
        notes = list(item.get("notes") or [])
        daily = item.get("daily") or {}
        if daily:
            consistency = daily.get("direction_consistency")
            if consistency is not None:
                notes.append(f"方向一致率 {consistency * 100:.0f}%")
            single = daily.get("single_day") or {}
            if single:
                notes.append(f"最大单日 {single.get('date')} 占比 {single.get('dominance_pct', 0):.0f}%")
        note_text = "<br>".join(notes) if notes else "-"
        if include_guardrail:
            lines.append(
                "| {name} | {role} | {segment} | {uplift} | {direction} | {movement} | {guardrail} | {notes} |".format(
                    name=md_cell(item["name"]),
                    role=md_cell(item.get("decision_role") or "guardrail"),
                    segment=md_cell(fmt_segment(item.get("segment") or {})),
                    uplift=fmt_value(item.get("uplift_pct"), item.get("unit", "%")),
                    direction=md_cell(item.get("direction") or "-"),
                    movement=md_cell(item.get("movement") or "-"),
                    guardrail=md_cell(item.get("guardrail_status") or "-"),
                    notes=md_cell(note_text),
                )
            )
        else:
            meets = item.get("meets_expectation")
            meets_text = "是" if meets is True else "否" if meets is False else "未知"
            lines.append(
                "| {name} | {role} | {segment} | {uplift} | {direction} | {movement} | {meets} | {notes} |".format(
                    name=md_cell(item["name"]),
                    role=md_cell(item.get("decision_role") or "secondary"),
                    segment=md_cell(fmt_segment(item.get("segment") or {})),
                    uplift=fmt_value(item.get("uplift_pct"), item.get("unit", "%")),
                    direction=md_cell(item.get("direction") or "-"),
                    movement=md_cell(item.get("movement") or "-"),
                    meets=md_cell(meets_text),
                    notes=md_cell(note_text),
                )
            )
    return lines


def render_daily_table(items: list[dict[str, Any]]) -> list[str]:
    lines = [
        "| 指标 | 分组 | 天数 | 方向一致率 | 最大单日 | 单日占比 | 昨日 vs 前日跳变 | 判断 |",
        "|------|------|------|------------|----------|----------|------------------|------|",
    ]
    row_count = 0
    for item in items:
        daily = item.get("daily") or {}
        if not daily:
            continue
        single = daily.get("single_day") or {}
        jump = daily.get("day_over_day_jump_pct")
        guardrail = item.get("guardrail_status")
        judgment = guardrail if guardrail else item.get("movement", "-")
        lines.append(
            "| {name} | {segment} | {days} | {consistency} | {date} | {dominance} | {jump} | {judgment} |".format(
                name=md_cell(item["name"]),
                segment=md_cell(fmt_segment(item.get("segment") or {})),
                days=md_cell(daily.get("days", 0)),
                consistency=f"{(daily.get('direction_consistency') or 0) * 100:.0f}%",
                date=md_cell(single.get("date", "-")),
                dominance=f"{single.get('dominance_pct', 0):.0f}%" if single else "-",
                jump=f"{jump:.0f}%" if jump is not None else "-",
                judgment=md_cell(judgment),
            )
        )
        row_count += 1
    if row_count == 0:
        lines.append("| by-day 数据 | overall | - | - | - | - | - | 未提供可匹配的 by-day 数据，无法判断波动来源 |")
    return lines


def render_market_gap_table(items: list[dict[str, Any]], noise_band_pct: float) -> list[str]:
    lines = [
        "| 指标 | 分组 | 单桶 - 大盘 | 判断 |",
        "|------|------|-------------|------|",
    ]
    row_count = 0
    for item in items:
        gap = item.get("market_gap_pct")
        if gap is None:
            continue
        judgment = "波动内" if abs(gap) <= noise_band_pct else "差异明显"
        lines.append(
            "| {name} | {segment} | {gap} | {judgment} |".format(
                name=md_cell(item["name"]),
                segment=md_cell(fmt_segment(item.get("segment") or {})),
                gap=fmt_pct(gap),
                judgment=judgment,
            )
        )
        row_count += 1
    if row_count == 0:
        lines.append("| all-bucket baseline | overall | - | 未找到 all-bucket baseline 行，无法做单桶 vs 大盘对比 |")
    return lines


def render_input_table(report: dict[str, Any]) -> list[str]:
    rows = report.get("input_rows") or {}
    table_rows = [
        ("period absolute rows", rows.get("period_absolute", 0)),
        ("period relative rows", rows.get("period_relative", 0)),
        ("daily absolute rows", rows.get("daily_absolute", 0)),
        ("daily relative rows", rows.get("daily_relative", 0)),
        ("generated_at", report.get("generated_at", "-")),
    ]
    lines = ["| 项目 | 值 |", "|------|----|"]
    for key, value in table_rows:
        lines.append(f"| {md_cell(key)} | {md_cell(value)} |")
    return lines


def render_markdown(report: dict[str, Any]) -> str:
    exp = report.get("experiment") or {}
    summary = report.get("summary") or {}
    lines = [
        f"# Ads 实验 Daily 分析 - {exp.get('name', 'unknown')}",
        "",
        "## 1. 总体结论",
        "",
    ]
    lines.extend(render_summary_table(summary))

    lines.extend(["", "## 2. 核心指标", ""])
    core = report.get("core_metrics") or []
    lines.extend(render_metric_table(core) if core else ["暂无核心指标结果。"])

    diagnostic = report.get("diagnostic_metrics") or []
    if diagnostic:
        lines.extend(["", "## 2.1 诊断指标", ""])
        lines.extend(render_metric_table(diagnostic))

    lines.extend(["", "## 3. Guardrail", ""])
    guardrails = report.get("guardrails") or []
    lines.extend(render_metric_table(guardrails, include_guardrail=True) if guardrails else ["暂无 guardrail 结果。"])

    lines.extend(["", "## 4. By Day 稳定性", ""])
    lines.extend(render_daily_table(core + diagnostic + guardrails))

    lines.extend(["", "## 5. 单桶 vs 大盘", ""])
    noise_band_pct = float((report.get("analysis") or {}).get("noise_band_pct", DEFAULT_NOISE_BAND_PCT))
    lines.extend(render_market_gap_table(core + diagnostic + guardrails, noise_band_pct))

    lines.extend(["", "## 6. 输入数据", ""])
    lines.extend(render_input_table(report))
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze Ads AB experiment report JSON.")
    parser.add_argument("--config", required=True, type=Path, help="Experiment monitor YAML config")
    parser.add_argument("--report-json", required=True, type=Path, help="Period report JSON from sp-ab")
    parser.add_argument("--daily-json", type=Path, help="Optional by-day report JSON from sp-ab")
    parser.add_argument("--output-json", type=Path, help="Write structured analysis JSON")
    parser.add_argument("--output-md", type=Path, help="Write Chinese Markdown report")
    args = parser.parse_args()

    config = load_yaml(args.config)
    report_payload = load_json(args.report_json)
    daily_payload = load_json(args.daily_json)
    report = analyze(config, report_payload, daily_payload)

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    markdown = render_markdown(report)
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)


if __name__ == "__main__":
    main()
