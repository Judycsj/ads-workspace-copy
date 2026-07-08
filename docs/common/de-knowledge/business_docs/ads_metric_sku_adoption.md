---
doc_id: "ads_metric_sku_adoption"
title: "SKU Adoption%（广告SKU渗透率）"
status: "verified"
owner: "ads_pm"
source_type: "curated_metric_formula"
domain: "ads_mart"
doc_type: "metric_formula"
source_refs:
  -
    type: "curated_json"
    path: "data/business_docs/ads_metric_formulas.json"
    title: "Migrated from old ads_knowledge_v3 composite_metrics; this is the curated source for generated metric formula business docs."
last_reviewed: "2026-04-02"
aliases:
  - "SKU adoption"
  - "SKU渗透率"
  - "广告SKU占比"
  - "sku adoption rate"
related_tables:
  - "mp_paidads.ads_item_supply_1d"
external_tables:
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1xZlsemGn_LZouKRNuTe3302Qf62_892QVlWlf3j6nYA gdoc_url=https://docs.google.com/document/d/1xZlsemGn_LZouKRNuTe3302Qf62_892QVlWlf3j6nYA/edit -->


# SKU Adoption%（广告SKU渗透率）

## 1. 口径定义

投放广告的SKU数占全平台活跃SKU数的比例，从ads_item_supply_1d单表计算。

## 2. 计算公式

```text
sku_adoption = count(distinct item_id where is_active_ads_item=1 AND (expenditure>0 OR impression>0)) / count(distinct item_id)
```

## 3. 使用注意

典型过滤条件：tz_type = 'local'

## 4. 推荐表

| 表 | 角色 |
| --- | --- |
| `mp_paidads.ads_item_supply_1d` | 复合指标 |

## 5. 适用范围

- Domain: `ads_mart`
- 该文档是人工确认过的复合指标/公式口径参考，只在问题明确命中该指标时使用。
- 如果问题指定了其他业务域或显式 SRDI 表，不应套用本广告数仓口径。
