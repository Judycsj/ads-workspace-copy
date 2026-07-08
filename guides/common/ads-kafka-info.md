# Kafka Topic Info (ads-kafka-info) Guide

> **Language**: [English](ads-kafka-info.md) | [中文](ads-kafka-info.zh-CN.md)

Discover and analyze Kafka topics under a CMDB service tree — batch scan, single topic deep dive, L3 group reverse index, and ChatOps-style search.

**Trigger keywords**: "Kafka", "kafka topic", "kafka scan", "kafka lookup", "mq", "consumer group", "Flink job", "SDU consumer", "kafka info"

---

## Scenario 1: Batch scan all Kafka topics under paidads

> **You**: `Scan all Kafka topics under paidads`
>
> **AI**: Discovers 444 services → queries topic bindings → deduplicates → outputs 9588 LIVE topics with partitions, retention, throughput, L3 groups.

```bash
export SPACE_TOKEN="eyJ..."
uv run scripts/kafka_info.py scan shopee.mp_search_recommendation_ads.paidads
uv run scripts/kafka_info.py scan shopee.mp_search_recommendation_ads.paidads --format csv -o report.csv
uv run scripts/kafka_info.py scan shopee.mp_search_recommendation_ads.paidads --env all  # include TEST/UAT
```

### Scan output fields

| Field | Description |
|-------|-------------|
| Topic Name | Kafka topic name |
| Cluster | Kafka cluster ID, e.g. `ks_deepData_live` |
| Env / AZ | Environment and availability zone |
| Partitions / Replicas | Topic configuration |
| Retention (h) | Data retention in hours |
| Produce/Consume Reserved (MB/s) | Reserved throughput |
| Bound Services | CMDB services bound to the topic (semicolon-separated) |
| L3 Group | L3 service group extracted from bound service path |
| OA L1 / L2 | Organization hierarchy |

### Deduplication

Topics are deduplicated by `(cluster_id, topic_name, az)`. A topic bound to multiple services is listed once with all bound services and L3 groups merged.

---

## Scenario 2: Look up a single topic (SDU + Flink details)

> **You**: `Look up topic online_bidding_logify_store_event-global-live`
>
> **AI**: Finds the topic in CMDB, then queries Knots for SDU producers/consumers and Flink jobs. Returns cluster config, partition count, retention, bound services, and all downstream consumers.

```bash
uv run scripts/kafka_info.py lookup online_bidding_logify_store_event-global-live
uv run scripts/kafka_info.py lookup my-topic --tree-path shopee.mp_search_recommendation_ads
uv run scripts/kafka_info.py lookup my-topic -o topic_detail.json
```

### Lookup output structure

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

### Use cases

- **Troubleshooting**: Topic lag → find all consumers (SDU + Flink) → locate owner
- **Capacity planning**: Check partition count, retention, reserved throughput
- **Impact assessment**: Before modifying a topic, see how many downstream consumers would be affected

---

## Scenario 3: List topics by L3 group

> **You**: `What Kafka topics does ads_bidding use?`
>
> **AI**: Runs L3 reverse index, lists all topics bound to services under `ads_bidding`.

```bash
uv run scripts/kafka_info.py group ads_bidding           # specific L3
uv run scripts/kafka_info.py group                        # list all L3 groups
uv run scripts/kafka_info.py group ads_retrieval --format csv -o retrieval.csv
```

### L3 extraction rule

```
tree_path = shopee.mp_search_recommendation_ads.paidads
service   = shopee.mp_search_recommendation_ads.paidads.ads_bidding.product_ads.online_bidding
                                                        ^^^^^^^^^^^^
                                                        L3 = ads_bidding
```

### Use cases

- **Resource audit**: How many topics does each L3 team own?
- **Cost optimization**: Find low-usage topics (many partitions, little traffic)
- **Architecture review**: Check for cross-L3 topic sharing

---

## Scenario 4: ChatOps-style query (cluster / topic / consumer group)

> **You**: `Who is consuming from ks_deepData_live on topic online_bidding_logify_store_event-global-live?`
>
> **AI**: Fetches full Knots data, builds inverted index, filters by cluster + topic, returns SDU consumers and Flink jobs with owner info.

```bash
# Level 1: by cluster only
uv run scripts/kafka_info.py query ks_deepData_live

# Level 2: cluster + topic
uv run scripts/kafka_info.py query ks_deepData_live online_bidding_logify_store_event-global-live

# Level 3: cluster + topic + consumer group
uv run scripts/kafka_info.py query ks_deepData_live my-topic MyConsumerGroup
```

### Use cases

- **Consumer lag investigation**: Find all consumers for a topic → narrow down by consumer group
- **Impact assessment**: Before decommissioning a topic, list all SDUs and Flink jobs using it
- **Owner discovery**: Find who is responsible for a specific consumer group

---

## Data Sources

All APIs are read-only and authenticated with Space Bearer Token.

| API | Source | Data | Approx. Volume |
|-----|--------|------|-----------------|
| Space CMDB `get_minified_tree` | Service tree | All services | ~10K services, ~3s |
| Space CMDB `get_kafka_topic_info` | Per-service | Topic bindings | 20-thread parallel, ~30s for 200 svcs |
| Knots `user_client_logs` | SDU registry | Producer/consumer SDUs | ~72K records, ~30s |
| Knots `flink_job_list` | Flink registry | Flink job associations | ~11K records, ~10s |

### Authentication

```bash
# Option 1: CLI argument
uv run scripts/kafka_info.py --space-token "eyJ..." scan ...

# Option 2: Environment variable
export SPACE_TOKEN="eyJ..."
uv run scripts/kafka_info.py scan ...
```

Token source: https://space.shopee.io → avatar (top-right) → Copy Token. Valid for ~24 hours. The same token works for both Space CMDB and Knots APIs (shared SSO).

### API reference

For detailed API request/response schemas, see the data-sources reference in `guides/common/ads-kafka-info/data-sources.md`.
