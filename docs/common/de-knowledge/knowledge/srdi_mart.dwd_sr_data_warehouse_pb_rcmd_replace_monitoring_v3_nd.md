<!-- ads-workspace-gdoc-sync: gdoc_id=10QzOXtAzSwZ1DICI4QTQ8py7kXb8kyHgxM27IbEgnBU gdoc_url=https://docs.google.com/document/d/10QzOXtAzSwZ1DICI4QTQ8py7kXb8kyHgxM27IbEgnBU/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_monitoring_v3_nd

**分层：** DWD（明细层）
**主键：** `grass_region` + `local_date` + `exp_tag` + `item_id` + `cspu_id`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日（T+1 调度，写入当日分区）
**访问频次：** 797 次

---

## 业务描述

本表用于记录**搜推推荐替换策略（PB Recommend Replace）监控场景**下，item × cspu 维度状态发生"反转"的商品明细数据。具体而言，表中仅保留满足以下条件的记录：

- 实验策略为 `T2`（监控回退策略）；
- 商品在 Flink dump 来的每日状态表中（`cheapest_v3_daily_status_info_df`），其 `pruning_tag` 处于稳定的 `non_preferred` 或 `preferred` 状态（排除探索中/无效/准备中状态）；
- 上述状态与维度表（`dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df`）中记录的历史 `pruning_tag` **不一致**（即发生了状态翻转）。

**核心业务场景：**
- 监控推荐替换策略 T2 中，item 下各 cspu 的 pruning 状态是否发生变化，用于触发监控回退逻辑。
- 支持对替换策略效果的异常感知与数据追溯。

**适合回答的问题：**
- 某日某站点下，哪些 item × cspu 组合的 pruning 状态发生了翻转？
- 策略 T2 下，状态反转的商品规模有多大？
- 某个 item 或 cspu 在哪些日期出现过状态反转？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `ID`、`TH` 等，用于多站点分区隔离 |
| `local_date` | date | 业务日期，对应上游数据的 `grass_date`，任务按日分区写入 |

### 维度：商品与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，与 cspu_id 联合标识一条替换关系 |
| `cspu_id` | bigint | 标准商品单元 ID（Canonical SPU），为 item 下的最优替换候选 |
| `exp_tag` | string | 实验标签，当前表仅包含 `T2`（监控回退策略）的记录 |

### 指标：版本与状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `version_date` | int | 版本号，取任务运行日的次日（`local_date + 1`）格式化为 `YYYYMMDD` 整型，用于标识数据写入批次 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必同时指定两个分区字段**，避免全表扫描：
  ```sql
  WHERE grass_region = 'XX'
    AND local_date = '2024-01-01'
  ```
- `exp_tag` 在当前 ETL 逻辑中已固定过滤为 `'T2'`，查询时可直接用该条件进一步缩小范围，但不依赖其做去重。

### 不可直接 SUM 的字段

- `version_date`：为派生的批次版本号（`date_add(local_date, 1)` 转整型），**不具备数值加和意义，不可 SUM**。
- 本表为明细粒度，`item_id` / `cspu_id` 在同一分区内理论上已通过 `row_number()` 去重（每个 `exp_tag + item_id + cspu_id` 取最新 `version_date` 的一条），但**跨日期分区不可直接聚合计数，需注意日期维度的语义边界**。

### 时效性说明

- 表名后缀 `_nd` 表示每日快照（Natural Day），每次写入为指定日期分区的全量覆盖（`INSERT OVERWRITE`）。
- 数据反映的是**当日（`local_date`）发生状态翻转**的 item × cspu 明细，不包含历史累计。
- `version_date` 为 `local_date + 1`，即任务实际运行日，与 `local_date` 差一天，使用时注意区分。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `rcmd_feature.cheapest_v3_daily_status_info_df` | Flink 实时 dump 的每日 item × cspu 状态宽表，提供 `pruning_tag`、`explore_status`、`exp_tag` 等字段，经去重后作为当日状态基准 |
| `srdi_mart.dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df` | 推荐替换策略的历史 pruning_tag 维度表，取截至当日最新分区，作为状态比对基准 |

---

## ETL 逻辑摘要

### 数据流

```
rcmd_feature.cheapest_v3_daily_status_info_df   (当日状态，去重取最新)
        │
        ▼
  dump_status_{region}  (临时视图：仅保留 pruning_tag 非空、状态稳定、exp_tag=T2 的记录)
        │
        │     srdi_mart.dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df (历史 pruning_tag)
        │                    │
        │              pruning_exp_{region}  (临时视图：取最新分区的 T2 维度数据)
        │                    │
        └──── INNER JOIN on item_id + exp_tag（过滤 pruning_tag 不一致） ────┘
                                    │
                                    ▼
        dwd_sr_data_warehouse_pb_rcmd_replace_monitoring_v3_nd
                   partition(grass_region, local_date)
```

### 关键步骤

**Step 1 — 临时视图 `dump_status_{region}`**

从 `rcmd_feature.cheapest_v3_daily_status_info_df` 读取当日（`grass_date = local_date`）指定站点数据，核心处理逻辑：
- 使用 `row_number() OVER (PARTITION BY exp_tag, item_id, cspu_id ORDER BY version_date DESC)` 对 Flink 可能重复写入的记录去重，取最新版本；
- 将 `pruning_tag` 与 `explore_status` 组合映射为 `exploration_status`（`preferred` / `non_preferred` / `explore`），优先以 `pruning_tag` 判断；
- 过滤条件：`pruning_tag IS NOT NULL`、`exploration_status IN ('non_preferred', 'preferred')`、`exp_tag = 'T2'`。

**Step 2 — 临时视图 `pruning_exp_{region}`**

从维度表 `dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df` 取截至 `local_date` 的最新可用分区数据（通过 `data_infra.max_pt` 函数动态获取），过滤条件：`exp_tag = 'T2'`。

**Step 3 — INSERT OVERWRITE 写目标表**

将 Step 1 与 Step 2 的结果按 `item_id + exp_tag` 做 INNER JOIN，保留两侧 `pruning_tag` **不相等**的记录（即状态发生翻转的商品），写入目标表当日分区：
- 输出字段：`exp_tag`、`cspu_id`、`item_id`、`version_date`（计算为 `cast(replace(date_add(local_date, 1), '-', '') as int)`）；
- 分区：`grass_region`、`local_date`。

### 注意事项

- **Flink dump 重复风险**：上游 `cheapest_v3_daily_status_info_df` 因 Flink instance 重试可能存在重复行，ETL 已通过 `row_number()` 去重，但若上游数据在任务运行期间仍在写入，可能影响去重结果的完整性。
- **维度表分区依赖**：Step 2 使用 `data_infra.max_pt` 动态取最新分区，若维度表当日分区未就绪，将自动回退到历史最新分区，可能引入轻微的数据滞后。
- **INSERT OVERWRITE 覆盖写**：每次调度对指定 `(grass_region, local_date)` 分区做全量覆盖，重跑安全，但并发写同一分区会有冲突风险（当前 `multi_writer = false`，无多路并发写入）。
- **`version_date` 语义**：该字段值为 `local_date + 1` 的 `YYYYMMDD` 整型，代表任务运行日，而非业务发生日，使用时勿与 `local_date` 混淆。

---

*文档生成时间：2026-05-17*