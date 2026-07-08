<!-- ads-workspace-gdoc-sync: gdoc_id=1fx_8P81rHGMbYtiqImYA2DsN1NzTIfa73EKitqOpXNY gdoc_url=https://docs.google.com/document/d/1fx_8P81rHGMbYtiqImYA2DsN1NzTIfa73EKitqOpXNY/edit -->

# srdi_mart.dws_sr_data_warehouse_search_rel_score_metrics_1d

**分层：** dws_search
**主键：** `sort_type`, `card_type`, `is_ads`, `top_location_type`, `grass_region`, `local_date`
**分区：** `grass_region`（大区）/ `local_date`（业务日期）
**更新频率：** 每日一次（T+1 全量覆写对应分区）
**引用频次 / 访问频次：** 303

---

## 业务描述

本表汇聚搜索结果页曝光的**相关性评分指标**，以日粒度统计不同维度组合下的搜索相关性表现，是搜索相关性质量监控与分析的核心 DWS 汇总表。

**核心业务场景：**

- 监控搜索结果的整体及分维度相关性得分（原始分 / 校正分）变化趋势；
- 识别低相关性 Query（bad query）占比及 bad case 曝光率，辅助模型效果评估；
- 区分广告（`is_ads`）与自然结果、不同排序策略（`sort_type`）、不同卡片类型（`card_type`）下的相关性差异；
- 支持 Top 20 / Top 40 位置范围内相关性指标的分层对比分析。

**适合回答的问题：**

- 某大区某天，自然搜索结果 Top 20 位置的平均相关性原始分是多少？
- 广告结果与自然结果的相关性分布差异如何？
- 哪些 `card_type` 或 `sort_type` 组合下 bad query 率最高？
- `somewhat_rate`（模糊相关率）和 `irrelevant_rate`（无关率）随时间如何变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/国家标识，与上游表 `country` 字段对应，作为分区键 |
| `local_date` | date | 业务日期，对应上游数据的 `dt` 字段，作为分区键 |

### 维度：搜索场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `sort_type` | string | 排序类型；维度聚合时未参与分组的场景填充为 `__ALL__`，原始值为空时填充为 `null` |
| `card_type` | string | 卡片类型；维度聚合时未参与分组的场景填充为 `__ALL__`，原始值为空时填充为 `null` |
| `is_ads` | string | 是否广告，取值为字符串 `'true'`/`'false'`；维度聚合时未参与分组的场景填充为 `__ALL__`，原始值为空时填充为 `false` |
| `top_location_type` | int | 位置范围类型：`20` 表示统计 Top 20 曝光坑位，`40` 表示统计 Top 40 曝光坑位 |

### 指标：item 级别相关性均值

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_avg_rel_raw` | double | 坑位级别相关性原始分均值，计算方式：`SUM(rel_raw) / SUM(item_imp_cnt)`，即所有曝光坑位的原始相关性分之和除以曝光坑位总数 |
| `item_avg_rel_add` | double | 坑位级别相关性校正分（additive）均值，计算方式：`SUM(rel_add) / SUM(item_imp_cnt)`，即所有曝光坑位的校正相关性分之和除以曝光坑位总数 |

### 指标：request 级别相关性均值

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_avg_rel_raw` | double | Query 级别相关性原始分均值，计算方式：对每个 request 先计算其 `rel_raw / item_imp_cnt`，再跨 request 取平均（`AVG`），反映典型 Query 的相关性原始分水平 |
| `request_avg_rel_add` | double | Query 级别相关性校正分均值，计算方式：对每个 request 先计算其 `rel_add / item_imp_cnt`，再跨 request 取平均（`AVG`），反映典型 Query 的相关性校正分水平 |

### 指标：相关性质量率

| 字段 | 类型 | 说明 |
|---|---|---|
| `bad_query_rate` | double | Bad Query 率：bad_case 分值占比超过 20%（`bad_case / item_imp_cnt > 0.2`）的 request 数量 / 总 request 数量；其中 bad_case 权重：完全无关（`rel_lx=0, rel_raw>0`）权重 4，模糊相关（`rel_lx=1`）权重 0.5 |
| `bad_case_rate` | double | Bad Case 率：`SUM(bad_case) / SUM(item_imp_cnt)`，即加权 bad case 曝光量占总曝光坑位的比例 |
| `irrelevant_rate` | double | 完全无关率：`rel_lx=0` 且 `rel_raw>0` 的曝光坑位数 / 总曝光坑位数 |
| `somewhat_rate` | double | 模糊相关率：`rel_lx=1` 的曝光坑位数 / 总曝光坑位数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定分区字段**，查询时务必携带 `grass_region` 和 `local_date` 条件，避免全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-01'
  ```
- 如需限定位置范围，须同时过滤 `top_location_type`（`20` 或 `40`），避免重复计算：
  ```sql
  AND top_location_type = 20
  ```

### 不可直接 SUM 的字段

以下字段均为**预聚合比率或均值**，跨维度合并时不能直接 `SUM`，否则结果无意义：

| 字段 | 原因 |
|---|---|
| `item_avg_rel_raw` | 加权均值，需用原始 `SUM(rel_raw)/SUM(item_imp_cnt)` 重算 |
| `item_avg_rel_add` | 同上，加权均值 |
| `request_avg_rel_raw` | AVG of per-request 均值，不可跨组简单相加 |
| `request_avg_rel_add` | 同上 |
| `bad_query_rate` | 比率，分子分母不可拆分 |
| `bad_case_rate` | 比率，分子分母不可拆分 |
| `irrelevant_rate` | 比率，分子分母不可拆分 |
| `somewhat_rate` | 比率，分子分母不可拆分 |

### 维度组合说明

- 本表通过 `GROUPING SETS` 预聚合了多种维度组合，`__ALL__` 表示该维度未参与当次分组（即全量汇总），查询时需注意避免维度交叉导致重复统计。
- 若需查询单一维度汇总数据（如所有 `sort_type` 的整体），应筛选其他维度为 `__ALL__`，例如：
  ```sql
  WHERE card_type = '__ALL__' AND is_ads = '__ALL__'
  ```

### 时效性说明

- 本表为 **T+1 日粒度**表，每日调度写入前一天数据；最新分区数据通常在次日产出。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_fp_search_base_1d` | 搜索曝光明细基础表，提供坑位级别的相关性原始分（`rel_raw`）、校正分（`rel_add`）、相关性标签（`rel_lx`）、位置（`location`）、请求ID（`request_id`）等字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_fp_search_base_1d
        │  过滤当天/当区、location < 40、非空 rel 字段
        ▼
fp_search_base_raw（临时视图）
        │  按 GROUPING SETS 多维聚合，分别统计 Top20 / Top40 位置范围，UNION ALL 合并
        ▼
request_grouped（临时视图，request 级别中间结果）
        │  在 request 粒度上二次聚合，计算各比率指标
        ▼
srdi_mart.dws_sr_data_warehouse_search_rel_score_metrics_1d
```

### 关键步骤

**Step 1 — 构建基础明细视图 `fp_search_base_raw`**

从 `dwd_fp_search_base_1d` 中过滤当日（`dt = ${local_date}`）、当大区（`country = ${grass_region}`）、`location < 40`、且 `rel_raw != 0` / `rel_lx` / `imp_time` 均非空的有效曝光记录，同时对 `sort_type`、`card_type`、`is_ads` 三个维度字段做空值保护（`COALESCE`）。

**Step 2 — 构建 request 级聚合视图 `request_grouped`**

以 GROUPING SETS 方式生成 8 种维度组合（包含全量汇总 `(request_id)` 和各维度子集）的 request 级中间聚合结果，分两段分别统计：
- **Top 20**（`location < 20`）：`top_location_type = 20`
- **Top 40**（`location < 40`）：`top_location_type = 40`

两段通过 `UNION ALL` 合并，每行记录 request 的曝光坑位数（`item_imp_cnt`）、相关性分求和、无关/模糊相关计数及 bad_case 加权分。

**Step 3 — 最终聚合写入目标表**

对 `request_grouped` 按 `sort_type, card_type, is_ads, top_location_type` 四维分组，计算：
- `item_avg_rel_raw/add`：全局曝光坑位加权均值
- `request_avg_rel_raw/add`：per-request 均值的跨 request 平均（`AVG`）
- `bad_query_rate`：利用 `COUNT(DISTINCT CASE WHEN ... THEN request_id END)` 统计超阈值 query 占比
- `bad_case_rate`、`irrelevant_rate`、`somewhat_rate`：各类坑位占比

最终以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 覆写写入目标表分区。

### 注意事项

- **单 writer**：本表仅由单个 ETL 文件写入，无 multi-writer 竞争风险。
- **分区覆写**：采用 `INSERT OVERWRITE PARTITION` 模式，每次调度仅覆写当日当区分区，重跑安全。
- **GROUPING SETS 展开**：`request_grouped` 中，未参与当前 GROUPING SETS 分组的维度列值为 `NULL`，最终 Step 3 聚合后输出的 `sort_type` / `card_type` / `is_ads` 将以 `__ALL__` 表示全量汇总维度，查询时需注意区分。
- **位置范围双写**：Top 20 与 Top 40 数据通过 UNION ALL 合并后统一写入，`top_location_type` 字段是区分两组数据的唯一标识，若未过滤该字段将导致指标双倍计算。
- **rel_raw 过滤**：上游过滤了 `rel_raw = 0` 的记录，bad_case 统计中的"无关"定义为 `rel_lx=0 AND rel_raw>0`，需注意与 `rel_raw=0` 场景的区别。

---

*文档生成时间：2026-05-17*