<!-- ads-workspace-gdoc-sync: gdoc_id=1LxpzAFMFRjulbGFktAsXgaK1Vzquly9ZNqIJ19l7jFA gdoc_url=https://docs.google.com/document/d/1LxpzAFMFRjulbGFktAsXgaK1Vzquly9ZNqIJ19l7jFA/edit -->

# Columns: mkplpaidads_data.dim_common_item_latest__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为维度快照表 (dim table)，所有字段均为 item_id x grass_region 粒度，不具备累加性。跨 item 聚合取值需用 MAX/MIN/FIRST，不可直接 SUM。

- `price`, `price_usd`, `price_min`, `price_max`, `discount_pct` -- 商品维度价格，不可 SUM
- `rating_star` -- 商品维度评分，不可 SUM
- `sold_cnt`, `liked_cnt`, `rating_good_cnt`, `rating_normal_cnt`, `rating_bad_cnt` -- 商品维度计数，不可 SUM
- `actual_stock`, `stock` -- 商品维度库存，不可 SUM
- `create_timestamp`, `modify_timestamp` -- 时间戳，不可 SUM
- `is_free_shipping`, `status`, `shop_status` -- 状态标志，不可 SUM

### 去重注意事项

同一 `item_id` 可能对应多个 `shop_id` (一个 item 在不同 shop 出现)，使用 `DISTINCT` 或 `ROW_NUMBER()` 按业务需求去重：
- JOIN 前用 `(grass_region, item_id, shop_id)` 粒度 GROUP BY
- 再按 `(grass_region, item_id)` 选择单行 (如 `ROW_NUMBER() OVER (PARTITION BY grass_region, item_id ORDER BY shop_id DESC)`)

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| status | 1 | Active (正常在售) |
| status | 0 | Inactive |
| shop_status | 1 | Active shop |
| is_free_shipping | 1 | Free shipping enabled |
| is_free_shipping | 0 | No free shipping |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8+ 区: 'SG','MY','TH','PH','TW','ID','VN','BR' (加上 'MX','CO','CL','AR')
- `status`: 1 (过滤出在售商品，~80% 查询包含)
- `grass_region = 'SG'` -- 单区测试/分析常用
- `shop_id > 0`, `item_id > 0` -- 排除无效 ID
- `price_min > 0`, `price_max > 0` -- 排除无价格商品
- `level1_global_be_category_id IS NOT NULL` -- 过滤无分类商品
- `level3_global_be_category_id = 100209` -- SG 特定三级品类过滤 (手机壳)

## All Columns

*从代码库 267 个引用文件中归纳，非完整 DDL。from-code only 模式，建议运行 `--source from-di` 补充描述和查询频率。*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | Item ID (primary key with grass_region) | - | - |
| shop_id | bigint | Shop ID | - | - |
| grass_region | string | Region code (partition column) | - | - |
| dt | string/date | Snapshot date (partition column) | - | - |
| name | string | Item name/title | - | - |
| images | array\<string\> | Array of image URLs | - | - |
| sold_cnt | int | Historical sold count | - | - |
| liked_cnt | int | Like count | - | - |
| rating_good_cnt | int | Good rating count | - | - |
| rating_normal_cnt | int | Normal rating count | - | - |
| rating_bad_cnt | int | Bad rating count | - | - |
| comment_cnt | int | Comment count | - | - |
| price | decimal(25,10) | Item price | - | - |
| price_usd | decimal | Item price in USD | - | - |
| price_min | decimal(25,10) | Min price (before discount) | - | - |
| price_max | decimal(25,10) | Max price (before discount) | - | - |
| discount_pct | double | Discount percentage | - | - |
| rating_star | double | Average star rating | - | - |
| level1_global_be_category_id | bigint | L1 global BE category ID | - | - |
| level2_global_be_category_id | bigint | L2 global BE category ID | - | - |
| level3_global_be_category_id | bigint | L3 global BE category ID | - | - |
| level4_global_be_category_id | bigint | L4 global BE category ID | - | - |
| level5_global_be_category_id | bigint | L5 global BE category ID | - | - |
| level2_global_be_category_local_name | string | L2 category local language name | - | - |
| global_brand_id | int | Global brand ID (0 = no brand) | - | - |
| global_brand | string | Global brand name | - | - |
| tier_variations | array\<struct\> | Tier/variation details (name, options, images, properties, type) | - | - |
| attr_infos | array\<struct\> | Attribute info array (global_attr_name, value, etc.) | - | - |
| status | int | Item status (1 = active) | - | - |
| shop_status | int | Shop status (1 = active) | - | - |
| is_free_shipping | tinyint | Free shipping flag | - | - |
| actual_stock | int | Actual stock quantity | - | - |
| stock | int | Stock quantity | - | - |
| create_datetime | string/timestamp | Create datetime | - | - |
| modify_datetime | string/timestamp | Modify datetime | - | - |
| create_timestamp | bigint | Create unix timestamp | - | - |
| modify_timestamp | bigint | Modify unix timestamp | - | - |
