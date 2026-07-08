<!-- ads-workspace-gdoc-sync: gdoc_id=1h91S_cpDJYxdAi8PuUA5wUpZzTKKu6qu_KWicfc1Dy0 gdoc_url=https://docs.google.com/document/d/1h91S_cpDJYxdAi8PuUA5wUpZzTKKu6qu_KWicfc1Dy0/edit -->

# mp_paidads.ods_log_ads_report_livestream_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `shopee_livestream_ads_report_event_{region}_live` |
| Consumer Group | `paidads-report-ng-livestream` |
| Brokers | `kafka.kafka_maketplace_ads_live_sg-01.ap-sg-1-general-a.live.mq.shopee.io:9092` |
| Proto 定义 | [report_event_livestream.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/log/report_event_livestream.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `ReportNgEventLiveStream`）

### ReportNgEventLiveStream（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 1 | `ads_id` | int64 | bigint |
| 2 | `item_id` | int64 | bigint |
| 3 | `shop_id` | int64 | bigint |
| 4 | `user_id` | int64 | bigint |
| 5 | `account_id` | int64 | bigint |
| 6 | `ls_session_id` | int64 | bigint |
| 7 | `campaign_id` | int64 | bigint |
| 8 | `entry_point` | int32 | int |
| 9 | `entrance` | int32 | int |
| 10 | `placement` | int32 | int |
| 11 | `country` | string | string |
| 12 | `timestamp` | int64 | bigint |
| 13 | `keyword` | string | string |
| 14 | `query` | string | string |
| 15 | `match_type` | int32 | int |
| 16 | `order_id` | int64 | bigint |
| 17 | `model_id` | int64 | bigint |
| 18 | `request_id` | string | string |
| 19 | `bundle` | bool | boolean |
| 20 | `signature` | string | string |
| 21 | `bid_type` | int32 | int |
| 22 | `location` | int32 | int |
| 23 | `slot_id` | int32 | int |
| 24 | `app_ver` | string | string |
| 25 | `platform` | int32 | int |
| 26 | `cod` | bool | boolean |
| 27 | `click_timestamp` | int64 | bigint |
| 28 | `paid_order` | int32 | int |
| 29 | `confirmed_order` | int32 | int |
| 30 | `paid_timestamp` | int32 | int |
| 31 | `confirmed_timestamp` | int32 | int |
| 32 | `buyer_segments` | LsBuyerSegment | array<struct<...>> |
| 33 | `buyer_segments_string` | string | string |
| 34 | `pricing_type` | int32 | int |
| 35 | `date` | int32 | int |
| 36 | `click` | int64 | bigint |
| 37 | `raw_click` | int64 | bigint |
| 38 | `impression` | int64 | bigint |
| 39 | `add_to_cart` | int64 | bigint |
| 40 | `location_in_ads` | int64 | bigint |
| 41 | `order` | int64 | bigint |
| 42 | `daily_order` | int64 | bigint |
| 43 | `order_amount` | int64 | bigint |
| 44 | `order_gmv` | int64 | bigint |
| 45 | `cost` | int64 | bigint |
| 46 | `raw_expense` | int64 | bigint |
| 47 | `daily_order_amount` | int64 | bigint |
| 48 | `broad_order` | int64 | bigint |
| 49 | `broad_item_count` | int64 | bigint |
| 50 | `broad_gmv` | int64 | bigint |
| 51 | `shop_item_click` | int64 | bigint |
| 52 | `broad_shop_item_click` | int64 | bigint |
| 53 | `shop_item_impression` | int64 | bigint |
| 54 | `broad_shop_item_imp` | int64 | bigint |
| 55 | `expense_free_credit_with_expiry` | int64 | bigint |
| 56 | `expense_free_credit_without_expiry` | int64 | bigint |
| 57 | `expense_paid_credit_with_expiry` | int64 | bigint |
| 58 | `expense_paid_credit_without_expiry` | int64 | bigint |
| 59 | `checkout` | int64 | bigint |
| 60 | `click_area` | int32 | int |
| 61 | `daily_gmv` | int64 | bigint |
| 62 | `cost_by_cpm` | int64 | bigint |
| 63 | `cpm` | int64 | bigint |
| 64 | `non_fraud_click` | int64 | bigint |
| 65 | `broad_add_to_cart` | int64 | bigint |
| 66 | `add_to_cart_without_click` | int64 | bigint |
| 67 | `pcr` | double | double |
| 68 | `pctr` | double | double |
| 69 | `rank_bid` | double | double |
| 70 | `pvr_boost` | double | double |
| 71 | `match_boost` | double | double |
| 72 | `rank_score` | double | double |
| 73 | `organic_value` | double | double |
| 74 | `broad_match_value` | double | double |
| 75 | `lite_pctr` | double | double |
| 76 | `lite_pcr` | double | double |
| 77 | `raw_request_id` | string | string |
| 78 | `origin_bid_price` | double | double |
| 79 | `creative_id` | int64 | bigint |
| 80 | `image_id` | string | string |
| 81 | `video_id` | string | string |
| 82 | `global_cat_ids` | int32 | array<int> |
| 83 | `creative_algo` | int32 | int |
| 84 | `target_cir` | double | double |
| 85 | `imp_user_id` | int64 | bigint |
| 86 | `pageview_user_id` | int64 | bigint |
| 87 | `sub_entrance` | int64 | bigint |
| 88 | `pageview` | int64 | bigint |
| 89 | `view` | int64 | bigint |
| 90 | `view_duration` | int64 | bigint |
| 91 | `product_click` | int64 | bigint |
| 92 | `deduct_impression` | int64 | bigint |
| 93 | `non_fraud_impression` | int64 | bigint |
| 94 | `origin_ids` | LsOriginIDs | struct<...> |
| 95 | `report_id` | string | string |
| 96 | `ta_group_id` | int64 | bigint |
| 97 | `ta_matched_tag_ids` | int32 | array<int> |
| 98 | `ta_premium_rate` | int64 | bigint |
| 99 | `display_video_id` | int64 | bigint |
| 100 | `deduct_unique_id` | int64 | bigint |
| 101 | `target_type` | string | string |
| 102 | `page_section` | string | string |
| 103 | `page_type` | string | string |
| 104 | `attr_data_type` | int32 | int |
| 105 | `affiliate_id` | int64 | bigint |
| 106 | `agent_order` | int64 | bigint |
| 107 | `agent_order_amount` | int64 | bigint |
| 108 | `agent_order_gmv` | int64 | bigint |
| 109 | `agent_checkout` | int64 | bigint |
| 110 | `paid_order_gmv` | int64 | bigint |
| 111 | `traffic_source` | int32 | int |
| 112 | `algo_json_data` | string | string |
| 113 | `recall_source` | int32 | int |
| 114 | `click_event_id` | string | string |
| 115 | `source` | string | string |
| 116 | `content_mix_frame_tab_name` | int32 | int |
| 117 | `streamer_id` | int64 | bigint |
| 118 | `imp_attr_order` | int64 | bigint |
| 119 | `imp_attr_order_amount` | int64 | bigint |
| 120 | `imp_attr_order_gmv` | int64 | bigint |
| 121 | `imp_attr_agent_order` | int64 | bigint |
| 122 | `imp_attr_agent_order_amount` | int64 | bigint |
| 123 | `imp_attr_agent_order_gmv` | int64 | bigint |
| 124 | `shop_exp_tag` | int32 | int |
| 125 | `imp_attr_paid_order` | int64 | bigint |
| 126 | `imp_attr_paid_order_amount` | int64 | bigint |
| 127 | `imp_attr_paid_order_gmv` | int64 | bigint |
| 128 | `paid_order_amount` | int64 | bigint |
| 129 | `paid_broad_order` | int64 | bigint |
| 130 | `paid_broad_gmv` | int64 | bigint |
| 131 | `paid_broad_order_amount` | int64 | bigint |
| 132 | `paid_agent_order` | int64 | bigint |
| 133 | `paid_agent_order_amount` | int64 | bigint |
| 134 | `paid_agent_order_gmv` | int64 | bigint |
| 135 | `event_timestamp` | int64 | bigint |
| 136 | `paid_checkout` | int64 | bigint |
| 137 | `bid_rerank_trace` | string | string |
| 138 | `paid_agent_checkout` | int64 | bigint |
| 139 | `paid_no_click_order_amount` | int64 | bigint |
| 140 | `paid_no_click_order_gmv` | int64 | bigint |
| 141 | `paid_no_click_order` | int64 | bigint |
| 142 | `imp_timestamp` | int64 | bigint |
| 143 | `deduction_reason` | int32 | int |
| 144 | `plan_bucket_list` | int64 | array<bigint> |
| 145 | `traffic_bucket_list` | int64 | array<bigint> |
| 146 | `response_timestamp` | int64 | bigint |
| 147 | `report_type` | int32 | int |
| 148 | `unique_id` | string | string |
| 149 | `entrance_group` | string | string |

### LsBuyerSegment（`buyer_segments` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `segment_type_id` | int32 | int |
| 2 | `info` | LsInfo | array<struct<segment_value_id:string |

### LsInfo（`buyer_segments.info` 的嵌套消息）

| field# | 字段名 | Proto 类型 |
|---|---|---|
| 1 | `segment_value_id` | string |

### LsOriginIDs（`origin_ids` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `item_id` | int64 | bigint |
| 2 | `index` | int32 | int |
| 3 | `order_item_item_id` | int64 | bigint |
| 4 | `order_item_snapshot_id` | int64 | bigint |
| 5 | `order_item_group_id` | int64 | bigint |
