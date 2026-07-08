<!-- ads-workspace-gdoc-sync: gdoc_id=1yGip0V6MyRrm8Ao0XV3iKjL6jI5m6zqDatkIp2LdcR0 gdoc_url=https://docs.google.com/document/d/1yGip0V6MyRrm8Ao0XV3iKjL6jI5m6zqDatkIp2LdcR0/edit -->

# Columns: traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live

> No DDL found in codebase. Columns below are inferred from SQL usage patterns. Run `--source from-di` to supplement with DataMap definitions.

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

> 未从代码库中识别到 SUM(DISTINCT) 模式，本表为明细事件日志，自然可累加。

### 枚举值映射 (Value Mappings)

#### operation

| Value | Meaning |
|--------|---------|
| impression | 曝光事件 |
| click | 点击事件 |

#### common_feature (CASE-WHEN 映射, 多文件重复出现)

| Mapping Rule | Output Value |
|--------|---------|
| module = 'Global Search' | Global Search |
| module = 'Image Search' | Image Search |
| feature_group = 'You May Also Like' | You May Also Like |
| feature_group = 'Live Streaming' | Live Streaming |
| feature_group = 'Order Successful Recommendation' | Order Successful Recommendation |
| feature_group = 'Cart Recommendation' | Cart Recommendation |
| feature = 'mpp_ymal-order_list' | My Purchase Page Recommendation |
| feature = 'odp_ymal-order_detail' | Order Detail Page Recommendation |
| module = 'Daily Discover' | Daily Discover |
| feature_group = 'Video' | Video |
| feature_group = 'Games' | Games |
| feature_detail like '%-shop_item' and feature_group = 'Search' | Search Shop |
| feature_detail = 'me-you_may_also_like-item' | Me YMAL |
| feature = 'voucher-voucher_landing' | Voucher Landing Recommendation |
| feature = 'crm_omni_attri-hot_deals_landing' | Hot Deals Landing Recommendation |
| feature_detail = 'shop-you_may_also_like-item' | Shop YMAL |
| feature_detail = 'order_shipping_info-you_may_also_like-item' | Shipping Info Page YMAL |
| feature_detail = 'search-shop' | Search Shop |
| else | Others |

#### entry_point (CASE-WHEN 映射, 多文件重复出现)

| Mapping Rule | Output Value |
|--------|---------|
| page_type = 'search' and page_section is null and target_type in ('item','video','livestream','related_search') | Global Search |
| module = 'Image Search' | Image Search |
| feature_group = 'You May Also Like' and target_type not in ('video') | You May Also Like |
| feature_group = 'You May Also Like' and target_type in ('video') | YMAL Video External |
| feature_detail = 'me-you_may_also_like-item' | Me You May Also Like |
| feature_group = 'Order Successful Recommendation' | Order Successful Recommendation |
| feature = 'mpp_ymal-order_list' | My Purchase Page Recommendation |
| feature = 'odp_ymal-order_detail' | Order Detail Page Recommendation |
| feature_group = 'Cart Recommendation' | Cart Recommendation |
| module = 'Daily Discover' | Daily Discover External |
| feature_detail like DD mixfeed pattern | Daily Discover Mix Feed Internal |
| feature_detail = 'shop-you_may_also_like-item' | Shop You May Also Like |
| feature_group = 'Video' and is_ymal_item = 1 | Video You May Also Like |
| else | Undefined |

#### tz_type

| Value | Meaning |
|--------|---------|
| local | Localtime-based (most queries) |

#### business_line

| Value | Meaning |
|--------|---------|
| Homepage | Homepage events (used in Live Ads Tracker) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: date('${grass_date}') -- 几乎 100% 查询
- `grass_region`: upper('${region}') -- 按区域过滤
- `tz_type`: 'local' -- 几乎所有查询使用 local 时区
- `user_id`: `> 0` -- 排除匿名用户
- `operation`: `in ('impression', 'click')` -- 曝光和点击
- `target_type`: 'item' -- item 级事件 (Live Ads Tracker)
- `feature_detail`: `like 'image_search-%'` -- 图片搜索场景
- `feature_detail`: `like '%-shop_item'` -- Search Shop 场景
- `common_property.is_ads`: `= true` / `!= true or is null` -- ads vs organic 分流
- `search_property.image_source`: `in ('DD_rcmd','PDP_FS','PDP_YMAL','SEARCH_RESULT_CARD',...)` -- 图片搜索来源

## All Columns

Columns inferred from SQL usage in codebase (no DDL available):

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 [PARTITION] | - | - |
| grass_region | string | 分区区域 [PARTITION] | - | - |
| tz_type | string | 时区类型 (local/regional) [PARTITION] | - | - |
| operation | string | 事件操作类型 (impression/click) | - | - |
| event_type | string | 事件类型 | - | - |
| user_id | bigint | 用户 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| ads_id | bigint | 广告 ID | - | - |
| app_version | string | App 版本号 | - | - |
| platform | string | 平台 (ios_app/android_app) | - | - |
| rn_version | string | React Native 版本 | - | - |
| page_type | string | 页面类型 (search/mix_feed_page 等) | - | - |
| page_section | string | 页面区域 | - | - |
| target_type | string | 目标类型 (item/video/livestream/related_search) | - | - |
| module | string | 上报模块 (Global Search/Image Search/Daily Discover 等) | - | - |
| feature | string | 具体功能标识 (mpp_ymal-order-list 等) | - | - |
| feature_group | string | 功能分组 (You May Also Like/Live Streaming/Games 等) | - | - |
| feature_detail | string | 功能详情 (image_search-* / *-shop_item 等) | - | - |
| object | string | 上报对象 | - | - |
| business_line | string | 业务线 (Homepage 等) | - | - |
| common_property | struct | 通用属性 (含 is_ads: boolean) | - | - |
| source1 | struct | Step1 归因数据 (含 common_property, location_property, module, feature_detail, feature_group, feature) | - | - |
| source2 | struct | Step2 归因数据 (同 source1 结构) | - | - |
| location_property | struct | 位置属性 (含 location: bigint) | - | - |
| search_property | struct | 搜索属性 (含 scenario: string, image_source: string) | - | - |
| video_property | struct | 视频属性 (含 is_ymal_item: int) | - | - |
| event_timestamp | timestamp | 事件时间戳 | - | - |
