-- task_code: data_paidadsmart.studio_6745044  asset_id: 6745044
create external table if not exists dws_advertiser_livestream_revenue_1d__reg_s0_live 
(
    
    shop_id bigint comment 'shop_id'
    ,streamer_id bigint comment 'streamer_id'
    ,streamer_type int comment 'streamer_type'
    ,total_expenditure_amt_local_1d double comment 'total_expenditure_amt_local_1d'
    ,total_expenditure_amt_usd_1d double comment 'total_expenditure_amt_usd_1d'
    ,paid_expenditure_wo_expiry_amt_local_1d double comment 'paid_expenditure_wo_expiry_amt_local_1d'
    ,paid_expenditure_wo_expiry_amt_usd_1d double comment 'paid_expenditure_wo_expiry_amt_usd_1d'
    ,paid_expenditure_w_expiry_amt_local_1d double comment 'paid_expenditure_w_expiry_amt_local_1d'
    ,paid_expenditure_w_expiry_amt_usd_1d double comment 'paid_expenditure_w_expiry_amt_usd_1d'
    ,free_expenditure_wo_expiry_amt_local_1d double comment 'free_expenditure_wo_expiry_amt_local_1d'
    ,free_expenditure_wo_expiry_amt_usd_1d double comment 'free_expenditure_wo_expiry_amt_usd_1d'
    ,free_expenditure_w_expiry_amt_local_1d double comment 'free_expenditure_w_expiry_amt_local_1d'
    ,free_expenditure_w_expiry_amt_usd_1d double comment 'free_expenditure_w_expiry_amt_usd_1d'
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_advertiser_livestream_revenue_1d'
;

create external table if not exists  dws_advertiser_livestream_revenue_1d__${region}_s0_live
(
     shop_id bigint comment 'shop_id'
    ,streamer_id bigint comment 'streamer_id'
    ,streamer_type int comment 'streamer_type'
    ,total_expenditure_amt_local_1d double comment 'total_expenditure_amt_local_1d'
    ,total_expenditure_amt_usd_1d double comment 'total_expenditure_amt_usd_1d'
    ,paid_expenditure_wo_expiry_amt_local_1d double comment 'paid_expenditure_wo_expiry_amt_local_1d'
    ,paid_expenditure_wo_expiry_amt_usd_1d double comment 'paid_expenditure_wo_expiry_amt_usd_1d'
    ,paid_expenditure_w_expiry_amt_local_1d double comment 'paid_expenditure_w_expiry_amt_local_1d'
    ,paid_expenditure_w_expiry_amt_usd_1d double comment 'paid_expenditure_w_expiry_amt_usd_1d'
    ,free_expenditure_wo_expiry_amt_local_1d double comment 'free_expenditure_wo_expiry_amt_local_1d'
    ,free_expenditure_wo_expiry_amt_usd_1d double comment 'free_expenditure_wo_expiry_amt_usd_1d'
    ,free_expenditure_w_expiry_amt_local_1d double comment 'free_expenditure_w_expiry_amt_local_1d'
    ,free_expenditure_w_expiry_amt_usd_1d double comment 'free_expenditure_w_expiry_amt_usd_1d'
) 
partitioned by
(
    grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_advertiser_livestream_revenue_1d/tz_type=local/grass_region=${upper_region}'
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

cache table  base_data_local 
select 
    a.shop_id  as shop_id
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
from 
(select  shop_id 
        ,sum(total_expenditure_amt_local_1d) as total_expenditure_amt_local_1d
        ,sum(total_expenditure_amt_usd_1d)  as total_expenditure_amt_usd_1d
        ,sum(paid_expenditure_wo_expiry_amt_local_1d) as paid_expenditure_wo_expiry_amt_local_1d
        ,sum(paid_expenditure_wo_expiry_amt_usd_1d) as paid_expenditure_wo_expiry_amt_usd_1d
        ,sum(paid_expenditure_w_expiry_amt_local_1d) as paid_expenditure_w_expiry_amt_local_1d
        ,sum(paid_expenditure_w_expiry_amt_usd_1d) as paid_expenditure_w_expiry_amt_usd_1d
        ,sum(paid_expenditure_w_expiry_amt_usd_1d) as free_expenditure_wo_expiry_amt_local_1d
        ,sum(free_expenditure_wo_expiry_amt_usd_1d) as free_expenditure_wo_expiry_amt_usd_1d
        ,sum(free_expenditure_w_expiry_amt_local_1d) as free_expenditure_w_expiry_amt_local_1d
        ,sum(free_expenditure_w_expiry_amt_usd_1d) as free_expenditure_w_expiry_amt_usd_1d
from    mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
  and   tz_type = 'local'
  group by 1
)a 
left join dim_ls b 
on a.shop_id = b.shop_id
;



insert overwrite table dws_advertiser_livestream_revenue_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select  shop_id 
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
        ,upper('${region}') as grass_region
        ,DATE('${grass_date}') as grass_date
from    base_data_local
;

insert overwrite table dws_advertiser_livestream_revenue_1d__reg_s0_live partition (tz_type = 'regional', grass_region, grass_date)
select  shop_id 
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
        ,upper('${region}') as grass_region
        ,DATE('${grass_date}') as grass_date
from    base_data_local
;

alter table dws_advertiser_livestream_revenue_1d__${region}_s0_live add if not exists partition(grass_date = "${grass_date}")
;