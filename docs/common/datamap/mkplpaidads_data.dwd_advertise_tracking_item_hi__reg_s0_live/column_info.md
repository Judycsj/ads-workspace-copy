<!-- ads-workspace-gdoc-sync: gdoc_id=1JLSZMr0266gFbyJo9_iKjxh3aVvwFktX9T0Kil4ai5o gdoc_url=https://docs.google.com/document/d/1JLSZMr0266gFbyJo9_iKjxh3aVvwFktX9T0Kil4ai5o/edit -->

# Columns: mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | IMPRESSION |
| operation | 2 | CLICK |
| operation | 3 | VIEW |
| operation | 4 | ADD_TO_CART |
| operation | 5 | PLACE_ORDER |
| operation | 6 | CLOSE_BANNER |
| operation | 7 | REPORT_DISLIKE |
| operation | 8 | REPORT_INAPPROPRIATE |
| operation | 9 | REPORT_IRRELEVANT |
| operation | 10 | REPORT_IMPRESSION |
| operation | 1001 | SHOP_IMPRESSION |
| operation | 1002 | SHOP_CLICK |
| platform | 1 | IOS_WEB |
| platform | 2 | IOS_APP |
| platform | 3 | ANDROID_WEB |
| platform | 4 | ANDROID_APP |
| platform | 5 | PC_MALL |
| platform | 6 | IOS_LITE |
| platform | 7 | ANDROID_LITE |
| platform | 8 | PLATFORM_RESERVED |
| platform | 9 | ANDROID_APP_LITE |
| platform | 99 | XIAPI |
| platform | 128 | OTHERS |
| bz_type | 'Search' | placement in (0, 29) |
| bz_type | 'Discovery' | placement not in (0, 29) |
| ads_entrance | 1 | Search |
| ads_entrance | 3 | Discovery (DD) |
| ads_entrance | 4 | YMAL |
| ads_entrance | 7 | Game Ads |
| ads_entrance | 8-11 | Cart Unify |
| ads_entrance | 23 | Search (variant) |
| ads_entrance | 25,30,31,32 | Discovery (variants) |
| ads_entrance | 51 | YMAL (variant) |
| ads_entrance | 14-22,26,41,43 | Game Ads (variants) |

### 常见 WHERE 值 (Common Filter Values)

- `operation`: 多数查询用 `IN (1, 2, 5)` (Imp/Click/Order) 或 `= 2` (Click only)
- `fraud_type`: `= ''` 排除欺诈记录
- `duplicate_label`: `IS NULL` 排除重复事件
- `pricing_type`: `IN (11, 15)` for ROI/OCPM; `IN ('9','10','14')` for Live Ads
- `ads_id`, `user_id`, `item_id`, `shop_id`: `> 0` 过滤无效记录
- `grass_region`: 标准 8 区 `('ID','MY','PH','SG','TH','TW','VN','BR')`

### 价格字段注意事项

- `item_price`: 已除以 100000，单位为当地货币
- `add_cart_item_price`: 已除以 100000
- `internal.deduction_info.bidprice`: 已除以 100000
- `internal.deduction_info.deduction_price`: 已除以 100000
- `product_card` 中的价格字段 (price, price_max, price_min 等): 已除以 100000
- `item_json_data` 中的 `$.item_price`: 原始值，需手动除以 100000
- `bid_rerank_trace` 中的 `$.pgmv`, `$.mpc_e_cost`, `$.mpc_e_gmv`: 原始值，需手动除以 100000

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | - [PARTITION] | 9196/18465/40240 |  |
| 2 | grass_region | varchar(10) | Country the tracking information belong to [PARTITION] | 8507/16895/36948 |  |
| 3 | item_id | bigint | ID of item | 7601/15159/33124 | 58157667119 |
| 4 | ads_id | bigint | ID of the advertisement | 7293/14500/31865 | 98346496 |
| 5 | user_id | bigint | ID of each user | 7373/14774/31667 | 8589268992 |
| 6 | ads_placement | bigint | ads_placement | 5994/11983/26474 | 50 |
| 7 | ads_entrance | string | Ads traffic entrance | 5982/11944/26462 | 9 |
| 8 | item_json_data | string | Item information with json format | 6042/12061/26347 | {} |
| 9 | ads_request_id | string | When a request hits ads system, ads will check whether this request could be fulfilled by an earlier response in the cache. | 6114/12129/25817 | fff852cd4dd166871b9b7b4790096800 |
| 10 | h | int | - [PARTITION] | 5645/11565/25430 |  |
| 11 | operation | bigint | User behavior Impression:1 Click:2 View:3 AddToCart:4 PlaceOrder:5 ShopImpression:1001 ShopClick:1002 | 5683/11397/25381 | 23 |
| 12 | pricing_type | string | Advertising pricing type | 5800/10473/21692 | 29 |
| 13 | item_price | decimal(25,10) | item_price (devided by 100000) | 4941/9806/20833 | 12642.49984 |
| 14 | sub_entrance | bigint | Indicates the source of advertising traffic | 4818/9534/20224 | 410104 |
| 15 | internal | struct | Advertisement click deduction information | 4286/8690/19540 | {"deduction_info":{"quality":null,"bidprice":null,"next_score":null,"next_ads_id":null,"next_ads_keyword":null,"algo_name":null,"boost_status":null,"deduction_price":null,"ads_id":null,"placement":null}} |
| 16 | shop_id | bigint | ID of item's shop | 4440/8906/19181 | 1783198928 |
| 17 | timestamp | bigint | unix timestamp when a tracking event is generated from FE | 4276/8513/19172 | 1774414799 |
| 18 | campaign_id | bigint | deprecated | 3864/7657/17187 | 53328005 |
| 19 | query | struct | User search information(Search terms, price ranges, etc.) PS:itemid and shopid are for discovery ads | 3883/7833/16804 | {"keyword":null,"sorttype":null,"colorful_blocks":[],"filter_price_min":null,"filter_price_max":null,"filter_include_sf":null,"filter_with_discount":null,"filter_attribute":null,"filter_item_condition":null,"filter_user_verified":null,"filters":null,"item_id":0,"shop_id":0} |
| 20 | v_item_id | bigint | virtual item id | 3750/7551/16164 | NULL |

### 查询频率分析

Top 20 高频字段呈现以下特征：

- **分区键主导**：`grass_date`、`grass_region`、`h` 三个分区列查询量最高（L30D 25K-40K），几乎所有查询都需要指定分区条件；`bz_type` 分区列查询量相对较低（L30D 7.3K），说明部分查询不按业务类型筛选
- **广告与商品核心实体**：`item_id`（33K）、`ads_id`（31K）、`user_id`（31K）是最高频的数据列，反映该表以用户-广告-商品三元组为核心分析维度
- **流量来源与入口**：`ads_placement`（26K）、`ads_entrance`（26K）、`sub_entrance`（20K）查询量集中，用于分析广告流量的入口分布和来源拆分
- **行为与扣费类**：`operation`（25K）记录用户行为类型（曝光/点击/加购/下单），`pricing_type`（21K）和 `internal`（19K）用于分析计费方式和扣费明细
- **搜索与请求上下文**：`item_json_data`（26K）、`ads_request_id`（25K）、`query`（16K）等字段用于追踪请求链路和搜索上下文
- **商业价值字段**：`item_price`（20K）、`campaign_id`（17K）、`shop_id`（19K）用于关联商品价格、广告计划和店铺维度的分析
- **虚拟商品支持**：`v_item_id`（16K）进入 Top 20，反映虚拟商品（virtual item）在广告追踪中的重要性

> MAX(column): MAX() aggregated values from grass_date=2026-03-25, grass_region=SG, h=12 (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| user_id | bigint | ID of each user | 7373/14774/31667 | 8589268992 |
| session_id | string | ID of user session | 493/1111/2309 | zzy0vrul8x2P746ABD9kkHs5hwK/0SUy+XS+0sseIZcABHmYz48A9SFDNbj2BkkLcLNVxoW0ITOR3ot3VEDWwble2+J1AJO20nF1Y0af+87AWgMsAiRro8QmgKHYGdlvpn+Ba8SPHykOhwnQkUULprb5bObLAuXL1Se9DTLG0IE= |
| device_id | string | ID of user device | 3438/6925/14865 | zz0aGs1aG2ge8X4y16M11uhAKOjp12D0 |
| client_ip | string | ID of user client | 3255/6570/14094 | 99.247.41.85, 10.188.14.139 |
| platform | bigint | User platform type | 314/669/1469 | 128 |
| timestamp | bigint | unix timestamp when a tracking event is generated from FE | 4276/8513/19172 | 1774414799 |
| token | string | a pair of data with sessionid,used to verify the request currently FE get from cookies (SPC_R_T_IV) | 52/153/324 | zA+6CS84nrwvqloS5kBRFQ== |
| source | string | tracking may come from coreserver and client, this field is filled by tracking server | 52/145/313 | rw |
| item_id | bigint | ID of item | 7601/15159/33124 | 58157667119 |
| shop_id | bigint | ID of item's shop | 4440/8906/19181 | 1783198928 |
| discount | bigint | a deduction from the usual price of something. | 52/145/313 | 100 |
| is_free_shipping | int | Is the product free shipping FALSE:0 TRUE:1 | 52/145/313 | 1 |
| is_prefered | int | Whether shop is displayed first | 52/145/313 | 1 |
| algorithm | string | deprecated | 52/145/313 |  |
| organic_location | bigint | index of this item among the whole list (including all organic and ads)，index start from 0 | 3539/7109/15204 | 1141 |
| refer_urls | array | refer_urls | 52/145/313 | [] |
| item_model_id | bigint | Model ID of item(SKU level) | 52/145/313 | NULL |
| list_type | string | User behavior type (category, collection, search or recommend) | 206/453/973 | search |
| ads_id | bigint | ID of the advertisement | 7293/14500/31865 | 98346496 |
| location_in_ads | bigint | index of this item among the ads item index start from 0 | 3349/6793/14505 | 555 |
| campaign_id | bigint | deprecated | 3864/7657/17187 | 53328005 |
| ads_keyword | string | Query keyword for search ads | 3237/6529/13998 | 黑醋 |
| match_type | bigint | Search keyword match type KW_EXACT_MATCH = 0;  KW_PHRASE_MATCH = 1; | 3069/6193/13276 | 1 |
| query | struct | User search information(Search terms, price ranges, etc.) PS:itemid and shopid are for discovery ads | 3883/7833/16804 | {"keyword":null,"sorttype":null,"colorful_blocks":[],"filter_price_min":null,"filter_price_max":null,"filter_include_sf":null,"filter_with_discount":null,"filter_attribute":null,"filter_item_condition":null,"filter_user_verified":null,"filters":null,"item_id":0,"shop_id":0} |
| abtest_sign | string | abtest signature | 59/159/343 | {"request_id":"b11ba3af4dd223c319ae548d15703900","item_cat_id":null,"best_match_key":"","recall_score_list":[{"recall_level":4,"score":0}],"coarse_rank_score":null,"re_rank_score":null,"item_similarity":null,"is_ads":true,"ctr_score":null,"cvr_score":null} |
| item_json_data | string | Item information with json format | 6042/12061/26347 | {} |
| tracking_json_data | string | Tracking information from ads_tracking(different from item's tracking ) | 3283/6757/14392 | {} |
| ads_request_id | string | When a request hits ads system, ads will check whether this request could be fulfilled by an earlier response in the cache. | 6114/12129/25817 | fff852cd4dd166871b9b7b4790096800 |
| fe_ab_sign | string | Front abtest signature this field is only used for storing the A/B result of FE side, for BE pls use ab_sign | 52/145/313 | 0.b.10747@VFUG1RQ4GP5 |
| add_cart_item_amount | bigint | Add to cart item quantity | 59/159/343 | 1840 |
| add_cart_item_price | decimal(25,10) | Add to cart item price (devided by 100000) | 59/159/343 | 100000.0 |
| product_card | struct | the display info about the product_card refer to https://confluence.shopee.io/x/p7fPBg | 52/145/313 | {"campaign_label_ids":null,"has_video":1,"item_discount":null,"shop_type":null,"is_service_by_shopee":1,"image_flag_ids":null,"price_before_discount":null,"price_max_before_discount":null,"price_min_before_discount":null,"price":null,"price_max":null,"price_min":null,"bundle_deal_label":null,"is_wholesale":1,"addon_deal_label":null,"is_cashback":1,"is_groupbuy":1,"other_promotion_label_id":null,"rating_star":null,"rating_star_rounded":null,"sold_count":null,"is_free_shipping":1,"other_icon_in_price_id":null,"is_sold_out":1} |
| raw_request_id | string | Raw request ID is generated from BFF, upon each new request. refer to https://confluence.shopee.io/x/6ZLmg | 3667/7454/15859 | fffd1e194dd1cf575685ec57dda02b00 |
| organic_request_id | string | ID of request in organic refer to https://confluence.shopee.io/x/6ZLmg | 1065/2165/4670 | fff852cd4dd166871b9b7b4790096800 |
| internal_label | struct | Including deduplication labels/fraud labels, which are generated by tracking. | 179/399/868 | {"frauds":[{"fraud_type":"OneAccOneAdsOneDayFourTimes"}],"sessionid":null,"adsinfo_extract_label":null,"dfp_device_id":null,"risk_tags":[]} |
| ads_entrance | string | Ads traffic entrance | 5982/11944/26462 | 9 |
| tracking_placement | bigint | Tracking_placement is the traffic source field reported by the front end, which corresponds to entrance one by one. | 529/1102/2464 | 3339 |
| inner_placement | bigint | Inner_placement is a field of our commonly used strategy. | 52/145/314 | 50 |
| ads_placement | bigint | ads_placement | 5994/11983/26474 | 50 |
| internal | struct | Advertisement click deduction information | 4286/8690/19540 | {"deduction_info":{"quality":null,"bidprice":null,"next_score":null,"next_ads_id":null,"next_ads_keyword":null,"algo_name":null,"boost_status":null,"deduction_price":null,"ads_id":null,"placement":null}} |
| operation | bigint | User behavior Impression:1 Click:2 View:3 AddToCart:4 PlaceOrder:5 ShopImpression:1001 ShopClick:1002 | 5683/11397/25381 | 23 |
| pricing_type | string | Advertising pricing type | 5800/10473/21692 | 29 |
| operation_desc | string | operation_desc | 2688/5300/11090 | VIEW |
| platform_desc | string | platform_desc | 3069/6193/13276 | PC_MALL |
| tracking_queue_name | string | the name of the recall queue | 52/145/313 | NULL |
| fraud_type | string | fraud_type | 447/909/2155 | 9,11 |
| search_page_sort_type | bigint | search result page sort type that user selected | 52/145/313 | 13 |
| matched_premium_segments | string | segment info | 52/145/313 | NULL |
| ab_sign | string | ab_sign | 3627/7266/15381 | &#124;new_ab_sign&#124;664941&#124;664905&#124;544551&#124;593627&#124;658114&#124;644467&#124;442643&#124;659409&#124;544561&#124;661593&#124;655639&#124;556607&#124;650066&#124;554795&#124;657847&#124;573839&#124;526514&#124;663179&#124;608999&#124;654726&#124;596754&#124;626801&#124;532359&#124;634228&#124;660322&#124;656537&#124;600405&#124;663698&#124;660900&#124;658395&#124;663560&#124;661449&#124;663537&#124;656435&#124;597098&#124;648164&#124;613422&#124;662987&#124;603331&#124;609304&#124;652595&#124;657512&#124;651407&#124;663195&#124;578877&#124;658142&#124;661948&#124;661587&#124;538754&#124;663167&#124;662726&#124;663130&#124;657609&#124;650907&#124;618376&#124;663441&#124;544504&#124;565122&#124;663918&#124;660045&#124;657559&#124;656514&#124;602923&#124;640460&#124;565080&#124;527429&#124;653627&#124;663552&#124;613859&#124;569040&#124;505790&#124;620213&#124;609138&#124; |
| app_ver | string | app_version | 3076/6215/13353 | 37104 |
| rn_ver | string | react native version | 3076/6215/13359 | 6097005 |
| view_session_id | string | A unique view_session_id will be generated during page initialization | 59/159/343 | fzzxH2R47D8QWeiu/Y1xZGII3/p2jBknJMjdZMAsfmE=-1774412899372 |
| sub_entrance | bigint | Indicates the source of advertising traffic | 4818/9534/20224 | 410104 |
| dfp | string | device fingerprint, use for fraud analyse | 59/159/344 | zzzx2jkxqjFzcs5VzltT5g==&#124;v0FeRMbtRI6bvXs/oxbsInz01q3DGRoggRYO9QwEC0t8PKJWlbKwApHWnfw38OZ/FAxIMzTpygThjadjMN/o4Q==&#124;c2TeL3jEhTt1h/Kf&#124;08&#124;1 |
| click_area | int | click_area | 3069/6193/13276 | 5 |
| display_video_id | bigint | display_video_id | 52/145/313 | NULL |
| ta_group_id | bigint | target audience group id | 3069/6193/13276 | NULL |
| ta_matched_tag_ids | array | unique identifier of when the advertisement hits the intended target audience group | 3069/6193/13276 | NULL |
| ta_premium_rate | bigint | the premium rate when the advertisement matches the target audience group of people | 3069/6193/13276 | NULL |
| vv_id | string | video view id | 52/145/313 | :rUVD7lNuCAAvhz1bAAAAAA==:content_mix_feed:19d232f8181 |
| sdk_version | string | sdk_version | 52/145/313 | 2.2.5,2.2.6,SPC_T |
| sdk_type | string | sdk_type | 52/145/313 | ios |
| page_type | string | page_type ( image_search、search、shop、me etc.) | 3312/6661/14278 | ymal_cart_landing |
| page_section | string | page_section (search、rcmd、search、you_may_also_lick etc.) | 3117/6273/13505 | you_may_also_like |
| target_type | string | target_type ( item etc. ) | 3110/6277/13510 | video_product_impression |
| sort_by | string | sorting method, fro instance price、sales、relevancy、ctime、pop. | 3077/6214/13318 | sales |
| scenario | string | search scenario eg:PAGE_GLOBAL_SEARCH, PAGE_PDP_SEARCH, PAGE_PREFILL_SEARCH.. | 3069/6193/13276 | PAGE_VOUCHER_SEARCH |
| search_entrance | string | search_entrance, the entrance to search scenario | 3069/6193/13276 | voucher_search_bar |
| search_mid | string | Search middle page  eg: sdp_history, sdp_prefill, sup_history, sup_query_suggest... | 3069/6193/13276 | voice_search |
| search_session_id | string | unique search ID in the search results page | 3239/6583/14059 | ss-fffb16ca-8bff-4185-ba65-26975876d2fd |
| global_session_id | string | unique global search ID | 222/535/1096 | gs-fffd0608-92c8-4c90-9013-b25cc610b479 |
| current_page | string | current_page eg content_mix_feed、common_video_trending_page、dd_video_new_landing_page | 224/494/1116 | trending_page |
| content_type | string | content_type eg shopee_video、item | 52/145/313 | top_section |
| content_id | string | content_id | 52/145/313 | zzpfzwYAAAAcwh4OAAAAAA== |
| trigger_mode | string | trigger_mode eg anchor_product、comment_product | 52/145/313 | profile_product |
| sv_source_page | string | sv_source_page eg video_tab、iaa_srp_video_card、app_auto_streaming | 52/145/359 | whatsapp |
| display_ad_tag | int | if display ads tag | 3167/6389/13776 | 2 |
| card_type | string | card type of the DD card | 74/167/335 | video |
| video_id | string | video_id | 52/145/358 | zwctbvbRCAAVBsrAAQAAAA== |
| be_ab | array | be abtest signature | 52/147/315 | [] |
| item_price | decimal(25,10) | item_price (devided by 100000) | 4941/9806/20833 | 12642.49984 |
| target_cir | double | target cost-Income Ratio, can be customized by the user | 3290/6607/14157 | 2.040816307067871 |
| sold_cnt_per_order | bigint | deprecated (using item_price) | 139/304/641 | NULL |
| duplicate_label | int | DuplicateType | 412/850/1987 | 7 |
| click_event_id | string | click_event_id | 59/164/351 | fffffada-b0cd-4fb4-8c24-799edf1338d6 |
| sold_cnt_per_order_double | double | deprecated (using item_price) | 55/148/316 | NULL |
| bid_deduction_price | bigint | bid_deduction_price | 448/986/2275 | 978000 |
| new_product_boost_stage | int | new_product_boost_stage | 3156/6352/13605 | 2 |
| item_voucher | struct | the info about item_voucher,incuding display_ads_voucher_label、promotion_id etc. | 1625/3143/6423 | {"display_ads_voucher_label":null,"best_vouchers":[{"promotion_id":928495719399424,"voucher_code":"LISA1011","voucher_discount":null,"minimum_spend":null,"voucher_valid_start_time":null,"voucher_valid_end_time":null,"groups":[],"is_auto_claimed_just_now":false},{"promotion_id":1382661377892360,"voucher_code":"SV1382661377892360","voucher_discount":null,"minimum_spend":null,"voucher_valid_start_time":null,"voucher_valid_end_time":null,"groups":["SG REG Smart Voucher","Reg Smart Voucher"],"is_auto_claimed_just_now":null}],"initial_price":33233000,"final_price":7209000} |
| bid_voucher_id | bigint | voucher id in ads bidding | 3388/6791/14527 | 1382957931700224 |
| voucher_deduction_price | bigint | voucher_deduction_price=deduction_price-deduction_price_0 | 3156/6352/13605 | NULL |
| is_auto_claimed_just_now | tinyint | if ads voucher been just auto claimed | 318/670/1434 | 1 |
| is_roi3_best_voucher | tinyint | if groups contain 'ADS-ROI' | 66/173/374 | 1 |
| v_model_id | bigint | virtual model id | 3077/6204/13289 | NULL |
| v_item_id | bigint | virtual item id | 3750/7551/16164 | NULL |
| ctx_item_type | int | 1-real item; 2-virtual item | 3743/7537/16157 | 1 |
| algo_json_data | string | include algo team params | 1768/3430/7194 | {"entrance_group_idx":39} |
| unique_id | string | tms unique_id | 3069/6194/13322 | fzxrDAlYIcB1RRoR1mR5RDHDUEnj0Lcgaw7pp9k3iOE=-ymal-995582-1774412348543-25683917023 |
| event_timestamp | bigint | event_timestamp | 78/171/341 | NULL |
| sequence_id | string | sequence_id | 52/145/313 | NULL |
| bid_rerank_trace | string | Used to record some intermediate field values generated by online bidding | 2679/5161/11372 | {   "shop_pgmv_7d": -0.0,   "pctr_0": 0.08260556310415268,   "pcr_0": 0.0109322652220726,   "is_roi3": true,   "voucher_unpicked_reason": "997",   "uplift_model_score_str": "0.000000,1.000000,1.000000,1.000000,1.000000,1.000000,1.000000",   "shop_pay_pgmv": -0.0,   "feedback_ratio_1h": 0.7,   "feedback_ratio_3h": 0.8,   "feedback_ratio_24h": 0.9,   "feedback_ratio_72h": 0.95,   "pctr": 0.08260556310415268,   "uplift_pctr_ratio1": 1.0,   "uplift_pctr_ratio2": 1.0,   "uplift_pctr_ratio3": 1.0,   "uplift_pctr_ratio4": 1.0,   "uplift_pctr_ratio5": 1.0,   "uplift_pctr_ratio6": 1.0,   "uplift_pcr_ratio1": 1.0,   "uplift_pcr_ratio2": 1.0,   "uplift_pcr_ratio3": 1.0,   "uplift_pcr_ratio4": 1.0,   "uplift_pcr_ratio5": 1.0,   "uplift_pcr_ratio6": 1.0,   "crv_cali_coef": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0] } |
| uni_pcr_model_name | string | The model name of uni cr | 1762/3418/7076 | gpu_pgmv_uni_L2_atc_v2 |
| item_price_shop | double | The estimated value of model, the average price of items in the shop (Divide by 100000) | 1639/3169/6576 | 15057.67098 |
| avg_sold_cnt_shop | double | The estimated value of model, the average sold cnt of items in the shop | 1644/3174/6583 | 949.155517578125 |
| avg_sold_cnt_item | double | The estimated value of model, the average sold cnt of items | 1644/3194/6650 | 54.20766830444336 |
| is_ocpm | boolean | - | 152/342/695 | true |
| attribute_reason | int | - | 52/149/317 | 5 |
| model_id | bigint | - | 60/153/162 | 445681271343 |
| rsku_list_infos_json | string | - | 52/145/154 | [] |
| is_preselected_vmodel | boolean | - | 52/145/154 | NULL |
| grass_region | varchar(10) | Country the tracking information belong to [PARTITION] | 8507/16895/36948 |  |
| grass_date | date | - [PARTITION] | 9196/18465/40240 |  |
| h | int | - [PARTITION] | 5645/11565/25430 |  |
| bz_type | varchar(20) | - [PARTITION] | 1665/3429/7277 |  |
