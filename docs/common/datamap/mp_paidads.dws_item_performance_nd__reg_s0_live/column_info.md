<!-- ads-workspace-gdoc-sync: gdoc_id=1OegdKl73c-vZa7dYCljs-imLPy3JpA2Uldytq9VoVqo gdoc_url=https://docs.google.com/document/d/1OegdKl73c-vZa7dYCljs-imLPy3JpA2Uldytq9VoVqo/edit -->

# Columns: mp_paidads.dws_item_performance_nd__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表粒度为 item x day x region，所有指标均为可直接 SUM 的累加字段（item 级别的单日快照）。未发现 SUM(DISTINCT) 或最大-最小依赖的非累加字段。

注意：跨 item 聚合时，algo_item_price / algo_paid_item_price 等价格类字段需要加权平均（按 order_cnt 加权），不能直接 AVG。

### 枚举值映射 (Value Mappings)

*from-code 模式：未在 2+ 个读文件中发现重复的 CASE-WHEN 枚举映射*

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (本表固定写 'local'，查询也固定使用 'local')
- `grass_region`: upper('${region}') — 按区域变量过滤
- `grass_date`: date('${BIZ_YESTERDAY}') — 查询最新分区
- `platform_order_cnt_30d > 0`: 过滤有出单的商品
- `platform_order_cnt_30d >= 10`: 30d10o 条件（需要至少10单的商品）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | item id | - | - |
| shop_id | bigint | shop id | - | - |
| item_create_timestamp | bigint | item create timestamp | - | - |
| item_create_datetime | string | item create datetime | - | - |
| level1_category_id | bigint | level1 category id | - | - |
| level1_category_name | string | level1 category name | - | - |
| level2_category_id | bigint | level2 category id | - | - |
| level2_category_name | string | level2 category name | - | - |
| level3_category_id | bigint | level3 category id | - | - |
| level3_category_name | string | level3 category name | - | - |
| is_ads_item_1d | tinyint | item had product ads in last 1 day | - | - |
| is_ads_item_7d | tinyint | item had product ads in last 7 days | - | - |
| is_gms_ads_item_1d | tinyint | item had gms ads in last 1 day | - | - |
| is_new_item_30d | tinyint | Item creation time is within 30 days | - | - |
| platform_impression_cnt_1d | bigint | platform impression cnt 1d | - | - |
| platform_impression_cnt_7d | bigint | platform impression cnt 7d | - | - |
| platform_impression_cnt_30d | bigint | platform impression cnt 30d | - | - |
| platform_click_cnt_1d | bigint | platform click cnt 1d | - | - |
| platform_click_cnt_7d | bigint | platform click cnt 7d | - | - |
| platform_click_cnt_30d | bigint | platform click cnt 30d | - | - |
| platform_order_cnt_1d | bigint | platform order cnt 1d | - | - |
| platform_order_cnt_7d | bigint | platform order cnt 7d | - | - |
| platform_order_cnt_14d | bigint | platform order cnt 14d | - | - |
| platform_order_cnt_30d | bigint | platform order cnt 30d | - | - |
| platform_gmv_usd_1d | double | platform gmv usd 1d | - | - |
| platform_gmv_usd_7d | double | platform gmv usd 7d | - | - |
| platform_gmv_usd_14d | double | platform gmv usd 14d | - | - |
| platform_gmv_usd_30d | double | platform gmv usd 30d | - | - |
| ads_impression_cnt_1d | bigint | ads impression cnt 1d | - | - |
| ads_impression_cnt_7d | bigint | ads impression cnt 7d | - | - |
| ads_impression_cnt_30d | bigint | ads impression cnt 30d | - | - |
| ads_click_cnt_1d | bigint | ads click cnt 1d | - | - |
| ads_click_cnt_7d | bigint | ads click cnt 7d | - | - |
| ads_click_cnt_30d | bigint | ads click cnt 30d | - | - |
| ads_broad_order_cnt_1d | bigint | ads broad order cnt 1d | - | - |
| ads_broad_order_cnt_7d | bigint | ads broad order cnt 7d | - | - |
| ads_broad_order_cnt_30d | bigint | ads broad order cnt 30d | - | - |
| ads_expenditure_amt_local_1d | double | ads expenditure amt local 1d | - | - |
| ads_expenditure_amt_local_7d | double | ads expenditure amt local 7d | - | - |
| ads_expenditure_amt_local_30d | double | ads expenditure amt local 30d | - | - |
| ads_expenditure_amt_usd_1d | double | ads expenditure amt usd 1d | - | - |
| ads_expenditure_amt_usd_7d | double | ads expenditure amt usd 7d | - | - |
| ads_expenditure_amt_usd_30d | double | ads expenditure amt usd 30d | - | - |
| ads_broad_gmv_amt_local_1d | double | ads broad gmv amt local 1d | - | - |
| ads_broad_gmv_amt_local_7d | double | ads broad gmv amt local 7d | - | - |
| ads_broad_gmv_amt_local_30d | double | ads broad gmv amt local 30d | - | - |
| ads_broad_gmv_amt_usd_1d | double | ads broad gmv amt usd 1d | - | - |
| ads_broad_gmv_amt_usd_7d | double | ads broad gmv amt usd 7d | - | - |
| ads_broad_gmv_amt_usd_30d | double | ads broad gmv amt usd 30d | - | - |
| ads_paid_broad_order_cnt_1d | bigint | ads paid broad order cnt 1d | - | - |
| ads_paid_broad_order_cnt_7d | bigint | ads paid broad order cnt 7d | - | - |
| ads_paid_broad_order_cnt_30d | bigint | ads paid broad order cnt 30d | - | - |
| ads_paid_broad_order_gmv_1d | double | ads paid broad order gmv 1d | - | - |
| ads_paid_broad_order_gmv_7d | double | ads paid broad order gmv 7d | - | - |
| ads_paid_broad_order_gmv_30d | double | ads paid broad order gmv 30d | - | - |
| ads_paid_broad_order_gmv_usd_1d | double | ads paid broad order gmv usd 1d | - | - |
| ads_paid_broad_order_gmv_usd_7d | double | ads paid broad order gmv usd 7d | - | - |
| ads_paid_broad_order_gmv_usd_30d | double | ads paid broad order gmv usd 30d | - | - |
| gross_ads_revenue_usd_1d | double | ads gross revenue usd 1d | - | - |
| gross_ads_revenue_usd_7d | double | ads gross revenue usd 7d | - | - |
| gross_ads_revenue_usd_30d | double | ads gross revenue usd 30d | - | - |
| algo_item_price | double | item price calculate by algo team, local currency | - | - |
| algo_item_price_usd | double | item price calculate by algo team, usd currency | - | - |
| algo_paid_item_price | double | paid item price calculate by algo team, local currency | - | - |
| algo_paid_item_price_usd | double | paid item price calculate by algo team, usd currency | - | - |
| platform_gmv_local_1d | double | platform gmv local 1d | - | - |
| platform_gmv_local_7d | double | platform gmv local 7d | - | - |
| platform_gmv_local_14d | double | platform gmv local 14d | - | - |
| platform_gmv_local_30d | double | platform gmv local 30d | - | - |
| tz_type | string [PARTITION] | timezone type | - | - |
| grass_region | string [PARTITION] | partition key | - | - |
| grass_date | date [PARTITION] | partition key, yyyy-MM-dd | - | - |
