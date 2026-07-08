<!-- ads-workspace-gdoc-sync: gdoc_id=1LrIaPXq4Hdfyfnuz9zXZgQezuQOoaxZpwNgbOcyxe5g gdoc_url=https://docs.google.com/document/d/1LrIaPXq4Hdfyfnuz9zXZgQezuQOoaxZpwNgbOcyxe5g/edit -->

# mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live

## Description

- **Desc:** Campaign-level valid budget table. Calculates the effective daily budget for each campaign considering account balance, campaign budget settings, and strategy-based quota allocation (e.g., Live Ads quota_split). Used as the core budget reference across ads data pipelines.
- **Granularity:** daily x campaign_id x shop_id x pricing_type x region
- **Use Case:** Bidding model training features, budget utilization monitoring, deduction loss analysis, Live Ads hit-budget detection, budget supply reporting, seller center ads diagnosis, shop-level feature engineering (traffic boost)
- **Update Frequency:** Daily

## Key Metrics

- Budget: campaign_valid_budget_usd, account_valid_budget_usd, budget_usd, campaign_total_budget_usd, campaign_strategy_valid_budget_usd
- Expenditure: ads_expenditure_usd, account_expenditure_usd
- Account: account_balance_usd, account_balance_last1d_usd, topup_amt_usd, expired_amt_usd

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: campaign_id, shop_id, pricing_type, campaign_status, main_product_type, product_type, sub_product_type
- Seller: seller_tier, advertiser_tier, is_auto_topup_enabled, is_cb_seller

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/ads_campaign_valid_budget_1d |
| Retention | 1100 |
| Column Count | 31 (28 data + 3 partition) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX (US view: BR + MX) |
| DQC Status | - |
| Table Size | 502.90 GB |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | ella.yuan@shopee.com |
| Technical PIC | xiaochen.yang@shopee.com |
| Team | mkplpaidads |
| Project | data_paidadsmart(data_paidadsmart) |
| Business Domain | Marketplace - Paid Ads |
| Data Mart | Paid Ads Mart |
| DW Layer | ADS |
| Market Region | REG |

## Popularity

- Studio Tasks References: 1283 files
- L7D Query Count: 6,540
- Completeness: 58.71
- Popularity: 100.00
