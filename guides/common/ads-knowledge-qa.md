# Ads Knowledge Q&A (ads-knowledge-qa) Guide

> **Language**: [English](ads-knowledge-qa.md) | [中文](ads-knowledge-qa.zh-CN.md)

Answers Shopee Paid Ads questions through guarded layered retrieval (ads-workspace index → atomic note → Confluence → sra-kb-query → code), with local wrappers for code search and freshness-filtered Confluence lookup.

**Trigger keywords**: "ads-knowledge-qa", "广告知识问答助手", "广告系统", "ads-engine", "online-bidding", "paidads-recall", "eCPM", "ROI", "CTR", "CVR", "ocpx", "双出价", "出价策略"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with the guarded retrieval pipeline |
| `references/workflow.md` | Layer-by-layer retrieval strategy and worked examples |
| `references/security-rules.md` | Redaction and safe-output rules |
| `references/repos.md` | `core-knowledge/03.ads-engine/01.system-architecture-overview.md` repo routing, code-search lookup queries, and index-state notes |
| `scripts/preflight.sh` | Dependency check for code search and Confluence wrappers |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| `sra-code-search` | Skill | Wrapper target for repo search, zgrep, and hyper-search |
| `sra-confluence-kb` | Skill | Wrapper target for freshness-filtered Confluence search |
| `sra-kb-query` | Skill | Hosted S&R&A KB Q&A fallback |
| `sp-grafana` | Skill | Live monitoring queries |
| `ads-okr-epic-report` | Skill | OKR/KR/KP progress and project report generation |
| GitLab access | Network | Read Ads docs/README/code when the retrieval path reaches source repositories |
| ads-workspace docs | Local files | Primary knowledge source: search `docs/common/index-synthesis*.md` first, then read the selected atomic note under `docs/common/core-knowledge/`, `docs/common/readme/<repo>/`, or supporting `docs/common/**` / `docs/team/**` Markdown |

---

## Usage

### Scenario 1: Concept / Architecture question

> "How is eCPM calculated?"

Classified as general knowledge. Searches `docs/common/index-synthesis*.md` first to locate the atomic note, then reads the selected `docs/common/core-knowledge/` file and returns the formula and Shopee-specific context.

### Scenario 2: Architecture & business question

> "How does ads-engine recall work?"

The skill first checks `docs/common/index-synthesis*.md`, then reads the indexed core-knowledge or repo README atomic note, and uses Confluence / `sra-kb-query` only if the answer is still insufficient.

### Scenario 3: Data table & SQL question

> "Which table has campaign-level daily metrics?"

This is a non-target use case. The skill should delegate DW SQL and actual data analysis to `sra-data-query` instead of forcing docs/code retrieval.

### Scenario 4: Code implementation question

> "How does online-bidding compute the final bid price?"

Classified as implementation intent. The skill jumps quickly to source code, using `docs/common/readme/<repo>/` for repo overview when useful and the local `bash scripts/run_code_search.sh ...` wrapper instead of hard-coded installed paths.

Before code search, the skill resolves the target repo from `docs/common/core-knowledge/03.ads-engine/01.system-architecture-overview.md`, runs `search-repo`, and uses the returned repo `name`; static or guessed `gitlab/...` slugs are not valid inputs.

### Scenario 5: OKR / KP progress question

> "What is the progress of O3 KP2?"

This is not a knowledge retrieval path. For an exact KP target, route to `/ads-okr-epic-report --query <kp>` so the answer is returned in chat without writing files. If the target is ambiguous, such as `O3 KP2` matching multiple KRs, list the candidate KP titles and ask the user to choose before running the report.

---

## Retrieval Pipeline

1. **Preflight** — Optionally run `bash scripts/preflight.sh` once per session
2. **L1** — Parse intent and decide whether the question is concept / architecture / implementation / monitoring
3. **L2** — Check `docs/common/index-synthesis*.md`, read the selected atomic note under `docs/common/core-knowledge/` or `docs/common/readme/<repo>/`, then other ads-workspace Markdown, Confluence, and `sra-kb-query`
4. **Optional source-repo docs fallback** — Use `core-knowledge/03.ads-engine/01.system-architecture-overview.md` to pick candidate repos and read source-repo docs only when centralized README is insufficient
5. **L4** — Search code facts with the local wrapper when implementation detail is needed
6. **L5** — Delegate monitoring questions to `sp-grafana`
7. **Project progress** — Delegate exact KP progress questions to `/ads-okr-epic-report --query`; use normal `ads-okr-epic-report` for KR/O report generation

---

## Output Format

Answers should:

- Stop at the first sufficient retrieval layer instead of over-searching
- Mark missing information explicitly as "无相关文档" or "无相关代码"
- Include source attribution for every key fact
- Prefer code facts when docs and implementation conflict
- Apply the redaction rules from `references/security-rules.md`

---

## Downstream Skills

| Skill | Purpose |
|-------|---------|
| `sra-data-query` | DataSuite ad-hoc data analysis and SQL execution |
| `/ads-text2da` | Natural language data analysis and SQL execution |
| `/ads-diagnose` | Diagnose ad performance anomalies |
| `sp-grafana` | Monitoring and dashboard lookups |
| `ads-okr-epic-report` | Query KP progress in chat with `--query`, or generate KR/O project reports from Epic files |
