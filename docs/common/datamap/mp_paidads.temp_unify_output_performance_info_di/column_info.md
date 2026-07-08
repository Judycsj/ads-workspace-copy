<!-- ads-workspace-gdoc-sync: gdoc_id=1WuEsoEkXoFCVSCa5kaYWCv8kvtXcKJuUezmivQtTVes gdoc_url=https://docs.google.com/document/d/1WuEsoEkXoFCVSCa5kaYWCv8kvtXcKJuUezmivQtTVes/edit -->

# Columns: mp_paidads.temp_unify_output_performance_info_di

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为 row-level 对比表，所有 *_old / *_new 字段均为单条记录的值，不可直接 SUM 跨行聚合。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| type | traffic | 流量效果对比 |
| type | attribution_order | 订单归因效果对比 |
| type | attribution_addtocart_imp | ATC+展示归因效果对比 |
| type | finance | 扣费效果对比（读取端存在，写入端未见） |

### 常见 WHERE 值 (Common Filter Values)

- `type`: 'traffic' / 'attribution_order' / 'attribution_addtocart_imp' / 'finance'
- `grass_region`: 'PH' (测试中主要使用)
- `grass_date`: 按需指定日期
- `new_join_key IS NOT NULL`: 过滤已关联上的记录（dashboard 端必用）
- `new_join_key IS NULL`: 查找未关联上的记录
- `*_old IS DISTINCT FROM *_new`: 查找新旧值差异记录
- `entrance IN (27,28,37,38,39)`: 特定入口筛选
- `h_new = 8`: 按小时筛选

## All Columns

> 此表结构为 paired columns：每个业务字段都有 `*_old` 和 `*_new` 两个列，分别存储旧版和新版数据流的值。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | bigint | 入口ID | - | - |
| join_key | string | 旧版关联键（entrance:xxx,order_id:xxx,item_id:xxx 或 entrance:xxx,unique_id:xxx） | - | - |
| new_join_key | string | 新版关联键（格式同 join_key），NULL 表示新旧未能关联 | - | - |
| ads_id_old | string | 旧版广告ID | - | - |
| ads_id_new | string | 新版广告ID | - | - |
| item_id_old | string | 旧版商品ID | - | - |
| item_id_new | string | 新版商品ID | - | - |
| shop_id_old | string | 旧版店铺ID | - | - |
| shop_id_new | string | 新版店铺ID | - | - |
| user_id_old | string | 旧版用户ID | - | - |
| user_id_new | string | 新版用户ID | - | - |
| account_id_old | string | 旧版账户ID | - | - |
| account_id_new | string | 新版账户ID | - | - |
| streamer_id_old | string | 旧版主播ID | - | - |
| streamer_id_new | string | 新版主播ID | - | - |
| ls_session_id_old | string | 旧版直播场次ID | - | - |
| ls_session_id_new | string | 新版直播场次ID | - | - |
| campaign_id_old | string | 旧版计划ID | - | - |
| campaign_id_new | string | 新版计划ID | - | - |
| placement_old | string | 旧版广告位 | - | - |
| placement_new | string | 新版广告位 | - | - |
| timestamp_old | string | 旧版时间戳 | - | - |
| timestamp_new | string | 新版时间戳 | - | - |
| keyword_old | string | 旧版关键词 | - | - |
| keyword_new | string | 新版关键词 | - | - |
| query_old | string | 旧版搜索词 | - | - |
| query_new | string | 新版搜索词 | - | - |
| match_type_old | string | 旧版匹配类型 | - | - |
| match_type_new | string | 新版匹配类型 | - | - |
| order_id_old | string | 旧版订单ID | - | - |
| order_id_new | string | 新版订单ID | - | - |
| model_id_old | string | 旧版模型ID | - | - |
| model_id_new | string | 新版模型ID | - | - |
| request_id_old | string | 旧版请求ID | - | - |
| ads_request_id_new | string | 新版广告请求ID | - | - |
| ab_sign_old | string | 旧版AB签名 | - | - |
| ab_sign_new | string | 新版AB签名 | - | - |
| location_old | string | 旧版位置 | - | - |
| location_new | string | 新版位置 | - | - |
| app_version_old | string | 旧版App版本 | - | - |
| app_version_new | string | 新版App版本 | - | - |
| platform_old | string | 旧版平台 | - | - |
| platform_new | string | 新版平台 | - | - |
| is_cod_old | string | 旧版货到付款标识 | - | - |
| is_cod_new | string | 新版货到付款标识 | - | - |
| click_timestamp_old | string | 旧版点击时间戳 | - | - |
| click_timestamp_new | string | 新版点击时间戳 | - | - |
| paid_order_cnt_old | string | 旧版已支付订单数 | - | - |
| paid_direct_order_cnt_new | string | 新版直接已支付订单数 | - | - |
| paid_timestamp_old | string | 旧版支付时间戳 | - | - |
| paid_timestamp_new | string | 新版支付时间戳 | - | - |
| confirmed_timestamp_old | string | 旧版确认时间戳 | - | - |
| confirmed_timestamp_new | string | 新版确认时间戳 | - | - |
| pricing_type_old | string | 旧版出价类型 | - | - |
| pricing_type_new | string | 新版出价类型 | - | - |
| ta_group_id_old | string | 旧版TA分组ID | - | - |
| ta_group_id_new | string | 新版TA分组ID | - | - |
| click_cnt_old | string | 旧版点击次数 | - | - |
| deduct_click_cnt_new | string | 新版扣费点击次数 | - | - |
| raw_click_cnt_old | string | 旧版原始点击次数 | - | - |
| raw_click_cnt_new | string | 新版原始点击次数 | - | - |
| impression_cnt_old | string | 旧版展示次数 | - | - |
| deduplicated_impression_cnt_new | string | 新版去重展示次数 | - | - |
| add_to_cart_cnt_old | string | 旧版加购次数 | - | - |
| direct_add_to_cart_cnt_new | string | 新版直接加购次数 | - | - |
| location_in_ads_old | string | 旧版广告内位置 | - | - |
| location_in_ads_new | string | 新版广告内位置 | - | - |
| order_cnt_old | string | 旧版下单数 | - | - |
| place_direct_order_cnt_new | string | 新版直接下单数 | - | - |
| ads_item_sold_cnt_old | string | 旧版广告商品售出数 | - | - |
| place_direct_order_item_sold_cnt_new | string | 新版直接下单商品售出数 | - | - |
| ads_order_gmv_local_old | string | 旧版广告订单GMV（本币） | - | - |
| place_direct_order_gmv_new | string | 新版直接下单GMV | - | - |
| paid_order_gmv_local_old | string | 旧版已支付订单GMV（本币） | - | - |
| paid_direct_order_gmv_new | string | 新版直接已支付订单GMV | - | - |
| raw_expense_old | string | 旧版原始花费 | - | - |
| raw_expense_new | string | 新版原始花费 | - | - |
| broad_order_cnt_old | string | 旧版广义下单数 | - | - |
| place_broad_order_cnt_new | string | 新版广义下单数 | - | - |
| broad_item_cnt_old | string | 旧版广义商品数 | - | - |
| place_broad_order_item_sold_cnt_new | string | 新版广义下单商品售出数 | - | - |
| broad_gmv_amt_local_old | string | 旧版广义GMV（本币） | - | - |
| place_broad_order_gmv_new | string | 新版广义下单GMV | - | - |
| shop_item_click_cnt_old | string | 旧版店铺商品点击次数 | - | - |
| direct_shop_item_click_cnt_new | string | 新版直接店铺商品点击次数 | - | - |
| broad_shop_item_click_cnt_old | string | 旧版广义店铺商品点击次数 | - | - |
| broad_shop_item_click_cnt_new | string | 新版广义店铺商品点击次数 | - | - |
| shop_item_impression_cnt_old | string | 旧版店铺商品展示次数 | - | - |
| direct_shop_item_impression_cnt_new | string | 新版直接店铺商品展示次数 | - | - |
| broad_shop_item_impression_cnt_old | string | 旧版广义店铺商品展示次数 | - | - |
| broad_shop_item_impression_cnt_new | string | 新版广义店铺商品展示次数 | - | - |
| expense_free_credit_with_expiry_old | string | 旧版有过期免费金花费 | - | - |
| free_with_expiry_expense_new | string | 新版有过期免费金花费 | - | - |
| expense_free_credit_without_expiry_old | string | 旧版无过期免费金花费 | - | - |
| free_without_expiry_expense_new | string | 新版无过期免费金花费 | - | - |
| expense_paid_credit_with_expiry_old | string | 旧版有过期付费金花费 | - | - |
| paid_with_expiry_expense_new | string | 新版有过期付费金花费 | - | - |
| expense_paid_credit_without_expiry_old | string | 旧版无过期付费金花费 | - | - |
| paid_without_expiry_expense_new | string | 新版无过期付费金花费 | - | - |
| checkout_cnt_old | string | 旧版结账次数 | - | - |
| place_checkout_cnt_new | string | 新版下单结账次数 | - | - |
| click_area_old | string | 旧版点击区域 | - | - |
| click_area_new | string | 新版点击区域 | - | - |
| expense_by_cpm_old | string | 旧版CPM花费 | - | - |
| expense_by_cpm_new | string | 新版CPM花费 | - | - |
| cpm_old | string | 旧版CPM | - | - |
| cpm_new | string | 新版CPM | - | - |
| non_fraud_click_cnt_old | string | 旧版非作弊点击次数 | - | - |
| non_fraud_click_cnt_new | string | 新版非作弊点击次数 | - | - |
| broad_add_to_cart_cnt_old | string | 旧版广义加购次数 | - | - |
| broad_add_to_cart_cnt_new | string | 新版广义加购次数 | - | - |
| add_to_cart_without_clicks_cnt_old | string | 旧版无点击加购次数 | - | - |
| add_to_cart_without_click_cnt_new | string | 新版无点击加购次数 | - | - |
| new_boost_old | string | 旧版新品助推标识 | - | - |
| is_new_boost_new | string | 新版新品助推标识 | - | - |
| ta_matched_tag_ids_old | array<bigint> | 旧版TA匹配标签 | - | - |
| ta_matched_tag_ids_new | array<bigint> | 新版TA匹配标签 | - | - |
| ta_premium_rate_old | string | 旧版TA溢价率 | - | - |
| ta_premium_rate_new | string | 新版TA溢价率 | - | - |
| deduct_unique_id_old | string | 旧版扣费唯一ID | - | - |
| deduct_unique_id_new | string | 新版扣费唯一ID | - | - |
| click_event_id_old | string | 旧版点击事件ID | - | - |
| click_event_id_new | string | 新版点击事件ID | - | - |
| display_ads_tag_old | string | 旧版广告标签展示 | - | - |
| is_ad_tag_displayed_new | string | 新版广告标签展示 | - | - |
| page_type_old | string | 旧版页面类型 | - | - |
| page_type_new | string | 新版页面类型 | - | - |
| page_section_old | string | 旧版页面区域 | - | - |
| page_section_new | string | 新版页面区域 | - | - |
| target_type_old | string | 旧版定向类型 | - | - |
| target_type_new | string | 新版定向类型 | - | - |
| search_scenario_old | string | 旧版搜索场景 | - | - |
| search_scenario_new | string | 新版搜索场景 | - | - |
| search_entrance_old | string | 旧版搜索入口 | - | - |
| search_entrance_new | string | 新版搜索入口 | - | - |
| search_mid_old | string | 旧版搜索mid | - | - |
| search_mid_new | string | 新版搜索mid | - | - |
| sort_by_old | string | 旧版排序方式 | - | - |
| sort_by_new | string | 新版排序方式 | - | - |
| raw_request_id_old | string | 旧版原始请求ID | - | - |
| raw_request_id_new | string | 新版原始请求ID | - | - |
| video_id_old | string | 旧版视频ID | - | - |
| video_id_new | string | 新版视频ID | - | - |
| target_cir_old | string | 旧版目标CIR | - | - |
| target_cir_new | string | 新版目标CIR | - | - |
| decoded_video_id_old | string | 旧版解码视频ID | - | - |
| decoded_video_id_new | string | 新版解码视频ID | - | - |
| item_price_old | string | 旧版商品价格 | - | - |
| item_price_new | string | 新版商品价格 | - | - |
| new_product_boost_coef_old | string | 旧版新品助推系数 | - | - |
| new_product_boost_coef_new | string | 新版新品助推系数 | - | - |
| new_product_boost_stage_old | string | 旧版新品助推阶段 | - | - |
| new_product_boost_stage_new | string | 新版新品助推阶段 | - | - |
| vv_id_old | string | 旧版视频播放ID | - | - |
| video_view_id_new | string | 新版视频播放ID | - | - |
| voucher_details_old | string | 旧版券详情 | - | - |
| voucher_details_new | string | 新版券详情 | - | - |
| ctx_item_type_old | string | 旧版上下文商品类型 | - | - |
| ctx_item_type_new | string | 新版上下文商品类型 | - | - |
| v_model_id_old | string | 旧版视频模型ID | - | - |
| v_model_id_new | string | 新版视频模型ID | - | - |
| v_item_id_old | string | 旧版视频商品ID | - | - |
| v_item_id_new | string | 新版视频商品ID | - | - |
| order_item_has_spu_vmodel_old | string | 旧版订单商品SPU视频模型 | - | - |
| is_order_item_has_spu_vmodel_new | string | 新版订单商品SPU视频模型 | - | - |
| sub_entrance_old | string | 旧版子入口 | - | - |
| sub_entrance_new | string | 新版子入口 | - | - |
| page_view_old | string | 旧版页面浏览 | - | - |
| page_view_cnt_new | string | 新版页面浏览次数 | - | - |
| view_old | string | 旧版直播观看 | - | - |
| live_view_cnt_new | string | 新版直播观看次数 | - | - |
| view_duration_old | string | 旧版观看时长 | - | - |
| view_duration_new | string | 新版观看时长 | - | - |
| product_click_old | string | 旧版商品点击 | - | - |
| product_click_cnt_new | string | 新版商品点击次数 | - | - |
| deduct_impression_old | string | 旧版扣费展示 | - | - |
| deduct_impression_cnt_new | string | 新版扣费展示次数 | - | - |
| non_fraud_impression_old | string | 旧版非作弊展示 | - | - |
| non_fraud_impression_cnt_new | string | 新版非作弊展示次数 | - | - |
| attr_data_type_old | string | 旧版归因数据类型 | - | - |
| attr_data_type_new | string | 新版归因数据类型 | - | - |
| traffic_source_old | string | 旧版流量来源 | - | - |
| traffic_source_new | string | 新版流量来源 | - | - |
| agent_order_cnt_old | string | 旧版代理下单数 | - | - |
| place_agent_order_cnt_new | string | 新版代理下单数 | - | - |
| agent_order_item_sold_cnt_old | string | 旧版代理下单商品数 | - | - |
| place_agent_order_item_sold_cnt_new | string | 新版代理下单商品数 | - | - |
| agent_order_gmv_old | string | 旧版代理下单GMV | - | - |
| place_agent_order_gmv_new | string | 新版代理下单GMV | - | - |
| agent_checkout_cnt_old | string | 旧版代理结账数 | - | - |
| place_agent_checkout_cnt_new | string | 新版代理结账数 | - | - |
| algo_json_data_old | string | 旧版算法JSON数据 | - | - |
| algo_json_data_new | string | 新版算法JSON数据 | - | - |
| shop_recall_type_old | string | 旧版店铺召回类型 | - | - |
| shop_recall_type_new | string | 新版店铺召回类型 | - | - |
| raw_impression_old | string | 旧版原始展示 | - | - |
| raw_impression_cnt_new | string | 新版原始展示次数 | - | - |
| deduplicated_click_old | string | 旧版去重点击 | - | - |
| deduplicated_click_cnt_new | string | 新版去重点击次数 | - | - |
| video_view_old | string | 旧版视频播放 | - | - |
| video_view_cnt_new | string | 新版视频播放次数 | - | - |
| raw_product_click_old | string | 旧版原始商品点击 | - | - |
| raw_product_click_cnt_new | string | 新版原始商品点击次数 | - | - |
| video_play_complete_old | string | 旧版视频完播 | - | - |
| video_play_complete_cnt_new | string | 新版视频完播次数 | - | - |
| ads_voucher_auto_claimed_old | string | 旧版广告券自动领取 | - | - |
| is_ads_voucher_auto_claimed_new | string | 新版广告券自动领取 | - | - |
| no_click_order_old | string | 旧版无点击下单 | - | - |
| place_no_click_order_cnt_new | string | 新版无点击下单数 | - | - |
| no_click_item_count_old | string | 旧版无点击商品数 | - | - |
| place_no_click_order_item_sold_cnt_new | string | 新版无点击下单商品数 | - | - |
| no_click_gmv_old | string | 旧版无点击GMV | - | - |
| place_no_click_order_gmv_new | string | 新版无点击下单GMV | - | - |
| plan_bucket_list_old | array<bigint> | 旧版计划桶列表 | - | - |
| plan_bucket_list_new | array<bigint> | 新版计划桶列表 | - | - |
| bid_rerank_trace_old | string | 旧版出价重排追踪 | - | - |
| bid_rerank_trace_new | string | 新版出价重排追踪 | - | - |
| uni_pcr_model_name_old | string | 旧版统一PCR模型名 | - | - |
| uni_pcr_model_name_new | string | 新版统一PCR模型名 | - | - |
| item_price_shop_old | string | 旧版商品店铺价 | - | - |
| item_price_shop_new | string | 新版商品店铺价 | - | - |
| expense_rebate_free_credit_without_expiry_old | string | 旧版无过期返利免费金花费 | - | - |
| free_without_expiry_rebate_expense_new | string | 新版无过期返利免费金花费 | - | - |
| original_itemid_old | string | 旧版原始商品ID | - | - |
| original_itemid_new | string | 新版原始商品ID | - | - |
| mapped_ads_itemid_old | string | 旧版映射广告商品ID | - | - |
| mapped_ads_itemid_new | string | 新版映射广告商品ID | - | - |
| duplicate_label_old | string | 旧版重复标签 | - | - |
| duplicate_label_new | string | 新版重复标签 | - | - |
| ad_tag_old | string | 旧版广告标签 | - | - |
| ad_attr_flags_new | string | 新版广告属性标志 | - | - |
| imp_attr_order_cnt_old | string | 旧版展示归因下单数 | - | - |
| imp_attr_place_order_cnt_new | string | 新版展示归因下单数 | - | - |
| imp_attr_order_amount_old | string | 旧版展示归因下单金额 | - | - |
| imp_attr_place_order_item_sold_cnt_new | string | 新版展示归因下单商品数 | - | - |
| imp_attr_order_gmv_old | string | 旧版展示归因GMV | - | - |
| imp_attr_place_order_gmv_new | string | 新版展示归因下单GMV | - | - |
| imp_attr_paid_order_cnt_old | string | 旧版展示归因支付订单数 | - | - |
| imp_attr_paid_order_cnt_new | string | 新版展示归因支付订单数 | - | - |
| imp_attr_paid_order_item_sold_cnt_old | string | 旧版展示归因支付商品数 | - | - |
| imp_attr_paid_order_item_sold_cnt_new | string | 新版展示归因支付商品数 | - | - |
| imp_attr_paid_order_gmv_old | string | 旧版展示归因支付GMV | - | - |
| imp_attr_paid_order_gmv_new | string | 新版展示归因支付GMV | - | - |
| paid_order_item_sold_cnt_old | string | 旧版已支付商品数 | - | - |
| paid_direct_order_item_sold_cnt_new | string | 新版直接已支付商品数 | - | - |
| paid_broad_order_cnt_old | string | 旧版已支付广义下单数 | - | - |
| paid_broad_order_cnt_new | string | 新版已支付广义下单数 | - | - |
| paid_broad_order_gmv_old | string | 旧版已支付广义GMV | - | - |
| paid_broad_order_gmv_new | string | 新版已支付广义GMV | - | - |
| paid_broad_order_item_sold_cnt_old | string | 旧版已支付广义商品数 | - | - |
| paid_broad_order_item_sold_cnt_new | string | 新版已支付广义商品数 | - | - |
| paid_no_click_order_cnt_old | string | 旧版已支付无点击下单数 | - | - |
| paid_no_click_order_cnt_new | string | 新版已支付无点击下单数 | - | - |
| paid_agent_order_cnt_old | string | 旧版已支付代理下单数 | - | - |
| paid_agent_order_cnt_new | string | 新版已支付代理下单数 | - | - |
| paid_agent_order_item_sold_cnt_old | string | 旧版已支付代理商品数 | - | - |
| paid_agent_order_item_sold_cnt_new | string | 新版已支付代理商品数 | - | - |
| paid_agent_order_gmv_old | string | 旧版已支付代理GMV | - | - |
| paid_agent_order_gmv_new | string | 新版已支付代理GMV | - | - |
| paid_checkout_cnt_old | string | 旧版已支付结账数 | - | - |
| paid_checkout_cnt_new | string | 新版已支付结账数 | - | - |
| paid_agent_checkout_cnt_old | string | 旧版已支付代理结账数 | - | - |
| paid_agent_checkout_cnt_new | string | 新版已支付代理结账数 | - | - |
| paid_no_click_order_item_sold_cnt_old | string | 旧版已支付无点击商品数 | - | - |
| paid_no_click_order_item_sold_cnt_new | string | 新版已支付无点击商品数 | - | - |
| paid_no_click_order_gmv_old | string | 旧版已支付无点击GMV | - | - |
| paid_no_click_order_gmv_new | string | 新版已支付无点击GMV | - | - |
| shop_view_old | string | 旧版店铺浏览 | - | - |
| shop_view_cnt_new | string | 新版店铺浏览次数 | - | - |
| shop_video_play_old | string | 旧版店铺视频播放 | - | - |
| shop_video_play_cnt_new | string | 新版店铺视频播放次数 | - | - |
| shop_video_play_complete_old | string | 旧版店铺视频完播 | - | - |
| shop_video_play_complete_cnt_new | string | 新版店铺视频完播次数 | - | - |
| shop_video_play_time_old | string | 旧版店铺视频播放时长 | - | - |
| shop_video_play_duration_new | string | 新版店铺视频播放时长 | - | - |
| shop_video_click_old | string | 旧版店铺视频点击 | - | - |
| shop_video_click_cnt_new | string | 新版店铺视频点击次数 | - | - |
| brand_max_target_type_old | string | 旧版品牌Max定向类型 | - | - |
| brand_max_target_type_new | string | 新版品牌Max定向类型 | - | - |
| imp_timestamp_old | string | 旧版展示时间戳 | - | - |
| imp_timestamp_new | string | 新版展示时间戳 | - | - |
| traffic_bucket_list_old | array<bigint> | 旧版流量桶列表 | - | - |
| traffic_bucket_list_new | array<bigint> | 新版流量桶列表 | - | - |
| deduction_reason_old | string | 旧版扣费原因 | - | - |
| deduction_reason_new | string | 新版扣费原因 | - | - |
| is_ocpm_old | string | 旧版OCPM标识 | - | - |
| is_ocpm_new | string | 新版OCPM标识 | - | - |
| keywords_group_type_old | string | 旧版关键词组类型 | - | - |
| keywords_group_type_new | string | 新版关键词组类型 | - | - |
| brand_max_ads_type_old | string | 旧版品牌Max广告类型 | - | - |
| brand_max_ads_type_new | string | 新版品牌Max广告类型 | - | - |
| package_request_id_old | string | 旧版包请求ID | - | - |
| package_request_id_new | string | 新版包请求ID | - | - |
| package_request_asset_id_old | string | 旧版包请求资产ID | - | - |
| package_request_asset_id_new | string | 新版包请求资产ID | - | - |
| boost_deduction_price_old | string | 旧版助推扣费价格 | - | - |
| boost_deduction_price_new | string | 新版助推扣费价格 | - | - |
| creator_id_old | string | 旧版创作者ID | - | - |
| video_creator_id_new | string | 新版视频创作者ID | - | - |
| expenditure_amt_local_old | string | 旧版花费（本币） | - | - |
| expense_new | string | 新版花费 | - | - |
| h_new | string | 新版小时（仅在 write INSERT 中包含，DDL 中未定义） | - | - |

### Partition Columns

| Column Name | Type | Description |
|-------------|------|-------------|
| grass_region | string | 地区 |
| grass_date | date | 分区日期 |
| type | string | 数据类型：traffic / attribution_order / attribution_addtocart_imp / finance |
