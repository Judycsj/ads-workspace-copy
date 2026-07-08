<!-- ads-workspace-gdoc-sync: gdoc_id=1FJOHgJ9DxHuqJrwbjpvZNSAW3mFvnaqh4cSMjmwR45w gdoc_url=https://docs.google.com/document/d/1FJOHgJ9DxHuqJrwbjpvZNSAW3mFvnaqh4cSMjmwR45w/edit -->

# Columns: mp_paidads.dws_item_performance_1d__reg_s0_live

## Column Usage Notes

### 聚合说明 (Aggregation Notes)

- 所有指标列均为 **可累加 (Additive)** 字段，直接 `SUM()` 聚合即可。
- 该表粒度已到 shop_id × item_id，聚合到 shop 级别时将所有 item_* 和 org_* 列 `SUM()` 即可。
- `org_` 前缀列 = 自然流量归因（非广告），不带前缀的 `item_*` 列 = 广告 + 自然合计。
- `direct` = direct attribution（直接归因），`broad` = broad attribution（宽口径归因，包含间接）。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询 — 此表仅存储 local 时区数据)
- `grass_date`: '${grass_date}' (变量形式，按天分区)
- `grass_region`: upper('${region}') 或静态值如 'SG', 'ID', 'TH' 等

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | 店铺 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| item_imp_cnt | bigint | 商品总曝光次数 (广告+自然) | - | - |
| org_item_imp_cnt | bigint | 自然流量商品曝光次数 | - | - |
| item_click_cnt | bigint | 商品总点击次数 (广告+自然) | - | - |
| org_item_click_cnt | bigint | 自然流量商品点击次数 | - | - |
| org_direct_order_cnt | bigint | 自然流量直接归因下单数 | - | - |
| org_broad_order_cnt | bigint | 自然流量宽口径归因下单数 | - | - |
| org_direct_gmv_usd | double | 自然流量直接归因 GMV (USD) | - | - |
| org_broad_gmv_usd | double | 自然流量宽口径归因 GMV (USD) | - | - |
| item_direct_order_cnt | bigint | 商品直接归因下单数 (广告+自然) | - | - |
| item_broad_order_cnt | bigint | 商品宽口径归因下单数 (广告+自然) | - | - |
| item_direct_gmv_usd | double | 商品直接归因 GMV (USD) | - | - |
| item_broad_gmv_usd | double | 商品宽口径归因 GMV (USD) | - | - |
| tz_type | string | 时区类型 (仅 'local') [PARTITION] | - | - |
| grass_region | string | 地域 [PARTITION] | - | - |
| grass_date | date | 数据日期 [PARTITION] | - | - |
