<!-- ads-workspace-gdoc-sync: gdoc_id=1KrhgfSZLbo2KhOuxIezb0955LfgcbCBTYOy_XG5Ni2Q gdoc_url=https://docs.google.com/document/d/1KrhgfSZLbo2KhOuxIezb0955LfgcbCBTYOy_XG5Ni2Q/edit -->

# Columns: mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。该表为维度表，所有字段均为 item 级别的属性，按 item_id 聚合时取 MIN(item_first_adopted_date) 和 MAX(is_migrated_item)。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | local | 本地时区 (唯一值) |
| grass_region | ID,MY,PH,SG,TH,TW,VN,BR | 8 个标准区域 |
| is_migrated_item | 0 | 非迁移商品 (Simple2 自然采纳) |
| is_migrated_item | 1 | 迁移商品 (从 Simple 迁移到 Simple2) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (所有查询)
- `grass_region`: 按区域单值过滤 ('ID','MY','PH','SG','TH','TW','VN','BR')
- `grass_date`: ${BIZ_YESTERDAY} (写), ${L1D_Date} / previous_2d (读)
- `item_id > 0`: 过滤无效商品

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | 商品ID | - | - |
| shop_id | bigint | 店铺ID | - | - |
| seller_id | bigint | 卖家ID | - | - |
| level1_global_be_category_id | bigint | 一级类目ID | - | - |
| level1_global_be_category | string | 一级类目名称 | - | - |
| level2_global_be_category_id | bigint | 二级类目ID | - | - |
| level2_global_be_category | string | 二级类目名称 | - | - |
| level3_global_be_category_id | bigint | 三级类目ID | - | - |
| level3_global_be_category | string | 三级类目名称 | - | - |
| item_first_adopted_date | date | 商品首次采纳 Simple2 的日期 | - | - |
| is_migrated_item | tinyint | 是否从 Simple 迁移到 Simple2 的商品 (0/1) | - | - |
| tz_type | string | [PARTITION] 时区类型 | - | - |
| grass_region | string | [PARTITION] 区域代码 | - | - |
| grass_date | date | [PARTITION] 分区日期 | - | - |
