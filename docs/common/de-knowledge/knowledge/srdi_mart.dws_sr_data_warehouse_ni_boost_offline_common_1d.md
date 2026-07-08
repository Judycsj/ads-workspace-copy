<!-- ads-workspace-gdoc-sync: gdoc_id=1lPOHxrE7j8bLgl9uLI7GoPsWKrKN428k9gKL2hhws20 gdoc_url=https://docs.google.com/document/d/1lPOHxrE7j8bLgl9uLI7GoPsWKrKN428k9gKL2hhws20/edit -->

# srdi_mart.dws_sr_data_warehouse_ni_boost_offline_common_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `regional_date` + `exp_tag` + `item_id`
**分区：** `grass_region`（大区）, `regional_date`（本地日期）
**更新频率：** 每日离线调度（T+1）
**访问频次：** 206 次

---

## 业务描述

本表汇总各大区、各日期下，推荐场景（Organic）中商品维度的曝光、点击、下单数据，并按实验分组标签（`exp_tag`）进行区分，用于离线评估 NI Boost 策略在不同实验组之间的效果差异。

**核心业务场景：**
- 评估 NI Boost 离线实验效果（T1 实验组 vs C1 对照组 vs OTHER）；
- 分析推荐场景（You May Also Like、Daily Discover、Post Purchase）下商品的曝光→点击→转化漏斗；
- 与实时指标进行对齐比对，辅助策略迭代决策。

**适合回答的问题：**
- 某大区某天，实验组与对照组商品的点击率（CTR）和订单转化率分别是多少？
- 特定商品在不同实验分组中的曝光量、点击量、成单量如何？
- 各推荐场景合并后，某实验分组的整体 GMV 趋势如何？

> **注意：** 表仅包含 Organic（非广告）流量，且限定推荐场景下的特定卡片类型，不代表全站数据。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识，如 ID、VN、PH、TH、MY 等 |
| `regional_date` | date | 本地日期（业务日期，已处理时区），对应数据统计日 |

### 维度：商品与实验分组

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，仅包含 `item_id > 0` 的有效商品 |
| `exp_tag` | string | 实验分组标签。各大区 NI Boost 实验组标记为 `T1`（按大区对应不同 exp_group_id 判定）；通用对照组（exp_group_id=378802）标记为 `C1`；其余流量标记为 `OTHER` |

### 指标：曝光、点击与订单

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_cnt` | bigint | 商品曝光次数（operation = 'impression' 的聚合计数） |
| `click_cnt` | bigint | 商品点击次数（operation = 'click' 的聚合计数） |
| `order_cnt` | double | 商品成单次数（operation = 'order' 的聚合计数，来源上报数据，类型为 double） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤**：查询时**必须同时指定** `grass_region` 和 `regional_date`，否则将触发全分区扫描，影响性能和成本：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2025-01-01'
  ```
- 若需多大区对比，建议使用 `grass_region IN ('ID', 'VN', 'PH')` 而非不加过滤。

### 不可直接 SUM 的字段

| 字段 | 风险说明 |
|------|----------|
| `order_cnt` | 类型为 double，跨分区聚合时可能存在浮点精度损失，建议使用 `ROUND` 或 `CAST` 后再汇总 |
| CTR / CVR（派生） | 本表不存储比率字段，若需计算点击率（`click_cnt / imp_cnt`）或转化率（`order_cnt / click_cnt`），**不可先 SUM 比率再平均**，须先汇总分子分母再做除法 |

### 时效性说明

- 本表为 **离线日粒度表（`_1d`）**，T+1 产出，当天数据需次日方可使用。
- `regional_date` 已按各大区本地时区处理，与实时数据对齐，可直接与实时结果进行横向比对。
- 表中 `exp_tag` 的实验分组 ID 硬编码于 ETL，若实验扩量/新增大区，需同步更新 ETL 逻辑，历史数据不会自动回刷。

### 数据口径说明

- **仅包含 Organic 流量**：已过滤广告（`is_ads = false or is_ads is null`）。
- **仅包含推荐场景**：涵盖 You May Also Like、Daily Discover、Post Purchase 三个场景。
- **卡片类型限定**：`target_type = 'item'`，或首页 Daily Discover 下的 `item_feed_card`、`item_mix_feed_card`、`repurchase_mix_feed_card`。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供商品维度的曝光、点击、下单行为明细数据，按大区、本地日期、操作类型过滤后聚合 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
        │  过滤：Organic 流量 + 推荐场景 + 指定卡片类型
        │  按 (item_id, exp_group_ids) 聚合 imp/click/order
        ▼
Temporary View: imp_click_${grass_region_without_quote}
        │  exp_group_ids → exp_tag (T1/C1/OTHER) 映射
        │  按 (exp_tag, item_id) 二次聚合
        ▼
srdi_mart.dws_sr_data_warehouse_ni_boost_offline_common_1d
   PARTITION (grass_region, regional_date)
```

### 关键步骤

**Step 1 — 创建中间 Temporary View**

从 `dwd_sr_data_warehouse_platform` 读取指定大区、指定日期的行为明细，过滤条件包括：
- 仅保留 Organic 流量（非广告）；
- 仅保留三个推荐场景（You May Also Like / Daily Discover / Post Purchase）；
- 仅保留指定卡片类型；
- `item_id > 0`。

按 `(item_id, exp_group_ids)` 分组，通过条件聚合分别累加曝光（`imp_cnt`）、点击（`click_cnt`）、下单（`order_cnt`）计数。同时利用 `CASE WHEN array_contains(exp_group_ids, <id>)` 逻辑，根据大区与实验组 ID 的映射关系生成 `exp_tag`（T1 / C1 / OTHER）。

**Step 2 — INSERT OVERWRITE 写目标表**

从 Temporary View 中按 `(exp_tag, item_id)` 二次聚合（合并同一商品在不同 exp_group_ids 下但 exp_tag 相同的行），以 `INSERT OVERWRITE ... PARTITION (grass_region, regional_date)` 方式写入目标表，确保幂等性。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件，无多 Writer 并发写入风险。
- **分区覆写**：采用 `INSERT OVERWRITE PARTITION` 写入，每次调度会覆盖对应大区+日期分区，支持幂等重跑。
- **实验 ID 硬编码**：各大区对应的 NI Boost 实验 exp_group_id 硬编码在 ETL SQL 中（如 ID:627728、VN:640343、PH:655654、TH:655641、MY:662593；对照组:378802），实验变更时需同步更新 ETL 并评估是否需要历史数据回刷。
- **参数化大区**：ETL 通过 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}` 等参数按大区分别调度，Temporary View 名称含大区后缀以避免并发冲突。

---

*文档生成时间：2026-05-17*