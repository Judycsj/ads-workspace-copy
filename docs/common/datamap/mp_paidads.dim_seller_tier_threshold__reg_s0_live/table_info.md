<!-- ads-workspace-gdoc-sync: gdoc_id=10S_thRnh6T9-EUWgUSvgRdcuupUqCYgs6C7X3ZoFXrQ gdoc_url=https://docs.google.com/document/d/10S_thRnh6T9-EUWgUSvgRdcuupUqCYgs6C7X3ZoFXrQ/edit -->

# mp_paidads.dim_seller_tier_threshold__reg_s0_live

## Description

- **Desc:** Seller tier threshold configuration table. Stores the minimum USD GMV thresholds for classifying sellers into tiers (large_seller / medium_seller / small_seller) on a per-region basis. Used by downstream shop info workflows to compute seller_tier values dynamically based on month-over-month GMV comparison.
- **Granularity:** per region (no time dimension; threshold values are set per grass_region)
- **Use Case:**
  - Daily seller tier and status classification in `dim_shop_info__reg_s0_live` (daily workflow) -- maps shop_id to seller_tier by comparing M-o-M GMV against thresholds
  - Monthly seller tier and status classification in `dim_shop_info_monthly__reg_s0_live` / `dim_shop_info_1m__reg_s0_live` (monthly workflow) -- same logic with additional adoption tags
  - Seller tier computation in `ads_advertise_mkt_1d__reg_s0_live` (ads marketing daily) -- lightweight tier computation for ads-level data without full status tracking
- **Update Frequency:** Ad-hoc / On-demand (no scheduled INSERT OVERWRITE found in studio_tasks; thresholds are likely managed externally via DataSuite or configuration system)

## Key Metrics

- Threshold values (USD):
  - **larger_seller_min_value** -- minimum GMV USD for `large_seller` tier
  - **medium_seller_min_value** -- minimum GMV USD for `medium_seller` tier
  - **small_seller_min_value** -- minimum GMV USD for `small_seller` tier (below this = `micro_seller`)

## Key Dimensions

- **seller_tier** -- Tier label: `large_seller`, `medium_seller`, `small_seller` (one row per tier per region)
- **grass_region** -- Region code (e.g. `ID`, `MY`, `PH`, `SG`, `TH`, `TW`, `VN`, `BR`, `MX`)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX (8+ regions, inferred from downstream workflow region files) |
| DQC Status | - |
| Table Size | - |

> Note: No DDL (CREATE TABLE) or INSERT OVERWRITE found in the studio_tasks codebase. This table is likely managed externally (e.g. DataSuite direct upload or configuration service). Run `--source from-di` to get DDL and technical properties from DataMap.

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 51 files (all read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
