<!-- ads-workspace-gdoc-sync: gdoc_id=1JUwns1xv5uBpee4OdWdROZXgE4xGjPYtATj8qlOkvK8 gdoc_url=https://docs.google.com/document/d/1JUwns1xv5uBpee4OdWdROZXgE4xGjPYtATj8qlOkvK8/edit -->

# Columns: mp_mgmt.dws_order_item_rev_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 order_id/item_id 聚合时注意以下字段不具备加性，需按 group_id/model_id/bundle_order_item_id 粒度 join 后聚合：
- `commission_base_amt_usd`, `commission_fee_usd`, `service_fee_usd` -- 汇总级别字段，在 item 粒度聚合时可直接 SUM

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| is_bi_excluded_rev_prm | 0 | Normal (not excluded for revenue/prm) |
| is_bi_excluded_rev_prm | 1 | BI excluded (test orders etc.) |
| is_bi_excluded_order | 0 | Normal (not excluded) |
| is_bi_excluded_order | 1 | BI excluded order |
| is_returned_item | 0 | Not returned |
| is_returned_item | 1 | Item returned |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: `= upper('${region}')` (~70% queries) / `IN (${region})` (multi-region, ~20%)
- `grass_date`: range filter `BETWEEN date('${grass_date_30day}') AND date('${grass_date}')`, or single day `= date '${BIZ_YESTERDAY}'`
- `is_bi_excluded_rev_prm`: `= 0` (~80% of queries, exclude test/bi-excluded orders)
- `is_bi_excluded_order`: `= 0` (exclude bi-excluded orders)
- `cancel_datetime`: `IS NULL` (filter cancelled orders)
- `is_returned_item`: `= 0` (filter returned items)
- `regional_create_date`: `>= date('${grass_date_30day}') AND < date_add(date('${grass_date}'), 1)` for time-range filtering

### 佣金字段结构说明

- **Level 1** 字段 (`_level1` 后缀): 最细粒度佣金估算，按费率 × 金额计算
- **Level 2** 字段 (`_level2` 后缀): 汇总级别，如 `estimate_other_revenue_usd_level2`
- **shop type 拆分**: `local_c2c` (MP), `local_mall` (Mall), `cb` (Cross Border) 三种店铺类型各有独立的 commission 字段
- **commission_base_amt_usd**: 佣金计算基数（GMV 或子集），用于模型训练特征
- **commission_fee_usd**: 实际佣金费用总额
- **service_fee_usd**: 服务费（transaction/service fee）

### 过滤建议

- 所有 PC2/Revenue 计算必须加 `is_bi_excluded_rev_prm = 0` 排除测试订单
- 统计分析建议同时排除 `cancel_datetime IS NULL AND is_returned_item = 0`
- 多日汇总建议用 `regional_create_date` 而非 `grass_date` 确保口径一致

## All Columns

*DDL not found in codebase. Column names and types inferred from SQL usage in 46 read files. Run --source from-di to get full column list with descriptions.*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | Partition date | - | - |
| grass_region | string | Region/country | - | - |
| order_id | bigint | Order ID | - | - |
| item_id | bigint | Item ID | - | - |
| model_id | bigint | Model ID | - | - |
| group_id | bigint | Group ID | - | - |
| bundle_order_item_id | bigint | Bundle order item ID | - | - |
| shop_id | bigint | Shop ID | - | - |
| level1_global_be_category_id | bigint | Level 1 global backend category ID | - | - |
| level1_global_be_category | string | Level 1 global backend category name | - | - |
| regional_create_date | date | Regional create date (order place date in region timezone) | - | - |
| local_create_date | date | Local create date | - | - |
| create_datetime | string | Create datetime | - | - |
| cancel_datetime | string | Cancel datetime (NULL = not cancelled) | - | - |
| commission_base_amt_usd | double | Commission base amount in USD | - | - |
| commission_fee_usd | double | Total commission fee in USD | - | - |
| service_fee_usd | double | Service fee in USD | - | - |
| estimate_mandatory_commission_fee_usd_level1 | double | Estimated mandatory commission fee USD (Level 1) | - | - |
| estimate_local_c2c_mandatory_commission_fee_usd_level1 | double | MP (C2C) mandatory commission fee USD (Level 1) | - | - |
| estimate_local_mall_mandatory_commission_fee_usd_level1 | double | Mall mandatory commission fee USD (Level 1) | - | - |
| estimate_cb_mandatory_commission_fee_usd_level1 | double | Cross Border mandatory commission fee USD (Level 1) | - | - |
| estimate_optional_commission_fee_usd_level1 | double | Estimated optional commission fee USD (Level 1) | - | - |
| estimate_local_c2c_optional_commission_fee_usd_level1 | double | MP (C2C) optional commission fee USD (Level 1) | - | - |
| estimate_local_mall_optional_commission_fee_usd_level1 | double | Mall optional commission fee USD (Level 1) | - | - |
| estimate_cb_optional_commission_fee_usd_level1 | double | Cross Border optional commission fee USD (Level 1) | - | - |
| estimate_buyer_handling_fee_usd_level1 | double | Buyer handling fee USD (Level 1) | - | - |
| estimate_seller_handling_fee_usd_level1 | double | Seller handling fee USD (Level 1) | - | - |
| estimate_other_revenue_usd_level2 | double | Other revenue USD (Level 2) | - | - |
| is_bi_excluded_rev_prm | int | BI exclusion flag for revenue/prm | - | - |
| is_bi_excluded_order | int | BI exclusion flag for order | - | - |
| is_returned_item | int | Return flag for item | - | - |
| is_cb_shop | int | Cross Border shop flag | - | - |
| is_official_shop | int | Official shop flag | - | - |
