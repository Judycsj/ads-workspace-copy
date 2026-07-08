-- task_code: data_paidadsmart.studio_10511290  asset_id: 10511290
create external table if not exists ads_brand_max_ads_user_level_new_4a_1d__reg_s0_live (
    shop_id  BIGINT
    ,campaign_id  BIGINT
    ,user_id BIGINT
    ,new_aware BIGINT
    ,new_appeal BIGINT
    ,new_action BIGINT
    ,new_advocate BIGINT
)
partitioned by
    (   
        tz_type string
        ,grass_region string comment 'grass_region'
        ,grass_date date comment 'grass_date'
    ) stored as PARQUET location '${HIVE_PATH}/ads_brand_max_ads_user_level_new_4a_1d__reg_s0_live'
;

--拉取过去 7 天内被该广告曝光过的用户人群
create or replace temporary view campaign_user_performance as (
    select
        -- grass_date,
        grass_region,
        shop_id,
        campaign_id,
        user_id,
        sum(impression_cnt) as impression_cnt
    from mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where 
        tz_type = 'local'
        and grass_region in ('MY','SG','TH','ID','VN','PH','TW')
        and grass_date >= '${BEFORE_7_DAY}'and grass_date <= '${BIZ_YESTERDAY}' 
        and placement in (65)          --  BRAND_MAX_ADS = 65
    group by 1,2,3,4
    having sum(impression_cnt) > 0
);

-- 拉取昨天的用户人群标签
create or replace temporary view yesterday_user_segment as (
    select
        a.shop_id,
        a.campaign_id,
        a.user_id,
        a.impression_cnt,
        coalesce(b.segment, -1) as segment,         --没找到 segment 就给-1
        b.grass_region,
        b.grass_date
    from 
    (
        select * from campaign_user_performance
    ) a
    join  
    (
        select 
            grass_date,
            grass_region,
            shop_id,
            user_id,
            case when segment_name = 'opportunity' then 0
                    when segment_name = 'aware' then 1
                    when segment_name = 'appeal' then 2
                    when segment_name = 'action' then 3
                    when segment_name = 'advocate' then 4
                else -1
            end
                as segment
        from mkpldp_business_insight.dwd_shop_user_segment_di_reg_s0
        where grass_date = '${BIZ_YESTERDAY}'
    ) b
    on a.grass_region = b.grass_region
    and a.shop_id = b.shop_id
    and a.user_id = b.user_id
);


create or replace temporary view full_user_segment as (
    select
        a.shop_id,
        a.campaign_id,
        a.user_id,
        a.impression_cnt,
        a.segment as yesterday_segment,
        coalesce(b.segment, -1) as day_before_yesterday_segment,
        a.grass_region,
        a.grass_date
    from 
        yesterday_user_segment a
    left join  
    (
        select 
            grass_date,
            grass_region,
            shop_id,
            user_id,
            case when segment_name = 'opportunity' then 0
                    when segment_name = 'aware' then 1
                    when segment_name = 'appeal' then 2
                    when segment_name = 'action' then 3
                    when segment_name = 'advocate' then 4
                else -1
            end
                as segment
        from mkpldp_business_insight.dwd_shop_user_segment_di_reg_s0
        where grass_date = '${DAY_BEFORE_YESTERDAY}'
    ) b
    on a.grass_region = b.grass_region
    and a.shop_id = b.shop_id
    and a.user_id = b.user_id
);

insert overwrite table ads_brand_max_ads_user_level_new_4a_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
(
    select 
        shop_id,
        campaign_id,
        user_id,
        new_aware,
        new_appeal,
        new_action,
        new_advocate,
        grass_region,
        grass_date
    from
    (
        select
            shop_id,
            campaign_id,
            user_id,
            case when yesterday_segment = 1 and day_before_yesterday_segment < yesterday_segment then 1 else 0 end as new_aware,
            case when yesterday_segment = 2 and day_before_yesterday_segment < yesterday_segment then 1 else 0 end as new_appeal,
            case when yesterday_segment = 3 and day_before_yesterday_segment < yesterday_segment then 1 else 0 end as new_action,
            case when yesterday_segment = 4 and day_before_yesterday_segment < yesterday_segment then 1 else 0 end as new_advocate,
            grass_region,
            grass_date
        from full_user_segment
    ) 
    where new_aware + new_appeal + new_action + new_advocate > 0
);