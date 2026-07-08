<!-- ads-workspace-gdoc-sync: gdoc_id=1ukdm07eGwXvljnnORb65gwtzkhOqt4JNvY7Jg3CMdBA gdoc_url=https://docs.google.com/document/d/1ukdm07eGwXvljnnORb65gwtzkhOqt4JNvY7Jg3CMdBA/edit -->

# Columns: mkplpaidads_search_ads.product_ads_business_tag

## Column Usage Notes

### 枚举值映射 (Value Mappings)

**pricing_type** — 计费类型，定义业务标签的生成逻辑：

| Value | Meaning | Applies To |
|-------|---------|------------|
| 11 | target_roas2.0 (ROI2) | all tags |
| 15 | simple2.0 (Simple ROI2) | all tags |
| 24 | gms | multi_item tags + pricing_type_tag (BR only) |
| 25 | multi_product | multi_item tags + pricing_type_tag (BR only) |
| 27 | gms_simple | multi_item tags + pricing_type_tag (BR only) |

**business_tag** — 业务标签，每个值代表一种 campaign 业务状态判定：

| Value | Meaning | Logic Summary |
|-------|---------|---------------|
| cold_start | 冷启动 | 近8天创建 + 过去7天出单 < 5 |
| empty_order | 空耗 | 创建 > 7天 + 过去7天出单 <= 0 |
| empty_order_expand | 空耗承接期 | 最近14天内破零 + 最近7天有破零且总单<3，或最近7天无单 |
| npb | 新品 (New Product Boost) | 商品创建 < 31天 + 过去30天无单 |
| new_advv | 新广告主 | 广告创建 < 14天 + 老品 + 过去60天广告数 <= 1 |
| multi_item_cold_start | 多品冷启动 | 同 cold_start 逻辑，针对 pricing_type IN (24,25,27) |
| multi_item_empty_order | 多品空耗 | 同 empty_order 逻辑，针对 pricing_type IN (24,25,27) |
| multi_item_empty_order_expand | 多品空耗承接 | 同 empty_order_expand 逻辑，针对 pricing_type IN (24,25,27) |
| target_roas2.0 | 投放模式 (pricing_type=11) | pricing_type_tag workflow 写入 |
| simple2.0 | 投放模式 (pricing_type=15) | pricing_type_tag workflow 写入 |
| gms | 投放模式 (pricing_type=24) | pricing_type_tag workflow 写入 (BR only) |
| multi_product | 投放模式 (pricing_type=25) | pricing_type_tag workflow 写入 (BR only) |
| gms_simple | 投放模式 (pricing_type=27) | pricing_type_tag workflow 写入 (BR only) |

### 常见 WHERE 值 (Common Filter Values)

- **grass_region**: 'ID','MY','VN','TH','PH','SG','TW' (Asian 7 regions) / 'BR' (Brazil standalone)
- **business_tag**: 'npb', 'cold_start', 'empty_order_expand' — 选品/Reserve 最常见的三个标签组合
- **pricing_type**: 11, 15 — Product Ads 核心计费类型
- **grass_date**: `date_add(current_date, -1)` (workflow 内部) / `date('${BIZ_PRE_DAY}')` (下游引用)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| campaign_id | BIGINT | 广告计划 ID | - | - |
| pricing_type | INT | 计费类型 [PARTITION] | - | - |
| business_tag | STRING | 业务标签 [PARTITION] | - | - |
| grass_date | STRING | 日期分区 [PARTITION] | - | - |
| grass_region | STRING | 地区分区 [PARTITION] | - | - |
