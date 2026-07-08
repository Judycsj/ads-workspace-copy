<!-- ads-workspace-gdoc-sync: gdoc_id=11SByXVIBo3bIJ1ATp4dZo3xS91LmjsQy3X4HYDthpn4 gdoc_url=https://docs.google.com/document/d/11SByXVIBo3bIJ1ATp4dZo3xS91LmjsQy3X4HYDthpn4/edit -->

# Columns: mp_paidads.ods_log_ads_report_hi__ph_s0_live

## Column Usage Notes

### Non-Additive Fields

This is an event-level ODS table. Most metric columns are already per-event flags (0/1) or amounts, so standard SUM works for aggregation. No SUM(DISTINCT) pattern was observed.

However, be aware:
- `cpm` stores the CPM bid price per event -- use `MAX(cpm)` to get the bid, not SUM
- `rank_bid`, `rank_score`, `pvr_boost`, `match_boost`, `organic_value`, `broad_match_value`, `lite_pctr`, `lite_pcr`, `pcr`, `pctr` are model prediction scores -- never SUM, use AVG or per-record only
- `order_gmv`, `broad_gmv`, `daily_gmv`, `cost`, `raw_expense` are in raw units (/100000 to convert to local currency)

### Value Mappings

| Column | Value | Meaning |
|--------|-------|---------|
| report_type | 0 | Tracking event |
| report_type | 1 | Translog/finance event |
| report_type | 2 | Order event |
| report_type | 3 | Paid order event |
| entrance | 27,28,37,38,39 | Livestream entrances (used in unify comparison) |
| entrance | 54 | Video/shop entrances |
| placement | 3 | Keyword/Product Ads |
| placement | 40, 50 | Standard placements |
| placement | 45 | Shop Ads (compared with seller_report) |
| placement | 65 | Specific finance cost comparison placement |

### Common Filter Values

**From codebase observations (PH region):**

- `grass_date = date'2026-04-07'` -- date range filter (typical)
- `h = 2`, `h = 8`, `h IN (14,15)`, `h = 22` -- hour-level partition filter
- `report_type IS NULL` -- non-order events (traffic events only)
- `report_type = 1` -- translog/deduction events
- `entrance IN (27,28,37,38,39)` -- livestream entrance filter
- `placement = 3` -- Product Ads
- `placement = 45` -- Shop Ads
- `placement = 65` -- Specific finance placement
- `order_id = <value> AND item_id = <value>` -- specific event lookup
- `deduct_unique_id = <value>` -- specific deduction trace
- `unique_id IN (...)` -- specific event tracking
- `cost > 0` -- only events with cost
- `broad_order > 0`, `broad_gmv > 0` -- conversion event filters
- `impression > 0` -- impression event filter
- `paid_order > 0` -- paid order event filter
- `COALESCE(expected_revenue, 0)` -- safe aggregation of financial fields

**Used in comparisons (old pipeline = this table vs new pipeline):**
- Compared with: `ods_log_attribution_event_hi__ph_s0_live`, `ods_log_finance_deduction_event_hi__ph_s0_live`, `ods_log_seller_report_hi__ph_s0_live`, `ods_log_seller_center_report_hi__ph_s0_live`

## All Columns

*Same schema as `mp_paidads.ods_log_ads_report_hi__reg_s0_live` (regional aggregation). PH region data is filtered to `grass_region = 'PH'`.*

| Column Name | Type | Description |
|-------------|------|-------------|
| ads_id | bigint | - |
| item_id | bigint | - |
| shop_id | bigint | - |
| user_id | bigint | - |
| campaign_id | bigint | - |
| entry_point | int | - |
| entrance | int | - |
| placement | int | - |
| country | string | - |
| timestamp | bigint | - |
| keyword | string | - |
| query | string | - |
| match_type | int | - |
| order_id | bigint | - |
| request_id | string | - |
| bundle | boolean | - |
| signature | string | - |
| bid_type | int | - |
| cod | boolean | - |
| click_timestamp | bigint | - |
| paid_order | int | - |
| confirmed_order | int | - |
| paid_timestamp | int | - |
| confirmed_timestamp | int | - |
| pricing_type | int | - |
| buyer_segments | array\<struct\> | - |
| date | int | - |
| click | bigint | - |
| raw_click | bigint | - |
| impression | bigint | - |
| add_to_cart | bigint | - |
| location_in_ads | bigint | - |
| order | bigint | - |
| daily_order | bigint | - |
| order_amount | bigint | - |
| order_gmv | bigint | - |
| cost | bigint | - |
| raw_expense | bigint | - |
| broad_order | bigint | - |
| broad_item_count | bigint | - |
| broad_gmv | bigint | - |
| shop_item_click | bigint | - |
| broad_shop_item_click | bigint | - |
| shop_item_impression | bigint | - |
| broad_shop_item_imp | bigint | - |
| expense_free_credit_with_expiry | bigint | - |
| expense_free_credit_without_expiry | bigint | - |
| expense_paid_credit_with_expiry | bigint | - |
| expense_paid_credit_without_expiry | bigint | - |
| checkout | bigint | - |
| click_area | int | - |
| daily_gmv | bigint | - |
| model_id | bigint | - |
| location | int | - |
| cost_by_cpm | bigint | - |
| cpm | bigint | - |
| non_fraud_click | bigint | - |
| slot_id | int | - |
| app_ver | string | - |
| platform | int | - |
| rank_bid | double | - |
| pvr_boost | double | - |
| match_boost | double | - |
| rank_score | double | - |
| organic_value | double | - |
| broad_match_value | double | - |
| lite_pctr | double | - |
| lite_pcr | double | - |
| broad_add_to_cart | bigint | - |
| add_to_cart_without_click | bigint | - |
| raw_request_id | string | - |
| origin_bid_price | double | - |
| creative_id | bigint | - |
| image_id | string | - |
| video_id | string | - |
| sub_entrance | bigint | - |
| daily_order_amount | bigint | - |
| report_id | string | - |
| buyer_segments_string | string | - |
| target_cir | double | - |
| pcr | double | - |
| pctr | double | - |
| creative_algo | int | - |
| imp_user_id | bigint | - |
| pageview_user_id | bigint | - |
| pageview | bigint | - |
| account_id | bigint | - |
| ls_session_id | bigint | - |
| view | bigint | - |
| view_duration | bigint | - |
| product_click | bigint | - |
| deduct_impression | bigint | - |
| non_fraud_impression | bigint | - |
| ta_group_id | bigint | - |
| ta_premium_rate | bigint | - |
| display_video_id | bigint | - |
| deduct_unique_id | bigint | - |
| page_type | string | - |
| page_section | string | - |
| target_type | string | - |
| search_scenario | string | - |
| search_entrance | string | - |
| search_mid | string | - |
| click_event_id | string | - |
| gmv_boost | double | - |
| attr_data_type | int | - |
| sort_by | string | - |
| new_boost | bigint | - |
| video_view | bigint | - |
| agent_order | bigint | - |
| agent_order_amount | bigint | - |
| agent_order_gmv | bigint | - |
| agent_checkout | bigint | - |
| traffic_source | int | - |
| raw_impression | bigint | - |
| deduplicated_click | bigint | - |
| display_ads_tag | int | - |
| organic_request_id | string | - |
| broad_order_1d | bigint | - |
| click_user_id | bigint | - |
| cold_start_boost | double | - |
| item_price | bigint | - |
| creator_id | bigint | - |
| video_ads_type | int | - |
| vv_id | string | - |
| raw_product_click | bigint | - |
| video_play_complete | bigint | - |
| new_product_boost_coef | double | - |
| new_product_boost_stage | int | - |
| voucher_details | array\<struct\> | - |
| bid_voucher_id | bigint | - |
| voucher_deduction_price | bigint | - |
| deduction_price_0 | bigint | - |
| pcr_v | double | - |
| pctr_v | double | - |
| broad_pcr_v | double | - |
| ads_voucher_auto_claimed | bigint | - |
| ctx_item_type | int | - |
| v_model_id | bigint | - |
| v_item_id | bigint | - |
| click_item_model_id | bigint | - |
| order_item_has_spu_vmodel | boolean | - |
| paid_order_gmv | bigint | - |
| algo_json_data | string | - |
| deduct_order | bigint | - |
| cps_dedup_click | bigint | - |
| expected_revenue | bigint | - |
| receivable_revenue | bigint | - |
| affiliate_id | bigint | - |
| shop_recall_type | bigint | - |
| no_click_order | bigint | - |
| no_click_item_count | bigint | - |
| no_click_gmv | bigint | - |
| plan_bucket_list | array\<bigint\> | - |
| pgmv | double | - |
| bid_rerank_trace | string | - |
| uni_pcr_model_name | string | - |
| unique_id | string | - |
| expense_rebate_free_credit_without_expiry | bigint | - |
| ad_tag | bigint | Added via ALTER TABLE |
| report_type | int | Added via ALTER TABLE: 0=tracking, 1=translog, 2=order, 3=paid_order |
| grass_date | date | [PARTITION] |
| h | int | [PARTITION] |
