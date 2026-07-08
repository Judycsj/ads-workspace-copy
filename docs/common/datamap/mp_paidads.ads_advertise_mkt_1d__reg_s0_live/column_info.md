<!-- ads-workspace-gdoc-sync: gdoc_id=1bX0WtNjPgUNT9F4Tv4dQ6vKKjunzOlvosks_RVouBHE gdoc_url=https://docs.google.com/document/d/1bX0WtNjPgUNT9F4Tv4dQ6vKKjunzOlvosks_RVouBHE/edit -->

# Columns: mp_paidads.ads_advertise_mkt_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

No SUM(DISTINCT) patterns found in this table -- all metric columns are directly additive at the ads_id + placement + entrance + new_boost grain. However, note that `avg_ads_ranks` is a **weighted average** (not additive): it is stored as `SUM(rank * imp) / SUM(imp)` in the workflow, so re-aggregating requires weighting by `impression_cnt`.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 0 | DEFAULT_PRICING |
| pricing_type | 1 | MANUAL_MODE_CPC |
| pricing_type | 2 | ENHANCED_CPC |
| pricing_type | 3 | BOOST_ADS_PRICING |
| pricing_type | 4 | SIMPLE_MODE_PRICING |
| pricing_type | 5 | COST_PER_TIME |
| pricing_type | 6 | COST_PER_MILE |
| pricing_type | 7 | AUTO_BOOST_PRICING |
| pricing_type | 8 | TARGET_BROAD_ROAS |
| pricing_type | 9 | LIVE_STREAM_MAX_VIEW |
| pricing_type | 10 | LIVE_STREAM_MAX_GMV |
| pricing_type | 11 | ROI_TWO_PRICING |
| pricing_type | 12 | AUTO_PRODUCT_ROI_TARGET |
| pricing_type | 13 | NEW_PRODUCT_BOOST_PRICING |
| pricing_type | 14 | LIVE_STREAM_TARGET_ROAS |
| pricing_type | 15 | SIMPLE_ROI_TWO_PRICING |
| pricing_type | 16 | VIDEO_MAX_VIEW |
| pricing_type | 17 | VIDEO_MAX_GMV |
| pricing_type | 18 | ROI_THREE_PRICING |
| placement | 0 | keyword:search |
| placement | 2 | targeting:daily_discover |
| placement | 3 | keyword:shop |
| placement | 4 | keyword:simple_mode |
| placement | 5 | targeting:ymal |
| placement | 7 | keyword:banner |
| placement | 20 | shop_simple |
| placement | 54 | (video ads related) |
| placement | 802 | targeting:simple_mode_dd |
| placement | 805 | targeting:simple_mode_ymal |
| placement | 1000 | boost:search |
| placement | 1002 | boost:daily_discover |
| placement | 1005 | boost:ymal |
| placement | 1200 | auto_boost:search |
| placement | 1202 | auto_boost:daily_discover |
| placement | 1205 | auto_boost:ymal |
| cold_start_status_7d | 'Order success' | order_cnt_7d > 0 |
| cold_start_status_7d | 'Broad order success' | order=0, broad_order > 0 |
| cold_start_status_7d | 'In progress' | no orders, imp <= 3000 |
| cold_start_status_7d | 'Unsuccess' | no orders, 3000 < imp <= 9000 |
| cold_start_status_7d | 'Low quality' | no orders, imp > 9000 |
| seller_tier | 'large_seller' | GMV >= large threshold |
| seller_tier | 'medium_seller' | medium <= GMV < large |
| seller_tier | 'small_seller' | small <= GMV < medium |
| seller_tier | 'micro_seller' | GMV < small threshold |
| advertiser_tier | 'large_advertiser' | spend >= large threshold |
| advertiser_tier | 'medium_advertiser' | medium <= spend < large |
| advertiser_tier | 'small_advertiser' | small <= spend < medium |
| advertiser_tier | 'micro_advertiser' | spend < small threshold |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'local'` (~70% queries, used for adoption/supply metrics) / `'regional'` (~30%, used for OKR TR/revenue reporting)
- `placement NOT IN (7)`: exclude banner placement (standard for OKR active ads count)
- `pricing_type != 29`: excluded in production write (unknown/deprecated type)
- `is_ads_active = 1 OR has_performance = 1`: standard "active ads" filter for supply metrics
- `seller_type_1p NOT IN ('Lovito','SCS','Local SCS')`: OKR net revenue excludes 1P sellers
- `grass_region IN ('ID','BR','PH','TH','MY','VN','SG','TW')`: standard 8 regions for global reporting
- `placement IN (0,2,3,4,5,802,805,1000,1002,1005,1200,1202,1205,20,54)`: valid placements for cold start analysis

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | The grass_date column indicates the date of the data entry &#124; 日期分区字段more [PARTITION] | 19618/34851/69278 |  |
| 2 | grass_region | string | This column indicates the regional partition for the datamore [PARTITION] | 19398/34363/68195 |  |
| 3 | tz_type | string | This column denotes the timezone partition for the data entriesmore [PARTITION] | 19228/33918/67042 |  |
| 4 | shop_id | bigint | Shop id from mp_paidads.dim_advertise__reg_s0_live, used to identify the specific shop associated with an advertisement. &#124; 用于识别与广告关联的特定商店。 | 15361/26677/52238 | 1782595312 |
| 5 | item_id | bigint | item_id &#124; 商品ID | 12215/21820/43376 | 58157685122 |
| 6 | is_ads_active | tinyint | Ads active status from mp_paidads.dim_advertise__reg_s0_live. | 10518/19811/40840 | 1 |
| 7 | has_performance | tinyint | This flag indicates whether the advertisement has shown any measurable performance | 10061/18940/38647 | 1 |
| 8 | placement | bigint | Placement &#124; 广告位 (枚举值见Enum) [BIZ PRIMARY KEY] | 9860/17401/33652 | 4405 |
| 9 | ads_expenditure_amt_usd | double | Total expenditure on advertisements in USD &#124; 广告总支出（以美元计） | 9062/15513/31452 | 634.7385169072573 |
| 10 | pricing_type | int | pricing type of ads &#124; 广告计价模式 (枚举值见Enum) enum AdsPricingType{ DEFAULT_PRICING = 0; // to prevent there's ads who don't care pricing type MANUAL_MODE_CPC = 1; ENHANCED_CPC = 2; BOOST_ADS_PRICING = 3; SIMPLE_MODE_PRICING = 4; // when using default target_roi (0) COST_PER_TIME = 5; COST_PER_MILE = 6; // cost per thousand impression AUTO_BOOST_PRICING = 7; TARGET_BROAD_ROAS = 8; // when using custom target_roi LIVE_STREAM_MAX_VIEW = 9; LIVE_STREAM_MAX_GMV = 10; ROI_TWO_PRICING = 11; AUTO_PRODUCT_ROI_TARGET = 12; // unused for now NEW_PRODUCT_BOOST_PRICING = 13; // when new product boost is turned on for an ad LIVE_STREAM_TARGET_ROAS = 14; // name might not be final, just want to reserve the number first SIMPLE_ROI_TWO_PRICING = 15; VIDEO_MAX_VIEW = 16; VIDEO_MAX_GMV = 17; ROI_THREE_PRICING = 18; } | 5353/10117/21989 | 28 |
| 11 | campaign_id | bigint | Campaign_id &#124; 营销活动ID | 5218/10019/20271 | 53361987 |
| 12 | impression_cnt | bigint | raw impresssion coount &#124; 原始曝光量 | 4667/8378/19937 | 72858 |
| 13 | broad_order_gmv_amt_usd | double | This column indicates the gross merchandise value (GMV) from broad orders in USD. | 5417/9200/19691 | 31565.434051809374 |
| 14 | ads_gmv_usd | double | The gross merchandise value (GMV) generated by advertisements in US dollars under the direct attribution metric ｜ 直接订单归因口径下订单 GMV | 5044/8179/18366 | 30287.522246391138 |
| 15 | order_cnt | bigint | This column indicates the total count of direct orders generated from advertisements ｜ 该列表示广告产生的直接口径的订单数 | 3772/7184/17848 | 228 |
| 16 | broad_order_cnt | bigint | This column reflects the total count of broad orders generated from advertisements ｜ 该列反应了广告产生的广泛口径的订单数 | 4769/7541/16229 | 232 |
| 17 | click_cnt | bigint | count of successful deducted clicks &#124; 成功扣除的点击次数 | 3338/6318/15925 | 15245 |
| 18 | ads_id | bigint | Ads id from shopee.paid_ads_dim_advertise [BIZ PRIMARY KEY] | 2606/5386/14214 | 98465484 |
| 19 | ads_expenditure_amt_local | double | Total expenditure on ads in local currency ｜ 以当地货币计算的广告总支出 | 3527/5405/11544 | 802.4681700000001 |
| 20 | ads_gmv_local | double | direct order gmv in local currency | 2742/3785/7889 | 38291.0 |

### 查询频率分析

Top 20 高频查询字段可归纳为以下主题：

1. **分区过滤字段**（#1-3）：`grass_date`、`grass_region`、`tz_type` 查询频次遥遥领先（L30D 67K-69K），几乎所有查询都以这三个字段作为 WHERE 条件，说明该表严格按日期+区域+时区分区使用。

2. **广告标识与状态**（#4-7, #11, #18）：`shop_id`、`item_id`、`is_ads_active`、`has_performance`、`campaign_id`、`ads_id` 是最常用的维度字段，用于定位具体广告/商店/商品，以及按活跃状态和有效果进行过滤。

3. **广告位与计价**（#8, #10）：`placement`（广告位）和 `pricing_type`（计价模式）是核心分析维度，用于按广告位和出价策略拆分分析。

4. **花费与收入指标**（#9, #19）：`ads_expenditure_amt_usd` 和 `ads_expenditure_amt_local` 是最常查询的花费字段，说明花费分析以 USD 口径为主。

5. **效果指标**（#12-17, #20）：`impression_cnt`（曝光）、`click_cnt`（点击）、`order_cnt`/`broad_order_cnt`（直接/广义订单数）、`ads_gmv_usd`/`broad_order_gmv_amt_usd`（直接/广义 GMV）、`ads_gmv_local` 构成完整的漏斗指标体系，广义口径和直接口径指标查询频次相近。

> MAX(column): MAX() aggregated values from grass_date=2026-03-25, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| ads_id | bigint | Ads id from shopee.paid_ads_dim_advertise [BIZ PRIMARY KEY] | 2606/5386/14214 | 98465484 |
| shop_id | bigint | Shop id from mp_paidads.dim_advertise__reg_s0_live, used to identify the specific shop associated with an advertisement. &#124; 用于识别与广告关联的特定商店。 | 15361/26677/52238 | 1782595312 |
| seller_id | bigint | Seller ID  the unique identifier for each seller associated with the advertisement. ｜ 卖家ID, 表示与该广告关联的每个卖家的唯一标识符。 | 139/282/661 | 8589093347 |
| pricing_type | int | pricing type of ads &#124; 广告计价模式 (枚举值见Enum) enum AdsPricingType{ DEFAULT_PRICING = 0; // to prevent there's ads who don't care pricing type MANUAL_MODE_CPC = 1; ENHANCED_CPC = 2; BOOST_ADS_PRICING = 3; SIMPLE_MODE_PRICING = 4; // when using default target_roi (0) COST_PER_TIME = 5; COST_PER_MILE = 6; // cost per thousand impression AUTO_BOOST_PRICING = 7; TARGET_BROAD_ROAS = 8; // when using custom target_roi LIVE_STREAM_MAX_VIEW = 9; LIVE_STREAM_MAX_GMV = 10; ROI_TWO_PRICING = 11; AUTO_PRODUCT_ROI_TARGET = 12; // unused for now NEW_PRODUCT_BOOST_PRICING = 13; // when new product boost is turned on for an ad LIVE_STREAM_TARGET_ROAS = 14; // name might not be final, just want to reserve the number first SIMPLE_ROI_TWO_PRICING = 15; VIDEO_MAX_VIEW = 16; VIDEO_MAX_GMV = 17; ROI_THREE_PRICING = 18; } | 5353/10117/21989 | 28 |
| campaign_id | bigint | Campaign_id &#124; 营销活动ID | 5218/10019/20271 | 53361987 |
| campaign_status | tinyint | This column reflects the current status of the advertising campaign as indicated in the associated dimension table. &#124; 广告活动的当前状态 | 679/1277/2855 | 7 |
| campaign_status_text | string | Campaign status in text &#124; campaign status 额外信息 | 3/14/35 | ADS_PAUSED |
| campaign_start_datetime | string | This column captures the start time of the advertising campaign ｜ campaign的开始时间 | 349/741/1762 | 2279-09-02 00:00:00 |
| campaign_end_datetime | string | This column captures the end time of the advertising campaign ｜ campaign的结束时间 | 266/543/1448 | 9999-12-31 23:59:59 |
| campaign_total_quota_local | double | The total budget allocated for the advertising campaign in local currency &#124; 广告设置活动总预算以当地货币计 | 3/13/26 | 19013.64 |
| campaign_total_quota_usd | double | Total advertising campaign budget expressed in USD &#124; 以美元表示的广告活动总预算 | 279/550/1317 | 15039.4621317 |
| campaign_daily_quota_local | double | This column reflects the daily quota allocated for the advertisement campaign in local currency, which helps in managing budget allocations effectively. ｜ 此栏以当地货币反映每日为广告活动分配的配额，这有助于有效地管理预算分配。 | 47/91/204 | 10000000000000 |
| campaign_daily_quota_usd | double | This column represents the daily quota set for the advertisement campaign in USD ｜ 此栏表示以美元为单位的每日广告活动配额 | 343/702/1696 | 7909827961241.843 |
| placement | bigint | Placement &#124; 广告位 (枚举值见Enum) [BIZ PRIMARY KEY] | 9860/17401/33652 | 4405 |
| ads_type | string | Ads type in text from shopee.paid_ads_dim_advertise. | 249/441/2053 | targeting:ymal |
| ads_create_datetime | string | Ads create time &#124; 广告活动的创建时间 | 690/1409/2814 | 2026-03-25 23:59:27 |
| item_id | bigint | item_id &#124; 商品ID | 12215/21820/43376 | 58157685122 |
| item_name | string | item_name ｜ 商品名称 | 10/29/41 | 󠁧󠁢󠁳󠁣󠁴󠁿Walkers Shortbread Highlander 200g/150g/OatFlake Cranberry/Choco Hazelnut/Belgian Chocolate Chunk Cookies 150g |
| impression_cnt | bigint | raw impresssion coount &#124; 原始曝光量 | 4667/8378/19937 | 72858 |
| click_cnt | bigint | count of successful deducted clicks &#124; 成功扣除的点击次数 | 3338/6318/15925 | 15245 |
| order_cnt | bigint | This column indicates the total count of direct orders generated from advertisements ｜ 该列表示广告产生的直接口径的订单数 | 3772/7184/17848 | 228 |
| ads_items_sold_cnt | bigint | count of items sold in direct order &#124; 直接归因订单销售的商品item数量 | 315/648/3141 | 1630 |
| ads_gmv_local | double | direct order gmv in local currency | 2742/3785/7889 | 38291.0 |
| ads_gmv_usd | double | The gross merchandise value (GMV) generated by advertisements in US dollars under the direct attribution metric ｜ 直接订单归因口径下订单 GMV | 5044/8179/18366 | 30287.522246391138 |
| ads_expenditure_amt_local | double | Total expenditure on ads in local currency ｜ 以当地货币计算的广告总支出 | 3527/5405/11544 | 802.4681700000001 |
| ads_expenditure_amt_usd | double | Total expenditure on advertisements in USD &#124; 广告总支出（以美元计） | 9062/15513/31452 | 634.7385169072573 |
| avg_ads_ranks | double | Average ads position in a page &#124; 广告在页面上的平均位置 | 13/31/68 | 92503.0 |
| shopitem_impression_cnt | bigint | This column represents the count of impressions for shop ads items &#124; 广义归因口径下，广告商店曝光量 | 6/16/28 | 102701 |
| shopitem_click_cnt | bigint | Total number of clicks on direct shop items driven by advertisements &#124; 直接归因口径下，广告商店点击数 | 370/740/1486 | 252 |
| broad_shopitem_click_cnt | bigint | This column shows the count of clicks on broad shop items from advertisements | 150/303/589 | 1981 |
| broad_shopitem_impression_cnt | bigint | This column indicates the total count of impressions received by broad shop ads | 150/303/589 | 253294 |
| broad_order_item_cnt | bigint | count of items sold in broad ads order. &#124; 广泛归因口径下广告item量 | 201/430/895 | 1630 |
| broad_order_gmv_amt_local | double | Represents the gross merchandise value (GMV) of orders classified as broad orders in local currency. | 837/1721/4820 | 39906.6 |
| broad_order_gmv_amt_usd | double | This column indicates the gross merchandise value (GMV) from broad orders in USD. | 5417/9200/19691 | 31565.434051809374 |
| broad_order_cnt | bigint | This column reflects the total count of broad orders generated from advertisements ｜ 该列反应了广告产生的广泛口径的订单数 | 4769/7541/16229 | 232 |
| paid_order_cnt | bigint | paid order count. | 5/21/38 | 22445 |
| paid_order_cnt_ytd | bigint | total paid order of grass_date minus 1 date. | 3/21/33 | 24455 |
| confirmed_order_cnt | bigint | confirm order count. | 5/15/29 | NULL |
| confirmed_order_cnt_ytd | bigint | total confirm order of grass_date minus 1 date. | 3/13/25 | NULL |
| checkout_cnt | bigint | order count &#124; 订单数 根据order_id进行去重 | 1102/1786/5595 | 232 |
| is_ads_active | tinyint | Ads active status from mp_paidads.dim_advertise__reg_s0_live. | 10518/19811/40840 | 1 |
| has_performance | tinyint | This flag indicates whether the advertisement has shown any measurable performance | 10061/18940/38647 | 1 |
| hit_daily_budget | tinyint | deprecated | 3/13/25 | NULL |
| hit_total_budget | tinyint | deprecated | 3/13/25 | NULL |
| is_cb_seller | tinyint | A flag indicating whether the shop is a cross-border seller | 614/1259/2596 | 1 |
| level1_global_be_category | struct | Level 1 global backend category name of the item | 1839/2871/5238 | {"level1_global_be_category_id":null,"level1_global_be_category":null} |
| level1_fe_display_category_list | array | This column contains an array of structures representing the level 1 front-end display categories | 80/167/356 | [{"level1_fe_display_category_id":11029718,"level1_fe_display_category":"Miscellaneous","level1_fe_display_category_fraction_factor":1.0}] |
| level1_kpi_category_list | array | This column contains a list of first-level KPI categories | 80/167/356 | [{"level1_kpi_category_id":11032601,"level1_kpi_category":"Miscellaneous","level1_kpi_category_fraction_factor":1.0}] |
| level2_global_be_category | struct | This column encapsulates the level 2 global buyer engagement category | 1727/2629/4571 | {"level2_global_be_category_id":null,"level2_global_be_category":null} |
| level2_fe_display_category_list | array | This column contains a list of level 2 front-end display categories | 80/167/356 | [{"level2_fe_display_category_id":11059285,"level2_fe_display_category":"Infant Milk Formula","level2_fe_display_category_fraction_factor":1.0}] |
| level2_kpi_category_list | array | This column holds an array of structures containing level 2 KPI categories | 80/167/356 | [{"level2_kpi_category_id":11059282,"level2_kpi_category":"Infant Milk Formula","level2_kpi_category_fraction_factor":1.0}] |
| level3_global_be_category | struct | level3_global_be_category | 649/1234/2488 | {"level3_global_be_category_id":null,"level3_global_be_category":null} |
| level3_fe_display_category_list | array | This column contains an array of structures that represent level3_fe_display_category | 80/167/356 | [{"level3_fe_display_category_id":11116286,"level3_fe_display_category":"Jam & Spread","level3_fe_display_category_fraction_factor":1.0}] |
| level3_kpi_category_list | array | This column holds an array of structures containing level 3 KPI categories | 80/167/356 | [{"level3_kpi_category_id":11116287,"level3_kpi_category":"Jam & Spread","level3_kpi_category_fraction_factor":1.0}] |
| shop_level1_global_be_category | string | shop_level1_global_be_category | 93/196/466 | Women Shoes |
| shop_level1_fe_display_category | string | shop_level1_fe_display_category | 3/13/25 | Women's Shoes |
| shop_level1_kpi_category | string | shop_level1_kpi_category | 3/13/25 | Women's Shoes |
| add_to_cart_cnt | bigint | This column tracks the number of times items have been added to the cart from advertisements | 135/285/596 | 283 |
| add_to_cart_without_clicks_cnt | bigint | sum of a one day's add_to_cart_without clicks | 3/13/25 | 99 |
| broad_add_to_cart_cnt | bigint | broad_add_to_cart_cnt = add_to_cart + add_to_cart_without_clicks + broad_add_to_cart_other. | 455/914/4222 | 314 |
| broad_roi | double | This column calculates the return on investment from broad orders | 5/15/27 | 40100000 |
| cold_start_status_7d | string | This column denotes the 7-day status of ads based on their performance | 3/13/25 | Unsuccess |
| cold_start_status_14d | string | This column denotes the 14-day status of ads based on their performance | 3/13/25 | Unsuccess |
| first_7d_order_count | bigint | This column counts the total number of orders received within the first 7 days | 3/13/25 | 16 |
| first_14d_order_count | bigint | This column captures the count of orders generated within the first 14 days | 3/13/25 | 61 |
| first_order_date | date | the date of the first order after the ads creation &#124; 广告创建后第一个订单的日期 | 3/13/25 | 2026-03-25 |
| view_cnt | bigint | pdp_view, count of views on your product detail page after logged-in users click on your ads | 115/234/1651 | 55712 |
| product_click_cnt | bigint | number of product clicks (deduplicated), only for video ads. | 435/869/1761 | 1611 |
| new_boost | bigint | wether the advertise is new item ads &#124; 广告是否是新项目广告 [BIZ PRIMARY KEY] | 3/13/25 | 0 |
| ta_group_id | bigint | target audience group id | 3/13/25 | 60147 |
| ta_premium_rate | bigint | the premium rate when the advertisement matches the target audience group | 3/13/25 | NULL |
| tag_ids | array | tag_ids | 3/13/25 | NULL |
| entrance | bigint | Entrance &#124; 广告入口 (枚举值见Enum) [BIZ PRIMARY KEY] | 154/367/1217 | 74 |
| entry_point | string | entry type &#124; 广告类型 | 112/224/466 | You May Also Like |
| traffic_type | string | Describes the type of traffic source for the advertisements &#124; 描述广告的流量来源类型 | 134/274/786 | You May Also Like |
| sub_product_type | string | refer to spreadsheet | 498/1208/3842 | video_roi2.0 |
| product_type | string | refer to spreadsheet | 347/905/3390 | Video Ads |
| main_product_type | string | main_product_type &#124; 广告类型 | 1371/2634/6517 | Video Ads |
| video_play_complete | bigint | number of completed video views ｜ 已完成视频观看次数 | 3/13/25 | 372 |
| video_play_3s_cnt | bigint | This column represents the count of times a video advertisement was played for more than 3 seconds. | 3/13/25 | 331910 |
| video_play_5s_cnt | bigint | This column records the number of times a video advertisement was played for more than 5 seconds | 3/13/25 | 328604 |
| video_view | bigint | In one video play, the vv count is only incremented when the first frame of the video is played | 17/41/1250 | 2881 |
| view_duration | bigint | This column indicates the duration for which ads were viewed | 3/13/25 | 9714755816 |
| seller_type | string | This column indicates the type of seller associated with the shop | 66/140/382 | VNCB |
| seller_type_1p | string | Denotes the type of seller, specifically identifying one-party sellers | 390/661/1433 | Unknown |
| is_cb_sip_affiliated | tinyint | this is a SIP shop tag. if parent shop is cb shop | 327/535/1089 | 1 |
| is_local_sip_affiliated | tinyint | this is a SIP shop tag. if parent shop is local shop | 327/535/1089 | 1 |
| price_usd | double | item price (in usd) &#124; 商品价格 以美元计价 | 33/88/184 | 6466284.358315207 |
| level4_global_be_category | string | level4_global_be_category | 3/13/25 | Yoga Mats |
| seller_tier | string | big seller definition &#124; 大卖家标签 | 140/284/654 | small_seller |
| advertiser_tier | string | Big Ads Spender Tag Definition | 140/283/652 | small_advertiser |
| net_ads_revenue_usd_1d | double | This column represents the net advertisement revenue generated | 337/638/2039 | 634.7384990000002 |
| free_ads_revenue_amt_usd_1d | double | The amount of revenue in USD generated from free advertisements | 483/782/1504 | 237.29482799999994 |
| gross_ads_revenue_usd_1d | double | gross_ads_revenue_usd_1d（after VAT）=net_ads_revenue_usd_1d+free_ads_revenue_amt_usd_1d | 496/833/1596 | 634.7384990000002 |
| deduplicated_click_cnt | bigint | This column records the count of unique clicks on advertisements | 753/1243/2300 | 13777 |
| cps_dedup_click_cnt | bigint | This column represents the count of deduplicated clicks specifically deducted by CPS | 383/646/1315 | NULL |
| deduct_order_cnt | bigint | The count of orders that have been deducted by the Cost Per Sale (CPS) model | 3/13/25 | 0 |
| potential_product_type | int | This column denotes the type of a potential product at the time of ad creation | 3/13/25 | 2 |
| ads_status | bigint | ads status, enum | 370/632/1210 | 7 |
| expense_rebate_free_credit_without_expiry | decimal(25,10) | it records auto rebate-based free credit provided by the platform without an expiry date | 3/13/25 | 232.79545 |
| imp_attr_paid_order_cnt | bigint | Count of broad paid orders that don't have ads click but has ads impression | 4/15/27 | 47 |
| imp_attr_paid_order_item_sold_cnt | bigint | Count of broad paid order items that don't have ads click but has ads impression | 4/14/26 | 536 |
| imp_attr_paid_order_gmv | double | Sum of broad paid order gmv in local concurrency | 6/16/28 | 23662.0 |
| imp_attr_paid_order_gmv_usd | double | Sum of broad paid order gmv in usd concurrency | 6/16/28 | 18716.23492190001 |
| paid_order_item_sold_cnt | bigint | Count of direct paid orders | 3/13/25 | 1768 |
| paid_broad_order_cnt | bigint | Count of broad paid orders | 243/366/657 | 227 |
| paid_broad_order_gmv | double | Sum of broad paid order gmv in local concurrency | 77/160/334 | 38620.6 |
| paid_broad_order_item_sold_cnt | bigint | Count of broad paid order items | 12/31/61 | 1768 |
| paid_broad_order_gmv_usd | double | Sum of broad paid order gmv in usd concurrency | 245/374/662 | 30548.230176299996 |
| paid_checkout_cnt | bigint | Checkout is calculated by count distinct paid orderid | 3/13/25 | 227 |
| paid_agent_checkout_cnt | bigint | calculated by count distinct paid agent order_id | 3/13/25 | 27 |
| paid_no_click_order_item_sold_cnt | bigint | count of items in order that don't have ads click& impr but hit the order_exp_tag | 3/13/25 | 120 |
| paid_no_click_order_gmv | double | sum of order gmv that don't have ads click& impr but hit the order_exp_tag | 5/15/27 | 558.83 |
| paid_no_click_order_cnt | bigint | count of order that don't have ads click& impr but hit the order_exp_tag | 3/13/25 | 18 |
| paid_no_click_order_gmv_usd | double | sum of order gmv usd that don't have ads click& impr but hit the order_exp_tag | 5/15/27 | 442.024916 |
| no_click_gmv_usd | double | sum of order gmv usd that don't have ads click& impr but hit the order_exp_tag | 7/17/29 | 798.1016413 |
| tz_type | string | This column denotes the timezone partition for the data entriesmore [PARTITION] | 19228/33918/67042 |  |
| grass_region | string | This column indicates the regional partition for the datamore [PARTITION] | 19398/34363/68195 |  |
| grass_date | date | The grass_date column indicates the date of the data entry &#124; 日期分区字段more [PARTITION] | 19618/34851/69278 |  |
