<!-- ads-workspace-gdoc-sync: gdoc_id=1l6h_uyfRgnCq5pUsCD9-vqfzqwb5FvZwbqIyTIkR5HY gdoc_url=https://docs.google.com/document/d/1l6h_uyfRgnCq5pUsCD9-vqfzqwb5FvZwbqIyTIkR5HY/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_winner_order_1d

**分层：** DWS（数据汇总层）
**主键：** `cspu_id` + `model_id` + `item_id` + `shop_id` + `grass_region` + `local_date`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE，按分区）
**访问频次：** 32 次

---

## 业务描述

本表为搜推数仓 **价格竞争力（Price Competitiveness / PB）** 场景下，以天为粒度的 **胜出款（Winner）订单聚合宽表**。

核心业务场景：

- 以 CSPU（标准商品单元）× 模型 × 商品 × 店铺为维度，汇总当天各组合的订单量；
- 关联 Winner 模型识别结果，标记当天该 model 是否属于"胜出款"（`is_win_day`），即是否命中 `business_type in (3, 4)` 的单变体模型分析规则；
- 支持分析胜出款商品在不同粒度（CSPU / 商品 / 店铺）维度上的订单表现，辅助价格竞争力策略评估与优化。

**适合回答的问题：**

- 某日某区域下，各 CSPU/商品/店铺的订单量是多少？
- 当天哪些模型属于 Winner？其订单贡献如何？
- Winner 模型与非 Winner 模型的订单量对比分析？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域（如 SG、MY 等），分区键，查询时必须指定 |
| `local_date` | date | 业务日期（本地日期），分区键，查询时必须指定 |

### 维度：商品与模型标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 标准商品单元 ID（Canonical SPU），商品归一化后的标准 ID |
| `model_id` | bigint | 模型 ID，对应 SKU 级别的价格竞争力分析模型 |
| `item_id` | bigint | 商品 ID（listing 级别） |
| `shop_id` | bigint | 店铺 ID |

### 指标：胜出状态与订单量

| 字段名 | 类型 | 说明 |
|---|---|---|
| `is_win_day` | int | 当天该 model 是否为胜出款：1 = 胜出（business_type in (3,4) 的单变体模型），0 = 非胜出；由 `max(if(...))` 聚合而来 |
| `order_cnt` | double | 当天该组合的订单量汇总，来源于小时级基础聚合表，缺失时补 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 均为分区字段，查询时必须同时指定，避免全表扫描。

```sql
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `is_win_day` | 标志位（0/1），跨行直接 SUM 无业务意义；需以 `MAX` 或 `COUNT(CASE WHEN ...)` 方式聚合 |
| `order_cnt` | 本表已按 `cspu_id + model_id + item_id + shop_id` 分组聚合，跨分区或跨维度 SUM 时需确认维度是否重叠，避免重复计数 |

### 时效性说明

- 本表为 **日粒度（`_1d`）** 汇总表，数据在每日 ETL 完成后可用；
- 数据来源小时级流量表（`dws_sr_data_warehouse_tc_pb_basic_aggr_1d`），依赖上游小时数据全量到齐后才产出，通常存在一定延迟；
- 不提供实时或准实时数据，不适合用于日内监控场景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 提供 CSPU × 模型 × 商品 × 店铺 × 小时的关联关系，作为驱动表（主表） |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 提供小时级别的模型订单量（`order_cnt`），过滤条件为 `mapping_general = '__ALL__'` |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 提供单变体模型分析结果，用于判断当天 model 是否属于 Winner（`business_type in (3,4)`） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf   （CSPU-模型关联主表）
        │
        ├── LEFT JOIN ──► dws_sr_data_warehouse_tc_pb_basic_aggr_1d  （小时订单量）
        │                  按 local_hour + model_id 关联
        │
        └── LEFT JOIN ──► dim_sr_data_warehouse_pb_one_variation_model_analysis_hf  （Winner模型）
                           按 model_id 关联
                                │
                                ▼
        dws_sr_data_warehouse_tc_pb_winner_order_1d  （按分区 INSERT OVERWRITE）
```

### 关键步骤

1. **Statement 1 — `all_cspu_model`（临时视图）**
   从 `dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` 按指定 `grass_region` 和 `local_date` 过滤，获取当天所有 CSPU × model × item × shop × 小时的关联关系，作为事实驱动主表。

2. **Statement 2 — `traffic_raw`（临时视图）**
   从 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d` 按 `grass_region`、`local_date` 及 `mapping_general = '__ALL__'` 过滤，按 `local_hour` + `model_id` 分组聚合订单量 `order_cnt`，得到小时级模型订单数据。

3. **Statement 3 — `winner`（临时视图）**
   从 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` 按 `grass_region`、`local_date` 过滤，并限定 `business_type in (3,4)`，获取当天所有 Winner model 的去重集合。

4. **Statement 4 — INSERT OVERWRITE（目标表写入）**
   以 `all_cspu_model` 为主表，依次 LEFT JOIN `traffic_raw`（按 `local_hour + model_id`）和 `winner`（按 `model_id`）；
   按 `cspu_id + model_id + item_id + shop_id` 分组聚合：
   - `is_win_day`：`max(if(c.model_id is not null, 1, 0))`，判断该 model 当天是否命中 Winner；
   - `order_cnt`：`coalesce(sum(order_cnt), 0)`，汇总订单量，无订单数据时补 0。
   结果按 `grass_region` + `local_date` 分区覆写目标表。

### 注意事项

- **单写入源**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 竞争风险。
- **分区级覆写**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 方式，每次执行仅覆盖指定分区，不影响其他分区历史数据。
- **参数化执行**：SQL 使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等运行时参数，实际执行时由调度系统注入；`grass_region_without_quote` 用于临时视图命名（避免引号语法问题），`grass_region` 用于分区过滤（带引号字符串）。
- **主表驱动**：以 `all_cspu_model`（CSPU-模型关联维表）为主表做 LEFT JOIN，可能导致 `order_cnt` 为 0 的行较多（即有关联关系但无订单的商品），分析时需注意过滤。
- **`mapping_general = '__ALL__'`**：上游订单量表按多种聚合口径存储，此处明确限定全量口径，避免指标重复统计。

---

*文档生成时间：2026-05-17*