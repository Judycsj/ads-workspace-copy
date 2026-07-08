<!-- ads-workspace-gdoc-sync: gdoc_id=1yM7oTgQRelrnxNf1ri7e0EceJvY7piG4EpxbcSVB4c8 gdoc_url=https://docs.google.com/document/d/1yM7oTgQRelrnxNf1ri7e0EceJvY7piG4EpxbcSVB4c8/edit -->

# traffic_omni_oa.dwd_scenario_event_log_hi__reg

## Description

- **Desc:** Omni scenario event log table, recording user traffic events (impressions, clicks, etc.) across platform entry points. Contains detailed event-level data with page type, scenario, feature, and user context fields. Used as the primary source for entry-point-level impression/click attribution and traffic type classification.
- **Granularity:** Event-level (hourly partition, one row per user operation event)
- **Use Case:**
  - Entry point impression counting for Take Rate (ads_advertise_take_rate_v2_1d) -- maps to entry_point via CASE-WHEN on page_type/module/feature_group/feature_detail
  - Organic vs Ads traffic metrics at entry point and item level (dws_organic_metrics_1d) -- uses common_feature and entry_point dual mappings
  - NG report vs TMS exposure diff analysis (ads_report_ng_tms_diff_1d) -- compares report-based vs scenario-event-based impression/click metrics
  - Entry point definition and coverage checks (manual tasks)
- **Update Frequency:** Hourly

## Key Metrics

This is a source/event table -- it does not contain pre-aggregated metrics. Downstream usage derives:
- Impression counts: COUNT(1) WHERE operation='impression'
- Click counts: COUNT(1) WHERE operation='click'
- Ads impression/click split: filtered by `common_property.is_ads = 1` or `is_ads = true`

## Key Dimensions

- **Partition columns**: grass_date, grass_hour, grass_region, tz_type
- **Entry point classification**: page_type, page_section, target_type, module, feature_detail, feature_group, feature, object, search_property.scenario
- **Ads identification**: common_property.is_ads / is_ads
- **User context**: user_id, shop_id, item_id, platform, rn_version, app_version
- **Event context**: operation

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | reg (standard 8: ID, MY, PH, SG, TH, TW, VN, BR) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 37 files (0 write, 37 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
