-- task_code: data_paidadsmart.studio_2874979  asset_id: 2874979
create or replace temporary view credit_view as
SELECT
    grass_region
    ,grass_date
    ,shop_id
    ,order_type AS credit_order_type
    ,credit_topup_main_type
    ,credit_balance_amt
    ,credit_balance_amt_usd
FROM mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
WHERE grass_region = upper('${region}')
AND grass_date = date('${grass_date}') 
AND (credit_topup_expiry_end_timestamp is not NULL and credit_topup_expiry_end_timestamp > 0)
AND date(credit_topup_expiry_end_datetime) <= date('${grass_date}');


INSERT OVERWRITE TABLE dws_advertiser_credit_expiry_td__reg_s0_live partition (tz_type='local', grass_region, grass_date)
    SELECT 
         dim.shop_id
        ,dim.user_id
        ,COALESCE(manual_free_credit_expired_amt_td, 0.0)
        ,COALESCE(manual_free_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(manual_paid_credit_expired_amt_td, 0.0)
        ,COALESCE(manual_paid_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(seller_mission_free_credit_expired_amt_td, 0.0)
        ,COALESCE(seller_mission_free_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(seller_mission_paid_credit_expired_amt_td, 0.0)
        ,COALESCE(seller_mission_paid_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(srm_free_credit_expired_amt_td, 0.0)
        ,COALESCE(srm_free_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(srm_paid_credit_expired_amt_td, 0.0)
        ,COALESCE(srm_paid_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(total_free_credit_expired_amt_td, 0.0)
        ,COALESCE(total_free_credit_expired_amt_usd_td, 0.0)
        ,COALESCE(total_paid_credit_expired_amt_td, 0.0)
        ,COALESCE(total_paid_credit_expired_amt_usd_td, 0.0)
        ,dim.grass_region
        ,date('${grass_date}')  AS grass_date
    FROM (
        SELECT
            distinct shop_id
            ,user_id
            ,grass_region
        FROM mp_paidads.dim_advertiser__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
    ) dim
    LEFT JOIN (
        SELECT
            shop_id
            ,grass_region
            ,manual_free_credit_expired_amt_td
            ,manual_free_credit_expired_amt_usd_td
            ,manual_paid_credit_expired_amt_td
            ,manual_paid_credit_expired_amt_usd_td
            ,seller_mission_free_credit_expired_amt_td
            ,seller_mission_free_credit_expired_amt_usd_td
            ,seller_mission_paid_credit_expired_amt_td
            ,seller_mission_paid_credit_expired_amt_usd_td
            ,srm_free_credit_expired_amt_td
            ,srm_free_credit_expired_amt_usd_td
            ,srm_paid_credit_expired_amt_td
            ,srm_paid_credit_expired_amt_usd_td
            ,(manual_free_credit_expired_amt_td +
              seller_mission_free_credit_expired_amt_td +
              srm_free_credit_expired_amt_td) AS total_free_credit_expired_amt_td
            ,(manual_free_credit_expired_amt_usd_td +
              seller_mission_free_credit_expired_amt_usd_td +
              srm_free_credit_expired_amt_usd_td) AS total_free_credit_expired_amt_usd_td
            ,(manual_paid_credit_expired_amt_td +
              seller_mission_paid_credit_expired_amt_td +
              srm_paid_credit_expired_amt_td) AS total_paid_credit_expired_amt_td
            ,(manual_paid_credit_expired_amt_usd_td +
              seller_mission_paid_credit_expired_amt_usd_td +
              srm_paid_credit_expired_amt_usd_td) AS total_paid_credit_expired_amt_usd_td
        FROM (
            SELECT
                 grass_region
                ,shop_id
                ,SUM(manual_free_credit_expired_amt_td) AS manual_free_credit_expired_amt_td
                ,SUM(manual_free_credit_expired_amt_usd_td) AS manual_free_credit_expired_amt_usd_td
                ,SUM(manual_paid_credit_expired_amt_td) AS manual_paid_credit_expired_amt_td
                ,SUM(manual_paid_credit_expired_amt_usd_td) AS manual_paid_credit_expired_amt_usd_td
                ,SUM(seller_mission_free_credit_expired_amt_td) AS seller_mission_free_credit_expired_amt_td
                ,SUM(seller_mission_free_credit_expired_amt_usd_td) AS seller_mission_free_credit_expired_amt_usd_td
                ,SUM(seller_mission_paid_credit_expired_amt_td) AS seller_mission_paid_credit_expired_amt_td
                ,SUM(seller_mission_paid_credit_expired_amt_usd_td) AS seller_mission_paid_credit_expired_amt_usd_td
                ,SUM(srm_free_credit_expired_amt_td) AS srm_free_credit_expired_amt_td
                ,SUM(srm_free_credit_expired_amt_usd_td) AS srm_free_credit_expired_amt_usd_td
                ,SUM(srm_paid_credit_expired_amt_td) AS srm_paid_credit_expired_amt_td
                ,SUM(srm_paid_credit_expired_amt_usd_td) AS srm_paid_credit_expired_amt_usd_td
            FROM (
                SELECT   grass_region
                        ,shop_id
                        ,CASE WHEN credit_order_type=3 AND credit_topup_main_type=3
                             THEN credit_balance_amt ELSE 0 END AS manual_free_credit_expired_amt_td
                        ,CASE WHEN credit_order_type=3 AND credit_topup_main_type=3
                             THEN credit_balance_amt_usd ELSE 0 END AS manual_free_credit_expired_amt_usd_td
                        ,CASE WHEN credit_order_type=3 AND credit_topup_main_type=2
                             THEN credit_balance_amt ELSE 0 END AS manual_paid_credit_expired_amt_td
                        ,CASE WHEN credit_order_type=3 AND credit_topup_main_type=2
                             THEN credit_balance_amt_usd ELSE 0 END AS manual_paid_credit_expired_amt_usd_td
                        ,CASE WHEN credit_order_type=8 AND credit_topup_main_type=3
                             THEN credit_balance_amt ELSE 0 END AS seller_mission_free_credit_expired_amt_td
                        ,CASE WHEN credit_order_type=8 AND credit_topup_main_type=3
                             THEN credit_balance_amt_usd ELSE 0 END AS seller_mission_free_credit_expired_amt_usd_td
                        ,CASE WHEN credit_order_type=8 AND credit_topup_main_type=2
                             THEN credit_balance_amt ELSE 0 END AS seller_mission_paid_credit_expired_amt_td
                        ,CASE WHEN credit_order_type=8 AND credit_topup_main_type=2
                             THEN credit_balance_amt_usd ELSE 0 END AS seller_mission_paid_credit_expired_amt_usd_td
                        ,CASE WHEN credit_order_type=9 AND credit_topup_main_type=3
                             THEN credit_balance_amt ELSE 0 END AS srm_free_credit_expired_amt_td
                        ,CASE WHEN credit_order_type=9 AND credit_topup_main_type=3
                             THEN credit_balance_amt_usd ELSE 0 END AS srm_free_credit_expired_amt_usd_td
                        ,CASE WHEN credit_order_type=9 AND credit_topup_main_type=2
                             THEN credit_balance_amt ELSE 0 END AS srm_paid_credit_expired_amt_td
                        ,CASE WHEN credit_order_type=9 AND credit_topup_main_type=2
                             THEN credit_balance_amt_usd ELSE 0 END AS srm_paid_credit_expired_amt_usd_td
                FROM credit_view
            )
            GROUP BY grass_region, shop_id
        )
    ) credit
    ON (dim.shop_id = credit.shop_id AND dim.grass_region = credit.grass_region);

alter table dws_advertiser_credit_expiry_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");