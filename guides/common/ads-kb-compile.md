# Ads KB Compile (ads-kb-compile) Guide

> **Language**: [English](ads-kb-compile.md) | [中文](ads-kb-compile.zh-CN.md)

Read input content from local Markdown files, Google Docs, inline text, or workspace git changes, map to target files referenced in `index-synthesis.md`, smart-merge incremental information preserving existing structure, update bilingual counterparts, and refresh the index-synthesis.

**Trigger keywords**: "kb-compile", "知识入库", "编译知识", "compile to kb", "merge into knowledge base", "sync to core-knowledge", "入库到知识库", "ads-kb-compile", "git changes compile", "recent changes", "最近改动入库", "git 变更入库"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with the compile workflow (Step 1-7 + Step 1.5 for git mode) |
| `references/mapping-rules.md` | Write scope, excluded targets, section-to-file mapping table, matching algorithm, target type adaptation |
| `references/workflow.md` | Scope resolution, smart merge rules, diff classification, bilingual handling, git change mode rules |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| `docs/common/index-synthesis.md` | Local file | Master index for mapping input to target files |
| Target directories | Local directories | All directories referenced in index-synthesis.md Section 2 |
| `mcp__google-drive` | MCP server | Required when input is a Google Doc |

---

## Write Scope

The skill can modify all files referenced in `index-synthesis.md` Section 2, **unless** the directory is listed in the Excluded Targets table in `references/mapping-rules.md`.

Currently excluded:
- `docs/common/readme/` → use `ads-readme-generate`
- `docs/common/datamap/` → use `sra-table-info-query`

All other indexed files (Core Knowledge, DPM, How-Tos, SOPs) are writable.

---

## Usage

### Scenario 1: Compile a local Markdown file

> "把 `docs/personal/luka.yang/notes/new-recall-channel.md` 编译入库到知识库"

The skill reads the file, identifies the recall domain, maps to §2.1, and merges into `core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.md` with bilingual updates.

### Scenario 2: Compile from Google Docs

> "Compile this Google Doc into the KB: https://docs.google.com/document/d/1abc.../edit"

The skill reads the Doc via MCP, identifies the topic, maps to the target file, merges, and updates the index.

### Scenario 3: Consolidate Sub-KB content

> "把 `docs/common/sub-kb/2.1-recall/kb.md` 的内容 compile 到 core-knowledge"

The skill reads the sub-kb file as input, maps to the corresponding core-knowledge file, and smart-merges with deduplication.

### Scenario 4: Multi-section document

> "这个文档涵盖了召回和出价两部分，请入库"

The skill splits the input by section boundaries, maps each segment independently, and merges into the respective files.

### Scenario 5: Compile from git changes

> "把最近 7 天的变更编译入库"

The skill runs `git log --since="7 days ago"` to discover changed files across `docs/`, `skills/common/`, `guides/common/`, `scripts/`, `templates/`, and root config files (`CLAUDE.md`, `README.md`, etc.). It filters to in-scope files, classifies them (direct edits vs. skill/guide changes vs. source changes), and processes them in batch: direct edits get index refreshed, other changes go through the full compile flow.

### Scenario 6: Cross-section compile

> "把 DPM 的 deduction module 相关概念 compile 到核心知识"

The skill reads the DPM deduction doc, extracts conceptual content, maps to core-knowledge §5.4, and merges — keeping implementation details in the DPM original.

---

## Workflow Overview

1. **Parse Input** — Read local .md, Google Doc, inline text, or discover git changes; detect language
2. **Git Change Discovery** *(git mode only)* — Run git log across `docs/`, `skills/common/`, `guides/common/`, `scripts/`, `templates/`, and root config files; filter scope, classify changes, confirm with user
3. **Topic Identification** — Analyze domain keywords, section references, headings
4. **Map to Target** — Match input to target files via mapping table (core-knowledge) or index path (other sections)
5. **Read Existing** — Read target files and bilingual counterparts
6. **Smart Merge** — Scope check, diff classify (new/updated/redundant), preview to user
7. **Write Updates** — Merge primary language, generate translation if counterpart exists, update metadata
8. **Update Index** — Refresh index-synthesis Section 2.x rows and Section 1 coverage stats

---

## Output

After compilation, the skill prints a structured report including:
- Input source(s) processed
- Target files updated with line counts
- Direct edits with index refreshed
- Sections modified
- Index stats updated
- Skipped files (excluded targets) with recommended tools

---

## Related Skills

| Skill | When to Use Instead |
|-------|-------------------|
| `ads-knowledge-qa` | Querying existing knowledge (read-only) |
| `ads-readme-generate` | Auto-generating code repo READMEs (excluded from this skill's scope) |
| `sra-table-info-query` | Building Hive table metadata DataMap (excluded from this skill's scope) |
| `ads-workspace-gdoc-sync` | Syncing Markdown to Google Drive (opposite direction) |
| `ads-okr-memory-update` | Recording session notes to project/personal memory |
| `ads-okr-memory-sync` | Syncing memory files into project epic files |
