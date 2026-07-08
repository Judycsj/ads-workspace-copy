<!-- ads-workspace-gdoc-sync: gdoc_id=1ry_FvEI9ijJx1wsa4C1UtRcZ2CEExbANBgYHTgEvoUo gdoc_url=https://docs.google.com/document/d/1ry_FvEI9ijJx1wsa4C1UtRcZ2CEExbANBgYHTgEvoUo/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_chatgpt_be_log

**分层：** DWD（明细数据层）
**主键：** `request_id` + `item_id`（逻辑主键，标识一次 ChatGPT 搜索请求下的单条商品曝光记录）
**分区：** `grass_region`（静态分区）/ `local_date` / `local_hour` / `regional_date` / `regional_hour`（动态分区）
**更新频率：** 小时级（按 `local_hour` 分区写入，每小时覆盖刷新）
**引用频次/访问频次：** 42

---

## 业务描述

本表是 SRDI 搜推数仓中专门记录 **ChatGPT 搜索场景后端日志**的明细宽表（DWD 层）。数据来源于全量搜索后端日志表 `srdi_mart.dwd_sr_data_warehouse_search_be_log`，通过过滤 `search_page = 'CHATGPT_SEARCH'` 得到，仅保留用户通过 ChatGPT 入口发起搜索时所产生的每一条商品曝光/排序记录。

**核心业务场景：**
- 分析 ChatGPT 搜索流量的规模、趋势及区域分布
- 评估 ChatGPT 搜索场景下搜索词改写、意图识别、多模态召回等算法效果
- 分析 ChatGPT 会话（`chatgpt_conversation_id`）维度的搜索行为链路
- 排查广告混排（ads mix）、ROI 模型、替换商品（vitem replacement）等策略在 ChatGPT 场景中的表现
- 评估预计达时间（EDT）、不可服务过滤等供给侧约束对 ChatGPT 搜索结果的影响

**适合回答的问题：**
- ChatGPT 搜索场景下，各区域每小时的请求量、商品曝光量是多少？
- ChatGPT 的意图类型（`chatgpt_intent_type`）分布及对应的召回/排序分数如何？
- ChatGPT 搜索词（`chatgpt_search_query`）与实际请求词（`request_keyword`）的改写差异如何？
- 广告混排、ROI2 策略在 ChatGPT 搜索场景中的渗透率和效果如何？
- vitem 替换策略在 ChatGPT 场景中的触发情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），静态分区，每次写入需指定 |
| `local_date` | date | 请求的本地日期（动态分区） |
| `local_hour` | int | 请求的本地小时（动态分区，0–23） |
| `regional_date` | date | 区域日期（动态分区，与 local_date 含义对应不同时区口径） |
| `regional_hour` | int | 区域小时（动态分区，0–23） |

---

### 维度：请求与会话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 搜索请求唯一标识，逻辑主键之一 |
| `session_id` | string | 用户会话 ID |
| `search_session_id` | string | 搜索会话 ID |
| `search_session_id_be` | string | 后端视角的搜索会话 ID |
| `global_session_id` | string | 全局会话 ID，跨服务链路追踪 |
| `backend_log_timestamp` | bigint | 后端日志写入时间戳（毫秒级 Unix 时间戳） |
| `receive_request_time` | bigint | 后端接收到请求的时间戳（毫秒级 Unix 时间戳） |

---

### 维度：ChatGPT 搜索专属信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `chatgpt_conversation_id` | string | ChatGPT 对话 ID，标识一次 ChatGPT 会话 |
| `chatgpt_intent_type` | string | ChatGPT 识别的搜索意图类型 |
| `chatgpt_original_prompt` | string | 用户输入给 ChatGPT 的原始 Prompt |
| `chatgpt_search_query` | string | ChatGPT 转化后的搜索词 |
| `chatgpt_search_query_trans` | string | ChatGPT 搜索词的翻译结果 |
| `search_page` | string | 搜索页面来源，本表固定为 `CHATGPT_SEARCH` |

---

### 维度：用户与商品信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `item_id` | bigint | 商品 ID，逻辑主键之一 |
| `shop_id` | bigint | 店铺 ID |
| `item_unique_key` | string | 商品唯一键（区分同一 item_id 的不同上下文） |
| `video_id` | bigint | 关联视频 ID（直播/短视频场景） |

---

### 维度：搜索词与改写

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_keyword` | string | 后端接收到的请求搜索词 |
| `ori_keyword` | string | 原始搜索词（改写前） |
| `rewrite_keyword` | string | 改写后的搜索词 |
| `rewrite_type` | int | 改写类型枚举值 |
| `query_expansion_info` | struct\<expansion_type:int, expansion_keyword:array\<string\>\> | 查询扩展信息，包含扩展类型和扩展词列表 |
| `request_sort_type` | string | 请求的排序类型 |

---

### 维度：多模态意图

| 字段 | 类型 | 说明 |
|---|---|---|
| `multimodal_user_intention_info` | string | 多模态用户意图信息（JSON 序列化） |
| `multimodal_info_filter_groups` | string | 多模态过滤分组信息 |
| `multimodal_info_sort_type` | int | 多模态排序类型 |
| `multimodal_info_fallback_to_image_search` | boolean | 是否降级为图片搜索 |
| `multimodal_origin_keyword` | string | 多模态原始关键词 |
| `multimodal_intention_model_search_text` | string | 多模态意图模型输出的搜索文本 |

---

### 维度：意图过滤（flt_intent）

| 字段 | 类型 | 说明 |
|---|---|---|
| `flt_intent_disabled` | boolean | 意图过滤是否被禁用 |
| `flt_intent_filter_list` | array\<string\> | 意图过滤命中的过滤项列表 |
| `flt_intent_new_query` | string | 意图过滤后的新查询词 |
| `flt_intent_raw_query` | string | 意图过滤前的原始查询词 |

---

### 维度：直播信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `live_session_id` | bigint | 直播场次 ID |
| `live_intention_type` | int | 直播意图类型 |

---

### 维度：广告相关标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_id` | bigint | 广告 ID |
| `ads_id_for_ocpc` | bigint | OCPC 模式下的广告 ID |
| `ads_id_for_roi2` | bigint | ROI2 模式下的广告 ID |
| `ad_info` | string | 广告附加信息（JSON 序列化） |
| `is_ads_for_ads_mix` | int | 广告混排中是否为广告位（ETL 中固定写入 NULL，预留字段） |
| `is_ads_for_ads_mix` | int | 见上 |

---

### 维度：商品排序与召回位置

| 字段 | 类型 | 说明 |
|---|---|---|
| `recall_rank` | int | 召回阶段排名 |
| `merge_rank` | int | 合并排序阶段排名 |
| `rank_rank` | int | 精排阶段排名 |
| `location` | bigint | 商品在结果页中的位置 |
| `offset` | int | 请求的分页偏移量 |
| `ctx_item_type` | int | 上下文商品类型 |
| `imp_item_type` | string | 曝光商品类型 |
| `real_item_type_list` | array\<string\> | 实际商品类型列表 |
| `card_type` | string | 卡片类型 |
| `dynamic_ui` | string | 动态 UI 配置信息 |
| `related_card` | string | 关联卡片信息 |
| `downstream` | string | 下游服务标识 |

---

### 维度：规则与策略标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `tc_rule_id` | bigint | 流量控制规则 ID |
| `tc_item_group_id` | string | 流量控制商品分组 ID |
| `tc_boost_weight` | string | 流量控制加权权重 |
| `rule_ids` | array\<int\> | 命中的规则 ID 列表 |
| `effective_rule_ids` | array\<int\> | 实际生效的规则 ID 列表 |
| `ab_sign` | array\<int\> | A/B 实验分组标识列表 |

---

### 维度：vitem 替换策略

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_replacement_enabled` | boolean | 是否开启 vitem 替换功能 |
| `is_vitem_replaced` | boolean | 当前商品是否被 vitem 替换 |
| `is_vitem_swap` | boolean | 是否发生 vitem 换位 |
| `is_fake_replacement` | boolean | 是否为虚假替换（mock 场景） |
| `replaced_item_id` | bigint | 被替换的原始商品 ID |
| `item_id_before_vitem_replacement` | bigint | vitem 替换前的商品 ID |
| `has_replacement_candidate` | string | 是否存在替换候选商品 |
| `eligible_to_replace` | string | 当前商品是否具备替换资格 |
| `cheapest_replacement` | string | 最低价替换商品信息 |
| `ritem_id` | bigint | 替换商品 ID |
| `rshop_id` | bigint | 替换商品所属店铺 ID |
| `rmodel_id` | bigint | 替换商品的模型 ID |
| `vmodel_id` | bigint | 虚拟模型 ID |
| `final_vitem_info` | string | 最终 vitem 信息（JSON 序列化） |
| `final_winner_ritem_info` | string | 最终胜出的替换商品信息（JSON 序列化） |
| `refreshed_item_id` | bigint | 刷新后的商品 ID |
| `refreshed_item_position` | int | 刷新后的商品位置 |

---

### 维度：预计达时间（EDT）

| 字段 | 类型 | 说明 |
|---|---|---|
| `edt_max` | int | 预计最晚达时间（天） |
| `edt_max_hours` | int | 预计最晚达时间（小时） |
| `edt_max_mins` | int | 预计最晚达时间（分钟） |
| `edt_min` | int | 预计最早达时间（天） |
| `edt_min_hours` | int | 预计最早达时间（小时） |
| `edt_min_mins` | int | 预计最早达时间（分钟） |
| `calc_edt_max` | int | 计算得出的最晚 EDT（天） |
| `calc_edt_max_hours` | int | 计算得出的最晚 EDT（小时） |
| `estimated_delivery_time_text` | string | 预计达时间展示文案 |
| `fastest_channel_ids` | array\<bigint\> | 最快物流渠道 ID 列表 |
| `max_estimated_delivery_timestamp` | bigint | 最晚预计送达时间戳（毫秒） |
| `min_estimated_delivery_timestamp` | bigint | 最早预计送达时间戳（毫秒） |
| `filtered_by_unserviceable` | boolean | 是否因不可配送被过滤 |

---

### 维度：其他业务字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_nls_consult` | string | 是否为 NLS 咨询请求 |
| `price_filter_flag` | string | 价格过滤标志 |
| `ads_mix_params` | string | 广告混排参数（JSON 序列化） |
| `request_level_mix_params` | string | 请求级别混排参数（JSON 序列化） |
| `mix_rank_model_type` | string | 混排模型类型 |
| `label_name` | array\<string\> | 商品标签名称列表 |
| `label_text` | array\<string\> | 商品标签展示文本列表 |
| `recall_item_tracking_info` | struct\<ruleid:array\<int\>, matched_keywords:array\<string\>\> | 召回商品追踪信息，包含命中规则 ID 和匹配关键词 |

---

### 指标：相关性分数

| 字段 | 类型 | 说明 |
|---|---|---|
| `rel_add` | double | 相关性附加分 |
| `rel_raw` | double | 相关性原始分 |
| `rel_lx` | int | 相关性 LX 分 |
| `rel_lx_score` | int | 相关性 LX 评分 |
| `rel_add_score` | double | 相关性附加分（ETL 中固定写入 NULL，预留字段） |
| `rel_raw_score` | double | 相关性原始分（扩展字段） |
| `rel_qcp_all_added_score` | double | QCP 全量附加相关性分（ETL 中固定写入 NULL，预留字段） |
| `rel_qcp_el_added_score` | double | QCP EL 附加相关性分（ETL 中固定写入 NULL，预留字段） |
| `rel_tag_match_added_score` | double | 标签匹配附加相关性分（ETL 中固定写入 NULL，预留字段） |

---

### 指标：排序分数

| 字段 | 类型 | 说明 |
|---|---|---|
| `es_score` | double | Elasticsearch 召回分 |
| `rank_score` | double | 精排总分 |
| `ctr_score` | double | CTR 预估分 |
| `cvr_score` | double | CVR 预估分 |
| `mix_score` | double | 综合混排分 |
| `ads_mix_rank_score` | double | 广告混排综合分 |
| `mix_rank_model_score` | double | 混排模型分（ETL 中固定写入 NULL，预留字段） |
| `model_pid` | double | 模型 PID 参数（ETL 中固定写入 NULL，预留字段） |

---

### 指标：广告混排（ads mix）相关分数（预留字段）

> 以下字段在 ETL 中**统一写入 NULL**，为结构预留，不可用于分析。

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_organic_value_for_ads_mix` | double | 广告自然价值分（预留，NULL） |
| `ads_rank_bid_for_ads_mix` | bigint | 广告混排竞价（预留，NULL） |
| `ads_rank_score_for_ads_mix` | double | 广告混排排序分（预留，NULL） |
| `alpha_for_ads_mix` | double | 混排 alpha 参数（预留，NULL） |
| `ctr_score_for_ads_mix` | double | 广告混排 CTR 分（预留，NULL） |
| `cvr_score_for_ads_mix` | double | 广告混排 CVR 分（预留，NULL） |
| `ecpm_for_ads_mix` | double | 广告混排 eCPM（预留，NULL） |
| `ecpm_weight_for_ads_mix` | int | 广告混排 eCPM 权重（预留，NULL） |
| `ecpm_weight_for_ads_mix_v2` | double | 广告混排 eCPM 权重 v2（预留，NULL） |
| `eval_ads_organic_value_for_ads_mix` | double | 评估广告自然价值（预留，NULL） |
| `eval_search_organic_value_for_ads_mix` | double | 评估搜索自然价值（预留，NULL） |
| `item_ads_pay_impr_1d_for_ads_mix` | bigint | 商品广告 1 天付费曝光数（预留，NULL） |
| `item_avg_pay_price_usd_for_ads_mix` | double | 商品平均付费单价（USD）（预留，NULL） |
| `item_type_for_ads_mix` | int | 混排商品类型（预留，NULL） |
| `merge_score_for_ads_mix` | double | 混排合并分（预留，NULL） |
| `mix_rank_score_for_ads_mix` | double | 混排总分（预留，NULL） |
| `org_roi2_mix_rank_score_for_ads_mix` | double | ROI2 混排自然分（预留，NULL） |
| `pctr_for_ads_mix` | double | 广告混排 pCTR（预留，NULL） |
| `pid_for_ads_mix` | double | 混排 PID 参数（预留，NULL） |
| `real_ads_ecpm_for_ads_mix` | double | 实际广告 eCPM（预留，NULL） |
| `real_ads_rank_score_for_ads_mix` | double | 实际广告排序分（预留，NULL） |
| `rel_lx_mixrank_score_for_ads_mix` | int | LX 混排相关性分（预留，NULL） |
| `stage2_ads_rank_score_for_ads_mix` | double | 二阶段广告排序分（预留，NULL） |
| `stage2_org_addbuff_score_for_ads_mix` | double | 二阶段自然附加缓冲分（预留，NULL） |
| `stage2_org_rank_score_for_ads_mix` | double | 二阶段自然排序分（预留，NULL） |
| `boosting_rule_weight` | double | 规则加权权重（预留，NULL） |

---

### 指标：ROI 模型分数

| 字段 | 类型 | 说明 |
|---|---|---|
| `pctr_for_roi1` | double | ROI1 模型预估 CTR |
| `pcr_for_roi1` | double | ROI1 模型预估转化率 |
| `pctr_for_roi2` | double | ROI2 模型预估 CTR |
| `pcr_for_roi2` | double | ROI2 模型预估转化率 |
| `broad_pcr_for_roi2` | double | ROI2 宽口径预估转化率 |
| `roi2_rank_score_for_roi2` | double | ROI2 排序综合分 |
| `roi2_rank_rank_for_roi2` | int | ROI2 排序排名 |
| `porg_for_roi2` | double | ROI2 预估自然值 |
| `ecpm_for_roi2` | double | ROI2 eCPM |
| `ecpm_weight_for_roi2` | double | ROI2 eCPM 权重 |

---

### 指标：直播评分

| 字段 | 类型 | 说明 |
|---|---|---|
| `live_relevance_score` | int | 直播相关性分 |
| `live_biz_value_score` | double | 直播业务价值分 |
| `live_ctcvr_score` | double | 直播 CTCVR 分 |

---

### 指标：流量计数

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_count` | bigint | 当前请求总商品数（含过滤后） |
| `ori_total_count` | bigint | 原始请求总商品数（过滤前） |
| `mock_deduction_price` | bigint | Mock 扣费价格（测试/模拟场景） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：静态分区字段，每次查询必须指定，否则触发全表扫描：
  ```sql
  WHERE grass_region = 'SG'
  ```
- **`local_date`**：动态分区日期，必须指定，建议与 `local_hour` 联用缩小扫描范围：
  ```sql
  AND local_date = '2024-01-01'
  AND local_hour = 10
  ```
- **`search_page`**：本表数据来源已过滤 `search_page = 'CHATGPT_SEARCH'`，但若与其他表 JOIN 后过滤仍需注意对齐。
- 本表为**小时级分区表**，若查询多小时或多日数据，须列举所有分区条件，避免全量扫描。

### 不可直接 SUM / AVG 的字段

| 字段 | 风险说明 |
|---|---|
| `ctr_score`、`cvr_score`、`pctr_for_roi1/2`、`pcr_for_roi1/2` 等预估分 | 为单商品预估值，聚合均值需按业务口径分组，不可跨请求直接 SUM |
| `roi2_rank_score_for_roi2`、`rank_score`、`mix_score` 等排序分 | 排序分在不同请求间无可比性，不可跨请求求均值 |
| `total_count`、`ori_total_count` | 为请求级别指标，同一 request_id 下多行重复，聚合前需先按 request_id 去重 |
| `ecpm_for_roi2`、`ads_mix_rank_score` 等 eCPM 指标 | 不同广告主竞价单位不同，直接 SUM 无意义 |

### 预留 NULL 字段注意事项

ETL 中以下字段**固定写入 NULL**，在当前版本不可用于分析，勿作为过滤或聚合条件：
`ads_organic_value_for_ads_mix`、`ads_rank_bid_for_ads_mix`、`ads_rank_score_for_ads_mix`、`alpha_for_ads_mix`、`ctr_score_for_ads_mix`、`cvr_score_for_ads_mix`、`ecpm_for_ads_mix`、`ecpm_weight_for_ads_mix`、`ecpm_weight_for_ads_mix_v2`、`eval_ads_organic_value_for_ads_mix`、`eval_search_organic_value_for_ads_mix`、`is_ads_for_ads_mix`、`item_ads_pay_impr_1d_for_ads_mix`、`item_avg_pay_price_usd_for_ads_mix`、`item_type_for_ads_mix`、`merge_score_for_ads_mix`、`mix_rank_score_for_ads_mix`、`org_roi2_mix_rank_score_for_ads_mix`、`pctr_for_ads_mix`、`pid_for_ads_mix`、`real_ads_ecpm_for_ads_mix`、`real_ads_rank_score_for_ads_mix`、`rel_lx_mixrank_score_for_ads_mix`、`stage2_ads_rank_score_for_ads_mix`、`stage2_org_addbuff_score_for_ads_mix`、`stage2_org_rank_score_for_ads_mix`、`boosting_rule_weight`、`rel_add_score`、`rel_qcp_all_added_score`、`rel_qcp_el_added_score`、`rel_tag_match_added_score`、`model_pid`、`mix_rank_model_score`。

### 时效性说明

- 本表为**小时级增量覆盖表**，数据延迟通常为 T+1 小时内可用。
- 每个分区 `(grass_region, local_date, local_hour)` 执行 `INSERT OVERWRITE`，重跑安全，但多并发写同一分区存在数据覆盖风险。
- 不提供累计（`*_td`）或近 N 天（`*_nd`）聚合数据，历史区间分析需自行 UNION 多分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 全量搜索后端日志宽表，本表通过 `search_page = 'CHATGPT_SEARCH'` 过滤得到 ChatGPT 搜索子集 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search_be_log
    │  过滤条件：
    │  ├── grass_region IN (${grass_region})
    │  ├── local_date = ${local_date}
    │  ├── local_hour = ${local_hour}
    │  └── search_page = 'CHATGPT_SEARCH'
    ▼
srdi_mart.dwd_sr_data_warehouse_search_chatgpt_be_log
    分区：grass_region（静态）/ local_date / local_hour / regional_date / regional_hour（动态）
```

### 关键步骤

1. **数据筛选**：直接从上游全量搜索后端日志表按 `grass_region`、`local_date`、`local_hour` 分区条件扫描，并追加 `search_page = 'CHATGPT_SEARCH'` 业务过滤，提取 ChatGPT 搜索场景专属记录。
2. **字段透传**：大多数字段从上游表原样透传，无加工转换逻辑。
3. **预留字段置 NULL**：ads mix 相关的 25+ 个字段（`ads_organic_value_for_ads_mix` 等）及若干其他预留字段（`boosting_rule_weight`、`rel_add_score`、`model_pid`、`mix_rank_model_score` 等）在当前 ETL 版本中统一写入 NULL，保留表结构兼容性。
4. **分区写入**：以 `INSERT OVERWRITE ... PARTITION(grass_region = ${grass_region}, local_date, local_hour, regional_date, regional_hour)` 形式写入，`grass_region` 为静态参数，其余四个分区字段为动态分区从 SELECT 列推断。

### 注意事项

- **单 writer**：当前 ETL 仅有 1 个 SQL 文件，无多文件并发写入同一表的风险。
- **分区覆盖安全**：`INSERT OVERWRITE` 保证同一分区重跑幂等，但若外部任务同时写入相同分区，存在数据互覆风险。
- **字段版本演进**：大量 ads mix 字段当前为 NULL，后续版本可能启用；消费方在使用这些字段前，需确认是否已有实际数据填充。
- **上游依赖**：本表强依赖 `srdi_mart.dwd_sr_data_warehouse_search_be_log` 的分区完整性，若上游分区延迟或数据缺失，本表对应分区数据将为空或不完整。
- **`regional_date` / `regional_hour` 来源**：该两个分区字段从上游表直接透传，其时区换算逻辑由上游 ETL 负责，本表不做二次转换。

---

*文档生成时间：2026-05-17*