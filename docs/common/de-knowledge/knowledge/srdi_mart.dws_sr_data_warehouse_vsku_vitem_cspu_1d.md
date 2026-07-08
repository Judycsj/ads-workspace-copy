<!-- ads-workspace-gdoc-sync: gdoc_id=1Ay94ZJ7ijm1CcPTtkLnjy505F9zGtse4a6OGB002RrM gdoc_url=https://docs.google.com/document/d/1Ay94ZJ7ijm1CcPTtkLnjy505F9zGtse4a6OGB002RrM/edit -->

# srdi_mart.dws_sr_data_warehouse_vsku_vitem_cspu_1d

**分层：** DWS（数据汇总层）
**主键：** `vitem_id` + `cspu_id` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日（T+1）
**访问频次：** 24,776 次

---

## 业务描述

本表用于汇总搜索推荐域（SRDI）中，**虚拟商品（vitem）× 内容标准商品单元（cspu）** 维度下的每日订单量数据。核心业务场景是将直播/视频场景下的 vsku 订单，通过 vitem-cspu-model 映射关系归因到具体的虚拟商品与内容 SPU 组合，为搜推效果评估、商品排序优化、内容电商 GMV 分析等提供基础汇总指标。

**适合回答的问题：**
- 某大区某天，特定 vitem 下各 cspu 的订单量是多少？
- 某 cspu 在各 vitem 中的成单分布如何？
- 搜推侧不同虚拟商品组合的日粒度成单效果对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 ID、TH 等，用于数据分区隔离 |
| `local_date` | date | 业务日期（本地日期），数据统计口径为自然日 |

### 维度：虚拟商品与内容标准商品单元

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品 ID（vsku item），标识直播/内容场景下的虚拟商品实体，与 `cspu_id` 联合唯一定位一条记录 |
| `cspu_id` | bigint | 内容标准商品单元 ID（Content SPU），标识归属的内容 SPU，由 vitem-model 映射关系推导而来 |

### 指标：订单量

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt_1d` | double | 当日订单量（订单分量累加值）。由上游 vsku 订单明细表中的 `order_fraction`（订单分量）按 `vitem_id` + `cspu_id` 聚合求和得出，代表该 vitem-cspu 组合在当日的成单贡献量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全分区扫描，造成严重性能问题及资源浪费。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-01-01'
  ```
- `grass_region` 的值需与目标大区保持一致（字符串类型，区分大小写）。

### 不可直接 SUM 的字段

- **`order_cnt_1d`**：虽然字段本身是 `double` 类型的加和指标，但其底层来源为 `order_fraction`（订单分量，非整数），**跨 `local_date` 多天累加**时需注意：
  - 本表仅存储单日数据（`_1d` 后缀），多日汇总需在应用层按日 SUM 后再聚合，不可直接对历史分区不加 `local_date` 过滤后 SUM。
  - 同一 `(vitem_id, cspu_id, grass_region, local_date)` 组合已在 ETL 层聚合完毕，业务层直接使用即可，无需再次 GROUP BY 去重。

### 时效性说明

- 本表为 **`_1d`（单日）** 汇总表，每日全量覆盖写入（`INSERT OVERWRITE`），反映的是 `local_date` 当天的快照数据。
- 上游来源包含半实时维表（`_hf` 后缀，高频更新），ETL 调度完成后数据生效，通常为 **T+1** 可查。
- 不适用于实时或小时级查询场景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | vitem-cspu-model 维度映射表（高频更新维表），提供 `vitem_id`、`cspu_id`、`model_id` 的对应关系，作为订单归因的关联键 |
| `mp_order.dwd_spu_vsku_order_item_df__reg_live` | vsku 订单明细宽表（按大区分流），提供 `spu_vsku_item_id`（即 vitem_id）、`model_id`、`order_fraction`（订单分量）字段，是订单量计算的来源 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_vsku_model_mapping_hf  ──┐
  (vitem-cspu-model 映射，按区域+日期过滤)      │  LEFT JOIN on model_id & vitem_id
                                               ├──► 按 vitem_id + cspu_id 聚合 SUM(order_fraction)
dwd_spu_vsku_order_item_df__reg_live  ─────────┘
  (vsku 订单明细，按区域+日期过滤，预聚合 order_fraction)

                        ▼
    dws_sr_data_warehouse_vsku_vitem_cspu_1d
    分区：grass_region + local_date（INSERT OVERWRITE）
```

### 关键步骤

1. **Statement 1 — 临时视图 `model_vitem_mapping_{region}`**
   - 从 vitem-cspu-model 维度映射表中，按 `grass_region` 和 `local_date` 过滤当天数据。
   - 按 `(vitem_id, cspu_id, model_id)` 去重聚合，处理同一 `model_id` 在一天内可能多次换绑 `cspu_id` 但 `vitem_id` 不变的边界场景。

2. **Statement 2 — 临时视图 `vsku_order_{region}`**
   - 从 vsku 订单明细表中，按 `grass_region` 和 `grass_date`（= `local_date`）过滤当天数据。
   - 按 `(spu_vsku_item_id, model_id)` 预聚合，计算每个 vitem-model 组合的订单分量之和（`order_cnt`）。

3. **Statement 3 — INSERT OVERWRITE 目标表**
   - 将 `model_vitem_mapping` 与 `vsku_order` 通过 `model_id` 和 `vitem_id`（= `spu_vsku_item_id`）进行 LEFT JOIN。
   - 使用 LEFT JOIN 确保即使无订单数据的 vitem-cspu 组合也被保留。
   - 按 `(vitem_id, cspu_id)` 聚合求和 `order_cnt`，写入目标表对应分区。
   - 以 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 方式全量覆盖写入，保证幂等性。

### 注意事项

- **单 writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无多文件并发写分区冲突风险。
- **分区写入模式**：采用 `INSERT OVERWRITE ... PARTITION(grass_region = ?, local_date = ?)` 的静态分区覆盖模式，重跑指定分区时安全幂等，不会影响其他大区或日期分区。
- **JOIN 键设计说明**：ETL 注释明确指出，JOIN 条件为 `model_id` + `vitem_id` 双键关联，原因是一个 rsku 可绑定同 cspu 下的多个 vmodel，而一个 rmodel 必然对应不同的 vitem，此约束由上游数据层保障，消费侧无需额外处理。
- **`order_fraction` 非整数**：`order_cnt_1d` 的来源为 `order_fraction`（订单分量），其值可能为小数，字段类型 `double` 符合预期，统计时需注意精度问题，不可强转为整型。
- **维表时效性**：上游维度映射表为高频更新（`_hf`）表，ETL 取的是 `local_date` 当天的快照，若维表更新时间晚于订单数据，可能存在极少数归因缺失的风险。

---

*文档生成时间：2026-05-17*