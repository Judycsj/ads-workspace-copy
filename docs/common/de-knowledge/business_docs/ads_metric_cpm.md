---
doc_id: "ads_metric_cpm"
title: "CPM（千次曝光成本）"
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
  - "CPM"
  - "千次曝光成本"
  - "cost per mille"
related_tables:
  - "mp_paidads.ads_advertise_mkt_1d"
  - "mp_paidads.ads_advertise_take_rate_v2_1d"
external_tables:
---
<!-- ads-workspace-gdoc-sync: gdoc_id=147fS8zSt-EQN9SXLsrRECCE03pTXA8qwd0jrKzo81v4 gdoc_url=https://docs.google.com/document/d/147fS8zSt-EQN9SXLsrRECCE03pTXA8qwd0jrKzo81v4/edit -->


# CPM（千次曝光成本）

## 1. 口径定义

广告每一千次曝光的成本，衡量广告曝光效率。

## 2. 计算公式

```text
CPM = raw_ads_rev_usd * 1000 / ads_imp
或 CPM = ads_expenditure_amt_usd * 1000 / impression_cnt
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
