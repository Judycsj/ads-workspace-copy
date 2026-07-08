<!-- ads-workspace-gdoc-sync: gdoc_id=1-RU7KQdSOr1W8yWdc6AbmRtjzJnONW7sjiD_SYC_DWY gdoc_url=https://docs.google.com/document/d/1-RU7KQdSOr1W8yWdc6AbmRtjzJnONW7sjiD_SYC_DWY/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_model_day_level_analysis_1d

**分层：** DWS（数据汇总层）
**主键：** `cspu_id` + `model_id` + `item_id` + `shop_id` + `mapping_general` + `shop_scs_type`（在分区内唯一）
**分区：** `grass_region`（站点/区域）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE，按分区）
**引用频次/访问频次：** 362

---

## 业务描述

本表为搜推数仓（SRDI）**推荐业务（PB）单规格商品（One Variation）模型日粒度分析表**，面向 TC（Top Category / 全类目）场景。

核心业务场景：
- 以 **模型（model）** 为核心分析单元，将小时级别数据（`_hour_level_` 上游表）向上聚合为**日粒度**指标，支持按天对推荐模型的曝光、订单、GMV 等核心电商指标进行分析。
- 覆盖单规格商品（One Variation）在推荐场景下的**模型维度性能表现**，可关联 Buybox、店铺类型（SCS）、模型业务类型等维度。
- 支持跨站点（`grass_region`）的日级别推荐效果横向对比。

适合回答的问题：
- 某站点某天，某模型（model_id）的曝光量、订单量、GMV 是多少？
- 同一 CSPU 下各 item 在不同店铺的推荐效果如何？
- Buybox 商品与非 Buybox 商品的推荐表现差异？
- 某模型对应哪些业务类型（model_type）和 CSPU 类型（cspu_type）？
- 某 CSPU 近 1 天（L1D）的订单量（cspu_l1d_order_cnt）情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `MY`、`TH`、`ID` 等，每次写入按该分区覆盖 |
| `local_date` | date | 业务日期（当地日期），数据所属的自然日 |

### 维度：商品与模型标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（Catalog SPU）ID，商品目录层面的标准商品单元标识 |
| `model_id` | bigint | 推荐模型 ID，用于标识具体的推荐模型实体 |
| `item_id` | bigint | 商品 Item ID，SKU/Listing 级别的商品标识 |
| `shop_id` | bigint | 店铺 ID |

### 维度：商品与店铺属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 商品通用映射标识，用于商品关联/映射分类 |
| `shop_scs_type` | string | 店铺 SCS（Service & Commitment Standard）类型，如 Mall、CB 等 |
| `model_type` | array\<int\> | 模型所属业务类型集合，由小时数据中的 `business_type` 聚合（`collect_set`）去重得到 |
| `cspu_type` | array\<double\> | CSPU 类型集合，由小时级数据的 `cspu_type` 数组展平后去重（`array_distinct(flatten(collect_list(...)))`）得到 |
| `is_buybox` | int | 是否为 Buybox 商品，取当日最大值（`max`）；通常 1=是，0=否 |

### 指标：曝光指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt` | bigint | 商品曝光次数（含推荐干预后），由小时数据按日汇总（`sum`） |
| `item_org_imp_cnt` | bigint | 商品原始曝光次数（推荐干预前/自然曝光），由小时数据按日汇总（`sum`） |

### 指标：订单指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_order_cnt` | double | 模型带来的订单数（含推荐），由小时数据按日汇总（`sum`） |
| `model_org_order_cnt` | double | 模型对应的原始订单数（自然/对照），由小时数据按日汇总（`sum`） |
| `cspu_l1d_order_cnt` | double | CSPU 近 1 天（L1D，Last 1 Day）订单量，取小时粒度数据中的最大值（`max`），代表当日最新快照值 |

### 指标：GMV 指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_gmv` | double | 模型带来的 GMV（美元或标准货币），由小时数据按日汇总（`sum`） |
| `model_org_gmv` | double | 模型对应的原始 GMV（自然/对照，标准货币），由小时数据按日汇总（`sum`） |
| `model_gmv_local` | double | 模型带来的 GMV（本地货币），由小时数据按日汇总（`sum`） |
| `model_org_gmv_local` | double | 模型对应的原始 GMV（本地货币），由小时数据按日汇总（`sum`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定站点分区，否则将触发全分区扫描，严重影响查询性能。
- **`local_date`**：必须指定业务日期分区，避免全量扫描。建议同时使用两个分区字段过滤。

```sql
-- 正确示例
WHERE grass_region = 'MY'
  AND local_date = '2025-05-16'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `cspu_l1d_order_cnt` | 由 `max` 聚合计算得到，代表 CSPU 近 1 天订单量的快照值，跨行 SUM 会重复计算 |
| `is_buybox` | 由 `max` 聚合计算得到，为状态标识字段，不具有加和语义 |
| `model_type` | Array 类型，需使用数组函数（如 `array_contains`）进行筛选，不可直接聚合 |
| `cspu_type` | Array 类型，已在 ETL 中展平去重，不可直接 SUM，跨行合并需使用 `flatten` + `array_distinct` |

### 时效性说明

- 本表为 **`_1d` 后缀日粒度表**，数据更新频率为每日一次，通常反映 T-1 日的完整数据。
- 数据来源于小时级表（`_hour_level_analysis_1d`）的日内汇总，数据完整性依赖上游小时表当天所有分区就绪。
- `cspu_l1d_order_cnt` 中的"L1D"窗口含义来自上游小时表，本表直接取 `max` 透传，**不代表本表所在日期的当日订单**，请结合业务定义使用。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_model_hour_level_analysis_1d` | 小时粒度推荐模型分析数据，经 `sum`/`max`/`collect_set`/`flatten` 等聚合后汇总为日粒度写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_model_hour_level_analysis_1d
    （小时级模型分析数据，按 grass_region + local_date 过滤）
        │
        │  group by cspu_id, model_id, item_id, shop_id, mapping_general, shop_scs_type
        │  sum(曝光/订单/GMV 指标)
        │  collect_set(business_type) → model_type
        │  array_distinct(flatten(collect_list(cspu_type))) → cspu_type
        │  max(cspu_l1d_order_cnt), max(is_buybox)
        ▼
srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_model_day_level_analysis_1d
    PARTITION (grass_region, local_date)
```

### 关键步骤

1. **数据读取与过滤**：从上游小时级表中按 `grass_region` 和 `local_date` 两个分区条件过滤当日当站点数据。
2. **维度分组**：按 `cspu_id`、`model_id`、`item_id`、`shop_id`、`mapping_general`、`shop_scs_type` 六个维度字段进行分组。
3. **指标聚合**：
   - 曝光/订单/GMV 类指标：`sum` 累加小时数据。
   - `model_type`：对 `business_type` 执行 `collect_set` 去重收集，输出 `array<int>`。
   - `cspu_type`：对各小时 `cspu_type` 数组执行 `collect_list` → `flatten` → `array_distinct`，输出去重后的 `array<double>`。
   - `cspu_l1d_order_cnt` 与 `is_buybox`：取 `max` 取最大值/最新状态。
4. **分区写入**：以 `INSERT OVERWRITE ... PARTITION (grass_region, local_date)` 方式覆盖写入目标分区，保证幂等性。

### 注意事项

- **单一 writer**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 并发写入风险。
- **分区覆盖**：每次执行为动态分区 OVERWRITE，重跑同一 `grass_region` + `local_date` 分区时会完整覆盖历史数据，具有幂等性，重跑安全。
- **上游依赖完整性**：由于本表为小时数据的日汇总，若上游小时表当天存在数据缺失或延迟，日聚合结果将偏低，需关注上游数据质量。
- **Array 字段的计算开销**：`cspu_type` 字段使用了 `flatten` + `array_distinct` + `collect_list` 的组合操作，数据量大时对 Spark 执行有一定性能压力，查询时建议避免对该字段做复杂展开操作。

---

*文档生成时间：2026-05-17*