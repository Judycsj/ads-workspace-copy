<!-- ads-workspace-gdoc-sync: gdoc_id=1hnka2NPc1o5xPjgAFjgNyvo6IiSI0ksuQHRQ8nuXaq8 gdoc_url=https://docs.google.com/document/d/1hnka2NPc1o5xPjgAFjgNyvo6IiSI0ksuQHRQ8nuXaq8/edit -->

# mp_paidads.ads_advertise_mkt_1d__reg_s0_live

## Description

- **Desc:** Daily aggregated ADS-level table containing all advertisement information: ads status, campaign details, pricing type, item info, performance metrics (imp/click/order/gmv/expenditure), active status, cold start status, seller/advertiser tier, revenue breakdown (gross/net/free), and SIP flags. Primary Key: ads_id + placement + entrance + new_boost.
- **Granularity:** daily x ads_id x placement x entrance x new_boost x tz_type x region
- **Use Case:** OKR Take Rate daily tracker, SKU/seller adoption rate, ads supply metrics, algo model feature extraction (bidding/incentive/item selection), ads cold start analysis, advertiser strategy, revenue breakdown by seller type (1P/SIP), entry point performance analysis
- **Update Frequency:** Daily

## Key Metrics

- Revenue: ads_expenditure_amt_usd, ads_expenditure_amt_local, net_ads_revenue_usd_1d, free_ads_revenue_amt_usd_1d, gross_ads_revenue_usd_1d
- Performance: impression_cnt, click_cnt, order_cnt, ads_gmv_usd, ads_gmv_local, ads_items_sold_cnt
- Broad Attribution: broad_order_cnt, broad_order_gmv_amt_usd, broad_order_gmv_amt_local, broad_order_item_cnt
- Paid Order: paid_order_cnt, paid_broad_order_cnt, paid_broad_order_gmv_usd
- Engagement: add_to_cart_cnt, broad_add_to_cart_cnt, checkout_cnt, view_cnt, product_click_cnt
- Video: video_view, video_play_complete, video_play_3s_cnt, video_play_5s_cnt, view_duration
- Derived: broad_roi, avg_ads_ranks, deduplicated_click_cnt

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Ads Identity: ads_id, placement, entrance, new_boost
- Business: entry_point, traffic_type, pricing_type, main_product_type, sub_product_type, product_type
- Entity: shop_id, item_id, campaign_id, seller_id
- Status: is_ads_active, has_performance, ads_status, campaign_status
- Seller: seller_type, seller_type_1p, is_cb_seller, is_cb_sip_affiliated, is_local_sip_affiliated, seller_tier, advertiser_tier
- Category: level1/2/3_global_be_category, level4_global_be_category, shop_level1_global_be_category

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/ads_advertise_mkt_1d |
| Retention | Permanent |
| Column Count | 167 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (SEA 8 regions) + MX, CO, CL (LATAM via US cluster) |
| DQC Status | SUCCESS |
| Table Size | 85.14 TB |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | renjie.xia@shopee.com |
| Team | mkplpaidads |
| Business Domain | Marketplace - Paid Ads |
| DW Layer | ADS |

## Popularity

- Studio Tasks References: 1430 files (16 write, 1414 read)
- L7D Query Count: 17,992
- Completeness: 78.27
- Popularity: 100.00
