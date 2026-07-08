<!-- ads-workspace-gdoc-sync: gdoc_id=15mMNl4mJh9v9qJjQce_u1IFM_4lQzfH30xGPcQoQ-ik gdoc_url=https://docs.google.com/document/d/15mMNl4mJh9v9qJjQce_u1IFM_4lQzfH30xGPcQoQ-ik/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_llm_rewrite_1d

**分层：** dws_search
**主键：** experiment_id + exp_group_id + grass_region + local_date
**分区：** grass_region（站点区域）/ local_date（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 939 次

---

## 业务描述

本表为搜索 LLM 改写（llm rewrite / llmsim）功能的 A/B 实验日粒度汇总宽表，固定追踪实验 ID `100655`，按实验分组（`exp_group_id`）聚合各类搜索行为与结果指标。

**核心业务场景：**

1. **LLM 改写列表页效果评估**：统计命中 LLM 改写关键词后的搜索 session 数、曝光、点击、成单、GMV 及广告收入，衡量改写后列表页的整体表现。
2. **LLM 改写入口流量分析**：从 `entrance_keyword_type = 'llmsim'` 视角统计曝光、点击、成单、GMV，评估用户通过改写入口进入列表后的转化效果。
3. **LLM Related Search（相关搜索）模块效果**：统计 Related Search 模块的曝光 PV/UV、点击 PV/UV 及去重 query/session 量，评估推荐关键词对用户搜索行为的引导效果。
4. **A/B 实验分组对比**：所有指标均按实验分组下钻，支持实验组与对照组的横向对比。

**适合回答的问题举例：**
- 实验组 vs 对照组，LLM 改写后搜索 UV、点击率、GMV 有何差异？
- LLM Related Search 模块的曝光 UV 和点击 UV 趋势如何？
- 改写后无召回（no-recall）搜索量占比是多少？
- LLM 入口带来的广告收入与自然 GMV 各是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 `MY`、`TH`、`ID` 等，写入时通过 PARTITION 参数注入 |
| `local_date` | date | 业务本地日期（yyyy-MM-dd），写入时通过 PARTITION 参数注入 |

---

### 维度：实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID，本表固定为 `100655`（LLM 改写实验） |
| `exp_group_id` | bigint | 实验分组 ID，对应实验组或对照组，来源于 `dim_sr_data_warehouse_abtest_user_group` |

---

### 指标：LLM 改写列表页（List Page）核心指标

> 口径：用户搜索关键词命中 LLM 改写（BE 日志 `is_nls_consult = 'true'`），且该 session 存在页面浏览或无召回曝光记录（`contains_view_cnt = 1`）时，视为一次 LLM List 搜索。

| 字段 | 类型 | 说明 |
|---|---|---|
| `llm_list_search_uu` | bigint | LLM 改写列表页搜索 UV（按 user_id 去重，llm_list > 0 的用户数） |
| `llm_list_search_volume` | bigint | LLM 改写列表页搜索量（按 user_id + keyword 去重的 session 数） |
| `llm_list_success_volume` | bigint | LLM 改写列表页有效点击搜索量（session 内有点击行为的 user+keyword 去重数） |
| `llm_list_norecall_volume` | bigint | LLM 改写列表页无召回搜索量（列表页出现无召回模块的 user+keyword 去重数） |
| `llm_list_imp_cnt` | bigint | LLM 改写列表页商品/视频/直播总曝光次数（PV） |
| `llm_list_click_cnt` | bigint | LLM 改写列表页商品/视频/直播总点击次数（PV） |
| `llm_list_order_cnt` | double | LLM 改写列表页成单数（PV 累加，不可直接跨分组 SUM 比较比率） |
| `llm_list_gmv` | double | LLM 改写列表页成交 GMV（美元，place_order_gmv 汇总） |
| `llm_list_ads_revenue` | double | LLM 改写列表页广告消耗金额（美元，expenditure_amt_usd 汇总） |
| `llm_list_query` | bigint | LLM 改写列表页搜索词去重数（keyword 维度去重） |

---

### 指标：LLM 改写入口（Entrance）指标

> 口径：`entrance_keyword_type = 'llmsim'` 且 `target_type IN ('item','video','livestream')` 的行为，不限制是否命中 BE 日志改写列表。

| 字段 | 类型 | 说明 |
|---|---|---|
| `llm_search_volume` | double | LLM 改写入口触发搜索量（Related Search 模块有点击的 user+keyword 去重数） |
| `llm_success_volume` | bigint | LLM 改写入口有点击搜索量（entrance_keyword_type=llmsim 且有点击行为的 user+keyword 去重数） |
| `llm_imp_cnt` | double | LLM 改写入口商品/视频/直播曝光次数（PV，entrance_keyword_type=llmsim） |
| `llm_clk_cnt` | bigint | LLM 改写入口商品/视频/直播点击次数（PV，entrance_keyword_type=llmsim） |
| `llm_order_cnt` | double | LLM 改写入口成单数（entrance_keyword_type=llmsim 对应的 order） |
| `llm_gmv` | double | LLM 改写入口成交 GMV（美元，entrance_keyword_type=llmsim 对应的 GMV） |
| `llm_ads_revenue` | double | LLM 改写入口广告消耗（美元，曝光 request_id + item_id 与广告日志关联后的消耗） |

---

### 指标：LLM Related Search 模块指标

> 口径：`module_keyword_type = 'llmsim'` 且 `target_type = 'related_search'` 的模块行为，需在存在页面浏览的 session 中（`contains_view_cnt = 1`）。

| 字段 | 类型 | 说明 |
|---|---|---|
| `llm_rs_search_volume` | bigint | Related Search 模块曝光搜索量（有 SRP 页面浏览的 user+keyword 去重数） |
| `llm_rs_search_uv` | bigint | Related Search 模块曝光搜索 UV（user_id 去重） |
| `llm_rs_imp_pv` | bigint | Related Search 模块曝光 PV（`llm_rs_imp_cnt`，模块曝光次数累加） |
| `llm_rs_clk_pv` | bigint | Related Search 模块点击 PV（`llm_rs_clk_cnt`，模块点击次数累加） |
| `llm_rs_imp_uv` | bigint | Related Search 模块曝光 UV（有模块曝光的 user_id 去重数） |
| `llm_rs_clk_uv` | bigint | Related Search 模块点击 UV（有模块点击的 user_id 去重数） |
| `llm_rs_imp_volume` | bigint | Related Search 模块曝光搜索量（有曝光的 user+keyword 去重数） |
| `llm_rs_clk_volume` | bigint | Related Search 模块点击搜索量（有点击的 user+keyword 去重数） |
| `llm_rs_query_cnt` | bigint | Related Search 模块曝光搜索词去重数（keyword 维度去重，有曝光） |

---

## 查询使用须知

### 必须包含的过滤条件

```sql
WHERE grass_region = 'XX'   -- 必须指定站点，否则跨站混算
  AND local_date = 'YYYY-MM-DD'  -- 必须指定日期分区
```

- `grass_region` 和 `local_date` 均为分区字段，**查询时必须同时指定**，否则将触发全表扫描，严重影响性能。
- 如需多日汇总，使用 `local_date BETWEEN '...' AND '...'` 或 `local_date IN (...)` 显式枚举。

### 不可直接 SUM 的字段

以下字段属于**去重计数（COUNT DISTINCT）**衍生指标，跨行直接 SUM 会导致重复计算，**不可跨分组或跨日期直接累加**：

| 字段 | 原因 |
|---|---|
| `llm_list_search_uu` | user_id 去重数，跨日 SUM 存在同一用户重复计数 |
| `llm_list_search_volume` | (user_id, keyword) 去重数 |
| `llm_list_success_volume` | (user_id, keyword) 去重数 |
| `llm_list_norecall_volume` | (user_id, keyword) 去重数 |
| `llm_list_query` | keyword 去重数 |
| `llm_search_volume` | (user_id, keyword) 去重数 |
| `llm_success_volume` | (user_id, keyword) 去重数 |
| `llm_rs_search_volume` | (user_id, keyword) 去重数 |
| `llm_rs_search_uv` | user_id 去重数 |
| `llm_rs_imp_uv` | user_id 去重数 |
| `llm_rs_clk_uv` | user_id 去重数 |
| `llm_rs_imp_volume` | (user_id, keyword) 去重数 |
| `llm_rs_clk_volume` | (user_id, keyword) 去重数 |
| `llm_rs_query_cnt` | keyword 去重数 |

以下字段含浮点累加逻辑（部分来自 COALESCE 补零），跨分组计算比率时需以 SUM 分子/SUM 分母的形式计算，**不可直接对比均值字段**：

| 字段 | 原因 |
|---|---|
| `llm_list_order_cnt` | double 类型，含精度问题，应作为分子参与比率计算 |
| `llm_order_cnt` | 同上 |
| `llm_imp_cnt` | double 类型 |
| `llm_search_volume` | double 类型 |

### 时效性说明

- 本表为 **`_1d` 日粒度**表，每日 T+1 调度产出，数据反映前一自然日（本地时间）全天行为。
- 广告数据来源使用 `tz_type = 'local'` 的本地时区口径，与搜索行为数据时区保持一致。
- 本表不提供实时/准实时数据，历史分区一旦写入即为全量覆盖，不累积追加。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取实验 100655 的用户-分组映射，作为 A/B 实验圈人条件 |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细（曝光/点击/成单/GMV），提供列表页及入口维度的核心指标原始数据 |
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 搜索后端日志，通过 `is_nls_consult = 'true'` 标记命中 LLM 改写的关键词列表 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告效果明细，提供广告消耗金额（`expenditure_amt_usd`），通过 request_id + item_id 与曝光日志关联区分 LLM 改写曝光内的广告消耗 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──────────────────────────────────────┐
                                                                               ↓
dwd_sr_data_warehouse_search (impression)  →  dwd_impression                  │
dwd_advertise_performance_di__reg_s0_live  →  ads_performance                 │
dwd_sr_data_warehouse_search_be_log        →  be_log_llm_list                 │
dwd_sr_data_warehouse_search (all ops)     →  dwd_raw_data                    │
                                                 ↓                            │
                                            dws_srp（用户+关键词级聚合）        │
                                                 ↓                            │
                                            dws_srp_with_llm（关联 BE 日志+广告）│
                                                 ↓                            │
                                            dws_srp_result（INNER JOIN 实验圈人）┘
                                                 ↓
                            INSERT OVERWRITE → dws_sr_data_warehouse_search_abtest_llm_rewrite_1d
```

### 关键步骤

| 步骤 | 临时视图 | 说明 |
|---|---|---|
| Step 1 | `user_exp_mapping` | 从实验用户分组维表中筛选实验 100655、当日已分配（`is_assignment_log=1`）的用户，获取 `user_id → exp_group_id` 映射 |
| Step 2 | `dwd_impression` | 从搜索明细中提取 `entrance_keyword_type = 'llmsim'` 且为 impression 的 `(item_id, request_id)` 去重集合，用于后续广告关联 |
| Step 3 | `ads_performance` | 关联广告消耗日志与 LLM 曝光记录，按用户+关键词汇总总广告消耗及 LLM 曝光内广告消耗 |
| Step 4 | `be_log_llm_list` | 从 BE 日志中提取 `is_nls_consult = 'true'` 的关键词集合，标记命中 LLM 改写列表的词 |
| Step 5 | `dwd_raw_data` | 从搜索明细汇总各用户+关键词+类型维度的 view/impression/click/order/GMV 指标，限定 global_search / search_in_pdp / search_prefill 页面且排除子页面（`page_section IS NULL`） |
| Step 6 | `dws_srp` | 在 dwd_raw_data 基础上按 user+keyword 聚合，区分 Related Search 模块指标、列表页整体指标、LLM 入口指标，并生成 `contains_view_cnt` 标记（是否存在有效 SRP 浏览） |
| Step 7 | `dws_srp_with_llm` | FULL OUTER JOIN 三路数据（SRP 行为 + BE 改写词列表 + 广告），整合 LLM 列表页标记及广告收入，生成用户+关键词级完整宽表 |
| Step 8 | `dws_srp_result` | INNER JOIN 实验用户圈人，按 `experiment_id + exp_group_id` 分组聚合所有去重计数及 PV 指标，固定写入 `experiment_id = 100655` |
| Step 9 | INSERT OVERWRITE | 按 `grass_region` + `local_date` 分区全量覆盖写入目标表 |

### 注意事项

1. **单 writer，分区覆盖写入**：本表为单文件 ETL（`multi_writer = false`），每次调度对指定 `grass_region` + `local_date` 分区执行 `INSERT OVERWRITE`，同分区重跑安全，不同站点/日期分区相互独立。
2. **实验 ID 硬编码**：`experiment_id` 在 ETL 中固定写入 `100655`，如需扩展至其他实验，须修改 ETL 逻辑，不可复用本表查询其他实验。
3. **FULL OUTER JOIN 带来的 NULL 处理**：`dws_srp_with_llm` 使用 FULL OUTER JOIN 合并 SRP 行为、BE 改写词和广告数据，user_id 和 keyword 均经过 `COALESCE` 兜底；下游 INNER JOIN 实验圈人时，无法匹配实验用户的记录会被过滤，不影响最终数据完整性。
4. **广告关联口径**：广告消耗通过 `raw_request_id + item_id` 与 LLM 曝光 impression 关联，仅统计 Global Search（`entrance = 1`）渠道，本地时区（`tz_type = 'local'`）口径。
5. **`llm_imp_cnt` 和 `llm_search_volume` 为 double 类型**：由于中间聚合逻辑含 SUM 浮点运算，DataMap 中记录为 double，使用时注意精度，避免直接用于整数比较。
6. **`page_section IS NULL` 过滤**：搜索行为数据严格限定主搜索页面（排除子板块），与常规搜索漏斗口径保持一致。

---

*文档生成时间：2026-05-17*