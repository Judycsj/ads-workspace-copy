-- task_code: data_paidadsmart.studio_6975543  asset_id: 6975543
CREATE EXTERNAL TABLE IF NOT EXISTS ads_region_roi2_key_metrics_daily__reg_s0_live
(
    roi2_ads_revenue_usd double
    ,roi2_ads_click_cnt bigint
    ,roi2_ads_impression_cnt bigint
    ,roi2_broad_gmv_usd double
    ,roi2_broad_order_cnt bigint
    ,roi2_active_ads_cnt bigint 
    ,roi2_active_ads_item_cnt bigint 
    ,roi2_active_advertiser_cnt bigint 
    ,roi2_whitelist_shop_cnt bigint 
    ,roi2_overbid_camp_1_rev_usd double
    ,roi2_overbid_camp_2_rev_usd double
    ,roi2_fulfilled_camp_1_rev_usd double
    ,roi2_fulfilled_camp_2_rev_usd double
    ,roi2_underbid_camp_1_rev_usd double
    ,roi2_underbid_camp_2_rev_usd double
    ,roi2_total_excl_nodata_camp_rev_usd double
    ,roi2_overbid_camp_1_cnt bigint 
    ,roi2_overbid_camp_2_cnt bigint 
    ,roi2_fulfilled_camp_1_cnt bigint 
    ,roi2_fulfilled_camp_2_cnt bigint 
    ,roi2_underbid_camp_1_cnt bigint 
    ,roi2_underbid_camp_2_cnt bigint 
    ,roi2_total_excl_nodata_camp_cnt bigint 
    ,roi2_valid_budget_usd double
    -- ,roi2_campaign_expenditure_usd
    ,roi2_valid_budget_limited_usd double
    ,roi2_campaign_expenditure_limited_usd double
    ,uplift_10p_item_cnt bigint 
    ,window_item_cnt bigint 
    ,uplift_10p_revenue_usd double
    ,window_revenue_usd double
    ,total_ads_revenue_usd double
    ,total_active_ads_cnt bigint 
    ,total_active_ads_item_cnt bigint 
    ,total_active_advertiser_cnt bigint 
    ,active_30d_advertiser_cnt bigint 
    ,roi2_active_30d_whitelist_shop_cnt bigint 
    ,total_net_ads_revenue_usd_1d double
    ,roi2_net_ads_revenue_usd_1d double
    ,roi2_paid_broad_gmv_usd double
    ,roi2_paid_broad_order_cnt bigint
)
COMMENT 'key metrics for roi2 key metrics. Granularity: grass_region, grass_date'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/ads_region_roi2_key_metrics_daily__reg_s0_live/'
;


create or replace temporary view roi2_ads_1d as (
    select 
        sum(ads_expenditure_amt_usd) as roi2_ads_revenue_usd
        ,sum(deduplicated_click_cnt) as roi2_ads_click_cnt
        ,sum(impression_cnt) as roi2_ads_impression_cnt
        ,sum(broad_order_gmv_amt_usd) as roi2_broad_gmv_usd
        ,sum(broad_order_cnt) as roi2_broad_order_cnt
        ,count(distinct if((is_ads_active = 1 or has_performance = 1), ads_id, null)) as roi2_active_ads_cnt
        ,count(distinct if((is_ads_active = 1 or has_performance = 1), item_id, null)) as roi2_active_ads_item_cnt
        ,count(distinct if((is_ads_active = 1 or has_performance = 1), shop_id, null)) as roi2_active_advertiser_cnt
        ,sum(cps_dedup_click_cnt) as roi2_cps_dedup_click_cnt
        ,sum(paid_broad_order_gmv_usd) as roi2_paid_broad_gmv_usd
        ,sum(paid_broad_order_cnt) as roi2_paid_broad_order_cnt
    from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where tz_type = 'local'
    and grass_date = date('${BIZ_YESTERDAY}')
    and grass_region = upper('${region}')
    and placement = 40
);

create or replace temporary view total_ads_1d as (
    select 
        sum(ads_expenditure_amt_usd) as total_ads_revenue_usd
        ,count(distinct if((is_ads_active = 1 or has_performance = 1), ads_id, null)) as total_active_ads_cnt
        ,count(distinct if((is_ads_active = 1 or has_performance = 1), item_id, null)) as total_active_ads_item_cnt
        ,count(distinct if((is_ads_active = 1 or has_performance = 1), shop_id, null)) as total_active_advertiser_cnt
    from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where tz_type = 'local'
    and grass_date = date('${BIZ_YESTERDAY}')
    and grass_region = upper('${region}')
);


create or replace temporary view roi2_whitelist_active_advertiser as (
    select
        count(distinct shop_id) as active_30d_advertiser_cnt      
    from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where
        tz_type = 'local'
        and (is_ads_active = 1 or has_performance = 1)
        and grass_date between date('${PREV_30D}') and date('${BIZ_YESTERDAY}')
        and grass_region = upper('${region}')
);


create or replace temporary view campaign_valid_budget as (
    select 
        sum(campaign_valid_budget_usd) as roi2_valid_budget_usd
        -- ,sum(ads_expenditure_usd) as roi2_campaign_expenditure_usd
        ,sum(if(budget_usd = 9999999999, 0, campaign_valid_budget_usd)) as roi2_valid_budget_limited_usd
        ,sum(if(budget_usd = 9999999999, 0, ads_expenditure_usd)) as roi2_campaign_expenditure_limited_usd
    from mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live a 
    join mp_paidads.dim_advertise_roi_exp__reg_s0_live b 
    on a.campaign_id = b.campaign_id
    where a.tz_type = 'local'
    and a.grass_date = date('${BIZ_YESTERDAY}')
    and a.grass_region = upper('${region}')
    and b.grass_date = date('${BIZ_YESTERDAY}')
    and b.grass_region = upper('${region}')
)
;

create or replace temporary view roi_ratio_group as (
    select 
         sum(case when roi_ratio_group = '0-0.5' then ads_rev_d0 end) as roi2_overbid_camp_1_rev_usd
        ,sum(case when roi_ratio_group = '0.5-0.8' then ads_rev_d0 end) as roi2_overbid_camp_2_rev_usd
        ,sum(case when roi_ratio_group = '0.8-1' then ads_rev_d0 end) as roi2_fulfilled_camp_1_rev_usd
        ,sum(case when roi_ratio_group = '1-1.2' then ads_rev_d0 end) as roi2_fulfilled_camp_2_rev_usd
        ,sum(case when roi_ratio_group = '1.2-2' then ads_rev_d0 end) as roi2_underbid_camp_1_rev_usd
        ,sum(case when roi_ratio_group = '2+' then ads_rev_d0 end) as roi2_underbid_camp_2_rev_usd
        ,sum(case when roi_ratio_group not in ('no data','no gmv','no rev') then ads_rev_d0 end) as roi2_total_excl_nodata_camp_rev_usd
        ,count(distinct case when roi_ratio_group = '0-0.5' then campaign_id end) as roi2_overbid_camp_1_cnt
        ,count(distinct case when roi_ratio_group = '0.5-0.8' then campaign_id end) as roi2_overbid_camp_2_cnt
        ,count(distinct case when roi_ratio_group = '0.8-1' then campaign_id end) as roi2_fulfilled_camp_1_cnt
        ,count(distinct case when roi_ratio_group = '1-1.2' then campaign_id end) as roi2_fulfilled_camp_2_cnt
        ,count(distinct case when roi_ratio_group = '1.2-2' then campaign_id end) as roi2_underbid_camp_1_cnt
        ,count(distinct case when roi_ratio_group = '2+' then campaign_id end) as roi2_underbid_camp_2_cnt
        ,count(distinct case when roi_ratio_group not in ('no data','no gmv','no rev') then campaign_id end) as roi2_total_excl_nodata_camp_cnt
    from (
        select  
            a.campaign_id
            ,ads_rev_d0
            ,case 
                when advv = 0 and ads_rev_7d > 0 then 'no gmv'
                when advv > 0 and ads_rev_7d = 0 then 'no rev'
                when roi_ratio < 0.5 then '0-0.5'
                when roi_ratio < 0.8 then '0.5-0.8'
                when roi_ratio < 1 then '0.8-1'
                when roi_ratio <= 1.2 then '1-1.2'
                when roi_ratio < 2 then '1.2-2'
                when roi_ratio >= 2 then '2+'
                else 'no data'
            end as roi_ratio_group 
        from 
        (
            select 
                campaign_id
                ,sum(coalesce(ads_expenditure_amt_usd,0)) as ads_rev_d0
            from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
            where tz_type = 'local'
            and grass_region = upper('${region}')
            and grass_date = date('${BIZ_YESTERDAY}')
            and placement = 40
            and (is_ads_active = 1 or has_performance > 0)
            group by campaign_id
        )a 
        left join 
        (
            select 
                campaign_id
                ,sum(coalesce(broad_gmv_amt_local * target_cir, 0)) as advv 
                ,sum(coalesce(expenditure_amt_local, 0)) as ads_rev_7d
                ,sum(coalesce(broad_gmv_amt_local * target_cir, 0)) / sum(coalesce(expenditure_amt_local, 0)) as roi_ratio
            from mp_paidads.dwd_advertise_performance_di__reg_s0_live
            where tz_type = 'local'
            and grass_region = upper('${region}')
            and grass_date between date('${PREV_7D}') and date('${BIZ_YESTERDAY}')
            and placement = 40
            group by campaign_id
        ) c
        on a.campaign_id = c.campaign_id
    )
);

create or replace temporary view platform_item_gmv as (  
    select
        item_id
        ,grass_date
        ,sum(gmv_usd_1d) as gmv_usd
        -- ,sum(paid_order_cnt_1d) as order_cnt
    from mp_order.dws_item_gmv_1d__reg_s0_live
    where
    grass_date between date('${BIZ_YESTERDAY}') - interval '20' day and date('${BIZ_YESTERDAY}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and gmv_usd_1d > 0
    group by 1,2
)
;

create or replace temporary view item_uplift as (
    select 
        count(1) as window_item_cnt
        ,sum(if(platform_gmv_w7d / platform_gmv_med14d - 1 >= 0.1,1,0)) as uplift_10p_item_cnt
        ,sum(ads_rev_w7d) as window_revenue_usd
        ,sum(if(platform_gmv_w7d / platform_gmv_med14d - 1 >= 0.1,ads_rev_w7d,0)) as uplift_10p_revenue_usd
    from
    (
        select
            ads_7d.item_id
            ,sum(ads_revenue_usd)/count(1) as ads_rev_w7d
            ,avg(gmv_usd) as platform_gmv_w7d
        from(  
            select 
                item_id
                ,grass_date
                ,sum(ads_expenditure_amt_usd) as ads_revenue_usd
            from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
            where tz_type = 'local'
            and grass_region = upper('${region}')
            and grass_date between date('${PREV_7D}') and date('${BIZ_YESTERDAY}')
            and placement = 40
            and (campaign_status = 1 or is_ads_active = 1)
            and date(COALESCE(campaign_end_datetime, '9999-01-01')) >= grass_date
            and has_performance > 0
            group by 1,2
        ) ads_7d 
        left join platform_item_gmv 
        on ads_7d.item_id = platform_item_gmv.item_id 
        and ads_7d.grass_date = platform_item_gmv.grass_date 
        group by 1
    ) window_7d 
    join(
        select
            ads_14d.item_id
            ,percentile(gmv_usd, 0.5) as platform_gmv_med14d
        from(  
            select 
                item_id
                -- ,ads_id
                ,grass_date
                ,sum(impression_cnt) as impression_cnt
            from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
            where tz_type = 'local'
            and grass_region = upper('${region}')
            and grass_date between date('${PREV_21D}') and date('${PREV_8D}')
            and placement not in (3, 20, 2003, 2030, 40)
            group by item_id, grass_date
            having sum(impression_cnt) > 0
        ) ads_14d 
        join platform_item_gmv
        on ads_14d.item_id = platform_item_gmv.item_id 
        and ads_14d.grass_date = platform_item_gmv.grass_date 
        group by 1
    )window_14d 
    on window_7d.item_id = window_14d.item_id
);

create or replace temporary view net_revenue as (
    select 
        sum(net_ads_revenue_usd_1d) as total_net_ads_revenue_usd_1d
        ,sum(if(placement = 40, net_ads_revenue_usd_1d, 0)) as roi2_net_ads_revenue_usd_1d
    from mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
    where tz_type = 'local'
    and grass_date = date('${BIZ_YESTERDAY}')
    and grass_region = upper('${region}')
)
;


INSERT OVERWRITE TABLE ads_region_roi2_key_metrics_daily__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    roi2_ads_revenue_usd
    ,roi2_ads_click_cnt
    ,roi2_ads_impression_cnt
    ,roi2_broad_gmv_usd
    ,roi2_broad_order_cnt
    ,roi2_active_ads_cnt
    ,roi2_active_ads_item_cnt
    ,roi2_active_advertiser_cnt
    ,null as roi2_whitelist_shop_cnt
    ,roi2_overbid_camp_1_rev_usd
    ,roi2_overbid_camp_2_rev_usd
    ,roi2_fulfilled_camp_1_rev_usd
    ,roi2_fulfilled_camp_2_rev_usd
    ,roi2_underbid_camp_1_rev_usd
    ,roi2_underbid_camp_2_rev_usd
    ,roi2_total_excl_nodata_camp_rev_usd
    ,roi2_overbid_camp_1_cnt
    ,roi2_overbid_camp_2_cnt
    ,roi2_fulfilled_camp_1_cnt
    ,roi2_fulfilled_camp_2_cnt
    ,roi2_underbid_camp_1_cnt
    ,roi2_underbid_camp_2_cnt
    ,roi2_total_excl_nodata_camp_cnt
    ,roi2_valid_budget_usd
    -- ,roi2_campaign_expenditure_usd
    ,roi2_valid_budget_limited_usd
    ,roi2_campaign_expenditure_limited_usd
    ,uplift_10p_item_cnt
    ,window_item_cnt
    ,uplift_10p_revenue_usd
    ,window_revenue_usd
    ,total_ads_revenue_usd
    ,total_active_ads_cnt
    ,total_active_ads_item_cnt
    ,total_active_advertiser_cnt
    ,active_30d_advertiser_cnt
    ,null as roi2_active_30d_whitelist_shop_cnt
    ,total_net_ads_revenue_usd_1d
    ,roi2_net_ads_revenue_usd_1d
    ,roi2_cps_dedup_click_cnt
    ,roi2_paid_broad_gmv_usd
    ,roi2_paid_broad_order_cnt
    ,upper('${region}') as grass_region
    ,DATE('${BIZ_YESTERDAY}') as grass_date   
from  roi2_ads_1d
    ,roi2_whitelist_active_advertiser
    , total_ads_1d
    , campaign_valid_budget
    , roi_ratio_group
    , item_uplift      
    , net_revenue