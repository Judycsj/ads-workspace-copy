<!-- ads-workspace-gdoc-sync: gdoc_id=1OlX5PXa3DHSnnZVOdaVoBcVpQzz-WFPpHBX_vYny9VM gdoc_url=https://docs.google.com/document/d/1OlX5PXa3DHSnnZVOdaVoBcVpQzz-WFPpHBX_vYny9VM/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_repurchase_days_180d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `platform` + `scenario_tag` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）/ `local_date`（日期）
**更新频率：** 每日（T+1）
**访问频次：** 686

---

## 业务描述

本表面向搜推（SR）A/B 实验体系，以**实验分组（exp_group_id）× 平台（platform）× 场景标签（scenario_tag）**为维度，统计过去 30 / 60 / 90 / 180 天内各实验分组用户的**复购间隔天数分布**，包含均值及 25/50/75/90 分位数共 20 个指标。

**核心业务场景：**
- A/B 实验效果评估：评估不同实验分组在不同时间窗口下对用户复购间隔的影响；
- 平台差异分析：对比 iOS App、Android App 及其他平台用户的复购行为；
- 场景精细化运营：通过 `scenario_tag` 区分推荐、搜索等不同场景（`DA_*` 前缀场景及全量 `__ALL__`）下的复购间隔分布。

**适合回答的典型问题：**
- 某实验分组用户在过去 90 天内，iOS 平台下的复购间隔中位数是多少？
- 与对照组相比，实验组用户 180 天复购间隔的 P90 是否显著更短？
- 在特定推荐场景下，各实验分组的平均复购间隔趋势如何变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区分区，如 SG、BR 等；每次写入固定覆盖单一大区分区 |
| `local_date` | date | 业务日期分区，即统计基准日（当天）；所有时间窗口以该日期为终点向前推算 |

### 维度：实验分组与业务场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`；仅包含满足白名单和日志归因条件的用户所在分组 |
| `platform` | string | 用户下单所在平台，取值为 `ios_app`、`android_app` 或 `others`（其余平台合并）；CUBE 展开后 `__ALL__` 表示全平台汇总 |
| `scenario_tag` | string | 业务场景标签，仅包含 `DA_` 前缀的场景及 `__ALL__`（全场景汇总） |

### 指标：各时间窗口复购间隔均值（天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_repurchase_days_30` | double | 过去 30 天内，该分组用户复购间隔天数的加权均值（以用户数为权重）。计算方式：（最晚购买日 - 最早购买日）÷（购买天数 - 1），仅统计购买天数 > 1 的用户 |
| `avg_repurchase_days_60` | double | 过去 60 天内复购间隔天数加权均值，计算逻辑同上 |
| `avg_repurchase_days_90` | double | 过去 90 天内复购间隔天数加权均值，计算逻辑同上 |
| `avg_repurchase_days_180` | double | 过去 180 天内复购间隔天数加权均值，计算逻辑同上 |

### 指标：各时间窗口复购间隔 25 分位数（天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `25pct_repurchase_days_30` | double | 过去 30 天内复购间隔天数的 P25（第 25 百分位数），基于分组内用户分布用累计用户数近似计算 |
| `25pct_repurchase_days_60` | double | 过去 60 天内复购间隔天数的 P25 |
| `25pct_repurchase_days_90` | double | 过去 90 天内复购间隔天数的 P25 |
| `25pct_repurchase_days_180` | double | 过去 180 天内复购间隔天数的 P25 |

### 指标：各时间窗口复购间隔 50 分位数（天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `50pct_repurchase_days_30` | double | 过去 30 天内复购间隔天数的 P50（中位数） |
| `50pct_repurchase_days_60` | double | 过去 60 天内复购间隔天数的 P50 |
| `50pct_repurchase_days_90` | double | 过去 90 天内复购间隔天数的 P50 |
| `50pct_repurchase_days_180` | double | 过去 180 天内复购间隔天数的 P50 |

### 指标：各时间窗口复购间隔 75 分位数（天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `75pct_repurchase_days_30` | double | 过去 30 天内复购间隔天数的 P75 |
| `75pct_repurchase_days_60` | double | 过去 60 天内复购间隔天数的 P75 |
| `75pct_repurchase_days_90` | double | 过去 90 天内复购间隔天数的 P75 |
| `75pct_repurchase_days_180` | double | 过去 180 天内复购间隔天数的 P75 |

### 指标：各时间窗口复购间隔 90 分位数（天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `90pct_repurchase_days_30` | double | 过去 30 天内复购间隔天数的 P90 |
| `90pct_repurchase_days_60` | double | 过去 60 天内复购间隔天数的 P90 |
| `90pct_repurchase_days_90` | double | 过去 90 天内复购间隔天数的 P90 |
| `90pct_repurchase_days_180` | double | 过去 180 天内复购间隔天数的 P90 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则将全量扫描所有历史分区，产生大量不必要的计算开销。通常取最新的业务日期，例如：`WHERE local_date = '2024-06-30'`。
- **`grass_region`**：必须指定，跨大区汇总需在应用层手动合并，不可直接在 SQL 中省略该条件做全表聚合。

### 不可直接 SUM 的字段

以下所有指标均为**预聚合派生指标**，跨分组或跨场景横向叠加无业务意义，**禁止直接 SUM**：

| 字段类型 | 字段示例 | 原因 |
|---|---|---|
| 均值 | `avg_repurchase_days_*` | 加权均值，分子/分母均未单独存储，不可直接累加 |
| 分位数 | `25pct_*`、`50pct_*`、`75pct_*`、`90pct_*` | 分位数不满足加法可加性，跨行 SUM 无意义 |

- 如需跨实验分组比较，应直接在行级对应字段做比较，而非求和。
- `platform = '__ALL__'` 行已包含全平台汇总，与其他 platform 行存在**数据重叠**，分析时须选定一个口径，避免重复计算。

### 时效性说明

- 本表为**每日快照表**，每个 `local_date` 分区对应一次全量覆盖写入（`INSERT OVERWRITE`）。
- 时间窗口为**滚动 N 天**（30 / 60 / 90 / 180），以 `local_date` 为截止日向前推算，不是累计至今（non-TD）。
- 历史分区不会追溯更新，若上游数据补录，需重跑对应 `local_date` 分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供 A/B 实验用户分组信息，筛选条件：`is_assignment_log = 1`、`is_rcmd_search_whitelist = 1`、`user_id > 0`，取指定 `local_date` 的分组快照 |
| `srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d` | 提供用户级别每日下单记录，读取过去 180 天数据，筛选条件：`order_cnt > 0`、`feature_detail = '__ALL__'`，用于计算各时间窗口下用户的购买日期分布 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
                                            ├──► JOIN (user_id) ──► 复购间隔计算 ──► 分位数展开 ──► PIVOT写入目标表
dws_sr_data_warehouse_platform_user_level_benchmark_1d (近180天) ──┘
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `exp_group_data` | 从 A/B 实验用户分组维度表中提取当日满足白名单条件的用户与其实验分组映射 |
| Step 2 | `order_data` | 从用户下单基准表中拉取过去 180 天的有效下单记录，将平台归类为 `ios_app`、`android_app`、`others`，按用户 + 平台 + 场景 + 日期去重聚合 |
| Step 3 | `order_data_180d` | 对 Step 2 结果按用户 + 场景进行 CUBE（对 platform 维度 CUBE 展开，生成全平台汇总行），统计各时间窗口（30/60/90/180天）内的购买天数、最早购买日、最晚购买日 |
| Step 4 | `order_cube_data` | 基于最早/最晚购买日及购买天数，计算各时间窗口的**个人平均复购间隔**：`(max_date - min_date) / (days_count - 1)`，购买天数 ≤ 1 的用户该字段为 NULL |
| Step 5 | `order_explode_data` | 使用 `LATERAL VIEW STACK` 将宽表中4个时间窗口的均值列纵向展开为 `(day_type, avg_repurchase_days)` 两列，过滤掉 NULL 行 |
| Step 6 | `join_table` | 将实验分组数据（Step 1）与展开后的复购间隔数据（Step 5）按 `user_id` INNER JOIN，按（分组 + 平台 + 场景 + 时间窗口 + 复购间隔值）聚合用户数 `uu` |
| Step 7 | `window_table` | 使用窗口函数，按（平台 + 分组 + 场景 + 时间窗口）分组，对 `avg_repurchase_days` 升序排列，计算累计用户数 `cum_uu_cnt` 和总用户数 `total_uu` |
| Step 8 | `percentile_table` | 在 Step 7 基础上，用 `CEIL(pct * total_uu)` 定位分位数对应的 `avg_repurchase_days` 值，同时计算加权均值；输出4个分位数 + 均值共5个指标 |
| Step 9（写入） | — | 从 `percentile_table` PIVOT（按 `day_type` 行转列），输出20个指标字段，`INSERT OVERWRITE` 写入目标表指定分区，文件重分区为10个 |

### 注意事项

- **单一写入来源**：本表为 single-writer，仅有一个 ETL 文件，不存在多文件并发写入同一分区的风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE PARTITION (grass_region, local_date)` 模式，每次执行覆盖指定大区和日期的分区，历史分区数据不受影响。
- **分位数精度**：分位数基于预先分组聚合（`join_table` 中相同复购间隔值合并为一行）后通过累计用户数近似计算，与原始数据的精确 `percentile` 函数存在微小差异，属设计取舍。
- **NULL 过滤**：`avg_repurchase_days` 为 NULL（购买天数 ≤ 1）的用户在 Step 5 已被过滤，不参与分组统计，导致该分组的指标仅反映有复购行为的用户。
- **平台 CUBE 重叠**：`platform = '__ALL__'` 行由 CUBE 生成，与具体平台行存在用户重叠，查询时需单独选择一个 `platform` 值，避免双重计数。
- **参数化执行**：ETL SQL 使用 `${local_date}`、`${grass_region}`、`${grass_region_without_quote}` 等参数化变量，不同大区的 Temporary View 通过后缀区分，每次调度针对单一大区执行。

---

*文档生成时间：2026-05-17*