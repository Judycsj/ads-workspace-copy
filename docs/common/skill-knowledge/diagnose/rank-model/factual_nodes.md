<!-- ads-workspace-gdoc-sync: gdoc_id=1xQOZmrd52LQf5cGJh6_VROIIQEnpCwWW78Md--ISPvE gdoc_url=https://docs.google.com/document/d/1xQOZmrd52LQf5cGJh6_VROIIQEnpCwWW78Md--ISPvE/edit -->

# R3 模型预估异常归因节点/R3 Model Estimation Anomaly Attribution Nodes

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-23 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/rank-model/factual_nodes.md)

---

本文件定义 R3（模型预估异常）的二级及以下归因节点，供 rank-model subagent 使用。
一级 R3 定义见 `../overall/factual_nodes.md`。

下方所有 node 都必须按 `分子字段 / 分母字段` 计算；分母为 0、字段为空或源数据缺失时，该 node 输出 `N/A`，不能用其他字段替代。
字段含义、源表、聚合口径与逻辑字段定义统一见 `agents/common/ads-diagnose-model-deepdive-hb.md` 的“字段含义专表”。

## 方向过滤规则/Direction Filtering Rules

R3 模型预估异常必须按主异常方向过滤后再计入一级模块归因：

- **超收方向**（A1/A3/B1/B3）：只将 `pcoc_direction = 高估` 的节点计入 R3 命中；低估节点即使超过阈值，也只能作为方向不匹配旁证
- **欠收方向**（A2/A4/B2/B4）：只将 `pcoc_direction = 低估` 的节点计入 R3 命中；高估节点即使超过阈值，也只能作为方向不匹配旁证
- **无固定方向的节点**（如 R3.4.1）只有在能解释当前主异常方向时才计入

## 通用计算规则/General Calculation Rules

- PCOC 类 node 统一表示预测值 / 真实值；`sum(分子字段) / nullIf(sum(分母字段), 0) < 0.8` 为低估，`> 1.2` 为高估。
- ratio 类 node 使用 `sum(分子字段) / nullIf(sum(分母字段), 0)`；目前仅 R3.4.1 使用，阈值为 `> 0.05`。
- feedback 类 node 的分子/分母是逻辑字段，按 `ads-diagnose-model-deepdive-hb.md` 的“字段含义专表”先聚合构造，再执行两个字段相除。

## pGMV 层级关系/pGMV Hierarchy

R3.1 pGMV 归因必须按层级编号和使用，不能把点击归因口径与到达口径并列为同一层原因：

- `R3.1.3-R3.1.5` 是二级到达口径指标，用于定位当天、昨天、2-7 天点击中哪个到达段贡献整体 pGMV 偏差。
- `R3.1.3.x/R3.1.4.x/R3.1.5.x` 是三级点击归因拆解指标，只能挂靠在对应的二级到达口径指标下，用于解释该到达段内 final、cali、model、feedback 机制。
- 最终结论应先给出二级到达口径主因，再给出其下命中的三级点击归因拆解；点击归因节点不能单独替代二级到达口径主因。

| 二级到达口径父节点 | 三级点击归因拆解节点 | 点击日期分区 |
| --- | --- | --- |
| `R3.1.3` 当天点击到达 | `R3.1.3.1-R3.1.3.5` 当天点击归因 | `grass_date = D` |
| `R3.1.4` 昨天点击到达 | `R3.1.4.1-R3.1.4.5` 昨天点击归因 | `grass_date = D - 1` |
| `R3.1.5` 2-7 天点击到达 | `R3.1.5.1-R3.1.5.5` 2-7 天点击归因 | `grass_date BETWEEN D - 7 AND D - 2` |

---

## R3.1 pGMV PCOC 偏差/pGMV PCOC Deviation

### R3.1.1: UniCR 覆盖场景 final_pgmv PCOC
- **检测**: `scene_group = 'unicr_covered'`，`sum(daily_pgmv_sum_last_7d_clk) / sum(broad_gmv_usd)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: UniCR 覆盖场景最终 pGMV 相对实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `daily_pgmv_sum_last_7d_clk`，分母字段 `broad_gmv_usd`；影响大小看 `pcoc_bias_impact_ratio`

### R3.1.2: UniCR 未覆盖 / other 场景 final_pgmv PCOC
- **检测**: `scene_group = 'other'`，`sum(daily_pgmv_sum_last_7d_clk) / sum(broad_gmv_usd)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: UniCR 未覆盖或 other 场景最终 pGMV 相对实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `daily_pgmv_sum_last_7d_clk`，分母字段 `broad_gmv_usd`；只使用 union 表，不用 `unipgmv_item_data_daily_ck` 解释 other 场景

**二级到达口径指标（R3.1.3-R3.1.5）**：用于定位点击年龄段对目标到达日 `D` pGMV 偏差的贡献。

### R3.1.3: 当天点击到达 pgmv_pcoc
- **检测**: `click_age_bucket = '0d_today_click'`，`sum(arrive_pred_gmv_sum_clk_0d) / sum(arrive_conv_gmv_sum_clk_0d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: UniCR 覆盖入口内，当天点击在今天到达口径的预测 GMV 相对实际到达 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `arrive_pred_gmv_sum_clk_0d`，分母字段 `arrive_conv_gmv_sum_clk_0d`；到达口径只查目标到达日 `D` 分区，并限制 `entrance_group IN ('SEARCH', 'DD', 'YMAL', 'PP')`

### R3.1.4: 昨天点击到达 pgmv_pcoc
- **检测**: `click_age_bucket = '1d_yesterday_click'`，`sum(arrive_pred_gmv_sum_clk_1d) / sum(arrive_conv_gmv_sum_clk_1d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: UniCR 覆盖入口内，昨天点击在今天到达口径的预测 GMV 相对实际到达 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `arrive_pred_gmv_sum_clk_1d`，分母字段 `arrive_conv_gmv_sum_clk_1d`；用于识别延迟一天到达偏差

### R3.1.5: 2-7 天点击到达 pgmv_pcoc
- **检测**: `click_age_bucket = '2_7d_old_click'`，`sum(arrive_pred_gmv_sum_clk_2_7d) / sum(arrive_conv_gmv_sum_clk_2_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: UniCR 覆盖入口内，2-7 天点击在今天到达口径的预测 GMV 相对实际到达 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `arrive_pred_gmv_sum_clk_2_7d`，分母字段 `arrive_conv_gmv_sum_clk_2_7d`；与整体偏差同向且 `pcoc_bias_impact_ratio` 最大的段优先作为主因

**三级点击归因拆解指标（R3.1.3.x/R3.1.4.x/R3.1.5.x）**：用于在已定位的二级到达段下继续拆解机制；输出时必须挂靠到对应到达段。

### R3.1.3.1: 当天点击归因 final_pgmv_pcoc
- **检测**: `click_age_bucket = '0d_today_click'`，`sum(click_has_score_final_pgmv_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 当天点击在点击归因口径下，最终 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_final_pgmv_sum`，分母字段 `click_has_score_broad_gmv_7d`；点击归因口径查 `grass_date = D`

### R3.1.3.2: 当天点击归因 cali_pgmv_pcoc
- **检测**: `click_age_bucket = '0d_today_click'`，`sum(click_has_score_cali_broad_pgmv_7d_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 当天点击在点击归因口径下，校准后 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_cali_broad_pgmv_7d_sum`，分母字段 `click_has_score_broad_gmv_7d`；raw model 未明显偏差但该节点同向时，机制更像 calibration

### R3.1.3.3: 当天点击归因 model_pgmv_pcoc
- **检测**: `click_age_bucket = '0d_today_click'`，`sum(click_has_score_broad_pgmv_7d_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 当天点击在点击归因口径下，模型原始 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_broad_pgmv_7d_sum`，分母字段 `click_has_score_broad_gmv_7d`；同向时机制优先判断为 raw model

### R3.1.3.4: 当天点击归因 feedback_1h_pcoc
- **检测**: `click_age_bucket = '0d_today_click'`，`click_pred_feedback_rate_1h / click_actual_feedback_rate_1h`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 当天点击在点击归因口径下，预测 1h GMV 回流率相对真实 1h GMV 回流率的偏差
- **备注**: `role: amplifier`；分子字段 `click_pred_feedback_rate_1h`，分母字段 `click_actual_feedback_rate_1h`；两个字段均为逻辑字段；用于判断 early feedback

### R3.1.3.5: 当天点击归因 feedback_24h_pcoc
- **检测**: `click_age_bucket = '0d_today_click'`，`click_pred_feedback_rate_24h / click_actual_feedback_rate_24h`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 当天点击在点击归因口径下，预测 24h GMV 回流率相对真实 24h GMV 回流率的偏差
- **备注**: `role: amplifier`；分子字段 `click_pred_feedback_rate_24h`，分母字段 `click_actual_feedback_rate_24h`；两个字段均为逻辑字段；用于判断 delayed feedback

### R3.1.4.1: 昨天点击归因 final_pgmv_pcoc
- **检测**: `click_age_bucket = '1d_yesterday_click'`，`sum(click_has_score_final_pgmv_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 昨天点击在点击归因口径下，最终 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_final_pgmv_sum`，分母字段 `click_has_score_broad_gmv_7d`；点击归因口径查 `grass_date = D - 1`

### R3.1.4.2: 昨天点击归因 cali_pgmv_pcoc
- **检测**: `click_age_bucket = '1d_yesterday_click'`，`sum(click_has_score_cali_broad_pgmv_7d_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 昨天点击在点击归因口径下，校准后 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_cali_broad_pgmv_7d_sum`，分母字段 `click_has_score_broad_gmv_7d`；机制更像 calibration

### R3.1.4.3: 昨天点击归因 model_pgmv_pcoc
- **检测**: `click_age_bucket = '1d_yesterday_click'`，`sum(click_has_score_broad_pgmv_7d_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 昨天点击在点击归因口径下，模型原始 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_broad_pgmv_7d_sum`，分母字段 `click_has_score_broad_gmv_7d`；机制优先判断为 raw model

### R3.1.4.4: 昨天点击归因 feedback_1h_pcoc
- **检测**: `click_age_bucket = '1d_yesterday_click'`，`click_pred_feedback_rate_1h / click_actual_feedback_rate_1h`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 昨天点击在点击归因口径下，预测 1h GMV 回流率相对真实 1h GMV 回流率的偏差
- **备注**: `role: amplifier`；分子字段 `click_pred_feedback_rate_1h`，分母字段 `click_actual_feedback_rate_1h`；两个字段均为逻辑字段；用于判断 early feedback

### R3.1.4.5: 昨天点击归因 feedback_24h_pcoc
- **检测**: `click_age_bucket = '1d_yesterday_click'`，`click_pred_feedback_rate_24h / click_actual_feedback_rate_24h`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 昨天点击在点击归因口径下，预测 24h GMV 回流率相对真实 24h GMV 回流率的偏差
- **备注**: `role: amplifier`；分子字段 `click_pred_feedback_rate_24h`，分母字段 `click_actual_feedback_rate_24h`；两个字段均为逻辑字段；用于判断 delayed feedback

### R3.1.5.1: 2-7 天点击归因 final_pgmv_pcoc
- **检测**: `click_age_bucket = '2_7d_old_click'`，`sum(click_has_score_final_pgmv_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 2-7 天点击在点击归因口径下，最终 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_final_pgmv_sum`，分母字段 `click_has_score_broad_gmv_7d`；点击归因口径查 `grass_date BETWEEN D - 7 AND D - 2`

### R3.1.5.2: 2-7 天点击归因 cali_pgmv_pcoc
- **检测**: `click_age_bucket = '2_7d_old_click'`，`sum(click_has_score_cali_broad_pgmv_7d_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 2-7 天点击在点击归因口径下，校准后 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_cali_broad_pgmv_7d_sum`，分母字段 `click_has_score_broad_gmv_7d`；机制更像 calibration

### R3.1.5.3: 2-7 天点击归因 model_pgmv_pcoc
- **检测**: `click_age_bucket = '2_7d_old_click'`，`sum(click_has_score_broad_pgmv_7d_sum) / sum(click_has_score_broad_gmv_7d)`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 2-7 天点击在点击归因口径下，模型原始 pGMV 相对 7 天实际 GMV 的偏差
- **备注**: `role: amplifier`；分子字段 `click_has_score_broad_pgmv_7d_sum`，分母字段 `click_has_score_broad_gmv_7d`；机制优先判断为 raw model

### R3.1.5.4: 2-7 天点击归因 feedback_1h_pcoc
- **检测**: `click_age_bucket = '2_7d_old_click'`，`click_pred_feedback_rate_1h / click_actual_feedback_rate_1h`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 2-7 天点击在点击归因口径下，预测 1h GMV 回流率相对真实 1h GMV 回流率的偏差
- **备注**: `role: amplifier`；分子字段 `click_pred_feedback_rate_1h`，分母字段 `click_actual_feedback_rate_1h`；两个字段均为逻辑字段；用于判断 early feedback

### R3.1.5.5: 2-7 天点击归因 feedback_24h_pcoc
- **检测**: `click_age_bucket = '2_7d_old_click'`，`click_pred_feedback_rate_24h / click_actual_feedback_rate_24h`；`< 0.8` 为低估，`> 1.2` 为高估
- **含义**: 2-7 天点击在点击归因口径下，预测 24h GMV 回流率相对真实 24h GMV 回流率的偏差
- **备注**: `role: amplifier`；分子字段 `click_pred_feedback_rate_24h`，分母字段 `click_actual_feedback_rate_24h`；两个字段均为逻辑字段；用于判断 delayed feedback

---

## R3.2 pCTR PCOC 偏差/pCTR PCOC Deviation

### R3.2.1: pCTR PCOC 高估（超收方向）
- **检测**: `sum(pctr_sum_by_imp) / sum(ads_clk) > 1.2`
- **含义**: 模型高估 CTR，导致出价偏高
- **备注**: `role: amplifier`；分子字段 `pctr_sum_by_imp`，分母字段 `ads_clk`

### R3.2.2: pCTR PCOC 低估（欠收方向）
- **检测**: `sum(pctr_sum_by_imp) / sum(ads_clk) < 0.8`
- **含义**: 模型低估 CTR，导致出价偏低
- **备注**: `role: amplifier`；分子字段 `pctr_sum_by_imp`，分母字段 `ads_clk`

---

## R3.4 模型预估失败/Model Estimation Failure

### R3.4.1: 模型预估失败率高
- **检测**: `sum(pcr_direct_fail_imp_cnt) / sum(ads_imp) > 0.05`
- **含义**: 大量曝光缺少 pCR 预估值，导致出价不准
- **备注**: `role: amplifier`；分子字段 `pcr_direct_fail_imp_cnt`，分母字段 `ads_imp`；无固定方向，需结合主异常方向判断
