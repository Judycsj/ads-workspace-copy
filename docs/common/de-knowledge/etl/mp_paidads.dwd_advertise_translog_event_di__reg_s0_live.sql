-- task_code: data_paidadsmart.studio_6482376  asset_id: 6482376
add jar hdfs://R2/projects/mkplpaidads_data/hdfs/udf/muyu.gao/paidads-data-warehouse-udf-1.0.5.jar;
CREATE or replace TEMPORARY FUNCTION json_from_protobuf as 'com.shopee.deepdata.warehouse.hive.udf.TranslogExtinfoDecodeUDF';
set time zone '${timezone}';

create or replace temporary view translog_event as
select
    translog.id as id
    ,translog.adsid as ads_id
    ,translog.itemid as item_id
    ,cast(translog.shopid as bigint) as shop_id
    ,translog.timestamp as timestamp
    ,translog.client_ip as client_ip
    ,translog.operation as operation
    ,coalesce(translog.userid,cpm_detail.user_id) as user_id
    ,translog.price as price
    ,json_from_protobuf(get_json_object(to_json(translog), '$.extinfo')) as decoded_extinfo
    ,translog.status as status
    ,translog.acc_before_balance as acc_before_balance
    ,translog.acc_after_balance as acc_after_balance
    ,translog.dai_before_balance as dai_before_balance
    ,translog.dai_after_balance as dai_after_balance
    ,translog.deviceid as device_id
    ,translog.keyword as keyword
    ,translog.placement as placement
    ,translog.deduct_unique_id as deduct_unique_id
    ,translog.acc_user_id as acc_user_id
    ,translog.account_id as account_id
    ,root_ads_data_str
    ,item_ads_data_str
    ,shop_ads_data_str
    ,country
    ,produce_ts
    ,location
    ,sub_entrance
    ,cpm_event_details_str
    ,click_area
    ,display_video_id
    ,rn_ver
    ,platform
    ,track_session_id
    ,search_session_id
    ,click_event_id
    ,page_type
    ,page_section
    ,target_type
    ,search_scenario
    ,search_entrance
    ,search_mid
    ,raw_request_id
    ,imp_cost_details
    ,traffic_source
    ,sort_by
    ,algo_json_data
    ,click_time_daily_budget
    ,common_json_data
    ,original_deduct_id
    ,original_order_timestamp
    ,track_unique_id
    ,grass_region
    ,cpm_detail.entrance as entrance
from mp_paidads.ods_log_translog_event_hi__reg_s0_live
lateral view outer EXPLODE(from_json(cpm_event_details_str, 'array<struct<user_id:bigint, entrance:int>>')) t as cpm_detail
where
    grass_date >= DATE('${grass_date}')
    and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    and   DATE(from_unixtime(translog.timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
    and   DATE(from_unixtime(translog.timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
    and grass_region = upper('${region}')
;

INSERT OVERWRITE TABLE dwd_advertise_translog_event_di__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    id
    ,ads_id
    ,item_id
    ,shop_id
    ,timestamp
    ,client_ip
    ,user_id
    ,price
    ,decoded_extinfo
    ,CAST(get_json_object(decoded_extinfo, '$.matchType') AS int) AS match_type
    ,CAST(get_json_object(decoded_extinfo, '$.recallType') AS int) AS recall_type
    ,CAST(get_json_object(decoded_extinfo, '$.expectDeductPrice') AS bigint) AS expect_deduct_price
    ,CAST(get_json_object(decoded_extinfo, '$.query.keyword') AS string) AS user_query
    ,CAST(get_json_object(decoded_extinfo, '$.query.sorttype') AS int) AS sort_type
    ,cast(get_json_object(decoded_extinfo, '$.query.itemid') as BIGINT) as pdp_item_id
    ,cast(get_json_object(decoded_extinfo, '$.query.shopid') as BIGINT) as pdp_shop_id
    ,get_json_object(decoded_extinfo, '$.adsCredits') as ads_credits
    ,get_json_object(decoded_extinfo, '$.deductionInfo') as deduction_info
    ,get_json_object(decoded_extinfo, '$.paidFreeExpirySummary') as paid_free_expiry_summary
    ,CAST(get_json_object(decoded_extinfo, '$.deductionInfo.bidprice') AS bigint) AS bid_price
    ,CAST(get_json_object(decoded_extinfo, '$.deductionInfo.nextScore') AS DOUBLE) AS second_ads_ecpm
    ,CAST(get_json_object(decoded_extinfo, '$.deductionInfo.nextAdsid') AS BIGINT) AS second_ads_id
    ,get_json_object(decoded_extinfo, '$.deductionInfo.algoName') as ab_sign
    ,CAST(get_json_object(decoded_extinfo, '$.topupSign') AS string) AS topup_sign
    ,coalesce(CAST(get_json_object(decoded_extinfo, '$.entrance') AS int),entrance) AS entrance
    ,CAST(get_json_object(decoded_extinfo, '$.pricingType') AS int) AS pricing_type
    ,status
    ,acc_before_balance
    ,acc_after_balance
    ,dai_before_balance
    ,device_id
    ,keyword
    ,placement
    ,deduct_unique_id
    ,root_ads_data_str
    ,item_ads_data_str
    ,shop_ads_data_str
    ,country
    ,produce_ts
    ,location
    ,sub_entrance
    ,cpm_event_details_str
    ,click_area
    ,display_video_id
    ,rn_ver
    ,platform
    ,track_session_id
    ,search_session_id
    ,click_event_id
    ,page_type
    ,page_section
    ,target_type
    ,search_scenario
    ,search_entrance
    ,search_mid
    ,raw_request_id
    ,imp_cost_details
    ,traffic_source
    ,sort_by
    ,operation
    ,dai_after_balance
    ,acc_user_id
    ,account_id
    ,algo_json_data
    ,click_time_daily_budget
    ,common_json_data
    ,original_deduct_id
    ,original_order_timestamp
    ,track_unique_id
    ,grass_region
    ,DATE('${grass_date}') as grass_date
from translog_event;

alter table dwd_advertise_translog_event_di__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");