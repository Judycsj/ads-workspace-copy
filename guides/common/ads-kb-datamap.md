# ads-kb-datamap Skill Guide

> **Contributors**: luka.yang | **Last Updated**: 2026-06-16 | [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-kb-datamap.md)

`ads-kb-datamap` builds table knowledge base entries for Hive tables used by
downstream skills like `ads-text2da`. It extracts table metadata, column
definitions, and SQL patterns from codebases (`from-code`) and DataSuite
DataMap UI (`from-di`).

---

## Prerequisites

- **from-code**: `projects/gitlab/paidads-alg/studio_tasks/` must be cloned locally
- **from-di**: Browser MCP (Playwright) configured; DataSuite login session active

---

## When to use

- Building or updating table KB entries in `docs/common/datamap/`
- Adding SQL pattern documentation for a Hive table
- Supplementing code-derived metadata with DataMap UI data (column descriptions, query frequency)

---

## Quick Start

```bash
# Single table (default: from-code)
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live

# Specify data source
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source from-code
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source from-di
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source both

# Interactive mode (select from existing KB tables)
/ads-kb-datamap
```

---

## Output

Three files per table in `docs/common/datamap/{db}.{table_name}/`:

| File | Purpose |
|------|---------|
| `table_info.md` | Search index — table description, key metrics/dimensions, technical properties |
| `column_info.md` | Column reference — field types, value mappings, non-additive flags |
| `sql_patterns.md` | Coding context — WHERE/JOIN/aggregation patterns, SQL snippets, write lineage |

---

## Data Sources

- **from-code** (primary): Scans `studio_tasks/` codebase for SQL references, extracts DDL, query patterns, and write lineage
- **from-di** (supplementary): Scrapes DataSuite DataMap UI for column descriptions, query frequency, DQC status, and business properties

---

## Tips

- Run `from-code` first to establish the KB skeleton, then `from-di` to fill in DataMap-specific fields
- Multiple tables can be specified comma-separated
- The skill is idempotent: `from-code` overwrites `sql_patterns.md` and incrementally updates the other two files
