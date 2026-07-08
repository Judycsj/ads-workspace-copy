<!-- ads-workspace-gdoc-sync: gdoc_id=1soNxAt71FZuXt6qByxTSvgRzMViulIPKKyzcpYOGlrY gdoc_url=https://docs.google.com/document/d/1soNxAt71FZuXt6qByxTSvgRzMViulIPKKyzcpYOGlrY/edit -->

# srdi_mart.dwd_sr_data_warehouse_tc_pb_winner_model_minf

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `regional_minute` + `cspu_id` + `model_id` + `item_id`
**分区：** `grass_region` / `regional_date` / `regional_hour` / `regional_minute`（四级分区，精确到分钟）
**更新频率：** 分钟级实时写入（每分钟一个分区快照）
**引用频次 / 访问频次：** 21,891 次

---

## 业务描述

本表记录搜推竞价（TC PB，Top-of-Category Price Boost）场景下，**每分钟粒度的竞价获胜模型（Winner Model）明细快照**。每条记录代表在指定分钟窗口内，某一 CSPU 下某个竞价模型赢得流量提升资格时的核心状态信息，包含出价、流量提升阶段、累计获胜时长、库存、店铺类型及 CSPU 历史价格率等维度。

**核心业务场景：**
- 监控 TC PB 竞价结果：追踪哪些模型处于 Normal Boost / Decay Boost 状态。
- 分析竞价模型的存活时长（`last_win_accumulative_hours`），评估 Boost 持续周期。
- 结合出价、库存、店铺类型进行竞价效果归因与策略调优。
- 为算法侧提供实时获胜模型的特征输入（仅输出算法所需的 `full_traffic_boost` 和 `decay_traffic_boost` 状态数据）。

**适合回答的问题：**
- 当前分钟内各大区有哪些模型处于竞价获胜状态？
- 某模型从开始获胜到当前已累计多少小时？
- 不同店铺类型（SCS-local / SCS-CB / non-SCS）的获胜模型分布如何？
- 某 CSPU 的历史价格率（`cspu_pr_rate`）对应哪些获胜模型？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY 等），分区键之一 |
| `regional_date` | date | 大区本地日期，分区键之一 |
| `regional_hour` | int | 大区本地小时（0–23），分区键之一 |
| `regional_minute` | int | 大区本地分钟（0–59），分区键之一；与 `regional_hour` 共同标识分钟级快照 |

### 维度：竞价模型标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（Category SPU）标识，竞价的商品聚合单元 |
| `model_id` | bigint | 竞价模型 ID，关联 `dim_model` 获取库存等属性 |
| `item_id` | bigint | 商品 SKU/Item ID |
| `shop_id` | bigint | 店铺 ID |

### 维度：店铺与 CSPU 属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_scs_type` | string | 店铺 SCS 类型，取值：`scs-local`、`scs-cb`、`non-scs`（原始为 null 时填充为 `non-scs`） |
| `cspu_pr_rate` | string | CSPU 历史价格率标签，来自前一日 CSPU 级别汇总表的最新分区 |

### 维度：流量提升状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `current_boost_type` | string | 当前流量提升类型，枚举值：`Normal Boost`（全量提升）、`Decay Boost`（衰减提升）、`No Boost`（无提升，实际本表只输出前两者） |
| `traffic_status` | int | 流量状态编码：`1` = full_traffic_boost（Normal Boost），`2` = decay_traffic_boost（Decay Boost） |

### 指标：竞价与时间戳

| 字段 | 类型 | 说明 |
|---|---|---|
| `bid_price` | double | 出价金额（单位：元），由上游原始值除以 100,000 换算 |
| `full_start_timestamp` | bigint | 模型进入全量流量提升阶段的 Unix 时间戳（秒） |
| `decay_start_timestamp` | bigint | 模型进入衰减阶段的 Unix 时间戳（秒）；原始值为 0 时存储为 null |
| `no_boost_start_timestamp` | bigint | 模型停止 Boost 的 Unix 时间戳（秒）；原始值为 0 时存储为 null |
| `last_win_accumulative_hours` | double | 模型累计获胜小时数；若 `no_boost_start_timestamp` 存在则 = `(no_boost_start_timestamp - full_start_timestamp) / 3600`；否则 = `(当前分钟末时间戳 - full_start_timestamp) / 3600` |
| `model_stock` | bigint | 竞价模型对应的库存数量，来自实时维度表 `rt_dim_model` |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：该表为四级分区表，不指定 `grass_region` 将触发全分区扫描，代价极高。
- **必须指定 `regional_date`**：按日期过滤是基本要求，建议同时指定 `regional_hour` 或 `regional_minute` 缩小扫描范围。
- 典型过滤模板：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-05-17'
    AND regional_hour = 14
    AND regional_minute = 30
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `bid_price` | 同一 model/item 在不同分钟分区重复出现，跨分钟 SUM 无业务意义；需指定单一分钟分区后聚合 |
| `last_win_accumulative_hours` | 派生计算值（基于当前分钟时间戳），跨分钟累加会重复计算；应取单一时间点快照分析 |
| `model_stock` | 实时快照值，跨分钟 SUM 无意义 |
| `cspu_pr_rate` | 字符串类型标签，不适合数值聚合 |

### 时效性说明

- 本表为**分钟级快照表**，每分钟写入一个 `(grass_region, regional_date, regional_hour, regional_minute)` 分区，不同分钟的数据相互独立。
- `cspu_pr_rate` 来自前一日汇总表的最新分区，存在 **T-1 日时效性**，非实时字段。
- `model_stock` 来自实时维度表，时效性为近实时（Live 表），但受上游刷新频率影响。
- 分析"当前状态"时请选取最新的 `regional_minute` 分区，避免混用多分钟数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.rcmd_feature.ods_sr_data_warehouse_tc_pb_winner_model` | 竞价获胜模型原始数据，提供 cspu_id、model_id、item_id、shop_id、bid_price、时间戳及 status 等核心字段；仅过滤 `full_traffic_boost` 和 `decay_traffic_boost` 两种状态 |
| `mp_item.rt_dim_model__reg_s0_live` | 实时模型维度表，关联获取 `model_stock`（模型库存） |
| `regds_listing.dim_scs_shop_list_df` | SCS 店铺维度表，关联获取 `shop_scs_type`（店铺 SCS 类型），仅保留 `scs-local` 和 `scs-cb` 类型 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | CSPU 日级汇总表，关联获取 `cspu_pr_rate`（CSPU 历史价格率），取严格早于当前 `regional_date` 的最新分区 |

---

## ETL 逻辑摘要

### 数据流

```
ods_sr_data_warehouse_tc_pb_winner_model   (Paimon 实时源，status 过滤)
        │
        ▼
winner_model_<region>  (Temp View：清洗出价、处理时间戳、计算累计小时数、编码 traffic_status)
        │
        ├── LEFT JOIN dim_model_<region>    (rt_dim_model：补充 model_stock)
        ├── LEFT JOIN shop_type_<region>    (dim_scs_shop_list_df：补充 shop_scs_type)
        └── LEFT JOIN cspu_label_<region>   (dws cspu 日表：补充 cspu_pr_rate)
                │
                ▼
        INSERT OVERWRITE dwd_sr_data_warehouse_tc_pb_winner_model_minf
        PARTITION (grass_region, regional_date, regional_hour, regional_minute)
```

### 关键步骤

1. **Statement 1 — `winner_model_<region>`（核心清洗 View）**
   - 从 Paimon ODS 表读取当前分钟获胜模型，过滤 `status IN ('full_traffic_boost', 'decay_traffic_boost')`。
   - `bid_price` 除以 100,000 换算为元。
   - `decay_start_timestamp` / `no_boost_start_timestamp` 为 0 时替换为 null。
   - `last_win_accumulative_hours`：若 `no_boost_start_timestamp` 为 null，则以当前分区时间（`regional_date` + `regional_hour` + `regional_minute * 60`）减去 `full_start_timestamp` 计算；否则以 `no_boost_start_timestamp - full_start_timestamp` 计算，结果单位为小时。
   - `traffic_status` 编码：`full_traffic_boost` → 1，`decay_traffic_boost` → 2。

2. **Statement 2 — `dim_model_<region>`（模型库存 View）**
   - 从实时维度表按 `grass_region` 过滤，仅取 `model_id` 和 `model_stock`。

3. **Statement 3 — `shop_type_<region>`（店铺类型 View）**
   - 从 SCS 店铺列表按 `grass_region` 和 `type IN ('scs-local','scs-cb')` 过滤，仅保留 SCS 类型店铺。

4. **Statement 4 — `cspu_label_<region>`（CSPU 价格率 View）**
   - 从 CSPU 日级汇总表取满足 `local_date < regional_date` 的最新分区（通过 `data_infra.max_pt` 函数确定），保证使用 T-1 日之前的最新可用数据。

5. **Statement 5 — INSERT OVERWRITE（目标写入）**
   - 将以上四个 Temp View 以 `winner_model` 为主表依次 LEFT JOIN，补充 `model_stock`、`shop_scs_type`（null 填充为 `non-scs`）、`cspu_pr_rate`、`current_boost_type`（枚举文本），写入目标分区。
   - 使用 `REPARTITION(100)` 控制输出文件数。

### 注意事项

- **单一 ETL 文件，无 multi-writer 风险**：该表由单个 SQL 文件写入，不存在多 writer 并发覆盖问题。
- **INSERT OVERWRITE 分区覆盖**：每次执行仅覆盖指定 `(grass_region, regional_date, regional_hour, regional_minute)` 分区，历史分钟分区不受影响；重跑幂等安全。
- **Temp View 按 region 参数化命名**：View 名称包含 `${grass_region_without_quote}` 参数，不同大区并行运行时 View 相互隔离，无冲突风险。
- **`cspu_pr_rate` 的时效性风险**：`max_pt` 取的是严格早于 `regional_date` 的最新日期分区；若上游 DWS 表当日分区延迟产出，不会影响本表，但 `cspu_pr_rate` 可能使用较旧的标签。
- **`traffic_status = 3 / current_boost_type = 'No Boost'`**：由 SQL 的 `else` 分支定义，但 ODS 源数据已过滤仅保留 status 1/2，正常情况下不会出现该值；如出现，需排查上游数据异常。

---

*文档生成时间：2026-05-17*