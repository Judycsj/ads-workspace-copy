<!-- ads-workspace-gdoc-sync: gdoc_id=1k1oCDZBpLg37KbuFwyBU40tSS687r04At4sbjJWhvLw gdoc_url=https://docs.google.com/document/d/1k1oCDZBpLg37KbuFwyBU40tSS687r04At4sbjJWhvLw/edit -->

# mp_paidads.dwd_advertise_new_item_boost_event_th

**分层：** DWD（数据明细层）
**主键：** `ads_id` + `broad_order` + `timestamp`
**分区：** `grass_region` / `grass_date` / `h`
**更新频率：** 每小时调度（按业务时间 BIZ_TIME 滚动写入）
**引用频次：** 2 次

---

## 业务描述

本表记录付费广告平台中 **新品加速（Item Boost）** 广告的曝光/点击等原始事件明细，定价类型固定为 `pricing_type = 13`（新品加速计费类型），每条记录代表一次有效的广告事件（`broad_order > 0` 且 `timestamp > 0`）。

表的核心用途是为下游广告计费、效果归因及投放监控提供经过初步清洗的事件级原子数据，支撑 Item Boost 产品线的报表统计与异常排查。由于数据以小时粒度分区存储，下游可按需快速圈定特定时段的事件流水，适合高频、低延迟的广告效果分析场景。

ETL 采用**滚动合并**策略：每次调度将前一小时的新增事件与前两小时的已有分区数据做 `UNION ALL` 后覆盖写入，起到对迟到数据进行一次补偿修正的效果。各地区按本地时区参数化调度，覆盖所有上线地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识（如 `TH`、`ID`、`VN` 等），各地区通过调度参数 `${region}` 写入对应分区 |
| `grass_date` | date | 业务日期（本地时区），由调度参数 `bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1h')` 计算得出，即当前调度时刻的前一小时所在日期 |
| `h` | int | 业务小时（0–23，本地时区），由 `bizTimeFormatter(BIZ_TIME, 'H', '-1h')` 计算得出，即当前调度时刻的前一小时 ⚠️ 查询时务必同时指定 `grass_date` + `h`，单独过滤 `grass_date` 仍会扫描当天所有小时分区 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告计划 ID，唯一标识一个 Item Boost 广告投放单元 |
| `broad_order` | bigint | 广告事件订单号（宽口径流水标识），来源数据已过滤 `broad_order > 0`，保证每条记录均有有效订单号 |
| `timestamp` | bigint | 事件发生的时间戳（Unix 毫秒或秒，以上游 ODS 日志为准），来源数据已过滤 `timestamp > 0` ⚠️ 为原始日志时间戳，时间单位需结合上游 ODS 字段口径确认，不可直接与 `grass_date`/`h` 做时间比较而不转换单位 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，造成资源浪费甚至查询超时：

```sql
WHERE grass_region = '<目标地区>'   -- 如 'TH'
  AND grass_date  = DATE '<目标日期>'  -- 如 DATE '2026-04-21'
  AND h           = <目标小时>         -- 如 10
```

- 遗漏 `grass_region`：扫描所有地区分区，数据量成倍放大。
- 遗漏 `grass_date`：扫描历史所有日期，I/O 开销极大。
- 遗漏 `h`：扫描当天全部 24 个小时分区，对小时级分析场景影响显著。

如需按日汇总，应在 `WHERE` 中保留 `grass_region` + `grass_date`，并在 `SELECT` 层对 `h` 做 `GROUP BY` 或不选取，**不可省略分区过滤**。

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确处理方式 |
|------|------|-------------|
| `timestamp` | 为事件时间戳，直接 SUM 无业务意义 | 仅用于排序、去重、时间窗口计算；如需时间范围过滤，需先转换为日期时间类型再比较 |
| `broad_order` | 为事件流水号，直接 SUM 无业务意义 | 用于 `COUNT(DISTINCT broad_order)` 统计去重订单数，或与其他表 JOIN 关联 |

### 时效性说明

本表采用**滚动两小时合并**写入策略：

- **当前小时分区（h = N）**：由本次调度将 ODS 前一小时数据（h = N）与本表前两小时分区（h = N-1）`UNION ALL` 后覆盖写入。
- **h = N-1 分区**已在上一次调度中完成修正，数据相对稳定。
- 若需分析**最新一小时**数据，请取最新已完成调度的 `h` 分区，并注意该分区可能仍在当次调度窗口内被覆盖更新。
- 建议分析时以 **h = BIZ_HOUR - 2** 及更早的分区作为"稳定数据"，避免读取正在写入的最新分区造成数据不完整。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 广告日志原始数据（ODS 层），按小时分区；本表从中过滤 `pricing_type = 13`（新品加速）、`broad_order > 0`、`timestamp > 0` 的有效事件记录 |
| `mp_paidads.dwd_advertise_new_item_boost_event_th__reg_s0_live`（自身） | 前两小时已写入分区；与 ODS 新增数据合并，实现迟到数据的一次补偿修正 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_ads_report_hi__reg_s0_live
  │  过滤条件：
  │    grass_date = BIZ_DATE(-1h)
  │    h          = BIZ_HOUR(-1h)
  │    pricing_type = 13
  │    broad_order  > 0
  │    timestamp    > 0
  │
  │  (新增事件)
  ▼
  UNION ALL
  │
mp_paidads.dwd_advertise_new_item_boost_event_th（自身回读）
  │  过滤条件：
  │    grass_date = BIZ_DATE(-2h)
  │    h          = BIZ_HOUR(-2h)
  │
  │  (前两小时已有数据，补偿迟到事件)
  ▼
  INSERT OVERWRITE
  │  REPARTITION(10)
  │  分区写入：grass_region / grass_date / h
  ▼
mp_paidads.dwd_advertise_new_item_boost_event_th（目标分区）
```

> **计算引擎：** Spark SQL（`/*+ REPARTITION(10) */` hint 指定 10 个输出分区）
> **写入方式：** `INSERT OVERWRITE PARTITION`（按 `grass_region`, `grass_date`, `h` 动态覆盖写入）

### 关键 CTE 说明

本 ETL 无显式 CTE，逻辑通过内联子查询（`UNION ALL`）实现，无需单独说明。

### 注意事项

1. **自身回读的幂等性风险**：ETL 每次将自身 `h-2` 分区数据重新读出并合并写入 `h-1` 分区，若调度出现重跑，`h-2` 分区需保证已完整写入，否则可能丢失数据。
2. **`pricing_type = 13` 硬过滤**：本表仅包含新品加速（Item Boost）计费类型的事件，其他计费类型数据不在本表范围内，下游不应将本表与全品类广告事件表直接比较总量。
3. **`broad_order > 0` 与 `timestamp > 0` 的含义**：上游 ODS 日志中存在 `broad_order = 0` 或 `timestamp = 0` 的无效日志行，本表在 ETL 阶段已过滤，下游无需重复过滤，但需了解本表数据量小于 ODS 原始量。
4. **分区时间与事件时间的差异**：`grass_date` + `h` 为调度业务时间，`timestamp` 为事件实际发生时间，两者可能因迟到数据而不完全对齐，时间精确分析时应以 `timestamp` 为准而非分区时间。
5. **各地区独立调度**：表名后缀 `__reg_s0_live` 表明通过 `${region}`、`${timezone}` 参数化覆盖所有地区，各地区按本地时区独立调度，不同地区的同一 `grass_date`/`h` 分区对应的 UTC 时间不同。

---

*文档生成时间：2026-04-22*