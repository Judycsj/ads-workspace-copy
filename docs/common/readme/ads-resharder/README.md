<!-- ads-workspace-gdoc-sync: gdoc_id=1dqIAY1m3uZW_Uf6MC9vaHM1JianzsIRYhk4H_WfH7oM gdoc_url=https://docs.google.com/document/d/1dqIAY1m3uZW_Uf6MC9vaHM1JianzsIRYhk4H_WfH7oM/edit -->

# ads-resharder

> **Git repository:** https://git.garena.com/shopee/deep/ads-resharder  
> **PIC:** Zhining | **Team:** Data Support (Advertiser Platform)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Architecture](#architecture)
   - [Service Topology](#service-topology)
4. [Directory Structure](#directory-structure)
5. [SPEX and Modules](#spex-and-modules)
   - [API Overview](#api-overview)
   - [Resharding Jobs](#resharding-jobs)
6. [Cronjobs](#cronjobs)
7. [Development Guidelines](#development-guidelines)
   - [Code Style](#code-style)
   - [Project Structure](#project-structure)
   - [Naming Conventions](#naming-conventions)
   - [Error Handling](#error-handling)
   - [Unit Testing Standards](#unit-testing-standards)
   - [Code Review & Git Workflow](#code-review--git-workflow)
8. [Configuration](#configuration)
   - [Config Files](#config-files)
   - [SPEX and spcli Setup](#spex-and-spcli-setup)
9. [Deployment](#deployment)
   - [Build for Production](#build-for-production)
   - [Release Process](#release-process)
10. [Monitoring](#monitoring)
11. [Business Terminology Glossary](#business-terminology-glossary)
    - [Core Metrics](#core-metrics)
    - [Ad Types and Products](#ad-types-and-products)
    - [Placements & Entrances](#placements--entrances)
    - [Sellers & Advertisers](#sellers--advertisers)
    - [Bidding & Pricing](#bidding--pricing)
    - [Prediction & Models](#prediction--models)
    - [System Features & Services](#system-features--services)
    - [Ad Supply & Display](#ad-supply--display)
    - [Controls & Filtering](#controls--filtering)
    - [External Services & Systems](#external-services--systems)
    - [Technical Terms](#technical-terms)
12. [Additional Resources](#additional-resources)
13. [Frequently Asked Questions](#frequently-asked-questions)

---

## Introduction

`ads-resharder` is a stateless Go streaming service within the Shopee Advertiser Platform. It sits between the raw MySQL Binlog CDC Kafka topics and the downstream consumers (indexers, billing, SRM, marketing services), performing **Resharding / 分片**: re-routing per-region, sharded database CDC events onto logical, per-country Kafka topics with a consistent partitioning strategy.

The service supports two parallel consumer paths controlled by runtime feature flags:

- **KJC path** (`kafka_job_client`): legacy GDS client, currently active alongside EKL.
- **EKL path** (`enhanced-kafka-lib` + Muse): newer CDC consumer framework, enabled via `enable-ekl: true`.

Both paths produce to the same set of destination Kafka topics.

---

## Features

- **Multi-region CDC fan-in**: Consumes binlog events from `shopee_ads_xx_db` (TH, TW, SG, ID, PH, MY, VN, BR), `shopee_ads_srm`, `shopee_ads_marketing` (Panama CDC), `shopee_ads_balance_*` (Balance DB via EKL, consumer config from Config Center), and per-region-per-shard `shopee_order_core_*` topics (up to 100 shards × 10 countries).
- **Prehashing for ordered delivery**: Applies a custom hash function on shard key fields (e.g. `userid`, `campaignid`, `account_id`) so that related records for the same entity always land on the same Kafka partition, preserving order.
- **Per-country fan-out**: Routes processed records to country-scoped topics (`ads_gds_{CID}`) and order topics (`shopee_order_gds_{CID}_live`), plus a marketplace-wide topic (`shopee_marketplace_gds_ads_resharder`).
- **35+ table types handled**: Covers the full Ads Core DB schema — campaigns, advertisements, keywords, translogs, credits, V3 credit/balance tables, audit logs — plus Balance DB CDC, SRM, marketing, and order data.
- **Dual-mode consumer**: KJC and EKL paths run concurrently; KJC can be disabled independently via `disable-kjc: true`.
- **Balance DB CDC (EKL)**: `shopee_ads_balance_*` DB binlog events are consumed exclusively via the EKL path with consumer config managed through Config Center (`kafka_config`). Five V3 credit/balance tables (`ads_credit_v3_tab`, `frozen_ads_credit_v3_tab`, `ads_credit_expense_tab`, `translog_v3_tab`, `campaign_daily_expense_tab`) and `topup_translog_tab` from the Balance DB route to a dedicated `balance_producer`. Balance DB `topup_translog_tab` uses job type string `ads_balance_topup_translog`, distinct from the Ads Core DB path (`ads_topup_translog`).
- **Config-center-driven hot reload**: Kafka topology (`kafka_config`) and performance tuning (`performance_param`) are loaded from Config Center namespace `resharder_live_default` and updated without restart.
- **Prometheus instrumentation**: Exposes per-table, per-command counters, processing latency histograms, and end-to-end latency under `paidads_resharder_*` and `paidads_ekl_resharder_*` namespaces.
- **SPEX integration**: Registered as SPEX service `paidads.resharder` (env: live, tag: master); exposes `/ping` and `/smoketest` HTTP endpoints via `paidads-platform-lib/app`.

---

## Architecture

The following diagram shows the data flow through ads-resharder:

```
MySQL Databases (per region, sharded)
  ├── shopee_ads_xx_db (TH/TW/SG/ID/PH/MY/VN/BR)   ─┐
  ├── shopee_ads_srm                                   │  Binlog
  ├── shopee_ads_marketing (Panama CDC)                │  CDC
  ├── shopee_ads_balance_*_db (per region, EKL only)  │  Kafka
  └── shopee_order_core_{CID}_db_00000000~N            │  Kafka
                                                       ▼
                              ┌───────────────────────────────────────┐
                              │           ads-resharder               │
                              │                                       │
                              │  ┌──────────┐   ┌───────────────┐    │
  Source Kafka Topics ───────►│  │ KJC Path │   │   EKL Path    │    │
  (GDS / Panama CDC)          │  │(kjc client│  │(enhanced-kafka│    │
                              │  │ + preHash)│  │  lib + Muse)  │    │
                              │  └────┬─────┘   └──────┬────────┘    │
                              │       │                 │             │
                              │  TableManager ◄─────────┘            │
                              │  WriterManager                        │
                              │  ConfigGetter (Config Center)        │
                              └───────────────────────────────────────┘
                                               │
                     ┌─────────────────────────┼──────────────────────┐
                     ▼                         ▼                      ▼
          ads_gds_{CID}              shopee_marketplace_gds    shopee_order_gds
          (per country:              _ads_resharder             _{CID}_live /
           tw/br/sg/id/              (single topic)             shopee_order_gds
           ph/th/my/vn/                                         _live
           mx/co/cl)
                     │
                     ▼
          Downstream consumers:
          ads-indexer, ads_service, ultimate_ads_service,
          ads-status-syncer, ads-account-balance, ...
```

### Service Topology

**Upstream (CDC sources)**

| Service / DB | Protocol | Description |
|---|---|---|
| `shopee_ads_xx_db` (TH/TW/SG/ID/PH/MY/VN/BR) | Kafka (GDS, KJC) | Main Ads Core DB binlog via `db_shopee_ads_{cid}` topics |
| `shopee_ads_srm` | Kafka (GDS, KJC) | SRM DB binlog via `db_shopee_ads_srm` topic |
| `shopee_ads_marketing` | Kafka (Panama CDC, SASL) | Marketing DB binlog via `panama_live_shopee_ads_marketing_{cid}_db` topics |
| `shopee_ads_balance_*` (per region) | Kafka (EKL + Muse) | Balance DB Binlog; consumer config from Config Center `kafka_config`. Tables: `ads_credit_v3_tab`, `frozen_ads_credit_v3_tab`, `ads_credit_expense_tab`, `translog_v3_tab`, `campaign_daily_expense_tab`, `topup_translog_tab` |
| `shopee_order_core_{cid}_db` | Kafka (Panama CDC, SASL) | Order DB binlog, up to 100 shards per country for non-LATAM; 1 shard for LATAM |
| Config Center | HTTPS | Hot-reload of `kafka_config` and `performance_param` from `resharder_live_default` |

**Downstream (output topics)**

| Topic pattern | Description |
|---|---|
| `ads_gds_{CID}` | Per-country ads CDC events for indexers and platform services |
| `shopee_marketplace_gds_ads_resharder` | Marketplace-wide topic for marketing tables (daily budget prompt, campaign day) |
| `shopee_order_gds_live` | Global order events (non-LATAM) |
| `shopee_order_gds_{CID}_live` / `shopee_order_gds-{CID}-live` | Per-country order events for BR, MX, CO, CL, AR |

All destination topics land on `kafka.ks_paidads_live.ap-sg-1-general-a.live.mq.shopee.io:9092`.

**Dependencies**

| Dependency | Protocol | Usage |
|---|---|---|
| `ads-db-lib` | Go library | Protobuf schema definitions (`beeshop_ads.proto`, `adsdblib.proto`) |
| `proto_parser` / `dbmap` | Go library | CDC record unmarshalling and DB map |
| `kafka_job_client` (KJC) | Go library | Legacy GDS Kafka consumer |
| `enhanced-kafka-lib` (EKL) + Muse | Go library | New Kafka consumer with CRDS |
| `ads-config-lib` / Config Center SDK | Go library | Config Center subscription |
| Jaeger | UDP | Distributed tracing (disabled in live: `flag: false`) |
| Prometheus | HTTP scrape | Metrics at `:http_port/metrics` |

---

## Directory Structure

```
ads-resharder/
├── config/                     # Config loading and struct definitions
│   ├── config.go               # ResharderConfig top-level struct
│   ├── resharder.go            # Resharder-specific config fields
│   ├── reload.go               # DB auth hot-reload (UpdateDBAuth)
│   ├── util.go                 # Config utilities
│   └── files/
│       ├── live.yml            # Production config (sources, destinations, table entries)
│       ├── test.yml            # Test environment config
│       └── uat.yml             # UAT config
├── deploy/
│   ├── resharder.json          # Mesos deployment descriptor (build + run commands)
│   └── mesos.sh                # Mesos build/run script
├── init/
│   └── resharder/
│       ├── main.go             # Entry point — app.Run with ResharderConfig
│       └── run.go              # run() function, wires Resharder + starts goroutines
├── internal/
│   ├── constants/
│   │   ├── db_column.go        # DBColumnsMap: default column lists per table
│   │   ├── record_info.go      # DB2RecordInfo and EKLDB2RecordInfo maps
│   │   └── record_info_enum.go # Enum helpers
│   └── resharder/
│       ├── resharder.go        # Resharder struct, New(), Start(), Stop()
│       ├── config.go           # Option and TableConfigEntry structs (YAML)
│       ├── config_center.go    # ConfigGetter — Config Center subscription + hot reload
│       ├── consts.go           # jobTypeMap, unmarshalFuncMap, db2RecordInfoMap
│       ├── table_manager.go    # TableManager, TableEntry, proc unit registration
│       ├── processor_factory.go# ProcFactory — maps processor func names to implementations
│       ├── ekl_consumer.go     # EKLConsumerManager — Muse/EKL consumer lifecycle
│       ├── ekl_consumer_handler.go # EKLMessageHandler — transform/dispatch/process
│       ├── ekl_job.go          # EKLJob and CDCRecord struct
│       ├── ekl_producer.go     # EKL producer wrappers (ads/order/marketplace)
│       ├── ekl_hash.go         # EKL-side prehash function builder
│       ├── producer.go         # countryProducer, singleProducer, countryMultiProducer
│       ├── producer_manager.go # WriterManager — maps destination names to producers
│       ├── kafka_producer.go   # SingleKafkaProducer, MultiKafkaProducer wrappers
│       ├── kafkameta.go        # Kafka metadata helpers
│       ├── hash.go             # KJC-side prehash function builder
│       ├── helper.go           # Misc helpers
│       ├── option.go           # Option struct validation
│       ├── parser.go           # RecordParser for EKL path
│       ├── pid_gen.go          # PID (partition ID) generator registry
│       ├── adsdblib_compat.go  # Custom adsdblib Protobuf unmarshalling (NPB, potential product, GMS item, account audit)
│       ├── exporter.go         # Prometheus metric definitions + parseTableName (KJC path)
│       ├── balancedb/
│       │   └── topup.go        # Balance DB topup translog detection (IsTopupTranslog)
│       ├── kjcmeta/
│       │   └── meta.go         # KJC job metadata: success/error callbacks with Prometheus
│       ├── metrics/
│       │   └── metrics.go      # Prometheus metric definitions for EKL path (EKLMessageCmdCount etc.)
│       ├── tablekey/
│       │   └── tablekey.go     # CDC table key <db>.<table> parser with shard-suffix stripping
│       └── ...                 # test files
├── internal/utils/
│   └── trim_table_suffix.go    # TrimTableSuffix — strips shard suffix from table name
├── tool/
│   ├── benchmark/              # Benchmark tests
│   ├── db_column/              # Tool to generate DB column lists
│   └── observer/               # Standalone observer tool
├── Makefile                    # Build targets: resharder, test, vet, fmt, dep, ci
├── go.mod / go.sum             # Go module dependencies
├── sp-workspace.yml            # SPEX workspace config (proto gen targets)
└── .gitlab-ci.yml              # GitLab CI: test → build (manual) → image (manual)
```

---

## SPEX and Modules

### API Overview

`ads-resharder` is registered as SPEX service **`paidads.resharder`** (env: `live`, tag: `master`, deployment: `default`). It does not expose custom SPEX commands; its SPEX registration is used for service discovery and standard platform integration.

Standard HTTP endpoints (from `paidads-platform-lib/app`):

| Endpoint | Method | Purpose |
|---|---|---|
| `/ping` | GET | Health check (used by Mesos to verify instance liveness) |
| `/smoketest` | GET | Smoke test during deployment (30 retries, 2 s timeout) |
| `/metrics` | GET | Prometheus metrics scrape |

### Resharding Jobs

The resharder processes the following logical table types. Each table entry maps to a `SearchIndexType` job type that is encoded in the downstream Kafka message:

| Table Name | Proto | Job Type String | Shard Key (prehash field) |
|---|---|---|---|
| `campaign_tab` | `beeshop_ads.proto` | `ads_campaign` | `userid` |
| `advertisement_tab` | `beeshop_ads.proto` | `ads_advertisement` | `userid` |
| `ads_account_tab` | `beeshop_ads.proto` | `ads_account` | `userid` |
| `translog_tab` | `beeshop_ads.proto` | `ads_translog` | `account_id` + `userid` |
| `ad_keyword_tab` | `beeshop_ads.proto` | `ads_keyword` | `userid` |
| `campaign_balance_tab` | `beeshop_ads.proto` | `ads_campaign_balance` | `campaignid` |
| `campaign_daily_balance_tab` | `beeshop_ads.proto` | `ads_campaign_balance_by_date` | `campaignid` |
| `ads_credit_tab` | `beeshop_ads.proto` | `ads_credit` | `user_id` |
| `topup_translog_tab` | `beeshop_ads.proto` | `ads_topup_translog` | `user_id` |
| `ads_credit_v3_tab` | `adsdblib.proto` | `ads_credit_v3` | `user_id` |
| `frozen_ads_credit_v3_tab` | `adsdblib.proto` | `frozen_ads_credit_v3` | `user_id` |
| `ads_credit_expense_tab` | `adsdblib.proto` | `ads_credit_expense` | `acc_user_id` |
| `translog_v3_tab` | `adsdblib.proto` | `ads_translog_v3` | `acc_user_id` |
| `campaign_daily_expense_tab` | `adsdblib.proto` | `campaign_daily_expense` | `userid` |
| `ad_audit_event_tab` | `beeshop_ads.proto` | `ad_audit_event` | `userid` |
| `advertisement_audit_tab` | `beeshop_ads.proto` | `advertisement_audit_tab` | `userid` |
| `campaign_audit_tab` | `beeshop_ads.proto` | `campaign_audit_tab` | `userid` |
| `product_campaign_audit_tab` | `beeshop_ads.proto` | `product_campaign_audit_tab` | `userid` |
| `target_audience_group_tab` | `beeshop_ads.proto` | `ads_target_audience_group` | `userid` |
| `product_ad_tab` | `beeshop_ads.proto` | `ads_product_advertisement` | `userid` |
| `creative_tab` | `beeshop_ads.proto` | `ads_creative` | `adsid` |
| `ads_new_product_boost_tab` | `beeshop_ads.proto` | `ads_new_product_boost` | `userid` |
| `ads_potential_product_tab` | `beeshop_ads.proto` | `ads_potential_product` | `userid` |
| `product_gms_item_tab` | `beeshop_ads.proto` | `ads_product_gms_item` | `user_id` |
| `ads_account_audit_tab` | `beeshop_ads.proto` | `ads_account_audit` | `userid` |
| `reserved_keyword_whitelist_tab` | `beeshop_ads.proto` | `reserved_keyword_whitelist` | `keyword` |
| `segment_white_blacklist_model_tab` | `srm_core.proto` | `segment_white_blacklist_model` | `shopid` |
| `daily_budget_prompt_campaign_tab` | `adsdblib.proto` | `daily_budget_prompt_campaign` | `campaignid` → marketplace |
| `campaign_day_rcmd_entry_tab` | `adsdblib.proto` | `campaign_day_rcmd_entry` | `campaignid` → marketplace |
| `order_item_tab` | `order_info.proto` | `order` | — (insert only) |

---

## Cronjobs

`ads-resharder` itself does not run cronjobs. It is a continuously running streaming service. The Advertiser Platform cronjob surface is managed by other services (e.g. `ads-status-syncer`, `ads_service`, `ultimate_ads_service`, `auto-rebate`, `ads-marketing`). For the full cronjob list, see the [Platform Cronjob Knowledge Base](https://docs.google.com/document/d/1Z6VYs8vyJ-D914cU8wDBltrE6ItZ2TrhoZiXOSPkXmM/).

---

## Development Guidelines

### Code Style

- Follow standard Go formatting enforced by `gofmt`. Run `make fmt` before committing.
- Run `make vet` (or `make ci-vet`) to catch common static errors. The CI pipeline rejects unvetted code.
- All public functions and types must have Go doc comments.

### Project Structure

- Business logic lives under `internal/resharder/`. Do not import `internal/` from outside the module.
- Entry point is `init/resharder/`; it only wires dependencies and calls `app.Run`.
- Table configuration is data-driven: adding a new table means adding a YAML stanza in `config/files/{env}.yml` and updating the proto/dbmap mapping — no new Go files are required in most cases.

### Naming Conventions

- Commit messages: `(Feat|Fix|Docs|Style|Refactor|Test|Chore): [JIRA-ID] description`
- Branch names: `dev/$username` or `feature/$feature_name`
- Processor function names in YAML (`processorfunc`, `eklprocessorfunc`) must match registered names in `ProcFactory`.

### Error Handling

- Return errors wrapped with `fmt.Errorf("context: %w", err)` to preserve stack context.
- Fatal startup errors are returned from `New()` and cause the process to exit via `app.Run`.
- Runtime processing errors are logged with table/command context and counted in `paidads_resharder_error` / `paidads_ekl_resharder_ekl_errors`.

### Unit Testing Standards

- Run tests with `make test` (verbose + coverage) or `make test-nv` (CI mode).
- Test files are co-located with the source files they test (e.g. `ekl_consumer_handler_test.go`).
- The `tool/benchmark/` directory holds benchmark tests.

### Code Review & Git Workflow

- All changes go through Merge Requests. Squash commits, delete source branch after merge.
- Algo/platform code merges only after validation in at least one region.
- CI stages: `test` (auto) → `build` (manual) → `image` (manual). See `.gitlab-ci.yml`.

---

## Configuration

### Config Files

The main runtime configuration is in `config/files/{env}.yml`:

| File | Environment |
|---|---|
| `config/files/live.yml` | Production (live) |
| `config/files/test.yml` | Test |
| `config/files/uat.yml` | UAT |

Key sections in `live.yml`:

| Section | Description |
|---|---|
| `ads-resharder.option.sources` | KJC consumer groups, broker lists, topic lists, prehashing options |
| `ads-resharder.option.destination` | Kafka producer configs for `ads_producer`, `marketplace_producer`, `order_producer`, `order_country_producer` (KJC); `balance_producer` topology is Config-Center-driven via `kafka_config` |
| `ads-resharder.option.tableentries` | One entry per logical table: proto name, type name, DB columns, pid gen func, processor functions |
| `ads-resharder.config-center` | Config Center namespace (`resharder_live_default`) and secret |
| `ads-resharder.spex` | SPEX service registration parameters |

**Config Center hot-reload keys** (namespace: `resharder_live_default`):

| Key | Type | Description |
|---|---|---|
| `performance_param` | JSON | `enable_prefilter_by_key`, `enable_partial_unmarshal` |
| `kafka_config` | JSON | EKL Muse consumer list (`source_cdc_kafka`) and EKL destination producer configs (`destination`) |

### SPEX and spcli Setup

Install spcli:

```bash
pip install --upgrade shopee-spex-cli
```

Install the local SPEX network proxy (inp-client):

```bash
wget http://proxy.uss.s3.sz.shopee.io/api/v4/50054564/spex-s3ia-sg-live/intranet_penetrator/inp-client/latest/inp-client_darwin_amd64 \
  -O /usr/local/bin/inp-client && chmod +x /usr/local/bin/inp-client
inp-client  # run in background terminal
```

Regenerate SPEX proto stubs (after modifying `sp_proto/`):

```bash
spcli proto gen
# outputs to gen/go/
```

---

## Deployment

### Build for Production

```bash
# Download dependencies (no network after this)
make dep-vo

# Build binary for current OS
make resharder
# Output: bin/paidads_resharder_server

# Cross-compile for Linux (used by Jenkins/Mesos)
# (also produced by `make resharder`, as bin/paidads_resharder_server.linux)
```

Jenkins / Mesos CI build command (from `deploy/resharder.json`):

```bash
make dep-vo && bash ./deploy/mesos.sh build resharder resharder config/files
```

CI Docker image: `harbor.shopeemobile.com/paidads/base/platform-ci:1.21` (Go 1.21)

### Release Process

1. Push changes to a feature branch and open a Merge Request.
2. GitLab CI runs `make ci` (vet + fmt + test) automatically on the `test` stage.
3. Trigger `build_job` (manual) to build the binary.
4. Trigger `build_image_job` (manual, `.gitlab/make-image.sh`) to build and push the Docker image.
5. Deploy via Mesos using `deploy/resharder.json`. The `run.command` is `./mesos.sh run resharder`.
6. Mesos smoke-tests `/smoketest` (HTTP, 30 retries × 2 s timeout) before marking the instance healthy.

---

## Monitoring

Grafana dashboards (Advertiser Platform folder: [advertiser-platform](https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform)):

| Dashboard | Link |
|---|---|
| Ads Status Syncer + Job + Derived Data + Resharder (Non Live) | [Link](https://monitoring.infra.sz.shopee.io/grafana/d/4xxD8pdHz/ads-status-syncer-job-derived-data-resharder-non-live) |
| Live Ads Resharder | [Link](https://monitoring.infra.sz.shopee.io/grafana/d/BLgcEuRnz/live-ads-resharder) |
| Resharder EKL ads db (nonlive) | [Link](https://monitoring.infra.sz.shopee.io/grafana/d/sY8oKqsNz/resharder-ekl-ads-db-nonlive) |
| Billing Lag (TDR Overview) | [Link](https://monitoring.infra.sz.shopee.io/grafana/d/YMWPK-Q7z/tdr-overview-dashboard?orgId=39&viewPanel=73&from=now-7d&to=now) |
| Live Ads DB Regional | [Link](https://monitoring.infra.sz.shopee.io/grafana/d/4RB9tsfIz/region-live-ads-db?orgId=39) |

**Key Prometheus metrics** (scrapped from `:http_port/metrics`):

| Metric | Type | Labels | Description |
|---|---|---|---|
| `paidads_resharder_counter` | Counter | `subsystem`, `db`, `table`, `cmd` | CDC message count per table/command (KJC path) |
| `paidads_resharder_latency` | Histogram | `message_type`, `message_source` | Processing latency in µs (KJC path) |
| `paidads_resharder_e2e_latency` | Histogram | `topic`, `message_source` | End-to-end latency in seconds (KJC path) |
| `paidads_resharder_error` | Counter | `subsystem`, `partition`, `message_type`, `err_type` | Processing errors (KJC path) |
| `paidads_ekl_resharder_counter` | Counter | `subsystem`, `db`, `table`, `cmd` | CDC message count (EKL path) |
| `paidads_ekl_resharder_latency` | Histogram | `message_type`, `message_source` | Processing latency in µs (EKL path) |
| `paidads_ekl_resharder_e2e_latency` | Histogram | `topic`, `message_source` | End-to-end latency in seconds (EKL path) |
| `paidads_ekl_resharder_ekl_errors` | Counter | `subsystem`, `partition`, `message_type`, `err_type` | Processing errors (EKL path) |

Kafka consumer lag monitoring: [Kafka Exporter — paidads-bigshop-deduct-event topic](https://monitoring.infra.sz.shopee.io/grafana/d/tMpwXZvMz/kafka-exporter-dashboard?from=now-24h&orgId=74&refresh=5m&to=now&var-cluster=ks_ads_live&var-group=All&var-middleware_datasource=vm-live-middleware&var-topic=paidads-bigshop-deduct-event-id-live&viewPanel=180)

---

## Business Terminology Glossary

### Core Metrics

| Term | Full Name | Definition |
|---|---|---|
| CTR | Click-Through Rate | Clicks / Impressions — measures ad relevance |
| CR | Conversion Rate | Ad orders / Clicks — purchase likelihood after click |
| eCPM | Effective Cost per Mille | Total Spend / Total Impressions × 1000 |
| CPC | Cost Per Click | Amount spent per click |
| CPM | Cost Per Mille | Cost per 1,000 ad impressions |
| ROI | Return on Investment | Ad GMV / Ad Expenditure (seller perspective) |
| ROAS | Return on Ad Spending | Synonym for ROI |
| CIR | Cost-Income Ratio | Ads Revenue / Ads GMV |
| Take-Rate | — | Ads Revenue / Platform GMV |
| Rank Score | — | eCPM + quality factors |
| Display Rate | — | Ads with impressions / Active ads |
| Fill-up Rate | — | Actual impressions / Potential impressions |

### Ad Types and Products

| Term | Definition |
|---|---|
| Search Ads (SADS) | Keyword-triggered ads shown in search results |
| Discovery Ads (DADS) | Targeting ads shown on recommendation surfaces; also called TADS |
| Display Ads | Brand/CPM ads using creatives (images/video); includes Brand Max, Video Ads, Live Stream Ads |
| NPB / New Product Boost | Automatic boost for newly listed products |
| Shop Ads | Ads promoting an entire shop |
| Search Brand Ads | Reserved keyword brand ads |
| Brand Consideration Ads | Brand-level ads for consideration stage |

### Placements & Entrances

| Value | Meaning |
|---|---|
| `placement=3` | Shop Ads |
| `placement=4` | Search Ads |
| `placement=40` | Discovery / Recommendation Ads |

### Sellers & Advertisers

| Term | Definition |
|---|---|
| Active Seller | Seller with an open ads account, active in a defined window |
| Preferred Sellers (PS) | Sellers meeting Shopee quality guidelines |
| Official Shops (OS) | Brand-owned official storefronts |
| MCN | Multi-Channel Network; manages KOL/influencer partnerships |

### Bidding & Pricing

| Term | Definition |
|---|---|
| oCPC / Simple Mode | Auto-keyword-selection mode; platform auto-optimises bids |
| Manual Mode | Seller sets explicit keyword bids |
| PID Controller | Proportional-Integral-Derivative controller used to adjust Simple Mode bids dynamically |
| OCPC CIR | Cost-Income Ratio target used to constrain automated bidding |
| uGSP | Unified Generalized Second Price auction mechanism |

### Prediction & Models

| Term | Definition |
|---|---|
| pCTR | Predicted Click-Through Rate |
| pCR | Predicted Conversion Rate |
| rcgbdt | RC Gradient Boost Decision Trees; pCTR prediction model |
| Cold Start | State of an ad with insufficient data for accurate prediction |

### System Features & Services

| Term | Definition |
|---|---|
| SRM | Seller Relationship Management — manages seller segments, programs, incentives |
| QSS | QuickStart Service — helps new advertisers ramp up ad usage |
| VGS | Values Grid Search — auto-tunes algorithm parameters |
| Auto Top-up | Automatic credit top-up for local sellers |
| Advv | Advertiser Value — long-term revenue metric for the platform |

### Ad Supply & Display

| Term | Definition |
|---|---|
| Ads GMV | Total sales attributed to ad clicks (7-day attribution window) |
| Ads Order | Order placed within 7 days of an ad click |
| Traffic Rate | Impressions from one ad type as a share of all impressions |
| Rebate | Cash-back credited to campaigns based on performance programs |

### Controls & Filtering

| Term | Definition |
|---|---|
| Blacklist | Keyword or item-ID level exclusion list |
| Whitelist | Feature-access enablement list (e.g. Target ROI, Shop Ads customisation) |
| Broad Match | Query triggers ad if it contains the keyword (partial match) |
| Exact Match | Query must exactly equal the keyword |
| Badcase | Manually flagged ad/keyword anomaly for ops review |

### External Services & Systems

| Term | Definition |
|---|---|
| GDS | Global Data Stream — Shopee's MySQL Binlog CDC Kafka infrastructure |
| KJC | `kafka_job_client` — legacy GDS consumer library used by ads-resharder |
| EKL | `enhanced-kafka-lib` — newer CDC consumer framework (Muse-based) |
| SDDL | Shopee Dynamic DDL — database schema migration platform |
| Panama CDC | Shopee's newer CDC pipeline replacing GDS for some databases |

### Technical Terms

| Term | Definition |
|---|---|
| Resharding / 分片 | Re-routing sharded DB CDC events to logical per-country topics |
| Prehashing | Applying a deterministic hash on shard key fields before Kafka partition assignment |
| PID Gen | Partition-ID Generator — determines which shard key field to hash per table |
| KJC Proc Unit | KJC framework unit: `(table, operation, processorFunc)` triple |
| EKL Proc Unit | EKL framework unit: `(db, table, operation, CDCProcessFunc)` |
| ProtoName | Protobuf schema file name used for CDC record deserialisation (e.g. `beeshop_ads.proto`) |

---

## Additional Resources

- Git repository: https://git.garena.com/shopee/deep/ads-resharder
- Advertiser Platform Confluence: https://confluence.shopee.io/display/SPAD/Advertiser+Platform
- Paid Ads Glossary: https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- ads-db-lib (DB access library): https://git.garena.com/shopee/deep/ads-db-lib
- SPEX Go Quick Start: https://spex.shopee.io/overview/quick-start/languages/go/index.html
- DB Sharding Progress Tracker: https://docs.google.com/spreadsheets/d/1J_9SxnYOZ3I3MLH-JweoPgeg4cV7do-nY2qYcSLqos4/edit
- DB Decoupling Design Doc: https://docs.google.com/document/d/1I5Wr0fr5-wBH6KWyGpUBCNYMY4YU-Wv0eZ5okhDfveU/
- Platform Cronjob Knowledge Base: https://docs.google.com/document/d/1Z6VYs8vyJ-D914cU8wDBltrE6ItZ2TrhoZiXOSPkXmM/
- Monitoring Grafana (Advertiser Platform): https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform
- Space CMDB Cronjob Tree: https://space.shopee.io/console/cmdb/cronjobs/tree/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.platform
- SDDL Intro: https://gdbc.shopee.io/sddl/intro

---

## Frequently Asked Questions

**Q1: How do I add a new Ads DB table to the resharder?**

If your table's protobuf model is already in `beeshop_ads.proto`:
1. Add a table entry to `config/files/{env}.yml` with the correct `tablename`, `dbtable`, `typename`, `dbcolumns`, and `pidgenfunc`.
2. Add a `prehashingoptions` entry for the table under the relevant KJC source in `live.yml`.

If your table's proto model is **not** from `beeshop_ads.proto` (e.g. a new proto file):
1. Add your table to `dbmap.AdsDbLibProtoName` in `proto_parser/protoc-gen-dbmap/config.go`.
2. Run `make adsdblib` to regenerate the dbmap code.
3. Copy the generated output to `beeshop_ads.dbmap.go`.
4. Then proceed with the YAML steps above, setting `protoname: beeshop_ads.proto`.

See [MR !160](https://git.garena.com/shopee/deep/proto_parser/-/merge_requests/160) → [MR !161](https://git.garena.com/shopee/deep/proto_parser/-/merge_requests/161) for a concrete example.

**Q2: What does the prehashing step do and why does it matter?**

Prehashing applies a deterministic hash on a specified field (e.g. `userid`) before the KJC/EKL framework assigns a Kafka partition. This ensures that all CDC events for the same entity (e.g. all campaigns for a given user) always go to the same partition in the destination topic, which preserves ordering for downstream consumers that need sequential processing per entity.

**Q3: What is the difference between the KJC path and the EKL path?**

KJC (`kafka_job_client`) is the legacy GDS consumer framework. EKL (`enhanced-kafka-lib`) is the newer Muse-based consumer. Both process the same tables and write to the same destinations. They are controlled by `enable-ekl: true` and `disable-kjc: false` in `live.yml`. Currently both run simultaneously; the KJC path can be turned off gradually as EKL is validated.

**Q4: How is the EKL Kafka topology configured separately from the static YAML?**

EKL consumer config (Muse client names, keys, regions) and EKL destination producer configs are stored in Config Center under namespace `resharder_live_default`, key `kafka_config`. This allows changing EKL consumer group topology without a service restart or redeploy.

**Q5: How does the resharder route order events differently from ads events?**

Order events from `shopee_order_core_{cid}_db` are routed to either the single topic `shopee_order_gds_live` (for non-LATAM countries via the global group) or to per-country topics `shopee_order_gds_{CID}_live` / `shopee_order_gds-{CID}-live` (for BR, MX, CO, CL, AR). This is controlled by the `producer-destination` field in the table entry: `order_producer` for global, `order_country_producer` for per-country.

**Q6: How do I check if the resharder is consuming a specific Kafka topic correctly?**

Check the consumer group lag in the Kafka Exporter dashboard or via `kafka.ks_paidads_live` metrics. The group names are defined in `live.yml` (e.g. `ads_gds_live_consumer` for the main ads DB). Consumer lag spikes on the destination topics (`ads_gds_{CID}`) indicate the resharder is not forwarding fast enough.

**Q7: What happens when a new DB shard is added (e.g. `shopee_ads_br_db_10`)?**

For the GDS KJC path, the broker assigns topics dynamically — no config change needed for a new shard of an existing database. For the Panama CDC path (marketing, order), the per-shard topics must be explicitly added to the `topiclist` in `live.yml` and the service redeployed.

**Q8: How do I run tests locally?**

```bash
make dep-vo       # download dependencies
make test         # run all tests with coverage
make ci           # simulate full CI: vet + fmt + test
```

**Q9: The `/smoketest` endpoint is failing during deployment. What should I check?**

The smoke test (30 retries × 2 s timeout) validates that the process started and the HTTP server is up. Check that: (1) the config file path is correct for the environment, (2) Config Center subscription succeeds (check logs for `subscribe resharder config fail`), and (3) all Kafka producers initialise without error (check logs for `fail init gds client`).

**Q10: How do I trace a specific CDC event through the system?**

If Jaeger tracing is enabled (`flag: true` in the YAML `jaeger` section), each event carries a span. In live, Jaeger is disabled. Use the Prometheus `paidads_resharder_counter` metric filtered by `table` and `cmd` to verify events are being processed, and check `paidads_resharder_e2e_latency` to measure the delay from DB write to Kafka message.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 6c9b8618dffe4a85d37504ec8ef2b8c61cefb5cd -->
