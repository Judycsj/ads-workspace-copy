<!-- ads-workspace-gdoc-sync: gdoc_id=1AwWhRRJnDgePFy9Tbwml_ynsy4PVcbvCyB64vlkbUKw gdoc_url=https://docs.google.com/document/d/1AwWhRRJnDgePFy9Tbwml_ynsy4PVcbvCyB64vlkbUKw/edit -->

# srdi_mart.dws_sr_data_warehouse_fll_diversity_funnel_10m

**分层：** DWS（数据服务层）
**主键：** `regional_date` + `regional_hour` + `timestamp_10m` + `country` + `bundle` + `abt` + `is_ads` + `recall_queue_id` + `card_type` + `stage`
**分区：** `regional_date`（日期分区）、`regional_hour`（小时分区）
**更新频率：** 每小时调度，按小时分区 INSERT OVERWRITE 覆盖写入
**访问频次：** 1074 次

---

## 业务描述

本表面向搜推（SR）全链路（Full-Link，FLL）场景，统计 **推荐漏斗各阶段的 LLM Cluster 多样性指标**，时间粒度为 **10 分钟**。

核心业务场景：
- 监控推荐系统在 Recall → PreRank → Rank → MixRank → Dispatch 各漏斗阶段的内容多样性（LLM Cluster 分布）随时间的变化趋势；
- 支持按 AB 实验分组（`abt`）、是否广告（`is_ads`）、召回队列（`recall_queue_id`）、卡片类型（`card_type`）、推荐入口（`bundle`）等维度拆分，快速定位多样性问题；
- 适用于大促、版本上线等关键节点的实时/近实时多样性巡检与对比分析。

适合回答的问题示例：
- 某 10 分钟窗口内，不同 AB 组在 Rank 阶段的 LLM Cluster 数量差异是多少？
- 广告与非广告 item 在 Dispatch 阶段的 LLM Cluster 密度如何分布？
- 某召回队列在过去一小时内各漏斗阶段的多样性趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据日期（区域本地时间），分区键 |
| `regional_hour` | string | 数据小时（区域本地时间，格式 HH），分区键 |

### 维度：时间与地域

| 字段 | 类型 | 说明 |
|---|---|---|
| `timestamp_10m` | string | 10 分钟粒度时间戳，格式 `yyyy-MM-dd HH:mm`，由请求 unix timestamp 向上取整到 600 秒边界后格式化得到 |
| `country` | string | 国家/地区代码（分区写入时指定），取值如 ID、BR、PH、TH、VN、MY、TW、SG |

### 维度：推荐场景与实验

| 字段 | 类型 | 说明 |
|---|---|---|
| `bundle` | string | 推荐入口，`daily_discover_main` 映射为 `dd`，其余（购物车等）映射为 `cart` |
| `abt` | string | AB 实验分组 ID（各国家对应不同实验号区间），`__ALL__` 表示全量汇总（CUBE 聚合） |
| `is_ads` | string | 是否广告 item，`true` 表示广告（item_type 为 ROI1/TARGET_ROI2/SIMPLE_ROI2），`false` 表示非广告；`__ALL__` 表示不区分（CUBE 聚合） |
| `recall_queue_id` | string | 召回队列 ID，来源于 recall_info.strategies 展开；`__ALL__` 表示全量汇总（CUBE 聚合） |
| `card_type` | string | 卡片类型，取值为 `ITEM`、`VIDEO`、`STREAM`、`OTHER` |
| `stage` | string | 漏斗阶段，取值为 `RECALL`、`PRERANK`、`RANK`、`MIXRANK`、`DISPATCH`，通过各阶段 info 字段是否为 NULL 展开 |

### 指标：LLM Cluster 多样性

| 字段 | 类型 | 说明 |
|---|---|---|
| `unique_llm_cluster_count` | bigint | 在当前分组维度下，去重后的 LLM Cluster（`llm_cluster_v2`）数量，衡量内容多样性绝对量 |
| `unique_llm_cluster_per_req` | double | 每次请求平均携带的唯一 LLM Cluster 数，= `unique_llm_cluster_count / unique_request_cnt`，衡量单请求多样性 |
| `llm_cluster_density` | double | LLM Cluster 密度，= `unique_llm_cluster_count / item_cnt`，衡量 item 维度的 Cluster 覆盖率 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `regional_date` 和 `regional_hour`**，否则将触发全分区扫描，造成严重的计算资源浪费：
  ```sql
  WHERE regional_date = '2025-05-17'
    AND regional_hour = '10'
  ```
- 若需查询某国家数据，建议同时过滤 `country` 字段（写入时已按 country 分区，过滤可加速）。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `unique_llm_cluster_per_req` | 比率型指标，为预聚合除法结果，跨行 SUM 无业务意义，需用分子/分母重新计算 |
| `llm_cluster_density` | 比率型指标，同上，不可跨行累加 |
| `unique_llm_cluster_count` | 去重计数，已在当前维度组合下去重，**跨维度/跨时间窗口 SUM 会导致重复计数**，不可直接累加 |

> ⚠️ 注意 `abt`、`is_ads`、`recall_queue_id` 三个维度使用了 `CUBE` 聚合，值为 `__ALL__` 的行代表该维度的全量汇总。查询时若不过滤 `__ALL__`，会导致数据重复统计。建议明确指定维度值或统一只使用 `__ALL__` 行做汇总分析。

### 时效性说明

- 本表为 **准实时小时表**，每小时调度一次，延迟约为 1 个自然小时。
- `timestamp_10m` 为 10 分钟粒度，一个小时分区内包含最多 6 个时间桶，可用于小时内趋势分析。
- 每次写入为 `INSERT OVERWRITE`，按 `(regional_date, regional_hour, country)` 三级分区覆盖，历史分区数据不会追加，重跑安全。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_rcmd` | 全链路推荐日志原始宽表，提供请求维度信息、AB 实验标签、item 列表及各漏斗阶段详情、LLM Cluster 标签等 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_rcmd
    │  过滤：regional_date/regional_hour/country/bundle/full_link_all=true
    ▼
raw（请求粒度宽表）
    │  lateral view explode：ab_signs × data × stage × recall_queue_id
    ▼
exploded（item × stage × recall_queue_id 行级明细）
    │
    ├──→ uniq_req_pre（CUBE(abt,is_ads,recall_queue_id) 去重请求预聚合）
    │         ▼
    │     uniq_req（请求数 & item 数汇总）
    │
    └──→ uniq_llm_pre（CUBE(abt,is_ads,recall_queue_id) 去重 LLM Cluster 预聚合）
              ▼
          uniq_llm（唯一 LLM Cluster 数汇总）
              │
              └──→ LEFT JOIN uniq_req
                        ▼
              INSERT OVERWRITE 目标表
```

### 关键步骤

1. **Statement 1 — `raw_${region}`（Temporary View）**
   从 ODS 全链路日志中读取指定日期、小时、国家、bundle 的全量采样请求（`full_link_all = true`）。按国家过滤对应的 AB 实验 ID 列表，计算每请求的 item 数量（`item_cnt_per_request`）。

2. **Statement 2 — `exploded_${region}`（Temporary View）**
   对 raw 视图进行四重 lateral view explode：
   - `ab_signs` → 每个 AB 分组一行；
   - `data` → 每个 item 一行；
   - 漏斗 stage 数组 → 每个 item 所经过的阶段各一行（根据各阶段 info 是否为 NULL 构造）；
   - `recall_info.strategies` 的 `queue_id` → 每个召回策略一行。
   同时完成 `is_ads`、`card_type`、`timestamp_10m` 的标准化处理。

3. **Statement 3 — `uniq_req_pre_${region}`（Temporary View）**
   在 exploded 视图上，按 `CUBE(abt, is_ads, recall_queue_id)` 与其余维度 GROUP BY，在 request 粒度去重（保留 `item_cnt_per_request` 和 `request_id`），生成含 `__ALL__` 汇总行的预聚合结果。

4. **Statement 4 — `uniq_req_${region}`（Temporary View）**
   在 uniq_req_pre 基础上汇总得到每个维度组合下的 `item_cnt`（item 总数）和 `unique_request_cnt`（唯一请求数）。

5. **Statement 5 — `uniq_llm_pre_${region}`（Temporary View）**
   与 uniq_req_pre 同维度，在 request × llm_cluster_v2 粒度去重，为后续计算 unique LLM Cluster 数做准备。

6. **Statement 6 — `uniq_llm_${region}`（Temporary View）**
   在 uniq_llm_pre 基础上 COUNT(1) 得到每维度组合的 `unique_llm_cluster_count`。

7. **Statement 7 — INSERT OVERWRITE（目标表写入）**
   将 uniq_llm LEFT JOIN uniq_req，计算比率指标 `unique_llm_cluster_per_req` 和 `llm_cluster_density`，按 `(regional_date, regional_hour, country)` 分区覆盖写入目标表。

### 注意事项

- **单 Writer**：本表为单 ETL 文件写入（`multi_writer = false`），无并发写入风险。
- **参数化区域**：SQL 中使用 `${grass_region}` / `${grass_region_without_quote}` 等运行时参数，实际调度时按国家或区域分批传参，每次写入对应一个 country 分区。
- **CUBE 聚合导致数据膨胀**：`abt`、`is_ads`、`recall_queue_id` 三个维度做了全 CUBE，输出行数为原始组合的 2³=8 倍，查询时必须明确过滤维度值或只取 `__ALL__` 行，避免重复统计。
- **Dispatch stage 判断逻辑**：`DISPATCH` 阶段判断依赖 `d.final_stage = 'DISPATCH'`，而非 dispatch_info 字段是否为 NULL，与其他阶段逻辑略有差异，需注意。
- **LLM Cluster 字段**：使用 `llm_cluster_v2`（来自 `rcmd_unit_info`），非 v1 版本，下游对比历史数据时需确认版本一致性。

---

*文档生成时间：2026-05-17*