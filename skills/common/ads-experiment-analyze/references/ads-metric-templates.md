# Ads Metric Templates

## Bidding Experiments (出价实验)

Use for tail-bucket experiments with customer-side bidding metrics. Always ask the user for target `pricing_type`.

Decision principle:

- Bidding-side tail-bucket experiments can create artificial `rev_usd` / `advv_cost` gains by competing for or stealing impressions between tail buckets.
- Therefore, do not treat raw revenue or raw ADVV lift as the first-pass success criterion.
- The primary question is: under customer delivery constraints, did unit efficiency improve?
- Judge success first by `cpm`, `advv_per_imp`, and fulfillment / waste-rate constraints. Then use `rev_usd`, `net_rev_after_rebate`, and `advv_cost` as secondary context and tail-bucket cannibalization diagnostics.

Metric roles:

| Role | Metric | Default Direction | Scope | Interpretation |
|------|--------|-------------------|-------|----------------|
| primary | `cpm` | `increase` | both | Main unit revenue efficiency |
| primary | `advv_per_imp` | `increase` | both | Main unit advertiser value efficiency |
| constraint | `fulfilled_rev_pct_1d` | `non_decrease` | both | Primary customer fulfillment constraint, displayed as treatment-control `pp` |
| constraint | `underbid_rev_pct_1d` | `non_increase` | both | Customer-side underbid waste constraint, displayed as treatment-control `pp` |
| constraint | `overbid_rev_pct_1d` | `non_increase` | both | Customer-side overbid waste constraint, displayed as treatment-control `pp` |
| constraint | `no_gmv_rev_pct_1d` | `non_increase` | both | Customer-side no-GMV waste constraint, displayed as treatment-control `pp` |
| guardrail | `fulfilled_rev_pct_7d` | fail only if below control by more than `2pp` | both | `guardrail_fulfill` |
| constraint | `underbid_rev_pct_7d` | `non_increase` | both | Supporting 7d stability view, displayed as treatment-control `pp` |
| constraint | `overbid_rev_pct_7d` | `non_increase` | both | Supporting 7d stability view, displayed as treatment-control `pp` |
| constraint | `no_gmv_rev_pct_7d` | `non_increase` | both | Supporting 7d stability view, displayed as treatment-control `pp` |
| secondary | `rev_usd` | `increase` | both | Business context only; may include tail-bucket impression competition |
| secondary | `net_rev_after_rebate` | `increase` | both | Business context only; may include tail-bucket impression competition |
| secondary | `advv_cost` | `increase` | both | Business context only; diagnose together with 999口径 |
| diagnostic | `advv_999` / `advv_cost_999` | `non_decrease` | both | Tail-sample ADVV diagnostic |
| diagnostic | `advv_999_per_imp` | `non_decrease` | both | Stable per-impression ADVV diagnostic |

Required interpretation:

- `overall` should meet expectation.
- Target `pricing_type` should meet expectation.
- If `overall` improves but target `pricing_type` is flat or worse, flag "收益来源不明确".
- If target `pricing_type` improves but `overall` is flat or worse, flag "局部收益未传导到整体".
- `GREEN` requires primary efficiency metrics to improve or at least not regress materially, customer constraints to pass, and guardrails to pass.
- A secondary `rev_usd` / `advv_cost` gain alone must not make the experiment `GREEN`.
- A secondary `rev_usd` / `advv_cost` drop alone should not make the experiment `RED` if primary efficiency and customer constraints are healthy; mark it `YELLOW` and explain the business tradeoff.
- If raw `rev_usd` / `advv_cost` improves while `cpm` / `advv_per_imp` is flat or worse, flag possible tail-bucket impression competition or cannibalization.
- Use `fulfilled_rev_pct(1d)` as the primary fulfillment metric.
- Display all fulfillment / waste-rate metrics as absolute treatment-control percentage-point changes, not AB platform relative uplift.
- Use `fulfilled_rev_pct(7d)` only as `guardrail_fulfill`: compare treatment absolute rate with control absolute rate, and fail if any treatment bucket drops by more than `2pp`.
- Use `advv_999` / `advv_cost_999` as a diagnostic metric for ADVV volatility. If raw `advv_cost` moves materially but `advv_999` is flat or much smaller, flag that the ADVV result may be driven by tail or extreme samples rather than a stable overall shift.
- Use `advv_999_per_imp = advv_cost_999 / imp_cnt` as the per-impression stable ADVV diagnostic. Compare it with raw `advv_per_imp`; if raw per-imp ADVV moves materially but 999 per-imp stays flat or much smaller, flag per-impression ADVV as tail-sample driven.

## Traffic-side Experiments (流量侧实验)

Use for fine ranking model, recall, and generic traffic-side experiments. Voucher experiments use the same table shape, but keep the voucher-specific economics guardrail.

### Model / Recall / Generic Traffic

Decision principle:

- Primary success metrics are `ads_revenue_usd` / `rev` and `advv_cost_1d` / `advv`; both should increase, and larger increases are better.
- `gmv_995_v2` is a platform GMV guardrail, not the primary success metric. It fails when the drop is worse than `-0.5%`.
- Ad revenue should not grow by materially more than ADVV. If `rev` uplift is clearly higher than `advv` uplift, flag possible over-collection / 超收 risk.
- A total-period win is not clean if it is driven by one unusually strong day. The conclusion must say whether most days are positive for `rev` and `advv`.

Metric roles:

| Role | Metric | Default Direction | Interpretation |
|------|--------|-------------------|----------------|
| primary | `ads_revenue_usd` / `rev` | `increase` | Main ads revenue objective |
| primary | `advv_cost_1d` / `advv` | `increase` | Main advertiser value objective |
| guardrail | `gmv_995_v2` | fail if `< -0.5%` | Platform GMV protection |
| guardrail | `search_gmv_995_v2` | fail if `< -0.5%` | Search GMV guardrail / checklist |
| guardrail | `rcmd_unify_gmv_995_v2` | fail if `< -0.5%` | Recommendation GMV guardrail / checklist |
| guardrail | `bad_query_rate` | `non_increase`, fail when deterioration exceeds 1% | Relevance / quality guardrail |
| secondary | `gmv` | `non_decrease` | Business context |
| secondary | `imp_cnt` | `non_decrease` | Traffic context |
| secondary | `cpm` | `increase` | Revenue efficiency context |
| secondary | `advv_per_imp` | `increase` | Advertiser value efficiency context |

Required interpretation:

- `GREEN` requires `rev` and `advv` to be positive beyond noise, `gmv_995_v2` to pass the `-0.5%` guardrail, and by-day behavior to be broadly positive.
- If `rev` is positive but `advv` is flat or negative, mark risk: revenue gain may come from over-collection rather than advertiser value improvement.
- If both `rev` and `advv` are positive but `rev` uplift is materially higher than `advv` uplift, flag 超收 risk and avoid clean `GREEN` unless the user accepts the tradeoff.
- If total-period `rev` / `advv` is positive but fewer than most days are positive, or the metric is `SINGLE_DAY_DRIVEN`, mark it as unstable and do not treat it as a clean pass.

### Voucher Experiments

Voucher experiments should still show `rev`, `advv`, `gmv_995_v2`, `search_gmv_995_v2`, and `rcmd_unify_gmv_995_v2`, but the voucher economics decision also depends on `ads_voucher_cost` and `guardrail_voucher`.

Core / guardrail metrics:

| Metric | Default Direction |
|--------|-------------------|
| `gmv` | `increase` |
| `gmv_995_v2` | `non_decrease` |
| `ads_revenue_usd` | `increase` |
| `advv_cost_1d` | `increase` |
| `ads_voucher_cost` | `non_increase` |
| `imp_cnt` | `non_decrease` |
| `cpm` | `increase` |
| `advv_per_imp` | `increase` |
| `guardrail_voucher` | `pass_min: 0` |
| `bad_query_rate` | `non_increase`, fail when deterioration exceeds 1% |

Derived metrics:

```text
cpm = ads_revenue_usd / imp_cnt
advv_per_imp = advv_cost_1d / imp_cnt
guardrail_voucher = uplift(gmv_995_v2) / 4 + uplift(advv_cost_1d) - ads_voucher_cost
```

Guardrail policy:

- For model / recall / generic traffic experiments, `gmv_995_v2 < -0.5%` is a guardrail failure. Negative movement within `0.5%` is a fluctuation-sized risk and should be marked `PASS_UNSTABLE` / discussion, not a hard fail.
- `guardrail_voucher > 0`: pass.
- If `guardrail_voucher` is positive but within the 0.5% noise band, report `PASS_UNSTABLE` because the pass signal is still fluctuation-sized.
- `guardrail_voucher <= 0` with impact inside 0.5% noise band: discuss, not fail.
- `bad_query_rate` deterioration within 0.5%: treat as fluctuation.
- `bad_query_rate` deterioration from 0.5% to 1%: discuss.
- `bad_query_rate` deterioration above 1%: fail unless the data is clearly incomplete or single-day-driven, in which case escalate for manual discussion.
