<!-- ads-workspace-gdoc-sync: gdoc_id=1IU3eQa9RvgurwGSyMw_SrG0BKtyRDi9wNdJ5yCFocfY gdoc_url=https://docs.google.com/document/d/1IU3eQa9RvgurwGSyMw_SrG0BKtyRDi9wNdJ5yCFocfY/edit -->

# mp_paidads.dwd_ads_request_performance_di__reg_s0_live

## Description

- **Desc:** Request-level ads performance fact table. Aggregates tracking events (impression, click, order) from `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` to the granularity of one row per (request_id, user_id, ads_id, entrance, placement) per day. Contains click/impression counts, order/GMV at multiple attribution windows (1h/24h/4d/7d/30d), model prediction scores (pCTR/pCR/pGMV), bidding info, and voucher details. HUDI COW table with partial-update upsert — the initial INSERT writes tracking-side fields, then OA (Order Attribution) MERGE writes order/expenditure fields.
- **Granularity:** daily x request_id x user_id x ads_id x entrance x placement x grass_region
- **Use Case:** Algo model calibration PCOC monitoring, uplift model evaluation, feedback ratio computation, ROI3 voucher discount performance analysis, click-level pGMV/pCR diagnostics, request-level AB experiment analysis
- **Update Frequency:** Daily (two-phase: tracking INSERT + OA MERGE)

## Key Metrics

- Click/Impression: click_cnt, impression_cnt, dedup_click_cnt, dedup_impression_cnt, deduplicated_click
- Expenditure: expenditure_amt_local, expenditure_amt_usd
- Order (7d): broad_order_cnt, direct_order_cnt, daily_order_cnt
- Order (1h/24h/4d): broad_order_cnt_1h, broad_order_cnt_24h, broad_order_cnt_4d, direct_order_cnt_1h, direct_order_cnt_24h, direct_order_cnt_4d
- GMV (7d): broad_gmv_amt_local, broad_gmv_amt_usd, direct_gmv_amt_local, direct_gmv_amt_usd
- GMV (1h/24h/4d): broad_order_gmv_local_1h, broad_order_gmv_usd_24h, direct_order_gmv_local_1h, etc.
- Paid Order: paid_order_cnt, paid_order_cnt_24h, paid_order_gmv_usd, paid_broad_order_cnt
- Model Scores: pCTR, pCR, direct_pcr, broad_pcr, rank_score, pcr_1d, pcr_delay, pcr_shop
- Voucher: pctr_v, pcr_v, broad_pcr_v, bid_price_0, voucher_deduction_price, deduction_price_0
- Bidding: bidprice, deduction_price, pid_coef, bid_rerank_trace (JSON with pGMV, feedback_ratio, uplift scores)

## Key Dimensions

- Partition: grass_region, grass_date
- Business: entrance, sub_entrance, pricing_type, placement
- Entity: ads_id, campaign_id, item_id, shop_id, user_id, request_id
- Model: uni_pcr_model_name, ab_sign, plan_bucket_list
- Category: level1_global_be_category, level1_global_be_category_id, level2_global_be_category, level2_global_be_category_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | HUDI (COW) |
| Partition Columns | grass_region (STRING), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/dwd_ads_request_performance_di__reg_s0_live` |
| Retention | 90 days (hoodie.cleaner.days.retained) |
| Column Count | 112+ (including HUDI metadata) |
| Region Coverage | ID, TH, VN, PH, SG, MY, TW, BR, AR, CL, CO, MX (UTC8 + Latin) |
| Primary Key | request_id, user_id, ads_id, entrance, placement |
| HUDI Index | BUCKET (CONSISTENT_HASHING, hash_field=user_id, 128-512 buckets) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 1037 files (read) + 6 write workflows (main + US + backfill)
- L7D Query Count: -
- Completeness: -
- Popularity: -
