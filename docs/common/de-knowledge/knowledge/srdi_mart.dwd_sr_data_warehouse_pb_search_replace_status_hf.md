<!-- ads-workspace-gdoc-sync: gdoc_id=1KkIXYKqit89ApKFbfJEPs8oaUJBX9zPyDXzJX_TmUlA gdoc_url=https://docs.google.com/document/d/1KkIXYKqit89ApKFbfJEPs8oaUJBX9zPyDXzJX_TmUlA/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_search_replace_status_hf

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `exp_tag` + `cspu_id` + `item_id`
**分区：** `grass_region`（站点/区域）、`regional_date`（业务日期）、`regional_hour`（业务小时）
**更新频率：** 小时级（hf，hourly frequency）
**引用频次/访问频次：** 4043

---

## 业务描述

本表记录搜索替换（Search Replace）实验中，以 **（exp_tag, cspu_id, item_id）** 为粒度的**探索状态快照**，是搜推「以 CSPU 为单位的搜索替换」策略的核心状态表。

**核心业务场景：**

1. **探索状态追踪**：记录每个实验组（`exp_tag`）下，商品（`item_id`）对应的候选 CSPU（`cspu_id`）当前处于哪个探索阶段（待探索 / 探索中 / 优选 / 非优选）。
2. **剪枝决策落地**：结合上游剪枝结果（`pruning_tag`），判断当前 CSPU 属于明显好、明显差、长尾还是普通可探索，直接影响是否进入流量探索。
3. **分级探测判断**：对 `long_tail` 类型的 CSPU 执行四档曝光量（≥100 / ≥200 / ≥500 / ≥1000）的分级 CTR 对比探测，并将结论写入 `exploration_status`。
4. **最低价标记**：通过关联最优变价模型，标记该 item-CSPU 组合是否为最低价（`is_cheapest`）。
5. **状态继承与重置**：每小时增量计算时，以上一快照分区为基础，对新版本数据进行状态合并，避免探索进度丢失或错误继承。

**适合回答的问题：**
- 当前小时某区域某实验下，各 CSPU 的探索状态分布如何？
- 哪些 CSPU 已达到 `preferred` / `non_preferred` 结论，哪些仍在 `explore`？
- 被过滤的 CSPU 其过滤原因（`filtered_reason`）的分布情况？
- 某 item 对应的最低价 CSPU 当前探索进度如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识（如 SG、MY、TH 等），所有查询必须指定 |
| `regional_date` | date | 业务日期（区域本地时间），格式 `yyyy-MM-dd` |
| `regional_hour` | int | 业务小时（区域本地时间，0–23） |

### 维度：实验与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_tag` | string | 实验组标签，标识搜索替换 AB 实验的分组 |
| `cspu_id` | bigint | 候选 CSPU ID，即被替换的目标 SPU |
| `item_id` | bigint | 原始商品 ID |
| `version_date` | int | 剪枝/替换策略的版本日期，用于检测策略是否有新版本更新（格式通常为 `yyyyMMdd` 整型） |

### 维度：状态与标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `pruning_tag` | string | 剪枝标签，来自上游剪枝表。取值包括：`obvious_good`（明显优质）、`obvious_bad`（明显差）、`can_not_explore`（不可探索）、`long_tail`（长尾，走分级探测）、`same_with_cspu`（与 CSPU 同质，走普通探测）等 |
| `exploration_status` | string | 当前小时的探索状态结论。取值：`prepare`（待探索，尚无剪枝数据）、`explore`（探索中，未达结论门槛）、`preferred`（优选，探索通过）、`non_preferred`（非优选，探索淘汰）|
| `filtered_reason` | string | 探索被过滤/失败的原因。当 `exploration_status` 为 `non_preferred` 时填充，取值示例：`normal_failed`、`tiered_normal_failed`、`tiered_failed_level_1/2/3`、`obvious_bad`、`can_not_explore` 等；探索通过或仍在探索中时为 null |

### 指标：最低价标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_cheapest` | int | 该 item-CSPU 组合在当前小时是否命中最低价模型：`1` 表示是最低价，`0` 表示否。来源于 `dwd_sr_data_warehouse_pb_one_variation_model_minf` |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定三个分区字段**：`grass_region`、`regional_date`、`regional_hour`，缺少任一均会触发全表扫描，导致查询超时或资源超额消耗。
- 推荐写法示例：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2024-08-01'
    AND regional_hour = 10
  ```
- 如需跨小时分析，建议显式列举小时范围，避免使用 `regional_date BETWEEN ... AND ...` 而不限定 `regional_hour`。

### 不可直接 SUM / AVG 的字段

| 字段 | 原因 |
|---|---|
| `is_cheapest` | 为 0/1 标记字段，可 SUM 计数，但不可直接 AVG 后与其他指标对比，需明确分母含义 |
| `exploration_status` | 枚举状态字段，只能做分组计数（COUNT），不能数值聚合 |
| `filtered_reason` | 枚举字符串，只能做分组计数 |
| `version_date` | 整型版本号，MAX/MIN 有意义，SUM 无业务意义 |

### 时效性说明

- 本表为**小时级快照表**（`_hf`），每小时全量覆盖写入对应分区（`INSERT OVERWRITE PARTITION`）。
- 每个分区是截至该小时末的**状态快照**，不是增量明细，**不可跨小时累加**。
- 表内会引用近 7 天（`date_sub(regional_date, 6)` 至 `regional_date`）范围内的历史分区查找上一快照，因此存在**跨分区依赖**；首次运行或历史分区缺失时，上一快照为空，会退化为全量初始化状态。
- 数据就绪时间依赖上游 `dwd_sr_data_warehouse_pb_search_replace_pruning_hf` 和 `dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf` 的产出，存在一定延迟，使用时需关注数据 marker 就绪情况。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_status_hf`（自身） | 读取上一快照分区，继承历史探索状态（exploration_status、filtered_reason、pruning_tag、version_date） |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_pruning_hf` | 提供当前小时的剪枝标签（pruning_tag）和版本日期（version_date），驱动状态更新 |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf` | 提供当前小时探索流量（explore）和对照流量（base）的 N 日曝光/点击指标，用于 CTR 对比决策 |
| `srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf` | 提供当前小时最低价模型结果，用于打标 `is_cheapest` |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_pb_search_replace_status_hf（上一快照）
         ↓ last_status（历史状态继承）
dwd_sr_data_warehouse_pb_search_replace_pruning_hf
         ↓ pruning（当前剪枝结果）
         → accumulated_list（FULL OUTER JOIN，状态合并 + 版本比较）
dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf（explore 流量）
         ↓ explore_realtime_metrics（探索组实时指标）
dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf（base 流量）
         ↓ control_realtime_metrics（对照组实时指标）
dwd_sr_data_warehouse_pb_one_variation_model_minf
         ↓ cheapest_list（最低价标记）
         → INSERT OVERWRITE → dwd_sr_data_warehouse_pb_search_replace_status_hf（当前小时分区）
```

### 关键步骤

1. **查找上一快照分区**（Statement 1）：在目标表近 7 天的已有分区中，找到早于当前 `(regional_date, regional_hour)` 的最近一个时间分区，作为历史状态基础。

2. **构建历史状态视图 `last_status`**（Statement 2）：从上一快照分区读取 `exp_tag`、`cspu_id`、`item_id`、`version_date`、`pruning_tag`、`exploration_status`、`filtered_reason`，作为本次状态继承的起点。

3. **构建最低价视图 `cheapest_list`**（Statement 3）：从最优变价模型表读取当前小时有效的 item-CSPU 最低价组合，用于最终打标 `is_cheapest`。

4. **构建剪枝视图 `pruning`**（Statement 4）：读取当前小时的剪枝结果（`pruning_tag`、`version_date`），代表策略侧最新的判断。

5. **构建探索组实时指标视图 `explore_realtime_metrics`**（Statement 5）：从实时指标表筛选 `traffic_tag='explore'` 的流量，按 `(exp_tag, cspu_id, item_id, version_date)` 聚合 N 日曝光量（`explore_imp_cnt_nd`）和 N 日点击量（`explore_click_cnt_nd`）。

6. **构建对照组实时指标视图 `control_realtime_metrics`**（Statement 6）：从实时指标表筛选 `traffic_tag='base'` 的流量，按 `(cspu_id, item_id)` 聚合 N 日曝光量（`cspu_imp_cnt_nd`）和 N 日点击量（`cspu_click_cnt_nd`），作为 CTR 对比基准。

7. **构建状态合并视图 `accumulated_list`**（Statement 7）：将历史状态（`last_status`）与当前剪枝（`pruning`）做 FULL OUTER JOIN，通过版本比较逻辑判断 `update_flag`：
   - `prepare`：历史与新剪枝均无版本，首次准备
   - `new`：历史无版本，新剪枝有版本，全新进入
   - `rollback`：历史版本较新且已 `preferred`，新版本回退，重置探索
   - `exploring`：其余情况，保持探索状态继续推进
   - 非 `exploring` 状态时，`exploration_status`、`filtered_reason` 清空，`pruning_tag` 和 `version_date` 重置为新值。

8. **最终写入目标表**（Statement 8，`INSERT OVERWRITE`）：以 `accumulated_list` 为主表，LEFT JOIN 探索组指标、对照组指标、最低价列表，执行核心探索状态计算逻辑：
   - `exploration_status` 计算：若历史状态不为 null，则按 `pruning_tag` 分支执行分级/普通 CTR 探测判断；否则按 `pruning_tag` 静态规则直接赋值（`obvious_good`→`preferred`，`obvious_bad`/`can_not_explore`→`non_preferred`，null→`prepare`，其余→`explore`）。
   - `filtered_reason` 计算：与 `exploration_status` 联动，探索失败时写入对应失败层级原因，通过时置 null。
   - `is_cheapest`：命中 `cheapest_list` 则为 1，否则为 0。

### 注意事项

- **自依赖写入风险**：ETL 在 Statement 1/2 中读取目标表自身历史分区，写入时为 `INSERT OVERWRITE` 当前分区，不会覆盖历史分区，但需确保历史分区存在且完整，否则首次运行时无历史状态可继承，所有记录将从 `prepare`/`explore` 初始化。
- **单 Writer**：本表为单 ETL 文件写入（`multi_writer: false`），无并发写入竞争风险。
- **参数化分区写入**：SQL 使用 `${grass_region}`、`${regional_date}`、`${regional_hour}` 参数化分区，每次调度对应单一区域单一小时分区的全量覆盖写入。
- **上游 Marker 强依赖**：除自身历史分区外，其余上游表均为强依赖 marker，若上游 marker 未就绪则当前实例跳过，历史状态不更新。
- **CTR 分级探测门槛**：`long_tail` 类型的分级探测共四档（100/200/500/1000 曝光），各档 CTR 阈值不同（1 次点击 / 10% / 50% / 100% CSPU CTR），逻辑复杂，下游使用 `exploration_status` 时应以该表输出值为准，不应在下游重新计算。
- **CSPU 指标 null 处理**：对照组指标（`cspu_imp_cnt_nd`、`cspu_click_cnt_nd`）异常为 null 时，ETL 统一以 0 代入计算（`coalesce(..., 0)`），避免 null 除法导致结果偏差。

---

*文档生成时间：2026-05-17*