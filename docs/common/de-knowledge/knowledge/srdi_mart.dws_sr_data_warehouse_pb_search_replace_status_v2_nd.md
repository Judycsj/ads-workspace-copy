<!-- ads-workspace-gdoc-sync: gdoc_id=1NO5ylxNnpFZGDb7KlaG2EsNcSpsjB_c-6sS4IUaRFuQ gdoc_url=https://docs.google.com/document/d/1NO5ylxNnpFZGDb7KlaG2EsNcSpsjB_c-6sS4IUaRFuQ/edit -->

# srdi_mart.dws_sr_data_warehouse_pb_search_replace_status_v2_nd

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `cspu_id` + `item_id` + `exp_tag`
**分区：** `grass_region`（大区）/ `local_date`（业务日期）
**更新频率：** 每日调度（按 `local_date` 分区覆盖写入）
**访问频次：** 197 次

---

## 业务描述

本表面向搜索推荐（SR）数据仓库的 **PB（Price Book）搜索替换（Search Replace）** 业务，汇总每个 CSPU 候选商品在特定实验分组下的**探索状态（exploration_status）**、**物料剪枝状态（pruning_tag）**，以及当日截至最新小时的 **探索流量（explore）** 和 **基准流量（base/cspu）** 的近 N 天累计曝光/点击指标。

**核心业务场景：**
- 监控 PB 搜索替换模型中每个 CSPU-商品对在不同实验 Tag 下的探索/优选/非优选/准备状态分布；
- 评估替换策略的流量覆盖效果，支持对 `preferred`、`non_preferred`、`explore`、`prepare` 等探索状态的全面追踪；
- 结合实时指标（最新小时分区快照），反映近 N 天滚动窗口内的流量表现；
- 支持商品维度（`item_id`）的探索状态聚合，通过优先级规则（preferred > non_preferred > explore > prepare）取最高探索状态。

**适合回答的问题：**
- 某大区某日，哪些 CSPU 商品对处于「优选」或「探索」状态？
- 近 N 天内，各实验组下 CSPU 的曝光/点击量如何？
- 某商品（item_id）在当前版本下的整体探索状态是什么？
- 搜索替换策略中被剪枝的 CSPU 商品占比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`TH` 等，分区键之一 |
| `local_date` | date | 业务本地日期，分区键之一，对应 tracker 结算日期 |

### 维度：商品与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（Canonical SPU）唯一标识，来自 PB 单一变体模型分析表 |
| `item_id` | bigint | 商品 ID，与 `cspu_id` 共同标识一个候选替换对 |
| `exp_tag` | string | 实验分组标签，当前逻辑固定为 `exp_1`，用于区分实验版本 |
| `version_date` | int | 替换策略版本日期，来源于实时指标表，标识当前生效的模型版本 |

### 维度：状态标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `pruning_tag` | string | CSPU 剪枝标签，来自替换状态表，标识该 CSPU 是否被剪枝及剪枝原因 |
| `exploration_status` | string | CSPU 粒度的探索状态，取值包括 `preferred`、`non_preferred`、`explore`、`prepare`，来自替换状态表最新小时分区 |
| `item_exploration_status` | string | 商品（item_id）粒度的探索状态聚合，按优先级规则取该商品下所有 CSPU 中最高等级的探索状态（`preferred` > `non_preferred` > `explore` > `prepare`） |

### 指标：探索流量近 N 天累计

| 字段 | 类型 | 说明 |
|---|---|---|
| `explore_imp_cnt` | bigint | `traffic_tag='explore'` 流量下，CSPU-商品对当日最新小时的近 N 天累计曝光次数（`imp_cnt_nd`），NULL 补 0 |
| `explore_click_cnt` | bigint | `traffic_tag='explore'` 流量下，CSPU-商品对当日最新小时的近 N 天累计点击次数（`click_cnt_nd`），NULL 补 0 |

### 指标：基准（CSPU）流量近 N 天累计

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt` | bigint | `traffic_tag='base'` 流量下，CSPU-商品对当日最新小时的近 N 天累计曝光次数（`imp_cnt_nd`），NULL 补 0；关联条件中 `exp_tag='control'` |
| `cspu_click_cnt` | bigint | `traffic_tag='base'` 流量下，CSPU-商品对当日最新小时的近 N 天累计点击次数（`click_cnt_nd`），NULL 补 0；关联条件中 `exp_tag='control'` |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，该字段为分区键之一，缺失将导致全分区扫描，严重影响性能。
- **`local_date`**：必须指定，该字段为分区键之一，建议精确指定单日期或使用日期范围，避免全量扫描。

```sql
-- 推荐写法
WHERE grass_region = 'ID'
  AND local_date = '2025-05-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `explore_imp_cnt`、`explore_click_cnt` | 字段值为近 N 天滚动窗口累计指标（`_nd` 后缀），跨日期直接 SUM 会造成重复累加 |
| `cspu_imp_cnt`、`cspu_click_cnt` | 同上，近 N 天滚动窗口累计指标，不可跨日期 SUM |
| `item_exploration_status` | 派生聚合字段，由优先级规则计算得出，不可再次 GROUP BY 聚合后直接取值 |

> ⚠️ 如需汇总多日趋势，请仅取每日最新分区值，**不要对 `_nd` 指标跨 `local_date` 直接求和**。

### 时效性说明

- 表名含 `_nd` 后缀，表示指标为**近 N 天滚动窗口**统计，具体 N 值由上游实时指标表（`dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf`）中的 `imp_cnt_nd`、`click_cnt_nd` 字段定义。
- 实时指标来源为当日**最大可用小时分区**的快照，并非当日完整数据，存在日内截断；全天汇总数据需等待次日调度完成。
- 状态字段（`exploration_status`、`pruning_tag`）取自替换状态表当日**最新区域小时分区**，反映调度时刻的最新状态，非历史累积状态。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 获取当日有效的 CSPU-商品对候选列表（cheapest list），作为主体驱动表 |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf` | 获取当日最大小时分区的近 N 天曝光/点击指标，分别按 `traffic_tag='explore'` 和 `traffic_tag='base'` 拆分使用 |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_status_hf` | 获取当日最新小时的 CSPU 探索状态（`exploration_status`）和剪枝标签（`pruning_tag`） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf  ──→ cheapest_list（CSPU-商品候选对）
                                                                          │
dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf ──→ max_explore（explore流量指标）
dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf ──→ max_cspu（base流量指标）
                                                                          │
dwd_sr_data_warehouse_pb_search_replace_status_hf ──→ current_version_status（当前探索状态）
                                                     ──→ item_tag_status（商品粒度探索状态聚合）
                                                                          │
                                            多路 LEFT JOIN → INSERT OVERWRITE 目标表
```

### 关键步骤

1. **Step 1 — `cheapest_list`（Temporary View）**
   从 PB 单一变体模型分析维度表中提取当日当前大区的有效 CSPU-商品对，固定展开 `exp_tag = 'exp_1'`，作为全流程的主体驱动集合。

2. **Step 2 — 获取最大小时分区（SET 变量）**
   查询实时指标表，取当日当前大区的最大可用 `local_date + local_hour` 组合，拼接为字符串，用于后续指标取数时锁定同一时间截面，保证 explore 与 base 指标口径一致。

3. **Step 3 — `max_explore`（Temporary View）**
   从实时指标表按最大小时分区过滤 `traffic_tag='explore'`，提取 CSPU-商品对的近 N 天曝光（`imp_cnt_nd`）和点击（`click_cnt_nd`），NULL 补 0。

4. **Step 4 — `max_cspu`（Temporary View）**
   从实时指标表按最大小时分区过滤 `traffic_tag='base'`，提取 CSPU-商品对的基准流量近 N 天曝光和点击，NULL 补 0。

5. **Step 5 — `current_version_status`（Temporary View）**
   从替换状态表取当日最新区域小时分区数据，获取每个 CSPU-商品-实验组的 `exploration_status`、`pruning_tag`、`version_date`。

6. **Step 6 — `item_tag_status`（Temporary View）**
   在 `current_version_status` 基础上，按 `item_id + exp_tag` 分组，通过优先级前缀排序（`preferred=3`、`non_preferred=2`、`explore=1`、`prepare=0`），取 MAX 后切分获得 `item_exploration_status`，实现商品粒度的探索状态聚合。

7. **Step 7 — INSERT OVERWRITE（最终写入）**
   以 `cheapest_list` 为驱动，依次 LEFT JOIN `current_version_status`（获取 CSPU 状态）、`item_tag_status`（获取商品状态），再 LEFT JOIN `max_explore`（匹配 `version_date`）和 `max_cspu`（`exp_tag='control'`），最终覆盖写入目标表对应的 `grass_region + local_date` 分区。

### 注意事项

- **单 Writer，无并发冲突**：该表仅有 1 个 ETL 文件写入，`multi_writer=false`，不存在多 Writer 并发覆盖风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 方式，每次运行仅覆盖当日当前大区分区，历史分区数据不受影响。
- **实时指标为日内截断快照**：`max_partition` 取当日最大可用小时，若调度时间较早，`explore_imp_cnt` / `cspu_imp_cnt` 等指标不代表全天完整数据。
- **base 流量关联条件差异**：`max_cspu`（base 流量）在最终 JOIN 时使用 `exp_tag='control'` 过滤，而非与 `cheapest_list` 的 `exp_tag` 对应匹配，需注意该字段语义与 explore 流量的差异。
- **状态字段 LEFT JOIN 可能产生 NULL**：若某 CSPU-商品对在状态表中无记录，则 `exploration_status`、`pruning_tag`、`version_date` 均为 NULL，下游使用时需做空值处理。

---

*文档生成时间：2026-05-17*