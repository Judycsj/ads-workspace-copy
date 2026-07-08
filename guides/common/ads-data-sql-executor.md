# Ads SQL Executor (ads-data-sql-executor) Guide

> **Language**: [English](ads-data-sql-executor.md) | [中文](ads-data-sql-executor.zh-CN.md)

Unified SQL execution infrastructure for all Ads skills. Accepts SQL + optional engine hint, selects the execution path (ClickHouse direct / Presto personal-query / DataSuite Playwright fallback), runs the query, handles errors and retries, and returns structured results.

**Trigger keywords**: "ads-data-sql-executor", "run sql", "execute sql", "run this query", "execute this query"

---

## When to Use

- **Directly**: `/ads-data-sql-executor SELECT count(*) FROM ...` when you have SQL ready to run
- **Via delegation**: Called by `ads-data-text2da` after SQL is generated and confirmed
- **As infrastructure**: Other skills (ads-diagnose, roi3 series) reference the scripts directly

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Skill definition with engine selection, execution paths, and error handling |
| `scripts/run_clickhouse_query.py` | ClickHouse runner: direct HTTP + DataSuite API fallback |
| `scripts/run_personal_presto_query.py` | Presto runner via `dataservice` SDK |
| `scripts/test_clickhouse_query.py` | Unit tests for the ClickHouse runner |
| `references/setup.md` | Environment setup guide for both runners |
| `references/config.example.json` | Configuration template for `~/.config/text2da/config.json` |
| `references/datasuite-ui-guide.md` | DataSuite Playwright fallback operation guide |

---

## Execution Paths

| Path | Engine | When Used |
|------|--------|-----------|
| Path 0 | ClickHouse | SQL targets ClickHouse tables, uses `cluster()`, or user specifies ClickHouse |
| Path A | Presto | SQL targets Hive tables and `~/.config/text2da/config.json` exists |
| Path B | DataSuite Playwright | Fallback when Path 0/A config is missing or fails |

---

## Setup

See `references/setup.md` for detailed instructions. Quick summary:

1. Create `~/.config/text2da/config.json` from `references/config.example.json`
2. For Presto: configure `python_bin`, `personal_token`, `end_user`, `presto_queue`
3. For ClickHouse: configure `clickhouse.sg` section with `host`, `user`, `password`

---

## Related Skills

| Skill | Relationship |
|-------|-------------|
| `ads-data-text2da` | Orchestrator that generates SQL and delegates execution here |
| `ads-data-analyze` | Receives results from this skill for analysis |
| `ads-text2da` | Legacy version, also delegates execution here |
