<!-- ads-workspace-gdoc-sync: gdoc_id=1fw40FPPtOYOo8jmEm6fGGuftkNBFK-VPZt1mN8SazxA gdoc_url=https://docs.google.com/document/d/1fw40FPPtOYOo8jmEm6fGGuftkNBFK-VPZt1mN8SazxA/edit -->

# mp_paidads.dws_streamer_livestream_org_performance_1d__reg_s0_live

## Description

- **Desc:** Streamer-level organic (non-ad) live streaming performance metrics aggregated daily. Covers viewer traffic, watch time, orders, GMV, impressions, and clicks broken down by total, recommendation traffic, and ads-recommendation traffic channels. Acts as the DWS aggregation layer sourcing from `dws_ls_session_livestream_org_performance_1d` with DAU metrics enriched from live streaming event detail tables.
- **Granularity:** daily x streamer x tz_type x grass_region
- **Use Case:**
  - Compute 7-day organic GMV for advertiser live streaming metrics aggregation
  - Calculate streamer organic performance scores (view, order, GMV by channel) for advertiser targeting ROI models
  - Build streamer GMV percentile tiers for advertiser segmentation
  - Feed organic performance into 7-day retention/advertiser lifecycle analysis
  - Support live ads ROI update workflow (post-7-day organic GMV backfill)
- **Update Frequency:** Daily

## Key Metrics

- **Traffic/Organic Performance**:
  - view_total_cnt, view_rcmd_cnt, view_rcmd_ads_cnt (View counts by traffic source)
  - time_total_cnt, time_rcmd_cnt, time_rcmd_ads_cnt (Watch duration by traffic source)
  - dau, rcmd_dau, rcmd_ads_dau (Daily active users by traffic source) -- Non-additive, use MAX
  - org_imp_cnt, org_rcmd_imp_cnt, org_rcmd_ads_imp_cnt (Organic impressions by traffic source)
  - org_click_cnt, org_rcmd_click_cnt, org_rcmd_ads_click_cnt (Organic clicks by traffic source)
- **Transaction/GMV**:
  - order_total_cnt, order_rcmd_cnt, order_rcmd_ads_cnt (Order counts by traffic source)
  - gmv_total_usd, gmv_rcmd_usd, gmv_rcmd_ads_usd (GMV in USD by traffic source)
  - gmv_total_local (GMV in local currency)

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 业务: streamer_id, streamer_type, shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | ${HIVE_PATH}/dws_streamer_livestream_org_performance_1d |
| Retention | - |
| Column Count | 28 (25 data + 3 partition) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 30 files (7 write, 23 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
