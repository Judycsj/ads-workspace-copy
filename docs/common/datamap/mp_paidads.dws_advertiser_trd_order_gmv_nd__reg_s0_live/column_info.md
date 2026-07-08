<!-- ads-workspace-gdoc-sync: gdoc_id=17ZMwnU0rfa0QWXlYuZok-wQXDSEeqqD2LmMol3NjZ9w gdoc_url=https://docs.google.com/document/d/17ZMwnU0rfa0QWXlYuZok-wQXDSEeqqD2LmMol3NjZ9w/edit -->

# Columns: mp_paidads.dws_advertiser_trd_order_gmv_nd__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未从代码库中检测到 SUM(DISTINCT) 模式。所有指标均为 shop_id 维度下的滚动窗口聚合，按 grass_region 分组，可直接 SUM 聚合。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | local | 本地时区 (US 地区: MX/BR/CO/CL) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (唯一值，US 地区 workflow)
- `grass_region`: MX, BR, CO, CL (各 workflow 按 region 变量写入)
- `grass_date`: 通常为当前调度日期 `DATE('${grass_date}')`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | shopid | - | - |
| user_id | BIGINT | userid | - | - |
| buyer_cnt_1d | BIGINT | buyer_cnt_1d | - | - |
| buyer_cnt_7d | BIGINT | buyer_cnt_7d | - | - |
| buyer_cnt_30d | BIGINT | buyer_cnt_30d | - | - |
| buyer_cnt_60d | BIGINT | buyer_cnt_60d | - | - |
| buyer_cnt_90d | BIGINT | buyer_cnt_90d | - | - |
| order_cnt_1d | BIGINT | order_cnt_1d | - | - |
| order_cnt_7d | BIGINT | order_cnt_7d | - | - |
| order_cnt_30d | BIGINT | order_cnt_30d | - | - |
| order_cnt_60d | BIGINT | order_cnt_60d | - | - |
| order_cnt_90d | BIGINT | order_cnt_90d | - | - |
| order_item_cnt_1d | BIGINT | order_item_cnt_1d | - | - |
| order_item_cnt_7d | BIGINT | order_item_cnt_7d | - | - |
| order_item_cnt_30d | BIGINT | order_item_cnt_30d | - | - |
| order_item_cnt_60d | BIGINT | order_item_cnt_60d | - | - |
| order_item_cnt_90d | BIGINT | order_item_cnt_90d | - | - |
| items_sold_cnt_1d | BIGINT | items_sold_cnt_1d | - | - |
| items_sold_cnt_7d | BIGINT | items_sold_cnt_7d | - | - |
| items_sold_cnt_30d | BIGINT | items_sold_cnt_30d | - | - |
| items_sold_cnt_60d | BIGINT | items_sold_cnt_60d | - | - |
| items_sold_cnt_90d | BIGINT | items_sold_cnt_90d | - | - |
| gmv_1d | DOUBLE | gmv_cnt_1d | - | - |
| gmv_7d | DOUBLE | gmv_cnt_7d | - | - |
| gmv_30d | DOUBLE | gmv_cnt_30d | - | - |
| gmv_60d | DOUBLE | gmv_cnt_60d | - | - |
| gmv_90d | DOUBLE | gmv_cnt_90d | - | - |
| gmv_usd_1d | DOUBLE | gmv_usd_cnt_1d | - | - |
| gmv_usd_7d | DOUBLE | gmv_usd_cnt_7d | - | - |
| gmv_usd_30d | DOUBLE | gmv_usd_cnt_30d | - | - |
| gmv_usd_60d | DOUBLE | gmv_usd_cnt_60d | - | - |
| gmv_usd_90d | DOUBLE | gmv_usd_cnt_90d | - | - |
| tz_type | STRING | [PARTITION] | - | - |
| grass_region | STRING | [PARTITION] | - | - |
| grass_date | DATE | [PARTITION] | - | - |
