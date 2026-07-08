<!-- ads-workspace-gdoc-sync: gdoc_id=1takvMPFdhrOuaK2gEA6vbBWN63LY1-UB4KVcHFD8xts gdoc_url=https://docs.google.com/document/d/1takvMPFdhrOuaK2gEA6vbBWN63LY1-UB4KVcHFD8xts/edit -->

# mp_paidads.dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live

## Description

- **Desc:** Ads and organic performance metrics aggregated at the common_feature (recommendation scenario) level. The table JOINs ads-side performance data (`dwd_advertise_performance_di`) with omni-channel (full traffic attribution) data from multiple `traffic_omni_oa` tables, attribution-weights orders/GMV, and appends content live streaming metrics. Each row represents a unique combination of (user, common_feature, app_version, item, location, shop) for a given day and region.
- **Granularity:** Daily x grass_region x tz_type x common_feature x user_id x item_id x location x shop_id x app_version
- **Use Case:**
  1. Omni-channel GMV analysis by shop/item/common_feature (shop-level, platform-level, feature-level comparisons)
  2. AB experiment evaluation with uplift models (user/item-level omni labels as experiment targets)
  3. Ads diagnosis: omni core key metrics merge for daily monitoring dashboards
  4. Data quality validation: comparing omni attribution vs ads-side report/raw data
  5. Voucher coverage and bidding strategy AB experiments
- **Update Frequency:** Daily (scheduled workflow in `data_paidadsmart/workflows/`)

## Key Metrics

- **收入类 (Revenue):** ads_revenue, ads_revenue_usd, ads_revenue_roi2, ads_revenue_usd_roi2, ads_commision_fee, ads_commision_fee_usd
- **GMV 类 (GMV):** ads_direct_gmv, ads_broad_gmv, ads_gmv_usd, ads_broad_gmv_usd, ads_gmv_200_cap_usd, ads_gmv_500_cap_usd, ads_broad_gmv_200_cap_usd, ads_broad_gmv_500_cap_usd
- **效果类 (Performance):** ads_impr_cnt, ads_click_cnt, ads_direct_order_cnt, ads_broad_order_cnt, ads_direct_item_sold_cnt, ads_broad_item_sold_cnt, ads_atc_cnt, ads_deduction_click_cnt, ads_deduction_impression_cnt
- **直播类 (Live Streaming):** ads_live_view_cnt, ads_live_view_duration, ads_live_item_click_cnt
- **Omni 流量类 (Traffic):** omni_entry_impr_cnt/ads/organic, omni_entry_click_cnt/ads/organic, omni_item_impr_cnt/ads/organic, omni_item_click_cnt/ads/organic
- **Omni 转化类 (Conversion):** omni_ppv_cnt/ads/organic, omni_atc_cnt/ads/organic, omni_stay_time/ads/organic
- **Omni 订单/GMV 类 (Order/GMV):** omni_order_cnt/ads/organic, omni_gmv/ads/organic, omni_gmv_usd/ads/organic, omni_commission_fee/ads/organic, omni_commission_fee_usd/ads/organic, omni_item_sold_cnt/ads/organic
- **直播 Omni 类 (Content Live):** content_live_ads_view_cnt/duration/item_click_cnt, content_live_ads_direct/broad_order_cnt/item_sold_cnt/gmv/gmv_usd
- **标记类 (Flags):** if_ads_item, if_roi1_item, if_roi2_item, if_new_product_boost, if_simple2_item

## Key Dimensions

- **分区 (Partitions):** grass_date, grass_region, tz_type
- **核心维度 (Core Dimensions):** common_feature (推荐场景), user_id, item_id, shop_id
- **辅助维度 (Auxiliary):** location, app_version

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (Hive External Table) |
| Input/Output Format | MapredParquetInputFormat / MapredParquetOutputFormat |
| SerDe | org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/dws_advertise_user_exp_common_feature_performance_1d |
| Retention | 180 days |
| Column Count | 95 non-partition + 3 partition = 98 total |
| Region Coverage | 12 regions: ID, MY, PH, SG, TH, TW, VN, MX, CO, CL, BR, BR_US |
| DQC Status | SUCCESS |
| Table Size | 85.22 TB |
| Create Info | data_paidadsmart / Feb 23, 2024 10:57 AM |
| Last Edited Info | zhangyawei@shopee.com / Dec 20, 2024 11:13 AM |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | ella.yuan@shopee.com |
| Technical PIC | renjie.xia@shopee.com zhangyawei@shopee.com |
| Team | mkplpaidads |
| Project | data_paidadsmart(data_paidadsmart) |
| Business Domain | Marketplace - Paid Ads |
| Data Mart | Paid Ads Mart |
| Data Topic | Traffic |
| DW Layer | DWS |
| Market Region | REG |
| Sensitivity Level | BUSINESS S2 |

## Popularity

- Studio Tasks References: 95 files (12 write, 83 read)
- L7D Query Count: 570
- Completeness: 78.87
- Popularity: 100.00
