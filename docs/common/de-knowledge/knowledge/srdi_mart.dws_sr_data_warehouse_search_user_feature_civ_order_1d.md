<!-- ads-workspace-gdoc-sync: gdoc_id=1Gwv9OqPrCzOXOSPoYbRU4KXvZGGzVwzNr2W2M2wLiUY gdoc_url=https://docs.google.com/document/d/1Gwv9OqPrCzOXOSPoYbRU4KXvZGGzVwzNr2W2M2wLiUY/edit -->

# srdi_mart.dws_sr_data_warehouse_search_user_feature_civ_order_1d

**分层：** dws_search（数据服务层 - 搜索域）
**主键：** `user_id` + `feature_detail` + `is_ads` + `grass_region` + `local_date`
**分区：** `grass_region`（站点/大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1，覆盖写入）
**访问频次：** 125 次

---

## 业务描述

本表为搜索域用户维度特征转化漏斗汇总宽表，以 **用户 × 搜索特征（feature_detail）× 是否广告（is_ads）** 为统计粒度，记录用户在指定日期内各搜索功能入口（feature）的完整行为链路数据，涵盖曝光、点击、详情页浏览（PPV）、搜索结果页浏览（SRP PV）及下单金额/数量等核心电商指标。

**核心业务场景：**
- 评估各搜索功能入口（feature）对用户购买行为的贡献与转化效率
- 对比广告（is_ads=true）与自然结果（is_ads=false）在各 feature 下的漏斗表现
- 分析不同 scenario_tags 下用户行为差异（如全局搜索 vs 图片搜索 vs PDP 内搜索等）
- 为搜索推荐算法特征工程提供用户级别的行为聚合特征

**适合回答的问题：**
- 某站点某日，某用户在某搜索入口的曝光 → 点击 → 下单转化率如何？
- 广告结果与自然结果在不同搜索特征下的 GMV 贡献差异是什么？
- 指定 feature_group 下，各 feature_detail 带来的下单金额排名？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `ID`、`MY`、`TH` 等，每次查询必须指定 |
| `local_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`，每次查询必须指定 |

### 维度：用户与搜索特征标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识 |
| `feature_detail` | string | 搜索特征细粒度标识，与平台行为日志中的 `feature_detail` 对齐，为分组 key |
| `feature` | string | 特征映射名称，由特征列表维表（feature_list）映射得到，对应 `mapping_detail` |
| `feature_group` | string | 特征分组，由特征列表维表映射得到，对应 `mapping_general`，粗粒度分类 |
| `is_ads` | string | 是否广告结果；`'true'` 表示广告，`'false'` 表示自然结果，`'__ALL__'` 表示全量汇总（含广告+自然，由 GROUPING SETS 生成） |
| `scenario_tags` | array\<string\> | 该 feature_detail 对应的场景标签列表（已过滤掉以 `'Page '` 开头的标签），来源于特征场景标签映射维表，取最近一条记录 |

### 指标：搜索行为漏斗指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（impression），统计 operation='impression' 的操作次数累计，NULL 补 0 |
| `clk_cnt` | bigint | 点击次数（click），统计 operation='click' 的操作次数累计，NULL 补 0 |
| `ppv_cnt` | bigint | 商品详情页浏览次数（PPV），统计 operation='ppv' 的操作次数累计，包含多来源归因（source1、source2），NULL 补 0 |
| `srp_pv` | bigint | 搜索结果页（SRP）浏览次数，统计 operation='view' 且 page_type 在 `global_search`、`search_in_pdp`、`search_prefill`、`image_search`、`shopee_mart_search` 范围内的操作次数，NULL 补 0 |
| `place_order_cnt` | double | 下单笔数，统计 operation='order' 的操作次数累计，包含多来源归因，NULL 补 0 |
| `place_gmv` | double | 下单 GMV（美元/标准货币），统计 operation='order' 的 `place_order_gmv` 字段累计，NULL 补 0 |
| `place_gmv_usd` | double | 下单 GMV（本地货币），统计 operation='order' 的 `place_order_gmv_local` 字段累计，NULL 补 0 |

> **注意：** `place_gmv` 与 `place_gmv_usd` 字段命名与实际含义需结合 ETL 确认：`place_gmv` 对应 `place_order_gmv`（跨币种标准化），`place_gmv_usd` 对应 `place_order_gmv_local`（本地货币）。

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能及费用。
- **`local_date`**：必须指定，本表为每日快照，建议精确到具体日期；若需分析多日趋势，请显式枚举或使用 `BETWEEN`。

```sql
-- 推荐写法
WHERE grass_region = 'ID'
  AND local_date = '2024-01-15'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt`、`clk_cnt`、`ppv_cnt`、`srp_pv`、`place_order_cnt`、`place_gmv`、`place_gmv_usd` | 当 `is_ads = '__ALL__'` 时为广告+自然的汇总行，若同时保留 `is_ads IN ('true', 'false', '__ALL__')` 进行 SUM，会导致**重复计数**。请在聚合前过滤 `is_ads != '__ALL__'`（取明细）或仅使用 `is_ads = '__ALL__'`（取汇总）。 |
| `scenario_tags` | array 类型，不可直接 SUM，需使用 `EXPLODE` 或数组函数处理。 |

### 时效性说明

- 本表为 **T+1 日更新**，当日数据最早于次日数据管道完成后可用。
- 表名后缀 `_1d` 表示每日粒度快照，**不做滚动累计**，历史数据需跨日期聚合。
- 使用 `INSERT OVERWRITE` 覆盖写入，同一 `(grass_region, local_date)` 分区每次全量重算，不存在增量追加。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 核心行为事件明细表，提供用户维度的曝光、点击、PPV、下单等操作记录，包含主归因及 source1、source2 多路归因字段 |
| `srdi_mart.dim_sr_data_warehouse_feature_scenario_tag_mapping` | 特征场景标签映射维表，为每个 `feature_detail` 关联对应的 `scenario_tags` 和 `operation` 类型，取最新一条记录 |
| `mkplsearch_data_product.shopee_snr_team_oa_feature_list` | 搜索特征列表维表，维护 `feature_detail` → `feature`（mapping_detail）→ `feature_group`（mapping_general）的映射关系 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform  ──────────────────────────────────────┐
  (主归因 + source1 + source2 三路 UNION ALL)                          │
                                                                       ▼
                                                        platform_data_parse
                                                               │
                                                               │ GROUP BY GROUPING SETS
                                                               ▼
                                                        platform_data_grouped
                                                               │
dim_feature_scenario_tag_mapping ──► feature_scenario_tag_mapping      │
shopee_snr_team_oa_feature_list  ──► feature_list                      │
                                                               │ LEFT JOIN
                                                               ▼
                                    INSERT OVERWRITE  dws_sr_data_warehouse_search_user_feature_civ_order_1d
```

### 关键步骤

**Step 1 — `feature_scenario_tag_mapping`（Temporary View）**
从维表 `dim_sr_data_warehouse_feature_scenario_tag_mapping` 读取指定站点和日期的特征场景标签映射，过滤 operation 范围为 click/impression/view/ppv/order，去除以 `'Page '` 开头的 scenario_tags 元素，并通过 `ROW_NUMBER()` 按 `feature_detail` 取最新小时（`local_hour DESC`）的唯一记录（`recency_rank = 1`）。

**Step 2 — `feature_list`（Temporary View）**
从运营维护的特征列表 `shopee_snr_team_oa_feature_list` 读取 `feature_detail → feature → feature_group` 三级映射，不做日期/站点过滤（全量维表）。

**Step 3 — `platform_data_parse`（Temporary View）**
对 `dwd_sr_data_warehouse_platform` 进行三路数据展开：
- **路径 1（全操作）**：取所有 operation（click/impression/view/ppv/order），以主归因字段 `feature_detail` 为 key。
- **路径 2（ppv/order）**：取 `source1_feature_detail`，仅在其不为空且与主归因 `feature_detail` 不同时补充归因。
- **路径 3（ppv/order）**：取 `source2_feature_detail`，仅在其不为空且与 source1、主归因均不同时补充归因，实现多路归因去重。

**Step 4 — `platform_data_grouped`（Temporary View）**
对 `platform_data_parse` 按 `(user_id, feature_detail, is_ads)` 使用 `GROUPING SETS` 进行双维度聚合：
- **明细行**：`(user_id, feature_detail, is_ads)` — 区分广告/自然。
- **汇总行**：`(user_id, feature_detail)` — is_ads 填充为 `'__ALL__'`，合并广告与自然。
各操作类型指标分别 SUM 汇总。

**Step 5 — INSERT OVERWRITE（目标表写入）**
将 `platform_data_grouped` 与 `feature_list`（LEFT JOIN on feature_detail）、`feature_scenario_tag_mapping`（LEFT JOIN on feature_detail，WHERE recency_rank=1）关联，NULL 值补 0 后，按 `(grass_region, local_date)` 分区覆盖写入目标表。

### 注意事项

- **单一 Writer**：`multi_writer = false`，该表仅由单个 ETL 文件写入，无并发分区写入风险。
- **覆盖写入**：使用 `INSERT OVERWRITE PARTITION`，每次执行将完全重算并覆盖指定 `(grass_region, local_date)` 分区，重跑幂等安全。
- **多路归因展开**：source1、source2 仅对 ppv 和 order 操作生效，impression 和 click 仅使用主归因，避免行为指标重复归因。
- **维表未命中**：`feature_list` 和 `feature_scenario_tag_mapping` 均为 LEFT JOIN，若 `feature_detail` 在维表中无对应记录，则 `feature`、`feature_group`、`scenario_tags` 字段为 NULL；最终 WHERE `recency_rank = 1` 会过滤掉在维表中完全缺失的 `feature_detail` 记录（因 recency_rank 为 NULL）。
- **SRP PV 口径**：`srp_pv` 仅统计特定 page_type 的 view 事件，并非所有 view 操作，使用时注意与其他 view 指标的口径差异。

---

*文档生成时间：2026-05-17*