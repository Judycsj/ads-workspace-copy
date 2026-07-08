<!-- ads-workspace-gdoc-sync: gdoc_id=1ZgKjL0pZ5QhmMgFqY87qb0VVUG31Zt08E9R0dgs7v9A gdoc_url=https://docs.google.com/document/d/1ZgKjL0pZ5QhmMgFqY87qb0VVUG31Zt08E9R0dgs7v9A/edit -->

# mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`
- canonical_table: `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`
- resolution: `describe:exact`
- source: `datasuite_describe`
- business_docs: `roi3_ads_voucher`

## 使用边界

- 这张表只在命中的业务文档显式声明时作为外部表使用。
- 字段、类型和分区过滤以本文件记录的 DataMap/DESCRIBE 元数据为准。
- 不要把这张表自动加入广告数仓主候选表集合；它只补充业务链路排查。

## 分区和过滤

- inferred_partition_keys: `grass_date`, `grass_region`, `h`, `bz_type`
- required_filters: `grass_date`, `grass_region`

## 字段列表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `user_id` | `bigint` |  |
| `session_id` | `varchar` |  |
| `device_id` | `varchar` |  |
| `client_ip` | `varchar` |  |
| `platform` | `bigint` |  |
| `timestamp` | `bigint` |  |
| `token` | `varchar` |  |
| `source` | `varchar` |  |
| `item_id` | `bigint` |  |
| `shop_id` | `bigint` |  |
| `discount` | `bigint` |  |
| `is_free_shipping` | `integer` |  |
| `is_prefered` | `integer` |  |
| `algorithm` | `varchar` |  |
| `organic_location` | `bigint` |  |
| `refer_urls` | `array(varchar)` |  |
| `item_model_id` | `bigint` |  |
| `list_type` | `varchar` |  |
| `ads_id` | `bigint` |  |
| `location_in_ads` | `bigint` |  |
| `campaign_id` | `bigint` |  |
| `ads_keyword` | `varchar` |  |
| `match_type` | `bigint` |  |
| `query` | `row(keyword varchar, sorttype bigint, colorful_blocks array(varchar), filter_price_min bigint, filter_price_max bigint, filter_include_sf bigint, filter_with_discount bigint, fi...` |  |
| `abtest_sign` | `varchar` |  |
| `item_json_data` | `varchar` |  |
| `tracking_json_data` | `varchar` |  |
| `ads_request_id` | `varchar` |  |
| `fe_ab_sign` | `varchar` |  |
| `add_cart_item_amount` | `bigint` |  |
| `add_cart_item_price` | `decimal(25,10)` |  |
| `product_card` | `row(campaign_label_ids array(bigint), has_video integer, item_discount bigint, shop_type bigint, is_service_by_shopee integer, image_flag_ids array(bigint), price_before_discoun...` |  |
| `raw_request_id` | `varchar` |  |
| `organic_request_id` | `varchar` |  |
| `internal_label` | `row(frauds array(row(fraud_type varchar)), sessionid varchar, adsinfo_extract_label bigint, dfp_device_id varchar, risk_tags array(varchar))` |  |
| `ads_entrance` | `varchar` |  |
| `tracking_placement` | `bigint` |  |
| `inner_placement` | `bigint` |  |
| `ads_placement` | `bigint` |  |
| `internal` | `row(deduction_info row(quality double, bidprice decimal(25,10), next_score double, next_ads_id bigint, next_ads_keyword varchar, algo_name varchar, boost_status varchar, deducti...` |  |
| `operation` | `bigint` |  |
| `pricing_type` | `varchar` |  |
| `operation_desc` | `varchar` |  |
| `platform_desc` | `varchar` |  |
| `tracking_queue_name` | `varchar` |  |
| `fraud_type` | `varchar` |  |
| `search_page_sort_type` | `bigint` |  |
| `matched_premium_segments` | `varchar` |  |
| `ab_sign` | `varchar` |  |
| `app_ver` | `varchar` |  |
| `rn_ver` | `varchar` |  |
| `view_session_id` | `varchar` |  |
| `sub_entrance` | `bigint` |  |
| `dfp` | `varchar` |  |
| `click_area` | `integer` |  |
| `display_video_id` | `bigint` |  |
| `ta_group_id` | `bigint` |  |
| `ta_matched_tag_ids` | `array(integer)` |  |
| `ta_premium_rate` | `bigint` |  |
| `vv_id` | `varchar` |  |
| `sdk_version` | `varchar` |  |
| `sdk_type` | `varchar` |  |
| `page_type` | `varchar` |  |
| `page_section` | `varchar` |  |
| `target_type` | `varchar` |  |
| `sort_by` | `varchar` |  |
| `scenario` | `varchar` |  |
| `search_entrance` | `varchar` |  |
| `search_mid` | `varchar` |  |
| `search_session_id` | `varchar` |  |
| `global_session_id` | `varchar` |  |
| `current_page` | `varchar` |  |
| `content_type` | `varchar` |  |
| `content_id` | `varchar` |  |
| `trigger_mode` | `varchar` |  |
| `sv_source_page` | `varchar` |  |
| `display_ad_tag` | `integer` |  |
| `card_type` | `varchar` |  |
| `video_id` | `varchar` |  |
| `be_ab` | `array(bigint)` |  |
| `item_price` | `decimal(25,10)` |  |
| `target_cir` | `double` |  |
| `sold_cnt_per_order` | `bigint` |  |
| `duplicate_label` | `integer` |  |
| `click_event_id` | `varchar` |  |
| `sold_cnt_per_order_double` | `double` |  |
| `bid_deduction_price` | `bigint` |  |
| `new_product_boost_stage` | `integer` | new_product_boost_stage |
| `item_voucher` | `row(display_ads_voucher_label integer, best_vouchers array(row(promotion_id bigint, voucher_code varchar, voucher_discount bigint, minimum_spend bigint, voucher_valid_start_time...` |  |
| `bid_voucher_id` | `bigint` |  |
| `voucher_deduction_price` | `bigint` |  |
| `is_auto_claimed_just_now` | `tinyint` |  |
| `is_roi3_best_voucher` | `tinyint` |  |
| `v_model_id` | `bigint` |  |
| `v_item_id` | `bigint` |  |
| `ctx_item_type` | `integer` |  |
| `algo_json_data` | `varchar` |  |
| `unique_id` | `varchar` | tms unique_id |
| `event_timestamp` | `bigint` |  |
| `sequence_id` | `varchar` | sequence_id |
| `bid_rerank_trace` | `varchar` |  |
| `uni_pcr_model_name` | `varchar` |  |
| `item_price_shop` | `double` |  |
| `avg_sold_cnt_shop` | `double` |  |
| `avg_sold_cnt_item` | `double` |  |
| `is_ocpm` | `boolean` |  |
| `attribute_reason` | `integer` |  |
| `model_id` | `bigint` |  |
| `rsku_list_infos_json` | `varchar` |  |
| `is_preselected_vmodel` | `boolean` |  |
| `shop_voucher_json` | `varchar` |  |
| `grass_region` | `varchar(10)` |  |
| `grass_date` | `date` |  |
| `h` | `integer` |  |
| `bz_type` | `varchar(20)` |  |

## 解析日志

- `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
