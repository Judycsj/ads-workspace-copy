-- task_code: data_paidadsmart.studio_4989310  asset_id: 4989310
create external table if not exists dwd_seller_cir__reg_s0_live
(
    shop_id bigint comment 'shop_id'
    ,ads_id bigint comment 'ads_id'
    ,item_id bigint comment 'item_id'
    ,placement bigint comment 'placement'
    ,ctime bigint comment 'ctime'
    ,mtime bigint comment 'mtime'
    ,status int comment 'status'
    ,cir double comment 'cir'
    , create_datetime string
    , modify_datetime string
    , final_value_list array<double>
    , product_placement int
    , user_id bigint
    , campaign_type int
    ,platform int
    ,campaign_id bigint
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${path}'
;

create or replace temporary view dim_product_campaign as
select * from
(SELECT
    campaign_id
    ,shop_id
    ,product_placement
    ,row_number() over(partition by campaign_id,shop_id order by campaign_modify_datetime) as rank  
from mp_paidads.dim_product_campaign__reg_s0_live
WHERE grass_region = upper('${region}')
AND grass_date = date('${grass_date}') 
)where rank = 1
;

create or replace temporary view campaign_tab as 
select 
    campaign_id
    ,daily_quota_usd as budget
    ,roi_two 
    ,campaign_start_datetime
    ,campaign_end_datetime
from mp_paidads.dim_campaign__reg_s0_live
where grass_date = DATE('${grass_date}')
and grass_region = UPPER('${region}')
and tz_type = 'local';

CREATE OR REPLACE TEMPORARY VIEW advertise_tab_df AS
 SELECT shopid AS shop_id
        , userid AS user_id
        , adsid AS ads_id
        , itemid AS item_id
        , campaignid as campaign_id
        , ctime 
        , mtime 
        , status
        , placement
        , target_broad_roi
        , 1 / target_broad_roi as cir
        , from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss') AS  create_datetime
        , from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss') AS  modify_datetime
        , grass_region
        , DATE('${grass_date}') AS grass_date
    FROM (
        SELECT
          shopid
        , userid
        , campaignid
        , adsid
        , itemid
        , ctime 
        , mtime 
        , case when decoded_extinfo.pricing_type = 4 then 0 
          when decoded_extinfo.pricing_type = 8 then 1 end as status
        , CASE 
            WHEN placement = 8      THEN ARRAY(802,805)
            WHEN placement = 33      THEN ARRAY(3327,3328,3337,3338,3339,3342,3348)
            ELSE ARRAY(placement) 
          END AS placement_array
        , case when placement = 40 then roi_two else decoded_extinfo.target_broad_roi / 100000.0 end AS target_broad_roi
        , ucase('${region}') as grass_region
      FROM(
        SELECT
           shopid
          , userid 
          , campaignid
          , adsid
          , itemid
          , ctime
          , mtime
          , status
          , placement
          , from_json(_decoded_extinfo, 'struct<keywords:array<
                                                    struct<
                                                    keyword:string,
                                                    price:string,
                                                    status:int,
                                                    match_type:int,
                                                    algorithm:string
                                                >>,
                                                target:struct<
                                                    price:string,
                                                    premium_rate:int,
                                                    base_price:string,
                                                    segments:array<struct<
                                                    segment_type_id:int,
                                                    segment_cluster_id:array<string>,
                                                    segment_premium_rate:string,
                                                    final_bid_price:string
                                                    >>
                                                >,
                                                target_roi:int,
                                                shop_customisation:struct<
                                                    display_title:string,
                                                    image_url:string,
                                                    collection_id:string
                                                >,
                                                banner:struct<
                                                    image_uri_pc:string,
                                                    image_uri_app:string,
                                                    keywords:array<string>,
                                                    landing_page_url:string
                                                >,
                                                display:struct<
                                                    image_pc:string,
                                                    image_mobile:string,
                                                    item_id:array<string>,
                                                    l1_cat_id:string,
                                                    under_promotion:boolean,
                                                    promo_discount_value:string,
                                                    promo_discount_unit:string,
                                                    copywriting_text:string,
                                                    target_url:string
                                                >,
                                                boost:struct<
                                                    id:string,
                                                    package_id:int,
                                                    price:string,
                                                    days:int,
                                                    est_views:string
                                                >,
                                                pricing_type:int,
                                                delivery:struct<
                                                    entry_points:array<int>,
                                                    entrances:array<int>
                                                >,
                                                auto_boost:struct<
                                                    algo_status:int
                                                >,
                                                target_broad_roi:int
                                                >') AS decoded_extinfo
          FROM mp_paidads.shopee_ads_${region}_db__advertisement_tab__reg_continuous_s0_live
          WHERE ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
          and placement in (4,8,40,33)
        )a
        left join campaign_tab e 
        on a.campaignid = e.campaign_id
    )b
    lateral view explode(placement_array) as placement
    
;

create or replace  temporary view target_roi as 
select  shop_id
        ,item_id
        ,ads_id
        ,array(final_value_1, final_value_2, final_value_3) as final_value_list
        ,user_id
        ,campaign_id
        ,campaign_type
        ,selected_target_roi
        ,status
        ,platform
        ,null as entry_point
from    (
    select  shop_id
            ,item_id
            ,ads_id
            ,final_value_1
            ,final_value_2
            ,final_value_3
            ,user_id
            ,campaign_id
            ,campaign_type
            ,selected_target_roi
            ,case when selected_target_roi_type = 1 then 0 when selected_target_roi_type = 2 then 1 end as status
            ,platform
            ,ROW_NUMBER() OVER (partition by shop_id, item_id, ads_id, user_id, campaign_id order by timestamp desc) as rank
    from    (
        select  shop_id
                ,timestamp
                ,recommendation.product_ads_info.item_id as item_id
                ,recommendation.product_ads_info.ads_id as ads_id
                ,recommendation.recommended_value_list[0].final_value / 100000.0 as final_value_1
                ,recommendation.recommended_value_list[1].final_value / 100000.0 as final_value_2
                ,recommendation.recommended_value_list[2].final_value / 100000.0 as final_value_3
                ,user_id
                ,recommendation.campaign_id as campaign_id
                ,recommendation.campaign_type as campaign_type
                ,recommendation.selected_target_roi as selected_target_roi
                ,recommendation.selected_target_roi_type as selected_target_roi_type
                ,platform
        from    (
            select  shop_id
                    ,explode_outer(recommendation_list) as recommendation
                    ,timestamp
                    ,user_id
                    ,platform
            from    mp_paidads.ods_log_target_roi_rcmd_log_hi__reg_s0_live
            where   grass_region = upper('${region}')
                    and grass_date >= date('${grass_date}')
                    and grass_date <= date_add(date('${grass_date}'), 1)
        ) a
    ) b
) c
where   rank = 1
;

create or replace  temporary view target_roi_two as 
select  shop_id
        ,item_id
        ,ads_id
        ,array(final_value_1, final_value_2, final_value_3) as final_value_list
        ,null as user_id 
        ,campaign_id
        ,null as campaign_type
        ,selected_target_roi
        ,null as status
        ,platform
        ,entry_point
from    (
    select  b.shop_id
            ,b.campaign_id
            ,c.item_id
            ,c.ads_id
            ,final_value_1
            ,final_value_2
            ,final_value_3
            ,platform
            ,selected_target_roi
            ,entry_point
            ,ROW_NUMBER() OVER (partition by b.shop_id, b.campaign_id order by timestamp desc) as rank
    from    (
        select  shop_id
                ,timestamp
                ,recommendation.campaign_id as campaign_id
                ,recommendation.recommended_value_list[0].final_value / 100000.0 as final_value_1
                ,recommendation.recommended_value_list[1].final_value / 100000.0 as final_value_2
                ,recommendation.recommended_value_list[2].final_value / 100000.0 as final_value_3
                ,recommendation.final_selected_value as selected_target_roi
                ,platform
                ,entry_point
        from    (
            select  shop_id
                    ,explode_outer(recommendation_list) as recommendation
                    ,timestamp
                    ,platform
                    ,entry_point
            from    mp_paidads.ods_log_target_roi_two_rcmd_log_hi__reg_s0_live
            where   grass_region = upper('${region}')
                    and grass_date >= date('${grass_date}')
                    and grass_date <= date_add(date('${grass_date}'), 1)
        ) a
    ) b
    left join mp_paidads.dim_advertise_roi_exp__reg_s0_live c
    on b.shop_id = c.shop_id
    and b.campaign_id = c.campaign_id
    and  c.grass_region = upper('${region}')
    and c.grass_date = DATE('${grass_date}')
) d
where   rank = 1
;


INSERT OVERWRITE TABLE dwd_seller_cir__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    a.shop_id
    ,a.ads_id
    ,a.item_id
    ,a.placement
    ,a.ctime
    ,a.mtime
    ,case when array_contains(coalesce(a.final_value_list, d.final_value_list), coalesce(a.target_broad_roi,d.target_broad_roi)) then 2 else coalesce(a.status,d.status) end as status
    ,coalesce(a.cir, d.cir) as cir
    ,a.create_datetime
    ,a.modify_datetime
    ,coalesce(a.final_value_list, d.final_value_list) as final_value_list
    ,coalesce(a.product_placement, d.product_placement) as product_placement
    ,coalesce(a.user_id, d.user_id) as user_id
    ,coalesce(a.campaign_type, d.campaign_type) as campaign_type
    ,coalesce(a.platform, d.platform) as platform
    ,a.campaign_id
    ,coalesce(a.suggest_roi_entry_point, d.suggest_roi_entry_point) as suggest_roi_entry_point
    ,upper('${region}') as grass_region
    ,DATE('${grass_date}') as grass_date
from (
    SELECT a.shop_id as shop_id
            , a.ads_id as ads_id
            , a.item_id  as item_id
            , placement
            , ctime 
            , mtime 
            -- , case when array_contains(final_value_list, target_broad_roi) then 2 else a.status end as status 
            ,target_broad_roi  
            ,a.status as status      
            , cir
            , create_datetime
            , modify_datetime
            , final_value_list
            , product_placement
            , a.user_id
            , campaign_type
            , c.platform
            , a.campaign_id
            , c.entry_point as suggest_roi_entry_point
            , grass_region
            , grass_date
    from advertise_tab_df a
    left join 
    (
        SELECT * FROM target_roi
        UNION ALL
        SELECT * FROM target_roi_two
    )c 
    on a.shop_id = c.shop_id
    and a.ads_id = c.ads_id
    and a.item_id = c.item_id
    left join dim_product_campaign d
    on a.campaign_id = d.campaign_id
    and a.shop_id = d.shop_id
    where a.placement in (4, 802, 805, 40)
    union all 
    select 
            ls.shop_id as shop_id
            , ls.ads_id as ads_id
            , ls.item_id  as item_id
            , placement
            , ctime 
            , mtime 
            -- , case when array_contains(final_value_list, (selected_target_roi / 100000.0)) then 2 else target_roi.status end as status    
            ,coalesce(target_roi.selected_target_roi / 100000.0,roi2.selected_target_roi / 100000.0,roi_two) as target_broad_roi  
            ,target_roi.status as status    
            , 1 / (coalesce(target_roi.selected_target_roi / 100000.0,roi2.selected_target_roi / 100000.0,roi_two)) AS cir
            , create_datetime
            , modify_datetime
            , coalesce(target_roi.final_value_list,roi2.final_value_list) as final_value_list
            , null as product_placement
            , ls.user_id
            , target_roi.campaign_type as campaign_type
            , coalesce(target_roi.platform,roi2.platform) as platform
            ,ls.campaign_id
            ,roi2.entry_point as suggest_roi_entry_point
            , grass_region
            , grass_date
    from advertise_tab_df ls
    left join target_roi  
    on ls.user_id = target_roi.user_id
    and ls.campaign_id = target_roi.campaign_id
    left join target_roi_two roi2 
    on ls.shop_id = roi2.shop_id 
    and ls.campaign_id = roi2.campaign_id
    left join campaign_tab c
    on ls.campaign_id = c.campaign_id
    where ls.placement in (3327, 3328, 3337, 3338, 3339, 3342, 3348)
)a 
left join 
(   
    select * , round(1/cir,1) as target_broad_roi
    from dwd_seller_cir__reg_s0_live
    where
        grass_region = upper('${region}')
        and grass_date = date('${PREV_2D}')
) d 
on a.shop_id = d.shop_id
    and a.item_id = d.item_id
    and a.ads_id = d.ads_id
    and a.placement = d.placement
;

alter table dwd_seller_cir__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');