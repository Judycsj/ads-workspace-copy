<!-- ads-workspace-gdoc-sync: gdoc_id=1NVSubqEtlNIxlQS1dU1gaGI5iDQPuzlJRkOk7MN-n6U gdoc_url=https://docs.google.com/document/d/1NVSubqEtlNIxlQS1dU1gaGI5iDQPuzlJRkOk7MN-n6U/edit -->

# mp_order.dws_item_gmv_1d__reg_s0_live

## Description

- **Desc:** Item-level daily GMV summary table owned by the Order team (mp_order). Contains daily placed order counts, GMV (local & USD), and buyer counts at item-shop granularity. Serves as the canonical source for platform-side item performance metrics used across Ads DW pipelines.
- **Granularity:** daily x item_id x shop_id x region
- **Use Case:** ROI2 item key metrics (platform GMV window), Ads diagnosis (platform order/CR), Discovery Ads target CIR (item order count), Seller metrics (platform GMV per shop, key seller percentile), Shop GMV Max budget recommendation, Item competitiveness scoring, Advertiser trade order GMV N-day aggregation
- **Update Frequency:** Daily

## Key Metrics

- GMV: gmv_usd_1d, gmv_1d (local currency)
- Order: placed_order_cnt_1d, paid_order_cnt_1d
- Buyer: placed_buyer_cnt_1d
- Item: placed_item_cnt_1d, item_amount_1d

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: shop_id, item_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CL, CO |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | mp_order (Order Team) |
| Business Domain | Order / GMV |
| DW Layer | DWS (Summary) |

## Popularity

- Studio Tasks References: 286 files (26 unique workflows, 33 manual tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
