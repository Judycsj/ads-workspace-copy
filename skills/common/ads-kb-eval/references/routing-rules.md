# 路由规则/Routing Rules

本文件定义 `ads-kb-eval` 技能的问题到文件路由规则。

---

## 路由优先级/Routing Priority

按以下顺序匹配，**优先匹配靠前的 section**：

1. **§2.1 核心知识索引** — 广告业务知识的权威来源
2. **§2.2 DPM 核心知识** — DPM 模块和项目知识
3. **§2.3 代码仓库 README** — 服务架构和代码实现细节
4. **§2.4 数据表参考** — 数据表结构和查询模式
5. **§2.5 Workspace 使用指南** — 工具使用和开发环境
6. **§2.6 团队信息与 SOP** — 流程规范和入职

---

## 路由算法/Routing Algorithm

### Step 1: 关键词提取

从问题文本中提取领域关键词：
- 业务词：recall, bidding, ranking, pacing, voucher, ROI, CTR, CVR, pGMV, 召回, 出价, 混排, 计费
- 系统词：engine, indexer, vespa, redis, kafka, DAG, serving, EGO, OhMyEmb
- 服务名：ads-engine, online-bidding, ultrav-core, paidads-recall, paidads-tracking
- 产品词：product ads, shop ads, live ads, video ads, brand ads, GMS, BrandMax
- 数据词：Hive, 表, table, column, tracking, attribution, deduction
- 平台词：前端, 后端, frontend, backend, platform, seller center
- 工具词：DataSuite, AB 实验, Grafana, EGO, workspace, skill

### Step 2: 主题分类

| 主题      | 关键词模式                                                      | 主路由                  |
| ------- | ---------------------------------------------------------- | -------------------- |
| 广告概览/基础 | 广告生态, 指标体系, 归因模型, 系统链路, GSP                                | §2.1 (1.x files)     |
| 召回策略    | recall, 召回, 双塔, KNN, 队列, OhMyEmb, 特征 slot                  | §2.1 (2.1 file)      |
| 排序模型    | CXR, pGMV, UniCR, CTR, CVR, calibration, 校准                | §2.1 (2.2 file)      |
| 出价算法    | bidding, 出价, ROI, MPC, bid2cost, tROI, ECPC                | §2.1 (2.3 file)      |
| 流量计费    | pacing, 扶持, 混排, 计费, boost, budget                          | §2.1 (2.4 file)      |
| 智能优惠券   | voucher, 优惠券, ROI3, ROI4, uplift                           | §2.1 (2.5 file)      |
| 广告主策略   | suggest ROI, 选品, advertiser, agent                         | §2.1 (2.6 file)      |
| 系统架构    | 架构总览, 仓库列表, 核心服务, microservice                             | §2.1 (3.1 file)      |
| 广告引擎    | engine, API0-API3, 广告引擎, 接口                                | §2.1 (3.2 file)      |
| 召回服务    | recall 服务, recall DAG, operator, Vespa serving, paidads-recall | §2.1 (3.3 file)   |
| 出价服务    | bidding 服务, online-bidding, ultrav, Tag Service, 投放链路       | §2.1 (3.4 file)      |
| 索引服务    | indexer, AdsInfo, Vespa 索引, schema, protobuf                | §2.1 (3.5 file)      |
| 数据服务    | 广告数据服务, tracking 服务, deduction 服务, attribution 服务          | §2.1 (3.6 file)      |
| 服务实现    | 代码, 仓库, repo, service, API                                 | §2.3 (README files)  |
| 数据表     | Hive, table, column, SQL, 表字段                              | §2.4 (DataMap files) |
| 数仓体系    | 数仓, 分层, ODS, DWD, DWS, DIM, ADS, 命名规范, 核心表                 | §2.1 (5.1 file)      |
| 维度与指标   | 维度, 指标, CTR, ROAS, Take Rate, CPC, CPM, GMV 口径             | §2.1 (5.2 file)      |
| 埋点与归因   | tracking, 埋点, attribution, 归因, TMS, Direct/Broad order     | §2.1 (5.3 file)      |
| 计费与扣费   | billing, deduction, 计费, 扣费, topup, 充值, revenue, rebate, 赔付 | §2.1 (5.4 file)      |
| 报表与交付   | seller report, 卖家报表, data delivery, GMV 对账, Take Rate 分析   | §2.1 (5.5 file)      |
| 工具环境    | workspace, skill, Claude Code, EGO, DataSuite              | §2.5 (How-To files)  |
| 团队流程    | 入职, 上线, 值班, OKR, SOP, PIC                                  | §2.6 (SOP files)     |
| DPM     | tracking 埋点, deduction 计费, OA 归因, seller report            | §2.2 (DPM files)     |

### Step 2.5: 策略 vs 工程歧义消解

当问题同时命中策略主题（2.x 文件）和工程信号词时，需要消解歧义决定主路由。

**工程信号词**（命中任一则倾向工程路由）：

| 信号类别 | 关键词                                                        |
| ------ | ---------------------------------------------------------- |
| DAG/算子 | DAG, operator, op, YAML, yaml, 算子, 节点配置                    |
| 服务链路   | 投放链路, serving 链路, service 链路, 在线服务, 线上链路                  |
| 代码实现   | 仓库, repo, 代码, code, 代码路径, 实现, 白名单, feature toggle, 开关    |
| 索引存储   | schema, protobuf, field, 字段来源, 索引规模                       |
| 运维监控   | 集群利用率, 耗时, latency, QPS, Grafana, 监控面板, dashboard         |
| Debug  | debug SOP, 排查, troubleshoot, 日志, log                       |

**消解规则**：
1. **策略关键词 + 工程信号词** → 主路由: 工程文件，辅路由: 策略文件
2. **纯策略关键词**（无工程信号词）→ 维持策略路由
3. **纯工程关键词** → 工程文件

**领域→工程文件映射**：

| 领域关键词                    | 策略文件（降为辅路由） | 工程文件（升为主路由） |
| ------------------------ | ------------- | ------------- |
| 召回, recall               | 2.1 召回策略      | 3.3 召回服务      |
| 出价, bidding              | 2.3 出价算法      | 3.4 出价服务      |
| 索引, index, Vespa         | 2.1 召回策略      | 3.5 索引        |
| 数据, tracking, deduction  | —             | 3.6 数据        |
| 引擎, engine, API          | —             | 3.2 引擎        |

**示例**：
- "广告召回在 API0 pipeline 中的执行位置？DAG 各包含哪些 operator" → "召回" + "DAG operator"（工程信号词）→ 主路由 3.3 召回服务，辅路由 2.1 召回策略
- "shop ads 的投放链路是怎样的" → "投放链路"（工程信号词）→ 主路由 3.2/3.4 工程文件
- "召回双塔模型的训练范式是什么" → "召回" + "双塔训练"（纯策略关键词）→ 维持主路由 2.1 召回策略

### Step 3: 文件匹配

对每个主题，匹配 Summary 描述中的关键词命中数。取命中数最高的 1-5 个文件。

### Step 4: 多文件路由

一个问题可能路由到多个 section 的文件：
- 策略 + 工程：如 "召回服务的 DAG 架构" → §2.1 (2.1 策略) + §2.1 (3.3 工程) + §2.5 (paidads-recall README)
- 策略 + 数据：如 "ROI3 指标表" → §2.1 (2.5 voucher) + §2.3 (DataMap ROI3 表)
- 最多路由 5 个文件

---

## 完整文件映射表/Complete File Mapping

### §2.1 核心知识索引 (25 files)

路径前缀: `docs/common/core-knowledge/`

| 编号 | 文件路径 | 关键词 |
|------|---------|--------|
| 1.1 | `01.ads-overview/01.preface.zh-CN.md` | 前言, 导读, 知识库架构 |
| 1.2 | `01.ads-overview/02.online-advertising-fundamentals.zh-CN.md` | 广告生态, 指标体系, 归因模型, CTR, CVR, CPC, CPM |
| 1.3 | `01.ads-overview/03.system-pipeline-modules.zh-CN.md` | 系统链路, 端到端, 召回-排序-混排 pipeline |
| 1.4 | `01.ads-overview/04.strategy-mechanisms.zh-CN.md` | 出价机制, 混排, 计费, GSP |
| 1.5 | `01.ads-overview/05.ecommerce-business-characteristics.zh-CN.md` | 电商广告, 业务特性 |
| 1.6 | `01.ads-overview/06.shopee-paid-ads-overview.zh-CN.md` | Shopee 广告, 产品类型, Product/Shop/Live/Video/Brand Ads |
| 2.1 | `02.ads-strategy/01.recall-and-supply-strategy.zh-CN.md` | recall, 召回, 双塔, KNN, 队列, 特征, OhMyEmb, DAG, 降级, filter |
| 2.2 | `02.ads-strategy/02.cxr-pgmv-models-and-calibration.zh-CN.md` | CXR, pGMV, UniCR, CTR, CVR, calibration, 样本, label, 特征 |
| 2.3 | `02.ads-strategy/03.bidding-products-and-algorithms.zh-CN.md` | bidding, 出价, ROI, MPC, Bid2X, BEM, 冷启动, tROI, ECPC, GMS |
| 2.4 | `02.ads-strategy/04.traffic-strategy-and-billing.zh-CN.md` | pacing, 扶持, boost, 混排, 计费, budget |
| 2.5 | `02.ads-strategy/05.ads-smart-voucher.zh-CN.md` | voucher, 优惠券, ROI3, ROI4, uplift, 发券 |
| 2.6 | `02.ads-strategy/06.advertiser-strategy.zh-CN.md` | 广告主, suggest ROI, suggest budget, 选品, agent |
| 3.1 | `03.ads-engine/01.system-architecture-overview.zh-CN.md` | 系统架构, 仓库列表, 核心服务 |
| 3.2 | `03.ads-engine/02.ads-engine.zh-CN.md` | engine, API 接口, 广告引擎 |
| 3.3 | `03.ads-engine/03.ads-recall-service.zh-CN.md` | recall 服务, DAG, Vespa, Redis |
| 3.4 | `03.ads-engine/04.ads-bidding-service.zh-CN.md` | bidding 服务, online-bidding, ultrav |
| 3.5 | `03.ads-engine/05.ads-index.zh-CN.md` | indexer, AdsInfo, Vespa 索引 |
| 3.6 | `03.ads-engine/06.ads-data.zh-CN.md` | 广告数据, tracking, attribution, deduction |
| 4.1 | `04.ads-platform/01.platform-frontend.zh-CN.md` | 前端, frontend, 模块联邦, pas-* |
| 4.2 | `04.ads-platform/02.platform-backend.zh-CN.md` | 后端, backend, ads_service, UAS, GMS |
| 5.1 | `05.ads-data/01.data-warehouse-overview.zh-CN.md` | 数仓, 分层, ODS, DWD, DWS, DIM, ADS, 命名规范, 核心表 |
| 5.2 | `05.ads-data/02.key-dimensions-and-metrics.zh-CN.md` | 维度, 指标, CTR, ROAS, Take Rate, CPC, CPM, GMV 口径, impression, click |
| 5.3 | `05.ads-data/03.tracking-and-attribution.zh-CN.md` | tracking, 埋点, attribution, 归因, TMS, Direct, Broad, Agent, 去重 |
| 5.4 | `05.ads-data/04.billing-and-deduction.zh-CN.md` | billing, 计费, deduction, 扣费, topup, 充值, revenue, 收入, rebate, 赔付, CPC, CPM, OCPM |
| 5.5 | `05.ads-data/05.seller-reporting.zh-CN.md` | seller report, 卖家报表, data delivery, 数据交付, GMV 对账, Take Rate |

### §2.2 DPM 核心知识 (15 files)

路径前缀: `docs/team/20.paid-ads-dpm/ads_knowledge_base/`

| 文件路径 | 关键词 |
|---------|--------|
| `module/ads_tracking_cn.md` | Ads Tracking, 埋点 |
| `module/auto_rebate_cn.md` | 赔付, rebate |
| `module/data_delivery_cn.md` | 数据交付 |
| `module/deduction_cn.md` | 计费, 去重, 预扣费, 离线扣费 |
| `module/new_tms_tracking_cn.md` | New TMS, 埋点参数 |
| `module/oa_cn.md` | 订单归因, OA |
| `module/seller_center_tracking_cn.md` | Seller Center 埋点 |
| `module/seller_report_cn.md` | 卖家报表 |
| `project/Auto Escrow & GMS/auto-top-up-from-order-escrow-data-story.md` | Auto Top-up, Escrow, GMV |
| `project/Smart Voucher/roi3_knowledgebase_v2.md` | ROI3 券, QCPX, Uplift |
| `shared/alias-dictionary_cn.md` | 标准别名, alias |
| `shared/common-concept-dictionary_cn.md` | 通用概念 |
| `shared/common-dimension-dictionary_cn.md` | 通用维度 |
| `shared/common-metric-dictionary_cn.md` | 通用指标 |
| `shared/guides/gmv-reconciliation-guide_cn.md` | GMV 口径, 对账 |

### §2.3 代码仓库 README (56 files)

路径前缀: `docs/common/readme/`，每个仓库一个目录，含 `README.zh-CN.md`。

按服务匹配：问题中提到的服务名 → 对应仓库目录。

| 分类 | 仓库 |
|------|------|
| 广告引擎 | ads-engine, paidads-recall, feature-server |
| 出价服务 | online-bidding, ultrav-core, ultrav-core-timewindow, ultrav-data-aggregator, ultrav-data-processor, bidding-store, bidding-store-cpp, bid-sense, boost-support-service, campaign, tag-service |
| 索引服务 | paidads-graph-indexer, paidads-gdshub, paidads-ads-info-gateway, paidads-valar, ads-status-syncer, ads-derived-data-service |
| 数据服务 | paidads-tracking, paidads-report-ng, paidads-attribution-service, paidads-oa-processor, paidads-deduction, paidads-offline-deduction, ads-account-balance, ads-resharder |
| 平台后端 | ads_service, ultimate_ads_service, ads-marketing, ads-booking-service, ads-db-lib, keyword-manager, recommend-keyword-v3, sku-selector, oh-my-embedding, sequence-model-processor, paidadsbackendadmin, ads-crm, ads-srm, uber-srm, auto-rebate, auto-topup, topup |
| 平台前端 | pas-index, pas-product, pas-shop, pas-display, pas-livestream, pas-mcn, pas-common-vue3, ads-remote, paid_ads_admin |
| 工具 | ads-platform-quick-debug-bot |

### §2.4 数据表参考 (13 tables)

路径前缀: `docs/common/datamap/`

| 表名 | 目录 | 关键词 |
|------|------|--------|
| `dwd_advertise_performance_di` | `mp_paidads.dwd_advertise_performance_di__reg_s0_live/` | 广告效果明细, 日分区 |
| `dws_advertise_performance_1d` | `mp_paidads.dws_advertise_performance_1d__reg_s0_live/` | 广告效果日聚合 |
| `ads_advertise_take_rate_v2_1d` | `mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live/` | 广告费率 |
| `dws_advertise_item_performance_1d` | `mp_paidads.dws_advertise_item_performance_1d__reg_s0_live/` | 商品维度效果 |
| `dws_advertise_user_exp_common_feature_performance_1d` | `mp_paidads.dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live/` | 用户实验特征效果 |
| `ads_advertiser_mkt_1d` | `mp_paidads.ads_advertiser_mkt_1d__reg_s0_live/` | 广告主营销日报 |
| `ads_advertise_mkt_1d` | `mp_paidads.ads_advertise_mkt_1d__reg_s0_live/` | 广告营销日报 |
| `ads_campaign_valid_budget_1d` | `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live/` | Campaign 有效预算 |
| `dwd_advertise_tracking_item_hi` | `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live/` | Tracking 明细 |
| `index_ads_info_log` | `mkplpaidads_data.index_ads_info_log/` | 索引日志 |
| `ads_roi3_strategy_algo_metrics_1d` (Hive) | `mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live/` | ROI3 策略算法指标 |
| `ads_roi3_strategy_algo_metrics_clickhouse_1d` (CK) | `mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live/` | ROI3 策略算法指标 ClickHouse |
| `dws_user_item_feature_sales_funnel_metrics_1d` | `traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live/` | 流量漏斗指标 |

每张表包含: `table_info.md`（概述）、`column_info.md`（字段详情），部分有 `sql_patterns.md`。

### §2.5 Workspace 使用指南 (30 files)

路径前缀: `docs/team/00.paid-ads-dev/04.how-tos/`

| 文件路径 | 关键词 |
|---------|--------|
| `01.getting-started/01.cc-and-codex-setup.md` | Claude Code, CodeX, 安装, 配置 |
| `01.getting-started/02.workspace-quickstart.md` | workspace, 快速入门, 克隆 |
| `02.knowledge-and-data/01.knowledge-qa.md` | 知识问答, knowledge QA |
| `02.knowledge-and-data/02.knowledge-compile.md` | 知识入库, compile, Hive 元数据 |
| `03.okr-planning-and-execution/01.project-planning.md` | OKR, 项目规划, Epic TD |
| `03.okr-planning-and-execution/02.daily-execution-and-memory.md` | 日常执行, 项目记忆, memory |
| `03.okr-planning-and-execution/03.progress-reporting-and-meeting.md` | 进展报告, 会议, report |
| `04.cross-team-requirement/01.cross-team-requirement.md` | 跨团队, cross-team |
| `05.analysis-and-diagnosis/01.data-analysis.md` | 数据分析, SQL, 自然语言 |
| `05.analysis-and-diagnosis/02.experiment-and-rollout.md` | AB 实验, 全量, rollout |
| `05.analysis-and-diagnosis/03.ads-case-diagnosis.md` | 诊断, 曝光异常, 花费异常 |
| `05.analysis-and-diagnosis/04.biz-anomaly-attribution.md` | 大盘异动, 归因, anomaly |
| `06.development-and-research/01.be-code-gen.md` | BE 代码生成, TRD |
| `06.development-and-research/02.platform-code-gen.md` | Platform 代码生成, Figma |
| `06.development-and-research/03.auto-research.md` | 自动化研究, EGO Job |
| `07.quality-and-reliability/01.realtime-loss-prevention.md` | 资损防控, 实时检测 |
| `07.quality-and-reliability/02.data-consistency.md` | 在离线一致性, 数据巡检 |
| `07.quality-and-reliability/03.index-field-quality.md` | Index 字段质量 |
| `07.quality-and-reliability/04.model-dqc.md` | 模型 DQC, 样本质量 |
| `07.quality-and-reliability/05.resource-management.md` | 资源管理, Redis, Kafka |
| `08.workspace-tool/01.meeting-workflow.md` | 会议, 纪要, meeting |
| `08.workspace-tool/02.commit-and-publish.md` | 提交, GitLab, MR, Google Docs |
| `09.skill-contribution/01.skill-contribution.md` | 技能创建, SKILL.md |
| `20.dev-environment/01.dev-env-setup.zh-CN.md` | 研发环境, Mac, VPN, Git |
| `20.dev-environment/02.ego-jobs.zh-CN.md` | EGO, 训练平台, Job |
| `20.dev-environment/03.data-studio.zh-CN.md` | Data Studio, 数据分析 |
| `20.dev-environment/04.ab-experiment.zh-CN.md` | AB 平台, 实验创建 |
| `20.dev-environment/05.datasuite-monitoring.zh-CN.md` | DataSuite, 定时任务, 监控 |
| `20.dev-environment/06.google-workspace.zh-CN.md` | Google Workspace, 文档管理 |
| `20.dev-environment/07.ads-biz-metrics.zh-CN.md` | 指标看板, metrics dashboard |

### §2.6 团队信息与 SOP (11 files)

路径前缀: `docs/team/00.paid-ads-dev/`

| 文件路径 | 关键词 |
|---------|--------|
| `01.team-info/01.email-list.md` | 团队成员, 邮箱, leader |
| `02.onboarding/01.onboarding-todos.zh-CN.md` | 入职, 待办, onboarding |
| `02.onboarding/02.onboarding-entry-task.zh-CN.md` | Entry Task, 入门任务 |
| `03.sop/01.okr-sop.md` | OKR 规范, KP 类型 |
| `03.sop/02.release-process.zh-CN.md` | 上线流程, 发版 |
| `03.sop/03.hdfs-management.zh-CN.md` | HDFS, 小文件合并 |
| `03.sop/04.campaign-on-duty.zh-CN.md` | 大促值班, 监控 |
| `03.sop/05.code-repo-management.zh-CN.md` | 代码库管理, 分支规范 |
| `03.sop/06.handover.zh-CN.md` | 项目交接, 离职 |
| `03.sop/07.attendance.zh-CN.md` | 出勤, 请假 |
| `03.sop/08.performance-career-development.zh-CN.md` | 绩效, 晋升 |
