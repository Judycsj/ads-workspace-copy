<!-- ads-workspace-gdoc-sync: gdoc_id=1bcPCQiHstOmaOM2ep3LPFPOrwIwLeQQudsCiuzLkCBQ gdoc_url=https://docs.google.com/document/d/1bcPCQiHstOmaOM2ep3LPFPOrwIwLeQQudsCiuzLkCBQ/edit -->

# Columns: dev_mp_paidads.dwd_tracking_tms_request_event_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表为事件级明细表（event-level），每条记录对应一个独立的用户行为事件，不存在跨维度累加重复的问题。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | impression | 曝光事件 |
| operation | click | 点击事件 |
| operation | view | 浏览事件 |
| entrance | 1 | GLOBAL SEARCH |
| entrance | 3 | DAILY DISCOVERY |
| entrance | 4 | YMAL PDP |
| entrance | 8 | SHOPPING CART |
| entrance | 9 | ORDER SUCCESSFUL PAGES |
| entrance | 10 | ORDER DETAIL PAGE |
| entrance | 11 | MY PURCHASE PAGE |
| entrance | 23 | IMAGE SEARCH |
| entrance | 27 | LIVE STREAM DISCOVERY |
| entrance | 28 | LIVE STREAM FOR YOU |
| entrance | 29 | VIDEO FEED |
| entrance | 33 | VIDEO FEED HP |
| entrance | 34 | VIDEO FEED DISCOVERY |
| entrance | 35 | MINI FEED VIDEO |
| entrance | 37 | LS HOME CAROUSEL |
| entrance | 38 | LS PDP |
| entrance | 39 | LS AUTO LANDING |
| entrance | 40 | ME YMAL |
| entrance | 42 | LS VIDEO FEED |
| entrance | 45 | SHOP YMAL |
| entrance | 48 | LS GAME |
| entrance | 50 | KEYWORD SEARCH VIDEO FEED |
| entrance | 51 | VIDEO FEED YMAL |
| entrance | 54 | VIDEO PDP |
| entrance | 55 | VIDEO PDP WINDOW LANDING |
| entrance | 56 | MINI FEED VIDEO ADS |
| entrance | 58 | YMAL FEED VIDEO ADS |
| video_ads_type | 0 | product_ads |
| video_ads_type | 1 | video_ads |
| content_mix_frame_tab_name | 0 | UNKNOWN |
| content_mix_frame_tab_name | 1 | LiveTab |
| content_mix_frame_tab_name | 2 | ForYouTab |
| content_mix_frame_tab_name | 3 | VideoTab |
| content_mix_frame_tab_name | 4 | DiscoverTab |
| traffic_source | 0 | KW_EXACT_MATCH |
| traffic_source | 1 | KW_PHRASE_MATCH |
| is_wifi | 0 | false |
| is_wifi | 1 | true |
| is_affiliated | 0 | false |
| is_affiliated | 1 | true |
| if_mini_ls | 0 | false (非 mini 直播间) |
| if_mini_ls | 1 | true (mini 直播间) |
| platform_desc | ios_app | iOS App |
| platform_desc | android_app | Android App |
| platform_desc | ios_web | iOS Web |
| platform_desc | android_web | Android Web |
| platform_desc | pc_web | PC Web |
| platform_desc | other | 其他 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: date '${grass_date}' (全局使用), date '2025-04-20' (单日示例)
- `grass_region`: in (${grass_region}) (全局使用), 'SG' (单区示例)
- `h`: '${BIZ_H}' (INSERT 写入)
- `ads_info is not null`: 限制广告业务数据（INSERT 上游）
- `ads_id > 0`: 过滤非广告流量（dashboard 对比场景）
- `app_version`: >= '3.45.0' (新版本过滤), >= '35200' (直播场景)
- `rn_version`: >= '6.54.0' (新版本过滤), >= '6061011' (直播场景)
- `entrance`: in (37) / in (27,28,38,39,42,48) (按入口过滤)
- `platform_desc`: 'ios_app' (iOS 特殊逻辑)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| event_id | string | unique ID of each user behavior event | - | - |
| event_timestamp | bigint | event happening time set on user device. timestamp of unix | - | - |
| log_timestamp | bigint | Time when the data is logged in server | - | - |
| user_id | bigint | unique user ID | - | - |
| device_id | string | unique ID for each physical device | - | - |
| platform_desc | string | Platform: other, ios_web, ios_app, android_web, android_app, pc_web | - | - |
| platform_implementation | string | pc, android, ios, mweb, rweb, rn, h5 | - | - |
| client_ip | string | client IP address | - | - |
| is_wifi | tinyint | whether client use wifi, 1=true 0=false | - | - |
| os | string | enum: ios, android | - | - |
| os_version | string | os version from upstream | - | - |
| brand | string | client device brand | - | - |
| model | string | client device model | - | - |
| app_version | string | client app version | - | - |
| operation | string | the action of event, enum: view/impression/click_and_others | - | - |
| page_type | string | page emitted the event | - | - |
| page_section | string | position section | - | - |
| target_type | string | target type from upstream | - | - |
| session_id | string | the interval of a session is determined by client | - | - |
| sequence_id | bigint | session id in one session for the same user | - | - |
| last_view_event_id | string | event_id of the previous view page | - | - |
| data | string | business data fields, Use caution if you use this | - | - |
| rn_version | string | rn version from upstream | - | - |
| unique_id | string | unique_id (主键标识) | - | - |
| ads_operation | bigint | refer to beeshop_ads.proto | - | - |
| location | bigint | The location of the advertisement, the global location | - | - |
| location_in_ads | bigint | The location of the advertisement card | - | - |
| display_ad_tag | tinyint | Whether to display advertising logo | - | - |
| item_id | bigint | item_id | - | - |
| shop_id | bigint | shop_id | - | - |
| traffic_source | bigint | Traffic source type: 0=KW_EXACT_MATCH, 1=KW_PHRASE_MATCH | - | - |
| ab_sign | string | AB test signature | - | - |
| ads_id | bigint | ads_id | - | - |
| campaign_id | bigint | campaign_id | - | - |
| ads_keyword | string | ads_keyword | - | - |
| match_type | bigint | keyword match_type | - | - |
| placement | bigint | placement | - | - |
| ads_request_id | string | ads_request_id | - | - |
| recall_type | string | recall type (ref: tms.proto) | - | - |
| pctr | double | predict ctr | - | - |
| pcr | double | predict cr | - | - |
| query | string | User search information (Search terms, price ranges, etc.) | - | - |
| cpm_deduction_info | string | cpm_deduction_info | - | - |
| sold_cnt_per_order | double | - | - | - |
| attr_data_type | bigint | bitmask: if first bit=1, it is a boosted item | - | - |
| pricing_type | bigint | pricing type of ads | - | - |
| entrance | bigint | location of ads entries (ref: beeshop_ads.proto) | - | - |
| target_cir | double | target cost-Income Ratio | - | - |
| rank_score | double | - | - | - |
| ta_group_id | bigint | target audience group id | - | - |
| gmv_boost | double | - | - | - |
| broad_pcr | double | broad predict cr | - | - |
| ecpm_weight | double | - | - | - |
| rank | bigint | - | - | - |
| json_data | string | ads_info.item.json_data | - | - |
| dre_version | string | dre_version | - | - |
| search_session_id | string | search_session_id | - | - |
| deduction_quality | double | deduction_info.quality | - | - |
| deduction_bidprice | decimal(25,10) | deduction_info.bidprice | - | - |
| deduction_price | decimal(25,10) | deduction_info.deduction_price | - | - |
| impression_cnt | bigint | impression count (operation='impression'→1) | - | - |
| click_cnt | bigint | click count (operation='click'→1) | - | - |
| view_cnt | bigint | view count (operation='view'→1) | - | - |
| ls_session_id | bigint | live streaming room id | - | - |
| livestream_duration | bigint | duration of live streaming viewing | - | - |
| if_mini_ls | tinyint | is it a mini live streaming room | - | - |
| content_mix_frame_tab_name | bigint | 0=UNKNOWN, 1=LiveTab, 2=ForYouTab, 3=VideoTab, 4=DiscoverTab | - | - |
| is_affiliated | tinyint | - | - | - |
| video_creator_id | bigint | unique identifier of video creator | - | - |
| display_video_id_encoded | string | video id encoded, decoded via decode_video_id UDF | - | - |
| video_duration | bigint | duration of live video viewing | - | - |
| video_ads_type | bigint | 0=product_ads, 1=video_ads | - | - |
| ctx_item_type | bigint | item type | - | - |
| item_voucher | string | item voucher information (parsed struct→json) | - | - |
| v_item_id | bigint | virtual item id | - | - |
| creative_algo | bigint | - | - | - |
| creative_id | bigint | - | - | - |
| raw_request_id | string | raw request_id | - | - |
| ta_matched_tag_ids | array\<bigint\> | - | - | - |
| ta_premium_rate | bigint | - | - | - |
| search_entrance | string | fe search_params.search_entrance.entrance | - | - |
| sort_by | string | fe search_params.sort_by | - | - |
| search_mid | string | fe search_params.search_entrance.mid | - | - |
| item_price | bigint | - | - | - |
| new_product_boost_coef | double | - | - | - |
| new_product_boost_stage | bigint | - | - | - |
| bid_voucher_id | bigint | - | - | - |
| voucher_deduction_price | bigint | - | - | - |
| v_model_id | bigint | virtual model id | - | - |
| streamer_user_id | bigint | streamer_user_id | - | - |
| streamer_shop_id | bigint | streamer_shop_id | - | - |
| best_vouchers | string | best_vouchers | - | - |
| click_area | bigint | click_area | - | - |
| account_id | bigint | account_id | - | - |
| ads_operation_mapping2 | array\<int\> | ads_operation_mapping | - | - |
| sub_entrance | int | sub_entrance | - | - |
| video_shop_id | bigint | The shop id corresponding to video creator | - | - |
| rsku_list_infos | string | rsku list info (parsed struct→json) | - | - |
| image_id | string | image_id only for image search | - | - |
| candidate_box | string | candidate_box only for image search | - | - |
| l1_cat | string | l1_cat only for image search | - | - |
| keyword | string | keyword / 关键词 | - | - |
| sorttype | int | sorttype / 排序 | - | - |
| filters | string | filters / 过滤条件 (parsed struct→json) | - | - |
| view_session_id | string | only dd mixfeed | - | - |
| current_page | string | only for video | - | - |
| content_type | string | only for video | - | - |
| trigger_mode | string | only for video | - | - |
| sv_source_page | string | only for video | - | - |
| layout_type | int | Identify the layout type of the current page (only for search) | - | - |
| location_in_shop | int | only for search | - | - |
| shop_location | int | only for search | - | - |
| banner_id | bigint | A unique identifier for a banner (only display ads & brand consideration) | - | - |
| banner_source | int | only display ads & brand consideration | - | - |
| campaign_unitid | int | unique identifier of campaigns (only display ads) | - | - |
| slotid | int | position of the slot (only display ads & brand consideration) | - | - |
| image_hash | string | Take from the hash in the CDN (only display ads) | - | - |
| target_url | string | image_url (only display ads, search brand ads multi banner) | - | - |
| card_location | int | card number (only display ads) | - | - |
| banner_cnt | int | multi banner count (only display ads, search brand ads) | - | - |
| landing_url_type | int | Click landing url type of the banner (only display ads) | - | - |
| landing_page_url | string | (only display ads, search brand ads multi banner) | - | - |
| shop_recall_type | bigint | only for search brand ads, all events | - | - |
| live_duration | int | watching duration in ms (only for search brand ads live template) | - | - |
| referer_type | int | only for shop ads & search brand ads, 3-VIEW & 12-SHOP_VIEW events | - | - |
| referer_data | string | only for display ads & search brand ads, 3-VIEW & 12-SHOP_VIEW events | - | - |
| prefill_keyword | string | only for brand consideration | - | - |
| global_session_id | string | only for brand consideration | - | - |
| refer_urls | string | - | - | - |
| list_type | string | - | - |
| content_id | string | only for video | - | - |
| mapped_ads_itemid | bigint | only for roi2.0 antou live traffic | - | - |
| original_ads_itemid | bigint | only for roi2.0 antou live traffic | - | - |
| shop_voucher | string | shop_voucher (parsed struct→json) | - | - |
| json_data_original | string | original json_data from upstream | - | - |
| grass_region | string | [PARTITION] Region | - | - |
| grass_date | date | [PARTITION] Date | - | - |
| h | tinyint | [PARTITION] Hour | - | - |
