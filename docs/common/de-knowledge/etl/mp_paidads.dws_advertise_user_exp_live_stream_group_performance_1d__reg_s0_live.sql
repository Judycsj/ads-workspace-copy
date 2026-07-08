-- task_code: data_paidadsmart.studio_6024140  asset_id: 6024140
--drop table dws_advertise_user_exp_live_stream_group_performance_1d__reg_s0_live;
CREATE EXTERNAL TABLE if not exists dws_advertise_user_exp_live_stream_group_performance_1d__reg_s0_live (
  `group_id` bigint COMMENT 'user experiment group id',
  
  `ads_imp_cnt` bigint COMMENT 'impression count',
  `ads_view_cnt` bigint COMMENT 'impression count',
  `ads_view_uu` bigint COMMENT 'impression count',
  `ads_view_duration` bigint COMMENT 'impression count',
  `ads_raw_click_cnt` bigint COMMENT 'ads_raw_clk_cnt',
  `ads_raw_click_uu` bigint COMMENT 'ads_raw_clk_uu',
  `ads_product_clk_cnt` bigint COMMENT 'ads_product_clk_cnt',
  `ads_product_clk_uu` bigint COMMENT 'ads_product_clk_uu',
  `expected_cpm` decimal(25, 10) COMMENT 'expected_cpm',

  `ads_direct_order_cnt` bigint COMMENT 'direct order count',
  `ads_direct_order_uu` bigint COMMENT 'direct order uu',
  `ads_broad_order_cnt` bigint COMMENT 'ads_broad_order_cnt',
  `ads_broad_order_uu` bigint COMMENT 'ads_broad_order_uu',
  `ads_broad_item_sold_cnt` bigint COMMENT 'ads_broad_item_sold_cnt',
  `ads_broad_item_sold_uu` bigint COMMENT 'ads_broad_item_sold_uu',
  `ads_direct_item_sold_cnt` bigint COMMENT 'ads_direct_item_sold_cnt',
  `ads_direct_item_sold_uu` bigint COMMENT 'ads_direct_item_sold_uu',
  `ads_daily_item_sold_cnt` bigint COMMENT 'ads_direct_item_sold_cnt',
  `ads_daily_item_sold_uu` bigint COMMENT 'ads_direct_item_sold_uu',

  `ads_revenue` decimal(25, 10) COMMENT 'ads revenue',
  `ads_revenue_usd` decimal(25, 10) COMMENT 'ads revenue usd',
  `ads_daily_gmv` decimal(25, 10) COMMENT 'ads_daily_gmv',
  `ads_daily_gmv_usd` decimal(25, 10) COMMENT 'ads_daily_gmv_usd',
  `ads_daily_gmv_usd_500` decimal(25, 10) COMMENT 'ads_daily_gmv_usd_500',
  `ads_daily_gmv_usd_200` decimal(25, 10) COMMENT 'ads_daily_gmv_usd_200',
  `ads_broad_gmv` decimal(25, 10) COMMENT 'ads_broad_gmv',
  `ads_broad_gmv_usd` decimal(25, 10) COMMENT 'ads_broad_gmv_usd',
  `ads_direct_gmv` decimal(25, 10) COMMENT 'direct order gmv',
  `ads_direct_gmv_usd` decimal(25, 10) COMMENT 'direct order usd gmv',
  `ads_direct_gmv_usd_500` decimal(25, 10) COMMENT 'ads_order_gmv_usd_500',
  `ads_direct_gmv_usd_200` decimal(25, 10) COMMENT 'ads_order_gmv_usd_200',

  `rev_free_credit_with_expiry` decimal(25, 10) COMMENT 'expense_free_credit_with_expiry',
  `rev_free_credit_without_expiry` decimal(25, 10) COMMENT 'expense_free_credit_without_expiry',
  `rev_paid_credit_with_expiry` decimal(25, 10) COMMENT 'expense_free_credit_with_expiry',
  `rev_paidcredit_without_expiry` decimal(25, 10) COMMENT 'expense_free_credit_without_expiry',
  `ads_deduct_imp_cnt` bigint COMMENT 'ads_deduct_imp_cnt',
  `agent_gmv_amt_local`	decimal(25, 10) COMMENT 'agent_gmv_amt_local',
	`agent_order_cnt`	bigint	COMMENT 'agent_order_cnt',
	`agent_item_cnt`	bigint	COMMENT 'agent_item_cnt',
	`agent_checkout`	bigint	COMMENT 'agent_checkout',
  `agent_gmv_amt_usd`	decimal(25, 10) COMMENT 'agent_gmv_amt_usd',
  `checkout_cnt`	bigint	COMMENT 'checkout_cnt',
  `view1_5`  bigint,
   `view6_10`  bigint,
   `view11_15` bigint,
   `view16_20` bigint,
  `view21_25` bigint,
  `view26_30` bigint,
  `view30_plus` bigint
  )
COMMENT 'dws_advertise_user_exp_live_stream_group_performance_1d__reg_s0_live'
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
  '${HIVE_PATH}/dws_advertise_user_exp_live_stream_group_performance_1d';

--ads_performance_base
create or replace temporary view ads_performance_base
--cache table ads_performance_base
as
select ads_base.grass_region, user_id, 
    SUM(impression_cnt) as impression_cnt,
    SUM(view) as view,
    SUM(view_duration) as view_duration,
    SUM(raw_click_cnt) as raw_click_cnt,
    SUM(product_click) as product_click,
    SUM(cpm) as expected_ads_rev,

    SUM(order_cnt) AS order_cnt,
    SUM(broad_order_cnt) AS broad_order_cnt,
    SUM(broad_item_cnt) AS broad_item_cnt,
    SUM(ads_item_sold_cnt) AS ads_item_sold_cnt,
    SUM(daily_order_amount) AS daily_order_amount,

    SUM(expenditure_amt_local) as ads_rev,
    SUM(ads_order_gmv_local) AS ads_order_gmv_local,
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
      end) as ads_order_gmv_usd_200,

    SUM(expense_free_credit_with_expiry) AS expense_free_credit_with_expiry,
    SUM(expense_free_credit_without_expiry) AS expense_free_credit_without_expiry,
    SUM(expense_paid_credit_with_expiry) AS expense_paid_credit_with_expiry,
    SUM(expense_paid_credit_without_expiry) AS expense_paid_credit_without_expiry,
    SUM(deduct_impression) as ads_deduct_imp_cnt,
    SUM(agent_gmv) as agent_gmv_amt_local,
    SUM(agent_order) as agent_order_cnt,
    SUM(agent_item_sold_cnt) as agent_item_cnt,
    SUM(agent_checkout) as agent_checkout,
    SUM(checkout) AS checkout,
    SUM(case when location between 0 and 4 then view end) as view1_5,
    SUM(case when location between 5 and 9 then view end) as view6_10,
    SUM(case when location between 10 and 14 then view end) as view11_15,
    SUM(case when location between 15 and 19 then view end) as view16_20,
    SUM(case when location between 20 and 24 then view end) as view21_25,
    SUM(case when location between 25 and 29 then view end) as view26_30,
    SUM(case when location >= 30 then view end) as view30_plus
from
(
  select grass_region, user_id, 
  impression as impression_cnt,
  click as click_cnt,
  order as order_cnt,
  order_gmv as ads_order_gmv_local,
  ads_expenditure as expenditure_amt_local,
  order_gmv_usd as ads_order_gmv_usd,
  item_sold_cnt as ads_item_sold_cnt,
  broad_order as broad_order_cnt,
  expense_free_credit_with_expiry,expense_free_credit_without_expiry,
  expense_paid_credit_with_expiry,expense_paid_credit_without_expiry,
  view,view_duration,
  product_click,
  raw_click as raw_click_cnt,
  broad_item_sold_cnt as broad_item_cnt,
  expense_by_cpm,
  daily_item_sold_cnt as daily_order_amount,
  daily_order as daily_order_cnt,
  daily_gmv_amt_local,
  broad_gmv as broad_gmv_amt_local,
  cpm,deduct_impression,
  agent_gmv, agent_order, agent_item_sold_cnt, agent_checkout,checkout,
  location
  --from mp_paidads.dwd_advertise_performance_di__reg_s0_live
  from mp_paidads.dwd_livestream_performance_di__reg_s0_live
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
group by ads_base.grass_region, user_id;


create or replace temporary view live_stream_group_performance
as
select grass_region,group_id, 
  SUM(impression_cnt) as impression_cnt,
  SUM(view) as view,
  count (distinct (case when view > 0 then user_id else null end)) as view_uu,
  SUM(view_duration) as view_duration,
  SUM(raw_click_cnt) as raw_click_cnt,
  count (distinct (case when raw_click_cnt > 0 then user_id else null end)) as raw_click_uu,
  SUM(product_click) as product_click,
  count (distinct (case when product_click > 0 then user_id else null end)) as product_click_uu,
  SUM(expected_ads_rev) as expected_ads_rev,

  SUM(order_cnt) AS order_cnt,
  count (distinct (case when order_cnt > 0 then user_id else null end)) as order_uu,
  SUM(broad_order_cnt) AS broad_order_cnt,
  count (distinct (case when broad_order_cnt > 0 then user_id else null end)) as broad_order_uu,
  SUM(broad_item_cnt) AS broad_item_cnt,
  count (distinct (case when broad_item_cnt > 0 then user_id else null end)) as broad_item_uu,
  SUM(ads_item_sold_cnt) AS ads_item_sold_cnt,
  count (distinct (case when ads_item_sold_cnt > 0 then user_id else null end)) as ads_item_sold_uu,
  SUM(daily_order_amount) AS daily_order_amount,
  count (distinct (case when daily_order_amount > 0 then user_id else null end)) as daily_order_amount_uu,

  SUM(ads_rev) as ads_rev, 
  SUM(ads_order_gmv_local) AS ads_order_gmv_local,
  SUM(daily_gmv_amt_local ) AS daily_gmv_amt_local,
  SUM(broad_gmv_amt_local) AS broad_gmv_amt_local,
  SUM(daily_gmv_usd_500) as daily_gmv_usd_500,
  SUM(daily_gmv_usd_200) as daily_gmv_usd_200,
  SUM(ads_order_gmv_usd_500) as ads_order_gmv_usd_500,
  SUM(ads_order_gmv_usd_200) as ads_order_gmv_usd_200,
  
  SUM(expense_free_credit_with_expiry) AS expense_free_credit_with_expiry,
  SUM(expense_free_credit_without_expiry) AS expense_free_credit_without_expiry,
  SUM(expense_paid_credit_with_expiry) AS expense_paid_credit_with_expiry,
  SUM(expense_paid_credit_without_expiry) AS expense_paid_credit_without_expiry,
  SUM(ads_deduct_imp_cnt) AS ads_deduct_imp_cnt,
  SUM(agent_gmv_amt_local) as agent_gmv_amt_local,
  SUM(agent_order_cnt) as agent_order_cnt,
  SUM(agent_item_cnt) as agent_item_cnt,
  SUM(agent_checkout) as agent_checkout,
  SUM(checkout) as checkout,
  SUM(view1_5) as view1_5,
  SUM(view6_10) as view6_10,
  SUM(view11_15) as view11_15,
  SUM(view16_20) as view16_20,
  SUM(view21_25) as view21_25,
  SUM(view26_30) as view26_30,
  SUM(view30_plus) as view30_plus
from (
    select tab1.*,group_id from
    (
        select * from ads_performance_base
    ) tab1
    inner join 
    (
        select * from mp_paidads.dim_live_stream_abtest_group__reg_s0_live
        where grass_date =  date('${grass_date}') 
          and grass_region=upper('${region}')
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by grass_region, group_id;



insert overwrite table dws_advertise_user_exp_live_stream_group_performance_1d__reg_s0_live 
partition (tz_type='local', grass_region, grass_date)
select group_id, 
impression_cnt as ads_imp_cnt,
view as ads_view_cnt,
view_uu as ads_view_uu,
view_duration as ads_view_duration,
raw_click_cnt as ads_raw_click_cnt,
raw_click_uu as ads_raw_click_uu,
product_click as ads_product_click_cnt,
product_click_uu as ads_product_click_uu,
expected_ads_rev / impression_cnt / 1000 as expected_cpm,
order_cnt as ads_direct_order_cnt,
order_uu as ads_direct_order_uu,
broad_order_cnt as ads_broad_order_cnt,
broad_order_uu as ads_broad_order_uu, 
broad_item_cnt as ads_broad_item_sold_cnt,
broad_item_uu as ads_broad_item_sold_uu,
ads_item_sold_cnt as ads_direct_item_sold_cnt,
ads_item_sold_uu as ads_direct_item_sold_uu,
daily_order_amount as ads_daily_item_sold_cnt,
daily_order_amount_uu as ads_daily_item_sold_uu,

ads_rev as ads_revenue,
ads_rev / exchange_rate as ads_revenue_usd,
daily_gmv_amt_local as ads_daily_gmv,
daily_gmv_amt_local / exchange_rate as ads_daily_gmv_usd,
daily_gmv_usd_500 as ads_daily_gmv_usd_500,
daily_gmv_usd_200 as ads_daily_gmv_usd_200,
broad_gmv_amt_local as ads_broad_gmv,
broad_gmv_amt_local / exchange_rate as ads_broad_gmv_usd,
ads_order_gmv_local as ads_direct_gmv,
ads_order_gmv_local / exchange_rate as ads_direct_gmv_usd,
ads_order_gmv_usd_500 as ads_direct_gmv_usd_500,
ads_order_gmv_usd_200 as ads_direct_gmv_usd_200,
  
expense_free_credit_with_expiry,
expense_free_credit_without_expiry,
expense_paid_credit_with_expiry,
expense_paid_credit_without_expiry,
ads_deduct_imp_cnt,
agent_gmv_amt_local,agent_order_cnt,agent_item_cnt,agent_checkout,
agent_gmv_amt_local / exchange_rate as agent_gmv_usd,
checkout as checkout_cnt,
view1_5,
view6_10,
view11_15,
view16_20,
view21_25,
view26_30,
view30_plus,
ads_performance.grass_region, 
date('${grass_date}')  as grass_date
from (
    select * from live_stream_group_performance
) ads_performance
LEFT OUTER JOIN 
(
    select * from mp_order.dim_exchange_rate__reg_s0_live
    where grass_date =  date('${grass_date}') 
    and grass_region=upper('${region}')
) exchange_rate
ON ads_performance.grass_region = exchange_rate.grass_region;