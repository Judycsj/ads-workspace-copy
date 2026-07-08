# Ads Knowledge Q&A Repo Routing

Use `docs/common/index-synthesis*.md` to locate repo README atomic notes first.
For L4 repo routing, use `docs/common/core-knowledge/03.ads-engine/01.system-architecture-overview.md`
(`Core Repository List`) as the source of truth for core Ads repos. Do not use the previous Google Doc repo list.

This file is only a retrieval aid. When the core knowledge repo list changes, trust
that source first and update this table later.

## L4 / Optional Source-Repo Docs Resolution

1. Find the candidate repo in `docs/common/core-knowledge/03.ads-engine/01.system-architecture-overview.md`.
2. Use the GitLab path from that row as the default code-search query.
3. Run `search-repo` and use the returned `name` as the `repo` parameter.
4. Prefer an exact returned name matching `gitlab/<GitLab path>`.
5. If exact repo is not returned, do not invent a slug; stay with ads-workspace
   docs/Confluence/KP sources or ask whether a related indexed repo is acceptable.

```bash
# Locate the README/core repo atomic note through the index first.
rg -n "ads-engine|online-bidding|paidads-recall" docs/common/index-synthesis.zh-CN.md docs/common/index-synthesis.md

# Locate the core repo section.
Read("docs/common/core-knowledge/03.ads-engine/01.system-architecture-overview.md")

# Resolve a repo before source-repo docs/code search.
bash scripts/run_code_search.sh search-repo '{"query": "shopee/deep/ads-engine", "limit": 10}'
```

`code-search` index state is operational data and can change. The table below was
verified through `search-repo` on 2026-05-19 using the GitLab path from the core repo list as
the query. Re-run `search-repo` when precision matters or a query fails.

Current no-exact-slug repo:
- `scoringX` (`shopee/deep/scoringX`): GitLab path query returns `scoringx-client` / `scoringx-expl`, not the core repo.

## Core Repo Lookup Table

| Repo in core list | GitLab path from doc | code-search query | Expected index state | Notes |
|---|---|---|---|---|
| ads-engine | `shopee/deep/ads-engine` | `shopee/deep/ads-engine` | indexed exact | Use the exact returned `name`. |
| online-bidding | `shopee/deep/paidads-bidding/online-bidding` | `shopee/deep/paidads-bidding/online-bidding` | indexed exact | Use the exact returned `name`. |
| paidads-recall | `shopee/deep/paidads-recall` | `shopee/deep/paidads-recall` | indexed exact | Use the exact returned `name`. |
| bidding-store | `shopee/deep/paidads-bidding/bidding-store` | `shopee/deep/paidads-bidding/bidding-store` | indexed exact | Use the exact returned `name`. |
| ultrav-core-timewindow | `shopee/deep/paidads-bidding/ultrav-core-timewindow` | `shopee/deep/paidads-bidding/ultrav-core-timewindow` | indexed exact | Use the exact returned `name`. |
| ultrav-data-processor | `shopee/deep/paidads-bidding/ultrav-data-processor` | `shopee/deep/paidads-bidding/ultrav-data-processor` | indexed exact | Use the exact returned `name`. |
| hyperx | `shopee/deep/HyperX-config` | `shopee/deep/HyperX-config` | indexed exact | Use the exact returned `name`. |
| paidads-indexer | `shopee/deep/paidads-indexer` | `shopee/deep/paidads-indexer` | indexed exact | Exact repo may not be the first fuzzy result; select the exact path returned by `search-repo`. |
| paidads-graph-indexer | `shopee/deep/indexer/paidads-graph-indexer` | `shopee/deep/indexer/paidads-graph-indexer` | indexed exact | Use the exact returned `name`. |
| paidads-schema | `shopee/deep/paidads-schema` | `shopee/deep/paidads-schema` | indexed exact | Use the exact returned `name`. |
| paidads-valar | `shopee/deep/paidads-valar` | `shopee/deep/paidads-valar` | indexed exact | Use the exact returned `name`. |
| paidads-tracking | `shopee/deep/paidads-tracking` | `shopee/deep/paidads-tracking` | indexed exact | Exact repo can be returned beside `paidads-tracking-proto`; select the exact path returned by `search-repo`. |
| paidads-deduction | `shopee/deep/paidads-deduction` | `shopee/deep/paidads-deduction` | indexed exact | Exact repo can be returned after offline/prededuction repos; select the exact path returned by `search-repo`. |
| paidads-report-ng | `shopee/deep/paidads-report-ng` | `shopee/deep/paidads-report-ng` | indexed exact | Use the exact returned `name`. |
| paidads-superkia | `shopee/deep/paidads-superkia` | `shopee/deep/paidads-superkia` | indexed exact | Use the exact returned `name`. |
| oh-my-embedding | `shopee/deep/oh-my-embedding` | `shopee/deep/oh-my-embedding` | indexed exact | Use the exact returned `name`. |
| scoringX | `shopee/deep/scoringX` | `shopee/deep/scoringX` | not indexed exact | `search-repo` returned `scoringx-client` / `scoringx-expl`, not the core `scoringX` repo. Use docs/Confluence unless a related repo is explicitly acceptable. |
| ads_service | `shopee/deep/ads_service` | `shopee/deep/ads_service` | indexed exact | Exact repo can be returned beside `ultimate_ads_service`; select the exact path returned by `search-repo`. |
| ultimate_ads_service | `shopee/deep/ultimate_ads_service` | `shopee/deep/ultimate_ads_service` | indexed exact | Use the exact returned `name`. |
| tag-service | `shopee/deep/tag-service` | `shopee/deep/tag-service` | indexed exact | Use the full path query; bare `tag-service` can return unrelated services first. |
| ads-status-syncer | `shopee/deep/ads-status-syncer` | `shopee/deep/ads-status-syncer` | indexed exact | Use the exact returned `name`. |
| paidads-gdsclient | `shopee/deep/paidads-gdsclient` | `shopee/deep/paidads-gdsclient` | indexed exact | Use the exact returned `name`. |
| topup | `shopee/deep/topup` | `shopee/deep/topup` | indexed exact | Use the full path query; bare `topup` returns unrelated repos first. |
| adsengine-abtest-param | `shopee/deep/adsengine-abtest-param` | `shopee/deep/adsengine-abtest-param` | indexed exact | Use the exact returned `name`. |
| graph-manager-conf | `shopee/deep/searchads/graph-manager-conf` | `shopee/deep/searchads/graph-manager-conf` | indexed exact | Use the exact returned `name`. |

## Keyword Routing Hints

Use these hints only to pick a candidate row from the core repo list. The row's GitLab path remains
the code-search query source.

| Topic | Prefer repo rows |
|---|---|
| Engine API0/API1/API2/API3/API4, GraphEngine operators, DAG runtime | `ads-engine`, `graph-manager-conf` |
| Bidding, ROI2/ROI3, oCPX, bid price, coefficient lookup | `online-bidding`, `bidding-store`, `ultrav-core-timewindow`, `ultrav-data-processor` |
| Recall, KNN, KV recall, embedding retrieval | `paidads-recall`, `oh-my-embedding` |
| Index, AdsInfo, Vespa schema, index job | `paidads-indexer`, `paidads-graph-indexer`, `paidads-valar`, `paidads-schema` |
| Tracking, deduction, attribution, report pipeline | `paidads-tracking`, `paidads-deduction`, `paidads-report-ng` |
| Advertiser platform CRUD, UAS/AAAS, status, balance, topup | `ultimate_ads_service`, `ads_service`, `ads-status-syncer`, `topup` |
| AB experiment params | `adsengine-abtest-param` |
