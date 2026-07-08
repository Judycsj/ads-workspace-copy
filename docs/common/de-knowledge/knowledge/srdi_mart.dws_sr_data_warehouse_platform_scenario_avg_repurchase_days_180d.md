<!-- ads-workspace-gdoc-sync: gdoc_id=1F9hzOiqIheslNw2KBPUSdiROl22_zb_J5bpqGXHdcrw gdoc_url=https://docs.google.com/document/d/1F9hzOiqIheslNw2KBPUSdiROl22_zb_J5bpqGXHdcrw/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_avg_repurchase_days_180d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `platform` + `scenario_tag`
**分区：** `grass_region`（地区）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次：** 907

---

## 业务描述

本表统计各平台（`platform`）× 场景标签（`scenario_tag`）维度下，用户在近 30 / 60 / 90 / 180 天多个时间窗口内的**平均复购间隔天数**分布情况，包括均值及 25th、50th、75th、90th 四个百分位数。

**核心业务场景：**
- 评估不同平台和业务场景的用户复购活跃度与复购节律；
- 识别高频复购与低频复购用户群体的分布差异；
- 为搜推策略（频次控制、触达时机）提供数据支撑；
- 对比 30 / 60 / 90 / 180 天窗口，观察复购周期随观察窗口变化的规律。

**适合回答的问题：**
- 某平台在某场景下，过去 30 天内用户平均多久复购一次？
- 不同场景的复购间隔中位数（50th 分位）是多少？
- 复购间隔的长尾分布（90th 分位）在各时间窗口下有何差异？
- 各区域、各平台的复购节律对比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区标识，如 `ID`、`TH` 等；查询时必须显式指定 |
| `local_date` | date | 业务日期分区，即统计截止日期；查询时必须显式指定 |

### 维度：平台与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 用户所在平台；`ios_app` 和 `android_app` 保留原值，其余归并为 `others` |
| `scenario_tag` | string | 业务场景标签，来源于上游用户基准表的 `scenario_tag` 字段 |

### 指标：平均复购间隔天数（均值）

> 计算方式：对窗口内有订单的有效购买日去重后，取（最大购买日 − 最小购买日）/ （购买天数 − 1）得到每用户的平均复购间隔，再对所有用户求均值。仅有 1 天购买记录的用户不参与计算（值为 null）。

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_repurchase_days_30` | double | 近 30 天窗口内，用户平均复购间隔天数的均值 |
| `avg_repurchase_days_60` | double | 近 60 天窗口内，用户平均复购间隔天数的均值 |
| `avg_repurchase_days_90` | double | 近 90 天窗口内，用户平均复购间隔天数的均值 |
| `avg_repurchase_days_180` | double | 近 180 天窗口内，用户平均复购间隔天数的均值 |

### 指标：复购间隔天数分布（25th 百分位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `25pct_repurchase_days_30` | double | 近 30 天窗口内，用户平均复购间隔天数的 25th 百分位数（近似值） |
| `25pct_repurchase_days_60` | double | 近 60 天窗口内，用户平均复购间隔天数的 25th 百分位数（近似值） |
| `25pct_repurchase_days_90` | double | 近 90 天窗口内，用户平均复购间隔天数的 25th 百分位数（近似值） |
| `25pct_repurchase_days_180` | double | 近 180 天窗口内，用户平均复购间隔天数的 25th 百分位数（近似值） |

### 指标：复购间隔天数分布（50th 百分位 / 中位数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `50pct_repurchase_days_30` | double | 近 30 天窗口内，用户平均复购间隔天数的 50th 百分位数（近似值） |
| `50pct_repurchase_days_60` | double | 近 60 天窗口内，用户平均复购间隔天数的 50th 百分位数（近似值） |
| `50pct_repurchase_days_90` | double | 近 90 天窗口内，用户平均复购间隔天数的 50th 百分位数（近似值） |
| `50pct_repurchase_days_180` | double | 近 180 天窗口内，用户平均复购间隔天数的 50th 百分位数（近似值） |

### 指标：复购间隔天数分布（75th 百分位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `75pct_repurchase_days_30` | double | 近 30 天窗口内，用户平均复购间隔天数的 75th 百分位数（近似值） |
| `75pct_repurchase_days_60` | double | 近 60 天窗口内，用户平均复购间隔天数的 75th 百分位数（近似值） |
| `75pct_repurchase_days_90` | double | 近 90 天窗口内，用户平均复购间隔天数的 75th 百分位数（近似值） |
| `75pct_repurchase_days_180` | double | 近 180 天窗口内，用户平均复购间隔天数的 75th 百分位数（近似值） |

### 指标：复购间隔天数分布（90th 百分位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `90pct_repurchase_days_30` | double | 近 30 天窗口内，用户平均复购间隔天数的 90th 百分位数（近似值） |
| `90pct_repurchase_days_60` | double | 近 60 天窗口内，用户平均复购间隔天数的 90th 百分位数（近似值） |
| `90pct_repurchase_days_90` | double | 近 90 天窗口内，用户平均复购间隔天数的 90th 百分位数（近似值） |
| `90pct_repurchase_days_180` | double | 近 180 天窗口内，用户平均复购间隔天数的 90th 百分位数（近似值） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，每次查询必须指定，否则触发全分区扫描，性能极差。示例：`WHERE grass_region = 'ID'`
- **`local_date`**：分区字段，通常取单日快照（截止日期）。示例：`AND local_date = '2024-06-30'`
- 若需跨日对比，建议限定少量日期区间，避免无界扫描。

### 不可直接 SUM 的字段

以下所有指标字段均为**预聚合派生均值或近似百分位数**，跨行 SUM 无业务意义，不可直接叠加：

| 字段类别 | 原因 |
|---|---|
| `avg_repurchase_days_*` | 已是用户级均值再聚合的组合均值，二次 SUM 会导致量纲错误 |
| `25pct_` / `50pct_` / `75pct_` / `90pct_repurchase_days_*` | `percentile_approx` 结果，不满足加法可加性，不可跨分组 SUM 或 AVG |

如需跨 `platform` 或 `scenario_tag` 汇总，须回溯至上游用户明细表重新计算。

### 时效性说明

- 本表为**每日全量快照**，每个 `local_date` 分区包含截至当日的多窗口统计结果；
- 各指标均为**滑动窗口**（30 / 60 / 90 / 180 天），`local_date` 代表窗口终点，窗口起点动态计算；
- 数据通常在次日产出，不具备实时性，使用前请确认最新可用分区日期。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d` | 提供用户级每日有效订单记录（`order_cnt > 0`），用于计算各用户在不同时间窗口内的购买天数、最早 / 最晚购买日期，进而推导复购间隔 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d
    │  过滤：指定 grass_region、近 180 天、feature_detail = '__ALL__'、order_cnt > 0
    ▼
Temporary View: dws_base_data_${grass_region_without_quote}
    │  字段：user_id、platform（归并为 ios_app / android_app / others）、scenario_tag、local_date
    ▼
t0：用户 × 场景 × 日期去重（GROUP BY scenario_tag, user_id, local_date, platform）
    ▼
t1：用户级多窗口统计（计算各窗口内购买天数、最大 / 最小购买日期）
    ▼
t2：用户级平均复购间隔天数（(max_date - min_date) / (days_count - 1)；days_count ≤ 1 时为 null）
    ▼
最终聚合：按 platform × scenario_tag 计算 avg + percentile_approx(0.25/0.50/0.75/0.90)
    ▼
INSERT OVERWRITE：目标分区 (grass_region, local_date)
```

### 关键步骤

1. **Statement 1 — 创建临时视图 `dws_base_data_${grass_region_without_quote}`**
   - 从上游基准表筛选目标地区、近 180 天、汇总层（`feature_detail = '__ALL__'`）、有效订单（`order_cnt > 0`）的用户日记录；
   - 对 `platform` 做归一化处理：仅保留 `ios_app`、`android_app`，其余统一标记为 `others`。

2. **Statement 2 — INSERT OVERWRITE 写入目标表，包含三层嵌套子查询**
   - **t0**：按 `scenario_tag`、`user_id`、`local_date`（及 `platform` 等维度占位）分组去重，确保每用户每天只计一次购买；
   - **t1**：对每个用户在 30 / 60 / 90 / 180 天四个窗口内分别统计购买天数（`days_count_*`）、最大购买日期（`max_date_*`）、最小购买日期（`min_date_*`）；
   - **t2**：逐用户计算各窗口平均复购间隔：`(max_date - min_date) / (days_count - 1)`，购买天数 ≤ 1 时置为 `null`（无法计算间隔）；
   - **最终聚合**：按 `platform` × `scenario_tag` 分组，计算 `avg` 及 `percentile_approx`（0.25 / 0.50 / 0.75 / 0.90）共 20 个指标字段；
   - 写入目标表对应 `(grass_region, local_date)` 分区，全量覆盖。

### 注意事项

- **单写入文件**：本表仅有 1 个 ETL 文件，无多 writer 并发写入风险；
- **`${fields_placeholder}` 占位符**：ETL SQL 中存在模板变量，实际执行时 `platform` 维度通过该占位符注入，文档中已按 DataMap 字段列表确认其存在；
- **`feature_detail = '__ALL__'` 过滤**：上游基准表数据按 feature 分组存储，本表只取汇总层数据，若误去掉该过滤条件将导致数据重复计入；
- **`percentile_approx` 精度**：所有百分位数字段均为近似值，不保证精确，不适用于精确审计场景；
- **窗口起止边界**：30 天窗口为 `[local_date-29, local_date]`，60 天为 `[local_date-59, local_date]`，以此类推，均为闭区间；
- **INSERT OVERWRITE 全量覆盖**：每次运行将覆盖该 `(grass_region, local_date)` 分区的全量数据，重跑安全。

---

*文档生成时间：2026-05-17*