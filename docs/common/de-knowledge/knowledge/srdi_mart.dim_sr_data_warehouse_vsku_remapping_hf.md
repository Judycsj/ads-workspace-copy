<!-- ads-workspace-gdoc-sync: gdoc_id=1dY-Lrh93W0zhUHdlkKh1-jvLf9gCj0DOxchkEMGDXdo gdoc_url=https://docs.google.com/document/d/1dY-Lrh93W0zhUHdlkKh1-jvLf9gCj0DOxchkEMGDXdo/edit -->

# srdi_mart.dim_sr_data_warehouse_vsku_remapping_hf

**分层**：DIM（维度层）
**主键**：`cspu_id` + `mapping_type` + `grass_region` + `regional_date` + `regional_hour`
**分区**：`grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率**：小时级（hf = hourly frequency）
**引用/访问频次**：5353 次

---

## 业务描述

本表为搜推数仓中 **vSKU（虚拟 SKU）重映射维度表**，核心功能是建立 CSPU（商品标准单元）与 vItem（虚拟商品）之间的映射关系，并按映射来源类型加以区分。

该表支持以下两类映射场景：

| `mapping_type` | 含义 | 来源 |
|---|---|---|
| `1` | **直接映射**：CSPU 自身在 vSKU-Model 映射表中存在直接的 vItem 对应关系 | `dim_sr_data_warehouse_vsku_model_mapping_hf` |
| `0` | **间接映射（补全映射）**：CSPU 不在直接映射表中，但其关联的 CSPU 存在 vItem 映射，通过 CSPU 维度补全 | `dwd_sr_data_warehouse_pb_all_cspu_link_hf` left join 补全 |

**典型业务场景**：
- 搜推系统中，对尚未建立 vSKU 直接映射的商品，通过 CSPU 聚合关联找到对应的虚拟 SKU，保证召回覆盖率。
- 分析 vSKU 的生长周期（`vsku_grow_period`）、发布日期（`vsku_publish_local_date`）与销售表现（`vsku_order_cnt_nd`）。
- 支持商品模型（`model_id`）到虚拟商品（`vitem_id`）的全链路追踪。

**适合回答的问题**：
- 某区域某小时内，哪些 CSPU 可以映射到哪些 vItem？映射方式是直接还是间接？
- 某 vItem 的近 N 天订单量（`vsku_order_cnt_nd`）是多少？
- 某店铺（`shop_id`）下商品（`item_id`）对应的 vSKU 覆盖情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `ID`、`TH` 等，ETL 按该字段分区写入，**查询必须指定** |
| `local_date` | date | 本地日期（商品所在站点本地时区），来源于上游表 |
| `local_hour` | int | 本地小时（0–23），与 `local_date` 共同定位小时分区 |
| `regional_date` | date | 区域日期（统一区域时区），ETL 过滤与写入的基准日期分区，**查询必须指定** |
| `regional_hour` | int | 区域小时（0–23），与 `regional_date` 共同定位小时分区，**查询必须指定** |

### 维度：映射标识与类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_type` | int | 映射类型：`1` = 直接映射（来自 vSKU-Model 映射表），`0` = 间接补全映射（通过 CSPU 关联补全） |
| `cspu_id` | bigint | CSPU ID，商品标准单元标识，映射关系的主体 |
| `model_id` | bigint | 商品模型 ID，CSPU 所属模型，直接映射时来自 vSKU-Model 映射表，间接映射时来自全量 CSPU 链路表 |
| `item_id` | bigint | 商品 ID（listing 级别），直接映射时来自 vSKU-Model 映射表，间接映射时来自全量 CSPU 链路表 |
| `shop_id` | bigint | 店铺 ID，直接映射时来自 vSKU-Model 映射表，间接映射时来自全量 CSPU 链路表 |

### 维度：vSKU 信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品 ID（vItem），映射目标，间接映射时可能为 NULL（若 CSPU 无法匹配任何 vItem） |
| `vsku_grow_period` | int | vSKU 生长周期（枚举值），表示 vSKU 所处的成长阶段 |
| `vsku_publish_local_date` | date | vSKU 首次发布的本地日期 |

### 指标：vSKU 销售表现

| 字段 | 类型 | 说明 |
|---|---|---|
| `vsku_order_cnt_nd` | double | vSKU 近 N 天订单量（滑动窗口预聚合值），用于间接映射时按此指标降序取最优 vItem（`row_number() over ... order by vsku_order_cnt_nd desc`） |

---

## 查询使用须知

### 必须包含的过滤条件

```sql
-- 查询时必须同时指定以下分区字段，避免全表扫描：
WHERE grass_region = 'XX'
  AND regional_date = '2024-01-01'
  AND regional_hour = 0
```

- `grass_region`、`regional_date`、`regional_hour` 为核心分区过滤字段，**缺少任意一个都会引发全分区扫描**，影响性能及成本。
- 如需按本地时区过滤，可额外加 `local_date` 和 `local_hour`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `vsku_order_cnt_nd` | 近 N 天滑动窗口预聚合值，跨行直接 SUM 会造成重复计算；如需汇总，需先按 `vitem_id` 去重后取值 |

### 映射类型过滤注意事项

- 同一 `cspu_id` 在同一分区内可能同时存在 `mapping_type=1` 和 `mapping_type=0` 两条记录，若只需直接映射结果，需过滤 `mapping_type = 1`。
- 间接映射（`mapping_type=0`）记录中，`vitem_id` 可能为 NULL（CSPU 无法找到对应 vItem 时）。

### 时效性说明

- 表为**小时级更新**（hf），每小时覆盖写入对应 `regional_date` + `regional_hour` 分区。
- `vsku_order_cnt_nd` 字段为上游预计算的近 N 天窗口指标，当前快照值仅代表写入时刻的统计结果，不随查询时间动态变化。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_all_cspu_link_hf` | 提供全量 CSPU 链路信息（`cspu_id`、`model_id`、`item_id`、`shop_id` 等），作为间接映射的 CSPU 底表 |
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | 提供 vSKU 与 Model/CSPU 的直接映射关系及 vSKU 属性（`vitem_id`、`vsku_grow_period`、`vsku_publish_local_date`、`vsku_order_cnt_nd`），同时用于直接映射写入和间接映射的 vItem 补全 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_pb_all_cspu_link_hf  ──────────────────────────────┐
                                                                          ▼
dim_sr_data_warehouse_vsku_model_mapping_hf ──► [去重+取最优vItem] ──► UNION ALL ──► dim_sr_data_warehouse_vsku_remapping_hf
                                          └──────────────────────────────────────► (直接映射, mapping_type=1)
                                                                          ▲
                                                    (间接映射, mapping_type=0)
```

### 关键步骤

**Step 1 — Temporary View `all_cspu_${grass_region_without_quote}`**

从 `dwd_sr_data_warehouse_pb_all_cspu_link_hf` 按 `grass_region`、`regional_date`、`regional_hour` 过滤，获取当前分区下的全量 CSPU 链路数据。

**Step 2 — Temporary View `vsku_rmodel_mapping_${grass_region_without_quote}`**

从 `dim_sr_data_warehouse_vsku_model_mapping_hf` 按相同分区条件过滤，获取当前分区下的 vSKU-Model 直接映射数据。

**Step 3 — Temporary View `cspu_with_vitem_${grass_region_without_quote}`**

对 vSKU-Model 映射数据按 `cspu_id` 分组，通过 `ROW_NUMBER() OVER (PARTITION BY cspu_id ORDER BY vsku_order_cnt_nd DESC)` 为每个 CSPU 选取近 N 天订单量最高的 vItem，保留 `rn=1` 的行，得到每个 CSPU 对应的最优 vItem 映射。

**Step 4 — INSERT OVERWRITE（目标表写入）**

执行 `INSERT OVERWRITE TABLE ... PARTITION(grass_region, local_date, local_hour, regional_date, regional_hour)`，通过 UNION ALL 合并两路数据：

- **Branch 1（直接映射，`mapping_type=1`）**：直接将 `vsku_rmodel_mapping` 视图的全量数据写入，`mapping_type` 固定为 `1`。
- **Branch 2（间接映射，`mapping_type=0`）**：将全量 CSPU（`all_cspu`）Left Join `cspu_with_vitem`（按 `cspu_id`）补全 vItem 信息，再 Left Join `vsku_rmodel_mapping`（按 `model_id`）过滤掉已存在直接映射的 CSPU（`c.model_id IS NULL`），`mapping_type` 固定为 `0`。

### 注意事项

1. **单一写入文件，无 multi-writer 风险**：该表由单个 ETL 文件写入，无并发写冲突。
2. **分区覆盖写入（INSERT OVERWRITE）**：每次执行会覆盖对应 `grass_region` + `regional_date` + `regional_hour` 分区，历史分区数据保持不变。
3. **间接映射过滤逻辑存在已知风险**：ETL 注释中明确指出 `c.model_id IS NULL` 的 join key（`model_id`）"已经不够用了"，即通过 `model_id` 排除直接映射的逻辑可能存在遗漏，实际写入的间接映射数据可能包含本应被排除的记录，需关注上游数据变更对该逻辑的影响。
4. **参数化执行**：ETL 使用 `${grass_region}`、`${grass_region_without_quote}`、`${regional_date}`、`${regional_hour}`、`${schema}` 等参数，按 `grass_region` 分批执行，每次写入特定站点分区。
5. **`vsku_order_cnt_nd` 去重逻辑**：Step 3 对 vSKU-Model 映射表先做 `GROUP BY` 去重再做 `ROW_NUMBER` 排序，若上游存在重复记录，去重后取最优值，结果唯一。

---

*文档生成时间：2026-05-17*