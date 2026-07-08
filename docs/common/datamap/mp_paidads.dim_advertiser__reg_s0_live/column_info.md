<!-- ads-workspace-gdoc-sync: gdoc_id=1tkvp4uNFwcXwNjQHCDwylzmOsyRNvs1hD0JbPeYks-0 gdoc_url=https://docs.google.com/document/d/1tkvp4uNFwcXwNjQHCDwylzmOsyRNvs1hD0JbPeYks-0/edit -->

# Columns: mp_paidads.dim_advertiser__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a dimension table -- all fields are non-aggregatable attributes. No SUM/AVG patterns observed.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| seller_type_1p | 'Lovito' | ggp_seller_name = 'Lovito - GGP' |
| seller_type_1p | 'SCS' | ggp_seller_name = 'Flock project - GGP' |
| seller_type_1p | 'Local SCS' | local_scs = 1 (from dim_local_scs_shop_list) |
| seller_type_1p | 'Others' | cb_seller_type = 'CNCB' |
| seller_type_1p | 'Unknown' | Default / no match |
| tz_type | 'local' | Local timezone (most common) |
| tz_type | 'regional' | Regional timezone |
| is_auto_topup_enabled | 1 | Auto top-up ON (decoded from extinfo) |
| is_auto_topup_enabled | 0 | Auto top-up OFF |
| is_auto_budget_increase_enabled | 1 | Auto budget increase ON |
| is_auto_budget_increase_enabled | 0 | Auto budget increase OFF |
| is_auto_escrow_enabled | 1 | Auto escrow ON |
| is_auto_escrow_enabled | 0 | Auto escrow OFF |
| is_roi_three_voucher_enabled | 1 | ROI3 voucher ON |
| is_roi_three_voucher_enabled | 0 | ROI3 voucher OFF |
| is_auto_ads_solution_enabled | 1 | Auto ads solution ON |
| is_auto_ads_solution_enabled | 0 | Auto ads solution OFF |
| adopt_audience_targeting | True | Has active target audience groups (count > 0) |
| adopt_audience_targeting | False | No active target audience groups |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (dominant usage ~90% of queries)
- `grass_region`: standard regions 'ID','MY','PH','SG','TH','TW','VN','BR'; also 'MX','AR' for LATAM
- `grass_date`: typically `DATE('${BIZ_YESTERDAY}')` or `DATE('${grass_date}')`
- `is_auto_topup_enabled`: 1 (filter for ATU-on advertisers)
- `is_auto_escrow_enabled`: 1 (filter for escrow-on advertisers)
- `seller_type_1p`: exclude 'Local SCS','SCS','Lovito' for OKR

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| beetalk_userid | bigint | - | - | - |
| user_name | string | - | - | - |
| language | string | - | - | - |
| status | int | User status | - | - |
| account_status | int | Ads account status | - | - |
| shop_status | int | Shop status | - | - |
| is_seller | tinyint | - | - | - |
| is_managed_seller | tinyint | - | - | - |
| is_official_shop | tinyint | - | - | - |
| is_preferred_shop | tinyint | - | - | - |
| is_cb_seller | tinyint | Cross-border seller flag | - | - |
| create_datetime | string | User registration datetime | - | - |
| modify_datetime | string | User modify datetime | - | - |
| account_create_datetime | string | Ads account creation datetime | - | - |
| account_modify_datetime | string | Ads account modify datetime | - | - |
| shop_create_datetime | string | Shop creation datetime | - | - |
| first_item_create_datetime | string | First item listing datetime (MIN from dim_item) | - | - |
| shop_modify_datetime | string | Shop modify datetime | - | - |
| is_auto_topup_enabled | tinyint | Auto top-up feature flag | - | - |
| is_campaign_auto_bid_enabled | tinyint | Campaign auto bid feature flag | - | - |
| shop_level1_global_be_category | string | L1 global BE category | - | - |
| shop_level1_fe_display_category | string | L1 FE display category | - | - |
| shop_level1_kpi_category | string | L1 KPI category | - | - |
| shop_level2_global_be_category | string | L2 global BE category | - | - |
| shop_level2_fe_display_category | string | L2 FE display category | - | - |
| shop_level2_kpi_category | string | L2 KPI category | - | - |
| account_create_timestamp | bigint | Ads account creation unix timestamp | - | - |
| account_modify_timestamp | bigint | Ads account modify unix timestamp | - | - |
| balance | bigint | Account balance (raw, /100000 for actual) | - | - |
| adopt_audience_targeting | boolean | Has active target audience groups | - | - |
| version_tag | int | Setup flow version | - | - |
| is_self_mcn | tinyint | Self MCN flag | - | - |
| seller_type | string | CB seller type (from dim_shop_ext) | - | - |
| seller_type_1p | string | 1P seller classification: Lovito/SCS/Local SCS/Others/Unknown | - | - |
| is_auto_budget_increase_enabled | tinyint | Auto budget increase feature flag | - | - |
| auto_topup_threshold_amt | double | Auto top-up threshold (local currency) | - | - |
| auto_topup_threshold_amt_usd | double | Auto top-up threshold (USD) | - | - |
| auto_topup_amt | double | Auto top-up amount (local currency) | - | - |
| auto_topup_amt_usd | double | Auto top-up amount (USD) | - | - |
| auto_topup_daily_cap_amt | double | Auto top-up daily cap (local currency) | - | - |
| auto_topup_daily_cap_amt_usd | double | Auto top-up daily cap (USD) | - | - |
| auto_budget_increase_daily_cap | int | Auto budget increase daily cap | - | - |
| auto_budget_increase_percentage | double | Auto budget increase percentage | - | - |
| auto_budget_increase_effective_types | array\<int\> | Auto budget increase effective campaign types | - | - |
| is_roi_three_voucher_enabled | tinyint | ROI3 voucher feature flag | - | - |
| is_cb_sip_affiliated | tinyint | SIP shop tag - parent is CB shop | - | - |
| is_local_sip_affiliated | tinyint | SIP shop tag - parent is local shop | - | - |
| is_auto_escrow_enabled | tinyint | Auto escrow feature flag | - | - |
| is_auto_ads_solution_enabled | tinyint | Auto ads solution feature flag | - | - |
| auto_escrow_additional_fee_rate | double | Auto escrow additional fee rate | - | - |
| auto_escrow_fixed_program_fee_rate | double | Auto escrow fixed program fee rate | - | - |
| tz_type | string | [PARTITION] Timezone type: local/regional | - | - |
| grass_region | string | [PARTITION] Region code: ID/MY/PH/SG/TH/TW/VN/BR/MX/AR | - | - |
| grass_date | date | [PARTITION] Business date | - | - |
