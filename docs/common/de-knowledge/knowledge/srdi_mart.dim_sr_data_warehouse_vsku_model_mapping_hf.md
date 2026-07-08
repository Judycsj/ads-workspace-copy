<!-- ads-workspace-gdoc-sync: gdoc_id=1z3_lHU5SxzHEutH3sY44gxvLk0-8lKxNBpZ46NYobSM gdoc_url=https://docs.google.com/document/d/1z3_lHU5SxzHEutH3sY44gxvLk0-8lKxNBpZ46NYobSM/edit -->

# srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf

**分层：** DIM（维度层）
**主键：** `grass_region` + `vitem_id`（业务上，一个 rmodel 对应不同的 vitem；完整分区内以 `cspu_id + model_id + vitem_id` 唯一标识映射关系）
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`（五分区联合，小时级快照）
**更新频率：** 小时级（hf = hourly frequency）
**引用/访问频次：** 68,030 次

---

## 业务描述

本表记录搜推数仓中 **虚拟 SKU（vSKU）与真实商品体系（rSKU）之间的模型映射关系**，是搜推体系中打通虚拟商品与真实商品的核心维度表。

每一行表示：在某一地区（`grass_region`）、某一小时快照时刻，一个真实商品（`cspu_id / model_id / item_id / shop_id`）与虚拟商品（`vmodel_id / vitem_id / vshop_id`）之间的有效绑定关系，并附带 vSKU 的生命周期阶段和近期订单量指标，用于支撑搜推策略的分层运营。

**核心业务场景：**
- 搜推召回/排序时，通过 vitem 维度关联真实商品链路
- 基于 vSKU 发布时长（`vsku_grow_period`）进行新品/成长期/成熟期分层运营
- 过滤测试商品（live test vitem），保证线上数据质量
- 支持多区域（PH、TH、SG 等）时区转换后的本地时间对齐

**适合回答的问题：**
- 某 vitem 当前绑定的真实 model/item/shop 是什么？
- 某 cspu 下有哪些 vSKU 处于新品期（grow_period=1）？
- 当前小时快照中，哪些 vitem 近 N 天订单量为 0？
- 某地区的 rSKU ↔ vSKU 映射关系全量是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `SG`、`PH`、`TH` 等 |
| `local_date` | date | 当地时区日期，由新加坡时间（regional_date/regional_hour）经时区转换得到 |
| `local_hour` | int | 当地时区小时，由新加坡时间经时区转换得到 |
| `regional_date` | date | 新加坡时区（SG）基准日期，即调度时的 regional_date 参数 |
| `regional_hour` | int | 新加坡时区（SG）基准小时，即调度时的 regional_hour 参数 |

### 维度：真实商品（rSKU）标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 跨店标准商品单元 ID（Cross-shop SPU），真实商品聚合层级 |
| `model_id` | bigint | 真实商品的 model ID（rModel），对应 Shopee 平台商品规格层 |
| `item_id` | bigint | 真实商品的 item ID（rItem） |
| `shop_id` | bigint | 真实商品归属的店铺 ID |

### 维度：虚拟商品（vSKU）标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `vmodel_id` | bigint | 虚拟商品的 vModel ID，与 rModel 存在绑定关系；一个 rModel 对应的多个 vmodel_id 必属于不同 vitem |
| `vitem_id` | bigint | 虚拟商品的 vItem ID，搜推体系核心操作粒度 |
| `vshop_id` | bigint | 虚拟商品归属的虚拟店铺 ID |

### 维度：vSKU 生命周期属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `vsku_publish_local_date` | date | vSKU 在当地时区的发布日期，来源于 `dim_sr_data_warehouse_vsku_vitem.publish_local_date` |
| `vsku_grow_period` | int | vSKU 成长阶段：`1`=新品期（发布≤14天）；`2`=成长期（15~28天）；`3`=成熟期（>28天）；发布日期为空时默认计为 1 天（新品） |

### 指标：vSKU 近期销售

| 字段 | 类型 | 说明 |
|---|---|---|
| `vsku_order_cnt_nd` | double | vSKU 近 N 天订单量，来源于 `dws_sr_data_warehouse_vsku_vitem_nd.order_cnt_nd`；上游无数据时补 0（`coalesce(..., 0)`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须同时指定** `grass_region`、`regional_date`、`regional_hour`（或等价的 `local_date` + `local_hour`），避免全表扫描。推荐写法：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-05-17'
    AND regional_hour = 10
  ```
- 如需取**最新快照**，应配合 `max_pt` 或调度最新分区值过滤，不可直接 `MAX(local_date)` 跨全表聚合。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `vsku_order_cnt_nd` | 近 N 天滑动窗口预聚合指标，已在上游 dws 层聚合，直接 SUM 会导致重复计数 |
| `vsku_grow_period` | 分类枚举值（1/2/3），对其求和无业务意义 |
| `local_date` / `local_hour` / `regional_date` / `regional_hour` | 分区时间字段，仅用于过滤，不参与度量计算 |

### 时效性说明

- 本表为**小时级快照表**（`_hf` 后缀），每小时覆盖写入（`INSERT OVERWRITE`）对应分区。
- `vsku_order_cnt_nd` 中的 `nd` 表示**近 N 天滑动窗口**，具体天数由上游 `dws_sr_data_warehouse_vsku_vitem_nd` 定义，本表不做额外定义，使用时需确认上游 N 的取值。
- 上游 tag 和 metrics 数据取的是 `local_date < regional_date` 的最新分区，存在**最多 1 天的数据延迟**。

### 其他注意事项

- `vsku_grow_period = 1` 含义包含两种情况：真实新品（发布≤14天）**以及** `publish_local_date` 为 NULL 的记录（默认视作第 1 天），使用时需留意。
- 本表已在 ETL 中剔除 PH、TH 站点的指定 live test vitem，线上使用无需二次过滤。
- 一个 rModel（`model_id`）可绑定同一 cspu 下多个 vmodel，但这些 vmodel 必属于不同的 vitem（ETL 层已做限制）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.srdi_mart.ods_sr_data_warehouse_vsku_model_mapping` | 主体映射关系来源，提供 cspu_id、model_id、item_id、shop_id、vmodel_id、vitem_id、vshop_id；仅取 `status=1` 的有效记录，并剔除 live test vitem |
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 提供 vitem 维度的本地发布日期（`publish_local_date`），用于计算 vSKU 发布天数和成长阶段 |
| `srdi_mart.dws_sr_data_warehouse_vsku_vitem_nd` | 提供 vitem 粒度的近 N 天订单量（`order_cnt_nd`），即 `vsku_order_cnt_nd` |

---

## ETL 逻辑摘要

### 数据流

```
paimon.srdi_mart.ods_sr_data_warehouse_vsku_model_mapping  ──┐
                                                              ├─► (LEFT JOIN on vitem_id) ─► INSERT OVERWRITE
srdi_mart.dim_sr_data_warehouse_vsku_vitem ────────────────┐ │   dim_sr_data_warehouse_vsku_model_mapping_hf
                                                           └─┤
srdi_mart.dws_sr_data_warehouse_vsku_vitem_nd ─────────────┘
```

### 关键步骤

1. **Statement 1 — `vsku_tag` 临时视图**
   从 `dim_sr_data_warehouse_vsku_vitem` 取当前区域、最新可用分区（`local_date < regional_date`）的 vitem 发布日期（`publish_local_date`）。

2. **Statement 2 — `vsku_metrics` 临时视图**
   从 `dws_sr_data_warehouse_vsku_vitem_nd` 取当前区域、最新可用分区（`local_date < regional_date`）的近 N 天订单量（`order_cnt_nd`）。

3. **Statement 3 — `vsku_rmodel_mapping` 临时视图**
   从 Paimon ODS 表读取状态有效（`status=1`）的 rSKU ↔ vSKU 映射关系，并按区域剔除 live test vitem（PH/TH 各有固定排除列表）。

4. **Statement 4 — INSERT OVERWRITE 目标表**
   以 `vsku_rmodel_mapping` 为主表，依次 LEFT JOIN `vsku_tag`（获取发布日期）和 `vsku_metrics`（获取订单量），计算：
   - `vsku_publish_days`：当地当前时间与发布日期的天数差（发布日期为 NULL 时补 1）
   - `vsku_grow_period`：依据 `vsku_publish_days` 分 3 档
   - `vsku_order_cnt_nd`：`coalesce(vsku_order_cnt_nd, 0)` 补零
   - `local_date` / `local_hour`：通过 `date_timezone_convert` 将 SG 基准时间转换为目标区域本地时间
   - 写入目标表对应分区（`grass_region` + `local_date` + `local_hour` + `regional_date` + `regional_hour`）

### 注意事项

- **单写入器（multi_writer=false）**：仅一个 ETL 文件写入本表，不存在多 writer 并发冲突风险。
- **INSERT OVERWRITE 分区写入**：每次执行覆盖单个五元组分区，历史分区不受影响，可安全重跑。
- **Paimon ODS 表**：`vsku_rmodel_mapping` 来源于 Paimon 格式表，需确认 Spark 读取时 Paimon Catalog 配置正确。
- **时区转换依赖**：`date_timezone_convert` 为自定义 UDF，`local_date` / `local_hour` 分区值完全依赖该函数正确性，若 UDF 版本变更需回归验证。
- **上游分区延迟**：tag 和 metrics 两个临时视图均取 `local_date < regional_date` 的最新分区，若上游当日分区未就绪不会阻塞写入，但数据会滞后一天。

---

*文档生成时间：2026-05-17*