<!-- ads-workspace-gdoc-sync: gdoc_id=15oJB3pF2Dv_bXU3s8RQ_KHULLoi3DH4T7UknsddZn0k gdoc_url=https://docs.google.com/document/d/15oJB3pF2Dv_bXU3s8RQ_KHULLoi3DH4T7UknsddZn0k/edit -->

# Columns: mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live

## Column Usage Notes

### Non-Additive Fields

No SUM(DISTINCT) patterns detected in read references. All metric columns are additive at the order_id grain.

### Value Mappings (Enum)

| Column | Value | Meaning |
|--------|-------|---------|
| order_type | 1 | deduction |
| order_type | 2 | topup_from_order |
| order_type | 3 | topup_manual |
| order_type | 4 | topup_wallet (auto topup) |
| order_type | 5 | deduct_order |
| order_type | 6 | topup_svs (normal SVS topup) |
| order_type | 7 | free credit without expiry |
| order_type | 8 | topup_from_seller_mission |
| order_type | 9 | topup_from_srm |
| order_type | 10 | topup_negative |
| order_type | 14 | manual credit (new type) |
| order_type | 16 | (ads credit topup, amount from credit table) |
| order_type | 28 | paid credit without expiry |
| credit_topup_type | 1 | paid credit without expiry |
| credit_topup_type | 2 | paid credit with expiry |
| credit_topup_type | 3 | free credit without expiry |
| credit_topup_type | 4 | free credit with expiry |
| credit_topup_main_type | 2 | paid credit |
| credit_topup_main_type | 3 | free credit |
| credit_topup_main_type | 5 | mixed (package topup) |

### Common Filter Values

- `tz_type`: `'local'` (most common, ~80% queries) / `'regional'` (used in some net revenue workflows)
- `grass_region`: Standard regions `'ID','TH','VN','PH','SG','TW','MY','BR'`; extended with `'MX','AR','CO','CL'` in US workflows
- `order_type`: `6` (normal SVS topup, used in funnel analysis), `3` (manual topup), `2,4` (paid wallet topups), `10` (negative adjustments, topup_amt is negated)
- `credit_topup_type`: `IN (1,2,3,4)` (all four credit types in incentive analysis)
- `is_topup_today`: `= 1` (filter for same-day topups)
- `is_credit_topup_expired`: `= 1` (expired credits)
- `credit_topup_expiry_end_timestamp`: `> 0` (has expiry) / `= 0` (no expiry)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | shop_id | - | - |
| user_id | bigint | user_id | - | - |
| order_id | bigint | topup order id | - | - |
| svs_topup_status | bigint | status only for svs topups | - | - |
| topup_create_timestamp | bigint | create timestamp for topup events | - | - |
| topup_create_datetime | string | create datetime for topup events | - | - |
| topup_amt | double | topup amount in local currency (negative for order_type=10) | - | - |
| topup_amt_usd | double | topup amount in USD | - | - |
| order_type | bigint | order type (includes all types of topups) | - | - |
| order_type_name | string | order type name (see enum mapping above) | - | - |
| is_topup_today | tinyint | if topup takes place on grass_date | - | - |
| credit_topup_type | bigint | type of free and paid topup (1-4) | - | - |
| credit_topup_type_name | string | type of free and paid topup | - | - |
| pckg_id | bigint | package id > 0 means package topup (order_type = 6) | - | - |
| pckg_original_amt | double | original price of package (how much sellers topup in their accounts) in local currency | - | - |
| pckg_original_amt_usd | double | original price of package in USD | - | - |
| pckg_expiry_timestamp | bigint | package expiry timestamp | - | - |
| pckg_expiry_datetime | string | package expiry datetime | - | - |
| pckg_paid_amt | double | discounted price of package (how much sellers actually pay) in local currency | - | - |
| pckg_paid_amt_usd | double | discounted price of package in USD | - | - |
| voucher_id | bigint | voucher id > 0 means voucher topup (order_type = 6) | - | - |
| voucher_discount_amt | double | Free ad credits included in voucher topup (in local currency) | - | - |
| voucher_discount_amt_usd | double | Free ad credits included in voucher topup (in USD) | - | - |
| voucher_expiry_timestamp | bigint | expiry timestamp for voucher topups | - | - |
| voucher_expiry_datetime | string | expiry datetime for voucher topups | - | - |
| is_package_topup | tinyint | is_package_topup (pckg_id > 0) | - | - |
| is_voucher_topup | tinyint | is_voucher_topup (voucher_id > 0) | - | - |
| manual_credit_create_timestamp | bigint | manual_credit_create_timestamp | - | - |
| manual_credit_create_datetime | string | manual_credit_create_datetime | - | - |
| manual_credit_approved_timestamp | bigint | datetime when manual credit is approved | - | - |
| manual_credit_approved_datetime | string | timestamp when manual credit is approved | - | - |
| credit_reason | string | reason for manual credit approval | - | - |
| credit_operator | string | operator who handles credit approval | - | - |
| credit_program_name | string | credit_topup_program_name | - | - |
| credit_program_start_timestamp | bigint | start time of the credit program | - | - |
| credit_program_start_datetime | string | start time of the credit program | - | - |
| credit_topup_status | bigint | topup status for order_type in (3,8,9,10) | - | - |
| credit_topup_main_type | bigint | whether it is paid or free topup (2=paid, 3=free) | - | - |
| credit_topup_main_type_name | string | whether it is paid or free topup | - | - |
| credit_topup_sub_type | bigint | topup sub category ID | - | - |
| credit_topup_sub_type_name | string | topup sub category name | - | - |
| credit_balance_amt | double | the balance amount from the topup amount | - | - |
| credit_balance_amt_usd | double | the balance amount from the topup amount in usd | - | - |
| credit_topup_expiry_start_timestamp | bigint | datetime from which the credit becomes effective | - | - |
| credit_topup_expiry_start_datetime | string | datetime from which the credit becomes effective | - | - |
| credit_topup_expiry_end_timestamp | bigint | timestamp whereby the credit will expire | - | - |
| credit_topup_expiry_end_datetime | string | datetime whereby the credit will expire | - | - |
| credit_modify_timestamp | bigint | last modified timestamp from ods_paidads_ads_credit_tab | - | - |
| credit_modify_datetime | string | last modified datetime from ods_paidads_ads_credit_tab | - | - |
| is_credit_topup_expired_today | tinyint | if credit expired on grass_date, tag = 1 | - | - |
| is_credit_topup_expired | tinyint | if credit has expired by grass_date, tag = 1 | - | - |
| tz_type | string | [PARTITION] timezone type: 'local' or 'regional' | - | - |
| grass_region | string | [PARTITION] country partition | - | - |
| grass_date | date | [PARTITION] grass date partition | - | - |

### Extended Columns (data_paidadsmart workflow only)

The newer `data_paidadsmart` production workflow adds the following columns (not in original DDL):

| Column Name | Type | Description |
|-------------|------|-------------|
| topup_amt_usd_his | double | topup amount in USD using historical exchange rate |
| pckg_original_amt_usd_his | double | package original amount in USD (historical rate) |
| pckg_paid_amt_usd_his | double | package paid amount in USD (historical rate) |
| voucher_discount_amt_usd_his | double | voucher discount in USD (historical rate) |
| credit_balance_amt_usd_his | double | credit balance in USD (historical rate) |
| notified | bigint | notification status |
| credit_program_id | bigint | credit program ID |
| svs_entity_type | int | SVS entity type |
| svs_entity_id | bigint | SVS entity ID |
| ads_credit_extinfo | string | ads credit extension info (JSON) |
| effective_type | int | effective type (1=ROI2, 2=livestream, 3=search_brand) |
| manual_credit_effective_type | int | manual credit effective type |
| ads_credit_id | bigint | ads credit ID |
| ads_revenue_push_type | string | ads revenue push type |
| seller_investment_type | string | seller investment type |
| seller_investment_amount | double | seller investment amount |
| operator | string | operator for manual topup action |
| action_type | int | action type for manual topup action |
| ads_package_id | bigint | ads package ID |
| consumption_type | int | consumption type |
