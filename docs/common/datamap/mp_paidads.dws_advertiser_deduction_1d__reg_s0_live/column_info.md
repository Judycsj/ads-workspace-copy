<!-- ads-workspace-gdoc-sync: gdoc_id=1oNyZ7i4QnMNgAC6ya6G5YbAVW3c-0FkvYqt-vUcjTrk gdoc_url=https://docs.google.com/document/d/1oNyZ7i4QnMNgAC6ya6G5YbAVW3c-0FkvYqt-vUcjTrk/edit -->

# Columns: mp_paidads.dws_advertiser_deduction_1d__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | local | Local timezone partition |
| tz_type | regional | Regional timezone partition |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') (parameterized per region MX/CO/CL/BR/AR)
- `tz_type`: 'local' (used in dim_advertiser_tier_tag and dws_advertiser_ads_rev_1d for computing revenue)
- `grass_date`: DATE('${grass_date}') (daily partition filter)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | Shop ID | - | - |
| paid_expenditure_wo_expiry_amt_local_1d | DOUBLE | Paid expenditure without expiry (local currency, 1 day) | - | - |
| paid_expenditure_wo_expiry_amt_usd_1d | DOUBLE | Paid expenditure without expiry (USD, 1 day) | - | - |
| paid_expenditure_w_expiry_amt_local_1d | DOUBLE | Paid expenditure with expiry (local currency, 1 day) | - | - |
| paid_expenditure_w_expiry_amt_usd_1d | DOUBLE | Paid expenditure with expiry (USD, 1 day) | - | - |
| free_expenditure_wo_expiry_amt_local_1d | DOUBLE | Free credit expenditure without expiry (local currency, 1 day) | - | - |
| free_expenditure_wo_expiry_amt_usd_1d | DOUBLE | Free credit expenditure without expiry (USD, 1 day) | - | - |
| free_expenditure_w_expiry_amt_local_1d | DOUBLE | Free credit expenditure with expiry (local currency, 1 day) | - | - |
| free_expenditure_w_expiry_amt_usd_1d | DOUBLE | Free credit expenditure with expiry (USD, 1 day) | - | - |
| tz_type [PARTITION] | STRING | Timezone type (local / regional) | - | - |
| grass_region [PARTITION] | STRING | Region code | - | - |
| grass_date [PARTITION] | DATE | Data partition date | - | - |
