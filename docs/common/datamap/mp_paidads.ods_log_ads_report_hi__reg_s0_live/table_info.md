<!-- ads-workspace-gdoc-sync: gdoc_id=1KpJ58TxHoLxsdBd9xJ-Ddi4lRsGnP3ehlEPKc8bE3t0 gdoc_url=https://docs.google.com/document/d/1KpJ58TxHoLxsdBd9xJ-Ddi4lRsGnP3ehlEPKc8bE3t0/edit -->

# mp_paidads.ods_log_ads_report_hi__reg_s0_live

## Description

- **Desc:** ODS-layer hourly ads report event log (commonly called "ReportNG"), recording per-event impression/click/order/checkout/add-to-cart facts for all Shopee Ads placements. Each row is a single event with full attribution context (ads_id, request_id, report_id, buyer/seller info, bidding trace, UDF-decodable algo features). Upstream data is ingested from the ads report service via Parquet files on HDFS.
- **Granularity:** hourly x event-level (one row per ads event per region per hour)
- **Use Case:** DWD performance table production (dwd_advertise_preformance_hi), Take Rate daily report (ads_advertise_take_rate_v2_1d), Brand Tracking Ads daily (dws_brand_tracking_ads_1d), Uplift model training & PCOC monitoring, Algo feature extraction (query-item conversion sequences, calibrator features), Display Ads performance reporting, Advertiser overspend detection, AB experiment signature analysis
- **Update Frequency:** Hourly (event-driven ingestion, partitioned by hour)

## Key Metrics

- Event flags: `impression`, `click`, `raw_click`, `non_fraud_click`, `deduplicated_click`, `order`, `daily_order`, `checkout`, `add_to_cart`, `broad_order`, `broad_add_to_cart`, `pageview`, `product_click`, `view`, `video_view`, `video_play_complete`
- GMV/Revenue: `order_gmv` (raw, /100000 for USD local), `daily_gmv`, `broad_gmv`, `cost` (advertiser spend, /100000), `raw_expense`, `cost_by_cpm`, `cpm`, `paid_order_gmv`, `agent_order_gmv`
- Credit breakdown: `expense_free_credit_with_expiry`, `expense_free_credit_without_expiry`, `expense_paid_credit_with_expiry`, `expense_paid_credit_without_expiry`, `expense_rebate_free_credit_without_expiry`
- Algo scores: `rank_bid`, `rank_score`, `pvr_boost`, `match_boost`, `organic_value`, `broad_match_value`, `lite_pctr`, `lite_pcr`, `pcr`, `pctr`, `pcr_v`, `pctr_v`, `broad_pcr_v`, `pgmv`, `gmv_boost`, `cold_start_boost`, `new_product_boost_coef`, `expected_revenue`, `receivable_revenue`
- Order amount: `order_amount` (item sold count), `broad_item_count`, `daily_order_amount`, `agent_order`, `agent_order_amount`, `no_click_order`, `no_click_gmv`, `deduct_order`

## Key Dimensions

- Partition: `grass_region`, `grass_date` (or `dt` in legacy schema), `h` (hour)
- Ads entity: `ads_id`, `campaign_id`, `shop_id`, `item_id`, `account_id`, `model_id`, `creative_id`
- Traffic: `entrance`, `sub_entrance`, `placement`, `slot_id`, `pricing_type`, `bid_type`, `entry_point`
- User: `user_id`, `imp_user_id`, `pageview_user_id`, `click_user_id`, `buyer_segments`
- Attribution: `request_id`, `report_id`, `signature` (AB sign), `raw_request_id`, `unique_id`, `deduct_unique_id`
- Content: `keyword`, `query`, `match_type`, `page_type`, `page_section`, `target_type`, `search_scenario`, `search_entrance`
- Algo: `bid_rerank_trace` (UDF-decodable JSON), `algo_json_data`, `uni_pcr_model_name`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (spark.sql.parquet.mergeSchema=true) |
| Partition Columns | `grass_region` STRING, `grass_date` DATE (or `dt` DATE in legacy), `h` INT |
| HDFS Path | `hdfs://R2/projects/data_paidadsmart/hdfs/prod/logs/ods_log_ads_report_hi__reg_s0_live` (mp_paidads schema); `hdfs://R2/projects/mkplpaidads_data/hdfs/prod/logs/ads_report_ng_event` (mkplpaidads_data schema) |
| Retention | - |
| Column Count | ~190 (schema evolving, mergeSchema enabled) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX |
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

- Studio Tasks References: 1108 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
