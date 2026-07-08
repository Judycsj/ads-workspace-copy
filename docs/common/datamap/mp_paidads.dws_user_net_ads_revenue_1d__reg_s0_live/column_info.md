<!-- ads-workspace-gdoc-sync: gdoc_id=105pOlwlyJhoiMUZneORKaNcTrA0_R9SJapsn-ToBvaA gdoc_url=https://docs.google.com/document/d/105pOlwlyJhoiMUZneORKaNcTrA0_R9SJapsn-ToBvaA/edit -->

# Columns: mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段在跨维度聚合时不可直接 SUM，因为它们是通过全用户均摊（amount / COUNT(*)）得出的：

- `paid_credit_expired_amt_usd_1d` — 全维度只有一个过期金额总值，通过 CROSS JOIN 均摊到所有 user_id，跨 user_id 聚合时需用 SUM(DISTINCT) 或 MAX
- `others_free_credit_expired_amt_usd_1d` — 同上，免费 credit 过期金额均摊值

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| credit_topup_type | 1 | Paid (non-taxable) |
| credit_topup_type | 2 | Paid (taxable) |
| credit_topup_type | 3, 4 | Free credit |
| gov_order_type | gov | Government/NNWH fund programs |
| gov_order_type | lovito | Lovito monthly ads self top up |
| gov_order_type | SIP | SIP ads drive / SIP compensation |
| gov_order_type | SCS | SCS monthly ads self/platform top up |
| gov_order_type | others | Other free credit programs |
| is_taxable_ads | 1 | Taxable (NNWH, cncb, gov fund programs) |
| is_taxable_ads | 0 | Non-taxable |
| tz_type | regional | 标准时区聚合 (约 70% 查询使用) |
| tz_type | local | 本地时区 (ROI3/Live Ads 场景) |
| placement | 9 | Display Ads |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'regional' (聚合场景，dws_user_pc2_1d / dws_common_feature_user_item_pc2_1d 均使用) / 'local' (对账/调试场景)
- `grass_region`: 标准 9 区 ('ID','MY','PH','SG','TH','TW','VN','MX','BR')
- `grass_date`: 多天范围过滤 `between date('${grass_date_30day}') and date('${grass_date}')`
- `entrance`: 用于 JOIN dim_common_feature_mapping 映射到 common_feature_group

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| ads_id | bigint | - | - | - |
| item_id | bigint | - | - | - |
| campaign_id | bigint | - | - | - |
| entrance | int | - | - | - |
| placement | int | - | - | - |
| pricing_type | int | - | - | - |
| sub_entrance | bigint | - | - | - |
| credit_order_type | bigint | - | - | - |
| credit_order_type_name | string | - | - | - |
| credit_reason | string | - | - | - |
| credit_topup_sub_type | bigint | - | - | - |
| credit_topup_sub_type_name | string | - | - | - |
| credit_program_id | bigint | - | - | - |
| credit_program_name | string | - | - | - |
| credit_topup_type | int | - | - | - |
| credit_topup_type_name | string | - | - | - |
| entry_point | string | - | - | - |
| entry_point_v2 | string | - | - | - |
| traffic_type | string | - | - | - |
| sub_product_type | string | - | - | - |
| product_type | string | - | - | - |
| main_product_type | string | - | - | - |
| raw_gross_ads_revenue_usd_1d | double | - | - | - |
| gross_ads_revenue_usd_1d | double | - | - | - |
| net_ads_revenue_usd_1d | double | - | - | - |
| paid_credit_revenue_usd_1d | double | - | - | - |
| raw_paid_credit_revenue_usd_1d | double | - | - | - |
| others_free_credit_revenue_usd_1d | double | - | - | - |
| raw_others_free_credit_revenue_usd_1d | double | - | - | - |
| tax_paid_on_free_credit_revenue_usd_1d | double | - | - | - |
| free_credit_deduction_amt_usd_1d | double | - | - | - |
| free_ads_revenue_amt_usd_1d | double | - | - | - |
| sip_free_credit_revenue_usd_1d | double | - | - | - |
| scs_free_credit_revenue_usd_1d | double | - | - | - |
| lovito_free_credit_revenue_usd_1d | double | - | - | - |
| gov_free_credit_revenue_usd_1d | double | - | - | - |
| paid_credit_expired_amt_usd_1d | double | - | - | - |
| others_free_credit_expired_amt_usd_1d | double | - | - | - |
| raw_display_ads_revenue_usd_1d | double | - | - | - |
| display_ads_revenue_usd_1d | double | - | - | - |
| tz_type [PARTITION] | string | - | - | - |
| grass_region [PARTITION] | string | - | - | - |
| grass_date [PARTITION] | date | - | - | - |
