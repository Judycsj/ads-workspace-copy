# Ads DQC Report (ads-dqc-report) Guide

> **Language**: [English](ads-dqc-report.md) | [中文](ads-dqc-report.zh-CN.md)

Generates weekly DQC reports from SG ClickHouse for Performance DQC and Union Ads DQC. It compares the current week with the previous week, detects coverage drops of at least 5pp, and detects average-value drops of at least 10%.

**Trigger keywords**: "DQC report", "dqc weekly report", "DQC 周报", "weekly dqc", "performance dqc report", "union ads dqc report", "coverage weekly report", "average weekly report", "DQC anomaly fields"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with date parsing, ClickHouse query flow, anomaly rules, field exclusions, and report template |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| ClickHouse access | Network | Office network or VPN required to reach the SG ClickHouse cluster |
| ads-diagnose config | Local skill context | Reuses the SG ClickHouse connection configuration from `ads-diagnose` |

---

## Usage

### Scenario 1: Generate both weekly reports

> "Generate the DQC weekly report for week_end=2026-04-28"

The skill queries the latest available data, builds a 7-day current window and a 7-day previous window, then outputs both Performance DQC and Union Ads DQC sections.

### Scenario 2: Performance-only report

> "Generate performance dqc report for TH, ID, BR ending 2026-04-28"

Only the Performance DQC table is queried. The result includes data completeness checks, coverage anomalies, and average anomalies for the requested regions.

### Scenario 3: Explicit week window

> "DQC 周报，week_start=2026-04-22, week_end=2026-04-28, region=ALL"

The current week uses the explicit date range, while the previous week is computed by shifting that whole window backward by the same number of days.

### Scenario 4: Save report to the default directory

> "Generate weekly dqc and save it"

Unless a custom path is provided, the report is saved under `docs/team/00.paid-ads-dev/17.ads-dqc-report/` using `{cur_end}-weekly-dqc-report.md`.

---

## Data Sources

| Report | ClickHouse table |
|--------|------------------|
| Performance DQC | `mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics` |
| Union Ads DQC | `mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics` |

All regions, including BR, are queried from the SG ClickHouse cluster. The skill does not use Hive/DataSuite as the report generation entry point.

---

## Detection Rules

| Rule | Metric fields | Condition |
|------|---------------|-----------|
| Coverage anomaly | Fields ending with `_fill_rate` | Current week average drops by at least 5pp versus previous week |
| Average anomaly | Fields ending with `_avg` | Current week average drops by at least 10% versus previous week, when previous week value is greater than 0 |

Before judging anomalies, the skill checks daily data completeness by `grass_region + grass_date`. Regions with missing current-week or previous-week dates are listed under `Data Missing` and are skipped by default to avoid false positives.

---

## Output Format

The generated Markdown report contains:

- **Summary** — anomaly counts and the most severe field per report
- **Performance DQC Report** — data missing, coverage anomalies, and average anomalies
- **Union Ads DQC Report** — data missing, coverage anomalies, and average anomalies
- **Notes** — thresholds, aggregation logic, disabled-check exclusions, and data source

When no significant drops are found, the report explicitly states that no DQC coverage or average-value anomaly was detected for the week.
