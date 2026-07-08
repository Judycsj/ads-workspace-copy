<!-- ads-workspace-gdoc-sync: gdoc_id=1rb_J4Le-oxP_iarkdGFXIc_kjR37t3gF1YFbuyzm2N0 gdoc_url=https://docs.google.com/document/d/1rb_J4Le-oxP_iarkdGFXIc_kjR37t3gF1YFbuyzm2N0/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_reward_tbi_uplift_dictionary_30d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `cspu_k` + `k`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日一次（按大区分区覆盖写入）
**访问频次：** 373 次

---

## 业务描述

本表用于存储 **TBI（Treatment Boost Index）奖励机制下，基于过去 30 天滑动窗口的 uplift 提升率字典**，服务于搜推广告 Reward 模型的分档映射场景。

核心业务场景如下：

- **Model 分档定位**：根据每个 model 在过去 30 天 winner day 内的日均 impression 量（`avg_imp_cnt`）和日均 CSPU impression 量（`avg_cspu_imp_cnt`），将 model 映射到 10 个分位档（0.1 ~ 0.9）与"最低档"（0）构成的二维分档矩阵（cspu 维度 × 整体流量维度）。
- **Uplift 字典构建**：对每个（`cspu_k`，`k`）分档组合，聚合该档位所有 winner model 的实验对照数据（impression、GMV），计算 TBI 处理效应相对于对照的提升率（uplift pct）。
- **缺失值兜底**：impression uplift 缺失时填充 `0.02`，GMV uplift 缺失时填充 `0`，确保字典完整覆盖所有分档组合。

**适合回答的典型问题：**
- 特定大区、特定日期，某档位模型的 TBI impression 提升率是多少？
- 某档位组合（cspu_k × k）下有多少 model 参与了 uplift 计算？
- TBI 机制在高流量档位 vs 低流量档位的 GMV 提升效果对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY 等，用于分区隔离各市场数据 |
| `local_date` | date | 业务日期，即计算触发日期，窗口覆盖 `[local_date-29, local_date]` 共 30 天 |

### 维度：分档分位键

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_k` | double | CSPU 维度分位档位键，取值为 0、0.1、0.2、…、0.9，对应 model 按 `avg_cspu_imp_cnt` 或 `avg_cspu_gmv` 落入的分位区间下界 |
| `k` | double | 整体流量维度分位档位键，取值为 0、0.1、0.2、…、0.9，对应 model 按 `avg_imp_cnt` 或 `avg_gmv` 落入的分位区间下界 |

### 指标：Impression 分位阈值与提升率

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt_pp` | double | `cspu_k` 对应的 CSPU 日均 impression 量分位阈值（30 天 winner day 均值的近似分位数），由 `APPROX_PERCENTILE` 计算 |
| `imp_cnt_pp` | double | `k` 对应的整体日均 impression 量分位阈值（30 天 winner day 均值的近似分位数），由 `APPROX_PERCENTILE` 计算 |
| `tbi_imp_cnt_uplift_pct` | double | 该（`cspu_k`, `k`）档位组合下，TBI 处理组相对对照组的 impression 提升率。计算逻辑：`treatment_imp_cnt_normal / control_imp_cnt - 1`；若对照组为 0 且处理组 > 0 则填 1.0；缺失或负值兜底填 `0.02` |
| `imp_group_model_cnt` | bigint | 参与该档位 impression uplift 计算的 distinct model 数量，仅用于自测核查 |

### 指标：GMV 分位阈值与提升率

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_gmv_pp` | double | `cspu_k` 对应的 CSPU 日均 GMV 分位阈值（30 天 winner day 均值的近似分位数），由 `APPROX_PERCENTILE` 计算 |
| `gmv_pp` | double | `k` 对应的整体日均 GMV 分位阈值（30 天 winner day 均值的近似分位数），由 `APPROX_PERCENTILE` 计算 |
| `tbi_gmv_uplift_pct` | double | 该（`cspu_k`, `k`）档位组合下，TBI 处理组相对对照组的 GMV 提升率。计算逻辑：`GREATEST(treatment_gmv_normal / control_gmv - 1, 0)`；若对照组 GMV 为 0 且处理组 > 0 则填 1.0；缺失时兜底填 `0` |
| `gmv_group_model_cnt` | bigint | 参与该档位 GMV uplift 计算的 distinct model 数量，仅用于自测核查 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则全分区扫描，影响性能且通常无跨区聚合意义。
- **`local_date`**：必须指定具体日期，该表每日全量覆盖写入，通常取最新分区日期即可。

```sql
-- 推荐写法
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `tbi_imp_cnt_uplift_pct` | 各档位 uplift 比率，系加权聚合中间结果，跨档位直接 SUM 无业务意义 |
| `tbi_gmv_uplift_pct` | 同上，GMV 提升比率不可跨档位累加 |
| `cspu_imp_cnt_pp` / `imp_cnt_pp` | 分位阈值，为近似分位数（`APPROX_PERCENTILE`），不可直接 SUM/AVG |
| `cspu_gmv_pp` / `gmv_pp` | 同上，GMV 维度分位阈值 |
| `cspu_k` / `k` | 分位档位键，数值本身为分位点标识，直接加减无意义 |

### 时效性说明

- 本表为 **30 天滑动窗口聚合表**（`_30d` 后缀），每日产出一个快照分区，数据窗口为 `[local_date-29, local_date]`。
- 数据每日 T+1 产出，反映截至 `local_date` 的最近 30 天 winner model 行为。
- `imp_group_model_cnt`、`gmv_group_model_cnt` 仅供研发自测使用，**不建议用于对外业务报表**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d` | 提供每个 model 的每日实验级别数据，包含 `is_win_day`、`imp_cnt`、`gmv`、`cspu_imp_cnt`、`cspu_gmv`、`control_imp_cnt`、`treatment_imp_cnt_normal`、`control_gmv`、`treatment_gmv_normal` 等字段，作为本表所有计算的唯一原始来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d
  └─ 过滤指定大区近 30 天数据
       └─ 筛选 winner model（30天内至少有1天 is_win_day=1）
            └─ 计算 winner day 日均指标（imp/gmv/cspu_imp/cspu_gmv）
                 └─ 计算 10 分位 + 零档共 11 个分位阈值（笛卡尔积展开）
                      ├─ impression 维度：落档 → 聚合对照/处理组 → 计算 imp uplift pct
                      └─ GMV 维度：落档 → 聚合对照/处理组 → 计算 gmv uplift pct
                           └─ 笛卡尔积合并两套字典 + 缺失值兜底
                                └─ INSERT OVERWRITE 目标表分区
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `traffic_${grass_region_without_quote}` | 从上游 1d 表过滤指定大区近 30 天全量数据 |
| Step 2 | `winner_30d_${grass_region_without_quote}` | 筛选 30 天内有至少 1 个 winner day 的 model 集合 |
| Step 3 | `avg_30d_${grass_region_without_quote}` | 计算各 model 在 winner day 下的日均 imp、GMV、CSPU imp、CSPU GMV，以及对照/处理组的总量（用于后续 uplift 计算） |
| Step 4 | `model_percentile_${grass_region_without_quote}` | 对全体 winner model 的日均指标分别计算 10 个近似分位数（P10~P90），展开为 11 行（含零档），形成分位阈值字典 |
| Step 5 | `imp_cnt_uplift_dict_raw_${grass_region_without_quote}` | 将 model 按（cspu_imp_cnt 分位 × imp_cnt 分位）落档（取最高档，row_number 去重），按档位聚合 control/treatment impression，计算 `tbi_imp_cnt_uplift_pct`，负值/零值按规则兜底 |
| Step 6 | `gmv_uplift_dict_raw_${grass_region_without_quote}` | 同 Step 5，按 GMV 维度落档并计算 `tbi_gmv_uplift_pct`，负值截断为 0 |
| Step 7 | `combine_uplift_dict_${grass_region_without_quote}` | 以分位阈值字典笛卡尔积为基准，LEFT JOIN impression uplift 和 GMV uplift 结果，`COALESCE` 填充缺失值（impression 兜底 0.02，GMV 兜底 0） |
| Step 8 | 目标表写入 | `INSERT OVERWRITE` 按 `grass_region`、`local_date` 分区写入目标表 |

### 注意事项

- **非 multi-writer**：该表由单一 ETL 文件写入，无并发写入风险。
- **分区覆盖写入**：每次执行对指定 `grass_region` + `local_date` 分区全量覆盖（`INSERT OVERWRITE`），历史分区不受影响。
- **近似分位数精度**：`APPROX_PERCENTILE` 为近似算法，在 model 数量极少时分位阈值可能出现重复或退化，导致相邻档位合并。
- **落档逻辑说明**：model 落档采用"落入所有满足条件的分位区间中取最高档"策略（`row_number() OVER ORDER BY k DESC` 取 `rnk=1`），即 model 归属其能达到的最高分位档。
- **兜底值差异**：impression uplift 缺失兜底为 `0.02`（非零正值），GMV uplift 缺失兜底为 `0`，两者语义不同，下游使用时需注意区分。
- **自测字段**：`imp_group_model_cnt`、`gmv_group_model_cnt` 在 ETL 注释中明确标注"仅用于自测"，生产使用场景应避免将其作为业务指标输出。
- **参数化大区**：SQL 通过 `${grass_region}` / `${grass_region_without_quote}` 参数化执行，每次调度针对单一大区，多大区需多次调度。

---

*文档生成时间：2026-05-17*