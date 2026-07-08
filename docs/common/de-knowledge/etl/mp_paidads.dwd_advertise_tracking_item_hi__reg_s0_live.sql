--add jar hdfs://R2/projects/mkplpaidads_data/hdfs/udf/frederic.li/paidads-data-warehouse-udf-1.0.0.jar;
add jar hdfs://D2/projects/data_paidadsmart/hdfs/udf/paidads-data-warehouse-udf-1.0.63.jar;
CREATE OR REPLACE TEMPORARY FUNCTION bid_info_decode_fuc as  'com.shopee.deepdata.warehouse.hive.udf.BiddingInfoDecodeUDF';
CREATE OR REPLACE TEMPORARY FUNCTION proc_arr as  'com.shopee.deepdata.warehouse.hive.udf.ProcArrStringUDF';

insert overwrite table dwd_advertise_tracking_item_hi__reg_s0_live partition (grass_region, grass_date, h, bz_type)
select
    userid as user_id
    ,sessionid as session_id
    ,deviceid as device_id
    ,client_ip
    ,cast(platform as bigint) as platform
    ,timestamp
    ,token
    ,`from` as source
    ,item.itemid as item_id
    ,item.shopid as shop_id
    ,item.discount as discount
    ,IF(item.free_shipping = false  ,0 ,1) as is_free_shipping
    ,IF(item.is_prefered = false  ,0 ,1) as is_prefered
    ,item.algorithm as algorithm
    ,item.location as organic_location
    ,item.refer_urls as refer_urls
    ,item.item_modelid as item_model_id
    ,item.list_type as list_type
    ,item.adsid as ads_id
    ,item.location_in_ads as location_in_ads
    ,item.campaignid as campaign_id
    ,item.ads_keyword as ads_keyword
    ,item.match_type as match_type
    -- getTrackingQuery
    ,named_struct(
        'keyword', item.query.keyword,
        'sorttype', item.query.sorttype,
        'colorful_blocks', if(item.query.colorful_blocks is not null, item.query.colorful_blocks, array()),
        'filter_price_min', item.query.filter_price_min ,
        'filter_price_max', item.query.filter_price_max ,
        'filter_include_sf', item.query.filter_include_sf ,
        'filter_with_discount', item.query.filter_with_discount ,
        'filter_attribute', item.query.filter_attribute ,
        'filter_item_condition', item.query.filter_item_condition ,
        'filter_user_verified', item.query.filter_user_verified,
        'filters', item.query.filters,
        'item_id', if(item.query.itemid is not null, item.query.itemid, 0),
        'shop_id', if(item.query.shopid is not null, item.query.shopid, 0)
    )as query
    --,item.query as query
    ,item.abtest_sign as abtest_sign
    ,item.json_data as item_json_data
    ,json_data as tracking_json_data
    -- ,if(get_json_object(json_data, '$.request_id') is not null, get_json_object(json_data, '$.request_id'), get_json_object(item.json_data, '$.request_id')) as ads_request_id
    ,COALESCE(get_json_object(item.json_data, '$.request_id'), get_json_object(json_data, '$.request_id')) as ads_request_id
    ,fe_ab_sign
    ,item.add_cart_amount as add_cart_item_amount
    ,cast(item.add_cart_price/100000 as decimal(25,10)) as add_cart_item_price
    --,item.product_card as product_card
    ,named_struct(
        'campaign_label_ids',item.product_card.campaign_label_ids
        ,'has_video',IF(item.product_card.has_video= false  ,0 ,1)
        ,'item_discount',item.product_card.item_discount
        ,'shop_type',item.product_card.shop_type
        ,'is_service_by_shopee',IF(item.product_card.service_by_shopee= false  ,0 ,1)
        ,'image_flag_ids',item.product_card.image_flag_ids
        ,'price_before_discount',cast(item.product_card.price_before_discount/100000 as decimal(25,10))
        ,'price_max_before_discount',cast(item.product_card.price_max_before_discount/100000 as decimal(25,10))
        ,'price_min_before_discount',cast(item.product_card.price_min_before_discount/100000 as decimal(25,10))
        ,'price',cast(item.product_card.price/100000 as decimal(25,10))
        ,'price_max',cast(item.product_card.price_max/100000 as decimal(25,10))
        ,'price_min',cast(item.product_card.price_min/100000 as decimal(25,10))
        ,'bundle_deal_label',item.product_card.bundle_deal_label
        ,'is_wholesale',IF(item.product_card.wholesale= false  ,0 ,1)
        ,'addon_deal_label',item.product_card.addon_deal_label
        ,'is_cashback',IF(item.product_card.cashback= false  ,0 ,1)
        ,'is_groupbuy',IF(item.product_card.is_groupbuy= false  ,0 ,1)
        ,'other_promotion_label_id',item.product_card.other_promotion_label_id
        ,'rating_star',cast(item.product_card.rating_star as double)
        ,'rating_star_rounded',cast(item.product_card.rating_star_rounded as double)
        ,'sold_count',item.product_card.sold_count
        ,'is_free_shipping',IF(item.product_card.free_shipping= false  ,0 ,1)
        ,'other_icon_in_price_id',item.product_card.other_icon_in_price_id
        ,'is_sold_out',IF(item.product_card.sold_out= false  ,0 ,1)
    ) as product_card
    ,item.request_id as raw_request_id
    ,case
        when placement in (2,5,13,14,15,16) then regexp_replace(split(split(item.abtest_sign, "REQID:")[1], ",")[0], "%3A", ":")
        else coalesce(get_json_object(item.json_data, '$.search_data.request_id'), get_json_object(item.json_data, '$.request_id'))
    end as organic_request_id
    ,internal_label
    ,COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) as ads_entrance
    ,placement as tracking_placement
    ,cast(get_json_object(item.json_data, '$.placement') as bigint) as inner_placement
    ,item.internal.deduction_info.placement as ads_placement
    -- getInternal
    ,named_struct(
        'deduction_info',
            named_struct(
                'quality', item.internal.deduction_info.quality,
                'bidprice', cast(item.internal.deduction_info.bidprice/100000 as decimal(25,10)),
                'next_score', item.internal.deduction_info.next_score,
                'next_ads_id', item.internal.deduction_info.next_adsid,
                'next_ads_keyword', item.internal.deduction_info.next_ads_keyword,
                'algo_name', item.internal.deduction_info.algo_name,
                'boost_status', item.internal.deduction_info.boost_status,
                'deduction_price', cast(item.internal.deduction_info.deduction_price/100000 as decimal(25,10)),
                'ads_id', item.internal.deduction_info.ads_id,
                'placement', item.internal.deduction_info.placement
            )
    ) as internal
    --,item.internal as internal
    ,operation as operation
    --,if(placement is not null, cast(placement as bigint), 0) as entry_point
    --fix roi2 pricing_type is null bug
    ,get_json_object(item.json_data, '$.pricing_type')  as pricing_type
    ,CASE WHEN operation = 1 THEN 'IMPRESSION' WHEN operation = 2 THEN 'CLICK' WHEN operation = 3 THEN 'VIEW' WHEN operation = 4 THEN 'ADD_TO_CART' WHEN operation = 5 THEN 'PLACE_ORDER' WHEN operation = 1001 THEN 'SHOP_IMPRESSION' WHEN operation = 1002 THEN 'SHOP_CLICK' WHEN operation = 6 THEN 'CLOSE_BANNER'  WHEN operation = 7 THEN 'REPORT_DISLIKE' WHEN operation = 8 THEN 'REPORT_INAPPROPRIATE' WHEN operation = 9 THEN 'REPORT_IRRELEVANT' WHEN operation = 10 THEN 'REPORT_IMPRESSION' END AS operation_desc
    ,CASE WHEN platform = 1 THEN 'IOS_WEB' WHEN platform = 2 THEN 'IOS_APP' WHEN platform = 3 THEN 'ANDROID_WEB' WHEN platform = 4 THEN 'ANDROID_APP' WHEN platform = 5 THEN 'PC_MALL' WHEN platform = 6 THEN 'IOS_LITE' WHEN platform = 7 THEN 'ANDROID_LITE' WHEN platform = 8 THEN 'PLATFORM_RESERVED' WHEN platform = 9 THEN 'ANDROID_APP_LITE' WHEN platform = 99 THEN 'XIAPI' WHEN platform = 128 THEN 'OTHERS' END AS platform_desc
    ,CASE
        WHEN placement in (0,4,1000,1200) THEN get_json_object(item.json_data, '$.recall_source')
        WHEN placement in (1,2,5,801,802,805,1001,1002,1005,1202,1205) THEN get_json_object(item.json_data, '$.queue_name')
        ELSE NULL
    END AS tracking_queue_name
    ,proc_arr(to_json(internal_label)) AS fraud_type
    ,item.query.sorttype as search_page_sort_type
    ,get_json_object(item.json_data, '$.buyer_segments') as matched_premium_segments
    --,get_json_object(item.json_data, '$.ab_sign') as ab_sign
    ,COALESCE(get_json_object(item.json_data, '$.ab_sign'), get_json_object(json_data, '$.ab_sign')) as ab_sign
    ,app_ver
    ,rn_ver
    ,view_session_id
    ,sub_entrance
    ,dfp
    ,item.click_area as click_area
    ,item.item_video.display_video_id as display_video_id
    ,cast(get_json_object(item.json_data, '$.ta_group_id') as bigint) as ta_group_id
    ,from_json(item.json_data,'struct<ab_sign:string,ads_id:bigint,request_id:string,response_timestamp:bigint,buyer_segments:string,ta_group_id:bigint,ta_matched_tag_ids:array<int>,ta_premium_rate:bigint>').ta_matched_tag_ids as ta_matched_tag_ids
    ,cast(get_json_object(item.json_data, '$.ta_premium_rate') as bigint) as ta_premium_rate
    ,vv_id
    ,sdk_version
    ,sdk_type
    ,page_type
    ,page_section
    ,item.target_type as target_type

    ,search_props.sort_by as sort_by
    ,search_props.scenario as scenario
    ,search_props.search_entrance as search_entrance
    ,search_props.search_mid as search_mid
    ,search_props.search_session_id as search_session_id
    ,search_props.global_session_id as global_session_id
    ,video_props.current_page as current_page
    ,video_props.content_type as content_type
    ,video_props.content_id as content_id
    ,video_props.trigger_mode as trigger_mode
    ,video_props.sv_source_page as sv_source_page

    ,item.display_ad_tag as display_ad_tag
    ,item.item_rcmd_props.card_type as card_type
    ,item.item_rcmd_props.video_id as video_id
    ,item.item_rcmd_props.be_ab as be_ab

    ,COALESCE(cast(get_json_object(item.json_data, '$.item_price') / 100000 as decimal(25,10)),
        from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').item_price / 100000) as item_price

    ,COALESCE(cast(get_json_object(item.json_data, '$.target_cir') as double),
        from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').target_cir) as target_cir

    --deprecated
    ,COALESCE(cast(get_json_object(item.json_data, '$.sold_cnt_per_order') as double),
        from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').avg_sold_cnt) as sold_cnt_per_order

    /*
    ,case when  (COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) in ('1','23')
                and item.internal.deduction_info.placement in (50))
        then from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').item_price / 100000

        else cast(get_json_object(item.json_data, '$.item_price')/100000 as decimal(25,10)) end as item_price

    ,case when  (COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) in ('1','23')
                and item.internal.deduction_info.placement in (50))
        then from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').target_cir

        else cast(get_json_object(item.json_data, '$.target_cir') as double) end as target_cir

    ,case when  (COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) in ('1','23')
                and item.internal.deduction_info.placement in (50))
        then COALESCE(from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').avg_sold_cnt
                        , cast(get_json_object(item.json_data, '$.sold_cnt_per_order') as double))
        else cast(get_json_object(item.json_data, '$.sold_cnt_per_order') as double) end as sold_cnt_per_order

    */
    ,item.internal.duplicate_label as duplicate_label
    ,item.internal.event_id as click_event_id
    /*
    ,case when  (COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) in ('1','23')
                and item.internal.deduction_info.placement in (50))
        then from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').avg_sold_cnt

        else cast(get_json_object(item.json_data, '$.sold_cnt_per_order') as double) end as sold_cnt_per_order_double

    */

    --deprecated
    ,COALESCE(cast(get_json_object(item.json_data, '$.sold_cnt_per_order') as double),
        from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                            'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                            'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').avg_sold_cnt) as sold_cnt_per_order_double

    ,item.internal.deduction_info.bid_deduction_price as bid_deduction_price
    ,cast(get_json_object(item.json_data, '$.new_product_boost_stage') as int) as new_product_boost_stage

    ,item.item_voucher as item_voucher
    ,cast(get_json_object(bid_info_decode_fuc(get_json_object(item.json_data, '$.bid_rerank_trace')), '$.bid_voucher_id') as bigint) as bid_voucher_id
    ,cast(COALESCE(get_json_object(item.json_data, '$.voucher_deduction_price'), get_json_object(json_data, '$.voucher_deduction_price')) as bigint) as voucher_deduction_price
    ,case when(ARRAY_CONTAINS(transform(item.item_voucher.best_vouchers, x-> ARRAY_CONTAINS(x.groups, 'ADS-ROI') and x.is_auto_claimed_just_now), true) = true) then 1
        else 0 end as is_auto_claimed_just_now
    ,case when(ARRAY_CONTAINS(transform(item.item_voucher.best_vouchers, x-> ARRAY_CONTAINS(x.groups, 'ADS-ROI')), true) = true) then 1
        else 0 end as is_roi3_best_voucher
    ,item.vmodelid as v_model_id
    ,item.vitemid as v_item_id
    ,item.ctx_item_type as ctx_item_type
    ,item.internal.algo_json_data as algo_json_data
    ,item.unique_id
    ,event_timestamp
    ,sequence_id

    ,bid_info_decode_fuc(get_json_object(item.json_data, '$.bid_rerank_trace')) as bid_rerank_trace
    ,get_json_object(item.json_data, '$.uni_pcr_model_name') as uni_pcr_model_name
    ,cast(get_json_object(item.json_data, '$.item_price_shop') / 100000 as double) as item_price_shop
    ,cast(get_json_object(item.json_data, '$.avg_sold_cnt_shop') as double) as avg_sold_cnt_shop
    ,cast(get_json_object(item.json_data, '$.avg_sold_cnt_item') as double) as avg_sold_cnt_item

    ,item.internal.deduction_info.is_ocpm as is_ocpm
    ,cast(get_json_object(item.json_data, '$.attribute_reason') as int) as attribute_reason

    ,item.modelid as model_id
    ,to_json(item.rsku_list_infos) as rsku_list_infos_json
    ,item.is_preselected_vmodel as is_preselected_vmodel
    ,to_json(item.shop_voucher) as shop_voucher_json

    ,grass_region
    ,grass_date
    ,h
    ,if(coalesce(placement, 0) in (0, 29), 'Search', 'Discovery') as bz_type
from mp_paidads.ods_log_ads_tracking_hi__reg_s0_live
lateral view explode(items)  as item
where grass_date = '${TODAY_DATE}'
and h = ${TODAY_HOUR}
and item.itemid > 0
--and item.shopid > 0
/*
and operation in (
    -- Impression
    1,
    -- Click
    2,
    -- View
    3,
    -- AddToCart
    --4,
    -- PlaceOrder
    5,
    --Video
    21,22,23,
    -- ShopImpression
    1001,
    -- ShopClick
    1002,
    6,7,8,9,10
)
*/;
