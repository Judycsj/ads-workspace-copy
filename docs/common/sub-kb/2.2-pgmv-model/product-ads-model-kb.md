---
id: product_ads_pgmv_model_kb
title: Product Ads pGMV / UniCR 模型知识库
domain: pgmv-model
owner: Product Algo / Model Algo
source_refs:
  - docs/team/04.product-algo/model-algo/knowledge/unicr-kb-all.md
  - docs/team/04.product-algo/model-algo/knowledge/model-algo-kb.md
last_updated: 2026-05-11
last_verified_at: 2026-04-30
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1CtJmTWq4-fQqjH5n8Om2sNq46ixbyvan41ifT-Yut1g gdoc_url=https://docs.google.com/document/d/1CtJmTWq4-fQqjH5n8Om2sNq46ixbyvan41ifT-Yut1g/edit -->

# Product Ads pGMV 与 UniCR 模型知识库 / Product Ads pGMV and UniCR Model KB
> **Contributors**: haibo.di ｜ **最后更新**：2026-05-11 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/sub-kb/2.2-pgmv-model/product-ads-model-kb.md)

本文是 Product Ads pGMV / UniCR 的主知识库，聚焦业务目标、样本链路、模型结构、训练范式、线上推理、pGMV 校准与分析排查。全量特征明细、slot 表、覆盖率、FSE 链路和特征重要度已拆到 [product_ads_feature.md](product_ads_feature.md)，本文只保留特征体系和排查入口。

## 0. 信息索引与阅读路径 / Information Index and Reading Path

### 0.1 必要信息索引 / Required Information Index

| 类别 | 当前索引 |
|---|---|
| 代码仓库 GitLab 路径 | `shopee/deep/paidads-alg`、`shopee/deep/scoringX`、`shopee/search_recommend/offline/label_join_config` |
| 核心服务 SDU 路径 | **【待确认】需由 owner 通过 Space / SMC 确认 ScoringX / EGO Serving / 样本生产相关 SDU 路径** |
| ConfigCenter namespace | **【待确认】模型 serving、校准和特征开关的 ConfigCenter namespace 需补齐当前线上值** |
| Grafana dashboard | `featurelog_monitor_all`、EGO Predictor / OnlinePS 相关 dashboard、URanker uworker latency dashboard |
| 关键 Kafka topic | **【待确认】样本回流、rank dump、label backflow 如有 Kafka topic，需按当前生产配置补齐** |
| 核心 Hive 表名 | `mkplpaidads_offline.cr_train_data`、`mkplpaidads_search_ads.slot_quality_stats_new`、`mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`、`mp_paidads.dwd_advertise_performance_di__reg_s0_live` |
| 业务分析入口表 | `mkplpaidads_search_ads.item_basic_info_for_cali_and_case` |

### 0.2 本文读法 / How to Read

- 新同学先读第 1 章和第 2 章，建立“候选 item -> UniCR -> cali -> 竞价”的主链路认知。
- 看训练、样本、label 问题时读第 3 章和第 4 章。
- 看模型结构、特征、cali 时读第 5 章到第 7 章。
- 做数据分析、排查 PCOC 或 pGMV 异常时读第 8 章和第 9 章。
- 查全量特征和 slot 时跳转 [product_ads_feature.md](product_ads_feature.md)。

## 1. 全链路速览 / End-to-End Overview

### 1.1 UniCR 是什么 / What UniCR Is

UniCR 是 Paid Ads 精排阶段的转化率与 pGMV 预估模型，服务于广告竞价排序（Rerank）。它的目标不是只判断“会不会转化”，而是预估一次点击最终能带来多少 GMV，并把这个结果用于排序、出价和后续校准。

核心 pGMV 公式：

```text
pGMV = item_price × sold_cnt_smoothed × CR_7d
```

其中：

- `item_price`：商品价格。
- `sold_cnt_smoothed`：分段平滑后的销量信息；`x <= 2` 保持原值，`x > 2` 转为 `2 + log(x - 1)`。
- `CR_7d`：点击后 7 天内转化率预估。

UniCR 同时覆盖 direct 与 shop 两路价值：

- `direct_pcr_7d` / `shop_pcr_7d`：7 天转化率预估。
- `direct_pgmv_7d` / `shop_pgmv_7d`：7 天 pGMV 原始预估。
- `direct_order2pay` / `shop_order2pay`：下单到支付率。
- `direct_pcr_{1h,6h,1d,3d}` / `shop_pcr_{1h,6h,1d,3d}`：延迟反馈多窗口 CR。
- `ads_direct_atc` / `ads_shop_atc`：加购率辅助任务。

### 1.2 主链路一图 / Main Flow

```text
粗排候选 item
-> UniCR 主模型打分
-> pGMV cali 在线后校准
-> 竞价侧组合 value / eCPM
-> Rerank 排序与投放

Rank FeatureDump + UB 行为
-> RawSample
-> FP
-> TrainData
-> LabelJoin 回刷
-> Seed / Increment 训练
-> Eval / Release
```

### 1.3 业务指标与技术指标 / Business and Technical Metrics

UniCR 的业务目标是让广告排序更准确地反映点击后的真实商业价值。业务实验重点看 AB 平台指标，例如 GMV、revenue、broad GMV、adv cost 和 Search 场景 bad query rate。

PCOC 是模型技术评估/校准评估指标，不归为业务指标。当前 UniCR 模型技术评估主要维护点击归因口径 PCOC：按点击发生日归因，等待点击后 7 天转化或 GMV 完整回流后，评估这批点击的预测是否准确。

```text
pCR 点击归因 PCOC  = sum(pcr_7d) / sum(actual_order_7d)
pGMV 点击归因 PCOC = sum(pred_pgmv_7d) / sum(actual_gmv_7d)
```

PCOC 解读：

- `PCOC ≈ 1`：整体预估接近真实。
- `PCOC > 1`：整体高估。
- `PCOC < 1`：整体低估。

### 1.4 精排业务背景 / Rerank Business Context

促销节奏：

- 大促：每个月一次，日期按月份递增，例如 1 月 1 日、2 月 2 日。
- 小促：每个月月中和月末各一次。
- 促销时间和力度维护在 Google Sheet：`https://docs.google.com/spreadsheets/d/1fzKsIQz1T7saO1mvODUHQ25L9IJ_H5pwBTE2Qvjcmx4/edit?gid=1670187272#gid=1670187272`

AB 平台常看业务指标：

| 指标 | 统计范围 | 解读 |
|---|---|---|
| `order_per_uu(*100)` | 所有场景 | 订单效率 |
| `gmv` | 所有场景 | GMV 规模 |
| `gmv_995_v2` | 所有场景 | 去极值 GMV |
| `revenue_usd` | 所有场景 | 广告收入 |
| `broad_gmv_usd` | 所有场景 | broad GMV |
| `advv_cost_7d` | 所有场景 | 广告成本 / 消耗 |
| `bad_query_rate(org+ads)` | 仅 Search | Search 体验 guardrail |
| `bad_query_rate(org)` | 仅 Search | Organic 相关性 guardrail |
| `bad_query_rate(ads)` | 仅 Search | Ads 相关性 guardrail |

## 2. 线上模型链路 / Online Model Chain

### 2.1 两个核心模型 / Two Core Online Models

精排阶段至少有两个串联的核心在线模型：

| 模型 | 输入 | 输出 | 作用 |
|---|---|---|---|
| UniCR 主模型 | 粗排阶段筛出的候选 item 及上下文特征 | direct / shop PCR、pGMV、Order2Pay、ATC | 对候选 item 做细粒度商业价值预估 |
| pGMV cali 模型 | UniCR 输出的原始 pGMV | 普通版与大促版校准 pGMV | 做在线 post-calibration，降低系统性偏差 |

当前文档主体默认以 ID 地区 `gpu_nsr_atc_v1_id_v0` / `exp_i_atc_v1_id` 链路为主说明；L2 与 BR 的版本信息保留为索引，不在本文重复展开。

### 2.2 已推全模型版本 / Launched Model Versions

UniCR 主模型版本，截止 2026-04-26：

| Region | Model version | DAG | 代码 |
|---|---|---|---|
| ID | Seed: `exp_s_atc_v1_id`；Increment: `exp_i_atc_v1_id` | `gpu_nsr_atc_v1_id_v0` / `gpu_nsr_atc_v1_id_ytl` | `paidads-alg/ego_models/model_modules/unicr_v3` |
| L2(TW, SG, TH, PH, MY, VN) | Seed: `exp_s_uni_atc_v1_L2`；Increment: `exp_i_uni_atc_v1_L2` | `gpu_pgmv_uni_L2_atc_v1` | `paidads-alg/ego_models/model_modules/unicr_l2_v3` |
| BR | Seed: `exp_s_nsr_br`；Increment: `exp_i_nsr_br` | `gpu_nsr_br` | **【待确认】BR 源码结构未完整纳入本文对比** |

pGMV cali 模型版本，截止 2026-04-26：

| Region | Model version | DAG |
|---|---|---|
| ID | `prd_i_id_item` | `gpu_pgmv_cali_id_item` |
| L2(TW, SG, TH, PH, MY) | `exp_i_l2_item` / `exp_i_l2_item_bdc` | `gpu_pgmv_cali_l2_item` |
| VN | `exp_i_vn_item` | `gpu_pgmv_cali_vn_item` |
| BR | `gpu_pgmv_cali_br_all` | `gpu_pgmv_cali_br_all` |

### 2.3 候选到竞价分 / Candidate to Bid Score

第 0 步：粗排给精排候选 item，当前补充口径是上限 `400`。

第 1 步：UniCR 输出 direct / shop 两路原始 PCR 与 pGMV。

第 2 步：cali 模型对 `direct_pgmv_7d` / `shop_pgmv_7d` 做后校准，输出普通版和大促版。

第 3 步：竞价侧组合价值分。

普通期口径：

```text
ecpm = pctr * (direct_pcr_7d * cali_direct_pgmv_7d_v2
             + shop_pcr_7d * cali_shop_pgmv_7d_v2) * target_cir
```

大促期口径：

```text
ecpm = pctr * (direct_pcr_7d * cali_direct_pgmv_7d_prom_v2
             + shop_pcr_7d * cali_shop_pgmv_7d_prom_v2) * target_cir
```

只看模型链路时，可简化为：

```text
value = direct_pcr_7d * cali_direct_pgmv_7d
      + shop_pcr_7d * cali_shop_pgmv_7d
```

### 2.4 线上输出映射 / Online Output Mapping

代码位置：`online-bidding/internal/rule/productads/rerank/model/rerank_uni_pgmv.go`

| 模型 Head / UniPcr key | 线上变量 | 用途 |
|---|---|---|
| `direct_pcr_7d` | `directPcr7d` | Direct 7 天转化率 |
| `shop_pcr_7d` | `shopPcr7d` | Shop 7 天转化率 |
| `direct_pgmv_7d` | `directPgmv7d` | Direct 7 天原始 pGMV |
| `shop_pgmv_7d` | `shopPgmv7d` | Shop 7 天原始 pGMV |
| `direct_order2pay` | `directOrder2Pay` | Direct 下单到支付率 |
| `shop_order2pay` | `shopOrder2Pay` | Shop 下单到支付率 |
| `direct_pcr_{1h,6h,1d,3d}` | `directPcr{1h,6h,1d,3d}` | Direct 延迟反馈多窗口 CR |
| `shop_pcr_{1h,6h,1d,3d}` | `shopPcr{1h,6h,1d,3d}` | Shop 延迟反馈多窗口 CR |
| `cali_direct_pgmv_7d_v2` | `caliDirectPgmv7dV2` | 校准后 Direct pGMV |
| `cali_shop_pgmv_7d_v2` | `caliShopPgmv7dV2` | 校准后 Shop pGMV |
| `cali_{direct,shop}_pgmv_7d_prom_v2` | `caliDirectPgmv7dPromV2` / `caliShopPgmv7dPromV2` | 大促校准 pGMV |
| `ads_direct_atc` / `ads_shop_atc` | 未在该 rule 中使用 | ATC 率辅助输出 |

## 3. 样本与 Label 链路 / Sample and Label Pipeline

### 3.1 样本主流程 / Main Sample Flow

样本产出链路的职责是：拼接 Rank FeatureDump 与用户行为，经 FP 处理后落盘为 Parquet TrainData，再通过 LabelJoin 将转化标签回刷到样本中。

```text
在线 Rank FeatureDump + UB 用户行为
-> 流拼接（Kafka + HBase）
-> RawSample（Request 粒度）
-> FP（Request -> Item 粒度）
-> TrainData（Parquet）
-> LabelJoin（T-1 ~ T-8 回刷）
-> EGO 训练
```

三大阶段：

| 阶段 | 说明 | 数据粒度 |
|---|---|---|
| 流拼接 | 实时消费 UB 与 FeatureDump Kafka，按 `RequestId + ItemId` 拼接，落盘 RawSample | Request |
| FP | 调用 FP lib，将 RawSample 转为 EGO 可消费的 TrainData | Item |
| Label 回流 | 将 order、pay、ATC、GMV 等回刷到 TrainData | Item |

### 3.2 流拼接与过滤 / Stream Join and Filtering

流拼接机制：

- 使用 HBase 缓存用户行为，延迟消费 FeatureDump Kafka。
- 保证约 1 小时拼接窗口，该窗口可回流约 99.6% 的 impression 和 click。
- 拼接成功的 RawSample 落盘到 HDFS。

采样与过滤规则：

| 阶段 | 条件 | 处理 |
|---|---|---|
| Rank Dump | 请求中没有 ads item | 整个请求丢弃 |
| Rank Dump | 请求中有 ads item | dump 全部 ads item + 50% organic item |
| 流拼接 | FeatureDump 中没有 click | 丢弃 |
| 流拼接 | 拼接到 UB 的 FeatureDump | 保留 impression 与 click 对应 item 的特征，unimpr item 按采样逻辑保留 |
| Convertor | `search_info_item_type_str == 'organic'` | 过滤 organic 自然流量样本 |
| Convertor | `'pcr' not in debug_info_dict or debug_info_dict['pcr'] == 0` | 过滤线上无广告精排打分或精排 pCR 为 0 的样本 |

### 3.3 RawSample 与 FP / RawSample and FP

RawSample 关键信息：

| 项目 | 说明 |
|---|---|
| 数据格式 | 列存，已从行存升级 |
| 数据分区 | Region + Day + Hour；分区时间为 Rank dumpTime |
| 数据内容 | `FullDumpContextV2`，包含 Rank FeatureDump Arrow 特征、DumpContext、Join 后的 Impr / Click UB |
| SG Hive 表 | `mkplpaidads_offline.ssp_raw_sample_uni_ads_hourly_reg_live` |
| US Hive 表 | `mkplpaidads_offline.ssp_raw_sample_uni_ads_hourly_br_live` |

FP 关键信息：

| 模型 | AFP Scene | 产物 |
|---|---|---|
| CR / UniCR | Scene id = 71 | Item 粒度 CR TrainData |
| CTR | Scene id = 82 | Item 粒度 CTR TrainData |

FP 输出遵循 EGO Parquet Format，每条样本包含 `action_info`、`debug_info` 等字段。

### 3.4 TrainData / TrainData

UniCR 使用的核心训练数据：

```text
hdfs://R2/projects/mkplpaidads_offline/hdfs/prod/alg/ads/train_data_parquet/cr/all
```

| 数据集 | HDFS 路径 | Hive / Marker |
|---|---|---|
| CR TrainData | `.../train_data_parquet/cr/all` | Hive: `mkplpaidads_offline.cr_train_data`；Marker: `mkplpaidads_offline.ads_cr_${region}_daily_virtual` |
| CTR TrainData | `.../train_data_parquet/ctr/all` | Hive: `mkplpaidads_offline.ctr_train_data`；Marker: `mkplpaidads_offline.ads_ctr_${region}_daily_virtual` |
| CTR Eval | `.../train_data_parquet/ctr/all` | Marker: `mkplpaidads_offline.ads_ctr_eval_${region}_gentraindata` |

查询方式：

```sql
SELECT *
FROM mkplpaidads_offline.cr_train_data
WHERE ...;
```

slot 数据需要直接读 Parquet，例如：

```sql
CREATE TEMPORARY VIEW sample
USING parquet
OPTIONS (
    path "hdfs://R2/projects/mkplpaidads_offline/hdfs/prod/alg/ads/train_data_parquet/cr/all/ID/2025-05-27/00"
);

SELECT slot_1224, count(*)
FROM sample
GROUP BY slot_1224;
```

### 3.5 Label 回流 / Label Backfill

LabelJoin 将用户转化行为回刷到已经落盘的 TrainData。由于转化存在延迟，CR Label 每天会对 T-1 至 T-8 共 8 天样本持续回刷。回刷完成后，`mkplpaidads_offline.ads_cr_${region}_daily_virtual` 就绪，下游 EGO 训练即可启动。

LabelJoin 本质是 Spark SQL Join：

```text
TrainData(request_id, item_id, features, action_info, debug_info)
LEFT JOIN 上游归因表(request_id, item_id, order, pay, gmv, atc ...)
-> TrainData(action_info / label 字段更新)
```

上游归因关键字段：

- `ads_direct_order_cnt`：Direct Ads Order 数。
- `ads_shop_order_cnt`：Broad 中排除 Direct 后的 Shop Ads Order 数。
- 上游按 `user_id + request_id + item_id` 聚合，LabelJoin 再按 `request_id + item_id` 回刷。
- T-1 样本先做 `first_hour` 回刷，后续通过 `delay1d` 到 `delay7d` 持续补齐 7 天归因窗口。

### 3.6 训练 Label 与 Loss 对应 / Training Labels and Loss Mapping

当前 UniCR 主模型 `final_loss` 由四组 loss 相加：

```text
final_loss = cr_loss + order2pay_loss + delay_feedback_loss + act_loss
```

真正参与 loss 的 label：

| Loss 组 | label_idx | 模型读取名 | 预测 Head | 样本级 Weight |
|---|---:|---|---|---|
| CR Loss | 0 / 2 | `direct_label_1d` / `shop_label_1d` | `direct_cr_1d` / `shop_cr_1d` | 对应窗口 `label_weight` |
| CR Loss | 4 / 6 | `direct_label_3d` / `shop_label_3d` | `direct_cr_3d` / `shop_cr_3d` | 对应窗口 `label_weight` |
| CR Loss | 8 / 10 | `direct_label_7d` / `shop_label_7d` | `direct_cr_7d` / `shop_cr_7d` | 对应窗口 `label_weight` |
| Delay Loss | 24 / 26 | `direct_label_1h` / `shop_label_1h` | `direct_pcr_1h` / `shop_pcr_1h` | 对应窗口 `label_weight` |
| Delay Loss | 48 / 50 | `direct_label_6h` / `shop_label_6h` | `direct_pcr_6h` / `shop_pcr_6h` | 对应窗口 `label_weight` |
| Order2Pay Loss | 44 / 46 | `direct_pay_label` / `shop_pay_label` | `direct_order2pay` / `shop_order2pay` | `pay_weight` |
| ACT Loss | 28 / 52 | `ads_direct_act_label` / `ads_shop_act_label` | `ads_direct_act` / `ads_shop_act` | `act_weight` |

不直接参与 `final_loss` 的 label / weight：

| label_idx | 名称 | 当前用途 |
|---:|---|---|
| 30 / 32 | `direct_gmv_label` / `shop_gmv_label` | `direct_pgmv_7d` / `shop_pgmv_7d` XRMSE target 与评估 |
| 34 / 36 | `direct/shop_gmv_seg_label` | 保留字段，当前不进 `final_loss` |
| 12 / 14 | `shop_valid_weight` / `broad_valid_weight` | 监控或 target 辅助权重 |
| 16 / 18 / 20 / 22 | `search/dd/ymal/pp_weight` | 分场景 target 评估 |
| 38 / 40 | `uplift_weight` / `uplift_zero_weight` | 历史 Uplift 相关 target |
| 42 | `placement_weight` | placement 信息，模型 target 中另用 `placement in (40, 50)` 形成 `final_weight` |

### 3.7 LabelJoin 作业与操作 / LabelJoin Jobs and Operations

LabelJoin 作业类型：

| 作业类型 | 说明 |
|---|---|
| `first_hour` | 最新样本首次回刷，即 T-1 数据，只含小时级回流 |
| `delay{N}d` | 对 T-(N+1) 天样本做第 N 天回刷，N=1~7 |
| `2day` | 跨天级回刷，聚合前一天所有小时级结果 |

新调度方案解除 7 天回刷作业之间的日间依赖，各分区可并行运行；仅保证单分区内部 `delay0d_H -> delay1d_H -> delay1d_D -> ...` 的最小串行约束。产出时效从旧方案约 06:00 提前到小时级约 01:30、含天级全量约 03:00。

常见操作：

- 升级 FP Scene Version：AlgoLab 发布新 version -> 修改 DataSuite FP 作业 Template `scene_version` -> 同步子作业并发布。
- 升级 FP 算子：联系 FP 侧发布新 FP tag -> 联系样本侧升级。
- 新增 Label：修改 `label_join_config/ads_cr` -> 打 `ads_cr-*` tag 触发 CI/CD -> 修改 DataSuite LabelJoin 作业 `join_generator_version` -> 测试发布。

## 4. 训练范式与评估 / Training and Evaluation

### 4.1 两阶段训练 / Two-Stage Training

UniCR 日常训练采用“种子轮 + 增量轮”的两阶段方式，在标签完整性与样本新鲜度之间折中。

| 阶段 | 配置 | 目的 |
|---|---|---|
| Seed | 使用 T-8 完整回流数据，从 model bank 初始化，只训练 1 天 | 建立标签干净、稳定的参数基线 |
| Increment | 基于 seed ckpt，顺序吃 T-7 到 T-2 六天数据 | 利用更新鲜样本，并通过 `label_weight` 处理标签未完整回流 |
| Eval | 使用 T-1 数据评估 | 检查 AUC / PCOC，通过门限后自动发布 |

ID 训练配置摘要：

| 项目 | Seed | Increment |
|---|---|---|
| 入口文件 | `unicr_pgmv_id_seed.py` | `unicr_pgmv_id_inc.py` |
| task 配置 | `Product_Rank_V3_exp_s_atc_v1_id/task.yaml` | `Product_Rank_V3_exp_i_atc_v1_id/task.yaml` |
| 训练数据 | T-8，1 天完整回流 | T-7 ~ T-2，6 天连续增量 |
| convertor | `convertor_pgmv_prob_id.py` | `convertor_pgmv_prob_id_self.py` |
| 资源 | 15 workers × A30 MIG，45 sample_servers | 16 workers × A30 MIG，48 sample_servers |

评估与发布：

| 项目 | 配置 |
|---|---|
| 评估数据 | T-1 |
| 评估来源 | 增量轮最新 ckpt |
| `check_metrics` | `direct_pcr_7d` AUC ∈ [0.8, 1.01]、PCOC ∈ [1.0, 2.0]；`shop_pcr_7d` AUC ∈ [0.8, 1.01]、PCOC ∈ [1.1, 2.5] |
| 线上推理 | 使用最新增量轮 ckpt |
| serving 模型 | `gpu_nsr_atc_v1_id_v0`，项目 `PaidadsUniCR`，executor `trt` |

### 4.2 延迟反馈建模 / Delayed Feedback Modeling

广告转化存在显著延迟反馈：用户点击广告后，实际转化可能在 1 小时到 7 天内任意时间发生。UniCR 用条件概率级联分解长窗口 CR。

```text
CR_7d <- 主塔直接输出

CR_3d = cr_3d_prob × CR_7d
CR_1d = cr_1d_prob × CR_3d
PCR_6h = prob_6h × CR_1d
PCR_1h = prob_1h × PCR_6h
```

设计意义：

- `CR_7d` 用完整回流数据训练，作为稳定基准。
- 短窗口条件概率补充时效性。
- 未完整回流标签通过 `label_weight=0` 和条件性 `stop_gradient` 屏蔽。
- 线上可根据业务需要选用不同时间窗口 head。

梯度阻断规则：

| 条件概率头 | 阻断条件 | 含义 |
|---|---|---|
| `cr_3d_prob` | `label_weight_7d == 0` | 7d 标签未回流，不训练 3d\|7d 条件概率 |
| `cr_1d_prob` | `label_weight_3d == 0` | 3d 标签未回流，不训练 1d\|3d 条件概率 |
| `1h_6h_prob` | `label_weight_6h == 0` | 6h 标签未回流，不训练 1h\|6h 条件概率 |
| `6h_1d_prob` | `label_weight_1d == 0` | 1d 标签未回流，不训练 6h\|1d 条件概率 |

shop 路有同样逻辑。

### 4.3 损失函数 / Loss Functions

整体损失：

```text
Final Loss = CR Loss + Delay Feedback Loss + Order2Pay Loss + ACT Loss
```

当前任务级口径：

- 四个损失组组间系数均为 `1.0`，直接相加。
- 组内各子 loss 直接相加，没有额外 task-level 手工权重。
- 每个子 loss 内部仍按样本级 `label_weight`、`pay_weight` 或 `act_weight` 加权。
- `direct_pgmv_7d` / `shop_pgmv_7d` 是组合输出与评估 target，没有单独 pGMV loss。
- 当前有效 loss 都使用手写 Binary Cross Entropy，并按样本权重求和。

```text
loss = label * -log(predict + 1e-8)
     + (1 - label) * -log(1 - predict + 1e-8)
final_loss = reduce_sum(loss * weight)
```

### 4.4 离线评估结果 / Offline Evaluation Results

数据来源：EGO Job `#44471067` evaluation，评估日期 2026-04-12，ckpt 来自 2026-04-11 增量轮。

核心 Head 天级 AUC：

| Head | AUC | 说明 |
|---|---:|---|
| `direct_pcr_7d` | 0.8551 | Direct 7 天 CR |
| `shop_pcr_7d` | 0.9093 | Shop 7 天 CR |
| `broad_pcr_7d` | 0.8485 | Broad 7 天 CR |
| `direct_order2pay` | 0.7716 | Direct 下单到支付率 |
| `shop_order2pay` | 0.7973 | Shop 下单到支付率 |
| `ads_direct_atc` | 0.7672 | Direct ATC |
| `ads_shop_atc` | 0.8530 | Shop ATC |

延迟回流各窗口 AUC：

| 窗口 | Direct AUC | Shop AUC |
|---|---:|---:|
| 7d | 0.8551 | 0.9093 |
| 3d | 0.8554 | 0.9101 |
| 1d | 0.8557 | 0.9109 |
| 6h | 0.8562 | 0.9115 |
| 1h | 0.8568 | 0.9119 |

分 Domain AUC：

| Domain | Direct PCR 7d | Shop PCR 7d | Direct pGMV 7d AUC | Shop pGMV 7d AUC | Broad pGMV 7d AUC |
|---|---:|---:|---:|---:|---:|
| Search | 0.8627 | 0.9047 | 0.7957 | 0.8648 | 0.7870 |
| Daily Discover | 0.8139 | 0.8897 | 0.7187 | 0.8451 | 0.7048 |
| YMAL / PP | 0.8305 | 0.8801 | 0.7467 | 0.8310 | 0.7370 |
| Product Page | 0.8011 | 0.8742 | 0.7062 | 0.8268 | 0.6957 |

### 4.5 样本后验分布 / Sample Posterior Distribution

数据来源：EGO Job `#44464858` seed 训练，训练数据日期 2026-04-05（T-8），ID 地区。

样本量：

| 指标 | 值 |
|---|---:|
| 全流量总样本 | 约 302.9M |
| Search 样本 | 约 155.5M，51.3% |
| Daily Discover 样本 | 约 67.1M，22.2% |
| YMAL 样本 | 约 40.6M，13.4% |
| Product Page 样本 | 约 10.9M，3.6% |

核心后验：

| Target | Label Rate | 正样本数 | 含义 |
|---|---:|---:|---|
| `direct_pcr_7d` | 3.51% | 约 10.64M | 直接购买 7 天转化率 |
| `shop_pcr_7d` | 0.53% | 约 1.59M | 店铺购买 7 天转化率 |
| `broad_pcr_7d` | 3.82% | 约 11.58M | 宽口径 7 天转化率 |
| `direct_order2pay` | 80.28% | 约 8.54M | 直接购买下单到支付率 |
| `shop_order2pay` | 83.77% | 约 1.33M | 店铺购买下单到支付率 |
| `ads_direct_atc` | 17.77% | 约 53.81M | 直接加购率 |
| `ads_shop_atc` | 1.66% | 约 5.04M | 店铺加购率 |

关键观察：

- Direct 转化率远高于 Shop，ID 地区用户以直接购买为主。
- Direct 1h 回流率约 84.5%，Shop 约 66.5%；Shop 延迟回流更显著。
- Order2Pay 率 80%+，说明下单后支付概率较高。
- ATC 率显著高于 CR，可提供更稠密的辅助信号。
- 种子轮训练后核心 target PCOC 基本接近 1。

## 5. 特征体系 / Feature System

### 5.1 特征总览 / Feature Overview

UniCR 特征以稀疏 ID 与行为统计为主，整体可理解为五层输入：

1. 用户基础属性。
2. 当前上下文与主商品信息。
3. 候选商品静态与统计特征。
4. 用户行为序列与偏好聚合。
5. 用户-商品 / 主商品-候选商品交叉特征。

主要特征族：

| 分组 | 规模 / 形态 | 作用 |
|---|---|---|
| Dense | 2 个 slot | 连续统计特征，通过 `AutoDis` 编码 |
| OneHot | 5 个 slot | 离散化统计特征转 embedding |
| Sparse | 约 316 个 slot | 用户、商品、店铺、类目和统计先验 |
| Target | 4 个 slot | `item_id`、`shop_id`、`global_subcat`、`global_thirdcat` |
| Query | 1 个 slot | 搜索词分词后的 query 表达 |
| 行为序列 | click 长度 500，cart/order 长度 128 | 通过 `SimpleAttentionV3` 做 target-aware 表达 |
| Extra | 46 个 slot | 广告、用户、场景补充信号 |
| Entrance / OrgPredict / Price / SoldCnt | 若干连续值和桶化特征 | domain、上一轮预估、价格与销量平滑相关输入 |

当前全量特征统计为 494 个特征，包含 sparse=469、dense=20。分类列主要用于快速分析与分桶参考，结果可能不完全准确。

### 5.2 模型内处理方式 / Model-Side Processing

| 特征类型 | 处理方式 |
|---|---|
| Dense | `AutoDis` 连续值离散化编码 |
| Sparse | embedding lookup |
| 行为序列 | `SimpleAttentionV3` 提取目标相关兴趣表达 |
| Domain 特征 | `EpNet` 做 domain-aware gating |
| 交叉特征 | `FINT` 做二阶特征交叉 |
| 融合表征 | 进入 `MMOE-STAR` 主干 |

### 5.3 特征侧已知问题 / Known Feature Issues

- 部分特征分类与归属仍有待确认项。
- 覆盖率、空值率、零值率分布不均。
- 接入层偏工程堆叠，特征解释成本较高。
- 细节特征很多，但不是所有 slot 都能带来稳定增益。
- 需要重点排查 train-serve gap、序列截断、低覆盖和低收益冗余 slot。

## 6. 模型架构 / Model Architecture

### 6.1 主体结构 / Main Architecture

UniCR 是一个面向广告转化与 pGMV 预估的多任务模型，底座采用 `MMOE-STAR`。

```text
特征编码
-> EpNet domain-aware gating
-> FINT 二阶特征交叉
-> MMOE-STAR 多任务主干
-> CR / Delay / ATC / Order2Pay 多个输出塔
-> price × sold_cnt × CR_7d 组合得到 pGMV
```

关键模块：

| 模块 | 类 / 函数 | 关键参数 | 作用 |
|---|---|---|---|
| AutoDis | `AutoDisLayer` | `emb_dim=16` | 连续特征自动离散化为 embedding |
| OneHotToEmb | `OneHotToEmbeddingLayer` | `embedding_dim=16` | OneHot 编码转稠密 embedding |
| HardBucketize | `HardBucketizeLayer` | `bucket_size=10000, emb_size=16` | OrgPredict 硬分桶后转 embedding |
| SimpleAttentionV3 | `SimepleAttentionV3` | - | target attention 提取行为序列兴趣 |
| EpNet | `EpNetLayer` | - | 基于 domain embedding 对特征做 gating |
| FINT | `fint_interaction_layer` | `order=2, dropout=0.0` | 二阶特征交叉 |
| MMOE-STAR | `MMOESTAR` | experts=4, domains=5, tasks=6 | 多专家、多域、多任务主干 |
| Order2Pay | `Order2PayLayer` | hidden=(128,64) | 下单到支付率预估 |
| ACT | `ActLayer` | hidden=(128,64) | ATC 率预估 |
| ProbHour | `ProbHourLayer` | hidden=(128,64) | 1h / 6h / 1d 延迟反馈概率 |

关键结构参数：

- Expert 数：4。
- Domain 数：5。
- CR Task 数：6。
- Tower DNN：`(64, 1)`。
- Expert DNN：`(256, 128)`。

### 6.2 Domain 定义 / Domain Definition

`STAR` 的 domain 不是直接使用原始 `entrance id`，而是先通过 `CATEGORIES` 映射到离散 domain，再由 `OneHotLayer` 做 one-hot。`num_domains=5` 来自 4 个显式业务场景 domain + 1 个默认兜底 domain。

| Entrance ID | Domain Index | 含义 |
|---|---:|---|
| 未命中 `CATEGORIES` 的其他入口 | 0 | 默认 / other |
| 1 | 1 | Search |
| 3 | 2 | Daily Discover |
| 4 | 3 | YMAL |
| 8, 9, 10, 11 | 4 | Product Page / PP 等 |

样本 convertor 中的 `search_weight / dd_weight / ymal_weight / pp_weight` 也与上述映射对齐。

### 6.3 Direct 与 Shop 双路输出 / Direct and Shop Outputs

模型同时覆盖 direct 和 shop 两类转化维度，避免只看直接购买而忽略经店铺路径形成的转化价值。

```text
broad_cr_7d = direct_cr_7d + shop_cr_7d
broad_pgmv  = direct_pgmv + shop_pgmv
```

### 6.4 Region 间结构差异 / Cross-Region Differences

已对比 ID 模型 `unicr_v3/pgmv_order2pay_id_prob_sir.py` 与 L2 模型 `unicr_l2_v3/delf_other_region_prob.py`：

| 对比项 | ID | L2 | 影响 |
|---|---|---|---|
| Region 特征 | 没有单独 region-conditioned 分支 | 额外读取 `REGION_DENSE_SLOT=46354` 与 `REGION_SPARSE_SLOT=30585` | 显式注入 region 信息 |
| HardBucketize | 不感知 region | `num_regions=8` 并传入 `region_indicator` | pCTR / pCR 等上一轮预估特征按 region 条件化 |
| AutoDis | 不感知 region | `num_regions=8` 并传入 `region_indicator` | dense 与 org-predict 特征按 region 条件化 |
| 有效 head | CR、Delay、Order2Pay、ATC、pGMV 派生 | 与 ID 保持一致 | 暂无确认的 region 专用 head 差异 |

BR 暂未纳入源码级结构对比。源码中 `ATC` / `ACT` 命名差异按笔误或命名遗留处理，不作为结构差异。

## 7. pGMV 校准系统 / pGMV Calibration System

### 7.1 校准目标 / Calibration Goal

cali 是一套多粒度、多层级的在线 pGMV 后校准系统，用来对上游 UniCR 模型的 pGMV 预测值做 post-calibration，使其更接近真实 GMV 分布。

目标：

- 消除系统性偏差，使 `E[pGMV] ~= E[GMV]`。
- 在地区、item、时间窗口等维度上保持校准精度。
- 在大促等特殊时段动态调整校准比例。

被校准对象：

```python
direct_pgmv_7d = ego.get_dense_feature(name='direct_pgmv_7d', dim=1, feature_type=ITEM)
shop_pgmv_7d = ego.get_dense_feature(name='shop_pgmv_7d', dim=1, feature_type=ITEM)
```

输出 4 个 `ego.Target`：

| Target | 含义 |
|---|---|
| `cali_direct_pgmv_7d_v2` | Direct pGMV 校准值，普通版 |
| `cali_shop_pgmv_7d_v2` | Shop pGMV 校准值，普通版 |
| `cali_direct_pgmv_7d_prom_v2` | Direct pGMV 校准值，大促修正 |
| `cali_shop_pgmv_7d_prom_v2` | Shop pGMV 校准值，大促修正 |

评估指标：XRMSE（交叉 RMSE）。

### 7.2 整体结构 / Overall Structure

```text
UniCR 原始 pGMV
├── SIR / ALL 粒度校准
│   ├── 普通版 SIR_normal
│   └── 大促修正版 SIR_prom
├── ItemCali / Item 粒度校准
└── 融合与条件门控
    ├── 满足条件：0.5 * ItemCali + 0.5 * SIR
    └── 不满足条件：fallback 到 SIR
```

核心模块：

| 模块 | 文件 | 核心作用 |
|---|---|---|
| SIR | `layers/sir_new_v2.py` | ALL 粒度分段线性校准 |
| ItemCali | `layers/item_cali.py` | 基于 item 历史 `GMV / pGMV` 比值校准 |
| 大促修正 | `layers/fix_ar_ratio_v2.py` | 通过 `prom_ratio` 修正大促点击归因 GMV 与到达 GMV 错位 |
| 融合门控 | `item_cali_main.py` | 判断是否启用 item 校准，输出普通版和大促版 |

### 7.3 SIR ALL 粒度校准 / SIR ALL-Level Calibration

SIR（Segmented Isotonic Regression）将 pGMV 值域分桶，在每个桶内用分段线性插值把模型预测值映射到实际观测值。

输入：

- `uncalib_score`：上游 UniCR pGMV 预测值。
- `cr_label`：每个合并桶的平均实际 GMV per click，即 `merge_bucket` output1。
- `bucket_mean_value`：每个合并桶的平均预测 pGMV per click，即 `merge_bucket` output2。

算法：

```text
给定桶边界 x_0, x_1, ..., x_n（pGMV 均值）
和对应值 y_0, y_1, ..., y_n（GMV 均值）

对于落在第 i 个桶的 x:
f(x) = k_i * (x - x_i) + y_i
k_i = (y_{i+1} - y_i) / (x_{i+1} - x_i)
```

1h / 24h 融合：

| 地区 | w_1h | w_24h | 原因 |
|---|---:|---:|---|
| MY, ID, VN, PH, BR | 0.9 | 0.1 | 数据量充足，1h 已够稳定 |
| SG, TH, TW | 0.8 | 0.2 | 数据量较小，需要更多 24h 稳定性 |

分桶策略：

- SG / TH：5 个桶，保证统计稳定性。
- 其他地区：10 个桶。
- 5 桶数据 pad 到 11 维，与 10 桶对齐。

`merge_bucket` 合桶约束：

- 每个桶有足够样本量，至少 `total_clk / bucket_number`。
- 每个桶 GMV 统计量足够大，至少 `17,500,000`。
- 桶间实际 GMV/click 严格单调递增。

### 7.4 ItemCali 粒度校准 / Item-Level Calibration

ItemCali 直接用单个 item 的历史统计做校准：

```text
scale = item_GMV_sum / item_pGMV_sum
calib_score = model_output * scale
```

解读：

- `scale > 1`：模型低估，校准后放大。
- `scale < 1`：模型高估，校准后缩小。
- `scale ~= 1`：预测接近真实。

时间窗口：

```text
final_score = 0.9 * (pGMV * scale_1d)
            + 0.1 * (pGMV * scale_3d)
```

安全机制：

- 小值保护：GMV 或 pGMV < `10,000` 时，scale 默认为 1。
- 订单数门控：`broad_order_cnt >= 15` 才可能启用 item 校准。
- 偏差门控：`scale_3d < 2/3` 或 `scale_3d > 2` 才启用；否则 fallback 到 SIR。

### 7.5 大促时间修正 / Promotion-Time Correction

SIR 分桶统计基于到达口径 GMV，而校准目标是点击归因口径 GMV。日常两者比值稳定，大促期间会显著偏离：

- 促前：用户加购、延迟购买，点击归因 GMV > 到达 GMV，`ratio > 1`。
- 促后：大促点击订单陆续回流，ratio 从峰值逐渐回落。

核心口径：

```text
prom_ratio = 点击归因口径 GMV / 到达口径 GMV
SIR_prom = SIR_normal * prom_ratio
```

`dt` 计算：

```text
各 region 大促实际开始时间 = start_time_base(slot 6200) + region_offset
dt = (cur_time(slot 8888) - 各 region 大促实际开始时间) // 3600
```

Region offset：

| Region | Offset |
|---|---:|
| MY, SG | +0h |
| TW, PH | +4h |
| TH, ID, VN | +5h |
| BR | +15h |

影响窗口：

- `dt ∈ [-120h, 0)`：促前 5 天，ratio 逐渐升高。
- `dt ∈ [0, +24h)`：促后 1 天，ratio 从峰值回落。
- `dt <= -120h` 或 `dt >= +24h`：ratio 强制为 1。

数据来源：

- `start_time_base`（slot 6200）与 `prom_scale`（slot 6201）由运营在每次大促前约 2 天通过 `sales_data_for_fes_new.sql` 写入 FSE。
- `cur_time`（slot 8888）由在线服务系统自动注入。
- `params.py` 中的参数通过 L-BFGS-B 在历史大促数据上离线拟合，按 `{REGION}_{ENTRANCE}_{PLACEMENT}` 组合存储。

### 7.6 融合、门控与限幅 / Fusion, Gating and Clipping

融合：

```text
fused_normal = 0.5 * ItemCali + 0.5 * SIR_normal
fused_prom   = 0.5 * ItemCali + 0.5 * SIR_prom
```

门控：

```text
if order_cnt >= 15 AND (scale_3d < 2/3 OR scale_3d > 2):
    output = fused
else:
    output = SIR
```

不存在“部分融合”的中间状态：要么使用融合结果，要么完全退回 SIR。

限幅：

```text
calib_score = clip(calib_score, ref / (1 + thre), ref * (1 + thre))
```

| 场景 | thre | 允许范围 |
|---|---:|---|
| SIR 大多数地区 | 0.35 | `[pGMV/1.35, pGMV*1.35]` |
| SIR TW 低桶（bucket < 3） | 0.5 | `[pGMV/1.5, pGMV*1.5]` |
| SIR TW 高桶 shop | 0.4 | `[pGMV/1.4, pGMV*1.4]` |
| SIR 大促版 TW / SG | 0.5 | `[pGMV/1.5, pGMV*1.5]` |
| Item + SIR 融合后 | 0.5 | `[pGMV/1.5, pGMV*1.5]` |

### 7.7 Cali Slot 与 FSE 表 / Cali Slots and FSE Tables

cali 详细 slot 明细已集中维护在 [product_ads_feature.md](product_ads_feature.md)，主文档保留分类入口：

| 类别 | Slot / 表 | 用途 |
|---|---|---|
| SIR 分桶统计 | `16501~16523`，FSE 表 `ads.cali_segment_data_v3` | direct/shop、1h/24h、10 桶/5 桶统计 |
| Item 粒度统计 | `6136~6182`，FSE 表 `ads.cali_item_data_v3_agg_rt` | item-level GMV/pGMV scale 与订单数门控 |
| Zero order 天数 | `6990`，FSE 表 `ads.zero_order_cnt_5d_v2` | 当前 factor=1.0，未实际生效 |
| 上下文与大促参数 | `46354`、`8888`、`1224`、`6200`、`6201` | region、请求时间、entrance、大促开始时间和强度 |

权重策略汇总：

| 模块 | 维度 | 地区 | 权重 |
|---|---|---|---|
| SIR | 1h vs 24h | MY, ID, VN, PH, BR | `[0.9, 0.1]` |
| SIR | 1h vs 24h | SG, TH, TW | `[0.8, 0.2]` |
| ItemCali | 1d vs 3d | 全部 | `[0.9, 0.1]` |
| SIR + ItemCali | Item vs SIR | 全部 | `[0.5, 0.5]` |

### 7.8 Cali 文件结构 / Cali File Structure

```text
paidads-alg/ego_models/model_modules/cali(online分支)
├── item_cali_main.py              # 主入口：特征读取、校准流程编排、输出
├── sales_data_for_fes_new.sql     # 大促参数写入 SQL
├── ego_learner/
│   └── ego-learner.yaml           # EGO 训练配置
├── layers/
│   ├── sir_new_v2.py              # SIR 分段线性插值校准
│   ├── item_cali.py               # Item 粒度 GMV/pGMV 比值校准
│   ├── fix_ar_ratio_v2.py         # 大促时间修正
│   ├── params.py                  # 大促拟合参数
│   └── info.py                    # 均值 AR ratio
└── merge_bucket.h                 # merge_bucket C++ 算子
```

## 8. 数据表与分析口径 / Data Tables and Analysis Definitions

### 8.1 业务分析入口表 / Business Analysis Entry Table

UniCR 做业务分析和校准分析时，关键入口表是：

```text
mkplpaidads_search_ads.item_basic_info_for_cali_and_case
```

表定位：点击归因明细表，包含预估值和真实值，可用于分析 UniCR pGMV 的业务规模、价值结构与校准偏差。

它主要回答三类问题：

1. 业务规模：广告点击后实际带来了多少 direct / shop GMV。
2. 价值结构：GMV 主要来自 direct 还是 shop，不同 `region / entrance / placement` 是否有明显差异。
3. 预测质量：UniCR pGMV 与真实 GMV 是否一致，偏差集中在哪些流量切片。

### 8.2 已确认字段口径 / Confirmed Field Definitions

当前已经确认 3 个预测值相关字段：

| 字段 | 当前理解 | 建议用途 |
|---|---|---|
| `direct_pgmv_7d_sum` | 原始预估值 | 看模型未经校准时的输出规模 |
| `cali_direct_pgmv_7d_sum` | 校准后预估值 | 看 cali 对原始分数的修正幅度 |
| `final_pgmv_sum` | 最终预估值 | 首轮业务分析默认使用 |

分析时建议拆两层：

1. 校准链路分析：`direct_pgmv_7d_sum -> cali_direct_pgmv_7d_sum`。
2. 最终效果分析：`final_pgmv_sum -> actual_gmv`。

不要在 schema 未确认前，把 `final_pgmv_sum` 强行等同于 `direct + shop` 的简单相加。

### 8.3 语义字段视图 / Semantic Field View

| 语义名 | 当前对应字段 | 含义 | 状态 |
|---|---|---|---|
| `raw_pred_pgmv` | `direct_pgmv_7d_sum` | 模型原始预估值 | 已确认 |
| `cali_pred_pgmv` | `cali_direct_pgmv_7d_sum` | 校准后预估值 | 已确认 |
| `final_pred_pgmv` | `final_pgmv_sum` | 最终预估值 | 已确认，首轮默认使用 |
| `pred_shop_pgmv_7d` | **【待确认】** | shop 7d pGMV 预测值 | 需 schema 补充 |
| `actual_direct_gmv_7d` | **【待确认】** | direct 7d 真实 GMV | 需 schema 补充 |
| `actual_shop_gmv_7d` | **【待确认】** | shop 7d 真实 GMV | 需 schema 补充 |
| `actual_total_gmv` | **【待确认】** | 最终对比用真实 GMV | 需 schema 补充 |
| `dt / region / entrance / placement` | **【待确认】** | 日期与核心切分维度 | 需 schema 补充 |
| `request_id / item_id / shop_id` | **【待确认】** | 请求、商品、店铺主键 | 需 schema 补充 |

### 8.4 核心指标 / Core Metrics

第一轮按“规模 -> 结构 -> 预测质量 -> 排序能力”顺序看。

规模类：

| 指标 | 计算方式 | 说明 |
|---|---|---|
| 点击量 | `count(*)` | 样本规模 |
| 去重请求数 | `count(distinct request_id)` | 请求覆盖规模 |
| 去重商品数 | `count(distinct item_id)` | 供给覆盖规模 |
| 去重店铺数 | `count(distinct shop_id)` | 商家覆盖规模 |
| 真实 GMV/click | `sum(actual_total_gmv) / count(*)` | 每次点击平均真实价值 |

预测质量：

```text
PCOC_final  = sum(final_pred_pgmv) / sum(actual_total_gmv)
PCOC_direct = sum(pred_direct_pgmv_7d) / sum(actual_direct_gmv_7d)
PCOC_shop   = sum(pred_shop_pgmv_7d) / sum(actual_shop_gmv_7d)
WMAPE       = sum(abs(final_pred_pgmv - actual_total_gmv)) / sum(actual_total_gmv)
```

校准链路诊断：

| 指标 | 计算方式 | 说明 |
|---|---|---|
| 原始预测总量 | `sum(raw_pred_pgmv)` | 校准前规模 |
| 校准后预测总量 | `sum(cali_pred_pgmv)` | cali 输出规模 |
| 校准提升倍数 | `sum(cali_pred_pgmv) / sum(raw_pred_pgmv)` | 整体抬高或压低幅度 |
| 单点击校准变化量 | `avg(cali_pred_pgmv - raw_pred_pgmv)` | 平均每次点击修正量 |
| 单点击校准变化率 | `avg((cali_pred_pgmv - raw_pred_pgmv) / nullif(raw_pred_pgmv, 0))` | 相对修正幅度 |

排序能力：

| 指标 | 计算方式 | 说明 |
|---|---|---|
| 分桶单调性 | 按 `final_pred_pgmv` 做 `ntile(10)`，看每桶预测均值与真实均值 | 判断高分样本是否更高价值 |
| Top bucket GMV capture | `top10% bucket actual_gmv / total actual_gmv` | 看高分流量承接多少真实 GMV |
| 分桶 PCOC | 每个分桶内 `sum(pred) / sum(actual)` | 定位分数段高估或低估 |

### 8.5 首轮分析路径 / First-Pass Analysis Path

1. 整体概览：输出点击量、真实 GMV、最终预测 pGMV、pGMV/click、`PCOC_final`、WMAPE。
2. direct / shop 拆分：在字段可用时输出 direct 与 shop 两路 GMV、pGMV、PCOC 和占比。
3. 校准链路诊断：看 `direct_pgmv_7d_sum` 到 `cali_direct_pgmv_7d_sum` 的整体变化和切片变化。
4. 核心维度下钻：优先按 `region`、`region × entrance`、`region × entrance × placement` 切。
5. 分桶分析：按 `final_pred_pgmv` 分 10 桶或 20 桶，看 GMV capture、单调性和桶内 PCOC。

### 8.6 SQL 统一口径 / SQL Standard Definitions

建议在 SQL 最外层先统一衍生字段，再做聚合：

```text
raw_pred_pgmv    = coalesce(direct_pgmv_7d_sum, 0)
cali_pred_pgmv   = coalesce(cali_direct_pgmv_7d_sum, 0)
final_pred_pgmv  = coalesce(final_pgmv_sum, 0)
actual_total_gmv = coalesce(actual_direct_gmv_7d, 0) + coalesce(actual_shop_gmv_7d, 0)
abs_err_total    = abs(final_pred_pgmv - actual_total_gmv)
```

聚合层：

```text
total_click                = count(*)
total_actual_gmv           = sum(actual_total_gmv)
total_final_pred_pgmv      = sum(final_pred_pgmv)
avg_actual_gmv_per_click   = sum(actual_total_gmv) / count(*)
avg_final_pgmv_per_click   = sum(final_pred_pgmv) / count(*)
pcoc_final                 = sum(final_pred_pgmv) / nullif(sum(actual_total_gmv), 0)
wmape_total                = sum(abs_err_total) / nullif(sum(actual_total_gmv), 0)
```

### 8.7 字段确认原则 / Field Confirmation Rules

后续拿到表结构后，优先确认：

1. `final_pgmv_sum` 是否仅是校准后 direct 的最终落地值，还是包含其他后处理逻辑。
2. 真实值是否拆成 direct / shop 两列，还是只有总 GMV。
3. 是否有 `region`、`entrance`、`placement`。
4. 是否有 `request_id`、`item_id`、`shop_id`。
5. 日期字段是 `grass_date`、`dt` 还是其他分区名。

如果 schema 不完整，最小可分析集至少要有日期、点击粒度主键、预测值和真实值。

## 9. 监控与排查 / Monitoring and Troubleshooting

### 9.1 监控入口 / Monitoring Entrypoints

| 类型 | 入口 |
|---|---|
| 特征空值率监控 | Grafana `featurelog_monitor_all` |
| 特征质量监控表 | `mkplpaidads_search_ads.slot_quality_stats_new` |
| UniCR / URanker 延时 | `uranker-uworker` dashboard，重点看 `Rank Latency`、`Rank Latency P99`、`EgoPredict Latency`、`FeatureProcess Latency` |
| PCOC 看板 | DataSuite dashboard `f1379dc0-6a0d-42d0-ba27-b3c3586f3b84` |

`slot_quality_stats_new` 关键字段：

| 字段 | 说明 |
|---|---|
| `slot_id` | Slot 标识 |
| `entrance` | 流量入口 |
| `total_cnt` | 总样本数 |
| `null_cnt` / `zero_cnt` / `empty_cnt` | NULL、全零、空数组数量 |
| `avg_len` | 平均数组长度 |
| `null_rate` / `zero_rate` / `empty_rate` | NULL、全零、空数组占比 |
| `biz` / `region` / `dt` | 分区维度 |

### 9.2 排查顺序 / Troubleshooting Order

发现 UniCR / pGMV 异常时，按下面顺序收敛问题：

1. 先看规模：点击量、请求数、item 数、shop 数、direct / shop / total GMV、pGMV/click。
2. 再看结构：direct 与 shop GMV 占比、预测结构与真实结构、`region / entrance / placement` 差异。
3. 再看预测质量：`PCOC_final`、`PCOC_direct`、`PCOC_shop`、总偏差、WMAPE。
4. 再看排序能力：分桶单调性、分桶 PCOC、Top bucket GMV capture。
5. 最后定位链路：标签回流、特征覆盖、校准修正、线上输出映射、direct / shop 单路异常。

### 9.3 常见问题定位 / Common Root-Cause Directions

| 现象 | 优先排查 |
|---|---|
| PCOC 突然偏高或偏低 | Label 回流、点击归因窗口、真实 GMV 口径、cali 分桶统计 |
| 某 region 异常 | region-specific model / cali 权重、5 桶 / 10 桶策略、大促 offset、FSE region slot |
| Search 与非 Search 差异大 | OrgPredict 仅 Search 有效、domain mapping、入口特征覆盖 |
| pGMV 分桶不单调 | 模型排序能力、SIR 合桶、样本量不足、特征漂移 |
| cali 修正幅度异常 | SIR 1h/24h 融合、ItemCali order gate、`scale_3d`、大促 `prom_ratio`、限幅阈值 |
| 线上延时上涨 | EGO Predict、FeatureProcess、Rank latency、特征请求链路 |

## 10. 已知问题与待补充 / Known Issues and Open Items

### 10.1 已知约束 / Known Constraints

- OrgPredict 特征仅在 Search 入口（entrance=1）有效，其余入口被 mask 为 0。
- Order2Pay / ACT 塔的输入 `fc_input` 使用 `stop_gradient`，不反传梯度到主干；Delay Feedback 相关 head 仍会作用到共享参数。
- Seed 与 Increment 不只是训练数据时间窗不同：Increment 在 MMOE-STAR 骨干输入处对 `fc_input` 施加 `tf.stop_gradient`，仅更新 Tower 参数；Seed 不加该限制。
- Seed 中额外保留的 `pcr_0`、`uplift_ratio_1~6` 属于历史 Uplift 残留，Uplift 已从 UniCR 主模型独立出去。
- BR 暂未纳入本文源码级结构对比。
- `mkplpaidads_search_ads.item_basic_info_for_cali_and_case` 字段级 schema 仍需补齐。

### 10.2 待补充项 / Open Items

- **【待确认】** ScoringX / EGO Serving / 样本生产相关 SDU 路径。
- **【待确认】** 模型 serving、cali、特征开关相关 ConfigCenter namespace。
- **【待确认】** 样本回流、rank dump、label backflow 相关 Kafka topic。
- **【待确认】** `item_basic_info_for_cali_and_case` 的完整字段 schema 和 SQL 模板。
- **【待确认】** BR UniCR 与 cali 的源码级结构差异。
- **【待确认】** Research 待验假设列表，目前原文为空，需要 owner 后续补充。
