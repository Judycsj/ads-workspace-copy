-- task_code: data_paidadsmart.studio_6790358  asset_id: 6790358
create external table if not exists dim_streamer_new_old_tag__reg_s0_live
(
     streamer_id bigint
     ,streamer_type int
     ,shop_id bigint
     ,shop_level1_global_be_category string
     ,shop_level2_global_be_category string
     ,today_new_advertiser_status int
     ,month_new_advertiser_status int 
     ,new_ls_streamer_status int
     ,advertiser_gmv_tier string 
     ,advertiser_ls_gmv_tier string
     ,advertiser_rev_tier string
     ,streamer_first_streaming_date string
     ,streamer_last_streaming_date string
     ,streamer_first_live_ads_date string
     ,streamer_last_live_ads_date string
     ,is_streaming_today tinyint
     ,is_rev_today tinyint
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dim_streamer_new_old_tag'
;

create or replace temporary view dim_streamer as 
select 
    streamer_id
    ,streamer_type
    ,streamer_shop_id as shop_id 
    ,streamer_first_streaming_date
    ,streamer_last_streaming_date
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
    ,case when date(streamer_last_streaming_date) = '${grass_date}' then 1 else 0 end is_streaming_today
    ,case when date(streamer_last_streaming_date) >= TRUNC('${grass_date}','MM') then 1 else 0 end is_streaming_this_month
from livestream.ls_mart_dim_streamer
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

create or replace temporary view streamer_per as 
select  
    a.shop_id as shop_id
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
from
(select 
    shop_id 
from mp_paidads.dws_advertiser_livestream_performance_1d__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
group by 1
) a 
left join 
(
select 
    shop_id
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category 
from mp_paidads.dim_advertiser__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
) b 
on a.shop_id = b.shop_id
;

create or replace temporary view ls_streamer as 
select 
    streamer_id
    ,streamer_type
    ,COALESCE(b.shop_id, a.shop_id) as shop_id
    ,streamer_first_streaming_date
    ,streamer_last_streaming_date
    ,COALESCE(b.shop_level1_global_be_category , a.shop_level1_global_be_category) as shop_level1_global_be_category
    ,COALESCE(b.shop_level2_global_be_category , a.shop_level2_global_be_category) as shop_level2_global_be_category
    ,is_streaming_today
    ,is_streaming_this_month
from dim_streamer a
full join streamer_per b 
on a.shop_id = b.shop_id
;

create or replace temporary view streaming_date_ytd as 
select 
    streamer_id
    ,case when streamer_last_streaming_date >= date_sub('${grass_date}',90) then 1 else 0 end as is_streaming_last_90d
from livestream.ls_mart_dim_streamer
where grass_region = upper('${region}')
and   grass_date = date_sub(DATE('${grass_date}'),1)
and tz_type = 'local'
;

create or replace temporary view revenue_td as 
select 
    shop_id
    ,total_expenditure_amt_usd_td as ads_revenue_td
    ,streamer_first_live_ads_date
    ,streamer_last_live_ads_date
    ,case when date(streamer_last_live_ads_date) = '${grass_date}' then 1 else 0 end is_rev_today
    ,case when date(streamer_last_live_ads_date) >= TRUNC('${grass_date}','MM') then 1 else 0 end as is_revenue_this_month
from mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

create or replace temporary view rev_date_ytd as 
select 
    shop_id
    ,case when streamer_last_live_ads_date >= date_sub('${grass_date}',365) then 1 else 0 end as is_revenue_last_365d
from mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = date_sub(DATE('${grass_date}'),1)
and tz_type = 'local'
;

create or replace temporary view rev_date_last_month as 
select 
    shop_id
    ,case when streamer_last_live_ads_date >= ADD_MONTHS(TRUNC('${grass_date}','MM'),-1) then 1 else 0 end as is_revenue_last_month
    ,case when streamer_last_live_ads_date >= ADD_MONTHS(TRUNC('${grass_date}','MM'),-12) then 1 else 0 end as is_revenue_last_12_month
from mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = date_sub(TRUNC(DATE('${grass_date}'),'MM'),1)
and tz_type = 'local'
;


create or replace temporary view rev_tier as 
select 
    shop_id
    ,case  when rev_percentile >= 0 and rev_percentile < 0.01 then '1% percentile'
                when rev_percentile >= 0.01 and rev_percentile < 0.1 then '10% percentile'
                when rev_percentile >= 0.1 and rev_percentile < 0.25 then '25% percentile'
                when rev_percentile >= 0.25 and rev_percentile < 0.5 then '50% percentile'
                when rev_percentile >= 0.5 and rev_percentile < 0.75 then '75% percentile'
                else 'Other'
          end as advertiser_rev_tier
from
(select
    shop_id
    ,PERCENT_RANK() over (partition by grass_region order by COALESCE(total_expenditure_amt_usd_1d,0) desc) as rev_percentile
from mp_paidads.dws_advertiser_livestream_revenue_1d__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
and total_expenditure_amt_usd_1d > 0
)a
;

create or replace temporary view gmv_tier as 
select 
    shop_id 
    ,case when gmv_usd_30d >= 25000 then 'large_seller'
    when gmv_usd_30d >= 10000 and gmv_usd_30d < 25000 then 'medium_seller'
    when gmv_usd_30d >= 5000 and gmv_usd_30d < 10000 then 'small_seller'
    else 'micro seller' end as advertiser_gmv_tier
from mp_order.dws_seller_gmv_nd__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

create or replace temporary view org_gmv_tier as 
select 
    streamer_id
    ,case  when gmv_percentile >= 0 and gmv_percentile < 0.01 then 'Top 1%'
                when gmv_percentile >= 0.01 and gmv_percentile < 0.05 then 'Top 5%'
                when gmv_percentile >= 0.05 and gmv_percentile < 0.1 then 'Top 10%'
                when gmv_percentile >= 0.1 and gmv_percentile < 0.2 then 'Top 20%'
                when gmv_percentile >= 0.2 and gmv_percentile < 0.3 then 'Top 30%'
                when gmv_percentile >= 0.3 and gmv_percentile < 0.4 then 'Top 40%'
                when gmv_percentile >= 0.4 and gmv_percentile < 0.5 then 'Top 50%'
            else 'Other'
          end as advertiser_ls_gmv_tier
from 
(select 
    streamer_id
    ,PERCENT_RANK() over (partition by grass_region order by COALESCE(gmv_rcmd_usd,0) desc) as gmv_percentile
    ,gmv_rcmd_usd
from 
    (
    select 
    streamer_id
    ,grass_region
    ,sum(gmv_rcmd_usd) as gmv_rcmd_usd
from mp_paidads.dws_streamer_livestream_org_performance_1d__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
and gmv_rcmd_usd > 0
group by 1,2
)t
)a
;

INSERT OVERWRITE TABLE dim_streamer_new_old_tag__reg_s0_live PARTITION (tz_type = 'local', grass_region, grass_date)
select 
    a.streamer_id as streamer_id
    ,streamer_type
    ,a.shop_id  as shop_id
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
    ,case when COALESCE(is_revenue_last_365d,0) = 1 then 0 
        when COALESCE(is_rev_today,0) = 1  and COALESCE(is_revenue_last_365d,0) = 0 then 1
        else 'Not Applicable Today' end as today_new_advertiser_status 
    ,case when COALESCE(is_revenue_last_month,0) = 1 and COALESCE(is_revenue_this_month,0) = 1 then 0 
        when COALESCE(is_revenue_last_12_month,0) = 1 and COALESCE(is_revenue_last_month,0) = 0 and COALESCE(is_revenue_this_month,0) = 1 then 1
        when COALESCE(is_revenue_last_12_month,0) = 0 and COALESCE(is_revenue_this_month,0) = 1 then 2 
        else 3 end as month_new_advertiser_status  
    ,case when COALESCE(is_streaming_today,0) = 1 and COALESCE(is_streaming_last_90d,0) = 0 then 0 
        when COALESCE(is_streaming_this_month,0) = 1 then 1
        else 2 end as new_ls_streamer_status 
    ,COALESCE(advertiser_gmv_tier,'micro seller')  as advertiser_gmv_tier
    ,COALESCE(advertiser_ls_gmv_tier,'Not Applicable Today') as advertiser_ls_gmv_tier
    ,COALESCE(advertiser_rev_tier,'Not Applicable Today') as advertiser_rev_tier
    ,streamer_first_streaming_date
    ,streamer_last_streaming_date
    ,streamer_first_live_ads_date
    ,streamer_last_live_ads_date
    ,COALESCE(is_streaming_today,0) as is_streaming_today
    ,COALESCE(is_rev_today,0) as is_rev_today
    ,upper('${region}')
    ,DATE('${grass_date}')
from ls_streamer a 
left join streaming_date_ytd b 
on a.streamer_id = b.streamer_id
left join revenue_td c 
on a.shop_id = c.shop_id
left join rev_date_ytd d 
on a.shop_id = d.shop_id
left join rev_date_last_month e 
on a.shop_id = e.shop_id
left join rev_tier f 
on a.shop_id = f.shop_id
left join gmv_tier g 
on a.shop_id = g.shop_id
left join org_gmv_tier h 
on a.streamer_id = h.streamer_id
;