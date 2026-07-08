<!-- ads-workspace-gdoc-sync: gdoc_id=1izbckw9QwLJy155Zsw8sB9f7AZmF___WDEQiezkWkQI gdoc_url=https://docs.google.com/document/d/1izbckw9QwLJy155Zsw8sB9f7AZmF___WDEQiezkWkQI/edit -->

# traffic.dwd_view_di__reg_live

## Description

- **Desc:** App-side user view event detail table (traffic domain DWD layer). Records page view events from Shopee App, capturing user browsing behavior with page type and domain context. Used by the ads team for audience building (potential buyer) and advertiser activity classification.
- **Granularity:** daily x user x item x shop x page_type x region
- **Use Case:** L2 category potential buyer audience generation (PPV = product page view count), advertiser tier tag classification (app activity tracking via "my_ads_homepage" views)
- **Update Frequency:** Daily

## Key Metrics

- 行为计数: view count (`count(*)` grouped by user/shop_cat/item_cat), time-windowed view activity (30d / 30-60d / 60-365d buckets)

## Key Dimensions

- 分区: grass_date (date), grass_region (string), tz_type (string)
- 实体: user_id, shop_id, item_id
- 页面上下文: page_type, domain_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SEA 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) + MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

> 未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |
| Market Region | REG |

## Popularity

- Studio Tasks References: 33 files (29 read in workflows, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
