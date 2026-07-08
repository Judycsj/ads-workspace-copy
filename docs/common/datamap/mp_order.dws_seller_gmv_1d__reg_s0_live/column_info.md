<!-- ads-workspace-gdoc-sync: gdoc_id=1i1jIknbFI0T1jKbulPxn3MMnJxMlbBR9eUW_ASUtZ_g gdoc_url=https://docs.google.com/document/d/1i1jIknbFI0T1jKbulPxn3MMnJxMlbBR9eUW_ASUtZ_g/edit -->

# Columns: mp_order.dws_seller_gmv_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未从代码库中发现 SUM(DISTINCT) 模式，暂无已确认的非累加字段。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | regional | 标准化地区时区 (最常用, ~70% 查询) |
| tz_type | local | 本地时区 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'regional' (Take Rate / OKR 分析) / 'local' (dim_shop_info 日常调度, 数据分析探索)
- `grass_region`: 'ID', 'SG', 'MY', 'PH', 'TH', 'TW', 'VN', 'BR', 'MX', 'CO', 'CL' (各地区独立调度)
- `grass_date`: 通常使用 BETWEEN 日期范围过滤，常见为近 90 天滚动窗口

## All Columns

以下列为 from-code 从 SQL 使用中推理，描述和查询频率待 from-di 补充。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | 商家/店铺 ID | - | - |
| gmv_1d | double | 当日 GMV (本地币种) | - | - |
| gmv_usd_1d | double | 当日 GMV (USD) | - | - |
| placed_order_cnt_1d | bigint | 当日下单数 | - | - |
| placed_buyer_cnt_1d | bigint | 当日下单买家数 | - | - |
| placed_item_cnt_1d | bigint | 当日下单商品数 | - | - |
| tz_type | string [PARTITION] | 时区类型 (regional/local) | - | - |
| grass_region | string [PARTITION] | 地区/国家代码 | - | - |
| grass_date | DATE [PARTITION] | 数据日期 | - | - |
