-- task_code: data_paidadsmart.studio_2861680  asset_id: 2861680
INSERT OVERWRITE TABLE dws_advertiser_account_1d__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT   /*+BROADCAST(exrate)*/
            dim_advertiser.user_id
            ,t.shop_id
            ,balance.acc_before_balance
            ,balance.acc_before_balance / exchange_rate AS acc_before_balance_usd
            ,balance.acc_after_balance
            ,balance.acc_after_balance / exchange_rate AS acc_after_balance_usd
            ,t.low_threshold
            ,t.low_threshold / exchange_rate AS low_threshold_usd
            ,CASE WHEN t.min_acc_after_balance < t.low_threshold THEN 1 ELSE 0 END AS is_reach_threshold
            ,t.grass_region
            ,date('${grass_date}') AS grass_date
    FROM
    (
        SELECT   shop_id
                ,grass_region
                ,MIN(acc_after_balance) AS min_acc_after_balance
                ,CASE
                    WHEN grass_region = 'TW' THEN 5
                    WHEN grass_region = 'ID' THEN 2000
                    WHEN grass_region = 'VN' THEN 2000
                    WHEN grass_region = 'TH' THEN 5
                    WHEN grass_region = 'MY' THEN 0.7
                    WHEN grass_region = 'SG' THEN 0.2
                    WHEN grass_region = 'PH' THEN 4
                    WHEN grass_region = 'BR' THEN 1
                    WHEN grass_region = 'MX' THEN 1
                    ELSE 1
                 END AS low_threshold
        FROM mp_paidads.dwd_advertiser_transaction_di__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}')
        GROUP BY shop_id, grass_region
    ) t
    LEFT OUTER JOIN (
        SELECT   shop_id
                ,grass_region
                ,MAX( CASE WHEN desc_rn = 1 THEN acc_after_balance ELSE NULL END) AS acc_after_balance
                ,MAX( CASE WHEN asc_rn = 1 THEN acc_before_balance ELSE NULL END) AS acc_before_balance
        FROM (
            SELECT   shop_id
                    ,grass_region
                    ,acc_after_balance
                    ,acc_before_balance
                    ,row_number() OVER (PARTITION BY grass_region, shop_id ORDER BY COALESCE(event_timestamp, 0) DESC, acc_after_balance ASC) AS desc_rn
                    ,row_number() OVER (PARTITION BY grass_region, shop_id ORDER BY COALESCE(event_timestamp, 0) ASC, acc_before_balance DESC) AS asc_rn
            FROM mp_paidads.dwd_advertiser_transaction_di__reg_s0_live
            WHERE grass_region = upper('${region}')
            AND grass_date = date('${grass_date}')
        )
        WHERE (desc_rn = 1 OR asc_rn = 1)
        GROUP BY shop_id
                ,grass_region
    ) balance
    ON (t.shop_id = balance.shop_id AND t.grass_region = balance.grass_region)
    LEFT OUTER JOIN (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}')
    ) exrate
    ON t.grass_region = exrate.grass_region
    LEFT OUTER JOIN
    (
        SELECT   shop_id
                ,user_id
                ,grass_region
        FROM mp_paidads.dim_advertiser__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}')
        GROUP BY shop_id
                ,user_id
                ,grass_region
    ) dim_advertiser
    ON t.shop_id = dim_advertiser.shop_id AND t.grass_region = dim_advertiser.grass_region;

alter table dws_advertiser_account_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");