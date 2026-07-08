<!-- ads-workspace-gdoc-sync: gdoc_id=1qSR41p3z9yTQ69Nd_OM-DhKZkgmrgkUMEeR3SS9rbfo gdoc_url=https://docs.google.com/document/d/1qSR41p3z9yTQ69Nd_OM-DhKZkgmrgkUMEeR3SS9rbfo/edit -->

# Columns: abtest.abtest_mart_dws_assignment_agg_1d

> DDL not found in paidads-alg codebase. Column list inferred from SQL usage patterns across 580 read references.

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- **grass_region**: Standard 8 regions ('ID','MY','PH','SG','TH','TW','VN','BR'), used with `IN` or `IN (upper('${region}'))`
- **local_date**: Date range filter via `between date'${start}' and date'${end}'` or single date `= date('${grass_date}')`
- **user_id**: `user_id > 0` or `user_id is not null and user_id != 0` (exclude invalid users)
- **group_id**: `group_id in (${exp_group_id})` (specific experiment groups)
- **scene_id**: Used to filter specific AB test scenes, e.g.:
  - Search Ads scenes: `scene_id IN (422, 443, 515, 516, 381, 437, 435, 433, 414, 390, 389, 388, 387, 340, 308)`
  - Shop Ads scene: `scene_id = 885`
- **layer_id**: Filter specific experiment layers, e.g. `layer_id = 4296` (search guide related experiments)
- **traffic_split_type**: `traffic_split_type in ('userid', 'userId')` (user-level traffic split)
- **experiment_id**: Referenced in comments/descriptions but rarely used in WHERE directly

### Non-Additive Fields

This table is a dimension/mapping table. `user_id` should use `DISTINCT` counting pattern when counting unique users per group.

## All Columns

Columns observed from actual SQL usage patterns (DDL unavailable):

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | User identifier | - | - |
| group_id | bigint | Experiment group ID assigned to the user | - | - |
| grass_region | string | Region code (partition column) | - | - |
| local_date | date | Local date for the assignment record (partition column) | - | - |
| scene_id | bigint | AB test scene ID (experiment context) | - | - |
| layer_id | bigint | AB test layer ID | - | - |
| experiment_id | bigint | AB test experiment ID | - | - |
| traffic_split_type | string | Traffic split mechanism type ('userid', 'userId', etc.) | - | - |
