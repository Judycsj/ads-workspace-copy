<!-- ads-workspace-gdoc-sync: gdoc_id=1tII4cT45aYc4BXHxy8uMCWx7wTFj8NFXVpKaimkMCzM gdoc_url=https://docs.google.com/document/d/1tII4cT45aYc4BXHxy8uMCWx7wTFj8NFXVpKaimkMCzM/edit -->

# Columns: mp_paidads.dim_advertise__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为维度表，无需 SUM/SUM(DISTINCT) 聚合。但跨 placement 聚合时注意：
- 同一 ads_id 在多个 placement 有记录（placement 展开），统计"广告数"时需按 ads_id 去重

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0 | keyword:search |
| placement | 1 | targeting:similar_product |
| placement | 2 | targeting:daily_discover |
| placement | 3 | keyword:shop |
| placement | 4 | keyword:simple_mode |
| placement | 5 | targeting:ymal |
| placement | 7 | keyword:banner |
| placement | 801 | targeting:simple_mode_sp |
| placement | 802 | targeting:simple_mode_dd |
| placement | 805 | targeting:simple_mode_ymal |
| placement | 1000 | boost:search |
| placement | 1001 | boost:similar_product |
| placement | 1002 | boost:daily_discover |
| placement | 1005 | boost:ymal |
| placement | 1200 | auto_boost:search |
| placement | 1202 | auto_boost:daily_discover |
| placement | 1205 | auto_boost:ymal |
| placement | 20 | shop_simple |
| placement | 2003 | shop_simple (expanded) |
| placement | 2030 | shop_simple (expanded) |
| placement | 33 | live_stream (base) |
| placement | 3327-3348 | live_stream (expanded sub-placements) |
| placement | 40 | ROI2/discovery_ads |
| placement | 4400-4405 | placement 44 expanded |
| ads_status | (int) | 广告状态码 |
| campaign_status | 1 | Normal |
| is_ads_active | 0 | 当日无 INDEX 记录或 campaign 时间不覆盖 |
| is_ads_active | 1 | 当日有活跃投放记录 |
| tz_type | 'local' | 本地时区（主流使用） |
| target_roi_type | 0 | 有设定目标 ROI |
| target_roi_type | 1 | 未设定目标 ROI (target_roi=0) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (几乎所有查询都过滤 tz_type='local')
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')，部分场景加 'AR','MX'
- `placement`: 1002,1005 (Discovery/YMAL boost); 40 (ROI2); 33,3327-3348 (LiveStream); 0 (Search)
- `is_ads_active`: 1 (过滤活跃广告)
- `campaign_status`: 1 (Normal campaign)
- `ads_status`: 按需过滤

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告 ID | - | - |
| ads_status | int | 广告状态 | - | - |
| ads_create_datetime | string | 广告创建时间（本地时区） | - | - |
| placement | int | 投放位置（展开后） | - | - |
| ads_type | string | 投放类型标签 (keyword:search 等) | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| seller_id | bigint | 卖家 user_id | - | - |
| seller_name | string | 卖家名称 | - | - |
| language | string | 语言 | - | - |
| item_id | bigint | 商品 ID | - | - |
| item_name | string | 商品名称 | - | - |
| campaign_id | bigint | Campaign ID | - | - |
| campaign_status | int | Campaign 状态 | - | - |
| campaign_status_text | string | Campaign 状态文本 | - | - |
| total_quota_local | bigint | Campaign 总预算（本地币） | - | - |
| total_quota_usd | double | Campaign 总预算（USD） | - | - |
| daily_quota_local | bigint | Campaign 日预算（本地币） | - | - |
| daily_quota_usd | double | Campaign 日预算（USD） | - | - |
| campaign_start_datetime | string | Campaign 开始时间 | - | - |
| campaign_end_datetime | string | Campaign 结束时间 | - | - |
| is_ads_active | int | 当日是否有活跃投放 (0/1) | - | - |
| level1_global_be_category | struct | L1 BE 品类 (id, name) | - | - |
| level1_fe_display_category_list | array\<struct\> | L1 FE 展示品类列表 | - | - |
| level1_kpi_category_list | array\<struct\> | L1 KPI 品类列表 | - | - |
| level2_global_be_category | struct | L2 BE 品类 (id, name) | - | - |
| level2_fe_display_category_list | array\<struct\> | L2 FE 展示品类列表 | - | - |
| level2_kpi_category_list | array\<struct\> | L2 KPI 品类列表 | - | - |
| level3_global_be_category | struct | L3 BE 品类 (id, name) | - | - |
| level3_fe_display_category_list | array\<struct\> | L3 FE 展示品类列表 | - | - |
| level3_kpi_category_list | array\<struct\> | L3 KPI 品类列表 | - | - |
| is_segment_ad | int | 是否定向广告 (当前全部为 0) | - | - |
| filter_segments_age_list | - | 年龄定向（当前为 null） | - | - |
| filter_segments_gender_list | - | 性别定向（当前为 null） | - | - |
| filter_segments_location_list | - | 地域定向（当前为 null） | - | - |
| premium_segments_behavior_list | - | 行为定向溢价（当前为 null） | - | - |
| filter_segments_category_list | - | 品类定向（当前为 null） | - | - |
| boost_id | bigint | Boost ID | - | - |
| boost_package_id | bigint | Boost 套餐 ID | - | - |
| boost_price | double | Boost 价格 | - | - |
| boost_days | int | Boost 天数 | - | - |
| boost_est_views | bigint | Boost 预估曝光 | - | - |
| pricing_type | int | 出价类型 | - | - |
| auto_boost_algo_status | int | Auto Boost 算法状态 | - | - |
| daily_available_quota | bigint | 分位置日可用预算 | - | - |
| split_budget_version | int | 预算拆分版本 | - | - |
| is_budget_split | int | 是否预算拆分 (0/1) | - | - |
| target_roi | int | 目标 ROI | - | - |
| target_roi_type | int | ROI 类型 (0=有设定, 1=未设定) | - | - |
| ads_create_timestamp | bigint | 广告创建 Unix 时间戳 | - | - |
| ads_modify_timestamp | bigint | 广告修改 Unix 时间戳 | - | - |
| ads_modify_datetime | string | 广告修改时间（本地时区） | - | - |
| keywords | string | 关键词 JSON | - | - |
| target_price | double | 目标出价 (除以 100000) | - | - |
| target_premium_rate | int | 目标溢价率 | - | - |
| target_base_price | double | 基础出价 (除以 100000) | - | - |
| shop_customisation_display_title | string | 店铺自定义展示标题 | - | - |
| shop_customisation_image_url | string | 店铺自定义图片 URL | - | - |
| shop_customisation_collection_id | bigint | 店铺自定义合集 ID | - | - |
| banner_image_uri_pc | string | Banner PC 端图片 URI | - | - |
| banner_image_image_uri_app | string | Banner App 端图片 URI | - | - |
| banner_keywords | string | Banner 关键词 | - | - |
| banner_landing_page_url | string | Banner 落地页 URL | - | - |
| ta_group_id | bigint | 目标受众分组 ID | - | - |
| ta_premium_rate | int | 目标受众溢价率 | - | - |
| tag_ids | array\<int\> | 受众标签 ID 列表 | - | - |
| target_affiliate_user_id | bigint | 联盟直播目标用户 ID | - | - |
| sub_product_type | string | 子产品类型 | - | - |
| product_type | string | 产品类型 | - | - |
| main_product_type | string | 主产品类型 | - | - |
| post_id | bigint | 视频/帖子 ID | - | - |
| video_id | string | 视频 ID | - | - |
| video_status | string | 视频状态 | - | - |
| first_delivery_timestamp | bigint | 首次投放 Unix 时间戳 | - | - |
| first_delivery_datetime | string | 首次投放时间（本地时区） | - | - |
| potential_product_type | int | 潜力商品类型 | - | - |
| item_create_datetime | string | 商品创建时间 | - | - |
| search_brand_package_order_id | string | 搜索品牌包裹订单 ID | - | - |
| is_nominated_for_package_non_ads | tinyint | 是否被提名为非广告包裹 | - | - |
| is_organic_non_ads | tinyint | 是否自然非广告 | - | - |
| brand_max_type | int | Brand Max 类型 | - | - |
| brand_max_package_request_id | bigint | Brand Max 包裹请求 ID | - | - |
| tz_type | string | [PARTITION] 时区类型 ('local') | - | - |
| grass_region | string | [PARTITION] 地区代码 | - | - |
| grass_date | date | [PARTITION] 日期 | - | - |
