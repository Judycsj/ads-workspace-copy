<!-- ads-workspace-gdoc-sync: gdoc_id=1MR22J-lX9O6qmTQD5NqqTGAo29ijLS2v2ZNsUQOOzyQ gdoc_url=https://docs.google.com/document/d/1MR22J-lX9O6qmTQD5NqqTGAo29ijLS2v2ZNsUQOOzyQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_relevance_metrics_1d

**分层：** dws_search
**主键：** exp_group_id + is_ads + is_login + sort_type + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 713

---

## 业务描述

本表为搜索 A/B 实验相关性指标日聚合宽表，面向**搜推数仓（SRDI）**的搜索质量评估场景。表中以实验组（`exp_group_id`）为核心维度，汇总每个实验组在不同广告流量（`is_ads`）、登录状态（`is_login`）和排序策略（`sort_type`）下的相关性评分均值、无关率等关键指标，用于支撑以下业务场景：

- **A/B 实验效果评估**：对比各实验组在相关性维度上的表现差异，判断算法迭代是否提升搜索结果质量。
- **相关性质量监控**：追踪每日搜索结果的平均相关性得分（原始分、lx 分、附加分）及无关率趋势。
- **分流量分析**：区分广告流量与自然流量、不同排序策略下的相关性差异。

**适合回答的典型问题：**
- 实验组 A 与对照组 B 在昨日的搜索相关性均分差异有多大？
- 某地区某排序策略下，搜索无关率在最近一段时间的趋势如何？
- 广告流量与非广告流量的相关性得分是否存在显著差距？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，对应业务大区（如 SG、MY 等），与上游 country 字段对应 |
| `local_date` | date | 数据日期分区，格式 yyyy-MM-dd，表示指标所属自然日 |

### 维度：实验与流量维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，标识用户所属实验桶 |
| `is_ads` | string | 是否为广告流量。取值为 `'true'`/`'false'` 或 `'__ALL__'`（表示全量聚合，不区分广告与否） |
| `is_login` | boolean | 是否为登录用户。当前 ETL 逻辑中仅处理 `user_id > 0` 的登录用户，该字段固定为 `true` |
| `sort_type` | string | 搜索排序策略类型，标识当次请求使用的排序方式 |

### 指标：相关性评分与请求量

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_rel_avg_score` | double | 实验组内所有用户、所有请求的 rel_raw（原始相关性得分）请求级均值的累计求和。**不可直接跨组或跨日 SUM 后除以请求数得到均分，需结合 num_requests 加权计算** |
| `total_rel_avg_lx` | double | 实验组内所有用户、所有请求的 rel_lx（LX 相关性得分）请求级均值的累计求和。使用方式同上 |
| `total_rel_avg_add` | double | 实验组内所有用户、所有请求的 rel_add（附加相关性得分）请求级均值的累计求和。使用方式同上 |
| `total_irrelevance_rate` | double | 实验组内所有用户、所有请求的无关率（rel_lx = 0 的曝光占比）请求级值的累计求和。**不可直接作为最终无关率使用，需除以 num_requests 还原均值** |
| `num_requests` | bigint | 实验组内各维度组合下的总请求数（去重后），用于将上述累计指标还原为均值的分母 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`** 两个分区字段，否则将触发全分区扫描，产生大量不必要的计算开销：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 若需多日分析，建议使用 `local_date BETWEEN ... AND ...` 明确范围。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确使用方式 |
|---|---|---|
| `total_rel_avg_score` | 预聚合的均值累计值，非原始总分 | 跨组/跨日对比时需加权：`SUM(total_rel_avg_score) / SUM(num_requests)` |
| `total_rel_avg_lx` | 同上 | `SUM(total_rel_avg_lx) / SUM(num_requests)` |
| `total_rel_avg_add` | 同上 | `SUM(total_rel_avg_add) / SUM(num_requests)` |
| `total_irrelevance_rate` | 预聚合的无关率累计值，非最终无关率 | `SUM(total_irrelevance_rate) / SUM(num_requests)` |

### is_ads 的 `__ALL__` 值

`is_ads = '__ALL__'` 是 ETL 使用 `GROUPING SETS` 生成的全量聚合行（不区分广告与非广告），与 `'true'`/`'false'` 行存在数据重叠。**对同一 exp_group_id 汇总时切勿与具体取值行混合求和**，应按需选择其中一类过滤：
```sql
-- 分析全量（不区分广告）
WHERE is_ads = '__ALL__'
-- 分析非广告自然流量
WHERE is_ads = 'false'
```

### 时效性说明

- 本表为 **1d 日表**，每日 T+1 调度写入，反映前一自然日数据。
- 每次写入为 `INSERT OVERWRITE`，对应分区数据完整覆盖，无增量追加风险。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供用户与 A/B 实验组的映射关系，过滤条件为分配日志有效（`is_assignment_log = 1`）且在搜索白名单（`is_search_whitelist = 1`） |
| `srdi_mart.dwd_fp_search_base_1d` | 搜索曝光明细宽表，提供每次搜索请求下各商品的相关性原始分（`rel_raw`）、lx 分（`rel_lx`）、附加分（`rel_add`）及广告标识、排序类型等基础字段 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_fp_search_base_1d          dim_sr_data_warehouse_abtest_user_group
        │                                        │
        ▼                                        ▼
  dwd_fp_search (曝光明细过滤去重)        user_exp_mapping (实验组映射)
        │                                        │
        ▼                                        │
search_rel_metrics_by_req (请求级相关性聚合)      │
        │                                        │
        ▼                                        │
search_rel_metrics_by_user (用户级累计)           │
        │                                        │
        └──────────── INNER JOIN ────────────────┘
                           │
                           ▼
      dws_sr_data_warehouse_search_abtest_relevance_metrics_1d
                    (实验组级汇总写入)
```

### 关键步骤

1. **user_exp_mapping（Temporary View）**：从实验组维表中提取当日有效的用户-实验组映射，限定为分配日志有效且搜索白名单用户。

2. **dwd_fp_search（Temporary View）**：从搜索曝光明细表中过滤当日、指定地区、位置在前 40 位（`location <= 39`）、有曝光时间且为登录用户（`user_id > 0`）的记录，按 `user_id + item_id + request_id + is_ads + sort_type` 去重，对相关性各分取 MAX 值。

3. **search_rel_metrics_by_req（Temporary View）**：在请求粒度上，使用 `GROUPING SETS` 对 `is_ads` 维度做两级聚合（区分 is_ads 与全量 `__ALL__`），计算每个请求的相关性均分（`rel_avg_score`、`rel_avg_lx`、`rel_avg_add`）及无关率（`irrelevance_rate`）。

4. **search_rel_metrics_by_user（Temporary View）**：将请求级指标在用户粒度上累加，得到每个用户在各维度组合下的指标累计值及请求数。

5. **INSERT OVERWRITE（最终写入）**：将用户级数据与实验组映射 INNER JOIN，按 `exp_group_id + is_login + sort_type + is_ads` 分组求和，写入目标表对应分区。

### 注意事项

- **单一写入文件**：本表仅由一个 ETL 文件写入，无 multi-writer 风险。
- **INNER JOIN 导致用户过滤**：仅匹配到实验组的用户才会进入最终结果，未命中实验组白名单的用户数据将被丢弃，统计口径为**实验覆盖用户**，非全量搜索用户。
- **GROUPING SETS 产生 `__ALL__` 行**：`is_ads = '__ALL__'` 行与具体 is_ads 行存在数据重叠，查询时须明确选择，防止重复计数。
- **分区覆盖写入**：每次执行为 `INSERT OVERWRITE PARTITION`，会覆盖对应 `grass_region + local_date` 分区的全量数据，重跑安全。
- **参数化地区**：ETL 使用 `${grass_region}` / `${grass_region_without_quote}` / `${local_date}` 等模板参数，每次调度按地区和日期单独执行。

---

*文档生成时间：2026-05-17*