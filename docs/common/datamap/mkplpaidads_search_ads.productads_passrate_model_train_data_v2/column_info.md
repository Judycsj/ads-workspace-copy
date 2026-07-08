<!-- ads-workspace-gdoc-sync: gdoc_id=17HIDuQ8gCVNoIpmZssvUyYM35UXuWa-dmZqlbgVTiQY gdoc_url=https://docs.google.com/document/d/17HIDuQ8gCVNoIpmZssvUyYM35UXuWa-dmZqlbgVTiQY/edit -->

# Columns: mkplpaidads_search_ads.productads_passrate_model_train_data_v2

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表为 ads_id x item_id 粒度，所有指标已是单条记录级别，不存在跨维度聚合导致的重复计算问题。但以下字段在跨日期/区域聚合时需注意：

- `free_shipping` — boolean 类型，聚合时需明确语义
- `cspu_type`, `is_p0_cspu_type` — 商品属性，跨分区取最新的

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| item_type | npb | Normal Product Business（普通商品） |
| item_type | cold_start | 冷启动商品 |
| item_type | empty_order_expand | 无订单扩展商品 |
| pricing_type | 11, 15 | Product Ads（代码中过滤） |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 单日分区过滤，训练时使用 8 天前数据
- `grass_region`: 单区域训练，如 'ID', 'TH', 'MY', 'VN', 'PH', 'SG', 'TW', 'BR'
- `item_type`: 'npb'（~60% 引用，7d1o 模型）/ 'cold_start'/'empty_order_expand'（~40%，7d3o 模型）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| pricing_type | int | 出价类型 | - | - |
| ads_id | bigint | 广告 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| l1_cat | bigint | 一级类目 | - | - |
| l2_cat | bigint | 二级类目 | - | - |
| discount | double | 折扣率 | - | - |
| free_shipping | boolean | 是否包邮 | - | - |
| creation_elapsed_duration | double | 商品创建至今时长 | - | - |
| stock | int | 库存数量 | - | - |
| cspu_type | bigint | CSPU 类型 | - | - |
| is_p0_cspu_type | int | 是否为 P0 CSPU 类型 | - | - |
| platform_impression_cnt_7d | double | 平台 7 天曝光数 | - | - |
| platform_click_cnt_7d | double | 平台 7 天点击数 | - | - |
| platform_atc_cnt_7d | double | 平台 7 天加购数 | - | - |
| platform_order_cnt_7d | double | 平台 7 天订单数 | - | - |
| platform_impression_cnt_14d | double | 平台 14 天曝光数 | - | - |
| platform_click_cnt_14d | double | 平台 14 天点击数 | - | - |
| platform_atc_cnt_14d | double | 平台 14 天加购数 | - | - |
| platform_order_cnt_14d | double | 平台 14 天订单数 | - | - |
| platform_impression_cnt_30d | double | 平台 30 天曝光数 | - | - |
| platform_click_cnt_30d | double | 平台 30 天点击数 | - | - |
| platform_atc_cnt_30d | double | 平台 30 天加购数 | - | - |
| platform_order_cnt_30d | double | 平台 30 天订单数 | - | - |
| platform_ctr_7d | double | 平台 7 天点击率 | - | - |
| platform_cr_7d | double | 平台 7 天转化率 | - | - |
| platform_atc_cr_7d | double | 平台 7 天加购转化率 | - | - |
| platform_ctr_14d | double | 平台 14 天点击率 | - | - |
| platform_cr_14d | double | 平台 14 天转化率 | - | - |
| platform_atc_cr_14d | double | 平台 14 天加购转化率 | - | - |
| platform_ctr_30d | double | 平台 30 天点击率 | - | - |
| platform_cr_30d | double | 平台 30 天转化率 | - | - |
| platform_atc_cr_30d | double | 平台 30 天加购转化率 | - | - |
| platform_ctcvr_7d | double | 平台 7 天 CTCVR | - | - |
| platform_ctcvr_14d | double | 平台 14 天 CTCVR | - | - |
| platform_ctcvr_30d | double | 平台 30 天 CTCVR | - | - |
| create_time | date | 商品创建日期 | - | - |
| campaign_daily_quota_usd | double | 计划日预算（USD） | - | - |
| price_usd | double | 出价（USD） | - | - |
| target_roi | double | 目标 ROI | - | - |
| cpa | double | CPA | - | - |
| l1_campaign_daily_quota_usd_percentile | double | L1 类目内日预算百分位 | - | - |
| l1_price_usd_percentile | double | L1 类目内出价百分位 | - | - |
| l1_troi_percentile | double | L1 类目内目标 ROI 百分位 | - | - |
| l1_cpa_percentile | double | L1 类目内 CPA 百分位 | - | - |
| l1_l2_campaign_daily_quota_usd_percentile | double | L1_L2 类目内日预算百分位 | - | - |
| l1_l2_price_usd_percentile | double | L1_L2 类目内出价百分位 | - | - |
| l1_l2_troi_percentile | double | L1_L2 类目内目标 ROI 百分位 | - | - |
| l1_l2_cpa_percentile | double | L1_L2 类目内 CPA 百分位 | - | - |
| ads_total_impression_cnt_7d | bigint | 广告 7 天总曝光数 | - | - |
| ads_total_click_cnt_7d | bigint | 广告 7 天总点击数 | - | - |
| ads_total_add_to_cart_cnt_7d | bigint | 广告 7 天总加购数 | - | - |
| ads_total_order_cnt_7d | bigint | 广告 7 天总订单数 | - | - |
| ads_total_impression_cnt_14d | bigint | 广告 14 天总曝光数 | - | - |
| ads_total_click_cnt_14d | bigint | 广告 14 天总点击数 | - | - |
| ads_total_add_to_cart_cnt_14d | bigint | 广告 14 天总加购数 | - | - |
| ads_total_order_cnt_14d | bigint | 广告 14 天总订单数 | - | - |
| ads_total_impression_cnt_30d | bigint | 广告 30 天总曝光数 | - | - |
| ads_total_click_cnt_30d | bigint | 广告 30 天总点击数 | - | - |
| ads_total_add_to_cart_cnt_30d | bigint | 广告 30 天总加购数 | - | - |
| ads_total_order_cnt_30d | bigint | 广告 30 天总订单数 | - | - |
| ads_ctr_7d | double | 广告 7 天点击率 | - | - |
| ads_ctr_14d | double | 广告 14 天点击率 | - | - |
| ads_ads_ctr_30d | double | 广告 30 天点击率 | - | - |
| ads_atc_cr_7d | double | 广告 7 天加购转化率 | - | - |
| ads_atc_cr_14d | double | 广告 14 天加购转化率 | - | - |
| ads_atc_cr_30d | double | 广告 30 天加购转化率 | - | - |
| ads_cr_7d | double | 广告 7 天转化率 | - | - |
| ads_cr_14d | double | 广告 14 天转化率 | - | - |
| ads_cr_30d | double | 广告 30 天转化率 | - | - |
| ads_ctcvr_7d | double | 广告 7 天 CTCVR | - | - |
| ads_ctcvr_14d | double | 广告 14 天 CTCVR | - | - |
| ads_ctcvr_30d | double | 广告 30 天 CTCVR | - | - |
| order_7d_cnt | bigint | 接下来 7 天直接订单数（训练 label） | - | - |
| ads_first_delivery_date | date | 广告首次投放日期 | - | - |
| delivery_elapsed_duration | double | 广告投放至今时长 | - | - |
| item_type | string | 商品类型（npb / cold_start / empty_order_expand） | - | - |
| campaign_id | bigint | 计划 ID | - | - |
| avg_pctr_7d | double | 预估 CTR 7 天均值 | - | - |
| avg_pcr_7d | double | 预估 CR 7 天均值 | - | - |
| avg_pctcvr_7d | double | 预估 CTCVR 7 天均值 | - | - |
| avg_pctr_14d | double | 预估 CTR 14 天均值 | - | - |
| avg_pcr_14d | double | 预估 CR 14 天均值 | - | - |
| avg_pctcvr_14d | double | 预估 CTCVR 14 天均值 | - | - |
| ads_total_p_ctcvr_7d | double | 新 P-label：广告预估 CTCVR 7 天总和 | - | - |
| grass_date | date | [PARTITION] 数据日期（T-8） | - | - |
| grass_region | string | [PARTITION] 区域 | - | - |
