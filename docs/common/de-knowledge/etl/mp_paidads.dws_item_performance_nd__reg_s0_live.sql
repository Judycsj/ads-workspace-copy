-- task_code: data_paidadsmart.studio_10205324  asset_id: 10205324
CREATE EXTERNAL TABLE IF NOT EXISTS dws_item_performance_nd__reg_s0_live
(
    item_id bigint comment 'item id'
    ,shop_id bigint comment 'shop id'
    ,item_create_timestamp bigint comment 'item create timestamp'
    ,item_create_datetime string comment 'item create datetime'
    ,level1_category_id bigint comment 'level1 category id'
    ,level1_category_name string comment 'level1 category name'
    ,level2_category_id bigint comment 'level2 category id'
    ,level2_category_name string comment 'level2 category name'
    ,level3_category_id bigint comment 'level3 category id'
    ,level3_category_name string comment 'level3 category name'
    ,is_ads_item_1d tinyint comment 'item had product ads in last 1 day'
    ,is_ads_item_7d tinyint comment 'item had product ads in last 7 days'
    ,is_gms_ads_item_1d tinyint comment 'item had gms ads in last 1 day'
    ,is_new_item_30d tinyint comment 'Item creation time is within 30 days'
    ,platform_impression_cnt_1d bigint comment 'platform impression cnt 1d'
    ,platform_impression_cnt_7d bigint comment 'platform impression cnt 7d'
    ,platform_impression_cnt_30d bigint comment 'platform impression cnt 30d'
    ,platform_click_cnt_1d bigint comment 'platform click cnt 1d'
    ,platform_click_cnt_7d bigint comment 'platform click cnt 7d'
    ,platform_click_cnt_30d bigint comment 'platform click cnt 30d'
    ,platform_order_cnt_1d bigint comment 'platform order cnt 1d'
    ,platform_order_cnt_7d bigint comment 'platform order cnt 7d'
    ,platform_order_cnt_14d  bigint comment 'platform order cnt 14d'
    ,platform_order_cnt_30d bigint comment 'platform order cnt 30d'
    ,platform_gmv_usd_1d double comment 'platform gmv usd 1d'
    ,platform_gmv_usd_7d double comment 'platform gmv usd 7d'
    ,platform_gmv_usd_14d double comment 'platform gmv usd 14d'
    ,platform_gmv_usd_30d double comment 'platform gmv usd 30d'
    ,ads_impression_cnt_1d bigint comment 'ads impression cnt 1d'
    ,ads_impression_cnt_7d bigint comment 'ads impression cnt 7d'
    ,ads_impression_cnt_30d bigint comment 'ads impression cnt 30d'
    ,ads_click_cnt_1d bigint comment 'ads click cnt 1d'
    ,ads_click_cnt_7d bigint comment 'ads click cnt 7d'
    ,ads_click_cnt_30d bigint comment 'ads click cnt 30d'
    ,ads_broad_order_cnt_1d bigint comment 'ads broad order cnt 1d'
    ,ads_broad_order_cnt_7d bigint comment 'ads broad order cnt 7d'
    ,ads_broad_order_cnt_30d bigint comment 'ads broad order cnt 30d'
    ,ads_expenditure_amt_local_1d double comment 'ads expenditure amt local 1d'
    ,ads_expenditure_amt_local_7d double comment 'ads expenditure amt local 7d'
    ,ads_expenditure_amt_local_30d double comment 'ads expenditure amt local 30d'
    ,ads_expenditure_amt_usd_1d double comment 'ads expenditure amt usd 1d'
    ,ads_expenditure_amt_usd_7d double comment 'ads expenditure amt usd 7d'
    ,ads_expenditure_amt_usd_30d double comment 'ads expenditure amt usd 30d'
    ,ads_broad_gmv_amt_local_1d double comment 'ads broad gmv amt local 1d'
    ,ads_broad_gmv_amt_local_7d double comment 'ads broad gmv amt local 7d'
    ,ads_broad_gmv_amt_local_30d double comment 'ads broad gmv amt local 30d'
    ,ads_broad_gmv_amt_usd_1d double comment 'ads broad gmv amt usd 1d'
    ,ads_broad_gmv_amt_usd_7d double comment 'ads broad gmv amt usd 7d'
    ,ads_broad_gmv_amt_usd_30d double comment 'ads broad gmv amt usd 30d'
    ,ads_paid_broad_order_cnt_1d bigint comment 'ads paid broad order cnt 1d'
    ,ads_paid_broad_order_cnt_7d bigint comment 'ads paid broad order cnt 7d'
    ,ads_paid_broad_order_cnt_30d bigint comment 'ads paid broad order cnt 30d'
    ,ads_paid_broad_order_gmv_1d double comment 'ads paid broad order gmv 1d'
    ,ads_paid_broad_order_gmv_7d double comment 'ads paid broad order gmv 7d'
    ,ads_paid_broad_order_gmv_30d double comment 'ads paid broad order gmv 30d'
    ,ads_paid_broad_order_gmv_usd_1d double comment 'ads paid broad order gmv usd 1d'
    ,ads_paid_broad_order_gmv_usd_7d double comment 'ads paid broad order gmv usd 7d'
    ,ads_paid_broad_order_gmv_usd_30d double comment 'ads paid broad order gmv usd 30d'
    ,gross_ads_revenue_usd_1d double comment 'ads gross revenue usd 1d'
    ,gross_ads_revenue_usd_7d double comment 'ads gross revenue usd 7d'
    ,gross_ads_revenue_usd_30d double comment 'ads gross revenue usd 30d'
)
COMMENT 'table for item nd metrics'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dws_item_performance_nd__reg_s0_live/'
;

create or replace temporary view  item_base_data as (
select 
    item_id
    ,SUM(CASE WHEN is_today = 1 THEN impression_cnt ELSE 0 END ) AS platform_impression_cnt_1d
    ,SUM(CASE WHEN is_7d = 1 THEN impression_cnt ELSE 0 END ) AS platform_impression_cnt_7d
    ,SUM(CASE WHEN is_30d = 1 THEN impression_cnt ELSE 0 END ) AS platform_impression_cnt_30d
    ,SUM(CASE WHEN is_today = 1 THEN click_cnt ELSE 0 END ) AS platform_click_cnt_1d
    ,SUM(CASE WHEN is_7d = 1 THEN click_cnt ELSE 0 END ) AS platform_click_cnt_7d
    ,SUM(CASE WHEN is_30d = 1 THEN click_cnt ELSE 0 END ) AS platform_click_cnt_30d
    ,SUM(CASE WHEN is_today = 1 THEN order_cnt_1d ELSE 0 END ) AS platform_order_cnt_1d
    ,SUM(CASE WHEN is_7d = 1 THEN order_cnt_1d ELSE 0 END ) AS platform_order_cnt_7d
    ,SUM(CASE WHEN is_14d = 1 THEN order_cnt_1d ELSE 0 END ) AS platform_order_cnt_14d
    ,SUM(CASE WHEN is_30d = 1 THEN order_cnt_1d ELSE 0 END ) AS platform_order_cnt_30d
    ,SUM(CASE WHEN is_today = 1 THEN gmv_usd_1d ELSE 0.0 END ) AS platform_gmv_usd_1d
    ,SUM(CASE WHEN is_7d = 1 THEN gmv_usd_1d ELSE 0.0 END ) AS platform_gmv_usd_7d
    ,SUM(CASE WHEN is_14d = 1 THEN gmv_usd_1d ELSE 0.0 END ) AS platform_gmv_usd_14d
    ,SUM(CASE WHEN is_30d = 1 THEN gmv_usd_1d ELSE 0.0 END ) AS platform_gmv_usd_30d
    FROM (
        SELECT  
            item_id
            ,item_click_cnt_1d as click_cnt
            ,item_impr_cnt_1d as impression_cnt
            ,gmv_usd_1d as gmv_usd_1d
            ,order_1d as order_cnt_1d
            ,CASE WHEN local_date = DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_today
            ,CASE WHEN local_date BETWEEN DATE('${PREV_7D}') AND DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_7d
            ,CASE WHEN local_date BETWEEN DATE('${PREV_14D}') AND DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_14d
            ,CASE WHEN local_date BETWEEN DATE('${PREV_30D}') AND DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_30d
        from traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live
        where
            local_date >= date '${PREV_30D}'
            and local_date <= date '${BIZ_YESTERDAY}'
            and grass_region = upper('${region}')
    )
    GROUP BY item_id
)
;

create or replace temporary view  dim_item as (
select 
    shop_id
    ,item_id
    ,create_timestamp as item_create_timestamp
    ,create_datetime as item_create_datetime
    ,level1_global_be_category_id as level1_category_id
    ,level1_global_be_category as level1_category_name
    ,level2_global_be_category_id as level2_category_id
    ,level2_global_be_category as level2_category_name
    ,level3_global_be_category_id as level3_category_id
    ,level3_global_be_category as level3_category_name
from mp_item.dim_item__reg_s0_live
where 
    tz_type = 'local'
    and grass_region = upper('${region}')
    and grass_date = date('${BIZ_YESTERDAY}')
);

create or replace temporary view  dim_ads_item as (
select 
    item_id
    ,1 as is_ads_item_7d
    ,max(case when grass_date = date('${BIZ_YESTERDAY}') then 1 end) as is_ads_item_1d
    ,max(case when grass_date = date('${BIZ_YESTERDAY}') and pricing_type in (24,27) then 1 end) as is_gms_ads_item_1d
from mp_paidads.dim_advertise__reg_s0_live
where 
    tz_type = 'local'
    and grass_region = upper('${region}')
    and grass_date between date('${PREV_7D}') and date('${BIZ_YESTERDAY}')
    and item_id > 0
    and main_product_type = 'Product Ads'
    and is_ads_active = 1
group by 1
);



create or replace temporary view  item_ads_data as (
select item_id
        ,SUM(CASE WHEN is_today = 1 THEN impression_cnt ELSE 0 END ) AS ads_impression_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN impression_cnt ELSE 0 END ) AS ads_impression_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN impression_cnt ELSE 0 END ) AS ads_impression_cnt_30d
        ,SUM(CASE WHEN is_today = 1 THEN click_cnt ELSE 0 END ) AS ads_click_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN click_cnt ELSE 0 END ) AS ads_click_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN click_cnt ELSE 0 END ) AS ads_click_cnt_30d
        ,SUM(CASE WHEN is_today = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_cnt_30d
        ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS ads_expenditure_amt_local_1d
        ,SUM(CASE WHEN is_7d = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS ads_expenditure_amt_local_7d
        ,SUM(CASE WHEN is_30d = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS ads_expenditure_amt_local_30d
        ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS ads_expenditure_amt_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS ads_expenditure_amt_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS ads_expenditure_amt_usd_30d
        ,SUM(CASE WHEN is_today = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS ads_broad_gmv_amt_local_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS ads_broad_gmv_amt_local_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS ads_broad_gmv_amt_local_30d
        ,SUM(CASE WHEN is_today = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_amt_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_amt_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_amt_usd_30d
        ,SUM(CASE WHEN is_today = 1 THEN paid_broad_order_cnt ELSE 0 END ) AS ads_paid_broad_order_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN paid_broad_order_cnt ELSE 0 END ) AS ads_paid_broad_order_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN paid_broad_order_cnt ELSE 0 END ) AS ads_paid_broad_order_cnt_30d
        ,SUM(CASE WHEN is_today = 1 THEN paid_broad_order_gmv ELSE 0 END ) AS ads_paid_broad_order_gmv_1d
        ,SUM(CASE WHEN is_7d = 1 THEN paid_broad_order_gmv ELSE 0 END ) AS ads_paid_broad_order_gmv_7d
        ,SUM(CASE WHEN is_30d = 1 THEN paid_broad_order_gmv ELSE 0 END ) AS ads_paid_broad_order_gmv_30d
        ,SUM(CASE WHEN is_today = 1 THEN paid_broad_order_gmv_usd ELSE 0 END ) AS ads_paid_broad_order_gmv_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN paid_broad_order_gmv_usd ELSE 0 END ) AS ads_paid_broad_order_gmv_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN paid_broad_order_gmv_usd ELSE 0 END ) AS ads_paid_broad_order_gmv_usd_30d

    FROM (
        SELECT  
            item_id
            ,shop_id
            ,impression_cnt_1d AS impression_cnt
            ,click_cnt_1d AS click_cnt
            ,order_cnt_1d AS order_cnt
            ,broad_order_cnt_1d AS broad_order_cnt
            ,expenditure_amt_local_1d AS expenditure_amt_local
            ,expenditure_amt_usd_1d AS expenditure_amt_usd
            ,broad_gmv_amt_local_1d AS broad_gmv_amt_local
            ,broad_gmv_amt_usd_1d AS broad_gmv_amt_usd
            ,paid_broad_order_cnt
            ,paid_broad_order_gmv
            ,paid_broad_order_gmv_usd
            ,CASE WHEN grass_date = DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_today
            ,CASE WHEN grass_date BETWEEN DATE('${PREV_7D}') AND DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_7d
            ,CASE WHEN grass_date BETWEEN DATE('${PREV_30D}') AND DATE('${BIZ_YESTERDAY}') THEN 1 ELSE 0 END AS is_30d
        FROM mp_paidads.dws_advertise_performance_1d__reg_s0_live
        WHERE 
            tz_type = 'local'
            and grass_region = upper('${region}')
            and grass_date BETWEEN DATE('${PREV_30D}') AND DATE('${BIZ_YESTERDAY}')
    )
    GROUP BY item_id
)
;


create or replace temporary view  item_gross_ads_revenue as (
select 
    item_id 
    ,sum(gross_ads_revenue_usd_1d) as gross_ads_revenue_usd_1d
    ,sum(gross_ads_revenue_usd_7d) as gross_ads_revenue_usd_7d
    ,sum(gross_ads_revenue_usd_30d) as gross_ads_revenue_usd_30d
from
( 
    select 
        ads_id 
        ,sum(case when grass_date = DATE('${BIZ_YESTERDAY}') then gross_ads_revenue_usd_1d end) as gross_ads_revenue_usd_1d
        ,sum(case when grass_date BETWEEN DATE('${PREV_7D}') AND DATE('${BIZ_YESTERDAY}') then gross_ads_revenue_usd_1d end) as gross_ads_revenue_usd_7d
        ,sum(gross_ads_revenue_usd_1d) as gross_ads_revenue_usd_30d
    from mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
    WHERE 
        tz_type = 'local'
        and grass_region = upper('${region}')
        and grass_date BETWEEN DATE('${PREV_30D}') AND DATE('${BIZ_YESTERDAY}')
        and gross_ads_revenue_usd_1d > 0
    group by 1
) a 
left join (
    select distinct
        ads_id
        ,item_id
    from mp_paidads.dim_advertise__reg_s0_live
    where 
        tz_type = 'local'
        and grass_region = upper('${region}')
        and grass_date between date('${PREV_7D}') and date('${BIZ_YESTERDAY}')
        and item_id > 0
) b 
on a.ads_id = b.ads_id
group by item_id
);

INSERT OVERWRITE TABLE dws_item_performance_nd__reg_s0_live PARTITION (tz_type = 'local', grass_region, grass_date)
SELECT
    a.item_id
    ,b.shop_id
    ,item_create_timestamp
    ,item_create_datetime
    ,level1_category_id
    ,level1_category_name
    ,level2_category_id
    ,level2_category_name
    ,level3_category_id
    ,level3_category_name
    ,coalesce(is_ads_item_1d, 0) as is_ads_item_1d
    ,coalesce(is_ads_item_7d, 0) as is_ads_item_7d
    ,coalesce(is_gms_ads_item_1d, 0) as is_gms_ads_item_1d
    ,case when date(item_create_datetime) >=  date('${PREV_30D}') then 1 else 0 end as is_new_item_30d
    ,platform_impression_cnt_1d
    ,platform_impression_cnt_7d
    ,platform_impression_cnt_30d
    ,platform_click_cnt_1d
    ,platform_click_cnt_7d
    ,platform_click_cnt_30d
    ,platform_order_cnt_1d
    ,platform_order_cnt_7d
    ,platform_order_cnt_14d
    ,platform_order_cnt_30d
    ,platform_gmv_usd_1d
    ,platform_gmv_usd_7d
    ,platform_gmv_usd_14d
    ,platform_gmv_usd_30d
    ,ads_impression_cnt_1d
    ,ads_impression_cnt_7d
    ,ads_impression_cnt_30d
    ,ads_click_cnt_1d
    ,ads_click_cnt_7d
    ,ads_click_cnt_30d
    ,ads_broad_order_cnt_1d
    ,ads_broad_order_cnt_7d
    ,ads_broad_order_cnt_30d
    ,ads_expenditure_amt_local_1d
    ,ads_expenditure_amt_local_7d
    ,ads_expenditure_amt_local_30d
    ,ads_expenditure_amt_usd_1d
    ,ads_expenditure_amt_usd_7d
    ,ads_expenditure_amt_usd_30d
    ,ads_broad_gmv_amt_local_1d
    ,ads_broad_gmv_amt_local_7d
    ,ads_broad_gmv_amt_local_30d
    ,ads_broad_gmv_amt_usd_1d
    ,ads_broad_gmv_amt_usd_7d
    ,ads_broad_gmv_amt_usd_30d
    ,ads_paid_broad_order_cnt_1d
    ,ads_paid_broad_order_cnt_7d
    ,ads_paid_broad_order_cnt_30d
    ,ads_paid_broad_order_gmv_1d
    ,ads_paid_broad_order_gmv_7d
    ,ads_paid_broad_order_gmv_30d
    ,ads_paid_broad_order_gmv_usd_1d
    ,ads_paid_broad_order_gmv_usd_7d
    ,ads_paid_broad_order_gmv_usd_30d
    ,gross_ads_revenue_usd_1d
    ,gross_ads_revenue_usd_7d
    ,gross_ads_revenue_usd_30d
    ,upper('${region}') as grass_region
    ,DATE('${BIZ_YESTERDAY}') as grass_date
from item_base_data a 
left join dim_item b 
on a.item_id = b.item_id 
left join dim_ads_item c
on a.item_id = c.item_id 
left join item_ads_data d 
on a.item_id = d.item_id 
left join item_gross_ads_revenue e
on a.item_id = e.item_id 
;