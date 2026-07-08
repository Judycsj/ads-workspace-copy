---
id: product_ads_bidding_kb
title: Product Ads Bidding 知识库
domain: bidding
owner: Product Algo / Bidding Algo
source_refs:
  - docs/team/04.product-algo/bidding-algo/temp/jirong.you/bidding-kb/bidding-kb.md
  - docs/team/04.product-algo/bidding-algo/temp/jirong.you/bidding-kb/writing-rules.md
last_updated: 2026-04-30
last_verified_at: 2026-04-30
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1REvaeX0dOzELqoiRilRPWKEwQDCqiz9FTRRIS0jvNEk gdoc_url=https://docs.google.com/document/d/1REvaeX0dOzELqoiRilRPWKEwQDCqiz9FTRRIS0jvNEk/edit -->


# Bidding 知识库

## KB 必要信息索引

| 类别 | 当前索引 |
|---|---|
| 代码仓库 GitLab 路径 | `shopee/deep/paidads-bidding/online-bidding`、`shopee/deep/paidads-bidding/bidding-store`、`shopee/deep/paidads-bidding/ultrav-core-timewindow`、`shopee/deep/paidads-bidding/ultrav-data-processor` |
| 核心服务 SDU 路径 | **【待确认】需由 owner 通过 Space / SMC 确认 `online-bidding`、`bidding-store`、UltraCore / timewindow 线上 SDU 路径** |
| ConfigCenter namespace | `online_config/global/`、`online_config/global_update/`、`debug/test_config/*.json` |
| Grafana dashboard | **【待确认】当前源 KB 未集中列出 Grafana 链接，需补充 bidding / UltraCore / bidding-store dashboard** |
| 关键 Kafka topic | **【待确认】反馈回流、posterior、ultrav-data-processor 相关 topic 需按当前生产配置补齐** |
| 核心 Hive 表名 | `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live`、`mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`、`mp_paidads.dwd_advertise_performance_di__reg_s0_live` |

## 范围

本文汇总 `Product Ads bidding` 的业务、技术和工程知识。

正文按以下顺序组织：

1. `Business`
2. `Technical`
3. `Engineering`

附录包含：

1. 术语表
2. 资料来源登记

本文不展开以下内容：

- 全量历史方案
- 全量 Google Doc 细节
- 全量 Redis、Kafka、protobuf 细节
- 样本产出任务代码不在当前工作区的实现部分

## Business

### 1. 业务定义

#### 1.1 单品与多品

- 单品：一个 `campaign` 对应一个 `item`
- 单品：一个 `item` 对应一个 `ads`
- 多品：一个 `campaign` 对应多个 `item`
- 多品：一个 `item` 对应一个 `ads`

#### 1.2 OCPM 与 OCPC

- `OCPM = Optimized Cost Per Mille`
- `OCPC = Optimized Cost Per Click`
- 两者都属于智能出价模式
- 两者都具有“出价点与计费点分离”的特征

`OCPC` 的业务定义包括：

- 出价点是转化目标
- 计费点是点击
- 广告主设置业务目标成本，例如 `Target CPA`
- 系统结合 `pCVR`、`pCTR` 等预估结果换算排序时使用的 `eCPM`
- 最终按点击扣费

`OCPM` 的业务定义包括：

- 出价点是转化目标
- 计费点是曝光
- 广告主设置业务目标成本，例如 `Target CPA`
- 系统换算排序时使用的 `eCPM`
- 最终按曝光扣费

`OCPM / OCPC` 是出价与扣费模式概念。

`pricing_type` 是 `Product Ads` 的产品定义。两者不是同一维度。

#### 1.3 产品形态与 pricing_type

| 产品形态 | 常见叫法 | 说明 |
| --- | --- | --- |
| `Target ROI2` | `roi2.0`、`TargetROAS` | 目标 ROAS 型自动出价 |
| `Simple ROI2` | `roi2.0 simple`、`AutoBidding` | 简化版自动出价 |
| `GMV Max Ad Group` | `multi_product_boost` | 面向 GMV 最大化的产品形态 |
| `GMV Max Shop` | `gmv_shop_max` | 面向 shop 维度的 GMV Max 形态 |
| `Manual CPC` | `manual_cpc` | 手动出价 |
| `Manual eCPC` | `manual_ecpc` | 增强手动出价 |

| pricing_type | 产品名称 | 产品形态 |
| --- | --- | --- |
| `11` | 单品 `Target ROI2` | 单品 |
| `15` | 单品 `Simple ROI2` | 单品 |
| `24` | 多品 `GMV Max Shop target` | 多品 |
| `25` | 多品 `GMV Max Ad Group` | 多品 |
| `27` | 多品 `GMV Max Shop simple` | 多品 |

#### 1.4 各 pricing_type 的目标与约束

| pricing_type | 用户输入 | 调控目标 | 约束 |
| --- | --- | --- | --- |
| `11` | 预算 + `target_roi` | 最大化 `gmv` | 满足用户设置的 `target_roi` |
| `15` | 仅预算 | 最大化 `rev` | ROI 落在建议区间内 |
| `24` | 预算 + `target_roi` | 最大化 `gmv` | 满足用户设置的 `target_roi` |
| `25` | 预算 + `target_roi` | 最大化 `gmv` | 满足用户设置的 `target_roi` |
| `27` | 仅预算 | 最大化 `rev` | ROI 落在建议区间内 |

补充口径：

- `11/24/25` 属于 `Target` 类
- `15/27` 属于 `Simple` 类
- `Target` 类由用户设置 `target_roi`
- `Simple` 类只设置预算，由系统给出 ROI 建议区间

#### 1.5 出价插件

##### 1.5.1 Rapid Boost

- `Rapid Boost` 是挂在现有 ROI2 / GMV Max 主链路上的增强能力
- `Rapid Boost` 用于常规场景下的动态 ROI 下探
- 在线出价公式不变，变化的是调控目标的生成方式

##### 1.5.2 Campaign Surge

- `Campaign Surge` 是挂在现有 ROI2 / GMV Max 主链路上的增强能力
- `Campaign Surge` 用于大促场景下的动态 `tROI` 下探
- 平台侧提供 `ROI_origin`、`ROI_after`、toggle 和预算信息

##### 1.5.3 dynamic probing

`Target` 类产品的字段关系如下：

- `ROI_origin = idx_upper_bound = 原始 tROI`
- `ROI_after = target_roi = 允许下探后的 ROI 下界`
- `ROI_after <= final_target_roi <= ROI_origin`

dynamic probing 的处理顺序如下：

1. 估算预算更充分消耗所需的 ROI 放松程度
2. 将结果限制在允许区间内
3. 使用最终目标 ROI 继续完成 `coef` 搜索和在线出价

##### 1.5.4 同时生效时的处理

- `Campaign Surge` 与 `Rapid Boost` 同时生效时，按更激进的下探比例生效

### 2. 关键指标

#### 2.1 主要指标

##### `imp` / `click` / `order`

广告的实际曝光、点击和转化结果。

##### `cost`

广告消耗。在平台收入口径中通常记为 `rev`。

##### `gmv`

广告实际转化 `gmv`。

##### `advv`

广告主价值，通常等于 `gmv / target_roi`。

##### `achievement`

广告目标达成状态。状态包括 `fulfill`、`overbid`、`underbid`、`noadvv`。业务分析通常关注达标广告的 `cost` 占比。

不同广告产品的达成计算方式不同。同一产品也可能存在多种达标口径。

##### `cpc` / `cpm`

后验单次 `click` 的费用和单次 `imp` 的费用。本系统中的 `cpm` 一般不按 1000 曝光计算。

#### 2.2 Achievement 口径

##### 2.2.1 状态定义

`achievement` 描述广告在给定统计窗口内的实际结果状态。

状态包括：

- `fulfill`
- `overbid`
- `underbid`
- `noadvv`

业务统计区分两种口径：

- `algo`
- `seller`

统计窗口为 `1d` 和 `7d`。

##### 2.2.2 algo 与 seller 口径

| 维度 | `algo` 口径 | `seller` 口径 |
| --- | --- | --- |
| ratio | `advv_w / cost_w * cost_ratio_coef` | `advv_w / cost_w` |
| `overbid` | `< 0.8` | `< 0.8` |
| `fulfill` | `0.8 ~ 1.2` | `0.8 ~ 1.2` |
| `underbid` | `> 1.2` | `> 1.2` |

当 `advv_w = 0` 时，结果归类为 `noadvv`。

变量定义：

| 记号 | 含义 |
| --- | --- |
| `cost_w` | 窗口内实际消耗 |
| `advv_w` | 窗口内实际 `advv` |
| `cost_ratio_coef` | `algo` 口径使用的系数参数 |

`algo` 口径：

```text
achievement_ratio_a(w) = advv_w / cost_w * cost_ratio_coef
overbid:  < 0.8
fulfill:  0.8 ~ 1.2
underbid: > 1.2
```

`seller` 口径：

```text
achievement_ratio_s(w) = advv_w / cost_w
overbid:  < 0.8
fulfill:  0.8 ~ 1.2
underbid: > 1.2
```

##### 2.2.3 命名规则

命名模式：

```text
{state}_{window}_{view}
```

其中：

- `window ∈ {1d, 7d}`
- `view ∈ {a, s}`
- `a = algo`
- `s = seller`

##### 2.2.4 聚合口径

在同一统计分组内：

```text
state_period_cost_prop = state_period_cost / total_cost
state_period_ads_prop  = state_period_ads  / ad_cnt
```

状态含义：

| 状态 | 含义 |
| --- | --- |
| `overbid` | 实际 `advv` 相对 `cost` 偏低 |
| `fulfill` | 实际 `advv` 相对 `cost` 落在目标区间内 |
| `underbid` | 实际 `advv` 相对 `cost` 偏高 |
| `noadvv` | 窗口内 `advv = 0` |

## Technical

### 1. 技术总览

#### 1.1 反馈闭环主链路

`广告参与竞价和混排 -> 广告下发真实环境并产生真实行为 -> 收集并聚合后验数据 -> 近线调控 -> 在线实时出价`

主链路说明：

`广告参与竞价和混排`

- 广告侧在在线请求中参与出价、排序，并输出参与混排
- 功能由 `Ads Engine` 在线投放链路和 SRA 引擎模块承接

`广告下发真实环境并产生真实行为`

- 混排后的广告进入真实流量环境
- 用户产生 `impression`、`click`、`conversion`、`order` 等行为

`收集并聚合后验数据`

1. 请求和混排结果落到 `searchlog` 等请求侧日志
2. 行为结果落到 `tracking`、`translog`、`order` 等行为日志
3. `ultrav-data-processor` 消费后验事件并生成统一事件对象
4. `ultrav-data-aggregator` 聚合时间窗指标并写入 Redis

`近线调控`

- 读取时间窗指标和环境模型结果
- 评估候选 `coef` 的未来结果
- 输出新的系数或相关调控结果
- 主要由 `ultrav-core-timewindow` 实现

`在线实时出价`

- 在单次请求内读取广告候选、预估信号、预算状态、实验信息和已装载系数
- 完成实时出价公式计算和编排
- 输出 `bidValue`、`eCPM`、`deduction` 相关结果
- 主要由 `online-bidding` 实现

#### 1.2 环境模型副链路

`收集并聚合后验数据 -> 环境模型样本 -> 环境时序模型 -> 近线调控`

副链路说明：

- 环境模型样本由聚合后的后验数据和模拟出价结果整理得到
- `bidding_env` 提供模型定义和训练入口
- `sequence-model-processor` 负责统计模型和深度模型推理，并把结果写入 Redis
- 统计模型不依赖训练产物
- 深度模型依赖训练产物
- 推理阶段由 `sequence-model-processor` 选择广告集合，调用 `EGO` 推理服务，并写入 Redis
- `FuncModel` 位于 `ultrav-core-timewindow` 内部

#### 1.3 在 SRA 在线链路中的位置

在 SRA 的 GMV MAX 融合链路中：

`req -> recall -> prerank -> ranking -> mix rank`

Ads 链路通过 `API0` 到 `API3` 与 Organic 交互：

| API | Organic 阶段位置 | Ads 侧作用 | 输出 |
| --- | --- | --- | --- |
| `API0` | `recall` | 广告召回 | 广告候选集 |
| `API1` | `recall` 之后、`ranking` 之前 | 补充广告正排信息 | `ads infos` |
| `API2` | `ranking` 之后、`mix rank` 之前 | 出价与策略计算 | `bidValue`、`eCPM` |
| `API3` | `mix rank` 之后 | 扣费、tracking 和 deduction | `deduction result` |

### 2. 在线实时出价

#### 2.1 请求入口与 Rerank

产品广告在线出价入口为 `Rerank(ctx, req)`。

处理流程：

1. 校验请求合法性
2. 构建 `ReqOption`
3. 把广告列表转换为内部 `AdData`
4. 进入 `DoRerank`
5. 输出 `RerankAdsResponse`

`DoRerank` 的阶段顺序如下：

1. `rerankModel`
2. `rerankPrepare`
3. `rerankVoucher`
4. `rerankBidding`
5. `rerankVoucherNew`
6. `rerankCalculatePadvv`
7. `rerankSubsidy`
8. `rerankDeduction`
9. `rerankFinalization`

阶段职责包括：

- `rerankModel`、`rerankPrepare`：准备出价上下文和模型输入
- `rerankBidding`：执行核心出价计算
- `rerankDeduction`：处理 deduction 相关结果
- `rerankFinalization`：组装最终响应

#### 2.2 请求输入与 AdData

`BuildAdsDataForRerank` 将外部请求装载到内部 `AdData`。

输入类别包括：

| 类别 | 字段示例 |
| --- | --- |
| 广告基础信息 | `ads_id`、`item_id`、`shop_id`、`campaign_id` |
| 预估信号 | `pctr`、`pcr`、`uni_pcr` |
| 投放属性 | `pricing_type`、`placement` |
| 预算与状态 | `remain_budget_rt`、`budget_usage_ratio` |
| bucket 信息 | `plan_bucket`、`plan_bucket_list` |
| 系数信息 | `ad_coef_infos` |
| 其它上下文 | voucher / subsidy / crowd 相关信息 |

内部对象包括：

- `ReqOption`：请求级上下文和处理选项
- `AdData`：单广告级别的实时出价输入

`ad_coef_infos` 当前包含以下字段：

- `coef_type`
- `id_type`
- `coef`
- `entrance_coef`
- `extra`
- `last_update_time`

#### 2.3 bidding-store 与系数读取

`bidding-store` 是在线实时出价链路外部的系数服务。

`GetAdCoef` 的处理流程：

1. 校验 `country`、`request_id`、`ads_info`
2. 构建内部 request / response
3. 调用统一 handler 处理 `HandleGetAdCoefRequest`
4. 返回 `AdCoefResponse`

读取能力包括：

- 对外提供 `GetAdCoef`
- 支持本地缓存
- 支持本地缓存与 Redis 回源
- 支持 full load 和 warmup

读取行为包括：

- 非 full load 模式下优先查本地缓存
- bucket 级 key 缺失时回退到 `global bucket`
- full load 支持 warmup、周期刷新和手动刷新

当前可确认边界：

- `bidding-store` 提供系数读取能力
- `online-bidding` 消费已装载到请求中的系数

#### 2.4 online-bidding 与引擎边界

`online-bidding` 对应在线实时出价执行阶段，负责：

- 读取广告候选和请求上下文
- 读取预估信号、预算状态、实验信息和系数
- 完成请求级实时出价编排
- 输出 `bidValue`、`eCPM` 和 `deduction` 结果

与 Ads Engine 的边界包括：

- `API0`：广告召回，不属于 `online-bidding`
- `API1`：Ads Info，不属于 `online-bidding`
- `API2`：出价与策略计算，直接关联 `online-bidding`
- `API3`：deduction 与 tracking 相关计算，与 `online-bidding` 输出衔接

### 3. 反馈数据

#### 3.1 日志来源与后验事件

后验数据链路包含两类日志：

- 请求侧日志：`searchlog` 等请求侧日志
- 行为侧日志：`tracking`、`translog`、`order` 等行为日志

反馈闭环直接关注以下事件类型：

- `impression`
- `click`
- `conversion`
- `order`

行为日志的事件语义包括：

- `tracking`：原始曝光、原始点击
- `translog`：扣费曝光、扣费点击、扣费下单
- `order`：归因订单

#### 3.2 ultrav-data-processor

`ultrav-data-processor` 位于行为日志之后、聚合服务之前。

职责包括：

- 接入投放后的后验事件
- 将原始行为日志转换为统一事件对象
- 作为 `aggregator` 的上游事件来源

事件接入行为包括：

- 通过 EKL consumer 消费 Kafka
- 支持单 consumer 和多国家 consumer
- 使用 `AdvancedConsumer`
- `Dispatcher = Random`
- `WorkerNum = 1000`
- 默认 `RateLimitPerSecond = 5000`

#### 3.3 ultrav-data-aggregator

`ultrav-data-aggregator` 的职责包括：

- 消费 enriched `TrackingEvent`
- 聚合时间窗指标
- 把指标写入 Redis
- 把聚合结果提供给 `ultrav-core` / `ultrav-core-timewindow`

数据流包括：

1. 从 Kafka 消费 `TrackingEvent`
2. `Transform()` 解析 JSON
3. `SumChecker.Exists()` 去重
4. `ProcessTrackingEvent()` 生成指标
5. `MetricWriter` 或 `LocalAggregator` 写 Redis

事件标准化包括：

- JSON 反序列化为 `TrackingEvent`
- 解析 `GroupKeysMap`
- 基于 `SumChecker.Exists()` 去重
- 解析 `BidRerankTrace`

写入语义包括：

- 普通 key 直接进入 `MetricWriter`
- hot key 先进入 `LocalAggregator`
- Redis 写入支持 global 与 country-specific dual-write

Redis 操作类型包括：

- `COUNT`
- `SCALAR`
- `HASH`
- `FEEDBACK`

#### 3.4 时间窗指标

时间窗指标至少包含以下维度：

- 指标名
- 时间窗标记
- 分组键字符串
- 可选 `plan bucket` / `traffic bucket`

核心指标类型包括：

- `impression`
- `click`
- `conversion`
- `order`
- `GMV`
- `cost`
- `revenue`
- `ROI`
- `ROAS`

时间窗类型包括：

- `history`
- `date`
- `hour`
- `minute`
- `quarter`
- `every minute`

Redis key 结构包括：

- metric name
- time window string
- group key string
- 可选 `plan bucket id`
- 可选 `traffic bucket id`

下游用途包括：

- 近线调控
- 环境模型样本整理和训练

#### 3.5 时效性与回流

反馈链路具有异步时效性。

已知事实包括：

- 后验数据通过投放后的异步处理链路回流
- 数据完整性受回流延迟和观测窗口影响
- 同一广告在跨天窗口内仍可能收到新的后验事件

时效性来源包括：

- 广告先进入真实流量环境，再产生后验行为
- 后验行为先写日志，再进入 `processor` 和 `aggregator`
- `aggregator` 对 hot key 采用 9 到 10 秒本地缓冲

相关语境包括：

- 回流
- 滞留效应
- 跨天窗口
- 回流率预估

### 4. 近线调控

#### 4.1 角色与边界

近线调控位于 `收集并聚合后验数据` 之后、`在线实时出价` 之前。

职责包括：

- 读取时间窗指标和运行时配置
- 结合环境时序模型评估候选 `coef`
- 基于 `MPC` 和 evaluator 选择最终调控结果
- 将结果交给输出链路写入下游

上游包括：

- 聚合后的时间窗指标
- 环境时序模型输出

下游为请求级实时出价执行阶段。

主要实现模块为 `ultrav-core-timewindow`。

#### 4.2 输入与状态

近线调控直接依赖以下输入：

- 聚合后的时间窗指标
- 广告状态
- 预算状态
- 配置和实验信息
- 环境时序模型输出

搜索参数包括：

- `coef_min`
- `coef_max`
- `mpc_step_cnt`

预算相关预测结果包括：

- `PredictCost`
- `PredictGmv`
- `PredictCostCali`
- `PredictGmvCali`
- `HitBudgetSlot`

#### 4.3 MPC 搜索与决策

`MPC` 的基本过程：

1. 枚举候选 `coef`
2. 对每个候选 `coef` 生成未来结果
3. evaluator 做比较和选择

搜索流程包括：

1. 读取 `coef_min`、`coef_max`、`mpc_step_cnt`
2. 计算 step
3. 对每个候选 `coef` 调用 `validModel.Predict(coef)`
4. 调用 `evaluator.Evaluate(coef, predictResult)`
5. 记录最优 `coef` 和 `PredictResult`
6. 把最优结果交给后续 `postProcess` 和 `wrapOutput`

当新候选分数 `>=` 当前最优分数时，会更新最优结果。

#### 4.4 bid2x 与校准

`bid2x` 表示在给定广告当前状态和候选 `coef` 条件下，预测后续时间窗内结果量或结果轨迹的过程。

常见结果量包括：

- `req_num`
- `cost`
- `gmv`
- `imp`
- `win_ratio`

近线主链路直接消费：

- `bid2cost`
- `bid2gmv`

校准链路包括：

- 基础预测
- `RecentFeature / P2P` 校准
- `P2R` 校准
- 预算截断后的最终结果

处理顺序包括：

1. `scatter.Inference(slot, coef)` 生成 `slot` 级原始结果
2. 应用 `P2P`
3. 应用 `P2R` 和预测值校准系数
4. 在预算约束下计算 `costTodayCapBudget` 和 `gmvTodayCapBudget`
5. 生成 `PredictCostCali`、`PredictGmvCali` 和 `HitBudgetSlot`

#### 4.5 输出与交付

`ultrav-core-timewindow` 负责输出调控结果。

`ProcessOutput` 的主线如下：

1. 校验 `ExpOutput`
2. 生成 trace
3. 计算实验名和国家维度
4. 顺序执行 `output writers`
5. 输出监控

输出 writer 包括：

- `output_redis`
- `output_databus`
- `output_kafka_producer`

配置与交付约束包括：

- 先拉取最新线上配置到 `online_config/global/`
- 只在 `online_config/global_update/` 落配置改动
- 不直接修改 `online_config/global/`
- 测试时通过 `debug/test_config/*.json` 驱动 verifier

### 5. 环境时序模型

#### 5.1 概述

环境模型副链路位于 `收集并聚合后验数据` 与 `近线调控` 之间。

链路可表示为：

`聚合后的后验数据 -> 环境模型样本 -> 环境时序模型 -> 推理服务 -> timewindow -> MPC`

模块包括：

- `bidding_env`：模型定义、训练入口、流量回放脚本示例
- `sequence-model-processor`：选择广告集合、调用 `EGO` 推理服务、写入 Redis
- `ultrav-core-timewindow`：模型注册、结果消费和 `MPC`

模型类型包括：

- `统计模型`
- `深度模型`
- `函数模型`

其中：

- `统计模型` 不依赖训练产物
- `深度模型` 依赖训练产物
- `函数模型` 位于 `ultrav-core-timewindow` 内部，不经过样本训练副链路

#### 5.2 样本与流量回放

环境模型样本由聚合后的后验数据和模拟出价结果整理得到。

回放脚本输出字段包括：

- `ads_id`
- `coef`
- `tr_pgmv`
- `tr_pv`
- `tr_pctr`
- `tr_ecpm_2`
- `tr_pctcvr`
- `req_num`

流量回放流程包括：

1. 读取指定时间窗内的 `search_log` 请求数据
2. 读取同一时间窗内的 tracking 曝光数据
3. 按 `request_id` 合并请求侧排序信息和曝光结果
4. 对目标广告按候选 `coef` 重算 `rank_score` 和新排名
5. 结合曝光向量和最大曝光位次判断是否获得曝光
6. 输出按候选 `coef` 组织的回放记录

流量回放规则包括：

- 遍历 `coefList = [0.25, 0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0, 4.0]`
- 对请求内广告按 `rank_score` 降序排序
- 根据候选 `coef` 重算目标广告的新 `rank_score`
- 使用二分查找定位新排名
- 基于相邻 `rank_score` 估算 `tr_ecpm_2`

#### 5.3 统计模型

统计模型属于环境模型副链路，不依赖训练产物。

统计模型在 `bidding_env` 中的实现名为 `stats`。

统计模型在 `ultrav-core-timewindow` 中的近线模型名为 `gmv_max_stat_model`。

统计模型输入包括：

- 序列特征
- 候选 `coef` 特征
- 时间特征

统计模型使用 `SingleWindowFeatureExtractor` 组织输入。

预测逻辑包括：

1. 读取序列特征、候选 `coef` 特征和时间特征
2. 使用 `weighted_average_forecast_with_mask` 计算请求量和候选 `coef` 相关特征
3. 输出未来 `num_steps` 个 `slot` 的结果张量

#### 5.4 深度模型

深度模型属于环境模型副链路，依赖训练产物。

深度模型实现名包括：

- `Transm`
- `EncDec`
- `WinRatioEncDecNoAutoRegressive`
- `cost_gmv_v1`
- `DLinearReq`

深度模型在 `ultrav-core-timewindow` 中的近线模型名为 `gmv_max_deep_model`。

深度模型输入包括：

- `FSE` 特征
- 时间特征
- 广告特征
- 候选 `coef` 相关特征

`env_new_v1x3` 中的主要输入包括：

- 广告和类目特征
- `timeslot` 时间特征
- `ads_req_num`、`ads_pv`、`ads_pctr`、`ads_pctcvr` 等历史序列
- 按候选 `coef` 和 `entrance` 组织的 `gmv`、`cost`、`win_num` 特征

深度模型设计内容包括：

- 以时间序列窗口作为输入
- 以候选 `coef` 和未来 `slot` 作为输出组织维度
- 以请求量、成本、GMV、`win_ratio` 等结果量作为预测对象

结构类型包括：

- 自回归 Transformer
- 编码器-解码器结构
- 非自回归 `win_ratio` 结构
- `cost/gmv` 级联结构
- 请求量预测结构

#### 5.5 时序模型推理服务与流程

统计模型和深度模型使用同一条推理链路。

`sequence-model-processor` 执行统计模型和深度模型推理。

推理流程包括：

1. 定时触发推理任务
2. 通过 Redis lock 抢占任务分片
3. 获取目标广告集合，并按 `adsId` 尾号和并发数切分任务
4. 组装共享特征表、可迭代表和 `AFP item context table`
5. 调用 `uranker` / `EGO` 推理服务
6. 将结果封装为 `TimeSlot2X` protobuf，并通过 `PipeSet` 批量写入 Redis

统计模型和深度模型都使用 `EGO` 侧 `FSE` 特征。

`sequence-model-processor` 使用以下特征 provider：

- `shared table`
- `iterable table`
- `AFP item context table`

输出 key 形态如下：

- `<model_prefix>_<placement>_<country>_<entrance>_<adsId>`

输出 value 为 `TimeSlot2X` protobuf，内容按 `slot -> coef -> predict values` 组织。

#### 5.6 接入 timewindow

`ultrav-core-timewindow` 注册以下近线模型：

- `gmv_max_stat_model`
- `gmv_max_deep_model`

接入流程包括：

1. `sequence-model-processor` 将环境模型结果写入 Redis
2. `ultrav-core-timewindow` 通过已注册模型读取结果
3. `baseTsModel` 对每个 `slot` 和候选 `coef` 调用 `scatter.Inference(slot, coef)`
4. `baseTsModel` 应用 `P2P`、`P2R` 和预算处理
5. `baseTsModel` 输出 `PredictResult`
6. `MPC` 使用 `PredictResult` 执行搜索和决策

`StatModel` 和 `DeepModel` 共享 `baseTsModel`。

#### 5.7 函数模型

`FuncModel` 位于 `ultrav-core-timewindow` 内部，不经过样本训练副链路。

输入特征包括：

- 历史多天聚合特征
- `last24h` 特征
- `OriginCoef`、`Cost`、`PGMV`、`BroadGmv`
- `Click`、`BroadOrder`
- 预算状态

有效性条件包括：

- `click threshold`
- `order threshold`
- `featureUsePvalue`

`FuncModel` 生成以下特征：

- `FeatureCoef`
- `FeatureCost`
- `FeatureGmv`

特征准备步骤包括：

1. 对多天数据和 `last24h` 数据做指数加权
2. 计算 `FeatureCoef`
3. 计算 `FeatureCost` 和 `FeatureGmv`
4. 应用 `P2R` 校准
5. 应用预算命中调整

预测逻辑使用以下公式：

- `cost = FeatureCost * (coef / FeatureCoef) ^ exponent`
- `gmv = FeatureGmv * (coef / FeatureCoef) ^ (exponent - 1)`

预测步骤包括：

1. 计算 1 天成本和 GMV 预测值
2. 根据 `CDF` 计算当日剩余时段预测值
3. 根据剩余预算计算预算截断后的预测值
4. 输出 `PredictResult`

### 6. 算法数据分析

#### 6.1 Plan Bucket 与分桶机制

请求中会携带 `plan_bucket`、`plan_bucket_list`。

bucket 信息属于实验或分桶上下文。

`bidding-store` 的 bucket 级 key 缺失时，会回退到 `global bucket`。

尾号实验机制包括：

1. `adsinfo` 生成 `plan bucket`
2. 数据收集按继承方式处理
3. `ultrav trigger` 监听指定 `plan bucket`
4. `bidding-store` 按既有 key 读取系数
5. `engine` 读取唯一 `coef`，失败时回退到 `global`

预算分桶机制包括：

1. `adsinfo` 生成 `plan bucket`
2. AB 平台流量侧提供 `traffic bucket`
3. 数据收集按 `plan bucket + traffic bucket` 组织
4. 后验读取带 `traffic bucket`
5. `bidding-store` 的 key 带 `traffic bucket`
6. `engine` 读取 `coef` 时传递 `traffic bucket`

Layer 语义包括：

- `Layer1`：出价层
- `Layer2`：非出价层
- `layer id = 1`：可承载预算分桶
- 其它 `layer`：只做尾号实验

bucket 公式如下：

```text
bucket id = {pricing type} * 1e2 + {layer id} * 1e1 + {bucket number}
```

流量切分规则包括：

- `小流量分桶` 固定为 1% 的桶
- `大分桶` 承接剩余流量
- `大桶流量 = (100% - 小流量分桶数量 * 1%) / 大分桶数量`

#### 6.2 数据分析用表

本节记录 `offline_jobs/sqls` 中已登记的 Product Ads 分析表和核心取数 SQL。

##### 6.2.1 表总览

| 类别 | 表 | 粒度 | 主要用途 |
| --- | --- | --- | --- |
| tracking 原始表 | 待补充 | 原始行为事件 | 原始曝光、点击和行为事件排查 |
| performance 原始表 | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | `date + region + ads + placement + entrance` | 后验曝光、点击、下单、消耗、GMV 和在线 trace 分析 |
| ads algo 日报告表 | `mkplpaidads_search_ads.daily_target2_algo_dim_ads` | `date + region + ads + placement + plan` | `Target ROI2` 日级广告效果、预算、achievement 统计 |
| ads algo 日报告表 | `mkplpaidads_search_ads.daily_simple2_algo_dim_ads` | `date + region + ads + placement + plan` | `Simple ROI2` 日级广告效果、预算、achievement 统计 |
| ads algo 日报告表 | GMS 日报告表待补充 | `date + region + ads` | `GMS` 日级广告效果分析 |
| perf 天级 ads 小表 | `mkplpaidads_search_ads.roi2_ads_perf_adv` | `date + region + ads + placement + pricing_type` | 天级广告效果指标、预估指标和目标 CIR 汇总 |
| tracking 小时级 ads 小表 | `mkplpaidads_search_ads.roi2_tracking_by_ads_hourly` | `date + hour + region + ads + placement` | 小时级出价、扣费、预估和 MPC 输出分析 |
| ultrav-core 表 | `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live` | `date + hour + region + strategy + group_key` | `ultrav-core-timewindow` 调控 trace、预算命中和输出系数分析 |

##### 6.2.2 主要字段含义

| 表 | 字段 | 含义 |
| --- | --- | --- |
| `dwd_advertise_performance_di__reg_s0_live` | `grass_date`、`grass_region` | 本地日期和国家 |
| `dwd_advertise_performance_di__reg_s0_live` | `tz_type` | 时区口径，常用过滤为 `local` |
| `dwd_advertise_performance_di__reg_s0_live` | `pricing_type`、`placement`、`entrance` | 投放类型、版位和入口 |
| `dwd_advertise_performance_di__reg_s0_live` | `ads_id` | 广告 ID |
| `dwd_advertise_performance_di__reg_s0_live` | `impression_cnt`、`click_cnt`、`broad_order_cnt` | 曝光、点击和 broad order |
| `dwd_advertise_performance_di__reg_s0_live` | `expenditure_amt_usd`、`broad_gmv_amt_usd` | 美元口径消耗和 broad GMV |
| `dwd_advertise_performance_di__reg_s0_live` | `target_cir` | 目标 CIR，用于从 GMV 口径折算 `advv` |
| `dwd_advertise_performance_di__reg_s0_live` | `bid_rerank_trace` | 在线出价 trace，常用于解析 `pgmv`、`adjust_bid`、`pid_coef` |
| `daily_target2_algo_dim_ads` | `plan_id`、`campaign_id`、`ads_id` | 计划、活动和广告 ID |
| `daily_target2_algo_dim_ads` | `status_tag` | 广告状态标签，常用过滤为 `normal` |
| `daily_target2_algo_dim_ads` | `impression_1d`、`click_1d`、`cost_usd_1d` | 1 天曝光、点击和消耗 |
| `daily_target2_algo_dim_ads` | `broad_order_1d`、`broad_gmv_usd_1d`、`advv_usd_1d` | 1 天订单、GMV 和 advv |
| `daily_target2_algo_dim_ads` | `cost_usd_7d`、`broad_gmv_usd_7d`、`advv_usd_7d` | 7 天消耗、GMV 和 advv |
| `daily_target2_algo_dim_ads` | `valid_budget_usd` | 有效预算 |
| `daily_simple2_algo_dim_ads` | `sug_troi_lower_bound`、`sug_troi_upper_bound` | Simple ROI2 的目标 ROI 下界和上界 |
| `daily_simple2_algo_dim_ads` | `budget_tier` | 预算分层标签 |
| `daily_simple2_algo_dim_ads` | `advv` | Simple ROI2 日报告中的广告主价值指标 |
| `roi2_ads_perf_adv` | `metric['imp']`、`metric['click']`、`metric['cost']` | 天级曝光、点击和消耗 |
| `roi2_ads_perf_adv` | `metric['advv']`、`metric['broad_order']`、`metric['broad_gmv']` | 天级 advv、订单和 GMV |
| `roi2_ads_perf_adv` | `metric['pgmv']`、`metric['padvv']`、`metric['sum_target_cir']` | 天级预估 GMV、预估 advv 和目标 CIR 汇总 |
| `roi2_tracking_by_ads_hourly` | `h` | 小时 |
| `roi2_tracking_by_ads_hourly` | `imp_cnt`、`click_cnt` | 小时级曝光和点击 |
| `roi2_tracking_by_ads_hourly` | `metric_sum_on_imp['pid_coef']`、`metric_sum_on_imp['origin_coef']`、`metric_sum_on_imp['underbid_coef']` | 曝光侧出价系数 |
| `roi2_tracking_by_ads_hourly` | `metric_sum_on_imp['bid_price']`、`metric_sum_on_imp['deduction_price']` | 曝光侧出价和扣费价格 |
| `roi2_tracking_by_ads_hourly` | `metric_sum_on_click['deduction_price']` | 点击侧扣费价格，用于汇总后验 `cost` |
| `roi2_tracking_by_ads_hourly` | `metric_sum_on_imp['target_cir']` | 曝光侧目标 CIR 汇总，用于计算平均目标 ROI |
| `roi2_tracking_by_ads_hourly` | `metric_sum_on_imp['pctr']`、`metric_sum_on_imp['pgmv']` | 曝光侧 pCTR 和 pGMV 汇总 |
| `roi2_tracking_by_ads_hourly` | `metric_sum_on_imp['mpc_e_cost']`、`metric_sum_on_imp['mpc_e_gmv']` | MPC 输出的预估 cost 和 GMV |
| `dwd_trace_bidding_hyperx_hi__reg_s0_live` | `project_name`、`strategy_name`、`event_type`、`version` | trace 所属项目、策略、事件和版本 |
| `dwd_trace_bidding_hyperx_hi__reg_s0_live` | `emission_timestamp` | trace 产生时间戳 |
| `dwd_trace_bidding_hyperx_hi__reg_s0_live` | `group_key_map` | 分组键，常用于解析 `ads_id`、`placement`、`pricing_type` |
| `dwd_trace_bidding_hyperx_hi__reg_s0_live` | `output_param` | 输出参数，常用于解析最终 `coef` |
| `dwd_trace_bidding_hyperx_hi__reg_s0_live` | `extra_json` | 调控 trace，常用于解析预算、历史指标、模型选择、预测值和预算命中状态 |

##### 6.2.3 核心 SQL

performance 原始表常用取数：

```sql
select
    grass_date, grass_region, pricing_type, placement, ads_id,
    coalesce(impression_cnt, 0.0) as imp,
    coalesce(click_cnt, 0.0) as click,
    coalesce(broad_order_cnt, 0.0) as broad_order,
    coalesce(expenditure_amt_usd, 0.0) as cost,
    coalesce(broad_gmv_amt_usd, 0.0) as broad_gmv,
    coalesce(target_cir, 0.0) as target_cir,
    bid_rerank_trace
from mp_paidads.dwd_advertise_performance_di__reg_s0_live
where tz_type = 'local'
  and grass_region = '${region}'
  and placement = ${placement}
  and grass_date >= date('${date_begin}')
  and grass_date <= date('${date_end}')
```

ads algo 日报告常用取数：

```sql
select
    grass_date, grass_region, placement, plan_id, campaign_id, ads_id,
    impression_1d, click_1d, cost_usd_1d,
    broad_order_1d, broad_gmv_usd_1d, advv_usd_1d,
    cost_usd_7d, broad_gmv_usd_7d, advv_usd_7d,
    valid_budget_usd
from mkplpaidads_search_ads.daily_target2_algo_dim_ads
where status_tag = 'normal'
  and grass_region in (${regions})
  and grass_date >= date('${date_begin}')
  and grass_date <= date('${date_end}')
```

perf 天级 ads 小表常用取数：

```sql
select
    grass_date, grass_region, placement, pricing_type, ads_id,
    metric['imp'] as imp,
    metric['click'] as click,
    metric['cost'] as cost,
    metric['advv'] as advv,
    metric['broad_order'] as broad_order,
    metric['broad_gmv'] as broad_gmv,
    metric['pgmv'] as pgmv,
    metric['padvv'] as padvv,
    metric['sum_target_cir'] as sum_target_cir
from mkplpaidads_search_ads.roi2_ads_perf_adv
where entrance = -1
  and grass_region = '${region}'
  and placement = ${placement}
  and grass_date >= date('${date_begin}')
  and grass_date <= date('${date_end}')
```

tracking 小时级 ads 小表常用取数：

```sql
select
    grass_date, grass_region, placement, ads_id, h,
    sum(imp_cnt) as imp_cnt,
    sum(click_cnt) as click_cnt,
    sum(metric_sum_on_imp['pid_coef']) / sum(imp_cnt) as avg_pid_coef,
    sum(metric_sum_on_imp['bid_price'] / exchange) / sum(imp_cnt) as avg_bid_price,
    sum(metric_sum_on_click['deduction_price'] / exchange) as sum_cost,
    1 / (sum(metric_sum_on_imp['target_cir']) / sum(imp_cnt)) as avg_target_roi,
    sum(metric_sum_on_imp['mpc_e_cost'] / exchange) / sum(imp_cnt) as avg_mpc_e_cost,
    sum(metric_sum_on_imp['mpc_e_gmv'] / exchange) / sum(imp_cnt) as avg_mpc_e_gmv
from mkplpaidads_search_ads.roi2_tracking_by_ads_hourly
where grass_region = '${region}'
  and placement = ${placement}
  and grass_date >= date('${date_begin}')
  and grass_date <= date('${date_end}')
  and entrance != 999
group by 1, 2, 3, 4, 5
```

ultrav-core trace 表常用取数：

```sql
select
    from_unixtime(emission_timestamp / 1000 + hour_diff * 3600) as local_trigger_time,
    cast(element_at(group_key_map, 'ads_id') as bigint) as ads_id,
    event_type,
    strategy_name,
    round(cast(json_extract_scalar(element_at(output_param, '0'), '$.coef') as double), 6) as final_coef,
    cast(json_extract(extra_json, '$.ads_info.target_roi_lower') as double) as target_roi_lower,
    cast(json_extract(extra_json, '$.ads_info.target_roi_upper') as double) as target_roi_upper,
    cast(json_extract(extra_json, '$.post_processor.hit_budget_cap') as boolean) as hit_budget_cap,
    extra_json as trace
from mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live
where grass_date >= date'${date_begin}'
  and grass_date <= date_add('day', 1, date'${date_end}')
  and project_name = 'ultrav_core_timewindow'
  and strategy_name like 'planid_${strategy_regex}'
  and grass_region = '${region}'
```

##### 6.2.4 模型分析补充表

| 表 | 主要字段 | 用途 |
| --- | --- | --- |
| `mkplpaidads_search_ads.mpc_ts_model_pcoc_daily` | `real_pcost`、`real_cost`、`real_pgmv`、`real_gmv`、`slot_cost_*_sum_capped`、`slot_gmv_*_sum_capped` | 环境模型 `cost/gmv/roi` 预测校准评估 |
| `mkplpaidads_search_ads.mpc_model_snapshot` | `model_name`、`placement`、`model_info` | 模型输出快照展开，解析 `ads_id`、`slot_id`、`coef`、`req_num`、`imp`、`cost`、`gmv`、`roi` |
| `mkplpaidads_search_ads.mpc_model_check` | `model_name`、`placement`、`metrics` | 模型检查指标，解析全零、单调性和 ROI 形态指标 |

## Engineering

### 1. 服务总表

| 服务 | 角色 | 关键入口 |
| --- | --- | --- |
| `service/online-bidding/online-bidding` | 在线请求级出价编排 | `internal/handler/product_ads.go` |
| `service/infra/bidding-store` | 系数读取服务 | `internal/handler/productads/main.go` |
| `service/ultrav-data-processor/ultrav-data-processor` | 后验事件接入 | `pkg/handler/event_handler.go` |
| `service/ultrav-data-aggregator/ultrav-data-aggregator` | 时间窗指标聚合 | `pkg/services/stats_processor/processor.go` |
| `service/ultrav-core/ultrav-core` | bidding framework | `README.md` |
| `service/ultrav-core-timewindow` | 时间窗配置、验证和调控结果输出 | `README.md`、`CONFIG_WORKFLOW.md`、`src/internal/service/output_processor/output_processor.go` |
| `service/infra/common` | 公共类型和通用能力 | `README.md`、`types/` |

### 2. 在线路径

#### 2.1 online-bidding

- 角色：在线请求级出价编排
- 关键入口：`internal/handler/product_ads.go`、`internal/handler/stage/productads/handle_rerank.go`
- 主要目录：`handler`、`stage`、`rule`

#### 2.2 bidding-store

- 角色：系数读取服务
- 关键入口：`internal/handler/productads/main.go`、`internal/storage/query_caches_and_update.go`、`internal/storage/full_load.go`
- 主要目录：`handler`、`storage`、`monitoring`

### 3. 反馈路径

#### 3.1 ultrav-data-processor

- 角色：后验事件接入
- 关键入口：`pkg/handler/event_handler.go`、`server/product_ads/main.go`
- 主要目录：`event handler`、`processor`、`server`

#### 3.2 ultrav-data-aggregator

- 角色：时间窗指标聚合
- 关键入口：`pkg/handler/`、`pkg/services/metric_generator/`、`pkg/services/metric_writer/`、`pkg/services/stats_processor/`
- 主要目录：`handler`、`metric_generator`、`metric_writer`、`stats_processor`

### 4. 调控与配置路径

#### 4.1 ultrav-core

- 角色：bidding framework
- 关键入口：`README.md`

#### 4.2 ultrav-core-timewindow

- 角色：时间窗配置、验证和调控结果输出
- 关键入口：`README.md`、`CONFIG_WORKFLOW.md`、`src/internal/service/output_processor/output_processor.go`
- 主要目录：`src/`、`online_config/`、`debug/test_config/`、`debug/tools/run_remote.sh`

#### 4.3 infra/common

- 角色：公共类型和通用能力
- 关键入口：`README.md`、`types/`

## 附录

### 1. 术语表

#### 链路术语

`Rerank`

- 产品广告在线请求级处理入口，对应 `RerankAdsRequest -> RerankAdsResponse`

`DoRerank`

- 产品广告多阶段处理流水线的主编排函数

`GetAdCoef`

- 系数读取接口

`TrackingEvent`

- `ultrav-data-aggregator` 消费的事件载体
- 来自 `ultrav-data-processor` 产出的 enriched tracking event

#### 指标与信号

`pCTR`

- 点击率预估信号

`pCR`

- 转化相关预估信号

`pGMV`

- GMV 预估信号

`imp`

- 广告获得的曝光量
- 在 `bid2x` 语义中，`imp` 可定义为结果量

`req_num`

- 请求量结果
- 在 `bid2x` 语义中，`req_num` 可定义为结果量

`win_num`

- 离线回放中的竞得数量

`win_ratio`

- `win_num / req_num` 形式的竞得比例结果量

`eCPM`

- 广告排序的核心比较单位

`coef`

- 进入在线出价路径、用于调控出价或相关中间量的系数集合

`bid2x`

- 近线 `MPC` 语境下的结果预测能力
- 给定广告当前状态和候选 `coef`，预测后续时间窗内的结果量或结果轨迹

`StatModel`

- `MPC` 近线调控主用的统计模型实现
- `StatModel` 按 `time slot` 组织散点数据，通过 `PCHIP` 插值从 `coef` 预测一组结果量

`achievement`

- 广告在给定统计窗口和给定口径下，相对业务目标所处的状态

#### 产品与模式

`Target ROI2`

- 目标 ROAS 型自动出价产品

`Simple ROI2`

- 简化版自动出价产品

`Manual CPC`

- 手动出价模式

`Manual eCPC`

- 增强手动出价模式

#### 调控与配置

`plan bucket`

- 承载实验分桶语义的桶号标识

`尾号实验`

- 围绕 `plan bucket` 做实验路由的一类分桶实验

`大分桶`

- 承接主流量的常规实验桶

`小流量分桶`

- 固定 1% 粒度的小流量实验桶

`timewindow`

- 以时间窗指标、配置读取和输出处理为核心的近线调控目录 `service/ultrav-core-timewindow`

`global`

- `timewindow` 配置目录中的线上快照目录 `online_config/global/`

`global_update`

- `timewindow` 配置目录中的本地拟修改目录 `online_config/global_update/`

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
| `docs/common/core-knowledge/` (原单体文件，已拆分迁入) | 仓库 markdown | Ads 总览、链路、指标、GMV Max 背景 | `L2` | `used` | 总览、业务和技术文档的 Ads 链路来源 |
| `algo_jobs/ads-workspace/ads-workspace/sra-toolkit/skills/sra-glossary/references/service-topology.md` | 仓库 markdown | SRA 服务拓扑、Organic 与 Ads API 交互 | `L2` | `used` | 技术总览的 SRA 链路来源 |
| `service/online-bidding/online-bidding/internal/handler/product_ads.go` | 代码 | 产品广告在线出价入口 | `L1` | `used` | `Rerank` 入口 |
| `service/online-bidding/online-bidding/internal/handler/stage/productads/handle_rerank.go` | 代码 | 在线出价阶段编排 | `L1` | `used` | `DoRerank` 阶段顺序 |
| `service/online-bidding/online-bidding/README.md` | README | 在线出价服务定位、本地调试、参考资料 | `L2` | `used` | 服务定位 |
| `service/infra/bidding-store/internal/handler/productads/main.go` | 代码 | 系数读取入口 | `L1` | `used` | `GetAdCoef` 入口 |
| `service/infra/bidding-store/internal/handler/handler.go` | 代码 | 系数读取统一 handler | `L1` | `used` | `HandleGetAdCoefRequest` 入口 |
| `service/infra/bidding-store/internal/storage/query_caches_and_update.go` | 代码 | 本地缓存与 Redis 回源 | `L1` | `used` | 在线读取模型 |
| `service/infra/bidding-store/internal/storage/full_load.go` | 代码 | full load 与 warmup | `L1` | `used` | full load 模式 |
| `service/infra/bidding-store/README.md` | README | 系数服务定位、本地调试、参考资料 | `L2` | `used` | 服务定位 |
| `service/ultrav-data-processor/ultrav-data-processor/pkg/handler/event_handler.go` | 代码 | Kafka consumer 入口 | `L1` | `used` | 事件接入模型 |
| `service/ultrav-data-processor/ultrav-data-processor/README.md` | README | 后验事件处理角色 | `L2` | `used` | 服务定位 |
| `service/ultrav-data-aggregator/ultrav-data-aggregator/README.md` | README | 时间窗聚合、Redis 写入、目录结构 | `L2` | `used` | 反馈闭环定位 |
| `service/ultrav-data-aggregator/ultrav-data-aggregator/pkg/handler/event_handler.go` | 代码 | TrackingEvent 解析、去重与事件处理入口 | `L1` | `used` | aggregator 事件标准化与 checksum 去重 |
| `service/ultrav-data-aggregator/ultrav-data-aggregator/pkg/services/stats_processor/processor.go` | 代码 | 聚合执行主线 | `L1` | `used` | `ProcessTrackingEvent` |
| `service/ultrav-data-aggregator/ultrav-data-aggregator/pkg/types/time_span_mark.go` | 代码 | 时间窗类型与 TTL 定义 | `L1` | `used` | 时间窗指标窗口语义 |
| `service/ultrav-data-aggregator/ultrav-data-aggregator/pkg/types/data_entry.go` | 代码 | 指标 entry 与 Redis key 结构 | `L1` | `used` | 时间窗指标键结构 |
| `service/ultrav-core/ultrav-core/README.md` | README | UltraV Core 总体定位 | `L2` | `used` | 服务定位 |
| `service/ultrav-core-timewindow/README.md` | README | timewindow 项目目录、测试、配置、验证 | `L2` | `used` | 配置与验证入口 |
| `service/ultrav-core-timewindow/CONFIG_WORKFLOW.md` | markdown | timewindow 配置修改规则 | `L2` | `used` | 配置目录约束 |
| `service/ultrav-core-timewindow/src/internal/service/output_processor/output_processor.go` | 代码 | 调控结果输出 | `L1` | `used` | `ProcessOutput` |
| `service/ultrav-core-timewindow/src/internal/model/model_util/scatter.go` | 代码 | 时序模型的 `coef -> imp/cost/gmv` 插值输出 | `L1` | `used` | 时序模型插值输出 |
| `service/ultrav-core-timewindow/src/internal/strategy/product_ad/gmv_max/model/base_ts_model.go` | 代码 | 时序模型的预测与校准主链路 | `L1` | `used` | `bid2x` 与 `StatModel` / `DeepModel` 主代码来源 |
| `service/ultrav-core-timewindow/src/internal/strategy/product_ad/gmv_max/model/stat_model.go` | 代码 | `StatModel` 入口模型定义 | `L1` | `used` | 环境时序模型入口 |
| `service/ultrav-core-timewindow/src/internal/strategy/product_ad/gmv_max/model/deep_model.go` | 代码 | `DeepModel` 入口模型定义 | `L1` | `used` | 环境时序模型入口 |
| `service/ultrav-core-timewindow/src/internal/strategy/product_ad/gmv_max/model/func_model.go` | 代码 | `FuncModel` 入口与预测公式 | `L1` | `used` | 近线调控内部函数模型 |
| `service/ultrav-core-timewindow/src/cmd/product_ad_cmd/registor.go` | 代码 | 近线调控注册的 `DeepModel` / `StatModel` / `FuncModel` | `L1` | `used` | 模型边界来源 |
| `service/ultrav-core-timewindow/src/internal/strategy/product_ad/gmv_max/agent/gmv_max_agent.go` | 代码 | `MPC` 搜索与系数决策 | `L1` | `used` | 近线调控决策主线 |
| `service/ultrav-core-timewindow/src/internal/model/predict_result.go` | 代码 | 预测结果对象 | `L1` | `used` | `bid2x` 输出字段定义 |
| `service/sequence-model-processor/sequence-model-processor/README.md` | README | sequence-model-processor 仓库内说明 | `L2` | `indexed` | 仓库索引 |
| `service/sequence-model-processor/sequence-model-processor/pkg/handler/uranker_periodic_handler.go` | 代码 | 选择广告集合、调用推理服务并写 Redis | `L1` | `used` | 环境模型推理主线 |
| `service/sequence-model-processor/sequence-model-processor/pkg/uranker/internal.go` | 代码 | AFP/FSE 特征 provider 组装 | `L1` | `used` | 环境模型推理输入结构 |
| `service/sequence-model-processor/sequence-model-processor/pkg/uranker/uranker.go` | 代码 | 调用 `URank` / `EGO` 推理服务并封装 `TimeSlot2X` | `L1` | `used` | 环境模型推理实现 |
| `service/sequence-model-processor/sequence-model-processor/pkg/handler/stat_model_periodic_handler.go` | 代码 | 历史 `StatModel` 周期推理链路 | `L1` | `indexed` | 历史实现 |
| `service/sequence-model-processor/sequence-model-processor/pkg/stat_model/stat_model_feature.go` | 代码 | 历史 `StatModel` 输入特征结构与解析 | `L1` | `indexed` | 历史实现 |
| `service/sequence-model-processor/sequence-model-processor/pkg/stat_model/avg_model_v1.go` | 代码 | 历史 `StatModel` 平均模型推理 | `L1` | `indexed` | 历史实现 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/samples/playback_new.py` | 代码 | 15 分钟流量回放脚本示例 | `L1` | `used` | 环境模型回放口径示例 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/model_registry.py` | 代码 | 时序模型注册表 | `L1` | `used` | 模型家族来源 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/model_module.py` | 代码 | 配置驱动的训练与在线推理图入口 | `L1` | `used` | 环境模型训练入口 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/models/stats.py` | 代码 | `stats` 统计模型实现 | `L1` | `used` | 环境模型统计模型 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/models/transm.py` | 代码 | `Transm` 深度模型实现 | `L1` | `used` | 环境模型深度模型 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/models/enc_dec.py` | 代码 | `EncDec` 深度模型实现 | `L1` | `used` | 环境模型深度模型 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/models/cost_gmv_v1.py` | 代码 | `cost_gmv_v1` 深度模型实现 | `L1` | `used` | 环境模型深度模型 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/models/winratio_encdec_no_auto_regressive.py` | 代码 | `WinRatioEncDecNoAutoRegressive` 深度模型实现 | `L1` | `used` | 环境模型深度模型 |
| `algo_jobs/paidads-alg/master/ego_models/model_modules/bidding_env/models/models/configs/base.py` | 代码 | 候选 `coef` 列表和模型基础配置 | `L1` | `used` | 环境模型基础参数 |
| `offline_jobs/sqls/ads_case/ads_perfdi.sql` | SQL | performance 原始表广告级取数 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/global/perfdi_region_daily_additive.sql` | SQL | performance 原始表按区域日期聚合 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/global/target.sql` | SQL | Target ROI2 日报告和 achievement 聚合 | `L1` | `used` | 算法数据分析表说明、achievement 判定公式 |
| `offline_jobs/sqls/bucket_perf/target_daily.sql` | SQL | Target ROI2 按 plan 日级聚合 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/bucket_perf/simple_daily.sql` | SQL | Simple ROI2 日报告和 achievement 聚合 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/ads_case/ads_perf_adv.sql` | SQL | perf 天级 ads 小表取数 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/bucket_perf/target_perf_adv_daily.sql` | SQL | perf 天级 ads 小表与 Target 日报告 join | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/ads_case/ads_tracking_hourly.sql` | SQL | tracking 小时级 ads 小表取数 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/global/tracking_hourly.sql` | SQL | tracking 小时级区域聚合 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/ads_case/ads_ultracore_log.sql` | SQL | ultrav-core trace 表取数 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/ads_case/ads_hit_time.sql` | SQL | budget hit time trace 取数 | `L1` | `used` | 算法数据分析表说明 |
| `offline_jobs/sqls/ads_case/ads_mpc_pcoc.sql` | SQL | MPC 预测校准广告级分析 | `L1` | `used` | 模型分析补充表说明 |
| `offline_jobs/sqls/bucket_perf/target_mpc_pcoc_daily.sql` | SQL | MPC 预测校准 plan 级聚合 | `L1` | `used` | 模型分析补充表说明 |
| `offline_jobs/sqls/model/ads_model_info.sql` | SQL | MPC 模型快照展开 | `L1` | `used` | 模型分析补充表说明 |
| `offline_jobs/sqls/model/model_check_overall.sql` | SQL | MPC 模型检查指标展开 | `L1` | `used` | 模型分析补充表说明 |
| `tools/ops/metric.py` | 代码 | achievement 聚合指标注册 | `L1` | `used` | `cost_prop` 和 `ads_prop` 计算方式 |
| 补充口径：`req_num`、`imp` 的结果量边界 | 补充说明 | `req_num`、`imp` 在 `bid2x` 语义中的结果量边界 | `L4` | `used` | 近线调控与环境模型文档的结果量边界说明 |
| `bidding-kb/skills/advv-coef.md` | workflow | `timewindow` 配置专项 workflow | `L2` | `indexed` | 配置 workflow |
| Google Doc `Support Plan Bucket Experiment phase2` | Google Doc | `plan bucket`、尾号实验、预算分桶、layer、桶号定义 | `L3` | `used` | 算法数据分析中的分桶机制来源 |
| Google Doc `ROI2 & Simple2 实验情况同步` | Google Doc | `ROI2`、`Simple2` 的 layer、大桶、小桶、base 桶占位 | `L3` | `used` | 桶位语义来源 |
| Google Doc `Pgmv高估 & 回流率高估的影响和解决方案` | Google Doc | 回流率高估、滞留效应、后验链路分析 | `L3` | `used` | 时效性来源 |
| Google Doc `[EpicTD][20260121][ProductAds-All-Target2-Bidding] - MPC模型预估能力评估和校准` | Google Doc | 回流预估数据、跨天窗口、后验值校准 | `L3` | `used` | 反馈数据、近线调控、环境模型补充来源 |
| Google Doc `MPC 时序模型` | Google Doc | `threshold_bid`、`threshold_coef`、多模型结构口径 | `L3` | `used` | 环境模型概念口径来源 |
| `service/online-bidding/online-bidding/README.md` 中引用的 `New Ads Bidding Overall` GDoc | Google Doc | bidding 总体设计 | `L3` | `todo` | 总体设计补充资料 |
| `service/online-bidding/online-bidding/README.md` 中引用的 `New Bidding infra - API design` GDoc | Google Doc | bidding infra / API 设计 | `L3` | `todo` | API 边界补充资料 |
| 其他 Google Doc（待归类） | Google Doc | 零散设计与业务背景 | `L3` | `todo` | 待补主题归类 |
| `bidding-kb-nouse/` | 历史草稿 | 旧版结构与内容参考 | `L4` | `indexed` | 结构参考 |
