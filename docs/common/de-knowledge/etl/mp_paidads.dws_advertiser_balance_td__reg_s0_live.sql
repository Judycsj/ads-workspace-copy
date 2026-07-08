-- task_code: data_paidadsmart.studio_2867260  asset_id: 2867260
set time zone 'America/Mexico_City';
create or replace temporary view end_balance_view as
select
        a.user_id
        , b.shop_id
        , a.order_id
        , pckg_paid_amt
        , topup_amt
        , voucher_discount_amt
        , credit_topup_type
        , is_package_topup
        , is_voucher_topup 
        , a.order_type as order_type
        , a.main_type as main_type
        , credit_expiry_time AS credit_expiry_timestamp
        , top_up_amount
        , start_of_day_balance
        , end_of_day_balance 
        , effective_type
        , 'local' AS tz_type
        , a.grass_region
        , date(dt) AS grass_date
    FROM (
        SELECT *
        FROM mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND dt = '${grass_date}'
    ) a
    LEFT JOIN (
        SELECT
            user_id
            , shop_id
            , grass_region
        FROM mp_paidads.dim_advertiser__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
    ) b
    ON a.user_id = b.user_id
    AND a.grass_region = b.grass_region
    LEFT JOIN (
      SELECT
        pckg_paid_amt * 100000.0 as pckg_paid_amt
        , topup_amt * 100000.0 as topup_amt
        , voucher_discount_amt * 100000.0 as voucher_discount_amt
        , credit_topup_type
        , is_package_topup
        , is_voucher_topup
        , order_id
        , shop_id
        , effective_type
        , order_type
        , credit_topup_main_type as main_type
        , grass_region
      FROM mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
      WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
        group by 1,2,3,4,5,6,7,8,9,10,11,12
    --   AND (is_package_topup = 1 OR is_voucher_topup = 1)
    ) c
    ON a.order_id = c.order_id
    AND b.shop_id = c.shop_id
    and a.order_type = c.order_type
    AND a.grass_region = c.grass_region
    and a.main_type = c.main_type;

set time zone 'America/Araguaina'
;

INSERT OVERWRITE TABLE dws_advertiser_balance_td__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  
            shop_id
           ,free_credit_w_expiry_eod_balance_amt_td
           ,free_credit_w_expiry_eod_balance_amt_td / exchange_rate AS free_credit_w_expiry_eod_balance_amt_usd_td
           ,free_credit_wo_expiry_eod_balance_amt_td
           ,free_credit_wo_expiry_eod_balance_amt_td / exchange_rate AS free_credit_wo_expiry_eod_balance_amt_usd_td
           ,paid_credit_w_expiry_eod_balance_amt_td
           ,paid_credit_w_expiry_eod_balance_amt_td / exchange_rate AS paid_credit_w_expiry_eod_balance_amt_usd_td
           ,paid_credit_wo_expiry_eod_balance_amt_td
           ,paid_credit_wo_expiry_eod_balance_amt_td / exchange_rate AS paid_credit_wo_expiry_eod_balance_amt_usd_td
           ,paid_credit_wo_expiry_sod_balance_amt_td
           ,paid_credit_wo_expiry_sod_balance_amt_td / exchange_rate AS paid_credit_wo_expiry_sod_balance_amt_usd_td
           ,total_eod_balance_td
           ,total_eod_balance_td / exchange_rate AS total_eod_balance_usd_td
           ,roi2_eod_balance_amt_td
           ,livestream_eod_balance_amt_td
           ,search_brand_eod_balance_amt_td
           ,roi2_eod_balance_amt_td / exchange_rate AS roi2_eod_balance_amt_usd_td
           ,livestream_eod_balance_amt_td / exchange_rate AS livestream_eod_balance_usd_amt_td
           ,search_brand_eod_balance_amt_td / exchange_rate AS search_brand_eod_balance_usd_amt_td
           ,grass_region
           ,grass_date
    FROM (
      SELECT /*+ BROADCAST(exrate) */
            a.shop_id
           ,a.free_credit_w_expiry_eod_balance_amt_td + a.mixed_free_credit_w_expiry_to_add as free_credit_w_expiry_eod_balance_amt_td
           ,a.free_credit_wo_expiry_eod_balance_amt_td + a.mixed_free_credit_wo_expiry_to_add as free_credit_wo_expiry_eod_balance_amt_td
           ,a.paid_credit_w_expiry_eod_balance_amt_td + a.mixed_paid_credit_w_expiry_to_add as paid_credit_w_expiry_eod_balance_amt_td
           ,a.paid_credit_wo_expiry_eod_balance_amt_td  as paid_credit_wo_expiry_eod_balance_amt_td
           ,COALESCE(a.paid_credit_wo_expiry_sod_balance_amt_td, 0.0) as paid_credit_wo_expiry_sod_balance_amt_td
           ,(COALESCE(a.free_credit_w_expiry_eod_balance_amt_td,0.0) +
             COALESCE(a.free_credit_wo_expiry_eod_balance_amt_td,0.0) +
             COALESCE(a.paid_credit_w_expiry_eod_balance_amt_td,0.0) +
             COALESCE(a.paid_credit_wo_expiry_eod_balance_amt_td,0.0) +
             COALESCE(a.mixed_free_credit_w_expiry_to_add,0.0) +
             COALESCE(a.mixed_free_credit_wo_expiry_to_add,0.0) +
             COALESCE(a.mixed_paid_credit_w_expiry_to_add,0.0) 
             ) AS total_eod_balance_td
           ,roi2_eod_balance_amt_td
           ,livestream_eod_balance_amt_td
           ,search_brand_eod_balance_amt_td
           ,a.grass_region
           ,date('${grass_date}')  AS grass_date
           ,exchange_rate
    FROM (
        SELECT shop_id
              ,grass_region
              ,SUM(CASE
                   WHEN main_type = 3 AND FROM_UNIXTIME(credit_expiry_timestamp ,'yyyy-MM-dd') >= '${grass_date}' THEN end_of_day_balance
                   ELSE 0 END) / 100000.0 as free_credit_w_expiry_eod_balance_amt_td
              ,SUM(CASE
                   WHEN main_type = 3 AND credit_expiry_timestamp = 0 THEN end_of_day_balance
                   ELSE 0 END) / 100000.0 as free_credit_wo_expiry_eod_balance_amt_td
              ,SUM(CASE
                   WHEN main_type = 2 AND FROM_UNIXTIME(credit_expiry_timestamp ,'yyyy-MM-dd') >= '${grass_date}' THEN end_of_day_balance
               ELSE 0 END) / 100000.0 as paid_credit_w_expiry_eod_balance_amt_td
              ,SUM(CASE
                   WHEN order_id is NULL AND credit_expiry_timestamp is NULL THEN end_of_day_balance
               ELSE 0 END) / 100000.0 as paid_credit_wo_expiry_eod_balance_amt_td
              ,SUM(CASE
                   WHEN is_package_topup = 1 AND credit_topup_type = 4
                   -- when this is package topup and credit type is free credit w expiry
                   THEN CASE WHEN end_of_day_balance >= pckg_paid_amt
                             THEN end_of_day_balance - pckg_paid_amt
                              -- if there are free credits remaining
                             WHEN end_of_day_balance < pckg_paid_amt
                             THEN 0
                             -- no free credits remaining
                         END
                   WHEN is_voucher_topup = 1 AND credit_topup_type = 1
                   -- when this is a voucher topup, we use the difference between balance and paid
                   -- credit amount to add to the free credits
                   THEN CASE WHEN end_of_day_balance >= topup_amt AND FROM_UNIXTIME(credit_expiry_timestamp ,'yyyy-MM-dd') >= '${grass_date}'
                              -- there are free credits remaining as balance is > than paid amount
                              THEN end_of_day_balance 
                        END
                   ELSE 0 END) / 100000.0 AS mixed_free_credit_w_expiry_to_add 
              ,SUM(CASE
                   WHEN is_voucher_topup = 1 AND credit_topup_type = 3
                   -- when this is a voucher topup, we use the difference between balance and paid
                   -- credit amount to add to the free credits
                --    AND    end_of_day_balance >= topup_amt
                   AND    credit_expiry_timestamp = 0
                   THEN   end_of_day_balance 
                   ELSE 0 END) / 100000.0 AS mixed_free_credit_wo_expiry_to_add
              ,SUM(CASE
                 -- when this is a package topup and there are remaining paid credits
                  WHEN is_package_topup = 1 AND credit_topup_type = 2
                  THEN CASE WHEN end_of_day_balance >= pckg_paid_amt
                            THEN pckg_paid_amt
                            WHEN end_of_day_balance < pckg_paid_amt
                            THEN end_of_day_balance
                        END
                  ELSE 0 END) / 100000.0 AS mixed_paid_credit_w_expiry_to_add
            --   ,SUM(CASE
            --        -- when this is a voucher topup and there are remaining paid credits
            --        WHEN is_voucher_topup = 1 AND credit_topup_type = 1 
            --        THEN CASE WHEN end_of_day_balance >= topup_amt
            --                  THEN topup_amt
            --                  WHEN end_of_day_balance < topup_amt
            --                  THEN end_of_day_balance
            --             END
            --        ELSE 0 END) / 100000.0 AS mixed_paid_credit_wo_expiry_to_add
              ,SUM(CASE
                   WHEN order_id is NULL AND credit_expiry_timestamp is NULL THEN start_of_day_balance
               ELSE 0 END) / 100000.0 as paid_credit_wo_expiry_sod_balance_amt_td
              ,sum(CASE WHEN effective_type = 1 THEN end_of_day_balance
                   ELSE 0 END) / 100000.0 as roi2_eod_balance_amt_td
              ,sum(CASE WHEN effective_type = 2 THEN end_of_day_balance
                   ELSE 0 END) / 100000.0 as livestream_eod_balance_amt_td
              ,sum(CASE WHEN effective_type = 3 THEN end_of_day_balance
                   ELSE 0 END) / 100000.0 as search_brand_eod_balance_amt_td
        FROM end_balance_view
        GROUP BY 1,2
    ) a
    LEFT OUTER JOIN (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
    ) exrate
    ON a.grass_region = exrate.grass_region
    );

alter table dws_advertiser_balance_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");