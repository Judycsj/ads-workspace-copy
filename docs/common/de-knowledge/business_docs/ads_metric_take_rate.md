---
doc_id: "ads_metric_take_rate"
title: "Take Rate（广告变现率）"
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
  - "take rate"
  - "变现率"
  - "广告变现率"
  - "monetization rate"
related_tables:
  - "mp_paidads.ads_advertise_take_rate_v2_1d"
external_tables:
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1fwezb27FwiT40tgFxs7mRTZvtSKvlqPT-C93niaRvR0 gdoc_url=https://docs.google.com/document/d/1fwezb27FwiT40tgFxs7mRTZvtSKvlqPT-C93niaRvR0/edit -->


# Take Rate（广告变现率）

## 1. 口径定义

广告净收入占平台GMV的比例，衡量广告对平台整体交易的变现效率。有两个口径：含ROI3 voucher成本和不含ROI3 voucher成本。

## 2. 计算公式

```text
take_rate = net_ads_rev_usd / platform_gmv_excl_testorder
take_rate_excl_roi3 = (net_ads_rev_usd - ads_voucher_ads_part_amt_usd) / platform_gmv_excl_testorder
注意: platform_gmv_excl_testorder 是预聚合字段，需用 SUM(DISTINCT ...) 去重
```

## 3. 使用注意

典型过滤条件：tz_type = 'regional'

## 4. 推荐表

| 表 | 角色 |
| --- | --- |
| `mp_paidads.ads_advertise_take_rate_v2_1d` | 复合指标 |

## 5. 适用范围

- Domain: `ads_mart`
- 该文档是人工确认过的复合指标/公式口径参考，只在问题明确命中该指标时使用。
- 如果问题指定了其他业务域或显式 SRDI 表，不应套用本广告数仓口径。
