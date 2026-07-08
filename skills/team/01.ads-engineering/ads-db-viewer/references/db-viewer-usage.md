# DB Viewer Usage/DB Viewer 用法

backendadmin exposes DB Viewer through SPEX commands. This skill uses the non-MTS commands because the generic SPEX HTTP gateway can authenticate them with service auth.

## Commands/命令

| Purpose | SPEX command |
|---|---|
| Metadata | `paidads.backend_admin.get_database_viewer_metadata` |
| Query data | `paidads.backend_admin.database_viewer` |

Avoid `_mts` commands for local usage. MTS commands require SPEX request application headers containing BFF user identity, and the generic HTTP gateway did not pass tested HTTP headers into that application header.

## Database Enum/数据库枚举

| Value | Name | Domain |
|---:|---|---|
| 1 | `DATABASE_ADS` | Ads Core DB |
| 2 | `DATABASE_ARCHIVE` | Archive DB |
| 3 | `DATABASE_BUYER_SEGMENT` | Buyer Segment DB |
| 4 | `DATABASE_SRM` | SRM DB |
| 5 | `DATABASE_BUYER_SEGMENT_BY_REGION` | Region-split Buyer Segment DB |
| 6 | `DATABASE_ADS_MARKETING` | Ads Marketing DB |
| 7 | `DATABASE_REBATE` | Rebate DB |

## Metadata Request/元数据请求

Use table name when known, or table example plus database enum when starting from a physical table:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py metadata \
  --env live \
  --region SG \
  --database ADS \
  --table-example ads_account_tab_00000000
```

## Query Request/查询请求

Use `--fields` for local projection and `--filter`/`--range` for DB Viewer filters:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py query \
  --env live \
  --region SG \
  --database ADS \
  --table-example ads_account_tab_00000000 \
  --filter userid=123 \
  --range ctime=1700000000..1800000000 \
  --limit 1 \
  --fields status,ctime
```

Raw filter JSON is also supported:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py query \
  --env live \
  --region SG \
  --database 1 \
  --table-example ads_account_tab_00000000 \
  --filters-json '[{"name":"userid","value":"123"}]' \
  --fields status
```

## Optional Local Adapter/可选本机适配层

This is an implementation convenience for repeated local calls, not a user-facing workflow. Prefer direct `metadata` and `query` commands in guides and final answers.

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_viewer.py serve \
  --env live \
  --region SG \
  --port 18080
```

Endpoints:

- `GET /health`
- `POST /metadata`
- `POST /query`

Example:

```bash
curl -sS http://127.0.0.1:18080/query \
  -H 'content-type: application/json' \
  -d '{"table_name_example":"ads_account_tab_00000000","database":1,"limit":1,"fields":["status"]}'
```

The response returns parsed rows in `data.records`.

## Auth/Auth 认证

The script reuses the `sp-spex-api` helper for SPEX HTTP gateway auth:

- Space token from `--token`, `SPACE_TOKEN`, SRA credentials, SMC token, or ads-workspace `spex_http_gateway.bearer_token`.
- Service key and SDU are resolved automatically from SPEX privilege APIs and cached by the helper.
- Do not print or paste service keys, bearer tokens, or raw auth headers in answers.
