<!-- ads-workspace-gdoc-sync: gdoc_id=16-ojiEgmle1awRmeyGuJMEoiEIDeXHps4iCrAJ7nCzo gdoc_url=https://docs.google.com/document/d/16-ojiEgmle1awRmeyGuJMEoiEIDeXHps4iCrAJ7nCzo/edit -->

# Columns: mp_order.dws_item_gmv_nd__reg_s0_live

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
- `grass_region`: Standard 8 regions -- 'ID','MY','PH','SG','TH','TW','VN','BR'
- `grass_date`: T-1 or T-2 (`date_add(current_date(), -1)`, `${BIZ_PRE_TWO_DAYS}`, single date)
- `placed_order_cnt_30d > 0` -- active item filter (most common business filter)
- `item_id is not null` -- data quality filter

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | Item identifier | - | - |
| shop_id | bigint | Shop identifier (inferred) | - | - |
| gmv_usd_1d | double | Daily GMV in USD | - | - |
| placed_order_cnt_1d | bigint | Daily placed order count | - | - |
| placed_order_cnt_30d | bigint | 30-day rolling placed order count | - | - |
| tz_type | string | Timezone type [PARTITION] | - | - |
| grass_region | string | Region code [PARTITION] | - | - |
| grass_date | date | Partition date [PARTITION] | - | - |

**Note:** Column list is inferred from code references (no DDL found in paidads-alg codebase since this table is owned by mp_order). Run `--source from-di` to get the complete column list with descriptions and query frequency.
