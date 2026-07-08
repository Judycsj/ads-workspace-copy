<!-- ads-workspace-gdoc-sync: gdoc_id=1JRX69GHhyagWK83soPVeYWegSMcVUH_onxGobSQvaZc gdoc_url=https://docs.google.com/document/d/1JRX69GHhyagWK83soPVeYWegSMcVUH_onxGobSQvaZc/edit -->

# mkplpaidads_search_ads.mkpl_paidads_item_prediction

## Description

- **Desc:** Product Ads item potential prediction table. Contains GBDT model predictions for each item (shop_id, item_id) per day per region: classification probability of getting orders (pred_cls), expected order count in next 7 days (order_expected), and a normalized potential score (potential_score = 1 - exp(-order_expected/3.0)). Used for item reserve strategy (NPB, cold start, empty order expansion) to select high-potential items for boosted advertising.
- **Granularity:** daily x grass_region x (shop_id, item_id) — one row per item per day per region
- **Use Case:**
  - Product Ads reserve strategy (NPB / cold start item selection by percentile bucket)
  - Precision-recall evaluation of item potential model against actual order data
  - Soft label generation for ads strategy (new_potential)
  - Dashboard queries: prediction distribution monitoring by region
  - Item redis tagging pipeline (dump predicted items to redis for online serving)
- **Update Frequency:** Daily (Spark dynamic partition overwrite, trains and writes one day ahead)

## Key Metrics

- 单一预测值: potential_score (normalized expected orders, range [0, 1)), order_expected (raw expected 7-day orders), pred_cls (classification probability)

## Key Dimensions

- 分区: dt, grass_region
- 业务主键: shop_id, item_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (SNAPPY compression) |
| Partition Columns | dt (DATE), grass_region (STRING) |
| HDFS Path | - |
| Retention | - |
| Column Count | 5 (3 data + 2 partition) |
| Region Coverage | 8 standard regions (ID, TH, MY, VN, SG, PH, TW, BR) |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | chuncheng.yang@shopee.com (DDL creator) |
| Team | Ads Algo |
| Business Domain | Product Ads / Search Ads |
| DW Layer | Application (model prediction output) |

## Popularity

- Studio Tasks References: 72 files (32 workflows + 37 manual_tasks + 3 other)
- L7D Query Count: -
- Completeness: -
- Popularity: -
