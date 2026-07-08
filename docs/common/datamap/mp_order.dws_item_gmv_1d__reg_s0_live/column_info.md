<!-- ads-workspace-gdoc-sync: gdoc_id=1yFw-bOBdNRygtour_QEsBOuFOp8QFQbe4FJEVRSh3AM gdoc_url=https://docs.google.com/document/d/1yFw-bOBdNRygtour_QEsBOuFOp8QFQbe4FJEVRSh3AM/edit -->

# Columns: mp_order.dws_item_gmv_1d__reg_s0_live

## Column Usage Notes

### Non-Additive Fields

No non-additive fields identified in current codebase references.

### Value Mappings

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | 'local' | Local timezone (used in ~95% of queries) |
| tz_type | 'regional' | Regional timezone (rare) |

### Common Filter Values

- `tz_type`: 'local' (dominant, nearly all queries use local timezone)
- `grass_region`: Standard regions -- 'ID','MY','PH','SG','TH','TW','VN','BR'; US regions -- 'MX','CL','CO'
- `grass_date`: Single day (`= date('${BIZ_YESTERDAY}')`) or date range (7d/14d/21d/30d/60d/90d windows)
- Common date range patterns:
  - `between date('${PREV_7D}') and date('${BIZ_YESTERDAY}')` -- 7-day window
  - `between date('${PREV_30D}') and date('${BIZ_YESTERDAY}')` -- 30-day window
  - `>= DATE_SUB(DATE('${grass_date}'), 6) and <= DATE('${grass_date}')` -- last 7 days
  - `between (DATE('${grass_date}') - INTERVAL 89 DAYS) and DATE('${grass_date}')` -- 90-day window
  - `>= date(date_trunc('month', '${grass_date}'))` -- month-to-date
- Row-level filters:
  - `gmv_usd_1d > 0` (filter out zero-GMV items)
  - `gmv_1d > 0` (local currency variant)
  - `placed_order_cnt_1d > 0` (items with orders)
  - `placed_order_cnt_1d >= 1` (seller-level having clause)
  - `item_id is not null` (data quality filter)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | Item identifier | - | - |
| shop_id | bigint | Shop identifier | - | - |
| gmv_usd_1d | double | Daily GMV in USD | - | - |
| gmv_1d | double | Daily GMV in local currency | - | - |
| placed_order_cnt_1d | bigint | Daily placed order count | - | - |
| paid_order_cnt_1d | bigint | Daily paid order count | - | - |
| placed_buyer_cnt_1d | bigint | Daily placed buyer count | - | - |
| placed_item_cnt_1d | bigint | Daily placed item count | - | - |
| item_amount_1d | bigint | Daily item amount (quantity) | - | - |
| tz_type | string | Timezone type [PARTITION] | - | - |
| grass_region | string | Region code [PARTITION] | - | - |
| grass_date | date | Partition date [PARTITION] | - | - |

**Note:** Column list is inferred from code references (no DDL found in paidads-alg codebase since this table is owned by mp_order). Run `--source from-di` to get the complete column list with descriptions and query frequency.
