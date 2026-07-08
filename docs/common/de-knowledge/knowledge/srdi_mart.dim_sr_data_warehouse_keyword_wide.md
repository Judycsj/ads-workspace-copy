<!-- ads-workspace-gdoc-sync: gdoc_id=1dUJ6fkmJAzuLraDwwD8BOqbEnTwGcMX2Ddgs6TrpX2k gdoc_url=https://docs.google.com/document/d/1dUJ6fkmJAzuLraDwwD8BOqbEnTwGcMX2Ddgs6TrpX2k/edit -->

# srdi_mart.dim_sr_data_warehouse_keyword_wide

**分层**：DIM（维度层）
**主键**：`grass_region` + `local_date` + `keyword`
**分区**：`grass_region`，`local_date`
**更新频率**：每日（T+1）
**访问频次**：198

---

## 业务描述

本表是搜索关键词的宽表维度，记录每个关键词在特定站点（`grass_region`）和日期下，**最匹配的一级商品类目**信息。

其核心逻辑为：基于当日有真实搜索行为的关键词，关联过去 31 天（含当日）的搜索曝光数据及商品类目信息，以"最近日期优先、曝光量最高优先"的策略，为每个关键词打上最具代表性的一级全球后端类目标签。

**核心业务场景：**
- 搜索关键词的类目归因与语义理解
- 搜索流量的类目维度分析（如按类目统计搜索量、CTR 等）
- 关键词类目扩展与搜索推荐策略优化
- 搜索与推荐联动场景中的关键词特征补全

**适合回答的问题：**
- 关键词 X 在某站点某日期下归属于哪个一级类目？
- 哪些关键词被归类到某一特定类目下？
- 不同站点的关键词类目分布差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 站点/大区标识，如 `'ID'`、`'TH'` 等，用于区分不同市场的数据分区 |
| `local_date` | date | 数据日期（本地日期），对应 ETL 调度日期；关键词须在当日有搜索行为才会写入 |

### 维度：关键词信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 搜索关键词，已做小写（`LOWER`）和去空格（`TRIM`）标准化处理 |

### 维度：关键词类目归因

| 字段 | 类型 | 说明 |
|------|------|------|
| `level1_keyword_category_max_imp` | string | 关键词对应的一级全球后端类目名称（`level1_global_be_category`）；基于过去 31 天内最近日期、曝光量最高的商品类目推断 |
| `level1_keyword_category_id_max_imp` | bigint | 关键词对应的一级全球后端类目 ID（`level1_global_be_category_id`）；与 `level1_keyword_category_max_imp` 一一对应 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将全量扫描所有站点分区，产生大量不必要的数据读取。
- **`local_date`**：必须指定，建议使用等值过滤（`local_date = 'YYYY-MM-DD'`）。该表每日覆盖写入，直接取特定日期分区即可获得当日最新的关键词类目映射。

```sql
-- 推荐写法
SELECT keyword, level1_keyword_category_max_imp, level1_keyword_category_id_max_imp
FROM srdi_mart.dim_sr_data_warehouse_keyword_wide
WHERE grass_region = 'ID'
  AND local_date = '2024-01-15';
```

### 不可直接 SUM 的字段

- 本表为**维度宽表**，不包含任何指标字段，所有字段均为维度属性，不存在聚合计算场景。
- `level1_keyword_category_id_max_imp` 和 `level1_keyword_category_max_imp` 是归因结果，**不可进行数值聚合**（如 SUM、AVG），只可用于分组或过滤。

### 时效性说明

- 每日 T+1 调度，当日数据通常于次日早间完成写入。
- 类目归因逻辑基于**过去 31 天（含当日）**的曝光数据进行计算，属于**滚动窗口预聚合**结果，已固化在分区内，查询时直接使用当日分区即可，无需自行做窗口聚合。
- 关键词须在**当日（`local_date`）**有真实搜索行为（来自 `global_search`、`search_in_pdp`、`search_prefill` 页面类型）才会出现在当日分区中；历史存在但当日无搜索的关键词不会出现。
- `level1_keyword_category_max_imp` / `level1_keyword_category_id_max_imp` 可能随日期变化而改变（因 31 天曝光窗口滚动），使用时需注意时间维度一致性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细表，提供关键词列表（当日搜索行为）及过去 31 天的关键词 × 商品曝光量数据 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度宽表，提供商品 ID 到一级全球后端类目（名称及 ID）的映射，使用过去 31 天数据 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search（当日搜索词）
        ↓ 去重、标准化
keywords_all_ops_1d（当日活跃关键词集合）
        ↓ LEFT JOIN
dwd_sr_data_warehouse_search（31天曝光明细）
        → keywords_item_id_imp_31d（关键词×商品 31天曝光汇总）
        ↓ LEFT JOIN
keywords_filter_1d（限定当日关键词的31天曝光数据）
        ↓ LEFT JOIN
dim_sr_data_warehouse_item（31天商品类目）
        → keywords_item_cat（关键词×类目 31天曝光汇总）
        ↓ ROW_NUMBER 排序
keywords_item_cat_rank（关键词×类目排名）
        ↓ WHERE recency_rank = 1
INSERT OVERWRITE → dim_sr_data_warehouse_keyword_wide
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|------|---------------|------|
| Step 1 | `item_cats_31d` | 从 `dim_sr_data_warehouse_item` 取过去 31 天的商品一级全球后端类目数据 |
| Step 2 | `keywords_all_ops_1d` | 从 `dwd_sr_data_warehouse_search` 取当日有效搜索关键词（标准化后去重），过滤条件：`page_type IN ('global_search','search_in_pdp','search_prefill')`、`page_section IS NULL`、`target_type IN ('item','video','livestream')`、`keyword IS NOT NULL` |
| Step 3 | `keywords_item_id_imp_31d` | 从 `dwd_sr_data_warehouse_search` 取过去 31 天曝光事件（`operation = 'impression'`），按关键词 × 商品 × 日期聚合 `SUM(operation_cnt)` 得到曝光量 |
| Step 4 | `keywords_filter_1d` | 以当日关键词集合（Step 2）LEFT JOIN 31 天曝光数据（Step 3），保证只保留当日有搜索行为的关键词 |
| Step 5 | `keywords_item_cat` | LEFT JOIN 商品类目数据（Step 1），按关键词 × 类目 × 日期聚合曝光量 |
| Step 6 | `keywords_item_cat_rank` | 使用 `ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY local_date DESC, imp_count DESC)` 对每个关键词的类目候选排序，取最近日期中曝光量最高者 |
| Step 7 | INSERT OVERWRITE | 过滤 `recency_rank = 1`，将关键词及其最匹配类目写入目标表对应 `grass_region` + `local_date` 分区 |

### 注意事项

- **单一 Writer**：本表仅有一个 ETL 文件写入，不存在 multi-writer 并发写分区风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，每次调度会完整覆盖当日分区，重跑安全。
- **关键词过滤逻辑**：Step 4 的 LEFT JOIN 设计保证了目标表**只记录当日有搜索行为的关键词**，过去有行为但今日未出现的关键词不会继承历史分区数据，存在关键词"消失"的情况，使用时注意。
- **类目归因为预聚合结果**：`level1_keyword_category_max_imp` 是基于 31 天滚动窗口取的最优类目，非当日实时计算值，直接使用分区字段过滤查询即可，切勿在业务层对多日分区数据进行二次聚合取最大值。
- **参数化模板**：SQL 使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 等变量，各站点按参数独立调度，Temporary View 名称含站点后缀以避免命名冲突。

---

*文档生成时间：2026-05-17*