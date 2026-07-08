<!-- ads-workspace-gdoc-sync: gdoc_id=1b8sNyHE0t3ojgEAlQNtC1pgzB--ibKpsifdPXK9ahz0 gdoc_url=https://docs.google.com/document/d/1b8sNyHE0t3ojgEAlQNtC1pgzB--ibKpsifdPXK9ahz0/edit -->

# srdi_mart.dwd_sr_data_warehouse_curated_search_clk_imp

**分层：** DWD（明细数据层）
**主键：** `event_id`（单条行为事件唯一标识）
**分区：** `grass_region` / `local_date` / `operation`
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE，按分区）
**访问频次：** 2030 次

---

## 业务描述

本表记录搜索场景下 **Curated Search（精选搜索）** 活动的点击（click）与曝光（impression）明细事件，是搜推数仓中 Curated Search 行为分析的核心 DWD 宽表。

**核心业务场景：**
- 分析 Curated Search 活动模块在搜索结果页（`page_type=search`）及搜索建议页（`page_type=search_suggest_page`）的曝光与点击表现；
- 追踪各运营活动（`activity_id/activity_name`）、各模块（`module_id/module_name`）的用户行为；
- 结合关键词维度（`keyword`、`keyword_category`、`keyword_cluster`）评估精选搜索在不同关键词下的效果；
- 支持按大区（`grass_region`）、日期（`local_date`）、操作类型（`operation`）进行分区查询与汇总。

**适合回答的问题：**
- 某大区某日 Curated Search 各活动/模块的点击量与曝光量分别是多少？
- 哪些关键词的 Curated Search 模块曝光/点击率最高？
- 特定活动（`activity_id`）在各平台（`platform`）的用户行为分布情况如何？
- Curated Search 品牌模块（`is_brand=1`）与非品牌模块的点击量对比？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 ID、MY、TH 等；查询必须指定 |
| `local_date` | date | 本地日期，事件发生日期；查询必须指定 |
| `operation` | string | 行为操作类型，固定取值：`click`（点击）或 `impression`（曝光） |

### 维度：用户与设备

| 字段名 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，来源于流量日志 `userid` 字段 |
| `device_id` | string | 设备 ID，来源于流量日志 `deviceid` 字段 |
| `session_id` | string | 用户会话 ID |
| `platform` | string | 客户端平台，如 iOS、Android、Web 等 |

### 维度：事件与页面

| 字段名 | 类型 | 说明 |
|---|---|---|
| `event_id` | string | 事件唯一标识 ID |
| `log_timestamp` | bigint | 日志记录的原始时间戳（毫秒） |
| `page_type` | string | 页面类型，取值为 `search`（搜索结果页）或 `search_suggest_page`（搜索建议页） |
| `page_section` | array\<string\> | 页面分区信息，数组类型；`search_suggest_page` 场景下 `page_section[0]='search_bar'` |
| `target_type` | string | 目标类型，本表固定为 `curated_search` |
| `location` | bigint | 模块在页面中的位置编号，来源于事件 data 字段中的 `location` 或 `search_FE.location` |
| `user_input` | string | 用户输入的原始文本，来源于 `user_input` 或 `search_FE.user_input` |

### 维度：商店

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |

### 维度：关键词

| 字段名 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 标准化后的搜索关键词（小写、去首尾空格、`-` 替换为空格），来源于 `search_params.keyword` 或 `search_FE.keyword` |
| `keyword_category` | string | 关键词所属一级品类（来源于关键词维表 `dim_sr_data_warehouse_keyword_di` 的 `level1_keyword_category`） |
| `keyword_cluster` | string | 关键词聚类标签（来源于关键词维表 `dim_sr_data_warehouse_keyword_di` 的 `keyword_cluster`） |

### 维度：Curated Search 活动与模块

| 字段名 | 类型 | 说明 |
|---|---|---|
| `activity_id` | bigint | Curated Search 活动 ID，对应 `layout_id` |
| `activity_name` | string | 活动名称 |
| `activity_start_time` | bigint | 活动开始时间戳 |
| `activity_end_time` | bigint | 活动结束时间戳 |
| `activity_category_id` | bigint | 活动所属品类 ID |
| `activity_category` | string | 活动所属品类名称 |
| `module_id` | bigint | 活动下的模块 ID |
| `module_name` | string | 模块名称；`module_schema_id=2`（搜索建议页场景）时，该字段用于匹配关键词 |
| `module_url` | string | 模块跳转 URL（标准化小写） |
| `module_schema_id` | bigint | 模块类型标识；`1/4/5` 为搜索结果页模块，`2` 为搜索建议页模块 |
| `module_description` | string | 模块描述信息 |
| `is_brand` | bigint | 是否为品牌模块，`1` 表示品牌，`0` 表示非品牌 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：表按大区分区，查询时必须显式指定，避免全表扫描；
- **`local_date`**：表按日期分区，查询时必须指定日期或日期范围，避免全量扫描；
- **`operation`**：若仅需点击或曝光数据，应显式过滤 `operation='click'` 或 `operation='impression'`，以减少数据扫描量。

### 不可直接 SUM / 聚合的字段

- **`location`**：位置序号，为排名/位置维度，不具备求和意义，应作为维度使用；
- **`log_timestamp`**、**`activity_start_time`**、**`activity_end_time`**：时间戳字段，仅可用于过滤、排序或计算时间差，不可直接累加；
- **点击率（CTR）**等比率指标**未在本表预计算**，需在查询层由 click 计数除以 impression 计数手动计算，且两者需分别从 `operation='click'` 与 `operation='impression'` 分区读取后再做关联，不可在同一分区直接聚合；
- **`user_id`**、**`device_id`**、**`session_id`**：为去重指标的基础字段，统计 UV/USession 时需使用 `COUNT(DISTINCT ...)`，不可直接 `COUNT` 或 `SUM`。

### 时效性说明

- 本表为**每日 T+1 全量覆盖**，数据反映前一自然日的行为事件；
- 每次写入为 `INSERT OVERWRITE`，按 `(grass_region, local_date, operation)` 三级分区覆盖，当日数据在 ETL 完成前不可用；
- 无实时/准实时流，不支持日内增量查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | 原始点击事件明细，提供 click 行为的用户、设备、页面、事件、关键词等信息 |
| `traffic.shopee_traffic_dwd_impression_hi__reg_s1_live` | 原始曝光事件明细，提供 impression 行为数据；`cs_list` JSON 数组字段经 LATERAL VIEW EXPLODE 展开为多行 |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词维表，提供关键词的一级品类（`level1_keyword_category`）和关键词聚类（`keyword_cluster`）；LEFT JOIN，允许关键词未命中维表 |
| `srdi_mart.dim_sr_data_warehouse_curated_activity_module` | Curated Search 活动模块维表，提供活动、模块的运营配置信息；INNER JOIN，只保留能匹配上活动配置的事件 |

---

## ETL 逻辑摘要

### 数据流

```
traffic.shopee_traffic_dwd_impression_hi__reg_s1_live
    │── LATERAL VIEW EXPLODE(cs_list)
    └──► traffic_cs_explode_{region}（Temporary View）
                                                    ┐
traffic.shopee_traffic_dwd_click_hi__reg_s1_live    ├──► JOIN dim_keyword + JOIN dim_activity_module
                                                    ┘
                        ▼
        INSERT OVERWRITE dwd_sr_data_warehouse_curated_search_clk_imp
        PARTITION (grass_region, local_date, operation)
```

### 关键步骤

**Step 1 — Temporary View：`traffic_cs_explode_{region}`**

- 读取曝光事件表，过滤条件：`page_type='search'` 或（`page_type='search_suggest_page'` 且 `page_section[0]='search_bar'`），且 `target_type='curated_search'`；
- 对 `data.cs_list` JSON 数组字段使用 `LATERAL VIEW OUTER EXPLODE` 展开，每个曝光元素生成独立一行；
- 同时解析两套字段路径：标准路径（`data.layout_id`、`data.url` 等）和前端字段路径（`data.search_FE.*`），用于后续分别匹配不同 `module_schema_id` 的模块；
- 关键词统一做标准化处理：`REPLACE(TRIM(LOWER(...)), '-', ' ')`。

**Step 2 — INSERT OVERWRITE：四路 UNION ALL 写入目标表**

目标分区动态由 `operation` 字段值决定（`click` 或 `impression`），共四个分支：

| 分支 | 数据来源 | page_type | module_schema_id | operation |
|---|---|---|---|---|
| ① | `shopee_traffic_dwd_click_hi` | `search` | 1, 4, 5 | `click` |
| ② | `shopee_traffic_dwd_click_hi` | `search_suggest_page` | 2 | `click` |
| ③ | `traffic_cs_explode`（impression） | `search` | 1, 4, 5 | `impression` |
| ④ | `traffic_cs_explode`（impression） | `search_suggest_page` | 2 | `impression` |

- 分支①③：使用标准路径字段匹配，JOIN 条件包含 `layout_id=activity_id`、`url=module_url`、`ARRAY_CONTAINS(activity_keyword_list, keyword)`、`position=module_position`；过滤 `activity_status IN (1,2)`；
- 分支②④：使用 `search_FE.*` 路径字段匹配，JOIN 条件为 `fe_layout_id=activity_id`、`fe_url=module_url`、`fe_keyword=module_name`；仅限 `module_schema_id=2`；
- 关键词维表（`dim_sr_data_warehouse_keyword_di`）均为 LEFT JOIN，未匹配时 `keyword_category`、`keyword_cluster` 为 NULL；
- 活动模块维表（`dim_sr_data_warehouse_curated_activity_module`）均为 INNER JOIN，未匹配的事件行将被过滤丢弃。

### 注意事项

- **Single Writer**：本表仅有一个 ETL 文件写入，不存在多 Writer 并发冲突风险；
- **分区覆盖风险**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date, operation)` 动态分区写入，重跑时会覆盖对应 `(grass_region, local_date, operation)` 组合的全部数据，需确认幂等性；
- **INNER JOIN 过滤效应**：与活动模块维表的 INNER JOIN 会过滤掉未在维表中配置的 Curated Search 事件，下游统计数据以维表配置为准，口径需对齐；
- **`cs_list` 展开**：曝光事件的 `cs_list` 使用 `LATERAL VIEW OUTER EXPLODE`，若 `cs_list` 为 NULL 或空数组，`elems` 为 NULL，此时使用顶层 `data` 字段兜底解析；
- **关键词标准化**：关键词全链路均做 `LOWER + TRIM + REPLACE('-',' ')` 处理，下游使用关键词过滤时需保持一致的标准化逻辑；
- **`position` 空值处理**：JOIN 条件中使用 `COALESCE(INT(position), 'null') = COALESCE(dimc.module_position, 'null')` 处理两侧均为 NULL 的情况，避免 NULL≠NULL 导致匹配失败。

---

*文档生成时间：2026-05-17*