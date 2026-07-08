<!-- ads-workspace-gdoc-sync: gdoc_id=1aNUumZd_p_9ZNzfSyPfQmsJ26chrqD6dzxnI9HzdsgY gdoc_url=https://docs.google.com/document/d/1aNUumZd_p_9ZNzfSyPfQmsJ26chrqD6dzxnI9HzdsgY/edit -->

# mp_order.dws_seller_gmv_td__reg_s0_live

## Description

- **Desc:** Seller-level GMV to-date (MTD/cumulative) summary table, owned by mp_order team. Provides shop-level GMV accumulation used downstream for seller tier classification, seller status determination (new/churn/existing/reactivated), and effective shop filtering in Ads data warehouse.
- **Granularity:** daily x shop_id x region
- **Use Case:** Seller tier classification (large/medium/small/micro based on GMV thresholds), Seller status lifecycle tracking (new/existing/churn/reactivated via MoM GMV comparison), Effective shop filtering (shops with gmv_td > 0), dim_shop_info daily/monthly production, ads_advertise_mkt_1d production
- **Update Frequency:** Daily

## Key Metrics

- gmv_usd_td: Cumulative GMV in USD (month-to-date), primary metric for seller tier classification
- gmv_td: Cumulative GMV in local currency (month-to-date), used for effective shop filtering

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: shop_id

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

- Studio Tasks References: 172 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
