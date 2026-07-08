<!-- ads-workspace-gdoc-sync: gdoc_id=1xLbmvTb84LvpTGqhgQqF-8YLKrjC7jIn7Sx50C5mv3I gdoc_url=https://docs.google.com/document/d/1xLbmvTb84LvpTGqhgQqF-8YLKrjC7jIn7Sx50C5mv3I/edit -->

# srdi_mart.dws_sr_data_warehouse_hashtag_replace_analysis_nd

**分层：** DWS（数据汇总层）
**主键：** `exp_tag` + `target_item_id` + `hashtag_id` + `version_date`（分区内唯一）
**分区：** `grass_region`（区域）/ `local_date`（业务日期）
**更新频率：** 每日（T+1，按分区增量覆写）
**访问频次：** 42 次

---

## 业务描述

本表用于追踪和分析**话题标签（Hashtag）替换实验**在近 N 天（nd）维度上的效果数据，是搜推数仓话题标签替换专项分析的核心汇总表。

**核心业务场景：**

- 在搜推场景下，针对某个目标商品（`target_item_id`）开展话题标签替换实验，将原始话题标签替换为候选话题标签，通过对照组（Control）、探索组（Explore）、偏好组（Prefer）以及实验组（Exp）等分桶策略，评估替换后的曝光、点击、成单表现。
- 表中记录了每个实验的起止探索时间，可用于判断替换实验的探索阶段是否已经启动或结束。
- 每日滚动更新，通过与前一日分析结果进行 full outer join 合并当日最新状态，实现累计指标的滚动维护。

**适合回答的问题：**

- 某个话题标签替换实验在当前日期，各分桶的曝光量、点击量、成单量分别是多少？
- 某个实验的探索阶段从哪一天开始？是否已完成探索（`finish_explore_date` 是否有值）？
- 对照组与实验各分组的效果对比如何（CTR、CVR 趋势分析）？
- 某区域（`grass_region`）下话题标签替换实验的整体推进情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 区域标识（如市场/国家），用于分区隔离，查询时必须指定 |
| `local_date` | date | 业务日期，每日更新，查询时必须指定，代表当前分区的数据快照日期 |

---

### 维度：实验标识与配置信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_tag` | string | 实验标识标签，用于区分不同话题标签替换实验，与 `target_item_id`、`hashtag_id`、`version_date` 共同构成实验唯一键 |
| `target_item_id` | bigint | 目标商品 ID，即参与话题标签替换实验的商品 |
| `hashtag_id` | string | 话题标签 ID，即被替换或候选的话题标签 |
| `version_date` | string | 实验版本日期，标识实验配置的版本，用于区分同一商品/标签的不同批次实验 |
| `start_explore_date` | date | 探索阶段开始日期；当实验首次产生探索曝光（`explore_imp_cnt_nd > 0`）时记录当日日期，后续保留最早值 |
| `finish_explore_date` | date | 探索阶段完成日期；当探索曝光量超过 300 时（`explore_imp_cnt_nd > 300`）记录当日日期，后续保留最早值 |

---

### 指标：实验总体曝光、点击与成单（Exp 组）

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_imp_cnt_nd` | bigint | 实验组（Exp）近 N 天累计曝光次数 |
| `exp_click_cnt_nd` | bigint | 实验组（Exp）近 N 天累计点击次数 |
| `exp_order_cnt_nd` | double | 实验组（Exp）近 N 天累计成单数 |

---

### 指标：探索分桶（Explore 组）曝光、点击与成单

| 字段 | 类型 | 说明 |
|------|------|------|
| `explore_imp_cnt_nd` | bigint | 探索组（Explore）近 N 天累计曝光次数；同时用于判断探索阶段的起止条件 |
| `explore_click_cnt_nd` | bigint | 探索组（Explore）近 N 天累计点击次数 |
| `explore_order_cnt_nd` | double | 探索组（Explore）近 N 天累计成单数 |

---

### 指标：偏好分桶（Prefer 组）曝光、点击与成单

| 字段 | 类型 | 说明 |
|------|------|------|
| `prefer_imp_cnt_nd` | bigint | 偏好组（Prefer）近 N 天累计曝光次数 |
| `prefer_click_cnt_nd` | bigint | 偏好组（Prefer）近 N 天累计点击次数 |
| `prefer_order_cnt_nd` | double | 偏好组（Prefer）近 N 天累计成单数 |

---

### 指标：对照分桶（Control 组）曝光、点击与成单

| 字段 | 类型 | 说明 |
|------|------|------|
| `control_imp_cnt_nd` | bigint | 对照组（Control）近 N 天累计曝光次数 |
| `control_click_cnt_nd` | bigint | 对照组（Control）近 N 天累计点击次数 |
| `control_order_cnt_nd` | double | 对照组（Control）近 N 天累计成单数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 均为分区字段，查询时**必须同时指定**，否则将触发全表扫描，影响性能并可能造成资源浪费：
  ```sql
  WHERE grass_region = 'XX'
    AND local_date = '2026-05-20'
  ```
- 若需查询某区域最新数据，可使用 `local_date = current_date() - 1`，注意数据在 T+1 日更新。

### 不可直接 SUM 的字段

- **`*_order_cnt_nd`**（类型为 `double`）：成单数字段为浮点型，直接 SUM 跨实验时需注意语义是否合理；不同实验的统计口径可能存在加权或去重，需结合业务确认是否可加和。
- **CTR / CVR 等比率指标**：本表未存储点击率、转化率等比率字段，如需计算请用 `click_cnt / imp_cnt`，**不可对该比率进行 SUM**。
- **`start_explore_date` / `finish_explore_date`**：为状态型日期字段，不可聚合求和，仅用于筛选和判断探索阶段状态。

### 时效性说明

- 表名后缀 `_nd` 表示**近 N 天滚动累计**指标，每日通过合并前一日分区数据和当日维度表状态进行滚动更新，并非单日增量。
- 每日 ETL 以 `INSERT OVERWRITE` 方式写入当日分区，当日分区数据在 ETL 完成后方可查询，通常为 **T+1** 可用。
- `local_date` 分区代表的是数据合并后的快照日期，而非原始事件发生日期。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dws_sr_data_warehouse_hashtag_replace_analysis_nd` | 自引用：读取前一日（`local_date - 1`）的分析结果，作为历史累计基准，通过滚动合并维护近 N 天指标的连续性 |
| `srdi_mart.dim_sr_data_warehouse_hashtag_replace_status_df` | 维度状态表：提供当日（`local_date`）的话题标签替换实验最新状态及各分桶指标快照，作为当日增量数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
前一日分区（自引用 T-1）
        │
        ▼
last_analysis_view ──┐
                      ├─ FULL OUTER JOIN（on exp_tag + target_item_id + hashtag_id + version_date）
today_status_view ───┘
        │
        ▼
INSERT OVERWRITE → dws_sr_data_warehouse_hashtag_replace_analysis_nd（当日分区）
```

整体逻辑为：将当日维度状态表中的最新指标与前一日累计分析结果进行 full outer join，优先采用当日数据（`COALESCE(b, a)`），并根据业务规则推算探索起止日期，最终写入当日分区。

### 关键步骤

1. **Statement 1 — 创建历史临时视图 `last_analysis_${grass_region_without_quote}`**
   - 从目标表自身读取前一日（`local_date - 1`）、指定区域的分析结果，作为历史累计基准。

2. **Statement 2 — 创建当日状态临时视图 `today_status_${grass_region_without_quote}`**
   - 从维度状态表 `dim_sr_data_warehouse_hashtag_replace_status_df` 读取当日指定区域的最新实验状态及各分桶指标。

3. **Statement 3 — 合并写入目标表**
   - 以 `exp_tag`、`target_item_id`、`hashtag_id`、`version_date` 为连接键，对历史视图（`a`）与当日状态视图（`b`）进行 **FULL OUTER JOIN**。
   - 维度字段（`exp_tag`、`target_item_id`、`hashtag_id`、`version_date`）使用 `COALESCE(a, b)` 保留非空值。
   - 各分桶指标字段（曝光、点击、成单）使用 `COALESCE(b, a)` 优先采用当日最新数据，当日无数据时保留历史值。
   - **探索起止日期**采用状态驱动逻辑：
     - `start_explore_date`：历史已记录则保留历史值；否则当 `explore_imp_cnt_nd > 0` 时记录当日日期。
     - `finish_explore_date`：历史已记录则保留历史值；否则当 `explore_imp_cnt_nd > 300` 时记录当日日期。
   - 以 `INSERT OVERWRITE` 方式写入目标表当日分区（`grass_region` + `local_date`）。

### 注意事项

- **自引用依赖**：ETL 读取目标表自身前一日分区，首次写入某区域时历史视图为空，需确保初始分区存在或做好冷启动处理。
- **分区覆写**：采用 `INSERT OVERWRITE PARTITION` 模式，每次执行仅覆盖指定 `grass_region` + `local_date` 的分区，不影响其他分区数据。
- **参数化执行**：SQL 中使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 等占位符，需由调度框架在运行时注入，不同区域需分别执行。
- **single writer**：本表仅有一个 ETL 文件，不存在多写入方并发冲突风险。
- **探索完成阈值**：`finish_explore_date` 的触发条件为 `explore_imp_cnt_nd > 300`，该阈值为业务硬编码逻辑，如业务规则变更需同步修改 ETL。

---

*文档生成时间：2026-05-20*