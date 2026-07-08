<!-- ads-workspace-gdoc-sync: gdoc_id=1iWXZ1iZI6Fb_6SpoTObxXfB1RF3vhsU-kRsr8ssEkIs gdoc_url=https://docs.google.com/document/d/1iWXZ1iZI6Fb_6SpoTObxXfB1RF3vhsU-kRsr8ssEkIs/edit -->

# srdi_mart.dws_sr_data_warehouse_search_sqe_sample_user_keyword_1d

**分层：** dws_search（搜索域汇总层）
**主键：** user_id + keyword + search_mid（逻辑唯一键，经 DISTINCT 去重）
**分区：** grass_region（大区）/ local_date（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 8,545 次

---

## 业务描述

本表是搜索质量评估（SQE，Search Quality Evaluation）采样数据集的用户-关键词维度宽表，每日产出一份快照，记录当日参与 AB 实验的搜索用户在各关键词上的行为画像及上下文信息。

**核心业务场景：**

- **搜索质量实验分析**：仅保留已命中 AB 实验分组（`exp_type` ≠ 0）的用户，天然适用于对照/实验组的搜索质量评估。
- **多模态搜索分析**：记录图片搜索（`image_url`、`image_bounding_box`、`last_md5`、`last_box_xy`）、语音搜索（`audio_url`）及算法意图改写（`algo_intent_search_txt`）的上下文，支持多模态搜索链路质量评估。
- **关键词分层与聚类**：结合关键词热度分位段（`keyword_type`）、一级品类（`level1_keyword_category`）和关键词聚类（`keyword_cluster`），支持按关键词维度拆分分析质量指标。
- **用户意图理解**：包含用户意图标签（`user_intention`）和算法意图搜索文本（`algo_intent_search_txt`），用于评估意图识别效果。

**适合回答的问题：**

- 实验组 vs 对照组在不同关键词热度段（头/腰/尾词）的搜索质量差异如何？
- 图片搜索用户的意图理解准确率是多少？
- 某大区当日参与实验的用户在语音/图片/文字搜索上的关键词分布情况？
- 各关键词聚类下的实验用户规模和分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识，如 `ID`、`MY`、`TH` 等；所有查询必须指定此分区 |
| `local_date` | date | 业务日期（当地时区），格式 `yyyy-MM-dd`；所有查询必须指定此分区 |

### 维度：用户与实验信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户唯一标识；过滤 `user_id > 0`，仅包含已登录用户 |
| `exp_group_ids` | array\<int\> | 用户在当日命中的所有实验组 ID 列表，来源于 ABTest 实验分配日志（场景 scene_id=381 或 layer_id=4420） |
| `exp_type` | int | 实验类型归类：2=命中 layer_id=4420（优先级高）；1=命中 layer_id=3763；0=未命中以上实验层。**本表通过 INNER JOIN 仅保留 exp_type 有值的用户** |

### 维度：搜索行为与上下文

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 用户搜索关键词，已做小写化和首尾空格清洗（`TRIM(LOWER(keyword))`） |
| `search_mid` | string | 搜索模式标识，如 `image%` 表示图片搜索；用于区分文字、图片、语音等搜索方式 |
| `user_intention` | string | 多模态用户意图信息，来源于后端日志（`multimodal_user_intention_info`）；纯文本搜索或无后端日志时为 NULL |
| `algo_intent_search_txt` | string | 算法意图改写后的搜索文本（`multimodal_intention_model_search_text`）；无对应后端日志时为 NULL |
| `audio_url` | string | 语音搜索音频 URL；非语音搜索用户为 NULL，来源于语音搜索 session 级指标表 |

### 维度：图片搜索上下文

| 字段 | 类型 | 说明 |
|------|------|------|
| `image_url` | string | 图片搜索使用的图片 URL，由 CDN 前缀拼接 ai_search_info 中的 md5 构成；非图片搜索时为 NULL |
| `image_bounding_box` | string | 图片搜索框选区域坐标，取自 `ai_search_info.box.box_xy`；非图片搜索时为 NULL |
| `last_md5` | string | 搜索 session 内最后一次图片搜索的图片 md5，取自 `srp_seq_info` 最后一个元素；session_id 为空时为 NULL |
| `last_box_xy` | array\<int\> | 搜索 session 内最后一次图片搜索的框选坐标数组；session_id 为空时为 NULL |
| `last_keyword` | string | 搜索 session 内最后一次搜索的关键词，取自 `srp_seq_info` 最后一个元素的 keyword 字段；session_id 为空时为 NULL |

### 维度：关键词属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword_type` | string | 关键词按近 30 天累计搜索量分位数划分的热度段：`0%-20%`（冷门词）、`20%-50%`、`50%-80%`、`80%-100%`（头部词）；关键词在 30 日指标表中无记录时为 NULL |
| `keyword_cluster` | string | 关键词所属聚类标识，来源于关键词维表；关键词无聚类时为 NULL |
| `level1_keyword_category` | string | 关键词一级品类分类，来源于关键词维表；关键词无品类时为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全表扫描，影响查询性能并可能超时。
- 本表每日 INSERT OVERWRITE，查询某日数据须指定 `local_date = 'yyyy-MM-dd'`，不支持跨日累计（无 `_td`/`_nd` 类型窗口）。

```sql
-- 推荐查询模式
WHERE grass_region = 'ID'
  AND local_date = '2025-05-16'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `keyword_type` | 分位段字符串标签，不可聚合求和；用于 GROUP BY 分层 |
| `exp_group_ids` | 数组类型，不可直接 SUM；统计实验组用户数应使用 `ARRAY_CONTAINS(exp_group_ids, <id>)` 过滤 |
| `last_box_xy` | 数组类型坐标，不可聚合；用于图片搜索框选区域的单行解析 |
| `image_url` / `audio_url` / `last_md5` | 标识性字段，不应聚合；可用于 IS NOT NULL 判断多模态覆盖率 |

### 数据范围与时效性

- 本表为 **日级快照**（`_1d` 后缀），不包含实时数据，通常在次日早间完成当日数据写入。
- 仅覆盖 `page_type IN ('global_search', 'search_in_pdp', 'search_prefill')` 的搜索曝光/浏览行为（`operation IN ('impression', 'view')`），不含点击行为。
- **本表仅包含参与 AB 实验的已登录用户**（INNER JOIN 实验分配表），不代表全体搜索用户，不适合计算全量搜索指标。
- `keyword_type` 基于近 30 天搜索量分位数（`time_range = 1`，全类型 `is_ads='__ALL__'`，`card_type='__ALL__'`），若关键词在 30 日指标表中无记录则为 NULL。
- `user_intention` 和 `algo_intent_search_txt` 仅对有后端日志（BE log）且 `multimodal_user_intention_info IS NOT NULL` 的请求有值。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户实验分组（exp_group_ids、exp_type），仅保留参与实验的已登录用户 |
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 获取多模态用户意图（user_intention）和算法意图改写文本（algo_intent_search_txt） |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索明细日志，提供 user_id、keyword、search_mid、search_session_id、ai_search_info 等核心字段 |
| `srdi_mart.dws_sr_data_warehouse_ai_search_wide_metrics_1d` | 获取图片搜索 session 级 srp_seq_info 序列，用于提取 last_md5、last_box_xy、last_keyword |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词维表，提供 level1_keyword_category、keyword_cluster |
| `srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d` | 关键词近 30 天搜索量分位数，用于计算 keyword_type |
| `srdi_mart.dws_sr_data_warehouse_voice_search_session_level_metrics_1d` | 语音搜索 session 级指标表，提供 audio_url |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search            ──┐
dwd_sr_data_warehouse_search_be_log     ──┤→ dwm_search_session_level（搜索session去重）
                                          │
dws_sr_data_warehouse_ai_search_wide_   ──┤→ srp_seq_info_last_element（图片搜索seq末尾元素）
  metrics_1d                             │
                                          ↓
                                       dws_user_keyword（含last图片信息，UNION session有/无）
                                          ↓
                                       dws_user_keyword_deduplicated（DISTINCT去重）
                                          │
dim_sr_data_warehouse_abtest_user_group ──┤→ user_exp_mapping（INNER JOIN，过滤非实验用户）
dim_sr_data_warehouse_keyword_di        ──┤→ dim_keyword（LEFT JOIN，关键词品类&聚类）
dws_sr_...search_keyword_level_metrics  ──┤→ dws_keyword（LEFT JOIN，关键词热度分位段）
dws_sr_...voice_search_session_level_  ──┤→ audio_url（LEFT JOIN，语音搜索URL）
  metrics_1d                             │
                                          ↓
                          INSERT OVERWRITE 目标表
```

### 关键步骤

1. **user_exp_mapping**（临时视图）：从实验分配表按 `scene_id=381 OR layer_id=4420` 过滤，聚合用户命中的所有实验组 ID，并按 layer_id 优先级归类 `exp_type`（4420 优先于 3763）。

2. **be_log**（临时视图）：从后端日志表提取每个 `request_id` 的最新用户意图和算法意图改写文本（`MAX` 聚合去重）。

3. **dwm_search_session_level**（临时视图）：从搜索明细日志关联后端日志，过滤曝光/浏览行为及指定 page_type，提取关键词（小写化）、search_mid、image_url、image_bounding_box 等字段。对 `request_id IS NOT NULL` 和 `request_id IS NULL` 两路数据分别处理后 UNION ALL（后者 user_intention 和 algo_intent_search_txt 置 NULL）。

4. **srp_seq_info_last_element**（临时视图）：从图片搜索宽表（`search_mid LIKE 'image%'`）按 session 聚合 srp_seq_info 数组，取最后一个元素（`ELEMENT_AT(..., -1)`），用于获取 session 内最后一次图片搜索的上下文。

5. **dws_user_keyword**（临时视图）：将 `dwm_search_session_level` 按 session_id 与 `srp_seq_info_last_element` LEFT JOIN，解析最后图片元素的 md5、box_xy、keyword；session_id 为空或 NULL 的数据单独 UNION ALL，相关字段置 NULL。

6. **dws_user_keyword_deduplicated**（临时视图）：对上步结果执行 `SELECT DISTINCT`，消除 UNION ALL 引入的重复行。

7. **dim_keyword**（临时视图）：从关键词日维表获取指定大区当日的品类和聚类信息。

8. **dws_keyword**（临时视图）：从近 30 日关键词指标表（`is_ads='__ALL__'`，`card_type='__ALL__'`，`time_range=1`）读取关键词搜索量累计分位数，映射为四段式 `keyword_type`。

9. **audio_url**（临时视图）：从语音搜索 session 表按 user_id 去重聚合，获取音频 URL。

10. **INSERT OVERWRITE**（最终写入）：以去重后的用户-关键词数据为主表，INNER JOIN 实验用户映射（过滤非实验用户），LEFT JOIN 关键词维表、关键词热度表、语音 URL 表，写入目标表当日当区分区。

### 注意事项

- **单 Writer，无并发冲突风险**：本表仅有 1 个 ETL 文件写入，不存在多 Writer 竞争问题。
- **实验用户限定**：最终 INSERT 使用 INNER JOIN 实验用户映射表，若某用户当日无实验分配记录则不会出现在本表，查询结果代表实验抽样集合而非全量搜索用户。
- **关键词维表为日维表**：`dim_sr_data_warehouse_keyword_di` 以 `local_date` 为分区，若关键词当日无维表数据，则 `level1_keyword_category`、`keyword_cluster` 为 NULL。
- **keyword_type 依赖 30 日窗口**：`dws_sr_data_warehouse_search_keyword_level_metrics_30d` 为近 30 天滚动窗口，新词或低频词可能无匹配记录，`keyword_type` 为 NULL 属正常现象，统计时应考虑 NULL 占比。
- **UNION ALL 去重**：步骤 3 和 5 均使用 UNION ALL 合并有/无 session_id 两路数据，步骤 6 通过 `SELECT DISTINCT` 进行最终去重，确保 user_id + keyword + search_mid 等维度组合的唯一性。
- **图片 URL 域名硬编码**：`image_url` 拼接使用固定 CDN 前缀 `https://search-dl-ws-latam.img.susercontent.com/`，该前缀与拉美（LATAM）区域相关，跨大区使用时需注意 URL 有效性。

---

*文档生成时间：2026-05-17*