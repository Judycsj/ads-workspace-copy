---
id: non_product_ads_bidding_kb
title: Non-Product Ads (Brand & Content) Bidding 知识库
domain: bidding
owner: Content Algo / Bidding Algo
source_refs:
  - docs/personal/ivan.duzl/shop-content-ads-kb.zh-CN.md
  - service/ultrav-core/internal/agent/{shop_ads_agent, live_ads_agent, video_ads_agent}
  - service/online-bidding/online-bidding/internal/rule/{shopads, liveads, videoads}
last_updated: 2026-05-04
last_verified_at: 2026-05-04
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1V9msZSZJCnCeaKwcNwMlIl5zxfBCgSSMnaNnTF9f-94 gdoc_url=https://docs.google.com/document/d/1V9msZSZJCnCeaKwcNwMlIl5zxfBCgSSMnaNnTF9f-94/edit -->

# Non-Product Ads Bidding 知识库

## KB 必要信息索引

| 类别 | 当前索引 |
|---|---|
| 代码仓库 GitLab 路径 | `shopee/deep/paidads-bidding/online-bidding`、`shopee/deep/paidads-bidding/ultrav-core` |
| 离线 agent 入口 | `ultrav-core/internal/agent/{shop_ads_agent, live_ads_agent, video_ads_agent}` |
| 在线 rule 入口 | `online-bidding/internal/rule/{shopads, liveads, videoads}` |
| 核心服务 SDU 路径 | **Shop Ads**: [`ultrav_core`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.shop_ads.ultrav_core/dashboard) ｜ [`onlinebidding_v2`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.shop_ads.onlinebidding_v2/dashboard) ｜ [`ultrav_data_aggregator`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.shop_ads.ultrav_data_aggregator/dashboard)<br>**Live Ads**: [`ultrav_core`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.live_ads.ultrav_core/dashboard) ｜ [`onlinebidding_v2`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.live_ads.onlinebidding_v2/dashboard) ｜ [`ultrav_data_aggregator`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.live_ads.ultrav_data_aggregator/dashboard)<br>**Video Ads**: [`ultrav_core`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.video_ads.ultrav_core/quota/container/summary_by_az) ｜ [`onlinebidding_v2`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.video_ads.onlinebidding_v2/quota/container/summary_by_az) ｜ [`ultrav_data_aggregator`](https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.video_ads.ultrav_data_aggregator/quota/container/summary_by_az) |
| ConfigCenter namespace | **Shop Ads**: [`adsbidding.ultravcoreshop`](https://space.shopee.io/console/cmdb/config_center/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.shop_ads.ultrav_core/resource_management?env=live&project=%5Bsp%5Dadsbidding&resourceType=spex&spexServiceName=adsbidding.ultravcoreshop&tab=namespace)<br>**Live Ads**: [`adsbidding.ultravcorelivead`](https://space.shopee.io/console/cmdb/config_center/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.live_ads.ultrav_core/resource_management?env=live&project=%5Bsp%5Dadsbidding&resourceType=spex&spexServiceName=adsbidding.ultravcorelivead&tab=namespace)<br>**Video Ads**: [`adsbidding.ultravcorevideoad`](https://space.shopee.io/console/cmdb/config_center/detail/shopee.mp_search_recommendation_ads.paidads.ads_bidding.video_ads.ultrav_core/resource_management?env=live&project=%5Bsp%5Dadsbidding&resourceType=spex&spexServiceName=adsbidding.ultravcorevideoad&tab=namespace) |
| Grafana dashboard | **Shop Ads**: [Shop Ads Business Metrics](https://monitoring.infra.sz.shopee.io/grafana/d/FeJ-bFb4z/shop-ads-business-metrics?orgId=39&refresh=30s)<br>**Live Ads**: [Live Ads Core Metrics](https://monitoring.infra.sz.shopee.io/grafana/d/wvL90HDHz/live-ads-core-metrics?orgId=39)<br>**Video Ads**: [Video Ads Core Metrics](https://grafana.shopee.io/d/GoIw2dVHz/video-ads-core-metrics?orgId=2) |

## 范围

本文汇总 `Shop Ads`、`Live Ads`、`Video Ads`（统称 `Brand & Content Ads`，与 `Product Ads` 相对）的业务、技术和工程知识。

正文按以下顺序组织：

1. `Business`
2. `Technical`
3. `Engineering`

附录包含：

1. 术语表
2. 资料来源登记

本文不展开以下内容：

- 与 Product Ads 共享的反馈链路、数据聚合、tracking / translog / order 日志细节（详见 `product-ads-bidding-kb.md`）
- 全量历史方案
- 全量 Google Doc 细节
- 全量 Redis、Kafka、protobuf 细节

## Business

### 1. 业务定义

#### 1.1 Brand & Content Ads 范围

`Brand & Content Ads` 包含以下三种产品形态：

- `Shop Ads`：以店铺为推荐主体
- `Live Ads`：以直播间为推荐主体
- `Video Ads`：以视频为推荐主体

与 `Product Ads`（以单 item 为推荐主体）相对，三者在召回、扣费、混排策略上存在系统性差异，但共享 `ultrav-core` + `online-bidding` 的两侧出价框架。

#### 1.2 投放场景

##### 1.2.1 Shop Ads

支持以下投放面：

| 投放面 | 说明 |
| --- | --- |
| 搜索结果页 SRP | 命中 shop 关键词时展示 shop 卡片 |
| Game | Fruit / Daily-Check / Claw / Lucky-Prize 游戏页（每个入口都有独立 `bidCoef`） |
| Display / Discover | 推荐流 |

主要投放面截图（从左到右：SRP 商家卡片、SRP 关键词变体、Game 游戏页、Display / Discover）：

| SRP | SRP 关键词 | Game | Display |
| --- | --- | --- | --- |
| ![](img/cb0f0e068530e6d1355019696108a12f.png) | ![](img/123dbadea5f8220fc67bdebd3612c995.png) | ![](img/8de441bc1b1210e845a45100a7e09253.png) | ![](img/eb482a07dd8a11dce8064e896ad113fc.png) |

在线服务（`online-bidding/internal/rule/shopads/rank/bid/cal_coef.go`）的入口分发：

- `Placement = SHOP_SEARCH` 走默认搜索路径，`bid cap` 来自 `ShopSearchBidPriceCapByCountry`。
- `Placement = AUTO_SHOP_FRUIT_GAME_RECOMMEND` 触发对应游戏的场景系数（`FruitGameBidCoeff`、`DailyCheckGameBidCoeff`、`ClawGameBidCoeff`、`LuckyPrizeGameBidCoeff`），`bid cap` 来自 `ShopRcmdBidPriceCapByCountry`。
- ROI 2.0 系列（`Simple ROI2` / `ROI2` / `Shop GMV Max` / `Multi-Product Delivery` / `Shop GMV Max Simple`）在 `Entrance = ENTRANCE_SHOP` 下覆盖 cap 为 `Roi2MinBidCap` / `Roi2MaxBidCap`，可被 `ProductRoi2AntouShopMaxBidCap` 进一步覆盖。

##### 1.2.2 Live Ads

服务端将入口归为三类（`online-bidding/internal/rule/liveads/rerank/common/const.go`）：

| 入口分组 | 代码常量 | 典型入口 |
| --- | --- | --- |
| `Live Homepage` | `ENTRANCE_GROUP_LIVE_HOMEPAGE = 37` | 直播首页流（Discover-Live、Live tab homepage 等） |
| `Live PDP` | `ENTRANCE_GROUP_LIVE_PDP = 38` | PDP 浮窗的直播间入口 |
| `Live Other` | `ENTRANCE_GROUP_LIVE_OTHER = 39` | 其余直播入口（For You + Sliding、Autolanding、视频流直播等） |

入口分组决定：

- 统一 rerank 规则下的 `ecpv` min/max cap（`LiveAdsHPEcpvMinCap`/`MaxCap`、`LiveAdsPDPEcpvMinCap`/`MaxCap`、`LiveAdsOtherEcpvMinCap`/`MaxCap`）。
- `Max View` 的入口系数（`LiveAdsMaxViewHPCoef`、`LiveAdsMaxViewPDPCoef`、`LiveAdsMaxViewOtherCoef`）。
- `ROI2` / `Simple-ROI2` 的 pgmv 校准 cap factor（`LiveAdsNormDayHPCaliFactor`、`PDPCaliFactor`、`OtherCaliFactor` 以及对应 campaign-day 变体）。

`KOL` vs `Seller` 入口系数另有一条 AB 通路（`rerank_kol_seller_entrance_coef.go`），按 `(country, abVersion, entrance)` 取值。

主要直播入口截图：

| Discover (3327) | For You + Sliding (3328) | Video feed (3342) | Homepage (3337) | PDP (3338) |
| --- | --- | --- | --- | --- |
| ![](img/7c2d3106dd1c973b1697dc6fbdf0de82.png) | ![](img/fa0aa45d50499acaf22f0c4da333d006.png) | ![](img/270d82d94a374055ace5c66546a48c9c.png) | ![](img/75e44df6de8776ae4c49d6c105c15ead.png) | ![](img/b0c4959ace69e63bca6a950a4e015ea6.png) |

###### 单列与双列差异

历史上单列流（如 PDP 浮窗、For-You Sliding，每屏只可见一个直播间）和双列流（如 Discover、Homepage，网格化展示两个直播卡）的 eCPM 公式不同。**当前代码已经统一**：所有 `Live` 出价类型在 rerank 都按 `ecpm = ecpv · pCTR · 1000` 计算（`rerank_unified_ecpm.go:68`、`rerank_common_ecpm.go:58`、`rerank_ecpm.go:68`），不再按单列/双列分支公式。单列与双列的差异通过以下三条间接体现：

1. 入口分组（PDP 单列 vs Homepage / Other）使用不同的 `ecpv cap` 与入口系数。
2. 不同入口的 pgmv 校准 factor 不同。
3. 上游 pCTR / pCR 模型已按入口/布局学过分布差异，在线 bidding 直接消费。

代码中的 `Live` 出价类型（`adspb.AdsPricingType_LIVE_STREAM_*`）：
`LIVE_STREAM_MAX_VIEW`、`LIVE_STREAM_MAX_GMV`、`LIVE_STREAM_ROI_TWO`（`Target ROAS 2.0`）、`LIVE_STREAM_SIMPLE_ROI_TWO`（`Simple ROAS 2.0`）。

##### 1.2.3 Video Ads

两条投放路径并存：

- **明投**：KOL / 商家在视频上直接挂广告。`Max View`（按曝光出价）和 `Max GMV`（按 ROI 出价）。
- **暗投**：Product Ads ROI2 召回到视频场景，pricingType 为 `VIDEO_ROI_TWO`。共用同一套 rank rule，但出价系数由 Product Ads ROI2 栈维护，不进入视频 agent。

`online-bidding/internal/rule/videoads/rank/bid/` 在合并后的明投 + 暗投候选集上工作，按 pricingType 在每条规则的 `IsValid` 中分发。

主要视频入口截图：

| Homepage 内流 (33) | DD 外流 (3, video) | DD 内流 (34) | Video tab trending (29) | YMAL (58) |
| --- | --- | --- | --- | --- |
| ![](img/445920c1f3dcfd341a6f7b3250588bcf.png) | ![](img/dfcdfc20548cec3299a81450e768a8a3.png) | ![](img/97c3c8ccc449a0f070b7c68a6215f8c2.png) | ![](img/d2fdd97f0c512122040f82a182d240be.png) | ![](img/cfde7d6254f924a0d43c9f06d7fd9e71.png) |
| DD Minifeed (56) | For You (29) | Video page (29) | Search Video (1) / Search Video Landing (50) | PDP 浮窗 (54/55) |
| ![](img/7b7152bb857729539f9df2a896c110b3.png) | ![](img/6e384911cbf9fa6d9ca02cb83c29e65d.png) | ![](img/94a57639fb766931d5bb3a1b906dc2ab.png) | ![](img/77fdfc4fb29d03babc8af7f1dda8bc4e.png) | ![](img/fa660d5b32c48e6bc838b895020d907d.png) |

#### 1.3 出价产品形态

各出价产品在三个广告下的覆盖情况：

| 出价产品 | Shop Ads | Live Ads | Video Ads |
| --- | :---: | :---: | :---: |
| `Manual CPC` / `Manual eCPC` | ✓ | — | — |
| `AutoMode`（`Simple 1.0` / `Shop GMV Max`） | ✓ | — | — |
| `Max View 2.0` | — | ✓ | ✓ |
| `Max GMV 2.0` | — | ✓ | ✓ |
| `Target ROAS 2.0` (`ROI_TWO`) | — | ✓ | 暗投复用 Product Ads ROI2 |
| `Simple ROAS 2.0` (`SIMPLE_ROI_TWO`) | — | ✓ | — |

### 2. 关键指标

非 Product Ads 共享 Product Ads 的核心指标体系（`imp` / `click` / `order` / `cost` / `gmv` / `advv` / `cpc` / `cpm`，详见 `product-ads-bidding-kb.md` Business §2）。差异化指标如下：

- `ecpv = FinalCpaBid · pCR`（Live `Max View` 用 `· Ecr`），是 `Live Ads` 在 rerank 阶段的核心比较单位。
- `pCR` / `Ecr`：`Live` / `Video` 场景下被使用的转化与曝光相关预估信号。
- `Pgmv = pCTR · pCR · aov`：`Live Ads` rerank 中的 `Pgmv` 计算口径（`rerank_pgmv.go:21`），用于 ROI2 校准。
- `targetSBS`（Speed of Budget Spent）：MPC 中按剩余 quarter 窗口 `pdfSum` 归一的预算消耗速率，用于 `Live Max View 2.0` 等 BCB-MPC 控制器。

`Achievement` 状态、`algo` / `seller` 口径与命名规则与 Product Ads 一致。

## Technical

### 1. 技术总览

#### 1.1 两侧框架

非 Product Ads 出价分为两侧：

1. **`ultrav-core`**（离线，Flink 触发）：周期性消费反馈数据（`revenue`、`advv`、`click`、`order`、`deductedImp` 等），输出每个广告的 `priceCoef`。
2. **`online-bidding`**（在线服务）：把 `priceCoef` 与实时预估（`pCTR`、`pCR`、`Ecr`、`Pgmv`、`Aov`）以及入口/活动期系数组合成最终 eCPM。

每条策略的 agent 名称就是 `ultrav-core/internal/agent/...` 下的目录名。

#### 1.2 反馈数据与近线调控

非 Product Ads 与 Product Ads 共享反馈数据链路（`tracking` / `translog` / `order` 日志 → `ultrav-data-processor` → `ultrav-data-aggregator` → Redis 时间窗指标）。详见 `product-ads-bidding-kb.md` Technical §3。

近线调控直接由 `ultrav-core/internal/agent/{shop_ads_agent, live_ads_agent, video_ads_agent}` 下各自的控制器实现，下文 §3 展开。

### 2. 在线实时出价

#### 2.1 Shop Ads

![Shop Ads 出价架构](img/1098b9ad546bc0e01ab86a0d301489ee.png)

##### 2.1.1 出价模式

- **`Manual mode`**：商家自选关键词、自填出价，系统按 `keywordBid · pCTR` 排序（保留作 baseline，rank 阶段无独立公式）。
- **`eCPC mode`**：在 manual bid 基础上系统用 PID 系数微调，最终 click 出价 = `keywordBid · priceCoef · pcrCoef · scaling`。
- **`AutoMode`（`Shop GMV Max` / `Simple 1.0`）**：搜索场景由系统自动选词，游戏/推荐场景按 ROI 目标出价；初始出价端到端从 ROI 目标、`shopPcr`、`aov` 推导。

##### 2.1.2 在线最终出价公式

| 模式 | 公式 | 来源 |
| --- | --- | --- |
| `eCPC`（manual + ecpc） | `priceCoef = α + β · priceCoef · pcrCoef`，再 clamp 到 `[EcpcLowerBound, EcpcUpperBound]`；最终出价 = `InitBiddingPrice · priceCoef · entranceCoef` | `manual_ecpc_coef.go:46`、`cal_coef.go:30` |
| `AutoMode init bid` | `InitBiddingPrice = ceil(shopPcr · aov / realTargetRoi)`，其中 `realTargetRoi = TargetRoi / DefaultTargetRoiCoefficient · ShopAdsAutoModeBidConstCoef`；`SHOP_KEYWORD_SEARCH` 再乘 `InitPriceScaleMap[country]`，并 clamp 到 `[MinBidCap·minScale, MaxBidCap·maxScale]` | `init_auto_bid_price.go:49,57,67` |
| `AutoMode GMV 校准`（仅 search，且非 early-boost） | `priceCoef *= GmvCaliCoef`，并 clamp 到 `[PlanNormalDayGmvCoeffLower, …Upper]`（campaign-day 用对应变量） | `gmv_coef.go:51,68` |
| 最终调整出价 | `AdjustBiddingPrice = InitBiddingPrice · priceCoef · entranceCoef`（再叠加游戏场景系数，再过国家级 min/max bid cap；ROI2 系列覆盖为 `Roi2MinBidCap` / `Roi2MaxBidCap`） | `cal_coef.go:30,87` |

#### 2.2 Live Ads

![Live Ads 出价架构 (1/2)](img/90ca7213e568dbde6e6046c6d77024cc.png)

![Live Ads 出价架构 (2/2)](img/89a611cb16162033f24f6e818ff6844d.png)

##### 2.2.1 在线最终出价公式

服务暴露两阶段：prerank（按 `ECPM` 截断到 ~Top200）和 rerank（送给混排的最终 `ECPM`）。

| 阶段 | 出价类型 | ECPM 公式 | 来源 |
| --- | --- | --- | --- |
| Prerank | `Max View` | `FinalCpaBid · pCTR · Ecr · 1000` | `prerank_ecpm.go:25` |
| Prerank | `Max GMV` / `Target ROAS` / `Simple ROAS` | `FinalCpaBid · pCTR · pCR · 1000` | `prerank_ecpm.go:23` |
| Rerank（统一规则，AB `EnableUnifiedEcpmRuleMigration` 开） | 全部四种 Live 出价类型 | `ecpv = FinalCpaBid · pCR`（Max View 用 `· Ecr`）；`ecpm = clamp(ecpv, MinCap, MaxCap) · pCTR · 1000` | `rerank_unified_ecpm.go:33–68` |
| Rerank（旧版 MaxView/MaxGmv） | `Max View` / `Max GMV` | 同样的 `ecpv` 结构；`ecpv cap` 来自 `MaxViewCountryDefaultEcpvCap` / `MaxGmvCountryDefaultEcpvCap` 的国家×入口配置 | `rerank_common_ecpm.go:27–67` |
| Rerank（旧版 Target/Simple ROAS） | `ROI_TWO` / `SIMPLE_ROI_TWO` | `ecpv = FinalCpaBid · pCR`；用 `target_roas2` / `simple2` 配置中的 plan 级 GMV 校准 cap 截断 | `rerank_ecpm.go:28–67` |
| Pgmv | All | `Pgmv = pCTR · pCR · aov` | `rerank_pgmv.go:21` |

把 `ultrav-core` 的 `priceCoef` 和服务侧系数合成的 **`bidCoef`** 由 `rerank_unified_bid_coef.go:30` 一次性算出：

```
bidCoef = priceCoef · entranceCoef · campCoef
bidCoef = clamp(bidCoef, LiveAdsNormDayBidCoefMinCap, …MaxCap)
// campaign-day 用 LiveAdsCampDayBidCoef[Min/Max]Cap；黑名单主播单独有一组 cap
```

`entranceCoef` 来源按出价类型分支（`rerank_unified_entrance_coef.go`）：

- `ROI_TWO` / `SIMPLE_ROI_TWO`：从 `BiddingStoreData[GmvCalibrator]` 取 GMV 校准系数，再按入口分组 factor（`HP/PDP/Other` × normal-day 或 campaign-day）截断。
- `Max View`：直接取入口分组系数（`LiveAdsMaxView{HP,PDP,Other}Coef`）。

`campCoef` 仅在 early-boost / campaign 模式生效，`ROI2` 系列用 `EarlyBoostFactor`，`Max View` 用 `LiveAdsMaxViewCampaignFactor`。

##### 2.2.2 历史出价公式参考（单列 vs 双列）

历史上服务端按布局给出独立公式，当前代码（见 §2.2.1）已统一为 `ecpv · pCTR · 1000`，但下面保留历史分解以备参考。

**`Max View`** — 总体结构：

![](img/827d34c888853872e6d67784abbf438e.png)

- 单列流：

  ![](img/cf4c20ff945072b6e5f1e0cfc8b089af.png)
  ![](img/b980beabf8dac56b904252ed13da1c01.png)

- 双列流：

  ![](img/ae0b45ae982a7e0a283e573701fc13c2.png)
  ![](img/ce78088a5d7816aa05bb8a1f951dae49.png)

**`Max GMV`** — 总体结构：

![](img/d85fedc65ff9d7335c76472835304e2b.png)

- 单列流：

  ![](img/acd76fb11452e29739ca585a57045563.png)
  ![](img/38f7de6ebbb174615617fbf51e24d22e.png)

- 双列流：

  ![](img/bab2913a86d77c039515327141710b4e.png)
  ![](img/6520026879a532cf037fbbb2967a1075.png)

**`Target ROAS`** — 单列与双列的差异只在末项：

- 单列流：

  ![](img/acd76fb11452e29739ca585a57045563.png)
  ![](img/59a8018fc0a1abd4bf23423823cc787a.png)

- 双列流：

  ![](img/bab2913a86d77c039515327141710b4e.png)
  ![](img/c2c8325bf5d411e0a4804005d1e39c92.png)

#### 2.3 Video Ads

##### 2.3.1 在线最终出价公式

| 出价类型 | ECPM 公式 | 来源 |
| --- | --- | --- |
| `Max View` | `priceCoef · InitCpm · MaxViewExtraCoef · 1000` | `rank_max_view_ecpm.go:31` |
| `Max View`（AB `EnableMaxViewInitialCpvEcpm` 开） | `pCTR · InitCpv · priceCoef · MaxViewEcpmExtraCoef · 1000` | `rank_max_view_ecpm.go:34` |
| `Max GMV` | `priceCoef · ItemPrice · SoldCount / TargetRoi · MaxGmvExtraCoef · pCTR · pCR · 1000` | `rank_max_gmv_ecpm.go:32` |
| `ROI_TWO`（视频场景的暗投） | 同 `Max GMV`，但 `MaxGmvExtraCoef` 改取 `GetCountryRoiTwoExtraCoef()` | `rank_max_gmv_ecpm.go:48` |

### 3. 近线调控（ultrav-core agent）

#### 3.1 Shop Ads agent

| 阶段 / 模式 | Agent 路径 | 策略 |
| --- | --- | --- |
| `AutoMode` 冷启动 | `internal/agent/shop_ads_agent/auto_model_cold_start`（`auto_model_cold_start`） | 当 `BroadOrderCnt < OrderThreshold` 时返回常量 `BoostCoeff`；纯冷启动系数，不涉及 PID/MPC。 |
| `AutoMode` 成熟期（仅 `Target ROAS`，旧版） | `internal/agent/shop_ads_agent/auto_model_target_roas`（`auto_model_target_roas`） | 基于 ROAS 误差的 PID：`pError = 1 − rev/wAdvv`（超目标）或 `wAdvv/rev − 1`（未达），其中 `wAdvv = WeightBroadAdvv / roiDiscountRatio`；完整 PID（Kp、Ki、Kd），有 min/max coef cap，对游戏场景有独立 coef bound。 |
| `Manual eCPC` | `internal/agent/shop_ads_agent/manual_model_ecpc_strategy`（`manual_model_ecpc_strategy`） | PI 控制器（无 D 项）：`pError = 1 − rev/(advv·TargetCPCDiscountRatio)`；长尾词使用独立 `[longTailMinCoef, longTailMaxCoef]`。 |
| `AutoMode Search + Game` 成熟期联合调价 | `internal/agent/shop_ads_agent/shop_ads_target_roas_union_bidding_strategy`（`shop_ads_target_roas_union_bidding_strategy`） | 两阶段。**冷启动**（`BroadOrder7d < ColdStartOrderThreshold && IsUseBcb`）：BCB-PID。**成熟期**：MPC（`target_roas_mpc_strategy`）。触发条件：`clickDiff > ClickThreshold OR orderDiff > OrderThreshold OR timeDiff > TriggerTimeSeconds`。 |
| Campaign-day GMV 校准 | `internal/agent/shop_ads_agent/shop_gmv_calibrator`（`shop_gmv_calibrator`） | `gmvCaliCoef = Σ broadGmv / Σ pgmv`，统计最近 `NumHistoryWindows` 个 15 分钟窗口；窗口需满足 `orderCount ≥ WindowOrderThreshold` 才进入累计；总量再用 `clickThres`、`orderThres` gating。输出系数被在线 `gmv_coef.go` 消费。 |

#### 3.2 Live Ads agent

| 出价类型 | Agent 路径 | 控制器 |
| --- | --- | --- |
| `Max GMV 2.0` / `Target ROAS 2.0` / `Simple ROAS 2.0`（统一） | `internal/agent/live_ads_agent/live_max_gmv_unification`（`live_max_gmv_unification`） | 按 `DailyBroadOrder < LiveAdsBudgetPacingOrder` 分两阶段。**冷启动**：`FeedbackBudgetAllocator` → BCB-PID。**成熟期**：`ROI Bid InterpolatedMpc`（在历史 bid→ROI 样本上做线性插值）。状态保存 `LastCumDeductImp`、`LastCumOrder` 与 PID 误差；触发：`orderGain ≥ OrderTrigger OR impGain ≥ DeductImpTrigger OR timeElapsed ≥ PeriodTriggerDuration`。冷启动/成熟期切换时 bid coef 重置为 `InitialBcbBidCoef` 或 `InitialRoiBidCoef`。 |
| `Max View 2.0` | `internal/agent/live_ads_agent/live_max_view2_mpc`（`live_max_view2_mpc`） | 纯 MPC：把每个 quarter 的 `(coef, deductedImp, revenue)` 装成 `MpcUnit`，按最小 imp 阈值合并、按 coef-per-imp 分桶，再对 `coef → revSpeed` 做 Isotonic 回归保证单调，最后用 `inverseLinearInterpolate` 求满足 `targetSBS = (rtBudget / timeRemaining) / pdfSum` 的 coef。输出受单步 `CoefDiffPositive/NegativeCap` 与绝对 `CoefMinCap/MaxCap` 双重 clamp。还会调一个 duration coef 修正实际 slot 的结束时间。 |

单列/双列说明：两个 agent 都不按布局分支，每个广告一次只输出一个 `priceCoef`；布局相关的差异由服务侧的入口分组 cap 与入口系数承担。

#### 3.3 Video Ads agent

| 出价类型 | Agent 路径 | 控制器 |
| --- | --- | --- |
| `Max View` | `internal/agent/video_ads_agent/video_max_view`（`video_max_view`） | 单阶段 BCB-PID。最终 coef 取 `PID.GetPidCoef()`；输出 `CoefExtra.TargetCir = 1 / TargetRoi`。 |
| `Max GMV` | `internal/agent/video_ads_agent/video_max_gmv`（`video_max_gmv`） | 两阶段，按 `data.GetStrategyName()` 分发。**`StrategyNameBcbMpc`**（冷启 / budget 控制）：BCB-MPC，coef 取 `Context.BcbMpc.GetPidCoef()`。**`StrategyNameRoiPid`**（成熟期）：ROI-PID。 |

### 4. 通用出价能力

出价栈里有若干跨 Shop / Live / Video 复用的通用能力，被 §3 各产品 agent 组合调用。大致策略包括出价策略迭代、控制算法、环境建模、大促校准。

#### 4.1 出价策略迭代

成熟形态最终落到三种控制范式之一：

- **`Budget-Constraint Bidding`（BCB）**：按预算 pacing 出价，用于 `Video Max View` 和 `Live Max View` 冷启动路径。
  - 实现：BCB-PID（`video_max_view`、`live_max_gmv_unification` 与 `shop_ads_target_roas_union_bidding_strategy` 的冷启动阶段）或 BCB-MPC（`video_max_gmv` 冷启动、`live_max_view2_mpc`）。
- **强 ROI / 软预算**：`Live Target ROAS 2.0` 成熟期（`live_max_gmv_unification` 内部的 ROI Bid InterpolatedMpc）。
- **`Adaptive Dual Mode`（强预算、软 ROI）**：按数据密度动态切换 BCB 与 ROI/MPC，由 `shop_ads_target_roas_union_bidding_strategy`（PID→MPC）和 `live_max_gmv_unification`（PID→ROI-MPC）实现。阶段切换时 bid coef 重置为对应种子（`InitialBcbBidCoef` / `InitialRoiBidCoef`）。

![Adaptive Dual Mode 流程](img/07b8bd36c0733ea6b207c15ed562b8f6.png)

![BCB → ROI / MPC 阶段切换](img/46cb747aef4ac92048ed368f19b3a428.png)

#### 4.2 出价控制算法

- **`PID`**：在用，覆盖 Shop AutoMode `Target ROAS`（旧版）、`Manual eCPC`、`Video Max View`，以及 Shop / Live 统一策略的 BCB-PID 阶段。误差项总是 `pError = 1 − rev/wAdvv`（或低于预算时取倒数形式）；`iError` 累积带 min/max 防止积分饱和。
- **`MPC`（Model Predictive Control）**：在用，覆盖 `Live Max View 2.0`、`Live Max GMV` 统一策略成熟期、`Shop AutoMode` 统一策略成熟期、`Video Max GMV` 冷启动。核心步骤：
  1. 把最近若干 quarter 的 `(coef, deductedImp, revenue)` 分桶合并，消除稀疏桶噪声。
  2. 对 `coef → revSpeed` 做 Isotonic 回归，保证单调。
  3. `inverseLinearInterpolate(coef → revSpeed, targetSBS)` 解出下个 coef。
  4. 单步 diff cap + 绝对 min/max cap 双重 clamp。

**MPC 框架**：

![](img/9ffaa4c59863ec5feec4664b2e85fb0b.png)

**预测目标**（连续时间形式）：

![](img/4bbd353e9ec1cec7d8a297b88f86236a.png)

![](img/465c6b250aa8b57890b69439e2caf6a8.png)

求 ![](img/87cc513c6cf122ca79bf10140ed1d0c5.png) 满足 ![](img/9516d9002b8855ccf15a2e9ffebafd38.png)。

**两个关键项的分解**：

- ![](img/62fa258b743254ec02235627f6a517e1.png) ≈ ![](img/98f728a7f17c8e5b2d60caec43e39f74.png)
- ![](img/6272d2d0197e9ffc8fbca4fa03675002.png) ≈ ![](img/228f429cc7a1eab36cc7c4e58b787a32.png)

因子 ![](img/af15f47f966107d4bb50788cbe8e222a.png) 与估计偏差 / 出价强度 / 用户流量密度都有关。Live / Shop 的一价拍卖里被简化为统计意义的流量分布 ![](img/a119d270ec8a5a6c934f3b806063e8f8.png)。

bid → cost 与 bid → gmv 用线性插值做归一化：

- ![](img/f73640ba10287bdc02209ed91ec34259.png)
- ![](img/b45b511bc5e1258f32e034b429f7b023.png)

#### 4.3 环境建模

环境建模的作用是让 MPC 在样本之外做外推 —— 既包括时间维度（预测剩余 quarter 的流量强度），也包括出价维度（预测未观测过的 bid 对应的 cost / GMV）。

##### 4.3.1 当前线上：统计 PDF

- **`Quarter PDF`（曝光分布）**：默认按国家给；当 `ExtraParam.IsImpPdfDynamic` 开且 `ImpsPdf` 非空时，可用主播级动态 PDF 覆盖（`live_max_view2_mpc/max_view2_mpc_strategy.go:289`）。PDF 的定义是「每 15 分钟 quarter 内的请求量 / 当日总请求量」，离线从历史数据聚合得到。
- **`targetSBS`（Speed of Budget Spent）**：按剩余 quarter 窗口的 `pdfSum` 归一，使得 MPC 比较收入速率时是按 pdf 加权而非平均的 `budget / time`。
- **`bid → cost / bid → gmv` 线性插值**：在更精细的可学习模型尚未线上化时，服务侧用此简化形式替代。

统计 PDF 的局限：

- 假设日内流量稳定 / 平稳 —— 大促、季节性、外部冲击下经常被打破。
- 对历史偏差敏感，无法快速适应突变。
- 缺乏个性化 —— 把 campaign / advertiser / segment 级别的差异都抹平了。

##### 4.3.2 下一步方向：Budget2Roi 建模

目标是学习「每个广告自己的 PDF + 出价响应」，让预算分配能够跨日跨大促自适应。参考：[TD] [ProductAds-Bidding] Environmental Sequence Modeling。训练 setup：`mkplpaidads_search_ads.ads_bidding_seq_id`，ID 区域，pricing type 11/15，click 操作，14 天窗口。

**共享 cost model**：

```
cost = Wa · pdf(t) · Scale · ResponseFn(bid; Ka, Gamma)
```

- `pdf(t)`：96 个 quarter 的 softmax 分布（`Σ pdf = 1`），表征日内流量形状。
- `Wa`、`Ka`、`Gamma`：per-ad + per-category 可学参数（出价响应函数）。
- `Scale`：per-ad 可学幅值，由 `scale_head(z_final)` 给出，吸收响应函数无法覆盖的量纲差异。
- Shape–scale 解耦：PDF 只学**形状**（强制 sum=1），Scale 只学**幅值** —— 解决 identifiability 模糊。

**M1 — 静态 PDF baseline**：

- PDF 固定，从 `mkplpaidads_search_ads.bid_pdf_quarter_index_map` 读入，不参与训练；只训 `Wa`、`Ka`、`Gamma`。
- Loss：cost 预测的 weighted Huber + 相邻样本 diff Huber。

**M2 — 层级 Cat/Ad，shape-scale，无 residual**：

- 轻量模型，从广告级特征学一个稳定的 96-quarter PDF。
- 输入：bid history、time（sin / cos）、`ads_id`、`cats_id`。
- 层级结构：category PDF 作为稀疏 / 未见广告的稳定基底；ad embedding 在其上微调；gate 控制两者比例 —— 稀疏广告自动回退到 category 级。
- 用统计 PDF 作为软 KL 先验：`KL(learned_pdf || statistical_pdf)`。
- 不带 residual head —— M2 上线只走 lookup，所以 PDF + tower + scale 必须自己就准。
- 上线方式：encoder **每个广告只跑一次** → 把 96-bin PDF 与 Scale 写入 Redis；eval 不需要再做合成 forward。Fallback 链：广告级 PDF → 类目级 PDF → 全局 PDF（按 pricing_type）。
- Loss：`cost_point + cost_diff + kl + smooth + entropy_floor + recon`（recon 是 `[log1p(bid), sin(q), cos(q)]` 的 MSE）。

**M3 — RNN-VAE**：

- 用 GRU 消费 bid history，每条样本都给出动态 PDF。
- Shape-scale + 层级 cat / ad + GRU 时序上下文。
- 保留 residual head —— M3 在线全量推理，residual 修正可用且有效。
- 统计 PDF KL 先验，权重 0.08。
- 上线方式：每次请求都跑全模型推理。
- Loss：`cost_point + cost_diff + kl + smooth + entropy_floor + recon + ridge_l2`。

**方法对比**（离线，按曝光量分桶 head / torso / tail）：

| 桶 | 方法 | Ads 数 | cost_mae | cost_rmse | cost_wape | cost_smape |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| head | M3 | 5,264 | 0.318 | 0.946 | 0.410 | 0.218 |
| head | M2 | 5,264 | 0.341 | 1.004 | 0.440 | 0.247 |
| head | Baseline | 5,264 | 0.445 | 1.200 | 0.575 | 0.367 |
| torso | M3 | 21,054 | 0.038 | 0.413 | 0.416 | 0.067 |
| torso | M2 | 21,054 | 0.040 | 0.383 | 0.435 | 0.069 |
| torso | Baseline | 21,054 | 0.048 | 0.280 | 0.525 | 0.098 |
| tail | Baseline | 26,317 | 0.0058 | 0.089 | 0.576 | 0.017 |
| tail | M2 | 26,317 | 0.0062 | 0.152 | 0.609 | 0.014 |
| tail | M3 | 26,317 | 0.0064 | 0.181 | 0.627 | 0.015 |

解读：M3 在 head 和 torso（个性化收益明显的桶）上明显占优；tail（稀疏广告）上静态 baseline 在 point error 上还有竞争力，M2 借类目级回退把差距收窄。综合考虑上线成本（M2 只需 lookup、M3 要在线推理），**M2 是推荐的上线路径**。

##### 4.3.3 数学参考

早期 VAE 形式（启发后续工作）：

![](img/6a6eda181211dbd1039a094ac089d84a.png)

![](img/7ed350e4060e5aba893de70074f5ddb8.png)

![](img/2b93c25164ac74dc790f22248de84d04.png)

![](img/e6f439f74293fc46022d04d10782f5ff.png)

其中 ![](img/6a6eda181211dbd1039a094ac089d84a.png) 为环境潜变量，![](img/7ed350e4060e5aba893de70074f5ddb8.png) / ![](img/2b93c25164ac74dc790f22248de84d04.png) 为 encoder，![](img/e6f439f74293fc46022d04d10782f5ff.png) 为 decoder。当前 M3 RNN-VAE 沿用这个结构，把后验改成 GRU 驱动。

线上简化版的 cost 响应形式（M1 `Wa · pdf · Scale · ResponseFn` 的前身）：

![](img/aa35c958e230517d3e1b326ae0b6f784.png)

![](img/316d0fb589eaab8af4d974c6f46a7b4d.png)

直播场景给 ![](img/f70c6555bcaf30e909bd9abfa8954cef.png) 引入了简单的时序结构：

![](img/8f3904d8e8cc36a94d41c7dfa857e8fb.png)

#### 4.4 大促策略

端到端 pgmv 校准是常驻的，并不只在大促当日生效：

- `shop_gmv_calibrator` 每 quarter 输出一次 `gmvCaliCoef`；`gmv_coef.go` 在 `AutoMode` 搜索广告上消费它，平日截断到 `PlanNormalDayGmvCoeff[Lower,Upper]`，大促期截断到 `PlanCampaignDayGmvCoeff[Lower,Upper]`。
- `Live Ads` 的对应机制走 `BiddingStoreData[GmvCalibrator]`，由 `rerank_unified_entrance_coef.go` 消费，平日 vs 大促日的校准 factor 按入口分组（`HP / PDP / Other`）切换。
- 大促模式还会用 `CampaignEcpvCapLooseCoef` 放宽 `ecpv max cap`（`rerank_unified_ecpm.go:55`），避免放松后的 pgmv 校准系数被更紧的 `ecpv cap` 抵消。

**端到端 pgmv 校准公式**：

![](img/daac7f5788d3d20652f2ae516ef03e2f.png)

![](img/ec21aa1a5551f1e22c420f680114b607.png)

平日和大促日走同一套校准形态，仅 cap 区间不同。

### 5. 已知挑战

#### 5.1 Shop Ads

- AOV 准确度直接影响 `AutoMode` 出价范围（`shopPcr · aov / realTargetRoi`）以及 GMV 校准增益。

#### 5.2 Live Ads

- KOL vs Seller 差异：KOL 主投 PDP，Seller 主投 rcmd，需要不同 cap factor（已在 `HP/PDP/Other` 因子和 KOL-Seller AB 入口系数表中实现）。
- AOV / 系统 `Target ROAS` 估计噪音（特别是 `ROI 2.0` BCB 需要估计直播间起止时间）。
- 直播档期错配：`Live 2.0` 强制 "All Day" 排期，agent 需要通过 `FillDurationInfo` 估计直播时长，不能依赖用户填的结束时间。

#### 5.3 Video Ads

- 视频场景订单稀疏（每千次曝光的订单约为 product ads 的 1/10），`TargetROI` 较高（≈ KOL 佣金倒数），导致 ROI-PID 成熟期数据稀疏，BCB-MPC 仍是常态。
- 明投 vs 暗投：高 `TargetROI` 下，明投 `Max-GMV` 难以在同一拍卖中战胜暗投 `ROI2`，白名单扩量受此牵制。

## Engineering

### 1. 服务总表

| 服务 | 角色 | 关键入口 |
| --- | --- | --- |
| `service/online-bidding/online-bidding` | 在线请求级出价编排 | `internal/rule/shopads/`、`internal/rule/liveads/`、`internal/rule/videoads/` |
| `service/ultrav-core/ultrav-core` | bidding framework 与离线 agent | `internal/agent/shop_ads_agent/`、`internal/agent/live_ads_agent/`、`internal/agent/video_ads_agent/` |
| `service/infra/bidding-store` | 系数读取服务 | 与 Product Ads 共享，详见 `product-ads-bidding-kb.md` Engineering §2.2 |

反馈链路（`ultrav-data-processor` / `ultrav-data-aggregator`）与 Product Ads 共享，本文不再重复。

### 2. 在线出价模块

#### 2.1 Shop Ads

- 角色：店铺广告在线出价
- 关键入口：`online-bidding/internal/rule/shopads/rank/bid/cal_coef.go`、`init_auto_bid_price.go`、`gmv_coef.go`、`manual_ecpc_coef.go`
- 主要目录：`rank/bid/`

#### 2.2 Live Ads

- 角色：直播广告在线出价
- 关键入口：
  - 统一规则：`online-bidding/internal/rule/liveads/rerank/bid/rerank_unified_ecpm.go`、`rerank_unified_bid_coef.go`、`rerank_unified_entrance_coef.go`、`rerank_pgmv.go`
  - 旧版：`rerank_common_ecpm.go`、`rerank_ecpm.go`
  - prerank：`prerank_ecpm.go`
- 主要目录：`rerank/bid/`、`rerank/common/`

#### 2.3 Video Ads

- 角色：视频广告在线出价（明投 + 暗投）
- 关键入口：`online-bidding/internal/rule/videoads/rank/bid/rank_max_view_ecpm.go`、`rank_max_gmv_ecpm.go`
- 主要目录：`rank/bid/`

### 3. 离线 agent 模块

#### 3.1 Shop Ads agent

- 角色：店铺广告离线系数计算
- 关键入口：
  - `ultrav-core/internal/agent/shop_ads_agent/auto_model_cold_start`
  - `ultrav-core/internal/agent/shop_ads_agent/auto_model_target_roas`
  - `ultrav-core/internal/agent/shop_ads_agent/manual_model_ecpc_strategy`
  - `ultrav-core/internal/agent/shop_ads_agent/shop_ads_target_roas_union_bidding_strategy`
  - `ultrav-core/internal/agent/shop_ads_agent/shop_gmv_calibrator`

#### 3.2 Live Ads agent

- 角色：直播广告离线系数计算
- 关键入口：
  - `ultrav-core/internal/agent/live_ads_agent/live_max_gmv_unification`（`Max GMV` / `Target ROAS` / `Simple ROAS` 统一）
  - `ultrav-core/internal/agent/live_ads_agent/live_max_view2_mpc`（`Max View 2.0`）

#### 3.3 Video Ads agent

- 角色：视频广告离线系数计算
- 关键入口：
  - `ultrav-core/internal/agent/video_ads_agent/video_max_view`
  - `ultrav-core/internal/agent/video_ads_agent/video_max_gmv`

## 附录

### 1. 术语表

#### 链路术语

`Rerank`

- `Live Ads` 在线请求级处理入口

`prerank` / `rerank`

- `Live Ads` 服务的两阶段：prerank 截断到 ~Top200，rerank 输出送给混排的最终 `ECPM`

`明投` / `暗投`

- `Video Ads` 的两条投放路径。明投：KOL / 商家直接挂广告；暗投：Product Ads ROI2 召回到视频场景，pricingType 为 `VIDEO_ROI_TWO`

`单列` / `双列`

- `Live Ads` 的布局划分。单列流（PDP 浮窗、For-You Sliding 等）每屏只可见一个直播间；双列流（Discover、Homepage 等）网格化展示两个直播卡

#### 出价产品

`Manual CPC` / `Manual eCPC`

- Shop Ads 的手动出价 / 增强手动出价

`AutoMode`

- Shop Ads 的自动出价模式（`Simple 1.0` / `Shop GMV Max`）

`Max View 2.0`

- Live / Video Ads 的按曝光出价产品

`Max GMV 2.0`

- Live / Video Ads 的按 GMV 出价产品

`Target ROAS 2.0` (`ROI_TWO`)

- Live Ads 的目标 ROAS 型自动出价产品

`Simple ROAS 2.0` (`SIMPLE_ROI_TWO`)

- Live Ads 的简化版自动出价产品

#### 控制范式

`BCB`

- `Budget-Constraint Bidding`，按预算 pacing 出价

`Adaptive Dual Mode`

- 按数据密度动态切换 BCB 与 ROI/MPC 的双模控制器

`PID` / `MPC`

- 经典控制算法（`Proportional-Integral-Derivative` / `Model Predictive Control`），覆盖各 agent 的成熟期或冷启动

#### 核心系数

`priceCoef`

- 离线 `ultrav-core` agent 输出的广告级出价系数

`bidCoef`

- 在线服务侧合成的最终系数：`bidCoef = priceCoef · entranceCoef · campCoef`

`entranceCoef`

- 入口系数，按出价类型从 `BiddingStoreData[GmvCalibrator]` 或入口分组常量取值

`campCoef`

- 大促 / early-boost 系数（`EarlyBoostFactor`、`LiveAdsMaxViewCampaignFactor` 等）

`GmvCaliCoef`

- 端到端 pgmv 校准系数：`Σ broadGmv / Σ pgmv`，由 `shop_gmv_calibrator` 等 agent 输出

`targetSBS`

- `Speed of Budget Spent`，MPC 中按剩余 quarter 窗口 `pdfSum` 归一的预算消耗速率

#### 入口分组

`Live Homepage` / `Live PDP` / `Live Other`

- Live Ads 的三组入口分类（代码常量 `ENTRANCE_GROUP_LIVE_HOMEPAGE = 37` / `LIVE_PDP = 38` / `LIVE_OTHER = 39`）

`HP / PDP / Other`

- pgmv 校准 cap factor 的三组分类，与上面的入口分组一一对应

### 2. 资料来源登记

#### 说明

可信级别：

- `L1`：代码、接口定义、配置、运行入口
- `L2`：仓库内 README / 正式 markdown
- `L3`：Google Doc
- `L4`：背景理论或历史材料

状态：

- `used`：已进入正文
- `indexed`：已登记但未进入正文
- `todo`：待阅读或待补充

#### 清单

| 来源标识 | 类型 | 主题 | 可信级别 | 状态 | 作用 |
| --- | --- | --- | --- | --- | --- |
| `docs/personal/ivan.duzl/shop-content-ads-kb.zh-CN.md` | 仓库 markdown | Shop / Live / Video Ads 投放场景与出价策略 | `L2` | `used` | 本 KB 主体来源 |
| `service/ultrav-core/ultrav-core/internal/agent/shop_ads_agent/` | 代码 | Shop Ads 离线系数计算 agent | `L1` | `used` | Shop Ads agent 实现 |
| `service/ultrav-core/ultrav-core/internal/agent/live_ads_agent/live_max_gmv_unification` | 代码 | Live Max GMV / Target / Simple ROAS 统一 agent | `L1` | `used` | Live Ads 统一 agent |
| `service/ultrav-core/ultrav-core/internal/agent/live_ads_agent/live_max_view2_mpc` | 代码 | Live Max View 2.0 BCB-MPC | `L1` | `used` | Live Max View 2.0 agent |
| `service/ultrav-core/ultrav-core/internal/agent/video_ads_agent/video_max_view` | 代码 | Video Max View BCB-PID | `L1` | `used` | Video Max View agent |
| `service/ultrav-core/ultrav-core/internal/agent/video_ads_agent/video_max_gmv` | 代码 | Video Max GMV BCB-MPC / ROI-PID | `L1` | `used` | Video Max GMV agent |
| `service/online-bidding/online-bidding/internal/rule/shopads/rank/bid/cal_coef.go` | 代码 | Shop Ads 在线出价系数计算 | `L1` | `used` | Shop Ads 在线出价主链路 |
| `service/online-bidding/online-bidding/internal/rule/shopads/rank/bid/init_auto_bid_price.go` | 代码 | Shop Ads `AutoMode` 初始出价 | `L1` | `used` | `InitBiddingPrice` 公式 |
| `service/online-bidding/online-bidding/internal/rule/shopads/rank/bid/gmv_coef.go` | 代码 | Shop Ads GMV 校准系数应用 | `L1` | `used` | `GmvCaliCoef` 在线消费 |
| `service/online-bidding/online-bidding/internal/rule/shopads/rank/bid/manual_ecpc_coef.go` | 代码 | Shop Ads `Manual eCPC` PI 控制器 | `L1` | `used` | `eCPC` 模式 |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/bid/rerank_unified_ecpm.go` | 代码 | Live Ads 统一 ECPM 公式 | `L1` | `used` | Live Ads 在线主链路 |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/bid/rerank_unified_bid_coef.go` | 代码 | Live Ads `bidCoef` 合成 | `L1` | `used` | `bidCoef = priceCoef · entranceCoef · campCoef` |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/bid/rerank_unified_entrance_coef.go` | 代码 | Live Ads `entranceCoef` 分支 | `L1` | `used` | `entranceCoef` 来源 |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/bid/rerank_pgmv.go` | 代码 | Live Ads `Pgmv` 计算 | `L1` | `used` | `Pgmv = pCTR · pCR · aov` |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/bid/rerank_common_ecpm.go` | 代码 | Live Ads 旧版 MaxView/MaxGmv ECPM | `L1` | `used` | 旧版 ECPM 公式 |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/bid/rerank_ecpm.go` | 代码 | Live Ads 旧版 Target/Simple ROAS ECPM | `L1` | `used` | 旧版 ECPM 公式 |
| `service/online-bidding/online-bidding/internal/rule/liveads/prerank/bid/prerank_ecpm.go` | 代码 | Live Ads prerank ECPM | `L1` | `used` | prerank 截断公式 |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/common/const.go` | 代码 | Live Ads 入口分组常量 | `L1` | `used` | `ENTRANCE_GROUP_LIVE_*` |
| `service/online-bidding/online-bidding/internal/rule/liveads/rerank/common/rerank_kol_seller_entrance_coef.go` | 代码 | Live Ads KOL vs Seller 入口系数 AB 通路 | `L1` | `used` | KOL/Seller 分流 |
| `service/online-bidding/online-bidding/internal/rule/videoads/rank/bid/rank_max_view_ecpm.go` | 代码 | Video Ads `Max View` ECPM | `L1` | `used` | Video Ads 在线主链路 |
| `service/online-bidding/online-bidding/internal/rule/videoads/rank/bid/rank_max_gmv_ecpm.go` | 代码 | Video Ads `Max GMV` / `ROI_TWO` ECPM | `L1` | `used` | Video Ads 明投 + 暗投公式 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/...` | 代码 | Budget2Roi 环境时序模型 | `L1` | `indexed` | M2 / M3 模型实现待 KB 补充 |
| `mkplpaidads_search_ads.ads_bidding_seq_id` | Hive 表 | Budget2Roi 训练样本 | `L1` | `used` | Environmental Sequence Modeling 训练 setup |
| `mkplpaidads_search_ads.bid_pdf_quarter_index_map` | Hive 表 | M1 静态 PDF 来源 | `L1` | `used` | M1 baseline PDF |
| Google Doc `[TD] [ProductAds-Bidding] Environmental Sequence Modeling` | Google Doc | Budget2Roi 模型设计 | `L3` | `used` | M1 / M2 / M3 设计来源 |
