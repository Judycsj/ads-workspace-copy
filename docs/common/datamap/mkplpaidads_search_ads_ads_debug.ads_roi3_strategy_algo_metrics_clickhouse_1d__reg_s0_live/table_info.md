<!-- ads-workspace-gdoc-sync: gdoc_id=1MrfbwuojZf_UdnL6OSU0GpnGdi_VQBosdgl8PYoLiMA gdoc_url=https://docs.google.com/document/d/1MrfbwuojZf_UdnL6OSU0GpnGdi_VQBosdgl8PYoLiMA/edit -->

# mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live

## Description

**Table Description**

This ClickHouse table is the low-latency serving copy of the ROI3 P0 daily strategy and algorithm metrics table. It is used for daily report, anomaly scan, experiment bucket comparison, and fast drill-down by region, entrance, pricing type, and experiment tag.

**Aliases / Search Keywords**

| Alias | Meaning | Real Table |
|---|---|---|
| `roi3_base_clickhouse` | ROI3 P0 ClickHouse serving table | `mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live` |
| `roi3_base_ck` | Short alias for ROI3 P0 ClickHouse serving table | Same as above |
| `roi3_p0_clickhouse` | ROI3 P0 daily diagnosis ClickHouse table | Same as above |

**Source Hive Table**

```text
mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
```

The ClickHouse table mirrors the Hive source table with the same grain and metric fields. Hive remains the source of truth; ClickHouse is the query acceleration layer for analysis and reporting.

**Granularity**

```text
grass_date + grass_region + exp_tag + entrance + pricing_type + local_hour
```

`local_hour` is the region-local business hour (0-23), added by KP1 v2 as a local-hour split dimension; each daily partition is further broken down by local hour.

`exp_tag = 'all'` represents the overall market. Numeric `exp_tag` values represent specific experiment buckets and should not be directly summed across buckets unless the experiment traffic design explicitly allows it.

**Use Case**

- Query ROI3 P0 daily metrics quickly for one or more regions.
- Compare experiment buckets against base buckets.
- Calculate ROI-style metrics such as broad GMV / cost, direct GMV / cost, ADVV / cost, and revenue-related ratios.
- Track ads voucher exposure, claim, redeem, cost, and platform GMV impact.
- Support `ads-text2da` analysis over ROI3 daily report and diagnosis data.

**Update Frequency**

Daily. Data is synced from the source Hive table through DataHub Hive to ClickHouse.

## Technical Properties

| Property | Value |
|---|---|
| **Storage Type** | ClickHouse |
| **Cluster** | `cluster_mkplpaidads_mkplpaidads_search_ads_online` |
| **Database** | `mkplpaidads_search_ads_ads_debug` |
| **Table** | `ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live` |
| **Source Hive Table** | `mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live` |
| **DataHub Task** | `mkplpaidads_search_ads.datahub.etl_batch.433019` |
| **Engine** | `ReplicatedMergeTree` |
| **Partition Key** | `grass_date` |
| **Order Key** | `(grass_date, grass_region, exp_tag, entrance, pricing_type, local_hour)` |
| **Market Region** | REG |
| **DW Layer** | Serving / Debug ClickHouse mirror |

## Query Requirement

Always query this table through ClickHouse `cluster(...)` table function:

```sql
FROM cluster(
    'cluster_mkplpaidads_mkplpaidads_search_ads_online',
    'mkplpaidads_search_ads_ads_debug',
    'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
)
```

Do not query the local table name directly through a ClickHouse VIP, because it may hit only one local shard or replica and return incomplete results.

## Business Properties

| Property | Value |
|---|---|
| **Team** | mkplpaidads / Search Ads |
| **Business Domain** | Marketplace - Paid Ads |
| **Data Topic** | ROI3 strategy monitoring |
| **Owner Context** | KR3-KP1 ROI3 P0 daily diagnosis data foundation |
| **Sensitivity Level** | Internal ads analysis data |

## Completeness & Popularity

- **Completeness**: Newly added ROI3 project table KB.
- **Popularity**: Expected to be used by ROI3 daily report, experiment analysis, and `ads-text2da` follow-up queries.
