<!-- ads-workspace-gdoc-sync: gdoc_id=1Sv0AIAWHphAfhrpihRbxH9lNwAbLXdJWxUEs5UnISWE gdoc_url=https://docs.google.com/document/d/1Sv0AIAWHphAfhrpihRbxH9lNwAbLXdJWxUEs5UnISWE/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_group_metrics_14d_30d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `experiment_id` + `exp_group_id`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日（T+1 离线调度）
**引用频次 / 访问频次：** 709

---

## 业务描述

本表为搜索域 A/B 实验组维度的**双窗口汇总宽表**，记录各实验组在统计日（`local_date`）对应的 **近 14 天** 和 **近 30 天** 搜索行为与成交指标。

**核心业务场景：**
- 搜索 A/B 实验效果评估：按实验（`experiment_id`）、实验组（`exp_group_id`）维度对比 GMV、订单量、搜索活跃 UV 等关键指标
- 实验长周期观测：同时提供 14 天和 30 天两个滚动窗口，支持短期效果与长期留存的双口径分析
- 多场景覆盖：涵盖全站搜索（`global_search`）、PDP 内搜索（`search_in_pdp`）、预填充搜索（`search_prefill`）三类搜索场景
- 实验维度下钻：结合实验层（`layer_id/layer_name`）与实验场景（`scene_id/scene_name`）做多维交叉分析

**适合回答的问题举例：**
- 某实验组在过去 14/30 天内的搜索 UV、订单 UV、GMV 各是多少？
- 不同实验组之间的成交转化率和 GMV 表现是否存在显著差异？
- 某实验在最近 30 天的整体效果趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 `SG`、`MY`、`TH` 等，每个分区对应一个区域 |
| `local_date` | date | 业务统计日期，即数据截止日期，14d/30d 窗口均以该日期为右边界 |

### 维度：实验维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来自实验维表 `dim_sr_data_warehouse_abtest_group` |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID，用于区分同一场景下的不同实验层 |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID，当前仅包含白名单实验（54616、15367、188150） |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验组 ID，主键之一；来自搜索用户分组与实验分组的 FULL JOIN |
| `exp_group_name` | string | 实验组名称 |

### 指标：搜索活跃用户（近 14 天 / 近 30 天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu_14d` | bigint | 近 14 天内有搜索曝光行为（`view_cnt > 0`）且命中该实验组的去重用户数 |
| `search_uu_30d` | bigint | 近 30 天内有搜索曝光行为（`view_cnt > 0`）且命中该实验组的去重用户数 |

### 指标：订单与 GMV（近 14 天 / 近 30 天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt_14d` | double | 近 14 天内搜索带来的订单量（来自 item/video/livestream 目标类型，`page_section IS NULL`） |
| `order_uu_14d` | bigint | 近 14 天内搜索带来至少 1 笔订单的去重用户数 |
| `gmv_14d` | double | 近 14 天内搜索带来的 GMV（成交金额） |
| `order_cnt_30d` | double | 近 30 天内搜索带来的订单量 |
| `order_uu_30d` | bigint | 近 30 天内搜索带来至少 1 笔订单的去重用户数 |
| `gmv_30d` | double | 近 30 天内搜索带来的 GMV（成交金额） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须过滤分区字段**，同时指定 `grass_region` 与 `local_date`，否则将触发全表扫描，消耗大量资源：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-06-30'
  ```
- `local_date` 为滚动窗口的右边界（截止日），每个 `local_date` 分区已预聚合了对应的 14d/30d 数据，**不应跨多个 `local_date` 分区进行行级累加**。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `search_uu_14d` / `search_uu_30d` | 去重用户数（COUNT DISTINCT），跨分组/跨日期直接 SUM 会重复计数 |
| `order_uu_14d` / `order_uu_30d` | 去重用户数（COUNT DISTINCT），同上 |
| `order_cnt_14d` / `order_cnt_30d` | 预聚合滚动窗口指标，跨多个 `local_date` 分区 SUM 会造成数据重叠累加 |
| `gmv_14d` / `gmv_30d` | 预聚合滚动窗口指标，同上 |

- 若需跨实验组对比，请在**同一 `local_date` 分区内**按组汇总，不要对 UV 类字段做跨组 SUM。
- 转化率、人均 GMV 等比率指标需在应用层用分子/分母字段自行计算，不可通过对现有字段直接聚合得到。

### 时效性说明

- 本表为 **T+1 离线日更表**，当天数据次日产出。
- `*_14d` / `*_30d` 后缀代表以 `local_date` 为右边界的滚动窗口，非累计值，每日全量覆盖（`INSERT OVERWRITE`）对应分区。
- 实验分组数据来源于 `dim_sr_data_warehouse_abtest_user_group` 的 `is_assignment_log = 1` 记录，仅包含已正式分组的用户，灰度阶段可能存在用户数偏少的情况。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验维表，提供实验/实验层/实验场景/实验组的维度信息；仅取搜索白名单实验（`is_search_whitelist = 1`）及指定 `experiment_id` |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户实验分组表，提供用户与实验组的映射关系（近 30 天窗口，仅取正式分组记录） |
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 搜索 SRP 用户每日基准指标表，提供用户维度的搜索曝光量、订单量、GMV 等 1d 粒度数据 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_group          → dim_exp（实验维度信息）
dim_sr_data_warehouse_abtest_user_group     → user_exp_mapping（用户-实验组映射，近30天）
dws_sr_data_warehouse_search_srp_user_benchmark_1d → dwd_view_metric（搜索曝光用户日粒度）
                                              → dwd_order_metrics（搜索订单/GMV 日粒度）

user_exp_mapping JOIN dwd_view_metric       → dws_search_uu_metrics（搜索 UV 汇总）
user_exp_mapping JOIN dwm_order_metrics     → dws_order_metrics（订单/GMV 汇总）

dws_search_uu_metrics FULL JOIN dws_order_metrics LEFT JOIN dim_exp
                                            → 目标表（按 grass_region + local_date 分区写入）
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `dim_exp` | 从实验维表拉取指定日期、搜索白名单内的实验组维度信息（限定 3 个 `experiment_id`） |
| 2 | `user_exp_mapping` | 从用户分组表拉取近 30 天（`[local_date-30, local_date]`）的用户-实验组分配记录，仅取正式分组（`is_assignment_log = 1`） |
| 3 | `dwd_view_metric` | 从 SRP 基准表提取近 30 天内三类搜索场景下有曝光（`view_cnt > 0`）的用户日记录 |
| 4 | `dws_search_uu_metrics` | `user_exp_mapping` JOIN `dwd_view_metric`（按 user_id + local_date），分别用 COUNT DISTINCT + IF 条件计算 14d 和 30d 的搜索 UV |
| 5 | `dwd_order_metrics` | 从 SRP 基准表提取近 30 天内三类搜索场景下（`page_section IS NULL`，`target_type IN ('item','video','livestream')`）的用户日订单量与 GMV |
| 6 | `dwm_order_metrics` | 对 `dwd_order_metrics` 按 user_id + local_date 再次汇总（预防上游多行重复） |
| 7 | `dws_order_metrics` | `user_exp_mapping` JOIN `dwm_order_metrics`，分别用 SUM + IF / COUNT DISTINCT + IF 计算 14d/30d 的订单量、订单 UV、GMV |
| 8 | **INSERT OVERWRITE** | `dws_search_uu_metrics` FULL JOIN `dws_order_metrics`（按 `exp_group_id`），LEFT JOIN `dim_exp` 补充维度，写入目标表对应 `grass_region` + `local_date` 分区 |

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表由单个 ETL 文件写入，不存在多文件并发写同一分区的问题。
- **INSERT OVERWRITE 全量覆盖**：每次调度对指定 `(grass_region, local_date)` 分区做全量覆盖，重跑安全。
- **FULL JOIN 导致 `exp_group_id` 可能为 NULL**：搜索 UV 和订单两条链路通过 FULL JOIN 合并，最终写入时使用 `COALESCE(a.exp_group_id, b.exp_group_id)` 取非空值；但若某实验组仅有搜索行为或仅有订单行为，另一侧指标将为 NULL，下游使用时需注意 NULL 处理。
- **实验 ID 白名单硬编码**：`experiment_id IN (54616, 15367, 188150)` 在两个上游 VIEW 中均有硬编码过滤，新增实验需同步修改 ETL SQL。
- **`${grass_region_without_quote}` 参数**：Temporary View 命名使用不含引号的区域变量以避免 SQL 命名冲突，与 `WHERE` 条件中的 `${grass_region}` 为同一区域的不同格式参数。
- **搜索场景过滤一致性**：搜索 UV 链路和订单链路均限定 `page_type IN ('global_search','search_in_pdp','search_prefill')`，两者口径对齐；但订单链路额外增加 `page_section IS NULL` 和 `target_type` 限制，需注意与 UV 口径的差异。

---

*文档生成时间：2026-05-17*