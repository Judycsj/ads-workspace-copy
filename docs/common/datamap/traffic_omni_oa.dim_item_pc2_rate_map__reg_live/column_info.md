<!-- ads-workspace-gdoc-sync: gdoc_id=1JZUbezkoNIj7pbS6GRFZLRbVUfD_PPaYbI4_8BN5_5I gdoc_url=https://docs.google.com/document/d/1JZUbezkoNIj7pbS6GRFZLRbVUfD_PPaYbI4_8BN5_5I/edit -->

# Columns: traffic_omni_oa.dim_item_pc2_rate_map__reg_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段跨 item_id 聚合时必须使用 SUM(DISTINCT)：

- `pc2_rate` -- 每个 item 独有的 PC2 rate，跨 item 聚合时不能直接 SUM。正确用法：`SUM(DISTINCT pc2_rate) ... GROUP BY level2_global_be_category_id`
- `pc2_rate_exp_v2` -- 实验版 PC2 rate，同上。仅在 `dws_common_feature_user_item_pc2_1d` 工作流中使用

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | local | All queries use 'local' timezone |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% of queries -- always 'local')
- `grass_region`: Standard 8+1 regions: 'ID','MY','PH','SG','TH','TW','VN','BR','MX'
- `grass_date`: Rolling 30-day window via `grass_date between date('${grass_date_30day}') and date('${grass_date}')` (all queries), or single date in playground `grass_date = date('${grass_date}')`

## All Columns

> Column names and types inferred from SQL usage patterns. DDL not found in codebase. Run --source from-di to get exact types and descriptions.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date (partition) | Data partition date | - | - |
| grass_region | string (partition) | Region code (e.g. ID, MY, SG) | - | - |
| tz_type | string (partition) | Timezone type, always 'local' | - | - |
| item_id | bigint | Item identifier (primary key) | - | - |
| level2_global_be_category_id | bigint/string | Secondary global BE category ID | - | - |
| pc2_rate | double | Calibrated PC2 rate for the item (NON-ADDITIVE: use SUM DISTINCT) | - | - |
| pc2_rate_exp_v2 | double | Experimental PC2 rate v2 (NON-ADDITIVE: use SUM DISTINCT) | - | - |
