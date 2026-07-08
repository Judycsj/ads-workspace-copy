<!-- ads-workspace-gdoc-sync: gdoc_id=1UcNMjq8TQVB11vInRtIuq-b4Ibs1zD-0mSKSu8oGWTE gdoc_url=https://docs.google.com/document/d/1UcNMjq8TQVB11vInRtIuq-b4Ibs1zD-0mSKSu8oGWTE/edit -->

# Columns: mp_paidads.ads_sc_potential_product_ads_item_temp__reg

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段为比率或均值，不能简单 SUM 聚合，跨 item 聚合时需要重新计算：

- `ctrcr_7d` — 点击转化率 (orders/impressions)，不可直接 SUM
- `avg_order_7d` — 7天日均订单数，不可直接 SUM
- `avg_order_cnt_14d` — 对比期日均订单数，不可直接 SUM
- `order_growth_rate` — 订单增长率，不可直接 SUM

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| final_cat | (derived) | l3_cat > 0 时取 l3_cat, 否则 l2_cat > 0 取 l2_cat, 否则取 l1_cat — 取最细可用类目层级 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 大写国家码，如 'MX', 'SG', 'VN', 'TW', 'TH', 'PH', 'MY', 'ID', 'CO', 'CL', 'BR'
- `grass_date`: date'${BIZ_YESTERDAY}' (产出的业务日期，通常为 T-1)
- `item_id > 0`: 过滤无效 item

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| l1_cat | bigint | 一级类目 ID | - | - |
| l2_cat | bigint | 二级类目 ID | - | - |
| l3_cat | bigint | 三级类目 ID | - | - |
| final_cat | bigint | 最终类目 ID（取最细可用层级） | - | - |
| ctrcr_7d | double | 7天点击转化率 (orders/impressions) | - | - |
| gmv_usd_7d | double | 7天GMV (USD) | - | - |
| avg_order_7d | double | 7天日均订单数 | - | - |
| order_cnt_7d | double | 7天订单总数 | - | - |
| avg_order_cnt_14d | double | 对比期(14天前)日均订单数 | - | - |
| order_growth_rate | double | 订单增长率 (7d avg / 14d avg - 1) | - | - |
| impression_7d | bigint | 7天曝光数 | - | - |
| click_7d | bigint | 7天点击数 | - | - |
| grass_region | string | 国家/区域 [PARTITION] | - | - |
| grass_date | date | 数据日期 [PARTITION] | - | - |
