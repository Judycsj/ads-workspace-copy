<!-- ads-workspace-gdoc-sync: gdoc_id=1eTX_8MfTmdYWItLERETE2UVLwRYuozwnSs4lwByGRno gdoc_url=https://docs.google.com/document/d/1eTX_8MfTmdYWItLERETE2UVLwRYuozwnSs4lwByGRno/edit -->

# mp_paidads.dwd_advertise_performance_di__reg_s0_live

## Description

- **Desc:** DWD-layer daily advertisement performance fact table. Each row is an individual ad event (click, impression deduction, order attribution, CPM deduction). Combines CPC/CPS report events, livestream report events, and CPM/CPC/CPS translog deduction records with USD conversion and dimension enrichment.
- **Granularity:** Event-level (per ads_id x item_id x user_id x request_id x deduct_unique_id x placement x grass_date x grass_region). NOT pre-aggregated -- one row per raw event.
- **Use Case:** Ad revenue reporting, ROI/ROAS analysis, bidding model calibration (PCOC), AB test experiment analysis, voucher strategy metrics, budget allocation, advertiser value (ADVV) calculation, ads funnel diagnostics.
- **Update Frequency:** Daily (per-region partitioned writes, each region runs independently).

## Key Metrics

- Revenue/Spend: `expenditure_amt_usd`, `expenditure_amt_local`
- GMV (Direct): `ads_order_gmv_usd`, `ads_order_gmv_local`
- GMV (Broad): `broad_gmv_amt_usd`, `broad_gmv_amt_local`
- Impressions: `impression_cnt`, `deduct_impression`, `raw_impression`, `non_fraud_impression`
- Clicks: `click_cnt`, `click_before_deduction_cnt`, `raw_click_cnt`, `deduplicated_click`, `non_fraud_click`
- Orders (Direct): `order_cnt`, `checkout_cnt`, `ads_item_sold_cnt`
- Orders (Broad): `broad_order_cnt`, `broad_item_cnt`
- Orders (Paid): `paid_order_cnt`, `paid_order_gmv_local`, `paid_order_gmv_usd`
- Voucher: `voucher_deduction_price`, `deduction_price`, `bid_voucher_id`, `ads_voucher_auto_claimed`
- Bidding: `target_cir`, `origin_bid_price`, `raw_expense`, `boost_deduction_price`
- Video: `video_view`, `video_play_complete`, `video_play_3s_cnt`, `video_play_5s_cnt`, `view_duration`

## Key Dimensions

- Partition: `grass_date`, `grass_region`, `tz_type` (always 'local')
- Ad entity: `ads_id`, `campaign_id`, `shop_id`, `account_id`, `item_id`
- User: `user_id`
- Placement: `placement`, `entrance`, `sub_entrance`, `page_type`, `page_section`
- Pricing: `pricing_type`
- Attribution: `order_id`, `request_id`, `deduct_unique_id`
- Targeting: `ta_group_id`, `ta_matched_tag_ids`, `ta_premium_rate`
- Experiment: `ab_sign`, `plan_bucket_list`, `traffic_bucket_list`
- Creative: `creative_id`, `creative_algo`, `video_id`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | `tz_type`, `grass_region`, `grass_date` |
| HDFS Path | `hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/dwd_advertise_performance_di` |
| Retention | 730 days |
| Column Count | ~180+ (DDL has 183 columns including partitions) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, AR, CL, CO |
| DQC Status | SUCCESS |
| Table Size | 1.76 PB |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | ella.yuan@shopee.com |
| Technical PIC | renjie.xia@shopee.com, zhangyawei@shopee.com |
| Team | mkplpaidads |
| Project | data_paidadsmart |
| Business Domain | Marketplace - Paid Ads |
| Data Mart | Paid Ads Mart |
| Data Topic | Traffic |
| DW Layer | DWD |
| Market Region | REG |
| Sensitivity Level | BUSINESS S2 |

## Popularity

- Studio Tasks References: 7846 files (read), 46 files (write)
- L7D Query Count: 23,835
- Completeness: 71.72
- Popularity: 100.00
