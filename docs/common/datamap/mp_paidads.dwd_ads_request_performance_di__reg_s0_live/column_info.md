<!-- ads-workspace-gdoc-sync: gdoc_id=1P8Z032Blc6l4S-zii2znv5AhIO_4UZ82is-eoayk85E gdoc_url=https://docs.google.com/document/d/1P8Z032Blc6l4S-zii2znv5AhIO_4UZ82is-eoayk85E/edit -->

# Columns: mp_paidads.dwd_ads_request_performance_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This table is at request-level granularity. Most numeric fields are already per-request, so standard SUM works for aggregation. However:
- `pCTR`, `pCR`, `direct_pcr`, `broad_pcr`, `rank_score`, `pcr_1d`, `pcr_delay`, `pcr_shop` — model scores, must use AVG (weighted by click_cnt) or SUM/COUNT for PCOC
- `item_price`, `item_price_shop`, `avg_sold_cnt_item`, `avg_sold_cnt_shop` — item-level features, use AVG or SUM/click_cnt
- `target_cir` — campaign-level target, not additive
- `bid_rerank_trace` — JSON string, extract fields with get_json_object/JSON_EXTRACT before aggregation

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 0 | default |
| pricing_type | 1 | manual_cpc |
| pricing_type | 2 | manual_ecpc |
| pricing_type | 3 | itemboost |
| pricing_type | 4 | simple_ocpc |
| pricing_type | 7 | autoboost |
| pricing_type | 8 | simple_roas |
| pricing_type | 9 | livestream_max_view |
| pricing_type | 10 | livestream_max_gmv |
| pricing_type | 11 | target_roi2.0 |
| pricing_type | 13 | new_product_boost |
| pricing_type | 14 | livestream_target_roas |
| pricing_type | 15 | simple_roi2.0 |
| pricing_type | 16 | video_max_view |
| pricing_type | 17 | video_max_gmv |
| pricing_type | 18 | roi3.0 |
| entrance | 1 | search |
| entrance | 3 | dd (discovery/daily discover) |
| entrance | 4 | ymal (you may also like) |
| entrance | 8,9,10,11 | pp (product page) |
| entrance | 29,33,34 | video/other |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: Standard regions 'ID','SG','MY','TH','VN','PH','TW','BR'; Latin regions 'AR','CL','CO','MX'
- `entrance`: 1 (search), 3 (dd), 4 (ymal), 8/9/10/11 (pp), 29/33/34 (video)
- `placement`: 40 (target), 50 (simple)
- `pricing_type`: 11 (ROI2.0/target_roi), 18 (ROI3.0)
- `click_cnt > 0`: Filter to clicked requests only (very common in PCOC analysis)
- `deduplicated_click > 0`: Filter to deduplicated clicked requests
- `user_id > 0` and `item_id > 0` and `ads_id > 0`: Exclude invalid records
- `uni_pcr_model_name != ''`: Filter to requests with valid model prediction

### bid_rerank_trace JSON 常用字段

`bid_rerank_trace` is a JSON string containing model estimation details. Commonly extracted fields:

| JSON Path | Meaning | Usage |
|-----------|---------|-------|
| `$.direct_pgmv_7d` | Direct pGMV 7d prediction (x1e5) | PCOC = SUM(pgmv)/SUM(gmv) |
| `$.shop_pgmv_7d` | Shop pGMV 7d prediction (x1e5) | Shop-level PCOC |
| `$.broad_pgmv_7d` | Broad pGMV 7d prediction (x1e5) | Broad PCOC |
| `$.pgmv` | Final pGMV after online post-processing (x1e5) | Final PCOC |
| `$.feedback_ratio_1h` | Predicted 1h feedback ratio | pGMV_1h = pgmv_7d x fr_1h |
| `$.feedback_ratio_24h` | Predicted 24h feedback ratio | pGMV_24h = pgmv_7d x fr_24h |
| `$.cali_direct_pgmv_7d` | Calibrated direct pGMV 7d | Post-calibration PCOC |
| `$.cali_shop_pgmv_7d` | Calibrated shop pGMV 7d | Post-calibration PCOC |
| `$.cali_broad_pgmv_7d` | Calibrated broad pGMV 7d | Post-calibration PCOC |
| `$.uplift_pcr0` | Uplift pCR base score | Voucher uplift evaluation |
| `$.uplift_pcr_ratio2..6` | Uplift pCR ratio at discount levels | Voucher uplift evaluation |
| `$.uplift_model_score_str` | Comma-separated calibrated uplift scores | After-cali uplift PCOC |
| `$.voucher_price` | Voucher price in bidding (x1e5) | Discount rate = voucher_price/item_price/1e5 |
| `$.voucher_unpicked_reason` | Reason voucher not picked (17/18/99=RCT) | RCT sample filtering |
| `$.isRoi3` | Whether this is ROI3 mode | ROI3 analysis |
| `$.direct_pcr_7d` | Direct pCR 7d | Model monitoring |
| `$.pid_coef` | PID coefficient | Bidding adjustment |

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | ads_id | - | - |
| campaign_id | bigint | campaign_id | - | - |
| item_id | bigint | item_id | - | - |
| user_id | bigint | user_id | - | - |
| request_id | string | ads_request_id | - | - |
| shop_id | bigint | shop_id | - | - |
| entrance | bigint | location of ads entries where buyer clicks or impresses | - | - |
| pricing_type | int | pricing type of ads | - | - |
| placement | bigint | Placement | - | - |
| click_cnt | bigint | click_cnt | - | - |
| impression_cnt | bigint | impression_cnt | - | - |
| deduct_click_cnt | bigint | deduct_click_cnt | - | - |
| deduct_impression_cnt | bigint | deduct_impression_cnt | - | - |
| expenditure_amt_local | double | expenditure_amt_local | - | - |
| expenditure_amt_usd | double | expenditure_amt_usd | - | - |
| broad_order_cnt | bigint | broad_order_cnt | - | - |
| broad_item_cnt | bigint | broad_item_cnt | - | - |
| broad_gmv_amt_local | double | broad_gmv_amt_local | - | - |
| broad_gmv_amt_usd | double | broad_gmv_amt_local | - | - |
| daily_order_cnt | bigint | daily_order_cnt | - | - |
| daily_item_cnt | bigint | broad_item_cnt | - | - |
| daily_gmv_amt_local | double | daily_gmv_amt_local | - | - |
| daily_gmv_amt_usd | double | daily_gmv_amt_usd | - | - |
| direct_order_cnt | bigint | direct_order_cnt | - | - |
| direct_item_cnt | bigint | direct_item_cnt | - | - |
| direct_gmv_amt_local | double | direct_gmv_amt_local | - | - |
| direct_gmv_amt_usd | double | direct_gmv_amt_usd | - | - |
| pCTR | double | item_json_data.pCTR | - | - |
| pCR | double | item_json_data.pCR | - | - |
| direct_pcr | double | item_json_data.extra_json.direct_pcr | - | - |
| broad_pcr | double | item_json_data.broad_pcr | - | - |
| rank_score | double | item_json_data.rank_score | - | - |
| rank | bigint | item_json_data.rank | - | - |
| item_price | double | item_json_data.item_price | - | - |
| sold_cnt_per_order | bigint | item_json_data.sold_cnt_per_order | - | - |
| target_cir | double | item_json_data.target_cir | - | - |
| bidprice | double | internal.deduction_info.bidprice | - | - |
| deduction_price | double | internal.deduction_info.deduction_price | - | - |
| pcr_1d | double | item_json_data.pcr_1d | - | - |
| pcr_delay | double | item_json_data.pcr_delay | - | - |
| pcr_shop | double | item_json_data.pcr_shop | - | - |
| sub_entrance | bigint | sub_entrance | - | - |
| broad_order_1d | bigint | broad_order_1d | - | - |
| dedup_impression_cnt | bigint | dedup_impression_cnt | - | - |
| dedup_click_cnt | bigint | dedup_click_cnt | - | - |
| acct_cnt | bigint | acct_cnt | - | - |
| organic_location | bigint | organic_location | - | - |
| new_product_boost_coef | double | new_product_boost_coef | - | - |
| new_product_boost_stage | bigint | new_product_boost_stage | - | - |
| new_product_boost_tier | bigint | new_product_boost_tier | - | - |
| pctr_v | double | incl voucher, pctr | - | - |
| pcr_v | double | incl voucher, pcr | - | - |
| broad_pcr_v | double | incl voucher, broad_pcr | - | - |
| bid_price_0 | double | incl voucher, bid_price | - | - |
| bid_voucher_id | bigint | voucher id in ads bidding | - | - |
| voucher_deduction_price | double | voucher_deduction_price=deduction_price-deduction_price_0 | - | - |
| deduction_price_0 | double | excl voucher | - | - |
| is_auto_claimed_just_now | int | if ads voucher been just auto claimed | - | - |
| item_voucher | struct | item.item_voucher (nested struct with voucher details) | - | - |
| display_ads_voucher_label | int | whether ads voucher is actually displayed in FE | - | - |
| pdp_view | bigint | pdp_view | - | - |
| ads_voucher_auto_claimed | bigint | operation=3 & is_auto_claimed_just_now=1 | - | - |
| paid_order_cnt | bigint | count of ads orders when paid in 30 days | - | - |
| paid_order_cnt_24h | bigint | count of ads orders when paid in 24h | - | - |
| ab_sign | string | ab_sign | - | - |
| paid_order_gmv_local | double | paid order amount in local currency | - | - |
| paid_order_gmv_usd | double | paid order amount in usd currency | - | - |
| paid_order_gmv_local_24h | double | nearly 24 hours to pay order amount in local currency | - | - |
| paid_order_gmv_usd_24h | double | nearly 24 hours to pay order amount in usd currency | - | - |
| algo_json_data | string | tracking.algo_json_data | - | - |
| broad_order_cnt_24h | bigint | broad order volume nearly 24 hours after clicking the AD | - | - |
| broad_order_gmv_usd_24h | double | broad order gmv nearly 24 hours after clicking on the AD | - | - |
| broad_order_gmv_local_24h | double | broad order gmv nearly 24 hours after clicking on the AD | - | - |
| direct_order_cnt_24h | bigint | direct order volume nearly 24 hours after clicking the AD | - | - |
| direct_order_gmv_usd_24h | double | direct order gmv nearly 24 hours after clicking on the AD | - | - |
| direct_order_gmv_local_24h | double | direct order gmv nearly 24 hours after clicking on the AD | - | - |
| broad_order_cnt_4d | bigint | broad order volume nearly 4 days after clicking the AD | - | - |
| broad_order_gmv_usd_4d | double | broad order gmv nearly 4 days after clicking on the AD | - | - |
| broad_order_gmv_local_4d | double | broad order gmv nearly 4 days after clicking on the AD | - | - |
| direct_order_cnt_4d | bigint | direct order volume nearly 4 days after clicking the AD | - | - |
| direct_order_gmv_usd_4d | double | direct order gmv nearly 4 days after clicking on the AD | - | - |
| direct_order_gmv_local_4d | double | direct order gmv nearly 4 days after clicking on the AD | - | - |
| cps_dedup_click | bigint | cps dedup_click | - | - |
| deduct_order_cnt | bigint | cps order_cnt | - | - |
| first_impression_timestamp | bigint | local timestamp, impression first timestamp | - | - |
| first_click_timestamp | bigint | local timestamp, click first timestamp | - | - |
| bid_rerank_trace | string | estimated score of the bidding model (JSON) | - | - |
| pid_coef | double | a coefficient of the bidding algorithm | - | - |
| uni_pcr_model_name | string | The model name of uni cr | - | - |
| item_price_shop | double | estimated avg price of items in the shop (/ 100000) | - | - |
| avg_sold_cnt_shop | double | estimated avg sold cnt of items in the shop | - | - |
| avg_sold_cnt_item | double | estimated avg sold cnt of items | - | - |
| plan_bucket_list | array\<bigint\> | Group IDs (BucketID) of the advertising plan experiment | - | - |
| paid_broad_order_cnt | bigint | count of broad orders when paid in 30 days | - | - |
| paid_broad_order_gmv_local | double | paid broad order amount in local currency | - | - |
| paid_broad_order_gmv_usd | double | paid broad order amount in usd | - | - |
| deduplicated_click | bigint | deduplicated_click from dwd_advertise_performance_di | - | - |
| level1_global_be_category | string | Level 1 global backend category name | - | - |
| level1_global_be_category_id | bigint | Level 1 global backend category ID | - | - |
| level2_global_be_category | string | Level 2 global backend category name | - | - |
| level2_global_be_category_id | bigint | Level 2 global backend category ID | - | - |
| broad_order_cnt_1h | bigint | broad order volume nearly 1 hour after clicking/impression | - | - |
| broad_order_gmv_usd_1h | double | broad order gmv nearly 1 hour after clicking/impression | - | - |
| broad_order_gmv_local_1h | double | broad order gmv nearly 1 hour after clicking/impression | - | - |
| direct_order_cnt_1h | bigint | direct order volume nearly 1 hour after clicking/impression | - | - |
| direct_order_gmv_usd_1h | double | direct order gmv nearly 1 hour after clicking/impression | - | - |
| direct_order_gmv_local_1h | double | direct order gmv nearly 1 hour after clicking/impression | - | - |
| entrance_group | string | Entrance group id | - | - |
| grass_region | string | [PARTITION] Region code | - | - |
| grass_date | date | [PARTITION] Business date | - | - |
