---
doc_id: "ads_metric_cpc"
title: "CPC（每次点击成本）"
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
  - "CPC"
  - "每次点击成本"
  - "点击成本"
  - "cost per click"
related_tables:
  - "mp_paidads.ads_advertise_mkt_1d"
  - "mp_paidads.ads_advertise_take_rate_v2_1d"
external_tables:
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1UIQzuvcR_jLAAbDMWbMcrJNnDqOEdu_gEtO65wg0tUI gdoc_url=https://docs.google.com/document/d/1UIQzuvcR_jLAAbDMWbMcrJNnDqOEdu_gEtO65wg0tUI/edit -->


# CPC（每次点击成本）

## 1. 口径定义

广告主每次广告点击的平均成本。在take_rate表中计算时乘以1000是因为原始数据的单位换算。

## 2. 计算公式

```text
CPC = raw_ads_rev_usd * 1000 / ads_click
或 CPC = ads_expenditure_amt_usd / click_cnt（在mkt表中）
```

## 3. 使用注意

典型过滤条件：可按traffic_type或product_type分组

## 4. 推荐表

| 表 | 角色 |
| --- | --- |
| `mp_paidads.ads_advertise_mkt_1d` | 复合指标 |
| `mp_paidads.ads_advertise_take_rate_v2_1d` | 复合指标 |

## 5. 适用范围

- Domain: `ads_mart`
- 该文档是人工确认过的复合指标/公式口径参考，只在问题明确命中该指标时使用。
- 如果问题指定了其他业务域或显式 SRDI 表，不应套用本广告数仓口径。
