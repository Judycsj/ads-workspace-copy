-- task_code: data_paidadsmart.studio_3849646  asset_id: 3849646
-- create external table if not exists ads_advertiser_seller_all_metrics_1d__reg_s0_live
-- (
--     shop_id    bigint
--     ,seller_name  string
--     ,seller_type  string
--     ,cluster      string
--     ,shop_level1_global_be_category  string
--     ,shop_level2_global_be_category  string
--     ,is_principal   tinyint
--     ,principal_type  string
--     ,total_topup_amt  double
--     ,total_topup_amt_usd   double
--     ,seller_topup_amt  double
--     ,seller_topup_amt_usd  double
--     ,manual_topup_amt  double
--     ,manual_topup_amt_usd  double
--     ,free_credit_topup_amt  double.....
--     ,free_credit_topup_amt_usd  double
--     ,paid_credit_topup_amt  double
--     ,paid_credit_topup_amt_usd  double
--     ,voucher_free_credit_topup_amt  double
--     ,voucher_free_credit_topup_amt_usd  double
--     ,package_free_credit_topup_amt  double
--     ,package_free_credit_topup_amt_usd  double
--     ,seller_mission_free_credit_topup_amt  double
--     ,seller_mission_free_credit_topup_amt_usd  double
--     ,manual_free_credit_topup_amt  double
--     ,manual_free_credit_topup_amt_usd  double
--     ,srm_free_credit_topup_amt  double
--     ,srm_free_credit_topup_amt_usd  double
--     ,total_deduction_amt  double
--     ,total_deduction_amt_usd  double
--     ,free_credit_deduction_amt  double
--     ,free_credit_deduction_amt_usd  double
--     ,paid_credit_deduction_amt  double
--     ,paid_credit_deduction_amt_usd  double
--     ,voucher_free_credit_deduction_amt  double
--     ,voucher_free_credit_deduction_amt_usd  double
--     ,package_free_credit_deduction_amt  double
--     ,package_free_credit_deduction_amt_usd  double
--     ,seller_mission_free_credit_deduction_amt  double
--     ,seller_mission_free_credit_deduction_amt_usd  double
--     ,manual_free_credit_deduction_amt  double
--     ,manual_free_credit_deduction_amt_usd  double
--     ,srm_free_credit_deduction_amt  double
--     ,srm_free_credit_deduction_amt_usd  double
--     ,total_credit_expiry_amt  double
--     ,total_credit_expiry_amt_usd  double
--     ,free_credit_expiry_amt  double
--     ,free_credit_expiry_amt_usd  double
--     ,paid_credit_expiry_amt  double
--     ,paid_credit_expiry_amt_usd  double
--     ,voucher_free_credit_expiry_amt  double
--     ,voucher_free_credit_expiry_amt_usd  double
--     ,package_free_credit_expiry_amt  double
--     ,package_free_credit_expiry_amt_usd  double
--     ,seller_mission_free_credit_expiry_amt  double
--     ,seller_mission_free_credit_expiry_amt_usd  double
--     ,manual_free_credit_expiry_amt  double
--     ,manual_free_credit_expiry_amt_usd  double
--     ,srm_free_credit_expiry_amt  double
--     ,srm_free_credit_expiry_amt_usd  double
--     ,total_balance_amt  double
--     ,total_balance_amt_usd  double
--     ,free_credit_balance_amt  double
--     ,free_credit_balance_amt_usd  double
--     ,paid_credit_balance_amt  double
--     ,paid_credit_balance_amt_usd  double
--     ,voucher_free_balance_amt  double
--     ,voucher_free_balance_amt_usd  double
--     ,package_free_balance_amt  double
--     ,package_free_balance_amt_usd  double
--     ,manual_free_balance_amt  double
--     ,manual_free_balance_amt_usd  double
--     ,srm_free_balance_amt  double
--     ,srm_free_balance_amt_usd  double
--     ,deleted_campaign_cnt  bigint
--     ,ongoing_campaign_cnt  bigint
--     ,pause_campaign_cnt  bigint
--     ,closed_campaign_cnt  bigint
--     ,create_campaign_cnt  bigint
--     ,end_campaign_cnt  bigint
--     ,avg_campaign_items  double
--     ,daily_quota_local  double
--     ,avg_campaign_budget  double
--     ,hit_budget_campaign_cnt  bigint
--     ,hit_budget_campaign_per  double
--     ,budget_cost_ratio  double
--     ,avg_hit_budget_expense  double
--     ,limited_budget_cnt  bigint
--     ,unlimited_budget_cnt  bigint
-- )
--     partitioned by
-- (
--     tz_type string comment 'tz_type'
--     ,grass_region string comment 'grass_region'
--     ,grass_date DATE comment 'grass_date'
-- )
-- stored as PARQUET
-- location '${path}'
-- ;

create or replace temporary view seller_info as
select  shop_id
        ,seller_name
        ,shop_level1_global_be_category
        ,shop_level2_global_be_category
        ,seller_type
        ,cluster
        ,is_principal
        ,principal_type
        ,is_cb_seller
        ,account_create_datetime
        ,is_official_shop
        ,is_preferred_shop
        ,is_managed_seller
        ,seller_tier
        ,advertiser_tier
        ,seller_status
        ,advertiser_status
        ,ads_placement_type
        ,key_seller_90
        ,key_seller_95
from    mp_paidads.dim_shop_info__reg_s0_live
where grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local';
;

--credit_df 
cache table credit_df 
select 
    shop_id
    ,order_type
    ,order_id
    ,credit_topup_type
    ,is_package_topup
    ,is_voucher_topup
    ,topup_amt
    ,topup_amt_usd
    ,is_credit_topup_expired_today
    ,is_topup_today
    ,credit_balance_amt
    ,credit_balance_amt_usd
    ,pckg_paid_amt
    ,pckg_paid_amt_usd
    ,voucher_discount_amt
    ,voucher_discount_amt_usd
    ,credit_topup_expiry_end_datetime
    ,credit_topup_expiry_end_timestamp
from mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
where grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local';


--topup amount
create or replace temporary view topup as
select 
    shop_id
    ,sum(topup_amt) as total_topup_amt
    ,sum(topup_amt_usd) as total_topup_amt_usd
    ,sum(case when order_type in (2,4,6) then topup_amt else 0.0 end) as seller_topup_amt
    ,sum(case when order_type in (2,4,6) then topup_amt_usd else 0.0 end) as seller_topup_amt_usd
    ,sum(case when order_type in (2,6) then topup_amt else 0.0 end) as seller_one_time_topup_amt
    ,sum(case when order_type in (2,6) then topup_amt_usd else 0.0 end) as  seller_one_time_topup_amt_usd
    ,sum(case when is_voucher_topup = 1 then topup_amt else 0.0 end) as voucher_topup_amt
    ,sum(case when is_voucher_topup = 1 then topup_amt_usd else 0.0 end) as voucher_topup_amt_usd
    ,sum(case when is_package_topup = 1 then topup_amt else 0.0 end) as package_topup_amt
    ,sum(case when is_package_topup = 1 then topup_amt_usd else 0.0 end) as package_topup_amt_usd
    ,sum(case when order_type in (4) then topup_amt else 0.0 end) as seller_auto_topup_amt
    ,sum(case when order_type in (4) then topup_amt_usd else 0.0 end) as  seller_auto_topup_amt_usd
    ,sum(case when order_type in (3,10,8,9) then topup_amt else 0.0 end) as admin_topup_amt
    ,sum(case when order_type in (3,10,8,9) then topup_amt_usd else 0.0 end) as admin_topup_amt_usd
    ,sum(case when order_type in (3,10) then topup_amt else 0.0 end) as admin_manual_topup_amt
    ,sum(case when order_type in (3,10) then topup_amt_usd else 0.0 end) as admin_manual_topup_amt_usd
    ,sum(case when order_type = 3 then topup_amt else 0.0 end) as admin_manual_cb_topup_amt
    ,sum(case when order_type = 3 then topup_amt_usd else 0.0 end) as admin_manual_cb_topup_amt_usd
    ,sum(case when order_type in (10) then topup_amt else 0.0 end) as admin_manual_adjust_topup_amt
    ,sum(case when order_type in (10) then topup_amt_usd else 0.0 end) as admin_manual_adjust_topup_amt_usd
    ,sum(case when order_type in (8,9) then topup_amt else 0.0 end) as admin_api_topup_amt
    ,sum(case when order_type in (8,9) then topup_amt_usd else 0.0 end) as admin_api_topup_amt_usd
    ,sum(case when order_type in (8) then topup_amt else 0.0 end) as admin_api_seller_mission_topup_amt
    ,sum(case when order_type in (8) then topup_amt_usd else 0.0 end) as admin_api_seller_mission_topup_amt_usd
    ,sum(case when order_type in (9) then topup_amt else 0.0 end) as admin_api_qss_topup_amt
    ,sum(case when order_type in (9) then topup_amt_usd else 0.0 end) as admin_api_qss_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) then topup_amt else 0.0 end) as free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) then topup_amt_usd else 0.0 end) as free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) then topup_amt else 0.0 end) as paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) then topup_amt_usd else 0.0 end) as paid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type in (2,4,6) then topup_amt else 0.0 end) as seller_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type in (2,4,6) then topup_amt_usd else 0.0 end) as seller_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type in (2,6) then topup_amt else 0.0 end) as seller_one_time_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type in (2,6) then topup_amt_usd else 0.0 end) as  seller_one_time_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type in (3,10,8,9) then topup_amt else 0.0 end) as admin_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type in (3,10,8,9) then topup_amt_usd else 0.0 end) as admin_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type in (8,9) then topup_amt else 0.0 end) as admin_api_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type in (8,9) then topup_amt_usd else 0.0 end) as admin_api_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and is_voucher_topup = 1 then topup_amt else 0.0 end) as voucher_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and is_voucher_topup = 1 then topup_amt_usd else 0.0 end) as voucher_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and is_package_topup = 1 then topup_amt else 0.0 end) as package_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and is_package_topup = 1 then topup_amt_usd else 0.0 end) as package_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then topup_amt else 0.0 end) as admin_api_seller_mission_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then topup_amt_usd else 0.0 end) as admin_api_seller_mission_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then topup_amt else 0.0 end) as admin_manual_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then topup_amt_usd else 0.0 end) as admin_manual_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then topup_amt else 0.0 end) as admin_api_qss_free_credit_topup_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then topup_amt_usd else 0.0 end) as admin_api_qss_free_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and order_type in (2,4,6) then topup_amt else 0.0 end) as seller_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and order_type in (2,4,6) then topup_amt_usd else 0.0 end) as seller_paid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and order_type in (2,6) then topup_amt else 0.0 end) as seller_one_time_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and order_type in (2,6) then topup_amt_usd else 0.0 end) as  seller_one_time_paid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and order_type in (4) then topup_amt else 0.0 end) as seller_auto_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and order_type in (4) then topup_amt_usd else 0.0 end) as  seller_auto_fpaid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and order_type in (3,10,8,9) then topup_amt else 0.0 end) as admin_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and order_type in (3,10,8,9) then topup_amt_usd else 0.0 end) as admin_paid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and is_voucher_topup = 1 then topup_amt else 0.0 end) as voucher_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and is_voucher_topup = 1 then topup_amt_usd else 0.0 end) as voucher_paid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and is_package_topup = 1 then topup_amt else 0.0 end) as package_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and is_package_topup = 1 then topup_amt_usd else 0.0 end) as package_paid_credit_topup_amt_usd
    ,sum(case when credit_topup_type in (1,2) and order_type = 3 then topup_amt else 0.0 end) as admin_manual_paid_credit_topup_amt
    ,sum(case when credit_topup_type in (1,2) and order_type = 3 then topup_amt_usd else 0.0 end) as admin_manual_paid_credit_topup_amt_usd
from credit_df
where is_topup_today = 1
group by shop_id;

--deduction
create or replace temporary view deduction_di as
select 
    shop_id
    ,sum(deduction_amt) as total_deduction_amt
    ,sum(deduction_amt_usd) as total_deduction_amt_usd
    ,sum(case when credit_topup_type in (3,4) then deduction_amt else 0.0 end) as free_credit_deduction_amt
    ,sum(case when credit_topup_type in (3,4) then deduction_amt_usd else 0.0 end) as free_credit_deduction_amt_usd
    ,sum(case when credit_topup_type in (1,2) then deduction_amt else 0.0 end) as paid_credit_deduction_amt
    ,sum(case when credit_topup_type in (1,2) then deduction_amt_usd else 0.0 end) as paid_credit_deduction_amt_usd
    ,sum(case when credit_topup_type in (3,4) and sub_type = 1 then deduction_amt else 0.0 end) as voucher_free_credit_deduction_amt
    ,sum(case when credit_topup_type in (3,4) and sub_type = 1 then deduction_amt_usd else 0.0 end) as voucher_free_credit_deduction_amt_usd
    ,sum(case when credit_topup_type in (3,4) and sub_type = 2 then deduction_amt else 0.0 end) as package_free_credit_deduction_amt
    ,sum(case when credit_topup_type in (3,4) and sub_type = 2 then deduction_amt_usd else 0.0 end) as package_free_credit_deduction_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then deduction_amt else 0.0 end) as seller_mission_free_credit_deduction_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then deduction_amt_usd else 0.0 end) as seller_mission_free_credit_deduction_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then deduction_amt else 0.0 end) as manual_free_credit_deduction_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then deduction_amt_usd else 0.0 end) as manual_free_credit_deduction_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then deduction_amt else 0.0 end) as srm_free_credit_deduction_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then deduction_amt_usd else 0.0 end) as srm_free_credit_deduction_amt_usd
from
(select  
    shop_id
    ,deduction_amt
    ,deduction_amt_usd
    ,credit_topup_type
    ,credit_order_type as order_type
    ,sub_type
from mp_paidads.dwd_advertiser_deduction_di__reg_s0_live
where grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   )a
group by shop_id;

--expiry amount
create or replace temporary view expiry as
select 
    shop_id
    ,sum(credit_balance_amt) as total_credit_expiry_amt
    ,sum(credit_balance_amt_usd) as total_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (3,4) then credit_balance_amt else 0.0 end) as free_credit_expiry_amt
    ,sum(case when credit_topup_type in (3,4) then credit_balance_amt_usd else 0.0 end) as free_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (1,2) then credit_balance_amt else 0.0 end) as paid_credit_expiry_amt
    ,sum(case when credit_topup_type in (1,2) then credit_balance_amt_usd else 0.0 end) as paid_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (3,4) and is_voucher_topup = 1 then credit_balance_amt else 0.0 end) as voucher_free_credit_expiry_amt
    ,sum(case when credit_topup_type in (3,4) and is_voucher_topup = 1 then credit_balance_amt_usd else 0.0 end) as voucher_free_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (3,4) and is_package_topup = 1 then credit_balance_amt else 0.0 end) as package_free_credit_expiry_amt
    ,sum(case when credit_topup_type in (3,4) and is_package_topup = 1 then credit_balance_amt_usd else 0.0 end) as package_free_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then credit_balance_amt else 0.0 end) as seller_mission_free_credit_expiry_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then credit_balance_amt_usd else 0.0 end) as seller_mission_free_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then credit_balance_amt else 0.0 end) as manual_free_credit_expiry_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then credit_balance_amt_usd else 0.0 end) as manual_free_credit_expiry_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then credit_balance_amt else 0.0 end) as srm_free_credit_expiry_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then credit_balance_amt_usd else 0.0 end) as srm_free_credit_expiry_amt_usd
from credit_df
where is_credit_topup_expired_today = 1
group by shop_id;

--balance
create or replace temporary view balance_df as
select 
    shop_id
    ,sum(total_balance_amt) as total_balance_amt
    ,sum(total_balance_amt_usd) as total_balance_amt_usd
    ,sum(free_credit_balance_amt) as free_credit_balance_amt
    ,sum(free_credit_balance_amt_usd) as free_credit_balance_amt_usd
    ,sum(paid_credit_balance_amt) as paid_credit_balance_amt
    ,sum(paid_credit_balance_amt_usd) as paid_credit_balance_amt_usd
    ,sum(voucher_free_balance_amt) as voucher_free_balance_amt
    ,sum(voucher_free_balance_amt_usd) as voucher_free_balance_amt_usd
    ,sum(package_free_balance_amt) as package_free_balance_amt
    ,sum(package_free_balance_amt_usd) as package_free_balance_amt_usd
    ,sum(seller_mission_free_balance_amt) as seller_mission_free_balance_amt
    ,sum(seller_mission_free_balance_amt_usd) as seller_mission_free_balance_amt_usd
    ,sum(manual_free_balance_amt) as manual_free_balance_amt
    ,sum(manual_free_balance_amt_usd) as manual_free_balance_amt_usd
    ,sum(srm_free_balance_amt) as srm_free_balance_amt
    ,sum(srm_free_balance_amt_usd) as srm_free_balance_amt_usd
from
(select 
    shop_id
    ,SUM(CASE WHEN order_id is NULL AND credit_expiry_time is NULL THEN end_of_day_balance ELSE 0 END) / 100000.0 as total_balance_amt
    ,SUM(CASE WHEN order_id is NULL AND credit_expiry_time is NULL THEN end_of_day_balance_usd ELSE 0 END) / 100000.0 as total_balance_amt_usd
    ,0 as free_credit_balance_amt
    ,0 as free_credit_balance_amt_usd
    ,SUM(CASE WHEN order_id is NULL AND credit_expiry_time is NULL THEN end_of_day_balance ELSE 0 END) / 100000.0 as paid_credit_balance_amt
    ,SUM(CASE WHEN order_id is NULL AND credit_expiry_time is NULL THEN end_of_day_balance_usd ELSE 0 END) / 100000.0 as paid_credit_balance_amt_usd
    ,0 as voucher_free_balance_amt
    ,0 as voucher_free_balance_amt_usd
    ,0 as package_free_balance_amt
    ,0 as package_free_balance_amt_usd
    ,0 as seller_mission_free_balance_amt
    ,0 as seller_mission_free_balance_amt_usd
    ,0 as manual_free_balance_amt
    ,0 as manual_free_balance_amt_usd
    ,0 as srm_free_balance_amt
    ,0 as srm_free_balance_amt_usd
from mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live
where grass_region = upper('${region}')
  and   dt = '${grass_date}'
group by shop_id
union all
select 
    shop_id
    ,sum(credit_balance_amt) as total_balance_amt
    ,sum(credit_balance_amt_usd) as total_balance_amt_usd
    ,sum(case when credit_topup_type in (3,4) then credit_balance_amt else 0.0 end) as free_credit_balance_amt
    ,sum(case when credit_topup_type in (3,4) then credit_balance_amt_usd else 0.0 end) as free_credit_balance_amt_usd
    ,sum(case when credit_topup_type in (1,2) then credit_balance_amt else 0.0 end) as paid_credit_balance_amt
    ,sum(case when credit_topup_type in (1,2) then credit_balance_amt_usd else 0.0 end) as paid_credit_balance_amt_usd
    ,sum(case when credit_topup_type in (3,4) and is_voucher_topup = 1 then credit_balance_amt else 0.0 end) as voucher_free_balance_amt
    ,sum(case when credit_topup_type in (3,4) and is_voucher_topup = 1 then credit_balance_amt_usd else 0.0 end) as voucher_free_balance_amt_usd
    ,sum(case when credit_topup_type in (3,4) and is_package_topup = 1 then credit_balance_amt else 0.0 end) as package_free_balance_amt
    ,sum(case when credit_topup_type in (3,4) and is_package_topup = 1 then credit_balance_amt_usd else 0.0 end) as package_free_balance_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then credit_balance_amt else 0.0 end) as seller_mission_free_balance_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 8 then credit_balance_amt_usd else 0.0 end) as seller_mission_free_balance_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then credit_balance_amt else 0.0 end) as manual_free_balance_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 3 then credit_balance_amt_usd else 0.0 end) as manual_free_balance_amt_usd
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then credit_balance_amt else 0.0 end) as srm_free_balance_amt
    ,sum(case when credit_topup_type in (3,4) and order_type = 9 then credit_balance_amt_usd else 0.0 end) as srm_free_balance_amt_usd
    from credit_df
    where date(credit_topup_expiry_end_datetime) >= '${grass_date}' or credit_topup_expiry_end_timestamp = 0
    group by shop_id
)a
 group by shop_id;

 cache table ads_advertise_mkt 
 select 
    shop_id,
    campaign_id,
    item_id,
    ads_id,
    placement,
    campaign_status,
    campaign_start_datetime,
    campaign_end_datetime,
    campaign_daily_quota_usd,
    campaign_total_quota_usd,
    impression_cnt,
    click_cnt,
    order_cnt,
    broad_order_cnt,
    ads_gmv_usd,
    broad_order_gmv_amt_usd,
    ads_expenditure_amt_usd,
    is_ads_active,
    has_performance,
    grass_region
 from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = '${grass_date}'
    and tz_type = 'local';


--campaign
create or replace temporary view campaign_cnt as
select 
    shop_id,
    count(distinct case when array_contains(campaign_status,0) then campaign_id else null end) as deleted_campaign_cnt ,
    count(distinct case when array_contains(campaign_status,1) then campaign_id else null end) as ongoing_campaign_cnt,
    count(distinct case when array_contains(campaign_status,2) then campaign_id else null end) as pause_campaign_cnt ,
    count(distinct case when array_contains(campaign_status,3) then campaign_id else null end) as closed_campaign_cnt , 
    count(distinct case when date(campaign_start_datetime) = '${grass_date}'  then campaign_id else null end) as create_campaign_cnt ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' then campaign_id else null end) as end_campaign_cnt ,
    avg(item_cnt) as avg_campaign_items,

    count(distinct case when array_contains(campaign_status,0) and ads_cnt = 1 and max_placement = 4 then campaign_id else null end) as deleted_campaign_cnt_search_simple_only ,
    count(distinct case when array_contains(campaign_status,1) and ads_cnt = 1 and max_placement = 4 then campaign_id else null end) as ongoing_campaign_cnt_search_simple_only ,
    count(distinct case when array_contains(campaign_status,2) and ads_cnt = 1 and max_placement = 4 then campaign_id else null end) as pause_campaign_cnt_search_simple_only ,
    count(distinct case when array_contains(campaign_status,3) and ads_cnt = 1 and max_placement = 4 then campaign_id else null end) as closed_campaign_cnt_search_simple_only , 
    count(distinct case when date(campaign_start_datetime) = '${grass_date}' and ads_cnt = 1 and max_placement = 4 then campaign_id else null end) as create_campaign_cnt_search_simple_only ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and ads_cnt = 1 and max_placement = 4 then campaign_id else null end) as end_campaign_cnt_search_simple_only ,
    avg(case when ads_cnt = 1 and max_placement = 4 then item_cnt end) as avg_campaign_items_search_simple_only,
    

    count(distinct case when array_contains(campaign_status,0) and ads_cnt = 1 and max_placement = 0 then campaign_id else null end) as deleted_campaign_cnt_search_manual_only,
    count(distinct case when array_contains(campaign_status,1) and ads_cnt = 1 and max_placement = 0 then campaign_id else null end) as ongoing_campaign_cnt_search_manual_only,
    count(distinct case when array_contains(campaign_status,2) and ads_cnt = 1 and max_placement = 0 then campaign_id else null end) as pause_campaign_cnt_search_manual_only,
    count(distinct case when array_contains(campaign_status,3) and ads_cnt = 1 and max_placement = 0 then campaign_id else null end) as closed_campaign_cnt_search_manual_only, 
    count(distinct case when date(campaign_start_datetime) = '${grass_date}' and ads_cnt = 1 and max_placement = 0 then campaign_id else null end) as create_campaign_cnt_search_manual_only,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and ads_cnt = 1 and max_placement = 0 then campaign_id else null end) as end_campaign_cnt_search_manual_only,
    avg(case when ads_cnt = 1 and max_placement = 0 then item_cnt end) as avg_campaign_items_search_manual_only,
    
    count(distinct case when array_contains(campaign_status,0) and ads_cnt = 2 and max_placement = 4 then campaign_id else null end) as deleted_campaign_cnt_search_manual_simple,
    count(distinct case when array_contains(campaign_status,1) and ads_cnt = 2 and max_placement = 4 then campaign_id else null end) as ongoing_campaign_cnt_search_manual_simple,
    count(distinct case when array_contains(campaign_status,2) and ads_cnt = 2 and max_placement = 4 then campaign_id else null end) as pause_campaign_cnt_search_manual_simple,
    count(distinct case when array_contains(campaign_status,3) and ads_cnt = 2 and max_placement = 4 then campaign_id else null end) as closed_campaign_cnt_search_manual_simple,
    count(distinct case when date(campaign_start_datetime) = '${grass_date}' and ads_cnt = 2 and max_placement = 4 then campaign_id else null end) as create_campaign_cnt_search_manual_simple,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and ads_cnt = 2 and max_placement = 4 then campaign_id else null end) as end_campaign_cnt_search_manual_simple,
    avg(case when ads_cnt = 2 and max_placement = 4 then item_cnt end) as avg_campaign_items_search_manual_simple,
    
    count(distinct case when array_contains(campaign_status,0) and max_placement in (2,5) then campaign_id else null end) as deleted_campaign_cnt_discovery_manual,
    count(distinct case when array_contains(campaign_status,1) and max_placement in (2,5) then campaign_id else null end) as ongoing_campaign_cnt_discovery_manual,
    count(distinct case when array_contains(campaign_status,2) and max_placement in (2,5) then campaign_id else null end) as pause_campaign_cnt_discovery_manual,
    count(distinct case when array_contains(campaign_status,3) and max_placement in (2,5) then campaign_id else null end) as closed_campaign_cnt_discovery_manual,
    count(distinct case when date(campaign_start_datetime) = '${grass_date}' and max_placement in (2,5) then campaign_id else null end) as create_campaign_cnt_discovery_manual,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and max_placement in (2,5) then campaign_id else null end) as end_campaign_cnt_discovery_manual,
    avg(case when max_placement in (2,5) then item_cnt end) as avg_campaign_items_discovery_manual,
    
    count(distinct case when array_contains(campaign_status,0) and max_placement in (802,805) then campaign_id else null end) as deleted_campaign_cnt_discovery_simple,
    count(distinct case when array_contains(campaign_status,1) and max_placement in (802,805) then campaign_id else null end) as ongoing_campaign_cnt_discovery_simple,
    count(distinct case when array_contains(campaign_status,2) and max_placement in (802,805) then campaign_id else null end) as pause_campaign_cnt_discovery_simple,
    count(distinct case when array_contains(campaign_status,3) and max_placement in (802,805) then campaign_id else null end) as closed_campaign_cnt_discovery_simple,
    count(distinct case when date(campaign_start_datetime) = '${grass_date}' and max_placement in (802,805) then campaign_id else null end) as create_campaign_cnt_discovery_simple,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and max_placement in (802,805) then campaign_id else null end) as end_campaign_cnt_discovery_simple,
    avg(case when max_placement in (802,805) then item_cnt end) as avg_campaign_items_discovery_simple,

    count(distinct case when array_contains(campaign_status,0) and max_placement in (40) then campaign_id else null end) as deleted_campaign_cnt_roi_two,
    count(distinct case when array_contains(campaign_status,1) and max_placement in (40) then campaign_id else null end) as ongoing_campaign_cnt_roi_two,
    count(distinct case when array_contains(campaign_status,2) and max_placement in (40) then campaign_id else null end) as pause_campaign_cnt_roi_two,
    count(distinct case when array_contains(campaign_status,3) and max_placement in (40) then campaign_id else null end) as closed_campaign_cnt_roi_two,
    count(distinct case when date(campaign_start_datetime) = '${grass_date}' and max_placement in (40) then campaign_id else null end) as create_campaign_cnt_roi_two,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and max_placement in (40) then campaign_id else null end) as end_campaign_cnt_roi_two,
    avg(case when max_placement in (40) then item_cnt end) as avg_campaign_items_roi_two
    
from ( 
    select 
        campaign_id
        ,shop_id
        ,max(placement) as max_placement
        ,count(distinct ads_id) as ads_cnt
        ,count(distinct item_id) as item_cnt
        ,min(campaign_start_datetime) as campaign_start_datetime
        ,max(campaign_end_datetime) as campaign_end_datetime
        ,collect_set(campaign_status) as campaign_status
    from ads_advertise_mkt
    group by campaign_id,shop_id
) a
group by shop_id
;

--Budget
create or replace temporary view campaign_budget as
select 
    shop_id
    ,sum(daily_quota_local / exchange_rate)  as daily_quota_usd
    ,sum(total_quota_local / exchange_rate)  as total_quota_usd
    ,sum(daily_quota_local / exchange_rate)  / count(distinct case when daily_quota_local>0 or total_quota_local>0 then a.campaign_id end) as avg_campaign_budget
    ,count(distinct case when hit_daily_budget = 1 then a.campaign_id end) as hit_budget_campaign_cnt
    ,count(distinct case when hit_daily_budget = 1 then a.campaign_id end) / count(distinct case when daily_quota_local>0 or total_quota_local>0 then a.campaign_id end) as hit_budget_campaign_per
    ,avg(daily_deduction / daily_quota_local) as budget_cost_ratio
    ,avg(case when hit_daily_budget = 1 then daily_deduction / daily_quota_local else null end) as avg_hit_budget_expense
    ,count(distinct case when daily_quota_local is not null or total_quota_local is not null then a.campaign_id end) as limited_budget_cnt
    ,count(distinct case when daily_quota_local is null and total_quota_local is null then a.campaign_id end) as unlimited_budget_cnt
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 then a.campaign_id end) as daily_budget_campaign_cnt
    ,count(distinct case when ifnull(total_quota_local,0) > 0 then a.campaign_id end) as total_budget_campaign_cnt

    ,sum(case when ads_cnt = 1 and max_placement = 4 then daily_quota_local / exchange_rate else 0.0 end)  as daily_quota_usd_search_simple_only
    ,sum(case when ads_cnt = 1 and max_placement = 4 then total_quota_local / exchange_rate else 0.0 end)  as total_quota_usd_search_simple_only
    ,count(distinct case when hit_daily_budget = 1 and ads_cnt = 1 and max_placement = 4 then a.campaign_id end) as hit_budget_campaign_cnt_search_simple_only
    ,count(distinct case when (daily_quota_local is not null or total_quota_local is not null) and ads_cnt = 1 and max_placement = 4 then a.campaign_id end) as limited_budget_cnt_search_simple_only
    ,count(distinct case when (daily_quota_local is null and total_quota_local is null) and ads_cnt = 1 and max_placement = 4 then a.campaign_id end) as unlimited_budget_cnt_search_simple_only
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 and ads_cnt = 1 and max_placement = 4 then a.campaign_id end) as daily_budget_campaign_cnt_search_simple_only
    ,count(distinct case when ifnull(total_quota_local,0) > 0 and ads_cnt = 1 and max_placement = 4 then a.campaign_id end) as total_budget_campaign_cnt_search_simple_only

    ,sum(case when ads_cnt = 1 and max_placement = 0 then daily_quota_local / exchange_rate else 0.0 end)  as daily_quota_usd_search_manual_only
    ,sum(case when ads_cnt = 1 and max_placement = 0 then total_quota_local / exchange_rate else 0.0 end)  as total_quota_usd_search_manual_only
    ,count(distinct case when hit_daily_budget = 1 and ads_cnt = 1 and max_placement = 0 then a.campaign_id end) as hit_budget_campaign_cnt_search_manual_only
    ,count(distinct case when (daily_quota_local is not null or total_quota_local is not null) and ads_cnt = 1 and max_placement = 0 then a.campaign_id end) as limited_budget_cnt_search_manual_only
    ,count(distinct case when (daily_quota_local is null and total_quota_local is null) and ads_cnt = 1 and max_placement = 0 then a.campaign_id end) as unlimited_budget_cnt_search_manual_only
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 and ads_cnt = 1 and max_placement = 0 then a.campaign_id end) as daily_budget_campaign_cnt_search_manual_only
    ,count(distinct case when ifnull(total_quota_local,0) > 0 and ads_cnt = 1 and max_placement = 0 then a.campaign_id end) as total_budget_campaign_cnt_search_manual_only

    ,sum(case when ads_cnt = 2 and max_placement = 4 then daily_quota_local / exchange_rate else 0.0 end)  as daily_quota_usd_search_manual_simple
    ,sum(case when ads_cnt = 2 and max_placement = 4 then total_quota_local / exchange_rate else 0.0 end)  as total_quota_usd_search_manual_simple
    ,count(distinct case when hit_daily_budget = 1 and ads_cnt = 2 and max_placement = 4 then a.campaign_id end) as hit_budget_campaign_cnt_search_manual_simple
    ,count(distinct case when (daily_quota_local is not null or total_quota_local is not null) and ads_cnt = 2 and max_placement = 4 then a.campaign_id end) as limited_budget_cnt_search_manual_simple
    ,count(distinct case when (daily_quota_local is null and total_quota_local is null) and ads_cnt = 2 and max_placement = 4 then a.campaign_id end) as unlimited_budget_cnt_search_manual_simple
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 and ads_cnt = 2 and max_placement = 4 then a.campaign_id end) as daily_budget_campaign_cnt_search_manual_simple
    ,count(distinct case when ifnull(total_quota_local,0) > 0 and ads_cnt = 2 and max_placement = 4 then a.campaign_id end) as total_budget_campaign_cnt_search_manual_simple

    ,sum(case when max_placement in (2,5) then daily_quota_local / exchange_rate else 0.0 end)  as daily_quota_usd_discovery_manual
    ,sum(case when max_placement in (2,5) then total_quota_local / exchange_rate else 0.0 end)  as total_quota_usd_discovery_manual
    ,count(distinct case when hit_daily_budget = 1 and max_placement in (2,5) then a.campaign_id end) as hit_budget_campaign_cnt_discovery_manual
    ,count(distinct case when (daily_quota_local is not null or total_quota_local is not null) and max_placement in (2,5) then a.campaign_id end) as limited_budget_cnt_discovery_manual
    ,count(distinct case when (daily_quota_local is null and total_quota_local is null) and max_placement in (2,5) then a.campaign_id end) as unlimited_budget_cnt_discovery_manual
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 and max_placement in (2,5) then a.campaign_id end) as daily_budget_campaign_cnt_discovery_manual
    ,count(distinct case when ifnull(total_quota_local,0) > 0 and max_placement in (2,5) then a.campaign_id end) as total_budget_campaign_cnt_discovery_manual

    ,sum(case when max_placement in (802,805) then daily_quota_local / exchange_rate else 0.0 end)  as daily_quota_usd_discovery_simple
    ,sum(case when max_placement in (802,805) then total_quota_local / exchange_rate else 0.0 end)  as total_quota_usd_discovery_simple
    ,count(distinct case when hit_daily_budget = 1 and max_placement in (802,805) then a.campaign_id end) as hit_budget_campaign_cnt_discovery_simple
    ,count(distinct case when (daily_quota_local is not null or total_quota_local is not null) and max_placement in (802,805) then a.campaign_id end) as limited_budget_cnt_discovery_simple
    ,count(distinct case when (daily_quota_local is null and total_quota_local is null) and max_placement in (802,805) then a.campaign_id end) as unlimited_budget_cnt_discovery_simple
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 and max_placement in (802,805) then a.campaign_id end) as daily_budget_campaign_cnt_discovery_simple
    ,count(distinct case when ifnull(total_quota_local,0) > 0 and max_placement in (802,805) then a.campaign_id end) as total_budget_campaign_cnt_discovery_simple

    ,sum(case when max_placement in (40) then daily_quota_local / exchange_rate else 0.0 end)  as daily_quota_usd_roi_two
    ,sum(case when max_placement in (40) then total_quota_local / exchange_rate else 0.0 end)  as total_quota_usd_roi_two
    ,count(distinct case when hit_daily_budget = 1 and max_placement in (40) then a.campaign_id end) as hit_budget_campaign_cnt_roi_two
    ,count(distinct case when (daily_quota_local is not null or total_quota_local is not null) and max_placement in (40) then a.campaign_id end) as limited_budget_cnt_roi_two
    ,count(distinct case when (daily_quota_local is null and total_quota_local is null) and max_placement in (40) then a.campaign_id end) as unlimited_budget_cnt_roi_two
    ,count(distinct case when ifnull(daily_quota_local,0) > 0 and max_placement in (40) then a.campaign_id end) as daily_budget_campaign_cnt_roi_two
    ,count(distinct case when ifnull(total_quota_local,0) > 0 and max_placement in (40) then a.campaign_id end) as total_budget_campaign_cnt_roi_two
from
(   
    select 
        campaign_id
        ,shop_id
        ,max(placement) as max_placement
        ,count(distinct ads_id) as ads_cnt
        ,grass_region
    from ads_advertise_mkt
    where (is_ads_active = 1 or has_performance = 1)
    group by campaign_id,shop_id,grass_region
)a
left join 
(
    select 
        campaign_id
        ,hit_daily_budget
        ,daily_quota_local
        ,daily_deduction
        ,total_quota_local
    from mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live
    where grass_region = upper('${region}')
        and   grass_date = '${grass_date}'
        and tz_type = 'local'    
)b
on a.campaign_id = b.campaign_id
left join 
(   
    select exchange_rate,grass_region
    from
    mp_order.dim_exchange_rate__reg_s0_live
    where grass_region = upper('${region}')
        and   grass_date = '${grass_date}'
)c 
on a.grass_region = c.grass_region
group by shop_id;

create or replace temporary view ads_performance as 
select 
    shop_id,
    sum(impression_cnt) as ads_imp_cnt,
    sum(click_cnt) as ads_click_cnt,
    sum(order_cnt) as ads_direct_order_cnt,
    sum(broad_order_cnt) as ads_broad_order_cnt,
    sum(ads_gmv_usd) as ads_direct_gmv_usd,
    sum(broad_order_gmv_amt_usd) as ads_broad_gmv_usd,
    sum(ads_expenditure_amt_usd) as ads_revenue_usd,
    count(distinct case when ads_expenditure_amt_usd > 0 then ads_id end) as have_expenditure_ads_cnt,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) then ads_id end) as active_ads_cnt,

    sum(case when placement in (0,4,1000, 1200) then impression_cnt else 0 end) as ads_imp_cnt_search,
    sum(case when placement in (0,4,1000, 1200) then click_cnt else 0 end) as ads_click_cnt_search,
    sum(case when placement in (0,4,1000, 1200) then order_cnt else 0 end) as ads_direct_order_cnt_search,
    sum(case when placement in (0,4,1000, 1200) then broad_order_cnt else 0 end) as ads_broad_order_cnt_search,
    sum(case when placement in (0,4,1000, 1200) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_search,
    sum(case when placement in (0,4,1000, 1200) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_search,
    sum(case when placement in (0,4,1000, 1200) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_search,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (0,4,1000, 1200) then ads_id end) as have_expenditure_ads_cnt_search,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (0,4,1000, 1200) then ads_id end) as active_ads_cnt_search,

    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then impression_cnt else 0 end) as ads_imp_cnt_discovery,
    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then click_cnt else 0 end) as ads_click_cnt_discovery,
    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then order_cnt else 0 end) as ads_direct_order_cnt_discovery,
    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then broad_order_cnt else 0 end) as ads_broad_order_cnt_discovery,
    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_discovery,
    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_discovery,
    sum(case when placement in (2,5,802,805,1002,1005,1202,1205) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_discovery,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id end) as have_expenditure_ads_cnt_discovery,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id end) as active_ads_cnt_discovery,

    sum(case when placement in (3) then impression_cnt else 0 end) as ads_imp_cnt_shop,
    sum(case when placement in (3) then click_cnt else 0 end) as ads_click_cnt_shop,
    sum(case when placement in (3) then order_cnt else 0 end) as ads_direct_order_cnt_shop,
    sum(case when placement in (3) then broad_order_cnt else 0 end) as ads_broad_order_cnt_shop,
    sum(case when placement in (3) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_shop,
    sum(case when placement in (3) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_shop,
    sum(case when placement in (3) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_shop,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (3) then ads_id end) as have_expenditure_ads_cnt_shop,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (3) then ads_id end) as active_ads_cnt_shop,

    sum(case when placement = 0 then impression_cnt else 0 end) as ads_imp_cnt_search_manual,
    sum(case when placement = 0 then click_cnt else 0 end) as ads_click_cnt_search_manual,
    sum(case when placement = 0 then order_cnt else 0 end) as ads_direct_order_cnt_search_manual,
    sum(case when placement = 0 then broad_order_cnt else 0 end) as ads_broad_order_cnt_search_manual,
    sum(case when placement = 0 then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_search_manual,
    sum(case when placement = 0 then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_search_manual,
    sum(case when placement = 0 then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_search_manual,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 0 then ads_id end) as have_expenditure_ads_cnt_search_manual,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement = 0 then ads_id end) as active_ads_cnt_search_manual,

    sum(case when placement = 4 then impression_cnt else 0 end) as ads_imp_cnt_search_simple,
    sum(case when placement = 4 then click_cnt else 0 end) as ads_click_cnt_search_simple,
    sum(case when placement = 4 then order_cnt else 0 end) as ads_direct_order_cnt_search_simple,
    sum(case when placement = 4 then broad_order_cnt else 0 end) as ads_broad_order_cnt_search_simple,
    sum(case when placement = 4 then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_search_simple,
    sum(case when placement = 4 then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_search_simple,
    sum(case when placement = 4 then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_search_simple,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 4 then ads_id end) as have_expenditure_ads_cnt_search_simple,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement = 4 then ads_id end) as active_ads_cnt_search_simple,

    sum(case when placement in (1000,1002,1005) then impression_cnt else 0 end) as ads_imp_cnt_itemboost,
    sum(case when placement in (1000,1002,1005) then click_cnt else 0 end) as ads_click_cnt_itemboost,
    sum(case when placement in (1000,1002,1005) then order_cnt else 0 end) as ads_direct_order_cnt_itemboost,
    sum(case when placement in (1000,1002,1005) then broad_order_cnt else 0 end) as ads_broad_order_cnt_itemboost,
    sum(case when placement in (1000,1002,1005) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_itemboost,
    sum(case when placement in (1000,1002,1005) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_itemboost,
    sum(case when placement in (1000,1002,1005) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_itemboost,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (1000,1002,1005) then ads_id end) as have_expenditure_ads_cnt_itemboost,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (1000,1002,1005) then ads_id end) as active_ads_cnt_itemboost,

    sum(case when placement in (1200,1202,1205) then impression_cnt else 0 end) as ads_imp_cnt_autoboost,
    sum(case when placement in (1200,1202,1205) then click_cnt else 0 end) as ads_click_cnt_autoboost,
    sum(case when placement in (1200,1202,1205) then order_cnt else 0 end) as ads_direct_order_cnt_autoboost,
    sum(case when placement in (1200,1202,1205) then broad_order_cnt else 0 end) as ads_broad_order_cnt_autoboost,
    sum(case when placement in (1200,1202,1205) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_autoboost,
    sum(case when placement in (1200,1202,1205) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_autoboost,
    sum(case when placement in (1200,1202,1205) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_autoboost,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (1200,1202,1205) then ads_id end) as have_expenditure_ads_cnt_autoboost,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (1200,1202,1205) then ads_id end) as active_ads_cnt_autoboost,

    sum(case when placement = 2 then impression_cnt else 0 end) as ads_imp_cnt_dd_manual,
    sum(case when placement = 2 then click_cnt else 0 end) as ads_click_cnt_dd_manual,
    sum(case when placement = 2 then order_cnt else 0 end) as ads_direct_order_cnt_dd_manual,
    sum(case when placement = 2 then broad_order_cnt else 0 end) as ads_broad_order_cnt_dd_manual,
    sum(case when placement = 2 then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_dd_manual,
    sum(case when placement = 2 then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_dd_manual,
    sum(case when placement = 2 then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_dd_manual,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 2 then ads_id end) as have_expenditure_ads_cnt_dd_manual,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement = 2 then ads_id end) as active_ads_cnt_dd_manual,

    sum(case when placement in (802) then impression_cnt else 0 end) as ads_imp_cnt_dd_simple,
    sum(case when placement in (802) then click_cnt else 0 end) as ads_click_cnt_dd_simple,
    sum(case when placement in (802) then order_cnt else 0 end) as ads_direct_order_cnt_dd_simple,
    sum(case when placement in (802) then broad_order_cnt else 0 end) as ads_broad_order_cnt_dd_simple,
    sum(case when placement in (802) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_dd_simple,
    sum(case when placement in (802) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_dd_simple,
    sum(case when placement in (802) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_dd_simple,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (802) then ads_id end) as have_expenditure_ads_cnt_dd_simple,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (802) then ads_id end) as active_ads_cnt_dd_simple,

    sum(case when placement = 5 then impression_cnt else 0 end) as ads_imp_cnt_ymal_manual,
    sum(case when placement = 5 then click_cnt else 0 end) as ads_click_cnt_ymal_manual,
    sum(case when placement = 5 then order_cnt else 0 end) as ads_direct_order_cnt_ymal_manual,
    sum(case when placement = 5 then broad_order_cnt else 0 end) as ads_broad_order_cnt_ymal_manual,
    sum(case when placement = 5 then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_ymal_manual,
    sum(case when placement = 5 then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_ymal_manual,
    sum(case when placement = 5 then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_ymal_manual,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 5 then ads_id end) as have_expenditure_ads_cnt_ymal_manual,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement = 5 then ads_id end) as active_ads_cnt_ymal_manual,

    sum(case when placement in (805) then impression_cnt else 0 end) as ads_imp_cnt_ymal_simple,
    sum(case when placement in (805) then click_cnt else 0 end) as ads_click_cnt_ymal_simple,
    sum(case when placement in (805) then order_cnt else 0 end) as ads_direct_order_cnt_ymal_simple,
    sum(case when placement in (805) then broad_order_cnt else 0 end) as ads_broad_order_cnt_ymal_simple,
    sum(case when placement in (805) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_ymal_simple,
    sum(case when placement in (805) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_ymal_simple,
    sum(case when placement in (805) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_ymal_simple,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (805) then ads_id end) as have_expenditure_ads_cnt_ymal_simple,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (805) then ads_id end) as active_ads_cnt_ymal_simple,

    sum(case when placement in (40) then impression_cnt else 0 end) as ads_imp_cnt_roi_two,
    sum(case when placement in (40) then click_cnt else 0 end) as ads_click_cnt_roi_two,
    sum(case when placement in (40) then order_cnt else 0 end) as ads_direct_order_cnt_roi_two,
    sum(case when placement in (40) then broad_order_cnt else 0 end) as ads_broad_order_cnt_roi_two,
    sum(case when placement in (40) then ads_gmv_usd else 0.0 end) as ads_direct_gmv_usd_roi_two,
    sum(case when placement in (40) then broad_order_gmv_amt_usd else 0.0 end) as ads_broad_gmv_usd_roi_two,
    sum(case when placement in (40) then ads_expenditure_amt_usd else 0.0 end) as ads_revenue_usd_roi_two,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (40) then ads_id end) as have_expenditure_ads_cnt_roi_two,
    count(distinct case when (is_ads_active = 1 or has_performance = 1) and placement in (40) then ads_id end) as active_ads_cnt_roi_two
from ads_advertise_mkt
group by shop_id;

cache table dim_advertise 
select 
    shop_id,
    item_id,
    placement,
    ads_id,
    ads_status,
    ads_create_datetime,
    campaign_end_datetime,
    is_ads_active,
    grass_date,
    grass_region
from 
    mp_paidads.dim_advertise__reg_s0_live
where 
    grass_region = upper('${region}')
    and grass_date = '${grass_date}'
    and tz_type = 'local';

create or replace temporary view ads_cnt as 
select 
    shop_id,
    count(distinct case when ads_status in (0,7) then ads_id else null end) as deleted_ads_cnt ,
    count(distinct case when ads_status = 1 then ads_id else null end) as ongoing_ads_cnt,
    count(distinct case when ads_status = 2 then ads_id else null end) as pause_ads_cnt ,
    count(distinct case when ads_status = 3 then ads_id else null end) as closed_ads_cnt , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}'  then ads_id else null end) as create_ads_cnt ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' then ads_id else null end) as end_ads_cnt ,

    count(distinct case when ads_status in (0,7) and placement in (0,4,1000, 1200) then ads_id else null end) as deleted_ads_cnt_search ,
    count(distinct case when ads_status = 1 and placement in (0,4,1000, 1200) then ads_id else null end) as ongoing_ads_cnt_search ,
    count(distinct case when ads_status = 2 and placement in (0,4,1000, 1200) then ads_id else null end) as pause_ads_cnt_search ,
    count(distinct case when ads_status = 3 and placement in (0,4,1000, 1200) then ads_id else null end) as closed_ads_cnt_search , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (0,4,1000, 1200) then ads_id else null end) as create_ads_cnt_search ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (0,4,1000, 1200) then ads_id else null end) as end_ads_cnt_search ,

    count(distinct case when ads_status in (0,7) and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as deleted_ads_cnt_discovery ,
    count(distinct case when ads_status = 1 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as ongoing_ads_cnt_discovery ,
    count(distinct case when ads_status = 2 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as pause_ads_cnt_discovery ,
    count(distinct case when ads_status = 3 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as closed_ads_cnt_discovery , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as create_ads_cnt_discovery ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as end_ads_cnt_discovery ,
    
    count(distinct case when ads_status in (0,7) and placement in (3) then ads_id else null end) as deleted_ads_cnt_shop ,
    count(distinct case when ads_status = 1 and placement in (3) then ads_id else null end) as ongoing_ads_cnt_shop ,
    count(distinct case when ads_status = 2 and placement in (3) then ads_id else null end) as pause_ads_cnt_shop ,
    count(distinct case when ads_status = 3 and placement in (3) then ads_id else null end) as closed_ads_cnt_shop , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (3) then ads_id else null end) as create_ads_cnt_shop ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (3) then ads_id else null end) as end_ads_cnt_shop ,
   
    count(distinct case when ads_status in (0,7) and placement = 0 then ads_id else null end) as deleted_ads_cnt_search_manual ,
    count(distinct case when ads_status = 1 and placement = 0 then ads_id else null end) as ongoing_ads_cnt_search_manual ,
    count(distinct case when ads_status = 2 and placement = 0 then ads_id else null end) as pause_ads_cnt_search_manual ,
    count(distinct case when ads_status = 3 and placement = 0 then ads_id else null end) as closed_ads_cnt_search_manual , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 0 then ads_id else null end) as create_ads_cnt_search_manual ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 0 then ads_id else null end) as end_ads_cnt_search_manual ,
   
    count(distinct case when ads_status in (0,7) and placement = 4 then ads_id else null end) as deleted_ads_cnt_search_simple ,
    count(distinct case when ads_status = 1 and placement = 4 then ads_id else null end) as ongoing_ads_cnt_search_simple ,
    count(distinct case when ads_status = 2 and placement = 4 then ads_id else null end) as pause_ads_cnt_search_simple ,
    count(distinct case when ads_status = 3 and placement = 4 then ads_id else null end) as closed_ads_cnt_search_simple , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 4 then ads_id else null end) as create_ads_cnt_search_simple ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 4 then ads_id else null end) as end_ads_cnt_search_simple ,
    
    count(distinct case when ads_status in (0,7) and placement in (1000,1002,1005) then ads_id else null end) as deleted_ads_cnt_itemboost ,
    count(distinct case when ads_status = 1 and placement in (1000,1002,1005) then ads_id else null end) as ongoing_ads_cnt_itemboost ,
    count(distinct case when ads_status = 2 and placement in (1000,1002,1005) then ads_id else null end) as pause_ads_cnt_itemboost ,
    count(distinct case when ads_status = 3 and placement in (1000,1002,1005) then ads_id else null end) as closed_ads_cnt_itemboost , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (1000,1002,1005) then ads_id else null end) as create_ads_cnt_itemboost ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (1000,1002,1005) then ads_id else null end) as end_ads_cnt_itemboost ,
    
    count(distinct case when ads_status in (0,7) and placement in (1200,1202,1205) then ads_id else null end) as deleted_ads_cnt_autoboost ,
    count(distinct case when ads_status = 1 and placement in (1200,1202,1205) then ads_id else null end) as ongoing_ads_cnt_autoboost ,
    count(distinct case when ads_status = 2 and placement in (1200,1202,1205) then ads_id else null end) as pause_ads_cnt_autoboost ,
    count(distinct case when ads_status = 3 and placement in (1200,1202,1205) then ads_id else null end) as closed_ads_cnt_autoboost , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (1200,1202,1205) then ads_id else null end) as create_ads_cnt_autoboost ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (1200,1202,1205) then ads_id else null end) as end_ads_cnt_autoboost ,
   
    count(distinct case when ads_status in (0,7) and placement = 2 then ads_id else null end) as deleted_ads_cnt_dd_manual ,
    count(distinct case when ads_status = 1 and placement = 2 then ads_id else null end) as ongoing_ads_cnt_dd_manual ,
    count(distinct case when ads_status = 2 and placement = 2 then ads_id else null end) as pause_ads_cnt_dd_manual ,
    count(distinct case when ads_status = 3 and placement = 2 then ads_id else null end) as closed_ads_cnt_dd_manual , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 2 then ads_id else null end) as create_ads_cnt_dd_manual ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 2 then ads_id else null end) as end_ads_cnt_dd_manual ,
   
    count(distinct case when ads_status in (0,7) and placement in (802) then ads_id else null end) as deleted_ads_cnt_dd_simple ,
    count(distinct case when ads_status = 1 and placement in (802) then ads_id else null end) as ongoing_ads_cnt_dd_simple ,
    count(distinct case when ads_status = 2 and placement in (802) then ads_id else null end) as pause_ads_cnt_dd_simple ,
    count(distinct case when ads_status = 3 and placement in (802) then ads_id else null end) as closed_ads_cnt_dd_simple , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (802) then ads_id else null end) as create_ads_cnt_dd_simple ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (802) then ads_id else null end) as end_ads_cnt_dd_simple ,
   
    count(distinct case when ads_status in (0,7) and placement = 5 then ads_id else null end) as deleted_ads_cnt_ymal_manual ,
    count(distinct case when ads_status = 1 and placement = 5 then ads_id else null end) as ongoing_ads_cnt_ymal_manual ,
    count(distinct case when ads_status = 2 and placement = 5 then ads_id else null end) as pause_ads_cnt_ymal_manual ,
    count(distinct case when ads_status = 3 and placement = 5 then ads_id else null end) as closed_ads_cnt_ymal_manual , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 5 then ads_id else null end) as create_ads_cnt_ymal_manual ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 5 then ads_id else null end) as end_ads_cnt_ymal_manual ,
    
    count(distinct case when ads_status in (0,7) and placement in (805) then ads_id else null end) as deleted_ads_cnt_ymal_simple ,
    count(distinct case when ads_status = 1 and placement in (805) then ads_id else null end) as ongoing_ads_cnt_ymal_simple ,
    count(distinct case when ads_status = 2 and placement in (805) then ads_id else null end) as pause_ads_cnt_ymal_simple ,
    count(distinct case when ads_status = 3 and placement in (805) then ads_id else null end) as closed_ads_cnt_ymal_simple , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (805) then ads_id else null end) as create_ads_cnt_ymal_simple ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (805) then ads_id else null end) as end_ads_cnt_ymal_simple,

    count(distinct case when ads_status in (0,7) and placement in (40) then ads_id else null end) as deleted_ads_cnt_roi_two ,
    count(distinct case when ads_status = 1 and placement in (40) then ads_id else null end) as ongoing_ads_cnt_roi_two ,
    count(distinct case when ads_status = 2 and placement in (40) then ads_id else null end) as pause_ads_cnt_roi_two ,
    count(distinct case when ads_status = 3 and placement in (40) then ads_id else null end) as closed_ads_cnt_roi_two , 
    count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (40) then ads_id else null end) as create_ads_cnt_roi_two ,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (40) then ads_id else null end) as end_ads_cnt_roi_two

from 
    dim_advertise
group by shop_id
;

create or replace temporary view ads_cnt_7d as 
select 
    shop_id,
    count(distinct case when ads_status in (0,7) then ads_id else null end) as deleted_ads_cnt_7d,
    count(distinct case when ads_status = 1 then ads_id else null end) as ongoing_ads_cnt_7d,
    count(distinct case when ads_status = 2 then ads_id else null end) as pause_ads_cnt_7d,
    count(distinct case when ads_status = 3 then ads_id else null end) as closed_ads_cnt_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' then ads_id else null end) as create_ads_cnt_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' then ads_id else null end) as end_ads_cnt_7d,
    
    count(distinct case when ads_status in (0,7) and placement in (0,4,1000, 1200) then ads_id else null end) as deleted_ads_cnt_search_7d,
    count(distinct case when ads_status = 1 and placement in (0,4,1000, 1200) then ads_id else null end) as ongoing_ads_cnt_search_7d,
    count(distinct case when ads_status = 2 and placement in (0,4,1000, 1200) then ads_id else null end) as pause_ads_cnt_search_7d,
    count(distinct case when ads_status = 3 and placement in (0,4,1000, 1200) then ads_id else null end) as closed_ads_cnt_search_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (0,4,1000, 1200) then ads_id else null end) as create_ads_cnt_search_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (0,4,1000, 1200) then ads_id else null end) as end_ads_cnt_search_7d,
    
    count(distinct case when ads_status in (0,7) and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as deleted_ads_cnt_discovery_7d,
    count(distinct case when ads_status = 1 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as ongoing_ads_cnt_discovery_7d,
    count(distinct case when ads_status = 2 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as pause_ads_cnt_discovery_7d,
    count(distinct case when ads_status = 3 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as closed_ads_cnt_discovery_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as create_ads_cnt_discovery_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id else null end) as end_ads_cnt_discovery_7d,
    
    count(distinct case when ads_status in (0,7) and placement in (3) then ads_id else null end) as deleted_ads_cnt_shop_7d,
    count(distinct case when ads_status = 1 and placement in (3) then ads_id else null end) as ongoing_ads_cnt_shop_7d,
    count(distinct case when ads_status = 2 and placement in (3) then ads_id else null end) as pause_ads_cnt_shop_7d,
    count(distinct case when ads_status = 3 and placement in (3) then ads_id else null end) as closed_ads_cnt_shop_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (3) then ads_id else null end) as create_ads_cnt_shop_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (3) then ads_id else null end) as end_ads_cnt_shop_7d,
    
    count(distinct case when ads_status in (0,7) and placement = 0 then ads_id else null end) as deleted_ads_cnt_search_manual_7d,
    count(distinct case when ads_status = 1 and placement = 0 then ads_id else null end) as ongoing_ads_cnt_search_manual_7d,
    count(distinct case when ads_status = 2 and placement = 0 then ads_id else null end) as pause_ads_cnt_search_manual_7d,
    count(distinct case when ads_status = 3 and placement = 0 then ads_id else null end) as closed_ads_cnt_search_manual_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement = 0 then ads_id else null end) as create_ads_cnt_search_manual_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement = 0 then ads_id else null end) as end_ads_cnt_search_manual_7d,
   
    count(distinct case when ads_status in (0,7) and placement = 4 then ads_id else null end) as deleted_ads_cnt_search_simple_7d,
    count(distinct case when ads_status = 1 and placement = 4 then ads_id else null end) as ongoing_ads_cnt_search_simple_7d,
    count(distinct case when ads_status = 2 and placement = 4 then ads_id else null end) as pause_ads_cnt_search_simple_7d,
    count(distinct case when ads_status = 3 and placement = 4 then ads_id else null end) as closed_ads_cnt_search_simple_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement = 4 then ads_id else null end) as create_ads_cnt_search_simple_7d,
    count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 4 then ads_id else null end) as end_ads_cnt_search_simple_7d,
   
    count(distinct case when ads_status in (0,7) and placement in (1000,1002,1005) then ads_id else null end) as deleted_ads_cnt_itemboost_7d,
    count(distinct case when ads_status = 1 and placement in (1000,1002,1005) then ads_id else null end) as ongoing_ads_cnt_itemboost_7d,
    count(distinct case when ads_status = 2 and placement in (1000,1002,1005) then ads_id else null end) as pause_ads_cnt_itemboost_7d,
    count(distinct case when ads_status = 3 and placement in (1000,1002,1005) then ads_id else null end) as closed_ads_cnt_itemboost_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (1000,1002,1005) then ads_id else null end) as create_ads_cnt_itemboost_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (1000,1002,1005) then ads_id else null end) as end_ads_cnt_itemboost_7d,
    
    count(distinct case when ads_status in (0,7) and placement in (1200,1202,1205) then ads_id else null end) as deleted_ads_cnt_autoboost_7d,
    count(distinct case when ads_status = 1 and placement in (1200,1202,1205) then ads_id else null end) as ongoing_ads_cnt_autoboost_7d,
    count(distinct case when ads_status = 2 and placement in (1200,1202,1205) then ads_id else null end) as pause_ads_cnt_autoboost_7d,
    count(distinct case when ads_status = 3 and placement in (1200,1202,1205) then ads_id else null end) as closed_ads_cnt_autoboost_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (1200,1202,1205) then ads_id else null end) as create_ads_cnt_autoboost_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (1200,1202,1205) then ads_id else null end) as end_ads_cnt_autoboost_7d,
   
    count(distinct case when ads_status in (0,7) and placement = 2 then ads_id else null end) as deleted_ads_cnt_dd_manual_7d,
    count(distinct case when ads_status = 1 and placement = 2 then ads_id else null end) as ongoing_ads_cnt_dd_manual_7d,
    count(distinct case when ads_status = 2 and placement = 2 then ads_id else null end) as pause_ads_cnt_dd_manual_7d,
    count(distinct case when ads_status = 3 and placement = 2 then ads_id else null end) as closed_ads_cnt_dd_manual_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement = 2 then ads_id else null end) as create_ads_cnt_dd_manual_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement = 2 then ads_id else null end) as end_ads_cnt_dd_manual_7d,
   
    count(distinct case when ads_status in (0,7) and placement in (802) then ads_id else null end) as deleted_ads_cnt_dd_simple_7d,
    count(distinct case when ads_status = 1 and placement in (802) then ads_id else null end) as ongoing_ads_cnt_dd_simple_7d,
    count(distinct case when ads_status = 2 and placement in (802) then ads_id else null end) as pause_ads_cnt_dd_simple_7d,
    count(distinct case when ads_status = 3 and placement in (802) then ads_id else null end) as closed_ads_cnt_dd_simple_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (802) then ads_id else null end) as create_ads_cnt_dd_simple_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (802) then ads_id else null end) as end_ads_cnt_dd_simple_7d,
   
    count(distinct case when ads_status in (0,7) and placement = 5 then ads_id else null end) as deleted_ads_cnt_ymal_manual_7d,
    count(distinct case when ads_status = 1 and placement = 5 then ads_id else null end) as ongoing_ads_cnt_ymal_manual_7d,
    count(distinct case when ads_status = 2 and placement = 5 then ads_id else null end) as pause_ads_cnt_ymal_manual_7d,
    count(distinct case when ads_status = 3 and placement = 5 then ads_id else null end) as closed_ads_cnt_ymal_manual_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement = 5 then ads_id else null end) as create_ads_cnt_ymal_manual_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement = 5 then ads_id else null end) as end_ads_cnt_ymal_manual_7d,
   
    count(distinct case when ads_status in (0,7) and placement in (805) then ads_id else null end) as deleted_ads_cnt_ymal_simple_7d,
    count(distinct case when ads_status = 1 and placement in (805) then ads_id else null end) as ongoing_ads_cnt_ymal_simple_7d,
    count(distinct case when ads_status = 2 and placement in (805) then ads_id else null end) as pause_ads_cnt_ymal_simple_7d,
    count(distinct case when ads_status = 3 and placement in (805) then ads_id else null end) as closed_ads_cnt_ymal_simple_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (805) then ads_id else null end) as create_ads_cnt_ymal_simple_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (805) then ads_id else null end) as end_ads_cnt_ymal_simple_7d,

    count(distinct case when ads_status in (0,7) and placement in (40) then ads_id else null end) as deleted_ads_cnt_roi_two_7d,
    count(distinct case when ads_status = 1 and placement in (40) then ads_id else null end) as ongoing_ads_cnt_roi_two_7d,
    count(distinct case when ads_status = 2 and placement in (40) then ads_id else null end) as pause_ads_cnt_roi_two_7d,
    count(distinct case when ads_status = 3 and placement in (40) then ads_id else null end) as closed_ads_cnt_roi_two_7d, 
    count(distinct case when date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}' and placement in (40) then ads_id else null end) as create_ads_cnt_roi_two_7d,
    count(distinct case when date(campaign_end_datetime) >= date_sub('${grass_date}',7) and date(campaign_end_datetime) < '${grass_date}' and placement in (40) then ads_id else null end) as end_ads_cnt_roi_two_7d
from 
    mp_paidads.dim_advertise__reg_s0_live
where 
    grass_region = upper('${region}')
    and   grass_date >= date_sub('${grass_date}',7)
    and   grass_date <  '${grass_date}'
    and date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}'
group by shop_id
;

create or replace temporary view has_expenditure_ads_cnt_7d as 
select 
    shop_id,
    count(distinct case when ads_expenditure_amt_usd > 0 then ads_id end) as have_expenditure_ads_cnt_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (0,4,1000,1200) then ads_id end) as have_expenditure_ads_cnt_search_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (2,5,802,805,1002,1005,1202,1205) then ads_id end) as have_expenditure_ads_cnt_discovery_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 3 then ads_id end) as have_expenditure_ads_cnt_shop_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 0 then ads_id end) as have_expenditure_ads_cnt_search_manual_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 4 then ads_id end) as have_expenditure_ads_cnt_search_simple_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 2 then ads_id end) as have_expenditure_ads_cnt_dd_manual_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 802 then ads_id end) as have_expenditure_ads_cnt_dd_simple_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 5 then ads_id end) as have_expenditure_ads_cnt_ymal_manual_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement = 805 then ads_id end) as have_expenditure_ads_cnt_ymal_simple_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (1000,1002,1005) then ads_id end) as have_expenditure_ads_cnt_itemboost_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (1200,1202,1205) then ads_id end) as have_expenditure_ads_cnt_autoboost_7d,
    count(distinct case when ads_expenditure_amt_usd > 0 and placement in (40) then ads_id end) as have_expenditure_ads_cnt_roi_two_7d
from  
    mp_paidads.ads_advertise_mkt_1d__reg_s0_live
where 
    grass_region = upper('${region}')
    and   grass_date >= date_sub('${grass_date}',7)
    and   grass_date <  '${grass_date}'
    and date(ads_create_datetime) >= date_sub('${grass_date}',7) and date(ads_create_datetime) < '${grass_date}'
group by shop_id
;

--
cache table tracking_item_performance as 
select
    shop_id
    ,item_id
    ,item_imp_cnt
    ,org_item_imp_cnt
    ,item_click_cnt
    ,org_item_click_cnt
    ,org_direct_order_cnt
    ,org_broad_order_cnt
    ,org_direct_gmv_usd
    ,org_broad_gmv_usd
    ,item_direct_order_cnt
    ,item_broad_order_cnt
    ,item_direct_gmv_usd
    ,item_broad_gmv_usd
from mp_paidads.dws_item_performance_1d__reg_s0_live
where tz_type = 'local'
and grass_date = '${grass_date}'
and grass_region = upper('${region}');

cache table ads_item 
select 
        item_id
        ,1 as is_ads
    from dim_advertise
    where is_ads_active = 1
    group by item_id;

--shop platform order
create or replace temporary view item_gmv as
select  
    shop_id
    ,a.item_id as item_id
    ,order_cnt
    ,coalesce(is_ads,0) as is_ads
    ,platform_gmv_usd
    ,first_value(a.item_id) over(partition by shop_id order by order_cnt desc) as top_selling_item_id
from
(
    select
        shop_id
        ,item_id
        ,sum(placed_order_cnt_1d) AS order_cnt
        ,sum(gmv_usd_1d) as platform_gmv_usd
FROM   mp_order.dws_item_gmv_1d__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = '${grass_date}'
    and tz_type = 'local'
    group by 1,2
)a
left join ads_item b
on a.item_id = b.item_id
;

create or replace temporary view platform_order as
select 
    shop_id
    ,top_selling_item_id
    ,sum(case when is_ads = 1 then order_cnt else 0 end) as ads_platform_order_cnt
    ,sum(case when is_ads = 0 then order_cnt else 0 end) as org_platform_order_cnt
    ,sum(platform_gmv_usd) as platform_gmv_usd
    ,sum(order_cnt) as platform_order_cnt
from item_gmv
group by 1,2
;

create or replace temporary view org_performance as 
select  
        shop_id
        ,sum(item_imp_cnt) as shop_item_imp_cnt
        ,sum(org_item_imp_cnt) as org_item_imp_cnt
        ,sum(item_click_cnt) as shop_item_click_cnt
        ,sum(org_item_click_cnt) as org_item_click_cnt
        ,sum(org_direct_order_cnt) as org_direct_order_cnt
        ,sum(org_broad_order_cnt) as org_broad_order_cnt
        ,sum(org_direct_gmv_usd) as org_direct_gmv_usd
        ,sum(org_broad_gmv_usd) as org_broad_gmv_usd
from tracking_item_performance
group by shop_id
;

create or replace temporary view ads_item_cnt as 
select 
    a.shop_id as shop_id
    ,have_ads_items_cnt
    ,newly_create_ads_items_cnt
    ,ongoing_ads_items_cnt
    ,closed_ads_items_cnt
    ,end_campaign_items_cnt
    ,have_expenditure_items_cnt
    ,have_ads_order_items_cnt
    ,have_ads_items_cnt_search
    ,newly_create_ads_items_cnt_search
    ,ongoing_ads_items_cnt_search
    ,closed_ads_items_cnt_search
    ,end_campaign_items_cnt_search
    ,have_expenditure_items_cnt_search
    ,have_ads_order_items_cnt_search
    ,have_ads_items_cnt_discovery
    ,newly_create_ads_items_cnt_discovery
    ,ongoing_ads_items_cnt_discovery
    ,closed_ads_items_cnt_discovery
    ,end_campaign_items_cnt_discovery
    ,have_expenditure_items_cnt_discovery
    ,have_ads_order_items_cnt_discovery
    ,have_ads_items_cnt_shop
    ,newly_create_ads_items_cnt_shop
    ,ongoing_ads_items_cnt_shop
    ,closed_ads_items_cnt_shop
    ,end_campaign_items_cnt_shop
    ,have_expenditure_items_cnt_shop
    ,have_ads_order_items_cnt_shop
    ,have_ads_items_cnt_search_manual
    ,newly_create_ads_items_cnt_search_manual
    ,ongoing_ads_items_cnt_search_manual
    ,closed_ads_items_cnt_search_manual
    ,end_campaign_items_cnt_search_manual
    ,have_expenditure_items_cnt_search_manual
    ,have_ads_order_items_cnt_search_manual
    ,have_ads_items_cnt_search_simple
    ,newly_create_ads_items_cnt_search_simple
    ,ongoing_ads_items_cnt_search_simple
    ,closed_ads_items_cnt_search_simple
    ,end_campaign_items_cnt_search_simple
    ,have_expenditure_items_cnt_search_simple
    ,have_ads_order_items_cnt_search_simple
    ,have_ads_items_cnt_dd_manual
    ,newly_create_ads_items_cnt_dd_manual
    ,ongoing_ads_items_cnt_dd_manual
    ,closed_ads_items_cnt_dd_manual
    ,end_campaign_items_cnt_dd_manual
    ,have_expenditure_items_cnt_dd_manual
    ,have_ads_order_items_cnt_dd_manual
    ,have_ads_items_cnt_dd_simple
    ,newly_create_ads_items_cnt_dd_simple
    ,ongoing_ads_items_cnt_dd_simple
    ,closed_ads_items_cnt_dd_simple
    ,end_campaign_items_cnt_dd_simple
    ,have_expenditure_items_cnt_dd_simple
    ,have_ads_order_items_cnt_dd_simple
    ,have_ads_items_cnt_ymal_manual
    ,newly_create_ads_items_cnt_ymal_manual
    ,ongoing_ads_items_cnt_ymal_manual
    ,closed_ads_items_cnt_ymal_manual
    ,end_campaign_items_cnt_ymal_manual
    ,have_expenditure_items_cnt_ymal_manual
    ,have_ads_order_items_cnt_ymal_manual
    ,have_ads_items_cnt_ymal_simple
    ,newly_create_ads_items_cnt_ymal_simple
    ,ongoing_ads_items_cnt_ymal_simple
    ,closed_ads_items_cnt_ymal_simple
    ,end_campaign_items_cnt_ymal_simple
    ,have_expenditure_items_cnt_ymal_simple
    ,have_ads_order_items_cnt_ymal_simple
    ,have_ads_items_cnt_itemboost
    ,newly_create_ads_items_cnt_itemboost
    ,ongoing_ads_items_cnt_itemboost
    ,closed_ads_items_cnt_itemboost
    ,end_campaign_items_cnt_itemboost
    ,have_expenditure_items_cnt_itemboost
    ,have_ads_order_items_cnt_itemboost
    ,have_ads_items_cnt_autoboost
    ,newly_create_ads_items_cnt_autoboost
    ,ongoing_ads_items_cnt_autoboost
    ,closed_ads_items_cnt_autoboost
    ,end_campaign_items_cnt_autoboost
    ,have_expenditure_items_cnt_autoboost
    ,have_ads_order_items_cnt_autoboost
    ,have_expenditure_items_cnt_roi_two
    ,have_ads_order_items_cnt_roi_two
    ,have_ads_items_cnt_roi_two
    ,newly_create_ads_items_cnt_roi_two
    ,ongoing_ads_items_cnt_roi_two
    ,closed_ads_items_cnt_roi_two
    ,end_campaign_items_cnt_roi_two
from
(
    select 
        shop_id
        ,count(distinct case when is_ads_active = 1 then item_id else null end) as have_ads_items_cnt
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' then item_id end) as newly_create_ads_items_cnt
        ,count(distinct case when ads_status = 1 then item_id else null end) as ongoing_ads_items_cnt
        ,count(distinct case when ads_status = 3 then item_id else null end) as closed_ads_items_cnt
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' then item_id else null end) as end_campaign_items_cnt

        ,count(distinct case when is_ads_active = 1 and placement in (0,4,1000, 1200) then item_id else null end) as have_ads_items_cnt_search
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (0,4,1000, 1200) then item_id end) as newly_create_ads_items_cnt_search
        ,count(distinct case when ads_status = 1 and placement in (0,4,1000, 1200) then item_id else null end) as ongoing_ads_items_cnt_search
        ,count(distinct case when ads_status = 3 and placement in (0,4,1000, 1200) then item_id else null end) as closed_ads_items_cnt_search
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (0,4,1000, 1200) then item_id else null end) as end_campaign_items_cnt_search

        ,count(distinct case when is_ads_active = 1 and placement in (2,5,802,805,1002,1005,1202,1205) then item_id else null end) as have_ads_items_cnt_discovery
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (2,5,802,805,1002,1005,1202,1205) then item_id end) as newly_create_ads_items_cnt_discovery
        ,count(distinct case when ads_status = 1 and placement in (2,5,802,805,1002,1005,1202,1205) then item_id else null end) as ongoing_ads_items_cnt_discovery
        ,count(distinct case when ads_status = 3 and placement in (2,5,802,805,1002,1005,1202,1205) then item_id else null end) as closed_ads_items_cnt_discovery
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (2,5,802,805,1002,1005,1202,1205) then item_id else null end) as end_campaign_items_cnt_discovery

        ,count(distinct case when is_ads_active = 1 and placement = 3 then item_id else null end) as have_ads_items_cnt_shop
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 3 then item_id end) as newly_create_ads_items_cnt_shop
        ,count(distinct case when ads_status = 1 and placement = 3 then item_id else null end) as ongoing_ads_items_cnt_shop
        ,count(distinct case when ads_status = 3 and placement = 3 then item_id else null end) as closed_ads_items_cnt_shop
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 3 then item_id else null end) as end_campaign_items_cnt_shop

        ,count(distinct case when is_ads_active = 1 and placement = 0 then item_id else null end) as have_ads_items_cnt_search_manual
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 0 then item_id end) as newly_create_ads_items_cnt_search_manual
        ,count(distinct case when ads_status = 1 and placement = 0 then item_id else null end) as ongoing_ads_items_cnt_search_manual
        ,count(distinct case when ads_status = 3 and placement = 0 then item_id else null end) as closed_ads_items_cnt_search_manual
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 0 then item_id else null end) as end_campaign_items_cnt_search_manual

        ,count(distinct case when is_ads_active = 1 and placement = 4 then item_id else null end) as have_ads_items_cnt_search_simple
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 4 then item_id end) as newly_create_ads_items_cnt_search_simple
        ,count(distinct case when ads_status = 1 and placement = 4 then item_id else null end) as ongoing_ads_items_cnt_search_simple
        ,count(distinct case when ads_status = 3 and placement = 4 then item_id else null end) as closed_ads_items_cnt_search_simple
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 4 then item_id else null end) as end_campaign_items_cnt_search_simple

        ,count(distinct case when is_ads_active = 1 and placement = 2 then item_id else null end) as have_ads_items_cnt_dd_manual
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 2 then item_id end) as newly_create_ads_items_cnt_dd_manual
        ,count(distinct case when ads_status = 1 and placement = 2 then item_id else null end) as ongoing_ads_items_cnt_dd_manual
        ,count(distinct case when ads_status = 3 and placement = 2 then item_id else null end) as closed_ads_items_cnt_dd_manual
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 2 then item_id else null end) as end_campaign_items_cnt_dd_manual

        ,count(distinct case when is_ads_active = 1 and placement = 802 then item_id else null end) as have_ads_items_cnt_dd_simple
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 802 then item_id end) as newly_create_ads_items_cnt_dd_simple
        ,count(distinct case when ads_status = 1 and placement = 802 then item_id else null end) as ongoing_ads_items_cnt_dd_simple
        ,count(distinct case when ads_status = 3 and placement = 802 then item_id else null end) as closed_ads_items_cnt_dd_simple
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 802 then item_id else null end) as end_campaign_items_cnt_dd_simple

        ,count(distinct case when is_ads_active = 1 and placement = 5 then item_id else null end) as have_ads_items_cnt_ymal_manual
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 5 then item_id end) as newly_create_ads_items_cnt_ymal_manual
        ,count(distinct case when ads_status = 1 and placement = 5 then item_id else null end) as ongoing_ads_items_cnt_ymal_manual
        ,count(distinct case when ads_status = 3 and placement = 5 then item_id else null end) as closed_ads_items_cnt_ymal_manual
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 5 then item_id else null end) as end_campaign_items_cnt_ymal_manual

        ,count(distinct case when is_ads_active = 1 and placement = 805 then item_id else null end) as have_ads_items_cnt_ymal_simple
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement = 805 then item_id end) as newly_create_ads_items_cnt_ymal_simple
        ,count(distinct case when ads_status = 1 and placement = 805 then item_id else null end) as ongoing_ads_items_cnt_ymal_simple
        ,count(distinct case when ads_status = 3 and placement = 805 then item_id else null end) as closed_ads_items_cnt_ymal_simple
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement = 805 then item_id else null end) as end_campaign_items_cnt_ymal_simple

        ,count(distinct case when is_ads_active = 1 and placement in (1000,1002,1005) then item_id else null end) as have_ads_items_cnt_itemboost
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (1000,1002,1005) then item_id end) as newly_create_ads_items_cnt_itemboost
        ,count(distinct case when ads_status = 1 and placement in (1000,1002,1005) then item_id else null end) as ongoing_ads_items_cnt_itemboost
        ,count(distinct case when is_ads_active = 3 and placement in (1000,1002,1005) then item_id else null end) as closed_ads_items_cnt_itemboost
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (1000,1002,1005) then item_id else null end) as end_campaign_items_cnt_itemboost

        ,count(distinct case when is_ads_active = 1 and placement in (1200,1202,1205) then item_id else null end) as have_ads_items_cnt_autoboost
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (1200,1202,1205) then item_id end) as newly_create_ads_items_cnt_autoboost
        ,count(distinct case when ads_status = 1 and placement in (1200,1202,1205) then item_id else null end) as ongoing_ads_items_cnt_autoboost
        ,count(distinct case when ads_status = 3 and placement in (1200,1202,1205) then item_id else null end) as closed_ads_items_cnt_autoboost
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (1200,1202,1205) then item_id else null end) as end_campaign_items_cnt_autoboost

        ,count(distinct case when is_ads_active = 1 and placement in (40) then item_id else null end) as have_ads_items_cnt_roi_two
        ,count(distinct case when date(ads_create_datetime) = '${grass_date}' and placement in (40) then item_id end) as newly_create_ads_items_cnt_roi_two
        ,count(distinct case when ads_status = 1 and placement in (40) then item_id else null end) as ongoing_ads_items_cnt_roi_two
        ,count(distinct case when ads_status = 3 and placement in (40) then item_id else null end) as closed_ads_items_cnt_roi_two
        ,count(distinct case when date(campaign_end_datetime) = '${grass_date}' and placement in (40) then item_id else null end) as end_campaign_items_cnt_roi_two
from dim_advertise
group by shop_id
)a 
left join 
(
    select 
        shop_id
        ,count(distinct case when ads_expenditure_amt_usd > 0 then item_id else null end) as have_expenditure_items_cnt
        ,count(distinct case when order_cnt > 0 then item_id else null end) as have_ads_order_items_cnt

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement in (0,4,1000, 1200) then item_id else null end) as have_expenditure_items_cnt_search
        ,count(distinct case when order_cnt > 0 and placement in (0,4,1000, 1200) then item_id else null end) as have_ads_order_items_cnt_search

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement in (2,5,802,805,1002,1005,1202,1205) then item_id else null end) as have_expenditure_items_cnt_discovery
        ,count(distinct case when order_cnt > 0 and placement in (2,5,802,805,1002,1005,1202,1205) then item_id else null end) as have_ads_order_items_cnt_discovery

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 3 then item_id else null end) as have_expenditure_items_cnt_shop
        ,count(distinct case when order_cnt > 0 and placement = 3 then item_id else null end) as have_ads_order_items_cnt_shop

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 0 then item_id else null end) as have_expenditure_items_cnt_search_manual
        ,count(distinct case when order_cnt > 0 and placement = 0 then item_id else null end) as have_ads_order_items_cnt_search_manual

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 4 then item_id else null end) as have_expenditure_items_cnt_search_simple
        ,count(distinct case when order_cnt > 0 and placement = 4 then item_id else null end) as have_ads_order_items_cnt_search_simple

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 2 then item_id else null end) as have_expenditure_items_cnt_dd_manual
        ,count(distinct case when order_cnt > 0 and placement = 2 then item_id else null end) as have_ads_order_items_cnt_dd_manual

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 802 then item_id else null end) as have_expenditure_items_cnt_dd_simple
        ,count(distinct case when order_cnt > 0 and placement = 802 then item_id else null end) as have_ads_order_items_cnt_dd_simple

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 5 then item_id else null end) as have_expenditure_items_cnt_ymal_manual
        ,count(distinct case when order_cnt > 0 and placement = 5 then item_id else null end) as have_ads_order_items_cnt_ymal_manual

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement = 805 then item_id else null end) as have_expenditure_items_cnt_ymal_simple
        ,count(distinct case when order_cnt > 0 and placement = 805 then item_id else null end) as have_ads_order_items_cnt_ymal_simple

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement in (1000,1002,1005) then item_id else null end) as have_expenditure_items_cnt_itemboost
        ,count(distinct case when order_cnt > 0 and placement in (1000,1002,1005) then item_id else null end) as have_ads_order_items_cnt_itemboost

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement in (1200,1202,1205) then item_id else null end) as have_expenditure_items_cnt_autoboost
        ,count(distinct case when order_cnt > 0 and placement in (1200,1202,1205) then item_id else null end) as have_ads_order_items_cnt_autoboost

        ,count(distinct case when ads_expenditure_amt_usd > 0 and placement in (40) then item_id else null end) as have_expenditure_items_cnt_roi_two
        ,count(distinct case when order_cnt > 0 and placement in (40) then item_id else null end) as have_ads_order_items_cnt_roi_two
    from  ads_advertise_mkt
    group by shop_id
)b
on a.shop_id = b.shop_id
;

create or replace temporary view platform_order_nd as 
select 
    shop_id
    ,item_id
    ,placed_order_cnt_30d
from mp_order.dws_item_gmv_nd__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = '${grass_date}'
    and tz_type = 'local'
;

create or replace temporary view seller_item_cnt as 
select 
    a.shop_id as shop_id
    ,count(distinct a.item_id) as total_items_cnt
    ,count(distinct case when date(create_datetime) = '${grass_date}' then a.item_id end) as newly_items_cnt
    ,count(distinct case when item_imp_cnt>0 then a.item_id else null end) as have_imp_items_cnt
    ,count(distinct case when item_click_cnt>0 then a.item_id else null end) as have_click_items_cnt
    ,count(distinct case when item_direct_order_cnt>0 then a.item_id else null end) as have_order_items_cnt
    ,count(distinct case when placed_order_cnt_30d>0 then a.item_id else null end) as active_items_cnt
from
(
    select 
        shop_id
        ,item_id
        ,create_datetime
from mp_item.dim_item__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = '${grass_date}'
    and tz_type = 'local'
)a 
left join tracking_item_performance b
on a.shop_id = b.shop_id and a.item_id = b.item_id
left join platform_order_nd c
on a.shop_id = c.shop_id and a.item_id = c.item_id
group by a.shop_id
;

--ads item performance
create or replace temporary view ads_item_performance as
select 
    shop_id
    ,sum(case when is_ads = 1 then item_imp_cnt else 0 end) as ads_item_imp_cnt
    ,sum(case when is_ads = 1 then item_click_cnt else 0 end) as ads_item_click_cnt
    ,sum(case when is_ads = 1 then item_direct_order_cnt else 0 end) as ads_item_order_cnt
    ,sum(case when is_ads = 1 then item_direct_gmv_usd else 0 end) as ads_item_gmv_usd
from tracking_item_performance a
left join ads_item b
on a.item_id = b.item_id
group by shop_id
;

create or replace temporary view platform_gmv_td as 
select 
    shop_id
    ,sum(gmv_usd_td) as platform_gmv_usd_td
from mp_order.dws_item_gmv_td__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = '${grass_date}'
    and tz_type = 'local'
group by shop_id;

create or replace temporary view ads_performance_td as
select  
    shop_id
    ,sum(expenditure_amt_usd_td) as ads_revenue_usd_td
    ,sum(ads_gmv_amt_usd_td) as ads_gmv_usd_td
    ,sum(case when placement in (0,4) then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_search
    ,sum(case when placement in (0,4) then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_search
    ,sum(case when placement = 0 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_search_manual
    ,sum(case when placement = 0 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_search_manual
    ,sum(case when placement = 4 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_search_simple
    ,sum(case when placement = 4 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_search_simple
    ,sum(case when placement = 2 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_dd_manual
    ,sum(case when placement = 2 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_dd_manual
    ,sum(case when placement = 802 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_dd_simple
    ,sum(case when placement = 802 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_dd_simple
    ,sum(case when placement = 5 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_ymal_manual
    ,sum(case when placement = 5 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_ymal_manual
    ,sum(case when placement = 805 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_ymal_simple
    ,sum(case when placement = 805 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_ymal_simple
    ,sum(case when placement in (1000,1002,1005) then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_itemboost
    ,sum(case when placement in (1000,1002,1005) then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_itemboost
    ,sum(case when placement in (1200,1202,1205) then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_autoboost
    ,sum(case when placement in (1200,1202,1205) then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_autoboost
    ,sum(case when placement = 3 then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_shop
    ,sum(case when placement = 3 then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_shop
    ,sum(case when placement in (2,5,802,805) then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_discovery
    ,sum(case when placement in (2,5,802,805) then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_discovery
    ,sum(case when placement in (40) then expenditure_amt_usd_td else 0.0 end) as ads_revenue_usd_td_roi_two
    ,sum(case when placement in (40) then ads_gmv_amt_usd_td else 0.0 end) as ads_gmv_usd_td_roi_two
from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live 
where grass_region = upper('${region}')
and   grass_date = '${grass_date}'
and tz_type = 'local'
group by shop_id
;

insert overwrite table ads_advertiser_seller_all_metrics_1d__reg_s0_live partition (tz_type = 'local',grass_region,grass_date)
select 
    a.shop_id as shop_id
    ,seller_name
    ,seller_type
    ,cluster
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
    ,is_principal
    ,principal_type
    ,total_topup_amt
    ,total_topup_amt_usd
    ,seller_topup_amt
    ,seller_topup_amt_usd
    ,admin_manual_cb_topup_amt
    ,admin_manual_cb_topup_amt_usd
    ,free_credit_topup_amt
    ,free_credit_topup_amt_usd
    ,paid_credit_topup_amt
    ,paid_credit_topup_amt_usd
    ,voucher_free_credit_topup_amt
    ,voucher_free_credit_topup_amt_usd
    ,package_free_credit_topup_amt
    ,package_free_credit_topup_amt_usd
    ,admin_api_seller_mission_free_credit_topup_amt
    ,admin_api_seller_mission_free_credit_topup_amt_usd
    ,admin_manual_free_credit_topup_amt
    ,admin_manual_free_credit_topup_amt_usd
    ,admin_api_qss_free_credit_topup_amt
    ,admin_api_qss_free_credit_topup_amt_usd
    ,total_deduction_amt
    ,total_deduction_amt_usd
    ,free_credit_deduction_amt
    ,free_credit_deduction_amt_usd
    ,paid_credit_deduction_amt
    ,paid_credit_deduction_amt_usd
    ,voucher_free_credit_deduction_amt
    ,voucher_free_credit_deduction_amt_usd
    ,package_free_credit_deduction_amt
    ,package_free_credit_deduction_amt_usd
    ,seller_mission_free_credit_deduction_amt
    ,seller_mission_free_credit_deduction_amt_usd
    ,manual_free_credit_deduction_amt
    ,manual_free_credit_deduction_amt_usd
    ,srm_free_credit_deduction_amt
    ,srm_free_credit_deduction_amt_usd
    ,total_credit_expiry_amt
    ,total_credit_expiry_amt_usd
    ,free_credit_expiry_amt
    ,free_credit_expiry_amt_usd
    ,paid_credit_expiry_amt
    ,paid_credit_expiry_amt_usd
    ,voucher_free_credit_expiry_amt
    ,voucher_free_credit_expiry_amt_usd
    ,package_free_credit_expiry_amt
    ,package_free_credit_expiry_amt_usd
    ,seller_mission_free_credit_expiry_amt
    ,seller_mission_free_credit_expiry_amt_usd
    ,manual_free_credit_expiry_amt
    ,manual_free_credit_expiry_amt_usd
    ,srm_free_credit_expiry_amt
    ,srm_free_credit_expiry_amt_usd
    ,total_balance_amt
    ,total_balance_amt_usd
    ,free_credit_balance_amt
    ,free_credit_balance_amt_usd
    ,paid_credit_balance_amt
    ,paid_credit_balance_amt_usd
    ,voucher_free_balance_amt
    ,voucher_free_balance_amt_usd
    ,package_free_balance_amt
    ,package_free_balance_amt_usd
    ,manual_free_balance_amt
    ,manual_free_balance_amt_usd
    ,srm_free_balance_amt
    ,srm_free_balance_amt_usd
    ,deleted_campaign_cnt
    ,ongoing_campaign_cnt
    ,pause_campaign_cnt
    ,closed_campaign_cnt
    ,create_campaign_cnt
    ,end_campaign_cnt
    ,avg_campaign_items
    ,daily_quota_usd
    ,avg_campaign_budget
    ,hit_budget_campaign_cnt
    ,hit_budget_campaign_per
    ,budget_cost_ratio
    ,avg_hit_budget_expense
    ,limited_budget_cnt
    ,unlimited_budget_cnt
    ,'all' as ads_type
    ,coalesce(seller_tier,'micro_seller') as seller_tier
    ,advertiser_tier
    ,is_cb_seller
    ,account_create_datetime
    ,deleted_ads_cnt
    ,ongoing_ads_cnt
    ,pause_ads_cnt
    ,closed_ads_cnt
    ,create_ads_cnt
    ,end_ads_cnt
    ,deleted_ads_cnt_7d
    ,ongoing_ads_cnt_7d
    ,pause_ads_cnt_7d
    ,closed_ads_cnt_7d
    ,create_ads_cnt_7d
    ,end_ads_cnt_7d
    ,ads_imp_cnt
    ,ads_click_cnt
    ,ads_direct_order_cnt
    ,ads_broad_order_cnt
    ,ads_direct_gmv_usd
    ,ads_broad_gmv_usd
    ,ads_platform_order_cnt
    ,ads_click_cnt / ads_imp_cnt as ads_ctr 
    ,ads_direct_order_cnt / ads_click_cnt as ads_cr 
    ,ads_direct_order_cnt / ads_imp_cnt as ads_ctr_cr 
    ,ads_direct_order_cnt / ads_platform_order_cnt as ads_order_contribution
    ,ads_direct_gmv_usd / ads_revenue_usd as ads_direct_order_roi 
    ,ads_broad_gmv_usd / ads_revenue_usd as ads_broad_order_roi
    ,ads_revenue_usd / platform_gmv_usd as ads_take_rate
    ,shop_item_imp_cnt
    ,org_item_imp_cnt
    ,shop_item_click_cnt
    ,org_item_click_cnt
    ,org_direct_gmv_usd
    ,org_broad_gmv_usd
    ,org_direct_order_cnt
    ,org_broad_order_cnt
    ,org_platform_order_cnt
    ,org_item_click_cnt / org_item_imp_cnt as org_ctr 
    ,org_direct_order_cnt / org_item_click_cnt as org_cr 
    ,org_direct_order_cnt / org_item_imp_cnt as org_ctr_cr 
    ,org_direct_order_cnt / org_platform_order_cnt as org_order_contribution
    ,ads_revenue_usd
    ,platform_gmv_usd
    ,have_expenditure_ads_cnt
    ,have_expenditure_ads_cnt_7d
    ,total_items_cnt
    ,newly_items_cnt
    ,have_imp_items_cnt
    ,have_click_items_cnt
    ,have_order_items_cnt
    ,have_ads_items_cnt
    ,newly_create_ads_items_cnt
    ,ongoing_ads_items_cnt
    ,closed_ads_items_cnt
    ,end_campaign_items_cnt
    ,have_expenditure_items_cnt
    ,have_ads_order_items_cnt
    ,ads_item_imp_cnt
    ,ads_item_click_cnt
    ,ads_item_order_cnt
    ,ads_item_gmv_usd
    ,ads_item_click_cnt / ads_item_imp_cnt as ads_item_ctr 
    ,ads_item_order_cnt / ads_item_click_cnt as ads_item_cr 
    ,ads_item_order_cnt / ads_item_imp_cnt as ads_item_ctr_cr 
    ,ads_imp_cnt / ads_item_imp_cnt as ads_imp_per
    ,ads_direct_order_cnt / ads_item_order_cnt as ads_direct_order_per
    ,ads_direct_gmv_usd / ads_item_gmv_usd as ads_direct_gmv_per
    ,seller_one_time_topup_amt
    ,seller_one_time_topup_amt_usd
    ,voucher_topup_amt
    ,voucher_topup_amt_usd
    ,package_topup_amt
    ,package_topup_amt_usd
    ,seller_auto_topup_amt
    ,seller_auto_topup_amt_usd
    ,admin_topup_amt
    ,admin_topup_amt_usd
    ,admin_manual_topup_amt
    ,admin_manual_topup_amt_usd
    ,admin_manual_adjust_topup_amt
    ,admin_manual_adjust_topup_amt_usd
    ,admin_api_topup_amt
    ,admin_api_topup_amt_usd
    ,admin_api_seller_mission_topup_amt
    ,admin_api_seller_mission_topup_amt_usd
    ,admin_api_qss_topup_amt
    ,admin_api_qss_topup_amt_usd
    ,seller_free_credit_topup_amt
    ,seller_free_credit_topup_amt_usd
    ,seller_one_time_free_credit_topup_amt
    ,seller_one_time_free_credit_topup_amt_usd
    ,admin_free_credit_topup_amt
    ,admin_free_credit_topup_amt_usd
    ,admin_api_free_credit_topup_amt
    ,admin_api_free_credit_topup_amt_usd
    ,seller_paid_credit_topup_amt
    ,seller_paid_credit_topup_amt_usd
    ,seller_one_time_paid_credit_topup_amt
    ,seller_one_time_paid_credit_topup_amt_usd
    ,seller_auto_paid_credit_topup_amt
    ,seller_auto_fpaid_credit_topup_amt_usd
    ,admin_paid_credit_topup_amt
    ,admin_paid_credit_topup_amt_usd
    ,voucher_paid_credit_topup_amt
    ,voucher_paid_credit_topup_amt_usd
    ,package_paid_credit_topup_amt
    ,package_paid_credit_topup_amt_usd
    ,admin_manual_paid_credit_topup_amt
    ,admin_manual_paid_credit_topup_amt_usd
    ,seller_mission_free_balance_amt
    ,seller_mission_free_balance_amt_usd
    ,coalesce(ads_placement_type,'no_related_ads') as ads_placement_type
    ,total_quota_usd
    ,deleted_campaign_cnt_search_simple_only
    ,ongoing_campaign_cnt_search_simple_only
    ,pause_campaign_cnt_search_simple_only
    ,closed_campaign_cnt_search_simple_only
    ,create_campaign_cnt_search_simple_only
    ,end_campaign_cnt_search_simple_only
    ,avg_campaign_items_search_simple_only
    ,limited_budget_cnt_search_simple_only
    ,unlimited_budget_cnt_search_simple_only
    ,daily_quota_usd_search_simple_only
    ,total_quota_usd_search_simple_only
    ,hit_budget_campaign_cnt_search_simple_only
    ,deleted_campaign_cnt_search_manual_only
    ,ongoing_campaign_cnt_search_manual_only
    ,pause_campaign_cnt_search_manual_only
    ,closed_campaign_cnt_search_manual_only
    ,create_campaign_cnt_search_manual_only
    ,end_campaign_cnt_search_manual_only
    ,avg_campaign_items_search_manual_only
    ,limited_budget_cnt_search_manual_only
    ,unlimited_budget_cnt_search_manual_only
    ,daily_quota_usd_search_manual_only
    ,total_quota_usd_search_manual_only
    ,hit_budget_campaign_cnt_search_manual_only
    ,deleted_campaign_cnt_search_manual_simple
    ,ongoing_campaign_cnt_search_manual_simple
    ,pause_campaign_cnt_search_manual_simple
    ,closed_campaign_cnt_search_manual_simple
    ,create_campaign_cnt_search_manual_simple
    ,end_campaign_cnt_search_manual_simple
    ,avg_campaign_items_search_manual_simple
    ,limited_budget_cnt_search_manual_simple
    ,unlimited_budget_cnt_search_manual_simple
    ,daily_quota_usd_search_manual_simple
    ,total_quota_usd_search_manual_simple
    ,hit_budget_campaign_cnt_search_manual_simple
    ,deleted_campaign_cnt_discovery_manual
    ,ongoing_campaign_cnt_discovery_manual
    ,pause_campaign_cnt_discovery_manual
    ,closed_campaign_cnt_discovery_manual
    ,create_campaign_cnt_discovery_manual
    ,end_campaign_cnt_discovery_manual
    ,avg_campaign_items_discovery_manual
    ,limited_budget_cnt_discovery_manual
    ,unlimited_budget_cnt_discovery_manual
    ,daily_quota_usd_discovery_manual
    ,total_quota_usd_discovery_manual
    ,hit_budget_campaign_cnt_discovery_manual
    ,deleted_campaign_cnt_discovery_simple
    ,ongoing_campaign_cnt_discovery_simple
    ,pause_campaign_cnt_discovery_simple
    ,closed_campaign_cnt_discovery_simple
    ,create_campaign_cnt_discovery_simple
    ,end_campaign_cnt_discovery_simple
    ,avg_campaign_items_discovery_simple
    ,limited_budget_cnt_discovery_simple
    ,unlimited_budget_cnt_discovery_simple
    ,daily_quota_usd_discovery_simple
    ,total_quota_usd_discovery_simple
    ,hit_budget_campaign_cnt_discovery_simple
    ,deleted_ads_cnt_search
    ,ongoing_ads_cnt_search
    ,pause_ads_cnt_search
    ,closed_ads_cnt_search
    ,create_ads_cnt_search
    ,end_ads_cnt_search
    ,have_expenditure_ads_cnt_search
    ,deleted_ads_cnt_discovery
    ,ongoing_ads_cnt_discovery
    ,pause_ads_cnt_discovery
    ,closed_ads_cnt_discovery
    ,create_ads_cnt_discovery
    ,end_ads_cnt_discovery
    ,have_expenditure_ads_cnt_discovery
    ,deleted_ads_cnt_shop
    ,ongoing_ads_cnt_shop
    ,pause_ads_cnt_shop
    ,closed_ads_cnt_shop
    ,create_ads_cnt_shop
    ,end_ads_cnt_shop
    ,have_expenditure_ads_cnt_shop
    ,deleted_ads_cnt_search_manual
    ,ongoing_ads_cnt_search_manual
    ,pause_ads_cnt_search_manual
    ,closed_ads_cnt_search_manual
    ,create_ads_cnt_search_manual
    ,end_ads_cnt_search_manual
    ,have_expenditure_ads_cnt_search_manual
    ,deleted_ads_cnt_search_simple
    ,ongoing_ads_cnt_search_simple
    ,pause_ads_cnt_search_simple
    ,closed_ads_cnt_search_simple
    ,create_ads_cnt_search_simple
    ,end_ads_cnt_search_simple
    ,have_expenditure_ads_cnt_search_simple
    ,deleted_ads_cnt_dd_manual
    ,ongoing_ads_cnt_dd_manual
    ,pause_ads_cnt_dd_manual
    ,closed_ads_cnt_dd_manual
    ,create_ads_cnt_dd_manual
    ,end_ads_cnt_dd_manual
    ,have_expenditure_ads_cnt_dd_manual
    ,deleted_ads_cnt_dd_simple
    ,ongoing_ads_cnt_dd_simple
    ,pause_ads_cnt_dd_simple
    ,closed_ads_cnt_dd_simple
    ,create_ads_cnt_dd_simple
    ,end_ads_cnt_dd_simple
    ,have_expenditure_ads_cnt_dd_simple
    ,deleted_ads_cnt_ymal_manual
    ,ongoing_ads_cnt_ymal_manual
    ,pause_ads_cnt_ymal_manual
    ,closed_ads_cnt_ymal_manual
    ,create_ads_cnt_ymal_manual
    ,end_ads_cnt_ymal_manual
    ,have_expenditure_ads_cnt_ymal_manual
    ,deleted_ads_cnt_ymal_simple
    ,ongoing_ads_cnt_ymal_simple
    ,pause_ads_cnt_ymal_simple
    ,closed_ads_cnt_ymal_simple
    ,create_ads_cnt_ymal_simple
    ,end_ads_cnt_ymal_simple
    ,have_expenditure_ads_cnt_ymal_simple
    ,deleted_ads_cnt_itemboost
    ,ongoing_ads_cnt_itemboost
    ,pause_ads_cnt_itemboost
    ,closed_ads_cnt_itemboost
    ,create_ads_cnt_itemboost
    ,end_ads_cnt_itemboost
    ,have_expenditure_ads_cnt_itemboost
    ,deleted_ads_cnt_autoboost
    ,ongoing_ads_cnt_autoboost
    ,pause_ads_cnt_autoboost
    ,closed_ads_cnt_autoboost
    ,create_ads_cnt_autoboost
    ,end_ads_cnt_autoboost
    ,have_expenditure_ads_cnt_autoboost
    ,deleted_ads_cnt_search_7d
    ,ongoing_ads_cnt_search_7d
    ,pause_ads_cnt_search_7d
    ,closed_ads_cnt_search_7d
    ,create_ads_cnt_search_7d
    ,end_ads_cnt_search_7d
    ,have_expenditure_ads_cnt_search_7d
    ,deleted_ads_cnt_discovery_7d
    ,ongoing_ads_cnt_discovery_7d
    ,pause_ads_cnt_discovery_7d
    ,closed_ads_cnt_discovery_7d
    ,create_ads_cnt_discovery_7d
    ,end_ads_cnt_discovery_7d
    ,have_expenditure_ads_cnt_discovery_7d
    ,deleted_ads_cnt_shop_7d
    ,ongoing_ads_cnt_shop_7d
    ,pause_ads_cnt_shop_7d
    ,closed_ads_cnt_shop_7d
    ,create_ads_cnt_shop_7d
    ,end_ads_cnt_shop_7d
    ,have_expenditure_ads_cnt_shop_7d
    ,deleted_ads_cnt_search_manual_7d
    ,ongoing_ads_cnt_search_manual_7d
    ,pause_ads_cnt_search_manual_7d
    ,closed_ads_cnt_search_manual_7d
    ,create_ads_cnt_search_manual_7d
    ,end_ads_cnt_search_manual_7d
    ,have_expenditure_ads_cnt_search_manual_7d
    ,deleted_ads_cnt_search_simple_7d
    ,ongoing_ads_cnt_search_simple_7d
    ,pause_ads_cnt_search_simple_7d
    ,closed_ads_cnt_search_simple_7d
    ,create_ads_cnt_search_simple_7d
    ,end_ads_cnt_search_simple_7d
    ,have_expenditure_ads_cnt_search_simple_7d
    ,deleted_ads_cnt_dd_manual_7d
    ,ongoing_ads_cnt_dd_manual_7d
    ,pause_ads_cnt_dd_manual_7d
    ,closed_ads_cnt_dd_manual_7d
    ,create_ads_cnt_dd_manual_7d
    ,end_ads_cnt_dd_manual_7d
    ,have_expenditure_ads_cnt_dd_manual_7d
    ,deleted_ads_cnt_dd_simple_7d
    ,ongoing_ads_cnt_dd_simple_7d
    ,pause_ads_cnt_dd_simple_7d
    ,closed_ads_cnt_dd_simple_7d
    ,create_ads_cnt_dd_simple_7d
    ,end_ads_cnt_dd_simple_7d
    ,have_expenditure_ads_cnt_dd_simple_7d
    ,deleted_ads_cnt_ymal_manual_7d
    ,ongoing_ads_cnt_ymal_manual_7d
    ,pause_ads_cnt_ymal_manual_7d
    ,closed_ads_cnt_ymal_manual_7d
    ,create_ads_cnt_ymal_manual_7d
    ,end_ads_cnt_ymal_manual_7d
    ,have_expenditure_ads_cnt_ymal_manual_7d
    ,deleted_ads_cnt_ymal_simple_7d
    ,ongoing_ads_cnt_ymal_simple_7d
    ,pause_ads_cnt_ymal_simple_7d
    ,closed_ads_cnt_ymal_simple_7d
    ,create_ads_cnt_ymal_simple_7d
    ,end_ads_cnt_ymal_simple_7d
    ,have_expenditure_ads_cnt_ymal_simple_7d
    ,deleted_ads_cnt_itemboost_7d
    ,ongoing_ads_cnt_itemboost_7d
    ,pause_ads_cnt_itemboost_7d
    ,closed_ads_cnt_itemboost_7d
    ,create_ads_cnt_itemboost_7d
    ,end_ads_cnt_itemboost_7d
    ,have_expenditure_ads_cnt_itemboost_7d
    ,deleted_ads_cnt_autoboost_7d
    ,ongoing_ads_cnt_autoboost_7d
    ,pause_ads_cnt_autoboost_7d
    ,closed_ads_cnt_autoboost_7d
    ,create_ads_cnt_autoboost_7d
    ,end_ads_cnt_autoboost_7d
    ,have_expenditure_ads_cnt_autoboost_7d
    ,ads_imp_cnt_search
    ,ads_click_cnt_search
    ,ads_direct_order_cnt_search
    ,ads_broad_order_cnt_search
    ,ads_direct_gmv_usd_search
    ,ads_broad_gmv_usd_search
    ,ads_revenue_usd_search
    ,ads_imp_cnt_discovery
    ,ads_click_cnt_discovery
    ,ads_direct_order_cnt_discovery
    ,ads_broad_order_cnt_discovery
    ,ads_direct_gmv_usd_discovery
    ,ads_broad_gmv_usd_discovery
    ,ads_revenue_usd_discovery
    ,ads_imp_cnt_shop
    ,ads_click_cnt_shop
    ,ads_direct_order_cnt_shop
    ,ads_broad_order_cnt_shop
    ,ads_direct_gmv_usd_shop
    ,ads_broad_gmv_usd_shop
    ,ads_revenue_usd_shop
    ,ads_imp_cnt_search_manual
    ,ads_click_cnt_search_manual
    ,ads_direct_order_cnt_search_manual
    ,ads_broad_order_cnt_search_manual
    ,ads_direct_gmv_usd_search_manual
    ,ads_broad_gmv_usd_search_manual
    ,ads_revenue_usd_search_manual
    ,ads_imp_cnt_search_simple
    ,ads_click_cnt_search_simple
    ,ads_direct_order_cnt_search_simple
    ,ads_broad_order_cnt_search_simple
    ,ads_direct_gmv_usd_search_simple
    ,ads_broad_gmv_usd_search_simple
    ,ads_revenue_usd_search_simple
    ,ads_imp_cnt_dd_manual
    ,ads_click_cnt_dd_manual
    ,ads_direct_order_cnt_dd_manual
    ,ads_broad_order_cnt_dd_manual
    ,ads_direct_gmv_usd_dd_manual
    ,ads_broad_gmv_usd_dd_manual
    ,ads_revenue_usd_dd_manual
    ,ads_imp_cnt_dd_simple
    ,ads_click_cnt_dd_simple
    ,ads_direct_order_cnt_dd_simple
    ,ads_broad_order_cnt_dd_simple
    ,ads_direct_gmv_usd_dd_simple
    ,ads_broad_gmv_usd_dd_simple
    ,ads_revenue_usd_dd_simple
    ,ads_imp_cnt_ymal_manual
    ,ads_click_cnt_ymal_manual
    ,ads_direct_order_cnt_ymal_manual
    ,ads_broad_order_cnt_ymal_manual
    ,ads_direct_gmv_usd_ymal_manual
    ,ads_broad_gmv_usd_ymal_manual
    ,ads_revenue_usd_ymal_manual
    ,ads_imp_cnt_ymal_simple
    ,ads_click_cnt_ymal_simple
    ,ads_direct_order_cnt_ymal_simple
    ,ads_broad_order_cnt_ymal_simple
    ,ads_direct_gmv_usd_ymal_simple
    ,ads_broad_gmv_usd_ymal_simple
    ,ads_revenue_usd_ymal_simple
    ,ads_imp_cnt_itemboost
    ,ads_click_cnt_itemboost
    ,ads_direct_order_cnt_itemboost
    ,ads_broad_order_cnt_itemboost
    ,ads_direct_gmv_usd_itemboost
    ,ads_broad_gmv_usd_itemboost
    ,ads_revenue_usd_itemboost
    ,ads_imp_cnt_autoboost
    ,ads_click_cnt_autoboost
    ,ads_direct_order_cnt_autoboost
    ,ads_broad_order_cnt_autoboost
    ,ads_direct_gmv_usd_autoboost
    ,ads_broad_gmv_usd_autoboost
    ,ads_revenue_usd_autoboost
    ,have_ads_items_cnt_search
    ,newly_create_ads_items_cnt_search
    ,ongoing_ads_items_cnt_search
    ,closed_ads_items_cnt_search
    ,end_campaign_items_cnt_search
    ,have_expenditure_items_cnt_search
    ,have_ads_order_items_cnt_search
    ,have_ads_items_cnt_discovery
    ,newly_create_ads_items_cnt_discovery
    ,ongoing_ads_items_cnt_discovery
    ,closed_ads_items_cnt_discovery
    ,end_campaign_items_cnt_discovery
    ,have_expenditure_items_cnt_discovery
    ,have_ads_order_items_cnt_discovery
    ,have_ads_items_cnt_shop
    ,newly_create_ads_items_cnt_shop
    ,ongoing_ads_items_cnt_shop
    ,closed_ads_items_cnt_shop
    ,end_campaign_items_cnt_shop
    ,have_expenditure_items_cnt_shop
    ,have_ads_order_items_cnt_shop
    ,have_ads_items_cnt_search_manual
    ,newly_create_ads_items_cnt_search_manual
    ,ongoing_ads_items_cnt_search_manual
    ,closed_ads_items_cnt_search_manual
    ,end_campaign_items_cnt_search_manual
    ,have_expenditure_items_cnt_search_manual
    ,have_ads_order_items_cnt_search_manual
    ,have_ads_items_cnt_search_simple
    ,newly_create_ads_items_cnt_search_simple
    ,ongoing_ads_items_cnt_search_simple
    ,closed_ads_items_cnt_search_simple
    ,end_campaign_items_cnt_search_simple
    ,have_expenditure_items_cnt_search_simple
    ,have_ads_order_items_cnt_search_simple
    ,have_ads_items_cnt_dd_manual
    ,newly_create_ads_items_cnt_dd_manual
    ,ongoing_ads_items_cnt_dd_manual
    ,closed_ads_items_cnt_dd_manual
    ,end_campaign_items_cnt_dd_manual
    ,have_expenditure_items_cnt_dd_manual
    ,have_ads_order_items_cnt_dd_manual
    ,have_ads_items_cnt_dd_simple
    ,newly_create_ads_items_cnt_dd_simple
    ,ongoing_ads_items_cnt_dd_simple
    ,closed_ads_items_cnt_dd_simple
    ,end_campaign_items_cnt_dd_simple
    ,have_expenditure_items_cnt_dd_simple
    ,have_ads_order_items_cnt_dd_simple
    ,have_ads_items_cnt_ymal_manual
    ,newly_create_ads_items_cnt_ymal_manual
    ,ongoing_ads_items_cnt_ymal_manual
    ,closed_ads_items_cnt_ymal_manual
    ,end_campaign_items_cnt_ymal_manual
    ,have_expenditure_items_cnt_ymal_manual
    ,have_ads_order_items_cnt_ymal_manual
    ,have_ads_items_cnt_ymal_simple
    ,newly_create_ads_items_cnt_ymal_simple
    ,ongoing_ads_items_cnt_ymal_simple
    ,closed_ads_items_cnt_ymal_simple
    ,end_campaign_items_cnt_ymal_simple
    ,have_expenditure_items_cnt_ymal_simple
    ,have_ads_order_items_cnt_ymal_simple
    ,have_ads_items_cnt_itemboost
    ,newly_create_ads_items_cnt_itemboost
    ,ongoing_ads_items_cnt_itemboost
    ,closed_ads_items_cnt_itemboost
    ,end_campaign_items_cnt_itemboost
    ,have_expenditure_items_cnt_itemboost
    ,have_ads_order_items_cnt_itemboost
    ,have_ads_items_cnt_autoboost
    ,newly_create_ads_items_cnt_autoboost
    ,ongoing_ads_items_cnt_autoboost
    ,closed_ads_items_cnt_autoboost
    ,end_campaign_items_cnt_autoboost
    ,have_expenditure_items_cnt_autoboost
    ,have_ads_order_items_cnt_autoboost
    ,is_official_shop
    ,is_preferred_shop
    ,is_managed_seller
    ,platform_gmv_usd_td
    ,top_selling_item_id
    ,ads_revenue_usd_td
    ,ads_gmv_usd_td
    ,ads_revenue_usd_td_search
    ,ads_gmv_usd_td_search
    ,ads_revenue_usd_td_search_manual
    ,ads_gmv_usd_td_search_manual
    ,ads_revenue_usd_td_search_simple
    ,ads_gmv_usd_td_search_simple
    ,ads_revenue_usd_td_dd_manual
    ,ads_gmv_usd_td_dd_manual
    ,ads_revenue_usd_td_dd_simple
    ,ads_gmv_usd_td_dd_simple
    ,ads_revenue_usd_td_ymal_manual
    ,ads_gmv_usd_td_ymal_manual
    ,ads_revenue_usd_td_ymal_simple
    ,ads_gmv_usd_td_ymal_simple
    ,ads_revenue_usd_td_itemboost
    ,ads_gmv_usd_td_itemboost
    ,ads_revenue_usd_td_autoboost
    ,ads_gmv_usd_td_autoboost
    ,ads_revenue_usd_td_shop
    ,ads_gmv_usd_td_shop
    ,ads_revenue_usd_td_discovery
    ,ads_gmv_usd_td_discovery
    ,daily_budget_campaign_cnt
    ,daily_budget_campaign_cnt_discovery_manual
    ,daily_budget_campaign_cnt_discovery_simple
    ,daily_budget_campaign_cnt_search_manual_only
    ,daily_budget_campaign_cnt_search_manual_simple
    ,daily_budget_campaign_cnt_search_simple_only
    ,total_budget_campaign_cnt
    ,total_budget_campaign_cnt_discovery_manual
    ,total_budget_campaign_cnt_discovery_simple
    ,total_budget_campaign_cnt_search_manual_only
    ,total_budget_campaign_cnt_search_manual_simple
    ,total_budget_campaign_cnt_search_simple_only
    ,coalesce(key_seller_90,0) as key_seller_90
    ,coalesce(key_seller_95,0) as key_seller_95
    ,active_items_cnt
    ,seller_status
    ,advertiser_status
    ,active_ads_cnt
    ,active_ads_cnt_search
    ,active_ads_cnt_discovery
    ,active_ads_cnt_shop
    ,active_ads_cnt_search_manual
    ,active_ads_cnt_search_simple
    ,active_ads_cnt_itemboost
    ,active_ads_cnt_autoboost
    ,active_ads_cnt_dd_manual
    ,active_ads_cnt_dd_simple
    ,active_ads_cnt_ymal_manual
    ,active_ads_cnt_ymal_simple
    ,deleted_campaign_cnt_roi_two
    ,ongoing_campaign_cnt_roi_two 
    ,pause_campaign_cnt_roi_two 
    ,closed_campaign_cnt_roi_two 
    ,create_campaign_cnt_roi_two 
    ,end_campaign_cnt_roi_two 
    ,avg_campaign_items_roi_two 
    ,daily_quota_usd_roi_two 
    ,total_quota_usd_roi_two 
    ,hit_budget_campaign_cnt_roi_two 
    ,limited_budget_cnt_roi_two 
    ,unlimited_budget_cnt_roi_two 
    ,daily_budget_campaign_cnt_roi_two 
    ,total_budget_campaign_cnt_roi_two 
    ,ads_imp_cnt_roi_two 
    ,ads_click_cnt_roi_two 
    ,ads_direct_order_cnt_roi_two 
    ,ads_broad_order_cnt_roi_two 
    ,ads_direct_gmv_usd_roi_two 
    ,ads_revenue_usd_roi_two 
    ,have_expenditure_ads_cnt_roi_two 
    ,active_ads_cnt_roi_two 
    ,deleted_ads_cnt_roi_two 
    ,ongoing_ads_cnt_roi_two 
    ,pause_ads_cnt_roi_two 
    ,closed_ads_cnt_roi_two 
    ,create_ads_cnt_roi_two 
    ,end_ads_cnt_roi_two 
    ,deleted_ads_cnt_roi_two_7d 
    ,ongoing_ads_cnt_roi_two_7d 
    ,pause_ads_cnt_roi_two_7d 
    ,closed_ads_cnt_roi_two_7d 
    ,create_ads_cnt_roi_two_7d 
    ,end_ads_cnt_roi_two_7d 
    ,have_expenditure_ads_cnt_roi_two_7d 
    ,have_expenditure_items_cnt_roi_two 
    ,have_ads_order_items_cnt_roi_two 
    ,have_ads_items_cnt_roi_two 
    ,newly_create_ads_items_cnt_roi_two 
    ,ongoing_ads_items_cnt_roi_two 
    ,closed_ads_items_cnt_roi_two 
    ,end_campaign_items_cnt_roi_two 
    ,ads_revenue_usd_td_roi_two 
    ,ads_gmv_usd_td_roi_two 
    ,ads_broad_gmv_usd_roi_two
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
from seller_info a 
left join topup b 
on a.shop_id = b.shop_id
left join deduction_di c 
on a.shop_id = c.shop_id
left join expiry d 
on a.shop_id = d.shop_id
left join balance_df e 
on a.shop_id = e.shop_id
left join campaign_cnt f  
on a.shop_id = f.shop_id
left join campaign_budget g
on a.shop_id = g.shop_id
left join org_performance h 
on a.shop_id = h.shop_id
left join ads_cnt i 
on a.shop_id = i.shop_id 
left join ads_cnt_7d j
on a.shop_id = j.shop_id 
left join platform_order k
on a.shop_id = k.shop_id 
left join seller_item_cnt n
on a.shop_id = n.shop_id
left join ads_item_performance p
on a.shop_id = p.shop_id
left join ads_item_cnt q
on a.shop_id = q.shop_id 
left join has_expenditure_ads_cnt_7d r 
on a.shop_id = r.shop_id 
left join ads_performance s
on a.shop_id = s.shop_id 
left join platform_gmv_td t
on a.shop_id = t.shop_id 
left join ads_performance_td u
on a.shop_id = u.shop_id 
;