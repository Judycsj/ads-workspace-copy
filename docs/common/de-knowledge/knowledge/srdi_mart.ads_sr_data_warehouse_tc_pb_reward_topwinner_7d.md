<!-- ads-workspace-gdoc-sync: gdoc_id=150HaXxYN1lS5vA-0NH1hoDgIFSvYiJ_HTsFFIfrykmc gdoc_url=https://docs.google.com/document/d/150HaXxYN1lS5vA-0NH1hoDgIFSvYiJ_HTsFFIfrykmc/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_reward_topwinner_7d

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `local_date`（每个分区仅写入一行）
**分区**：`grass_region`（地区）、`local_date`（本地日期）
**更新频率**：每日一次（按分区覆盖写入）
**访问频次**：323 次

---

## 业务描述

本表用于记录搜索推荐（SR）数仓 TC（Top Creator / 店铺商品）场景下，**价格竞价（PB）奖励实验（Reward Experiment）在过去 7 天滚动窗口内的最优模型排名结果**。

核心业务场景：
- 在 PB 奖励实验中，对 treatment 组与 control 组的曝光量（imp）、订单量（order）、GMV 三项核心指标分别计算 Uplift（相对提升率），以评估各模型的实验效果。
- 从所有参与实验的模型中，分别挑选出 **曝光 Uplift 最高的模型（Top Imp Model）** 和 **在 GMV Uplift 非零前提下订单 Uplift 最高的模型（Top Order Model）**，以交叉拼接的方式存入本表。

适合回答的问题：
- 过去 7 天，某地区（`grass_region`）PB 奖励实验中，哪个模型的曝光提升率最高？
- 哪个模型在保证 GMV 有增益的前提下，订单提升率最高？
- 最优模型在曝光、订单、GMV 三个维度上的 Uplift 分别是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区标识，如 `ID`、`TH` 等；ETL 按地区分区独立执行并写入 |
| `local_date` | date | 本地日期，代表数据统计截止日期，7 天窗口为 `[local_date - 6, local_date]` |

### 维度：模型标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_model_id` | bigint | 曝光 Uplift 最高的模型 ID（Top Imp Model），取自按 `imp_uplift` 降序排名第一的模型 |
| `order_model_id` | bigint | 订单 Uplift 最高的模型 ID（Top Order Model），在 `gmv_uplift != 0` 的前提下，按 `order_uplift` 降序排名第一的模型 |

### 指标：Uplift 提升率

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uplift` | double | Top Imp Model 对应的曝光 Uplift，计算公式：`treatment_imp_cnt / 9 / control_imp_cnt - 1`；当 `control_imp_cnt <= 0` 时置为 0 |
| `order_uplift` | double | Top Order Model 对应的订单 Uplift，计算公式：`treatment_order_cnt / 9 / control_order_cnt - 1`；当 `control_order_cnt <= 0` 时置为 0 |
| `gmv_uplift` | double | Top Order Model 对应的 GMV Uplift，计算公式：`treatment_gmv / 9 / control_gmv - 1`；当 `control_gmv <= 0` 时置为 0；该字段来自 Top Order Model，不来自 Top Imp Model |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 分区过滤**，否则将触发全分区扫描，产生大量不必要的数据读取：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```
- 若需查询多日趋势，建议使用 `local_date BETWEEN ... AND ...` 明确范围。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uplift` | 预聚合相对比率，跨分区/地区直接 SUM 无业务意义 |
| `order_uplift` | 同上，为相对提升率 |
| `gmv_uplift` | 同上，为相对提升率 |

> 多地区、多日期的汇总分析须在理解业务口径后自行加权，不可简单累加或平均。

### 时效性说明

- 本表为 **每日滚动 7 天窗口（7d）**聚合结果，`local_date` 对应的数据覆盖 `[local_date - 6, local_date]` 共 7 天。
- 每日 ETL 完成后数据可用，存在一定的 T+1 延迟，不适合实时/准实时场景。
- 每次写入为 `INSERT OVERWRITE` 按分区覆盖，当日分区数据以最新一次写入为准。

### 其他注意事项

- 本表每个 `(grass_region, local_date)` 分区理论上**仅有一行数据**（Top Imp Model CROSS JOIN Top Order Model），若 Top Imp Model 或 Top Order Model 为空（如实验数据缺失），分区可能为空。
- `gmv_uplift` 字段来源于 Top Order Model，而非 Top Imp Model，两个模型可能不同，使用时注意字段归属语义。
- Uplift 计算中 treatment 组流量被除以 9（`treatment_xxx / 9`），反映实验中 treatment 与 control 的流量分配比例为 9:1，使用原始值时需知晓此换算背景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_exp_reward_1d` | 提供按 `(shop_id, item_id, model_id, exp_group_type)` 分组的天级实验指标（曝光量、订单量、GMV），ETL 读取近 7 天数据进行聚合 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_exp_reward_1d（近7天）
    ↓ 按 (shop_id, item_id, model_id) 聚合 treatment/control 指标
    ↓ 按 model_id 聚合，计算各指标 Uplift
[uplift_stats]
    ↓ 按 imp_uplift DESC LIMIT 1              ↓ gmv_uplift != 0，按 order_uplift DESC LIMIT 1
[top_imp_models]                            [top_order_models]
    ↓                 CROSS JOIN                ↓
srdi_mart.ads_sr_data_warehouse_tc_pb_reward_topwinner_7d（分区覆盖写入）
```

### 关键步骤

| 步骤 | 操作类型 | 说明 |
|---|---|---|
| Statement 1 | CREATE TEMPORARY VIEW `uplift_stats` | 从 DWS 层读取近 7 天数据，先按 `(shop_id, item_id, model_id)` 分组累加 treatment/control 的曝光、订单、GMV；再按 `model_id` 聚合，用 `MAX` + 条件兜底（分母 ≤ 0 时置 0）计算三项 Uplift |
| Statement 2 | CREATE TEMPORARY VIEW `top_imp_models` | 从 `uplift_stats` 按 `imp_uplift DESC` 取 Top 1，作为曝光最优模型 |
| Statement 3 | CREATE TEMPORARY VIEW `top_order_models` | 从 `uplift_stats` 过滤 `gmv_uplift != 0` 后，按 `order_uplift DESC` 取 Top 1，作为订单最优模型 |
| Statement 4 | INSERT OVERWRITE（目标表分区） | 将 `top_imp_models` 与 `top_order_models` CROSS JOIN，选取最终 5 个指标字段写入目标分区 |

### 注意事项

- **单一写入者**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险。
- **分区写入**：使用 `INSERT OVERWRITE ... PARTITION (grass_region, local_date)`，每次执行覆盖单个分区，不影响其他分区历史数据。
- **参数化执行**：SQL 中 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 均为运行时参数，ETL 按地区逐个调度执行。
- **空结果风险**：若某地区在指定 7 天窗口内实验数据缺失（`model_id <= 0` 被过滤或 DWS 表无数据），`uplift_stats` 为空，导致 Top Model 视图为空，最终分区写入 0 行，查询时需注意。
- **`gmv_uplift` 过滤逻辑**：`top_order_models` 强制排除 `gmv_uplift = 0` 的模型，确保订单最优模型同时具备 GMV 增益，但若所有模型 `gmv_uplift` 均为 0，该视图同样为空。

---

*文档生成时间：2026-05-17*