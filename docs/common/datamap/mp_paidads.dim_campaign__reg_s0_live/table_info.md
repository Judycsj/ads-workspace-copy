<!-- ads-workspace-gdoc-sync: gdoc_id=1RcI-o-AyUTP-pTDGyAoLyml5qHC06_bXXcXBpTlcZ_s gdoc_url=https://docs.google.com/document/d/1RcI-o-AyUTP-pTDGyAoLyml5qHC06_bXXcXBpTlcZ_s/edit -->

# mp_paidads.dim_campaign__reg_s0_live

## Description

- **Desc:** Campaign dimension table. Stores campaign-level attributes and configurations parsed from the raw campaign_tab ODS table. Covers budget, status, ROI targets, auto-budget settings, CPS/NPA/rapid boost flags, and creation metadata for all Ads campaign types.
- **Granularity:** daily x campaign_id x grass_region x tz_type
- **Use Case:** Campaign budget lookup for diagnosis/bidding workflows, Target ROI (roi_two) tracking for Target 2.0 / Simple ROI campaigns, Campaign attribute enrichment in seller-center diagnosis, Rebate/whitelist eligibility check via campaign_tag, Campaign naming for omni diagnosis reports
- **Update Frequency:** Daily

## Key Metrics

- Budget: daily_quota_local, daily_quota_usd, total_quota_local, total_quota_usd
- ROI: roi_two (Target ROAS), roi_two_display_target_value
- Estimates: simple_roi_two_estimate (est_roi_lower_bound, est_roi_upper_bound, est_order_lower_bound, est_order_upper_bound)
- Product GMS: product_gms_estimate (has_est, roi_lower_bound, roi_upper_bound, bid_roi)

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Campaign: campaign_id, shop_id, user_id
- Status: campaign_status, campaign_status_text
- Type: campaign_type, creation_entry_point, creation_platform
- Feature flags: is_cps, is_npa, npa_current_phase, is_rapid_boost_on, is_auto_ads_solution_on, gmv_type, campaign_tag

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (inferred from workflow) |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | ~40+ (including struct fields) |
| Region Coverage | ID, VN, TH, SG, PH, MY, TW, MX, BR, AR (+ US variants) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 238 files (read), 17 files (write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
