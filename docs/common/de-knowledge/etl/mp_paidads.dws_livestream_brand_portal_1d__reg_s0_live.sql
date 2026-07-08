-- task_code: data_paidadsmart.studio_6639966  asset_id: 6639966
create external table if not exists dws_livestream_brand_portal_1d__reg_s0_live
(
    shop_id bigint
     ,campaign_id bigint
     ,campaign_type int
     ,views bigint
     ,orders bigint
     ,gross_sales double
     ,gross_sales_usd double
     ,ads_spend double
     ,ads_spend_usd double
     ,paid_order_cnt bigint
     ,paid_order_gmv double
     ,paid_order_gmv_usd double
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_livestream_brand_portal_1d'
;

create or replace temporary view dim_advertise as 
select 
    campaign_id
    ,shop_id
from mp_paidads.dim_advertise__reg_s0_live
where   grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and  placement = 3327
group by 1,2;


create or replace temporary view revenue as 
select 
    campaign_id
    ,pricing_type
    ,sum(total_expenditure_amt_local_1d) as ads_spend
    ,sum(total_expenditure_amt_usd_1d) as ads_spend_usd
from mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live
where   grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and tz_type = 'local'
group by 1,2;

INSERT OVERWRITE TABLE dws_livestream_brand_portal_1d__reg_s0_live PARTITION (tz_type = 'local', grass_region, grass_date)
select 
    shop_id
    ,a.campaign_id as campaign_id
    ,campaign_type
    ,views
    ,orders 
    ,gross_sales
    ,gross_sales_usd
    ,ads_spend
    ,ads_spend_usd
    ,paid_order_cnt
    ,paid_order_gmv
    ,paid_order_gmv_usd
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
from
(select 
    campaign_id
    ,pricing_type as campaign_type
    ,sum(view) as views
    ,sum(checkout) as orders 
    ,sum(broad_gmv) as gross_sales
    ,sum(broad_gmv_usd) as gross_sales_usd
    ,sum(paid_order) as paid_order_cnt
    ,sum(paid_order_gmv) as paid_order_gmv
    ,sum(paid_order_gmv_usd) as paid_order_gmv_usd
from mp_paidads.dwd_livestream_performance_di__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = date('${grass_date}')
    and tz_type = 'local'
group by 1,2
)a
left join dim_advertise b 
on a.campaign_id = b.campaign_id
left join revenue c 
on a.campaign_id = c.campaign_id
and a.campaign_type = c.pricing_type
;