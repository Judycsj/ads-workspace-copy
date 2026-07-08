-- task_code: data_paidadsmart.studio_9164188  asset_id: 9164188
create external table if not exists ads_campaign_auto_rebate_details_1d__reg_s0_live
(
    shop_id bigint comment 'shop_id'
    ,item_id bigint comment 'item_id'
    ,campaign_id bigint comment 'campaign_id'
    ,if_has_seller_negative_behavior tinyint comment 'seller_negative_behavior'
    ,fraud_tag tinyint
    ,if_appeal_success tinyint
    ,last_appeal_date string 
    ,last_fraud_date string
    ,fraud_explanation string
    ,fraud_effect_start_time string
    ,fraud_effect_end_time string
    ,auto_rebate_status string
    ,invalid_reason array<int>
    ,no_rebate_needed_type int 
    ,is_need_manual_review tinyint
    ,broad_order_cnt bigint
    ,broad_gmv_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,broad_gmv_usd double
    ,expenditure_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,expenditure_amt_usd double
    ,advv_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,advv_amt_usd double
    ,roi_ratio double
    ,original_rebate_amt bigint comment 'original_rebate_value=expenditure_usd-advv_usd/0.9,local currency, *10^5 (as platform need)'
    ,original_rebate_usd double
    ,expected_rebate_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,expected_rebate_usd double
    ,region_expected_rebate_amt_usd double comment 'expected_rebate_amt_usd by region level'
    ,target_roi2_region_net_ads_expenditure_amt_usd double
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_campaign_auto_rebate_details_1d__reg_s0_live'
;

create or replace temporary view target2_campaign as
select 
    campaign_id,item_id ,shop_id,pricing_type,grass_region
from mp_paidads.dim_advertise__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
and placement = 40 and pricing_type =11
and ads_status = 1
group by 1,2,3,4,5
union all 
select 
    campaign_id,null as item_id ,shop_id,pricing_type,grass_region
from mp_paidads.dim_advertise__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
and placement = 40 and pricing_type in (24,25)
and ads_status = 1
group by 1,2,3,4,5
;

create or replace temporary view ads_perf as
select 
    grass_region
    ,a.campaign_id as campaign_id
    ,shop_id
    ,pricing_type
    ,expenditure_amt_local
    ,expenditure_amt_usd
    ,broad_order_cnt
    ,broad_gmv_amt_local
    ,broad_gmv_amt_usd
    ,advv_local
    ,advv_usd
    ,advv_with_rapid_amt_local
    ,advv_with_rapid_amt_usd
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv_local
    ,paid_broad_order_gmv_usd
    ,paid_advv_amt_local
    ,paid_advv_amt_usd
    ,paid_advv_with_rapid_amt_local
    ,paid_advv_with_rapid_amt_usd
from (
select 
    grass_region
    ,campaign_id
    ,sum(expenditure_amt_local) as expenditure_amt_local
    ,sum(expenditure_amt_usd) as expenditure_amt_usd
    ,sum(case when broad_gmv_amt_local > 0 then broad_order_cnt else 0 end) as broad_order_cnt
    ,sum(broad_gmv_amt_local) as broad_gmv_amt_local
    ,sum(broad_gmv_amt_usd) as broad_gmv_amt_usd
    ,sum(broad_gmv_amt_local * target_cir) as advv_local
    ,sum(broad_gmv_amt_usd * target_cir) as advv_usd
    ,sum(case when rapid_boost_toggle=true or campaign_surge_toggle=true then broad_gmv_amt_local * target_cir else broad_gmv_amt_local * target_cir/0.9 end) as advv_with_rapid_amt_local
    ,sum(case when rapid_boost_toggle=true or campaign_surge_toggle=true then broad_gmv_amt_usd * target_cir else broad_gmv_amt_usd * target_cir/0.9 end) as advv_with_rapid_amt_usd
    
    ,sum(case when paid_broad_order_gmv > 0 then paid_broad_order_cnt else 0 end) as paid_broad_order_cnt
    ,sum(paid_broad_order_gmv) as paid_broad_order_gmv_local
    ,sum(paid_broad_gmv_usd) as paid_broad_order_gmv_usd
    ,sum(paid_broad_order_gmv * target_cir) as paid_advv_amt_local
    ,sum(paid_broad_gmv_usd * target_cir) as paid_advv_amt_usd
    ,sum(case when rapid_boost_toggle=true or campaign_surge_toggle=true then paid_broad_order_gmv * target_cir else paid_broad_order_gmv * target_cir/0.9 end) as paid_advv_with_rapid_amt_local
    ,sum(case when rapid_boost_toggle=true or campaign_surge_toggle=true then paid_broad_gmv_usd * target_cir else paid_broad_gmv_usd * target_cir/0.9 end) as paid_advv_with_rapid_amt_usd
from mp_paidads.dwd_advertise_performance_di__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
and placement = 40 and pricing_type in (11,24,25)
and campaign_id is not null
group by 1,2
)a left join (
    select campaign_id,shop_id,pricing_type
    from mp_paidads.dim_advertise__reg_s0_live
    where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and tz_type = 'local' and pricing_type in (11,24,25)
    group by 1,2,3
)b on a.campaign_id=b.campaign_id
;


create or replace temporary view delete_campaign as
select 
    campaign_id
from mp_paidads.dim_advertise__reg_s0_live
where grass_region = upper('${region}')
and grass_date = date_sub(DATE('${grass_date}'),1)
and tz_type = 'local'
and placement = 40 
and pricing_type in (11,24,25)
and campaign_status in (0,7)
group by 1
;


create or replace temporary view dim_whitelist_roi2 as
select a.shop_id
from (
    select shop_id
    from mp_paidads.dim_advertiser__reg_s0_live
    where grass_region = upper('${region}')
    and grass_date = DATE('${grass_date}') and shop_id is not null 
)a left join (
    select 
        shop_id 
    from mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live
    where grass_region = upper('${region}')
    and grass_date = DATE('${grass_date}')
    group by 1
)b on a.shop_id = b.shop_id
where b.shop_id is null
;

create or replace temporary view dim_whitelist_gms as
select shop_id
from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null  and type = 1
group by 1
;

create or replace temporary view dim_whitelist_mpd as
select shop_id
from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null and type = 2
group by 1
;


create or replace temporary view active_campaign as
select 
    coalesce(a.campaign_id,b.campaign_id) as campaign_id
    ,coalesce(a.shop_id,b.shop_id) as shop_id
    ,coalesce(a.pricing_type,b.pricing_type) as pricing_type
    ,a.item_id
    ,coalesce(a.grass_region,b.grass_region) as grass_region
    ,coalesce(expenditure_amt_local,0) as expenditure_amt_local
    ,coalesce(expenditure_amt_usd,0.0) as expenditure_amt_usd
    ,coalesce(broad_order_cnt,0) as broad_order_cnt
    ,coalesce(broad_gmv_amt_local,0) as broad_gmv_amt_local
    ,coalesce(broad_gmv_amt_usd,0.0) as broad_gmv_amt_usd
    ,coalesce(advv_local,0) as advv_local
    ,coalesce(advv_usd,0.0) as advv_usd
    ,coalesce(advv_with_rapid_amt_local,0) as advv_with_rapid_amt_local
    ,coalesce(advv_with_rapid_amt_usd,0.0) as advv_with_rapid_amt_usd
    ,coalesce(paid_broad_order_cnt,0) as paid_broad_order_cnt
    ,coalesce(paid_broad_order_gmv_local,0) as paid_broad_order_gmv_local
    ,coalesce(paid_broad_order_gmv_usd,0.0) as paid_broad_order_gmv_usd
    ,coalesce(paid_advv_amt_local,0) as paid_advv_amt_local
    ,coalesce(paid_advv_amt_usd,0.0) as paid_advv_amt_usd
    ,coalesce(paid_advv_with_rapid_amt_local,0) as paid_advv_with_rapid_amt_local
    ,coalesce(paid_advv_with_rapid_amt_usd,0.0) as paid_advv_with_rapid_amt_usd
from target2_campaign  a 
full join ads_perf b 
on a.campaign_id = b.campaign_id
left join delete_campaign c 
on coalesce(a.campaign_id,b.campaign_id)  = c.campaign_id 
where c.campaign_id is null
;

cache table auto_rebate OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select 
    grass_region
    ,campaign_id
    ,a.shop_id as shop_id
    ,item_id
    ,pricing_type
    ,expenditure_amt_local
    ,expenditure_amt_usd
    ,broad_order_cnt
    ,broad_gmv_amt_local
    ,broad_gmv_amt_usd
    ,advv_local
    ,advv_usd
    ,advv_with_rapid_amt_local
    ,advv_with_rapid_amt_usd

    ,case when broad_order_cnt < 5 then 1 
        when expenditure_amt_local <= 0 or round(advv_with_rapid_amt_local / expenditure_amt_local,2) >= 1 then 2 end as no_rebate_needed_type

    ,round(advv_local / expenditure_amt_local,2) as roi_ratio
    ,expenditure_amt_local - advv_with_rapid_amt_local as original_rebate_amt
    ,expenditure_amt_usd - advv_with_rapid_amt_usd as original_rebate_amt_usd
    ,case when broad_order_cnt >= 5 and round(advv_with_rapid_amt_local / expenditure_amt_local,2) < 1  then expenditure_amt_local - advv_with_rapid_amt_local else 0 end as expected_rebate_amt
    ,case when broad_order_cnt >= 5 and round(advv_with_rapid_amt_usd/expenditure_amt_usd,2) < 1  then expenditure_amt_usd - advv_with_rapid_amt_usd else 0 end as expected_rebate_amt_usd

    ,paid_broad_order_cnt
    ,paid_broad_order_gmv_local
    ,paid_broad_order_gmv_usd
    ,paid_advv_amt_local
    ,paid_advv_amt_usd
    ,paid_advv_with_rapid_amt_local
    ,paid_advv_with_rapid_amt_usd
    ,round(paid_advv_amt_local / expenditure_amt_local,2) as paid_roi_ratio
    ,expenditure_amt_local - paid_advv_with_rapid_amt_local as paid_original_rebate_amt
    ,expenditure_amt_usd - paid_advv_with_rapid_amt_usd as  paid_original_rebate_usd
    ,case when broad_order_cnt >= 5 and round(paid_advv_with_rapid_amt_local / expenditure_amt_local,2) < 1  then expenditure_amt_local - paid_advv_with_rapid_amt_local else 0 end as paid_expected_rebate_amt
    ,case when broad_order_cnt >= 5 and round(paid_advv_with_rapid_amt_usd/expenditure_amt_usd,2) < 1  then expenditure_amt_usd - paid_advv_with_rapid_amt_usd else 0 end as paid_expected_rebate_usd
from dim_whitelist_roi2 w
join active_campaign a on w.shop_id = a.shop_id
where a.pricing_type = 11
union all 
select 
    grass_region
    ,campaign_id
    ,a.shop_id as shop_id
    ,item_id
    ,pricing_type
    ,expenditure_amt_local
    ,expenditure_amt_usd
    ,broad_order_cnt
    ,broad_gmv_amt_local
    ,broad_gmv_amt_usd
    ,advv_local
    ,advv_usd
    ,advv_with_rapid_amt_local
    ,advv_with_rapid_amt_usd

    ,case when (broad_order_cnt < 5 and pricing_type =25) or (broad_order_cnt < 10 and pricing_type=24) then 1 
        when expenditure_amt_local <= 0 or round(advv_with_rapid_amt_local / expenditure_amt_local,2) >= 1 then 2 end as no_rebate_needed_type

    ,round(advv_local / expenditure_amt_local,2) as roi_ratio
    ,expenditure_amt_local - advv_with_rapid_amt_local as original_rebate_amt
    ,expenditure_amt_usd - advv_with_rapid_amt_usd as original_rebate_amt_usd
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(advv_with_rapid_amt_local / expenditure_amt_local,2) < 1  then expenditure_amt_local - advv_with_rapid_amt_local else 0 end as expected_rebate_amt
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(advv_with_rapid_amt_usd/expenditure_amt_usd,2) < 1  then expenditure_amt_usd - advv_with_rapid_amt_usd else 0 end as expected_rebate_amt_usd

    ,paid_broad_order_cnt
    ,paid_broad_order_gmv_local
    ,paid_broad_order_gmv_usd
    ,paid_advv_amt_local
    ,paid_advv_amt_usd
    ,paid_advv_with_rapid_amt_local
    ,paid_advv_with_rapid_amt_usd
    ,round(paid_advv_amt_local / expenditure_amt_local,2) as paid_roi_ratio
    ,expenditure_amt_local - paid_advv_with_rapid_amt_local as paid_original_rebate_amt
    ,expenditure_amt_usd - paid_advv_with_rapid_amt_usd as  paid_original_rebate_usd
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(paid_advv_with_rapid_amt_local / expenditure_amt_local,2) < 1  then expenditure_amt_local - paid_advv_with_rapid_amt_local else 0 end as paid_expected_rebate_amt
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(paid_advv_with_rapid_amt_usd/expenditure_amt_usd,2) < 1  then expenditure_amt_usd - paid_advv_with_rapid_amt_usd else 0 end as paid_expected_rebate_usd
from dim_whitelist_mpd w
join active_campaign a on w.shop_id = a.shop_id
where a.pricing_type =25
union all 
select 
    grass_region
    ,campaign_id
    ,a.shop_id as shop_id
    ,item_id
    ,pricing_type
    ,expenditure_amt_local
    ,expenditure_amt_usd
    ,broad_order_cnt
    ,broad_gmv_amt_local
    ,broad_gmv_amt_usd
    ,advv_local
    ,advv_usd
    ,advv_with_rapid_amt_local
    ,advv_with_rapid_amt_usd

    ,case when (broad_order_cnt < 5 and pricing_type =25) or (broad_order_cnt < 10 and pricing_type=24) then 1 
        when expenditure_amt_local <= 0 or round(advv_with_rapid_amt_local / expenditure_amt_local,2) >= 1 then 2 end as no_rebate_needed_type

    ,round(advv_local / expenditure_amt_local,2) as roi_ratio
    ,expenditure_amt_local - advv_with_rapid_amt_local as original_rebate_amt
    ,expenditure_amt_usd - advv_with_rapid_amt_usd as original_rebate_amt_usd
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(advv_with_rapid_amt_local / expenditure_amt_local,2) < 1  then expenditure_amt_local - advv_with_rapid_amt_local else 0 end as expected_rebate_amt
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(advv_with_rapid_amt_usd/expenditure_amt_usd,2) < 1  then expenditure_amt_usd - advv_with_rapid_amt_usd else 0 end as expected_rebate_amt_usd

    ,paid_broad_order_cnt
    ,paid_broad_order_gmv_local
    ,paid_broad_order_gmv_usd
    ,paid_advv_amt_local
    ,paid_advv_amt_usd
    ,paid_advv_with_rapid_amt_local
    ,paid_advv_with_rapid_amt_usd
    ,round(paid_advv_amt_local / expenditure_amt_local,2) as paid_roi_ratio
    ,expenditure_amt_local - paid_advv_with_rapid_amt_local as paid_original_rebate_amt
    ,expenditure_amt_usd - paid_advv_with_rapid_amt_usd as  paid_original_rebate_usd
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(paid_advv_with_rapid_amt_local / expenditure_amt_local,2) < 1  then expenditure_amt_local - paid_advv_with_rapid_amt_local else 0 end as paid_expected_rebate_amt
    ,case when ((broad_order_cnt >= 5 and pricing_type = 25) or (broad_order_cnt >= 10 and pricing_type=24)) and round(paid_advv_with_rapid_amt_usd/expenditure_amt_usd,2) < 1  then expenditure_amt_usd - paid_advv_with_rapid_amt_usd else 0 end as paid_expected_rebate_usd
from dim_whitelist_gms w
join active_campaign a on w.shop_id = a.shop_id
where a.pricing_type =24
;

create or replace temporary view net_rev as
select 
    grass_region
    ,sum(net_ads_revenue_usd_1d) as target_roi2_region_net_ads_expenditure_amt_usd
from mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
and placement = 40 
and pricing_type in (11,24,25)
group by 1
;

create or replace temporary view total_rebate as
select 
    grass_region
    ,sum(expected_rebate_amt_usd) as region_expected_rebate_amt_usd
from auto_rebate 
group by 1
;

create or replace temporary view cap as
select 
    grass_region
    ,cast(rebate_amt_cap as double) as rebate_amt_cap
    ,cast(manual_review_threshold as double) as manual_review_threshold
from mp_paidads.dim_auto_rebate_cap__reg_s0_live 
where grass_region = upper('${region}')
group by 1,2,3
;


insert overwrite table ads_campaign_auto_rebate_details_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select 
    shop_id 
    ,item_id
    ,campaign_id
    ,null as if_has_seller_negative_behavior
    ,null as fraud_tag
    ,null as if_appeal_success
    ,null as last_appeal_success_date
    ,null as last_fraud_date
    ,null as fraud_explanation
    ,null as fraud_effect_start_time
    ,null as fraud_effect_end_time
    ,null as auto_rebate_status
    ,null as invalid_reason

    ,no_rebate_needed_type
    ,case when region_expected_rebate_amt_usd > target_roi2_region_net_ads_expenditure_amt_usd * manual_review_threshold then 1 else 0 end as is_need_manual_review
    
    ,broad_order_cnt
    ,round(broad_gmv_amt_local * 100000)
    ,broad_gmv_amt_usd
    ,round(expenditure_amt_local * 100000)
    ,expenditure_amt_usd
    ,round(advv_local * 100000)
    ,advv_usd
    
    ,roi_ratio
    ,round(original_rebate_amt * 100000)
    ,original_rebate_amt_usd
    ,round(least(expected_rebate_amt * 100000, expenditure_amt_local * rebate_amt_cap * 100000 ))
    ,least(expected_rebate_amt_usd, expenditure_amt_usd * rebate_amt_cap)
    
    ,region_expected_rebate_amt_usd
    ,target_roi2_region_net_ads_expenditure_amt_usd

    ,round(advv_with_rapid_amt_local * 100000)
    ,advv_with_rapid_amt_usd


    ,paid_broad_order_cnt
    ,round(paid_broad_order_gmv_local * 100000)
    ,paid_broad_order_gmv_usd
    ,round(paid_advv_amt_local * 100000)
    ,paid_advv_amt_usd
    ,round(paid_advv_with_rapid_amt_local * 100000)
    ,paid_advv_with_rapid_amt_usd
    ,paid_roi_ratio
    ,round(paid_original_rebate_amt * 100000)
    ,paid_original_rebate_usd
    ,round(least(paid_expected_rebate_amt * 100000, expenditure_amt_local * rebate_amt_cap * 100000 ))
    ,least(paid_expected_rebate_usd, expenditure_amt_usd * rebate_amt_cap)
    ,pricing_type
    ,upper('${region}')
    ,DATE('${grass_date}')
from auto_rebate a 
left join total_rebate b 
on a.grass_region = b.grass_region 
left join net_rev c 
on a.grass_region = c.grass_region 
left join cap d 
on a.grass_region = d.grass_region 
;