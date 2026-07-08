<!-- ads-workspace-gdoc-sync: gdoc_id=1O3OSMHfBcsu8PyiQyotIJn8BB8uTTQtc271iowGc54s gdoc_url=https://docs.google.com/document/d/1O3OSMHfBcsu8PyiQyotIJn8BB8uTTQtc271iowGc54s/edit -->

# srdi_mart.dwd_sr_data_warehouse_platform

**分层：** DWD（明细数据层）
**主键：** 无单一自然主键；事件级明细行，可通过 `event_id` + `operation` + `grass_region` + `local_date` + `local_hour` 联合标识
**分区：** `grass_region` / `local_date` / `local_hour` / `operation` / `regional_date` / `regional_hour`
**更新频率：** 小时级增量写入（traffic 系列为小时分区 HI 表）；omni 系列为日级分区 DI 表
**访问频次：** 379,466 次
**multi-writer：** 是（14 个 ETL 文件并发写入不同 operation 分区）

---

## 业务描述

本表是 Shopee 搜推（Search & Recommendation）域的核心 DWD 事件明细宽表，汇聚了搜索、推荐、直播等全链路用户行为事件，覆盖曝光、点击、加购、商品详情页浏览、下单等完整转化漏斗。

**核心业务场景：**
- 搜索结果页（SRP）、首页信息流、推荐场景的商品曝光与点击行为分析
- Omni 归因链路分析：通过 `source1_*` / `source2_*` 字段溯源用户在多个页面的行为来源
- 订单 GMV 归因：omni_order 将订单与点击/加购事件关联，支持多触点归因
- AB 实验效果评估：通过 `exp_group_ids`、`algo_tag`、`reporting_*` 字段支持实验分组分析
- 搜索质量分析：关键词改写、LLM 深度思考、AI 搜索、语音搜索等新特性效果监控
- 页面性能监控：服务端耗时、前端性能、缓存命中等

**适合回答的问题：**
- 某关键词/场景的曝光量、点击率、加购率、下单转化率
- 特定 AB 实验组的 GMV、点击、转化指标对比
- 搜索入口、搜索词改写对用户行为的影响
- 商品在不同页面/模块的曝光与点击表现
- Omni 归因链路中各触点的贡献

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），物理分区键 |
| `local_date` | date | 事件发生的本地日期（按 grass_region 时区转换），物理分区键 |
| `local_hour` | int | 事件发生的本地小时（0-23，按 grass_region 时区转换），物理分区键 |
| `operation` | string | 事件操作类型（见下方枚举说明），物理分区键 |
| `regional_date` | date | 事件发生的新加坡时区日期（SG TZ），物理分区键 |
| `regional_hour` | int | 事件发生的新加坡时区小时（0-23），物理分区键 |

> `operation` 枚举值包括：`click`、`impression`、`omni_click`、`omni_impression`、`cart`（加购）、`ppv`（商品详情页浏览）、`order`（下单）、`stay_view`、`stay_impression`、`action_scroll_down`、`action_voice_search`、`action_video`、`action_filter` 等行为动作。

---

### 维度：事件基础标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `event_id` | string | 事件唯一标识符 |
| `event_timestamp` | bigint | 事件发生时间戳（毫秒）；order 类型取 order_place_timestamp*1000 |
| `log_timestamp` | bigint | 日志记录时间戳（毫秒）；order 类型为 NULL |
| `operation_cnt` | double | 操作计数；click/impression/cart/ppv 等为 1；order 为 `order_fraction * atc_prorate * first_touchpoint_item` 的乘积 |
| `original_operation` | string | 原始事件操作名称，写入前未经映射的 operation 值 |

---

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `device_id` | string | 设备 ID |
| `platform` | string | 客户端平台（iOS / Android 等） |
| `app_version` | string | App 版本号 |
| `rn_version` | string | React Native 版本号 |
| `platform_implementation` | string | 平台实现标识 |
| `session_id` | string | 会话 ID |
| `user_type` | array\<int\> | 用户类型标签数组，来自 search_info |
| `groupid` | int | 实验分组 ID，来自 search_info |

---

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `model_id` | bigint | 商品型号 ID；非订单场景通常为 NULL |
| `item_type` | int | 商品类型，来自 search_info |
| `card_type` | string | 卡片类型（如 item、video、livestream 等） |
| `knode_id` | string | 推荐集合 ID（collection_id），用于推荐场景 |
| `ctx_items` | array\<struct\<shop_id:bigint,item_id:bigint\>\> | 上下文商品列表，记录触发事件的父级商品 |
| `ctx_item_type` | int | 上下文商品类型 |
| `ctx_streaming_id` | string | 上下文直播 ID |
| `ctx_from_source` | string | 上下文来源标识 |
| `item_unique_key` | string | 商品唯一键，来自 search_FE.item.item_unique_key 或 card_unique_id |
| `vsku_info` | string | vSKU 信息 |
| `spu_vsku_property` | struct\<...\> | 商品点击时的 SPU/vSKU 属性，包含 ctx_item_type、spu_vsku_model_id、预选型号等；仅 click/cart/ppv 场景填充 |
| `click_spu_vsku_property` | struct\<...\> | 订单场景中点击时的 SPU/vSKU 属性 |
| `spu_vsku_order_property` | struct\<...\> | 订单场景 SPU/vSKU 属性，含 has_spu_vsku、initial/updated_vsku_cnt 等 |

---

### 维度：页面与位置

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_type` | string | 当前页面类型（如 search、home、product 等），经过 search_domain_map 映射后的值 |
| `page_section` | array\<string\> | 页面子区域（如 daily_discover、shopee_video 等） |
| `target_type` | string | 目标对象类型（如 item、video、livestream、hint_keyword 等） |
| `feature_detail` | string | 复合特征描述，格式为 `page_type-page_section-target_type` |
| `location` | int | 商品/目标在页面中的位置序号 |
| `content_location` | int | 内容（直播/视频）在页面中的位置 |
| `banner_location` | int | Banner 位置（仅 impression 场景填充） |
| `original_page_type` | string | 原始页面类型（映射前），PPV 场景记录 page_type 原值 |
| `position_current_page` | string | 当前翻页位置标识（来自 video_property.current_page） |
| `pre_source_page_type` | string | 前一来源页面类型（来自 pre_source 结构体） |
| `pre_source_page_section` | string | 前一来源页面子区域 |
| `pre_source_target_type` | string | 前一来源目标类型 |
| `pre_source_event_id` | string | 前一来源事件 ID |
| `last_view_event_id` | string | 上一次浏览事件 ID（traffic 系列携带） |
| `last_view_civ_id` | string | 上一次浏览的 civ_id（traffic 系列携带） |
| `civ_id` | string | 当前事件的 civ_id（traffic 系列携带） |

---

### 维度：来源溯源（Source1/Source2 Omni 归因）

| 字段 | 类型 | 说明 |
|---|---|---|
| `source1_page_type` | string | 归因来源1的页面类型 |
| `source1_page_section` | array\<string\> | 归因来源1的页面子区域 |
| `source1_target_type` | string | 归因来源1的目标类型 |
| `source1_location` | int | 归因来源1的位置序号 |
| `source1_feature_detail` | string | 归因来源1的复合特征描述 |
| `source1_mapped_page_type` | string | 归因来源1经过映射后的页面类型 |
| `source2_page_type` | string | 归因来源2的页面类型 |
| `source2_page_section` | array\<string\> | 归因来源2的页面子区域 |
| `source2_target_type` | string | 归因来源2的目标类型 |
| `source2_location` | int | 归因来源2的位置序号 |
| `source2_feature_detail` | string | 归因来源2的复合特征描述 |
| `source2_mapped_page_type` | string | 归因来源2经过映射后的页面类型 |
| `source1_ext_item_id` | string | 归因来源1的扩展 item_id |
| `source2_ext_item_id` | string | 归因来源2的扩展 item_id |
| `source1_ext_shop_id` | bigint | 归因来源1的扩展 shop_id |
| `source2_ext_shop_id` | bigint | 归因来源2的扩展 shop_id |

---

### 维度：搜索属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词 |
| `search_entrance` | string | 搜索入口标识（如 text_search、voice_search 等） |
| `search_mid` | string | 搜索 mid，经 search_mid_mapping 维表补全 |
| `search_session_id` | string | 搜索会话 ID |
| `global_session_id` | string | 全局会话 ID |
| `search_prefill_id` | int | 搜索预填 ID |
| `prefill_type` | string | 预填类型 |
| `input_type` | string | 输入类型（文本/语音等） |
| `last_keyword` | string | 上一次搜索关键词 |
| `last_entrance` | string | 上一次搜索入口 |
| `sort_type` | string | 排序类型（来自 search_FE.search_params.sortBy） |
| `sort_order` | string | 排序顺序（asc/desc，来自 search_FE.search_params.order） |
| `search_filter` | array\<struct\<filter_group_name:string,filter_name:string,filter_option:string,is_shortcut_filter:boolean\>\> | 搜索筛选器数组 |
| `search_filter_string` | array\<string\> | 搜索筛选器 JSON 字符串数组 |
| `search_filter_address_id` | array\<bigint\> | 搜索筛选器中的地址 ID 列表 |
| `search_scenario_be_key` | string | 搜索场景后端键（search_FE.search_params.search_scenario.be_key） |
| `user_input` | string | 用户输入内容（语音/图片搜索原始输入） |
| `search_guide_request_id` | string | 搜索引导请求 ID（来自 parse_search_info.reqid） |
| `reserved_keyword` | string | 预留关键词（search_params.reserved_keyword） |
| `queues` | string | 队列/规则 ID 字符串，从 recommendation_info 提取 QUES 字段或 rule_ids |
| `request_id` | string | 搜索/推荐服务请求 ID（从 recommendation_info REQID 或 search_property 提取） |
| `md5` | string | 图片搜索 MD5（search_FE.md5） |
| `image_source` | string | 图片来源（image_search 等） |
| `image_aspect_ratio` | string | 图片宽高比（如 3:4、1:1 等） |
| `image_id` | string | 商品图片 ID；当 image_aspect_ratio 为 3:4 时取 long_image_id，否则取 image_id 或 image_hashcode |
| `image_id` | string | 商品展示图片 ID |
| `item_similarity` | double | 图片搜索相似度分数 |
| `attr_data_type` | string | 属性数据类型（来自 search_info） |
| `entrance_keyword_type` | string | 入口关键词类型（traffic 来自 search_FE context，omni_order 来自 keyword_type） |
| `module_keyword_type` | string | 模块关键词类型（来自 search_FE.module.clicked_keyword） |
| `hint_keyword_source` | int | 提示关键词来源标识（来自 search_FE.keyword_source） |
| `search_fe_error_type` | string | 搜索前端错误类型（search_FE.error_type） |
| `fe_status_code_info` | array\<string\> | 前端状态码信息数组（search_FE.status_code_info） |

---

### 维度：关键词改写与 AI 搜索

| 字段 | 类型 | 说明 |
|---|---|---|
| `rewrite_keyword` | string | 改写后的关键词 |
| `origin_rewrite_keyword` | string | 改写前的原始关键词 |
| `fe_querywrite_status` | int | 前端查询改写状态码（query_rewrite.fe_query_rewrite_status） |
| `rewrite_id` | int | 改写类型 ID（query_rewrite.rewrite_type） |
| `llm_rewrite_keyword` | string | LLM 改写关键词 |
| `is_llm_deepthinking` | boolean | 是否启用 LLM 深度思考（llm_dt_recall） |
| `rs_is_llm_card` | boolean | 是否 LLM 推荐卡片（is_llm_card 或 search_FE context） |
| `rs_impressed_keyword` | string | 推荐场景已曝光关键词（search_FE.module.impressed_keyword） |
| `rs_clicked_keyword` | string | 推荐场景已点击关键词（search_FE.module.clicked_keyword） |
| `ai_search_info` | string | AI 搜索信息原始 JSON 字符串 |
| `ai_search_info_md5` | string | AI 搜索信息 MD5（预留，当前未填充） |
| `ai_search_info_box` | string | AI 搜索框信息（预留，当前未填充） |
| `ai_search_info_user_input` | string | AI 搜索用户输入（预留，当前未填充） |
| `ai_search_info_minifeed_ui_type` | int | AI 搜索 MiniFeed UI 类型（预留，当前未填充） |
| `ai_search_info_click_area` | int | AI 搜索点击区域（预留，当前未填充） |
| `ai_minifeed_card_title` | string | AI MiniFeed 卡片标题（aiminifeed_title） |
| `fe_header_ai_summary` | string | 搜索结果页头部 AI 摘要（search_FE.header.ai_summary），仅 view 场景填充 |
| `fe_topic_navigation` | array\<string\> | 前端话题导航数组（search_FE.topic_navigation），仅 view 场景填充 |
| `fe_voice_search_classification` | string | 语音搜索分类（search_FE.classification） |
| `voice_search_session_id` | string | 语音搜索会话 ID |
| `use_mobile_vad` | boolean | 是否使用移动端 VAD（语音活动检测）|
| `search_box_xy` | string | 搜索框坐标（search_FE.box.box_xy 或 box_xy） |

---

### 维度：Topic / AI Topic

| 字段 | 类型 | 说明 |
|---|---|---|
| `topic_title` | string | 话题标题 |
| `topic_location` | int | 话题位置 |
| `ai_topic_srp_location` | int | AI 话题在 SRP 中的位置 |
| `ai_topic_srp_title` | string | AI 话题在 SRP 中的标题 |
| `fe_module_title` | string | 前端模块标题（search_FE.module.title） |

---

### 维度：视频与直播

| 字段 | 类型 | 说明 |
|---|---|---|
| `content_id` | string | 内容 ID；target_type=video 时为 decode_video_id，target_type=livestream 时为 ctx_streaming_id |
| `content_type` | string | 内容类型（video_property.content_type 或 params.content_type） |
| `video_id` | string | 视频 ID；仅首页 shopee_video/daily_discover 场景填充 |
| `video_request_id` | string | 视频请求 ID；仅首页视频场景填充 |
| `video_play_loop` | double | 视频播放循环次数（video_info[0].video_play_loop 或 video_play_loop） |
| `highlight_video_playback_loop` | int | 高亮视频播放循环次数 |
| `live_in_search_request_id` | string | 搜索内嵌直播请求 ID |
| `live_in_search_item_id` | bigint | 搜索内嵌直播商品 ID |
| `live_in_search_location` | int | 搜索内嵌直播位置 |
| `ctx_streaming_id` | string | 上下文直播流 ID（click 场景） |
| `ctx_from_source` | string | 上下文来源（click 场景） |
| `sv_source_page` | string | 短视频来源页面（params.sv_source_page） |
| `sv_source_request_id` | string | 短视频来源请求 ID |
| `sv_source_location` | int | 短视频来源位置 |
| `sv_source_item_id` | bigint | 短视频来源商品 ID（click 场景） |
| `seg_duration` | string | 视频分段时长（params.seg_duration） |
| `content_location` | int | 内容位置 |
| `from_source` | string | 来源标识（view 场景 from_source 字段） |
| `business_id` | string | 业务 ID（meta.business_id 或 video_property.business_id） |
| `camera_page_version` | string | 相机/图搜页版本（search_FE.version） |

---

### 维度：场景分组与实验

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_group` | string | 算法场景分组（由 get_all_tag UDF 计算），'not found' 值被清洗为 NULL |
| `feature` | string | 场景 feature 标识（来自 omni 源表的 feature 字段） |
| `reporting_business_line` | string | DPM 口径的业务线分组（omni 场景取 business_line，traffic 场景由 get_all_tag 计算） |
| `reporting_module` | string | DPM 口径的模块分组 |
| `reporting_object` | string | DPM 口径的对象分组 |
| `algo_tag` | string | 算法口径的场景分组标签，由 get_all_tag UDF 计算（all_tags[4]），如 DA_Search_RCMD |
| `exp_group_ids` | array\<int\> | AB 实验分组 ID 数组，合并自 ab_sign、recommendation_info AB 字段、be_ab、exp_group_id 等多个来源，并去重 |
| `upstream_feature` | string | 上游 feature 标识（recommendation_property.upstream） |
| `match_id` | string | 匹配 ID，用于商品匹配追踪 |
| `dre_version` | string | DRE 版本号（搜索排序引擎版本） |
| `shop_recall_type` | string | 店铺召回类型 |
| `layout_type` | int | 布局类型（search_FE.layout_type） |
| `layout_variant` | string | 布局变体标识（仅 click 场景） |

---

### 维度：Source1/Source2 搜索与场景属性（Omni 归因链路）

| 字段 | 类型 | 说明 |
|---|---|---|
| `source1_keyword` | string | 归因来源1的搜索关键词 |
| `source1_search_entrance` | string | 归因来源1的搜索入口 |
| `source1_search_mid` | string | 归因来源1的搜索 mid |
| `source1_search_session_id` | string | 归因来源1的搜索会话 ID |
| `source1_global_session_id` | string | 归因来源1的全局会话 ID |
| `source1_last_keyword` | string | 归因来源1的上一次关键词 |
| `source1_last_entrance` | string | 归因来源1的上一次入口 |
| `source1_request_id` | string | 归因来源1的请求 ID（Rcmd mixer 或 search server，可能为 NULL） |
| `source1_sort_by` | string | 归因来源1的排序方式 |
| `source1_queues` | string | 归因来源1的规则队列 |
| `source1_feature` | string | 归因来源1的 feature 标识 |
| `source1_feature_group` | string | 归因来源1的场景分组 |
| `source1_algo_tag` | string | 归因来源1的算法标签 |
| `source1_reporting_business_line` | string | 归因来源1的 DPM 业务线 |
| `source1_reporting_module` | string | 归因来源1的 DPM 模块 |
| `source1_reporting_object` | string | 归因来源1的 DPM 对象 |
| `source1_is_ads` | boolean | 归因来源1是否广告 |
| `source1_ads_id` | bigint | 归因来源1的广告 ID |
| `source1_content_id` | string | 归因来源1的内容 ID |
| `source1_content_type` | string | 归因来源1的内容类型 |
| `source1_business_id` | string | 归因来源1的业务 ID |
| `source1_search_filter` | array\<struct\<...\>\> | 归因来源1的搜索筛选器 |
| `source1_search_filter_string` | array\<string\> | 归因来源1的搜索筛选器 JSON 字符串 |
| `source1_search_filter_address_id` | array\<bigint\> | 归因来源1的筛选地址 ID |
| `source1_image_id` | string | 归因来源1的图片 ID（recommendation_property.image_hashcode） |
| `source1_is_llm_deepthinking` | boolean | 归因来源1是否 LLM 深度思考 |
| `source1_rs_is_llm_card` | boolean | 归因来源1是否 LLM 卡片 |
| `source1_dre_version` | string | 归因来源1的 DRE 版本 |
| `source1_shop_recall_type` | string | 归因来源1的店铺召回类型 |
| `source1_layout_type` | int | 归因来源1的布局类型 |
| `source1_sv_source_location` | int | 归因来源1的短视频来源位置 |
| `source1_sv_source_page` | string | 归因来源1的短视频来源页面 |
| `source1_sv_source_request_id` | string | 归因来源1的短视频来源请求 ID |
| `source1_shop_layout_item_list` | array\<bigint\> | 归因来源1的店铺布局商品列表 |
| `source1_tc_rule_array` | array\<string\> | 归因来源1的流量控制规则数组 |
| `source1_biz_flag` | array\<string\> | 归因来源1的业务标签 |
| `source1_ai_search_info` | string | 归因来源1的 AI 搜索信息 |
| `source1_ai_search_info_md5` | string | 归因来源1的 AI 搜索 MD5（预留，当前未填充） |
| `source1_ai_search_info_box` | string | 归因来源1的 AI 搜索框信息（预留，当前未填充） |
| `source1_ai_search_info_user_input` | string | 归因来源1的 AI 搜索用户输入（预留，当前未填充） |
| `source1_ai_search_info_minifeed_ui_type` | int | 归因来源1的 AI MiniFeed UI 类型（预留，当前未填充） |
| `source1_ai_search_info_click_area` | int | 归因来源1的 AI 搜索点击区域（预留，当前未填充） |
| `source1_item_unique_key` | string | 归因来源1的商品唯一键 |
| `source1_title_text` | string | 归因来源1的商品标题文本 |
| `source1_match_id` | string | 归因来源1的匹配 ID |
| `source1_display_price_model_id` | bigint | 归因来源1的展示价格型号 ID |
| `source1_entrance_keyword_type` | string | 归因来源1的入口关键词类型 |
| `source1_voice_search_session_id` | string | 归因来源1的语音搜索会话 ID |
| `source2_keyword` | string | 归因来源2的搜索关键词 |
| `source2_search_entrance` | string | 归因来源2的搜索入口 |
| `source2_search_mid` | string | 归因来源2的搜索 mid |
| `source2_search_session_id` | string | 归因来源2的搜索会话 ID |
| `source2_global_session_id` | string | 归因来源2的全局会话 ID |
| `source2_last_keyword` | string | 归因来源2的上一次关键词 |
| `source2_last_entrance` | string | 归因来源2的上一次入口 |
| `source2_request_id` | string | 归因来源2的请求 ID（当前通常为空值，暂未使用） |
| `source2_sort_by` | string | 归因来源2的排序方式 |
| `source2_queues` | string | 归因来源2的规则队列 |
| `source2_feature` | string | 归因来源2的 feature 标识 |
| `source2_feature_group` | string | 归因来源2的场景分组 |
| `source2_algo_tag` | string | 归因来源2的算法标签 |
| `source2_reporting_business_line` | string | 归因来源2的 DPM 业务线 |
| `source2_reporting_module` | string | 归因来源2的 DPM 模块 |
| `source2_reporting_object` | string | 归因来源2的 DPM 对象 |
| `source2_is_ads` | boolean | 归因来源2是否广告 |
| `source2_ads_id` | bigint | 归因来源2的广告 ID |
| `source2_content_id` | string | 归因来源2的内容 ID |
| `source2_content_type` | string | 归因来源2的内容类型 |
| `source2_business_id` | string | 归因来源2的业务 ID |
| `source2_search_filter` | array\<struct\<...\>\> | 归因来源2的搜索筛选器 |
| `source2_search_filter_string` | array\<string\> | 归因来源2的搜索筛选器 JSON 字符串 |
| `source2_search_filter_address_id` | array\<bigint\> | 归因来源2的筛选地址 ID |
| `source2_image_id` | string | 归因来源2的图片 ID |
| `source2_is_llm_deepthinking` | boolean | 归因来源2是否 LLM 深度思考 |
| `source2_rs_is_llm_card` | boolean | 归因来源2是否 LLM 卡片 |
| `source2_dre_version` | string | 归因来源2的 DRE 版本 |
| `source2_shop_recall_type` | string | 归因来源2的店铺召回类型 |
| `source2_layout_type` | int | 归因来源2的布局类型 |
| `source2_sv_source_location` | int | 归因来源2的短视频来源位置 |
| `source2_sv_source_page` | string | 归因来源2的短视频来源页面 |
| `source2_sv_source_request_id` | string | 归因来源2的短视频来源请求 ID |
| `source2_shop_layout_item_list` | array\<bigint\> | 归因来源2的店铺布局商品列表 |
| `source2_tc_rule_array` | array\<string\> | 归因来源2的流量控制规则数组 |
| `source2_biz_flag` | array\<string\> | 归因来源2的业务标签 |
| `source2_ai_search_info` | string | 归因来源2的 AI 搜索信息 |
| `source2_ai_search_info_md5` | string | 归因来源2的 AI 搜索 MD5（预留，当前未填充） |
| `source2_ai_search_info_box` | string | 归因来源2的 AI 搜索框信息（预留，当前未填充） |
| `source2_ai_search_info_user_input` | string | 归因来源2的 AI 搜索用户输入（预留，当前未填充） |
| `source2_ai_search_info_minifeed_ui_type` | int | 归因来源2的 AI MiniFeed UI 类型（预留，当前未填充） |
| `source2_ai_search_info_click_area` | int | 归因来源2的 AI 搜索点击区域（预留，当前未填充） |
| `source2_item_unique_key` | string | 归因来源2的商品唯一键 |
| `source2_title_text` | string | 归因来源2的商品标题文本 |
| `source2_match_id` | string | 归因来源2的匹配 ID |
| `source2_display_price_model_id` | bigint | 归因来源2的展示价格型号 ID |
| `source2_entrance_keyword_type` | string | 归因来源2的入口关键词类型 |
| `source2_voice_search_session_id` | string | 归因来源2的语音搜索会话 ID |

---

### 维度：广告与流量控制

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 当前事件是否广告流量 |
| `ads_id` | bigint | 广告 ID |
| `display_ad_tag` | string | 展示广告标签（仅 traffic click 场景） |
| `traffic_source` | int | 流量来源类型（traffic 场景） |
| `biz_flag` | array\<string\> | 业务标签数组（来自 search_FE.traffic_info.biz_flag） |
| `tc_rule_array` | array\<string\> | 流量控制规则数组（来自 search_FE.traffic_info.tc_rule_array） |
| `is_group_buy` | boolean | 是否拼团商品 |

---

### 维度：商品展示属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `title_text` | string | 商品标题文本（title_info.title_text 或 search_FE.title_info.title_text） |
| `title_id` | string | 标题 ID（traffic click 场景） |
| `title_is_rewrite` | boolean | 标题是否经过改写 |
| `title_info` | struct\<title_text:string,title_is_rewrite:boolean\> | 标题完整结构体 |
| `title_source` | string | 标题来源标识（search_xui_info.title_source） |
| `labels` | array\<struct\<label_text:string,label_type:string,label_location:int\>\> | 标签数组（search_FE.label_icon_info.labels） |
| `show_labels` | array\<string\> | 展示标签文本列表（search_FE.item.show_labels） |
| `label_source` | array\<string\> | 标签来源数组（search_xui_info.label_source） |
| `seller_flags` | array\<string\> | 卖家标志（如 Choice、Preferred 等，来自 search_FE.label_icon_info.seller_flags 或 traffic_omni_oa） |
| `first_label` | string | 第一标签文本 |
| `first_label_id` | bigint | 第一标签 ID |
| `first_label_content` | string | 第一标签内容 |
| `second_label` | string | 第二标签文本 |
| `second_label_id` | bigint | 第二标签 ID |
| `second_label_content` | string | 第二标签内容 |
| `library_name` | string | 图片库名称（search_xui_info.library_name） |
| `xui_item_status` | int | XUI 商品状态（search_xui_info.xui_item_status） |
| `xui_image_stage` | int | XUI 图片加载阶段（search_xui_info.xui_image_stage） |
| `display_price` | string | 商品展示价格（item.display_price 或 price_after_voucher） |
| `display_price_model_id` | bigint | 展示价格对应的型号 ID |
| `imp_price_local` | double | 曝光时的本地货币价格（price/100000.0，仅 impression 场景） |
| `rating` | string | 商品评分（item.rating） |
| `sold_cnt_str` | string | 商品销量字符串展示（如 "1k+ sold"，来自 search_FE.item.sold_cnt_str 或 traffic_omni_oa） |
| `shipped_from` | string | 商品发货地（来自 search_FE.item.shipped_from 或 traffic_omni_oa） |
| `edd` | string | 预计送达日期文本（search_FE.edd） |
| `edt_string_type` | string | EDT 标签类型（search_FE.item.edt 或 edt_label.label_content） |
| `edt_model_id` | bigint | EDT 型号 ID |
| `edt_pre_selected_shipping_id` | string | EDT 预选配送 ID（edt_tracking_info.a） |
| `pre_selected_edt` | string | 预选 EDT 值（edt_tracking_info.b） |
| `display_type_edt` | string | EDT 展示类型（edt_tracking_info.c） |
| `edt_buyer_address` | string | EDT 买家地址（edt_tracking_info.d） |
| `liked` | boolean | 用户是否已收藏 |
| `is_back` | boolean | 是否返回行为 |
| `is_cache` | boolean | 是否缓存响应（fe_performance_info.isCache，仅 traffic click） |
| `is_censor` | boolean | 是否受到审核（is_censor，仅 impression 场景） |
| `prefill_id_from_csa` | bigint | 来自 CSA 的预填 ID（search_FE.prefill_id，仅 traffic click） |
| `shop_layout_item_list` | array\<bigint\> | 店铺布局商品 ID 列表（search_property.item_list）|
| `content_mix_frame_tab_name` | string | 内容混合框架 Tab 名称 |
| `url` | string | 页面 URL（仅 traffic click/impression 场景） |
| `vsku_info` | string | vSKU 信息 JSON 字符串 |
| `ctx_item_type` | int | 上下文商品类型整数值 |
| `target_property` | string | target_type 为 item 时的目标属性 JSON；其他为 NULL |
| `page_section` | array\<string\> | 页面子区域数组 |

---

### 指标：订单 GMV 与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `place_order_gmv` | double | 下单 GMV（USD），仅 order 场景：`gmv_usd * atc_prorate * first_touchpoint_item`；cart/impression/click/ppv 为 NULL |
| `place_order_gmv_local` | double | 下单 GMV（本地货币），仅 order 场景：`gmv * atc_prorate * first_touchpoint_item`；其他场景为 NULL |
| `place_seller_gmv` | double | 卖家 GMV（USD），仅 order 场景：`place_sellergmv_usd * atc_prorate * last_touchpoint_item` |
| `place_seller_gmv_local` | double | 卖家 GMV（本地货币），仅 order 场景：`place_sellergmv * atc_prorate * last_touchpoint_item` |
| `pc2_gmv` | double | PC2 GMV（USD），仅 order 场景：`pc2_usd * atc_prorate * first_touchpoint_item` |
| `pc2_gmv_local` | double | PC2 GMV（本地货币），仅 order 场景：`pc2 * atc_prorate * first_touchpoint_item` |
| `order_id` | bigint | 订单 ID，仅 order 场景填充 |
| `order_fraction` | double | 订单拆单系数，按商品种类和型号均分；仅 order 场景 |
| `item_amount` | int | 订单中该商品的数量；仅 order 场景 |
| `atc_prorate` | double | 加购摊薄系数；仅 order 场景。GMV 等指标需乘以此系数使用 |
| `first_touchpoint_item` | int | 是否为第一触点商品的标志（0/1）；仅 order 场景 |
| `oa_click_event_timestamp` | bigint | Omni 链路中点击事件时间戳；仅 order 场景 |
| `oa_atc_event_timestamp` | bigint | Omni 链路中加购事件时间戳；仅 order 场景 |
| `window_day` | int | 归因时间窗口天数；仅 order 场景 |

---

### 指标：页面行为与性能

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_stay_duration` | bigint | 页面停留时长（毫秒）；stay_view/stay_impression 场景有值，ppv 场景取 page_duration |
| `rating_score` | double | 商品评分数值（search_FE.rating_score，仅 traffic click） |
| `total_duration` | bigint | 前端总耗时（fe_performance.total_duration，仅 traffic click） |
| `stages_duration` | array\<string\> | 前端各阶段耗时数组（fe_performance.stages_duration，仅 traffic click） |
| `server_cost` | bigint | 后端服务耗时（be_performance.server_cost，仅 traffic click） |
| `request_pack_size` | bigint | 请求包大小（be_performance.request_pack_size，仅 traffic click） |
| `response_pack_size` | bigint | 响应包大小（be_performance.response_pack_size，仅 traffic click） |

---


### 维度：自动校验补齐

以下字段由生成后字段覆盖率校验补齐，字段存在和类型以 DataMap snapshot 为准。

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_manual_stop` | boolean | DataMap 字段，原始描述为空 |
| `source1_position_current_page` | string | DataMap 字段，原始描述为空 |
| `source2_position_current_page` | string | DataMap 字段，原始描述为空 |

## 查询使用须知

### 必须包含的过滤条件

1. **分区过滤（强制）**：所有查询必须指定 `local_date`（或 `regional_date`）和 `grass_region`；强烈建议同时指定 `operation` 以避免跨分区全扫描。

   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2026-05-19'
     AND operation = 'click'
   ```

2. **小时级查询**：如需精确到小时，需同时过滤 `local_hour`（traffic 系列数据）；omni 系列（cart/ppv/order/omni_click/omni_impression）以日为粒度写入，`local_hour` 由事件时间决定，不固定为整点。

3. **operation 语义边界**：
   - `click` / `impression`：来自 traffic 原始日志（`shopee_traffic_dwd_*`），不含归因链路
   - `omni_click` / `omni_impression`：来自 omni 归因系统（`traffic_omni_oa`），含 source1/source2 归因字段
   - `cart`（加购）/ `ppv`（商品详情页浏览）：omni 归因系统
   - `order`：订单事件，含 GMV 字段
   - `stay_view` / `stay_impression` / `action_*`：页面行为事件，来自 traffic click 分区

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `place_order_gmv` / `place_order_gmv_local` | 已按 `atc_prorate * first_touchpoint_item` 分摊，不可再叠加 atc_prorate；仅 order 场景有值 |
| `place_seller_gmv` / `place_seller_gmv_local` | 同上，已按 `atc_prorate * last_touchpoint_item` 分摊 |
| `pc2_gmv` / `pc2_gmv_local` | 同上，已预分摊 |
| `order_fraction` | 拆单系数，代表该行占订单的比例，不可直接求和为订单数 |
| `atc_prorate` | 摊薄系数，非聚合指标 |
| `item_amount` | 若计算总量需乘以 `atc_prorate`：`SUM(item_amount * atc_prorate)` |
| `operation_cnt` | order 场景已预计算为 `order_fraction * atc_prorate * first_touchpoint_item`，不可再乘系数 |
| `item_similarity` | 相似度分数，为比率指标，不可直接 SUM |
| `imp_price_local` | 单个商品价格，仅统计均价时可用 AVG，不可直接 SUM |
| `exp_group_ids` | 数组类型，需 EXPLODE 后使用 |
| `rating_score` | 评分均值，不可直接 SUM |
| `video_play_loop` | 播放循环次数，为每个事件的单次值，直接 SUM 无意义时需结合业务 |

### 时效性说明

- **traffic 系列**（click/impression/view）：小时级数据，`local_hour` 为有效分区维度，通常延迟 1-2 小时可用。
- **omni 系列**（cart/ppv/omni_click/omni_impression）：日级数据（DI），通常次日 T+1 可用，`local_hour` 由事件时间推算而非整点。
- **order 场景**：订单归因数据，延迟视上游 omni_order 而定，通常 T+1 或更晚，`window_day` 记录归因时间窗口。
- 本表不含 `*_nd`（最近 N 天聚合）或 `*_td`（今日累计）预聚合字段，所有指标需在查询时自行汇总。
- **source1/source2 字段**：仅在 omni 系列（omni_click、omni_impression、cart、ppv、order）中有效，traffic 系列中这些字段均为 NULL。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | traffic click 原始事件日志（小时分区） |
| `traffic.shopee_traffic_dwd_impression_hi__reg_s1_live` | traffic impression 原始事件日志（小时分区） |
| `traffic.shopee_traffic_dwd_view_hi__reg_s1_live` | traffic view/page view 原始事件日志（小时分区） |
| `traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live` | Omni 加购事件日志（日分区，含归因链路） |
| `traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live` | Omni 商品曝光/点击事件日志（日分区） |
| `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | Omni 订单-加购归因旅程日志（日分区） |
| `traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live` | Omni 商品详情页浏览事件（日分区） |
| `mp_foa.dim_search_domain_map__reg_live` | 搜索场景域名映射维表（按 search_scenario_key 映射 page_type） |
| `srdi_mart.dim_sr_data_warehouse_search_mid_mapping` | 搜索 mid 映射维表（Google Sheet 维护，补全搜索入口 mid） |

---

## ETL 逻辑摘要

### 数据流

```
原始日志（traffic / traffic_omni_oa）
    ↓ Parse SQL（SOURCE 1-7）：结构化解析、字段提取、时区转换
    ↓ Temporary View（Parse Layer）
    ↓ Join 维表（search_domain_map / search_mid_mapping）
    ↓ 打 algo_tag 等标签（get_all_tag UDF）
    ↓ INSERT OVERWRITE（SOURCE 8-14）→ srdi_mart.dwd_sr_data_warehouse_platform
```

### 关键步骤

**Step 1 – Parse Layer（SOURCE 1-7，生成 Temporary View）**

- **omni_cart_parse**：从 `dwd_atc_event_di` 解析加购事件，提取 last_item_click 结构体中的搜索/推荐属性，组装 source1/source2 归因字段，时区转换生成 local_date/regional_date。
- **omni_mart_impression_click_parse**：从 `dwd_item_event_log_di` 按 event_type 区分 omni_impression / omni_click，提取 search_property / recommendation_property，过滤 source1/source2 有效记录。
- **omni_order_parse**：从 `dwd_order_item_atc_journey_di` 解析订单-加购链路，计算 `order_fraction * atc_prorate * first_touchpoint_item` 作为 operation_cnt，提取 pc2/gmv/seller_gmv 等多种 GMV 指标。
- **omni_ppv_parse**：从 `dwd_product_page_view_di` 解析商品详情页浏览，携带 page_stay_duration（page_duration 字段）。
- **traffic_click_parse（两步）**：第一步（pre_parse）通过 `srdi_fastjson2_from_json` 将 data JSON 字段解析为结构化的 parse_data / parse_search_info / parse_search_filter；第二步提取各业务字段并拼装 feature_detail。
- **traffic_impression_parse（两步）**：同 click_parse 结构，额外解析 banner_location、is_censor、imp_price_local（price/100000.0）。
- **traffic_view_parse（两步）**：同上，额外解析 fe_header_ai_summary、fe_topic_navigation、live_in_search 相关字段；不含 search_filter 结构解析。

**Step 2 – 维表关联与标签计算（SOURCE 8-14，写入目标表）**

- **traffic 系列（click/impression/view）**：依次 LEFT JOIN `dim_search_domain_map` 按 search_scenario_key 映射 page_type，LEFT JOIN `dim_sr_data_warehouse_search_mid_mapping` 补全 search_mid，再调用 `get_all_tag` UDF 计算 feature_group、reporting_business_line/module/object、algo_tag，最终 `INSERT OVERWRITE` 到目标表对应的 `local_hour` 分区。
- **omni 系列**：先生成 `*_add_all_tags` 中间视图（调用 `get_all_tag` 计算当前事件及 source1/source2 各自的 algo_tag），再 `INSERT OVERWRITE` 到目标表对应的日期分区（不固定 local_hour）。
- **字段对齐**：各 ETL 文件在 INSERT 时对本 operation 不适用的字段统一填 NULL，保证与宽表 Schema 对齐；omni 系列的 source1*/source2* 字段来自解析层，traffic 系列的 source1*/source2* 字段均置 NULL。

### 注意事项

1. **Multi-writer 并发写入**：14 个 ETL 文件并发写入同一物理表的不同 `operation` 分区。各文件使用 `INSERT OVERWRITE ... PARTITION(operation=...)` 写固定 operation 值，分区隔离，**但若调度时同一 grass_region + local_date + local_hour + operation 被多个 job 并发覆盖，存在数据竞争风险**，需在调度层保证互斥。

2. **traffic 系列按 local_hour 写，omni 系列不固定 local_hour**：traffic click/impression/view 的 INSERT OVERWRITE 指定了 `local_hour = ${local_hour}`（静态分区）；omni 系列（cart/ppv/order/omni_*）的 local_hour 为动态分区，由事件时间决定，同一日期的数据可能分布在多个 local_hour 分区。

3. **`get_all_tag` UDF 依赖 page_type 映射**：traffic 系列在 JOIN search_domain_map 之后才调用 UDF，omni 系列在解析层已使用 mapped_page_type，两者计算 algo_tag 的 page_type 来源不同，分析时需注意口径差异。

4. **omni_mart_impression_click 过滤条件**：该 ETL 仅写入 `source1_feature_detail IS NOT NULL OR source2_feature_detail IS NOT NULL` 的记录，即必须有有效归因来源，纯首曝记录不会写入此 operation。

5. **`feature_group` 清洗**：'not found'、'not found valid click'、'not found atc' 等值在写入时被替换为 NULL，下游不应依赖这些字面量进行过滤。

6. **DDL 一致性风险**：表共有 323 列，由 14 个文件协同维护；新增字段时需同步更新所有 ETL 文件，否则遗漏文件的旧分区数据将对应列为 NULL，造成历史数据不一致。

7. **`dim_sr_data_warehouse_search_mid_mapping` 需提前刷新**：traffic click / traffic impression 的 ETL 在执行前均包含 `REFRESH TABLE srdi_mart.dim_sr_data_warehouse_search_mid_mapping` 语句，以确保取到最新映射。

---

*文档生成时间：2026-05-20*