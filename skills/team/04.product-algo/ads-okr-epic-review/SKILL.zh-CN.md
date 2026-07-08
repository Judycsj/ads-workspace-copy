---
name: ads-okr-epic-review
description: >
  Product Algo Ads OKR Epic TD review skill (Product Algo Ads OKR Epic TD 评审工具) — reviews existing
  Epic TD / epic-file.md documents as KP project documents for structure completeness,
  problem validity, Why Do to KA traceability, KA deliverable clarity, metric and validation
  design, rhythm planning, definition clarity, and Ads knowledge-base alignment.
  TRIGGER when: user mentions "ads-okr-epic-review", "Epic TD review", "epic review",
  "review epic-file", "审查 epic", "评审 Epic TD", "项目 TD 体检", "why do 到 KA",
  "KA 到交付物", "交付物到指标", "节奏是否清晰", "定义是否清晰", or asks to review an
  Ads OKR Epic TD file.
  DO NOT TRIGGER when: user wants to generate a new Epic TD from scratch (use ads-okr-epic-td),
  generate a progress report (use a dedicated Epic progress-report skill when available),
  or review detailed algorithm/code correctness inside one KA (use a domain TD review skill
  when available).
category: workflow
tags: [ads, okr, epic, td, review, product-algo]
---

# Ads OKR Epic 评审

这个 Product Algo team skill 用来评审已经存在的 Ads OKR Epic TD，把它当成一个 KP 项目文档来检查。评审重点不是“文笔好不好”，而是这个 Epic 是否能被读懂、能被执行、能被验证、能被管理：结构是否完整，问题是否清楚且成立，`Why Do -> KA -> 交付物 -> 指标` 链路是否打通，验证设计和节奏是否清楚，关键定义是否明确，是否和 Ads 知识库一致。

## 快速介绍 / Plain-Language Intro

这个 skill 可以理解成 Product Algo reviewer 和 KP owner 用的 Epic TD 体检工具。它帮助大家快速判断一份 KP 文档有没有讲清楚为什么做、要交付哪些 KA、每个 KA 产出什么交付物、这些交付物怎么被 review、用什么指标证明 work，以及执行节奏怎么管。适合在老板 review、owner review 或批量 OKR 质量检查前使用。

## 核心范围 / Core Scope

这个 skill 不评审实现代码细节、算法公式、SQL 正确性、精确 baseline 数值、已经完成的实验结果、离线 replay 结果，或者证据数据本身。如果某个 KA 需要深入评审 bidding、算法、实验、数据查询、rollout 或平台正确性，只指出应该交给哪个领域 skill 继续看，不要假装这个 skill 已经完成了那部分评审。

默认评审范围很窄：只给 Epic 的元信息和第一、二、三章打分。默认忽略第四章 `TRD 文档列表` 和第五章 `KP 执行与状态`。不要因为第四/五章缺 TRD 链接、owner、ETA、effort、实验记录、rollout 状态、关键结论、问题讨论或 next step 就扣分。只有在用户明确要求看进展、rollout、执行状态，或者第一/二/三章明确引用第四/五章作为交付物或验证定义时，才读取第四/五章。

输出必须让普通读者能看懂，不要让人去猜 review 黑话。每个 `Top Fix` 或 `Fair` 原因都要写清楚三件事：缺什么、为什么这个缺口会让执行或评审变难、应该补哪个交付物 / 指标概念 / 分析方向 / 实验规则 / 定义。不要只写 `固化 gate`、`冻结契约`、`补齐 scope`、`source-of-truth` 这类抽象词；要翻译成真实动作，例如：“说明 TROI/CIR 在这个 KP 里分别是什么意思，以及它们如何影响出价或验证”。

评审粒度停留在 Epic TD 层级。不要默认要求离线 replay，因为 replay 成本高，通常属于后续详细分析。不要在概念已经被 KB 支撑或 Epic 自己定义清楚时，继续要求精确读取字段、表名、单位或字段 owner。不要因为没有写出“连续降多少次”“低 coef 持续多久”这类具体阈值就扣分，只要 Epic 写清楚了检测维度，并说明具体数值会由后续数据分析决定即可。只有当概念、检测维度、验证思路或后续分析方法缺失时，才算问题。

## 中文版本维护

这个 skill 里的每个非中文文件，都必须在同目录有一个给人类阅读的简体中文版本：

- `SKILL.md` -> `SKILL.zh-CN.md`
- `references/evidence-loading.md` -> `references/evidence-loading.zh-CN.md`
- `references/review-rubric.md` -> `references/review-rubric.zh-CN.md`

以后新增或修改任何非 `*.zh-CN.md` 文件时，必须在同一次变更里同步更新对应的 `*.zh-CN.md` 文件。中文版本要保留同样的评审规则、边界、示例和输出契约，可以用更自然的中文表达，但不能削弱或改变源文件的要求。

## 默认模式

默认进行单文件深度评审。可以接受这些输入：

- 本地 `epic-file.md` 路径。
- KP 标识，例如 `O1-KR1-KP1`。
- 可以映射到本地 workspace 的 GitLab tree URL。
- 一个目录；目录输入会切换成轻量批量评审模式。

如果用户没有给目标，简短追问一个输入：Epic 文件路径、KP 标识、GitLab tree URL 或 Epic 目录。

## 快速开始

1. 读取 `references/evidence-loading.md`。
2. 读取 `references/review-rubric.md`。
3. 定位目标 Epic 文件或批量目录。
4. 读取主 `epic-file.md`，或者读取每个目标 KP 文件。
5. 只从元信息和第一、二、三章抽取事实摘要：Why Do、KA 列表、宣称的交付物、指标、验证计划、节奏或 gate、关键名词、引用证据。
6. 只加载最小必要 KB：元信息和第一/二/三章引用的资料、同目录上下文、`master/docs/common` 索引入口，以及 `master/skills/common` 下相关的只读 skill。
7. 按八项 checklist 评审。
8. 逐 KA 诊断必要性、可观察交付物、验证方式、节奏和定义缺口。
9. 输出人能看懂的 review。批量模式下，`Top Fix` 必须是具体下一步动作，每个 `Fair` 都必须用中文说清楚缺什么。

## 审查工作流

### Step 1：确认输入

- 如果输入是文件路径，确认文件存在并读取。
- 如果输入是 GitLab tree URL，先映射到本地 workspace 路径再读文件。
- 如果输入是 KP 标识，在 `docs/team/00.paid-ads-dev/10.trd-prd-td-list/` 下搜索匹配的 Epic 文件。
- 如果一个 KP 标识匹配多个路径，列出候选并让用户选择。不要猜。
- 如果输入是目录，查找 `**/epic-file.md`，使用批量模式。
- 除非用户明确要求编辑，否则不要修改源 Epic 文件。

### Step 2：抽取事实摘要

只抽取文档已经写出的事实：

- 元信息：`KP Title`、`KP Type`、`Why Do`、`Deliverable`、`pic` 等。
- 只看第一、二、三章：KA 列表、宣称的交付物、指标、验证计划、节奏或 gate、关键名词、引用资料和 open question。
- 只看第一、二、三章：背景、范围、验收标准、非目标、方案思路、实现大纲、风险边界、决策规则。
- 不把第四章 `TRD 文档列表` 或第五章 `KP 执行与状态` 当作打分材料。

事实摘要和 review 判断要分开写。缺失字段写 `未明确`，不要自己脑补。

### Step 3：加载最小必要知识

遵循 `references/evidence-loading.md`。

- 优先读取元信息或第一/二/三章明确引用的文件。
- 只有同目录上下文能解释目标 Epic 时才读。
- 通过 index、README 或清楚命名的入口文件使用 `master/docs/common`，不要大范围扫库。
- 使用 `master/skills/common` 下相关只读 KB 或 QA skill，帮助解释术语、业务链路、指标、验证方法或已知 Ads 概念。
- 默认不要顺着第四章 TRD 列表或第五章状态表继续读。
- 当已有知识足够判断定义、业务链路、指标设计、验证方法和 KB 冲突时就停止。

证据表述要区分 `Epic says`、`Evidence says` 和 `Reviewer infers`。

### Step 4：检查结构完整

判断 Epic 是否有足够结构让读者理解：

- 目标、背景和范围。
- Why Do 以及为什么现在要做。
- KA 列表和方案形态。
- 验证方式。
- 元信息或第一/二/三章中的节奏、阶段顺序、gate 或验证 cadence。
- 相关时要有非目标或 out-of-scope 边界。

### Step 5：检查问题与逻辑链路

判断问题是否清楚、成立，以及主链路是否能追踪：

```text
Why Do -> KA -> 可观察交付物 -> 业务指标 / 技术指标 / 分析或实验验证
```

review 要指出链路断在哪里。不要因为缺精确 baseline 数值就当成 blocker，只要 Epic 已经说明问题如何被衡量或分析即可。

### Step 6：逐 KA 诊断交付物

每个 KA 都必须有一个人类可以观察和 review 的交付物，例如代码、功能点、分析报告、配置方案、实验设计、数据契约、rollout 判断、tracking sanity、dashboard、go/no-go 结论或记录下来的决策。

`分析一下`、`支持一下`、`观察一下`、`优化一下` 这类空动词不够，除非 Epic 同时说明会产出什么，以及 reviewer 怎么检查。

如果某个 KA 的交付物是一个 skill，Epic 必须用产品文档的粒度说明这个 skill：它做什么用，谁来用，解决什么具体问题。只写“建设一个诊断 skill”或“补一个分析 skill”不够，还要说明使用场景、大致输入/输出，以及它能帮助使用者做出什么判断或完成什么工作流。

### Step 7：检查指标与验证设计

- 业务指标必须对齐业务目标。
- 功能或代码类交付物需要技术指标证明这个东西确实 work。
- 分析报告或实验设计类交付物需要有分析方向、切分维度、对照组、观察窗口、决策规则或粗略实验设计。
- 主业务指标和辅助技术指标是主要内容。
- 风险指标是可选项；只有在成本、质量、稳定性、回滚或指标定义风险明显时才要求观察。
- 离线 replay 是可选项，不应默认要求。可以接受历史统计、抽样 case 分析、dashboard 观察、小流量实验设计或清楚的后续分析计划。

### Step 8：检查节奏、定义与输出

- 每个 KA 应该在元信息或第一/二/三章里有足够的节奏、阶段顺序或 gate 描述，让 reviewer 知道工作怎么推进、怎么验证。
- 不要用第五章的 owner、ETA、effort、status 或 next-step 单元格给节奏打分。
- 关键名词必须由 Epic 定义，或者能被 KB 支撑。
- 如果 KB 里有定义，Epic 应该引用它，或者至少不冲突。
- 如果 KB 没有定义，Epic 应该自己定义。
- 定义停留在概念层级即可，除非 Epic 明确在定义数据契约。对于 target ROI 这类已有概念，只要 Epic 一致使用即可，不要为了证明概念存在而要求 exact serving field、table column、unit 或 missing-field behavior。
- 输出时，把抽象 review 词翻译成具体项目动作。不要写“冻结字段契约”，要写“说明这个指标/概念在本 KP 里是什么意思，以及它如何参与判断”。
- 输出遵循 `references/review-rubric.md`。

## 批量模式

目录输入时：

- 对每个 KP 独立执行同一套八项 checklist。
- 只给元信息和第一、二、三章打分。忽略第四章 `TRD 文档列表` 和第五章 `KP 执行与状态`，除非用户明确要求看执行细节。
- 优先读取主 Epic 文件。只有当关键定义或业务链路无法从核心范围和少量 common KB 判断时，才加载额外 KB。
- 输出一张紧凑表格，列为：`KP`、`Overall`、`结构`、`问题成立`、`链路`、`验证`、`节奏`、`定义/KB`、`Top Fix`。
- `Top Fix` 必须写具体下一步文档修改，不要只写分类标签。坏例子：`固化验证 gate`；好例子：`写清楚什么实验结果可以进小流量、什么结果必须回滚`。
- 表格后每个 KP 写 2-4 句人话，说明哪里清楚、主链路哪里断、为什么每个 `Fair` 是 Fair。
- `Fair` 解释必须回答：“现在写了什么？还缺什么？不补会导致谁无法判断什么？应该补哪个交付物、指标概念、分析方向、实验规则或哪段定义？”
- 不要只输出分数表或压缩标签。

## 边界

- 不要修改源 Epic，除非用户明确要求编辑。
- 不要更新 GSheet 或 Google Docs。
- 不要通过 workspace 或 SRA skill 执行写操作。
- 不要触发 rollout、配置变更、实验或线上动作。
- 不要在这个 skill 里评审代码实现细节、算法公式、SQL 正确性、模型结构或完整实验显著性。
- 不要仅仅因为没有精确 baseline、已完成实验结果、离线 replay、SQL 输出、具体阈值或具体证据数据而扣分。
- 不要仅仅因为一个已有 Ads 概念没有写真实读取字段、表字段、单位或字段 owner 而扣分。
- 不要把后续数据分析要填的占位符当成问题，例如阈值数字、观察窗口或 coef cutoffs。只有当 Epic 没有写清变量、分析方向或后续分析要支持的决策时，才标缺口。
- 不要因为第四章 `TRD 文档列表` 或第五章 `KP 执行与状态` 不完整、过期或为空而扣分。
- 当 Epic 没说这些事实要怎么衡量、分析或用于验证时，才应该扣分。
- 不要读取 Ads docs 下所有文件。只使用核心范围引用、本地 index、`docs/common` 和相关只读 common skill 中最小有用 KB。
- 不要伪造 KB 或 skill 支撑。如果没找到证据，就说没找到。
- 不要把问题藏在抽象 review 词里。如果用了 `口径`、`gate`、`契约`、`scope`、`guardrail`、`source-of-truth` 这类词，必须在同一句解释成概念、指标含义、分析维度、候选决策规则或可 review 的交付物。除非 Epic 专门在定义数据契约，或者概念本身无法理解，否则不要要求 exact field、exact unit 或 exact threshold。

## 参考资料

- [references/evidence-loading.md](references/evidence-loading.md)
- [references/evidence-loading.zh-CN.md](references/evidence-loading.zh-CN.md)
- [references/review-rubric.md](references/review-rubric.md)
- [references/review-rubric.zh-CN.md](references/review-rubric.zh-CN.md)
