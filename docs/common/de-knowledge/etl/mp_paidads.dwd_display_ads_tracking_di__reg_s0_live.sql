-- task_code: data_paidadsmart.studio_2861224  asset_id: 2861224
-- UTC-5: MX
SET TIME ZONE 'America/Mexico_City';

create or replace temporary view display_ads_tracking as
(
    select  banner, client_ip, country
                    ,deviceid
                    , from
                    , internal_label
                    , json_data
                    ,operation
                    ,placement
                    , platform
                    ,sessionid
                    ,timestamp
                    ,token
                    ,userid
    from mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live
    where (grass_date='${grass_date}' or grass_date='${today_date}')
    and country = upper('${region}')
);

INSERT OVERWRITE TABLE dwd_display_ads_tracking_di__reg_s0_live PARTITION (tz_type='local', grass_region='${upper_region}' ,grass_date)
select  user_id
        ,banner.json_data.shop_id as shop_id
        ,case   when banner.source = 2 then banner.banner_id
                else null
         end as ads_id
        ,case   when banner.source = 2 then null else banner.banner_id
         end as banner_id
        ,banner.source as source
        ,device_id
        ,banner.json_data.request_id as request_id
        ,placement
        ,operation
        ,platform
        ,banner.slot_id as slot_id
        ,session_id
        ,client_ip
        ,banner.json_data.ab_sign as ab_sign
        ,event_timestamp
        ,event_datetime
        ,banner
        ,from 
        ,json_data
        ,token
        ,CAST(get_json_object(origin_banner.json_data,'$.placement') AS int) as ads_placement
        ,CAST(get_json_object(origin_banner.json_data,'$.entrance') AS int) as ads_entrance
        ,date('${grass_date}') as grass_date
from    (
    select  *
    from    (
        select  userid AS user_id,
            banner as origin_banner,
                STRUCT(
            banner.bannerid AS banner_id
            ,banner.campaign_unitid AS campaign_unit_id
            ,banner.image_hash AS image_hash
            ,banner.slotid AS slot_id
            ,banner.source
            ,banner.target_url
            ,STRUCT(
                get_json_object(banner.json_data,'$.request_id') AS request_id
                ,get_json_object(banner.json_data,'$.ab_sign') AS ab_sign
                ,CAST(get_json_object(banner.json_data,'$.generated_time') AS bigint) AS generated_timestamp
                ,CAST(get_json_object(banner.json_data,'$.l1_cat_id') AS bigint) AS l1_cat_id
                ,CAST(get_json_object(banner.json_data,'$.shop_id') AS bigint) AS shop_id
                ,get_json_object(banner.json_data,'$.track_id') AS track_id
            ) AS json_data
        ) AS banner
                ,client_ip
                ,deviceid AS device_id
                ,from
                ,json_data
                ,operation
                ,placement
                ,platform
                ,sessionid as session_id
                ,timestamp as event_timestamp
                ,from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss') AS event_datetime
                ,token
                ,country as grass_region
                ,date('${grass_date}') as grass_date
        from    display_ads_tracking
    ) c
    where   DATE(from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
      and   DATE(from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
) d;

alter table dwd_display_ads_tracking_di__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');