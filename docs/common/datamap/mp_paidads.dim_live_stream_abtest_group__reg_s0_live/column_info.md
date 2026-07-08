<!-- ads-workspace-gdoc-sync: gdoc_id=1-RvpykyBnHTv0lxc7MbzI4aM0fBEvfXi6SO7hdE9UfQ gdoc_url=https://docs.google.com/document/d/1-RvpykyBnHTv0lxc7MbzI4aM0fBEvfXi6SO7hdE9UfQ/edit -->

# Columns: mp_paidads.dim_live_stream_abtest_group__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无 — 本表为维度表，group_id 和 user_id 均为维度键，不适用 SUM 聚合。

### 枚举值映射 (Value Mappings)

无 — 本表为维度映射表，不包含需要通过CASE-WHEN枚举的业务字段。

### 常见 WHERE 值 (Common Filter Values)

- **tz_type**: 'local' (生产环境固定值)
- **grass_region**: 'SG', 'MY', 'PH', 'ID', 'TH', 'TW', 'VN', 'BR', 'CO', 'CL', 'MX' (11 regions)
- **group_id**: 如 137094, 137095, 137096 等实验分组ID，通过 IN 子句筛选
- **grass_date**: 单日过滤 `grass_date = date('${grass_date}')`，或7天范围 `grass_date between date_sub('${grass_date}', 7) and date_sub('${grass_date}', 1)`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| group_id | bigint | user experiment group id | - | - |
| user_id | bigint | user_id | - | - |
| tz_type | string | 时区类型 (partition) | - | - |
| grass_region | string | 国家/区域 (partition) | - | - |
| grass_date | date | 数据日期 (partition) | - | - |
