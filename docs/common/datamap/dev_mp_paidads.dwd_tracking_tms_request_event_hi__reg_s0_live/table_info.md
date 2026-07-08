<!-- ads-workspace-gdoc-sync: gdoc_id=1idvtzVn_LzH6bXmVcH3C8xLEzL-_l043NDWt0RQLVlM gdoc_url=https://docs.google.com/document/d/1idvtzVn_LzH6bXmVcH3C8xLEzL-_l043NDWt0RQLVlM/edit -->

# dev_mp_paidads.dwd_tracking_tms_request_event_hi__reg_s0_live

## Description

- **Desc:** TMS (Tracking Management System) 流量小时级明细表。从 traffic.paidads_dwd_event_log_hi__reg_live 解析 protobuf 数据，将 JSON items 展开为逐行事件，并通过 UDF (tms_protobuf, deduction_udf, decode_video_id) 解析业务字段。对 session_id + sequence_id 去重（按 log_timestamp 取最新），生成 impression_cnt / click_cnt / view_cnt 等行为指标。承载搜索广告、直播广告、视频广告、品牌广告等多种广告类型的底层追踪数据，是对比旧版追踪系统（mkplpaidads_data.dwd_advertise_tracking_*）数据质量的核心参照表。

- **Granularity:** event-level x grass_region x hour (grass_date, h)
- **Use Case:**
  1. TMS 与旧版 UBT 追踪数据差异对比分析（dashboard 系列文件，按 entrance 维度逐字段比对）
  2. UBT 小时去重（排除客户端延迟上报导致的重复数据）
  3. 广告事件追踪验证 — 对比 unique_id / ads_id / request_id / placement 等关键标识字段
  4. 分入口（entrance）的场景级流量分析

- **Update Frequency:** Hourly

## Key Metrics

- 行为计数: impression_cnt, click_cnt, view_cnt（从 operation 字段派生: impression=1, click=1, view=1）
- 追踪事件标识: unique_id, session_id, sequence_id, event_id
- 广告标识: ads_id, campaign_id, ads_keyword, ads_request_id, recall_type
- 排分/出价: deduction_bidprice, deduction_price, deduction_quality, cpm_deduction_info
- 预估: pctr, pcr, broad_pcr, rank_score, ecpm_weight, target_cir
- 商品/店铺: item_id, shop_id, item_price, sold_cnt_per_order, v_item_id, v_model_id
- 直播: ls_session_id, ls_session_id, livestream_duration, if_mini_ls, content_mix_frame_tab_name
- 视频: video_creator_id, display_video_id_encoded, video_duration, video_ads_type
- 定向: ta_group_id, ta_matched_tag_ids, ta_premium_rate
- 新商品: new_product_boost_coef, new_product_boost_stage
- 券: bid_voucher_id, voucher_deduction_price, best_vouchers, item_voucher, shop_voucher
- 品牌广告: banner_id, banner_source, campaign_unitid, slotid, image_hash, target_url, card_location, banner_cnt, landing_url_type, landing_page_url
- 搜索: query, search_session_id, search_entrance, sort_by, search_mid, keyword, sorttype, filters, ads_keyword, match_type

## Key Dimensions

- 分区: grass_region, grass_date, h (hour)
- 行为: operation (impression/click/view), ads_operation, traffic_source
- 入口: entrance (1=GLOBAL SEARCH, 4=YMAL PDP, 3=DAILY DISCOVERY, 23=IMAGE SEARCH, 27=LIVE STREAM DISCOVERY, 28=LIVE STREAM FOR YOU, 29=VIDEO FEED, 33=VIDEO FEED HP, 34=VIDEO FEED DISCOVERY, 35=MINI FEED VIDEO, 37=LS HOME CAROUSEL, 38=LS PDP, 39=LS AUTO LANDING, 42=LS VIDEO FEED, 48=LS GAME, 50=KEYWORD SEARCH VIDEO FEED, 54=VIDEO PDP, 55=VIDEO PDP WINDOW LANDING, 56=MINI FEED VIDEO ADS, 58=YMAL FEED VIDEO ADS)
- 广告: pricing_type, placement, match_type, attr_data_type, creative_algo
- 平台: platform_desc (other/ios_web/ios_app/android_web/android_app/pc_web), platform_implementation
- 页面: page_type, page_section, target_type
- 内容类型: ctx_item_type, content_type, content_mix_frame_tab_name
- 视频: video_ads_type (0=product_ads, 1=video_ads), trigger_mode, sv_source_page, current_page
- 布局: layout_type, location_in_shop, shop_location, referer_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | parquet |
| Partition Columns | grass_region (string), grass_date (date), h (tinyint) |
| HDFS Path | ${HIVE_PATH}/dwd_tracking_tms_request_event_hi__reg_s0_live |
| Retention | - |
| Column Count | ~138 (from DDL) |
| Region Coverage | Regional (SG/MY/PH/TH/TW/ID/VN/BR, inferred from grass_region partition) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 13 files (0 write, 13 read) -- from-code scan 2026-06-16; 注：INSERT/CREATE 搜索因代码库过大超时，可能有未发现的 write 文件
- L7D Query Count: -
- Completeness: -
- Popularity: -
