-- task_code: data_paidadsmart.studio_2866807  asset_id: 2866807
SET TIME ZONE '${timezone}';

CREATE or replace TEMPORARY FUNCTION json_from_protobuf as 'com.shopee.deepdata.warehouse.hive.udf.DecodeProtobuf';

CREATE OR REPLACE TEMPORARY VIEW ads_account_audit as
(
    SELECT  
            id
          , userid AS user_id
          , accountid AS account_id
          , operator_email
          , timestamp AS event_timestamp
          , from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
          , client_ip
          , platform
          , create_timestamp
          , from_unixtime(create_timestamp, 'yyyy-MM-dd HH:mm:ss') as create_datetime
          , modify_timestamp
          , from_unixtime(modify_timestamp, 'yyyy-MM-dd HH:mm:ss') as modify_datetime
          , status
          , balance
          , overdue_limit
          , CAST(get_json_object(new_data_extinfo, '$.dailyPnSetting') AS STRING) as daily_pn_setting
          , CAST(get_json_object(new_data_extinfo, '$.autoTopupSetting') AS STRING) as auto_topup_setting 
          , CAST(get_json_object(new_data_extinfo, '$.campaignDaySetting') AS STRING) as campaign_day_setting
          , audit_event
          , old_data
          , new_data
          , CAST(get_json_object(new_data_extinfo, '$.autoBudgetIncreaseSetting') AS STRING) as auto_budget_increase_setting
          , from_json(get_json_object(new_data_extinfo, '$.autoBudgetIncreaseSetting'), 'struct<on BOOLEAN,dailyCap INT,increasePct INT,isDailyReset BOOLEAN,effectiveTypes ARRAY<INT>,latestIsDailyResetTimestamp STRING,isDailyResetSettingOnTimestamp BOOLEAN,campaignDaysDailyCap INT>') AS autoBudgetIncreaseSetting
          , old_data_extinfo
          , new_data_extinfo
          ,ads_account_audit_extinfo

    FROM
    (
      SELECT
            *
          , CAST(get_json_object(new_data, '$.ctime') AS bigint) AS create_timestamp
          , CAST(get_json_object(new_data, '$.mtime') AS bigint) AS modify_timestamp
          , from_unixtime(get_json_object(new_data, '$.mtime'), 'yyyy-MM-dd HH:mm:ss') as modify_datetime
          , CAST(get_json_object(new_data, '$.status') AS bigint) AS status
          , CAST(get_json_object(new_data, '$.balance') AS double) / 100000 AS balance
          , CAST(get_json_object(new_data, '$.overdue_limit') AS bigint) AS overdue_limit
          , json_from_protobuf(get_json_object(new_data, '$.extinfo')) as new_data_extinfo
          , json_from_protobuf(get_json_object(old_data, '$.extinfo')) as old_data_extinfo
          ,ads_account_audit_extinfo
      FROM
        (
        SELECT
          id
          , userid
          , accountid
          , operator_email
          , timestamp
          , client_ip
          , platform
          , audit_event
          , CAST(old_data AS STRING) AS old_data
          , CAST(new_data AS STRING) AS new_data
          ,_decoded_extinfo as ads_account_audit_extinfo 
        FROM mp_paidads.shopee_ads_${region}_${db_type}__ads_account_audit_tab__reg_continuous_s0_live
        WHERE timestamp < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
        and timestamp >= UNIX_TIMESTAMP(DATE('${grass_date}'))
      )
    )
);

INSERT OVERWRITE TABLE dwd_advertiser_audit_di__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)    
    SELECT
        id
        , user_id
        , account_id
        , operator_email
        , client_ip
        , platform
        , event_timestamp
        , event_datetime
        , create_timestamp
        , create_datetime
        , modify_timestamp
        , modify_datetime
        , status
        , daily_pn_setting_is_off
        , daily_pn_balance_amt
        , (daily_pn_balance_amt / exrate.exchange_rate) AS daily_pn_balance_amt_usd
        , daily_pn_last_sending_hour
        , auto_topup_setting_is_on
        , auto_topup_threshold_amt
        , (auto_topup_threshold_amt / exrate.exchange_rate) AS auto_topup_threshold_amt_usd
        , auto_topup_amt
        , (auto_topup_amt / exrate.exchange_rate) AS auto_topup_amt_usd
        , campaign_day_setting_is_on
        , auto_topup_daily_cap_amt
        , auto_topup_daily_cap_amt / exrate.exchange_rate as auto_topup_daily_cap_amt_usd
        ,audit_event
        ,old_data
        ,new_data
        ,auto_budget_increase_setting
        ,auto_budget_increase_setting_is_on
        ,auto_budget_increase_daily_cap
        ,auto_budget_increase_percentage
        ,auto_budget_increase_setting_is_daily_reset
        ,auto_budget_increase_effective_types
        ,auto_budget_increase_latest_is_daily_reset_timestamp
        ,auto_budget_increase_is_daily_reset_setting_on_timestamp
        ,auto_budget_increase_campaign_days_daily_cap
        , old_data_extinfo
        , new_data_extinfo
        ,ads_account_audit_extinfo
        , a.grass_region
        , date('${grass_date}') as grass_date
    FROM (
        SELECT 
            id
            , user_id
            , account_id
            , operator_email
            , client_ip
            , platform
            , event_timestamp
            , event_datetime
            , create_timestamp
            , create_datetime
            , modify_timestamp
            , modify_datetime
            , status
            , CASE
                WHEN daily_pn_setting is NULL THEN NULL
                WHEN get_json_object(daily_pn_setting, '$.isOff') = true THEN 1
                WHEN get_json_object(daily_pn_setting, '$.isOff') = false THEN 0
            END as daily_pn_setting_is_off
            , CASE
                WHEN daily_pn_setting is NULL THEN NULL
                WHEN get_json_object(daily_pn_setting, '$.balance') is NULL THEN NULL
                ELSE CAST(get_json_object(daily_pn_setting, '$.balance') AS double) / 100000.0
            END as daily_pn_balance_amt
            , CASE
                WHEN daily_pn_setting is NULL THEN NULL
                WHEN get_json_object(daily_pn_setting, '$.timestamp') is NULL THEN NULL
                ELSE CAST(get_json_object(daily_pn_setting, '$.timestamp') AS bigint)
            END as daily_pn_last_sending_hour
            , CASE
                WHEN auto_topup_setting is NULL THEN NULL
                WHEN get_json_object(auto_topup_setting, '$.on') = true THEN 1
                WHEN get_json_object(auto_topup_setting, '$.on') = false THEN 0
            END as auto_topup_setting_is_on
            , CASE
                WHEN auto_topup_setting is NULL THEN NULL
                WHEN get_json_object(auto_topup_setting, '$.threshold') is NULL THEN NULL
                ELSE CAST(get_json_object(auto_topup_setting, '$.threshold') AS double) / 100000.0
            END as auto_topup_threshold_amt
            , CASE
                WHEN auto_topup_setting is NULL THEN NULL
                WHEN get_json_object(auto_topup_setting, '$.amount') is NULL THEN NULL
                ELSE CAST(get_json_object(auto_topup_setting, '$.amount') AS double) / 100000.0
            END as auto_topup_amt
            , CASE
                WHEN campaign_day_setting is NULL THEN NULL
                WHEN get_json_object(campaign_day_setting, '$.on') = true THEN 1
                WHEN get_json_object(campaign_day_setting, '$.on') = false THEN 0
            END as campaign_day_setting_is_on
            , CASE
                WHEN auto_topup_setting is NULL THEN NULL
                WHEN get_json_object(auto_topup_setting, '$.dailyCap') is NULL THEN NULL
                ELSE CAST(get_json_object(auto_topup_setting, '$.dailyCap') AS double) / 100000.0
            END as auto_topup_daily_cap_amt
            ,audit_event
            ,old_data
            ,new_data
            ,auto_budget_increase_setting
            , CASE
                WHEN autoBudgetIncreaseSetting is NULL THEN NULL
                WHEN autoBudgetIncreaseSetting.on = true THEN 1
                WHEN autoBudgetIncreaseSetting.on = false THEN 0
            END as auto_budget_increase_setting_is_on
            ,autoBudgetIncreaseSetting.dailyCap as auto_budget_increase_daily_cap
            , CASE
                WHEN autoBudgetIncreaseSetting.increasePct is NULL THEN NULL
                ELSE CAST(autoBudgetIncreaseSetting.increasePct AS double) / 100000.0
            END as auto_budget_increase_percentage
            , CASE
                WHEN autoBudgetIncreaseSetting is NULL THEN NULL
                WHEN autoBudgetIncreaseSetting.isDailyReset = true THEN 1
                WHEN autoBudgetIncreaseSetting.isDailyReset = false THEN 0
            END as auto_budget_increase_setting_is_daily_reset
            ,autoBudgetIncreaseSetting.effectiveTypes as auto_budget_increase_effective_types
            ,cast(autoBudgetIncreaseSetting.latestIsDailyResetTimestamp as bigint) as auto_budget_increase_latest_is_daily_reset_timestamp
            , CASE
                WHEN autoBudgetIncreaseSetting is NULL THEN NULL
                WHEN autoBudgetIncreaseSetting.isDailyResetSettingOnTimestamp = true THEN 1
                WHEN autoBudgetIncreaseSetting.isDailyResetSettingOnTimestamp = false THEN 0
            END as auto_budget_increase_is_daily_reset_setting_on_timestamp
            ,  autoBudgetIncreaseSetting.campaignDaysDailyCap as auto_budget_increase_campaign_days_daily_cap
            , old_data_extinfo
            , new_data_extinfo
            ,ads_account_audit_extinfo
            ,upper('${region}') as grass_region
        FROM ads_account_audit
    ) a
    LEFT OUTER JOIN
    (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
    ) exrate
    ON a.grass_region = exrate.grass_region;

alter table dwd_advertiser_audit_di__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');