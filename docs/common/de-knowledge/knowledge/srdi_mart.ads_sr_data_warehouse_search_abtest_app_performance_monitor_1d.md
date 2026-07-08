<!-- ads-workspace-gdoc-sync: gdoc_id=1gPx5oh6fIfbaAWdvfYVxGnfzvGZ991jloSqUhljSoKc gdoc_url=https://docs.google.com/document/d/1gPx5oh6fIfbaAWdvfYVxGnfzvGZ991jloSqUhljSoKc/edit -->

# srdi_mart.ads_sr_data_warehouse_search_abtest_app_performance_monitor_1d

**分层：** ADS（应用数据服务层）
**主键：** `grass_region` + `local_date` + `experiment_id` + `exp_group_id` + `platform` + `layout_variant` + `app_version` + `dre_version` + `operation` + `stage` + `category_level` + `parent_stage` + `client_type`
**分区：** `grass_region`（站点大区）, `local_date`（日期）
**更新频率：** 每日 T+1 全量覆写（`INSERT OVERWRITE`）
**引用频次 / 访问频次：** 714

---

## 业务描述

本表用于搜索 A/B 实验（ABTest）维度下的 App 端搜索性能监控，按天聚合，覆盖各实验组的页面加载时延、阶段耗时分布、服务端耗时、网络包大小及缓存命中率等核心性能指标。

**核心业务场景：**
- 搜索 A/B 实验效果评估：对比不同实验组（`experiment_id` / `exp_group_id`）在 App 搜索场景下的性能差异。
- 多维度性能下钻：支持按平台（iOS/Android）、布局变体、App 版本、DRE 渲染引擎版本、操作类型（首页加载 / 翻页 / 筛选）、渲染阶段（stage）等多个维度分析性能。
- 端到端链路耗时拆解：将总耗时拆解为各渲染 stage 耗时、JS 运行时耗时、服务端耗时及"其他"耗时，支持定位性能瓶颈。
- 请求/响应包大小分析：监控网络传输包体大小的分布变化。
- 缓存命中率追踪：监控首页加载的缓存成功率。

**适合回答的典型问题：**
- 实验组 X vs 对照组在首页加载 P90 耗时上有多大差异？
- Android 端在特定 DRE 版本下翻页的 server_cost P99 是多少？
- 各实验组的缓存命中率趋势如何变化？
- 某布局变体下请求包大小的 P80/P95 分布是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区，如 `SG`、`MY`、`TH` 等，作为一级分区 |
| `local_date` | date | 数据日期，格式 `yyyy-MM-dd`，作为二级分区 |

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID，来源于 `dim_sr_data_warehouse_abtest_user_group` |
| `exp_group_id` | bigint | 实验分组 ID，标识对照组或实验组 |

### 维度：设备与版本

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，取值为 `ios_app` 或 `android_app` |
| `app_version` | string | App 版本号（格式 `major.minor.patch`），`__ALL__` 表示全版本聚合 |
| `dre_version` | string | DRE 渲染引擎版本号（格式 `major.minor.patch`），`__ALL__` 表示全版本聚合 |
| `layout_variant` | string | 搜索结果布局变体，`__ALL__` 表示全变体聚合 |

### 维度：操作与渲染阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `operation` | string | 性能操作类型：`action_first_page_performance`（首页加载）、`action_pagination_performance`（翻页）、`action_filter_performance`（筛选刷新）、`__ALL__`（全操作聚合） |
| `stage` | string | 渲染阶段名称，如 `fsp`、`load_more`、`filter_refresh`、`js_runtime`、`others`，`__ALL__` 表示该行为操作级别汇总行（非 stage 明细行） |
| `category_level` | string | 阶段分类层级，来源于 `stages_duration` 的 JSON 结构，仅在 stage 明细行有值；汇总行为 `NULL` |
| `parent_stage` | string | 父级渲染阶段名称，仅在 stage 明细行有值；汇总行为 `NULL` |
| `client_type` | string | 客户端类型（如 `js`、`server`），用于区分 `js_runtime` 细分；部分场景为 `NULL` 或空字符串 |

### 指标：实验组用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `group_uu` | bigint | 实验组独立用户数（UV），来源于 ABTest 分配日志 |
| `search_uu` | bigint | 实验组中有搜索行为的独立用户数（搜索 UV） |
| `search_volume` | bigint | 实验组内搜索去重 PV（按 user_id + device_id + keyword 去重后的搜索次数） |

### 指标：各渲染阶段耗时分位数（毫秒）

| 字段 | 类型 | 说明 |
|---|---|---|
| `duration_p80` | double | 指定 stage 耗时 P80（毫秒），仅 stage 明细行有值，汇总行为 `NULL` |
| `duration_p90` | double | 指定 stage 耗时 P90（毫秒），仅 stage 明细行有值，汇总行为 `NULL` |
| `duration_p95` | double | 指定 stage 耗时 P95（毫秒），仅 stage 明细行有值，汇总行为 `NULL` |
| `duration_p99` | double | 指定 stage 耗时 P99（毫秒），仅 stage 明细行有值，汇总行为 `NULL` |

### 指标：端到端总耗时分位数（毫秒）

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_duration_p80` | double | 搜索请求端到端总耗时 P80（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |
| `total_duration_p90` | double | 搜索请求端到端总耗时 P90（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |
| `total_duration_p95` | double | 搜索请求端到端总耗时 P95（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |
| `total_duration_p99` | double | 搜索请求端到端总耗时 P99（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |

### 指标：服务端耗时分位数（毫秒）

| 字段 | 类型 | 说明 |
|---|---|---|
| `server_cost_p80` | double | 服务端处理耗时 P80（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |
| `server_cost_p90` | double | 服务端处理耗时 P90（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |
| `server_cost_p95` | double | 服务端处理耗时 P95（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |
| `server_cost_p99` | double | 服务端处理耗时 P99（毫秒），仅 `stage = '__ALL__'` 的汇总行有值 |

### 指标：请求包大小分位数（字节）

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_pack_size_p80` | bigint | 请求包大小 P80（字节），仅 `stage = '__ALL__'` 的汇总行有值 |
| `request_pack_size_p90` | bigint | 请求包大小 P90（字节），仅 `stage = '__ALL__'` 的汇总行有值 |
| `request_pack_size_p95` | bigint | 请求包大小 P95（字节），仅 `stage = '__ALL__'` 的汇总行有值 |
| `request_pack_size_p99` | bigint | 请求包大小 P99（字节），仅 `stage = '__ALL__'` 的汇总行有值 |

### 指标：响应包大小分位数（字节）

| 字段 | 类型 | 说明 |
|---|---|---|
| `response_pack_size_p80` | bigint | 响应包大小 P80（字节），仅 `stage = '__ALL__'` 的汇总行有值 |
| `response_pack_size_p90` | bigint | 响应包大小 P90（字节），仅 `stage = '__ALL__'` 的汇总行有值 |
| `response_pack_size_p95` | bigint | 响应包大小 P95（字节），仅 `stage = '__ALL__'` 的汇总行有值 |
| `response_pack_size_p99` | bigint | 响应包大小 P99（字节），仅 `stage = '__ALL__'` 的汇总行有值 |

### 指标：加载次数

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_load_times` | double | 每次 search session 内指定 operation 的平均加载次数，仅 `stage = '__ALL__'` 的汇总行有值 |
| `p50_load_times` | bigint | 每次 search session 加载次数的 P50 分位数，仅 `stage = '__ALL__'` 的汇总行有值 |
| `p80_load_times` | bigint | 每次 search session 加载次数的 P80 分位数，仅 `stage = '__ALL__'` 的汇总行有值 |
| `p90_load_times` | bigint | 每次 search session 加载次数的 P90 分位数，仅 `stage = '__ALL__'` 的汇总行有值 |
| `p95_load_times` | bigint | 每次 search session 加载次数的 P95 分位数，仅 `stage = '__ALL__'` 的汇总行有值 |
| `p99_load_times` | bigint | 每次 search session 加载次数的 P99 分位数，仅 `stage = '__ALL__'` 的汇总行有值 |

### 指标：缓存命中率

| 字段 | 类型 | 说明 |
|---|---|---|
| `cache_success_rate` | double | 首页加载（`action_first_page_performance`）的缓存命中率，取值 [0, 1]，仅 `stage = '__ALL__'` 且 `operation = 'action_first_page_performance'` 的汇总行有值 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须指定**，否则触发全表扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 多日期范围查询时，推荐使用 `local_date BETWEEN '2024-01-01' AND '2024-01-07'`，避免跨分区扫描过多数据。

### 行类型说明（重要）

本表采用 **稀疏宽表** 设计，同一分区内存在两类行，指标字段互斥填充，查询时必须区分：

| 行类型 | `stage` 值 | 有值的指标 | 为 NULL 的指标 |
|---|---|---|---|
| **Stage 明细行** | 具体 stage 名称（如 `fsp`、`js_runtime`、`others` 等） | `duration_p80/90/95/99` | `total_duration_*`、`server_cost_*`、`request_pack_size_*`、`response_pack_size_*`、`avg_load_times`、`p*_load_times`、`cache_success_rate` |
| **操作汇总行** | `'__ALL__'` | `total_duration_*`、`server_cost_*`、`request_pack_size_*`、`response_pack_size_*`、`avg_load_times`、`p*_load_times`、`cache_success_rate` | `duration_p80/90/95/99`、`category_level`、`parent_stage`、`client_type` |

### 不可直接 SUM 的字段

以下字段为预计算的分位数、均值或比率，**不可跨行直接累加**，多日期汇总须回溯原始明细重新计算：

- 所有 `*_p80`、`*_p90`、`*_p95`、`*_p99` 字段（分位数）
- `avg_load_times`（均值）
- `cache_success_rate`（比率）
- `group_uu`、`search_uu`（去重用户数，不可跨实验组或跨日期 SUM）
- `search_volume`（已去重的 PV，不可跨日期 SUM）

### 维度取值约定

- `layout_variant`、`app_version`、`dre_version` 为 `'__ALL__'` 时，表示对应维度的全量聚合值。
- `category_level`、`parent_stage`、`client_type` 在汇总行（`stage = '__ALL__'`）中均为 `NULL`。
- `cache_success_rate` 仅对 `operation = 'action_first_page_performance'` 有业务含义，其他 operation 的汇总行该字段为 `NULL`。

### 版本过滤说明

ETL 已过滤只保留 `app_version >= 3.27.0` 且 `dre_version >= 1.50.2` 的数据；`category_level` / `parent_stage` 相关 stage 指标仅在 `dre_version >= 1.57.4` 时才有完整数据；`client_type` 区分的 `js_runtime` 口径在 `dre_version >= 1.67.0` 后有变化，跨版本对比需注意口径一致性。

### 时效性说明

- 本表为 **日粒度** 表（后缀 `_1d`），每日 T+1 跑批产出，数据反映前一自然日的完整情况。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取 ABTest 实验用户分组映射（`user_id` → `experiment_id` + `exp_group_id`），过滤有效分配日志及搜索白名单用户 |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细宽表，提供用户搜索 PV、各渲染阶段耗时（`stages_duration`）、总耗时、服务端耗时、请求/响应包大小、缓存标记等原始事件数据 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
                                            ├──► 用户实验映射 (user_exp_mapping)
dwd_sr_data_warehouse_search ──────────────┤
    │                                       ├──► 实验组 UU / 搜索 UU / 搜索量
    │                                       │
    ├──► 版本过滤后明细 ──────────────────────┤
    │    (app_version >= 3.27.0             │
    │     dre_version >= 1.50.2)            │
    │         │                             │
    │         ├──► Stage 耗时 EXPLODE        │
    │         │    → 分位数聚合              ├──► INSERT OVERWRITE
    │         │                             │    目标表（两路 UNION ALL）
    │         ├──► 派生 stage 计算           │
    │         │    (js_runtime / others)    │
    │         │                             │
    │         ├──► total_duration /         │
    │         │    server_cost /            │
    │         │    pack_size 分位数         │
    │         │                             │
    │         └──► load_times /             │
    │              cache_success_rate  ─────┘
```

### 关键步骤

1. **用户实验映射（`user_exp_mapping`）**：从 `dim_sr_data_warehouse_abtest_user_group` 中提取当日、当 region、已分配且在搜索白名单内的用户实验分组关系，并缓存。同步计算各实验组 UU（`exp_group_uu`）、搜索 UU（`search_uu`）、搜索量（`search_volume`）并缓存。

2. **原始数据过滤与版本筛选（`dwd_raw_data_version_filtered`）**：从 `dwd_sr_data_warehouse_search` 中筛选 DRE 实现、App 端、指定 page_type、有效 operation 的数据，并二次过滤 `app_version >= 3.27.0` 且 `dre_version >= 1.50.2` 的记录。

3. **Stage 耗时 EXPLODE 与分位数计算（`dws_stage_duration_metrics`）**：对 `stages_duration` JSON 数组进行 LATERAL VIEW EXPLODE 展开，按用户分组累计频次，关联实验映射后，使用加权 `PERCENTILE` 计算各维度组合下 `duration` 的 P80/P90/P95/P99。仅保留 `dre_version >= 1.57.4` 的行用于 `category_level` / `parent_stage` 维度。

4. **派生 Stage 指标计算（`dws_runtime_metrics`）**：计算 `others`（非 JS/Server 耗时）和 `js_runtime`（JS 运行时耗时）两个合成 stage，针对 `dre_version` 不同范围（`[1.57.4, 1.67.0)` 与 `>= 1.67.0`）分别使用不同的计算口径，最终合并后聚合分位数。

5. **总耗时与包大小分位数计算（`dws_total_duration_and_be_statistics_merge`）**：
   - `total_duration` 和 `response_pack_size` 通过 `APPROX_PERCENTILE` 计算；
   - `server_cost` 和 `request_pack_size` 通过加权 `PERCENTILE`（先聚合频次再计算分位数）计算；
   - 支持按 `CUBE(layout_variant, app_version, dre_version)` 多维展开；
   - 三路结果通过 `FULL JOIN` 合并。

6. **加载次数指标计算（`dws_load_times`）**：按 `search_session_id` 和操作类型统计 session 内的加载次数，展平后关联实验映射，计算 `avg_load_times` 及 P50/P80/P90/P95/P99。

7. **缓存命中率计算（`dws_cache_success_rate`）**：仅针对 `action_first_page_performance` 操作，计算命中缓存（`is_cache = 'true'`）的比例，支持 CUBE 多维聚合。

8. **最终写入（`INSERT OVERWRITE`）**：两路 UNION ALL 写入目标表：
   - **第一路**：Stage 明细行，填充 `duration_p*` 指标，其余指标置 `NULL`，`stage` 值为具体阶段名。
   - **第二路**：操作汇总行，填充 `total_duration_*`、`server_cost_*`、`pack_size_*`、`load_times_*`、`cache_success_rate` 等指标，`stage` 固定为 `'__ALL__'`，`duration_p*` 置 `NULL`。

### 注意事项

- **单 Writer**：该表仅由 1 个 ETL 文件写入，无 multi-writer 并发冲突风险。
- **分区覆写**：每次执行按 `grass_region` + `local_date` 的组合分区做 `INSERT OVERWRITE`，幂等安全，重跑不会产生重复数据。
- **稀疏宽表结构**：两路 UNION ALL 导致同一分区内存在大量 `NULL` 值，下游使用时必须按 `stage` 字段区分行类型，避免误用 `NULL` 值参与计算。
- **版本依赖口径**：`category_level`/`parent_stage` 仅在 `dre_version >= 1.57.4` 后存在；`js_runtime` 的计算口径在 `dre_version = 1.67.0` 前后有本质差异，跨时间段横向对比时需特别注意。
- **APPROX_PERCENTILE vs PERCENTILE**：`total_duration` 和 `response_pack_size` 使用了近似分位数算法（精度参数 2000），与 `duration`、`server_cost`、`request_pack_size` 使用加权精确 `PERCENTILE` 的口径不同，存在微小误差。

---

*文档生成时间：2026-05-17*