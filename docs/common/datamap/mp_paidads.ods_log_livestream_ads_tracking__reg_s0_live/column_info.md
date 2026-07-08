<!-- ads-workspace-gdoc-sync: gdoc_id=1D5Mw87VmMOc0Rg_Yj_DQJgOD5kyHwOqVCd1Zo5YmNOo gdoc_url=https://docs.google.com/document/d/1D5Mw87VmMOc0Rg_Yj_DQJgOD5kyHwOqVCd1Zo5YmNOo/edit -->

# Columns: mp_paidads.ods_log_livestream_ads_tracking__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a raw event log table with no pre-aggregated numeric metrics. No SUM(DISTINCT) patterns apply.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| entrance | 27 | LIVE STREAM DISCOVERY |
| entrance | 28 | LIVE STREAM FOR YOU |
| entrance | 37 | LS HOME CAROUSEL |
| entrance | 38 | LS PDP |
| entrance | 39 | LS AUTO LANDING |
| entrance | 42 | LS VIDEO FEED |
| entrance | 48 | LS GAME |
| platform | 2 | ios_app |
| platform | 4 | android_app |
| livestreams[].content_mix_frame_tab_name | 0 | UNKNOWN |
| livestreams[].content_mix_frame_tab_name | 1 | LiveTab |
| livestreams[].content_mix_frame_tab_name | 2 | ForYouTab |
| livestreams[].content_mix_frame_tab_name | 3 | VideoTab |
| livestreams[].content_mix_frame_tab_name | 4 | DiscoverTab |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN' (7 regions)
- `grass_date`: DATE literal (e.g., `DATE '2025-08-20'`, `date "${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}"`)
- `h`: 0-23 (hourly partition, often filtered as `h = 12` or `h >= 19`)
- `operation`: 1 (deduct impr, most common for bidding signal extraction)
- `entrance`: 27,28,37,38,39,42,48 (livestream-specific entrances)
- `livestreams[0].ads_id > 0`: common filter for valid livestream ads rows
- `get_json_object(livestreams[0].json_data, '$.pricing_type')`: '19' (MAX_GMV2), '22' (other), '10'
- `placement`: 3327,3328,3337,3338,3339,3342,3348 (livestream placements)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| userid | bigint | User ID (buyer) | - | - |
| sessionid | string | Session ID | - | - |
| deviceid | string | Device ID | - | - |
| client_ip | string | Client IP address | - | - |
| platform | bigint | Platform (2=ios_app, 4=android_app) | - | - |
| operation | bigint | Event operation type (1=Impression/DeductImpr) | - | - |
| items | array<struct<...>> | Item-level tracking data (product_card, internal deduction_info, query, etc.) | - | - |
| timestamp | bigint | Event timestamp (unix epoch) | - | - |
| country | string | Country code | - | - |
| token | string | Auth token | - | - |
| `from` | string | Source origin | - | - |
| shops | array<struct<...>> | Shop-level tracking data (vouchers, query, internal deduction_info, etc.) | - | - |
| placement | bigint | Top-level placement ID | - | - |
| json_data | string | Top-level JSON metadata | - | - |
| fe_ab_sign | string | Frontend AB test signature | - | - |
| internal_label | struct<frauds,sessionid,adsinfo_extract_label,dfp_device_id,risk_tags> | Internal label struct (fraud detection, DFP, risk tags) | - | - |
| banner | struct<bannerid,source,campaign_unitid,slotid,json_data,image_hash,target_url,dl_json_data> | Banner tracking data | - | - |
| app_ver | string | App version string | - | - |
| rn_ver | string | React Native version string | - | - |
| entrance | bigint | Entrance/page source (27-48 for livestream) | - | - |
| view_session_id | string | View session ID | - | - |
| sub_entrance | bigint | Sub-entrance ID | - | - |
| dfp | string | DFP device fingerprint | - | - |
| source | string | Data source identifier | - | - |
| livestreams | array<struct<ls_session_id,user_id,shop_id,ads_id,location,json_data,duration,list_type,click_area,items,internal,if_mini_ls,content_mix_frame_tab_name>> | **Livestream ads tracking data (the primary data column for this table)**. Each element represents one livestream ad entry. | - | - |

### livestreams 嵌套字段 (Most Commonly Accessed Nested Fields)

| Nested Field | Type | Description |
|-------------|------|-------------|
| livestreams[].ls_session_id | bigint | Livestream room/session ID |
| livestreams[].user_id | bigint | Streamer user ID |
| livestreams[].shop_id | bigint | Streamer shop ID |
| livestreams[].ads_id | bigint | Ad ID |
| livestreams[].location | int | Location within page |
| livestreams[].json_data | string | JSON string containing bidding signals (pricing_type, pctr, pcr, target_cir, ecpm, aov, price_coef, deduction_price, request_id, streamer_type, placement, etc.) |
| livestreams[].duration | int | Viewing duration of the livestream |
| livestreams[].list_type | string | List type |
| livestreams[].click_area | int | Click area |
| livestreams[].items | array<struct<item_id,shop_id,target_type>> | Items in the livestream |
| livestreams[].internal.cpm_deduction_info.placement | int | CPM deduction placement ID |
| livestreams[].internal.cpm_deduction_info.cpm | bigint | CPM value |
| livestreams[].internal.cpm_deduction_info.ads_id | bigint | CPM deduction ad ID |
| livestreams[].internal.frauds | array<struct<fraud_type>> | Fraud detection info |
| livestreams[].internal.event_id | string | Event ID |
| livestreams[].internal.request_id | string | Request ID |
| livestreams[].internal.ads_request_id | string | Ads request ID |
| livestreams[].if_mini_ls | boolean | Whether it is a mini livestream |
| livestreams[].content_mix_frame_tab_name | int | Content mix frame tab (0=UNKNOWN, 1=LiveTab, 2=ForYouTab, 3=VideoTab, 4=DiscoverTab) |

### livestreams[].json_data 常用 JSON 字段 (Extracted via get_json_object)

| JSON Path | Type | Description |
|-----------|------|-------------|
| $.pricing_type | int/string | Pricing type (e.g. 10, 19=MAX_GMV2, 22) |
| $.pctr | double | Predicted CTR |
| $.pcr | double | Predicted CVR |
| $.target_cir | double | Target CIR (Conversion to Impression Rate) |
| $.ecpm | double | eCPM value |
| $.aov | double | Predicted AOV (in micros, usually divided by 100000) |
| $.price_coef | double | Bidding price coefficient |
| $.deduction_price | double | Final deduction/bidding price |
| $.request_id | string | Request ID for joining with performance data |
| $.streamer_type | int | Streamer type (2,3=KOL, else=seller) |
| $.placement | int | Placement ID within JSON data |
