<!-- ads-workspace-gdoc-sync: gdoc_id=1NheEOcCMXMzDXpA7TeQBLJMW7nfsFiivQkNbpiY6JpQ gdoc_url=https://docs.google.com/document/d/1NheEOcCMXMzDXpA7TeQBLJMW7nfsFiivQkNbpiY6JpQ/edit -->

# mp_paidads.ods_log_ads_report_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `shopee_ads_report_event_{region}_live` |
| Consumer Group | `paidads-datawarehouse-664cba` |
| Brokers | `kafka.kafka_aqb6pqgg_live.na-us-2-general-a.live.mq.shopee.io:9092` |
| Proto 定义 | [report_event.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/log/report_event.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `ReportNgEvent`）

### ReportNgEvent（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 1 | `ads_id` | int64 | bigint |
| 2 | `item_id` | int64 | bigint |
| 3 | `shop_id` | int64 | bigint |
| 4 | `user_id` | int64 | bigint |
| 5 | `campaign_id` | int64 | bigint |
| 6 | `entry_point` | int32 | int |
| 7 | `entrance` | int32 | int |
| 8 | `placement` | int32 | int |
| 9 | `country` | string | string |
| 10 | `timestamp` | int64 | bigint |
| 11 | `keyword` | string | string |
| 12 | `query` | string | string |
| 13 | `match_type` | int32 | int |
| 14 | `order_id` | int64 | bigint |
| 15 | `request_id` | string | string |
| 16 | `bundle` | bool | boolean |
| 17 | `signature` | string | string |
| 18 | `bid_type` | int32 | int |
| 19 | `cod` | bool | boolean |
| 20 | `click_timestamp` | int64 | bigint |
| 21 | `paid_order` | int32 | int |
| 22 | `confirmed_order` | int32 | int |
| 23 | `paid_timestamp` | int32 | int |
| 24 | `confirmed_timestamp` | int32 | int |
| 25 | `pricing_type` | int32 | int |
| 26 | `buyer_segments` | BuyerSegment | array<struct<...>> |
| 27 | `date` | int32 | int |
| 28 | `click` | int64 | bigint |
| 29 | `raw_click` | int64 | bigint |
| 30 | `impression` | int64 | bigint |
| 31 | `add_to_cart` | int64 | bigint |
| 32 | `location_in_ads` | int64 | bigint |
| 33 | `order` | int64 | bigint |
| 34 | `daily_order` | int64 | bigint |
| 35 | `order_amount` | int64 | bigint |
| 36 | `order_gmv` | int64 | bigint |
| 37 | `cost` | int64 | bigint |
| 38 | `raw_expense` | int64 | bigint |
| 39 | `broad_order` | int64 | bigint |
| 40 | `broad_item_count` | int64 | bigint |
| 41 | `broad_gmv` | int64 | bigint |
| 42 | `shop_item_click` | int64 | bigint |
| 43 | `broad_shop_item_click` | int64 | bigint |
| 44 | `shop_item_impression` | int64 | bigint |
| 45 | `broad_shop_item_imp` | int64 | bigint |
| 46 | `expense_free_credit_with_expiry` | int64 | bigint |
| 47 | `expense_free_credit_without_expiry` | int64 | bigint |
| 48 | `expense_paid_credit_with_expiry` | int64 | bigint |
| 49 | `expense_paid_credit_without_expiry` | int64 | bigint |
| 50 | `checkout` | int64 | bigint |
| 51 | `click_area` | int32 | int |
| 52 | `daily_gmv` | int64 | bigint |
| 53 | `model_id` | int64 | bigint |
| 54 | `location` | int32 | int |
| 55 | `cost_by_cpm` | int64 | bigint |
| 56 | `cpm` | int64 | bigint |
| 57 | `non_fraud_click` | int64 | bigint |
| 58 | `slot_id` | int32 | int |
| 59 | `app_ver` | string | string |
| 60 | `platform` | int32 | int |
| 61 | `broad_add_to_cart` | int64 | bigint |
| 62 | `add_to_cart_without_click` | int64 | bigint |
| 63 | `rank_bid` | double | double |
| 64 | `pvr_boost` | double | double |
| 65 | `match_boost` | double | double |
| 66 | `rank_score` | double | double |
| 67 | `organic_value` | double | double |
| 68 | `broad_match_value` | double | double |
| 69 | `lite_pctr` | double | double |
| 70 | `lite_pcr` | double | double |
| 71 | `raw_request_id` | string | string |
| 72 | `origin_bid_price` | double | double |
| 73 | `creative_id` | int64 | bigint |
| 74 | `image_id` | string | string |
| 75 | `video_id` | string | string |
| 76 | `sub_entrance` | int64 | bigint |
| 77 | `daily_order_amount` | int64 | bigint |
| 78 | `report_id` | string | string |
| 79 | `buyer_segments_string` | string | string |
| 80 | `target_cir` | double | double |
| 81 | `pcr` | double | double |
| 82 | `pctr` | double | double |
| 83 | `global_cat_ids` | int32 | array<int> |
| 84 | `creative_algo` | int32 | int |
| 85 | `imp_user_id` | int64 | bigint |
| 86 | `pageview_user_id` | int64 | bigint |
| 87 | `pageview` | int64 | bigint |
| 88 | `origin_ids` | OriginIDs | struct<...> |
| 89 | `account_id` | int64 | bigint |
| 90 | `ls_session_id` | int64 | bigint |
| 91 | `view` | int64 | bigint |
| 92 | `view_duration` | int64 | bigint |
| 93 | `product_click` | int64 | bigint |
| 94 | `deduct_impression` | int64 | bigint |
| 95 | `non_fraud_impression` | int64 | bigint |
| 96 | `ta_group_id` | int64 | bigint |
| 97 | `ta_matched_tag_ids` | int32 | array<int> |
| 98 | `ta_premium_rate` | int64 | bigint |
| 99 | `display_video_id` | int64 | bigint |
| 100 | `deduct_unique_id` | int64 | bigint |
| 101 | `gmv_boost` | double | double |
| 102 | `page_type` | string | string |
| 103 | `page_section` | string | string |
| 104 | `target_type` | string | string |
| 105 | `search_scenario` | string | string |
| 106 | `search_entrance` | string | string |
| 107 | `search_mid` | string | string |
| 108 | `click_event_id` | string | string |
| 109 | `attr_data_type` | int32 | int |
| 110 | `sort_by` | string | string |
| 111 | `new_boost` | int64 | bigint |
| 112 | `video_view` | int64 | bigint |
| 113 | `agent_order` | int64 | bigint |
| 114 | `agent_order_amount` | int64 | bigint |
| 115 | `agent_order_gmv` | int64 | bigint |
| 116 | `agent_checkout` | int64 | bigint |
| 117 | `traffic_source` | int32 | int |
| 118 | `raw_impression` | int64 | bigint |
| 119 | `deduplicated_click` | int64 | bigint |
| 120 | `display_ads_tag` | int32 | int |
| 121 | `organic_request_id` | string | string |
| 122 | `broad_order_1d` | int64 | bigint |
| 123 | `click_user_id` | int64 | bigint |
| 124 | `cold_start_boost` | double | double |
| 125 | `item_price` | int64 | bigint |
| 126 | `creator_id` | int64 | bigint |
| 127 | `video_ads_type` | int32 | int |
| 128 | `vv_id` | string | string |
| 129 | `raw_product_click` | int64 | bigint |
| 130 | `video_play_complete` | int64 | bigint |
| 131 | `new_product_boost_coef` | double | double |
| 132 | `new_product_boost_stage` | int32 | int |
| 133 | `voucher_details` | VoucherDetail | array<struct<...>> |
| 134 | `bid_voucher_id` | int64 | bigint |
| 135 | `voucher_deduction_price` | int64 | bigint |
| 136 | `bid_price_0` | int64 | bigint |
| 137 | `pcr_v` | double | double |
| 138 | `pctr_v` | double | double |
| 139 | `broad_pcr_v` | double | double |
| 140 | `deduction_price_0` | int64 | bigint |
| 141 | `ads_voucher_auto_claimed` | int64 | bigint |
| 142 | `ctx_item_type` | int32 | int |
| 143 | `v_model_id` | int64 | bigint |
| 144 | `v_item_id` | int64 | bigint |
| 145 | `click_item_model_id` | int64 | bigint |
| 146 | `order_item_has_spu_vmodel` | bool | boolean |
| 147 | `paid_order_gmv` | int64 | bigint |
| 148 | `algo_json_data` | string | string |
| 149 | `cps_dedup_click` | int64 | bigint |
| 150 | `deduct_order` | int64 | bigint |
| 151 | `cps_info` | CpsInfo | struct<...> |
| 152 | `expected_revenue` | int64 | bigint |
| 153 | `receivable_revenue` | int64 | bigint |
| 154 | `affiliate_id` | int64 | bigint |
| 155 | `shop_recall_type` | int64 | bigint |
| 156 | `no_click_order` | int64 | bigint |
| 157 | `no_click_item_count` | int64 | bigint |
| 158 | `no_click_gmv` | int64 | bigint |
| 159 | `plan_bucket_list` | int64 | array<bigint> |
| 160 | `pgmv` | double | double |
| 161 | `bid_rerank_trace` | string | string |
| 162 | `uni_pcr_model_name` | string | string |
| 163 | `item_price_item` | int64 | bigint |
| 164 | `avg_sold_cnt_item` | double | double |
| 165 | `item_price_shop` | int64 | bigint |
| 166 | `avg_sold_cnt_shop` | double | double |
| 167 | `unique_id` | string | string |
| 168 | `expense_rebate_free_credit_without_expiry` | int64 | bigint |
| 169 | `original_itemid` | int64 | bigint |
| 170 | `mapped_ads_itemid` | int64 | bigint |
| 171 | `streamer_type` | int32 | int |
| 172 | `duplicate_label` | int32 | int |
| 173 | `streamer_id` | int64 | bigint |
| 174 | `entrance_group` | string | string |
| 175 | `ad_tag` | int64 | bigint |
| 176 | `imp_attr_order` | int64 | bigint |
| 177 | `imp_attr_order_amount` | int64 | bigint |
| 178 | `imp_attr_order_gmv` | int64 | bigint |
| 179 | `imp_attr_agent_order` | int64 | bigint |
| 180 | `imp_attr_agent_order_amount` | int64 | bigint |
| 181 | `imp_attr_agent_order_gmv` | int64 | bigint |
| 182 | `shop_exp_tag` | int32 | int |
| 183 | `imp_attr_paid_order` | int64 | bigint |
| 184 | `imp_attr_paid_order_amount` | int64 | bigint |
| 185 | `imp_attr_paid_order_gmv` | int64 | bigint |
| 186 | `paid_order_amount` | int64 | bigint |
| 187 | `paid_broad_order` | int64 | bigint |
| 188 | `paid_broad_gmv` | int64 | bigint |
| 189 | `paid_broad_order_amount` | int64 | bigint |
| 190 | `paid_agent_order` | int64 | bigint |
| 191 | `paid_agent_order_amount` | int64 | bigint |
| 192 | `paid_agent_order_gmv` | int64 | bigint |
| 193 | `event_timestamp` | int64 | bigint |
| 194 | `paid_checkout` | int64 | bigint |
| 195 | `is_backfill` | bool | boolean |
| 196 | `paid_agent_checkout` | int64 | bigint |
| 197 | `paid_no_click_order_amount` | int64 | bigint |
| 198 | `paid_no_click_order_gmv` | int64 | bigint |
| 199 | `paid_no_click_order` | int64 | bigint |
| 200 | `shop_view` | int64 | bigint |
| 201 | `shop_video_play` | int64 | bigint |
| 202 | `shop_video_play_complete` | int64 | bigint |
| 203 | `shop_video_play_time` | int64 | bigint |
| 204 | `shop_video_click` | int64 | bigint |
| 205 | `brand_max_target_type` | int32 | int |
| 206 | `imp_timestamp` | int64 | bigint |
| 207 | `traffic_bucket_list` | int64 | array<bigint> |
| 208 | `deduction_reason` | int32 | int |
| 209 | `is_ocpm` | bool | boolean |
| 210 | `report_type` | int32 | int |
| 211 | `porg` | double | double |
| 212 | `keywords_group_type` | int32 | int |
| 213 | `brand_max_ads_type` | int32 | int |
| 214 | `package_request_id` | int64 | bigint |
| 215 | `package_request_asset_id` | int64 | bigint |
| 216 | `boost_deduction_price` | double | double |
| 217 | `is_preselected_vmodel` | bool | boolean |
| 218 | `response_timestamp` | int64 | bigint |

### BuyerSegment（`buyer_segments` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `segment_type_id` | int32 | int |
| 2 | `info` | Info | array<struct<segment_value_id:string |

### Info（`buyer_segments.info` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `segment_value_id` | string |

### OriginIDs（`origin_ids` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `item_id` | int64 | bigint |
| 2 | `index` | int32 | int |
| 3 | `order_item_item_id` | int64 | bigint |
| 4 | `order_item_snapshot_id` | int64 | bigint |
| 5 | `order_item_group_id` | int64 | bigint |
| 6 | `bundle_order_item_id` | int64 | bigint |
| 7 | `order_unique_id` | int64 | bigint |

### VoucherDetail（`voucher_details` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `promotion_id` | int64 | bigint |
| 2 | `voucher_code` | string | string |
| 3 | `groups` | string | array<string> |
| 4 | `reward_discount` | int64 | bigint |

### CpsInfo（`cps_info` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `order_id` | int64 | bigint |
| 2 | `order_item_id` | int64 | bigint |
| 3 | `order_model_id` | int64 | bigint |
| 4 | `order_group_id` | int64 | bigint |
| 5 | `order_gmv` | int64 | bigint |
| 6 | `click_time_daily_budget` | int64 | bigint |
| 7 | `original_deduct_unique_id` | int64 | bigint |
| 8 | `original_order_timestamp` | int64 | bigint |
