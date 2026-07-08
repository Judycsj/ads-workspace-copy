<!-- ads-workspace-gdoc-sync: gdoc_id=1FtvusJUXHZe8cLkfGlF0NYLmB_bBif98beLsd1g7CH0 gdoc_url=https://docs.google.com/document/d/1FtvusJUXHZe8cLkfGlF0NYLmB_bBif98beLsd1g7CH0/edit -->

# mp_paidads.ods_log_ads_report_hi__ph_s0_live

## Description

- **Desc:** ODS-layer hourly ads report event log for the Philippines region (PH), commonly called "ReportNG". Records per-event impression/click/order/checkout/add-to-cart facts for all Shopee Ads placements in PH. Each row is a single event with full attribution context (ads_id, request_id, report_id, buyer/seller info, bidding trace). Same schema as `reg_s0_live` but filtered to `grass_region = 'PH'`. Upstream data is ingested from ads report service via Parquet files on HDFS.
- **Granularity:** hourly x event-level (one row per ads event per hour)
- **Use Case:** Unify output comparison (old vs new attribution pipeline), finance reconciliation (cost/expected_revenue comparison between report-ng and finance deduction events), seller report comparison, DWD performance table production (PH region), individual event debugging
- **Update Frequency:** Hourly (event-driven ingestion, partitioned by hour)

## Key Metrics

- Event flags: `impression`, `click`, `raw_click`, `non_fraud_click`, `deduplicated_click`, `deduct_impression`, `order`, `daily_order`, `checkout`, `paid_order`, `confirmed_order`, `add_to_cart`, `broad_order`, `broad_add_to_cart`, `pageview`, `product_click`, `view`, `video_view`, `video_play_complete`, `shop_item_click`, `broad_shop_item_click`, `shop_item_impression`, `broad_shop_item_imp`
- GMV/Revenue: `order_gmv` (raw, /100000 for local), `daily_gmv`, `broad_gmv`, `paid_order_gmv`, `agent_order_gmv`, `no_click_gmv`
- Cost/Credit: `cost` (advertiser spend, /100000), `raw_expense`, `cost_by_cpm`, `cpm`, `expense_free_credit_with_expiry`, `expense_free_credit_without_expiry`, `expense_paid_credit_with_expiry`, `expense_paid_credit_without_expiry`, `expense_rebate_free_credit_without_expiry`
- Algo scores: `rank_bid`, `rank_score`, `pvr_boost`, `match_boost`, `organic_value`, `broad_match_value`, `lite_pctr`, `lite_pcr`, `pcr`, `pctr`, `pcr_v`, `pctr_v`, `broad_pcr_v`, `pgmv`, `gmv_boost`, `cold_start_boost`, `new_product_boost_coef`
- Revenue: `expected_revenue`, `receivable_revenue`
- Order amount: `order_amount`, `broad_item_count`, `daily_order_amount`, `agent_order`, `agent_order_amount`, `no_click_order`, `no_click_item_count`, `deduct_order`

## Key Dimensions

- Partition: `grass_date` (DATE), `h` (INT, hour)
- Ads entity: `ads_id`, `campaign_id`, `shop_id`, `item_id`, `account_id`, `model_id`, `creative_id`
- Traffic: `entrance`, `sub_entrance`, `placement`, `slot_id`, `pricing_type`, `bid_type`, `entry_point`
- User: `user_id`, `imp_user_id`, `pageview_user_id`, `click_user_id`
- Attribution: `request_id`, `report_id`, `signature`, `raw_request_id`, `unique_id`, `deduct_unique_id`
- Content: `keyword`, `query`, `match_type`, `page_type`, `page_section`, `target_type`, `search_scenario`, `search_entrance`
- Algo: `bid_rerank_trace`, `algo_json_data`, `uni_pcr_model_name`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | `grass_date` DATE, `h` INT |
| HDFS Path | - |
| Retention | - |
| Column Count | ~160 (same schema as reg_s0_live, schema evolving with mergeSchema) |
| Region Coverage | PH only |
| DQC Status | - |
| Table Size | - |

## Business Properties

*Not fetched from DataMap. Run `--source from-di` to populate.*

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 14 files (all manual_tasks/playground, no formal workflows)
- L7D Query Count: -
- Completeness: -
- Popularity: -
