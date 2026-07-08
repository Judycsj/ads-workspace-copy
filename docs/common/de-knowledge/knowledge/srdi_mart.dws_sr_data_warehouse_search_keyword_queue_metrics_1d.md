<!-- ads-workspace-gdoc-sync: gdoc_id=1MYABtHmY36wEu9H4O5Rs9_mVzp9iVvY1QqHeTQHIj_E gdoc_url=https://docs.google.com/document/d/1MYABtHmY36wEu9H4O5Rs9_mVzp9iVvY1QqHeTQHIj_E/edit -->

# srdi_mart.dws_sr_data_warehouse_search_keyword_queue_metrics_1d

**分层**: dws_search
**主键**: `keyword` + `queue_id` + `grass_region` + `local_date`
**分区**: `grass_region`（地区）, `local_date`（业务日期）
**更新频率**: 每日一次（T+1）
**引用频次 / 访问频次**: 11

---

## 业务描述

本表是搜索域关键词 × 召回队列维度的日粒度汇总宽表，面向搜索算法分析与运营评估场景。表中以搜索关键词（`keyword`）和召回队列（`queue_id`）为核心维度，融合了：

1. **算法侧指标**：当天召回日志中每个 (keyword, queue_id) 组合实际参与排序的商品数（`ranking_items`），反映队列召回能力；
2. **曝光 / 点击行为指标（当日）**：从用户行为追踪数据汇聚而来的曝光 PV / UV / 商品数、点击 PV / UV / 商品数，以及点击率；
3. **成交指标（当日 + 近 7 日）**：订单数、成交商品数、GMV、下单用户数，同时提供当日值与过去 7 天累计值，便于观察短期与中期转化效果。

**适合回答的典型问题**：
- 某关键词在各召回队列上的排序商品规模是否健康（`ranking_items`）？
- 不同召回队列对同一关键词的曝光、点击及转化贡献如何？
- 特定队列在指定地区的 CTR 趋势如何变化？
- 某关键词 7 日内带来了多少 GMV，与当日 GMV 的比值如何？
- 各地区各队列的成交用户覆盖情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区（国家/站点）标识，对应 ETL 参数 `${grass_region}`；每次写入覆盖单个地区分区 |
| `local_date` | date | 业务日期，对应 ETL 参数 `${local_date}`；每次写入覆盖单天分区 |

### 维度：搜索关键词与召回队列

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词，已经过 `LOWER(TRIM(...))` 标准化处理 |
| `queue_id` | int | 召回队列 ID，来自算法日志的 `recall_types` 字段展开；`queue_id >= 0` 表示有效队列 |

### 指标：召回排序规模（算法侧，当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ranking_items` | bigint | 当日该 (keyword, queue_id) 组合在排序阶段出现的去重商品数；仅保留 `ranking_items >= 5` 的组合（作为基础过滤条件） |

### 指标：曝光行为（当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_items` | bigint | 当日曝光的去重商品数（`count distinct item_id` where `is_imp > 0`） |
| `imp_pv` | bigint | 当日曝光次数（`sum(is_imp > 0)`，以 (user, request, item) 为粒度计数） |
| `imp_uv` | bigint | 当日曝光去重用户数（`count distinct user_id` where `is_imp > 0`） |

### 指标：点击行为（当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_items` | bigint | 当日被点击的去重商品数（`count distinct item_id` where `is_clk > 0`） |
| `click_pv` | bigint | 当日点击次数（`sum(is_clk > 0)`） |
| `click_uv` | bigint | 当日点击去重用户数（`count distinct user_id` where `is_clk > 0`） |
| `ctr_pv` | double | 当日点击率（`click_pv / imp_pv`）；为预聚合派生比率，**不可直接跨行累加** |

### 指标：成交转化（当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_items` | bigint | 当日产生订单的去重商品数（`count distinct item_id` where `is_order > 0`） |
| `order_num` | bigint | 当日订单次数（`sum(is_order > 0)`，以 (user, request, item) 粒度） |
| `order_gmv` | double | 当日成交 GMV（美元），含当日行为窗口内的 `gmv_usd` 之和 |
| `order_uv` | bigint | 当日下单去重用户数（`count distinct user_id` where `is_order > 0`） |

### 指标：成交转化（近 7 日滚动窗口）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_items_7d` | bigint | 过去 7 日（`[local_date-7, local_date-1]`）产生订单的去重商品数 |
| `order_num_7d` | bigint | 过去 7 日去重订单数（`count distinct order_id`） |
| `order_gmv_7d` | double | 过去 7 日成交 GMV（美元）之和 |
| `order_uv_7d` | bigint | 过去 7 日下单去重用户数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则会触发全分区扫描，代价极高。  
- **`local_date`**：必须指定具体日期或合理日期范围，避免跨分区全表扫描。  
- 示例：`WHERE grass_region = 'SG' AND local_date = '2024-06-01'`

### 不可直接 SUM / AVG 的字段

| 字段 | 原因 | 正确做法 |
|---|---|---|
| `ctr_pv` | 预聚合比率（`click_pv / imp_pv`），直接累加无业务意义 | 需用 `SUM(click_pv) / SUM(imp_pv)` 重新计算 |
| `imp_uv`、`click_uv`、`order_uv`、`order_uv_7d` | 去重用户数，跨行累加会重复计数 | 不可跨 keyword / queue_id 直接相加，需回溯明细层 |
| `imp_items`、`click_items`、`order_items`、`order_items_7d`、`ranking_items` | 去重商品数，跨维度聚合会重复计数 | 跨 keyword / queue_id 汇总时需回溯明细层 |
| `order_num_7d` | 7 日去重订单数，与当日口径不同（`distinct order_id`），不可与 `order_num` 直接相加 | 注意口径差异，避免混用 |

### 时效性说明

- 本表为 **T+1 日粒度**快照表，当天数据通常在次日凌晨完成写入。
- `order_gmv_7d` 等 `_7d` 字段反映的是 **过去 7 个自然日**（不含当日）的滑动窗口聚合值；需注意它与当日指标的时间窗口不同，**两者不可直接累加**。
- 表中不包含广告流量（`is_ads = false` 过滤），仅代表自然搜索结果数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `search_data.dwd_extracted_data_from_sample_dump_1h` | 搜索算法采样日志，用于提取 (keyword, item_id, recall_types) 以计算 `ranking_items` |
| `srdi_mart.dwd_fp_search_base_1d` | 搜索行为追踪宽表（曝光、点击、成交），按 `rule_ids` 展开队列，分别用于计算当日行为指标和 7 日成交指标 |

---

## ETL 逻辑摘要

### 数据流

```
search_data.dwd_extracted_data_from_sample_dump_1h
    │  (当日数据，按 dt + country 过滤)
    ▼
search_algo_log_raw → item 展开 → queue 展开 → 聚合
    └─► search_algo_log_agg（ranking_items，≥5 条件过滤）
                                        │
srdi_mart.dwd_fp_search_base_1d         │
    │  (当日，is_ads=false)              │
    ▼                                   │
search_tracking_raw → 去重聚合           │
    └─► search_tracking_1d              │
        (imp/click/order 当日指标)       │  LEFT JOIN (keyword, queue_id)
                                        │◄──────────────────────────────
srdi_mart.dwd_fp_search_base_1d         │
    │  (过去7日，is_ads=false，          │
    │   仅含 order_id not null)          │
    ▼                                   │
search_tracking_7d_raw → 去重聚合       │
    └─► search_tracking_7d             │
        (7日成交指标)                   │
                                        ▼
              INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_search_keyword_queue_metrics_1d
              PARTITION (grass_region, local_date)
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `search_algo_log_raw` | 从算法采样日志读取当日数据，对 `query` 做 `LOWER(TRIM)` 标准化 |
| 2 | `search_algo_log_item_exploded` | 将 `request_items` 数组展开为 (keyword, item_id, queues) 行 |
| 3 | `search_algo_log_queue_exploded` | 将 `queues`（recall_types）数组展开为 (keyword, queue_id, item_id) 行 |
| 4 | `search_algo_log_agg` | 按 (keyword, queue_id) 聚合 `count distinct item_id`，过滤 `item_id > 0`、`queue_id >= 0`，并 HAVING `ranking_items >= 5` |
| 5 | `search_tracking_raw` | 从行为宽表读取当日非广告数据，展开 `rule_ids` 为 queue_id |
| 6 | `search_tracking` | 按 (keyword, queue_id, user_id, request_id, item_id) 去重，标记 is_imp / is_clk / is_order，累加 gmv；HAVING 过滤无曝光行 |
| 7 | `search_tracking_1d` | 在去重粒度上按 (keyword, queue_id) 聚合，计算当日全部曝光/点击/成交指标及 ctr_pv |
| 8 | `search_tracking_7d_raw` | 从行为宽表读取过去 7 日（`[local_date-7, local_date-1]`）非广告、有订单的数据，展开 queue_id |
| 9 | `search_tracking_7d` | 按 (keyword, queue_id) 聚合 7 日成交的去重商品数、订单数、GMV、用户数 |
| 10 | INSERT OVERWRITE | 以 `search_algo_log_agg` 为主驱动表，LEFT JOIN `search_tracking_1d` 和 `search_tracking_7d`，写入目标分区 |

### 注意事项

- **以算法日志为驱动**：最终 INSERT 以 `search_algo_log_agg`（ranking_items）为左表，行为指标通过 LEFT JOIN 补入；若某 (keyword, queue_id) 在行为表中无匹配，则曝光/点击/成交字段均为 `NULL`，查询时需注意 NULL 处理。
- **HAVING ranking_items >= 5**：表中仅保留召回商品数不低于 5 的 (keyword, queue_id) 组合，低频长尾关键词可能被过滤。
- **INSERT OVERWRITE 分区写入**：每次 ETL 按 `(grass_region, local_date)` 覆盖写入，同一分区的历史数据会被全量替换，重跑历史分区是安全的。
- **单 writer**：该表由单一 ETL 文件写入（`multi_writer = false`），无并发写入冲突风险。
- **7 日窗口口径差异**：`_7d` 指标的订单去重粒度为 `distinct order_id`，而当日 `order_num` 的粒度为 (user, request, item) 行计数，两者统计口径不同，不可混用。
- **非广告流量**：所有行为指标均在 `is_ads = false` 条件下计算，不包含广告投放带来的流量。

---

*文档生成时间：2026-05-17*