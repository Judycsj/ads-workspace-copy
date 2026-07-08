-- task_code: data_paidadsmart.studio_2622208  asset_id: 2622208
CREATE OR REPLACE TEMPORARY VIEW campaign_tab_df AS
(
    SELECT
        campaignid AS campaign_id
        , status
        , shopid AS shop_id
        , userid AS user_id
        , start_time AS start_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(start_time as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as start_datetime
        , end_time AS end_timestamp
        , CASE
            WHEN (end_time = 0 OR end_time is NULL) THEN NULL
            ELSE date_format(from_utc_timestamp(to_utc_timestamp(cast(end_time as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss')
          END AS end_datetime
        , ctime AS create_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as create_datetime
        , mtime AS modify_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(mtime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as modify_datetime
        , daily_quota
        , total_quota
        , campaign_type
        , from_json(_decoded_extinfo, 'struct<
                        target_platform: array<int>,
                        is_auto_boost: boolean,
                        unselected_days: array<bigint>,
                        detail: string,
                        quota_splits: array<struct<
                            placement: int,
                            daily_available_quota: string,
                            version: int,
                            placements: array<int>
                        >>,
                        version: int,
                        migration_task_id: bigint,
                        target_broad_roi: struct<
                            value: int
                        >,
                        live_stream: struct<
                            time_slots: array<struct<
                                start_time: int,
                                end_time: int
                            >>,
                            create_restart_time: bigint
                        >,
                        creation_entry_point: int,
                        roi_two: struct<
                            target_value: int,
                            simple_roi_two_estimate: struct<
                                est_roi_lower_bound: int,
                                est_roi_upper_bound: int,
                                est_order_lower_bound: string,
                                est_order_upper_bound: string
                            >,
                            is_upgraded: boolean,
                            target_recommendation: struct<
                                values: array<struct<
                                    algo_value: string,
                                    final_value: string,
                                    percentile: int
                                >>,
                                is_default: boolean,
                                entry_point: int,
                                timestamp: string,
                                api_source: int
                            >,
                            is_npa: boolean,
                            display_target_value: int
                        >,
                        new_product_boost: struct<
                            current_state: boolean,
                            boosted_before: boolean
                        >,
                        auto_budget_increase: struct<
                            counter: int,
                            last_increment_timestamp: string,
                            user_last_daily_quota: string,
                            last_daily_reset_timestamp: string
                        >,
                        cps: struct<
                            cps: boolean,
                            last_cps_timestamp: string
                        >,
                        is_entry_point_eligible_potential: boolean,
                        product_gms: struct<
                            num_item_pool: int,
                            estimate: struct<
                                has_est: boolean,
                                roi_lower_bound: int,
                                roi_upper_bound: int,
                                bid_roi: int
                            >
                        >,
                        rapid_boost: struct<
                            is_on: boolean
                        >,
                        creation_platform: int,
                        npa: struct<
                            current_phase: int
                        >,
                        gmv_type: struct<
                            type: int
                        >,
                        campaign_tag: string,
                        auto_ads_solution: struct<
                            is_on: boolean
                        >
                    >') as decoded_extinfo
        , upper('${region}') AS grass_region
    FROM 
        (
            select /*+ REPARTITION(200) */  *
            from mp_paidads.shopee_ads_${region}_${db_type}__campaign_tab__reg_continuous_s0_live
        )
    WHERE ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
);


INSERT OVERWRITE TABLE dim_campaign__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  campaign_id
            ,shop_id
            ,user_id
            ,campaign_status
            ,CASE WHEN campaign_status = 0 THEN 'ADS_DELETED'
                  WHEN campaign_status = 1 THEN 'ADS_NORMAL'
                  WHEN campaign_status = 2 THEN 'ADS_PAUSED'
                  WHEN campaign_status = 3 THEN 'ADS_CLOSED'
                  WHEN campaign_status = 4 THEN 'ADS_TEMP_RESERVED'
                  WHEN campaign_status = 5 THEN 'ADS_CANCELLED'
                  WHEN campaign_status = 6 THEN 'ADS_BANNED'
                  WHEN campaign_status = 7 THEN 'ADS_DELETED_HIDE'
                  ELSE 'OTHERS'
            END AS campaign_status_text
            ,campaign_start_datetime
            ,campaign_end_datetime
            ,campaign_create_datetime
            ,campaign_modify_datetime
            ,total_quota / 100000.0 AS total_quota_local
            ,daily_quota / 100000.0 AS daily_quota_local
            ,total_quota / 100000.0 / exchange_rate AS total_quota_usd
            ,daily_quota / 100000.0 / exchange_rate AS daily_quota_usd
            ,quota_splits
            ,campaign_start_timestamp
            ,campaign_end_timestamp
            ,campaign_create_timestamp
            ,campaign_modify_timestamp
            ,roi_two / 100000.0 as roi_two
            ,campaign_type
            ,auto_budget_increase_counter
            ,last_increment_timestamp
            ,user_last_daily_quota/ 100000.0 as user_last_daily_quota
            ,last_daily_reset_timestamp
            ,creation_entry_point
            ,named_struct(
                'est_roi_lower_bound', est_roi_lower_bound / 100000
                ,'est_roi_upper_bound', est_roi_upper_bound / 100000
                ,'est_order_lower_bound', est_order_lower_bound
                ,'est_order_upper_bound', est_order_upper_bound
            ) as simple_roi_two_estimate
            ,is_upgraded
            ,is_cps
            ,last_cps_timestamp
            ,final_value_list
            ,suggest_roi_entry_point
            ,is_rapid_boost_on
            ,named_struct(
                'has_est', product_gms_estimate.has_est 
                ,'roi_lower_bound', product_gms_estimate.roi_lower_bound / 100000.0
                ,'roi_upper_bound', product_gms_estimate.roi_upper_bound / 100000.0
                ,'bid_roi', product_gms_estimate.bid_roi / 100000.0
            ) as product_gms_estimate
            ,creation_platform
            ,is_npa 
            ,npa_current_phase
            ,gmv_type
            ,campaign_tag
            ,suggest_roi_api_source
            ,is_auto_ads_solution_on
            ,roi_two_display_target_value / 100000.00 as roi_two_display_target_value
            ,campaign.region as grass_region
            ,DATE('${grass_date}') as grass_date
    FROM (
        SELECT  campaign_id
                ,shop_id
                ,user_id
                ,status AS campaign_status
                ,start_datetime AS campaign_start_datetime
                ,end_datetime AS campaign_end_datetime
                ,create_datetime AS campaign_create_datetime
                ,modify_datetime AS campaign_modify_datetime
                ,total_quota
                ,daily_quota
                ,decoded_extinfo.quota_splits
                ,start_timestamp AS campaign_start_timestamp
                ,end_timestamp as campaign_end_timestamp
                ,create_timestamp as campaign_create_timestamp
                ,modify_timestamp as campaign_modify_timestamp
                ,decoded_extinfo.roi_two.target_value as roi_two
                ,campaign_type
                ,decoded_extinfo.auto_budget_increase.counter  as auto_budget_increase_counter
                ,cast(decoded_extinfo.auto_budget_increase.last_increment_timestamp as bigint) as last_increment_timestamp
                ,cast(decoded_extinfo.auto_budget_increase.user_last_daily_quota as bigint)  as user_last_daily_quota
                ,cast(decoded_extinfo.auto_budget_increase.last_daily_reset_timestamp as bigint) as last_daily_reset_timestamp
                ,cast(decoded_extinfo.roi_two.simple_roi_two_estimate.est_roi_lower_bound as double) as est_roi_lower_bound
                ,cast(decoded_extinfo.roi_two.simple_roi_two_estimate.est_roi_upper_bound as double) as est_roi_upper_bound
                ,cast(decoded_extinfo.roi_two.simple_roi_two_estimate.est_order_lower_bound as bigint) as est_order_lower_bound
                ,cast(decoded_extinfo.roi_two.simple_roi_two_estimate.est_order_upper_bound as bigint) as est_order_upper_bound
                ,CASE
                    WHEN decoded_extinfo.roi_two.is_upgraded is NULL THEN NULL
                    WHEN decoded_extinfo.roi_two.is_upgraded = true THEN 1
                    WHEN decoded_extinfo.roi_two.is_upgraded = false THEN 0
                END as is_upgraded
                ,CASE
                    WHEN decoded_extinfo.cps.cps is NULL THEN NULL
                    WHEN decoded_extinfo.cps.cps = true THEN 1
                    WHEN decoded_extinfo.cps.cps = false THEN 0
                END as is_cps
                ,cast(decoded_extinfo.cps.last_cps_timestamp as bigint) as last_cps_timestamp
                ,decoded_extinfo.creation_entry_point
                ,transform(
                    decoded_extinfo.roi_two.target_recommendation.values, 
                    x -> cast(x.final_value as bigint) / 100000.0
                ) as final_value_list
                ,decoded_extinfo.roi_two.target_recommendation.entry_point as suggest_roi_entry_point
                ,decoded_extinfo.roi_two.target_recommendation.api_source as suggest_roi_api_source
                ,CASE
                    WHEN decoded_extinfo.rapid_boost.is_on is NULL THEN NULL
                    WHEN decoded_extinfo.rapid_boost.is_on = true THEN 1
                    WHEN decoded_extinfo.rapid_boost.is_on = false THEN 0
                END as is_rapid_boost_on
                ,decoded_extinfo.product_gms.estimate as product_gms_estimate
                ,decoded_extinfo.creation_platform
                ,CASE
                    WHEN decoded_extinfo.roi_two.is_npa is NULL THEN NULL
                    WHEN decoded_extinfo.roi_two.is_npa = true THEN 1
                    WHEN decoded_extinfo.roi_two.is_npa = false THEN 0
                END as is_npa
                ,decoded_extinfo.npa.current_phase as npa_current_phase
                ,decoded_extinfo.gmv_type.`type` as gmv_type
                ,cast(decoded_extinfo.campaign_tag as bigint) as campaign_tag
                ,CASE
                    WHEN decoded_extinfo.auto_ads_solution.is_on is NULL THEN NULL
                    WHEN decoded_extinfo.auto_ads_solution.is_on = true THEN 1
                    WHEN decoded_extinfo.auto_ads_solution.is_on = false THEN 0
                END as is_auto_ads_solution_on
                ,decoded_extinfo.roi_two.display_target_value as roi_two_display_target_value
                ,grass_region AS region
        FROM campaign_tab_df
    ) campaign
    LEFT OUTER JOIN (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}') 
    ) exrate
    ON campaign.region = exrate.grass_region;

alter table dim_campaign__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');