create external table if not exists dws_advertise_livestream_revenue_1d__reg_s0_live
(
    ads_id bigint comment 'ads_id'
    ,placement bigint comment 'placement'
    ,campaign_id bigint comment 'campaign_id'
    ,shop_id bigint comment 'shop_id'
    ,target_affiliate_id bigint
    ,item_id bigint comment 'item_id'
    ,entrance int comment 'entrance'
    ,sub_entrance int comment 'sub_entrance'
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
location '${HIVE_PATH}/dws_livestream_revenue_1d'
;

create external table if not exists  dws_advertise_livestream_revenue_1d__${region}_s0_live
(
     ads_id bigint comment 'ads_id'
    ,placement bigint comment 'placement'
    ,campaign_id bigint comment 'campaign_id'
    ,shop_id bigint comment 'shop_id'
    ,target_affiliate_id bigint
    ,item_id bigint comment 'item_id'
    ,entrance int comment 'entrance'
    ,sub_entrance int comment 'sub_entrance'
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
location '${HIVE_PATH}/dws_livestream_revenue_1d/tz_type=local/grass_region=${upper_region}'
;

insert overwrite table dws_advertise_livestream_revenue_1d__reg_s0_live partition (tz_type = 'regional', grass_region = '${upper_region}', grass_date='${grass_date}')
select /*+ MAPJOIN(exrate)*/ ads_id
    ,placement
    ,campaign_id
    ,shop_id
    ,target_affiliate_id
    ,item_id
    ,entrance
    ,sub_entrance
    ,pricing_type
    ,ads_expenditure as total_expenditure_amt_local_1d
    ,ads_expenditure_usd as total_expenditure_amt_usd_1d
    ,expense_paid_credit_without_expiry as paid_expenditure_wo_expiry_amt_local_1d
    ,(expense_paid_credit_without_expiry / exrate.exchange_rate) as paid_expenditure_wo_expiry_amt_usd_1d
    ,expense_paid_credit_with_expiry as paid_expenditure_w_expiry_amt_local_1d
    ,(expense_paid_credit_with_expiry / exrate.exchange_rate) as paid_expenditure_w_expiry_amt_usd_1d
    ,expense_free_credit_without_expiry as free_expenditure_wo_expiry_amt_local_1d
    ,(expense_free_credit_without_expiry / exrate.exchange_rate) as free_expenditure_wo_expiry_amt_usd_1d
    ,expense_free_credit_with_expiry as free_expenditure_w_expiry_amt_local_1d
    ,(expense_free_credit_with_expiry / exrate.exchange_rate) as free_expenditure_w_expiry_amt_usd_1d
    ,streamer_id
from (
    select ads_id
        ,placement
        ,campaign_id
        ,shop_id
        ,target_affiliate_id
        ,item_id
        ,entrance
        ,sub_entrance
        ,pricing_type
        ,sum(ads_expenditure) as ads_expenditure
        ,sum(ads_expenditure_usd) as ads_expenditure_usd
        ,sum(expense_paid_credit_without_expiry)*1.00000/100000  as expense_paid_credit_without_expiry
        ,sum(expense_paid_credit_with_expiry)*1.00000/100000  as expense_paid_credit_with_expiry
        ,sum(expense_free_credit_without_expiry)*1.00000/100000  as expense_free_credit_without_expiry
        ,sum(expense_free_credit_with_expiry)*1.00000/100000  as expense_free_credit_with_expiry
        ,streamer_id
        ,grass_region
    from mp_paidads.dwd_livestream_performance_di__reg_s0_live
    where grass_region = '${upper_region}' and ads_expenditure > 0
        and grass_date >= DATE_SUB(DATE('${grass_date}'), 1)
        and grass_date <= DATE('${grass_date}')
        AND event_timestamp >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
        AND event_timestamp < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
    group by ads_id,placement,shop_id,campaign_id,item_id ,entrance,pricing_type,target_affiliate_id,streamer_id,sub_entrance,grass_region
)a left outer join (
    select  grass_region,exchange_rate
    from mp_order.dim_exchange_rate__reg_s0_live
    where grass_region = '${upper_region}' and   grass_date = DATE('${grass_date}')
) exrate on a.grass_region = exrate.grass_region
;
