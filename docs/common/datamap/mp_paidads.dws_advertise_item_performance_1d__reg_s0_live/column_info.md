<!-- ads-workspace-gdoc-sync: gdoc_id=1G7eFBAb_j4jQCm0E-8xwHZxfiqZky3dG51XcgmbGLtc gdoc_url=https://docs.google.com/document/d/1G7eFBAb_j4jQCm0E-8xwHZxfiqZky3dG51XcgmbGLtc/edit -->

# Columns: mp_paidads.dws_advertise_item_performance_1d__reg_s0_live

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | date partition [PARTITION] | 128/264/584 |  |
| 2 | tz_type | string | timezone partition [PARTITION] | 114/236/522 |  |
| 3 | shop_id | bigint | seller's shop id | 98/205/458 | 1782542494 |
| 4 | impression_cnt_1d | bigint | count of impression on the ads item within one day, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 77/164/348 | 93431 |
| 5 | expenditure_amt_usd_1d | double | ads expenditure amount on ads item level in 1 day in usd, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 68/140/322 | 791.0500059323716 |
| 6 | item_id | bigint | ads item id | 64/136/306 | 58157656489 |
| 7 | grass_region | string | country partition [PARTITION] | 60/126/288 |  |
| 8 | click_cnt_1d | bigint | sum of click count within one day on the ads item, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 56/116/248 | 32617 |
| 9 | ads_gmv_amt_usd_1d | double | sum of ads gmv amount in 1 day in USD, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 47/98/232 | 68646.23294443348 |
| 10 | order_cnt_1d | bigint | ads item order count in 1d, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 47/98/218 | 308 |
| 11 | placement | bigint | placement of the ads item | 30/59/122 | 3339 |
| 12 | ads_id | bigint | Advertisement id | 14/28/59 | 98463190 |
| 13 | expenditure_amt_local_1d | double | Advertiser's expenditure in local currency, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 7/14/29 | 1000.0849699999993 |
| 14 | cpc_local_1d | double | cost per click of the ads item within one day in local currency | 7/14/29 | 86.46497 |
| 15 | cpc_usd_1d | double | cost per click of the ads item within one day in usd currency. | 7/14/29 | 68.39230373739369 |
| 16 | ads_gmv_amt_local_1d | double | total ads item order gmv amount in 1 d in local currency, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 7/14/29 | 86786.0 |
| 17 | ctr_1d | double | click through rate of the ads item in 1d | 7/14/29 | 3.0 |
| 18 | cr_1d | double | conversion rate of the ads item in 1d | 7/14/29 | 34.0 |
| 19 | cir_1d | double | cost in return on item level in 1 day | 7/14/29 | 55.82089999999999 |
| 20 | avg_ads_ranks_1d | double | Average ads position in a page from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 7/14/29 | 1155.0 |

### 查询频率分析

Top 20 字段的查询模式呈现明显的三层结构：

1. **分区字段（最高频）**：`grass_date`（584）、`tz_type`（522）、`grass_region`（288）是查询必备的过滤条件，几乎所有查询都会用到。
2. **核心维度与指标（中高频）**：`shop_id`（458）、`impression_cnt_1d`（348）、`expenditure_amt_usd_1d`（322）、`item_id`（306）、`click_cnt_1d`（248）、`ads_gmv_amt_usd_1d`（232）、`order_cnt_1d`（218）构成了广告效果分析的核心字段，覆盖曝光-点击-花费-转化-GMV 全链路。
3. **衍生比率与本地货币字段（低频）**：`ctr_1d`、`cr_1d`、`cir_1d`、`cpc_local_1d`、`cpc_usd_1d`、`ads_gmv_amt_local_1d`、`avg_ads_ranks_1d` 等衍生指标查询量较低（L30D=29），通常可由基础指标计算得出，用户更多直接使用基础字段自行计算。

> MAX(column): MAX() aggregated values from grass_date=2026-03-25, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| shop_id | bigint | seller's shop id | 98/205/458 | 1782542494 |
| user_name | string | user name of the seller | -/-/- | zzzzlx.sg |
| item_id | bigint | ads item id | 64/136/306 | 58157656489 |
| ads_id | bigint | Advertisement id | 14/28/59 | 98463190 |
| placement | bigint | placement of the ads item | 30/59/122 | 3339 |
| item_name | string | ads item name | -/-/- | ANY room Nordic Style Wall Clock |
| impression_cnt_1d | bigint | count of impression on the ads item within one day, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 77/164/348 | 93431 |
| click_cnt_1d | bigint | sum of click count within one day on the ads item, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 56/116/248 | 32617 |
| expenditure_amt_local_1d | double | Advertiser's expenditure in local currency, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 7/14/29 | 1000.0849699999993 |
| expenditure_amt_usd_1d | double | ads expenditure amount on ads item level in 1 day in usd, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 68/140/322 | 791.0500059323716 |
| cpc_local_1d | double | cost per click of the ads item within one day in local currency | 7/14/29 | 86.46497 |
| cpc_usd_1d | double | cost per click of the ads item within one day in usd currency. | 7/14/29 | 68.39230373739369 |
| order_cnt_1d | bigint | ads item order count in 1d, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 47/98/218 | 308 |
| ads_gmv_amt_local_1d | double | total ads item order gmv amount in 1 d in local currency, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 7/14/29 | 86786.0 |
| ads_gmv_amt_usd_1d | double | sum of ads gmv amount in 1 day in USD, from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 47/98/232 | 68646.23294443348 |
| ctr_1d | double | click through rate of the ads item in 1d | 7/14/29 | 3.0 |
| cr_1d | double | conversion rate of the ads item in 1d | 7/14/29 | 34.0 |
| cir_1d | double | cost in return on item level in 1 day | 7/14/29 | 55.82089999999999 |
| avg_ads_ranks_1d | double | Average ads position in a page from mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live | 7/14/29 | 1155.0 |
| tz_type | string | timezone partition [PARTITION] | 114/236/522 |  |
| grass_region | string | country partition [PARTITION] | 60/126/288 |  |
| grass_date | date | date partition [PARTITION] | 128/264/584 |  |
