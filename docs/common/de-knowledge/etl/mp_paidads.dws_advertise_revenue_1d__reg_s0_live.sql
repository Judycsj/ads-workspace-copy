-- task_code: data_paidadsmart.studio_6405922  asset_id: 6405922
create external table if not exists dws_advertise_revenue_1d__reg_s0_live 
(
    ads_id bigint comment 'ads_id'
    ,placement bigint comment 'placement' 
    ,campaign_id bigint comment 'campaign_id'
    ,shop_id bigint comment 'shop_id'
    ,item_id bigint comment 'item_id'
    ,entrance int comment 'entrance'
    ,pricing_type int comment 'pricing_type'
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
location '${path}'
;

create external table if not exists  dws_advertise_revenue_1d__${region}_s0_live
(
     ads_id bigint comment 'ads_id'
    ,placement bigint comment 'placement'
    ,campaign_id bigint comment 'campaign_id'
    ,shop_id bigint comment 'shop_id'
    ,item_id bigint comment 'item_id'
    ,entrance int comment 'entrance'
    ,pricing_type int comment 'pricing_type'
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
location '${path}/tz_type=local/grass_region=${upper_region}'
;

insert overwrite table dws_advertise_revenue_1d__reg_s0_live partition (tz_type = 'local', grass_region = '${upper_region}', grass_date = '${grass_date}')
select  /*+ MAPJOIN(exrate)*/ ads_id
        ,placement
        ,campaign_id
        ,shop_id
        ,item_id 
        ,entrance
        ,pricing_type
        ,expenditure_amt_local as total_expenditure_amt_local_1d
        ,expenditure_amt_local / exrate.exchange_rate as total_expenditure_amt_usd_1d
        ,paid_expenditure_wo_expiry_amt_local as paid_expenditure_wo_expiry_amt_local_1d
        ,(paid_expenditure_wo_expiry_amt_local / exrate.exchange_rate) as paid_expenditure_wo_expiry_amt_usd_1d
        ,paid_expenditure_w_expiry_amt_local as paid_expenditure_w_expiry_amt_local_1d
        ,(paid_expenditure_w_expiry_amt_local / exrate.exchange_rate) as paid_expenditure_w_expiry_amt_usd_1d
        ,free_expenditure_wo_expiry_amt_local as free_expenditure_wo_expiry_amt_local_1d
        ,(free_expenditure_wo_expiry_amt_local / exrate.exchange_rate) as free_expenditure_wo_expiry_amt_usd_1d
        ,free_expenditure_w_expiry_amt_local as free_expenditure_w_expiry_amt_local_1d
        ,(free_expenditure_w_expiry_amt_local / exrate.exchange_rate) as free_expenditure_w_expiry_amt_usd_1d
        ,sub_entrance
        ,traffic_source
from (
        select ads_id,placement,shop_id,campaign_id,item_id,entrance,pricing_type,sub_entrance,traffic_source,grass_region
            ,sum(expense_free_credit_with_expiry)/ 100000.0 as free_expenditure_w_expiry_amt_local
            ,sum(expense_free_credit_without_expiry)/ 100000.0 as free_expenditure_wo_expiry_amt_local
            ,sum(expense_paid_credit_with_expiry)/ 100000.0 as paid_expenditure_w_expiry_amt_local
            ,sum(expense_paid_credit_without_expiry)/ 100000.0 as paid_expenditure_wo_expiry_amt_local
            ,sum(expenditure_amt_local) as expenditure_amt_local
        from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where   grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and expenditure_amt_local>0
        group by ads_id,placement,shop_id,campaign_id,item_id,entrance,pricing_type,sub_entrance,traffic_source,grass_region
) a
left outer join (
    select  grass_region
            ,exchange_rate
    from    mp_order.dim_exchange_rate__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}')
) exrate
on  a.grass_region = exrate.grass_region
;

alter table dws_advertise_revenue_1d__${region}_s0_live add if not exists partition(grass_date = "${grass_date}")
;