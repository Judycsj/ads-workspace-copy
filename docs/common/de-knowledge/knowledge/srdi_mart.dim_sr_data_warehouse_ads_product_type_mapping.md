<!-- ads-workspace-gdoc-sync: gdoc_id=1eQgwzwXhJhcB5AqGVEFQTBq742OGHTF7AGjCDczHxyU gdoc_url=https://docs.google.com/document/d/1eQgwzwXhJhcB5AqGVEFQTBq742OGHTF7AGjCDczHxyU/edit -->

# srdi_mart.dim_sr_data_warehouse_ads_product_type_mapping

**分层：** DIM（维度层）
**主键：** `pricing_type`, `placement`, `sub_product_type`, `product_type`, `main_product_type`（联合唯一）
**分区：** `local_date`（日期分区）
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次：** 295 次

---

## 业务描述

本表为搜推数仓（SRDI）广告产品类型映射维度表，维护广告投放的产品类型层级结构与定价/投放位置的对应关系。

**核心业务场景：**
- 提供广告产品类型的标准分类体系（主产品类型 → 产品类型 → 子产品类型三级层级），供下游事实表和报表层进行维度关联。
- 将广告的 `pricing_type`（定价类型）与 `placement`（投放位置）映射到对应的产品类型，支持广告效果分析、费用归因及产品维度下钻。
- 作为公共维度被搜推业务多个 ADS/MART 层表 JOIN 使用，确保产品类型口径统一。

**适合回答的问题：**
- 某 `pricing_type` + `placement` 组合对应的产品类型是什么？
- 各主产品类型下包含哪些子产品类型？
- 广告报表按产品类型分组时，如何完成编码到名称的转换？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `local_date` | date | 数据分区日期，格式 `yyyy-MM-dd`，每日全量刷新 |

### 维度：产品类型层级

| 字段 | 类型 | 说明 |
|------|------|------|
| `main_product_type` | string | 主产品类型，产品分类最高层级（如搜索广告、展示广告等） |
| `product_type` | string | 产品类型，介于主类型与子类型之间的中间层级 |
| `sub_product_type` | string | 子产品类型，产品分类最细粒度 |

### 维度：广告投放属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `pricing_type` | int | 定价类型编码，标识广告的计费方式（如 CPC、CPM 等），来源于上游枚举值并转换为整型 |
| `placement` | int | 投放位置编码，标识广告展示的位置，来源于上游枚举值并转换为整型 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必指定 `local_date` 分区**，避免全表扫描。推荐使用当日或最新业务日期：
  ```sql
  WHERE local_date = '2026-05-17'
  ```
- 本表为维度映射表，通常以 `pricing_type` + `placement` 或产品类型字段作为 JOIN 条件关联事实表，JOIN 时同样需携带 `local_date` 过滤。

### 不可直接 SUM 的字段

本表为纯维度映射表，**不包含任何度量/指标字段**，所有字段均为描述性维度属性，不应对任何字段执行 SUM、AVG 等聚合运算。

### 时效性说明

- 数据每日全量覆写，反映上游 `mp_paidads.dim_product_type_mapping__reg_s0_live` 当日状态。
- 表为静态映射关系，若产品类型枚举未发生变更，历史分区与最新分区内容一致；建议下游始终使用最新分区以保证口径一致。
- 上游表后缀 `_live` 表示为近实时数据源，本表落库后即为 T+0 日维度快照。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 提供广告产品类型映射的原始枚举数据，包含定价类型、投放位置及产品类型三级层级信息 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_product_type_mapping__reg_s0_live
        │
        │  SELECT + CAST + GROUP BY 去重
        ▼
srdi_mart.dim_sr_data_warehouse_ads_product_type_mapping
         (partition: local_date = ${local_date})
```

### 关键步骤

1. **读取上游维度表**：从 `mp_paidads.dim_product_type_mapping__reg_s0_live` 读取全量产品类型映射记录。
2. **类型转换**：将 `pricing_type` 和 `placement` 显式 `CAST` 为 `int` 类型，统一数据类型。
3. **去重处理**：对五个业务字段 (`pricing_type`, `placement`, `sub_product_type`, `product_type`, `main_product_type`) 执行 `GROUP BY`，消除上游可能存在的重复记录。
4. **分区覆写**：以 `INSERT OVERWRITE` 方式写入目标表指定日期分区 (`local_date = ${local_date}`)，实现每日全量刷新。

### 注意事项

- **单一写入者**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险，分区写入逻辑清晰。
- **全量覆写语义**：每次执行均覆盖当日分区全量数据，上游若有数据回刷需重新触发当日分区任务。
- **上游依赖为 live 表**：上游表 `_live` 后缀标识近实时更新，建议在上游数据稳定后（通常为每日固定时间窗口后）再触发本表 ETL，避免因上游数据未完整入库导致映射缺失。
- **GROUP BY 去重依赖**：本表未使用 `DISTINCT`，而是以 `GROUP BY 1,2,3,4,5` 替代，两者语义等价，但需关注上游若新增字段时 ETL 逻辑需同步维护。

---

*文档生成时间：2026-05-17*