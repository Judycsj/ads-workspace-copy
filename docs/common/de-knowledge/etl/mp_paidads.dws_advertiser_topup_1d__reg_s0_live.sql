-- task_code: data_paidadsmart.studio_2668191  asset_id: 2668191
set time zone 'Asia/Singapore';
create or replace temporary view base as 
SELECT
    'local' as tz_type
    ,grass_region
    ,shop_id
    ,user_id
    ,order_id
    ,order_type
    ,credit_topup_type
    ,topup_amt
    ,topup_amt_usd
    ,topup_create_timestamp
    ,CASE
        WHEN order_type in (2,6) THEN "normal"
        WHEN order_type in (10) THEN "negative"
        WHEN order_type in (9) THEN "srm"
        WHEN order_type in (4) THEN "auto"
        WHEN order_type in (8) THEN "sellermission"
        WHEN order_type in (3) THEN "manual"
        ELSE NULL
    END AS topup_category_name
FROM mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
WHERE grass_region = upper('${region}')
AND grass_date = date('${grass_date}') 
AND date(topup_create_datetime) = date('${grass_date}') 
UNION ALL
SELECT
    'regional' as tz_type
    ,grass_region
    ,shop_id
    ,user_id
    ,order_id
    ,order_type
    ,credit_topup_type
    ,topup_amt
    ,topup_amt_usd
    ,topup_create_timestamp
    ,CASE
        WHEN order_type in (2,6) THEN "normal"
        WHEN order_type in (10) THEN "negative"
        WHEN order_type in (9) THEN "srm"
        WHEN order_type in (4) THEN "auto"
        WHEN order_type in (8) THEN "sellermission"
        WHEN order_type in (3) THEN "manual"
        ELSE NULL
    END AS topup_category_name
FROM mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
WHERE grass_region = upper('${region}')
AND grass_date = date('${grass_date}') 
AND grass_date between date('${grass_date}')  - interval '1' day AND date('${grass_date}') 
AND date(from_unixtime(topup_create_timestamp, 'yyyy-MM-dd HH:mm:ss')) = date('${grass_date}') ; -- should use sg timezone?

INSERT OVERWRITE TABLE dws_advertiser_topup_1d__reg_s0_live PARTITION (tz_type, grass_region, grass_date)
SELECT  
        shop_id
        ,user_id
        ,total_topup_amt
        ,total_topup_amt_usd
        ,total_manual_amt_local
        ,total_manual_amt_usd
        ,manual_free_credit_topup_amt_local
        ,manual_free_credit_topup_amt_usd
        ,manual_paid_credit_topup_amt_local
        ,manual_paid_credit_topup_amt_usd
        ,total_auto_amt_local
        ,total_auto_amt_usd
        ,total_normal_amt_local
        ,total_normal_amt_usd
        ,normal_svs_topup_amt_local
        ,normal_svs_topup_amt_usd
        ,normal_order_topup_amt_local
        ,normal_order_topup_amt_usd
        ,srm_topup_amt
        ,srm_topup_amt_usd
        ,seller_mission_topup_amt
        ,seller_mission_topup_amt_usd
        ,neg_topup_amt
        ,neg_topup_amt_usd
        ,first_topup_timestamp
        ,first_manual_ts
        ,first_normal_ts
        ,first_auto_ts
        ,last_topup_timestamp
        ,last_manual_ts
        ,last_auto_ts
        ,last_normal_ts
        ,topup_times_cnt
        ,manual_topup_times_cnt
        ,auto_topup_times_cnt
        ,normal_topup_times_cnt
        ,srm_topup_times_cnt
        ,paid_wo_expiry_topup_amt_usd
        ,paid_w_expiry_topup_amt_usd
        ,free_wo_expiry_topup_amt_usd
        ,free_w_expiry_topup_amt_usd
        ,paid_wo_expiry_topup_amt_local
        ,paid_w_expiry_topup_amt_local
        ,free_wo_expiry_topup_amt_local
        ,free_w_expiry_topup_amt_local
        ,tz_type
        ,grass_region
        ,date('${grass_date}')  AS grass_date
FROM 
(
    SELECT  tz_type ,shop_id
            ,user_id
            ,grass_region
            ,SUM(topup_amt) AS total_topup_amt
            ,SUM(topup_amt_usd) AS total_topup_amt_usd
            ,SUM(CASE WHEN topup_category_name = 'manual' THEN topup_amt ELSE 0.0 END) AS total_manual_amt_local
            ,SUM(CASE WHEN topup_category_name = 'manual' THEN topup_amt_usd ELSE 0.0 END) AS total_manual_amt_usd
            ,SUM(CASE WHEN topup_category_name = 'manual' AND credit_topup_type in (3,4) THEN topup_amt ELSE 0.0 END) AS manual_free_credit_topup_amt_local
            ,SUM(CASE WHEN topup_category_name = 'manual' AND credit_topup_type in (3,4) THEN topup_amt_usd ELSE 0.0 END) AS manual_free_credit_topup_amt_usd
            ,SUM(CASE WHEN topup_category_name = 'manual' AND credit_topup_type in (1,2) THEN topup_amt ELSE 0.0 END) AS manual_paid_credit_topup_amt_local
            ,SUM(CASE WHEN topup_category_name = 'manual' AND credit_topup_type in (1,2) THEN topup_amt_usd ELSE 0.0 END) AS manual_paid_credit_topup_amt_usd

            ,SUM(CASE WHEN topup_category_name = "auto" THEN topup_amt ELSE 0.0 END) AS total_auto_amt_local
            ,SUM(CASE WHEN topup_category_name = "auto" THEN topup_amt_usd ELSE 0.0 END) AS total_auto_amt_usd
            ,SUM(CASE WHEN topup_category_name = "normal" THEN topup_amt ELSE 0.0 END) AS total_normal_amt_local
            ,SUM(CASE WHEN topup_category_name = "normal" THEN topup_amt_usd ELSE 0.0 END) AS total_normal_amt_usd
            ,SUM(CASE WHEN topup_category_name = "normal" AND order_type = 6 THEN topup_amt ELSE 0.0 END) AS normal_svs_topup_amt_local
            ,SUM(CASE WHEN topup_category_name = "normal" AND order_type = 6 THEN topup_amt_usd ELSE 0.0 END) AS normal_svs_topup_amt_usd
            ,SUM(CASE WHEN topup_category_name = "normal" AND order_type = 2 THEN topup_amt ELSE 0.0 END) AS normal_order_topup_amt_local
            ,SUM(CASE WHEN topup_category_name = "normal" AND order_type = 2 THEN topup_amt_usd ELSE 0.0 END) AS normal_order_topup_amt_usd

            ,SUM(CASE WHEN topup_category_name = "srm" THEN topup_amt ELSE 0.0 END) AS srm_topup_amt
            ,SUM(CASE WHEN topup_category_name = "srm" THEN topup_amt_usd ELSE 0.0 END) AS srm_topup_amt_usd
            ,SUM(CASE WHEN topup_category_name = "sellermission" THEN topup_amt ELSE 0.0 END) AS seller_mission_topup_amt
            ,SUM(CASE WHEN topup_category_name = "sellermission" THEN topup_amt_usd ELSE 0.0 END) AS seller_mission_topup_amt_usd
            ,SUM(CASE WHEN topup_category_name = "negative" THEN topup_amt ELSE 0.0 END) AS neg_topup_amt
            ,SUM(CASE WHEN topup_category_name = "negative" THEN topup_amt_usd ELSE 0.0 END) AS neg_topup_amt_usd

            ,MIN(CASE WHEN topup_category_name = "auto" THEN topup_create_timestamp ELSE NULL END) AS first_auto_ts
            ,MIN(CASE WHEN topup_category_name = "normal" THEN topup_create_timestamp ELSE NULL END) AS first_normal_ts
            ,MIN(CASE WHEN topup_category_name = "manual" THEN topup_create_timestamp ELSE NULL END) AS first_manual_ts
            ,MAX(CASE WHEN topup_category_name = "auto" THEN topup_create_timestamp ELSE NULL END) AS last_auto_ts
            ,MAX(CASE WHEN topup_category_name = "normal" THEN topup_create_timestamp ELSE NULL END) AS last_normal_ts
            ,MAX(CASE WHEN topup_category_name = "manual" THEN topup_create_timestamp ELSE NULL END) AS last_manual_ts

            ,COUNT(DISTINCT order_id) AS topup_times_cnt
            ,COUNT(DISTINCT CASE WHEN topup_category_name = 'manual' THEN order_id ELSE NULL END) AS manual_topup_times_cnt
            ,COUNT(DISTINCT CASE WHEN topup_category_name = 'auto' THEN order_id ELSE NULL END) AS auto_topup_times_cnt
            ,COUNT(DISTINCT CASE WHEN topup_category_name = 'normal' THEN order_id ELSE NULL END) AS normal_topup_times_cnt
            ,COUNT(DISTINCT CASE WHEN topup_category_name = 'srm' THEN order_id ELSE NULL END) AS srm_topup_times_cnt
            ,MIN(topup_create_timestamp) AS first_topup_timestamp
            ,MAX(topup_create_timestamp) AS last_topup_timestamp

            ,sum(case when credit_topup_type = 1 then topup_amt_usd else 0.0 end) as paid_wo_expiry_topup_amt_usd
            ,sum(case when credit_topup_type = 2 then topup_amt_usd else 0.0 end) as paid_w_expiry_topup_amt_usd
            ,sum(case when credit_topup_type = 3 then topup_amt_usd else 0.0 end) as free_wo_expiry_topup_amt_usd
            ,sum(case when credit_topup_type = 4 then topup_amt_usd else 0.0 end) as free_w_expiry_topup_amt_usd
            ,sum(case when credit_topup_type = 1 then topup_amt else 0.0 end) as paid_wo_expiry_topup_amt_local
            ,sum(case when credit_topup_type = 2 then topup_amt else 0.0 end) as paid_w_expiry_topup_amt_local
            ,sum(case when credit_topup_type = 3 then topup_amt else 0.0 end) as free_wo_expiry_topup_amt_local
            ,sum(case when credit_topup_type = 4 then topup_amt else 0.0 end) as free_w_expiry_topup_amt_local
    FROM base
    GROUP BY 1,2,3,4
)a;

alter table dws_advertiser_topup_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");