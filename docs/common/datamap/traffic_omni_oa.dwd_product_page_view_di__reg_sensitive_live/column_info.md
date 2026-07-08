<!-- ads-workspace-gdoc-sync: gdoc_id=1ZceKa2bhuIlj6-RlCOJOCjUnkkfN_GBQQcIRKQ2JL00 gdoc_url=https://docs.google.com/document/d/1ZceKa2bhuIlj6-RlCOJOCjUnkkfN_GBQQcIRKQ2JL00/edit -->

# Columns: traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

当前代码库中仅作为明细事件表使用，未见 SUM(DISTINCT) 模式。所有聚合均为 COUNT/SUM 条件聚合在分组键上。

### 枚举值映射 (Value Mappings)

*从 CASE-WHEN 提取，来自 2+ 个文件中的 omni_ppv_stay_time_base 公共 CTE*

| Column (derived) | Value | Meaning |
|--------|-------|---------|
| common_feature | Search Shop | Shop search item page |
| common_feature | Global Search | Global search results |
| common_feature | Image Search | Image search |
| common_feature | You May Also Like | YMAL recommendations |
| common_feature | Live Streaming | Live streaming room |
| common_feature | Daily Discover | Daily Discover feed |
| common_feature | Games | Games module |
| common_feature | Video | Video feed |
| common_feature | Order Successful Recommendation | Post-order recommendations |
| common_feature | Cart Recommendation | Cart page recommendations |
| common_feature | My Purchase Page Recommendation | MPP YMAL |
| common_feature | Order Detail Page Recommendation | ODP YMAL |
| common_feature | Me YMAL | Me page YMAL |
| common_feature | Voucher Landing Recommendation | Voucher landing |
| common_feature | Hot Deals Landing Recommendation | Hot deals landing |
| common_feature | Shop YMAL | Shop page YMAL |
| common_feature | Platform | All steps combined |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% of queries)
- `grass_region`: upper('${region}') — 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')
- `user_id`: > 0 (100% of queries, excludes anonymous)
- `is_back`: false (exclude back-navigation page views)
- `operation`: 'view' (for PPV and stay time computation)

## All Columns

> DDL 未在代码库中找到，以下列从 SQL 使用推断。请运行 --source from-di 补充完整列清单和描述。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date [PARTITION] | 分区日期 | - | - |
| grass_region | string [PARTITION] | 地区分区 | - | - |
| tz_type | string [PARTITION] | 时区类型 | - | - |
| user_id | bigint | 用户 ID | - | - |
| operation | string | 事件操作类型 (view/click/impression) | - | - |
| is_back | boolean | 是否为回退操作 | - | - |
| page_duration | bigint | 页面停留时长 (ms) | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| app_version | string | APP 版本 | - | - |
| platform | string | 平台 (android/ios) | - | - |
| feature_detail | string | 功能详情 | - | - |
| feature_group | string | 功能分组 | - | - |
| feature | string | 功能标识 | - | - |
| module | string | 模块名称 | - | - |
| page_type | string | 页面类型 | - | - |
| page_section | array | 页面区块 | - | - |
| target_type | string | 目标类型 | - | - |
| common_property | struct | 公共属性 (含 is_ads) | - | - |
| location_property | struct | 位置属性 (含 location) | - | - |
| last_item_click | struct | 上一次点击归因 (含 common_property.is_ads, module) | - | - |
| source1 | struct | 第一级来源归因 | - | - |
| source2 | struct | 第二级来源归因 | - | - |
| video_property | struct | 视频属性 (含 is_ymal_item) | - | - |
| search_property | struct | 搜索属性 (含 scenario) | - | - |
| rn_version | string | RN 版本 | - | - |
| scenario | string | 搜索场景 | - | - |
| object | string | 对象标识 | - | - |
