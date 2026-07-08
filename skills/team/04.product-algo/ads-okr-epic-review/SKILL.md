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

# Ads OKR Epic 评审 / Ads OKR Epic Review

Use this Product Algo team skill to review an existing Ads OKR Epic TD as a KP project document. The review asks whether the Epic can be understood, executed, verified, and managed: structure completeness, problem clarity, `Why Do -> KA -> deliverable -> metric` chain, validation design, rhythm planning, definitions, and KB alignment.

## 快速介绍 / Plain-Language Intro

This skill is an Epic TD health check for Product Algo reviewers and KP owners. It helps people quickly see whether a KP document explains why the work matters, which KAs will be delivered, what artifact each KA produces, how those artifacts can be reviewed, what metrics prove they work, and how execution rhythm is controlled. Use it before boss review, owner review, or batch OKR quality review.

## 核心范围 / Core Scope

This skill does not review implementation details, algorithm formulas, SQL correctness, exact baseline numbers, completed experiment results, offline replay results, or concrete evidence data itself. If a KA needs bidding, algorithm, experiment, data-query, rollout, or platform correctness review, call out the handoff target instead of pretending this skill has completed that review.

Review scope is intentionally narrow: score only the Epic metadata and chapters 一、二、三. Ignore chapter 四 `TRD 文档列表` and chapter 五 `KP 执行与状态` by default. Do not lower scores because chapter 四/五 has missing TRD links, owner, ETA, effort, experiment records, rollout status, key findings, problems, discussion, or next steps. Read chapter 四/五 only when the user explicitly asks for progress, rollout, or execution-status review, or when chapters 一、二、三 explicitly point there for an artifact or validation definition.

Output must be plain enough that a reader can understand the problem without knowing review jargon. For every `Top Fix` or `Fair` reason, write three concrete parts: what is missing, why that missing piece makes execution or review hard, and what artifact / metric concept / analysis direction / experiment rule / definition should be added. Avoid unexplained shorthand such as `固化 gate`, `冻结契约`, `补齐 scope`, or `source-of-truth`; translate it into the real action, such as "说明 TROI/CIR 在这个 KP 里分别是什么意思，以及它们如何影响出价或验证".

Keep the review at Epic TD granularity. Do not require offline replay because replay cost is high and usually belongs to later detailed analysis. Do not require exact physical read fields, table names, units, or field owners when the concept is already known in KB or clearly defined by the Epic. Do not require concrete threshold numbers such as "连续降多少次" or "低 coef 持续多久" when the Epic has the right detection dimensions and says the exact value will be decided by follow-up data analysis. Penalize only when the concept, detection dimension, validation idea, or follow-up analysis method is missing.

## 中文版本维护 / Chinese Companion Files

Every non-Chinese file in this skill must have a human-readable Simplified Chinese companion file next to it:

- `SKILL.md` -> `SKILL.zh-CN.md`
- `references/evidence-loading.md` -> `references/evidence-loading.zh-CN.md`
- `references/review-rubric.md` -> `references/review-rubric.zh-CN.md`

When adding or changing any non-`*.zh-CN.md` file, update its `*.zh-CN.md` companion in the same change. The Chinese version should preserve the same review rules, boundaries, examples, and output contracts. It may use more natural Chinese phrasing, but it must not weaken or contradict the English/source file.

## 默认模式 / Default Mode

Default to single-file deep review. Accept:

- A local `epic-file.md` path.
- A KP identifier such as `O1-KR1-KP1`.
- A GitLab tree URL that can be mapped to a local workspace directory.
- A directory, which switches to lightweight batch mode.

If the user provides no target, ask for one concise input: the Epic file path, KP identifier, GitLab tree URL, or Epic directory.

## 快速开始 / Quick Start

1. Read `references/evidence-loading.md`.
2. Read `references/review-rubric.md`.
3. Locate the target Epic file or batch directory.
4. Read the primary `epic-file.md` or each target KP file.
5. Extract a factual Epic summary from metadata and chapters 一、二、三: Why Do, KA list, claimed deliverables, metrics, validation plan, rhythm or gates, key terms, and cited evidence.
6. Load only the minimum necessary KB: references from metadata and chapters 一、二、三, same-directory context, `master/docs/common` index entries, and relevant read-only skills under `master/skills/common`.
7. Run the eight-item review checklist.
8. For each KA, diagnose necessity, observable artifact, validation method, rhythm, and definition gaps.
9. Output human-readable findings. In batch mode, `Top Fix` must be a concrete next action, and every `Fair` item must explain the missing piece in plain Chinese.

## 审查工作流 / Review Workflow

### Step 1：确认输入 / Confirm Input

- If input is a file path, verify it exists and read it.
- If input is a GitLab tree URL, map it to the local workspace path before reading files.
- If input is a KP identifier, search under `docs/team/00.paid-ads-dev/10.trd-prd-td-list/` for matching Epic files.
- If one KP identifier matches multiple paths, list the candidates and ask the user to choose. Do not guess.
- If input is a directory, find `**/epic-file.md` and use batch mode.
- Do not modify source Epic files unless the user explicitly asks for editing.

### Step 2：抽取事实摘要 / Extract Factual Summary

Extract only what the document says:

- Metadata such as `KP Title`, `KP Type`, `Why Do`, `Deliverable`, and `pic`.
- From chapters 一、二、三 only: KA list, claimed deliverables, metrics, validation plan, rhythm or gates, key terms, references, and open questions.
- From chapters 一、二、三 only: background, scope, acceptance criteria, non-goals, solution idea, implementation outline, risk boundary, and decision rules when present.
- Do not extract chapter 四 `TRD 文档列表` or chapter 五 `KP 执行与状态` as scoring material.

Keep factual summary separate from review judgment. Mark missing fields as `未明确` rather than inferring unsupported content.

### Step 3：加载最小必要知识 / Load Minimum Necessary Knowledge

Follow `references/evidence-loading.md`.

- Read files explicitly cited by metadata or chapters 一、二、三 first.
- Read same-directory context only when it explains the target Epic.
- Use `master/docs/common` through index, README, or clearly named entry files before broad search.
- Use relevant read-only `master/skills/common` KB or QA skills when they help explain terms, business chains, metrics, validation methods, or known Ads concepts.
- Do not follow chapter 四 TRD lists or chapter 五 status tables by default.
- Stop when loaded knowledge is enough to judge definitions, business chain, metric design, validation method, and KB conflicts.

Evidence statements must distinguish `Epic says`, `Evidence says`, and `Reviewer infers`.

### Step 4：检查结构完整 / Review Structure Completeness

Judge whether the Epic has enough structure for readers to understand:

- Goal, background, and scope.
- Why Do and why now.
- KA list and solution shape.
- Validation approach.
- Rhythm, stage order, gates, or validation cadence described in metadata or chapters 一、二、三.
- Non-goals or out-of-scope boundary when relevant.

### Step 5：检查问题与逻辑链路 / Review Problem And Logic Chain

Judge whether the problem is clear and valid, and whether the main chain is traceable:

```text
Why Do -> KA -> observable artifact -> business metric / technical metric / analysis or experiment validation
```

The review should identify where the chain breaks. Do not turn a missing exact baseline value into a blocker when the Epic clearly states how the problem will be measured or analyzed.

### Step 6：逐 KA 诊断交付物 / Diagnose KA Deliverables

Every KA must have a human-observable artifact, such as code, feature, analysis report, configuration plan, experiment design, data contract, rollout judgment, tracking sanity, dashboard, go/no-go conclusion, or documented decision.

Empty verbs such as `分析一下`, `支持一下`, `观察一下`, or `优化一下` are insufficient unless the Epic names the produced artifact and how it will be reviewed.

If a KA deliverable is a skill, the Epic must explain the skill at product-document level: what the skill is used for, who will use it, and what concrete problem it solves. A skill deliverable is not clear enough if it only says "build a diagnosis skill" or "add an analysis skill" without naming the user, trigger scenario, rough input/output, and decision or workflow it enables.

**KP Deliverable structure check** (warning, non-blocking): verify that `交付目标/Deliverable` in KP Metadata contains both `【收益】` and `【执行】` parts. If present, check:
- 【收益】 should contain quantified metrics (numbers, percentages, or absolute values). Flag if purely qualitative.
- 【执行】 should name concrete deliverables (features, frameworks, analysis reports, models). Flag if only vague verbs.
- If the field lacks the 【收益】/【执行】 structure entirely, flag as a structural warning suggesting the owner restructure it.

### Step 7：检查指标与验证设计 / Review Metrics And Validation

- Business metrics must align with the business goal.
- Function or code deliverables need technical metrics proving the artifact works.
- Analysis report or experiment design deliverables need an analysis direction, segmentation, comparison group, observation window, decision rule, or rough experiment design.
- Main business metrics and auxiliary technical metrics are primary.
- Risk metrics are optional unless there is obvious cost, quality, stability, rollback, or metric-definition risk.
- Offline replay is optional and should not be required as the default proof method. Accept feasible alternatives such as historical statistics, sampled case analysis, dashboard observation, small-flow experiment design, or a clear follow-up analysis plan.

### Step 8：检查节奏、定义与输出 / Review Rhythm, Definitions, And Output

- Each KA should have enough rhythm, stage order, or gate description in metadata or chapters 一、二、三 for a reviewer to understand how the work progresses and is validated.
- Do not use chapter 五 owner, ETA, effort, status, or next-step cells for the rhythm score.
- Key terms must be defined by the Epic or supported by KB.
- If KB has a definition, the Epic should cite it or at least not conflict with it.
- If KB has no definition, the Epic should define the term itself.
- Definitions should stay at concept level unless the Epic is explicitly defining a data contract. For an existing concept such as target ROI, it is enough that the Epic uses the known concept consistently; do not ask for the exact serving field, table column, unit, or missing-field behavior just to prove the concept exists.
- For output, translate abstract review words into concrete project actions. Do not write "冻结字段契约"; write "说明这个指标/概念在本 KP 里是什么意思，以及它如何参与判断".
- Output follows `references/review-rubric.md`.

## 批量模式 / Batch Mode

For directory input:

- Review each KP independently with the same eight-item checklist.
- Score only metadata and chapters 一、二、三. Ignore chapter 四 `TRD 文档列表` and chapter 五 `KP 执行与状态` unless the user explicitly asks for those execution details.
- Read primary Epic files first. Load extra KB only when a definition or business-chain issue cannot be judged from the primary Epic core scope and small common KB lookup.
- Produce one compact table with columns: `KP`, `Overall`, `结构`, `问题成立`, `链路`, `验证`, `节奏`, `定义/KB`, `Top Fix`.
- `Top Fix` must name the next document change in concrete terms, not a category label. Bad: `固化验证 gate`; good: `写清楚什么实验结果可以进小流量、什么结果必须回滚`.
- After the table, write 2-4 plain-language sentences per KP explaining what is clear, where the main chain breaks, and why each `Fair` item is Fair.
- A `Fair` explanation must answer: "现在写了什么？还缺什么？不补会导致谁无法判断什么？应该补哪个交付物、指标概念、分析方向、实验规则或哪段定义？"
- Do not answer batch review with only scores or compressed labels.

## 边界 / Boundaries

- Do not modify the source Epic unless the user explicitly asks for editing.
- Do not update GSheet or Google Docs.
- Do not perform write operations through workspace or SRA skills.
- Do not trigger rollout, config changes, experiments, or online actions.
- Do not review code implementation details, algorithm formulas, SQL correctness, model structure, or full experiment significance inside this skill.
- Do not penalize an Epic only because exact baseline values, finished experiment results, offline replay results, SQL outputs, concrete threshold numbers, or concrete evidence data are absent.
- Do not penalize an Epic only because it does not name real read fields, table columns, units, or field owners for a concept that is already established in Ads KB or clearly defined in the Epic.
- Do not turn placeholders into findings when they are about exact values to be filled by later data analysis, such as threshold numbers, observation windows, or coefficient cutoffs. Mark a gap only if the Epic lacks the variables to analyze, the analysis direction, or the decision that the later analysis should support.
- Do not penalize an Epic because chapter 四 `TRD 文档列表` or chapter 五 `KP 执行与状态` is incomplete, stale, or empty.
- Penalize an Epic when it does not say how those facts would be measured, analyzed, or used for validation at a concept and method level.
- Do not load every file under Ads docs. Use the minimum useful KB from core-scope references, local index files, `docs/common`, and relevant read-only common skills.
- Do not fabricate KB or skill support. If no evidence is found, say so.
- Do not hide the issue behind abstract review vocabulary. If a phrase such as `口径`, `gate`, `契约`, `scope`, `guardrail`, or `source-of-truth` is useful, immediately explain it as concepts, metric meanings, analysis dimensions, candidate decision rules, or reviewable artifacts. Do not demand exact field names, exact units, or exact threshold values unless the Epic is specifically defining a data contract or the concept itself is otherwise impossible to understand.

## 参考资料 / References

- [references/evidence-loading.md](references/evidence-loading.md)
- [references/review-rubric.md](references/review-rubric.md)
