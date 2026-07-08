<!-- ads-workspace-gdoc-sync: gdoc_id=1Z1uomwolf1gpys832PsA5XSN590NaQKSMK7hgK5CJw8 gdoc_url=https://docs.google.com/document/d/1Z1uomwolf1gpys832PsA5XSN590NaQKSMK7hgK5CJw8/edit -->

# Columns: paidads_mart.dwd_trace_recall_log_di__reg_s0_live

## Column Usage Notes

### 字段使用模式

本表为三元组 (request_id, item_id) 粒度的召回明细日志，每行代表一个 item 在某 request 中的召回状态。使用时需要注意：

- `queue_tag` vs `queue_tags` vs `delivery_item_tags`: 单个队列标签 (`queue_tag`) vs 数组型多队列标签 (`queue_tags` / `delivery_item_tags`)
- `reason` 字段是召回漏斗分析的核心，有 30+ 种枚举值，代表召回链路中不同阶段的淘汰/通过状态
- `extra_json` 是 JSON 字段，包含扩展信息（如 `pricing_type`, `video_bid_price`, `item_price`, `seed_item_id`），需用 `get_json_object()` 提取
- `ab_test_sign` 是 pipe-separated 的实验号字符串，需用 `LIKE '%|xxx|%'` 或 `split()` + `array_intersect()` 匹配

### 枚举值映射 (Value Mappings)

**biz_type → 场景映射:**

| Column | Value | Meaning |
|--------|-------|---------|
| biz_type | 1 | Search Ads |
| biz_type | 2 | Daily Discover (DD) |
| biz_type | 3 | You May Also Like (YMAL) |
| biz_type | 4 | Cart Unify / OSP |
| biz_type | 5 | Game |
| biz_type | 6 | Video Ads |
| biz_type | 7 | Shop |

**entrance → 场景映射:**

| Column | Value | Meaning |
|--------|-------|---------|
| entrance | 1 | Search |
| entrance | 3, 25, 31, 32 | Daily Discover |
| entrance | 4 | You May Also Like |
| entrance | 7, 14, 15, 16, 17, 18, 19, 20, 21, 22, 26, 30, 41, 43 | Game |
| entrance | 8, 9, 10, 11, 40, 45, 51 | Cart Unify / Product Page |
| entrance | 29, 33, 34, 35, 50, 58 | Video Ads |

**reason → 漏斗阶段映射:**

| Column | Value | Meaning |
|--------|-------|---------|
| reason | RECALL_REASON_PICKED, RECALL_REASON_PICKED_RANDOM_RECALL_ADS | 6 - API0 Result (最终入选) |
| reason | RECALL_REASON_UNPICKED_LOW_ECPM, RECALL_REASON_UNPICKED_LOW_PCTR, RECALL_REASON_UNPICKED_LOW_PCR, RECALL_REASON_UNPICKED_LOW_PCTR_PCR, RECALL_REASON_UNPICKED_PACING_PRERANK_STRATEGY_DROPS | 5 - Prerank 淘汰 |
| reason | RECALL_REASON_UNPICKED_NO_PAIRED_KEYWORD, RECALL_REASON_UNPICKED_LOW_BID_PRICE, RECALL_REASON_UNPICKED_ADS_INFO_ERR, RECALL_REASON_UNPICKED_OFFLINE_FILTER_NOT_PASS, RECALL_REASON_UNPICKED_ORGANIC_OFFLINE_FILTER_NOT_PASS, RECALL_REASON_UNPICKED_ITEM_NO_ADS, RECALL_REASON_UNPICKED_VIDEO_INFO_ERR, RECALL_REASON_UNPICKED_LOW_QUALITY_VIDEO | 4 - Ads Info 淘汰 |
| reason | RECALL_REASON_UNPICKED_LOW_RELE_SCORE, RECALL_REASON_UNPICKED_RELEVANCE_BLACKLIST | 3 - Relevance 淘汰 |
| reason | RECALL_REASON_UNPICKED_DUPLICATE_ITEM_ID, RECALL_REASON_UNPICKED_SNAKE_MERGE_DROPS, RECALL_REASON_UNPICKED_SHOP_TRUNCATE | 2 - Snake Merge 淘汰 |
| reason | RECALL_REASON_UNPICKED_INACTIVE_ITEM, RECALL_REASON_UNPICKED_INACTIVE_KEYWORD, RECALL_REASON_UNPICKED_OVER_DELIVERY, RECALL_REASON_UNPICKED_OVER_DELIVERY_ANTI_FRAUD_FILTER, RECALL_REASON_UNPICKED_OVER_DELIVERY_FLOW_CONTROL_FILTER, RECALL_REASON_UNPICKED_LOW_BUDGET 等 | 1 - Inactive Filter 淘汰 |

**placement → 出价类型映射:**

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0, 1, 2, 5 | Manual (ROI1) |
| placement | 40 | Target ROI2 |
| placement | 50 | Simple ROI2 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')
- `local_date`: 单一日期，固定分区过滤
- `biz_type`: 1 (Search, 最高频) / 2 (DD) / 3 (YMAL) / 6 (Video)
- `is_full_sample = 1` — 全量样本过滤（AB 实验分析必需）
- `reason is not null` — 排除空 reason 行
- `ads_id > 0` — 过滤无广告 ID 的记录
- `query is not null` — 过滤无查询词记录
- `queue_tag like '%7%'` — Video Ads 队列过滤
- `placement in (0, 4, 1000, 1200, 40, 50)` — 标准出价类型
- `ab_test_sign like '%|xxxxx|%'` — 精确实验号匹配
- `(timestamp % 600) < 60` — 时间采样（1/10 采样率）
- `abs(hash(request_id)) % 1000 < 10` — Hash 采样（1% 采样率）

## All Columns

*DDL 未在代码库中找到。请运行 `--source from-di` 补充列名、类型和描述信息。*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| - | - | - | - | - |
