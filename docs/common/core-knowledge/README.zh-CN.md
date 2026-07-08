<!-- ads-workspace-gdoc-sync: gdoc_id=1ZidLB4knlrwk6CrIZrS5541XLn35K38OMlxeT-Va_Hk gdoc_url=https://docs.google.com/document/d/1ZidLB4knlrwk6CrIZrS5541XLn35K38OMlxeT-Va_Hk/edit -->

# 广告核心知识/Ads Core Knowledge

> **Contributors**: luka.yang, amos.wu, cody.tan, ivan.du ｜ **最后更新**：2026-05-25 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/core-knowledge/README.zh-CN.md)
> **Language**: [English](README.md) | [中文](README.zh-CN.md)

---

> **维护者**：luka.yang & amos.wu & cody.tan & ivan.du — 欢迎提出修改建议或补充内容
>
> **注意**：部分模块信息可能过时，新人同学请与 mentor 沟通确认，并主动更新过时内容
>
> **唯一修改源**：本目录 `docs/common/core-knowledge/`。原来的单体文件已拆解为下方的按章节目录结构
>
> **Google Doc 阅读源[ReadOnly]**：[中文版](https://docs.google.com/document/d/1uEgOiNArIQm5zC6GBq9xejcKihX1rcxhGC1kP-AIznk/edit?tab=t.0) & [English Version](https://docs.google.com/document/d/1fqIvFEwni2GrZ3hn2hjKmpZ7FpinTOFCn8DfWBlKFJY/edit?tab=t.0#heading=h.uw953boyf1l1)

---

## 1. 广告概述/Ads Overview

| # | 文档 | 摘要 |
|---|------|------|
| 01 | [前言/Preface](01.ads-overview/01.preface.zh-CN.md) | 文档说明与导读 |
| 02 | [在线广告基础](01.ads-overview/02.online-advertising-fundamentals.zh-CN.md) | 广告生态、指标体系、归因模型 |
| 03 | [广告系统链路模块](01.ads-overview/03.system-pipeline-modules.zh-CN.md) | 端到端系统链路全景 |
| 04 | [广告系统策略机制](01.ads-overview/04.strategy-mechanisms.zh-CN.md) | 出价、混排、计费核心机制 |
| 05 | [电商广告的业务特性与产品创新](01.ads-overview/05.ecommerce-business-characteristics.zh-CN.md) | 电商场景特有策略 |
| 06 | [Shopee Paid Ads 业务介绍](01.ads-overview/06.shopee-paid-ads-overview.zh-CN.md) | Shopee 广告业务全貌 |

---

## 2. 广告策略/Ads Strategy

| # | 文档 | 摘要 |
|---|------|------|
| 01 | [召回通路和供给策略](02.ads-strategy/01.recall-and-supply-strategy.zh-CN.md) | 召回架构、商品卡/非商品卡召回、队列实现 |
| 02 | [CXR & PGMV 模型和校准](02.ads-strategy/02.cxr-pgmv-models-and-calibration.zh-CN.md) | Product Ads UniCR/pGMV、样本/Label、特征、架构 |
| 03 | [出价产品和算法](02.ads-strategy/03.bidding-products-and-algorithms.zh-CN.md) | 出价产品、调控、Bid2X、反馈闭环、BEM |
| 04 | [流量策略和广告计费](02.ads-strategy/04.traffic-strategy-and-billing.zh-CN.md) | Pacing/扶持/混排/计费 |
| 05 | [广告智能优惠券](02.ads-strategy/05.ads-smart-voucher.zh-CN.md) | ROI3/ROI4、Uplift 模型、发券、出价 |
| 06 | [广告主策略](02.ads-strategy/06.advertiser-strategy.zh-CN.md) | 扶持出价和广告主 Agent 策略 |
| 07 | [选品策略](02.ads-strategy/07.item-selection-strategy.zh-CN.md) | GMS 全托管选品、商品潜力模型、保送召回 |

---

## 3. 广告引擎/Ads Engine

| # | 文档 | 摘要 |
|---|------|------|
| 01 | [广告系统架构总览](03.ads-engine/01.system-architecture-overview.zh-CN.md) | 系统架构与核心仓库列表 |
| 02 | [广告引擎](03.ads-engine/02.ads-engine.zh-CN.md) | Engine 七大 API 接口 |
| 03 | [召回服务](03.ads-engine/03.ads-recall-service.zh-CN.md) | Recall 服务架构 |
| 04 | [出价服务](03.ads-engine/04.ads-bidding-service.zh-CN.md) | Bidding 服务架构 |
| 05 | [广告索引](03.ads-engine/05.ads-index.zh-CN.md) | Indexer 与 AdsInfo 架构 |
| 06 | [广告数据](03.ads-engine/06.ads-data.zh-CN.md) | 数据分类/服务/链路 |

---

## 4. 广告平台/Ads Platform

| # | 文档 | 摘要 |
|---|------|------|
| 01 | [平台前端](04.ads-platform/01.platform-frontend.zh-CN.md) | 投放平台前端全景 |
| 02 | [平台后端](04.ads-platform/02.platform-backend.zh-CN.md) | 投放平台后端架构 |
