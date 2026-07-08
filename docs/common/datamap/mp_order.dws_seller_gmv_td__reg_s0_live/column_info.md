<!-- ads-workspace-gdoc-sync: gdoc_id=15KxJchNUVsl7Mh3_tBfGF8GHecELbeBWrKUMNmbn2n8 gdoc_url=https://docs.google.com/document/d/15KxJchNUVsl7Mh3_tBfGF8GHecELbeBWrKUMNmbn2n8/edit -->

# Columns: mp_order.dws_seller_gmv_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未在代码中发现 SUM(DISTINCT) 模式。该表为 shop_id 粒度的 to-date 汇总表，gmv_usd_td / gmv_td 本身即为累加值，不应跨日期 SUM。

### 枚举值映射 (Value Mappings)

未发现 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询)
- `grass_region`: upper('${region}') -- 标准 8+3 区 ('ID','MY','PH','SG','TH','TW','VN','BR','MX','CO','CL')
- `gmv_usd_td > 0`: 用于 seller tier 分类时过滤有 GMV 的 seller
- `gmv_td > 0`: 用于 effective shop 过滤
- `grass_date` 常见模式:
  - `date_trunc('month', '${grass_date}') - interval '1' day` -- 上月末（当月 seller tier）
  - `date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day` -- 上上月末（MoM 对比）
  - `date_trunc('month', date_trunc('month', date_trunc('month', ...) - interval '1' day) - interval '1' day) - interval '1' day` -- 3 个月前月末
  - `date'${yesterday}'` -- 昨日（effective shop 过滤）

## All Columns

> DDL 未在 Ads 代码库中找到（外部表 mp_order 所有），以下为从使用代码推断的列。运行 --source from-di 可补充完整列列表。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | Seller/shop identifier | - | - |
| gmv_usd_td | double | Cumulative GMV in USD (month-to-date) | - | - |
| gmv_td | double | Cumulative GMV in local currency (month-to-date) | - | - |
| tz_type | string | [PARTITION] Timezone type, always 'local' in Ads usage | - | - |
| grass_region | string | [PARTITION] Region code (e.g. 'ID', 'SG') | - | - |
| grass_date | date | [PARTITION] Data date | - | - |
