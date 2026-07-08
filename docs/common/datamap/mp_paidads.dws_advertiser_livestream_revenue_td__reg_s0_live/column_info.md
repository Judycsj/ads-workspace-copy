<!-- ads-workspace-gdoc-sync: gdoc_id=1PpuySYyoUZ9V86L_fQckDGjKnl4MGOQFTH2p-aUz4T8 gdoc_url=https://docs.google.com/document/d/1PpuySYyoUZ9V86L_fQckDGjKnl4MGOQFTH2p-aUz4T8/edit -->

# Columns: mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live

> **备注**: 未从代码库找到 DDL 定义。以下列信息从 SQL 使用模式推断，类型为推断值。运行 `--source from-di` 可获取完整列列表和 DataMap 元信息。

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 所有查询均使用 `'local'`
- `grass_region`: 按单区域过滤，使用 `upper('${region}')` 模式
- `grass_date`: 关键过滤条件，支持多种日期间距：
  - `DATE('${grass_date}')` — 当日快照（约50%查询）
  - `date_sub(DATE('${grass_date}'), 1)` — T-1 快照（用于计算 365 天消耗）
  - `date_sub(DATE('${grass_date}'), 366)` — T-366 快照（与 T-1 做差）
  - `date_sub(TRUNC(DATE('${grass_date}'),'MM'), 1)` — 上月末快照（计算上月消耗）
  - `date_sub(ADD_MONTHS(TRUNC('${grass_date}','MM'), -1), 1)` — 上上月末快照
  - `date_sub(ADD_MONTHS(TRUNC('${grass_date}','MM'), -12), 1)` — 12 个月前月末快照

### 典型使用模式

- **累计差值计算**: 该表存储的是累计（TD）值，计算时间段内消耗需用两个不同日期的快照做差值。例如：
  - `今日累计 - T-366 累计 = 过去365天消耗`
  - `当月累计 = T日累计 - 上月末累计`
  - `上月累计 = 上月末累计 - 上上月末累计`

- **自连接模式**: 常见于同一查询中对该表进行多次引用（T日、T-1、T-366、T-上月等），通过 JOIN on shop_id 求差值。

## All Columns

> 以下列从代码库 SQL 实际使用中推断。列类型为推测值，运行 `--source from-di` 后可补充完整列列表及类型。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | 店铺/广告主 ID | - | - |
| grass_region | string | 区域 (VN/TW/TH/SG/PH/MY/ID) | - | - |
| grass_date | date | 分区日期 | - | - |
| tz_type | string | 时区类型 (固定 'local') | - | - |
| total_expenditure_amt_usd_td | double | 累计总消耗 USD (To Date) | - | - |
| streamer_first_live_ads_date | string | 首次直播广告日期 | - | - |
| streamer_last_live_ads_date | string | 最近一次直播广告日期 | - | - |
