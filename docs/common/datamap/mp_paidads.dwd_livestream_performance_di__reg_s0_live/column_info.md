<!-- ads-workspace-gdoc-sync: gdoc_id=1vp4dHRZivJTbBg-QPTxWS6vHkMfXg2V8_jTj7ON8TAs gdoc_url=https://docs.google.com/document/d/1vp4dHRZivJTbBg-QPTxWS6vHkMfXg2V8_jTj7ON8TAs/edit -->

# Columns: mp_paidads.dwd_livestream_performance_di__reg_s0_live

## Column Usage Notes

### Non-Additive Fields

No SUM(DISTINCT) patterns identified from code references for this table. All metrics appear to be event-level and directly summable within a single partition.

### Value Mappings

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 9 | Live Ads - Max View (CPM) |
| pricing_type | 10 | Live Ads - Max Order (CPC) |
| pricing_type | 14 | Live Ads - Max Click |
| pricing_type | 19 | Live Ads - Target ROI |
| pricing_type | 22 | Live Ads - (additional type) |
| tz_type | 'local' | Local timezone (only value used) |
| streamer_type | 0 | Default / Unknown |
| is_cod | 0 | Not Cash-on-Delivery |
| is_cod | 1 | Cash-on-Delivery order |

### Common Filter Values

- `tz_type`: `'local'` -- only value used in queries
- `pricing_type`: `in (9, 10, 14)` (standard Live Ads) or `in (9, 10, 14, 19, 22)` (extended including Target ROI)
- `grass_region`: standard 7 regions `('ID','MY','PH','SG','TH','TW','VN')`
- `ads_expenditure > 0` -- filter for revenue/expenditure queries
- `(order > 0 or agent_order > 0 or order_gmv > 0 or agent_gmv > 0)` -- filter for order attribution queries
- `view > 0` -- filter for view event queries

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | - | - | - |
| item_id | bigint | - | - | - |
| shop_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| campaign_id | bigint | - | - | - |
| account_id | bigint | - | - | - |
| ls_session_id | bigint | - | - | - |
| streamer_id | bigint | - | - | - |
| entrance | int | - | - | - |
| placement | int | - | - | - |
| event_timestamp | bigint | - | - | - |
| location | int | - | - | - |
| location_in_ads | int | - | - | - |
| slot_id | bigint | - | - | - |
| impression | bigint | - | - | - |
| non_fraud_impression | bigint | - | - | - |
| deduct_impression | bigint | - | - | - |
| click | bigint | - | - | - |
| raw_click | bigint | - | - | - |
| order | bigint | - | - | - |
| checkout | bigint | - | - | - |
| view | bigint | - | - | - |
| add_to_cart | bigint | - | - | - |
| broad_order | bigint | - | - | - |
| paid_order | bigint | - | - | - |
| confirmed_order | bigint | - | - | - |
| cpm | bigint | - | - | - |
| expense_by_cpm | bigint | - | - | - |
| order_gmv | double | - | - | - |
| order_gmv_usd | double | - | - | - |
| item_sold_cnt | bigint | - | - | - |
| broad_gmv | double | - | - | - |
| broad_gmv_usd | double | - | - | - |
| broad_item_sold_cnt | bigint | - | - | - |
| ads_expenditure | double | - | - | - |
| ads_expenditure_usd | double | - | - | - |
| view_duration | bigint | - | - | - |
| ls_session_start_timestamp | bigint | - | - | - |
| ls_session_start_datetime | string | - | - | - |
| ls_session_end_timestamp | bigint | - | - | - |
| ls_session_end_datetime | string | - | - | - |
| ls_session_duration | bigint | - | - | - |
| product_click | bigint | - | - | - |
| campaign_start_datetime | string | - | - | - |
| campaign_end_datetime | string | - | - | - |
| ads_create_timestamp | bigint | - | - | - |
| ads_create_datetime | string | - | - | - |
| request_id | string | - | - | - |
| pricing_type | int | - | - | - |
| order_id | bigint | - | - | - |
| model_id | bigint | - | - | - |
| expense_free_credit_with_expiry | bigint | - | - | - |
| expense_free_credit_without_expiry | bigint | - | - | - |
| expense_paid_credit_with_expiry | bigint | - | - | - |
| expense_paid_credit_without_expiry | bigint | - | - | - |
| ads_expenditure_vat | double | - | - | - |
| ads_expenditure_usd_vat | double | - | - | - |
| target_type | string | - | - | - |
| page_section | string | - | - | - |
| page_type | string | - | - | - |
| origin_item_id | bigint | - | - | - |
| target_affiliate_id | bigint | - | - | - |
| sub_entrance | bigint | - | - | - |
| agent_gmv | double | - | - | - |
| agent_gmv_usd | double | - | - | - |
| agent_order | bigint | - | - | - |
| agent_item_sold_cnt | bigint | - | - | - |
| agent_checkout | bigint | - | - | - |
| daily_order | bigint | - | - | - |
| daily_item_sold_cnt | bigint | - | - | - |
| daily_gmv_amt_local | double | - | - | - |
| daily_gmv_amt_usd | double | - | - | - |
| click_timestamp | bigint | - | - | - |
| click_datetime | string | - | - | - |
| event_datetime | string | - | - | - |
| paid_timestamp | bigint | - | - | - |
| paid_datetime | string | - | - | - |
| confirmed_timestamp | bigint | - | - | - |
| confirmed_datetime | string | - | - | - |
| platform | string | - | - | - |
| streamer_type | int | - | - | - |
| traffic_source | bigint | - | - | - |
| recall_source | int | - | - | - |
| target_cir | double | - | - | - |
| click_event_id | string | - | - | - |
| streamer_shop_id | bigint | - | - | - |
| source | string | - | - | - |
| content_mix_frame_tab_name | int | - | - | - |
| imp_attr_order | bigint | - | - | - |
| imp_attr_order_amount | bigint | - | - | - |
| imp_attr_order_gmv | double | - | - | - |
| imp_attr_order_gmv_usd | double | - | - | - |
| imp_attr_agent_order | bigint | - | - | - |
| imp_attr_agent_order_amount | bigint | - | - | - |
| imp_attr_agent_order_gmv | double | - | - | - |
| imp_attr_agent_order_gmv_usd | double | - | - | - |
| shop_exp_tag | string | - | - | - |
| paid_order_amount | bigint | - | - | - |
| paid_order_gmv | double | - | - | - |
| paid_order_gmv_usd | double | - | - | - |
| paid_checkout_cnt | bigint | - | - | - |
| imp_attr_paid_order_cnt | bigint | - | - | - |
| imp_attr_paid_order_amount | bigint | - | - | - |
| is_cod | int | - | - | - |
| bid_rerank_trace | string | - | - | - |
| tz_type | string | [PARTITION] timezone type | - | - |
| grass_region | string | [PARTITION] partition key | - | - |
| grass_date | date | [PARTITION] partition key, yyyy-MM-dd | - | - |
