<!-- ads-workspace-gdoc-sync: gdoc_id=1uM2yXPSkRgFZRuRObw1EsZP7HkP-Z18ORXavavJ40Oc gdoc_url=https://docs.google.com/document/d/1uM2yXPSkRgFZRuRObw1EsZP7HkP-Z18ORXavavJ40Oc/edit -->

# Columns: mp_order.dws_item_gmv_td__reg_s0_live

## Column Usage Notes

### Non-Additive Fields

No non-additive fields identified in current codebase references.

### Value Mappings

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | 'local' | Local timezone (used in all workflow queries) |
| tz_type | 'regional' | Regional timezone (rare, not observed in codebase) |

### Common Filter Values

- `tz_type`: 'local' (exclusive, all workflow queries use local timezone)
- `grass_region`: Standard regions -- 'ID','MY','PH','SG','TH','TW','VN','BR'; Americas -- 'MX','CL','CO'
- `grass_date`: Single day (`= '${grass_date}'`), or T-2 (`= current_date - interval '2' day` in manual tasks)
- `grass_region`: Always parameterized as `upper('${region}')` in workflow tasks
- Row-level filters (not commonly applied, queries aggregate to shop level):
  - `placed_order_cnt_td > 0` (items with orders, for active item counts)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | Item identifier | - | - |
| shop_id | bigint | Shop identifier | - | - |
| gmv_usd_td | double | Cumulative GMV in USD (item creation to date) | - | - |
| placed_order_cnt_td | bigint | Cumulative placed order count (item creation to date) | - | - |
| placed_order_fraction_td | double | Cumulative order fraction (used for attribution/proration) | - | - |
| tz_type | string | Timezone type [PARTITION] | - | - |
| grass_region | string | Region code [PARTITION] | - | - |
| grass_date | date | Partition date (snapshot date) [PARTITION] | - | - |

**Note:** Column list is inferred from code references (no DDL found in paidads-alg codebase since this table is owned by mp_order). The table is a TD (to-date) variant in the `dws_item_gmv_*` family alongside `dws_item_gmv_1d` (daily) and `dws_item_gmv_nd` (N-day rolling). Additional columns such as `gmv_td` (local currency), `paid_order_cnt_td`, `placed_buyer_cnt_td`, `placed_item_cnt_td`, and `item_amount_td` may exist but were not observed in codebase references. Run `--source from-di` to get the complete column list with descriptions and query frequency.
