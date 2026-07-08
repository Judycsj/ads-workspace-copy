<!-- ads-workspace-gdoc-sync: gdoc_id=17ziTSk0myFOI-sxHLRh-yEWGF-HISRbc6YXRQi0lxMM gdoc_url=https://docs.google.com/document/d/17ziTSk0myFOI-sxHLRh-yEWGF-HISRbc6YXRQi0lxMM/edit -->

# Columns: mp_item.rt_dim_item__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a dimension table — all fields are non-additive attributes. No SUM(DISTINCT) patterns detected.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| status | 1 | Active item (default filter in all workflows) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 10 regions — 'ID','MY','PH','SG','TH','TW','VN','BR','MX','CO' (parameterized via `${grass_region}`)
- `status`: 1 — active items only (used in 100% of reads)
- `date(create_datetime)`: date range filter — typically items created within last 20 days relative to `${grass_date}`
- `grass_region`: 'SG', 'ID' — used in ad-hoc coverage validation queries

## All Columns

Source: from-code SQL references. Limited to columns observed in SQL usage. No DDL found in codebase — run `--source from-di` to get full column list with descriptions.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | Item unique identifier (PK) | - | - |
| create_datetime | string | Item creation local datetime (yyyy-MM-dd HH:mm:ss) | - | - |
| create_timestamp | bigint | Item creation unix timestamp | - | - |
| status | bigint | Item status (1 = active) | - | - |
| grass_region | string | Region partition column | - | - |
| modify_datetime | string | Item last modification local datetime | - | - |
