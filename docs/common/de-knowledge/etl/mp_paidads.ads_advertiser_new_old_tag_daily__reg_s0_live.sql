-- task_code: data_paidadsmart.studio_8990941  asset_id: 8990941
create external table if not exists ads_advertiser_new_old_tag_daily__reg_s0_live
(
    shop_id bigint comment '店铺ID'
    ,advertiser_lifeycle_type string comment '广告主生命周期' 
    ,advertiser_lifeycle_type_level2 string 
    ,advertiser_lifeycle_type_level3 string
    ,first_expenditure_date string comment '首次消耗日期'
    ,expenditure_amt_usd_30d double comment '近30日广告消耗'
    ,expenditure_amt_usd_60d double  comment '近60日广告消耗'
    ,avg_daily_expenditure_amt_usd_30d double  comment '近30日广告日均消耗'
    ,avg_daily_expenditure_amt_usd_60d double comment '前30-60日广告日均消耗'
    ,gmv_usd_60d double  comment '过去60天gmv'
) 
comment 'ads historical cumulative revenue from 2023.1.1'
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_advertiser_new_old_tag_daily__reg_s0_live'
;

create or replace temporary view rev as 
select 
    shop_id 
    ,ads_first_revenue_date  
from mp_paidads.ads_advertiser_new_old_base_metrics_daily__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
;


create or replace temporary view rev_nd as 
select 
    shop_id
    ,sum(expenditure_amt_usd_30d) as expenditure_amt_usd_30d --t-29,t
    ,sum(expenditure_amt_usd_60d) as expenditure_amt_usd_60d --t-59,t
    ,sum(expenditure_amt_usd_60d) - sum(expenditure_amt_usd_30d) as expenditure_amt_usd_30_60d --t-59,t-30
from mp_paidads.dws_advertise_performance_nd__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
group by 1 
;

create or replace temporary view arpu as 
select 
    shop_id
    ,min(case when coalesce(paid_expenditure_wo_expiry_amt_local_1d,0) + coalesce(paid_expenditure_w_expiry_amt_local_1d,0) + coalesce(free_expenditure_wo_expiry_amt_local_1d,0) + coalesce(free_expenditure_w_expiry_amt_local_1d,0) > 0 and grass_date >= date_sub(DATE('${grass_date}'),29) then grass_date else null end) as first_expenditure_date_30d
    ,min(case when coalesce(paid_expenditure_wo_expiry_amt_local_1d,0) + coalesce(paid_expenditure_w_expiry_amt_local_1d,0) + coalesce(free_expenditure_wo_expiry_amt_local_1d,0) + coalesce(free_expenditure_w_expiry_amt_local_1d,0) > 0 and grass_date < date_sub(DATE('${grass_date}'),29) then grass_date else null end) as first_expenditure_date_30_60d
from mp_paidads.dws_advertiser_deduction_1d__reg_s0_live
where grass_region = upper('${region}')
and grass_date <= DATE('${grass_date}')
and grass_date >= date_sub(DATE('${grass_date}'),59)
and tz_type = 'local'
group by 1 
;

create or replace temporary view platform_gmv as 
select 
    shop_id
    ,sum(gmv_usd_60d) as gmv_usd_60d
from mp_order.dws_item_gmv_nd__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
group by 1 
;

create or replace temporary view dim_advertiser as 
select 
    shop_id
from mp_user.dim_shop__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

create or replace temporary view metrics as 
select 
    a.shop_id as shop_id
    ,ads_first_revenue_date as first_expenditure_date
    ,coalesce(expenditure_amt_usd_30d,0.0) as expenditure_amt_usd_30d
    ,coalesce(expenditure_amt_usd_60d,0.0) as expenditure_amt_usd_60d
    ,case when first_expenditure_date_30_60d is null then 0 else coalesce(expenditure_amt_usd_30_60d,0.0) end as expenditure_amt_usd_30_60d
    ,datediff(DATE('${grass_date}'),first_expenditure_date_30d) + 1 as expenditure_day_cnt_30d
    ,datediff(date_sub(DATE('${grass_date}'),30),first_expenditure_date_30_60d) + 1 as expenditure_day_cnt_30_60d
    ,coalesce(expenditure_amt_usd_30d / (datediff(DATE('${grass_date}'),first_expenditure_date_30d) + 1),0.0) as ads_arpu_30d
    ,coalesce(expenditure_amt_usd_30_60d / (datediff(date_sub(DATE('${grass_date}'),30),first_expenditure_date_30_60d) + 1),0.0) as ads_arpu_30_60d
    ,coalesce(gmv_usd_60d,0.0) as gmv_usd_60d
    ,upper('${region}')
    ,DATE('${grass_date}')
from dim_advertiser a 
left join rev b 
on a.shop_id = b.shop_id
left join rev_nd c 
on a.shop_id = c.shop_id
left join arpu d 
on a.shop_id = d.shop_id
left join platform_gmv e
on a.shop_id = e.shop_id
;

create or replace temporary view tag as 
select 
    shop_id
    ,case when expenditure_amt_usd_60d = 0 and gmv_usd_60d = 0 then 'potential_seller_without_gmv'
        when expenditure_amt_usd_60d = 0 and gmv_usd_60d > 0 then 'potential_seller_with_gmv'
        when expenditure_amt_usd_30d = 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date >= date_sub(DATE('${grass_date}'),59) and first_expenditure_date <= date_sub(DATE('${grass_date}'),30) then 'short_term_churn_seller_new'
        when expenditure_amt_usd_30d = 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date < date_sub(DATE('${grass_date}'),59) then 'short_term_churn_seller_regular'
        when first_expenditure_date >= date_sub(DATE('${grass_date}'),29) then 'new_seller'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date >= date_sub(DATE('${grass_date}'),59) and first_expenditure_date <= date_sub(DATE('${grass_date}'),30)
             and (ads_arpu_30d - ads_arpu_30_60d) / ads_arpu_30_60d >= 0.3 then 'regular_seller_new_uplift'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date >= date_sub(DATE('${grass_date}'),59) and first_expenditure_date <= date_sub(DATE('${grass_date}'),30)
             and abs(ads_arpu_30d - ads_arpu_30_60d) / ads_arpu_30_60d < 0.3 then 'regular_seller_new_stable'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date >= date_sub(DATE('${grass_date}'),59) and first_expenditure_date <= date_sub(DATE('${grass_date}'),30)
             and (ads_arpu_30_60d - ads_arpu_30d ) / ads_arpu_30_60d >= 0.3 then 'regular_seller_new_pre_churn'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date < date_sub(DATE('${grass_date}'),59) 
             and (ads_arpu_30d - ads_arpu_30_60d) / ads_arpu_30_60d >= 0.5 then 'regular_seller_regular_uplift'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date < date_sub(DATE('${grass_date}'),59) 
             and abs(ads_arpu_30d - ads_arpu_30_60d) / ads_arpu_30_60d < 0.5 then 'regular_seller_regular_stable'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d > 0 and first_expenditure_date < date_sub(DATE('${grass_date}'),59) 
             and (ads_arpu_30_60d - ads_arpu_30d) / ads_arpu_30_60d >= 0.5 then 'regular_seller_regular_pre_churn'
        when expenditure_amt_usd_30d > 0 and expenditure_amt_usd_30_60d = 0 and first_expenditure_date < date_sub(DATE('${grass_date}'),59) then 'churn_recall_seller'
        end as advertiser_lifeycle_type_level3
    ,first_expenditure_date
    ,expenditure_amt_usd_30d
    ,expenditure_amt_usd_60d
    ,expenditure_amt_usd_30_60d
    ,ads_arpu_30d
    ,ads_arpu_30_60d
    ,gmv_usd_60d
from metrics
;

create or replace temporary view hit_budget_ratio as 
select 
    shop_id
    ,sum(campaign_cnt) as campaign_cnt
    ,sum(hit_campaign_cnt) as hit_campaign_cnt
    ,sum(hit_campaign_cnt) * 1.000 / sum(campaign_cnt) as shop_hit_budget_rate
    ,sum(valid_budget) as valid_budget_amt_usd_30d
from
(select
        grass_date
        ,grass_region
        ,shop_id
        ,count(distinct campaign_id) as campaign_cnt
        ,count(distinct case when campaign_valid_budget_usd > 0 and ads_expenditure_usd > campaign_valid_budget_usd * 0.97 then campaign_id
            else null end) as hit_campaign_cnt
        ,sum(case when pricing_type in (1,2,11,15,20) then campaign_valid_budget_usd else 0 end) as valid_budget
from mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live
where grass_region = upper('${region}')
and grass_date >= date_sub(DATE('${grass_date}'),29)
and grass_date <= DATE('${grass_date}')
and pricing_type not in (5)
group by 1,2,3
)
group by 1;

create or replace temporary view tier as 
select 
    shop_id
    ,seller_tier
from mp_paidads.dim_shop_info__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

create or replace temporary view regular_seller as 
select shop_id
from tag
where advertiser_lifeycle_type_level3 in ('regular_seller_new_uplift','regular_seller_new_stable','regular_seller_new_pre_churn','regular_seller_regular_uplift', 'regular_seller_regular_stable', 'regular_seller_regular_pre_churn')
group by 1
;

create or replace temporary view regular_seller_tag as 
select 
    shop_id 
    ,case when seller_tier in ('large_seller', 'medium_seller') and valid_budget_tier_30d > 0.5 and shop_hit_budget_rate >0.8 then 'regular_seller_p0'
        when seller_tier in ('large_seller', 'medium_seller') and valid_budget_tier_30d > 0.5 and shop_hit_budget_rate > 0.2 and shop_hit_budget_rate <=0.8 then 'regular_seller_p1'
        when seller_tier in ('large_seller', 'medium_seller') and valid_budget_tier_30d > 0.5 and shop_hit_budget_rate <= 0.2 then 'regular_seller_p2'
        when seller_tier in ('small_seller', 'micro_seller') and valid_budget_tier_30d > 0.5 then 'regular_seller_p3'
        when seller_tier in ('small_seller', 'micro_seller') and valid_budget_tier_30d <= 0.5 then 'regular_seller_p4' end as regular_seller_tag 
    ,shop_hit_budget_rate
    ,valid_budget_amt_usd_30d
    ,case when valid_budget_tier_30d <= 0.05 then 'p0'
        when valid_budget_tier_30d > 0.05 and valid_budget_tier_30d <= 0.1 then 'p5'
        when valid_budget_tier_30d > 0.1 and valid_budget_tier_30d <= 0.15 then 'p10'
        when valid_budget_tier_30d > 0.15 and valid_budget_tier_30d <= 0.2 then 'p15'
        when valid_budget_tier_30d > 0.2 and valid_budget_tier_30d <= 0.25 then 'p20'
        when valid_budget_tier_30d > 0.25 and valid_budget_tier_30d <= 0.3 then 'p25'
        when valid_budget_tier_30d > 0.3 and valid_budget_tier_30d <= 0.35 then 'p30'
        when valid_budget_tier_30d > 0.35 and valid_budget_tier_30d <= 0.4 then 'p35'
        when valid_budget_tier_30d > 0.4 and valid_budget_tier_30d <= 0.45 then 'p40'
        when valid_budget_tier_30d > 0.45 and valid_budget_tier_30d <= 0.5 then 'p45'
        when valid_budget_tier_30d > 0.5 and valid_budget_tier_30d <= 0.55 then 'p50'
        when valid_budget_tier_30d > 0.55 and valid_budget_tier_30d <= 0.6 then 'p55'
        when valid_budget_tier_30d > 0.6 and valid_budget_tier_30d <= 0.65 then 'p60'
        when valid_budget_tier_30d > 0.65 and valid_budget_tier_30d <= 0.7 then 'p65'
        when valid_budget_tier_30d > 0.7 and valid_budget_tier_30d <= 0.75 then 'p70'
        when valid_budget_tier_30d > 0.75 and valid_budget_tier_30d <= 0.8 then 'p75'
        when valid_budget_tier_30d > 0.8 and valid_budget_tier_30d <= 0.85 then 'p80'
        when valid_budget_tier_30d > 0.85 and valid_budget_tier_30d <= 0.9 then 'p85'
        when valid_budget_tier_30d > 0.9 and valid_budget_tier_30d <= 0.95 then 'p90'
        when valid_budget_tier_30d > 0.95 then 'p95' end as valid_budget_tier_30d
from
(select 
    a.shop_id as shop_id
    ,shop_hit_budget_rate
    ,valid_budget_amt_usd_30d
    ,PERCENT_RANK() over(order by coalesce(valid_budget_amt_usd_30d,0)) as valid_budget_tier_30d
    ,seller_tier
from regular_seller a 
left join hit_budget_ratio b 
on a.shop_id = b.shop_id 
left join tier c 
on a.shop_id = c.shop_id
)t
;

insert overwrite table ads_advertiser_new_old_tag_daily__reg_s0_live partition(tz_type='local', grass_region, grass_date)
select 
    a.shop_id
    ,case when advertiser_lifeycle_type_level3 in ('short_term_churn_seller_new', 'short_term_churn_seller_regular') then 'short_term_churn_seller'
        when advertiser_lifeycle_type_level3 in ('potential_seller_without_gmv', 'potential_seller_with_gmv') then 'potential_seller'
        when advertiser_lifeycle_type_level3 in ('regular_seller_new_uplift','regular_seller_new_stable','regular_seller_new_pre_churn','regular_seller_regular_uplift', 'regular_seller_regular_stable', 'regular_seller_regular_pre_churn') then 'regular_seller'
        else advertiser_lifeycle_type_level3 end as advertiser_lifeycle_type
    ,case when advertiser_lifeycle_type_level3 in ('regular_seller_new_uplift','regular_seller_new_stable','regular_seller_new_pre_churn') then 'regular_seller_new'
        when advertiser_lifeycle_type_level3 in ('regular_seller_regular_uplift', 'regular_seller_regular_stable', 'regular_seller_regular_pre_churn') then 'regular_seller_regular'
        else advertiser_lifeycle_type_level3 end as advertiser_lifeycle_type_level2
    ,advertiser_lifeycle_type_level3
    ,first_expenditure_date
    ,expenditure_amt_usd_30d
    ,expenditure_amt_usd_60d
    ,ads_arpu_30d
    ,ads_arpu_30_60d
    ,gmv_usd_60d
    ,regular_seller_tag
    ,shop_hit_budget_rate
    ,valid_budget_amt_usd_30d
    ,valid_budget_tier_30d
    ,upper('${region}')
    ,DATE('${grass_date}')
from tag a
left join regular_seller_tag b 
on a.shop_id = b.shop_id
;