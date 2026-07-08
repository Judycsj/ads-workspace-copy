<!-- ads-workspace-gdoc-sync: gdoc_id=167eUsehHolmR9-jBB7HDN136vvqnP7F2E9RF0dw4JbQ gdoc_url=https://docs.google.com/document/d/167eUsehHolmR9-jBB7HDN136vvqnP7F2E9RF0dw4JbQ/edit -->

# Ads Core Knowledge/广告核心知识

> **Contributors**: luka.yang, amos.wu, cody.tan, ivan.du ｜ **最后更新**：2026-05-25 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/core-knowledge/README.md)
> **Language**: [English](README.md) | [中文](README.zh-CN.md)

---

> **Maintainers**: luka.yang & amos.wu & cody.tan & ivan.du — Suggestions for edits or additions are welcome
>
> **Note**: Some module information may be outdated. New team members should confirm with their mentor and proactively update stale content.
>
> **Single Source of Truth**: This `docs/common/core-knowledge/` directory. The former monolithic file has been decomposed into the chapter-based structure below.
>
> **Google Doc Read Source [ReadOnly]**: [Chinese Version](https://docs.google.com/document/d/1uEgOiNArIQm5zC6GBq9xejcKihX1rcxhGC1kP-AIznk/edit?tab=t.0) & [English Version](https://docs.google.com/document/d/1fqIvFEwni2GrZ3hn2hjKmpZ7FpinTOFCn8DfWBlKFJY/edit?tab=t.0#heading=h.uw953boyf1l1)

---

## 1. Ads Overview/广告概述

| # | Document | Summary |
|---|----------|---------|
| 01 | [Preface](01.ads-overview/01.preface.md) | Document overview and reading guide |
| 02 | [Online Advertising Fundamentals](01.ads-overview/02.online-advertising-fundamentals.md) | Ad ecosystem, metrics, attribution models |
| 03 | [System Pipeline Modules](01.ads-overview/03.system-pipeline-modules.md) | End-to-end system pipeline overview |
| 04 | [Strategy Mechanisms](01.ads-overview/04.strategy-mechanisms.md) | Bidding, blending, billing core mechanisms |
| 05 | [E-commerce Business Characteristics](01.ads-overview/05.ecommerce-business-characteristics.md) | E-commerce specific strategies and innovations |
| 06 | [Shopee Paid Ads Overview](01.ads-overview/06.shopee-paid-ads-overview.md) | Shopee ads business landscape |

---

## 2. Ads Strategy/广告策略

| # | Document | Summary |
|---|----------|---------|
| 01 | [Recall Channels & Supply Strategy](02.ads-strategy/01.recall-and-supply-strategy.md) | Recall architecture, product/non-product recall, queue implementation |
| 02 | [CXR & PGMV Models and Calibration](02.ads-strategy/02.cxr-pgmv-models-and-calibration.md) | Product Ads UniCR/pGMV, sample/label, features, architecture |
| 03 | [Bidding Products and Algorithms](02.ads-strategy/03.bidding-products-and-algorithms.md) | Bidding products, control, Bid2X, feedback loop, BEM |
| 04 | [Traffic Strategy and Ad Billing](02.ads-strategy/04.traffic-strategy-and-billing.md) | Pacing, boost, blend, billing |
| 05 | [Ads Smart Voucher](02.ads-strategy/05.ads-smart-voucher.md) | ROI3/ROI4, Uplift model, issuance, bidding |
| 06 | [Advertiser Strategy](02.ads-strategy/06.advertiser-strategy.md) | Subsidy boost and advertiser agent strategy |
| 07 | [Item Selection Strategy](02.ads-strategy/07.item-selection-strategy.md) | GMS managed item selection, item potential model, reserve recall |

---

## 3. Ads Engine/广告引擎

| # | Document | Summary |
|---|----------|---------|
| 01 | [System Architecture Overview](03.ads-engine/01.system-architecture-overview.md) | Architecture & core repository list |
| 02 | [Ads Engine](03.ads-engine/02.ads-engine.md) | Engine 7 API interfaces |
| 03 | [Ads Recall Service](03.ads-engine/03.ads-recall-service.md) | Recall service architecture |
| 04 | [Ads Bidding Service](03.ads-engine/04.ads-bidding-service.md) | Bidding service architecture |
| 05 | [Ads Index](03.ads-engine/05.ads-index.md) | Indexer & AdsInfo architecture |
| 06 | [Ads Data](03.ads-engine/06.ads-data.md) | Data classification, services, pipeline |

---

## 4. Ads Platform/广告平台

| # | Document | Summary |
|---|----------|---------|
| 01 | [Platform Frontend](04.ads-platform/01.platform-frontend.md) | Ad platform frontend overview |
| 02 | [Platform Backend](04.ads-platform/02.platform-backend.md) | Ad platform backend architecture |
