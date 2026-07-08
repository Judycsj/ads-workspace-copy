<!-- ads-workspace-gdoc-sync: gdoc_id=1HLM2deRPRTdSIXeaofOkKuNu-jvU6jWCqGdq5l3GM18 gdoc_url=https://docs.google.com/document/d/1HLM2deRPRTdSIXeaofOkKuNu-jvU6jWCqGdq5l3GM18/edit -->

# mp_order.dws_buyer_seller_gmv_td__reg_s0_live

## Description

- **Desc:** Buyer-seller order history to-date summary table, owned by mp_order team. Records cumulative (to-date) order relationships between buyers and shops, used as a lookup to determine whether a user has ordered from a specific shop (order history). A key building block in Target Audience (TA) workflows to exclude existing buyers and derive potential new buyers.
- **Granularity:** daily x buyer_id x shop_id x region
- **Use Case:** Target Audience order history (exclude users who have ordered from a shop to derive potential new buyers), Target Audience tag bitmap generation (filter out existing buyers per shop), User-shop order relationship lookup
- **Update Frequency:** Daily

## Key Metrics

- placed_order_cnt_td: Cumulative placed order count for this buyer-shop pair (to-date), primary filter (> 0) to identify order history

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: buyer_id (aliased as user_id), shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | mp_order (external) |
| Business Domain | Order / GMV |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 64 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
