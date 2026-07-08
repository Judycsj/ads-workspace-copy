<!-- ads-workspace-gdoc-sync: gdoc_id=1d7_8IPuBhSN1Ah8ksnOt_kL9kevplAD-I8yw89FIXWU gdoc_url=https://docs.google.com/document/d/1d7_8IPuBhSN1Ah8ksnOt_kL9kevplAD-I8yw89FIXWU/edit -->

# Columns: mp_paidads.dws_shop_performance_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段不可直接 SUM 聚合，需特殊处理：

- `take_rate_mtd` — 比率字段 (ads_expense_mtd / shop_total_gmv_mtd)，不可 SUM，需用分子分母分别求和后重新计算
- `sku_with_ads_expense_ratio_mtd` — 比率字段 (sku_with_ads_expense_mtd / active_item_cnt)，不可 SUM
- `active_item_cnt` — 来自 dws_shop_listing_td 快照，跨日期聚合时不可直接 SUM（应取 MAX 或最新值）
- `total_order_cnt` — 生产逻辑中为 COUNT(DISTINCT order_id)，跨 shop 聚合可直接 SUM，但跨日期聚合需注意去重

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 生产查询，此表仅写入 tz_type='local')
- `grass_region`: 标准 11 区 ('ID','MY','PH','SG','TH','TW','VN','BR','CO','CL','MX')
- `shop_id is not null`: CRM 报表中普遍使用的过滤条件

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | 店铺ID | - | - |
| total_order_cnt | bigint | 全店下单数 (COUNT DISTINCT order_id) | - | - |
| total_gmv | decimal(38,10) | 全店GMV (seller_gmv) | - | - |
| checkout_cnt | bigint | 广告结算商品数 | - | - |
| direct_ads_order | bigint | 直接广告订单数 | - | - |
| direct_ads_gmv | decimal(38,10) | 直接广告GMV (ads_order_gmv_local) | - | - |
| broad_ads_order | bigint | 泛广告订单数 | - | - |
| broad_ads_gmv | decimal(38,10) | 泛广告GMV (broad_gmv_amt_local) | - | - |
| ads_expense | decimal(38,10) | 广告总消耗 (= expenditure_amt_local + display_ads_expense) | - | - |
| ads_expense_mtd | decimal(38,10) | 月初至今广告总消耗 | - | - |
| take_rate_mtd | decimal(38,10) | 月初至今广告Take Rate (= ads_expense_mtd / shop_total_gmv_mtd) | - | - |
| sku_with_ads_expense_mtd | bigint | 月初至今有广告消耗的SKU数 | - | - |
| sku_with_ads_expense_ratio_mtd | decimal(38,10) | 有广告消耗SKU占比 (= sku_with_ads_expense_mtd / active_item_cnt) | - | - |
| sku_with_ads_expense_search_mtd | bigint | 月初至今搜索广告(Shopping Ads)有消耗SKU数 | - | - |
| sku_with_ads_expense_discovery_mtd | bigint | 月初至今发现广告(Discovery Ads)有消耗SKU数 | - | - |
| shop_total_gmv_mtd | decimal(38,10) | 月初至今全店GMV | - | - |
| active_item_cnt | bigint | 活跃商品数 (来自 dws_shop_listing_td 快照) | - | - |

*注: Description / Query Frequency / MAX 采样值需运行 --source from-di 补充*
