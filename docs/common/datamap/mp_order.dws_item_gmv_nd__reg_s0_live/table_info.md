<!-- ads-workspace-gdoc-sync: gdoc_id=1FvhENjxNngXrS_d6phuzpqcQs3M_eYee_sUCRHm8TdI gdoc_url=https://docs.google.com/document/d/1FvhENjxNngXrS_d6phuzpqcQs3M_eYee_sUCRHm8TdI/edit -->

# mp_order.dws_item_gmv_nd__reg_s0_live

## Description

- **Desc:** Item-level daily GMV summary table with N-day rolling metrics, owned by the Order team (mp_order). Contains daily placed order counts and GMV (USD) at item level, plus pre-computed 30-day rolling order count. Serves as the canonical source for active item identification, item-level GMV, and supply-side adoption rate metrics in Ads pipelines.
- **Granularity:** daily x item_id x region
- **Use Case:** Active item identification (placed_order_cnt_30d > 0), Item-level GMV for ROI and boost coefficient calculation, Supply-side monitoring (active items/shops count), Advertiser growth analytics (churn/reactive analysis, NPA pass rate), Seller incentive strategy (winner seller/item selection by 30d order count)
- **Update Frequency:** Daily

## Key Metrics

- GMV: gmv_usd_1d (daily GMV in USD)
- Order: placed_order_cnt_1d (daily), placed_order_cnt_30d (30-day rolling)

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: item_id, shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
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

- Studio Tasks References: 55 files (5 workflows, 1 scheduled_task, 45 manual_tasks, 2 personal)
- L7D Query Count: -
- Completeness: -
- Popularity: -
