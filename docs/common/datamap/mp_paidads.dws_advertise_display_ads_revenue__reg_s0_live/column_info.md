<!-- ads-workspace-gdoc-sync: gdoc_id=1J3pVhSUhGLKQAlEGpxhq5IXSX1FHrTx3FN21pltRRiU gdoc_url=https://docs.google.com/document/d/1J3pVhSUhGLKQAlEGpxhq5IXSX1FHrTx3FN21pltRRiU/edit -->

# Columns: mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `estimate_cpm_local` / `estimate_cpm_usd` -- 从上游 `MAX(cpm)` 聚合得到，跨 ads 或维度聚合时不能直接 SUM，应使用 AVG 或加权平均。如需按维度汇总 CPM，建议用 `expense_amt_usd / impression_cnt * 1000` 自行计算 eCPM。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 9 | Display Ads (表中唯一值) |
| tz_type | 'regional' | 亚洲地区 (UTC+8 时区基准) |
| tz_type | 'local' | 本地时区 (BR/ID/MX 使用, 对应本地时区) |

### 常见 WHERE 值 (Common Filter Values)

- `placement`: 9 (Display Ads) -- 表中固定过滤条件
- `tz_type`: 'regional' (~60% 场景) / 'local' (BR/ID/MX 本地时区)
- `grass_region`: 'BR','ID','MX','MY','PH','SG','TH','TW','VN' (覆盖全部 9 个地区)
- `substr(budget_start_datetime,1,10) <= '${grass_date}'` -- 过滤在预算起止时间内的广告
- `substr(budget_end_datetime,1,10) >= '${grass_date}'`

### 金额精度说明

- `estimate_cpm_local`: 存储值 = 原始 CPM / 100,000，实际运算需除回
- `estimate_cpm_usd`: 存储值 = 原始 CPM / 100,000 / exchange_rate
- `expense_amt_local`: 存储值 = CPM * impressions / 100,000，已做精度缩放
- `expense_amt_usd`: 存储值 = expense_amt_local / exchange_rate
- 下游读取时常见 `/1000.00` 转换（如 `SUM(expense_amt_usd/1000.00)`），因 2022-10-26 前后精度缩放不同：
  - 2022-10-26 之前: `expense_amt_usd/100000.00/1000.00`
  - 2022-10-26 之后: `expense_amt_usd/1000.00`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | ads_id | - | - |
| entrance | int | - | - | - |
| pricing_type | int | - | - | - |
| placement | int | - | - | - |
| shop_id | bigint | shop_id | - | - |
| budget_start_datetime | string | budget_start_date | - | - |
| budget_end_datetime | string | budget_end_date | - | - |
| impression_cnt | bigint | impression_cnt | - | - |
| estimate_cpm_local | decimal(38,10) | estimate_cpm_local | - | - |
| estimate_cpm_usd | decimal(38,10) | estimate_cpm_usd | - | - |
| expense_amt_local | decimal(38,10) | expense_amt_local | - | - |
| expense_amt_usd | decimal(38,10) | expense_amt_usd | - | - |
| click_cnt | bigint | - | - | - |
| campaign_id | bigint | - | - | - |
| tz_type | string [PARTITION] | - | - | - |
| grass_region | string [PARTITION] | - | - | - |
| grass_date | date [PARTITION] | date | - | - |
