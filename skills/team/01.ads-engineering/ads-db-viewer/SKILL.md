---
name: ads-db-viewer
description: >
  Ads DB Viewer (广告 DB 查看器) — explain Paid Ads database design, table meaning, DB Viewer metadata, field semantics, and query small live DB samples through backendadmin non-MTS DB Viewer commands.
  TRIGGER when: user mentions "ads db", "ads-db-lib", "DB Viewer", "database_viewer", "live db", "查 live DB", "表含义", "字段介绍", "DB meta", "广告数据库", or asks to explain/query Paid Ads DB tables.
  DO NOT TRIGGER when: user asks for Hive/DataSuite warehouse SQL only, generic MySQL help unrelated to Paid Ads, or indexer log population analysis better handled by ads-idx-analyser.
---

# Ads DB Viewer/广告 DB 查看器

Use this skill to answer two classes of Paid Ads DB questions:

1. Explain the current database design, table meaning, DB Viewer metadata, and field semantics.
2. Query a small amount of live data through backendadmin DB Viewer using the non-MTS SPEX commands.

Runtime requirements: `uv`, `ads-db-lib` checked out in the workspace, and `sp-spex-api` helper scripts available from the sibling `sra-toolkit` repo or `SRA_TOOLKIT_DIR`.

## Source Order/资料优先级

Read `references/source-priority.md` before answering schema or design questions. The short rule is:

1. Use the Google Doc as the conceptual starting point when accessible.
2. Use live DB Viewer metadata as the current online table/field source.
3. Use `ads-db-lib` code to correct table routing, sharding, client ownership, and business semantics.
4. Use live sample rows only for verification, and keep queries narrow.

## Core Scripts/核心脚本

| Script | Purpose |
|---|---|
| `scripts/ads_db_viewer.py` | Query backendadmin DB Viewer metadata/live data via SPEX HTTP gateway using non-MTS commands. |
| `scripts/ads_db_lib_lookup.py` | Search local `ads-db-lib` for table constants, methods, model usage, and business semantics. |

Run scripts with `uv run` from the `ads-workspace` repo or the skill directory.

## Explain a Table/解释表

1. Read `references/source-priority.md` and `references/ads-db-map.md`.
2. Fetch DB Viewer metadata for the table:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py metadata \
  --env live \
  --region SG \
  --database 1 \
  --table-example ads_account_tab_00000000
```

3. Cross-check `ads-db-lib`:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_lib_lookup.py \
  --query ads_account
```

4. Answer with source separation:

- **Design meaning**: from the Google Doc when available, corrected by `ads-db-lib`.
- **Current metadata**: from DB Viewer metadata, including table format, database enum, columns, filter keys, and shard hints when present.
- **Field semantics**: from metadata first, then `ads-db-lib` method names, proto/model names, comments, and README business context.
- **Uncertainty**: state when the Google Doc could not be fetched or when a field lacks code/documentation evidence.

## Query Live Data/查询 Live 数据

Use only small, targeted reads. Default to `limit=1`, project fields whenever possible, and do not expose sensitive identifiers unless the user explicitly needs them for debugging.

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py query \
  --env live \
  --region SG \
  --database 1 \
  --table-example ads_account_tab_00000000 \
  --limit 1 \
  --fields status
```

For filters:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py query \
  --env live \
  --region SG \
  --database 1 \
  --table-example ads_account_tab_00000000 \
  --filter userid=123 \
  --fields status,ctime
```

For small batch reads, require a clear limit and prefer filters:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py query \
  --env live \
  --region SG \
  --database 1 \
  --table-example ads_account_tab_00000000 \
  --limit 10 \
  --fields accountid,userid,status,ctime,mtime
```

The response returns parsed rows in `data.records`.

## Safety Rules/安全规则

- Prefer metadata and code lookup before live row reads.
- Query live only through backendadmin DB Viewer non-MTS commands:
  - `paidads.backend_admin.get_database_viewer_metadata`
  - `paidads.backend_admin.database_viewer`
- Keep `limit <= 10` unless the user explicitly requests more and the debugging case justifies it.
- Use `fields` projection for live reads.
- Treat local proxy/server mode as an implementation convenience only; do not present "start proxy" as the user-facing workflow.
- Do not print service keys, bearer tokens, raw auth headers, or credential file contents.
- Redact or summarize PII-like values when they are not essential to the user's question.

## Reference Files/参考文件

- `references/source-priority.md` — evidence order and Google Doc handling.
- `references/db-viewer-usage.md` — command schema, database enum, filters, and auth behavior.
- `references/ads-db-map.md` — high-level DB domains and `ads-db-lib` correction rules.
