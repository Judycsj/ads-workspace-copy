<!-- ads-workspace-gdoc-sync: gdoc_id=1_-6JuO1TMEUv2F4ARjHyQ-pjwKuwcS5YQEw4JXNIEpY gdoc_url=https://docs.google.com/document/d/1_-6JuO1TMEUv2F4ARjHyQ-pjwKuwcS5YQEw4JXNIEpY/edit -->

# mp_paidads.dws_advertiser_active_status_td

**分层**：DWS（数据服务层 · 累计快照型）
**主键**：`shop_id`, `user_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日增量覆写（INSERT OVERWRITE，按分区滚动追加）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表是广告主（卖家）**活跃状态的全量累计快照表（TD，To-Date）**，记录每个店铺（`shop_id`）及其所属卖家（`user_id`）截至当日的**最后一次广告活跃日期**（`last_active_date`）。每个自然日的分区保存了该日期为止所有历史活跃广告主的最新活跃时间戳，数据按地区与时区参数化调度，覆盖多个市场。

典型使用场景包括：判断广告主是否为"近期活跃用户"（如近 7 天 / 30 天内有广告活跃行为）、计算广告主活跃留存率、识别流失风险账户，以及为广告智能运营策略（如召回、激励）提供活跃状态基础标签。

作为 TD 型累计快照，本表通过每日与前一日历史数据进行 UNION 合并并取最大值的方式，避免了对全量历史明细数据的重复扫描，是构建广告主生命周期分析和活跃度监控看板的核心基础表。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。各地区按本地时区参数化调度，当前数据写入值为 `'local'`。查询时**必须指定**此字段以避免全表扫描。 |
| `grass_region` | string | 国家/地区分区，如 `'MX'`、`'TH'` 等，存储为大写形式。查询时**必须指定**此字段。 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`，表示当前快照所对应的业务日期。查询时**必须指定**此字段。 |

### 维度：主键与广告主标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，唯一标识一个广告主店铺，与 `user_id` 联合构成本表主键。 |
| `user_id` | bigint | 卖家 ID（Seller ID），与 `shop_id` 联合构成本表主键。 |

### 指标：广告主活跃状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `last_active_date` | string | 截至当前分区日期（`grass_date`），该广告主（`shop_id` + `user_id`）最近一次产生广告活跃行为的日期，格式 `YYYY-MM-DD`。⚠️ 为累计取 MAX 的派生字段，不可直接 SUM；如需统计活跃间隔天数，应用 `datediff(grass_date, last_active_date)` 计算；跨分区比较时须确保取同一 `grass_date` 分区以保证口径一致。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，缺少任意一个将导致全分区扫描，引发严重性能问题或数据重复：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `'local'` 分区，漏写将扫描所有 tz_type 分区 |
| `grass_region` | `grass_region = '<目标地区>'`，如 `'MX'` | 指定所需地区，大写形式 |
| `grass_date` | `grass_date = '<目标日期>'` | TD 快照表每个日期分区均存储全量历史最新状态，取最新日期分区即可获得截至今日的活跃状态 |

> ⚠️ **漏写 `grass_date` 的后果**：本表为 TD 累计快照，每个日期分区均包含全量广告主数据，若不指定日期将导致同一 `shop_id` + `user_id` 组合在结果中出现多行（每天一行），造成严重数据膨胀。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|------|------|----------|
| `last_active_date` | 累计快照的派生字段（历史 MAX），对多行直接聚合无业务意义 | 用 `datediff(current_date, last_active_date)` 判断距今活跃天数；统计"N 天内活跃广告主数"应用 `COUNT(DISTINCT shop_id) WHERE datediff(grass_date, last_active_date) <= N` |

### 时效性说明

本表为 **TD（累计至今）快照**，每个 `grass_date` 分区保存截至该日的最新活跃状态：

- 若需"当前最新"活跃状态，取 **最新已产出的 `grass_date` 分区**（通常为 T-1 日，视调度完成时间而定）。
- 不建议对多个 `grass_date` 分区做 UNION 后再聚合，历史分区的 `last_active_date` 已被更新分区包含，重复使用会引入脏数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_activeness_1d__${region}_s0_live` | 每日广告活跃明细表（1D 粒度），提供当日有活跃行为的 `shop_id` + `user_id` 及对应 `grass_date`，用于获取当天增量活跃记录 |
| `mp_paidads.dws_advertiser_active_status_td__${region}_s0_live` | 本表自身前一日快照（T-1 分区），用于与当日增量数据合并，延续历史累计的最后活跃日期 |

---

## ETL 逻辑摘要

### 数据流

```
dws_advertise_activeness_1d__${region}_s0_live
  (grass_date = '${grass_date}' · 当日增量)
          │
          │  SELECT shop_id, user_id
          │         MAX(grass_date) AS last_active_date
          │  GROUP BY shop_id, user_id
          ▼
     ┌─────────────┐
     │  CTE / 子查询 │   UNION ALL
     │  当日活跃快照  │◄──────────────────────────────────┐
     └─────────────┘                                   │
                                                       │
dws_advertiser_active_status_td__${region}_s0_live     │
  (grass_date = '${day_before_grass_date}' · T-1 历史快照) ─┘
          │
          │  UNION ALL 合并后
          │  GROUP BY shop_id, user_id
          │  MAX(last_active_date)
          ▼
dws_advertiser_active_status_td__${region}_s0_live
  (partition: tz_type='local', grass_region=upper('${region}'), grass_date='${grass_date}')
  ✅ INSERT OVERWRITE 写入当日分区
```

### 注意事项

1. **自引用滚动合并**：ETL 逻辑采用"当日增量 UNION ALL 前日全量快照"再取 MAX 的经典 TD 快照模式，每次仅读取 T-1 分区而非全量历史，计算效率高，但依赖 T-1 分区数据必须已完整产出；若 T-1 分区缺失或补数，需重跑当日及其后所有日期分区。

2. **参数化调度覆盖多地区**：SQL 中的 `${region}`、`${grass_date}`、`${day_before_grass_date}` 均为调度模板变量，各地区独立调度实例运行，文档中出现的具体地区代码（如 `MX`）仅为示例，表实际覆盖所有已上线地区。

3. **`tz_type` 固定写入 `'local'`**：当前 ETL 硬编码分区为 `tz_type='local'`，查询时须指定此值；若未来扩展其他时区类型（如 `'utc'`），过滤条件需相应调整。

4. **`last_active_date` 类型为 string**：字段虽存储日期值，类型为 `string` 而非 `date`，进行日期运算时需显式转换，如 `datediff(grass_date, cast(last_active_date as date))`，避免隐式转换错误。

5. **分区维护**：ETL 末尾通过 `ALTER TABLE ... ADD IF NOT EXISTS PARTITION` 确保分区注册，正常调度下无需手动操作，但在补数场景下需确认分区已正确注册。

---

*文档生成时间：2026-04-22*