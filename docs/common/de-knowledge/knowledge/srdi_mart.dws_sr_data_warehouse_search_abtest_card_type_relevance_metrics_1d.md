<!-- ads-workspace-gdoc-sync: gdoc_id=1bfPgu7AWQH-0ZwserogyIk311vh8xKbwaDuVqDLzods gdoc_url=https://docs.google.com/document/d/1bfPgu7AWQH-0ZwserogyIk311vh8xKbwaDuVqDLzods/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_card_type_relevance_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `exp_group_id` + `ads_type` + `sort_type` + `top_location_type` + `card_type` + `search_mid` + `with_keyword`
**分区：** `grass_region`（地区）, `local_date`（日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 1384

---

## 业务描述

本表是搜索相关性 A/B 实验的每日汇总宽表，面向**搜索质量评估与 A/B 实验对比**场景。

核心逻辑：以搜索曝光商品的相关性打分为基础，按实验分组（`exp_group_id`）、卡片类型（`card_type`）、广告类型（`ads_type`）、排序类型（`sort_type`）、位置区间（`top_location_type`）、搜索入口（`search_mid`）及是否带关键词（`with_keyword`）多维度聚合，产出请求量、曝光量、相关性得分、差/好请求数等核心指标。

**适合回答的典型问题：**
- 不同 A/B 实验组在某日的搜索相关性整体表现如何？
- 各卡片类型（图文卡、视频卡等）对相关性的影响是否存在显著差异？
- 广告位（Ads）与非广告位（Non Ads）的相关性差距如何？
- 前 20 位结果（`top_location_type = '20 below'`）的相关性是否优于整体？
- 图像搜索与文本搜索的相关性表现差异？
- bad query 率和 good query 率在各实验组间的对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/国家分区，如 `SG`、`PH` 等，对应业务的地区维度 |
| `local_date` | date | 数据日期，格式 `YYYY-MM-DD`，每日一分区 |

### 维度：实验与请求维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来自实验用户分组表，标识用户所属的实验桶 |
| `ads_type` | string | 广告类型，取值来自 `sub_product_type`（有值时）、`'Non Ads'`（非广告）、`'others'`（其他）；`'__ALL__'` 表示全量汇总 |
| `sort_type` | string | 搜索排序类型，如默认排序、价格排序等；原始为 NULL 时填充 `'NA'`，跨维度汇总时为 `'__ALL__'` |
| `top_location_type` | string | 搜索结果展示位置区间，取值：`'20 below'`（位置 < 20）、`'20-40'`（20 ≤ 位置 < 40）、`'0-3'`、`'0-19'`、`'0-39'`、`'20-39'`、`'__ALL__'`（全量汇总）；仅统计前 40 位曝光 |
| `card_type` | string | 搜索结果卡片类型，如图文卡、视频卡等；原始为 NULL 时填充 `'NA'`，跨维度汇总时为 `'__ALL__'` |
| `search_mid` | string | 搜索入口标识；图像搜索时还额外汇总 `'mutimodel_search_all'`，文本搜索时汇总 `'text_search_all'`；`'__ALL__'` 表示全量汇总 |
| `with_keyword` | string | 是否带关键词，取值 `'true'`（有关键词）、`'false'`（无关键词）、`'__ALL__'`（全量汇总） |

### 指标：曝光与请求量

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_item_num` | bigint | 该维度组合下的曝光商品总数（去重前按请求聚合后再 SUM） |
| `request_cnt` | bigint | 该维度组合下的搜索请求数（user 粒度去重后计数再 SUM） |

### 指标：相关性得分

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_rel_score` | double | 所有曝光商品 `rel_raw`（原始相关性得分）的累计求和 |
| `total_rel_add` | double | 所有曝光商品 `rel_add`（增量相关性得分，负值截断为 0）的累计求和 |
| `total_request_avg_rel_raw` | double | 各请求维度下 `request_avg_rel_raw` 的累计值（先在请求粒度求均值，再按用户 SUM，最终再 SUM）；**不可直接除以 `request_cnt` 得到均值，需结合原始请求数还原** |
| `total_request_avg_rel_add` | double | 各请求维度下 `request_avg_rel_add` 的累计值（同 `total_request_avg_rel_raw` 逻辑）；**不可直接 SUM 后作为均值使用** |

### 指标：相关性质量分类计数

| 字段 | 类型 | 说明 |
|---|---|---|
| `irrelevant_cnt` | double | 不相关商品曝光数（`rel_lx = 0` 且 `rel_raw > 0`）的累计值 |
| `somewhat_cnt` | double | 部分相关商品曝光数（`rel_lx = 1`）的累计值 |
| `same_cnt` | bigint | 完全相关商品曝光数（`rel_lx = 3`）的累计值 |
| `bad_case_cnt` | double | 差质量曝光的加权计数：不相关商品权重为 4，部分相关权重为 0.5，其余为 0 |

### 指标：请求质量计数

| 字段 | 类型 | 说明 |
|---|---|---|
| `bad_query_cnt` | double | 差请求数：在请求粒度下，`bad_case_cnt / item_imp_cnt > 0.2` 的请求被记为 bad query，此处为累计求和 |
| `good_query_cnt` | bigint | 好请求数：在请求粒度下，`irrelevant_cnt = 0` 且 `somewhat_cnt ≤ 1` 且 `same_cnt ≥ 1` 的请求被记为 good query，此处为累计求和 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，查询时必须同时指定，避免全表扫描。示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 维度字段中 `'__ALL__'` 为汇总行，若只需特定维度的数据，需显式过滤排除 `'__ALL__'`，或明确选择 `'__ALL__'` 作为汇总口径，避免重复计算。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `total_request_avg_rel_raw` | 该字段是请求粒度均值的累计和（两次聚合），直接 SUM 跨行结果无业务意义；若需全局均值，应用 `total_rel_score / imp_item_num` 近似替代 |
| `total_request_avg_rel_add` | 同上，是预聚合派生指标，不可跨行直接 SUM |
| `bad_query_cnt` | 在请求维度定义，跨 `exp_group_id` 或 `card_type` 维度 SUM 时需注意去重问题（同一请求可能在多个维度组合中出现） |
| `good_query_cnt` | 同 `bad_query_cnt` |
| `irrelevant_cnt` / `somewhat_cnt` / `bad_case_cnt` | 因多维 GROUPING SETS 展开，不同维度组合的数据存在重叠，跨 `'__ALL__'` 行 SUM 会导致重复计数 |

### 时效性说明

- 本表为 `_1d` 后缀日表，每日 T+1 产出，反映前一日全天数据。
- 单日数据需通过 `local_date` 精确定位，不存在滚动窗口或累计逻辑。

### 其他注意事项

- `top_location_type` 仅覆盖前 40 位（`location <= 39`）的曝光，位置超出 40 的商品不计入本表。
- `rel_raw = 0` 或 `rel_lx IS NULL` 的商品在 ETL 阶段已过滤，本表数据不含此类记录。
- 用户 ID ≤ 0 的匿名用户已在 ETL 过滤，本表仅含已登录实验白名单用户的数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_fp_search_base_1d` | 搜索曝光明细，提供商品级的相关性得分（`rel_raw`、`rel_lx`、`rel_add`）、位置、排序方式、卡片类型、广告类型、搜索入口等原始字段 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维表，提供用户与实验组的映射关系，过滤条件为搜索白名单用户（`is_search_whitelist = 1`）且有分配日志（`is_assignment_log = 1`） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_fp_search_base_1d (位置/卡片/广告/相关性明细)
      │
      ├─► [按位置区间分组] dwd_fp_search_location_type
      ├─► [无位置区间]    dwd_fp_search
      └─► [search_mid 维度 + EXPLODE] dwd_fp_search_search_mid
                                          │
                                          └─► dwd_fp_search_search_location_explode
                                                    │
                           ┌──────────────────────────┘
                           ▼
              search_rel_metrics_by_req  (request 粒度，GROUPING SETS 多维聚合)
                           │
                           ▼
              search_rel_metrics_by_user (user 粒度聚合，计算 bad/good query)
                           │
                           │  INNER JOIN
              dim_sr_data_warehouse_abtest_user_group (user → exp_group_id)
                           │
                           ▼
        dws_sr_data_warehouse_search_abtest_card_type_relevance_metrics_1d
```

### 关键步骤

1. **`user_exp_mapping`**：从 A/B 实验维表中读取当日指定地区的搜索白名单用户与实验分组映射。

2. **`dwd_fp_search_location_type`**：从 `dwd_fp_search_base_1d` 读取前 40 位曝光商品，按 `(user_id, request_id, item_id, sort_type, location_type, card_type, ads_type)` 分组，聚合取最大值的相关性得分；`location_type` 按位置区间划分为 `'20 below'` 和 `'20-40'`。

3. **`dwd_fp_search`**：同源，不带 `location_type` 分组，用于全量位置汇总（对应 `top_location_type = '__ALL__'`）。

4. **`dwd_fp_search_search_mid`**：同源，额外保留 `search_mid`、`keyword`（转化为 `with_keyword`）和 `location`，并构建 `search_mids`、`with_keywords`、`location_types` 三个数组，准备 EXPLODE。

5. **`dwd_fp_search_search_location_explode`**：对上一步的三个数组执行 LATERAL VIEW EXPLODE，展开为多行，实现 `search_mid`、`with_keyword`、`location_type` 的多维汇总。

6. **`search_rel_metrics_by_req`**：将三路临时视图（带位置区间的 ads/sort/card 组合、全量位置的 ads/sort/card 组合、search_mid 路径）通过 UNION ALL 合并，使用 GROUPING SETS 在 request 粒度计算各相关性指标（`total_rel_score`、`total_rel_add`、`item_imp_cnt`、`irrelevant_cnt`、`somewhat_cnt`、`bad_case_cnt`、`same_cnt`、`request_avg_rel_raw`、`request_avg_rel_add`）。

7. **`search_rel_metrics_by_user`**：在用户粒度聚合上一步结果，累计各相关性指标，并计算 `request_cnt`（请求数）、`bad_query_cnt`（差请求数，按 `bad_case_cnt / item_imp_cnt > 0.2` 判断）、`good_query_cnt`（好请求数）。

8. **INSERT OVERWRITE（最终写入）**：将用户粒度汇总结果与实验用户映射表做 INNER JOIN（过滤未在实验白名单的用户），按实验组和所有维度字段 GROUP BY 后聚合写入目标表，输出文件使用 `REPARTITION(10)` 控制文件数。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件，无 multi-writer 风险。
- **INNER JOIN 影响覆盖范围**：最终写入仅包含在实验白名单中的用户数据，未加入实验的用户搜索行为不计入本表，分析时需注意口径与全量搜索日志不一致。
- **GROUPING SETS 展开导致数据行重叠**：`'__ALL__'` 汇总行与具体维度值行之间存在重叠，跨维度聚合时须选定单一维度口径，避免重复计算。
- **分区覆盖写入**：每次运行对指定 `(grass_region, local_date)` 分区做 INSERT OVERWRITE，重跑安全，但需确保参数 `${grass_region}` 和 `${local_date}` 正确传入。
- **`rel_raw = 0` 过滤**：ETL 已在 WHERE 条件排除 `rel_raw = 0` 的商品，表内相关性指标均基于有效打分商品。

---

*文档生成时间：2026-05-17*