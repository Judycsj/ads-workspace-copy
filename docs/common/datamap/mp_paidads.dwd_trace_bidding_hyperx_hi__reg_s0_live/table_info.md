<!-- ads-workspace-gdoc-sync: gdoc_id=18CqLWmyjVxn7RsSjHWQmZk2PbVn1D4OgMFAZXuKgSkQ gdoc_url=https://docs.google.com/document/d/18CqLWmyjVxn7RsSjHWQmZk2PbVn1D4OgMFAZXuKgSkQ/edit -->

# mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live

## Description

- **Desc:** HyperX bidding agent trace log at hourly granularity. Consolidates bidding trace data from multiple ad business types (product, shop, livestream, video, brand) into a unified DWD layer, recording agent parameters, MPC predictions, reward outputs, and real-time campaign performance snapshots from the UltraV bidding system.
- **Granularity:** hourly x agent_call x region (each row = one agent emission per ads_id/campaign_id/strategy per hour)
- **Use Case:** UltraV posterior data quality monitoring, MPC pCoC calibration analysis, time-series model prediction pipeline (ts_model_pred), ROI2 performance predictor, budget pacing & reallocation monitoring, traffic boost budget usage analysis, voucher budget alert
- **Update Frequency:** Hourly

## Key Metrics

- MPC predictions: mpc_e_gmv_24h, mpc_e_cost_24h, mpc_e_gmv_daily, mpc_e_cost_daily, mpc_e_cost_ratio
- Cumulative performance: daily_metrics_imp, daily_metrics_click, daily_metrics_order, daily_metrics_gmv, daily_metrics_cost, daily_metrics_advv
- Budget: rt_remain_budget, daily_budget, account_balance
- Bidding coefficients: pid_coef, target_roi, coef_array
- Agent call count: imp_count

## Key Dimensions

- Partition: grass_region, grass_date, h, biz_type
- Extracted from group_key_map: ads_id, campaign_id, placement, pricing_type, plan_bucket_id
- Agent: project_name, strategy_name, version
- Derived: extra_json (JSON trace with nested MPC/calibration/budget fields)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_region (string), grass_date (date), h (tinyint), biz_type (string) |
| HDFS Path | ${HIVE_PATH}/dwd_trace_bidding_hyperx_hi__reg_s0_live |
| Retention | - |
| Column Count | 37 columns + 4 partition columns |
| Region Coverage | ID, TH, PH, VN, BR, MY, TW, SG |
| DQC Status | - |
| Table Size | - |

## Business Properties

*Not retrieved from DataMap. Run `--source from-di` to populate.*

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 211 files (89 workflows, 122 manual/scheduled/playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
