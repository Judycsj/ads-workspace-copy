# CacheCloud Cluster Info (ads-cachecloud-info) Guide

> **Language**: [English](ads-cachecloud-info.md) | [中文](ads-cachecloud-info.zh-CN.md)

Discover and analyze CacheCloud (Redis) clusters under a CMDB service tree — batch scan with QPS, single cluster deep dive, L3 group reverse index, and cacheName/domain bi-directional resolve.

**Trigger keywords**: "CacheCloud", "cachecloud scan", "Redis cluster", "redis qps", "cache cluster list", "L3 group", "cachecloud lookup", "domain", "cache domain", "cacheName", "resolve"

---

## Scenario 1: Batch scan all CacheCloud clusters under paidads

> **You**: `Scan all CacheCloud clusters under paidads`
>
> **AI**: Discovers all leaf services → queries cluster bindings → deduplicates → queries Grafana for proxy QPS → outputs report with L3 groups and owner info.

```bash
export SPACE_TOKEN="eyJ..."
export GRAFANA_KEY="eyJ..."

# Full scan with QPS (2-5 min for Grafana queries)
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads

# Only paidads-owned clusters (exclude cross-tenant ACL clusters)
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads --owner-only

# Fast mode: skip QPS (only Space token needed)
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads --skip-qps

# CSV output
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads --format csv -o report.csv
```

### Scan output fields

| Field | Description |
|-------|-------------|
| CacheCloud Cluster | Cluster name |
| Bound Services | CMDB services bound to the cluster (semicolon-separated) |
| QPS | Proxy QPS from Grafana (or `N/A` if skipped) |
| Monitoring Link | Grafana dashboard link for the cluster |
| Owner Service / Tenant | Actual cluster owner (vs. ACL access) |
| Cluster Owner | Owner email |
| L3 Group | L3 service group extracted from bound service path |

### Cross-tenant clusters

The Space `/cache/v1/api/clusters` API returns all clusters a service has **ACL access** to, not just clusters it **owns**. Use `--owner-only` or check `Owner Tenant` to distinguish.

---

## Scenario 2: Look up a single cluster

> **You**: `Look up CacheCloud cluster deep.paidads.campaign.campaign`
>
> **AI**: Returns QPS, command breakdown, proxy/shard count, memory, bound services, monitoring link.

```bash
uv run scripts/cachecloud_info.py lookup deep.paidads.campaign.campaign
uv run scripts/cachecloud_info.py lookup deep.paidads.campaign.campaign -o detail.json
```

### Lookup output structure

```json
{
  "cluster_name": "deep.paidads.campaign.campaign",
  "owner_service": "shopee...campaign",
  "owner_tenant": "paidads",
  "cluster_owner": "user@shopee.com",
  "l3_groups": ["ads_bidding"],
  "bound_services": ["svc1", "svc2"],
  "qps_total": 16.16,
  "qps_by_command": {"GET": 10.5, "SET": 3.2, "MGET": 2.46},
  "proxy_count": 2,
  "shard_count": 4,
  "shard_mem_gb": 1.23,
  "monitoring_link": "https://monitoring.infra.sz.shopee.io/grafana/d/P6laqgyVz/..."
}
```

### Use cases

- **Capacity review**: Check QPS, memory usage, shard count for right-sizing
- **Cost audit**: Find low-QPS clusters that could be consolidated
- **Incident triage**: Get monitoring link and owner info for a problematic cluster

---

## Scenario 3: List clusters by L3 group

> **You**: `What CacheCloud clusters does ads_retrieval use?`
>
> **AI**: Runs L3 reverse index, lists all clusters under `ads_retrieval` with QPS and monitoring links.

```bash
uv run scripts/cachecloud_info.py group ads_retrieval        # specific L3
uv run scripts/cachecloud_info.py group                       # all L3 groups
uv run scripts/cachecloud_info.py group ads_bidding --format csv -o bidding.csv
uv run scripts/cachecloud_info.py group ads_retrieval --skip-qps  # fast mode
```

### L3 extraction rule

```
tree_path = shopee.mp_search_recommendation_ads.paidads
service   = shopee.mp_search_recommendation_ads.paidads.ads_retrieval.vespa.recall_engine
                                                        ^^^^^^^^^^^^^^
                                                        L3 = ads_retrieval
```

---

## Scenario 4: Resolve cacheName ↔ domain

> **You**: `What's the domain for deep.paidads.search.searchads.bidding.simple_mode.live.sg_acl?`
>
> **AI**: Scans CMDB cluster bindings, matches by cacheName, returns the domain.

> **You**: `Which cache cluster uses domain pnj5j.elasticredis.cloud.shopee.io?`
>
> **AI**: Scans CMDB cluster bindings, matches by domain, returns the cacheName.

```bash
# cacheName → domain
uv run scripts/cachecloud_info.py resolve deep.paidads.search.searchads.bidding.simple_mode.live.sg_acl

# domain → cacheName
uv run scripts/cachecloud_info.py resolve pnj5j.elasticredis.cloud.shopee.io

# domain with port (port stripped automatically)
uv run scripts/cachecloud_info.py resolve pnj5j.elasticredis.cloud.shopee.io:10004

# Custom tree path
uv run scripts/cachecloud_info.py resolve pnj5j.elasticredis.cloud.shopee.io --tree-path shopee.mp_search_recommendation_ads
```

### Resolve output

```json
{
  "cluster_name": "deep.paidads.search.searchads.bidding.simple_mode.live.sg_acl",
  "domain": "pnj5j.elasticredis.cloud.shopee.io:10004",
  "pool": "cachecloud-live-sg-b2",
  "env": "live",
  "region": "sg",
  "owner_service": "shopee...paidads...",
  "cluster_owner": "amos.wu@shopee.com",
  "monitoring_link": "https://monitoring.infra.sz.shopee.io/grafana/d/P6laqgyVz/..."
}
```

### Input auto-detection

- Contains `.elasticredis.` or `cloud.shopee.io` → treated as **domain**, resolves to cacheName
- Otherwise → treated as **cacheName**, resolves to domain

### Use cases

- **Config lookup**: Find the Redis connection domain for a cache cluster name in code/config
- **Incident triage**: Got a domain from logs/alerts, need to find which cache cluster it belongs to
- **Cross-referencing**: Verify cacheName ↔ domain mapping during migration or troubleshooting

---

## Data Sources

| API | Description | Auth |
|-----|-------------|------|
| Space CMDB `get_minified_tree` | Service tree discovery | Space token |
| Space CMDB `/cache/v1/api/clusters` | CacheCloud cluster bindings per service | Space token |
| Grafana `cachecloud-eks-live` | Proxy QPS via PromQL (orgId=9) | Grafana API key |

### Authentication

```bash
# Space token: space.shopee.io → avatar → Copy Token (~24h validity)
export SPACE_TOKEN="eyJ..."

# Grafana API key: orgId=9 API key for cachecloud-eks-live datasource
export GRAFANA_KEY="eyJ..."

# Or pass via CLI
uv run scripts/cachecloud_info.py --space-token "eyJ..." --grafana-key "eyJ..." scan ...
```

### Monitoring link format

```
https://monitoring.infra.sz.shopee.io/grafana/d/P6laqgyVz/cache-on-k8s
  ?orgId=1&var-datasource=cachecloud-eks-live
  &var-cluster={cluster_name}&var-pool={pool}
```

### Performance notes

- Full scan with QPS: 2-5 min (300ms delay between Grafana pool queries)
- Use `--skip-qps` for fast iterations, `--qps-cache` to reuse previous results
- Space CMDB queries parallelized (20 threads)
