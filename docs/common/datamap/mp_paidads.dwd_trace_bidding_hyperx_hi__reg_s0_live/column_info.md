<!-- ads-workspace-gdoc-sync: gdoc_id=1T6l5DVhUwWC2mSwcw5F7cXqGQwdpIvZYSpRxt2Toupo gdoc_url=https://docs.google.com/document/d/1T6l5DVhUwWC2mSwcw5F7cXqGQwdpIvZYSpRxt2Toupo/edit -->

# Columns: mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

No SUM(DISTINCT) patterns detected in codebase references. This table stores individual trace log records rather than pre-aggregated metrics.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| biz_type | 'product' | Product Ads (from ods_log_hyperx_exp_hi_temp_s0_live, has full MPC fields) |
| biz_type | 'shop' | Shop Ads (from ods_log_shop_ads_bidding_hyperx_hi, base fields only) |
| biz_type | 'livestream' | Livestream Ads (from ods_log_live_ads_bidding_hyperx_hi, base fields only) |
| biz_type | 'video' | Video Ads (from ods_log_video_ads_bidding_hyperx_hi, base fields only) |
| biz_type | 'brand' | Brand Ads (from ods_log_brand_ads_bidding_hyperx_hi, base fields only) |
| project_name | 'ultrav_core' | Main UltraV bidding project (majority of queries) |
| project_name | 'ultrav_core_timewindow' | UltraV time-window based bidding (ts_model_pred, budget pacing) |

### 常见 WHERE 值 (Common Filter Values)

- `project_name`: 'ultrav_core' (posterior monitor, pcoc, roi2, voucher budget), 'ultrav_core_timewindow' (ts_model_pred, budget reallocation)
- `strategy_name` (common patterns):
  - `'posterior_data_monitor'` (data quality monitoring)
  - `'ads_info_snapshot%'` (LIKE, pcoc snapshot)
  - `'planid_target2%'` / `'planid_simple2%'` (LIKE, time-window prediction)
  - `'roi2_perf_predictor'` (ROI2 performance prediction)
  - `'cofund_budget_control'` (voucher budget monitoring)
  - `'%subsidy_traffic_budget%'` (LIKE, traffic boost)
- `version`: 'v0' (posterior monitor), 'v3' (cofund budget)
- `grass_region`: Standard 8 regions ('ID','TH','PH','VN','BR','MY','TW','SG')
- `group_key_map` key access patterns:
  - `group_key_map['ads_id']`, `group_key_map['campaign_id']`
  - `group_key_map['placement']`, `group_key_map['pricing_type']`
  - `group_key_map['plan_bucket_id']` (traffic boost: = 12)

### extra_json 常用 JSON Path (Common JSON Paths)

Downstream consumers heavily parse `extra_json` via `get_json_object` / `json_extract_scalar`:

**UltraV posterior monitor** (strategy = 'posterior_data_monitor'):
- `$.CampaignMetrics.CostUA1d`, `$.CampaignMetrics.BroadGmvUA1d`, `$.CampaignMetrics.BroadPayGmv1d`
- `$.CampaignMetrics.Advv1d`, `$.CampaignMetrics.Order1d`, `$.CampaignMetrics.Click1d`, `$.CampaignMetrics.Impression1d`
- `$.CampaignMetrics.CostReal1d`, `$.CampaignMetrics.FeedBackPgmv1d`

**Time-window prediction** (strategy LIKE 'planid_%'):
- `$.post_processor.final_prediction_v2.effective_online.gmv.raw.slots`
- `$.post_processor.final_prediction_v2.effective_online.cost.raw.slots`
- `$.post_processor.final_prediction_v2.effective_online.gmv.after_p2p.slots`
- `$.post_processor.final_prediction_v2.effective_online.cost.after_p2r.slots`
- `$.post_processor.final_prediction_v2.effective_online.gmv.final.slots`
- `$.mpc_model.model_choose`, `$.mpc_model.model_trace.p2r_cost_cali`, `$.mpc_model.model_trace.p2r_gmv_cali`
- `$.main_data.ads_cost_today`, `$.main_data.ads_pgmv_today`, `$.main_data.ads_broad_gmv_today`

**pCoC snapshot** (strategy LIKE 'ads_info_snapshot%'):
- `$.cdf`, `$.imp_today`, `$.cost_usd_today`, `$.gmv_usd_today`
- `$.mpc_e_cost_local_today`, `$.mpc_e_gmv_local_today` (and _calied_ variants)
- `$.mpc_e_cost_real_pcoc_today`, `$.mpc_e_gmv_real_pcoc_today`
- `$.budget_tag`, `$.budget_hit_minute`, `$.daily_budget_usd`
- `$.cold_start_flag`, `$.empty_flag`, `$.npb_flag`

**Voucher budget** (strategy = 'cofund_budget_control'):
- `$.TraceArray[0]` -> `$.TotalBudgetUsd`

**Traffic boost** (strategy LIKE '%subsidy_traffic_budget%'):
- `$.boost_budget_info.daily_boost_budget_map.{biz_tag}`, `$.boost_budget_info.boost_cost_map.{biz_tag}`
- `$.boost_budget_info.traffic_budget`, `$.traffic_pid_coef`, `$.traffic_theoretical_max_coef`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| project_name | string | project_name | - | - |
| strategy_name | string | strategy_name | - | - |
| version | string | version | - | - |
| emission_timestamp | bigint | emission_timestamp | - | - |
| event_timestamp | bigint | event_timestamp | - | - |
| event_type | string | event_type | - | - |
| group_key_map | map\<string,string\> | Key-value pairs: ads_id, campaign_id, placement, pricing_type, plan_bucket_id, etc. | - | - |
| reward_output | map\<string,string\> | reward_output | - | - |
| initial_agent_params | map\<string,string\> | initial_agent_params | - | - |
| updated_agent_params | map\<string,string\> | updated_agent_params (contains p2p prediction JSON arrays) | - | - |
| output_param | map\<string,string\> | output_param (contains update_time for voucher budget) | - | - |
| flag_params | map\<string,string\> | flag_params | - | - |
| extra_json | string | JSON trace with nested MPC/calibration/budget/performance fields | - | - |
| target_roi | double | target roi, current target_roi (product ads only) | - | - |
| pid_coef | double | The current final bid coefficient (product ads only) | - | - |
| mpc_e_gmv_24h | bigint | MPC estimated GMV in 24 hours (product ads only) | - | - |
| mpc_e_cost_24h | bigint | MPC estimated cost in 24 hours (product ads only) | - | - |
| mpc_e_gmv_daily | bigint | MPC estimated daily GMV (product ads only) | - | - |
| mpc_e_cost_daily | bigint | MPC estimated daily cost (product ads only) | - | - |
| mpc_e_cost_ratio | double | MPC estimated daily cost ratio (product ads only) | - | - |
| p_gmv_daily | double | Cumulative pGMV up to current moment (product ads only) | - | - |
| p_cost_daily | double | Cumulative pCost up to current moment (product ads only) | - | - |
| coef_array | array\<double\> | Current median bid coefficients: underbid_coef, entrance_coef (product ads only) | - | - |
| daily_metrics_imp | bigint | Current actual cumulative impressions (product ads only) | - | - |
| daily_metrics_click | bigint | Current actual cumulative clicks (product ads only) | - | - |
| daily_metrics_order | bigint | Current actual cumulative orders (product ads only) | - | - |
| daily_metrics_gmv | bigint | Current actual cumulative GMV (product ads only) | - | - |
| daily_metrics_cost | bigint | Current actual cumulative cost (product ads only) | - | - |
| daily_metrics_advv | double | Current actual cumulative ADVV (product ads only) | - | - |
| rt_remain_budget | bigint | Remaining budget as of current moment (product ads only) | - | - |
| daily_budget | bigint | Planned budget for the day (product ads only) | - | - |
| account_balance | bigint | Total account balance as of current moment (product ads only) | - | - |
| imp_count | bigint | Agent online call count within time slice (product ads only) | - | - |
| debug_info_json | string | debug_info_json (product ads only) | - | - |
| campaign_id | bigint | campaign_id (product ads only; for other biz_types use group_key_map['campaign_id']) | - | - |
| budget_tag | string | Budget size classification (product ads only) | - | - |
| grass_region | string | [PARTITION] Region code | - | - |
| grass_date | date | [PARTITION] Partition date | - | - |
| h | tinyint | [PARTITION] Hour (0-23) | - | - |
| biz_type | string | [PARTITION] Business type: product, shop, livestream, video, brand | - | - |
