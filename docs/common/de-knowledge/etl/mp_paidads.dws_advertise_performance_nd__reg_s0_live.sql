-- task_code: data_paidadsmart.studio_2525992  asset_id: 2525992
INSERT OVERWRITE TABLE dws_advertise_performance_nd__reg_s0_live PARTITION (tz_type, grass_region, grass_date)
SELECT
    ads_id
     ,placement
     ,ads_type
     ,shop_id
     ,seller_id
     ,impression_cnt_1d
     ,impression_cnt_7d
     ,impression_cnt_30d
     ,impression_cnt_60d
     ,impression_cnt_90d
     ,click_cnt_1d
     ,click_cnt_7d
     ,click_cnt_30d
     ,click_cnt_60d
     ,click_cnt_90d
     ,order_cnt_1d
     ,order_cnt_7d
     ,order_cnt_30d
     ,order_cnt_60d
     ,order_cnt_90d
     ,paid_order_cnt_ytd_1d
     ,confirmed_order_cnt_ytd_1d
     ,ads_items_sold_cnt_1d
     ,ads_items_sold_cnt_7d
     ,ads_items_sold_cnt_30d
     ,ads_items_sold_cnt_60d
     ,ads_items_sold_cnt_90d
     ,ads_gmv_amt_local_1d
     ,ads_gmv_amt_local_7d
     ,ads_gmv_amt_local_30d
     ,ads_gmv_amt_local_60d
     ,ads_gmv_amt_local_90d
     ,ads_gmv_amt_usd_1d
     ,ads_gmv_amt_usd_7d
     ,ads_gmv_amt_usd_30d
     ,ads_gmv_amt_usd_60d
     ,ads_gmv_amt_usd_90d
     ,expenditure_amt_local_1d
     ,expenditure_amt_local_7d
     ,expenditure_amt_local_30d
     ,expenditure_amt_local_60d
     ,expenditure_amt_local_90d
     ,expenditure_amt_usd_1d
     ,expenditure_amt_usd_7d
     ,expenditure_amt_usd_30d
     ,expenditure_amt_usd_60d
     ,expenditure_amt_usd_90d
     ,COALESCE(click_cnt_1d / impression_cnt_1d, 0.0)   AS ctr_1d
     ,COALESCE(click_cnt_7d / impression_cnt_7d, 0.0)   AS ctr_7d
     ,COALESCE(click_cnt_30d / impression_cnt_30d, 0.0) AS ctr_30d
     ,COALESCE(click_cnt_60d / impression_cnt_60d, 0.0) AS ctr_60d
     ,COALESCE(click_cnt_90d / impression_cnt_90d, 0.0) AS ctr_90d
     ,COALESCE(expenditure_amt_local_1d / ads_gmv_amt_local_1d, 0.0)   AS cir_1d
     ,COALESCE(expenditure_amt_local_7d / ads_gmv_amt_local_7d, 0.0)   AS ctr_7d
     ,COALESCE(expenditure_amt_local_30d / ads_gmv_amt_local_30d, 0.0) AS ctr_30d
     ,COALESCE(expenditure_amt_local_60d / ads_gmv_amt_local_60d, 0.0) AS ctr_60d
     ,COALESCE(expenditure_amt_local_90d / ads_gmv_amt_local_90d, 0.0) AS ctr_90d
     ,COALESCE(order_cnt_1d / click_cnt_1d, 0.0)   AS cr_1d
     ,COALESCE(order_cnt_7d / click_cnt_7d, 0.0)   AS cr_7d
     ,COALESCE(order_cnt_30d / click_cnt_30d, 0.0) AS cr_30d
     ,COALESCE(order_cnt_60d / click_cnt_60d, 0.0) AS cr_60d
     ,COALESCE(order_cnt_90d / click_cnt_90d, 0.0) AS cr_90d
     ,COALESCE(expenditure_amt_local_1d / click_cnt_1d, 0.0)   AS cpc_local_1d
     ,COALESCE(expenditure_amt_local_7d / click_cnt_7d, 0.0)   AS cpc_local_7d
     ,COALESCE(expenditure_amt_local_30d / click_cnt_30d, 0.0) AS cpc_local_30d
     ,COALESCE(expenditure_amt_local_60d / click_cnt_60d, 0.0) AS cpc_local_60d
     ,COALESCE(expenditure_amt_local_90d / click_cnt_90d, 0.0) AS cpc_local_90d
     ,COALESCE(expenditure_amt_usd_1d / click_cnt_1d, 0.0)   AS cpc_usd_1d
     ,COALESCE(expenditure_amt_usd_7d / click_cnt_7d, 0.0)   AS cpc_usd_7d
     ,COALESCE(expenditure_amt_usd_30d / click_cnt_30d, 0.0) AS cpc_usd_30d
     ,COALESCE(expenditure_amt_usd_60d / click_cnt_60d, 0.0) AS cpc_usd_60d
     ,COALESCE(expenditure_amt_usd_90d / click_cnt_90d, 0.0) AS cpc_usd_90d
     ,COALESCE(ads_gmv_amt_local_1d / expenditure_amt_local_1d, 0.0)   AS roi_1d
     ,COALESCE(ads_gmv_amt_local_7d / expenditure_amt_local_7d, 0.0)   AS roi_7d
     ,COALESCE(ads_gmv_amt_local_30d / expenditure_amt_local_30d, 0.0) AS roi_30d
     ,COALESCE(ads_gmv_amt_local_60d / expenditure_amt_local_60d, 0.0) AS roi_60d
     ,COALESCE(ads_gmv_amt_local_90d / expenditure_amt_local_90d, 0.0) AS roi_90d
     ,broad_gmv_amt_local_1d
     ,broad_gmv_amt_local_7d
     ,broad_gmv_amt_local_30d
     ,broad_gmv_amt_local_60d
     ,broad_gmv_amt_local_90d
     ,broad_gmv_amt_usd_1d
     ,broad_gmv_amt_usd_7d
     ,broad_gmv_amt_usd_30d
     ,broad_gmv_amt_usd_60d
     ,broad_gmv_amt_usd_90d
     ,COALESCE(broad_gmv_amt_local_1d / expenditure_amt_local_1d, 0.0)   AS broad_roi_1d
     ,COALESCE(broad_gmv_amt_local_7d / expenditure_amt_local_7d, 0.0)   AS broad_roi_7d
     ,COALESCE(broad_gmv_amt_local_30d / expenditure_amt_local_30d, 0.0) AS broad_roi_30d
     ,COALESCE(broad_gmv_amt_local_60d / expenditure_amt_local_60d, 0.0) AS broad_roi_60d
     ,COALESCE(broad_gmv_amt_local_90d / expenditure_amt_local_90d, 0.0) AS broad_roi_90d
     ,broad_order_cnt_1d
     ,broad_order_cnt_7d
     ,broad_order_cnt_30d
     ,broad_order_cnt_60d
     ,broad_order_cnt_90d
     ,tz_type
     ,upper('${region}') as grass_region
     ,DATE('${grass_date}') AS grass_date
FROM
    (
    SELECT   tz_type
        ,ads_id
        ,placement
        ,ads_type
        ,shop_id
        ,seller_id
        ,SUM(CASE WHEN is_today = 1 THEN impression_cnt ELSE 0 END ) AS impression_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN impression_cnt ELSE 0 END ) AS impression_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN impression_cnt ELSE 0 END ) AS impression_cnt_30d
        ,SUM(CASE WHEN is_60d = 1 THEN impression_cnt ELSE 0 END ) AS impression_cnt_60d
        ,SUM(CASE WHEN is_90d = 1 THEN impression_cnt ELSE 0 END ) AS impression_cnt_90d
        ,SUM(CASE WHEN is_today = 1 THEN click_cnt ELSE 0 END ) AS click_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN click_cnt ELSE 0 END ) AS click_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN click_cnt ELSE 0 END ) AS click_cnt_30d
        ,SUM(CASE WHEN is_60d = 1 THEN click_cnt ELSE 0 END ) AS click_cnt_60d
        ,SUM(CASE WHEN is_90d = 1 THEN click_cnt ELSE 0 END ) AS click_cnt_90d
        ,SUM(CASE WHEN is_today = 1 THEN order_cnt ELSE 0 END ) AS order_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN order_cnt ELSE 0 END ) AS order_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN order_cnt ELSE 0 END ) AS order_cnt_30d
        ,SUM(CASE WHEN is_60d = 1 THEN order_cnt ELSE 0 END ) AS order_cnt_60d
        ,SUM(CASE WHEN is_90d = 1 THEN order_cnt ELSE 0 END ) AS order_cnt_90d
        ,SUM(CASE WHEN is_today = 1 THEN paid_order_cnt_ytd ELSE 0 END ) AS paid_order_cnt_ytd_1d
        ,SUM(CASE WHEN is_today = 1 THEN confirmed_order_cnt_ytd ELSE 0 END ) AS confirmed_order_cnt_ytd_1d
        ,SUM(CASE WHEN is_today = 1 THEN ads_items_sold_cnt ELSE 0 END ) AS ads_items_sold_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN ads_items_sold_cnt ELSE 0 END ) AS ads_items_sold_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN ads_items_sold_cnt ELSE 0 END ) AS ads_items_sold_cnt_30d
        ,SUM(CASE WHEN is_60d = 1 THEN ads_items_sold_cnt ELSE 0 END ) AS ads_items_sold_cnt_60d
        ,SUM(CASE WHEN is_90d = 1 THEN ads_items_sold_cnt ELSE 0 END ) AS ads_items_sold_cnt_90d
        ,SUM(CASE WHEN is_today = 1 THEN ads_gmv_amt_local ELSE 0.0 END ) AS ads_gmv_amt_local_1d
        ,SUM(CASE WHEN is_7d = 1 THEN ads_gmv_amt_local ELSE 0.0 END ) AS ads_gmv_amt_local_7d
        ,SUM(CASE WHEN is_30d = 1 THEN ads_gmv_amt_local ELSE 0.0 END ) AS ads_gmv_amt_local_30d
        ,SUM(CASE WHEN is_60d = 1 THEN ads_gmv_amt_local ELSE 0.0 END ) AS ads_gmv_amt_local_60d
        ,SUM(CASE WHEN is_90d = 1 THEN ads_gmv_amt_local ELSE 0.0 END ) AS ads_gmv_amt_local_90d
        ,SUM(CASE WHEN is_today = 1 THEN ads_gmv_amt_usd ELSE 0.0 END ) AS ads_gmv_amt_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN ads_gmv_amt_usd ELSE 0.0 END ) AS ads_gmv_amt_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN ads_gmv_amt_usd ELSE 0.0 END ) AS ads_gmv_amt_usd_30d
        ,SUM(CASE WHEN is_60d = 1 THEN ads_gmv_amt_usd ELSE 0.0 END ) AS ads_gmv_amt_usd_60d
        ,SUM(CASE WHEN is_90d = 1 THEN ads_gmv_amt_usd ELSE 0.0 END ) AS ads_gmv_amt_usd_90d
        ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS expenditure_amt_local_1d
        ,SUM(CASE WHEN is_7d = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS expenditure_amt_local_7d
        ,SUM(CASE WHEN is_30d = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS expenditure_amt_local_30d
        ,SUM(CASE WHEN is_60d = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS expenditure_amt_local_60d
        ,SUM(CASE WHEN is_90d = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS expenditure_amt_local_90d
        ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS expenditure_amt_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS expenditure_amt_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS expenditure_amt_usd_30d
        ,SUM(CASE WHEN is_60d = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS expenditure_amt_usd_60d
        ,SUM(CASE WHEN is_90d = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS expenditure_amt_usd_90d
        ,SUM(CASE WHEN is_today = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS broad_gmv_amt_local_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS broad_gmv_amt_local_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS broad_gmv_amt_local_30d
        ,SUM(CASE WHEN is_60d = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS broad_gmv_amt_local_60d
        ,SUM(CASE WHEN is_90d = 1 THEN broad_gmv_amt_local ELSE 0.0 END ) AS broad_gmv_amt_local_90d
        ,SUM(CASE WHEN is_today = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS broad_gmv_amt_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS broad_gmv_amt_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS broad_gmv_amt_usd_30d
        ,SUM(CASE WHEN is_60d = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS broad_gmv_amt_usd_60d
        ,SUM(CASE WHEN is_90d = 1 THEN broad_gmv_amt_usd ELSE 0.0 END ) AS broad_gmv_amt_usd_90d
        ,SUM(CASE WHEN is_today = 1 THEN broad_order_cnt ELSE 0 END ) AS broad_order_cnt_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_order_cnt ELSE 0 END ) AS broad_order_cnt_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_order_cnt ELSE 0 END ) AS broad_order_cnt_30d
        ,SUM(CASE WHEN is_60d = 1 THEN broad_order_cnt ELSE 0 END ) AS broad_order_cnt_60d
        ,SUM(CASE WHEN is_90d = 1 THEN broad_order_cnt ELSE 0 END ) AS broad_order_cnt_90d
    FROM (
    SELECT  tz_type
        ,ads_id
        ,placement
        ,if(placement=20, 'shop_simple', ads_type) as ads_type
        ,shop_id
        ,seller_id
        ,impression_cnt_1d AS impression_cnt
        ,click_cnt_1d AS click_cnt
        ,order_cnt_1d AS order_cnt
        ,broad_order_cnt_1d AS broad_order_cnt
        ,paid_order_cnt_ytd_1d AS paid_order_cnt_ytd
        ,confirmed_order_cnt_ytd_1d AS confirmed_order_cnt_ytd
        ,ads_items_sold_cnt_1d AS ads_items_sold_cnt
        ,ads_gmv_amt_local_1d AS ads_gmv_amt_local
        ,ads_gmv_amt_usd_1d AS ads_gmv_amt_usd
        ,expenditure_amt_local_1d AS expenditure_amt_local
        ,expenditure_amt_usd_1d AS expenditure_amt_usd
        ,broad_gmv_amt_local_1d AS broad_gmv_amt_local
        ,broad_gmv_amt_usd_1d AS broad_gmv_amt_usd
        ,CASE WHEN grass_date = DATE('${grass_date}') THEN 1 ELSE 0 END AS is_today
        ,CASE WHEN grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 6 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_7d
        ,CASE WHEN grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 29 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_30d
        ,CASE WHEN grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 59 DAYS) AND DATE('${grass_date}')  THEN 1 ELSE 0 END AS is_60d
        ,CASE WHEN grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 89 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_90d
    FROM mp_paidads.dws_advertise_performance_1d__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 89 DAYS) AND DATE('${grass_date}')
    AND pricing_type!=29
    )
    GROUP BY tz_type
        ,ads_id
        ,placement
        ,ads_type
        ,shop_id
        ,seller_id
    );

alter table dws_advertise_performance_nd__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");