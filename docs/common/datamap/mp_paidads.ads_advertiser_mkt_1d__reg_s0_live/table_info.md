<!-- ads-workspace-gdoc-sync: gdoc_id=18TwnMGGY23Lxkdm1HRYNsIUCRlAw8ZrRYu8phsZrFIE gdoc_url=https://docs.google.com/document/d/18TwnMGGY23Lxkdm1HRYNsIUCRlAw8ZrRYu8phsZrFIE/edit -->

# mp_paidads.ads_advertiser_mkt_1d__reg_s0_live

## Description

- **Desc:** Advertiser-level daily aggregation table. Consolidates an advertiser's account status, top-up history, ads performance (impression/click/order/GMV/expenditure), account balance, credit expiry, and shop category into a single wide table keyed by shop_id. Produced by joining 10+ upstream DWS/DIM tables per region per day.
- **Granularity:** daily x shop_id x tz_type x grass_region
- **Use Case:** Advertiser health monitoring, seller tier segmentation by platform GMV, incentive strategy eligibility (e.g. CB seller spend 7d > 0, hit balance detection), traffic boost feature engineering (shop-level 90-day rolling features), ads ROI analysis by seller size, active advertiser counting, LTV prediction vs actual monitoring, shop ad budget suggestion (SOD balance computation), category-level ROI benchmarking
- **Update Frequency:** Daily

## Key Metrics

- 支出类: ads_expenditure_amt_usd_{1,7,30,60,90}d, ads_expenditure_amt_local_{1,7,30,60,90}d
- 支出拆分: paid_expenditure_{wo,w}_expiry_amt_usd_1d, free_expenditure_{wo,w}_expiry_amt_usd_1d
- 效果类: ads_impression_{1,7,30,60,90}d, ads_click_cnt_{1,7,30,60,90}d, ads_order_cnt_{1,7,30,60,90}d
- GMV: ads_gmv_amt_usd_{1,7,30,60,90}d, ads_broad_gmv_usd_{1,7,30,60,90}d, ads_broad_order_{1,7,30,60,90}d
- 平台指标: platform_gmv_usd_{1,7,30,60,90}d, platform_order_cnt_{1,7,30,60,90}d
- 充值: total_topup_amt_usd_{1,7,30,60}d (manual/auto/normal/seller_mission/srm/neg 拆分)
- 余额: total_eod_balance_usd_td, free/paid_credit_{wo,w}_expiry_eod_balance_amt_usd_td
- 品类支出: l1cat_ads_expenditure_amt_usd_1d, l2cat_ads_expenditure_amt_usd_1d
- 结账: checkout_cnt

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 标识: shop_id, user_id
- 账户状态: status, account_status, has_active_ads, has_ads_performance, is_active_ads_seller
- 卖家属性: is_cb_seller, is_managed_seller, is_official_shop, is_preferred_shop, is_self_mcn
- 自动化: is_auto_topup_enabled, is_campaign_auto_bid_enabled
- 品类: shop_level1_global_be_category, shop_level2_global_be_category
- 余额阈值: is_reach_low_threshold

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (run from-di to fill) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/ads_advertiser_mkt_1d |
| Retention | Permanent |
| Column Count | ~275 (incl. partition columns) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (+ MX, CL, CO via US cluster) |
| DQC Status | SUCCESS |
| Table Size | 6.98 TB |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | renjie.xia@shopee.com |
| Team | mkplpaidads |
| Business Domain | Marketplace - Paid Ads |
| DW Layer | ADS |

## Popularity

- Studio Tasks References: 510 files (235 workflows, 5 scheduled, 263 manual, 17 playground)
- L7D Query Count: 4,129
- Completeness: 78.44
- Popularity: 100.00
