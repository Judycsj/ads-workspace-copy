-- task_code: data_paidadsmart.studio_6751557  asset_id: 6751557
create external table if not exists dws_ls_session_livestream_performance_1d__reg_s0_live
(
     ls_session_id bigint 
     ,streamer_id bigint 
     ,streamer_type int
     ,ads_id bigint
     ,shop_id bigint
     ,pricing_type int
     ,campaign_id bigint
     ,campaign_start_datetime string
     ,campaign_end_datetime string
     ,ls_session_start_datetime string 
     ,ls_session_end_datetime string 
     ,impression_cnt bigint
     ,deduct_impression_cnt bigint
     ,non_fraud_impression_cnt bigint
     ,click_cnt bigint
     ,order_cnt bigint
     ,ads_items_sold_cnt bigint
     ,ads_gmv_amt_local double
     ,ads_gmv_amt_usd double
     ,broad_ads_gmv_amt_local double
     ,broad_ads_gmv_amt_usd double
     ,broad_order_cnt bigint
     ,paid_order_cnt bigint
     ,confirmed_order_cnt bigint
     ,checkout_cnt bigint
     ,add_to_cart_cnt bigint
     ,view_cnt bigint
     ,product_click_cnt bigint
     ,ads_expenditure_local double
     ,ads_expenditure_usd double
     ,broad_item_sold_cnt bigint
     ,ads_expenditure_vat_local double
     ,ads_expenditure_vat_usd double
     ,effective_view_cnt bigint
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_ls_session_livestream_performance_1d'
;

create external table if not exists dws_ls_session_livestream_performance_1d__${region}_s0_live
(
    ls_session_id bigint 
     ,streamer_id bigint 
     ,streamer_type int
     ,ads_id bigint
     ,shop_id bigint
     ,pricing_type int
     ,campaign_id bigint
     ,campaign_start_datetime string
     ,campaign_end_datetime string
     ,ls_session_start_datetime string 
     ,ls_session_end_datetime string 
     ,impression_cnt bigint
     ,deduct_impression_cnt bigint
     ,non_fraud_impression_cnt bigint
     ,click_cnt bigint
     ,order_cnt bigint
     ,ads_items_sold_cnt bigint
     ,ads_gmv_amt_local double
     ,ads_gmv_amt_usd double
     ,broad_ads_gmv_amt_local double
     ,broad_ads_gmv_amt_usd double
     ,broad_order_cnt bigint
     ,paid_order_cnt bigint
     ,confirmed_order_cnt bigint
     ,checkout_cnt bigint
     ,add_to_cart_cnt bigint
     ,view_cnt bigint
     ,product_click_cnt bigint
     ,ads_expenditure_local double
     ,ads_expenditure_usd double
     ,broad_item_sold_cnt bigint
     ,ads_expenditure_vat_local double
     ,ads_expenditure_vat_usd double
     ,effective_view_cnt bigint
) 
partitioned by
(
    grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_ls_session_livestream_performance_1d/tz_type=local/grass_region=ID'
;

create or replace temporary view ls_performance as 
select 
    ls_session_id  
     ,streamer_id  
     ,streamer_type 
     ,ads_id 
     ,shop_id 
     ,pricing_type 
     ,campaign_id 
     ,campaign_start_datetime 
     ,campaign_end_datetime 
     ,ls_session_start_datetime  
     ,ls_session_end_datetime  
     ,sum(impression) as impression_cnt
     ,sum(deduct_impression) as deduct_impression_cnt
     ,sum(non_fraud_impression) as non_fraud_impression_cnt
     ,sum(raw_click) as click_cnt
     ,sum(order) as order_cnt
     ,sum(item_sold_cnt) as ads_items_sold_cnt
     ,sum(order_gmv) as ads_gmv_amt
     ,sum(order_gmv_usd) as ads_gmv_amt_usd
     ,sum(broad_gmv) as broad_ads_gmv_amt
     ,sum(broad_gmv_usd) as broad_ads_gmv_amt_usd
     ,sum(broad_order) as broad_order_cnt
     ,sum(paid_order) as paid_order_cnt
     ,sum(confirmed_order) as confirmed_order_cnt
     ,sum(checkout) as checkout_cnt
     ,sum(add_to_cart) as add_to_cart_cnt
     ,sum(view) as view_cnt
     ,sum(product_click) as product_click_cnt
     ,sum(broad_item_sold_cnt) as broad_item_sold_cnt
     ,sum(ads_expenditure_vat) as ads_expenditure_vat_local
     ,sum(ads_expenditure_usd_vat) as ads_expenditure_vat_usd
     ,count(distinct case when view > 0 then concat(request_id, cast(ads_id as string)) else null end) as effective_view_cnt
from mp_paidads.dwd_livestream_performance_di__reg_s0_live
where grass_region = upper('${region}')
          and   grass_date = date('${grass_date}')
group by 1,2,3,4,5,6,7,8,9,10,11
;

create or replace temporary view ls_rev as
select 
    ls_session_id
     ,ads_id
     ,pricing_type
     ,campaign_id
     ,total_expenditure_amt_local_1d as ads_expenditure
     ,total_expenditure_amt_usd_1d as ads_expenditure_usd
from mp_paidads.dws_ls_session_livestream_revenue_1d__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = date('${grass_date}')
    and tz_type = 'local'
;


cache table output
SELECT
    a.ls_session_id  
     ,streamer_id  
     ,streamer_type 
     ,a.ads_id 
     ,a.shop_id 
     ,a.pricing_type 
     ,a.campaign_id 
     ,campaign_start_datetime 
     ,campaign_end_datetime 
     ,ls_session_start_datetime  
     ,ls_session_end_datetime  
     ,impression_cnt
     ,deduct_impression_cnt
     ,non_fraud_impression_cnt
     ,click_cnt
     ,order_cnt
     ,ads_items_sold_cnt
     ,ads_gmv_amt
     ,ads_gmv_amt_usd
     ,broad_ads_gmv_amt
     ,broad_ads_gmv_amt_usd
     ,broad_order_cnt
     ,paid_order_cnt
     ,confirmed_order_cnt
     ,checkout_cnt
     ,add_to_cart_cnt
     ,view_cnt
     ,product_click_cnt
     ,c.ads_expenditure
     ,c.ads_expenditure_usd
     ,broad_item_sold_cnt
     ,ads_expenditure_vat_local
     ,ads_expenditure_vat_usd
     ,effective_view_cnt
     ,upper('${region}') as grass_region
     ,DATE('${grass_date}') AS grass_date
from ls_performance a 
left join ls_rev c 
on a.ads_id = c.ads_id 
and a.pricing_type = c.pricing_type 
and a.campaign_id = c.campaign_id 
and a.ls_session_id = c.ls_session_id  
;


INSERT OVERWRITE TABLE dws_ls_session_livestream_performance_1d__reg_s0_live PARTITION (tz_type = 'local', grass_region, grass_date)
select *
FROM output;

alter table dws_ls_session_livestream_performance_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");