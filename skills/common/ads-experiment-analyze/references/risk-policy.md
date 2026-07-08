# Risk Policy

## Noise Band

Default:

```yaml
noise_band_pct: 0.5
```

Any metric with `abs(uplift_pct) < 0.5%` is treated as fluctuation by default. Do not call it a real increase or decrease unless the user overrides the noise band or the AB platform provides strong evidence.

When AA groups are available, compare experiment movement against both the default noise band and the AA-diff band:

```text
effective_band = max(0.5%, abs(AA diff))
```

For multiple base AA groups, use the maximum absolute deviation from the base mean unless the user specifies a different AA policy. If AA is unavailable, explicitly warn that the result has weaker confidence.

## Promo Split

If the analysis window contains promo days, split the conclusion into `normal` and `promo`. Promo days are:

- Day `15` of every month.
- Day `25` of every month.
- Double-day dates where month equals day, such as `2/2`, `5/5`, and `11/11`.

Do not average promo and normal days into one conclusion when their effects diverge materially.

## Movement Status

| Status | Meaning |
|--------|---------|
| `UP_CONFIDENT` | Credible increase beyond noise band and stable enough by day |
| `DOWN_CONFIDENT` | Credible decrease beyond noise band and stable enough by day |
| `FLAT` | Within noise band |
| `UP_VOLATILE` | Average is up, but by-day signal is unstable |
| `DOWN_VOLATILE` | Average is down, but by-day signal is unstable |
| `SINGLE_DAY_DRIVEN` | A single day contributes more than the configured dominance threshold |
| `INCONCLUSIVE` | Missing value, missing by-day data, or insufficient signal |

Stability checks:

- Direction consistency over the available complete days.
- Yesterday vs day-before jump.
- Single-day dominance.
- Experiment bucket vs all-bucket-sum gap.

If by-day data is unavailable, do not label a non-flat metric as confident. Mark it `INCONCLUSIVE` and ask for a by-day report link or a report tab with date dimension.

For bidding experiments, compare raw `advv_cost` against `advv_999` / `advv_cost_999` when diagnosing ADVV movement. Also compare raw `advv_per_imp` against `advv_999_per_imp`. If raw ADVV changes materially but the corresponding 999 metric stays within the noise band or moves much less, explain that the ADVV signal may be tail-sample driven. If both move in the same direction beyond the noise band, the ADVV change is more credible.

For bidding-side tail-bucket experiments, `rev_usd` and raw `advv_cost` can be inflated by tail-bucket impression competition, so they are secondary business-context metrics rather than first-pass success metrics. Judge success primarily by unit efficiency (`cpm`, `advv_per_imp`) under customer constraints (`fulfilled`, `underbid`, `overbid`, `no_gmv`). If `rev_usd` / `advv_cost` improves while unit efficiency or customer constraints do not, flag possible cannibalization instead of calling the experiment successful. If `rev_usd` / `advv_cost` drops while unit efficiency and customer constraints are healthy, mark the business tradeoff as `YELLOW`, not an automatic `RED`.

For bidding fulfillment, use `fulfilled_rev_pct(1d)` as the primary core metric. Display all fulfillment / waste-rate metrics (`fulfilled`, `underbid`, `overbid`, `no_gmv`) as absolute treatment minus control changes in percentage points (`pp`), not AB platform relative uplift. Treat `fulfilled_rev_pct(7d)` as `guardrail_fulfill`; the guardrail fails only when any treatment bucket drops by more than `2pp`, and smaller drops should be reported as `PASS_UNSTABLE`, not a hard fail.

For traffic-side model / recall experiments, judge success primarily by `ads_revenue_usd` / `rev` and `advv_cost_1d` / `advv`. Both should increase beyond the effective noise band. `gmv_995_v2` is a platform GMV guardrail and fails when it drops by more than `0.5%`; smaller negative movement should be discussed as fluctuation-sized risk. A result where `rev` is positive but `advv` is flat or negative is not a clean win and should be flagged as possible over-collection / 超收. If both are positive but `rev` uplift is materially higher than `advv` uplift, mark `YELLOW` unless the business owner explicitly accepts the tradeoff.

For traffic-side model / recall experiments, the summary must mention by-day positivity for `rev` and `advv`. If total-period uplift is positive but fewer than most days are positive, or if one day dominates the result, do not mark the experiment `GREEN`. A primary metric marked `SINGLE_DAY_DRIVEN` should make the result `RED` until the date split or abnormal day is explained.

## Guardrail Status

| Status | Meaning |
|--------|---------|
| `PASS` | Clearly passes |
| `PASS_UNSTABLE` | Average passes, but by-day behavior is unstable |
| `DISCUSS` | Small risk, near-threshold issue, or unclear impact |
| `FAIL` | Clear material guardrail failure |
| `UNKNOWN` | Metric is missing or cannot be mapped |

Do not mechanically fail small guardrail movement. If the magnitude is within the 0.5% noise band, mark `DISCUSS` or `PASS_UNSTABLE` and explain that the current evidence looks like fluctuation.

## Overall Status

Use the strongest evidence:

- `GREEN`: core metrics meet expectation, guardrails pass, by-day behavior is stable, and market gap is not material.
- `YELLOW`: core metrics are directionally okay but volatile, confidence is weak, guardrail is `DISCUSS` or `PASS_UNSTABLE`, or market gap needs attention.
- `RED`: core metric materially violates expectation, guardrail has material `FAIL`, or experiment bucket is materially worse than all-bucket baseline.

## Market Gap

Compare the experiment bucket against all-bucket-sum from AB platform data:

```text
market_gap = experiment_bucket_uplift - all_buckets_sum_uplift
```

Flag risks:

- Experiment bucket improves less than all buckets by a material margin.
- Experiment bucket worsens while all buckets are flat or improving.
- Experiment bucket and all buckets move in opposite directions.

Default market gap threshold should start at the same 0.5% noise band unless the user sets a stricter business threshold.
