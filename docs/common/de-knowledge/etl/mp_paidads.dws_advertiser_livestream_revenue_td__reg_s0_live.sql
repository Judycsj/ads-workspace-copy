-- task_code: data_paidadsmart.studio_6746556  asset_id: 6746556
create external table if not exists dws_advertiser_livestream_revenue_td__reg_s0_live 
(
    
    shop_id bigint comment 'shop_id'
    ,streamer_id bigint comment 'streamer_id'
    ,streamer_type int comment 'streamer_type'
    ,total_expenditure_amt_local_td double comment 'total_expenditure_amt_local_td'
    ,total_expenditure_amt_usd_td double comment 'total_expenditure_amt_usd_td'
    ,paid_expenditure_wo_expiry_amt_local_td double comment 'paid_expenditure_wo_expiry_amt_local_td'
    ,paid_expenditure_wo_expiry_amt_usd_td double comment 'paid_expenditure_wo_expiry_amt_usd_td'
    ,paid_expenditure_w_expiry_amt_local_td double comment 'paid_expenditure_w_expiry_amt_local_td'
    ,paid_expenditure_w_expiry_amt_usd_td double comment 'paid_expenditure_w_expiry_amt_usd_td'
    ,free_expenditure_wo_expiry_amt_local_td double comment 'free_expenditure_wo_expiry_amt_local_td'
    ,free_expenditure_wo_expiry_amt_usd_td double comment 'free_expenditure_wo_expiry_amt_usd_td'
    ,free_expenditure_w_expiry_amt_local_td double comment 'free_expenditure_w_expiry_amt_local_td'
    ,free_expenditure_w_expiry_amt_usd_td double comment 'free_expenditure_w_expiry_amt_usd_td'
    ,streamer_first_live_ads_date string
    ,streamer_last_live_ads_date string
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_advertiser_livestream_revenue_td'
;

create external table if not exists  dws_advertiser_livestream_revenue_td__${region}_s0_live
(
     shop_id bigint comment 'shop_id'
    ,streamer_id bigint comment 'streamer_id'
    ,streamer_type int comment 'streamer_type'
    ,total_expenditure_amt_local_td double comment 'total_expenditure_amt_local_td'
    ,total_expenditure_amt_usd_td double comment 'total_expenditure_amt_usd_td'
    ,paid_expenditure_wo_expiry_amt_local_td double comment 'paid_expenditure_wo_expiry_amt_local_td'
    ,paid_expenditure_wo_expiry_amt_usd_td double comment 'paid_expenditure_wo_expiry_amt_usd_td'
    ,paid_expenditure_w_expiry_amt_local_td double comment 'paid_expenditure_w_expiry_amt_local_td'
    ,paid_expenditure_w_expiry_amt_usd_td double comment 'paid_expenditure_w_expiry_amt_usd_td'
    ,free_expenditure_wo_expiry_amt_local_td double comment 'free_expenditure_wo_expiry_amt_local_td'
    ,free_expenditure_wo_expiry_amt_usd_td double comment 'free_expenditure_wo_expiry_amt_usd_td'
    ,free_expenditure_w_expiry_amt_local_td double comment 'free_expenditure_w_expiry_amt_local_td'
    ,free_expenditure_w_expiry_amt_usd_td double comment 'free_expenditure_w_expiry_amt_usd_td'
    ,streamer_first_live_ads_date string
    ,streamer_last_live_ads_date string
) 
partitioned by
(
    grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_advertiser_livestream_revenue_td/tz_type=local/grass_region=${upper_region}'
;


create or replace temporary view  base_data_local as
select 
    shop_id
        ,streamer_id 
        ,streamer_type
        ,total_expenditure_amt_local_1d
        ,total_expenditure_amt_usd_1d 
        ,paid_expenditure_wo_expiry_amt_local_1d 
        ,paid_expenditure_wo_expiry_amt_usd_1d 
        ,paid_expenditure_w_expiry_amt_local_1d 
        ,paid_expenditure_w_expiry_amt_usd_1d 
        ,free_expenditure_wo_expiry_amt_local_1d 
        ,free_expenditure_wo_expiry_amt_usd_1d 
        ,free_expenditure_w_expiry_amt_local_1d 
        ,free_expenditure_w_expiry_amt_usd_1d 
        ,'${grass_date}' as streamer_last_live_ads_date
from    mp_paidads.dws_advertiser_livestream_revenue_1d__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
  and   tz_type = 'local'
;

create or replace temporary view  revenue_td as
select  *
from    mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = date_sub(DATE('${grass_date}'),1)
  and   tz_type = 'local'
;

insert overwrite table dws_advertiser_livestream_revenue_td__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select  coalesce(a.shop_id,b.shop_id) as shop_id
        ,coalesce(a.streamer_id,b.streamer_id) as streamer_id 
        ,coalesce(a.streamer_type,b.streamer_type) as streamer_type 
        ,COALESCE(total_expenditure_amt_local_1d,0) + COALESCE(total_expenditure_amt_local_td,0) as total_expenditure_amt_local_td
        ,COALESCE(total_expenditure_amt_usd_1d,0) + COALESCE(total_expenditure_amt_usd_td,0) as total_expenditure_amt_usd_td 
        ,COALESCE(paid_expenditure_wo_expiry_amt_local_1d,0) + COALESCE(paid_expenditure_wo_expiry_amt_local_td,0) as paid_expenditure_wo_expiry_amt_local_td 
        ,COALESCE(paid_expenditure_wo_expiry_amt_usd_1d,0) + COALESCE(paid_expenditure_wo_expiry_amt_usd_td,0) as paid_expenditure_wo_expiry_amt_usd_td 
        ,COALESCE(paid_expenditure_w_expiry_amt_local_1d,0) + COALESCE(paid_expenditure_w_expiry_amt_local_td,0) as paid_expenditure_w_expiry_amt_local_td 
        ,COALESCE(paid_expenditure_w_expiry_amt_usd_1d,0) + COALESCE(paid_expenditure_w_expiry_amt_usd_td,0) as paid_expenditure_w_expiry_amt_usd_td 
        ,COALESCE(free_expenditure_wo_expiry_amt_local_1d,0) + COALESCE(free_expenditure_wo_expiry_amt_local_td,0) as free_expenditure_wo_expiry_amt_local_td 
        ,COALESCE(free_expenditure_wo_expiry_amt_usd_1d,0) + COALESCE(free_expenditure_wo_expiry_amt_usd_td,0) as free_expenditure_wo_expiry_amt_usd_td 
        ,COALESCE(free_expenditure_w_expiry_amt_local_1d,0) + COALESCE(free_expenditure_w_expiry_amt_local_td,0) as free_expenditure_w_expiry_amt_local_td 
        ,COALESCE(free_expenditure_w_expiry_amt_usd_1d,0) + COALESCE(free_expenditure_w_expiry_amt_usd_td,0) as free_expenditure_w_expiry_amt_usd_td 
        ,COALESCE(b.streamer_first_live_ads_date,'${grass_date}') as streamer_first_live_ads_date
        ,COALESCE(a.streamer_last_live_ads_date,b.streamer_last_live_ads_date) as streamer_last_live_ads_date
        ,upper('${region}') as grass_region
        ,DATE('${grass_date}') as grass_date
from    base_data_local a 
full join revenue_td b 
on a.shop_id = b.shop_id
;

alter table dws_advertiser_livestream_revenue_td__${region}_s0_live add if not exists partition(grass_date = "${grass_date}")
;