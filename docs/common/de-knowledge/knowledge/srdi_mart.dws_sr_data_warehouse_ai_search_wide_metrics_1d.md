<!-- ads-workspace-gdoc-sync: gdoc_id=1SitRUcvAzr19WcR_vdxRZG4AomZmA6vDZYbQFhZfQ3I gdoc_url=https://docs.google.com/document/d/1SitRUcvAzr19WcR_vdxRZG4AomZmA6vDZYbQFhZfQ3I/edit -->

# srdi_mart.dws_sr_data_warehouse_ai_search_wide_metrics_1d

**分层：** dws_search  
**主键：** user_id + srp_request_id + inner_request_id + item_id + page_type + page_section + target_type + is_ads + srp_location + inner_location + global_session_id + search_session_id + keyword + title + minifeed_llm_query + minifeed_inner_card_type + topic_text + topic_location（宽表，无单一主键，行粒度为各 AI 搜索功能的事件聚合行）  
**分区：** `grass_region`（站点）、`local_date`（业务日期）  
**更新频率：** 每日一次（T+1 覆盖写）  
**引用频次 / 访问频次：** 3285

---

## 业务描述

本表是 Shopee 搜索推荐数仓中专门面向 **AI 搜索功能** 的日粒度宽指标表，汇聚了搜索结果页（SRP）上各类 AI 增强功能的曝光、点击、下单及 GMV 数据，涵盖以下核心场景：

| 功能模块 | 说明 |
|---|---|
| **LLM Deepthinking（深度思考）** | 大模型对搜索词的意图理解、关键词抽取、用户画像分析及召回物品列表 |
| **LLM Filter（LLM 过滤器）** | 用户在搜索结果页使用 LLM 驱动的筛选标签时的行为 |
| **Autocomplete（智能补全）** | LLM 驱动的搜索框搜索建议被点击后跳转到搜索结果页的行为 |
| **Related Search LLM Card（LLM 相关搜索卡片）** | SRP 中 LLM 生成的相关搜索推荐卡片的曝光与点击 |
| **AI Minifeed Card（AI 信息流卡片）** | 嵌入 SRP 中的 AI 视频/商品混合信息流卡片的内容行为 |
| **AI Topic Card（AI 话题卡片）** | SRP 话题卡片及其跳转至 `ai_topic_landing` 页后的商品行为 |
| **Multimodal Search（多模态/图像搜索）** | 用户使用图片发起搜索时的检索和商品交互行为 |

**适合回答的典型问题：**
- 各 AI 搜索功能的日活覆盖率、点击率、转化率和 GMV 贡献
- LLM Deepthinking 关键词抽取效果及召回物品分布
- AI Minifeed Card / AI Topic Card 内部商品的点击与成交
- 多模态图像搜索的意图识别（`mm_search_intent_type`）和图片定位（`box_xy`）
- 智能补全（Autocomplete）对下游搜索会话的 GMV 贡献
- 各 AI 功能之间的叠加/共现情况（多个 AI 功能字段可同时不为 NULL）

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点标识，如 `SG`、`MY`、`TH` 等，每次 ETL 按站点独立分区覆盖写 |
| `local_date` | date | 业务日期（按目标站点时区转换后的本地日期），格式 `yyyy-MM-dd` |

---

### 维度：用户与会话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；来自 LLM Deepthinking 的纯元数据行该字段为 NULL |
| `global_session_id` | string | 全局会话 ID，跨页面标识一次用户访问会话 |
| `search_session_id` | string | 搜索会话 ID，标识一次搜索行为链路 |
| `srp_request_id` | string | SRP 请求 ID，标识一次搜索结果页请求 |
| `inner_request_id` | string | AI Minifeed Card / AI Topic Card 内部子请求 ID，非 AI 信息流场景为 NULL |

---

### 维度：页面与内容定位

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_type` | string | 页面类型，如 `global_search`、`search_in_pdp`、`search_prefill`、`video`、`ai_topic_landing` |
| `page_section` | string | 页面区块，如 `topic_result`；大多数场景为 NULL |
| `target_type` | string | 交互目标类型，如 `item`、`video`、`related_search`、`ai_minifeed_card`、`ai_topic_card` 等 |
| `srp_location` | int | 目标内容在 SRP 中的位置序号 |
| `inner_location` | int | 目标内容在 AI Minifeed Card / AI Topic Card 内部的位置序号 |
| `is_ads` | boolean | 是否为广告物品 |

---

### 维度：搜索词与入口

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 用户搜索词 |
| `request_keyword` | string | 后端实际请求关键词（来自 `dwd_sr_data_warehouse_search_be_log`），可能经过改写 |
| `search_entrance` | string | 搜索入口标识，如搜索框、扫一扫等 |
| `last_entrance` | string | 当前版本恒为 NULL，预留字段（AI Mode 功能） |

---

### 维度：商品与内容标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID；纯维度行（Deepthinking 元数据）为 NULL |
| `title` | string | AI 卡片标题；Minifeed Card 时为 `ai_minifeed_card_title`，Topic Card 时为 `ai_topic_srp_title` |
| `title_text` | string | 商品或内容原始标题文本 |
| `content_id` | string | 内容 ID（视频等富媒体内容标识） |
| `image_id` | string | 图片 ID |

---

### 维度：AI Minifeed Card 相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `minifeed_llm_query` | string | AI Minifeed Card 关联的 LLM 改写查询词（`llm_rewrite_keyword`） |
| `minifeed_inner_card_type` | string | Minifeed 内部卡片类型：`item_card`（商品卡）或 `video_card`（视频卡） |
| `minifeed_ui_type` | int | Minifeed 卡片 UI 类型，来自 `ai_search_info.minifeed_ui_type` |
| `click_area` | int | 用户点击区域标识，来自 `ai_search_info.click_area` |

---

### 维度：AI Topic Card 相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `topic_text` | string | AI 话题卡片的话题文本标题 |
| `topic_location` | int | 话题在 SRP 中的展示位置 |
| `topic_summary` | string | AI 话题摘要文本（来自 `fe_header_ai_summary`） |
| `topic_image_id` | string | AI 话题卡片封面图片 ID |
| `topic_impressed_keyword` | string | AI 话题卡片曝光时的关联关键词（`ai_topic_impressed_keyword`） |
| `topic_clicked_keyword` | string | AI 话题卡片点击时的关联关键词（`ai_topic_clicked_keyword`） |

---

### 维度：LLM Deepthinking 相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_llm_deepthinking` | boolean | 该请求是否触发了 LLM Deepthinking 能力 |
| `llm_keyword_extraction` | array\<string\> | LLM 从用户 query 中抽取的关键词列表（取二维数组第一维首元素） |
| `llm_user_profile` | string | LLM 推断的用户画像描述 |
| `llm_demand_analysis` | string | LLM 对用户搜索需求的分析结果（`demand_analysis`） |
| `llm_item_list` | array\<struct\<item_id:bigint,shop_id:bigint,search_query:string\>\> | LLM Deepthinking 召回并经过筛选排序后的推荐物品列表 |

---

### 维度：LLM Filter 相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_llm_filtered` | boolean | 当前请求是否使用了 LLM 过滤器（`filter_type = 3`） |
| `filter_groups` | string | 多模态搜索后端日志中的过滤分组信息（`multimodal_info_filter_groups`） |
| `sort_type` | int | 多模态搜索排序类型（`multimodal_info_sort_type`） |

---

### 维度：Related Search LLM Card 相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_from_llm_rs` | boolean | 该行是否来自 LLM 相关搜索卡片（`rs_is_llm_card`） |
| `rs_impressed_keyword` | string | LLM 相关搜索卡片曝光时展示的关键词 |
| `rs_clicked_keyword` | string | LLM 相关搜索卡片被点击时的关键词 |

---

### 维度：Autocomplete 相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `autocomplete_queue` | int | 用户使用 LLM 智能补全（`hint_keyword_source IN (18, 19)`）后进入搜索结果页的补全来源类型；通过 `search_session_id` 关联，不触发时为 NULL |

---

### 维度：多模态图像搜索相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_mid` | string | 搜索媒体 ID，图像搜索时以 `image` 开头 |
| `ms_image_url` | string | 多模态搜索上传图片的完整 URL，格式为 `https://search-dl-ws-latam.img.susercontent.com/{md5}` |
| `ms_image_bounding_box` | string | 多模态搜索图片框选区域原始 JSON 字符串（`{}`时置 NULL） |
| `md5` | string | 多模态搜索图片的 MD5 哈希值（即原始 `ai_search_info.md5`） |
| `box_xy` | array\<int\> | 图片裁剪框坐标，格式 `[left, top, width, height]`，由 `ms_image_bounding_box` 解析而来 |
| `box_id` | int | 框选框 ID，从 `ms_image_bounding_box.boxId` 解析（ETL 中以 DOUBLE cast，DataMap 类型为 int） |
| `box_score` | double | 框选框置信度分数，从 `ms_image_bounding_box.score` 解析 |
| `fallback_to_image_search` | boolean | 多模态搜索是否回退到纯图像搜索（来自后端日志） |
| `algo_intent_search_txt` | string | 算法推断的多模态搜索意图文本（`multimodal_intention_model_search_text`） |
| `mm_search_intent_type` | string | 多模态搜索用户意图类型（来自 `ai_search_info.mm_search_intent_type`） |
| `srp_seq_info` | array\<string\> | 多模态图像搜索会话内的历史请求序列（含 keyword、mid、md5、box_xy、view_timestamp），按时间升序排列，每个元素为 JSON 字符串 |

---

### 维度：算法召回质量（来自搜索后端日志）

| 字段 | 类型 | 说明 |
|---|---|---|
| `rel_lx` | int | 相关性等级分（来自 `dwd_sr_data_warehouse_search_be_log.rel_lx`） |
| `recall_score` | double | 召回分（`es_score`），来自后端日志 |
| `rel_raw_score` | double | 相关性原始分（`rel_raw_score`），来自后端日志 |

---

### 维度：Query 改写与扩展（预留）

| 字段 | 类型 | 说明 |
|---|---|---|
| `qp_query_expansion` | string | QP 查询扩展词，当前版本 ETL 中恒为 NULL，预留字段 |

---

### 维度：AI Mode 相关（预留）

> 以下字段在当前 ETL 版本中均写入 NULL，为 AI Mode 功能预留扩展字段。

| 字段 | 类型 | 说明 |
|---|---|---|
| `ai_mode_session_id` | string | AI Mode 会话 ID（预留，当前为 NULL） |
| `ai_mode_bubble_id` | string | AI Mode 气泡 ID（预留，当前为 NULL） |
| `ai_mode_bubble_index` | int | AI Mode 气泡序号（预留，当前为 NULL） |
| `ai_mode_item_location` | int | AI Mode 内商品位置（预留，当前为 NULL） |
| `ai_mode_keyword` | string | AI Mode 触发关键词（预留，当前为 NULL） |
| `ai_mode_hook_text` | string | AI Mode 钩子文本（预留，当前为 NULL） |
| `ai_mode_impressed_text` | array\<string\> | AI Mode 曝光文本列表（预留，当前为 NULL） |
| `ai_mode_impressed_text_array` | array\<string\> | AI Mode 曝光文本数组（预留，当前为 NULL） |
| `ai_mode_rendered_text` | array\<string\> | AI Mode 渲染文本列表（预留，当前为 NULL） |
| `ai_mode_rendered_text_array` | array\<string\> | AI Mode 渲染文本数组（预留，当前为 NULL） |
| `ai_mode_keywords_array` | array\<string\> | AI Mode 关键词数组（预留，当前为 NULL） |
| `ai_mode_duration` | bigint | AI Mode 持续时长（预留，当前为 NULL） |
| `ai_mode_overtime_thresh` | bigint | AI Mode 超时阈值（预留，当前为 NULL） |
| `ai_mode_impressed_text_array` | array\<string\> | （同上，参见 DataMap 字段列表） |
| `is_fully_rendered` | boolean | AI Mode 是否完全渲染（预留，当前为 NULL） |
| `feedback_type` | string | AI Mode 用户反馈类型（预留，当前为 NULL） |
| `prev_selected_status` | string | AI Mode 上一次选中状态（预留，当前为 NULL） |
| `error_type` | string | AI Mode 错误类型（预留，当前为 NULL） |

---

### 维度：时间戳（预留）

> 以下时间戳字段当前 ETL 均写入 NULL，为 AI Mode 功能预留。

| 字段 | 类型 | 说明 |
|---|---|---|
| `event_timestamp` | bigint | 事件时间戳（预留，当前为 NULL） |
| `rnd_start_timestamp` | bigint | 渲染开始时间戳（预留，当前为 NULL） |
| `rnd_end_timestamp` | bigint | 渲染结束时间戳（预留，当前为 NULL） |
| `see_more_timestamp` | bigint | "查看更多"操作时间戳（预留，当前为 NULL） |
| `dismiss_timestamp` | bigint | 关闭/消除操作时间戳（预留，当前为 NULL） |
| `receive_start_timestamp` | bigint | 接收开始时间戳（预留，当前为 NULL） |
| `receive_end_timestamp` | bigint | 接收结束时间戳（预留，当前为 NULL） |

---

### 指标：核心行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数，由 `operation = 'impression'` 的 `operation_cnt` 累加得到 |
| `click_cnt` | bigint | 点击次数，由 `operation = 'click'` 的 `operation_cnt` 累加得到 |
| `order_cnt` | double | 订单数，由 `operation = 'order'` 的 `operation_cnt` 累加得到 |

---

### 指标：交易价值指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 下单 GMV（`place_order_gmv`），仅统计 `operation = 'order'` 的记录 |
| `pc2_gmv` | double | PC2 口径 GMV，仅统计 `operation = 'order'` 的记录 |

---


### 维度：自动校验补齐

以下字段由生成后字段覆盖率校验补齐，字段存在和类型以 DataMap snapshot 为准。

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_filter` | array<string> | DataMap 字段，原始描述为空 |

## 查询使用须知

### 必须包含的过滤条件

```sql
WHERE grass_region = 'SG'        -- 必须指定站点
  AND local_date = '2025-05-16'  -- 必须指定日期，避免全量扫描
```

两个分区字段均为**必填过滤条件**，缺失任一将导致全分区扫描，查询性能极差。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `recall_score`、`rel_raw_score`、`box_score` | 为单行维度值，不能跨行 SUM，应使用 MAX/AVG 等聚合 |
| `box_id`、`rel_lx`、`sort_type` | 维度标识或分级字段，不应直接 SUM |
| `srp_seq_info` | Array 类型，直接聚合无意义，需 EXPLODE 后使用 |
| `llm_item_list`、`llm_keyword_extraction` | Array/Struct 复杂类型，需 EXPLODE/LATERAL VIEW 展开 |
| `box_xy` | Array 类型坐标，不可直接 SUM |
| `autocomplete_queue` | 为枚举类型标识（来源类型），不应累加 |

### 多 AI 功能字段可同时不为 NULL

各 AI 功能（Deepthinking、LLM Filter、Autocomplete、Related Search、Minifeed、Topic Card、多模态搜索）在设计上**允许相互叠加**（ETL SQL 注释明确说明 `Each ai_search feature can overlap with one another`）。分析单一功能时，务必按对应字段精确过滤：

```sql
-- 仅分析 Deepthinking
WHERE is_llm_deepthinking = TRUE

-- 仅分析 AI Minifeed Card
WHERE target_type = 'ai_minifeed_card'

-- 仅分析多模态图像搜索
WHERE search_mid LIKE 'image%'
```

### AI Mode 预留字段

`ai_mode_*`、`rnd_*_timestamp`、`receive_*_timestamp`、`see_more_timestamp`、`dismiss_timestamp`、`event_timestamp`、`is_fully_rendered`、`feedback_type`、`prev_selected_status`、`error_type`、`last_entrance`、`qp_query_expansion` 当前版本 ETL 均写入 NULL，**不应在生产指标统计中使用**。

### LLM Deepthinking 元数据行

来自 `ods_sr_data_warehouse_search_llm_deepthinking_recall__reg_continuous_s0_live` 的 Deepthinking 元数据，以单独的 UNION 分支插入，该类行的 `user_id`、`item_id`、`operation`、`gmv` 等字段均为 NULL。统计用户/商品级指标时应过滤：

```sql
WHERE user_id IS NOT NULL
  AND item_id IS NOT NULL
```

### 时效性

本表为 **T+1 日级** 表，每日凌晨覆盖写前一日分区，不提供实时或小时级数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 核心事件表，提供 SRP 曝光、点击、下单事件及 AI 搜索特征字段（含 source1/source2 归因链路） |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索会话维度表，用于 Deepthinking 的 `request_id` 与 `search_session_id` 关联 |
| `srdi_mart.ods_sr_data_warehouse_search_llm_deepthinking_recall__reg_continuous_s0_live` | LLM Deepthinking 原始召回日志，提供关键词抽取、用户画像、需求分析及物品列表 |
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 搜索后端日志，提供相关性分（`rel_lx`、`rel_raw_score`）、召回分（`es_score`）、多模态排序/过滤字段 |
| `mp_foa.dim_search_domain_map__reg_live` | 搜索域名映射维表，用于 Autocomplete 场景下搜索页面类型的规范化映射 |

---

## ETL 逻辑摘要

### 数据流

```
ods_sr_data_warehouse_search_llm_deepthinking_recall  ──┐
dwd_sr_data_warehouse_search                            ─┤
dwd_sr_data_warehouse_platform (主事件/source1/source2) ─┼──► combined_dwd_data ──► dwm_agg_data ──┐
mp_foa.dim_search_domain_map__reg_live                  ─┤                                          │
                                                          ┘                                          ├──► INSERT OVERWRITE
dwd_sr_data_warehouse_search_be_log ──────────────────────── search_be_log_dims_deduplicate ────────┤
dwd_sr_data_warehouse_platform (view events) ─────────────── multimodal_seq_info_* ────────────────┘
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `ods_llm_deepthinking_*` | 从 LLM Deepthinking 服务日志提取关键词抽取、用户画像、需求分析和召回物品列表，按时区过滤后与搜索会话关联 |
| 2 | `autocomplete_click_*` | 筛选 `hint_keyword_source IN (18, 19)` 的搜索建议点击事件 |
| 3 | `search_mapped_page_types_*` | 从维表获取站点对应的合法搜索页面类型列表 |
| 4 | `autocomplete_filter_*` | 将 Autocomplete 点击与后续搜索结果页关联，得到 `search_session_id` → `autocomplete_queue` 的映射 |
| 5 | `dwd_data_*` | 从 `dwd_sr_data_warehouse_platform` 三路 UNION（主路径 + source1 + source2 归因链路）提取各 AI 功能的事件行，过滤条件为 6 类 AI 功能的 OR 组合 |
| 6 | `multimodal_search_dims_deduplicate_*` | 按 `(srp_request_id, item_id)` 去重，提取多模态图片 URL 和框选坐标 |
| 7 | `srp_minifeed_dims_deduplicate_*` | 按 `(search_session_id, srp_request_id, srp_location)` 去重，提取 AI Minifeed Card 的维度信息 |
| 8 | `srp_ai_topic_click_dims_deduplicate_*` | 按 `(search_session_id, fe_module_title, srp_location)` 去重，提取 AI Topic Card 点击维度信息 |
| 9 | `srp_ai_topic_view_dims_deduplicate_*` | 从 `ai_topic_landing` 页面的 view 事件中展开 `fe_topic_navigation` 数组，获取话题摘要和图片 ID |
| 10 | `minifeed_data_*` | 从 `dwd_sr_data_warehouse_platform` 三路 UNION 提取 AI Minifeed Card 内部（`page_type = 'video'`）的商品曝光、点击、下单事件 |
| 11 | `ai_topic_data_*` | 从 `dwd_sr_data_warehouse_platform` 三路 UNION 提取 AI Topic Landing 页（`ai_topic_landing`）的商品交互事件 |
| 12 | `combined_dwd_data_*` | 将 `dwd_data_*`、`minifeed_data_*`（JOIN 维度表）、`ai_topic_data_*`（JOIN 维度表）及 `ods_llm_deepthinking_*`（元数据行）四路 UNION ALL 合并为统一的事件宽行 |
| 13 | `dwm_agg_data_*` | 对 `combined_dwd_data_*` 按全量维度列 GROUP BY，聚合计算 `click_cnt`、`imp_cnt`、`order_cnt`、`gmv`、`pc2_gmv`；同时 LEFT JOIN `autocomplete_filter_*` 补充 `autocomplete_queue` |
| 14 | `search_be_log_dims_deduplicate_*` | 从 `dwd_sr_data_warehouse_search_be_log` 按 `(request_id, item_id)` 去重，提取相关性分、召回分、多模态排序/过滤字段 |
| 15 | `multimodal_seq_info_ranked_*` → `multimodal_seq_info_filtered_*` → `multimodal_seq_info_exploded_*` → `multimodal_seq_info_enriched_*` | 多阶段处理：从 view 事件中取每个搜索会话的首次图像搜索记录 → 解析 `box_xy` → EXPLODE 历史请求序列 → 关联各子会话的 md5/box_xy，按时间戳升序重建完整搜索序列 `srp_seq_info` |
| 16 | **INSERT OVERWRITE** | 最终将 `dwm_agg_data_*` LEFT JOIN `search_be_log_dims_deduplicate_*`（按图像搜索条件）和 `multimodal_seq_info_enriched_*`（按 `search_session_id`）写入目标表分区，输出时对 `ms_image_url` 拼接域名前缀，对 `ms_image_bounding_box` 进行有效性判断，并将 `box_xy`、`box_id`、`box_score` 解析为结构化字段 |

### 注意事项

1. **单一 ETL 文件，单分区写入**：本表为 single-writer，每次按 `(grass_region, local_date)` 覆盖写，无多文件并发写入风险。
2. **AI 功能字段互相叠加**：ETL 注释明确说明各功能可以叠加，`combined_dwd_data_*` 使用 4 路 UNION ALL 合并，分析时务必按具体功能字段过滤，避免重复计数。
3. **Source1/Source2 归因链路**：`dwd_sr_data_warehouse_platform` 中的 `source1_*` 和 `source2_*` 字段用于跨页面订单归因，仅在 `operation = 'order'` 时纳入统计，不含曝光和点击事件。
4. **LLM Deepthinking 时区处理**：ODS 表数据按 UTC 存储，ETL 使用 `date_timezone_convert` 函数按目标站点时区过滤，同时查询前后各一天的分区以避免时区边界数据丢失。
5. **`ms_image_url` 域名差异**：ETL 对 LATAM 区域拼接了特定域名前缀，不同站点的图片域名可能不同，直接使用 `ms_image_url` 字段值时需注意。
6. **`box_id` 类型不一致**：ETL 中以 `CAST(...AS DOUBLE)` 解析，但 DataMap 声明为 `int`，实际存储为 int；查询时应注意精度。
7. **REPARTITION(200) 提示**：最终 INSERT 使用了 `/*+ REPARTITION(200) */` 以控制输出文件数量，表明该表数据量较大。

---

*文档生成时间：2026-05-17*