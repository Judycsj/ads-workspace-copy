-- task_code: data_paidadsmart.studio_6492772  asset_id: 6492772
create external table if not exists dws_advertise_livestream_performance_1d__reg_s0_live
(
    ads_id bigint
     ,placement  int 
     ,shop_id bigint
     ,pricing_type int
     ,campaign_id bigint
     ,entrance int
     ,item_id bigint
     ,target_affiliate_id bigint
     ,impression_cnt bigint
     ,deduct_impression_cnt bigint
     ,non_fraud_impression_cnt bigint
     ,click_cnt bigint
     ,order_cnt bigint
     ,ads_items_sold_cnt bigint
     ,ads_gmv_amt double
     ,ads_gmv_amt_usd double
     ,broad_ads_gmv_amt double
     ,broad_ads_gmv_amt_usd double
     ,broad_order_cnt bigint
     ,paid_order_cnt bigint
     ,confirmed_order_cnt bigint
     ,checkout_cnt bigint
     ,add_to_cart_cnt bigint
     ,view_cnt bigint
     ,product_click_cnt bigint
     ,ads_expenditure double
     ,ads_expenditure_usd double
     ,paid_order_ytd_cnt bigint
     ,confirmed_order_ytd_cnt bigint
     ,broad_item_sold_cnt bigint
     ,sub_entrance bigint
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_livestream_performance_1d'
;

create external table if not exists dws_advertise_livestream_performance_1d__${region}_s0_live
(
    ads_id bigint
     ,placement  int 
     ,shop_id bigint
     ,pricing_type int
     ,campaign_id bigint
     ,entrance int
     ,item_id bigint
     ,target_affiliate_id bigint
     ,impression_cnt bigint
     ,deduct_impression_cnt bigint
     ,non_fraud_impression_cnt bigint
     ,click_cnt bigint
     ,order_cnt bigint
     ,ads_items_sold_cnt bigint
     ,ads_gmv_amt double
     ,ads_gmv_amt_usd double
     ,broad_ads_gmv_amt double
     ,broad_ads_gmv_amt_usd double
     ,broad_order_cnt bigint
     ,paid_order_cnt bigint
     ,confirmed_order_cnt bigint
     ,checkout_cnt bigint
     ,add_to_cart_cnt bigint
     ,view_cnt bigint
     ,product_click_cnt bigint
     ,ads_expenditure double
     ,ads_expenditure_usd double
     ,paid_order_ytd_cnt bigint
     ,confirmed_order_ytd_cnt bigint
     ,broad_item_sold_cnt bigint
     ,sub_entrance bigint
) 
partitioned by
(
    grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_livestream_performance_1d/tz_type=local/grass_region=ID'
;

create or replace temporary view ls_performance as 
select 
    ads_id
     ,placement
     ,shop_id
     ,pricing_type
     ,campaign_id
     ,entrance
     ,item_id
     ,sub_entrance
     ,streamer_id
     ,max(account_id) as account_id
     ,max(target_affiliate_id) as target_affiliate_id
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
     ,count(distinct case when view > 0 then concat(request_id, cast(ads_id as string)) else null end) as effective_view
     ,sum(view_duration) as view_duration
     ,sum(ads_expenditure) as ads_expenditure
     ,sum(ads_expenditure_usd) as ads_expenditure_usd
from mp_paidads.dwd_livestream_performance_di__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date >= DATE_SUB(DATE('${grass_date}'), 1)
    and  grass_date <= DATE('${grass_date}')
    AND   event_timestamp >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
    AND   event_timestamp < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
group by 1,2,3,4,5,6,7,8,9
;

create or replace temporary view ls_order_ytd as 
select 
    ads_id
     ,placement
     ,shop_id
     ,pricing_type
     ,campaign_id
     ,entrance
     ,sub_entrance
     ,streamer_id
     ,sum(paid_order) as paid_order_ytd_cnt
     ,sum(confirmed_order) as confirmed_order_ytd_cnt
from mp_paidads.dwd_livestream_performance_di__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date >= DATE_SUB(DATE('${grass_date}'), 2)
    and  grass_date <= DATE_SUB(DATE('${grass_date}'), 1)
    AND   event_timestamp >= to_unix_timestamp(DATE_SUB(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
    AND   event_timestamp < to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
    and  (paid_order > 0 or confirmed_order > 0)
group by 1,2,3,4,5,6,7,8
;


create or replace temporary view  dim_ls as
select 
    streamer_id
    ,streamer_shop_id as shop_id
    ,streamer_type
from livestream.ls_mart_dim_streamer
where grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
  and   tz_type = 'local'
group by 1,2,3
;

cache table output
SELECT
    a.ads_id as ads_id
     ,a.placement as placement 
     ,a.shop_id as shop_id
     ,a.pricing_type as pricing_type
     ,a.campaign_id as campaign_id
     ,a.entrance as entrance
     ,a.item_id as item_id
     ,a.target_affiliate_id as target_affiliate_id
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
     ,ads_expenditure
     ,ads_expenditure_usd
     ,paid_order_ytd_cnt
     ,confirmed_order_ytd_cnt
     ,broad_item_sold_cnt
     ,a.sub_entrance
     ,a.streamer_id
     ,streamer_type
     ,ads_expenditure_vat_local
     ,ads_expenditure_vat_usd
     ,effective_view
     ,account_id
     ,view_duration
     ,upper('${region}') as grass_region
     ,DATE('${grass_date}') AS grass_date
from ls_performance a 
left join ls_order_ytd b 
on a.ads_id = b.ads_id 
and a.placement = b.placement 
and a.shop_id = b.shop_id 
and a.pricing_type = b.pricing_type 
and a.campaign_id = b.campaign_id 
and a.entrance = b.entrance 
and a.streamer_id = b.streamer_id
and a.sub_entrance <=> b.sub_entrance
left join dim_ls d 
on a.streamer_id = d.streamer_id
;



INSERT OVERWRITE TABLE dws_advertise_livestream_performance_1d__reg_s0_live PARTITION (tz_type = 'regional', grass_region, grass_date)
select *
FROM output;

alter table dws_advertise_livestream_performance_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");