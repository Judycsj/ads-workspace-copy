<!-- ads-workspace-gdoc-sync: gdoc_id=1bsOEpttuzQz4XPA74SCTQzEBefIbP7c3x_TzTVIfuEU gdoc_url=https://docs.google.com/document/d/1bsOEpttuzQz4XPA74SCTQzEBefIbP7c3x_TzTVIfuEU/edit -->

# Columns: mp_paidads.ods_shopee_paidads_keyword_ad_search_log

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为 request × ad 级别的日志表，所有字段均为单次请求的原始值，无跨维度的重复计数问题。直接 SUM 即可，无需 SUM(DISTINCT)。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| reason | 0 | PICKED (成功展示) |
| reason | 1 | UNPICKED_LOW_PCR_SCORE |
| reason | 2 | UNPICKED_LOW_PCTR_SCORE |
| reason | 3 | UNPICKED_LOW_PCR_PCTR_SCORE |
| reason | 4 | UNPICKED_DUPLICATE_ITEM_ID |
| reason | 5 | UNPICKED_INACTIVE |
| reason | 6 | UNPICKED_TRUNCATED |
| reason | 7 | UNPICKED_USER_BLACKLSITED |
| reason | 8 | UNPICKED_TRUNCATED_OVER_RECALL_ADS_TARGET_SUP_ADS |
| reason | 9 | UNPICKED_LOW_ECPM |
| recall_source | 0 | RECALL_SOURCE_KEYWORD |
| recall_source | 1 | RECALL_SOURCE_SIMPLE |
| recall_source | 2 | RECALL_SOURCE_ITEM |
| recall_source | 3 | RECALL_SOURCE_OFFLINE_QUEUE |
| recall_source | 4 | RECALL_SOURCE_QUERY_EXPANSION |
| recall_source | 5 | RECALL_SOURCE_KNN |
| recall_source | 6 | RECALL_SOURCE_BFQ |
| recall_source | 7 | RECALL_SOURCE_SWING |
| recall_source | 8 | RECALL_SOURCE_GS_KNN |
| recall_source | 9 | RECALL_SOURCE_ORGANIC_OFFLINE_QUEUE |
| recall_source | 10 | RECALL_SOURCE_RETRIEVAL_I2I |
| recall_source | 11 | RECALL_SOURCE_PRERANK_I2I |
| recall_source | 12 | RECALL_SOURCE_ONE_TOWER |
| recall_source | 13 | RECALL_SOURCE_QUERY_TAG |
| recall_source | 50 | RECALL_SOURCE_SIMPLE_TEXT |
| recall_source | 51 | RECALL_SOURCE_SIMPLE_BROAD |
| recall_source | 52 | RECALL_SOURCE_SIMPLE_INTENTION |
| recall_source | 53 | RECALL_SOURCE_SIMPLE_BOOST |
| recall_source | 54 | RECALL_SOURCE_SIMPLE_AUTO_BOOST |

### 常见 WHERE 值 (Common Filter Values)

- **tz_type**: `'local'` (~100% 生产查询使用此值)
- **placement**: `0, 4, 1000, 1200` (搜索广告位; 0=主搜结果页, 4=品类页)
- **reason**: `'PICKED'` (仅关注成功展示的广告; ~80% 分析场景)
- **grass_region**: 8 个标准区域 `'ID','MY','PH','SG','TH','TW','VN'`; 拉美区域 `'BR','MX','CO','CL'`
- **ads_id > 0** (过滤无效广告)
- **request_id is not null** 且 `!= 'SA-Portal'` (过滤内部请求)
- **pctr > 0** (~60% 分析场景过滤零分预估)
- **ab_sign**: `rlike '%|1818|%'` / `like '%entrance=23%'` 等模式匹配做实验分流

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| message_id | string | Primary key: CONCAT(session_id, sequence_id, event_timestamp, region) | - | - |
| request_id | string | 请求唯一标识 | - | - |
| country | string | 原始 country 字段 (如 SG, ID, MY) | - | - |
| query | string | 用户搜索关键词 | - | - |
| ads_id | bigint | 广告 ID | - | - |
| placement | bigint | 广告位类型 (0=主搜, 4=品类页, 1000=搜索推荐, 1200=...) | - | - |
| index_trace_id | string | 索引链路追踪 ID | - | - |
| session_id | string | 用户会话 ID | - | - |
| user_id | bigint | 用户 ID | - | - |
| ab_sign | string | AB 实验签名/分桶标识 (如 `weblab=xxx`, `entrance=xxx`) | - | - |
| item_id | bigint | 商品 ID | - | - |
| pctr | double | 预估点击率 (pCTR) | - | - |
| bid_price | bigint | 出价 (原始单位, 需 /100000 转 Local Currency) | - | - |
| pcr_price | bigint | pCR 出价 | - | - |
| capped_price | bigint | 上限价格/capped bid (需 /100000 转 Local Currency) | - | - |
| rank | bigint | 最终排序位置 (越小越靠前, 1-based) | - | - |
| deduction_price | bigint | 实际扣费价格 | - | - |
| ecr | double | 预估转化率 (pCVR) | - | - |
| pcr | double | 预估转化率 (pCR, 另一版本) | - | - |
| match_type | string | 关键词匹配类型 | - | - |
| group_id | bigint | 广告组 ID | - | - |
| ecpm | double | ECPM 排序分 (综合排序得分) | - | - |
| rele_score | double | 相关性得分 | - | - |
| recall_rank | bigint | 粗排/recall 阶段排名 | - | - |
| recall_score | double | 召回得分 | - | - |
| recall_type | bigint | 召回类型 (数字编码) | - | - |
| extra_json | string | 扩展 JSON 字段 (见下方 extra_json 常用 key 说明) | - | - |
| reason | string | 广告是否展示/Pick 原因 (枚举值见上方) | - | - |
| recall_source | bigint | 召回来源编码 (枚举值见上方) | - | - |
| recall_source_name | string | 召回来源名称 | - | - |
| request_source | string | 请求来源 | - | - |
| intention_id_list | string | 意图 ID 列表 (string array) | - | - |
| timestamp | bigint | 事件 Unix 时间戳 | - | - |
| event_datetime | string | 事件本地时间 (yyyy-MM-dd HH:mm:ss) | - | - |
| recall_resp_code | bigint | 请求超时标记 (0=正常, 非0=超时无广告展示) | - | - |
| tz_type | string | [PARTITION] 时区类型 (通常 'local') | - | - |
| grass_region | string | [PARTITION] 区域 | - | - |
| grass_date | date | [PARTITION] 数据日期 (yyyy-MM-dd) | - | - |

### extra_json 常用 Key

extra_json 是结构灵活的 JSON 字段，经常通过 `get_json_object()` / `json_extract()` 提取以下 key：

| Key | 类型 | 用途 |
|-----|------|------|
| origin-bid-price | int | 原始出价 (cents, /100000 = Local Currency) |
| bid-type | int | 出价类型 |
| sort-type | int | 排序算法版本号 (如 9=特定版本) |
| bid-version | int | 出价版本 |
| r-cap-type | int | 粗排 cap 类型 |
| keyword | string | 关键词 (同 query) |
| bid-keyword | string | 出价关键词 |
| item-price | double | 商品价格 |
| organic-value | double | 自然推荐价值 |
| ecpm | double | ECPM 分 |
| rank-score | double | 排序分 |
| page-offset | int | 分页偏移 |
| page-limit | int | 分页大小 |
| creative_id | string | 创意 ID |
| creative_algo | string | 创意算法版本 |
| creative_drop | string | 创意丢弃标记 |
| creative_imp | string | 创意展示标记 |
| creative_click | string | 创意点击标记 |
| rerank-trace | json | 重排追踪(嵌套JSON): $.ad_data.cali_pcr, $.ad_data.ori_cali_pcr, $.ad_data.cali_verify_pcr, $.organic.* |
| query_rewrite | string | Query 改写信息 |
| ad-tag | int | 广告标签 |
| tcir | double | target CIR |
| TAGroupId | int | TA 人群包 ID |
| TATagIds | array<int> | TA 匹配标签 ID 列表 |
| TAPremiumRate | int | TA 溢价比例 |
| entrance | int | 流量入口 |
| pctr-algo | string | pCTR 算法版本 |
| pcr-algo | string | pCR 算法版本 |
| vespa-recall-score | double | KNN 相似度得分 |
