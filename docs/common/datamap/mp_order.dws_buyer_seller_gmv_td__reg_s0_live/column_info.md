<!-- ads-workspace-gdoc-sync: gdoc_id=1PlvZm5aVCs5SWpF_QBdjTherPOuPbhRmo4G81vcbIBw gdoc_url=https://docs.google.com/document/d/1PlvZm5aVCs5SWpF_QBdjTherPOuPbhRmo4G81vcbIBw/edit -->

# Columns: mp_order.dws_buyer_seller_gmv_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未在代码中发现 SUM(DISTINCT) 模式。该表为 buyer_id x shop_id 粒度的 to-date 汇总表，下游查询仅用于判断是否有过订单记录 (`placed_order_cnt_td > 0`)，不做跨 buyer 的 SUM 聚合。

### 枚举值映射 (Value Mappings)

未发现 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询)
- `grass_region`: upper('${region}') -- 标准 8+3 区 ('ID','MY','PH','SG','TH','TW','VN','BR','MX','CO','CL')
- `placed_order_cnt_td > 0`: 100% 查询，用于过滤有实际下单记录的 buyer-shop 对
- `grass_date`: date'${yesterday}' (100% 查询)，固定取昨日分区

## All Columns

> DDL 未在 Ads 代码库中找到（外部表 mp_order 所有），以下为从使用代码推断的列。运行 --source from-di 可补充完整列列表。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| buyer_id | bigint | Buyer user identifier (downstream aliased as user_id) | - | - |
| shop_id | bigint | Shop/seller identifier | - | - |
| placed_order_cnt_td | bigint | Cumulative placed order count for this buyer-shop pair (to-date) | - | - |
| tz_type | string | [PARTITION] Timezone type, always 'local' in Ads usage | - | - |
| grass_region | string | [PARTITION] Region code (e.g. 'ID', 'SG') | - | - |
| grass_date | date | [PARTITION] Data date | - | - |
