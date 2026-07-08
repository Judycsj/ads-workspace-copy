-- task_code: data_paidadsmart.studio_10431760  asset_id: 10431760
insert overwrite table dwd_trace_bidding_hyperx_hi__reg_s0_live partition (grass_region, grass_date, h, biz_type)
select
    project_name
    ,strategy_name
    ,version
    ,emission_timestamp
    ,event_timestamp
    ,event_type
    ,map_from_entries(group_key_map) as group_key_map
    ,map_from_entries(reward_output) as reward_output
    ,map_from_entries(initial_agent_params) as initial_agent_params
    ,map_from_entries(updated_agent_params) as updated_agent_params
    ,map_from_entries(output_param) as output_param
    ,map_from_entries(flag_params) as flag_params
    ,extra_json
    ,null as target_roi
    ,null as pid_coef
    ,null as mpc_e_gmv_24h
    ,null as mpc_e_cost_24h
    ,null as mpc_e_gmv_daily
    ,null as mpc_e_cost_daily
    ,null as mpc_e_cost_ratio
    ,null as p_gmv_daily
    ,null as p_cost_daily
    ,null as coef_array
    ,null as daily_metrics_imp
    ,null as daily_metrics_click
    ,null as daily_metrics_order
    ,null as daily_metrics_gmv
    ,null as daily_metrics_cost
    ,null as daily_metrics_advv
    ,null as rt_remain_budget
    ,null as daily_budget
    ,null as account_balance
    ,null as imp_count
    ,null as debug_info_json
    ,null as campaign_id
    ,null as budget_tag
    ,grass_region
    ,grass_date
    ,h
    ,'livestream' as biz_type
from mp_paidads.ods_log_live_ads_bidding_hyperx_hi__reg_s0_live
where
    grass_region in (${grass_region})
    and grass_date = '${BIZ_DT}'
    and h = '${BIZ_HOUR}'
union all 
select
    project_name
    ,strategy_name
    ,version
    ,emission_timestamp
    ,event_timestamp
    ,event_type
    ,map_from_entries(group_key_map) as group_key_map
    ,map_from_entries(reward_output) as reward_output
    ,map_from_entries(initial_agent_params) as initial_agent_params
    ,map_from_entries(updated_agent_params) as updated_agent_params
    ,map_from_entries(output_param) as output_param
    ,map_from_entries(flag_params) as flag_params
    ,extra_json
    ,null as target_roi
    ,null as pid_coef
    ,null as mpc_e_gmv_24h
    ,null as mpc_e_cost_24h
    ,null as mpc_e_gmv_daily
    ,null as mpc_e_cost_daily
    ,null as mpc_e_cost_ratio
    ,null as p_gmv_daily
    ,null as p_cost_daily
    ,null as coef_array
    ,null as daily_metrics_imp
    ,null as daily_metrics_click
    ,null as daily_metrics_order
    ,null as daily_metrics_gmv
    ,null as daily_metrics_cost
    ,null as daily_metrics_advv
    ,null as rt_remain_budget
    ,null as daily_budget
    ,null as account_balance
    ,null as imp_count
    ,null as debug_info_json
    ,null as campaign_id
    ,null as budget_tag
    ,grass_region
    ,grass_date
    ,h
    ,'shop' as biz_type
from mp_paidads.ods_log_shop_ads_bidding_hyperx_hi__reg_s0_live
where
    grass_region in (${grass_region})
    and grass_date = '${BIZ_DT}'
    and h = '${BIZ_HOUR}'
union all
select
    project_name
    ,strategy_name
    ,version
    ,emission_timestamp
    ,event_timestamp
    ,event_type
    ,map_from_entries(group_key_map) as group_key_map
    ,map_from_entries(reward_output) as reward_output
    ,map_from_entries(initial_agent_params) as initial_agent_params
    ,map_from_entries(updated_agent_params) as updated_agent_params
    ,map_from_entries(output_param) as output_param
    ,map_from_entries(flag_params) as flag_params
    ,extra_json
    ,null as target_roi
    ,null as pid_coef
    ,null as mpc_e_gmv_24h
    ,null as mpc_e_cost_24h
    ,null as mpc_e_gmv_daily
    ,null as mpc_e_cost_daily
    ,null as mpc_e_cost_ratio
    ,null as p_gmv_daily
    ,null as p_cost_daily
    ,null as coef_array
    ,null as daily_metrics_imp
    ,null as daily_metrics_click
    ,null as daily_metrics_order
    ,null as daily_metrics_gmv
    ,null as daily_metrics_cost
    ,null as daily_metrics_advv
    ,null as rt_remain_budget
    ,null as daily_budget
    ,null as account_balance
    ,null as imp_count
    ,null as debug_info_json
    ,null as campaign_id
    ,null as budget_tag
    ,grass_region
    ,grass_date
    ,h
    ,'video' as biz_type
from mp_paidads.ods_log_video_ads_bidding_hyperx_hi__reg_s0_live
where
    grass_region in (${grass_region})
    and grass_date = '${BIZ_DT}'
    and h = '${BIZ_HOUR}'
union all
select
    project_name
    ,strategy_name
    ,version
    ,emission_timestamp
    ,event_timestamp
    ,event_type
    ,map_from_entries(group_key_map) as group_key_map
    ,map_from_entries(reward_output) as reward_output
    ,map_from_entries(initial_agent_params) as initial_agent_params
    ,map_from_entries(updated_agent_params) as updated_agent_params
    ,map_from_entries(output_param) as output_param
    ,map_from_entries(flag_params) as flag_params
    ,extra_json
    ,null as target_roi
    ,null as pid_coef
    ,null as mpc_e_gmv_24h
    ,null as mpc_e_cost_24h
    ,null as mpc_e_gmv_daily
    ,null as mpc_e_cost_daily
    ,null as mpc_e_cost_ratio
    ,null as p_gmv_daily
    ,null as p_cost_daily
    ,null as coef_array
    ,null as daily_metrics_imp
    ,null as daily_metrics_click
    ,null as daily_metrics_order
    ,null as daily_metrics_gmv
    ,null as daily_metrics_cost
    ,null as daily_metrics_advv
    ,null as rt_remain_budget
    ,null as daily_budget
    ,null as account_balance
    ,null as imp_count
    ,null as debug_info_json
    ,null as campaign_id
    ,null as budget_tag
    ,grass_region
    ,grass_date
    ,h
    ,'brand' as biz_type
from mp_paidads.ods_log_brand_ads_bidding_hyperx_hi__reg_s0_live
where
    grass_region in (${grass_region})
    and grass_date = '${BIZ_DT}'
    and h = '${BIZ_HOUR}'
union all 
select 
    project_name
    ,strategy_name
    ,version
    ,emission_timestamp
    ,event_timestamp
    ,event_type
    ,map_from_entries(group_key_map) as group_key_map
    ,map_from_entries(reward_output) as reward_output
    ,map_from_entries(initial_agent_params) as initial_agent_params
    ,map_from_entries(updated_agent_params) as updated_agent_params
    ,map_from_entries(output_param) as output_param
    ,map_from_entries(flag_params) as flag_params
    ,extra_json
    ,target_roi
    ,pid_coef
    ,mpc_e_gmv_24h
    ,mpc_e_cost_24h
    ,mpc_e_gmv_daily
    ,mpc_e_cost_daily
    ,mpc_e_cost_ratio
    ,p_gmv_daily
    ,p_cost_daily
    ,coef_array
    ,daily_metrics_imp
    ,daily_metrics_click
    ,daily_metrics_order
    ,daily_metrics_gmv
    ,daily_metrics_cost
    ,daily_metrics_advv
    ,rt_remain_budget
    ,daily_budget
    ,account_balance
    ,imp_count
    ,debug_info_json
    ,campaign_id
    ,budget_tag
    ,grass_region
    ,grass_date
    ,h
    ,'product' as biz_type
from mp_paidads.ods_log_hyperx_exp_hi_temp_s0_live
where
    grass_region in (${grass_region})
    and grass_date = '${BIZ_DT}'
    and h = '${BIZ_HOUR}'
;