<!-- ads-workspace-gdoc-sync: gdoc_id=1ejAVdjgq_P9lhq66g0ogcbt4GmWMSPqjakmoT7LwH2Y gdoc_url=https://docs.google.com/document/d/1ejAVdjgq_P9lhq66g0ogcbt4GmWMSPqjakmoT7LwH2Y/edit -->

# Columns: mp_item.dws_shop_listing_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未从代码中识别到 SUM(DISTINCT) 模式。

### 枚举值映射 (Value Mappings)

未从代码中识别到跨文件重复的 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~95% of queries use 'local')
- `grass_region`: standard 8 regions ('BR','ID','MY','PH','SG','TH','TW','VN'), some queries also include 'MX','CO','CL'
- `grass_date`: typically `'${BIZ_PRE_DAY}'` or `'${BIZ_YESTERDAY}'` (single day filter)

## All Columns

> Note: Hive DDL not found in paidads-alg codebase (table owned by mp_item team). Columns inferred from SQL usage patterns.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | Shop ID | - | - |
| active_item_cnt | bigint | Number of active (listed) items for the shop | - | - |
| shop_level1_global_be_category | string | Shop L1 global BE category name | - | - |
| shop_level2_global_be_category | string | Shop L2 global BE category name | - | - |
| shop_level1_global_be_category_id | bigint | Shop L1 global BE category ID | - | - |
| shop_level2_global_be_category_id | bigint | Shop L2 global BE category ID | - | - |
| shop_level1_fe_display_category | string | Shop L1 FE display category name | - | - |
| shop_level2_fe_display_category | string | Shop L2 FE display category name | - | - |
| shop_level1_fe_display_category_id | bigint | Shop L1 FE display category ID | - | - |
| shop_level1_kpi_category | string | Shop L1 KPI category name | - | - |
| shop_level2_kpi_category | string | Shop L2 KPI category name | - | - |
| grass_region | string | [PARTITION] Region code (e.g. 'SG','ID') | - | - |
| grass_date | date | [PARTITION] Business date | - | - |
| tz_type | string | [PARTITION] Timezone type ('local' / 'regional') | - | - |
