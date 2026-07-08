<!-- ads-workspace-gdoc-sync: gdoc_id=1DzQQnxyYybWYLQYiUfYaT25vuYfbcuXGWQchYcjwD8o gdoc_url=https://docs.google.com/document/d/1DzQQnxyYybWYLQYiUfYaT25vuYfbcuXGWQchYcjwD8o/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_be_log

**分层：** DWD（明细数据层）
**主键：** `request_id` + `item_id`（推断，按去重逻辑 `rn = 1` 保留唯一行）
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（按 `local_hour` / `regional_hour` 分区写入）
**访问频次：** 16,264 次

---

## 业务描述

本表为搜索后端（Search Backend）明细日志的 DWD 层宽表，记录每次搜索请求中每个候选商品在后端各阶段（召回、粗排、精排、广告混排、ROI 定价等）的详细评分与业务属性。

**核心业务场景：**
- 搜索相关性与排序分析：追踪 ES 分、相关性分、CTR/CVR 预估、精排分等各阶段分值流转
- 广告混排分析：通过 `ads_mix_params` 字段获取广告混排参数，分析广告与自然结果的竞争关系
- ROI 策略分析：分析 ROI1/ROI2 维度的点击率预估、转化率预估、ECPM 等定价指标
- 预计达时效（EDT）分析：评估商品配送时效对搜索排序的影响
- 多模态搜索分析：分析图文混合搜索、ChatGPT 意图搜索等新型搜索场景
- 商品替换（VItem）分析：追踪虚拟商品替换、Refresh 商品替换等替换逻辑
- Query 改写与扩展分析：分析关键词改写、查询扩展对召回的影响

**适合回答的问题：**
- 某 keyword 下各商品在召回、排序阶段的分值分布是怎样的？
- 广告商品与自然商品的混排比例和 ECPM 差异如何？
- 某时间段内商品 EDT 过滤率（`filtered_by_unserviceable`）是多少？
- 多模态搜索场景下意图识别命中率如何？
- 特定 AB 实验（`ab_sign`）对搜索排序分值的影响？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），所有查询必须指定此分区 |
| `local_date` | date | 本地日期分区，以请求发生地的本地时区为准 |
| `local_hour` | int | 本地小时分区（0–23） |
| `regional_date` | date | 区域日期分区，以服务器区域时区为准 |
| `regional_hour` | int | 区域小时分区（0–23） |

### 维度：请求与会话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 搜索请求唯一标识，主键之一 |
| `session_id` | string | 用户前端会话 ID |
| `search_session_id` | string | 搜索会话 ID |
| `search_session_id_be` | string | 后端侧搜索会话 ID |
| `global_session_id` | string | 全局会话 ID，跨服务追踪用 |
| `live_session_id` | bigint | 直播场景会话 ID |
| `user_id` | bigint | 用户 ID |
| `backend_log_timestamp` | bigint | 后端日志时间戳（毫秒） |
| `receive_request_time` | bigint | 后端接收请求时间戳（毫秒） |

### 维度：搜索词与查询改写

| 字段 | 类型 | 说明 |
|---|---|---|
| `ori_keyword` | string | 用户原始搜索词 |
| `request_keyword` | string | 实际发送给后端的搜索词 |
| `rewrite_keyword` | string | 改写后的搜索词 |
| `rewrite_type` | int | 改写类型编码 |
| `request_sort_type` | string | 请求排序类型（综合、销量、价格等） |
| `query_expansion_info` | struct<expansion_type:int, expansion_keyword:array<string>> | 查询扩展信息，含扩展类型与扩展词列表 |
| `flt_intent_raw_query` | string | 意图过滤原始 Query |
| `flt_intent_new_query` | string | 意图过滤后的新 Query |
| `flt_intent_filter_list` | array<string> | 意图过滤命中的过滤项列表 |
| `flt_intent_disabled` | boolean | 意图过滤是否被禁用 |

### 维度：商品与店铺标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，主键之一 |
| `shop_id` | bigint | 店铺 ID |
| `item_unique_key` | string | 商品唯一键（用于跨区/跨类目去重） |
| `ritem_id` | bigint | 真实商品 ID（VItem 场景下的底层商品） |
| `rshop_id` | bigint | 真实店铺 ID |
| `rmodel_id` | bigint | 真实型号 ID |
| `vmodel_id` | bigint | 虚拟型号 ID |
| `video_id` | bigint | 关联视频 ID |
| `refreshed_item_id` | bigint | Refresh 替换后的商品 ID |
| `refreshed_item_position` | int | Refresh 替换商品在结果列表中的位置 |

### 维度：广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_id` | bigint | 广告计划 ID |
| `ads_id_for_ocpc` | bigint | oCPC 广告计划 ID |
| `ads_id_for_roi2` | bigint | ROI2 策略广告计划 ID |
| `ad_info` | string | 广告附加信息 |

### 维度：商品类型与标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_item_type` | string | 曝光商品类型 |
| `real_item_type_list` | array<string> | 商品真实类型列表 |
| `ctx_item_type` | int | 上下文商品类型编码 |
| `card_type` | string | 卡片类型（普通卡、大图卡等） |
| `label_name` | array<string> | 标签名称列表 |
| `label_text` | array<string> | 标签展示文本列表 |
| `biz_flag` | array<string> | 业务标记数组（多种业务属性标识） |
| `tc_rule_id` | bigint | 流量控制规则 ID |
| `tc_item_group_id` | string | 流量控制商品分组 ID |
| `tc_boost_weight` | string | 流量控制加权系数 |
| `tc_rule_array` | array<string> | 命中的流量控制规则数组 |
| `rule_ids` | array<int> | 命中的业务规则 ID 列表 |
| `effective_rule_ids` | array<int> | 最终生效的规则 ID 列表 |
| `search_page` | string | 搜索页面类型标识 |
| `downstream` | string | 下游系统标识 |

### 维度：AB 实验

| 字段 | 类型 | 说明 |
|---|---|---|
| `ab_sign` | array<int> | 命中的 AB 实验桶标识列表 |

### 维度：直播场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `live_intention_type` | int | 直播意图类型 |
| `live_relevance_score` | int | 直播相关性分 |

### 维度：多模态搜索

| 字段 | 类型 | 说明 |
|---|---|---|
| `multimodal_user_intention_info` | string | 多模态用户意图信息（JSON） |
| `multimodal_info_filter_groups` | string | 多模态信息过滤分组 |
| `multimodal_info_sort_type` | int | 多模态信息排序类型 |
| `multimodal_info_fallback_to_image_search` | boolean | 多模态是否降级为纯图片搜索 |
| `multimodal_origin_keyword` | string | 多模态原始关键词 |
| `multimodal_intention_model_search_text` | string | 多模态意图模型生成的搜索文本 |

### 维度：ChatGPT 搜索场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `chatgpt_conversation_id` | string | ChatGPT 对话 ID |
| `chatgpt_intent_type` | string | ChatGPT 意图类型 |
| `chatgpt_original_prompt` | string | 用户原始 Prompt |
| `chatgpt_search_query` | string | ChatGPT 转译后的搜索词 |
| `chatgpt_search_query_trans` | string | ChatGPT 搜索词翻译结果 |

### 维度：商品替换（VItem/Replacement）

| 字段 | 类型 | 说明 |
|---|---|---|
| `replaced_item_id` | bigint | 被替换的商品 ID |
| `has_replacement_candidate` | string | 是否有替换候选商品 |
| `eligible_to_replace` | string | 是否符合替换资格 |
| `cheapest_replacement` | string | 最低价替换商品信息（JSON 字符串） |
| `is_fake_replacement` | boolean | 是否为伪替换（由 `cheapest_replacement` JSON 字段 `is_fake_replacement` 解析得到） |
| `vitem_replacement` | string | 虚拟商品替换信息 |
| `vitem_info` | string | 虚拟商品信息 |
| `vitem_replacement_enabled` | boolean | 虚拟商品替换是否启用（当前 ETL 写入 NULL） |
| `is_vitem_replaced` | boolean | 虚拟商品是否已被替换（当前 ETL 写入 NULL） |
| `item_id_before_vitem_replacement` | bigint | 替换前的原始商品 ID（当前 ETL 写入 NULL） |
| `is_vitem_swap` | boolean | 是否为虚拟商品 Swap（当前 ETL 写入 NULL） |
| `final_vitem_info` | string | 最终虚拟商品信息（当前 ETL 写入 NULL） |
| `final_winner_ritem_info` | string | 最终胜出真实商品信息（当前 ETL 写入 NULL） |

### 维度：配送时效（EDT）

| 字段 | 类型 | 说明 |
|---|---|---|
| `edt_max` | int | 最大预计送达时间（天） |
| `edt_max_hours` | int | 最大预计送达时间（小时） |
| `edt_max_mins` | int | 最大预计送达时间（分钟） |
| `edt_min` | int | 最短预计送达时间（天） |
| `edt_min_hours` | int | 最短预计送达时间（小时） |
| `edt_min_mins` | int | 最短预计送达时间（分钟） |
| `calc_edt_max` | int | 计算得到的最大 EDT（天） |
| `calc_edt_max_hours` | int | 计算得到的最大 EDT（小时） |
| `estimated_delivery_time_text` | string | 预计送达时间展示文本 |
| `fastest_channel_ids` | array<bigint> | 最快配送渠道 ID 列表 |
| `max_estimated_delivery_timestamp` | bigint | 最晚预计送达时间戳 |
| `min_estimated_delivery_timestamp` | bigint | 最早预计送达时间戳 |
| `filtered_by_unserviceable` | boolean | 是否因配送不可达被过滤 |

### 维度：其他页面与展示信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `dynamic_ui` | string | 动态 UI 配置信息 |
| `related_card` | string | 关联推荐卡片信息 |
| `is_nls_consult` | string | 是否为 NLS 咨询场景标记 |
| `price_filter_flag` | string | 价格过滤标记 |
| `mix_rank_model_type` | string | 混排模型类型标识 |
| `recall_item_tracking_info` | struct<ruleid:array<int>, matched_keywords:array<string>> | 召回追踪信息，含命中规则 ID 和匹配关键词列表 |

### 指标：召回与排序分

| 字段 | 类型 | 说明 |
|---|---|---|
| `es_score` | double | Elasticsearch 召回相关性分 |
| `recall_rank` | int | 召回阶段排名 |
| `merge_rank` | int | 合并排序阶段排名 |
| `rank_rank` | int | 精排阶段排名 |
| `rank_score` | double | 精排综合分 |
| `mix_score` | double | 混排综合分 |
| `ads_mix_rank_score` | double | 广告混排综合分 |
| `offset` | int | 商品在返回结果中的偏移位置 |
| `location` | bigint | 商品位置标识 |
| `ori_total_count` | bigint | 原始召回总数 |
| `total_count` | bigint | 最终返回总数 |

### 指标：相关性分

| 字段 | 类型 | 说明 |
|---|---|---|
| `rel_add` | double | 相关性附加分 |
| `rel_lx` | int | 相关性级别（LX 分级） |
| `rel_lx_score` | int | 相关性 LX 分值 |
| `rel_raw` | double | 相关性原始分 |
| `rel_raw_score` | double | 相关性原始分（另一来源） |

### 指标：CTR / CVR 预估

| 字段 | 类型 | 说明 |
|---|---|---|
| `ctr_score` | double | 自然搜索 CTR 预估分 |
| `cvr_score` | double | 自然搜索 CVR 预估分 |
| `pctr_for_roi1` | double | ROI1 策略 pCTR 预估 |
| `pcr_for_roi1` | double | ROI1 策略 pCR（转化率）预估 |
| `pctr_for_roi2` | double | ROI2 策略 pCTR 预估 |
| `pcr_for_roi2` | double | ROI2 策略 pCR 预估 |
| `broad_pcr_for_roi2` | double | ROI2 宽口径 pCR 预估 |
| `porg_for_roi2` | double | ROI2 自然 pORG 预估 |

### 指标：广告 ROI2 定价

| 字段 | 类型 | 说明 |
|---|---|---|
| `ecpm_for_roi2` | double | ROI2 eCPM 值 |
| `ecpm_weight_for_roi2` | double | ROI2 eCPM 权重系数 |
| `roi2_rank_score_for_roi2` | double | ROI2 精排分 |
| `roi2_rank_rank_for_roi2` | int | ROI2 精排排名 |

### 指标：直播场景评分

| 字段 | 类型 | 说明 |
|---|---|---|
| `live_biz_value_score` | double | 直播业务价值分 |
| `live_ctcvr_score` | double | 直播 CT-CVR 预估分 |

### 指标：广告混排（已废弃，建议从 ads_mix_params 取值）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_organic_value_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `ads_rank_bid_for_ads_mix` | bigint | **已废弃**，请从 `ads_mix_params` 取值 |
| `ads_rank_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `alpha_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `boosting_rule_weight` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `ctr_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `cvr_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `ecpm_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `ecpm_weight_for_ads_mix` | int | **已废弃**，请参考 `ecpm_weight_for_ads_mix_v2` |
| `ecpm_weight_for_ads_mix_v2` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `eval_ads_organic_value_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `eval_search_organic_value_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `is_ads_for_ads_mix` | int | **已废弃**，请从 `ads_mix_params` 取值 |
| `item_ads_pay_impr_1d_for_ads_mix` | bigint | **已废弃**，请从 `ads_mix_params` 取值 |
| `item_avg_pay_price_usd_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `item_type_for_ads_mix` | int | **已废弃**，请从 `ads_mix_params` 取值 |
| `merge_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `mix_rank_model_score` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `mix_rank_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `model_pid` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `org_roi2_mix_rank_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `pctr_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `pid_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `real_ads_ecpm_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `real_ads_rank_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `rel_add_score` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `rel_lx_mixrank_score_for_ads_mix` | int | **已废弃**，请从 `ads_mix_params` 取值 |
| `rel_qcp_all_added_score` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `rel_qcp_el_added_score` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `rel_tag_match_added_score` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `stage2_ads_rank_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `stage2_org_addbuff_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |
| `stage2_org_rank_score_for_ads_mix` | double | **已废弃**，请从 `ads_mix_params` 取值 |

### 指标：汇总参数包

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_mix_params` | string | 广告混排参数 JSON 包，包含所有 `*_for_ads_mix` 废弃字段的最新值，优先使用此字段 |
| `request_level_mix_params` | string | 请求级别混排参数 JSON 包 |

### 指标：价格相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `mock_deduction_price` | bigint | 模拟扣费价格（广告出价模拟，单位分） |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：所有查询必须指定，该字段为第一分区键，缺失将导致全表扫描。
   ```sql
   WHERE grass_region = 'SG'
   ```
2. **`local_date` 或 `regional_date`**：小时级分区表，务必同时限定日期分区，避免跨天全量扫描。
   ```sql
   AND local_date = '2024-01-01' AND local_hour = 10
   ```
3. **建议同时指定 `local_hour` / `regional_hour`**：表为小时粒度分区，不指定小时将读取整天所有小时分区。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `ctr_score`、`cvr_score`、`pctr_for_roi1/2`、`pcr_for_roi1/2` | 预估概率值（0–1 区间），需用 AVG 或加权求和，不可直接累加 |
| `ecpm_for_roi2`、`ecpm_weight_for_roi2` | 单次预估值，直接 SUM 无业务意义 |
| `rank_score`、`mix_score`、`ads_mix_rank_score`、`es_score`、`rel_raw` 等所有评分字段 | 模型打分，只适合对比分布，不适合 SUM |
| `rel_lx`、`rel_lx_score` | 分级/评分枚举，直接 SUM 无意义 |
| `roi2_rank_rank_for_roi2`、`recall_rank`、`merge_rank`、`rank_rank` | 排名值，不可 SUM |
| `ads_mix_params`、`request_level_mix_params` | JSON 字符串，需先解析后再聚合对应子字段 |

### 已废弃字段注意事项

- 所有 `*_for_ads_mix` 系列的独立列（`ads_rank_score_for_ads_mix`、`ecpm_for_ads_mix` 等）在当前 ETL 中均写入 `NULL`，**禁止用于任何分析**。
- 请统一使用 `ads_mix_params` JSON 字段并通过 `GET_JSON_OBJECT` 解析所需子字段。

### 时效性说明

- 本表为**小时级分区表**，数据在每个小时完成后经 ETL 写入，存在一定延迟（通常 T+1～T+2 小时）。
- 不包含累计（`*_td`）或滚动窗口（`*_nd`）字段，所有指标均为**单次请求明细值**，需要按需在查询层聚合。
- `local_date`/`local_hour` 与 `regional_date`/`regional_hour` 可能因时区差异不一致，分析时注意选择统一的时区口径。

### 去重逻辑

- ETL 通过 `WHERE rn = 1`（基于 `search_be_log_exploded_w_rn`）对上游数据去重，保证 `(request_id, item_id)` 在同一分区内唯一。即便如此，跨分区 JOIN 时仍需注意不要产生重复计数。

---

## 数据来源

| 上游表/视图 | 用途 |
|---|---|
| `search_be_log_exploded_w_rn`（临时视图） | ETL 入口临时视图，由上游 ODS 层搜索后端日志展开并排序去重（row_number = 1）后得到，实际源头对应 `search_data.ods_search_intel_log_v2_1h_raw` 及 `search_data.ods_search_intel_log_1h` 等搜索后端原始日志表 |

---

## ETL 逻辑摘要

### 数据流

```
search_data.ods_search_intel_log_*（搜索后端原始日志）
    └──> search_be_log_exploded_w_rn（临时视图：展开商品列表 + row_number 去重）
            └──> srdi_mart.dwd_sr_data_warehouse_search_be_log（INSERT OVERWRITE 按小时分区写入）
```

### 关键步骤

1. **临时视图构建（`search_be_log_exploded_w_rn`）**
   - 对搜索后端日志进行商品维度展开（一条请求日志 → 多条商品明细）。
   - 使用 `ROW_NUMBER()` 对 `(request_id, item_id)` 去重，取 `rn = 1` 保留第一条。
   - 计算 `local_date`、`local_hour`、`regional_date`、`regional_hour` 分区字段。

2. **字段清洗与派生**
   - `is_fake_replacement`：由 `CAST(FROM_JSON(cheapest_replacement, 'STRUCT<is_fake_replacement:BOOLEAN>').is_fake_replacement AS BOOLEAN)` 从 `cheapest_replacement` JSON 字段解析得到。
   - 所有 `*_for_ads_mix` 独立列（历史冗余字段）：ETL 显式写入 `NULL`，以 `ads_mix_params` JSON 字段替代。
   - VItem 相关新字段（`vitem_replacement_enabled`、`is_vitem_replaced`、`item_id_before_vitem_replacement`、`is_vitem_swap`、`final_vitem_info`、`final_winner_ritem_info`）：当前 ETL 写入 `NULL`，待后续逻辑补充。
   - `model_pid`、`mix_rank_model_score`、`boosting_rule_weight`：同样写入 `NULL`。

3. **目标表写入**
   - 使用 `INSERT OVERWRITE TABLE ... PARTITION(grass_region = ${grass_region}, local_date, local_hour, regional_date, regional_hour)` 动态分区覆盖写入。
   - 仅写入 `grass_region IN (${grass_region})` 对应的分区，支持按大区参数化执行。

### 注意事项

- **单 Writer 模式**：本表仅有一个 ETL 文件（`multi_writer = false`），不存在多文件并发写入同一分区的风险。
- **动态分区覆盖**：每次执行会覆盖指定 `grass_region` 下对应小时分区的全部数据，重跑时无需手动清理分区。
- **大量 NULL 字段**：约 30+ 个 `*_for_ads_mix` 废弃字段及部分 VItem 新字段当前均为 NULL，下游使用前需确认字段可用性，避免误用空值字段导致分析失真。
- **JSON 字段解析成本**：`ads_mix_params` 和 `request_level_mix_params` 为 JSON 字符串，频繁的 `GET_JSON_OBJECT` 解析在大规模查询中性能开销较高，建议在下游 DWS 层预先拍平关键子字段。
- **分区键时区双轨制**：同时维护 `local_*` 和 `regional_*` 两套时区分区，查询时需在业务层统一口径，避免混用导致数据重叠或遗漏。

---

*文档生成时间：2026-05-17*