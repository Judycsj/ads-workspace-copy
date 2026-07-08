-- task_code: data_paidadsmart.studio_3334486  asset_id: 3334486
SET TIME ZONE '${timezone}';

INSERT OVERWRITE TABLE dim_program__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
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
    ,program_start_timestamp
    ,program_start_datetime
    ,display_timestamp
    ,CASE
        WHEN display_timestamp is NULL THEN NULL
        ELSE from_unixtime(display_timestamp, 'yyyy-MM-dd HH:mm:ss')
    END AS display_datetime
    ,learn_more_link
    ,credit_expiry_duration
    ,credit_claim_period
    ,cashback_onboarding
    ,cashback_multi
    ,fixed_multi
    ,default_daily_budget
    ,owner_operator_type
    ,is_auto_claim
    ,null as program_type_name
    ,a.grass_region AS grass_region
    ,DATE('${grass_date}') as grass_date
FROM (
    SELECT
        program_id
        ,program_name
        ,program_status
        ,segment_id
        ,program_type
        ,program_quota
        ,extinfo
        ,cast(get_json_object(extinfo, '$.qss.sku_number') AS bigint) AS sku_number
        ,cast(get_json_object(extinfo, '$.qss.topup_window') AS bigint) AS topup_window
        ,cast(get_json_object(extinfo, '$.qss.min_topup')  AS double) / 100000.0 AS min_topup
        ,cast(get_json_object(extinfo, '$.qss.topup_deadline') AS bigint) AS topup_deadline
        ,cast(get_json_object(extinfo, '$.qss.free_credit') AS double) / 100000.0 AS free_credit
        ,cast(get_json_object(extinfo, '$.qss.credit_expiry_duation') AS bigint) AS credit_expiry_duation
        ,cast(get_json_object(extinfo, '$.qss.item_price_floor') AS double) / 100000.0 AS item_price_floor
        ,cast(get_json_object(extinfo, '$.qss.default_daily_budget') AS double) / 100000.0 AS default_daily_budget
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
        ,cast(get_json_object(extinfo, '$.incentive.display_time') AS bigint) AS display_timestamp
        ,get_json_object(extinfo, '$.incentive.learn_more_link') AS learn_more_link
        ,cast(get_json_object(extinfo, '$.incentive.credit_expiry_duration') AS bigint) AS credit_expiry_duration
        ,cast(get_json_object(extinfo, '$.incentive.credit_claim_period') AS bigint) AS credit_claim_period
        ,get_json_object(extinfo, '$.cashback_onboarding') as cashback_onboarding
        ,get_json_object(extinfo, '$.cashback_multi') as cashback_multi
        ,get_json_object(extinfo, '$.fixed_multi') as fixed_multi
        ,cast(get_json_object(extinfo, '$.access_control.owner_operator_type') as int) as owner_operator_type
        ,cast(get_json_object(extinfo, '$.incentive.is_auto_claim') AS boolean ) AS is_auto_claim
        ,upper('${region}') AS grass_region
    FROM (
        select 
            id AS program_id
            , program_name
            , program_status
            , COALESCE(segmentid, 0) AS segment_id
            , program_type
            , quota AS program_quota
            , CASE
                WHEN CAST(decode(extinfo, 'utf-8') AS string) = '' OR LOWER(CAST(decode(extinfo, 'utf-8') AS string)) = 'null' THEN NULL
                ELSE decode(extinfo, 'utf-8')
              END AS extinfo
            , end_time AS program_end_timestamp
            , CASE
                WHEN end_time is NULL THEN NULL
                ELSE from_unixtime(end_time, 'yyyy-MM-dd HH:mm:ss')
              END AS program_end_datetime
            , operator_id
            , operator
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
            , start_time AS program_start_timestamp
            ,  CASE
                WHEN start_time is NULL THEN NULL
                ELSE from_unixtime(start_time, 'yyyy-MM-dd HH:mm:ss')
              END AS program_start_datetime
        FROM mp_paidads.shopee_ads_srm_${region}_db__program_tab__reg_daily_s0_live
        WHERE ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
        )
) a
LEFT OUTER JOIN (
    SELECT
        grass_region
        ,exchange_rate
    FROM mp_order.dim_exchange_rate__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE '${grass_date}'
) exrate
ON a.grass_region = exrate.grass_region

union all 

select  
    a.id as program_id
    ,program_name
    ,program_status
    ,null as segment_id
    ,null as program_type
    ,null as program_quota
    ,a._decoded_extinfo as extinfo
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
    , end_time AS program_end_timestamp
    , CASE
        WHEN end_time is NULL THEN NULL
        ELSE from_unixtime(end_time, 'yyyy-MM-dd HH:mm:ss')
        END AS program_end_datetime       
    ,null as operator_id
    ,null as operator
    , a.ctime AS program_create_timestamp
    , CASE
        WHEN a.ctime is NULL THEN NULL
        ELSE from_unixtime(a.ctime, 'yyyy-MM-dd HH:mm:ss')
        END AS program_create_datetime
    , a.mtime AS program_last_modified_timestamp
    , CASE
        WHEN a.mtime is NULL THEN NULL
        ELSE from_unixtime(a.mtime, 'yyyy-MM-dd HH:mm:ss')
        END AS program_last_modified_datetime
    , a.start_time AS program_start_timestamp
    ,  CASE
        WHEN start_time is NULL THEN NULL
        ELSE from_unixtime(start_time, 'yyyy-MM-dd HH:mm:ss')
        END AS program_start_datetime
    ,null as display_timestamp
    ,null as display_datetime
    ,null as learn_more_link
    ,null as credit_expiry_duration
    ,null as credit_claim_period
    ,null as cashback_onboarding
    ,null as cashback_multi
    ,null as fixed_multi
    ,null as default_daily_budget
    ,null as owner_operator_type
    ,null as is_auto_claim
    ,b.program_type_name as program_type_name
    ,upper('${region}') AS grass_region
    ,DATE('${grass_date}') as grass_date
from mp_paidads.shopee_ads_srm_${region}_db__program_v2_tab__reg_continuous_s0_live a 
left join mp_paidads.shopee_ads_srm_${region}_db__program_type_tab__reg_continuous_s0_live b 
on a.program_type_id = b.id
;

alter table dim_program__${region}_s0_live add if not exists partition (grass_date = '${grass_date}');