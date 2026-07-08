<!-- ads-workspace-gdoc-sync: gdoc_id=1XA7ND0Xslj2oyQiveSbb2BgEoT94u_fm9s-ImUS4pIg gdoc_url=https://docs.google.com/document/d/1XA7ND0Xslj2oyQiveSbb2BgEoT94u_fm9s-ImUS4pIg/edit -->

# Columns: mp_paidads.dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表粒度为用户 x common_feature 级别，在当前粒度上各指标可直接 SUM。但在跨 common_feature 聚合场景（如 AB 实验 label 提取）中，部分指标需注意：

- `omni_order_cnt`, `omni_gmv`, `omni_gmv_usd`, `omni_item_sold_cnt`: 当在同一 (user, item) 级别存在多条 common_feature 行时，需用 MAX() 取值，避免跨 feature 重复加总
- `ads_revenue`, `ads_revenue_usd`: 同一 user x item 在多个 feature 下均有广告曝光时，收入可能重复，跨 feature 聚合时需去重或使用 feature='Platform' 行

### 枚举值映射 (Value Mappings)

> 来源：生产逻辑中的 CASE-WHEN 映射（写入文件），多个地区分区文件均确认

**common_feature 取值映射**:

| Value | Source Feature/Module | Description |
|-------|----------------------|-------------|
| Platform | Aggregated (all features) | 全部推荐场景的汇总视图 |
| Search Shop | Search + shop items | 搜索店铺商品推荐 |
| Global Search | module='Global Search' | 全局搜索 |
| Image Search | module='Image Search' | 图片搜索 |
| You May Also Like | feature_group='You May Also Like' | 猜你喜欢 |
| Live Streaming | feature_group='Live Streaming' | 直播推荐 |
| Order Successful Recommendation | feature_group='Order Successful Recommendation' | 下单成功推荐 |
| Cart Recommendation | feature_group='Cart Recommendation' | 购物车推荐 |
| My Purchase Page Recommendation | feature='mpp_ymal-order_list' | 我的购买页推荐 |
| Order Detail Page Recommendation | feature='odp_ymal-order_detail' | 订单详情页推荐 |
| Daily Discover | module='Daily Discover' | 每日发现 |
| Games | feature_group='Games' | 游戏 |
| Video | feature_group='Video' | 视频推荐 |
| Video YMAL | feature_group='Video' + video_property.is_ymal_item=1 | 视频猜你喜欢 |
| Me YMAL | feature_detail='me-you_may_also_like-item' | 我的页猜你喜欢 |
| Voucher Landing Recommendation | feature='voucher-voucher_landing' | 优惠券入口页推荐 |
| Hot Deals Landing Recommendation | feature='crm_omni_attri-hot_deals_landing' | 热卖入口页推荐 |
| Shop YMAL | feature_detail='shop-you_may_also_like-item' | 店铺页推荐 |
| Shipping Info Page YMAL | feature_detail='order_shipping_info-you_may_also_like-item' | 物流信息页推荐 |
| Others | (catch-all) | 未被任一规则匹配的特征 |

**Item Type Flag 取值映射**（均为 0/1）:

| Column | Value=1 条件 | Description |
|--------|-------------|-------------|
| if_roi1_item | pricing_type IN (1,2,3,4,7,8) | ROI1 商品（有 ROI1 广告曝光） |
| if_roi2_item | placement IN (40) | ROI2 商品（有 ROI2 广告曝光） |
| if_new_product_boost | pricing_type IN (13) OR new_product_boost_stage IN (1,2) | NPB 商品 |
| if_simple2_item | pricing_type IN (15) | Simple ROI2 商品 |
| if_ads_item | ads_impr_cnt > 0 | 有广告曝光的商品 |

### 常见 WHERE 值 (Common Filter Values)

- **tz_type**: `'local'` -- 几乎所有查询均使用此条件
- **grass_region**: `'ID','MY','PH','SG','TH','TW','VN'` (7 个 QQ 市场，最常见) / `'BR'` (巴西市场，单独分析)
- **common_feature**: `'Platform'` -- 全平台汇总视角，最常用；`common_feature <> 'Others'` -- 排除未分类特征（噪音过滤）
- **user_id**: `user_id > 0` -- 排除匿名用户
- **item_id**: `item_id > 0` -- 有效商品过滤
- **shop_id**: `shop_id IS NOT NULL` -- 有效店铺过滤

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | date of ads performance [PARTITION] | 699/1409/3339 |  |
| 2 | grass_region | string | region of ads performance [PARTITION] | 692/1395/3309 |  |
| 3 | common_feature | string | common_feature | 635/1289/3091 | You May Also Like |
| 4 | user_id | bigint | user_id | 483/974/2367 | 8589745007 |
| 5 | ads_revenue_usd | decimal(25,10) | the cost amount in usd currency that we deducted from translog. from mp_paidads.dwd_advertise_performance_di.expenditure_amt_local/exchange_rate | 470/949/2281 | 35.7460945224 |
| 6 | tz_type | string | timezone [PARTITION] | 310/652/1449 |  |
| 7 | if_ads_item | int | if the item has ad impressions | 155/318/697 | 1 |
| 8 | omni_gmv_usd | decimal(25,10) | omni_gmv,  expressed in USD. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 151/284/634 | 8620.8503065058 |
| 9 | omni_order_cnt | decimal(25,10) | the total order value or count across all traffic sources (both ads and organic). from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 144/277/627 | 16.0 |
| 10 | item_id | bigint | item_id | 132/260/590 | 58157920841 |
| 11 | ads_direct_order_cnt | bigint | total number of order_cnt, from mp_paidads.dwd_advertise_performance_di | 98/189/407 | 22 |
| 12 | ads_gmv_usd | decimal(25,10) | direct order gmv in usd currency on query level., from mp_paidads.dwd_advertise_performance_di.ads_order_gmv_local | 98/189/407 | 3599.5649594621 |
| 13 | ads_broad_order_cnt | bigint | total number of broad_order_cnt, from mp_paidads.dwd_advertise_performance_di | 91/175/375 | 24 |
| 14 | ads_broad_gmv_usd | decimal(25,10) | broad order gmv in usd currency on query level., from mp_paidads.dwd_advertise_performance_di.broad_gmv_amt_local | 91/175/375 | 3599.5649594621 |
| 15 | omni_item_impr_ads_cnt | bigint | omni_item_impr_ads_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 1424 |
| 16 | omni_item_impr_cnt | bigint | omni_item_impr_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 4793 |
| 17 | omni_item_click_ads_cnt | bigint | omni_item_click_ads_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 54 |
| 18 | omni_item_click_cnt | bigint | omni_item_click_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 343 |
| 19 | omni_ads_order_cnt | decimal(25,10) | the total order value or count attributed to users who came through advertisements. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 60/109/260 | 6.0 |
| 20 | omni_ads_gmv_usd | decimal(25,10) | omni_ads_gmv,  expressed in USD. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 60/109/260 | 3365.6317975084 |

### 查询频率分析

Top 20 高频查询字段呈现以下主题分布：

1. **分区键**（3 个）：`grass_date`、`grass_region`、`tz_type` 占据 Top 6 中的 3 席，是几乎所有查询的必选过滤条件。
2. **维度键**（3 个）：`common_feature`（推荐场景）、`user_id`、`item_id` 为核心分析粒度，支撑用户级和商品级的效果评估。
3. **广告收入与 GMV（USD）**（4 个）：`ads_revenue_usd`（L30D=2281，最高非分区字段）、`ads_gmv_usd`、`ads_broad_gmv_usd`、`omni_gmv_usd` 是 ROI/ROAS 计算的核心度量。
4. **订单量**（3 个）：`ads_direct_order_cnt`、`ads_broad_order_cnt`、`omni_order_cnt`，用于转化率和订单归因分析。
5. **Omni 流量与转化**（5 个）：`omni_item_impr_ads_cnt/cnt`、`omni_item_click_ads_cnt/cnt`、`omni_ads_order_cnt`、`omni_ads_gmv_usd`，反映全渠道归因分析是该表的重要使用场景。
6. **广告标记**（1 个）：`if_ads_item` 用于区分广告/自然流量商品。

**使用模式总结**：该表主要服务于 common_feature（推荐场景）粒度下的广告效果分析，高频查询集中在 USD 口径的收入、GMV、订单量指标，以及 Omni（全渠道归因）维度的流量和转化指标。广告侧指标（`ads_*`）和全渠道指标（`omni_*`）的查询频率差距不大，说明用户同时关注广告直接归因和全渠道归因视角。

> MAX(column): MAX() aggregated values from grass_date=2026-03-29, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| user_id | bigint | user_id | 483/974/2367 | 8589745007 |
| common_feature | string | common_feature | 635/1289/3091 | You May Also Like |
| app_version | string | app_version | -/-/1 | v1.0.0-sw_WEBFE_MKP_2026_03_v4_1_1_r18 |
| item_id | bigint | item_id | 132/260/590 | 58157920841 |
| location | bigint | location | -/-/1 | 4965 |
| if_ads_item | int | if the item has ad impressions | 155/318/697 | 1 |
| ads_impr_cnt | bigint | total number of impressions from ads item, from mp_paidads.dwd_advertise_performance_di.impression_cnt | -/-/1 | 409 |
| ads_click_cnt | bigint | total number of raw_click from mp_paidads.dwd_advertise_performance_di | -/-/1 | 75 |
| ads_direct_order_cnt | bigint | total number of order_cnt, from mp_paidads.dwd_advertise_performance_di | 98/189/407 | 22 |
| ads_broad_order_cnt | bigint | total number of broad_order_cnt, from mp_paidads.dwd_advertise_performance_di | 91/175/375 | 24 |
| ads_direct_gmv | decimal(25,10) | total gmv from direct order, from mp_paidads.dwd_advertise_performance_di.ads_order_gmv_local | -/-/1 | 4550.75 |
| ads_broad_gmv | decimal(25,10) | total gmv from broad order, from mp_paidads.dwd_advertise_performance_di.broad_gmv_amt_local | -/-/1 | 4550.75 |
| ads_revenue | decimal(25,10) | the cost amount in local currency that we deducted from translog, from mp_paidads.dwd_advertise_performance_di.expenditure_amt_local | -/-/1 | 45.192 |
| ads_gmv_usd | decimal(25,10) | direct order gmv in usd currency on query level., from mp_paidads.dwd_advertise_performance_di.ads_order_gmv_local | 98/189/407 | 3599.5649594621 |
| ads_broad_gmv_usd | decimal(25,10) | broad order gmv in usd currency on query level., from mp_paidads.dwd_advertise_performance_di.broad_gmv_amt_local | 91/175/375 | 3599.5649594621 |
| ads_revenue_usd | decimal(25,10) | the cost amount in usd currency that we deducted from translog. from mp_paidads.dwd_advertise_performance_di.expenditure_amt_local/exchange_rate | 470/949/2281 | 35.7460945224 |
| ads_gmv_200_cap_usd | decimal(25,10) | if ads_order_gmv_local/exchange_rate > 200, then 200 else ads_order_gmv_local/exchange_rate | -/-/1 | 640.5853272691 |
| ads_gmv_500_cap_usd | decimal(25,10) | if ads_order_gmv_local/exchange_rate > 500 then 500 else ads_order_gmv_local/exchange_rate end | -/-/1 | 1500.0 |
| ads_broad_gmv_200_cap_usd | decimal(25,10) | if broad_gmv_amt_local/exchange_rate > 200 then 200 else broad_gmv_amt_local/exchange_rate end | -/-/1 | 669.8358710698 |
| ads_broad_gmv_500_cap_usd | decimal(25,10) | if broad_gmv_amt_local/exchange_rate > 500 then 500 else broad_gmv_amt_local/exchange_rate end | -/-/1 | 1500.0 |
| ads_atc_cnt | bigint | the sum of add_to_cart_cnt and add_to_cart_without_clicks_cnt, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 51 |
| ads_commision_fee | decimal(25,10) | The fee charged as a commission for the sale of the item from the ads, from mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live | -/-/1 | 3231.21 |
| ads_commision_fee_usd | decimal(25,10) | ads_commision_fee expressed in USD | -/-/1 | 2555.8315222473 |
| ads_deduction_click_cnt | bigint | the sum of click_cnt, from mp_paidads.dwd_advertise_performance_di | -/-/1 | 21 |
| ads_deduction_impression_cnt | bigint | the sum of deduct_impression, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 754 |
| ads_live_view_cnt | bigint | the sum of view, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 551 |
| ads_live_view_duration | bigint | the sum of view_duration, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 30336273 |
| ads_live_item_click_cnt | bigint | the sum of product_click, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 153 |
| ads_broad_item_sold_cnt | bigint | the sum of broad_item_cnt, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 878 |
| ads_direct_item_sold_cnt | bigint | the sum of ads_item_sold_cnt, from mp_paidads.dwd_advertise_performance_di. | -/-/1 | 878 |
| omni_entry_impr_ads_cnt | bigint | the sum of impression from ads, from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live. | -/-/1 | 409 |
| omni_entry_impr_organic_cnt | bigint | the sum of impression from organic, from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live. | -/-/1 | 3940 |
| omni_entry_impr_cnt | bigint | the sum of impression ,  from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live. | -/-/1 | 3972 |
| omni_entry_click_ads_cnt | bigint | sum of clicks from ads , from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live. | -/-/1 | 75 |
| omni_entry_click_organic_cnt | bigint | sum of clicks from organic, from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live. | -/-/1 | 139 |
| omni_entry_click_cnt | bigint | sum of clicks, from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live. | -/-/1 | 139 |
| omni_item_impr_ads_cnt | bigint | omni_item_impr_ads_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 1424 |
| omni_item_impr_organic_cnt | bigint | omni_item_impr_organic_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | -/-/1 | 4793 |
| omni_item_impr_cnt | bigint | omni_item_impr_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 4793 |
| omni_item_click_ads_cnt | bigint | omni_item_click_ads_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 54 |
| omni_item_click_organic_cnt | bigint | omni_item_click_organic_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | -/-/1 | 343 |
| omni_item_click_cnt | bigint | omni_item_click_cnt, from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live | 60/109/260 | 343 |
| omni_ads_ppv_cnt | bigint | the count of product page views that are associated with advertisements, from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live | -/-/1 | 28 |
| omni_organic_ppv_cnt | bigint | the count of product page views that are not associated with advertisements,  from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live | -/-/1 | 113 |
| omni_ppv_cnt | bigint | the total count of product page views , from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live | -/-/1 | 113 |
| omni_ads_atc_cnt | bigint | the count of successful add-to-cart actions that are associated with advertisements across various channels, from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live | -/-/1 | 50 |
| omni_organic_atc_cnt | bigint | the count of successful add-to-cart actions that are not associated with advertisements. from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live | -/-/1 | 60 |
| omni_atc_cnt | bigint | the count of successful add-to-cart actions. from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live | -/-/1 | 60 |
| omni_stay_time | bigint | the total time spent on product pages by users. from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live | -/-/1 | 7180516 |
| omni_ads_stay_time | bigint | the total time spent on product pages by users who arrived via advertisements. from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live | -/-/1 | 7263665 |
| omni_organic_stay_time | bigint | the total time spent on product pages by users who arrived organically, from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live | -/-/1 | 7263665 |
| omni_ads_order_cnt | decimal(25,10) | the total order value or count attributed to users who came through advertisements. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 60/109/260 | 6.0 |
| omni_organic_order_cnt | decimal(25,10) | the total order value or count attributed to users who came not through ads. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 16.0 |
| omni_order_cnt | decimal(25,10) | the total order value or count across all traffic sources (both ads and organic). from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 144/277/627 | 16.0 |
| omni_ads_gmv | decimal(25,10) | omni_ads_gmv, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 4255.0 |
| omni_organic_gmv | decimal(25,10) | omni_organic_gmv, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 10898.91 |
| omni_gmv | decimal(25,10) | equal gmv*atc_prorate*first_touchpoint_item；from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 10898.91 |
| omni_ads_gmv_usd | decimal(25,10) | omni_ads_gmv,  expressed in USD. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 60/109/260 | 3365.6317975084 |
| omni_organic_gmv_usd | decimal(25,10) | omni_organic_gmv,  expressed in USD. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 8620.8503065058 |
| omni_gmv_usd | decimal(25,10) | omni_gmv,  expressed in USD. from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 151/284/634 | 8620.8503065058 |
| omni_ads_commission_fee | decimal(25,10) | the sum of omni_commission_fee*atc_prorate*first_touchpoint_item when is_ads equal true. | -/-/1 | 188.24 |
| omni_organic_commission_fee | decimal(25,10) | the sum of omni_commission_fee*atc_prorate*first_touchpoint_item when is_ads equal false or null. | -/-/1 | 799.47 |
| omni_commission_fee | decimal(25,10) | The fee charged as a commission for the sale of the item from omni. | -/-/1 | 799.47 |
| omni_ads_commission_fee_usd | decimal(25,10) | omni_ads_commission_fee_usd, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 148.8946015424 |
| omni_organic_commission_fee_usd | decimal(25,10) | omni_organic_commission_fee_usd, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 632.3670160174 |
| omni_commission_fee_usd | decimal(25,10) | omni_commission_fee_usd, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | 35/70/151 | 632.3670160174 |
| omni_item_sold_cnt | bigint | omni_item_sold_cnt, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 1000 |
| omni_ads_item_sold_cnt | bigint | omni_ads_item_sold_cnt, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 319 |
| omni_organic_item_sold_cnt | bigint | omni_organic_item_sold_cnt, from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live | -/-/1 | 1000 |
| content_live_ads_view_cnt | bigint | count of content_live_ads_view, from livestream.ls_mart_dwd_traffic_ls_session_view_detail_di | -/-/1 | 4544 |
| content_live_ads_view_duration | bigint | content_live_ads_view_duration, from livestream.ls_mart_dwd_view_streaming_detail_di.duration_b | -/-/1 | 128710 |
| content_live_ads_item_click_cnt | bigint | content_live_ads_item_click_cnt, from livestream.ls_mart_dwd_traffic_ls_session_view_detail_di | -/-/1 | 0 |
| content_live_ads_direct_order_cnt | bigint | content_live_ads_direct_order_cnt, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 13 |
| content_live_ads_direct_item_sold_cnt | bigint | content_live_ads_direct_item_sold_cnt, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 878 |
| content_live_ads_direct_gmv | decimal(25,10) | content_live_ads_direct_gmv, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 6736.0 |
| content_live_ads_direct_gmv_usd | decimal(25,10) | content_live_ads_direct_gmv_usd, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 5328.0601146926 |
| content_live_ads_broad_order_cnt | bigint | content_live_ads_broad_order_cnt, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 13 |
| content_live_ads_broad_item_sold_cnt | bigint | content_live_ads_broad_item_sold_cnt, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 878 |
| content_live_ads_broad_gmv | decimal(25,10) | content_live_ads_broad_gmv, from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 6736.0 |
| content_live_ads_broad_gmv_usd | decimal(25,10) | content_live_ads_broad_gmv_usd,from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di | -/-/1 | 5328.0601146926 |
| ads_revenue_roi2 | decimal(25,10) | roi2 ads revenue in local currency | -/-/1 | 20.0 |
| ads_revenue_usd_roi2 | decimal(25,10) | roi2 ads revenue in usd currency | -/-/1 | 15.8196559225 |
| if_roi1_item | int | the item_id with at least one  roi1 ads impression | -/-/1 | 1 |
| if_roi2_item | int | the item_id with at least one  roi2 ads impression | -/-/1 | 1 |
| if_new_product_boost | int | the item_id with at least one npb ads impression | -/-/1 | 1 |
| if_simple2_item | int | the item_id with at least one simple roi2 ads impression | -/-/1 | 1 |
| shop_id | bigint | shop_id | 51/100/251 | 58154590629 |
| tz_type | string | timezone [PARTITION] | 310/652/1449 |  |
| grass_region | string | region of ads performance [PARTITION] | 692/1395/3309 |  |
| grass_date | date | date of ads performance [PARTITION] | 699/1409/3339 |  |
