# 跨层联合分析/Cross-Layer Joint Analysis

两个实验分别在**不同的正交叠加层**（overlapping orthogonal layers）时，分析某个 `(层A桶 × 层B桶)` 组合格的联合/交互效果。范例：模型层 × 选券策略层（2026-06-22 cr_uplift × KP10 选券目标）。本文是 playbook，落地仍走 spoke `ads-roi3-experiment-analysis` 出报告（按 `report-skeleton.md`）。

## 0. 何时用/When to use

- 两实验在**不同 AB 层**、**正交分流**（独立随机叠加，scene 内多层）。
- 要的不是"某层的平均效果"，而是**特定组合格** vs **prod 默认组合**的效果（如 max-ecpm×新模型 vs max-advv×旧模型）。
- ⚠️ AB 平台单实验报表给的是"对本层的平均"（**跨另一层 blended**），**不能**当组合格读——这是最常见的误读。

## 1. Step 0 正交性与层确认/Confirm orthogonality & layers（前置硬步骤）

像"系数复合确认"一样先问清，否则全错：
- 查 scene + 每层 `layer_id`，确认两层**正交**（独立分流）。
- 取每层桶号 + 流量份额%。
- **组合格流量 = 两层份额相乘**（例：10%×10%=1%；base 20%×20%=4%）。组合格通常很小（1% 级），噪声大，需多满日。

## 2. 显式定义组合格/Define cross cells explicitly

- **Treatment 格** = 层A实验桶 × 层B实验桶（每个目标组合一格）。
- **Base 格** = 层A base × 层B base = **prod 默认组合**（关键：不是任一单层的 base，是两层都取 base 的那块）。
- 每格列出桶集合 + 标流量%。报告里把"到底多少流量在对比"写清楚。

## 3. 取数两路/Two data paths（都走 DataSuite）

ab_sign（=signature）串接**所有层**的桶号 `|...|A|...|B|...|`，故广告侧可直接两层 LIKE 交叉；但全订单无 ab_sign，须走分流日志。

| 指标族 | 表 | 分桶方式 |
|---|---|---|
| 广告侧 rev / advv / broad_gmv / 曝光·点击·订单 | perf `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | `ab_sign LIKE '%\|A\|%' AND ab_sign LIKE '%\|B\|%'` |
| 全盘 platform_gmv(_995) / 券成本 / 全订单 | 分流日志 `srdi_mart.dim_sr_data_warehouse_abtest_user_group`（project Ads / `is_assignment_log=1`）按 `user_id` 两层交叉 → join 订单 `mp_paidads.dwd_unified_order_event_hi__reg_s0_live`（**order 粒度**，别用 ods_log 行级会超时） | 见下「为什么必须 split-log」 |

**为什么全盘 GMV 必须 split-log**：unified order **没有全订单 ab_sign**，`voucher_click_context` 只落在 ads 券订单上（有选择偏差，test 兑券率高→base 大量平台券-only 订单隐形）。全盘跨臂只能用分流日志按 user_id 分桶。advv 用 P0 口径：`IF(pricing_type IN (1,2,3,13,16), expenditure_amt_usd, broad_gmv_amt_usd*target_cir)`。

## 4. 打平流量/Traffic-equalize（最关键，最易错）

- **分母 = 分流日志的实际分桶用户数**（exogenous 随机化单位）。`uplift = (T_metric/T_users)/(BASE_metric/BASE_users) − 1`。
- **绝不用曝光/点击/订单打平**——它们是被处理影响的 outcome（模型/策略会改曝光，如模型 ON 每用户多服务曝光），拿它当分母等于把效果除掉、能翻转结论。【2026-06-22 踩过：曝光打平把 rev 真实 +2.2% 假掉成 −1.7%，把"过"误判成"挂"。】
- **SRM 自检**：用户比 ≈ 设计份额比（如 4.0）→ 分流干净；偏离大 → 见 §5。

## 5. 抽干格剔除/Drop drained cells

某格用户数/曝光数比远偏设计（如 12 vs 4）= 被抽干 / rebalance（流量被挪走）→ **弃用并标注**，不要当有效组。组合格小，单格被抽干很常见。

## 6. 隔离 vs 捆绑/Isolation caveat

- 组合格 vs base 是 **A×B 联合变化**，不是单层净效应。
- 要隔离某层效应：**把另一层桶固定、只变目标层**（例：T1=689153×exp vs T3=689156×exp，两格同模型只差策略 → 干净隔离"GMV 权重"效应）。
- 报告必写**隔离了什么、没隔离什么**（如"模型纯效应未隔离，需补 模型exp×策略base 格"）。

## 7. 指标 + VPR + 稳健性/Metrics, VPR, robustness

- 全账：rev / advv / broad_gmv / platform_gmv_995 / 券成本 / VPR，**双栏**（打平绝对值 + 相对%，见 `report-skeleton.md` 指标表标准格式）。
- **噪声指标做敏感性**：platform_gmv 原始 AA ~±1.5%，把"GMV 项当 0"再算一遍 VPR——若结论靠噪声级 GMV 撑（如 VPR 含GMV +5%、当0则 −4%）则判"脆"，不能下正结论。
- 涉及新模型/变体 → **必出 pcoc 三件套**（硬规则，见 `report-skeleton.md`）。
- 可信度按运行满日降级（坐实≥14d / 方向信号7-13d / 不足<7d）。

## 8. 常见坑清单/Pitfalls checklist

- ❌ 曝光打平（§4）——头号坑，结论会反。
- ❌ 拿 AB 平台单实验报表当组合格（混了另一层）（§0）。
- ❌ 用 `voucher_click_context` 取全盘 GMV（只券订单，选择偏差）（§3）。
- ❌ base 选成单层 base（应是 A-base×B-base 的 prod 组合）（§2）。
- ❌ 不剔抽干格 → 噪声当效果（§5）。
- ⚠️ perf 表个人 Presto 被 Ranger 拒读、重 join 超时 → 走 DataSuite；重 join 把 `sra-ds-sql-query` 的 `POLL_MAX_RETRIES` 调高（默认 300s 不够）。
- ⚠️ 把联合格当单层净效应汇报（§6）。

> 复跑范例（SQL 全文 + per-user 口径）：`docs/personal/roger.li/roi3/experiments/platform-gmv-uplift/2026-06-22-cr-uplift-guardrail-vpr-platformgmv-readout-repro.md`。
