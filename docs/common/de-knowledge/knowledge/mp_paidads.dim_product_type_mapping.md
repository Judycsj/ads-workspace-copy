<!-- ads-workspace-gdoc-sync: gdoc_id=1BTagnoo8aeiC7hdQvYxJLRPQ32HOKk1EPmPdI0PRQzk gdoc_url=https://docs.google.com/document/d/1BTagnoo8aeiC7hdQvYxJLRPQ32HOKk1EPmPdI0PRQzk/edit -->

# mp_paidads.dim_product_type_mapping

**分层**：DIM（维度层）
**主键**：`pricing_type` + `placement`
**分区**：无分区字段
**更新频率**：随 Google Sheets 手工维护更新，快照同步至数仓
**引用频次**：5 次（候选表范围内）

---

## 业务描述

本表是付费广告产品类型的标准映射维表，将广告系统底层的 `pricing_type`（计费类型编码）与 `placement`（广告位编码）组合映射到业务可读的三级产品分类体系：`sub_product_type`（子产品类型）、`product_type`（产品类型）和 `main_product_type`（主产品类型）。

该表是付费广告数据体系中的核心维度表之一，广泛用于将原始广告事件数据关联至业务口径的产品分类，支撑广告绩效分析、预算归因、产品线 ROI 对比等场景。下游报表和事实表通过 `(pricing_type, placement)` 关联本表，实现数据的业务语义化。

数据源为业务方在 Google Sheets 中手工维护的映射规则表，覆盖 Product Ads、Shop Ads、Brand Ads、Live Ads、Video Ads 等全线广告产品，当前共有 104 条有效映射记录。

---

## 字段列表

### 维度：产品类型映射键

| 字段 | 类型 | 说明 |
|------|------|------|
| `pricing_type` | string | 广告计费类型编码（如 `1`=manual_cpc、`3`=itemboost、`9`=livestream_max_view 等），与 `placement` 联合构成本表的逻辑主键 ⚠️ 原始值为数字字符串，JOIN 时需注意上游表的类型一致性，避免隐式类型转换导致关联失败 |
| `placement` | string | 广告位编码（如 `0`、`4`、`33`、`3327` 等），与 `pricing_type` 联合构成本表的逻辑主键 ⚠️ 原始值为数字字符串，JOIN 时需注意上游表的类型一致性 |

### 维度：产品分类层级

| 字段 | 类型 | 说明 |
|------|------|------|
| `sub_product_type` | string | 子产品类型，最细粒度的产品分类标签，使用英文下划线命名（如 `manual_cpc`、`itemboost`、`livestream_max_gmv`、`search_result_page` 等），直接反映广告的投放策略与计费模式 |
| `product_type` | string | 产品类型，中间层分类（如 `Manual Mode`、`Item Boost`、`Simple Mode`、`ROI2.0`、`Live Ads`、`Search Brand Ads`、`Display Ads` 等），用于产品线维度的汇总分析 |
| `main_product_type` | string | 主产品类型，最高层分类，当前枚举值为：`Product Ads`、`Shop Ads`、`Brand Ads`、`Live Ads`、`Video Ads`，用于跨产品线的顶层汇总与对比 |

### 维度：元数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `ingestion_timestamp` | string | 数据从 Google Sheets 快照写入数仓的时间戳，用于追踪维表的最近同步时间 ⚠️ 为写入时间戳而非业务时间，不应用于业务时间过滤；若同一批次多次同步，该字段可用于判断最新快照 |

---

## 查询使用须知

本表为维表，直接 `SELECT` 或 `JOIN` 使用，无聚合场景。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（`142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4` / Sheet1） | 业务方手工维护的产品类型映射规则，为本表唯一数据来源 |

---

## ETL 逻辑摘要

### 维表说明

本表为 Google Sheets 快照维表，数据由付费广告业务方在 Google Sheets（[Product Type Mapping / Sheet1](https://docs.google.com/spreadsheets/d/142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4)）中手工维护，通过 `gws sheets.spreadsheets.values.get` 接口定期抓取快照后写入数仓。

**内容结构**：

- 每行代表一条 `(pricing_type, placement)` 组合到三级产品分类的映射规则
- 当前共 104 条记录，覆盖 Product Ads、Shop Ads、Brand Ads、Live Ads、Video Ads 五大主产品线
- 原始 Google Sheets 含 8 列，其中 `col_6`、`col_7`、`col_8` 三列为空列，未写入数仓

**数据流**：

```
Google Sheets (手工维护)
  [142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4 / Sheet1]
          │
          │  gws API 快照抓取
          ▼
mp_paidads.dim_product_type_mapping__reg_s0_live
  (pricing_type, placement, sub_product_type,
   product_type, main_product_type, ingestion_timestamp)
```

### 注意事项

1. **主键唯一性**：本表逻辑主键为 `(pricing_type, placement)` 组合，下游 JOIN 时应以此两字段关联，单独使用任意一个字段均可能产生多对多匹配，导致指标重复计算。
2. **类型对齐**：`pricing_type` 和 `placement` 在 Google Sheets 中以数字形式存储，写入数仓后为 `string` 类型。JOIN 上游事实表时，需确认事实表中对应字段的类型并做必要的类型转换（如 `CAST(fact.pricing_type AS STRING)`），避免关联失效。
3. **维表时效性**：本表内容依赖人工在 Google Sheets 中更新。若平台新增广告产品或计费模式，可能存在映射缺失（JOIN 后为 NULL）的情况，需与业务方确认维表是否已同步更新。
4. **空列忽略**：原始 Google Sheets 中的 `col_6`、`col_7`、`col_8` 三列均为空，未载入数仓字段，无需关注。

---

*文档生成时间：2026-05-20*