# Ads Experiment Analyzer Config Schema

Use a YAML config per experiment or per experiment family. Keep the user-facing config explicit: the analyzer should not guess business intent when metric direction changes the conclusion.

## Top-level Fields

```yaml
experiment:
  name: roi3_exp_v1
  type: bidding              # bidding | voucher | model | recall | traffic
  business_direction: auto   # auto | bidding | voucher | model | recall | traffic
  report_url: "https://abtest.shopee.io/..."
  owner: ""
  target_pricing_types: [all, "target_roas 2.0"] # bidding default when user omits pricing_type

analysis:
  language: zh-CN
  window_days: 7
  noise_band_pct: 0.5
  rev_advv_gap_risk_pct: 0.5 # traffic-side over-collection warning threshold
  daily_compare: yesterday_vs_day_before
  market_baseline: all_buckets_sum
  min_direction_consistency: 0.6
  day_over_day_jump_pct: 30
  single_day_dominance_pct: 50
  auto_infer: true
  ask_only_ambiguities: true
  show_statistical_scope: true
  split_promo_days: true
  promo_days:
    monthly_days: [15, 25]
    double_day: true
  region_scope: all          # all | top_gmv | selected
  default_merge_policy:
    base: separate           # separate | merge
    treatment: separate      # separate | merge
  aa_policy:
    enabled: auto
    source: inferred_base_groups
    warn_if_missing: true

selectors:
  group_field: abtest_group
  date_fields: [abtest_date, grass_date, date, dt]
  treatment_values: []       # optional; empty means use all relative rows
  market_baseline_values: [all, overall, ALL, total, all_buckets_sum]
  segment_fields: []         # e.g. [pricing_type, region]

metrics:
  core: []
  traffic_core: []
  voucher_core: []
  bidding_core: []
  guardrail: []
  derived: []
```

## Auto Infer Contract

When a report link is provided, infer the statistical scope before analysis:

```yaml
statistical_scope:
  requested_dates: [2026-04-22, 2026-04-26]
  actual_returned_dates: [2026-04-22, 2026-04-23, 2026-04-24, 2026-04-25, 2026-04-26]
  regions: [ID]
  filters:
    target_feature: ALL
    is_ads: all
    platform: all
  template_tabs:
    - Platformwide - Period
    - Rollout Checklist
    - Search Core Metrics
  group_mapping:
    base_groups:
      - {name: base1, group_id: "670578", bucket: "1:10", traffic_pct: 10}
    treatment_groups:
      - {name: exp1, group_id: "670581", bucket: "31:40", traffic_pct: 10}
  traffic_allocation:
    by_group:
      - {name: base1, group_id: "670578", bucket: "1:10", ratio: "10/100", traffic_pct: 10}
    by_region:
      - {region: ID, group_id: "670578", bucket: "1:10", ratio: "10/100", traffic_pct: 10}
  merge_policy:
    base: separate
    treatment: separate
  aa_groups:
    - ["670578", "670579", "670580"]
```

Rules:

- User-provided group IDs, bucket names, dates, regions, or filters override AB share defaults.
- Do not merge groups by default. A semicolon group from the share, such as `670578;670579;670580`, is treated as a platform-provided combined group and must be stated explicitly.
- The statistical scope must include traffic / tail-bucket ratio for every group used:
  - For traffic-side experiments, report AB platform `percentage` by group and by region when available.
  - For bidding tail-bucket experiments, report tail number / bucket range and ratio, such as `9913-all` or `1:10,51:60 = 20/100 = 20%`.
  - If the share/report omits the ratio, fetch experiment detail or group metadata before concluding; if still unavailable, explicitly mark it as `unknown` in the scope table.
- If base AA groups are found, compute AA-diff and use it as a natural fluctuation reference together with the `0.5%` noise band. If no AA is found, emit a risk warning.
- Default region output is overall first and then all regions by region.
- If promo days appear in the date window, split normal and promo conclusions. Promo days are monthly `15`, monthly `25`, and double days where month equals day.
- Business direction must be stated: `bidding`, `voucher`, `model`, `recall`, or `traffic`.

## Metric Fields

```yaml
- name: rev_usd
  aliases: [revenue_usd]
  direction: increase        # increase | decrease | non_decrease | non_increase | flat
  decision_role: secondary   # primary | constraint | secondary | diagnostic | guardrail
  scope: overall             # overall | target_pricing_type | both
  guardrail: false
  required: true
  diagnostic: false
  fail_if: null
```

Rules:

- Use `aliases` when AB report names differ from common names.
- Use `scope: both` for bidding metrics that must pass in both `overall` and target `pricing_type`.
- Use `required: true` for metrics whose absence should make the report `YELLOW`.
- Use `diagnostic: true` for supporting metrics such as `advv_999` that explain volatility but should not decide the red/yellow/green status by themselves.
- Use `decision_role` to control severity:
  - `primary`: main success metric. Material misses can make the result `RED`.
  - `constraint`: customer / quality constraint. Material misses can make the result `RED`.
  - `secondary`: business-context metric. Material misses are usually `YELLOW`, because they may be tradeoffs or tail-bucket artifacts.
  - `diagnostic`: explanatory metric. Does not decide status by itself.
  - `guardrail`: explicit guardrail metric with its own pass/fail policy.
- For bidding experiments, `cpm` and `advv_per_imp` should be `primary`; fulfillment / waste-rate metrics should be `constraint`; `rev_usd`, `net_rev_after_rebate`, and raw `advv_cost` should be `secondary`.
- For model / recall / generic traffic experiments, `ads_revenue_usd` / `rev` and `advv_cost_1d` / `advv` should be `primary`; `gmv_995_v2` should be configured as a `guardrail` with `fail_decrease_pct: 0.5`.
- For voucher experiments, use `voucher_core` when available so voucher economics can keep `guardrail_voucher` while still reporting `rev`, `advv`, and GMV checklist metrics.
- Directions:
  - `increase`: should go up beyond the noise band.
  - `decrease`: should go down beyond the noise band.
  - `non_decrease`: should not materially go down.
  - `non_increase`: should not materially go up.
  - `flat`: should stay within the noise band.

## Derived Metrics

The script supports a small expression format for common ratios:

```yaml
derived_metrics:
  - name: cpm
    formula: ads_revenue_usd / imp_cnt
    direction: increase
  - name: advv_per_imp
    formula: advv_cost_1d / imp_cnt
    direction: increase
  - name: advv_999_per_imp
    formula: advv_cost_999 / imp_cnt
    formula_mode: ratio_uplift
    direction: non_decrease
    diagnostic: true
  - name: guardrail_fulfill
    source_metric: fulfilled_rev_pct(7d)
    formula_mode: absolute_diff_pct_points
    unit: pp
    fail_decrease_pp: 2.0
    guardrail: true
  - name: guardrail_gmv_995_v2
    source_metric: gmv_995_v2
    direction: non_decrease
    fail_decrease_pct: 0.5
    guardrail: true
```

When the input is `sp-ab` relative rows, ratio formulas such as `ads_revenue_usd / imp_cnt` are not recomputed from relative percentages because that is mathematically misleading. Prefer a direct `cpm` / `advv_per_imp` metric in the AB report. Formula evaluation on relative rows is reserved for metrics that explicitly set `allow_relative_formula: true` or for guardrail formulas.

Use `formula_mode: ratio_uplift` when the analyzer should compute the uplift from absolute control/treatment rows:

```text
treatment_ratio = treatment_numerator / treatment_denominator
control_ratio = control_numerator / control_denominator
uplift_pct = (treatment_ratio / control_ratio - 1) * 100
```

This is the correct mode for `advv_999_per_imp = advv_cost_999 / imp_cnt`.

Use `formula_mode: absolute_diff_pct_points` for rate metrics or guardrails that must compare treatment and control absolute rates. When this mode is set, the analyzer evaluates the absolute treatment-control rows before falling back to AB platform relative uplift:

```text
diff_pp = (treatment_rate - control_rate) * 100
```

This is the correct mode for bidding fulfillment / waste-rate metrics and for `guardrail_fulfill`, where `fulfilled_rev_pct(7d)` must not drop more than `2pp` for any treatment bucket.

Use `fail_decrease_pct` for percentage-uplift guardrails such as `gmv_995_v2`:

```yaml
- name: guardrail_gmv_995_v2
  source_metric: gmv_995_v2
  direction: non_decrease
  fail_decrease_pct: 0.5
  guardrail: true
```

The analyzer marks the guardrail `FAIL` only when the metric is below `-0.5%`. A smaller negative value is `PASS_UNSTABLE`, because it is within the default fluctuation band but should still be visible in the report.

For `guardrail_voucher`, prefer a direct AB report metric if the report has one. If not, define the formula and ensure the input report contains compatible uplift or absolute values:

```yaml
- name: guardrail_voucher
  formula: gmv_995_v2 / 4 + advv_cost_1d - ads_voucher_cost
  pass_min: 0
  guardrail: true
  allow_relative_formula: true
```

## Output Destinations

The initial implementation renders Markdown and JSON locally. Google Doc and SeaTalk are reserved workflow destinations:

```yaml
outputs:
  markdown: true
  json: true
  google_doc:
    enabled: false
    doc_url: ""
  seatalk:
    enabled: false
    webhook: ""
```

When Google Doc or SeaTalk is requested, generate Markdown first, then use the available workspace/MCP capability to publish it.

## Output Format Contract

All business directions share the same table-first Markdown output contract:

| Section | Required format |
|---------|-----------------|
| Statistical scope | Table of dates, actual returned dates, business direction, regions, groups, buckets, traffic / tail-bucket ratios, merge policy, AA policy, tabs, filters, and metric calculation mode |
| Overall conclusion | Table with status, recommendation, RED reasons, and YELLOW reasons |
| Core metrics | Table; one row per metric, segment, group, or split scenario |
| Guardrails | Table; one row per guardrail with `PASS` / `PASS_UNSTABLE` / `DISCUSS` / `FAIL` / `UNKNOWN` |
| By-day stability | Table with days, direction consistency, single-day dominance, day-over-day jump, and judgment |
| By-region | Table; overall first, then all regions unless the user narrows scope |
| Group breakdown | Table; treatment groups remain separate unless the user asks to merge |
| AA/noise and market comparison | Table; include AA diff when available, otherwise show the missing-AA confidence warning |

Narrative text should be short and only explain the final recommendation or unusual caveats. Do not replace metric results with paragraph-only summaries.
