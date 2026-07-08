<!-- ads-workspace-gdoc-sync: gdoc_id=1g4hnMA3Vb0iDQVv0H1q6W2cAF98sT2P71Kdw_Fubbfg gdoc_url=https://docs.google.com/document/d/1g4hnMA3Vb0iDQVv0H1q6W2cAF98sT2P71Kdw_Fubbfg/edit -->

# Columns: traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表为 DWS 层 view，指标为 1d 粒度。跨天聚合时直接 SUM 即可（指标本身就是 1d 增量值）。未发现 SUM(DISTINCT) 的代码模式。

注意：`order_1d` / `gmv_usd_1d` 等指标是 atc_prorated 的 fraction value，跨 user/shop/item 向高维度聚合时直接 SUM 是合理的。但如果同时跨 `user_id` 和 `item_id` 去重，需要注意 atc_proration 导致的数据膨胀。

### 枚举值映射 (Value Mappings)

以下映射在 2+ 个代码文件中重复出现：

| Column | Value | Meaning | Context |
|--------|-------|---------|---------|
| business_line | Search | 搜索流量 | Scene classification |
| business_line | Homepage | 首页流量 | Scene classification |
| business_line | Rcmd | 推荐流量 | Scene classification |
| business_line | Shop(Non Rcmd) | 店铺非推荐流量 | MAX(column)采样值 |
| module | Global Search | 全局搜索模块 | Search scene |
| module | Daily Discover | 每日发现模块 | DD scene |
| module | User Scenario | 用户场景模块 | MAX(column)采样值 |
| object | you may also like | YMAL推荐 | YMAL scene |
| object | zone card | 区域卡片 | MAX(column)采样值 |

### 常见 WHERE 值 (Common Filter Values)

从代码库 WHERE 子句提取的常用过滤值：

- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN','BR' (标准 8 区, ~100% 查询)
- `local_date`: 范围从 `date_sub('${BIZ_PRE_DAY}', 29)` 到 `date('${BIZ_PRE_DAY}')` (30天窗口最常用)
- `shop_id IS NOT NULL AND item_id IS NOT NULL` (~80% ML场景)
- `gmv_usd_1d > 0` (过滤有GMV的商品, 品类/分层分析)
- `MONTH(local_date) <> DAY(local_date) AND DAY(local_date) NOT IN (15,25)` (排除 campaign day 和 payday, 品类分桶分析)
- `regional_date = date('${1_DAYS_AGO}')` (Singa时区日期过滤, 诊断场景)

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_region | string | Partition@The `grass_region` column specifies the region where the traffic/order events happened. | 11004/20265/41634 |  |
| 2 | local_date | date | Partition@The `local_date` column represents the date in local timezone. | 10875/20024/41129 |  |
| 3 | item_id | bigint | The `item_id` column is a unique identifier assigned to each item in the inventory. | 8744/16092/32214 | 58157920841 |
| 4 | order_1d | double | The `order_1d` column represents the sum of atc_prorated order fraction value of all item orders in 1 day. | 6914/12009/24498 | 16.000000000000004 |
| 5 | user_id | bigint | The `user_id` column serves as a unique identifier for users. | 6612/11488/23328 | 8589745007 |
| 6 | business_line | string | The `business_line` column represents the business line of the main click/impression event. | 6055/10692/21410 | Shop(Non Rcmd) |
| 7 | module | string | The `module` column represents the reporting module of a main click/impression event. | 5904/10254/20807 | User Scenario |
| 8 | gmv_usd_1d | double | The `gmv_usd_1d` column represents the sum of atc_prorated gmv value in USD of all order items in 1 day. | 6056/10392/20425 | 8620.8503065058 |
| 9 | source1_business_line | string | The `source1_business_line` column represents the business line of the 1st-step source click event. | 5382/9344/18495 | Search |
| 10 | source2_business_line | string | The `source2_business_line` column represents the business line of the 2nd-step source click event. | 5362/9304/18406 | Search |
| 11 | source1_module | string | The `source1_module` column represents the reporting module of a 1st-step source click event. | 5244/8927/17948 | User Scenario |
| 12 | source2_module | string | The `source2_module` column represents the reporting module of a 2nd-step source click event. | 5224/8887/17859 | User Scenario |
| 13 | object | string | The `object` column represents the reporting object of the main click/impression event. | 5084/9033/17662 | zone card |
| 14 | source1_object | string | The `source1_object` column represents the reporting object of 1st-step source click event. | 4406/7681/14763 | you may also like |
| 15 | source2_object | string | The `source2_object` column represents the reporting object of 2nd-step source click event. | 4400/7668/14735 | you may also like |
| 16 | impr_cnt_1d | bigint | The `impr_cnt_1d` column represents the sum of all cards impressions in 1 day. | 4328/6858/13161 | 8280 |
| 17 | order_organic_1d | double | The `order_organic_1d` column represents the sum of atc_prorated order fraction value of non-ads item orders in 1 day. | 2915/5986/12803 | 16.000000000000004 |
| 18 | item_impr_cnt_1d | bigint | The `item_impr_cnt_1d` column represents the count of all item-card impressions in 1 day. | 2878/5720/12196 | 4127 |
| 19 | shop_id | bigint | The `shop_id` column identifies the shop which an item belongs to. | 2537/4953/10389 | 1786997919 |
| 20 | click_cnt_1d | bigint | The `click_cnt_1d` column represents the count of all cards and button clicks in 1 day. | 3879/5842/10277 | 191 |

### 查询频率分析

Top 20 高频字段可归为以下主题：

1. **分区键**（#1-2）：`grass_region` 和 `local_date` 是分区列，几乎所有查询都会使用，L30D 查询量均超过 4 万次。

2. **实体标识**（#3, #5, #19）：`item_id`、`user_id`、`shop_id` 是核心维度键，用于关联其他表或进行实体级聚合分析。`item_id` 查询量最高（32K），反映该表以商品粒度分析为主。

3. **订单与 GMV 指标**（#4, #8, #17）：`order_1d`、`gmv_usd_1d`、`order_organic_1d` 是核心业务指标，用于衡量销售转化和交易金额。Organic 订单单独高频出现说明 ads vs organic 对比分析是常见场景。

4. **流量归因维度**（#6-7, #9-15）：`business_line`、`module`、`object` 及其 source1/source2 对应字段占据 Top 20 中 10 个位置，说明多层级流量归因（主事件 → 一级来源 → 二级来源）是该表最核心的使用场景。

5. **曝光与点击指标**（#16, #18, #20）：`impr_cnt_1d`、`item_impr_cnt_1d`、`click_cnt_1d` 用于漏斗上层分析，常与订单指标配合计算转化率。

> MAX(column): MAX() aggregated values from grass_date=2026-03-29, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| user_id | bigint | The `user_id` column serves as a unique identifier for users. | 6612/11488/23328 | 8589745007 |
| device_id | string | The `device_id` column identifies the user device involved in traffic and/or order events. | 9/14/25 | zzzHgnDd7hpzlisml4qbk8Mrd5GK06EO |
| platform | string | The `platform` column specifies the platform through which user interactions or transactions occurred. | 74/145/308 | pc_web |
| platform_implementation | string | The `platform_implementation` column specifies the platform implementation of the user's Shopee application. | 74/145/306 | rweb_ios |
| app_version | string | The `app_version` column specifies the version of the application used during user interaction. | 200/397/848 | v1.0.0-sw_WEBFE_MKP_2026_03_v4_1_1_r18 |
| rn_version | string | The `rn_version` column specifies the react native version on user's device. | 200/397/846 | 6.99.0 |
| location | int | The `location` column represents the location of item in a click/impression event. | 44/84/175 | 4965 |
| gender | bigint | The `gender` column indicates the gender of the user. | 200/404/867 | 4 |
| is_cb_seller | tinyint | The `is_cb_seller` column indicates whether the seller is a cross-border seller. | 52/112/220 | 1 |
| placed_order_cnt_td | bigint | The `placed_order_cnt_td` column represents the total count of orders placed by a user to date. | 200/404/867 | 36092 |
| item_id | bigint | The `item_id` column is a unique identifier assigned to each item in the inventory. | 8744/16092/32214 | 58157920841 |
| item_status | bigint | The `item_status` column indicates the current status of an item. | 149/301/646 | 8 |
| stock | bigint | The `stock` column represents the current inventory level of an item. | 233/467/1004 | 1345297717 |
| price | decimal(25,10) | The `price` column represents the price of an item around midnight local time in local currency. | 9/14/25 | 999999.0 |
| price_usd | decimal(25,10) | The `price_usd` column represents the price of an item around midnight local time in US Dollars. | 397/702/1340 | 790982.0051413882 |
| price_before_discount | decimal(25,10) | The `price_before_discount` column represents the original price of an item before any discounts. | 9/14/25 | 999999.0 |
| price_before_discount_usd | decimal(25,10) | The `price_before_discount_usd` column represents the original price of an item in USD before any discounts. | 135/273/586 | 790982.0051413882 |
| rating_score | decimal(25,10) | The `rating_score` column represents the average rating score of an item. | 231/470/1007 | 5.0 |
| rating_total_cnt | bigint | The `rating_total_cnt` column represents the total count of ratings received for the items. | 231/470/1007 | 729164 |
| comment_cnt | bigint | The `comment_cnt` column indicates the total number of comments made on the item. | 231/470/1007 | 131138 |
| create_datetime | string | The `create_datetime` column records the local date and time when the order was placed. | 610/1234/2673 | 2026-03-29 23:56:33 |
| level1_global_be_category_id | bigint | The `level1_global_be_category_id` column represents the identifier for the main global backend category of an item. | 424/811/1606 | 102187 |
| level2_global_be_category_id | bigint | The `level2_global_be_category_id` column identifies the Level 2 global backend category ID of the item. | 452/867/1725 | 102272 |
| level1_global_be_category | string | The `level1_global_be_category` column contains the name of the Level 1 global backend category. | 1486/2652/6097 | Women Shoes |
| level2_global_be_category | string | The `level2_global_be_category` column represents the name of the Level 2 global backend category. | 568/1208/2344 | Writing & Correction |
| shop_id | bigint | The `shop_id` column identifies the shop which an item belongs to. | 2537/4953/10389 | 1786997919 |
| shop_status | bigint | The `shop_status` column indicates the current operational status of the shop. | 30/56/115 | 1 |
| is_cb_shop | tinyint | The `is_cb_shop` column indicates whether the item comes from a cross-border shop. | 359/693/1463 | 1 |
| is_official_shop | tinyint | The `is_official_shop` column indicates whether the shop is an official store. | 175/357/847 | 1 |
| is_preferred_shop | tinyint | The `is_preferred_shop` column indicates whether the shop is marked as a preferred shop. | 175/357/847 | 1 |
| is_preferred_plus_shop | tinyint | The `is_preferred_plus_shop` column indicates whether a shop is classified as a Preferred Plus shop. | 175/357/847 | 0 |
| seller_type | string | The `seller_type` column specifies the type of seller. | 24/43/86 | VNCB |
| seller_type_1p | string | The `seller_type_1p` column indicates the first-party (1P) seller type. | 9/14/25 | Unknown |
| is_cb_sip_affiliated | tinyint | The `is_cb_sip_affiliated` column indicates whether the item is from an affiliate cross-border shop. | 9/14/25 | 1 |
| is_local_sip_affiliated | tinyint | The `is_local_sip_affiliated` column indicates whether the item is from an affiliate local shop. | 25/44/99 | 1 |
| business_line | string | The `business_line` column represents the business line of the main click/impression event. | 6055/10692/21410 | Shop(Non Rcmd) |
| module | string | The `module` column represents the reporting module of a main click/impression event. | 5904/10254/20807 | User Scenario |
| object | string | The `object` column represents the reporting object of the main click/impression event. | 5084/9033/17662 | zone card |
| source1_business_line | string | The `source1_business_line` column represents the business line of the 1st-step source click event. | 5382/9344/18495 | Search |
| source1_module | string | The `source1_module` column represents the reporting module of a 1st-step source click event. | 5244/8927/17948 | User Scenario |
| source1_object | string | The `source1_object` column represents the reporting object of 1st-step source click event. | 4406/7681/14763 | you may also like |
| source2_business_line | string | The `source2_business_line` column represents the business line of the 2nd-step source click event. | 5362/9304/18406 | Search |
| source2_module | string | The `source2_module` column represents the reporting module of a 2nd-step source click event. | 5224/8887/17859 | User Scenario |
| source2_object | string | The `source2_object` column represents the reporting object of 2nd-step source click event. | 4400/7668/14735 | you may also like |
| feature_group | string | The `feature_group` column represents the group classification of the main click/impression event. | 1024/1778/3485 | not found valid click |
| feature | string | The `feature` column shows feature of the main click/impression events. | 631/1274/2707 | you_may_also_like-order_shipping_info |
| feature_detail | string | The `feature_detail` column contains detailed feature attributes related to the main click/impression event. | 1588/2006/2988 | you_may_also_like-item |
| source1_feature_group | string | The `source1_feature_group` column categorizes the feature group of source1 events. | 500/762/1447 | not found |
| source1_feature | string | The `source1_feature` column shows feature of 1st-step source events. | 557/1129/2411 | ymal_product-product |
| source1_feature_detail | string | The `source1_feature_detail` column represents detailed feature attributes related to the 1st-step source click event. | 1439/1711/2366 | voucher_tnc-shop_icon |
| source2_feature_group | string | The `source2_feature_group` column categorizes the feature group of source2 events. | 500/762/1447 | not found |
| source2_feature | string | The `source2_feature` column shows feature of 2nd-step source events. | 557/1129/2411 | ymal_landing-product |
| source2_feature_detail | string | The `source2_feature_detail` column represents detailed feature attributes related to the 2nd-step source click event. | 1439/1711/2366 | video-live_avatar_button_click |
| item_impr_cnt_1d | bigint | The `item_impr_cnt_1d` column represents the count of all item-card impressions in 1 day. | 2878/5720/12196 | 4127 |
| item_impr_ads_cnt_1d | bigint | The `item_impr_ads_cnt_1d` column captures the count of ads item-card impressions in 1 day. | 851/1697/3519 | 1382 |
| item_impr_organic_cnt_1d | bigint | The `item_impr_organic_cnt_1d` column represents the count of non-ads item-card impressions in 1 day. | 1589/3205/6860 | 4127 |
| item_click_cnt_1d | bigint | The `item_click_cnt_1d` column records the count of all item-card clicks in 1 day. | 2355/4679/9979 | 343 |
| item_click_ads_cnt_1d | bigint | The `item_click_ads_cnt_1d` column represents the count of ads item-card clicks in 1 day. | 687/1369/2812 | 49 |
| item_click_organic_cnt_1d | bigint | The `item_click_organic_cnt_1d` column represents the count of non-ads item-card clicks in 1 day. | 1588/3220/6922 | 343 |
| ppv_cnt_1d | bigint | The `ppv_cnt_1d` column represents the count of direct product page views in 1 day. | 494/957/1918 | 75 |
| ppv_ads_cnt_1d | bigint | The `ppv_ads_cnt_1d` column represents the count of direct ads product page views in 1 day. | 284/578/1223 | 25 |
| ppv_organic_cnt_1d | bigint | The `ppv_organic_cnt_1d` column represents the count of direct non-ads product page views in 1 day. | 284/578/1223 | 75 |
| ppv_duration_1d | bigint | The `ppv_duration_1d` column represents the sum of page duration of product page views in 1 day. | 297/566/1024 | 7248153 |
| ppv_ads_duration_1d | bigint | The `ppv_ads_duration_1d` column represents the sum of page duration of ads product page views in 1 day. | 285/538/964 | 7211400 |
| ppv_organic_duration_1d | bigint | The `ppv_organic_duration_1d` column represents the sum of page duration of non-ads product page views in 1 day. | 285/538/964 | 7248153 |
| atc_cnt_1d | bigint | The `atc_cnt_1d` column represents the count of Add to Cart actions in 1 day. | 606/1174/2298 | 56 |
| atc_ads_cnt_1d | bigint | The `atc_ads_cnt_1d` column represents the count of atc events for ads items in 1 day. | 490/956/1866 | 50 |
| atc_organic_cnt_1d | bigint | The `atc_organic_cnt_1d` column represents the count of atc events for non-ads items in 1 day. | 497/970/1896 | 56 |
| order_1d | double | The `order_1d` column represents the sum of atc_prorated order fraction value of all item orders in 1 day. | 6914/12009/24498 | 16.000000000000004 |
| order_ads_1d | double | The `order_ads_1d` column represents the sum of atc_prorated order fraction value of ads item orders in 1 day. | 2623/3904/6845 | 5.5 |
| order_organic_1d | double | The `order_organic_1d` column represents the sum of atc_prorated order fraction value of non-ads item orders in 1 day. | 2915/5986/12803 | 16.000000000000004 |
| gmv_1d | double | The `gmv_1d` column represents the sum of atc_prorated gmv in local currency in 1 day. | 374/780/1664 | 10898.91 |
| gmv_ads_1d | double | The `gmv_ads_1d` column represents the sum of atc_prorated gmv in local currency of ads item orders in 1 day. | 120/255/515 | 4255.0 |
| gmv_organic_1d | double | The `gmv_organic_1d` column represents the sum of atc_prorated gmv value of non-ads item orders in 1 day. | 128/275/553 | 10898.91 |
| gmv_usd_1d | double | The `gmv_usd_1d` column represents the sum of atc_prorated gmv value in USD of all order items in 1 day. | 6056/10392/20425 | 8620.8503065058 |
| gmv_usd_ads_1d | double | The `gmv_usd_ads_1d` column represents the sum of atc_prorated gmv in USD of ads item orders in 1 day. | 994/1827/3753 | 3365.6317975084 |
| gmv_usd_organic_1d | double | The `gmv_usd_organic_1d` column represents the sum of atc_prorated gmv value in USD of non-ads item orders in 1 day. | 1969/4032/8400 | 8620.8503065058 |
| pc2_1d | double | The `pc2_1d` column represents the sum of atc_prorated pc2 value of all item orders in 1 day. | 147/296/626 | 610.3389599999999 |
| pc2_ads_1d | double | The `pc2_ads_1d` column represents the sum of atc_prorated pc2 value of ads item orders in 1 day. | 23/47/90 | 238.27999999999997 |
| pc2_organic_1d | double | The `pc2_organic_1d` column represents the sum of atc_prorated pc2 value of non-ads item orders in 1 day. | 100/203/423 | 610.3389599999999 |
| pc2_usd_1d | double | The `pc2_usd_1d` column represents the sum of atc_prorated pc2 value in USD of all related orders in 1 day. | 2397/3179/5308 | 482.7676171643247 |
| pc2_usd_ads_1d | double | The `pc2_usd_ads_1d` column represents the sum of atc_prorated pc2 value in USD of ads item orders in 1 day. | 261/462/991 | 188.47538066047036 |
| pc2_usd_organic_1d | double | The `pc2_usd_organic_1d` column represents the sum of atc_prorated pc2 value in USD of non-ads item orders in 1 day. | 348/642/1378 | 482.7676171643247 |
| item_qty_1d | double | The `item_qty_1d` column represents the sum of atc_prorated item quantity of all orders in 1 day. | 23/47/90 | 1000.0 |
| item_qty_ads_1d | double | The `item_qty_ads_1d` column represents the sum of atc_prorated item quantity of ads item orders in 1 day. | 23/47/90 | 269.0 |
| item_qty_organic_1d | double | The `item_qty_organic_1d` column represents the sum of atc_prorated item quantity of non-ads item orders in 1 day. | 23/47/90 | 1000.0 |
| place_sellergmv_1d | double | - | 9/14/25 | 10898.91 |
| ads_place_sellergmv_1d | double | - | 9/14/25 | 4335.0 |
| organic_place_sellergmv_1d | double | - | 9/14/25 | 10898.91 |
| place_sellergmv_usd_1d | double | - | 9/14/25 | 8620.8503065058 |
| ads_place_sellergmv_usd_1d | double | - | 9/14/25 | 3428.910421245 |
| organic_place_sellergmv_usd_1d | double | - | 9/14/25 | 8620.8503065058 |
| impr_cnt_1d | bigint | The `impr_cnt_1d` column represents the sum of all cards impressions in 1 day. | 4328/6858/13161 | 8280 |
| impr_ads_cnt_1d | bigint | The `impr_ads_cnt_1d` column represents the count of all cards impressions for advertised items in 1 day. | 2423/3515/6014 | 194 |
| impr_organic_cnt_1d | bigint | The `impr_organic_cnt_1d` column represents the sum of all cards impressions on non-advertised items in 1 day. | 1786/3735/7840 | 8280 |
| click_cnt_1d | bigint | The `click_cnt_1d` column represents the count of all cards and button clicks in 1 day. | 3879/5842/10277 | 191 |
| click_ads_cnt_1d | bigint | The `click_ads_cnt_1d` column records the sum of all cards clicks on advertised items in 1 day. | 745/1393/2901 | 75 |
| click_organic_cnt_1d | bigint | The `click_organic_cnt_1d` column represents the sum of all cards and button clicks on non-advertised items in 1 day. | 1727/3539/7299 | 191 |
| local_hour | int | The `local_hour` column represents the hour of the day in the local timezone. | 16/28/55 | 23 |
| regional_date | date | The `regional_date` column records the date in Singapore timezone. | 457/903/1894 | 2026-03-29 |
| regional_hour | int | The `regional_hour` column represents the hour of the day in the Singapore Time timezone. | 13/18/29 | 23 |
| grass_region | string | Partition@The `grass_region` column specifies the region where the traffic/order events happened. | 11004/20265/41634 |  |
| local_date | date | Partition@The `local_date` column represents the date in local timezone. | 10875/20024/41129 |  |
