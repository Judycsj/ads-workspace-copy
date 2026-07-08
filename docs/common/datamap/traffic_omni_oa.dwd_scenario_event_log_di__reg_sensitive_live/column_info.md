<!-- ads-workspace-gdoc-sync: gdoc_id=1yLo7paVPQLy1WXS2w6lmMrwkkvTBEcPjTIytya5-oe4 gdoc_url=https://docs.google.com/document/d/1yLo7paVPQLy1WXS2w6lmMrwkkvTBEcPjTIytya5-oe4/edit -->

# Columns: traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live

> No DDL found in codebase (table managed by traffic_omni team). Columns below are inferred from SQL usage patterns in ads studio_tasks. Run `--source from-di` to supplement with DataMap definitions.

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

> 未从代码库中识别到 SUM(DISTINCT) 模式，本表为明细事件日志，自然可累加。

### 枚举值映射 (Value Mappings)

#### operation

从 WHERE 过滤推演：

| Value | Meaning |
|--------|---------|
| impression | 曝光事件 |
| click | 点击事件 |

#### common_feature (CASE-WHEN 映射, 多文件重复出现)

| Mapping Rule | Output Value |
|--------|---------|
| feature_detail like '%-shop_item' AND feature_group = 'Search' OR feature_detail = 'search-shop' | Search Shop |
| module = 'Global Search' | Global Search |
| module = 'Image Search' | Image Search |
| feature_group = 'You May Also Like' | You May Also Like |
| feature_group = 'Order Successful Recommendation' | Order Successful Recommendation |
| feature_group = 'Cart Recommendation' | Cart Recommendation |
| feature = 'mpp_ymal-order_list' | My Purchase Page Recommendation |
| feature = 'odp_ymal-order_detail' | Order Detail Page Recommendation |
| module = 'Daily Discover' | Daily Discover |
| feature_group = 'Video' | Video |
| feature_group = 'Games' | Games |
| feature_group = 'Live Streaming' | Live Streaming |
| feature_detail = 'me-you_may_also_like-item' | Me YMAL |
| feature = 'voucher-voucher_landing' | Voucher Landing Recommendation |
| feature = 'crm_omni_attri-hot_deals_landing' | Hot Deals Landing Recommendation |
| feature_detail = 'shop-you_may_also_like-item' | Shop YMAL |
| else | Others |

#### entry_point (CASE-WHEN 映射, 多文件重复出现)

| Mapping Rule | Output Value |
|--------|---------|
| page_type = 'search' AND page_section IS NULL AND target_type IN ('item','video','livestream','related_search') AND scenario NOT IN shop scenarios | Global Search |
| module = 'Image Search' | Image Search |
| feature_group = 'You May Also Like' AND target_type NOT IN ('video') | You May Also Like |
| feature_group = 'You May Also Like' AND target_type IN ('video') | YMAL Video External |
| feature_detail = 'me-you_may_also_like-item' | Me You May Also Like |
| feature_group = 'Order Successful Recommendation' | Order Successful Recommendation |
| feature = 'mpp_ymal-order_list' | My Purchase Page Recommendation |
| feature = 'odp_ymal-order_detail' | Order Detail Page Recommendation |
| feature_group = 'Cart Recommendation' | Cart Recommendation |
| module = 'Daily Discover' | Daily Discover External |
| else | Undefined |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% of queries -- the `_local` variant is used; regional variant uses `tz_type='regional'`)
- `operation`: in ('impression', 'click') -- 几乎所有查询都过滤这两类事件
- `user_id`: > 0 -- 排除未登录用户
- `grass_region`: upper('${region}') -- 逐区域处理

## All Columns

> Columns below are inferred from SQL SELECT usage. No DDL to confirm exact column names and types.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 | - | - |
| grass_region | string | 分区域 (如 ID, MY, PH) | - | - |
| tz_type | string | 时区类型 ('local' / 'regional') | - | - |
| operation | string | 事件操作类型 ('impression' / 'click') | - | - |
| user_id | bigint | 用户 ID | - | - |
| common_property | struct | 通用属性 (含 is_ads 布尔值) | - | - |
| platform | string | 平台 (iOS/Android) | - | - |
| rn_version | string | React Native 版本 | - | - |
| search_property | struct | 搜索属性 (含 scenario) | - | - |
| page_type | string | 页面类型 | - | - |
| page_section | string/null | 页面区域 (搜索场景下为空) | - | - |
| target_type | string | 目标类型 (item/video/livestream/related_search) | - | - |
| module | string | 模块名 (Global Search/Image Search/Daily Discover/...) | - | - |
| feature_detail | string | 特征详情 | - | - |
| feature_group | string | 特征分组 (Search/You May Also Like/Video/...) | - | - |
| feature | string | 特征标识 | - | - |
| object | string | 上报对象 | - | - |
| app_version | string/null | App 版本号 | - | - |
| item_id | bigint/null | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| location_property | struct | 位置属性 (含 location) | - | - |
| last_item_click | struct | 最近一次 item 点击的属性 (归因用) | - | - |
| source1 | struct | 归因链源1 (含 common_property.is_ads 等) | - | - |
| source2 | struct | 归因链源2 (含 common_property.is_ads 等) | - | - |
