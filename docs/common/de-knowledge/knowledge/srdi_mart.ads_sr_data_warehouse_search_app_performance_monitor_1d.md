<!-- ads-workspace-gdoc-sync: gdoc_id=1Ym7rFnTB3YE2ou7TVgsUDX5b65AbCft3YI1RsKPOwSQ gdoc_url=https://docs.google.com/document/d/1Ym7rFnTB3YE2ou7TVgsUDX5b65AbCft3YI1RsKPOwSQ/edit -->

# srdi_mart.ads_sr_data_warehouse_search_app_performance_monitor_1d

**分层：** ADS（应用数据服务层）
**主键：** `grass_region` + `local_date` + `platform` + `layout_variant` + `app_version` + `dre_version` + `operation` + `stage` + `category_level` + `parent_stage` + `client_type`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日（T+1）全量覆写（`INSERT OVERWRITE`）
**引用频次/访问频次：** 776

---

## 业务描述

本表用于监控 Shopee 搜索 App 端（iOS / Android）基于 DRE（Dynamic Rendering Engine）渲染框架的端到端性能指标，覆盖首次加载（FSP）、翻页（Pagination）、筛选刷新（Filter）三类操作的全链路耗时分布、服务端开销、网络包大小、页面加载次数及缓存命中率等核心指标。

**核心业务场景：**
- 搜索 App 性能大盘日报监控，按大区/平台/App 版本/DRE 版本/布局变体多维度下钻分析性能分布。
- 识别特定版本上线后各阶段（stage）耗时分位数异常，辅助定位性能劣化根因。
- 评估缓存策略效果（首页缓存命中率）及网络传输开销变化趋势。
- 对比不同布局变体（`layout_variant`）的端到端性能差异，支撑 A/B 实验结论。

**适合回答的典型问题：**
- 某大区某 App 版本首页渲染 P90 耗时是多少？较上周有无劣化？
- DRE 引擎升级后，各渲染阶段（stage）耗时分布如何变化？
- 翻页操作的服务端响应 P95 耗时和响应包体大小分布情况如何？
- 首页缓存命中率在 iOS 与 Android 间是否存在差异？
- 某布局变体下，用户平均每次会话触发几次翻页/筛选加载？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 ID、MY、TH 等），用于分区隔离各市场数据 |
| `local_date` | date | 业务日期，数据所属自然日 |

---

### 维度：版本与平台标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，取值为 `ios_app` 或 `android_app` |
| `app_version` | string | App 版本号（格式 `x.y.z`）；汇总行取值为 `__ALL__` |
| `dre_version` | string | DRE（动态渲染引擎）版本号（格式 `x.y.z`）；汇总行取值为 `__ALL__`。仅纳入 >= 1.50.2 的版本 |
| `layout_variant` | string | 搜索结果页布局变体，用于 A/B 实验区分；汇总行取值为 `__ALL__` |

### 维度：操作与阶段标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `operation` | string | 操作类型：`action_first_page_performance`（首页加载）、`action_pagination_performance`（翻页）、`action_filter_performance`（筛选刷新）、`__ALL__`（跨操作汇总） |
| `stage` | string | 渲染阶段名称（如 `fsp`、`load_more`、`filter_refresh`、`js_runtime`、`others`、`server_cost` 等）；当行记录的是总耗时及网络/缓存指标时取值为 `__ALL__` |
| `category_level` | string | 阶段所属层级（来源于 DRE stages 结构，仅 stage 粒度行填充，dre_version >= 1.57.4 生效；其余行为 NULL） |
| `parent_stage` | string | 父级阶段名称（来源于 DRE stages 结构，仅 stage 粒度行填充，dre_version >= 1.57.4 生效；其余行为 NULL） |
| `client_type` | string | 阶段所属客户端执行类型（如 `js`、`server` 等；仅 stage 粒度行填充，dre_version >= 1.67.0 引入细分；汇总行为 NULL） |

---

### 指标：各阶段耗时分位数（ms）

| 字段 | 类型 | 说明 |
|---|---|---|
| `duration_p80` | double | 指定 stage 耗时 P80（毫秒）；仅在 `stage != '__ALL__'` 的行有值，其余行为 NULL |
| `duration_p90` | double | 指定 stage 耗时 P90（毫秒）；同上 |
| `duration_p95` | double | 指定 stage 耗时 P95（毫秒）；同上 |
| `duration_p99` | double | 指定 stage 耗时 P99（毫秒）；同上 |

### 指标：端到端总耗时分位数（ms）

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_duration_p80` | double | 端到端总耗时 P80（毫秒）；仅在 `stage = '__ALL__'` 的行有值，其余行为 NULL |
| `total_duration_p90` | double | 端到端总耗时 P90（毫秒）；同上 |
| `total_duration_p95` | double | 端到端总耗时 P95（毫秒）；同上 |
| `total_duration_p99` | double | 端到端总耗时 P99（毫秒）；同上 |

### 指标：服务端处理耗时分位数（ms）

| 字段 | 类型 | 说明 |
|---|---|---|
| `server_cost_p80` | double | 服务端处理耗时 P80（毫秒）；仅在 `stage = '__ALL__'` 的行有值，其余行为 NULL |
| `server_cost_p90` | double | 服务端处理耗时 P90（毫秒）；同上 |
| `server_cost_p95` | double | 服务端处理耗时 P95（毫秒）；同上 |
| `server_cost_p99` | double | 服务端处理耗时 P99（毫秒）；同上 |

### 指标：请求包大小分位数（bytes）

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_pack_size_p80` | bigint | 请求包大小 P80（字节）；仅在 `stage = '__ALL__'` 的行有值，其余行为 NULL |
| `request_pack_size_p90` | bigint | 请求包大小 P90（字节）；同上 |
| `request_pack_size_p95` | bigint | 请求包大小 P95（字节）；同上 |
| `request_pack_size_p99` | bigint | 请求包大小 P99（字节）；同上 |

### 指标：响应包大小分位数（bytes）

| 字段 | 类型 | 说明 |
|---|---|---|
| `response_pack_size_p80` | bigint | 响应包大小 P80（字节）；仅在 `stage = '__ALL__'` 的行有值，其余行为 NULL |
| `response_pack_size_p90` | bigint | 响应包大小 P90（字节）；同上 |
| `response_pack_size_p95` | bigint | 响应包大小 P95（字节）；同上 |
| `response_pack_size_p99` | bigint | 响应包大小 P99（字节）；同上 |

### 指标：页面加载次数

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_load_times` | double | 每个 search_session 平均加载次数（各操作类型的均值）；仅在 `stage = '__ALL__'` 的行有值，其余行为 NULL |
| `p50_load_times` | bigint | 每个 search_session 加载次数 P50；同上 |
| `p80_load_times` | bigint | 每个 search_session 加载次数 P80；同上 |
| `p90_load_times` | bigint | 每个 search_session 加载次数 P90；同上 |
| `p95_load_times` | bigint | 每个 search_session 加载次数 P95；同上 |
| `p99_load_times` | bigint | 每个 search_session 加载次数 P99；同上 |

### 指标：缓存命中率

| 字段 | 类型 | 说明 |
|---|---|---|
| `cache_success_rate` | double | 首页加载（`action_first_page_performance`）的缓存命中率（`is_cache='true'` 占比，值域 [0,1]）；非首页操作或 `stage != '__ALL__'` 行为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段必须同时指定**：每次查询必须在 `WHERE` 子句中同时过滤 `grass_region` 和 `local_date`，避免全表扫描。
   ```sql
   WHERE grass_region = 'ID'
     AND local_date = '2024-01-01'
   ```
2. **`stage` 字段区分行类型**：本表采用"宽表混合存储"模式，两类逻辑不同的行共存于同一分区：
   - `stage = '__ALL__'`：包含 `total_duration_*`、`server_cost_*`、`*_pack_size_*`、`*_load_times`、`cache_success_rate`；`duration_*` 为 NULL。
   - `stage != '__ALL__'`：包含 `duration_*`；其余指标字段均为 NULL。
   - **查询时务必按 `stage` 过滤以匹配目标指标**，否则 NULL 值会混入聚合结果。
3. **`operation` 字段含汇总行**：`operation = '__ALL__'` 表示跨操作类型汇总，对应 `total_duration`、`server_cost`、包大小等指标按 session 维度加总后计算分位数，与各单操作行不同源，请勿混合使用。
4. **维度汇总行识别**：`layout_variant`、`app_version`、`dre_version` 取值为 `__ALL__` 的行为 CUBE 聚合汇总行，勿与明细维度行混用。

### 不可直接 SUM 的字段

以下字段均为**预计算分位数或比率**，跨行直接 `SUM` / `AVG` 在数学上无意义，严禁使用：

| 字段 | 原因 |
|---|---|
| `duration_p80/p90/p95/p99` | 基于 `APPROX_PERCENTILE` 预聚合，不可再次 SUM |
| `total_duration_p80/p90/p95/p99` | 同上 |
| `server_cost_p80/p90/p95/p99` | 同上 |
| `request_pack_size_p80/p90/p95/p99` | 同上 |
| `response_pack_size_p80/p90/p95/p99` | 同上 |
| `avg_load_times` | 均值，跨维度不可直接 SUM |
| `p50/p80/p90/p95/p99_load_times` | 分位数，不可再次 SUM |
| `cache_success_rate` | 比率，不可跨行 SUM，需回源计算 |

### 时效性说明

- 本表为 **1d（每日）** 粒度表，`local_date` 对应业务自然日，通常 T+1 产出。
- 数据仅覆盖 **App 版本 >= 3.27.0** 且 **DRE 版本 >= 1.50.2** 的用户行为。
- `category_level`、`parent_stage` 字段仅在 DRE 版本 >= 1.57.4 时存在有效数据。
- `client_type` 字段的细分值（如 `js`）仅在 DRE 版本 >= 1.67.0 时存在。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索会话明细宽表，提供平台、版本、操作类型、各阶段耗时数组（`stages_duration`）、总耗时、服务端耗时、包大小、缓存标识等原始字段，是本表唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search
        │
        ▼
[dwd_raw_data]  基础过滤（page_type、platform_implementation、操作类型、版本格式校验）
        │
        ▼
[dwd_raw_data_version_filtered]  版本下限过滤（app_version >= 3.27.0，dre_version >= 1.50.2）
        │
        ├──► [dwd_raw_data_explode_stages]  展开 stages 数组（LATERAL VIEW EXPLODE）
        │           │
        │           ├──► [dws_stage_duration_metrics]  各 stage 耗时分位数（dre >= 1.57.4）
        │           │
        │           └──► [dwd_runtime_metrics]  js_runtime / others 衍生 stage（按版本分支）
        │                       │
        │                       └──► [dws_runtime_metrics]  衍生 stage 耗时分位数
        │
        │   [dws_all_stage_duration_merge]  合并 stage + runtime 分位数结果
        │
        ├──► [dws_total_duration_and_be_statistics_individual_op]  各操作维度总耗时/包大小分位数
        ├──► [dwd_total_duration_and_be_statistics_for_all_op]  operation=__ALL__ session 级加总
        │           └──► [dws_total_duration_and_be_statistics_all_op]  跨操作分位数
        │   [dws_total_duration_and_be_statistics_merge]  合并各操作 + __ALL__ 总耗时指标
        │
        ├──► [dwd_load_times] → [load_times_flatten] → [dwm_load_times] → [dws_load_times]  加载次数指标
        │
        └──► [dws_cache_success_rate]  缓存命中率
        │
        ▼
INSERT OVERWRITE
ads_sr_data_warehouse_search_app_performance_monitor_1d
（UNION ALL 合并 stage 粒度行 + 总指标行）
```

### 关键步骤

| 步骤序号 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `dwd_raw_data` | 从 DWD 表按 `grass_region`、`local_date` 过滤；限定页面类型（`global_search`、`search_prefill`、`search_in_pdp`）、平台为 `ios_app`/`android_app`、`platform_implementation = 'dre'`、登录用户（`user_id > 0`）、click 操作、版本格式合法；将 `stages_duration` JSON 数组解析为 struct 数组 |
| 2 | `dwd_raw_data_version_filtered` | 在步骤 1 基础上进一步过滤：`app_version >= 3.27.0` 且 `dre_version >= 1.50.2` |
| 3 | `dwd_raw_data_explode_stages` | 对 stages struct 数组执行 `LATERAL VIEW EXPLODE`，展开为每行一条 stage 明细，过滤 `duration IS NULL` 的行 |
| 4 | `dws_stage_duration_metrics` | 对 stage 明细（dre_version >= 1.57.4）按 `platform`、`CUBE(layout_variant, app_version, dre_version)`、`operation`、`stage`、`category_level`、`parent_stage` 分组，计算 `APPROX_PERCENTILE(duration, [0.8,0.9,0.95,0.99])` |
| 5 | `dwd_runtime_metrics` | 按版本分支（dre 1.57.4–1.67.0 和 dre >= 1.67.0）计算 `js_runtime`（JS 执行时间）和 `others`（其余时间）两个衍生 stage 的 session 级 duration，通过 UNION ALL 合并四个子查询 |
| 6 | `dws_runtime_metrics` | 对衍生 stage 明细按完整维度分组 + GROUPING SETS 汇总，计算分位数 |
| 7 | `dws_all_stage_duration_merge` | UNION ALL 合并步骤 4（`stage_duration_metrics`）和步骤 6（`runtime_metrics`）的结果，输出统一的 stage 粒度分位数宽行 |
| 8 | `dws_total_duration_and_be_statistics_individual_op` | 对版本过滤后原始数据，按 `platform`、`CUBE(layout_variant, app_version, dre_version)`、`operation` 分组，计算 `total_duration`、`server_cost`、`request_pack_size`、`response_pack_size` 的分位数 |
| 9 | `dwd_total_duration_and_be_statistics_for_all_op` | 为 `operation = '__ALL__'` 场景，先在 session 粒度对不同操作的 `total_duration` 求和（翻页操作特殊处理：取 `load_more_item_exposure` stage 累加值），再求 `server_cost`、包大小之和 |
| 10 | `dws_total_duration_and_be_statistics_all_op` | 对步骤 9 结果再次按 `platform`、`layout_variant`、`app_version`、`dre_version` 分组，计算分位数 |
| 11 | `dws_total_duration_and_be_statistics_merge` | UNION ALL 合并步骤 8（各操作）和步骤 10（`__ALL__`）的总耗时/包大小分位数 |
| 12 | `dwd_load_times` → `load_times_flatten` → `dwm_load_times` | 计算每个 session 的各操作加载次数；通过 `load_times_flatten` 把三类操作拍平到同维度行，通过 EXPLODE 恢复 operation 维度，过滤无真实数据的幻影行 |
| 13 | `dws_load_times` | 对 session 级加载次数计算 `AVG` 和 `APPROX_PERCENTILE([0.5,0.8,0.9,0.95,0.99])` |
| 14 | `dws_cache_success_rate` | 仅针对 `action_first_page_performance` 操作，按维度 CUBE 计算 `is_cache='true'` 占比 |
| 15 | **INSERT OVERWRITE（最终写入）** | 以 UNION ALL 写入两类行：① stage 粒度行（来自步骤 7），`duration_*` 有值，其余指标为 NULL；② 总指标行（步骤 11 LEFT JOIN 步骤 13、14），`stage='__ALL__'`，`duration_*` 为 NULL；使用 `REPARTITION(500)` 控制输出文件数 |

### 注意事项

- **单 Writer，无多写风险**：本表仅有 1 个 ETL 文件，无 multi-writer 并发写入风险。
- **行类型混存，NULL 字段须注意**：`stage = '__ALL__'` 行与 `stage != '__ALL__'` 行的有效指标列完全不同，查询前必须按 `stage` 过滤，否则 SUM/AVG 会将 NULL 与非 NULL 行混合。
- **分位数使用 `APPROX_PERCENTILE`**：所有分位数均为近似值（基于 Spark 内置算法），存在约 1% 以内的相对误差，不可与精确排序结果直接比较。
- **版本过滤分支复杂**：`dwd_runtime_metrics` 和 `dws_stage_duration_metrics` 均有 DRE 版本范围限制（1.57.4–1.67.0 vs >= 1.67.0），低于 1.57.4 的 DRE 版本不会产生 `category_level`、`parent_stage`、`client_type` 等字段的有效数据。
- **`operation = '__ALL__'` 的 `total_duration` 计算口径特殊**：翻页操作使用 `load_more_item_exposure` stage 的累加值，而非原始 `total_duration`，与单操作的计算口径不一致，跨操作对比时需知悉。
- **`cache_success_rate` 仅对首页操作有意义**：ETL 中通过 LEFT JOIN 条件 `a.operation = 'action_first_page_performance'` 限制，翻页和筛选操作对应行的 `cache_success_rate` 为 NULL。

---

*文档生成时间：2026-05-17*