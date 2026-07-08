<!-- ads-workspace-gdoc-sync: gdoc_id=1pbKJXMwJKV3K0r5JHl9HxxOUBqv9hxK-NWJpr0S9cMQ gdoc_url=https://docs.google.com/document/d/1pbKJXMwJKV3K0r5JHl9HxxOUBqv9hxK-NWJpr0S9cMQ/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_reward_ongoing_hour_level_nd

**分层：** DWS（数据汇总层）
**主键：** `shop_id` + `model_id` + `latest_winner_start_timestamp` + `grass_region` + `local_date` + `local_hour`
**分区：** `grass_region` / `local_date` / `local_hour`
**更新频率：** 小时级（每小时覆盖写入当前分区）
**引用频次 / 访问频次：** 14,375

---

## 业务描述

本表面向搜推（SR）数仓的 **TC 推广宝（PB）奖励模型（Reward Model）** 场景，以小时为粒度，持续累计并保留当前正在进行中（Ongoing）的各奖励模型的曝光、订单及 GMV 数据。

**核心业务场景：**

- 追踪每个店铺（`shop_id`）下每个奖励模型（`model_id`）自本轮奖励开始（`latest_winner_start_timestamp`）以来的累计效果表现。
- 每小时合并"历史截止上一小时"的累计数据与"当前小时"的增量数据，形成滚动累加的全量窗口视图。
- 支持实时监控处于活跃状态（`model_status` 为进行中）的奖励模型的周期内累计效果。

**适合回答的问题：**

- 截至当前小时，某店铺的某奖励模型自本轮奖励开始以来累计曝光 / 成单 / GMV 是多少？
- 当前小时各奖励模型的整体效果趋势如何？
- 在特定区域、特定日期、特定小时下，哪些模型仍处于活跃状态？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 ID、MY、TH 等），用于多区域分区隔离 |
| `local_date` | date | 本地日期，格式 `yyyy-MM-dd` |
| `local_hour` | int | 本地小时（0–23），与 `local_date` 共同定位数据时间分区 |

### 维度：店铺与奖励模型

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，标识归属商家 |
| `model_id` | bigint | 奖励模型 ID，标识具体的推广宝奖励策略 |
| `model_status` | string | 模型状态，来源为当前小时与历史数据合并后取 `MAX`；上游过滤范围为状态 1（进行中）和 2（待完成/其他活跃态） |
| `latest_winner_start_timestamp` | bigint | 本轮奖励的开始时间戳（Unix 毫秒级），对应上游字段 `full_start_timestamp`；用于区分同一模型不同奖励周期的累计窗口 |

### 指标：累计效果

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 累计曝光次数，为历史截止上一小时 + 当前小时曝光量之和 |
| `order_cnt` | bigint | 累计成单数，为历史截止上一小时 + 当前小时订单量之和 |
| `gmv` | double | 累计 GMV（成交金额），为历史截止上一小时 + 当前小时 GMV 之和 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：该表按区域分区，跨区 UNION 查询需显式列举所有目标区域。
- **必须指定 `local_date` 和 `local_hour`**：每小时覆盖写入，未限定分区时将全量扫描所有历史小时分区，导致严重性能问题。建议同时指定三个分区字段。
- 如需取当日最新数据，应先确认当前最大 `local_hour` 再过滤，避免读到未完成写入的分区。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt` | 本表为累计滚动值（历史 + 当前小时），**跨小时 SUM 会重复计算**，仅可取某一时间点分区的值 |
| `order_cnt` | 同上，跨小时 SUM 存在重复累计 |
| `gmv` | 同上，跨小时 SUM 存在重复累计 |
| `model_status` | 由 `MAX` 聚合得出，属于派生状态字段，不具备加法意义 |

> ⚠️ 本表的 `imp_cnt`、`order_cnt`、`gmv` 均为**自 `latest_winner_start_timestamp` 起的本轮奖励周期累计值**，而非当前小时增量。如需增量值，需用相邻两小时分区数据做差。

### 时效性说明

- 本表为**小时级准实时表**（`hour_level`），每小时触发一次 `INSERT OVERWRITE` 覆盖当前 `(grass_region, local_date, local_hour)` 分区。
- 后缀 `_nd` 表示近 N 天滚动窗口：ETL 查询上游时限定 `local_date between date_sub(${local_date}, 6) and ${local_date}`（近 7 天），超出窗口的历史分区不参与更新，但物理分区仍保留。
- 数据存在一定延迟，当前小时分区的最终数据需等待 ETL 任务执行完成后才可靠。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_ongoing_hour_level_nd`（自身） | 读取上一有效小时分区的历史累计数据（`before_data`），实现滚动累加 |
| `srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini` | 读取当前小时（`local_date` + `local_hour`）的增量明细数据（`current`），提供曝光、订单、GMV 原始度量 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini
  （当前小时增量，model_status IN (1,2)）
          │
          ▼
   current_view（按 shop_id, model_id, model_status, full_start_timestamp 聚合）
          │
          ▼
  current_sum_view（统一列名为 latest_winner_start_timestamp，标记 source='current'）
          │
          ├──────────────────────────────────────────────────────────┐
          │                                                          │
srdi_mart.dws_sr_data_warehouse_tc_pb_reward_ongoing_hour_level_nd   │
  （自身：上一有效小时分区，近7天内）                               │
          │                                                          │
          ▼                                                          │
   before_data_view                                                  │
          │                                                          │
          ▼                                                          │
  before_sum_view（按 shop_id, model_id, model_status,               │
                  latest_winner_start_timestamp 聚合，source='before'）
          │                                                          │
          └──────────────────── UNION ALL ────────────────────────── ┘
                                    │
                                    ▼
          GROUP BY shop_id, model_id, latest_winner_start_timestamp
          （MAX(model_status)，SUM 各指标）
                                    │
                                    ▼
          INSERT OVERWRITE 目标表当前分区
```

### 关键步骤

| 步骤 | Spark SQL 动作 | 说明 |
|---|---|---|
| 1 | `SET last_partition_*` | 计算当前区域在近 7 天内、早于当前小时的最近一个有效分区（格式 `yyyyMMdd_HH`），用于后续回溯读取 |
| 2 | `CREATE TEMPORARY VIEW before_data_*` | 从目标表自身读取上一有效小时的全量分区数据，形成历史基线视图 |
| 3 | `CREATE TEMPORARY VIEW current_*` | 从上游明细表读取当前小时、`model_status IN (1,2)` 的数据，按维度聚合为小时级增量 |
| 4 | `CREATE TEMPORARY VIEW before_sum_*` | 对历史基线视图按维度聚合，标记 `source='before'` |
| 5 | `CREATE TEMPORARY VIEW current_sum_*` | 对当前小时增量视图按维度聚合，将 `full_start_timestamp` 重命名为 `latest_winner_start_timestamp`，标记 `source='current'` |
| 6 | `INSERT OVERWRITE` 目标分区 | 将 `before_sum` 与 `current_sum` UNION ALL 后，按 `(shop_id, model_id, latest_winner_start_timestamp)` 分组，取 `MAX(model_status)`、`SUM` 各指标，写入当前 `(grass_region, local_date, local_hour)` 分区 |

### 注意事项

- **滚动累计而非增量写入**：ETL 每小时将"历史累计 + 当前小时增量"合并后覆盖写入，若历史分区数据质量有问题（如上一小时缺分区），`last_partition` 会回溯更早分区，可能导致当前小时数据缺失当期增量。
- **`last_partition` 为空风险**：若近 7 天内无任何历史分区（如首次写入或连续缺数），`before_data` 视图将为空，最终结果仅含当前小时增量，历史累计归零。
- **`model_status` 的过滤与聚合差异**：上游过滤 `model_status IN (1, 2)`（整型），目标表 `model_status` 字段类型为 `string`，最终写入值为 UNION ALL 后 `MAX(model_status)` 的结果，需注意类型隐式转换。
- **ETL SQL 中存在注释掉的 `ROW_NUMBER` 逻辑**：原设计曾尝试用 `row_number()` 去重优先取 `current` 数据，现改为 `SUM` 累加，两种数据源之间不做去重，直接叠加；业务侧需理解同一 `(shop_id, model_id, latest_winner_start_timestamp)` 在 UNION ALL 后会出现来自 `before` 和 `current` 的两条记录，最终通过 `GROUP BY + SUM` 合并。
- **单文件单写入**：`multi_writer = false`，无并发写入冲突风险。

---

*文档生成时间：2026-05-17*