<!-- ads-workspace-gdoc-sync: gdoc_id=16F_j1ttGX3aALBIy11p0zURa4lBKN-Uy4qKSim7tFRQ gdoc_url=https://docs.google.com/document/d/16F_j1ttGX3aALBIy11p0zURa4lBKN-Uy4qKSim7tFRQ/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_scenario_retention_30d

**分层：** DWS（数据服务层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `scenario_tag`
**分区：** `grass_region`（站点区域），`local_date`（业务日期）
**更新频率：** 每日调度，每次写入覆盖当日分区（INSERT INTO PARTITION）
**访问频次：** 934 次

---

## 业务描述

本表用于记录搜索/推荐实验分组（`exp_group_id`）在不同业务场景（`scenario_tag`）下的用户**留存率**与**复购率**，时间窗口为最近 30 天滚动视图。

**核心业务场景：**
- **实验效果评估**：衡量不同 A/B 实验分组对用户留存与复购行为的影响，支撑搜推策略迭代决策。
- **多周期对比**：提供 1 日、3 日、5 日、7 日四个时间窗口的留存率与复购率，方便跨周期横向比较用户粘性变化趋势。
- **场景细分分析**：通过 `scenario_tag` 区分不同搜推场景（如搜索、推荐频道等），支持场景层面的实验归因分析。

**适合回答的典型问题：**
- 某实验分组在特定场景下，次日/3日/7日用户留存率是多少？
- 各实验分组的复购率在不同时间窗口内如何变化？
- 对比控制组与实验组，哪个场景的用户粘性提升最显著？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 US、SG 等；分区键，查询时必须指定 |
| `local_date` | date | 业务日期分区键；含义为对应留存/复购观测窗口的基准日期（即实验用户行为发生的参照日），由 ETL 根据调度日期计算写入（`date_sub(${local_date}, N)`，N=1/3/5/7） |

### 维度：实验与场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | string | 实验分组 ID，标识 A/B 实验中的某一分组（如对照组、实验组） |
| `scenario_tag` | string | 业务场景标签，标识用户行为所属的搜推场景（如搜索、推荐等） |

### 指标：用户留存率

留存率定义：在基准日（`local_date` 对应的参照日，即 N 天前）有曝光（imp）的用户中，当日（调度日）仍有曝光的用户占比。

| 字段 | 类型 | 说明 |
|---|---|---|
| `retention_rate_a1` | double | 1 日留存率：1 天前有曝光的用户中，当日也有曝光的比例；当 `local_date = 调度日 - 1` 时该字段有值，其余窗口为 NULL |
| `retention_rate_a3` | double | 3 日留存率：3 天前有曝光的用户中，当日也有曝光的比例；当 `local_date = 调度日 - 3` 时该字段有值，其余窗口为 NULL |
| `retention_rate_a5` | double | 5 日留存率：5 天前有曝光的用户中，当日也有曝光的比例；当 `local_date = 调度日 - 5` 时该字段有值，其余窗口为 NULL |
| `retention_rate_a7` | double | 7 日留存率：7 天前有曝光的用户中，当日也有曝光的比例；当 `local_date = 调度日 - 7` 时该字段有值，其余窗口为 NULL |
| `retention_rate_a14` | double | 14 日留存率（当前已置为常量 0，对应逻辑已注释，暂不使用） |

### 指标：用户复购率

复购率定义：在基准日（N 天前）有下单（order）的用户中，在对应近 N 天窗口内也有下单的用户占比。

| 字段 | 类型 | 说明 |
|---|---|---|
| `repurchase_rate_a1` | double | 1 日复购率：1 天前有下单的用户中，当日也有下单的比例；当 `local_date = 调度日 - 1` 时该字段有值，其余窗口为 NULL |
| `repurchase_rate_a3` | double | 3 日复购率：3 天前有下单的用户中，近 3 天（含当日）也有下单的比例；当 `local_date = 调度日 - 3` 时该字段有值，其余窗口为 NULL |
| `repurchase_rate_a5` | double | 5 日复购率：5 天前有下单的用户中，近 5 天（含当日）也有下单的比例；当 `local_date = 调度日 - 5` 时该字段有值，其余窗口为 NULL |
| `repurchase_rate_a7` | double | 7 日复购率：7 天前有下单的用户中，近 7 天（含当日）也有下单的比例；当 `local_date = 调度日 - 7` 时该字段有值，其余窗口为 NULL |
| `repurchase_rate_a14` | double | 14 日复购率（当前已置为常量 0，对应逻辑已注释，暂不使用） |

### Hoodie 元数据字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `_hoodie_commit_time` | string | Hudi 提交时间戳 |
| `_hoodie_commit_seqno` | string | Hudi 提交序列号 |
| `_hoodie_record_key` | string | Hudi 记录主键 |
| `_hoodie_partition_path` | string | Hudi 分区路径 |
| `_hoodie_file_name` | string | Hudi 数据文件名 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须指定，该字段为分区键，不加条件将触发全分区扫描，严重影响性能。
   ```sql
   WHERE grass_region = 'US'
   ```
2. **`local_date`**：必须指定日期范围，避免全量扫描。注意 `local_date` 的语义是**观测窗口基准日**（调度日 - N），并非调度运行日期。

### 不可直接 SUM 的字段

- `retention_rate_a1/a3/a5/a7`、`repurchase_rate_a1/a3/a5/a7` 均为**比率型预聚合指标**（分子/分母已在 ETL 中聚合完成），**不可跨行直接 SUM 或 AVG**，对多分组/场景汇总时需重新获取原始分子分母数据（回溯上游表）或仅做行级别查询/展示。
- `retention_rate_a14` 和 `repurchase_rate_a14` 当前恒为 `0`（ETL 逻辑已注释），**不应用于任何实际计算**。

### 稀疏结构说明

每行中，**留存率和复购率字段仅有一个时间窗口有值，其余窗口均为 NULL**。这是因为 ETL 以 UNION ALL 方式将不同时间窗口拆分为独立行写入，`local_date` 对应的具体日期即标识该行属于哪个窗口：

| `local_date` 对应值 | 有值字段 |
|---|---|
| 调度日 - 1 | `retention_rate_a1`、`repurchase_rate_a1` |
| 调度日 - 3 | `retention_rate_a3`、`repurchase_rate_a3` |
| 调度日 - 5 | `retention_rate_a5`、`repurchase_rate_a5` |
| 调度日 - 7 | `retention_rate_a7`、`repurchase_rate_a7` |

查询特定窗口数据时，建议同时过滤 `local_date` 以避免混淆。

### 时效性说明

- 本表为 **T+1 每日调度**，数据反映截至调度日前 N 天的用户行为。
- 表名后缀 `_30d` 表示该表维护最近 30 天的滚动窗口分区，历史分区会被周期性清理，**不建议跨超过 30 天的历史查询**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `${schema}.dws_sr_data_warehouse_platform_user_exp_level_benchmark_1d` | 提供用户级别的实验分组、场景标签、每日曝光数（`imp_cnt`）及下单数（`order_cnt`）明细，作为计算留存与复购的基础数据 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_platform_user_exp_level_benchmark_1d（用户日级别行为明细）
    │
    ├──► tmp_exp_order_base（用户维度下单行为标记，近 7 天窗口）
    ├──► tmp_exp_imp_base（用户维度曝光行为标记，指定离散日期点）
    │
    └──► tmp_union_date（UNION ALL 合并 + 用户级别 MAX 去重）
             │
             └──► exp_retention_repurchase_result（CACHE TABLE，按实验分组+场景聚合，计算各时间窗口留存率与复购率）
                      │
                      └──► dws_sr_data_warehouse_platform_exp_scenario_retention_30d
                           （UNION ALL 拆分为 4 行/分组，分别写入不同 local_date 分区）
```

### 关键步骤

**Step 1：`tmp_exp_order_base`（临时视图）**
- 从上游表读取近 7 天（`date_add(local_date, -7)` 至 `local_date`）有下单记录（`order_cnt > 0`）的用户。
- 按用户+实验分组+场景，用 `MAX(CASE WHEN ...)` 打标：是否在当日/近 3 日/近 5 日/近 7 日下单（`order_aX_a0`），以及是否在 N 天前单日下单（`order_a1/a3/a5/a7`）。
- 曝光相关字段（`imp_aX`）在此视图中置为 NULL，占位用于后续 UNION。

**Step 2：`tmp_exp_imp_base`（临时视图）**
- 从上游表读取指定离散日期（当日、-1、-3、-5、-7 天）有曝光记录（`imp_cnt > 0`）的用户。
- 按用户+实验分组+场景，打标各离散日期点是否有曝光（`imp_a0/a1/a3/a5/a7`）。
- 下单相关字段在此视图中置为 NULL，占位用于后续 UNION。

**Step 3：`tmp_union_date`（临时视图）**
- 将 `tmp_exp_order_base` 与 `tmp_exp_imp_base` UNION ALL 合并。
- 按 `(exp_group_id, scenario_tag, user_id)` 分组，对所有标记字段取 MAX，得到每个用户在全部维度上的行为汇总标记。

**Step 4：`exp_retention_repurchase_result`（CACHE TABLE）**
- 在 `tmp_union_date` 基础上，按 `(exp_group_id, scenario_tag)` 聚合，计算各时间窗口的留存率与复购率：
  - **留存率**：`SUM(imp_aX = 1 AND imp_a0 = 1) / SUM(imp_aX)`（X 天前有曝光且当日也有曝光的用户比例）
  - **复购率**：`SUM(order_aY_a0 = 1 AND order_aX = 1) / SUM(order_aX)`（X 天前有下单且对应窗口内也有下单的用户比例）
  - `retention_rate_a14` 与 `repurchase_rate_a14` 硬编码为 `0`（对应 14 日窗口逻辑已注释）。
- 使用 `CACHE TABLE` 缓存结果，供后续多次 UNION ALL 扫描复用，避免重复计算。

**Step 5：INSERT INTO 目标表（最终写入）**
- 将 `exp_retention_repurchase_result` 通过 4 路 UNION ALL 展开，每路对应一个时间窗口（a1/a3/a5/a7），其余窗口字段置 NULL。
- 各路写入的 `local_date` 分别为 `date_sub(调度日, 1/3/5/7)`，以标识该行对应的观测基准日。
- 使用 `WHERE retention_rate_aX IS NOT NULL OR repurchase_rate_aX IS NOT NULL` 过滤无效行，避免写入全空数据。
- 通过 `INSERT INTO TABLE ... PARTITION (grass_region = ..., local_date)` 写入目标表，`local_date` 为动态分区。

### 注意事项

1. **稀疏写入设计**：目标表每次调度会向 4 个不同 `local_date` 分区写入数据（调度日 -1、-3、-5、-7），这意味着历史分区数据会被周期性地**追加覆盖**，查询时需注意同一 `local_date` 分区可能存在多次调度写入的数据。
2. **14 日窗口已废弃**：`retention_rate_a14` 和 `repurchase_rate_a14` 对应的 ETL 计算逻辑已全部注释，字段值恒为 `0` 或 `NULL`，**不可用于分析**。
3. **CACHE TABLE 依赖**：Step 4 使用 `CACHE TABLE` 缓存中间结果，若 Spark 集群内存不足，可能导致回退重算，影响任务性能。
4. **有效用户过滤**：上游数据源过滤了 `COALESCE(user_id, 0) > 0`，即排除了匿名用户（user_id 为 NULL 或 0 的记录），留存与复购率仅统计有效登录用户群体。
5. **单一 ETL 文件写入**：本表为单 writer，不存在多文件并发写入的分区竞争风险。

---

*文档生成时间：2026-05-17*