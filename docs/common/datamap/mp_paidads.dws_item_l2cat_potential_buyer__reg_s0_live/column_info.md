<!-- ads-workspace-gdoc-sync: gdoc_id=1JOzH312aC-CejY323wK5FSrbAXFftQm8z-r1x5wE9HA gdoc_url=https://docs.google.com/document/d/1JOzH312aC-CejY323wK5FSrbAXFftQm8z-r1x5wE9HA/edit -->

# Columns: mp_paidads.dws_item_l2cat_potential_buyer__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为 (user_id, l2_item_cat) 粒度的标签表，无指标类非累加字段。potential_buyer_type 是用户级的分类标签，不做聚合累加，而是在下游通过 WHERE potential_buyer_type >= 2 做过滤使用。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| potential_buyer_type | 0 | 非潜在买家（不满足最低阈值） |
| potential_buyer_type | 1 | 低潜在买家 |
| potential_buyer_type | 2 | 中潜在买家（TA广告召回的最低门槛） |
| potential_buyer_type | 3 | 高潜在买家 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准11区 ('SG','MY','ID','PH','VN','TH','TW','MX','CO','CL','BR')
- `grass_date`: date'${yesterday}'（绝大多数查询读取最新一天的分区）
- `potential_buyer_type`: >= 2（下游 TA 召回的最低门槛，几乎所有消费方都使用此条件）
- `l2_item_cat`: 具体类目ID（如 100737），用于特定类目的潜在买家分析

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | - | - | - |
| l2_item_cat | bigint | - | - | - |
| potential_buyer_type | int | - | - | - |
| grass_region | string | [PARTITION] | - | - |
| grass_date | DATE | [PARTITION] | - | - |
