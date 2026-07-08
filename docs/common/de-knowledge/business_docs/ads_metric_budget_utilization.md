---
doc_id: "ads_metric_budget_utilization"
title: "预算使用率（Budget Utilization）"
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
  - "预算使用率"
  - "预算利用率"
  - "budget utilization"
  - "budget usage rate"
related_tables:
  - "mp_paidads.ads_campaign_valid_budget_1d"
external_tables:
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1vdKpu-IaZmg5IrFJteD2if7Sl6Z0PNd3b_euj92zyVc gdoc_url=https://docs.google.com/document/d/1vdKpu-IaZmg5IrFJteD2if7Sl6Z0PNd3b_euj92zyVc/edit -->


# 预算使用率（Budget Utilization）

## 1. 口径定义

广告实际消耗占有效预算的比例，衡量预算利用效率。

## 2. 计算公式

```text
budget_utilization = ads_expenditure_usd / campaign_valid_budget_usd
```

## 3. 使用注意

典型过滤条件：先按天聚合再按月avg

## 4. 推荐表

| 表 | 角色 |
| --- | --- |
| `mp_paidads.ads_campaign_valid_budget_1d` | 复合指标 |

## 5. 适用范围

- Domain: `ads_mart`
- 该文档是人工确认过的复合指标/公式口径参考，只在问题明确命中该指标时使用。
- 如果问题指定了其他业务域或显式 SRDI 表，不应套用本广告数仓口径。
