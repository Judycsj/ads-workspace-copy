<!-- ads-workspace-gdoc-sync: gdoc_id=1HuCdRdc0j01vHEfFc58KeV7qO_NGuH91V8gvh_l3_SU gdoc_url=https://docs.google.com/document/d/1HuCdRdc0j01vHEfFc58KeV7qO_NGuH91V8gvh_l3_SU/edit -->

# ads_service

**仓库地址：** https://git.garena.com/shopee/deep/ads_service

---

## 目录 / Table of Contents

1. [项目概述](#项目概述)
2. [核心功能](#核心功能)
3. [项目架构](#项目架构)
4. [目录结构](#目录结构)
5. [SPEX 与业务模块](#spex-与业务模块)
   - [服务入口与协议](#服务入口与协议)
   - [核心业务域](#核心业务域)
   - [外部依赖与存储](#外部依赖与存储)
6. [定时任务](#定时任务)
   - [代码命令与线上任务](#代码命令与线上任务)
7. [开发与本地运行](#开发与本地运行)
   - [构建、测试与 Proto 流程](#构建测试与-proto-流程)
   - [运行入口与运行时依赖](#运行入口与运行时依赖)
   - [Code Review & Git Workflow](#code-review--git-workflow)
8. [配置与部署](#配置与部署)
   - [环境配置文件](#环境配置文件)
   - [动态配置](#动态配置)
   - [Mesos 构建与发布](#mesos-构建与发布)
9. [监控与排障](#监控与排障)
10. [关键术语](#关键术语)
11. [参考资料](#参考资料)
12. [常见问题](#常见问题)

---

## 项目概述

`ads_service` 是 Shopee Paid Ads **广告主平台的核心后端服务**。它负责广告数据的全生命周期管理，包括账户管理、Campaign/广告创建、关键词出价、扣费流水记录、Display Ads 账单生成、报表查询以及白名单/欺诈用户管理，覆盖所有 Shopee 市场（SG、MY、TH、ID、VN、PH、TW、BR、MX）。

服务通过 Shopee SPEX RPC 框架（`paidads.ads_service.*`）对外暴露 API，被 `ads-marketing`、`sku-selector`、`paidadsbackendadmin`、`ultimate_ads_service` 等上游服务调用。这些上游服务位于卖家前端与本后端之间。

与主服务共用同一份代码库的 `ads_service_cronjob` 二进制文件负责定时维护任务。

**本地运行关键依赖：** 运行服务二进制时，`data/` 目录必须与工作目录处于同级（通过 `bash ./scripts/getdata.sh` 填充）。缺少该目录时服务会在启动时崩溃。

---

## 核心功能

能力来源于 `sp_proto/paidads/ads_service.proto` 和 `internal/` 模块结构：

| 业务域 | 能力 |
|---|---|
| **账户** | 广告账户余额查询、钱包详情、免费 Credit 列表、即将过期 Credit、手动充值、Credit 子类型管理、卖家任务账户 |
| **Campaign** | Campaign Day 管理（查询/添加/删除/统计）、Campaign 消耗查询 |
| **Banner Ads** | 创建/查询/更新 Banner Ads Campaign、更新 Campaign 状态、获取店铺保留关键词 |
| **广告 / 关键词** | 关键词出价扫描（v2）、关键词黑名单 CRUD（查询/添加/更新/黑名单判断）、关键词白名单管理、关键词推荐（搜索广告 + Shop Ads）、建议出价（搜索广告 + Shop Ads） |
| **扣费流水** | 查询扣费及充值流水（CPC/CPM/Credit），translog 汇总 |
| **Display Ads** | 完整生命周期：日历信息、CPM 定价、公司档案、账单生成与校验、创意上传、状态管理、管理员消息、自定义受众、店铺白名单检查 |
| **报表** | `query_report`、`get_agg_report` |
| **Auto Boost** | 查询/扫描 Auto Boost 广告，获取合格 SKU |
| **白名单 / 欺诈** | 白名单类型管理、添加/删除/查询白名单用户（白名单扩展信息包含 `EscrowWhitelistExtInfo`，新增 `optional_fee_rate` 和 `optional_fee_rate_change_type` 字段，用于管理员配置可选 Escrow 费率）、欺诈用户 CRUD（查询/添加/删除）、欺诈原因 |
| **Discovery Ads 建议出价** | Discovery Ads 建议出价（活跃）；Target Ads 和 Segment 建议出价已废弃 |
| **通知** | 管理员消息、Push 通知、Credit 到期通知、推荐评分 |

---

## 项目架构

`ads_service` 是一个 Go SPEX 服务。启动流程（来自 `init/ads_service/run.go`）如下：

1. **加载配置** — `uniconfig` 读取 `config/files/{env}.yml`。
2. **连接 Config Center** — `config-sdk-go` 客户端，用于动态配置键管理。
3. **初始化 DB Manager** — 由 `ads-db-lib` 支撑的 `DBLibManager`，同时嵌入 `dblib.DBManager` 和 `dblib.IDMappingClient`（通过 `IDMappingCache` DB 组），与 Config Center 集成支持密钥热更新。`IDMappingClient` 支持通过 AdsID/ShopID 查找 UserID，实现基于主键的 DB 分片路由。
4. **初始化 HTTP-over-SPEX** — `hos.InitClient`（`mktzlib/http_over_spex`）。
5. **初始化 SPEX Agent** — `paidads-platform-lib/spex/v2`，注册前缀为 `paidads.ads_service`。
6. **订阅 SPEX 配置** — 从 SPEX agent 的 `config` 键加载 `AdsServiceSpexConfig`，通过 watcher goroutine 热更新。
7. **初始化辅助子系统** — 保留关键词管理器、Redis 锁、限流器（通用+Campaign）、通知器、textproc、RNG endpoint、欺诈用户缓存（Redis）、Target Ads 出价客户端（gRPC+etcd，两个实例：suggest bid price 和 segment bid price）、关键词推荐客户端（`search_kw_rcmd`）、通用缓存管理器、临时存储（Redis）、Display Ads 配置管理器、成人类目管理器、商品数据管理器、广告配置管理器、Shop Ads 资格管理器、用户店铺缓存、白名单管理器、出价价格管理器、Display Ads 溢价率缓存、翻译器管理器（通用+搜索品牌）、配置仓库、GFS（USS）初始化。
8. **组装并注册服务** — `api/ads_service.NewServer(...)` 完成组装，`AdsServiceProcessor` 注册至 SPEX。
9. **监听请求** — 等待关机信号。

```
卖家中心 / MCN Portal / Open API / Admin Portal
              │ (HTTP → SPEX)
         ads-marketing / sku-selector
              │ (SPEX)
         ┌────▼────────────────────────────┐
         │         ads_service (SPEX)      │
         │  paidads.ads_service.*          │
         │                                 │
         │  ┌──────────────┐  ┌─────────┐  │
         │  │  ads-DB      │  │  Redis  │  │
         │  │ (MySQL 分片) │  │ (缓存/  │  │
         │  └──────────────┘  │  分布锁)│  │
         │  ┌──────────────┐  └─────────┘  │
         │  │ Config Center│               │
         │  └──────────────┘  ┌─────────┐  │
         │  ┌──────────────┐  │  Kafka  │  │
         │  │ GFS (USS)    │  │ (日志)  │  │
         │  └──────────────┘  └─────────┘  │
         └─────────────────────────────────┘
              │ (SPEX / gRPC client)
         paidads-targetads-ad-bidding / webservice / notifier / textproc / translator
```

**上下游调用拓扑（来源：Confluence Advertiser Platform KB）：**

| 类型 | 服务 / 组件 | 协议 | 描述 |
|---|---|---|---|
| **上游调用方** | `ads-marketing`、`sku-selector` | SPEX | 卖家侧主要 RPC 调用方 |
| **上游调用方** | `paidadsbackendadmin` | SPEX | 运营后台 |
| **上游调用方** | `ultimate_ads_service` | SPEX | 广告 DB 网关服务 |
| **下游 / 依赖** | `ads-DB`（`ads-db-lib`，MySQL 分片）| MySQL via goorm | 主数据库；7 个逻辑 DB 组，按 userid/campaignid/date 分片 |
| **下游 / 依赖** | Redis | redis/v8 | 缓存层（通用缓存、分布式锁、黑名单缓存、临时存储、欺诈用户缓存、用户店铺内存缓存） |
| **下游 / 依赖** | Config Center（`config-sdk-go`）| HTTP | 动态配置与 DB 密钥管理 |
| **下游 / 依赖** | GFS / USS | gRPC | Display Ads 创意文件存储 |
| **下游 / 依赖** | Kafka（via `paidads-platform-lib/log`）| Kafka | 日志投递 |
| **下游 / 依赖** | `paidads-targetads-ad-bidding` | gRPC+etcd | Target Ads / Segment Ads 建议出价（两个独立客户端实例） |
| **下游 / 依赖** | webservice（HTTP over SPEX）| SPEX | 外部数据服务（商品数据、成人类目、关键词推荐） |
| **下游 / 依赖** | Transify（translator）| HTTP | 关键词/品牌广告文本的 i18n 翻译 |

---

## 目录结构

```
ads_service/
├── api/ads_service/       # SPEX server 组装 — NewServer()、handler 注册
├── config/
│   ├── files/             # 静态环境配置：test.yml、staging.yml、live.yml、liveish.yml、stable.yml、uat.yml
│   ├── config.go          # Config 结构体定义（AdsService、AdsDBLibOption 等）
│   └── reload.go          # 配置热重载工具
├── cron_jobs/             # 所有定时任务命令实现
│   ├── display_ads/       # billing_generator、billing_checker、status_updater
│   ├── shop_ads/          # blacklist_checker、whitelist_checker
│   ├── ads_credit_expiry_notifier.go
│   ├── ads_preboost_whitelist_cache_updater.go
│   ├── db_observer.go
│   └── translog_summary.go
├── data/                  # 文本处理数据（未提交到 Git；通过 scripts/getdata.sh 填充）
├── deploy/
│   ├── mesos.sh           # Mesos 两阶段构建/运行脚本
│   ├── adsservice.json    # 主服务 Mesos 部署描述文件
│   └── adsservicecronjob.json  # Cronjob 二进制 Mesos 部署描述文件
├── init/
│   ├── ads_service/       # main + run.go — 主服务入口
│   └── ads_service_cronjob/ # main.go — Cronjob 二进制入口
├── internal/              # 所有业务逻辑（不对外暴露）
│   ├── ads_service/       # Prometheus exporter（latency、error、time_diff、DB count）、共享常量
│   ├── ads_account/       # 账户余额管理、钱包详情、免费 Credit
│   ├── ads_config/        # 广告配置管理器（由 Config Center AdsConfigSecret 支撑）
│   ├── ads_credit_subtype/# 广告 Credit 子类型查询/设置
│   ├── ads_helper/        # Campaign/广告/关键词变更的审计事件处理器（AdsAuditHandler 接口 + DB 支撑实现）
│   ├── ads_manual_topup/  # 手动充值 Activity
│   ├── adsadminclient/    # Admin 服务客户端
│   ├── admin_message/     # 管理员消息 Controller（DB + notifier + 搜索品牌 translator）
│   ├── adult_category/    # 成人类目校验（通过 webservice）
│   ├── auto_boost/        # Auto Boost 广告：查询/扫描/合格 SKU
│   ├── banner_ads/        # Banner Ads CRUD 子包（create、get、update、list、update_campaign_status、get_shop_reserved_keyword）
│   ├── bid_price/         # 出价价格管理器（Config Center 支撑）
│   ├── campaign_day/      # Campaign Day 数据工具
│   ├── campaign_info/     # Campaign CRUD 工具、Campaign 消耗
│   ├── config_center/     # Config Center 客户端封装
│   ├── db_manager/        # ads-db-lib 管理器初始化
│   ├── display_ads/       # Display Ads 配置管理器、账单、溢价率缓存、创意管理、自定义受众
│   ├── expiring_credit/   # 即将过期 Credit 工具
│   ├── fraud_user/        # 欺诈用户管理（DB 支撑）、欺诈原因
│   ├── item_boost/        # Item Boost 套餐与可变定价管理
│   ├── item_data/         # 商品数据获取（通过 webservice）
│   ├── keyword/           # 关键词出价扫描（v2）
│   ├── keyword_blacklist/ # 关键词黑名单管理（查询/添加/更新/判断）
│   ├── keyword_whitelist/ # 保留关键词白名单 CRUD 和审计
│   ├── kw_rcmd/           # 关键词推荐 + 建议出价编排
│   ├── notifier/          # SeaTalk / 邮件通知
│   ├── qps_rate_limiter/  # QPS 限流器
│   ├── recommend_score/   # 推荐评分（通过 webservice）
│   ├── redis_locker/      # 分布式锁（Redis 支撑）
│   ├── report/            # 基于 RNG 的报表查询（query_report、get_agg_report）
│   ├── repository/config/ # 配置仓库 — 订阅 Config Center `ads_service_{env}_default` 命名空间；提供每地区 `AdsCacheConfig`（缓存 TTL）和 `FeatureDowngradeConfig`（降级开关）
│   ├── search_kw_rcmd/    # 搜索关键词推荐客户端
│   ├── shop_ads/          # Shop Ads 资格检查
│   ├── spex/              # `AdsServiceSpexConfig` — 热更新动态配置
│   ├── suggest_price/     # Discovery Ads 建议出价计算
│   ├── sync_log/          # 同步日志工具
│   ├── temp_storage/      # 临时存储（Redis 支撑）
│   ├── textproc/          # 文本处理（简繁转换、词干提取）— 需要 data/ 目录
│   ├── topup_translog/    # 充值流水工具
│   ├── traffic_controller/# 流量控制工具
│   ├── transaction_log/   # Translog 配置与处理
│   ├── translator/        # Transify i18n 翻译管理器（通用 + 搜索品牌）
│   ├── webservice/        # HTTP over SPEX 管理器（外部数据服务）
│   ├── whitelist/         # 白名单 Activity（类型/用户 CRUD，基于 whitelist_manager）
│   └── whitelist_manager/ # 白名单 CRUD，DB + 缓存双写
├── pkg/
│   ├── cache/             # 通用缓存管理器（Redis 支撑）
│   └── reserved_keyword_manager/ # 保留关键词管理
├── protobuf/go/           # 自动生成的 Go protobuf 绑定（禁止手动编辑）
├── scripts/
│   └── getdata.sh         # 下载文本处理数据到 data/ 目录
├── sp_proto/paidads/
│   └── ads_service.proto  # 标准 RPC 协议定义（4111 行）
├── sp-workspace.yml       # SPEX generator workspace 配置
├── textproc.xml           # 文本处理插件配置
├── tool/                  # 一次性运营/修复工具集合（非生产主链路）
├── utils/                 # 共享工具函数：Display Ads/Shop Ads/Campaign 索引的主键路由构建器（BuildAdvertisementPrimaryKeysFromDisplayAdsIndex、BuildCampaignPrimaryKeysFromDisplayAdsIndex、BuildCampaignPrimaryKeysFromShopAdsIndex）、UniquePositiveNum、数值工具
└── Makefile
```

---

## SPEX 与业务模块

### 服务入口与协议

主服务二进制从 `init/ads_service/` 构建，以 SPEX worker 身份注册，命名空间前缀为 `paidads.ads_service`（定义于 `protobuf/go/paidads_ads_service.pb`）。

完整 RPC 协议定义在 `sp_proto/paidads/ads_service.proto` 中。活跃（非废弃）RPC 族群（来源：`api/ads_service/server.go` 验证）：

- **账户：** `get_ads_account`、`get_wallet_detail`、`list_free_ads_credit`、`get_expiring_credit_amount`、`ads_manual_topup`、`get_seller_mission_ads_account`、`get_ads_credit_subtypes`、`set_ads_credit_subtypes`
- **Campaign Day：** `get_campaign_days`、`add_campaign_day`、`delete_campaign_day`、`get_campaign_day_stats`
- **Campaign：** `get_campaign_expense`
- **Banner Ads：** `create_banner_ads`、`get_banner_ads`、`update_banner_ads`、`list_banner_ads_campaigns`、`update_campaign_status`、`get_shop_reserved_keyword`
- **Auto Boost：** `get_auto_boost_ads`、`scan_auto_boost_campaigns`、`get_qualified_sku`
- **关键词 / 黑名单：** `scan_advertisement_keyword_v2`、`get_blacklist_keyword`、`add_blacklist_keyword`、`update_blacklist_keyword`、`is_keyword_blacklisted`、`get_reserved_keyword_whitelist`、`set_reserved_keyword_whitelist`、`get_reserved_keyword_whitelist_audit`
- **关键词推荐 / 建议出价：** `get_search_ads_keyword_recommend`、`get_shop_ads_keyword_recommend`、`get_search_ads_keyword_suggest_price`、`get_shop_ads_keyword_suggest_price`、`trigger_keyword_suggest_log`
- **扣费流水：** `get_transaction_log`、`get_transaction_log_with_v1_override`、`get_topup_translog`
- **Display Ads：** `get_display_ads_list`、`get_display_ads_detail`、`create_display_ads`、`edit_display_ads`、`set_display_ads_status`、`upload_creative_image`、`upload_display_ads_creative`、`get_display_ads_calendar_info`、`get_display_ads_cpm_info`、`get_display_ads_company_profiles`、`upload_display_shop_billing_info`、`get_display_ads_admin_message`、`set_display_ads_admin_message`、`check_shop_whitelist`、`get_display_ads_custom_audience`
- **报表：** `query_report`、`get_agg_report`
- **白名单 / 欺诈：** `get_whitelist_type`、`add_whitelist_users`、`delete_whitelist_users`、`get_whitelist_users`、`get_fraud_users`、`add_fraud_users`、`delete_fraud_users`、`get_fraud_reasons`
- **建议出价：** `get_discovery_ads_suggest_price`
- **管理员 / 通知：** `send_notification`、`get_recommend_score`
- **Item Boost：** `get_item_boost_variable_settings`、`add_item_boost_variable_setting`、`get_item_boost_user_custom_package`、`set_item_boost_user_custom_package`

> **已废弃的 RPC**（返回 `ERROR_DEPRECATED`）：`get_ads`、`get_campaigns`、`set_account`、`get_ads_item_index`、`get_campaign_list`、`get_ads_list`、`get_ads_list_by_keyword`、`create_auto_shop_ads`、`update_auto_shop_ads_status`、`get_auto_shop_ads`、`get_shop_ads_index`、`get_target_ads_suggest_price`、`get_target_ads_segment_suggest_price`、`get_item_boost_estimated_quota`、`get_item_boost_estimated_order`、`set_advertise_batch`、`set_advertise_batch_with_snapshot`，以及所有 BuyerSegment 相关 RPC。请勿调用这些接口 — 如需替代方案请联系维护者。

handler 组装发生在 `api/ads_service/server.go`。`NewServer()` 函数从 `init/ads_service/run.go` 接收所有已初始化的管理器（DB、缓存、webservice 等）并返回 SPEX processor 接口的实现。

### 核心业务域

业务逻辑完全位于 `internal/`。核心模块：

| 模块 | 职责 |
|---|---|
| `internal/ads_account` | 账户余额 CRUD、Credit 管理、钱包详情、免费 Credit、卖家任务账户 |
| `internal/ads_config` | 广告配置管理器（由 Config Center `AdsConfigSecret` 支撑） |
| `internal/ads_credit_subtype` | 广告 Credit 子类型查询/设置 |
| `internal/ads_helper` | 广告审计事件处理器 — 构建审计事件并将 Campaign、广告、关键词变更日志写入 ads-DB，通过 `AdsAuditHandler` 接口实现，供 `banner_ads` 各模块调用 |
| `internal/ads_manual_topup` | 手动充值 Activity（通过 webservice） |
| `internal/admin_message` | 管理员消息 Controller（DB + notifier + 搜索品牌 translator） |
| `internal/auto_boost` | Auto Boost 广告：查询/扫描广告、获取合格 SKU |
| `internal/banner_ads/*` | Banner Ads CRUD 子包：`create_banner_ads`、`get_banner_ads`、`get_shop_reserved_keyword`、`list_banner_ads_campaigns`、`update_banner_ads`、`update_campaign_status` |
| `internal/campaign_info` | Campaign 数据访问工具，Campaign 消耗 |
| `internal/campaign_day` | Campaign Day CRUD |
| `internal/keyword` | 关键词出价扫描（v2） |
| `internal/keyword_blacklist` | 关键词黑名单查询/添加/更新/判断 |
| `internal/keyword_whitelist` | 保留关键词白名单 CRUD 和审计 |
| `internal/display_ads` | Display Ads 配置管理器、账单对象、溢价率缓存、自定义受众、管理员消息 |
| `internal/transaction_log` | Translog 配置与处理 |
| `internal/report` | 基于 RNG 的报表查询（`query_report`、`get_agg_report`） |
| `internal/recommend_score` | 推荐评分（通过 webservice） |
| `internal/shop_ads` | Shop Ads 资格检查 |
| `internal/whitelist` | 白名单 Activity（类型/用户 CRUD，基于 whitelist_manager） |
| `internal/whitelist_manager` | 白名单 CRUD，DB + 缓存双写 |
| `internal/bid_price` | 出价价格管理器（Config Center 支撑） |
| `internal/suggest_price` | Discovery Ads 建议出价计算 |
| `internal/item_boost` | Item Boost 套餐与可变定价管理 |
| `internal/item_data` | 商品数据获取（通过 webservice） |
| `internal/adult_category` | 成人类目校验（通过 webservice） |
| `internal/fraud_user` | 欺诈用户管理（DB 支撑）、欺诈原因 |
| `internal/search_kw_rcmd` | 搜索关键词推荐客户端 |
| `internal/kw_rcmd` | 关键词推荐 + 建议出价编排层 |
| `internal/translator` | Transify i18n 翻译（通用 + 搜索品牌，两个管理器实例） |
| `internal/spex` | `AdsServiceSpexConfig` — 热更新动态配置 |
| `internal/db_manager` | `ads-db-lib` 管理器初始化与 Config Center 密钥集成 |
| `internal/config_center` | Config Center 客户端封装 |
| `internal/webservice` | HTTP over SPEX 管理器（外部数据服务） |
| `internal/notifier` | SeaTalk / 邮件通知 |
| `internal/textproc` | 文本处理（简繁转换、词干提取）— 需要 `data/` 目录 |
| `internal/redis_locker` | 分布式锁（Redis 支撑） |
| `internal/temp_storage` | 临时存储（Redis 支撑） |
| `internal/traffic_controller` | 流量控制工具 |
| `internal/repository/config` | 配置仓库 — 订阅 Config Center 命名空间 `ads_service_{env}_default`；提供每地区 `AdsCacheConfig`（缓存 TTL、key 配置）和 `FeatureDowngradeConfig`（功能降级开关）；供 `transaction_log` 和 `campaign_day` Activity 消费 |

### 外部依赖与存储

| 依赖 | 用途 |
|---|---|
| **ads-DB**（`ads-db-lib` v0.127.1）| 主数据库：7 个逻辑 DB 组（Core、SRM、Marketing、Ops、Rebate、Booking、CRM），MySQL 分片（按 userid/campaignid/date）。通过 `internal/db_manager` 访问。`DBLibManager` 现在也实现了 `dblib.IDMappingClient`（通过 `IDMappingCache` DB 组），支持为 Display Ads、Auto Boost、Shop Ads 及 Campaign 查询提供主键路由（UserID + CampaignID/AdsID），在调用方未提供 UserID 时避免跨分片 scatter-gather。 |
| **Redis** | 多角色：通用缓存（`pkg/cache`）、分布式锁（`internal/redis_locker`）、黑名单缓存、临时存储（`internal/temp_storage`）、欺诈用户缓存、用户店铺内存缓存（Redis 支撑）。 |
| **Config Center** | 动态配置与 DB 密钥管理。键名包括 `AdsDbLib`、`AdsConfigSecret`、`BidPrice`。通过 `internal/config_center` 管理。 |
| **GFS（USS / `discover-landing/uss-go`）**| Display Ads 创意文件存储。配置项位于 `AdsServiceSpexConfig.DisplayAdsStorage`。 |
| **Kafka** | 日志投递（via `paidads-platform-lib/log`）。 |
| **paidads-targetads-ad-bidding** | gRPC 客户端，用于 Target Ads 和 Segment Ads 建议出价（两个独立客户端实例）。 |
| **textproc / `data/`** | 关键词归一化文本处理（简繁转换、词干提取）。需要本地 `data/` 目录。 |
| **Transify（translator）**| i18n 翻译服务，用于关键词和搜索品牌广告文本翻译（两个管理器实例：通用和搜索品牌）。 |

---

## 定时任务

### 代码命令与线上任务

`ads_service_cronjob` 二进制从 `init/ads_service_cronjob/main.go` 构建，与主服务共用同一份 `config.AdsService` 配置和 DB/缓存初始化。命令通过 `--country` 和 `--dry_run` 标志运行。

| 代码命令名 | 源文件 | 描述 |
|---|---|---|
| `notify_ads_credit_expiry` | `cron_jobs/ads_credit_expiry_notifier.go` | 扫描并通知即将过期 Credit 的卖家 |
| `display_ads_billing_generator` | `cron_jobs/display_ads/billing_generator.go` | 生成 Display Ads 账单记录（🔴 Critical） |
| `display_ads_billing_checker` | `cron_jobs/display_ads/billing_checker.go` | 校验 Display Ads 账单准确性 |
| `display_ads_status_updater` | `cron_jobs/display_ads/status_updater.go` | Display Ads 状态机（计划下线） |
| `update_pre_boost_whitelist_cache` | `cron_jobs/ads_preboost_whitelist_cache_updater.go` | 刷新预推广活动激增白名单缓存 |
| `shop_ads_blacklist_checker` | `cron_jobs/shop_ads/blacklist_checker.go` | 检查并更新 Shop Ads 黑名单 |
| `shop_ads_whitelist_checker` | `cron_jobs/shop_ads/whitelist_checker.go` | 检查并更新 Shop Ads 白名单 |
| `db_observer` | `cron_jobs/db_observer.go` | 监控数据库变化，触发后续处理 |
| `translog_summary` | `cron_jobs/translog_summary.go` | 聚合扣费日志，预计算充值变化 |

与 CMDB 线上任务的对应关系（来源：KB）：

| CMDB 任务名 | `ads_service` 命令 | 重要程度 |
|---|---|---|
| `display_ads_billing_generator` | `display_ads_billing_generator` | 🔴 Critical |
| `display_ads_billing_checker` | `display_ads_billing_checker` | 🟢 Low |
| `display_ads_status_updater` | `display_ads_status_updater` | 🟠 High（计划下线） |
| `translog_summary_live` | `translog_summary` | 🟢 Low |
| `notify ads credit expiry [ALL]` | `notify_ads_credit_expiry` | 🟢 Low |
| `shop_ads_whitelist` | `shop_ads_whitelist_checker` | 🟠 High |
| `db_observer_live` | `db_observer` | 🟢 Low |
| `preboost_campaign_surge_whitelist_live` | `update_pre_boost_whitelist_cache` | 🟢 Low |
| `LIVE \| KOL hive syncer` | （内部独立任务）| 🟡 Medium |

CMDB 任务列表：https://space.shopee.io/console/cmdb/cronjobs/tree/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.platform

---

## 开发与本地运行

### 构建、测试与 Proto 流程

**Go 版本：** `go 1.24`（来源：`go.mod`）。

| 命令 | 用途 |
|---|---|
| `make ads_service` | 构建主服务二进制 → `bin/paidads_ads_service_server`（本地）和 `bin/paidads_ads_service_server.linux`（交叉编译） |
| `make ads_service_cronjob` | 构建 Cronjob 二进制 → `bin/paidads_ads_service_cronjob_server[.linux]` |
| `make test` | 带 verbose 输出和覆盖率运行所有测试 |
| `make test-nv` | 不带 verbose 输出运行测试 |
| `make ci` | 完整 CI 模拟：`ci-vet` → `fmt` → `test-nv` |
| `make ci-lint` | 通过 `spkit` 运行 `golangci-lint`；存在 lint 问题时退出码为 1（注意：linter 本身使用 `--issues-exit-code 0`，但 Makefile 通过检查输出文件大小显式调用 `exit 1`） |
| `make fmt` | 运行 `go fmt`，若有文件被格式化则失败 |
| `make vet` | 运行 `go vet -all` |
| `make proto-compile` | 仅从 `sp_proto/paidads/ads_service.proto` 重新生成 Go 绑定（`spcli proto gen --force` + `spex-generator`） |
| `make proto-ensure` | 完整 proto 同步：拉取最新外部 proto + 重新生成所有绑定（`hspex-cli ensure` + `spcli proto ensure` + `spex-generator`） |
| `make update_textproc_data` | 通过 `bash ./scripts/getdata.sh` 下载/更新文本处理数据到 `data/` |
| `make dep` | `go mod tidy` + `go mod download` |
| `make build-tool TOOL=<name>` | 从 `tool/<name>/` 构建一次性工具 |

> **关于 `ci-lint`：** 虽然 `golangci-lint` 使用 `--issues-exit-code 0` 调用，但 Makefile 之后会检查 `gl-code-quality-report.json` 是否大于 `{}`（3 字节），若存在 lint 问题则调用 `exit 1`。lint 失败**会**阻断 CI。

> **Proto 生成前提：** `hspex-cli`、`spcli` 和 `spex-generator` 必须通过 `spkit` 可用。在 Linux 上，Makefile 会对 `protobuf/go/` 下生成的文件执行 `chown` 修复（workaround for SPPE-2787）。

### 运行入口与运行时依赖

**主服务：**

```bash
# 1. 确保 data/ 目录存在（与工作目录同级）：
bash ./scripts/getdata.sh       # 或：make update_textproc_data

# 2. 构建并运行（设置 SP_UNIX_SOCKET 用于本地 SPEX）：
make start
# 等价于：
#   make ads_service
#   SP_UNIX_SOCKET=/tmp/spex.sock ./bin/paidads_ads_service_server -c config/files/test.yml
```

**Cronjob 二进制：**

```bash
make ads_service_cronjob
./bin/paidads_ads_service_cronjob_server -c config/files/test.yml \
  display_ads_billing_generator --country SG --dry_run true
```

**本地运行必要依赖：**
- `data/` 目录与当前工作目录同级（文本处理模型文件，缺少则启动崩溃）。
- 可达的 SPEX socket 或 stub（本地设置 `SP_UNIX_SOCKET=/tmp/spex.sock`）。
- 可访问的 Config Center 端点（在 `config/files/test.yml` 中配置）。
- MySQL（通过 ads-DB，在 `config/files/test.yml` 中配置）。
- Redis（在 `config/files/test.yml` 中配置）。

**依赖说明：** 需要从 `paidads-platform-lib` releases 获取 `spex-generator` >= v2.2.0（https://git.garena.com/shopee/deep/paidads-platform-lib/-/releases）。

### Code Review & Git Workflow

- **合并策略：** 仅通过 Merge Request 合并。Squash commit，合并后删除源分支。
- **分支命名：** `dev/$username` 或 `feature/$feature_name`。
- **MR 标题格式（由 CI `check_mr_title` 阶段强制校验）：** 必须包含 Jira ticket（`SPPA-XXXXX`），格式为 `(Feat|Fix|Docs|Style|Refactor|Test|Chore): [<内容>] <描述>`。示例：`Feat: [SPPA-12345] Add optional escrow fee rate field`。无独立 ticket 的变更可使用 `SPPA-65887`。
- **CI 阶段：** `check_mr_title` → `autotest` → `check` → `changelog` → `release`。
- **Proto 变更：** 只编辑 `.proto` 源文件；修改 `sp_proto/paidads/ads_service.proto` 后运行 `make proto-compile`，修改其他 proto 文件后运行 `make proto-ensure`。禁止直接编辑 `protobuf/go/` 下的文件。
- **错误包装：** 始终使用 `fmt.Errorf("... err: %w", err)` 保留错误链；禁止先 log 再返回丢失上下文的新错误。

---

## 配置与部署

### 环境配置文件

静态配置文件位于 `config/files/`：

| 文件 | 环境 |
|---|---|
| `test.yml` | 本地开发 |
| `staging.yml` | Staging |
| `uat.yml` | UAT |
| `liveish.yml` | Liveish（影子生产） |
| `stable.yml` | Stable（预生产） |
| `live.yml` | 生产 |

每个文件对应 `config.AdsService` 结构体，包含 DB DSN 组、Redis 地址、SPEX 服务/环境/标签、Config Center 端点以及各子系统配置。

### 动态配置

动态配置通过两个渠道管理：

1. **Config Center（`config-sdk-go`）：** 持有 DB 密钥（`AdsDbLib`、`AdsConfigSecret`）和出价价格配置（`BidPrice`）。运行时更新，无需重启。
2. **SPEX 配置键 `"config"`：** 持有 `AdsServiceSpexConfig` — 白名单定义、API 限流配置、DB toggle、流量控制器、Translog 设置、Display Ads GFS 选项、黑名单缓存 TTL、Campaign Day 配置、关键词推荐 v3 实验版本配置。通过 `internalspex.WatchConfig` 运行时热更新。

部署时 SPEX 配置 tag 会被覆盖：在构建环境中设置 `SPEX_SERVICE_TAG=alpha` 或 `SPEX_SERVICE_TAG=beta` 后，`mesos.sh` 会将配置文件中的 `tag: master` 改写为 `tag: alpha/beta`。

### Mesos 构建与发布

部署通过 `deploy/mesos.sh` 的两阶段流程执行：

**构建阶段**（`ACTION=build`）：
```bash
bash deploy/mesos.sh build ads_service ads_service $CONFIG_DIR $DATA_DIR
```
- 通过 `make ads_service`（附带 `EXTINFO=Env:${env}`）编译二进制。
- 若 `SPEX_SERVICE_TAG=alpha|beta`，则改写 SPEX tag。
- 将 `config/{env}.yml` → `config.yml`、`data/`、`mesos.sh`、`deploy/{MODULE}.json`、`go.mod`、`go.sum` 复制到临时目录并替换工作区根目录。

**运行阶段**（`ACTION=run`）：
```bash
bash deploy/mesos.sh run ads_service ads_service
```
- 将 `config.yml` 中的 `#HTTP_PORT` 替换为容器分配的 `$PORT`。
- 执行 `./paidads_ads_service_server.linux -config config.yml --log-prefix ""`。

Cronjob 二进制使用 `MODULE=ads_service_cronjob`、`BIN=ads_service_cronjob`。

---

## 监控与排障

**Grafana 监控面板**（advertiser-platform 文件夹）：

| 面板 | 链接 |
|---|---|
| Advertiser Platform 文件夹 | https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform |
| Ads Overall Core Monitor | https://monitoring.infra.sz.shopee.io/grafana/d/RvLmQsMHk/ads-overall-core-monitor |
| Ads Deduction (Live Env) | https://monitoring.infra.sz.shopee.io/grafana/d/IRf-3Kjmk/ads-deduction-live-env |
| Ads Deduction - Deployment | https://monitoring.infra.sz.shopee.io/grafana/d/DDfWmKpnk/ads-deduction-deployment |
| Display Ads | https://monitoring.infra.sz.shopee.io/grafana/d/ggZ0wrRVk/display-ads |
| display-ads-billing | https://monitoring.infra.sz.shopee.io/grafana/d/sXfGzmxIk/display-ads-billing |
| Search-ads Service v3 | https://monitoring.infra.sz.shopee.io/grafana/d/XX2g2Tn4z/search-ads-service-v3 |
| Ads Count | https://monitoring.infra.sz.shopee.io/grafana/d/4cBj1iOVz/ads-count |
| Region Live Ads DB | https://monitoring.infra.sz.shopee.io/grafana/d/4RB9tsfIz/region-live-ads-db |

**核心 Prometheus 指标**（来源：`internal/ads_service/exporter.go` 和 `cron_jobs/*/exporter.go`）：

| 指标名 | 标签 | 描述 |
|---|---|---|
| `paidads_ads_service_latency` | `country`、`component`、`name` | RPC 延迟（毫秒） |
| `paidads_ads_service_error` | `country`、`component`、`name`、`error` | 每个 RPC 的错误计数 |
| `paidads_ads_service_time_diff` | `country`、`component`、`name` | 时间漂移（用于批量 set API 监控） |
| `paidads_ads_db_manager_count` | `queryName`、`caller` | 每个调用方的 DB 查询次数 |
| Display Ads 账单计数器 | （账单专用标签）| 来自 `cron_jobs/display_ads/exporter.go` |
| Shop Ads 白名单变更 | `whitelist_change` 标签 | 来自 `cron_jobs/shop_ads/exporter.go` |

**日志路径**（示例，实际路径以 SDU 为准）：`/home/toc/SDE/logs/ads_service/`

告警规则未在本仓库中定义，请参考平台级告警配置。

---

## 关键术语

| 术语 | 含义 |
|---|---|
| **Product Ads** | 基于关键词或自动出价、绑定具体商品（item）的广告 |
| **Shop Ads** | 推广整个卖家店铺的广告 |
| **Display Ads** | 品牌/CPM 展示广告，按展示量计费，由 billing_generator 定时任务生成账单 |
| **Live Stream Ads** | 直播场景下投放的广告 |
| **Target Ads** | 面向特定受众（买家分群）的定向广告 |
| **ads-DB** | 支撑 ads_service 的分片 MySQL 数据库集合，通过 ads-db-lib 访问 |
| **translog** | 扣费流水记录，存储在按日期分片的 `translog_tab` 表中 |
| **Config Center** | Shopee 集中式动态配置服务，持有 DB 密钥和运行时开关 |
| **GFS** | 全局文件存储（USS 适配器），用于 Display Ads 创意文件上传 |
| **CPC** | Cost Per Click，搜索/产品广告的标准计费模式 |
| **CPM** | Cost Per Mille，Display Ads 的计费模式 |
| **eCPM** | Effective Cost Per Mille，总广告消耗 / 总展示量 |
| **ROI** | Return on Investment，广告 GMV / 广告消耗 |
| **SPEX** | Shopee 内部 RPC 框架（类似 gRPC + 服务注册中心） |
| **spcli** | Proto 管理 CLI 工具（`spcli proto gen`、`spcli proto ensure`） |

---

## 参考资料

- **仓库地址：** https://git.garena.com/shopee/deep/ads_service
- **Advertiser Platform 架构（Confluence）：** https://confluence.shopee.io/display/SPAD/Advertiser+Platform
- **Paid Ads 业务术语表：** https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- **Cronjob 梳理（Google Docs）：** https://docs.google.com/document/d/1Z6VYs8vyJ-D914cU8wDBltrE6ItZ2TrhoZiXOSPkXmM/
- **监控与 Grafana 面板汇总（Google Docs）：** https://docs.google.com/document/d/1xbEldfLSGJ5KsFjKk2IjZQfoI0XfQ8Ffwja0UKVHjNw/
- **CMDB 定时任务列表：** https://space.shopee.io/console/cmdb/cronjobs/tree/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.platform
- **paidads-platform-lib releases**（spex-generator）：https://git.garena.com/shopee/deep/paidads-platform-lib/-/releases
- **ads-db-lib：** https://git.garena.com/shopee/deep/ads-db-lib

---

## 常见问题

**Q：RPC 接口定义在哪里？**  
`sp_proto/paidads/ads_service.proto` 是标准来源。生成的 Go 绑定在 `protobuf/go/paidads_ads_service.pb/` 下。禁止直接编辑生成文件 — 请编辑 `.proto` 后运行 `make proto-compile`。

**Q：如何判断一个 RPC 是活跃还是已废弃？**  
检查 `api/ads_service/server.go`。活跃 RPC 会委托给 Activity 或 Manager。废弃的 RPC 直接返回 `ERROR_DEPRECATED` 并提示联系维护者。当前活跃的主要域：Banner Ads、Auto Boost、Campaign Day、关键词推荐、Display Ads、扣费流水、报表（仅 query — export_report 已删除）、白名单/欺诈。

**Q：如何在本地运行服务？**  
确保 `data/` 目录存在于工作目录中（`bash ./scripts/getdata.sh` 或 `make update_textproc_data`），然后运行 `make start`。这会设置 `SP_UNIX_SOCKET=/tmp/spex.sock` 并使用 `config/files/test.yml` 启动服务器。

**Q：为什么需要 `data/` 目录？**  
它包含文本处理模型文件（简繁转换、词干提取），由 `internal/textproc` 使用。缺少该目录，服务启动时会 panic。

**Q：如何更新 proto 文件？**  
- 如果修改了 `sp_proto/paidads/ads_service.proto`：运行 `make proto-compile`。  
- 如果修改了其他 `.proto` 文件：运行 `make proto-ensure`。  
- 禁止编辑 `protobuf/go/` 下的任何文件。

**Q：主服务和 Cronjob 二进制有什么区别？**  
两者共用同一份代码库和配置。`ads_service` 是长期运行的 SPEX 服务，处理 RPC 请求。`ads_service_cronjob` 是一次性 CLI，执行指定命令（如 `display_ads_billing_generator`）后退出。每个命令通过 CMDB 外部调度。

**Q：动态配置在哪里修改？**  
- **DB 密钥 / `AdsConfigSecret` / `BidPrice`：** Config Center（键名在 `config.AdsService.ConfigCenterSecrets` 中）。  
- **白名单规则、限流配置、DB toggle、GFS 选项、关键词推荐实验版本等：** SPEX `config` 键（通过 SPEX 控制台或 `spkit` 更新）。

**Q：SPEX `alpha`/`beta` tag 如何影响配置？**  
如果在 Mesos 构建阶段设置了 `SPEX_SERVICE_TAG=alpha` 或 `beta`，`mesos.sh` 会将环境配置文件中的 `tag: master` 改写为 `tag: alpha/beta`，使服务订阅对应的 SPEX 配置 tag 而非 `master`。

**Q：`ci-lint` 实际上做了什么？**  
它使用 `.golangci.yml` 运行 `golangci-lint` 并将结果输出到 `gl-code-quality-report.json`。虽然 linter 以 `--issues-exit-code 0` 调用，但 Makefile 之后会检查 JSON 输出是否大于 `{}`（3 字节），若存在 lint 问题则调用 `exit 1`。lint 失败**会**阻断 CI。

**Q：`translator` 模块用于什么？**  
`internal/translator` 封装了 Transify i18n 服务。启动时会初始化两个独立的管理器实例：一个用于通用关键词/广告文本翻译，另一个专门用于搜索品牌广告文本。这使 ads_service 能在 Shopee 所有市场中提供多语言广告内容。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 99fcf4adde51a4acdb1fd4a7d978e772fb6f80de | spec: 76fce5f679f9550b -->
