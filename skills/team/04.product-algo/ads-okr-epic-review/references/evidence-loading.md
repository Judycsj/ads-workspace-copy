# Evidence And KB Loading For Epic Project Review

Use this reference to load enough knowledge for an Ads OKR Epic TD review without turning the task into a repo audit, data audit, or implementation review.

The goal is not to prove concrete baseline numbers, offline replay results, exact data fields, or final threshold values. The goal is to check whether the Epic's structure, definitions, logic chain, deliverables, metric design, validation plan, and rhythm are grounded in the minimum necessary Ads knowledge.

Review scope is metadata plus chapters 一、二、三 only. Chapter 四 `TRD 文档列表` and chapter 五 `KP 执行与状态` are execution appendices for this skill: ignore them for scoring and do not follow their links by default.

## Target Resolution

### Local File Path

If the user provides a file path:

1. Confirm the file exists.
2. Prefer files named `epic-file.md`.
3. If the file is another Markdown document, continue only if the user clearly intends it as the target Epic.

### KP Identifier

If the user provides a KP identifier such as `O1-KR1-KP1`:

1. Normalize case for matching.
2. Search under `docs/team/00.paid-ads-dev/10.trd-prd-td-list/`.
3. Match directory names, file names, and Epic headings.
4. If exactly one target matches, use it.
5. If multiple files match, list the candidate paths and ask the user to choose.

Suggested command:

```bash
find docs/team/00.paid-ads-dev/10.trd-prd-td-list -path "*/epic-file.md" -print | rg -i "o1|kr1|kp1"
```

Replace the final pattern with the actual objective, KR, and KP terms.

### GitLab Tree URL

If the user provides a GitLab tree URL:

1. Map repository root `https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/` to the local `ads-workspace/` root.
2. Preserve the path suffix after `master/`.
3. Treat the mapped local path as a directory or file target.
4. If the path does not exist locally, say so and ask for a local path or an updated checkout.

### Directory Input

If the user provides a directory:

1. Treat it as batch mode.
2. Find primary Epic files under the directory.
3. Prefer `epic-file.md`; if the current OKR directory uses one Markdown file per KP, read those KP Markdown files directly.
4. Do not load sibling `resource/`, CSV, xlsx, images, or external platform data by default.

Suggested command:

```bash
find docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1 -name "*.md" -print | sort
```

## Loading Order

Load knowledge in this order:

1. Read the primary Epic TD file.
2. Read files explicitly linked or referenced by metadata or chapters 一、二、三.
3. Read same-directory context only when it explains metadata or chapters 一、二、三 of the target Epic, such as `MEMORY.md`, sibling overview docs, or referenced TD files.
4. Read relevant `master/docs/common` knowledge through index, README, or clearly named entry files. Use the smallest useful set.
5. Use relevant read-only skills under `master/skills/common`, such as `ads-kb`, Confluence knowledge lookup, Ads knowledge QA, experiment analysis references, rollout references, or table / metric knowledge helpers when the Epic needs those concepts.
6. Stop when the loaded knowledge is enough to judge definitions, business chain, metric design, validation method, and KB conflicts.

Do not read the entire Ads documentation tree. Use explicit terms from the Epic core scope to keep retrieval narrow. Ignore chapter 四 TRD links and chapter 五 status-table links unless the user explicitly asks for execution, rollout, or progress review.

## What To Extract From The Epic

Extract facts before judging:

- Metadata: `KP Title`, `KP Type`, `Why Do`, `Deliverable`, `pic`, owner, and date fields when present.
- From chapters 一、二、三: problem statement and why-now reasoning.
- From chapters 一、二、三: KA list, claimed deliverables, acceptance criteria, and non-goals.
- From chapters 一、二、三: business metrics, technical metrics, validation plan, analysis plan, experiment design, rollout judgment, or go/no-go rule.
- From chapters 一、二、三: rhythm, stage order, validation cadence, gates, risks, and open questions.
- From chapters 一、二、三: key terms, acronyms, system names, table names, metric names, strategy names, and referenced documents.
- If a KA deliverable is a skill: what the skill is used for, who will use it, what problem it solves, its rough input/output, and what decision or workflow it enables.

If a field is absent, record `未明确`; do not infer it from nearby docs unless the Epic clearly references that source.

## What KB Is Used For

Use KB and read-only skills to:

- Validate whether key Ads concepts are named and used correctly.
- Find definitions for critical terms when the Epic omits them.
- Check whether the Epic's business chain and metric direction conflict with known Ads knowledge.
- Judge whether the proposed evidence supplement or statistics method is reasonable.
- Identify when a domain-specific skill should be used for a deeper review.

Use KB at concept level. If a term such as target ROI, ADVV, GMV, ROAS, or achievement rate is already a known Ads concept and the Epic uses it consistently, do not require the Epic to list the physical table, read field, unit, or missing-field behavior. Ask for those details only when the Epic is defining a new metric, changing a data contract, or the concept cannot be understood without them.

Relevant sources include:

- `docs/common/**`, especially index, README, Ads introduction, metric, experiment, rollout, and domain glossary files.
- `docs/team/**` only when a targeted search with Epic terms finds a clearly relevant document.
- `skills/common/ads-kb` for Ads business or metric concepts.
- Confluence or Ads knowledge QA skills when local docs are insufficient and the task remains read-only.
- Experiment, rollout, table, metric, Kafka, or platform knowledge skills when the Epic depends on those concepts.

## What KB Is Not Used For

Do not use KB loading as a reason to require:

- Exact baseline values to already exist.
- Offline replay results to already exist.
- Exact threshold numbers to already be filled when the Epic says later data analysis will choose them.
- Physical read fields, table columns, exact units, or field owners for existing concepts.
- Experiment results to already be completed.
- Concrete evidence data to be pasted into the Epic.
- Source code, SQL correctness, model formulas, or algorithm implementation details to be reviewed.
- Large `resource/`, CSV, xlsx, image, or external platform dumps to be read by default.
- Chapter 四 `TRD 文档列表` or chapter 五 `KP 执行与状态` to be complete.

## Suggested Search Pattern

Start with terms from the Epic:

- KP title words.
- System names such as `bid2x`, `MPC`, `ROI3`, `Graph Indexer`, `bidding_store`, or `ultrav`.
- Metric names such as `ADVV`, `GMV`, `achievement rate`, `PCOC`, `v-profit`, or `platform_gmv`.
- Model, strategy, table, label, experiment, or rollout names.

Preferred command:

```bash
rg -n "bid2x|MPC|ADVV|achievement rate" docs/common docs/team -g "*.md"
```

Use at most two broad keyword attempts before narrowing. Do not claim KB support unless a local file was actually read or a read-only skill result was actually obtained.

## Evidence Statements

In the review, separate facts and inference:

- `Epic says`: content directly written in the target Epic.
- `Evidence says`: nearby evidence, local KB, common skill result, SQL summary, experiment summary, rollout doc, or platform fact that was actually read.
- `Reviewer infers`: reviewer inference from Epic content and evidence.

For single-file deep review, include a concise evidence or KB log when it helps the user understand why a definition or chain is judged. Keep it short; the review should not become a raw evidence dump.

Suggested log shape:

```markdown
| 类型 | 来源 | 查询词 / 目标 | 命中内容 | 对本 review 的作用 | 缺口 |
| --- | --- | --- | --- | --- | --- |
```

## Evidence Gaps To Report

Report a gap when:

- A key term is undefined in the Epic and cannot be found in KB.
- A problem claim depends on a fact, but the Epic does not explain how to measure, analyze, or prove it.
- A KA has no human-observable artifact.
- A KA deliverable is a skill, but the Epic does not explain what the skill is used for, who will use it, and what problem it solves.
- A function or code deliverable has no technical metric proving it works.
- An analysis report or experiment design deliverable has no analysis direction or experiment design outline.
- Business metrics do not align with the stated business goal.
- The Epic conflicts with KB definitions, metric meaning, or business chain.
- Chapters 一、二、三 make staged delivery, rollout, or validation claims but do not explain the order, gate, cadence, or decision rule.
- A cited document does not exist locally or a relevant read-only skill cannot be accessed.

Do not report a gap when the Epic has a placeholder for a concrete number and also explains the analysis dimension and later decision, for example "连续下降次数 TBD, 用历史样本分布确定" or "低 coef 持续时间后续按 region 分析". That is acceptable at Epic TD review granularity.

Do not report a serious gap only because:

- The exact baseline number is missing.
- Offline replay is missing.
- Concrete threshold numbers are placeholders for later data analysis.
- Real read fields, units, table columns, or field owners are absent for known Ads concepts.
- The experiment has not finished.
- SQL has not been executed.
- Concrete evidence data is not pasted into the Epic.
- Code implementation details are not described.
- Chapter 四 TRD links, chapter 五 owner / ETA / effort / status, rollout records, key findings, problems, discussion, or next steps are missing or stale.

## Batch Mode Evidence Limits

Batch mode prioritizes readable comparison across KPs:

- Read each primary Epic or KP Markdown file, but score only metadata and chapters 一、二、三.
- Extract the eight review dimensions.
- Run small `docs/common` or `ads-kb` lookup only when a key definition or business-chain judgment depends on it.
- Do not inspect `memory/`, `resource/`, CSV, xlsx, images, chapter 四 TRD links, chapter 五 status links, or external references unless the user explicitly asks for deep review on that KP.
- Explain every `Fair` item in plain language after the table.

## Error Handling

- File missing: ask for a valid local path or updated checkout.
- KP identifier unmatched: say no matching Epic was found and ask for a path or broader directory.
- KP identifier multi-matched: list candidates and stop.
- Chapter missing: continue review and score the affected checklist item `Fair` or `Weak`.
- KB not found: write `未找到相关 KB 支撑`.
- Relevant common skill unavailable: write the missing skill or blocked source as a gap.
- Evidence too large: state it was not inspected and explain the size or format boundary.
