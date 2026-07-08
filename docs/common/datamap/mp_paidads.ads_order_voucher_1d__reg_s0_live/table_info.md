<!-- ads-workspace-gdoc-sync: gdoc_id=1HF-DVzHzurbwxTiks-PxWYSnLCViyPVF9qpBRL1VV0U gdoc_url=https://docs.google.com/document/d/1HF-DVzHzurbwxTiks-PxWYSnLCViyPVF9qpBRL1VV0U/edit -->

# mp_paidads.ads_order_voucher_1d__reg_s0_live

## Description

- **Desc:** Daily order-level voucher redemption table for ads-related orders. Links order items with voucher information (seller/platform/FSV/ads voucher), matches voucher click context from dwd_advertise_performance_di via user+shop+voucher_id within 48h attribution window, and enriches with cofund ratio and package info from dim_advertise. Granularity is order_id x item_id per day per region.
- **Granularity:** daily x order_id x item_id x tz_type x region
- **Use Case:** ROI3 voucher cost monitoring (budget use ratio alerts), AB test metrics with voucher cost breakdown (roi3_exp_v1/v2/v4), cofund performance dashboard (voucher + platform co-funding analysis by strategy/model experiment buckets), uplift user portrait feature generation (daily voucher redemption behavior aggregation), PGMV 99.5 percentile exclusion performance analysis
- **Update Frequency:** Daily

## Key Metrics

- Voucher Cost: ads_voucher_amt_usd, ads_voucher_amt_local, seller_voucher_amt_usd, platform_voucher_amt_usd, fsv_voucher_amt_usd, gross_ads_voucher_amt_usd
- Platform Cost: ads_voucher_amt_usd * voucher_cofund_ratio (platform finance cost), ads_voucher_amt_usd * platform_spend_ratio_by_req (platform algo cost)
- Order Value: platform_order_gmv_amt_usd, platform_order_gmv_amt_local, seller_gmv_amt_usd, item_price_usd
- Rebate Breakdown: net_sv_rebate_by_seller_amt_usd, net_sv_rebate_by_external_amt_usd, net_pv_rebate_by_seller_amt_usd, net_pv_rebate_by_external_amt_usd

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Order: order_id, shop_id, item_id, user_id
- Voucher Identity: seller_voucher_id, ads_voucher_id, fsv_voucher_id, platform_voucher_id
- Ads Context (from matched click): match_voucher_click_ads_id, match_voucher_click_pricing_type, match_voucher_click_placement, match_voucher_click_entrance, match_voucher_click_ab_sign
- Experiment: ab_sign, plan_bucket_list (from order-attributed perf_di record)
- Package: non_ads_type, package_request_id, package_co_fund_ratio

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | ${HIVE_PATH}/ads_order_voucher_1d |
| Retention | - |
| Column Count | 49 (base DDL 31 + extended columns in newer versions) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (SEA 8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 177 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
