-- task_code: data_paidadsmart.studio_9096786  asset_id: 9096786
create external table if not exists ads_advertise_simple2_key_metrics_nd__reg_s0_live
(
    ads_id  bigint comment 'ads_id'
    ,shop_id  bigint comment 'shop_id'
    ,campaign_id bigint  comment 'campaign_id'
    ,item_id  bigint  comment 'item_id'
    ,click_cnt_14d bigint comment '14 days click_cnt'
    ,broad_order_cnt_14d bigint comment '14 days broad_order_cnt'
    ,broad_order_gmv_amt_usd_14d double comment '14 days broad_order_gmv, local currency'
    ,expenditure_amt_usd_14d double comment '14 days ads expenditure amt, local currency'
    ,impression_cnt_1d  bigint comment 'impression_cnt'
    ,click_cnt_1d  bigint comment 'click_cnt'
    ,direct_order_cnt_1d  bigint  comment 'direct_order_cnt'
    ,direct_order_gmv_amt_usd_1d double comment 'direct_order_gmv, local currency'
    ,broad_order_cnt_1d   bigint comment 'broad_order_cnt'
    ,broad_order_gmv_amt_usd_1d double comment 'broad_order_gmv, local currency'
    ,expenditure_amt_usd_1d double  comment 'ads expenditure amt, local currency'
    ,limit_type int comment '0-unlimit budget, 1-limit budget'
    ,campaign_valid_budget_amt_usd double comment 'campaign_valid_budget, local currency'
    ,is_hit_budget tinyint comment 'case
        when campaign_valid_budget_amt_usd > 0 and expenditure_amt_usd_1d > campaign_valid_budget_amt_usd * 0.97 then 1
        else 0'
    ,net_expenditure_amt_usd_1d double comment 'net ads expenditure amt'
    ,est_roi_lower double comment 'est roi lower bound'
    ,est_roi_upper double comment 'est roi upper bound'
    ,est_7days_order_lower double comment 'est_7days_order_lower_bound'
    ,est_7days_order_upper double comment 'est_7days_order_upper_bound'
    ,input_budget_amt double comment 'input_budget_amt'
    ,final_recommended_budget_amt  double comment 'final_recommended_budget_amt'
    ,is_cb_shop tinyint comment '1-cb shop, 0-local shop'
    ,seller_type_1p string comment 'seller_type_1p'
    ,target_cir double comment 'target_cir'
    ,cpa  double comment 'target_cir*item_price'
    ,advv_14d double comment '14 days advv'
    ,impression_cnt_14d bigint comment '14 days impression_cnt'
    ,status_combine string comment 'case when campaign_status = 1 and ads_status = 1 then normal'
    ,expenditure_amt_usd_3d double comment '3 days expenditure_am'
    ,advv_3d double comment '3 days advv'
    ,is_migrated_item tinyint comment 'is_migrated_item'
    ,item_first_adopted_date date comment 'item_first_adopted_date'
    ,click_cnt_7d bigint comment '7 days click_cnt'
    ,broad_order_cnt_7d  bigint comment '7 days broad_order_cnt'
    ,broad_order_gmv_amt_usd_7d  double comment '7 days broad_order_gmv'
    ,expenditure_amt_usd_7d double comment '7 days expenditure_am'
    ,advv_7d double comment '7 days advv'
    ,impression_cnt_7d bigint comment '7 days impression_cnt'
    ,advv_1d double comment '1 day advv'
    ,roi_group_7d_system string comment 'Groupings based on whether the estimated ROI lower/upper bound meets the target'
    ,roi_group_7d_seller string comment 'Group according to whether the estimated ROI lower/upper bounds meet the standard, combined with a 0.8-1.2 coefficient.'
    ,is_cold_start_stage tinyint comment 'Is the latest status of ads on the day in the cold start phase'
    ,paid_broad_order_gmv_amt_usd_1d double comment 'paid_broad_order gmv amount, usd currency'
    ,paid_broad_order_cnt_1d bigint comment 'paid_broad_order_cnt'
    ,paid_advv_1d double comment '1 day paid advv, paid_advv=paid_broad_gmv_usd*target_cir'
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_advertise_simple2_key_metrics_nd__reg_s0_live'
;

create or replace temporary view net_rev as 
select ads_id 
        ,sum(net_ads_revenue_usd_1d) as net_expenditure_amt_usd_1d
from mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
where   grass_region = upper('${region}')
        and grass_date = DATE('${grass_date}')
        and tz_type = 'local'
        and pricing_type = 15 
group by 1
;


create or replace temporary view perf_metrics as
select 
    ads_id
    ,sum(impression_cnt) as impression_cnt_1d 
    ,sum(deduplicated_click) as click_cnt_1d 
    ,sum(order_cnt) as direct_order_cnt_1d 
    ,sum(ads_order_gmv_usd) as direct_order_gmv_amt_usd_1d
    ,sum(broad_order_cnt) as broad_order_cnt_1d 
    ,sum(broad_gmv_amt_usd) as broad_order_gmv_amt_usd_1d
    ,sum(expenditure_amt_usd) as expenditure_amt_usd_1d
    ,avg(case when impression_cnt > 0 then target_cir end) as target_cir 
    ,avg(case when impression_cnt > 0 then item_price/100000 end) as item_price
    ,sum(broad_gmv_amt_usd*target_cir) as advv_1d
    ,sum(paid_broad_order_cnt) as paid_broad_order_cnt_1d 
    ,sum(paid_broad_gmv_usd) as paid_broad_order_gmv_amt_usd_1d
    ,sum(paid_broad_gmv_usd*target_cir) as paid_advv_1d
from mp_paidads.dwd_advertise_performance_di__reg_s0_live
where grass_region = upper('${region}')
        and grass_date = DATE('${grass_date}')
        and tz_type = 'local'
        and pricing_type = 15 
group by 1
;

create or replace temporary view valid_budget as
select
    grass_region
    ,campaign_id
    ,if(budget_usd = 9999999999, 0, 1) as limit_type
    ,campaign_valid_budget_usd
    ,ads_expenditure_usd as campaign_expenditure_amt_usd
    ,case
        when campaign_valid_budget_usd > 0 and ads_expenditure_usd > campaign_valid_budget_usd * 0.97 then 1
        else 0
    end as is_hit_budget
from mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live
where
    grass_region = upper('${region}')
    and grass_date = DATE('${grass_date}')
    and tz_type = 'local'
group by 1,2,3,4,5,6
;

create or replace temporary view l14d_metrics as
select 
    ads_id
    ,campaign_id
    ,grass_region
    ,sum(deduplicated_click) as click_cnt_14d 
    ,sum(broad_order_cnt) as broad_order_cnt_14d 
    ,sum(broad_gmv_amt_usd) as broad_order_gmv_amt_usd_14d
    ,sum(expenditure_amt_usd) as expenditure_amt_usd_14d
    ,sum(broad_gmv_amt_usd*target_cir) as advv_14d
    ,sum(impression_cnt) as impression_cnt_14d
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '6' day then deduplicated_click else 0 end) as click_cnt_7d 
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '6' day then broad_order_cnt else 0 end) as broad_order_cnt_7d 
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '6' day then broad_gmv_amt_usd else 0 end) as broad_order_gmv_amt_usd_7d
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '6' day then expenditure_amt_usd else 0 end) as expenditure_amt_usd_7d
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '6' day then broad_gmv_amt_usd*target_cir else 0 end) as advv_7d
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '6' day then impression_cnt else 0 end) as impression_cnt_7d
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '2' day then expenditure_amt_usd end) as expenditure_amt_usd_3d
    ,sum(case when grass_date >= DATE('${grass_date}') - interval '2' day then broad_gmv_amt_usd*target_cir end) as advv_3d
    ,max(case when grass_date >= DATE('${grass_date}') - interval '6' day then 1 else 0 end) as has_performance_7d
from mp_paidads.dwd_advertise_performance_di__reg_s0_live 
where pricing_type = 15
    and grass_region = upper('${region}')
    and grass_date between DATE('${grass_date}') - interval '13' day and DATE('${grass_date}')
    and tz_type = 'local'
    and campaign_id is not null
    group by 1,2,3
;


create or replace temporary view rcmd_budget as
select *
    from (
    select campaign_id 
            -- ,est_roi_lower
            -- ,est_roi_upper
            -- ,est_7days_order_lower
            -- ,est_7days_order_upper
            ,input_budget
            ,recommended_budget
            ,grass_region
            ,row_number() over(partition by grass_region, campaign_id order by grass_date desc) as date_rk
    from mp_paidads.ods_log_simple_roi2_estimated_data_s0_live
    where 
        grass_date between date'2024-10-01' and DATE('${grass_date}')
        and grass_region = upper('${region}')
    )
    where date_rk = 1
;

create or replace temporary view estimate_roi_gmv as
select 
    campaign_id
    ,simple_roi_two_estimate.est_roi_lower_bound as est_roi_lower
    ,simple_roi_two_estimate.est_roi_upper_bound as est_roi_upper
    ,simple_roi_two_estimate.est_order_lower_bound as est_7days_order_lower
    ,simple_roi_two_estimate.est_order_upper_bound as est_7days_order_upper
from mp_paidads.dim_campaign__reg_s0_live
where grass_region = upper('${region}')
    and grass_date = DATE('${grass_date}')
    and tz_type = 'local'
;

create or replace temporary view cb_tag as
select
    shop_id
    ,case
        when seller_type_1p is null then 'unknow'
        else seller_type_1p
    end as seller_type_1p
    ,is_cb_shop
    ,grass_region
from cncbbi_general.shop_level_shop_info_shopee_td
where grass_region = upper('${region}')
group by 1, 2, 3, 4
;

create or replace temporary view dim_status as
select distinct
    ads_id
    ,campaign_id 
    ,item_id 
    ,shop_id
    ,grass_region
    ,case when campaign_status = 1 and ads_status = 1 then 1 else 0 end as status_combine
    ,date(ads_create_datetime) as ads_create_date
from mp_paidads.dim_advertise__reg_s0_live 
where grass_date = DATE('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and product_type = 'ROI2.0'
;


create or replace temporary view adopt_tag as
select item_id
        ,is_migrated_item
        ,item_first_adopted_date
from mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live
where grass_date = DATE('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
group by 1,2,3
;


create or replace temporary view ex_rate as
select grass_region
        ,exchange_rate
from mp_order.dim_exchange_rate__reg_s0_live
where grass_date = DATE('${grass_date}')
    and grass_region = upper('${region}')
    -- and tz_type = 'local'
;

create or replace temporary view perf_cold_start_stage as
select 
    ads_id 
    ,is_cold_start_stage
from
(    select 
        ads_id
        ,bit_get(ad_tag, 34) as is_cold_start_stage
        ,row_number() over(partition by ads_id order by `timestamp` desc) as imp_rank
    from mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where grass_region = upper('${region}')
        and grass_date = DATE('${grass_date}')
        and tz_type = 'local'
        and pricing_type = 15 
        and impression_cnt > 0
)
where imp_rank = 1
;

insert overwrite TABLE ads_advertise_simple2_key_metrics_nd__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select b.ads_id 
        ,s.shop_id 
        ,b.campaign_id
        ,s.item_id 
        ,click_cnt_14d
        ,broad_order_cnt_14d
        ,broad_order_gmv_amt_usd_14d
        ,expenditure_amt_usd_14d

        ,impression_cnt_1d 
        ,click_cnt_1d 
        ,direct_order_cnt_1d 
        ,direct_order_gmv_amt_usd_1d
        ,broad_order_cnt_1d 
        ,broad_order_gmv_amt_usd_1d
        ,expenditure_amt_usd_1d

        ,limit_type
        ,campaign_valid_budget_usd
        ,is_hit_budget

        ,net_expenditure_amt_usd_1d

        ,est_roi_lower
        ,est_roi_upper
        ,est_7days_order_lower
        ,est_7days_order_upper
        ,input_budget
        ,recommended_budget

        ,COALESCE(is_cb_shop,0) as is_cb_shop
        ,seller_type_1p

        ,target_cir
        ,target_cir*item_price/exchange_rate as cpa 
        ,advv_14d
        ,impression_cnt_14d
        ,case when status_combine = 1 then 'normal' else 'abnormal' end as status_combine
        ,expenditure_amt_usd_3d
        ,advv_3d
        ,is_migrated_item
        ,item_first_adopted_date
        
        ,click_cnt_7d 
        ,broad_order_cnt_7d 
        ,broad_order_gmv_amt_usd_7d 
        ,expenditure_amt_usd_7d 
        ,advv_7d 
        ,impression_cnt_7d 
        ,advv_1d
        ,case
            when est_roi_lower is null or est_roi_upper is null then '6. Null db_value'
            when coalesce(expenditure_amt_usd_7d, 0)  =0  then '5. No rev'
            when coalesce(broad_order_gmv_amt_usd_7d , 0)  = 0 then '4. No GMV'
            when coalesce(broad_order_gmv_amt_usd_7d , 0) /expenditure_amt_usd_7d  < est_roi_lower then '1. Overbid'
            when coalesce(broad_order_gmv_amt_usd_7d , 0) /expenditure_amt_usd_7d  >= est_roi_lower and coalesce(broad_order_gmv_amt_usd_7d , 0) / expenditure_amt_usd_7d  <= est_roi_upper then '2. Fulfilled'
            when coalesce(broad_order_gmv_amt_usd_7d , 0) /expenditure_amt_usd_7d  > est_roi_upper   then '3. Underbid'
            else '7. Others'
        end as roi_group_7d_system
        ,case 
            when  est_roi_lower is null or est_roi_upper is null then '7. Null db_value'
            when coalesce(expenditure_amt_usd_7d, 0)  =0  then '6. No rev'
            when coalesce(broad_order_gmv_amt_usd_7d , 0) = 0 then '5. No GMV'
            when coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) <0.8 * est_roi_lower and coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) < est_roi_upper then '1. Overbid'
            when coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) <= 1.2 * est_roi_lower and coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) < est_roi_upper then '2. Fulfil Strategy'
            when coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) > 1.2 * est_roi_lower and coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) <= est_roi_upper then '3. System Underbid'
            when coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) > 1.2 * est_roi_lower and coalesce(broad_order_gmv_amt_usd_7d, 0)/ coalesce(expenditure_amt_usd_7d , 0) > est_roi_upper then '4. Underbid' 
            else '8. Others'
        end as roi_group_7d_seller
        
        ,is_cold_start_stage

        ,paid_broad_order_gmv_amt_usd_1d
        ,paid_broad_order_cnt_1d 
        ,paid_advv_1d

        ,b.grass_region
        ,DATE('${grass_date}') as grass_date
from (select * from l14d_metrics where has_performance_7d = 1) as b
left join dim_status as s 
on  b.campaign_id = s.campaign_id
and b.ads_id = s.ads_id
left join perf_metrics as c 
on b.ads_id = c.ads_id 
left join valid_budget as d 
on b.campaign_id = d.campaign_id 
and b.grass_region = d.grass_region
left join net_rev as n 
on b.ads_id  = n.ads_id 
left join estimate_roi_gmv as e 
on  b.campaign_id = e.campaign_id 
left join rcmd_budget r  
on  b.campaign_id = r.campaign_id 
and b.grass_region = r.grass_region
left join cb_tag as cb 
on cb.shop_id = s.shop_id 
left join adopt_tag as f 
on s.item_id = f.item_id 
left join ex_rate g 
on b.grass_region = g.grass_region
left join perf_cold_start_stage h 
on b.ads_id = h.ads_id
;