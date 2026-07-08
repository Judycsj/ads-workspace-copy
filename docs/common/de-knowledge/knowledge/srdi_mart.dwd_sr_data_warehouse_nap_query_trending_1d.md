<!-- ads-workspace-gdoc-sync: gdoc_id=1744DgrU-aYNniIadN5kJxvkPcR9u9_1fWJ_v-pMLm6k gdoc_url=https://docs.google.com/document/d/1744DgrU-aYNniIadN5kJxvkPcR9u9_1fWJ_v-pMLm6k/edit -->

# srdi_mart.dwd_sr_data_warehouse_nap_query_trending_1d

**分层**：DWD（明细数据层）
**主键**：`grass_region` + `local_date` + `item_id` + `trending_type`
**分区**：`grass_region`（大区）/ `local_date`（业务日期）
**更新频率**：每日一次（T+1）
**访问频次**：119 次

---

## 业务描述

本表记录 NAP（北美站）搜索场景下，**商品维度的趋势关键词标注明细数据**，来源于趋势标注回流任务（`Trend_Label_NAP` 项目）。

核心业务场景：
- 追踪每件商品在特定日期被关联的趋势关键词（`trending_keyword`）及其排名（`trending_keyword_rank`），支持搜索趋势分析与商品趋势标签维护；
- 记录商品的关联搜索词列表（`search_query_list`），用于搜索相关性分析和流量溯源；
- 通过 QC 过滤（排除重复含义、敏感、模糊、不相关标注项），保障入表数据质量。

适合回答的问题：
- 某大区某日，哪些商品被标注了趋势关键词？趋势类型是什么？
- 某商品当前关联的趋势关键词排名分布如何？
- 某商品的关联搜索词列表有哪些？
- 哪些商品通过了趋势标注 QC 审核？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 NAP），作为分区键之一，查询时必须指定 |
| `local_date` | date | 业务日期，ETL 写入时由调度参数 `${local_date}` 注入，作为分区键之一 |

### 维度：商品基本信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，由源表 `task_data_item_id` 转换而来 |
| `original_item_title` | string | 商品标题，对应源表 `task_data_item_title`，用于标识商品名称 |
| `trending_type` | string | 趋势类型，对应源表 `task_data_trending_type`，区分不同趋势维度（如季节性、爆款等） |
| `qc_status` | string | 数据质控状态，当前固定写入 `'pass'`，表示已通过 QC 过滤条件的记录 |

### 指标：趋势关键词与搜索词

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_query_list` | array\<string\> | 商品关联的搜索词列表，经 `FROM_JSON` 解析并 `ARRAY_DISTINCT` 去重，不可直接 SUM/COUNT，需 explode 后统计 |
| `trending_keyword` | array\<string\> | 趋势关键词列表，按关键词排名（`rank`）升序排列，经 `COLLECT_LIST` + `SORT_ARRAY` + `REGEXP_REPLACE` 处理，去除首尾单引号；不可直接聚合，需 explode 后使用 |
| `trending_keyword_rank` | array\<int\> | 趋势关键词对应排名列表，与 `trending_keyword` 位置一一对应，经 `SORT_ARRAY(COLLECT_LIST(rank))` 生成；不可直接 SUM，需结合 `trending_keyword` 按 zip 方式使用 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定分区字段**：`grass_region` 和 `local_date`，否则会触发全表扫描，影响性能并产生不必要的资源消耗。
  ```sql
  WHERE grass_region = 'NAP'
    AND local_date = '2024-01-01'
  ```
- 本表无历史滚动窗口语义，每个分区为当日独立全量快照（取源表最新 `grass_date` 分区写入），跨日对比需自行 JOIN 多个分区。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `search_query_list` | Array 类型，直接聚合无意义，需先 `LATERAL VIEW EXPLODE` 展开后再统计 |
| `trending_keyword` | Array 类型，且已按 rank 有序排列，需 explode 后按需分析 |
| `trending_keyword_rank` | Array 类型，与 `trending_keyword` 位置对应，需配合 zip 或 explode with ordinality 使用；直接 SUM 无业务意义 |

### 时效性说明

- 本表为 **日刷新快照表（`_1d`）**，数据 T+1 可用。
- ETL 实际写入的数据日期取自源表 `mkplsearch_data_product.trending_label_reg_daily_live` 的 **最大 `grass_date`**，而非调度参数 `local_date` 本身；若源表存在延迟，目标分区数据可能反映的是前一日或更早的最新标注状态。
- `qc_status` 固定为 `'pass'`，不代表实时审核，仅表示 ETL 过滤时通过了 QC 规则。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mkplsearch_data_product.trending_label_reg_daily_live` | 趋势标注任务回流明细表，提供商品趋势关键词、排名、搜索词及 QC 标志字段；ETL 取其最大 `grass_date` 分区中 `project_name = 'Trend_Label_NAP'` 的数据 |

---

## ETL 逻辑摘要

### 数据流

```
mkplsearch_data_product.trending_label_reg_daily_live
    （取 max(grass_date) 分区，project_name = 'Trend_Label_NAP'，QC 过滤）
        └─► 子查询展平明细
                └─► GROUP BY 聚合关键词列表
                        └─► INSERT OVERWRITE srdi_mart.dwd_sr_data_warehouse_nap_query_trending_1d
                                PARTITION (grass_region, local_date)
```

### 关键步骤

**Statement 1 —— 变量初始化**
```sql
set cat_max_date = (
    select max(grass_date) as max_date
    from mkplsearch_data_product.trending_label_reg_daily_live
);
```
获取源表最新数据日期，赋值给变量 `cat_max_date`，供后续 SQL 过滤使用。

**Statement 2 —— INSERT OVERWRITE 写目标分区**

分两层执行：

- **内层子查询**：从源表筛选 `grass_date = ${cat_max_date}`、`project_name = 'Trend_Label_NAP'` 的数据，同时排除 QC 不合格记录（`duplicated_meaning / sensitive / unclear / irrelevant` 任一为 `'Yes'` 的行，以及 header 行 `huey_task_id <> 'huey_task_id'`），按商品、标题、趋势类型、关键词、排名、搜索词六列 GROUP BY 去重。

- **外层聚合**：按 `(item_id, item_title, trending_type, search_query_list)` 分组：
  - `search_query_list`：JSON 解析后去重（`ARRAY_DISTINCT(FROM_JSON(...))`）；
  - `trending_keyword`：先 `COLLECT_LIST` 收集 `(rank, keyword)` 结构体，再 `SORT_ARRAY` 按 rank 升序排列，最后 `transform + REGEXP_REPLACE` 去除关键词首尾单引号；
  - `trending_keyword_rank`：`SORT_ARRAY(COLLECT_LIST(rank))` 按升序收集排名；
  - `qc_status`：固定写入字面值 `'pass'`。

- 最终以 `INSERT OVERWRITE … PARTITION (grass_region = ${grass_region}, local_date = ${local_date})` 写入目标分区。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，无 multi-writer 并发风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE PARTITION`，每次调度会覆盖指定 `(grass_region, local_date)` 分区，重跑幂等安全。
- **源表日期与分区日期解耦**：写入分区 `local_date` 来自调度参数，而数据实际来源于源表 `max(grass_date)`，两者可能不一致，排查数据时需注意区分。
- **`trending_keyword` 与 `trending_keyword_rank` 对应关系**：两者均通过 `SORT_ARRAY` 按 rank 升序排列，字段中同一下标位置的 keyword 和 rank 一一对应，使用时应成对处理。
- **`search_query_list` 原始格式**：源表字段为 JSON 字符串，ETL 已通过 `FROM_JSON` 解析为 `array<string>` 并去重，下游无需再次解析。

---

*文档生成时间：2026-05-17*