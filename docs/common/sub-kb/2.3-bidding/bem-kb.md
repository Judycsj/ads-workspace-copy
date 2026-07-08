---
id: ads_bem_overview
title: Ads Basic Environment Model 总览
domain: bem
owner: TBD
source_refs:
  - https://docs.google.com/document/d/1JekSB-j8JKisjqNxSCANDNqE-cIiWH9vL9vUgHWjcRk/edit?tab=t.0#heading=h.s7d0m15ehyv
  - https://docs.google.com/document/d/1FIwyGqFUwC31YPx7tHgn2FR7eCmnTvYxW5FEtznL0A0/edit?tab=t.0#heading=h.vzu5igw1mcdm
last_updated: 2026-04-23
last_verified_at: 2026-04-23
confidence: medium
---

# Ads Basic Environment Model 总览

## KB 必要信息索引

| 类别 | 当前索引 |
|---|---|
| 代码仓库 GitLab 路径 | `shopee/deep/paidads-alg`、`shopee/deep/paidads-bidding/ultrav-core-timewindow`、`shopee/deep/paidads-bidding/ultrav-core` |
| 核心服务 SDU 路径 | **【待确认】需由 owner 通过 Space / SMC 确认 BEM 推理服务、UltraCore / timewindow 线上 SDU 路径** |
| ConfigCenter namespace | **【待确认】BEM / UltraCore 消费侧配置 namespace 需补齐当前线上值** |
| Grafana dashboard | **【待确认】当前源 KB 未集中列出 BEM 训练、推理、Redis 写入与 UltraCore 消费 dashboard** |
| 关键 Kafka topic | **【待确认】流量回放 / SearchLog / Tracking 如经 Kafka 回流，需按当前生产配置补齐 topic** |
| 核心 Hive 表名 | **【待确认】当前源 KB 以日志、回放样本与 HDFS/Redis 链路描述为主，需补齐权威 Hive 表名** |

## 阅读指引

本文档围绕 Basic Environment Model（BEM）/时序模型的完整工程链路展开，按"流量回放 -> 样本与特征 -> 模型训练与推理 -> 决策消费 -> Loss -> 离线评估 -> 验证与上线 -> 工程入口"组织。

- `§0-§3` **总览**：BEM 要解决的问题、整体框架、链路定位和职责边界。
- `§4` **核心概念**：coef、流量回放、反事实排序、曝光边界、时序窗口、PCOC、NPE/CPE 等术语。
- `§5` **整体框架**：样本服务、模型训练&推理、MPC 决策三部分如何串起来。
- `§6` **样本与特征**：样本粒度、目录结构、上游依赖、基础特征、回放特征和数据质量要求。
- `§7` **流量回放**：如何还原真实竞价环境、扰动 coef、判断竞得并汇总指标矩阵。
- `§8` **模型结构**：当前以 `cost_gmv_v2` 为主，补充建模对象、切窗方式、`v1` 基线结构、`v1/v2` 对比和关键模块。
- `§9` **训练、推理与接口**：EGO 训练、近线推理服务、Redis key/value、proto 结构、Ultra 预处理和预算折算。
- `§10` **Loss**：基础预测损失、业务一致性损失、target 级权重和当前配置。
- `§11` **离线评估**：`next_step`/NPE、`sum2end`/CPE、MAPE 和 PCOC 达标率，以及它们的适用场景。
- `§12` **验证与上线注意事项**：样本验证、SearchLog/Tracking join、TMS 曝光补充、监控拦截和 rollout 风险。
- `§13` **代码与参考资料**：关键代码路径、平台入口、参考文档和待补内容。

## 0. 一句话摘要

Basic Environment Model 当前可理解为：基于历史真实流量日志做离线流量回放，在不同出价系数 `coef` 下模拟广告参与竞排后的曝光、价值与成本表现，再用时序模型预测未来一段时间不同 `coef` 下的 `gmv` 和 `cost`，供 UltraCore / MPC 决策消费。

这套链路的核心不是直接在线试错，而是在历史请求分布上做 counterfactual evaluation，把回放结果组织成 `(ads_id, entrance, coef, time_slot)` 粒度的时序样本，让模型学习广告在不同出价变化下的未来表现。

## 1. 基本信息

| 字段 | 内容 |
|---|---|
| 主题名称 | Basic Environment Model / Bidding Time Series Model |
| 当前模型 | `cost_gmv_v2` |
| 当前主要产品范围 | Product Ads ROI2 / TargetROI；当前上线范围以 ID 为主 |
| 核心输入 | 历史请求日志、排序日志、曝光/Tracking 日志、基础时序特征、流量回放特征 |
| 样本粒度 | `ads_id + entrance + coef + 15min time slot` |
| 核心输出 | 不同 `coef` 在未来 96 个 15min 时间片内的 `cost`、`gmv`、`win_ratio`、`rpm`、`gpm`、`req_num` 等 |
| 推理方式 | 近线定时推理，全量广告打分后写 Redis，UltraCore 读取 |
| 推理周期 | 15min 一次 |
| Redis TTL | 24h |
| 下游使用 | UltraCore / MPC 策略，用于不同 coef 下的成本、GMV 预估和预算折算 |
| 当前状态 | 样本、训练、推理、评估链路逐步打通；部分数据一致性、fallback、监控和 v1/v2 diff 待继续补齐 |

## 2. 业务背景

时序模型要回答的问题是：如果一个广告在真实流量环境下使用不同的出价系数 `coef`，它未来一段时间可能获得多少流量、花费多少成本、产生多少 GMV，以及这些结果随时间和 `coef` 的变化关系是什么。

直接在线尝试所有 `coef` 成本高、风险大，所以系统先基于历史日志还原真实竞价环境，再在离线环境中替换单个广告的出价参数，重新模拟排序与曝光结果，并统计收益与成本表现。模型再学习这些回放结果，用于近线预测和策略决策。

当前 BEM 的工程目标可以拆成四类：

- SearchLog 补充 `SimpleROI`、`TargetROI` 等字段，让样本和策略目标可落盘。
- SimpleROI / TargetROI 样本落盘，形成基础时序训练数据。
- 建设 Bidding 推理服务，定时对全量广告打分并写 Redis。
- 产出流量回放特征，让模型显式学习 `coef` 变化对流量、成本和 GMV 的影响。

## 3. BEM 定位

### 3.1 整体链路位置

```text
历史请求日志 / SearchLog / TrackingLog
  -> 流量回放：还原候选集合、曝光边界、反事实排序
  -> 样本服务：按 ads_id + entrance + coef + 15min 聚合指标
  -> EGO 训练：学习未来 96 个 time slot 的多目标预测
  -> 近线推理：每 15min 对全量广告打分
  -> Redis 存储：timeseries_{placement}_{country}_{entrance}_{ads_id}
  -> UltraCore / MPC：读取不同 coef 预测结果，做预算折算和策略决策
```

![BEM 整体框架](img/td-framework.png)

### 3.2 本主题职责

- 负责还原历史请求中的竞价环境，并在不同 `coef` 下模拟目标广告的曝光与成本表现。
- 负责把基础时序特征和流量回放特征整理成模型训练样本。
- 负责预测未来 96 个 15min 时间片内，不同 `coef` 下的流量、成本、GMV 和中间指标。
- 负责把近线推理结果写入 Redis，供 UltraCore / MPC 读取。
- 不直接负责线上真实扣费、最终排序或预算履约，但会为这些模块提供可消费的未来收益/成本曲线。

### 3.3 与 MPC 决策的关系

MPC 使用时序模型输出做不同 `coef` 下的未来成本和 GMV 估计。由于时序模型越远期预测越不稳定，决策侧会和统计模型做加权融合：

- 越近的时间片更相信时序模型。
- 越远的时间片更相信统计模型。
- 融合后的结果再进入预算折算和 coef 选择逻辑。

## 4. 核心概念

| 概念 | 定义 | 与本主题关系 |
|---|---|---|
| `coef` | 出价变化系数，用来模拟广告在不同出价强度下的竞排表现 | 模型预测和策略决策的核心横轴 |
| `coefScale` | 相对上一阶段 coef 的变化倍率，如 `[0.25, 0.375, 0.562, 0.844, 1.266, 1.898, 2.847, 4]` | 推理侧可以通过不同 scale 结果插值 |
| 绝对 coef | 固定 coef 候选，如 `[0.25, 0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0, 4.0]` | 流量回放样本里的常见扰动点 |
| 流量回放 | 在真实请求分布上，替换单个广告的出价参数，重新模拟排序与曝光结果 | 生成反事实训练样本 |
| 反事实排序模拟 | 保持其他广告不变，只调整目标广告 `coef`，重算排序分数和曝光结果 | 回答“如果当时用另一个出价会发生什么” |
| 曝光边界 | 每个请求真实发生的曝光数量或最靠后曝光位置 | 判断重新排序后的目标广告是否竞得曝光 |
| Impression Win | 目标广告在扰动 `coef` 后进入曝光边界 | 回放特征中 `win_ratio`、cost、gmv 等指标的基础 |
| `win_ratio` | 在某个 `coef` 下的竞得率/曝光胜出率 | 连接出价、流量、成本和最终 GMV |
| `rpm` | Revenue Per Mille，请求维度的收益或成本强度指标 | 中间预测目标之一 |
| `gpm` | GMV Per Mille，流量质量相关指标 | 中间预测目标之一 |
| 非零 indicator | 标识某个业务指标是否真实发生过、是否为稀疏信号 | 帮助模型区分“值为 0”和“没有发生” |
| NPE / `next_step` | 下一时间片预测误差 | 评估短期单步预测精度 |
| CPE / `sum2end` | 从当前时间片到日结束的累计预测误差 | 评估未来总量预测能力 |
| PCOC | 预测值与真实值的比例校准指标 | 评估是否存在系统性高估/低估 |

## 5. 整体框架

整体分为三部分：样本服务、模型训练&推理、MPC 决策。

### 5.1 样本服务

样本服务负责把历史流量和回放结果组织成训练样本。当前方案中有两类特征：

- 基础特征：来自 SearchLog / TrackingLog / 样本链路的真实历史时序特征。
- 流量回放特征：通过扰动 `coef` 得到的不同出价下的指标矩阵。

样本服务侧的关键依赖：

- SearchLog 需要补充 `SimpleROI` 和 `TargetROI` 字段。
- `SimpleROI` / `TargetROI` 样本需要落盘。
- BE 消费 Kafka 产出流量回放特征到 Redis。
- DE 产出原始特征和训练数据；基础特征流程打通后，新增回放特征主要依赖配置和少量开发。

从框架上看，样本服务的职责可以压缩成：

```text
恢复真实请求候选集和曝光
-> 做不同 coef 下的流量回放
-> 聚合成时序样本与回放特征
-> 交给训练链路继续切窗和组装
```

具体的底表、连接逻辑和回放重排细节放在 `§6.1.1` 展开。

![样本流程](img/td-sample-flow.png)

### 5.2 模型训练与推理

训练侧使用 EGO 框架，当前预期无需新增独立训练模块。资源估计可先参考 UniCR 类模型，在参数量相近时预计资源接近或更少。

推理侧新增 Bidding 模型推理服务：

- 对全量广告做近线推理。
- 广告量级：ID 约 100 万广告。
- 周期：15min 一次。
- QPS 较低，资源需求预期低于 1 GPU。
- 结果写入 Redis，供 UltraCore 读取。

![模型整体流程](img/td-model-flow.png)

![模型训练流程](img/td-model-training.png)

### 5.3 预估与决策

推理服务输出未来 96 个 15min 时间片内的预测结果。输出目标分为 bid-free 和 bid-aware 两类：

| 类型 | 优先级 | 目标 |
|---|---|---|
| Bid-free | P0 | `req` / `req-gmv` / `req-cost` |
| Bid-free | P1 | `req-advv` / `req-click` / `req-order` |
| Bid-aware | P0 | `bid2gmv` / `bid2cost`；目标稀疏时可预测 `bid2gmvscale`、`bid2costscale` |
| Bid-aware | P1 | `bid2imp` / `bid2order` |

其中 bid-aware 目标可以按路径拆解：

```text
出价 -> 流量 -> 成本 -> 竞得率（竞胜率 -> 曝光率）-> 点击率 -> 转化率 -> Cost / GMV
```

一个 P0 拆解方向是：

```text
bid2cost = req * req_cost_avg * bid2ImpWinProb
```

## 6. 样本与特征

### 6.1 样本组织

当前样本的核心粒度是：

```text
ads_id + entrance + coef + 15min time slot
```

更贴近模型输入输出的切窗方式、历史窗口 / 未来窗口定义，以及 `seq_length / window_size / num_steps` 的代码口径，放到 `§8.1 建模对象与切窗方式` 展开。

### 6.1.1 样本依赖底表与连接逻辑

样本构建代码目录：

- https://git.garena.com/shopee/deep/paidads-alg/-/tree/master/ego_models/model_modules/bidding_env/samples
- 当前代码入口：https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/samples/playback_fse.py

当前样本构建主要依赖 `3` 张上游表。核心逻辑是：用请求候选集表恢复 request 内完整广告排序，用 tracking 表恢复真实曝光，再在 request 维度做流量回放。

| 表 | 作用 | 关键字段 |
|---|---|---|
| `srdi_mart.dwd_sr_data_warehouse_roi2_ads_search_log` | 最核心的请求候选集表，作用有两层：一是提供 request 内完整广告候选集，二是提供排序和出价相关特征，如 `rank_score / ecpm / ecpm_weight / pctr / pgmv`；较新的脚本还会从 `ads_bid_ext_str` 中解析 `pcr / pgmv / additional_boost / pid_coef` | `request_id`、`item_id`、`ads_id`、`pctr`、`pcr`、`pgmv`、`ecpm`、`ecpm_weight`、`rank_score`、`ads_bid_ext_str`、`event_timestamp`、`entrance` |
| `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` | 广告 tracking 曝光表，用来恢复哪些广告在 request 中真实曝光；由于 tracking 里 `request_id` 口径不完全统一，代码会兜出统一 request_id | `ads_request_id`、`raw_request_id`、`organic_request_id`、`item_json_data.request_id`、`timestamp`、`item_id`、`ads_id`、`operation` |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台 impression 补充表，只在部分脚本中使用，用来补 tracking 表里可能缺失的曝光信息，提高曝光恢复完整性 | `request_id`、`event_timestamp`、`item_id`、`operation`、`user_id` |

连接逻辑可以概括成 `4` 步：

```text
1. 从 search_log 先挑目标 request：先筛出目标广告、目标 region、目标时间范围内出现过的 request_id
2. 再从 search_log 拉这些 request 的完整候选集：恢复该次请求里的所有候选广告以及它们的 rank_score / ecpm / pctr / pgmv 等字段
3. 从 tracking 表恢复真实曝光：按统一后的 request_id 把 tracking 曝光数据和候选集对齐，再在 request 内用 item_id 判断哪些广告真实曝光
4. 必要时用 platform 表补曝光：如果 tracking 曝光不全，再用平台 impression 表补齐
```

在此基础上，代码会在每个 request 内：

- 按 `rank_score` 排序
- 对目标广告枚举不同 `coef`
- 重算 `new_rank_score`
- 用二分插入求新位置 `new_rank`
- 判断该位置是否还能落在曝光边界内
- 最后聚合成不同 `coef` 下的 `win_num / gmv / cost` 等回放特征

几个实现细节值得记住：

- `request_id` 在 tracking 表里不是单一字段，代码用 `COALESCE(ads_request_id, raw_request_id, organic_request_id, get_json_object(item_json_data, '$.request_id'))` 统一抽取。
- 候选集合必须来自 SearchLog 全量请求候选，不能只保留 impression item，否则回放时会低估位置变化。
- 曝光边界当前实现不是根据“最末曝光 rank”直接 join，而是先按 `request_id` 收集曝光 `item_id`，再用曝光 item 数量近似构造 `max_rank`。
- 平台 impression 表被作为第二曝光源 union 进来，说明当前样本链路默认广告 tracking 可能不完整，需额外补齐曝光。

### 6.1.2 样本目录与真实样本结构

样本路径：

```text
hdfs://R2/projects/mkplpaidads_offline/hdfs/prod/ads_sequence_sample/train_data/
```

组织方式：目录按 `region -> date` 组织，顶层有 `8` 个 region：

```text
BR / ID / MY / PH / SG / TH / TW / VN
```

分区方式：每个 `region` 下再按天分区。例如 `ID` 当前有：

```text
2026-04-07 ~ 2026-04-26
```

共 `20` 天数据。整体结构可以理解为：

```text
train_data/
└── <region>/
    └── <date>/
        └── compact-*.zstd.parquet
```

样本量级：按一个真实 parquet 文件的样本量 `1374` 行/文件粗估，各 region 合计约 `6260` 万样本。

| Region | 文件数 | 估算样本量 |
|---|---:|---:|
| BR | 6773 | 约 930 万 |
| ID | 16377 | 约 2250 万 |
| MY | 3563 | 约 490 万 |
| PH | 5887 | 约 809 万 |
| SG | 547 | 约 75 万 |
| TH | 4488 | 约 617 万 |
| TW | 2581 | 约 355 万 |
| VN | 5373 | 约 738 万 |

样本结构：抽查 `ID/2026-04-26` 的一个 parquet 文件，字段结构是：

```text
277 = 8 + 269
```

其中：

- `8` 个非 slot 字段：样本上下文
  - `mio_info`
  - `dump_time`
  - `user_id`
  - `item_id (ad_id)`
  - `request_id`
  - `attr_info`
  - `debug_info`
  - `action_info`
- `269` 个 slot 时序特征：
  - `65` 个基础真实时序
  - `96` 个旧版回放特征
  - `108` 个新版回放特征

进一步展开：

```text
269 = (1×4 + 15×4 + 1) + (8×4×3) + (9×4×3)
```

这里：

- `4` = 场景：`search / dd / ymal / other`
- `8` = 旧版 `coef` 档位
- `9` = 新版 `coef` 档位
- `3` = 回放指标：`win_num / gmv / cost`

所以，一条样本本质上是：

```text
一个广告在历史窗口里的真实表现曲线 + 多个候选出价下的反事实回放曲线
```

样本示例：

- `item_id = 728825923`
- `request_id = 1777221900ID728825923`
- `slot_20000` 前 `5` 个值：`[32, 21, 19, 28, 15]`
- `slot_20100` 前 `5` 个值：`[23.05, 46.34, 67.69, 61.57, 74.47]`

其中可以这样理解：

- `slot_20000`：`coef = 0.25 × search × win_num`
- `slot_20100`：`coef = 0.25 × dd × cost`

所以这条样本表示的不是某一个时刻，而是：

```text
广告 728825923 在一整段历史窗口中，不同场景、不同 coef、不同指标上的时序轨迹
```

### 6.2 基础时序特征

当前 `v2` 的特征空间可以分成两层理解。

第一层是 YAML 配置里的原始特征空间：

- 共 `138` 个原始 feature。
- 其中 `134` 个 dense，`4` 个 sparse。
- 除 `lbl_mask` 外，大多数时序 dense 特征的长度都是 `768`。

原始特征按语义大致分成四类：

- 静态 ID / 类目特征：`ads_id`、`l1_cat`、`l2_cat`、`l3_cat`
- 基础流量特征：`item_req_num_*`、`ads_req_num_*`、`ads_pv_*`
- 预估与目标特征：`ads_pctr_*`、`ads_pctcvr_*`、`ads_target_cir_*`
- 回放特征：不同 `coef` 下的 `gmv`、`cost`、`win_num`

基础特征示例：

| 特征 | 含义 |
|---|---|
| `ads_req_num_search` | Search 入口历史请求量 |
| `ads_pv_search` | Search 入口历史曝光量 |
| `ads_pctr_search` | Search 入口历史 CTR 预估 |
| `ads_pctcvr_search` | Search 入口历史 CVR 预估 |
| `ads_target_cir_search` | Search 入口历史目标 CIR |

这些原始特征按入口拆分，当前入口口径包括：

```text
search / ymal / dd / other
```

### 6.3 流量回放特征

回放特征是当前样本空间最关键的一层，它把“同一广告在不同出价下会发生什么”补进样本里。

当前配置一共使用 `9` 个 `coef`：

```text
0.25, 0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0, 4.0
```

每个 `coef` 都按四个入口分别记录三类原始回放特征：

- `coef_xxx_gmv_*`
- `coef_xxx_cost_*`
- `coef_xxx_win_num_*`

因此原始回放特征总数是：

```text
9 coefs * 4 entrances * 3 measures = 108
```

在 `features_group` 里，这些原始特征会进一步聚合成模型真正使用的业务特征：

- `coef_xxx_gmv_sum`
- `coef_xxx_cost_sum`
- `coef_xxx_win_num_sum`
- `coef_xxx_gpm`
- `coef_xxx_rpm`
- `coef_xxx_win_ratio`

示例：

| 特征 | 含义 |
|---|---|
| `coef_250_gmv_search` | `coef=0.25`、Search 入口下的回放 GMV |
| `coef_250_cost_search` | `coef=0.25`、Search 入口下的回放 cost |
| `coef_250_win_num_search` | `coef=0.25`、Search 入口下的竞得次数 |
| `coef_1000_gpm` | `coef=1.0` 下单位竞得 GMV |
| `coef_4000_win_ratio` | `coef=4.0` 下竞得率 |

### 6.4 特征处理逻辑

特征处理可以分成三步：

1. 先按入口聚合基础特征，得到：
   - `item_req_num_sum`
   - `ads_req_num_sum`
   - `ads_pv_sum`
   - `ads_pctr_sum`
   - `ads_pctcvr_sum`
   - `ads_target_cir_sum`
2. 再按每个 `coef` 聚合回放特征，构造：
   - `coef_xxx_gmv_sum`
   - `coef_xxx_cost_sum`
   - `coef_xxx_win_num_sum`
   - `coef_xxx_gpm`
   - `coef_xxx_rpm`
   - `coef_xxx_win_ratio`
3. 最后拼成两组模型输入：
   - `seq_feas`：`6` 个基础时序通道
   - `coef_xxx_fea`：每个 `coef` 对应 `5` 个回放通道

进入 `cost_gmv_v2` 前，`SingleWindowFeatureExtractor` 会把回放特征 reshape 成：

```text
[B, window_size, 9, 5]
```

当前模型只把 `gmv` 和 `cost` 两个 target 的历史回放轨迹喂进主 encoder，因此默认主输入维度是：

```text
1 + 1 + 9 + 9 + 9 + 9 = 38
```

也就是：

- `req_num`
- `req_num > 0` indicator
- `gmv` 的 9 个 `coef` 历史值
- `gmv` 的 9 个非零 indicator
- `cost` 的 9 个 `coef` 历史值
- `cost` 的 9 个非零 indicator

这一层口径要和“原始配置里有 138 个 feature”区分开看：

- `138` 是配置层的原始特征空间
- `38` 是当前 `v2` 主 encoder 真正吃进去的默认输入维度

## 7. 流量回放

流量回放的核心目标是：**在真实流量环境下，模拟一个广告在不同 `coef` 下参与竞排时，可能获得的曝光、排名以及对应的收益与成本。**

![流量回放示意图 1](img/image-001.png)

![流量回放示意图 2](img/image-002.png)

### 7.1 还原真实竞价环境

先从历史日志中恢复真实发生过的请求场景：

- 每个请求里有哪些广告参与竞排。
- 每个广告当时的排序特征、分数和 `ecpm_weight`。
- 哪些广告最终被曝光。

这样可以构建出：

- 候选集合：参与排序的所有 item。
- 曝光结果：真实展示的 item。
- 曝光边界：请求下最大可曝光排名或最靠后曝光位置。

### 7.2 扰动 coef 并重排

在保持其他广告不变的前提下，只调整目标广告的 `coef`：

- 还原原始 `rank_score` 和 `ecpm`。
- 用新的 `coef` 计算目标广告扰动后的 `rank_score_new`。
- 放回原始候选集合。
- 重新计算目标广告的新排名 `new_rank`。

核心是在回答：**如果当时这个广告用的是另一个出价，会发生什么？**

### 7.3 竞得判定

扰动后需要判断目标广告是否竞得曝光。当前有两种口径：

- 方案一：关联 SearchLog 参竞表和 Tracking 曝光表，获取每个请求下的最大可曝光排名作为竞得阈值。
- 方案二：使用最靠后曝光的位置作为竞得阈值。

需要注意：曝光事件相对参竞事件存在延迟，样本链路需要引入约 15min 等待。

### 7.4 回放聚合指标

对所有合法扰动结果进行聚合，形成按 `ads_id + entrance + coef + 15min` 的指标矩阵：

| 字段 | 含义 |
|---|---|
| `ads_id` | 广告 ID |
| `entrance` | 入口，如 `SEARCH` / `DD` / `YMAL` |
| `coef` | 扰动后的出价系数 |
| `event_timestamp_15min` | 15min 聚合时间窗口 |
| `ad_sum_gmv_15min` | 15min GMV 汇总 |
| `ad_sum_cost_15min` | 15min 成本汇总 |
| `ad_sum_costtwo_15min` | 二价成本相关汇总 |
| `ad_sum_pv_15min` | 竞得曝光次数 |
| `ad_sum_click_num_15min` | 点击数估计 |
| `ad_sum_order_num_15min` | 订单数估计 |

当前回放产出表：

```text
mkplpaidads_offline.dwd_sequence_coef
```

分区字段：

```text
dt, hh, region
```

### 7.5 回放代码与口径注意事项

已记录的计算实现：

- PySpark 版本：`paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback.py`
- Local 版本：`paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback_local.py`

需要特别注意的口径：

- 当前只做 ID region 时，region 过滤应聚焦 ID。
- Base data 需要保留 organic 部分数据，不应把所有缺少广告字段的行过滤掉。
- `ads_id > 0` 时，需要要求 `ads_bid_ext_str` 中存在 `additional_boost` 和 `pid_coef`。
- 排序不能只拿 impression item，需要保留完整候选集合，否则会低估位置变化。
- `coef` 变化后，二价 `ecpm` 会随新位置变化，不能直接复用原始 `next_ecpm`。

扰动后新位置的二价计算应基于新位置的下一名：

```text
second_price_ecpm = (rank_score[i+1] - ecpm_weight[i] * ecpm[i]) / (ecpm_weight[i] * pctr[i])
```

## 8. 模型结构

当前知识库中，“当前时序模型结构”统一指 `cost_gmv_v2`。对应代码入口如下；如果后续主模型版本发生切换，再随知识库迭代更新：

- GitLab: https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/models/cost_gmv_v2.py

之所以仍保留 `v1`，是为了给 `v2` 提供一个基线对照，方便解释模型演进方向。

### 8.1 建模对象与切窗方式

当前模型建模的核心粒度是：

```text
ads_id + entrance + coef + 15min time slot
```

它先在回放侧按上面粒度聚合成反事实指标矩阵，再在训练侧按 `(ads_id, coef)` 组织成时间序列，切成两段：

- 历史窗口：模型输入
- 未来窗口：预测标签

切窗逻辑在 `SingleWindowFeatureExtractor` 里是明确写死的：

- 训练时先从完整序列中截出一段历史窗口 `fea_seq`
- 再截出紧随其后的未来窗口 `lbl_seq`
- 对回放特征也做同样的历史 / 未来切分

按当前 `v2` 配置：

- 完整序列长度 `seq_length = 768`
- 历史窗口长度 `window_size = 600`
- 未来预测长度 `num_steps = 100`

也就是训练时核心在学习：

```text
用过去 600 个 step 的历史序列 -> 预测未来 100 个 step 的 cost / gmv 轨迹
```

从业务粒度看，样本本质上就是：

```text
给定某个 ads 在多个 coef 下的历史表现，预测它未来在多个 coef 下的 cost / gmv 变化
```

当前 `cost_gmv_v2` 的代码口径是：

- `window_size = 600`
- `num_steps = 100`
- `seq_length = 768`

对应代码：

- 特征切窗：[`features/single.py`](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/models/features/single.py)
- 模型配置：[`cost_gmv_v2.yaml`](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/confs/models/cost_gmv_v2.yaml)

### 8.2 v1 基线结构

`cost_gmv_v1` 可以概括为：

```text
历史特征
-> Shared Encoder
-> 4 个中间目标 Decoder
-> 每个目标各自 MMoE
-> 得到 win_ratio / gpm / rpm / req_num
-> CascadeMLPFusion
-> 输出 gmv / cost
```

v1 的核心特点：

- 先预测中间机制变量，再融合得到最终 `gmv/cost`。
- 更偏“机制拆解”思路，可解释性更强。
- 默认 Encoder 输入维度较大，包含 `req_num + gmv + cost + win_ratio + gpm + rpm` 及对应 indicator。

![cost_gmv_v1 模型结构](img/v1-architecture.png)

### 8.3 v2 当前结构

`cost_gmv_v2` 默认不再走“两阶段中间目标 -> 最终融合”的主路径，而是直接对最终目标建模。其默认主线可以概括为：

```text
历史特征
-> Shared Encoder
-> target-specific Decoder
-> shared experts + specific experts
-> Task-Aware Gate（感知 coef + task）
-> per-coef head
-> monotone / coef-chain / repair
-> 直接输出 gmv / cost
```

![cost_gmv_v2 模型结构图](img/v2-architecture.png)

v2 的核心特点：

- 默认 `target_names = ["gmv", "cost"]`，直接预测最终目标。
- Experts 从“每个 target 独立”升级成“shared + specific”两层结构。
- Gate 从普通 `MMoEGate` 升级成 `TaskAwareMMoEGate`，显式引入 `coef value + coef embedding + target embedding`。
- Decoder 支持 condition-guided 机制，还可叠加 dual horizon、cross-attention、step-router 等增强模块。
- 输出侧加入 monotone、coef-chain、repair 等约束，更强调业务合理性和稳定性。

### 8.4 v1 vs v2 总览对比

| 维度 | v1 | v2 | 变化意义 |
|---|---|---|---|
| 建模目标 | 先预测 `win_ratio/gpm/rpm/req_num`，再融合得到 `gmv/cost` | 默认直接预测 `gmv/cost` | 从“机制拆解”转向“直接目标建模” |
| 整体结构 | Shared Encoder + Per-target Decoder + MMoE + Cascade Fusion | Shared Encoder + Per-target Decoder + Shared/Specific Experts + Task-Aware Gate + Output Repair | 表达能力更强，结构更复杂 |
| Gate | 普通 `MMoEGate` | `TaskAwareMMoEGate` | 显式引入 coef/task 信息 |
| Experts | 每个 target 独立 experts | shared experts + specific experts | 参数共享更强，target 个性保留更多 |
| Decoder | 标准 decoder | condition-guided decoder，可选 dual horizon / cross attention | 对时间段和条件信息建模更细 |
| 输出约束 | 较少 | monotone / coef-chain / repair / calibration | 更强调业务合理性 |
| 默认 target | 中间目标 + 最终目标 | 默认只做 `gmv/cost` | 训练目标更聚焦 |

### 8.5 v2 关键模块

| 模块 | 作用 | 输入 shape | 输出 shape |
|---|---|---|---|
| Encoder | 编码历史序列 | `[B, W, 38]` | `[B, W, D]` |
| Decoder | 为单个 target 生成未来时序表示 | `[B, 192+T, *]` | `[B, T, D]` |
| Shared Experts | 提供跨 target 共享模式 | `[B, T, D]` | `[B, T, D]` |
| Specific Experts | 提供 target 专属模式 | `[B, T, D]` | `[B, T, D]` |
| Task-Aware Gate | 按 coef/task 选择 expert | `[B, T, D] + coef + task emb` | `[B, T, E]` |
| Per-coef Head | 生成每个 coef 的 cls/value | `[B, T, D]` | `[B, T, 9]` |
| Output Repair | 做单调性/业务约束修正 | `[B, T, 9]` | `[B, T, 9]` |

### 8.6 v2 主要张量流向

| 阶段 | 张量 |
|---|---|
| 输入 | `encoder_inputs: [B, W, 38]` |
| Encoder 输出 | `encoder_output: [B, W, D]` |
| Decoder 输出 | `decoder_pred_output: [B, T, D]` |
| Gate 输出 | `gate_weights: [B, T, E]` |
| Head 输出 | `cls_preds: [B, T, 9]`，`multipliers: [B, T, 9]` |
| 最终 value | `val_preds: [B, T, 9]` |
| 最终预测 | `preds: [B, T, 9]` |

### 8.7 如何理解这次升级

- 从“先学中间机制，再融合最终目标”改成“直接预测最终目标”。
- 从“普通 MMoE”升级到“coef/task 感知的 CGC/MMoE”。
- 从“只追求拟合”升级到“拟合 + 单调性 + 校准 + 分段控制”。

## 9. 训练、推理与接口

### 9.1 训练链路

训练使用 EGO 框架，代码可以按 6 层理解：

| 层级 | 路径 | 作用 |
|---|---|---|
| 启动入口 | `model.py` | 指定 YAML 配置，调用 `create_model(conf_yaml)`，最后执行 `model.run()` |
| 训练主框架 | `model_module.py` | 负责读配置、构建输入、加载具体模型、接入 EGO 训练/推理 pipeline |
| 模型注册 | `model_registry.py` | 维护 `model_name -> build_model` 的映射，按名字动态加载 `models/*.py` |
| 配置层 | `confs/models/*.yaml` | 定义 `model_name`、features、feature_group、labels、hparams |
| 模型实现层 | `models/*.py` | 具体模型实现，如 `cost_gmv_v1.py`、`cost_gmv_v2.py` |
| 基础组件层 | `models/features/*`、`models/loss/*`、`layers/*` | 特征切窗、loss 计算、Transformer/MMoE/Embedding 等通用模块 |

当前主配置和主模型分别是：

- 配置：`confs/models/cost_gmv_v2.yaml`
- 模型：`models/cost_gmv_v2.py`

训练主链路可以压缩成下面这条：

```text
YAML 配置
-> InputBuilder 拉取 label / dense / sparse feature
-> feature_group 做 add / concat / divide / avg_to_sum 聚合
-> SingleWindowFeatureExtractor 切出训练窗口、label 和未来时间特征
-> model_registry 按 model_name 加载 cost_gmv_v2
-> cost_gmv_v2 构图并产出 loss / eval targets
-> TrainingPipeline 封装为 ego.OfflineRound
-> ego.compile 执行训练
```

几个关键点：

- `model_module.py` 里的 `InputBuilder` 负责把 YAML 里的 slot 配置真正变成 Tensor。
- `models/features/single.py` 里的 `SingleWindowFeatureExtractor` 负责切出 `fea_seq`、`fea_req_num`、`fea_coef`、`lbl_coef`，并生成未来时间片特征。
- `cost_gmv_v2.yaml` 不只是超参文件，也定义了大量原始 slot 和派生 `feature_group`，所以它本身就是训练输入契约的一部分。
- EGO learner 侧的数据路径、converter、batch size、valid slots 等调度配置在 `extra/schedule/ego_learner.yaml`。

一句话总结：

```text
配置驱动输入 -> 特征切窗 -> 动态加载模型 -> 产出 EGO rounds -> ego.compile 训练
```

### 9.2 推理服务

![BEM 线上部署与推理流程图](img/td-serving-flow.png)

线上从部署模型到在线推理的完整流程可以概括为：

```text
先把模型训练好并发布到 EGO Serving
-> 再由新增的 Bidding 推理服务每 15min 批量拉全量广告做近线推理
-> 将未来不同 coef 下的预测结果写入 Redis
-> UltraCore 读取这些结果做 MPC 预估和决策
-> OnlineBidding 消费决策结果
```

按步骤展开就是：

1. 模型训练
   样本先进入 EGO 训练，训练出 BEM 时序模型。

2. 模型部署
   训练好的模型发布到 `EgoServing`，作为可被线上推理服务调用的模型服务。

3. 近线推理服务启动
   新增一个 Bidding 推理服务。它不是每个请求实时现算，而是定时批量跑。

4. 定时批量推理
   图里的设计口径是每 `15min` 跑一次；推理服务会从 `ads_info` 拉取全量广告。

5. 构造推理输入
   对每个广告，推理服务会把广告当前特征整理成模型可吃的格式，再调用已部署模型做推理。具体包括：
   - 取特征
   - 构建 Arrow
   - 调 AFP
   - 再调 Algo / EgoServing

6. 写入 Redis
   推理完成后，把每个广告未来一段时间、不同 `coef` 下的预测结果写入 Redis。

7. UltraCore 读取预测结果
   `UltraCore` 内的 `MPC预估` 模块从 Redis 取回这些预测结果。

8. MPC 做决策
   `MPC预估` 把模型预测结果交给 `MPC决策`，结合预算和目标选出更合适的出价策略。

9. OnlineBidding 消费决策
   最后，`UltraCore` 把决策结果往上提供给 `OnlineBidding`，在线出价链路据此执行。

一句话总结：

```text
训练阶段负责产出模型，部署阶段把模型挂到 EgoServing，线上阶段由 Bidding 推理服务定时批量算全量广告预测并写 Redis，UltraCore 再基于 Redis 中的预测做 MPC 决策，最终服务 OnlineBidding。
```

推理服务负责定时对全量广告打分并写入 Redis。当前模型输出包括：

| 输出 | 形状 | 含义 |
|---|---|---|
| `cost` | `9 * 96` | 9 个 coef、未来 96 个时间片的成本预测 |
| `gmv` | `9 * 96` | 9 个 coef、未来 96 个时间片的 GMV 预测 |
| `rpm` | `9 * 96` | 9 个 coef、未来 96 个时间片的 RPM 预测 |
| `gpm` | `9 * 96` | 9 个 coef、未来 96 个时间片的 GPM 预测 |
| `win_ratio` | `9 * 96` | 9 个 coef、未来 96 个时间片的竞得率预测 |
| `req-gmv` | `96` | bid-free 流量质量预测 |
| `req-num` | `96` | bid-free 流量规模预测 |

模型输入特征包括 context 特征和 FSE 特征，AFP scenario 入口待在工程部分补齐。

### 9.3 Redis Key

推理结果按广告维度写 Redis：

```text
timeseries_{placement}_{country}_{entrance}_{ads_id}
```

字段说明：

- `placement`：广告 placement。
- `country`：国家或 region。
- `entrance`：EntranceGroup 概念，小 entrance 会聚合；`entrance=0` 表示不区分 entrance 的模型。
- `ads_id`：广告 ID。

TTL：

```text
24h
```

### 9.4 Redis Value / Proto

推理结果使用 PB 写入。为了兼容后续 coef 列表和预估长度变化，coef 和 time slot 两处都使用 map。

```proto
syntax = "proto3";

message PredictValues {
  double cost = 1;
  double gmv = 2;
  double imp = 3;
  double order = 4;
  double win_ratio = 5;
  double rpm = 6;
  double gpm = 7;
}

message SlotInfo {
  // bid aware: key = string(coef)
  map<string, PredictValues> coefInfoMap = 1;

  // bid free
  double req_num = 2;
  double gmv_per_req = 3;
}

message TimeSlot2X {
  // key = timeSlot, 0...95
  map<int32, SlotInfo> slotInfoMap = 1;

  // model inference seconds
  int64 updateTime = 2;
}
```

time slot 语义：

- time slot 固定表示一天中的第几个 15min 时间片。
- 如果当前是 slot 40，推理未来 24h 时，写入顺序是 `41, 42, ..., 95, 0, 1, ..., 40`。
- `updateTime` 记录本次 inference 时间。

### 9.5 Ultra 预处理与预算折算

Ultra 预处理模块读取推理服务写入的 Redis PB，并按当前预算计算到当天结束的不同 `coef` 累计 `gmv` 和 `cost`。

![Ultra 预处理](img/td-ultra-preprocess.png)

预算折算逻辑：

```text
for coef in coef_list:
  total_cost = 0
  total_gmv = 0

  for ts from current slot to day end:
    cur_cost = prediction[ts][coef].cost
    cur_gmv = prediction[ts][coef].gmv

    if total_cost + cur_cost > remaining_budget:
      budget_ratio = (remaining_budget - total_cost) / cur_cost
      total_cost += cur_cost * budget_ratio
      total_gmv += cur_gmv * budget_ratio
      break

    total_cost += cur_cost
    total_gmv += cur_gmv
```

最终输出：

```json
[
  {"coef": "coef_1", "gmv": "gmv_1", "cost": "cost_1"},
  {"coef": "coef_n", "gmv": "gmv_n", "cost": "cost_n"}
]
```

其中 `gmv` 和 `cost` 表示按该 `coef` 出价到当天结束，并经过 budget 折算后的总 GMV 和总 cost。

## 10. Loss

### 10.1 Loss 设计

这一节先按 `cost_gmv_v1` 的代码口径整理。对应代码入口：

![Loss 设计](img/image-004.png)

- 模型代码：[`cost_gmv_v1.py`](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/models/cost_gmv_v1.py)
- 模型配置：[`cost_gmv_v1.yaml`](https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/confs/models/cost_gmv_v1.yaml)

`v1` 的单个 target loss 可以压缩成下面这条：

```text
final_loss
= 分类/回归主损失
+ 全局误差
+ PCOC 约束
+ coef 加权误差
+ 总量校准
+ 分 coef 校准
```

#### 1. 基础预测损失

基础预测损失解决两个问题：

1. 这个位置有没有值。
2. 如果有值，数值预测得准不准。

具体包括：

- `win_cls_loss`：判断当前位置是否非零。
- `win_reg_loss`：只在真实值非零的位置计算数值误差。
- `log_loss`：在 log 空间比较预测和真实值，缓解大值样本主导梯度。
- `global_mse` / `global_mae`：从最终输出层面约束整体误差。

其中有两组 step 级加权需要特别记住：

- `win_cls_loss` 按时间步做分段加权：
  - 前 `20` 步权重 `25`
  - `20-39` 步权重 `35`
  - `40-59` 步权重 `40`
  - `60-79` 步权重 `70`
  - `80-99` 步权重 `100`
- `win_reg_loss` 也按时间步做分段加权：
  - 前 `60` 步权重 `8`
  - `60-79` 步权重 `10`
  - `80-99` 步权重 `12`

这说明 `v1` 已经在 loss 层显式强调了更后段时间步的重要性。

#### 2. 业务一致性与校准损失

业务一致性与校准损失进一步约束预测结果是否业务合理：

- `pcoc_loss`：约束预测和真实比例关系，减少系统性高估或低估。
- `coef_weighted_loss`：让模型更关注业务重要的 `coef` 区间。
- `calibration_loss`：约束整体预测总量和真实总量接近。
- `calibration_by_coef`：保证各个 `coef` 分段的总量也合理。

其中 `calibration_by_coef` 在代码里还额外对不同 `coef` 使用了手工权重：

```text
[0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.3, 1.6, 2.0]
```

也就是越高 `coef` 的总量校准越重。

#### 3. 当前权重配置

`cost_gmv_v1.yaml` 当前主权重如下：

| 项目 | 当前权重 | 说明 |
|---|---:|---|
| `cls_weight` | `40.0` | 非零分类损失 |
| `reg_weight` | `8.0` | 非零位置回归损失 |
| `log_weight` | `0.05` | log 空间回归损失 |
| `mse_weight` | `30.0` | 全局 MSE |
| `mae_weight` | `0.3` | 全局 MAE |
| `pcoc_weight` | `250000.0` | PCOC 约束 |
| `coef_weighted_weight` | `1.0` | coef 加权误差 |
| `calibration_weight` | `600000.0` | 总量校准 |
| `calibration_by_coef_weight` | `300000.0` | 分 coef 校准 |

PCOC 和 coef-weighted loss 的内部配置也需要一起看：

| 项目 | 当前配置 |
|---|---|
| `use_pcoc_loss` | `True` |
| `pcoc_mode` | `both` |
| `pcoc_coef_weights` | `hybrid` |
| `pcoc_global_weight` | `1.0` |
| `pcoc_per_coef_weight` | `0.5` |
| `coef_loss_weights` | `hybrid` |
| `use_smape_loss` | `True` |
| `use_log_space_loss` | `True` |
| `smape_weight` | `0.5` |
| `coef_log_weight` | `0.3` |

#### 4. target 级权重

`v1` 是多 target 联合训练，最终总 loss 还会再乘一层 target 权重：

| target | 权重 |
|---|---:|
| `win_ratio` | `15000.0` |
| `gpm` | `150.0` |
| `rpm` | `150.0` |
| `req_num` | `50.0` |
| `gmv` | `1.0` |
| `cost` | `12.0` |

这说明 `v1` 的训练重心并不平均，而是明显更强调：

- 中间目标里的 `win_ratio`
- 最终目标里的 `cost`
- 以及整体总量和比例校准

## 11. 离线评估

离线评估框架是：

- 评价指标：`MAPE`、`PCOC` 达标率
- 评价窗口：单步评价（NPE）、累积误差评价（CPE）
- 达标口径：Item 维度达标、Cost 维度达标

### 11.1 MAPE

`MAPE` 用来衡量预测值和真实值之间的相对误差有多大。

在这个项目里，它会用于：

- 单步预测场景下的误差
- 累计预测场景下的误差

也就是同时看：

- 下一个时间片的 `cost / gmv` 预测偏差
- 从当前时刻累计到当天结束的 `cost / gmv` 预测偏差

优点：

- 直观，容易理解
- 适合比较不同模型谁更准
- 对“数值离真实值差多远”很敏感

缺点：

- 对小值样本比较敏感，真实值很小时会放大误差
- 只能看“偏差大小”，不直接体现“系统性高估还是低估”
- 对 MPC 这种累计决策场景，单独看 `MAPE` 不够

### 11.2 PCOC 达标率

`PCOC` 不是只看一个平均值，而是看达标率。它关注的是：

- 这个比例是否落在可接受区间内
- 有多少样本“达标”

当前达标区间按文档口径记录为：

```text
PCOC in (0.8, 1.2)
```

`PCOC` 明确拆了两种口径：

- Item 维度达标：逐广告看预测和真实的比例是否达标，反映“有多少广告的预测是稳定可用的”
- Cost 维度达标：从成本贡献角度看达标情况，更关注高消耗广告上的预测质量

所以 `PCOC` 的重点不是“平均接近 `1` 就行”，而是：

- 有多少广告达标
- 高 cost 广告是否也达标

优点：

- 能直接反映模型是否存在系统性高估/低估
- 比单纯平均值更适合做“是否可上线”的稳定性判断
- 对 MPC 场景特别重要，因为决策更怕系统性 bias

缺点：

- 只看达标率时，会丢失误差大小细节
- 达标了不代表每个样本都很准，只代表落在阈值范围内
- 阈值怎么设会影响结论，比较依赖业务口径

接入 EGO-Eval 时的思路：

- 对 PCOC 达标率类型指标，可以套用 AUC 类逻辑。
- Cost 加权：`label = ads cost & cost > 0`，`pValue = pcoc 是否在 (0.8, 1.2)`。
- 等权重：`label = 1 & cost > 0`，`pValue = pcoc 是否在 (0.8, 1.2)`。
- MSE 类型指标可直接使用误差统计。

### 11.3 NPE / `next_step`

`NPE`（Next Predict Error）是在当前时刻计算下一个时间片预测值和真实值的差异。

![NPE](img/td-next-predict-error.png)

重点关注：

- 下一个时间片的预测准不准
- 每个时间片的 `MAPE`
- 每个时间片的 `PCOC` 达标率
- 在时间片基础上按 cost 占比融合得到整体 `MAPE / PCOC` 达标率

优点：

- 更能反映模型本身的时序拟合能力
- 更适合发现哪个时间片预测不好

缺点：

- 只看一步，不代表累计效果一定好

### 11.4 CPE / `sum2end`

`CPE`（Cumulative Predict Error）是在当前时刻计算到日结束整体预测值和真实值的差异。

![CPE](img/td-cumulative-predict-error.png)

构造方式：

- 起点之前使用真实值累计
- 起点之后使用预测值累计
- 与“全真实值累计”比较

重点关注：

- 从当前时点往后看，整体总量有没有预测准
- 更适合评估对预算、GMV、cost 等总量决策的支持能力

优点：

- 更贴近真实决策场景
- 更适合评估“今天剩余预算/收益”的预测是否可用

缺点：

- 容易掩盖局部时间片问题
- 有时正负误差会在累计后互相抵消

### 11.5 为什么要同时看 `MAPE` 和 `PCOC` 达标率

因为它们看的是两件互补的事：

- `MAPE` 看的是：预测值离真实值有多远
- `PCOC` 达标率看的是：预测比例是否稳定、是否落在可接受范围内

只看 `MAPE` 的问题是：

- 你知道偏差大小，但不知道是否存在系统性高估/低估

只看 `PCOC` 达标率的问题是：

- 你知道是否达标，但不知道具体误差到底有多大

所以把两者组合起来：

- 用 `MAPE` 看精度
- 用 `PCOC` 达标率看稳定性和可用性

### 11.6 为什么还要分 `NPE` 和 `CPE`

因为这个模型的用途不只是“预测下一个点”，而是要支撑后面的 MPC 决策。

所以必须同时看两层：

- `NPE`：看短期预测能力
- `CPE`：看累计预测能力

这套评估设计本质上是：

- `NPE + MAPE/PCOC`：看短期预测质量
- `CPE + MAPE/PCOC`：看累计决策可用性

### 11.7 指标矩阵

如果一天有 24 个小时、96 个 15min 时间片，评估可以按以下方式展开：

| 指标类型 | 评价窗口 | 指标 |
|---|---|---|
| 单步评价 | 每个未来时间片 | MAPE、PCOC 达标率 |
| 累积误差 | 从当前时间片到当天结束 | MAPE、PCOC 达标率 |
| 整体评价 | 各时间片 cost 加权融合 | 整体 MAPE、整体 PCOC 达标率 |

当前仍需补齐：

- `hitrate` 的具体定义和实现。
- `v1` / `v2` 的指标 diff。
- 训练时指标与线上评估指标的一致性。

## 12. 验证与上线注意事项

### 12.1 样本验证

样本验证的基本方法是：取同一个时间片，对比 Redis 内数据、样本内数据和 SearchLog 内统计数据是否一致。

已记录的问题：

- SQL 和样本内不一致：Kafka 内包含其他阶段信息，需要 org 侧 DE 将 stage 信息写入 Kafka 后，BE 过滤掉非混排数据。
- 流量回放 SQL 代码曾存在问题，已提给 DE 侧修复。
- Go 服务统计中需要关注时间判断和时区问题。

ReqNum 验证示例关注字段：

- `ads_id`
- `entrance`
- `regional_date`
- `regional_hour`
- `event_timestamp`
- `request_id`
- `user_id`
- `pgmv`
- `pctr`
- `pcr * pctr`
- `ecpm`

### 12.2 数据一致性验证

上线前需要做离在线一致性验证：

- 样本内数据 vs Redis 数据。
- Redis 数据 vs SearchLog 聚合。
- SearchLog vs TrackingLog join 后曝光数据。
- Go 服务统计结果 vs SQL 统计结果。
- 时间片、时区、region、entrance 的口径一致性。

### 12.3 SearchLog / TrackingLog join

流量回放需要关联参竞和曝光：

- SearchLog 提供候选集合、排序分数、`ecpm`、`ecpm_weight`、`pctr`、`pcr`、`pgmv` 等。
- TrackingLog 提供真实曝光事件，用于判断请求下哪些 item 曝光。
- 曝光相对参竞有延迟，样本需要考虑约 15min 等待。

如果曝光边界缺失或 join 不完整，会直接影响 `win_ratio`、cost、GMV 等回放指标。

### 12.4 TMS 曝光补充

引入 TMS 数据的目标是补充曝光数据，缓解 SearchLog/Tracking join 中曝光缺失或边界不连续的问题。

需要重点验证：

- 接入 TMS 后特征是否和原链路一致。
- `coef` 变大时结果是否单调。
- 实际曝光位置是否连续。
- 基于 `rank_score` 排序和基于 `rank` 排序的结果差异。

### 12.5 广告圈选规则

模型训练和推理的广告集合需要有稳定圈选规则。当前记录过点击阈值过滤分析，后续应补齐：

- 为什么需要点击阈值。
- 阈值如何影响样本规模和模型稳定性。
- 阈值对长尾广告覆盖的影响。
- 推理侧是否与训练侧保持同一圈选口径。

### 12.6 监控和拦截

上线前需要建设两类保护：

- 离线监控：Grafana 看板接入 Redis 预估值，配置异常报警。
- 上线拦截：调度框架检查 train/eval 指标，对异常模型做发布拦截。

线上 PCOC 监控可以按小时计算：

- 落表数据：`coef`、预估 `eCost/eGmv`、真实 `cost/gmv`。
- 计算 `pcoc`，观察预测与实际偏差。

## 13. 代码与参考资料

### 13.1 快速索引

| 项目 | 位置 |
|---|---|
| 当前主模型代码 | https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/models/cost_gmv_v2.py |
| 当前样本构建代码 | https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/samples/playback_fse.py |
| 当前特征切窗代码 | https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/models/features/single.py |
| 当前配置 YAML | https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/confs/models/cost_gmv_v2.yaml |
| 当前推理链路图位置 | `docs/common/sub-kb/2.3-bidding/img/td-serving-flow.png` |

### 13.2 关键代码路径

| 模块 | 路径/入口 | 说明 |
|---|---|---|
| 流量回放 PySpark | `paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback.py` | 回放样本计算逻辑 |
| 流量回放 local | `paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback_local.py` | 本地版本 |
| 流量回放 FSE 样例 | https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/samples/playback_fse.py | 展示样本依赖底表、曝光补充和回放重排逻辑 |
| 模型结构 | `models/*.py` | `model_name` 对应的模型结构文件 |
| v2 主模型代码 | https://git.garena.com/shopee/deep/paidads-alg/-/blob/master/ego_models/model_modules/bidding_env/models/models/cost_gmv_v2.py | 当前主讲版本 `cost_gmv_v2.py` |
| 模型配置 | `conf/models/*yaml` | 配置 `model_name`、features、hparams、labels |
| 模型入口 | `model.py` | 串联模型配置和训练入口 |
| 工具层 | `utils.py`、`layers/attention`、`loss` | attention、loss、工具封装 |
| Go 统计服务 | `paidads-bidding/sequence-model-processor/pkg/service/metric_generator/generator.go` | 样本/指标统计逻辑入口 |

### 13.3 数据表与服务

| 名称 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_roi2_ads_search_log` | 参竞、排序、预估值、请求维度基础数据 |
| `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` | 曝光 Tracking，用于判断真实 impression |
| `mkplpaidads_offline.dwd_sequence_coef` | 流量回放后的 `(ads_id, entrance, coef, 15min)` 指标矩阵 |
| Redis `timeseries_{placement}_{country}_{entrance}_{ads_id}` | 近线推理结果存储 |

### 13.4 平台入口

- AFP Scenario：`https://algolab.shopee.io/afp/scenario/detail?id=108&scopeId=12&projectId=11`
- EGO：模型训练与评估平台，具体任务入口待补。
- Grafana：Redis 预估值和线上 PCOC 监控看板待补。

### 13.5 参考文档

- https://docs.google.com/document/d/1JekSB-j8JKisjqNxSCANDNqE-cIiWH9vL9vUgHWjcRk/edit?tab=t.0#heading=h.s7d0m15ehyv
- https://docs.google.com/document/d/1FIwyGqFUwC31YPx7tHgn2FR7eCmnTvYxW5FEtznL0A0/edit?tab=t.0#heading=h.vzu5igw1mcdm
- DE 样本 TRD：`https://confluence.shopee.io/pages/viewpage.action?pageId=2758007275`

### 13.6 待补内容

- BEM / 时序模型在不同 entrance、region、pricing type 下的真实上线范围。
- `v1` / `v2` 特征差异和模型结构差异。
- `hitrate` 的定义、计算方式和使用场景。
- fallback 的具体填充策略和线上回退策略。
- Redis 推理结果落表方式，以及 Grafana 指标链接。
- EGO 训练任务、评估任务、发布任务的具体入口。
- MPC 统计模型与时序模型融合公式的最终实现位置。


---

# BEM Agent Handoff

# BEM Knowledge Card Agent Handoff

## 1. 目的

这份文档用于说明 [bem_knowledge_template.md](./bem-kb.md) 是如何搭起来的、目前已经补到了什么程度、主要依赖哪些来源、哪些内容已经相对可信、哪些内容仍然只是框架或待补项。

目标不是重复正文，而是帮助下一位 agent：

- 快速理解当前 BEM 知识卡片的组织方式。
- 知道哪些来源最值得继续深挖。
- 区分“已经有代码/文档支撑的内容”和“仍需继续核实的内容”。
- 直接沿着现有结构继续补，而不是重新起草一版。

## 2. 目标文件

- 目标文档：`docs/team/04.product-algo/bem-algo/bem-kb/bem_knowledge_template.md`
- 当前定位：Ads Basic Environment Model / Bidding Time Series Model 总览知识卡片
- 当前状态：已经不是初始化模板，已覆盖整体框架、流量回放、样本与特征、`v1/v2` 模型结构、训练推理链路、Loss 与评估、部分工程入口；但仍不是最终版操作手册

## 3. 构建思路

### 3.1 总体方法

当前这份 BEM 文档是按下面的顺序逐步补齐的：

1. 先用 Google Doc 建立“BEM 要解决什么问题、整体链路长什么样、TD 主线是什么”的全局认知。
2. 再把 Google Doc 中的叙述性内容压缩进知识卡片结构，形成“流量回放 -> 样本特征 -> 模型结构 -> 推理接口 -> 评估验证”的主线。
3. 然后回到本地代码，用真实代码路径补齐训练入口、配置层、模型注册、`v1/v2` 结构和关键 tensor 流向。
4. 对指标、Redis、proto、Ultra 预处理、上线注意事项这类工程内容，优先保留已经能从文档或代码确认的部分，不做过细推断。
5. 遇到不能确认的地方，不写死为事实，而是集中留在正文 `§12.5 待补内容` 和本 handoff 的“待补项”中。

### 3.2 决策规则

- 业务背景、方案目标、模块职责：优先相信 Google Doc / TD / 串讲文档。
- 训练链路、模型结构、配置入口：优先相信 repo 代码。
- 指标定义、线上口径、监控阈值：如果没有 SQL 或 dashboard 真值，不写成最终定义。
- 当 Doc 和代码冲突时，以代码为准；当代码也看不出真值时，明确标记“待补”。
- 对 `v1/v2` 差异，只写当前代码里能稳定确认的结构级差异，不把猜测写进对比表。

### 3.3 为什么这样写

这份 BEM 文档的目标不是单纯“把 TD 抄成 Markdown”，而是做成一个同时适合下面三种用途的知识卡片：

- 新人 onboarding 时能快速讲清主线。
- 汇报时能直接沿着章节顺序讲模型与链路。
- 后续继续深挖时，能知道哪些部分已经有依据，哪些部分需要继续补代码或 SQL。

所以当前采用的是“Doc 给主线，代码给真值，待补项显式保留”的写法。

## 4. 主要来源清单

### 4.1 目标文档本体

- `docs/team/04.product-algo/bem-algo/bem-kb/bem_knowledge_template.md`

作用：

- 作为持续回填的主文件。
- front matter 的 `source_refs` 记录了当前主要外部文档来源。
- 结构本身就是后续补充内容的落点地图。

### 4.2 Google Docs / TD

当前正文 front matter 中已显式记录了两份高价值 Google Doc：

- `https://docs.google.com/document/d/1JekSB-j8JKisjqNxSCANDNqE-cIiWH9vL9vUgHWjcRk/edit?tab=t.0#heading=h.s7d0m15ehyv`
- `https://docs.google.com/document/d/1FIwyGqFUwC31YPx7tHgn2FR7eCmnTvYxW5FEtznL0A0/edit?tab=t.0#heading=h.vzu5igw1mcdm`

另外正文里也引用了：

- DE 样本 TRD：`https://confluence.shopee.io/pages/viewpage.action?pageId=2758007275`

贡献：

- 提供 BEM 的整体框架、时序模型主线和讲述顺序。
- 提供流量回放、样本服务、推理服务、Redis proto、Ultra 预处理、评估指标等工程背景。
- 提供当前阶段项目进展和模块边界。
- 是 `§2-§11` 大部分叙述性内容的主要来源。

### 4.3 本地代码仓库

当前已经明确写入正文、或在补文时实际阅读过的关键路径包括：

- `paidads-alg/ego_models/model_modules/bidding_env/models/model.py`
- `paidads-alg/ego_models/model_modules/bidding_env/models/model_module.py`
- `paidads-alg/ego_models/model_modules/bidding_env/models/model_registry.py`
- `paidads-alg/ego_models/model_modules/bidding_env/models/confs/models/cost_gmv_v2.yaml`
- `paidads-alg/ego_models/model_modules/bidding_env/models/models/cost_gmv_v1.py`
- `paidads-alg/ego_models/model_modules/bidding_env/models/models/cost_gmv_v2.py`
- `paidads-alg/ego_models/model_modules/bidding_env/models/models/features/single.py`
- `paidads-alg/ego_models/model_modules/bidding_env/models/extra/schedule/ego_learner.yaml`
- `paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback.py`
- `paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback_local.py`
- `paidads-bidding/sequence-model-processor/pkg/service/metric_generator/generator.go`

贡献：

- 给出 EGO 训练入口、配置层、模型注册方式、特征切窗方式和训练 pipeline。
- 给出 `cost_gmv_v1` / `cost_gmv_v2` 的真实模型结构，用于整理 `§8`。
- 给出回放样本和部分统计逻辑的真实工程落点。

### 4.4 数据表、服务与平台入口

当前正文中已经明确记录了部分真实对象：

- 表：
  - `srdi_mart.dwd_sr_data_warehouse_roi2_ads_search_log`
  - `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`
  - `mkplpaidads_offline.dwd_sequence_coef`
- Redis：
  - `timeseries_{placement}_{country}_{entrance}_{ads_id}`
- 平台：
  - AFP Scenario
  - EGO
  - Grafana（链接待补）

贡献：

- 给出训练样本、回放产物、推理结果和平台入口的最小可用地图。

### 4.5 图片与结构图资产

当前正文已落入本地的图片包括：

- `img/td-framework.png`
- `img/td-sample-flow.png`
- `img/td-model-flow.png`
- `img/td-model-training.png`
- `img/td-ultra-preprocess.png`
- `img/td-next-predict-error.png`
- `img/td-cumulative-predict-error.png`
- `img/v1-architecture.png`
- `img/v2-architecture.png`

贡献：

- 用于支撑汇报时的整体框架、训练推理链路和 `v1/v2` 模型讲解。

## 5. 关键内容是怎么落到知识卡片里的

### 5.1 总览、定位与整体框架

来源：

- 两份主 Google Doc
- TD / 串讲材料

落点：

- `§0 一句话摘要`
- `§2 业务背景`
- `§3 BEM 定位`
- `§5 整体框架`

写法原则：

- 优先把 BEM 在链路中的职责讲清楚。
- 只保留跨文档重复出现、能作为共识的主线。

### 5.2 流量回放、样本与特征

来源：

- 主 Google Doc
- 流量回放相关代码路径
- DE 样本 TRD

落点：

- `§6 流量回放`
- `§7 样本与特征`

写法原则：

- 先讲“为什么要回放”，再讲“怎么扰动 coef、怎么判定竞得、怎么聚合指标”。
- 对样本和特征部分，优先保留粒度、窗口、分组、fallback 这些高层事实。

### 5.3 v1 / v2 模型结构

来源：

- `cost_gmv_v1.py`
- `cost_gmv_v2.py`
- 模型结构图

落点：

- `§8.1 v1 基线结构`
- `§8.2 v2 当前结构`
- `§8.3 v1 vs v2 总览对比`
- `§8.4-§8.6`

写法原则：

- `v1` 只保留基线结构和作用，不展开太多枝节。
- `v2` 作为主讲版本，强调模块结构、张量流向和升级方向。
- 对比部分以汇报友好的紧凑表格为主，不堆函数细节。

### 5.4 训练、推理与接口

来源：

- `model.py`
- `model_module.py`
- `model_registry.py`
- `cost_gmv_v2.yaml`
- `SingleWindowFeatureExtractor`
- 推理相关 TD / 设计说明

落点：

- `§9.1 训练链路`
- `§9.2-§9.5`

写法原则：

- 训练链路优先讲“代码结构 + 主流程”。
- 推理链路优先讲“写 Redis 给谁消费、key/value 长什么样、Ultra 怎么处理”。

### 5.5 Loss、评估与上线注意事项

来源：

- 主 Google Doc
- `v1/v2` 代码中的 loss 配置和评估项
- 样本 / 推理 / 监控相关说明

落点：

- `§10 Loss 与评估`
- `§11 验证与上线注意事项`

写法原则：

- 先保留评估维度和业务含义，再逐步补公式和监控阈值。
- 没有稳定真值的线上口径先不写死。

## 6. 已验证事实与推断边界

### 6.1 已验证

以下内容已经有比较明确的文档或代码支撑：

- BEM 主链路是“历史日志 / 流量回放 -> 样本服务 -> EGO 训练 -> 近线推理 -> Redis -> UltraCore / MPC 消费”。
- 样本粒度是 `ads_id + entrance + coef + 15min time slot`。
- 近线推理周期是 `15min`，Redis TTL 是 `24h`。
- `v1` 与 `v2` 确实是两套不同结构，且 `v2` 已经转向以 `gmv/cost` 为主的更重结构。
- `model.py -> model_module.py -> model_registry.py -> models/*.py` 是当前 EGO 训练主入口。
- `SingleWindowFeatureExtractor` 是训练窗口切分的关键入口之一。
- `playback.py` / `playback_local.py` 是流量回放样本计算路径。
- 正文中列出的表、Redis key、平台入口和主参考文档都已经在文档里显式落点。

### 6.2 仍是待补或半确认

以下内容仍然需要继续补证据：

- BEM 在不同 `entrance / region / pricing type` 下的真实上线范围。
- `v1/v2` 的完整特征差异、目标差异和实际线上切换状态。
- `hitrate` 的定义、公式和真实使用方式。
- fallback 的具体填充策略、线上回退逻辑和触发条件。
- Redis 推理结果是否还有落表或二次加工链路。
- Grafana 指标链接、线上监控面板和报警阈值。
- EGO 训练任务、评估任务、发布任务的具体入口和 job 配置。
- MPC 与统计模型的融合公式、实现位置和版本差异。

## 7. 实际使用过的工具与限制

### 7.1 有效路径

- Google Doc 读取：Google Workspace MCP / 本地同步脚本
- 本地 repo 阅读：shell + `rg` + `sed`
- Git 操作：本地分支提交、merge `master`、push 到个人分支
- Markdown 整理：直接在 `ads-workspace` 中回填文档和图片

### 7.2 遇到的限制

- 当前 BEM 指标口径部分主要来自 TD / 串讲，而不是成体系的 SQL 资产，因此“看板级真值”还不充分。
- 训练、推理、上线的真实平台入口还没有全部补齐，尤其是 EGO / Grafana / 发布任务。
- 一些工程链路在 Doc 中有叙述，但没有逐一核到 repo 或配置文件。

### 7.3 采用的 fallback

- 对结构性内容，先以 TD / 串讲为主，避免完全空白。
- 对训练链路和模型结构，回到代码确认主入口与关键模块。
- 对暂时找不到真值的内容，统一放入 `待补`，而不是在正文里写死。

## 8. 下一位 agent 的建议工作流

### 8.1 建议优先级

1. 先补 `§12.5` 里的待补项，尤其是上线范围、`v1/v2` 差异、fallback、EGO / Grafana 入口。
2. 再补 `§9` 和 `§10` 的“真值化”部分，把训练任务入口、评估任务入口、公式和口径补实。
3. 再补 `§11` 的验证与 rollout 细节，让文档从“介绍型”走向“排查型”。
4. 最后再考虑补更多案例、FAQ 和典型排障路径。

### 8.2 建议操作顺序

1. 先通读 [bem_knowledge_template.md](./bem-kb.md)，重点看 `§8-§12`。
2. 针对正文中的“待补”或明显依赖真值的内容，优先去找代码、平台入口或 SQL。
3. 如果要补 `v2` 结构，优先看 `cost_gmv_v2.py`，不要只依赖结构图。
4. 如果要补训练链路，优先看 `model.py / model_module.py / model_registry.py / cost_gmv_v2.yaml / SingleWindowFeatureExtractor`。
5. 回填时，优先补“路径、表名、配置名、接口名、asset id、公式”，再补大段解释。

### 8.3 更新原则

- 新加内容如果没有硬证据，放到“待补”，不要在正文里写成已确认事实。
- 如果某个结论只来自单份串讲材料，尽量在 handoff 或正文里保留来源线索。
- 对 `v1/v2`、评估口径、上线范围这类容易过时的内容，补充时最好同步更新 `last_verified_at`。

## 9. 可直接复用的关键信息

### 9.1 主线讲法

当前正文最稳定的一条讲述主线是：

```text
历史流量日志
-> 流量回放
-> 样本服务
-> 时序模型训练
-> 近线推理写 Redis
-> UltraCore / MPC 消费
```

### 9.2 v2 汇报框架

当前 `§8` 已经整理成适合汇报的结构：

- `v1 基线结构`
- `v2 当前结构`
- `v1 vs v2 总览对比`
- `v2 关键模块`
- `v2 主要张量流向`
- `如何理解这次升级`

### 9.3 高价值路径

- 主文档：`docs/team/04.product-algo/bem-algo/bem-kb/bem_knowledge_template.md`
- 训练入口：`paidads-alg/ego_models/model_modules/bidding_env/models/model.py`
- 主框架：`paidads-alg/ego_models/model_modules/bidding_env/models/model_module.py`
- 注册层：`paidads-alg/ego_models/model_modules/bidding_env/models/model_registry.py`
- 主配置：`paidads-alg/ego_models/model_modules/bidding_env/models/confs/models/cost_gmv_v2.yaml`
- v1 模型：`paidads-alg/ego_models/model_modules/bidding_env/models/models/cost_gmv_v1.py`
- v2 模型：`paidads-alg/ego_models/model_modules/bidding_env/models/models/cost_gmv_v2.py`
- 特征切窗：`paidads-alg/ego_models/model_modules/bidding_env/models/models/features/single.py`
- 回放样本：`paidads-alg/ego_models/model_modules/bidding_timeseries/samples/playback.py`

### 9.4 当前最值得继续补的点

- `v2` 对 `v1` 的真实工程替换范围
- `hitrate` / fallback / rollout 监控
- EGO 训练任务入口和评估任务入口
- Redis 结果的真实消费和监控闭环

## 10. 修改记录 Track

这一节用于持续记录每一次对 BEM 知识卡片和 handoff 的修改。

- 写法目标：简洁记录“改了什么、为什么改”。
- 记录方式：按 `10.1 / 10.2 / 10.3 ...` 继续追加。
- 使用原则：每次有阶段性更新时补一条，不需要写成长篇变更日志。

### 10.1 初始创建与第一轮整理（2026-04-24）

修改内容：

- 新建 `bem_knowledge_template.md` 与 `bem_knowledge_template_agent_handoff.md`。
- 基于两份主 Google Doc 搭起 BEM 主体框架，形成“流量回放 -> 样本与特征 -> 模型结构 -> 训练推理 -> Loss 评估 -> 上线注意事项”的主线。
- 补入 `v1` / `v2` 两张模型结构图，并把 `§8` 调整为更适合汇报的紧凑结构。
- 阅读 `cost_gmv_v1.py` / `cost_gmv_v2.py`，补充 `v1/v2` 模型结构总结、关键模块和对比关系。
- 阅读 `bidding_env/models` 目录，重写 `§9.1 训练链路`，整理为“代码结构 + 主流程”版本。
- 将本 handoff 从模板态扩展为正式交接文档，并补齐来源、已验证事实、待补项、建议工作流和可复用路径。

备注：

- 当前版本已经适合做介绍和汇报，但还不是完整的 on-call / troubleshooting 手册。
- 后续修改可继续从 `10.2` 开始追加。

### 10.2 当前模型口径收紧（2026-04-27）

修改内容：

- 在主文档中明确“当前时序模型结构”统一指 `cost_gmv_v2`。
- 补充 `cost_gmv_v2.py` 的代码入口，并保留 `v1` 作为基线对照。
- 收紧 `§7 样本与特征`，补齐样本切窗、底表连接、特征空间和 `encoder input = 38` 的代码口径。
- 删除 `§7.5 fallback 策略`。
- 将 `§10.1` 收紧为 `cost_gmv_v1` 的 loss 设计与关键权重配置。

### 10.3 章节重排与查阅收口（2026-04-28）

修改内容：

- 将知识库目录从 `knowledge_template` 改名为 `bem-kb`，并同步修正文内路径。
- 调整章节顺序为“`§6 样本与特征` -> `§7 流量回放` -> `§8 模型结构`”，减少主线跳跃。
- 将样本切窗与建模对象前移到 `§8.1`，让模型章节先讲清输入输出对象。
- 将 `§10` 拆成纯 `Loss`，新增独立的 `§11 离线评估`。
- 将 `样本验证` 挪到 `§12`，并在 `§13` 前增加代码与图的快速索引小表。

## 11. 最后提醒

- 不要把这份 handoff 当成正文摘要，它更像“下一步怎么继续补正文”的操作说明。
- BEM 这类文档很容易被 TD 牵着走，但后续继续补时要尽量往“代码 / SQL / 平台入口”收敛。
- 如果要继续补大块内容，优先补 `§9-§12`，因为这些部分最能把文档从“讲清楚”推进到“能落地排查”。
