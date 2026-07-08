<!-- ads-workspace-gdoc-sync: gdoc_id=1lewFaYgbJL_kuQh2rdE79lHA8UlH-Pe9jfnmDEM39bE gdoc_url=https://docs.google.com/document/d/1lewFaYgbJL_kuQh2rdE79lHA8UlH-Pe9jfnmDEM39bE/edit -->

# mp_paidads.ods_log_livestream_ads_tracking__reg_s0_live

## Description

- **Desc:** ODS-layer raw livestream ads tracking log table, recording all client-side livestream ad tracking events (impression, view, order, etc.) with deeply nested struct/array fields including items, shops, banners, and livestreams. Data is ingested from the ads tracking SDK with Parquet schema merge enabled. This is the primary source-of-truth for livestream ad intermediate value extraction (pCTR, pCVR, AOV, price_coef, deduction_price, etc.).
- **Granularity:** hourly x region (one row per tracking event per user per timestamp, with multiple livestream entries per row via array)
- **Use Case:** Extract intermediate values (pCTR, pCVR, target_cir, ecpm, aov, price_coef, deduction_price) for livestream ads bidding models (ROI2/MAX_GMV2/MAX_VIEW); TMS data quality comparison (old tracking vs UBT/UBTA); livestream ads dashboard ETL; ad hoc livestream case analysis and debugging; livestream tracking scoring/ranking analysis
- **Update Frequency:** Hourly (partition per hour per region)

## Key Metrics

This is a raw event log table - no pre-aggregated metrics. Key fields extracted from `livestreams[].json_data` by downstream:
- Bidding signals: `pctr` (predicted CTR), `pcr` (predicted CVR), `pctr` (predicted conversion rate), `ecpm`, `target_cir`, `aov` (predicted AOV in micros)
- Pricing: `price_coef` (bidding price coefficient), `deduction_price` (final deduction price)
- Placement: `placement`, `pricing_type`, `request_id`, `price_coef`
- Streamer: `user_id` (streamer), `shop_id`, `streamer_type`

## Key Dimensions

- Partition: `grass_date`, `grass_region`, `h` (hour)
- Event: `operation` (1=Impression/DeductImpr)
- Entrance: `entrance` (27=LIVE STREAM DISCOVERY, 28=LIVE STREAM FOR YOU, 37=LS HOME CAROUSEL, 38=LS PDP, 39=LS AUTO LANDING, 42=LS VIDEO FEED, 48=LS GAME)
- Livestream: `livestreams[].ads_id`, `livestreams[].ls_session_id`, `livestreams[].user_id` (streamer_id), `livestreams[].shop_id`
- Platform: `platform` (2=ios_app, 4=android_app)
- Content: `livestreams[].content_mix_frame_tab_name` (0=UNKNOWN, 1=LiveTab, 2=ForYouTab, 3=VideoTab, 4=DiscoverTab)
- Livestream type: `livestreams[].if_mini_ls` (boolean, mini livestream indicator)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (spark.sql.parquet.mergeSchema = true) |
| Partition Columns | `grass_region` (string), `grass_date` (date), `h` (int) |
| HDFS Path | `hdfs://R2/projects/data_paidadsmart/hdfs/prod/logs/ods_log_livestream_ads_tracking__reg_s0_live` |
| Retention | - |
| Column Count | 25 top-level columns (with deeply nested struct/array sub-fields, especially `items`, `shops`, `livestreams`) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN (7 regions; also region-split tables exist: id/sg/th/vn/my/ph/tw_s0_live) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 69 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
