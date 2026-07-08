# CacheCloud 集群信息查询 (ads-cachecloud-info) 使用指南

> **Language**: [English](ads-cachecloud-info.md) | [中文](ads-cachecloud-info.zh-CN.md)

发现和分析 CMDB 服务树下的 CacheCloud (Redis) 集群 — 批量扫描含 QPS、单点查询、L3 分组倒排、cacheName 与 domain 双向解析。

**触发关键词**: "CacheCloud", "cachecloud 扫描", "Redis 集群", "redis qps", "集群列表", "L3 分组", "查 cachecloud", "查 redis 集群", "domain", "域名", "cache domain", "cacheName", "resolve"

---

## 场景 1: 批量扫描 paidads 下所有 CacheCloud 集群

> **你**: `扫描一下 paidads 下面的所有 CacheCloud 集群`
>
> **AI**: 发现所有叶子 service → 查询集群绑定 → 去重 → 查 Grafana proxy QPS → 输出含 L3 分组和 owner 信息的报告。

```bash
export SPACE_TOKEN="eyJ..."
export GRAFANA_KEY="eyJ..."

# 全量扫描含 QPS（Grafana 查询约 2-5 分钟）
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads

# 仅包含 paidads 自有集群（排除跨租户 ACL 集群）
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads --owner-only

# 快速模式：跳过 QPS（只需 Space token）
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads --skip-qps

# CSV 输出
uv run scripts/cachecloud_info.py scan shopee.mp_search_recommendation_ads.paidads --format csv -o report.csv
```

### 扫描输出字段

| 字段 | 说明 |
|------|------|
| CacheCloud Cluster | 集群名称 |
| Bound Services | 绑定的 CMDB service（分号分隔） |
| QPS | Grafana proxy QPS（跳过时显示 `N/A`） |
| Monitoring Link | Grafana 监控面板链接 |
| Owner Service / Tenant | 实际集群 owner（区别于 ACL 访问权限） |
| Cluster Owner | Owner 邮箱 |
| L3 Group | 从 bound service 路径提取的 L3 分组 |

### 跨租户集群说明

Space `/cache/v1/api/clusters` API 返回的是 service 有 **ACL 访问权限** 的所有集群，而非仅 **拥有** 的集群。使用 `--owner-only` 或检查 `Owner Tenant` 字段来区分。

---

## 场景 2: 单点查询一个集群

> **你**: `查一下 deep.paidads.campaign.campaign 这个 CacheCloud 集群`
>
> **AI**: 返回 QPS、命令分布、proxy/shard 数量、内存、绑定 service、监控链接。

```bash
uv run scripts/cachecloud_info.py lookup deep.paidads.campaign.campaign
uv run scripts/cachecloud_info.py lookup deep.paidads.campaign.campaign -o detail.json
```

### 输出结构

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

### 使用场景

- **容量评估**: 查看 QPS、内存、shard 数量，判断是否需要扩缩容
- **成本审计**: 找到低 QPS 集群，评估是否可以合并
- **故障排查**: 快速获取问题集群的监控链接和 owner

---

## 场景 3: 按 L3 分组查询集群

> **你**: `ads_retrieval 下面有哪些 CacheCloud 集群？`
>
> **AI**: 运行 L3 倒排查询，列出 `ads_retrieval` 下所有集群及其 QPS 和监控链接。

```bash
uv run scripts/cachecloud_info.py group ads_retrieval        # 指定 L3
uv run scripts/cachecloud_info.py group                       # 所有 L3 分组
uv run scripts/cachecloud_info.py group ads_bidding --format csv -o bidding.csv
uv run scripts/cachecloud_info.py group ads_retrieval --skip-qps  # 快速模式
```

### L3 提取规则

```
tree_path = shopee.mp_search_recommendation_ads.paidads
service   = shopee.mp_search_recommendation_ads.paidads.ads_retrieval.vespa.recall_engine
                                                        ^^^^^^^^^^^^^^
                                                        L3 = ads_retrieval
```

---

## 场景 4: cacheName ↔ domain 双向解析

> **你**: `查一下 deep.paidads.search.searchads.bidding.simple_mode.live.sg_acl 的 domain`
>
> **AI**: 扫描 CMDB 集群绑定，按 cacheName 匹配，返回 domain。

> **你**: `pnj5j.elasticredis.cloud.shopee.io 对应哪个 cache 集群？`
>
> **AI**: 扫描 CMDB 集群绑定，按 domain 匹配，返回 cacheName。

```bash
# cacheName → domain
uv run scripts/cachecloud_info.py resolve deep.paidads.search.searchads.bidding.simple_mode.live.sg_acl

# domain → cacheName
uv run scripts/cachecloud_info.py resolve pnj5j.elasticredis.cloud.shopee.io

# 带端口的 domain（自动去除端口）
uv run scripts/cachecloud_info.py resolve pnj5j.elasticredis.cloud.shopee.io:10004

# 自定义服务树路径
uv run scripts/cachecloud_info.py resolve pnj5j.elasticredis.cloud.shopee.io --tree-path shopee.mp_search_recommendation_ads
```

### 输出结构

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

### 输入自动识别

- 包含 `.elasticredis.` 或 `cloud.shopee.io` → 视为 **domain**，解析为 cacheName
- 否则 → 视为 **cacheName**，解析为 domain

### 使用场景

- **配置查询**: 在代码/配置中看到 cache 集群名，需要找到对应的 Redis 连接域名
- **故障排查**: 从日志/告警中拿到 domain，需要找到对应的 cache 集群
- **交叉验证**: 迁移或排查时验证 cacheName ↔ domain 映射关系

---

## 数据源

| API | 说明 | 认证 |
|-----|------|------|
| Space CMDB `get_minified_tree` | 服务树发现 | Space token |
| Space CMDB `/cache/v1/api/clusters` | 按 service 查询 CacheCloud 集群绑定 | Space token |
| Grafana `cachecloud-eks-live` | 通过 PromQL 查询 proxy QPS (orgId=9) | Grafana API key |

### 认证

```bash
# Space token: space.shopee.io → 右上角头像 → Copy Token（有效期约 24h）
export SPACE_TOKEN="eyJ..."

# Grafana API key: orgId=9 的 API key，用于 cachecloud-eks-live 数据源
export GRAFANA_KEY="eyJ..."

# 或通过 CLI 参数传入
uv run scripts/cachecloud_info.py --space-token "eyJ..." --grafana-key "eyJ..." scan ...
```

### 监控链接格式

```
https://monitoring.infra.sz.shopee.io/grafana/d/P6laqgyVz/cache-on-k8s
  ?orgId=1&var-datasource=cachecloud-eks-live
  &var-cluster={cluster_name}&var-pool={pool}
```

### 性能说明

- 全量扫描含 QPS: 2-5 分钟（Grafana 每个 pool 间隔 300ms）
- 使用 `--skip-qps` 快速迭代，`--qps-cache` 复用之前的 QPS 数据
- Space CMDB 查询 20 线程并发
