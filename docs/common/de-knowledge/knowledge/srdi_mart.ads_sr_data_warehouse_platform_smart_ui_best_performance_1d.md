<!-- ads-workspace-gdoc-sync: gdoc_id=1jDZPyp09JupFvZme8mmy170tGfThkkdG9pU1MGPCVX4 gdoc_url=https://docs.google.com/document/d/1jDZPyp09JupFvZme8mmy170tGfThkkdG9pU1MGPCVX4/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_smart_ui_best_performance_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `scenario_tag` + `item_id` + `image_id`
**分区：** `grass_region`（站点大区）、`local_date`（业务日期）、`scenario_tag`（场景标签）
**更新频率：** 每日一次（T+1）
**引用/访问频次：** 900 次

---

## 业务描述

本表为搜索平台「Smart UI」（智能封面图）功能的核心 ADS 层输出表，记录各站点每日维度下，**商品粒度 × 封面图粒度**的曝光、点击、成交等核心指标，并附带图片排名、最优封面标记及实验状态信息。

**核心业务场景：**

- **最优封面图评估**：通过 `is_best_image` 标识当日曝光量排名第一且满足 AB 实验条件的封面图，为 Smart UI 功能提供"最佳图片"结论。
- **封面图效果对比**：对同一商品的多张封面图（原始封面 vs. 推荐封面）进行曝光率（CTR）和曝光量排名对比，评估 Smart UI 优化效果。
- **30 日趋势分析**：提供图片级和商品级的近 30 天曝光、点击汇总及 CTR，支持中期效果趋势回顾。
- **实验覆盖度分析**：通过 `exp_status` 标识商品是否已满足双臂 AB 实验的最低曝光要求（各 ≥ 100 次），用于过滤有效实验样本。

**适合回答的典型问题：**

- 某站点某日，哪些商品的 Smart UI 推荐封面图效果最好？
- 原始封面与 AI 推荐封面的 CTR 差异是多少？
- 近 30 天内，某商品各封面图的曝光量和点击率排名如何变化？
- 哪些商品已积累足够的 AB 实验数据可以得出结论？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 SG、MY、TH 等），查询时必须指定 |
| `local_date` | date | 业务日期（当日），查询时必须指定 |
| `scenario_tag` | string | 场景标签，当前 ETL 固定写入值为 `'Global Search'`（全站搜索场景） |

### 维度：商品与图片标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 商品所属店铺 ID，来源于商品维表 |
| `image_id` | string | 封面图 ID，由商品维表 `images` 字段以逗号分割取第一张，或来自 Smart UI 推荐图片 |
| `is_origin_cover` | boolean | 是否为商品原始封面图（`true`：原始封面；`false`：Smart UI 推荐封面） |
| `is_best_image` | boolean | 是否为当日最优封面图：`exp_status = 1`（满足 AB 实验条件）且 `image_imp_rank_row_number = 1`（曝光量排名第一）时为 `true` |

### 维度：实验状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_status` | int | 商品 AB 实验状态。`1`：原始封面和推荐封面在近 180 天内各自曝光量均 ≥ 100 次，满足实验有效条件；`0`：不满足 |

### 指标：当日曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 当日该图片在搜索结果页的曝光次数 |
| `click_cnt` | bigint | 当日该图片的点击次数 |
| `image_ctr` | double | 当日图片点击率，计算公式：`click_cnt / imp_cnt`（`imp_cnt = 0` 时取 0） |

### 指标：当日成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 当日该图片带来的成交订单数 |
| `gmv` | double | 当日该图片带来的 GMV（成交金额） |

### 指标：图片曝光与 CTR 排名（当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_imp_rank_dense` | int | 同一商品下，按当日曝光量降序的 DENSE_RANK 排名（并列不跳号） |
| `image_imp_rank_row_number` | int | 同一商品下，按当日曝光量降序的 ROW_NUMBER 排名（曝光量相同时，CTR 高者优先，再按 `image_id` 降序打破平局） |
| `image_ctr_rank_dense` | int | 同一商品下，按当日 CTR 降序的 DENSE_RANK 排名（并列不跳号） |
| `image_ctr_rank_row_number` | int | 同一商品下，按当日 CTR 降序的 ROW_NUMBER 排名 |

### 指标：近 30 日图片级指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_30d` | bigint | 近 30 天（含当日）该图片的累计曝光次数 |
| `click_cnt_30d` | bigint | 近 30 天（含当日）该图片的累计点击次数 |
| `image_ctr_30d` | double | 近 30 天图片点击率，计算公式：`click_cnt_30d / imp_cnt_30d`（未做零除保护，`imp_cnt_30d = 0` 时可能为 NULL） |

### 指标：近 30 日商品级指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt_30d` | bigint | 近 30 天（含当日）该商品所有封面图的累计曝光次数（商品粒度汇总） |
| `item_click_cnt_30d` | bigint | 近 30 天（含当日）该商品所有封面图的累计点击次数（商品粒度汇总） |
| `item_ctr_30d` | double | 近 30 天商品整体点击率，计算公式：`item_click_cnt_30d / item_imp_cnt_30d`（未做零除保护） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，所有查询**必须同时指定**，否则将触发全表扫描，严重影响性能。
- `scenario_tag` 亦为分区字段，当前数据固定为 `'Global Search'`，建议查询时显式指定以裁剪分区。

### 不可直接 SUM 的字段

以下字段为**预计算比率或排名**，不可跨行直接 `SUM` 或 `AVG` 后作为汇总指标使用：

| 字段 | 原因 |
|---|---|
| `image_ctr` | 比率字段，应由 `SUM(click_cnt) / SUM(imp_cnt)` 重新计算 |
| `image_ctr_30d` | 比率字段，应由 `SUM(click_cnt_30d) / SUM(imp_cnt_30d)` 重新计算 |
| `item_ctr_30d` | 比率字段，应由 `SUM(item_click_cnt_30d) / SUM(item_imp_cnt_30d)` 重新计算 |
| `image_imp_rank_dense` | 窗口排名，跨行聚合无意义 |
| `image_imp_rank_row_number` | 窗口排名，跨行聚合无意义 |
| `image_ctr_rank_dense` | 窗口排名，跨行聚合无意义 |
| `image_ctr_rank_row_number` | 窗口排名，跨行聚合无意义 |
| `is_best_image` | 布尔标记，统计最优图数量应使用 `COUNT(IF(is_best_image, 1, NULL))` |
| `exp_status` | 枚举标记，统计有效实验商品数应使用 `COUNT(DISTINCT IF(exp_status=1, item_id, NULL))` |

### 零除风险

- `image_ctr_30d` 和 `item_ctr_30d` 在 ETL 中未做零除保护，当 `imp_cnt_30d` 或 `item_imp_cnt_30d` 为 0 时，字段值可能为 `NULL` 或 `Infinity`，使用时建议添加 `NULLIF` 保护。

### 时效性说明

- 本表为 **T+1** 日更新，`local_date` 代表当日业务日期。
- `*_30d` 字段为**滚动近 30 天**（`DATE_SUB(local_date, 29)` 至 `local_date`）预聚合结果，**不可**与其他日期分区的同名字段直接相加。
- `exp_status` 的计算依赖近 **180 天**历史数据，并非仅当日数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_smart_ui_metrics_1d` | Smart UI 搜索曝光/点击/成交明细指标，提供当日、近 30 天、近 180 天各时间窗口的图片级指标 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表，提供商品的 `shop_id` 及原始封面图 ID（`images` 字段首张图），用于关联 `is_origin_cover` 判断 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_item（当日）
        │
        ▼
dim_item（临时视图：item_id / image_id / shop_id）
        │
        ├─────────────────────────────────────────────────────────┐
        ▼                                                         ▼
dws_search_smart_ui_metrics_1d（当日）           dws_search_smart_ui_metrics_1d（近30天 / 近180天）
        │                                                         │
        ▼                                                         ▼
dws_smart_ui_1d（图片级当日汇总：                    smart_ui_180d（图片级180天曝光）
  imp/click/order/gmv/is_origin_cover）                          │
        │                                              dws_item_exp_status（商品实验状态）
        │                                                         │
        │                              dws_smart_ui_30d_image_level（图片级30天指标）
        │                              dws_smart_ui_30d_item_level（商品级30天指标）
        │                                                         │
        └──────────────────── JOIN ───────────────────────────────┘
                                   │
                          dws_item_image（最终宽表：含排名/CTR/最优标记）
                                   │
                                   ▼
        ads_sr_data_warehouse_platform_smart_ui_best_performance_1d
          PARTITION(grass_region, local_date, scenario_tag='Global Search')
```

### 关键步骤

1. **Step 1 — `dim_item`（临时视图）**
   从 `dim_sr_data_warehouse_item` 抽取当日商品的 `item_id`、原始封面图 `image_id`（`images` 字段逗号分割取第一张）和 `shop_id`，按 `(item_id, image_id, shop_id)` 去重。

2. **Step 2 — `dws_smart_ui_1d`（临时视图）**
   从 `dws_sr_data_warehouse_search_smart_ui_metrics_1d` 获取当日（`local_date`）、`target_type = 'item'` 的图片级曝光/点击/成交数据，LEFT JOIN `dim_item` 获取 `shop_id`，并通过二次 LEFT JOIN `dim_item` 判断当前图片是否为原始封面（`is_origin_cover`）。按 `(item_id, image_id)` 分组汇总。

3. **Step 3 — `smart_ui_1d_item_id`（临时视图）**
   从 `dws_smart_ui_1d` 提取当日有数据的 `item_id` 集合，用于后续商品级 30 天指标的 JOIN 过滤。

4. **Step 4 — `smart_ui_180d`（临时视图）**
   回溯近 180 天（`DATE_SUB(local_date, 179)` 至 `local_date`），与 `dws_smart_ui_1d` INNER JOIN 限定范围，按 `(item_id, image_id)` 汇总近 180 天图片曝光量，同时携带 `is_origin_cover` 信息。

5. **Step 5 — `dws_item_exp_status`（临时视图）**
   基于 `smart_ui_180d`，按 `item_id` 聚合：若原始封面 180 天曝光 ≥ 100 且非原始封面 180 天曝光 ≥ 100，则 `exp_status = 1`，否则为 `0`。

6. **Step 6 — `dws_smart_ui_30d_image_level_metrics`（临时视图）**
   回溯近 30 天，INNER JOIN `dws_smart_ui_1d` 限定范围，按 `(item_id, image_id)` 汇总 `imp_cnt_30d`、`click_cnt_30d`。

7. **Step 7 — `dws_smart_ui_30d_item_level_metrics`（临时视图）**
   回溯近 30 天，INNER JOIN `smart_ui_1d_item_id` 限定商品范围，按 `item_id` 汇总 `item_imp_cnt_30d`、`item_click_cnt_30d`。

8. **Step 8 — `dws_item_image`（最终宽表临时视图）**
   将上述所有临时视图 JOIN 汇总，计算：
   - `image_ctr`（当日 CTR）
   - `image_ctr_30d`（30 日 CTR）
   - `item_ctr_30d`（30 日商品 CTR）
   - 四个窗口排名字段（DENSE_RANK / ROW_NUMBER × 曝光维度 / CTR 维度）

9. **Step 9 — INSERT OVERWRITE（目标写入）**
   从 `dws_item_image` 读取全部字段，计算 `is_best_image`（`exp_status = 1 AND image_imp_rank_row_number = 1`），固定 `scenario_tag = 'Global Search'`，以 `INSERT OVERWRITE … PARTITION(grass_region, local_date, scenario_tag)` 方式写入目标表。

### 注意事项

- **单一写入者**：本表仅有 1 个 ETL 文件，无多文件并发写入风险。
- **分区覆盖写入**：使用 `INSERT OVERWRITE … PARTITION` 模式，每次执行将完全覆盖指定 `(grass_region, local_date)` 分区下的数据，重跑安全。
- **参数化站点**：ETL 通过 `${grass_region}` / `${grass_region_without_quote}` / `${local_date}` 参数化执行，每个站点独立运行，不同站点数据互不影响。
- **零除风险**：`image_ctr_30d` 和 `item_ctr_30d` 在 ETL 中直接做除法，未加 `NULLIF` 或 `IF(imp_cnt > 0, ...)` 保护，若上游数据存在曝光为 0 的记录，可能产生 NULL 或异常值。
- **180 天数据依赖**：`exp_status` 依赖近 180 天数据，历史数据不完整时（如新上线站点）可能导致大量商品 `exp_status = 0`，影响 `is_best_image` 的覆盖率。
- **COALESCE NULL 处理**：JOIN 条件统一使用 `COALESCE(field, sentinel)` 处理 NULL，确保 NULL 值可以正确参与等值 JOIN，避免 NULL != NULL 导致的数据丢失。

---

*文档生成时间：2026-05-17*