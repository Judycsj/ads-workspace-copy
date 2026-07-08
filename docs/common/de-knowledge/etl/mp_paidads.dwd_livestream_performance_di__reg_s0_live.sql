-- task_code: data_paidadsmart.studio_5440705  asset_id: 5440705
set time zone 'Asia/Jakarta';
add jar hdfs://R2/projects/data_paidadsmart/hdfs/udf/paidads-data-warehouse-udf-1.0.63.jar;
CREATE OR REPLACE TEMPORARY FUNCTION bid_info_decode_fuc as  'com.shopee.deepdata.warehouse.hive.udf.BiddingInfoDecodeUDF';

CREATE EXTERNAL TABLE IF NOT EXISTS dwd_livestream_performance_di__reg_s0_live(
    ads_id bigint
    ,item_id bigint
    ,shop_id bigint
    ,user_id bigint
    ,campaign_id bigint
    ,account_id bigint
    ,ls_session_id bigint
    ,streamer_id bigint
    ,entrance int
    ,placement int
    ,event_timestamp bigint
    ,location int
    ,location_in_ads int
    ,slot_id bigint
    ,impression bigint
    ,non_fraud_impression bigint
    ,deduct_impression bigint
    ,click bigint
    ,raw_click bigint
    ,order bigint
    ,checkout bigint
    ,view bigint
    ,add_to_cart bigint
    ,broad_order bigint
    ,paid_order bigint
    ,confirmed_order bigint
    ,cpm bigint
    ,expense_by_cpm bigint
    ,order_gmv double
    ,order_gmv_usd double
    ,item_sold_cnt bigint
    ,broad_gmv double
    ,broad_gmv_usd double
    ,broad_item_sold_cnt bigint
    ,ads_expenditure double
    ,ads_expenditure_usd double
    ,view_duration bigint
    ,ls_session_start_timestamp bigint
    ,ls_session_start_datetime string
    ,ls_session_end_timestamp bigint
    ,ls_session_end_datetime string
    ,ls_session_duration bigint
    ,product_click bigint
    ,campaign_start_datetime string
    ,campaign_end_datetime string
    ,ads_create_timestamp bigint
    ,ads_create_datetime string
    ,source string 
    ,content_mix_frame_tab_name int 
)partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dwd_livestream_performance_di/'
;

CREATE EXTERNAL TABLE IF NOT EXISTS dwd_livestream_performance_di__id_s0_live(
    `ads_id` bigint,
  `item_id` bigint,
  `shop_id` bigint,
  `user_id` bigint,
  `campaign_id` bigint,
  `account_id` bigint,
  `ls_session_id` bigint,
  `streamer_id` bigint,
  `entrance` int,
  `placement` int,
  `event_timestamp` bigint,
  `location` int,
  `location_in_ads` int,
  `slot_id` bigint,
  `impression` bigint,
  `non_fraud_impression` bigint,
  `deduct_impression` bigint,
  `click` bigint,
  `raw_click` bigint,
  `order` bigint,
  `checkout` bigint,
  `view` bigint,
  `add_to_cart` bigint,
  `broad_order` bigint,
  `paid_order` bigint,
  `confirmed_order` bigint,
  `cpm` bigint,
  `expense_by_cpm` bigint,
  `order_gmv` double,
  `order_gmv_usd` double,
  `item_sold_cnt` bigint,
  `broad_gmv` double,
  `broad_gmv_usd` double,
  `broad_item_sold_cnt` bigint,
  `ads_expenditure` double,
  `ads_expenditure_usd` double,
  `view_duration` bigint,
  `ls_session_start_timestamp` bigint,
  `ls_session_start_datetime` string,
  `ls_session_end_timestamp` bigint,
  `ls_session_end_datetime` string,
  `ls_session_duration` bigint,
  `product_click` bigint,
  `campaign_start_datetime` string,
  `campaign_end_datetime` string,
  `ads_create_timestamp` bigint,
  `ads_create_datetime` string,
  `ads_expenditure_vat` double,
  `ads_expenditure_usd_vat` double,
  `target_type` string,
  `page_section` string,
  `page_type` string,
  `origin_item_id` bigint,
  `target_affiliate_id` bigint,
  `sub_entrance` bigint,
  `agent_gmv` double,
  `agent_gmv_usd` double,
  `agent_order` bigint,
  `agent_item_sold_cnt` bigint,
  `agent_checkout` bigint,
  `daily_order` bigint,
  `daily_item_sold_cnt` bigint,
  `daily_gmv_amt_local` double,
  `daily_gmv_amt_usd` double,
  `click_timestamp` bigint,
  `click_datetime` string,
  `event_datetime` string,
  `paid_timestamp` bigint,
  `paid_datetime` string,
  `confirmed_timestamp` bigint,
  `confirmed_datetime` string,
  `platform` string,
  `streamer_type` int
  ,source string 
  ,content_mix_frame_tab_name int 
)partitioned by
(
     grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dwd_livestream_performance_di/tz_type=local/grass_region=ID'
;

create or replace temporary view livestream_report_ng as 
select  *
from    mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live
where   grass_region = upper('${region}')
      and   grass_date >= DATE('${grass_date}')
      and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
      and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
      and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
      and   deduct_impression is null
;

create or replace temporary view translog as
select * , FROM_JSON( get_json_object(decoded_extinfo, '$.paidFreeExpirySummary.entries'), 'array<
                  struct<
                      type:BIGINT,
                      amount:string,
                      effective_type:int
                  >
              >') as entrys
from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
and tz_type='local'
and operation = 11 
and cast(get_json_object(decoded_extinfo, '$.pricingType') as int) in (9,10,14,19,22)
;

create or replace temporary view cpm_deduction as 
select 
    ads_id, timestamp,shop_id,account_id,grass_region,deduct_unique_id,placement, -- translog_db
    campaign_id,bid_type,entry_point,pricing_type, -- translog_db extinfo 

    page_type,page_section,platform, -- translog_event 

    --cpm_detial
    cpm_detail.user_id as user_id,
    cpm_detail.target_type as target_type,
    imp_cost_detail.adjusted_cost as cost,
    imp_cost_detail.credit_cost as credit_cost,
    imp_cost_detail.balance_cost as balance_cost,
    cpm_detail.vv_id as vv_id,
    cpm_detail.source as source,
    cpm_detail.content_mix_frame_tab_name as content_mix_frame_tab_name,
    coalesce(cpm_detail.entrance,entrance) as entrance,
    coalesce(cpm_detail.ls_session_id, ls_session_id) as ls_session_id,
     
    get_json_object(cpm_detail.live_json_data, '$.request_id') as request_id,
    
    get_json_object(cpm_detail.live_json_data, '$.ab_sign') as signature,

    round(entry_1  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_paid_credit_without_expiry,
    round(entry_2  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_paid_credit_with_expiry,
    round(entry_3  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_free_credit_without_expiry,
    round(entry_4  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_free_credit_with_expiry,

    --fixed
    deduct_impression
    ,case when target_affiliate_id = 0 then account_id else target_affiliate_id end as target_affiliate_id
    ,traffic_source
    ,cast(get_json_object(cpm_detail.live_json_data, '$.recall_source') as int) as recall_source
    ,cast(get_json_object(cpm_detail.live_json_data, '$.target_cir') as double) as target_cir
    ,click_event_id
from
(
    select 
    --from translog_db
    adsid as ads_id, 

    translog_db.timestamp as timestamp,
    shopid as shop_id, 
    translog_db.account_id as account_id,
    translog_db.placement as placement,
    translog_db.grass_region as grass_region,
    translog_db.deduct_unique_id as deduct_unique_id,
    translog_db.dai_after_balance-translog_db.dai_before_balance as total_cost,


    --from translog_db extinfo
    cast(get_json_object(translog_db.decoded_extinfo, '$.campaignid') as bigint) as campaign_id,
    cast(get_json_object(translog_db.decoded_extinfo, '$.lsSessionId') as bigint) as ls_session_id,
    get_json_object(translog_db.decoded_extinfo, '$.bidType') as bid_type,
    get_json_object(translog_db.decoded_extinfo, '$.requestId') as request_id,
    get_json_object(translog_db.decoded_extinfo, '$.entryPoint') as entry_point,
    cast(get_json_object(translog_db.decoded_extinfo, '$.entrance') as bigint) as entrance,
    cast(get_json_object(translog_db.decoded_extinfo, '$.pricingType') as int) as pricing_type,
    get_json_object(translog_db.decoded_extinfo, '$.adsCredits') as ads_credits,
    cast(get_json_object(translog_db.decoded_extinfo, '$.targetAffiliateUserId') as bigint) as target_affiliate_id,
    aggregate(filter(entrys, x-> x.type = 1),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_1,
    aggregate(filter(entrys, x-> x.type = 2),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_2,
    aggregate(filter(entrys, x-> x.type = 3),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_3,
    aggregate(filter(entrys, x-> x.type = 4),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_4 ,

    --from translog_event
    page_type,
    page_section,
    platform,
    imp_cost_details, 
    root_ads_data_str,
    search_scenario,
    search_entrance,
    search_mid,
    cpm_event_details_str,
    traffic_source,
    click_event_id,

    --fixed
    1 as deduct_impression

    from translog as translog_db
    left join 
    (
      select distinct translog.deduct_unique_id as deduct_unique_id,translog.adsid as ads_id
        ,page_type,page_section,platform,imp_cost_details, root_ads_data_str,search_scenario
        ,search_entrance,search_mid,cpm_event_details_str,traffic_source,click_event_id
      from mp_paidads.ods_log_translog_event_hi__reg_s0_live
      where grass_date >= DATE('${grass_date}') and grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
        and   DATE(from_unixtime(translog.timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
        and   DATE(from_unixtime(translog.timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
        and grass_region = upper('${region}') and translog.operation = 11 -- and translog.pricing_type in (9,10,14,19,22)
    ) as translog_event
    on translog_db.deduct_unique_id = translog_event.deduct_unique_id and translog_db.adsid = translog_event.ads_id
) lateral view POSEXPLODE(FROM_JSON(cpm_event_details_str, 'array<
                  struct<
                      user_id:BIGINT,
                      event_ts:BIGINT,
                      uniq_id:BIGINT,
                      cpm:BIGINT,
                      live_json_data:string,
                      rn_ver:string,
                      event_id:string,
                      target_type:string,
                      shop_json_data:string,
                      vv_id:string,
                      video_json_data:string,
                      source:string,
                      ls_session_id:bigint,
                      content_mix_frame_tab_name:int,
                      entrance:int
                  >
              >')) cpm_details pos1,  cpm_detail
  lateral view POSEXPLODE(imp_cost_details) imp_cost_details pos2,  imp_cost_detail
where pos1=pos2
;

-- fix translog_event cpm records loss issue
-- use translog_db to extract revenue and dimensions
create or replace temporary view cpm_deduction_issue_fix as 
select 
    adsid as ads_id, 

    timestamp,
    shopid as shop_id, 
    account_id,
    placement,
    translog_db.grass_region as grass_region,
    translog_db.deduct_unique_id as deduct_unique_id,
    case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end as cost,

    cast(get_json_object(decoded_extinfo, '$.campaignid') as bigint) as campaign_id,
    cast(get_json_object(decoded_extinfo, '$.lsSessionId') as bigint) as ls_session_id,
    get_json_object(decoded_extinfo, '$.bidType') as bid_type,
    get_json_object(decoded_extinfo, '$.requestId') as request_id,
    get_json_object(decoded_extinfo, '$.entryPoint') as entry_point,
    cast(get_json_object(decoded_extinfo, '$.entrance') as bigint) as entrance,
    cast(get_json_object(decoded_extinfo, '$.pricingType') as int) as pricing_type,
    
    round(entry_1  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_paid_credit_without_expiry,
    round(entry_2  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_paid_credit_with_expiry,
    round(entry_3  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_free_credit_without_expiry,
    round(entry_4  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_free_credit_with_expiry,

    --fixed
    case when(translog_event.cost is null) then cast(get_json_object(decoded_extinfo, '$.batchCnt') as bigint) 
      else cast(get_json_object(decoded_extinfo, '$.batchCnt') as bigint) - cnt end as deduct_impression
    
    ,case when target_affiliate_id = 0 then account_id else target_affiliate_id end as target_affiliate_id
    ,traffic_source
from (
      select *, 
        dai_after_balance-dai_before_balance as cost, 
        cast(get_json_object(decoded_extinfo, '$.targetAffiliateUserId') as bigint) as target_affiliate_id,
        cast(get_json_object(decoded_extinfo, '$.trafficSource') as bigint) as traffic_source,
        aggregate(filter(entrys, x-> x.type = 1),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_1,
        aggregate(filter(entrys, x-> x.type = 2),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_2,
        aggregate(filter(entrys, x-> x.type = 3),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_3,
        aggregate(filter(entrys, x-> x.type = 4),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_4
      from  translog
    ) as translog_db
    left join 
    (
      select deduct_unique_id,ads_id, sum(cost) as cost, count(*) as cnt
      from cpm_deduction
      group by deduct_unique_id,ads_id
    ) translog_event
on translog_db.deduct_unique_id = translog_event.deduct_unique_id and translog_db.adsid = translog_event.ads_id
where (translog_db.cost != translog_event.cost or translog_event.cost is null)
;

create or replace temporary view live_report_ng_all as 
select  ads_id
        ,broad_gmv 
        ,broad_item_count 
        ,broad_order 
        ,broad_shop_item_click 
        ,broad_shop_item_imp 
        ,campaign_id
        ,click
        ,click_timestamp
        ,cost / 100000.0 as cost
        ,daily_order 
        ,daily_gmv
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,impression
        ,item_id
        ,location_in_ads
        ,order 
        ,checkout 
        ,order_amount 
        ,order_gmv 
        ,order_id
        ,placement
        ,raw_click 
        ,user_id
        ,request_id
        ,shop_id
        ,shop_item_click 
        ,shop_item_impression 
        ,timestamp as event_timestamp
        ,confirmed_order 
        ,paid_order 
        ,paid_timestamp
        ,confirmed_timestamp
        ,entrance
        ,pricing_type
        ,add_to_cart 
        ,location
        ,platform
        ,raw_click 
        ,sub_entrance
        ,account_id
        ,ls_session_id
        ,view
        ,view_duration
        ,product_click
        ,deduct_impression
        ,non_fraud_impression
        ,cpm 
        ,cost_by_cpm 
        ,origin_ids.item_id as origin_item_id
        ,daily_order_amount
        ,slot_id
        ,page_type
        ,page_section
        ,target_type
        ,model_id
        ,affiliate_id as target_affiliate_id
        ,agent_order_gmv 
        ,agent_order
        ,agent_order_amount 
        ,agent_checkout
        ,traffic_source
        ,recall_source
        ,target_cir
        ,click_event_id
        ,source 
        ,content_mix_frame_tab_name
        ,imp_attr_order
        ,imp_attr_order_amount
        ,imp_attr_order_gmv / 100000.0 as imp_attr_order_gmv
        ,imp_attr_agent_order
        ,imp_attr_agent_order_amount
        ,imp_attr_agent_order_gmv / 100000.0 as imp_attr_agent_order_gmv
        ,shop_exp_tag
        ,paid_order_amount
        ,paid_order_gmv / 100000.0 as paid_order_gmv
        ,paid_checkout as paid_checkout_cnt
        ,imp_attr_paid_order as imp_attr_paid_order_cnt
        ,imp_attr_paid_order_amount
        ,case when cod = true then 1 else 0 end as is_cod
        ,bid_info_decode_fuc(bid_rerank_trace) as bid_rerank_trace
        ,grass_region
from    livestream_report_ng

union all 

--cpm deduction
select  ads_id
        ,null as broad_gmv 
        ,null as broad_item_count 
        ,null as broad_order 
        ,null as broad_shop_item_click 
        ,null as broad_shop_item_imp 
        ,campaign_id
        ,null as click
        ,null as click_timestamp
        ,cost / 100000.0 as cost
        ,null as daily_order 
        ,null as daily_gmv
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,null as impression
        ,null as item_id
        ,null as location_in_ads
        ,null as order 
        ,null as checkout 
        ,null as order_amount 
        ,null as order_gmv 
        ,null as order_id
        ,placement
        ,null as raw_click 
        ,user_id
        ,request_id
        ,shop_id
        ,null as shop_item_click 
        ,null as shop_item_impression 
        ,timestamp as event_timestamp
        ,null as confirmed_order 
        ,null as paid_order 
        ,null as paid_timestamp
        ,null as confirmed_timestamp
        ,entrance as entrance
        ,pricing_type
        ,null as add_to_cart
        ,null as location
        ,platform
        ,null as raw_click
        ,null as sub_entrance
        ,account_id
        ,ls_session_id
        ,null as view
        ,null as view_duration
        ,null as product_click
        ,deduct_impression
        ,null as non_fraud_impression
        ,null as cpm 
        ,null as cost_by_cpm
        ,null as origin_item_id
        ,null as daily_order_amount
        ,null as slot_id
        ,page_type
        ,page_section
        ,target_type
        ,null as model_id
        ,target_affiliate_id
        ,null as agent_order_gmv 
        ,null as agent_order
        ,null as agent_order_amount 
        ,null as agent_checkout
        ,traffic_source
        ,recall_source
        ,target_cir
        ,click_event_id
        ,source 
        ,content_mix_frame_tab_name
        ,null as imp_attr_order
        ,null as imp_attr_order_amount
        ,null as imp_attr_order_gmv
        ,null as imp_attr_agent_order
        ,null as imp_attr_agent_order_amount
        ,null as imp_attr_agent_order_gmv
        ,null as shop_exp_tag
        ,null as paid_order_amount
        ,null as paid_order_gmv
        ,null as paid_checkout_cnt
        ,null as imp_attr_paid_order_cnt
        ,null as imp_attr_paid_order_amount
        ,null as is_cod
        ,null as bid_rerank_trace
        ,grass_region
from    cpm_deduction

union all 

--cpm deduction issue fix
select  ads_id
        ,null as broad_gmv 
        ,null as broad_item_count 
        ,null as broad_order 
        ,null as broad_shop_item_click 
        ,null as broad_shop_item_imp 
        ,campaign_id
        ,null as click
        ,null as click_timestamp
        ,cost / 100000.0 as cost
        ,null as daily_order 
        ,null as daily_gmv
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,null as impression
        ,null as item_id
        ,null as location_in_ads
        ,null as order 
        ,null as checkout 
        ,null as order_amount 
        ,null as order_gmv 
        ,null as order_id
        ,placement
        ,null as raw_click 
        ,null as user_id
        ,request_id
        ,shop_id
        ,null as shop_item_click 
        ,null as shop_item_impression 
        ,timestamp as event_timestamp
        ,null as confirmed_order 
        ,null as paid_order 
        ,null as paid_timestamp
        ,null as confirmed_timestamp
        ,entrance as entrance
        ,pricing_type
        ,null as add_to_cart
        ,null as location
        ,null as platform
        ,null as raw_click
        ,null as sub_entrance
        ,account_id
        ,ls_session_id
        ,null as view
        ,null as view_duration
        ,null as product_click
        ,deduct_impression
        ,null as non_fraud_impression
        ,null as cpm 
        ,null as cost_by_cpm
        ,null as origin_item_id
        ,null as daily_order_amount
        ,null as slot_id
        ,null as page_type
        ,null as page_section
        ,null as target_type
        ,null as model_id
        ,target_affiliate_id
        ,null as agent_order_gmv 
        ,null as agent_order
        ,null as agent_order_amount 
        ,null as agent_checkout
        ,traffic_source
        ,null as recall_source
        ,null as target_cir
        ,null as click_event_id
        ,null as source 
        ,null as content_mix_frame_tab_name
        ,null as imp_attr_order
        ,null as imp_attr_order_amount
        ,null as imp_attr_order_gmv
        ,null as imp_attr_agent_order
        ,null as imp_attr_agent_order_amount
        ,null as imp_attr_agent_order_gmv
        ,null as shop_exp_tag
        ,null as paid_order_amount
        ,null as paid_order_gmv
        ,null as paid_checkout_cnt
        ,null as imp_attr_paid_order_cnt
        ,null as imp_attr_paid_order_amount
        ,null as is_cod
        ,null as bid_rerank_trace
        ,grass_region
from    cpm_deduction_issue_fix
;



create or replace temporary view dim_advertise as 
select 
    ads_id
    ,campaign_id
    ,shop_id
    ,ads_create_timestamp
    ,ads_create_datetime
    ,campaign_start_datetime
    ,campaign_end_datetime
from mp_paidads.dim_advertise__reg_s0_live
where   grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}')
and pricing_type in (9,10,14,19,22)
group by 1,2,3,4,5,6,7;


create or replace temporary view ls_dim as 
select 
    ls_session_id
    ,streamer_id
    ,streamer_type
    ,ls_session_duration
    ,start_timestamp as ls_session_start_timestamp
    ,start_time as ls_session_start_time
    ,end_timestamp as ls_session_end_timestamp
    ,end_time as ls_session_end_time
    ,streamer_shop_id
from livestream.ls_mart_dim_ls_session
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}');


create or replace temporary view dim_exchange as 
select 
    grass_region
    ,exchange_rate
from mp_order.dim_exchange_rate__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${grass_date}');


create or replace temporary view dim_shop as
select
    shop_id
    ,is_cb_shop
    ,is_official_shop
    ,is_managed_shop
from mp_user.dim_shop__reg_s0_live
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
;

create or replace temporary view tax as
select 
    grass_region
    ,max(case when metric_type = 'cb_paid_ads_revenue' then vat_rate else 0.0 end) as cb_tax
    ,max(case when metric_type = 'local_paid_ads_revenue' then vat_rate else 0.0 end) as local_tax
from regbida_keyreports.dim_vat_rate 
where grass_region = upper('${region}')
and grass_date in (select max(grass_date) as grass_date from regbida_keyreports.dim_vat_rate where grass_region = upper('${region}'))
and metric_type in ('cb_paid_ads_revenue', 'local_paid_ads_revenue') 
group by 1;


create or replace temporary view base as
select 
    a.ads_id as ads_id
    ,item_id
    ,coalesce(b.shop_id,a.shop_id) as shop_id
    ,user_id
    ,coalesce(a.campaign_id,b.campaign_id) as campaign_id
    ,account_id
    ,a.ls_session_id as ls_session_id
    ,streamer_id
    ,entrance
    ,a.placement as placement
    ,event_timestamp
    ,location
    ,cast(location_in_ads as int) as location_in_ads
    ,slot_id
    ,impression
    ,non_fraud_impression
    ,deduct_impression
    ,click
    ,raw_click
    ,order
    ,checkout
    ,view
    ,add_to_cart
    ,broad_order
    ,paid_order
    ,confirmed_order
    ,cpm
    ,cost_by_cpm as expense_by_cpm
    ,order_gmv / 100000.0 as order_gmv
    ,order_gmv /  (100000.0 * exchange_rate) as order_gmv_usd
    ,order_amount as item_sold_cnt
    ,broad_gmv / 100000.0 as broad_gmv
    ,broad_gmv /  (100000.0 * exchange_rate) as broad_gmv_usd
    ,broad_item_count as broad_item_sold_cnt
    ,cost as ads_expenditure
    ,cost /  exchange_rate as ads_expenditure_usd
    ,view_duration
    ,ls_session_start_timestamp
    ,ls_session_start_time
    ,ls_session_end_timestamp
    ,ls_session_end_time
    ,ls_session_duration
    ,product_click
    ,campaign_start_datetime
    ,campaign_end_datetime
    ,ads_create_timestamp
    ,from_unixtime(ads_create_timestamp, 'yyyy-MM-dd HH:mm:ss') as ads_create_datetime
    ,request_id
    ,pricing_type
    ,order_id
    ,model_id
    ,expense_free_credit_with_expiry 
    ,expense_free_credit_without_expiry
    ,expense_paid_credit_with_expiry
    ,expense_paid_credit_without_expiry
    ,target_type
    ,page_section
    ,page_type
    ,origin_item_id
    ,target_affiliate_id
    ,sub_entrance
    ,agent_order_gmv / 100000.0 as agent_gmv
    ,agent_order_gmv / (100000.0 * exchange_rate) as agent_gmv_usd
    ,agent_order
    ,agent_order_amount as agent_item_sold_cnt
    ,agent_checkout
    ,daily_order
    ,daily_order_amount as daily_item_sold_cnt
    ,daily_gmv / 100000.0 as daily_gmv_amt_local
    ,daily_gmv / (100000.0 * exchange_rate) as daily_gmv_amt_usd
    ,click_timestamp
    ,from_unixtime(click_timestamp, 'yyyy-MM-dd HH:mm:ss') as click_datetime
    ,from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
    ,paid_timestamp
    ,from_unixtime(paid_timestamp, 'yyyy-MM-dd HH:mm:ss') as paid_datetime
    ,confirmed_timestamp
    ,from_unixtime(confirmed_timestamp, 'yyyy-MM-dd HH:mm:ss') as confirmed_datetime
    ,platform
    ,streamer_type
    ,traffic_source
    ,recall_source
    ,target_cir
    ,click_event_id
    ,streamer_shop_id
    ,source 
    ,content_mix_frame_tab_name
    ,imp_attr_order
    ,imp_attr_order_amount
    ,imp_attr_order_gmv
    ,imp_attr_order_gmv / exchange_rate as imp_attr_order_gmv_usd
    ,imp_attr_agent_order
    ,imp_attr_agent_order_amount
    ,imp_attr_agent_order_gmv
    ,imp_attr_agent_order_gmv / exchange_rate as imp_attr_agent_order_gmv_usd
    ,shop_exp_tag
    ,paid_order_amount
    ,paid_order_gmv
    ,paid_order_gmv / exchange_rate as paid_order_gmv_usd
    ,paid_checkout_cnt
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_amount
    ,is_cod
    ,bid_rerank_trace
    ,a.grass_region as grass_region
from live_report_ng_all a 
left join dim_advertise b 
on a.ads_id = b.ads_id
-- and a.campaign_id = b.campaign_id
left join ls_dim c 
on a.ls_session_id = c.ls_session_id
left join dim_exchange d 
on a.grass_region = d.grass_region
;

insert overwrite table dwd_livestream_performance_di__reg_s0_live partition (tz_type='local', grass_region, grass_date)
select 
    ads_id
    ,item_id
    ,a.shop_id as shop_id
    ,user_id
    ,campaign_id
    ,account_id
    ,ls_session_id
    ,streamer_id
    ,entrance
    ,placement
    ,event_timestamp
    ,location
    ,location_in_ads
    ,slot_id
    ,impression
    ,non_fraud_impression
    ,deduct_impression
    ,click
    ,raw_click
    ,order
    ,checkout
    ,view
    ,add_to_cart
    ,broad_order
    ,paid_order
    ,confirmed_order
    ,cpm
    ,expense_by_cpm
    ,order_gmv
    ,order_gmv_usd
    ,item_sold_cnt
    ,broad_gmv
    ,broad_gmv_usd
    ,broad_item_sold_cnt
    ,ads_expenditure
    ,ads_expenditure_usd
    ,view_duration
    ,ls_session_start_timestamp
    ,ls_session_start_time
    ,ls_session_end_timestamp
    ,ls_session_end_time
    ,ls_session_duration
    ,product_click
    ,campaign_start_datetime
    ,campaign_end_datetime
    ,ads_create_timestamp
    ,ads_create_datetime
    ,request_id
    ,pricing_type
    ,order_id
    ,model_id
    ,expense_free_credit_with_expiry 
    ,expense_free_credit_without_expiry
    ,expense_paid_credit_with_expiry
    ,expense_paid_credit_without_expiry
    ,ads_expenditure / (case when is_cb_shop = 1 then 1 + COALESCE(cb_tax,0.0) else 1 + COALESCE(local_tax,0.0) end) as ads_expenditure_vat
    ,ads_expenditure_usd / (case when is_cb_shop = 1 then 1 + COALESCE(cb_tax,0.0) else 1 + COALESCE(local_tax,0.0) end) as ads_expenditure_usd_vat
    ,target_type
    ,page_section
    ,page_type
    ,origin_item_id
    ,target_affiliate_id
    ,sub_entrance
    ,agent_gmv
    ,agent_gmv_usd
    ,agent_order
    ,agent_item_sold_cnt
    ,agent_checkout
    ,daily_order
    ,daily_item_sold_cnt
    ,daily_gmv_amt_local
    ,daily_gmv_amt_usd
    ,click_timestamp
    ,click_datetime
    ,event_datetime
    ,paid_timestamp
    ,paid_datetime
    ,confirmed_timestamp
    ,confirmed_datetime
    ,platform
    ,streamer_type
    ,traffic_source
    ,recall_source
    ,target_cir
    ,click_event_id
    ,streamer_shop_id
    ,source 
    ,content_mix_frame_tab_name
    ,imp_attr_order
    ,imp_attr_order_amount
    ,imp_attr_order_gmv
    ,imp_attr_order_gmv_usd
    ,imp_attr_agent_order
    ,imp_attr_agent_order_amount
    ,imp_attr_agent_order_gmv
    ,imp_attr_agent_order_gmv_usd
    ,shop_exp_tag
    
    ,paid_order_amount
    ,paid_order_gmv
    ,paid_order_gmv_usd
    ,paid_checkout_cnt
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_amount
    ,is_cod
    ,bid_rerank_trace
    ,a.grass_region as grass_region
    ,date('${grass_date}') grass_date
from base a 
left join dim_shop e 
on a.shop_id = e.shop_id
left join tax f 
on a.grass_region = f.grass_region 
;

alter table dwd_livestream_performance_di__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");