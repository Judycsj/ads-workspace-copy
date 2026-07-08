-- task_code: data_paidadsmart.studio_3335654  asset_id: 3335654
set time zone '${timezone}';
create or replace temporary view  white_blacklist as
select  id
        ,segmentid AS segment_id
        ,model_type AS model_type_id
        ,CASE
            WHEN model_type = 1 THEN 'BLACKLIST'
            WHEN model_type = 2 THEN 'WHITELIST'
        END AS model_type
        ,shopid AS shop_id
        ,model_status AS model_status_id
        ,CASE
            WHEN model_status = 0 THEN 'DELETED'
            WHEN model_status = 1 THEN 'NORMAL'
            WHEN model_status = 2 THEN 'PENDING_ADD'
            WHEN model_status = 3 THEN 'PENDING_DELETE'
        END AS model_status
        ,ctime AS segment_create_timestamp
        ,case   when ctime is NULL THEN NULL
                ELSE from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss')
         end as segment_create_datetime
        ,mtime AS segment_last_modified_timestamp
        ,case   when mtime is NULL THEN NULL
                ELSE from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss')
         end as segment_last_modified_datetime
        ,ucase('${region}') grass_region
from    mp_paidads.shopee_ads_srm_${region}_db__segment_white_blacklist_model_tab__reg_daily_s0_live
where   ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
;

create or replace temporary view  dim_program as
SELECT
            program_id
            ,program_name
            ,program_status
            ,segment_id
            ,program_type
            ,program_quota
            ,extinfo
            ,sku_number
            ,topup_window
            ,min_topup_amt
            ,min_topup_amt_usd
            ,topup_deadline_timestamp
            ,topup_deadline_datetime
            ,free_credit_amt
            ,free_credit_amt_usd
            ,credit_expiry_days_cnt
            ,min_item_price_amt
            ,min_item_price_amt_usd
            ,program_end_timestamp
            ,program_end_datetime
            ,operator_id
            ,operator
            ,program_create_timestamp
            ,program_create_datetime
            ,program_last_modified_timestamp
            ,program_last_modified_datetime
            ,program_start_timestamp
            ,program_start_datetime
            ,display_timestamp 
            ,display_datetime 
            ,credit_expiry_duration
            ,credit_claim_period
            ,learn_more_link
            ,default_daily_budget
            ,owner_operator_type
            ,program_type_name
            ,grass_region
        FROM mp_paidads.dim_program__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
        ;

create or replace temporary view seller_qss_config as
SELECT
            shopid AS shop_id
            ,programid as program_id
            ,_decoded_extinfo as extinfo
            ,cast(get_json_object(_decoded_extinfo, '$.qss.sku_number') AS bigint) AS sku_number
            ,cast(get_json_object(_decoded_extinfo, '$.qss.topup_window') AS bigint) AS topup_window
            ,cast(get_json_object(_decoded_extinfo, '$.qss.min_topup')  AS double) / 100000.0 AS min_topup
            ,cast(get_json_object(_decoded_extinfo, '$.qss.topup_deadline') AS bigint) AS topup_deadline
            ,cast(get_json_object(_decoded_extinfo, '$.qss.free_credit') AS double) / 100000.0 AS free_credit
            ,cast(get_json_object(_decoded_extinfo, '$.qss.credit_expiry_duation') AS bigint) AS credit_expiry_duation
            ,cast(get_json_object(_decoded_extinfo, '$.qss.item_price_floor') AS double) / 100000.0 AS item_price_floor
            ,cast(get_json_object(_decoded_extinfo, '$.qss.default_daily_budget') AS double) / 100000.0 AS default_daily_budget
            , ctime AS program_create_timestamp
            , CASE
                WHEN ctime is NULL THEN NULL
                ELSE from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss')
             END AS program_create_datetime
            , mtime AS program_last_modified_timestamp
            , CASE
                WHEN mtime is NULL THEN NULL
                ELSE from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss')
              END AS program_last_modified_datetime
            ,config_status as seller_qss_config_status
            ,ucase('${region}') as grass_region
        FROM mp_paidads.shopee_ads_srm_${region}_db__seller_qss_config_tab__reg_continuous_s0_live
        WHERE ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
;

create or replace temporary view  seller_program as
SELECT
            id as incentive_id
            ,shopid AS shop_id
            ,programid AS program_id
            ,seller_program_type AS seller_program_event_id
            ,CASE
                WHEN seller_program_type = 0 THEN 'NOOP'
                WHEN seller_program_type = 1 THEN 'VIEW'
                WHEN seller_program_type = 2 THEN 'SIGNUP'
                WHEN seller_program_type = 3 THEN 'CREATE_ADS'
                WHEN seller_program_type = 4 THEN 'REMOVE'
                WHEN seller_program_type = 5 THEN 'RESUME'
                WHEN seller_program_type = 6 THEN 'CHECK_TOPUP'
                WHEN seller_program_type = 7 THEN 'JOIN_OTHERS'
                WHEN seller_program_type = 8 THEN 'READ_ADS'
            END AS seller_program_event
            ,seller_program_status AS seller_program_status_id
            ,CASE
                WHEN seller_program_status = 0   THEN 'NOT_STARTED'
                WHEN seller_program_status = 1   THEN 'READY'
                WHEN seller_program_status = 2   THEN 'COMPLETED'
                WHEN seller_program_status = 3   THEN 'FAILED'
                WHEN seller_program_status = 4   THEN 'REMOVED'
                WHEN seller_program_status = 5   THEN 'ADS_CREATE_SUCCESS'
                WHEN seller_program_status = 6   THEN 'ADS_CREATE_FAILURE'
                WHEN seller_program_status = 7   THEN 'CREDIT_INJECTION_SUCCESS'
                WHEN seller_program_status = 8   THEN 'CREDIT_INJECTION_FAILURE'
                WHEN seller_program_status = 9   THEN 'ADS_CREATION_SUCCESS_END'
                WHEN seller_program_status = 10  THEN 'CREDIT_INJECTION_SUCCESS_END'
                WHEN seller_program_status = 11  THEN 'JOIN_OTHER_PROGRAM'
                WHEN seller_program_status = 12  THEN 'REWARD_CLAIM_FAILURE'
                WHEN seller_program_status = 100 THEN 'PREVIOUS_STATE'
            END AS seller_program_status
            ,sign_up_time AS sign_up_timestamp
            ,case   when sign_up_time is NULL THEN NULL
                ELSE from_unixtime(sign_up_time, 'yyyy-MM-dd HH:mm:ss')
         end as sign_up_datetime
            ,deadline AS deadline_timestamp
            ,case   when deadline is NULL THEN NULL
                ELSE from_unixtime(deadline, 'yyyy-MM-dd HH:mm:ss')
         end as deadline_datetime
            ,ctime AS seller_program_onboard_timestamp
            ,case   when ctime is NULL THEN NULL
                ELSE from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss')
         end as seller_program_onboard_datetime
            ,mtime AS seller_program_last_modified_timestamp
            ,case   when mtime is NULL THEN NULL
                ELSE from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss')
         end as seller_program_last_modified_datetime
            ,_decoded_extinfo AS seller_program_extinfo
            ,ucase('${region}') grass_region
    FROM mp_paidads.shopee_ads_srm_${region}_db__seller_program_tab__reg_continuous_s0_live
    WHERE ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1));


-- 2025-06-06 deprecated
-- create or replace temporary view  seller_program_view as
-- SELECT
--             shopid AS shop_id
--             ,programid AS program_id
--             ,ctime AS advertiser_program_popup_create_timestamp
--             ,case   when ctime is NULL THEN NULL
--                 ELSE from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss')
--          end AS advertiser_program_popup_create_datetime
--             ,ucase('${region}') grass_region
-- FROM mp_paidads.shopee_ads_srm_${region}_db__seller_program_view_tab__reg_daily_s0_live
--     WHERE ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1));

INSERT OVERWRITE TABLE dim_advertiser_segment_program__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT
        id
        ,a.segment_id
        ,model_type_id
        ,model_type
        ,b.shop_id as shop_id
        ,model_status_id
        ,model_status
        ,segment_create_timestamp
        ,segment_create_datetime
        ,segment_last_modified_timestamp
        ,segment_last_modified_datetime
        ,a.program_id
        ,program_name
        ,program_status
        ,program_type
        ,program_quota
        ,extinfo
        ,sku_number
        ,topup_window
        ,min_topup_amt
        ,min_topup_amt_usd
        ,topup_deadline_timestamp
        ,topup_deadline_datetime
        ,free_credit_amt
        ,free_credit_amt_usd
        ,credit_expiry_days_cnt
        ,min_item_price_amt
        ,min_item_price_amt_usd
        ,program_end_timestamp
        ,program_end_datetime
        ,operator_id
        ,operator
        ,program_create_timestamp
        ,program_create_datetime
        ,program_last_modified_timestamp
        ,program_last_modified_datetime
        ,seller_program_event_id
        ,seller_program_event
        ,seller_program_status_id
        ,seller_program_status
        ,sign_up_timestamp
        ,sign_up_datetime
        ,deadline_timestamp
        ,deadline_datetime
        ,seller_program_onboard_timestamp
        ,seller_program_onboard_datetime
        ,seller_program_last_modified_timestamp
        ,seller_program_last_modified_datetime
        ,null as advertiser_program_popup_create_timestamp
        ,null as advertiser_program_popup_create_datetime
        ,seller_program_extinfo
        ,program_start_timestamp
        ,program_start_datetime
        ,display_timestamp
        ,display_datetime
        ,credit_expiry_duration
        ,credit_claim_period
        ,learn_more_link
        ,default_daily_budget
        ,owner_operator_type
        ,null as seller_qss_config_status
        ,incentive_id
        ,case 
            when program_type = '1' then cast(get_json_object(seller_program_extinfo, '$.qss.base.priority_score') as bigint) 
            when program_type in ('2', '3', '4') then cast(get_json_object(seller_program_extinfo, '$.incentive.priority_score') as bigint) 
            when program_type = '5' then cast(get_json_object(seller_program_extinfo, '$.cashback_onboarding.base.priority_score') as bigint) 
            when program_type = '6' then cast(get_json_object(seller_program_extinfo, '$.cashback_multi.base.priority_score') as bigint) 
            when program_type = '7' then cast(get_json_object(seller_program_extinfo, '$.fixed_multi.base.priority_score') as bigint) 
            when program_type = '8' then cast(get_json_object(seller_program_extinfo, '$.acp.base.priority_score') as bigint)
        end as priority_score
        ,null as program_type_name
        ,upper('${region}') AS grass_region
        ,DATE('${grass_date}') as grass_date
    FROM  
    (
        select *
        from dim_program
        -- for QSS new flow, if value = 2 -> algo: use seller_qss_config_tab
        where program_type is not null
        and (program_type <> '1' or COALESCE(owner_operator_type, 0) <> 2)
    ) a
    LEFT JOIN seller_program b
    ON a.program_id = b.program_id
    -- LEFT JOIN seller_program_view c
    -- ON b.shop_id = c.shop_id
    --     AND a.program_id = c.program_id
    LEFT JOIN white_blacklist d
    ON (a.segment_id = d.segment_id
        and b.shop_id = d.shop_id
        AND a.grass_region = d.grass_region)
    
    union all 

    select 
        null as id
        ,h.segment_id
        ,null as model_type_id
        ,null as model_type
        ,f.shop_id as shop_id
        ,null as model_status_id
        ,null as model_status
        ,null as segment_create_timestamp
        ,null as segment_create_datetime
        ,null as segment_last_modified_timestamp
        ,null as segment_last_modified_datetime
        ,h.program_id
        ,program_name
        ,program_status
        ,program_type
        ,program_quota
        ,extinfo
        ,sku_number
        ,topup_window
        ,min_topup AS min_topup_amt
        ,min_topup / exchange_rate AS min_topup_amt_usd
        ,topup_deadline AS topup_deadline_timestamp
        ,from_unixtime(topup_deadline, 'yyyy-MM-dd HH:mm:ss') AS topup_deadline_datetime
        ,free_credit AS free_credit_amt
        ,free_credit / exchange_rate AS free_credit_amt_usd
        ,credit_expiry_duation AS credit_expiry_days_cnt
        ,item_price_floor AS min_item_price_amt
        ,item_price_floor / exchange_rate AS min_item_price_amt_usd
        ,program_end_timestamp
        ,program_end_datetime
        ,operator_id
        ,operator
        ,program_create_timestamp
        ,program_create_datetime
        ,program_last_modified_timestamp
        ,program_last_modified_datetime
        ,seller_program_event_id
        ,seller_program_event
        ,seller_program_status_id
        ,seller_program_status
        ,sign_up_timestamp
        ,sign_up_datetime
        ,deadline_timestamp
        ,deadline_datetime
        ,seller_program_onboard_timestamp
        ,seller_program_onboard_datetime
        ,seller_program_last_modified_timestamp
        ,seller_program_last_modified_datetime
        ,null as advertiser_program_popup_create_timestamp
        ,null as advertiser_program_popup_create_datetime
        ,seller_program_extinfo
        ,program_start_timestamp
        ,program_start_datetime
        ,display_timestamp
        ,display_datetime
        ,credit_expiry_duration
        ,credit_claim_period
        ,learn_more_link
        ,default_daily_budget
        ,2 as owner_operator_type
        ,seller_qss_config_status
        ,incentive_id
        ,cast(get_json_object(seller_program_extinfo, '$.qss.base.priority_score') as bigint) as priority_score
        ,null as program_type_name
        ,upper('${region}') AS grass_region
        ,DATE('${grass_date}') as grass_date
    from 
    (
        select 
            program_id
            ,segment_id
            ,program_name
            ,program_status
            ,program_type
            ,program_quota
            ,program_end_timestamp
            ,program_end_datetime
            ,operator_id
            ,operator
            ,program_start_timestamp
            ,program_start_datetime
            ,display_timestamp
            ,display_datetime
            ,credit_expiry_duration
            ,credit_claim_period
            ,learn_more_link
            ,upper('${region}') AS grass_region
            ,DATE('${grass_date}') as grass_date
        from dim_program
        -- for QSS new flow, if value = 2 -> algo: use seller_qss_config_tab
        where program_type = '1'
        and owner_operator_type = 2
    ) h 
    LEFT JOIN seller_qss_config f
    ON h.program_id = f.program_id
    left join seller_program e
    on f.program_id = e.program_id
    and f.shop_id = e.shop_id
    LEFT JOIN (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE '${grass_date}'
    ) exrate
    ON h.grass_region = exrate.grass_region

    union all 

    select 
        null as id
        ,null as segment_id
        ,null as model_type_id
        ,null as model_type
        ,c.shop_id as shop_id
        ,null as model_status_id
        ,null as model_status
        ,null as segment_create_timestamp
        ,null as segment_create_datetime
        ,null as segment_last_modified_timestamp
        ,null as segment_last_modified_datetime
        ,a.program_id
        ,program_name
        ,program_status
        ,program_type
        ,program_quota
        ,a.extinfo
        ,null as sku_number
        ,null as topup_window
        ,null as min_topup_amt
        ,null as min_topup_amt_usd
        ,null as topup_deadline_timestamp
        ,null as topup_deadline_datetime
        ,null as free_credit_amt
        ,null as free_credit_amt_usd
        ,null as credit_expiry_days_cnt
        ,null as min_item_price_amt
        ,null as min_item_price_amt_usd
        ,program_end_timestamp
        ,program_end_datetime
        ,null as operator_id
        ,null as operator
        ,program_create_timestamp
        ,program_create_datetime
        ,program_last_modified_timestamp
        ,program_last_modified_datetime
        ,null as seller_program_event_id
        ,null as seller_program_event
        ,incentive_status as seller_program_status_id
        ,case when incentive_status = 0 then 'INACTIVE'
            when incentive_status = 1 then 'ACTIVE'
            when incentive_status = 2 then 'COMPLETED'
            when incentive_status = 3 then 'DISMISSED'
            when incentive_status = 4 then 'FAILED'
        end as seller_program_status
        ,null as sign_up_timestamp
        ,null as sign_up_datetime
        ,null as deadline_timestamp
        ,null as deadline_datetime
        ,b.ctime AS seller_program_onboard_timestamp
        ,case   when b.ctime is NULL THEN NULL
            ELSE from_unixtime(b.ctime, 'yyyy-MM-dd HH:mm:ss')
         end as seller_program_onboard_datetime
        ,b.mtime AS seller_program_last_modified_timestamp
        ,case   when b.mtime is NULL THEN NULL
            ELSE from_unixtime(b.mtime, 'yyyy-MM-dd HH:mm:ss')
         end as seller_program_last_modified_datetime
        ,null as advertiser_program_popup_create_timestamp
        ,null as advertiser_program_popup_create_datetime
        ,b._decoded_extinfo as seller_program_extinfo
        ,program_start_timestamp
        ,program_start_datetime
        ,null as display_timestamp
        ,null as display_datetime
        ,null as credit_expiry_duration
        ,null as credit_claim_period
        ,null as learn_more_link
        ,null as default_daily_budget
        ,null as owner_operator_type
        ,null as seller_qss_config_status
        ,b.incentive_id
        ,null as priority_score
        ,program_type_name
        ,upper('${region}') AS grass_region
        ,DATE('${grass_date}') as grass_date
    from (
        select *
        from dim_program 
        -- new program data flow
        where program_type_name is not null
    )a 
    left join mp_paidads.shopee_ads_srm_${region}_db__incentive_tab__reg_continuous_s0_live b
    ON a.program_id = b.program_id
    left join (
        select distinct shop_id, user_id
        FROM  mp_user.dim_user__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = '${grass_date}'
    )c
    on b.user_id = c.user_id
    ;


alter table dim_advertiser_segment_program__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");