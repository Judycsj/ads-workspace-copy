<!-- ads-workspace-gdoc-sync: gdoc_id=1fMjVKxPEg8gPBP7ixThPASK7aCuHbMJWKcJ8UFaCluw gdoc_url=https://docs.google.com/document/d/1fMjVKxPEg8gPBP7ixThPASK7aCuHbMJWKcJ8UFaCluw/edit -->

# srdi_mart.dim_sr_data_warehouse_nap_trending_pool_df

**分层：** DIM（维度层）
**主键：** `item_id`（在给定 `grass_region` + `local_date` 分区内唯一）
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖（`INSERT OVERWRITE`）
**访问频次：** 104 次

---

## 业务描述

本表为**新增商品潮流趋势候选池（NAP Trending Pool）维度快照表**，记录在各大区（`grass_region`）维度下，由推荐系统筛选出的每日潮流趋势商品及其所属类目信息。

**核心业务场景：**
- 为搜索/推荐（SR）算法提供每日潮流趋势候选商品池，供召回、过滤或特征构建使用。
- 结合类目维度（`global_be_category`、`global_be_category_id`）支持按类目维度分析潮流趋势商品分布。
- 作为下游算法或报表的基础维度表，回答"某大区某日有哪些商品/店铺进入潮流趋势池"、"潮流趋势商品的全球后端类目分布如何"等问题。

**适合回答的典型问题：**
- 某大区某日的潮流趋势候选商品有哪些？
- 各类目下潮流趋势商品的数量分布？
- 特定商品/店铺是否在今日趋势池中？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 `SG`、`MY`、`TH` 等），与上游 `rcmd_feature.nap_trending_pool_v2` 及 `srdi_mart.dim_sr_data_warehouse_item` 保持一致 |
| `local_date` | date | 业务日期，表示该批次数据对应的本地日期，每日全量覆盖 |

### 维度：商品与店铺标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，来自 `rcmd_feature.nap_trending_pool_v2`，在当日潮流趋势池中去重后作为主体标识 |
| `shop_id` | bigint | 商品所属店铺 ID，对同一 `item_id` 取 `max(shop_id)` 聚合，代表该商品关联的店铺 |

### 维度：商品类目信息

| 字段名 | 类型 | 说明 |
|---|---|---|
| `global_be_category_id` | bigint | 全球后端类目 ID，从 `srdi_mart.dim_sr_data_warehouse_item` left join 补全，取 `max(global_be_category_id)`；若商品在商品维表中不存在则为 NULL |
| `global_be_category` | string | 全球后端类目名称，从 `srdi_mart.dim_sr_data_warehouse_item` left join 补全，取 `max(global_be_category)`；若商品在商品维表中不存在则为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区键，查询时必须指定，避免全表扫描。
- **`local_date`**：分区键，必须指定目标业务日期（通常取最新日期或特定日期），避免跨分区全量读取。

```sql
-- 推荐写法示例
SELECT *
FROM srdi_mart.dim_sr_data_warehouse_nap_trending_pool_df
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01';
```

### 不可直接 SUM / 二次聚合的注意事项

- **`shop_id`**：该字段为 `max(shop_id)` 的聚合结果，语义上代表商品关联店铺，**不可对其进行 SUM 或均值运算**，仅用于过滤和关联。
- **`global_be_category_id` / `global_be_category`**：同样为 `max()` 聚合取值，存在 NULL（商品未命中商品维表时），使用前建议做非空过滤。

### 时效性说明

- 本表为**每日全量快照（df = daily full）**，每个 `grass_region` + `local_date` 分区代表当日潮流趋势商品池的完整快照。
- 上游 `rcmd_feature.nap_trending_pool_v2` 中取的是 `max(grass_date)` 对应的最新数据，因此本表实际反映的是上游特征表的最新可用日期数据，而非严格意义上的 T 日生产数据，若上游数据延迟则本表内容可能落后于 `local_date`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `rcmd_feature.nap_trending_pool_v2` | 主表，提供当日（取 `max(grass_date)`）各大区的潮流趋势候选商品池，包含 `item_id`、`shop_id` 等核心字段 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，按 `grass_region` + `local_date` 过滤后，left join 补全商品的全球后端类目信息（`global_be_category_id`、`global_be_category`） |

---

## ETL 逻辑摘要

### 数据流

```
rcmd_feature.nap_trending_pool_v2
        │  （按 grass_region + max(grass_date) 过滤，item_id 去重，max(shop_id)）
        ▼
    子查询 T1（item_id, shop_id）
        │
        │  LEFT JOIN on item_id
        ▼
srdi_mart.dim_sr_data_warehouse_item
        │  （按 grass_region + local_date 过滤，item_id 去重，max 类目字段）
        ▼
    子查询 T2（item_id, global_be_category_id, global_be_category）
        │
        ▼
srdi_mart.dim_sr_data_warehouse_nap_trending_pool_df
（INSERT OVERWRITE PARTITION(grass_region, local_date)）
```

### 关键步骤

1. **Statement 1 — 创建临时视图 `max_date_view_${grass_region_without_quote}`**
   - 从 `rcmd_feature.nap_trending_pool_v2` 中，按当前处理的 `grass_region` 查询最新的 `grass_date`（`max(grass_date)`）。
   - 结果存为临时视图，供后续 INSERT 语句中的子查询引用，确保取上游最新可用日期的数据。

2. **Statement 2 — INSERT OVERWRITE 写入目标表**
   - **子查询 T1**：从 `rcmd_feature.nap_trending_pool_v2` 按 `grass_region` 和上一步得到的 `max_date` 过滤，以 `item_id` 为粒度聚合（`group by item_id`），取 `max(shop_id)` 作为代表店铺。
   - **子查询 T2**：从 `srdi_mart.dim_sr_data_warehouse_item` 按 `grass_region` + `local_date` 过滤，同样以 `item_id` 聚合，取 `max(global_be_category)` 和 `max(global_be_category_id)`。
   - **关联**：T1 LEFT JOIN T2 on `item_id`，保留趋势池中所有商品，类目信息可为 NULL。
   - **写入**：`INSERT OVERWRITE` 指定 `PARTITION(grass_region, local_date)` 全量覆盖当日分区。

### 注意事项

- **单一 ETL 文件，无 multi-writer 风险**：本表仅有一个 ETL 文件写入，不存在多任务并发写同一分区的竞争问题。
- **上游日期对齐风险**：ETL 中使用 `max(grass_date)` 动态获取上游最新日期，若上游 `rcmd_feature.nap_trending_pool_v2` 当日数据未就绪，本表将沿用上游最近可用日期的数据，可能导致 `local_date` 与实际数据日期不一致，使用时需注意。
- **聚合语义**：`shop_id`、`global_be_category`、`global_be_category_id` 均通过 `max()` 聚合处理，对于同一商品存在多个值的情况，仅保留字典序或数值最大的一个，业务使用时需了解此聚合规则的潜在影响。
- **类目信息可为 NULL**：若商品在 `srdi_mart.dim_sr_data_warehouse_item` 中无对应记录，`global_be_category_id` 和 `global_be_category` 将为 NULL，下游使用时需做相应的空值处理。

---

*文档生成时间：2026-05-17*