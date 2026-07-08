<!-- ads-workspace-gdoc-sync: gdoc_id=1J7cjwItdsKRjFcAVeLDU8fX0ccgaUf38EXI0zddnuCg gdoc_url=https://docs.google.com/document/d/1J7cjwItdsKRjFcAVeLDU8fX0ccgaUf38EXI0zddnuCg/edit -->

# Columns: traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

*From CASE-WHEN patterns in 2+ files (video_vv_not, query8, dws_display_ads_performance_di, dws_advertise_user_exp_common_feature_performance)*

| Column | Value | Meaning |
|--------|-------|---------|
| operation | action_add_to_cart_success | Add to cart action (most common filter) |
| page_type | (various) | Page context: product, search, home, etc. |
| common_feature (derived) | Search Shop | Search within shop |
| common_feature (derived) | Global Search | Global search results |
| common_feature (derived) | Image Search | Image-based search |
| common_feature (derived) | You May Also Like | YMAL recommendation |
| common_feature (derived) | Daily Discover | Daily Discover feed |
| common_feature (derived) | Video | Video feed |
| common_feature (derived) | Live Streaming | Live streaming room |
| common_feature (derived) | Me YMAL | Me page recommendations |
| common_feature (derived) | Games | Games section |
| common_feature (derived) | Platform | All steps aggregated |
| common_feature (derived) | Others | Not matched (filtered out in aggregations) |

### 常见 WHERE 值 (Common Filter Values)

- `operation` = 'action_add_to_cart_success' (consistently across all queries)
- `grass_region` = upper('${region}') (region-specific, typically ID/MY/PH/SG/TH/TW/VN/BR)
- `tz_type` = 'local' (always local timezone for ATC event analysis)
- `grass_date` = date('${grass_date}') / '${bizTimeFormatter(BIZ_TIME,"yyyy-MM-dd","-1d")}'
- `user_id` > 0 (exclude anonymous users)
- `common_feature` != 'Others' (exclude unmatched features in aggregations)
- `page_type` in ('null','bundle_deal') (specific filter in Display Ads workflow)

### 非累加字段 (Non-Additive Fields)

*No SUM(DISTINCT) patterns identified in read references.* ATC events at event_id level are naturally additive.

## All Columns

*DDL not found in codebase. Columns inferred from actual SQL usage in 21 reference files.*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | [PARTITION] Event date | - | - |
| grass_region | string | [PARTITION] Region code | - | - |
| user_id | bigint | User who performed ATC | - | - |
| item_id | bigint | Item added to cart | - | - |
| shop_id | bigint | Shop of the item | - | - |
| event_timestamp | bigint | Event timestamp (ms, divided by 1000 for seconds) | - | - |
| event_id | string | Unique event identifier | - | - |
| item_quantity | bigint | Quantity added to cart | - | - |
| item_price | decimal | Item unit price | - | - |
| operation | string | Event operation type | - | - |
| page_type | string | Page type context | - | - |
| page_section | array\<string\> | Page section detail | - | - |
| target_type | string | Target element type | - | - |
| session_id | string | User session id | - | - |
| platform | string | Platform (iOS/Android) | - | - |
| rn_version | string | App RN version | - | - |
| app_version | string | App version | - | - |
| common_property | struct | Common properties (incl. is_ads flag, request_id, etc.) | - | - |
| source1.common_property | struct | Step-1 source properties (incl. is_ads) | - | - |
| source2.common_property | struct | Step-2 source properties (incl. is_ads) | - | - |
| last_item_click | struct | Last item click context (module, common_property, etc.) | - | - |
| location_property | struct | Location property (incl. location int) | - | - |
| feature_detail | string | Feature detail identifier (e.g. 'video-mix_feed_page-...') | - | - |
| feature_group | string | Feature group (e.g. 'Search', 'You May Also Like') | - | - |
| feature | string | Feature name (e.g. 'mpp_ymal-order_list') | - | - |
| module | string | Module name (e.g. 'Global Search', 'Daily Discover') | - | - |
| search_property | struct | Search-related properties (keyword, scenario, etc.) | - | - |
| video_property | struct | Video-related properties (is_ymal_item, etc.) | - | - |
| spu_vsku_property | struct | SPU/VSku properties (spu_vsku_item_id, spu_vsku_shop_id, ctx_item_type) | - | - |
| tz_type | string | Timezone type (typically 'local') | - | - |
