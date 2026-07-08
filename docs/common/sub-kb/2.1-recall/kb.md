---
id: ads_recall_overview
title: Ads Recall 总览
domain: recall
owner: Recall Engineering / Recall Strategy
source_refs:
  - https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=451255125#gid=451255125
  - https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=1667042420#gid=1667042420
  - https://docs.google.com/spreadsheets/d/1NaFd2L61WLKti4_DLowNBRyxQL5RQU7O7boy5P57pmw/edit?gid=1498984967#gid=1498984967
  - https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk/edit?gid=65057492#gid=65057492
  - https://docs.google.com/document/d/1sxfoqsG2tkBXw_NRn27Cfjffg29M5O-dKtSN2X7Z-jA/edit
  - https://docs.google.com/document/d/10hKfxxEOKyowtJc1jd4CoCNXzqph4Absn7ryIXFQ7ek/edit
  - https://docs.google.com/document/d/1pIRzJjlBbv2no_brtXRd7XhQbWFtZFOZCFGocxyEvgs/edit
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10570848
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10834998
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755111
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755116
  - https://arxiv.org/abs/2508.20900
  - https://docs.google.com/document/d/1uEgOiNArIQm5zC6GBq9xejcKihX1rcxhGC1kP-AIznk
  - https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY
  - https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/team/01.ads-engineering
  - https://docs.google.com/document/d/1UnTWVdgGnZgAqkPa-Pn12j8GCRZwn94EoHoxCmzvVjQ
  - https://docs.google.com/document/d/15oAssKRKJKr8jfng4nk0jyXy6ysxYqczd58vL6iorfU
  - https://docs.google.com/document/d/1GZr8tQSqJa88xU_8ZXzXTNJe3TjFazllP2cnVv0AoG4
  - https://docs.google.com/document/d/1WzXIPJabDeF4r1iyJIxl2WPuDTNrINvYoc_06A4WA5g/edit
  - https://abtest.shopee.io/feature/42/detail/3586
  - https://ego-portal.mlp.shopee.io/serving/batchModelServing/
  - https://graphmanager.shopee.io/selfmodel/front/model-config
  - https://release.sra.shopee.io/template/list
  - https://algolab.shopee.io/afp/node/list?projectId=11&current=1&pageSize=10&scopeId=12
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390147
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390057
  - https://docs.google.com/document/d/1GrUQ8ZuufZSnMrrGDICUkRL3rmKmvwbaIDFmvurBjyQ
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10917479
last_updated: 2026-04-29
last_verified_at: 2026-04-29
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1EdpIEI0o1g0_b-of1CGPLgbXygGh-IkUmgBGy9Fxq_4 gdoc_url=https://docs.google.com/document/d/1EdpIEI0o1g0_b-of1CGPLgbXygGh-IkUmgBGy9Fxq_4/edit -->

# Ads Recall 总览

## KB 必要信息索引

| 类别                     | 当前索引                                                                                                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 代码仓库 GitLab 路径         | `shopee/deep/paidads-recall`、`shopee/deep/searchads/graph-manager-conf`、`shopee/deep/oh-my-embedding`、`shopee/deep/paidads-alg`                                                                                     |
| 核心服务 SDU 路径            | **【待确认】需由 owner 通过 Space / SMC 确认当前 `paidads-recall`、OhMyEmb、EGO Serving 线上 SDU 路径**                                                                                                                                |
| ConfigCenter namespace | **【待确认】召回主配置以 `graph-manager-conf` YAML 与 AB 参数为主，若存在 ConfigCenter namespace 需补充实际线上值**                                                                                                                             |
| Grafana dashboard      | Search Ads Recall Funnel、Discovery Ads Recall Funnel、Retrieval Service、Retrieval v3、KNN Deploy、OhMyEmb Offline Pipeline、Recall Dependency Monitor                                                                   |
| 关键 Kafka topic         | **【待确认】OhMyEmb / embedding 离线链路存在 Kafka 阶段，具体 topic 需按当前 Data Delivery / pipeline 配置补齐**                                                                                                                            |
| 核心 Hive 表名             | `paidads_mart.dwd_trace_recall_log_di__reg_s0_live`、`mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`、`mp_paidads.dwd_advertise_performance_di__reg_s0_live`、`mp_paidads.ods_shopee_paidads_index_log` |

## 阅读指引

本文档按"业务背景 → 召回链路 → 上线运维 → 指标数据 → 代码位置"组织，各章节速览：

- `§0–§3` **总览**：一句话摘要、基本信息、业务背景与痛点、召回在整体链路中的位置和职责边界。
- `§4` **核心概念**：分四小节——队列与通路、检索方式（op 级）、模型与样本、合并/过滤/降级，兼作 §5–§11 的索引入口。
- `§5` **召回通路与策略**：队列编号规范、各场景（Search/DD/YMAL/Shop/Live/Video/Brand）的队列清单、候选生成逻辑、过滤与合并规则、降级策略。
- `§6` **样本及特征构成**：训练样本来源、正负样本构造、AFP 特征处理、长序列与 UniModel 特征清单。
- `§7` **训练与准备**：以 LongSeq 主模型（623012104）为例介绍训练数据、模型架构、训练与评估流程。
- `§8` **召回上线流程**：从新增队列、模型训练发布、AB 实验创建到指标查看、Rollout 推全的完整 SOP。
- `§9` **关键指标**：离线指标（recall_rate / precision@100）、在线整桶指标（rev/advv/gmv）、队列效果分析（采纳/独占双口径全套指标）。
- `§10` **数据契约**：常用 Hive 表、tracking 字段、独占率/采纳率/离线 recall rate 标准口径、DataSuite 调度与 DataBus 配送任务清单。
- `§11` **代码与逻辑位置**：仓库地图、关键逻辑入口、关键配置与参数，以及按队列号 / 模型名 / 场景反查完整信息的查询路径。
- `§12` **参考资料**：相关文档、平台入口、代码仓库索引。

> 读者使用指南：§1–§4 是"定位 + 术语"层；具体代码事实 / SQL 口径一律以 §5–§11 为准（见 handoff §3.2 决策规则——文档 vs 代码以代码为准，文档 vs SQL 以 SQL 为准）。

> Agent 默认处理顺序：
> 1. 先判断这是**静态知识题**还是**平台/数据查询题**。
> 2. 若是查询题，优先按 §10.1 / §11.3.5 / §12.4 / §12.5 选择对应 skill：
>    - 新增 OhMyEmb / KNN 模型：`ads-recall-ohmyemb-add-model`
>    - 新增 KNN / KV 队列：`ads-recall-add-queue`
>    - OhMyEmb 模型或 DAG 节点调试：`ads-recall-ohmyemb-debug`
>    - 查 Hive / DataSuite 数据：`sra-ds-sql-query`
>    - 查 DataSuite asset / workflow / 脚本：`sra-datasuite-crawler`
>    - 查 Grafana：`sp-grafana`
>    - 查 AB：`sp-ab`
>    - 查 AFP：`sra-afp`
>    - 查 EGO serving / checkpoint：`sra-ego-serving-list` / `sra-ego-checkpoint`
>    - 查请求级 case：`auto-case-attribution`（见 §10.4 / §12.2）
> 3. 若 skill 因权限、cookie、接口边界或数据不存在而失败，再把 KB 中对应的**手动查询流程 + 平台链接 + 关键过滤维度**作为回答返回给用户。
> 4. 除非 KB 同时缺“静态答案”和“查询路径”，否则不要直接回答“不能回答”。

## 0. 一句话摘要
- 这个召回主题是什么：Ads 多广告场景的统一召回知识卡片，覆盖 Product Ads、Video Ads、Livestream Ads、Shop Ads、Brand Ads 的候选生成、通路、索引、模型化召回和监控诊断。
- 作用在哪类流量/广告类型：Search、DD、YMAL、RCMD 等入口，以及 Product Ads、Video Ads、Livestream Ads、Shop Ads、Brand Ads。
- 核心目标：提升召回覆盖率和候选质量，降低 0 候选与长尾劣势，通过通路精简、索引统一、模型化召回和诊断工具建设提升收入、稳定性和迭代效率。
- 当前代码级覆盖度：§5.2.1 / §11.3 对 Product Ads 的 Search + Discovery 队列做了完整 YAML/Go 级核查；Shop Ads / Live Ads 已在 §11.3.6-§11.3.7 补充静态 DAG / `node_chain` / 默认 limit 配置卡片；Video / Brand 仍以登记表口径为主，其中 Brand 的部分静态配置已散落在 §11.3.1 / §11.3.2。

## 1. 基本信息

| 字段      | 内容                                                                                                                                                                                                                                                                                                                 |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 主题名称    | Ads Recall（总体）                                                                                                                                                                                                                                                                                                     |
| 召回类型    | 按检索方式分 6 大类 op：KNN（Vespa ANN）/ KV（Redis）/ Text（Vespa 倒排）/ FSE Realtime / U2U2I（KNN+FSE 两阶段）/ Fallback。详见 §5.2.1                                                                                                                                                                                                    |
| 适用广告类型  | Product Ads / Video Ads / Livestream Ads / Shop Ads / Brand Ads                                                                                                                                                                                                                                                    |
| 适用场景/入口 | Search / DD / YMAL / RCMD / Live / Video / Shop                                                                                                                                                                                                                                                                    |
| 负责人     | Cody（召回工程 + 召回策略 + 召回 KB / 诊断方向统一推进）。具体队列 PIC 按队列粒度分散管理，详见 §5.1                                                                                                                                                                                                                                                    |
| 相关系统    | 代码与配置：`paidads-recall`（Retrieval 服务）/ `graph-manager-conf`（retrieval DAG + ohmyemb 节点）/ `oh-my-embedding` / `paidads-alg`（训练）。底层依赖：Vespa（KNN + Text）/ Redis（KV）/ FSE（实时特征 + 长序列）/ EGO（训练 + Serving）/ AFP（特征血缘）/ DataSuite（调度 + 监控 SQL）/ AB Test Platform。下游消费：Ads Info（状态/定向）/ Tracking / Prerank / Rank / MixRank |
| 当前状态    | 架构升级与知识沉淀中；统一召回、Search 个性化、SID/U2C2I、长序列 2k、Content Ads recall 重构、LLM/Q2Tag2I 等方向并行推进                                                                                                                                                                                                                              |

> 备注：`相关系统` 已收敛到 §11.1 仓库地图 + §12.5 平台入口能一一对应的对象；"召回类型"沿 §5.2.1 的 op 分类，避免出现 §5–§11 中无代码落点的泛化词（"个性化召回 / 规则扩召回"等）。

## 2. 业务背景

### 2.1 痛点与驱动因素（来自 OKR / Tracker / TRD）
- **召回覆盖**：Ads impression 中 ads recall 占比低于预期（95% 为 team-level 目标），部分场景存在 0 候选、独占率低、长尾差等问题。参见 §9 离线/在线指标口径。
- **广告库规模**：广告库持续膨胀（TW 从 580 万 → 950 万），但单次请求仅能展示几十条广告，第一级筛选必须在毫秒级完成。
- **架构历史包袱**：召回通路多、索引分散、placement 路由负担重，导致维护成本高、调参链路长、线上诊断不统一。→ 对应 §5.1 队列登记表、§5.3 过滤链、§11.3 队列关键配置。
- **模型化方向**：2025 Q1 已在 RCMD 场景落地离线 U2I 长序列多兴趣建模并取得线上收益；当前目标是演进为在线统一长序列模型（参见 §7 LongSeq 623012104 案例），提升实时性并降低离线维护成本。
- **业务目标**：提升 recall coverage、候选质量和收入表现；统一索引和业务路由；沉淀召回知识库、分析方法和诊断 skill。
- **适用场景**：理解 Ads 全局召回链路、做队列诊断、做索引/路由重构、分析召回实验收益。

### 2.2 季度路线图
<!-- 下列季度条目仅来源于 OKR / Tracker / Epic 等产品文档，属于团队方向性归纳；未与 graph-manager-conf / paidads-recall / paidads-alg 等代码级事实逐条核对。具体队列是否已上线、是否已全量，请结合 §5.1 登记表、§5.2 代码分析及 §8 rollout 文档进一步确认。 -->
- **2025Q1**：统一 Search / Discovery 的 recall 架构，推动队列收敛、Search relevance 和全链路一致性建模，并暴露出长序列长度不足的问题。
- **2025Q3**：推进 API0 / 全 bidding type 统一召回、Query/User2Tag 服务化、QIR 迁移与相关性优化；U2U2I 全量后带来显著收入增益。
- **2025Q4**：建设 Tag 评估体系、Recall Efficiency、U2C2I/SID、RCMD 长序列在线化，季度层面形成"长序列"与"语义中间层"两条主线。
- **2026Q1**：继续推进 Content Ads recall 重构、Search LLM/Q2Tag2I、Search & RCMD 模型化召回、2k 长序列、model i2i、quota / 降级 / 实验监控等能力建设。

## 3. 召回定位

### 3.1 在整体链路中的位置

```text
全量广告库（百万级）
  ↓  [Recall] 多路并行召回 → 过滤 → Zigzag Merge → 几千条候选   ← 本文档关注
  ↓  Prerank 粗排模型打分 → 几百条
  ↓  Rank 精排模型打分 → 几十条
  ↓  MixRank 混排 → 最终展示
```

一次请求的完整链路：

```text
request -> query/user/context understanding -> recall -> filter -> merge -> prerank/rank -> mixrank
```

### 3.2 本主题职责
- **负责召回什么候选**：为 Search、DD、YMAL、RCMD、Live、Video、Shop、Brand 等场景生成广告候选。按检索方式分 6 大类 op（KNN / KV / Text / FSE Realtime / U2U2I / Fallback，见 §5.2.1），按业务通路表现为 U2I、I2I、Q2Tag2I、U2C2I/SID、Keywordless、Popularity、Rewrite、AdTag、Content Ads unified recall 等队列（见 §5.1 登记表、§11.3 队列关键配置）。
- **不负责什么**：不负责最终排序、最终竞价/出价、扣费结算、投放履约，也不负责候选索引的生产与写入本身。
- **与上下游的边界**：
  - **上游（特征 / 索引）**：`Ads Info` 与 `Indexer` 负责候选可检索性、字段可用性与时效性（§11.1 下游依赖表）。`FSE` 提供实时用户行为、长序列特征及 `SimpleStandardURankerOp` 的在线特征（见 §5.2.1 E、§6 特征报告）。`AFP` 提供离线特征血缘与 serving 端特征处理。`EGO` 负责双塔模型训练与 Serving，产出 User Tower / Item Tower Embedding（见 §7 LongSeq 案例、§8.2 模型发布）。
  - **下游（排序 / 竞价）**：`Prerank` 粗排决定进入精排的候选；`Rank` 精排决定最终优先级；`Bidding` 决定价格和目标约束；`MixRank` 负责广告与自然结果的混排。
  - **合并与过滤**：召回内部包含 `MergeRecallResultOp`、`AdsInfoFilter`（Search / Discovery）、`RcmdAdsDedupOp`（仅 Discovery）、`SnakeMergeFilterOp`、`BizTagCalculateOp`、`PackRecallAdsResultOp`、`SendRecallLogOp` 等 op，具体语义见 §5.2、§5.3 与 §11.3。

因此，“模型召回到了”不等于“一定进入粗排”：候选还要经过 merge、AdsInfoFilter、Discovery 去重、SnakeMerge 截断、业务标签计算、打包和日志透传。排查时应先确认候选停在哪个阶段，再判断是模型检索、过滤、去重、quota 截断还是下游链路问题。

## 4. 核心概念

<!-- 本节只列"术语 + 在哪里展开"，具体代码落点、配置文件、op 名称一律指向 §5–§11；新增/修改术语请同步 handoff §6 已验证事实清单。 -->

### 4.1 队列与通路

| 概念 | 定义 | 与本主题关系 / 落点 |
|---|---|---|
| recall channel | 单一路径或队列，例如 KNN、Q2Tag2I、U2I、I2I、Keywordless | 召回的基本组织单元，队列清单见 §5.1 |
| queue_name | 召回队列的 9 位数字编码，例 `611020304`、`624012101` | 统一标识 场景 / 通路类型 / 服务类型 / 具体队列；规则见 §5.0 |
| candidate | 召回阶段输出的广告候选集合 | 后续 filter / merge / rank 的输入 |
| query understanding | 对 query / user / context 的理解结果（rewrite、意图特征等） | 决定是否走某些扩召回通路；Search 场景入口见 §5.2.1 |

### 4.2 检索方式（op 级）

| 概念 | 定义 | 与本主题关系 / 落点 |
|---|---|---|
| KNN recall | 通过 Vespa ANN 向量索引做双塔近邻检索 | 模型化召回队列的主要在线执行方式，见 §5.2.1 A |
| KV recall | 通过 Redis 查离线算好的 I2I / U2I 映射 | 离线产出队列（I2I / U2I）的在线执行方式，见 §5.2.1 B |
| text recall | 通过 Vespa 倒排索引做关键词匹配 | Search 特有的文本匹配队列，见 §5.2.1 C |
| FSE realtime recall | 基于 FSE 在线实时用户行为 / 长序列特征做召回 | 承接 `SimpleStandardURankerOp` 的在线 reranker，见 §5.2.1 E |
| U2U2I recall | KNN + FSE 两阶段（先 U→U，再 U→I）组合召回 | RCMD / Discovery 主力收入队列之一，见 §5.2.1 D、§5.1 DD/YMAL |
| fallback recall | 当前置队列 0 候选或降级时启用的兜底通路 | 保障 0 候选兜底与稳定性，见 §5.2.1 F、§5.4 降级 |

### 4.3 模型与样本

| 概念 | 定义 | 与本主题关系 / 落点 |
|---|---|---|
| dual-tower model（双塔模型） | User / Query 塔与 Item 塔分别编码成向量，通过余弦相似度检索 TopK | Recall 最主要的模型架构，案例见 §7 LongSeq |
| I2I（Item-to-Item） | 给定一个 Item，找到相似 / 相关 Item | 策略 I2I（ItemCF 共现）与模型 I2I（Embedding 暴力近邻）实现不同，见 §5.2.1 B |
| U2I（User-to-Item） | 用户塔 × Item 塔的 TopK 召回 | 长序列 / 多兴趣双塔的主形态，见 §7 |
| Q2I / Q2Tag2I | Query 塔 → Item 或 Query → Tag → Item 的 Search 专用通路 | Search relevance + 扩召回同时兼顾，见 §5.1 Search |
| Extra Embedding | 用离线预计算的稠密 embedding（LLM / MPI）替代 sparse fkey | 长序列模型训练/serving 的关键特征形态，见 §6、§7.2 |
| checkpoint | 模型训练产出的快照，用于 serving 发布 | 每个 checkpoint 绑定样本日期，见 §7、§8.2 |

### 4.4 合并 / 过滤 / 降级

| 概念 | 定义 | 与本主题关系 / 落点 |
|---|---|---|
| merge / truncate | 多队列结果的合并、去重、截断过程 | 决定候选量、独占率与后链路负载，对应 `MergeRecallResultOp` / `SnakeMergeFilterOp`，见 §5.2.2 |
| AdsInfoFilter | 召回后的 ads 基础过滤链（可见性 / 审核 / 类目 / 黑白名单 / 价格 / placement / 视频匹配 / 店铺评分 / 反作弊 / 同店 / 跨境等） | Search 与 Discovery 走不同实现，见 §5.3 |
| RcmdAdsDedup | Discovery 专属的跨队列去重 op | 仅 Discovery 启用，见 §5.2.2 |
| biz tag | 候选在 `BizTagCalculateOp` 阶段写入的业务标签 | 供下游 Prerank / Rank / 监控使用，见 §5.2.2 |
| downgrade level | L2 / L3 / LM 三级降级，逐级关停非关键通路与模型 | 稳定性兜底，配置见 §5.4 / `retrieval/recommend_game.yaml` |

> 以上表格仅做术语索引；具体 op 名称、配置文件路径、YAML 片段请跳到对应章节阅读。

## 5. 召回通路与策略

<!--
Agent 阅读提示：
- §5 是"事实层"的入口，§5.0 编号规范 → §5.1 队列清单（登记表口径）→ §5.2 候选生成（代码口径）→ §5.3 过滤（代码口径）→ §5.4 降级（YAML 口径）。
- 登记表 vs 代码冲突时以代码为准（handoff §3.2 决策规则）。典型已知边界：Shop / Live 已补到专用 graph（见 §11.3.6 / §11.3.7）；Video / Brand 仍有部分队列只在登记表中可见，尚未系统补齐到同粒度代码卡片。
- 需要查具体字段（queue_limit、rank_profile、label2recall_limit 等）时直接跳到 §11.3。
-->

### 5.0 队列编号规范
- 当前统一编码规则：`{AdsType,1} + {Scene,1} + {L1QueueType,1} + {BusinessAttr,1} + {ServerType,1} + {L2QueueType,2} + {QueueNum,2}`。
- 例子：`611020304` 表示 `All + Search + Q2I + Efficiency + Tag2I-Vespa + Term-Q2I + 04`，当前对应 Search 的 `Q2Tag2I Vespa` 主队列。
- 例子：`624012101` 表示 `All + Discovery + U2U + Efficiency + Embedding + ModelU2U + 01`，当前对应 Discovery/RCMD 的 `U2U2I` 召回入口。
- 统一命名的目标：把旧 ROI1/ROI2 分裂队列映射到 API0 合并后的 `All` 队列，同时保留场景、队列大类、服务类型和强业务属性的可读性。

### 5.1 召回队列清单

以下队列信息来自[召回队列命名约定](https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk)登记表。

<!--
此表口径 = 登记表，主要用于回答"有哪些队列、各自是什么用途、谁是 PIC"。
真正决定线上行为的是 §5.2 / §11.3 的代码/YAML 口径：
- 队列是否在线 → 看 graph-manager-conf retrieval YAML 是否有对应节点；
- rank_profile / 限额 / 降级 level → §11.3 每队列字段表；
- PIC 列仅到"队列归属人"粒度，与 §1 文档负责人是不同语义。
-->


**Search Ads 队列：**

| 队列号 | 队列全称 | 用途 | PIC | 检索方式 |
|---|---|---|---|---|
| `611020304` | All-Search-Q2I-Efficiency-Tag2I-Vespa-Term-Q2I | 文本精确匹配 Q2Tag2I | lumm | Text (Vespa 倒排) |
| `611010104` | All-Search-Q2I-Efficiency-Embedding2I-Model-Q2I | 语义向量 Q2I | Xiao Zhang | KNN (Vespa ANN) |
| `611010103` | All-Search-Q2I-Efficiency-Embedding2I-Model-Q2I | Cluster KNN Q2I（`rank_profile=clusterv2`） | - | KNN (Vespa ANN) |
| `611030109` | All-Search-Q2I-Efficiency-Tag2I-Redis-Model-Q2I | LLM 离线 Q2I | Swam | KV (Redis) |
| `611030110` | All-Search-Q2I-Efficiency-Tag2I-Redis-Model-Q2I | LLM Q2I (with ECPM) | Swam | KV (Redis) |
| `612031201` | All-Search-I2I-Efficiency-Tag2I-Redis-StragyI2I | Q2Tag2I(Tag=Item) | - | KV (Redis) |
| `111520301` | ROI1-Search-Q2I-manual ads w/ bidkw-Tag2I-Vespa-Term-Q2I | Manual Ads BidKW 匹配 | Bert Chen | Text (Vespa 倒排) |
| `111520302` | ROI1-Search-Q2I-manual ads w/ bidkw-Tag2I-Vespa-Term-Q2I | Manual Ads Item 匹配 | Bert Chen | Text (Vespa 倒排) |
| `611610101` | All-EmbeddingQ2I-Search-General_Support-ModelQ2I-01 | 通用扶持（成熟广告） | Kaiqiang Wang | KNN |
| `611610102` | All-EmbeddingQ2I-Search-General_Support-ModelQ2I-02 | 通用扶持（冷启广告） | Kaiqiang Wang | KNN |
| `611030202` | All-Search-Q2I-Efficiency-Tag2I-Redis-Stragy-Q2I-02 | Realtime Popular Q2I | Mimi Lu | KV (Redis) |
| `111030201` | ROI1-Search-Q2I-Efficiency-Tag2I-Redis-Model-Q2I | 行为 Q2I（`q2i_bhv_org_v1`） | - | KV (Redis) |

**Discovery Ads 队列：**

| 队列号 | 队列全称 | 用途 | PIC | 检索方式 |
|---|---|---|---|---|
| `623012104` | All-Discovery-U2I-Efficiency-Embedding(U/Q)2I-ModelU2I-04 | Online U2I（LongSeq 主模型） | Qianqian Pu | KNN (Vespa ANN) |
| `623012102` | All-Discovery-U2I-Efficiency-Embedding(U/Q)2I-ModelU2I-02 | Online U2I (LongSeq v1)，已从 `recommend_game.yaml` 移除 | Qianqian Pu | KNN (Vespa ANN) |
| `623012108` | All-Discovery-U2I-Efficiency-Embedding(U/Q)2I-ModelU2I-08 | U2I UniModel | Xiao Zhang | KNN (Vespa ANN) |
| `623922201` | All-Tag2I-Vespa-Discovery-other-StragyU2I-01 | Offline U2I (default recall) | Changrui Dai | Text (Vespa) |
| `624012101` | All-Discovery-U2U-Efficiency-Embedding-ModelU2U-01 | U2U2I | Jiaheng Dou | KNN (Vespa ANN) |
| `622031201` | All-Tag2I-Redis-Discovery-Efficiency-StragyI2I-01 | 策略 I2I (ItemCF 协同过滤) | Kaiqiang Wang | KV (Redis) |
| `622031101` | All-Tag2I-Redis-Discovery-Efficiency-ModelI2I-01 | 模型 I2I (Embedding 近邻) | Kaiqiang Wang | KV (Redis) |
| `623612101` | All-EmbeddingU2I-Discovery-General_Support-ModelU2I-01 | 通用扶持（成熟广告） | Kaiqiang Wang | KNN |
| `623612102` | All-EmbeddingU2I-Discovery-General_Support-ModelU2I-02 | 通用扶持（冷启广告） | Kaiqiang Wang | KNN |

**Shop Ads 队列：**

| 队列号 | 队列全称 | 用途 | 检索方式 |
|---|---|---|---|
| `677525101` | All-Shop-Q2S-manual ads w/ bidkw-Tag2I-Vespa-Term-Q2S | Shop BidKW Term Recall | Text (Vespa 倒排) |
| `677020301` | All-Shop-Q2S-Efficiency-Tag2I-Vespa-Term-Q2I | Q2Tag(Vespa)2I2S | Text (Vespa 倒排) |
| `677030201` | All-Shop-Q2S-Efficiency-Tag2I-Redis-Strategy-Q2I | Q2Tag(Redis)2I2S / LLM offline | KV (Redis) |
| `677010101` | All-Shop-Q2S-Efficiency-EmbeddingQ2I-Model-Q2I | Q2Tag(Emb)2I2S | KNN (Vespa ANN) |
| `677030202` | All-Shop-Q2S-Efficiency-Tag2I-Redis-Stragy-Q2I-02 | Realtime Popular Q2I2S | KV (Redis) |

**Live / Video Ads 队列：**

| 队列号 | 用途 | 场景 | 检索方式 |
|---|---|---|---|
| `653012101` | Live KNN (item index) | Live | KNN (Vespa ANN) |
| `655012101` | Live KNN (live index) | Live | KNN (Vespa ANN) |
| `653031201` | Live U2I2IL (redis + item index) | Live | KV + KNN |
| `653031202` | Live View Follow | Live | KV |
| `658940401` | Live PDP2L | Live | KV |
| `653940401` | Live Random Fallback | Live | Random |
| `663012101` | Video KNN (item index) | Video | KNN (Vespa ANN) |
| `666012101` | Video KNN (video index) | Video | KNN (Vespa ANN) |
| `663031201` | Video U2I2IV (redis + item index) | Video | KV + KNN |
| `668940401` | Video PDP2V | Video | KV |
| `663940401` | Video Random Fallback | Video | Random |

**Brand Ads 队列：**

| 队列号 | 用途 | 场景 |
|---|---|---|
| `611912108` | Brand Max Shop | Search |
| `623912108` | Brand Max Shop | RCMD |
| `611920304` | Search Q2Tag2I for Shop Manual Ads | Search |

注意：各队列 quota/limit 值参见[召回队列命名约定](https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk)登记表，实际在线值可能受 AB 参数覆盖（如 `recommend_game.yaml` / `search_recall.yaml`）。

补充：
- `PIC` 的首选来源永远是登记表 / owner 文档；**不要默认把代码作者直接当成 PIC**。
- 若登记表里没有 `PIC`，可按 §11.3.5 H 的 git 反查方法先找“**最近实现负责人候选**”，用于追 owner、补资料或继续确认。

### 5.2 候选生成逻辑

<!--
§5.2 全部以 graph-manager-conf master 为准（参见 handoff 第十九次 / 第二十次修改）。
如果看到与登记表、OKR、Epic 冲突，一律以此节 + §11.3 为准。
Agent 新增/修改任何 op 名称（`KnnQ2IOp` / `KnnU2IOp` / `RedisU2IOp` / `SimpleStandardURankerOp` / `RandomRecallOp` / `MergeRecallResultOp` / `SnakeMergeFilterOp` / `RcmdAdsDedupOp` / `BizTagCalculateOp` / `PackRecallAdsResultOp` / `SendRecallLogOp` 等）时，必须回到 graph-manager-conf 的 retrieval/ohmyemb YAML 里验证。
-->

#### 5.2.1 队列按检索方式分类

根据 `search_recall.yaml` 和 `recommend_game.yaml` 中每个队列的 `op` 字段，所有队列可分为以下 6 类：

**A. KNN（Vespa ANN 向量近邻检索）**

在线通过 OhMyEmb 推理得到 Query/User Embedding，再通过 Vespa `nearestNeighbor` 做 ANN 检索返回 TopK。

典型 KNN 队列在线链路可以概括为：

```text
request / context / FSE feature
  -> OhMyEmb online_query_user(SimpleStandardURankerOp)
  -> user/query embedding
  -> KnnU2IOp / KnnQ2IOp / KnnU2UOp
  -> Vespa nearestNeighbor(rank_profile, required_output)
  -> candidates
  -> MergeRecallResultOp
  -> AdsInfoFilter
  -> RcmdAdsDedupOp(仅 Discovery)
  -> SnakeMergeFilterOp
  -> BizTagCalculateOp
  -> PackRecallAdsResultOp
  -> SendRecallLogOp
  -> Prerank
```

离线 item 侧还有一条配套链路：`item features -> EGO/URanker item tower -> OhMyEmb offline_item(SimpleStandardURankerOp) -> item embedding -> Vespa index`。特殊队列 `624012101` 是两阶段：先由 `KnnU2UOp` 找相似用户，再由 `GetFseU2IOp` 从 FSE 拉相似用户行为聚合 item 候选。

| 场景 | 队列 | DAG op | 说明 |
|------|------|--------|------|
| Search | `611010104` | `KnnQ2IOp` | Query 双塔，`vespa_name=sa_q2i_knn_recall`，`rank_profile=v1` |
| Search | `611010103` | `KnnQ2IOp` | Cluster KNN，`vespa_name=sa_q2i_knn_recall`，`rank_profile=clusterv2` |
| Search | `611610101` | `KnnQ2IOp` | 通用扶持（成熟），`rank_profile=64dimv3` |
| Search | `611610102` | `KnnQ2IOp` | 通用扶持（冷启） |
| Discovery | `623012104` | `KnnU2IOp` | Online U2I 主模型，`vespa_name=dd_u2i_knn_recall`（`recommend_game.yaml`） |
| Discovery | `623012108` | `KnnU2IOp` | U2I UniModel（`recommend_game.yaml`） |
| Discovery | `623612101` | `KnnU2IOp` | 通用扶持（成熟），仅在 `recommend_dd/ymal/pp.yaml` 中 |
| Discovery | `623612102` | `KnnU2IOp` | 通用扶持（冷启），仅在 `recommend_dd/ymal/pp.yaml` 中 |

模型训练代码：
- Search Q2I UniModel (611010104)：[prod_djh_unimodel_v1](https://git.garena.com/shopee/deep/paidads-alg/-/tree/exp/recall/OnlineU2I/%20prod_djh_unimodel_v1)（`exp` 分支）。
- Discovery U2I UniModel (623012108)：[prod_djh_unimodel_v1](https://git.garena.com/shopee/deep/paidads-alg/-/tree/exp/recall/OnlineU2I/%20prod_djh_unimodel_v1)（`exp` 分支）。
- Discovery U2I 长序列主模型 (623012104)：[long-seq](https://git.garena.com/shopee/deep/paidads-alg/-/tree/exp/recall/OnlineU2I/long-seq)（`exp` 分支），使用 `click_500` 长序列特征 + MoE ReasoningBlock + ExtraAdapter，按 `region x scene(DD/YMAL)` 分区训练；详细架构见 §7.2。

**B. KV（Redis 离线映射查询）**

离线算好 query→item 或 item→item 映射写入 Redis，在线直接查 key 获取候选列表。

| 场景 | 队列 | DAG op | 说明 |
|------|------|--------|------|
| Search | `611030109` | `RedisQ2IQRCustomizedOp` | LLM 离线 Q2I |
| Search | `611030110` | `RedisQ2IQRCustomizedOp` | LLM Q2I (with ECPM) |
| Search | `111030201` | `RedisQ2IOp` | 行为 Q2I，`model=q2i_bhv_org_v1`，`source=roi1` |
| Discovery | `622031201` | `RedisI2IOp` | 策略 I2I，`model=stgy_i2i`（ItemCF 90 天共现统计） |
| Discovery | `622031101` | `RedisI2IOp` | 模型 I2I，`model=model_i2i`（Embedding 暴力近邻） |

离线产出代码：
- 策略 I2I：[stgy_i2i](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/i2i/stgy_i2i)
- 模型 I2I：[model_i2i](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/i2i/model_i2i)
- LLM Q2I：[Q2Tag2I](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/Q2Tag2I/swam/q2tag2i)，脚本分 `query_feature`、`item_feature`、`tag2tag`、`hot_item`、`query_compression` 等子流程。

**C. Text（Vespa 倒排索引匹配）**

通过 Vespa 倒排索引做 keyword / tag 文本匹配。

| 场景 | 队列 | DAG op | 说明 |
|------|------|--------|------|
| Search | `611020304` | `QT2IOp` | Q2Tag2I 主队列，支持 `raw/rewrite/extend` 三种 query 类型 |
| Search | `111520301` | `RecallKeywordMatchV2Op` | Manual Ads BidKW 匹配 |
| Search | `111520302` | `RecallKeywordItemMatchV2Op` | Manual Ads Item 匹配 |
| Shop | `677525101` | Text (Vespa) | Shop BidKW Term Recall |
| Shop | `677020301` | Text (Vespa) | Q2Tag(Vespa)2I2S |

**D. FSE / Realtime（在线实时特征查询）**

从 FSE 实时拉取用户行为或 query 热度数据生成候选。

| 场景 | 队列 | DAG op | 说明 |
|------|------|--------|------|
| Search | `611030202` | `RecallFetchFSERealtimeQ2IItemOp` | Realtime Popular Q2I |
| Search | `612031201` | `RecallFetchFSEQ2I2IItemOp` | Q2Tag2I(Tag=Item)，`model=itemcf_i2i_v1` |

**E. U2U2I（两阶段：KNN 找相似用户 + FSE 拉行为）**

先通过 `KnnU2UOp` 找相似用户，再由 `GetFseU2IOp` 从 FSE 拉取相似用户行为聚合成 item 候选。

| 场景 | 队列 | DAG op | 说明 |
|------|------|--------|------|
| Discovery | `624012101` | `KnnU2UOp` + `GetFseU2IOp` | `vespa_name=knn_u2u`，按 `label_weight/label_limit` 聚合 |

代码：[u2u2i](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/u2u2i)

**F. Fallback（兜底召回）**

当主队列不可用或候选不足时触发的降级队列。

| 场景 | 队列 | DAG op | 说明 |
|------|------|--------|------|
| Discovery | `623922201` | `GetVespaFallback` | Offline U2I default recall，`rank_profile=random` |
| Live | `653940401` | Random | Live Random Fallback |
| Video | `663940401` | Random | Video Random Fallback |

**G. Support / Cold-start（扶持与冷启兜底）**

冷启策略不是单独的一条全局分支，而是由扶持队列、非强个性化队列和 fallback 共同承担：

- Item 冷启：Search `611610102`、Discovery `623612102` 明确承担冷启广告扶持；前提仍是 item 已进入索引并具备基础可召回字段。
- 成熟广告扶持：Search `611610101`、Discovery `623612101` 面向成熟广告扶持，与冷启扶持队列一起补长尾供给。
- User 冷启：当用户长序列行为弱时，通常更多依赖 query / item 驱动队列、扶持队列和 fallback；KB 当前没有单独沉淀一套 user cold-start 专用分支。
- Query 冷启：QT2I、LLM Q2I、Realtime Popular Q2I 等非强个性化队列承担部分兜底；这是基于队列用途的解释，实际策略仍以对应 graph / AB 为准。

补充说明：
- Shop / Live 已在专用 graph 中定位到静态配置，详见 §11.3.6 / §11.3.7。
- Video / Brand 仍未完全整理成与 Search / Discovery 同粒度的配置卡片；本节为保持 op 分类主表简洁，只列 Search / Discovery 主队列与少量跨场景代表项。
- 若用户手里拿到的是 Shop / Live / Video / Brand 队列号，优先回 §5.1 看登记表口径，再到 §11.3 的对应子节或 §11.3.5 的反查路径继续定位。

#### 5.2.2 通用流程

所有类型的队列共享以下通用流程（已在 YAML DAG 中确认）：

1. **独立召回**：各队列按各自的 op 并行执行，互不依赖。
2. **Merge**：通过 `MergeRecallResultOp` 合并所有队列结果。
3. **过滤**：通过 `SearchAdsInfoFilterOp`（Search）或 `RCMDAdsInfoFilterOp`（Discovery）做 ads 状态和定向过滤。
4. **去重**：Discovery 通过 `RcmdAdsDedupOp` 做候选去重。
5. **Snake Merge**：通过 `SnakeMergeFilterOp` 按 quota 配额交替取出，截断到最终 TopK。
6. **Biz Tag**：通过 `BizTagCalculateOp` 计算业务标签。
7. **打包与日志**：`PackRecallAdsResultOp` 打包结果，`SendRecallLogOp` 发送召回日志。

#### 5.2.3 Downgrade 层级

`recommend_game.yaml` / `search_recall.yaml` 中实际使用的降级层级（已验证无 L1）：

| 层级 | 含义 | 对应队列 |
|------|------|---------|
| L2 | 重度降级时关闭 | `624012101`（U2U2I）、`623012108`（U2I UniModel）、`611020304`（Q2Tag2I）、`611920304`（Search Q2Tag2I for Shop Manual Ads） |
| L3 | 中度降级时关闭 | `611010104`（Search KNN Q2I）、`611912108`（Brand Max Shop） |
| LM | 最轻度降级时关闭 | `623922201`（Fallback）、`611610101`/`611610102`（Search 通用扶持） |
| 无 | 不参与降级 | `623012104`（Online U2I LongSeq 主模型） |

降级负责保稳定性，cache 负责稳延时和降低依赖压力。KNN 队列的 cache 行为通常由 AB 队列参数中的 `cache_key`、`cache_ttl_sec`、`cache_read_mode`，以及 graph YAML 中的 `with_redis`、`with_memory`、`rw_mode`、`DefaultCacheTTL` 等字段共同决定。不同队列、场景、region 的读写模式可能不同，例如同一 KNN 队列在 DD / YMAL / PP / Game 下可能分别走 write-only、read-only 或 memory cache；最终线上行为以 AB 生效配置和当前 graph tag 为准。

### 5.3 过滤逻辑

以下过滤逻辑全部来自代码验证（`paidads-recall` 仓库），按 DAG 执行顺序排列。

<!--
Agent 阅读提示：
- Search 与 Discovery 共用 `CommonAdsInfoFilterOp` 基类，但分别注册 `SearchAdsInfoFilterOp` / `RCMDAdsInfoFilterOp`，filter 链顺序不同 —— 看到某个过滤项"只在一边生效"是正常的（见 §5.3.2）。
- 只有 Discovery 有 `RcmdAdsDedupOp`（实时去重）；Search 没有此步（见 §5.3.3）。
- 所有 "Unpick Reason" 串是在线打点 + §10 tracking 表可查的常量，排查 0 候选 / drop rate 时直接 grep 此列。
-->

#### 5.3.1 过滤链路概览

**Search DAG**（`search_recall.yaml`）：
```text
各队列并行召回 → MergeRecallResultOp → SearchAdsInfoFilterOp → SnakeMergeFilterOp → BizTagCalculateOp → Pack
```

**Discovery DAG**（`recommend_game.yaml`）：
```text
各队列并行召回 → MergeRecallResultOp → RCMDAdsInfoFilterOp → RcmdAdsDedupOp → SnakeMergeFilterOp → BizTagCalculateOp → Pack
```

区别：Discovery 在 AdsInfoFilter 之后、SnakeMerge 之前多一步 `RcmdAdsDedupOp`（实时去重）。

#### 5.3.2 AdsInfoFilter 过滤链

AdsInfoFilter 是主过滤步骤，对 merge 后的每个候选广告逐条检查。Search 和 Discovery 共享 `CommonAdsInfoFilterOp` 基类，但各自注册不同的 filter 链。

**通用 baseCheck（两条链路共享）：**

| 过滤项 | 代码位置 | 条件 | Unpick Reason |
|--------|---------|------|---------------|
| ads info 存在性 | `common_operator/ads_info_filter_op.go` | `info == nil` 或 `info.GetAdsId() <= 0` | `OfflineFilterAdsNotExist` |

**Search 过滤链**（[search_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/search/search_ads_info_filter.go)）：

| 序号 | 过滤项 | 条件 | Unpick Reason |
|------|--------|------|---------------|
| 1 | 广告可见性 | `VisibleCheckByEntranceGroup(SEARCH)` → `AdsDormantConversionCheck`：广告时间有效 或 匹配 TagB 休眠转化标签 | `OfflineFilterAdsNotVisible` / `OfflineFilterAdsDormantConversion` |
| 2 | 审核 ID 过滤 | `CensoringFilter`：item 的 `censoring_ids` 命中平台/地区/搜索场景的屏蔽 ID；AB `SearchBlock1p` 控制是否屏蔽第一方卖家 | `OfflineFilterCensoring` |
| 3 | 类目黑名单 | `WhiteListFilter`：item 的 `GlobalCatIds` 命中 `disabledCats` 集合 | `OfflineFilterWhitelist` |
| 4 | Query 黑名单 | `AttrQueryBlacklistFilter`：广告的 `AttrQueryBlacklist` 等于原始 query 或分词后 token | `OfflineFilterAttrQueryBlacklist` |
| 5 | 类目白名单 | `WhiteListOnlyFilter`：白名单非空时，item 必须命中至少一个白名单类目 | `OfflineFilterWhitelist` |
| 6 | 非广告定价过滤 | `Roi3NonAdsPricing`：`PricingType == NonAdsPricing` | `OfflineFilterRoi3NonAdsPricing` |

**Discovery 过滤链**（[recommend_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/recommend_ads_info_filter.go)）：

| 序号 | 过滤项 | 条件 | Unpick Reason |
|------|--------|------|---------------|
| 1 | 广告可见性 | `VisibleCheckByEntranceGroup`：DD/YMAL/PP → `AdsDormantConversionCheck`；其他 → `TimeCheck` | `OfflineFilterAdsNotVisible` |
| 2 | Placement 过滤 | `IsPlacementMatchSource`：广告 placement 必须在当前入口允许的 placement 列表中 | `OfflineFilterCommon` |
| 3 | 明投视频匹配 | `IsMingTouVideoInfoMatch`：Video 入口下，明投广告的 `PostId` 必须等于请求的 `VideoID` | `OfflineFilterVideoNotMatch` |
| 4 | 暗投视频匹配 | `IsAnTouVideoInfoMatch`：Video 入口下，暗投广告的 `VideoList` 必须包含请求的 `VideoID`；AB `EnableVideoAntouFilter` 控制 | `OfflineFilterVideoNotMatch` |
| 5 | 视频 ROI 类型 | `IsVideoRoiTypeMatched`：Video 入口下，Spex `VideoFilterMark` 按 ROI type 匹配 placement 和 `PricingType` | `OfflineFilterVideoRoiType` |
| 6 | 审核 ID 过滤 | `IsCensoringIdMatch`：item 的 `censoring_ids` 命中平台/地区/场景（YMAL/DD 场景各有独立屏蔽 ID）的屏蔽规则 | `OfflineFilterCensoring` |
| 7 | 店铺评分 | `IsShopRatting`：`Shop.Rating < 1.0` 且非 ROI2/Video 入口 | `OfflineFilterShopRating` |
| 8 | 流量反作弊 | `IsTrafficMatch`：`TrafficControl.AntiFraudBlockProbabilities[0].BlockProb` 大于随机阈值 | `OfflineFilterTrafficBlock` |
| 9 | 店铺黑名单 | `IsShopMatch`：Spex `block_shop_info` 按入口/国家配置的店铺 ID 黑名单 | `OfflineFilterShopBlocked` |
| 10 | YMAL 同店过滤 | `IsYmalShopSame`：YMAL 入口下，广告店铺 == 请求 PDP 店铺 | `OfflineFilterYmalSameShop` |
| 11 | 定价类型过滤 | `IsPricingTypeMatch`：Game 入口下，`PricingType == CostPerSale` | `OfflineFilterPricingTypeMismatch` |
| 12 | 跨境店铺过滤 | `IsCrossBroderShop`：仅 ID 地区，`Shop.IsCrossBroder == true` | `OfflineFilterCrossBorder` |
| 13 | 非广告定价过滤 | `Roi3NonAdsPricing`：同 Search | `OfflineFilterRoi3NonAdsPricing` |

#### 5.3.3 实时去重（仅 Discovery）

`RcmdAdsDedupOp` 调用 `FilterShownRecallAds`（[ads_dedup_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/ads_dedup_op.go)）：

| 条件 | 说明 |
|------|------|
| 开关 | AB `RecallAutofreshEnable` 且 Spex `CountryDedupTTLSec` 非空 |
| 逻辑 | 请求携带 `DedupItemList`（已曝光 item + 时间戳），对每个候选检查 `now - timestamp < TTL`，在 TTL 内的 item 被去重 |
| 视频特殊逻辑 | Video 入口按 `video_id` 而非 `item_id` 去重 |
| 保护机制 | 若去重会导致某队列所有候选被移除，则跳过该队列的去重 |
| Unpick Reason | `OfflineFilterRealtimeFilter` |

#### 5.3.4 SnakeMerge（quota 截断）

`SnakeMergeFilterOp`（[snake_merge_filter_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/common_operator/snake_merge_filter_op.go)）：

- 按 AB `MergeQueueQuota` 配额比例，各队列交替取出候选（Zigzag 方式）
- 按 AB `RecallPickedNum` 截断到最终 TopK
- 未被 pick 的候选记录 Unpick Reason
- 实际“优先级”由 merge 输入顺序、`MergeQueueQuota` 和 `RecallPickedNum` 共同决定，不是某个队列把自己的 TopK 直接塞进粗排。不同 region × entrance 的在线 quota 需要回 AB Test Platform 查生效配置。

## 6. 样本及特征构成

<!--
Agent 阅读提示：
- §6 面向"训练样本 + 双塔特征清单"，以 §7 要展开的 LongSeq 623012104 模型（paidads-alg/recall/OnlineU2I/long-seq/）为主视角，其他队列特征面可能不同，请回到各自 yaml/py 验证。
- "Slot" 是样本侧的物理字段编号（一条样本中的位置）；"逻辑特征"是语义归并后的命名（多个 Slot 可能对应同一语义）。表格中"Slot → 逻辑特征"是归并后的视角（见 §6.1 标题 "38 Slot → 26 个逻辑特征"）。
- "CTR 共用"列标注该 Slot 是否与 CTR 样本共享；Recall 独占 = 该特征只出现在召回样本里（§6.4 有对照）。
- §6.6 Extra Embedding 是本模型独有的"稠密 embedding 直接替换 sparse fkey"方案，属于 LongSeq 的训练与 serving 关键形态，见 handoff 第七次修改。
-->

### 6.1 User 塔特征（38 Slot → 26 个逻辑特征）

#### 6.1.1 用户静态画像（7）

来自 FSE 表 `rcmd_user_feature`。

| Slot ID | 特征名 | FSE Column | 含义 | CTR 共用 |
|---|---|---|---|---|
| 30000 | U_UserID | userid | 用户唯一标识 | 是 |
| 30004 | U_MPIIPCity | mpi_ip_city | MPI 推断的用户 IP 所在城市，反映地理偏好 | 是 |
| 30360 | U_MPIAge | mpi_age | MPI 推断的用户年龄段，用于人群画像匹配 | 是 |
| 30361 | U_MPIGender | mpi_gender | MPI 推断的用户性别，用于性别偏好建模 | 是 |
| 30363 | U_ClickGlobalSubcats | click_global_sub_cat | 用户历史点击的全局二级类目分布，反映兴趣偏好 | 是 |
| 31446 | U_MPIAddressCity | mpi_address_city | MPI 推断的用户收货地址城市，反映购买地域 | 是 |
| 46354 | U_Country | country | 用户所在国家/地区（Recall 独占，用于分区训练路由） | **否** |

#### 6.1.2 用户行为序列（15 Slot → 12 个逻辑特征）

来自 FSE 长序列表（Non-MFP），覆盖 click / cart / order 三类行为，每类包含 ItemID、ShopID、GlobalSubCat、GlobalThirdCat 四个维度。

| Slot ID | 特征名 | FSE Table | FSE Column | 含义 |
|---|---|---|---|---|
| 45, 31253 | U_lt_click_ItemID | long_term_user_session_click_behavior | itemid | 用户长期点击过的商品 ID 序列 |
| 31254 | U_lt_click_ShopID | long_term_user_session_click_behavior | shopid | 用户长期点击商品所属的店铺 ID 序列 |
| 31331, 32457 | U_lt_click_GlobalSubCat | long_term_user_session_click_behavior | globalsubcat | 用户长期点击商品的全局二级类目序列 |
| 31332 | U_lt_click_GlobalThirdCat | long_term_user_session_click_behavior | globalthirdcat | 用户长期点击商品的全局三级类目序列 |
| 31327 | U_lt_cart_ItemID | long_term_user_session_cart_behavior | itemid | 用户长期加购过的商品 ID 序列 |
| 31328, 32416 | U_lt_cart_ShopID | long_term_user_session_cart_behavior | shopid | 用户长期加购商品所属的店铺 ID 序列 |
| 31333 | U_lt_cart_GlobalSubCat | long_term_user_session_cart_behavior | globalsubcat | 用户长期加购商品的全局二级类目序列 |
| 31334 | U_lt_cart_GlobalThirdCat | long_term_user_session_cart_behavior | globalthirdcat | 用户长期加购商品的全局三级类目序列 |
| 31329 | U_lt_order_ItemID | long_term_user_session_order_behavior | itemid | 用户长期下单过的商品 ID 序列 |
| 31330 | U_lt_order_ShopID | long_term_user_session_order_behavior | shopid | 用户长期下单商品所属的店铺 ID 序列 |
| 31335 | U_lt_order_GlobalSubCat | long_term_user_session_order_behavior | globalsubcat | 用户长期下单商品的全局二级类目序列 |
| 31336 | U_lt_order_GlobalThirdCat | long_term_user_session_order_behavior | globalthirdcat | 用户长期下单商品的全局三级类目序列 |

以上 15 个 Slot（12 个逻辑特征）全部与 CTR 共用。同一特征对应多个 Slot 是因不同模型版本或路由使用了独立的 Node。

#### 6.1.3 PDP 上下文（12 Slot → 5 个逻辑特征）

PDP 场景的 trigger item 属性，部分来自 Context（无 FSE 表），部分查询 `rcmd_item_feature`。

| Slot ID | 特征名 | FSE Column | 含义 |
|---|---|---|---|
| 1973, 30084, 39981 | Context_ItemID | — | 当前 PDP 页面的 trigger 商品 ID，YMAL 场景的锚点 |
| 30085, 51993 | Context_ShopID | — | trigger 商品所属的店铺 ID |
| 30093, 55233, 31197 | Context_item_GlobalSubCat | global_sub_category_id | trigger 商品的全局二级类目，用于类目对齐召回 |
| 17436, 30092, 31198 | Context_item_GlobalThirdCat | global_third_category_id | trigger 商品的全局三级类目，用于细粒度类目匹配 |
| 31193 | Context_item_IntentionL0V24 | intention_l0_v24 | trigger 商品的零级意图标签（V24 版本），表示购买意图大类 |

以上 12 个 Slot（5 个逻辑特征）全部与 CTR 共用。同一特征对应多个 Slot 是因不同模型版本或路由使用了独立的 Node。

#### 6.1.4 User Embedding — dense（2）

| Slot ID | 特征名 | FSE Table | FSE Column | 含义 |
|---|---|---|---|---|
| 24387 | llm_embedding | user_last_query_rt | llm_embedding | 用户最近一次搜索 query 经 LLM 编码后的 dense 向量，捕获语义搜索意图 |
| 35863 | Context_query_ftatt_embedding | — | — | 当前 query 经 FastText + Attention 编码的 dense 向量，轻量级语义表示 |

均与 CTR 共用。

#### 6.1.5 User Context（2）

| Slot ID | 特征名 | 含义 |
|---|---|---|
| 1224 | Context_entrance | 当前请求的流量入口类型（Search / Discovery / PDP），用于场景感知 |
| 5868 | Context_query_spm_token_list | 搜索 query 经 SentencePiece 分词后的 token ID 序列，用于文本匹配 |

均与 CTR 共用。

### 6.2 Item 塔特征（47 Slot → 27 个逻辑特征）

#### 6.2.1 商品基础属性（23 Slot → 9 个逻辑特征）

主要来自 FSE 表 `rcmd_item_feature`，覆盖 ID、类目、价格、库存等。

| Slot ID | 特征名 | FSE Column | 含义 | CTR 共用 |
|---|---|---|---|---|
| 32536, 32540, 60000 | I_ItemID | itemid | 商品唯一标识 | 是 |
| 30103, 30320 | I_ShopID | shopid | 商品所属店铺 ID，用于店铺级别偏好建模 | 是 |
| 30107, 30614, 36335 | I_GlobalCat | global_category_id | 全局一级类目 ID（最粗粒度类目划分） | 是 |
| 30108, 30615, 32286, 32288, 32289 | I_GlobalSubCat | global_sub_category_id | 全局二级类目 ID，核心类目匹配信号 | 是 |
| 30109, 30616 | I_GlobalThirdCat | global_third_category_id | 全局三级类目 ID（最细粒度类目划分） | 是 |
| 30344, 30601, 30612, 30829, 36346 | I_Price | price | 商品价格（本币），用于价格带匹配与价格敏感度建模 | 是 |
| 34183 | I_StockLocation | stock_location_type | 库存位置类型（本地仓 / 跨境仓 / 海外仓），影响物流时效 | 是 |
| 1659 | Q_spm_token_id | item_title_embedding.spm_token_id | 商品标题经 SentencePiece 分词后的 token ID，与 query token 做交互匹配 | 是 |
| 52484 | I_country_v2 | paidads_scoring_feature_category_item_v2.country | 商品所属国家/地区（Recall 独占，用于跨境场景分区） | **否** |

同一特征对应多个 Slot，原因同 §6.1.3。

#### 6.2.2 商品统计特征（14 Slot → 13 个逻辑特征）

来自 FSE 表 `rcmd_item_feature`，覆盖 7d / 14d / 30d 多个时间窗口的曝光、点击、加购、下单、评分、评论、折扣等统计量。

| Slot ID | 特征名 | FSE Column | 含义 |
|---|---|---|---|
| 30336 | I_NImpression7 | impr_7d_cnt | 商品近 7 天曝光次数，衡量短期热度 |
| 30353 | I_NImpression14 | impr_14d_cnt | 商品近 14 天曝光次数 |
| 30117, 30843 | I_NClick30 | click_30d_cnt | 商品近 30 天点击次数，衡量中长期受欢迎程度 |
| 30352 | I_NClick14 | click_14d_cnt | 商品近 14 天点击次数 |
| 30338 | I_NCart7 | cart_7d_cnt | 商品近 7 天加购次数，反映短期购买意向 |
| 30342 | I_NCart30 | cart_30d_cnt | 商品近 30 天加购次数 |
| 30116 | I_NOrder7 | order_7d_cnt | 商品近 7 天下单次数，反映短期转化能力 |
| 30603 | I_NSold | sold_cnt | 商品历史累计销量 |
| 30349 | I_CTR30 | ctr30 | 商品近 30 天点击率（click/impression），衡量吸引力 |
| 31170 | I_NRate30 | rate_30d_cnt | 商品近 30 天评分/评价次数 |
| 31171 | I_NComment30 | comment_30d_cnt | 商品近 30 天评论数量，反映用户互动活跃度 |
| 32284 | I_Discount | discount | 商品当前折扣力度（如 0.8 表示打八折） |
| 34204 | I_HasVoucherLabel | has_voucher_label | 是否有优惠券标签（bool），影响价格吸引力 |

以上 14 个 Slot（13 个逻辑特征）全部与 CTR 共用。

#### 6.2.3 商品 Tag / 语义（5 Slot → 2 个逻辑特征）

来自 FSE 表 `rcmd_item_feature` 的意图标签字段。

| Slot ID | 特征名 | FSE Column | 含义 |
|---|---|---|---|
| 30113, 30331, 30332 | I_IntentionsL1V24 | intention_l1_v24_list | 商品一级意图标签列表（V24 版本），如"服饰""电子"等购物意图分类 |
| 32547, 33128 | I_IntentionL0V24 | intention_l0_v24 | 商品零级意图标签（V24 版本），最粗粒度的购买意图大类 |

全部与 CTR 共用。

#### 6.2.4 Item Embedding — dense（2）

| Slot ID | 特征名 | FSE Table | FSE Column | 含义 |
|---|---|---|---|---|
| 11 | item_llm_embedding | query_understanding_item_tag | llm_embedding | 商品标题经 LLM 编码的 dense 向量，捕获深层语义 |
| 62736 | Q_ft_att_embedding | item_title_embedding | ft_att_embedding | 商品标题经 FastText + Attention 编码的 dense 向量，轻量级语义表示 |

均与 CTR 共用。

#### 6.2.5 店铺统计特征（3）

来自 FSE 表 `rcmd_shop_feature`。

| Slot ID | 特征名 | FSE Column | 含义 |
|---|---|---|---|
| 30496 | I_shop_NSold | sold_cnt | 店铺历史累计销量，反映店铺整体规模 |
| 32525 | I_shop_NSold7 | sold_7d_cnt | 店铺近 7 天销量，反映店铺短期活跃度 |
| 32529 | I_shop_ShopFollowCount | shop_follow_cnt | 店铺粉丝/关注数量，反映店铺受欢迎程度 |

全部与 CTR 共用。

### 6.3 两塔共享特征（4 Slot）

以下 Slot 同时出现在 User 塔和 Item 塔 DAG 中，用于两塔之间的 ID 对齐：

| Slot ID | 特征名 | FSE Column | 含义 |
|---|---|---|---|
| 28339 | I_ItemID | itemid | 两塔共享的商品 ID，用于 User 塔获取 target item 信息 |
| 16278 | I_ShopID | shopid | 两塔共享的店铺 ID |
| 30199 | I_GlobalSubCat | global_sub_category_id | 两塔共享的全局二级类目 ID |
| 36582 | I_GlobalThirdCat | global_third_category_id | 两塔共享的全局三级类目 ID |

全部与 CTR 共用。

### 6.4 与 CTR 样本的关系

Recall Scenario 79 共 228 个 Slot，其中 211 个与 CTR Scenario 82 共享，17 个为 Recall 独占。

在本次追踪的 89 个 DAG 在线推理 Slot 中，**仅 2 个为 Recall 独占**：

| Slot ID | 特征名 | FSE Table.Column | 含义 |
|---|---|---|---|
| 46354 | U_Country | rcmd_user_feature.country | 用户所在国家/地区，用于分区训练与跨境场景路由 |
| 52484 | I_country_v2 | paidads_scoring_feature_category_item_v2.country | 商品所属国家/地区，用于跨境场景分区匹配 |

其余 87 个 Slot 定义与 CTR 完全一致（同 Slot ID、同 FSE 映射），说明 Recall 双塔模型的特征体系与 CTR 高度对齐，训练样本中的特征定义可直接复用。

### 6.5 特征来源汇总

| FSE Table | 类型 | 涉及特征类别 | Slot 数 |
|---|---|---|---|
| rcmd_user_feature | Non-MFP | 用户画像（ID/性别/年龄/地址/国家/点击类目） | 7 |
| long_term_user_session_click_behavior | Non-MFP | 用户点击行为序列（ItemID/ShopID/SubCat/ThirdCat） | 6 |
| long_term_user_session_cart_behavior | Non-MFP | 用户加购行为序列 | 5 |
| long_term_user_session_order_behavior | Non-MFP | 用户下单行为序列 | 4 |
| rcmd_item_feature | Non-MFP | 商品属性/统计/Tag（类目/价格/曝光/点击/加购/下单/意图） | 48 |
| rcmd_shop_feature | Non-MFP | 店铺统计（销量/粉丝数） | 3 |
| user_last_query_rt | MFP | 用户最近 query LLM Embedding | 1 |
| query_understanding_item_tag | MFP | 商品 LLM Embedding | 1 |
| item_title_embedding | Non-MFP | query SPM Token / FastText Embedding | 2 |
| paidads_scoring_feature_category_item_v2 | — | 商品国家（Recall 独占） | 1 |
| （Context，无 FSE） | Context | 入口/query/PDP item ID/shop ID/Embedding | 11 |

> **数据来源**：AFP 平台 Scenario 79 (recall_server), DAG 1098/1099, 通过 `sra-afp` Skill 的 `analyse-slot` 命令逐 Slot 追踪血缘链，覆盖全部 89 个在线推理 Slot。

#### 6.5.1 高质量特征回答边界

当前 KB 没有 feature importance 或 SHAP 排名，因此不能断言“最重要 TopN 特征”。回答“有哪些可用高质量特征”时，建议按特征族说明可复用方向：

- User 侧：用户 ID、MPI 城市 / 年龄 / 性别 / 地址城市、历史点击类目、长期 click / cart / order 行为序列、最近 query LLM embedding、当前 query FastText + Attention embedding、SPM token、入口 Context。
- Item 侧：item / shop / category / price / stock、7/14/30 天曝光 / 点击 / 加购 / 下单 / CTR、销量、评价、折扣、voucher、意图标签、商品标题 LLM embedding、商品标题 FastText + Attention embedding、店铺销量和粉丝。
- RCMD LongSeq 额外特征：LLM Title Emb、MPI Title Emb、MPI Image Emb，经 external slot 挂载后用于 Target Item、PDP Trigger Item 和 Click Sequence。
- Recall 独占特征：当前在线推理链路中明确看到 `U_Country` 和 `I_country_v2`；其余多数 slot 与 CTR 样本共享，适合从 CTR / Rank 特征体系复用但仍需按对应模型 DAG 校验。

### 6.6 Extra Embedding 特征（RCMD 长序列模型专用）

RCMD 场景的在线长序列双塔模型（DAG 1331/1332, `recall_discovery_longseq_*`）引入了 **Extra Embedding 替换技术**：通过 EGO 平台的外部挂载（`import_extra_slots`），将指定 Slot 原有的 sparse fkey 替换为预计算的 LLM / MPI dense embedding，使序列特征获得多模态语义信息。

> 参考文档：[长序列模型方案](https://docs.google.com/document/d/1sxfoqsG2tkBXw_NRn27Cfjffg29M5O-dKtSN2X7Z-jA/edit?pli=1&tab=t.ns9lurhorfe1)

#### 6.6.1 Embedding 来源表

| 简称 | Hive 表 | 列名 | 维度 | 说明 |
|---|---|---|---|---|
| LLM Title Emb | `mkplpaidads_data.query_understanding_item_tag` | `llm_embedding` | 256 float | 大模型生成的商品标题 Embedding |
| MPI Title Emb | `mpi_data_mart.dws_all_item_seller_listing_title_embedding_tags_reg_df` | `emb` | 256 float | MPI 多模态模型标题 Embedding |
| MPI Image Emb | `mpi_data_mart.dws_all_item_seller_listing_image_embedding_tags_reg_df` | `emb` | 256 float | MPI 多模态模型图片 Embedding |

三张表以 `item_id` 为 key 取并集，各取前 64 维后按序拼接为 192 维向量，经哈希（MurmurHash3 + shared_slot_id）生成 fkey→embedding 映射表，写入 HDFS 供 EGO 平台加载。

映射表生成流程已迁移到 DataSuite 统一调度：
- **调度任务**：[DataSuite 10390147](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390147)
- **产出代码**：[DataSuite 10390057](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390057)

#### 6.6.2 Extra Slot 使用明细

模型代码：[longseq_model_base2.0.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_model_base2.0.py)

| 变量名 | Slot ID | 维度 | 挂载方式 | 用途 |
|---|---|---|---|---|
| `EXTRA_ITEM_SLOT` | 4491 | 48 | `import_extra_slots` + 外部映射表 | Target Item 的多模态 Embedding |
| `EXTRA_PDP_ITEM_SLOT` | 1973 | 48 | `import_extra_slots` + 外部映射表 | PDP Trigger Item 的多模态 Embedding |
| `EXTRA_CLK_Seq_SLOT` | 45 | 48 | `import_extra_slots` + 外部映射表 | 用户点击序列中每个 Item 的多模态 Embedding |
| `EXTRA_SLOT` | 2010, 2011, 2004, 4001, 4002, 4003, 4004, 8001, 30108 | 16 each | `import_extra_slots` | Shared Slot 映射 / 辅助特征 |
| — | 4006 | 48 | `import_extra_slots` | 附加 dense Embedding |

#### 6.6.3 模型中的处理流程

```
原始 Slot (sparse ID emb, dim=16×N)
  ├── 标准 ID 部分 ──→ concat ──→ [B, seq, 64]
  └── Extra Emb 部分 ──→ ExtraFeatureAdapter(LayerNorm → Dense → Dropout) ──→ [B, seq, 48]
        ↓
     concat(ID part, Extra part) ──→ SharedItemDNN ──→ [B, seq, 64] (统一表示)
```

`ExtraFeatureAdapter` 对外部挂载的 dense embedding 做对齐：先 LayerNorm 归一化，再经一层 Dense(ReLU) 映射到目标维度，附加 Dropout 正则化。处理后与标准 ID embedding 拼接，送入 `SharedItemDNN` 瓶颈层（256→128→64）得到统一维度表示。

该技术对 Target Item、PDP Item 和 Click Sequence 三个位置均应用相同的 Adapter + DNN 结构，使序列内每个 item 都携带 LLM/MPI 多模态语义信息。

> **适用范围**：仅用于 RCMD 场景的长序列模型（DAG 1331/1332），PDP 双塔模型（DAG 1098/1099）不使用此技术。

## 7. 训练 / 配置 / 上线范式（以队列 623012104 长序列模型为完整案例）

不是所有记录了队列号的召回队列，都对应“一个需要训练、上线 Serving、配置 AFP 特征”的模型。更稳妥的组织方式是：**先按实现范式分型，再决定应该记录成模型卡、离线产出卡还是队列链路卡**。

本章因此分两层阅读：
- `§7.0` 先给出所有带队列号路径的实现范式总览，说明每类通常能查到什么信息、适合用什么模板记录。
- `§7.1-§7.5` 继续以 Discovery 长序列 KNN 队列 `623012104` 作为**完整案例**，展示一条“在线模型 serving 型”路径从样本 → 训练 → Serving 的全流程。

<!--
Agent 阅读提示：
- §7.0 先给队列实现范式总览；真正完整展开的 full example 仍然只有 623012104。
- 不要默认"有队列号 = 有训练/EGO Serving/AFP"：Redis / Text / FSE / Fallback / Support 队列经常只有部分链路。
- 如需调查其他模型 / 队列，请先回到 §5.2.1 的类别判断，再决定走"完整模型卡 / 离线产出卡 / 队列链路卡"哪条路径。
- 代码目录 `paidads-alg/recall/OnlineU2I/long-seq/` 仅存在于 `exp` 分支（见 handoff 第十九次修改），所有 long-seq 代码链接已用 `-/blob/exp/...`；切勿改成 master。
- §7.3 离线训练调度 = DataSuite 10917479 + 物理机 ego_runner + EGO 训练平台三层架构（handoff 第十八次修改）；是"当前唯一生产级全量训练入口"。
- §7.4 EGO Serving 的 OhMyEmb 节点名以 graph-manager-conf/ohmyemb/*.yaml 为准（handoff 第十九次修改）：`rcmd_u2i_knn_recall@embeddingv2`、op 为 `SimpleStandardURankerOp`、item tower 离线模型名带 `_offline` 后缀。
-->

### 7.0 队列实现范式总览

本章建议采用两层结构来组织“非 LongSeq 模型/队列”的知识：

1. **第一层看实现范式**：决定这条路径有没有训练、有没有 online serving、有没有 AFP、以及排查时该去哪个平台。
2. **第二层看业务角色**：`main / support / manual / fallback / experimental` 等标签只作为补充说明，不单独决定文档模板。

#### 7.0.1 按实现范式分型

| 实现范式 | 是否训练 / 产出 | 是否通常有独立 online serving | 代表队列 | 说明 | 推荐模板 |
|---|---|---|---|---|---|
| 在线模型 serving 型 | 需要训练 | 通常有 | `611010104` / `611010103` / `623012104` / `623012108` / `677010101` / `653012101` / `655012101` | 在线推 Query/User Embedding，再做 Vespa ANN 检索；通常能串起 `AB -> OhMyEmb -> EGO -> AFP` | 完整模型卡 |
| 离线产出映射型 | 需要离线产出 | 通常无独立 serving | `611030109` / `611030110` / `111030201` / `622031201` / `622031101` | 离线算好 query→item / item→item / tag→item 映射，在线 Redis / KV 查表 | 离线产出卡 |
| 文本 / 规则 / 倒排检索型 | 通常不需要训练 | 无 | `611020304` / `111520301` / `111520302` / `677525101` / `677020301` / `611920304` | 依赖 Vespa 倒排、manual match、query/tag rewrite；重点是 `rank_profile`、索引字段、query 处理链 | 检索 / 规则卡 |
| 实时特征 / 实时统计型 | 通常不需要训练 | 无 | `611030202` / `612031201` / `677030202` | 依赖 FSE 或实时统计结果；重点是窗口、权重、更新时效与 key 设计 | 实时特征卡 |
| 两阶段 / 混合链路型 | 部分阶段需要 | 视 stage 而定 | `624012101` / `677030201` / `677525101` / `653031201` / `663031201` | 前段取 seed，后段再扩展；重点是 `node_chain`、每段 limit、依赖系统和 merge 顺序 | 链路卡 |
| 兜底 / 扶持 / 随机型 | 不需要训练 | 无 | `623922201` / `653940401` / `663940401` / `611610101` / `611610102` / `623612101` / `623612102` | 重点是默认开关、用途、降级层级、merge 位置，不应强行写成“模型卡” | 队列卡 |

#### 7.0.2 每类队列通常能查到哪些信息

| 实现范式 | 通常稳定可查 | 一般不该强求 |
|---|---|---|
| 在线模型 serving 型 | queue YAML、AB Feature/Layer、OhMyEmb 节点、EGO serving / checkpoint、AFP slot / DAG、样本、convertor、训练调度、`required_output` / `rank_profile` | 无；这是信息最完整的一类 |
| 离线产出映射型 | queue YAML、Redis `model/source`、离线代码路径、调度任务 / 更新周期、`outputMarker` / `inputMarker`、Data Delivery 基本信息、target key/index 语义、在线 op、反序列化 debug 路径 | 不应默认存在 EGO serving、OhMyEmb 节点或 AFP 完整链路；也不应把旧 SOP 中的 Redis 地址 / HDFS Router / 凭据写成 KB 事实 |
| 文本 / 规则 / 倒排检索型 | queue YAML、`rank_profile`、query rewrite / tag / keyword 路径、Vespa 索引字段、manual match 规则、AB 参数 | 不应强行补训练代码、convertor、EGO serving、AFP 特征配置 |
| 实时特征 / 实时统计型 | queue YAML、FSE 表 / key / window / weight、实时聚合口径、数据时效、更新频率 | 不应强行写成模型架构或 online serving 卡 |
| 两阶段 / 混合链路型 | `node_chain`、每段 limit、每段依赖（Redis / Vespa / FSE / KNN）、merge 输入顺序；若第一段是 KNN，可局部继续查模型信息 | 不应把整条链路硬压成一个“单模型摘要” |
| 兜底 / 扶持 / 随机型 | `downgrade_level`、触发场景、merge 位置、`rank_profile=random` / default recall、AB enable / quota、default role | 不应强行补训练、样本、convertor、AFP |

#### 7.0.3 推荐记录模板

- **完整模型卡**：用于在线模型 serving 型。固定记录 `架构 / 关键超参 / 样本 / convertor / 训练调度 / serving / AFP / 排查入口`。
- **离线产出卡**：用于 Redis / I2I / LLM Q2I / 实时统计类。固定记录 `离线逻辑或统计口径 / 产出位置 / 更新频率 / marker / transfer 类型 / target key 或 index prefix / 在线 op / debug 入口`。
- **链路 / 队列卡**：用于两阶段、文本规则、fallback、support。固定记录 `node_chain / 依赖系统 / AB key / limit / downgrade / merge 位置 / 排查入口`。

**离线产出映射型队列的常见 delivery 模式：**

| delivery 模式 | 典型输入 | 在线落点 | 适用说明 |
|---|---|---|---|
| `redis_common_pb` | 原始 parquet，经 Data Delivery 按 schema 转成通用 PB | Redis KV | 适用于“离线产出是结构化字段，平台负责 PB 序列化”的队列 |
| `redis_common_kv` | 业务侧已序列化好的 `key/value` parquet | Redis KV | 适用于“业务侧自己控制 value 编码”的队列 |
| stream / Vespa 类 | 视具体任务而定 | Vespa / 其他在线索引 | 是否使用、以及参数细节必须回到当前 workflow / delivery detail 验证，不能默认套用旧 SOP |

> 上表只保留 Databus SOP 中相对稳定的“实现范式”知识，不继承旧文档里的 Redis 地址、HDFS Router、账号密码、阈值默认值或联系人信息。

因此，`623012104` 这类长序列 KNN 更适合作为“**完整模型卡的 full example**”；而像 `623922201` 这类 game 兜底队列，重点应写成“**队列卡**”，记录默认召回用途、`rank_profile=random`、降级层级与 merge 位置，而不是去补不存在的训练 / serving / AFP 信息。

#### 7.0.4 训练目标与样本问题的回答口径

当用户问“Recall 目前的预估目标是什么”或“Recall 模型的样本是什么”时，先回到 `§7.0.1` 判断队列实现范式，再决定回答深度。只有“在线模型 serving 型”通常能完整回答训练目标、label、loss、负采样、样本、convertor、训练调度和 serving；Redis / Text / FSE / fallback 类队列应回答离线产出、规则或链路口径，不应硬补不存在的模型训练事实。

**完整模型卡建议至少包含：**

| 信息 | 回答要点 | 常见来源 |
|---|---|---|
| 预估目标 | 模型优化目标、label 定义、loss、温度/采样等关键超参 | 训练代码、model config、EGO 训练配置 |
| 评估指标 | AUC / PCoC / Recall@K / Precision@K 等，必须说明 region / scene 粒度 | eval report、DataSuite 离线评估 |
| 样本来源 | 原始表或 HDFS 路径、日期粒度、region / scene 分区 | 样本 SQL、DataSuite workflow、训练任务 |
| 样本过滤 | entrance、click/order、可索引广告、context item 等过滤条件 | 样本 SQL、convertor、ground truth SQL |
| 特征与 convertor | slot 清单、特殊 reshape / hash / extra embedding、正负样本构造 | convertor、AFP、feature config |
| 训练与上线 | EGO job、checkpoint、serving model、OhMyEmb / Retrieval DAG 节点 | EGO Portal、OhMyEmb、graph-manager-conf |

以本章完整案例 `623012104`（Discovery LongSeq U2I）为例，可以回答：

- **预估目标**：双塔 U2I 点击对齐目标，正样本来自点击行为；loss 使用 Softmax Cross-Entropy（inner product / temperature），评估看 region × scene 维度的 AUC / PCoC。
- **样本口径**：从 CTR parquet 读取样本，过滤 DD / YMAL 入口且 `action_info.click IS NOT NULL`，输出到 `longseq_sample_v1/{country}/{date}/00`，后续由 convertor 生成 EGO 训练样本。
- **标签与负采样**：convertor 中正样本 `label=1, weight=1`；负样本通过 EGO NSC 机制产生，当前 LongSeq 案例配置为 `sample_ratio=127, share_batch=False`，可近似理解为每个正样本配 127 个负样本且不跨 batch 共享。
- **特征补充**：除标准 User / Item / Seq / Query slot 外，还会挂载 LLM Title Emb、MPI Title Emb、MPI Image Emb 等 Extra Embedding，细节见 `§6.6`。
- **Hard negative 边界**：KB 当前没有全局 hard negative 定义，不能静态断言所有队列都采用同一种 hard negative。若参考 Search 长尾优化类方案，常见做法是把同 request 中曝光 / 召回但未点击的 item 作为 hard negative；但这应写成具体方案口径，不应泛化为全 Recall 现状。

不要把上面这个 LongSeq 案例直接泛化到 Search KNN、UniModel、U2U2I、LLM Q2I、I2I KV、Realtime Popular 或 fallback 队列。遇到这些队列时，先按 `§5.2.1` 的检索方式和 `§11.3.5` 的队列字段反查模型 / 任务 / 下发链路，再补成对应的模型卡、离线产出卡或队列卡。


### 7.1 样本构造

#### 7.1.1 样本来源与过滤

样本构造代码：[longseq_sample.sql](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_sample.sql)

| 项目 | 说明 |
|---|---|
| 原始数据 | CTR parquet 样本：`hdfs://R2/projects/mkplpaidads_offline/hdfs/prod/alg/ads/train_data_parquet/ctr/all/{country}/{date}/*` |
| 输出路径 | `hdfs://R2/projects/mkplpaidads_search_ads/hdfs/prod/public_sample/product_ads/recall/common/longseq_sample_v1/{country}/{date}/00` |
| 过滤条件 | `slot_1224`（entrance）∈ {3.0=DD, 4.0=YMAL}，且 `action_info.click IS NOT NULL`（仅保留有点击的样本） |
| 分区粒度 | 按 country × date 分区，每分区 400 个 parquet 文件 |

样本涵盖的 Slot 包括：
- **User Slot**：1973, 30000, 30004, 30360, 30361, 30363, 31446, 30084, 30085, 31193, 31197, 31198, 30093, 30092, 1224 等（共 34 个）
- **Item Slot**：4491, 28339, 16278, 30199, 36582, 60000, 30103, 30108, 30109 等（共 87 个）
- **Seq Slot**：45, 31253, 31254, 31331, 31332, 31327, 31328, 31333, 31334, 31329, 31330, 31335, 31336, 47020, 13853（共 15 个）
- **Query Slot**：5868, 35863

#### 7.1.2 Convertor（样本预处理）

Convertor 代码：[convertor_dcr_longseq_base.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/convertor_dcr_longseq_base.py)

| 项目 | 说明 |
|---|---|
| 输入格式 | `sample_id \t debug_info \t action_str \t dense \t sparse` |
| 过滤逻辑 | 跳过 Search 样本（`slot_1224 == 1`），仅保留 DD/YMAL |
| 标签 | 正样本 `label=1`，权重 `weight=1`；负采样由 EGO NSC 机制完成 |
| Country 映射 | MY=1, TH=2, SG=3, ID=4, TW=5, VN=6, PH=7, BR=8 |
| Dense 追加 | 自动追加 `#46354:{country}` 到 dense 特征末尾 |
| 输出格式 | `sample_id \t label dense #user_id:xx #multitask:xx sparse #item_id:xx #neg_type:xx` |

### 7.2 模型架构

模型代码：[longseq_model_base2.0.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_model_base2.0.py)

#### 7.2.1 整体结构

```text
User Tower:
  User Sparse (5 slot, 80-dim) → Dense(64)
  Click Seq (4 ID slot × 500, 64-dim) + Extra Emb (48-dim) → ExtraAdapter → SharedItemDNN → [B, 500, 64]
  PDP Item (4 ID slot, 64-dim) + Extra Emb (48-dim) → ExtraAdapter → SharedItemDNN → [B, 1, 64]
  Position Embedding(500) → History Context
  LongTermInterestExtractor(2 latent tokens, cross-attn)
  DD prompt: [user_static, long_term_interest(2), recent_3] → 6 tokens
  YMAL prompt: [user_static, pdp_emb, recent_4] → 6 tokens
  → 3-layer ReasoningBlock(MoE, cross-attn with seq_len 500→200→50)
  → Flatten → Dense(64) → L2 Normalize → user_emb_output

Item Tower:
  Item Sparse (4 slot, 64-dim) + Extra Emb (48-dim) → ExtraAdapter → SharedItemDNN → [B, 1, 64]
  → L2 Normalize → item_emb_output
```

#### 7.2.2 关键超参数

| 参数 | 值 | 说明 |
|---|---|---|
| `EMB_SIZE` | 16 | 标准 sparse embedding 维度 |
| `EXTRA_EMB_SIZE` | 48 | Extra Embedding（LLM/MPI）维度 |
| `TOTAL_EMB_DIM` | 64 | 统一表示维度 |
| `CLK_Seq_LEN` | 500 | 点击序列长度 |
| `BLOCKS` | 3 | ReasoningBlock 层数 |
| `NUM_HEADS` | 1 | 注意力头数 |
| `FFN_HIDDEN_UNIT` | 128 | FFN 隐层 |
| `temperature` | 0.1 | Softmax 温度 |
| `neg_num` / NSC | 127 | 负采样率（EGO NSC share_batch=False） |
| `CONTEXT_N` | 5 | Prompt token 数 |

#### 7.2.3 训练配置

| 项目 | 说明 |
|---|---|
| 训练框架 | EGO（`ego.compile`） |
| 负采样 | NSC（`sample_ratio=127, share_batch=False`） |
| 分区训练 | 按 `region × scene(DD/YMAL)` 分 16 个 partition（MY/TH/SG/ID/TW/VN/PH/BR × DD/YMAL） |
| 损失函数 | Softmax Cross-Entropy：`-label * log(softmax(inner_prod / 0.1))` |
| 评估指标 | 按 region × scene 分别计算 AUC（如 `ctr_auc_DD_ID`、`ctr_auc_YMAL_TW`） |
| 增量训练 | 支持 checkpoint 增量更新（`ckpt#...-inc`） |

#### 7.2.4 特征依赖总结（与 §6 对应）

| 模型组件 | Slot 来源 | 对应章节 |
|---|---|---|
| User Sparse | `USER_SLOT`: 30363, 30000, 30361, 30360, 31446 | §6.1.1 |
| Click Sequence | `CLK_Seq_SLOT`: 31253, 31254, 31331, 31332 | §6.1.2 |
| PDP Item | `PDP_ITEM_SLOT`: 30084, 30085, 31197, 31198 | §6.1.3 |
| Entrance / Country | 1224 / 46354 | §6.1.5 / §6.4 |
| Target Item | `ITEM_SLOT`: 60000, 30103, 30108, 30109 | §6.2.1 |
| Extra Embedding | `EXTRA_ITEM_SLOT`(4491), `EXTRA_PDP_ITEM_SLOT`(1973), `EXTRA_CLK_Seq_SLOT`(45) | §6.6 |
| Extra Shared Slot | `EXTRA_SLOT`: 2010, 2011, 2004, 4001-4004, 8001, 30108 + 4006 | §6.6.2 |

### 7.3 离线训练调度

模型训练通过 EGO 调度框架例行执行，该框架基于 DataSuite 调度 + 物理机提交 + EGO 训练平台三层协作。详细使用手册见 [EGO 调度用户手册](https://docs.google.com/document/d/1GrUQ8ZuufZSnMrrGDICUkRL3rmKmvwbaIDFmvurBjyQ/edit)。

#### 7.3.1 调度框架概述

```text
DataSuite（调度触发）
  ↓ 按 BIZ_DATE 天级触发 SSH 节点
物理机（ego_runner）
  ↓ git pull → 读取 ego_tasks/{model_name}_{model_version}/ 下的 task.yaml + ego-learner.yaml
  ↓ 执行 train.sh → 向 EGO 平台提交训练/发布任务
EGO 训练平台
  ↓ 拉取 HDFS 样本 → DataConvertor 预处理 → GPU 训练 → 保存 Checkpoint
  ↓ check_metrics → release → 线上 Serving 自动更新
```

调度涉及的代码目录（均在 [paidads-alg](https://git.garena.com/shopee/deep/paidads-alg) 仓库 `exp` / `online` 分支）：

| 目录 | 职责 |
|---|---|
| `ego_runner/` | 调度脚本（`train.sh` / `config.py`），用户无需修改 |
| `ego_tasks/{model_name}_{model_version}/` | 每个调度任务的配置文件：`task.yaml`（训练/发布参数）+ `ego-learner.yaml`（特征/样本/Convertor 参数） |
| `ego_models/convertor/` | DataConvertor 代码，由调度脚本自动打包上传 |
| `ego_models/model_modules/` | 模型代码，通过 `package.sh` 打包上传到 EGO 平台 |

#### 7.3.2 线上训练调度任务

长序列模型的线上例行训练调度任务为 [DataSuite 10917479](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10917479)，该任务每天完成训练获得新的 Checkpoint 后，自动更新到 EGO Serving。

更新频率回答边界：`623012104` 长序列主模型可以明确回答为天级更新；FSE realtime / popular 类队列依赖实时特征或实时聚合，通常是准实时 / 实时更新；Redis / I2I / LLM Q2I / QT2I 等离线映射型队列依赖各自 workflow、marker 和 Data Delivery 链路，KB 不维护逐队列频率快照，需要按 §11.3.5 的 `queue -> workflow -> marker -> delivery` 路径逐个反查。

一个完整的例行调度包含 5 个串联步骤：

| 步骤 | job_type | 调度逻辑 | 说明 |
|---|---|---|---|
| 种子轮 | `train` | 每天 load T-9 的 ckpt，训练 T-8 数据 | 依赖样本产出任务 |
| 增量轮 | `incrementTrain` | 每天 load 种子轮 T-8 的 ckpt，训练 T-7 至 T-2 数据 | 依赖种子轮完成 |
| 指标检查 | `check_metrics` | check 增量轮 eval 轮 T-2 数据的 AUC / PCoC | 依赖增量轮完成 |
| 评估轮 | `eval` | load 增量轮 T-2 ckpt，使用 T-1 数据评估 | 依赖增量轮完成 |
| 模型发布 | `release` | release 增量轮 T-2 的 ckpt 到线上 | 依赖 check_metrics 通过 |

DataSuite 调度节点配置示例：

```text
ENV_NAME="ego_tasks_exp";
job_type="train";
model_name="recall_rcmd_longseq_v2";
model_version="prd_s_sg";
backfill_time_begin="";
backfill_time_end="";
cd /ldap_home/mkplpaidads_search_ads/common/$ENV_NAME/ads_algo/paidads-alg/ego_runner/;
git pull;
bash train.sh --date=${BIZ_DATE} --job_type=$job_type --model_name=$model_name --model_version=$model_version \
  --backfill_time_begin=$backfill_time_begin --backfill_time_end=$backfill_time_end
```

#### 7.3.3 关键配置参数

**task.yaml** 关键字段：

| 参数 | 说明 |
|---|---|
| `date_offset` | 训练数据偏移量（如 -1 表示使用前一天数据） |
| `continues_train_days` | 从数据开始日期连续训练的天数 |
| `model_bank` | 首次训练 load 的 checkpoint_id，为空则从最近 ckpt 继续或从头训练 |
| `skip_date` | 跳过指定日期的训练数据 |
| `resource.*` | GPU 类型（A30/A100-80GiB）、worker 数、内存、SS 数 |
| `increment_train.from_model_name/version` | 增量轮从哪个 seed 模型继承 ckpt |
| `release.online_model_name` | 线上模型名，需 `gpu_` 开头 |
| `release.project_name` | 发布项目（如 `PaidadsUniCR`） |
| `check_metrics.targets` | 指标校验规则（AUC 上下界、PCoC 公式） |

**ego-learner.yaml** 关键字段：

| 参数 | 说明 |
|---|---|
| `data_path` / `data_done_file` | HDFS 样本路径和完成标志 |
| `sample_type` | 样本格式（`parquet`） |
| `data_converter` | DataConvertor 执行脚本 |
| `minibatch_size` | 训练 batch size |
| `pass_size` | 每轮 eval 间隔样本数 |
| `converter_config.converter_name` | 注册的 Convertor 类名 |

#### 7.3.4 任务命名规范

| 任务类型 | model_name 格式 | model_version 格式 | 限制 |
|---|---|---|---|
| 调研类（backfill） | `tmp_{name}_{region}` | 自定义 | SG 限 1 个，US 限 3 个 |
| 实验类 | `exp_{name}_{region}` | 自定义 | 国家去重后限 2 个 |
| 全量类（线上） | `prd_{name}_{region}` | `prd_s_{region}`（种子）/ `prd_i_{region}`（增量） | 不限 |

#### 7.3.5 Backfill（回溯训练）

当需要连续训练大量历史数据时，使用 DataSuite 的 Backfill 功能：

1. 在调度页面配置 `start_date` 和 `end_date`，设置 `Task Instance Concurrency=1`
2. 调度脚本通过 `backfill_time_begin` / `backfill_time_end` 参数控制 ckpt 清理范围
3. Backfill 结束后需**冻结调度任务**，否则会继续例行调度

#### 7.3.6 Checkpoint 管理

- **Baseline 保护**：将 model_version 配置为 Baseline 可避免 ckpt 被自动删除
- **自动清理策略**：保留最近 3 天 ckpt → 近 1 月每周保留 1 个 → 1~2 月每 2 周保留 1 个 → 2 月以上仅保留 1 个
- **手动白名单**：在 [EGO 项目管理](https://ego-portal.mlp.shopee.io/management/projectManagement/list) 中手动加白名单保护 ckpt
- **US→SG 跨集群**：通过 EGO 的 Sync 功能（Quick Sync / Validate Then Sync）将 US 集群 ckpt 复制到 SG 继续训练或直接 release

### 7.4 EGO Serving

#### 7.4.1 在线部署概况

> 训练完成后，模型通过 §7.3 的调度框架自动 release 到 EGO Serving，更新以下在线推理服务。

| 项目 | User Tower | Item Tower |
|---|---|---|
| **Serving 名** | `recall_rcmd_longseq_v2_user_tower` | `recall_rcmd_longseq_v2_item_tower` |
| **Online Model ID** | 22081 | 22080 |
| **版本** | #54 (version_id: 1966856) | #54 (version_id: 1966857) |
| **状态** | serving | serving |
| **QPS** | ~14,175 | ~2,157 |
| **Tenant / Project** | paidads / ads_recall (100217) | paidads / ads_recall (100217) |
| **Predictor Service** | `paidads-recall` (152523) + `paidads-recall-offline` (693474) | 同左 |
| **ZK 注册** | `zk-ai_platform-global-live` | 同左 |

两个 Tower 共享同一离线模型（`Product_Ads-Recall-LongSeqModel-v1`, model_id: 9056）和 Checkpoint（id: 6232633），由同一次训练产出后拆分。

#### 7.4.2 AFP 节点配置

User Tower 和 Item Tower 在 AFP 平台上分别对应 DAG Group 1331 和 1332（Scenario 79, Project 12），通过 OhMyEmb 服务中转推理。

**User Tower**（[online_query_user.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/online_query_user.yaml) 节点 `rcmd_u2i_knn_recall@embeddingv2`）：

| 字段 | 值 |
|---|---|
| `op` | `SimpleStandardURankerOp` |
| `service_name` | `StandardURankerRcmdOnline` |
| `business` | `paidads_rcmdrecall_online` |
| `emb_column_name` | `user_emb_output` |
| `model_name`（非 BR） | `recall_rcmd_longseq_v2_user_tower` |
| `model_name`（BR） | `recall_rcmd_longseq_v2_user_tower_br` |
| `required_feature` | Context_ItemID, Context_ItemID_v2, Context_ShopID, Context_ShopID_v2, Context_entrance |

**Item Tower**（[offline_item.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/offline_item.yaml) 节点 `rcmd_u2i_knn_recall@embeddingv2`）：

| 字段 | 值 |
|---|---|
| `op` | `SimpleStandardURankerOp` |
| `service_name` | `StandardURankerRcmdOffline` |
| `business` | `paidads_rcmdrecall_offline` |
| `emb_column_name` | `item_emb_output` |
| `model_name`（非 BR） | `recall_rcmd_longseq_v2_item_tower_offline` |
| `model_name`（BR） | `recall_rcmd_longseq_v2_item_tower_br_offline` |

#### 7.4.3 Grafana 监控

| 面板 | 监控内容 |
|---|---|
| [Predictor - User Tower](https://monitoring.infra.sz.shopee.io/grafana/d/HTScQnYVz/egopredictor-basis?orgId=38&var-model=recall_rcmd_longseq_v2_user_tower) | User Tower 推理延迟/QPS/错误率 |
| [Predictor - Item Tower](https://monitoring.infra.sz.shopee.io/grafana/d/HTScQnYVz/egopredictor-basis?orgId=38&var-model=recall_rcmd_longseq_v2_item_tower) | Item Tower 推理延迟/QPS/错误率 |
| [OnlinePS - User Tower](https://monitoring.infra.sz.shopee.io/grafana/d/sZMn18sVk/ego-onlineps-jian-kong-lyra?orgId=38&var-model_name=recall_rcmd_longseq_v2_user_tower_1966856) | User Tower PS 参数服务器监控 |
| [OnlinePS - Item Tower](https://monitoring.infra.sz.shopee.io/grafana/d/sZMn18sVk/ego-onlineps-jian-kong-lyra?orgId=38&var-model_name=recall_rcmd_longseq_v2_item_tower_1966857) | Item Tower PS 参数服务器监控 |

### 7.5 上线分支参考

队列 `623012104` 和长序列模型 `recall_rcmd_longseq_v2` 在各仓库中的分支：

| 仓库 | 分支 | 用途 |
|---|---|---|
| [graph-manager-conf](https://git.garena.com/shopee/deep/searchads/graph-manager-conf) | [`self-knn-que/U2I_KNN_623012104`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/tree/self-knn-que/U2I_KNN_623012104) | 队列 DAG 配置（retrieval/） |
| [graph-manager-conf](https://git.garena.com/shopee/deep/searchads/graph-manager-conf) | [`self-knn-model/recall_rcmd_longseq_v2`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/tree/self-knn-model/recall_rcmd_longseq_v2) | 模型节点配置（ohmyemb/） |
| [paidads-recall](https://git.garena.com/shopee/deep/paidads-recall) | [`self-knn-que/U2I_KNN_623012104`](https://git.garena.com/shopee/deep/paidads-recall/-/tree/self-knn-que/U2I_KNN_623012104) | Retrieval 服务 AB 参数注册 + graph version |
| [oh-my-embedding](https://git.garena.com/shopee/deep/oh-my-embedding) | [`self-knn-model/recall_rcmd_longseq_v2`](https://git.garena.com/shopee/deep/oh-my-embedding/-/tree/self-knn-model/recall_rcmd_longseq_v2) | OhMyEmb graph version 更新 |

> 上表是 `623012104` 的历史完整上线参考。当前新增模型 / 队列时，优先按 §8 的 skill-first 流程推进；`oh-my-embedding graph_version` 和服务发布属于后续交接步骤，不是 `ads-recall-ohmyemb-add-model` 默认执行范围。

## 8. 召回上线流程

> 首选自动化 skill：
> - [ads-recall-ohmyemb-add-model](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/team/01.ads-engineering/ads-recall-ohmyemb-add-model)：新增 OhMyEmb / SimpleStandardURankerOp 模型节点，内置配置收集、YAML 预览、`model_conf` 测试和提交门禁。
> - [ads-recall-add-queue](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/team/01.ads-engineering/ads-recall-add-queue)：新增 KNN / KV 召回队列，内置参考队列加载、DAG / AB / Makefile 预览、ABTestConfig 校验、RESP Lab 预发测试和 MR 门禁。
> - [ads-recall-ohmyemb-debug](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/team/01.ads-engineering/ads-recall-ohmyemb-debug)：OhMyEmb 日常调试，支持 `model_conf` / `required_output` / compare、random case、curl 输出和 embedding 结果分析。
>
> 新版 SOP 参考：[recall sop by agent](https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY/edit)，其中 KNN 队列见 [`knn-que_ZH`](https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY/edit?tab=t.ip45bggpv6w0)，KNN 模型见 [`add-model_ZH`](https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY/edit?tab=t.c6e377xrra7m)。

<!--
Agent 阅读提示：
- §8 是三条并行但有依赖的上线线：
  1. 队列线（§8.1）— 优先使用 ads-recall-add-queue；它负责 graph-manager-conf/retrieval 节点、MergeRecallQueue 输入、paidads-recall GraphManagerVersion / ABTestConfig 校验和 RESP Lab 预发测试。
  2. 模型线（§8.2）— 优先使用 ads-recall-ohmyemb-add-model；它负责 graph-manager-conf/ohmyemb 节点、node_name 唯一性校验和 ads-recall-ohmyemb-debug 的 model_conf 测试。不要把旧 SMS 流程当成主路径。
  3. 实验线（§8.4/§8.5）— 在 AB Test 平台配 Feature/Layer/Exp，然后做 rollout。
- 顺序：新队列如果还依赖新模型，必须先完成模型节点配置和 OhMyEmb debug 测试，再走队列线；真正发布 / tag / AB 实验由对应 master 或平台流程确认，agent 不越权触发生产发布。
-->

### 8.1 添加 KNN 队列

适用于：在已有 KNN 模型的基础上，新增一个在线召回队列。

**首选流程**：使用 `ads-recall-add-queue`。该 skill 会从 `graph-manager-conf/retrieval` 动态读取同类型参考队列，生成完整 DAG / AB / Makefile 预览，并在用户确认后执行修改、校验和预发测试。手工 SOP 只作为背景参考，见新版 Google Doc 的 [`knn-que_ZH`](https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY/edit?tab=t.ip45bggpv6w0)。

| 阶段 | skill 行为 | 关键门禁 / 输出 |
|---|---|---|
| Round 1 信息收集 | 收集 `queue_kind=KNN`、`scene`、`recall_type`、`queue_name`、可选 `reference_queue`、KNN 前置条件和 AB 参数状态 | 必须确认 Vespa / Embedding / 向量数据已就绪；`knnRecallCfg{queue_name}` 与 `model_param_key` 已在 AB 平台创建或确认存在 |
| Round 2 预览 | 选择同类最新参考队列，生成新节点和 `MergeRecallQueue` 输入变更 | 展示参数差异表、完整 DAG YAML、merge 输入追加位置、AB 默认值；用户确认前不改文件 |
| 执行变更 | 修改 `graph-manager-conf/retrieval/{dag_file}.yaml`，再修改 `paidads-recall` 的 `GraphManagerVersion` 并更新 `adsengine-abtest-param` | 分支命名 `{username}/feat/{AlgoType}-{queue_name}`；校验 `ABTestConfig` 中存在 `knnRecallCfg{queue_name}` 和 `model_param_key` 的 JSON tag |
| 预发测试 | 推送分支后等待 RESP Lab 部署，执行 1 次 preliminary test | `op_debug_info` 中出现新节点，`_trace_detail_.result_count > 0`，Label 中出现新 `queue_name` |
| 合并交接 | 测试通过后再由用户确认是否提 MR | graph-manager-conf 先合并打 tag，再更新 paidads-recall `GraphManagerVersion`；生产发布由 Recall Master / Release 平台处理 |

**KNN 队列关键字段**：

| 字段 | 口径 |
|---|---|
| `ab_param_key` | 固定为 `knnRecallCfg{queue_name}`，注意首字母小写 |
| `model_param_key` | ABTestConfig 中的模型参数字段，用于运行时指定 Vespa cluster / rank profile / embedding field |
| `vespa_name` | Vespa application / table 名，可被 `model_param_key` 覆盖 |
| `rank_profile` | Vespa rank profile，可被 `model_param_key` 覆盖 |
| `required_output` | embedding 字段标识；新接入推荐用 `vespa_name@embedding{rank_profile}` 对齐模型参数 |
| `recall_limit` / `additional_hit` | 召回上限和额外候选数，默认继承参考队列，改动需在预览阶段确认 |
| `downgrade_level` / cache 字段 | 降级和缓存策略，默认继承参考队列；U2U / Q2I 场景需额外确认缓存 key、`target_hits` 或 `label2recall_limit` |

**场景到 op 的常用映射**：

| 场景 | recall_type | op | 目标 DAG |
|---|---|---|---|
| DD / YMAL / PP / Game | `u2i` | `KnnU2IOp` | `recommend_{scene}.yaml` |
| DD / YMAL / PP / Game | `u2u` | `KnnU2UOp` + `GetFseU2IOp` | `recommend_{scene}.yaml` |
| Search | `q2i` | `KnnQ2IOp` | `search_recall.yaml` |
| Live / Video / Shop | `u2l` / `u2v` / `q2s` 等 | 按 skill 的 scene mapping 选择 | `live_ads_recall.yaml` / `video_ads_recall.yaml` / `shop_search_retrieval.yaml` |

### 8.2 添加 KNN 模型

适用于：上线新的双塔模型用于 KNN 召回（新队列或替换已有队列的模型）。

**首选流程**：使用 `ads-recall-ohmyemb-add-model`。该 skill 的职责范围是把新的 `SimpleStandardURankerOp` 节点加入 `graph-manager-conf/ohmyemb`，并用 `ads-recall-ohmyemb-debug` 的 `model_conf` 模式测试通过后提交代码等待合入。新版手工 SOP 见 Google Doc 的 [`add-model_ZH`](https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY/edit?tab=t.c6e377xrra7m)。

| 阶段 | skill 行为 | 关键门禁 / 输出 |
|---|---|---|
| 配置收集 | 收集 `target_dag`、`node_name`、`service_name`、`business`、`model_name`、`item_type`、`emb_column_name`、可选 `required_feature` | `target_dag` 只能是 `online_query_user`、`offline_item` 或 `offline_query_user`；收到 `node_name` 后必须在目标 YAML 校验唯一性 |
| 改动预览 | 生成 `graph-manager-conf/ohmyemb/*.yaml` 的完整节点块和插入位置说明 | 展示 YAML 字符串到 `model_conf` proto 数字的转换；用户确认前不改文件 |
| 模型通道测试 | 调用 `ads-recall-ohmyemb-debug` 的 `model_conf` 模式，默认 live 环境，可使用 random sampled case | 输出可复制 curl、request/response 和 embedding 维度 / 数量分析 |
| 提交等待 | 测试通过且用户确认后，只提交 graph-manager-conf 相关改动 | 不默认更新 `oh-my-embedding` 的 `graph_version`，不默认发布 online/offline service，不默认检查 Redis/Vespa，不默认配置 AB 实验 |
| 后续交接 | 若确实需要发布、`graph_version`、Vespa 数据写入或实验配置，按 Google Doc 手工 SOP 和平台 owner 继续 | 发布 / tag / AB 实验由 Recall Master、OhMyEmb owner 或实验 owner 明确确认后推进 |

**OhMyEmb 节点关键字段**：

| 字段 | 口径 |
|---|---|
| `name` | DAG 节点名，通常为 `{vespa_table}@{field}`，例如 `paidads_item@embeddingv1` |
| `op` | 固定为 `SimpleStandardURankerOp` |
| `service_name` | Graph Manager YAML 中写不带 `SG` / `US` 后缀的字符串，例如 `StandardURankerRcmdOnline`；`model_conf` 测试时再转换为 SG proto 数字 |
| `business` | 必须与 URanker 注册 business 一致，例如 `paidads_rcmdrecall_online`、`paidads_searchrecall_offline` |
| `model_name` | 算法提供的 URanker 模型名；为空会导致节点静默跳过 |
| `item_type` | YAML 使用 `PRODUCT` / `VIDEO` / `LIVE`；`model_conf` 测试使用 `1 / 2 / 3` |
| `emb_column_name` | 精确的 score head / embedding 列名，大小写敏感 |
| `required_feature` | 可选；YAML 使用 `Context_entrance` 等字符串，`model_conf` 测试使用 proto 数字；offline item 常见为省略 |

`service_name` 常用映射：`RcmdOnline=54`、`RcmdOffline=53`、`SearchOnline=48`、`SearchOffline=47`、`VideoOnline=36`、`VideoOffline=35`、`LiveOnline=42`、`LiveOffline=41`。这些数字只用于 `paidads.emb_service.get_embedding` 的 `model_conf` 测试；Graph Manager YAML 仍写无后缀字符串。

端到端上线顺序可拆成三条线：模型线先完成 OhMyEmb 节点配置、`model_conf` / `required_output` 测试和数据 ready；队列线再新增 retrieval DAG 节点、merge 输入、AB 参数注册与 liveish / RESP Lab 测试；实验线最后在 AB Test Platform 配置 Feature / Layer / Exp，并把实验 `group_id` 加到 Retrieval 和 Engine 的 Space 配置中，随后观察 Grafana 漏斗、Queue Metrics 和 AB 报表。`ads-recall-ohmyemb-add-model` 与 `ads-recall-add-queue` 默认只推进到代码改动、测试和 MR 门禁，生产 tag / release / AB 生效仍需要对应 owner 明确确认。

### 8.3 涉及仓库汇总

| 仓库 | 上线用途 |
|---|---|
| [graph-manager-conf](https://git.garena.com/shopee/deep/searchads/graph-manager-conf) | 队列 DAG 配置（`retrieval/`）+ 模型节点配置（`ohmyemb/`） |
| [paidads-recall](https://git.garena.com/shopee/deep/paidads-recall) | Retrieval 服务：AB 参数注册、graph version 更新 |
| [ads-workspace skills](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/team/01.ads-engineering) | Recall 自助接入与调试：模型、队列、OhMyEmb debug |
| [oh-my-embedding](https://git.garena.com/shopee/deep/oh-my-embedding) | OhMyEmb 运行时服务；`graph_version` / 发布只在模型节点合入后的手工交接阶段处理 |
| [paidads-alg](https://git.garena.com/shopee/deep/paidads-alg) | 模型训练代码（§5.2 / §6 / §7） |

### 8.4 查看 AB 实验指标

模型或队列上线后，需要在 AB 平台查看实验数据以评估效果。

#### 8.4.1 AB 平台配置查看

队列 `623012104` 的 AB Feature 为 `knnRecallCfg623012104`（Feature ID: 3586），绑定在 Scene `paidads_universal`（ID: 1361）、Layer `recall_u2i_longseq`（ID: 175210）上。

- Feature 页面：[https://abtest.shopee.io/feature/42/detail/3586](https://abtest.shopee.io/feature/42/detail/3586)
- 实验详情页：`https://abtest.shopee.io/scenes/42/experiment/detail?expId={exp_id}&projectId=42&sceneId=1361`

Feature 配置按 **Region × Entrance（DD/GAME/PP/YMAL/ALL）** 二维管理：
- 已开启 Region：BR, ID, MY, PH, SG, TH, TW, VN
- 各 Entrance 关键参数：`enable`、`recall_limit`（1000）、`cache_key`（`raw:rcmd_model_longseq_qqcr_0130`）、`cache_ttl_sec`（300）、`cache_read_mode`（DD/YMAL=3, GAME/PP=2）
- YMAL 使用独立 cache_key：`rcmd_model_longseq_qqcr1_0130`

#### 8.4.2 使用 SRA Toolkit 查看实验数据

SRA toolkit 的 `sp-ab` skill 支持通过命令行查询实验配置和报表数据。

**查看实验配置：**

```bash
# 查看 Feature 基本信息
uv run scripts/get-experiment.py feature 3586

# 查看 Feature 值配置（Region × Entrance 明细）
uv run scripts/get-experiment.py feature-values 3586

# 查看实验详情（含 group 流量分配）
uv run scripts/get-experiment.py detail {exp_id} --summary --pair-groups

# 查看 Layer 上所有实验（含历史已完成实验）
uv run scripts/get-experiment.py layer-exps --layer 175210 --status pending,ongoing,complete

# 查看实验操作日志
uv run scripts/get-experiment.py op-log {exp_id} --lookback 180
```

**查看实验报表：**

```bash
# 自动获取日期范围和所有指标（推荐）
uv run scripts/get-report.py {exp_id} --auto-range --all-metrics

# 指定日期范围和 region（适用于已完成实验，无法自动推断 region 的情况）
uv run scripts/get-report.py {exp_id} --start 2026-03-06 --end 2026-03-23 --all-metrics \
    --regions ID MY TH --control {control_group_id} --treatments {exp_group_id}

# 重放 AB 平台分享链接
uv run scripts/get-report.py --from-url "https://abtest.shopee.io/scenes/42/experiment/viewReport?shareId=271233&tab=1"
```

默认使用模板 **"One Page - Paid Ads A/B Test" > "Rollout Checklist"**，关注指标：
- Platform / RCMD / DD / YMAL 维度的 `order_cnt`、`gmv`、`gmv_995`、`revenue_usd`、`advv_cost_1d`、`roi2_advv_cost_1d`、`达标rev%`、`Narrow ROI`、`CPA`、`CPM`

#### 8.4.3 历史实验记录（队列 623012104）

| Exp ID | 实验名称 | 状态 | 时间 | 流量 | 要点 |
|---|---|---|---|---|---|
| 207865 | `recall_longseq_exp` | Complete | 2025-12 ~ 2026-01 | BR 70% | 首次上线验证 |
| 210266 | `drop_offline_u2i_exp` | Complete | 2026-01 | — | 下线旧离线队列 |
| 214819 | `recall_longseq_model` | Complete | 2026-02 | — | 模型迭代 |
| 214832 | `recall_longseq_model` | Complete | 2026-02 ~ 2026-03 | 8 region 10~20% | 模型迭代→推全 |
| 216586 | `recall_longseq_rope_model` | Complete | 2026-03 ~ 2026-04 | 8 region 10% | RoPE 模型验证 |

### 8.5 Rollout 推全文档

实验验收通过后，需编写 Rollout 推全文档供 review 审批，然后通过 Feature Launch 全量上线。

<!--
Agent 提示：如果任务是"生成 Rollout 文档"，优先调用 sra-toolkit 的 ads-rollout-generate skill，而不是手动拼 doc；它会自动对齐 Guardrail / Monthly Uplift 公式（见 §8.5.2）。
-->


#### 8.5.1 Rollout 文档结构

以队列 `623012104` 长序列模型为例，其 Rollout 文档为：[Rollout Doc - 召回长序列 u2i 模型](https://docs.google.com/document/d/1GZr8tQSqJa88xU_8ZXzXTNJe3TjFazllP2cnVv0AoG4/edit)

标准 Rollout 文档包含以下 Tab 结构：

| Tab | 内容 |
|---|---|
| **Project Info(CH/EN)** | 背景、方法/策略优化点、Epic TRD 链接、参与者 |
| **{YYYYMMDD}-{Regions}** | 每轮 rollout 的实验数据（可有多个 Tab，按日期和 region 分组） |

每轮实验数据 Tab 包含：
1. **Experiment Info**：实验周期、流量桶类型、流量比例、rollout region、entrance、bidding type、AB test 链接
2. **Core Metric Conclusion**：
   - Guardrail 指标：是否 all pass，对 FAIL 指标需给出解释
   - Overall core Metric Uplift：聚焦 `rev_usd`、`deep_advv_999`、`broad_gmv`，按 country 拆分，计算 Monthly Uplift（100% 流量外推）
3. **Recall Metric**：队列级分析（如 adopt/exclusive ratio）

#### 8.5.2 使用 SRA Toolkit 生成 Rollout 文档

SRA toolkit 的 `ads-rollout-generate` skill 可以自动或半自动生成 Rollout 文档：

**新建 Rollout 文档流程：**
1. 提供 TRD 文档链接 → 提取背景和方法
2. 提供 AB 报表分享链接 → 自动拉取 `rev_usd`、`deep_advv_999`、`broad_gmv` 按 country 拆分
3. 提供 Guardrail snapshot 截图 → 分析 PASS/FAIL
4. 自动生成 Google Doc，包含 Project Info (EN/CH) + 实验数据 Tab

**追加 Country 数据流程：**
1. 提供已有 Rollout 文档链接
2. 提供新 country 的 AB 报表分享链接 + Guardrail snapshot
3. 自动追加新 Tab 到已有文档

**Monthly Uplift 计算公式：**
```
Monthly Uplift (100%) = base_value × uplift% × (1 / experiment_traffic_ratio) × 30
```

#### 8.5.3 Feature Launch 全量上线

Rollout review 通过后，在 AB 平台执行 Feature Launch：
1. 在 Feature 页面选择 Launch value（如 `default`）
2. 选择 Launch scope（Scene: `paidads_universal`）
3. 按 Region 逐步放量或一次性全量
4. 确认所有关联实验状态为 Complete

## 9. 关键指标

<!--
Agent 阅读提示：
- §9.1 离线 = 模型侧指标（recall_rate / precision@100），不看线上流量；
  §9.2.1 在线整桶 = AB 实验级（rev / advv / gmv），对齐 rollout 指标；
  §9.2.2 队列效果 = 以 (region, scene, queue_id) 为粒度的"采纳 vs 独占"全套指标。
- "采纳口径 (adopt_*)" = 队列至少召回一次该候选；"独占口径 (excl_*)" = 只有该队列召回，用于衡量单独贡献。
- "独占率 excl_ratio = excl_imp / adopt_imp" 是队列取舍的关键指标。
- `advv` 在 Search 与 Discovery/Shop 口径不同；`gmv` 有 direct / broad 两种归因，跨产品对比前一定要先统一（见 §9.2.1 口径说明列）。
-->

### 9.1 离线指标

用于评估召回模型的候选覆盖能力，不依赖线上实验。

| 指标 | 含义 | 公式 | 评估粒度 | 参考 SQL |
|---|---|---|---|---|
| offline_recall_rate | 离线召回率：模型 Top100 候选命中 ground truth 的覆盖程度 | `avg(recall_cnt / click_cnt)`，其中 `recall_cnt` = Top100 候选与 ground truth 的交集数，`click_cnt` = ground truth 有效点击数 | DD 按 `user_id`；Search/YMAL 按 `request_id` | [`dd_recall.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/dd_recall.sql) / [`ymal_recall.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/ymal_recall.sql) / [`search_recall.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/search_recall.sql) |
| precision_at_100 | Precision@100：Top100 候选纯度 | `avg(recall_cnt / 100)` | 同上 | 同上 |

**Ground truth 差异说明：**

| 场景 | Ground truth 时间窗 | 有效 Ads 条件 | DataSuite 任务 |
|---|---|---|---|
| DD | T+1 日首页点击 (`home click`) | `placement in (2,40,50)` | [9772741](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=9772741) |
| YMAL | T+0 日点击 | `contextitems is not null` + `placement in (5,40,50)` | [9774185](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=9774185) |
| Search | T+0 日搜索点击 | Search placements | [9481741](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=9481741) |

### 9.2 在线指标

#### 9.2.1 整桶效果分析

AB 实验维度，衡量 Recall 改动对业务大盘的影响。数据来源：AB Platform Project 42（`Paidads Realtime Performance` / `Search Ads Realtime (Druid)` / `Discovery Ads (Realtime)`）。

| 指标 | 含义 | 公式 | 粒度 | 口径说明 |
|---|---|---|---|---|
| rev | 广告收入 | `SUM(revenue_amt_usd)` 或 AB 面板 `Revenue Usd`；数仓字段 `ads_revenue_usd` | `exp × region × entrance` | — |
| advv | 广告价值量 | Search 主口径 `SUM(advv)`（CPC: `bid_price × click / 1e5`，非 CPC: `raw_expense / 1e5`）；Discovery/Shop 用 `SUM(broad_advv_usd)` | `exp × region × entrance` | Search 与 Discovery/Shop 口径不同（`search advv` vs `broad advv`），跨产品对比前需统一 |
| gmv | 成交额 | 直接归因 `SUM(ads_gmv_usd)`；广泛归因 `SUM(ads_broad_gmv_usd)` | `exp × region × entrance` | Discovery/Shop 场景主看 `Broad Gmv`；实验结论前需统一 `direct` / `broad` 归因口径 |

#### 9.2.2 队列效果分析

以 `(grass_region, scene, queue_id)` 为维度，区分**采纳口径**（被该队列召回即计入）和**独占口径**（仅被该队列召回）进行全链路效果分析，用于指导队列 quota 调优。

数据来源：[`queue_effect_analysis.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/queue_effect_analysis.sql)（关联 `dwd_advertise_performance_di` + `dwd_advertise_tracking_item_hi`）。

**输入参数：** `@dt`（查询日期）、`@exp_id`（实验 ID，用于 tracking 的 `ab_sign` 过滤）。

**核心流程：**
1. 从 `dwd_advertise_performance_di` 取全链路指标 per `(region, request_id, item_id)`，按 `entrance` 映射 `scene`（search/ymal/dd/cart_unify）
2. 从 `dwd_advertise_tracking_item_hi` 解析 `algo_json_data.recall_queue_ids` 得到每个 item 命中的队列列表，按 `ab_sign` 中的 `exp_id` 过滤实验组
3. JOIN 后 LATERAL VIEW EXPLODE 队列数组，标记 `is_exclusive`（`queue_cnt = 1`，即仅被一个队列召回）
4. 按 `(grass_region, scene, queue_id)` 分别聚合采纳/独占两套指标，并 UNION ALL 补充 `all` 维度汇总

**输出指标清单：**

| 类别 | 指标 | 采纳口径字段 | 独占口径字段 | 含义 |
|---|---|---|---|---|
| 基础量 | 曝光 / 点击 / 加购 / 下单 | `adopt_imp` / `adopt_click` / `adopt_checkout` / `adopt_order` | `excl_imp` / `excl_click` / `excl_checkout` / `excl_order` | 各环节绝对量 |
| 金额 | 收入 / 扣费 / GMV / 直接GMV / 间接GMV | `adopt_rev` / `adopt_charge` / `adopt_gmv` / `adopt_direct_gmv` / `adopt_indirect_gmv` | `excl_rev` / `excl_charge` / `excl_gmv` / `excl_direct_gmv` / `excl_indirect_gmv` | 各环节金额（`rev` = `expected_revenue`，`charge` = `expenditure_amt_local`，`gmv` = `broad_gmv_amt_local`） |
| 份额 | 曝光占比 / 收入占比 / 扣费占比 / GMV 占比 | `adopt_imp_share` / `adopt_rev_share` / `adopt_charge_share` / `adopt_gmv_share` | `excl_imp_share` / `excl_rev_share` / `excl_charge_share` / `excl_gmv_share` | 该队列占全场景 baseline 的比例 |
| 漏斗效率 | CTR / Click→Checkout / CVR / Imp→Order | `adopt_ctr` / `adopt_click2checkout` / `adopt_cvr` / `adopt_imp2order` | `excl_ctr` / `excl_click2checkout` / `excl_cvr` / `excl_imp2order` | 转化效率 |
| 单次曝光效率 | ARPI / Charge Per Imp / GMV Per Imp | `adopt_arpi` / `adopt_charge_per_imp` / `adopt_gmv_per_imp` | `excl_arpi` / `excl_charge_per_imp` / `excl_gmv_per_imp` | 每次曝光产出 |
| 广告主 ROI | ROAS | `adopt_roas` | `excl_roas` | `gmv / charge` |
| GMV 结构 | 直接 GMV 占比 | `adopt_direct_gmv_ratio` | `excl_direct_gmv_ratio` | `direct_gmv / gmv` |
| 计费效率 | Charge/Rev 比 | `adopt_charge_rev_ratio` | — | `charge / rev` |
| 采纳 vs 独占 | 独占率 | — | `excl_ratio` | `excl_imp / adopt_imp`，衡量该队列独特供给价值 |

**辅助指标 — 采纳率（ads_adopt_ratio）：**

来源：[`ads_adopt_rate.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/ads_adopt_rate.sql)。在有 `dwd_trace_recall_log_di` 记录的请求范围内，统计 performance 中满足指定口径的 `(request_id, item_id)` 能在 recall_log 中找到对应记录的比例。

公式：`ads_adopt_ratio = 1 - not_in_recall_req_item_cnt / perf_total_req_item_cnt`，粒度 `scene × country × day`。

| 口径 | 过滤条件 | 建议采样率 |
|---|---|---|
| 曝光口径（默认） | `impression_cnt > 0` | 1% |
| 点击口径 | `click_cnt > 0` | 1% |
| 下单口径 | `broad_order_cnt + order_cnt + daily_order_cnt > 0` | 10%（订单量少） |

**当前独占率 / 采纳率分析 SQL：**

当前以 DataSuite SQL [11058141](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141) 为准。它取代了此前只统计 **impression 主口径** 的版本，在保留 `adopt_rate / exclusive_rate` 作为曝光口径主指标的同时，新增 click / order item 口径，适合回答“某队列除了拿到曝光份额之外，是否真正贡献了点击/下单”：

- `click_item_flag = click_cnt > 0`
- `order_item_flag = broad_order_cnt + order_cnt + daily_order_cnt > 0`
- `click_adopt_rate = click_cnt / total_click_n`
- `click_exclusive_rate = exclusive_click_cnt / total_click_n`
- `order_adopt_rate = order_cnt / total_order_n`
- `order_exclusive_rate = exclusive_order_cnt / total_order_n`

同一份 SQL 也可用于回答“API0 / API1 分别透出的 ads 数量和质量”这类问题：Tracking 解析 `algo_json_data.recall_queue_ids` 时会把数字队列号统一归一为 `ads`，代表 Ads Recall / API0 侧供给；非 `ads` 的来源前缀保留为原始队列来源，通常用于观察 Org Recall / API1 反查侧透出的 ads。结合 `reason(stage)` / `funnel_stage`，可以按 `ads` vs 非 `ads` 来源分别查看曝光、点击、下单三套 item 口径下的 adopt / exclusive numerator、denominator 和 rate。

与 `queue_effect_analysis.sql` 的区别在于：`queue_effect_analysis.sql` 更偏队列级经营效果分析（rev / charge / gmv / roas / funnel efficiency），而 [11058141](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141) 是当前权威的“**队列 × 漏斗阶段 × item 口径**” adopt / exclusive 归因 SQL。

### 9.3 指标使用指引

- **模型迭代**：先看离线 `recall_rate` / `precision_at_100` 验证模型覆盖能力提升，再上 AB 看整桶 `rev` / `advv` / `gmv` 验证业务结果。
- **队列调优**：用 `queue_effect_analysis.sql` 分析各队列的份额、漏斗效率、ROAS 和独占率，指导 quota 调整和队列上下线决策。
- **链路健康**：关注 `ads_adopt_ratio`，若采纳率异常下降说明 recall_log 丢失或链路断裂，需排查 tracking 数据完整性。
- **口径统一**：`advv` 在 Search 和 Discovery/Shop 口径不同，`gmv` 有 direct/broad 两种归因，跨场景对比前必须先统一。

## 10. 数据契约

<!--
Agent 阅读提示：
- §10.1 按"人工维护 / 准实时 / 离线"三栏列出所有数据源；跑 SQL 走 sra-ds-sql-query skill，查监控走 sp-grafana skill。
- §10.2 是"标准查询口径"：独占率/采纳率/离线 recall rate 三套 SQL，直接可复用；不要重写口径，如果需要新指标，先来这里找相近口径再 fork。
- §10.3 必带过滤条件（`tz_type='local_tz'` / `grass_date`）是 mp_paidads 表的通用约束，忘记加会导致数据翻倍或空值。
- 若本节没有静态数值，但给出了 skill / 平台查询路径，agent 应先执行查询；只有 skill 失败时，才返回手动流程，不要直接说“不能回答”。
-->

### 10.1 数据源

以下列出 Recall 分析与监控常用的数据源，按存储类型分组。

**Agent 查询总原则**：
- 先看本节能不能直接把“问题类型 -> 平台 -> skill”对上。
- 对 agent 而言，本节的优先级高于“主观判断不能回答”。
- 如果已经存在 skill 或平台入口，默认先查；只有确认查不到、没权限、或接口边界不支持时，再回退到手动流程。

**常见问题 -> 首选 skill -> 兜底路径**

| 问题类型                                                         | 首选 skill                                      | 首选平台/入口                 | skill 查不到时的兜底                                    |
| ------------------------------------------------------------ | --------------------------------------------- | ----------------------- | ------------------------------------------------ |
| 采纳率 / 独占率 / impression / click / order / index_log 等 Hive 数据 | `sra-ds-sql-query`                            | Hive / DataSuite ad-hoc | 返回对应 SQL / 表名 / 过滤维度                             |
| DataSuite workflow / asset / SQL 脚本内容                        | `sra-datasuite-crawler`                       | DataSuite Studio        | 返回 asset 链接和 workflow/detail / file/detail 下钻顺序  |
| 服务健康 / 队列耗时 / 集群利用率 / 漏斗                                     | `sp-grafana`                                  | Grafana                 | 返回 dashboard 链接、变量和推荐 panel                      |
| AB feature / layer / experiment / quota                      | `sp-ab`                                       | AB Test Platform        | 返回 feature/layer 反查顺序和 AB 页面链接                   |
| AFP DAG / slot / feature lineage                             | `sra-afp`                                     | AFP                     | 返回 scenario / dag_group / slot 反查顺序              |
| EGO serving / checkpoint / ready_at_time 相关                  | `sra-ego-serving-list` / `sra-ego-checkpoint` | EGO / OhMyEmb           | 返回 model_name / checkpoint / ready_at_time 的手动路径 |
| 请求级“为什么没召回 item”                                             | `auto-case-attribution`                       | in-repo skill           | 返回 §10.4 的最少输入和 case SOP 入口                      |
| OneBI 单队列效果看板                                                | 当前无专门 skill                                   | OneBI / Dashboard       | 返回 dashboard 链接、filter 字段、页面说明                   |
| Data Delivery sinker / version / monitor                     | 当前无专门 skill                                   | AlgoLab Data Delivery   | 返回 project 11 页面、权限边界和手动下钻方法                     |

#### Spreadsheet（人工维护，周级更新）

| 名称 | 说明 | 链接 | 关键维度 |
|---|---|---|---|
| One Stop Tracker | Ads 全团队实验与项目进展跟踪表，包含各实验阶段的 region、scene、ads type 拆分数据，是 rollout review 的基础输入 | [【Ads Team】One Stop Tracker](https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=451255125#gid=451255125) | region、scene、ads type、experiment stage |
| Queue Registry | 召回队列的统一编号登记表，记录每个 queue_id 的命名规则、用途、PIC、生产代码路径和调度任务入口，是队列资产查询的唯一入口 | [召回队列命名约定](https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk/edit?gid=65057492#gid=65057492) | queue_id、scene、queue_type、owner |

#### Grafana（准实时监控）

| 面板 | 说明 | 链接 | 关键维度 |
|---|---|---|---|
| Search Recall Funnel | Search 场景各队列的召回量→过滤后→粗排候选量漏斗，用于判断 Search 召回供给是否正常 | [Search Ads Recall Funnel](https://monitoring.infra.sz.shopee.io/grafana/d/3sprlRpNk?orgId=39) | service、region、queue |
| Discovery Recall Funnel | Discovery 场景各队列召回量漏斗，含 Snake Merge 前后的候选量对比，用于判断 DD/YMAL/PP 场景供给和 merge 截断比例 | [Discovery Ads Recall Funnel](https://monitoring.infra.sz.shopee.io/grafana/d/KGPn-2cNz?orgId=39) | service、region、queue |
| Retrieval Service | Retrieval 服务整体 QPS、P99 延时和队列级别耗时，用于判断服务是否过载或某队列延时异常 | [Retrieval service](https://monitoring.infra.sz.shopee.io/grafana/d/9j91dj8Mz?orgId=39) / [Retrieval v3](https://monitoring.infra.sz.shopee.io/grafana/d/G66aGJ4Vk?orgId=39) | service、region、queue |
| Queue Metrics | 各队列的 picked / final 候选数和采纳率趋势，用于监控单队列供给波动和实验前后对比 | [Recall Queue Metrics](https://monitoring.infra.sz.shopee.io/grafana/d/sX-4O4B4z?orgId=39) | queue、region |
| Dependency Monitor | 召回依赖服务（Vespa / FSE / Redis / EGO / OhMyEmb）的健康状态和错误率 | [Recall Dependency Monitor](https://monitoring.infra.sz.shopee.io/grafana/d/zvx0F0yVk?orgId=39) | service |
| KNN Deploy | KNN 队列的 Vespa 缓存命中率，判断 cache 策略是否生效 | [KNN Deploy](https://monitoring.infra.sz.shopee.io/grafana/d/v6Qm6gi4z?orgId=39) | region |
| OhMyEmb Offline Pipeline | 离线 pipeline 各阶段延时与错误，用于排查 Item Tower embedding 产出延迟或失败 | [OhMyEmb Offline Pipeline](https://monitoring.infra.sz.shopee.io/grafana/d/pCo2VkPNz?orgId=39) | node、region |
| Ads Engine Critical Metrics | Engine 侧看到的召回响应量，用于从下游视角验证召回供给 | [Ads Engine Critical Metrics](https://monitoring.infra.sz.shopee.io/grafana/d/916wkZsVz?orgId=39) | region |

#### OneBI / Dashboard（按队列切分）

| 面板 | 说明 | 链接 | 关键维度 |
|---|---|---|---|
| Recall Rele Log Monitor | Product Ads Recall queue 的队列级时序效果看板，支持按 `Queue id / Exp id / Region / Entrance / Date` 过滤，查看单队列的曝光、点击、下单、GMV、Rev、Adopt、Exclusive、CTR、CVR、CPC、CPA、CPM 等趋势 | [recall_rele_log_monitor](https://datasuite.shopee.io/dashboard/dashboard/ea3b1440-00f2-47d0-b24c-0b2851c25974/normal?page=1767668504039_184xp) | queue_id、exp_id、region、entrance、date |

使用建议：
- 默认从 `Experiment Recall Metric` page 开始；当前默认筛选通常是 `Region=BR/ID/MY/PH/SG/TH/TW/VN`、`Entrance=search/cart_unify/dd/game/ymal`、`Exp id=638931`，`Queue id` 为空时表示同时看多队列。
- 做单队列健康度评估时，优先补齐 `Queue id + Exp id + Region + Entrance + Date`；若只改 `Queue id`，其余筛选会沿用 page 默认值。
- 该 dashboard 当前实测通过 `POST /dashboard/api/v1/report/execute` 执行，首屏指标包括 `Adopt Rate / Exclusive Rate / Impression count / Click count / Order count / GMV / Advv / Rev / CTR / CVR / GPM / CTCVR / CPC / CPA / CPM / Advv/Imp / Advv/clk / All Imp Count`。
- 底层查询来自 `mkplpaidads_search_ads_ads_debug.ads_recall_abtest_monitor`；页面说明标注为 `10% sample`，因此比例指标通常比绝对量更稳定。
- 这块看板优先解决“按队列切分”的效果观察；Grafana 仍主要承担服务健康、依赖状态和召回漏斗监控。

#### Agent 优先：skill 查询；手动兜底：最近更新时间 / 算法耗

> KB 当前**不沉淀固定时点的快照数值**，但已经给出足够稳定的查询路径。
> 对 agent：先用 skill / 平台查询；只有 skill 查不到、没权限或接口边界不支持时，再把下面的手动流程作为回答返回给用户。

**A. 如何手动查某一路算法的最近更新时间**

Agent 首选：
- `sra-ego-serving-list`：先确认 `online_model / version / status`
- `sra-ego-checkpoint`：再确认 checkpoint 时间、样本日期
- `sra-datasuite-crawler`：若还要继续追 DataSuite 调度 / workflow 最近运行
- 若是非 KNN 队列且有 workflow / delivery 链：先 `sra-datasuite-crawler`，再手动去 Data Delivery

1. 先按 `queue_id` 用 §11.3.5 反查队列类型和主链路。
2. 若是 `KnnQ2IOp / KnnU2IOp / KnnU2UOp` 这类在线模型队列：
   - 走 `queue -> retrieval YAML -> OhMyEmb 节点 -> EGO serving / checkpoint`
   - 再用 [OhMyEmb Offline Pipeline](https://monitoring.infra.sz.shopee.io/grafana/d/pCo2VkPNz?orgId=39) 或 [Self Model Service Grafana](https://graphmanager.shopee.io/selfmodel/front/grafana-panel) 看 `ready_at_time`
   - 若该模型有明确训练调度，再回 DataSuite 训练任务看最近一次成功运行时间（如长序列的 [10917479](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10917479)）
3. 若是 `Redis / FSE / QT2I / LLM / blacklist / fallback` 这类非 KNN 队列：
   - 走 `queue -> 任务等级表 / DataSuite workflow`
   - 先看 workflow 最近运行情况、marker、脚本参数和下游产出
   - 若明确存在下发链路，再继续到 §12.5 的 AlgoLab Data Delivery 看 sinker / version / monitor（若权限允许）
   - 推荐最短检查顺序：
     1. `workflow 最近成功时间`
     2. `outputMarker / inputMarker` 是否按预期产出
     3. 输入数据形态是否匹配（例如 parquet 是否已展开到可下发结构）
     4. Data Delivery 的 `Task Type / Data Type`
     5. `Source Info` 是否对齐当前 HDFS path / marker
     6. `Target Info` 是否对齐当前 Redis / Vespa 目标、key prefix 或 index 语义
     7. `History / version / monitor` 是否显示最近一次成功下发
     8. 必要时再做反序列化或读 Redis/Vespa 样本验证
4. 因此，“最近更新时间”在 KB 中的推荐口径应写成：
   - **在线模型队列**：`EGO serving version / checkpoint 时间 + ready_at_time + DataSuite 调度时间`
   - **非 KNN 队列**：`离线 workflow 最近成功时间 + 下发链路更新时间`

**B. 如何手动查某一路召回的算法耗**

Agent 首选：
- `sp-grafana`
- 若要做请求级 case，先用 `auto-case-attribution` 定位 queue / stage，再回 Grafana 看耗时

1. 队列级总耗时：
   - 看 [Retrieval service](https://monitoring.infra.sz.shopee.io/grafana/d/9j91dj8Mz?orgId=39) / [Retrieval v3](https://monitoring.infra.sz.shopee.io/grafana/d/G66aGJ4Vk?orgId=39)
   - 关键过滤维度：`service / region / queue`
2. 若是 KNN / 在线模型队列，还可以继续拆：
   - [Predictor - User Tower](https://monitoring.infra.sz.shopee.io/grafana/d/HTScQnYVz/egopredictor-basis?orgId=38&var-model=recall_rcmd_longseq_v2_user_tower)
   - [Predictor - Item Tower](https://monitoring.infra.sz.shopee.io/grafana/d/HTScQnYVz/egopredictor-basis?orgId=38&var-model=recall_rcmd_longseq_v2_item_tower)
   - [OnlinePS - User Tower](https://monitoring.infra.sz.shopee.io/grafana/d/sZMn18sVk/ego-onlineps-jian-kong-lyra?orgId=38&var-model_name=recall_rcmd_longseq_v2_user_tower_1966856)
   - [OnlinePS - Item Tower](https://monitoring.infra.sz.shopee.io/grafana/d/sZMn18sVk/ego-onlineps-jian-kong-lyra?orgId=38&var-model_name=recall_rcmd_longseq_v2_item_tower_1966857)
3. 若是 Redis / FSE / Vespa / OhMyEmb 依赖问题：
   - 看 [Recall Dependency Monitor](https://monitoring.infra.sz.shopee.io/grafana/d/zvx0F0yVk?orgId=39)
   - 必要时再配合 `Retrieval v3` 拆 Vespa / Embedding / FSE 侧延时
4. 因此，“算法耗”在 KB 中的推荐口径应写成：
   - **队列级总耗时**：`Retrieval Service / Retrieval v3`
   - **KNN 模型推理耗时**：`Predictor / OnlinePS`
   - **依赖侧耗时 / 异常**：`Dependency Monitor / OhMyEmb Offline Pipeline`

**C. 如何手动查 EGO / URanker 集群利用率**

Agent 首选：
- `sp-grafana`
- 若只知道 `queue_id`，先按 §11.3.5 / §11.3.3 反查到 `model_name / service_name`，再带着这些维度去查

1. 若只知道 `queue_id`，先按 §11.3.5 / §11.3.3 反查 `required_output / model_name / service_name`。
2. 对在线模型队列，优先看：
   - [Predictor - User Tower](https://monitoring.infra.sz.shopee.io/grafana/d/HTScQnYVz/egopredictor-basis?orgId=38&var-model=recall_rcmd_longseq_v2_user_tower)
   - [Predictor - Item Tower](https://monitoring.infra.sz.shopee.io/grafana/d/HTScQnYVz/egopredictor-basis?orgId=38&var-model=recall_rcmd_longseq_v2_item_tower)
   - [OnlinePS - User Tower](https://monitoring.infra.sz.shopee.io/grafana/d/sZMn18sVk/ego-onlineps-jian-kong-lyra?orgId=38&var-model_name=recall_rcmd_longseq_v2_user_tower_1966856)
   - [OnlinePS - Item Tower](https://monitoring.infra.sz.shopee.io/grafana/d/sZMn18sVk/ego-onlineps-jian-kong-lyra?orgId=38&var-model_name=recall_rcmd_longseq_v2_item_tower_1966857)
3. 这些面板适合人工查看在线推理集群的 `QPS / 延时 / 错误率`，以及面板当前暴露出的实例或资源使用指标；若需要更细的服务视角，再按 `service_name / model_name` 回到对应发布平台或部署入口继续查。
4. 因此，“集群利用率”在 KB 中的推荐口径应写成：
   - **EGO / StandardURanker 在线推理侧**：`Predictor / OnlinePS`
   - **Retrieval 服务整体负载**：`Retrieval Service / Retrieval v3`

**D. 如何手动查 ads item 是否进出索引、何时可被召回**

Agent 首选：
- `sra-ds-sql-query`：先查 `mp_paidads.ods_shopee_paidads_index_log`
- 若问题已经变成“为什么这条 ads 没被索引 / 没被更新”，再补 `ads-idx-analyser`

1. 先查 `mp_paidads.ods_shopee_paidads_index_log`，按 `item_id / grass_date / placement / operation` 看该广告在指定日期是否存在 `INDEX / UPDATE / DELETE` 等索引事件。
2. 若只需要判断“这条广告在某天、某 placement 下理论上是否可被 Recall 命中”，通常以 `operation IN ('INDEX', 'UPDATE')` 的快照为准。
3. 若要继续追“为什么进索引 / 为什么出索引 / 延迟大概是多少”，需要把上游变更时间（Ads Info / Indexer 触发）和 `index_log` 时间对齐，再到 Ads Info / Indexer 的日志或对应平台继续看；这部分已超出 Recall 自身代码范围。
4. 因此，这类问题在 KB 中的推荐口径应写成：
   - **是否在索引里、何时有索引快照**：`ods_shopee_paidads_index_log`
   - **具体触发条件 / 根因 / 精确延迟**：继续到 Ads Info / Indexer 侧排查，Recall KB 仅提供入口和过滤口径

#### Hive / DataSuite（T+1 离线表）

| 表/任务名 | 说明 | 链接 | 关键维度 | 分区字段 |
|---|---|---|---|---|
| `ads_recall_abtest_monitor` | 历史实验级 recall queue 监控表，主要产出 impression 主口径的 adopt / exclusive / rev / gmv / advv | [DataSuite 10570848](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10570848) | grass_date、region、entrance、queue、experiment | grass_date |
| `ads_recall_abtest_biz_monitor` | 历史实验级 biz queue 监控表，同上但按 biz_queue 维度拆分 | [DataSuite 10834998](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10834998) | grass_date、region、entrance、biz_queue、experiment | grass_date |
| `独占率/采纳率分析 SQL（当前口径）` | 当前权威 SQL：统一产出 impression / click / order 三套 item 口径的 adopt / exclusive numerator、denominator 和 rate，并按 `reason(stage)` 拆分漏斗阶段；可用 `recall_queue='ads'` vs 非 `ads` 来源观察 API0 / API1 侧透出 ads 贡献 | [DataSuite 11058141](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141) | grass_date、region、entrance、queue、reason、experiment | — |
| `dd_recall` | DD 场景离线 recall/precision@100 评估，输入为 HDFS 候选文件，ground truth 为 T+1 home click | [DataSuite 10755111](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755111) | region、scene、run_date、model | grass_date |
| `ymal_recall` | YMAL 场景离线 recall/precision@100 评估，输入为 HDFS 候选文件，ground truth 为 T+0 click（要求 contextitems 非空） | [DataSuite 10755116](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755116) | region、scene、run_date、model | grass_date |
| `recall_abtest_monitor_exp_list` | 实验白名单表，定义哪些 exp_id 纳入 adopt/exclusive 监控 | `mkplpaidads_search_ads.recall_abtest_monitor_exp_list` | experiment、scene | grass_date |
| `dwd_user_behavior` | 用户行为明细表（click/cart/order），作为离线 recall 评估的 ground truth 来源 | `rcmd_feature.dwd_user_behavior` | userid/requestid、itemid、country、action | dt |
| `ods_shopee_paidads_index_log` | 广告索引可用性快照，记录每个 item 在哪些 placement 可被索引到，用于 ground truth 过滤（只保留可被召回的 ads item） | `mp_paidads.ods_shopee_paidads_index_log` | grass_region、grass_date、item_id、placement、operation | grass_date |
| `dwd_advertise_performance_di` | 广告效果表（impression/click/order/gmv/rev/advv），实验级监控的分子数据来源 | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | grass_date、region、adid | grass_date |
| `dwd_advertise_tracking_item_hi` | 广告追踪表，包含 `recall_queue_ids`（召回队列标识）和 `ab_sign`（实验命中标识），是 adopt/exclusive 计算的基础 | `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` | grass_date、region、request_id、queue | grass_date |
| `dwd_trace_recall_log_di` | 召回日志表，记录每个 request 召回了哪些 queue 和 item，用于补齐 tracking 中的 `recall_queue_ids` 占位值 | `paidads_mart.dwd_trace_recall_log_di__reg_s0_live` | grass_date、region、request_id、queue | grass_date |
| `query_understanding_item_tag` | 商品 LLM Embedding 表（256 维），用于 Extra Embedding 挂载（§6.6）和离线分析 | `mkplpaidads_data.query_understanding_item_tag` | item_id | dt |
| `dws_all_item_seller_listing_title_embedding_tags_reg_df` | MPI 商品标题 Embedding 表（256 维），用于 Extra Embedding 挂载 | `mpi_data_mart.dws_all_item_seller_listing_title_embedding_tags_reg_df` | item_id、region | dt |
| `dws_all_item_seller_listing_image_embedding_tags_reg_df` | MPI 商品图片 Embedding 表（256 维），用于 Extra Embedding 挂载 | `mpi_data_mart.dws_all_item_seller_listing_image_embedding_tags_reg_df` | item_id、region | dt |

#### HDFS / 离线文件

| 类型 | 说明 | 路径模板 | 关键维度 |
|---|---|---|---|
| Parquet | 长序列训练样本，从 CTR parquet 过滤 DD/YMAL click 后按 country × date 分区输出（§7.1.1） | `hdfs://R2/.../recall/common/longseq_sample_v1/{country}/{date}/00` | user_id、target_item、sample_date、scene |
| TXT | 离线召回候选 dump，格式为 `key,item,score`，用于离线 recall/precision@100 评估的输入 | 路径因实验而异，如 `.../0314_dd_ID_tmp_dcr_longseq_model_base2.9.2` | key、item_id、score、scene |

### 10.2 标准查询与指标口径

本节把 Recall 团队日常使用的指标查询统一组织在一起，按「**在线指标**」和「**离线指标**」两大类展开，每个指标给出**计算过程、关键口径、数据来源和注意事项**。

队列级全链路效果分析（采纳/独占口径的 rev / CTR / ROAS / GMV 等衍生指标）已在 §9.2.2 中详细列出，此处不重复；需要时请参照 §9.2.2 的 [`queue_effect_analysis.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/queue_effect_analysis.sql) 口径。

---

#### 10.2.1 在线指标 A — 当前独占率 / 采纳率 SQL（11058141）

**用途**：统一回答“某队列在曝光、点击、下单三个 item 口径下的 adopt / exclusive 份额分别是多少，以及 item 损失主要发生在哪个漏斗阶段”。这是当前独占率 / 采纳率的权威 SQL 口径，也可用于按 `ads` / 非 `ads` 来源拆解 API0 / API1 侧透出 ads 的数量与贡献。

**当前 DataSuite SQL**：
- [独占率 / 采纳率分析 SQL (11058141)](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141)

**历史相关资产**：
- [ads_recall_abtest_monitor (10570848)](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10570848)：旧版 impression 主口径 recall queue 监控表
- [ads_recall_abtest_biz_monitor (10834998)](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10834998)：旧版 impression 主口径 biz queue 监控表

> 从 2026-04-21 起，文档中的“独占率 / 采纳率计算口径”统一以 [11058141](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141) 为准；`10570848 / 10834998` 仅保留为历史物化表 / 看板背景，不再作为主公式来源。

**计算过程（当前 SQL 主链路）**：

```
Step 0  biz_type_mapping         recall_log 的 biz_type -> entrance_name 归一化
Step 1  perf_base / filtered     Performance 表生成 impression / click / order item flag
Step 2  recall_log_normalized    recall_log 归一化 entrance，并保留 full sample request
Step 3  tracking_base / filtered Tracking 解析 queue_ids，保留 org/ads 独占判定逻辑
Step 4  tracking_perf_join_log   Performance × Tracking JOIN，得到 recall_queue_ids + is_exclusive
Step 5  total_metrics            计算 total_impression_n / total_click_n / total_order_n
Step 6  log_reason_lookup        从 recall_log 推断 item 最终达到的最高漏斗阶段
Step 7  funnel_expanded          将 item 膨胀到 1~N 个阶段，形成漏斗链
Step 8  queue_stats              按 queue × reason(stage) 聚合 numerator
Step 9  final_select             输出 impression / click / order 三套 adopt / exclusive rate
```

**各步骤关键口径**：

| 步骤 | 数据源 | 关键逻辑 |
|------|--------|---------|
| **Performance item flag** | `dwd_advertise_performance_di` | 按 `(request_id, item_id, entrance)` 归并出 `impression_item_flag / click_item_flag / order_item_flag` |
| **click 定义** | Performance 表 | `click_item_flag = (click_cnt > 0)` |
| **order 定义** | Performance 表 | `order_item_flag = (broad_order_cnt + order_cnt + daily_order_cnt > 0)` |
| **Tracking 队列解析** | `dwd_advertise_tracking_item_hi` | 解析 `algo_json_data.recall_queue_ids`，按 request-item 聚合为 `recall_queue_ids` 数组 |
| **独占判定** | Tracking JOIN Performance | `size(recall_queue_ids) = 1` |
| **Stage 推断** | `dwd_trace_recall_log_di` | 根据 unpick / picked reason 把 item 归并到最高漏斗阶段 |
| **漏斗膨胀** | recall_log + tracking/perf join | item 到达更高阶段时，会同时计入之前已通过的阶段 |
| **全量分母** | JOIN 后结果集 | 分别计算 `total_impression_n / total_click_n / total_order_n`，且补 `all region / all entrance` 汇总 |

**核心公式**：

| 指标 | 公式 | 分母定义 |
|------|------|---------|
| `adopt_rate` | `impression_cnt / total_impression_n` | impression 主口径 |
| `exclusive_rate` | `exclusive_impression_cnt / total_impression_n` | impression 主口径 |
| `click_adopt_rate` | `click_cnt / total_click_n` | click item 口径 |
| `click_exclusive_rate` | `exclusive_click_cnt / total_click_n` | click item 口径 |
| `order_adopt_rate` | `order_cnt / total_order_n` | order item 口径 |
| `order_exclusive_rate` | `exclusive_order_cnt / total_order_n` | order item 口径 |
| `exclusive` 判定 | `size(recall_queue_ids) = 1` | 仅被一个队列召回 |

**输出维度**：

- 主维度：`exp_id × entrance × recall_queue × reason(stage) × grass_region × grass_date`
- 汇总维度：补 `all region`、`all entrance`

**API0 / API1 产出分析口径**：

- `recall_queue = 'ads'`：Tracking 中数字型 recall queue id 统一归一为 `ads`，代表 Ads Recall / API0 侧供给。
- `recall_queue != 'ads'`：保留 tracking 原始来源前缀，通常用于观察 Org Recall / API1 反查侧透出的 ads；具体来源名称以 `algo_json_data.recall_queue_ids` 实际前缀为准。
- `adopt_*_numerator` / `exclusive_*_numerator` 可以作为“透出 ads 数量”的分子口径，分别覆盖曝光、点击、下单三套 item 口径。
- `adopt_*_rate` / `exclusive_*_rate` 可作为“质量/贡献”的相对口径，判断 API0 / API1 侧来源在不同漏斗阶段对曝光、点击、下单的贡献强度。

**reason(stage) 枚举**：

- `1_is_ad_inactive_filter`
- `2_is_snake_merge`
- `3_is_ad_relevance`
- `4_is_ad_info`
- `5_is_ad_prerank`
- `6_is_api0_result`

**输出字段核心集合**：

- impression：`adopt_numerator / adopt_denominator / adopt_rate / exclusive_numerator / exclusive_denominator / exclusive_rate`
- click：`click_adopt_numerator / click_adopt_denominator / click_adopt_rate / click_exclusive_numerator / click_exclusive_denominator / click_exclusive_rate`
- order：`order_adopt_numerator / order_adopt_denominator / order_adopt_rate / order_exclusive_numerator / order_exclusive_denominator / order_exclusive_rate`

**与旧版 SQL 的关系**：

- `10570848 / 10834998`：历史上主要回答 impression 主口径的 adopt / exclusive
- `11058141`：当前替换版 SQL，把 impression / click / order 三套口径统一到一个结果集中，并增加 `reason(stage)` 维度

---

#### 10.2.2 在线指标 B — 广告召回采纳率（ads_adopt_ratio）

**用途**：衡量最终产生效果（曝光/点击/下单）的广告中有多少比例能在召回日志中找到对应记录。若采纳率异常下降，说明 recall_log 丢失或召回→曝光链路断裂。

**查询模板**：[`ads_adopt_rate.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/ads_adopt_rate.sql)（Ad-hoc 查询，不写入表）。

**计算过程（4 步）**：

```
Step 1  recall_log       从 recall_log 取当天所有有记录的 (region, scene, request_id, item_id)
Step 2  recall_req       提取 recall_log 中出现过的 (region, scene, request_id) 集合
Step 3  perf_filtered    Performance 表按指定口径（曝光/点击/下单）过滤，且 request_id 必须在 recall_req 中
Step 4  LEFT JOIN        perf_filtered LEFT JOIN recall_log，统计找不到匹配的比例
```

**核心公式**：
```
ads_adopt_ratio = 1 − not_in_recall_req_item_cnt / perf_total_req_item_cnt
```
即：在有 recall_log 记录的请求范围内，Performance 中满足指定口径的 `(request_id, item_id)` 能在 recall_log 中按 `(region, scene, request_id, item_id)` 精确匹配到记录的比例。

**三种口径**：

| 口径 | Performance 过滤条件 | 建议采样率 |
|------|---------------------|-----------|
| 曝光（默认） | `impression_cnt > 0` | 1%（`abs(hash(request_id)) % 1000 < 10`） |
| 点击 | `click_cnt > 0` | 1% |
| 下单 | `broad_order_cnt + order_cnt + daily_order_cnt > 0` | 10%（订单量少，需更大采样） |

**场景映射**：通过 `entrance` 数字映射到 `search / ymal / dd / cart_unify` 四个场景。recall_log 额外使用 `biz_type` 联合 `entrance` 做更严格的场景匹配。

**输出粒度**：`scene × country × day`。

**与 §10.2.1 的区别**：
- §10.2.1（ads_recall_abtest_monitor）回答的是「每个队列贡献了多少比例的曝光」，分析维度包含 exp_id 和 queue_id。
- §10.2.2（ads_adopt_ratio）回答的是「最终产生效果的广告有多少比例能追溯到召回日志」，不区分队列和实验，用于监控链路完整性。

---

#### 10.2.3 离线指标 — 模型 Recall@100 / Precision@100

**用途**：评估召回模型的离线候选覆盖能力，验证模型改动是否提升了 Top-100 候选对 ground truth 的命中率。

**DataSuite 任务**：
- DD 场景：[dd_recall (10755111)](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755111)
- YMAL 场景：[ymal_recall (10755116)](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755116)
- Search 场景：[search_recall (9481741)](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=9481741)

**SQL 模板**：
- [`dd_recall.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/dd_recall.sql)
- [`ymal_recall.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/ymal_recall.sql)
- [`search_recall.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/search_recall.sql)

**计算过程（3 步）**：

```
Step 1  u2i（临时视图）        从 HDFS CSV 加载模型 Top-K 候选，按 score 降序截取 Top-100
Step 2  ground_truth           从用户行为表取 click + 广告索引表过滤可召回 ads item
Step 3  JOIN + 聚合             候选与 ground truth 取交集，按 user_id / request_id 粒度计算 recall 和 precision
```

**核心公式**：
```
offline_recall_rate = avg(recall_cnt / click_cnt)
precision_at_100   = avg(recall_cnt / 100)
```
其中 `recall_cnt` = Top-100 候选命中的 distinct ground truth item 数，`click_cnt` = 同一 user/request 下的 ground truth distinct click item 数。

**三个场景的口径差异**：

| 维度 | DD | YMAL | Search |
|------|-----|------|--------|
| **输入主键** | `user_id, item_id, score` | `request_id, item_id, score` | `request_id, item_id, score` |
| **评估粒度** | 按 `user_id` 聚合 | 按 `request_id` 聚合 | 按 `request_id` 聚合 |
| **ground truth 时间** | T+1 日（次日 click） | T+0 日（同日 click） | T+0 日（同日 click） |
| **ground truth 页面** | `page in ('home')`（首页） | `contextitems IS NOT NULL AND size(contextitems) > 0` | Search 页面 |
| **placement 过滤** | `(2, 40, 50)` | `(5, 40, 50)` | Search placements |
| **JOIN key** | `user_id + item_id` | `substring_index(requestid, '_', -1) + item_id` | `request_id + item_id` |

**ground truth 构造细节**：
1. 用户行为来自 `rcmd_feature.dwd_user_behavior`，取 `actiontype='others'` 且 `action='click'` 的记录。
2. 与 `mp_paidads.ods_shopee_paidads_index_log` 做 JOIN，只保留在指定日期、Region、placement 和 `operation IN ('INDEX', 'UPDATE')` 下可被索引到的 ads item——确保 ground truth 中的 item 是理论上可被召回的。
3. YMAL 场景要求 `contextitems` 非空（必须有 trigger item），且对行为表中的 `requestid` 做 `substring_index(requestid, '_', -1)` 截取后再与候选文件对齐。

**输入文件格式**：HDFS CSV，每行 `key,item,score`（无 header），路径因实验而异，需在执行时指定 `@path`、`@dt`、`@country` 三个参数。

---

#### 10.2.4 常用查询场景速查

除上述核心指标外，以下场景在日常工作中频繁使用：

| 场景 | 查询工具 | 输出粒度 | 说明 |
|------|---------|---------|------|
| 队列资产查询 | [召回队列命名约定](https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk/edit?gid=65057492#gid=65057492) | queue_id × scene | 从队列编号反查用途、PIC、代码位置和调度任务 |
| 渠道效果分析 | [One Stop Tracker](https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=451255125#gid=451255125) + AB 报告 + [Queue Metrics Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/sX-4O4B4z?orgId=39) | queue × region × scene | 结合 tracker 周级数据和 Grafana 实时趋势评估单队列贡献 |
| 队列时序效果看板 | [recall_rele_log_monitor](https://datasuite.shopee.io/dashboard/dashboard/ea3b1440-00f2-47d0-b24c-0b2851c25974/normal?page=1767668504039_184xp) | queue × date × exp_id | 默认从 `Experiment Recall Metric` page 开始，带 `Queue id + Exp id + Region + Entrance + Date`，适合看单队列 click/order/gmv/rev/adopt/exclusive/ctr/cvr 趋势 |
| 队列全链路效果 | [`queue_effect_analysis.sql`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/recall/chore/add_recall_docs/docs/team/04.product-algo/recall-algo/sql/queue_effect_analysis.sql)（§9.2.2） | region × scene × queue_id | Ad-hoc 单实验分析：采纳/独占双口径的 rev/CTR/ROAS/GMV 等全套指标 |
| 召回漏斗分析 | [Search Funnel](https://monitoring.infra.sz.shopee.io/grafana/d/3sprlRpNk?orgId=39) / [Discovery Funnel](https://monitoring.infra.sz.shopee.io/grafana/d/KGPn-2cNz?orgId=39) | region × queue × stage | 判断供给是否正常、某队列是否被过滤或 merge 截断 |
| 过滤损耗分析 | `recall_log` + `tracking` + `performance` 三表 join | queue × stage × filter item | 排查 recall 进了但 tracking 看不到、queue id 丢失、QIR 通过率异常等问题 |
| quota / limit 梳理 | [AB Feature 页面](https://abtest.shopee.io/feature/42) + DAG YAML 配置 | region × scene × queue | 比对 AB 参数实际生效值与 YAML 默认值是否一致 |
| 长序列离线评估 | [EGO Portal](https://ego-portal.mlp.shopee.io/serving/batchModelServing/) train / eval report | model × region × scene | 比较 uv/pv、500/2k、结构改造效果 |
| 长序列样本构造校验 | TRD + parquet / dump debug | user × sample_date × target item | 排查 slot hash、reshape_50、embedding 全 0 或不一致问题 |
| 服务健康检查 | [Retrieval service](https://monitoring.infra.sz.shopee.io/grafana/d/9j91dj8Mz?orgId=39) / [Dependency Monitor](https://monitoring.infra.sz.shopee.io/grafana/d/zvx0F0yVk?orgId=39) | service × region | 上线前后检查服务是否过载、依赖是否异常 |

**Recall 日常健康最小检查集**：

- 供给层：看各队列 recall 量、filter 后量、SnakeMerge 前后量、picked / final 候选数，以及 0 候选或异常掉量。
- 服务层：看 Retrieval QPS、P99、错误率、队列级耗时。
- 依赖层：看 Vespa / Redis / FSE / EGO / OhMyEmb 错误率、延时、cache hit、OhMyEmb `ready_at_time`。
- 效果层：看 `ads_adopt_ratio`、adopt / exclusive、曝光 / 点击 / 下单、CTR / CVR、GMV、Rev、Advv。
- 最小面板组合：Funnel、Queue Metrics、Retrieval Service、Dependency Monitor、Recall Rele Log Monitor。

#### 10.2.5 常见 Recall 问题回答路径

本小节把 zhangxiao@shopee.com 和 teng.lv@shopee.com 这两组问题整理成可复用回答路径。原则是：**KB 写“怎么查、按什么口径解释”，不沉淀某个实验或某天的静态数值**；涉及实际数值时，必须带 `date / region / entrance / exp_id / queue_id` 重新跑 SQL 或看监控。

| 问题 | 优先回答位置 | 回答时应包含 | 不应写死的内容 |
|---|---|---|---|
| Recall 预估目标是什么 | `§7.0.4`、`§7.2.3` | 先按队列实现范式判断是否真有训练模型；对 `623012104` 可说明点击对齐的双塔 U2I 目标、Softmax CE、AUC / PCoC；其他队列需回到模型卡或离线产出卡补证据 | 不把 LongSeq 的目标泛化成所有 Recall 队列的目标 |
| Recall 模型样本是什么 | `§7.0.4`、`§7.1`、`§6.6` | 对 `623012104` 说明 CTR parquet 来源、DD / YMAL click 过滤、输出路径、convertor、slot / Extra Embedding、正样本和 EGO NSC 负采样 | 不把单模型样本路径写成所有队列的统一样本 |
| 正负样本比例和 hard negative 怎么定义 | `§7.0.4`、`§7.1.2`、`§7.2.2` | 以 LongSeq 为例说明正样本 `label=1, weight=1`，NSC `sample_ratio=127, share_batch=False`；hard negative 需回具体方案确认 | 不把某个 TD 中的 hard negative 定义写成全 Recall 统一事实 |
| Recall 目前有哪几路，以及每一路独占率 / 采纳率 | `§5.1`、`§9.2.2`、`§10.2.1`、`§10.2.4` | 先用 `§5.1` 回答队列清单和检索方式；再用 `11058141` 或 `queue_effect_analysis.sql` 按实验输出 queue × region × entrance 的 adopt / exclusive | 不在 KB 里保存当前值，也不混用 `adopt_rate` 与 `excl_ratio` |
| 如何查看队列的具体配置 | `§11.3`、`§11.3.5` | 静态配置先查 `graph-manager-conf/retrieval/*.yaml` 或本 KB 表格；线上实际值再查 AB Feature values；只知道 key 时先搜 `knnRecallCfg{queue_name}` / `QueueParam{queue_name}` / `qt2iCfg{queue_name}` | 不把 YAML 默认值当成线上实时值 |
| 还有哪些可用高质量特征 | `§6.1-§6.6`、`§6.5.1` | 按 User / Item / Extra Embedding / Recall 独占特征四类回答，并说明当前 KB 没有 feature importance 排名 | 不断言“最重要 TopN 特征” |
| 每一路召回 quota 是多少 | `§11.3.4`、`§11.3.5`、`§10.2.4` | 先读 YAML 默认 limit，例如 `recall_limit / label2recall_limit / additional_hit / result_global_limit`；再查 AB Feature 实际覆盖值，如 `MergeQueueQuota / RecallPickedNum / knnRecallCfg{queue_name}` | 不把 YAML 默认值当作线上最终 quota |
| SnakeMerge quota 和优先级怎么分配 | `§5.3.4`、`§11.3.4`、`§11.3.5` | 说明 `MergeQueueQuota` Zigzag 交替取数、`RecallPickedNum` 最终截断；优先级由 merge 输入顺序、quota 和 TopK 截断共同决定 | 不把某队列自己的 TopK 当作直接进入粗排 |
| 每一路算法最近更新时间 | `§10.1`、`§11.3.5`、`§7.3`、`§7.4` | 在线模型走 `queue -> retrieval YAML -> OhMyEmb -> EGO serving / checkpoint -> ready_at_time -> 训练调度`；非 KNN 走 `queue -> workflow -> marker -> Data Delivery -> target history/version` | 不保存全队列最近更新时间快照 |
| 每条队列更新频率怎么样 | `§5.1`、`§7.3.2`、`§11.3.5` | 队列清单可从 §5.1 回答；频率按范式区分：LongSeq 天级、FSE realtime 准实时、Redis/LLM/QT2I 走 workflow + delivery 反查 | 不维护“所有队列频率表”静态快照 |
| Recall 集群利用率 | `§10.1`、`§11.3.5` | 先由 queue 反查 `required_output / model_name / service_name`；EGO / URanker 看 Predictor / OnlinePS，Retrieval 总负载看 Retrieval service / Retrieval v3 | 不保存 CPU / memory / GPU utilization 快照 |
| 每一路算法耗时 | `§10.1`、`§10.2.4` | 队列级总耗时看 Retrieval service / Retrieval v3；KNN 推理耗时看 Predictor / OnlinePS；依赖耗时看 Dependency Monitor / OhMyEmb | 不保存固定时点 P50 / P95 / P99 |
| Ads Recall 覆盖多少 ads click / order | `§10.2.2`、必要时 `§10.2.1` | 若问“最终产生效果的广告里有多少出现在 recall_log”，用 `ads_adopt_ratio`；若问“具体队列或 API0/API1 来源贡献”，用 `11058141` 的 click/order adopt 和 exclusive 字段 | 不把 impression、click、order 三套分母混在一起 |
| 整个 Recall 服务架构是什么样 | `§3.1`、`§5.2.1`、`§5.2.2`、`§5.3.1`、`§5.4` | 用 `Recall -> Prerank -> Rank -> MixRank` 解释大链路；再说明 Recall 内部“多队列并行召回 -> merge -> ads info filter -> dedup / snake merge -> biz tag -> pack”，并按 KNN / KV / Text / FSE / U2U2I / Fallback 说明检索方式 | 不把 Search 和 Discovery 的 DAG 差异抹平，Discovery 多 `RcmdAdsDedupOp` |
| 模型召回到进入粗排经过哪些阶段和过滤 | `§3.2`、`§5.2.2`、`§5.3` | 按 `模型/检索 -> MergeRecallResult -> AdsInfoFilter -> Dedup(Discovery) -> SnakeMerge -> BizTag -> Pack/Log -> Prerank` 说明，并列出 Search / Discovery 主要过滤项 | 不把“召回到了”直接等同于“进入粗排” |
| KNN 队列从取特征到检索的完整 DAG | `§5.2.1 A`、`§8.1`、`§11.3.5` | 在线链路按 `feature -> OhMyEmb -> embedding -> KNN op -> Vespa -> merge/filter/pack` 解释；item 侧补 `offline_item -> Vespa index`；`624012101` 说明 U2U -> FSE 两阶段 | 不把 U2U2I 简化成普通 U2I |
| Vespa 里存了哪些内容 | `§11.3.5`、`§11.3.1-§11.3.7` | 先按队列的 `vespa_name / rank_profile / required_output` 说明 corpus、embedding 或倒排字段类型；完整 schema 需要回 Vespa template/schema 或 index config 查 | 不声称 KB 已列出所有 Vespa schema 字段 |
| KNN 队列默认走哪些 AB 参数 | `§11.3.4`、`§8.1` | 队列级参数通常是 `knnRecallCfg{queue_name}`；模型级参数按队列类型选择 `knnRecall*ModelCfg`；最终 merge 还受 `MergeQueueQuota` / `RecallPickedNum` 影响 | 不只查队列级 key 而忽略模型 key 与 merge key |
| 线上关键监控和日常健康指标 | `§10.1`、`§10.2.4`、`§12.4` | 按供给层、服务层、依赖层、效果层四层检查；最小面板组合是 Funnel、Queue Metrics、Retrieval Service、Dependency Monitor、Recall Rele Log Monitor | 不把单个面板当成完整健康结论 |
| ads item 进出索引触发条件和延迟 | `§11.3.5`、`§10.3` | Recall 侧能查 `mp_paidads.ods_shopee_paidads_index_log` 中 `INDEX / UPDATE / DELETE` 事件和近似时间点；触发条件与精确 SLA 要继续追 Ads Info / Indexer | 不把索引生产逻辑写成 Recall 自身职责 |
| 离在线一致性怎么保证 / 是否有自动 diff | `§6.4`、`§7.3`、`§7.4`、`§11.3.5` | 说明特征定义一致、同 checkpoint 发布到 serving、`ready_at_time` 监控三层；当前 KB 未沉淀自动 diff 工具 | 不声称存在统一 offline-online embedding auto diff 平台 |
| user / item / query 冷启策略 | `§5.2.1 G`、`§5.2.3`、`§11.3.4` | item 看冷启扶持队列与索引可召回性；user 看 query/item 驱动和 fallback；query 看 QT2I / LLM Q2I / realtime popular 等非强个性化通路 | 不把推断写成统一硬编码策略 |
| 如何保证和后链路一致性 | `§3.2`、`§5.2.2`、`§9.2.2`、`§11.3.5` | 说明 Ads Info / Indexer 上游一致性、BizTag/Pack/SendRecallLog 下游透传、tracking 中 `recall_queue_ids` 和 `ab_sign` 贯穿链路 | 不声称 KB 已有完整字段契约表或 SLA |
| 通用降级和 cache 策略 | `§5.2.3`、`§11.3.4`、`§11.3.5` | 降级分 L2/L3/LM；cache 由 AB 队列参数和 graph YAML 的 `with_redis/with_memory/rw_mode/DefaultCacheTTL` 共同决定 | 不把 cache 写成一套全局模板 |
| API0 / API1 分别透出的 ads 数量和质量 | `§10.2.1` | 用 `11058141`：`recall_queue='ads'` 代表 Ads Recall / API0 侧供给，非 `ads` 前缀观察 Org Recall / API1 反查侧 ads；数量看 `*_numerator`，质量/贡献看 `*_rate`，阶段看 `reason(stage)` | 不保存某个 exp 的实际值；API1 来源名以 tracking 原始前缀为准 |

### 10.3 必带过滤条件
- region：必须带，至少拆到 L2 或国家级别。
- sample date：长序列样本与离线评估必须带天级样本日期。
- date / time window：必须明确自然日、实验窗口或周窗口。
- traffic / entrance：必须区分 Search / DD / YMAL / RCMD / Live / Video 等入口。
- queue_id：做代码归因、任务归因、队列迁移和 rollout 排查时必须带。
- experiment / exp_id：做实验级监控和效果归因时必须带。
- queue / queue_group：做 adopt / exclusive / filter loss 分析时必须带。
- placement：历史数据仍可能使用该口径；做迁移分析时必须和 pricingType 对照。
- ads type：必须区分 Product / Video / Live / Shop / Brand。
- target item / scene：分析长序列样本或 next token prediction 时必须区分 target item 和场景信息。
- timezone：必须与 dashboard / 报表口径保持一致，跨 region 分析时需要确认 local timezone 还是统一 UTC 口径。

### 10.4 请求级 Case 排查入口

当问题变成“**某个队列为什么在某个 request 下没有召回某个 item**”时，不建议只看队列级聚合指标；更稳妥的路径是先做 request 级 case 排查，再决定是否继续追代码、模型或平台配置。

**最少输入建议**：
- 绝对日期 / 日期范围
- region
- scene / entrance
- `queue_id` 或 `queue_tag`
- `request_id`
- `item_id`
- 口径（exposure / click / order）

若是 Search / YMAL，额外补 `query`；若是 YMAL / PDP，额外补 `pdp_item_id` 会更快。

**推荐思路（轻量版）**：
1. 先用 `recall_log` 限定 request 范围，再从 `performance` 定义 case，避免直接从全量 `performance` 猜“漏召”。
2. 先证明目标队列是否真的跑了，再判断该 item 是否进入该队列候选集；这里要先做 `queue_id -> queue_tag` 实际映射。
3. 再补 `tracking` queue source、global coverage、query / user 历史支持、商品 title / category 等证据，排除伪归因。
4. 只有在“队列已触发 + item 未进候选 + 支持证据基本齐全”后，才建议继续做 topK 候选语义对比，判断是强邻居竞争、coverage 缺失还是邻域跑偏。

**本 KB 已覆盖的直接支撑**：
- 过滤链与 `Unpick Reason`：见 §5.3.2-§5.3.4
- request / queue / item 三表口径：见 §10.1-§10.2
- 队列配置与平台映射反查：见 §11.3

**使用边界提醒**：
- `queue_id` 和 `recall_log.queue_tag` 可能不完全相同，不能直接当成同一个值。
- 如果当前只能证明“item 没进候选集”，就先停在这里，不要过早升级成“候选内排序低”或“模型坏了”。
- 对 `611010104`，若未补 AlgoLab `get_doc` 在线索引验证，不要直接把“长期不在最终输出”写成“索引缺失”。

更深入的 request 级排查，请转到下面这些文档，不建议把完整 SOP 重复写在 KB 里：
- [auto-case-attribution Skill](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/SKILL.md)
- [Workflow Gates](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/references/workflow-gates.md)
- [SQL Playbook](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/references/sql-playbook.md)
- [YMAL Representative Case Report](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/ymal-case-analysis-report.md)

Agent 执行顺序建议：
1. 先用 `auto-case-attribution`；
2. 若 skill 因权限、输入缺失或平台边界无法继续，再把本节的最少输入、轻量判定顺序和上面的 SOP 链接返回给用户；
3. 不要在有 skill 和 SOP 入口的情况下直接回答“不能排查”。

## 11. 代码与逻辑位置

<!--
Agent 阅读提示：
- §11.1 = 五个仓库的职责对照（graph-manager-conf / paidads-recall / oh-my-embedding / paidads-alg / afp-config）；需要 clone / grep 时直接来这里找入口。
- §11.2 = 关键代码逻辑（op 定义、入口 handler 等）。
- §11.3 = 所有已做代码核查的队列关键配置，完全基于 graph-manager-conf master（handoff 第二十次修改）；遇到"某队列在线行为"问题，先看这里再回 §5.2。
- §11.3 当前已覆盖 Product Ads Search / Discovery + Shop Ads + Live Ads；Video / Brand 仍未完全整理成同粒度配置卡片，其中 Brand 的部分静态配置散落在 Search / Discovery 子节。
- 若遇到“KB 没直接给值”的问题，不要止步于 §11 的静态表；应把这里的 `queue_name / ab_param_key / model_name / required_output / service_name` 当成 skill 查询的输入参数。
-->

### 11.1 仓库地图

| repo | 代码入口 | 职责 | 对应章节 |
|---|---|---|---|
| paidads-alg | [Q2Tag2I](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/Q2Tag2I/swam/q2tag2i) | Search Q2Tag2I 离线 pipeline（query_feature / item_feature / tag2tag / hot_item） | §5.2.1 C-Text / B-KV |
| paidads-alg | [online_search.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/recall/OnlineU2I/SearchMultiRegionKnn/models/online_search.py) | Search 在线 Query/Item 双塔训练与导出 | §5.2.1 A-KNN |
| paidads-alg | [online_rcmd.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/recall/OnlineU2I/RcmdMultiRegionKnn/models/online_rcmd.py) | RCMD/DD/YMAL 在线 User/Item 双塔训练与导出 | §5.2.1 A-KNN |
| paidads-alg | [u2u2i](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/u2u2i) | U2U2I 任务入口与 rollout 文档索引 | §5.2.1 E-U2U2I |
| paidads-alg | [model_i2i](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/i2i/model_i2i) | 模型 I2I（Embedding 近邻）离线产出 → Redis | §5.2.1 B-KV |
| paidads-alg | [stgy_i2i](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/i2i/stgy_i2i) | 策略 I2I（ItemCF 90 天共现统计）离线产出 → Redis | §5.2.1 B-KV |
| paidads-alg | [SearchMultiRegionKnn/models/](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/OnlineU2I/SearchMultiRegionKnn/models) | Search 样本组织（convertor.py / ego-learner.yaml） | §6.1-6.5 |
| paidads-alg | [RcmdMultiRegionKnn/models/](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/OnlineU2I/RcmdMultiRegionKnn/models) | RCMD 样本组织（convertor.py / ego-learner.yaml） | §6.1-6.5 |
| paidads-alg | [long-seq/longseq_model_base2.0.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_model_base2.0.py) | RCMD 长序列模型训练代码（双塔 + MoE + ExtraAdapter） | §7.2 |
| paidads-alg | [long-seq/convertor_dcr_longseq_base.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/convertor_dcr_longseq_base.py) | 长序列样本 Convertor（过滤 + 标签 + country 追加） | §7.1.2 |
| paidads-alg | [long-seq/longseq_sample.sql](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_sample.sql) | 长序列样本 Spark 构造（CTR parquet → DD/YMAL click 过滤） | §7.1.1 |
| paidads-alg | [ego_runner/](https://git.garena.com/shopee/deep/paidads-alg/-/tree/exp/ego_runner) + [ego_tasks/](https://git.garena.com/shopee/deep/paidads-alg/-/tree/exp/ego_tasks) | EGO 调度框架脚本 + 各模型调度配置（task.yaml / ego-learner.yaml） | §7.3 |
| DataSuite（模型训练调度） | [调度任务 10917479](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10917479) | 长序列模型线上例行训练（seed→increment→check→eval→release） | §7.3.2 |
| DataSuite（Extra Emb 产出） | [调度任务 10390147](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390147) / [产出代码 10390057](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390057) | LLM/MPI Embedding 映射表生成（哈希 + 拼接 + 写 HDFS） | §6.6 |
| graph-manager-conf | [recommend_game.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/recommend_game.yaml) | Discovery 在线 DAG：队列注册、op 编排、limit、downgrade | §5.2 / §5.2.3 / §7.5 |
| graph-manager-conf | [search_recall.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/search_recall.yaml) | Search 在线 DAG：队列注册、op 编排、limit | §5.2 |
| graph-manager-conf | [online_query_user.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/online_query_user.yaml) | OhMyEmb User Tower 节点（DAG 1331 embeddingv2） | §7.4.2 |
| graph-manager-conf | [offline_item.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/offline_item.yaml) | OhMyEmb Item Tower 节点（DAG 1332 embeddingv2） | §7.4.2 |
| paidads-recall | [search_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/search/search_ads_info_filter.go) | Search AdsInfoFilter 过滤链 | §5.3.2 |
| paidads-recall | [recommend_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/recommend_ads_info_filter.go) | Discovery AdsInfoFilter 过滤链 | §5.3.2 |
| paidads-recall | [ads_dedup_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/ads_dedup_op.go) | Discovery 实时去重（RcmdAdsDedupOp / FilterShownRecallAds） | §5.3.3 |
| paidads-recall | [snake_merge_filter_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/common_operator/snake_merge_filter_op.go) | SnakeMerge quota 截断 | §5.3.4 |
| paidads-recall | [get_fse_u2i_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/get_fse_u2i_op.go) | GetFseU2IOp：FSE 拉用户行为，聚合 U2I / U2U2I 候选 | §5.2.1 E-U2U2I |
| paidads-recall | [fallback_vespa_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/fallback_vespa_op.go) | GetVespaFallback：兜底 Vespa 召回 | §5.2.1 F-Fallback |
| paidads-recall | [ads_filter/](https://git.garena.com/shopee/deep/paidads-recall/-/tree/master/pkg/retrieval/recommend/operator/ads_filter) | Discovery 过滤子模块（censoring / placement / shop / traffic / video） | §5.3.2 |

### 11.2 关键逻辑

| 逻辑点 | 代码位置 | 做什么 | 修改风险 | 关联章节 / 指标 |
|---|---|---|---|---|
| Search filter chain | [search_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/search/search_ads_info_filter.go) | Search 场景 6 项过滤（可见性/审核/类目黑白名单/query黑名单/定价） | 高 | §5.3.2 · filter_pass_rate |
| Discovery filter chain | [recommend_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/recommend_ads_info_filter.go) + [ads_filter/](https://git.garena.com/shopee/deep/paidads-recall/-/tree/master/pkg/retrieval/recommend/operator/ads_filter) | Discovery 场景 13 项过滤（可见性/placement/视频/审核/店铺/去重/跨境/定价） | 高 | §5.3.2 · filter_pass_rate / recall_coverage |
| Q2Tag2I offline pipeline | [Q2Tag2I/script/offline_data/](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/Q2Tag2I/swam/q2tag2i/script/offline_data) | query_feature / hot_item / tag2tag 离线生成与 QEQR merge | 中 | §5.2.1 C · recall_hit_rate |
| KNN 双塔训练 | [online_search.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/recall/OnlineU2I/SearchMultiRegionKnn/models/online_search.py) / [online_rcmd.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/recall/OnlineU2I/RcmdMultiRegionKnn/models/online_rcmd.py) | Search Q2I / RCMD U2I 双塔模型的训练、slot 配置和 embedding 导出 | 高 | §5.2.1 A / §6.1-6.5 · offline_auc / xtr |
| 长序列模型训练 | [longseq_model_base2.0.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_model_base2.0.py) | RCMD 长序列双塔（MoE ReasoningBlock + ExtraAdapter + SharedItemDNN） | 高 | §7.2 · offline_auc / xtr |
| 长序列样本构造 | [longseq_sample.sql](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_sample.sql) + [convertor_dcr_longseq_base.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/convertor_dcr_longseq_base.py) | CTR parquet → DD/YMAL click 过滤 → label/weight/country 预处理 | 中 | §7.1 · offline_auc |
| Extra Embedding 挂载 | [DataSuite 调度 10390147](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390147) + [longseq_model_base2.0.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_model_base2.0.py) | LLM/MPI emb 映射表生成 + EGO import_extra_slots 动态挂载 | 中 | §6.6 · offline_auc |
| 离线训练调度 | [DataSuite 10917479](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10917479) + [ego_runner](https://git.garena.com/shopee/deep/paidads-alg/-/tree/exp/ego_runner) | DataSuite 天级触发 → ego_runner 提交 EGO 训练/发布任务 → 自动更新线上 ckpt | 高 | §7.3 · offline_auc / serving_freshness |
| EGO Serving | [EGO Portal](https://ego-portal.mlp.shopee.io/serving/batchModelServing/) | User Tower (22081) + Item Tower (22080) 在线推理服务 | 高 | §7.4 · latency_p95 / qps |
| experiment monitor | DataSuite assets [10570848](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10570848) / [10834998](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10834998) | performance + tracking (+ recall_log) 联表生成 adopt / exclusive / rev 等指标 | 中 | §10.2.1 · adopt_rate / exclusivity_ratio |

### 11.3 队列关键配置

> 以下配置**完全来自代码**：`graph-manager-conf` master 分支的 [`retrieval/search_recall.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/search_recall.yaml) / [`retrieval/recommend_game.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/recommend_game.yaml) / [`retrieval/shop_search_retrieval.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/shop_search_retrieval.yaml) / [`retrieval/live_ads_recall.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/live_ads_recall.yaml) / [`retrieval/live_ads_pdp_recall.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/live_ads_pdp_recall.yaml)、[`ohmyemb/online_query_user.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/online_query_user.yaml) / [`ohmyemb/offline_item.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/offline_item.yaml)，以及 `paidads-recall` master（`Makefile` 中 `GraphManagerVersion := recall_1.3.70`）。
>
> 本节当前已系统覆盖：
> - Product Ads Search / Discovery：见 §11.3.1-§11.3.5
> - Shop Ads / Live Ads：见 §11.3.6-§11.3.7
>
> Video / Brand 仍未完全整理成与 Search / Discovery 同粒度的配置卡片；其中 Brand 的部分静态配置已散落在 §11.3.1 / §11.3.2，后续再统一收敛。
>
> Agent 提示：需要查 `queue_limit` / `rank_profile` / `label2recall_limit` / `downgrade_level` 等字段的单队列值，直接按 `queue_name` 定位到各子节表格；OhMyEmb 节点 `service_name` / `model_name` / `emb_column_name` / BR 特殊映射在 §11.3.3；AB 参数模板命名规则在 §11.3.4。

#### 11.3.1 Search 队列（`search_recall.yaml`）

**A. KNN（`KnnQ2IOp`）**

| queue_name | node name | ab_param_key | model_param_key | vespa_name | rank_profile | required_output | label2recall_limit (raw/extend) | additional_hit | downgrade_level |
|---|---|---|---|---|---|---|---|---|---|
| `611010104` | `Q2I_KNN_611010104` | `knnRecallCfg611010104` | `knnRecallModelCfg` | `sa_q2i_knn_recall` | `v1` | `sa_knn_v8.1` | 1000 / 400 | 1000 | **L3** |
| `611010103` | `Q2C2I_KNN_611010103` | `knnRecallCfg611010103` | `knnRecallClusterModelCfg` | `sa_q2i_knn_recall` | `clusterv2` | `sa_q2i_knn_recall@embeddingclusterv2` | 1000 / 400 | 1000 | — |
| `611610101` | `Q2I_KNN_611610101` | `knnRecallCfg611610101` | `knnRecallModelCfg` | `sa_q2i_knn_recall` | `64dimv3` | `sa_q2i_knn_recall@embedding64dimv3` | 200 / 20 | 1000 | **LM** |
| `611610102` | `Q2I_KNN_611610102` | `knnRecallCfg611610102` | `knnRecallModelCfg` | `sa_q2i_knn_recall` | `64dimv3` | `sa_q2i_knn_recall@embedding64dimv3` | 200 / 20 | 1000 | **LM** |
| `611912108` | `Q2I_KNN_611912108` | `knnRecallCfg611912108` | `knnRecallPaidAdsItemModelCfg`（+ `client_ab_param_key: itemVespaClientKey`） | `paidads_item` | `v1` | `paidads_item@embeddingv1` | 1000 / 400 | 1000 | **L3** |

补充字段：`611610101` / `611610102` 带 `ad_tag_mask: [60]`（仅扶持带 tag=60 的广告）；`611912108` 带 `pricing_types: [2]`，依赖 `CheckFirstPage:IsFirstPage`。

**B. Text / Tag（`QT2IOp`）**

| queue_name | node name | 缓存 ab key（`AB "qt2iCfgXXX"`） | vespa_name | rank_profile | pricing_types | downgrade_level |
|---|---|---|---|---|---|---|
| `611020304` | `QT2I_611020304` | `qt2iCfg611020304` | `sa_text_match_recall` | `broad_tag_va` | — | **L2** |
| `611920304` | `QT2I_611920304` | `qt2iCfg611920304` | `paidads_item` | `broad_tag_vb` | `[2]` | **L2** |

所有 QT2I 节点共享的 broad 匹配字段：`broad_match_tag_field: kwrcmd_tag_bm_b`、`broad_match_phrase_field: bm_phrase_kw_b`。

**C. KV（`RedisQ2IQRCustomizedOp` / `RedisQ2IOp`）**

| queue_name | node name | op | ab_param_key | model | source | downgrade_mode |
|---|---|---|---|---|---|---|
| `611030109` | `Q2I_611030109` | `RedisQ2IQRCustomizedOp` | `QueueParam611030109` | `offline_llm_q2i` | `unify` | `limit_per_seed` |
| `611030110` | `Q2I_611030110` | `RedisQ2IQRCustomizedOp` | `QueueParam611030110` | `offline_llm_ecpm_q2i` | `unify` | `limit_per_seed` |
| `111030201` | `Q2I_111030201` | `RedisQ2IOp` | `QueueParam111030201` | `q2i_bhv_org_v1` | `roi1` | `limit_per_seed` |

所有 KV Q2I 节点共享：`compatible_old: true`、`label2limit` / `label2result_limit_per_seed` 默认全 0（由 AB / 实际参数覆盖）。

**D. FSE 实时 / FSE I2I（`RecallFetchFSE*Op`）**

| queue_name | node name | op | ab_param_key | 内部 model | seed_limit | result_global_limit |
|---|---|---|---|---|---|---|
| `611030202` | `FSE_Q2I_611030202` | `RecallFetchFSERealtimeQ2IItemOp` | `QueueParam611030202` | — | `raw: 1` | 100 |
| `612031201` | `Q2I2I_612031201` | `RecallFetchFSEQ2I2IItemOp` | `related_operators.612031201`（无独立 `ab_param_key`） | `itemcf_i2i_v1` | 100 | limit=100 |

`611030202` 的行为权重：`UserBehaviorClickRT/ATCRT/OrderRT` 各为 `1`。

**E. Keyword / Item 文本匹配（无 `queue_name` 字段）**

| node name | op | 说明 |
|---|---|---|
| `RecallKeywordMatch` | `RecallKeywordMatchV2Op` | BidKW 匹配，`args: {}` |
| `RecallKeywordItemMatch` | `RecallKeywordItemMatchV2Op` | Item 匹配，`args: {}` |

Search 文档中提到的 `111520301` / `111520302` 队列号在 YAML 中没有直接出现，属代码以外的命名约定（由 op 内部或下游归一）。

#### 11.3.2 Discovery 队列（`recommend_game.yaml`）

**A. KNN U2I（`KnnU2IOp`）**

| queue_name | node name | ab_param_key | model_param_key | vespa_name | rank_profile | required_output | recall_limit | additional_hit | placements | downgrade_level |
|---|---|---|---|---|---|---|---|---|---|---|
| `623012104` | `U2I_KNN_623012104` | `knnRecallCfg623012104` | `knnRecallRcmdLongSeqModelV2Cfg` | `dd_u2i_knn_recall` | `v1` | `rcmd_u2i_knn_recall@embeddingv1` | 500 | 2000 | `[2,5,802,805,1202,1205,50,40]` | — |
| `623012108` | `U2I_KNN_623012108` | `knnRecallCfg623012108` | `knnRecallRcmdUnionModelCfg` | `dd_u2i_knn_recall` | `v1` | `dd_knn_ego_union_v1` | 500 | 2000 | `[2,802,1202,50,40]` | **L2** |

`623012104` / `623012108` 的 cache / Vespa 行为**不是所有场景都相同**：`PP / Game` 显式 `skip_vespa: true` + `with_redis: true` + `rw_mode: read_only`；`DD` 为 `with_redis: true` + `rw_mode: write_only`；`YMAL` 中 `623012108` 未显式写 op cache，而 `623012104` 为 `with_redis: true` + `rw_mode: write_only`。排查时必须以对应 graph 文件为准。

**B. KNN U2U → FSE（`KnnU2UOp` + `GetFseU2IOp`）**

| queue_name | node name | op | ab_param_key | model_param_key | vespa_name | required_output | recall_limit | target_hits | distance_threshold | downgrade_mode | downgrade_level |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `624012101` | `U2U_KNN_624012101` | `KnnU2UOp` | `knnRecallCfg624012101` | `knnRecallRcmdU2UModelCfg` | `knn_u2u` | `u2u_knn_ego_union_v1` | 40 | 40 | 1 | `limit_skip` | **L2** |
| — | `U2U2I_624012101` | `GetFseU2IOp` | `knnRecallCfg624012101` | — | — | — | — | — | — | — | — |

注：`624012101` 由 `KnnU2UOp` 找相似用户 → `GetFseU2IOp` 从 FSE 拉行为聚合成候选，两个节点共享同一 `ab_param_key`。

**C. KV I2I（`RedisI2IOp`）**

| queue_name | node name | ab_param_key | model | source | result_global_limit | label2weight（Click/ATC/Order）|
|---|---|---|---|---|---|---|
| `622031201` | `U2I2I_622031201` | `QueueParam622031201` | `stgy_i2i` | `unify` | 2500 | 10 / 10 / 10 |
| `622031101` | `U2I2I_622031101` | `QueueParam622031101` | `model_i2i` | `unify` | 2500 | 10 / 10 / 10 |

两者均设 `sub_version: 1`、`result_with_seed_weight: true`，seed/result 无 per-seed 上限。

**D. Fallback（`GetVespaFallback`）**

| queue_name | node name | ab_param_key | vespa_name | rank_profile | result_global_limit | downgrade_level |
|---|---|---|---|---|---|---|
| `623922201` | `D2I_623922201` | `GameFallbackAdsRandomParam` | `dd_u2i_knn_recall` | `random` | 30 | **LM** |

**降级层级汇总**（代码中仅出现 L2 / L3 / LM；`623012104` 长序列主模型不设 `downgrade_level`）：

| 层级 | 触发时机 | 对应队列 |
|---|---|---|
| **L2** | 重度降级 | `611020304`、`611920304`、`623012108`、`624012101` |
| **L3** | 中度降级 | `611010104`、`611912108` |
| **LM** | 最轻度降级 | `611610101`、`611610102`、`623922201` |
| **无** | 不受降级影响 | `623012104`、`611010103`、`611030109`/`611030110`/`111030201`/`611030202`/`612031201` |

#### 11.3.3 OhMyEmb 节点配置

> User Tower 在 [`ohmyemb/online_query_user.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/online_query_user.yaml)，Item Tower 在 [`ohmyemb/offline_item.yaml`](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/ohmyemb/offline_item.yaml)。所有节点 op 均为 `SimpleStandardURankerOp`，`allow_error: true`，`item_type: PRODUCT`，下表仅列出关键区分字段。

**A. RCMD U2I 系列**

| 节点名 | 关联召回队列 | service_name (User/Item) | business | emb_column (User/Item) | model_name（非 BR / BR）|
|---|---|---|---|---|---|
| `rcmd_u2i_knn_recall@embeddingv2` | `623012104`（长序列 V2）| `StandardURankerRcmdOnline` / `StandardURankerRcmdOffline` | `paidads_rcmdrecall_*` | `user_emb_output` / `item_emb_output` | `recall_rcmd_longseq_v2_user_tower` / `recall_rcmd_longseq_v2_user_tower_br`（Item 对应 `..._item_tower_offline` / `..._item_tower_br_offline`）|
| `rcmd_u2i_knn_recall@embeddingv5` | 代码中未见引用 | 同上 | 同上 | 同上 | `recall_all_u2i_seq_sid_user/item_offline`（BR: `recall_all_u2i_multi_target_*`）|
| `rcmd_u2i_knn_recall@embeddingv7` | 代码中未见引用 | 同上 | 同上 | 同上 | `recall_search_joint_rcmd_user/item_tower_offline` |

注：`623012104` 的 `required_output` 为 `rcmd_u2i_knn_recall@embeddingv1`，OhMyEmb 一侧通过 `emb_service_online.yaml` 的别名把 `@embeddingv1` 绑定到真实节点；OhMyEmb 内部不单独维护 `rcmd_u2i_knn_recall@embeddingv1` 的训练模型节点。

User Tower `required_feature` 统一为：`Context_entrance, Context_ItemID, Context_ItemID_v2, Context_ShopID, Context_ShopID_v2`。

**B. Search KNN 系列**

| 节点名 | 关联召回队列 | service_name (User/Item) | business | model_name（非 BR / BR）|
|---|---|---|---|---|
| `sa_q2i_knn_recall@embedding64dimv3` | `611610101`、`611610102` | `StandardURankerSearchOnline` / `StandardURankerSearchOffline` | `paidads_searchrecall_*` | `recall_all_u2i_seq_sid_user/item_offline`（BR: `recall_all_u2i_multi_target_*`）|
| `sa_q2i_knn_recall@embedding64dimv5` | 代码中未见引用 | 同上 | 同上 | `recall_search_joint_rcmd_user_tower` / `recall_search_joint_rcmd_item_tower_offline` |
| `knn_u2u@embeddingv1` | `624012101`（U2U）| `StandardURankerSearchOnline`（仅 User Tower）| `paidads_searchrecall_online` | `recall_search_joint_rcmd_user_tower` |

User Tower `required_feature`：`Context_entrance, Context_query_ftatt_embedding, Context_query_spm_token_list`（`knn_u2u@embeddingv1` 仅需 `Context_entrance`）。

**C. Paidads Item 系列**（Search Brand Max / `611912108`）

| 节点名 | 关联召回队列 | model_name（非 BR / BR）| 备注 |
|---|---|---|---|
| `paidads_item@embeddingv1` | `611912108`（Brand Max）| `recall_search_joint_rcmd_user_tower` / `..._item_tower_offline` | union-model |
| `paidads_item@embeddingv2` | 代码中未见引用 | `recall_all_u2i_multi_target_user/item_offline` | union-model new |
| `paidads_item@embeddingv3` | 代码中未见引用 | `recall_rcmd_longseq_v2_user_tower` / `..._item_tower_offline`（BR 带后缀）| long-seq model |
| `paidads_item@embeddingv4` | 代码中未见引用 | `recall_all_u2i_seq_sid_user/item_offline` | union-model new |

#### 11.3.4 AB 参数约定

| 参数模板 | 作用范围 | 举例 |
|---|---|---|
| `knnRecallCfg{queue_name}` | 控制 KNN 队列开关和队列级参数 | `knnRecallCfg623012104`、`knnRecallCfg611010104` |
| `knnRecall*ModelCfg` | 控制 KNN 队列使用的模型参数 | `knnRecallModelCfg`（Search 主）、`knnRecallClusterModelCfg`、`knnRecallRcmdLongSeqModelV2Cfg`、`knnRecallRcmdUnionModelCfg`、`knnRecallRcmdU2UModelCfg`、`knnRecallPaidAdsItemModelCfg` |
| `qt2iCfg{queue_name}` | QT2I 文本队列的缓存 key | `qt2iCfg611020304`、`qt2iCfg611920304` |
| `QueueParam{queue_name}` | Redis / FSE 队列参数 | `QueueParam622031201`、`QueueParam611030109`、`QueueParam611030202` |
| `GameFallbackAdsRandomParam` | Discovery Fallback 专用 | `623922201` |
| `itemVespaClientKey` | `paidads_item` Vespa 客户端切换 | `611912108` |
| `MergeQueueQuota` / `RecallPickedNum` | SnakeMerge 全局参数 | 所有 `SnakeMergeFilterOp` 共享 |
| `DefaultCacheTTL` | 缓存 TTL 默认值（由 AB 覆盖）| 出现在所有带 op cache 的节点 key 模板中 |

AB 参数在 `paidads-recall` 中通过 [`pkg/retrieval/common_operator/base_recall_op.go`](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/common_operator/base_recall_op.go) 的 `BaseRecallOp.Init` 注册：YAML 的 `ab_param_key` 字符串对应 `adsengine-abtest-param.ABTestConfig` 结构体中某个字段的 json tag，运行时从 `GraphEngineCtx.GetABParam()` 反射取出对应字段并反序列化为队列 `RecallConfig`（若 `ab_param_key` 在 `ABTestConfig` 中不存在，`Init` 会直接报错）。

KNN 队列默认要同时看两层 AB 参数：队列级参数通常是 `knnRecallCfg{queue_name}`，控制 enable、limit、cache、TTL、read/write mode 等队列行为；模型级参数按队列类型选择 `knnRecallModelCfg`、`knnRecallClusterModelCfg`、`knnRecallRcmdLongSeqModelV2Cfg`、`knnRecallRcmdUnionModelCfg`、`knnRecallRcmdU2UModelCfg`、`knnRecallPaidAdsItemModelCfg` 等，用于指定 Vespa / rank profile / embedding field。最终进入后链路的数量还会受全局 `MergeQueueQuota` 和 `RecallPickedNum` 影响。

常见静态上限速查（线上实际值仍以 AB values 为准）：

- Search KNN：`611010104` / `611010103` / `611912108` 的 `label2recall_limit` 为 raw `1000`、extend `400`，`additional_hit=1000`；`611610101` / `611610102` 为 raw `200`、extend `20`，`additional_hit=1000`。
- Discovery：`623012104` / `623012108` 静态 `recall_limit=500`、`additional_hit=2000`；`623012104` 的 AB 示例中曾覆盖到 `recall_limit=1000`。`624012101` 为 `recall_limit=40`、`target_hits=40`；`622031201` / `622031101` 为 `result_global_limit=2500`；`623922201` fallback 为 `result_global_limit=30`。
- Shop / Live：`677010101` raw `200`、extend `0`、`additional_hit=1000`；`677020301` raw seed `1`、raw hit `300`；Shop 多个二阶段后段 `result_global_limit=1000`；Live KNN `653012101` / `655012101` 为 `500`，Live random `653940401` 为 `50`，Live PDP `658940401` 为 `100`。
- Video / Brand 和部分 Text / KV 队列尚未全部沉淀到同粒度静态表；遇到这类问题应回到对应 retrieval YAML、AB Feature values 和队列登记表交叉确认。

#### 11.3.5 按线索反查完整信息（Agent / 人工排查指南）

> 适用场景：只知道 `queue_name` / `node name` / `required_output` / `EGO model_name` / `serving 名称` / `服务场景` 中的一部分，需要逐步反查出队列配置、AB 参数、EGO/AFP 依赖、DataSuite / 监控入口和上下游关系。
>
> 重要提醒：
> - `623012104` / `623012108` 都是 **KNN 队列**，资料完整且较新，是最适合演示的样例，但不能把 KNN 的排查路径机械套到全部队列。
> - 队列表 spreadsheet（如 `1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk`）收录范围更大，但不同队列类型在代码中的落点并不相同；**登记表与代码冲突时，仍以 `graph-manager-conf` / `paidads-recall` master 和线上平台为准**。
> - 老文档 / README 中可能出现旧式 AB key 示例（如 `U2IKnn623012108Config`）；当前新增队列和现网代码以 `knnRecallCfg{queue_name}` / `QueueParam{queue_name}` / `qt2iCfg{queue_name}` / 专用 fallback key 为准。
>
> Agent 默认顺序：
> 1. 先用本节静态字段把 `queue / node / model / required_output / service_name` 定位出来；
> 2. 再按类型调用 skill：`sp-ab`、`sra-afp`、`sra-ego-serving-list`、`sra-ego-checkpoint`、`sra-datasuite-crawler`、`sp-grafana`、`sra-ds-sql-query`；
> 3. 若技能查不到，再把本节对应的小节步骤和平台链接返回给用户；
> 4. 不要在这里直接停在“KB 没写，所以不能回答”。

**0. 先用总表做 L0 入口，再落到代码和平台**

表格：`source_refs` 中的 `1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk`（gid `65057492`）是目前 Ads 全量队列的**最好入口**，适合回答“这个队列大概属于什么类型 / 哪个场景 / PIC 是谁 / 大致用途是什么”。

这张表当前至少可以稳定提供：

| 列 / 区域 | 用法 |
|---|---|
| 顶部命名规则区 | 用来解码 `queue_name` 的各个数字段含义：广告类型、场景、L1 队列大类、业务属性、服务类型、L2 子类型、具体序号 |
| `队列编号` | 最稳定的主键，后续统一回到代码和平台里继续查 |
| `队列名称` | 对人类友好的 L0 标签，通常已经暴露了 `Scene / L1 / Server_Type / L2` 线索 |
| `队列用途概述` | 快速判断它是 KNN / Redis / FSE / fallback / brand / shop / live / video 哪类用途 |
| `PIC` | 找 owner / 业务同学确认时很有用 |
| `quota/limit` / `impression ratio` / `cache_ttl_sec` | 作为线上表现和配置的补充口径，便于和 AB / SQL 结果交叉核对 |
| 分区标题（Search / Rcmd / Shop ...） | 先把范围缩到对应 graph 文件，再进入代码核实 |

实测例子：
- `623012108` 在总表中显示为 `All-Discovery-U2I-Efficiency-Embedding (U/Q)2I-ModelU2I-08`，这和代码中的 `KnnU2IOp + U2I + embedding + ModelU2I` 完全一致。
- `622031201` 在总表中显示为 `All-Tag2I-Redis-Discovery-Efficiency-StragyI2I-01`，这能帮助排查者在不看代码前就先判断它更像 **Redis I2I**，而不是 KNN。
- `611030109` 在总表中显示为 `All-Search-Q2I-Efficiency-Tag2I-Redis-Model-Q2I`，也能提前提示它应优先走 `QueueParam + RedisQ2IQRCustomizedOp` 的排查路径。

推荐顺序：
1. 先在总表查 `queue_name`、`queue_name` 对应的人类可读名称、用途、PIC。
2. 根据总表里的 `Scene / L1 / Server_Type / L2` 先做类型判断。
3. 再到 `graph-manager-conf` / `paidads-recall` / AB / EGO / AFP 做代码和平台核实。

**A. 先判队列类型，再决定查询路径**

| 入口特征 | 典型 op / 字段 | 典型队列 | 是否一定有 EGO / AFP | 推荐主路径 |
|---|---|---|---|---|
| `required_output` 指向 embedding，`model_param_key` 为 `knnRecall*ModelCfg` | `KnnQ2IOp` / `KnnU2IOp` | `623012108`、`623012104`、`611010104` | 通常有 | graph-manager-conf → AB → OhMyEmb → EGO → AFP |
| `required_output` 为 user embedding，且下游紧跟 `GetFseU2IOp` | `KnnU2UOp` + `GetFseU2IOp` | `624012101` | 只有第一阶段有 | graph-manager-conf → AB → OhMyEmb / EGO（user tower）→ FSE |
| `model: xxx` / `source: unify` / `ab_param_key: QueueParam...` | `RedisI2IOp` / `RedisU2IOp` / `RedisQ2IQRCustomizedOp` / `RedisD2IOp` | `622031201`、`611030109` | 通常没有独立 EGO / AFP | graph-manager-conf → AB QueueParam → paidads-alg rule-based 路径 / Redis 数据 |
| `user_actions_weight` / `result_global_limit` / `RecallFetchFSE...` | `RecallFetchFSERealtimeQ2IItemOp` / `RecallFetchFSEQ2I2IItemOp` / `GetFseU2IOp` | `611030202`、`612031201`、`624012101` 第二阶段 | 不一定 | graph-manager-conf → AB QueueParam / related_operators → FSE / 行为表 |
| `qt2iCfg...` / `vespa_name: sa_text_match_recall` | `QT2IOp` | `611020304`、`611920304` | 没有 | graph-manager-conf → AB `qt2iCfg` → Vespa 文本匹配配置 |
| `rank_profile: random` / fallback 专用 key | `GetVespaFallback` | `623922201` | 没有 | graph-manager-conf → AB fallback key → Vespa random |

**B. 从 `queue_name` 或 `node name` 开始**

如果用户只是问“队列具体配置”，先拆成两层：静态配置查 `graph-manager-conf/retrieval/*.yaml` 或本节表格；线上实际生效值继续查 AB Test Platform 的 Feature values。静态字段和 AB values 冲突时，以 AB / 线上为准。

1. 先在 `graph-manager-conf` master 的 `retrieval/*.yaml` 中定位队列节点。
   可直接按 `queue_name`、`node name` 或 `ab_param_key` 搜索。
2. 记录这几个字段：`op`、`queue_name`、`ab_param_key`、`model_param_key`、`vespa_name`、`rank_profile`、`required_output`、`placements`、`recall_limit/result_global_limit`、`downgrade_level`、缓存配置（`with_redis/with_memory/rw_mode`）。
3. 根据 `op` 分流：
   - `KnnQ2IOp` / `KnnU2IOp`：继续查 `AB -> OhMyEmb -> EGO -> AFP`。
   - `KnnU2UOp`：先查 `AB -> OhMyEmb/EGO user tower`，再看下游是否接 `GetFseU2IOp`。
   - `Redis*Op`：重点查 `QueueParam...`、`model`、`source`、对应 `paidads-alg` 离线产出，不必强行追 EGO。
   - `RecallFetchFSE*` / `GetFseU2IOp`：重点查 FSE / 行为聚合逻辑、`user_actions_weight`、上游 seed 节点。
   - `QT2IOp`：重点查 `qt2iCfg...`、`vespa_name`、`rank_profile`、tag/phrase 规则。
   - `GetVespaFallback`：重点查 fallback key、`rank_profile=random`、结果上限和缓存。
4. 再到 `paidads-recall` master 验证：
   - `BaseRecallOp.Init` / `GetUpdatedConfig` 是否会通过 `ABTestConfig` 反射读取该 `ab_param_key`；
   - 对应 op 的 manual / README 是否有该类节点的补充说明；
   - `Makefile` 中 `GraphManagerVersion` 指向哪个 graph tag。
5. 若是 KNN，再查 `graph-manager-conf/ohmyemb/*.yaml`：
   - 用 `required_output` 或 `model_name` 搜 `online_query_user.yaml` / `offline_item.yaml`；
   - 确认 `service_name`、`business`、`emb_column_name`、`required_feature`；
   - 再去 EGO 查 serving / checkpoint / version。

**C. 从 `EGO serving model` 或 `model_name` 开始**

1. 先在 EGO 查 serving 列表 / 详情 / 版本历史，拿到：
   - `online_model_name`
   - `checkpoint_id`
   - `checkpoint_model_name`
   - `checkpoint_model_version_name`
   - `predictor_service_info`
2. 再到 `graph-manager-conf/ohmyemb/*.yaml` 按 `model_name` 反查节点名。
3. 用该节点名去找 retrieval YAML 中谁在使用对应 `required_output`。
4. 这样可以把 `model_name -> OhMyEmb 节点 -> queue_name / node name -> AB key` 串起来。
5. 若反查不到具体队列，要考虑：
   - 该模型只是共享底座，被多个队列共用；
   - 该模型在 ohmyemb 中存在，但当前 retrieval YAML 没有引用；
   - 该模型属于 Search / RCMD / Brand / Live / Video 的另一条 graph。

**D. 从 `服务场景` 或 `graph 文件` 开始**

1. 先按场景缩小到 graph 文件：
   - Search Product Ads：`retrieval/search_recall.yaml`
   - DD：`retrieval/recommend_dd.yaml`
   - YMAL：`retrieval/recommend_ymal.yaml`
   - PP：`retrieval/recommend_pp.yaml`
   - Game：`retrieval/recommend_game.yaml`
   - Live / Video / Shop / Brand：对应 `live_ads_recall.yaml` / `video_ads_recall.yaml` / `shop_*` / `brand_*`
2. 在该文件内先看 `MergeRecallQueue` / merge 节点 inputs，可以快速知道当前场景都挂了哪些队列。
3. 再逐个看上游节点的 `op` 类型，决定是否继续查 `AB / EGO / AFP / Redis / FSE / Vespa`。

**D.1 AB 平台实操提醒（已实测）**

- `get-experiment.py` 现成脚本已验证可稳定查询：`scenes`、`layers`、`feature <feature_id>`、`feature-values <feature_id>`。
- 现成脚本暂不支持按 `ab_param_key / feature_key` 直接搜索 `feature_id`；命令列表里只有 `feature` 和 `feature-values`，没有 feature-search 子命令。
- 因此，若当前只知道 `knnRecallCfg...` / `QueueParam...` / `qt2iCfg...` / `GameFallbackAdsRandomParam` 这类 key，建议先到 AB UI 的 `Feature List` 页面搜索 `feature_key`（Ads 项目路由是 `/feature/42`），拿到 `feature_id` 后再用 `sp-ab` 或现成脚本导出 detail / values。
- `623012108 -> knnRecallCfg623012108 -> feature_id=2346` 已在线验证，可作为标准样例；其他非 KNN 队列本次已验证到 `graph / op / ab_param_key` 层，继续下钻 AB 时按上一条执行。

**E. 推荐的最小补齐字段集合**

排查结束时，建议至少补齐以下字段，避免只得到“半张图”：

| 类别 | 需要补齐的字段 |
|---|---|
| 基本识别 | `queue_name`、`node name`、`scene / graph 文件`、`op` |
| 队列配置 | `ab_param_key`、`model_param_key`、`vespa_name`、`rank_profile`、`required_output`、`placements`、`downgrade_level`、缓存模式 |
| 平台映射 | AB feature / layer、EGO serving / checkpoint（若适用）、AFP scenario / DAG / slot（若适用） |
| 上下游 | 上游 seed 节点、下游 merge 节点、是否两阶段（如 `KnnU2UOp -> GetFseU2IOp`） |
| 数据与监控 | 对应 DataSuite / monitor / SQL 入口，或 Redis / FSE / Vespa 数据源 |

**F. 已实测的不同类型样例**

| 队列 | 类型 | 反查结果 | 结论 |
|---|---|---|---|
| `623012108` | `KnnU2IOp` | `knnRecallCfg623012108` → `knnRecallRcmdUnionModelCfg` → `dd_knn_ego_union_v1` / `ymal_knn_ego_union_v1` → `recall_search_joint_rcmd_*` / `recall_all_u2i_*` 候选模型 → AFP slot 链路 | **标准 KNN 路径**，适合演示“全链路反查” |
| `624012101` | `KnnU2UOp` + `GetFseU2IOp` | `knnRecallCfg624012101` → `knnRecallRcmdU2UModelCfg` → `u2u_knn_ego_union_v1` → `knn_u2u@embeddingv1`（只 user tower）→ 下游 `GetFseU2IOp` | **半 KNN、半 FSE**，不能只查 EGO |
| `622031201` | `RedisI2IOp` | `QueueParam622031201` + `model: stgy_i2i` + `source: unify` + `label2weight` | **Redis I2I**，重点在 QueueParam / Redis 产出，无独立 EGO / AFP |
| `611030109` | `RedisQ2IQRCustomizedOp` | `QueueParam611030109` + `model: offline_llm_q2i` + `source: unify` | **Redis Q2I**，重点在 rule-based / Redis，不走 KNN 模型链 |
| `611030202` | `RecallFetchFSERealtimeQ2IItemOp` | `QueueParam611030202` + `user_actions_weight` + `result_global_limit=100` | **FSE Realtime**，重点看 FSE / 行为权重，不追 EGO |
| `611020304` | `QT2IOp` | `qt2iCfg611020304` + `vespa_name: sa_text_match_recall` + `rank_profile: broad_tag_va` | **Text / Tag 召回**，重点看文本匹配配置 |
| `623922201` | `GetVespaFallback` | `GameFallbackAdsRandomParam` + `rank_profile: random` + `result_global_limit=30` | **Fallback**，通常没有模型 / AFP 链路 |

**G. 本节的实用结论**

- 若只知道 `queue_name`，第一跳永远是 `graph-manager-conf/retrieval/*.yaml`，先判 `op` 再决定后续路径。
- 若只知道 `model_name` 或 EGO serving 名，第一跳应是 `EGO -> OhMyEmb -> retrieval YAML`，不要直接去 AB 平台盲搜。
- 若只知道场景（Search / DD / YMAL / PP / Game），先定位 graph 文件，再看 merge inputs 和节点 op。
- 若是 `Redis*` / `FSE*` / `QT2I` / `Fallback`，**没有必要强行补 EGO / AFP**；这类队列的“完整信息”重点在 `QueueParam / qt2iCfg / FSE 配置 / Vespa rank_profile / 离线产出模型`。
- 若是 `KnnU2IOp` / `KnnQ2IOp`，完整路径通常才会覆盖 `AB + OhMyEmb + EGO + AFP + DataSuite`。
- 回答“Vespa 里存了什么”时，只能从队列配置反推出已知类别：KNN embedding corpus（如 `sa_q2i_knn_recall`、`dd_u2i_knn_recall`、`paidads_item`、`paidads_live`、`knn_u2u`），Text / Tag 倒排字段（如 QT2I broad match tag / phrase、Shop 的 item title / native tag），以及 fallback / random rank profile 使用的候选文档。KB 没有完整 Vespa schema；若用户要每个 schema 的全字段，必须继续查 Vespa template / schema / index config。
- 回答“ads item 为什么进 / 出索引、延迟多少”时，Recall 侧只能先查 `mp_paidads.ods_shopee_paidads_index_log` 中某天、某 region、某 placement 下的 `INDEX / UPDATE / DELETE` 事件和近似时间点；真正触发条件与精确延迟要继续追 `Ads Info`、`Indexer` 及其上游状态变更。KB 不保存固定 SLA。
- 回答“离在线一致性”时，当前可确认三层：Recall Scenario 79 的在线推理 slot 大部分与 CTR Scenario 82 共享定义；User Tower / Item Tower 来自同一训练产物并通过 EGO release 到 Serving；OhMyEmb 用 `ready_at_time` 监控 `country × node_name × model_name` 是否就绪。KB 当前没有记录统一的离线 embedding vs 在线 embedding 自动 diff SOP。
- 回答“和后链路一致性”时，先说明三类机制：上游由 `Ads Info` / `Indexer` 保证广告状态和可检索字段；召回通过 `BizTagCalculateOp`、`PackRecallAdsResultOp`、`SendRecallLogOp` 把业务标签和日志透传给 Prerank / Rank / MixRank / 监控；链路追踪依赖 tracking 表 `algo_json_data.recall_queue_ids` 与 `ab_sign`。KB 还没有完整字段契约表、SLA 或变更通知机制。

**H. 登记表没有 PIC 时，如何用 git 反查“最近实现负责人候选”**

这是一条**兜底路径**，适合 Shop / Live / Video / Brand 等登记表 `PIC` 缺失、但又需要先找最近 owner 继续排查的场景。

使用原则：
- `官方 PIC` 仍以登记表 / owner 文档 / MR 页面确认为准。
- git 历史只能帮助反查“最近实现负责人候选（implementation owner candidate）”，不能无条件替代 `PIC`。

推荐顺序：
1. 先按场景定位主仓库和主文件：
   - Search / DD / YMAL / PP / Game / Shop / Live / Video / Brand：优先看 `graph-manager-conf/retrieval/*.yaml`
   - recall 服务侧补充：再看 `paidads-recall`
   - KNN 队列若还要继续追模型 owner，再补 `oh-my-embedding` / `paidads-alg`
2. 在主文件里先定位该 `queue_id` 或节点名。
3. 用 git 历史找“首次引入这条队列”的 commit：
   - `git log --all --reverse -S '<queue_id>' -- <file>`
4. 再用 remote refs 和 merge commit 找 feature branch：
   - `git branch -r --contains <commit>`
   - `git log --merges --grep '<feature keyword>'`
5. 若同一个账号同时出现在：
   - 首次引入 commit author
   - feature branch 名
   - merge branch 记录
   则可把该账号记为“最近实现负责人候选”，用于继续追问或补 owner 信息。

使用边界：
- `commit author != 官方 PIC != MR 创建人`，三者可能不同。
- 若只能证明“某账号最近改过这条队列”，建议在文档里写成“最近实现负责人候选”或“最近修改人”，不要直接覆写 `PIC`。
- 最稳妥的落地方式是：先用 git 反查到候选人，再去登记表、MR 页面或业务 owner 处做一次确认。

**I. 按 `PIC` 串联队列、离线任务、DataSuite 和 Data Delivery（轻量版）**

> 适用场景：只知道 `PIC`，或者手里同时有 `queue_id / PIC / DataSuite workflow link / sinkerName` 中的一部分，希望把“队列登记表 -> 离线任务 -> 下发链路 -> 监控入口”先串成一张大图。
>
> 这条路径对 **非 KNN 队列**尤其有用，例如 `Redis I2I`、`LLM Q2I`、`QT2I`、`U2U2I`、`blacklist / FSE` 等。它们往往不会像 KNN 那样自然落到 `OhMyEmb + EGO + AFP`，但通常会落到 `DataSuite workflow + Redis/Vespa/databus 配送 + 监控 SQL / Dashboard`。

先明确边界：
- `Product Ads -> Recall` 任务等级表收录的是“Recall 管理范围内的离线任务资产”，其中既包含**直接服务线上队列**的任务，也包含样本、query/item 特征、转化数据、blacklist、monitor 底表等辅助任务。
- 因此，`PIC 相同` 只能说明“这些资产大概率由同一 owner 维护”，**不能自动推出**“每个任务都与该 PIC 的每条队列一一对应”。
- 对非 KNN 队列，更稳的写法通常是：`直接对应` / `高概率关联` / `同 PIC 管理的周边资产`，不要强行写成一对一。

推荐顺序：
1. 先查队列登记表（`1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk`），拿到 `queue_id / queue_name / usage / PIC / scene / 大致类型`。
2. 再查 Ads 全量任务等级表（`1gPlN8AW4C9u6XQPep64iTsfaLhYYDyhQyV0DAi72RFk`），只看 `Product Ads -> Recall` 分区，并按同一个 `PIC` 过滤。
3. 先用任务名 / 描述把任务分成几类：
   - `直接产候选 / 直接产 Redis 映射`：如 `stgy_i2i`、`model_i2i`、`OfflineQ2I-LLM-*`
   - `query / item 特征准备`：如 `QueryFeatures-WriteToHive`、`q2tag2i.item_feature_write_to_hive`
   - `tag / usertag / tagservice`：常见于 Redis / tag-based 召回的辅助链路
   - `blacklist / filter / monitor / sample / pbdata`：通常是支持资产，不一定直接对应线上队列
4. 打开任务等级表里的 `DataSuite Workflow Link`：
   - 若是 workflow，可在二级看到 `nodes + links`
   - 再逐个打开节点，看它是 shell/SSH 任务还是 Python Spark 任务
5. 读节点详情时重点看：
   - shell/SSH：`content`
   - Python Spark：`pythonSparkConfig.mainResource`、`programArgument`
   - 依赖和产出：`inputMarker`、`outputMarker`
   这一步通常就足够判断它是在做“产候选 / 写 Redis / 写 databus / 准备 query/item 特征 / 生成 blacklist”中的哪一类。
6. 若任务明显有“离线产出 -> Redis / Vespa / databus / namespace 下发”的后半段，再到 AlgoLab Data Delivery（project `11`）按 `PIC` 或 `sinkerName` 继续追。

当前已验证、适合作为样例的链路：

| PIC | 队列（非 KNN 优先） | 任务等级表中的对应资产 | 当前可写结论 |
|---|---|---|---|
| `kaiqiang.wang@shopee.com` | `622031201`（Offline I2I merge）、`622031101`（model I2I） | `stgy_i2i_productads_strategy_1d_recall`、`model_i2i_productads_strategy_1d_recall`、`usertag_*`、`tagservice_*` | **直接对应 + 同 PIC 周边资产**。`stgy_i2i` / `model_i2i` 可直接视为 I2I 主产出任务；`usertag/tagservice` 更像 tag / Redis 辅助链路。 |
| `swam.yeehn@shopee.com` | `611030109`、`611030110`（LLM Q2I） | `QueryFeatures-WriteToHive`、`OfflineQ2I-LLM-search-*`、`OfflineQ2I-LLM-qwen-*` | **直接对应**。可把它理解成“query 特征准备 + 小时级 LLM active ads / rank 产出”的完整离线链。 |
| `jiaheng.dou@shopee.com` | `624012101`（U2U2I） | `u2u2i_productads_strategy_1d_recall` | **直接对应**。workflow / 主脚本都能直接落到 `u2u2i.py`。 |
| `lumm@sea.com` | `611020304`（QT2I） | `q2tag2i.item_feature_write_to_hive`、`recall-unify-i2i` | **部分对应**。前者更像 QT2I / item-feature 准备链；后者是 I2I cache sync / delivery 相关共享资产，不一定只服务 `611020304`。 |
| `bert.chen@shopee.com` | `111520301`、`111520302`（manual ads） | `llmtopk_product_ads_strategy_1d_recall` | **同 PIC 管理，但当前不能写成一对一**。可确认同一 owner 同时维护 manual ads 队列和 llmtopk recall pipeline。 |
| `teng.lv@shopee.com` | 队列表中暂无直接 PIC 命中 | `blacklist_for_fse_productads_strategy_1d_recall` | **更像 delivery / blacklist 侧 owner**。可确认有 blacklist 任务；若要继续证明它和具体 queue 的对应关系，通常还要补 Data Delivery 权限。 |

DataSuite 这层当前能稳定拿到的信息：
- `workflow/detail`：看 workflow 的 node / edge 结构，适合判断是“国家并行 + union”“hourly active rank”“cache sync”还是“特征准备”。
- `file/detail`：看节点具体内容。
  - 若节点是 shell/SSH 任务，通常直接在 `content` 里看到执行命令。
  - 若节点是 Python Spark 任务，通常要继续看 `pythonSparkConfig.mainResource` 指向的脚本文件，再结合 `programArgument` 判断输入输出。

Data Delivery / Databus 这层推荐使用方式：
- 只把它当作**下发链路检查层**，不要把旧 SOP 中的静态配置值直接抄回 KB。
- 更适合回答的问题是：
  - “这条离线产出最终是写 Redis 还是写 Vespa？”
  - “它依赖哪个 marker / data path 才会触发？”
  - “最近一次 version / history 是否成功？”
  - “target 的 key prefix / index 语义是什么？”
- Databus SOP 中可复用的稳定骨架只有：
  - `准备离线数据`
  - `确认 marker`
  - `进入 project 11`
  - `核对 Task Type / Data Type`
  - `核对 Source Info`
  - `核对 Target Info`
  - `查看 History / version / monitor`
  - `必要时做反序列化 debug`
- 不应从旧 SOP 继承：Redis 地址、HDFS Router、账号密码、默认阈值、并发建议、联系人。

AlgoLab Data Delivery 这层的当前边界：
- 页面入口：`https://algolab.shopee.io/datadelivery/data-sinker/task?projectId=11`
- 这层非常适合回答“某离线产出最终写到了哪个 Redis / Vespa / databus / namespace / sinker”。
- 但当前若缺 `ALGO_DATADELIVERY_READ`（某些接口还要 `ALGO_DATADELIVERY_APPROVE`），就只能把它当作**下一跳入口**，无法稳定读到 detail / version / monitor。
- 因此，在权限不足时，建议在 KB 或排查报告中写成：
  - “可继续到 Data Delivery project 11 追下发链路”
  - “当前因权限未拿到 detail / version / monitor，暂不把 sinker 结论写死”

实操提醒：
- 这条 `PIC` 反查链最适合 Redis / LLM / QT2I / U2U2I / blacklist 等非 KNN 资产；对 KNN 队列仍应优先走本节 A–F 的 `graph -> AB -> OhMyEmb -> EGO -> AFP` 主路径。
- 若队列登记表 `PIC` 为空，则先回到 H，用 git 找“最近实现负责人候选”，再来套这条 `PIC -> 任务 -> workflow -> delivery` 路径。

**J. 按 `PIC` 反查队列（轻量版）**

> 适用场景：手里只有 `PIC`，想先知道他大致负责哪些 Recall 队列或相关离线资产。

推荐顺序：
1. 先在 `Queue Registry` 里按 `PIC` 过滤，拿到这位 owner 显式登记过的 `queue_id / scene / queue_type`。
2. 若目标场景是 Shop / Live / Video / Brand，且登记表里 `PIC` 为空：
   - 先走 H，用 git 反查“最近实现负责人候选”；
   - 再把候选人带回队列表和任务等级表继续串。
3. 再在 `Product Ads 全量任务等级表` 的 `Product Ads -> Recall` 分区按同一 `PIC` 过滤，补离线 workflow / blacklist / feature 准备 / delivery 资产。
4. 若需要继续确认“某 PIC 是否真的负责这条队列”，再顺着：
   - `queue -> graph-manager-conf / paidads-recall`
   - `PIC -> 任务等级表 / workflow / Data Delivery`
   两边交叉验证。

使用边界：
- 这条路径解决的是**手动反查方法**，不是静态 `PIC -> queue` 总表。
- 对空 `PIC` 队列，更稳妥的写法是“最近实现负责人候选”或“待 owner 确认”，不要把 git author 直接覆写成官方 PIC。

**K. 高频 op 手动速查（轻量版）**

> 适用场景：只看到 op 名，想快速知道它属于哪一层、先查什么配置、再去哪个平台。

| op | 作用层 | 第一跳 | 关键字段 | 下一跳 |
|---|---|---|---|---|
| `KnnQ2IOp` / `KnnU2IOp` / `KnnU2UOp` | KNN 召回 | `graph-manager-conf/retrieval/*.yaml` | `ab_param_key`、`model_param_key`、`required_output`、`rank_profile`、`recall_limit/result_global_limit` | §11.3.3 OhMyEmb、§11.3.4 AB、EGO / AFP |
| `RedisQ2IOp` / `RedisU2IOp` / `RedisI2IOp` | Redis 映射召回 | retrieval YAML | `QueueParam*`、`model`、`source`、`limit_per_seed / result_global_limit` | 任务等级表、DataSuite workflow、marker/output、Data Delivery、Redis 读样本 |
| `SimpleStandardURankerOp` | OhMyEmb / StandardURanker 推理 | `graph-manager-conf/ohmyemb/*.yaml` | `service_name`、`business`、`model_name`、`emb_column_name`、`required_feature` | Predictor / OnlinePS / EGO Serving |
| `RecallFetchFSERealtimeQ2IItemOp` / `GetFseU2IOp` | FSE / 实时行为召回 | retrieval YAML | `user_actions_weight`、`result_global_limit`、`source table / key` | FSE / 实时链路、dependency monitor |
| `SnakeMergeFilterOp` | merge / quota / 截断 | retrieval DAG + `paidads-recall` merge 逻辑 | `MergeQueueQuota`、`RecallPickedNum`、队列输入顺序 | Recall Funnel、Queue Metrics、tracking / unpick reason |

实操提醒：
- 高频 op 的第一跳始终是**先回 graph**，确认它出现在哪张 retrieval / ohmyemb YAML、前后连接哪些节点。
- 若目标是定位线上效果或耗时，不要停在 op 名字本身，必须继续追到 `queue_name / ab_param_key / required_output / model_name`。

**非 KNN 队列最短 debug 路径：**
1. 先从 retrieval YAML 确认 `QueueParam* / model / source / result_global_limit`。
2. 再回任务等级表 / DataSuite workflow，确认主脚本、输入输出路径、`outputMarker` / `inputMarker`。
3. 若 workflow 有明确“下发”后半段，再进 Data Delivery project `11`，依次检查 `Task Type / Data Type / Source Info / Target Info / History / version / monitor`。
4. 若目标是 Redis 映射或 PB/KV 下发，最后用读 Redis 样本或反序列化脚本验证 `key/value` 是否符合预期。

**L. 手动查询：队列下线 / `service_name` 行为差异**

**1. 队列下线（轻量入口）**

推荐顺序：
1. 先判断是：
   - **只关队列开关**：优先查 AB Feature / Layer，确认是否可以只 `disable`
   - **真正删代码**：再去 `graph-manager-conf/retrieval/*.yaml` 和 `paidads-recall` 看 graph version / 注册项
   - **连模型一起退**：再补查 `graph-manager-conf/ohmyemb`、EGO serving、DataSuite / Data Delivery
2. 对 KNN 队列，先确认该 `required_output / model_name` 是否仍被其他队列复用；若仍复用，不应直接把模型链一起删掉。
3. 下线后重点看：
   - `Recall Queue Metrics`
   - `Retrieval Service / Retrieval v3`
   - Search / Discovery / Shop / Live 对应漏斗面板
4. 因此，KB 当前更适合回答：
   - **下线时应该查哪些系统、按什么顺序确认**
   - 而不是直接提供一份“所有队列统一的下线脚本”

**2. `service_name` 行为差异（轻量入口）**

`service_name` 的第一层语义，通常先看“在线 / 离线”和“Search / RCMD”两组差异：

| `service_name` | 第一层语义 | 常见位置 | 重点一起看的字段 |
|---|---|---|---|
| `StandardURankerRcmdOnline` | RCMD 在线 user/query 侧推理 | `online_query_user.yaml` | `business`、`model_name`、`emb_column_name`、`required_feature` |
| `StandardURankerRcmdOffline` | RCMD 离线 item 侧 embedding 产出 | `offline_item.yaml` | `business`、`model_name`、`emb_column_name` |
| `StandardURankerSearchOnline` | Search 在线 user/query 侧推理 | `online_query_user.yaml` | `business`、`model_name`、`required_feature` |
| `StandardURankerSearchOffline` | Search 离线 item 侧 embedding 产出 | `offline_item.yaml` | `business`、`model_name`、`emb_column_name` |

推荐顺序：
1. 先查 §11.3.3，确认该队列落到哪个 OhMyEmb 节点。
2. 再把 `service_name + business + model_name + emb_column_name + required_feature` 一起看，不要只盯 `service_name`。
3. 若要继续判断线上行为或资源占用，再去：
   - `Predictor / OnlinePS`
   - EGO Serving
   - `ready_at_time` / Offline Pipeline

#### 11.3.6 Shop Ads（`shop_search_retrieval.yaml`）

> 口径说明：本节只记录 `graph-manager-conf` master 的**静态 DAG 事实**。`enable` / `limit` / quota 的实际线上值仍可能被 AB 覆盖；若与平台实时值冲突，以 AB / 线上为准。

**A. 场景主链路**

`shop_search_retrieval.yaml` 的主 DAG 结构为：

```text
多路召回
  -> MergeRecallResultOp
  -> ShopAdsInfoFilterOp
  -> MergeRecallQueueOp
  -> FilterInactiveAdsOp
  -> PackAdsShopsOp / SendRecallLogOp
```

这一条 graph 的特点是：Shop Search 里既有单阶段队列，也有明显的两阶段链路（先取 seed，再做 item/shop 扩展），因此排查时必须同时看 `node_chain` 和 `MergeRecallQueue` 的输入顺序。

**B. 队列配置表**

| queue_name | node_chain | op / 路径 | ab_param_key | 检索目标 | 默认 limit / result_limit | 缓存 / rw_mode | merge 输入位置 |
|---|---|---|---|---|---|---|---|
| `677030201` | `Q2I_677030201 -> I2S_677030201` | `RedisQ2IQRCustomizedOp -> VespaI2S` | `Q2IParam677030201` / `I2SParam677030201` | `offline_llm_ecpm_q2i`（`source=unify`）→ `paidads_item` (`rank_profile=item_title`) | 前段 `label2result_limit_per_seed=0`；后段 `seed_global_limit=200`，`result_global_limit=1000` | 前段 `with_memory=true`, `rw_mode=read_write` | 1 |
| `677525101` | `Q2S_677525101 -> S2I_677525101` | `VespaQ2S -> VespaS2I` | `Q2SParam677525101` / `S2IParam677525101` | `paidads_shop` (`rank_profile=keyword_exact_broad_count`) → `paidads_item` (`rank_profile=item_title`) | 前段 `raw seed=1`, `raw hit=100`；后段 `seed_global_limit=200`，`result_global_limit=1000` | YAML 未显式写 op cache | 2 |
| `677020301` | `QT2I2S_677020301` | `VespaQT2S` | `QueueParam677020301` | `paidads_item` (`rank_profile=native_tag`) | `raw seed=1`, `raw hit=300` | `cache_ttl_sec=30`, `cache_read_mode=0` | 3 |
| `677010101` | `Q2S_KNN_677010101` | `KnnQ2SOp` | `knnRecallCfg677010101` | `paidads_item` (`required_output=paidads_item@embeddingv1`, `rank_profile=v1`) | `label2recall_limit raw=200`, `extend=0`, `additional_hit=1000` | `with_memory=true`, `rw_mode=read_write` | 4 |
| `677030202` | `FSEQ2I_677030202 -> I2S_677030202` | `RecallFetchFSERealtimeQ2IItemOp -> VespaI2S` | `Q2IParam677030202` / `I2SParam677030202` | FSE realtime `shop_pop_q2i` → `paidads_item` (`rank_profile=item_title`) | 前段 `raw result=100`, `result_global_limit=200`；后段 `seed_global_limit=200`, `result_global_limit=1000` | FSE 节点无本地 cache；后段 YAML 未显式写 op cache | 5 |

**C. 排查提示**

- `677030201` / `677525101` / `677030202` 都是**两阶段链路**，漏召排查不能只盯住第一个节点；要先判断前段 seed 是否为空，再看后段 Vespa 扩展。
- Shop graph 里当前**未显式出现 `downgrade_level`**，因此本节不补该列；若后续需要实时状态，仍应回到 AB / 线上配置核实。
- `677020301` 是最典型的“文本 + tag 规则”路径；优先查 `rank_profile=native_tag`、`query_tags`、`item_tag_boosts` 和 cache。
- `677010101` 是 Shop 当前最接近 Search KNN 的路径，但它的 `required_output` 指向 `paidads_item@embeddingv1`，排查时要和 Search / Brand 共享的 item embedding 体系区分开。

#### 11.3.7 Live Ads（`live_ads_recall.yaml` / `live_ads_pdp_recall.yaml`）

> 口径说明：本节同样只记录 master YAML 的静态事实。Live 场景使用**两张 graph**：主入口在 `live_ads_recall.yaml`，PDP 入口在 `live_ads_pdp_recall.yaml`。

**A. 场景主链路**

`live_ads_recall.yaml` 的主 DAG 结构为：

```text
多路召回
  -> MergeRecallResultOp
  -> LiveAdsInfoFilterOp
  -> SnakeMergeFilterOp
  -> LivePostFilterOp
  -> BizTagCalculateOp
  -> PackRecallAdsResultOp / SendRecallLogOp
```

`live_ads_pdp_recall.yaml` 则是一条更短的 PDP 支路：

```text
PDP_I2I_658940401
  -> MergeRecallResultOp
  -> LiveAdsInfoFilterOp
  -> SnakeMergeFilterOp
  -> LivePostFilterOp
  -> PackRecallAdsResultOp / SendRecallLogOp
```

**B. 队列配置表**

| queue_name | graph 文件 | node_chain | op / 路径 | ab_param_key | 检索目标 | 默认 limit / result_limit | 缓存 / rw_mode | merge 输入位置 |
|---|---|---|---|---|---|---|---|---|
| `653031201` | `live_ads_recall.yaml` | `Redis_I2I_653031201 -> Vespa_I2I_653031201` | `RedisI2IOp -> LiveI2IOp` | `QueueParam653031201` / `QueueParamVespa653031201` | `model=live_i2i`, `source=unify` → `paidads_item` (`rank_profile=unranked`) | 前段 `result_global_limit=500`；后段 `seed_global_limit=500`, `result_global_limit=1000` | YAML 未显式写 op cache | 2 |
| `653031202` | `live_ads_recall.yaml` | `Redis_U2A_653031202` | `RedisU2AOp` | `QueueParam653031202` | `model=live_u2a_follow_view`, `source=unify` | `result_global_limit=100` | YAML 未显式写 op cache | 5 |
| `653012101` | `live_ads_recall.yaml` | `U2I_KNN_653012101` | `LiveKnnU2IOp` | `knnRecallCfg653012101` | `paidads_item` (`required_output=paidads_item@embeddingv1`, `rank_profile=v1`) | `result_global_limit=500` | `with_redis=true`, `rw_mode=read_write` | 4 |
| `655012101` | `live_ads_recall.yaml` | `U2L_KNN_655012101` | `KnnU2LOp` | `knnRecallCfg655012101` | `paidads_live` (`required_output=paidads_live@embeddingv1`, `rank_profile=v1`) | `result_global_limit=500` | `with_memory=true`, `rw_mode=read_write` | 3 |
| `653940401` | `live_ads_recall.yaml` | `Random_653940401` | `LiveAdsRandomOp` | `QueueParam653940401` | `paidads_live` (`rank_profile=random`, `document_name=stream_default`) | `result_global_limit=50` | YAML 未显式写 op cache | 1 |
| `658940401` | `live_ads_pdp_recall.yaml` | `PDP_I2I_658940401` | `LiveI2IOp` | `QueueParam658940401` | `paidads_item` (`rank_profile=unranked`) | `seed_global_limit=50`, `result_global_limit=100` | YAML 未显式写 op cache | PDP graph 唯一路径 |

**C. 排查提示**

- `653031201` 是 Live 里最典型的**Redis seed -> Vespa 扩展**队列；若最终候选为空，要分清是 Redis 前段没给 seed，还是 `LiveI2IOp` 后段没扩出来。
- `653012101` / `655012101` 都是 KNN，但目标 corpus 不同：前者打 `paidads_item`，后者打 `paidads_live`；排查时不要混淆商品广告和直播间召回。
- `653940401` 是主 graph 里的 random fallback；`658940401` 则是 PDP 支路的 item-to-live 路径，两者不应归为同一类“兜底队列”。
- `live_ads_recall.yaml` 的 `MergeRecallQueue` 还接入了 `653031203` / `653031204` 两个 `LivePopularOp` 节点，但它们当前不在 §5.1 的队列登记表中；本节只把**已登记队列**纳入主表，辅助节点在排查时按 graph 现状补充理解即可。

## 12. 参考资料

<!--
Agent 阅读提示：按查询场景选入口 —
- 了解"为什么做 / 方案思路" → §12.1 设计与方案文档（Google Doc，走 user-google_workspace MCP 读）。
- 需要走"新增队列/模型"的标准流程 → §12.2 SOP。
- 了解团队近期在做什么（OKR / Tracker / Epic）→ §12.3。
- 查 SQL 样例 / 监控面板 → §12.4 DataSuite / Dashboard（配合 §10.1 数据源、§9 指标口径使用）。
- 上线/配置生效/发布 → §12.5 平台入口（AB Test / EGO Portal / OhMyEmb / S&R Release / Space / AlgoLab）。
- 改代码 → §12.6 仓库地图，同 §11.1。
-->

### 12.1 设计与方案文档

| 文档 | 链接 | 对应章节 |
|---|---|---|
| 长序列模型方案 / Epic TRD | [Google Doc](https://docs.google.com/document/d/1pIRzJjlBbv2no_brtXRd7XhQbWFtZFOZCFGocxyEvgs/edit) | §7 训练与准备 |
| 长序列模型方案（Extra Embedding 技术） | [Google Doc](https://docs.google.com/document/d/1sxfoqsG2tkBXw_NRn27Cfjffg29M5O-dKtSN2X7Z-jA/edit) | §6.6 Extra Embedding |
| 召回通路及相关算法介绍 | [Google Doc](https://docs.google.com/document/d/1uEgOiNArIQm5zC6GBq9xejcKihX1rcxhGC1kP-AIznk) | §5 召回通路与策略 |
| 长序列 Rollout 文档 | [Google Doc](https://docs.google.com/document/d/1GZr8tQSqJa88xU_8ZXzXTNJe3TjFazllP2cnVv0AoG4/edit) | §8.5 Rollout 推全文档 |
| EGO 调度用户手册 | [Google Doc](https://docs.google.com/document/d/1GrUQ8ZuufZSnMrrGDICUkRL3rmKmvwbaIDFmvurBjyQ/edit) | §7.3 离线训练调度 |
| OneRec-V2 Technical Report | [arXiv](https://arxiv.org/abs/2508.20900) | §7.2 模型架构参考 |

### 12.2 SOP 文档

| SOP | 链接 | 对应章节 |
|---|---|---|
| Recall Agent SOP（KNN / KV Queue、OhMyEmb Add Model、Feature Server） | [Google Doc](https://docs.google.com/document/d/1cejoBu0Jagx0qdYGPg9QGrCWp4-DHbVXLckh9_UohcY) | §8.1 / §8.2 |
| Recall 自助接入 Skills | [01.ads-engineering skills](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/team/01.ads-engineering) | §8.1 / §8.2 |
| 黑名单过滤 SOP | [Google Doc](https://docs.google.com/document/d/1UnTWVdgGnZgAqkPa-Pn12j8GCRZwn94EoHoxCmzvVjQ) | §5.3.2 AdsInfoFilter |
| 模型/策略 I2I SOP | [Google Doc](https://docs.google.com/document/d/15oAssKRKJKr8jfng4nk0jyXy6ysxYqczd58vL6iorfU) | §5.2.1 B-KV |
| 请求级 Case 排查 Skill / SOP | [Skill](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/SKILL.md) / [Workflow Gates](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/references/workflow-gates.md) / [SQL Playbook](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/references/sql-playbook.md) / [Representative Report](../../../team/04.product-algo/recall-algo/skills/auto-case-attribution/ymal-case-analysis-report.md) | §10.4 |

SOP 快速参考：
- **新加 KNN 队列**：首选 `ads-recall-add-queue`。先确认 Vespa / Embedding / AB 参数存在，再预览 graph DAG、`MergeRecallQueue`、AB 默认值和 Makefile 变更，最后走 RESP Lab 预发测试。队列开关：`knnRecallCfg{queue_name}`（详见 §8.1）。
- **新加 KNN 模型**：首选 `ads-recall-ohmyemb-add-model`。先确认 OhMyEmb 节点字段和 `node_name` 唯一性，再预览 `graph-manager-conf/ohmyemb` YAML，并用 `ads-recall-ohmyemb-debug` 的 `model_conf` 模式测试 embedding 输出（详见 §8.2）。
- **OhMyEmb 日常 debug**：使用 `ads-recall-ohmyemb-debug`，按 `model_conf` / `required_output` / compare 三种模式确认参数，支持 random case、curl 输出和结果分析。
- **查某队列在某个 request 下为什么没召回某个 item**：先按 §10.4 对齐边界，再到 `auto-case-attribution` 的 Skill / Workflow Gates / SQL Playbook 深挖；KB 负责给入口和背景，case 级归因 SOP 统一走这套流程。

### 12.3 Tracker / OKR

| 名称 | 链接 |
|---|---|
| 【Ads Team】One Stop Tracker | [Google Sheet](https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=451255125#gid=451255125) |
| 召回队列命名约定 | [Google Sheet](https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk/edit?gid=65057492#gid=65057492) |
| Product Ads 全量任务等级表 | [Google Sheet](https://docs.google.com/spreadsheets/d/1gPlN8AW4C9u6XQPep64iTsfaLhYYDyhQyV0DAi72RFk/edit?gid=0#gid=0) |
| Recall 团队 OKR | [Google Sheet](https://docs.google.com/spreadsheets/d/1NaFd2L61WLKti4_DLowNBRyxQL5RQU7O7boy5P57pmw/edit?gid=1498984967#gid=1498984967) |

### 12.4 DataSuite / Dashboard

| 资产 | asset_id | 说明 | 对应章节 |
|---|---|---|---|
| Recall Queue AB Monitor | [10570848](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10570848) | 历史 impression 主口径 recall queue 监控表 | §10.1 / §10.2.1 |
| Biz Queue AB Monitor | [10834998](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10834998) | 历史 impression 主口径 biz queue 监控表 | §10.1 / §10.2.1 |
| Adopt / Exclusive 当前 SQL | [11058141](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11058141) | 当前权威 SQL：统一 impression / click / order 三套 item 口径，并按 `reason(stage)` 拆漏斗 | §9.2.2 / §10.1 / §10.2.1 |
| DD Recall Rate | [10755111](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755111) | DD 离线 recall / precision@100 | §10.2.2 |
| YMAL Recall Rate | [10755116](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10755116) | YMAL 离线 recall / precision@100 | §10.2.2 |
| 长序列模型训练调度 | [10917479](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10917479) | 线上模型日常训练迭代（seed→increment→check→eval→release） | §7.3.2 |

Agent 首选：
- 查 Hive / ad-hoc SQL：`sra-ds-sql-query`
- 查 DataSuite asset / workflow / SQL 脚本：`sra-datasuite-crawler`
- 查 Grafana：`sp-grafana`
- 查请求级 case：优先走 `auto-case-attribution`
- 查 OneBI：当前无专门 skill，直接走 dashboard / API；若失败，再回本节手动路径

DataSuite Studio（任务 / workflow 下钻）：
- 任务等级表里的 `DataSuite Workflow Link` 是排查非 KNN 队列离线链路的首选入口。
- 轻量用法：
  1. 先看 workflow 的 node / edge，判断它是“直接产候选”“特征准备”“cache sync / delivery”“blacklist / monitor”中的哪类。
  2. 再看节点详情：
     - shell / SSH 任务：读 `content`
     - Python Spark 任务：读 `pythonSparkConfig.mainResource` 和 `programArgument`
  3. 若脚本或 marker 明显指向 Redis / Vespa / databus 下发，再继续去 §12.5 的 AlgoLab Data Delivery。

OneBI Dashboard（按队列切分）：

| 面板 | 链接 | 用途 | 对应章节 |
|---|---|---|---|
| Recall Rele Log Monitor | [OneBI Dashboard](https://datasuite.shopee.io/dashboard/dashboard/ea3b1440-00f2-47d0-b24c-0b2851c25974/normal?page=1767668504039_184xp) | 按 `Queue id / Exp id / Region / Entrance / Date` 切分 Recall queue 的时序效果；首屏可直接看 impression / click / order / gmv / rev / adopt / exclusive / ctr / cvr 等指标 | §10.1 / §10.2.4 |

Grafana 面板（完整列表见 §10.1 Grafana 子节）：

| 面板 | 链接 | 监控内容 |
|------|------|---------|
| Search Ads Recall Funnel | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/3sprlRpNk?orgId=39) | Search 召回/粗排漏斗 |
| Discovery Ads Recall Funnel | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/KGPn-2cNz?orgId=39) | Discovery 召回漏斗，Snake Merge 前后 |
| Retrieval Service | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/9j91dj8Mz?orgId=39) | Retrieval 服务 QPS/延时/队列级别 |
| Retrieval v3 | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/G66aGJ4Vk?orgId=39) | Vespa/KNN/Embedding/FSE 延时与 QPS |
| KNN Deploy | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/v6Qm6gi4z?orgId=39) | KNN 缓存命中率 |
| OhMyEmb Offline Pipeline | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/pCo2VkPNz?orgId=39) | 离线 pipeline 各阶段延时与错误 |
| Ads Engine Critical Metrics | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/916wkZsVz?orgId=39) | Engine 侧召回响应量 |
| Shop Ads Retrieval | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/B4uzqD9Hz?orgId=39) | Shop Ads 召回量/merge/空率 |
| Live Ads Retrieval | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/qU-y-Wmvk?orgId=39) | Live 场景 SPEX + Vespa 延时 |
| Recall Queue Metrics | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/sX-4O4B4z?orgId=39) | 各队列 picked/final 采纳率 |
| Recall Dependency Monitor | [Grafana](https://monitoring.infra.sz.shopee.io/grafana/d/zvx0F0yVk?orgId=39) | 召回依赖服务健康状态 |

### 12.5 平台入口

| 平台 | 链接 | 用途 | 对应章节 |
|---|---|---|---|
| AB Test Platform (Ads) | [abtest.shopee.io/feature/42](https://abtest.shopee.io/feature/42) | 实验创建、Feature 配置、报表查看 | §8.1 / §8.4 |
| AFP 特征平台 | [algolab.shopee.io/afp](https://algolab.shopee.io/afp/node/list?projectId=11&current=1&pageSize=10&scopeId=12) | Scenario / DAG / Slot 管理 | §6 / §7.4.2 |
| EGO Portal | [ego-portal.mlp.shopee.io](https://ego-portal.mlp.shopee.io/serving/batchModelServing/) | 模型 Serving 管理、版本发布 | §7.3 / §7.4 |
| Self Model Service | [graphmanager.shopee.io](https://graphmanager.shopee.io/selfmodel/front/model-config) | OhMyEmb 节点配置的可选手工辅助入口；agent 主路径优先用 `ads-recall-ohmyemb-add-model` + `ads-recall-ohmyemb-debug` | §8.2 |
| OhMyEmb Offline Monitor | [graphmanager.shopee.io](https://graphmanager.shopee.io/selfmodel/front/grafana-panel) | 离线 embedding 产出监控 | §8.2 |
| AlgoLab Data Delivery | [algolab.shopee.io/datadelivery/data-sinker/task?projectId=11](https://algolab.shopee.io/datadelivery/data-sinker/task?projectId=11) | Data sinker / Redis / Vespa / databus 配送任务入口。推荐用它核对 `Task Type / Data Type / Source Info / Target Info / History`，确认离线产出最终如何下发到线上；常用于非 KNN 队列的后半段链路确认 | §11.3.5 I |
| S&R Release Platform | [release.sra.shopee.io](https://release.sra.shopee.io/template/list) | 在线服务发布 | §8.1 / §8.2 |

Agent 首选 skill：
- Recall 新增模型：`ads-recall-ohmyemb-add-model`
- Recall 新增 KNN / KV 队列：`ads-recall-add-queue`
- OhMyEmb 调试：`ads-recall-ohmyemb-debug`
- AB：`sp-ab`
- AFP：`sra-afp`
- EGO Serving / Online Model：`sra-ego-serving-list`
- EGO Checkpoint：`sra-ego-checkpoint`
- 发布平台：`sra-release`
- Self Model Service：仅作为手工兜底或查看历史配置；新增模型和测试优先使用上面的 Recall skills
- OhMyEmb Offline Monitor：监控查询可直接网页查看；若只是查 Grafana，也可回 `sp-grafana`
- AlgoLab Data Delivery：当前无专门 skill，直接网页/API；若权限受限，返回 project `11` 页面和权限边界即可

### 12.6 代码仓库

| 仓库 | 链接 | 职责 | 对应章节 |
|---|---|---|---|
| paidads-alg | [GitLab](https://git.garena.com/shopee/deep/paidads-alg) | 模型训练代码、离线 pipeline、样本构造 | §5.2 / §6 / §7 |
| graph-manager-conf | [GitLab](https://git.garena.com/shopee/deep/searchads/graph-manager-conf) | 在线 DAG 配置（retrieval/ + ohmyemb/） | §5.2 / §7.4.2 / §7.5 / §8 |
| paidads-recall | [GitLab](https://git.garena.com/shopee/deep/paidads-recall) | Retrieval 服务：召回、过滤、merge 逻辑 | §5.3 / §8 |
| oh-my-embedding | [GitLab](https://git.garena.com/shopee/deep/oh-my-embedding) | OhMyEmb 服务：embedding 推理与 graph version | §7.5 / §8.2 |
| paidads-dd-recall-algo | [GitLab](https://git.garena.com/shopee/deep/paidads-dd-recall-algo) | Extra Embedding 映射表生成（已迁移至 [DataSuite 10390147](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10390147)） | §6.6 |

关键代码入口（详见 §11.1 仓库地图）：
- 训练：[longseq_model_base2.0.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/exp/recall/OnlineU2I/long-seq/longseq_model_base2.0.py)（§7.2）、[Q2Tag2I](https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/recall/ruleBasedRecall/Q2Tag2I/swam/q2tag2i)（§5.2.1 C）
- 在线配置：[recommend_game.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/recommend_game.yaml)（§5.2）、[search_recall.yaml](https://git.garena.com/shopee/deep/searchads/graph-manager-conf/-/blob/master/retrieval/search_recall.yaml)（§5.2）
- 过滤：[search_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/search/search_ads_info_filter.go)（§5.3.2）、[recommend_ads_info_filter.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/recommend/operator/recommend_ads_info_filter.go)（§5.3.2）
- Merge：[snake_merge_filter_op.go](https://git.garena.com/shopee/deep/paidads-recall/-/blob/master/pkg/retrieval/common_operator/snake_merge_filter_op.go)（§5.3.4）
