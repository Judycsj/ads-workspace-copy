<!-- ads-workspace-gdoc-sync: gdoc_id=1TfSOCCixOrejNMwMI3B-iB2U23ZPUexGBgAJI9bevo4 gdoc_url=https://docs.google.com/document/d/1TfSOCCixOrejNMwMI3B-iB2U23ZPUexGBgAJI9bevo4/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_search_replace_pruning_hf

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `exp_tag` + `cspu_id` + `item_id`
**分区：** `grass_region`（大区）/ `regional_date`（业务日期）/ `regional_hour`（业务小时）
**更新频率：** 小时级（HF，高频更新）
**引用频次 / 访问频次：** 4234

---

## 业务描述

本表是搜索场景下**商品替换剪枝（Search Replace Pruning）**的小时级明细宽表，服务于 PB（Personalization & Business）搜索替换策略。

核心业务场景：
- 在搜索结果中，当展示商品（item）相对于其所属 CSPU（标准商品单元）表现较差时，系统需要判断是否将其"剪枝"（pruning），即降权或不再展示该 item，以 CSPU 中表现更好的 item 替换。
- 本表记录每个 `(exp_tag, cspu_id, item_id)` 组合当前的剪枝标签（`pruning_tag`）及版本信息（`version_date`），支撑在线替换剪枝策略的实时读取与版本管理。
- 采用**增量累积**机制：新分区数据在上一个可用历史分区基础上合并更新，保证组合 key 的连续性；仅当监控回退触发版本升级或存在新增 key 时，才更新剪枝标签与版本号。

适合回答的问题：
- 当前某大区某小时，哪些 item 被标记为 `obvious_bad` / `obvious_good` / `same_with_cspu` / `long_tail` / `can_not_explore`？
- 某 `(cspu_id, item_id)` 组合的剪枝版本（`version_date`）最近是否发生了升级？
- 在指定实验策略（`exp_tag`）下，特定商品的剪枝结论是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`TH` 等；驱动任务按区域并行写入 |
| `regional_date` | date | 业务日期（大区本地时间），格式 `yyyy-MM-dd` |
| `regional_hour` | int | 业务小时（大区本地时间），0–23 |

### 维度：商品与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_tag` | string | 实验策略标识，当前版本仅有 `exp_1`；预留多实验扩展能力 |
| `cspu_id` | bigint | 标准商品单元 ID（CSPU），商品替换的聚合维度 |
| `item_id` | bigint | 具体商品 ID（SKU 级别），被评估是否需要剪枝的主体 |

### 指标：剪枝结论与版本

| 字段 | 类型 | 说明 |
|---|---|---|
| `pruning_tag` | string | 剪枝标签，取值：`obvious_good`（明显好）/ `obvious_bad`（明显差）/ `same_with_cspu`（与 CSPU 持平）/ `long_tail`（长尾，曝光不足但可探索）/ `can_not_explore`（无法探索，广告曝光过少）；判断逻辑依赖 7 日曝光量、CTR、CTCR 与 CSPU 基准的对比 |
| `version_date` | int | 剪枝标签的版本日期，格式 `yyyyMMdd`（如 `20250903`）；当监控回退触发升级或首次写入时更新为当日；无质检信息时为 `null` |

---

## 查询使用须知

### 必须包含的过滤条件

- **三个分区字段必须同时指定**：`grass_region`、`regional_date`、`regional_hour`。缺少任意一个均会引发全表扫描，数据量极大。
- 推荐写法：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2025-09-03'
    AND regional_hour = 10
  ```
- 如需取最近历史分区，参照 ETL 逻辑：在最近 7 天范围内取小于当前时间点的最大 `(regional_date, regional_hour)` 组合。

### 不可直接 SUM 的字段

- `pruning_tag`：枚举标签，不可聚合求和，统计分布时应使用 `COUNT` + `GROUP BY`。
- `version_date`：版本标识字段，不具备数值加总意义，比较时应做整数大小比较（判断版本新旧）而非求和。

### 时效性说明

- 本表为**小时级（HF）**更新表，每小时写入一个新分区，无法通过单一分区获得跨小时累计数据。
- 表内数据采用**累积快照**语义：当前小时分区 = 上一可用分区的历史数据 + 本小时的增量更新合并结果，因此同一 `(exp_tag, cspu_id, item_id)` 在不同小时分区中均有记录（非仅增量行）。
- `version_date` 为 `null` 的记录表示该组合 key 尚无有效质检信息，线上读取时需注意过滤或做 null 处理。
- 由于任务要求单并发度（历史分区查找时依赖自身数据），**禁止并发重跑**同一分区，否则存在读写冲突风险。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf` | 获取当前小时 `(cspu_id, item_id)` 候选列表，作为本次需要评估的商品范围 |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_pruning_hf`（自引用） | 读取上一个可用历史分区的剪枝记录，用于累积合并，保持 key 的连续性 |
| `srdi_mart.dws_sr_data_warehouse_pb_replace_pruning_item_nd` | 例行任务产出的 item 近 7 日曝光、点击、下单等基础指标，用于计算剪枝标签 |
| `srdi_mart.dws_sr_data_warehouse_pb_replace_pruning_item_manual_7d` | 手动任务产出的 item 近 7 日基础指标，作为例行任务的补充兜底 |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_monitoring_nd` | 监控回退数据，提供需要触发版本升级的 `(exp_tag, cspu_id, item_id, version_date)` 信号 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_pb_one_variation_model_minf  ──┐
                                                      ├──► cheapest_list（当前候选商品）
                                                      │
dwd_sr_data_warehouse_pb_search_replace_pruning_hf ──┤（自引用：上一可用历史分区）
（自引用）                                             ├──► last_pruning（历史剪枝状态）
                                                      │
                                          FULL JOIN   │
                                                      ▼
                                          accumulated_pruning_list（累积合并后的 key 全集）
                                                      │
dws_sr_data_warehouse_pb_replace_pruning_item_nd ───┐ │
dws_sr_data_warehouse_pb_replace_pruning_item_manual_7d ─┤
                                                    └──► pruning_basic_metrics（指标合并）
                                                              │
                                                              ▼
                                                      pruning_exp（本次计算的新剪枝标签）
                                                              │
dwd_sr_data_warehouse_pb_search_replace_monitoring_nd ──► monitoring_back（版本升级信号）
                                                              │
                                accumulated_pruning_list + monitoring_back + pruning_exp
                                                              │
                                                              ▼
                               INSERT OVERWRITE → dwd_sr_data_warehouse_pb_search_replace_pruning_hf
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `cheapest_list` | 从 `one_variation_model_minf` 取当前小时候选 `(cspu_id, item_id)`，按实验策略数量复制行（当前仅 `exp_1`） |
| Step 2 | `SET last_partition` | 查询本表自身，在最近 7 天内找到小于当前时间点的最大历史分区字符串 `regional_date_HH` |
| Step 3 | `last_pruning` | 按 Step 2 定位到的历史分区，读取上一次剪枝结论与版本信息 |
| Step 4 | `accumulated_pruning_list` | `last_pruning` FULL OUTER JOIN `cheapest_list`，合并历史记录与新增 key，确保 key 全集不丢失 |
| Step 5 | `scheduler_pruning` | 从例行 DWS 表取 `mapping_general='Search'`、近 7 天有效（`last7d_day_cnt>=7`）的 item 指标，计算 CTR / CTCR 等派生比率 |
| Step 6 | `manual_pruning` | 从手动 DWS 表补充指标，排除已在例行结果中的 item（例行优先） |
| Step 7 | `pruning_basic_metrics` | UNION ALL 合并例行与手动指标 |
| Step 8 | `pruning_exp` | 按多阶阈值规则（曝光量 / 下单量 / CTR / CTCR 与 CSPU 基准 1.3x / 0.7x 对比）计算每个 item 的 `pruning_tag`；当前仅输出 `exp_1` |
| Step 9 | `monitoring_back` | 读取昨日监控回退数据，筛选 `version_date = 今日（yyyyMMdd）` 的记录，作为需要触发版本升级的信号 |
| Step 10 | INSERT OVERWRITE | 三路 LEFT JOIN（accumulated_pruning_list + monitoring_back + pruning_exp），按 `update_flag` 决策是否更新 `pruning_tag` 和 `version_date`，写入目标表当前分区 |

**`update_flag` 决策逻辑：**

```
update_flag = true  当且仅当：
  1. monitoring_back 中存在该 key 且 new_version_date > current_version_date（触发版本升级）
  2. OR current_version_date IS NULL（首次写入或上次无质检信息）
```

- `update_flag = true` 时：使用 `pruning_exp` 的新标签，版本号置为当日 `yyyyMMdd`（若新标签为 null 则版本号也为 null）。
- `update_flag = false` 时：保留历史 `pruning_tag` 和 `version_date` 不变。

### 注意事项

1. **单并发度限制**：ETL SQL 注释明确说明此任务必须设置为单并发度，因为 Step 2 需要读取目标表自身的历史分区，多并发并行写入会导致历史分区查询结果不确定，存在读写竞争风险。
2. **自引用风险**：本表在 Step 2 和 Step 3 中读取自身数据，重跑历史分区时需确认上一可用分区的数据完整性，否则可能产生基于错误历史状态的累积结果。
3. **监控回退时效性**：`monitoring_back` 依赖前一天的监控数据，且仅匹配 `version_date = 当日`；若监控任务当天未产出数据，则本次不触发版本升级，需等到次日重新计算。
4. **手动任务兜底时效性**：`manual_pruning` 要求 `local_date >= date_sub(regional_date, 2)`，即手动任务数据最多允许延迟 2 天；超出则不被采用。
5. **实验策略扩展**：`pruning_exp` 中 `exp_2` 相关逻辑已注释，当前仅有 `exp_1`；后续新增实验策略时，`cheapest_list` 的 `explode` 数组和 `pruning_exp` 均需同步修改。
6. **`version_date` null 语义**：`version_date` 为 null 表示该 key 尚无质检确认，线上消费时需作特殊处理，避免与有效版本 0 混淆。

---

*文档生成时间：2026-05-17*