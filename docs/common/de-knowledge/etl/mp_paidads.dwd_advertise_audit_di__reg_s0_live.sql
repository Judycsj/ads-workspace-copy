-- task_code: data_paidadsmart.studio_2866062  asset_id: 2866062
SET TIME ZONE '${timezone}';

create or replace temporary function json_from_protobuf as 'com.shopee.deepdata.warehouse.hive.udf.AuditDecodeProtoBuf';

create or replace temporary view ad_audit_event_di as (
    select
        audit_event
        ,campaignid as campaign_id
        ,client_ip
        ,ctime as create_timestamp
        ,from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss') as create_datetime
        ,eventid as event_id
        ,from_json(
            cast(extinfo as string)
            ,'struct<adv_status:array<struct<adsid:bigint, ad_placement:int, status:int>>,camp_status:int>'
        ) as extinfo
        ,id
        ,itemid as item_id
        ,operator
        ,operatorid as operator_id
        ,platform
        ,shopid as shop_id
        ,userid as user_id
        ,ucase('${region}') as grass_region
        ,date('${grass_date}') as grass_date
    from mp_paidads.shopee_ads_${region}_db__ad_audit_event_tab__reg_continuous_s0_live
    where
        ctime < unix_timestamp(date_add(date('${grass_date}'), 1))
        and ctime >= unix_timestamp(date('${grass_date}'))
)
;

create or replace temporary view ad_kw_audit_di as (
    select
        adsid as ads_id
        ,ctime as keyword_audit_timestamp
        ,from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss') as keyword_audit_datetime
        ,eventid as event_id
        ,id
        ,keyword_update_flags
        ,cast(get_json_object(new_data, '$.price') as bigint) / 100000.00 as keyword_bid_price_local
        ,get_json_object(new_data, '$.term') as keyword
        ,cast(get_json_object(new_data, '$.kw_status') as int) as keyword_status
        ,cast(get_json_object(new_data, '$.match_type') as int) as match_type
        ,old_data
        ,new_data
        ,ucase('${region}') as grass_region
        ,date('${grass_date}') as grass_date
    from
        (
            select
                adsid
                ,ctime
                ,eventid
                ,id
                ,cast(new_data as string) as new_data
                ,cast(old_data as string) as old_data
                ,update_flags as keyword_update_flags
            from mp_paidads.shopee_ads_${region}_db__ad_keyword_audit_tab__reg_continuous_s0_live
            where
                ctime < unix_timestamp(date_add(date('${grass_date}'), 1))
                and ctime >= unix_timestamp(date('${grass_date}'))
        )
)
;

create or replace temporary view advertisement_audit as (
    select
        id
        ,adsid as ads_id
        ,eventid as event_id
        ,timestamp as event_timestamp
        ,from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
        ,cast(user_id as bigint) as user_id
        ,placement
        ,cast(item_id as bigint) as item_id
        ,cast(shop_id as bigint) as shop_id
        ,cast(campaign_id as bigint) as campaign_id
        ,ctime as create_timestamp
        ,from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss') as create_datetime
        ,cast(new_data_status as tinyint) as status
        ,cast(
            get_json_object(decoded_extinfo_new, '$.target.price') as bigint
        ) as target_price
        ,mtime as modify_timestamp
        ,from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss') as modify_datetime
        ,cast(
            get_json_object(decoded_extinfo_new, '$.pricingType') as int
        ) as pricing_type
        ,old_data
        ,new_data
        ,decoded_extinfo_old as old_data_extinfo
        ,decoded_extinfo_new as new_data_extinfo
        ,grass_region
        ,date('${grass_date}') as grass_date
    from
        (
            select
                id
                ,adsid
                ,eventid
                ,ctime as timestamp
                ,ad_placement as placement
                ,coalesce(
                    cast(get_json_object(new_data, '$.ctime') as bigint)
                    ,cast(get_json_object(old_data, '$.ctime') as bigint)
                ) as ctime
                ,get_json_object(new_data, '$.itemid') as item_id
                ,get_json_object(new_data, '$.shopid') as shop_id
                ,get_json_object(new_data, '$.campaignid') as campaign_id
                ,get_json_object(new_data, '$.userid') as user_id
                ,get_json_object(new_data, '$.status') as new_data_status
                ,cast(get_json_object(new_data, '$.mtime') as bigint) as mtime
                ,old_data
                ,new_data
                ,json_from_protobuf (get_json_object(new_data, '$.extinfo')) as decoded_extinfo_new
                ,json_from_protobuf (get_json_object(old_data, '$.extinfo')) as decoded_extinfo_old
                ,ucase('${region}') as grass_region
            from
                (
                    select
                        id
                        ,adsid
                        ,eventid
                        ,ctime
                        ,ad_placement
                        ,cast(new_data as string) as new_data
                        ,cast(old_data as string) as old_data
                    from mp_paidads.shopee_ads_${region}_db__advertisement_audit_tab__reg_continuous_s0_live
                    where
                        ctime < unix_timestamp(date_add(date('${grass_date}'), 1))
                        and ctime >= unix_timestamp(date('${grass_date}'))
                ) t1
        ) t2
)
;

insert overwrite table dwd_advertise_audit_di__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select
    /*+ BROADCAST(exrate) */
    a.event_id as id
    ,a.ads_id
    ,a.user_id
    ,a.shop_id
    ,a.item_id
    ,b.operator
    ,b.operator_id
    ,b.platform
    ,case
        when platform = 0 then 'Unknown'
        when platform = 1 then 'PC'
        when platform = 2 then 'APP'
        when platform = 3 then 'SRM'
        else null
    end as platform_name
    ,a.create_timestamp
    ,a.create_datetime
    ,b.event_timestamp
    ,b.event_datetime
    ,b.audit_event
    ,case
        when audit_event = 1 then 'PAUSE'
        when audit_event = 2 then 'RESUME'
        when audit_event = 3 then 'START'
        when audit_event = 4 then 'CREATE'
        when audit_event = 5 then 'STOP'
        when audit_event = 6 then 'RESTART'
        when audit_event = 7 then 'CHANGE_SCHEDULE'
        when audit_event = 8 then 'CHANGE_BUDGET'
        when audit_event = 9 then 'SYSTEM_PAUSE'
        when audit_event = 10 then 'SYSTEM_END'
        when audit_event = 11 then 'SHOP_CUSTOMISATION_ADDED'
        when audit_event = 12 then 'SHOP_CUSTOMISATION_CHANGED'
        when audit_event = 13 then 'SHOP_CUSTOMISATION_REMOVED'
        when audit_event = 14 then 'CREATE_BANNER_ADS'
        when audit_event = 15 then 'MODIFY_BANNER_ADS'
        when audit_event = 16 then 'OFF_ALL_ADS'
        when audit_event = 17 then 'TOGGLE_SIMPLE_MODE'
        else 'UNKNOWN'
    end as audit_event_text
    ,a.placement
    ,case
        when a.create_timestamp = b.event_timestamp then 0
        else 1
    end as is_changed
    ,a.target_price / 100000.00 as target_bid_price_local
    ,a.target_price / 100000.00 / exchange_rate as target_bid_price_usd
    ,c.keyword_bid_price_local
    ,c.keyword_bid_price_local / exchange_rate as keyword_bid_price_usd
    ,c.keyword
    ,cast(md5(keyword) as bigint) as keyword_md5
    ,c.keyword_status
    ,c.match_type
    ,a.status
    ,keyword_audit_timestamp
    ,keyword_audit_datetime
    ,keyword_update_flags
    ,a.pricing_type
    ,a.old_data
    ,a.new_data
    ,a.old_data_extinfo
    ,a.new_data_extinfo
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
from
    (
        select
            id
            ,ads_id
            ,event_id
            ,user_id
            ,shop_id
            ,item_id
            ,create_timestamp
            ,create_datetime
            ,target_price
            ,status
            ,placement
            ,pricing_type
            ,old_data
            ,new_data
            ,old_data_extinfo
            ,new_data_extinfo
            ,grass_region
            ,grass_date
        from advertisement_audit
        where grass_region = upper('${region}')
    ) a
    left join (
        select
            id
            ,event_id
            ,operator
            ,operator_id
            ,platform
            ,create_timestamp as event_timestamp
            ,create_datetime as event_datetime
            ,audit_event
            ,extinfo.adv_status as adv_status
            ,grass_region
        from ad_audit_event_di
        where
            grass_region = upper('${region}')
            and grass_date = date('${grass_date}')
    ) b on a.grass_region = b.grass_region
    and a.event_id = b.event_id
    left join (
        select
            id
            ,ads_id
            ,event_id
            ,new_data
            ,keyword_audit_timestamp
            ,keyword_audit_datetime
            ,keyword_update_flags
            ,keyword_bid_price_local
            ,keyword
            ,keyword_status
            ,match_type
            ,grass_region
        from ad_kw_audit_di
        where
            grass_region = upper('${region}')
            and grass_date = date('${grass_date}')
    ) c on a.grass_region = c.grass_region
    and b.event_id = c.event_id
    and a.ads_id = c.ads_id
    left join (
        select
            grass_region
            ,exchange_rate
        from mp_order.dim_exchange_rate__reg_s0_live
        where
            grass_region = upper('${region}')
            and grass_date = date('${grass_date}')
    ) exrate on a.grass_region = exrate.grass_region
where a.grass_date = '${grass_date}'
;

alter table dwd_advertise_audit_di__${region}_s0_live add if not exists partition (grass_date = '${grass_date}')
;