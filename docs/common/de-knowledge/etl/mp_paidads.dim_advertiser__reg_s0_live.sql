-- task_code: data_paidadsmart.studio_2623799  asset_id: 2623799
CREATE OR REPLACE TEMPORARY VIEW account_tab_df AS
(
    SELECT accountid AS account_id
        , userid AS user_id
        , balance
        , status
        , create_timestamp
        , create_datetime
        , modify_timestamp
        , modify_datetime
        , CAST(auto_topup_enabled AS TINYINT) AS is_auto_topup_enabled
        , CAST(campaign_auto_bid_enabled AS TINYINT) AS is_campaign_auto_bid_enabled
        , cast(decoded_extinfo.setup_flow_version.version as INT) as version_tag
        , CAST(is_self_mcn AS TINYINT) AS is_self_mcn
        , CAST(auto_budget_increase_enabled AS TINYINT) as is_auto_budget_increase_enabled
        ,auto_topup_threshold_amt
        ,auto_topup_amt
        ,auto_topup_daily_cap_amt
        ,auto_budget_increase_daily_cap
        ,auto_budget_increase_percentage
        ,auto_budget_increase_effective_types
        ,CAST(roi_three_voucher_enabled AS TINYINT) as is_roi_three_voucher_enabled
        ,CAST(auto_escrow_enabled AS TINYINT) as is_auto_escrow_enabled
        ,CAST(auto_ads_solution_enabled AS TINYINT) as is_auto_ads_solution_enabled
        ,auto_escrow_additional_fee_rate
        ,auto_escrow_fixed_program_fee_rate
        , grass_region
        , DATE('${BIZ_YESTERDAY}') as grass_date
    FROM (
        SELECT *
            ,CASE WHEN decoded_extinfo.auto_topup_setting.on = true Then 1 ELSE 0 END AS auto_topup_enabled
            ,cast(decoded_extinfo.auto_topup_setting.threshold as double) / 100000 as auto_topup_threshold_amt
            ,cast(decoded_extinfo.auto_topup_setting.amount as double) / 100000 as auto_topup_amt
            ,cast(decoded_extinfo.auto_topup_setting.daily_cap as double) / 100000 as auto_topup_daily_cap_amt
            ,CASE WHEN decoded_extinfo.campaign_day_setting.on = true Then 1 ELSE 0 END AS campaign_auto_bid_enabled
            ,CASE WHEN decoded_extinfo.mcn_info.is_self_mcn = true Then 1 ELSE 0 END AS is_self_mcn 
            ,CASE WHEN decoded_extinfo.auto_budget_increase_setting.on = true Then 1 ELSE 0 END AS auto_budget_increase_enabled 
            ,cast(decoded_extinfo.auto_budget_increase_setting.daily_cap as int) as auto_budget_increase_daily_cap
            ,cast(decoded_extinfo.auto_budget_increase_setting.increase_pct as bigint) / 100000.0 as auto_budget_increase_percentage
            ,decoded_extinfo.auto_budget_increase_setting.effective_types  as auto_budget_increase_effective_types
            ,CASE WHEN decoded_extinfo.roi_three_voucher_setting.on = true Then 1 ELSE 0 END AS roi_three_voucher_enabled
            ,CASE WHEN decoded_extinfo.auto_escrow_setting.on = true Then 1 ELSE 0 END AS auto_escrow_enabled
            ,CASE WHEN decoded_extinfo.auto_ads_solution_setting.on = true Then 1 ELSE 0 END AS auto_ads_solution_enabled
            ,decoded_extinfo.auto_escrow_setting.additional_fee_rate / 100000.00 as auto_escrow_additional_fee_rate
            ,decoded_extinfo.auto_escrow_setting.fixed_program_fee_rate / 100000.00 as auto_escrow_fixed_program_fee_rate 
        FROM
        (
        SELECT
          accountid
            , userid
            , balance
            , ctime AS create_timestamp
            , date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as create_datetime
            , mtime AS modify_timestamp
            , date_format(from_utc_timestamp(to_utc_timestamp(cast(mtime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as modify_datetime
            , status
            , from_json(_decoded_extinfo, 'struct < 
                daily_pn_setting: struct < 
                    is_off: BOOLEAN,
                    TIMESTAMP: string,
                    balance: string >,
                auto_topup_setting: struct < 
                    on: BOOLEAN,
                    threshold: string,
                    amount: string,
                    daily_cap: string >,
                campaign_day_setting: struct < on: BOOLEAN >,
                setup_flow_version: struct < 
                    version: INT,
                    last_upgrade_task_id: string,
                    last_downgrade_task_id: string,
                    number_of_downgrade: INT >,
                mcn_info: struct < is_self_mcn: BOOLEAN >,
                auto_budget_increase_setting: struct < 
                    on: BOOLEAN,
                    daily_cap: INT,
                    increase_pct: INT,
                    is_daily_reset: BOOLEAN,
                    effective_types: ARRAY < INT >,
                    latest_is_daily_reset_timestamp: string,
                    is_daily_reset_setting_on_timestamp: BOOLEAN,
                    campaign_days_daily_cap: INT > ,
                roi_three_voucher_setting: struct <on: BOOLEAN >,
                auto_escrow_setting: struct <
                    on: BOOLEAN,
                    additional_fee_rate: int,
                    fixed_program_fee_rate: int
                >,
                auto_ads_solution_setting: struct <on: BOOLEAN >
            >') AS decoded_extinfo
            , upper('${region}') AS grass_region
        FROM mp_paidads.shopee_ads_${region}_${db_type}__ads_account_tab__reg_continuous_s0_live
        WHERE ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${BIZ_YESTERDAY}', 1), '${timezone}'), 'Asia/Singapore'))
        )
    )
);  
    
CREATE OR REPLACE TEMPORARY VIEW adopt_target_audience_flag AS
select userid, count (*) as target_audience_count from 
mp_paidads.shopee_ads_${region}_${db_type}__target_audience_group_tab__reg_continuous_s0_live
where group_status = 1 group by userid
having target_audience_count > 0;

CREATE OR REPLACE TEMPORARY VIEW seller_1p AS
(
select 
    a.shop_id
    ,seller_type
    ,case
        when a.seller_name = 'Lovito - GGP' then 'Lovito'
        when a.seller_name = 'Flock project - GGP' then 'SCS'
        when c.local_scs = 1 then 'Local SCS'
        when a.seller_type = 'CNCB' then 'Others'
        else 'Unknown'
    end as seller_type_1p
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
from 
    (    
    select
        shop_id
        ,ggp_seller_name as seller_name
        ,cb_seller_type as seller_type
        ,is_cb_sip_affiliated
        ,is_local_sip_affiliated
    from mp_seller.dim_shop_ext__reg_s0_live
    where
        grass_region = upper('${region}')
        AND grass_date = DATE'${PREV_2D}'
    )a
    left join
    (
        select 
            shop_id 
            ,1 as local_scs
        from mp_paidads.dim_local_scs_shop_list
    )c 
    on a.shop_id = c.shop_id
)
;
INSERT OVERWRITE TABLE dim_advertiser__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT   
            advertiser.shop_id
            ,user_id
            ,beetalk_userid
            ,user_name
            ,language
            ,status
            ,account_status
            ,shop_status
            ,is_seller
            ,COALESCE(is_managed_seller,0)
            ,COALESCE(is_official_shop,0)
            ,COALESCE(is_preferred_shop,0)
            ,COALESCE(is_cb_seller,0)
            ,create_datetime
            ,modify_datetime
            ,account_create_datetime
            ,account_modify_datetime
            ,shop_create_datetime
            ,first_item_create_datetime
            ,shop_modify_datetime
            ,is_auto_topup_enabled
            ,is_campaign_auto_bid_enabled
            ,shop_level1_global_be_category
            ,shop_level1_fe_display_category
            ,shop_level1_kpi_category
            ,shop_level2_global_be_category
            ,shop_level2_fe_display_category
            ,shop_level2_kpi_category
            ,account_create_timestamp
            ,account_modify_timestamp
            ,balance
            ,case when target_audience_count >0 then True
            else False end as adopt_audience_targeting
            ,version_tag
            ,is_self_mcn
            ,seller_1p.seller_type as seller_type
            ,coalesce(seller_1p.seller_type_1p, 'Unknown') as seller_type_1p
            ,is_auto_budget_increase_enabled
            ,auto_topup_threshold_amt
            ,auto_topup_threshold_amt_usd
            ,auto_topup_amt
            ,auto_topup_amt_usd
            ,auto_topup_daily_cap_amt
            ,auto_topup_daily_cap_amt_usd
            ,auto_budget_increase_daily_cap
            ,auto_budget_increase_percentage
            ,auto_budget_increase_effective_types
            ,is_roi_three_voucher_enabled
            ,is_cb_sip_affiliated
            ,is_local_sip_affiliated
            ,is_auto_escrow_enabled
            ,is_auto_ads_solution_enabled
            ,auto_escrow_additional_fee_rate
            ,auto_escrow_fixed_program_fee_rate
            , upper('${region}') AS grass_region
            ,DATE('${BIZ_YESTERDAY}') as grass_date
    FROM
    (
              SELECT 
                ads_account.user_id
                    ,account_id
                    ,account_create_datetime
                    ,account_create_timestamp
                    ,account_modify_datetime
                    ,account_modify_timestamp
                    ,balance
                    ,account_status
                    ,is_auto_topup_enabled
                    ,is_campaign_auto_bid_enabled
                    ,shop_id
                    ,status
                    ,user_name
                    ,language
                    ,country
                    ,create_datetime
                    ,modify_datetime
                    ,beetalk_userid
                    ,is_seller
                    ,shop_status
                    ,shop_create_datetime
                    ,shop_modify_datetime
                    ,ads_account.grass_region
                    ,version_tag
                    ,is_self_mcn
                    ,is_cb_seller
                    ,is_auto_budget_increase_enabled
                    ,auto_topup_threshold_amt
                    ,auto_topup_threshold_amt / exchange_rate as auto_topup_threshold_amt_usd
                    ,auto_topup_amt
                    ,auto_topup_amt / exchange_rate as auto_topup_amt_usd
                    ,auto_topup_daily_cap_amt
                    ,auto_topup_daily_cap_amt / exchange_rate as auto_topup_daily_cap_amt_usd
                    ,auto_budget_increase_daily_cap
                    ,auto_budget_increase_percentage
                    ,auto_budget_increase_effective_types
                    ,is_roi_three_voucher_enabled
                    ,is_auto_escrow_enabled
                    ,is_auto_ads_solution_enabled
                    ,auto_escrow_additional_fee_rate
                    ,auto_escrow_fixed_program_fee_rate
              FROM
              (
                    SELECT   distinct
                        user_id
                        ,account_id
                        ,create_datetime AS account_create_datetime
                        ,modify_datetime AS account_modify_datetime
                        ,status AS account_status
                        ,is_auto_topup_enabled
                        ,is_campaign_auto_bid_enabled
                        ,balance
                        ,create_timestamp AS account_create_timestamp 
                        ,modify_timestamp AS account_modify_timestamp
                        ,version_tag
                        ,is_self_mcn
                        ,is_auto_budget_increase_enabled
                        ,auto_topup_threshold_amt
                        ,auto_topup_amt
                        ,auto_topup_daily_cap_amt
                        ,auto_budget_increase_daily_cap
                        ,auto_budget_increase_percentage
                        ,auto_budget_increase_effective_types
                        ,is_roi_three_voucher_enabled
                        ,is_auto_escrow_enabled
                        ,is_auto_ads_solution_enabled
                        ,auto_escrow_additional_fee_rate
                        ,auto_escrow_fixed_program_fee_rate
                        ,grass_region
                    FROM account_tab_df
              ) ads_account
              LEFT JOIN
              (
                    SELECT   distinct user_id
                             ,shop_id
                             ,status
                             ,user_name
                             ,CAST(NULL AS string) AS language
                             ,LOWER(grass_region) AS country
                             ,registration_datetime AS create_datetime
                             ,modify_datetime
                             ,CAST(NULL AS bigint) as beetalk_userid
                             ,is_seller
                             ,is_cb_shop AS is_cb_seller
                             ,grass_region
                      FROM  mp_user.dim_user__reg_s0_live
                      WHERE grass_region = upper('${region}')
                      AND grass_date = '${BIZ_YESTERDAY}'
              ) account
              ON ads_account.user_id = account.user_id AND ads_account.grass_region = account.grass_region
              LEFT JOIN
              (
                    SELECT  distinct user_id
                            ,status AS shop_status
                            ,create_datetime AS shop_create_datetime
                            ,modify_datetime AS shop_modify_datetime
                            ,grass_region
                    FROM mp_user.dim_shop__reg_s0_live
                    WHERE grass_region = upper('${region}')
                    AND grass_date = '${BIZ_YESTERDAY}'
              ) shop
              ON ads_account.user_id = shop.user_id AND ads_account.grass_region = shop.grass_region
              LEFT JOIN(
                    SELECT
                        grass_region
                        ,exchange_rate
                    FROM mp_order.dim_exchange_rate__reg_s0_live
                    WHERE grass_region = upper('${region}')
                    AND grass_date = DATE('${BIZ_YESTERDAY}') 
                ) exrate
                ON ads_account.grass_region = exrate.grass_region
              
    ) advertiser
    LEFT JOIN
    (
             SELECT distinct shop_id
                    ,is_official_shop
                    ,is_preferred_shop
                    ,is_managed_shop AS is_managed_seller
                    ,grass_region
              FROM mp_user.dim_shop__reg_s0_live
              WHERE grass_region = upper('${region}')
              AND grass_date = '${BIZ_YESTERDAY}'
    ) ds
    ON advertiser.shop_id = ds.shop_id AND advertiser.grass_region = ds.grass_region
    LEFT JOIN
    (
        SELECT   shop_id
                ,MIN(create_datetime) AS first_item_create_datetime
                ,grass_region
        FROM marketplace.ods_shopee_item_v5_db__item_v5_tab_df__reg
        WHERE grass_region = upper('${region}')
        AND grass_date = '${BIZ_YESTERDAY}'
        GROUP BY shop_id, grass_region
    ) item
    ON advertiser.shop_id = item.shop_id AND advertiser.grass_region = item.grass_region
    LEFT JOIN (
        SELECT distinct
            grass_region
            , shop_id
            , shop_level1_global_be_category
            , shop_level1_fe_display_category
            , shop_level1_kpi_category
            , shop_level2_global_be_category
            , shop_level2_fe_display_category
            , shop_level2_kpi_category
        FROM mp_item.dws_shop_listing_td__reg_s0_live
        WHERE grass_date = DATE('${BIZ_YESTERDAY}')
        AND grass_region = upper('${region}') 
        AND tz_type='${tz_type}'
    ) category
    ON advertiser.shop_id = category.shop_id AND advertiser.grass_region = category.grass_region
    LEFT JOIN (
        select * from adopt_target_audience_flag
    ) target_audience_adopt
    ON advertiser.user_id = target_audience_adopt.userid
    LEFT JOIN seller_1p
    ON advertiser.shop_id = seller_1p.shop_id
;
alter table dim_advertiser__${region}_s0_live add if not exists partition (grass_date= '${BIZ_YESTERDAY}');