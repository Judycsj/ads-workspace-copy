<!-- ads-workspace-gdoc-sync: gdoc_id=16SBAeLg-fzWiV55Q732uIxUvh_YO-5O4WKuxDGMWJSY gdoc_url=https://docs.google.com/document/d/16SBAeLg-fzWiV55Q732uIxUvh_YO-5O4WKuxDGMWJSY/edit -->

# Columns: mpi_data_mart.dws_all_user_segmentation_tags_df

> **Note:** DDL not found in the paidads-alg codebase. Columns below are inferred from usage in downstream SQL files. Run `--source from-di` to fetch the full column list from DataMap.

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

No SUM(DISTINCT) patterns found in relation to this table. The table is used solely as a simple filter in downstream queries.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| a30_user | Yes | User was active in the last 30 days |
| a30_user | No | User was NOT active in the last 30 days |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') -- always parameterized, regions include ID, MY, PH, SG, TH, TW, VN, BR, CL, CO, MX
- `grass_date`: date'${yesterday}' -- always queried for the previous day
- `a30_user`: 'Yes' -- always filtered to active users only (~100% of queries)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint (inferred) | User identifier | - | - |
| a30_user | string (inferred) | Whether user was active in last 30 days ('Yes'/'No') | - | - |
| grass_region | string (inferred) | Region partition column | - | - |
| grass_date | date (inferred) | Date partition column | - | - |
