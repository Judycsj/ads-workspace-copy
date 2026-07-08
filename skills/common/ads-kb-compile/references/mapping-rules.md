# Section-to-File Mapping Rules/章节到文件映射规则

> This reference defines how input content maps to target files referenced in `docs/common/index-synthesis.md`.
> Core Knowledge paths are relative to `docs/common/core-knowledge/`.

---

## Write Scope/写入范围

**默认规则**：`index-synthesis.md` Section 2 中引用的所有文件均在写入范围内。
仅当文件/目录在下方 **Excluded Targets** 表中被明确列出时，才排除。

### Business Knowledge Hierarchy/业务知识层级关系

业务知识分为两层，入库时需注意内容定位以避免信息重叠：

| 层级 | 对应类别 | 职责 | 写什么 | 不写什么 |
|------|---------|------|--------|---------|
| **总览层/Overview** | 核心知识文档 (`docs/common/core-knowledge/`) | 是什么、为什么、核心概念与关系 | 定义、原理、模块关系、设计决策、关键指标含义 | 完整字段列表、具体 API 参数、逐行配置 |
| **详细层/Detail** | 数据表参考 (`docs/common/datamap/`) | 完整字段/SQL 模板 | 表结构、字段说明、SQL 示例 | 业务概念解释（引用总览层） |
| **详细层/Detail** | 代码仓库 README (`docs/common/readme/`) | 完整 API/配置/部署细节 | 接口签名、代码结构、部署拓扑、运维指南 | 算法原理（引用总览层） |
| **知识层/Knowledge** | DPM 核心知识 (`docs/team/20.paid-ads-dpm/ads_knowledge_base/`) | DPM 模块/项目专项知识 | 埋点规范、计费逻辑、归因细节、对账流程 | 系统架构全景（引用总览层） |
| **指南层/Guide** | How-Tos (`docs/team/00.paid-ads-dev/04.how-tos/`) | AI Agent 使用指南 | 工作流、使用示例、操作步骤 | 底层实现细节 |
| **规范层/SOP** | Team Info & SOPs (`docs/team/00.paid-ads-dev/01-03/`) | 团队组织与流程规范 | 人员信息、流程规范、值班安排 | 技术实现 |

### Compile Dispatch Rules/入库分工规则

1. **概念性内容**（定义、原理、模块关系、设计决策）→ 写入对应层级的目标文件
2. **实现细节**（完整字段、API 参数、配置项、SQL）→ 若目标在排除列表中则 **跳过不写入**，在报告中提醒用户使用对应工具；否则按目标文件类型写入
3. **混合内容** → 根据目标文件所属层级决定：概念层仅提取概念部分，知识/指南/规范层可写入更多细节
4. **判断标准**：如果删掉这段内容，读者还能理解「这个东西是什么、为什么这样设计」→ 属于详细层，跳过；否则属于目标层，写入

---

## Excluded Targets/排除目标

> 以下目录在本 skill 写入范围外，各有专属更新工具。
> **判断规则**：只有在此表中明确列出的才排除；未列出 = 可写。

| Scope | Path Pattern | Reason | Alternative Tool |
|-------|-------------|--------|-----------------|
| Section 2.3 | `docs/common/readme/**` | 由代码分析自动生成 | `ads-readme-generate` |
| Section 2.4 | `docs/common/datamap/**` | 由 Hive 元数据自动构建 | `sra-table-info-query` |

> **Note**: DPM (2.2)、How-Tos (2.5)、SOPs (2.6) 均未排除，属于可写范围。
> 如需将某个文件或 Section 恢复为排除/可写，增删对应行即可。

---

## Mapping Table/映射表

> 以下映射表适用于 Core Knowledge (Section 2.1)。路径相对于 `docs/common/core-knowledge/`。

| Section | Domain Keywords (EN) | 领域关键词 (ZH) | Target File |
|---|---|---|---|
| §1.1 | preface, reading guide | 前言, 阅读指南 | `01.ads-overview/01.preface.md` |
| §1.2 | online advertising, metrics, attribution, ecosystem | 在线广告基础, 指标, 归因 | `01.ads-overview/02.online-advertising-fundamentals.md` |
| §1.3 | system pipeline, module overview | 系统流水线, 模块概览 | `01.ads-overview/03.system-pipeline-modules.md` |
| §1.4 | strategy mechanisms, bidding basics, blending, billing basics | 策略机制, 出价基础, 混排, 计费基础 | `01.ads-overview/04.strategy-mechanisms.md` |
| §1.5 | e-commerce, business characteristics, innovation | 电商广告, 业务特征, 创新 | `01.ads-overview/05.ecommerce-business-characteristics.md` |
| §1.6 | Shopee paid ads, business overview, ad types | Shopee付费广告, 业务概览, 广告类型 | `01.ads-overview/06.shopee-paid-ads-overview.md` |
| §2.1 | recall, supply strategy, queue, candidate | 召回, 供给策略, 队列, 候选集 | `02.ads-strategy/01.recall-and-supply-strategy.md` |
| §2.2 | CXR, pGMV, model, calibration, UniCR, CTR, CVR, feature | CXR, pGMV, 模型, 校准, 特征 | `02.ads-strategy/02.cxr-pgmv-models-and-calibration.md` |
| §2.3 | bidding algorithm, OCPX, Bid2X, BEM, environment model, GmvMax | 出价算法, 出价产品, 环境模型 | `02.ads-strategy/03.bidding-products-and-algorithms.md` |
| §2.4 | traffic, pacing, billing, boost, blend, deduction | 流量策略, pacing, 计费, 扶持, 混排, 扣费 | `02.ads-strategy/04.traffic-strategy-and-billing.md` |
| §2.5 | voucher, uplift, ROI3, ROI4, smart voucher | 优惠券, uplift, 智能券 | `02.ads-strategy/05.ads-smart-voucher.md` |
| §2.6 | advertiser strategy, subsidy, managed mode, agent | 广告主策略, 补贴, 托管模式 | `02.ads-strategy/06.advertiser-strategy.md` |
| §3.1 | system architecture, repo list, service overview | 系统架构, 仓库列表, 服务概览 | `03.ads-engine/01.system-architecture-overview.md` |
| §3.2 | ads engine, API interface | 广告引擎, API接口 | `03.ads-engine/02.ads-engine.md` |
| §3.3 | recall service, ads-recall | 召回服务 | `03.ads-engine/03.ads-recall-service.md` |
| §3.4 | bidding service, online-bidding | 出价服务 | `03.ads-engine/04.ads-bidding-service.md` |
| §3.5 | ads index, AdsInfo, indexer | 广告索引, AdsInfo, 索引器 | `03.ads-engine/05.ads-index.md` |
| §3.6 | ads data, data pipeline, data service | 广告数据, 数据链路, 数据服务 | `03.ads-engine/06.ads-data.md` |
| §4.1 | platform frontend, seller center, PAS | 投放平台前端, 卖家中心 | `04.ads-platform/01.platform-frontend.md` |
| §4.2 | platform backend, marketing API | 投放平台后端, 营销API | `04.ads-platform/02.platform-backend.md` |
| §5.1 | data warehouse, table hierarchy, ODS, DWD, DWS, DIM, ADS, naming convention | 数仓, 分层, 命名规范, 核心表 | `05.ads-data/01.data-warehouse-overview.md` |
| §5.2 | dimension, metric, CTR, CVR, CPC, ROAS, take rate, impression, click, order | 维度, 指标, 转化率, 费效比 | `05.ads-data/02.key-dimensions-and-metrics.md` |
| §5.3 | tracking, attribution, OA, TMS, direct order, broad order | 埋点, 归因, 直接订单, 广泛订单 | `05.ads-data/03.tracking-and-attribution.md` |
| §5.4 | billing, deduction, topup, revenue, translog, rebate | 计费, 扣费, 充值, 收入, 赔付 | `05.ads-data/04.billing-and-deduction.md` |
| §5.5 | seller report, data delivery, GMV reconciliation, take rate analysis | 卖家报表, 数据交付, GMV 对账 | `05.ads-data/05.seller-reporting.md` |

### Dynamic Index-Based Mapping/动态索引映射

对于 index-synthesis Section 2.2-2.6 的文件，**不使用**上方关键词匹配表。
Skill 在运行时读取 `index-synthesis.md` 对应 Section 的表格，直接按 File Path 列解析目标文件路径。

映射逻辑：
1. 读取 `index-synthesis.md` Section 2 全部子表的 File Path 列
2. 将输入文件路径或内容主题与 index 中的文件条目匹配
3. 若输入文件本身就是 index 中某行的目标文件 → 直接定位
4. 若输入内容需要映射到非 core-knowledge 的目标 → 按 File Path 列中的路径定位

---

## Matching Algorithm/匹配算法

### Priority Order/优先级

1. **Explicit section reference**: Input contains `§X.Y` or `Section X.Y` → direct match (仅适用于 Core Knowledge §1.1-§5.5)
2. **File path match**: Input file path matches or is an index-referenced file → direct target (适用于所有 Section)
3. **Heading match**: Input H2/H3 heading text matches or is a subset of a target file's H2 heading
4. **Keyword match**: Count domain keyword hits per section; rank by hit count; top match wins (仅适用于 Core Knowledge)
5. **User disambiguation**: If top 2+ candidates have similar keyword hit counts, present them via `AskUserQuestion`

### Multi-Section Input/多章节输入

If input covers multiple sections (e.g., a TRD touching both recall and bidding):
1. Split input by H2/H3 boundaries
2. Map each segment independently
3. Present the full mapping to the user for confirmation before proceeding

### Bilingual File Pairing/双语文件配对

When updating a file, check for and update its bilingual counterpart:
- Core Knowledge: `.md` ↔ `.zh-CN.md`（同目录）
- DPM: `_en.md` ↔ `_cn.md`（同目录，部分文件仅单语）
- How-Tos: `.EN.md` ↔ `.md`（同目录）
- SOPs: `.md` ↔ `.zh-CN.md`（同目录，部分文件仅单语）

若目标文件没有对应的双语文件 → 跳过翻译步骤。

---

## Target Type Adaptation/目标类型适配

不同 index Section 的文件结构不同，合并时需适配：

| Index Section | Target Type | H2 Rule | Bilingual Convention | Notes |
|--------------|-------------|---------|---------------------|-------|
| 2.1 Core Knowledge | Atomic Note | Single H2 per file | `.md` + `.zh-CN.md` | 标准合并，关键词匹配 |
| 2.2 DPM Knowledge | Module/Project doc | Multiple H2 allowed | `_en.md` / `_cn.md` | 遵循已有标题结构 |
| 2.5 How-Tos | Guide doc | Multiple H2 allowed | `.EN.md` + `.md` | 遵循已有标题结构 |
| 2.6 Team Info & SOPs | Process doc | Multiple H2 allowed | `.md` + `.zh-CN.md`（部分单语） | 仅更新事实性内容 |
