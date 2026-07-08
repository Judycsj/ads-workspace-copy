<!-- ads-workspace-gdoc-sync: gdoc_id=1usRhraUgtIibQ3GcqSDl230pyKvV-fzPdjkGn7MWaCU gdoc_url=https://docs.google.com/document/d/1usRhraUgtIibQ3GcqSDl230pyKvV-fzPdjkGn7MWaCU/edit -->

# srdi_mart.ads_sr_data_warehouse_search_keyword_top_rel_item_1d

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `local_date` + `keyword`
**分区**：`grass_region`（大区）、`local_date`（业务日期）
**更新频率**：每日（T+1）
**引用频次 / 访问频次**：167

---

## 业务描述

本表用于沉淀**搜索关键词与其关联商品的 Top 排名关系**，每日按大区维度产出。

核心业务场景：

- 对搜索量位于头部（累计搜索量占比 ≤ 80%）的关键词，基于近 7 天的曝光、点击、成交数据，计算每个关键词下表现最佳的 Top 30 商品列表，并将其聚合打包存储为 JSON 数组字段。
- 支持搜索运营、推荐策略团队快速获取"高价值关键词 → 优质商品"的映射关系，用于搜索结果优化、流量分析及关键词商品相关性评估。

适合回答的典型问题：

- 某大区某日，关键词 X 下排名前 N 的关联商品有哪些？
- 头部关键词下，哪些商品的曝光/点击/成交综合表现最优？
- 关键词与其强相关商品、店铺的映射关系是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY 等），来自任务执行参数 `${grass_region}` |
| `local_date` | date | 业务日期，与上游表分区对齐，数据口径为截至当日 |

### 维度：关键词

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词，为当日大区内累计搜索量占比 ≤ 80% 的关键词（过滤自然搜索、全卡片类型、近 7 天搜索量 > 0 的词） |

### 指标：关键词关联商品列表

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_list` | array\<string\> | 该关键词下 Top 30 关联商品的 JSON 数组，按综合排名分数降序排列。每个元素为 JSON 字符串，结构为 `{"shop_id": ..., "item_id": ...}` |
| `debug_list` | array\<string\> | 与 `item_list` 一一对应的调试信息 JSON 数组，每个元素结构为 `{"imp_cnt": ..., "click_cnt": ..., "order_cnt": ..., "item_rank": ...}`，记录各商品的曝光数、点击数、成交数及排名，供调试和验证使用 |

---

## 查询使用须知

**必须包含的过滤条件**

- 查询时必须同时指定 `grass_region` 和 `local_date` 两个分区字段，以避免全表扫描。例如：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```

**不可直接聚合的字段**

- `item_list` 和 `debug_list` 均为预聚合的 JSON 数组字段，不可跨行直接 SUM 或 COUNT；如需解析内部元素，需先使用 `LATERAL VIEW` + `EXPLODE` 展开，再对 `get_json_object` 提取的子字段进行操作。
- `debug_list` 中的 `imp_cnt`、`click_cnt`、`order_cnt` 是近 7 天的汇总值（基于近 7 天明细数据 `GROUP BY` 聚合而来），不代表单日数据，跨日叠加 `local_date` 维度时会产生重复计算，**不可直接跨分区 SUM**。
- 排名分数（`rank_score`）为复合加权得分（曝光/10000 + 点击/100 + 成交×10），仅存于中间视图，最终表中未输出，不支持直接查询；若需排名信息，请参考 `debug_list` 中的 `item_rank`。

**时效性说明**

- 本表为日粒度（`_1d`）表，每日全量覆盖写入对应分区（`INSERT OVERWRITE`）。
- 商品指标统计口径为**近 7 天滚动窗口**（`dt BETWEEN date_sub(local_date, 6) AND local_date`），关键词热度来自 `time_range = 7` 的预聚合表，两者口径一致。
- 数据通常于次日产出，当日分区数据在 ETL 完成前不可用。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d` | 获取关键词近 7 天搜索量，用于计算搜索量排名及累计占比，筛选头部关键词（累计占比 ≤ 80%） |
| `srdi_mart.dwd_fp_search_base_1d` | 获取近 7 天搜索行为明细（曝光、点击、成交），关联头部关键词，计算各关键词下商品的综合排名分数 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_search_keyword_level_metrics_30d
    │  （取 local_date 分区，time_range=7，is_ads='__ALL__'，card_type='__ALL__'，search_volume>0）
    ▼
[keyword_search_rank_pct]  计算关键词搜索量排名 & 累计占比
    ▼
[filter_keyword]  过滤保留累计搜索量占比 ≤ 80% 的关键词，并打标分层（20%/50%/80%）
    ▼
dwd_fp_search_base_1d（近 7 天，country=grass_region，rel_lx=2，user_id>0）
    INNER JOIN filter_keyword
    ▼
[base_table]  按 keyword + item_id 聚合曝光/点击/成交，计算综合排名分数 rank_score
    ▼
[rank_table]  按 keyword 分组，对 rank_score 降序 ROW_NUMBER 排名
    ▼
[sort_table]  过滤 item_rank ≤ 30，按 keyword, item_rank 排序
    ▼
INSERT OVERWRITE → ads_sr_data_warehouse_search_keyword_top_rel_item_1d
    按 keyword 聚合，collect_list + transform 生成 item_list 和 debug_list JSON 数组
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `keyword_search_rank_pct_${grass_region_without_quote}` | 从 DWS 关键词指标表读取当日、指定大区、近 7 天搜索量数据，计算搜索量降序排名（`RANK()`）及累计搜索量占比（窗口累计 / 总量） |
| Step 2 | `filter_keyword_${grass_region_without_quote}` | 过滤累计占比 ≤ 0.8 的关键词，并按累计占比区间打标（0~20%、20%~50%、50%~80%） |
| Step 3 | `base_table_${grass_region_without_quote}` | 将过滤后的关键词与近 7 天搜索明细（DWD）内连接，按 `keyword + item_id + keyword_search_volume_type` 聚合曝光/点击/成交，计算综合排名分数：`rank_score = imp_cnt/10000 + click_cnt/100 + order_cnt×10` |
| Step 4 | `rank_table_${grass_region_without_quote}` | 按 `keyword` 分区，对 `rank_score` 降序使用 `ROW_NUMBER()` 生成商品排名 `item_rank` |
| Step 5 | `sort_table_${grass_region_without_quote}` | 过滤 `item_rank ≤ 30`，并按 `keyword, item_rank` 排序，确保后续 `collect_list` 顺序正确 |
| Step 6 | INSERT OVERWRITE | 按 `keyword` 分组，使用 `collect_list` + `transform` 将商品信息和调试信息分别序列化为 JSON 字符串数组，写入目标表对应分区 |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无多 Writer 并发冲突风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE ... PARTITION(grass_region=..., local_date=...)` 静态分区写入，每次执行幂等，重跑安全。
- **字段顺序依赖**：`item_list` 和 `debug_list` 依赖 `sort_table` 中 `ORDER BY keyword, item_rank` 的顺序，依靠 Spark 的 `collect_list` 保序特性（在单 stage 有序输入下）生效；若 Spark 版本或执行计划变更导致顺序不稳定，两个数组的对应关系可能错乱，需关注。
- **动态参数**：Temporary View 名称含大区参数 `${grass_region_without_quote}`，支持多大区并行执行而不互相干扰。
- **关键词过滤口径**：仅保留 `is_ads = '__ALL__'`、`card_type = '__ALL__'`、`time_range = 7`、`search_volume > 0` 的关键词，口径变更需同步修改 ETL。
- **搜索明细过滤**：DWD 层仅取 `rel_lx = 2`（关联类型）且 `user_id > 0`（排除非登录用户）的记录，与其他指标口径可能存在差异。

---

*文档生成时间：2026-05-17*