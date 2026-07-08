<!-- ads-workspace-gdoc-sync: gdoc_id=1AgfhNz58i3ystKWbY0AnLplXFy3llN58dBW3kcLlrzc gdoc_url=https://docs.google.com/document/d/1AgfhNz58i3ystKWbY0AnLplXFy3llN58dBW3kcLlrzc/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_reward_model_uplift_7d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `model_id` + `item_id` + `shop_id`
**分区：** `grass_region`（站点）, `local_date`（日期）
**更新频率：** 每日（T+1 写入，覆盖对应分区）
**引用频次 / 访问频次：** 1082

---

## 业务描述

本表面向搜推（Search & Recommendation）数仓，聚焦 **TC（Traffic Control）激励模型（Reward Model）中 Price-Beat（PB）方向** 的 7 日 Uplift 归因评估。每行代表某站点、某日期下，特定模型（`model_id`）× 商品（`item_id`）× 店铺（`shop_id`）粒度的流量与 GMV 增量拆解结果。

**核心业务场景：**
- **Winner 实验 Uplift 估算：** 基于已完成实验（`is_win_day=1`）的实验组 vs 对照组，估算过去 7 天归因于模型的曝光与 GMV 净增量。
- **TBI（To-Be Improved）推荐 Uplift 估算：** 结合 14 天 CSPU/总体均值与 Uplift 字典，预测模型未来可带来的曝光与 GMV 增量。
- **激励返利核算：** 汇总过去 7 天因 PB 活动产生的商品返利金额（`item_rebate_local_l7d`），用于激励预算管理与对账。
- **Uplift 分组诊断：** 保留控制组/实验组拆分指标及底层比率字段，支持模型效果归因与监控。

**适合回答的问题：**
- 某模型过去 7 天通过 Winner 实验带来了多少额外曝光和 GMV？
- 若按 TBI 字典推荐，预计可带来多少增量曝光和 GMV？
- 某商品/店铺在 PB 激励活动中产生了多少返利？
- 某模型的 Winner 实验 Uplift 百分比（曝光/GMV）是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区，分区键，如 `ID`、`MY` 等 |
| `local_date` | date | 数据日期（本地时区），分区键，对应 ETL 运行日期 |

---

### 维度：模型 & 商品 & 店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_id` | bigint | TC 激励模型 ID，是实验归因与 Uplift 计算的核心维度 |
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |

---

### 指标：7 日整体流量基础指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_l7d` | bigint | 过去 7 天总曝光次数（含全部日期） |
| `gmv_l7d` | double | 过去 7 天总 GMV（本地货币，已乘汇率转换） |

---

### 指标：Winner 实验原始流量（7 日，仅 is_win_day=1 的日期）

| 字段 | 类型 | 说明 |
|---|---|---|
| `win_imp_cnt_l7d` | bigint | Winner 日的过去 7 天曝光次数（实验组+对照组之和） |
| `win_gmv_l7d` | double | Winner 日的过去 7 天 GMV（已乘汇率，实验组+对照组之和） |
| `win_control_imp_cnt_l7d` | bigint | Winner 日对照组过去 7 天曝光次数 |
| `win_control_gmv_l7d` | double | Winner 日对照组过去 7 天 GMV（原始货币，未乘汇率） |
| `win_treatment_imp_cnt_l7d` | double | Winner 日实验组（归一化后）过去 7 天曝光次数 |
| `win_treatment_gmv_l7d` | double | Winner 日实验组（归一化后）过去 7 天 GMV（原始货币，未乘汇率） |

> ⚠️ `win_control_gmv_l7d`、`win_treatment_gmv_l7d` 未经汇率转换，与 `gmv_l7d` 单位不同，请勿直接混合计算。

---

### 指标：Winner 实验 Uplift 绝对量（7 日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `win_imp_cnt_l7d_uplift` | bigint | Winner 实验曝光 Uplift 绝对量（上限为 `win_imp_cnt_l7d`）；计算公式：`ceil(win_imp_cnt_l7d × (1 - 1/((1+win_imp_cnt_uplift_pct)×(1+imp_cnt_control_uplift_pct)))) + imp_cnt_extra_bonus`，取与 `win_imp_cnt_l7d` 的较小值 |
| `win_gmv_l7d_uplift` | double | Winner 实验 GMV Uplift 绝对量（本地货币，已乘汇率，上限为 `win_gmv_l7d`） |

---

### 指标：TBI 推荐 Uplift 绝对量（7 日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `tbi_rcmd_imp_cnt_l7d_uplift` | bigint | TBI 推荐策略预测的 7 日曝光增量，计算公式：`ceil(avg_imp_cnt_l14d × ((1+tbi_imp_cnt_uplift_pct)×(1+imp_cnt_control_uplift_pct)-1) × 7)` |
| `tbi_rcmd_gmv_l7d_uplift` | double | TBI 推荐策略预测的 7 日 GMV 增量（本地货币，已乘汇率）；`tbi_gmv_uplift_pct` 为 null 时取 0 |

---

### 指标：Uplift 比率

| 字段 | 类型 | 说明 |
|---|---|---|
| `win_imp_cnt_uplift_pct` | double | Winner 实验曝光 Uplift 百分比，`= max(treatment/control - 1, 0)`；control=0 且 treatment>0 时取 1.0；双零时取 0.02 |
| `win_gmv_uplift_pct` | double | Winner 实验 GMV Uplift 百分比，同上计算逻辑 |
| `imp_cnt_control_uplift_pct` | double | AA 对照组曝光 Uplift 修正系数，来自 `dws_sr_data_warehouse_tc_pb_reward_control_uplift_15d`，30 天更新一次，取最新可用分区 |
| `gmv_control_uplift_pct` | double | AA 对照组 GMV Uplift 修正系数，同上来源 |
| `tbi_imp_cnt_uplift_pct` | double | TBI 字典匹配得到的曝光 Uplift 百分比，按 `avg_cspu_imp_cnt_l14d` ≥ `cspu_imp_cnt_pp` 且 `avg_imp_cnt_l14d` ≥ `imp_cnt_pp` 的最优分桶取值 |
| `tbi_gmv_uplift_pct` | double | TBI 字典匹配得到的 GMV Uplift 百分比，按 `avg_cspu_gmv_l14d` ≥ `cspu_gmv_pp` 且 `avg_gmv_l14d` ≥ `gmv_pp` 的最优分桶取值 |

> ⚠️ 以上所有 `*_pct` / `*_uplift_pct` 字段均为比率，**不可直接 SUM**，汇总时需用基数指标加权。

---

### 指标：14 日均值基准

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_imp_cnt_l14d` | double | 过去 14 天日均曝光次数（含全部日期），`= sum(imp_cnt)/14` |
| `avg_gmv_l14d` | double | 过去 14 天日均 GMV（原始货币，未乘汇率），`= sum(gmv)/14` |
| `avg_cspu_imp_cnt_l14d` | double | 过去 14 天 CSPU（核心 SKU 池）日均曝光次数，`= sum(cspu_imp_cnt)/14` |
| `avg_cspu_gmv_l14d` | double | 过去 14 天 CSPU 日均 GMV（原始货币，未乘汇率），`= sum(cspu_gmv)/14` |

> ⚠️ `avg_*` 字段为预聚合均值，**不可直接 SUM** 后再求均值。

---

### 指标：曝光奖励与返利

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_extra_bonus` | double | 曝光额外奖励，计算逻辑：`0.02 × sum(imp_cnt)`（仅 Winner 日且当日曝光 Uplift 为负的记录），用于兜底激励 |
| `item_rebate_local_l7d` | double | 过去 7 天商品 PB 活动返利金额（本地货币），来源于订单实付返利，`item_promotion_type_id=323`；无返利时取 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-05-16'
  ```
- 每次调度仅覆盖写入当天的 `(grass_region, local_date)` 分区，跨日期查询时需按实际需求枚举或范围过滤 `local_date`。

### 不可直接 SUM 的字段

以下字段为比率、均值或预聚合派生指标，**不得直接 SUM 后参与聚合计算**：

| 字段 | 原因 |
|---|---|
| `win_imp_cnt_uplift_pct` | Uplift 比率，需以基数加权 |
| `win_gmv_uplift_pct` | Uplift 比率，需以基数加权 |
| `imp_cnt_control_uplift_pct` | 修正系数，全模型共享同一值 |
| `gmv_control_uplift_pct` | 修正系数，全模型共享同一值 |
| `tbi_imp_cnt_uplift_pct` | 字典分桶比率，需以基数加权 |
| `tbi_gmv_uplift_pct` | 字典分桶比率，需以基数加权 |
| `avg_imp_cnt_l14d` | 预聚合均值 |
| `avg_gmv_l14d` | 预聚合均值 |
| `avg_cspu_imp_cnt_l14d` | 预聚合均值 |
| `avg_cspu_gmv_l14d` | 预聚合均值 |
| `imp_cnt_extra_bonus` | 非线性派生指标 |
| `win_imp_cnt_l7d_uplift` | 含 LEAST 截断的派生量，跨行加总须确认业务含义 |
| `win_gmv_l7d_uplift` | 同上 |
| `tbi_rcmd_imp_cnt_l7d_uplift` | 预测增量，跨模型加总需谨慎去重 |
| `tbi_rcmd_gmv_l7d_uplift` | 同上 |

### 货币单位一致性

- `gmv_l7d`、`win_gmv_l7d_uplift`、`tbi_rcmd_gmv_l7d_uplift`、`item_rebate_local_l7d` 均已乘以汇率，为本地货币（local currency）。
- `win_control_gmv_l7d`、`win_treatment_gmv_l7d`、`avg_gmv_l14d`、`avg_cspu_gmv_l14d` **未乘汇率**，为原始货币，勿与上述字段直接相加。

### 时效性说明

- 本表为 **7 日滑动窗口快照表**（`_7d` 后缀），每日调度写入，每次覆盖当日分区。
- 14 日均值字段基于 `[local_date-13, local_date]` 窗口，跨 14 天按固定分母 14 计算，非动态天数。
- `imp_cnt_control_uplift_pct` / `gmv_control_uplift_pct` 来自独立 AA 实验估算，30 天更新一次，使用最新可用分区，**可能与 `local_date` 不同步**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d` | 核心流量明细，提供每日实验组/对照组曝光、GMV、CSPU 指标，用于 7 日及 14 日聚合 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_tbi_uplift_dictionary_30d` | TBI Uplift 百分比字典，按 CSPU/总体流量分桶，分别用于曝光和 GMV 的 TBI Uplift 匹配 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_control_uplift_15d` | AA 对照组 Uplift 修正系数，30 天更新一次，提供 `imp_cnt_control_uplift_pct` 和 `gmv_control_uplift_pct` |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | 订单返利明细，过滤 `item_promotion_type_id=323`（PB 活动），汇总过去 7 天商品返利金额 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，按站点+日期取最大汇率，用于将 GMV 转换为本地货币 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d  (14天原始流量)
    │
    ▼
traffic_raw  →  traffic_aggr  (7日/14日聚合，含 CSPU、Winner 日拆分)
                    │                           │
                    ▼                           ▼
            winner_l7d_uplift          avg_cspu/avg 均值
            (Winner Uplift 比率)              │
                    │                           ▼
                    │              tbi_rcmd_imp_uplift  ←─ tbi_uplift_dictionary_30d
                    │              tbi_rcmd_gmv_uplift  ←─ tbi_uplift_dictionary_30d
                    │
                    └──────────────────────────────────────────┐
                                                               ▼
dws_sr_data_warehouse_tc_pb_reward_control_uplift_15d  →  combine_uplift
                                                           (Uplift 绝对量合并)
                                                               │
         dwd_order_item_all_ent_df__reg_s0_live  →  rebate ──┘
                                                               │
         dim_exchange_rate__reg_s0_live  ─────────────────────┘
                                                               ▼
                              INSERT OVERWRITE  ads_sr_data_warehouse_tc_pb_reward_model_uplift_7d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `traffic_raw` | 从 DWS 层读取目标站点近 14 天（`[local_date-13, local_date]`）的模型实验日粒度数据 |
| Step 2 | `traffic_aggr` | 按 `(model_id, item_id, shop_id)` 聚合：7 日曝光/GMV（全量及 Winner 日实验组/对照组）、14 日均值（总体及 CSPU）、曝光额外奖励 |
| Step 3 | `winner_l7d_uplift` | 按 model_id 计算 Winner 实验曝光/GMV Uplift 百分比，含 GREATEST 保底（负 Uplift 归 0，双零兜底）逻辑 |
| Step 4 | `tbi_rcmd_imp_uplift` | 将 `traffic_aggr` 的 14 日均值与 TBI 字典 Inner Join，按 `cspu_k DESC, k DESC` 取最优分桶，获取 `tbi_imp_cnt_uplift_pct` |
| Step 5 | `tbi_rcmd_gmv_uplift` | 同 Step 4，匹配 GMV 维度分桶，获取 `tbi_gmv_uplift_pct` |
| Step 6 | `combine_uplift` | 将 Step 2–5 结果与 AA 对照组修正系数（`control_uplift_15d`，取最新可用分区）Left Join 合并，计算 Uplift 绝对量（含 LEAST 截断），保留所有中间比率字段 |
| Step 7 | `rebate` | 从订单明细表汇总过去 7 天 PB 活动返利金额，按 `model_id` 分组 |
| Step 8 | INSERT OVERWRITE | 将 `combine_uplift` 与汇率维表、返利表 Left Join，GMV 类字段乘以汇率，`item_rebate_local_l7d` 空值填 0，写入目标分区 `(grass_region, local_date)` |

### 注意事项

1. **单一写入，无 multi-writer 风险：** 本表仅有 1 个 ETL 文件，无多文件并发写入问题。
2. **分区覆盖写入：** 采用 `INSERT OVERWRITE PARTITION(grass_region, local_date)`，每次调度覆盖当日分区，重跑安全。
3. **AA 修正系数分区非对齐：** `imp_cnt_control_uplift_pct` / `gmv_control_uplift_pct` 使用 `max_pt` 函数取最新可用分区，该分区日期可能早于 `local_date`，历史回刷时需注意系数时效性。
4. **TBI 字典取当日分区：** `tbi_uplift_dictionary_30d` 指定 `local_date = ${local_date}`，若当日分区缺失会导致 TBI Uplift 字段为 null，`tbi_rcmd_gmv_l7d_uplift` 有 null 保护（取 0），但 `tbi_rcmd_imp_cnt_l7d_uplift` 无保护，需关注上游依赖。
5. **汇率取 max：** 汇率来源为 `max(exchange_rate)`，适用于站点内汇率唯一的场景；若多条记录存在，取最大值，需关注汇率数据质量。
6. **中间字段注释：** ETL SQL 中明确标注部分字段（如 `win_control_*`、`avg_*`、`imp_cnt_extra_bonus` 等）为"自测保存中间数据"，在生产表中保留，用于调试与链路验证，使用时需知晓其含义而非直接对外输出。
7. **Winner 日曝光 Uplift 双零兜底：** `win_imp_cnt_uplift_pct` 在控制组和实验组均为 0 时取固定值 0.02，会导致 `win_imp_cnt_l7d_uplift` 存在微小正数，分析时需注意。

---

*文档生成时间：2026-05-17*