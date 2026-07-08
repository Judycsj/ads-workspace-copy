# Ads Rollout Document Generator (ads-rollout-generate) Guide

> **Language**: [English](ads-rollout-generate.md) | [中文](ads-rollout-generate.zh-CN.md)

Generate a standard Ads rollout Markdown draft file from one AB platform experiment report link. The skill uses `sp-ab` to fetch AB platform data, fills the latest `rollout-doc.md` template, and asks before choosing unclear metric mappings or business thresholds.

**Trigger keywords**: "generate rollout", "fill rollout doc", "rollout 文档", "全量申请文档", "实验平台 link 填模板", "AB link 生成 rollout", "填写 rollout-doc.md"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main workflow and clarification policy |
| `references/template-mapping.md` | Template field mapping and data-fill rules |
| `references/guardrail-thresholds.yaml` | Static traffic-bucket and item-bucket guardrail thresholds |

---

## Prerequisites

| Dependency | Type | Purpose |
|------------|------|---------|
| `sp-ab` | Skill | Fetch AB platform report JSON and experiment metadata |
| AB platform report token | Credential | Required by `sp-ab` for Report Open API access |
| `uv` | Runtime | Runs the `sp-ab` helper scripts |

---

## Basic Usage

1. Provide one AB platform report link.
2. The skill fetches the report with `sp-ab` and summarizes the data scope.
3. Confirm any unclear metric mapping, formula, group mapping, or guardrail threshold.
4. The skill fills rollout data sections first.
5. Provide project background, method, Epic File, participants, Ticket, and Rollout Date when asked.
6. The skill writes the filled Markdown draft to `tmp/ads-rollout-generate/<exp_id-or-share_id>/...rollout.md` by default and returns the file path.

The default behavior is one link to one rollout `.md` file. If multiple links are provided, the skill generates independent draft files unless the user explicitly asks to combine them.

---

## Example Prompts

> Use `/ads-rollout-generate` to fill the rollout template from this AB platform link: `https://abtest.shopee.io/...`

> 根据这个实验平台 link 生成 rollout 文档，先把数据部分填好，背景和参与者我后面补。

> 帮我把这个 item bucket 实验转成 `rollout-doc.md` 格式；不确定的达标率指标先问我。

---

## Notes

- The skill does not reuse `ads-experiment-analyze` metric policies.
- Confirmed default mappings are stored in `references/template-mapping.md`; only unmapped or ambiguous fields require clarification.
- For speed, the skill first restores share parameters and builds a de-duplicated query plan. It should not replay the full shared UI summary by default when rollout generation needs corrected scopes such as non-normalized `Mo.*`, all-filter item rows, or supplemental tabs.
- Query planning is an execution optimization only: merge metric requests with the same template/tab/date/region/group/dim/filter/normalization scope, reuse matching raw files under `tmp/ads-rollout-generate/`, and keep the generated rollout doc structure and values identical to the documented metric rules. Do not add query-plan-only metadata to the final Markdown unless the user explicitly asks.
- Prefer server-side filters for fixed AB dimensions such as `target_feature`, `product_type`, `platform`, `is_ads`, `adtag_tier`, `budget_tier`, `campaign_order_tier`, and `hit_budget_tier`; use client-side filtering only when required by AB API semantics.
- Fetch fallback tabs only after the primary source is missing the required metric or matching rows. Do not prefetch exploratory sources.
- The skill must compare experiment parameters from the AB link: fetch the selected base group and selected rollout treatment group parameter payloads with `sp-ab` group detail / feature-value APIs, compare them structurally when possible, and write the result to Appendix `实验参数变化/Experiment Parameter Changes`.
- Parameter diff compares only the actual AB group `parameter` / feature-parameter payload. Group names, bucket ranges, traffic share, dates, normalization config, and report metrics are not parameter changes.
- If the selected base and rollout treatment payloads are confidently identical, add a Project Info `参数变化风险提示 / Parameter Change Risk` warning. If parameter data is missing or the baseline/treatment group is unclear, mark the Appendix row as `unresolved` instead of claiming no change.
- If the AB report selects multiple treatment buckets, the skill must ask which single treatment bucket is the rollout bucket before generating treatment-derived metrics. It must not choose the first treatment, randomly choose one, or aggregate treatments.
- If the control selector contains two or more Base buckets, `置信度分析-AA` uses those Base buckets as the default AA reference: normalize each Base bucket by traffic share, then take the arithmetic mean by date / region / metric. If there are fewer than two Base buckets and no explicit AA groups, use `未指定aa分桶桶号`.
- If the AB platform Date / `times_str` contains multiple date segments, merge all segments into one analysis window. Control and treatment come only from group selectors, never from date segments; `exp days` is the count of unique complete dates across all segments.
- For item-bucket data, `advv_999` uses `advv_cost_999`; `broad_gmv` uses `broad_gmv_usd`; `broad_gmv_999` uses `broad_gmv_usd_999`. Do not fill regular `broad_gmv` from the 999 field.
- For item-bucket `2.3`, derive `BiddingType` rows from the selected rollout bucket ID. `24*` is multi-item `GMS` (`PricingType=24/25/27`, `adtag_tier=ALL`); `99*` is single-item ROI2 and renders `All` / `Target_ROI2` / `Simple_ROI2` (`adtag_tier=ALL` / `target_roas2.0` / `simple2.0`); bucket IDs `<1000` render only the matching cold-start / new-product / empty-order `adtag_tier`.
- For `99*` item experiments, fetch `All`, `Target_ROI2`, and `Simple_ROI2` together for each source tab by keeping `adtag_tier` as a dimension or using one multi-value filter; do not run one query per BiddingType when the tab/scope/metrics are otherwise identical.
- Item-bucket bidding classes are mutually exclusive. A `99*` experiment must not render `GMS` or cold-start rows; a `24*` experiment must not render `All` / `Target_ROI2` / `Simple_ROI2`; a `<1000` experiment must not render unrelated item bidding rows.
- Item-bucket traffic share uses fixed Product Ads plan-bucket mapping when AB `normalization_config` is missing or unrelated. `24*` and `99*` large buckets (`2410-2414`, `2420-2424`, `9910-9914`, `9920-9924`) are 19% each; their small buckets (`2415-2419`, `2425-2429`, `9915-9919`, `9925-9929`) are 1% each. Cold-start `<1000` large buckets (`10-12`, `20-22`) are 97/300 = 32.3333% each; small buckets (`13-15`, `23-25`) are 1% each.
- For semicolon-separated item-bucket control groups, split the selector and sum fixed shares, for example `2413-all;2414-all = 38%`. If AB normalization conflicts with the fixed item mapping, ask whether the rollout uses special traffic allocation.
- In Core Metric Uplift Summary, traffic-bucket experiments must leave `Rev达标率 abs` and `Rev达标率 Rel.` as `-`; target achievement rate applies only to item / plan bucket experiments. For item / plan bucket experiments, both `2.2 Rev达标率 abs` and `Rev达标率 Rel.` must use `fulfilled_rev_pct(1d)` and align with the rendered `2.3 Item-Bucket-Exp.1d达标率` cell for the same region and aggregate item row. Do not use `fulfilled_rev_pct(7d)` / `7d达标率` for `2.2`; 7d target-rate values are only valid for sheet paste fields that explicitly request 7d.
- `Mo.*` columns are overall, non-normalized absolute-uplift metrics: turn AB platform `Normalization` off, do not reuse an enabled share `normalization_config`, keep only date / region / control / selected treatment, and set every other filter to `ALL` (`pricing_type`, entrance / `target_feature`, `adtag_tier`, `budget_tier`, `campaign_order_tier`, `hit_budget_tier`, product / ads type, scene, etc.). Product Ads plan-bucket overall rows are case-sensitive; use uppercase `adtag_tier=ALL`, not lowercase `all`.
- `2.2 Core Metric Uplift Summary` must include a `Region=ALL` row. Sum absolute-impact columns across rendered regions, including `Mo.*` (including `Mo. Advv 7d (w usd)`) and any future entrance absolute-impact columns; if any contributing region is missing, leave the `ALL` cell as `-` instead of showing a partial total. Do not sum rate / ratio / relative / pp columns such as `VPR abs`, `Rev达标率 abs`, `Rev达标率 Rel.`, or the current `Ent.* Rel.` columns. For `*. Rel.` columns in the `ALL` row, compute from aggregated full-traffic raw absolute inputs (`all_base_full = sum(region base_full)`, `all_exp_full = sum(region exp_full)`, `all_rel = all_exp_full / all_base_full - 1`); do not sum or average region percentages.
- `2.2 Core Metric Uplift Summary` includes 5 relative reference columns (`Rev Rel.`, `Advv 1d Rel.`, `Advv 7d Rel.`, `Broad GMV Rel.`, `Broad GMV 999 Rel.`), each placed immediately after its corresponding `Mo.*` column. These columns are always present in the table header; fill `-` when data is unavailable. Each `*. Rel.` is computed from the same source tab, same row scope, and same raw absolute base / treatment used for the corresponding `Mo.*`: `rel_reference = exp_full / base_full - 1` where `base_full = base_abs_raw / base_traffic_share`. Do not use AB report `relative_diff` directly (consistency check only). Do not reverse-engineer from rendered `Mo.*` values.
- For item / campaign-bucket rollouts, the Core Metric Uplift Summary includes AA-adjusted relative references: `Rev Adj. Rel.`, `Advv 999 Adj. Rel.`, and `Advv Adj. Rel.`. They use `adjusted_lift = post_lift - pre_aa`, where both `pre_aa` and `post_lift` are computed from full-traffic normalized raw treatment/base values from the same source scope.
- AA-adjusted metrics require a fixed pre window and confirmed pre-window bucket availability. If the pre window is missing, render `**【待确认】Pre AA Window**`; if bucket availability is unconfirmed, render `**【待确认】Pre AA Bucket Availability**`; if a conflict is found, render `-` and document it in Metric Mapping.
- `Rev Adj. Rel.` and `Advv 999 Adj. Rel.` are overall stability references. Raw lift remains mandatory and adjusted lift must not replace it. Region adjusted-lift values are diagnostic and should not be treated as a 1% hard guardrail.
- `Mo. Advv 7d (w usd)` is a traffic-bucket-only column sourced from `Ads Type (Ads Data Only) - Period.advv_cost_7d`. It does not use the `Rollout Checklist` / `Platformwide - Period` priority chain. Must pass the same Mo.* Source Gate and reverse sanity check as other `Mo.*` fields. Fill `-` when the source tab lacks `advv_cost_7d` or the gate fails.
- In `2.3 Traffic-Bucket-Exp`, `advv_cost_7d` is sourced from `Ads Type (Ads Data Only) - Period.advv_cost_7d` for all entrance rows, mapped by `target_feature` (`platform=ALL`, `search=Search`, `rcmd_unify=RCMD Unify`, `dd=Daily Discover`, `ymal=You May Also Like`, `cart=Cart Unify`, `game=Game`). Fill `-` if the tab lacks `advv_cost_7d` for a given entrance row; do not fallback to `advv_cost_1d`.
- `Ent. Rev Rel.`, `Ent. Advv Rel.`, and `Ent. GMV Rel.` are entrance-scoped metrics. They require a single explicit or share-filtered entrance, use `Platformwide - Period` first, and fall back to `Ads Type (Ads Data Only) - Period` only when Platformwide lacks the selected entrance metric. In Ads Type, the entrance can be a dimension row such as `target_feature=Game`, not only a `game_*` metric. Do not default them to `platform_*`.
- `VPR abs` is calculated as `(advv_cost_1d_uplift + gmv_995_v2_uplift / 4 - voucher_cost_uplift) / base_voucher_cost_norm`, with all inputs normalized by bucket traffic share first. In `2.3 Traffic-Bucket-Exp`, also render absolute `voucher_profit = advv_cost_1d_uplift + gmv_995_v2_uplift / 4 - voucher_cost_uplift`; it is the VPR numerator and does not divide by `base_voucher_cost_norm`.
- `Mo. Broad GMV (w usd)` and `Mo. Broad GMV 999 (w usd)` are separate fields. For item / plan buckets, fetch them from `GMV & ROI.broad_gmv_usd` and `GMV & ROI.broad_gmv_usd_999`; for traffic buckets, use scale-checked overall `broad_gmv_usd` / `broad_gmv` and `broad_gmv_999` sources, and reject sources whose absolute scale is inconsistent with the rendered relative KPI.
- For traffic-bucket `Mo. Rev` / `Mo. Advv`, use the same business KPI scale as the platform relative metric in `2.3` (usually `Rollout Checklist.platform_revenue_usd` / `platform_advv_cost_1d` for Product Ads). Reject a `Platformwide - Period` absolute source when `(Mo / 30) / base_daily_full_traffic` does not approximately equal the displayed relative uplift.
- In `2.3 Key Metrics List`, confirm bucket type first: traffic-bucket experiments render only `Traffic-Bucket-Exp`, and item / plan-bucket experiments render only `Item-Bucket-Exp`. Do not keep the other bucket table as an empty placeholder after bucket type is known.
- Keep `2.1 Experiment Info` to experiment metadata and necessary data scope only. Do not add `数据结论/Data Observation`; metric evidence belongs in `2.2` / `2.3`, and guardrail conclusions belong in `2.4`.
- In `Traffic-Bucket-Exp`, `Entrance` is a `target_feature` dimension, not a metric prefix. Keep the rollout template rows exactly: `platform/search/rcmd_unify/dd/ymal/cart/game/Guardrail Summary/置信度分析-by day/置信度分析-AA`.
- For traffic-bucket `2.3`, fetch `platform/search/rcmd_unify/dd/ymal/cart` from `Platformwide - Period` by `target_feature`; fetch `game` from `Ads Type (Ads Data Only) - Period` with `target_feature=Game, product_type=all`; fetch `bad_query_rate` from `Rollout Checklist.bad_query_rate` and use it for the search row, Guardrail Summary, and by-day.
- `Guardrail Summary` uses the `platform` row by default, with `bad_query_rate` using `Rollout Checklist.bad_query_rate` as the exception: when a metric value and static threshold both exist, judge `pass/fail`; when a metric value exists but no static threshold exists, default to `pass`; use `-` only for missing source data.
- `置信度分析-by day` is mandatory for both traffic-bucket and item / plan bucket tables. If the period table has a metric value, fetch or compute the matching daily metric and render `x/n`; do not write `-` only because the metric lacks a guardrail threshold, configured direction, or pre-fetched daily query. For item / plan bucket `1d达标率`, by-day uses daily `fulfilled_rev_pct(1d)` from the same row scope as `2.3 1d达标率`. If the daily source cannot be fetched, render `**【待确认】Daily Source**` and record the blocker in Metric Mapping, never `-`. `bad_query_rate` uses `Rollout Checklist.bad_query_rate`, so do not write a daily-source pending placeholder. `置信度分析-AA` counts days where AB daily uplift is positive and greater than the same metric's AA daily uplift; use explicit AA groups first, otherwise use the traffic-normalized mean of multiple control Base buckets when available.
- Daily queries are lazy-loaded. If `exp days = 1`, compute by-day as `1/1` or `0/1` from the period uplift. If AA is unavailable, skip AA-only daily queries; if multiple Base buckets provide AA, reuse the same daily raw result for AB by-day and AA whenever the tab/scope matches.
- `2.4 Guardrail Analysis` must match `2.3 Guardrail Summary`: every `fail` cell is summarized in 2.4, and `pass` / `-` cells are not listed by default; each fail conclusion must show the concrete static threshold, threshold type, direction, fail condition, source, and observed uplift / diff.
- Monthly uplift uses raw non-normalized absolute values and actual selected traffic shares: `monthly_abs_uplift = (exp_abs_raw / exp_traffic_share - base_abs_raw / base_traffic_share) * 30 / exp_days`; divide USD results by `10000` for `w usd`. For item buckets, use the fixed bucket-share mapping when AB share metadata does not include matching groups. If control contains multiple Base buckets, `base_traffic_share` is their summed share. Do not compute `Mo.*` from normalized absolute values or AB report relative uplift. Reverse-check every `Mo.*` cell: `monthly_abs_uplift_w_usd * 10000 * exp_days / 30` must equal `exp_abs_raw / exp_traffic_share - base_abs_raw / base_traffic_share`; values that only match `raw_abs_delta * 30 / exp_days` missed traffic-share normalization. Also check same-source scale: `(monthly_abs_uplift_w_usd / 30) / (base_abs_raw / base_traffic_share / exp_days / 10000)` must approximately equal the displayed relative uplift for the same metric.
- Every generated rollout doc must include Appendix tables for `Guardrail 要求/Guardrail Requirements`, `指标映射关系/Metric Mapping`, and `实验参数变化/Experiment Parameter Changes`. The Guardrail table lists all requirements and concrete values from `references/guardrail-thresholds.yaml`; the Metric Mapping table covers all metric-bearing rollout fields and their AB platform display metric names, source tabs, scopes, and formulas; the parameter-change Appendix lists parameter path, base value, treatment value, change type, source, and notes. A confirmed `no_change` row must be paired with the Project Info risk warning.
- The default output is a saved `.md` file under `tmp/ads-rollout-generate/`; inline Markdown is pasted only when requested.
