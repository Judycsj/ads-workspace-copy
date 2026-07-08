-- task_code: data_paidadsmart.studio_2865149  asset_id: 2865149
INSERT OVERWRITE TABLE dws_advertiser_account_td__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  
            COALESCE(a.user_id, b.user_id) AS user_id
           ,COALESCE(a.shop_id, b.shop_id) AS shop_id
           ,COALESCE(a.acc_before_balance, b.acc_before_balance) AS acc_before_balance
           ,COALESCE(a.acc_before_balance_usd, b.acc_before_balance_usd) AS acc_before_balance_usd
           ,COALESCE(a.acc_after_balance, b.acc_after_balance) AS acc_after_balance
           ,COALESCE(a.acc_after_balance_usd, b.acc_after_balance_usd) AS acc_after_balance_usd
           ,COALESCE(a.low_threshold, b.low_threshold) AS low_threshold
           ,COALESCE(a.low_threshold_usd, b.low_threshold_usd) AS low_threshold_usd
           ,COALESCE(a.is_reach_threshold, b.is_reach_threshold) AS is_reach_threshold
           ,COALESCE(a.grass_region, b.grass_region) AS grass_region
           ,date('${grass_date}') AS grass_date
    FROM (
        SELECT  user_id
               ,shop_id
               ,acc_before_balance
               ,acc_before_balance_usd
               ,acc_after_balance
               ,acc_after_balance_usd
               ,low_threshold
               ,low_threshold_usd
               ,is_reach_threshold
               ,grass_region
        FROM mp_paidads.dws_advertiser_account_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}')
    ) a
    FULL OUTER JOIN (
        SELECT  user_id
               ,shop_id
               ,acc_before_balance
               ,acc_before_balance_usd
               ,acc_after_balance
               ,acc_after_balance_usd
               ,low_threshold
               ,low_threshold_usd
               ,is_reach_threshold
               ,grass_region
        FROM mp_paidads.dws_advertiser_account_td__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date_sub(date('${grass_date}'), 1)
    ) b
    ON a.shop_id = b.shop_id AND a.grass_region = b.grass_region;

alter table dws_advertiser_account_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");