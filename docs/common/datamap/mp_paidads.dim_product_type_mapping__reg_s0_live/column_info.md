<!-- ads-workspace-gdoc-sync: gdoc_id=18Kb9gulFsx9mXMShbXnv38Z7N2wHCvG6MSlPYiDoMpI gdoc_url=https://docs.google.com/document/d/18Kb9gulFsx9mXMShbXnv38Z7N2wHCvG6MSlPYiDoMpI/edit -->

# Columns: mp_paidads.dim_product_type_mapping__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

从代码库中 SQL 引用的 CASE-WHEN 和 WHERE 过滤推断：

| Column | Value | Meaning |
|--------|-------|---------|
| main_product_type | Product Ads | 商品广告 (含 Manual, Simple, ROI2, Boost 等) |
| main_product_type | Live Ads | 直播广告 |
| main_product_type | Video Ads | 视频广告 |
| product_type | Manual Mode | 手动出价模式 |
| product_type | ROI2.0 | ROI2.0 自动出价模式 |

### 常见 JOIN 模式 (Common JOIN Patterns)

该表始终通过复合键 `(pricing_type, placement)` 进行 JOIN，且为有值全量映射（outer key 全部可匹配）：

- 标准模式：`LEFT JOIN product_type_mapping ON a.pricing_type = c.pricing_type AND a.placement = c.placement`
- CAST 适配：当源表字段类型不匹配时，`on a.placement = cast(b.placement as int) and a.pricing_type = cast(b.pricing_type as int)`
- 关联后 COALESCE：`COALESCE(sub_product_type,'others')`, `COALESCE(product_type,'Others')`, `COALESCE(main_product_type,'Others')`

### 常见 WHERE 值 (Common Filter Values)

该表通常全量加载不做过滤。在部分使用场景中会添加业务过滤：`main_product_type = 'Product Ads'`（只取商品广告）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| pricing_type | int | 出价类型，与 placement 组成复合键 | - | - |
| placement | int | 广告位，与 pricing_type 组成复合键 | - | - |
| sub_product_type | string | 子产品类型，最细粒度分类 | - | - |
| product_type | string | 产品类型，中间粒度分类（如 Manual Mode, ROI2.0） | - | - |
| main_product_type | string | 主产品类型，最粗粒度分类（如 Product Ads, Live Ads, Video Ads） | - | - |
