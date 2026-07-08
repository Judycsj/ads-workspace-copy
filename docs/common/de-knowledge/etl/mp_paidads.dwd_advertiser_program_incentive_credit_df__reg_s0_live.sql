-- task_code: data_paidadsmart.studio_6783167  asset_id: 6783167
SET TIME ZONE '${timezone}';

CREATE EXTERNAL TABLE IF NOT EXISTS dwd_advertiser_program_incentive_credit_df__reg_s0_live
(
    shop_id  bigint
    ,segment_id bigint
    ,program_id bigint
    ,program_name string
    ,program_status bigint
    ,program_type int
    ,program_start_timestamp bigint
    ,program_start_datetime string
    ,program_end_timestamp bigint
    ,program_end_datetime string
    ,display_timestamp bigint
    ,display_datetime string
    ,learn_more_link string
    ,credit_expiry_duration bigint
    ,credit_claim_period bigint
    ,sign_up_timestamp bigint
    ,sign_up_datetime string
    ,deadline_timestamp bigint
    ,deadline_datetime string
    ,priority_score bigint
    ,is_dismissed boolean
    ,completion_timestamp bigint
    ,completion_datetime string
    ,granted_credit_amount double
    ,granted_credit_amount_usd double
    ,granted_credit_order_id bigint
    ,topup_target_amount double
    ,topup_target_amount_usd double
    ,topup_reward_amount double
    ,topup_reward_amount_usd double
    ,topup_amount double
    ,topup_amount_usd double
    ,topup_order_ids array<bigint>
    ,ads_placements array<int> comment 'DEPRECATED; use incentive_ads_placement'
    ,spending_amount double
    ,spending_amount_usd double
    ,target_spending_tiers string
    ,seller_program_status_id bigint
    ,seller_program_status string
    -- 2024-11-20
    ,cashback_onboarding_info    string
    ,cashback_multi_info string
    ,fixed_multi_info    string
    ,incentive_ads_placement int
    ,trigger_campaign_id bigint
    ,trigger_time    bigint
    ,baseline_amount double
    ,spending_period bigint
    ,last_spending_timestamp bigint
    ,spending_start_time bigint
    ,spending_end_time   bigint
    ,credit_effective_type   int
    ,credit_amount_cap   double
    ,credit_amount_cap_usd   double
    ,uncapped_credit_amount  double
    ,uncapped_credit_amount_usd  double
    -- 2025-02-27
    ,last_topup_timestamp bigint
    ,ads_creation_try int 
    ,ads_creation_time bigint 
    ,unread_ads boolean
    ,topup_orders bigint 
    ,credit_inject_time bigint
    ,program_extinfo string
    ,owner_operator_type int
    -- 2025-03-06
    ,is_auto_claim boolean 
    -- 2025-04-15
    ,incentive_id bigint 
    ,popup_score bigint 
    -- 2025-04-23 acp
    ,ads_credit_package_info string
    ,package_id bigint
    ,shop_total_stock bigint
    ,shop_used_stock  bigint
    ,original_price double
    ,discount_price double
    ,discount_percentage double
    ,expiry_type int
    ,expiry_days int
    ,expiry_time bigint
    ,is_deactivated boolean 
    ,is_oos boolean  
    ,cashback_compound_info string
    ,fixed_compound_info string 
    -- 2025-06-05 atu
    ,auto_topup_info string comment 'auto topup info'
    ,is_atu_on_before boolean comment 'whether auto topup has ever been turned on while the seller is enrolled'
    ,target_topup_tiers string
    -- 2025-06-11 multi-tier
    ,first_tier_completion_timestamp bigint
    -- 2025-10-15 confund
    ,credit_consumption_type int
    ,program_type_name string
    ,granted_credit_order_ids array<bigint>
)
COMMENT 'granted credit order for incentive program. Granularity: shop_id * segment_id * program_id * granted_credit_translog_id'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dwd_advertiser_program_incentive_credit_df__reg_s0_live/'
;

create or replace temporary view dim_seller_program as 
select
    id
    ,segment_id
    ,shop_id
    ,program_id
    ,program_name
    ,program_status
    ,cast(program_type as int) as program_type
    ,extinfo
    ,program_end_timestamp
    ,program_end_datetime
    ,seller_program_status_id
    ,seller_program_status
    ,sign_up_timestamp
    ,sign_up_datetime
    ,deadline_timestamp
    ,deadline_datetime
    ,seller_program_extinfo
    ,program_start_timestamp
    ,program_start_datetime
    ,display_timestamp
    ,display_datetime
    ,credit_expiry_duration
    ,credit_claim_period
    ,learn_more_link
    ,owner_operator_type
    ,incentive_id
    ,cast(get_json_object(seller_program_extinfo, '$.acp.package.package_id') as bigint) as package_id
    ,program_type_name
from mp_paidads.dim_advertiser_segment_program__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${BIZ_YESTERDAY}')
;


create or replace temporary view  old_flow_data as
select 
    shop_id
    ,segment_id
    ,program_id
    ,program_name
    ,program_status
    ,program_type
    ,program_start_timestamp
    ,program_start_datetime
    ,program_end_timestamp
    ,program_end_datetime
    ,display_timestamp
    ,display_datetime
    ,learn_more_link
    ,cast(get_json_object(credit_reward, '$.credit_expiry_duration') as bigint) as credit_expiry_duration
    ,cast(get_json_object(base, '$.credit_claim_period') as bigint) as credit_claim_period
    ,sign_up_timestamp
    ,sign_up_datetime
    ,deadline_timestamp
    ,deadline_datetime
    ,cast(get_json_object(base, '$.priority_score') as bigint) as priority_score
    ,cast(get_json_object(base, '$.is_dismissed') as boolean) as is_dismissed
    ,cast(get_json_object(base, '$.completion_time') as bigint) as completion_timestamp
    ,cast(get_json_object(credit_reward, '$.granted_credit_amount') as double) / 100000 as granted_credit_amount
    ,cast(get_json_object(credit_reward, '$.granted_credit_order_id') as bigint) as granted_credit_order_id
    ,cast(get_json_object(topup, '$.target_amount') as double) / 100000 as topup_target_amount
    ,cast(get_json_object(topup, '$.reward_amount') as double) / 100000 as topup_reward_amount
    ,cast(get_json_object(topup, '$.topup_amount') as double) / 100000 as topup_amount
    ,cast(from_json(get_json_object(topup, '$.topup_order_ids'),'array<string>') as array<bigint>) as topup_order_ids
    ,from_json(get_json_object(spending_objective, '$.ads_placements'),'array<int>') as ads_placements 
    ,cast(get_json_object(spending_objective, '$.spending_amount') as double) / 100000 as spending_amount
    ,get_json_object(spending_objective, '$.target_spending_tiers') as target_spending_tiers
    ,seller_program_status_id
    ,seller_program_status
    -- cashback_onboarding : program_type = 5
    ,cashback_onboarding_info
    -- cashback_multi : program_type = 6, 9
    ,cashback_multi_info
    -- fixed_multi : program_type = 7, 10
    ,fixed_multi_info
    ,cast(get_json_object(spending_objective, '$.incentive_ads_placement') as int) as incentive_ads_placement
    ,cast(get_json_object(cashback_onboarding_info, '$.ads_trigger.trigger_campaign_id') as bigint) as trigger_campaign_id
    ,cast(get_json_object(cashback_onboarding_info, '$.ads_trigger.trigger_time') as bigint) as trigger_time
    ,cast(get_json_object(spending_objective, '$.baseline_amount') as double) / 100000 as baseline_amount
    ,cast(get_json_object(spending_objective, '$.spending_period') as bigint) as spending_period
    ,cast(get_json_object(spending_objective, '$.last_spending_timestamp') as bigint) as last_spending_timestamp
    ,cast(get_json_object(spending_objective, '$.spending_start_time') as bigint) as spending_start_time
    ,cast(get_json_object(spending_objective, '$.spending_end_time') as bigint)as spending_end_time
    ,cast(get_json_object(credit_reward, '$.credit_effective_type') as int) as credit_effective_type
    ,cast(get_json_object(credit_reward, '$.credit_amount_cap') as double) / 100000 as credit_amount_cap
    ,cast(get_json_object(credit_reward, '$.uncapped_credit_amount') as double) / 100000 as uncapped_credit_amount
    ,cast(get_json_object(topup, '$.last_topup_timestamp') as bigint) as last_topup_timestamp
    ,cast(get_json_object(qss_info, '$.ads_creation_try') as int) as ads_creation_try
    ,cast(get_json_object(qss_info, '$.ads_creation_time') as bigint) as ads_creation_time
    ,cast(get_json_object(qss_info, '$.unread_ads') as boolean) as unread_ads
    ,cast(get_json_object(qss_info, '$.topup_orders') as bigint) as topup_orders
    ,cast(get_json_object(qss_info, '$.credit_inject_time') as bigint) as credit_inject_time
    ,extinfo as program_extinfo
    ,owner_operator_type
    ,cast(get_json_object(extinfo, '$.incentive.is_auto_claim') AS boolean ) AS is_auto_claim
    ,incentive_id
    ,cast(get_json_object(base, '$.popup_score') as bigint) as popup_score
    -- acp : program_type = 8
    ,ads_credit_package_info
    ,package_id
    ,shop_total_stock
    ,shop_used_stock
    ,cast(get_json_object(ads_credit_package_info, '$.package.original_price') as double) / 100000 as original_price
    ,cast(get_json_object(ads_credit_package_info, '$.package.discount_price') as double) / 100000 as discount_price
    ,cast(get_json_object(ads_credit_package_info, '$.package.discount_percentage') as double) / 100000 as discount_percentage
    ,cast(get_json_object(ads_credit_package_info, '$.package.expiry_type') as int) as expiry_type
    ,cast(get_json_object(ads_credit_package_info, '$.package.expiry_days') as int) as expiry_days
    ,cast(get_json_object(ads_credit_package_info, '$.package.expiry_time') as bigint) as expiry_time
    ,cast(get_json_object(ads_credit_package_info, '$.package.is_deactivated') as boolean) as is_deactivated
    ,cast(get_json_object(ads_credit_package_info, '$.package.is_oos') as boolean) as is_oos
    -- cashback_compound : program_type = 11
    ,cashback_compound_info
    -- fixed_compound : program_type = 12
    ,fixed_compound_info
    -- auto_topup : program_type = 13
    ,auto_topup_info
    ,cast(get_json_object(auto_topup_info, '$.is_atu_on_before') as boolean) as is_atu_on_before
    ,get_json_object(topup, '$.target_topup_tiers') as target_topup_tiers
    ,cast(get_json_object(base, '$.first_tier_completion_time') as bigint) as first_tier_completion_timestamp
    -- ,topup_multi_info
    -- ,get_json_object(coalesce(topup, spending_objective), '$.tier_completion_list') as tier_completion_list
    ,cast(get_json_object(extinfo, '$.incentive.credit_consumption_type') AS int ) AS credit_consumption_type
    ,upper('${region}') as grass_region
    ,DATE('${BIZ_YESTERDAY}') as grass_date 
from(
    select 
            id
            ,segment_id
            ,shop_id
            ,program_id
            ,program_name
            ,program_status
            ,program_type
            ,extinfo
            ,program_end_timestamp
            ,program_end_datetime
            ,seller_program_status_id
            ,seller_program_status
            ,sign_up_timestamp
            ,sign_up_datetime
            ,deadline_timestamp
            ,deadline_datetime
            ,seller_program_extinfo
            ,program_start_timestamp
            ,program_start_datetime
            ,display_timestamp
            ,display_datetime
            ,credit_expiry_duration
            ,credit_claim_period
            ,learn_more_link
            ,owner_operator_type
            ,incentive_id
            ,package_id
            ,shop_total_stock
            ,shop_used_stock
            ,case 
                when program_type = 1 then get_json_object(seller_program_extinfo, '$.qss.base') 
                when program_type in (2, 3, 4) then get_json_object(seller_program_extinfo, '$.incentive')
                when program_type = 5 then get_json_object(seller_program_extinfo, '$.cashback_onboarding.base') 
                when program_type in (6, 9) then get_json_object(seller_program_extinfo, '$.cashback_multi.base') 
                when program_type in (7, 10) then get_json_object(seller_program_extinfo, '$.fixed_multi.base') 
                when program_type = 8 then get_json_object(seller_program_extinfo, '$.acp.base') 
                when program_type = 11 then get_json_object(seller_program_extinfo, '$.cashback_compound.base')
                when program_type = 12 then get_json_object(seller_program_extinfo, '$.fixed_compound.base')
                when program_type = 13 then get_json_object(seller_program_extinfo, '$.atu.base')
                when program_type = 14 then get_json_object(seller_program_extinfo, '$.topup_multi.base')
            end as base
            ,case 
                when program_type in (2, 3, 4) then get_json_object(seller_program_extinfo, '$.incentive.spending') 
                when program_type = 5 then get_json_object(seller_program_extinfo, '$.cashback_onboarding.spending_objective')
                when program_type in (6, 9) then get_json_object(seller_program_extinfo, '$.cashback_multi.spending_objective')
                when program_type in (7, 10) then get_json_object(seller_program_extinfo, '$.fixed_multi.spending_objective') 
                when program_type = 11 then get_json_object(seller_program_extinfo, '$.cashback_compound.spending_objective')
                when program_type = 12 then get_json_object(seller_program_extinfo, '$.fixed_compound.spending_objective')
            end as spending_objective
            ,case 
                when program_type = 1 then get_json_object(seller_program_extinfo, '$.qss') 
                when program_type in (2, 3, 4) then get_json_object(seller_program_extinfo, '$.incentive')
                when program_type = 5 then get_json_object(seller_program_extinfo, '$.cashback_onboarding.credit_reward')
                when program_type in (6, 9) then get_json_object(seller_program_extinfo, '$.cashback_multi.credit_reward')
                when program_type in (7, 10) then get_json_object(seller_program_extinfo, '$.fixed_multi.credit_reward')
                when program_type = 11 then get_json_object(seller_program_extinfo, '$.cashback_compound.credit_reward')
                when program_type = 12 then get_json_object(seller_program_extinfo, '$.fixed_compound.credit_reward')
                when program_type = 13 then get_json_object(seller_program_extinfo, '$.atu.credit_reward')
                when program_type = 14 then get_json_object(seller_program_extinfo, '$.topup_multi.credit_reward')
            end as credit_reward
            ,case 
                when program_type = 1 then get_json_object(seller_program_extinfo, '$.qss')
                when program_type in (2, 3, 4) then get_json_object(seller_program_extinfo, '$.incentive.topup')
                when program_type = 13 then get_json_object(seller_program_extinfo, '$.atu.topup')
                when program_type = 14 then get_json_object(seller_program_extinfo, '$.topup_multi.topup')
            end as topup
            ,get_json_object(seller_program_extinfo, '$.qss') as qss_info
                -- cashback_onboarding : program_type = 5
            ,get_json_object(seller_program_extinfo, '$.cashback_onboarding') as cashback_onboarding_info
            -- cashback_multi : program_type = 6, 9
            ,get_json_object(seller_program_extinfo, '$.cashback_multi') as cashback_multi_info
            -- fixed_multi : program_type = 7, 10
            ,get_json_object(seller_program_extinfo, '$.fixed_multi') as fixed_multi_info
            -- acp : program_type = 8
            ,get_json_object(seller_program_extinfo, '$.acp') as ads_credit_package_info
            -- cashback_compound : program_type = 11
            ,get_json_object(seller_program_extinfo, '$.cashback_compound') as cashback_compound_info
            -- fixed_compound : program_type = 12
            ,get_json_object(seller_program_extinfo, '$.fixed_compound') as fixed_compound_info
            -- auto_topup : program_type = 13
            ,get_json_object(seller_program_extinfo, '$.atu') as auto_topup_info
            -- topup_multi_tier : program_type = 14
            ,get_json_object(seller_program_extinfo, '$.topup_multi') as topup_multi_info
    from (
        select *
        from dim_seller_program
        where program_type is not null
    ) a
    left join (
        select 
            ads_package_id
            -- ,_decoded_extinfo as ads_package_extinfo
            ,cast(get_json_object(_decoded_extinfo, '$.shop_level_total_stock') as bigint) as shop_total_stock
            ,total_order_done as shop_used_stock
        from mp_paidads.shopee_ads_${region}_db__ads_package_tab__reg_continuous_s0_live
    ) b 
    on a.package_id = b.ads_package_id
) ;


create or replace temporary view  new_flow_data as(
    select 
        shop_id
        ,program_id
        ,program_name
        ,program_status
        ,program_type
        ,program_type_name
        ,extinfo as program_extinfo
        ,program_end_timestamp
        ,program_end_datetime
        ,seller_program_status_id
        ,seller_program_status
        ,seller_program_extinfo
        ,program_start_timestamp
        ,program_start_datetime
        ,a.incentive_id
        ,granted_credit_order_ids
        ,granted_credit_amount
        ,target_topup_tiers
        ,topup_amount
        ,topup_order_ids
        ,first_tier_completion_timestamp
        ,completion_timestamp
        ,upper('${region}') as grass_region
        ,DATE('${BIZ_YESTERDAY}') as grass_date 
    from 
    (
        select *
        from dim_seller_program
        where program_type_name is not null
    ) a 
    left join 
    (
        select 
            incentive_id
            ,collect_list(granted_credit_order_id) as granted_credit_order_ids
            ,sum(granted_credit_amount) as granted_credit_amount
            ,collect_list(target_topup_tiers) as target_topup_tiers
            ,sum(topup_amount) as topup_amount
            ,flatten(collect_list(topup_order_ids)) as topup_order_ids
            ,min(completion_timestamp) as first_tier_completion_timestamp
            ,max(completion_timestamp) as completion_timestamp
        from (
            select 
                incentive_id
                ,incentive_node_id
                ,extinfo
                ,cast(extinfo.action_give_handout.state.credit_handout.order_id as bigint) as granted_credit_order_id
                ,cast(extinfo.action_give_handout.state.credit_handout.actual_amount as bigint) / 100000.00 as granted_credit_amount
                ,target_topup_tiers
                ,aggregate(extinfo.cond_accumulate_topup.state.progress_list, 0L, (acc, x) -> acc + cast(x.amount as bigint)) / 100000.00 AS topup_amount
                ,cast(flatten(transform(extinfo.cond_accumulate_topup.state.progress_list, x -> x.topup_order_ids)) as array<bigint>) AS topup_order_ids
                ,cast(extinfo.cond_accumulate_topup.state.completion_trace.event_time as bigint) as completion_timestamp
            from (
            select
                incentive_id
                ,incentive_node_id
                ,_decoded_extinfo
                ,get_json_object(_decoded_extinfo,'$.cond_accumulate_topup.config.objective') as target_topup_tiers
                ,from_json(_decoded_extinfo, 'struct<
                    action_give_handout: struct <
                        config: struct <
                            calc_method: INT,
                            credit_handout: struct <
                                expiry_period: INT,
                                effective_type: INT,
                                amount: STRING,
                                amount_cap: STRING
                            >,
                            action_config: struct <
                                min_trigger_time: STRING
                            >
                        >,
                        state: struct <
                            credit_handout: struct <
                                uncapped_amount: STRING,
                                actual_amount: STRING,
                                order_id: STRING,
                                order_time: STRING,
                                expiry_time: STRING,
                                order_uniq_sign: STRING
                            >
                        >
                    >,
                    cond_accumulate_topup: struct <
                        config: struct <
                            objective: struct <
                                target_list: ARRAY <
                                    struct <
                                        target_type: INT
                                        ,incentive_topup_category: INT
                                        ,target_amount_list: ARRAY <STRING>
                                    >
                                >
                                ,reward_list: ARRAY <
                                    struct <
                                        fixed_amount: STRING
                                    >
                                >
                            >
                            ,completion_config: struct <
                                topup_completion_type: INT
                                ,min_tier: INT
                            >
                        >
                        ,state: struct <
                            active_period: struct <
                                start_time: STRING
                                ,end_time: STRING
                            >
                            ,tier_state_list: ARRAY <
                                struct <
                                    tier_idx: INT
                                    ,completion_trace: struct <
                                        event_time: STRING
                                        ,event_channel: INT
                                    >
                                >
                            >
                            ,completion_trace: struct <
                                event_time: STRING
                                ,event_channel: INT
                            >
                            ,progress_list: ARRAY <
                                struct <
                                    incentive_topup_category: INT
                                    ,amount: string
                                    ,topup_order_ids: ARRAY <STRING>
                                >
                            >
                        >
                    >
                >') as extinfo
            
            from mp_paidads.shopee_ads_srm_${region}_db__incentive_node_tab__reg_continuous_s0_live
            where ctime < unix_timestamp(date_add(date('${BIZ_YESTERDAY}'), 1))
            )
        ) 
        group by incentive_id
    ) b 
    on a.incentive_id = b.incentive_id
)
;


INSERT OVERWRITE TABLE dwd_advertiser_program_incentive_credit_df__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    shop_id
    ,segment_id
    ,program_id
    ,program_name
    ,program_status
    ,program_type
    ,program_start_timestamp
    ,program_start_datetime
    ,program_end_timestamp
    ,program_end_datetime
    ,display_timestamp
    ,display_datetime
    ,learn_more_link
    ,credit_expiry_duration
    ,credit_claim_period
    ,sign_up_timestamp
    ,sign_up_datetime
    ,deadline_timestamp
    ,deadline_datetime
    ,priority_score
    ,is_dismissed
    ,completion_timestamp
    ,from_unixtime(completion_timestamp, 'yyyy-MM-dd HH:mm:ss') as completion_datetime
    ,granted_credit_amount
    ,granted_credit_amount / exchange_rate as granted_credit_amount_usd
    ,granted_credit_order_id
    ,topup_target_amount
    ,topup_target_amount / exchange_rate as topup_target_amount_usd 
    ,topup_reward_amount
    ,topup_reward_amount / exchange_rate as topup_reward_amount_usd
    ,topup_amount
    ,topup_amount / exchange_rate as topup_amount_usd
    ,topup_order_ids
    ,ads_placements
    ,spending_amount
    ,spending_amount / exchange_rate as spending_amount_usd
    ,target_spending_tiers 
    ,seller_program_status_id 
    ,seller_program_status
    --  new fileds for program in (5,6,7)
    ,cashback_onboarding_info
    ,cashback_multi_info
    ,fixed_multi_info
    ,incentive_ads_placement
    ,trigger_campaign_id
    ,trigger_time
    ,baseline_amount
    ,spending_period
    ,last_spending_timestamp
    ,spending_start_time
    ,spending_end_time
    ,credit_effective_type
    ,credit_amount_cap
    ,credit_amount_cap / exchange_rate as credit_amount_cap_usd
    ,uncapped_credit_amount
    ,uncapped_credit_amount / exchange_rate as uncapped_credit_amount_usd  
    ,last_topup_timestamp
    ,ads_creation_try 
    ,ads_creation_time 
    ,unread_ads
    ,topup_orders 
    ,credit_inject_time  
    ,program_extinfo
    ,owner_operator_type  
    ,is_auto_claim
    ,incentive_id
    ,popup_score 
    ,ads_credit_package_info   
    ,package_id
    ,shop_total_stock
    ,shop_used_stock 
    ,original_price
    ,discount_price
    ,discount_percentage
    ,expiry_type
    ,expiry_days
    ,expiry_time
    ,is_deactivated
    ,is_oos         
    ,cashback_compound_info
    ,fixed_compound_info    
    ,auto_topup_info
    ,is_atu_on_before  
    ,target_topup_tiers   
    ,first_tier_completion_timestamp  
    ,credit_consumption_type
    ,null as program_type_name
    ,null as granted_credit_order_ids
    ,a.grass_region
    ,a.grass_date                                                                                                                                  
from old_flow_data a
left join (
    SELECT
        grass_region
        ,exchange_rate
    FROM mp_order.dim_exchange_rate__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${BIZ_YESTERDAY}')
)b
on a.grass_region = b.grass_region 

union all 
-- new dataflow

select 
    shop_id
    ,null as segment_id
    ,program_id
    ,program_name
    ,program_status
    ,program_type
    ,program_start_timestamp
    ,program_start_datetime
    ,program_end_timestamp
    ,program_end_datetime
    ,null as display_timestamp
    ,null as display_datetime
    ,null as learn_more_link
    ,null as credit_expiry_duration
    ,null as credit_claim_period
    ,null as sign_up_timestamp
    ,null as sign_up_datetime
    ,null as deadline_timestamp
    ,null as deadline_datetime
    ,null as priority_score
    ,null as is_dismissed
    ,completion_timestamp
    ,from_unixtime(completion_timestamp, 'yyyy-MM-dd HH:mm:ss') as completion_datetime
    ,granted_credit_amount
    ,granted_credit_amount / exchange_rate as granted_credit_amount_usd
    ,null as granted_credit_order_id
    ,null as topup_target_amount
    ,null as topup_target_amount_usd 
    ,null as topup_reward_amount
    ,null as topup_reward_amount_usd
    ,topup_amount
    ,topup_amount / exchange_rate as topup_amount_usd
    ,topup_order_ids
    ,null as ads_placements
    ,null as spending_amount
    ,null as spending_amount_usd
    ,null as target_spending_tiers 
    ,null as seller_program_status_id 
    ,null as seller_program_status
    ,null as cashback_onboarding_info
    ,null as cashback_multi_info
    ,null as fixed_multi_info
    ,null as incentive_ads_placement
    ,null as trigger_campaign_id
    ,null as trigger_time
    ,null as baseline_amount
    ,null as spending_period
    ,null as last_spending_timestamp
    ,null as spending_start_time
    ,null as spending_end_time
    ,null as credit_effective_type
    ,null as credit_amount_cap
    ,null as credit_amount_cap_usd
    ,null as uncapped_credit_amount
    ,null as uncapped_credit_amount_usd  
    ,null as last_topup_timestamp
    ,null as ads_creation_try 
    ,null as ads_creation_time 
    ,null as unread_ads
    ,null as topup_orders 
    ,null as credit_inject_time  
    ,program_extinfo
    ,null as owner_operator_type  
    ,null as is_auto_claim
    ,incentive_id
    ,null as popup_score 
    ,null as ads_credit_package_info   
    ,null as package_id
    ,null as shop_total_stock
    ,null as shop_used_stock 
    ,null as original_price
    ,null as discount_price
    ,null as discount_percentage
    ,null as expiry_type
    ,null as expiry_days
    ,null as expiry_time
    ,null as is_deactivated
    ,null as is_oos         
    ,null as cashback_compound_info
    ,null as fixed_compound_info    
    ,null as auto_topup_info
    ,null as is_atu_on_before  
    ,cast(target_topup_tiers as string) as target_topup_tiers  
    ,first_tier_completion_timestamp  
    ,null as credit_consumption_type
    ,program_type_name
    ,granted_credit_order_ids
    ,c.grass_region
    ,c.grass_date  
from  new_flow_data c 
left join (
    SELECT
        grass_region
        ,exchange_rate
    FROM mp_order.dim_exchange_rate__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${BIZ_YESTERDAY}')
)d
on c.grass_region = d.grass_region 
;

alter table dwd_advertiser_program_incentive_credit_df__${region}_s0_live add if not exists partition (grass_date = '${BIZ_YESTERDAY}');