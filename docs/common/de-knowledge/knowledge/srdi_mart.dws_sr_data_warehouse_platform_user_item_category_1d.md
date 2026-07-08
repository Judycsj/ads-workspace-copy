<!-- ads-workspace-gdoc-sync: gdoc_id=1WQ_CQjC3848lGG_pkL4vTBfftDKdgdzYOGCcyX6dqEY gdoc_url=https://docs.google.com/document/d/1WQ_CQjC3848lGG_pkL4vTBfftDKdgdzYOGCcyX6dqEY/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_user_item_category_1d

**分层**：DWS（数据汇总层）
**主键**：`user_id` + `item_id` + `operation` + `grass_region` + `local_date`
**分区**：`grass_region` / `local_date` / `operation`
**更新频率**：每日一次（T+1）
**引用频次 / 访问频次**：0

---

## 业务描述

本表记录**搜推数仓平台**中，用户与商品在一级全球品类（Men Clothes / Women Clothes）维度上的交互明细，粒度为**用户 × 商品 × 操作行为 × 日期**。

数据仅保留 `level1_global_be_category_id` 属于服装大类（100011 男装、100017 女装）的商品，操作行为限定为 **加购（cart）** 和 **下单（order）**。

**核心业务场景**：
- 统计某区域/日期下，男女装类目的用户行为量（加购数、下单数）。
- 分析用户在服装大类维度的购买偏好与转化漏斗（cart → order）。
- 作为上游宽表，为用户画像、类目运营、搜推效果评估等场景提供品类行为基础数据。

**适合回答的问题**：
- 某日某区域有多少用户对女装商品执行了加购/下单操作？
- 男装 vs 女装的用户行为分布如何？
- 特定用户在某日与哪些服装商品发生了交互？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识（如国家/站点），分区写入，查询时必须指定 |
| `local_date` | date | 业务日期，数据对应的自然日，分区写入，查询时必须指定 |
| `operation` | string | 用户操作行为，当前仅含 `cart`（加购）和 `order`（下单），动态分区写入 |

### 维度：用户与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识 |
| `item_id` | bigint | 商品唯一标识，仅保留 `item_id > 0` 的有效商品 |

### 指标：商品一级全球品类信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | bigint | 商品一级全球后端品类 ID，当前仅含 100011（Men Clothes）和 100017（Women Clothes）；由 `MAX` 聚合得出，在同一 `(user_id, item_id, operation)` 粒度下品类 ID 唯一，`MAX` 为消重手段 |
| `level1_global_be_category` | string | 商品一级全球后端品类名称，与 `level1_global_be_category_id` 对应；同上，由 `MAX` 聚合得出 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，查询时务必指定，否则触发全表扫描，影响性能。
- **`local_date`**：分区字段，查询时务必指定具体日期或合理范围。
- **`operation`**：分区字段，如只需分析特定行为（如仅下单），建议显式过滤以缩小扫描范围。

### 不可直接 SUM / 再聚合的注意事项

- **`level1_global_be_category_id` / `level1_global_be_category`**：均由 `MAX` 聚合写入，在当前粒度（`user_id + item_id + operation`）下为描述性属性，不具有数值累加意义，不应对其做 `SUM`。
- 本表已是按 `(user_id, item_id, operation)` 去重聚合后的结果，**不存在重复行**，如需统计用户数/商品数请使用 `COUNT DISTINCT`，不可直接 `COUNT(*)` 当作行为次数使用（本表不记录行为次数/频次）。

### 时效性说明

- 表名后缀 `_1d` 表示**天级快照表**，每个分区对应一个自然日的数据。
- 数据通常在 T+1 完成写入，当日数据不可用。
- 跨日期分析需遍历多个 `local_date` 分区，注意控制扫描范围。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，提供商品的一级全球品类信息（`level1_global_be_category_id`、`level1_global_be_category`），并按品类 ID 过滤服装类目（100011、100017） |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 用户 × 商品行为中间层，提供用户对商品的操作行为记录（`cart`、`order`） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_item          dwm_sr_data_warehouse_platform_user_item
        │（过滤服装类目 + 有效商品）                   │（过滤 cart/order 行为）
        ▼                                              ▼
item_category_<region>  ──── INNER JOIN（item_id）──── dwm_user_item_<region>
                                        │
                          GROUP BY user_id, item_id, operation
                          MAX(level1_global_be_category_id)
                          MAX(level1_global_be_category)
                                        │
                                        ▼
         dws_sr_data_warehouse_platform_user_item_category_1d
                  （分区：grass_region / local_date / operation）
```

### 关键步骤

1. **Statement 1 — 临时视图 `item_category_<region>`**
   从商品维度表 `dim_sr_data_warehouse_item` 中，按 `grass_region`、`local_date` 过滤当日当区域数据，进一步限定 `level1_global_be_category_id IN (100011, 100017)`（男装/女装）且 `item_id > 0`，获得有效商品的一级品类信息。

2. **Statement 2 — 临时视图 `dwm_user_item_<region>`**
   从用户行为中间层 `dwm_sr_data_warehouse_platform_user_item` 中，按 `grass_region`、`local_date` 过滤，并限定 `operation IN ('cart', 'order')`，获得当日当区域的加购与下单行为记录。

3. **Statement 3 — INSERT OVERWRITE 写目标表**
   将上述两个临时视图以 `item_id` 为键进行 INNER JOIN（仅保留品类匹配的行为记录），按 `(user_id, item_id, operation)` 分组，通过 `MAX` 聚合取品类 ID 和品类名称，以 `INSERT OVERWRITE` 动态分区方式写入目标表，分区键为 `grass_region`、`local_date`、`operation`。

### 注意事项

- **单一写入文件**：该表为单一 ETL 文件写入（`multi_writer=false`），无多文件并发写入风险。
- **`INSERT OVERWRITE` 分区覆盖**：每次执行会覆盖对应 `(grass_region, local_date)` 下所有 `operation` 分区的数据，重跑幂等，但需注意避免并发执行同一分区的任务。
- **动态分区写入**：`operation` 为动态分区字段，ETL 执行前需确认 Hive/Spark 动态分区配置开启（`hive.exec.dynamic.partition.mode=nonstrict`）。
- **INNER JOIN 过滤语义**：使用 INNER JOIN 而非 LEFT JOIN，意味着无法匹配到服装类目的行为记录将被丢弃，目标表仅包含有明确品类归属的用户行为。
- **`MAX` 聚合的语义**：在正常数据下，同一 `(item_id)` 对应唯一的 `level1_global_be_category_id` 和 `level1_global_be_category`，`MAX` 用于消除 JOIN 可能引入的重复行，并非真实意义上的最大值计算。

---

*文档生成时间：2026-05-18*