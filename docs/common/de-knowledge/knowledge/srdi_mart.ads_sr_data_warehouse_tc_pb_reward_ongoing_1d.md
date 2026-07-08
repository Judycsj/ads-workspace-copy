<!-- ads-workspace-gdoc-sync: gdoc_id=1Zkw2HTpWZGjusQ_vkwJBX13ken3i1A6LiDQ5fSFSVMk gdoc_url=https://docs.google.com/document/d/1Zkw2HTpWZGjusQ_vkwJBX13ken3i1A6LiDQ5fSFSVMk/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_reward_ongoing_1d

**分层：** ADS（应用数据层）
**主键：** `shop_id` + `model_id`（分区内唯一，通过 `row_number()` 去重保证）
**分区：** `grass_region`（区域）/ `local_date`（业务日期）/ `local_hour`（业务小时）
**更新频率：** 每小时覆盖写（INSERT OVERWRITE，按小时分区）
**访问频次：** 7213 次

---

## 业务描述

本表用于记录**搜索推荐（SR）数据仓库场景下，TC（流量控制）竞价奖励（PB Reward）正在进行中（Ongoing）**的最新模型状态快照，粒度为**店铺 × 模型 × 小时**。

核心业务场景：
- 追踪各店铺当前正在参与竞价奖励活动的模型的最新赢单状态及时间戳；
- 监控各店铺模型的曝光量、订单量及 GMV 等核心效果指标；
- 供下游报表、运营看板或实时决策系统查询当前进行中的奖励活动效果。

适合回答的问题举例：
- 某区域某小时内，哪些店铺的哪些模型正在参与竞价奖励？当前状态如何？
- 各店铺正在进行的竞价奖励模型的最新曝光量、订单量和 GMV 是多少？
- 某模型最近一次赢单是什么时候发生的？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 业务区域（如国家/地区站点），ETL 参数化注入，用于数据隔离 |
| `local_date` | date | 业务本地日期，ETL 参数化注入 |
| `local_hour` | int | 业务本地小时（0–23），ETL 参数化注入，标识数据所属小时分区 |

### 维度：店铺与模型标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，标识参与竞价奖励的商家 |
| `model_id` | bigint | 模型 ID，标识该店铺参与竞价奖励所用的算法/竞价模型 |
| `model_status` | string | 模型当前状态，描述该竞价奖励模型的运行状态（如 ongoing、paused 等） |
| `latest_winner_start_timestamp` | bigint | 最新赢单开始时间戳（Unix 毫秒或秒级），用于标识同一 `shop_id + model_id` 组合下最近一次赢单记录，ETL 以此字段降序取 `rn=1` 确保唯一性 |

### 指标：曝光与转化效果

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数，该店铺模型在当前小时内的广告/推荐曝光总量 |
| `order_cnt` | bigint | 订单数，该店铺模型在当前小时内带来的订单总量 |
| `gmv` | double | 成交总金额（Gross Merchandise Value），该店铺模型在当前小时内的 GMV，单位与业务系统一致 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须显式指定三个分区字段**，否则将触发全表扫描，严重影响查询性能：
  ```sql
  WHERE grass_region = '<区域>'
    AND local_date = '<日期>'
    AND local_hour = <小时>
  ```
- 若需查询某日全天数据，需枚举或范围过滤 `local_hour IN (0,1,...,23)`，注意各小时分区为独立快照，不可直接跨小时聚合（见下方注意事项）。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `gmv` | 为预聚合结果，跨小时 SUM 存在重复计算风险；如需日汇总请回溯上游 DWS 层 |
| `imp_cnt` | 同上，跨小时叠加需确认业务口径是否允许累加 |
| `order_cnt` | 同上，跨小时叠加需确认业务口径是否允许累加 |
| `latest_winner_start_timestamp` | 时间戳维度字段，不具备聚合意义，不可 SUM/AVG |

### 时效性说明

- 本表为**小时级覆盖写快照**，每小时产出一个分区，覆盖当前小时的"进行中"状态；
- 上游表名含 `_nd` 后缀（`dws_sr_data_warehouse_tc_pb_reward_ongoing_hour_level_nd`），表示上游维持近 N 天滚动窗口数据，本表每次仅取当前分区对应时间点的最新赢单记录；
- 数据反映的是**截至当前小时最新赢单（latest winner）**的状态快照，不是全历史累计；
- 若上游 ETL 延迟，本小时分区数据可能存在缺失或滞后，使用前请确认分区已产出。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_ongoing_hour_level_nd` | 提供 TC 竞价奖励 Ongoing 状态的小时级明细数据，包含各 `shop_id + model_id` 的多条历史赢单记录，本表从中取最新赢单记录写入 ADS 层 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_reward_ongoing_hour_level_nd
    （小时级 N 天滚动明细，按 grass_region / local_date / local_hour 过滤）
        │
        ▼  row_number() OVER (PARTITION BY shop_id, model_id
        │                      ORDER BY latest_winner_start_timestamp DESC)
        │  取 rn = 1（每 shop_id + model_id 保留最新赢单记录）
        │
        ▼
srdi_mart.ads_sr_data_warehouse_tc_pb_reward_ongoing_1d
    （INSERT OVERWRITE，按 grass_region / local_date / local_hour 分区写入）
```

### 关键步骤

1. **分区过滤**：从上游 DWS 表中按 `grass_region`、`local_date`、`local_hour` 三个参数过滤当前小时分区数据。
2. **去重排序（Window Function）**：对过滤后数据按 `(shop_id, model_id)` 分组，以 `latest_winner_start_timestamp DESC` 排序，通过 `row_number()` 标记行号。
3. **取最新记录**：外层 `WHERE rn = 1`，保证每个 `shop_id + model_id` 组合仅保留最新赢单的一行记录。
4. **覆盖写入目标分区**：`INSERT OVERWRITE` 将去重后结果写入目标表对应的 `(grass_region, local_date, local_hour)` 分区。

### 注意事项

- **单 writer**：本表仅有一个 ETL 文件写入，不存在 multi-writer 并发冲突风险。
- **覆盖写语义**：每次调度均以 `INSERT OVERWRITE` 方式写入，同一分区数据会被完整替换，具备幂等性，支持重跑。
- **去重依赖时间戳**：若上游数据中 `latest_winner_start_timestamp` 存在相同值（并列最新），`row_number()` 结果具有不确定性，最终保留哪一行取决于执行计划，需关注上游数据质量。
- **分区参数化**：`grass_region`、`local_date`、`local_hour` 均为运行时外部参数注入，调度时需确保参数传入正确，否则可能导致分区写入错位。
- **上游 `_nd` 窗口**：上游 DWS 表维护近 N 天数据，若跨天查询或回刷历史分区，需确认上游对应日期的数据仍在 N 天窗口内，避免数据缺失。

---

*文档生成时间：2026-05-17*