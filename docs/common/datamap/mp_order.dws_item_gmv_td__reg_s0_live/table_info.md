<!-- ads-workspace-gdoc-sync: gdoc_id=1GK-gXqJ0cXd_JAF-VV9FSvLir7EtksZ_Os9Ht-o2cpg gdoc_url=https://docs.google.com/document/d/1GK-gXqJ0cXd_JAF-VV9FSvLir7EtksZ_Os9Ht-o2cpg/edit -->

# mp_order.dws_item_gmv_td__reg_s0_live

## Description

- **Desc:** Item-level cumulative (to-date) GMV summary table, owned by the Order team (mp_order). Contains cumulative placed order counts and GMV (USD) at item-shop granularity, aggregated from item creation to current date. Sister table of `dws_item_gmv_1d` (daily) and `dws_item_gmv_nd` (N-day rolling). Serves as the canonical source for seller/platform-level cumulative performance metrics in Ads Seller Metrics pipelines.
- **Granularity:** daily snapshot x item_id x shop_id x region (cumulative metrics)
- **Use Case:** Seller all-metrics daily/weekly/monthly reporting (platform GMV TD, platform order count TD), Seller per-day average order/GMV analysis (ado_calc / adgmv_calc), Seller cumulative performance ranking and trend analysis
- **Update Frequency:** Daily

## Key Metrics

- GMV: gmv_usd_td (cumulative GMV in USD)
- Order: placed_order_cnt_td (cumulative placed order count), placed_order_fraction_td (cumulative order fraction, used for attribution/proration)
- Shops: shop_id (seller identifier)

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

- Studio Tasks References: 46 files (5 workflows, 2 manual tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
