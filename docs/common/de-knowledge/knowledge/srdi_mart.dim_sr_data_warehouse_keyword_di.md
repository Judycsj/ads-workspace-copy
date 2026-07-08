<!-- ads-workspace-gdoc-sync: gdoc_id=1EubgL4DpLUX5wOYa9wGneT_qWc9QML0mT34iEo9JNJI gdoc_url=https://docs.google.com/document/d/1EubgL4DpLUX5wOYa9wGneT_qWc9QML0mT34iEo9JNJI/edit -->

# srdi_mart.dim_sr_data_warehouse_keyword_di

**分层：** DIM（维度层）
**主键：** `grass_region` + `local_date` + `keyword`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE，按分区刷新）
**访问频次：** 6,003 次

---

## 业务描述

本表为搜推数仓的**关键词维度表**，以关键词（`keyword`）为粒度，整合了关键词的类目归属（全量五级类目体系与受限路径类目）、关键词聚类标签、搜索意图标签等多维属性，每日按站点分区全量更新。

**核心业务场景：**
- 搜索关键词的类目体系映射与下钻分析（L1～L5 全球后端类目归属）
- 关键词意图识别（如购物意图、导航意图等标签集合）
- 关键词聚类分析（基于 L1 类目的 cluster 分组）
- 受限类目路径分析（`restricted_*` 字段，用于特定业务场景下的类目过滤或合规控制）

**适合回答的问题：**
- 某关键词属于哪个 L1/L2/L3/L4/L5 全球后端类目？
- 某关键词的搜索意图标签有哪些？
- 某关键词归属于哪个类目 cluster？
- 某站点某日期下，特定类目下有哪些关键词？
- 受限类目维度下关键词的分布情况如何？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `SG`、`MY`、`PH` 等，按此字段进行分区存储 |
| `local_date` | date | 业务日期，ETL 运行日期对应的本地日期，按此字段进行分区存储 |

### 维度：关键词基础属性

| 字段名 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词（已经过 TRIM + LOWER 标准化处理） |
| `keyword_cluster` | string | 关键词所属聚类标签，来源于 L1 类目与 cluster 映射表，取 L1 类目对应的最大 cluster 值 |
| `keyword_intention` | array\<string\> | 关键词意图标签集合，取近 90 天内该关键词的所有意图标签（如购物意图、信息查询等），来源于搜索关键词标签表 |
| `keyword_timestamp` | date | 关键词时间戳（当前版本 ETL 写入 NULL，字段保留供后续使用） |

### 维度：全球后端类目（五级类目体系）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `level1_keyword_category` | string | 关键词归属的 L1 全球后端类目名称，基于印象量（impression）最大类目取值，通过受限路径逐级收束 |
| `level1_keyword_category_id` | int | 关键词归属的 L1 全球后端类目 ID |
| `level2_keyword_category` | string | 关键词归属的 L2 全球后端类目名称（在 L1 确定的基础上，按印象量最大子类目取值） |
| `level2_keyword_category_id` | int | 关键词归属的 L2 全球后端类目 ID |
| `level3_keyword_category` | string | 关键词归属的 L3 全球后端类目名称 |
| `level3_keyword_category_id` | int | 关键词归属的 L3 全球后端类目 ID |
| `level4_keyword_category` | string | 关键词归属的 L4 全球后端类目名称 |
| `level4_keyword_category_id` | int | 关键词归属的 L4 全球后端类目 ID |
| `level5_keyword_category` | string | 关键词归属的 L5 全球后端类目名称 |
| `level5_keyword_category_id` | int | 关键词归属的 L5 全球后端类目 ID |

> **注意：** 根据 ETL SQL，当前版本五级类目字段中 `level1_keyword_category_id` ～ `level5_keyword_category_id` 对应 INSERT 语句中的 `cat_id_l1`～`cat_id_l5`，`level1_keyword_category`～`level5_keyword_category` 对应 `level1_global_be_category`～`level5_global_be_category`。类目归属采用**受限路径**（restricted path）策略逐级收束确定，详见 ETL 逻辑摘要。

### 维度：受限路径类目（二、三级）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `restricted_level2_keyword_category` | string | 受限路径下关键词的 L2 类目名称（当前版本 ETL 写入 NULL，字段保留供后续使用） |
| `restricted_level2_keyword_category_id` | int | 受限路径下关键词的 L2 类目 ID（当前版本 ETL 写入 NULL，字段保留供后续使用） |
| `restricted_level3_keyword_category` | string | 受限路径下关键词的 L3 类目名称（当前版本 ETL 写入 NULL，字段保留供后续使用） |
| `restricted_level3_keyword_category_id` | int | 受限路径下关键词的 L3 类目 ID（当前版本 ETL 写入 NULL，字段保留供后续使用） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定站点分区，避免全表扫描。示例：`WHERE grass_region = 'SG'`
- **`local_date`**：必须指定业务日期分区，本表为每日全量覆盖，通常取最新日期。示例：`AND local_date = '2026-05-16'`
- 同时过滤两个分区字段是查询性能的基本保障。

### 不可直接聚合的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `keyword_intention` | array 类型，集合字段，不可直接 SUM/COUNT | 使用 `EXPLODE` 展开后按元素聚合 |
| `level*_keyword_category` / `level*_keyword_category_id` | 维度属性，不可加总，用于分组或过滤 | 作为 GROUP BY 维度使用 |
| `keyword_cluster` | 维度分组标签，不可加总 | 作为 GROUP BY 维度使用 |

### 时效性说明

- 本表为**每日全量维度表**（`_di` 后缀），每日按 `grass_region` + `local_date` 分区 INSERT OVERWRITE 全量刷新。
- `keyword_intention` 的采集窗口为**近 90 天**（`dt >= date_sub(local_date, 90)`），反映关键词的中期意图特征，并非仅当天数据。
- `keyword_timestamp`、`restricted_level2_*`、`restricted_level3_*` 四个字段当前 ETL 写入 **NULL**，查询时请注意，不要依赖这些字段做过滤或计算。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mkplsearch_data_product.global_category_cluster_mapping` | 获取 L1 类目与 cluster 的映射关系，用于生成关键词聚类标签 |
| `search_algo.search_keyword_tags_dump_latest` | 获取关键词意图标签（近 90 天），用于生成 `keyword_intention` 字段 |
| `mp_item.dim_global_be_category__reg_s0_live` | 获取全球后端类目五级层级结构（L1～L5 ID 与名称对应关系） |
| `srdi_mart.dws_sr_data_warehouse_search_keyword_query_cat_count_1d` | 获取关键词在各级类目下的曝光（impression）计数，作为类目归属判断的权重依据 |

---

## ETL 逻辑摘要

### 数据流

```
search_keyword_query_cat_count_1d（关键词-类目曝光量）
    + dim_global_be_category__reg_s0_live（类目层级结构）
        → 各级类目曝光计数（L1～L5）
            → 受限路径（逐级贪心选最大印象量子类目，L1→L2→L3→L4→L5）
                → l5_restricted（关键词最终五级类目归属）
                    ↕ LEFT JOIN category_cluster（L1类目→cluster）
                    ↕ LEFT JOIN kw_tag（关键词→意图标签集合）
                        → INSERT OVERWRITE dim_sr_data_warehouse_keyword_di
```

### 关键步骤

1. **`category_cluster`（临时视图）**：从 L1 类目-cluster 映射表按 `tree_type='global'` 过滤，对每个 L1 类目取 `MAX(cluster)` 作为唯一 cluster 标签。

2. **`kw_tag`（临时视图）**：从搜索关键词标签表中，取近 90 天内当前站点的数据，对关键词（TRIM+LOWER 标准化）按 `COLLECT_SET` 聚合所有意图标签。

3. **`item_cats`（临时视图）**：从全球后端类目维度表中获取当日快照，构建 L1～L5 的完整类目层级对照关系（用于后续各级 JOIN 补全类目名称）。

4. **`all_cat_cnts`（临时视图）**：从关键词-类目曝光量汇总表取当日 impression 数据，按关键词、类目 ID、层级（L1～L5）汇总 `SUM(count)`，排除 L1/L2 层级中 `cat_id=0` 的无效数据。

5. **`l1_cat_cnt` ～ `l5_cat_cnt`（临时视图，共 5 个）**：将 `all_cat_cnts` 按层级拆分，分别与 `item_cats` JOIN，补全各层级类目名称及父级类目 ID，形成各层级的关键词-类目-曝光量宽表。

6. **`l1_restricted` ～ `l5_restricted`（临时视图，共 5 个，受限路径收束）**：
   - `l1_restricted`：对每个关键词，按 L1 曝光量降序取第 1 名，确定唯一 L1 类目。
   - `l2_restricted`：在 `l1_restricted` 确定的 L1 类目约束下，与 `l2_cat_cnt` JOIN，按 L2 曝光量降序取第 1 名，确定唯一 L2 类目。
   - 以此类推，`l3_restricted`、`l4_restricted`、`l5_restricted` 逐级在父级约束下贪心选取印象量最大的子类目，最终形成每个关键词唯一的五级类目路径。

7. **INSERT OVERWRITE（最终写入）**：以 `l5_restricted` 为主表，LEFT JOIN `category_cluster`（按 L1 类目名称匹配 cluster），LEFT JOIN `kw_tag`（按关键词匹配意图标签），写入目标分区。`keyword_timestamp`、`restricted_level2_*`、`restricted_level3_*` 四个字段当前写入 NULL。

### 注意事项

- **单 writer 写入**：本表仅有 1 个 ETL 文件，无 multi-writer 风险，同一分区不存在并发写入冲突。
- **分区覆盖写入**：每次执行均为 `INSERT OVERWRITE` 按 `(grass_region, local_date)` 分区全量刷新，历史分区数据保留，当日分区完整重写。
- **NULL 字段预留**：`keyword_timestamp`、`restricted_level2_keyword_category`、`restricted_level2_keyword_category_id`、`restricted_level3_keyword_category`、`restricted_level3_keyword_category_id` 共 5 个字段当前 ETL 固定写入 NULL，为后续业务扩展预留，使用时请注意不依赖这些字段进行业务过滤或计算。
- **受限路径贪心策略**：类目归属采用逐级受限（restricted path）策略，每级类目仅在父级确定的范围内选取印象量最大的子类目，而非全局最大子类目，因此五级类目路径是一条自上而下一致的受限最优路径。
- **关键词标准化**：所有 `keyword` 字段均经过 `TRIM(LOWER(...))` 处理，下游使用时需保持一致的标准化方式进行 JOIN 或过滤。
- **`kw_tag` 窗口依赖**：`keyword_intention` 取近 90 天标签窗口，若源表 `search_keyword_tags_dump_latest` 数据存在延迟或缺失，可能导致部分关键词意图标签为空。

---

*文档生成时间：2026-05-17*