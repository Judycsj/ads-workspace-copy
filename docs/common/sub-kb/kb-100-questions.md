# Ads Sub-KB 100 问：面向 Agent 智能工作流的知识库问题清单/Ads Sub-KB 100 Questions: Knowledge Base Checklist for Agent-Powered Intelligent Workflows

> **Contributors**: luka.yang ｜ **最后更新**：2026-04-29 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/sub-kb/kb-100-questions.md)

---

## 一、背景/Background

`docs/common/sub-kb/` 下按三层架构组织了 **18 个核心 KB 文件**：

```
sub-kb/
├── 2.x 策略层 (11 files)
│   ├── 2.1-recall/kb.md
│   ├── 2.2-pgmv-model/{product,non-product}-ads-model-kb.md
│   ├── 2.3-bidding/{product,non-product}-ads-bidding-kb.md
│   ├── 2.4-traffic/pacing-deduction.md
│   ├── 2.5-voucher/{model,strategy}.md
│   └── 2.6-advertiser-strategy/{advertiser-agent,managed-mode,subsidy-boost}.md
├── 3.x 工程层 (5 files)
│   ├── 3.1-ads-engine/kb.md
│   ├── 3.2-ads-recall/kb.md
│   ├── 3.3-ads-bidding/kb.md
│   ├── 3.4-ads-index/kb.md
│   └── 3.5-ads-data/kb.md
└── 4.x 平台层 (2 files)
    ├── 4.1-platform-fe/kb.md
    └── 4.2-platform-be/kb.md
```

本清单为每个 sub-kb 文件提供**需要回答的核心问题**。问题设计覆盖三个层次：

1. **业务逻辑层**：是什么、为什么、产品机制
2. **系统架构层**：服务组件、数据流、接口协议、代码仓库、SDU 路径
3. **工程实操层**：代码路径、配置管理、监控告警、排查方法、发版流程

这些问题同时是 `ads-knowledge-qa` 等 Agent 的高频 query 原型。KB 作者按问题逐条填写即可完成知识沉淀。

补充：BEM / 时序环境模型沉淀在 `2.3-bidding/bem-kb.md`，作为 Product Ads bidding 的补充 KB。

## 二、问题分布总览/Question Distribution

| 模块 | 文件数 | 问题数 | Owner |
|------|--------|--------|-------|
| 2.1 Recall 召回 | 1 | 8 | @cody |
| 2.2 pGMV Model 预估模型 | 2 | 8 | @haibo / @yuheng |
| 2.3 Bidding 出价 | 2 | 12 | @xinyu / @ivan |
| 2.4 Traffic 流量策略 | 1 | 8 | @xinyu |
| 2.5 Voucher 智能优惠券 | 2 | 8 | @haibo / @roger |
| 2.6 Advertiser Strategy 广告主策略 | 3 | 6 | @youhe / @wangbo |
| 3.1 Ads Engine 广告引擎 | 1 | 10 | TBD |
| 3.2 Ads Recall 召回服务 | 1 | 6 | TBD |
| 3.3 Ads Bidding 出价服务 | 1 | 8 | TBD |
| 3.4 Ads Index 广告索引 | 1 | 6 | TBD |
| 3.5 Ads Data 广告数据 | 1 | 8 | TBD |
| 4.1 Platform FE 平台前端 | 1 | 6 | TBD |
| 4.2 Platform BE 平台后端 | 1 | 6 | TBD |
| **合计** | **18** | **100** | |

---

## 三、策略层 100 问/Strategy Layer Questions

### 2.1 Recall 召回 (`2.1-recall/kb.md` @cody) — 8 问

| # | 问题 |
|---|------|
| 1 | 广告召回在 API0 pipeline 中的执行位置？`ads-engine/pkg/handler/ads_recall` 的 DAG（`ads_recall_base` / `ads_recall_video` / `ads_recall_live`）各包含哪些 operator，执行顺序如何？ |
| 2 | `paidads-recall` 仓库的多场景召回架构：Search 召回（Query2Tag2Item / Online Query2Item / 直投队列）和 RCMD 召回（U2I2I / OnlineU2I / Offline U2I / U2U2I）各队列的离线数据流（样本源 → 模型训练 → 索引构建）和在线服务链路？ |
| 3 | OhMyEmb（`oh-my-embedding`）的向量召回系统：离线 embedding 计算（Data Source → Kafka → Embedding Calculator → Sinker → Redis → Vespa）的完整 pipeline？KNN 召回（`RecommendKnnRecallOp`）和 KV 召回（`RecommendFetchI2IItemOp`）的 YAML 配置结构和关键参数（vespa_name、rank_profile、recall_limit、score_range）？ |
| 4 | Vespa 索引规模和 schema 设计：Product Ads 130+ schemas（Simple ROI2: 102 fields/~1.5M ads，Target ROI2: 97 fields/~6M ads），Content Ads 60+ schemas。schema 字段来源和更新机制？ |
| 5 | 非商品卡广告召回逻辑差异：Shop 卡（item path + keyword path）、Video 卡（explicit/implicit）、Live 卡（item path + streamer path）的暗投 vs 明投机制？ |
| 6 | 召回阶段的过滤机制和 Recall Log：各阶段的 filter reason（INACTIVEITEM、ITEMNOADS、OFFLINEFILTERNOTPASS、LOWRELESCORE、NOPAIREDKEYWORD、LOWECPM 等）含义和排查方法？ |
| 7 | QueryUnderstanding 模块（QueryRewrite、QueryExtend/Query2UnifyQuery、Query2Tag）的实现和 MText（`shopee-server/mtext`）的集成方式？Query 特征来源（MFP feature table 6724）和 User 特征来源（MFP feature table 5560）？ |
| 8 | 召回核心监控指标（召回率、覆盖率、队列贡献占比、候选池大小、Vespa 查询延迟）和 AB 实验设计方法（分流方案、互斥/正交设计）？ |

### 2.2 pGMV Model 预估模型 — 8 问

**Product Ads (`product-ads-model-kb.md` @haibo) — 5 问**

| # | 问题 |
|---|------|
| 9 | UniCR 多任务多场景模型架构：EPNet (bottom) → MMOE-STAR (middle) → STAR (top) 的网络结构？6 个预估目标（`prob_1h / prob_6h / cr_1d / cr_3d / cr_7d` + GMV regression）的定义？多场景（search / dd / ymal / pp）的适配方式？ |
| 10 | 样本生产 pipeline（rank dump → FP → TrainData → Label backflow）：正负样本定义、归因逻辑（Click-through 7d / View-through 1d / Last Touch / Direct vs Broad）、延迟反馈建模方案？ |
| 11 | 模型特征体系：序列特征（click 500 / cart 128 / order 128）、用户特征、广告特征、上下文特征的来源（FSE 表名、Slot ID 列表）？ScoringX（`scoringX`）在线推理的实现方式和性能要求（P99 ≤ 45ms）？ |
| 12 | pGMV 计算公式（`pGMV = pCTR × pCVR × pAOV`，其中 Classification CR 0/1 + Regression 1/N GMV，`item_price × sold_cnt_smoothed × CR_7d`）和校准（calibration）：pcoc 计算（`sum(pcr) / sum(actual_order)`）、order-preserving 校准方法？ |
| 13 | 模型例行训练 pipeline（Stage 1 Seed Round: T-8 checkpoint + T-7 data → Stage 2 Incremental: T-6 to T-1 → Release）的关键配置？EGO 平台训练任务的提交和监控方式？核心评估指标（AUC/gAUC/calibration ratio/离在线一致性）？ |

**Non-Product Ads (`non-product-ads-model-kb.md` @yuheng) — 3 问**

| # | 问题 |
|---|------|
| 14 | Shop/Video/Live Ads 模型与 Product Ads UniCR 的共享和差异：预估目标差异（Video: pVR、Live: eCR）、label 定义差异、模型架构是否复用？各类型模型的 EGO 训练配置和仓库路径？ |
| 15 | 非商品卡广告的样本稀疏度挑战和应对方案？各类型独有特征（直播间热度、视频时长、shop 画像、streamer 特征）的来源和 FSE 表？ |
| 16 | 非商品卡广告模型的在线推理：是否与 Product Ads 共享 ScoringX？各广告类型在 `ads_unified` API4（`ads_unified_shop_ads / ads_unified_live / ads_unified_brand_max`）中的 scoring 调用方式？ |

### 2.3 Bidding 出价 — 12 问

**Product Ads (`product-ads-bidding-kb.md` @xinyu) — 7 问**

| # | 问题 |
|---|------|
| 17 | 出价产品体系全景：ROI1（手动 CPC/eCPC）、ROI2（自动 OCPM/OCPC，含 Simple/Target 两种模式）的产品定义？各模式的 eCPM 计算公式（Manual CPC: `pCTR × CPC`；eCPC: `pCTR × keywordBid × (pCVR/avgPCVR) × λ`；ROI2: `pCTR × pCVR × (pAOV/targetROAS) × λ`；Full-site: `pGMV × λ / Target_ROAS`）？ |
| 18 | 出价调控算法：PID（`λ = Kp×ErrorP + Ki×ErrorI + Kd×ErrorD + 1`）和 MPC（`argmax GMV(λ) s.t. constraints`）的原理？单步调控 vs 双步调控（Setting Budget→BCB / Setting TROI→TargetROAS）的适用场景？Lambda 分解（`λ = λ_cost × λ_pacing`）？ |
| 19 | Bid2X MPC 预估模型：Traffic Replay pipeline（ranking logs → replay auction per ad per λ → 15-min window → PCOC calibration）的数据流？样本矩阵结构（672 time slices × 10 lambdas × 4 metrics per ad）？三种建模方法（Linear Interpolation + Isotonic Regression / VAE / Foundation Model）？ |
| 20 | Bid2X 代码实现：核心 dataclass（`Item`, `ReplayResult`, `WindowSample`, `PCOCCoefficients`）和函数（`compute_ranker_score()`, `replay_one_request()`, `aggregate_to_windows()`, `pava()`, `bid2pcost()`, `solve_lambda()`）？Foundation Model 网络结构（`UnifiedEmbedding → VariableAttention → TemporalAttention → VariableAwareFusion → ZeroInflatedProjection`）？ |
| 21 | `online-bidding` 仓库的 DoRerank 6 阶段（Model → Voucher → Bidding → Subsidy → AdjustBid → Deduction）和子阶段（rerankModel → rerankPrepare → rerankVoucher → rerankBidding → ... → rerankFinalization）？entry point: `internal/handler/product_ads.go`？ |
| 22 | `bidding-store` 的数据模型（proto: `ad_coef_infos` 结构含 coef_type, id_type, coef, entrance_coef, extra, last_update_time）和多级缓存 + Fullload 机制？Plan bucket 计算公式（`bucket_id = pricing_type × 1e2 + layer_id × 1e1 + bucket_number`）？ |
| 23 | 出价配置管理：`online_config/global/` vs `online_config/global_update/` 的工作流？`debug/test_config/*.json` 的测试方法？Coef list（`[0.25, 0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0, 4.0]`）的用途？ |

**Non-Product Ads (`non-product-ads-bidding-kb.md` @ivan) — 5 问**

| # | 问题 |
|---|------|
| 24 | Shop/Video/Live Ads 各自的 eCPM 公式差异？Shop Ads Simple: `pCTR × pCVR × AOV / targetROAS × λ`；Live Max View Single Stream: `eCR × AOV / systemTargetROAS × λ`；Live Dual Stream: `pCTR × eCR × AOV / systemTargetROAS × λ`；Video Max View: `InitialCPM × (pVR/avgPVR) × λ`；Video Max GMV: `pCTR × pCVR × capItemPrice × avgSoldCount / targetROAS × λ`？ |
| 25 | 非商品卡广告在 API4（`ads_unified`）中的出价链路：Shop Ads（`shop_ads_retrieval → fetch_shop_ads_info → 14 filter types → rank_shop_and_items → fetch_bid_price`）、Live Ads（`recall_ls_ads_list → calc_ls_pre_rank → fetch_re_rank_coef → build_bid_ls_info`）的 operator 序列？ |
| 26 | 非商品卡广告的白名单控制（`sz_ads_roi2`, `sz_ads_live_stream_target_roas`, `sz_ads_live_gmv_max_target_roas`, `sz_ads_live_ads_gmv_max_simple`）及其配置方式？ |
| 27 | Dual Bidding 机制（`eCPM_shallow' = eCPM_shallow × ratio_shallow × λ_shallow`; `eCPM_deep' = eCPM_deep × ratio_deep × λ_deep`; `eCPM_final = f(eCPM_shallow', eCPM_deep') × I(pDVR ≥ threshold)`）在非商品卡广告中的应用？ |
| 28 | 非商品卡广告出价的冷启动策略和 Tag Service（`tag-service`）的 cold start tag 计算逻辑？ |

### 2.4 Traffic 流量策略 (`pacing-deduction.md` @xinyu) — 8 问

| # | 问题 |
|---|------|
| 29 | Pacing 四种方法：Hard Throttling（PTR）、Rank Deboost（alpha on ranking score，不影响计费）、Bid Shading（beta on bid，影响计费）、Lambda Integration 的原理和适用场景？ |
| 30 | 广告混排公式：`RankScore = alpha × eCPM + beta × OrgScore`；Product Ads: `rank_score = ecpm_weight × (ecpm + rank_boost) + porg`。alpha/beta 的配置方式和调优逻辑？ |
| 31 | GSP 计费公式：`actual_CPC_i = (RankScore_{i+1} - beta × OrgScore_i) / (alpha × pCTR_i) + delta`？Deduction bounds: `min_cap = bid × gfp_min_ratio; max_cap = min(GSP_price × gsp_max_ratio, bid); actual_charge = clip(GSP_price, min_cap, max_cap)`？ |
| 32 | 各广告类型的计费模型差异：Product Ads（GSP 多槽位 click-based，迁移中 impression）、Brand & Shop Ads（GFP 单槽位 click-based）、Video Ads（GSP 多槽位，明投=impression/暗投=click）、Live Ads（FP with rankcap & bidcap，明投=impression/暗投=click）？ |
| 33 | GMV Max pipeline 中广告与有机流量的 API0-API3 交互流程？API0: recall ↔ ads recall; API1: prerank ↔ ads info; API2: ranking ↔ bidding & strategy; API3: mix rank ↔ deduct & log？ |
| 34 | 流量扶持框架：Tag 系统（item_tag 64 bits offline + biz_tag 64 bits online）、参数配置（itemTagMask/bizTagMask/reserveQuotaRatio 5%-10%/pidBasedCoef/ruleBasedCoef）、配额保障（reserveQuotaRatio force-insert after pre-ranking）？ |
| 35 | Over Delivery 防控：API2 中 `over_delivery_filter` operator 的逻辑？超投检测和反作弊过滤（OVERDELIVERYANTIFRAUDFILTER）机制？ |
| 36 | 流量策略的 AB 实验设计：`adsengine-abtest-param` 仓库（300+ params）的参数注册方式？AB Platform（https://abtest.shopee.io/feature/42）的分流机制？ |

### 2.5 Voucher 广告智能优惠券 — 8 问

**Model (`model.md` @haibo) — 4 问**

| # | 问题 |
|---|------|
| 37 | ROI3（QCPX）vs ROI4（cofund）定义：ROI3 = Global GMV / (Ad cost + Voucher marketing cost)；ROI4 = 平台和商家共担券成本。两种模式的业务目标和适用场景？ |
| 38 | 发券 Uplift 因果推断模型：DragonNet 网络结构、多 treatment 建模方式、增量效果评估指标（AUUC）？Uplift 模型输出信号（`uplift_pcr0`, `uplift_ratio1-6`）如何转化为 `pCVR_i = uplift_pcr0 × uplift_ratio_i`？ |
| 39 | 发券模型的特征体系和 FSE 数据源？训练 pipeline（EGO 平台配置）？核心评估指标和 Guardrail 公式（`gmv_uplift/4 + advv_uplift - cost_uplift`）？ |
| 40 | Isotonic regularization 在 Uplift 模型中的应用？多 treatment 场景下券面额选择的建模方式？ |

**Strategy (`strategy.md` @roger) — 4 问**

| # | 问题 |
|---|------|
| 41 | 发券策略工程链路：voucher_profit 计算 → 选券 → 排序和计费（`addition_boost = voucher_profit` for ranking; `addition_deduction = uplift_advv` for billing）→ 后验收集和调控（`Rev_Coef = roi_coef × w_coef; GMV_Coef = roi_coef × (1 - w_coef)`）？ |
| 42 | 发券在 `online-bidding` DoRerank 中的集成位置（rerankVoucher 阶段）？与 bidding 阶段的交互逻辑？ |
| 43 | 发券 AB 实验分流方案和核心指标（券消耗量、ROI3/ROI4、增量 GMV、增量 advv）？ |
| 44 | 发券预算控制：日预算/总预算约束、券成本管理策略、与广告主 campaign budget 的关系？ |

### 2.6 Advertiser Strategy 广告主策略 — 6 问

**Advertiser Agent (`advertiser-agent.md` @youhe) — 2 问**

| # | 问题 |
|---|------|
| 45 | Advertiser Agent 的产品定义、核心功能（自动建计划/调价/选品/优化建议）、与 Seller Center 前端和 `ads_service` / `ultimate_ads_service` 后端的集成方式？ |
| 46 | Agent 的决策模型和推荐策略引擎：如何根据广告主历史数据和目标推荐投放策略？与 Tag Service（`tag-service`）的协同？ |

**Managed Mode (`managed-mode.md` @wangbo) — 2 问**

| # | 问题 |
|---|------|
| 47 | 托管投放的完整链路：Escrow 货款打通 → 自动 top-up（`topup` 服务）→ 自动建 campaign → 自动出价调控。各环节的系统实现和数据依赖？ |
| 48 | 托管投放的效果评估体系和与自主投放的 A/B 对比方法？平台代决策（选品/出价/预算分配）的算法逻辑？ |

**Subsidy & Boost (`subsidy-boost.md` @youhe) — 2 问**

| # | 问题 |
|---|------|
| 49 | 广告主增长激励策略：新客激励/复投激励/冷启动扶持的实现方式？与 Tag Service 的 tag 计算（cold start / ROI / budget tags）的集成？ |
| 50 | 补贴 ROI 衡量方式、广告主分层策略和差异化运营的数据依赖？ |

---

## 四、工程层 100 问/Engineering Layer Questions

### 3.1 Ads Engine 广告引擎 (`3.1-ads-engine/kb.md`) — 10 问

| # | 问题 |
|---|------|
| 51 | `ads-engine` 仓库整体架构：5 个 API Handler（`ads_recall / ads_info / bid_info / deduction / ads_unified`）的职责划分？入口代码路径（`ads-engine/server/ads_engine/main.go`）？ |
| 52 | Graph Engine（`graph-engine` Go package）DAG 编排系统：`graphmanager.GetGraph("adsengine", graphName)` 调用方式？Graph Manager Portal（https://graphmanager.shopee.io/）的使用？DAG 配置中心（`graph-manager-conf`：10 subsystems, 50+ pipelines）？ |
| 53 | Operator 框架：`IBaseOperator` 接口（`IsAvailable / Run / Execute`）和 `BaseOperator` 封装？`IRequestContext` 请求上下文？Operator 目录结构（`product_ads/` 62个, `shop_ads/` 36+个, `brand_max_ads/` 10个, `ls_ads/` 34个）？ |
| 54 | API0（Ads Recall）完整 operator 序列：`build_option → req_experiment → recall → relevance → fetch_prerank_score → calc_prerank_score → 各 filter → ad_plan_experiment → ads_info_supplement(FSE) → fetch_prerank_bid`？ |
| 55 | API2（Bid Info）完整 operator 序列：`build_option → set_creative → uni_pcr(DAO) → call_online_bidding / fetch_bid_coef → calc_ecpm(CPC) / calc_cpm(CPM) → over_delivery_filter`？ |
| 56 | API3（Deduction）完整 operator 序列：`ack → cal_deduction_price(CPC) → cal_cpm_deduction_price → build_deduction_info → build_cpm_deduction_info → full_link_log`？ |
| 57 | API4（Ads Unified）各广告类型 operator 序列和 SERVICE_TAG 注册（`master / brand_max / shop / ls`）？ |
| 58 | DAO 层架构：`EngineDao`（22 sub-DAOs）和 `ExtraDao`（21 sub-DAOs）的职责划分？各 DAO 对应的下游服务调用？ |
| 59 | Engine 配置管理：`ads-engine/config/`（test / liveish / live + dynamic config）和 `adsengine-abtest-param`（300+ params）的结构？ |
| 60 | Engine 性能指标（延迟 P99、QPS、CPU 利用率）的监控方式？Engine SPEX 接口定义（https://rap.shopee.io/spex/api_namespaces?apiId=464315）？ |

### 3.2 Ads Recall Service 召回服务 (`3.2-ads-recall/kb.md`) — 6 问

| # | 问题 |
|---|------|
| 61 | `paidads-recall` 仓库架构：8+ 召回场景的代码组织？与 `ads-engine` API0 handler 的 RPC 交互协议？ |
| 62 | Vespa 索引管理：`paidads-schema` 仓库中的 schema 定义？Content Ads 60+ schemas / Product Ads 130+ schemas 的分 country 设计？schema 字段增删改流程？ |
| 63 | OhMyEmb（`oh-my-embedding`）服务架构：Cache Syncer（`tools/cache_syncer`）的数据同步机制？embedding 更新频率和实时性保障？ |
| 64 | 召回服务的 SDU 部署拓扑（哪些 region/IDC 部署了哪些实例）？Space 服务树路径？Vespa 集群的容量和分片策略？ |
| 65 | 召回服务的 Grafana 监控 dashboard：Vespa QPS/延迟/资源利用率、各队列召回量、embedding 更新延迟？关键告警指标和阈值？ |
| 66 | 召回服务的发版流程（CI/CD pipeline、灰度策略、回滚方法）和 ConfigCenter namespace 配置？ |

### 3.3 Ads Bidding Service 出价服务 (`3.3-ads-bidding/kb.md`) — 8 问

| # | 问题 |
|---|------|
| 67 | `online-bidding` 仓库架构：entry point（`internal/handler/product_ads.go`）、5 种广告类型的 rerank/prerank/rank API？与 `ads-engine` API2 的 RPC 交互？ |
| 68 | `ultrav-core-timewindow` 三大组件：Trigger（realtime: imp/click/order; batch: periodic full ads）、Agent（bidding strategies）、Output（Redis + logs）的实现？MPC/target2/simple2/P2P hourly/pcoc 策略的代码组织？ |
| 69 | `ultrav-data-processor` 实时事件处理：Kafka consumer 配置（`AdvancedConsumer, Dispatcher=Random, WorkerNum=1000, RateLimitPerSecond=5000`）？event handler entry（`pkg/handler/event_handler.go`）？ |
| 70 | UltraV Redis 数据模型：key 格式（`METRIC_ORDER_20250520_6-1-2-3-0(47689239-MY-1-40-AD)`）、value 含义、time window 类型（history/date/hour/minute/quarter/every_minute）？Redis operation types（COUNT/SCALAR/HASH/FEEDBACK）？ |
| 71 | `bidding-store` 多级缓存架构和 Fullload 机制？proto 输出结构（`TimeSlot2X` organized by `slot → coef → predict values`）？Redis 输出 key 格式（`<model_prefix>_<placement>_<country>_<entrance>_<adsId>`）？ |
| 72 | HyperX（`hyperx`）超参数自动实验平台：Flink 实时 coef 计算？与 bidding 服务的集成？ |
| 73 | BEM 环境模型：statistical (stats) / deep (Transm, EncDec, WinRatioEncDecNoAutoRegressive, cost_gmv_v1, DLinearReq) / function model 三类模型的适用场景？FuncModel 预测公式（`cost = FeatureCost × (coef/FeatureCoef)^exponent`）？ |
| 74 | Bidding Service 的 output writers（`output_redis / output_databus / output_kafka_producer`）和 hot key 处理（9-10 second local buffer before Redis write）？ |

### 3.4 Ads Index 广告索引 (`3.4-ads-index/kb.md`) — 6 问

| # | 问题 |
|---|------|
| 75 | `paidads-indexer` 和 `paidads-graph-indexer`（Graph Engine DAG 版）的架构对比？Kafka → Vespa 的索引构建 pipeline？ |
| 76 | AdsInfo 服务（`paidads-valar`）：3 个 API（multi-dim query / incremental change / full load）的接口定义？peak QPS ~300K（`paidads.valar.get_campaign_balance_summary`）的性能保障？ |
| 77 | AdsInfo Protobuf 数据结构：`AdsInfo` message 核心字段（ads_id, item_id, campaign_id, shop_id, placement + 嵌套 Advertisement/Item/Campaign/Shop/Account/Tracing/BoostAds/LiveStreamAds/BrandSearchAds/VideoAds/Voucher）？`GetAdsInfoIdentifier` 查询维度？ |
| 78 | Ad Entity 层级结构：L1 Ad Account → L2 Campaign（budget, bidding mode, TROI）→ L3 Ad Unit（Ads）→ L4 Delivery Vehicle。各层级的状态管理和生命周期？ |
| 79 | `paidads-gdsclient`（GDS binlog consumer）：DB changes → ads index bridge 的数据流？新广告 500ms 内进入 ad pool 的实时性保障机制？ |
| 80 | SuperKIA（`paidads-superkia`）统一特征平台：实时特征 R/W SDK 的使用方式？与 FSE 的关系和职责划分？ |

### 3.5 Ads Data 广告数据 (`3.5-ads-data/kb.md`) — 8 问

| # | 问题 |
|---|------|
| 81 | `paidads-tracking` 事件追踪服务：FE 埋点 → tracking → 反作弊处理 → Kafka 的完整链路？tracking Kafka topic（`shopeeads{cid}live`）的消费方？ |
| 82 | `paidads-deduction` 在线计费引擎：CPC/CPM 二价计费的实现？Kafka topic（`shopeeadsdeduction{country}live / shopeeadscpmdeduction{country}live`）的数据结构？ |
| 83 | `paidads-report-ng` 报表服务：Redis + Pika 3 层存储架构？report Kafka topic（`shopeeadsreportevent{country}live` / display / livestream 变体）？ |
| 84 | 完整数据 pipeline 六条流：① imp/click/atc(FE→tracking→reporter→hive)、② deduct click(FE→tracking→deduction→reporter→hive)、③ place order(ads db→gds→ads resharder→reporter→hive)、④ cps order(order db→gds→ads resharder→reporter→deduction→reporter→hive)、⑤ paid order(order db→gds→order-data-push→reporter→hive)、⑥ pre-deduction(`paidadsdeductevent{country}live`)？ |
| 85 | Order Attribution 实现：Redis 中 `itemid+userid` key 的 7-day click attribution；broad attribution via `shopid+userid`。归因优先级（Click > View, Last Touch）的代码实现？ |
| 86 | 核心 Hive 表清单和用途：`odslogadstracking_hi`、`dwdadvertisetrackingitem_hi`、`odslogtranslogevent_hi`、`odslogadsreport_hi` 等 ODS/DWD/DWS 层表的数据含义和查询场景？ |
| 87 | Kafka topic 全景：tracking / deduction / translog / order / addtocart / report / imp batch / pre-deduction 共 10+ topic 的完整列表、数据格式和消费方？ |
| 88 | 数据质量检查（DQC）：计费一致性检查（多扣/少扣/不扣）、索引字段质量检查、模型数据 DQC 的机制和告警？ |

---

## 五、平台层 100 问/Platform Layer Questions

### 4.1 Platform FE 平台前端 (`4.1-platform-fe/kb.md`) — 6 问

| # | 问题 |
|---|------|
| 89 | 广告平台前端产品矩阵：Seller Center Shopee Ads / Ads Admin / BD Centre CRM / SRM / MCN 各自的功能定位和用户角色？ |
| 90 | 各广告类型的创建流程和核心交互：Product Ads（标准自动出价/手动出价/全站推广 GMV Max/CPS/新品推广/潜力品）、Shop Ads（基本设置/竞价/创意）、Brand Ads（Search Brand/Homepage Banner）、Live Ads（Boost GMV/Boost Views）、Video Ads 的前端流程和状态机？ |
| 91 | GMV Max 全站推广前端：自动出价 vs 自定义 ROAS 两种模式的 UI 差异？迁移流程的前端实现？版位展示（Search / DD / YMAL）？ |
| 92 | APP 端功能：账户及充值、报表查询、Product/Live/Video Ads 的移动端创建和管理流程？ |
| 93 | Seller 账号体系：主子账号平台和 Access Control 权限控制的前端实现？ |
| 94 | 前端核心代码仓库、技术栈和 AB 实验/灰度发布机制？ |

### 4.2 Platform BE 平台后端 (`4.2-platform-be/kb.md`) — 6 问

| # | 问题 |
|---|------|
| 95 | `ads_service`（Core API gateway）和 `ultimate_ads_service`（Core management service）的职责划分？full ad CRUD & batch ops 的 API 设计？ |
| 96 | `ads-status-syncer` 状态一致性守护进程：18 种 CDC event types？DB → 索引 → 投放状态的一致性保障机制？ |
| 97 | `topup` 充值服务：manual/auto/package 三种充值模式的实现？与 Escrow 货款打通的集成？ |
| 98 | `tag-service` 业务标签计算：cold start / ROI / budget 等 tag 的计算逻辑？item_tag（64 bits offline）和 biz_tag（64 bits online）的位设计？ |
| 99 | 广告生命周期状态机：创建 → 审核 → 投放 → 暂停 → 结算 → 下线的完整状态流转？核心数据结构和 DB schema？Campaign budget management 的实现（L2 Campaign 层 budget/bidding mode/TROI）？ |
| 100 | 平台后端的 SDU 部署拓扑、Space 服务树路径、Grafana 监控和发版流程？ |

---

## 六、KB 编写指南/KB Writing Guide

### 问题设计原则/Design Principles

1. **业务-系统-代码三层覆盖**：每个模块同时覆盖业务逻辑、系统架构和代码实现
2. **可执行性**：问题中嵌入了已知的代码路径/仓库名/公式/配置项，KB 作者可以直接验证和补充
3. **Agent 可用**：每个问题对应 `ads-knowledge-qa` / `ads-diagnose` / `ads-experiment-analyze` 等 Agent 的高频 query
4. **可验证**：KB 作者填写后，可让 Agent 回答这些问题来验收 KB 质量

### 建议编写流程/Recommended Workflow

1. **骨架填充**：Owner 逐条回答本清单中自己模块的问题，利用已嵌入的代码路径和公式作为骨架
2. **参考模板**：参考已有高质量 KB：
   - `docs/team/04.product-algo/model-algo/knowledge/cali-kb.md` — slot-level 精度，exhaustive mapping tables
   - `docs/team/04.product-algo/bidding-algo/temp/xinyu.zhou/Kb/bidding-kb.md` — Business/Technical/Engineering 三分法
   - `docs/team/04.product-algo/bem-algo/bem-kb/bem_knowledge_template.md` — 全生命周期覆盖 + YAML frontmatter
3. **Smoke Test**：用 `ads-knowledge-qa` Agent 测试 KB 回答质量
4. **迭代补充**：收集 Agent 无法回答或回答不准确的问题，补充知识
5. **必要内容检查**：确保每个 KB 包含：
   - 代码仓库 GitLab 路径
   - 核心服务 SDU 路径
   - ConfigCenter namespace
   - Grafana dashboard 链接
   - 关键 Kafka topic
   - 核心 Hive 表名

### 验证方式/Verification

- 对每个 sub-kb 文件，使用其对应问题作为 eval prompt
- 目标：每个模块的问题回答准确率 ≥ 80%
- 重点验证系统/代码层面的回答是否包含具体的仓库路径、代码文件、配置项

### 核心代码仓库速查/Key Repository Reference

| 仓库 | 路径 | 用途 |
|------|------|------|
| ads-engine | `shopee/deep/ads-engine` | 广告引擎，5 个 API via Graph Engine |
| online-bidding | `shopee/deep/paidads-bidding/online-bidding` | 实时出价与精排 |
| paidads-recall | `shopee/deep/paidads-recall` | 多场景召回 |
| bidding-store | `shopee/deep/paidads-bidding/bidding-store` | 高并发系数查询 |
| ultrav-core-timewindow | `shopee/deep/paidads-bidding/ultrav-core-timewindow` | 新一代出价与校准引擎 |
| ultrav-data-processor | `shopee/deep/paidads-bidding/ultrav-data-processor` | 实时事件处理 |
| hyperx | `shopee/deep/HyperX-config` | 超参数自动实验 |
| paidads-indexer | `shopee/deep/paidads-indexer` | 广告索引构建 |
| paidads-graph-indexer | `shopee/deep/indexer/paidads-graph-indexer` | DAG 版索引构建 |
| paidads-schema | `shopee/deep/paidads-schema` | AdsInfo & Vespa schema 定义 |
| paidads-valar | `shopee/deep/paidads-valar` | AdsInfo 集中存储与查询 |
| paidads-tracking | `shopee/deep/paidads-tracking` | 事件追踪 |
| paidads-deduction | `shopee/deep/paidads-deduction` | 在线计费引擎 |
| paidads-report-ng | `shopee/deep/paidads-report-ng` | 新一代报表服务 |
| paidads-superkia | `shopee/deep/paidads-superkia` | 统一特征平台 |
| oh-my-embedding | `shopee/deep/oh-my-embedding` | 统一向量召回 |
| scoringX | `shopee/deep/scoringX` | 在线 CTR/CR scoring |
| ads_service | `shopee/deep/ads_service` | 核心业务 API 网关 |
| ultimate_ads_service | `shopee/deep/ultimate_ads_service` | 核心管理服务 |
| tag-service | `shopee/deep/tag-service` | 业务标签计算 |
| ads-status-syncer | `shopee/deep/ads-status-syncer` | 状态一致性守护 |
| paidads-gdsclient | `shopee/deep/paidads-gdsclient` | GDS binlog 消费 |
| topup | `shopee/deep/topup` | 充值服务 |
| adsengine-abtest-param | `shopee/deep/adsengine-abtest-param` | AB 参数注册（300+ params） |
| graph-manager-conf | `shopee/deep/searchads/graph-manager-conf` | DAG 配置中心 |
| graph-engine | `shopee/deep/searchads/graph-engine` | Go DAG 解析引擎 |
