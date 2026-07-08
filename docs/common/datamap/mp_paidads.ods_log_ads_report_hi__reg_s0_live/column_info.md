<!-- ads-workspace-gdoc-sync: gdoc_id=1kepEBjNrk3lydfveIKRt3jFF4axWknWvKXrRzdR-cGA gdoc_url=https://docs.google.com/document/d/1kepEBjNrk3lydfveIKRt3jFF4axWknWvKXrRzdR-cGA/edit -->

# Columns: mp_paidads.ods_log_ads_report_hi__reg_s0_live

## Column Usage Notes

### Non-Additive Fields

This is an event-level ODS table. Most metric columns are already per-event flags (0/1) or amounts, so standard SUM works for aggregation. No SUM(DISTINCT) pattern was observed for this table in the codebase (unlike the aggregated take_rate table).

However, be aware:
- `cpm` stores the CPM bid price per event, not a sum — use `MAX(cpm)` to get the bid, not SUM
- `rank_bid`, `rank_score`, `pvr_boost`, `match_boost`, `organic_value`, `broad_match_value`, `lite_pctr`, `lite_pcr`, `pcr`, `pctr` are model prediction scores — never SUM, use AVG or per-record only
- `order_gmv`, `broad_gmv`, `daily_gmv`, `cost` are in raw units (/100000 to convert to local currency)

### Value Mappings

| Column | Value | Meaning |
|--------|-------|---------|
| entrance | 1 | Search |
| entrance | 3 | Daily Discover (DD/DDE) |
| entrance | 4 | You May Also Like (YMAL) |
| entrance | 6 | Brand Max |
| entrance | 8, 9, 10, 11 | Other placements (PP, etc.) |
| pricing_type | 11 | Target ROAS 2.0 (target single-item) |
| pricing_type | 15 | Simple 2.0 (simple single-item) |
| pricing_type | 18 | ROI 3.0 |
| pricing_type | 24 | Target GMS |
| pricing_type | 25 | Target multi-product |
| pricing_type | 27 | Simple GMS |
| pricing_type | 29 | (excluded in take rate, special type) |
| placement | 9 | Display Ads (Brand Tracking) |
| placement | 45, 46 | Shop Ads (pricing_type coalesced to 0) |
| placement | 3327, 3328, 33, 3337-3342, 3348 | Livestream placements (separate table used) |
| ctx_item_type | 2 | Virtual model item (excluded from ads_click when not preselected) |

### Common Filter Values

- `grass_region`: `'ID'`, `'MY'`, `'PH'`, `'SG'`, `'TH'`, `'TW'`, `'VN'`, `'BR'`, `'MX'`
- `entrance`: `IN (1, 3, 4, 8, 9, 10, 11)` — standard algo monitoring scope
- `pricing_type`: `IN (11, 15, 24, 25, 27)` — Product Ads bidding types
- `sub_entrance`: `NOT IN (310103)` when `entrance = 3` — DD exclusion
- `placement`: `!= 9` — exclude Display Ads in take rate
- `pricing_type`: `!= 29` — exclude in take rate
- `ads_id > 0` — filter valid ads
- `click > 0`, `raw_click > 0`, `deduplicated_click > 0` — click event filters
- `order > 0`, `broad_gmv > 0` — conversion event filters
- `impression > 0` — impression event filter
- `user_id > 0` — valid user filter
- `cost IS NULL` — undeducted events (for OA backfill)
- Timezone conversion: `DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss'))` for local timezone alignment

## All Columns

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
| buyer_segments | array\<struct\<segment_type_id:int, info:array\<struct\<segment_value_id:string\>\>\>\> | - |
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
| global_cat_ids | array\<int\> | - |
| creative_algo | int | - |
| imp_user_id | bigint | - |
| pageview_user_id | bigint | - |
| pageview | bigint | - |
| origin_ids | struct\<item_id:bigint, index:int, order_item_item_id:bigint, order_item_snapshot_id:bigint, order_item_group_id:bigint\> | - |
| account_id | bigint | - |
| ls_session_id | bigint | - |
| view | bigint | - |
| view_duration | bigint | - |
| product_click | bigint | - |
| deduct_impression | bigint | - |
| non_fraud_impression | bigint | - |
| ta_group_id | bigint | - |
| ta_matched_tag_ids | array\<int\> | - |
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
| voucher_details | array\<struct\<promotion_id:bigint, voucher_code:string, groups:array\<string\>\>\> | - |
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
| cps_info | struct\<order_id:bigint, order_item_id:bigint, order_model_id:bigint, order_group_id:bigint, order_gmv:bigint, click_time_daily_budget:bigint, original_deduct_unique_id:bigint, original_order_timestamp:bigint\> | - |
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
| item_price_item | bigint | - |
| avg_sold_cnt_item | double | - |
| item_price_shop | bigint | - |
| avg_sold_cnt_shop | double | - |
| unique_id | string | - |
| expense_rebate_free_credit_without_expiry | bigint | - |
| grass_region | string | [PARTITION] |
| grass_date | date | [PARTITION] |
| h | int | [PARTITION] |
