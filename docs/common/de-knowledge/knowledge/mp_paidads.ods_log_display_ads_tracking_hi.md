<!-- ads-workspace-gdoc-sync: gdoc_id=1DGON-lAeeP1BOG9cj_aI62GZWG3IY_S3ziPCeu1jFcM gdoc_url=https://docs.google.com/document/d/1DGON-lAeeP1BOG9cj_aI62GZWG3IY_S3ziPCeu1jFcM/edit -->

# mp_paidads.ods_log_display_ads_tracking_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `shopee_ads_display_ads` |
| Consumer Group | `paidads-datawarehouse-35b8d2` |
| Brokers | `kafka.ks_displayAdsTracking_live.ap-sg-1-general-a.live.mq.shopee.io:9092` |
| Proto 定义 | [ads_tracking.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/log/ads_tracking.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `Tracking`）

### Tracking（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 1 | `userid` | int64 | bigint |
| 2 | `sessionid` | string | string |
| 3 | `deviceid` | string | string |
| 4 | `client_ip` | string | string |
| 5 | `platform` | int64 | bigint |
| 6 | `operation` | int64 | bigint |
| 7 | `items` | TrackingItem | array<struct<...>> |
| 8 | `timestamp` | int64 | bigint |
| 9 | `country` | string | string |
| 10 | `token` | string | string |
| 11 | `from` | string | string |
| 12 | `shops` | TrackingShop | array<struct<...>> |
| 13 | `placement` | int64 | bigint |
| 14 | `json_data` | string | string |
| 15 | `fe_ab_sign` | string | string |
| 16 | `internal_label` | InternalLabel | struct<...> |
| 17 | `banner` | TrackingBanner | struct<...> |
| 18 | `app_ver` | string | string |
| 19 | `rn_ver` | string | string |
| 20 | `entrance` | int64 | bigint |
| 21 | `view_session_id` | string | string |
| 22 | `sub_entrance` | int64 | bigint |
| 23 | `dfp` | string | string |
| 24 | `source` | string | string |
| 25 | `livestreams` | TrackingLivestream | array<struct<...>> |
| 26 | `vv_id` | string | string |
| 27 | `sdk_version` | string | string |
| 28 | `sdk_type` | string | string |
| 29 | `page_type` | string | string |
| 30 | `page_section` | string | string |
| 31 | `target_type` | string | string |
| 32 | `search_props` | TrackingSearchProps | struct<...> |
| 33 | `video_props` | TrackingVideoProps | struct<...> |
| 34 | `referer` | TrackingReferer | struct<...> |
| 35 | `videos` | TrackingVideo | array<struct<...>> |
| 36 | `version` | string | string |
| 37 | `event_timestamp` | int64 | bigint |
| 38 | `log_timestamp` | int64 | bigint |
| 39 | `platform_implementation` | string | string |
| 40 | `sequence_id` | int64 | bigint |
| 41 | `tms_session_id` | string | string |
| 42 | `last_view_event_id` | string | string |
| 43 | `domain` | string | string |
| 44 | `type` | string | string |
| 45 | `de_device_id` | string | string |
| 46 | `exp_version` | int32 | int |
| 47 | `env` | string | string |
| 48 | `unique_id` | string | string |
| 49 | `dre_ver` | string | string |
| 50 | `livestream_props` | TrackingLivestreamsProps | struct<...> |

### TrackingItem（`items` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `itemid` | int64 | bigint |
| 2 | `shopid` | int64 | bigint |
| 3 | `discount` | int64 | bigint |
| 4 | `free_shipping` | bool | boolean |
| 5 | `is_prefered` | bool | boolean |
| 6 | `algorithm` | string | string |
| 7 | `compaignid` | string | string |
| 8 | `location` | int64 | bigint |
| 9 | `query` | TrackingQuery | struct<keyword:string,sorttype:bigint,colorful_blocks:array<string>,filter_price_min:bigint,filter_price_max:bigint,filter_include_sf:bigint,filter_with_discount:bigint,filter_attribute:bigint,filter_item_condition:bigint,filter_user_verified:bigint,filters:array<struct<match_type:bigint,match_id:array<bigint>,hashtag:array<string>>>,itemid:bigint,shopid:bigint> |
| 10 | `refer_urls` | string | array<string> |
| 11 | `item_modelid` | int64 | bigint |
| 12 | `list_type` | string | string |
| 13 | `adsid` | int64 | bigint |
| 14 | `location_in_ads` | int64 | bigint |
| 15 | `campaignid` | int64 | bigint |
| 16 | `ads_keyword` | string | string |
| 17 | `match_type` | int64 | bigint |
| 18 | `deduction_info` | string | string |
| 19 | `abtest_sign` | string | string |
| 20 | `add_cart_amount` | int64 | bigint |
| 21 | `add_cart_price` | int64 | bigint |
| 22 | `modelid` | int64 | bigint |
| 23 | `json_data` | string | string |
| 24 | `product_card` | ProductCard | struct<campaign_label_ids:array<bigint>,has_video:boolean,item_discount:bigint,shop_type:bigint,service_by_shopee:boolean,image_flag_ids:array<bigint>,price_before_discount:bigint,price_max_before_discount:bigint,price_min_before_discount:bigint,price:bigint,price_max:bigint,price_min:bigint,bundle_deal_label:string,wholesale:boolean,addon_deal_label:string,cashback:boolean,is_groupbuy:boolean,other_promotion_label_id:array<bigint>,rating_star:float,rating_star_rounded:float,sold_count:bigint,free_shipping:boolean,other_icon_in_price_id:array<bigint>,sold_out:boolean> |
| 25 | `internal` | Internal | struct<frauds:array<struct<fraud_type:string>>,deduction_info:struct<quality:double,bidprice:bigint,next_score:double,next_adsid:bigint,next_ads_keyword:string,algo_name:string,boost_status:string,deduction_price:bigint,ads_id:bigint,placement:int,bid_deduction_price:bigint>,event_id:string,cpm_deduction_info:struct<cpm:bigint,ads_id:bigint,placement:int>,duplicate_label:int,algo_json_data:string> |
| 26 | `request_id` | string | string |
| 27 | `video_id` | string | string |
| 28 | `click_area` | int32 | int |
| 29 | `item_video` | ItemVideo | struct<display_video_id:bigint,is_affiliated:boolean,video_creator_id:bigint,seller_id:bigint,display_video_id_encoded:string> |
| 32 | `display_ad_tag` | int32 | int |
| 33 | `item_rcmd_props` | TrackingItemRcmdProps | struct<card_type:string,video_id:string,be_ab:array<bigint>> |
| 34 | `target_type` | string | string |
| 35 | `traffic_source` | int32 | int |
| 36 | `item_voucher` | ItemVoucher | struct<display_ads_voucher_label:int,best_vouchers:array<struct<promotion_id:bigint,voucher_code:string,voucher_discount:bigint,minimum_spend:bigint,voucher_valid_start_time:bigint,voucher_valid_end_time:bigint,groups:array<string>,is_auto_claimed_just_now:boolean>>,initial_price:bigint,final_price:bigint> |
| 37 | `vmodelid` | int64 | bigint |
| 38 | `vitemid` | int64 | bigint |
| 39 | `ctx_item_type` | int32 | int |
| 40 | `rsku_list_infos` | RskuListinfo | array<struct<rmodel_id:bigint,ritem_id:bigint,rshop_id:bigint>> |
| 41 | `layout_type` | int32 | int |
| 42 | `location_in_shop` | int32 | int |
| 43 | `shop_location` | int32 | int |
| 44 | `mapped_ads_itemid` | int64 | bigint |
| 45 | `original_ads_itemid` | int64 | bigint |
| 46 | `unique_id` | string | string |
| 47 | `is_preselected_vmodel` | bool | boolean |
| 48 | `shop_voucher` | TrackingShopProps | TrackingShopProps |

### TrackingQuery（`items.query` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `keyword` | string |
| 2 | `sorttype` | int64 |
| 3 | `colorful_blocks` | string |
| 4 | `filter_price_min` | int64 |
| 5 | `filter_price_max` | int64 |
| 6 | `filter_include_sf` | int64 |
| 7 | `filter_with_discount` | int64 |
| 8 | `filter_attribute` | int64 |
| 9 | `filter_item_condition` | int64 |
| 10 | `filter_user_verified` | int64 |
| 11 | `filters` | TrackingFilter |
| 12 | `itemid` | int64 |
| 13 | `shopid` | int64 |
| 14 | `image_id` | string |
| 15 | `candidate_box` | string |
| 16 | `l1_cat` | string |

### ProductCard（`items.product_card` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `campaign_label_ids` | int64 |
| 2 | `has_video` | bool |
| 3 | `item_discount` | int64 |
| 4 | `shop_type` | int64 |
| 5 | `service_by_shopee` | bool |
| 6 | `image_flag_ids` | int64 |
| 7 | `price_before_discount` | int64 |
| 8 | `price_max_before_discount` | int64 |
| 9 | `price_min_before_discount` | int64 |
| 10 | `price` | int64 |
| 11 | `price_max` | int64 |
| 12 | `price_min` | int64 |
| 13 | `bundle_deal_label` | string |
| 14 | `wholesale` | bool |
| 15 | `addon_deal_label` | string |
| 16 | `cashback` | bool |
| 17 | `is_groupbuy` | bool |
| 18 | `other_promotion_label_id` | int64 |
| 19 | `rating_star` | float |
| 20 | `rating_star_rounded` | float |
| 21 | `sold_count` | int64 |
| 22 | `free_shipping` | bool |
| 23 | `other_icon_in_price_id` | int64 |
| 24 | `sold_out` | bool |

### Internal（`items.internal` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `deduction_info` | DeductionInfo |
| 2 | `frauds` | Fraud |
| 3 | `event_id` | string |
| 4 | `cpm_deduction_info` | CPMDeductionInfo |
| 5 | `duplicate_label` | int32 |
| 6 | `algo_json_data` | string |

### ItemVideo（`items.item_video` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `display_video_id` | int64 |
| 2 | `is_affiliated` | bool |
| 3 | `video_creator_id` | int64 |
| 4 | `seller_id` | int64 |
| 5 | `display_video_id_encoded` | string |

### TrackingItemRcmdProps（`items.item_rcmd_props` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `card_type` | string |
| 2 | `video_id` | string |
| 3 | `be_ab` | int64 |

### ItemVoucher（`items.item_voucher` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `display_ads_voucher_label` | int32 |
| 2 | `best_vouchers` | BestVoucher |
| 3 | `initial_price` | int64 |
| 4 | `final_price` | int64 |

### RskuListinfo（`items.rsku_list_infos` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `rmodel_id` | int64 |
| 2 | `ritem_id` | int64 |
| 3 | `rshop_id` | int64 |

### TrackingShopProps（`items.shop_voucher` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `shop_recall_type` | int64 |
| 2 | `vouchers` | ShopADVoucher |

### TrackingShop（`shops` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `shopid` | int64 | bigint |
| 2 | `query` | TrackingQuery | struct<keyword:string,sorttype:bigint,colorful_blocks:array<string>,filter_price_min:bigint,filter_price_max:bigint,filter_include_sf:bigint,filter_with_discount:bigint,filter_attribute:bigint,filter_item_condition:bigint,filter_user_verified:bigint,filters:array<struct<match_type:bigint,match_id:array<bigint>,hashtag:array<string>>>,itemid:bigint,shopid:bigint> |
| 3 | `algorithm` | string | string |
| 4 | `location` | int64 | bigint |
| 5 | `refer_urls` | string | array<string> |
| 6 | `list_type` | string | string |
| 7 | `json_data` | string | string |
| 8 | `internal` | Internal | struct<frauds:array<struct<fraud_type:string>>,deduction_info:struct<quality:double,bidprice:bigint,next_score:double,next_adsid:bigint,next_ads_keyword:string,algo_name:string,boost_status:string,deduction_price:bigint,ads_id:bigint,placement:int,bid_deduction_price:bigint>,event_id:string,cpm_deduction_info:struct<cpm:bigint,ads_id:bigint,placement:int>,duplicate_label:int> |
| 9 | `click_area` | int64 | bigint |
| 10 | `items` | ShopADItem | array<struct<itemid:bigint>> |
| 11 | `vouchers` | ShopADVoucher | array<struct<invalid_code:bigint,status_code:bigint,voucher:struct<user_id:bigint,create_time:bigint,promotion_id:bigint,voucher_code:string,voucher_market_type:bigint,use_type:bigint,reward_type:bigint,shop_id:bigint,min_spend:bigint,discount_info:struct<value:bigint,percentage:bigint,cap:bigint>,coin_cashback_info:struct<percentage:bigint,cap:bigint>>>> |
| 12 | `ls_session_id` | int64 | bigint |
| 13 | `target_type` | string | string |
| 14 | `shop_recall_type` | int64 | bigint |
| 15 | `duration` | int32 | int |
| 16 | `unique_id` | string | string |
| 17 | `shop_banners` | TrackingShopBanner | array<struct<banner_cnt:int,landing_url_type:int,target_url:string,landing_page_url:string,location:int |
| 18 | `display_video_id_encoded` | string | string |
| 19 | `landing_url_type` | int32 | int |
| 20 | `landing_page_url` | string | string |
| 21 | `material_ratio` | string | string |
| 22 | `location_type` | int32 | int |

### TrackingQuery（`shops.query` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `keyword` | string |
| 2 | `sorttype` | int64 |
| 3 | `colorful_blocks` | string |
| 4 | `filter_price_min` | int64 |
| 5 | `filter_price_max` | int64 |
| 6 | `filter_include_sf` | int64 |
| 7 | `filter_with_discount` | int64 |
| 8 | `filter_attribute` | int64 |
| 9 | `filter_item_condition` | int64 |
| 10 | `filter_user_verified` | int64 |
| 11 | `filters` | TrackingFilter |
| 12 | `itemid` | int64 |
| 13 | `shopid` | int64 |
| 14 | `image_id` | string |
| 15 | `candidate_box` | string |
| 16 | `l1_cat` | string |

### Internal（`shops.internal` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `deduction_info` | DeductionInfo |
| 2 | `frauds` | Fraud |
| 3 | `event_id` | string |
| 4 | `cpm_deduction_info` | CPMDeductionInfo |
| 5 | `duplicate_label` | int32 |
| 6 | `algo_json_data` | string |

### ShopADItem（`shops.items` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `itemid` | int64 |

### ShopADVoucher（`shops.vouchers` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `invalid_code` | int64 |
| 2 | `status_code` | int64 |
| 3 | `voucher` | UserVoucher |

### TrackingShopBanner（`shops.shop_banners` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `banner_cnt` | int32 |
| 2 | `landing_url_type` | int32 |
| 3 | `target_url` | string |
| 4 | `landing_page_url` | string |
| 5 | `location` | int32 |

### InternalLabel（`internal_label` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `frauds` | Fraud | array<struct<fraud_type:string>> |
| 2 | `sessionid` | string | string |
| 3 | `adsinfo_extract_label` | int64 | bigint |
| 4 | `dfp_device_id` | string | string |
| 5 | `risk_tags` | string | array<string |

### Fraud（`internal_label.frauds` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `fraud_type` | FraudType |

### TrackingBanner（`banner` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `bannerid` | int64 | bigint |
| 2 | `source` | int64 | bigint |
| 3 | `campaign_unitid` | int64 | bigint |
| 4 | `slotid` | int64 | bigint |
| 5 | `json_data` | string | string |
| 6 | `image_hash` | string | string |
| 7 | `target_url` | string | string |
| 8 | `dl_json_data` | string | string |
| 9 | `location` | int32 | int |
| 10 | `card_location` | int32 | int |
| 11 | `banner_internal` | BannerInternal | struct<cpm:bigint,request_id:string,ads_request_id:string,event_id:string,cpm_deduction_info:struct<cpm:bigint,ads_id:bigint,placement:int>,frauds:array<struct<fraud_type:string>>,duplicate_label:int> |
| 12 | `banner_cnt` | int32 | int |
| 13 | `landing_url_type` | int32 | int |
| 14 | `landing_page_url` | string | string |
| 15 | `unique_id` | string | string |
| 16 | `json_data_tms` | string | string |
| 17 | `target_type` | string | string |

### BannerInternal（`banner.banner_internal` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `cpm` | int64 |
| 2 | `request_id` | string |
| 3 | `ads_request_id` | string |
| 4 | `event_id` | string |
| 5 | `cpm_deduction_info` | CPMDeductionInfo |
| 6 | `frauds` | Fraud |
| 7 | `duplicate_label` | int32 |
| 8 | `algo_json_data` | string |

### TrackingLivestream（`livestreams` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `ls_session_id` | int64 | bigint |
| 2 | `user_id` | int64 | bigint |
| 3 | `shop_id` | int64 | bigint |
| 4 | `ads_id` | int64 | bigint |
| 5 | `location` | int32 | int |
| 6 | `json_data` | string | string |
| 7 | `duration` | int32 | int |
| 8 | `list_type` | string | string |
| 9 | `click_area` | int32 | int |
| 10 | `items` | TrackingLiveItem | array<struct<item_id:bigint,shop_id:bigint>> |
| 11 | `internal` | LivestreamInternal | struct<cpm_deduction_info:struct<cpm:bigint,ads_id:bigint,placement:int |
| 12 | `target_type` | string | string |
| 13 | `if_mini_ls` | bool | boolean |
| 14 | `content_mix_frame_tab_name` | int32 | int |
| 15 | `unique_id` | string | string |

### TrackingLiveItem（`livestreams.items` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `item_id` | int64 |
| 2 | `shop_id` | int64 |
| 3 | `target_type` | string |

### LivestreamInternal（`livestreams.internal` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `cpm_deduction_info` | CPMDeductionInfo |
| 2 | `frauds` | Fraud |
| 3 | `event_id` | string |
| 4 | `request_id` | string |
| 5 | `ads_request_id` | string |
| 6 | `algo_json_data` | string |
| 7 | `duplicate_label` | int32 |

### TrackingSearchProps（`search_props` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `sort_by` | string | string |
| 2 | `scenario` | string | string |
| 3 | `search_entrance` | string | string |
| 4 | `search_mid` | string | string |
| 5 | `search_session_id` | string | string |
| 6 | `global_session_id` | string | string |
| 7 | `prefill_keyword` | string | string |

### TrackingVideoProps（`video_props` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `current_page` | string | string |
| 2 | `content_type` | string | string |
| 3 | `content_id` | string | string |
| 4 | `trigger_mode` | string | string |
| 5 | `sv_source_page` | string | string |
| 6 | `content_mix_frame_tab_name` | int32 | int |

### TrackingReferer（`referer` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `ads_id` | int64 | bigint |
| 2 | `referer_type` | int32 | int |
| 3 | `track_json_data` | string | string |
| 4 | `referer_data` | string | string |
| 5 | `unique_id` | string | string |

### TrackingVideo（`videos` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `video_id` | string | string |
| 2 | `user_id` | int64 | bigint |
| 3 | `creator_id` | int64 | bigint |
| 4 | `shop_id` | int64 | bigint |
| 5 | `ads_id` | int64 | bigint |
| 6 | `location` | int32 | int |
| 7 | `location_in_ads` | int32 | int |
| 8 | `json_data` | string | string |
| 9 | `duration` | int32 | int |
| 10 | `display_ad_tag` | int32 | int |
| 11 | `request_id` | string | string |
| 12 | `traffic_source` | int32 | int |
| 13 | `video_ads_type` | int32 | int |
| 14 | `target_type` | string | string |
| 15 | `items` | TrackingVideoItem | array<struct<item_id:bigint,shop_id:bigint,click_area:int,target_type:string>> |
| 16 | `internal` | VideoInternal | struct<cpm_deduction_info:struct<cpm:bigint,ads_id:bigint,placement:int>,event_id:string,duplicate_label:int> |
| 17 | `unique_id` | string | string |
| 18 | `item_voucher` | ItemVoucher | ItemVoucher |

### TrackingVideoItem（`videos.items` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `item_id` | int64 |
| 2 | `shop_id` | int64 |
| 3 | `click_area` | int32 |
| 4 | `target_type` | string |

### VideoInternal（`videos.internal` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `cpm_deduction_info` | CPMDeductionInfo |
| 2 | `event_id` | string |
| 3 | `duplicate_label` | int32 |
| 4 | `request_id` | string |
| 5 | `ads_request_id` | string |
| 6 | `algo_json_data` | string |

### ItemVoucher（`videos.item_voucher` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `display_ads_voucher_label` | int32 |
| 2 | `best_vouchers` | BestVoucher |
| 3 | `initial_price` | int64 |
| 4 | `final_price` | int64 |

### TrackingLivestreamsProps（`livestream_props` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `ls_session_id` | int64 | bigint |
| 2 | `streamer_id` | int64 | bigint |
| 3 | `streaming_room_source` | string | string |
| 4 | `if_mini_ls` | bool | boolean |
| 5 | `content_mix_frame_tab_name` | int32 | int |
