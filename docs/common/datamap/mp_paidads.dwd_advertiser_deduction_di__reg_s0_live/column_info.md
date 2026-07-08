<!-- ads-workspace-gdoc-sync: gdoc_id=1c81FrCCoR_tWmtdOodwpuPfMocHMIVucxai8USjAUPA gdoc_url=https://docs.google.com/document/d/1c81FrCCoR_tWmtdOodwpuPfMocHMIVucxai8USjAUPA/edit -->

# Columns: mp_paidads.dwd_advertiser_deduction_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为事件级明细表（每行一条扣费记录），各金额字段可直接 SUM 聚合，无跨维度重复问题。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| credit_topup_type | 1 | paid credit without expiry |
| credit_topup_type | 2 | paid credit with expiry |
| credit_topup_type | 3 | free credit without expiry |
| credit_topup_type | 4 | free credit with expiry |
| operation (event_code) | 1 | deduction (standard click) |
| operation (event_code) | 11 | CPS deduction |
| operation (event_code) | 15 | CPR deduction |
| credit_order_type | 3 | manual credit |
| credit_order_type | 6 | package/voucher |
| credit_order_type | 8 | program credit |
| credit_order_type | 9 | auto credit |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (almost all queries)
- `grass_region`: standard 8+2 regions ('ID','MY','PH','SG','TH','TW','VN','BR','MX','AR')
- `placement`: 0,4 (Search), 2,5 (Discovery manual), 3,2003,2030 (Shop Ads), 40 (ROI2), 50 (Simple2), 802,805,1002,1005,1202,1205 (Discovery simple), 44,4400-4405 (Boost)
- `pricing_type`: 15 (Simple2), others per product type
- `operation`: 1 (standard deduction), 11 (CPS), 15 (CPR); combined as `event_code in (1,11,15)`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| id | bigint | - | - | - |
| shop_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| ads_id | bigint | - | - | - |
| campaign_id | bigint | - | - | - |
| placement | int | - | - | - |
| ads_type | int | - | - | - |
| ads_status | int | - | - | - |
| keywords | string | - | - | - |
| item_id | bigint | - | - | - |
| deduction_amt | double | Deduction amount in local currency | - | - |
| deduction_amt_usd | double | Deduction amount in USD (= deduction_amt / exchange_rate) | - | - |
| event_timestamp | bigint | Unix timestamp of the deduction event | - | - |
| event_datetime | string | Formatted datetime of the event | - | - |
| acc_before_balance | bigint | Account balance before deduction | - | - |
| acc_after_balance | bigint | Account balance after deduction | - | - |
| topup_order_id | bigint | Credit topup order ID | - | - |
| credit_amt_before_deduct | double | Credit amount before deduction (/100000) | - | - |
| credit_amt_after_deduct | double | Credit amount after deduction (/100000) | - | - |
| credit_topup_type | int | 1=paid no expiry, 2=paid expiry, 3=free no expiry, 4=free expiry | - | - |
| credit_topup_type_name | string | - | - | - |
| program_name | string | Credit program name | - | - |
| program_start_timestamp | bigint | - | - | - |
| original_topup_credit_amt | double | - | - | - |
| topup_expiry_start_timestamp | bigint | - | - | - |
| topup_expiry_end_timestamp | bigint | - | - | - |
| topup_expired_today | boolean | - | - | - |
| sub_type | int | - | - | - |
| match_type | int | - | - | - |
| recall_type | int | - | - | - |
| expected_price_deduction | bigint | Expected deduction price (before budget/balance limit) | - | - |
| user_query | string | - | - | - |
| sort_type | int | - | - | - |
| pdp_item_id | bigint | - | - | - |
| pdp_shop_id | int | - | - | - |
| pctr | double | - | - | - |
| bid_price | bigint | - | - | - |
| second_ads_ecpm | bigint | - | - | - |
| second_ads_id | bigint | - | - | - |
| ab_sign | string | AB test signatures | - | - |
| credit_order_type | int | - | - | - |
| credit_order_type_name | string | - | - | - |
| topup_create_timestamp | bigint | - | - | - |
| entrance | int | - | - | - |
| pricing_type | int | - | - | - |
| sub_entrance | int | - | - | - |
| credit_topup_sub_type_name | string | - | - | - |
| request_id | string | - | - | - |
| operation | int | Event code: 1=click deduction, 11=CPS, 15=CPR | - | - |
| effective_type | int | - | - | - |
| ads_credit_id | bigint | - | - | - |
| deduct_unique_id | string | - | - | - |
| credit_reason | string | - | - | - |
| deduction_price | double | Deduction price in local currency (/100000) | - | - |
| voucher_deduction_price | double | Voucher deduction price in local currency (/100000) | - | - |
| seller_type_1p | string | - | - | - |
| seller_type | string | - | - | - |
| deduction_price_usd | double | Deduction price in USD | - | - |
| voucher_deduction_price_usd | double | Voucher deduction price in USD | - | - |
| traffic_source | int | Traffic source (4 = new boost) | - | - |
| deduct_timestamp | bigint | - | - | - |
| click_timestamp | bigint | - | - | - |
| is_package_topup | int | - | - | - |
| is_voucher_topup | int | - | - | - |
| credit_program_id | bigint | - | - | - |
| credit_operator | string | - | - | - |
| voucher_id | bigint | - | - | - |
| cps_total_expenditure_amt | double | CPS total expenditure (/100000) | - | - |
| cps_available_budget | double | CPS available budget (/100000) | - | - |
| valid_balance_amt | double | Valid balance amount (/100000) | - | - |
| available_balance_amt | double | Available balance amount (/100000) | - | - |
| consumption_type | int | - | - | - |
| tz_type | string | [PARTITION] Timezone type: 'local' | - | - |
| grass_region | string | [PARTITION] Region code | - | - |
| grass_date | date | [PARTITION] Business date | - | - |
