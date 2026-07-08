<!-- ads-workspace-gdoc-sync: gdoc_id=1sP5TPfc7CcP2p-Mmons5arV_7PinxnDw1TZziaPDxLI gdoc_url=https://docs.google.com/document/d/1sP5TPfc7CcP2p-Mmons5arV_7PinxnDw1TZziaPDxLI/edit -->

# srdi_mart.dim_sr_data_warehouse_search_guide_request

**分层**：DIM（维度层）
**主键**：`user_id` + `global_session_id` + `mid`（联合唯一标识一条搜索引导请求记录）
**分区**：`grass_region`（大区）/ `local_date`（本地日期）
**更新频率**：每日全量覆盖写（INSERT OVERWRITE，按分区）
**访问频次**：234 次

---

## 业务描述

本表是搜推数仓中对**搜索引导（Search Guide）请求**的维度宽表，记录用户在搜索各引导场景下的行为快照。

ETL 从 `srdi_mart.dwd_sr_data_warehouse_search` 中筛选 `operation = 'click'` 且有效用户（`user_id > 0`）的点击事件，按用户会话维度聚合，并通过多层 `CASE WHEN` 逻辑将原始页面行为分类为标准化的搜索引导入口类型（`mid`），最终写入本维度表。

**核心业务场景**：

| 场景前缀 | 含义 |
|---|---|
| `sdp_*` | Search Discovery Page（搜索发现页 / 预搜索页）相关引导 |
| `sup_*` | Search Suggest Page（搜索建议页）相关引导 |
| `srp_*` | Search Result Page（搜索结果页）相关引导 |

**适合回答的问题**：
- 用户在各搜索引导入口（算法预填、运营预填、热搜、历史记录、联想词、相关搜索等）的点击分布情况如何？
- 特定用户 / 会话在某天触发了哪些搜索引导请求？
- 各引导类型（`mid`）对应的请求 ID 集合是什么，可用于与下游转化行为关联分析？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 业务大区标识，如 `SG`、`TW` 等，用于数据隔离与路由 |
| `local_date` | date | 事件发生的本地日期，ETL 每日按此分区覆盖写入 |

### 维度：用户与会话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；ETL 已过滤 `user_id > 0`，不含匿名/无效用户 |
| `global_session_id` | string | 全局会话 ID；ETL 已过滤 `IS NOT NULL`，保证每行均有有效会话 |

### 维度：搜索引导分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `mid` | string | 搜索引导入口类型，由 ETL 通过 `page_type`、`page_section`、`target_type`、`input_type`、`prefill_type` 组合映射得出。枚举值见下方说明 |
| `operation` | string | 用户操作类型；当前 ETL 仅保留 `click` 事件，聚合时取 `max(operation)` |

**`mid` 枚举值说明**：

| mid 值 | 含义 |
|---|---|
| `sdp_algo_prefill` | 预搜索页搜索框 - 算法预填词 |
| `sdp_ops_prefill` | 预搜索页搜索框 - 运营配置预填词 |
| `sdp_hint_history` | 预搜索页搜索框或历史记录区 - 联想词 / 历史记录 |
| `sdp_search_suggestion` | 预搜索页 - 热门搜索建议（popular_searches / search_suggestions） |
| `sdp_hot_search` | 预搜索页 - 热搜榜 |
| `sdp_null` | 预搜索页搜索框 - 联想词但 `input_type` 为 NULL（兜底分类） |
| `sup_ymws` | 搜索建议页 - 猜你想搜（next_keyword） |
| `sup_hint_history` | 搜索建议页 - 联想词 / 历史记录 |
| `sup_auto_complete` | 搜索建议页 - 自动补全（hint） |
| `sup_shop_history` | 搜索建议页 - 店铺历史记录 |
| `sup_curated_search` | 搜索建议页 - 精选搜索 |
| `srp_curated_search` | 搜索结果页 - 精选搜索 |
| `srp_related_search` | 搜索结果页 - 相关搜索 |

### 指标：请求 ID 聚合

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_guide_request_id` | string | 同一用户会话 + 引导类型下，所有搜索引导请求 ID 的集合，以逗号拼接（`collect_set` + `concat_ws`），为多值字符串 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全表扫描，影响性能和成本。

```sql
WHERE grass_region = 'SG'
  AND local_date = '2025-01-01'
```

- 若需跨大区查询，应明确列举 `grass_region IN (...)` 而非省略条件。

### 不可直接 SUM / 二次聚合的字段

| 字段 | 风险 | 正确用法 |
|---|---|---|
| `search_guide_request_id` | 该字段为逗号拼接的多值字符串，不可直接计数或 SUM；若需统计请求数，须先 `explode` 或 `split` 展开后再聚合 | `SIZE(SPLIT(search_guide_request_id, ','))` 可估算个数，但建议回溯 DWD 层做精确计算 |
| `operation` | 聚合时取的是 `max(operation)`，当前数据均为 `click`，直接 GROUP BY 或 COUNT 无业务意义 | 仅用于过滤或标记，不建议作为指标计算依据 |

### 时效性说明

- 本表为**每日分区全量覆盖**（INSERT OVERWRITE），数据时效取决于当日 ETL 任务完成时间，通常为 T+1 日可查。
- `local_date` 表示事件本地日期，跨时区分析时需注意与 UTC 时间的换算。
- 本表**不包含**滚动 N 日窗口或 `*_nd`/`*_td` 类预聚合指标，如需多日汇总须在查询层自行跨分区联合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细宽表，提供 `page_type`、`page_section`、`target_type`、`input_type`、`prefill_type`、`search_guide_request_id`、`operation`、`user_id`、`global_session_id` 等原始字段，用于过滤和聚合计算 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search
    │  过滤：local_date、grass_region、page_type in ('pre_search','search_suggest_page','search')
    │         operation = 'click'、user_id > 0
    ▼
Temporary View: dim_search_guide_${grass_region_without_quote}
    │  计算 mid（CASE WHEN 多条件映射）
    │  聚合：collect_set(search_guide_request_id) → concat_ws 拼接
    │        max(operation)
    │  GROUP BY: user_id, global_session_id, mid
    ▼
srdi_mart.dim_sr_data_warehouse_search_guide_request
    │  过滤：global_session_id IS NOT NULL
    │  分区写入：PARTITION(grass_region, local_date)
    ▼  INSERT OVERWRITE（按分区覆盖）
```

### 关键步骤

**Step 1 — 创建临时视图（Spark SQL Statement 1）**

- 数据源：`srdi_mart.dwd_sr_data_warehouse_search`，按 `local_date`、`grass_region` 分区过滤。
- 行级过滤：
  - `page_type IN ('pre_search', 'search_suggest_page', 'search')`
  - `operation = 'click'`
  - `user_id > 0`
- 字段计算：
  - `mid`：通过 13 条 `CASE WHEN` 分支，依据 `page_type`、`page_section[0]`、`target_type`、`input_type`、`prefill_type` 的组合，将原始行为映射为标准化引导类型标签；不满足任何分支的行 `mid` 为 `NULL`（NULL 行在后续 INSERT 中不会被显式过滤，但因 GROUP BY 会作为 NULL 组存在，可按需关注）。
  - `search_guide_request_id`：`concat_ws(',', collect_set(search_guide_request_id))`，对同一粒度下的请求 ID 去重后拼接。
  - `operation`：`max(operation)`，取聚合后最大值（当前场景均为 `click`）。
- 聚合粒度：`(user_id, global_session_id, mid)`。

**Step 2 — INSERT OVERWRITE 写入目标表（Spark SQL Statement 2）**

- 从临时视图读取数据，过滤 `global_session_id IS NOT NULL`。
- 以 `PARTITION(grass_region, local_date)` 静态分区覆盖写入目标表。
- 写入字段：`user_id`、`global_session_id`、`mid`、`search_guide_request_id`、`operation`。

### 注意事项

- **单 writer**：本表仅由 1 个 ETL 文件写入，无 multi-writer 风险，分区数据来源唯一。
- **静态分区覆盖**：INSERT OVERWRITE 按 `(grass_region, local_date)` 静态分区写入，重跑同一分区会完全覆盖历史数据，需注意回刷时的幂等性。
- **`mid` 为 NULL 的数据**：不满足任何 `CASE WHEN` 分支的原始行，聚合后 `mid = NULL`，当前 ETL 未显式过滤此类数据，查询时如需排除可加 `WHERE mid IS NOT NULL`。
- **`search_guide_request_id` 多值字段**：该字段为字符串形式的 ID 集合，下游使用时需展开处理，避免直接用于 JOIN 或计数。

---

*文档生成时间：2026-05-17*