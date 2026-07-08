<!-- ads-workspace-gdoc-sync: gdoc_id=1XDYamSCJzhN1MskfJtqkjBTm0R-bwl87HhjKB-BxUWg gdoc_url=https://docs.google.com/document/d/1XDYamSCJzhN1MskfJtqkjBTm0R-bwl87HhjKB-BxUWg/edit -->

# Columns: marketplace.shopee_seller_shop_tag_mapping_

> **Note**: DDL 未在 Ads 代码库中找到（该表由 Marketplace 侧管理）。以下列信息从 SQL 使用模式中提取。

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `region`: `UPPER('${region}')` — 全量文件均使用此条件，值域覆盖 ID/MY/PH/SG/TH/TW/VN/BR/MX/CO/CL
- `shop_tag_mapping_status`: `= 1` — 全量文件均使用此条件，仅取生效中的映射关系。status=3 为已删除

### 非累加字段 (Non-Additive Fields)

> 该表为维度映射表，无不涉及聚合。不影响累加性判断。

### 枚举值映射 (Value Mappings)

> 该表无 CASE-WHEN 枚举值映射（所有映射逻辑在上游 feature_toggle 表中完成）。

## All Columns

> DDL 未在 Ads 代码库中找到，以下列名从 SQL 引用中提取。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | 店铺 ID | - | - |
| tag_id | ? | 标签 ID，与 feature_toggle_tag_mapping 的 tag_id 关联 | - | - |
| region | STRING | 大区代码（如 ID/MY/PH/SG/TH/TW/VN/BR/MX/CO/CL） | - | - |
| shop_tag_mapping_status | INT | 映射状态，1=生效中 | - | - |
