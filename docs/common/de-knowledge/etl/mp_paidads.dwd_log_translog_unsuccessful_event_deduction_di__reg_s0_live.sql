-- task_code: data_paidadsmart.studio_5649629  asset_id: 5649629
CREATE TABLE if not exists dwd_log_translog_unsuccessful_event_deduction_di__reg_s0_live (
    unique_id bigint
    ,ads_id bigint
    ,account_id bigint
    -- ,country string
    ,campaign_id bigint
    ,seller_user_id bigint
    ,item_id bigint
    ,shop_id bigint
    ,deduct_type int
    -- ,event_time bigint
    ,entrance int
    ,pricing_type int
    ,placement int
    ,daily_quota bigint
    ,total_quota bigint
    ,operation int
    ,price bigint
    ,platform int
    ,sub_entrance int
    ,ls_session_id bigint
    ,deduct_date string
    ,is_seller boolean
    ,quota_split struct<placement:int,daily_available_quota:bigint,version:int,placements:array<int>>
    ,status int
    ,account struct<accountid:bigint,userid:bigint,balance:bigint,ctime:bigint,mtime:bigint,status:int,overdue_limit:bigint,extinfo:binary,display_ads_balance:bigint>
    ,ads_credits array<struct<order_id:bigint,order_type:int,user_id:bigint,shop_id:int,amount:bigint,balance:bigint,main_type:int,subtype:bigint,start_time:bigint,end_time:bigint,ctime:bigint,mtime:bigint,extinfo:binary>>
    ,campaign_balance_by_date struct<campaignid:bigint,userid:bigint,daily_balance:bigint,mtime:bigint,ctime:bigint,extinfo:binary>
    ,campaign_balance struct<campaignid:bigint,daily_balance:bigint,mtime:bigint,history_balance:bigint,userid:bigint>
    ,country string
    ,event_time bigint 
    ,adjusted_cost bigint 
    ,credit_cost bigint 
    ,balance_cost bigint
    ,campaign_balance_by_date_extinfo struct<placement_expenses:array<struct<placement:int, expense:bigint >>, initial_balance:bigint>
    ,grass_region string 
    ,grass_date date
)
PARTITIONED BY (grass_region, grass_date)
STORED AS parquet
LOCATION 'hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/dwd_log_translog_unsuccessful_event_deduction_di__reg_s0_live';

create or replace temporary function campaign_daily_balance_ext_info as 'com.shopee.deepdata.warehouse.hive.udf.CampaignDailyBalanceExtInfoUDF';

insert overwrite table dwd_log_translog_unsuccessful_event_deduction_di__reg_s0_live partition (grass_region, grass_date)
SELECT
    deduction_event.unique_id
    ,deduction_event.ads_id
    ,deduction_event.account_id
    -- ,deduction_event.country
    ,deduction_event.campaign_id
    ,deduction_event.seller_user_id
    ,deduction_event.item_id
    ,deduction_event.shop_id
    ,deduction_event.deduct_type
    -- ,deduction_event.event_time
    ,deduction_event.entrance
    ,deduction_event.pricing_type
    ,deduction_event.placement
    ,deduction_event.daily_quota
    ,deduction_event.total_quota
    ,deduction_event.operation
    ,deduction_event.price
    ,deduction_event.platform
    ,deduction_event.sub_entrance
    ,deduction_event.ls_session_id
    ,deduction_event.deduct_date
    ,deduction_event.is_seller
    ,deduction_event.quota_split
    ,status
    ,account
    ,ads_credits
    ,campaign_balance_by_date
    ,campaign_balance
    ,country
    ,event_time
    ,adjusted_cost
    ,credit_cost
    ,balance_cost
    ,campaign_daily_balance_ext_info(campaign_balance_by_date.extinfo) as campaign_balance_by_date_extinfo
    ,tracking_json_data 
    ,item_json_data 
    ,shop_json_data 
    ,recall_source 
    ,order_id 
    ,valid_balance
    ,available_balance
    ,version int
    ,user_id
    ,grass_region
    ,grass_date
FROM mp_paidads.ods_log_translog_unsuccessful_event_deduction_hi__reg_s0_live
where grass_date = '${BIZ_YESTERDAY}';