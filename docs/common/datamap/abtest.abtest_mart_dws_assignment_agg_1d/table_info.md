<!-- ads-workspace-gdoc-sync: gdoc_id=10O-SImO3Zt3OhOio88eyKwWc7bxwnVwlhkOWyFVO5ig gdoc_url=https://docs.google.com/document/d/10O-SImO3Zt3OhOio88eyKwWc7bxwnVwlhkOWyFVO5ig/edit -->

# abtest.abtest_mart_dws_assignment_agg_1d

## Description

- **Desc:** AB test user-group assignment daily aggregate table. Stores the mapping between user_id and experiment group_id for users exposed to AB tests on the platform. This is an externally maintained table produced by the AB test platform, not by the ads codebase.
- **Granularity:** daily x region x user_id x group_id
- **Use Case:**
  - Shop Ads experiment evaluation (performance metrics by experiment group)
  - Search Ads AB test metric computation
  - Live streaming ads experiment analysis and score extraction
  - Experiment outage/outlier labeling and checks
  - AB test platform GMV estimation and adjustment
- **Update Frequency:** Daily

## Key Metrics

This is a mapping/dimension table and does not contain metrics. Metrics are derived by joining with performance tables:
- Ads metrics (via `mp_paidads.dwd_advertise_performance_di__reg_s0_live`): ads_impr, ads_click, ads_order, ads_gmv, ads_revenue
- Platform metrics (via `traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live`): order_cnt, gmv_usd_1d
- Omni metrics: omni_entry_impr, omni_entry_click, omni_item_impr, omni_item_click, omni_gmv, omni_commission

## Key Dimensions

- Partition: grass_region, local_date
- AB test: user_id, group_id, scene_id, layer_id, experiment_id
- Traffic: traffic_split_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_region, local_date |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (standard 8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

Run `--source from-di` to populate Business Properties from DataMap.

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 580 files (0 write, 580 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
