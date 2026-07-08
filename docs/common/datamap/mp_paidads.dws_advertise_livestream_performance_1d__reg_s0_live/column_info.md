<!-- ads-workspace-gdoc-sync: gdoc_id=1SInNyJcYJ2DWAWik1qdLrVhtfRUeeCDECaP7gbSEqd8 gdoc_url=https://docs.google.com/document/d/1SInNyJcYJ2DWAWik1qdLrVhtfRUeeCDECaP7gbSEqd8/edit -->

# Columns: mp_paidads.dws_advertise_livestream_performance_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `effective_view_cnt` -- 上游由 `COUNT(DISTINCT ...)` 计算，跨 ads_id/streamer 等维度聚合时不可直接 SUM，需使用 `SUM(DISTINCT)` 或在最细粒度先 COUNT DISTINCT
- `account_id` -- 上游由 `MAX(account_id)` 聚合产出，非累加
- `target_affiliate_id` -- 上游由 `MAX(target_affiliate_id)` 聚合产出，非累加
- `paid_order_ytd_cnt` / `confirmed_order_ytd_cnt` -- 来自不同日期窗口的聚合（T-2 to T-1 for regional, T-1 for local），跨日期聚合时不可直接 SUM

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 9,10,14,19 | Live Ads / CBO (直播广告出价类型) |
| pricing_type | 11,15 | Auto/ANTO (自动投放) -- 不在此表，在 dwd 层过滤 |
| tz_type | local | 本地时区 |
| tz_type | regional | 区域时区 (UTC+8) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (绝大多数下游消费者) / 'regional' (部分场景)
- `grass_date`: 单日查询用 `grass_date = DATE('${grass_date}')`; 7 日滚动用 `grass_date BETWEEN (...) - INTERVAL 6 DAYS AND ...`
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN') + 'BR'，用 `upper('${region}')`
- `target_affiliate_id IS NOT NULL` -- 在 ads_advertise_livestream_metrics 中用于过滤 affiliate 广告

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告 ID | - | - |
| placement | int | 广告位 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| pricing_type | int | 出价类型 | - | - |
| campaign_id | bigint | 计划 ID | - | - |
| entrance | int | 入口类型 | - | - |
| item_id | bigint | 商品 ID (local 时区下为 null) | - | - |
| target_affiliate_id | bigint | 联盟目标 ID | - | - |
| impression_cnt | bigint | 曝光数 | - | - |
| deduct_impression_cnt | bigint | 扣量曝光数 | - | - |
| non_fraud_impression_cnt | bigint | 非作弊曝光数 | - | - |
| click_cnt | bigint | 点击数 | - | - |
| order_cnt | bigint | 订单数 | - | - |
| ads_items_sold_cnt | bigint | 广告商品售出件数 | - | - |
| ads_gmv_amt | double | 广告 GMV (本币) | - | - |
| ads_gmv_amt_usd | double | 广告 GMV (USD) | - | - |
| broad_ads_gmv_amt | double | 宽口径广告 GMV (本币) | - | - |
| broad_ads_gmv_amt_usd | double | 宽口径广告 GMV (USD) | - | - |
| broad_order_cnt | bigint | 宽口径订单数 | - | - |
| paid_order_cnt | bigint | 已支付订单数 | - | - |
| confirmed_order_cnt | bigint | 已确认订单数 | - | - |
| checkout_cnt | bigint | 结算数 | - | - |
| add_to_cart_cnt | bigint | 加购数 | - | - |
| view_cnt | bigint | 观看数 | - | - |
| product_click_cnt | bigint | 商品点击数 | - | - |
| ads_expenditure | double | 广告消耗 (本币) | - | - |
| ads_expenditure_usd | double | 广告消耗 (USD) | - | - |
| paid_order_ytd_cnt | bigint | YTD 已支付订单数 | - | - |
| confirmed_order_ytd_cnt | bigint | YTD 已确认订单数 | - | - |
| broad_item_sold_cnt | bigint | 宽口径售出商品数 | - | - |
| sub_entrance | bigint | 子入口类型 | - | - |
| streamer_id | bigint | 主播 ID | - | - |
| streamer_type | int | 主播类型 (来自 livestream.ls_mart_dim_streamer) | - | - |
| ads_expenditure_vat_local | double | 广告消耗含 VAT (本币) | - | - |
| ads_expenditure_vat_usd | double | 广告消耗含 VAT (USD) | - | - |
| effective_view_cnt | bigint | 有效观看数 (去重, 非累加) | - | - |
| account_id | bigint | 账户 ID | - | - |
| view_duration | bigint | 观看时长 | - | - |
