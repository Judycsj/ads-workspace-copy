<!-- ads-workspace-gdoc-sync: gdoc_id=15z8WXxzUR4DFsWW1Ff7h_tU4E4igg5prtWdocUCTnmE gdoc_url=https://docs.google.com/document/d/15z8WXxzUR4DFsWW1Ff7h_tU4E4igg5prtWdocUCTnmE/edit -->

# srdi_mart.ads_sr_data_warehouse_nap_trending_item_query_mapping_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `item_id`
**分区：** `grass_region`（区域）、`local_date`（业务日期）
**更新频率：** 每日更新（T+1）
**访问频次：** 44 次

---

## 业务描述

本表用于记录 **NAP（新品/热搜场景）trending 商品与搜索词的关联映射关系**，即对于每个商品，汇总其在当日热搜词体系下最相关的查询词列表（最多 5 个）。

**核心业务场景：**
- 为 NAP 搜索推荐场景提供"商品 → 热搜词"的反向映射，支持基于热搜趋势词对商品进行召回或标注。
- 结合人工维护的关键词过滤规则，仅保留满足 trending 质量要求的有效热搜词与商品的关联。
- 输出结果可直接用于搜索/推荐系统的在线特征服务或离线分析。

**适合回答的问题：**
- 某天某区域下，指定商品关联了哪些 trending 热搜词？
- 哪些商品在热搜词体系中有关联词覆盖？
- 商品在 trending 场景下的查询词分布情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 区域标识，如 `SG`、`MY` 等，用于多区域数据隔离 |
| `local_date` | date | 业务日期（本地时区），对应数据产生的自然日 |

### 维度：商品信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，表的业务主体标识 |

### 指标：热搜词关联信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `query_list` | array\<string\> | 该商品在当日关联的有效 trending 热搜词集合（去重），按关键词在热搜词列表中的排序优先级筛选，最多保留 5 个 |

---

## 查询使用须知

1. **必须指定分区过滤条件**：查询时务必同时过滤 `grass_region` 和 `local_date`，否则会触发全分区扫描，造成资源浪费。
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2024-01-01'
   ```

2. **`query_list` 为数组类型，不可直接聚合**：该字段是 `COLLECT_SET` 去重后的数组，若需展开查询词进行统计，需使用 `LATERAL VIEW EXPLODE(query_list)` 先行展开，不可对该字段直接 `SUM` 或 `COUNT`（`COUNT(query_list)` 只计非 null 行数，无业务意义）。

3. **每个商品最多关联 5 个热搜词**：`query_list` 数组长度上限为 5，由 ETL 逻辑在写入前按排序截断。

4. **时效性说明**：本表为日级快照表（`_1d` 后缀），每天全量覆写对应分区（`INSERT OVERWRITE`），仅反映当日热搜词与商品的关联状态，不累计历史。

5. **仅覆盖有效热搜词关联的商品**：未与任何有效 trending 关键词关联的商品不会出现在本表中，查询结果为空不代表商品不存在。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `search_algo.shopping_guide_fast_rising_keyword` | 提供当日各区域的快速上升热搜词（trending 词）候选集 |
| `srdi_mart.dwd_sr_data_warehouse_nap_diversity_query_keyword_dls_1d` | 提供人工维护的关键词过滤规则（`keep_or_not = 'Y'` 表示保留），用于对热搜词进行质量管控 |
| `search_algo.shopping_guide_keyword_items` | 提供关键词与商品的关联关系，包含按展现量排序的 top 商品列表（`top_imp_items` 数组） |

---

## ETL 逻辑摘要

### 数据流

```
search_algo.shopping_guide_fast_rising_keyword
    ├── 与 srdi_mart.dwd_sr_data_warehouse_nap_diversity_query_keyword_dls_1d (keep_or_not='Y')
    │   INNER JOIN → 过滤得到有效热搜词
    │
search_algo.shopping_guide_keyword_items
    └── posexplode(top_imp_items) → 展开商品-关键词关系，保留数组位置
    
有效热搜词 JOIN 商品-关键词关系
    └── ROW_NUMBER 按 (item_id) 分组，按 (array_position, keyword) 排序，取 rn <= 5
        └── COLLECT_SET(keyword) 按 item_id 聚合
            └── INSERT OVERWRITE → ads_sr_data_warehouse_nap_trending_item_query_mapping_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|------|-----------------------|------|
| Step 1 | `valid_keywords_${grass_region_without_quote}` | 从 `shopping_guide_fast_rising_keyword` 中筛选当日有效热搜词，通过 INNER JOIN DWD 层人工维护表（`keep_or_not = 'Y'`）完成质量过滤 |
| Step 2 | `item_keyword_relation_${grass_region_without_quote}` | 对 `shopping_guide_keyword_items` 的 `top_imp_items` 数组执行 `POSEXPLODE`，展开为 (keyword, array_position, item_id) 三元组，保留数组位置用于后续排序 |
| Step 3 | `item_keywords_${grass_region_without_quote}` | 将有效热搜词与商品-关键词关系 JOIN，对每个 `item_id` 使用 `ROW_NUMBER()` 按 `(array_position, keyword)` 排序，取前 5 条（`rn <= 5`） |
| Step 4 | INSERT OVERWRITE | 对 `item_id` 聚合，`COLLECT_SET(keyword)` 生成去重的 `query_list` 数组，写入目标表对应分区 |

### 注意事项

1. **单 writer，无 multi-writer 风险**：本表仅由单个 ETL 文件写入，不存在多任务并发写同一分区的风险。
2. **分区全量覆写**：采用 `INSERT OVERWRITE PARTITION (grass_region, local_date)` 方式写入，每次运行会完整替换该分区数据，幂等性良好，支持重跑。
3. **参数化区域执行**：SQL 使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}` 等变量，同一脚本通过不同参数调度以覆盖多个区域，temporary view 名称中含区域后缀以避免多区域并发时命名冲突。
4. **`query_list` 去重语义**：最终使用 `COLLECT_SET` 而非 `COLLECT_LIST`，数组中的关键词已去重，但数组内部顺序不保证与 Step 3 的排序完全一致。

---

*文档生成时间：2026-05-17*