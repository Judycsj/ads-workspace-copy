<!-- ads-workspace-gdoc-sync: gdoc_id=1wB4O446BHQrcr2uQoB0xmhzqH4nnsQULEX-FqZU_ckY gdoc_url=https://docs.google.com/document/d/1wB4O446BHQrcr2uQoB0xmhzqH4nnsQULEX-FqZU_ckY/edit -->

# mp_paidads.temp_dwd_event_performance_di__reg_s0_live

## Description

- **Desc:** 临时表，事件级广告效果明细宽表。整合多路数据源的事件级指标和维度：
  - 大部分区域（VN, SG, TH, TW, MY, ID, MX, BR）：从 `paidads_mart.dwd_event_performance_hi__reg_s0_live` 读入后 JOIN 辅助维表做字段补齐
  - PH 区域：使用 UDF 从 5 个数据源（Report NG, Livestream Report, CPM deduction, CPM deduction fix, CPC/CPS deduction）UNION ALL 后整合
  - 作为统一输出（unify output）的新旧数据映射差异校验底座（traffic / finance / attribution / attribution_atc 四个维度）
- **Granularity:** event-level（每行一个广告事件，核心粒度为 deduct_unique_id + ads_id + user_id / entrance / unique_id）
- **Use Case:**
  - Unify Output mapping 对比校验 — 对比新旧 performance 映射在 traffic / finance / attribution / attribution_atc 四个维度的差异（shengyu.wang）
  - Finance 拆账数据验证 — 对比 `dwd_advertise_performance_di__reg_s0_live`（旧）与 `temp_dwd_event_performance_di__reg_s0_live`（新）的 expense/item_price 差异
  - 单条事件明细查询和 debug（yaweizhang）
  - CPM 扣费多源数据整合（PH 专用）
- **Update Frequency:** Daily（每个 region 的工作流独立运行一次，partition overwrite）
- **Temporary:** Yes — "temp_" 前缀表，用于数据验证和过渡期对比，无长期保留策略

## Key Metrics

从 write/read SQL 中归纳的核心指标：

- **花费类**: expenditure_amt_local, expenditure_amt_usd, raw_expense, expense_rebate_free_credit_without_expiry
- **拆账类**: expense_paid_credit_with_expiry, expense_paid_credit_without_expiry, expense_free_credit_with_expiry, expense_free_credit_without_expiry
- **曝光点击类**: impression_cnt, click_cnt, click_before_deduction_cnt, raw_click_cnt, deduct_impression, non_fraud_impression, raw_impression, deduplicated_click, non_fraud_click_cnt
- **订单效果类**: order_cnt, checkout_cnt, ads_item_sold_cnt, ads_order_gmv_local, ads_order_gmv_usd, daily_order_cnt, daily_gmv_amt_local, daily_order_amount, broad_order_cnt, broad_item_cnt, broad_gmv_amt_local, broad_gmv_amt_usd, broad_order_1d
- **付费效果类**: paid_order_cnt, paid_order_item_sold_cnt, paid_order_gmv_local, paid_order_gmv_usd, paid_checkout_cnt, paid_broad_order_cnt, paid_broad_order_gmv, paid_broad_order_item_sold_cnt, paid_broad_gmv_usd, confirmed_order_cnt
- **浏览互动类**: shop_item_click_cnt, shop_item_impression_cnt, broad_shop_item_click_cnt, broad_shop_item_impression_cnt, add_to_cart_cnt, add_to_cart_without_clicks_cnt, broad_add_to_cart_cnt, product_click, page_view, shop_view, shop_video_play, shop_video_play_complete, shop_video_play_time, shop_video_click
- **直播指标类**: view, view_duration, video_view, video_play_complete, video_play_3s_cnt, video_play_5s_cnt, raw_product_click
- **归因效果类**: imp_attr_order_cnt, imp_attr_order_amount, imp_attr_order_gmv, imp_attr_paid_order_cnt, imp_attr_paid_order_item_sold_cnt, imp_attr_paid_order_gmv（及各自 usd/agent 变体）
- **No-Click 类**: no_click_order, no_click_item_count, no_click_gmv, paid_no_click_order_cnt, paid_no_click_order_gmv, paid_no_click_order_item_sold_cnt
- **Agent 类**: agent_order_cnt, agent_order_item_sold_cnt, agent_order_gmv, agent_checkout_cnt, paid_agent_order_cnt, paid_agent_order_item_sold_cnt, paid_agent_order_gmv, paid_agent_checkout_cnt
- **CPM 类**: cpm, expense_by_cpm, boost_deduction_price
- **券类**: voucher_deduction_price, deduction_price, ads_voucher_auto_claimed, bid_voucher_id, voucher_details, voucher_details_json
- **预期/应收**: expected_revenue, receivable_revenue, target_cir, roi_upper_bound

## Key Dimensions

- **分区维度**: tz_type ('local'), grass_region ('ID','MY','PH','SG','TH','TW','VN','BR','MX'), grass_date
- **广告维度**: ads_id, campaign_id, shop_id, account_id, placement, pricing_type, entrance, sub_entrance, entrance_group
- **竞价维度**: match_type, bid_type, search_origin_bid_price_local, search_bid_type, is_ocpm, origin_bid_price
- **内容维度**: item_id, origin_item_id, original_itemid, mapped_ads_itemid, keyword, query, video_id, creative_id, image_id, display_video_id, decoded_video_id, vv_id, ctx_item_type
- **用户维度**: user_id, ls_session_id, unique_id, platform, location, app_version, ab_sign, request_id, raw_request_id
- **归因维度**: report_type (0=traffic, 1=finance, 2=attribution_placed, 3=attribution_other), is_cod, is_preselected_vmodel
- **TA 维度**: ta_group_id, ta_matched_tag_ids, ta_premium_rate, tag_ids, matched_premium_segment, matched_premium_segment_type_id, matched_premium_segment_value_id
- **搜索维度**: search_scenario, search_entrance, search_mid, sort_by
- **页面维度**: page_type, page_section, target_type, slot_id, click_area, location_in_ads, landing_url_type
- **扣费维度**: deduct_unique_id, deduct_timestamp, deduction_reason, original_deduct_unique_id, deduct_order
- **算法/模型维度**: model_id, v_model_id, v_item_id, algo_json_data, bid_rerank_trace, uni_pcr_model_name, shop_recall_type, traffic_bucket_list, plan_bucket_list, creative_algo
- **Boost/标签维度**: new_boost, new_product_boost_coef, new_product_boost_stage, rapid_boost_toggle, rapid_boost_state, ad_tag, campaign_surge_toggle
- **直播维度**: streamer_id, creator_id
- **品牌维度**: brand_max_target_type, brand_max_ads_type, keywords_group_type, package_request_id, package_request_asset_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (inferred from DDL of downstream table `temp_unify_output_performance_mapping_detail_di`) |
| Partition Columns | tz_type STRING, grass_region STRING, grass_date STRING (inferred from INSERT OVERWRITE ... PARTITION) |
| HDFS Path | - (未在代码库中找到 CREATE TABLE DDL) |
| Retention | Temporary table; no long-term retention |
| Column Count | ~230 (12 个写文件使用相同列结构，PH 多源变体使用 UDF 扩展了部分字段) |
| Region Coverage | Multi-region: ID, MY, PH, SG, TH, TW, VN, BR, MX（含 BR_regional, MX_regional TZ 变体） |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 48 files（12 write + 36 read）
- L7D Query Count: -
- Completeness: -
- Popularity: -
