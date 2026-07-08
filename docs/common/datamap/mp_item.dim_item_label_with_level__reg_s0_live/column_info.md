<!-- ads-workspace-gdoc-sync: gdoc_id=1HPluO7u0ioG2fSX8k2aENl3_KsD37OV6B7tF8CB3FOw gdoc_url=https://docs.google.com/document/d/1HPluO7u0ioG2fSX8k2aENl3_KsD37OV6B7tF8CB3FOw/edit -->

# Columns: mp_item.dim_item_label_with_level__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| label_id | 841356053736030 | Blacklist label (NPB/NPA/RCmd 黑名单, ~86% queries) |
| label_id | 843249807227517 | Blacklist label (NPB/NPA/RCmd 黑名单, ~86% queries) |
| label_id | 298553329 | Blacklist label (NPB/NPA/RCmd 黑名单, ~86% queries) |
| label_id | 1002164 | "original" label (Creative Producer, ~14% queries) |
| deleted | 0 | 正常记录 (仅 discovery_ads 查询过滤) |
| tz_type | 'local' | 仅 discovery_ads 查询使用本地时区 |

### 常见 WHERE 值 (Common Filter Values)

- `label_id IN (841356053736030, 843249807227517, 298553329)` — Blacklist filtering for NPB/NPA/RCmd workflows (~86% of queries)
- `label_id = 1002164 AND deleted = 0` — Creative enrichment for s2pro workflows (~14% of queries)
- `tz_type = 'local'` — Used in discovery_ads workflows
- `grass_region = upper('${region}')` — Dynamic region parameter, covers 11+ regions
- `grass_date = DATE('${grass_date}')` — Daily partition snapshot

## All Columns

> Note: DDL not found in paidads-alg codebase. Columns inferred from SQL query patterns across 50 reference files. Table is owned by mp_item team.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | 商品ID | - | - |
| shop_id | bigint | 卖家ID | - | - |
| label_id | bigint | 标签ID | - | - |
| deleted | int | 软删除标记 (0=正常) | - | - |
| grass_date | date | 分区日期 [PARTITION] | - | - |
| grass_region | string | 分区区域 [PARTITION] | - | - |
| tz_type | string | 时区类型 [PARTITION] | - | - |
