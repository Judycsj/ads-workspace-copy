---
id: ads_roi3_overview
title: Ads ROI3 总览
domain: roi3
owner: Product Algo / ROI3 Strategy
source_refs:
  - ROI3 pacing analysis working draft: concept semantics, analysis contract, examples, and data migration notes (external working materials, not versioned in this repo)
  - Ads Smart Voucher business background notes (external supporting material, not versioned in this repo)
  - docs/team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-kb.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-business.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-model.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-sample.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-feature.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-data-tables.md
  - docs/common/sub-kb/2.2-pgmv-model/product-ads-model-kb.md
  - docs/common/core-knowledge/
last_updated: 2026-04-22
last_verified_at: 2026-04-22
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1pYLqZI4HruQR6MpSQ_S4Dc-pGK2jAw4VpJadJjfE4mE gdoc_url=https://docs.google.com/document/d/1pYLqZI4HruQR6MpSQ_S4Dc-pGK2jAw4VpJadJjfE4mE/edit -->


# Ads ROI3 总览

## KB 必要信息索引

| 类别 | 当前索引 |
|---|---|
| 代码仓库 GitLab 路径 | `shopee/deep/paidads-bidding/online-bidding`、`shopee/deep/paidads-bidding/ultra-core`、`shopee/deep/paidads-alg` |
| 核心服务 SDU 路径 | **【待确认】需由 owner 通过 Space / SMC 确认 `online-bidding`、UltraCore、posterior / controller 相关线上 SDU 路径** |
| ConfigCenter namespace | **【待确认】ROI3 / ROI4 / cofund / voucher pacing 参数 namespace 需补齐当前线上值** |
| Grafana dashboard | **【待确认】当前源 KB 未集中列出 ROI3 发券在线链路、预算、pacing、voucher spend dashboard** |
| 关键 Kafka topic | **【待确认】posterior、voucher spend、tracking 回流如有 Kafka topic，需按当前生产配置补齐** |
| 核心 Hive 表名 | `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live`、`mp_paidads.dwd_ads_request_performance_di__reg_s0_live`、`mp_paidads.ads_order_voucher_1d__reg_s0_live`、`mkplpaidads_search_ads.dws_cr_uplift_pcoc_di` |

## 阅读指引

本文档按“业务背景 -> 分层语义 -> 在线主链路 -> 关键变量 -> SQL 映射 -> 分析框架”组织，适合用来回答 3 类问题：

- ROI3 到底在做什么，和 ROI4 / cofund 的边界是什么。
- `pcr_0 / pcr_v / pgmv_0 / pgmv_v / uplift_* / pcoc / voucher_price / reward_discount / PidCoef` 分别属于哪一层。
- Level1 / Level2 / Level3 分析应该看哪些表、哪些变量、哪些约束。

如果问题更偏“在线发券 serving / RCT / 候选过滤 / package budget / coef 公式”，优先配套阅读：

- [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)

如果问题更偏“模型架构 / treatment-control / 1h label / uplift 特征 / 逐券 profit-bid 公式”，优先配套阅读：

- [`../../model-algo/knowledge/uplift-kb.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-kb.md)
- [`../../model-algo/knowledge/uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
- [`../../model-algo/knowledge/uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md)
- [`../../model-algo/knowledge/uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md)
- [`../../model-algo/knowledge/uplift-feature.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-feature.md)
- [`../../model-algo/knowledge/uplift-voucher-strategy.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md)
- [`../../model-algo/knowledge/uplift-data-tables.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-data-tables.md)

注意：

- 配套 FAQ 里的 `代码事实 / 字段映射 / SQL 方法` 可以直接复用。
- FAQ 里的具体统计数值仅是历史排查快照，不能直接视为当前 truth；后续类似问题需要按同一方法重新跑数。
- 本卡片负责统一 ROI3 的分析语义和在线观测约束，不展开复写 uplift 专题文档已经稳定的模型 / 样本 / 特征 / 策略细节。

建议阅读顺序：

- `§0–§3`：先统一 ROI3 的业务目标、边界和锁定语义。
- `§4–§6`：再理解模型层、校准层、策略层、控制层、观测层如何串起来。
- `§7–§10`：再看 pCOC、AB 桶语义、SQL 数据契约和三层分析框架。
- `§12`：最后看常见问答的“参考回答 + 取证路径”；这部分默认不应被当成标准答案。

## 0. 一句话摘要

- 这个主题是什么：Ads Product ROI3 的统一知识卡片，目标是把“模型预测、发券策略、预算控制、SQL 观测”放到同一套语义里理解。
- 作用在哪类流量：Product Ads 的 Smart Voucher / ROI3 / ROI4(cofund) 相关流量与实验分析。
- 核心目标：统一 ROI3 的变量定义、空间标签、成本口径和实验对照语义，支撑 Level1 / Level2 / Level3 分析与后续诊断脚本迭代。

## 1. 基本信息

| 字段 | 内容 |
|---|---|
| 主题名称 | Ads ROI3 |
| 主题定位 | Product Ads Smart Voucher 语义、链路与分析框架总览 |
| 适用对象 | 策略、分析、算法、诊断脚本维护者 |
| 主要参与方 | 用户、广告主、平台 |
| 相关系统 | `online-bidding`、`ultra-core`、posterior、AB 平台、DataSuite、HyperX trace |
| 主链路文件 | `rerank_uni_pgmv.go`、`rerank_voucher_rule.go`、`voucher_*`、`voucher_pacing_control/*` |
| 当前状态 | 已完成首版知识卡片，并补齐 FAQ 对齐的基础概念 / 表 / 字段 / 流程速记，沉淀了语义分层、变量字典、AB 桶约束、SQL 映射与三层分析框架 |

## 2. 业务背景与边界

### 2.1 ROI3 / ROI4 在业务上解决什么问题

Ads Smart Voucher 不是单纯改 bid，而是在广告竞价之外增加了“是否发券、发多大券、谁承担券成本”的补贴决策层。

背后的业务目标可以压缩成两句话：

- 发券可以提升用户转化意愿，从而提升广告竞争力与后续业务结果。
- 券不是白送的，平台必须关注发券带来的收益能否覆盖券成本。

### 2.2 ROI3 与 ROI4 / cofund 的边界

- `ROI3`
  - 默认指平台单边承担券成本。
  - 重点在“发券是否让平台总体价值更优”。
- `ROI4 / cofund`
  - 默认指平台与广告主共担。
  - 价值函数和控制链路里会更显式地加入平台 spend / ROI 约束。

在当前主语义下，区分两者最直接的代码落点包括：

- `enableCofund`
- `targetPlatformSpendImps`
- `getPlatformGmvRoi()`
- `voucher_pacing_control`

### 2.3 为什么 uplift 模型是 ROI3 的核心

ROI3 不是只看“发券后的最终值”，而是同时比较三类量：

- 不发券时会怎样：base 预测。
- 发券相对不发券能多带来多少：uplift 预测。
- 发券要付出多少成本：券面额、核销成本、平台 spend。

因此 ROI3 的核心不是一个单独的 `pcr` 或 `pgmv`，而是：

- `base`
- `voucher`
- `uplift`
- `cost`

四类量之间的关系。

在本知识库里，ROI3 的 canonical 语义默认按当前分析契约记录：

- 先看 `base / voucher / uplift / cost` 四类量之间的关系。
- 再看当前上线保护规则如何约束这些量。

当前最需要固定记住的 Guardrail 是：

```text
Guardrail = gmv_uplift / 4 + advv_uplift - cost_uplift > 0
```

也就是“平台从 GMV uplift 和广告收入 uplift 中拿回来的价值，要能覆盖券成本”。这里不展开 Profit / ROI / eCPMV 的专题推导，详细说明见 [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)。

如果需要补历史产品命名背景，可以再说明：
Confluence 和 `ads-knowledge-qa` 里常见的 `ROI3 = GMV / (ad cost + coupon cost)` 仍然成立，但它在本知识库里只作为背景定义，不替代当前 ROI3 分析契约。

### 2.4 业务背景与代码主线的优先级

业务背景文档可以帮助理解“为什么会有 ROI3 / ROI4”，但不能直接替代线上真实语义。当前知识库采用以下优先级：

1. 代码里真实参与决策和执行的变量。
2. SQL / trace / 日志里真实可观测的字段。
3. 业务背景文档对这些变量的业务解释。

当文档与代码不完全一致时，以代码主线为准。

## 3. 锁定语义

下面这些约束是 ROI3 分析和报告必须遵守的基础语义：

1. `pcoc` 一律表示 `预测值 / 实际值`。
2. `uplift_*` 一律表示 `voucher - base`。
3. `pcr / pctr / pgmv` 分别属于不同层次，不能互相替代。
4. `ModelPgmv` 统一视为 click 空间的 `pgmv_0_clk`。
5. `BidRerankTrace.PgmvV` 统一视为 click 空间的 `pgmv_v_clk`。
6. `VoucherPgpm` 不是严格意义上的 `pgpm_v_imp`，它更接近 bid 公式回推 click-space value 的 transport 变量。
7. `voucher_price` 不是核销成本，`reward_discount -> Metric_VOUCHER_PRICE` 才更接近真实核销券成本链路。
8. ROI3 控制器只负责调节执行强度，不负责生成模型预测。
9. `校准` 不等于 `控制`；前者是模型值的后处理，后者是预算节奏调节。
10. AB 平台 group 桶、在线实验桶、运行时 `roi3_traffic_bucket` 不是同一个概念，不能直接混用。
11. ROI3 发券预算使用率的 truth 分子优先使用实验平台 `ads_voucher_cost`，`DailyVoucherPrice` 只是 controller 观测，不是最终权威真值。
12. ROI3 pacing usage 默认只统计真正参与 pacing 的算法桶；`base` 桶和 `random voucher treatment` 桶要单独展示，不能默认并入 pacing 使用率。
13. AB 平台 `Platformwide - Period` 取数时必须保留 `target_feature`、`is_ads` 和 filter-only `platform` 的正确切片；缺维度会导致重复聚合。
14. 但在 Q5 / Q8 这类“实验贡献”问题里，`656432 random voucher treatment` 必须并入 ROI3 算法贡献，因为它是 uplift 模型 RCT 数据收集的必要代价。
15. 总盘实验 uplift 默认用 `656430 + 656431` 做 base；截图对齐的单桶 uplift 默认用 normalized `656430` 做 base。
16. `gmv_995_v2` 的权威实验口径优先走 `Platformwide - Period`；不要把 `High GMV / Low GMV` 明细表直接全表求和。
17. `Platformwide - Period` 上 `gmv_995`、`ads_revenue_usd`、`advv_cost_1d` 的页面显示值可能与 API raw 不在同一尺度；做 uplift 时必须保证 base 和 treatment 用同一尺度。
18. 对广告达标方向的判断，ROI3 流量实验默认通过 `cost_ratio_1d = ads_revenue_usd / advv_cost_1d` 间接完成，而不是直接宣称看到了 hit rate 因果影响。
19. `cost_ratio_1d > 1` 表示偏超成本，`cost_ratio_1d < 1` 表示偏欠成本；目标是向 `1` 收敛。
20. 当 `cost_ratio_1d > 1` 时，如果 `rev uplift > advv uplift`，会把系统进一步推向超成本；当 `cost_ratio_1d < 1` 时，`rev uplift > advv uplift` 才可能是向目标修复。

## 4. 概念分层与基础速记

### 4.1 FAQ 对齐的基础概念

先锁死 4 组最容易混淆的基础概念：

1. 券类型要分在线候选类型和订单结算口径两层看

- 在线候选准备路径里，当前主链路区分：
  - 普通静态券
  - 满减 / threshold 券
  - dynamic voucher
- 这三类是候选准备阶段的互斥分支。
- 但订单结算口径不是严格互斥：
  - `ads_voucher_amt_usd`
  - `seller_voucher_amt_usd`
  - `platform_voucher_amt_usd`
  - `fsv_voucher_amt_usd`
- 其中 `seller_voucher_amt_usd` 明确包含 `ads_voucher_amt_usd`，所以不能把订单金额字段直接当成互斥券类型。

2. RCT reason 要区分 random treatment 和 base rewrite

- `17 = randomNoVoucher`
- `18 = randomVoucher`
- `19 = randomVoucherNotFound`
- `99 = randomVoucherFromBase`

统一理解：

- `17 / 18 / 19` 是随机流程本身的语义。
- `99` 不是新的业务原因，而是 base bucket 为了日志 / 样本识别做的改写。

3. base / random / 算法桶不是同一类角色

- `656430 / 656431`：base
- `656432`：random voucher treatment
- `656433 ~ 656440`：算法桶

统一理解：

- 问总盘 uplift 贡献时，`656432 ~ 656440` 可以并入 ROI3 treatment。
- 问 pacing usage / 控制命中时，默认只统计算法桶，base 和 random 要单列。

4. blacklist 表要区分“严格黑名单”和“blacklist / user-tag 结果表”

- `mkplpaidads_search_ads.ads_smart_voucher_blacklist_user` 当前更接近 blacklist / user-tag 混合结果表。
- 它适合回答：
  - 哪些 group 被用于解释“不发券”
  - 不同 group 的用户 / GMV 覆盖情况
- 它不应在没有额外语义确认的情况下，直接等同“严格禁止发券名单”。

### 4.2 FAQ 对齐的基础流程

从 FAQ 抽出来的最小 serving 主流程如下：

```text
request
  -> ab / config prepare
  -> 准备候选券（dynamic / 普通 / threshold 三选一）
  -> 候选公共过滤
  -> modelPrepare
  -> isUserValid
  -> isItemRoi3Valid
  -> isRoi3VoucherLimit
  -> isBudgetAvailable
  -> 对每张券计算 uplift / profit / ROI / eCPMV
  -> voucherSelector
  -> 回写 response / trace / full link
  -> posterior 聚合 spend / order / redeem
  -> ultra-core controller 输出 PID / budget / calibration 相关系数
```

如果问题只是在问“线上到底怎么走”，默认先按这条流程回答；如果再需要细节，再下钻到具体函数名。

### 4.3 FAQ 对齐的基础表

下面这组表是 FAQ 和总览都默认优先使用的基础表：

| 表 / 资产 | 角色 | 最常回答的问题 |
|---|---|---|
| `mp_paidads.dwd_ads_request_performance_di__reg_s0_live` | request 聚合 + `bid_rerank_trace` | request 侧 `voucher_unpicked_reason`、`roi3_traffic_bucket`、uplift 头 |
| `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` | click / impression 级 trace | 未发券原因、系数、动态券、模型分回放 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | ads truth performance | ads GMV、spend、曝光、广告活跃用户 |
| `mp_paidads.ads_order_voucher_1d__reg_s0_live` | order / redeem truth | ads voucher spend、订单侧券金额口径、折扣率 |
| `mp_voucher.dim_voucher__reg_live` | 券类型维表 | 判断 `ADS-ROI`、统一 voucher type |
| `mkplpaidads_search_ads.ads_smart_voucher_blacklist_user` | blacklist / user-tag 结果表 | group 覆盖、发券解释、用户 / GMV 占比 |
| `mkplpaidads_search_ads.ctr_uplift_model_rct_di` | 标准 RCT 分析表 | `17 / 18 / 99` 样本、RCT 概率和 uplift 分析 |
| `mkplpaidads_search_ads.dwd_uplift_click_conversion_hi` | click 主口径 DWD | `pcr_0 / pcr_02 / ... / pcr_20`、reason、bucket |
| `mkplpaidads_search_ads.dwd_uplift_conversion_arrive_hi` | arrive 口径 DWD | arrive 旁证和补充 |
| `mkplpaidads_search_ads.auto_budget_refresh` | 离线大盘预算表 | region/date 级 budget truth |
| `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live` | controller / PID trace | `DailyVoucherPrice`、PID、budget coef、controller 旁证 |

### 4.4 FAQ 对齐的关键字段

后续 agent 回答 ROI3 发券问题时，优先围绕下面这组字段组织：

响应 / 下游字段：

- `VoucherId`
- `VoucherUnpickedReason`
- `VoucherTrafficFlag`
- `VoucherPcrUpliftRatio`
- `VoucherPctrUpliftRatio`
- `DynamicVoucherPrice`
- `DynamicVoucherDiscount`
- `TargetCir`
- `BidRerankTrace`

trace / debug 核心字段：

- `voucher_price`
- `bid_voucher_id`
- `voucher_unpicked_reason`
- `voucher_unpicked_reason_base`
- `dynamic_voucher_price`
- `dynamic_voucher_discount`
- `roi3_traffic_bucket`
- `pctr_0 / pctr_v`
- `pcr_0 / pcr_v`
- `target_platform_spend_imps`
- `voucher_boost`
- `voucher_deduction`
- `bid_coef_arr`

base / RCT 特别字段：

- `VirtualVoucherPrice`
- `VoucherUnpickedReasonBase`

controller / budget 核心字段：

- `PidCoef`
- `Roi3PlatformBudgetCoef`
- `Roi3PlatformGmvCoef`
- `Roi3PlatformAdvvCoef`
- `PackageVoucherBudgetCoef`
- `package_budget`
- `package_request_id`
- `daily_voucher_spend`
- `pid_coef`

### 4.5 分层视角

ROI3 相关变量应按 5 层理解：

| 层级 | 主要文件 | 主要回答什么问题 |
|---|---|---|
| 模型层 | `online-bidding/.../rerank_uni_pgmv.go` | 模型原始 head 是什么，base `pcr / pctr / pgmv` 来自哪里 |
| 校准层 | `online-bidding/.../rerank_uni_pgmv.go` | raw head 是否切到 cali head，是否做 score ratio / cap / monotonicity |
| 策略层 | `rerank_voucher_rule.go`、`voucher_prepare.go`、`voucher_algorithm.go`、`voucher_selector.go` | 如何从模型公共字段推导最终的发券决策、券档位、boost / deduction |
| 控制层 | `ultra-core/.../roi3_cofund/voucher_pacing_control/*` | posterior spend 如何平滑，PID 如何打系数 |
| 观测层 | click/arrive/pCOC 聚合表、trace 表、order 表 | 日志和数仓里哪些值能直接拿到、哪些只能推导、哪些当前缺失 |

需要特别明确：

- `gmv_calibrator` 不放在本知识卡片的 ROI3 主校准层里。
- `rerank_dummy_voucher_rule.go` 不是当前策略主线。
- 旧 `internal/agent/product_ad_agent/roi3` 可以作为历史参考，但当前控制主线看 `roi3_cofund/voucher_pacing_control`。

### 4.6 与 uplift 专题知识库的分工

ROI3 总览和 uplift 专题库的职责边界如下：

| 主题 | 权威专题入口 | 本文保留的内容 |
|---|---|---|
| 业务目标 / Guardrail / 评估口径 | [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md) | ROI3 分析时必须锁死的目标函数和变量边界 |
| 模型架构 / 训练 / score 加工 | [`uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md) | 线上公共字段来自哪一层、如何进入策略链路 |
| 样本 / treatment-control / 1h label / RCT | [`uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md) | 在线 bucket、reason、可观测字段和分析限制 |
| uplift 特征 / 画像 / 覆盖率 | [`uplift-feature.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-feature.md) | 哪些字段在 ROI3 诊断里可直接拿、哪些只是 proxy |
| 逐券 Profit / ROI / Bid / Deduction / Cofund | [`uplift-voucher-strategy.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md) | 在线主链路、关键变量映射和约束 |
| 数据表 / SQL 入口 | [`uplift-data-tables.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-data-tables.md) | ROI3 报告与诊断脚本复用的最小数据契约 |

## 5. 在线主链路

### 5.1 总体流程

```text
request
  -> 模型层读取 raw head
  -> 校准层做 cali / ratio / cap / monotonicity
  -> 写公共字段（ModelPgmv / VoucherPcr0 / VoucherPctr0 / ...）
  -> 策略层准备候选券并计算 value/cost
  -> 选择最优券，写 VoucherPgpm / VoucherPcr / VoucherDeduction / trace
  -> posterior 聚合真实曝光/点击/下单/核销
  -> 控制层平滑 spend，输出 PidCoef / budget coef
```

### 5.2 模型层 / 校准层主链路

`rerank_uni_pgmv.go` 的主线可以压缩成 4 步：

1. 读取 raw head：
   - `direct_pgmv_7d`
   - `shop_pgmv_7d`
   - `pcr_0`
   - `uplift_ratio_*`
   - `uplift_pctr0`
   - `uplift_pctr_ratio*`
2. 做 head 级处理：
   - fallback
   - `cali_*_pgmv_7d_v2`
   - `UsePromCali`
   - `uniCRPgmvRatio`
   - score ratio / cap / monotonicity
3. 写公共字段：
   - `ModelPgmv`
   - `ModelPgpm`
   - `VoucherPcr0`
   - `VoucherCrUpRatio1..6`
   - `VoucherPctr0`
   - `VoucherPctrRatio1..6`
4. 落 trace / full link：
   - `BidRerankTrace.*`
   - `FullLinkLog.*`

当前有 5 条应在 ROI3 语义里直接锁死的模型事实：

1. 当前 uplift 主模型的固定抽象是“`uplift_pcr0` + 6 档 `uplift_ratio`”，方法族以 DragonNet + IPW + TMLE 为核心，而不是普通的单塔 CVR 预估；详见 [`uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md)。
2. 训练目标虽然为了兼容 CR 格式保留了 `direct_label_1d` 输出，但实际 uplift 训练依赖 multitask `[18:19]` 上的 `direct_order_1h`；详见 [`uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md)。
3. Treatment / Control 的根定义是 `voucher_price > 0` 与 `voucher_price == 0`，而 RCT 分析样本的关键 reason 仍是 `17 / 18 / 99`；这也是 ROI3 必须把 `656432` 看成“实验参考桶”而不是普通算法桶的原因之一。
4. 6 档折扣的主语义仍是 `2% / 5% / 8% / 12% / 15% / 20%`，在线配置和训练桶中心需要保持对齐；85 折档位偏移依然是已知风险。
5. CTR uplift 分数虽然可能被加载和处理，但只要 `Roi3EnableCtrUpliftRatio=false`，ROI3 线上发券主链路就仍然以 CVR uplift 为主；详见 [`uplift-voucher-strategy.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md)。

### 5.3 策略层主链路

`rerank_voucher_rule.go` 及其配套文件的主线，建议统一按 FAQ 里的函数级流程来理解：

1. `abTestConfigPrepare()`
2. 准备候选券：
   - `dynamicVoucherPrepare`
   - `voucherListPrepare`
   - `voucherListPrepareNew`
3. 做候选公共过滤：
   - `max CPA cap`
   - `DynamicVoucherCap`
   - `voucherPrice >= VoucherThresholdPrice`
   - `MaxDiscountThresholdNoVoucher`
4. `modelPrepare()` 将模型公共字段包装成策略可消费结构。
5. 进入 request / item gating：
   - `isUserValid`
   - `isItemRoi3Valid`
   - `isRoi3VoucherLimit`
   - `isBudgetAvailable`
6. 对每张候选券计算：
   - `calcUpliftCTR()`
   - `calcUpliftCR()`
   - `calcUpliftProfitAndROI()`
7. `voucherSelector()` 选择最终券；算法桶还会额外受以下过滤约束：
   - `cofund send flag`
   - `only seller adjust`
   - seller voucher threshold
   - `voucherDiscountDisableList`
8. 回写结果和 trace：
   - `BestVoucherID`
   - `BestVoucherPrice`
   - `DynamicVoucherPrice`
   - `DynamicVoucherDiscount`
   - `VoucherPgpm`
   - `VoucherPcr`
   - `VoucherDeduction`
   - `VirtualVoucherPrice`
   - `VoucherUnpickedReason`
   - `VoucherUnpickedReasonBase`
   - `BidRerankTrace.PgmvV`
   - `BidRerankTrace.Pctr_0 / PctrV / Pcr_0 / PcrV`

### 5.4 策略后处理

在规则执行顺序上，`RerankVoucherRulesNew` 位于：

- `rerank_bidding` 之后
- `rerank_subsidy` / `rerank_deduction` 之前

依次执行的关键规则是：

- `RerankVoucherRuleNewV2`
- `VoucherBidBoostRule`
- `VoucherDeboostRule`
- `VoucherAdsAddDedRule`

这意味着：

- `VoucherPgpm / VoucherPcr / VoucherDeduction` 先由 voucher 主策略生成。
- 后续规则再把这些量转成 boost / deboost / deduction 通道里的执行量。

### 5.5 控制层主链路

`voucher_pacing_control` 的逻辑可以压缩成 5 步：

1. 从 posterior 拉 order / clk / imp 三套指标。
2. 用 `CaliCoef` 做 clk -> order spend 校正。
3. 用 order / clk / imp 做平滑混合。
4. 根据 budget、CDF、smooth spend 计算 PID error。
5. 输出 `PidCoef`、`Roi3BudgetCoefArray`、`CofundBudgetCoefArray`。

最终必须锁死一个边界：

- 控制层调的是节奏和执行强度。
- 控制层不生成 `pcr / pctr / pgmv`。

## 6. 关键变量与公式

### 6.1 关键变量字典

| 概念 | 主变量 | 所属层 | 统一语义 | 常见误解 |
|---|---|---|---|---|
| base GMV（click） | `ModelPgmv` | 模型/校准层 | `pgmv_0_clk` | 误当成 imp 空间 GMV |
| base GMV（imp） | `ModelPgpm` | 模型/校准层 | `pgpm_0_imp` 的公共桥接字段 | 与 `ModelPgmv` 混用 |
| base PCR | `VoucherPcr0` | 模型/校准层 | 策略消费的 base PCR 公共字段 | 误当作 raw `pcr_0` 本身 |
| voucher PCR uplift ratio | `VoucherCrUpRatio1..6` | 校准层对外字段 | 发券相对不发券的 PCR ratio | 忽略了三维校准前后的差异 |
| base PCTR | `VoucherPctr0` | 模型/校准层 | 策略消费的 base PCTR | 与 tracking 原始字段混写 |
| voucher PCTR uplift ratio | `VoucherPctrRatio1..6` | 模型/校准层 | 发券相对不发券的 PCTR ratio | 与 PCR ratio 混用 |
| voucher GMV（click） | `BidRerankTrace.PgmvV` | 策略 trace | `pgmv_v_clk` | 误当成 imp 空间结果 |
| bid 桥接值 | `VoucherPgpm` | 策略层 | 供 bid 公式回推 click-space value 的 transport 变量 | 误当作严格 `pgpm_v_imp` |
| 最终券面额 | `voucher_price` / `BestVoucherPrice` | 策略层 | 最终选中的发券面额 | 误当成真实核销成本 |
| 核销券成本 | `reward_discount -> Metric_VOUCHER_PRICE` | 观测/控制层 | 最接近真实 redeem cost 的 posterior 链路 | 与 `voucher_price` 混用 |
| 广告主真实消耗 / 收入 | `CostUA` / `CostReal` | 观测层 | 广告主实际 cost / revenue 口径 | 误当作 voucher-only 成本 |
| ecpm delta | `VoucherBoost` / `VoucherDeboost` | 策略后处理 | boost/deboost 的 ecpm 调整量 | 误当成模型值或券成本 |
| deduction 通道 | `VoucherDeduction` / `AdditionalDeduction` | 策略后处理 | price deduction 参数通道 | 与 boost 通道混淆 |
| 控制系数 | `PidCoef` | 控制层 | 节奏调节系数 | 误当成模型校准系数 |

### 6.2 Click 空间与 Imp 空间

ROI3 里最容易混淆的是 `uplift_pgmv` 的空间定义。

click 空间：

- `pgmv_0_clk = ModelPgmv`
- `pgmv_v_clk = BidRerankTrace.PgmvV = ModelPgmv * crRatioUp`
- `uplift_pgmv_clk = pgmv_v_clk - pgmv_0_clk`

imp 空间的严格定义：

- `pgpm_0_imp = ctr0 * cr0 * item_price * avg_sold_cnt`
- `pgpm_v_imp = ctrV * crV * item_price * avg_sold_cnt`
- `uplift_pgmv_imp = pgpm_v_imp - pgpm_0_imp`

分析约束：

- click 空间不显式使用 PCTR uplift。
- imp 空间必须同时使用 PCTR uplift 和 PCR uplift。
- `VoucherPgpm` 不能直接拿来当 `pgpm_v_imp` 的真值。

### 6.3 关键公式与解释

`voucher_bid_boost_rule.go` 里 ROI3 bid 调整的核心表达可理解为：

- 非 cofund：
  - `adjustBid = VoucherPgpm / pctr * tCir * coef - VoucherPcr * VoucherPrice * order2Pay`
- cofund：
  - `adjustBid = VoucherPgpm / pctr * tCir * coef - VoucherPcr * VoucherPrice * order2Pay + targetPlatformSpendImps / pctr`

理解这条公式的关键在于：

- `VoucherPgpm / pctr`
  - 本质上更接近 click-space 的 voucher value。
- `VoucherPcr * VoucherPrice * order2Pay`
  - 更接近每 click 预期 voucher cost。

因此整个公式更接近 click-space value/cost 的比较，而不是单纯的 imp-space GMV 公式。

### 6.4 成本与收入口径

| 概念 | 推荐语义 | 说明 |
|---|---|---|
| `voucher_price` | 发出去的券面额 | 策略侧最终选中的券值 |
| `reward_discount` | 核销掉的券成本 | 在观测层更接近真实 redeem cost |
| `Metric_VOUCHER_PRICE` | posterior 聚合后的 order/redeem 侧券成本 | 控制层消费的真实成本口径 |
| `Metric_VOUCHER_SPEND_CLICK / IMP` | click / imp 侧的券消耗代理 | 不是最终核销口径 |
| `CostUA / CostReal` | 广告主实际消耗 / revenue | 券成本只是其中一部分 |

## 7. pCOC、可观测性与展示约束

### 7.1 正确的 pCOC 定义

统一定义：

- `pcoc = 预测值 / 实际值`

它衡量的是模型高估还是低估，不是 ROI，也不是单位成本。

推荐命名：

- `base_pcr_pcoc = pred_pcr_0 / actual_pcr_0`
- `uplift_pcr_pcoc = pred_uplift_pcr / actual_uplift_pcr`
- `base_pctr_pcoc = pred_pctr_0 / actual_pctr_0`
- `uplift_pctr_pcoc = pred_uplift_pctr / actual_uplift_pctr`
- `base_gmv_pcoc = pred_pgmv_0 / actual_base_gmv`
- `predict_uplift_gmv_pcoc_clk = pred_uplift_pgmv_clk / actual_uplift_gmv`
- `predict_uplift_gmv_pcoc_imp = pred_uplift_pgmv_imp / actual_uplift_gmv`

### 7.2 当前哪些量能直接拿

可以直接拿：

- `ModelPgmv`
- `ModelPgpm`
- `VoucherPcr0`
- `VoucherCrUpRatio1..6`
- `VoucherPctr0`
- `VoucherPctrRatio1..6`
- `voucher_price`
- `BidRerankTrace.PgmvV`
- `BidRerankTrace.Pctr_0 / PctrV / Pcr_0 / PcrV`
- `reward_discount`
- `Metric_VOUCHER_PRICE`
- `Metric_COST_UA`
- `Metric_COST_REAL`
- `PidCoef`

可以稳定推导：

- `uplift_pcr = pcr_v - pcr_0`
- `uplift_pctr = pctr_v - pctr_0`
- `uplift_pgmv_clk = pgmv_v_clk - pgmv_0_clk`
- `uplift_pgmv_imp = pgpm_v_imp - pgpm_0_imp`

当前不能假装直接拿到：

- 一个统一落盘的真实 `pgmv_v_imp`
- 一个统一的券成本模型预测字段
- 一个不带空间标签的“通用 uplift GMV pCOC”

### 7.3 展示约束

后续分析和报告至少要遵守这些限制：

1. 不要把 `VoucherPgpm` 写成“最终 imp-space voucher GMV”。
2. 不要把 `voucher_price`、`reward_discount`、`Metric_VOUCHER_PRICE`、`CostUA` 混成一个“券成本”。
3. 展示 `uplift_gmv_pcoc` 时必须显式标注 `clk` 或 `imp`。
4. 字段不够时要写 `missing`、`proxy` 或 `not_directly_observable`，不要硬凑成“像是真的指标”。

## 8. AB 桶语义与反事实约束

### 8.1 先区分 3 种桶

ROI3 相关分析里至少要分清：

- AB 平台 group 桶：
  - 例如 `656430`、`656436`
- 在线实验桶：
  - `Roi3ExpBucket`
- 运行时 trace 桶：
  - `roi3_traffic_bucket = voucherStrategyBucketId * 100 + voucherModelBucketId`

三者不能混用。

### 8.2 当前已确认的 `roi3_exp_v1` 桶语义

以下语义来自 `reference.md` / `concept_kb.md` 当前确认的 `exp_id = 164284`：

| bucket | 语义 | 分析约束 |
|---|---|---|
| `656430 / 656431` | 随机不发券 base 桶 | 真实 uplift 的主对照 |
| `656432` | random voucher treatment | 不能和算法选券桶混为一类；默认不并入 pacing usage |
| `656433 ~ 656440` | 算法选券桶 | `NoModelScoreNoVoucher = true` 的语义要单独理解 |

### 8.3 反事实与 uplift 的统一定义

`uplift_* = voucher - base`，但真实 base 无法逐样本直接观测，因此真实 uplift 必须依赖随机 no-voucher 桶：

- `actual_uplift_metric = actual_metric(treatment) - actual_metric(random_no_voucher_bucket)`

这意味着：

- 预测 uplift 可以在样本级推导。
- 真实 uplift 必须在 group-level 依赖随机对照桶。

### 8.4 发券预算使用率的标准口径

ROI3 预算使用率至少要分清 3 个概念：

- `truth_coupon_cost`
  - 来自实验平台 `roi3_exp_v1` 的 `ads_voucher_cost`
  - 是预算使用率结论的权威分子
- `controller_spend`
  - 来自 HyperX trace 的 `DailyVoucherPrice`
  - 用来解释 controller 认为自己花了多少
- `pacing_target`
  - 来自 HyperX trace 的 `coalesce(AdjustBudget, DailyBudget)`
  - 小时级累计目标需要再乘 `CDF`

默认主口径：

- `truth_budget_usage = SUM(truth_coupon_cost on pacing buckets) / SUM(pacing_target on pacing buckets)`
- `controller_budget_usage = SUM(controller_spend on pacing buckets) / SUM(pacing_target on pacing buckets)`

这里的 `pacing buckets` 在当前 `roi3_exp_v1` 语义下指：

- 实验桶：`656433 ~ 656440`
- trace 桶：`voucherStrategyBucketId = 2 ~ 9`

明确不默认并入：

- `656430 / 656431`
  - 随机不发券 base 桶
- `656432`
  - random voucher treatment

如果要看随机券 treatment，本质上是在看实验参考桶，不是在看 pacing execution。

### 8.5 实验平台取数的标准切片

当前 ROI3 发券预算 usage 的实验平台权威来源是：

- 模板：
  `One Page - Paid Ads A/B Test`
- tab：
  `Platformwide - Period`
- metric：
  `ads_voucher_cost`

正确切片必须满足：

- `target_feature = ALL`
- `is_ads = all`
- `platform = all`

并且要保留模板要求的维度语义：

- `abtest_group`
  - 看总盘 / 分桶
- `abtest_region + abtest_group`
  - 看分国家

这里有两个高频坑：

1. 不能只按 `abtest_group` 或 `abtest_region + abtest_group` 取数然后直接求和，如果漏掉 `target_feature / is_ads / platform`，会把同一批 cost 重复聚合。
2. `is_ads = all` 已经是聚合总量，不能再和 `is_ads = true / false` 继续相加。

### 8.6 本次排查暴露的高频错误

这次 `2026-04-18` 的复盘说明，ROI3 预算 usage 最容易错在下面 4 个地方：

1. 把广告预算和发券预算混为一谈。
2. 把 `plan_bucket_id`、AB group bucket、`roi3_traffic_bucket` 混为同一个“桶”。
3. 把 `656432 random voucher treatment` 并进 pacing usage，导致国家 usage 被严重拉低。
4. 用 7 国加权后的桶 usage 去解释单个国家，忽略了大国家权重主导的问题。

### 8.7 2026-04-18 复盘样例

`2026-04-18` 这天，如果把 `656432 random voucher treatment` 错并入 pacing usage：

- 7 国总 truth usage 会被算成 `76.18%`

但按正确口径只统计 pacing 算法桶 `656433 ~ 656440`：

- 7 国总 truth usage 是 `98.19%`

两者的差异几乎完全来自 `656432` 被误并入了分子和分母，其中分母在 trace 里呈现为每个国家固定 `100000` 的占位型 budget。这个现象说明：

- 随机券 treatment 桶可以作为实验参考桶展示
- 但不能默认视为 pacing target 的一部分

### 8.8 Q5 / Q8 的实验平台回答契约

当前 ROI3 里，下面两类问题都应优先用实验平台回答，而不是回退到 proxy SQL：

- Q5：
  `local_new_pc2`、`gmv`、`gmv_995_v2`
- Q8：
  `ads_revenue_usd`、`advv_cost_1d`、`ads_voucher_cost`

**标准实验设置**

- 实验：
  `roi3_exp_v1 (164284)`
- 总盘趋势：
  - `ROI3 = 656432 ~ 656440`
  - `base = 656430 + 656431`
- 分桶截图：
  - `control = 656430`
  - `treatments = 656432 ~ 656440`

**标准公式**

- 总盘 uplift：
  - `base_cf = 9 x (base_0 + base_1)`
  - `uplift_abs = roi3_actual - base_cf`
  - `uplift_rel = uplift_abs / base_cf`
- 单 bucket uplift：
  - `bucket_base_cf = 2 x base_0`
  - `bucket_uplift_abs = bucket_actual - bucket_base_cf`
  - `bucket_uplift_rel = bucket_uplift_abs / |bucket_base_cf|`
- guardrail：
  - `guardrail = uplift_gmv / 4 + uplift_advv - voucher_cost`
  - 目标应为正

**推荐 tab**

- `Platformwide - Daily`
  - 最近一周日趋势
  - `local_new_pc2` / `gmv` / `ads_revenue_usd` / `advv_cost_1d` / `ads_voucher_cost`
- `Platformwide - Period`
  - `gmv_995_v2`
  - 截图对齐
  - 单日分桶明细

**补充说明**

- 这些指标的实验平台字段说明见 `§8.10`。
- 如果问题追到 `pc2` 的层级定义，优先回 `§8.11`，不要把 `local_new_pc2` 直接当作 `True PC2`。

**必须废弃的旧答法**

1. 不要把 Q5 默认答成 item/shop JOIN 的 proxy attributed contribution。
2. 不要把 Q8 默认答成 `pricing_type = 18` 的收入聚合。
3. 不要把 `High GMV / Low GMV` 的明细切片直接全表求和代替总盘。
4. 不要混用页面显示值和 API raw 再去算 uplift。

### 8.9 Q10 的实验平台回答契约

Q10 问的是“ROI3 对广告达标方向的影响，以及是否导致超成本 / 欠成本”。在当前 ROI3 语义下：

- 这是流量实验。
- 不能直接把实验结果写成“达标率已被因果证明提升/下降”。
- 应优先通过 `cost_ratio_1d` 间接判断 ROI3 是否把系统推向超成本或欠成本。

**标准指标**

- `cost_ratio_1d = ads_revenue_usd / advv_cost_1d`
- `ads_revenue_usd`
- `advv_cost_1d`
- `platform_达标rev%`
  - 只可作为辅助 proxy
  - 不可替代 `cost_ratio_1d` 成为主结论

**方向定义**

- `cost_ratio_1d > 1`
  - 偏超成本
- `cost_ratio_1d < 1`
  - 偏欠成本
- 目标：
  - 向 `1` 收敛

**判断规则**

1. 如果当前 `cost_ratio_1d > 1`：
   - `rev uplift > advv uplift` 会继续推高超成本。
   - 更健康的方向应是 `advv uplift >= rev uplift`。
2. 如果当前 `cost_ratio_1d < 1`：
   - 可以接受 `rev uplift > advv uplift`，因为是在向 `1` 修复。
3. 如果 `cost_ratio_1d` 已接近 `1`：
   - `rev` 和 `advv` 的增速应尽量接近。

**推荐 tab**

- `Platformwide - Daily`
  - 最近一周趋势
  - `cost_ratio_1d`
  - `ads_revenue_usd`
  - `advv_cost_1d`
- `Rollout Checklist`
  - `platform_达标rev%`
  - 仅作辅助解释

**必须废弃的旧答法**

1. 不要把 Q10 默认答成 `hit_rate = campaign_hit_cnt / (hit + waste)`。
2. 不要把流量实验结果直接写成“达标率已被证明改善/恶化”。
3. 不要把 `cost_ratio > 1` 和 `cost_ratio < 1` 的超/欠成本方向写反。

### 8.10 实验平台 Metric 词典

下面这组说明用于解释 ROI3 实验平台常见 metric 的页面含义和聚合公式。默认语境是：

- 模板：
  `One Page - Paid Ads A/B Test`
- 实验：
  `roi3_exp_v1`
- 聚合：
  下面公式默认按页面维度先聚合后计算；做 uplift 时必须保证 base 和 treatment 使用同一尺度。

**页面常见 alias**

| 原始 metric id | 页面常见名称 | 说明 |
|---|---|---|
| `revenue_usd` | `ads_revenue_usd` | 广告收入 |
| `gmv_usd` | `gmv` | 广告直接归因 GMV |
| `padvv_cost_7d` | `padvv_cost` | 预测 advertising value |

**核心业务与 ROI**

| Metric | Elaboration | Calculation |
|---|---|---|
| `revenue_usd` | Ads revenue | `sum(revenue_usd)` |
| `Narrow ROI` | Considers GMV from ads directly against revenue | `sum(ads_gmv) / sum(revenue_usd)` |
| `gmv_usd` | Gross merchandising value; value of items sold | `sum(ads_gmv)` |
| `Broad ROI` | Considers broad GMV against revenue | `sum(broad_gmv_usd) / sum(revenue_usd)` |
| `broad_gmv_usd` | Considers GMV from purchase of other listings, not only ad listing, with ad as entry point | `sum(broad_gmv_usd)` |
| `take_rate` | The percentage of total GMV that platform can collect as revenue | `sum(revenue_usd) / sum(plt_gmv)` |
| `revenue_pct` | Revenue of ads type against total feature group revenue | `sum(revenue_usd) / sum(total_revenue_usd)` |

**成本 / Value / Guardrail 相关**

| Metric | Elaboration | Calculation |
|---|---|---|
| `advv_cost_1d` | Advertising value of cost; estimated advertising costs from sellers, calculated based on clicks and GMV generated on the same day | `sum(advv_cost)` |
| `cost_ratio_1d` | Compare actual ad revenue against estimated ad revenue | `sum(revenue_usd) / sum(advv_cost)` |
| `advv_cost_7d` | Advertising value of cost; estimated advertising costs from sellers, calculated based on GMV generated on that day no matter when click happens | `sum(advv_cost_7d)` |
| `cost_ratio_7d` | Compare actual ad revenue against estimated ad revenue | `sum(revenue_usd) / sum(advv_cost_7d)` |
| `padvv_cost_7d` | Predicted advertising value; can check reference doc for detailed calculation logic | `sum(padvv_cost)` |
| `advv_gmv` | Advertising value of GMV; estimated advertising GMV from sellers | `sum(advv_gmv)` |
| `gmv_ratio` | Compare actual GMV against estimated GMV | `sum(gmv_for_ratio) / sum(advv_gmv)` |
| `advv_cost_1d_excl_outlier` | `advv_cost_1d` excluding those whose target CIR `> 50` | `sum(advv_cost_excl_outlier)` |
| `cost_ratio_1d_excl_outlier` | `cost_ratio_1d` excluding those whose target CIR `> 50` | `sum(revenue_usd) / sum(advv_cost_excl_outlier)` |

**流量 / 转化 / 位置类**

| Metric | Elaboration | Calculation |
|---|---|---|
| `ads_load` | Ads impression against total impression in omni OA | `sum(ads_imp_cnt) / sum(total_imp_cnt)` |
| `CPM` | Cost per ad impression | `1000 * sum(revenue_usd) / sum(ads_imp_cnt)` |
| `CPC` | Cost per ad click | `sum(revenue_usd) / sum(ads_click_cnt)` |
| `CPA` | Cost per ad order | `sum(revenue_usd) / sum(ads_order_cnt)` |
| `order_per_uu(*100)` | Order per impression user | `sum(ads_order_cnt) / sum(ads_imp_uu) * 100` |
| `gmv_per_uu` | GMV per impression user | `sum(ads_gmv) / sum(ads_imp_uu)` |
| `avg_imp_location` | Average impression location | `sum(ads_total_location) / sum(ads_imp_cnt)` |
| `top20_avg_imp_location` | Average impression location among top 20 location | `sum(top20_ads_location) / sum(top20_ads_imp_cnt)` |
| `gmv_per_order` | GMV per order | `sum(ads_gmv) / sum(ads_order_cnt)` |
| `imp_per_uu` | Impression per impression user | `sum(ads_imp_cnt) / sum(ads_imp_uu)` |
| `click_per_uu` | Click per impression user | `sum(ads_click_cnt) / sum(ads_imp_uu)` |
| `click_CTR` | Click through rate; ads click against impression | `sum(ads_click_cnt) / sum(ads_imp_cnt)` |
| `click_CR` | Click conversion rate; ads order against click | `sum(ads_order_cnt) / sum(ads_click_cnt)` |
| `CTR_CR` | Ads order against impression | `sum(ads_order_cnt) / sum(ads_imp_cnt)` |
| `uu_click_ctr` | Among all impression UU, the percentage of users that have clicked | `sum(ads_click_uu) / sum(ads_imp_uu)` |
| `uu_ctr_cr` | Among all impression UU, the percentage of users that have placed orders | `sum(ads_order_uu) / sum(ads_imp_uu)` |
| `imp_cnt` | Impression count | `sum(ads_imp_cnt)` |
| `click_cnt` | Click count | `sum(ads_click_cnt)` |
| `order_cnt` | Order count | `sum(ads_order_cnt)` |
| `imp_uu` | Impression user count | `sum(ads_imp_uu)` |
| `click_uu` | Click user count | `sum(ads_click_uu)` |
| `order_uu` | Order user count | `sum(ads_order_uu)` |

**出价 / 模型质量类**

| Metric | Elaboration | Calculation |
|---|---|---|
| `deduction_bid_ratio` | Compare deduction price against bid price | `sum(sum_deduction_price_usd) / sum(sum_bid_price_usd)` |
| `avg_deduction_price_usd` | Deduction price refers to actual post-discounted bid price | `sum(sum_deduction_price_usd) / sum(cnt_deduction_price)` |
| `avg_bid_price_usd` | Actual bid price | `sum(sum_bid_price_usd) / sum(cnt_bid_price)` |
| `ctr_pcoc` | Accuracy of the model prediction of CTR | `sum(case when imp_cnt > 0 then pctr else 0 end) / sum(imp_cnt)` |
| `cr_pcoc` | Accuracy of the model prediction of CR | `sum(case when click_cnt > 0 then pcr else 0 end) / sum(click_cnt)` |

**使用边界**

- `cost_ratio_1d` / `cost_ratio_7d` 的本质都是 `revenue / advv_cost`，区别在 estimated cost 的归因窗口。
- `Narrow ROI` / `Broad ROI` / `take_rate` 不能混作同一类指标；它们分别回答“直接广告 ROI”“入口扩展 ROI”“平台抽成效率”。
- `gmv_usd` / `broad_gmv_usd` / `advv_gmv` 也不是同一层：一个是实际广告 GMV，一个是 broad entry GMV，一个是 seller-side estimated GMV。
- 页面展示值和 API raw 可能存在固定缩放差异；同一次 uplift 计算里不要混用两种尺度。

### 8.11 实验平台 PC2 四层口径

当前实验平台和跨团队资料里，`pc2` 常见有 4 层语义：

| Name | Usage | Definition | Calculation Logic | Granularity | Data source |
|---|---|---|---|---|---|
| `Local PC2 (Existing)` | Used to adjust item traffic weight; items/category with higher PC2 will be allocated more traffic | Confirmed by the local team; it is a fixed rate | `gmv * pc2_rate` where `pc2_rate` is provided by local | `item_id`; can be broken down by business line / feature | Gsheet updated by Ops Team |
| `Proxy PC2 (NEW)` | Algo-controllable portion, used to evaluate the effectiveness of algorithm adjustments | Does not consider `3PL / transaction fee` | `Proxy PC2 = MP Revenue - PRM excl. 3PL Margin = Mandatory Commissions + Optional Commissions + Handling Fees + Paid Ads Rev - Paid Ads Voucher Amt (ROI3 + ROI4 only)` | `user_id x item_id`; can be broken down by business line / feature | CM order-item table, Ads Rev table, Ads Voucher table co-fund |
| `Adjusted Proxy PC2 (NEW)` | Based on `Proxy PC2`, simulates `Local PC2` so that the algo-controllable portion aligns more closely with local expectation | `Proxy PC2` adjusted by local PC2 expectation | `Adjusted Proxy PC2 % = item proxy pc2% * category local pc2% / category proxy pc2%`; `Adjusted Proxy PC2 = omni_gmv * Adjusted Proxy PC2 %` | `user_id x item_id`; can be broken down by business line / feature | Omni PC2 table `Local PC2`, CM order-item table, Ads Rev table, Ads Voucher table co-fund |
| `True PC2 (NEW)` | Actual PC2, including all constituent components | Actual PC2 including all components | `True PC2 = MP Revenue - PRM excl. 3PL Margin - RSF / RTS + 3PL - Gross Transaction Fee` | `user_id`; cannot be broken down by business line / feature | CM order-item table, CM daily table, Ads Rev table, Ads Voucher table co-fund |

补充说明：

- `True PC2` 的背景说明可参考 [PC 2](https://confluence.shopee.io/display/SPV/PC+2)。
- 当前 ROI3 实验平台里最常被直接拿来回答趋势问题的字段仍是 `local_new_pc2`，但它默认只应视为实验平台字段名，不要自动等同于 `True PC2`。
- 如果用户追问某个 dashboard / SQL / API 里的 `pc2` 到底对应哪一层，必须先锁定它是 `Local / Proxy / Adjusted Proxy / True` 哪一层，再回答。

## 9. SQL 数据契约与观测映射

### 9.1 主要表与用途

| 表 / 资产 | 主要用途 | 对应知识层 |
|---|---|---|
| AB 平台 `roi3_exp_v1` / `Platformwide - Daily` | `local_new_pc2` / `gmv` / `ads_revenue_usd` / `advv_cost_1d` / `ads_voucher_cost` 的日级实验趋势 | 观测、实验 |
| AB 平台 `roi3_exp_v1` / `Platformwide - Period` | `gmv_995_v2`、截图对齐明细、group / region 维度切片 | 观测、实验 |
| `mp_paidads.dwd_ads_request_performance_di__reg_s0_live` | request 聚合 + request trace | 观测、实验、策略解释 |
| `mkplpaidads_search_ads.dwd_uplift_click_conversion_hi` | click 主口径的模型/策略/核销观测 | 模型、策略、观测 |
| `mkplpaidads_search_ads.dwd_uplift_conversion_arrive_hi` | arrive 口径旁证 | 观测 |
| `mkplpaidads_search_ads.cr_uplift_model_rct_pcoc*` | PCR uplift / pCOC 聚合 | 观测、分析 |
| `mkplpaidads_search_ads.ctr_uplift_model_rct_di` | CTR uplift 相关聚合输入 | 观测、分析 |
| `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live` | pacing / PID / budget / spend trace | 控制 |
| `mp_paidads.ads_order_voucher_1d__reg_s0_live` | order / redeem 侧券成本真值 | 观测 |
| `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` | 模型分、系数、未发券原因、动态券面额 | 策略解释 |
| `mp_voucher.dim_voucher__reg_live` | 统一 voucher type / 判断 `ADS-ROI` | 券类型解释 |
| `mkplpaidads_search_ads.ads_smart_voucher_blacklist_user` | blacklist / user-tag 解释表 | 用户侧解释 |
| `mkplpaidads_search_ads.auto_budget_refresh` | 离线 budget truth | 控制、预算 |

### 9.2 概念到 SQL 的最小映射

| 概念 | 代码变量 | SQL / 日志落点 | 典型用途 |
|---|---|---|---|
| `base_pcr` | `VoucherPcr0` | click 表 `pcr_0` | Level3 回放与 reason analysis |
| `voucher_pcr` | `VoucherPcr` | click 表 `pcr_v` | voucher 后效果分析 |
| `uplift_pcr` | `pcr_v - pcr_0` | click 表 + `cr_uplift_*` 聚合表 | Level1 / 2 诊断 |
| `base_pctr` | `VoucherPctr0` | tracking / `ctr_uplift_model_rct_di` | CTR 侧校验 |
| `pgmv_0_clk` | `ModelPgmv` | tracking / full-click 重建 | Level3 replay |
| `pgmv_v_clk` | `BidRerankTrace.PgmvV` | full-click tracking 路径 | Level3 replay |
| `voucher_price` | `BestVoucherPrice` | click 表 `voucher_price` / tracking `dynamic_voucher_price` | 折扣档位分析 |
| `voucher_id` | `BestVoucherID` | trace `bid_voucher_id` / 响应 `VoucherId` | 下游感知最终发券结果 |
| `voucher_reason` | `VoucherUnpickedReason` | request / click / tracking `voucher_unpicked_reason` | reason analysis / RCT 取样 |
| `base_reason` | `VoucherUnpickedReasonBase` | trace `voucher_unpicked_reason_base` | base 组过滤原因排查 |
| `virtual_voucher_price` | `VirtualVoucherPrice` | trace `virtual_voucher_price` | base 组“本应随机发的券额” |
| `roi3_bucket` | `roi3_traffic_bucket` | click / arrive / request 相关表 | bucket slicing / base vs treatment 分流 |
| `redeemed_voucher_cost` | `reward_discount -> Metric_VOUCHER_PRICE` | order 表 / click 表 `reward_discount` | spend truth / redeem gap |
| `truth_coupon_cost` | `ads_voucher_cost` | AB 平台 `roi3_exp_v1` report | 预算使用率权威 truth |
| `controller_spend` | `DailyVoucherPrice*`、`DailyPlatformSpend*` | HyperX trace | Level2 pacing 解释 |
| `controller_coef` | `PidCoef`、`roi3_budget_coef`、`cofund_budget_coef` | HyperX trace / `output_param.extra` | 控制异常定位 |
| `package_budget` | `PackageBudget` | ultra-core trace `package_budget` / `package_request_id` | package 预算排查 |

### 9.3 SQL 使用原则

1. click 表是主口径，arrive 表只作为旁证。
2. pCOC / AUUC 这类技术指标优先使用聚合表，不要在报告里现场重造定义。
3. trace 表负责解释“控制器怎么调”，不是用来替代模型 / 策略字段。
4. order 表的价值在于提醒我们“发出去的券面额”和“最终核销掉的券成本”不是一回事。
5. 发券预算使用率结论优先以 AB 平台 `ads_voucher_cost` 为准，trace 侧 `DailyVoucherPrice` 只能作为 controller 旁证。
6. `Platformwide - Period` 必须保留 `target_feature = ALL`、`is_ads = all`、`platform = all` 这组切片，否则极易重复聚合。
7. 做 pacing usage 聚合时，先明确桶集合；当前 `roi3_exp_v1` 默认只统计算法桶 `656433 ~ 656440`。
8. 做 Q5 / Q8 总盘 uplift 时，默认 `ROI3 = 656432 ~ 656440`，`base = 656430 + 656431`。
9. 做截图对齐的单桶 uplift 时，默认比较对象是 normalized `656430`，不是 `656430 + 656431`。
10. `gmv_995_v2` 优先从 `Platformwide - Period` 读取，不要把 `High GMV / Low GMV` 的额外切片直接相加。
11. `gmv_995`、`ads_revenue_usd`、`advv_cost_1d` 如果用页面展示值回答，就要全程使用页面展示尺度；如果用 API raw，则 base 和 treatment 都必须留在 API raw 尺度。
12. 回答 Q10 时，`cost_ratio_1d` 是主口径；`platform_达标rev%` 只能辅助解释，不能替代主判断。
13. 如果当前 `cost_ratio_1d > 1`，看到 `rev uplift > advv uplift` 应判断为更偏超成本；如果当前 `cost_ratio_1d < 1`，才可判断为向目标修复。
14. 知识库中出现的历史排查数值只用于说明统计口径和方法，不能直接视为当前 truth；后续类似问题必须按同一方法重新跑数。

## 10. Level1 / Level2 / Level3 分析框架

### 10.1 三层主链路

| Level | 关注问题 | 主要证据 | 典型输出 |
|---|---|---|---|
| Level1 | 全天看发券是否换来更好的业务结果和平台结果 | 天级业务指标 + pCOC / AUUC + spend truth | `level1_metrics.json`、`level1_report.md` |
| Level2 | 分小时看效果和执行在哪些小时偏离 | 小时业务指标 + trace control + hourly uplift monitor | `level2_metrics.json`、`level2_report.md` |
| Level3 | 看当前策略相对更优发券决策还有多少空间 | click replay + reason/score + redeem gap | `level3_metrics.json`、`level3_report.md` |

### 10.2 当前 sidecar diagnostics

根据 `reference.md`，当前诊断侧车默认包括：

- Level1 diagnostics
  - `rct_quality`
  - `spend_truth`
  - `arrive_quality`（仅 deep）
- Level2 diagnostics
  - `trace_control`
  - `hourly_uplift_monitor`
- Level3 diagnostics
  - `coverage_alignment`
  - `reason_and_score`
  - `redeem_gap`（仅 deep）

### 10.3 顶层使用原则

以后 report 里每个技术指标，至少要能回答这 4 个问题：

1. 它属于哪一层：模型、校准、策略、控制还是观测。
2. 它在代码里由哪个文件、哪个变量计算出来。
3. 它在 SQL / 日志里落到哪张表、哪个字段。
4. 它在离线分析里由哪个脚本 / 产物消费。

如果这 4 个问题答不出来，那个指标不应该直接进最终报告。

## 11. 代码与逻辑位置

本节中的路径是相关源码仓库内的相对路径标识，用来帮助定位逻辑归属，不是当前文档仓库内的可点击文件链接。

### 11.1 模型 / 校准层

- `code/online-bidding/online-bidding/internal/rule/productads/rerank/model/rerank_uni_pgmv.go`

### 11.2 策略层

- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_prepare.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_algorithm.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_selector.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_bid_boost_rule.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_deboost_rule.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_deduction.go`
- `code/online-bidding/online-bidding/internal/rule/productads/rerank/voucher/voucher_ads_add_ded_rule.go`

### 11.3 控制层

- `code/ultra-core/ultrav-core/internal/agent/product_ad_agent/roi3_cofund/voucher_pacing_control/context.go`
- `code/ultra-core/ultrav-core/internal/agent/product_ad_agent/roi3_cofund/voucher_pacing_control/data.go`
- `code/ultra-core/ultrav-core/internal/agent/product_ad_agent/roi3_cofund/voucher_pacing_control/strategy.go`
- `code/ultra-core/ultrav-core/internal/agent/product_ad_agent/roi3_cofund/voucher_pacing_control/trace.go`

### 11.4 观测 / SQL 资产名

本节只保留工作底稿里使用过的 SQL 资产名和用途说明，不保留个人本地目录或不可复用的绝对路径。

- `11220298__dwd_uplift_click_conversion_hi.sql`
  - click 主口径明细
- `11250032__dwd_uplift_conversion_arrive_hi.sql`
  - arrive 口径明细
- `10711383__cr_uplift_model_rct_pcoc.sql`
  - PCR uplift / pCOC 日级聚合
- `10899626__cr_uplift_model_rct_pcoc_by_hour.sql`
  - PCR uplift / pCOC 小时聚合
- `10716972__ctr_uplift_model_rct_di.sql`
  - CTR uplift 相关聚合输入
- `coef_log.sql`
  - 控制链 trace 提取
- `voucher_spend.sql`
  - order / redeem spend 校验
- `model_score_coef.sql`
  - 模型分与系数解释
- `unpicked_reason.sql`
  - 未发券原因解释
- `discount.sql`
  - 券面额与折扣分布解释

## 12. ROI3 / Uplift 常见问答（参考回答与取证路径）

本节专门回答 ROI3 / uplift 讨论里最容易被问到、但也最容易被过度简化的问题。

使用约束先锁死 3 条：

1. 下面内容默认是“参考回答”，不是脱离上下文可复用到所有场景的标准答案。
2. 回答时应优先说明“当前是按哪个视角、哪个口径、哪份证据”在答。
3. 如果文档、代码、实验平台三者不一致，优先回到“当前线上链路 + 当前实验口径”重新取证，不要机械复读旧卡片。

本节按原始提问序号保留 Q1 ~ Q10；如果后续新增问题，继续按原始提问号扩展。

### 12.1 Q1 满减券和折扣券是 2 套券么

**参考回答**

建议不要直接回答成“是”或“不是”，而是先声明分层视角。

- 平台整体视角：
  先按 `PV / SV / FSV` 回答。
  - `PV = platform voucher`
  - `SV = seller voucher`
  - `FSV = free shipping voucher`
- 广告券视角：
  广告券属于 `SV` 体系中的一种。
- 广告发券策略视角：
  建议再拆成 `静态券 / 动态券`；
  动态券继续拆 `折扣券 / 满减券`；
  再继续拆 `单品券 / 店铺券`。

所以，这题更稳的参考回答是：

- 从平台结算 / 资产分类看，不能简单说“满减券和折扣券就是两套券体系”。
- 从广告动态券策略视角看，`满减券` 和 `折扣券` 是动态券内部的两种属性分支。

**优先怎么取证**

- 先查平台 / 结算侧分类：
  [`uplift-data-tables.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-data-tables.md)
  看 `platform_voucher_amt_usd`、`seller_voucher_amt_usd`、`shipping_seller_voucher_amt_usd` 等字段语义。
- 再查广告在线候选准备与过滤：
  [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)
  重点看券候选准备、券类型、候选过滤相关问答。
- 如果要确认“动态券内部的折扣 / 满减 / 单品 / 店铺”在当前线上到底如何落：
  回到代码路径
  - `rerank_voucher_rule.go`
  - `voucher_prepare.go`
  - `voucher_algorithm.go`
  再结合 `mp_voucher.dim_voucher__reg_live` 看最终券维表属性。

**回答边界**

- 这题最容易把“平台券分类”和“广告选券分支”混成一层。
- 如果问的是“谁出钱”，要单独补一层资助视角，不能拿 `SV` 的券类型分类直接替代出资方判断。
- 如果问的是“是否互斥”，要说明在线候选分支、订单侧金额字段、维表属性三层不一定完全一一互斥。

### 12.2 Q2 券消耗和 gmvUplift 是线性关系么

**参考回答**

建议默认拆成两个视角回答，而且默认结论都不要写成“固定线性关系”。

- 算法视角：
  关注的是在线选券 / bidding 里“预估券消耗”和“预估 GMV uplift”之间的公式关系。
  当前更稳的说法是：
  两者共享同一套 `ctr / cr / itemPrice / avgSoldCnt / voucherPrice / spendCoef` 等中间量，但不是一个固定常数比例的线性关系。
- 业务视角：
  关注的是实际实验结果里的 `gmv_995_v2 / rev / advv / ads_voucher_cost`。
  当前更稳的说法是：
  业务上要分别看 `gmv_v2`、`rev`、`advv` 和 `voucher cost` 的 uplift，不要把它压成“券成本和 GMV 增量线性对应”。

**优先怎么取证**

- 算法视角先看：
  [`uplift-voucher-strategy.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md)
  和 [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
  重点找 `upliftGmvImp`、`voucherSpend`、`Profit`、`ROI` 的公式链。
- 如果要确认当前线上实现是否有额外 cap / coef / 插值：
  回到代码
  - `rerank_uni_pgmv.go`
  - `voucher_algorithm.go`
  - `voucher_selector.go`
- 业务视角先看实验平台：
  `roi3_exp_v1`
  - `gmv_995_v2`
  - `ads_revenue_usd`
  - `advv_cost_1d`
  - `ads_voucher_cost`
- 如果问的是上线保护逻辑，再单独补 Guardrail：
  `guardrail = gmv / 4 + advv - voucher_cost`

**回答边界**

- 回答前必须先锁定“券消耗”指的是预估 spend 还是真实核销成本。
- 也必须先锁定“gmvUplift”指的是模型预估 uplift、实验平台 uplift，还是某个 SQL proxy uplift。
- 如果用户没有指明视角，默认先拆成“算法视角 / 业务视角”再答。

### 12.3 Q3 `platform_gmv_v2` / `platform_gmv` 是什么

**参考回答**

建议默认先拆成两个语境回答，不要把“数仓字段定义”和“ROI3 实验指标口径”混成一层。

- Take Rate / 数仓字段语境：
  `platform_gmv_v2` 通常是在说 Take Rate v2 相关表里的 `platform_gmv` 口径，不是一个完全独立的新业务概念。
  更稳的说法是：
  它本质上是订单侧的平台 GMV 字段，用于表示平台商品交易总额，常作为 Take Rate 分母。
- ROI3 / 实验平台语境：
  如果问题上下文已经切到 ROI3、发券实验、`roi3_exp_v1` 或 Guardrail，
  更稳的说法是：
  当前讨论的 `platform_gmv` 指向 ROI3 的平台 GMV 指标，是 ROI3 / Guardrail 主结果链路的一部分，不能再直接等同于广告侧 `broad_gmv` 或任意 SQL proxy GMV。

合并两边语义后的标准回答可以写成：

- `platform_gmv_v2` / `platform_gmv` 的底层本义是“平台 GMV”。
- 在数仓和 Take Rate 语境里，它更接近订单侧平台 GMV 字段。
- 在 ROI3 实验语境里，它又会表现为实验平台上的平台 GMV 指标，但具体 tab、窗口、归因规则不在这张主定义卡里写死，应按当次实验页面和口径说明补充。

**优先怎么取证**

- 字段定义 / 数仓侧先看：
  [`mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live/column_info.md`](../../datamap/mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live/column_info.md)
  和
  [`mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live/sql_patterns.md`](../../datamap/mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live/sql_patterns.md)
- ROI3 / 实验口径先看：
  [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
  重点看 `platform_gmv`、`gmv_uplift`、Guardrail 的实验口径说明。
- 如果要补 Confluence 证据：
  - [Take Rate DataSet](https://confluence.shopee.io/display/SPAD/Take+Rate+DataSet)
  - [24Q4 ROI3 Voucher](https://confluence.shopee.io/display/SPAD/24Q4+ROI3+Voucher)

**回答边界**

- 回答前必须先锁定用户问的是“字段定义”、`AB` 实验指标，还是某个 SQL / dashboard 里的 proxy 字段。
- `platform_gmv` 和 `platform_gmv_usd_proxy` 不是一回事，不能直接互换。
- 如果用户说的是 `platform_gmv_v2`，默认先按 Take Rate v2 / 数仓字段解释；只有上下文明确切到 ROI3 / 实验平台时，才补实验口径层。

### 12.4 Q4 `pc2` 和 `gmvUplift` 是什么关系

**参考回答**

建议默认拆成“指标本义”和“ROI3 使用方式”两层来答。

- 指标本义：
  `gmvUplift` 看的是平台 GMV 的增量；
  `pc2` 看的是利润贡献 / 盈利质量类信号。
- ROI3 使用方式：
  两者在 ROI3 里是并列指标，不是同义词，也没有固定换算关系。
  更稳的说法是：
  `gmvUplift` 更偏“规模增长”，`pc2` 更偏“利润质量”。

合并两边语义后的标准回答可以写成：

- `pc2` 不是 `gmvUplift` 的别名。
- `gmvUplift` 回答的是“交易额有没有增长”。
- `pc2` 回答的是“这部分增长最终带来的利润贡献质量如何”。
- 在 ROI3 / 发券语境里，两者都可以是 north star / posterior 观测指标，但当前 Guardrail 主公式直接使用的是 `gmvUplift` 相关项，而不是把 `pc2` 直接写进主保护公式。

**优先怎么取证**

- 先看 ROI3 / uplift 主文档：
  [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
  和
  [`core-knowledge`](../../core-knowledge/)
- 再看 ROI3 问答手册里的实验平台契约：
  [`roi3_agent_playbook.md`](../../../team/04.product-algo/roi3/roi3_agent_playbook.md)
  重点看当前实验平台里 `pc2` 相关字段、`gmv`、`gmv_995_v2` 的使用方式。
- 如果要补字段层证据：
  [`traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live/column_info.md`](../../datamap/traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live/column_info.md)
- 如果要补跨团队指标视角的 Confluence 证据：
  [CLV Uplift Metrics Update](https://confluence.shopee.io/display/BIG/%5BSPPC-XXXX%5D+CLV+Uplift+Metrics+Update)

**回答边界**

- 回答前先锁定用户问的是“指标本义”，还是某个实验页 / SQL / dashboard 里的 `pc2` 相关字段。
- `local_new_pc2` 默认只当作当前 ROI3 实验平台字段名，不升级成 `pc2` 的 canonical 定义。
- 也必须先锁定 `gmvUplift` 指的是模型预估 uplift、实验平台 uplift，还是某个 SQL proxy uplift。
- 不要把 `pc2` 直接说成“GMV 的另一种写法”，也不要把它机械压成“固定利润率 × GMV”。

### 12.5 Q5 目前的 guardrail 指标 `gmvUplift / 4 + revUplift - VoucherCostUplift` 是否合理

**参考回答**

当前更稳的参考回答是：

- `gmv_v2 / rev / advv` 才是业务结果主指标。
- `gmv / 4 + advv - voucher_cost` 是上线时用于观察单位效率是否明显恶化的 Guardrail。
- 所以它是“合理的上线保护指标”，但不应被写成“ROI3 当前唯一或主业务目标”。

如果继续追问“为什么是 `/4`”，可以补一句：

- 当前知识库把 `gmv / 4` 当成平台对 GMV 的粗粒度变现代理，用来把 GMV uplift 粗略映射到平台价值。

**优先怎么取证**

- 先看业务和策略说明：
  [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
- 再看产品背景 / ranking 表述：
  [`core-knowledge`](../../core-knowledge/)
- 如果问的是“最近是否合理 / 最近是否恶化”，不要只看文档，直接回实验平台拉
  - `gmv_995_v2`
  - `ads_revenue_usd`
  - `advv_cost_1d`
  - `ads_voucher_cost`

**回答边界**

- 这题不要把 Guardrail 写成训练目标。
- 也不要把 Guardrail 写成线上排序唯一目标。
- 如果问的是“是否适合上线决策”，必须补最近实验数据；只靠知识卡片无法下最终结论。

### 12.6 Q6 uplift 模型现在用多长时间窗口的数据，样本是啥

**参考回答**

默认要把这题拆成 4 个窗口，否则很容易答错：

- 训练 label 窗口：
  当前主 label 是 `direct_order_1h`。
- label 回刷窗口：
  当前文档写的是 `T-1 ~ T-8`。
- 画像 / 聚合特征窗口：
  常见是 `[T-30, T-1]`。
- 历史训练样本 lookback：
  当前知识库只能部分确认，不应直接写死成某个天数，除非拿到了当前 EGO 任务配置。

样本侧更稳的参考回答是：

- 当前 uplift 训练与 UniCR 共用 `cr_train_data` 体系。
- 样本是 item 粒度广告样本。
- Treatment / Control 的根定义仍是 `voucher_price > 0` vs `voucher_price == 0`。
- RCT 分析样本要重点看 `voucher_unpicked_reason in (17, 18, 99)`。

**优先怎么取证**

- 样本与 label 先看：
  [`uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md)
- 特征窗口再看：
  [`uplift-feature.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-feature.md)
- 如果要确认与 UniCR 的样本复用关系：
  [`product-ads-model-kb.md`](../2.2-pgmv-model/product-ads-model-kb.md)
- 如果问题里的“现在”是真问当前线上最新训练任务：
  继续去查 EGO 当前 job / learner yaml / portal config；
  没有任务级配置时，不要把历史卡片里的 lookback 当成当前 truth。

**回答边界**

- 这题最常见错误是把“1h label 窗口”写成“训练 lookback 天数”。
- 也常见把“特征窗口”和“label 回刷窗口”混成一回事。
- 对外答复时建议显式写出“已确认部分”和“待任务配置确认部分”。

### 12.7 Q7 uplift 模型现在建模的 label 是啥

**参考回答**

当前更稳的参考回答是：

- 实际训练目标是 `direct_order_1h`。
- 为了兼容 CR 数据格式，convertor 输出主字段可能仍写成 `direct_label_1d`。
- 真正训练时应以训练配置读取的 multitask head 为准，而不是只看字段名字。

**优先怎么取证**

- 先看：
  [`uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md)
- 再交叉验证：
  [`uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md)
- 如果后续文档和样本字段命名冲突：
  优先相信“当前训练配置实际取的 head”，不要只按产物字段名回答。

**回答边界**

- 这题一般可以直接回答，但最好顺手补一句“字段名兼容层和真实训练 head 不完全等价”。

### 12.8 Q8 uplift 模型现在是如何建模因果性和相关性的

**参考回答**

当前更稳的参考回答是：

- 因果性建模主线：
  `DragonNet + Propensity Head + IPW + TMLE`
- 相关性建模主线：
  shared backbone / outcome heads 先学习样本和转化的相关结构，再通过 propensity / IPW / TMLE 对 treatment bias 做纠偏。

更简化地说：

- 它不是只做普通相关性预估。
- 也不是纯 RCT 统计报表。
- 而是在监督预测框架外面，再叠一层因果纠偏。

**优先怎么取证**

- 先看：
  [`uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md)
- 再回到样本定义确认 RCT / policy sample 的来源：
  [`uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md)
- 如果要回答到“实现细节到底在哪个 repo / 哪个模块”：
  需要额外补模型代码仓库和训练配置，当前总览卡片只沉淀到方法层。

**回答边界**

- “相关性”这部分通常是工程化归纳，不一定在文档里单独叫这个名字。
- 所以回答时最好注明：这是按当前模型结构对文档做的归纳解释。

### 12.9 Q9 uplift 模型只看 AUUC 指标是否合理

**参考回答**

当前更稳的参考回答是：

- 不合理。
- `AUUC` 只能说明 uplift 排序能力的一部分。
- 默认还要同时看
  - `pcr0 AUC`
  - `pcr0 pCoC`
  - `uplift pCoC`
  - 在线实验或 Guardrail

更稳的表达是：

- `AUUC` 是核心指标之一，但不是单独足够的指标体系。

**优先怎么取证**

- 先看离线评估定义：
  [`uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md)
- 再看业务侧如何消费这些指标：
  [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
- 如果问题是“最近模型效果是否只看 AUUC”：
  还要补最近一周离线报表 / 看板 / 实验结果，而不是只看文档定义。

**回答边界**

- 先区分用户问的是“离线建模评估是否只看 AUUC”，还是“上线门槛是否只看 AUUC”。
- 这两个问题不能混答。

### 12.10 Q10 uplift 模型中 `pcr_0` 和 `uplift_ratio` 是怎么融合建模的，和 UniCR 模型是啥关系

**参考回答**

当前更稳的参考回答是：

- `pcr_0` 是无券基线转化率。
- `uplift_ratio_i = pCVR_i / pCVR_0`。
- 所以任意券档位的转化率可以写成
  `pCVR_i = uplift_ratio_i * pCVR_0`。
- 在线上如果实际券档位不刚好落在锚点，会先对多个 `uplift_ratio` 做插值，再和 `pcr_0` 合成最终 `crV / ecpmV / voucherSpend / Profit / ROI`。

它和 UniCR 的关系，当前更稳的说法是：

- 共享样本基础设施与部分训练数据链路。
- 但不是同一个模型本体。
- UniCR 更像基础 CR / pGMV 模型；
  uplift 是在其基础设施之上单独建的因果 uplift 模型。

**优先怎么取证**

- 先看模型抽象和公式：
  [`uplift-model.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-model.md)
- 再看在线策略如何消费这些 head：
  [`uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md)
  和 `rerank_uni_pgmv.go`
- 再看样本链路与 UniCR 关系：
  [`uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md)
  [`product-ads-model-kb.md`](../2.2-pgmv-model/product-ads-model-kb.md)
- 如果要落到“哪个 Hive 字段能拿到最终融合后的值”：
  再补
  [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)
  里的模型分 / 字段映射问题。

**回答边界**

- 这题最容易把“模型抽象关系”答成“最终 SQL 字段落点”。
- 如果用户实际想问的是“线上落表字段”和“回放公式”，要继续往 FAQ 的字段映射与 tracking / click 表走，不要只停在模型层。

## 13. 常见误区

1. 不能把 `VoucherPgpm` 直接解释成“最终 imp-space GMV”。
2. 不能把 `voucher_price` 当成真实券成本。
3. 不能把 `CostUA / CostReal` 当成 voucher-only cost。
4. 不能把 `VoucherBoost` 和 `AdditionalDeduction` 当成同一条执行通道。
5. 不能把 `calibration` 和 `control` 写成一回事。
6. 不能把 AB group bucket、`Roi3ExpBucket`、`roi3_traffic_bucket` 混在一起解释。

## 14. 参考资料

### 14.1 本轮核心输入

- ROI3 pacing analysis 语义底稿
- ROI3 pacing analysis 分析契约与诊断设计
- ROI3 pacing analysis 示例提问与运行范式
- ROI3 pacing analysis ClickHouse 迁移草案

说明：

- 上述材料当前不在本仓库中。
- 为保证团队复用性，这里只保留材料名称和用途，不保留个人本地绝对路径。

### 14.2 业务背景补充

- Ads Smart Voucher 业务背景说明（外部材料，不在本仓库）

使用原则：

- 仅用于帮助理解业务目标和参与方关系。
- 公式、变量和最终语义仍以代码主链路与 SQL 观测为准。

### 14.3 维护建议

- 变量语义如果变化，优先同步更新 `§3`、`§6`、`§9`。
- SQL 映射如果变化，优先同步更新 `§8`、`§9`、`§10`。
- 若后续沉淀更细的专题页，建议保持本卡片为“总览入口”，把案例、SQL、脚本说明外链出去，而不是把本页继续无限展开。

## 15. 10 个业务问题回答思路入口

这张总览卡片负责沉淀 `ROI3 的稳定语义和回答边界`，但不适合把所有“当前线上 / 当前数据 / 当前配置”的问题直接写成标准答案。

对于下面这类问题：

- 券类型和 ROI3 相对其他券型的优势
- 当前线上券型分布和预期效果
- ROI3 用户链路漏斗
- 当前最优券目标
- 带券 / 不带券的 bid / deduction 差异
- ratio-based uplift 与 direct head 建模的比较
- 预算如何分层控制
- ROI 如何被 Guardrail / gating / controller 保护
- 预测高估 / 低估时的校准手段
- region budget 的变化与生效链路

统一跳到：

- [`roi3_business_question_playbook.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_business_question_playbook.md)

使用原则：

1. 那张卡片不是标准答案，而是 `回答路径卡 / 取证 playbook`。
2. 回答时要先区分 `当前实现事实 / 当前数据 snapshot / 设计层推断`。
3. 涉及“当前线上”的问题，默认按 `ROI3 知识库 -> AB 当前配置 -> 最新代码 -> 最新数据` 4 层重新取证。
4. 临时跑出来的 `占比 / 漏斗率 / 预算变化` 数字只能带时间窗复用，不能提升成长期定义。


---

# ROI3 Voucher Serving FAQ

---
id: ads_roi3_voucher_serving_faq
title: ROI3 发券在线问答 FAQ
domain: roi3
owner: Product Algo / ROI3 Strategy
source_refs:
  - docs/team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-kb.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-business.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-sample.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md
  - docs/team/04.product-algo/model-algo/knowledge/uplift-data-tables.md
  - online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go
  - online-bidding/internal/rule/productads/rerank/voucher/voucher_selector.go
  - online-bidding/internal/rule/productads/rerank/voucher/voucher_rct_selector.go
  - online-bidding/internal/rule/productads/rerank/voucher/voucher_valid.go
  - online-bidding/internal/rule/productads/rerank/voucher/voucher_algorithm.go
  - ultrav-core/internal/agent/product_ad_agent/roi3_cofund/voucher_pacing_control/strategy.go
  - ultrav-core/internal/agent/product_ad_agent/roi3_cofund/package_budget_control/strategy.go
last_updated: 2026-04-21
last_verified_at: 2026-04-21
confidence: medium
---

# ROI3 发券在线问答 FAQ

## 0. 目的

本文专门回答 ROI3 发券在线 serving、RCT、预算调控相关的高频问题，目标是让 agent 在遇到类似问题时，优先命中文档，而不是每次重新从代码和 AB 配置开始排查。

## 0.1 使用边界

这份 FAQ 里有两类内容，使用方式必须区分：

- `代码事实 / 字段定义 / AB 分桶 / SQL 入口 / 统计方法`：可以复用。
- `具体数值结果`：**不能直接复用为长期事实或对外结论**。

这里出现的占比、概率、GMV、预算等数字，都只是某次排查在特定时间窗、特定 region、特定口径下得到的**快照示例**。它们写进知识库的目的，是告诉后续使用者：

- 遇到类似问题时，应该去看哪段代码、哪张表、哪条 SQL 链路。
- 应该用什么统计口径重新计算当下数据。

不是让后续使用者直接引用这里的历史数值。

因此，后续如果再遇到类似问题，默认动作应该是：

1. 先复用本文的代码路径、字段映射和 SQL 统计方法。
2. 再按新的时间窗、region、实验桶和业务范围重新跑数。
3. 只把重新统计出的结果作为当次问题的正式答案。

当前结论基于以下证据：

- `roi3_exp_v1` 当前实验配置：`exp_id=164284`，`version=629`
- `online-bidding` 本地代码：2026-04-20 校验
- `ultrav-core` 本地代码：2026-04-20 校验

## 0.2 和 uplift 专题知识库的分工

这份 FAQ 负责回答“ROI3 在线到底怎么跑、怎么审计、怎么回放”的问题，不重复复写 uplift 专题文档里已经稳定的模型事实。

推荐分工如下：

| 如果问题更偏…… | 先看哪里 |
|---|---|
| 候选过滤 / 在线选券 / RCT serving / budget / coef / package budget | 本 FAQ |
| Guardrail、业务目标、在线/离线评估关系 | [`../../model-algo/knowledge/uplift-business.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-business.md) |
| treatment-control、1h label、RCT 样本定义、折扣档位 | [`../../model-algo/knowledge/uplift-sample.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-sample.md) |
| Profit / ROI / Bid Boost / Deduction / Cofund 公式 | [`../../model-algo/knowledge/uplift-voucher-strategy.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md) |
| 模型总入口和专题导航 | [`../../model-algo/knowledge/uplift-kb.md`](../../../team/04.product-algo/model-algo/knowledge/uplift-kb.md) |

一个简单判断原则是：

- 问“线上是怎么执行 / 怎么排查”的，优先看 FAQ。
- 问“模型为什么这么设计 / 样本为什么这么定义 / 公式为什么这么写”的，优先看 uplift 专题文档。

## 1. 当前实验分桶速记

当前 `roi3_exp_v1` 可先记住这组事实：

| group_id | group_name | 流量 | 角色 | 关键参数 |
|---|---|---:|---|---|
| `656430` | `base_0` | 5% | base | `roi3IsRandomVoucher=true`, `roi3IsFixedDiscount=true`, `Roi3ExpBucket=0`, `voucherStrategyBucketId=0`, `MinToleranceThreshold=0.02`, `NoModelScoreNoVoucher=false`, `dynamicVoucherCap=20` |
| `656431` | `base_1` | 5% | base | 同 `base_0` |
| `656432` | `bucket_01_random` | 10% | random treatment | `roi3IsRandomVoucher=true`, `roi3IsFixedDiscount=true`, `Roi3ExpBucket=1`, `voucherStrategyBucketId=1`, `MinToleranceThreshold=0.02`, `NoModelScoreNoVoucher=false`, `dynamicVoucherCap=20.0` |
| `656433~656440` | `bucket_02~09` | 各 10% | 算法桶 | `roi3IsRandomVoucher=false`, `roi3IsFixedDiscount=false`, `Roi3ExpBucket=2~9`, `voucherStrategyBucketId=2~9`, `MinToleranceThreshold=0.01`, `NoModelScoreNoVoucher=true`, `dynamicVoucherCap=5.0` |

注意：

- 当前实验显式下发了 `MinToleranceThreshold / dynamicVoucherCap / NoModelScoreNoVoucher` 等参数。
- 当前实验没有显式下发 `roi3NoVoucherProp / roi3IsRandomWideRange`；这两个值仍要结合默认 AB 配置理解。

## 2. 11 个高频问题

### Q1. 券候选的过滤逻辑有哪些？分别影响的 imp 占比是多少？

**当前状态**

- 过滤逻辑：可以回答。
- 你这轮补充的“最近 3 天、按 region 看券消耗占比”也可以回答。
- 但如果问题字面仍是“每个过滤项影响的 imp 占比”，当前 FAQ 还没有直接产出，需要单独跑 trace / reason 口径。

**已确认的候选过滤逻辑**

候选来源阶段：

- `EnableDynamicVoucher=true` 时，走 `dynamicVoucherPrepare`
- 否则：
  - `VoucherGroup=nil` 或 `roi3VoucherWithThr=false` 时，走普通券 `voucherListPrepare`
  - 否则走满减券 `voucherListPrepareNew`

候选列表公共过滤：

- `max CPA cap`
- dynamic voucher cap 过滤：`DynamicVoucherCap` 超上限或 `voucherPrice >= VoucherThresholdPrice`
- `MaxDiscountThresholdNoVoucher` 小额折扣过滤

算法组选券前过滤：

- `cofund send flag`
- `only seller adjust`
- seller voucher threshold 过滤
- `voucherDiscountDisableList` 屏蔽档位

**最近 3 天 region 券消耗占比**

下面这组数值是**本次排查快照**，只用于示范统计口径和结果呈现方式；后续类似问题请复用同一方法重新跑数，不要直接复用这些历史数字。

口径：

- 时间：`2026-04-18 ~ 2026-04-20`
- 表：`mp_paidads.ads_order_voucher_1d__reg_s0_live`
- 指标：`SUM(ads_voucher_amt_usd)` 占全 region 总 ads voucher spend 的比例
- 过滤：`tz_type='local' AND ads_voucher_amt_usd > 0`

结果：

| region | ads voucher spend | spend share |
|---|---:|---:|
| `ID` | `3,207,816.53` | `52.0859%` |
| `VN` | `1,142,642.27` | `18.5533%` |
| `TH` | `1,063,004.43` | `17.2602%` |
| `TW` | `218,962.43` | `3.5553%` |
| `PH` | `172,336.68` | `2.7983%` |
| `MY` | `148,486.14` | `2.4110%` |
| `BR` | `112,790.47` | `1.8314%` |
| `SG` | `92,662.40` | `1.5046%` |

**当前还不能直接回答的部分**

- 每个过滤项对 `imp` 的影响占比，仍需要跑曝光或请求样本。
- 推荐补数方式：按 `voucher_unpicked_reason`、trace monitor 字段和 request 侧过滤字段回放统计。

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_selector.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_algo_selector.go`

### Q2. 在 online bidding 获取到券候选后，选券时还有哪些过滤逻辑？

**当前状态**

- 可以直接回答。

**标准答案**

在 `online-bidding` 拿到候选券后，主流程是：

1. `modelPrepare`
2. `isUserValid`
3. `isItemRoi3Valid`
4. `isRoi3VoucherLimit`
5. `isBudgetAvailable`
6. 对每张券计算 `calcUpliftCTR / calcUpliftCR / calcUpliftProfitAndROI`
7. `voucherSelector`

其中：

- `isUserValid` 会看 `Roi3GroupId=201`、`UserProfileTag` 黑白名单逻辑
- `isItemRoi3Valid` 会看 `VoucherAvailable`、预算使用率、`highTroiFilter`、类目/店铺黑名单
- `isRoi3VoucherLimit` 是频控逻辑
- `isBudgetAvailable` 会用 `remainBudgetRt` 和 `roi3MaxVoucherRatio * cpa` 做预算门槛判断

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_valid.go`

### Q3. 发券的 RCT 实验组有哪些 unpicked reason，对应的含义是什么？

**当前状态**

- 可以直接回答。

**标准答案**

当前代码常量里与 RCT 直接相关的 reason 是：

- `17 = randomNoVoucher`
- `18 = randomVoucher`
- `19 = randomVoucherNotFound`
- `99 = randomVoucherFromBase`

补充解释：

- `17`：随机流程明确选择“不发券”
- `18`：随机流程选择了目标折扣，并找到了容忍度内可发的券
- `19`：随机流程抽中了目标折扣，但候选券里没有容忍度内可匹配的券
- `99`：`base bucket` 跑完随机流程后，为了日志和样本识别被改写出来的 base 标记

当前多数离线 RCT SQL 仍主要按 `17 / 18 / 99` 取样，`19` 是否单独入样要看具体分析脚本。

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/const.go`
- `online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`

### Q4. 发券的 RCT 实验，随机不发券的概率是多少？对于不同的 item 会有差别吗？

**当前状态**

- 机制可答。
- 标准 RCT 分析口径下的观测概率，现在可以回答。
- 但如果要把 `19=randomVoucherNotFound` 也完整并入“精确概率”，还需要继续跑原始 request trace；这轮尝试过一次，查询超时。

**标准答案**

随机实验的代码机制已经明确：

- 若 `roi3IsRandomWideRange=false`，随机折扣分布是：
  - `2% -> 40%`
  - `5% -> 40%`
  - `8% -> 20%`
- 若 `roi3IsRandomWideRange=true`，随机折扣分布是：
  - `5% -> 30%`
  - `8% -> 30%`
  - `12% -> 20%`
  - `15% -> 10%`
  - `20% -> 10%`

真正的“不发券”分两种：

- `targetSubsidyRate <= 0`，记为 `17`
- 有目标折扣，但候选券里没有容忍度内匹配项，记为 `19`

对不同 item 会有差别，这一点是确定的，因为：

- 候选券集合不同
- item price 不同
- 容忍度 `MinToleranceThreshold` 不同 bucket 也不同

**标准 RCT 观测概率**

下面这组概率是**本次排查快照**，只对应 `2026-04-18 ~ 2026-04-20` 这段时间和当前标准 RCT 表口径；后续类似问题请沿用相同方法重新统计。

口径：

- 时间：`2026-04-18 ~ 2026-04-20`
- 表：`mkplpaidads_search_ads.ctr_uplift_model_rct_di`
- 范围：官方 RCT 分析表中的 `17 / 18 / 99`
- 计算方式：
  - random treatment 不发券概率 = `17 / (17 + 18)`
  - random treatment 发券概率 = `18 / (17 + 18)`
  - `99` 是 base bucket 的重写标记，用来确认 base 和 random 的量级是否接近 1:1

总体结果：

- random treatment 不发券概率：`66.6678%`
- random treatment 发券概率：`33.3322%`
- base 样本占标准 RCT 表的 request 比例：`52.3975%`

分 region 的 request 口径结果：

| region | random no voucher | random voucher | base share |
|---|---:|---:|---:|
| `BR` | `28.4%` | `71.6%` | `59.9%` |
| `ID` | `71.2%` | `28.8%` | `50.2%` |
| `MY` | `81.5%` | `18.5%` | `50.7%` |
| `PH` | `82.0%` | `18.0%` | `50.8%` |
| `SG` | `45.2%` | `54.8%` | `50.9%` |
| `TH` | `77.5%` | `22.5%` | `50.2%` |
| `TW` | `95.9%` | `4.1%` | `50.4%` |
| `VN` | `84.1%` | `15.9%` | `50.1%` |

item 是否有差别：会，而且差别可能很大。根因包括：

- 候选券集合不同
- item price 不同
- `MinToleranceThreshold` 不同 bucket 不同
- 是否命中 `19=randomVoucherNotFound`

**当前还不能完全写死的部分**

- 当前实验没有显式下发 `roi3NoVoucherProp / roi3IsRandomWideRange`
- 这版“精确概率”是标准 RCT 分析口径，`19` 尚未并入；原始 request trace 查询这轮超时

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/voucher_rct_selector.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_prepare.go`

### Q5. 发券的 RCT 实验 base 组流量如何区分，base 组本应随机发的券额字段是什么？

**当前状态**

- 可以直接回答。

**标准答案**

当前 base / treatment 分桶如下：

- `656430 / 656431`：base
- `656432`：random voucher treatment
- `656433 ~ 656440`：算法桶

如果问题是“base 组如果按随机逻辑本应发券，对应券额落在哪个字段”，代码里最直接的答案是：

- `BidRerankTrace.VirtualVoucherPrice`

如果问题是“base 组跑完逻辑后的原因码在哪里”，则看：

- `BidRerankTrace.VoucherUnpickedReasonBase`

补充：

- base 组 reason 会被改写成 `99`，不是普通的 `0*100 + reason`
- 当前 `base_0` 和 `base_1` 都是 5% 流量，合起来是 10%

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`
- `docs/team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md`

### Q6. 券类型都有哪些？不同券类型之间是互斥的吗？engine 的下游服务是如何感知广告发的不同券类型？

**当前状态**

- ads 在线 serving 的券类型可以回答。
- 平台券体系在 order 表上的大类可以回答；更细的 voucher_type 需要 JOIN `dim_voucher`。
- `online-bidding` 对下游透出的关键字段现在也可以直接回答。

**标准答案**

按范围拆开看：

1. ads 在线主链路里的券类型

当前 `online-bidding` 主链路里至少可以区分出：

- 普通静态券
- 满减 / threshold 券
- dynamic voucher

其中 dynamic voucher 自己又分成两类输出：

- discount 型：写 `DynamicVoucherDiscount`
- price 型：写 `DynamicVoucherPrice`

2. 平台券体系在 `ads_order_voucher_1d__reg_s0_live` 上可见的大类

订单侧至少能直接看到 4 个金额口径：

- `ads_voucher_amt_usd`
- `seller_voucher_amt_usd`
- `platform_voucher_amt_usd`
- `fsv_voucher_amt_usd`

注意：

- `seller_voucher_amt_usd` 明确**包含** `ads_voucher_amt_usd`
- 所以这些订单金额口径并不是严格互斥的分类

如果要进一步回答“平台里到底是哪种 voucher_type”，标准方式是：

- 先拿订单里的 `ads_voucher_id`
- 再 JOIN `mp_voucher.dim_voucher__reg_live`
- 用
  - `CASE WHEN contains(voucher_groups, 'ADS-ROI') THEN 'ads_voucher'`
  - `ELSE mp_voucher_settings.mp_voucher_type`
  作为统一券类型

3. ROI3 从 `online-bidding` 出去给下游的关键字段

响应结构上的关键字段：

- `VoucherId`
- `VoucherUnpickedReason`
- `VoucherTrafficFlag`
- `VoucherPcrUpliftRatio`
- `VoucherPctrUpliftRatio`
- `DynamicVoucherPrice`
- `DynamicVoucherDiscount`
- `TargetCir`
- `BidRerankTrace`

trace / debug 侧的关键字段：

- `voucher_price`
- `bid_voucher_id`
- `voucher_unpicked_reason`
- `voucher_unpicked_reason_base`
- `dynamic_voucher_price`
- `dynamic_voucher_discount`
- `pctr_0 / pctr_v`
- `pcr_0 / pcr_v`
- `target_platform_spend_imps`
- `voucher_boost`
- `voucher_deduction`

系数 / 调控侧还会额外透出：

- `PidCoef`
- `Roi3PlatformBudgetCoef`
- `Roi3PlatformGmvCoef`
- `Roi3PlatformAdvvCoef`
- `PackageVoucherBudgetCoef`

**互斥性结论**

- 在线候选准备路径是互斥分支：dynamic / 普通 / threshold 三选一
- 但订单侧金额字段不是严格互斥，最明确的例子是 `seller_voucher_amt_usd` 包含 `ads_voucher_amt_usd`
- 因此“券类型是否互斥”必须先说清是在问在线候选类型，还是订单结算口径

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-data-tables.md`

### Q7. 发券有哪些黑名单逻辑，黑名单用户比例，以及这些用户的 GMV 占比是多少？

**当前状态**

- 黑名单使用逻辑可以回答。
- 按 `ads_smart_voucher_blacklist_user` 表去做用户比例 / GMV 占比，现在也可以回答。
- 但要注意：这张表更像 blacklist / user-tag 混合结果表，而不是“严格禁止名单”单一口径。

**标准答案**

当前可确认有三层黑名单 / 过滤：

- 请求侧：
  - `isUserBlack`
  - `isShopBlacklisted`
  - 进入 `VoucherBlacklist`
- 用户 tag 侧：
  - `UserProfileTag`
  - `EnableRoi3UserTagFilter`
  - `Roi3GroupId`
- 动态配置侧：
  - `roi3BlackList`
  - 由 `region + fe_cat_ids + shop_ids` 组成 map

类目黑名单在 serving 时通过 `config.GetRoi3BlackListMap()` 命中；用户侧黑名单排查可看离线表：

- `mkplpaidads_search_ads.ads_smart_voucher_blacklist_user`

这轮数据补充发现：

- 表里的 `group_name` 目前只有两类：`control`、`mp_plus_ads`
- 这些 group 会重叠，不能直接把 group 级占比相加
- 所以下面分成两层口径：
  - union 口径：把表内出现过的用户去重后，当作“命中 blacklist / user-tag 表的用户”
  - group 口径：按 `control` / `mp_plus_ads` 分开看

union 口径，最近 3 天、按 region：

下面这组比例是**本次排查快照**，目的是沉淀“按哪张表、按什么分母、如何拆 union / group 口径”的方法，不是沉淀一个可长期复用的 blacklist 比例真值。

- 时间：`2026-04-18 ~ 2026-04-20`
- 广告活跃用户分母：`mp_paidads.dwd_advertise_performance_di__reg_s0_live`
- ads GMV 分母：同表 `SUM(ads_order_gmv_usd)`
- 大盘 GMV 分母：`traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live.SUM(gmv_usd_1d)`

| region | union user ratio | union ads GMV share | union total GMV share |
|---|---:|---:|---:|
| `ID` | `98.0%` | `98.9761%` | `待补，单 region 查询仍在超时边界` |
| `MY` | `96.4%` | `98.4746%` | `98.5868%` |
| `PH` | `93.4%` | `97.1463%` | `97.7327%` |
| `SG` | `97.4%` | `98.9277%` | `98.9643%` |
| `TH` | `96.2%` | `98.5574%` | `98.6120%` |
| `VN` | `94.8%` | `98.2094%` | `98.2467%` |

group 口径，最近 3 天、按 region：

下面这组数值同样只是**本次排查快照**；后续如果继续使用这张表，必须重新确认 `group_name` 语义、重叠关系和最新时间窗。

| region | group_name | user ratio | ads GMV share | total GMV share |
|---|---|---:|---:|---:|
| `ID` | `control` | `9.5%` | `9.0972%` | `9.4553%` |
| `ID` | `mp_plus_ads` | `97.7%` | `98.7423%` | `98.1461%` |
| `MY` | `control` | `11.6%` | `11.0006%` | `11.3874%` |
| `MY` | `mp_plus_ads` | `84.8%` | `87.4740%` | `87.1995%` |
| `PH` | `control` | `9.3%` | `9.5946%` | `9.8028%` |
| `PH` | `mp_plus_ads` | `84.0%` | `87.5518%` | `87.9300%` |
| `SG` | `control` | `4.9%` | `4.6462%` | `4.8169%` |
| `SG` | `mp_plus_ads` | `92.5%` | `94.2815%` | `94.1474%` |
| `TH` | `control` | `9.6%` | `8.5658%` | `9.2263%` |
| `TH` | `mp_plus_ads` | `86.6%` | `89.9916%` | `89.3857%` |
| `VN` | `control` | `47.7%` | `45.8009%` | `48.0731%` |
| `VN` | `mp_plus_ads` | `47.1%` | `52.4084%` | `50.1737%` |

**解读边界**

- 这张表里的用户覆盖率非常高，说明它更像“ROI3 blacklist / user-tag 覆盖表”，不能直接等同于“严格禁止发券名单”
- `group_name` 之间存在重叠，所以 group 级 GMV share 和 user ratio 不能直接相加
- 如果后续要落“严格 blacklist 用户比例”，必须先把 `group_name` 语义锁死

**证据**

- `online-bidding/internal/config/config.go`
- `online-bidding/internal/handler/stage/productads/handle_rerank.go`
- `online-bidding/internal/rule/productads/rerank/voucher/rerank_voucher_rule.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_valid.go`

### Q8. 发券的 base 预估值、uplift 原始预估值和纠偏后的预估值在哪个 hive 表的字段可以获取？

**当前状态**

- 可以回答到“原始值落表字段”。
- 纠偏后值目前只能回答到“在线字段 / raw monitor 字段”，还没有稳定 Hive 字段映射。

**标准答案**

Hive 里已经明确能取到的是：

- `mkplpaidads_search_ads.dwd_uplift_click_conversion_hi`
- `mkplpaidads_search_ads.dwd_uplift_conversion_arrive_hi`

字段包括：

- `pcr_0`
- `pcr_02`
- `pcr_05`
- `pcr_08`
- `pcr_12`
- `pcr_15`
- `pcr_20`

这些字段来自 `bid_rerank_trace.uplift_model_score_str`。

在线 serving 实际消费的纠偏后字段是：

- `VoucherPcr0`
- `VoucherCrUpRatio1..6`

代码也把最终值写进了 raw monitor：

- `uplift_pcr_0_final`
- `uplift_ratio_1_final ... uplift_ratio_6_final`

**当前还不能直接回答的部分**

- 这组 `*_final` 字段目前还没有在现有 Hive 文档里找到稳定落表映射
- 现有 `uplift_model_score_str` 记录的是校准前值，不应直接当作最终 serving 值

**证据**

- `docs/team/04.product-algo/roi3/sql/dwd_uplift_click_conversion_hi.sql`
- `docs/team/04.product-algo/roi3/sql/dwd_uplift_conversion_arrive_hi.sql`
- `online-bidding/internal/rule/productads/rerank/model/rerank_uni_pgmv.go`

### Q9. package 发券的预算在哪个离线表可以查到？在线服务哪里可以查到？

**当前状态**

- 大盘预算离线表：现在可以回答。
- package 预算在线 trace：现在可以回答。
- package 预算离线 SQL：仍待补。

**标准答案**

离线大盘预算 SQL：

注意：这部分沉淀的是“预算应该去哪里查、怎么查”的方法，不是沉淀某次查询出来的 budget 数字本身。

```sql
SELECT grass_region,
       CAST(grass_date AS STRING) AS grass_date,
       budget,
       ingestion_timestamp
FROM mkplpaidads_search_ads.auto_budget_refresh
WHERE budget > 0
```

在线 package 预算链路已经比较清楚：

1. ads info 提供：
   - `PackageBudget`
   - `PackageRequestId`
2. `ultrav-core` 的 `package_budget_control` 按：
   - `Country + CampaignId + PackageRequestId + TrafficType_UNIFIED_ORDER`
   聚合 `Metric_VOUCHER_PRICE`，得到 `DailyVoucherSpend`
3. controller 输出 package 级 PID coef
4. `online-bidding` 消费 `PackageVoucherBudgetPacingCoef`
5. 系数写入：
   - `PackageVoucherBudgetCoef`
   - `bid_coef_arr[20]`

在线 trace / 日志可看的字段包括：

- `package_budget`
- `package_request_id`
- `daily_voucher_spend`
- `pid_coef`

日志里可直接用：

- `strategy_name = 'package_budget_control'`

如果问题扩大到“ROI3 预算 / 校准相关策略名”，这轮也补充了常见的 ultra-core 日志策略名：

- `package_budget_control`
- `ads_non_ads_dim_roi_control`
- `entrance_dim_roi_control`
- `multi_dim_cali_discount`
- `multi_dim_cali_entrance`
- `multi_dim_cali_itemprice`

**当前还不能直接回答的部分**

- 文档库里还没有一个稳定的 Hive 表，明确把 `package_budget` 作为字段沉淀出来
- package 离线预算 SQL 仍待补

**证据**

- `ultrav-core/internal/agent/product_ad_agent/roi3_cofund/package_budget_control/context.go`
- `ultrav-core/internal/agent/product_ad_agent/roi3_cofund/package_budget_control/data.go`
- `ultrav-core/internal/agent/product_ad_agent/roi3_cofund/package_budget_control/strategy.go`
- `ultrav-core/internal/agent/product_ad_agent/roi3_cofund/package_budget_control/trace.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_algorithm.go`
- `online-bidding/internal/rule/productads/rerank/finalization/rerank_roi2_finalization_rule.go`

### Q10. 发券相关的调控 coef 都有哪些，选券和调控的公式是怎样的？

**当前状态**

- 可以直接回答。

**标准答案**

当前主干调控系数可以分三层看：

在线 bid 数组：

- `PidCoef`
- `Roi3PlatformBudgetCoef`
- `Roi3PlatformGmvCoef`
- `Roi3PlatformAdvvCoef`
- `PackageVoucherBudgetCoef`

controller 输出：

- `Roi3BudgetCoefArray`
- `CofundBudgetCoefArray`

AB / serving 关键门槛：

- `roi3MaxVoucherRatio`
- `MinToleranceThreshold`
- `dynamicVoucherCap`
- `NoModelScoreNoVoucher`
- `highTroiFilter`
- `roi3PcrVCaliFactor`
- `roi3UpliftCalibPcrRatio`

选券核心是先对每张券计算：

- `voucherProfit`
- `voucherROI`
- `upliftAdvvImp`
- `ecpmV`

然后按策略选择：

- `MaxProfit`
- `MaxROI`
- `FixROI`
- `MaxAdvv`
- `MaxEcpmV`

关键公式：

- 发券额外扣费：
  - `voucherDeduction = ratio * pcrV * voucherPrice * ctrRatioUp * budgetCoef`
- cofund 扣费：
  - `voucherDeduction = upliftAdvvImp / pctrV * ratio`
- 出价调整：
  - `adjustROI3Bid = (VoucherPgpm/pctr*tCir - VoucherPcr*VoucherPrice*order2Pay [+ targetPlatformSpendImps/pctr]) * coef`
- controller PID：
  - `errorP = 1 - (budget*CDF + smooth) / (spend + smooth)`

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/voucher_algorithm.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_deduction.go`
- `online-bidding/internal/rule/productads/rerank/voucher/voucher_bid_boost_rule.go`
- `online-bidding/internal/rule/productads/rerank/finalization/rerank_roi2_finalization_rule.go`
- `ultrav-core/internal/agent/product_ad_agent/roi3_cofund/voucher_pacing_control/strategy.go`

### Q11. 线上 serving 时发券的 uplift 预估值是按折扣档位预估几个候选的 upliftRatio，这个档位的数量和范围可以扩展吗？

**当前状态**

- 可以直接回答。

**标准答案**

当前 serving 侧是 6 个 uplift ratio 头，在线插值数组写死为：

- `[0.02, 0.05, 0.08, 0.12, 0.16, 0.20]`

对应代码消费字段：

- `VoucherCrUpRatio1..6`
- `VoucherPctrRatio1..6`

因此“能不能扩展”的答案是：

- 工程上可以
- 但不是只改 AB 配置就能完成

需要同步改：

- 模型输出头数量
- 训练样本分桶
- 在线插值数组
- 评估 / RCT SQL
- 监控和知识库口径

补充：

- 现有部分离线文档还保留 `15%` 档位说法
- 但 serving 代码当前已经使用 `16%`
- 后续如扩展档位，先统一 `15%/16%` 语义再推进

**证据**

- `online-bidding/internal/rule/productads/rerank/voucher/voucher_algorithm.go`
- `online-bidding/internal/rule/productads/rerank/model/rerank_uni_pgmv.go`

## 3. 给后续 agent 的回答规则

如果下次再遇到类似问题，建议 agent 先按下面顺序回答：

1. 先判断这是“代码可直接回答”还是“必须补数据”
2. 先引用本 FAQ，再补充：
   - 当前 AB 实验版本
   - 当前本地代码 HEAD
3. 遇到下面两类问题，不要把推断写成事实：
   - 每个过滤项影响的 `imp` 占比
   - `roi3NoVoucherProp` 这类当前实验未显式下发的默认 AB 值

推荐的后续补证据路径：

- 过滤占比：tracking / impression SQL
- 默认 AB 值：`adsengine-abtest-param` 源码或线上完整透传参数
- package budget 离线表：继续补数仓字段映射


---

# ROI3 Business Question Playbook

# ROI3 10 个业务问题回答思路卡 / ROI3 Business Question Playbook

## 1. 定位

这份文档回答的不是“ROI3 这 10 个问题的唯一标准答案”，而是：

- 当前 ROI3 知识库已经能支撑到哪一层。
- 回答每一题时应该先锁什么语境。
- 应该优先去哪里取证。
- 哪些数字只能当下次回答时的 snapshot，不能直接复用成长期事实。

建议把本文当成 `取证 playbook`，而不是 `canonical FAQ`。

## 2. 使用原则

### 2.1 先分清 4 层

回答这 10 题时，默认按下面顺序刷新证据：

1. ROI3 知识库：
   先锁定概念、边界、字段和实验平台 metric 本义。
2. AB 当前配置：
   先确认“当前线上用的是哪条分支 / 哪个目标 / 哪些桶”。
3. 最新代码：
   再确认 `online-bidding / ultra-core` 当前实现没有漂移。
4. 最新数据：
   最后补实验平台、trace、tracking、order truth 的当下数字。

### 2.2 回答时必须显式区分

- `当前实现事实`
  例如：当前 selector fallback 到 `MaxProfit`。
- `当前数据 snapshot`
  例如：`2026-04-21 12:00-12:59` 的券型曝光占比。
- `设计层推断`
  例如：ratio-based 建模 vs direct head 建模的优劣。

### 2.3 两个高频坑

1. 不要把“平台券体系”与“ROI3 在线候选分支”混成一个数字。
2. 不要把“下发 / 发券 / 领券 / 核销”混成一个漏斗。

### 2.4 当前可直接复用的 snapshot

以下数字可以作为“最近一次排查示例”，但回答时必须保留时间窗：

- `2026-04-21 12:00-12:59`、8 个 active region、`ads_placement = 40`、ROI3 impression sample：
  - `dynamic_price`: `118,834,351`，约 `90.0%`
  - `dynamic_discount`: `7,713,405`，约 `10.0%`
  - `threshold`: `50`
  - `static`: `1`
- `mkplpaidads_search_ads.auto_budget_refresh` 当前可见日期范围：
  `2026-04-01 ~ 2026-04-09`
- `2026-04-21`、8 个 active region、`tz_type = local`、`ads_voucher_id > 0` 的 redeem truth：
  - `redeemed_order_cnt = 2,941,393`
  - `redeemed_voucher_usd = 1,982,538.677758`

## 3. 十个问题的回答思路卡

### 3.1 Q1 在整个 Shopee 场域中，有多少种券类型，ROI3 发券相较于其他券类型是否有天然优势

**当前更稳的回答**

- 这题不能先追一个“总共有几种券”的单一数字，必须先锁语境。
- 从平台券体系看，至少要先分 `PV / SV / FSV`；ROI3 ads voucher 属于 `SV`。
- 从 ROI3 在线实现看，当前 serving 候选分支至少包括：
  `static / threshold / dynamic`，其中 `dynamic` 再分 `discount / price`。
- 所以更稳的结论是：
  ROI3 在平台券体系里不是“另一套完全独立的 voucher universe”，而是 `SV` 体系在广告请求阶段的一条在线发券能力。

**关于“天然优势”的推荐答法**

- 可以写清楚的“机制优势”：
  - ROI3 在广告请求阶段按 `user x item x voucher` 实时选券。
  - 它和 `bid / boost / deduction / budget pacing` 在同一条链路里联动。
  - 它能在广告曝光前就把发券收益和成本纳入排序 / 出价。
- 不能直接写死的“业务优势”：
  - `CTR / CVR / GMV / ROI / PC2` 一定更好。
  - 这部分必须基于统一对比口径做数据比较，不能只靠机制说明。

**推荐取证路径**

1. 先看 ROI3 总览卡片里 `PV / SV / FSV` 和 ROI3 归属：
   [`roi3_knowledge_template.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md)
2. 再看 ROI3 FAQ 里的在线候选券分支：
   [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)
3. 如果要补“其他券类型”的平台口径：
   再补更上游 voucher / settlement 文档，而不是只停在 ROI3 卡片。
4. 如果要比较“是否更优”：
   必须先定义比较维度：
   `imp share / click / auto-claim / redeem / cost / ROI / pc2`

**当前边界**

- ROI3 知识库能回答“ROI3 属于哪类券体系、在线候选怎么分”。
- 不能仅靠 ROI3 卡片回答“整个 Shopee 全站券类型总数”。
- 也不能只靠知识卡片回答“ROI3 对所有其他券类型天然更优”。

### 3.2 Q2 在 ROI3 场景下，线上有多少种券类型，每种券类型对应的预期效果是什么

**当前更稳的回答**

- 当前 ROI3 在线候选分支至少有：
  `static / threshold / dynamic`
- `dynamic` 又分：
  `dynamic_discount / dynamic_price`
- 如果问“当前线上主流是哪些”，可以补最近一次 sample：
  `2026-04-21 12:00-12:59` 的 ROI3 impression sample 几乎全是 `dynamic voucher`，其中：
  - `dynamic_price` 约 `90%`
  - `dynamic_discount` 约 `10%`
  - `threshold / static` 可忽略

**关于“预期效果”的推荐答法**

- 先把“预期效果”降成一组可测维度：
  `imp share / click / claim / redeem / gmv / ads revenue / budget efficiency / pc2`
- 当前更稳的表达是：
  - `dynamic_price` 是当前线上绝对主流，说明现网策略更倾向于把规模流量分给 price 型动态券。
  - `dynamic_discount` 是补充型动态券分支。
  - `threshold / static` 当前更像长尾或历史分支，不是主流线上流量承载方式。
- 不建议直接把这些写成“price 一定更好、discount 一定更差”的固定业务 truth。

**推荐取证路径**

1. 分支定义先看：
   [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)
2. 当前 mix 先从 tracking / performance 做分支映射：
   - `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`
   - `mp_paidads.dwd_advertise_performance_di__reg_s0_live`
3. 分支映射优先从 `bid_rerank_trace` 或稳定分支字段抽取：
   不要手写没有 code 证据的新 branch label。
4. 如果 full-day exact query 太贵：
   可以先给 sample 窗口，并明确写 `sample window`。

**当前边界**

- 知识库可以回答“有哪些线上券类型”和“最近样本里谁是主流”。
- “每种券类型对应的预期效果”目前更适合写成 `推荐统计口径`，而不是长期标准答案。

### 3.3 Q3 站在用户角度，当其打开 Shopee APP 到最终领取到 ROI3 券，整个过程涉及到的节点是什么且前后两个节点的数据漏斗是多少

**当前更稳的回答**

- 对 ROI3 来说，应该先收窄到广告发券主链路，而不是泛化成整个 App 全路径。
- 当前更稳的漏斗定义是：
  `BestVoucherID / VoucherId 下发 -> impression -> click / auto-claim -> order -> redeem`
- 如果产品一定要把“领取”单独拉出来，建议拆成：
  `下发 -> 曝光 -> 点击 -> claim / auto-claim -> 成交 -> 核销`

**必须明确的一句**

- `发券 != 领券`
- ROI3 更接近“系统在竞价阶段决定给哪张券”，而不是用户先手动进入券中心领券。

**每个节点怎么取证**

- 下发：
  `BestVoucherID`、`VoucherId`、`bid_voucher_id`
- 曝光：
  tracking `operation = 1` 或 performance `impression_cnt`
- 点击：
  tracking `operation = 2` 或 performance `click_cnt`
- claim / auto-claim：
  `is_auto_claimed_just_now`、`ads_voucher_auto_claimed`
- order：
  tracking `operation = 5` 或 performance `order_cnt`
- redeem：
  `mp_paidads.ads_order_voucher_1d__reg_s0_live`

**当前能给出的漏斗结论**

- 节点定义现在已经能稳定回答。
- redeem truth 也有稳定出口。
- 但“同一口径、全链路、精确漏斗率”当前还不能写成固定答案。

**原因**

- full-day tracking / performance 精确聚合代价高，容易超时或爆内存。
- `mkplpaidads_search_ads.dwd_uplift_conversion_arrive_hi` 当前存在坏分区，不适合直接作为稳定 same-day truth。

**推荐取证路径**

1. 先用知识库锁定节点语义：
   [`roi3_knowledge_template.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md)
   [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)
2. 再用 tracking / performance 拉 `下发 -> imp -> clk -> order`
3. 最后用 `ads_order_voucher_1d` 拉 redeem truth
4. 如果 claim 必须单独算：
   优先用 `is_auto_claimed_just_now` / `ads_voucher_auto_claimed`

**当前边界**

- 这题可以稳定回答“链路长什么样”。
- 不能把某一次临时 SQL 跑出来的 funnel rate 直接写进主知识卡片当长期 truth。

### 3.4 Q4 在请求阶段，策略层面下发一张最优券，最优的判断标准是什么

**当前更稳的回答**

- 先算每张候选券的：
  `voucherProfit / voucherROI / upliftAdvvImp / ecpmV`
- 再由 `voucherSelector` 按策略目标选最优券。
- 当前代码里显式分支是：
  `MaxROI / FixROI / MaxAdvv / MaxEcpmV`
- 如果不命中这些显式分支，selector fallback 到：
  `MaxProfit`

**当前线上更可能是哪一个目标**

- 当前 ongoing ROI3 实验：
  `scene = 1361 / paidads_universal`
  `experiment_id = 164284 / roi3_exp_v1`
- active groups `656430 ~ 656440` 的 `enableMaxEcpmV` 当前都是 `false`
- 结合 selector code fallback，当前最强结论是：
  `线上不是 MaxEcpmV，且更大概率走默认 MaxProfit 路径`

**推荐答法**

- 如果用户问“机制上怎么选最优券”：
  直接回答 `候选逐券打分 -> selector 按目标挑一张`
- 如果用户问“当前线上到底用哪个目标”：
  回答应写成：
  `当前 AB 配置 + selector fallback 最强指向 MaxProfit`
  而不是写成“已在 AB 配置里看到一条明确的 MaxProfit 开关”

**推荐取证路径**

1. AB 平台先看当前 ongoing experiment 和 active group features
2. 再看 `voucher_algo_selector.go`
3. 如果要继续补：
   再看 `voucher_algorithm.go` 和当前 serving 配置透出的 strategy name

**当前边界**

- “当前线上最优券目标”这题要区分：
  - `实现上支持哪些目标`
  - `当前线上实际启用哪一个目标`
- 当前最强结论是 `MaxProfit`，但它是 `AB 配置 + 代码 fallback` 的组合推断，不是单条 feature flag 原文。

### 3.5 Q5 广告在携带 / 不携带 ROI3 券的情况下，对应的 bidding / boost / deduction 有什么不同

**当前更稳的回答**

- 不带券：
  ROI3 voucher layer 不改 bid，系统走基础 bidding 路径。
- 带券：
  只有 `BestVoucherID > 0` 时，ROI3 才会把 `VoucherPgpm / VoucherPcr / VoucherDeduction` 带进 bid / boost / deduction。

**没发券时的 base bid**

- `Simple ROI2 CPC`：
  `adjustBid = ModelPgmv * targetCir * pidCoef * underBidCoef * modelCoef`
- `MP CPC`：
  `adjustBid = ModelPgmv * targetCir * finalCoef * underBidCoef * manuelCoef`
- `CPS`：
  `adjustBid = ModelPgmv * targetCir * pidCoef`

**发券后的 ROI3 增量 bid**

- 非 cofund：
  `VoucherPgpm / pctr * tCir * coef - VoucherPcr * VoucherPrice * order2Pay`
- cofund：
  再加 `targetPlatformSpendImps / pctr`

**发券后的 deduction / settlement 增量**

- 非 cofund：
  `VoucherDeduction = roi3VoucherDeductionRatio * pcrV * voucherPrice * ctrRatioUp`
  如果开启 budget control，再乘 budget coef。
- cofund / standard formula：
  `VoucherDeduction = upliftAdvvImp / pctrV * roi3VoucherDeductionRatio`
- 如果打开 `EnableVoucherDeductionBidCoef`：
  deduction 还会继续乘 `PidCoef * UnderBidCoef` 写进 `AdditionalDeduction`

**关于“结算公式”的推荐答法**

- ROI3 知识库当前最稳的是“增量公式”，不是把整条广告计费链从头重推一遍。
- 所以更稳的回答是：
  - 不发券：走广告基础结算 / deduction 通道
  - 发券：在基础结算上再叠加 `voucher_deduction / additional_deduction`，并在 truth 侧产生 voucher spend / redeem cost

**推荐取证路径**

1. base bidding 先看：
   `simple_roi2_cpc_bid.go`、`MP_cpc_bid.go`、`cps_bid.go`
2. 发券增量先看：
   `voucher_bid_boost_rule.go`
3. deduction / additional deduction 先看：
   `voucher_deduction.go`
4. 如果用户要完整广告计费链：
   需要再回一般 bidding / billing 文档，不要只靠 ROI3 卡片。

**当前边界**

- ROI3 知识库可以清楚回答“带券 vs 不带券的增量差异”。
- 如果用户追问“整条广告结算最终到账公式”，要补更上游广告计费知识库。

### 3.6 Q6 选券逻辑中 advvUplift 和 gmvUplift 的计算使用 `ctCvrPpliftRatio` 进行模拟，模型是否可以直接对发券 / 不发券的 advv 和 gmv 进行预估，两种模拟方法的优劣是什么

**当前更稳的回答**

- 这题要先拆成 `当前实现事实` 和 `设计层判断`。
- 当前实现事实：
  ROI3 当前主框架是 `base + uplift ratio`，
  即先建无券基线，再用 uplift ratio 推出带券空间的 `cr / gmv / advv / profit / ROI`。
- 这意味着：
  当前主链路更像“由基线 head + uplift head 组合推导”，而不是“直接输出发券 world / 不发券 world 两套完整 advv/gmv head”。

**当前能直接写的部分**

- 这套 ratio-based 框架的优点：
  - 能复用无券基线 head。
  - 多个券档位之间更容易维持相对单调性。
  - 线上组合公式更清楚，便于插值、cap 和 calibration。
- 这套 ratio-based 框架的风险：
  - `pcr_0` 和 `uplift_ratio` 的误差会连乘传播。
  - 很难天然表达更复杂的非线性世界差异。
  - 最终 `advv / gmv` 更像组合推导值，而不是 direct head truth。

**关于“是否可以 direct predict”的推荐答法**

- 设计上当然可以考虑 direct head：
  直接建 `with voucher / without voucher` 两套 `advv / gmv` 预估。
- 但这不是当前知识库已经证实的现网实现。
- 更稳的说法是：
  `可以作为模型设计方向讨论，但要额外验证样本、因果监督、calibration 和 serving 一致性`

**如果一定要比较两种方法的优劣**

- 下面这段属于 `设计层推断`，回答时要显式标注：
  - ratio-based：
    结构更轻、与当前线上链路更一致、对多档位券插值更友好。
  - direct world prediction：
    解释上更直接，但样本和标注要求更高，且要额外保证两套世界的一致性与稳定性。

**推荐取证路径**

1. 先看 ROI3 / uplift 模型与业务文档：
   - `uplift-model.md`
   - `uplift-business.md`
2. 再看 online-bidding 如何消费：
   - `rerank_uni_pgmv.go`
   - `voucher_algorithm.go`
3. 如果要把这题从“思路回答”升级成“设计评审结论”：
   必须再补 TD / model design doc / experiment review

**当前边界**

- 当前知识库足够回答“现网更偏 ratio-based 还是 direct head”。
- 不足以只靠现有卡片给出“哪种方法绝对更优”的最终结论。

### 3.7 Q7 Shopee 给到一笔营销预算进行广告发券，对于这笔预算，策略层面是基于何种维度进行分配，分配的标准是什么，在预算无穷的情况下，是否可以细化预算分配的维度

**当前更稳的回答**

- 当前代码级已确认的预算控制至少有 3 层：
  1. 大盘 / region-day pacing
  2. bucket offline / traffic control
  3. package budget control

**三层分别是什么**

- 大盘 / region-day pacing：
  `voucher_pacing_control`
  以总 spend、总 budget、CDF、PID error 计算
  `Roi3BudgetCoefArray / CofundBudgetCoefArray`
- bucket offline：
  `bucket_budget`
  以 `todayRev >= AvailableBudget * trafficRate` 判断某 bucket 是否 offline
- package budget：
  `package_budget_control`
  以 `Country + CampaignId + PackageRequestId + TrafficType_UNIFIED_ORDER` 聚合 `DailyVoucherSpend`
  再和 `PackageBudget`、CDF 比较，产出 package coef

**关于“分配标准”的推荐答法**

- 当前更稳的说法不是“系统先做一次全局最优预算规划”，而是：
  - request-time 由目标函数选券
  - controller / budget agent 再通过 coef / offline flag 控制执行强度
- 也就是说，当前是 `逐层 gating + pacing`，不是一张静态预算分配表。

**关于“预算无穷能否细化”**

- 当前实现事实：
  已确认的细化粒度到 `package`
- 设计上可以继续往下做：
  `campaign / item / category / seller / user segment`
- 但这属于“下一层设计方向”，不是当前代码已经上线的事实。

**推荐取证路径**

1. `ultra-core` 先看：
   - `voucher_pacing_control/*`
   - `bucket_budget/*`
   - `package_budget_control/*`
2. `online-bidding` 再看：
   - `voucher_algorithm.go`
   - budget coef 的消费位置
3. 如果用户追问“为什么按这些维度”：
   需要再补 budget strategy / planning 设计文档

**当前边界**

- 这题现在已经能答到“当前实现分哪几层、每层靠什么控制”。
- 但“预算无穷时的最优细分维度”仍然应明确标成设计讨论。

### 3.8 Q8 广告发券预算作为公司的一笔营销投入，在发券策略层面，如何保证这笔投入的 ROI 是达标的

**当前更稳的回答**

- 当前不是靠一个单点公式保证 ROI，而是 4 层一起工作：
  1. 目标函数和 Guardrail
  2. request-stage gating
  3. 逐券目标函数选券
  4. controller / budget pacing 调节执行强度

**四层怎么理解**

- Guardrail：
  `gmv_uplift / 4 + advv_uplift - cost_uplift > 0`
- request-stage gating：
  `isUserValid / isItemRoi3Valid / isRoi3VoucherLimit / isBudgetAvailable`
- selector：
  `voucherProfit / voucherROI / upliftAdvvImp / ecpmV`
- controller：
  通过 `CaliCoef / PID / budget coef / CDF` 控节奏

**实验和数据观测层怎么验证**

- truth 成本：
  `ads_voucher_cost`
- value / spend 对照：
  `ads_revenue_usd`、`advv_cost_1d`
- 主观察指标：
  `cost_ratio_1d = ads_revenue_usd / advv_cost_1d`

**推荐答法**

- 如果用户问“机制上怎么保 ROI”：
  可以直接回答上面 4 层
- 如果用户问“最近是否真的达标”：
  必须追加时间窗、region、experiment id，然后再拉实验平台数据

**推荐取证路径**

1. 总览知识卡片里的 Guardrail、metric 词典
2. FAQ 里的 gating、selector、controller
3. 实验平台里 `ads_voucher_cost / ads_revenue_usd / advv_cost_1d / cost_ratio_1d`

**当前边界**

- 这题可以稳定回答策略机制。
- 不能只靠知识卡片回答“最近一定达标 / 一定不达标”。

### 3.9 Q9 在请求阶段，最优券的判断标准都是基于模型输出的预估值实现的，当预估值出现高估 / 低估情况时，策略是否有校准手段

**当前更稳的回答**

- 有，而且不止一层。
- 当前线上消费的不是 raw head，而是经过 calibration / ratio / cap / monotonicity 后的最终字段。

**当前已确认的校准手段**

- `UsePromCali`
- `cali_*_pgmv_7d_v2`
- `uniCRPgmvRatio`
- score ratio
- cap
- monotonicity

**线上最终消费的字段**

- `VoucherPcr0`
- `VoucherCrUpRatio1..6`
- `VoucherPctr0`
- `VoucherPctrRatio1..6`

**推荐答法**

- 如果用户问“有没有校准手段”：
  直接回答有，并给出上面这条链
- 如果用户问“高估 / 低估时系统还有什么兜底”：
  可以补：
  - calibration 修正预测值
  - controller / budget gating 限制执行强度
  - 但 controller 不是 prediction calibration

**推荐取证路径**

1. 先看：
   `rerank_uni_pgmv.go`
2. 再看：
   [`roi3_voucher_serving_faq.md`](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)
3. 如果要问“当前校准效果到底多好”：
   要继续去拉 `*_final` 字段落表或线上监控

**当前边界**

- 可以稳定回答“有校准手段”。
- 不能只靠知识卡片回答“当前校准效果具体提升了多少”。

### 3.10 Q10 各个 REGION 的发券预算如何确定，更新频率是多少，策略如何感知预算的变化，预算变更后是否会立即生效

**当前更稳的回答**

- 这题必须拆成 4 个子问题：
  1. 预算 truth 在哪里
  2. 策略如何读到它
  3. controller 如何把变化转成 coef / pacing
  4. 如何验证变更后是否生效

**当前能直接回答的部分**

- 离线 truth budget：
  `mkplpaidads_search_ads.auto_budget_refresh`
- 当前表里可见日期范围：
  `2026-04-01 ~ 2026-04-09`
- 最近可见显著 region budget 变化：
  `SG: 24900 -> 16617`
  其他 region 基本持平

**策略如何感知预算变化**

- trace / controller 侧可见：
  `DailyBudget / AdjustBudget`
- package 粒度可见：
  `PackageBudget / PackageRequestId`
- online-bidding 会消费：
  `PackageVoucherBudgetPacingCoef`

**关于“更新频率”和“是否立即生效”的推荐答法**

- 离线 truth 表当前看起来是 `day-level`
- 但“预算变更后是否立即生效”不能只看离线 truth 表，必须补：
  - ultra-core controller log
  - HyperX trace
  - 或变更前后 request-time coef 变化

**推荐答法**

- 如果用户问“最近 x 天 budget 有哪些变化”：
  可以直接用 `auto_budget_refresh` 做 by-day diff
- 如果用户问“变更下去之后多久在线生效”：
  回答必须分成：
  - offline truth 更新时点
  - online controller / request trace 首次看到新 budget 的时点

**推荐取证路径**

1. 先看离线 truth：
   `mkplpaidads_search_ads.auto_budget_refresh`
2. 再看 ultra-core：
   `voucher_pacing_control/*`
   `package_budget_control/*`
3. 再看 online-bidding 如何消费 coef：
   `voucher_algorithm.go`
4. 如果要回答“立即生效了吗”：
   必须拉 controller log / trace by day 或 by hour 差异

**当前边界**

- 这题已经能稳定回答“用什么表 / 什么 agent / 什么 coef 去追预算变化”。
- 但不能只靠离线 truth 表回答“确定逻辑”和“秒级生效 SLA”。

## 4. 推荐的统一回答模板

后续 agent 回答这 10 题时，建议默认按下面格式：

1. 先写 `当前更稳的结论`
2. 再写 `这是实现事实 / snapshot / 设计推断 的哪一类`
3. 再写 `取证路径`
4. 最后写 `当前边界`

推荐一句总提醒：

- `下面给的是当前 ROI3 知识库下最稳的回答路径，不是长期固定答案；涉及当前线上目标、预算、曝光占比和漏斗数字时，建议按同一思路重新拉 AB 配置、最新代码和最新数据。`


---

# ROI3 Agent Handoff

# ROI3 Knowledge Card Agent Handoff

## 1. 目的

这份文档说明 [roi3_knowledge_template.md](../../../team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md) 是如何从 ROI3 分析资料中抽象出来的、又是如何在 `2026-04-20 ~ 2026-04-22` 这几轮更新中逐步收口到当前版本的；同时记录当前哪些结论已经锁定、哪些仍需后续补证据，以及下一位同学或 agent 应该如何继续扩建。

目标不是重复总览卡片本身，而是帮助后续维护者：

- 快速理解本轮知识库搭建的方法。
- 区分“本轮已统一的语义”与“后续仍需补实证”的部分。
- 继续扩展 ROI3 知识库时，不再回到 1600+ 行分析草稿从头整理。

## 2. 目标文件

- 目录入口：`docs/team/04.product-algo/roi3/README.md`
- 主文档：`docs/team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md`
- FAQ：`docs/team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md`
- 10 个业务问题回答思路卡：`docs/team/04.product-algo/roi3/knowledge_template/roi3_business_question_playbook.md`
- 问答手册：`docs/team/04.product-algo/roi3/roi3_agent_playbook.md`
- 一致性审计：`docs/team/04.product-algo/roi3/roi3_definition_consistency_audit.md`
- 关联专题：`docs/team/04.product-algo/model-algo/knowledge/uplift-*.md`
- 当前定位：ROI3 总览知识卡片 + 在线 FAQ + 10 个业务问题回答思路卡 + 问答手册 + 一致性审计 + uplift 专题回链入口
- 当前状态：已经覆盖业务背景、分层语义、关键变量、AB 桶约束、实验平台回答契约、SQL 映射、Level1/2/3 分析框架、实验平台 metric 词典、PC2 四层口径、10 个业务问题回答思路卡，并把 uplift 模型专题知识库接到了 ROI3 入口上

## 3. 本轮构建方法

### 3.1 核心方法

本轮没有直接复制 `concept_kb.md`，而是按下面顺序做抽象：

1. 先参考团队既有知识卡片的组织方式，确定“总览卡片 + handoff”应该怎么组织。
2. 再把 `concept_kb.md` 里最稳定、最容易被误解、最值得长期复用的内容抽出来。
3. 用 `reference.md` 把三层分析框架、AB 桶语义、脚本与 sidecar 结构补齐。
4. 用 `examples.md` 和 `clickhouse_schema_plan.md` 判断哪些内容更适合放在“知识卡片”，哪些应该留给未来的专题文档。
5. 对“模型 / 样本 / 特征 / 策略”这四类已经在 `model-algo/knowledge/uplift-*.md` 中较完整、且更接近代码语义的内容，不在 ROI3 总览里重复展开，而是改成摘要 + 回链。

### 3.2 这几轮是怎么扩建的

这份 ROI3 知识库不是一次写完的，而是按 4 个阶段逐步收口：

1. `2026-04-20`
   - 先补 [roi3_voucher_serving_faq.md](../../../team/04.product-algo/roi3/knowledge_template/roi3_voucher_serving_faq.md)。
   - 先解决“线上发券 / RCT / package budget / coef / uplift 档位”这类最常问、最容易阻塞分析的问题。
   - 同时把 Q5 / Q8 / Q10 的实验平台回答契约固定下来。
2. `2026-04-21`
   - 把 `model-algo/knowledge/uplift-*.md` 回链到 ROI3 入口。
   - 明确 ROI3 总览不再重复维护模型 / 样本 / 特征 / 策略专题的全文拷贝，而是保留摘要、边界和阅读路径。
3. `2026-04-22` 第一阶段
   - 补 Q3 / Q4：
     `platform_gmv_v2 / platform_gmv`、`pc2` 和 `gmvUplift`。
   - 随后引入 [roi3_definition_consistency_audit.md](../../../team/04.product-algo/roi3/roi3_definition_consistency_audit.md)，把本地 ROI3 知识库与 `ads-knowledge-qa` / Confluence 做双重比对。
   - 再根据 owner decisions，把 `ROI3` 主定义、Guardrail、`platform_gmv` 双语境、`local_new_pc2` 的降级边界回写到主卡片、问答手册和 handoff。
4. `2026-04-22` 第二阶段
   - 补 `§8.10 实验平台 Metric 词典`。
   - 补 `§8.11 实验平台 PC2 四层口径`。
   - 让问答手册不再需要现场重造 `revenue_usd / gmv_usd / advv_cost_* / cost_ratio_* / pc2` 的定义。
5. `2026-04-22` 第三阶段
   - 新增 [roi3_business_question_playbook.md](../../../team/04.product-algo/roi3/knowledge_template/roi3_business_question_playbook.md)。
   - 把“10 个业务问题”沉淀成 `回答路径卡`，而不是 `标准答案卡`。
   - 明确要求后续 agent 先刷新：
     `ROI3 知识库 -> AB 当前配置 -> 最新代码 -> 最新数据`
   - 同时把当前可复用的 snapshot 和 source table 边界写清楚，避免后续直接复用旧数字。

### 3.3 取舍原则

- 保留：
  - 语义分层
  - 锁定语义
  - 关键变量字典
  - click / imp 空间区别
  - 成本口径差异
  - AB 桶语义
  - SQL 最小映射
  - Level1 / Level2 / Level3 结构
- 不直接搬运：
  - `concept_kb.md` 中大量逐段变量穷举
  - 过长的分析实现细节
  - 运行命令示例全文
  - ClickHouse 迁移设计中的表级全部字段定义
  - 其他主题知识卡片中的业务内容

### 3.4 为什么这样做

`concept_kb.md` 是“深分析工作底稿”，信息很全，但不适合作为团队长期查阅入口。
知识卡片更需要：

- 先统一概念。
- 再给出稳定落点。
- 最后指向代码、SQL 和脚本入口。

所以本轮把 ROI3 知识库定位成：

- 一张总览卡片
- 加一份维护 handoff

并且明确做了两件清理：

- 不保留个人本地绝对路径。
- 不保留其他主题的业务内容，只借鉴知识卡片结构。

而不是把原始分析工程完整搬进 `docs/team/04.product-algo/roi3`。

## 4. 主要来源

### 4.1 直接使用的来源

- ROI3 pacing analysis 语义底稿：`concept_kb`
- ROI3 pacing analysis 分析契约：`reference`
- ROI3 pacing analysis 示例与调用范式：`examples`
- ROI3 pacing analysis ClickHouse 迁移草案：`clickhouse_schema_plan`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-kb.md`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-business.md`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-model.md`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-sample.md`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-feature.md`
- `docs/team/04.product-algo/model-algo/knowledge/uplift-voucher-strategy.md`
- `docs/team/04.product-algo/roi3/roi3_agent_playbook.md`
- `docs/team/04.product-algo/roi3/roi3_definition_consistency_audit.md`
- `docs/common/core-knowledge/`
- Confluence:
  - `24Q4 ROI3 Voucher`
  - `Take Rate DataSet`
  - `CLV Uplift Metrics Update`

说明：

- 这些来源里既包含仓库内文档，也包含外部工作底稿和 Confluence 材料。
- 为保证团队复用性，本 handoff 不再保留个人本地绝对路径。

### 4.2 来源分工

- `concept_kb.md`
  - 提供 ROI3 的概念主线、变量字典、空间标签、成本口径和 SQL 对照。
- `reference.md`
  - 提供 Level1 / Level2 / Level3 主链路、AB 桶语义、脚本产物和 diagnostics 结构。
- `examples.md`
  - 提供这个分析工程实际如何被调用的用户提问范式。
- `clickhouse_schema_plan.md`
  - 帮助识别哪些表和字段是“长期稳定的数据契约”。
- `uplift-kb.md`
  - 提供 uplift 专题的统一入口，用来判断哪些内容该沉淀在 ROI3 总览，哪些应回链到专题页。
- `uplift-business.md`
  - 提供 ROI3 的 Guardrail、评估口径、业务目标和风险语义。
- `uplift-model.md`
  - 提供模型架构、训练目标、score 加工和已知风险。
- `uplift-sample.md`
  - 提供 treatment / control、1h label、RCT 定义和折扣档位。
- `uplift-feature.md`
  - 提供 uplift 特征体系和覆盖率语义。
- `uplift-voucher-strategy.md`
  - 提供逐券 Profit / ROI / Bid / Deduction / Cofund 的策略细节。
- `roi3_agent_playbook.md`
  - 提供“哪些问题能直接答、哪些问题只能给 proxy、实验平台该去哪个 tab”这类 answerability 契约。
- `roi3_definition_consistency_audit.md`
  - 提供本地知识卡片与 `ads-knowledge-qa` / Confluence 的双重核对结果，以及 owner decision 为什么要这样回写。
- `core-knowledge/`
  - 提供 `ads-knowledge-qa` 主路径下 ROI3 / ROI4、north star metrics、voucher strategy 的 canonical 背景定义。
- `24Q4 ROI3 Voucher`
  - 提供 ROI3 产品命名公式和实验页面视角的背景证据。
- `Take Rate DataSet`
  - 提供 `platform_gmv` 在数仓/订单侧的证据。
- `CLV Uplift Metrics Update`
  - 提供 `pc2` 和 `gmv` 属于不同 metric family 的跨团队证据。
- 团队既有知识卡片写法
  - 仅提供组织方式参考，不提供 ROI3 业务内容。

## 5. 当前已锁定的核心结论

本轮知识卡片里已经作为稳定结论写入的内容包括：

1. `pcoc = 预测值 / 实际值`。
2. `uplift_* = voucher - base`。
3. `ModelPgmv` 统一视为 click 空间的 `pgmv_0_clk`。
4. `BidRerankTrace.PgmvV` 统一视为 click 空间的 `pgmv_v_clk`。
5. `VoucherPgpm` 不能直接等价为严格的 `pgpm_v_imp`。
6. `voucher_price` 与真实核销券成本不是一回事。
7. `reward_discount -> Metric_VOUCHER_PRICE` 是当前更可靠的 redeem cost 主链路。
8. `CostUA / CostReal` 应视为广告主实际消耗 / revenue 口径，不是 voucher-only cost。
9. 控制层只调执行强度，不生成模型预测。
10. AB 平台 group bucket、在线实验桶、运行时 trace bucket 必须区分。
11. 文档中不再保留个人本地绝对路径，外部材料只以名称和用途描述。
12. 文档内容只保留 ROI3 发券语义，不保留其他主题的业务内容。
13. ROI3 在本地知识库里默认按当前分析契约记录；`gmv_uplift / 4 + advv_uplift - cost_uplift > 0` 是当前主 Guardrail，但不是唯一的产品命名定义。
14. 当前 uplift 训练目标应默认理解为 `direct_order_1h`，不是把主输出 label 字段名直接当成训练目标。
15. Treatment / Control 默认按 `voucher_price > 0` 与 `voucher_price == 0` 划分，RCT 主 reason 仍以 `17 / 18 / 99` 为核心。
16. 模型 / 样本 / 特征 / 策略专题事实优先沉淀在 `uplift-*.md`，ROI3 总览只保留会影响分析契约的摘要和约束。
17. `ROI3 = GMV / (ad cost + coupon cost)` 在本知识库里只保留为历史产品命名背景，不替代当前 ROI3 分析契约。
18. `platform_gmv` 必须拆成两层：
    - Take Rate / 数仓字段定义
    - ROI3 / 实验平台指标定义
19. `platform_gmv` 在实验平台里的精确窗口、全场景、归因规则目前不作为主定义卡里的 canonical 事实，而是保留在审计和个案解释层。
20. `pc2` 的主定义在 ROI3 知识库里只保留到“利润贡献 / 盈利质量信号”这一层，不把 `local / proxy / adjusted proxy / true` 全部提升成主定义。
21. `local_new_pc2` 默认只作为当前 ROI3 实验平台字段名，不自动等于 `True PC2`。
22. `§8.10` 的 experiment metric 词典是页面解释层知识，用来回答 dashboard / AB 页面里的指标本义，不替代表级定义文档。
23. `§8.11` 的 PC2 四层口径是跨团队解释框架，用来帮助锁定“当前看到的 pc2 属于哪一层”，不是在声明 ROI3 当前线上只使用其中某一层。

## 6. 这次没有做的事情

需要明确，这一轮的“深度理解”主要是建立在 ROI3 分析资料之上，而不是再次逐行复核线上代码和 SQL。也就是说：

- 我读透并抽象了 `concept_kb.md` 与配套 `reference.md`。
- 我复用了 `model-algo/knowledge/uplift-*.md` 里已经沉淀好的专题事实。
- 我补做了 `ads-knowledge-qa` / Confluence 的概念一致性核对，并把结果沉淀在 `roi3_definition_consistency_audit.md`。
- 我没有在本轮里重新逐行审查 `online-bidding`、`ultra-core` 和所有 SQL 文件。
- 因此当前知识卡片的事实边界是：
  - 以这组 ROI3 分析资料已经完成的代码/SQL 对齐结果为准。
  - 以及 uplift 专题文档已经吸收的代码级事实为准。
  - 再叠加 `ads-knowledge-qa` / Confluence 对概念层的双重核对结果。
  - 不是重新独立完成了一次从源码到 SQL 的全量验证。

这不是缺点，但后续维护时要诚实保留这个边界。

## 7. 后续最值得继续补的方向

### 7.1 代码级再验证

如果下一位维护者要把这张卡片从“高质量总览”推进到“排障手册”，建议优先补：

- `rerank_uni_pgmv.go` 的逐字段代码锚点
- `voucher_algorithm.go` / `voucher_bid_boost_rule.go` 的关键公式定位
- `voucher_pacing_control/*` 中控制变量的代码片段级解释

### 7.2 SQL / 数据契约再固化

当前卡片已经给出表级映射，但仍可以继续补：

- 每张关键表的字段对照表
- 主分析 SQL 的入口路径
- “哪个指标直接拿、哪个指标要推导、哪个指标是 proxy”的更细颗粒度说明

### 7.3 实验平台定义继续补强

虽然 `§8.10` 和 `§8.11` 已经补上，但仍有 3 类信息还值得继续补：

- 实验平台页面 metric 和 API raw metric id 的逐项映射。
- `local_new_pc2` 与 `Local / Proxy / Adjusted Proxy / True PC2` 的更直接证据链。
- `platform_gmv` 在当前实验页里的更精确窗口 / attribution 说明是否能找到更权威来源。

### 7.4 专题页扩展

后续如果要继续扩建，建议按专题拆，而不是继续把总览卡片变长。优先可拆的主题：

- ROI3 变量字典专题
- ROI3 SQL 数据契约专题
- ROI3 Level1 / Level2 / Level3 报告阅读指南
- ROI3 AB bucket 与实验配置专题
- ROI3 实验平台 metric / tab 使用指南

## 8. 推荐的维护工作流

### 8.1 更新原则

1. 如果变量语义变了，先改总览卡片的 `§3 锁定语义` 和 `§6 关键变量与公式`。
2. 如果变化属于模型 / 样本 / 特征 / 策略专题，先改 `model-algo/knowledge/uplift-*.md`，再把会影响分析契约的部分同步回 ROI3 总览或 FAQ。
3. 如果变化属于概念主定义，先补 `roi3_definition_consistency_audit.md`，说明和 `ads-knowledge-qa` / Confluence 是否一致，再决定是否回写主卡片。
4. 如果变化属于实验平台页面指标解释，优先同步 `§8.10` / `§8.11`，并在问答手册里补入口提示。
5. 如果 SQL 或日志落点变了，必须同步改 `§9 SQL 数据契约与观测映射`。
6. 如果三层分析框架变了，必须同步改 `§10 Level1 / Level2 / Level3`。
7. 如果只是新增案例、报表或命令，不要堆进总览卡片，优先新建专题页后再回链。

### 8.2 建议操作顺序

1. 先读 [roi3_knowledge_template.md](../../../team/04.product-algo/roi3/knowledge_template/roi3_knowledge_template.md)。
2. 如果问题明显属于模型 / 样本 / 特征 / 策略专题，先读 `../../model-algo/knowledge/uplift-*.md` 对应文档。
3. 如果问题属于概念定义或口径冲突，先读 `../roi3_definition_consistency_audit.md`，确认当前 owner decision 是什么。
4. 如果问题属于实验平台 metric / pc2 口径，优先看总览卡片 `§8.10` / `§8.11`，再决定是否需要补外部证据。
5. 再回看 `concept_kb.md` 中对应章节，确认要改的是哪一层。
6. 需要代码锚点时，再去实际代码仓库补证据。
7. 最后把更新内容同步回总览卡片、FAQ、问答手册和 handoff。

## 9. 目录设计说明

本轮把 `docs/team/04.product-algo/roi3` 搭成了一个最小可维护结构：

- `README.md`
  - 目录入口
- `knowledge_template/roi3_knowledge_template.md`
  - 团队查阅用总览卡片
- `knowledge_template/roi3_voucher_serving_faq.md`
  - 面向线上发券 / RCT / package budget / coef 问题的问答补充
- `knowledge_template/roi3_knowledge_template_agent_handoff.md`
  - 面向后续维护者的上下文说明
- `roi3_agent_playbook.md`
  - 面向 agent / AI 问答的 answerability 与取证手册
- `roi3_definition_consistency_audit.md`
  - 面向概念主定义的审计轨迹与 owner decision 记录

这样做的原因是：

- 当前 `roi3` 目录原本几乎为空。
- 参考团队既有知识卡片的形式，最合适的首版形态就是“总览卡片 + handoff”。
- 后续继续扩建后，目录已自然演进成“总览卡片 + FAQ + playbook + audit + handoff”。
- 对于已经在 `model-algo/knowledge` 沉淀成熟的 uplift 专题，ROI3 目录不再重复维护一份拷贝，而是保留回链和边界说明。

## 10. 最后提醒

这套 ROI3 知识库的价值，不在于把分析资料全文搬过来，而在于把最容易混淆的语义锁死。
后续无论是写脚本、看实验、做诊断还是做交接，优先守住下面这几个锚点：

- 先分层，再解释变量。
- 先声明空间，再讨论 GMV。
- 先区分券面额和核销成本，再讨论成本。
- 先分清 bucket 体系，再讨论 uplift。
- 先判断当前问题是在问“主定义”还是“实验平台页面字段”，再决定去主卡片、audit 还是 metric 词典里找答案。

只要这几个锚点不丢，后续扩建会顺很多。
