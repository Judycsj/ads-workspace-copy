# Ads Data Text2DA (ads-data-text2da) Guide

> **Language**: [English](ads-data-text2da.md) | [中文](ads-data-text2da.zh-CN.md)

Decomposes data analysis tasks into sub-queries, generates SQL with smart table selection and LLM validation, selects the requested engine (Presto or ClickHouse) from user intent, SQL, and table metadata, executes through the matching runner or DataSuite fallback, then analyzes results and produces insight reports.

**Trigger keywords**: "ads-data-text2da", "text2da", "text2sql", "data analysis", "数据分析", "分析一下", "帮我分析", "查数据", "写SQL", "帮我查", "跑个SQL", "生成SQL"

---

## Key Improvements over ads-text2da

1. **Smart table retrieval**: 4-stage pipeline (keyword extraction → index scan → candidate evaluation → multi-table comparison) replaces brute-force glob scan
2. **Multi-table comparison**: When multiple tables can answer the same query, presents a comparison table with granularity, storage type, popularity, dimension/metric coverage, and query complexity
3. **SQL archival**: Generated SQL is saved to `docs/personal/{user}/sql/` for long-term retrieval and reuse
4. **LLM SQL validation**: Automatic pre-execution validation covering syntax, field existence, partition filters, JOIN correctness, aggregation logic, and LIMIT

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with full 6-phase workflow |
| `references/setup.md` | Setup guide for built-in personal-presto runner |
| `references/config.example.json` | Personal-presto configuration example |
| `references/datasuite-ui-guide.md` | DataSuite UI operation guide (fallback path) |
| `scripts/run_personal_presto_query.py` | Built-in personal-presto execution script |
| `scripts/run_clickhouse_query.py` | ClickHouse execution script with DataSuite ClickHouse fallback |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| `docs/common/datamap/` | Local KB | Table metadata (table_info, column_info, sql_patterns) |
| `docs/common/de-knowledge/` | Local KB | Ontology (dim_synonyms, retrieval terms), rerank profiles, business docs |
| `docs/common/index-synthesis.md` | Local KB | DataMap index for fast keyword-based table discovery |
| `~/.config/text2da/config.json` | Config | Personal-presto and optional ClickHouse direct runner configuration |
| Playwright MCP | MCP | DataSuite UI automation (fallback execution path) |
| Office network / VPN | Network | Access to Presto clusters and DataSuite |

---

## Usage

### Scenario 1: Simple query

> "Check yesterday's advertiser count by region"

Classified as simple — smart table retrieval finds the best table, generates a single SQL, validates it, saves to personal SQL directory, executes directly, returns result with brief insight.

### Scenario 2: Complex analysis

> "Analyze why SG CTR dropped last week"

Classified as complex — decomposes into sub-tasks (T1: overall trend, T2: dimension drill-down, T3: root cause verification), presents analysis plan for confirmation, executes iteratively.

### Scenario 3: Multi-table selection

> "Query shop-level revenue with attribution breakdown"

Multiple candidate tables found — presents comparison table showing granularity, coverage, and trade-offs. User confirms the best table before SQL generation.

---

## Workflow Overview

| Phase | Steps | Description |
|-------|-------|-------------|
| Phase 1 | Steps 1-3 | Understand task, smart table retrieval (4 stages), read table + DE-Knowledge KB |
| Phase 2 | Step 4 | Assess complexity (simple vs complex) |
| Phase 3 | Steps 5-6 | (Complex only) Decompose into sub-tasks, confirm plan with user |
| Phase 4 | Steps 7-12 | Generate SQL, LLM validate, save to personal dir, choose engine, execute, extract results |
| Phase 5 | Steps 13-14 | Analyze results, decide next step (iterate or finish) |
| Phase 6 | Step 15 | Generate structured analysis report |

---

## Execution Strategy

The execution engine is selected by the caller, SQL semantics, and KB `Storage Type`. ClickHouse and Presto are parallel paths, not priority tiers. An explicit caller choice wins over automatic detection:

1. **Presto** — keep the original Presto execution semantics: use the built-in personal-presto script when configured; fall back to DataSuite Playwright with Presto engine when personal-presto config/env/runtime is unavailable or the task is unsuitable.
2. **ClickHouse** — when ClickHouse is specified, execution must stay on the ClickHouse engine. Prefer `scripts/run_clickhouse_query.py`; if direct ClickHouse auth/HTTP fails, the runner automatically uses DataSuite ClickHouse engine 34. If the runner path is unavailable, DataSuite Playwright is allowed as long as ClickHouse engine is selected. This path must not become Hive or Presto.
3. **SparkSQL / other DataSuite-only cases** — use DataSuite Playwright directly when the task requires it.

---

## Output Format

**Simple tasks**: Result table + 1-2 key findings.

**Complex tasks**: Structured analysis report with:
- **Analysis background** — topic, data scope, tables used
- **Data overview** — key metrics summary table
- **Core findings** — numbered findings with data evidence
- **Key conclusions** — 2-3 sentences answering the original question
- **Recommendations** — actionable suggestions and follow-up directions
