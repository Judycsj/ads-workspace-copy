<!-- ads-workspace-gdoc-sync: gdoc_id=1Lls-quYUMMTH9GQBqKaNmqlNDRFrL59FcPQUBzFjjK8 gdoc_url=https://docs.google.com/document/d/1Lls-quYUMMTH9GQBqKaNmqlNDRFrL59FcPQUBzFjjK8/edit -->

# Brand & Content 团队问题清单：协作 KB 知识沉淀/Brand & Content Team Question List: Collaborative KB Knowledge Checklist

> **Contributors**: ivan.duzl ｜ **最后更新**：2026-05-08 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/sub-kb/brand-content-question-list.md)

---

## 一、背景/Background

本清单源自 Content-Algo 团队的「[question list for ads biz - content algo](https://docs.google.com/spreadsheets/d/1dq15UxbnEHC0VgomBGk_R6Kbsjb4rudhgGxx3a4qgvg/edit)」，由团队 20 位同学按个人 sheet 提交。共收集 **150+ 个问题**，覆盖业务、策略、工程、平台、协作五大类。

本文档按照 [`kb-100-questions.md`](./kb-100-questions.md) 的章节结构（2.x 策略层 / 3.x 工程层 / 4.x 平台层）将所有问题归类，并附加「六、协作与 Onboarding/Collaboration & Onboarding」承接不属于上述三层的通用类问题。每条问题保留提问人 (Asker)，便于后续 KB 编写过程中回访澄清。

填写约定：
- **问题/Question** 列保留原始中文/英文表述，必要时给出英文翻译
- **Asker** 列标注提问人 sheet（GSheet tab 名）
- 同一问题被多人重复提问时合并，Asker 列以 `,` 分隔列出全部提问人

## 二、问题分布总览/Question Distribution

| 模块/Module | 问题数/# Questions | 主要 Asker |
|------|--------|------------|
| 2.1 Recall 召回 | 4 | youhe.chen, bert.chen, zhigang.cui, yuheng.du |
| 2.2 pGMV Model 预估模型 | 12 | ivan.duzl, chenjiawei, bert.chen, zhigang.cui |
| 2.3 Bidding 出价 (Product) | 17 | ivan.duzl, bo.wangwb, youhe.chen, chenjiawei, yuquan.wang, zhigang.cui |
| 2.3 Bidding 出价 (Non-Product) | 22 | ivan.duzl, youhe.chen, chenjiawei, mani, bert.chen, zhigang.cui |
| 2.4 Traffic 流量策略 | 11 | youhe.chen, chenjiawei, mani, yuquan.wang |
| 2.5 Voucher 智能优惠券 | 11 | ivan.duzl, youhe.chen, zhigang.cui |
| 2.6 Advertiser Strategy 广告主策略 | 9 | bo.wangwb, naifeng.wang, hamdi |
| 3.1 Ads Engine 广告引擎 | 4 | chenjiawei, hamdi, yuquan.wang |
| 3.3 Ads Bidding 出价服务 | 2 | yuquan.wang, mani |
| 3.5 Ads Data 广告数据 | 16 | yuheng.du, chenjiawei, bert.chen, hamdi |
| 4.1 Platform FE 平台前端 | 2 | chenjiawei, mani |
| 4.2 Platform BE 平台后端 | 13 | bo.wangwb, hamdi, fighter, bert.chen |
| 六、协作与 Onboarding | 7 | bert.chen, fighter, hamdi |
| **合计/Total** | **130** | 16 askers |

注：2.2 Recall Service / 3.4 Ads Index 当前轮次未收到针对性问题，沉淀时可参考 [`kb-100-questions.md`](./kb-100-questions.md) 的对应章节。

---

## 三、策略层问题/Strategy Layer Questions

### 2.1 Recall 召回 (`2.1-recall/kb.md`) — 4 问/4 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 1 | 搜索和推荐场景的召回模块是如何统一的？/ How is the recall module unified across search and recommendation scenarios? | youhe.chen |
| 2 | shop/live/video 有哪些召回队列？/ What recall queues exist for shop / live / video ads? | bert.chen |
| 3 | shop ads 召回策略有哪些？/ What recall strategies are used for shop ads? | zhigang.cui |
| 4 | video 素材是怎么找回的？/ How is video creative material recalled? | yuheng.du |

### 2.2 pGMV Model 预估模型 (`2.2-pgmv-model/`) — 12 问/12 Questions

**Product Ads (`product-ads-model-kb.md`)**

| # | 问题/Question | Asker |
|---|------|-------|
| 5 | product ads UniCR 模型的逻辑，包括样本、label、特征和网络结构 / Logic of the product ads UniCR model, including samples, labels, features, and network structure | ivan.duzl |
| 6 | product ads UniCR 模型更新频次 / Update frequency of the product ads UniCR model | ivan.duzl |
| 7 | are there any CTR models used by product ads? | chenjiawei |
| 8 | what's the calibration strategy for product ads pCTR and pCR models respectively? | chenjiawei |
| 9 | for product ads, are there separate models per entrance, or a single model with entrance as a feature? | chenjiawei |

**Non-Product Ads (`non-product-ads-model-kb.md`)**

| # | 问题/Question | Asker |
|---|------|-------|
| 10 | shop ads CTR 建模的逻辑，包括训练样本、label 和特征的定义 / Logic of shop ads CTR modeling, including the definition of training samples, labels, and features | ivan.duzl |
| 11 | shop ads CVR 建模的逻辑，包括训练样本、label 和特征的定义 / Logic of shop ads CVR modeling, including the definition of training samples, labels, and features | ivan.duzl |
| 12 | shop ads CTR 建模方式 / Shop ads CTR modeling approach | zhigang.cui |
| 13 | shop ads CVR 建模方式 / Shop ads CVR modeling approach | zhigang.cui |
| 14 | how do live/video models currently integrate video/image/livestream features? are they being used currently? | chenjiawei |
| 15 | shop ranking 是怎么设计的？/ How is shop ranking designed? | bert.chen |
| 16 | 当前排序系统使用了哪些数据做训练？/ Which datasets are currently used to train the ranking system? | bert.chen |

### 2.3 Bidding 出价 — Product Ads (`2.3-bidding/product-ads-bidding-kb.md`) — 17 问/17 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 17 | ROI2 广告的出价策略介绍 / Introduction to ROI2 ad bidding strategies | ivan.duzl |
| 18 | ROI2 广告 MPC 预估的方式和方法 / Methods and approaches for ROI2 ad MPC estimation | ivan.duzl |
| 19 | 时序模型建模的设计和逻辑 / Design and logic of time-series modeling | ivan.duzl |
| 20 | 时序模型的样本构造逻辑 / Sample construction logic for time-series models | ivan.duzl |
| 21 | product ads 出价类型有哪些 / What bidding types exist for product ads? | zhigang.cui |
| 22 | product ads 出价中的优化策略有哪些 / What optimization strategies are used in product ads bidding? | zhigang.cui |
| 23 | Bid X MPC 的建模方法介绍和当前应用场景 / Introduction to Bid X MPC modeling methods and current application scenarios | zhigang.cui |
| 24 | product ads 出价冷启动策略介绍 / Introduction to product ads bidding cold-start strategies | zhigang.cui |
| 25 | Escrow 在 Product Ads 里的定位？/ How is Escrow positioned in Product Ads? | bo.wangwb |
| 26 | Escrow Bidding 要解决什么问题？北极星指标是什么？消耗覆盖是多少？/ What problem does Escrow Bidding solve? What is the North Star metric? What is the spend coverage? | bo.wangwb |
| 27 | Escrow Bidding 的出价框架；未来演进方向 / Escrow Bidding pricing framework and future evolution roadmap | bo.wangwb |
| 28 | 什么是 bid2cost / bid2gmv 建模，为什么要这么建模 / What is bid2cost / bid2gmv modeling, and why model it this way? | bo.wangwb |
| 29 | 什么是 target 产品 / simple 产品 / GMS 产品 / MP 产品 / What are the target / simple / GMS / MP product types? | bo.wangwb |
| 30 | 什么是 campaign surge / 什么是 rapid boost / What are campaign surge and rapid boost? | bo.wangwb |
| 31 | 成熟期广告的 tROI 出价是怎么做的？/ How is tROI bidding done for mature-stage ads? | youhe.chen |
| 32 | 在 online bidding 里对混排 ecpm、计费 ecpm 的影响 AdditionalBoost / AdditionalDeboost / additionalDeductionPrice 有哪些因素 / What factors influence AdditionalBoost / AdditionalDeboost / additionalDeductionPrice in online bidding for mixed-rank ecpm and billing ecpm? | youhe.chen |
| 33 | 多品、GMS 的出价链路是什么样的 / What does the bidding pipeline look like for multi-item and GMS ads? | youhe.chen |

### 2.3 Bidding 出价 — Non-Product Ads (`2.3-bidding/non-product-ads-bidding-kb.md`) — 22 问/22 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 34 | live ads 单列和双列分别是什么场景？排序和建模有啥差异？/ What scenarios use live ads single-column vs double-column? What are the ranking and modeling differences? | ivan.duzl |
| 35 | brand-max 广告整体流程是什么，包括库存和定价的逻辑 / What is the overall process for brand-max ads, including inventory and pricing logic? | ivan.duzl |
| 36 | live ads 的投放链路是怎样的 / What is the delivery pipeline for live ads? | ivan.duzl |
| 37 | shop ads 的投放链路是怎样的 / What is the delivery pipeline for shop ads? | ivan.duzl |
| 38 | video ads 的投放链路是怎样的 / What is the delivery pipeline for video ads? | ivan.duzl |
| 39 | video ads 内的 bundle 是什么含义 / What does "bundle" mean within video ads? | ivan.duzl |
| 40 | BrandMax 在哪些区域投放 / Which regions does BrandMax serve in? | youhe.chen |
| 41 | BrandMax 的 CPM 是如何计算的 / How is BrandMax CPM computed? | youhe.chen |
| 42 | BrandMax 的保量、竞价机制是什么样 / How do BrandMax volume guarantee and bidding mechanisms work? | youhe.chen |
| 43 | Search Brand Ads 的 CPM 是怎么计算的 / How is Search Brand Ads CPM computed? | youhe.chen |
| 44 | Search Brand Ads 的广告是如何选择、展示的 / How are Search Brand Ads selected and displayed? | youhe.chen |
| 45 | shop / live / video 下有哪些 pricing type，代表什么意思 / What pricing types exist under shop / live / video, and what do they mean? | bert.chen |
| 46 | Shop bidding 是怎么设计的 / How is Shop bidding designed? | bert.chen |
| 47 | content ads 包含哪些出价场景 / What bidding scenarios are included in content ads? | zhigang.cui |
| 48 | content 场景中出价的优化目标有哪些 / What are the bidding optimization objectives in content scenarios? | zhigang.cui |
| 49 | shop ads 出价类型介绍 / Introduction to shop ads bidding types | zhigang.cui |
| 50 | shop / live / video ads 中 MPC 调控策略介绍 / Introduction to MPC control strategies in shop / live / video ads | zhigang.cui |
| 51 | 出价场景 advv 计算方式介绍 / Introduction to advv calculation across bidding scenarios | zhigang.cui |
| 52 | shop ads target ROAS 出价公式介绍 / Introduction to shop ads target ROAS bidding formula | zhigang.cui |
| 53 | live ads max view / max GMV 的出价公式介绍 / Introduction to live ads max view / max GMV bidding formulas | zhigang.cui |
| 54 | 出价场景中 BCB 调控策略介绍 / Introduction to BCB control strategies in bidding scenarios | zhigang.cui |
| 55 | shop ads ECPC 出价的调控方法介绍 / Introduction to shop ads ECPC bidding control methods | zhigang.cui |
| 56 | content ads 出价有哪些计费方式 / What billing methods are used in content ads bidding? | zhigang.cui |
| 57 | explain to me the entire bidding workflow after scoring for shop, live, video and product ads respectively | chenjiawei |
| 58 | what's the differences in bidding logic between antou and mingtou for video ads, and subsequently shop ads | chenjiawei |
| 59 | for video ads, which are all the different entrances. how does entrance = 1 work in both the backend and frontend? | chenjiawei |
| 60 | what's the relationship between ROAS targets set by advertisers and the internal bidding signal the model uses? | chenjiawei |
| 61 | what is the current stage for bidding models — are we still using PID or more sophisticated style models? | chenjiawei |
| 62 | how does different ads handle the cold-start problem for new shops or new items with little to no impression history? are there any differences between all the different ads? | chenjiawei |
| 63 | 冷启动广告的历史信息少，pCTR、pCR 模型预估偏差如何修正的？/ How are pCTR / pCR model prediction biases corrected for cold-start ads with limited history? | youhe.chen |
| 64 | 冷启动类广告的 pCTR、pCR 模型和成熟期的特征、模型有什么差异？/ How do cold-start pCTR / pCR models differ from mature-stage models in features and architecture? | youhe.chen |
| 65 | 双出价这块浅层转化和深层转化的目标差异是什么，广告主需要设双层的目标吗？/ What's the difference between shallow vs deep conversion goals in dual bidding, and do advertisers need to set both? | youhe.chen |
| 66 | Differences between internal and external entrances for video ads | mani |
| 67 | What's the bidding logic for video ads mingtou? | mani |
| 68 | Currently what regions × entrances support video ads? Breakdown support for antou and mingtou | mani |
| 69 | What is the delivery pipeline like for brandmax? | mani |
| 70 | How do you compute the bid price for brandmax? | mani |
| 71 | What are the current bidding strategy plans for OCPM? | mani |
| 72 | Describe the relationship among AdditionalBoost, AdditionalDeduction, AdditionalDeboost, pOrg, and rankScore in online-bidding and ads engine | yuquan.wang |

### 2.4 Traffic 流量策略 (`2.4-traffic/pacing-deduction.md`) — 11 问/11 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 73 | 扶持框架的扶持预算是怎么设定的 / How is the boost budget set in the support framework? | youhe.chen |
| 74 | 扶持框架离线是怎么进行预算分配的 / How is offline budget allocation done in the support framework? | youhe.chen |
| 75 | 扶持成本是怎么收集的 / How is boost cost collected? | youhe.chen |
| 76 | 当前的扶持框架线上怎么结合其他服务的 / How does the current support framework integrate with other services online? | youhe.chen |
| 77 | 扶持里召回和粗排的保送是怎么实现的？/ How is recall / coarse-rank reservation implemented inside support? | youhe.chen |
| 78 | how does the system handle budget pacing — is it even pacing, ASAP, or something adaptive? how does it interact with the auction in real time? | chenjiawei |
| 79 | How does the boost service interact with the other bidding services? | mani |
| 80 | What metrics are used to verify traffic boost budget strategy is working as expected? | mani |
| 81 | How does the traffic boost budget strategy allocate additional budget to campaigns? | mani |
| 82 | How to monitor the healthiness of budget usage of subsidy framework v2? | yuquan.wang |
| 83 | How to fetch subsidy budget and current spending of subsidy framework v2 from redis? | yuquan.wang |

### 2.5 Voucher 智能优惠券 — Model + Strategy (`2.5-voucher/`) — 11 问/11 Questions

**Model (`model.md`)**

| # | 问题/Question | Asker |
|---|------|-------|
| 84 | product ads uplift 模型网络结构 / Network structure of the product ads uplift model | ivan.duzl |
| 85 | product ads RCT 样本的构建逻辑 / Construction logic of product ads RCT samples | ivan.duzl |
| 86 | 怎么预估 ROI3 发 or 不发券带来的效果 / How to estimate the effect of issuing vs not issuing ROI3 vouchers? | youhe.chen |
| 87 | ROI3 中的 uplift 模型如何建模 / How is the uplift model in ROI3 built? | zhigang.cui |
| 88 | what strategy is the uplift modelling using? i.e., S-learner, T-learner. how do we keep the treatment and control groups unbiased? | chenjiawei |

**Strategy (`strategy.md`)**

| # | 问题/Question | Asker |
|---|------|-------|
| 89 | ROI3 发券实验的核心观测指标，包括 AB 指标和 AA 指标 / Core observation metrics for ROI3 voucher experiments, including A/B and A/A metrics | ivan.duzl |
| 90 | ROI3 发券的整体策略逻辑 / Overall strategy logic of ROI3 voucher issuance | ivan.duzl |
| 91 | ROI3 发券的链路 / ROI3 voucher issuance pipeline | ivan.duzl |
| 92 | non-ads 发券链路的逻辑 / Logic of the non-ads voucher issuance pipeline | ivan.duzl |
| 93 | ROI3 发券的预算是怎么分配的？/ How is ROI3 voucher budget allocated? | youhe.chen |
| 94 | ROI3 发券的面额是如何设计的 / How is the ROI3 voucher denomination designed? | youhe.chen |
| 95 | ROI3 介绍 / Introduction to ROI3 | zhigang.cui |
| 96 | ROI3 发券流程介绍 / Introduction to ROI3 voucher issuance flow | zhigang.cui |

### 2.6 Advertiser Strategy 广告主策略 (`2.6-advertiser-strategy/`) — 9 问/9 Questions

**Advertiser Agent + AI 提效 (`advertiser-agent.md`)**

| # | 问题/Question | Asker |
|---|------|-------|
| 97 | suggest_roi / budget 是否可以使用 AI 来提效 / Can AI be applied to improve suggest_roi / budget efficiency? | naifeng.wang |
| 98 | incentive AI 提效的当前状态是怎样的 / What is the current state of incentive AI efficiency improvements? | naifeng.wang |
| 99 | incentive AI 提效下一步如何推进 / How will incentive AI efficiency be advanced next? | naifeng.wang |

**Managed Mode + Subsidy & Boost (`managed-mode.md` / `subsidy-boost.md`)**

| # | 问题/Question | Asker |
|---|------|-------|
| 100 | 什么是 suggest ROI / 什么是 suggest budget / What are suggest ROI and suggest budget? | bo.wangwb |
| 101 | 平台是否需要做选品？选品可以用在哪些业务场景 / Does the platform need to do item selection? Which business scenarios use it? | bo.wangwb |
| 102 | 选品模型应该如何建模 / How should the item selection model be built? | bo.wangwb |
| 103 | suggest_roi / budget 效果如何评估 / How is the effectiveness of suggest_roi / budget evaluated? | naifeng.wang |
| 104 | suggest_roi / budget 产品侧的主要诉求是什么 / What are the main product-side requirements for suggest_roi / budget? | naifeng.wang |
| 105 | suggest_roi / budget 技术侧的迭代路径大致是怎样的 / What is the rough technical iteration roadmap for suggest_roi / budget? | naifeng.wang |

---

## 四、工程层问题/Engineering Layer Questions

### 3.1 Ads Engine 广告引擎 (`3.1-ads-engine/kb.md`) — 4 问/4 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 106 | what's the end-to-end latency budget for a full ads ranking request, and how is it allocated across retrieval, feature fetch, scoring, and auction? | chenjiawei |
| 107 | How does the ads request flow work from frontend entry, retrieval, ranking, bidding, pacing, charging, and logging? | hamdi |
| 108 | Describe how the following microservices interact: online-bidding, ultrav-core, ultrav-data-processor, ultrav-core-aggregator, and bidding-store | yuquan.wang |
| 109 | shop 的业务链路 / Shop ads end-to-end business pipeline | yuheng.du |

### 3.3 Ads Bidding Service 出价服务 (`3.3-ads-bidding/kb.md`) — 5 问/5 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 110 | How does infra handle OCPM deductions, given that the number of deduction requests will be much greater? | mani |
| 111 | How are seller and traffic budgets computed for each campaign for the order_priority agent in ultrav-core or its upstreams? | yuquan.wang |
| 112 | What is the pool of ads that will be allocated positive traffic budget? | yuquan.wang |
| 113 | Will an ad be allocated positive budget if it has no target? if it has no model parameters? if its model prediction has saturated at seller budget? if the MCKP has a positive solution? | yuquan.wang |
| 114 | are there full trace logs on the candidate-level instead of event-level for shop, live, video ads respectively? | chenjiawei |

### 3.5 Ads Data 广告数据 (`3.5-ads-data/kb.md`) — 16 问/16 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 115 | video / shop 的流水是多少 / What is the GMV of video / shop ads? | yuheng.du |
| 116 | pcr 每日的归因比例是多少 / What is the daily attribution ratio for pcr? | yuheng.du |
| 117 | video / shop 转化率是多少 / What is the conversion rate of video / shop ads? | yuheng.du |
| 118 | shop / live / video 所有场景举例子 / List all scenarios for shop / live / video | yuheng.du |
| 119 | shop / live / video 所有场景流水比例 / GMV breakdown across shop / live / video scenarios | yuheng.du |
| 120 | shop / live / video 一共有多少场景 / Total scenario count for shop / live / video | yuheng.du |
| 121 | shop / live / video 主要消费品类 / Main consumption categories for shop / live / video | yuheng.du |
| 122 | shop 展示栏的数量 / Number of shop ad display slots | yuheng.du |
| 123 | what is the exact order attribution logic for the different types of ads (shop, live, video, product)? | chenjiawei |
| 124 | 当前哪个场景贡献的收益最多 / Which scenario currently contributes the most revenue? | bert.chen |
| 125 | broad order 是怎么定义的 / How is broad order defined? | bert.chen |
| 126 | 有哪些表比较常用，可以用来评估召回、排序、广告最终表现的 / Which tables are commonly used to evaluate recall, ranking, and final ads performance? | bert.chen |
| 127 | What are the main dashboards to monitor for each ads service, and which panels should be checked first during incidents? | hamdi |
| 128 | What are the core ads performance tables for hourly and daily analysis, and when should each one be used? | hamdi |
| 129 | What are the standard business metrics in ads — rev, advv, GMV, order, CTR, CVR, CPM, CPC, ROI, budget utilization? | hamdi |
| 130 | What are the key data tables for campaign, ads, item, shop, budget, bidding, exposure, click, order, and charging information? | hamdi |
| 131 | What are the main log sources for debugging ads issues, and how do we trace one request across services? | hamdi |

---

## 五、平台层问题/Platform Layer Questions

### 4.1 Platform FE 平台前端 (`4.1-platform-fe/kb.md`) — 2 问/2 Questions

| # | 问题/Question | Asker |
|---|------|-------|
| 132 | for video ads, which are all the different entrances — how does entrance = 1 work in both the backend and frontend? | chenjiawei |
| 133 | (Frontend display) shop 展示栏的数量 — 前端展示位定义 / Definition of shop ad display slots from the FE perspective | yuheng.du |

### 4.2 Platform BE 平台后端 (`4.2-platform-be/kb.md`) — 13 问/13 Questions

**GMS / Item Selection 业务托管 (Hamdi 专题)**

| # | 问题/Question | Asker |
|---|------|-------|
| 134 | What is GMS (Shop GMV Max), and how is it different from other ads products? | hamdi |
| 135 | What are the pricing types and bidding modes supported by GMS ads? | hamdi |
| 136 | What is the end-to-end GMS delivery pipeline, from campaign setup to item selection, bidding, serving, and feedback logging? | hamdi |
| 137 | How does the current GMS item selection pipeline work, and which services own each step? | hamdi |
| 138 | What candidate pools are used for GMS item selection, and how are items added, updated, or removed? | hamdi |
| 139 | What are the main prune / filter rules in GMS item selection (budget, validity, item quality, performance, eligibility)? | hamdi |
| 140 | How do tag-service, bidsense, and escrow service interact in the old and new GMS item selection logic? | hamdi |
| 141 | What online and offline signals are used for GMS selection (pCost, pROI, item prior features, post-ad performance, budget, order feedback)? | hamdi |
| 142 | How do we evaluate whether a GMS item selection change is good — ads with order, revenue, GMV, budget utilization, pROI, prune coverage? | hamdi |
| 143 | What are the common failure cases or historical bad cases in GMS item selection, and how should a new member debug them? | hamdi |

**Other Platform BE**

| # | 问题/Question | Asker |
|---|------|-------|
| 144 | 当前是怎么衡量卖家体验的 / How is seller experience currently measured? | bert.chen |
| 145 | 目前各个项目的 PIC 分别是谁 / Who are the current PICs for each project? | bert.chen |
| 146 | What are the git repos for the engine side of our team — what does each repo do and how do they connect to other services? | fighter |

---

## 六、协作与 Onboarding/Collaboration & Onboarding

通用类问题：实验流程、监控、配置、发版、上线规范，以及不在 18 个 sub-kb 文件中明确归属的协作话题。

| # | 问题/Question | Asker |
|---|------|-------|
| 147 | What are the standard experiment workflows for ads changes — offline validation, A/B setup, ramp-up, metric readout, rollout? | hamdi |
| 148 | How do we check whether an ads metric movement is caused by algo change, traffic shift, seller behavior, campaign mix, or platform issue? | hamdi |
| 149 | What are the main configuration platforms used by ads services, and how do we check config history or rollback safely? | hamdi |
| 150 | What are the usual release and on-call procedures for ads services — pre-checks, monitoring, rollback criteria, post-release validation? | hamdi |
| 151 | For Full Campaign Managed project related, how are experiments conducted? Are experiments conducted on the company A/B platform? | fighter |
| 152 | For Full Campaign Managed project related, what are some common / red-line business metrics aside from project-depending ones? | fighter |

---

## 七、KB 编写指南/KB Writing Guide

参见姊妹文档 [`kb-100-questions.md`](./kb-100-questions.md) 的「六、KB 编写指南」章节。简要复述：

1. **骨架填充**：Owner 逐条回答自己模块的问题，利用嵌入的代码路径和公式作为骨架
2. **参考模板**：参考已有高质量 KB（cali-kb / bidding-kb / bem KB template）
3. **Smoke Test**：用 `ads-knowledge-qa` Agent 测试 KB 回答质量
4. **迭代补充**：收集 Agent 无法回答或回答不准确的问题，补充知识
5. **必要内容检查**：每个 KB 必须包含代码仓库 GitLab 路径 / SDU 路径 / ConfigCenter namespace / Grafana dashboard 链接 / Kafka topic / Hive 表名

### 验证方式/Verification

- 对每个 sub-kb 文件，使用其对应问题作为 eval prompt
- 目标：每个模块的问题回答准确率 ≥ 80%
- 重点验证系统/代码层面的回答是否包含具体的仓库路径、代码文件、配置项
- 对于跨模块的 onboarding 问题，建议沉淀到团队 wiki 或 onboarding 文档

### 后续动作/Next Steps

- [ ] 将「六、协作与 Onboarding」类问题路由到对应 owner 或团队 wiki
- [ ] 待 sheet 后续补充时，本文档支持增量回填（按 Asker 分组）
- [ ] 与 [`kb-100-questions.md`](./kb-100-questions.md) 中的 100 题做去重对照，避免重复 KB 编写
