<!-- ads-workspace-gdoc-sync: gdoc_id=1bxabepT68vBv23mIIlXaZ8lH74MiNcqnAlH7dR-0cQo gdoc_url=https://docs.google.com/document/d/1bxabepT68vBv23mIIlXaZ8lH74MiNcqnAlH7dR-0cQo/edit -->

# Columns: mp_order.dim_exchange_rate__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `exchange_rate` — 维度属性，不可 SUM。多行时用 `MAX(exchange_rate)` 或 `GROUP BY exchange_rate` 去重。

### 枚举值映射 (Value Mappings)

无 CASE-WHEN 枚举映射（表结构简单，仅含汇率维度）。

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')；部分查询包含 'AR', 'US'
- `grass_date`: 通常过滤为 `date('${BIZ_YESTERDAY}')` 或 `date('${ISO_YESTERDAY}')`；范围查询如 `BETWEEN DATE('${PREV_7D}') AND DATE('${BIZ_YESTERDAY}')`

## All Columns

Source: DataMap (from-di), 4 columns total.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | string | Identifies the region for partitioning data. | - | - |
| currency | string | The currency in which the exchange rate is denominated. | - | - |
| exchange_rate | decimal(25,10) | The exchange rate from local currency to USD. | - | - |
| grass_date | date | Calendar day | - | - |
