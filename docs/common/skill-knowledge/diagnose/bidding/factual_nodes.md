<!-- ads-workspace-gdoc-sync: gdoc_id=1ivvG-5JdFA_caV8zB5aaTnRbrpn27Oq5pNISn1HEOz0 gdoc_url=https://docs.google.com/document/d/1ivvG-5JdFA_caV8zB5aaTnRbrpn27Oq5pNISn1HEOz0/edit -->

# R4 出价调控策略异常归因节点/R4 Bidding Control Strategy Anomaly Attribution Nodes

> **Contributors**: luka.yang, songlei ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/bidding/factual_nodes.md)

---

本文件定义 R4（出价调控策略异常）的二级归因叶子节点，供 bidding subagent 使用。
一级 R4 定义见 `../overall/factual_nodes.md`。

节点分为两类：

- `R4.1-R4.10`：日级 UNION 指标节点，直接消费 `ads_union_key_metrics_daily__reg_s0_live` 的 campaign / ads 日聚合字段。
- `R4.20-R4.27`：15min `RegulationEvent` 选点证据节点，解释为什么选择某个 15min bucket。
- `R4.30.1-R4.30.7`：15min `RegulationEvent` 选点后归因节点，解释该事件 action chain 的首个异常模块。

---

### R4.1: 调控滑动窗口导致（超收方向）
- **检测**: `delta_cost_7 < 0` AND `SUM(delta_cost_6..delta_cost_1) > 0` AND `delta_cost_0 < 0`
- **公式**: `delta_cost = revenue_usd - advv_usd`（每天计算）
- **含义**: 7 天前的欠收导致滑动窗口累积偏差，当日补偿性超收
- **备注**: `role: direct`

### R4.2: 调控滑动窗口导致（欠收方向）
- **检测**: `delta_cost_7 > 0` AND `SUM(delta_cost_6..delta_cost_1) < 0` AND `delta_cost_0 > 0`
- **公式**: `delta_cost = revenue_usd - advv_usd`（每天计算）
- **含义**: 7 天前的超收导致滑动窗口累积偏差，当日补偿性欠收
- **备注**: `role: direct`

### R4.3: 数据收集异常（超收方向）
- **检测**: `revenue_usd_0 > 1.1 * ultra_core_rev_0` OR `1.1 * advv_usd_0 < ultra_core_advv_0`
- **含义**: 调控系统收集到的 revenue/advv 数据与实际偏差较大，导致出价判断失误
- **备注**: `role: direct`

### R4.4: 数据收集异常（欠收方向）
- **检测**: `revenue_usd_0 < 0.9 * ultra_core_rev_0` OR `0.9 * advv_usd_0 > ultra_core_advv_0`
- **含义**: 调控系统收集到的 revenue/advv 数据与实际偏差较大，导致出价判断失误
- **备注**: `role: direct`

### R4.5: 出价调控速度过慢（超收方向）
- **检测**: `final_coef_0 > 0.7` OR `final_coef_avg_7d > 1`
- **含义**: 超收场景下出价系数未能及时下调，调控反应不够快
- **备注**: `role: direct`

### R4.6: 出价调控速度过慢（欠收方向）
- **检测**: `final_coef_0 < 3` OR `final_coef_avg_7d < 2`
- **含义**: 欠收场景下出价系数未能及时上调，调控反应不够快
- **备注**: `role: direct`

### R4.7: MPC ROI 高估
- **检测**: `mpc_e_gmv_0 / mpc_e_cost_0 > (broad_gmv_usd_0 / revenue_usd_0) * 1.5`
- **含义**: MPC 模块预期的 ROI 显著高于实际 ROI，导致出价偏高
- **备注**: `role: direct`

### R4.8: MPC ROI 低估
- **检测**: `mpc_e_gmv_0 / mpc_e_cost_0 < (broad_gmv_usd_0 / revenue_usd_0) * 0.7`
- **含义**: MPC 模块预期的 ROI 显著低于实际 ROI，导致出价偏低
- **备注**: `role: direct`

### R4.9: 出价系数死亡螺旋 (Coef Death Spiral)
- **检测**: `final_coef` 连续 3 天以上持续下降且达到 < 0.5，或在 3 天内从 >1 跌至 <0.5
- **含义**: coef↓ → eCPM↓ → 竞价失败 → 最差广告位 → 零订单 → ROI 无定义 → 系统继续压低 coef → 自我强化循环
- **备注**: `role: direct`；不会自行恢复，需要外部干预（降低真实 target ROI / TROI，即 `target_roi_by_imp`、充值或手动重置 coef）

### R4.10: 出价系数死亡螺旋（反向）
- **检测**: `final_coef` 连续 3 天以上持续上升且达到 > 3
- **含义**: coef↑ → 出价过高 → 高 cost 低 ROI → 系统尝试补偿但过度
- **备注**: `role: direct`

---

## RegulationEvent 15min 选点与一级归因节点

本节定义出价 RCA 中 15min `RegulationEvent` 级别的事实节点，用于解释：

1. 为什么选择某个 15min bucket 作为代表事件。
2. 这个事件的 action chain 首个异常模块是什么。

事实来源是 `skills/team/04.product-algo/ads-bidding-coef-rca/scripts/select_regulation_event.py` 和 `skills/team/04.product-algo/ads-bidding-coef-rca/scripts/render_regulation_event_nodes.py`。节点只消费脚本输出，不在知识库里重新实现选择逻辑。

### 基础派生字段

`classify_first_abnormal_module()` 只把 `increase` 和 `decrease` 当作有效动作；`flat`、`unknown` 不参与需要明确方向的一级归因判断。

| Action | 含义 |
| --- | --- |
| `increase` | 升系数 |
| `decrease` | 降系数 |
| `flat` | 有数据但变化未过阈值 |
| `unknown` | 缺数据、缺上一桶，或 baseline 为 0 |

`ratio_action(ratio, target, tolerance)` 用于生成 `raw_expected_action`、`expected_action`、`pred_action` 和 future action。默认 `tolerance = 0.0`。

| 条件 | action |
| --- | --- |
| `ratio` 或 `target` 缺失 | `unknown` |
| `ratio < target - abs(target) * tolerance` | `decrease` |
| `ratio > target + abs(target) * tolerance` | `increase` |
| `abs(ratio - target) <= abs(target) * tolerance` | `flat` |

`delta_action(delta, baseline, min_abs_jump, min_rel_jump)` 用于生成 `mpc_action` 和 `final_action`。默认 `min_abs_jump = 0.5`、`min_rel_jump = 0.15`、`valid_history_min = 0.05`、`min_target_rel_shift = 0.05`。

| 条件 | action |
| --- | --- |
| `delta` 缺失、`baseline` 缺失，或 `abs(baseline) = 0` | `unknown` |
| `delta >= min_abs_jump` 或 `delta / abs(baseline) >= min_rel_jump` | `increase` |
| `delta <= -min_abs_jump` 或 `delta / abs(baseline) <= -min_rel_jump` | `decrease` |
| 有数据但未过阈值 | `flat` |

### R4.20: 应降反升 / Expected Decrease but Coef Increases
- **节点类型**: 选点证据
- **检测**:
  - `expected_action = 'decrease'`
  - 强跳变命中以下任一条件：
    - `max(delta_mpc_coef, delta_final_coef) >= min_abs_jump`
    - `max(relative_delta_mpc, relative_delta_final) >= min_rel_jump`
  - 命中强跳变时，脚本输出 `primary_anomaly = 'contrarian_coef_jump'`
  - 如果未达到强跳变，但 `mpc_action = 'increase'` 或 `final_action = 'increase'`，脚本输出 `primary_anomaly = 'wrong_direction_coef_increase'`
- **分数影响**: `contrarian_coef_jump` 为 `+60`，再按绝对跳变和相对跳变幅度加分；`wrong_direction_coef_increase` 为 `+40`
- **含义**: history 判断应该降系数，但 MPC 或 final coef 实际往上走，是超成本方向最强的代表事件候选。
- **关键证据字段**: `history_ratio`、`target_ratio`、`mpc_coef`、`final_coef`、`delta_mpc_coef`、`delta_final_coef`、`relative_delta_mpc`、`relative_delta_final`
- **备注**: `role: selection_evidence`

### R4.21: 应升反降 / Expected Increase but Coef Decreases
- **节点类型**: 选点证据
- **检测**:
  - `expected_action = 'increase'`
  - 强跳变命中以下任一条件：
    - `min(delta_mpc_coef, delta_final_coef) <= -min_abs_jump`
    - `min(relative_delta_mpc, relative_delta_final) <= -min_rel_jump`
  - 命中强跳变时，脚本输出 `primary_anomaly = 'contrarian_coef_drop'`
  - 如果未达到强跳变，但 `mpc_action = 'decrease'` 或 `final_action = 'decrease'`，脚本输出 `primary_anomaly = 'wrong_direction_coef_decrease'`
- **分数影响**: `contrarian_coef_drop` 为 `+60`，再按绝对跳变和相对跳变幅度加分；`wrong_direction_coef_decrease` 为 `+40`
- **含义**: history 判断应该升系数，但 MPC 或 final coef 实际往下走，是欠成本方向最强的代表事件候选。
- **关键证据字段**: `history_ratio`、`target_ratio`、`mpc_coef`、`final_coef`、`delta_mpc_coef`、`delta_final_coef`、`relative_delta_mpc`、`relative_delta_final`
- **备注**: `role: selection_evidence`

### R4.22: 应降但系数高位 / Expected Decrease but Coef Stays High
- **节点类型**: 选点证据
- **检测**:
  - `expected_action = 'decrease'`
  - 未命中 `contrarian_coef_jump`
  - 未命中 `wrong_direction_coef_increase`
  - `final_level_pct >= 0.8` 或 `mpc_level_pct >= 0.8`
  - 脚本输出 `primary_anomaly = 'persistent_high_coef'`
- **分数影响**: `+32`
- **含义**: 没有明显反向跳变，但当前系数仍处于全天或窗口内高分位，说明应降时仍维持高系数。
- **关键证据字段**: `expected_action`、`mpc_level_pct`、`final_level_pct`、`mpc_coef`、`final_coef`
- **备注**: `role: selection_evidence`

### R4.23: 应升但系数低位 / Expected Increase but Coef Stays Low
- **节点类型**: 选点证据
- **检测**:
  - `expected_action = 'increase'`
  - 未命中 `contrarian_coef_drop`
  - 未命中 `wrong_direction_coef_decrease`
  - `final_level_pct <= 0.2` 或 `mpc_level_pct <= 0.2`
  - 脚本输出 `primary_anomaly = 'persistent_low_coef'`
- **分数影响**: `+32`
- **含义**: 没有明显反向跳变，但当前系数仍处于全天或窗口内低分位，说明应升时仍维持低系数。
- **关键证据字段**: `expected_action`、`mpc_level_pct`、`final_level_pct`、`mpc_coef`、`final_coef`
- **备注**: `role: selection_evidence`

### R4.24: 搜索前预测动作与已回流数据相反（MPC data-transform）
- **节点类型**: 选点证据，可升级为主异常
- **检测**:
  - `expected_action in ('increase', 'decrease')`
  - `pred_action in ('increase', 'decrease')`
  - `expected_action != pred_action`
  - `anomaly_flags` 包含 `data_transform_mismatch`
  - 如果没有更强 coef 主异常，脚本输出 `primary_anomaly = 'data_transform_mismatch'`
- **分数影响**: 基础 `+15`；如果 `expected_action` 同时匹配本次 `--issue` 方向，再 `+15`
- **含义**: evaluator history 给出的期望动作与 search 前 best-state predicted 动作相反，支持后续一级归因为 `MPC data-transform`。
- **关键证据字段**: `history_ratio`、`target_ratio`、`pred_ratio`、`expected_action`、`pred_action`
- **备注**: `role: selection_evidence`

### R4.25: History 证据不足 / Cold Start or Missing History
- **节点类型**: 选点置信度标记
- **检测**:
  - `history_ratio` 缺失，或 `history_ratio < valid_history_min`
  - 默认 `valid_history_min = 0.05`
  - `anomaly_flags` 包含 `cold_start_or_missing_history`
- **分数影响**: `-20`
- **含义**: history 证据不足，只能作为置信度提醒，不直接作为根因节点。
- **关键证据字段**: `history_ratio`、`target_ratio`
- **备注**: `role: selection_evidence`

### R4.26: Issue 方向不匹配 / Opposite Issue Direction
- **节点类型**: 选点过滤标记
- **检测**:
  - `--issue over_cost` 时，期望 `expected_action = 'decrease'`
  - `--issue under_cost` 时，期望 `expected_action = 'increase'`
  - 当前 `expected_action` 与 issue 期望方向相反
  - `anomaly_flags` 包含 `opposite_issue_direction`
- **分数影响**: `-45`
- **含义**: 该 bucket 的系统期望方向与 case 类型相反，通常不适合作为代表事件。
- **关键证据字段**: `issue`、`expected_action`、`history_ratio`、`target_ratio`
- **备注**: `role: selection_evidence`

### R4.27: 系数方向一致 / Direction Consistent
- **节点类型**: 负向选点证据
- **检测**:
  - `expected_action in ('increase', 'decrease')`
  - `mpc_action = expected_action`
  - `final_action = expected_action`
  - `anomaly_flags` 包含 `direction_consistent`
- **分数影响**: `-10`
- **含义**: history 期望、MPC coef 和 final coef 方向一致，通常不支持继续归因为 bidding 模块异常。
- **关键证据字段**: `expected_action`、`mpc_action`、`final_action`
- **备注**: `role: selection_evidence`

### R4.30.1: 已回流数据口径改写调控动作（History preprocessing）
- **节点类型**: 一级归因
- **检测**:
  - `raw_expected_action in ('increase', 'decrease')`
  - `expected_action in ('increase', 'decrease')`
  - `raw_expected_action != expected_action`
  - 脚本输出 `first_abnormal_module = 'History preprocessing'`
- **含义**: raw today history 和 evaluator history 给出相反动作，说明 history preprocessing 改写了系统判断方向。
- **关键证据字段**: `raw_history_ratio`、`history_ratio`、`target_ratio`、`raw_expected_action`、`expected_action`
- **备注**: `role: direct`

### R4.30.2: 目标值变化导致调控动作反向（Target）
- **节点类型**: 一级归因
- **检测**:
  - `target_ratio` 和 `prev_target_ratio` 都非空
  - `abs(target_ratio - prev_target_ratio) / abs(prev_target_ratio) >= min_target_rel_shift`
  - `prev_expected_action in ('increase', 'decrease')`
  - `expected_action in ('increase', 'decrease')`
  - `prev_expected_action != expected_action`
  - 脚本输出 `first_abnormal_module = 'Target'`
- **含义**: target ratio 变化足够大，并导致 expected action 翻转。
- **关键证据字段**: `prev_target_ratio`、`target_ratio`、`prev_expected_action`、`expected_action`
- **备注**: `role: direct`

### R4.30.3: 搜索前预测动作与已回流数据相反（MPC data-transform）
- **节点类型**: 一级归因
- **检测**:
  - `expected_action in ('increase', 'decrease')`
  - `pred_action in ('increase', 'decrease')`
  - `expected_action != pred_action`
  - 脚本输出 `first_abnormal_module = 'MPC data-transform'`
- **二级提示**:
  - `future_action_before_feedback != expected_action`：`mpc_issue_type = 'MPC data-transform: model_raw_prediction'`
  - `future_action_before_feedback = expected_action` 且 `future_action_after_feedback != expected_action`：`mpc_issue_type = 'MPC data-transform: delayed_feedback'`
  - `future_action_after_feedback != expected_action` 但 before-feedback 字段缺失：`mpc_issue_type = 'MPC data-transform: before-feedback evidence missing'`
  - 只有 best-state total ratio 冲突但 future 证据不足：`mpc_issue_type = 'MPC data-transform: original/final evidence insufficient'`
- **含义**: search 前 best-state predicted 方向已经和 history expected 方向冲突。
- **关键证据字段**: `history_ratio`、`target_ratio`、`pred_ratio`、`future_ratio_before_feedback`、`future_ratio_after_feedback`、`expected_action`、`pred_action`
- **备注**: `role: direct`

### R4.30.4: MPC 搜索选系数异常（MPC search）
- **节点类型**: 一级归因
- **检测**:
  - `expected_action in ('increase', 'decrease')`
  - `pred_action = expected_action`
  - `mpc_action in ('increase', 'decrease')`
  - `mpc_action != pred_action`
  - 脚本输出 `first_abnormal_module = 'MPC search'`
- **含义**: best-state predicted 方向正常，但 raw MPC coef 选择方向反了。
- **关键证据字段**: `expected_action`、`pred_action`、`mpc_action`、`mpc_coef`、`delta_mpc_coef`、`relative_delta_mpc`
- **备注**: `role: direct`

### R4.30.5: 后处理或输出改写异常（Post / Output）
- **节点类型**: 一级归因
- **检测**:
  - `expected_action in ('increase', 'decrease')`
  - `pred_action = expected_action`
  - `mpc_action = pred_action`
  - `final_action != mpc_action`
  - 脚本输出 `first_abnormal_module = 'Post / Output'`
- **含义**: raw MPC coef 方向正常，但 final coef 被后处理、step control 或输出链路改反、压住或变成未知。
- **关键证据字段**: `expected_action`、`pred_action`、`mpc_action`、`final_action`、`mpc_coef`、`final_coef`、`delta_final_coef`、`relative_delta_final`
- **备注**: `role: direct`

### R4.30.6: 曲线与系数方向一致（direction consistent）
- **节点类型**: 非异常结论
- **检测**:
  - `expected_action in ('increase', 'decrease')`
  - `expected_action = pred_action = mpc_action = final_action`
  - 脚本输出 `first_abnormal_module = 'direction consistent'`
- **含义**: history、best-state、MPC 和 final output 方向一致，不支持继续写模块异常。
- **关键证据字段**: `expected_action`、`pred_action`、`mpc_action`、`final_action`
- **备注**: `role: non_anomaly`

### R4.30.7: 需要补充 trace 明细（needs detail）
- **节点类型**: 证据不足
- **检测**:
  - 未命中 R4.30.1 到 R4.30.6
  - 脚本输出 `first_abnormal_module = 'needs detail'`
- **含义**: 15min bucket 级 action chain 不足以定位首个异常模块，需要进入 trace detail 或停止给出一级模块结论。
- **关键证据字段**: `module_reason`、action chain 全字段、缺失字段列表
- **备注**: `role: insufficient_evidence`

### RegulationEvent 输出要求

节点输出建议与 selector 结果保持同源，每个命中节点至少保留：

| 字段 | 说明 |
| --- | --- |
| `node_id` | 例如 `R4.20`、`R4.30.3` |
| `node_type` | `selection_evidence`、`l1_attribution`、`non_anomaly`、`insufficient_evidence` |
| `status` | `hit`、`not_hit`、`insufficient_evidence`、`not_applicable` |
| `role` | 对一级归因节点使用 `direct`；选点证据节点使用 `selection_evidence` |
| `bucket_15m` | selector 选中的事件时间 |
| `strategy_name` | selector 分组策略名 |
| `primary_anomaly` | selector 输出的主异常形态 |
| `anomaly_flags` | selector 输出的辅助标记 |
| `first_abnormal_module` | selector 输出的一级模块 |
| `evidence` | 触发该节点的字段和值 |

不要只输出节点 ID。`R4.20` 和 `R4.21` 必须带上 delta / relative delta 或 action 证据；`R4.30.3` 必须带上 `expected_action`、`pred_action` 和 ratio 证据。

---
