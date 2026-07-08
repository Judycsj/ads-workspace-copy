<!-- ads-workspace-gdoc-sync: gdoc_id=1QsDS3EJbco1OKpM1Iaday0Q5qOVZ-NUu6yvOH04q63o gdoc_url=https://docs.google.com/document/d/1QsDS3EJbco1OKpM1Iaday0Q5qOVZ-NUu6yvOH04q63o/edit -->

# Columns: mkplpaidads_search_ads.ads_overall_key_metrics_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨维度聚合时需注意：
- `platform_gmv` — 来自 take_rate 表，生产时用 `SUM(DISTINCT platform_gmv)` 聚合，跨 entrance/pricing_type 汇总时不可直接 SUM

### GROUPING SETS 汇总行

本表使用 GROUPING SETS 生成 16 种维度组合，`entrance`、`pricing_type`、`cluster`、`grass_region` 的 NULL 值被 COALESCE 为 `'ALL'`。查询时：
- `entrance = 'ALL'` 表示所有入口的汇总
- `pricing_type = 'ALL'` 表示所有计费模式的汇总
- `cluster = 'ALL'` 表示所有卖家群组的汇总
- `grass_region = 'ALL'` 表示所有地域的汇总

### 派生字段 (Derived Fields)

- `daily_pgmv_pcoc` = `sum(daily_pgmv_sum_last_7d_clk) / nullif(sum(broad_gmv_usd), 0)` — pGMV 预估校准系数，正常范围 0.9~1.2
- `gross_rev_usd` / `net_ads_rev` — 来自 take_rate 表 JOIN，非直接 SUM campaign 粒度
- `platform_gmv` — 来自 take_rate 表，SUM(DISTINCT)

### 常见 WHERE 值 (Common Filter Values)

- `entrance`: 'ALL' (汇总), 'Search', 'Daily Discover', 'Post Purchase', 'You May Also Like'
- `pricing_type`: 'ALL' (汇总), '11', '15'
- `grass_region`: 'ALL' (汇总), 'ID', 'MY', 'PH', 'SG', 'TH', 'TW', 'VN', 'BR'
- `cluster`: 'ALL' (汇总), 'Unknown', 其他卖家群组值

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | - [PARTITION] | 25/44/127 |  |
| 2 | grass_region | string | - [PARTITION] | 25/44/127 |  |
| 3 | entrance | string | 入口维度（GROUPING SETS 汇总为 ALL） | 25/44/125 | ALL |
| 4 | pricing_type | string | 计费模式维度（GROUPING SETS 汇总为 ALL） | 25/44/125 | ALL |
| 5 | daily_pgmv_pcoc | double | pGMV 预估校准系数 | 25/44/125 | 1118.5807294934277 |
| 6 | revenue_usd | double | 广告收入 (USD) | 18/30/95 | 412356.4918879007 |
| 7 | gross_rev_usd | double | 毛收入 (USD, 来自 take_rate) | 18/30/95 | 412391.235389 |
| 8 | net_ads_rev | double | 净广告收入 (来自 take_rate) | 18/30/95 | 381479.27729280066 |
| 9 | advv_usd | double | 广告验证价值 (USD) | 18/30/95 | 422235.5163349951 |
| 10 | direct_gmv_usd | double | 直接归因 GMV (USD) | 18/30/95 | 2214429.167696299 |
| 11 | broad_gmv_usd | double | 宽口径 GMV (USD) | 18/30/95 | 2720688.7569309 |
| 12 | ads_direct_order | int | 直接归因订单数 | 18/30/95 | 116113 |
| 13 | ads_broad_order | int | 宽口径订单数 | 18/30/95 | 141382 |
| 14 | ads_imp | bigint | 广告曝光数 | 18/30/95 | 99267911 |
| 15 | ads_clk | bigint | 广告点击数 | 18/30/95 | 3560912 |
| 16 | revenue_usd_7d | double | 7日广告收入 (USD) | 18/30/95 | 3164278.9488396966 |
| 17 | advv_usd_7d | double | 7日广告验证价值 (USD) | 18/30/95 | 3336325.1838009483 |
| 18 | ads_broad_order_7d | double | 7日宽口径订单数 | 18/30/95 | 1072505.0 |
| 19 | broad_gmv_usd_7d | double | 7日宽口径 GMV (USD) | 18/30/95 | 22417926.8423698 |
| 20 | ads_imp_7d | bigint | 7日广告曝光数 | 18/30/95 | 647475903 |

### 查询频率分析

Top 20 高频查询字段可分为以下主题：

1. **分区与维度字段**（L30D 125-127）：`grass_date`、`grass_region`、`entrance`、`pricing_type` 是最高频查询字段，几乎所有查询都会用到这些分区和维度进行筛选分组。`daily_pgmv_pcoc` 也属于高频组，反映近期对 pGMV 校准系数的关注。

2. **核心收入与 GMV 指标**（L30D 95）：`revenue_usd`、`gross_rev_usd`、`net_ads_rev`、`advv_usd`、`direct_gmv_usd`、`broad_gmv_usd` 构成广告收入和 GMV 的核心度量，是日常大盘监控的基础。

3. **流量漏斗指标**（L30D 95）：`ads_imp`、`ads_clk` 及 7 日滚动版本 `ads_imp_7d`、`ads_clk_7d` 用于衡量广告曝光和点击效率。

4. **订单与 7 日回溯**（L30D 95）：`ads_direct_order`、`ads_broad_order`、`ads_broad_order_7d`、`broad_gmv_usd_7d` 用于归因分析和延迟转化评估。

整体使用模式显示：该表主要用于搜索广告大盘的日常收入、GMV、流量漏斗监控，按 entrance（入口）和 pricing_type（计费模式）进行切片分析。所有非分区字段的查询频率高度一致（L30D=95），说明查询通常 SELECT 全部指标列。

> MAX(column): MAX() aggregated values from grass_date=2026-06-13, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string | 入口维度（GROUPING SETS 汇总为 ALL） | 25/44/125 | ALL |
| pricing_type | string | 计费模式维度（GROUPING SETS 汇总为 ALL） | 25/44/125 | ALL |
| revenue_usd | double | 广告收入 (USD) | 18/30/95 | 412356.4918879007 |
| gross_rev_usd | double | 毛收入 (USD, 来自 take_rate) | 18/30/95 | 412391.235389 |
| net_ads_rev | double | 净广告收入 (来自 take_rate) | 18/30/95 | 381479.27729280066 |
| advv_usd | double | 广告验证价值 (USD) | 18/30/95 | 422235.5163349951 |
| direct_gmv_usd | double | 直接归因 GMV (USD) | 18/30/95 | 2214429.167696299 |
| broad_gmv_usd | double | 宽口径 GMV (USD) | 18/30/95 | 2720688.7569309 |
| ads_direct_order | int | 直接归因订单数 | 18/30/95 | 116113 |
| ads_broad_order | int | 宽口径订单数 | 18/30/95 | 141382 |
| ads_imp | bigint | 广告曝光数 | 18/30/95 | 99267911 |
| ads_clk | bigint | 广告点击数 | 18/30/95 | 3560912 |
| revenue_usd_7d | double | 7日广告收入 (USD) | 18/30/95 | 3164278.9488396966 |
| advv_usd_7d | double | 7日广告验证价值 (USD) | 18/30/95 | 3336325.1838009483 |
| ads_broad_order_7d | double | 7日宽口径订单数 | 18/30/95 | 1072505.0 |
| broad_gmv_usd_7d | double | 7日宽口径 GMV (USD) | 18/30/95 | 22417926.8423698 |
| ads_imp_7d | bigint | 7日广告曝光数 | 18/30/95 | 647475903 |
| ads_clk_7d | bigint | 7日广告点击数 | 18/30/95 | 23184756 |
| bid_price_sum | double | 出价总和 | 18/30/95 | 21030633.012840074 |
| boost_price_sum | double | 加价总和 | 18/30/95 | 5501207.604359918 |
| expect_deduction_price_sum_raw | double | 预期扣费总和（原始） | 18/30/95 | 892003.6088590003 |
| expect_deduction_price_sum_valid | double | 预期扣费总和（有效） | 18/30/95 | 892003.6088590003 |
| gross_deduction_price_sum | double | 毛扣费总和 | 18/30/95 | 412356.5508553532 |
| net_deduction_price_sum | double | 净扣费总和 | 18/30/95 | 35396499080.05439 |
| raw_deduction_cnt | int | 原始扣费次数 | 18/30/95 | 3931930 |
| valid_deduction_cnt | int | 有效扣费次数 | 18/30/95 | 3176479 |
| troi_sum_by_imp | double | TROI 总和 (按曝光) | 18/30/95 | 921929555.9694601 |
| rt_remain_budget_sum_by_imp | double | 实时剩余预算总和 (按曝光) | 18/30/95 | 35834773406.15165 |
| sold_cnt_sum_by_imp | double | 已售数量总和 (按曝光) | 18/30/95 | 160344663.4384805 |
| item_price_sum_by_imp | double | 商品价格总和 (按曝光) | 18/30/95 | 4079183756.748564 |
| coef_sum_by_imp | double | 出价系数总和 (按曝光) | 18/30/95 | 153426371.85941502 |
| pctr_sum_by_imp | double | pCTR 预估总和 (按曝光) | 18/30/95 | 4277807.437248326 |
| pcr_direct_sum_by_imp | double | 直接 pCR 预估总和 (按曝光) | 18/30/95 | 2644514.1089015817 |
| pcr_direct_fail_imp_cnt | bigint | 直接 pCR 预估失败曝光数 | 18/30/95 | 6331556 |
| pcr_broad_sum_by_imp | double | 宽口径 pCR 预估总和 (按曝光) | 18/30/95 | 3332428.8494213177 |
| pgmv_direct_sum_by_imp | double | 直接 pGMV 预估总和 (按曝光) | 18/30/95 | 59061647.96301146 |
| pgmv_broad_sum_by_imp | double | 宽口径 pGMV 预估总和 (按曝光) | 18/30/95 | 79337653.77503446 |
| final_pgmv_sum_by_imp | double | 最终 pGMV 预估总和 (按曝光) | 18/30/95 | 177425452.9636841 |
| padvv_sum_by_imp | double | pADVV 预估总和 (按曝光) | 18/30/95 | 14890533.656741224 |
| ecpm_sum_by_imp | double | eCPM 总和 (按曝光) | 18/30/95 | 961177.2043823178 |
| pcr_direct_sum_by_clk | double | 直接 pCR 预估总和 (按点击) | 18/30/95 | 114935.36782605218 |
| pcr_broad_sum_by_clk | double | 宽口径 pCR 预估总和 (按点击) | 18/30/95 | 137620.54062538332 |
| pgmv_direct_sum_by_clk | double | 直接 pGMV 预估总和 (按点击) | 18/30/95 | 2342704.0787210725 |
| pgmv_broad_sum_by_clk | double | 宽口径 pGMV 预估总和 (按点击) | 18/30/95 | 2949069.7648054673 |
| final_pgmv_sum_by_clk | double | 最终 pGMV 预估总和 (按点击) | 18/30/95 | 26859049.411859103 |
| padvv_sum_by_clk | double | pADVV 预估总和 (按点击) | 18/30/95 | 556615.9304692483 |
| ecpc_sum_by_clk | double | eCPC 总和 (按点击) | 18/30/95 | 102355.35028012545 |
| request_cnt | bigint | 请求数 | 18/30/95 | 1060560650 |
| after_recall_num | bigint | 召回后数量 | 18/30/95 | 1005003616 |
| ads_after_recall_num | bigint | 广告召回后数量 | 18/30/95 | 545047595 |
| org_after_recall_num | bigint | 自然结果召回后数量 | 18/30/95 | 556322744 |
| after_prerank_num | bigint | 预排序后数量 | 18/30/95 | 562204208 |
| after_rank_num | bigint | 排序后数量 | 18/30/95 | 138386525 |
| after_mixrank_num | bigint | 混排后数量 | 18/30/95 | 11480700 |
| daily_advv_sum_last_7d_clk | bigint | 7日 pADVV 预估总和 (按点击) | 18/30/95 | NULL |
| daily_pgmv_direct_sum_last_7d_clk | bigint | 7日直接 pGMV 预估总和 (按点击) | 18/30/95 | NULL |
| daily_pgmv_broad_sum_last_7d_clk | bigint | 7日宽口径 pGMV 预估总和 (按点击) | 18/30/95 | NULL |
| daily_pgmv_pcoc | double | pGMV 预估校准系数 (pCOC) | 25/44/125 | 1118.5807294934277 |
| ads_imp_cnt | bigint | omni 广告曝光数 | 18/30/95 | 67156650 |
| ads_clk_cnt | bigint | omni 广告点击数 | 18/30/95 | 2557889 |
| ads_order_cnt | bigint | omni 广告订单数 | 18/30/95 | 89430 |
| ads_gmv_usd | double | omni 广告 GMV (USD) | 18/30/95 | 1582470.4649933898 |
| total_imp | bigint | 全渠道曝光数 | 18/30/95 | 86914699 |
| total_clk | bigint | 全渠道点击数 | 18/30/95 | 3248693 |
| total_order | bigint | 全渠道订单数 | 18/30/95 | 112229 |
| total_gmv | double | 全渠道 GMV (USD) | 18/30/95 | 2160302.854631041 |
| platform_gmv | double | 平台 GMV (⚠️ SUM DISTINCT) | 18/30/95 | 6810732.033666114 |
| cluster | string | 卖家群组 | 18/30/70 | Unknown |
| grass_date | date | [PARTITION] 日期分区 | 25/44/127 |  |
| grass_region | string | [PARTITION] 地域分区 | 25/44/127 |  |
