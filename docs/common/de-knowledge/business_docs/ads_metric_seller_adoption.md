---
doc_id: "ads_metric_seller_adoption"
title: "Seller Adoption%（广告卖家渗透率）"
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
  - "seller adoption"
  - "卖家渗透率"
  - "广告卖家占比"
  - "adoption rate"
related_tables:
  - "mp_paidads.ads_advertise_mkt_1d"
external_tables:
  - "traffic_omni_oa.dwd_order_item_atc_journey_di"
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1pplt_blWF5sUVjjRqE2WdUi3gwABIQai47GheW_Z66I gdoc_url=https://docs.google.com/document/d/1pplt_blWF5sUVjjRqE2WdUi3gwABIQai47GheW_Z66I/edit -->


# Seller Adoption%（广告卖家渗透率）

## 1. 口径定义

使用广告的活跃卖家数占全平台有订单卖家数的比例。需要跨域JOIN：广告活跃卖家来自ads_advertise_mkt_1d，全平台卖家来自订单归因表(traffic_omni_oa)。

## 2. 计算公式

```text
seller_adoption = active_ads_seller / active_seller_cnt
活跃广告卖家: count(distinct shop_id) where (is_ads_active=1 OR has_performance=1) AND placement NOT IN (7)
全平台卖家: count(distinct shop_id) from dwd_order_item_atc_journey where first_touchpoint_item=1
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
