<!-- ads-workspace-gdoc-sync: gdoc_id=1vTvu-nMyUhYAiQtVNOyFVibySVsRkIRJnewIPCD7wRo gdoc_url=https://docs.google.com/document/d/1vTvu-nMyUhYAiQtVNOyFVibySVsRkIRJnewIPCD7wRo/edit -->

# Columns: traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无明确 SUM(DISTINCT) 模式发现。但注意：
- `atc_prorate` 和 `first_touchpoint_item` / `last_touchpoint_item` 作为归因权重，GMV/order 指标必须乘以这些权重
- 跨 touchpoint (click/source1/source2) 的 UNION ALL 模式下，同一 order 会出现多次，不可直接 SUM

### 枚举值映射 (Value Mappings)

#### feature_group_omni → common_feature 映射

| feature_group_omni / feature_detail_omni / module | common_feature | 出现文件数 |
|---|---|---|
| module = 'Global Search' | Global Search | 10+ |
| module = 'Image Search' | Image Search | 5+ |
| module = 'Daily Discover' | Daily Discover | 10+ |
| feature_group_omni = 'You May Also Like' | You May Also Like | 10+ |
| feature_group_omni = 'Live Streaming' | Live Streaming | 10+ |
| feature_group_omni = 'Games' | Games | 5+ |
| feature_group_omni = 'Video' | Video | 5+ |
| feature_group_omni = 'Order Successful Recommendation' | Order Successful Recommendation | 5+ |
| feature_group_omni = 'Cart Recommendation' | Cart Recommendation | 5+ |
| feature_omni = 'mpp_ymal-order_list' | My Purchase Page Recommendation | 5+ |
| feature_omni = 'odp_ymal-order_detail' | Order Detail Page Recommendation | 5+ |
| feature_detail_omni = 'me-you_may_also_like-item' | Me YMAL | 5+ |
| feature_detail_omni = 'shop-you_may_also_like-item' | Shop YMAL | 5+ |
| feature_omni = 'voucher-voucher_landing' | Voucher Landing Recommendation | 3+ |
| feature_omni = 'crm_omni_attri-hot_deals_landing' | Hot Deals Landing Recommendation | 3+ |
| feature_group_omni = 'Buy Again (Me Page)' | Buy Again (Me Page) | 2+ |
| feature_detail_omni LIKE '%-shop_item' + feature_group_omni = 'Search' | Search Shop | 5+ |

#### click_common_property.entrance → entrance 映射

| entrance value | Meaning | 出现文件数 |
|---|---|---|
| 1, 23 | SEARCH | 3+ |
| 3 | DD (Daily Discover) | 3+ |
| 4 | YMAL | 3+ |
| 7, 14-22, 26 | GAME | 3+ |
| 8, 9, 10, 11 | PP (Post Purchase) | 3+ |
| 29, 31-34, 36 | VIDEO | 3+ |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (绝大多数查询使用 local timezone)
- `grass_region`: 标准 8 区 `('ID','MY','PH','SG','TH','TW','VN','BR')`
- `first_touchpoint_item`: = 1 (第一触点归因，~80% 查询使用)
- `user_id`: > 0 (过滤无效用户)
- `feature_group_omni`: 'Search', 'You May Also Like', 'Live Streaming', 'Games', 'Video', 'Daily Discover' 等
- `click_common_property.is_ads`: true/false (广告归因判断)

### 多触点属性对照 (Multi-Touchpoint Property Mapping)

此表有三层触点属性，命名规则一致：

| Click (step 0) | Source1 (step 1) | Source2 (step 2) |
|---|---|---|
| feature_group_omni | source1_feature_group_omni | source2_feature_group_omni |
| feature_detail_omni | source1_feature_detail_omni | source2_feature_detail_omni |
| feature_omni | source1_feature_omni | source2_feature_omni |
| module | source1_module | source2_module |
| business_line | source1_business_line | source2_business_line |
| object | source1_object | source2_object |
| click_common_property.is_ads | source1_common_property.is_ads | source2_common_property.is_ads |
| click_common_property.entrance | - | - |
| click_location_property.location | source1_location_property.location | source2_location_property.location |
| click_search_property.keyword | source1_search_property.keyword | source2_search_property.keyword |
| click_search_property.image_source | source1_search_property.image_source | source2_search_property.image_source |
| click_video_property.request_id | - | - |

## All Columns

> DDL 未在代码库中找到（非 Paid Ads 团队维护的外部表）。以下列名来自实际 SQL 引用中观察到的字段：

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区列 - 日期 | - | - |
| grass_region | string | 分区列 - 地区 | - | - |
| tz_type | string | 分区列 - 时区类型 (local/regional) | - | - |
| order_id | bigint | 订单 ID | - | - |
| order_item_id | bigint | 订单商品 ID | - | - |
| order_model_id | bigint | 订单 model ID | - | - |
| group_id | bigint | 订单 group ID | - | - |
| bundle_order_item_id | bigint | bundle 订单 item ID | - | - |
| user_id | bigint | 买家用户 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| item_id | bigint | 商品 ID (部分 SQL 使用 order_item_id) | - | - |
| app_version | string | App 版本号 | - | - |
| gmv | double | GMV 本地货币 | - | - |
| gmv_usd | double | GMV 美元 | - | - |
| place_sellergmv_usd | double | 卖家 GMV (USD) | - | - |
| order_fraction | double | 订单分摊系数 | - | - |
| item_amount | bigint | 商品数量 | - | - |
| atc_prorate | double | ATC 分摊权重 | - | - |
| first_touchpoint_item | int | 是否第一触点 (0/1) | - | - |
| last_touchpoint_item | int | 是否最后触点 (0/1) | - | - |
| order_place_timestamp | bigint | 下单时间戳 | - | - |
| feature_group_omni | string | Omni 入口大类 (Search/DD/YMAL/Live/Video/Games...) | - | - |
| feature_omni | string | Omni 入口细分 | - | - |
| feature_detail_omni | string | Omni 入口详情 | - | - |
| module | string | 模块 (Global Search/Image Search/Daily Discover...) | - | - |
| business_line | string | 业务线 (Search/Homepage/Rcmd...) | - | - |
| object | string | 对象 (you may also like/post purchase...) | - | - |
| page_type | string | 页面类型 | - | - |
| click_common_property | struct | 点击公共属性 (含 is_ads, entrance) | - | - |
| click_location_property | struct | 点击位置属性 (含 location) | - | - |
| click_search_property | struct | 搜索属性 (含 keyword, image_source) | - | - |
| click_video_property | struct | 视频属性 (含 request_id) | - | - |
| source1_common_property | struct | Source1 公共属性 (含 is_ads) | - | - |
| source1_location_property | struct | Source1 位置属性 (含 location) | - | - |
| source1_search_property | struct | Source1 搜索属性 | - | - |
| source1_feature_group_omni | string | Source1 入口大类 | - | - |
| source1_feature_detail_omni | string | Source1 入口详情 | - | - |
| source1_feature_omni | string | Source1 入口细分 | - | - |
| source1_module | string | Source1 模块 | - | - |
| source1_business_line | string | Source1 业务线 | - | - |
| source1_object | string | Source1 对象 | - | - |
| source1_page_type | string | Source1 页面类型 | - | - |
| source2_common_property | struct | Source2 公共属性 (含 is_ads) | - | - |
| source2_location_property | struct | Source2 位置属性 (含 location) | - | - |
| source2_search_property | struct | Source2 搜索属性 | - | - |
| source2_feature_group_omni | string | Source2 入口大类 | - | - |
| source2_feature_detail_omni | string | Source2 入口详情 | - | - |
| source2_feature_omni | string | Source2 入口细分 | - | - |
| source2_module | string | Source2 模块 | - | - |
| source2_business_line | string | Source2 业务线 | - | - |
| source2_object | string | Source2 对象 | - | - |
| omni_commission_fee | double | Omni 佣金 (本地货币) | - | - |
| omni_commission_fee_usd | double | Omni 佣金 (USD) | - | - |

<!-- ANALYSIS_PLACEHOLDER -->
