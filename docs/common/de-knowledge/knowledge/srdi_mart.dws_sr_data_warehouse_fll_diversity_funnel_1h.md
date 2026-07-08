<!-- ads-workspace-gdoc-sync: gdoc_id=1CheoTezn-aRdfInhS89ne-JdZJIhABuGl6WjUTzknFI gdoc_url=https://docs.google.com/document/d/1CheoTezn-aRdfInhS89ne-JdZJIhABuGl6WjUTzknFI/edit -->

# srdi_mart.dws_sr_data_warehouse_fll_diversity_funnel_1h

**分层：** DWS（数据汇总层）
**主键：** `regional_date` + `regional_hour` + `country` + `bundle` + `abt` + `is_ads` + `recall_queue_id` + `card_type` + `stage`
**分区：** `regional_date`（日期）、`regional_hour`（小时）
**更新频率：** 每小时一次（小时级调度，按分区覆盖写入）
**访问频次：** 844

---

## 业务描述

本表统计搜推**全链路日志（FLL）**在各漏斗阶段中，推荐结果的 **LLM Cluster（大模型聚类）多样性**指标，粒度为小时级。

核心业务场景为：衡量推荐系统在从召回（RECALL）到分发（DISPATCH）各阶段中，推荐内容的聚类多样性水平，以便评估不同 A/B 实验分组、广告/非广告、召回队列、卡片类型等维度对多样性的影响。

适合回答的典型问题：

- 某 A/B 实验组在 RANK 阶段的 LLM Cluster 多样性（每请求唯一 cluster 数、cluster 密度）是否优于对照组？
- 广告与非广告商品在各漏斗阶段的多样性差异如何？
- 特定召回队列、卡片类型在不同阶段的 LLM Cluster 数量分布趋势？
- 各国家/地区、各业务场景（DD、购物车等）的多样性漏斗表现对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据所属日期（本地区域时间），分区键，格式 `yyyy-MM-dd` |
| `regional_hour` | string | 数据所属小时（本地区域时间），分区键，格式 `HH`（如 `09`） |

### 维度：业务与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `country` | string | 国家/地区编码，如 `ID`、`BR`、`PH`、`TH`、`VN`、`MY`、`TW`、`SG`；由分区写入参数确定 |
| `bundle` | string | 推荐场景标识：`dd`（Daily Discover 主场景）或 `cart`（购物车及相关场景） |
| `abt` | string | A/B 实验分组 ID（字符串类型）；按国家过滤特定实验 ID 段；`__ALL__` 表示所有分组汇总 |
| `is_ads` | string | 是否为广告商品：`true`（ROI1/TARGET_ROI2/SIMPLE_ROI2 类型）/ `false`（非广告）；`__ALL__` 表示不区分 |
| `recall_queue_id` | string | 召回队列 ID（字符串类型），来源于召回策略的 `queue_id`；`__ALL__` 表示所有队列汇总 |
| `card_type` | string | 卡片类型，枚举值：`ITEM`、`VIDEO`、`STREAM`、`OTHER` |
| `stage` | string | 推荐漏斗阶段，枚举值：`RECALL`、`PRERANK`、`RANK`、`MIXRANK`、`DISPATCH` |

### 指标：LLM Cluster 多样性

| 字段 | 类型 | 说明 |
|---|---|---|
| `unique_llm_cluster_count` | bigint | 当前维度组合下，所有请求中出现的唯一 LLM Cluster（`llm_cluster_v2`）数量之和；经 CUBE 聚合去重后统计 |
| `unique_llm_cluster_per_req` | double | 每请求平均唯一 LLM Cluster 数，计算公式：`unique_llm_cluster_count / unique_request_cnt`（请求数来自关联的请求汇总表）|
| `llm_cluster_density` | double | LLM Cluster 密度，计算公式：`unique_llm_cluster_count / item_cnt`（`item_cnt` 为该维度下所有请求的商品总数）|

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：查询时务必同时过滤 `regional_date` 和 `regional_hour`，避免全表扫描。示例：
  ```sql
  WHERE regional_date = '2025-05-17'
    AND regional_hour = '10'
    AND country = 'ID'
  ```
- `country` 虽为分区写入参数而非显式分区列，建议始终在 `WHERE` 中指定以缩小扫描范围。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确聚合方式 |
|---|---|---|
| `unique_llm_cluster_per_req` | 派生比率指标（cluster 数 / 请求数），不具备可加性 | 重新用 `SUM(unique_llm_cluster_count) / SUM(unique_request_cnt)` 计算（需关联原始统计数据）|
| `llm_cluster_density` | 派生比率指标（cluster 数 / 商品总数），不具备可加性 | 同上，重新使用分子分母累加后再计算比值 |
| `unique_llm_cluster_count` | 跨维度已做 CUBE 聚合去重，多行相加存在重复计数风险 | 注意维度组合的 `__ALL__` 行已代表该维度的全量汇总，不应与细分行叠加 |

### `__ALL__` 维度说明

- `abt`、`is_ads`、`recall_queue_id` 三个维度通过 `CUBE` 展开，值为 `__ALL__` 的行代表该维度的全量聚合结果。
- 混合使用 `__ALL__` 行与细分行时，会导致重复计算，需在查询中明确约束维度取值。

### 时效性说明

- 本表为**小时级**汇总表，数据覆盖粒度为单小时，不跨天累积。
- 数据产出依赖上游 FLL 日志的小时分区就绪，通常在当前小时结束后延迟产出，请注意时效性。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_rcmd` | 全链路推荐日志原始宽表，提供请求维度、漏斗阶段信息、商品明细、A/B 分组、LLM Cluster 等字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_rcmd
    │
    ▼
raw_*（过滤、字段预处理：按国家/小时/bundle 过滤，提取 ab_signs）
    │
    ▼
exploded_*（多维展开：炸开 ab_signs、data 商品列表、漏斗 stage 数组、recall_queue_id 数组）
    │
    ├──────────────────────────────────────────┐
    ▼                                          ▼
uniq_req_pre_*（CUBE 聚合去重请求维度）   uniq_llm_pre_*（CUBE 聚合去重 LLM Cluster 维度）
    │                                          │
    ▼                                          ▼
uniq_req_*（汇总请求数、商品总数）        uniq_llm_*（汇总唯一 LLM Cluster 数）
    │                                          │
    └──────────────┬───────────────────────────┘
                   ▼
          LEFT JOIN 合并 → 计算比率指标
                   │
                   ▼
    srdi_mart.dws_sr_data_warehouse_fll_diversity_funnel_1h
    （INSERT OVERWRITE 按分区覆盖写入）
```

### 关键步骤

1. **`raw_*`（数据过滤与预处理）**
   - 过滤指定日期、小时、国家分区的 FLL 全链路数据（`sample_info.full_link_all = true`）。
   - 限定 bundle 范围：`daily_discover_main`、`shoppingcart`、`orderpaid_discover`、`my_purchases_page_ymal`、`order_detail_page_ymal`，并映射为 `dd`/`cart`。
   - 按国家从 `ab_sign` 数组中过滤出目标实验 ID（各国对应特定实验 ID 区间）。

2. **`exploded_*`（多维展开）**
   - `LATERAL VIEW OUTER EXPLODE(ab_signs)`：展开实验分组维度。
   - `LATERAL VIEW EXPLODE(data)`：展开商品列表，每条记录对应一个商品。
   - `LATERAL VIEW EXPLODE(array_remove(array(...), ''))`：将漏斗阶段动态构造为数组（根据各 stage info 字段非空性判断），展开为行，实现商品在多个漏斗阶段的多行表示。
   - `LATERAL VIEW OUTER EXPLODE(recall_info.strategies[*].queue_id)`：展开召回队列 ID。
   - 广告类型判断：`item_type IN ('ROI1','TARGET_ROI2','SIMPLE_ROI2')` 标记为广告。
   - 卡片类型归一化：映射为 `ITEM`/`VIDEO`/`STREAM`/`OTHER`。

3. **`uniq_req_pre_*` → `uniq_req_*`（请求维度聚合）**
   - 使用 `GROUP BY ... CUBE(abt, is_ads, recall_queue_id)` 生成所有维度组合（含 `__ALL__` 汇总行）。
   - 汇总得到各维度组合下的请求数（`unique_request_cnt`）和商品总数（`item_cnt`）。

4. **`uniq_llm_pre_*` → `uniq_llm_*`（LLM Cluster 多样性聚合）**
   - 同样使用 `CUBE(abt, is_ads, recall_queue_id)` 展开维度。
   - 以 `(request_id, llm_cluster_v2)` 为粒度去重后，统计每个维度组合的唯一 LLM Cluster 数（`unique_llm_cluster_count`）。

5. **最终写入**
   - 将 `uniq_llm_*` 与 `uniq_req_*` 按 `country`、`bundle`、`abt`、`is_ads`、`recall_queue_id`、`card_type`、`stage` LEFT JOIN。
   - 计算 `unique_llm_cluster_per_req`（cluster 数 / 请求数）和 `llm_cluster_density`（cluster 数 / 商品总数）。
   - 使用 `INSERT OVERWRITE ... PARTITION(regional_date, regional_hour, country)` 按分区覆盖写入目标表。

### 注意事项

- **单一 writer**：本表仅有一个 ETL 文件写入，不存在多写竞争问题。
- **动态国家分区**：ETL 通过 `${grass_region}` 参数控制写入国家分区，每次运行写入特定国家的一个小时分区，多国数据需多次调度完成。
- **CUBE 维度展开导致数据膨胀**：三个维度的 CUBE 会产生最多 2³=8 种组合，查询时若不限定 `__ALL__` 使用范围，数据量和结果可能显著膨胀。
- **LEFT JOIN 方向**：以 LLM Cluster 汇总表为左表，请求汇总表为右表进行 LEFT JOIN，若某维度组合下无对应请求记录，`unique_llm_cluster_per_req` 和 `llm_cluster_density` 将为 NULL（除数为 NULL）。
- **`recall_queue_id` 为空场景**：非召回阶段（如 RANK、DISPATCH）商品的 `recall_queue_id` 可能为 NULL，经 `OUTER EXPLODE` 后保留为单行，与 `__ALL__` 汇总行共存，查询时需注意区分。

---

*文档生成时间：2026-05-17*