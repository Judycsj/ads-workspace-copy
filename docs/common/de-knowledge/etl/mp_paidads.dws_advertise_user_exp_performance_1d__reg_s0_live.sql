-- task_code: data_paidadsmart.studio_5610159  asset_id: 5610159
--drop table dws_advertise_user_exp_performance_1d__reg_s0_live;
CREATE EXTERNAL TABLE if not exists dws_advertise_user_exp_performance_1d__reg_s0_live (
  `group_id` bigint COMMENT 'user experiment group id',
  `placement` int COMMENT 'Indicates placement of ads',
  `entrance` int COMMENT 'entrance',
  `pricing_type` int COMMENT 'pricing_type',

  `ads_imp_cnt` bigint COMMENT 'impression count',
  `ads_clk_cnt` bigint COMMENT 'click count',
  `ads_order_cnt` bigint COMMENT 'direct order count',
  `ads_gmv_usd` decimal(25, 10) COMMENT 'direct order gmv usd',
  `ads_revenue_usd` decimal(25, 10) COMMENT 'ads revenue usd',
  `ads_gmv` decimal(25, 10) COMMENT 'direct order gmv local concurrency',
  `ads_revenue` decimal(25, 10) COMMENT 'ads revenue local concurrency',
  `extreme_removed_ads_orders` bigint COMMENT 'extreme_removed_ads_orders(only for search ads)',
  `extreme_removed_ads_gmv_usd` decimal(25, 10) COMMENT 'extreme_removed_ads_gmv_usd(only for search ads)',
  `advv` decimal(25, 10) COMMENT 'advv(only for search ads)',
  `ads_item_sold_cnt` bigint COMMENT 'ads_item_sold_cnt',
  `ads_broad_order_cnt` bigint COMMENT 'ads_broad_order_cnt',
  `expense_free_credit_with_expiry` decimal(25, 10) COMMENT 'expense_free_credit_with_expiry',
  `expense_free_credit_without_expiry` decimal(25, 10) COMMENT 'expense_free_credit_without_expiry',
  `ads_daily_order_cnt` bigint COMMENT 'ads_daily_order_cnt',
  `ads_daily_gmv_usd` decimal(25, 10) COMMENT 'ads_daily_gmv_usd',
  `ads_broad_gmv_usd` decimal(25, 10) COMMENT 'ads_broad_gmv_usd',
  `ads_daily_gmv_usd_500` decimal(25, 10) COMMENT 'ads_daily_gmv_usd_500',
  `ads_daily_gmv_usd_200` decimal(25, 10) COMMENT 'ads_daily_gmv_usd_200',
  `ads_order_gmv_usd_500` decimal(25, 10) COMMENT 'ads_order_gmv_usd_500',
  `ads_order_gmv_usd_200` decimal(25, 10) COMMENT 'ads_order_gmv_usd_200',
  `ads_broad_gmv` decimal(25, 10) COMMENT 'ads_broad_gmv',
  `location` int COMMENT 'location',
  `sub_entrance` bigint COMMENT 'sub_entrance'
  )
COMMENT 'paid_ads_dws_advertise_user_exp_performance_1d'
PARTITIONED BY (
  `tz_type` string,
  `grass_region` string,
  `grass_date` date)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  '${HIVE_PATH}/dws_advertise_user_exp_performance_1d';

--ads_performance_base
--create or replace temporary view ads_performance_base
cache table ads_performance_base
as
select ads_base.grass_region,entrance, placement, user_id, pricing_type,location,sub_entrance,
    SUM(impression_cnt) as impression_cnt,
    SUM(click_cnt) as click_cnt,
    SUM(order_cnt) AS order_cnt,
    SUM(ads_order_gmv_local) AS ads_order_gmv_local,
    SUM(case when(placement = 9) then round(cpm * impression_cnt / 100000, 2) else expenditure_amt_local end) AS expenditure_amt_local,
    SUM(ads_order_gmv_usd) AS ads_order_gmv_usd,
    SUM(ads_item_sold_cnt) AS ads_item_sold_cnt,
    SUM(broad_order_cnt) AS broad_order_cnt,
    SUM(expense_free_credit_with_expiry) AS expense_free_credit_with_expiry,
    SUM(expense_free_credit_without_expiry) AS expense_free_credit_without_expiry,
    SUM(daily_order_cnt) AS daily_order_cnt,
    SUM(daily_gmv_amt_local ) AS daily_gmv_amt_local,
    SUM(broad_gmv_amt_local) AS broad_gmv_amt_local,
    SUM(case when (daily_gmv_amt_local/exchange_rate) > 500 then 500
            else (daily_gmv_amt_local/exchange_rate)
      end) as daily_gmv_usd_500,
    SUM(case when (daily_gmv_amt_local/exchange_rate) > 200 then 200
            else (daily_gmv_amt_local/exchange_rate) 
      end) as daily_gmv_usd_200,
    SUM(case when (ads_order_gmv_local/exchange_rate) > 500 then 500
            else (ads_order_gmv_local/exchange_rate)
      end) as ads_order_gmv_usd_500,
    SUM(case when (ads_order_gmv_local/exchange_rate) > 200 then 200
            else (ads_order_gmv_local/exchange_rate)
      end) as ads_order_gmv_usd_200
from
(
  
  select grass_region,entrance, placement, user_id, pricing_type,location,sub_entrance,
  impression_cnt,
  case when(placement=9) then raw_click_cnt else click_cnt end as click_cnt, cpm,
  order_cnt,ads_order_gmv_local,expenditure_amt_local,ads_order_gmv_usd,
  ads_item_sold_cnt,broad_order_cnt,expense_free_credit_with_expiry,expense_free_credit_without_expiry,
  daily_order_cnt,daily_gmv_amt_local,broad_gmv_amt_local
  from mp_paidads.dwd_advertise_performance_di__reg_s0_live
  where grass_date =  date('${grass_date}') 
  and grass_region=upper('${region}')
  and tz_type='local'
) ads_base
LEFT OUTER JOIN 
(
    select * from mp_order.dim_exchange_rate__reg_s0_live
    where grass_date =  date('${grass_date}') 
    and grass_region=upper('${region}')
) exchange_rate
on ads_base.grass_region = exchange_rate.grass_region
group by ads_base.grass_region,entrance, placement, user_id, pricing_type, location,sub_entrance;

--search extreme users
create or replace temporary view ads_search_extreme_users
as
select user_id,
sum(ifnull(order_cnt, 0)) as ads_orders,
sum(ifnull(ads_order_gmv_usd, 0)) as ads_gmv_usd,
1 as extreme_user_flag
from ads_performance_base
where placement in (0, 4, 1000, 1200)
group by user_id
having ads_orders>=50 or ads_gmv_usd>=200;

--search advv
create or replace temporary view advv_base
as
select user_id,placement,entrance,pricing_type,location,sub_entrance,sum(advv) as advv
from(
  select
      user_id
      , case when (placement = 0 and pricing_type = 1) then origin_bid_price * raw_click / 100000.0000
          when (placement = 0 and pricing_type != 1) then raw_expense / 100000.0000
          when (placement in (4,1000,1200)) then null -- ads_order_gmv_usd*target_cir / 1.0000
        else null end as advv
      , placement
      , entrance
      , pricing_type
      , location
      ,sub_entrance
  from
  (
    select user_id,ads_id,placement,entrance,pricing_type,location,sub_entrance,
        origin_bid_price,click_before_deduction_cnt as raw_click,raw_expense,ads_order_gmv_usd
    from mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where
        true
        and grass_date =  date('${grass_date}') 
        and grass_region=upper('${region}')
        and placement in (0,4,1000,1200)
        and entrance = 1
        and ads_id>0
  ) performance
) group by user_id, placement,entrance,pricing_type,location,sub_entrance;

create or replace temporary view ads_performance_base_new
as
select grass_region,
  ads_performance_base.entrance,
  ads_performance_base.placement, 
  ads_performance_base.user_id,
  ads_performance_base.pricing_type,
  ads_performance_base.location,
  ads_performance_base.sub_entrance,
  impression_cnt,click_cnt,order_cnt,ads_order_gmv_local,expenditure_amt_local,
  ads_order_gmv_usd,ads_item_sold_cnt,broad_order_cnt,expense_free_credit_with_expiry,
  expense_free_credit_without_expiry,daily_order_cnt,daily_gmv_amt_local,broad_gmv_amt_local,
  daily_gmv_usd_500, daily_gmv_usd_200,
  ads_order_gmv_usd_500, ads_order_gmv_usd_200,
  COALESCE(extreme_user_flag, 0) as extreme_user_flag,
  advv
from ads_performance_base
left join advv_base
on ads_performance_base.entrance = advv_base.entrance
and ads_performance_base.placement = advv_base.placement
and ads_performance_base.user_id = advv_base.user_id
and ads_performance_base.pricing_type = advv_base.pricing_type
and ads_performance_base.location = advv_base.location
and ads_performance_base.sub_entrance = advv_base.sub_entrance
left join 
ads_search_extreme_users
on ads_performance_base.user_id=ads_search_extreme_users.user_id;
;


-- prepare search group_id && user_id
-- Global Search、Image Search、Shop Game、Games、Search Shop、Brand Ads
-- entrance not in (3,4,8,9,10,11)
create or replace temporary view search_group
as
select user_id, exp_group_id as group_id 
from srdi_mart.dim_sr_data_warehouse_abtest_user_group
where local_date = date('${grass_date}') 
and grass_region=upper('${region}')
and user_id is not null and user_id != 0 and is_assignment_log = 1
group by user_id, exp_group_id
;

--Daily Discover、You May Also Like、Cart Recommendation、Order Successful Recommendation
--Order Detail Page Recommendation、My Purchase Page Recommendation
--entrance in (3,4,8,9,10,11)
create or replace temporary view dd_ymal_group
as
select user_id, exp_group_id as group_id 
from srdi_mart.dim_sr_data_warehouse_abtest_user_group
where local_date = date('${grass_date}') 
and grass_region = upper('${region}')
and user_id is not null and user_id != 0 and is_dim_join = 1
--video bug
and exp_group_id not in 
    (select distinct exp_group_id
      from srdi_mart.dim_sr_data_warehouse_exp
      where   scene_id in (588,171))
group by user_id, exp_group_id

union all 

--video need
select user_id, exp_group_id as group_id 
from srdi_mart.dim_sr_data_warehouse_abtest_user_group
where local_date = date('${grass_date}') 
and grass_region=upper('${region}')
and user_id is not null and user_id != 0 and is_assignment_log = 1
and exp_group_id in 
    (select distinct exp_group_id
      from srdi_mart.dim_sr_data_warehouse_exp
      where   scene_id in (588,171))
group by user_id, exp_group_id
;

create or replace temporary view search_group_performance
as
select grass_region,entrance, placement, group_id, pricing_type,location,sub_entrance,
SUM(impression_cnt) as ads_imp_cnt,
SUM(click_cnt) as ads_clk_cnt,
SUM(order_cnt) AS ads_order_cnt,
SUM(ads_order_gmv_local) AS ads_gmv_local,
SUM(expenditure_amt_local) AS expenditure_amt_local,
sum(case when extreme_user_flag = 0 then ifnull(order_cnt, 0) else 0 end) as extreme_removed_ads_orders,
sum(case when extreme_user_flag = 0 then ifnull(ads_order_gmv_usd, 0) else 0 end) as extreme_removed_ads_gmv_usd,
sum(advv) as advv,
SUM(ads_item_sold_cnt) AS ads_item_sold_cnt,
SUM(broad_order_cnt) AS broad_order_cnt,
SUM(expense_free_credit_with_expiry) AS expense_free_credit_with_expiry,
SUM(expense_free_credit_without_expiry) AS expense_free_credit_without_expiry,
SUM(daily_order_cnt) AS daily_order_cnt,
SUM(daily_gmv_amt_local ) AS daily_gmv_amt_local,
SUM(broad_gmv_amt_local) AS broad_gmv_amt_local,
SUM(daily_gmv_usd_500) as daily_gmv_usd_500,
SUM(daily_gmv_usd_200) as daily_gmv_usd_200,
SUM(ads_order_gmv_usd_500) as ads_order_gmv_usd_500,
SUM(ads_order_gmv_usd_200) as ads_order_gmv_usd_200
from (
    select grass_region,entrance, placement, group_id,pricing_type,location,sub_entrance,
    impression_cnt,click_cnt,order_cnt,ads_order_gmv_local,expenditure_amt_local,
    ads_order_gmv_usd,extreme_user_flag,advv,ads_item_sold_cnt,broad_order_cnt,
    expense_free_credit_with_expiry,expense_free_credit_without_expiry,
    daily_order_cnt,daily_gmv_amt_local,broad_gmv_amt_local,
    daily_gmv_usd_500, daily_gmv_usd_200,
    ads_order_gmv_usd_500, ads_order_gmv_usd_200 from
    (
        select * from ads_performance_base_new
        where entrance not in (3,4,8,9,10,11)
    ) tab1
    inner join 
    (
        select * from search_group
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by grass_region,entrance, placement, group_id, pricing_type ,location,sub_entrance;

create or replace temporary view dd_ymal_group_performance
as
select grass_region,entrance, placement, group_id, pricing_type,location,sub_entrance,
SUM(impression_cnt) as ads_imp_cnt,
SUM(click_cnt) as ads_clk_cnt,
SUM(order_cnt) AS ads_order_cnt,
SUM(ads_order_gmv_local) AS ads_gmv_local,
SUM(expenditure_amt_local) AS expenditure_amt_local,
null as extreme_removed_ads_orders,
null as extreme_removed_ads_gmv_usd,
null as advv,
SUM(ads_item_sold_cnt) AS ads_item_sold_cnt,
SUM(broad_order_cnt) AS broad_order_cnt,
SUM(expense_free_credit_with_expiry) AS expense_free_credit_with_expiry,
SUM(expense_free_credit_without_expiry) AS expense_free_credit_without_expiry,
SUM(daily_order_cnt) AS daily_order_cnt,
SUM(daily_gmv_amt_local ) AS daily_gmv_amt_local,
SUM(broad_gmv_amt_local) AS broad_gmv_amt_local,
SUM(daily_gmv_usd_500) as daily_gmv_usd_500,
SUM(daily_gmv_usd_200) as daily_gmv_usd_200,
SUM(ads_order_gmv_usd_500) as ads_order_gmv_usd_500,
SUM(ads_order_gmv_usd_200) as ads_order_gmv_usd_200
from (
    select grass_region,entrance, placement, group_id, pricing_type,location, sub_entrance,
    impression_cnt,click_cnt,order_cnt,ads_order_gmv_local,expenditure_amt_local,
    ads_order_gmv_usd,extreme_user_flag,advv,ads_item_sold_cnt,broad_order_cnt,
    expense_free_credit_with_expiry,expense_free_credit_without_expiry,
    daily_order_cnt,daily_gmv_amt_local,broad_gmv_amt_local,
    daily_gmv_usd_500, daily_gmv_usd_200,
    ads_order_gmv_usd_500, ads_order_gmv_usd_200 from
    (
        select * from ads_performance_base_new
        where entrance in (3,4,8,9,10,11)
    ) tab1
    inner join 
    (
        select * from dd_ymal_group
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by grass_region,entrance, placement, group_id, pricing_type,location,sub_entrance;

insert overwrite table dws_advertise_user_exp_performance_1d__reg_s0_live 
partition (tz_type='local', grass_region, grass_date)
select group_id, 
placement,
entrance,
pricing_type,
ads_imp_cnt,ads_clk_cnt,ads_order_cnt,
ads_gmv_local/exchange_rate as ads_gmv_usd,
expenditure_amt_local/exchange_rate as ads_revenue_usd,
ads_gmv_local as ads_gmv,
expenditure_amt_local as ads_revenue,
extreme_removed_ads_orders,
extreme_removed_ads_gmv_usd,
advv /exchange_rate as advv,
ads_item_sold_cnt,
broad_order_cnt as ads_broad_order_cnt,
expense_free_credit_with_expiry,
expense_free_credit_without_expiry,
daily_order_cnt as ads_daily_order_cnt,
daily_gmv_amt_local / exchange_rate as ads_daily_gmv_usd,
broad_gmv_amt_local / exchange_rate as ads_broad_gmv_usd,
daily_gmv_usd_500 as ads_daily_gmv_usd_500,
daily_gmv_usd_200 as ads_daily_gmv_usd_200,
ads_order_gmv_usd_500 as ads_order_gmv_usd_500,
ads_order_gmv_usd_200 as ads_order_gmv_usd_200,
broad_gmv_amt_local as ads_broad_gmv,
location,
sub_entrance,
ads_performance.grass_region, date('${grass_date}')  as grass_date
from (
    select * from dd_ymal_group_performance
    union all
    select * from search_group_performance
) ads_performance
LEFT OUTER JOIN 
(
    select * from mp_order.dim_exchange_rate__reg_s0_live
    where grass_date =  date('${grass_date}') 
    and grass_region=upper('${region}')
) exchange_rate
ON ads_performance.grass_region = exchange_rate.grass_region;