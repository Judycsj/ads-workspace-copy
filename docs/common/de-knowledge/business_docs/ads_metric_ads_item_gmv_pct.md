---
doc_id: "ads_metric_ads_item_gmv_pct"
title: "Ads Item GMV%（广告商品GMV占比）"
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
  - "ads item gmv%"
  - "广告商品GMV占比"
  - "item gmv penetration"
related_tables:
  - "mp_paidads.ads_advertise_mkt_1d"
external_tables:
  - "traffic_omni_oa.dwd_order_item_atc_journey_di"
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1FzsmzUlh12g5d404JkMYDhVqHuEAXlqgeUrXkOziwL0 gdoc_url=https://docs.google.com/document/d/1FzsmzUlh12g5d404JkMYDhVqHuEAXlqgeUrXkOziwL0/edit -->


# Ads Item GMV%（广告商品GMV占比）

## 1. 口径定义

投放广告的商品产生的GMV占平台总GMV的比例。需要跨域JOIN：从广告mkt表确定活跃广告item，从订单归因表计算GMV归因。

## 2. 计算公式

```text
ads_item_gmv_pct = sum(gmv where item_id in active_ads_items) / sum(total_gmv)
使用 gmv_usd * atc_prorate * first_touchpoint_item 计算归因GMV
```

## 3. 使用注意

典型过滤条件：tz_type = 'local', 跨域JOIN

## 4. 推荐表

| 表 | 角色 |
| --- | --- |
| `mp_paidads.ads_advertise_mkt_1d` | 复合指标 |
| `traffic_omni_oa.dwd_order_item_atc_journey_di` | 复合指标 |

## 5. 适用范围

- Domain: `ads_mart`
- 该文档是人工确认过的复合指标/公式口径参考，只在问题明确命中该指标时使用。
- 如果问题指定了其他业务域或显式 SRDI 表，不应套用本广告数仓口径。
