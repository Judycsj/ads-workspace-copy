<!-- ads-workspace-gdoc-sync: gdoc_id=1odGX7M315MYHuSzDYijZOmQUE3RIXwBjgUfSk6gxWDk gdoc_url=https://docs.google.com/document/d/1odGX7M315MYHuSzDYijZOmQUE3RIXwBjgUfSk6gxWDk/edit -->

# srdi_mart.dwd_sr_data_warehouse_nap_diversity_query_keyword_source_1d

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `local_date` + `keyword`
**分区：** `grass_region`（区域）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1，以前一天数据为基准）
**引用频次/访问频次：** 11

---

## 业务描述

本表用于记录**搜索多样性（NAP Diversity）场景下，经过去重筛选后的查询关键词来源明细**。具体地，表中存放的是从"快速上升关键词"池（`shopping_guide_fast_rising_keyword`）中筛选出的、在历史窗口内**首次出现**的新兴关键词，并附带其一级全球后端类目信息。

核心业务场景：
- 为搜索推荐多样性算法（NAP Diversity）提供候选词表，避免重复推送已在历史数据中出现过的关键词。
- 追踪某一区域下每日新增的快速上升搜索词及其所属商品类目，支持类目分布分析。
- 支持多区域并行运营，精细化管理各区域的候选关键词池。

适合回答的典型问题：
- 某区域某日有哪些新出现的快速上升搜索词？
- 新兴关键词主要集中在哪些一级类目？
- 历史上某关键词最早是在哪天进入候选词池的？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识（如 SG、MY、TH 等），用于区分不同本地化市场 |
| `local_date` | date | 业务日期，表示该批关键词被纳入候选池的日期（即快速上升词来源日期的次日） |

### 维度：关键词与类目信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词，从快速上升关键词池中筛选出的、当日首次出现的新兴词 |
| `level1_global_be_category_id` | bigint | 关键词对应的一级全球后端类目 ID |
| `level1_global_be_category` | string | 关键词对应的一级全球后端类目名称 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（强制）**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全分区扫描，导致性能问题：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 若需查询某一区域的历史累计词表，可按 `local_date` 范围过滤，但务必锁定 `grass_region`。

### 不可直接 SUM 的字段

- 本表为关键词明细表，无聚合指标字段，不存在直接 SUM 的限制。
- 注意：`keyword` 在同一分区内经过 `GROUP BY` 去重，同一 `(grass_region, local_date, keyword)` 组合不会重复出现。但若跨 `local_date` 统计，**同一 keyword 可能在不同日期分区均存在**（ETL 仅保证当日不重复历史，不保证全局唯一），统计新词数量时需做去重处理：
  ```sql
  SELECT COUNT(DISTINCT keyword) FROM ...
  ```

### 时效性说明

- 本表为 **`_1d` 日粒度表**，每日产出一个新分区，T+1 写入。
- ETL 使用 `date_sub(${local_date}, 1)` 作为上游数据源的日期，即当日写入的数据来源于**前一天**的快速上升关键词快照。
- 历史去重逻辑基于 `local_date <= date_sub(${local_date}, 1)` 的已有数据，因此该表具有**增量去重语义**：每日只写入此前从未入库的新词，历史分区数据**不会被修改**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `search_algo.shopping_guide_fast_rising_keyword` | 提供快速上升关键词候选池，包含关键词、类目、时间段（`fast_rising_1d_all` / `fast_rising_7d_all`）及区域信息，作为每日新词的来源 |
| `srdi_mart.dwd_sr_data_warehouse_nap_diversity_query_keyword_source_1d`（自引用） | 读取历史已入库关键词，用于去重过滤，确保当日写入的关键词在历史分区中从未出现 |

---

## ETL 逻辑摘要

### 数据流

```
search_algo.shopping_guide_fast_rising_keyword
        │  过滤：grass_region、grass_date = local_date-1、duration IN (fast_rising_1d_all / fast_rising_7d_all)
        ▼
  候选快速上升词（keyword + 类目信息）
        │  排除：已存在于目标表历史分区（local_date <= local_date-1）的 keyword
        ▼
  valid_keywords（新词明细）
        │
        ▼
  INSERT OVERWRITE 目标表对应分区（grass_region, local_date）
```

### 关键步骤

1. **Statement 1 — 创建临时视图 `valid_keywords_${grass_region_without_quote}`**
   - 从 `search_algo.shopping_guide_fast_rising_keyword` 中，按当前区域（`grass_region`）和前一天日期（`grass_date = local_date - 1`）过滤。
   - 进一步限定 `duration` 为 `fast_rising_1d_all` 或 `fast_rising_7d_all`，确保只取短期快速上升词。
   - 通过子查询从目标表本身读取历史已有关键词（`local_date <= local_date - 1`），用 `NOT IN` 排除已入库的词，实现增量去重。
   - 对 `(keyword, level1_global_be_category_id, level1_global_be_category)` 做 `GROUP BY` 去重，保证临时视图中每个关键词唯一。

2. **Statement 2 — INSERT OVERWRITE 写目标表**
   - 将临时视图 `valid_keywords_${grass_region_without_quote}` 的全量数据，以 `INSERT OVERWRITE` 方式写入目标表的对应分区 `(grass_region, local_date)`。
   - 目标表中只写入维度字段（`keyword`、`level1_global_be_category_id`、`level1_global_be_category`），分区列由 Hive 分区机制自动处理。

### 注意事项

- **自引用风险**：ETL 在构建临时视图时会读取目标表的历史分区，需确保目标表历史分区数据完整且正确，否则去重逻辑将失效，可能导致新词漏写或历史词重复写入。
- **INSERT OVERWRITE 覆盖语义**：每次执行会覆盖当前 `(grass_region, local_date)` 分区的全部数据，重跑同一分区是安全的，但会清除该分区此前的写入结果。
- **参数化区域**：SQL 中使用了 `${grass_region}` 和 `${grass_region_without_quote}` 两种参数形式，前者带引号用于 SQL 比较，后者不带引号用于临时视图命名，多区域任务需逐区域独立调度执行。
- **单 writer**：本表为单文件 ETL，无多 writer 并发写入风险，分区边界由调度参数控制。
- **duration 字段过滤**：同时纳入 `fast_rising_1d_all` 和 `fast_rising_7d_all` 两类上升趋势，两种来源数据在临时视图中合并后再去重，最终写入结果为两类来源的并集中的新词。

---

*文档生成时间：2026-05-17*