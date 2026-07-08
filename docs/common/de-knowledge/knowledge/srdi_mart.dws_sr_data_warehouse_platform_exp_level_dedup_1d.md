<!-- ads-workspace-gdoc-sync: gdoc_id=1TMWESxqBgSIaGlgHLmUQBn33Kb8RKoYV62KEurlw_DY gdoc_url=https://docs.google.com/document/d/1TMWESxqBgSIaGlgHLmUQBn33Kb8RKoYV62KEurlw_DY/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_dedup_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `platform` + `is_ads` + `scenario_tag` + `target_type` + `exp_type` + `grass_region` + `local_date`
**分区：** `exp_type` / `grass_region` / `local_date`
**更新频率：** 每日（T+1）
**访问频次：** 463

---

## 业务描述

本表以**实验组（exp_group_id）+ 平台 + 是否广告 + 场景标签 + 目标类型**为聚合粒度，记录搜推平台各实验组在曝光流量侧的**去重曝光量（dedup_imp_cnt）**，仅覆盖命中推荐白名单的实验组。

核心业务场景：
- **A/B 实验效果评估**：按实验组维度对比各业务场景的流量曝光规模，支持搜索、推荐等多业务线的实验分析。
- **多维切片分析**：通过 CUBE 预聚合，支持按 `platform`（设备平台）、`is_ads`（是否广告）、`target_type`（目标类型）进行任意组合下钻；`__ALL__` 占位符代表对应维度的全量汇总。
- **场景流量监控**：覆盖 Global Search、Daily Discover、YMAL、Cart Recommendation 等多个推荐与搜索场景，便于按场景监控实验流量健康度。

适合回答的典型问题：
- 某实验组在特定日期的去重曝光量是多少？
- 各平台（iOS/Android）下不同实验组的流量分布如何？
- 广告流量与自然流量在不同推荐场景中的曝光占比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验流量类型，当前 ETL 固定写入值为 `'traffic'`，标识曝光流量来源类型 |
| `grass_region` | string | 大区/站点标识，如 `ID`、`TH` 等，由调度参数动态传入 |
| `local_date` | date | 数据日期（本地时区），格式 `yyyy-MM-dd`，对应业务发生日 |

### 维度：实验与平台属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | 实验组 ID，关联 A/B 实验平台，仅保留推荐白名单（`is_rcmd_whitelist = 1`）中的实验组 |
| `platform` | string | 用户访问平台（如 iOS、Android 等）；CUBE 聚合时全量汇总行填充为 `'__ALL__'` |
| `is_ads` | string | 是否广告流量（`'true'`/`'false'`）；CUBE 聚合时全量汇总行填充为 `'__ALL__'` |
| `scenario_tag` | string | 场景标签，标识具体推荐或搜索场景，如 `'dpm module Global Search business line Search'`、`'DA_Daily Discover'` 等；由 `algo_tag` 及 `reporting_module`/`reporting_business_line` 组合派生，经 EXPLODE 展开后作为聚合维度 |
| `target_type` | string | 目标类型，区分不同的优化目标；CUBE 聚合时全量汇总行填充为 `'__ALL__'` |

### 指标：曝光去重量

| 字段 | 类型 | 说明 |
|---|---|---|
| `dedup_imp_cnt` | bigint | 去重曝光次数；对同一 `(request_id, user_id, item_id, location, banner_location)` 组合去重后（保留 `exp_group_ids` 较长的记录），按实验组 EXPLODE 展开再聚合得到的曝光计数，已在 CUBE 维度上预聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则将触发全分区扫描，严重影响查询性能。例：`WHERE local_date = '2024-08-01'`。
- **`grass_region`**：必须指定站点，不同站点数据相互独立。例：`AND grass_region = 'ID'`。
- **`exp_type`**：当前全量数据均为 `'traffic'`，建议显式过滤以保证语义明确。例：`AND exp_type = 'traffic'`。

### 不可直接 SUM 的字段及注意事项

- **`dedup_imp_cnt` 的 CUBE 汇总行问题**：表中存在 CUBE 预聚合产生的多粒度汇总行（`platform`、`is_ads`、`target_type` 为 `'__ALL__'` 时为该维度全量合计）。对 `dedup_imp_cnt` 进行求和时，**必须固定所有维度字段的过滤条件**，否则会发生重复累加。  
  - 正确做法：同时过滤 `platform`、`is_ads`、`target_type` 为具体值或统一选取 `'__ALL__'` 维度行，避免混合聚合。
- **`dedup_imp_cnt` 已是预聚合指标**：不可跨 `local_date` 直接 SUM 得到多日累计去重量，因为去重逻辑在单日 ETL 内完成，跨天累加不等于真实去重值。
- **`scenario_tag` 已 EXPLODE**：同一条原始曝光记录可能对应多个场景标签，各 `scenario_tag` 行之间存在重叠，不可对不同 `scenario_tag` 的 `dedup_imp_cnt` 直接求和比较总曝光量。

### 时效性说明

- 本表为 **每日快照表（`_1d`）**，每日凌晨调度，T+1 产出前一日数据。
- 不提供实时或准实时查询能力，时效性以 `local_date` 为最小粒度。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供原始曝光日志，包含 `exp_group_ids`、`platform`、`is_ads`、`algo_tag`、`reporting_module`、`reporting_business_line`、`target_type`、`request_id`、`user_id`、`item_id`、`location`、`banner_location` 等字段，过滤 `operation = 'impression'` 后作为曝光事实数据 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 推荐实验白名单维表，提供当日有效的推荐白名单实验组 ID（`is_rcmd_whitelist = 1`），用于过滤非白名单实验组 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform（曝光日志）
    │
    ▼ 过滤 impression + 目标场景 + 去重（row_number）
dim_sr_data_warehouse_abtest_group（白名单维表）
    │
    ▼ INNER JOIN 过滤白名单实验组
    │
    ▼ EXPLODE exp_group_ids（一条记录展开为多个实验组行）
    │
    ▼ SUM 汇总 dedup_imp_cnt
    │
    ▼ EXPLODE scenario_tags + CUBE(target_type, platform, is_ads) 多维预聚合
    │
    ▼ INSERT OVERWRITE（分区写入）
srdi_mart.dws_sr_data_warehouse_platform_exp_level_dedup_1d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `exp_filter_${grass_region}` | 从白名单维表读取当日推荐白名单实验组，仅保留 `is_rcmd_whitelist = 1` 的 `exp_group_id` |
| 2 | `log_data_${grass_region}` | 从 DWD 曝光日志中过滤目标场景（Global Search 或指定推荐场景标签），使用 `ROW_NUMBER` 对 `(request_id, user_id, item_id, location, banner_location)` 去重，优先保留 `exp_group_ids` 较长的记录；同时合并 `reporting_module`/`reporting_business_line` 与 `algo_tag` 为 `scenario_tags_str` |
| 3 | `concat_data_${grass_region}` | 取去重后（`rn = 1`）的记录，将 `scenario_tags_str` 拆分并过滤为标准场景标签数组 `scenario_tags` |
| 4 | `explode_table_${grass_region}` | LATERAL VIEW EXPLODE `exp_group_ids`，将每条曝光记录按实验组展开，每行 `dedup_imp_cnt = 1` |
| 5 | `base_table_${grass_region}` | INNER JOIN 白名单过滤，仅保留白名单实验组，按 `(exp_group_id, platform, is_ads, scenario_tags, target_type)` 聚合求和 `dedup_imp_cnt` |
| 6 | `cube_table_${grass_region}` | LATERAL VIEW EXPLODE `scenario_tags` 展开场景标签，同时对 `(target_type, platform, is_ads)` 进行 CUBE 多维聚合，`NULL` 维度值替换为 `'__ALL__'` |
| 7 | INSERT OVERWRITE | 写入目标表分区 `(exp_type='traffic', grass_region=..., local_date=...)`，覆盖写入 |

### 注意事项

- **单 Writer、分区覆盖写入**：本表为单 ETL 文件写入，`INSERT OVERWRITE` 按 `(exp_type, grass_region, local_date)` 分区覆盖，每次调度只刷新对应分区，不影响其他分区历史数据。
- **CUBE 汇总行**：CUBE 聚合会产生 `platform`、`is_ads`、`target_type` 取 `NULL`（写入时替换为 `'__ALL__'`）的汇总行，查询时需注意维度过滤以避免重复统计。
- **场景标签 EXPLODE 导致行数膨胀**：同一实验组的曝光若命中多个场景标签，会在 `scenario_tag` 维度上产生多行，各行 `dedup_imp_cnt` 均为该场景下的独立计数，跨场景不可简单累加。
- **参数化 View 命名**：Temporary View 名称含 `${grass_region_without_quote}` 参数，表明同一 SQL 文件在不同站点调度时逻辑独立，互不干扰。
- **`exp_group_ids` 多值问题**：约 0.08% 的记录存在多个 `exp_group_ids`，ETL 通过 `row_number` 保留较长的那条记录，轻微低估极少数边界场景的实验覆盖。

---

*文档生成时间：2026-05-17*