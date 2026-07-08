# Ads OKR Epic Project Review Rubric

Use this rubric to judge whether an Epic TD can work as a KP project document. The review should identify where the project chain breaks: why to do it, what KA solves it, what observable artifact will be delivered, and what metrics or validation method prove it works.

This rubric reviews document quality, project logic, validation design, and knowledge alignment. It does not review code implementation details, exact baseline values, finished experiment results, offline replay results, SQL correctness, model formulas, or algorithm correctness.

## Core Review Scope

Score only Epic metadata and chapters 一、二、三. Ignore chapter 四 `TRD 文档列表` and chapter 五 `KP 执行与状态` by default.

Do not lower scores because chapter 四/五 has missing or stale TRD links, owner, ETA, effort, experiment records, rollout status, key findings, problems, discussion, or next steps. Read those sections only when the user explicitly asks for progress / rollout / execution-status review, or when chapters 一、二、三 explicitly refer to them for an artifact or validation definition.

## Review Checklist

| Item | What To Check | Good | Fair | Weak |
| --- | --- | --- | --- | --- |
| 结构完整 | Metadata and chapters 一、二、三 include background, Why Do, KA, solution, validation, rhythm or gates, and non-goals when relevant. | Reader can understand the project without guessing. | One core section is thin or scattered but recoverable. | Core sections are missing or impossible to map. |
| 问题清晰且成立 | The problem is explicit, current, tied to business impact, and has a measurement or analysis method. | Problem, urgency, impact, and proof method are clear. | Direction is plausible but proof method or impact needs sharpening. | Problem is vague, unsupported, or disconnected from business goal. |
| Why Do -> KA | Every KA is necessary to solve the stated Why Do. | KA list is traceable and ordered. | Some KA is plausible but dependency or necessity is unclear. | KA reads like unrelated tasks. |
| KA -> 交付物 | Every KA has a human-observable artifact. If the artifact is a skill, the Epic explains what it is used for, who uses it, and what problem it solves. | Artifact is concrete and reviewable. Skill deliverables have clear user, use case, problem, and rough input/output. | Artifact exists but acceptance boundary is fuzzy, or a skill deliverable lacks user, use case, problem, or rough input/output. | KA uses empty verbs without a reviewable artifact, or names a skill without explaining what it does and who it helps. |
| 交付物 -> 指标 | Business metrics align with business goal; technical metrics prove function/code artifacts work; analysis/experiment artifacts have direction or design. | Metrics or validation methods close the loop. | Main direction is present but one metric, technical proof, or design outline is thin. | Cannot tell how delivery proves impact or workability. |
| 验证思路 | Main business metrics and auxiliary technical metrics are clear; risk metrics are included when risk is obvious. | Validation can decide go/no-go. | Primary metric exists but auxiliary proof, grouping, window, or risk observation is thin. | Validation is slogan-level or missing. |
| 节奏规划 | Metadata or chapters 一、二、三 explain stage order, validation cadence, gates, or decision rhythm when staged execution matters. | Reader can tell how work advances and what gate proves each stage. | Direction is present but one KA's gate, order, or cadence is fuzzy. | Core chapters make staged claims but give no order, gate, cadence, or decision rule. |
| 定义与 KB 对齐 | Key terms are defined in Epic or supported by KB, and no KB conflict is found. | Terms and assumptions are clear and consistent. | One term or assumption needs definition or citation. | Critical terms are undefined or conflict with KB. |

## Score Labels

- `Good`: Readers can clearly know why to do it, what will be done, what artifact will be delivered, how it will be validated, and what rhythm or gate manages progress.
- `Fair`: Direction is understandable, but one chain segment needs clearer definition, artifact, metric design, analysis direction, experiment design, or rhythm.
- `Weak`: Readers still cannot tell whether the problem is valid, whether KA is necessary, what artifact is delivered, or how workability and impact will be validated.

## Plain-Language Output Rules

The review must be understandable without decoding reviewer shorthand. For every `Top Fix` and every `Fair` explanation, use concrete project language:

```text
What is missing
-> why it blocks review / execution / go-no-go judgment
-> what artifact, metric concept, analysis direction, experiment rule, dashboard, or definition should be added
```

Translate abstract terms instead of leaving them raw:

| Avoid as the whole explanation | Say this instead |
| --- | --- |
| 固化验证 gate | 写清楚什么实验结果可以进小流量、什么结果必须回滚 |
| 冻结字段契约 | 说明这个指标/概念在本 KP 里是什么意思，以及它如何参与判断 |
| 固化口径 | 写清楚这个指标代表什么、怎么大致统计、用来支持哪个判断 |
| 收敛 scope | 写清楚第一期做什么、哪些方案放到后续 |
| 补齐 guardrail | 写清楚哪些指标不能明显变差，以及变差后要观察、回滚还是继续分析 |
| source-of-truth 待确认 | 说明这个概念引用现有 KB 还是本 Epic 自己定义，谁负责补充说明 |

Examples:

- Bad: `固化 low-support 误伤阈值和 overlay gate`
- Good: `说明会从哪些维度判断低曝光候选，以及怎么观察是否误伤赚钱广告；具体阈值可以后续数据分析确定`
- Bad: `冻结 TROI/CIR 字段契约`
- Good: `说明 TROI/CIR 在这个 KP 里分别是什么意思，是沿用现有概念还是新定义；如果是新定义，补计算思路`

Keep the requested fix at Epic TD granularity. Do not ask for offline replay by default. Do not ask for physical read fields, exact units, table columns, or field owners when the Epic is only using an existing Ads concept. Do not ask for exact threshold numbers when the Epic already names the dimensions to analyze and leaves the number to later data analysis. Ask for the missing concept, analysis dimension, validation method, or follow-up decision instead.

## Overall Judgment

- `清晰`: The eight checklist items are basically closed, with only minor wording or citation issues.
- `部分清晰`: The direction can move forward, but key Fair items require document, definition, artifact, validation, or rhythm updates.
- `不清晰`: The problem is invalid or unclear, KA is task-list-like, core deliverables are vague, metrics cannot prove workability, or core-chapter rhythm / gates are unmanageable.

Upgrade rules:

- Structure complete but logic chain broken cannot be `清晰`.
- A core KA without a human-observable artifact makes the overall judgment at least `部分清晰`.
- If the core KA artifact is missing and the project cannot be reviewed, the overall judgment should be `不清晰`.
- Missing exact baseline values, unfinished experiments, absent offline replay, concrete threshold numbers, or absent SQL outputs do not by themselves lower the overall judgment when the metric design and statistics method are clear.

## Severity Labels

- `Blocker`: Missing Why Do, invalid problem, core KA without observable artifact, no way to validate workability, or fully unmanageable core-chapter rhythm / gates.
- `Major`: Direction is valid but a key definition, KA artifact, validation metric, analysis / experiment design, or core-chapter rhythm / gate is missing.
- `Minor`: Wording, citation, terminology, or small clarification issue that does not block project execution.

## Logic Chain Review

Review this chain explicitly:

```text
Why Do
  -> KA
  -> human-observable artifact
  -> business metric / technical metric / analysis or experiment validation
```

Report the first broken point. Do not bury the main problem under a long list of minor wording issues.

### Problem Validity

The Epic should answer:

- What problem, opportunity, or gap exists now.
- Why it matters to the KR or business goal.
- Why this quarter is a reasonable time to do it.
- How the problem will be measured, analyzed, or proven.
- Which scope is excluded when that boundary matters.

The Epic does not need to paste the exact baseline number, replay result, or final threshold number into the document. It must describe the statistics or evidence supplement method clearly enough that a reader knows how the claim would be checked.

### Why Do To KA

Each KA should be a necessary part of solving the stated Why Do:

- Every important problem gap has at least one KA.
- Every KA has a reason to exist.
- KAs are actions or delivery stages, not metrics copied from the deliverable.
- KAs have logical order or dependency when order matters.
- The KA set fits one KP instead of several unrelated projects.

### KA To Artifact

Each KA must name the artifact that a human reviewer can observe. Valid artifacts include:

- Code or feature.
- Analysis report.
- Configuration plan.
- Experiment design.
- Data contract.
- Rollout judgment.
- Tracking sanity or dashboard.
- Go/no-go conclusion.
- Documented decision.
- Skill, when the Epic also explains what the skill is used for, who uses it, what concrete problem it solves, rough input/output, and what decision or workflow it enables.

Invalid KA wording:

- `分析一下` without report direction or expected decision.
- `支持一下` without supported feature, config, contract, or decision.
- `观察一下` without metric, window, owner, and expected action.
- `优化一下` without target artifact and validation method.
- `建设一个诊断 skill` without explaining who uses the skill, in what scenario, with what input/output, and what problem or decision it helps with.

### Artifact To Metric

Check two layers:

- Business metrics answer whether the Epic serves the business goal.
- Technical metrics are required only for function or code artifacts. They should prove that the delivered function works, such as coverage, latency, trigger rate, matching rate, calibration, data freshness, contract completeness, stability, or rollout health.
- Technical metrics can be defined at concept level in the Epic TD. Do not require exact serving fields, data-table columns, units, or missing-field behavior unless the KA deliverable itself is a data contract or metric-definition change.

For analysis reports and experiment designs, do not force technical metrics. Require analysis direction, segmentation, comparison group, observation window, decision rule, or rough experiment design instead.

### Validation Design

Validation should make the go/no-go decision understandable:

- Main business metrics are primary.
- Auxiliary technical metrics support function or code workability.
- Analysis / experiment deliverables need a clear analysis direction or experiment design.
- Offline replay is optional because it can be expensive. Do not mark a TD down only because it lacks replay. Ask instead whether it gives a feasible way to validate the idea, such as historical statistics, case analysis, dashboard observation, small-flow experiment design, or a follow-up data-analysis plan.
- Risk metrics are optional.
- When the Epic has obvious cost, quality, stability, rollback, or metric-definition risk, ask for risk observation.

## Rhythm Review

Review rhythm only from metadata and chapters 一、二、三. Do not use chapter 五 owner, ETA, effort, phase status, or next-step cells for this score.

Each KA should have enough of the following when staged execution matters:

- Stage order or dependency.
- Validation cadence or observation window.
- Gate or decision rule.
- Expected reviewable artifact at each stage.

Do not require every date to be perfect. Mark a gap when metadata and chapters 一、二、三 claim staged delivery, rollout, or validation but the reader cannot tell what state should be reached before moving on.

## Definition And KB Alignment

Check key names and assumptions:

- If a key term is defined in KB, the Epic should cite it or at least not conflict with it.
- If KB has no definition, the Epic should define the term itself.
- If the Epic's metric meaning or business chain conflicts with KB, mark a gap.
- If a term is well known in KB and used consistently, do not require the Epic to duplicate the full definition.

Use KB to judge concept correctness and business-chain alignment. Do not use KB as a reason to demand completed baseline data, offline replay, real read fields, exact units, or final threshold numbers.

## Single-File Output Contract

Use this structure for one Epic TD:

```markdown
# Epic TD Review: {KP Title}

## 0. Review Scope

- 本次只审元信息和第一/二/三章。
- 四、TRD 文档列表：忽略，不因 TRD 链接缺失或未更新扣分。
- 五、KP 执行与状态：忽略，不因 owner、ETA、effort、实验记录、rollout、结论、问题讨论、next step 缺失扣分。

## 1. 一句话结论

- 结论：清晰 / 部分清晰 / 不清晰
- 最主要问题：{一句话说明最大断点}
- 建议动作：{用人话说明下一步补什么；不要只写“固化 gate / 冻结契约 / 补 scope”}

## 2. Review Checklist

| 项目 | 评分 | 具体问题 | 建议 |
| --- | --- | --- | --- |
| 结构完整 | Good/Fair/Weak | ... | ... |
| 问题清晰且成立 | Good/Fair/Weak | ... | ... |
| Why Do -> KA | Good/Fair/Weak | ... | ... |
| KA -> 交付物 | Good/Fair/Weak | ... | ... |
| 交付物 -> 指标 | Good/Fair/Weak | ... | ... |
| 验证思路 | Good/Fair/Weak | ... | ... |
| 节奏规划 | Good/Fair/Weak | ... | ... |
| 定义与 KB 对齐 | Good/Fair/Weak | ... | ... |

## 3. 逻辑链路检查

Why Do
  -> KA
  -> 可观察交付物
  -> 业务指标 / 技术指标 / 分析或实验验证方式

## 4. KA 逐项诊断

| KA | 是否必要 | 可观察交付物 | 验证方式 | 节奏 | 结论 |
| --- | --- | --- | --- | --- | --- |

## 5. 指标与验证设计

| 类型 | 指标/验证方式 | 用途 | 是否足够 |
| --- | --- | --- | --- |
| 业务指标 | ... | 对齐业务目标 | ... |
| 技术指标 | ... | 证明功能/代码类 KA work | ... |
| 分析/实验设计 | ... | 证明分析或实验类 KA 有方向 | ... |
| 风险指标（可选） | ... | 观察副作用 | ... |

## 6. 定义与 KB 对齐

| 关键名词 | Epic 是否定义 | KB 是否支持 | 缺口 |
| --- | --- | --- | --- |

## 7. 必须补什么

1. {补什么具体材料 / 指标概念 / 分析方向 / 实验规则 / 定义}
2. ...
3. ...
```

Write in plain Chinese. Explain judgment in concrete project language instead of compressed labels. A user should understand the issue without rereading the full Epic. If you use a technical term such as `gate`, `guardrail`, `口径`, `字段契约`, or `source-of-truth`, explain it in the same sentence. Prefer concept-level fixes over demanding exact fields, units, replay results, or final thresholds.

## Batch Output Contract

Use this structure for multiple KP files:

```markdown
## Epic Review 批量摘要

| KP | Overall | 结构 | 问题成立 | 链路 | 验证 | 节奏 | 定义/KB | Top Fix |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

### KP1 {title}
清楚的点：...
主要断点：...
为什么是 Fair：现在写了什么；还缺什么；不补会导致谁无法判断什么。
下一步：补哪个交付物、指标概念、分析方向、实验规则或哪段定义。
```

Batch output requirements:

- Write 2-4 plain-language sentences per KP after the table.
- Explain why every `Fair` item is Fair.
- Name the concrete artifact, metric concept, analysis direction, definition, or rhythm item that is missing or fuzzy.
- `Top Fix` must be a concrete next action that a KP owner can apply directly. Do not use only category labels such as `补验证`, `固化口径`, `冻结契约`, or `收敛 scope`.
- For each `Fair`, explicitly say what is missing and why that makes review or execution hard. Good shape: `现在有 X，但缺 Y；不补 Y，就无法判断 Z；建议补 A。`
- Explain scores from metadata and chapters 一、二、三 only; do not cite chapter 四/五 status gaps as Fair reasons.
- Do not output only a score table.
- The user must be able to understand the concrete Fair point of each KP without rereading the source Epic.

## Review Anti-Patterns

Avoid these mistakes:

- Marking `Weak` only because exact baseline values are absent.
- Marking `Fair` or `Weak` only because replay is absent.
- Requiring exact physical read fields, units, table columns, or field owners when the Epic only needs to use an existing concept such as target ROI.
- Requiring final threshold numbers such as "连续降多少次" or "低 coef 持续多久" when the Epic has a placeholder and states that data analysis will decide the value.
- Asking for finished experiment results when the Epic only needs a clear experiment or validation design.
- Reviewing code, SQL, algorithm formulas, or model internals inside this skill.
- Treating `分析一下`, `支持一下`, `观察一下`, or `优化一下` as clear KA deliverables.
- Saying "Fair" without explaining the concrete broken link in human-readable language.
- Writing `Top Fix` as abstract shorthand, such as `固化验证 gate`, `冻结字段契约`, `补齐 guardrail`, or `收敛 scope`, without translating it into concept definitions, analysis dimensions, artifacts, validation methods, or decision rules.
- Lowering scores because chapter 四 `TRD 文档列表` or chapter 五 `KP 执行与状态` has missing links, status, ETA, effort, rollout records, findings, problems, or next steps.
