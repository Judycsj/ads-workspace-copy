-- task_code: data_paidadsmart.studio_2878918  asset_id: 2878918
INSERT OVERWRITE TABLE dws_advertiser_topup_nd__reg_s0_live PARTITION (tz_type, grass_region, grass_date)
    SELECT   
             shop_id
            ,seller_id
            ,SUM( CASE WHEN is_7d = 1 THEN total_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN total_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN total_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN total_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN total_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN total_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN total_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN total_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN manual_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN manual_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1  THEN manual_free_credit_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_free_credit_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_free_credit_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_free_credit_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1  THEN manual_free_credit_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_free_credit_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_free_credit_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_free_credit_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1  THEN manual_paid_credit_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_paid_credit_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_paid_credit_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_paid_credit_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1  THEN manual_paid_credit_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_paid_credit_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_paid_credit_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_paid_credit_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN auto_topup_amt_local ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN auto_topup_amt_local ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN auto_topup_amt_local ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN auto_topup_amt_local ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN auto_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN auto_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN auto_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN auto_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN normal_amt_local ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN normal_amt_local ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN normal_amt_local ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN normal_amt_local ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN normal_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN normal_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN normal_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN normal_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d  = 1 THEN seller_mission_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN seller_mission_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN seller_mission_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN seller_mission_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d  = 1 THEN seller_mission_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN seller_mission_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN seller_mission_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN seller_mission_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d  = 1 THEN srm_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN srm_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN srm_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN srm_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d  = 1 THEN srm_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN srm_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN srm_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN srm_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d  = 1 THEN neg_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN neg_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN neg_topup_amt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN neg_topup_amt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d  = 1 THEN neg_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN neg_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN neg_topup_amt_usd ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN neg_topup_amt_usd ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN topup_times_cnt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN manual_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN manual_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN manual_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN manual_topup_times_cnt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN auto_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN auto_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN auto_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN auto_topup_times_cnt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN normal_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN normal_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN normal_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN normal_topup_times_cnt ELSE 0.0 END )

            ,SUM( CASE WHEN is_7d = 1 THEN  srm_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_30d = 1 THEN srm_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_60d = 1 THEN srm_topup_times_cnt ELSE 0.0 END )
            ,SUM( CASE WHEN is_90d = 1 THEN srm_topup_times_cnt ELSE 0.0 END )

            ,tz_type
            ,grass_region
            ,date('${grass_date}')  AS grass_date
    FROM (
        SELECT  shop_id
                ,seller_id
                ,grass_region
                ,total_topup_amt
                ,total_topup_amt_usd
                ,manual_topup_amt
                ,manual_topup_amt_usd
                ,manual_free_credit_topup_amt
                ,manual_free_credit_topup_amt_usd
                ,manual_paid_credit_topup_amt
                ,manual_paid_credit_topup_amt_usd
                ,auto_topup_amt_local
                ,auto_topup_amt_usd
                ,normal_amt_local
                ,normal_amt_usd
                ,seller_mission_topup_amt
                ,seller_mission_topup_amt_usd
                ,srm_topup_amt
                ,srm_topup_amt_usd
                ,neg_topup_amt
                ,neg_topup_amt_usd
                ,topup_times_cnt
                ,manual_topup_times_cnt
                ,auto_topup_times_cnt
                ,normal_topup_times_cnt
                ,srm_topup_times_cnt
                ,CASE WHEN grass_date BETWEEN (date('${grass_date}')  - INTERVAL 6 DAYS) AND date('${grass_date}')  THEN 1 ELSE 0 END AS is_7d
                ,CASE WHEN grass_date BETWEEN (date('${grass_date}')  - INTERVAL 29 DAYS) AND date('${grass_date}')  THEN 1 ELSE 0 END AS is_30d
                ,CASE WHEN grass_date BETWEEN (date('${grass_date}')  - INTERVAL 59 DAYS) AND date('${grass_date}')   THEN 1 ELSE 0 END AS is_60d
                ,CASE WHEN grass_date BETWEEN (date('${grass_date}')  - INTERVAL 89 DAYS) AND date('${grass_date}')  THEN 1 ELSE 0 END AS is_90d
                ,tz_type
        FROM mp_paidads.dws_advertiser_topup_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date BETWEEN (date('${grass_date}')  - INTERVAL 89 DAYS) AND date('${grass_date}') 
    )
    WHERE seller_id IS NOT NULL
    GROUP BY shop_id, seller_id, grass_region, tz_type;

alter table dws_advertiser_topup_nd__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");