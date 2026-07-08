<!-- ads-workspace-gdoc-sync: gdoc_id=1W6bbiqlkqauSoeqqyNfSpHW2CmQoQZPcfoYSFL0nsoY gdoc_url=https://docs.google.com/document/d/1W6bbiqlkqauSoeqqyNfSpHW2CmQoQZPcfoYSFL0nsoY/edit -->

# ads_service

**Repository:** https://git.garena.com/shopee/deep/ads_service

---

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Directory Structure](#directory-structure)
5. [SPEX and Modules](#spex-and-modules)
   - [Service Entry and Protocol](#service-entry-and-protocol)
   - [Core Domains](#core-domains)
   - [Dependencies and Storage](#dependencies-and-storage)
6. [Cronjobs](#cronjobs)
   - [Code Commands and Scheduled Jobs](#code-commands-and-scheduled-jobs)
7. [Development and Local Run](#development-and-local-run)
   - [Build, Test, and Proto Workflow](#build-test-and-proto-workflow)
   - [Entrypoints and Runtime Requirements](#entrypoints-and-runtime-requirements)
   - [Code Review & Git Workflow](#code-review--git-workflow)
8. [Configuration and Deployment](#configuration-and-deployment)
   - [Environment Config Files](#environment-config-files)
   - [Runtime Config](#runtime-config)
   - [Mesos Build and Release](#mesos-build-and-release)
9. [Monitoring and Operations](#monitoring-and-operations)
10. [Key Terms](#key-terms)
11. [Additional Resources](#additional-resources)
12. [Frequently Asked Questions](#frequently-asked-questions)

---

## Introduction

`ads_service` is the **core advertiser-platform backend** for Shopee Paid Ads. It is responsible for the full lifecycle of ad data — including account management, campaign/ad creation, keyword bidding, transaction-log recording, Display Ads billing, reporting, and whitelist/fraud operations — for all Shopee markets (SG, MY, TH, ID, VN, PH, TW, BR, MX).

The service exposes its API via the Shopee SPEX RPC framework (`paidads.ads_service.*`). It is consumed by upstream services such as `ads-marketing`, `sku-selector`, `paidadsbackendadmin`, and `ultimate_ads_service`, all of which sit between seller-facing frontends and this backend. A companion binary, `ads_service_cronjob`, runs periodic maintenance tasks against the same config and database.

**Critical dependencies for local run:** the `data/` directory (text-processing data, populated by `bash ./scripts/getdata.sh`) must be present in the same directory from which the server binary is launched. Without it the service will fail to start.

---

## Features

Capabilities are derived from `sp_proto/paidads/ads_service.proto` and the `internal/` module layout:

| Domain | Capability |
|---|---|
| **Account** | Get ads account balance, wallet detail, free-ads-credit list, expiring credit amount, manual topup, ads credit subtype management |
| **Campaign** | Campaign-day management (get/add/delete/stats), campaign expense query |
| **Banner Ads** | Create/get/update/list Banner Ads campaigns, update campaign status, get shop reserved keyword |
| **Advertisement / Keyword** | Keyword bid scan (v2), keyword blacklist CRUD (get/add/update/is-blacklisted), keyword whitelist management, keyword recommend (search ads + shop ads), suggest price (search ads + shop ads) |
| **Transaction Log** | Query deduction and top-up transaction logs (CPC/CPM/Credit), translog summary |
| **Display Ads** | Full lifecycle: calendar info, CPM pricing, company profiles, billing generation and checking, creative upload, status management, admin message management, custom audience, shop whitelist check |
| **Report** | `query_report`, `get_agg_report` |
| **Auto Boost** | Get/scan Auto Boost ads, get qualified SKUs |
| **Whitelist / Fraud** | Whitelist type management, add/delete/get whitelist users (whitelist ext info includes `EscrowWhitelistExtInfo` with `optional_fee_rate` and `optional_fee_rate_change_type` for admin-configured optional escrow fee), fraud-user CRUD (get/add/delete), fraud reasons |
| **Discovery Ads Suggest Price** | Discovery Ads suggest price (active); Target Ads and Segment suggest price deprecated |
| **Admin / Notification** | Admin messages, push notifications, credit expiry notification, recommend score |

---

## Architecture

`ads_service` is a Go SPEX service. The startup sequence (verified from `init/ads_service/run.go`) is:

1. **Load config** — `uniconfig` reads `config/files/{env}.yml`.
2. **Connect Config Center** — `config-sdk-go` client for dynamic config keys.
3. **Init DB Manager** — `ads-db-lib`-backed `DBLibManager` that embeds both `dblib.DBManager` and `dblib.IDMappingClient` (via `IDMappingCache` DB group); wired with Config Center for live secret rotation. `IDMappingClient` enables UserID lookup by AdsID/ShopID for primary-key-based DB shard routing.
4. **Init HTTP-over-SPEX** — `hos.InitClient` for `mktzlib/http_over_spex`.
5. **Init SPEX agent** — `paidads-platform-lib/spex/v2`, registered under prefix `paidads.ads_service`.
6. **Subscribe SPEX config** — `AdsServiceSpexConfig` loaded from the `config` key on the SPEX agent; hot-reloaded via a watcher goroutine.
7. **Init ancillary subsystems** — Reserved keyword manager, Redis locker, rate limiters (general + campaign), notifier, textproc, RNG endpoint, fraud-user cache (Redis), Target Ads bidding client (gRPC+etcd, two instances: suggest bid price and segment bid price), keyword recommend client (`search_kw_rcmd`), general cache manager, temp storage (Redis), Display Ads config manager, adult category manager, item data manager, ads config manager, shop ads eligibility manager, user-shop cache, whitelist manager, bid-price manager, Display Ads premium rate cache, translator managers (general + search brand), config repository, GFS (USS) initialisation.
8. **Wire and register server** — `api/ads_service.NewServer(...)` assembled, `AdsServiceProcessor` registered with SPEX.
9. **Serve** — wait for shutdown signal.

```
Seller Center / MCN Portal / Open API / Admin Portal
              │ (HTTP → SPEX)
         ads-marketing / sku-selector
              │ (SPEX)
         ┌────▼────────────────────────────┐
         │         ads_service (SPEX)      │
         │  paidads.ads_service.*          │
         │                                 │
         │  ┌──────────────┐  ┌─────────┐  │
         │  │ ads-db-lib   │  │  Redis  │  │
         │  │ (MySQL shard)│  │ (cache/ │  │
         │  └──────────────┘  │  lock)  │  │
         │  ┌──────────────┐  └─────────┘  │
         │  │ Config Center│               │
         │  └──────────────┘  ┌─────────┐  │
         │  ┌──────────────┐  │  Kafka  │  │
         │  │ GFS (USS)    │  │ (log)   │  │
         │  └──────────────┘  └─────────┘  │
         └─────────────────────────────────┘
              │ (SPEX / gRPC client)
         paidads-targetads-ad-bidding / webservice / notifier / textproc / translator
```

**Service topology (from Confluence Advertiser Platform KB):**

| Type | Service / Component | Protocol | Description |
|---|---|---|---|
| **Upstream callers** | `ads-marketing`, `sku-selector` | SPEX | Primary seller-facing RPC callers |
| **Upstream callers** | `paidadsbackendadmin` | SPEX | Admin portal backend |
| **Upstream callers** | `ultimate_ads_service` | SPEX | Ads DB gateway service |
| **Downstream / dep** | `ads-DB` (`ads-db-lib`, MySQL shards) | MySQL via goorm | Primary data store; 7 logical DB groups, sharded by userid/campaignid/date |
| **Downstream / dep** | Redis | redis/v8 | Cache layer (general cache, Redis lock, blacklist cache, temp storage, fraud-user cache, user-shop in-memory cache) |
| **Downstream / dep** | Config Center (`config-sdk-go`) | HTTP | Dynamic config and DB secret management |
| **Downstream / dep** | GFS / USS | gRPC | Display Ads creative file storage |
| **Downstream / dep** | Kafka (via `paidads-platform-lib/log`) | Kafka | Log shipping |
| **Downstream / dep** | `paidads-targetads-ad-bidding` | gRPC+etcd | Bid-price suggestion for Target Ads / Segment Ads (two client instances) |
| **Downstream / dep** | webservice (HTTP over SPEX) | SPEX | External data services (item data, adult category, KW recommend) |
| **Downstream / dep** | Transify (translator) | HTTP | i18n translation for keyword/brand ads text |

---

## Directory Structure

```
ads_service/
├── api/ads_service/       # SPEX server wiring — NewServer(), handler registration
├── config/
│   ├── files/             # Static environment configs: test.yml, staging.yml, live.yml, liveish.yml, stable.yml, uat.yml
│   ├── config.go          # Config struct definitions (AdsService, AdsDBLibOption, …)
│   └── reload.go          # Config hot-reload utilities
├── cron_jobs/             # All cronjob command implementations
│   ├── display_ads/       # billing_generator, billing_checker, status_updater
│   ├── shop_ads/          # blacklist_checker, whitelist_checker
│   ├── ads_credit_expiry_notifier.go
│   ├── ads_preboost_whitelist_cache_updater.go
│   ├── db_observer.go
│   └── translog_summary.go
├── data/                  # Text-processing data (NOT committed; populate via scripts/getdata.sh)
├── deploy/
│   ├── mesos.sh           # Two-phase build/run script for Mesos deployment
│   ├── adsservice.json    # Mesos deploy descriptor for main service
│   └── adsservicecronjob.json  # Mesos deploy descriptor for cronjob binary
├── init/
│   ├── ads_service/       # main + run.go — main service entrypoint
│   └── ads_service_cronjob/ # main.go — cronjob binary entrypoint
├── internal/              # All business logic (not importable externally)
│   ├── ads_service/       # Prometheus exporters (latency, error, time_diff, DB count), shared consts
│   ├── ads_account/       # Account balance management, wallet detail, free-ads-credit
│   ├── ads_config/        # Ads config manager (backed by Config Center AdsConfigSecret)
│   ├── ads_credit_subtype/# Ads credit subtype get/set
│   ├── ads_helper/        # Audit event handler for campaign/ad/keyword changes (AdsAuditHandler interface + DB-backed impl)
│   ├── ads_manual_topup/  # Manual topup activity
│   ├── adsadminclient/    # Admin service client
│   ├── admin_message/     # Admin message controller (DB + notifier + search brand translator)
│   ├── adult_category/    # Adult category check via webservice
│   ├── auto_boost/        # Auto Boost ads: get/scan/qualified SKUs
│   ├── banner_ads/        # Banner Ads CRUD sub-packages (create, get, update, list, update_campaign_status, get_shop_reserved_keyword)
│   ├── bid_price/         # Bid price manager (Config Center-backed)
│   ├── campaign_day/      # Campaign Day data helpers
│   ├── campaign_info/     # Campaign CRUD helpers, expense query
│   ├── config_center/     # Config Center client wrapper
│   ├── db_manager/        # ads-db-lib manager initialisation
│   ├── display_ads/       # Display Ads config manager, billing, premium rate cache, creative management, custom audience
│   ├── expiring_credit/   # Expiring credit helpers
│   ├── fraud_user/        # Fraud user management (DB-backed), fraud reasons
│   ├── item_boost/        # Item Boost package and variable-settings management
│   ├── item_data/         # Item data retrieval via webservice
│   ├── keyword/           # Keyword bid scan (v2)
│   ├── keyword_blacklist/ # Keyword blacklist management (get/add/update/is-blacklisted)
│   ├── keyword_whitelist/ # Reserved keyword whitelist CRUD and audit
│   ├── kw_rcmd/           # Keyword recommend + suggest price orchestration
│   ├── notifier/          # SeaTalk/Email notifications
│   ├── qps_rate_limiter/  # QPS rate limiter
│   ├── recommend_score/   # Recommend score via webservice
│   ├── redis_locker/      # Distributed lock (Redis-backed)
│   ├── report/            # RNG-based report querying (query_report, get_agg_report)
│   ├── repository/config/ # Config repository — subscribes to `ads_service_{env}_default` in Config Center; provides per-region `AdsCacheConfig` (cache TTLs) and `FeatureDowngradeConfig` (feature downgrade flags)
│   ├── search_kw_rcmd/    # Search keyword recommend client
│   ├── shop_ads/          # Shop Ads eligibility checks
│   ├── spex/              # AdsServiceSpexConfig — hot-reloaded dynamic config
│   ├── suggest_price/     # Discovery Ads suggest price calculation
│   ├── sync_log/          # Sync log utilities
│   ├── temp_storage/      # Temporary storage (Redis-backed)
│   ├── textproc/          # Text processing (s2t, stemming) — requires data/ dir
│   ├── topup_translog/    # Top-up translog helpers
│   ├── traffic_controller/# Traffic controller utilities
│   ├── transaction_log/   # Transaction log config and processing
│   ├── translator/        # Transify i18n translation manager (general + search brand)
│   ├── webservice/        # HTTP-over-SPEX client manager for external data services
│   ├── whitelist/         # Whitelist activity (type/users CRUD, backed by whitelist_manager)
│   └── whitelist_manager/ # Whitelist CRUD backed by DB + cache
├── pkg/
│   ├── cache/             # General cache manager (Redis-backed)
│   └── reserved_keyword_manager/ # Reserved keyword management
├── protobuf/go/           # Auto-generated Go protobuf bindings (DO NOT EDIT)
├── scripts/
│   └── getdata.sh         # Downloads text-processing data into data/
├── sp_proto/paidads/
│   └── ads_service.proto  # Canonical RPC contract (4111 lines)
├── sp-workspace.yml       # SPEX generator workspace config
├── textproc.xml           # Text-processing plugin config
├── tool/                  # One-off operational/fix tools (NOT production main path)
├── utils/                 # Shared utility functions: primary-key routing builders for Display Ads/Shop Ads/Campaign indexes (BuildAdvertisementPrimaryKeysFromDisplayAdsIndex, BuildCampaignPrimaryKeysFromDisplayAdsIndex, BuildCampaignPrimaryKeysFromShopAdsIndex), UniquePositiveNum, numeric helpers
└── Makefile
```

---

## SPEX and Modules

### Service Entry and Protocol

The service binary is built from `init/ads_service/` and runs as a SPEX worker registered under the namespace prefix `paidads.ads_service` (defined in `protobuf/go/paidads_ads_service.pb`).

The full RPC contract is defined in `sp_proto/paidads/ads_service.proto`. Active (non-deprecated) RPC families, verified from `api/ads_service/server.go`:

- **Account:** `get_ads_account`, `get_wallet_detail`, `list_free_ads_credit`, `get_expiring_credit_amount`, `ads_manual_topup`, `get_seller_mission_ads_account`, `get_ads_credit_subtypes`, `set_ads_credit_subtypes`
- **Campaign Day:** `get_campaign_days`, `add_campaign_day`, `delete_campaign_day`, `get_campaign_day_stats`
- **Campaign:** `get_campaign_expense`
- **Banner Ads:** `create_banner_ads`, `get_banner_ads`, `update_banner_ads`, `list_banner_ads_campaigns`, `update_campaign_status`, `get_shop_reserved_keyword`
- **Auto Boost:** `get_auto_boost_ads`, `scan_auto_boost_campaigns`, `get_qualified_sku`
- **Keyword / Blacklist:** `scan_advertisement_keyword_v2`, `get_blacklist_keyword`, `add_blacklist_keyword`, `update_blacklist_keyword`, `is_keyword_blacklisted`, `get_reserved_keyword_whitelist`, `set_reserved_keyword_whitelist`, `get_reserved_keyword_whitelist_audit`
- **Keyword Recommend / Suggest Price:** `get_search_ads_keyword_recommend`, `get_shop_ads_keyword_recommend`, `get_search_ads_keyword_suggest_price`, `get_shop_ads_keyword_suggest_price`, `trigger_keyword_suggest_log`
- **Transaction Log:** `get_transaction_log`, `get_transaction_log_with_v1_override`, `get_topup_translog`
- **Display Ads:** `get_display_ads_list`, `get_display_ads_detail`, `create_display_ads`, `edit_display_ads`, `set_display_ads_status`, `upload_creative_image`, `upload_display_ads_creative`, `get_display_ads_calendar_info`, `get_display_ads_cpm_info`, `get_display_ads_company_profiles`, `upload_display_shop_billing_info`, `get_display_ads_admin_message`, `set_display_ads_admin_message`, `check_shop_whitelist`, `get_display_ads_custom_audience`
- **Report:** `query_report`, `get_agg_report`
- **Whitelist / Fraud:** `get_whitelist_type`, `add_whitelist_users`, `delete_whitelist_users`, `get_whitelist_users`, `get_fraud_users`, `add_fraud_users`, `delete_fraud_users`, `get_fraud_reasons`
- **Suggest Price:** `get_discovery_ads_suggest_price`
- **Admin / Notification:** `send_notification`, `get_recommend_score`
- **Item Boost:** `get_item_boost_variable_settings`, `add_item_boost_variable_setting`, `get_item_boost_user_custom_package`, `set_item_boost_user_custom_package`

> **Deprecated RPCs** (return `ERROR_DEPRECATED`): `get_ads`, `get_campaigns`, `set_account`, `get_ads_item_index`, `get_campaign_list`, `get_ads_list`, `get_ads_list_by_keyword`, `create_auto_shop_ads`, `update_auto_shop_ads_status`, `get_auto_shop_ads`, `get_shop_ads_index`, `get_target_ads_suggest_price`, `get_target_ads_segment_suggest_price`, `get_item_boost_estimated_quota`, `get_item_boost_estimated_order`, `set_advertise_batch`, `set_advertise_batch_with_snapshot`, and all BuyerSegment-related RPCs. Do not call these — contact maintainers for alternatives.

Handler wiring happens in `api/ads_service/server.go`. The `NewServer()` function receives all initialized managers (DB, cache, webservice, etc.) from `init/ads_service/run.go` and returns an implementation of the SPEX processor interface.

### Core Domains

Business logic resides entirely in `internal/`. Key modules:

| Module | Responsibility |
|---|---|
| `internal/ads_account` | Account balance CRUD, Credit management, wallet detail, free-ads-credit, seller mission account |
| `internal/ads_config` | Ads config manager backed by Config Center `AdsConfigSecret` |
| `internal/ads_credit_subtype` | Get/set ads credit subtypes |
| `internal/ads_helper` | Ads audit event handler — constructs audit events and writes campaign, advertisement, and keyword change logs to ads-DB via `AdsAuditHandler` interface; used by `banner_ads` modules |
| `internal/ads_manual_topup` | Manual topup activity (via webservice) |
| `internal/admin_message` | Admin message controller — wraps DB + notifier + search brand translator |
| `internal/auto_boost` | Auto Boost ads: get/scan ads, get qualified SKUs |
| `internal/banner_ads/*` | Banner Ads CRUD sub-packages: `create_banner_ads`, `get_banner_ads`, `get_shop_reserved_keyword`, `list_banner_ads_campaigns`, `update_banner_ads`, `update_campaign_status` |
| `internal/campaign_info` | Campaign data access helpers, campaign expense |
| `internal/campaign_day` | Campaign Day CRUD |
| `internal/keyword` | Keyword bid scan (v2) |
| `internal/keyword_blacklist` | Keyword blacklist get/add/update/is-blacklisted |
| `internal/keyword_whitelist` | Reserved keyword whitelist CRUD and audit |
| `internal/display_ads` | Display Ads config manager, billing objects, premium rate cache, custom audience, admin message |
| `internal/transaction_log` | Transaction log config and processing |
| `internal/report` | RNG-based report querying (`query_report`, `get_agg_report`) |
| `internal/recommend_score` | Get recommend score (via webservice) |
| `internal/shop_ads` | Shop Ads eligibility checks |
| `internal/whitelist` | Whitelist activity (type/users CRUD, backed by whitelist_manager) |
| `internal/whitelist_manager` | Whitelist CRUD backed by DB + cache |
| `internal/bid_price` | Bid price manager (Config Center-backed) |
| `internal/suggest_price` | Discovery Ads suggest price calculation |
| `internal/item_boost` | Item Boost package and variable-settings management |
| `internal/item_data` | Item data retrieval via webservice |
| `internal/adult_category` | Adult category validation via webservice |
| `internal/fraud_user` | Fraud user management (DB-backed), fraud reasons |
| `internal/search_kw_rcmd` | Search keyword recommend client |
| `internal/kw_rcmd` | Keyword recommend + suggest price orchestration layer |
| `internal/translator` | Transify i18n translation (general + search brand, two manager instances) |
| `internal/spex` | `AdsServiceSpexConfig` — hot-reloaded dynamic config |
| `internal/db_manager` | `ads-db-lib` manager initialisation and Config Center secret integration |
| `internal/config_center` | Config Center client wrapper |
| `internal/webservice` | HTTP-over-SPEX manager for external data services |
| `internal/notifier` | SeaTalk/Email notifications |
| `internal/textproc` | Text processing (s2t, stemming) — requires `data/` dir |
| `internal/redis_locker` | Distributed lock (Redis-backed) |
| `internal/temp_storage` | Temporary storage (Redis-backed) |
| `internal/traffic_controller` | Traffic controller utilities |
| `internal/repository/config` | Config repository — subscribes to Config Center namespace `ads_service_{env}_default`; provides per-region `AdsCacheConfig` (cache TTLs, key config) and `FeatureDowngradeConfig` (feature downgrade flags); consumed by `transaction_log` and `campaign_day` activities |

### Dependencies and Storage

| Dependency | Usage |
|---|---|
| **ads-DB** (`ads-db-lib` v0.127.1) | Primary data store: 7 logical DB groups (Core, SRM, Marketing, Ops, Rebate, Booking, CRM) with MySQL sharding per userid/campaignid/date. Accessed via `internal/db_manager`. `DBLibManager` now also implements `dblib.IDMappingClient` (via `IDMappingCache` DB group), enabling primary-key routing (UserID + CampaignID/AdsID) for Display Ads, Auto Boost, Shop Ads, and campaign queries — eliminates scatter-gather when UserID is not provided by the caller. |
| **Redis** | Multiple roles: general cache (`pkg/cache`), distributed lock (`internal/redis_locker`), blacklist cache, temp storage (`internal/temp_storage`), fraud-user cache, user-shop in-memory cache backed by Redis. |
| **Config Center** | Dynamic config and DB secret management. Keys include `AdsDbLib`, `AdsConfigSecret`, `BidPrice`. Managed via `internal/config_center`. |
| **GFS (USS / `discover-landing/uss-go`)** | Creative file storage for Display Ads. Options live in `AdsServiceSpexConfig.DisplayAdsStorage`. |
| **Kafka** | Log shipping via `paidads-platform-lib/log`. |
| **paidads-targetads-ad-bidding** | gRPC client for bid-price suggestion (Target Ads suggest bid, Segment bid — two separate client instances). |
| **textproc / `data/`** | Text processing for keyword normalization (simplified-to-traditional, stemming). Requires local `data/` directory. |
| **Transify (translator)** | i18n translation service for keyword and search brand ads text (two manager instances: general and search brand). |

---

## Cronjobs

### Code Commands and Scheduled Jobs

The `ads_service_cronjob` binary is built from `init/ads_service_cronjob/main.go`. It shares the same `config.AdsService` config struct and DB/cache wiring as the main service. Commands are run with the `--country` and `--dry_run` flags.

| Code Command Name | Source File | Description |
|---|---|---|
| `notify_ads_credit_expiry` | `cron_jobs/ads_credit_expiry_notifier.go` | Scan and notify sellers whose ads credits are about to expire |
| `display_ads_billing_generator` | `cron_jobs/display_ads/billing_generator.go` | Generate Display Ads billing records (🔴 Critical) |
| `display_ads_billing_checker` | `cron_jobs/display_ads/billing_checker.go` | Verify Display Ads billing accuracy |
| `display_ads_status_updater` | `cron_jobs/display_ads/status_updater.go` | Display Ads state machine (planned to be decommissioned) |
| `update_pre_boost_whitelist_cache` | `cron_jobs/ads_preboost_whitelist_cache_updater.go` | Refresh preboost campaign-surge whitelist cache |
| `shop_ads_blacklist_checker` | `cron_jobs/shop_ads/blacklist_checker.go` | Check and update Shop Ads blacklists |
| `shop_ads_whitelist_checker` | `cron_jobs/shop_ads/whitelist_checker.go` | Check and update Shop Ads whitelists |
| `db_observer` | `cron_jobs/db_observer.go` | Monitor DB changes, trigger downstream processing |
| `translog_summary` | `cron_jobs/translog_summary.go` | Aggregate deduction logs, pre-compute recharge changes |

Cross-reference with CMDB-scheduled jobs (from KB):

| CMDB Job Name | `ads_service` command | Importance |
|---|---|---|
| `display_ads_billing_generator` | `display_ads_billing_generator` | 🔴 Critical |
| `display_ads_billing_checker` | `display_ads_billing_checker` | 🟢 Low |
| `display_ads_status_updater` | `display_ads_status_updater` | 🟠 High (planned decommission) |
| `translog_summary_live` | `translog_summary` | 🟢 Low |
| `notify ads credit expiry [ALL]` | `notify_ads_credit_expiry` | 🟢 Low |
| `shop_ads_whitelist` | `shop_ads_whitelist_checker` | 🟠 High |
| `db_observer_live` | `db_observer` | 🟢 Low |
| `preboost_campaign_surge_whitelist_live` | `update_pre_boost_whitelist_cache` | 🟢 Low |
| `LIVE \| KOL hive syncer` | (separate internal task) | 🟡 Medium |

CMDB task list: https://space.shopee.io/console/cmdb/cronjobs/tree/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.platform

---

## Development and Local Run

### Build, Test, and Proto Workflow

**Go version:** `go 1.24` (from `go.mod`).

| Command | Purpose |
|---|---|
| `make ads_service` | Build main service binary → `bin/paidads_ads_service_server` (native) and `bin/paidads_ads_service_server.linux` (cross-compiled) |
| `make ads_service_cronjob` | Build cronjob binary → `bin/paidads_ads_service_cronjob_server[.linux]` |
| `make test` | Run all tests with verbose output and coverage |
| `make test-nv` | Run tests without verbose output |
| `make ci` | Full CI simulation: `ci-vet` → `fmt` → `test-nv` |
| `make ci-lint` | Run `golangci-lint` via `spkit`; exits 1 if any lint issues are found (note: `--issues-exit-code 0` is used for the lint runner itself, but the Makefile explicitly checks the output file size and exits 1 on any findings) |
| `make fmt` | Run `go fmt` and fail if any files were reformatted |
| `make vet` | Run `go vet -all` |
| `make proto-compile` | Regenerate Go bindings from `sp_proto/paidads/ads_service.proto` only (`spcli proto gen --force` + `spex-generator`) |
| `make proto-ensure` | Full proto sync: fetch latest external protos + regenerate all bindings (`hspex-cli ensure` + `spcli proto ensure` + `spex-generator`) |
| `make update_textproc_data` | Download/update text-processing data into `data/` via `bash ./scripts/getdata.sh` |
| `make dep` | `go mod tidy` + `go mod download` |
| `make build-tool TOOL=<name>` | Build a one-off tool from `tool/<name>/` |

> **Note on `ci-lint`:** Although `golangci-lint` is invoked with `--issues-exit-code 0`, the Makefile then checks if `gl-code-quality-report.json` is larger than `{}` (3 bytes). If lint findings exist, `exit 1` is called. This means lint **does** block CI.

> **Proto generation prerequisites:** `hspex-cli`, `spcli`, and `spex-generator` must be available via `spkit`. On Linux, the Makefile applies a `chown` workaround for generated files in `protobuf/go/`.

### Entrypoints and Runtime Requirements

**Main service:**

```bash
# 1. Ensure data/ directory is present (same directory as cwd when running):
bash ./scripts/getdata.sh       # or: make update_textproc_data

# 2. Build and run (sets SP_UNIX_SOCKET for local SPEX):
make start
# Equivalent to:
#   make ads_service
#   SP_UNIX_SOCKET=/tmp/spex.sock ./bin/paidads_ads_service_server -c config/files/test.yml
```

**Cronjob binary:**

```bash
make ads_service_cronjob
./bin/paidads_ads_service_cronjob_server -c config/files/test.yml \
  display_ads_billing_generator --country SG --dry_run true
```

**Required dependencies for local run:**
- `data/` directory in cwd (text-processing model files). Without this, startup fails.
- A reachable SPEX socket or stub (set `SP_UNIX_SOCKET=/tmp/spex.sock` for local).
- Accessible Config Center endpoint (configured in `config/files/test.yml`).
- MySQL (via ads-DB, configured in `config/files/test.yml`).
- Redis (configured in `config/files/test.yml`).

**Dependency note:** `spex-generator` >= v2.2.0 is required from `paidads-platform-lib` releases (https://git.garena.com/shopee/deep/paidads-platform-lib/-/releases).

### Code Review & Git Workflow

- **Merge policy:** Merge Requests only. Squash commits, delete source branch after merge.
- **Branch naming:** `dev/$username` or `feature/$feature_name`.
- **MR title format (enforced by `check_mr_title` CI stage):** Must include a Jira ticket (`SPPA-XXXXX`) and follow `(Feat|Fix|Docs|Style|Refactor|Test|Chore): [<content>] <description>`. Example: `Feat: [SPPA-12345] Add optional escrow fee rate field`. For changes without a dedicated ticket, use `SPPA-65887`.
- **CI stages:** `check_mr_title` → `autotest` → `check` → `changelog` → `release`.
- **Proto changes:** Edit `.proto` source only; run `make proto-compile` after changes to `sp_proto/paidads/ads_service.proto`, or `make proto-ensure` for other proto files. Never edit files under `protobuf/go/` directly.
- **Error wrapping:** Always use `fmt.Errorf("... err: %w", err)` to preserve error chain; never log-and-return a stripped error.

---

## Configuration and Deployment

### Environment Config Files

Static config files live in `config/files/`:

| File | Environment |
|---|---|
| `test.yml` | Local development |
| `staging.yml` | Staging |
| `uat.yml` | UAT |
| `liveish.yml` | Liveish (shadow production) |
| `stable.yml` | Stable (pre-production) |
| `live.yml` | Production |

Each file maps to a `config.AdsService` struct and includes DB DSN groups, Redis addresses, SPEX service/env/tag, Config Center endpoint, and subsystem-specific settings.

### Runtime Config

Dynamic config is managed via two channels:

1. **Config Center (`config-sdk-go`):** Holds DB secrets (`AdsDbLib`, `AdsConfigSecret`) and bid-price config (`BidPrice`). Updated at runtime without restart.
2. **SPEX config key `"config"`:** Holds `AdsServiceSpexConfig` — whitelist definitions, API rate limits, DB toggle, traffic controllers, transaction-log settings, Display Ads GFS options, blacklist cache TTL, campaign-day config, keyword recommend v3 experiment version. Updated at runtime via `internalspex.WatchConfig`.

The SPEX config tag is overridden during deployment: setting `SPEX_SERVICE_TAG=alpha` or `SPEX_SERVICE_TAG=beta` in the build environment causes `mesos.sh` to rewrite `tag: master` → `tag: alpha/beta` in the config file before packaging.

### Mesos Build and Release

Deployment is handled by `deploy/mesos.sh` using a two-phase process:

**Build phase** (`ACTION=build`):
```bash
bash deploy/mesos.sh build ads_service ads_service $CONFIG_DIR $DATA_DIR
```
- Compiles the binary via `make ads_service` (with `EXTINFO=Env:${env}`).
- Optionally rewrites SPEX tag if `SPEX_SERVICE_TAG=alpha|beta`.
- Copies `config/{env}.yml` → `config.yml`, `data/`, `mesos.sh`, `deploy/{MODULE}.json`, `go.mod`, `go.sum` to a temp dir and replaces the workspace root.

**Run phase** (`ACTION=run`):
```bash
bash deploy/mesos.sh run ads_service ads_service
```
- Patches `#HTTP_PORT` in `config.yml` with the container-assigned `$PORT`.
- Executes `./paidads_ads_service_server.linux -config config.yml --log-prefix ""`.

For the cronjob binary, use `MODULE=ads_service_cronjob` and `BIN=ads_service_cronjob`.

---

## Monitoring and Operations

**Grafana dashboards** (advertiser-platform folder):

| Dashboard | Link |
|---|---|
| Advertiser Platform folder | https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform |
| Ads Overall Core Monitor | https://monitoring.infra.sz.shopee.io/grafana/d/RvLmQsMHk/ads-overall-core-monitor |
| Ads Deduction (Live Env) | https://monitoring.infra.sz.shopee.io/grafana/d/IRf-3Kjmk/ads-deduction-live-env |
| Ads Deduction - Deployment | https://monitoring.infra.sz.shopee.io/grafana/d/DDfWmKpnk/ads-deduction-deployment |
| Display Ads | https://monitoring.infra.sz.shopee.io/grafana/d/ggZ0wrRVk/display-ads |
| display-ads-billing | https://monitoring.infra.sz.shopee.io/grafana/d/sXfGzmxIk/display-ads-billing |
| Search-ads Service v3 | https://monitoring.infra.sz.shopee.io/grafana/d/XX2g2Tn4z/search-ads-service-v3 |
| Ads Count | https://monitoring.infra.sz.shopee.io/grafana/d/4cBj1iOVz/ads-count |
| Region Live Ads DB | https://monitoring.infra.sz.shopee.io/grafana/d/4RB9tsfIz/region-live-ads-db |

**Key Prometheus metrics** (from `internal/ads_service/exporter.go` and `cron_jobs/*/exporter.go`):

| Metric | Labels | Description |
|---|---|---|
| `paidads_ads_service_latency` | `country`, `component`, `name` | RPC latency in milliseconds |
| `paidads_ads_service_error` | `country`, `component`, `name`, `error` | Error counter per RPC |
| `paidads_ads_service_time_diff` | `country`, `component`, `name` | Time drift (for batch set APIs) |
| `paidads_ads_db_manager_count` | `queryName`, `caller` | DB query count per caller |
| Display Ads billing counter | (billing-specific labels) | From `cron_jobs/display_ads/exporter.go` |
| Shop Ads whitelist change | `whitelist_change` label | From `cron_jobs/shop_ads/exporter.go` |

**Log path** (example, actual path depends on SDU): `/home/toc/SDE/logs/ads_service/`

Alert rules are not defined in this repository; refer to the platform-level alerting configuration.

---

## Key Terms

| Term | Meaning |
|---|---|
| **Product Ads** | Keyword-based or auto-bidding ads tied to a specific product (item) |
| **Shop Ads** | Ads that promote an entire seller shop |
| **Display Ads** | Brand/CPM ads — impression-based, billed by billing_generator cronjob |
| **Live Stream Ads** | Ads placed during live streaming sessions |
| **Target Ads** | Audience-targeted ads (buyer segmentation) |
| **ads-DB** | The set of sharded MySQL databases powering ads_service, accessed via ads-db-lib |
| **translog** | Transaction log — the per-click deduction record stored in `translog_tab` (sharded by date) |
| **Config Center** | Shopee's centralized dynamic config service; holds DB secrets and runtime toggles |
| **GFS** | Global File Storage (USS adaptor) — used for Display Ads creative file uploads |
| **CPC** | Cost Per Click — standard Search/Product Ads billing model |
| **CPM** | Cost Per Mille — billing model for Display Ads |
| **eCPM** | Effective Cost Per Mille — total ad spend / total impressions |
| **ROI** | Return on Investment = Ads GMV / Ads Spend |
| **SPEX** | Shopee's internal RPC framework (similar to gRPC + service registry) |
| **spcli** | CLI tool for proto management (`spcli proto gen`, `spcli proto ensure`) |

---

## Additional Resources

- **Repository:** https://git.garena.com/shopee/deep/ads_service
- **Advertiser Platform Architecture (Confluence):** https://confluence.shopee.io/display/SPAD/Advertiser+Platform
- **Paid Ads Glossary:** https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- **Cronjob KB (Google Doc):** https://docs.google.com/document/d/1Z6VYs8vyJ-D914cU8wDBltrE6ItZ2TrhoZiXOSPkXmM/
- **Monitoring & Grafana Panel Summary (Google Doc):** https://docs.google.com/document/d/1xbEldfLSGJ5KsFjKk2IjZQfoI0XfQ8Ffwja0UKVHjNw/
- **CMDB Cronjob List:** https://space.shopee.io/console/cmdb/cronjobs/tree/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.platform
- **paidads-platform-lib releases** (spex-generator): https://git.garena.com/shopee/deep/paidads-platform-lib/-/releases
- **ads-db-lib:** https://git.garena.com/shopee/deep/ads-db-lib

---

## Frequently Asked Questions

**Q: Where are the RPC definitions?**  
`sp_proto/paidads/ads_service.proto` is the canonical source. The generated Go bindings are in `protobuf/go/paidads_ads_service.pb/`. Never edit the generated files directly — edit the `.proto` and run `make proto-compile`.

**Q: How do I know if an RPC is still active or deprecated?**  
Check `api/ads_service/server.go`. Active RPCs delegate to an activity or manager. Deprecated RPCs immediately return `ERROR_DEPRECATED` with a message to contact maintainers. Key active domains: Banner Ads, Auto Boost, Campaign Day, Keyword Recommend, Display Ads, Transaction Log, Report (query only — export_report has been removed), Whitelist/Fraud.

**Q: How do I run the service locally?**  
Ensure `data/` exists in your working directory (`bash ./scripts/getdata.sh` or `make update_textproc_data`), then run `make start`. This sets `SP_UNIX_SOCKET=/tmp/spex.sock` and starts the server with `config/files/test.yml`.

**Q: Why is the `data/` directory required?**  
It contains text-processing model files (simplified-to-traditional Chinese conversion, stemming) used by `internal/textproc`. Without it the service panics at startup.

**Q: How do I update proto files?**  
- If you changed `sp_proto/paidads/ads_service.proto`: run `make proto-compile`.  
- If you changed any other `.proto` file: run `make proto-ensure`.  
- Never edit files under `protobuf/go/`.

**Q: What is the difference between the main service and the cronjob binary?**  
Both are built from the same codebase and share the same config. `ads_service` is a long-running SPEX server that handles RPC requests. `ads_service_cronjob` is a run-once CLI that executes a named command (e.g., `display_ads_billing_generator`) and exits. Each command is scheduled externally via CMDB.

**Q: Where is dynamic config changed?**  
- **DB secrets / `AdsConfigSecret` / `BidPrice`:** Config Center (the key names are in `config.AdsService.ConfigCenterSecrets`).  
- **Whitelist rules, rate limits, DB toggle, GFS options, keyword recommend experiment version, etc.:** The SPEX `config` key (updated via the SPEX console or `spkit`).

**Q: How does the SPEX `alpha`/`beta` tag affect config?**  
If `SPEX_SERVICE_TAG=alpha` or `beta` is set during the Mesos build phase, `mesos.sh` rewrites `tag: master` → `tag: alpha/beta` in the env config file. This makes the service subscribe to the corresponding SPEX config tag instead of `master`.

**Q: What does `ci-lint` actually do?**  
It runs `golangci-lint` with `.golangci.yml` and outputs results to `gl-code-quality-report.json`. Even though the linter is called with `--issues-exit-code 0`, the Makefile checks if the JSON output is larger than `{}` (3 bytes) and calls `exit 1` if there are any findings. Lint failures **do** block CI.

**Q: What is the `translator` module used for?**  
`internal/translator` wraps the Transify i18n service. Two separate manager instances are initialized: one for general keyword/ad text translation and one specifically for search brand ads text. This enables multi-language ad copy across Shopee's markets.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 99fcf4adde51a4acdb1fd4a7d978e772fb6f80de | spec: 76fce5f679f9550b -->
