---
name: ads-knowledge-qa
description: >
  Ads Knowledge Q&A (广告系统知识问答) — answers Shopee Paid Ads questions via guarded layered retrieval
  (ads-workspace index + atomic notes → Confluence → sra-kb-query → code), with local wrappers for code search
  and freshness-filtered Confluence lookup.
  TRIGGER when: user mentions "ads-knowledge-qa", "广告知识问答助手", "广告系统", "ads-engine",
  "online-bidding", "paidads-recall", "eCPM", "ROI", "CTR", "CVR", "ocpx",
  "nobid", "双出价", "出价策略", "广告召回", "广告排序", "广告计费", "GSP", "GraphEngine",
  "AdsInfo", "UltraV", "OhMyEmb", "Indexer", "归因", "混排", or asks about a Paid Ads
  service, module, or function.
  DO NOT TRIGGER when: user wants DW SQL/ad-hoc data analysis, release workflow, RESP tests, or AB setup.
skill_dependencies:
  - ads-okr-epic-report
  - sra-code-search
  - sra-confluence-kb
  - sra-data-query
  - sra-kb-query
  - sp-grafana
knowledge_sources:
  - file: ../../../docs/common/index-synthesis.zh-CN.md
    url: https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/index-synthesis.zh-CN.md
    note: Primary Ads KB retrieval entrypoint. Search this index first to select the exact atomic note under core-knowledge/readme/datamap, then read that file.
  - file: ../../../docs/common/index-synthesis.md
    url: https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/index-synthesis.md
    note: English Ads KB retrieval entrypoint. Use for English questions or when the Chinese index does not contain the needed term.
  - file: ../../../docs/common/core-knowledge/
    url: https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/core-knowledge/
    note: Canonical Ads introduction atomic notes in ads-workspace, split by domain. Read only after index-synthesis points to a candidate file; use 03.ads-engine/01.system-architecture-overview for the core repo registry.
  - file: ../../../docs/common/readme/
    url: https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/readme/
    note: Centralized repo README atomic notes. Use repo-specific docs/common/readme/<repo>/README*.md before source-repo README/docs after locating it through index-synthesis.
---

# Ads Knowledge Q&A

**Pipeline:** L1→parse intent → L2a→ads-workspace index (`docs/common/index-synthesis*.md`) → selected atomic note (`docs/common/core-knowledge/**` / `docs/common/readme/<repo>/**` / curated docs) → L2b→Confluence → L2c→sra-kb-query → L4→source code. Stop at first sufficient layer. `intent=impl` → L4 directly after repo resolution. Monitoring → `sp-grafana` (L5). OKR/KR/KP progress reports → `ads-okr-epic-report`. Source-repo README/docs are optional fallback only, not the standard layer.

**Before executing any retrieval, read these core files and use the local wrappers under `scripts/`:**
1. [references/workflow.md](references/workflow.md) — complete layer-by-layer strategy: ads-workspace doc search, Confluence CQL patterns (with 12-month date filter), optional source-repo docs fallback, L4 symbol search, response templates, worked examples.
2. [references/security-rules.md](references/security-rules.md) — output redaction rules (credentials, internal IPs, PII, vulnerabilities). Apply to every response before returning.
3. `bash scripts/preflight.sh` — optional but recommended once per session; resolves dependency skill locations and shows the supported entrypoints.

**Seatalkbot learning helper:**
- `python3 scripts/learn_session.py --session-json <path>` analyzes a Seatalkbot session payload, writes durable knowledge under `docs/common/ops-log/knowledge-bot-learnings/`, and opens an ads-workspace MR.
- Publishing supports `api`, `git`, and `relay` modes. `api` uses `ADS_WORKSPACE_LEARN_GITLAB_TOKEN` (or `GITLAB_TOKEN`); `relay` posts the analyzed learning payload to a devbox relay via `ADS_WORKSPACE_LEARN_RELAY_URL` and optional `ADS_WORKSPACE_LEARN_RELAY_SECRET`.
- Devbox relay: `python3 scripts/learn_publish_relay.py --port 19191` receives relay payloads and creates ads-workspace MRs using GitLab API when a token is configured, or the devbox Git remote when not. Use `ADS_WORKSPACE_LEARN_RELAY_DRY_RUN=true` for connectivity tests.
- This helper is intended for the Seatalkbot `/learn` command. It should only write reusable Paid Ads knowledge, not raw conversation logs or secrets.

**Rules (MUST follow):**
1. No `Agent` tool at L2 — run Confluence and `sra-kb-query` inline only.
2. Never hard-code installed skill paths such as `/root/.claude/skills/...` or `~/.cursor/skills/...`; always call local wrappers like `bash scripts/run_code_search.sh ...` and `bash scripts/search_confluence_recent.sh ...`.
3. Max 2 keyword attempts per layer; max 1 Confluence page fetch.
4. Confluence queries must use a rolling 12-month freshness filter. If you search via shell, use `bash scripts/search_confluence_recent.sh "<base-cql>" [limit]` so `lastModified >= "<today minus 12 months>"` is added automatically.
5. If a wrapper/preflight reports a missing dependency or credential issue, stop and surface that message directly instead of retrying with manual filesystem globbing.
6. No fabrication — no doc: mark "无相关文档"; no code: mark "无相关代码".
7. Do not use bot feedback or eval directories as business knowledge sources. In particular, never cite or rely on `docs/common/ops-log/knowledge-qa-ops/feedback/` or `docs/common/ops-log/knowledge-qa-ops/evals/` for Ads domain conclusions; those files are operational improvement inputs only.
8. For repo selection, use `docs/common/core-knowledge/03.ads-engine/01.system-architecture-overview.md` as the core repo standard. For code-search calls, treat that file as the source of search terms and expected index status, then always run `search-repo` and use the returned `name` as `repo`; never invent or reuse stale static slugs.
9. For OKR/KR/KP progress, status, project report, or "进展" requests, delegate to `ads-okr-epic-report` before any L2/L4 retrieval. For KP-level quick questions, use `/ads-okr-epic-report --query <kp>` only after the target is normalized to an exact KP id like `o3-kr6-kp2` or an `epic-file.md` path, so the report is returned in chat without writing files. `--query` is a slash-command/skill argument, not a Python script flag; do not call `scripts/check_freshness.py` to emulate query mode. If the target is ambiguous (for example "O3 KP2" can match multiple KRs), list the matching KP candidates and ask the user to choose; never invoke `/ads-okr-epic-report --query` with raw ambiguous text, do not guess, and do not use `ads-okr-epic-status-check-pa` unless the user explicitly asks for the PA-only status checker.
10. The canonical QA retrieval entrypoint is `docs/common/index-synthesis*.md`; it points to split atomic notes under `docs/common/core-knowledge/**`, `docs/common/readme/<repo>/`, and other curated docs. Source-repo README/docs are only optional fallback before L4.
11. When citing ads-workspace documents in the final answer, each cited file must be written either as a full repo-relative path starting with `docs/` or as its full absolute GitLab blob URL. Never output sibling-relative fragments such as `02.ads-strategy/foo.md`, `../foo.md`, or `同目录下的另一个文件.md`. If you cite multiple workspace docs, repeat the full `docs/...` path or full URL for every item.

**Delegate:** KP progress query→`ads-okr-epic-report --query` | KR/O report generation→`ads-okr-epic-report` | monitoring→`sp-grafana` | DW SQL/data→`sra-data-query` | release→`sra-release` | RESP→`ads-resp-lab` | AB→`sp-ab`

**Additional reference files (load only when needed):**
- [references/repos.md](references/repos.md) — core-repo-list-driven repo routing, code-search lookup query, and index-state notes (needed before L4 or optional source-repo docs fallback)
- [references/question-types.md](references/question-types.md) — intent classification, load only when intent is ambiguous
- [references/monitoring.md](references/monitoring.md) — Ads Engine dashboard IDs + PromQL examples (needed at L5)
