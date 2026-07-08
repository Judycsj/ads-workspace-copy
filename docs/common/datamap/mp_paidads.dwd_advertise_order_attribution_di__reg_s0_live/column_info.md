<!-- ads-workspace-gdoc-sync: gdoc_id=1kRXdvETAoEtLq1opEi50fJ3bqg8btYP_JV7Zub_mkLI gdoc_url=https://docs.google.com/document/d/1kRXdvETAoEtLq1opEi50fJ3bqg8btYP_JV7Zub_mkLI/edit -->

# Columns: mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表粒度为 daily x request/order 级别，以下指标按 request_id + ads_id + item_id + event_timestamp 去重后聚合时需要 MAX：
- `ads_gmv_amt_local`, `ads_gmv_amt_usd`, `broad_order_gmv_amt_local`, `broad_order_gmv_amt_usd`
- `order_cnt`, `paid_order_cnt`, `confirmed_order_cnt`, `daily_order_cnt`
- `ads_items_sold_cnt`, `broad_order_cnt`, `broad_order_item_cnt`
- `broad_shopitem_click_cnt`, `broad_shopitem_impression_cnt`

数据质量校验场景中统一使用 `MAX(COALESCE(col, 0))` 去重后对比。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| matched_premium_segment_value_id | 0 | buyer_segment_behaviour_general_audience |
| matched_premium_segment_value_id | 1 | buyer_segment_behaviour_view_in_shop |
| matched_premium_segment_value_id | 2 | buyer_segment_behaviour_cart_in_shop |
| matched_premium_segment_value_id | 3 | buyer_segment_behaviour_order_in_shop |
| matched_premium_segment_value_id | 4 | buyer_segment_behaviour_like_in_shop |
| matched_premium_segment_value_id | 10 | buyer_segment_behaviour_view_similar_item |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (所有查询均用 local)
- `grass_region`: 标准 8 区 + 美洲 ('SG','MY','PH','ID','TH','TW','VN','BR','MX','CO','CL')
- `grass_date`: date('{bizdate}') 或 >= date('{bizdate}') - interval '1' day
- `order_id`: IS NOT NULL (用于过滤有订单的归因记录)
- `paid_datetime IS NOT NULL OR confirmed_datetime IS NOT NULL`: 常用于筛选有实际转化的订单
- `placement`: 40 (ROI2/Search Ads), 0/3/4/1000/1200 (关键词广告)
- `entrance`: >0 (排除未知入口)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| order_id | BIGINT | order_id | - | - |
| request_id | STRING | request_id | - | - |
| query | STRING | 搜索 query | - | - |
| keywords | STRING | 关键词 | - | - |
| ads_id | BIGINT | 广告 ID | - | - |
| shop_id | BIGINT | 店铺 ID | - | - |
| item_id | BIGINT | 商品 ID | - | - |
| placement | BIGINT | 广告位 | - | - |
| click_timestamp | BIGINT | 点击时间戳 (unixtime) | - | - |
| click_datetime | STRING | 点击时间 (yyyy-MM-dd HH:mm:ss) | - | - |
| event_timestamp | BIGINT | 事件时间戳 (unixtime) | - | - |
| event_datetime | STRING | 事件时间 (yyyy-MM-dd HH:mm:ss) | - | - |
| paid_timestamp | BIGINT | 支付时间戳 (unixtime) | - | - |
| paid_datetime | STRING | 支付时间 (yyyy-MM-dd HH:mm:ss) | - | - |
| confirmed_timestamp | BIGINT | 确认时间戳 (unixtime) | - | - |
| confirmed_datetime | STRING | 确认时间 (yyyy-MM-dd HH:mm:ss) | - | - |
| pricing_type | INT | 出价类型 | - | - |
| daily_order_cnt | BIGINT | 当日订单数 | - | - |
| order_cnt | BIGINT | 订单数 | - | - |
| paid_order_cnt | BIGINT | 支付订单数 | - | - |
| confirmed_order_cnt | BIGINT | 确认订单数 | - | - |
| ads_gmv_amt_local | DOUBLE | 广告直接订单 GMV (本币) | - | - |
| ads_gmv_amt_usd | DOUBLE | 广告直接订单 GMV (USD) | - | - |
| ads_items_sold_cnt | BIGINT | 广告售出商品数 | - | - |
| broad_order_cnt | BIGINT | 泛订单数 | - | - |
| broad_order_gmv_amt_local | DOUBLE | 泛订单 GMV (本币) | - | - |
| broad_order_gmv_amt_usd | DOUBLE | 泛订单 GMV (USD) | - | - |
| broad_order_item_cnt | BIGINT | 泛订单商品数 | - | - |
| broad_shopitem_click_cnt | BIGINT | 泛店铺商品点击数 | - | - |
| broad_shopitem_impression_cnt | BIGINT | 泛店铺商品曝光数 | - | - |
| match_type | BIGINT | 关键词匹配类型 | - | - |
| matched_premium_segment_value_id | STRING | 匹配的 premium segment value ID (枚举: 0/1/2/3/4/10) | - | - |
| entrance | BIGINT | 入口 | - | - |
| tz_type | STRING [PARTITION] | 时区类型 | - | - |
| grass_region | STRING [PARTITION] | 国家/区域 | - | - |
| grass_date | DATE [PARTITION] | 数据日期 | - | - |
