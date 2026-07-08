<!-- ads-workspace-gdoc-sync: gdoc_id=18YrhvykC93_EmAAMHfrD4Xwvu3_JxcsBrcFxkpgJoEk gdoc_url=https://docs.google.com/document/d/18YrhvykC93_EmAAMHfrD4Xwvu3_JxcsBrcFxkpgJoEk/edit -->

# ads-db-lib

**仓库地址：** https://git.garena.com/shopee/deep/ads-db-lib

## 目录 / Table of Contents

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
  - [上下游调用拓扑](#上下游调用拓扑)
- [模块与包结构](#模块与包结构)
- [依赖方与使用方式](#依赖方与使用方式)
- [开发规范](#开发规范)
  - [代码风格](#代码风格)
  - [版本与兼容](#版本与兼容)
  - [单元测试](#单元测试)
  - [Code Review & Git Workflow](#code-review--git-workflow)
- [配置说明](#配置说明)
- [发布与集成](#发布与集成)
- [监控](#监控)
- [业务术语表](#业务术语表)
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
- [参考资料](#参考资料)
- [常见问题](#常见问题)

---

## 项目概述

`ads-db-lib`（import 别名 `adsdblib`）是 Paid Ads 平台所有服务访问 ads-DB 层的**共享 Go 库**。它基于 Shopee Ads 数据库（ads-DB），为所有广告域实体——账户、Campaign、广告（Advertisement）、关键词、创意、扣费流水、Rebate、SRM、CRM 和 Booking——提供统一的、类型安全的、感知地区（Region）的抽象接口。

消费方服务无需自己实现 MySQL 访问代码，只需 import `adsdblib`，获取一个带池化的 `DBManager`，即可由库自动处理：连接生命周期管理、分片路由（通过 SDDL 和 Hardy ORM）、Config Center 驱动的动态重配置，以及 Prometheus 指标暴露。

PIC：Chao、Yuhang、Zhining；所属团队：Advertiser Platform — Data Support。

> 原始 README 备注：在用 `adsdblib` 完整替换服务侧自建 DB 访问逻辑前，请先检查实现并做迁移验证。库里仍可能存在少量人工误差，发现问题后应先修正再推广。

---

## 核心功能

- **统一 DB 访问层** — 一次 import 覆盖 7 个逻辑数据库（Ads Core、SRM、Ads Marketing、Rebate、Booking、Buyer Segment、CRM）的全部 DB 操作。
- **地区感知分片路由** — 所有查询方法接受 `region` 字符串参数（`"SG"`、`"MY"`、`"ID"`、`"TH"`、`"PH"`、`"TW"`、`"VN"`、`"BR"`、`"MX"`、`"CO"`、`"CL"`、`"AR"`），路由到对应物理 DB 集群由库自动完成。
- **SDDL & Hardy 集成** — 通过 Shopee SDDL（Shopee Distributed Database Layer）和 `goorm`/Hardy ORM 透明管理物理分片。
- **Config Center 驱动的动态配置** — DB 密钥、分片 Split 配置和降级路由从 Shopee Config Center 在运行时订阅并应用，无需重启服务。
- **Client 池化模式** — 每类 DB 客户端（`AdsClient`、`SRMClient`、`AdsMarketingClient`、`RebateClient`、`BookingClient`、`CRMClient`、`BuyerSegmentClient`）都通过 `sync.Pool` 管理，减少内存分配开销。
- **审计表冷热路由** — 审计表按月分片（高流量地区可通过 Config Center 动态配置阈值），库根据 `ctime` 范围自动选择正确的分片。
- **Prometheus 指标** — 暴露 `paidads_ads_db_manager_latency`（直方图）和 `paidads_ads_db_manager_count`（计数器），按 country、queryName、caller、dbName、dbShard 细分。
- **自动生成 Mock** — 所有 Client 接口均有 `mocked_*.go` 文件（由 `script/mocked_generator.py` 生成），方便单元测试注入。
- **内嵌配置文件** — 各环境配置 YAML（`live`、`liveish`、`stable`、`staging`、`uat`、`test`）通过 `pkger` 打包进二进制。
- **ads-db-ss Sidecar 服务** — 内嵌 SPEX 服务（`cmd/ads_db_ss/`），允许其他服务（如 Indexer）通过 `AdsdblibProcessor` 接口远程调用 DB 操作，无需直接嵌入本库。
- **Redis 反查 ID 映射** — `IDMappingClient` 提供 CampaignID→UserID、AdsID→UserID、AdsID→CampaignID 的 Redis 查询能力，解决 `GetCampaignXXX` 类接口因缺少 UserID 而需全分片扫表的问题。使用 `NewIDMappingClient(rdb)` 创建实例，使用 `NewRedisClientWithKMS` 初始化 KMS 鉴权 Redis 客户端。
- **自动代管订单（Auto Escrow Orders）** — 通过 `auto_escrow.go` / `auto_escrow_v3.go` 管理代管订单全生命周期（`AddAdsAutoEscrowOrder`、`UpdateAdsAutoEscrowOrder`、`GetAdsAutoEscrowOrders`、`ScanAdsAutoEscrowOrdersV2`、`ScanAdsAutoEscrowOrdersV3`）及聚合代管订单（`AddAdsAutoEscrowAggregateOrder`、`GetAdsAutoEscrowAggregateOrders`、`ScanAdsAutoEscrowAggregateOrdersV2`）。两类订单均支持基于游标的时间范围分片扫描（表：`ads_auto_escrow_order_tab`、`ads_auto_escrow_aggregate_order_tab`）。`ScanAdsAutoEscrowOrdersV3` 采用 `BusinessFn` 回调模式进行并行分片流式扫描，不再返回游标切片。
- **Campaign Accelerator 套餐（Campaign Accelerator Packages）** — 通过 `campaign_accelerator.go` 管理 Campaign 加速套餐定义（中心 DB 非分片表 `campaign_accelerator_package_tab`）及按用户分配的套餐关系（分片表 `campaign_accelerator_package_user_tab`）。提供 `ScanCampaignAcceleratorPackageUsersV3` 支持并行分片扫描。

---

## 项目架构

### 上下游调用拓扑

`ads-db-lib` 以两种模式运行：**嵌入式 Go 库**（消费方服务直接 import），以及 **ads-db-ss SPEX Sidecar**（通过 RPC 向 Indexer 等远程调用方暴露部分 DB 操作）。

```mermaid
graph LR
    subgraph Upstream["上游消费方"]
        UAS[ultimate_ads_service]
        AS[ads_service]
        STATUS[ads-status-syncer]
        RES[ads-resharder]
        MKTG[ads-marketing]
        ADMIN[paidadsbackendadmin]
        OTHER[ads-crm / ads-srm / uber-srm / auto-rebate / ...]
        IDX[Indexer / 远程调用方]
    end

    subgraph LIB["ads-db-lib"]
        CORE[adsdblib<br/>DBManager + Client 池<br/>AdsClient / SRMClient / ...]
        SIDECAR[ads-db-ss<br/>SPEX Sidecar]
    end

    subgraph Downstream["下游依赖"]
        MYSQL[(MySQL 分片 DB<br/>via SDDL / Hardy)]
        REDIS[(Redis<br/>IDMappingClient)]
        CC[Config Center<br/>adsdblib_{env}_{tag}_default]
    end

    UAS -- "Go import" --> CORE
    AS -- "Go import" --> CORE
    STATUS -- "Go import" --> CORE
    RES -- "Go import" --> CORE
    MKTG -- "Go import" --> CORE
    ADMIN -- "Go import" --> CORE
    OTHER -- "Go import" --> CORE
    IDX -- "SPEX RPC" --> SIDECAR
    CORE --> SIDECAR
    CORE -- "goorm/Hardy" --> MYSQL
    CORE -- "go-redis" --> REDIS
    CORE -- "subscribe" --> CC
    SIDECAR -- "goorm/Hardy" --> MYSQL
```

| 方向 | 名称 | 协议/类型 | 说明 |
|------|------|----------|------|
| 上游 | `ultimate_ads_service`、`ads_service` 等 | Go import | 直接消费方；初始化 `DBManager` 并使用 Client 池 |
| 上游 | Indexer 及远程调用方 | SPEX RPC | 调用 `deep.paidads.platform.ads_db_ss`，无需嵌入本库 |
| 下游 | MySQL 分片 DB 集群 | goorm/Hardy ORM | 7 个逻辑 DB 域（Ads Core、SRM、Marketing、Rebate、Booking、Buyer Segment、CRM），覆盖 12 个 Region |
| 下游 | Redis | go-redis | `IDMappingClient`：无需全分片扫描即可解析 campaign/ad→user ID |
| 下游 | Config Center | 订阅 | 命名空间 `adsdblib_{env}_{tag}_default`；下发 ORM 配置、分片 Split DSN、降级路由、审计冷热阈值 |

---

## 模块与包结构

```
ads-db-lib/
├── *.go                        # 根包（adsdblib）：全部公开接口、Client、工具函数
│   ├── manager.go              # DBManager 接口 + dbManager 实现；Client 池初始化；NewDBManagerV2WithConfigCenter
│   ├── ads_client_interface.go # AdsClient 接口（~995 个方法）
│   ├── ads.go / ads_*.go       # AdsClient 实现（账户、Campaign、广告、关键词、扣费流水…）
│   ├── auto_escrow.go          # 代管订单及聚合代管订单管理
│   ├── auto_escrow_v3.go       # ScanAdsAutoEscrowOrdersV3：BusinessFn 回调并行分片扫描
│   ├── campaign_accelerator.go # Campaign Accelerator 套餐及用户关系管理（中心 DB + 分片）
│   ├── srm.go / srm_*.go       # SRMClient 实现（Segment、Program、Incentive、Tracker…）
│   ├── rebate.go               # RebateClient
│   ├── booking.go              # BookingClient
│   ├── crm.go                  # CRMClient
│   ├── buyer_segment.go        # BuyerSegmentClient
│   ├── const.go                # 所有表名常量和各 Region DSN Map
│   ├── exporter.go             # Prometheus 指标注册与暴露
│   ├── hot_cold_util.go        # 审计表冷热路由逻辑
│   ├── sbm_downgrade.go        # 影子 DB / 双写降级路由
│   ├── mocked_*.go             # 所有接口的自动生成 Mock 实现
│   └── accessor.go             # 直接 ORM 访问工具函数
├── config/
│   ├── db.go / model.go        # DBOption、DBSelector、ORMConfig、DBConfig 结构体定义
│   ├── files/                  # 内嵌 YAML 配置：live.yml、liveish.yml、staging.yml、test.yml、uat.yml、stable.yml
│   └── ads_db_ss.go            # ads-db-ss Sidecar 配置结构体
├── internal/
│   ├── configcenter/           # Shopee Config Center 客户端与订阅管理器
│   ├── hardyhelper/            # SDDL 分片 Hint 计算、Hardy Cursor Scanner
│   ├── spexutil/               # SPEX 拦截器、ads-db-ss 配置与解析器
│   ├── setup/                  # ads-db-ss 依赖注入：repositories、services、controllers
│   ├── cleaner/                # DB 表清理任务运行器（ads_db_cleaner 二进制）
│   ├── exporter/               # 内部 Prometheus 工具
│   └── collections/            # 泛型集合（Set）工具
├── pkg/authn/                  # 鉴权 Wrapper（ads-db-ss 身份认证）
├── cmd/
│   ├── ads_db_ss/              # ads-db-ss SPEX Sidecar 二进制入口
│   ├── ads_db_cleaner/         # DB 表清理二进制入口
│   └── generate_hardy_convertors/ # 从 mappings.go 生成 hardy_rec_convertors.go
├── protobuf/go/                # 生成的 adsdblib SPEX 接口 Go protobuf
├── sp_proto/paidads/           # adsdblib、SRM、CRM、Marketing 源 .proto 定义
├── script/
│   ├── mocked_generator.py     # 从接口定义生成 mocked_*.go
│   ├── yearly_table_generator.py
│   └── schema_diff/            # Schema Diff 工具：对比不同 region/env 间的表 DDL 差异
├── example/config_center/      # 示例：如何通过 Config Center 初始化 DBManager
├── id_mapping.go               # IDMappingClient：基于 Redis 的 CampaignID/AdsID → UserID 反查
├── redis_client.go             # NewRedisClientWithKMS：KMS 鉴权 Redis 客户端创建
├── Makefile                    # 构建、测试、Mock 生成、配置生成、Proto 编译
└── go.mod                      # 模块路径：git.garena.com/shopee/deep/ads-db-lib；Go 1.18
```

### 逻辑 DB ↔ 包映射

| DB 域 | DSN Map 常量 | Client 接口 | Go 文件 |
|-------|-------------|------------|---------|
| Ads Core DB（账户、Campaign、广告、关键词、扣费流水、Credit、索引表…） | `RegionAdsDSN` | `AdsClient` | `ads.go`、`ads_account_v*.go`、`ads_campaign_v*.go`、`ads_advertisement_v*.go`、`ads_keyword_v*.go`、`ads_translog_v*.go`… |
| SRM DB（Segment、Program、Incentive、Tracker） | `RegionSRMDSN` | `SRMClient` | `srm.go`、`srm_*.go` |
| Ads Marketing DB（Flag、Campaign Day、每日预算） | `RegionAdsMarketingDSN` | `AdsMarketingClient` | `ads_marketing.go` |
| Rebate DB | `RegionRebateDSN` | `RebateClient` | `rebate.go` |
| Booking DB（广告位库存、Brand Max） | `RegionBookingDSN` | `BookingClient` | `booking.go` |
| Buyer Segment DB | `RegionAdsTargetBuyerSegmentRegionDSN` | `BuyerSegmentClient` | `buyer_segment.go` |
| CRM DB | `CRMDSN`（全局唯一，不分 Region） | `CRMClient` | `crm.go` |

---

## 依赖方与使用方式

### 已知下游服务

根据 Google Docs 知识库和代码引用，import `adsdblib` 的服务包括：

- `ultimate_ads_service` — 主要消费方，几乎所有 ads-DB 读写都通过本库
- `ads_service` — 历史服务，同样直接 import
- `ads-status-syncer` — 读取 Campaign 和账户状态，使用 `AdsClient`
- `ads-resharder` — 读取并重分片 DB 数据
- `auto-rebate` — 使用 `RebateClient`
- `ads-crm` — 使用 `CRMClient`
- `ads-srm` / `uber-srm` — 使用 `SRMClient`
- `ads-marketing` — 使用 `AdsMarketingClient`
- `paidadsbackendadmin` — 使用 `AdsClient` 执行管理员查询
- `ads-db-ss`（内嵌，见下文）— 通过 SPEX 接口向 Indexer 等调用方暴露 DB 操作

Indexer 正在从直接 import `adsdblib` 迁移至调用 `ads-db-ss` SPEX 接口（见知识库 `GetCampaignXXX` 和 Indexer 连接优化章节）。

### 基础用法

如果你不需要额外定制或服务侧特有的原始查询，直接初始化 `DBManager`、获取所需 Client、使用后归还即可。

```go
import adsdblib "git.garena.com/shopee/deep/ads-db-lib"
import adsdblibConfig "git.garena.com/shopee/deep/ads-db-lib/config"

dbMgr, dispose, err := adsdblib.NewDBManagerV2WithConfigCenter(ctx,
    adsdblib.ManagerV2WithConfigCenterConfig{
        ConfigCenterClient: configCenterClient,
        ConfigCenterSecret: "your-secret",
        Option: adsdblibConfig.DBOption{
            DBSelector: adsdblibConfig.DBSelector{Ads: true},
            Conf:       adsdblibConfig.DBConfig{Parallelism: 16},
            Env:        "live",
        },
    },
    adsdblib.WithServiceName("your-service-name"),
)
if err != nil {
    return err
}
defer dispose()

// 获取 → 使用 → 归还 Client
cli, err := dbMgr.GetAdsClient()
if err != nil {
    return err
}
defer dbMgr.PutAdsClient(cli)

campaign, err := cli.GetCampaign(campaignID, userID, "SG")
```

### DBSelector — 按需开启 Client 池

`DBSelector` 控制初始化哪些 Client 池，只开启本服务需要的，避免不必要的连接：

```go
DBSelector: adsdblibConfig.DBSelector{
    All:          false, // 开启以下全部
    Ads:          true,
    SRM:          false,
    AdsMarketing: false,
    Rebate:       false,
    Booking:      false,
    CRM:          false,
    BuyerSegment:   false,
    IDGenerator:    true,  // 需要先开启 Ads = true
    IDMappingCache: true,  // 需要先开启 Ads = true；启用 Redis 分片键缓存
}
```

### ORM 配置覆盖

```go
// 覆盖所有 DB 的超时
Conf: adsdblibConfig.DBConfig{
    ORMCommon: &adsdblibConfig.ORMConfig{Timeout: 5 * time.Second},
}

// 仅覆盖特定 DB 的超时
Conf: adsdblibConfig.DBConfig{
    ORM: []adsdblibConfig.ORMConfig{{DBName: "shopee_ads_sg_db", Timeout: 5 * time.Second}},
}
```

合并优先级：`Lib ORMCommon < UserDefined ORMCommon < Lib ORM < UserDefined ORM`。

如果库内置配置已经满足需求，可以将 `ORMCommon` 和 `ORM` 留空。未填写的字段会继承库默认值，而不是把默认值清空。

### 通过 Redis 反查 ID（IDMappingClient）

`IDMappingClient` 无需扫描全量分片即可解析分片键：

```go
import adsdblib "git.garena.com/shopee/deep/ads-db-lib"

// 创建 KMS 鉴权 Redis 客户端
rdb, err := adsdblib.NewRedisClientWithKMS(ctx, adsdblib.RedisConfig{
    Addr:           "redis-host:6379",
    UserKMSKey:     "kms-key-for-redis-user",
    PasswordKMSKey: "kms-key-for-redis-password",
})
if err != nil {
    return err
}
defer rdb.Close()

idMapper := adsdblib.NewIDMappingClient(rdb)

// 通过 CampaignID 查 UserID，避免全分片扫描
userID, err := idMapper.GetUserIDByCampaignID(ctx, campaignID, "SG")

// 也支持批量查询
userIDs, err := idMapper.BatchGetUserIDByCampaignIDs(ctx, campaignIDs, "SG")
```

Redis Key 格式（供参考）：
- `ads:{region}:campaign_user:{campaignID}` — CampaignID → UserID
- `ads:{region}:ads_user:{adsID}` — AdsID → UserID
- `ads:{region}:ads_campaign:{adsID}` — AdsID → CampaignID

### 自定义查询

如果库中暂无所需查询，可通过 `cli.GetROrm(region)`、`cli.GetWOrm(region)` 等方法获取原始 `*goorm.Orm` 在服务侧实现。可复用的查询仍建议回收到 `ads-db-lib` 中；只有过于服务定制化的逻辑才建议留在消费方服务里。具体示例见 `example/config_center/`。

### 在单元测试中使用 Mock

```go
import "git.garena.com/shopee/deep/ads-db-lib"

var mockCli adsdblib.AdsClient = &adsdblib.MockedAdsClient{
    GetCampaignFunc: func(campaignID, userID int64, region string) (*Campaign, error) {
        return &Campaign{CampaignID: campaignID}, nil
    },
}
```

新增接口方法后，如需重新生成 Mock，请运行 `make gen-mock`。该命令依赖 `goimports`：

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

---

## 开发规范

### 代码风格

- 遵循 Go 标准规范（`gofmt`、`go vet`）。
- 提交前运行 `make fmt` 和 `make vet`；`make ci`（vet + fmt + test + validate-hardy-convertors）模拟 GitLab CI 流水线。
- **查询方法命名规范：**
  - `Add*` — `INSERT`，重复时报错；返回 `(id int64, err error)`。
  - `Add*Batch` — 批量 INSERT；返回 `(affectRows int64, err error)`。
  - `Audit*` — 审计日志 `INSERT`；返回 `(id int64, err error)`。
  - `Set*` — 已废弃；`INSERT OR UPDATE`（请改用 `Add` + `Update`）。
  - `Update*` — 按主键/唯一键 `UPDATE`；返回 `(affectRows int64, err error)`。
  - `Get*` — 按主键 `SELECT`，返回单条具体 proto 结构体。
  - `GetX*` — `SELECT … FOR UPDATE`（排他锁）版本。
  - `Get*s` — 带 `WHERE` 条件的 `SELECT`，接受 param 结构体，返回切片。
  - `GetX*s` — `SELECT … FOR UPDATE` 版本的 `Get*s`。
  - `Load*s` — 无 WHERE 的全表扫描，返回切片。
  - `Check*` — 存在性检查；返回 `(exist bool, err error)`。
  - `Count*` — `SELECT COUNT()`；返回 `(totalCount int64, err error)`。
- 写操作中始终用当前时间覆盖 `Ctime`/`Mtime`（例外：`ColdStartAds` 使用 `CreateTime`/`UpdateTime`；Archive DB 表跳过覆盖）。
- **Scan 参数状态过滤** — `CampaignScanParam` 新增 `Statuses []int32` 字段，支持在分片扫描时直接按 Campaign 状态过滤，无需结果集后过滤。
- **分片路由帮助函数** — `CampaignsParam.ShardHintIndexes()` 和 `AdsParam.ShardHintIndexes()` 从分片键计算 DB 与表的索引对，供 Hardy 的 routing-only 读取路径使用。`AdsParam.RouteShardKeys()` 从 `PrimaryKeys`、`CampaignUserKeys` 或普通 `UserIDs`/`CampaignIDs` 字段中解析路由级 UserID/CampaignID。
- **`TranslogsByDateParam`** — `TranslogsParam` 的同伴结构体，接受单个 `Timestamp` 仅用于表后缀路由（不注入 WHERE 条件）。新增 `MinID` 支持基于游标的分页，`ExcludeSellerUserIDInQuery` 可按需屏蔽 `acc_user_id` 过滤条件，`DeductUniqueID` 可按扣费事件 ID 过滤。
- 不要在消费方服务中添加特定于某 DB 的逻辑；请在 `ads-db-lib` 中提出新方法。

#### 查询分组速查

原始 README 曾按方法命名模式对查询 API 进行分组说明。下面保留这套说明方式，并把示例更新为当前代码中的真实签名。

| 分组 | 语义 | 当前示例 |
|------|------|---------|
| `Add*` | `orm.Add()` / `INSERT`，重复时报错；通常返回 `(id int64, err error)` | `AddAdvertisement(advertisement *bsads.Advertisement, region string) (id int64, err error)` |
| `Add*Batch` | 批量 `orm.Add()`；返回 `(affectRows int64, err error)`；即使 `err != nil`，`affectRows` 也可能非 0，因为前几批可能已成功；需要传入 `batchSize` | `AddSegmentWBLActionEntryBatch(entries []*pblib.SegmentWhiteBlacklistActionEntry, actionID int64, batchSize int, region string) (affectRows int64, err error)` |
| `Audit*` | 用于审计数据写入的 `orm.Add()`；入参通常是审计 param 结构体，而不是最终 DB model | `AuditAdvertisementV2(param AuditAdvertisementV2Param) (id int64, err error)` |
| `Set*` | 已废弃的 `orm.Set()` 风格：不存在则 `INSERT`，存在则 `UPDATE`；建议使用 `Add*` + `Update*` | `SetAdvertisement(advertisement *bsads.Advertisement, region string) (id int64, err error)` |
| `Update*` | `orm.Update()` / `UPDATE`，按主键、次级键或唯一键更新；通常返回 `(affectRows int64, err error)` | `UpdateAdvertisement(advertisement *bsads.Advertisement, region string) (affectRows int64, err error)` |
| `Get*` | `orm.Get()` / 按主键 `SELECT`；参数通常包括主键、必要的 split key，以及 `region` | `GetAdvertisement(adsID int64, campaignID int64, userID int64, region string, opts ...GetOption) (advertisement *bsads.Advertisement, err error)` |
| `GetX*` | `orm.GetX()` / `SELECT ... FOR UPDATE`；和 `Get*` 用法类似，但会加锁 | `GetXAdvertisement(userID int64, adsID int64, campaignID int64, region string) (advertisement *bsads.Advertisement, err error)` |
| `Get*s` | `orm.ReadRaw()` / 带 `WHERE` 条件的 `SELECT`；通常由 param 结构体驱动并返回切片 | `GetAdvertisements(param AdsParam, opts ...GetOption) (advertisements []*bsads.Advertisement, err error)` |
| `GetX*s` | 加锁版本的 `orm.ReadRaw()` / `SELECT ... FOR UPDATE` | `GetXTargetAdsBuyerSegmentTypes(region string, param BuyerSegmentTypeByRegionParam) (segmentTypes []*pblib.TargetAdsBuyerSegmentTypeByRegionDBModel, err error)` |
| `Load*s` | 无 `WHERE` 条件的 `orm.ReadRaw()`；通常返回全量切片，相关接口也可能结合 `LimitParam` 或 `SortParam` | `LoadCampaigns(region string) (campaigns []*bsads.Campaign, err error)` |
| `Check*` | 存在性检查；返回 `(exist bool, err error)` | `CheckAdvertisement(adsID int64, campaignID int64, region string) (exist bool, err error)` |
| `Count*` | `orm.Count()` / `SELECT COUNT()` | `CountSegmentWBLModels(param SegmentWBLModelsParam) (totalCount int64, err error)` |

### 版本与兼容

- `ads-db-lib` 以 Go 模块形式发布（路径：`git.garena.com/shopee/deep/ads-db-lib`）。
- 下游服务在 `go.mod` 中锁定特定 Tag 或 commit SHA。
- 破坏性接口变更（修改现有方法的必传参数）必须在合并前与所有已知消费方协调。
- 建议新增 `*WithCtx` 变体方法，而不是修改现有方法签名。
- 每次接口变更后，重新生成 Mock：`make gen-mock`（需要 `goimports`）。
- 每次修改配置文件后，重新生成嵌入二进制：`make gen-config`（需要 `pkger`）。
- 每次修改 proto 后，重新生成 protobuf：`make proto-compile`（需要 `spcli`）。

### 单元测试

- 运行测试：`make test`（详细输出）或 `make test-nv`（无详细输出）。
- 单元测试使用自动生成的 `mocked_*.go`（`MockedAdsClient`、`MockedSRMClient` 等），禁止在单元测试中访问真实 DB。
- 测试文件与实现文件并排放置（`*_test.go`）。
- `example/config_center/` 是集成示例，不视为单元测试。

### Code Review & Git Workflow

- Commit 格式：`(Feat|Fix|Docs|Style|Refactor|Test|Chore): [JIRA-ID] 描述`
- 分支命名：`dev/$username` 或 `feature/$feature_name`
- 所有变更通过 Merge Request 合并（squash commits，合并后删除源分支）。
- 影响下游服务的库变更，须在消费方完成测试或协调升级路径后才可合并。

---

## 配置说明

### 配置文件

内嵌 YAML 配置文件位于 `config/files/`，通过 `pkger` 打包进二进制：

| 文件 | 环境 |
|------|------|
| `live.yml` | 生产 |
| `liveish.yml` | 影子生产（压测、DB 迁移） |
| `stable.yml` | 稳定预发 |
| `staging.yml` | Staging |
| `uat.yml` | UAT |
| `test.yml` | 测试 / 单元测试 |

修改任意 `.yml` 文件后，运行 `make gen-config` 重新生成 `pkged.go`，并随代码一并提交。

如果本地尚未安装 `pkger`，可先执行：

```bash
go install github.com/markbates/pkger/cmd/pkger@latest
```

### Config Center 集成

库订阅 Config Center 命名空间 `adsdblib_{env}_{tag}_default`（live 当前使用 `adsdblib_live_temp_default`），内容包括：

- `ORMGroup` — ORM 连接配置和 SDDL 支持 DB 列表。
- `AdsDBSplit` — 各 Region 的 central/shard 分片 DSN 映射（驱动 `RegionAdsDSN` → `SplitDSN`）。
- `SbmDowngrade` — 影子 DB 路由（原始 DB → 目标 DB 的降级/迁移路径）。
- `AuditColdHotThreshold` — 按 Region 配置的审计表冷热分界阈值（月数）。

### SPEX 与 spcli 配置

`ads-db-ss` Sidecar 以 SPEX 服务方式暴露 `adsdblib` 接口：

- SPEX 服务名：`deep.paidads.platform.ads_db_ss`
- 生成 SPEX Stub：`make proto-compile`（调用 `spcli proto gen --force` 和 `spkit run spex-generator sp-workspace.yml`）
- 安装 `spcli`：`spkit run spcli`（参见 [SPEX Go SDK 快速上手](https://spex.shopee.io/overview/quick-start/languages/go/index.html) 和 [spcli 安装文档](https://spex.shopee.io/user-guide/SDK/Java/local.html)）

---

## 发布与集成

### 构建目标

```bash
# 构建 ads-db-ss Sidecar（Linux 交叉编译，用于 Mesos 部署）
make ads_db_ss

# 构建 DB 清理二进制
make ads_db_cleaner

# 构建 Hardy 转换器生成工具
make generate_hardy_convertors

# 本地执行 CI 检查
make ci
```

Mesos 部署描述文件：`deploy/adsdbss.json` 和 `deploy/adsdbcronjob.json`。

### 下游服务升级步骤

1. 在 `ads-db-lib` 合并变更并打 Tag（如 `v1.x.y`）。
2. 在各下游服务中升级依赖：
   ```bash
   go get git.garena.com/shopee/deep/ads-db-lib@v1.x.y
   go mod tidy
   ```
3. 若接口有新增方法，下游服务如重新暴露该接口，需重新生成 Mock。
4. 在下游服务完成测试后再部署。
5. 破坏性变更（罕见）须在打 Tag 前与所有消费团队协调。

### Hardy 转换器重新生成

`hardy_rec_convertors.go` 由 `cmd/generate_hardy_convertors/mappings.go` 生成：

```bash
make gen-hardy-convertors
```

CI 通过 `make validate-hardy-convertors` 验证生成文件未过期。

---

## 监控

Grafana 看板位于 [advertiser-platform 文件夹](https://monitoring.infra.sz.shopee.io/grafana/dashboards/f/advertiser-platform/advertiser-platform)：

| 看板名称 | 链接 |
|---------|------|
| PaidAds DB 看板 | [PaidAds-Db-Dashbord](https://monitoring.infra.sz.shopee.io/grafana/d/DqWajbR4z/paidads-db-dashbord) |
| PaidAds DB 看板 2 | [PaidAds-Db-Dashbord2](https://monitoring.infra.sz.shopee.io/grafana/d/k5IqkCg4k/paidads-db-dashbord2) |
| 各地区 Live ads DB | [[Region] Live ads db](https://monitoring.infra.sz.shopee.io/grafana/d/4RB9tsfIz/region-live-ads-db) |
| Resharder EKL（非 live） | [Resharder EKL ads db (nonlive)](https://monitoring.infra.sz.shopee.io/grafana/d/sY8oKqsNz/resharder-ekl-ads-db-nonlive) |

库暴露的核心 Prometheus 指标：

| 指标 | 类型 | Labels | 说明 |
|------|------|--------|------|
| `paidads_ads_db_manager_latency` | Histogram | `country`、`queryName`、`caller`、`dbName`、`dbShard` | 查询延迟（毫秒） |
| `paidads_ads_db_manager_count` | Counter | `country`、`queryName`、`status`、`caller`、`dbName` | 查询调用次数及状态 |
| `paidads_ads_db_manager_double_write_latency` | Histogram | `source`、`region`、`component`、`name` | 双写迁移延迟 |
| `paidads_ads_db_manager_orm_getter_count` | Counter | `region`、`db_type`、`status` | ORM getter（GetROrm 等）调用次数 |

在 Grafana Explore 中查看所有调用方（按 queryName）：
```promql
sum(rate(paidads_ads_db_manager_count{queryName!~"(Get|Put)AdsClient"}[1m])) by (caller)
```

计费 Lag 监控：[TDR Overview Dashboard — billing lag 面板](https://monitoring.infra.sz.shopee.io/grafana/d/YMWPK-Q7z/tdr-overview-dashboard?orgId=39&viewPanel=73&from=now-7d&to=now)

---

## 业务术语表

### 核心指标

| 术语 | 定义 |
|------|------|
| Ads GMV | 7 天内归因于广告点击的总销售额 |
| Ads Impression | 广告曝光次数 |
| CTR | Click-Through Rate = 点击数 / 曝光数 |
| CR / pCR | Conversion Rate = 广告订单 / 点击数；pCR 为预测转化率 |
| eCPM | Effective Cost Per Mille = 广告总花费 / 总曝光数 × 1000 |
| CPC | Cost Per Click，每次点击花费 |
| CPM | Cost Per Mille，每千次展示费用 |
| ROI | Return on Investment = Ads GMV / 广告花费（卖家视角） |
| ROAS | Return on Ads Spending，ROI 的同义词 |
| CIR | Cost-Income Ratio = 广告收入 / Ads GMV（平台视角） |
| Take-Rate | 广告收入 / 平台 GMV |
| Rank Score | eCPM + 质量因子 |
| Display Rate | 有曝光的广告数 / 活跃广告数 |
| Fill-up Rate | 实际曝光数 / 可用广告位曝光数 |

### 广告类型

| 术语 | 定义 |
|------|------|
| Search Ads | 关键词触发的搜索广告 |
| Discovery Ads（DADS / TADS） | 推荐场景广告（YMAL、Daily Discovery 等） |
| Display Ads | 品牌级 CPM 计费广告（视频、Banner）；由 `display_ads_*` 系列表管理 |
| Brand Max | 按展示量预约的品牌广告；由 Booking DB 管理 |
| Search Brand Ads | 搜索结果中的品牌关键词保留位 |
| Product Ads | 针对特定商品/SKU 的广告 |
| Live Stream Ads | 关联直播场次的广告 |
| Video Ads | 短视频格式广告 |
| New Product Boost（NPB） | 新商品上架推广加速功能 |

### 位置入口

| 术语 | 定义 |
|------|------|
| `placement = 4` | 搜索位置 |
| `placement = 3` | 店铺位置 |
| `placement = 40` | 推荐/Discovery 位置 |
| YMAL | You May Also Like — Discovery Ads 推荐区 |
| DD | Daily Discovery 日常发现 |
| PDP | Product Detail Page 商品详情页 |

### 卖家与广告主

| 术语 | 定义 |
|------|------|
| Active Seller | 在指定时间窗口内有广告账户且处于活跃状态的卖家 |
| PS | Preferred Sellers，Shopee 优质认证卖家 |
| OS | Official Shops 官方旗舰店 |
| SC | Seller Center 卖家中心 |
| SRM | Seller Relationship Management — Segment、Program、Incentive、Tracker |
| Segment | 卖家/买家分群规则定义 |
| Program | 卖家激励计划，关联 Segment 和配额规则 |
| Incentive | Program 下卖家的任务节点 |
| Tracker | 卖家行为追踪记录 |

### 竞价定价

| 术语 | 定义 |
|------|------|
| Manual Mode | 卖家手动设置关键词出价 |
| Simple Mode / oCPC | 自动优化出价；卖家设定目标 CIR 或 ROI；系统自动调整出价 |
| ROI2 / ROI3 | 目标 ROI 出价的第二、三代版本 |
| GMS | Gross Merchandise Sales — 预算与 GMV 挂钩的 Campaign 类型 |
| price（DB 字段） | 出价金额，以微货币单位存储 |
| daily_quota | Campaign 每日预算上限 |
| total_quota | Campaign 总生命周期预算上限 |

### 预测模型

| 术语 | 定义 |
|------|------|
| pCTR | 预测点击率 |
| pCR | 预测转化率 |
| rcgbdt | RC Gradient Boost Decision Trees — pCTR 模型 |
| PID | 比例积分微分控制器 — 用于 Simple Mode 的动态出价调整 |

### 系统特性与服务

| 术语 | 定义 |
|------|------|
| adsdblib | `git.garena.com/shopee/deep/ads-db-lib` 的 import 别名 |
| ads-DB | 本库管理的所有 MySQL 分片数据库的统称 |
| SDDL | Shopee Distributed Database Layer — 物理分片管理层 |
| Hardy | Shopee 面向分片 MySQL 的 ORM 框架 |
| ads-db-ss | 封装 adsdblib 的 SPEX Sidecar 服务，供远程调用方使用 |
| Config Center | Shopee 集中配置服务（命名空间：`adsdblib_{env}_{tag}_default`） |
| Auto Top-up | 账户余额低于阈值时自动充值 |
| QSS | Quick-Start Service — 新广告主快速入门功能 |

### 广告供给与展示

| 术语 | 定义 |
|------|------|
| Cold Start | 历史数据不足、模型无法精准预测的广告 |
| Broad Match | 搜索词包含关键词时触发广告召回 |
| Exact Match | 搜索词与关键词完全匹配时才触发 |
| Blacklist | 关键词或商品 ID 的排除名单 |
| Whitelist | 按卖家或商品控制功能访问权限的名单 |

### 管控与过滤

| 术语 | 定义 |
|------|------|
| Badcase | 被识别为效果不佳的广告位或创意；由 `badcase_*` 系列表管理 |
| OCPC CIR | 按商品/店铺/广告维度设置的自动出价成本控制上限 |
| Fraud user | 被标记为欺诈行为的卖家或买家（`fraud_user_tab`） |
| Rebate | Campaign 级别广告主激励，在达成 GMV 目标后发放 |

### 外部服务与系统

| 术语 | 定义 |
|------|------|
| SPEX | Shopee 内部 RPC 框架（服务网格）；ads-db-ss 使用 |
| SAS | Shopee Ads Services |
| SVS | Seller Value Service — 跨境卖家充值流程使用 |
| MCN | Multi-Channel Network — KOL/达人卖家账号管理 |

### 技术术语

| 术语 | 定义 |
|------|------|
| `deduct_unique_id` | 扣费事件的全局唯一标识，用于幂等性保证 |
| `uniq_sign` | 多张表中的去重键 |
| `extinfo` | Protobuf 序列化的 blob，用于扩展字段 |
| `ctime` / `mtime` | Unix 时间戳（秒），分别为创建/修改时间 |
| `region` string | 传给所有 Client 方法的两字母国家代码（如 `"SG"`、`"MY"` 等） |
| ORM | `goorm` — Shopee 内部 MySQL ORM 库 |
| XX | 压测使用的合成 Region，仅在 liveish 环境中路由到 `shopee_ads_xx_shard_db_00000000` |
| `ErrLockWaitTimeout` | 事务中触发 MySQL 锁等待超时（错误码 1205）时返回的错误 |
| `ErrRedisNotImplemented` | `IDMappingClient` 未配置 Redis 客户端时返回的错误 |

---

## 参考资料

- [技术设计文档 — Ads DB Manager lib](https://confluence.shopee.io/display/SPAD/Ads+DB+Manager+lib)
- [Advertiser Platform 架构总览（Confluence）](https://confluence.shopee.io/display/SPAD/Advertiser+Platform)
- [Paid Ads 业务术语表（Confluence）](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)
- [DB 解耦方案总览](https://docs.google.com/document/d/1I5Wr0fr5-wBH6KWyGpUBCNYMY4YU-Wv0eZ5okhDfveU/edit)
- [SDDL 介绍](https://gdbc.shopee.io/sddl/intro)
- [Database CMDB 控制面板](https://space.shopee.io/mts/sddl/shopee/database-listing?env=live&current=1&pageSize=10&name=ultimate_shard_db&collection_type=non-native&view_mode=full)
- [SPEX Go SDK 快速上手](https://spex.shopee.io/overview/quick-start/languages/go/index.html)

---

## 常见问题

**Q1. 如何向库中新增一个 DB 查询？**
在对应 Client 的具体实现类型中实现方法（如 `adsClient` 在 `ads.go`），并在 `ads_client_interface.go` 的接口中添加方法签名，然后运行 `make gen-mock` 重新生成 Mock。

**Q2. 如何避免不小心全表扫描过多分片？**
在查询 param 中始终传入分片键（`userid`、`campaignid`、`shopid` 等），`SplitParam` 会驱动分片选择。若只有非分片 ID（如仅有 `campaignid` 没有 `userid`），使用 `IDMappingClient` 的 `GetUserIDByCampaignID` 从 Redis 快速反查 UserID，无需全分片扫描。初始化方式见 `id_mapping.go` 中的 `NewIDMappingClient(rdb)` 和 `redis_client.go` 中的 `NewRedisClientWithKMS`。

**Q3. 什么时候用 `GetX*`（排他锁）vs `Get*`？**
仅在读取后立即需要在同一事务中更新该行时使用 `GetX*`（悲观锁）。只读查询始终用 `Get*`，避免不必要的锁竞争。

**Q4. `live` 和 `liveish` 环境有什么区别？**
`live` 是生产环境，路由到真实各 Region DB。`liveish` 是压测和 DB 迁移使用的影子环境，路由到合成的 `XX` Region DB（`shopee_ads_xx_shard_db_00000000`）。`liveish` + `delta` Tag 的 Client 会跳过所有非 XX Region。

**Q5. 审计表如何路由到正确的月份分片？**
`hot_cold_util.go` 从查询条件中提取 `ctime` 范围，计算出 `YYYYMM` 后缀，并只选择热窗口内的表分片（每 Region 的热窗口可通过 Config Center `AuditColdHotThreshold` 动态配置）。跨越热窗口的历史查询需访问冷存储。

**Q6. 如何更新内嵌配置文件？**
编辑 `config/files/*.yml`，然后运行 `make gen-config`（需要 `pkger`：`go get github.com/markbates/pkger/cmd/pkger`）。这会重新生成 `pkged.go`，须随代码一并提交。

**Q7. 降级路由（sbm_downgrade）是如何工作的？**
Config Center 发布 `SbmDowngrade` 配置，将原始 DB 名映射到目标 DB 名。当双写或读目标侧的 Flag 开启时，`sbm_downgrade.go` 透明地将 ORM 调用重定向到目标 DB（例如在 DB 拆分迁移期间）。

**Q8. 如何在本地运行 ads-db-ss Sidecar？**
构建：`make ads_db_ss`。以指向测试环境 Config Center 凭据的配置启动。服务监听 HTTP 端口（`/ping`、`/metrics`、`/debug/pprof`），并注册到 SPEX 接受 RPC 调用。

**Q9. 新表常量放在哪里？**
放在 `const.go` 中，遵循现有命名规范：分片表使用 `<Entity>Table = "<物理表名_%08d>"`，非分片表直接使用表名字符串。

**Q10. 我新增了接口方法，还需要更新什么？**
（1）在 `ads_client_interface.go` 的接口中添加方法。（2）在具体类型上实现该方法。（3）运行 `make gen-mock` 重新生成 `mocked_*.go`。（4）给库打新的版本 Tag。（5）通知下游团队升级依赖。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 03bea9adec9caa9e6c83bc28961a56f3466b3d05 | spec: 76fce5f679f9550b -->
