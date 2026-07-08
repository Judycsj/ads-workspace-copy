<!-- ads-workspace-gdoc-sync: gdoc_id=1vZUH2unp6V2W76pAqxDupkeSTrOz4kCKKXxXpvb5ihM gdoc_url=https://docs.google.com/document/d/1vZUH2unp6V2W76pAqxDupkeSTrOz4kCKKXxXpvb5ihM/edit -->

# Columns: marketplace.shopee_seller_shop_tag_mapping_latam_

> Note: 该表为 marketplace 侧表，列定义从 SQL 引用中推断。完整 DDL 需运行 `--source from-di` 补充。

## Column Usage Notes

### 枚举值映射 (Value Mappings)

> SQL 中未发现针对该表列的 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

- `region`: `UPPER('${region}')` — LatAm 国家代码（MX, BR, CO, CL），每次查询均按区域过滤
- `shop_tag_mapping_status`: `1` — 100% 查询都会过滤 status = 1（活跃映射）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | 店铺标识 | - | - |
| tag_id | BIGINT | 标签标识，关联 feature_toggle_tag_mapping_tab | - | - |
| region | string | 区域代码（LatAm），如 MX/BR/CO/CL | - | - |
| shop_tag_mapping_status | int | 映射状态：1 = active | - | - |
