-- task_code: data_paidadsmart.studio_6435912  asset_id: 6435912
create or replace temporary function campaign_protobuf as 'com.shopee.deepdata.warehouse.hive.udf.CampaignAuditDecodeProtoBuf';
create or replace temporary function product_campaign_protobuf as 'com.shopee.deepdata.warehouse.hive.udf.ProductCampaignAuditDecodeProtoBuf';

create table if not exists dwd_campaign_audit_di__reg_s0_live (
    `id` bigint comment 'primary key'
    ,`event_id` bigint comment 'event id'
    ,`campaign_id` bigint comment 'campaign id'
    ,`user_id` bigint comment 'ads owner user id'
    ,`shop_id` bigint comment 'ads owner shop id'
    ,`campaign_status` bigint comment 'campaign status in new data'
    ,`audit_event` bigint comment 'audit event code'
    ,`target_broad_roi` double comment 'only for ultimate setup flow'
    ,`operator` string comment 'operator name'
    ,`operator_id` bigint comment 'operator id'
    ,`platform` int comment 'PLATFORM_UNKNOWN=0;PLATFORM_PC=1;PLATFORM_APP=2;PLATFORM_SRM=3;PLATFORM_ADS_STATUS_SYNCER=12; more details see:https://sites.google.com/shopee.com/paid-ads-data/general-data-useful-tips/field-corresponding-enum-value#h.306lfzryzbke'
    ,`event_timestamp` bigint comment 'when the modification happens'
    ,`event_datetime` string comment 'when the modification happens'
    ,`old_data` string
    ,`new_data` string
    ,roi_two_target_value_old double
    ,roi_two_target_value_new double
    ,current_target_roi double
    ,last1_day_target_roi double
    ,last7_day_target_roi double
    ,new_data_extinfo string
    ,old_data_extinfo string
    ,ad_audit_event_extinfo string
    ,`tz_type` string
    ,`grass_region` string
    ,`grass_date` date
) using parquet partitioned by (
    tz_type
    ,grass_region
    ,grass_date
) comment 'aggregated data based on campaign audit' 
location '${HIVE_PATH}/dwd_campaign_audit_di__reg_s0_live' 
;

create table if not exists dwd_campaign_audit_di__${region}_s0_live (
    `id` bigint comment 'primary key'
    ,`event_id` bigint comment 'event id'
    ,`campaign_id` bigint comment 'campaign id'
    ,`user_id` bigint comment 'ads owner user id'
    ,`shop_id` bigint comment 'ads owner shop id'
    ,`campaign_status` bigint comment 'campaign status in new data'
    ,`audit_event` bigint comment 'audit event code'
    ,`target_broad_roi` double comment 'only for ultimate setup flow'
    ,`operator` string comment 'operator name'
    ,`operator_id` bigint comment 'operator id'
    ,`platform` int comment 'PLATFORM_UNKNOWN=0;PLATFORM_PC=1;PLATFORM_APP=2;PLATFORM_SRM=3;PLATFORM_ADS_STATUS_SYNCER=12;details see:https://sites.google.com/shopee.com/paid-ads-data/general-data-useful-tips/field-corresponding-enum-value#h.306lfzryzbke'
    ,`event_timestamp` bigint comment 'when the modification happens'
    ,`event_datetime` string comment 'when the modification happens'
    ,`old_data` string
    ,`new_data` string
    ,roi_two_target_value_old double
    ,roi_two_target_value_new double
    ,current_target_roi double
    ,last1_day_target_roi double
    ,last7_day_target_roi double
    ,new_data_extinfo string
    ,old_data_extinfo string
    ,ad_audit_event_extinfo string
    ,`grass_date` date
) using parquet partitioned by (
    grass_date
) comment 'aggregated data based on campaign audit' 
location '${HIVE_PATH}/dwd_campaign_audit_di__reg_s0_live/tz_type=local/grass_region=${upper_region}' 
;

create or replace temporary view campaign_audit as (
    select
        id
        ,eventid as event_id
        ,cast(campaign_id as bigint) as campaign_id
        ,cast(user_id as bigint) as user_id
        ,cast(shop_id as bigint) as shop_id
        ,old_data
        ,new_data
        ,new_decoded_extinfo as new_data_extinfo
        ,cast(new_data_status as tinyint) as status
        ,cast( get_json_object(new_decoded_extinfo, '$.targetBroadRoi.value') as double) as target_broad_roi
        ,cast( get_json_object(new_decoded_extinfo, '$.roiTwo.targetValue') as double) as roi_two_target_value_new
        ,cast( get_json_object(old_decoded_extinfo, '$.roiTwo.targetValue') as double) as roi_two_target_value_old
        ,old_decoded_extinfo as old_data_extinfo
    from
        (
            select
                id
                ,eventid
                ,get_json_object(new_data, '$.campaignid') as campaign_id
                ,get_json_object(new_data, '$.shopid') as shop_id
                ,get_json_object(new_data, '$.userid') as user_id
                ,old_data
                ,new_data
                ,get_json_object(new_data, '$.status') as new_data_status
                ,campaign_protobuf (get_json_object(new_data, '$.extinfo')) as new_decoded_extinfo
                ,campaign_protobuf (get_json_object(old_data, '$.extinfo')) as old_decoded_extinfo
                ,ucase('${region}') as grass_region
            from
                (
                    select
                        id
                        ,eventid
                        ,cast(new_data as string) as new_data
                        ,cast(old_data as string) as old_data
                    from mp_paidads.shopee_ads_${region}_db__campaign_audit_tab__reg_continuous_s0_live
                    where
                        ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
                        and ctime >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
                ) 

            union all 

            select
                id
                ,eventid
                ,get_json_object(new_data, '$.campaignid') as campaign_id
                ,get_json_object(new_data, '$.shopid') as shop_id
                ,get_json_object(new_data, '$.userid') as user_id
                ,old_data
                ,new_data
                ,null as new_data_status
                ,product_campaign_protobuf (get_json_object(new_data, '$.extinfo')) as new_decoded_extinfo
                ,product_campaign_protobuf (get_json_object(old_data, '$.extinfo')) as old_decoded_extinfo
                ,ucase('${region}') as grass_region
            from
                (
                    select
                        id
                        ,eventid
                        ,update_flags
                        ,cast(new_data as string) as new_data
                        ,cast(old_data as string) as old_data
                    from mp_paidads.shopee_ads_${region}_db__product_campaign_audit_tab__reg_continuous_s0_live
                    where
                        ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
                        and ctime >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
                ) 
        ) 

)
;

create or replace temporary view ad_audit_event as (
    select
        eventid as event_id
        ,audit_event
        ,campaignid as campaign_id
        ,client_ip
        ,ctime as event_timestamp
        ,from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}') as event_datetime
        ,operator
        ,operatorid as operator_id
        ,platform
        ,decode(extinfo, 'utf-8') as ad_audit_event_extinfo
        ,cast(GET_JSON_OBJECT(decode(extinfo, 'utf-8'), '$.auto_budget_increase.current_target_roi') as bigint) as current_target_roi
        ,cast(GET_JSON_OBJECT(decode(extinfo, 'utf-8'), '$.auto_budget_increase.float_last1_day_target_roi') as double) as last1_day_target_roi
        ,cast(GET_JSON_OBJECT(decode(extinfo, 'utf-8'), '$.auto_budget_increase.float_last7_day_target_roi') as double) as last7_day_target_roi
        ,ucase('${region}') as grass_region
        ,date('${grass_date}') as grass_date
    from mp_paidads.shopee_ads_${region}_db__ad_audit_event_tab__reg_continuous_s0_live
    where
        ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
        and ctime >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
)
;

insert overwrite table dwd_campaign_audit_di__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select
    a.id
    ,a.event_id
    ,a.campaign_id
    ,a.user_id
    ,a.shop_id
    ,a.status as campaign_status
    ,b.audit_event
    ,a.target_broad_roi / 100000.0 as target_broad_roi
    ,b.operator
    ,b.operator_id
    ,b.platform
    ,b.event_timestamp
    ,b.event_datetime
    ,a.old_data
    ,a.new_data
    ,roi_two_target_value_old / 100000.0 as roi_two_target_value_old
    ,roi_two_target_value_new / 100000.0 as roi_two_target_value_new
    ,b.current_target_roi  / 100000.0 as current_target_roi
    ,b.last1_day_target_roi / 100000 as last1_day_target_roi
    ,b.last7_day_target_roi / 100000 as last7_day_target_roi
    ,new_data_extinfo
    ,old_data_extinfo
    ,ad_audit_event_extinfo
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
from campaign_audit a
left join ad_audit_event b 
on a.event_id = b.event_id
;

alter table dwd_campaign_audit_di__${region}_s0_live add if not exists partition (grass_date = '${grass_date}');