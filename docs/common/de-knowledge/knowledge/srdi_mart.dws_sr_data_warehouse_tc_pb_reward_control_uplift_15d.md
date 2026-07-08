<!-- ads-workspace-gdoc-sync: gdoc_id=1Jd64gCEzuhvJljykfulcA-Hdi2RQ-U1UtrzqjZMkOtE gdoc_url=https://docs.google.com/document/d/1Jd64gCEzuhvJljykfulcA-Hdi2RQ-U1UtrzqjZMkOtE/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_reward_control_uplift_15d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date`
**分区：** `grass_region`（地区）, `local_date`（日期）
**更新频率：** 每日调度，按分区覆盖写入（INSERT OVERWRITE）
**访问频次：** 325 次

---

## 业务描述

本表用于衡量搜推（SR）频道内 **TC PB（竞价广告）Reward 模型**的控制组曝光及 GMV **提升效果（Uplift）**，统计口径为以分区日期为基准的近 15 天滚动窗口（实际计算采用 30 天数据，取平均后作为 15 天口径的代理指标）。

**核心业务场景：**
- 评估新晋获胜（Win）Reward 模型上线前后，对控制组流量的曝光量及 GMV 的相对增益（Uplift）。
- 识别"新晋赢家"模型（首次赢得竞价日当天及之后连续胜出），排除历史已多次获胜模型，确保 Uplift 评估的干净性。
- 提供每日 Uplift 明细列表，供下游分析历史波动趋势。

**适合回答的问题：**
- 特定大区、特定日期，TC PB Reward 模型上线后控制组曝光量 Uplift 均值是多少？
- 近期 GMV Uplift 趋势是否稳定，各 `d0`（基准日）的 Uplift 分布如何？
- 跨地区对比，哪个大区的 Reward 模型 GMV Uplift 表现更优？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，对应业务大区标识（如 ID、MY 等），每次调度按该分区覆盖写入 |
| `local_date` | date | 数据日期分区，即调度基准日期，用于定位当次产出的统计结果 |

### 维度：统计维度

> 本表粒度为 `grass_region` × `local_date`，无额外业务维度字段；所有聚合指标均在分区粒度上产出。

### 指标：控制组曝光 Uplift

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_control_uplift_pct` | double | 近 30 个有效 `d0` 基准日的控制组曝光量 Uplift（`after_imp_cnt / before_imp_cnt - 1`）的简单平均值（除以 30）。当 `before_imp_cnt <= 0` 且 `after_imp_cnt > 0` 时赋值 1.0，其余非正增长场景兜底赋值 0.02，代表当前分区日期下新晋获胜模型的平均曝光提升率 |
| `imp_cnt_control_uplift_pct_list` | array\<string\> | 各 `d0` 基准日的曝光 Uplift 明细列表，格式为 `d0_uplift_pct`（如 `2024-01-01_0.15`），用于下游追溯每日详细 Uplift 值 |

### 指标：控制组 GMV Uplift

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_control_uplift_pct` | double | 近 30 个有效 `d0` 基准日的控制组 GMV Uplift（`after_gmv / before_gmv - 1`，取 0 下限）的简单平均值（除以 30）。当 `before_gmv <= 0` 且 `after_gmv > 0` 时赋值 1.0，`before_gmv <= 0` 且 `after_gmv <= 0` 时赋值 0，代表当前分区日期下新晋获胜模型的平均 GMV 提升率 |
| `gmv_control_uplift_pct_list` | array\<string\> | 各 `d0` 基准日的 GMV Uplift 明细列表，格式为 `d0_uplift_pct`（如 `2024-01-01_0.08`），用于下游追溯每日详细 Uplift 值 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全表扫描，扫描成本极高。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-06-01'
  ```
- 若需跨日期区间查询，应以明确的日期范围限定 `local_date`，避免分区裁剪失效。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt_control_uplift_pct` | **比率/均值型指标**：已是多个 `d0` 的平均 Uplift 比率，跨行 SUM 无业务意义，跨日期或地区汇总需重新回溯明细表计算 |
| `gmv_control_uplift_pct` | **比率/均值型指标**：同上，不可直接 SUM 或 AVG 后再用于决策 |
| `imp_cnt_control_uplift_pct_list` | **预聚合列表**：array 类型，直接 SUM 语义不正确；如需汇总需先 `explode` 后解析明细再聚合 |
| `gmv_control_uplift_pct_list` | **预聚合列表**：同上 |

### 时效性说明

- 本表为 **每日快照表**（`local_date` 分区），不包含实时/准实时数据。
- 字段名含 `_15d` 后缀，但实际 ETL 逻辑中 `d0` 基准日的窗口为 `[local_date - 36d, local_date - 7d]`，每个 `d0` 使用前后各 7 天共 15 天的流量数据计算 Uplift；最终指标为有效 `d0` 之和除以 30（非严格 30 天，实际有效 `d0` 数量可能小于 30）。
- 上游依赖表 `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d` 有数据延迟时，本表产出时间相应顺延。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d` | 提供模型维度的每日曝光量（`control_imp_cnt`）、GMV（`control_gmv`）及是否为获胜日（`is_win_day`）等基础指标，作为 Uplift 计算的唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d
    └─► [traffic] 过滤地区+近44天数据
        └─► [traffic_by_d0] 以各d0为基准扩展±7天数据
            └─► [new_winner] 筛选新晋获胜模型
                └─► [daily_uplift] 计算每个d0的曝光/GMV Uplift
                    └─► INSERT OVERWRITE 目标表（汇总为分区粒度均值+列表）
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `traffic_${grass_region_without_quote}` | 从上游 1d 表中按 `grass_region` 及近 44 天（`local_date - 43d` 至 `local_date`）过滤出模型级别的每日曝光/GMV 明细 |
| Step 2 | `traffic_by_d0_${grass_region_without_quote}` | 以满足 `[local_date - 36d, local_date - 7d]` 区间内的每个自然日为 `d0`，通过 Self Join 扩展出每个 `d0` 前后各 7 天的数据行（`d0 ± 7d` 窗口共 15 天） |
| Step 3 | `new_winner_${grass_region_without_quote}` | 在扩展后的宽表上按 `(d0, model_id)` 聚合，筛选满足以下三个条件的"新晋获胜"模型：① 当天（`local_date = d0`）为获胜日；② `d0` 之前获胜天数 ≤ 1（近乎首次获胜）；③ `d0` 之后获胜天数 ≥ 6（持续获胜） |
| Step 4 | `daily_uplift_${grass_region_without_quote}` | 对新晋获胜模型（Join `new_winner`），分别汇总 `d0` 前后的 `control_imp_cnt` 和 `control_gmv`，计算每个 `d0` 的曝光 Uplift 和 GMV Uplift，含边界保护（分母为 0 的兜底逻辑） |
| Step 5 | INSERT OVERWRITE | 将所有 `d0` 的 Uplift 汇总至分区粒度：Uplift 均值（`SUM / 30`）写入 double 字段，明细以 `d0_uplift` 格式的字符串收集为 array 写入 list 字段，按 `(grass_region, local_date)` 分区覆盖写入目标表 |

### 注意事项

1. **除以 30 的固定分母**：最终均值计算采用 `SUM / 30` 而非 `SUM / COUNT(d0)`，若某个分区下有效 `d0` 数量不足 30，均值结果会被稀释偏低，使用时需结合 `*_list` 字段验证实际 `d0` 数量。
2. **单 Writer、分区覆盖写入**：ETL 为单文件、`INSERT OVERWRITE PARTITION (grass_region, local_date)`，无 multi-writer 风险；但同一调度日如对同一分区重跑，会完全覆盖历史产出。
3. **动态参数**：SQL 中 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 均为调度时注入的运行时参数，不同地区的调度任务实例相互独立。
4. **Uplift 兜底逻辑不对称**：`imp_cnt_control_uplift_pct` 在无增长时兜底为 0.02（非零），而 `gmv_control_uplift_pct` 兜底为 0，两字段的语义下界不同，对比分析时需注意。
5. **上游数据依赖**：强依赖 `dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d` 的历史数据完整性（近 44 天），若上游存在历史补数或延迟，需重新触发本表对应分区的回刷。

---

*文档生成时间：2026-05-17*