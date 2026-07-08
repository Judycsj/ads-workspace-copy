<!-- ads-workspace-gdoc-sync: gdoc_id=1jOmCkvFMPo5rf5veEWggg-K8EfupuqNb0RR9peJGCzM gdoc_url=https://docs.google.com/document/d/1jOmCkvFMPo5rf5veEWggg-K8EfupuqNb0RR9peJGCzM/edit -->

# Columns: mp_paidads.ods_shopee_paidads_index_log

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `grass_date`, `grass_region`, `tz_type` — 分区列，不能直接 SUM
- 大部分数值字段（pctr, ecr, cir, bidding_price 等）为单次索引事件的值，跨 ads_id 聚合时需注意业务含义

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | INDEX | 成功索引（广告进入索引库） |
| operation | UPDATE | 更新索引 |
| operation | DELETE | 删除索引 |
| visible | 1 | 广告可见/有效 |
| visible | 0 | 广告不可见（如日预算耗尽） |
| reason | OK | 索引成功 |
| reason | (其他) | 索引失败原因（如预算不足、审核未通过等） |
| placement | 0, 1, 2, 5 | Manual（手动出价） |
| placement | 40 | ROI2（ROI出价） |
| placement | 50 | Simple ROI2（简易ROI出价） |
| placement | 4, 1000, 1200 | Search Manual |
| placement | 802, 805, 1002, 1005, 1202, 1205 | Discovery Ads（发现页广告） |
| pricing_type | 1 | Normal Manual |
| pricing_type | 2 | Manual + eCPC |
| pricing_type | 11, 24, 25 | Target ROI（目标ROI出价） |
| pricing_type | 15 | Simple ROI（简易ROI） |
| pricing_type | 27 | Product GMS |
| tz_type | local | 当地时区 |
| tz_type | regional | 统一时区（新加坡时区） |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 通常取 T-1（`date_add(current_date, -1)` 或 `DATE('${1_DAYS_AGO}')`）
- `grass_region`: 标准8区 `('ID','TH','VN','MY','PH','TW','SG','BR')`
- `tz_type`: `'local'`（70%+ 查询使用 local 时区）
- `operation`: `'INDEX'`（最常用，约80%查询）、`'UPDATE'`（召回评估场景）
- `visible`: `1`（只取有效广告）
- `reason`: `'OK'`（只取成功索引的记录）
- `placement`: 按产品类型过滤
  - Discovery Ads 全量: `in (2, 5, 802, 805, 1002, 1005, 1202, 1205, 40, 50)`
  - ROI Ads: `in (40, 50)`
  - Search Ads: `in (0, 4, 1000, 1200)`
  - Full link diagnosis (manual): `in (0, 1, 2, 5)`
- `pricing_type`: 按出价模式过滤
  - ROI 类: `in (11, 15)` 或 `in (11, 15, 24, 25, 27)`
  - 非零: `pricing_type > 0`
- `ads_id > 0` / `item_id > 0` / `shop_id > 0`: 排除无效 ID
- `item_create_time`: `DATE(FROM_UNIXTIME(item_create_time))` 用于冷启动商品识别
  - 新品: `> date_add(current_date, -31)`（30天内创建）
  - 老品: `< date_add(current_date, -37)`（37天前创建）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| message_id | varchar | CONCAT(meta.session_id,meta.sequence_id,meta.event_timestamp,meta.region) primary key | - | - |
| ads_id | bigint | ads_id | - | - |
| index_trace_id | varchar | index_trace_id | - | - |
| placement | bigint | placement (投放位) | - | - |
| bidding_price | bigint | bidding_price | - | - |
| bid_keyword | varchar | bid keyword | - | - |
| cir | double | cir (目标CIR值) | - | - |
| cir_type | tinyint | cir_type | - | - |
| cir_sub_type | tinyint | cir_sub_type | - | - |
| count_per_order | double | count_per_order | - | - |
| ecr | double | ecr | - | - |
| group_id | bigint | group_id | - | - |
| hidden_tag_bm | varchar | hidden_tag_bm | - | - |
| hnsw_cluster_id | varchar | hnsw_cluster_id | - | - |
| hnsw_cluster_score | double | hnsw_cluster_score | - | - |
| intention_id_list | varchar | intention id list in string format | - | - |
| item_id | bigint | item_id (商品ID) | - | - |
| item_price | bigint | item_price | - | - |
| keyword | varchar | keyword | - | - |
| kw_intention_id_list | varchar | keyword intention id list | - | - |
| kwrcmd_tag_bm | varchar | kwrcmd_tag_bm | - | - |
| match_type | bigint | match_type | - | - |
| pctr | double | pctr (预估CTR) | - | - |
| reason | varchar | 索引结果。OK=成功；非OK=索引失败原因 | - | - |
| shop_id | bigint | shop_id (店铺ID) | - | - |
| pid_log_id | varchar | pid log id for simple mode ads | - | - |
| bid_type | bigint | bid type for simple mode (error, adjusted price, min cap, seller cap etc.) | - | - |
| timestamp | bigint | event timestamp | - | - |
| event_datetime | varchar | datetime format of timestamp in local timezone | - | - |
| sub_type_list | varchar | sub_type list in string format | - | - |
| filter_segments_gender_group_list | varchar | filter segments gender group list | - | - |
| filter_segments_gender_group_required_match | bigint | filter segments gender group required match | - | - |
| filter_segments_category_group_list | varchar | filter segments category group list | - | - |
| filter_segments_category_group_required_match | bigint | filter segments category group required match | - | - |
| filter_segments_age_group_list | varchar | filter segments age group list | - | - |
| filter_segments_age_group_required_match | bigint | filter segments age group required match | - | - |
| filter_segments_location_group_list | varchar | filter segments location group list | - | - |
| filter_segments_location_group_required_match | bigint | filter segments location group required match | - | - |
| premium_segments | varchar | premium_segments | - | - |
| operation | varchar | 操作类型：INDEX/UPDATE/DELETE | - | - |
| application_id | varchar | 索引类型：realtime or batch indexing | - | - |
| visible | tinyint | 可见性。1=可见；0=不可见（日常预算耗尽等） | - | - |
| update_timestamp | bigint | latest daily budget update timestamp | - | - |
| pricing_type | integer | 出价类型。1=Manual, 2=Manual+eCPC, 11/24/25=Target ROI, 15=Simple ROI, 27=GMS | - | - |
| daily_split_quota | bigint | daily_split_quota | - | - |
| split_budget_version | integer | split_budget_version | - | - |
| item_embedding_version | array(varchar) | item_embedding_version | - | - |
| named_entity | varchar | named_entity | - | - |
| ne_attribute | varchar | ne_attribute | - | - |
| item_attribute | array(bigint) | item_attribute | - | - |
| bm_kw_phrase | varchar | bm_kw_phrase | - | - |
| item_embedding | varchar | item_embedding | - | - |
| global_hiddentag | varchar | global_hiddentag | - | - |
| global_pname | varchar | global_pname | - | - |
| ads_kind | varchar | ads_kind | - | - |
| algo_status | integer | algo_status | - | - |
| campaign_id | bigint | campaign_id (广告系列ID) | - | - |
| global_hiddentag_bm | varchar | global_hiddentag_bm | - | - |
| index_source | varchar | index_source | - | - |
| item_create_time | bigint | item_create_time (商品创建时间Unix timestamp) | - | - |
| broad_target_roas | integer | broad_target_roas | - | - |
| item_name | varchar | item_name | - | - |
| brand | varchar | brand | - | - |
| brand_id | integer | brand_id | - | - |
| ta_group_id | bigint | ta_group_id | - | - |
| ta_premium_rate | bigint | ta_premium_rate | - | - |
| ta_tag_ids | array(integer) | ta_tag_ids | - | - |
| campaign_surge | integer | campaign_surge | - | - |
| item_price_v2 | bigint | item_price_v2 | - | - |
| begin_time | bigint | begin_time | - | - |
| end_time | bigint | end_time | - | - |
| tz_type | varchar | PARTITION KEY — 时区类型 (local/regional) | - | - |
| grass_region | varchar | PARTITION KEY — 地区 | - | - |
| grass_date | date | PARTITION KEY — 日期 yyyy-MM-dd | - | - |
