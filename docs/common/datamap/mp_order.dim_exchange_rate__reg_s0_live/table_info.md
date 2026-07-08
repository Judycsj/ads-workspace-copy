<!-- ads-workspace-gdoc-sync: gdoc_id=1SqwuCd0hQ17bYxnwi_tWAtaNsITdmYkSZYjh65fl90I gdoc_url=https://docs.google.com/document/d/1SqwuCd0hQ17bYxnwi_tWAtaNsITdmYkSZYjh65fl90I/edit -->

# mp_order.dim_exchange_rate__reg_s0_live

## Description

- **Desc:** Dimension table providing daily exchange rates from local currency to USD for each region. Owned by the mp_order team, widely used across Paid Ads workflows for currency conversion (local currency to/from USD).
- **Granularity:** daily x region
- **Use Case:** Currency conversion in ads revenue/cost reporting, bidding price conversion (local to USD), ROI calculation across regions, budget allocation solver, CPM forecast local currency conversion, ads diagnosis key metrics daily pipeline
- **Update Frequency:** Daily

## Key Metrics

- exchange_rate: Local currency to USD exchange rate (the core and only metric column)

## Key Dimensions

- Partition: grass_date, grass_region
- Business: currency

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Hive (VIRTUAL_VIEW) |
| Partition Columns | grass_date, grass_region (inferred from usage) |
| HDFS Path | - (virtual view) |
| Retention | Permanent |
| Column Count | ~4 (grass_region, currency, exchange_rate, grass_date) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
| DQC Status | SUCCESS |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | gardahadi@shopee.com |
| Technical PIC | linsheng.xia@shopee.com, kevin.liu@shopee.com, xuhui.zengxh@shopee.com |
| Team | regdedw1 |
| Project | data_ordermart |
| Business Domain | Marketplace - Core |
| DW Layer | DIM |
| Market Region | NO_REGION |
| L7D Query Count | 139,611 |

## Popularity

- Studio Tasks References: 3348 files (1703 workflows, 189 scheduled_tasks, 1456 manual_tasks)
- L7D Query Count: 139,611
- Completeness: 91.00
- Popularity: 100.00
