<!-- ads-workspace-gdoc-sync: gdoc_id=1hScHMQIvj9Qpt2_9vcMGhESpWwxQAwdNsaMiTzZV7hc gdoc_url=https://docs.google.com/document/d/1hScHMQIvj9Qpt2_9vcMGhESpWwxQAwdNsaMiTzZV7hc/edit -->

# srdi_mart.dwd_sr_data_warehouse_video_unify_full_link_log_1h

**分层：** DWD（明细层）
**主键：** `request_id` + `session_id` + `item_id` + `video_id` + `regional_date` + `regional_hour` + `country`
**分区：** `regional_date`（日期）、`regional_hour`（小时）、`country`（国家/地区）
**更新频率：** 每小时覆盖写入（INSERT OVERWRITE）
**访问频次：** 3006 次

---

## 业务描述

本表是**视频搜推广告全链路日志明细表**，按小时粒度记录视频广告候选商品在搜推系统各个处理阶段的完整流转信息，覆盖从召回（Recall）→ 预排序（Prerank）→ 精排（Rank）→ 混排（Mixrank）→ 下发（Dispatch）的端到端全链路。

**核心业务场景：**
- 分析各阶段（召回、预排序、精排、混排、下发）的候选商品留存与过滤情况
- 诊断各阶段 API 异常（召回、竞价、扣费等接口错误）
- 追踪单次搜推请求（`request_id`）的完整商品流转路径
- 分析广告商品的 eCPM、pCTR、pCVR 等排序指标分布
- 统计各召回队列（queue）的候选来源及策略效果
- 支持按国家/地区、小时粒度的广告投放效果分析

**适合回答的问题：**
- 某小时某地区的视频广告召回量、精排量、最终下发量分别是多少？
- 某商品/广告在精排阶段的 eCPM、pCTR 分布如何？
- 某请求中哪些商品在哪个阶段被过滤，过滤原因是什么？
- 广告混排阶段的 porg（原始分）与最终得分的关系？
- 某召回策略（queue）的候选商品数量及得分分布？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据所属日期（本地化区域日期），分区键，查询必须指定 |
| `regional_hour` | string | 数据所属小时（本地化区域小时，如 `"00"`~`"23"`），分区键，查询必须指定 |
| `country` | string | 国家/地区编码（如 `SG`、`MY`），分区键，查询必须指定 |

### 维度：请求与会话标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 搜推请求唯一标识，用于关联同一次请求的所有候选商品 |
| `session_id` | string | 用户会话标识 |
| `user_id` | bigint | 用户 ID |
| `entrance` | string | 请求入口（来源 bundle），如短视频、搜索等入口标识 |
| `ab_sign` | array\<int\> | AB 实验分桶标识列表，标记该请求命中的实验组 |

### 维度：商品与广告标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_id` | bigint | 广告计划 ID |
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `video_id` | string | 视频 ID，关联广告素材视频 |
| `item_type` | string | 商品类型标识 |

### 维度：全链路阶段标记

| 字段名 | 类型 | 说明 |
|---|---|---|
| `is_recall` | boolean | 是否进入召回阶段（recall_info 不为 null 则为 true） |
| `is_prerank` | boolean | 是否进入预排序阶段（prerank_info 不为 null 则为 true） |
| `is_rank` | boolean | 是否进入精排阶段（rank_info 不为 null 则为 true） |
| `is_mixrank` | boolean | 是否进入混排阶段（mixrank_info 不为 null 则为 true） |
| `is_dispatch` | boolean | 是否最终下发（final_stage = 'DISPATCH' 则为 true） |
| `is_sampled` | boolean | 是否为全链路采样数据（sample_info.full_link_ads） |

### 维度：召回阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `recall_type` | int | 召回来源类型：0=未知，1=仅广告召回，2=仅自然召回，3=广告+自然双路召回 |
| `recall_queues` | array\<int\> | 命中的召回队列 ID 列表（由 recall_strategies 中各策略的 queue_id 转换而来） |
| `recall_remove_reason` | string | 召回阶段过滤原因；若在召回后仍存活则为 `NOT_FILTERED` |

### 维度：预排序阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `prerank_remove_reason` | string | 预排序阶段过滤原因；若在预排序后仍存活则为 `NOT_FILTERED` |

### 维度：精排阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `rank_remove_reason` | string | 精排阶段过滤原因；若在精排后仍存活则为 `NOT_FILTERED` |

### 维度：混排阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `mixrank_remove_reason` | string | 混排阶段过滤原因；若在混排后仍存活则为 `NOT_FILTERED` |

### 维度：API 异常诊断

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_info_api_error` | string | 广告信息接口（roi_revert）异常信息，来源于召回阶段 |
| `bidding_api_error` | string | 竞价接口异常信息，来源于精排阶段 |
| `deduction_api_error` | string | 扣费接口异常信息，来源于混排阶段 |

### 维度：广告扩展信息（Protobuf 解析）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_recall_ext` | string | 召回阶段扩展信息，由 `ads_info.recall_ext` base64 解码 Protobuf（RecallFullLinkExt）后得到 |
| `ads_info_ext` | string | 广告信息扩展字段，由 `ads_info.info_ext` base64 解码 Protobuf（RecallFullLinkExt）后得到 |
| `ads_bid_ext` | string | 竞价扩展信息，由 `bidding_info.bid_ext` base64 解码 Protobuf（AdBidFullLinkExt）后得到 |
| `ads_deduct_ext` | string | 扣费扩展信息，由 `deduction_info.deduct_ext` base64 解码 Protobuf（DeductFullLinkExt）后得到 |

### 指标：召回阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `queue_scores` | array\<float\> | 各召回队列对应的候选得分列表，与 `recall_queues` 下标一一对应 |

### 指标：预排序阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `prerank_score` | float | 预排序阶段打分值 |
| `prerank_position` | int | 预排序阶段的候选排名（index） |

### 指标：精排阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `rank_score` | float | 精排阶段综合得分 |
| `rank_position` | int | 精排阶段的候选排名（index） |
| `rank_pctr` | float | 精排预估点击率（pCTR） |
| `rank_pcr` | float | 精排预估转化率（pCVR） |
| `rank_broad_pcr` | float | 精排宽泛转化率（broad pCVR） |
| `rank_ecpm` | float | 精排预估千次展示收益（eCPM） |
| `rank_ecpm_weight` | float | 精排 eCPM 权重 |
| `rank_estimated_gmv` | float | 精排预估 GMV |

### 指标：混排阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `mixrank_score` | float | 混排阶段综合得分 |
| `mixrank_position` | int | 混排阶段的候选排名（index） |
| `mixrank_item_price` | bigint | 混排阶段商品价格（单位：分或平台最小货币单位） |
| `mixrank_pctr` | float | 混排预估点击率（pCTR） |
| `mixrank_pcr` | float | 混排预估转化率（pCVR） |
| `mixrank_broad_pcr` | float | 混排宽泛转化率（broad pCVR） |
| `mixrank_ecpm` | float | 混排预估千次展示收益（eCPM） |
| `mixrank_ecpm_weight` | float | 混排 eCPM 权重 |
| `mixrank_estimated_gmv` | float | 混排预估 GMV |
| `mixrank_porg` | float | 混排原始分（porg，混排前的原始模型打分） |

### 指标：下发阶段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `dispatch_position` | int | 最终下发位置（dispatch 阶段的 index） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须全部指定**，查询时必须同时过滤 `regional_date`、`regional_hour` 和 `country`，否则会触发全表扫描导致性能问题或超时：
  ```sql
  WHERE regional_date = '2026-05-17'
    AND regional_hour = '10'
    AND country = 'SG'
  ```
- 若需要跨小时汇总，建议先在 WHERE 中指定日期范围并枚举 hour，避免省略 `regional_hour`。

### 不可直接 SUM 的字段

以下字段为**比率、预估分或位置类指标**，直接 SUM 无业务意义，需按实际分析场景使用 AVG、PERCENTILE 或加权汇总：

| 字段 | 原因 |
|---|---|
| `rank_pctr`、`mixrank_pctr` | 预估点击率，比率类，不可累加 |
| `rank_pcr`、`rank_broad_pcr`、`mixrank_pcr`、`mixrank_broad_pcr` | 预估转化率，比率类，不可累加 |
| `rank_ecpm`、`mixrank_ecpm` | 千次展示收益，为估算值，直接 SUM 无意义 |
| `rank_ecpm_weight`、`mixrank_ecpm_weight` | 权重系数，不可累加 |
| `rank_score`、`prerank_score`、`mixrank_score` | 阶段排序得分，不可累加 |
| `mixrank_porg` | 原始模型分，不可累加 |
| `rank_estimated_gmv`、`mixrank_estimated_gmv` | 预估 GMV，为模型预测值而非实际成交，直接汇总需结合业务含义 |
| `prerank_position`、`rank_position`、`mixrank_position`、`dispatch_position` | 位置/排名，不可累加 |
| `queue_scores` | 数组类型，需先 EXPLODE 展开再分析 |
| `recall_queues`、`ab_sign` | 数组类型，需先 EXPLODE 展开再分析 |

### 时效性说明

- 本表为**小时级明细表**（`_1h` 后缀），每小时覆盖写入当前分区，数据延迟通常在 1 小时以内。
- 采用 INSERT OVERWRITE 写入，已写入分区不会重复追加，重跑时会覆盖对应分区。
- `is_sampled = true` 的记录来自全链路采样数据，若进行全量漏斗分析时需注意采样率，避免直接与非采样指标混用。
- `regional_date` 和 `regional_hour` 为**区域本地化时间**，跨时区对比时需注意与 UTC 的换算。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_video` | 视频广告全链路原始日志 ODS 表，包含 request 级别的嵌套结构数据（data 数组），按 regional_date、regional_hour、country 分区过滤后 EXPLODE 展开为商品粒度 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_video
    │  (按分区过滤：regional_date / regional_hour / country)
    │  (LATERAL VIEW EXPLODE data 数组，展开为单商品粒度)
    ▼
临时视图 unify_fll_video_parse_${grass_region_without_quote}
    │  (字段提取、Protobuf base64 解码、阶段信息结构化)
    ▼
srdi_mart.dwd_sr_data_warehouse_video_unify_full_link_log_1h
    (INSERT OVERWRITE，分区：regional_date / regional_hour / country)
```

### 关键步骤

**Step 1 — 创建临时视图（Statement 1）**

从 ODS 原始表 `srdi_rt.ods_fll_video` 中按分区条件过滤数据，使用 `LATERAL VIEW EXPLODE(t.data)` 将每条 request 的候选商品数组展开为行粒度。提取各阶段的嵌套结构字段（recall_info、prerank_info、rank_info、mixrank_info、dispatch_info），并调用 `base64_to_protobuf` 自定义函数对广告扩展字段（recall_ext、info_ext、bid_ext、deduct_ext）进行 Protobuf 反序列化，结果保存为临时视图。

**Step 2 — 写入目标表（Statement 2）**

从临时视图读取数据，进行以下加工后 INSERT OVERWRITE 写入目标分区：

- **阶段存活标记**：通过判断各阶段 info 是否为 null 生成 `is_recall`、`is_prerank`、`is_rank`、`is_mixrank`；通过 `final_stage = 'DISPATCH'` 生成 `is_dispatch`。
- **召回类型编码**：根据 `from_organic` 和 `from_ads` 的组合值将召回来源编码为整型枚举 `recall_type`（0/1/2/3）。
- **召回队列展开**：使用 `transform` 函数将 `recall_strategies` 数组中各策略的 `queue_id` 和 `score` 分别转换为 `recall_queues`（array\<int\>）和 `queue_scores`（array\<float\>）。
- **过滤原因标准化**：各阶段的 `remove_reason` 统一处理为"若该阶段非最终截止阶段则写 `NOT_FILTERED`"逻辑，分别生成 `recall_remove_reason`、`prerank_remove_reason`、`rank_remove_reason`、`mixrank_remove_reason`。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无多 Writer 竞争风险。
- **分区写入**：采用静态分区 INSERT OVERWRITE，`regional_date`、`regional_hour`、`country` 三字段均为分区键，重跑时会覆盖已有分区数据，需注意幂等性。
- **`country` 作为第三分区键**：ODS 层按 `country in (${grass_region})` 过滤，目标表按单个 `country` 值写入分区，ETL 为按地区分批执行模式，一次作业写入一个地区分区。
- **Protobuf UDF 依赖**：`base64_to_protobuf` 为自定义函数，依赖 Protobuf schema 注册（RecallFullLinkExt、AdBidFullLinkExt、DeductFullLinkExt），若 schema 变更可能导致解析失败或字段为空。
- **`ads_info_api_error` / `bidding_api_error` / `deduction_api_error` 同源**：三个字段在临时视图中均来自 `d.roi_revert_reason`，字段含义在目标表语义层面区分了召回/竞价/扣费阶段，实际值相同，使用时应结合对应阶段的 is_* 标记进行过滤。

---

*文档生成时间：2026-05-17*