<!-- ads-workspace-gdoc-sync: gdoc_id=14iSFKcLbrxvmO7bA5W_EX-fiEZ9NhPhr2eb6cWNp2wA gdoc_url=https://docs.google.com/document/d/14iSFKcLbrxvmO7bA5W_EX-fiEZ9NhPhr2eb6cWNp2wA/edit -->

# SQL Patterns: mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live

## Aliases

When users mention `roi3_base_hive`, `roi3_base_source`, or `roi3_p0_hive`, use this Hive table:

```text
mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
```

When users mention `roi3_base_clickhouse`, use the ClickHouse mirror instead:

```text
mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live
```

## Common WHERE Filters

- `grass_date = date 'YYYY-MM-DD'` — 单日查询。
- `grass_date BETWEEN date 'YYYY-MM-DD' AND date 'YYYY-MM-DD'` — 日期范围查询。
- `grass_region = 'ID'` — 单地区查询。
- `grass_region IN ('ID', 'TH', 'VN', 'MY', 'SG', 'PH', 'TW')` — 多地区查询。
- `exp_tag = 'all'` — 整体大盘。
- `exp_tag = '656433'` — 单个实验桶。
- `entrance >= 0` — 只看广告流量入口；`entrance = -1` 为非广告订单补齐行。
- `pricing_type >= 0` — 只看广告计费类型；`pricing_type = -1` 为非广告订单补齐行。
- `local_hour = 14` — 单个本地业务小时（`0..23`）；不加该过滤可聚合全天。
- `local_hour BETWEEN 9 AND 18` — 分时段（本地小时区间）下钻。

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
    count(*) AS row_cnt,
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
FROM mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
WHERE grass_date = date '2026-05-08'
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
    if(sum(imp) = 0, 0, sum(clk) * 1.000000 / sum(imp)) AS click_ctr,
    if(sum(clk) = 0, 0, sum(direct_order) * 1.000000 / sum(clk)) AS direct_cvr,
    if(sum(cost) = 0, 0, sum(broad_gmv) / sum(cost)) AS broad_roi,
    if(sum(cost) = 0, 0, sum(direct_gmv) / sum(cost)) AS direct_roi,
    if(sum(cost) = 0, 0, sum(advv) / sum(cost)) AS advv_roi,
    if(sum(ads_voucher_platform_gmv) = 0, 0, sum(ads_voucher_cost) / sum(ads_voucher_platform_gmv)) AS ads_voucher_cost_rate
FROM mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
WHERE grass_date = date '2026-05-08'
  AND grass_region = 'ID'
  AND exp_tag IN ('all', '656433')
GROUP BY grass_date, grass_region, exp_tag
ORDER BY grass_date, grass_region, exp_tag;
```

### Snippet 3: Hive source vs ClickHouse mirror 对账

Use this Hive table as source of truth. For ClickHouse checks, query alias `roi3_base_clickhouse` with `cluster(...)`.

```sql
SELECT
    grass_date,
    grass_region,
    exp_tag,
    count(*) AS row_cnt,
    sum(imp) AS imp,
    sum(cost) AS cost,
    sum(ads_voucher_cost) AS ads_voucher_cost
FROM mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
WHERE grass_date BETWEEN date '2026-05-04' AND date '2026-05-08'
  AND grass_region = 'ID'
  AND exp_tag IN ('all', '656433')
GROUP BY grass_date, grass_region, exp_tag
ORDER BY grass_date DESC, grass_region, exp_tag;
```

### Snippet 4: base vs exp 基础聚合

```sql
WITH bucket_metrics AS (
    SELECT
        grass_date,
        grass_region,
        CASE
            WHEN exp_tag IN ('656430', '656431') THEN 'base'
            WHEN exp_tag IN ('656433', '656434', '656435', '656436', '656437', '656438', '656439', '656440') THEN 'exp'
            ELSE 'other'
        END AS group_type,
        sum(cost) AS cost,
        sum(broad_gmv) AS broad_gmv,
        sum(direct_gmv) AS direct_gmv,
        sum(advv) AS advv,
        sum(platform_gmv) AS platform_gmv,
        sum(ads_voucher_cost) AS ads_voucher_cost
    FROM mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live
    WHERE grass_date = date '2026-05-08'
      AND grass_region = 'ID'
      AND exp_tag IN ('656430', '656431', '656433', '656434', '656435', '656436', '656437', '656438', '656439', '656440')
    GROUP BY 1, 2, 3
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
