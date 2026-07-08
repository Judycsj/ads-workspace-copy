<!-- ads-workspace-gdoc-sync: gdoc_id=1xAriM-G9F_E5dQr2AH_BmJTaIrlurV9_2jvk_J32U0k gdoc_url=https://docs.google.com/document/d/1xAriM-G9F_E5dQr2AH_BmJTaIrlurV9_2jvk_J32U0k/edit -->

# Columns: mp_foa.dim_feature_map__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

N/A -- dimension table, no metric columns.

### 枚举值映射 (Value Mappings)

*Extracted from CASE-WHEN across 18+ Take Rate workflow files.*

| Column | Value | Meaning |
|--------|-------|---------|
| feature_group | Search | Search-related features (global_search, search_in_pdp, etc.) |
| feature_group | You May Also Like | PDP recommendation features |
| feature_group | Rcmd Others | Other recommendation placements (order_list, order_detail) |
| feature_group | Live Streaming | Livestream-related features (streaming_room) |
| feature_group | Daily Discover | Homepage Daily Discover feed |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') -- always uppercase, standard 8-11 regions (SG, MY, PH, TW, VN, ID, TH, BR, MX, CO, CL)
- `grass_date`: `max(grass_date)` subquery -- always reads the latest available partition per region

## All Columns

*Column names and types inferred from SQL usage. Run `--source from-di` to populate description, query frequency, and MAX values.*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| feature_detail | string | Concatenated feature key (page_type-page_section-target_type) | - | - |
| feature_group | string | Feature group name (Search, You May Also Like, Live Streaming, etc.) | - | - |
| feature | string | Individual feature name | - | - |
| grass_date | date | Partition: date | - | - |
| grass_region | string | Partition: upper-case region code | - | - |
