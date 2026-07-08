<!-- ads-workspace-gdoc-sync: gdoc_id=1shXs6RQTk9_gqadg5yk9vBGOf_W0MiQR5pdiqvVlDeA gdoc_url=https://docs.google.com/document/d/1shXs6RQTk9_gqadg5yk9vBGOf_W0MiQR5pdiqvVlDeA/edit -->

# mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live

## Description

- **Desc:** Raw hourly Live Ads report log from ads reporting service. Captures impression, click, order, GMV, view, checkout, and cost events for livestream ads (CPM placements: 33, 3327, 3328, 3337, 3338, 3339, 3342, 3348). Stored at hourly granularity per region as the ODS layer for Live Ads performance data.
- **Granularity:** hourly x grass_region x h x ads_id
- **Use Case:**
  1. Building `dwd_advertise_performance_di` -- hourly livestream report data unioned with search/shop ads report for full performance aggregation
  2. Live Ads PCR/PCOC model training -- joining with ranking trace for online-conversion-rate calibration
  3. Live Ads deduction/delivery monitoring -- analyzing deduction vs impression rates, budget check failures
  4. Live Ads hourly performance reporting -- per-region hourly aggregation of views, orders, revenue
  5. Live Ads case diagnosis -- troubleshooting specific ads_id/request_id with full event-level detail
- **Update Frequency:** Hourly (each partition represents one hour of data for one region)

## Key Metrics

- **Impression & Delivery:** impression, deduct_impression, non_fraud_impression, raw_impression, cpm, cost_by_cpm
- **Click & Engagement:** click, raw_click, non_fraud_click, product_click, shop_item_click, broad_shop_item_click
- **Order & Conversion:** order, daily_order, broad_order, paid_order, confirmed_order, checkout, daily_order
- **GMV & Revenue:** order_gmv, daily_gmv, broad_gmv, order_amount, daily_order_amount
- **Cost & Expense:** cost, raw_expense, expense_free_credit_with_expiry, expense_free_credit_without_expiry, expense_paid_credit_with_expiry, expense_paid_credit_without_expiry
- **Engagement:** view, view_duration, add_to_cart, add_to_cart_without_click, broad_add_to_cart, pageview
- **Model Scores:** pcr, pctr, rank_bid, pvr_boost, match_boost, rank_score, lite_pctr, lite_pcr, target_cir

## Key Dimensions

- **Partition:** grass_region, grass_date, h (hour)
- **Entity:** ads_id, campaign_id, shop_id, account_id, item_id, user_id, ls_session_id, streamer_id
- **Ad Type:** entry_point, entrance, placement, pricing_type, bid_type, sub_entrance, slot_id, location
- **Tracking:** request_id, order_id, model_id, creative_id, raw_request_id, signature
- **Region/Platform:** country, platform, app_ver, location, click_area

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (ParquetHiveSerDe) |
| Partition Columns | grass_region (string), grass_date (date), h (int) |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hdfs/prod/logs/ods_log_ads_report_livestream_hi |
| Retention | - |
| Column Count | 100 |
| Region Coverage | ID, TH, VN, SG, TW, MY, PH, BR, MX, CO, CL (11 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 35 files (4 write, 31 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
