<!-- ads-workspace-gdoc-sync: gdoc_id=1-72nsRUzTg3nNVX4R0MAwLQjbYsOT8GmYK_dr4P16ME gdoc_url=https://docs.google.com/document/d/1-72nsRUzTg3nNVX4R0MAwLQjbYsOT8GmYK_dr4P16ME/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_reward_model_exp_level_1d

**分层：** DWS（数据仓库汇总层）
**主键：** `model_id` + `item_id` + `shop_id` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**访问频次：** 691 次

---

## 业务描述

本表为搜推（SR）数据仓库针对 **Push Bar（PB）奖励模型（Reward Model）A/B 实验** 的 Item 粒度日级聚合表，记录每个模型（`model_id`）× 商品（`item_id`）× 店铺（`shop_id`）维度下，实验组（treatment）与对照组（control）的曝光量、GMV 等核心指标，并附带归一化处理后的对比指标与 Uplift 计算结果。

**核心业务场景：**
- 评估 PB 奖励模型实验中各模型对具体商品/店铺的流量与 GMV 贡献差异；
- 对比 treatment 组与 control 组的曝光量及 GMV，计算归一化后的实验效果；
- 判断某模型在当日是否为"获胜模型"（`is_win_day`），支持模型竞争决策；
- 结合 CSPU（商品池单元）粒度的曝光/GMV，评估奖励模型对商品池整体的影响。

**适合回答的问题：**
- 某大区某日，各奖励模型在 item/shop 维度上的 treatment 相较 control 曝光提升比例是多少？
- 哪些模型在当日获胜（`is_win_day = 1`）？
- 某 item 在实验组与对照组的 GMV 差异及归一化后的效果如何？
- 各模型对应 CSPU 维度的曝光量与 GMV 汇总情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`MY` 等，ETL 按大区独立写入分区 |
| `local_date` | date | 业务日期（本地时间），数据统计所属自然日 |

### 维度：模型 × 商品 × 店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_id` | bigint | 奖励模型 ID，PB 实验中的推荐模型标识 |
| `item_id` | bigint | 商品 ID，ETL 过滤 `item_id > 0` |
| `shop_id` | bigint | 店铺 ID，ETL 过滤 `shop_id > 0` |

### 指标：实验分组标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_win_day` | bigint | 当日是否为获胜模型：1 表示该 model_id 在当日为获胜模型（business_type in (3,4)），0 表示否 |

### 指标：全量曝光与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 该 item 在当日的全量曝光次数（不区分实验分组） |
| `gmv` | double | 该 model 在当日的全量 GMV（不区分实验分组，按 model 维度汇总） |

### 指标：实验组 vs 对照组原始值

| 字段 | 类型 | 说明 |
|---|---|---|
| `control_imp_cnt` | bigint | 对照组（control）曝光次数，用于实验对比基线 |
| `treatment_imp_cnt` | bigint | 实验组（treatment）曝光次数，归一化前的原始值 |
| `control_gmv` | double | 对照组（control）GMV |
| `treatment_gmv` | double | 实验组（treatment）GMV，归一化前的原始值 |

### 指标：归一化后的实验组指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `treatment_imp_cnt_normal` | double | 归一化后的实验组曝光量，计算方式：`treatment_imp_cnt / normalization_value` |
| `treatment_gmv_normal` | double | 归一化后的实验组 GMV，计算方式：`treatment_gmv / normalization_value` |

### 指标：Uplift 与归一化系数

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_1d_uplift_pct` | double | 当日曝光量 Uplift 比例（归一化后 treatment 相对 control 的提升率）；当 `control_imp_cnt > 0` 时为 `treatment_imp_cnt_normal / control_imp_cnt - 1`；当 treatment 有量而 control 无量时为 1.0；否则为 0 |
| `normalization_value` | double | 归一化系数，即 treatment 去重用户数 / control 去重用户数，用于消除实验分组用户规模差异 |

### 指标：CSPU 粒度汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt` | bigint | 该 item 所属 CSPU 的全量曝光次数（按 cspu+item 维度聚合） |
| `cspu_gmv` | double | 该 model 所属 CSPU 的全量 GMV（按 cspu+model 维度聚合） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则将触发全表扫描，影响性能：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-01-01'
  ```
- 本表每次写入均为 `INSERT OVERWRITE` 按 `(grass_region, local_date)` 分区覆写，查询时务必指定两个分区字段。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `normalization_value` | 为整体比值（去重用户数之比），直接 SUM 无业务意义，跨 model/item 汇总时需重新计算 |
| `imp_cnt_1d_uplift_pct` | 预计算的比率指标，不可直接 SUM，汇总时需基于 `control_imp_cnt`、`treatment_imp_cnt_normal` 重新推导 |
| `treatment_imp_cnt_normal` | 归一化后的派生指标，直接 SUM 仅在相同 `normalization_value` 下有意义，跨实验聚合须谨慎 |
| `treatment_gmv_normal` | 同上，为归一化派生指标 |
| `cspu_imp_cnt` | CSPU 维度预聚合值，同一 CSPU 下多条记录该字段值相同，多 item/model 汇总时会重复计数 |
| `cspu_gmv` | 同上，CSPU 维度预聚合值，多 model 汇总时会重复计数 |

### 时效性说明

- 本表为 **日级（`_1d`）** 汇总表，数据粒度为自然日，每日 T+1 全量刷新当日分区。
- 不支持小时级实时查询，日内数据以最新一次写入为准。
- `is_win_day` 字段基于当日维表（`dim_sr_data_warehouse_pb_one_variation_model_analysis_hf`）计算，反映的是当日模型竞争结果，不具有跨日累计含义。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 获取 CSPU → model_id / item_id / shop_id 的关联映射，按小时粒度 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 获取原始流量数据（曝光量、GMV），过滤 `mapping_general = '__ALL__'` |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取 A/B 实验分组信息（exp_group_id 452506~452525），区分 treatment / control 用户 |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 获取当日获胜模型列表（business_type in (3,4)），用于计算 `is_win_day` |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf   ──┐
                                                        ├──► all_cspu_model（CSPU-模型-商品-店铺映射）
                                                        └──► all_cspu_item（CSPU-商品映射）
dws_sr_data_warehouse_tc_pb_basic_aggr_1d            ──► traffic_raw（原始流量，按 user/item/model 汇总）
dim_sr_data_warehouse_abtest_user_group              ──► exp_group（用户实验分组 treatment/control）
                                                        │
traffic_raw + exp_group                              ──► traffic_exp（带分组的流量）
                                                        │
all_cspu_model + traffic_exp                         ──► model_traffic_hourly（小时级 CSPU×model×item 维度分组流量）
traffic_raw（all）                                   ──► traffic_all（model×item 汇总，无分组）
traffic_all + all_cspu_model                         ──► cspu_model_level（CSPU 维度 GMV）
traffic_all + all_cspu_item                          ──► cspu_item_level（CSPU 维度曝光量）
                                                        │
model_traffic_hourly + cspu_model_level + cspu_item_level ──► model_cspu_traffic_daily（按 model/item/shop 日粒度汇总）
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf ──► winner（获胜模型集合）
exp_group                                            ──► normalization（treatment/control 用户数之比）
                                                        │
model_cspu_traffic_daily + winner + normalization    ──► model_join（最终指标合并）
                                                        │
                                                        └──► INSERT OVERWRITE 目标表（过滤 item_id>0, shop_id>0）
```

### 关键步骤

1. **`all_cspu_model`**：从 CSPU 维表中提取指定大区、日期的 CSPU → model_id / item_id / shop_id 小时级映射，作为关联骨架。
2. **`all_cspu_item`**：在 `all_cspu_model` 基础上对 cspu+item 去重，用于后续 CSPU 曝光量关联。
3. **`traffic_raw`**：从基础聚合表中提取流量（`mapping_general = '__ALL__'`），按 local_hour / user_id / item_id / model_id 粒度汇总 imp_cnt 和 GMV。
4. **`exp_group`**：从实验分组维表中获取 exp_group_id 452506~452524 归为 treatment，452525 归为 control，过滤已分配日志（`is_assignment_log = 1`）。
5. **`traffic_exp`**：将 `traffic_raw` 与 `exp_group` 按 user_id 关联，得到带实验分组标签的小时级 item/model 流量。
6. **`model_traffic_hourly`**：以 `all_cspu_model` 为基准，通过 UNION ALL 分别将 item 维度的曝光量和 model 维度的 GMV 挂载到 CSPU 粒度（曝光量按 item 关联，GMV 按 model 关联），再 LEFT JOIN 后按 control/treatment 条件聚合，得到小时级 CSPU×model×item 的分组流量。
7. **`traffic_all`**：`traffic_raw` 按 local_hour / model_id / item_id 汇总全量流量（不区分实验分组）。
8. **`cspu_model_level`**：`traffic_all` 按 model 维度关联 `all_cspu_model`，聚合得到 CSPU 粒度的全量 GMV。
9. **`cspu_item_level`**：`traffic_all` 按 item 维度关联 `all_cspu_item`，聚合得到 CSPU 粒度的全量曝光量。
10. **`model_cspu_traffic_daily`**：将 `model_traffic_hourly`、`cspu_model_level`、`cspu_item_level` 按 cspu_id 和 local_hour 关联，汇总为日级 model × item × shop 粒度指标。
11. **`winner`**：从获胜模型维表中提取当日 business_type in (3,4) 的获胜 model_id 集合。
12. **`normalization`**：从 `exp_group` 中统计 treatment 去重用户数与 control 去重用户数之比，得到归一化系数（全局单值，广播 JOIN）。
13. **`model_join`**：将 `model_cspu_traffic_daily` 与 `winner`（LEFT JOIN 标记 `is_win_day`）、`normalization`（笛卡尔 JOIN）、item 维度全量 imp_cnt、model 维度全量 GMV 合并，组装全部指标。
14. **`INSERT OVERWRITE`**：从 `model_join` 中选取所有目标字段，计算 `treatment_imp_cnt_normal`、`treatment_gmv_normal`、`imp_cnt_1d_uplift_pct`，过滤 `item_id > 0 AND shop_id > 0` 后写入目标分区。

### 注意事项

- **单文件单写入**：本表仅有一个 ETL 文件，无 multi-writer 风险，分区写入按 `(grass_region, local_date)` 执行 INSERT OVERWRITE。
- **`normalization_value` 为全局单值**：通过 `on 1=1` 笛卡尔积广播到所有行，若实验分组数据缺失（control 用户数为 0），将导致除零或 NULL，需关注上游实验分组维表的数据完整性。
- **CSPU 流量归因逻辑**：`model_traffic_hourly` 中曝光量按 item 维度关联，GMV 按 model 维度关联，两者归因口径不同，`cspu_imp_cnt` 与 `cspu_gmv` 统计维度有差异，跨字段对比时须注意。
- **`exp_group_id` 硬编码**：实验分组 ID 范围（452506~452525）在 SQL 中硬编码，若实验配置变更，ETL 代码需同步更新。
- **过滤条件**：最终写入时过滤 `item_id > 0 AND shop_id > 0`，异常维度数据不会进入目标表。
- **模板变量**：SQL 中使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等模板变量，由调度系统注入，每次执行仅处理单一大区单日数据。

---

*文档生成时间：2026-05-17*