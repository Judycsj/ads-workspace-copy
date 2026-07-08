<!-- ads-workspace-gdoc-sync: gdoc_id=13RLdkvj_fc4PBEEdO4wkw0da4PCrL9QTGKczN9mpG8o gdoc_url=https://docs.google.com/document/d/13RLdkvj_fc4PBEEdO4wkw0da4PCrL9QTGKczN9mpG8o/edit -->

# mp_paidads.ods_log_translog_event_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `paidads_translog_event_{region}_live` |
| Consumer Group | `paidads-translog-event-00201d` |
| Brokers | `kafka.ks_ads_live-01.ap-sg-1-general-a.live.mq.shopee.io:9092` |
| Proto 定义 | [translog_event_streaming.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/log/translog_event_streaming.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `TranslogEvent`）

### TranslogEvent（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 1 | `translog` | TranslogStr | struct<...> |
| 2 | `root_ads_data_str` | string | string |
| 3 | `item_ads_data_str` | string | string |
| 4 | `shop_ads_data_str` | string | string |
| 5 | `country` | string | string |
| 6 | `produce_ts` | int64 | bigint |
| 7 | `location` | int32 | int |
| 8 | `sub_entrance` | int32 | int |
| 9 | `cpm_event_details_str` | string | string |
| 10 | `click_area` | int32 | int |
| 11 | `display_video_id` | int64 | bigint |
| 12 | `rn_ver` | string | string |
| 13 | `platform` | int32 | int |
| 14 | `track_session_id` | string | string |
| 15 | `search_session_id` | string | string |
| 16 | `click_event_id` | string | string |
| 17 | `page_type` | string | string |
| 18 | `page_section` | string | string |
| 19 | `target_type` | string | string |
| 20 | `search_scenario` | string | string |
| 21 | `search_entrance` | string | string |
| 22 | `search_mid` | string | string |
| 23 | `raw_request_id` | string | string |
| 24 | `imp_cost_details` | TranslogImpCostDetail | array<struct<...>> |
| 25 | `traffic_source` | int32 | int |
| 26 | `sort_by` | string | string |
| 27 | `display_ad_tag` | int32 | int |
| 28 | `video_id` | string | string |
| 29 | `video_creator_id` | int64 | bigint |
| 30 | `video_ads_type` | int32 | int |
| 40 | `voucher_details` | VoucherDetail | array<struct<...>> |
| 41 | `model_id` | int64 | bigint |
| 42 | `v_model_id` | int64 | bigint |
| 43 | `v_item_id` | int64 | bigint |
| 44 | `ctx_item_type` | int32 | int |
| 45 | `location_in_ads` | int32 | int |
| 46 | `algo_json_data` | string | string |
| 47 | `click_time_daily_budget` | int64 | bigint |
| 48 | `common_json_data` | string | string |
| 49 | `original_deduct_id` | int64 | bigint |
| 50 | `original_order_timestamp` | int64 | bigint |
| 51 | `track_unique_id` | string | string |
| 52 | `app_version` | string | string |
| 53 | `livestream_props` | TrackingLivestreamsProps | struct<...> |
| 54 | `is_preselected_vmodel` | bool | boolean |

### TranslogStr（`translog` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `id` | int64 | bigint |
| 2 | `adsid` | int64 | bigint |
| 3 | `itemid` | int64 | bigint |
| 4 | `shopid` | int32 | int |
| 5 | `operation` | int32 | int |
| 6 | `timestamp` | int64 | bigint |
| 7 | `client_ip` | int64 | bigint |
| 8 | `userid` | int64 | bigint |
| 9 | `price` | int64 | bigint |
| 10 | `extinfo` | bytes | binary |
| 11 | `status` | int32 | int |
| 12 | `acc_before_balance` | int64 | bigint |
| 13 | `acc_after_balance` | int64 | bigint |
| 14 | `dai_before_balance` | int64 | bigint |
| 15 | `dai_after_balance` | int64 | bigint |
| 16 | `deviceid` | string | string |
| 17 | `keyword` | string | string |
| 18 | `placement` | int32 | int |
| 19 | `deduct_unique_id` | int64 | bigint |
| 20 | `acc_user_id` | int64 | bigint |
| 21 | `account_id` | int64 | bigint |

### TranslogImpCostDetail（`imp_cost_details` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `event_ts` | int64 | bigint |
| 2 | `unique_id` | int64 | bigint |
| 3 | `user_id` | int64 | bigint |
| 4 | `request_id` | string | string |
| 5 | `batch_id` | int64 | bigint |
| 6 | `ads_id` | int64 | bigint |
| 7 | `price` | int64 | bigint |
| 8 | `adjusted_cost` | int64 | bigint |
| 9 | `credit_cost` | int64 | bigint |
| 10 | `balance_cost` | int64 | bigint |

### VoucherDetail（`voucher_details` 的嵌套消息，ODS 类型: array<struct>）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `promotion_id` | int64 | bigint |
| 2 | `voucher_code` | string | string |
| 3 | `groups` | string | array<string> |
| 4 | `reward_discount` | int64 | bigint |

### TrackingLivestreamsProps（`livestream_props` 的嵌套消息，ODS 类型: struct）

| field# | 字段名 | Proto 类型 | ODS 子字段类型 |
|---|---|---|---|
| 1 | `ls_session_id` | int64 | bigint |
| 2 | `streamer_id` | int64 | bigint |
| 3 | `streaming_room_source` | string | string |
| 4 | `if_mini_ls` | bool | boolean |
| 5 | `content_mix_frame_tab_name` | int32 | int |
