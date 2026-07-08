<!-- ads-workspace-gdoc-sync: gdoc_id=12g2nV_cV3LNF2vny6M8HEHngd4XQ7C0-YOfxrg368og gdoc_url=https://docs.google.com/document/d/12g2nV_cV3LNF2vny6M8HEHngd4XQ7C0-YOfxrg368og/edit -->

# Columns: mkplpaidads_data.item_price__reg_s0_live

## Column Usage Notes

### About This View

`item_price__reg_s0_live` is a VIEW, not a physical table. It is defined as:

```sql
CREATE OR REPLACE VIEW item_price__reg_s0_live AS (
    SELECT * FROM item_price_all_v2
    WHERE country IN ('SG', 'CO', 'CL', 'MX', 'VN', 'MY', 'TW', 'TH', 'PH', 'ID')
    UNION ALL
    SELECT * FROM item_price_all
    WHERE country IN ('BR')
)
```

- `item_price_all_v2` is written from `item_price_v2` JOIN `dim_exchange_rate__reg_s0_live` (daily workflow)
- `item_price_all` is written from `item_price` JOIN `dim_exchange_rate__reg_s0_live` (BR only, daily workflow)
- Column `avg_price_3d` and `avg_price_7d` are only available for BR region (from `item_price_all`)

### 非累加字段 (Non-Additive Fields)

- **price**: Stored in micro-units (bigint). Do NOT sum across items directly.
- **price_usd**: Stored in micro-units (bigint). Do NOT sum across items directly.
- **update_time**: Latest update timestamp, not additive.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| country | SG, CO, CL, MX, VN, MY, TW, TH, PH, ID | Regions from item_price_all_v2 |
| country | BR | Brazil - separate source (item_price_all) |

### 常见 WHERE 值 (Common Filter Values)

- `dt`: Usually `'${BIZ_YESTERDAY}'` or `'${PREV_2D}'` (~80% of queries)
- `country`: `upper('${region}')` or `'${upper_region}'` (matched to grass_region)
- `dt >= date_sub(date('${grass_date}'), 3)`: Used in voucher matching to get latest available price within 3-day window
- `dt = (SELECT max(dt) ...)`: Used to get the most recent price snapshot when date doesn't exactly match

### 派生指标 (Derived Metrics)

- **ads_item_price**: `cast(price as double) / 100000` -- local currency price in actual units (used in ROI2, Shop GMV max, item paid order ratio workflows)
- **algo_item_price**: `cast(price as double) / 100000` -- same calculation, named differently in dws_item_performance_nd
- **algo_item_price_usd**: `cast(price_usd as double) / 100000` -- USD price in actual units (dws_item_performance_nd)
- **item_price_usd**: `price_usd` -- raw USD micro-unit price, used directly in voucher matching

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | Item ID (business key) | - | - |
| price | bigint | Local currency price in micro-units (divide by 100,000) | - | - |
| price_usd | bigint | USD price in micro-units (divide by 100,000) | - | - |
| price_type | string | Price type classification | - | - |
| update_time | bigint | Last update timestamp | - | - |
| avg_price_3d | double | Average price over 3 days (BR only) | - | - |
| avg_price_7d | double | Average price over 7 days (BR only) | - | - |
| dt | string | Partition: date string (e.g. '2026-06-15') | - | - |
| status | int | Partition: item status | - | - |
| country | string | Partition: region code (SG, MY, ID, etc.) | - | - |
