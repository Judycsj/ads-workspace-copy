<!-- ads-workspace-gdoc-sync: gdoc_id=1b8yXlIdBtMH8XA7otM5MPjZP2CcA-dp6iEQJpNVBbSo gdoc_url=https://docs.google.com/document/d/1b8yXlIdBtMH8XA7otM5MPjZP2CcA-dp6iEQJpNVBbSo/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_card_type_nmv_metrics_7d

**分层：** dws_search
**主键：** grass_region + local_date + experiment_id + exp_group_id + scene_id + layer_id + search_entrance + card_type + is_ads + sort_type + search_mid + with_keyword
**分区：** grass_region, local_date
**更新频率：** 每日（覆盖写入当日分区，滚动计算过去 7 天窗口数据）
**引用频次 / 访问频次：** 995

---

## 业务描述

本表是搜索 A/B 实验维度下，按**入口 × 卡片类型**细分的近 7 日 NMV（净成交额）与订单指标汇总宽表，服务于搜索推荐方向的实验效果评估（Abtest 分析）。

**核心业务场景：**
- 评估各 A/B 实验分组在不同搜索入口（`search_entrance`）、卡片类型（`card_type`）、广告标志（`is_ads`）、排序方式（`sort_type`）、搜索模态（`search_mid`）、有无关键词（`with_keyword`）组合下的 NMV 和净订单贡献。
- 对比实验组与对照组在搜索侧（Global Search）订单转化的差异，同时提供全平台 NMV 基准数据，以便计算搜索侧渗透率或增量贡献。
- 支持按实验层（`layer_id`）、实验（`experiment_id`）、实验分组（`exp_group_id`）、场景（`scene_id`）多级下钻。

**适合回答的典型问题：**
- 某实验分组在图片搜索 vs 文字搜索下，近 7 日 NMV 和净订单量各是多少？
- 广告卡片（`is_ads=true`）与自然结果卡片在不同实验组的 NMV 差异如何？
- 某实验分组的搜索侧 NMV 占全平台 NMV 的比例是多少？
- 有关键词搜索与无关键词搜索在各实验组的订单转化 UU 对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区/站点标识，如 `ID`、`TH`、`VN` 等，每次写入覆盖对应大区分区 |
| `local_date` | date | 数据日期（动态分区），对应 ETL 调度日期；配合 7 日窗口聚合，单条记录代表当日为截止日的 7 天累计 |

### 维度：实验层级信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `scene_id` | bigint | A/B 实验场景 ID，来源于实验维度表 |
| `scene_name` | string | A/B 实验场景名称 |
| `layer_id` | bigint | 实验层 ID，用于区分同一场景下的不同实验层 |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验分组 ID（含对照组与实验组） |
| `exp_group_name` | string | 实验分组名称 |

### 维度：搜索行为细分

| 字段 | 类型 | 说明 |
|------|------|------|
| `search_entrance` | string | 搜索入口，如首页搜索框、PDP 内搜索等；空值归一为 `NA`；含聚合值 `__ALL__` |
| `card_type` | string | 卡片类型，从 `feature_detail` 解析（格式为 `page_type-[page_section-]card_type`），含 `item`、`video`、`livestream` 等；含聚合值 `__ALL__` 及组合值 `item+video+live` |
| `is_ads` | string | 是否为广告卡片，`true` / `false`；源字段为空时默认 `false`；含聚合值 `__ALL__` |
| `sort_type` | string | 排序方式；源字段为空时为 `NULL` 字符串；含聚合值 `__ALL__` |
| `search_mid` | string | 搜索模态标识，`image` 开头表示图片搜索，否则为文字搜索；含聚合值 `__ALL__`、`mutimodel_search_all`、`text_search_all` |
| `with_keyword` | string | 是否有关键词，`true` / `false`；含聚合值 `__ALL__` |

### 指标：搜索侧 NMV 与订单指标（近 7 日窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `nmv` | double | 实验分组在搜索侧（Global Search）的近 7 日净成交额（USD），为 7 天内各日订单 NMV 之和 |
| `net_order_cnt` | double | 实验分组在搜索侧的近 7 日净订单数，为 7 天内各日净订单数之和 |
| `net_order_uu` | bigint | 实验分组在搜索侧有净订单的去重用户数（7 日累计），基于 `COUNT(DISTINCT user_id WHERE net_order_cnt > 0)` |

### 指标：全平台 NMV 与订单基准指标（近 7 日窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_nmv` | double | 实验分组用户在全平台（不限业务线）的近 7 日净成交额（USD），用于计算搜索侧渗透率基准 |
| `platform_net_order_cnt` | double | 实验分组用户在全平台的近 7 日净订单数 |
| `platform_net_order_uu` | int | 实验分组用户在全平台有净订单的去重用户数（7 日累计） |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区过滤必须指定 `grass_region` 和 `local_date`**，否则将触发全表扫描：
   ```sql
   WHERE grass_region = 'ID'
     AND local_date = '2024-06-01'
   ```
2. `local_date` 为动态分区日期，每个分区存储的是以该日期为截止日的 **近 7 日聚合结果**，不是当日单日数据，因此不可对多个 `local_date` 分区求和以得到更长周期数据（会导致重复计算）。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|------|------|---------|
| `net_order_uu` | 去重 UU，跨分组/跨日期直接累加会重复计数 | 仅在同一 `grass_region` + `local_date` + 同一实验分组维度内使用 |
| `platform_net_order_uu` | 同上，全平台去重 UU | 同上 |
| `nmv`、`net_order_cnt`、`platform_nmv`、`platform_net_order_cnt` | 本表已含 `__ALL__` 聚合行，若未过滤维度值直接 SUM 会产生多倍重复 | 查询时必须明确过滤各维度的具体值或仅保留 `__ALL__`，避免与明细行双重累加 |

### 聚合维度值说明

- 各维度字段（`search_entrance`、`card_type`、`is_ads`、`sort_type`）均含 **`__ALL__`** 汇总行，代表该维度不区分的全量汇总。
- `search_mid` 和 `with_keyword` 仅在其他维度均为 `__ALL__` 时才有明细值，二者与 `search_entrance`/`card_type` 等维度不同时展开。
- `card_type = 'item+video+live'` 是特定页面类型下三类卡片的合并汇总值。
- `search_mid` 含 `mutimodel_search_all`（图片搜索汇总）和 `text_search_all`（文字搜索汇总）两个预聚合值。

### 时效性说明

- 本表为 **近 7 日滑动窗口**（`*_7d`）表，每日调度覆盖写入，`local_date` 分区存储截至当日的 7 天窗口聚合结果。
- 数据 T+1 可用，当日数据需等待次日调度完成后方可查询。
- 实验用户映射取自过去 7 天内有分流记录（`is_assignment_log = 1`）且在搜索白名单（`is_search_whitelist = 1`）中的用户。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验维度信息（场景、层、实验、分组），过滤搜索白名单实验 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户与实验分组的映射关系，取过去 7 天有分流记录的用户 |
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 平台级订单 NMV 明细，同时用于搜索侧（按 `reporting_business_line='Search'` 及 `reporting_module='Global Search'` 过滤）和全平台基准 NMV 计算；支持主归因（`feature_detail`）及 source1、source2 多归因口径 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_group          →  dim_exp（实验维度）
dim_sr_data_warehouse_abtest_user_group     →  user_exp_mapping_7d（用户-分组映射）
dwd_sr_data_warehouse_platform_nmv          →  order_nmv_raw（搜索侧原始订单，含三路归因）
                                            →  dwm_order_nmv_platform（全平台原始订单）

order_nmv_raw  →  dwm_order_nmv（用户级汇总 + 多值数组展开准备）
               →  dwm_order_nmv_explode（LATERAL VIEW EXPLODE 展开各维度组合）

dwm_order_nmv_explode + user_exp_mapping_7d  →  dws_order_nmv（搜索侧实验组级聚合）
dwm_order_nmv_platform + user_exp_mapping_7d →  dws_order_nmv_platform（全平台实验组级聚合）

dws_order_nmv + dws_order_nmv_platform + dim_exp
               →  INSERT OVERWRITE 目标表
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|------|---------------|------|
| 1 | `dim_exp` | 从实验维度表获取当日有效的搜索白名单实验分组信息 |
| 2 | `user_exp_mapping_7d` | 获取过去 7 天内命中搜索白名单且有分流日志的用户-实验分组-日期映射 |
| 3 | `order_nmv_raw` | 从平台 NMV 明细表抽取过去 7 天搜索侧订单，按主归因、source1、source2 三路 UNION ALL，解析 `feature_detail` 字段得到 `page_type`、`page_section`、`card_type`，处理空值归一 |
| 4 | `dwm_order_nmv` | 用户级按原始维度分组汇总，同时构造各维度的数组（含明细值与 `__ALL__`），为后续 EXPLODE 多维展开做准备 |
| 5 | `dwm_order_nmv_explode` | 分两路：① LATERAL VIEW EXPLODE 展开 `search_entrance`、`is_ads`、`card_type`、`sort_type` 四个维度（`search_mid` 和 `with_keyword` 固定为 `__ALL__`）；② EXPLODE 展开 `search_mid` 和 `with_keyword`（其余维度固定为 `__ALL__`），UNION ALL 合并，生成全量维度组合的用户级指标 |
| 6 | `dws_order_nmv` | 将 `dwm_order_nmv_explode` 与 `user_exp_mapping_7d` 按 `user_id + local_date` JOIN，聚合至实验分组维度，计算搜索侧 NMV、净订单数及净订单 UU |
| 7 | `dwm_order_nmv_platform` | 从平台 NMV 明细表获取过去 7 天全平台（不限业务线）用户级订单汇总 |
| 8 | `dws_order_nmv_platform` | 将全平台用户订单与实验用户映射 JOIN，聚合至实验分组维度，计算平台侧 NMV、净订单数及净订单 UU |
| 9 | INSERT OVERWRITE | 将搜索侧实验指标（`dws_order_nmv`）LEFT JOIN 全平台指标（`dws_order_nmv_platform`）和实验维度（`dim_exp`），写入目标表对应大区分区，指定 `BROADCASTJOIN` 和 `REPARTITION(20)` 优化 |

### 注意事项

- **单 writer，无并发写入风险**：本表仅有 1 个 ETL 文件，`multi_writer = false`，每次调度以 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 覆盖写入，不存在多 writer 竞争问题。
- **动态分区覆盖**：采用动态分区写入，同一 `grass_region` 下 `local_date` 作为动态分区字段，需确保 Spark/Hive 动态分区模式已开启（`hive.exec.dynamic.partition.mode=nonstrict`）。
- **三路归因 UNION ALL**：`order_nmv_raw` 同一笔订单在主归因、source1、source2 均满足条件时会出现多行，这是业务设计，代表订单被多个搜索归因渠道归因，查询时需注意避免将三路归因全量加总与单路口径混用。
- **`__ALL__` 聚合行膨胀**：EXPLODE 展开会显著增加数据行数（每条原始记录按维度组合数膨胀），查询时必须指定维度过滤条件，避免因未过滤 `__ALL__` 行而产生重复计算。
- **LEFT JOIN dim_exp**：实验维度以 LEFT JOIN 方式关联，若某 `exp_group_id` 在 `dim_exp` 中不存在（如非搜索白名单实验），则 `scene_id`、`layer_id`、`experiment_id` 等维度字段将为 NULL，查询时需注意。
- **参数化模板**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 为调度参数，由调度系统在运行时注入，不同大区独立调度。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验维度信息（场景、层、实验、分组），过滤搜索白名单实验 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户与实验分组的映射关系，取过去 7 天有分流记录的用户 |
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 平台级订单 NMV 明细，同时用于搜索侧（按业务线和模块过滤）及全平台基准 NMV 计算 |

---

*文档生成时间：2026-05-17*