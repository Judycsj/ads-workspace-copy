# Ads KB Eval (ads-kb-eval) Guide

> **Contributors**: amos.wu, luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-kb-eval.md)

> **Language**: [English](ads-kb-eval.md) | [中文](ads-kb-eval.zh-CN.md)

Evaluate KB document quality against given questions. Supports two evaluation modes: new question evaluation and module-level re-evaluation.

**Trigger keywords**: "KB eval", "evaluate KB", "knowledge base quality", "KB scoring", "KB coverage", "ads-kb-eval"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with dual-mode workflow (Mode A: new questions, Mode B: module eval) |
| `references/routing-rules.md` | Question-to-file routing rules and complete file mapping table |
| `references/scoring-rubric.md` | 1-5 scoring rubric (including metric-query specific rubric) and low-score reason templates |
| `scripts/refresh_summary.py` | Auto-refreshes summary and classification statistics tables in questions-list files |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| `docs/common/index-synthesis.zh-CN.md` | Local file | Master index for question routing |
| `docs/common/core-knowledge/` | Local directory | Knowledge documents to evaluate against |
| `docs/common/ops-log/questions/` | Local directory | Output directory for routing and eval results |

---

## Dual-Mode Architecture

The skill operates in two distinct modes, determined at Step 0 (Mode Detection):

### Mode A: New Questions

**Trigger**: User provides new questions (single question, markdown list, or file path).

**Flow**: Input parsing → Step 1 Preprocessing (dedup, scope check, classify) → Step 2 Routing & Scoring → Step 3 Write Results

- New questions are assigned permanent QIDs (format: `YYYYMMDDHHMMSS`)
- Deduplication against existing questions in `questions-list.md`
- Scope check detects overly broad questions and interactively splits them
- Classification into kb / metric-query / task / invalid (only kb and metric-query proceed to scoring)

### Mode B: Module Eval

**Trigger**: User specifies a module name (e.g., "evaluate 2.1 recall"), or calls `/ads-kb-eval` without questions.

**Flow**: Module selector (interactive) → Extract existing questions → Step 2 Re-score against latest KB → Step 3 Overwrite results

- Skips Step 1 preprocessing entirely
- Existing QIDs and routing are preserved
- Re-reads KB files for latest content and updates scores
- Interactive three-level module picker: Chapter → Sub-module → Section (if 50+ questions)

---

## Question Classification (Mode A only)

| Category | Definition | Action |
|----------|-----------|--------|
| **kb** (knowledge) | Concepts, architecture, flows — answerable from documents | Route + score |
| **metric-query** | Asks for dynamic metric values that change over time | Route + score with dual-dimension rubric |
| **task** (action) | Requires execution: generate SQL/reports, run experiments | Match to execution skill, skip scoring |
| **invalid** | Vague, missing context, unclear intent | Mark reason, skip scoring |

---

## Usage

### Mode A: Batch evaluation from question file

> "/ads-kb-eval docs/common/question-list.md"

Reads all questions → deduplicates → scope check → classify → route → score → write results.

### Mode A: Single question evaluation

> "Evaluate KB: What is the training paradigm for the recall dual-tower model?"

Routes to the relevant recall file, scores coverage, writes result.

### Mode B: Interactive module selection

> "/ads-kb-eval 评测模块" or "/ads-kb-eval" (no questions provided)

Lists all modules with question counts and average scores. User selects via interactive menu:
1. **Level 1**: Choose Chapter (Chapter 1-2 / Chapter 3-4 / Chapter 5-6)
2. **Level 2**: Choose sub-module within the selected Chapter
3. **Level 3** (optional): Further refine if sub-module has 50+ questions

### Mode B: Direct module specification

> "Evaluate Chapter1 Core Knowledge - 2.1 Recall"

Directly matches to section 2.1, skipping the interactive picker. Extracts existing questions and re-scores.

---

## Output

Results are written to **`docs/common/ops-log/questions/questions-list.md`** (and its `zh-CN` counterpart), organized by KB file following the `index-synthesis.zh-CN.md` section structure. After writing, `scripts/refresh_summary.py` auto-refreshes summary statistics. Historical score changes are tracked via git history.

Tables use 9 columns: `QID | Question | Type | Reason | Primary File | Secondary Files | Score | Low Score Reason | Note`. Non-5/5 rows are marked as `待处理` in the Note column.

---

## Scoring

### KB type (general scoring)

| Score | Definition |
|-------|-----------|
| **5** | Fully covered, complete and accurate, directly answerable |
| **4** | Mostly covered, minor gaps not affecting core answer |
| **3** | Partially covered, provides direction but missing key details |
| **2** | Limited coverage, only scattered related info |
| **1** | Not covered, no relevant information in routed files |

### Metric-query type (dual-dimension scoring)

| Score | Definition |
|-------|-----------|
| **5** | Current status fully described + query method clear (table/dashboard/skill) |
| **4** | Current status mostly described + query method present but not specific |
| **3** | Only current status OR only query method, missing the other half |
| **2** | Both dimensions have scattered info but incomplete |
| **1** | No relevant information in KB |

All non-5/5 scores include specific missing content and suggested file/section for improvement.
