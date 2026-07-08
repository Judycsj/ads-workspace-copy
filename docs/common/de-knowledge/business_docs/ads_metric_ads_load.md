---
doc_id: "ads_metric_ads_load"
title: "Ads Load（广告加载率）"
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
  - "ads load"
  - "广告加载率"
  - "广告渗透率"
  - "ad load rate"
related_tables:
  - "mp_paidads.ads_advertise_take_rate_v2_1d"
external_tables:
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1VMmiH6Ge9_ivCJ8Nmuga8dOnF2xAxCDaxnq_KhEf6bI gdoc_url=https://docs.google.com/document/d/1VMmiH6Ge9_ivCJ8Nmuga8dOnF2xAxCDaxnq_KhEf6bI/edit -->


# Ads Load（广告加载率）

## 1. 口径定义

广告曝光量占流量入口总曝光量的比例，衡量广告在流量中的渗透程度。

## 2. 计算公式

```text
ads_load = ads_imp / entry_point_imp
```

## 3. 使用注意

典型过滤条件：tz_type = 'regional', 按traffic_type分组

## 4. 推荐表

| 表 | 角色 |
| --- | --- |
| `mp_paidads.ads_advertise_take_rate_v2_1d` | 复合指标 |

## 5. 适用范围

- Domain: `ads_mart`
- 该文档是人工确认过的复合指标/公式口径参考，只在问题明确命中该指标时使用。
- 如果问题指定了其他业务域或显式 SRDI 表，不应套用本广告数仓口径。
