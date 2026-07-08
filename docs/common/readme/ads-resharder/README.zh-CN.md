<!-- ads-workspace-gdoc-sync: gdoc_id=1F5LO5PNLDZV5QHrLXJuLzcz8Uw9oJtEhvoMYFKDvz0E gdoc_url=https://docs.google.com/document/d/1F5LO5PNLDZV5QHrLXJuLzcz8Uw9oJtEhvoMYFKDvz0E/edit -->

# ads-resharder

> **Git 仓库：** https://git.garena.com/shopee/deep/ads-resharder  
> **PIC：** Zhining | **团队：** Data Support（广告主平台）

---

## 目录 / Table of Contents

1. [项目概述](#项目概述)
2. [核心功能](#核心功能)
3. [项目架构](#项目架构)
   - [上下游调用拓扑](#上下游调用拓扑)
4. [目录结构](#目录结构)
5. [SPEX 与业务模块](#spex-与业务模块)
   - [接口总览](#接口总览)
   - [Resharding 流程与任务](#resharding-流程与任务)
6. [定时任务](#定时任务)
7. [开发规范](#开发规范)
   - [代码风格](#代码风格)
   - [项目结构](#项目结构)
   - [命名规范](#命名规范)
   - [错误处理](#错误处理)
   - [单元测试](#单元测试)
   - [Code Review & Git Workflow](#code-review--git-workflow)
8. [配置说明](#配置说明)
   - [配置文件](#配置文件)
   - [SPEX 与 spcli 配置](#spex-与-spcli-配置)
9. [部署](#部署)
   - [生产构建](#生产构建)
   - [发布流程](#发布流程)
10. [监控](#监控)
11. [业务术语表](#业务术语表)
    - [核心指标](#核心指标)
    - [广告类型](#广告类型)
    - [位置入口](#位置入口)
    - [卖家与广告主](#卖家与广告主)
    - [竞价定价](#竞价定价)
    - [预测模型](#预测模型)
    - [系统特性与服务](#系统特性与服务)
    - [广告供给与展示](#广告供给与展示)
    - [管控与过滤](#管控与过滤)
    - [外部服务与系统](#外部服务与系统)
    - [技术术语](#技术术语)
12. [参考资料](#参考资料)
13. [常见问题](#常见问题)

---

## 项目概述

`ads-resharder` 是 Shopee 广告主平台（Advertiser Platform）中的无状态 Go 流式处理服务。它位于原始 MySQL Binlog CDC Kafka Topic 与下游消费方（Indexer、计费服务、SRM、营销服务等）之间，核心职责是 **Resharding / 分片**：将按地区、分片存储的数据库 CDC 事件，重新路由到按国家划分的逻辑 Kafka Topic，并保证一致的分区策略。

服务支持两条并行消费路径，由运行时 Feature Flag 控制：

- **KJC 路径**（`kafka_job_client`）：遗留 GDS 客户端，目前与 EKL 并行运行。
- **EKL 路径**（`enhanced-kafka-lib` + Muse）：新一代 CDC 消费框架，通过 `enable-ekl: true` 开启。

两条路径写入同一组目标 Kafka Topic。

---

## 核心功能

- **多地区 CDC 汇聚**：消费来自 `shopee_ads_xx_db`（TH/TW/SG/ID/PH/MY/VN/BR）、`shopee_ads_srm`、`shopee_ads_marketing`（Panama CDC）、`shopee_ads_balance_*`（余额 DB，仅 EKL，消费者配置来自配置中心）以及每个地区按分片的 `shopee_order_core_*` Topic（主要国家最多 100 个分片 × 10 个国家）。
- **Prehashing 有序投递**：对指定分片键字段（如 `userid`、`campaignid`、`account_id`）应用自定义哈希函数，确保同一实体的关联记录始终写入同一 Kafka 分区，保证顺序性。
- **按国家分发**：将处理后的记录路由到国家级 Topic（`ads_gds_{CID}`）和订单 Topic（`shopee_order_gds_{CID}_live`），以及全平台 Topic（`shopee_marketplace_gds_ads_resharder`）。
- **35+ 种表类型**：覆盖完整的 Ads Core DB 表结构——Campaign、广告、关键词、扣费流水、Credit、V3 余额/Credit 表、审计日志，以及余额 DB CDC、SRM、营销和订单数据。
- **双模消费**：KJC 和 EKL 路径可同时运行；可通过 `disable-kjc: true` 单独关闭 KJC。
- **余额 DB CDC（EKL）**：`shopee_ads_balance_*` DB 的 Binlog CDC 事件仅通过 EKL 路径消费，消费者配置由配置中心（`kafka_config`）管理。五张 V3 余额/Credit 表（`ads_credit_v3_tab`、`frozen_ads_credit_v3_tab`、`ads_credit_expense_tab`、`translog_v3_tab`、`campaign_daily_expense_tab`）及余额 DB 的 `topup_translog_tab` 均路由至专属 `balance_producer`。余额 DB 的 `topup_translog_tab` 使用 Job 类型字符串 `ads_balance_topup_translog`，与广告核心 DB 路径的 `ads_topup_translog` 不同。
- **配置中心热更新**：Kafka 拓扑（`kafka_config`）和性能参数（`performance_param`）从配置中心命名空间 `resharder_live_default` 加载，无需重启即可更新。
- **Prometheus 监控埋点**：在 `paidads_resharder_*` 和 `paidads_ekl_resharder_*` 命名空间下暴露按表、按命令的计数器，以及处理延迟和端到端延迟直方图。
- **SPEX 集成**：注册为 SPEX 服务 `paidads.resharder`（env: live，tag: master），通过 `paidads-platform-lib/app` 暴露 `/ping` 和 `/smoketest` HTTP 端点。

---

## 项目架构

以下为 ads-resharder 的数据流示意图：

```
MySQL 数据库（按地区、按分片）
  ├── shopee_ads_xx_db（TH/TW/SG/ID/PH/MY/VN/BR）  ─┐
  ├── shopee_ads_srm                                   │  Binlog
  ├── shopee_ads_marketing（Panama CDC）               │  CDC
  ├── shopee_ads_balance_*_db（按地区，仅 EKL）        │  Kafka
  └── shopee_order_core_{CID}_db_00000000~N            │  Kafka
                                                       ▼
                              ┌────────────────────────────────────────┐
                              │             ads-resharder              │
                              │                                        │
                              │  ┌──────────┐   ┌────────────────┐    │
  源端 Kafka Topic ──────────►│  │ KJC 路径 │   │   EKL 路径     │    │
  （GDS / Panama CDC）        │  │(kjc client│  │(enhanced-kafka │    │
                              │  │ + preHash)│  │  lib + Muse)   │    │
                              │  └────┬─────┘   └──────┬─────────┘    │
                              │       │                 │              │
                              │  TableManager ◄─────────┘             │
                              │  WriterManager                         │
                              │  ConfigGetter（配置中心）              │
                              └────────────────────────────────────────┘
                                               │
                 ┌─────────────────────────────┼──────────────────────────┐
                 ▼                             ▼                          ▼
      ads_gds_{CID}                shopee_marketplace_gds          shopee_order_gds
      （按国家：                    _ads_resharder                   _{CID}_live /
       tw/br/sg/id/                （单一 Topic）                    shopee_order_gds
       ph/th/my/vn/                                                  _live
       mx/co/cl）
                 │
                 ▼
      下游消费方：
      ads-indexer、ads_service、ultimate_ads_service、
      ads-status-syncer、ads-account-balance 等
```

### 上下游调用拓扑

**上游（CDC 数据源）**

| 服务 / 数据库 | 协议 | 说明 |
|---|---|---|
| `shopee_ads_xx_db`（TH/TW/SG/ID/PH/MY/VN/BR）| Kafka（GDS，KJC）| 广告核心 DB Binlog，消费 `db_shopee_ads_{cid}` Topic |
| `shopee_ads_srm` | Kafka（GDS，KJC）| SRM DB Binlog，消费 `db_shopee_ads_srm` Topic |
| `shopee_ads_marketing` | Kafka（Panama CDC，SASL）| 营销 DB Binlog，消费 `panama_live_shopee_ads_marketing_{cid}_db` Topic |
| `shopee_ads_balance_*`（按地区）| Kafka（EKL + Muse）| 余额 DB Binlog；消费者配置来自配置中心 `kafka_config`。涉及表：`ads_credit_v3_tab`、`frozen_ads_credit_v3_tab`、`ads_credit_expense_tab`、`translog_v3_tab`、`campaign_daily_expense_tab`、`topup_translog_tab` |
| `shopee_order_core_{cid}_db` | Kafka（Panama CDC，SASL）| 订单 DB Binlog，非 LATAM 最多 100 分片，LATAM 各 1 分片 |
| 配置中心 | HTTPS | 热更新 `kafka_config` 和 `performance_param`（命名空间 `resharder_live_default`）|

**下游（输出 Topic）**

| Topic 模式 | 说明 |
|---|---|
| `ads_gds_{CID}` | 按国家的广告 CDC 事件，供 Indexer 和平台服务消费 |
| `shopee_marketplace_gds_ads_resharder` | 全平台 Topic，用于营销表（日预算提示、Campaign Day） |
| `shopee_order_gds_live` | 全局订单事件（非 LATAM） |
| `shopee_order_gds_{CID}_live` / `shopee_order_gds-{CID}-live` | 按国家订单事件（BR、MX、CO、CL、AR） |

所有目标 Topic 均写入 `kafka.ks_paidads_live.ap-sg-1-general-a.live.mq.shopee.io:9092`。

**依赖项**

| 依赖 | 协议 | 用途 |
|---|---|---|
| `ads-db-lib` | Go 库 | Protobuf 表结构定义（`beeshop_ads.proto`、`adsdblib.proto`） |
| `proto_parser` / `dbmap` | Go 库 | CDC 记录反序列化和 DB Map |
| `kafka_job_client`（KJC）| Go 库 | 遗留 GDS Kafka 消费客户端 |
| `enhanced-kafka-lib`（EKL）+ Muse | Go 库 | 新一代 Kafka 消费框架（基于 CRDS） |
| `ads-config-lib` / Config Center SDK | Go 库 | 配置中心订阅 |
| Jaeger | UDP | 分布式链路追踪（线上已禁用：`flag: false`） |
| Prometheus | HTTP scrape | 指标采集（`:http_port/metrics`） |

---

## 目录结构

```
ads-resharder/
├── config/                     # 配置加载与结构体定义
│   ├── config.go               # ResharderConfig 顶层结构体
│   ├── resharder.go            # Resharder 专属配置字段
│   ├── reload.go               # DB auth 热更新（UpdateDBAuth）
│   ├── util.go                 # 配置工具方法
│   └── files/
│       ├── live.yml            # 线上配置（sources、destinations、tableentries）
│       ├── test.yml            # 测试环境配置
│       └── uat.yml             # UAT 配置
├── deploy/
│   ├── resharder.json          # Mesos 部署描述（build/run 命令）
│   └── mesos.sh                # Mesos 构建/运行脚本
├── init/
│   └── resharder/
│       ├── main.go             # 入口：app.Run + ResharderConfig
│       └── run.go              # run() 函数，组装 Resharder 并启动 goroutine
├── internal/
│   ├── constants/
│   │   ├── db_column.go        # DBColumnsMap：各表默认字段列表
│   │   ├── record_info.go      # DB2RecordInfo 和 EKLDB2RecordInfo 映射
│   │   └── record_info_enum.go # 枚举辅助
│   └── resharder/
│       ├── resharder.go        # Resharder 结构体，New()、Start()、Stop()
│       ├── config.go           # Option 和 TableConfigEntry 结构体（YAML）
│       ├── config_center.go    # ConfigGetter——配置中心订阅 + 热更新
│       ├── consts.go           # jobTypeMap、unmarshalFuncMap、db2RecordInfoMap
│       ├── table_manager.go    # TableManager、TableEntry、处理单元注册
│       ├── processor_factory.go# ProcFactory——将处理函数名映射到实现
│       ├── ekl_consumer.go     # EKLConsumerManager——Muse/EKL 消费者生命周期
│       ├── ekl_consumer_handler.go # EKLMessageHandler——转换/分发/处理
│       ├── ekl_job.go          # EKLJob 和 CDCRecord 结构体
│       ├── ekl_producer.go     # EKL 生产者封装（ads/order/marketplace）
│       ├── ekl_hash.go         # EKL 侧 prehash 函数构建
│       ├── producer.go         # countryProducer、singleProducer、countryMultiProducer
│       ├── producer_manager.go # WriterManager——将目标名映射到生产者
│       ├── kafka_producer.go   # SingleKafkaProducer、MultiKafkaProducer 封装
│       ├── kafkameta.go        # Kafka 元数据辅助
│       ├── hash.go             # KJC 侧 prehash 函数构建
│       ├── helper.go           # 杂项辅助函数
│       ├── option.go           # Option 结构体校验
│       ├── parser.go           # EKL 路径 RecordParser
│       ├── pid_gen.go          # PID（分区 ID）生成器注册
│       ├── adsdblib_compat.go  # adsdblib Protobuf 自定义反序列化（NPB、潜在商品、GMS Item、账户审计）
│       ├── exporter.go         # Prometheus 指标定义 + parseTableName（KJC 路径）
│       ├── balancedb/
│       │   └── topup.go        # 余额 DB topup translog 检测（IsTopupTranslog）
│       ├── kjcmeta/
│       │   └── meta.go         # KJC Job 元数据：成功/错误回调及 Prometheus 计数
│       ├── metrics/
│       │   └── metrics.go      # EKL 路径 Prometheus 指标定义（EKLMessageCmdCount 等）
│       ├── tablekey/
│       │   └── tablekey.go     # CDC 表键 `<db>.<table>` 解析（含分片后缀剥离）
│       └── ...                 # 测试文件
├── internal/utils/
│   └── trim_table_suffix.go    # TrimTableSuffix——去除表名中的分片后缀
├── tool/
│   ├── benchmark/              # 基准测试
│   ├── db_column/              # 生成 DB 字段列表的工具
│   └── observer/               # 独立观察者工具
├── Makefile                    # 构建目标：resharder、test、vet、fmt、dep、ci
├── go.mod / go.sum             # Go 模块依赖
├── sp-workspace.yml            # SPEX workspace 配置（proto 生成目标）
└── .gitlab-ci.yml              # GitLab CI：test → build（手动）→ image（手动）
```

---

## SPEX 与业务模块

### 接口总览

`ads-resharder` 注册为 SPEX 服务 **`paidads.resharder`**（env: `live`，tag: `master`，deployment: `default`）。服务本身不暴露自定义 SPEX 命令；SPEX 注册仅用于服务发现和平台标准集成。

标准 HTTP 端点（由 `paidads-platform-lib/app` 提供）：

| 端点 | 方法 | 用途 |
|---|---|---|
| `/ping` | GET | 健康检查（Mesos 用于验证实例存活） |
| `/smoketest` | GET | 部署时冒烟测试（30 次重试，超时 2 s） |
| `/metrics` | GET | Prometheus 指标采集 |

### Resharding 流程与任务

Resharder 处理以下逻辑表类型，每个表条目映射到一个 `SearchIndexType` Job 类型，并编码到下游 Kafka 消息中：

| 表名 | Proto | Job 类型字符串 | 分片键（prehash 字段）|
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
| `order_item_tab` | `order_info.proto` | `order` | — （仅 insert） |

---

## 定时任务

`ads-resharder` 本身不运行定时任务，它是一个持续运行的流式处理服务。广告主平台的 Cronjob 由其他服务管理（如 `ads-status-syncer`、`ads_service`、`ultimate_ads_service`、`auto-rebate`、`ads-marketing`）。完整 Cronjob 列表请参见 [Platform Cronjob 知识库](https://docs.google.com/document/d/1Z6VYs8vyJ-D914cU8wDBltrE6ItZ2TrhoZiXOSPkXmM/)。

---

## 开发规范

### 代码风格

- 使用 `gofmt` 进行标准 Go 格式化，提交前执行 `make fmt`。
- 执行 `make vet`（或 `make ci-vet`）进行静态检查，CI 流水线会拒绝未通过 vet 的代码。
- 所有公开函数和类型必须有 Go doc 注释。

### 项目结构

- 业务逻辑放在 `internal/resharder/`，模块外部不得导入 `internal/`。
- 入口点为 `init/resharder/`，仅负责依赖注入和调用 `app.Run`。
- 表配置采用数据驱动方式：新增表只需在 `config/files/{env}.yml` 中添加 YAML 条目，并更新 proto/dbmap 映射，大多数情况下无需新增 Go 文件。

### 命名规范

- 提交消息：`(Feat|Fix|Docs|Style|Refactor|Test|Chore): [JIRA-ID] description`
- 分支命名：`dev/$username` 或 `feature/$feature_name`
- YAML 中的处理函数名（`processorfunc`、`eklprocessorfunc`）必须与 `ProcFactory` 中的注册名一致。

### 错误处理

- 使用 `fmt.Errorf("上下文: %w", err)` 包装错误以保留调用栈信息。
- 启动阶段的致命错误从 `New()` 返回，由 `app.Run` 导致进程退出。
- 运行时处理错误需带表名/命令上下文记录日志，并在 `paidads_resharder_error` / `paidads_ekl_resharder_ekl_errors` 中计数。

### 单元测试

- 使用 `make test`（详细输出 + 覆盖率）或 `make test-nv`（CI 模式）运行测试。
- 测试文件与被测源文件同目录存放（如 `ekl_consumer_handler_test.go`）。
- 基准测试放在 `tool/benchmark/` 目录。

### Code Review & Git Workflow

- 所有变更通过 Merge Request 合并，使用 squash commit，合并后删除源分支。
- 算法/平台代码须在至少一个地区验证后方可合并。
- CI 阶段：`test`（自动）→ `build`（手动）→ `image`（手动），参见 `.gitlab-ci.yml`。

---

## 配置说明

### 配置文件

主运行时配置位于 `config/files/{env}.yml`：

| 文件 | 环境 |
|---|---|
| `config/files/live.yml` | 线上（生产） |
| `config/files/test.yml` | 测试 |
| `config/files/uat.yml` | UAT |

`live.yml` 关键章节：

| 章节 | 说明 |
|---|---|
| `ads-resharder.option.sources` | KJC 消费组配置：broker 列表、topic 列表、prehashing 选项 |
| `ads-resharder.option.destination` | Kafka 生产者配置：`ads_producer`、`marketplace_producer`、`order_producer`、`order_country_producer`（KJC）；`balance_producer` 拓扑通过配置中心 `kafka_config` 动态配置 |
| `ads-resharder.option.tableentries` | 每个逻辑表一个条目：proto 名、类型名、DB 字段、pid gen func、处理函数 |
| `ads-resharder.config-center` | 配置中心命名空间（`resharder_live_default`）和 Secret |
| `ads-resharder.spex` | SPEX 服务注册参数 |

**配置中心热更新 Key**（命名空间：`resharder_live_default`）：

| Key | 类型 | 说明 |
|---|---|---|
| `performance_param` | JSON | `enable_prefilter_by_key`、`enable_partial_unmarshal` |
| `kafka_config` | JSON | EKL Muse 消费者列表（`source_cdc_kafka`）和 EKL 目标生产者配置（`destination`） |

与 MySQL 分表/迁移和 SDDL（数据库 Schema 迁移平台）的协作点：当新增分片或迁移数据库时，需同步更新 `live.yml` 中的 topic 列表或 tableentries，并重新部署服务。

### SPEX 与 spcli 配置

安装 spcli：

```bash
pip install --upgrade shopee-spex-cli
```

安装本地 SPEX 网络代理（inp-client）：

```bash
wget http://proxy.uss.s3.sz.shopee.io/api/v4/50054564/spex-s3ia-sg-live/intranet_penetrator/inp-client/latest/inp-client_darwin_amd64 \
  -O /usr/local/bin/inp-client && chmod +x /usr/local/bin/inp-client
inp-client  # 在后台终端运行
```

修改 `sp_proto/` 后重新生成 SPEX proto 桩代码：

```bash
spcli proto gen
# 输出到 gen/go/
```

---

## 部署

### 生产构建

```bash
# 下载依赖（此后无需网络）
make dep-vo

# 编译当前平台二进制
make resharder
# 输出：bin/paidads_resharder_server

# 交叉编译 Linux 版本（Jenkins/Mesos 使用）
# 同样由 `make resharder` 输出为 bin/paidads_resharder_server.linux
```

Jenkins / Mesos CI 构建命令（来自 `deploy/resharder.json`）：

```bash
make dep-vo && bash ./deploy/mesos.sh build resharder resharder config/files
```

CI Docker 镜像：`harbor.shopeemobile.com/paidads/base/platform-ci:1.21`（Go 1.21）

### 发布流程

1. 将变更推送到 Feature 分支，发起 Merge Request。
2. GitLab CI 自动执行 `make ci`（vet + fmt + test），对应 `test` 阶段。
3. 手动触发 `build_job` 编译二进制。
4. 手动触发 `build_image_job`（`.gitlab/make-image.sh`）构建并推送 Docker 镜像。
5. 通过 Mesos 使用 `deploy/resharder.json` 部署，运行命令为 `./mesos.sh run resharder`。
6. Mesos 在标记实例为健康前，冒烟测试 `/smoketest`（HTTP，30 次重试 × 2 s 超时）。

---

## 监控

Grafana 大盘（Advertiser Platform 文件夹：[advertiser-platform](https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform)）：

| 大盘 | 链接 |
|---|---|
| Ads Status Syncer + Job + Derived Data + Resharder（Non Live） | [链接](https://monitoring.infra.sz.shopee.io/grafana/d/4xxD8pdHz/ads-status-syncer-job-derived-data-resharder-non-live) |
| Live Ads Resharder | [链接](https://monitoring.infra.sz.shopee.io/grafana/d/BLgcEuRnz/live-ads-resharder) |
| Resharder EKL ads db（nonlive）| [链接](https://monitoring.infra.sz.shopee.io/grafana/d/sY8oKqsNz/resharder-ekl-ads-db-nonlive) |
| 计费 Lag（TDR Overview） | [链接](https://monitoring.infra.sz.shopee.io/grafana/d/YMWPK-Q7z/tdr-overview-dashboard?orgId=39&viewPanel=73&from=now-7d&to=now) |
| Live Ads DB Regional | [链接](https://monitoring.infra.sz.shopee.io/grafana/d/4RB9tsfIz/region-live-ads-db?orgId=39) |

**核心 Prometheus 指标**（从 `:http_port/metrics` 采集）：

| 指标 | 类型 | 标签 | 说明 |
|---|---|---|---|
| `paidads_resharder_counter` | Counter | `subsystem`、`db`、`table`、`cmd` | 每表每命令 CDC 消息数（KJC 路径） |
| `paidads_resharder_latency` | Histogram | `message_type`、`message_source` | 处理延迟（µs，KJC 路径） |
| `paidads_resharder_e2e_latency` | Histogram | `topic`、`message_source` | 端到端延迟（s，KJC 路径） |
| `paidads_resharder_error` | Counter | `subsystem`、`partition`、`message_type`、`err_type` | 处理错误数（KJC 路径） |
| `paidads_ekl_resharder_counter` | Counter | `subsystem`、`db`、`table`、`cmd` | CDC 消息数（EKL 路径） |
| `paidads_ekl_resharder_latency` | Histogram | `message_type`、`message_source` | 处理延迟（µs，EKL 路径） |
| `paidads_ekl_resharder_e2e_latency` | Histogram | `topic`、`message_source` | 端到端延迟（s，EKL 路径） |
| `paidads_ekl_resharder_ekl_errors` | Counter | `subsystem`、`partition`、`message_type`、`err_type` | 处理错误数（EKL 路径） |

Kafka 消费 Lag 监控：[Kafka Exporter — paidads-bigshop-deduct-event topic](https://monitoring.infra.sz.shopee.io/grafana/d/tMpwXZvMz/kafka-exporter-dashboard?from=now-24h&orgId=74&refresh=5m&to=now&var-cluster=ks_ads_live&var-group=All&var-middleware_datasource=vm-live-middleware&var-topic=paidads-bigshop-deduct-event-id-live&viewPanel=180)

---

## 业务术语表

### 核心指标

| 术语 | 全称 | 定义 |
|---|---|---|
| CTR | Click-Through Rate，点击率 | 点击数 / 曝光数，衡量广告相关性 |
| CR | Conversion Rate，转化率 | 广告订单 / 点击数，点击后购买概率 |
| eCPM | Effective Cost per Mille，有效千次曝光费用 | 总消耗 / 总曝光 × 1000 |
| CPC | Cost Per Click，每次点击费用 | 每次点击的花费金额 |
| CPM | Cost Per Mille，千次曝光费用 | 每 1000 次曝光的费用 |
| ROI | Return on Investment，投资回报率 | 广告 GMV / 广告消耗（卖家视角） |
| ROAS | Return on Ad Spending | ROI 的同义词 |
| CIR | Cost-Income Ratio，成本收入比 | 广告收入 / 广告 GMV |
| Take-Rate | 货币化率 | 广告收入 / 平台 GMV |
| Rank Score | 排名分 | eCPM + 质量因子 |
| Display Rate | 展示率 | 有曝光广告数 / 活跃广告数 |
| Fill-up Rate | 填充率 | 实际曝光 / 潜在曝光 |

### 广告类型

| 术语 | 说明 |
|---|---|
| 搜索广告（SADS） | 关键词触发，展示在搜索结果中 |
| 发现广告（DADS / TADS）| 定向广告，展示在推荐入口，也称 TADS |
| 展示广告（Display Ads）| 品牌 / CPM 广告，使用素材（图片/视频）；包含 Brand Max、视频广告、直播广告 |
| NPB / 新品推广 | 对新上架商品的自动推广 |
| 店铺广告（Shop Ads）| 推广整个店铺 |
| 搜索品牌广告 | 保留关键词的品牌广告 |
| 品牌考量广告 | 品牌意识阶段的广告类型 |

### 位置入口

| 值 | 含义 |
|---|---|
| `placement=3` | 店铺广告 |
| `placement=4` | 搜索广告 |
| `placement=40` | 发现广告 / 推荐广告 |

### 卖家与广告主

| 术语 | 说明 |
|---|---|
| 活跃卖家（Active Seller）| 已开通广告账户且在指定周期内有活动的卖家 |
| 优质卖家（Preferred Sellers，PS）| 符合 Shopee 质量标准的卖家 |
| 官方店（Official Shops，OS）| 品牌自营旗舰店 |
| MCN | 多频道网络，管理 KOL / 达人合作关系 |

### 竞价定价

| 术语 | 说明 |
|---|---|
| oCPC / 简单模式（Simple Mode）| 自动选词模式，平台自动优化出价 |
| 手动模式（Manual Mode）| 卖家手动设置关键词出价 |
| PID 控制器 | 比例-积分-微分控制器，用于动态调节简单模式出价 |
| OCPC CIR | 自动出价的成本收入比目标，用于约束花费 |
| uGSP | 统一广义第二价格拍卖机制 |

### 预测模型

| 术语 | 说明 |
|---|---|
| pCTR | 预测点击率 |
| pCR | 预测转化率 |
| rcgbdt | RC 梯度提升决策树，用于 pCTR 预测 |
| 冷启动（Cold Start）| 广告数据不足、预测精度低的状态 |

### 系统特性与服务

| 术语 | 说明 |
|---|---|
| SRM | 卖家关系管理——管理卖家分群、激励计划和追踪 |
| QSS | 快速启动服务（QuickStart Service），帮助新广告主快速上量 |
| VGS | Values Grid Search，自动调节算法参数 |
| 自动充值（Auto Top-up）| 本地卖家的自动 Credit 补充 |
| Advv | 广告主价值（Advertiser Value），衡量平台长期收入增量 |

### 广告供给与展示

| 术语 | 说明 |
|---|---|
| 广告 GMV | 归因于广告点击的总销售额（7 天归因窗口）|
| 广告订单（Ads Order）| 点击广告后 7 天内产生的订单 |
| 流量率（Traffic Rate）| 某类广告曝光占全部曝光的比例 |
| 返利（Rebate）| 基于激励计划返还给 Campaign 的现金 |

### 管控与过滤

| 术语 | 说明 |
|---|---|
| 黑名单（Blacklist）| 关键词或商品 ID 级别的排除列表 |
| 白名单（Whitelist）| 功能访问启用列表（如 Target ROI、店铺广告定制）|
| 宽泛匹配（Broad Match）| 搜索词包含关键词即触发 |
| 精准匹配（Exact Match）| 搜索词必须与关键词完全一致才触发 |
| Badcase | 运营人工标记的广告/关键词异常，用于人工审核 |

### 外部服务与系统

| 术语 | 说明 |
|---|---|
| GDS | Global Data Stream，Shopee 的 MySQL Binlog CDC Kafka 基础设施 |
| KJC | `kafka_job_client`，ads-resharder 使用的遗留 GDS 消费库 |
| EKL | `enhanced-kafka-lib`，新一代 CDC 消费框架（基于 Muse） |
| SDDL | Shopee Dynamic DDL，数据库 Schema 迁移平台 |
| Panama CDC | Shopee 用于替换部分数据库 GDS 的新一代 CDC 管道 |

### 技术术语

| 术语 | 说明 |
|---|---|
| Resharding / 分片 | 将按分片存储的 DB CDC 事件重新路由到逻辑的按国家 Topic |
| Prehashing | 在 Kafka 分区分配前，对分片键字段应用确定性哈希 |
| PID Gen | 分区 ID 生成器——决定每张表以哪个字段做哈希 |
| KJC ProcUnit | KJC 框架处理单元：`(表名, 操作, 处理函数)` 三元组 |
| EKL ProcUnit | EKL 框架处理单元：`(db, 表名, 操作, CDCProcessFunc)` |
| ProtoName | 用于 CDC 记录反序列化的 Protobuf Schema 文件名（如 `beeshop_ads.proto`）|

---

## 参考资料

- Git 仓库：https://git.garena.com/shopee/deep/ads-resharder
- 广告主平台 Confluence：https://confluence.shopee.io/display/SPAD/Advertiser+Platform
- Paid Ads 术语表：https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- ads-db-lib（DB 访问库）：https://git.garena.com/shopee/deep/ads-db-lib
- SPEX Go 快速上手：https://spex.shopee.io/overview/quick-start/languages/go/index.html
- DB 分片进度追踪：https://docs.google.com/spreadsheets/d/1J_9SxnYOZ3I3MLH-JweoPgeg4cV7do-nY2qYcSLqos4/edit
- DB 解耦设计文档：https://docs.google.com/document/d/1I5Wr0fr5-wBH6KWyGpUBCNYMY4YU-Wv0eZ5okhDfveU/
- Platform Cronjob 知识库：https://docs.google.com/document/d/1Z6VYs8vyJ-D914cU8wDBltrE6ItZ2TrhoZiXOSPkXmM/
- 监控 Grafana（广告主平台）：https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform
- Space CMDB Cronjob 树：https://space.shopee.io/console/cmdb/cronjobs/tree/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.platform
- SDDL 介绍：https://gdbc.shopee.io/sddl/intro

---

## 常见问题

**Q1：如何向 Resharder 新增一张 Ads DB 表？**

如果表的 Protobuf 模型已在 `beeshop_ads.proto` 中：
1. 在 `config/files/{env}.yml` 中添加表条目，指定 `tablename`、`dbtable`、`typename`、`dbcolumns`、`pidgenfunc`。
2. 在 `live.yml` 对应 KJC source 的 `prehashingoptions` 下添加该表的条目。

如果表的 proto 模型**不在** `beeshop_ads.proto` 中（如新 proto 文件）：
1. 在 `proto_parser/protoc-gen-dbmap/config.go` 的 `dbmap.AdsDbLibProtoName` 中添加该表。
2. 执行 `make adsdblib` 重新生成 dbmap 代码。
3. 将生成产物复制到 `beeshop_ads.dbmap.go`。
4. 然后按上述 YAML 步骤添加条目，`protoname` 设为 `beeshop_ads.proto`。

具体示例参见 [MR !160](https://git.garena.com/shopee/deep/proto_parser/-/merge_requests/160) → [MR !161](https://git.garena.com/shopee/deep/proto_parser/-/merge_requests/161)。

**Q2：Prehashing 步骤的作用是什么？为什么重要？**

Prehashing 在 KJC/EKL 框架分配 Kafka 分区前，对指定字段（如 `userid`）应用确定性哈希。这确保同一实体（如同一用户的所有 Campaign）的 CDC 事件始终写入目标 Topic 的同一分区，从而让需要顺序处理的下游消费方能够按实体顺序消费。

**Q3：KJC 路径和 EKL 路径有何区别？**

KJC（`kafka_job_client`）是遗留 GDS 消费框架，EKL（`enhanced-kafka-lib`）是基于 Muse 的新一代 CDC 消费框架。两者处理相同的表并写入相同目标。通过 `live.yml` 中的 `enable-ekl: true` 和 `disable-kjc: false` 控制。目前两者同时运行，随着 EKL 验证完成，KJC 路径将逐步关闭。

**Q4：EKL 的 Kafka 拓扑如何单独配置，不依赖静态 YAML？**

EKL 消费者配置（Muse client 名称、key、region）和 EKL 目标生产者配置存储在配置中心命名空间 `resharder_live_default` 的 `kafka_config` key 下。这样可以在不重启或重新部署服务的情况下更改 EKL 消费组拓扑。

**Q5：Resharder 如何将订单事件与广告事件区别路由？**

来自 `shopee_order_core_{cid}_db` 的订单事件，根据表条目的 `producer-destination` 字段路由：`order_producer` 写入全局 Topic `shopee_order_gds_live`（非 LATAM），`order_country_producer` 写入按国家 Topic `shopee_order_gds_{CID}_live` / `shopee_order_gds-{CID}-live`（BR、MX、CO、CL、AR）。

**Q6：如何检查 Resharder 是否正确消费某个 Kafka Topic？**

在 Kafka Exporter 大盘或 `kafka.ks_paidads_live` 指标中查看消费组 Lag。消费组名在 `live.yml` 中定义（如广告主 DB 使用 `ads_gds_live_consumer`）。目标 Topic（`ads_gds_{CID}`）上出现 Lag 突增，说明 Resharder 转发速度不足。

**Q7：新增 DB 分片（如 `shopee_ads_br_db_10`）时如何处理？**

对于 GDS KJC 路径，Broker 动态分配 Topic，已有数据库新增分片无需修改配置。对于 Panama CDC 路径（营销、订单），必须在 `live.yml` 的 `topiclist` 中显式添加新分片 Topic，并重新部署服务。

**Q8：如何在本地运行测试？**

```bash
make dep-vo       # 下载依赖
make test         # 运行全部测试并显示覆盖率
make ci           # 模拟完整 CI：vet + fmt + test
```

**Q9：部署时 `/smoketest` 端点失败，应该排查什么？**

冒烟测试（30 次重试 × 2 s 超时）验证进程已启动且 HTTP Server 正常。检查：（1）环境配置文件路径是否正确；（2）配置中心订阅是否成功（日志中查找 `subscribe resharder config fail`）；（3）所有 Kafka 生产者是否初始化成功（日志中查找 `fail init gds client`）。

**Q10：如何追踪一条具体的 CDC 事件在系统中的流转过程？**

若 Jaeger 追踪已启用（YAML `jaeger` 章节 `flag: true`），每个事件携带 Span。线上环境已禁用 Jaeger。可使用 Prometheus 指标 `paidads_resharder_counter`（按 `table` 和 `cmd` 过滤）验证事件是否被处理，并通过 `paidads_resharder_e2e_latency` 衡量从 DB 写入到 Kafka 消息的延迟。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 6c9b8618dffe4a85d37504ec8ef2b8c61cefb5cd -->
