<!-- ads-workspace-gdoc-sync: gdoc_id=1AtY4lLxXtCNI_LJ8M_-TROP4fKWo-pKx4ALProviJsg gdoc_url=https://docs.google.com/document/d/1AtY4lLxXtCNI_LJ8M_-TROP4fKWo-pKx4ALProviJsg/edit -->

# Columns: srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type

## Column Usage Notes

### 枚举值映射 (Value Mappings)

cspu_type 枚举映射（从注释代码提取，4 个文件出现）:

| Column | Value | Meaning |
|--------|-------|---------|
| cspu_type | 1 | New CSPU (新 CSPU) -- P0 高优先级 |
| cspu_type | 2 | No CSPU (无 CSPU) |
| cspu_type | 3 | Not-enough-low ado (低需求现有 CSPU) |
| cspu_type | 4 | Not-enough (高需求低供给) -- P0 高优先级 |
| cspu_type | 6 | Enough-high supply (高需求高供给) |
| cspu_type | 8 | Other (其他) |

### 派生字段 (Derived Fields)

`is_p0_cspu_type` (不在表中，为下游派生):
```sql
CASE WHEN cspu_type IN (1, 4) THEN 1 ELSE 0 END AS is_p0_cspu_type
```
- 6/6 个文件使用此逻辑
- NULL 时处理为 `COALESCE(cspu_type, -1)`，此时 is_p0_cspu_type = 0

### 常见 WHERE 值 (Common Filter Values)

- `local_date`: `date('${BIZ_PRE_DAY}')` 或 `date('${ISO_7DAY_AGO}')` -- 使用最新分区
- `grass_region`: 标准 7 区 (`'ID','TH','MY','VN','PH','SG','TW'`) 或 8 区（含 `'BR'`）
- `item_id IN (subquery)`: 通过子查询限定商品范围

## All Columns

*from-code 字段从 SQL SELECT 提取，from-di 字段需运行 `--source from-di` 补充*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| local_date | date | 日期分区 | - | - |
| grass_region | string | 地区 | - | - |
| item_id | bigint | 商品 ID | - | - |
| cspu_type | bigint | CSPU 分类类型（1-8），详见枚举值映射 | - | - |
