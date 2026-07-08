<!-- ads-workspace-gdoc-sync: gdoc_id=16k0-oFFomo2QIZuhWHg41NRoqrf7WYbMjCamj8nfBMw gdoc_url=https://docs.google.com/document/d/16k0-oFFomo2QIZuhWHg41NRoqrf7WYbMjCamj8nfBMw/edit -->

# SQL Patterns: mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live

## Aliases

When users mention `roi3_base_clickhouse`, `roi3_base_ck`, or `roi3_p0_clickhouse`, use this ClickHouse table.

If users mention `roi3_base_hive`, use the source Hive table instead:

```text
mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
```

## Critical Query Rule

Always use ClickHouse `cluster(...)` table function for this table:

```sql
FROM cluster(
    'cluster_mkplpaidads_mkplpaidads_search_ads_online',
    'mkplpaidads_search_ads_ads_debug',
    'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
)
```

Do not query `mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live` directly through the VIP. Direct local-table queries can hit a single shard or replica and return incomplete data.

## Source Relationship

This ClickHouse table is synced from the Hive source table:

```text
mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
```

The ClickHouse table keeps the same grain and metrics. Hive is the source of truth; ClickHouse is the serving layer.

## Common WHERE Filters

- `grass_date = toDate('YYYY-MM-DD')` — 单日查询。
- `grass_date BETWEEN toDate('YYYY-MM-DD') AND toDate('YYYY-MM-DD')` — 日期范围查询。
- `grass_region = 'ID'` — 单地区查询。
- `grass_region IN ('ID', 'TH', 'VN', 'MY', 'SG', 'PH', 'TW')` — 多地区查询。
- `exp_tag = 'all'` — 整体大盘。
- `exp_tag = '656433'` — 单个实验桶。
- `entrance >= 0` — 只看广告流量入口；`entrance = -1` 为非广告订单补齐行。
- `pricing_type >= 0` — 只看广告计费类型；`pricing_type = -1` 为非广告订单补齐行。
- `local_hour BETWEEN 0 AND 23` — 区域本地业务小时过滤；支持分时段（hourly）下钻。

> 该表已提供分时段拆分维度 `local_hour`（区域本地业务小时 0-23），可在上述每日粒度上进一步按小时下钻。

## Common Aggregations

```sql
sum(imp) AS imp
sum(clk) AS clk
sum(broad_order) AS broad_order
sum(direct_order) AS direct_order
sum(broad_gmv) AS broad_gmv
sum(direct_gmv) AS direct_gmv
sum(advv) AS advv
sum(cost) AS cost
sum(ads_voucher_imp) AS ads_voucher_imp
sum(ads_voucher_clk) AS ads_voucher_clk
sum(ads_voucher_order) AS ads_voucher_order
sum(ads_voucher_gmv) AS ads_voucher_gmv
sum(ads_voucher_advv) AS ads_voucher_advv
sum(ads_voucher_ads_cost) AS ads_voucher_ads_cost
sum(ads_voucher_claim) AS ads_voucher_claim
sum(platform_order_cnt) AS platform_order_cnt
sum(ads_order_cnt) AS ads_order_cnt
sum(platform_gmv) AS platform_gmv
sum(ads_platform_gmv) AS ads_platform_gmv
sum(ads_voucher_redeem) AS ads_voucher_redeem
sum(ads_voucher_cost) AS ads_voucher_cost
sum(ads_voucher_platform_gmv) AS ads_voucher_platform_gmv
sum(total_redeem) AS total_redeem
sum(total_voucher_cost) AS total_voucher_cost
sum(total_voucher_platform_gmv) AS total_voucher_platform_gmv
```

## Representative SQL Snippets

### Snippet 1: 单日单地区单实验桶基础指标

```sql
SELECT
    count() AS row_cnt,
    sum(imp) AS imp,
    sum(clk) AS clk,
    sum(broad_order) AS broad_order,
    sum(direct_order) AS direct_order,
    sum(broad_gmv) AS broad_gmv,
    sum(direct_gmv) AS direct_gmv,
    sum(advv) AS advv,
    sum(cost) AS cost,
    sum(ads_voucher_imp) AS ads_voucher_imp,
    sum(ads_voucher_clk) AS ads_voucher_clk,
    sum(ads_voucher_order) AS ads_voucher_order,
    sum(ads_voucher_gmv) AS ads_voucher_gmv,
    sum(ads_voucher_advv) AS ads_voucher_advv,
    sum(ads_voucher_ads_cost) AS ads_voucher_ads_cost,
    sum(ads_voucher_claim) AS ads_voucher_claim,
    sum(platform_order_cnt) AS platform_order_cnt,
    sum(ads_order_cnt) AS ads_order_cnt,
    sum(platform_gmv) AS platform_gmv,
    sum(ads_platform_gmv) AS ads_platform_gmv,
    sum(ads_voucher_redeem) AS ads_voucher_redeem,
    sum(ads_voucher_cost) AS ads_voucher_cost,
    sum(ads_voucher_platform_gmv) AS ads_voucher_platform_gmv,
    sum(total_redeem) AS total_redeem,
    sum(total_voucher_cost) AS total_voucher_cost,
    sum(total_voucher_platform_gmv) AS total_voucher_platform_gmv
FROM cluster(
    'cluster_mkplpaidads_mkplpaidads_search_ads_online',
    'mkplpaidads_search_ads_ads_debug',
    'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
)
WHERE grass_date = toDate('2026-05-08')
  AND grass_region = 'ID'
  AND exp_tag = '656433';
```

### Snippet 2: ROI 和券成本衍生指标

```sql
SELECT
    grass_date,
    grass_region,
    exp_tag,
    sum(imp) AS imp,
    sum(clk) AS clk,
    sum(cost) AS cost,
    sum(broad_gmv) AS broad_gmv,
    sum(direct_gmv) AS direct_gmv,
    sum(advv) AS advv,
    if(sum(imp) = 0, 0, sum(clk) / sum(imp)) AS click_ctr,
    if(sum(clk) = 0, 0, sum(direct_order) / sum(clk)) AS direct_cvr,
    if(sum(cost) = 0, 0, sum(broad_gmv) / sum(cost)) AS broad_roi,
    if(sum(cost) = 0, 0, sum(direct_gmv) / sum(cost)) AS direct_roi,
    if(sum(cost) = 0, 0, sum(advv) / sum(cost)) AS advv_roi,
    if(sum(ads_voucher_platform_gmv) = 0, 0, sum(ads_voucher_cost) / sum(ads_voucher_platform_gmv)) AS ads_voucher_cost_rate
FROM cluster(
    'cluster_mkplpaidads_mkplpaidads_search_ads_online',
    'mkplpaidads_search_ads_ads_debug',
    'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
)
WHERE grass_date = toDate('2026-05-08')
  AND grass_region = 'ID'
  AND exp_tag IN ('all', '656433')
GROUP BY grass_date, grass_region, exp_tag
ORDER BY grass_date, grass_region, exp_tag;
```

### Snippet 3: 分区和同步状态检查

```sql
SELECT
    grass_date,
    grass_region,
    count() AS row_cnt,
    uniqExact(exp_tag) AS exp_tag_cnt,
    sum(imp) AS imp,
    sum(cost) AS cost,
    sum(ads_voucher_cost) AS ads_voucher_cost
FROM cluster(
    'cluster_mkplpaidads_mkplpaidads_search_ads_online',
    'mkplpaidads_search_ads_ads_debug',
    'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
)
WHERE grass_date BETWEEN toDate('2026-05-04') AND toDate('2026-05-08')
GROUP BY grass_date, grass_region
ORDER BY grass_date DESC, grass_region;
```

### Snippet 4: base vs exp 提升比例

Use weighted bucket aggregation outside this table only when the experiment traffic allocation is known. For the ROI3 2026-05-08 ID check, base buckets were `656430`, `656431`, and exp buckets were `656433` to `656440`.

```sql
WITH bucket_metrics AS (
    SELECT
        grass_date,
        grass_region,
        multiIf(
            exp_tag IN ('656430', '656431'), 'base',
            exp_tag IN ('656433', '656434', '656435', '656436', '656437', '656438', '656439', '656440'), 'exp',
            'other'
        ) AS group_type,
        sum(cost) AS cost,
        sum(broad_gmv) AS broad_gmv,
        sum(direct_gmv) AS direct_gmv,
        sum(advv) AS advv,
        sum(platform_gmv) AS platform_gmv,
        sum(ads_voucher_cost) AS ads_voucher_cost
    FROM cluster(
        'cluster_mkplpaidads_mkplpaidads_search_ads_online',
        'mkplpaidads_search_ads_ads_debug',
        'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
    )
    WHERE grass_date = toDate('2026-05-08')
      AND grass_region = 'ID'
      AND exp_tag IN ('656430', '656431', '656433', '656434', '656435', '656436', '656437', '656438', '656439', '656440')
    GROUP BY grass_date, grass_region, group_type
)
SELECT
    grass_date,
    grass_region,
    group_type,
    cost,
    broad_gmv,
    direct_gmv,
    advv,
    platform_gmv,
    ads_voucher_cost,
    if(cost = 0, 0, broad_gmv / cost) AS broad_roi,
    if(cost = 0, 0, direct_gmv / cost) AS direct_roi,
    if(cost = 0, 0, advv / cost) AS advv_roi
FROM bucket_metrics
WHERE group_type IN ('base', 'exp')
ORDER BY grass_date, grass_region, group_type;
```
