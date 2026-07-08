<!-- ads-workspace-gdoc-sync: gdoc_id=1IMLod_E4Nz_WQcJ6uXMSmqh47q8GZc3WEOBYr-t0nF8 gdoc_url=https://docs.google.com/document/d/1IMLod_E4Nz_WQcJ6uXMSmqh47q8GZc3WEOBYr-t0nF8/edit -->

# Columns: mp_paidads.dim_campaign__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为维度表（DIM），字段均为属性字段或快照值，不存在典型的累加指标。但以下字段跨日期查询时需注意：
- `daily_quota_local`, `daily_quota_usd` — 每日快照值，不可跨日期 SUM
- `total_quota_local`, `total_quota_usd` — 每日快照值，不可跨日期 SUM
- `roi_two` — Target ROAS 快照值，跨日期通常取 AVG 或 Latest

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| campaign_status | 0 | ADS_DELETED |
| campaign_status | 1 | ADS_NORMAL |
| campaign_status | 2 | ADS_PAUSED |
| campaign_status | 3 | ADS_CLOSED |
| campaign_status | 4 | ADS_TEMP_RESERVED |
| campaign_status | 5 | ADS_CANCELLED |
| campaign_status | 6 | ADS_BANNED |
| campaign_status | 7 | ADS_DELETED_HIDE |
| is_upgraded | 0 | false (ROI Two not upgraded) |
| is_upgraded | 1 | true (ROI Two upgraded) |
| is_cps | 0 | false (not CPS) |
| is_cps | 1 | true (CPS enabled) |
| is_rapid_boost_on | 0 | false (rapid boost off) |
| is_rapid_boost_on | 1 | true (rapid boost on) |
| is_npa | 0 | false (not NPA) |
| is_npa | 1 | true (NPA campaign) |
| is_auto_ads_solution_on | 0 | false |
| is_auto_ads_solution_on | 1 | true (auto ads solution on) |
| campaign_tag | 1 | GMS auto rebate eligible |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~90%+ 查询使用 local)
- `grass_region`: upper('${region}') — 标准 8+4 区 ('ID','MY','PH','SG','TH','TW','VN','BR','MX','AR')
- `campaign_status`: 1 (ADS_NORMAL, 筛选活跃 campaign)
- `roi_two`: > 0.0 (筛选有 Target ROI 的 campaign)
- `campaign_tag`: 1 (筛选 GMS auto rebate eligible)
- `campaign_type`: 8 (Product campaign, 用于 dim_omni_campaign_attr)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| campaign_id | bigint | Campaign ID | - | - |
| shop_id | bigint | Shop ID of campaign owner | - | - |
| user_id | bigint | User ID of campaign owner | - | - |
| campaign_status | int | Campaign status code (0-7) | - | - |
| campaign_status_text | string | Campaign status text (ADS_NORMAL, etc.) | - | - |
| campaign_start_datetime | string | Campaign start datetime in local timezone | - | - |
| campaign_end_datetime | string | Campaign end datetime in local timezone (NULL if no end) | - | - |
| campaign_create_datetime | string | Campaign creation datetime | - | - |
| campaign_modify_datetime | string | Campaign last modify datetime | - | - |
| total_quota_local | double | Total budget in local currency (raw / 100000.0) | - | - |
| daily_quota_local | double | Daily budget in local currency (raw / 100000.0) | - | - |
| total_quota_usd | double | Total budget in USD (local / exchange_rate) | - | - |
| daily_quota_usd | double | Daily budget in USD (local / exchange_rate) | - | - |
| quota_splits | array<struct<placement:int,daily_available_quota:string,version:int,placements:array<int>>> | Budget split by placement | - | - |
| campaign_start_timestamp | bigint | Campaign start Unix timestamp | - | - |
| campaign_end_timestamp | bigint | Campaign end Unix timestamp | - | - |
| campaign_create_timestamp | bigint | Campaign creation Unix timestamp | - | - |
| campaign_modify_timestamp | bigint | Campaign last modify Unix timestamp | - | - |
| roi_two | double | Target ROAS value (raw / 100000.0) | - | - |
| campaign_type | int | Campaign type (e.g. 8=Product) | - | - |
| auto_budget_increase_counter | int | Auto budget increase counter | - | - |
| last_increment_timestamp | bigint | Last auto budget increment timestamp | - | - |
| user_last_daily_quota | double | User last daily quota before auto-increase (raw / 100000.0) | - | - |
| last_daily_reset_timestamp | bigint | Last daily quota reset timestamp | - | - |
| creation_entry_point | int | Campaign creation entry point | - | - |
| simple_roi_two_estimate | struct<est_roi_lower_bound:double,est_roi_upper_bound:double,est_order_lower_bound:bigint,est_order_upper_bound:bigint> | Simple ROI Two estimate bounds | - | - |
| is_upgraded | int | Whether ROI Two is upgraded (0/1/NULL) | - | - |
| is_cps | int | Whether CPS is enabled (0/1/NULL) | - | - |
| last_cps_timestamp | bigint | Last CPS timestamp | - | - |
| final_value_list | array<double> | ROI target recommendation final values | - | - |
| suggest_roi_entry_point | int | Suggest ROI entry point | - | - |
| is_rapid_boost_on | int | Whether rapid boost is on (0/1/NULL) | - | - |
| product_gms_estimate | struct<has_est:boolean,roi_lower_bound:double,roi_upper_bound:double,bid_roi:double> | Product GMS estimate | - | - |
| creation_platform | int | Campaign creation platform | - | - |
| is_npa | int | Whether NPA campaign (0/1/NULL) | - | - |
| npa_current_phase | int | NPA current phase | - | - |
| gmv_type | int | GMV type | - | - |
| campaign_tag | bigint | Campaign tag (1=GMS rebate eligible) | - | - |
| suggest_roi_api_source | int | Suggest ROI API source | - | - |
| is_auto_ads_solution_on | int | Whether auto ads solution is on (0/1/NULL) | - | - |
| roi_two_display_target_value | double | ROI Two display target value (raw / 100000.0) | - | - |
| tz_type | string | Timezone type [PARTITION] | - | - |
| grass_region | string | Region code [PARTITION] | - | - |
| grass_date | date | Date [PARTITION] | - | - |
