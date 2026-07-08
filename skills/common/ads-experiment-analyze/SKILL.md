---
name: ads-experiment-analyze
description: >
  Ads Experiment Analyzer (广告实验分析) — run daily AB platform report analysis for Ads experiments, including core metrics, guardrails, stability, and experiment-bucket vs all-bucket risk checks.
  TRIGGER when: user mentions "ads experiment analysis", "AB 实验分析", "实验 daily", "实验跟踪", "guardrail", "by day 波动", "单桶大盘对比", "出价实验", "发券实验", "精排实验", "召回实验", or asks to analyze Ads AB test reports.
  DO NOT TRIGGER when: general AB platform setup questions (use sp-ab), non-Ads experiments, rollout document generation, or ads_id/campaign_id/shop_id anomaly diagnosis.
category: workflow
tags: [ads, ab-test, experiment, daily, guardrail, analysis]
skill_dependencies:
  - sp-ab
---

# Ads Experiment Analyzer (广告实验分析)

Analyze Ads AB platform experiments for daily tracking and go/no-go risk discussion. This skill is an orchestration layer: use `sp-ab` to fetch AB platform data, then apply Ads-specific metric templates, stability rules, guardrail checks, and experiment-bucket vs all-bucket comparisons.

## Supported Experiments

Use one of these modes:

- `bidding`: Plan Bucket A/B Test / bidding experiments (出价实验). If the user does not provide `pricing_type`, analyze `all` and `target_roas 2.0` by default, and state this in the statistical scope.
- `voucher`: voucher experiments (发券实验). Use traffic-side metrics and voucher guardrails.
- `model`: fine ranking / model experiments (精排模型实验). Use traffic-side metrics.
- `recall`: recall experiments (召回实验). Use traffic-side metrics.
- `traffic`: generic traffic-side experiments when the exact direction is unclear.

If the user does not specify the mode, infer it from the experiment name, template/tab names, feature keys, and metric set. Always state the inferred business direction in the report. Ask only when the ambiguity changes the conclusion.

For `bidding`, use a customer-constraint-first interpretation:

- Primary success metrics are `cpm` and `advv_per_imp`.
- Customer constraints are fulfillment / waste-rate metrics: `fulfilled_rev_pct`, `underbid_rev_pct`, `overbid_rev_pct`, and `no_gmv_rev_pct`; display them as absolute treatment-control `pp` changes.
- `rev_usd`, `net_rev_after_rebate`, and raw `advv_cost` are secondary business-context metrics. Because tail-bucket experiments can gain or lose impressions against nearby tail buckets, raw revenue / ADVV movement may be artificial and should not be the first-pass success criterion.
- A raw `rev_usd` / `advv_cost` gain without `cpm` / `advv_per_imp` improvement or customer-constraint health should be flagged as possible tail-bucket cannibalization, not a clean win.
- A raw `rev_usd` / `advv_cost` drop should normally be `YELLOW` instead of automatic `RED` when unit efficiency and customer constraints are healthy.

For `model`, `recall`, and generic `traffic`, use a traffic-side interpretation:

- Primary success metrics are `ads_revenue_usd` / `rev` and `advv_cost_1d` / `advv`; both should increase, and larger increases are better.
- `gmv_995_v2` is the platform GMV guardrail. It fails when treatment drops by more than `0.5%`, because ad revenue growth should not create material negative platform GMV impact.
- Ideally `advv` uplift should be at least as high as `rev` uplift. If `rev` is materially higher than `advv`, flag over-collection / 超收 risk even when both are positive.
- The summary must state whether by-day behavior is broadly positive. If the total-period win is mainly caused by one strong day, or fewer than most days are positive, do not call it a clean pass.

For `voucher`, keep the voucher economics guardrail (`guardrail_voucher > 0`) and `bad_query_rate` policy, while still reporting `rev`, `advv`, `gmv_995_v2`, `search_gmv_995_v2`, and `rcmd_unify_gmv_995_v2` in the same table-first format.

## Workflow

### Step 1: Auto Infer

Default mode is:

```text
Auto Infer -> Show Statistical Scope -> Ask Only Ambiguities -> Analyze
```

From the AB platform link, infer:

- `project_id`, `scene_id`, `exp_id`, `share_id`, experiment name, and business direction.
- Date window from the shared report, then validate the dates actually returned by the report.
- Regions, template/tab names, and report filters.
- Group names, group IDs, bucket ranges, and traffic / tail-bucket ratios from experiment metadata.
- Control/treatment groups from the shared report.
- Whether AA candidates exist among base groups.

User input always overrides the AB share configuration. In particular, if the user provides base/treatment group IDs or bucket names, use the user-provided mapping even when it differs from the share default.

Default grouping policy:

- Do not merge groups by default.
- If the AB share already contains an explicit combined group such as `670578;670579;670580`, treat it as a platform-provided combined group and say so.
- If the user asks to merge base groups, merge only those base groups; keep treatment groups separate unless the user asks to merge them.
- If AA groups are discovered, automatically add AA-diff comparison. If no AA group is found, warn that significance is judged only by the default noise band and by-day stability.

Date splitting policy:

- If the experiment window contains promo days, split the report into `normal` and `promo`.
- Promo days are every month `15`, every month `25`, and double-day dates where month equals day, such as `2/2`, `5/5`, and `11/11`.

Use `assets/monitor.example.yaml` as the starting config shape. For details, read `references/config-schema.md`.

### Step 2: Show Statistical Scope

Before giving conclusions, always show:

- Date range requested and dates actually returned by AB platform.
- Business direction: `bidding` / `voucher` / `model` / `recall` / `traffic`.
- Region scope: overall first, then all regions by-region by default.
- Group mapping: group name, group ID, bucket range, and traffic / tail-bucket ratio for every base and treatment group used.
- Traffic allocation: for traffic-side experiments, show each group's AB traffic percentage by region; for bidding tail-bucket experiments, show tail number / bucket range and its ratio, such as `1:10,51:60 = 20/100 = 20%`.
- Merge policy for base and treatment groups.
- AA policy and AA-diff source, or a risk warning if AA is unavailable.
- Template/tabs used and all AB report filters, such as `target_feature`, `is_ads`, `platform`, `pricing_type`, `voucher_type`, and `bucket_id`.
- Metric calculation mode: relative uplift, absolute percentage-point difference, or ratio recomputed from absolute numerator/denominator.

### Step 3: Ask Only Ambiguities

Ask the user only for missing or low-confidence inputs that can change the conclusion, such as:

- Whether to override control/treatment groups.
- Whether to exclude or separately label non-standard business dates beyond the default promo-day policy.
- Whether treatment groups should be merged.
- For bidding, whether a `pricing_type` other than `all` and `target_roas 2.0` is required.

### Step 4: Fetch AB Data

Use the `sp-ab` skill:

```bash
uv run get-report.py --from-url "<AB_REPORT_URL>" --json
```

For daily stability, fetch a by-day report too. Prefer a shared report link whose tab already contains day-level rows. If the shared report does not include a date dimension, ask the user for the by-day report link or query the same template with a by-day tab.

Also inspect traffic and parameter history:

```bash
uv run get-experiment.py traffic-history <exp_id> --lookback 30 --json
```

Use only complete natural days after the latest shuffle, traffic change, or parameter change. Default window is 7 complete days; if fewer are available, use all available complete days.

### Step 5: Run the Analyzer

Save report JSON from `sp-ab` and run:

```bash
uv run scripts/analyze_experiment.py \
  --config assets/monitor.example.yaml \
  --report-json /path/to/period_report.json \
  --daily-json /path/to/by_day_report.json \
  --output-md /path/to/daily_report.md \
  --output-json /path/to/daily_report.json
```

The analyzer accepts `sp-ab get-report.py --json` legacy output (`data.header`, `data.body`, `data.relative`) and row-style JSON (`rows`, `data`, `result`, or a top-level list of objects).

### Step 6: Interpret Results

Use `references/risk-policy.md` for the exact movement and risk policy.

Every metric must state whether it is a real change or likely fluctuation:

- `UP_CONFIDENT` / `DOWN_CONFIDENT`: direction is credible.
- `FLAT`: absolute uplift is within the default 0.5% noise band.
- `UP_VOLATILE` / `DOWN_VOLATILE`: average moved, but by-day behavior is unstable.
- `SINGLE_DAY_DRIVEN`: average is mainly driven by one day.
- `INCONCLUSIVE`: missing data or insufficient signal.

Guardrail states:

- `PASS`: clearly passes.
- `PASS_UNSTABLE`: passes on average but by-day behavior is unstable.
- `DISCUSS`: small risk or unclear impact; do not mechanically fail.
- `FAIL`: clear material failure.
- `UNKNOWN`: missing data or metric mapping.

Default rule: `abs(uplift) < 0.5%` is treated as fluctuation. For `bad_query_rate`, deterioration above `1%` is a strong risk, but changes within `0.5%` are treated as fluctuation.

For traffic-side model / recall experiments, `gmv_995_v2` is the guardrail and fails only when the drop is worse than `-0.5%`. A small negative movement within `0.5%` should be discussed as fluctuation / `PASS_UNSTABLE`, not mechanically failed.

### Step 7: Produce the Daily Report

Respond in Chinese by default, keeping metric names in English. Use this structure:

1. 统计口径: dates, business direction, regions, groups, buckets, traffic / tail-bucket ratios, merge policy, AA policy, tabs, filters, and metric calculation mode.
2. 总体结论: `GREEN` / `YELLOW` / `RED`, plus recommended action.
3. Overall 指标: core metrics, guardrails, AA/noise comparison, and by-day stability.
4. By Region: all regions by default, with one conclusion per region.
5. Group Breakdown: treatment groups separately unless the user requested merging.
6. 风险与建议: continue observing, split promo/normal, adjust group strategy, pause, or prepare rollout.

Presentation rules:

- All experiment directions (`bidding`, `voucher`, `model`, `recall`, `traffic`) must use the same table-first report format.
- Present conclusions, core metrics, guardrails, by-day stability, by-region effects, group breakdown, AA/noise comparison, and single-bucket vs market comparison as Markdown tables.
- Keep short narrative only before or after tables for the final recommendation; do not replace metric results with paragraph-only summaries.
- When normal/promo split exists, show separate tables for overall / normal / promo, or include a `场景` column such as `overall`, `normal`, and `promo`.
- For bidding fulfillment and waste-rate metrics, table values must be absolute treatment-control percentage-point changes (`pp`).

Use `scripts/render_daily_report.py` to re-render a saved JSON analysis if the Markdown format needs regeneration.

## References

- `references/config-schema.md` — monitor YAML fields and examples.
- `references/ads-metric-templates.md` — default Ads metric templates.
- `references/risk-policy.md` — movement, guardrail, and red/yellow/green policy.
- `assets/monitor.example.yaml` — minimal runnable config template.
