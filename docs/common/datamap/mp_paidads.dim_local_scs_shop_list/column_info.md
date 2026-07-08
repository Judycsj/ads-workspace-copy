<!-- ads-workspace-gdoc-sync: gdoc_id=1_EFbY2sGu23rEE54PmYsOBZFPf7wmGNPa_gDrKHIgjw gdoc_url=https://docs.google.com/document/d/1_EFbY2sGu23rEE54PmYsOBZFPf7wmGNPa_gDrKHIgjw/edit -->

# Columns: mp_paidads.dim_local_scs_shop_list

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a pure lookup list (dimension table). No aggregation patterns observed.

### 枚举值映射 (Value Mappings)

No CASE-WHEN mappings on this table. The table is always used as an existence check:

| Column | Value | Meaning |
|--------|-------|---------|
| local_scs | 1 | Hardcoded literal in all queries; marks shop as Local SCS |

### 常见 WHERE 值 (Common Filter Values)

No WHERE filters are applied to this table. It is always read without any partition or filter clauses -- the full list is fetched each time.

## All Columns

DDL not found in `projects/gitlab/paidads-alg/studio_tasks/`. Columns below inferred from read references.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | Shop identifier, used as JOIN key to identify Local SCS shops | - | - |
