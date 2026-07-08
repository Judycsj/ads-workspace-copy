<!-- ads-workspace-gdoc-sync: gdoc_id=1gdQagH60NpXk0vE0FE-4SKlrpAqGUeqcEhCugHpwBlU gdoc_url=https://docs.google.com/document/d/1gdQagH60NpXk0vE0FE-4SKlrpAqGUeqcEhCugHpwBlU/edit -->

# mp_paidads.ods_shopee_paidads_recall_log

## Description

- **Desc:** ODS layer search ads recall log, sourced from raw recall pipeline events (`ods_log_recall_hi__reg_s0_live`). Contains per-request recall details including query, keyword matching, ad score info, recall source/reason, bid prices, and AB test signatures. Data is deduplicated by `message_id` and exploded from raw `ad_detail` array into individual ad-level rows.
- **Granularity:** per-request per-ad (request_id x ads_id x item_id x reason x recall_source)
- **Use Case:** Recall source & placement distribution analysis, hopeless item (unpicked) identification for vector search optimization, AB test recall coverage comparison, bid price analysis by region/query, recall tag grouping (manual/simple/both) for performance attribution, keyword-applied recall evaluation, organic vs. paid recall fill rate analysis, i2i seed version AB testing, relevance model version tracking
- **Update Frequency:** Daily (external ODS pipeline, not from studio_tasks production workflows)

## Key Metrics

- **Request volume**: `COUNT(DISTINCT request_id)`, `COUNT(*)`
- **Pick rate / recall success**: `COUNT(DISTINCT CASE WHEN reason='RECALL_REASON_PICKED' THEN request_id END)`
- **Recall coverage**: ratios of picked/non-picked by recall_source, placement, region
- **Scoring metrics**: `AVG(es_score)`, `AVG(pctr)`, `AVG(ecpm_score)`, `AVG(rele_score)`, `AVG(pcr)`, `AVG(bid_price)`
- **Score distribution**: `percentile_approx(rele_score, 0.5)` median, `percentile_approx(picked_keyword_rele_score, 0.05/0.25/0.75/0.95)` percentile analysis
- **Recall tag**: `SUM(DISTINCT (placement+1))` encoding manual/simple/both recall
- **Hopeless items**: items recalled but never picked with `COUNT(DISTINCT user_id) >= 20`
- **Ads per request**: `COUNT(ads_id) / COUNT(DISTINCT request_id)` recall breadth
- **Unpicked rate by reason**: per-reason ratio of non-picked requests

## Key Dimensions

- **Partition**: grass_date, grass_region, tz_type
- **Entity**: request_id, message_id, ads_id, item_id, shop_id, user_id, country, query
- **Recall**: placement, recall_type, recall_source, reason, is_full_sample, match_type, recall_sources (array), filter_stage
- **Scoring**: es_score, bid_price, pctr, ecpm_score, rele_score, picked_keyword_rele_score, pcr
- **AB Test**: ab_test_sign, extra_json (seed_key_versions, rele_model_version, delivery_item_tags)
- **Bidding**: convert_bid_a, convert_bid_b, light_recall_rank
- **Query**: query, query_text_proc, query_text_proc_exact, picked_keyword, index_trace_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_paidads_recall_log |
| Retention | 31 days (auto DROP partition via lifecycle_management) |
| Column Count | 38 (34 data + 4 partition: message_id, request_id, country, query, user_id, ads_id, placement, recall_type, index_trace_id, query_text_proc, query_text_proc_exact, ab_test_sign, reason, recall_source, is_full_sample, match_type, es_score, bid_price, picked_keyword, picked_keyword_rele_score, rele_score, pctr, ecpm_score, light_recall_rank, extra_json, pcr, convert_bid_a, convert_bid_b, request_source, timestamp, event_datetime, item_id, shop_id, recall_sources, filter_stage, tz_type, grass_region, grass_date) |
| Region Coverage | BR, CO, CL, ID, MX, MY, PH, SG, TH, TW, VN + US (separate cluster via `ods_shopee_paidads_recall_log_us`) |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | Search Ads - Recall |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 790 files (55 workflows, 21 scheduled_tasks, 713 manual_tasks, 1 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
