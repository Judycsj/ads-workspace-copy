<!-- ads-workspace-gdoc-sync: gdoc_id=1FRL-JeUXanpVzeuUD8j4-swQ3z9szhAIv1SQGJz0iF8 gdoc_url=https://docs.google.com/document/d/1FRL-JeUXanpVzeuUD8j4-swQ3z9szhAIv1SQGJz0iF8/edit -->

# Columns: mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live

## Column Usage Notes

### Non-Additive Fields (Non-Additive Fields)

The following fields are computed via LEFT JOIN from `dwd_advertise_order_attribution_di__reg_s0_live` based on `paid_datetime` / `confirmed_datetime`, NOT directly summed from `dwd_advertise_performance_di` base data:
- `paid_order_cnt` -- attributed by date(paid_datetime) = grass_date
- `paid_order_cnt_ytd` -- attributed by date(paid_datetime) = grass_date - 1 day
- `confirmed_order_cnt` -- attributed by date(confirmed_datetime) = grass_date
- `confirmed_order_cnt_ytd` -- attributed by date(confirmed_datetime) = grass_date - 1 day

These are joined on 12 composite keys (ads_id, grass_region, placement, item_id, keyword, shop_id, query, pricing_type, match_type, matched_premium_segment_value, entrance + <=> pricing_type). Aggregating across these dimensions may require special handling.

### Enum Value Mappings (Value Mappings)

`matched_premium_segment_value` mapping (from CASE-WHEN in 4 write + 2+ read files):

| Value ID | Mapped Value |
|----------|-------------|
| 0 | buyer_segment_behaviour_general_audience |
| 1 | buyer_segment_behaviour_view_in_shop |
| 2 | buyer_segment_behaviour_cart_in_shop |
| 3 | buyer_segment_behaviour_order_in_shop |
| 4 | buyer_segment_behaviour_like_in_shop |
| 10 | buyer_segment_behaviour_view_similar_item |

`match_type` logic (from write files):
- `placement in (0, 3, 4, 1000, 1200)` -> COALESCE(match_type, 0)
- Other placements -> 0

`ads_type` mapping (from ads_advertise_mkt_1d backfill):

| placement | ads_type |
|-----------|----------|
| 0 | keyword:search |
| 1 | targeting:similar_product |
| 2 | targeting:daily_discover |
| 3 | keyword:shop |
| 4 | keyword:simple_mode |
| 5 | targeting:ymal |
| 7 | keyword:banner |
| 8 | targeting:simple_mode_all |
| 801 | targeting:simple_mode_sp |
| 802 | targeting:simple_mode_dd |
| 805 | targeting:simple_mode_ymal |
| 10 | boost:all |
| 1000 | boost:search |
| 1001 | boost:similar_product |
| 1002 | boost:daily_discover |
| 1005 | boost:ymal |
| 1200 | auto_boost:search |
| 1202 | auto_boost:daily_discover |
| 1205 | auto_boost:ymal |
| 20 | shop_simple |

### Common WHERE Values (Common Filter Values)

- `tz_type`: 'local' (all downstream consumers use only tz_type='local')
- `grass_region`: MX, CO, CL, BR (per-region workflow instances)
- `placement`: commonly filtered by (0, 2, 3, 4, 5, 802, 805, 1000, 1002, 1005, 1200, 1202, 1205, 20) for cold start analysis
- `order_cnt > 0` for first-order detection

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | BIGINT | ads id | - | - |
| placement | BIGINT | ads placement | - | - |
| ads_type | STRING | ads_type | - | - |
| keywords | STRING | keywords | - | - |
| match_type | BIGINT | match type between keywords and ads | - | - |
| item_id | BIGINT | item_id matched to this ads | - | - |
| item_name | STRING | item_name matched to item_id | - | - |
| shop_id | BIGINT | shop id | - | - |
| seller_id | BIGINT | sellerid | - | - |
| seller_name | STRING | seller name | - | - |
| query | STRING | query | - | - |
| pricing_type | INT | pricing_type | - | - |
| impression_cnt | BIGINT | ads impressions | - | - |
| click_cnt | BIGINT | ads clicks | - | - |
| order_cnt | BIGINT | ads orders (order items) | - | - |
| checkout_cnt | BIGINT | ads orders | - | - |
| ads_items_sold_cnt | BIGINT | ads_items_sold_cnt | - | - |
| ads_gmv_amt_local | DOUBLE | ads gmv,have use the origin gmv / pow(10,5) | - | - |
| ads_gmv_amt_usd | DOUBLE | ads_gmv_amt_usd | - | - |
| expenditure_amt_local | DOUBLE | ads expenditure_amt | - | - |
| expenditure_amt_usd | DOUBLE | ads expenditure_amt in usd | - | - |
| avg_ads_ranks | DOUBLE | avg ads_ranks | - | - |
| broad_shopitem_click_cnt | BIGINT | broad_shopitem_click_cnt (comment says avg_rank) | - | - |
| broad_shopitem_impression_cnt | BIGINT | broad_shopitem_impression_cnt,logic need to add | - | - |
| broad_order_item_cnt | BIGINT | broad_order_item_cnt | - | - |
| broad_order_gmv_amt_local | DOUBLE | broad_order_gmv_amt_local have divided pow(10,5) | - | - |
| broad_order_gmv_amt_usd | DOUBLE | broad_order_gmv_amt_usd | - | - |
| broad_order_cnt | BIGINT | broad_order_cnt | - | - |
| shopitem_impression_cnt | BIGINT | shopitem_impression_cnt | - | - |
| shopitem_click_cnt | BIGINT | shopitem_click_cnt | - | - |
| click_before_deduction_cnt | BIGINT | click_before_deduction_cnt | - | - |
| daily_order_cnt | BIGINT | daily_order_cnt | - | - |
| paid_order_cnt | BIGINT | paid_order_cnt (attributed by paid_datetime) | - | - |
| paid_order_cnt_ytd | BIGINT | paid_order_cnt_ytd (prev day paid) | - | - |
| confirmed_order_cnt | BIGINT | confirm_order_cnt (attributed by confirmed_datetime) | - | - |
| confirmed_order_cnt_ytd | BIGINT | confirm_order_cnt_ytd (prev day confirmed) | - | - |
| matched_premium_segment_value | STRING | mapped from 0\|1\|2\|3\|4\|10 | - | - |
| filter_segments_age_start | BIGINT | filter_segments_age_start | - | - |
| filter_segments_age_end | BIGINT | filter_segments_age_end | - | - |
| filter_segments_gender_list | STRING | filter_segments_gender_list | - | - |
| filter_segments_location_list | STRING | filter_segments_location_list | - | - |
| premium_segments_behavior_list | STRING | premium_segments_behavior_list | - | - |
| filter_segments_category_list | STRING | filter_segments_category_list | - | - |
| entrance | BIGINT | entrance | - | - |
| add_to_cart_cnt | BIGINT | add_to_cart_cnt | - | - |
| add_to_cart_without_clicks_cnt | BIGINT | add_to_cart_without_clicks_cnt | - | - |
| broad_add_to_cart_cnt | BIGINT | broad_add_to_cart_cnt | - | - |
| location | BIGINT | location | - | - |
| product_placement | INT | product_placement (from dim_product_campaign) | - | - |
| view_cnt | BIGINT | view_cnt (from base view) | - | - |
| product_click_cnt | BIGINT | product_click_cnt (from base view) | - | - |
| new_boost | - | new_boost field (from dwd_advertise_performance_di) | - | - |
| tz_type | STRING | [PARTITION] timezone type | - | - |
| grass_region | STRING | [PARTITION] region code | - | - |
| grass_date | DATE | [PARTITION] date partition | - | - |
