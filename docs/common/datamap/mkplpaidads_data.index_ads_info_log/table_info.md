<!-- ads-workspace-gdoc-sync: gdoc_id=19k0XZqsP5M3EiOYbZCxO37eya5B7Ew01AaameyN5Pb4 gdoc_url=https://docs.google.com/document/d/19k0XZqsP5M3EiOYbZCxO37eya5B7Ew01AaameyN5Pb4/edit -->

# mkplpaidads_data.index_ads_info_log

## Description

- **Desc:** Hourly-updated Hudi MERGE_ON_READ table storing the latest ads index snapshot per ads_id x country. This is the primary entity table for all marketplace ad types (Search, Discovery, Brand, Shopee Video, Live), containing ad attributes, bidding strategies, item/shop/campaign metadata, traffic control information, and voucher configurations in nested struct columns.
- **Granularity:** hourly x ads_id x country (Hudi record key: `id` = ads_id combined key)
- **Use Case:**
  - Traffic Boost candidate pool generation and budget allocation (MCKP solver)
  - Ads index status diagnosis (traffic control anomaly, campaign/ads/shop/item status)
  - ROI2/ROI3 bidding strategy and daily performance reports
  - Boost Service campaign scope and guardrail monitoring
  - Voucher strategy analysis and threshold pricing
  - Recall/LLM offline pipeline (hourly ads info update)
  - Live Ads performance and max view analysis
  - Brand/Search ads keyword and template extraction
- **Update Frequency:** Hourly (upstream indexer service writes via Hudi upsert)

## Key Metrics

*This is an entity/info table, not a metrics table. Metrics come from related performance tables.*

## Key Dimensions

- **Partition:** `dt` (date string), `h` (hour int), `country` (region code)
- **Entity:** `ads_id`, `campaign_id`, `item_id`, `shop_id`, `ads_account_id`
- **Type:** `placement` (40=Search, 100=Discovery, etc.), `advertisement.pricing_type`, `advertisement.plan_bucket_list`
- **Status:** `advertisement.ad_tag` (bitmask flags), `visible_start_ts`, `traffic_control`
- **Strategy:** `bid_strategy.target_roi`, `bid_strategy.bid_type`, `advertisement.cold_start_flag`

https://confluence.shopee.io/display/SPAD/AdsInfo+Fields

## Technical Properties

| Property | Value |
|---|---|
| **Table Update Frequency** | Hourly |
| **DQC Status** | WARNING |
| **Table Size** | 1.70 TB |
| **LakeHouse Type** | Hudi |
| **Table Type** | EXTERNAL_TABLE |
| **HDFS Path** | hdfs://R2/projects/mkplpaidads_data/hive/mkplpaidads_data/index_ads_info_log |
| **Retention** | Permanent |
| **Visibility** | Open |
| **Create Info** | mkplpaidads_data / Jul 02, 2025 10:45 AM |
| **Last Edited Info** | rui.chengcr@shopee.com / Jul 04, 2025 03:07 PM |

## Business Properties

| Property | Value |
|---|---|
| **Business PIC** | - |
| **Technical PIC** | rui.chengcr@shopee.com |
| **Team** | mkplpaidads |
| **Project** | Data Platform(mkplpaidads_data) |
| **Business Domain** | Marketplace - Paid Ads |
| **Data Mart** | Paidads DA |
| **Data Topic** | - |
| **DW Layer** | ADS |
| **Market Region** | REG |
| **Last 7 Days Query Count** | 6,561 |
| **Sensitivity Level** | - |

## Popularity

- **Studio Tasks References:** 336+ files (W: 0, R: 336+) -- heavily read across all ad types
- **L7D Query Count:** 6,561
- **Completeness:** 40.00
- **Popularity:** 100.00

*Note: No studio task writes to this table. It is produced by an upstream indexer service (Hudi upsert).*
