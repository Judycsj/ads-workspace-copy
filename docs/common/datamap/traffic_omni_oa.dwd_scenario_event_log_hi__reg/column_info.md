<!-- ads-workspace-gdoc-sync: gdoc_id=1oQxC2kWud7pxuX3i3AkCuaj2M3Yi0NliMJTX53DVb78 gdoc_url=https://docs.google.com/document/d/1oQxC2kWud7pxuX3i3AkCuaj2M3Yi0NliMJTX53DVb78/edit -->

# Columns: traffic_omni_oa.dwd_scenario_event_log_hi__reg

## Column Usage Notes

### 枚举值映射 (Value Mappings)

Entry point classification (CASE-WHEN logic, consistent across 2+ workflows):

| Column | Value | Meaning |
|--------|-------|---------|
| page_type | 'search' | Global Search (combined with page_section IS NULL and target_type filter) |
| module | 'Image Search' | Image Search entry point |
| module | 'Daily Discover' | Daily Discover External entry point |
| feature_group | 'You May Also Like' | YMAL entry point (with target_type NOT IN ('video') filter) |
| feature_group | 'Order Successful Recommendation' | Order Successful Recommendation entry point |
| feature_group | 'Cart Recommendation' | Cart Recommendation entry point |
| feature | 'mpp_ymal-order_list' | My Purchase Page Recommendation |
| feature | 'odp_ymal-order_detail' | Order Detail Page Recommendation |
| feature_detail | 'me-you_may_also_like-item' | Me You May Also Like entry point |
| feature | 'voucher-voucher_landing' | Voucher Landing Recommendation (in organic_metrics only) |
| feature | 'crm_omni_attri-hot_deals_landing' | Hot Deals Landing Recommendation (in organic_metrics only) |
| feature_detail | 'shop-you_may_also_like-item' | Shop You May Also Like (in organic_metrics only) |
| feature_group | 'Games' | Games entry (in organic_metrics only) |
| feature_group | 'Live Streaming' | Live Streaming (in organic_metrics only) |
| feature_group | 'Video' | Video entry (in organic_metrics only) |
| common_property.is_ads | true / 1 | Ads traffic (vs organic when false/null) |
| operation | 'impression' | Impression event |
| operation | 'click' | Click event |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (used in all 41 files)
- `operation` IN ('impression', 'click') (~50% of queries) / 'impression' only (~40% of queries)
- `grass_region`: upper('${region}') -- standard 8 regions (ID, MY, PH, SG, TH, TW, VN, BR)
- `user_id` > 0 AND `user_id` IS NOT NULL -- always applied
- `search_property.scenario` NOT IN ('PAGE_SHOP','PAGE_SHOP_SEARCH','PAGE_SHOP_CATEGORY','PAGE_SHOP_CATEGORY_SEARCH') -- filter out shop-scoped searches for Global Search classification

## All Columns

Columns inferred from SQL usage across 37 reference files. Type and description are approximate (no DDL found in codebase -- run `--source from-di` for authoritative definitions).

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | Partition: event date | - | - |
| grass_hour | string | Partition: event hour | - | - |
| tz_type | string | Partition: timezone type (typically 'local') | - | - |
| grass_region | string | Partition: region code (ID,MY,PH,SG,TH,TW,VN,BR) | - | - |
| user_id | bigint | User identifier | - | - |
| operation | string | Event operation type (impression, click) | - | - |
| platform | string | Platform ID (0=unknown,1=ios_web,2=ios_app,3=android_web,4=android_app,5=pc_mall,etc.) | - | - |
| rn_version | string | RN version / app build version | - | - |
| app_version | string | App version string | - | - |
| search_property | struct | Nested: .scenario (search scenario like PAGE_SHOP, PAGE_SHOP_SEARCH, etc.) | - | - |
| page_type | string | Page type (e.g., 'search') | - | - |
| page_section | string | Page section | - | - |
| target_type | string | Target content type (item, video, livestream, related_search) | - | - |
| module | string | Module name (Global Search, Image Search, Daily Discover, etc.) | - | - |
| feature_detail | string | Detailed feature path (e.g., 'me-you_may_also_like-item') | - | - |
| feature_group | string | Feature group (You May Also Like, Games, Live Streaming, etc.) | - | - |
| feature | string | Feature identifier (e.g., 'mpp_ymal-order_list', 'odp_ymal-order_detail') | - | - |
| object | string | Object type | - | - |
| common_property | struct | Nested: .is_ads (boolean, indicates ads traffic) | - | - |
| shop_id | bigint | Shop identifier | - | - |
| item_id | bigint | Item identifier | - | - |
| location_property | struct | Nested: .location (INT, position in listing) | - | - |
