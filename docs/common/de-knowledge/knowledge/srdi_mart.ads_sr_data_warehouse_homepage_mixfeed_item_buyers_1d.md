<!-- ads-workspace-gdoc-sync: gdoc_id=17wZ2m-3ylYYjkuhAnMKYrvx5lZGeEX6KmX2Lkfq0EKQ gdoc_url=https://docs.google.com/document/d/17wZ2m-3ylYYjkuhAnMKYrvx5lZGeEX6KmX2Lkfq0EKQ/edit -->

# srdi_mart.ads_sr_data_warehouse_homepage_mixfeed_item_buyers_1d

**分层**：ADS（应用数据层）
**主键**：`item_id`（分区内唯一）
**分区**：`grass_region`（大区）、`local_date`（业务日期）
**更新频率**：每日一次（T+1）
**引用频次 / 访问频次**：69 次

---

## 业务描述

本表用于记录**首页混合信息流（MixFeed / Daily Discover）场景**下，各商品在过去 3 天内的**购买用户样本**与**加购用户样本**。每行对应一个商品（`item_id`），存储该商品最近购买或加购行为中，按时间倒序排列的 **Top 3 用户 ID 字符串**，供下游召回、排序或用户展示场景使用。

**核心业务场景：**
- 首页混合信息流商品的社交信任信号构建（"已有 N 人购买"等展示）
- 商品推荐召回阶段的协同过滤特征
- 运营看板中商品近期购买 / 加购用户画像快照

**适合回答的问题：**
- 某商品在某大区过去 3 天内，从首页 MixFeed 入口产生的最新购买用户有哪些（最多 3 人）？
- 某商品在某大区过去 3 天内，从首页 MixFeed 入口产生的最新加购用户有哪些（最多 3 人）？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 业务大区（如 ID、TH、MY 等），用于数据隔离与分区裁剪 |
| `local_date` | date | 业务日期，对应 ETL 运行日期（当天），数据覆盖 `[local_date-2, local_date]` 共 3 天 |

### 维度：商品维度

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，分区内主键 |

### 指标：用户样本（Top 3，近 3 天窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `bought_users_3d` | string | 过去 3 天内从首页 MixFeed 入口完成购买的用户 ID 样本，按行为时间倒序取 Top 3，多个用户以 `#` 分隔（如 `"123#456#789"`）；无数据时为 `NULL` |
| `atc_users_3d` | string | 过去 3 天内从首页 MixFeed 入口完成加购（Add-to-Cart）的用户 ID 样本，按行为时间倒序取 Top 3，多个用户以 `#` 分隔；无数据时为 `NULL` |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`**，否则将触发全分区扫描，严重影响性能。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-06-01'
  ```
- `local_date` 语义为"截止到当天"的近 3 天滚动窗口，每日全量覆盖写入，查询时取最新分区即可获得最新数据。

### 不可直接聚合的字段

| 字段 | 原因 |
|---|---|
| `bought_users_3d` | 字符串拼接的用户 ID 列表，不可直接 SUM / COUNT；若需统计人数，需先 `split` 后计算数组长度，且存在去重问题 |
| `atc_users_3d` | 同上，字符串拼接的用户 ID 列表，不可直接 SUM / COUNT |

> ⚠️ 两个指标字段均为 **预聚合派生字符串**，仅保留 Top 3 样本，**不代表全量用户**，不可用于精确统计人数或去重计算。

### 时效性说明

- 本表为 **`_1d` 日粒度快照表**，每日 T+1 更新一次。
- 字段内数据覆盖窗口为 **近 3 天（`local_date - 2` 至 `local_date`）**，属于滚动窗口，非累计值。
- 分区采用 `INSERT OVERWRITE`，每次运行全量覆盖当日分区，无增量追加风险。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 用户行为明细表，提供首页 MixFeed 场景下的购买（`operation = 'order'`）和加购（`operation = 'cart'`）事件，包含用户 ID、商品 ID、事件时间等字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
        │
        ├─── [过滤：近3天 + 大区 + home页 + daily_discover + item_mix_feed_card]
        │
        ├─── 购买事件 (operation='order') ──► bought_data    ──► top3_bought
        │                                     (去重取最新)      (Row_Number ≤ 3)
        │
        └─── 加购事件 (operation='cart')  ──► cart_data     ──► top3_cart
                                              (去重取最新)      (Row_Number ≤ 3)
                                                     │
                                              combined_data (UNION ALL)
                                                     │
                                    INSERT OVERWRITE  ▼
                     ads_sr_data_warehouse_homepage_mixfeed_item_buyers_1d
```

### 关键步骤

1. **Statement 1 — `bought_data` 临时视图**
   从 `dwd_sr_data_warehouse_platform` 过滤近 3 天、指定大区、首页（`source1_page_type = 'home'`）、Daily Discover 频道（`source1_page_section[0] = 'daily_discover'`）、MixFeed 卡片（`source1_target_type = 'item_mix_feed_card'`）的**购买事件**，按 `(user_id, item_id)` 去重保留最大时间戳，再用 `ROW_NUMBER()` 按商品维度对用户按时间倒序排序。

2. **Statement 2 — `cart_data` 临时视图**
   逻辑与 Statement 1 完全对称，过滤条件相同，仅将 `operation` 改为 `'cart'`，提取**加购事件**并进行相同的去重和排序处理。

3. **Statement 3 — `top3_bought` 临时视图**
   从 `bought_data` 中筛选 `row_num <= 3`，按 `item_id` 分组，用 `concat_ws('#', COLLECT_LIST(user_id))` 将最多 3 个用户 ID 拼接为字符串。

4. **Statement 4 — `top3_cart` 临时视图**
   与 Statement 3 对称，从 `cart_data` 中生成加购用户 Top 3 字符串。

5. **Statement 5 — `combined_data` 临时视图**
   `UNION ALL` 合并 `top3_bought` 与 `top3_cart`，购买结果行 `atc_3d_array` 为 `NULL`，加购结果行 `bought_3d_array` 为 `NULL`，为后续 `MAX` 聚合合并做准备。

6. **Statement 6 — 写目标表**
   `INSERT OVERWRITE` 指定分区（`grass_region`、`local_date`），对 `combined_data` 按 `item_id` 分组，用 `MAX` 聚合将两列分别合并（空值忽略），得到每个商品同时包含购买和加购用户样本的单行结果；使用 `REPARTITION(1)` 控制输出文件数为 1。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件，无多 writer 并发写入风险。
- **分区全量覆盖**：每次运行使用 `INSERT OVERWRITE PARTITION`，当日分区被完整覆盖，不存在历史分区数据残留问题。
- **`COLLECT_LIST` 顺序不保证**：`ROW_NUMBER` 排序仅在聚合前完成，`COLLECT_LIST` 本身不保证顺序，最终 `bought_users_3d` / `atc_users_3d` 中用户 ID 顺序可能与预期时间倒序不完全一致。
- **用户 ID 过滤**：ETL 使用 `COALESCE(user_id, 0) > 0` 排除匿名用户（user_id 为 NULL 或 0）。
- **`REPARTITION(1)`**：最终写入强制合并为 1 个文件，适合小数据量分区，若未来数据量增长需评估性能影响。
- **参数化执行**：SQL 中的 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 为运行时注入参数，临时视图名含大区标识，支持多大区并行调度而不互相干扰。

---

*文档生成时间：2026-05-17*