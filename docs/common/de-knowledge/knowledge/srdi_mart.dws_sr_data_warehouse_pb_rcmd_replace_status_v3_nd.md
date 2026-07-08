<!-- ads-workspace-gdoc-sync: gdoc_id=10P6OmaR32uMNOMPoYqCKAkRkL87Nq33odBkLEJ7wTVE gdoc_url=https://docs.google.com/document/d/10P6OmaR32uMNOMPoYqCKAkRkL87Nq33odBkLEJ7wTVE/edit -->

# srdi_mart.dws_sr_data_warehouse_pb_rcmd_replace_status_v3_nd

**分层：** DWS（数据汇总层）
**主键：** `cspu_id` + `item_id` + `exp_tag`（联合唯一，分区内）
**分区：** `grass_region`（大区）/ `local_date`（业务日期）
**更新频率：** 每日调度（T+1）
**访问频次：** 218 次

---

## 业务描述

本表为搜推数仓**商品推荐替换（PB Recommend Replace）**场景下的状态汇总宽表，统计粒度为 **大区 × 日期 × (cspu_id, item_id, exp_tag)**。

核心业务场景：
- 记录每个 CSPU-Item 组合在不同实验 Tag（T1/T2）维度下的**探索状态**（`exploration_status`）与**剪枝标签**（`pruning_tag`），用于衡量推荐替换策略中各 CSPU-Item 对的质量分级（优选 / 非优选 / 探索中 / 待准备）。
- 汇总 Item 维度在各 Tag 下的**聚合探索状态**（`item_exploration_status`），支持 Item 级别的策略决策。
- 关联流量统计信息，提供探索曝光、探索点击、CSPU 曝光、CSPU 点击等**流量指标**，用于评估推荐替换效果。

适合回答的问题：
- 某大区某日，某 CSPU-Item 组合在 T1/T2 实验下的探索状态是什么？
- 哪些 Item 在指定日期已进入 preferred 状态，哪些仍处于 explore 阶段？
- 各剪枝标签（`pruning_tag`）下的曝光 / 点击流量分布如何？
- 不同版本日期（`version_date`）下 CSPU-Item 状态的变化趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `MY`、`TH` 等，所有查询必须指定此字段 |
| `local_date` | date | 业务日期，对应数据统计的本地日期，所有查询必须指定此字段 |

---

### 维度：实验与版本标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_tag` | string | 实验 Tag，取值为 `T1` 或 `T2`，表示不同的推荐替换实验分组；由 `all_cheapest` 视图通过 `explode(array('T1','T2'))` 展开生成 |
| `version_date` | int | 状态记录的版本日期，取自 dump 状态源或剪枝信息源（优先取 dump_status 的版本，不存在时取 pruning_info 的版本），用于追溯数据时效 |

---

### 维度：商品与 CSPU 标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（Color SKU Product Unit）唯一标识，推荐替换的最小商品规格维度 |
| `item_id` | bigint | Item（商品）唯一标识，CSPU 归属的父级商品 |

---

### 维度：探索状态与剪枝标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `pruning_tag` | string | CSPU-Item 组合的剪枝标签，优先取 dump_status 源，缺失时取 pruning_info 源；常见值：`obvious_good`（明显优质）、`obvious_bad`（明显劣质）、`can_not_explore`（不可探索）等 |
| `exploration_status` | string | CSPU 维度的探索状态，由 `pruning_tag` 与 `explore_status` 共同推断；取值：`preferred`（优选）、`non_preferred`（非优选）、`explore`（探索中）、`prepare`（待准备）。`pruning_tag` 优先级高于 `explore_status` |
| `item_exploration_status` | string | Item 维度的聚合探索状态，在同 `item_id` + `exp_tag` 下，按 `preferred > non_preferred > explore > prepare` 优先级取最高状态，用于 Item 级别决策 |

---

### 指标：流量统计

| 字段 | 类型 | 说明 |
|---|---|---|
| `explore_imp_cnt` | bigint | 当前 `exp_tag` 下的探索曝光次数，来源于 `traffic_statistic_infos['{exp_tag}_S_EXPLORE_impr']`；如 T1 对应 key 为 `T1_S_EXPLORE_impr` |
| `explore_click_cnt` | bigint | 当前 `exp_tag` 下的探索点击次数，来源于 `traffic_statistic_infos['{exp_tag}_S_EXPLORE_clk']` |
| `cspu_imp_cnt` | bigint | CSPU 维度的整体曝光次数，来源于 `traffic_statistic_infos['C1_S_UNSPECIFIED_impr']`，与 `exp_tag` 无关，在 T1/T2 行中数值一致 |
| `cspu_click_cnt` | bigint | CSPU 维度的整体点击次数，来源于 `traffic_statistic_infos['C1_S_UNSPECIFIED_clk']`，与 `exp_tag` 无关，在 T1/T2 行中数值一致 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，分区字段，不加该条件将触发全分区扫描，严重影响性能。
- **`local_date`**：必须指定，分区字段，建议指定具体日期或合理日期范围。

```sql
-- 示例
WHERE grass_region = 'MY'
  AND local_date = '2026-05-16'
```

### 不可直接 SUM 的字段

- **`cspu_imp_cnt` / `cspu_click_cnt`**：这两个字段在同一 `cspu_id + item_id` 下会因 `exp_tag` 展开为 T1、T2 两行，**直接 SUM 将导致数值翻倍**。若需汇总 CSPU 维度曝光/点击，须先按 `cspu_id + item_id` 去重或过滤 `exp_tag` 单值（如 `exp_tag = 'T1'`）后再聚合。
- **`explore_imp_cnt` / `explore_click_cnt`**：按 `exp_tag` 区分统计，跨 `exp_tag` 合计需明确业务含义，不建议跨 Tag 直接相加。
- **`item_exploration_status`**：聚合派生字段（Item 级最高优先级状态），不能直接用于计数加总，应作为维度过滤使用。
- **`version_date`**：版本号字段，不可做数值聚合运算。

### 时效性说明

- 表名后缀 `_nd` 表示**自然日（Natural Day）**快照表，每日全量覆写对应 `local_date` 分区。
- 数据 T+1 产出，`local_date` 分区对应前一业务日的状态快照。
- 剪枝信息（`pruning_info`）取当日最新小时分区（`max_pt` 动态获取），存在数据源小时级更新但本表仅保留每日一次调度结果的时效差异。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 提供当日所有 CSPU-Item 组合列表，作为全量 base 集合；按 `grass_region` + `local_date` 过滤 |
| `rcmd_feature.cheapest_v3_daily_status_info_df` | 提供 CSPU-Item 在各 `exp_tag` 下的 dump 状态，包含 `pruning_tag`、`explore_status`、`version_date` 及 `traffic_statistic_infos` 流量 map；按 `grass_region` + `grass_date` 过滤，并取 `version_date` 最新一条去重 |
| `srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_pruning_v3_hf` | 提供 CSPU-Item 的剪枝信息（`pruning_tag`、`version_date`），作为 dump 状态缺失时的补充；取当日最新小时分区数据 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf  ──┐
                                                             ├─► all_cheapest (CSPU x Item x T1/T2)
                                                             │
rcmd_feature.cheapest_v3_daily_status_info_df  ─────────────┤
   (row_number 去重取最新 version_date)                       ├─► dump_status (状态 + 流量)
                                                             │
dwd_sr_data_warehouse_pb_rcmd_replace_pruning_v3_hf  ───────┤
   (max_pt 取最新小时分区)                                    ├─► pruning_info (剪枝补充)
                                                             │
all_cheapest LEFT JOIN dump_status LEFT JOIN pruning_info  ──► tag_status (CSPU 粒度完整状态)
                                                             │
tag_status GROUP BY item_id + exp_tag  ─────────────────────► item_tag_status (Item 粒度聚合状态)
                                                             │
tag_status LEFT JOIN item_tag_status  ──────────────────────► INSERT OVERWRITE 目标表
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `all_cheapest` | 从维度表获取当日所有 CSPU-Item 组合，`explode(array('T1','T2'))` 展开为 T1/T2 两行，形成全量基础集合 |
| Step 2 | `dump_status` | 读取 Flink dump 的状态明细表，用 `row_number()` 按 `(exp_tag, item_id, cspu_id)` 分组、`version_date desc` 排序去重，取最新一条；推断 `exploration_status`（`pruning_tag` 优先于 `explore_status`）|
| Step 3 | `pruning_info` | 读取 DWD 剪枝表，取 `max_pt` 对应的最新小时分区数据，作为 dump 状态的补充来源 |
| Step 4 | `tag_status` | `all_cheapest` LEFT JOIN `dump_status` + `pruning_info`，合并 `pruning_tag`（coalesce）和 `exploration_status`（dump 优先，缺失时由 pruning_tag 推断），保留 `traffic_statistic_infos` map |
| Step 5 | `item_tag_status` | 在 `tag_status` 基础上按 `(item_id, exp_tag)` 分组，通过字符串拼接优先级前缀（`3#preferred` > `2#non_preferred` > `1#explore` > `0#prepare`）+ `max()` 取最高状态 |
| Step 6 | INSERT OVERWRITE | `tag_status` LEFT JOIN `item_tag_status`，展开 `traffic_statistic_infos` map 中的指定 key 为独立列，写入目标表对应 `(grass_region, local_date)` 分区 |

### 注意事项

- **Flink dump 重试导致的重复数据**：`rcmd_feature.cheapest_v3_daily_status_info_df` 存在因 Flink 实例重试写入多条的已知问题，ETL 已通过 `row_number()` 去重处理，但同一 `(exp_tag, item_id, cspu_id)` 仅保留最新 `version_date` 的一条，业务理解时需注意。
- **单 Writer，无多写风险**：该表仅有 1 个 ETL 文件写入，不存在多 Writer 分区冲突问题。
- **`cspu_imp_cnt` / `cspu_click_cnt` 跨 Tag 重复**：流量 map 中 `C1_S_UNSPECIFIED_impr/clk` 与 `exp_tag` 无关，T1 和 T2 两行写入相同值，聚合时需注意去重。
- **`pruning_info` 小时分区动态读取**：依赖 `data_infra.max_pt()` 函数获取最新小时分区，若上游小时级数据延迟将影响当日剪枝信息完整性。
- **`exploration_status` 推断逻辑优先级**：`pruning_tag` 的判断优先于原始 `explore_status`，业务分析时应以最终字段值为准，而非溯源原始 explore_status。

---

*文档生成时间：2026-05-17*