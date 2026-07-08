<!-- ads-workspace-gdoc-sync: gdoc_id=19jfe9GFBfweeXTgr3SMEHfx9GLVsDioza24FiJVq1mU gdoc_url=https://docs.google.com/document/d/19jfe9GFBfweeXTgr3SMEHfx9GLVsDioza24FiJVq1mU/edit -->

# mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live

## Description

**Table Description**

This Hive table is the ROI3 P0 daily base metrics source table. It consolidates performance-side ads delivery metrics and unified-order-side voucher redeem metrics into one daily diagnosis table for ROI3 analysis.

**Aliases / Search Keywords**

| Alias | Meaning | Real Table |
|---|---|---|
| `roi3_base_hive` | ROI3 P0 Hive source-of-truth table | `mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live` |
| `roi3_base_source` | ROI3 P0 source table | Same as above |
| `roi3_p0_hive` | ROI3 P0 daily diagnosis Hive table | Same as above |

**ClickHouse Serving Copy**

```text
mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live
```

The ClickHouse copy is used as a low-latency serving layer and has alias `roi3_base_clickhouse`. Hive remains the source of truth and should be used when joining with other Hive tables.

**Granularity**

```text
grass_date + grass_region + exp_tag + entrance + pricing_type + local_hour
```

`local_hour` is the region-local business hour `0..23` (KP1 v2 added the "local hour split"); it is an additional breakdown dimension under the same daily partition. `exp_tag = 'all'` represents the overall market. Numeric `exp_tag` values represent specific experiment buckets and should not be directly summed across buckets unless the experiment traffic design explicitly allows it.

**Use Case**

- Join ROI3 base metrics with other Hive tables.
- Validate ClickHouse synced data against Hive source data.
- Produce source-of-truth daily ROI3 metrics by region, entrance, pricing type, and experiment tag.
- Analyze ads voucher exposure, click, order, redeem, cost, and platform GMV impact.
- Support `ads-text2da` table selection when users ask for `roi3_base_hive`.

**Update Frequency**

Daily. The table is produced by the ROI3 P0 Spark task.

## Technical Properties

| Property | Value |
|---|---|
| **Storage Type** | Hive |
| **Database** | `mkplpaidads_search_ads` |
| **Table** | `ads_roi3_strategy_algo_metrics_1d__reg_s0_live` |
| **Alias** | `roi3_base_hive` |
| **ClickHouse Mirror Alias** | `roi3_base_clickhouse` |
| **Spark Task** | `mkplpaidads_search_ads.studio_11684045` |
| **Partition Keys** | `grass_date`, `grass_region` |
| **Grain Keys** | `grass_date`, `grass_region`, `exp_tag`, `entrance`, `pricing_type`, `local_hour` |
| **Market Region** | REG |
| **DW Layer** | ROI3 project ADS / base diagnosis table |

## Source Logic Summary

| Metric Family | Source | Notes |
|---|---|---|
| Ads performance metrics | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | Exposure, click, direct/broad order, direct/broad GMV, cost, ADVV, ads voucher traffic proxy. |
| Voucher redeem metrics | Unified order event / order-side data | Platform order, platform GMV, ads voucher redeem, ads voucher cost, total voucher cost. |
| Experiment tag | AB experiment user assignment joined to performance/order users | `all` is the overall market; numeric tags are experiment buckets. |

## Query Guidance

- Use this Hive table when the analysis needs to join with other Hive tables.
- Use the ClickHouse mirror `roi3_base_clickhouse` for low-latency standalone aggregation and report serving.
- For experiment bucket analysis, keep bucket traffic allocation in mind; experiment bucket rows are not generic additive dimensions.

## Business Properties

| Property | Value |
|---|---|
| **Team** | mkplpaidads / Search Ads |
| **Business Domain** | Marketplace - Paid Ads |
| **Data Topic** | ROI3 strategy monitoring |
| **Owner Context** | KR3-KP1 ROI3 P0 daily diagnosis data foundation |
| **Sensitivity Level** | Internal ads analysis data |

## Completeness & Popularity

- **Completeness**: ROI3 project source-of-truth table KB.
- **Popularity**: Expected to be used for source validation, Hive joins, daily report checks, and experiment analysis.
