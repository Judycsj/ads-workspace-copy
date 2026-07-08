-- task_code: data_paidadsmart.studio_7427909  asset_id: 7427909
use mp_paidads\n\n;\n\n
add jar hdfs://R2/projects/data_paidadsmart/hdfs/udf/paidads-data-warehouse-udf-1.0.63.jar\n\n;\n\n
CREATE OR REPLACE TEMPORARY FUNCTION decode_video_id as 'com.shopee.data.video.udf.DecodeVideoid' using jar 'hdfs://R2/projects/video/hdfs/udf/data-mart-udf-1.0-SNAPSHOT.jar'\n\n;\n\n
CREATE OR REPLACE TEMPORARY FUNCTION bid_info_decode_fuc as  'com.shopee.deepdata.warehouse.hive.udf.BiddingInfoDecodeUDF'\n\n;\n\n
--drop table if exists `dwd_request_tracking_video_hi__reg_s0_live`;
create external table if not exists `dwd_request_tracking_video_hi__reg_s0_live`
(
  `user_id` bigint, 
  `session_id` string, 
  `device_id` string, 
  `platform` bigint, 
  `timestamp` bigint, 
  `token` string, 
  `country` string, 
  `shop_id` bigint, 
  `account_id` bigint, 
  `creator_id` bigint, 
  `item_id` bigint, 
  `item_shop_id` bigint, 
  `organic_location` bigint, 
  `ads_id` bigint, 
  `location_in_ads` bigint, 
  `campaign_id` bigint, 
  `video_json_data` string, 
  `ads_request_id` string, 
  `fe_ab_sign` string, 
  `raw_request_id` string, 
  `ads_entrance` bigint, 
  `tracking_placement` bigint, 
  `ads_placement` bigint, 
  `internal` struct<cpm_deduction_info:struct<cpm:bigint, ads_id:bigint, placement:int>,event_id:string, duplicate_label:int>,
  `operation` bigint, 
  `pricing_type` int, 
  `pctr` decimal(25,10), 
  `pcr` decimal(25,10), 
  `broad_pcr` decimal(25,10), 
  `item_price` bigint,
  `sold_cnt` bigint, 
  `target_cir` decimal(25,10),
  `bid_price` bigint, 
  `initial_cpm` bigint, 
  `pid_coef` decimal(25,10), 
  `traffic_source` int,
  `operation_desc` string, 
  `platform_desc` string, 
  `video_ads_type` int, 
  `video_duration` bigint, 
  `ab_sign` string, 
  `app_ver` string, 
  `rn_ver` string, 
  `sub_entrance` bigint, 
  `dfp` string,

  `click_area` bigint, 
  `vv_id` string, 
  `sdk_version` string, 
  `sdk_type` string, 
  `page_type` string, 
  `page_section` string, 
  `target_type` string, 
  `current_page` string, 
  `content_type` string, 
  `content_id` string, 
  `trigger_mode` string, 
  `sv_source_page` string, 
  `video_id` string, 
  `display_ad_tag` int,
  `delivery_type` int, -- 0:mingtou，1:antou
  content_mix_frame_tab_name int,
  bid_rerank_trace string
) 
partitioned by
(
    `grass_region` varchar(10)
    ,`grass_date` date
    ,`h` int
) row format serde 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
stored as
    inputformat 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
    outputformat 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
location 'hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/dwd_request_tracking_video_hi'
\n\n;\n\n

create or replace temporary view  tracking_table_video_antou as
select *,item
from mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
lateral view explode(items)  as item
where grass_date = '2026-03-31'
and grass_region in ('AR','BR','ID','MX','MY','PH','SG','TH','TW','VN')
and h = 15
and item.itemid > 0
--and item.shopid > 0
and operation in (1,2,21,22,23)
and (cast(COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) as bigint) in (29, 33, 34, 50,56,55,58,54,62,63,64)
    or (cast(COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) as bigint) in(1,3) and item.target_type = 'video'))
and item.internal.deduction_info.placement not in (54)
\n\n;\n\n


insert overwrite table dwd_request_tracking_video_hi__reg_s0_live partition (grass_region, grass_date, h)
(select  /*+ REPARTITION(10) */
    userid as user_id
    ,sessionid as session_id
    ,deviceid as device_id
    ,cast(platform as bigint) as platform
    ,timestamp
    ,token
    ,country
    ,video.shop_id as shop_id
    
    ,cast(get_json_object(video.json_data, '$.account_id')as bigint)  as account_id
    ,video.creator_id as creator_id
    ,video_item.item_id as item_id
    ,video_item.shop_id as item_shop_id
    ,video.location as organic_location
    ,cast(COALESCE(get_json_object(video.json_data, '$.ads_id'), video.ads_id) as bigint) as ads_id
    ,video.location_in_ads as location_in_ads
    ,cast(get_json_object(video.json_data, '$.campaign_id') as bigint)  as campaign_id
    ,video.json_data as video_json_data
    ,get_json_object(video.json_data, '$.request_id') as ads_request_id
    ,fe_ab_sign
    ,video.request_id as raw_request_id
    ,cast(COALESCE(get_json_object(video.json_data, '$.entrance'), entrance) as bigint) as ads_entrance
    ,placement as tracking_placement
    ,cast(coalesce(video.internal.cpm_deduction_info.placement, placement) as bigint) as ads_placement
    ,video.internal as internal
    ,operation
    ,cast(get_json_object(video.json_data, '$.pricing_type') as int) as pricing_type
    ,cast(get_json_object(video.json_data, '$.pctr') as decimal(25,10)) as pctr
    ,cast(get_json_object(video.json_data, '$.pcr') as decimal(25,10)) as pcr
    ,cast(get_json_object(video.json_data, '$.broad_pcr') as decimal(25,10)) as broad_pcr
    ,cast(get_json_object(video.json_data, '$.item_price') as bigint) as item_price
    ,cast(get_json_object(video.json_data, '$.sold_cnt') as bigint) as sold_cnt
    ,cast(get_json_object(video.json_data, '$.target_cir') as decimal(25,10)) as target_cir
    ,cast(get_json_object(video.json_data, '$.bid_price') as bigint) as bid_price
    ,cast(get_json_object(video.json_data, '$.initial_cpm') as bigint) as initial_cpm
    ,cast(get_json_object(video.json_data, '$.pid_coef') as decimal(25,10)) as pid_coef
    ,video.traffic_source as traffic_source
    ,CASE WHEN operation = 1 THEN 'IMPRESSION' WHEN operation = 2 THEN 'CLICK' WHEN operation = 3 THEN 'VIEW' WHEN operation = 4 THEN 'ADD_TO_CART' 
    WHEN operation = 5 THEN 'PLACE_ORDER' WHEN operation = 1001 THEN 'SHOP_IMPRESSION' WHEN operation = 1002 THEN 'SHOP_CLICK' WHEN operation = 6 THEN 'CLOSE_BANNER'  
    WHEN operation = 7 THEN 'REPORT_DISLIKE' WHEN operation = 8 THEN 'REPORT_INAPPROPRIATE'  WHEN operation = 9 THEN 'REPORT_IRRELEVANT' 
    WHEN operation = 10 THEN 'REPORT_IMPRESSION'  WHEN operation = 11 THEN 'SHOP_SCROLL'  WHEN operation = 12 THEN 'SHOP_VIEW' 
    WHEN operation = 13 THEN 'LIVE_VIEW'  WHEN operation = 14 THEN 'PRODUCT_CLICK'  WHEN operation = 15 THEN 'LIVE_VIEW_PING' 
    WHEN operation = 16 THEN 'EXIT_STREAM'  WHEN operation = 17 THEN 'SHOP_ITEM_IMPRESSION'  WHEN operation = 18 THEN 'MORE_SHOP_CLICK' 
    WHEN operation = 19 THEN 'ENTRY_IMPRESSION'  WHEN operation = 20 THEN 'ENTRY_CLICK'  WHEN operation = 21 THEN 'VIDEO_VIEW' 
    WHEN operation = 22 THEN 'VIDEO_PLAY_TIME'  WHEN operation = 23 THEN 'VIDEO_PLAY_COMPLETE' 
    END AS operation_desc
    ,CASE WHEN platform = 1 THEN 'IOS_WEB' WHEN platform = 2 THEN 'IOS_APP' WHEN platform = 3 THEN 'ANDROID_WEB' WHEN platform = 4 THEN 'ANDROID_APP' 
    WHEN platform = 5 THEN 'PC_MALL' WHEN platform = 6 THEN 'IOS_LITE' WHEN platform = 7 THEN 'ANDROID_LITE' WHEN platform = 8 THEN 'PLATFORM_RESERVED' 
    WHEN platform = 9 THEN 'ANDROID_APP_LITE' WHEN platform = 99 THEN 'XIAPI' WHEN platform = 128 THEN 'OTHERS' 
    END AS platform_desc
    ,video.video_ads_type as video_ads_type
    ,video.duration as video_duration
    ,get_json_object(video.json_data, '$.ab_sign') as ab_sign
    ,app_ver
    ,rn_ver 
    ,sub_entrance 
    ,dfp
    ,video_item.click_area as click_area
    ,vv_id
    ,sdk_version
    ,sdk_type 
    ,page_type 
    ,page_section 
    ,case when operation = 14 then COALESCE(video_item.target_type, video.target_type)
        else video.target_type end as target_type
    ,video_props.current_page as current_page
    ,video_props.content_type as content_type
    ,video_props.content_id as content_id
    ,video_props.trigger_mode as trigger_mode
    ,video_props.sv_source_page as sv_source_page
    ,decode_video_id(video.video_id) as video_id
    ,video.display_ad_tag as display_ad_tag
    ,0 as delivery_type
    ,unique_id
    ,video_props.content_mix_frame_tab_name as content_mix_frame_tab_name
    ,bid_info_decode_fuc(get_json_object(video.json_data, '$.bid_rerank_trace')) as bid_rerank_trace
    ,grass_region
    ,grass_date
    ,h
from tracking_table_video_mingtou

union all 

select /*+ REPARTITION(10) */
     userid as user_id
    ,sessionid as session_id
    ,deviceid as device_id
    ,cast(platform as bigint) as platform
    ,timestamp
    ,token
    ,country
    ,null as shop_id
    ,null as account_id
    ,item.item_video.video_creator_id as creator_id
    ,item.itemid as item_id
    ,item.shopid as item_shop_id
    ,item.location as organic_location
    ,item.adsid as ads_id
    ,item.location_in_ads as location_in_ads
    ,item.campaignid as campaign_id
    ,null as video_json_data
    ,COALESCE(get_json_object(item.json_data, '$.request_id'), get_json_object(json_data, '$.request_id')) as ads_request_id
    ,fe_ab_sign
    ,item.request_id as raw_request_id

    ,cast(COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) as bigint ) as ads_entrance
    ,placement as tracking_placement
    ,item.internal.deduction_info.placement as ads_placement

    ,named_struct(
            'cpm_deduction_info',item.internal.cpm_deduction_info,
            'event_id',item.internal.event_id,
            'duplicate_label',item.internal.duplicate_label
        ) as internal

    ,operation
    ,cast(get_json_object(item.json_data, '$.pricing_type') as int)  as pricing_type
    ,null as pctr
    ,null as pcr
    ,null as broad_pcr
    ,case when  (COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) in ('1','23')
                    and item.internal.deduction_info.placement in (50)) 
            then from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                                'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                                'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').item_price / 100000
            else cast(get_json_object(item.json_data, '$.item_price')/100000 as decimal(25,10)) end as item_price

    ,item.product_card.sold_count as sold_cnt
    ,case when  (COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) in ('1','23')
                    and item.internal.deduction_info.placement in (50)) 
            then from_json(from_json(get_json_object(get_json_object(item.json_data, '$.extra_json'), '$.bid-infos'),
                                'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
                                'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').target_cir      
            else cast(get_json_object(item.json_data, '$.target_cir') as double) end as target_cir

    ,cast(item.internal.deduction_info.bidprice/100000 as decimal(25,10)) as bid_price
    ,null as initial_cpm
    ,null as pid_coef
    ,item.traffic_source
    ,CASE WHEN operation = 1 THEN 'IMPRESSION' WHEN operation = 2 THEN 'CLICK' WHEN operation = 3 THEN 'VIEW' WHEN operation = 4 THEN 'ADD_TO_CART' 
        WHEN operation = 5 THEN 'PLACE_ORDER' WHEN operation = 1001 THEN 'SHOP_IMPRESSION' WHEN operation = 1002 THEN 'SHOP_CLICK' WHEN operation = 6 THEN 'CLOSE_BANNER'  
        WHEN operation = 7 THEN 'REPORT_DISLIKE' WHEN operation = 8 THEN 'REPORT_INAPPROPRIATE'  WHEN operation = 9 THEN 'REPORT_IRRELEVANT' 
        WHEN operation = 10 THEN 'REPORT_IMPRESSION'  WHEN operation = 11 THEN 'SHOP_SCROLL'  WHEN operation = 12 THEN 'SHOP_VIEW' 
        WHEN operation = 13 THEN 'LIVE_VIEW'  WHEN operation = 14 THEN 'PRODUCT_CLICK'  WHEN operation = 15 THEN 'LIVE_VIEW_PING' 
        WHEN operation = 16 THEN 'EXIT_STREAM'  WHEN operation = 17 THEN 'SHOP_ITEM_IMPRESSION'  WHEN operation = 18 THEN 'MORE_SHOP_CLICK' 
        WHEN operation = 19 THEN 'ENTRY_IMPRESSION'  WHEN operation = 20 THEN 'ENTRY_CLICK'  WHEN operation = 21 THEN 'VIDEO_VIEW' 
        WHEN operation = 22 THEN 'VIDEO_PLAY_TIME'  WHEN operation = 23 THEN 'VIDEO_PLAY_COMPLETE' 
        END AS operation_desc
    ,CASE WHEN platform = 1 THEN 'IOS_WEB' WHEN platform = 2 THEN 'IOS_APP' WHEN platform = 3 THEN 'ANDROID_WEB' WHEN platform = 4 THEN 'ANDROID_APP' 
        WHEN platform = 5 THEN 'PC_MALL' WHEN platform = 6 THEN 'IOS_LITE' WHEN platform = 7 THEN 'ANDROID_LITE' WHEN platform = 8 THEN 'PLATFORM_RESERVED' 
        WHEN platform = 9 THEN 'ANDROID_APP_LITE' WHEN platform = 99 THEN 'XIAPI' WHEN platform = 128 THEN 'OTHERS' 
        END AS platform_desc
    ,null as video_ads_type
    ,null as video_duration
    ,COALESCE(get_json_object(item.json_data, '$.ab_sign'), get_json_object(json_data, '$.ab_sign')) as ab_sign
    ,app_ver
    ,rn_ver 
    ,sub_entrance 
    ,dfp
    ,item.click_area as click_area
    ,vv_id 
    ,sdk_version 
    ,sdk_type 
    ,page_type 
    ,page_section 
    ,item.target_type as target_type
    ,video_props.current_page as current_page 
    ,video_props.content_type as content_type 
    ,video_props.content_id as content_id
    ,video_props.trigger_mode as trigger_mode 
    ,video_props.sv_source_page as sv_source_page
    ,decode_video_id(coalesce(item.item_rcmd_props.video_id,item.item_video.display_video_id_encoded)) as video_id
    ,item.display_ad_tag as display_ad_tag
    ,1 as delivery_type
    ,unique_id
    ,video_props.content_mix_frame_tab_name as content_mix_frame_tab_name
    ,bid_info_decode_fuc(get_json_object(item.json_data, '$.bid_rerank_trace')) as bid_rerank_trace
    ,grass_region
    ,grass_date
    ,h
from tracking_table_video_antou
)
\n\n;\n\n


create or replace temporary view  tracking_table_video_mingtou as
select *, video_item 
from (
    select *, video, video.items as video_items
    from mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
    lateral view explode(videos)  as video
    where grass_date = '2026-03-31'
    and grass_region in ('AR','BR','ID','MX','MY','PH','SG','TH','TW','VN')
    and h = 15
    and operation in (1,2,14,21,22,23)
    and size(videos)>0 
) 
lateral view outer explode(video_items)  as video_item