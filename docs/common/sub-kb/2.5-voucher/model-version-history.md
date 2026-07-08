---
id: ads_roi3_uplift_model_version_history
title: Uplift 模型版本迭代历史
domain: voucher-model
owner: jingyi.wei
last_updated: 2026-06-05
confidence: high
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1sap-h_7Q-e9Hw8ao_5B6yr_63w7gxptMEQ9dF0qEWmY gdoc_url=https://docs.google.com/document/d/1sap-h_7Q-e9Hw8ao_5B6yr_63w7gxptMEQ9dF0qEWmY/edit -->


# Uplift 模型版本迭代历史

> 效果数据均为 ID 区域。按推全时间排序，只记录打出显著收益的大版本。

## 版本记录

| # | 推全时间 | 主要改动 | 线上收益（ID） |
|---|---------|---------|--------------|
| 1 | 2026-01 | CR uplift 模型与 PGMV 模型解耦 + pcr0 pCoC 优化 + TARNet 网络建模 + 筛选 30+ 核心贡献特征 | platform_gmv **+1.19%** |
| 2 | 2026-03 | 非 RCT 样本引入模型 / DragonNet 建模 + 商家平台券特征 | platform_gmv **+0.69%** |
| 3 | 2026-04 | 发券样本 order 窗口切换为 1h | platform_gmv **+0.24%** |
| 4 | 2026-04 | Uplift 模型升级单调性结构（Isotonic Regularization） | platform_gmv **+1.33%** |
| 5 | 2026-06（预期） | 引入券敏感度特征、场景建模、LLM 生产的 query/item 文本 Embedding 特征 | — |

## 版本详情

### 版本 1（2026-01）：模型解耦 + TARNet

**根因**：uplift 耦合在 PGMV 模型中时，PGMV 多次迭代训练会导致 pcr0 pCoC 系统性波动，干扰 uplift 实验效果判断，且耦合结构难以独立迭代。解耦后 uplift 模型独立训练和 serving，pCoC 稳定性大幅提升。

- CR uplift 模型从 PGMV 模型中独立，独立训练和 serving。
- 引入 TARNet 网络结构进行因果 uplift 建模（Control/Treatment 分塔，无 propensity head）。
- 对 pcr0 pCoC 进行系统性优化。
- 从全量候选特征中筛选 30+ 核心贡献 sparse 特征，减少噪声。

### 版本 2（2026-03）：DragonNet + 非 RCT 样本

**根因**：RCT 样本仅占全量点击样本的约 20%，样本量严重不足导致模型训练不充分，尤其高折扣档位曝光少、RCT 覆盖更稀疏。引入非 RCT 样本大幅扩充训练集，DragonNet 的 propensity head + IPW 修正非 RCT 样本的选择偏差，使样本扩充在无偏性约束下可行。

- **非 RCT 样本引入训练**：策略发券样本（非随机）存在选择偏差，此前只用 RCT 样本训练。
- **DragonNet 替换 TARNet**，引入三项改进：
  - a. Propensity Head 建模发券机制 + IPW 加权，缓解非随机发券样本的选择偏差。
  - b. Targeted Regularization（TMLE 正则），增加双重鲁棒性——propensity 或 outcome 模型任一正确时估计仍渐进无偏。
  - c. 将二分类 DragonNet（Treatment 为 0/1 是否发券）升级为**多分类**（Treatment 为不同折扣档位，对应 6 档券面额）。
- 同步引入商家平台券（SV）相关特征。

### 版本 3（2026-04）：1h Label 窗口

**根因**：广告券有效期仅 1 小时，但此前训练 label 为 `direct_order_1d`（1 天），归因窗口远大于券有效期，导致大量非券驱动的自然转化被计入 label，uplift 信号被噪声稀释。切换为 `direct_order_1h` 使 label 窗口与券激励周期严格对齐。

- 发券样本训练 label 从 `direct_order_1d` 切换为 **`direct_order_1h`**，与广告券有效期对齐。
- 减少 label 窗口内的自然转化噪声，提升 uplift 信号纯净度。

### 版本 4（2026-04）：Isotonic Regularization 单调性升级

**根因**：高折扣档（15%/20%）发券量少，各折扣 head 依赖各自稀疏梯度独立迭代，导致相邻折扣档位之间预估值不保序（高折扣 ratio 有时低于低折扣 ratio）。Isotonic 约束通过 `softplus(delta)` 让相邻档位梯度在一定程度上共享，同时修正了不保序导致的系统性高折扣低估问题，因此是四个版本中收益最大的。

- 升级折扣档位单调性约束机制：
  - **训练时**：通过 `softplus(delta)` 约束相邻档位预估值单调递增（Tower 内）。
  - **Serving 时**：保留在线保序 clip（`ratio1 ≤ ... ≤ ratio6`）兜底跨 Tower 单调性。
- 解决折扣档位不保序问题，同时通过梯度共享改善高折扣档位预估准确性。

### 版本 5（2026-06，预期）：新特征接入

- **券敏感度特征**：User voucher portrait（核销行为 1.x + 敏感度 2.x + 广告券 display/redeem）。
- **场景建模**：引入场景相关特征，增强模型对不同入口/场景的区分能力。
- **LLM 文本 Embedding 特征**：query embedding（slot_31889）+ item 文本 embedding（slot_11），LLM 生产。离线消融（KA5，2026-05-29，ID）：全档 AUUC 均值 +0.019、Uplift PCOC error -0.060，两项主指标达标；ID 小流量（2026-06-02 启动）2d readout：bad_query_rate +0.044%（Guardrail PASS），platform rev +1.48%，advv +2.47%。
