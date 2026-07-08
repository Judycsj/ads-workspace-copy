<!-- ads-workspace-gdoc-sync: gdoc_id=1-SZdKAw4-K9pws8cdHB2RB9_IH0uE54fDfdokdFt6rs gdoc_url=https://docs.google.com/document/d/1-SZdKAw4-K9pws8cdHB2RB9_IH0uE54fDfdokdFt6rs/edit -->

# Columns: regma_general.shop_attributes

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无（维度表，从代码库使用模式中未发现非累加字段）

### 枚举值映射 (Value Mappings)

代码库中仅读取 `principal_type` 字段，下游使用 CASE-WHEN 推导：

| Column | Derived Value | Meaning |
|--------|--------------|---------|
| principal_type | Cross Border | 当 is_cb_seller=1 且 principal_type IS NULL |
| principal_type | Local Brand | 当 principal_type IS NULL 且非 CB 卖家 (COALESCE default) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR') 加上 'MX'（通过 upper('${region}') 参数传入）
- 注意：无 `grass_date` 过滤条件，说明该表可能为无日期分区的快照表

## All Columns

基于代码库使用模式提取（仅 2 列被明确引用，其余列需 from-di 补充）：

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | 店铺 ID（使用时 cast 为 bigint） | - | - |
| principal_type | string | 店铺主营类型（如 Cross Border, Local Brand） | - | - |
| grass_region | string | 地域分区 | - | - |
