<!-- ads-workspace-gdoc-sync: gdoc_id=1v4GkVdj4c1g7OvBxBVU2Ho_mjZf55AmQ2BH22KcpCZo gdoc_url=https://docs.google.com/document/d/1v4GkVdj4c1g7OvBxBVU2Ho_mjZf55AmQ2BH22KcpCZo/edit -->

# Columns: mp_paidads.ods_shopee_paidads_recall_log

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 reason/recall_source 聚合时必须特别注意以下字段：

- `placement` (with `SUM(DISTINCT)`)：Used in `SUM(DISTINCT (placement+1))` pattern to encode recall_tag (6=both manual+simple, 5=manual only, 1=simple only). Cannot simply SUM across requests, must use DISTINCT per `(request_id, item_id)` group.
- `COUNT(DISTINCT request_id)`：跨多个 reason 分组后不能直接 SUM，必须先 GROUP BY reason 再用 MAX 或条件聚合。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| reason | RECALL_REASON_PICKED | Ad was picked for serving |
| reason | RECALL_REASON_UNPICKED_LOW_RELE_SCORE | Filtered out due to low relevance score |
| reason | RECALL_REASON_UNPICKED_DUPLICATE_ITEM_ID | Filtered out as duplicate item |
| reason | RECALL_REASON_UNPICKED_OFFLINE_FILTER_NOT_PASS | Failed offline quality filter |
| reason | RECALL_REASON_UNPICKED_LOW_ECPM | Filtered out due to low eCPM |
| reason | RECALL_REASON_UNPICKED_ADS_INFO_ERR | Filtered due to ad info error |
| reason | RECALL_REASON_UNPICKED_NO_PAIRED_KEYWORD | No paired keyword for the ad |
| recall_source | RECALL_SOURCE_GENERAL_Q2I_OFFLINE_QUEUE | General query-to-item offline recall queue |
| recall_source | RECALL_SOURCE_ROI2_GENERAL_Q2I_OFFLINE_QUEUE | ROI2 general offline recall queue |
| recall_source | RECALL_SOURCE_BFQ | Boost for query recall |
| recall_source | RECALL_SOURCE_SIMPLE_BOOST | Simple boost recall |
| recall_source | RECALL_SOURCE_KNN | KNN/vector search recall |
| placement | 0, 1, 2, 5 | Manual bidding (search ads) |
| placement | 4 | Simple bidding (keyword ads) |
| placement | 40 | ROI2 bidding |
| placement | 50 | Simple ROI2 bidding |
| placement | 1000, 1200 | Additional manual bidding variants (manual tasks) |
| is_full_sample | 1 | Full sample (not sampled), required for accurate stats |
| is_full_sample | 0 | Sampled log (partial data) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~95% of queries use local timezone)
- `is_full_sample`: 1 (required for accurate counting/stats, ~75% of queries)
- `grass_region`: Standard 8 regions ('ID','MY','PH','SG','TH','TW','VN') + LATAM ('MX','CO','CL','BR')
- `ads_id`: > 0 (filter out placeholder/invalid ads)
- `item_id`: > 0 (filter invalid items)
- `user_id`: > 0 (filter bots/invalid users)
- `request_id`: NOT LIKE '%search_log_replay' AND NOT LIKE '%stress_test' AND NOT LIKE '%test' AND NOT LIKE '%replay' AND <> 'SA-Portal' (filter test/replay data, ~15% of production insert queries)
- `reason`: 'RECALL_REASON_PICKED' (for picked-only analysis, ~40% of queries)
- `placement`: `IN (0, 4, 1000, 1200)` (search ads most common), `IN (0, 4)` (manual bidding only), `IN (0, 1, 2, 5)` (manual bidding variants), `= 0` (manual exact match only)
- `recall_source`: `IN ('RECALL_SOURCE_GENERAL_Q2I_OFFLINE_QUEUE', 'RECALL_SOURCE_ROI2_GENERAL_Q2I_OFFLINE_QUEUE')` (Q2I recall analysis), `<> 'RECALL_SOURCE_BFQ'` (exclude boost queries)
- `query`: IS NOT NULL (filter empty searches)

### AB Test Patterns

- `ab_test_sign`: parsed via `regexp_like(ab_test_sign, '\|{EXPERIMENT_ID}\|')` or `rlk '%\|{ID}\|%'` to extract weblab experiment IDs and split into base/exp groups
- Note: both `regexp_like` and `rlk`/`strpos` patterns are used; `regexp_like` is the modern preferred approach
- `extra_json`: parsed via `json_extract_scalar(extra_json, '$.seed_key_versions')` for i2i seed version analysis; also contains `rele_model_version` (via `get_json_object`) and `delivery_item_tags`
- Multiple AB test matching patterns exist: `|\%|{ID}|\%|` (most common), `.*weblab.*[^0-9]{ID}([^0-9].*|)` (legacy)

### Sampling Pattern

- `rand() < 0.1` appears in ~3% of queries for lightweight analysis/exploration (10% sampling)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| message_id | STRING | CONCAT(session_id, sequence_id, event_timestamp, region) -- dedup primary key from upstream | - | - |
| request_id | STRING | Unique request identifier; filter out test/replay/stress_test patterns | - | - |
| country | STRING | Country code of the request (may differ from grass_region in some contexts) | - | - |
| query | STRING | User search query text | - | - |
| user_id | BIGINT | User identifier | - | - |
| ads_id | BIGINT | Advertisement ID | - | - |
| placement | BIGINT | Bidding placement type (0/1/2/5=manual, 4=simple, 40=roi2, 50=simple_roi2) | - | - |
| recall_type | BIGINT | Type of recall strategy | - | - |
| index_trace_id | STRING | Index trace identifier for debugging | - | - |
| query_text_proc | STRING | Processed query text | - | - |
| query_text_proc_exact | STRING | Exact processed query text | - | - |
| ab_test_sign | STRING | AB test experiment signature string; filter via regexp_like/rlike/strpos | - | - |
| reason | STRING | Recall pick reason (PICKED, UNPICKED_LOW_RELE_SCORE, UNPICKED_DUPLICATE_ITEM_ID, UNPICKED_OFFLINE_FILTER_NOT_PASS, UNPICKED_LOW_ECPM, UNPICKED_ADS_INFO_ERR, UNPICKED_NO_PAIRED_KEYWORD) | - | - |
| recall_source | STRING | Source recall queue name (RECALL_SOURCE_GENERAL_Q2I_OFFLINE_QUEUE, RECALL_SOURCE_ROI2_GENERAL_Q2I_OFFLINE_QUEUE, RECALL_SOURCE_BFQ, RECALL_SOURCE_SIMPLE_BOOST, RECALL_SOURCE_KNN, etc.) | - | - |
| is_full_sample | TINYINT | Whether record is from full sample (1) or sampled (0); always filter =1 for accurate counting | - | - |
| match_type | STRING | Keyword match type (exact/broad/phrase) | - | - |
| es_score | DOUBLE | Elasticsearch relevance score | - | - |
| bid_price | BIGINT | Bid price for the ad; analyzed via AVG/percentile_approx | - | - |
| picked_keyword | STRING | The keyword that matched to pick this ad | - | - |
| picked_keyword_rele_score | DOUBLE | Relevance score of the picked keyword; analyzed via percentile_approx(0.05,0.25,0.5,0.75,0.95) | - | - |
| rele_score | DOUBLE | Overall relevance score; analyzed via MAX(STRUCT(timestamp, rele_score)) for latest value per query-item-model | - | - |
| pctr | DOUBLE | Predicted CTR | - | - |
| ecpm_score | DOUBLE | Effective CPM score | - | - |
| light_recall_rank | BIGINT | Ranking position in light recall stage | - | - |
| extra_json | STRING | Extra metadata in JSON format (seed_key_versions, rele_model_version, delivery_item_tags, etc.); use json_extract_scalar or get_json_object | - | - |
| pcr | DOUBLE | Predicted conversion rate | - | - |
| convert_bid_a | BIGINT | Conversion bid parameter A | - | - |
| convert_bid_b | BIGINT | Conversion bid parameter B | - | - |
| request_source | STRING | Source of the request (NULL if empty from upstream) | - | - |
| timestamp | BIGINT | Event timestamp (UNIX epoch); used for MAX(STRUCT(timestamp, ...)) pattern to get latest value | - | - |
| event_datetime | STRING | Human-readable event datetime in local timezone (yyyy-MM-dd HH:mm:ss) | - | - |
| item_id | BIGINT | Item/sku ID | - | - |
| shop_id | BIGINT | Shop ID | - | - |
| recall_sources | ARRAY<INT> | Array of recall source IDs (binary encoding, less used than `recall_source` string column) | - | - |
| filter_stage | INT | Stage at which filtering occurred | - | - |
| tz_type | STRING | Timezone type (partition key); almost always 'local' | - | - |
| grass_region | STRING | Region/country (partition key); standard 8 + LATAM + US | - | - |
| grass_date | DATE | Date (partition key, yyyy-MM-dd) | - | - |
