<!-- ads-workspace-gdoc-sync: gdoc_id=1rJLNg39wYIYs8XLpE8Ydm4FzId1BnYFWmdJzy54zQk4 gdoc_url=https://docs.google.com/document/d/1rJLNg39wYIYs8XLpE8Ydm4FzId1BnYFWmdJzy54zQk4/edit -->

# srdi_mart.dws_sr_data_warehouse_search_curated_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `user_id` + `activity_id` + `module_id` + `shop_id` + `keyword` + `keyword_category` + `keyword_cluster` + `module_schema_id`
**分区：** `grass_region`（站点大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1 覆盖写入）
**引用频次 / 访问频次：** 629

---

## 业务描述

本表是 SRDI 搜索数仓的**搜索精选模块（Curated Search）每日汇总宽表**，记录各站点、各活动、各模块、各用户、各关键词维度下的搜索曝光与点击汇总指标。

**核心业务场景：**
- 监控精选搜索模块（Curated Search）的每日曝光与点击表现；
- 分析不同活动（Activity）、模块（Module）在各大区的搜索效果；
- 按关键词、关键词分类、关键词簇评估搜索词的流量质量；
- 支持商家（Shop）维度的搜索行为分析。

**适合回答的典型问题：**
- 某站点某日，各活动模块的曝光量和点击量是多少？
- 特定关键词/关键词簇在某活动下的点击率如何？
- 某商家在指定模块的搜索曝光与点击表现？
- 不同 `module_schema_id` 下精选模块的流量分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识（如 ID、MY、TH 等），查询时必须指定 |
| `local_date` | date | 业务日期（本地时间），查询时必须指定 |

### 维度：用户与商家

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，行为主体 |
| `shop_id` | bigint | 商家 ID，搜索结果关联的店铺 |

### 维度：活动信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `activity_id` | bigint | 活动 ID |
| `activity_name` | string | 活动名称 |
| `activity_category` | string | 活动分类名称 |
| `activity_category_id` | bigint | 活动分类 ID |
| `activity_start_time` | bigint | 活动开始时间（Unix 时间戳，毫秒或秒，以上游为准） |
| `activity_end_time` | bigint | 活动结束时间（Unix 时间戳，毫秒或秒，以上游为准） |

### 维度：模块信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `module_id` | bigint | 模块 ID |
| `module_name` | string | 模块名称 |
| `module_schema_id` | bigint | 模块 Schema 类型 ID；当值为 `5` 时，曝光计数逻辑为 `COUNT(DISTINCT event_id)`，与其他值的统计口径不同 |

### 维度：关键词信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词原词 |
| `keyword_category` | string | 关键词所属分类 |
| `keyword_cluster` | string | 关键词所属聚类簇 |

### 指标：搜索行为统计

| 字段 | 类型 | 说明 |
|---|---|---|
| `impression_cnt` | bigint | 当日曝光次数；当 `module_schema_id = 5` 时为 `COUNT(DISTINCT event_id)`（去重曝光），否则为 `COUNT(1)`（原始曝光行数）；缺失时填充为 `0` |
| `click_cnt` | bigint | 当日点击次数，来源于 `operation = 'click'` 的事件行数统计；缺失时填充为 `0` |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：本表为多站点分区存储，查询时必须指定 `grass_region`，否则将触发全分区扫描，严重影响性能。
- **`local_date`**：本表为日粒度分区，查询时必须指定具体日期或日期范围，避免全量扫描。

```sql
-- 正确示例
WHERE grass_region = 'ID'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

- **`impression_cnt`（`module_schema_id = 5` 情况）**：当 `module_schema_id = 5` 时，该字段已在 ETL 中进行了 `COUNT(DISTINCT event_id)` 去重计算。若将不同 `module_schema_id` 的记录混合后直接对 `impression_cnt` 进行 SUM，**口径将不一致**，建议按 `module_schema_id` 分组分析或明确过滤。
- **点击率（CTR）等派生比率指标**：本表不含 CTR 等比率字段，如需计算，应先 SUM `click_cnt` 和 `impression_cnt`，再做除法，**不可直接对比率结果进行二次 SUM**。

### 时效性说明

- 本表为 **T+1 日更新**，每日由 ETL 任务对当日分区执行 `INSERT OVERWRITE`，数据在次日完成刷新。
- 不包含实时或准实时数据，分析最新当日数据时需关注数据就绪时间。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_curated_search_clk_imp` | 精选搜索点击与曝光明细表，作为点击和曝光两个临时视图的共同数据源，通过 `operation` 字段区分行为类型 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_curated_search_clk_imp
    │
    ├─ [operation = 'click']  ──► Temp View: dws_curated_click_{region}
    │                               GROUP BY 维度字段, COUNT(1) AS click_cnt_1d
    │
    └─ [operation = 'impression'] ─► Temp View: dws_curated_imp_{region}
                                      GROUP BY 维度字段
                                      CASE WHEN module_schema_id = 5
                                           THEN COUNT(DISTINCT event_id)
                                           ELSE COUNT(1)
                                      END AS imp_cnt_1d
                                               │
                    FULL JOIN（按全部维度字段关联）
                                               │
                                               ▼
        srdi_mart.dws_sr_data_warehouse_search_curated_metrics_1d
        PARTITION (grass_region, local_date)
        INSERT OVERWRITE
```

### 关键步骤

1. **Statement 1 — 创建点击临时视图**
   - 从 DWD 明细表过滤 `operation = 'click'`，按全部维度字段 GROUP BY，以 `COUNT(1)` 计算点击次数 `click_cnt_1d`，结果存入临时视图 `dws_curated_click_{region}`。

2. **Statement 2 — 创建曝光临时视图**
   - 从同一 DWD 明细表过滤 `operation = 'impression'`，按全部维度字段 GROUP BY，以分支逻辑计算曝光次数 `imp_cnt_1d`（`module_schema_id = 5` 时使用 `COUNT(DISTINCT event_id)`，否则使用 `COUNT(1)`），结果存入临时视图 `dws_curated_imp_{region}`。

3. **Statement 3 — FULL JOIN 写入目标表**
   - 将点击临时视图与曝光临时视图按全部 14 个维度字段做 FULL JOIN，使用 `COALESCE` 填充 NULL 维度字段，并将 `impression_cnt` 和 `click_cnt` 缺失时置为 `0`，最终 `INSERT OVERWRITE` 写入目标表对应分区。

### 注意事项

- **单 Writer 写入**：本表 ETL 为单文件驱动（`multi_writer = false`），同一分区只有一个 Spark job 写入，无并发写冲突风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 模式，每次运行会覆盖对应分区全量数据，补数或重跑时需注意对当日分区的覆盖影响。
- **维度对齐风险**：FULL JOIN 使用 14 个字段作为联接键，若 DWD 上游对同一事件的 `click` 和 `impression` 在维度字段取值上存在不一致（如 `keyword` 大小写差异），将导致关联失败、曝光或点击为 `0` 的记录产生，需关注上游数据质量。
- **`module_schema_id = 5` 口径特殊性**：曝光指标在该 Schema 类型下进行了去重处理，与其他 Schema 类型的统计口径不同，跨 `module_schema_id` 聚合时需格外注意。
- **参数化分区**：SQL 中使用了 `${grass_region}`、`${local_date}` 等参数占位符，临时视图名称也使用了 `${grass_region_without_quote}` 以避免引号冲突，实际执行时由调度系统注入。

---

*文档生成时间：2026-05-17*