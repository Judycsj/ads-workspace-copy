# Ads Experiment Analyzer (ads-experiment-analyze) Guide

> **Language**: [English](ads-experiment-analyze.md) | [中文](ads-experiment-analyze.zh-CN.md)

Daily analysis workflow for Ads AB experiments. It fetches AB platform report data through `sp-ab`, applies Ads-specific metric templates, and produces a Chinese risk report for core metrics, guardrails, by-day stability, and experiment-bucket vs all-bucket comparison.

**Trigger keywords**: "ads experiment analysis", "AB 实验分析", "实验 daily", "实验跟踪", "guardrail", "by day 波动", "单桶大盘对比", "出价实验", "发券实验", "精排实验", "召回实验"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main workflow and report interpretation rules |
| `assets/monitor.example.yaml` | Starting YAML config |
| `references/config-schema.md` | Config fields and metric schema |
| `references/ads-metric-templates.md` | Bidding and traffic-side metric templates |
| `references/risk-policy.md` | Movement, guardrail, and red/yellow/green policy |
| `scripts/analyze_experiment.py` | Analyzer for AB report JSON |
| `scripts/render_daily_report.py` | Re-render Markdown from saved analysis JSON |

---

## Prerequisites

| Dependency | Type | Purpose |
|------------|------|---------|
| `sp-ab` | Skill | Fetch AB platform experiment metadata and report JSON |
| AB platform report token | Credential | Required by `sp-ab get-report.py` for Report Open API |
| `uv` | Runtime | Runs the bundled scripts and resolves Python dependencies |

---

## Basic Usage

1. Prefer providing only the AB report link; the skill first auto-infers the statistical scope.
2. User-provided dates, groups, regions, or filters override the AB share.
3. Prepare or override a monitor config from `assets/monitor.example.yaml`.
4. Fetch period report JSON with `sp-ab`:

```bash
uv run get-report.py --from-url "<AB_REPORT_URL>" --json > period_report.json
```

5. Fetch a by-day report JSON when available:

```bash
uv run get-report.py --from-url "<AB_BY_DAY_REPORT_URL>" --json > by_day_report.json
```

6. Run the analyzer:

```bash
uv run scripts/analyze_experiment.py \
  --config assets/monitor.example.yaml \
  --report-json period_report.json \
  --daily-json by_day_report.json \
  --output-json daily_report.json \
  --output-md daily_report.md
```

---

## Example Prompts

> Use `/ads-experiment-analyze` to analyze this bidding experiment daily. Report link: `...`. Target pricing_type is `target_roas`.

> 帮我分析这个发券实验，重点看 guardrail_voucher、bad_query_rate，以及昨天 vs 前天是否波动。

> 这个 recall 实验帮我做 daily 跟踪，输出 Markdown，顺便指出单桶相对所有桶总和有没有明显风险。

---

## Notes

- The default noise band is `0.5%`; movement within the band is treated as fluctuation.
- The report must first show the statistical scope: dates, dates actually returned by AB platform, regions, group IDs, bucket ranges, traffic percentage or tail-bucket ratio, merge policy, AA policy, tabs, filters, and metric calculation mode.
- Every experiment must show each group's ratio: traffic-side experiments show AB platform traffic percentage, preferably by region; bidding tail-bucket experiments show tail/bucket range and ratio, such as `1:10,51:60 = 20/100 = 20%`. If the platform data is unavailable, mark it as `unknown` in the scope table instead of omitting it.
- All experiment directions (bidding, voucher, model, recall, and generic traffic-side) use a consistent table-first result format: overall conclusion, core metrics, guardrails, by-day, by-region, group breakdown, AA/noise judgment, and single-bucket vs market comparison should be rendered as Markdown tables.
- Split normal/promo conclusions when the window contains promo days: day 15, day 25, or double-day dates where month equals day.
- User-provided group mapping overrides the AB share; otherwise infer groups from the link.
- Do not merge groups by default. If the share itself contains a combined group, state it explicitly.
- If AA groups are found, include AA-diff as a fluctuation reference. If AA is unavailable, warn about weaker confidence.
- Bidding experiments default to `all` and `target_roas 2.0`; user-provided target `pricing_type` overrides the default.
- Bidding tail-bucket experiments use a customer-constraint-first interpretation: judge `cpm`, `advv_per_imp`, and `fulfilled/underbid/overbid/no_gmv` before `rev_usd`, `net_rev_after_rebate`, or raw `advv_cost`. Raw revenue / ADVV are secondary business context and tail-bucket cannibalization diagnostics, not standalone success criteria.
- Always state the business direction: bidding, voucher, model, recall, or generic traffic-side.
- Default output is overall first, followed by all-region by-region conclusions.
- For bidding fulfillment, `fulfilled_rev_pct(1d)` is the primary core metric. `fulfilled_rev_pct(7d)` is evaluated as `guardrail_fulfill` using absolute treatment-control percentage-point difference, and fails only when the drop is worse than `-2pp`.
- Bidding reports should include `advv_999` / `advv_cost_999` and `imp_cnt` when possible; the analyzer also computes `advv_999_per_imp = advv_cost_999 / imp_cnt` to judge whether raw `advv per imp` movement is tail-sample driven.
- Traffic-side experiments cover voucher, fine ranking model, and recall. For fine ranking / recall / generic traffic-side experiments, the primary decision is whether `rev` and `advv` increase; `gmv_995_v2` is the guardrail and fails only when the drop is worse than `0.5%`.
- Traffic-side reports must compare `rev` and `advv`: if `rev` is materially higher than `advv`, flag possible over-collection; if `rev` is positive but `advv` is not, do not call it a clean win.
- Traffic-side summaries must include whether by-day movement is positive. If the overall lift is driven by one unusually strong day, or most days are not positive, it is not a clean pass.
- Include `search_gmv_995_v2` and `rcmd_unify_gmv_995_v2` in the checklist as feature GMV guardrails / risk signals.
- Google Doc and SeaTalk outputs are reserved workflow destinations: generate Markdown first, then publish through available workspace tools.
