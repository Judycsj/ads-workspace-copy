<!-- ads-workspace-gdoc-sync: gdoc_id=138mvNlnzmRqt6dUuJzuguF9MaP-2FnH90W664iXkWiU gdoc_url=https://docs.google.com/document/d/138mvNlnzmRqt6dUuJzuguF9MaP-2FnH90W664iXkWiU/edit -->

# mkplpaidads_data.item_price__reg_s0_live

## Description

- **Desc:** Item price view for Ads, providing the latest item prices in local currency and USD. Unified view combining `item_price_all_v2` (most regions) and `item_price_all` (BR only). Prices are stored in micro-units (divide by 100,000 for actual value). Source data comes from the item_price pipeline (feature_generation/item_price_update workflow) which processes `item_price_v2` and `item_price` with exchange rate conversion.
- **Granularity:** daily x item_id x country x status
- **Use Case:**
  - Voucher matching: Look up `item_price_usd` for order voucher calculation (ads_order_voucher_1d)
  - ROI2 suggest: Calculate `ads_item_price = price / 100000` for ROI and budget suggestions (ads_sc_roi2_suggest_roi_budget_item_daily)
  - Item performance: Extract `algo_item_price` and `algo_item_price_usd` for DW layer (dws_item_performance_nd)
  - Shop GMV max: Calculate ads_item_price for bidding budget recommendations (ads_bidding_shop_gmv_max_*)
  - Item paid order ratio: Get item price for paid/broad order ratio computation (ads_indexer_item_paid_order_ratio_daily)
- **Update Frequency:** Daily

## Key Metrics

- **price** (bigint): Local currency price in micro-units. Divide by 100,000 for actual value.
- **price_usd** (bigint): USD price in micro-units. Divide by 100,000 for actual value.
- **price_type** (string): Type of price classification
- **avg_price_3d** (double): Average price over last 3 days (BR only)
- **avg_price_7d** (double): Average price over last 7 days (BR only)

## Key Dimensions

- 分区: dt (date string), status (int), country (string)
- 业务: item_id (bigint, lookup key)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | VIEW (no physical storage) |
| Partition Columns | N/A (VIEW - underlying tables partitioned by dt, status, country) |
| HDFS Path | N/A (VIEW) |
| Retention | N/A (VIEW) |
| Column Count | 8 (7 non-partition + 3 partition columns from union) |
| Region Coverage | SG, CO, CL, MX, VN, MY, TW, TH, PH, ID, BR (11 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 87 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
