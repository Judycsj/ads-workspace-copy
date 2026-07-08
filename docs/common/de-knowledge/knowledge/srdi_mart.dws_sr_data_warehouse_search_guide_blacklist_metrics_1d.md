<!-- ads-workspace-gdoc-sync: gdoc_id=1dWWqvMyAczdqAAS_0SmwMLHRfKpW4GUohjvYw1aooCE gdoc_url=https://docs.google.com/document/d/1dWWqvMyAczdqAAS_0SmwMLHRfKpW4GUohjvYw1aooCE/edit -->

# srdi_mart.dws_sr_data_warehouse_search_guide_blacklist_metrics_1d

**分层：** dws_search
**主键：** blacklist_word, filtered_keyword, reason, queue, filter_name, rule_type, grass_region, local_date
**分区：** grass_region, local_date
**更新频率：** 每日（T+1 覆盖写入）
**引用频次 / 访问频次：** 44

---

## 业务描述

本表汇总**搜索导购后端（Shopping Guide BE）黑名单过滤**的每日拦截指标，记录在各大区、各日期下，不同黑名单规则对用户搜索关键词的拦截情况。

**核心业务场景：**
- 监控 `AdminBlacklistFilter` 等黑名单过滤器对搜索词的每日拦截量；
- 按过滤器名称（`filter_name`）、规则类型（`rule_type`）、拦截原因（`reason`）多维度分析黑名单策略效果；
- 排查特定黑名单词（`blacklist_word`）或被过滤关键词（`filtered_keyword`）的命中频次，辅助规则运营和策略调整。

**适合回答的问题：**
- 某大区昨日哪些黑名单词拦截次数最多？
- 特定过滤器（`filter_name`）在某日期的总拦截量是多少？
- 各规则类型（`rule_type`）的拦截分布情况如何？
- 某关键词被哪些黑名单规则拦截？拦截原因是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY 等），用于多地区数据隔离 |
| `local_date` | date | 本地业务日期，对应数据统计日期（格式 yyyy-MM-dd） |

### 维度：黑名单规则与过滤信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `blacklist_word` | string | 命中的黑名单词，来源于日志 `extra_info.blacklist_word` |
| `filtered_keyword` | string | 被过滤的用户搜索关键词，来源于日志 `keyword` 字段 |
| `filter_name` | string | 触发拦截的过滤器名称，来源于日志 `filter_name` 字段 |
| `rule_type` | string | 黑名单规则类型，来源于日志 `rule_type` 字段 |
| `reason` | string | 拦截原因说明，来源于日志 `reason` 字段 |
| `queue` | string | 搜索请求所属队列标识，来源于日志 `queue` 字段 |

### 指标：拦截量统计

| 字段 | 类型 | 说明 |
|---|---|---|
| `intercept_cnt` | bigint | 在该维度组合下的拦截次数，对应原始日志中被 EXPLODE 展开后的记录数 COUNT(1) |

---

## 查询使用须知

1. **必须指定分区过滤条件**：查询时务必同时指定 `grass_region` 和 `local_date`，避免全表扫描导致性能问题及超量计费。
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2024-01-01'
   ```

2. **`intercept_cnt` 可以直接 SUM 聚合**：该字段为各维度组合的计数，在同一分区内按业务维度聚合时可直接相加；跨日期或跨大区汇总时需确认业务口径。

3. **不可随意跨分区 SUM 去重**：`blacklist_word`、`filtered_keyword` 等维度字段在不同日期/大区分区下可能重复出现，跨分区汇总时注意是否需要去重或按需聚合。

4. **时效性说明**：本表为 **1d（每日）** 粒度表，以 `INSERT OVERWRITE` 方式按分区写入，数据通常在 T+1 完成更新，不反映当日实时数据。

5. **数据覆盖范围**：原始日志通过时区转换（`date_timezone_convert`）将各大区时区对齐至 `local_date`，统计口径为该大区本地日期对应的完整一天。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `search_data.shopping_guide_funnel_log_1h_raw` | 搜索导购漏斗原始日志（小时粒度），提供 `AdminBlacklistFilter` 黑名单过滤的 JSON 明细事件，经时区转换和日期过滤后作为主要数据源 |

---

## ETL 逻辑摘要

### 数据流

```
search_data.shopping_guide_funnel_log_1h_raw
    │
    │  按 grass_region + regional_date 范围过滤，时区转换对齐 local_date
    │  解析 message JSON，提取 AdminBlacklistFilter 数组
    ▼
Temporary View: search_guide_be_log_${grass_region_without_quote}
    │
    │  LATERAL VIEW EXPLODE 展开黑名单过滤数组每条记录
    │  解析 detail JSON 提取各维度字段
    │  GROUP BY 维度聚合，COUNT(1) 得到 intercept_cnt
    ▼
srdi_mart.dws_sr_data_warehouse_search_guide_blacklist_metrics_1d
（PARTITION: grass_region + local_date）
```

### 关键步骤

1. **Statement 1 — 创建 Temporary View**
   - 从 `search_data.shopping_guide_funnel_log_1h_raw` 读取原始日志；
   - 过滤条件：`grass_region = ${grass_region}`，`regional_date BETWEEN ${local_date} AND date_add(${local_date}, 1)`，并通过 `date_timezone_convert` 将时区转换后的日期精确匹配 `${local_date}`；
   - 使用 `FROM_JSON(GET_JSON_OBJECT(message, '$.filtered_keywords.AdminBlacklistFilter'), 'ARRAY<STRING>')` 将 message 中的黑名单过滤数组解析为 `admin_blacklist_filter` 列，每个元素为一条过滤详情 JSON 字符串；
   - 结果存入临时视图 `search_guide_be_log_${grass_region_without_quote}`。

2. **Statement 2 — INSERT OVERWRITE 写入目标表**
   - 对临时视图执行 `LATERAL VIEW EXPLODE(admin_blacklist_filter) AS detail`，将数组展开为逐行记录；
   - 分别用 `GET_JSON_OBJECT` 从 `detail` 中提取 `blacklist_word`、`filtered_keyword`（keyword）、`reason`、`queue`、`filter_name`、`rule_type` 六个维度字段；
   - 按上述六个字段 `GROUP BY`，`COUNT(1)` 统计各组合的拦截次数 `intercept_cnt`；
   - 以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 方式写入目标表，实现幂等覆盖。

### 注意事项

- **单一 Writer**：本表仅有 1 个 ETL 文件写入，无多 Writer 并发场景，分区写入风险较低。
- **时区转换逻辑**：原始表 `regional_date` 为各大区本地时间存储，ETL 中使用 `date_timezone_convert` 转换后再匹配 `local_date`，不同大区时区差异由该函数处理，调试时需注意大区参数是否正确传入。
- **日期范围查询**：原始日志过滤使用 `BETWEEN local_date AND date_add(local_date, 1)` 的半开区间扩展范围，以覆盖可能的跨天日志，再通过时区转换精确过滤，避免数据遗漏或重复。
- **JSON 解析空值**：若 `message` 中 `AdminBlacklistFilter` 字段缺失或为空数组，`FROM_JSON` 返回空数组，`EXPLODE` 不产生任何行，不会造成脏数据写入。
- **参数化运行**：SQL 中 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 均为运行时参数，每次调度需正确注入，尤其注意 `grass_region` 与 `grass_region_without_quote` 的引号区别（前者用于 WHERE 条件比较，后者用于视图命名）。

---

*文档生成时间：2026-05-17*