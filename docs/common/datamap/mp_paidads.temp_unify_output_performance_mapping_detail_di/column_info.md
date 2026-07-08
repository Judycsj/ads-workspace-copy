<!-- ads-workspace-gdoc-sync: gdoc_id=1JT-nMiclMAflcd6GZRm6-_CWQ-WOVXV6MoAJ4pHSF1I gdoc_url=https://docs.google.com/document/d/1JT-nMiclMAflcd6GZRm6-_CWQ-WOVXV6MoAJ4pHSF1I/edit -->

# Columns: mp_paidads.temp_unify_output_performance_mapping_detail_di

## Column Usage Notes

### 列结构说明

所有业务字段采用 `{name}_new` / `{name}_old` 成对出现，分别存储新数据源和旧数据源的值。除 join_key 和 new_join_key 外，其余列均为 string 类型（来自 `CAST(... AS string)`）。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| type | traffic | 流量层对比（report_type=0, 无点击/曝光时间戳） |
| type | finance | 财务层对比（report_type=1, 按 entrance+ads_id+user_id+deduct_unique_id JOIN） |
| type | attribution | 归因层对比（report_type in 2,3, 按 entrance+order_id+item_id JOIN） |
| type | attribution_atc | ATC归因对比（report_type in 2,3, 按 entrance+unique_id JOIN, 有 ATC 事件） |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN','BR' (8个核心站点，另有 'MX')
- `type`: 'traffic' / 'finance' / 'attribution' / 'attribution_atc'
- `grass_date`: 按天分区，典型值如 date'2026-05-24'
- Read Query 典型过滤: 差异排查常加 `{field}_new is distinct from {field}_old` 条件

### 非累加字段 (Non-Additive Fields)

所有列均为 string 类型存储的明细级新旧值，跨行聚合无意义。此表为明细对比表，不应直接 SUM 各列。

### JOIN 键及其含义

表中的 `join_key` 存储新旧记录匹配所用的组合键，具体内容由 diff_type 决定：

- traffic: `unique_id:{value},entrance:{value}`
- finance: `entrance:{value},ads_id:{value},user_id:{value},deduct_unique_id:{value}`
- attribution: `entrance:{value},order_id:{value},item_id:{value}`
- attribution_atc: `entrance:{value},unique_id:{value}`

`new_join_key` 只在 finance/attribution/attribution_atc 类型中有意义（与 join_key 构造方式不同）。

## All Columns

所有列为 string 类型，按字段类别分组如下：

### 键/标识列

| Column Name | Type | Description |
|-------------|------|-------------|
| join_key | string | 新旧 JOIN 键（旧数据源的组合键） |
| new_join_key | string | 新数据源的组合键（FULL OUTER JOIN 后的新键） |
| entrance_new / entrance_old | string | 入口 |
| ads_id_new / ads_id_old | string | 广告 ID |
| campaign_id_new / campaign_id_old | string | 广告计划 ID |
| user_id_new / user_id_old | string | 用户 ID |
| account_id_new / account_id_old | string | 广告主 ID |
| shop_id_new / shop_id_old | string | 店铺 ID |
| item_id_new / item_id_old | string | 商品 ID |
| order_id_new / order_id_old | string | 订单 ID |
| request_id_new / request_id_old | string | 请求 ID |
| raw_request_id_new / raw_request_id_old | string | 原始请求 ID |
| deduct_unique_id_new / deduct_unique_id_old | string | 扣费唯一 ID |
| original_deduct_unique_id_new / original_deduct_unique_id_old | string | 原始扣费唯一 ID |
| unique_id_new / unique_id_old | string | 唯一标识（temporary view中） |
| ls_session_id_new / ls_session_id_old | string | 直播场次 ID |
| streamer_id_new / streamer_id_old | string | 主播 ID |
| creator_id_new / creator_id_old | string | 创作者 ID |
| original_itemid_new / original_itemid_old | string | 原始商品 ID |
| mapped_ads_itemid_new / mapped_ads_itemid_old | string | 映射后的广告商品 ID |
| click_event_id_new / click_event_id_old | string | 点击事件 ID |

### 花费/扣费列

| Column Name | Type | Description |
|-------------|------|-------------|
| expenditure_amt_local_new / expenditure_amt_local_old | string | 花费金额（本币） |
| expenditure_amt_usd_new / expenditure_amt_usd_old | string | 花费金额（USD） |
| raw_expense_new / raw_expense_old | string | 原始花费 |
| expense_by_cpm_new / expense_by_cpm_old | string | CPM花费 |
| expense_free_credit_with_expiry_new / expense_free_credit_with_expiry_old | string | 有有效期免费金花费 |
| expense_free_credit_without_expiry_new / expense_free_credit_without_expiry_old | string | 无有效期免费金花费 |
| expense_paid_credit_with_expiry_new / expense_paid_credit_with_expiry_old | string | 有有效期付费金花费 |
| expense_paid_credit_without_expiry_new / expense_paid_credit_without_expiry_old | string | 无有效期付费金花费 |
| expense_rebate_free_credit_without_expiry_new / expense_rebate_free_credit_without_expiry_old | string | 返券免费金花费 |
| deduction_price_new / deduction_price_old | string | 扣费金额 |
| voucher_deduction_price_new / voucher_deduction_price_old | string | 券扣费金额 |
| boost_deduction_price_new / boost_deduction_price_old | string | Boost扣费金额 |
| receivable_revenue_new / receivable_revenue_old | string | 应收收入 |
| expected_revenue_new / expected_revenue_old | string | 预期收入 |
| click_time_daily_budget_new / click_time_daily_budget_old | string | 点击时刻日预算 |

### 订单/GMV列

| Column Name | Type | Description |
|-------------|------|-------------|
| order_cnt_new / order_cnt_old | string | 订单数 |
| daily_order_cnt_new / daily_order_cnt_old | string | 当日订单数 |
| ads_order_gmv_local_new / ads_order_gmv_local_old | string | 广告订单GMV（本币） |
| ads_order_gmv_usd_new / ads_order_gmv_usd_old | string | 广告订单GMV（USD） |
| paid_order_gmv_local_new / paid_order_gmv_local_old | string | 已支付订单GMV（本币） |
| paid_order_gmv_usd_new / paid_order_gmv_usd_old | string | 已支付订单GMV（USD） |
| daily_gmv_amt_local_new / daily_gmv_amt_local_old | string | 当日GMV金额（本币） |
| daily_order_amount_new / daily_order_amount_old | string | 当日订单金额 |
| broad_gmv_amt_local_new / broad_gmv_amt_local_old | string | Broad归因GMV（本币） |
| broad_gmv_amt_usd_new / broad_gmv_amt_usd_old | string | Broad归因GMV（USD） |
| broad_order_cnt_new / broad_order_cnt_old | string | Broad归因订单数 |
| broad_item_cnt_new / broad_item_cnt_old | string | Broad归因商品数 |
| broad_order_1d_new / broad_order_1d_old | string | 1日Broad订单 |
| no_click_gmv_new / no_click_gmv_old | string | 无点击GMV |
| no_click_gmv_usd_new / no_click_gmv_usd_old | string | 无点击GMV（USD） |
| no_click_order_new / no_click_order_old | string | 无点击订单数 |
| no_click_item_count_new / no_click_item_count_old | string | 无点击商品数 |
| ads_item_sold_cnt_new / ads_item_sold_cnt_old | string | 广告商品售出数 |

### 付费/确认/结算

| Column Name | Type | Description |
|-------------|------|-------------|
| paid_order_cnt_new / paid_order_cnt_old | string | 已支付订单数 |
| paid_order_item_sold_cnt_new / paid_order_item_sold_cnt_old | string | 已支付商品售出数 |
| paid_checkout_cnt_new / paid_checkout_cnt_old | string | 已支付结算数 |
| paid_broad_order_cnt_new / paid_broad_order_cnt_old | string | 已支付Broad订单数 |
| paid_broad_order_gmv_new / paid_broad_order_gmv_old | string | 已支付Broad GMV |
| paid_broad_order_item_sold_cnt_new / paid_broad_order_item_sold_cnt_old | string | 已支付Broad商品售出数 |
| paid_broad_gmv_usd_new / paid_broad_gmv_usd_old | string | 已支付Broad GMV（USD） |
| paid_no_click_order_cnt_new / paid_no_click_order_cnt_old | string | 已支付无点击订单数 |
| paid_no_click_order_gmv_new / paid_no_click_order_gmv_old | string | 已支付无点击GMV |
| paid_no_click_order_item_sold_cnt_new / paid_no_click_order_item_sold_cnt_old | string | 已支付无点击商品售出数 |
| paid_no_click_order_gmv_usd_new / paid_no_click_order_gmv_usd_old | string | 已支付无点击GMV（USD） |
| paid_agent_order_cnt_new / paid_agent_order_cnt_old | string | 已支付代理订单数 |
| paid_agent_order_gmv_new / paid_agent_order_gmv_old | string | 已支付代理GMV |
| paid_agent_order_item_sold_cnt_new / paid_agent_order_item_sold_cnt_old | string | 已支付代理商品售出数 |
| paid_agent_order_gmv_usd_new / paid_agent_order_gmv_usd_old | string | 已支付代理GMV（USD） |
| paid_agent_checkout_cnt_new / paid_agent_checkout_cnt_old | string | 已支付代理结算数 |
| confirmed_order_cnt_new / confirmed_order_cnt_old | string | 已确认订单数 |
| checkout_cnt_new / checkout_cnt_old | string | 结算数 |
| agent_order_cnt_new / agent_order_cnt_old | string | 代理订单数 |
| agent_order_gmv_new / agent_order_gmv_old | string | 代理GMV |
| agent_order_gmv_usd_new / agent_order_gmv_usd_old | string | 代理GMV（USD） |
| agent_order_item_sold_cnt_new / agent_order_item_sold_cnt_old | string | 代理商品售出数 |
| agent_checkout_cnt_new / agent_checkout_cnt_old | string | 代理结算数 |

### 曝光/点击列

| Column Name | Type | Description |
|-------------|------|-------------|
| impression_cnt_new / impression_cnt_old | string | 曝光数 |
| click_cnt_new / click_cnt_old | string | 点击数 |
| raw_impression_new / raw_impression_old | string | 原始曝光 |
| raw_click_cnt_new / raw_click_cnt_old | string | 原始点击 |
| click_before_deduction_cnt_new / click_before_deduction_cnt_old | string | 扣费前点击 |
| deduct_impression_new / deduct_impression_old | string | 扣费曝光 |
| non_fraud_impression_new / non_fraud_impression_old | string | 非作弊曝光 |
| non_fraud_click_cnt_new / non_fraud_click_cnt_old | string | 非作弊点击 |
| deduplicated_click_new / deduplicated_click_old | string | 去重点击 |
| cps_dedup_click_new / cps_dedup_click_old | string | CPS去重点击 |
| page_view_new / page_view_old | string | 页面浏览 |
| shop_item_impression_cnt_new / shop_item_impression_cnt_old | string | 店铺商品曝光数 |
| broad_shop_item_impression_cnt_new / broad_shop_item_impression_cnt_old | string | Broad店铺商品曝光数 |

### 转化列

| Column Name | Type | Description |
|-------------|------|-------------|
| add_to_cart_cnt_new / add_to_cart_cnt_old | string | 加购数 |
| add_to_cart_without_clicks_cnt_new / add_to_cart_without_clicks_cnt_old | string | 无点击加购数 |
| broad_add_to_cart_cnt_new / broad_add_to_cart_cnt_old | string | Broad加购数 |
| product_click_new / product_click_old | string | 商品点击 |
| raw_product_click_new / raw_product_click_old | string | 原始商品点击 |
| shop_item_click_cnt_new / shop_item_click_cnt_old | string | 店铺商品点击数 |
| broad_shop_item_click_cnt_new / broad_shop_item_click_cnt_old | string | Broad店铺商品点击数 |

### Impression Attribution 列

| Column Name | Type | Description |
|-------------|------|-------------|
| imp_attr_order_cnt_new / imp_attr_order_cnt_old | string | 曝光归因订单数 |
| imp_attr_order_amount_new / imp_attr_order_amount_old | string | 曝光归因订单金额 |
| imp_attr_order_gmv_new / imp_attr_order_gmv_old | string | 曝光归因GMV |
| imp_attr_order_gmv_usd_new / imp_attr_order_gmv_usd_old | string | 曝光归因GMV（USD） |
| imp_attr_paid_order_cnt_new / imp_attr_paid_order_cnt_old | string | 曝光归因已支付订单数 |
| imp_attr_paid_order_gmv_new / imp_attr_paid_order_gmv_old | string | 曝光归因已支付GMV |
| imp_attr_paid_order_item_sold_cnt_new / imp_attr_paid_order_item_sold_cnt_old | string | 曝光归因已支付商品售出数 |
| imp_attr_paid_order_gmv_usd_new / imp_attr_paid_order_gmv_usd_old | string | 曝光归因已支付GMV（USD） |
| imp_attr_agent_order_cnt_new / imp_attr_agent_order_cnt_old | string | 曝光归因代理订单数 |
| imp_attr_agent_order_amount_new / imp_attr_agent_order_amount_old | string | 曝光归因代理订单金额 |
| imp_attr_agent_order_gmv_new / imp_attr_agent_order_gmv_old | string | 曝光归因代理GMV |
| imp_attr_agent_order_gmv_usd_new / imp_attr_agent_order_gmv_usd_old | string | 曝光归因代理GMV（USD） |

### 视频/直播列

| Column Name | Type | Description |
|-------------|------|-------------|
| view_new / view_old | string | 浏览数 |
| view_duration_new / view_duration_old | string | 浏览时长 |
| video_view_new / video_view_old | string | 视频浏览 |
| video_play_complete_new / video_play_complete_old | string | 视频播完 |
| video_play_3s_cnt_new / video_play_3s_cnt_old | string | 3秒播放数 |
| video_play_5s_cnt_new / video_play_5s_cnt_old | string | 5秒播放数 |
| video_id_new / video_id_old | string | 视频 ID |
| decoded_video_id_new / decoded_video_id_old | string | 解码后的视频 ID |
| vv_id_new / vv_id_old | string | VV ID |
| display_video_id_new / display_video_id_old | string | 展示视频 ID |
| shop_view_new / shop_view_old | string | 店铺浏览 |
| shop_video_play_new / shop_video_play_old | string | 店铺视频播放 |
| shop_video_play_complete_new / shop_video_play_complete_old | string | 店铺视频播完 |
| shop_video_play_time_new / shop_video_play_time_old | string | 店铺视频播放时长 |
| shop_video_click_new / shop_video_click_old | string | 店铺视频点击 |

### 投放/定向列

| Column Name | Type | Description |
|-------------|------|-------------|
| placement_new / placement_old | string | 广告位 |
| keyword_new / keyword_old | string | 关键词 |
| query_new / query_old | string | 搜索词 |
| match_type_new / match_type_old | string | 匹配方式 |
| location_in_ads_new / location_in_ads_old | string | 广告内位置 |
| location_new / location_old | string | 地域 |
| platform_new / platform_old | string | 平台 |
| app_version_new / app_version_old | string | App版本 |
| sub_entrance_new / sub_entrance_old | string | 子入口 |
| entrance_group_new / entrance_group_old | string | 入口组 |
| landing_url_type_new / landing_url_type_old | string | 落地页类型 |
| traffic_source_new / traffic_source_old | string | 流量来源 |
| page_type_new / page_type_old | string | 页面类型 |
| page_section_new / page_section_old | string | 页面位置 |
| target_type_new / target_type_old | string | 定向类型 |
| target_cir_new / target_cir_old | string | 目标CIR |
| slot_id_new / slot_id_old | string | 广告位ID |
| click_area_new / click_area_old | string | 点击区域 |
| attr_data_type_new / attr_data_type_old | string | 归因数据类型 |
| sort_by_new / sort_by_old | string | 排序方式 |

### 搜索广告列

| Column Name | Type | Description |
|-------------|------|-------------|
| search_origin_bid_price_local_new / search_origin_bid_price_local_old | string | 搜索原始出价（本币） |
| search_bid_type_new / search_bid_type_old | string | 搜索出价类型 |
| search_capped_price_new / search_capped_price_old | string | 搜索封顶价 |
| search_scenario_new / search_scenario_old | string | 搜索场景 |
| search_entrance_new / search_entrance_old | string | 搜索入口 |
| search_mid_new / search_mid_old | string | 搜索 MID |
| keywords_group_type_new / keywords_group_type_old | string | 关键词组类型 |

### 出价/模型列

| Column Name | Type | Description |
|-------------|------|-------------|
| origin_bid_price_new / origin_bid_price_old | string | 原始出价 |
| cpm_new / cpm_old | string | CPM |
| origin_item_id_new / origin_item_id_old | string | 原始商品 ID |
| pricing_type_new / pricing_type_old | string | 计费类型 |
| is_ocpm_new / is_ocpm_old | string | 是否 OCPM (值: 0/1) |
| bid_voucher_id_new / bid_voucher_id_old | string | 出价券 ID |
| model_id_new / model_id_old | string | 模型 ID |
| v_model_id_new / v_model_id_old | string | V模型 ID |
| v_item_id_new / v_item_id_old | string | V商品 ID |
| order_item_has_spu_vmodel_new / order_item_has_spu_vmodel_old | string | 订单商品有SPU VModel |
| is_preselected_vmodel_new / is_preselected_vmodel_old | string | 是否预选VModel |
| uni_pcr_model_name_new / uni_pcr_model_name_old | string | 统一PCR模型名称 |
| bid_rerank_trace_new / bid_rerank_trace_old | string | 出价重排序追踪 |
| roi_upper_bound_new / roi_upper_bound_old | string | ROI 上限 |
| plan_bucket_list_new / plan_bucket_list_old | string | 计划桶列表 |
| traffic_bucket_list_new / traffic_bucket_list_old | string | 流量桶列表 |
| creative_algo_new / creative_algo_old | string | 创意算法 |
| creative_id_new / creative_id_old | string | 创意 ID |
| image_id_new / image_id_old | string | 图片 ID |

### 时效/时间戳列

| Column Name | Type | Description |
|-------------|------|-------------|
| click_timestamp_new / click_timestamp_old | string | 点击时间戳 |
| click_datetime_new / click_datetime_old | string | 点击时间 |
| event_timestamp_new / event_timestamp_old | string | 事件时间戳 |
| event_datetime_new / event_datetime_old | string | 事件时间 |
| paid_timestamp_new / paid_timestamp_old | string | 支付时间戳 |
| paid_datetime_new / paid_datetime_old | string | 支付时间 |
| confirmed_timestamp_new / confirmed_timestamp_old | string | 确认时间戳 |
| confirmed_datetime_new / confirmed_datetime_old | string | 确认时间 |
| deduct_timestamp_new / deduct_timestamp_old | string | 扣费时间戳 |
| deduct_datetime_new / deduct_datetime_old | string | 扣费时间 |
| imp_timestamp_new / imp_timestamp_old | string | 曝光时间戳 |
| timestamp_new / timestamp_old | string | 时间戳 |
| response_timestamp_new / response_timestamp_old | string | 响应时间戳 |
| original_order_timestamp_new / original_order_timestamp_old | string | 原始订单时间戳 |

### 券/折扣列

| Column Name | Type | Description |
|-------------|------|-------------|
| voucher_details_new / voucher_details_old | string | 券详情 |
| voucher_details_json_new / voucher_details_json_old | string | 券详情JSON |
| ads_voucher_auto_claimed_new / ads_voucher_auto_claimed_old | string | 广告券自动领取 |

### Boost/New Product Boost 列

| Column Name | Type | Description |
|-------------|------|-------------|
| new_boost_new / new_boost_old | string | 新品Boost (值: 0/1) |
| new_product_boost_coef_new / new_product_boost_coef_old | string | 新品Boost系数 |
| new_product_boost_stage_new / new_product_boost_stage_old | string | 新品Boost阶段 |
| rapid_boost_toggle_new / rapid_boost_toggle_old | string | 快速Boost开关 |
| rapid_boost_state_new / rapid_boost_state_old | string | 快速Boost状态 |

### 其他属性列

| Column Name | Type | Description |
|-------------|------|-------------|
| ab_sign_new / ab_sign_old | string | AB实验标识 |
| is_cod_new / is_cod_old | string | 是否COD (值: 0/1) |
| matched_premium_segment_new / matched_premium_segment_old | string | 匹配的溢价分段 |
| matched_premium_segment_type_id_new / matched_premium_segment_type_id_old | string | 溢价分段类型 ID |
| matched_premium_segment_value_id_new / matched_premium_segment_value_id_old | string | 溢价分段值 ID |
| ta_group_id_new / ta_group_id_old | string | TA分组 ID |
| ta_matched_tag_ids_new / ta_matched_tag_ids_old | string | TA匹配标签 ID |
| ta_premium_rate_new / ta_premium_rate_old | string | TA溢价率 |
| tag_ids_new / tag_ids_old | string | 标签ID |
| algo_json_data_new / algo_json_data_old | string | 算法JSON数据 |
| duplicate_label_new / duplicate_label_old | string | 重复标签 |
| ad_tag_new / ad_tag_old | string | 广告标签 |
| display_ads_tag_new / display_ads_tag_old | string | 展示广告标签 (值: 0/1) |
| shop_recall_type_new / shop_recall_type_old | string | 店铺召回类型 |
| shop_exp_tag_new / shop_exp_tag_old | string | 店铺实验标签 |
| deduction_reason_new / deduction_reason_old | string | 扣费原因 |
| ctx_item_type_new / ctx_item_type_old | string | 上下文商品类型 |
| deduction_price_new / deduction_price_old | string | 扣费金额 |
| brand_max_target_type_new / brand_max_target_type_old | string | Brand Max定向类型 |
| brand_max_ads_type_new / brand_max_ads_type_old | string | Brand Max广告类型 |
| package_request_id_new / package_request_id_old | string | 打包请求 ID |
| package_request_asset_id_new / package_request_asset_id_old | string | 打包请求资产 ID |
| campaign_surge_toggle_new / campaign_surge_toggle_old | string | 计划增量开关 |
| deduct_order_new / deduct_order_old | string | 扣费订单 |
| avg_sold_cnt_shop_new / avg_sold_cnt_shop_old | string | 店铺平均售出数 |
| avg_sold_cnt_item_new / avg_sold_cnt_item_old | string | 商品平均售出数 |
| item_price_new / item_price_old | string | 商品价格（已除以100000） |
| item_price_shop_new / item_price_shop_old | string | 店铺商品价格 |
