# Source Priority/资料优先级

Use multiple sources and keep their roles separate. Do not merge conceptual documentation, generated metadata, and live samples into one unqualified claim.

## Priority Order/优先级顺序

1. **Google Doc/Google 文档**: the design and table-meaning source requested by the user.
   - Link: `https://docs.google.com/document/d/1xbEldfLSGJ5KsFjKk2IjZQfoI0XfQ8Ffwja0UKVHjNw/edit?tab=t.9yqy1atwtjia#heading=h.8kqz7ojwfqyr`
   - Use it for high-level design, table purpose, business ownership, and narrative descriptions.
   - If it is not already available in context, try an available Google Docs MCP/browser-auth/export path. Anonymous export may return 401; if so, state that the doc was not fetched and continue with code + metadata evidence.
2. **DB Viewer metadata/DB Viewer 元数据**: current online metadata from backendadmin.
   - Use it for current database enum, table identifier, table format, column list, filterable fields, and online visibility.
   - Metadata should override stale doc text for physical table shape.
3. **ads-db-lib code/ads-db-lib 代码**: runtime source for clients, sharding, table constants, model usage, helper methods, and business semantics.
   - Use `scripts/ads_db_lib_lookup.py --query <table_or_symbol>`.
   - Prefer concrete code evidence over guessed field meanings.
4. **Live sample rows/Live 样例行**: reality checks only.
   - Use tiny reads with field projection.
   - Samples can confirm value shape, sentinel values, and whether data exists; they do not define business semantics by themselves.

## Correction Rules/修正规则

- If the Google Doc and DB Viewer metadata disagree on current columns or table format, trust DB Viewer metadata and mention the doc appears stale.
- If the Google Doc and `ads-db-lib` disagree on routing, sharding, client owner, or table constants, trust `ads-db-lib` and cite the relevant file/method evidence.
- If a field exists in metadata but has no doc/code explanation, say "metadata confirms the field exists, but I did not find a reliable semantic description."
- If live rows show sentinel values, confirm in code before explaining them as business rules.

## Answer Shape/回答结构

For table explanation requests, answer in this order:

1. **What it is/表含义**: one-paragraph purpose.
2. **Where it lives/所在 DB**: database enum, domain, table format, sharding hints.
3. **Important fields/重要字段**: grouped by identity, status, money/budget, timestamps, ext fields.
4. **How code uses it/代码使用方式**: key `ads-db-lib` clients/methods and downstream patterns.
5. **Live check/线上校验**: optional tiny query result summary, not a full dump.
6. **Uncertainties/不确定点**: inaccessible doc, missing comments, or conflicting sources.
