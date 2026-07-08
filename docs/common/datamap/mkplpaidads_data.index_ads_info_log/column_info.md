<!-- ads-workspace-gdoc-sync: gdoc_id=1pE18VYlHKfvhrINNIYwJMW7RWF1TZVGQrXU3_aqfhpM gdoc_url=https://docs.google.com/document/d/1pE18VYlHKfvhrINNIYwJMW7RWF1TZVGQrXU3_aqfhpM/edit -->

# Columns: mkplpaidads_data.index_ads_info_log

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `dt`: Date string, almost always used as partition filter (e.g., `dt = '2026-03-25'`)
- `country`: Standard 8 regions -- `'ID','MY','PH','SG','TH','TW','VN','BR'`. Most queries filter to subset.
- `h`: Hour int (0-23). UTC+0 regions use directly; UTC+7/8 regions need timezone adjustment.
- `placement`: `40` (Search Ads, ~70% of queries), `100` (Discovery Ads). Critical for scoping to specific ad types.
- `advertisement.pricing_type`: `4` (Simple), `11` (Target ROI2), `15` (Simple ROI2). Used to filter by pricing model.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 40 | Search Ads |
| placement | 100 | Discovery Ads |
| advertisement.pricing_type | 4 | Simple |
| advertisement.pricing_type | 11 | Target ROI2 |
| advertisement.pricing_type | 15 | Simple ROI2 |
| advertisement.ad_tag (bitmask bits) | bit 31 | Empty spend flag |
| advertisement.ad_tag (bitmask bits) | bit 34 | Cold start flag |
| advertisement.ad_tag (bitmask bits) | bit 50 | NPB (New Product Boost) break-even |
| advertisement.ad_tag (bitmask bits) | bit 53 | New advertiser ads flag |
| bid_strategy.bid_type | 0 | Default (no strategy) |

### 时区处理 (Timezone Handling)

- UTC+0 regions (SG, MY, PH, TW): `TO_DATE(dt)` directly maps to `grass_date`
- UTC+7/8 regions (ID, TH, VN): `h=0` belongs to previous calendar day, use `DATE_ADD(TO_DATE(dt), CASE WHEN h=0 THEN -1 ELSE 0 END)`

### Struct 字段说明

该表为 Hudi MOR 表，大部分核心信息存储在嵌套 struct 中：

| Struct Column | Key Sub-Fields | Usage |
|---------------|---------------|-------|
| `advertisement` | `pricing_type`, `ad_tag`, `plan_bucket_list`, `ads_first_delivery_time`, `level`, `cold_start_flag` | Ad entity attributes and status |
| `bid_strategy` | `target_roi`, `bid_type`, `idx_roi_upper_bound`, `sug_roi_lower_bound`, `sug_roi_upper_bound` | Bidding parameters |
| `campaign` | `daily_budget`, `start_time`, `end_time`, `target_roi`, `total_budget`, `expense_mtime` | Campaign budget and settings |
| `account` | `balance`, `campaign_surge`, `is_roi_3_voucher_enabled` | Account-level flags |
| `item` | `item_id`, `title`, `min_price`, `global_cat_ids`, `fe_cat_ids`, `is_deboosted` | Item/product attributes |
| `shop` | `rating`, `is_cross_broder`, `is_blacklisted_for_roi_3_voucher` | Shop-level flags |
| `traffic_control` | `anti_fraud_block_probabilities`, `deboost_probabilities`, `over_delivery` | Traffic quality signals |
| `video_ads` | `post_id`, `video_item` | Video/Live ad metadata |
| `live_stream_ads` | `session_id`, `cpm`, `campaign_slots`, `session_start_ts` | Live stream session info |
| `voucher` | `discount_list_v1`, `discount_list_v2`, `roi_3_voucher_list` | Voucher/discount config |
| `brand_search_ads` | `keywords`, `keyword_groups`, `template`, `landing_page` | Brand search ad config |
| `brand_max_ads` | *(brand max campaign info)* | Brand Max ad config |

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | dt | string | - [PARTITION] | 11971/22929/38780 |  |
| 2 | h | int | - [PARTITION] | 11417/21664/36042 |  |
| 3 | country | string | - [PARTITION] | 11962/21820/35787 |  |
| 4 | placement | bigint | - | 11303/21193/33918 | 2030 |
| 5 | ads_id | bigint | - | 11253/20575/33462 | 98342012 |
| 6 | advertisement | struct | - | 11343/20564/32983 | {"ad_tag":null,"ads_creative":null,"ads_first_delivery_time":null,"attr_query_blacklist":null,"bid_infos":null,"bid_price":null,"cold_start_flag":null,"cpa":null,"cpm":null,"ctime":null,"delivery_time":null,"entrance":null,"first_delivery_time":null,"good_potential_product":null,"level":null,"plan_bucket_list":[413,421],"pricing_type":4} |
| 7 | item_id | bigint | - | 11037/19978/31720 | 58157661054 |
| 8 | campaign_id | bigint | - | 430/1214/2261 | 53328005 |
| 9 | shop_id | bigint | - | 414/1107/1906 | 1782542494 |
| 10 | bid_strategy | struct | - | 305/860/1787 | {"aov":null,"bid_type":0,"campaign_idx_roi_upper_bound":null,"campaign_surge_explore_roi_ratio_roi_two":null,"campaign_surge_explore_roi_ratio_simple_roi_two":null,"campaign_target_roi":null,"cpv":null,"ecr":null,"hit_experiment":null,"idx_roi_upper_bound":null,"initial_bid":null,"initial_coef":null,"rapid_boost_explore_roi_ratio":null,"sug_roi_lower_bound":0,"sug_roi_upper_bound":0,"target_roi":null} |
| 11 | ads_account_id | bigint | - | 348/954/1722 | 8572049859 |
| 12 | video_ads | struct | - | 353/820/1478 | {"post_id":2575074666611838,"video_item":{"category_order_count":{"avgsoldcntl0":1.5061026},"global_cat_ids":[100013,100075,100277],"item_id":20252693254,"price":1622000,"shop_id":133326149}} |
| 13 | account | struct | - | 421/964/1398 | {"balance":null,"campaign_surge":true,"is_roi_3_voucher_enabled":true,"pre_campaign_surge":null} |
| 14 | item | struct | - | 243/686/1139 | {"category_order_count":{"avgsoldcntl0":8.873405},"fe_cat_ids":[11000001,11011273,11011276],"global_brand":"no-brand","global_cat_ids":[100636,100711,101157],"is_deboosted":false,"item_id":55707643771,"min_price":290000,"mtext_title":"3d wall-panel wallpaper...","title":"3D Wall Panel Wallpaper..."} |
| 15 | campaign | struct | - | 255/614/931 | {"daily_budget":9000000,"end_time":9223372036854775807,"expense_mtime":1774411420,"start_time":1574265600,"target_roi":92273,"total_budget":0} |
| 16 | traffic_control | struct | - | 213/698/859 | {"anti_fraud_block_probabilities":null,"deboost_probabilities":null,"over_delivery":null} |
| 17 | visible_start_ts | bigint | - | 178/628/853 | 1774411200 |
| 18 | voucher | struct | - | 215/568/747 | {"discount_list_v1":null,"discount_list_v2":null,"roi_3_voucher_list":null} |
| 19 | live_stream_ads | struct | - | 178/470/730 | {"campaign_restart_ts":1774411946,"campaign_slots":[{"end_time":0,"start_time":0}],"cpm":0,"mcn_user_id":0,"session_id":1339150,"session_start_ts":1774411558,"target_affiliate_user_id":0,"visible_start_ts":null} |
| 20 | tracing | struct | - | 178/629/710 | {"indexer_mtime":1774412491,"trace_id":"1774412491995437121_39850647:paidads-livestreamindexer-live-global.260318160544063702.260318163222920379"} |

### 查询频率分析

Top 20 高频字段呈现以下特征：

- **分区键主导**：`dt`、`h`、`country` 三个分区列查询量最高（L30D 35K-38K），几乎所有查询都需要指定分区条件
- **广告核心实体**：`ads_id`、`placement`、`advertisement` 查询量紧随其后（L30D 32K-33K），反映该表主要用于广告维度的信息查询
- **关联维度**：`item_id`、`campaign_id`、`shop_id`、`ads_account_id` 等 ID 字段查询量在 1.7K-2.3K 之间，用于与其他表做关联
- **策略与配置类 struct**：`bid_strategy`、`campaign`、`video_ads`、`traffic_control` 等嵌套结构体查询量在 700-1800 之间，主要用于提取出价策略、投放配置等详细信息
- **低频辅助字段**：`_hoodie_*` 系列字段查询量极低（L30D ~59），仅在 Hudi 数据调试时使用

> MAX(column): MAX() aggregated values from dt=2026-03-25, country=SG, h=12 (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| _hoodie_commit_time | string | - | 7/26/59 | 20260325140306981 |
| _hoodie_commit_seqno | string | - | 7/26/59 | 20260325140306981_65_99999 |
| _hoodie_record_key | string | - | 7/26/59 | id:99999838382 |
| _hoodie_partition_path | string | - | 7/26/59 | dt=2026-03-25/h=12/country=SG |
| _hoodie_file_name | string | - | 7/26/59 | 8d086118-f67a-4dbc-923c-32f533e14b12-1_63-181-0_20260325140306981.parquet |
| __task_timestamp | bigint | - | 10/32/91 | 1774412498 |
| account | struct | - | 421/964/1398 | {"balance":null,"campaign_surge":true,"is_roi_3_voucher_enabled":true,"pre_campaign_surge":null} |
| ads_account_id | bigint | - | 348/954/1722 | 8572049859 |
| ads_id | bigint | - | 11253/20575/33462 | 98342012 |
| advertisement | struct | - | 11343/20564/32983 | {"ad_tag":null,"ads_creative":null,"ads_first_delivery_time":null,"attr_query_blacklist":null,"bid_infos":null,"bid_price":null,"cold_start_flag":null,"cpa":null,"cpm":null,"ctime":null,"delivery_time":null,"entrance":null,"first_delivery_time":null,"good_potential_product":null,"level":null,"plan_bucket_list":[413,421],"pricing_type":4} |
| bid_strategy | struct | - | 305/860/1787 | {"aov":null,"bid_type":0,"campaign_idx_roi_upper_bound":null,"campaign_surge_explore_roi_ratio_roi_two":null,"campaign_surge_explore_roi_ratio_simple_roi_two":null,"campaign_target_roi":null,"cpv":null,"ecr":null,"hit_experiment":null,"idx_roi_upper_bound":null,"initial_bid":null,"initial_coef":null,"rapid_boost_explore_roi_ratio":null,"sug_roi_lower_bound":0,"sug_roi_upper_bound":0,"target_roi":null} |
| boost_ads | struct | - | 10/126/186 | {"algo_status":0,"boost_days":null,"boost_est_views":null,"boost_id":null,"boost_price":null} |
| brand_max_ads | struct | - | 178/469/535 | NULL |
| brand_search_ads | struct | - | 178/470/536 | {"app_image_url":"sg-50009109-fa121744d7f4aecd9b3fb25ee3eced281773739309548","expansion_keywords":["ziehaflagshipstore"],"is_multiple_banners_adopted":true,"is_with_expansion_keywords":true,"keyword_groups":[{"cpm":11264015,"keywords":[{"data_source":2,"keywords":"ziehaflagshipstore"}],"kw_group_type":1}],"keywords":["zieha"],"landing_page":"https://shopee.sg/shop/877936491","template":2} |
| campaign | struct | - | 255/614/931 | {"daily_budget":9000000,"end_time":9223372036854775807,"expense_mtime":1774411420,"start_time":1574265600,"target_roi":92273,"total_budget":0} |
| campaign_id | bigint | - | 430/1214/2261 | 53328005 |
| content | struct | - | 178/626/700 | {"if_promote_others":null,"streamer_type":6,"user_type":null} |
| ext_fields | string | - | 178/320/422 | {"bidding":{"campaign_tag":1,"campaign_weekly_budget":9992475,"cpa_bid":99714,"is_auto_topup":false,"is_npa":false,"is_pay":false,"item_price_tier":1,"order_tier":3,"roi_tier":2,"target_order2pay":0.9987513893902256}} |
| item | struct | - | 243/686/1139 | {"category_order_count":{"avgsoldcntl0":8.873405},"fe_cat_ids":[11000001,11011273,11011276],"global_brand":"no-brand","global_cat_ids":[100636,100711,101157],"is_deboosted":false,"item_id":55707643771,"min_price":290000,"mtext_title":"3d wall-panel wallpaper...","title":"3D Wall Panel Wallpaper..."} |
| item_id | bigint | - | 11037/19978/31720 | 58157661054 |
| live_stream_ads | struct | - | 178/470/730 | {"campaign_restart_ts":1774411946,"campaign_slots":[{"end_time":0,"start_time":0}],"cpm":0,"mcn_user_id":0,"session_id":1339150,"session_start_ts":1774411558,"target_affiliate_user_id":0,"visible_start_ts":null} |
| new_product_boost | struct | - | 10/281/347 | {"stage":2,"tier":3} |
| placement | bigint | - | 11303/21193/33918 | 2030 |
| shop | struct | - | 178/478/545 | {"deduct_price_7d":null,"is_blacklisted_for_roi_3_voucher":false,"is_cross_broder":true,"rating":4.937354497354497} |
| shop_id | bigint | - | 414/1107/1906 | 1782542494 |
| task_time | bigint | - | 178/313/373 | 2026032512 |
| tracing | struct | - | 178/629/710 | {"indexer_mtime":1774412491,"trace_id":"1774412491995437121_39850647:paidads-livestreamindexer-live-global.260318160544063702.260318163222920379"} |
| traffic_control | struct | - | 213/698/859 | {"anti_fraud_block_probabilities":null,"deboost_probabilities":null,"over_delivery":null} |
| video_ads | struct | - | 353/820/1478 | {"post_id":2575074666611838,"video_item":{"category_order_count":{"avgsoldcntl0":1.5061026},"global_cat_ids":[100013,100075,100277],"item_id":20252693254,"price":1622000,"shop_id":133326149}} |
| visible_start_ts | bigint | - | 178/628/853 | 1774411200 |
| voucher | struct | - | 215/568/747 | {"discount_list_v1":null,"discount_list_v2":null,"roi_3_voucher_list":null} |
| id | bigint | - | 178/315/375 | 100095892610 |
| ts | bigint | - | 46/111/256 | 1774418506694 |
| dt | string | - [PARTITION] | 11971/22929/38780 |  |
| h | int | - [PARTITION] | 11417/21664/36042 |  |
| country | string | - [PARTITION] | 11962/21820/35787 |  |
