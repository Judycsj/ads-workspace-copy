<!-- ads-workspace-gdoc-sync: gdoc_id=1rrHVLsa2HZUIXNXAH1hobgCFE369ufuhSR4mviZBDng gdoc_url=https://docs.google.com/document/d/1rrHVLsa2HZUIXNXAH1hobgCFE369ufuhSR4mviZBDng/edit -->

# srdi_mart.dwd_sr_data_warehouse_rcmd_unify_full_link_log_1h

**分层：** DWD（明细层）
**主键：** `request_id` + `item_id` + `regional_date` + `regional_hour` + `country`
**分区：** `regional_date`（日期）、`regional_hour`（小时）、`country`（国家/地区）
**更新频率：** 每小时覆写（INSERT OVERWRITE，T+0 准实时）
**访问频次：** 23,015 次

---

## 业务描述

本表是搜推（SRDI）推荐场景下的**统一全链路日志明细宽表**，以小时粒度记录推荐系统各阶段（召回 → 预排序 → 排序 → 混排 → 分发）每条候选商品/广告的完整链路快照。

**核心业务场景：**
- 推荐全链路漏斗分析（各阶段通过/过滤情况）
- 各排序阶段模型分数、eCPM、预估 GMV 等指标的明细核查
- 广告召回、竞价、扣费链路的 API 异常排查
- AB 实验效果追踪（`ab_sign` 实验标识）
- 用户/会话/商品维度的推荐行为分析
- 多国家/地区的区域化推荐效果对比

**适合回答的问题：**
- 某次请求中某商品在各阶段的分数和位次是多少？
- 某时段某国家的召回命中率、排序截断率分别是多少？
- 广告在预排序/精排/混排阶段的 eCPM 分布如何？
- 某 AB 实验组在混排阶段的商品通过率变化趋势？
- 某商品被过滤在哪个阶段？过滤原因是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据所属日期（按地区时区对齐），分区键，查询时必须指定 |
| `regional_hour` | string | 数据所属小时（格式如 `"00"`～`"23"`），分区键，查询时建议指定 |
| `country` | string | 国家/地区标识（grass region），分区键，对应地区化推荐场景 |

### 维度：请求与会话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 推荐请求唯一 ID，用于串联同一请求的全链路日志 |
| `session_id` | string | 用户会话 ID |
| `cache_request_id` | string | 命中缓存时对应的原始请求 ID，与 `is_cached` 配合使用 |

### 维度：用户与入口

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一 ID |
| `entrance` | string | 推荐入口标识，来源于 `biz_info.rcmd_info.bundle` |
| `ads_entrance` | int | 广告入口标识，来源于 `biz_info.ads_entrance` |
| `ab_sign` | array\<int\> | AB 实验标识数组，记录命中的实验组 |

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `item_type` | string | 商品类型 |
| `ads_id` | bigint | 广告 ID |
| `ctx_item_type` | int | 上下文商品类型（虚拟商品场景使用） |
| `ritem_id` | bigint | 关联/真实商品 ID（虚拟商品场景下的原始商品） |
| `rshop_id` | int | 关联店铺 ID（int 类型） |
| `rshop_id_v2` | bigint | 关联店铺 ID v2（bigint，与 `rshop_id` 同义但精度更高） |
| `rmodel_id` | bigint | 关联模型 ID |
| `vmodel_id` | bigint | 虚拟模型 ID（当前暂不可用，固定为 `null`） |

### 维度：全链路阶段状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `final_stage` | string | 该条候选的最终到达阶段（如 `DISPATCH` 表示最终分发） |
| `is_recall` | boolean | 是否经过召回阶段（`recall_info` 不为 null 则为 true） |
| `is_prerank` | boolean | 是否经过预排序阶段（`prerank_info` 不为 null 则为 true） |
| `is_rank` | boolean | 是否经过精排阶段（`rank_info` 不为 null 则为 true） |
| `is_mixrank` | boolean | 是否经过混排阶段（`mixrank_info` 不为 null 则为 true） |
| `is_dispatch` | boolean | 是否最终分发（`final_stage = 'DISPATCH'` 则为 true） |
| `is_cached` | boolean | 本次请求是否命中缓存 |
| `is_sampled` | boolean | 是否被全链路广告采样（`sample_info.full_link_ads`） |
| `full_link_all` | boolean | 是否被全链路全量采样（`sample_info.full_link_all`） |

### 维度：召回阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `recall_type` | int | 召回来源类型：0=未知，1=仅广告召回，2=仅自然召回，3=广告+自然均召回 |
| `recall_queues` | array\<int\> | 命中的召回队列 ID 列表（由 `recall_strategies.queue_id` 转换） |
| `recall_remove_reason` | string | 召回阶段过滤原因（来源于 `d.filtered_reason`） |
| `ads_info_api_error` | string | 广告信息 API 异常原因（来源于 `roi_revert_reason`） |

### 维度：预排序阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `prerank_position` | int | 预排序阶段候选排名位次 |
| `prerank_remove_reason` | string | 预排序阶段过滤原因（来源于 `d.filtered_reason`） |
| `prerank_rcmd_rank_scores` | string | 预排序综合评分 JSON 字符串（`to_json(prerank_rcmd_rank_scores)`） |

### 维度：精排阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `rank_position` | int | 精排阶段候选排名位次 |
| `rank_remove_reason` | string | 精排阶段过滤原因（来源于 `d.filtered_reason`） |
| `rank_rcmd_rank_scores` | string | 精排综合评分 JSON 字符串（`to_json(rank_rcmd_rank_scores)`） |
| `bidding_api_error` | string | 竞价 API 异常原因（来源于 `roi_revert_reason`） |

### 维度：混排阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `mixrank_position` | int | 混排阶段候选排名位次 |
| `mixrank_remove_reason` | string | 混排阶段过滤原因（来源于 `d.filtered_reason`） |
| `mixrank_rcmd_rank_scores` | string | 混排综合评分 JSON 字符串（`to_json(mixrank_rcmd_rank_scores)`） |
| `deduction_api_error` | string | 扣费 API 异常原因（来源于 `roi_revert_reason`） |

### 维度：分发阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `dispatch_position` | int | 最终分发位次（`d.dispatch_info.index`） |

### 维度：广告扩展信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_recall_ext` | string | 广告召回扩展信息，由 base64 编码的 Protobuf（`RecallFullLinkExt`）解码而来 |
| `ads_info_ext` | string | 广告信息扩展字段，由 base64 编码的 Protobuf（`RecallFullLinkExt`）解码而来 |
| `ads_bid_ext` | string | 广告竞价扩展信息，由 base64 编码的 Protobuf（`AdBidFullLinkExt`）解码而来 |
| `ads_deduct_ext` | string | 广告扣费扩展信息，由 base64 编码的 Protobuf（`DeductFullLinkExt`）解码而来 |

### 指标：召回阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `queue_scores` | array\<float\> | 各召回队列的召回分数列表（由 `recall_strategies.score` 转换） |

### 指标：预排序阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `prerank_score` | float | 预排序综合评分 |
| `prerank_pctr` | float | 预排序预估点击率（pCTR） |
| `prerank_pcr` | float | 预排序预估转化率（pCVR） |
| `prerank_fusion_score` | float | 预排序融合分数（`rcmd_rank_scores.scores[0]`） |
| `prerank_ecpm` | float | 预排序阶段千次展示预估收益（eCPM） |
| `prerank_ecpm_weight` | float | 预排序阶段 eCPM 权重 |
| `prerank_p0_order` | float | 预排序阶段 P0 订单预估分 |
| `prerank_p0_click` | float | 预排序阶段 P0 点击预估分 |

### 指标：精排阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `rank_score` | float | 精排综合评分 |
| `rank_pctr` | float | 精排预估点击率（pCTR） |
| `rank_pcr` | float | 精排预估转化率（pCVR） |
| `rank_broad_pcr` | float | 精排宽泛预估转化率（broad pCVR） |
| `rank_ecpm` | float | 精排阶段千次展示预估收益（eCPM） |
| `rank_ecpm_weight` | float | 精排阶段 eCPM 权重 |
| `rank_estimated_gmv` | float | 精排阶段预估 GMV |
| `rank_item_price` | bigint | 精排阶段商品价格（`d.price_v2`，单位与原始价格字段一致） |

### 指标：混排阶段

| 字段 | 类型 | 说明 |
|---|---|---|
| `mixrank_score` | float | 混排综合评分 |
| `mixrank_pctr` | float | 混排预估点击率（pCTR） |
| `mixrank_pcr` | float | 混排预估转化率（pCVR） |
| `mixrank_broad_pcr` | float | 混排宽泛预估转化率（broad pCVR） |
| `mixrank_ecpm` | float | 混排阶段千次展示预估收益（eCPM） |
| `mixrank_ecpm_weight` | float | 混排阶段 eCPM 权重 |
| `mixrank_estimated_gmv` | float | 混排阶段预估 GMV |
| `mixrank_item_price` | bigint | 混排阶段商品价格（`d.price_v2`，与 `rank_item_price` 同源） |
| `mixrank_porg` | float | 混排阶段自然流量占比分数（pOrg） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`regional_date`**：必须指定，否则将全表扫描所有历史分区，严重影响查询性能。推荐格式：`WHERE regional_date = '2026-05-17'`。
- **`regional_hour`**：建议同时指定，进一步缩小扫描范围。格式示例：`AND regional_hour = '10'`。
- **`country`**：为分区列，查询特定地区数据时必须指定，避免跨区域全扫。

### 不可直接 SUM 的字段

以下字段为比率、预估分数或概率类指标，**不可直接求和（SUM）**，需使用加权平均或分析函数：

| 字段 | 原因 |
|---|---|
| `prerank_pctr`、`rank_pctr`、`mixrank_pctr` | 预估点击率（比率型），直接求和无意义 |
| `prerank_pcr`、`rank_pcr`、`mixrank_pcr` | 预估转化率（比率型），直接求和无意义 |
| `rank_broad_pcr`、`mixrank_broad_pcr` | 宽泛预估转化率（比率型） |
| `prerank_ecpm`、`rank_ecpm`、`mixrank_ecpm` | eCPM 为千次预估收益，应使用加权平均 |
| `prerank_ecpm_weight`、`rank_ecpm_weight`、`mixrank_ecpm_weight` | 权重字段，不可单独求和 |
| `mixrank_porg` | 比率型分数，不可直接求和 |
| `prerank_score`、`rank_score`、`mixrank_score` | 模型综合评分，相加无业务意义 |
| `prerank_fusion_score`、`prerank_p0_order`、`prerank_p0_click` | 模型子分数，相加无意义 |
| `queue_scores` | 数组类型分数，不可直接聚合 |

以下字段包含 **JSON 字符串**，需使用 `get_json_object` 或 `from_json` 解析后再使用：

- `prerank_rcmd_rank_scores`、`rank_rcmd_rank_scores`、`mixrank_rcmd_rank_scores`

以下字段包含 **Protobuf 解码结果**（字符串），需结合业务约定解析结构：

- `ads_recall_ext`、`ads_info_ext`、`ads_bid_ext`、`ads_deduct_ext`

### 时效性说明

- 本表为**小时级准实时表**，每小时按分区 `(regional_date, regional_hour, country)` 执行 `INSERT OVERWRITE`，数据通常延迟 1～2 小时可用。
- 表中**不包含历史累计指标**（无 `_nd`、`_td` 滚动窗口字段），所有字段均为单次请求的即时快照值。
- `vmodel_id` 字段当前固定为 `null`，暂不可用于分析。
- `ads_info_api_error`、`bidding_api_error`、`deduction_api_error` 均来源于同一上游字段 `roi_revert_reason`，三列含义相同，仅按阶段语义命名。
- `recall_remove_reason`、`prerank_remove_reason`、`rank_remove_reason`、`mixrank_remove_reason` 同样均来源于 `d.filtered_reason`，各阶段过滤原因在上游为同一字段，使用时注意结合 `is_recall`/`is_prerank`/`is_rank`/`is_mixrank` 判断实际所在阶段。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_rcmd` | 推荐全链路原始日志 ODS 表，按 `regional_date`、`regional_hour`、`country` 分区读取，每行包含一个请求下的多条候选商品数组（通过 `LATERAL VIEW EXPLODE` 展开） |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_rcmd
    │
    │  按 (regional_date, regional_hour, country) 过滤
    │  LATERAL VIEW EXPLODE(data) 展开候选商品数组
    │  base64_to_protobuf 解码广告扩展字段
    ▼
temporary view: unify_fll_rcmd_parse_<region>
    │
    │  阶段状态布尔化、recall_type 枚举转换
    │  recall_queues / queue_scores 数组映射
    │  rcmd_rank_scores 转 JSON 字符串
    │  多处复用 roi_revert_reason / filtered_reason
    ▼
srdi_mart.dwd_sr_data_warehouse_rcmd_unify_full_link_log_1h
（INSERT OVERWRITE 指定分区）
```

### 关键步骤

**Step 1 — 创建临时视图（`unify_fll_rcmd_parse_<region>`）**

- 从 `srdi_rt.ods_fll_rcmd` 读取指定分区数据（`regional_date`、`regional_hour`、`country`）。
- 使用 `LATERAL VIEW EXPLODE(t.data)` 将每个请求内的候选商品数组展开为行级明细。
- 从嵌套结构中提取各阶段（recall / prerank / rank / mixrank / dispatch）的详细字段，保留原始 `*_info` struct 供后续判断是否为 null。
- 调用 `base64_to_protobuf` UDF 解码四个广告扩展字段（`ads_recall_ext`、`ads_info_ext`、`ads_bid_ext`、`ads_deduct_ext`）。

**Step 2 — INSERT OVERWRITE 写目标表**

- 从临时视图读取展开后的明细数据，对字段进行以下转换：
  - **阶段状态**：判断各阶段 `*_info` 是否为 null，生成 `is_recall`、`is_prerank`、`is_rank`、`is_mixrank` 布尔字段；`is_dispatch` 由 `final_stage = 'DISPATCH'` 推导。
  - **召回类型**：通过 `from_organic`、`from_ads` 两个布尔值组合映射 `recall_type` 枚举（0/1/2/3）。
  - **召回队列**：使用 `transform` 函数将 `recall_strategies` 数组分别映射为 `recall_queues`（int 数组）和 `queue_scores`（float 数组）。
  - **API 异常字段**：`ads_info_api_error`、`bidding_api_error`、`deduction_api_error` 均赋值为 `roi_revert_reason`。
  - **过滤原因**：`recall_remove_reason`、`prerank_remove_reason`、`rank_remove_reason`、`mixrank_remove_reason` 均赋值为 `d.filtered_reason`（即 `remove_reason`）。
  - **价格**：`rank_item_price`、`mixrank_item_price` 均来源于 `d.price_v2`。
  - **评分 JSON 化**：`prerank_rcmd_rank_scores`、`rank_rcmd_rank_scores`、`mixrank_rcmd_rank_scores` 通过 `to_json()` 转为字符串存储。
  - **`vmodel_id`**：固定写入 `null`，标注为暂不可用。
- 按 `(regional_date, regional_hour, country)` 覆写目标分区。

### 注意事项

- **单写入文件**：本表为单 ETL 文件写入，无多 writer 并发冲突风险。
- **分区覆写**：采用 `INSERT OVERWRITE ... PARTITION(regional_date, regional_hour, country)` 静态分区写入，每次运行仅覆盖指定时间与地区分区，不影响其他分区数据。
- **多字段同源**：`ads_info_api_error`、`bidding_api_error`、`deduction_api_error` 三列以及 `recall_remove_reason`、`prerank_remove_reason`、`rank_remove_reason`、`mixrank_remove_reason` 四列均来自上游同一字段，下游使用时应结合阶段状态字段（`is_*`）进行筛选，避免重复计数或错误归因。
- **Protobuf 扩展字段**：`ads_*_ext` 字段已由 `base64_to_protobuf` UDF 解码，存储为字符串，下游解析需了解对应 Protobuf Schema（`RecallFullLinkExt`、`AdBidFullLinkExt`、`DeductFullLinkExt`）。
- **数组字段**：`ab_sign`、`recall_queues`、`queue_scores` 为数组类型，聚合分析时需配合 `EXPLODE` 或 `ARRAY` 函数处理。

---

*文档生成时间：2026-05-17*