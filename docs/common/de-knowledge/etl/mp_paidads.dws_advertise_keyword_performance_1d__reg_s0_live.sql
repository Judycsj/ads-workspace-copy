-- task_code: data_paidadsmart.studio_2521006  asset_id: 2521006
INSERT OVERWRITE TABLE dws_advertise_keyword_performance_1d__reg_s0_live PARTITION (tz_type='local', grass_region='BR', grass_date)
    SELECT  
            shop_id
            ,username
            ,item_id
            ,ads_id
            ,keywords
            ,match_type
            ,placement
            ,impression_cnt_1d
            ,click_cnt_1d
            ,expenditure_amt_local_1d
            ,expenditure_amt_usd_1d
            ,COALESCE(expenditure_amt_local_1d / click_cnt_1d, 0.0)   AS cpc_local_1d
            ,COALESCE(expenditure_amt_usd_1d / click_cnt_1d, 0.0)   AS cpc_usd_1d
            ,order_cnt_1d
            ,ads_gmv_amt_local_1d
            ,ads_gmv_amt_usd_1d
            ,COALESCE(click_cnt_1d / impression_cnt_1d, 0.0)   AS ctr_1d
            ,COALESCE(order_cnt_1d / click_cnt_1d, 0.0)   AS cr_1d
            ,COALESCE(expenditure_amt_local_1d / ads_gmv_amt_local_1d, 0.0)   AS cir_1d
            ,avg_ads_ranks_1d
            ,date('${grass_date}') AS grass_date
    FROM
    (
        SELECT  shop_id
                ,username
                ,item_id
                ,ads_id
                ,keywords
                ,match_type
                ,placement
                ,SUM(CASE WHEN is_today = 1 THEN impression_cnt ELSE 0 END ) AS impression_cnt_1d
                ,SUM(CASE WHEN is_today = 1 THEN click_cnt ELSE 0 END ) AS click_cnt_1d
                ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_local ELSE 0.0 END ) AS expenditure_amt_local_1d
                ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_usd ELSE 0.0 END ) AS expenditure_amt_usd_1d
                ,SUM(CASE WHEN is_today = 1 THEN order_cnt ELSE 0 END ) AS order_cnt_1d
                ,SUM(CASE WHEN is_today = 1 THEN ads_gmv_amt_local ELSE 0.0 END ) AS ads_gmv_amt_local_1d
                ,SUM(CASE WHEN is_today = 1 THEN ads_gmv_amt_usd ELSE 0.0 END ) AS ads_gmv_amt_usd_1d
                ,AVG(avg_ads_ranks) AS avg_ads_ranks_1d
                ,grass_region
        FROM (
            SELECT  a.shop_id AS shop_id
                    ,b.user_name AS username
                    ,a.item_id
                    ,a.ads_id
                    ,a.keywords
                    ,a.match_type
                    ,a.placement
                    ,COALESCE(impression_cnt ,0) AS impression_cnt
                    ,COALESCE(click_cnt,0) AS click_cnt
                    ,COALESCE(expenditure_amt_local,0.0) AS expenditure_amt_local
                    ,COALESCE(expenditure_amt_usd,0.0) AS expenditure_amt_usd
                    ,COALESCE(order_cnt,0) AS order_cnt
                    ,COALESCE(ads_gmv_amt_local,0.0) AS ads_gmv_amt_local
                    ,COALESCE(ads_gmv_amt_usd,0.0) AS ads_gmv_amt_usd
                    ,COALESCE(avg_ads_ranks,0.0) AS avg_ads_ranks
                    ,CASE WHEN a.grass_date = date('${grass_date}') THEN 1 ELSE 0 END AS is_today
                    ,a.grass_date AS grass_date
                    ,a.grass_region AS grass_region
            FROM (
                SELECT *
                FROM mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live
                WHERE grass_region = upper('${region}')
                AND grass_date = date('${grass_date}')
                AND tz_type = 'local'
            ) a
            LEFT JOIN (
                SELECT *
                FROM mp_paidads.dim_advertiser__reg_s0_live
                WHERE grass_region = upper('${region}')
                AND grass_date = date('${grass_date}')
            ) b
            ON a.shop_id = b.shop_id
            AND a.grass_region = b.grass_region
        )
        GROUP BY 1, 2, 3, 4, 5, 6, 7, grass_region
    );

alter table dws_advertise_keyword_performance_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");