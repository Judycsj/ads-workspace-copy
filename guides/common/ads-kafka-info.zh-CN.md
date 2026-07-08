# Kafka Topic 信息查询 (ads-kafka-info) 使用指南

> **Language**: [English](ads-kafka-info.md) | [中文](ads-kafka-info.zh-CN.md)

发现和分析 CMDB 服务树下的 Kafka topic — 批量扫描、单点查询、L3 分组倒排、ChatOps 风格搜索。

**触发关键词**: "Kafka", "kafka topic", "kafka 扫描", "kafka 查询", "消息队列", "消费组", "Flink 任务", "SDU 消费者", "查 kafka"

---

## 场景 1: 批量扫描 paidads 下所有 Kafka topic

> **你**: `扫描一下 paidads 下面的所有 Kafka topic`
>
> **AI**: 发现 444 个 service → 查询 topic 绑定 → 去重 → 输出 9588 个 LIVE topic，包含分区数、保留时间、吞吐量、L3 分组。

```bash
export SPACE_TOKEN="eyJ..."
uv run scripts/kafka_info.py scan shopee.mp_search_recommendation_ads.paidads
uv run scripts/kafka_info.py scan shopee.mp_search_recommendation_ads.paidads --format csv -o report.csv
uv run scripts/kafka_info.py scan shopee.mp_search_recommendation_ads.paidads --env all  # 包含 TEST/UAT
```

### 扫描输出字段

| 字段 | 说明 |
|------|------|
| Topic Name | Kafka topic 名称 |
| Cluster | Kafka 集群 ID，如 `ks_deepData_live` |
| Env / AZ | 环境和可用区 |
| Partitions / Replicas | topic 配置 |
| Retention (h) | 数据保留时间（小时） |
| Produce/Consume Reserved (MB/s) | 预留吞吐量 |
| Bound Services | 绑定的 CMDB service（分号分隔） |
| L3 Group | 从 bound service 路径提取的 L3 分组 |
| OA L1 / L2 | 组织架构层级 |

### 去重逻辑

按 `(cluster_id, topic_name, az)` 去重。同一 topic 被多个 service 绑定时，合并所有 bound services 和 L3 groups。

---

## 场景 2: 单点查询一个 topic（含 SDU + Flink 详情）

> **你**: `查一下 online_bidding_logify_store_event-global-live 这个 topic 的详情`
>
> **AI**: 从 CMDB 找到 topic，再从 Knots 查询 SDU 生产/消费者和 Flink 任务。返回集群配置、分区数、保留时间、绑定 service、所有下游消费者。

```bash
uv run scripts/kafka_info.py lookup online_bidding_logify_store_event-global-live
uv run scripts/kafka_info.py lookup my-topic --tree-path shopee.mp_search_recommendation_ads
uv run scripts/kafka_info.py lookup my-topic -o topic_detail.json
```

### 输出结构

```json
{
  "topic_name": "...",
  "clusters": [{ "cluster_id": "...", "partition_num": 128, "retention_h": 12.0, ... }],
  "bound_services": ["shopee...online_bidding"],
  "l3_groups": ["ads_bidding"],
  "sdu_clients": [
    { "sdu": "onlinebidding-live-global", "role": "producer", "owner": ["amos.wu@shopee.com"] },
    { "sdu": "biddingstore-live-global", "role": "consumer", "consumer_groups": ["BiddingStoreConsumer"] }
  ],
  "flink_jobs": [
    { "application_name": "bidding_pipeline", "connector_type": "source", "flink_link": "https://..." }
  ]
}
```

### 使用场景

- **排查问题**: topic 消费延迟 → 找到所有消费者（SDU + Flink）→ 定位 owner
- **容量规划**: 查看 partition 数、retention、预留吞吐量是否合理
- **影响评估**: 修改 topic 配置前，查看有多少下游消费者会受影响

---

## 场景 3: 按 L3 分组查询 topic

> **你**: `ads_bidding 下面有哪些 Kafka topic？`
>
> **AI**: 运行 L3 倒排查询，列出所有绑定到 `ads_bidding` 下 service 的 topic。

```bash
uv run scripts/kafka_info.py group ads_bidding           # 指定 L3
uv run scripts/kafka_info.py group                        # 列出所有 L3 分组
uv run scripts/kafka_info.py group ads_retrieval --format csv -o retrieval.csv
```

### L3 提取规则

```
tree_path = shopee.mp_search_recommendation_ads.paidads
service   = shopee.mp_search_recommendation_ads.paidads.ads_bidding.product_ads.online_bidding
                                                        ^^^^^^^^^^^^
                                                        L3 = ads_bidding
```

### 使用场景

- **资源梳理**: 查看每个 L3 团队使用了多少 Kafka topic
- **成本优化**: 找到低使用率的 topic（partition 多但流量小）
- **架构审查**: 检查是否有 topic 被跨 L3 共享

---

## 场景 4: ChatOps 风格查询（按 cluster / topic / consumer group）

> **你**: `谁在消费 ks_deepData_live 上的 online_bidding_logify_store_event-global-live？`
>
> **AI**: 拉取全量 Knots 数据，建立倒排索引，按 cluster + topic 过滤，返回 SDU 消费者和 Flink 任务及 owner 信息。

```bash
# Level 1: 仅按集群
uv run scripts/kafka_info.py query ks_deepData_live

# Level 2: 集群 + topic
uv run scripts/kafka_info.py query ks_deepData_live online_bidding_logify_store_event-global-live

# Level 3: 集群 + topic + 消费组
uv run scripts/kafka_info.py query ks_deepData_live my-topic MyConsumerGroup
```

### 使用场景

- **消费 lag 排查**: 先查 cluster + topic 找到所有消费者 → 再按 consumer_group 定位
- **影响面评估**: 下线某 topic 前，查看有哪些 SDU / Flink 在使用
- **owner 查询**: 不确定谁负责某个 consumer_group → query 一步到位

---

## 数据源

所有 API 均为只读，通过 Space Bearer Token 认证。

| API | 来源 | 数据 | 大致数据量 |
|-----|------|------|-----------|
| Space CMDB `get_minified_tree` | 服务树 | 所有 service | ~10K services, ~3s |
| Space CMDB `get_kafka_topic_info` | 按 service | topic 绑定 | 20 线程并发, 200 个 svc ~30s |
| Knots `user_client_logs` | SDU 注册表 | 生产/消费 SDU | ~72K 条, ~30s |
| Knots `flink_job_list` | Flink 注册表 | Flink 任务关联 | ~11K 条, ~10s |

### 认证

```bash
# 方式 1: CLI 参数
uv run scripts/kafka_info.py --space-token "eyJ..." scan ...

# 方式 2: 环境变量
export SPACE_TOKEN="eyJ..."
uv run scripts/kafka_info.py scan ...
```

Token 获取: https://space.shopee.io → 右上角头像 → Copy Token。有效期约 24 小时。同一个 token 同时用于 Space CMDB 和 Knots API（共享 SSO）。

### API 详细参考

完整的 API 请求/响应 schema，见 `guides/common/ads-kafka-info/data-sources.md`。
