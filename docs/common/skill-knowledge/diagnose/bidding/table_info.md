<!-- ads-workspace-gdoc-sync: gdoc_id=1hlAc9bGImSlbj2sjhkF7CBn3OkUKwZcOEcUEpPOwcXY gdoc_url=https://docs.google.com/document/d/1hlAc9bGImSlbj2sjhkF7CBn3OkUKwZcOEcUEpPOwcXY/edit -->

# R4 出价调控策略异常 — 相关表和字段定义/R4 Bidding Control Strategy — Table & Field Definitions

> **Contributors**: luka.yang, songlei ｜ **最后更新**：2026-05-29 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/bidding/table_info.md)

---

本文件定义 R4（出价调控策略异常）归因所需的表和字段信息。完整表定义见 `../overall/table_info.md`。

数据来源表：`mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live`（ClickHouse）

> **约定说明**:
> - `_0` = 诊断日，`_1` = 前一天，... `_7` = 7 天前
> - `_7d` 后缀表示最近 7 天聚合
> - 金额类字段在上游 `perf` 表中为本地币*100000，产出时除以 `exchange_rate` 转为 USD

---

## 核心效果指标/Core Performance Metrics

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `revenue_usd` | double | Gross Revenue, 广告收入 (USD) |
| `advv_usd` | double | 到达口径的预期消耗 (USD), advv = broad_gmv_amt_usd * target_cir |
| `broad_gmv_usd` | double | Broad 口径 GMV (USD), 同 shop 下单订单 |

---

## 核心效果指标（近 7 日）/Core Performance Metrics (Last 7 Days)

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `revenue_usd_7d` | double | 近 7 日广告收入 (USD) |
| `advv_usd_7d` | double | 近 7 日广告主价值 (USD) |

---

## 出价系数字段/Bidding Coefficient Fields

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `coef_sum_by_imp` | double | PID 系数之和（按曝光） |
| `coef_min_by_imp` | double | PID 系数最小值 |
| `coef_max_by_imp` | double | PID 系数最大值 |
| `final_coef` | double | 最终系数（来源 static_ads_info_metrics） |

---

## ROI 与竞价策略字段/ROI and Bidding Strategy Fields

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `target_roi` | double | ROI 下限/配置值（即 `idx_target_roi`），不代表真实 TROI |
| `target_roi_by_imp` | double | 真实 target ROI / TROI 日均值，按曝光加权计算：`troi_sum_by_imp / ads_imp`（要求 `ads_imp > 0`） |
| `idx_roi_upperbound` | double | ROI 上界 (Simple 模式), 非 NULL 表示 Simple 模式 |
| `ultra_core_rev` | double | Ultra Core 收集到的 gross rev (USD) |
| `ultra_core_advv` | double | Ultra Core 收集到的 advv (USD) |
| `mpc_e_gmv` | double | MPC 预期 GMV (USD) |
| `mpc_e_cost` | double | MPC 预期 Cost (USD) |

---

## R4 常用衍生指标/R4 Common Derived Metrics

| 衍生指标 | 计算公式 | 用途 |
|----------|----------|------|
| delta_cost | `revenue_usd - advv_usd`（每天计算） | R4.1/R4.2 滑动窗口检测 |
| cost_ratio_1d | `revenue_usd_0 / advv_usd_0` | 超收/欠收判定 |
| cost_ratio_7d | `SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)` | 超收/欠收判定 |
| ROI (宽口径) | `broad_gmv_usd / revenue_usd` | R4.7/R4.8 MPC ROI 对比 |
| MPC 预期 ROI | `mpc_e_gmv / mpc_e_cost` | R4.7/R4.8 检测 |
| 真实 target ROI / TROI | `troi_sum_by_imp / ads_imp` | TROI 变化、出价策略上下文判断 |
| 平均 PID 系数 | `coef_sum_by_imp / ads_imp` | 系数趋势分析 |
| final_coef 日均值 | `AVG(final_coef)` 近 7 天 | R4.5/R4.6/R4.9/R4.10 检测 |

---

## RegulationEvent Selector 输出字段

R4.20-R4.27 与 R4.30.1-R4.30.7 使用 `select_regulation_event.py` 的输出，不直接消费日级 union 表字段。字段来自 `regulation_event_selection.json` / `embedded_l1_selection.json` 和对应 candidates CSV，节点映射由 `render_regulation_event_nodes.py` 生成。

### 事件标识字段

| 字段 | 类型 | 口径说明 |
| --- | --- | --- |
| `bucket_15m` | string / timestamp | selector 选中的 15min 调控事件时间 |
| `strategy_name` | string | selector 分组使用的策略名 |
| `row_cnt` | double | 该 bucket 聚合到的 trace 行数 |
| `score` | double | selector 排序分数，只用于选代表事件 |

### 选点原因字段

| 字段 | 类型 | 口径说明 |
| --- | --- | --- |
| `primary_anomaly` | string | 当前 bucket 最主要的选点异常形态，例如 `contrarian_coef_jump`、`persistent_low_coef` |
| `anomaly_flags` | string | 以 `|` 分隔的辅助标记，例如 `data_transform_mismatch|cold_start_or_missing_history` |
| `reason` | string | selector 生成的可读选点解释 |

### Action chain 字段

| 字段 | 类型 | 口径说明 |
| --- | --- | --- |
| `raw_expected_action` | string | raw today history vs target 得到的期望动作 |
| `expected_action` | string | evaluator history vs target 得到的期望动作 |
| `pred_action` | string | best-state predicted ratio vs target 得到的动作 |
| `future_action_before_feedback` | string | feedback 前 future ratio vs target 得到的动作；可为空 |
| `future_action_after_feedback` | string | feedback 后 future ratio vs target 得到的动作；可为空 |
| `mpc_action` | string | raw MPC coef 相对上一桶的动作 |
| `final_action` | string | final coef 相对上一桶的动作 |

Action 取值为 `increase`、`decrease`、`flat`、`unknown`。一级归因只把 `increase` 和 `decrease` 作为明确方向。

### Ratio 与 coef 证据字段

| 字段 | 类型 | 口径说明 |
| --- | --- | --- |
| `history_ratio` | double | evaluator history `advv/cost` |
| `raw_history_ratio` | double | raw today history `advv/cost` |
| `target_ratio` | double | adjusted target ratio |
| `pred_ratio` | double | best-state predicted `advv/cost` |
| `future_ratio_before_feedback` | double | feedback 前 future `advv/cost`；可为空 |
| `future_ratio_after_feedback` | double | feedback 后 future `advv/cost`；可为空 |
| `mpc_coef` | double | raw MPC / best coef |
| `final_coef` | double | 最终生效 coef |
| `delta_mpc_coef` | double | 当前 `mpc_coef` 减上一桶 `mpc_coef` |
| `delta_final_coef` | double | 当前 `final_coef` 减上一桶 `final_coef` |
| `relative_delta_mpc` | double | `delta_mpc_coef / abs(prev_mpc_coef)` |
| `relative_delta_final` | double | `delta_final_coef / abs(prev_final_coef)` |
| `mpc_level_pct` | double | `mpc_coef` 在当前 pattern 内的分位 |
| `final_level_pct` | double | `final_coef` 在当前 pattern 内的分位 |

### 一级归因字段

| 字段 | 类型 | 口径说明 |
| --- | --- | --- |
| `first_abnormal_module` | string | selector 输出的一级模块：`History preprocessing`、`Target`、`MPC data-transform`、`MPC search`、`Post / Output`、`direction consistent`、`needs detail` |
| `module_reason` | string | 一级模块命中的可读原因 |
| `mpc_issue_type` | string | `MPC data-transform` / `MPC search` 的二级提示；不等于完整二级 RCA |
| `mpc_issue_reason` | string | `mpc_issue_type` 的可读原因 |

### 节点输出字段

`render_regulation_event_nodes.py` 从 selector 输出生成 `factual_node_hits.jsonl`。

| 字段 | 类型 | 口径说明 |
| --- | --- | --- |
| `node_id` | string | R4.20-R4.27 或 R4.30.1-R4.30.7 节点 ID |
| `node_name` | string | 节点名称 |
| `node_type` | string | `selection_evidence`、`l1_attribution`、`non_anomaly`、`insufficient_evidence` |
| `status` | string | `hit` 或 `insufficient_evidence` |
| `role` | string | `selection_evidence`、`direct`、`non_anomaly`、`insufficient_evidence` |
| `evidence` | object | 触发该节点的 selector 字段和值 |
