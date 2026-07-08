<!-- ads-workspace-gdoc-sync: gdoc_id=1jsmRH5vnKvusD5GH4VXmdq4Bp5LmdMnyidnGF8hB-rY gdoc_url=https://docs.google.com/document/d/1jsmRH5vnKvusD5GH4VXmdq4Bp5LmdMnyidnGF8hB-rY/edit -->

# Columns: mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a raw event log table with no pre-aggregated numeric metrics. No SUM(DISTINCT) patterns apply.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | IMPRESSION |
| operation | 2 | CLICK |
| operation | 3 | VIEW |
| operation | 4 | ADD_TO_CART |
| operation | 5 | PLACE_ORDER |
| operation | 6 | CLOSE_BANNER |
| operation | 7 | REPORT_DISLIKE |
| operation | 8 | REPORT_INAPPROPRIATE |
| operation | 9 | REPORT_IRRELEVANT |
| operation | 10 | REPORT_IMPRESSION |
| operation | 17 | SHOP_ITEM_IMPRESSION |
| operation | 18 | MORE_SHOP_CLICK |
| operation | 1001 | SHOP_IMPRESSION |
| operation | 1002 | SHOP_CLICK |
| operation | 1003 | SHOP_BANNER_IMPRESSION |
| platform | 1 | IOS_WEB |
| platform | 2 | IOS_APP |
| platform | 3 | ANDROID_WEB |
| platform | 4 | ANDROID_APP |
| platform | 5 | PC_MALL |
| platform | 6 | IOS_LITE |
| platform | 7 | ANDROID_LITE |
| platform | 8 | PLATFORM_RESERVED |
| platform | 9 | ANDROID_APP_LITE |
| platform | 99 | XIAPI |
| platform | 128 | OTHERS |
| placement | 0 | Search (with 29 also treated as Search in some DWD) |
| placement | 2,5 | Search-related (organic_request_id extracted from abtest_sign) |
| placement | 13,14,15,16 | Discovery-related (organic_request_id extracted from abtest_sign) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN','BR','MX','CO','CL' (11 regions)
- `grass_date`: DATE literal (e.g., `DATE '2026-01-12'`)
- `h`: 0-23 (hourly partition)
- `operation`: 1 (impression), 2 (click), 3 (view), 4 (add-to-cart), 5 (place-order), 1001 (shop impression), 1002 (shop click)
- `items[].itemid > 0`: common filter for item-level DWD
- `items[].shopid > 0`: common filter for valid items
- `shops[].shopid > 0`: common filter for shop-level DWD
- `size(shops) > 0`: common filter for shop tracking
- `size(items) > 0`: common filter for item tracking
- `size(videos) > 0`: common filter for video tracking

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| userid | bigint | - | - | - |
| sessionid | string | - | - | - |
| deviceid | string | - | - | - |
| client_ip | string | - | - | - |
| platform | bigint | - | - | - |
| operation | bigint | - | - | - |
| items | array\<struct\<...\>\> | Nested array of item-level tracking data. Key sub-fields: itemid, shopid, adsid, campaignid, ads_keyword, match_type, location, location_in_ads, query, product_card, internal (deduction_info), item_voucher, rsku_list_infos, etc. | - | - |
| timestamp | bigint | - | - | - |
| country | string | - | - | - |
| token | string | - | - | - |
| from | string | - | - | - |
| shops | array\<struct\<...\>\> | Nested array of shop-level tracking data. Key sub-fields: shopid, query, internal (deduction_info), items, vouchers, ls_session_id, shop_banners, etc. | - | - |
| placement | bigint | - | - | - |
| json_data | string | - | - | - |
| fe_ab_sign | string | - | - | - |
| internal_label | struct\<frauds, sessionid, adsinfo_extract_label, dfp_device_id, risk_tags\> | - | - | - |
| banner | struct\<banner_internal, bannerid, source, campaign_unitid, slotid, json_data, image_hash, target_url, dl_json_data, location, card_location, banner_cnt, landing_url_type, landing_page_url, unique_id, json_data_tms, target_type\> | - | - | - |
| app_ver | string | - | - | - |
| rn_ver | string | - | - | - |
| entrance | bigint | - | - | - |
| view_session_id | string | - | - | - |
| sub_entrance | bigint | - | - | - |
| dfp | string | - | - | - |
| vv_id | string | - | - | - |
| sdk_version | string | - | - | - |
| sdk_type | string | - | - | - |
| page_type | string | - | - | - |
| page_section | string | - | - | - |
| target_type | string | - | - | - |
| search_props | struct\<sort_by, scenario, search_entrance, search_mid, search_session_id, global_session_id, prefill_keyword\> | - | - | - |
| video_props | struct\<current_page, content_type, content_id, trigger_mode, sv_source_page, content_mix_frame_tab_name\> | - | - | - |
| videos | array\<struct\<video_id, user_id, creator_id, shop_id, ads_id, location, location_in_ads, json_data, duration, display_ad_tag, request_id, traffic_source, video_ads_type, target_type, items, internal, unique_id\>\> | - | - | - |
| version | string | - | - | - |
| event_timestamp | bigint | - | - | - |
| log_timestamp | bigint | - | - | - |
| platform_implementation | string | - | - | - |
| sequence_id | bigint | - | - | - |
| tms_session_id | string | - | - | - |
| last_view_event_id | string | - | - | - |
| domain | string | - | - | - |
| type | string | - | - | - |
| de_device_id | string | - | - | - |
| exp_version | int | - | - | - |
| env | string | - | - | - |
| unique_id | string | - | - | - |
| dre_ver | string | - | - | - |
| referer | struct\<ads_id, referer_type, track_json_data, referer_data, unique_id\> | - | - | - |
| livestream_props | struct\<ls_session_id, streamer_id, streaming_room_source, if_mini_ls, content_mix_frame_tab_name\> | - | - | - |
| conversion_type | int | - | - | - |
| grass_region | string | [PARTITION] Region code | - | - |
| grass_date | date | [PARTITION] Date | - | - |
| h | int | [PARTITION] Hour (0-23) | - | - |
