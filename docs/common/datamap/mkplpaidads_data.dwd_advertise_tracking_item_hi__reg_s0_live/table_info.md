<!-- ads-workspace-gdoc-sync: gdoc_id=1yjssr10AF0k_30Fv76RjIvv0-Duh6uyAGVO2aPsxn9E gdoc_url=https://docs.google.com/document/d/1yjssr10AF0k_30Fv76RjIvv0-Duh6uyAGVO2aPsxn9E/edit -->

# mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live

## Description

- **Desc:** Ads tracking item-level detail table. Explodes `items` array from `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` into per-item rows, enriching each row with deduction info, pricing type, entrance/placement mappings, voucher info, and bidding trace data. Core fact table for all ads tracking analysis.
- **Granularity:** hourly x user x item x ads_request_id x ads_id x region
- **Use Case:** Request-level performance aggregation (dwd_ads_request_performance), AB test recall monitoring, bidding model training data, tracking report (impression/click by entrance/placement), shop-level OCPM aggregation for diagnosis, ROI tracking with bidding metrics, voucher analysis
- **Update Frequency:** Hourly

## Key Metrics

- 行为计数: impression (operation=1), click (operation=2), view (operation=3), add_to_cart (operation=4), place_order (operation=5)
- 去重计数: dedup_impression (operation=1 AND duplicate_label IS NULL), dedup_click (operation=2 AND duplicate_label IS NULL)
- 出价/扣费: internal.deduction_info.bidprice, internal.deduction_info.deduction_price, bid_deduction_price
- 预估值 (from item_json_data): pCTR, pCR, broad_pcr, rank_score, pgmv
- 价格/ROI: item_price (divided by 100000), target_cir, voucher_deduction_price

## Key Dimensions

- 分区键: grass_date (date), grass_region (varchar(10)), h (int), bz_type (varchar(20), Search/Discovery)
- 广告实体: ads_id, campaign_id, item_id, shop_id, user_id
- 流量入口: ads_entrance (string), ads_placement (bigint), sub_entrance (bigint), tracking_placement
- 行为类型: operation (bigint), operation_desc (string), pricing_type (string)
- 搜索上下文: query.keyword, ads_keyword, match_type, page_type, page_section, scenario
- AB 实验: ab_sign, fe_ab_sign, algo_json_data
- 请求链路: ads_request_id, raw_request_id, organic_request_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (MapredParquetInputFormat / MapredParquetOutputFormat) |
| Partition Columns | grass_region (varchar(10)), grass_date (date), h (int), bz_type (varchar(20)) |
| HDFS Path | hdfs://R2/projects/mkplpaidads_data/hive/mkplpaidads_data/dwd_advertise_tracking_item_hi |
| Retention | 999999 |
| Column Count | 72 (56 data + 4 partition + 12 extended via INSERT) |
| Region Coverage | SEA 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) + MX, CO, CL (US workflow) |
| Table Type | EXTERNAL_TABLE |
| DQC Status | SUCCESS |
| Table Size | 2.05 PB |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | ella.yuan@shopee.com |
| Technical PIC | renjie.xia@shopee.com, zhangyawei@shopee.com |
| Team | mkplpaidads |
| Project | Data Platform(mkplpaidads_data) |
| Business Domain | Marketplace - Paid Ads |
| Data Mart | Paidads DA |
| DW Layer | DWD |
| Market Region | REG |

## Popularity

- Studio Tasks References: 2024 files (read) + 6 files (write)
- L7D Query Count: 9,860
- Completeness: 76.79
- Popularity: 100.00
