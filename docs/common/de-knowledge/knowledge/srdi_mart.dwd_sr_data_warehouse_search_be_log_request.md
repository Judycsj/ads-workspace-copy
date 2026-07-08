<!-- ads-workspace-gdoc-sync: gdoc_id=1m7KvaLgNiHlxK9MWOUnqCYpyTRxY3Y3vqzCuaVXuWP8 gdoc_url=https://docs.google.com/document/d/1m7KvaLgNiHlxK9MWOUnqCYpyTRxY3Y3vqzCuaVXuWP8/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_be_log_request

**分层：** DWD（数据明细层）
**主键：** `request_id`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（按 `local_hour` / `regional_hour` 分区写入）
**引用频次 / 访问频次：** 154

---

## 业务描述

本表记录搜索后端（Search Backend）日志中**请求级别**的明细数据，每行对应一次去重后的搜索请求快照。核心业务场景包括：

- **搜索请求追踪**：以 `request_id` 为粒度，记录每次搜索请求的基础属性。
- **实时奖励候选集分析**：通过 `realtime_reward_item_ids` 字段，追踪参与实时奖励机制的商品 ID 集合，支持奖励策略效果评估。
- **未曝光商品分析**：通过 `unexposed_item_ids` 字段，识别进入排序但未最终曝光的商品，辅助漏斗分析与覆盖率评估。
- **查询翻译质量监控**：通过 `query_translation` 字段，支持对搜索词翻译结果的审计与质量分析。
- **设备维度分析**：支持按 `device_label` 拆分不同设备类型的搜索行为差异。

适合回答的典型问题：
- 某区域、某小时内搜索请求量是多少？
- 某次请求命中了哪些实时奖励商品？
- 进入排序但未曝光的商品分布如何？
- 不同设备类型的搜索请求占比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 `ID`、`TH` 等），用于物理分区隔离，ETL 按参数化 `${grass_region}` 写入 |
| `local_date` | date | 请求发生的本地日期（按服务端本地时区） |
| `local_hour` | int | 请求发生的本地小时（0–23，按服务端本地时区） |
| `regional_date` | date | 请求发生的区域日期（按业务区域时区，与 `local_date` 可能不同） |
| `regional_hour` | int | 请求发生的区域小时（0–23，按业务区域时区） |

### 维度：请求基础信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 搜索请求唯一标识，作为本表主键；ETL 通过 `rn = 1` 过滤保证同一 `request_id` 仅保留一条记录 |
| `device_label` | string | 发起请求的设备类型标签（如 PC、APP 等），来源于上游日志 |
| `query_translation` | string | 搜索词的翻译结果，用于支持多语言搜索场景的查询分析 |

### 指标：商品 ID 集合

| 字段 | 类型 | 说明 |
|---|---|---|
| `realtime_reward_item_ids` | array\<bigint\> | 本次请求中参与实时奖励机制的商品 ID 列表；为数组类型，不可直接聚合，需展开（EXPLODE）后使用 |
| `unexposed_item_ids` | array\<bigint\> | 本次请求中进入排序但最终未曝光的商品 ID 列表；为数组类型，不可直接聚合，需展开（EXPLODE）后使用 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须指定 `grass_region`**，否则将触发全表扫描，扫描成本极高：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-05-01'
  ```
- 建议同时限定 `local_hour` 或 `regional_hour`，减少小时分区扫描范围。
- `local_date` 与 `regional_date` 因时区差异可能不同，需根据业务口径选择对应的日期分区字段，避免混用。

### 不可直接 SUM / 聚合的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `realtime_reward_item_ids` | 数组类型，直接聚合无意义 | 使用 `EXPLODE` 展开后统计商品频次或 UV |
| `unexposed_item_ids` | 数组类型，直接聚合无意义 | 使用 `EXPLODE` 展开后统计未曝光商品分布 |

### 时效性说明

- 本表为**小时级分区表**，数据延迟通常在小时量级，不适合实时场景。
- ETL 使用 `INSERT OVERWRITE` 按分区覆盖写入，同一分区数据可被重跑覆盖，查询近期分区时需注意数据是否已就绪。
- 历史数据以 `grass_region + local_date + local_hour`（或 `regional_date + regional_hour`）为分区边界，跨天汇总时请显式枚举日期范围。

---

## 数据来源

| 上游表 / 视图 | 用途 |
|---|---|
| `search_be_log_ranked`（临时视图 / 中间层） | 提供搜索后端日志的排名去重结果，ETL 通过 `rn = 1` 取每个 `request_id` 的首条记录，作为本表的直接数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
search_be_log_ranked（上游排名去重中间层）
    │
    │ 过滤：grass_region IN (${grass_region}) AND rn = 1
    ▼
srdi_mart.dwd_sr_data_warehouse_search_be_log_request
    （INSERT OVERWRITE，按 grass_region / local_date / local_hour / regional_date / regional_hour 分区覆盖）
```

### 关键步骤

1. **分区参数注入**：ETL 通过参数变量 `${grass_region}` 动态指定目标分区，支持按大区独立调度运行。
2. **去重过滤**：从 `search_be_log_ranked` 中筛选 `rn = 1` 的记录，确保同一 `request_id` 在同一分区内唯一，消除上游日志重复。
3. **区域过滤**：`WHERE grass_region IN (${grass_region})` 限制仅处理当前调度大区的数据，避免跨区混入。
4. **分区覆盖写入**：使用 `INSERT OVERWRITE TABLE ... PARTITION (grass_region = ${grass_region}, local_date, local_hour, regional_date, regional_hour)` 动态分区写入，已有分区数据将被全量替换。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 并发冲突风险。
- **`INSERT OVERWRITE` 幂等性**：分区粒度覆盖写入，ETL 重跑安全，但需确保上游 `search_be_log_ranked` 数据已完整产出，否则可能以空数据覆盖历史分区。
- **动态分区数量**：`local_date`、`local_hour`、`regional_date`、`regional_hour` 均为动态分区，单次调度写入分区数量取决于上游数据分布，若跨日期数据混入需关注分区膨胀问题。
- **上游依赖**：`search_be_log_ranked` 为中间视图，其排名逻辑（`rn` 列的生成规则）决定去重语义，若上游逻辑变更将直接影响本表数据口径。

---

*文档生成时间：2026-05-17*