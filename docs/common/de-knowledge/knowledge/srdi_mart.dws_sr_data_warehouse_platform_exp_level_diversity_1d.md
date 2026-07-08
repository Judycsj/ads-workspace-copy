<!-- ads-workspace-gdoc-sync: gdoc_id=1GxTX2ahd7w5XhiOCd6KtYf7HchllEU1Vn9b3lqK-kiQ gdoc_url=https://docs.google.com/document/d/1GxTX2ahd7w5XhiOCd6KtYf7HchllEU1Vn9b3lqK-kiQ/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_diversity_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `scene_type` + `card_type` + `exp_group_id` + `buyer_type`
**分区：** `grass_region`（站点区域），`local_date`（业务日期）
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 1558

---

## 业务描述

本表为搜推平台（Search & Recommendation）**实验组级别**的**内容多样性（Diversity）**汇总宽表，以实验分组（`exp_group_id`）× 场景（`scene_type`）× 卡片类型（`card_type`）为粒度，统计各实验组在不同场景下的曝光、点击、下单的量级指标及 LLM 品类多样性指标。

**核心业务场景：**

- A/B 实验效果评估：对比不同实验组在各流量场景（搜索、首页发现、推荐等）下的用户行为及内容多样性差异。
- 内容多样性分析：通过 LLM 品类覆盖数量（`*_llm_cat_cnt`）衡量用户所见/交互/转化内容的品类丰富度。
- 平台级与场景级指标拆分：支持 Platform（全平台汇总）、S&R、RCMD、DD、Search、YMAL、PP 及 PP 细分场景的多维分析。

**适合回答的问题：**

- 某实验组（`exp_group_id`）在 Search 场景下，相比对照组是否提升了用户点击的品类多样性？
- 各实验组在平台级（Platform）和推荐场景（RCMD）中，曝光 UU 数和转化量各是多少？
- 不同卡片类型（Organic Item / Item / Video）在 Daily Discover 场景下的 LLM 品类覆盖趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 `SG`、`MY` 等，所有查询必须指定此分区字段 |
| `local_date` | date | 业务日期（本地时间），所有查询必须指定此分区字段 |

### 维度：实验与场景分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，标识用户所属实验桶 |
| `scene_type` | string | 流量场景类型。原子场景：`Search`、`DD`（Daily Discover）、`YMAL`（You May Also Like）、`PP`（Post Purchase）及 `PP - *` 细分场景；聚合场景：`Platform`（全平台）、`S&R`（搜索+推荐）、`RCMD`（推荐汇总，含 DD/PP/YMAL） |
| `card_type` | string | 卡片类型聚合维度。取值：`Aggregated Organic Item`（去广告商品）、`Aggregated Item`（全量商品）、`Aggregated Video`（视频，仅限 DD/PP 场景）、`Aggregated Item + Video`（商品+视频，仅限 DD/PP 场景） |
| `buyer_type` | string | 买家类型，当前版本固定为 `__ALL__`（不做买家类型拆分） |

### 指标：曝光、点击、下单量级

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数总和（`omni_scenario_imp_cnt` 汇总） |
| `click_cnt` | bigint | 点击次数总和（`omni_scenario_click_cnt` 汇总） |
| `order_cnt` | double | 下单数总和；因 source1/source2 多归因路径可能导致聚合 `scene_type` 或 `card_type` 下重复计数，已知问题，与 BI 口径对齐 |

### 指标：去重用户数（UU）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 有曝光行为的实验用户数（`omni_scenario_imp_cnt > 0` 的记录数汇总至实验组级别） |
| `click_uu` | bigint | 有点击行为的实验用户数 |
| `order_uu` | bigint | 有下单行为的实验用户数 |

### 指标：BE 品类多样性（预留，当前为空）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_be_cat_cnt` | bigint | 曝光 BE 品类数，当前版本固定写入 `null`，预留字段 |
| `click_be_cat_cnt` | bigint | 点击 BE 品类数，当前版本固定写入 `null`，预留字段 |
| `order_be_cat_cnt` | bigint | 下单 BE 品类数，当前版本固定写入 `null`，预留字段 |

### 指标：传统品类多样性（预留，当前为空）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cat_count` | bigint | 曝光品类数，当前版本固定写入 `null`，预留字段 |
| `click_cat_count` | bigint | 点击品类数，当前版本固定写入 `null`，预留字段 |
| `order_cat_count` | bigint | 下单品类数，当前版本固定写入 `null`，预留字段 |

### 指标：LLM 品类多样性

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_llm_cat_cnt` | bigint | 实验组内所有用户曝光 LLM 品类数之和（每用户的 `COUNT(DISTINCT item_llm_cluster_id WHERE imp > 0)` 累加），衡量曝光内容的品类丰富度 |
| `click_llm_cat_cnt` | bigint | 实验组内所有用户点击 LLM 品类数之和，衡量点击内容的品类丰富度 |
| `order_llm_cat_cnt` | bigint | 实验组内所有用户下单 LLM 品类数之和，衡量转化内容的品类丰富度 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须显式指定，该字段为分区键，不过滤将导致全分区扫描。
- **`local_date`**：必须显式指定，例如 `local_date = '2024-01-01'`，不过滤将导致全量历史分区扫描。
- **`scene_type`**：注意聚合场景（`Platform`、`S&R`、`RCMD`）与原子场景（`DD`、`Search` 等）之间存在业务包含关系，跨场景汇总前需确认分析口径，避免重复统计。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_llm_cat_cnt`、`click_llm_cat_cnt`、`order_llm_cat_cnt` | 为各用户 per-UU 去重品类数的累加值（先 `COUNT(DISTINCT)` 再 `SUM`），跨维度再次 SUM 无法保证去重语义，不代表整体唯一品类数 |
| `imp_uu`、`click_uu`、`order_uu` | 为预聚合 UU 计数，跨 `exp_group_id` 或 `scene_type` 叠加会导致重复计数 |
| `order_cnt` | 类型为 `double`，且在聚合场景（`Platform`、`S&R`、`RCMD`）下因多归因路径（source1、source2）可能存在重复计数，跨场景叠加需谨慎 |
| `imp_be_cat_cnt`、`click_be_cat_cnt`、`order_be_cat_cnt`、`imp_cat_count`、`click_cat_count`、`order_cat_count` | 当前均为 `null`，不可参与计算 |

### 时效性说明

- 本表为 `_1d` 日粒度表，每日 T+1 产出，反映前一自然日的完整数据。
- 不包含实时或小时级别数据。

### 场景包含关系说明

| 聚合场景 | 包含的原子场景 |
|---|---|
| `Platform` | 全部场景（不含 `PP - *` 细分），不含 Video/Item+Video card_type |
| `S&R` | `DD`、`PP`、`Search`、`YMAL`，不含 Video/Item+Video card_type |
| `RCMD` | `DD`、`PP`、`YMAL`，不含 Video/Item+Video card_type |

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户实验分组信息（`exp_group_id`），过滤特定 `scene_id` 下的有效分配用户 |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 获取用户-商品行为明细，包括曝光、点击、下单次数，卡片类型，场景标签，以及 LLM 品类 ID（`item_llm_cluster_id`） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group   ──┐
                                             ├──► user_cluster_exp（用户×品类×实验组关联）
dwm_sr_data_warehouse_platform_user_item  ──┤
  → user_item_raw（行为明细 + 场景/卡片分类）  │
  → user_item_sub_scene（PP 细分场景展开）     │
  → user_item_union（原始 + 归因扩展 UNION）   │
  → user_cluster_agg（按卡片类型聚合 LLM 品类）┘
       → cubed_data（多场景 UNION 展开）
           → INSERT OVERWRITE 目标表
```

### 关键步骤

**Step 1 — `user_exp`（临时视图）**
从实验分组表按 `grass_region`、`local_date`、`scene_id`（142/132/368/373/1605/1718/2065）过滤，获取有效的用户实验分组映射 `(user_id, exp_group_id)`。

**Step 2 — `user_item_raw`（临时视图）**
从用户-商品行为宽表读取 `omni_impression`、`omni_click`、`order` 三类事件，提取卡片类型（`target_type`，从 `feature_detail` 解析）、主场景及 source1/source2 归因场景（`scene_type`），只保留 `target_type` 为 `item`、`item_mix_feed_card`、`video` 的记录。

**Step 3 — `user_item_sub_scene`（临时视图）**
针对 PP 场景（Post Purchase）进一步细分为 8 个子场景（如 `PP - Cart Recommendation`、`PP - SIP YMAL` 等），通过 `scenario_tags` 标签匹配实现。同时利用 source1/source2 归因路径补充订单归因记录（曝光/点击补 0）。

**Step 4 — `user_item_union`（临时视图）**
将 PP 细分场景数据与原始行为数据合并（UNION ALL），并追加 source1、source2 归因场景的订单记录（去重避免与主场景重复，通过 `concat_ws` 场景+卡片类型去重判断）。

**Step 5 — `user_cluster_agg`（临时视图）**
按四种 `card_type` 维度展开（UNION ALL）：
- `Aggregated Organic Item`：非广告商品（`is_ads != 'true'`，`target_type in ('item', 'item_mix_feed_card')`）
- `Aggregated Item`：全量商品
- `Aggregated Video`：视频卡片（仅 DD/PP 场景）
- `Aggregated Item + Video`：商品+视频混合（视频品类 ID 加 `v#` 前缀，仅 DD/PP 场景）

每类在 `(user_id, item_llm_cluster_id, scene_type)` 粒度聚合曝光/点击/下单。

**Step 6 — `user_cluster_exp`（临时视图）**
将 `user_cluster_agg` 与 `user_exp` 做 INNER JOIN，关联实验分组，形成 `(user_id, exp_group_id, card_type, scene_type, item_llm_cluster_id, 行为指标)` 粒度数据。

**Step 7 — `cubed_data`（临时视图）**
通过四段 UNION ALL 构造多场景视图：
- 聚合为 `Platform`（排除 PP 细分和 Video 类 card_type）
- 聚合为 `S&R`（DD/PP/Search/YMAL，排除 Video 类 card_type）
- 保留原子场景（DD、PP、PP 细分、YMAL）
- 聚合为 `RCMD`（DD/PP/YMAL，排除 Video 类 card_type）

每段在 `(user_id, exp_group_id, card_type, scene_type)` 粒度计算 LLM 品类去重数（per-UU）及行为量级。

**Step 8 — INSERT OVERWRITE（写目标表）**
对 `cubed_data` 按 `(scene_type, card_type, exp_group_id)` 做最终聚合，输出实验组级别指标：
- `buyer_type` 固定写 `'__ALL__'`
- `imp_cat_count`、`click_cat_count`、`order_cat_count`、`*_be_cat_*` 均写 `null`（预留字段）
- `*_llm_cat_cnt` 为各用户 per-UU 去重品类数的 SUM
- `*_uu` 为对应行为 `> 0` 的记录计数

### 注意事项

1. **`order_cnt` 重复计数风险**：当一笔订单的 `original`、`source1`、`source2` 三条归因路径对应不同 `scene_type` 或 `card_type`，但均归属同一聚合 `scene_type`（如 `Platform`）或聚合 `card_type` 时，该订单会被多次计入 `order_cnt`。此为已知问题，与 BI 口径保持一致，不予修正。
2. **`*_llm_cat_cnt` 语义**：该指标是"各用户品类去重数"的累加（先 per-UU `COUNT(DISTINCT)`，再跨用户 `SUM`），不等于整个实验组内的唯一品类总数，使用时需注意分母应为 `imp_uu`/`click_uu`/`order_uu` 而非直接比较绝对值。
3. **`null` 字段**：`imp_cat_count`、`click_cat_count`、`order_cat_count`、`imp_be_cat_cnt`、`click_be_cat_cnt`、`order_be_cat_cnt` 均为预留字段，当前 ETL 固定写入 `null`，下游不可直接使用。
4. **单 writer**：本表由单一 ETL 文件写入，不存在多 writer 并发写入问题。
5. **场景 ID 覆盖范围**：实验用户仅来源于 `scene_id in (142, 373, 132, 368, 1718, 1605, 2065)`，对应 Daily Discover、Global/Image Search、Product Detail Page、Cart 等主要场景，其他场景的用户不纳入本表统计。

---

*文档生成时间：2026-05-17*