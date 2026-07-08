-- task_code: data_paidadsmart.studio_5632093  asset_id: 5632093
CREATE EXTERNAL TABLE if not exists dws_advertise_user_exp_entrance_performance_1d__reg_s0_live (
  `group_id` bigint COMMENT 'user experiment group id',
  `entrance` string COMMENT 'entrance',
  `ads_imp_cnt` bigint COMMENT 'ads impression count',
  `ads_clk_cnt` bigint COMMENT 'ads click count',
  `ads_order_cnt` bigint COMMENT 'ads direct order count',
  `ads_gmv_usd` decimal(25, 10) COMMENT 'ads direct order gmv usd',
  `ads_revenue_usd` decimal(25, 10) COMMENT 'ads revenue usd',
  `organic_imp_cnt` bigint COMMENT 'organic imp count',
  `organic_clk_cnt` bigint COMMENT 'organic click count',
  `organic_order_cnt` bigint COMMENT 'organic order count',
  `organic_gmv_usd` decimal(25, 10) COMMENT 'organic gmv usd'
  )
COMMENT 'paid_ads_dws_advertise_user_entrance_exp_performance_1d'
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
  '${HIVE_PATH}/dws_advertise_user_exp_entrance_performance_1d';

--ads_performance_base
create or replace temporary view ads_performance_base
as
select grass_region,entrance,user_id,
impression_cnt,click_cnt,order_cnt,ads_order_gmv_local,expenditure_amt_local
from mp_paidads.dwd_advertise_performance_di__reg_s0_live
where grass_date =  date('${grass_date}') 
and grass_region=upper('${region}')
and entrance in (1,3,4);

--search group 
create or replace temporary view search_group
as
select user_id, exp_group_id as group_id 
from srdi_mart.dim_sr_data_warehouse_abtest_user_group
where local_date = date('${grass_date}') 
and grass_region=upper('${region}')
and user_id is not null and user_id != 0
and is_assignment_log = 1
group by user_id, exp_group_id
;

--dd&&ymal group
create or replace temporary view dd_ymal_group
as
select user_id, exp_group_id as group_id 
from srdi_mart.dim_sr_data_warehouse_abtest_user_group
where local_date = date('${grass_date}') 
and grass_region = upper('${region}')
and user_id is not null and user_id != 0
and is_dim_join = 1
group by user_id, exp_group_id
;


--/dd/ymal organic imp+gmv
create or replace temporary view dd_ymal_organic_base
as
select 
user_id,impr_organic_cnt_1d,click_organic_cnt_1d, order_organic_1d, 
gmv_usd_organic_1d, 3 as entrance
from traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live
where local_date = date('${grass_date}') 
and grass_region = upper('${region}')
and business_line = 'Homepage'
and module = 'Daily Discover'
and object = 'item card'

union all

select 
user_id,impr_organic_cnt_1d,click_organic_cnt_1d, order_organic_1d, 
gmv_usd_organic_1d, 4 as entrance
from traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live
where local_date = date('${grass_date}') 
and grass_region = upper('${region}')
and business_line = 'Rcmd'
and module = 'User Scenario'
and object = 'you may also like'
and feature_detail = 'product-you_may_also_like-item';

-- search organic imp+gmv
create or replace temporary view search_organic_base
as
select
user_id, item_impr_organic_cnt_1d, item_click_organic_cnt_1d, order_organic_1d, 
gmv_usd_organic_1d , 1 as entrance
from traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live
where local_date = date('${grass_date}') 
and grass_region = upper('${region}')
and business_line = 'Search'
and module = 'Global Search'
and feature_detail like '%-item';

create or replace temporary view search_organic_group_performance
as
select entrance, group_id,
SUM(item_impr_organic_cnt_1d) as organic_imp_cnt,
SUM(item_click_organic_cnt_1d) as organic_clk_cnt,
SUM(order_organic_1d) AS organic_order_cnt,
SUM(gmv_usd_organic_1d) AS organic_gmv_usd
from (
    select entrance, group_id,
    item_impr_organic_cnt_1d, item_click_organic_cnt_1d, order_organic_1d, gmv_usd_organic_1d from
    (
        select * from search_organic_base
    ) tab1
    inner join 
    (
        select * from search_group
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by entrance, group_id;

create or replace temporary view dd_ymal_organic_group_performance
as
select entrance, group_id,
SUM(impr_organic_cnt_1d) as organic_imp_cnt,
SUM(click_organic_cnt_1d) as organic_clk_cnt,
SUM(order_organic_1d) AS organic_order_cnt,
SUM(gmv_usd_organic_1d) AS organic_gmv_usd
from (
    select entrance, group_id,
    impr_organic_cnt_1d,click_organic_cnt_1d, order_organic_1d, gmv_usd_organic_1d from
    (
        select * from dd_ymal_organic_base
    ) tab1
    inner join 
    (
        select * from dd_ymal_group
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by entrance, group_id;

create or replace temporary view search_group_performance
as
select grass_region,entrance, group_id,
SUM(impression_cnt) as ads_imp_cnt,
SUM(click_cnt) as ads_clk_cnt,
SUM(order_cnt) AS ads_order_cnt,
SUM(ads_order_gmv_local) AS ads_gmv_local,
SUM(expenditure_amt_local) AS expenditure_amt_local
from (
    select grass_region,entrance, group_id,
    impression_cnt,click_cnt,order_cnt,ads_order_gmv_local,expenditure_amt_local from
    (
        select * from ads_performance_base
        where entrance in (1)
    ) tab1
    inner join 
    (
        select * from search_group
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by grass_region,entrance, group_id;

create or replace temporary view dd_ymal_group_performance
as
select grass_region,entrance, group_id,
SUM(impression_cnt) as ads_imp_cnt,
SUM(click_cnt) as ads_clk_cnt,
SUM(order_cnt) AS ads_order_cnt,
SUM(ads_order_gmv_local) AS ads_gmv_local,
SUM(expenditure_amt_local) AS expenditure_amt_local
from (
    select grass_region,entrance, group_id,
    impression_cnt,click_cnt,order_cnt,ads_order_gmv_local,expenditure_amt_local from
    (
        select * from ads_performance_base
        where entrance in (3,4)
    ) tab1
    inner join 
    (
        select * from dd_ymal_group
    ) tab2
    on  tab1.user_id = tab2.user_id
) group by grass_region,entrance, group_id;

insert overwrite table dws_advertise_user_exp_entrance_performance_1d__reg_s0_live 
partition (tz_type='local', grass_region, grass_date)
select ads_performance.group_id, 
CASE
    WHEN ads_performance.entrance = 1     THEN 'search'
    WHEN ads_performance.entrance = 3     THEN 'dd'
    WHEN ads_performance.entrance = 4     THEN 'ymal'
    ELSE NULL
END AS entrance,
ads_imp_cnt,ads_clk_cnt,ads_order_cnt,ads_gmv_local/exchange_rate as ads_gmv_usd,
expenditure_amt_local/exchange_rate as ads_revenue_usd,
organic_imp_cnt,organic_clk_cnt,organic_order_cnt,organic_gmv_usd,
ads_performance.grass_region, date('${grass_date}')  as grass_date
from (
    select * from dd_ymal_group_performance
    union all
    select * from search_group_performance
) ads_performance
LEFT OUTER JOIN 
(
    select * from dd_ymal_organic_group_performance
    union all
    select * from search_organic_group_performance
) organic_performance
ON ads_performance.entrance = organic_performance.entrance 
and ads_performance.group_id = organic_performance.group_id 
LEFT OUTER JOIN 
(
    select * from mp_order.dim_exchange_rate__reg_s0_live
    where grass_date =  date('${grass_date}') 
    and grass_region=upper('${region}')
) exchange_rate
ON ads_performance.grass_region = exchange_rate.grass_region;