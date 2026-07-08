<!-- ads-workspace-gdoc-sync: gdoc_id=1sEAVQOCwIh02uKS7pO2GgCH9Qr7q2Al2iATwEU8xxHs gdoc_url=https://docs.google.com/document/d/1sEAVQOCwIh02uKS7pO2GgCH9Qr7q2Al2iATwEU8xxHs/edit -->

# Columns: marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

不适用 — 这是映射/配置表，不包含数值聚合字段。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| feature_toggle_tag_mapping_status | 3 | Deleted（所有查询中均排除） |

### 常见 WHERE 值 (Common Filter Values)

- `feature_toggle_tag_mapping_status`: != 3（所有查询均排除已删除映射，出现于 11/11 文件）

## All Columns

> DDL 未在代码库中找到（外部 Marketplace 表）。以下列从 SQL 使用推断。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| feature_id | bigint (inferred) | Feature Toggle 唯一 ID，与 feature_toggle_info_tab 关联 | - | - |
| tag_id | bigint (inferred) | Seller Tag ID，与 shop_tag_mapping_tab 关联 | - | - |
| ctime | timestamp (inferred) | 映射创建时间 | - | - |
| feature_toggle_tag_mapping_status | int (inferred) | 映射状态：3 = 已删除 | - | - |
