<!-- ads-workspace-gdoc-sync: gdoc_id=1IaR4ChsDMu8PjfBUBMfeHSKimYUmptCN-PQk7P9sGcU gdoc_url=https://docs.google.com/document/d/1IaR4ChsDMu8PjfBUBMfeHSKimYUmptCN-PQk7P9sGcU/edit -->

# srdi_mart.dwd_sr_data_warehouse_tc_pb_winner_model_history

**分层：** DWD（数据明细层）
**主键：** `item_id` + `shop_id` + `cspu_id` + `model_id` + `grass_region` + `regional_date`（联合唯一标识一条竞价模型记录）
**分区：** `grass_region`（站点大区）、`regional_date`（业务日期）
**更新频率：** 每日全量覆盖写入（`INSERT OVERWRITE`）
**引用频次/访问频次：** 1

---

## 业务描述

本表记录**搜索推荐（SR）业务中竞价（PB，Price Bidding）场景的 Winner Model 历史快照数据**，来源于 ODS 层 Paimon 实时特征表，经过站点过滤后按大区和业务日期分区落入明细层，保留每日分区历史。

**核心业务场景：**
- 追踪每个商品（`item_id`）在特定店铺（`shop_id`）下，各竞价模型（`model_id`）的出价及状态变更历史；
- 分析竞价 Winner Model 的生命周期：从全量提升阶段（`full_start_timestamp`）、衰减阶段（`decay_start_timestamp`）到停止提升阶段（`no_boost_start_timestamp`）的时序流转；
- 支持按站点大区、日期切片进行竞价效果回溯与审计。

**适合回答的问题：**
- 某站点某日，某商品的竞价模型处于什么状态（`status`）？状态最后一次变更是何时？
- 某 CSPU 下各竞价模型的出价价格分布是怎样的？
- Winner Model 从进入全量提升到进入衰减阶段平均经历多长时间？
- 各大区竞价模型的状态流转趋势如何随日期变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识（如 SG、MY、TH 等），用于数据分区隔离，每次写入仅覆盖指定大区分区 |
| `regional_date` | date | 业务日期，数据所属的分区日期，格式为 `yyyy-MM-dd` |

### 维度：商品与店铺信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，标识参与竞价的具体商品 |
| `shop_id` | bigint | 店铺 ID，商品所属店铺 |
| `cspu_id` | bigint | CSPU ID（标准商品单元），商品的标准化聚合维度 |
| `model_id` | bigint | 竞价模型 ID，标识具体使用的 Winner Model |

### 维度：竞价模型状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `status` | string | 当前竞价模型状态，如生效、衰减、停止等阶段标识 |
| `status_update_time` | bigint | 模型状态最近一次更新的时间戳（毫秒级 Unix 时间戳） |

### 指标：竞价出价信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `bid_price` | bigint | 竞价出价价格，单位通常为最小货币单位（如分） |

### 指标：模型生命周期时间戳

| 字段 | 类型 | 说明 |
|---|---|---|
| `full_start_timestamp` | bigint | 模型进入全量提升阶段的开始时间戳（毫秒级 Unix 时间戳） |
| `decay_start_timestamp` | bigint | 模型进入衰减阶段的开始时间戳（毫秒级 Unix 时间戳） |
| `no_boost_start_timestamp` | bigint | 模型进入停止提升（no boost）阶段的开始时间戳（毫秒级 Unix 时间戳） |
| `msg_timestamp` | bigint | 原始消息时间戳，记录上游 ODS 数据写入或消息产生的时间（毫秒级 Unix 时间戳） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region` 和 `regional_date` 均为分区字段，查询时务必同时指定**，否则将触发全表扫描，造成严重性能问题：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-01-01'
  ```
- 若需多站点查询，使用 `IN` 而非 `LIKE`，与 ETL 过滤逻辑一致：
  ```sql
  WHERE grass_region IN ('SG', 'MY')
    AND regional_date = '2025-01-01'
  ```

### 不可直接 SUM 的字段

- **`bid_price`**：若同一商品在同一分区内存在多条模型记录，直接 SUM 会重复计算，需先按业务主键去重或聚合后再汇总；
- **各时间戳字段**（`full_start_timestamp`、`decay_start_timestamp`、`no_boost_start_timestamp`、`msg_timestamp`、`status_update_time`）：均为时间点语义，不具备加和意义，仅可用于比较、排序或计算时间差。

### 时效性说明

- 本表为**每日全量快照分区表**，每个 `(grass_region, regional_date)` 分区覆盖写入当日来自 ODS 层的全量数据；
- 数据反映的是 ODS 源表（`paimon.rcmd_feature.ods_sr_data_warehouse_tc_pb_winner_model`）在对应业务日期的状态快照，若需最新状态请查询最新 `regional_date` 分区；
- 历史趋势分析需按 `regional_date` 逐日汇总，不同日期分区数据相互独立。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.rcmd_feature.ods_sr_data_warehouse_tc_pb_winner_model` | ODS 层 Paimon 实时特征表，提供竞价 Winner Model 的原始明细数据，按站点大区过滤后全量写入目标分区 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.rcmd_feature.ods_sr_data_warehouse_tc_pb_winner_model
    │
    │  WHERE grass_region IN (${grass_region})
    │  SELECT 全部业务字段（共 11 个非分区字段）
    ▼
srdi_mart.dwd_sr_data_warehouse_tc_pb_winner_model_history
    PARTITION (grass_region = ${grass_region}, regional_date = ${regional_date})
```

### 关键步骤

1. **目标分区覆盖写入（INSERT OVERWRITE）**
   - 无中间 temporary view，ETL 为单 SQL statement 直接写入；
   - 以 `INSERT OVERWRITE TABLE ... PARTITION (grass_region = ${grass_region}, regional_date = ${regional_date})` 静态分区覆盖，每次执行仅覆盖指定 `(grass_region, regional_date)` 分区，不影响其他分区历史数据；
   - 从 ODS 表按 `grass_region` 过滤后，将 `item_id`、`shop_id`、`cspu_id`、`model_id`、`bid_price`、`status`、`status_update_time`、`full_start_timestamp`、`decay_start_timestamp`、`no_boost_start_timestamp`、`msg_timestamp` 共 11 个字段原样抽取写入目标表，无额外计算或转换逻辑。

### 注意事项

- **单 Writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），不存在多文件并发写入同一分区的竞争风险；
- **静态分区覆盖**：`grass_region` 和 `regional_date` 均以参数变量形式传入（`${grass_region}`、`${regional_date}`），每次调度仅处理单一分区组合，历史分区安全保留；
- **ODS 源表为 Paimon 格式**：上游为实时特征存储，调度时序需确保 ODS 层数据已完整写入当日快照后再触发本表 ETL，否则存在数据截断风险；
- **字段无转换**：所有字段从 ODS 直接透传，若 ODS 上游字段定义或枚举值发生变更，本表将直接受影响，需关注 `status` 字段枚举值的上游变更通知。

---

*文档生成时间：2026-05-17*