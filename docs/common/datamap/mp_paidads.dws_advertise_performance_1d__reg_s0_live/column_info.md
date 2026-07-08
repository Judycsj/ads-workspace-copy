<!-- ads-workspace-gdoc-sync: gdoc_id=1_4Y-H_yaYFdr_ET_Dha9h5XTTO8d2kAJ6UH69K0Ei88 gdoc_url=https://docs.google.com/document/d/1_4Y-H_yaYFdr_ET_Dha9h5XTTO8d2kAJ6UH69K0Ei88/edit -->

# Columns: mp_paidads.dws_advertise_performance_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表粒度为 ads_id × placement × entrance × pricing_type × campaign_id × item_id × traffic_source，聚合到更粗粒度时直接 SUM 即可。但以下字段需注意：

- `new_boost` — 派生字段（CASE WHEN 计算），不可 SUM，需重新按条件判断
- `avg_ads_ranks` — 累加值为 location_in_ads 总和除以 impression_cnt 再 +1，跨行聚合时需回到 SUM(location_in_ads)/SUM(impression_cnt)+1
- `rapid_boost_toggle`, `is_ocpm` — boolean/flag，聚合时用 MAX
- `paid_order_cnt_ytd_1d`, `confirmed_order_cnt_ytd_1d` — 昨日口径，与当日 paid_order_cnt_1d 不可混用

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0 | Search Ads |
| placement | 2, 802, 1002, 1202 | Daily Discover |
| placement | 3 | Shop Ads |
| placement | 4 | Discovery Ads |
| placement | 5, 805, 1005, 1205 | You May Also Like |
| placement | 20, 2003 | Auto/Simple Shop Ads |
| placement | 44, 4400, 4401, 4402, 4405 | New Boost (when traffic_source=4) |
| placement | 1000, 1200 | Search (extended) |
| placement | 3327, 3328, 3337, 3338, 3339 | Video Ads (use raw_click_cnt) |
| pricing_type | 11 | Target ROI2 |
| pricing_type | 15 | Simple ROI2 |
| tz_type | 'local' | 本地时区 (ROI/效果分析常用) |
| tz_type | 'regional' | 区域时区 (OKR/Shop Ads 月度分析) |
| matched_premium_segment_value_id | 0 | general_audience |
| matched_premium_segment_value_id | 1 | view_in_shop |
| matched_premium_segment_value_id | 2 | cart_in_shop |
| matched_premium_segment_value_id | 3 | order_in_shop |
| matched_premium_segment_value_id | 4 | like_in_shop |
| matched_premium_segment_value_id | 10 | view_similar_item |
| new_boost | 1 | New Product Boost (placement in 44,4400-4405 AND traffic_source=4) |
| new_boost | 0 | Non-boost |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~60% 查询，ROI/效果分析) / 'regional' (~40%，OKR/月度/Shop Ads)
- `placement`: 0 (Search) / 3 (Shop Ads, 非常高频) / 4 (Discovery) / 全入口 (0,4,1000,2,802,1002,5,805,1005,1200,1202,1205)
- `pricing_type`: 11,15 (ROI2) — Boost 策略 / Campaign Surge
- `ads_id > 0` — 过滤无效广告
- `campaign_id > 0` — 过滤无效计划
- `expenditure_amt_usd_1d > 0` — 有消耗的广告
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')，部分查询含 MX

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | grass_date &#124; 日期分区 [PARTITION] | 2441/4039/6918 |  |
| 2 | grass_region | string | country partition [PARTITION] | 2398/3963/6766 |  |
| 3 | tz_type | string | timezone partition [PARTITION] | 2370/3851/6521 |  |
| 4 | expenditure_amt_local_1d | double | the total amount of ads deduction calculated in local currency within the past day &#124; 最近一天内以当地货币计算的广告扣减总额 | 1627/2417/4182 | 802.4681700000001 |
| 5 | shop_id | bigint | shop id &#124; 商店ID | 1213/1979/3664 | 1782542494 |
| 6 | order_cnt_1d | bigint | direct order cnt within the past day &#124; 过去一天的直接订单数量 | 1366/2018/3574 | 173 |
| 7 | placement | bigint | placement | 1576/2370/3542 | 3339 |
| 8 | expenditure_amt_usd_1d | double | the total amount of ads deduction calculated in USD within the past day &#124; 最近一天内以美元货币计算的广告扣减总额 | 1506/2276/3461 | 634.7385169072573 |
| 9 | impression_cnt_1d | bigint | the total number of ads impression within the past day ( deduplicated, may contain fraud) &#124; 近一天广告的曝光次数（去重，可能包含作弊流量） | 1293/1885/3227 | 64461 |
| 10 | click_cnt_1d | bigint | the total number of successful deducted clicks within the past day &#124; 近一天成功扣除的点击次数 | 1285/1840/3096 | 15245 |
| 11 | ads_gmv_amt_local_1d | double | The total GMV of direct orders calculated in local currency within the past day &#124; 过去一天内以当地货币计算的直接订单GMV总和 | 1244/1775/3081 | 36920.0 |
| 12 | broad_gmv_amt_usd_1d | double | sum gmv of broad ads orders in USD within the past day &#124; 近一天内美元货币计价的广泛广告订单总成交额 | 1376/2009/2877 | 30480.99663832312 |
| 13 | broad_order_cnt_1d | bigint | the total number of broad ads orders within the past day &#124; 近一天内广泛归因的订单量 | 1168/1699/2838 | 183 |
| 14 | broad_gmv_amt_local_1d | double | sum gmv of broad ads orders in local currency within the past day &#124; 近一天内本地货币计价的广泛广告订单总成交额 | 1160/1654/2720 | 38535.6 |
| 15 | ads_id | bigint | ads_id &#124; 广告ID | 1314/1870/2584 | 98463190 |
| 16 | ads_gmv_amt_usd_1d | double | The total GMV of direct orders calculated in USD within the past day &#124; 过去一天内以美元货币计算的直接订单GMV总和 | 1077/1458/2426 | 29203.084832904882 |
| 17 | ads_items_sold_cnt_1d | bigint | the total number of items sold in direct order within one day &#124; 一天内直接订单售出的商品总数 | 963/1209/1782 | 1630 |
| 18 | paid_order_cnt_ytd_1d | bigint | count of paid_order for yesterday &#124; 昨日已付款订单数量 | 886/1055/1452 | 20367 |
| 19 | confirmed_order_cnt_ytd_1d | bigint | count of confirm_order for yesterday &#124; 昨天确认订单数量 | 886/1055/1452 | NULL |
| 20 | entrance | bigint | entrance | 799/1179/1401 | 74 |

### 查询频率分析

Top 20 高频查询字段主要分为以下几个主题：

1. **分区字段**（排名 1-3）：`grass_date`、`grass_region`、`tz_type` 是最常用的过滤条件，几乎所有查询都会用到，L30D 查询量 6500-6900 次。

2. **花费与收入指标**（排名 4, 8, 11-12, 14, 16）：`expenditure_amt_local/usd_1d`（广告花费）和 `ads_gmv_amt_local/usd_1d`、`broad_gmv_amt_local/usd_1d`（直接/广泛 GMV）是核心 ROI 分析字段，L30D 查询量 2400-4200 次。

3. **流量指标**（排名 7, 9-10）：`placement`（广告位）、`impression_cnt_1d`（曝光）、`click_cnt_1d`（点击）用于流量漏斗分析，L30D 查询量 3000-3500 次。

4. **订单指标**（排名 6, 13, 17-19）：`order_cnt_1d`（直接订单）、`broad_order_cnt_1d`（广泛订单）、`ads_items_sold_cnt_1d`（商品销量）、`paid/confirmed_order_cnt_ytd_1d`（已付款/确认订单）覆盖多种归因口径。

5. **维度字段**（排名 5, 15, 20）：`shop_id`、`ads_id`、`entrance` 是常用的分组和关联维度。

整体使用模式显示该表主要用于**广告效果日报分析**，核心场景包括 ROI 计算（花费 vs GMV）、流量漏斗（曝光→点击→订单）、以及多归因口径对比（直接 vs 广泛）。

> MAX(column): MAX() aggregated values from grass_date=2026-03-25, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| ads_id | bigint | ads_id &#124; 广告ID | 1314/1870/2584 | 98463190 |
| placement | bigint | placement | 1576/2370/3542 | 3339 |
| ads_type | string | type include: 1. targeting:similar_product 2. keyword:search 3. targeting:daily_discover 4. keyword:simple_mode 5. targeting:ymal 6. targeting:simple_mode_ymal 7. targeting:simple_mode_sp 8. targeting:simple_mode_dd | 417/494/672 | targeting:ymal |
| shop_id | bigint | shop id &#124; 商店ID | 1213/1979/3664 | 1782542494 |
| seller_id | bigint | seller id &#124; 卖家ID | 417/494/672 | 8572049859 |
| impression_cnt_1d | bigint | the total number of ads impression within the past day ( deduplicated, may contain fraud) &#124; 近一天广告的曝光次数（去重，可能包含作弊流量） | 1293/1885/3227 | 64461 |
| click_cnt_1d | bigint | the total number of successful deducted clicks within the past day &#124; 近一天成功扣除的点击次数 | 1285/1840/3096 | 15245 |
| order_cnt_1d | bigint | direct order cnt within the past day &#124; 过去一天的直接订单数量 | 1366/2018/3574 | 173 |
| paid_order_cnt_ytd_1d | bigint | count of paid_order for yesterday &#124; 昨日已付款订单数量 | 886/1055/1452 | 20367 |
| confirmed_order_cnt_ytd_1d | bigint | count of confirm_order for yesterday &#124; 昨天确认订单数量 | 886/1055/1452 | NULL |
| ads_items_sold_cnt_1d | bigint | the total number of items sold in direct order within one day &#124; 一天内直接订单售出的商品总数 | 963/1209/1782 | 1630 |
| ads_gmv_amt_local_1d | double | The total GMV of direct orders calculated in local currency within the past day &#124; 过去一天内以当地货币计算的直接订单GMV总和 | 1244/1775/3081 | 36920.0 |
| ads_gmv_amt_usd_1d | double | The total GMV of direct orders calculated in USD within the past day &#124; 过去一天内以美元货币计算的直接订单GMV总和 | 1077/1458/2426 | 29203.084832904882 |
| expenditure_amt_local_1d | double | the total amount of ads deduction calculated in local currency within the past day &#124; 最近一天内以当地货币计算的广告扣减总额 | 1627/2417/4182 | 802.4681700000001 |
| expenditure_amt_usd_1d | double | the total amount of ads deduction calculated in USD within the past day &#124; 最近一天内以美元货币计算的广告扣减总额 | 1506/2276/3461 | 634.7385169072573 |
| entrance | bigint | entrance | 799/1179/1401 | 74 |
| broad_gmv_amt_local_1d | double | sum gmv of broad ads orders in local currency within the past day &#124; 近一天内本地货币计价的广泛广告订单总成交额 | 1160/1654/2720 | 38535.6 |
| broad_gmv_amt_usd_1d | double | sum gmv of broad ads orders in USD within the past day &#124; 近一天内美元货币计价的广泛广告订单总成交额 | 1376/2009/2877 | 30480.99663832312 |
| avg_ads_ranks | bigint | Indicates the average rank of advertisements calculated based on their location in ads relative to impression counts. &#124; 根据广告在展示次数中的位置计算出的平均广告排名 | 462/547/752 | 92503 |
| broad_shop_item_click_cnt_1d | bigint | count of broad shop item clicks within the past day &#124; 近一天内广泛订单商品点击次数统计 | 462/547/752 | 1981 |
| broad_shop_item_impression_cnt_1d | bigint | count of broad shop item imprs within the past day &#124; 近一天内广泛订单商品曝光次数统计 | 462/547/752 | 253294 |
| broad_order_item_cnt_1d | bigint | count of items sold in broad ads order. &#124; 广泛归因订单下商品销售量 refer to https://confluence.shopee.io/x/XjJ0CQ | 462/547/752 | 1630 |
| broad_order_cnt_1d | bigint | the total number of broad ads orders within the past day &#124; 近一天内广泛归因的订单量 | 1168/1699/2838 | 183 |
| direct_shop_item_impression_cnt_1d | bigint | count of direct shop item imprs one day &#124; 一天内直接订单商店商品曝光数量统计 | 462/547/752 | 102701 |
| direct_shop_item_click_cnt_1d | bigint | count of direct shop item clicks one day | 462/547/752 | 252 |
| paid_order_cnt_1d | bigint | count of a one day's ads orders that paid in 30 days &#124; 统计一天内收到的、30天内付款的广告订单数量 | 462/547/752 | 18693 |
| confirmed_order_cnt_1d | bigint | count of a one day's ads orders when paid or confirmed in 30 days &#124; 统计一天内（付款或确认后30天内有效）广告订单数 | 462/547/752 | NULL |
| checkout_cnt_1d | bigint | "Checkout" is calculated by count distinct orderid, where any item within the order has a broad ad click in l7d. | 462/547/752 | 177 |
| direct_add_to_cart_cnt_1d | bigint | sum of a one day's add_to_cart | 462/547/752 | 283 |
| add_to_cart_without_clicks_cnt_1d | bigint | This column shows the total number of 'add to cart' actions without any clicks in a single day &#124; 一天内未进行任何点击的"添加到购物车"操作总数 | 462/547/752 | 99 |
| broad_add_to_cart_cnt_1d | bigint | This column represents the sum of the broad add-to-cart counts accumulated in the past day &#124; 近一天所有类别商品加入购物车次数的总和 | 462/547/752 | 314 |
| view_cnt_1d | bigint | This column captures the sum of views recorded in a single day &#124; 近一天的view总量 | 462/547/752 | 55712 |
| product_click_cnt_1d | bigint | deduplication of video ad product clicks in the past day &#124; 近一天视频广告产品点击去重数 | 462/547/752 | 1611 |
| new_boost | bigint | if it belongs to new product boost (derived: placement in 44,4400,4401,4402,4405 AND traffic_source=4) | 792/1165/1370 | 0 |
| pricing_type | bigint | pricing type of ads | 609/721/975 | 29 |
| campaign_id | bigint | campaign_id &#124; 活动ID | 356/594/1156 | 53361010 |
| item_id | bigint | ads item_id &#124; 广告_商品_id | 192/371/773 | 58157656489 |
| traffic_source | int | traffic_source (org, roi1, roi2 etc.) | -/-/2 | 6 |
| video_play_complete | bigint | count of completed video views &#124; 已完成视频观看次数 | 462/547/752 | 372 |
| video_play_3s_cnt | bigint | This column indicates the count of videos that were played for more than 3 seconds &#124; 显示播放时间超过 3 秒的视频数量。 | 462/547/752 | 331910 |
| video_play_5s_cnt | bigint | count of the video that was played for more than 5s &#124; 播放时长超过 5 秒的视频数量 | 462/547/752 | 328604 |
| video_view | bigint | video_view | 462/547/752 | 2881 |
| view_duration | bigint | Video playback duration, in milliseconds | 462/547/752 | 9714755816 |
| deduplicated_click_cnt | bigint | the count of deduplicated clicks &#124; 去重后的点击次数 | 462/547/752 | 13777 |
| cps_dedup_click_cnt | bigint | This column tracks the count of deduplicated clicks as determined by the cost-per-sale (CPS) model &#124; 近一天cps模型的去重点击数 | 588/799/1292 | NULL |
| deduct_order_cnt | bigint | the count of order that deducted by cps &#124; cps 扣除的订单数量 | 462/547/752 | 0 |
| expense_rebate_free_credit_without_expiry | decimal(25,10) | it records auto rebate-based free credit provided by the platform without an expiry date. &#124; 一个用于标记平台自动返利（auto rebate）所产生的 "无过期时间的免费广告金" 的字段 | 462/547/752 | 229.3319 |
| imp_attr_paid_order_cnt | bigint | Count of broad paid orders that don't have ads click but has ads impression (broad imp-attributed non-agent order & hits shop_exp_tag) | 462/547/752 | 47 |
| imp_attr_paid_order_item_sold_cnt | bigint | Count of broad paid order items that don't have ads click but has ads impression (broad imp-attributed non-agent order & hits shop_exp_tag) | 462/547/752 | 536 |
| imp_attr_paid_order_gmv | double | Sum of broad paid order gmv in local concurrency that don't have ads click but has ads impression (broad imp-attributed non-agent order & hits shop_exp_tag) | 462/547/752 | 23662.0 |
| imp_attr_paid_order_gmv_usd | double | Sum of broad paid order gmv in usd concurrency that don't have ads click but has ads impression (broad imp-attributed non-agent order & hits shop_exp_tag) | 462/547/752 | 18716.23492190001 |
| paid_order_item_sold_cnt | bigint | Count of direct paid orders. Broad paid order is when a user click into an item with ads and then pay for the items within last 7 days. | 462/547/752 | 1768 |
| paid_broad_order_cnt | bigint | Count of broad paid orders. Broad paid order is when a user click into an item with ads and then pay for the items within the same shop within last 7 days. | 606/836/1365 | 175 |
| paid_broad_order_gmv | double | Sum of broad paid order gmv in local concurrency. Broad paid order is when a user click into an item with ads and then pay for the items within the same shop within last 7 days. | 606/836/1365 | 38175.0 |
| paid_broad_order_item_sold_cnt | bigint | Count of broad paid order items. Broad paid order is when a user click into an item with ads and then pay for the items within the same shop within last 7 days. | 462/547/752 | 1768 |
| paid_broad_order_gmv_usd | double | Sum of broad paid order gmv in usd concurrency. Broad paid order is when a user click into an item with ads and then pay for the items within the same shop within last 7 days. | 525/673/1022 | 30195.768241900016 |
| paid_checkout_cnt | bigint | "Checkout" is calculated by count distinct paid orderid, where any item within the order has a broad ad click in l7d. | 462/547/752 | 174 |
| paid_agent_checkout_cnt | bigint | - | 462/547/752 | 27 |
| paid_no_click_order_item_sold_cnt | bigint | - | 462/547/752 | 120 |
| paid_no_click_order_gmv | double | - | 462/547/752 | 558.83 |
| paid_no_click_order_cnt | bigint | - | 462/547/752 | 18 |
| paid_no_click_order_gmv_usd | double | - | 462/547/752 | 442.024916 |
| no_click_gmv_usd | double | - | 462/547/752 | 798.1016413 |
| rapid_boost_toggle | - | Whether rapid boost toggle is on for this ad (MAX aggregation) | -/-/- | - |
| is_ocpm | - | Whether this ad uses oCPM pricing (MAX aggregation; when true, click_cnt uses deduplicated_click) | -/-/- | - |
| deduct_impression | - | Deducted impression count (SUM aggregation) | -/-/- | - |
| tz_type | string | timezone partition [PARTITION] | 2370/3851/6521 |  |
| grass_region | string | country partition [PARTITION] | 2398/3963/6766 |  |
| grass_date | date | grass_date &#124; 日期分区 [PARTITION] | 2441/4039/6918 |  |
