<!-- ads-workspace-gdoc-sync: gdoc_id=1DFOkwFWB96E9tNTHoRuX6VEGmKKvCS-RAJmKnIUtUY8 gdoc_url=https://docs.google.com/document/d/1DFOkwFWB96E9tNTHoRuX6VEGmKKvCS-RAJmKnIUtUY8/edit -->

# Columns: mp_paidads.ods_log_trace_shop_ads_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `ads` — 数组列, 需用 `LATERAL VIEW EXPLODE(ads)` 展开后聚合
- `ext_info` — JSON 字符串, 需用 `get_json_object(ext_info, '$.key')` 提取子字段
- `ads.ads_info.top_item_ids` — 数组, 需再次 EXPLODE
- `ads.ads_info.rcmd_items` — 数组, 需再次 EXPLODE
- `ads.ads_info.ext_info` — 广告级 JSON, 需二次解析

### 枚举值映射 (Value Mappings)

#### `ads[*].reason` (广告 pick/unpick 原因)

| Value | Meaning |
|-------|---------|
| 1 | PICKED |
| 3 | UNPICKED_RANK_LOW_PCTR_SCORE |
| 7 | UNPICKED_TRUNCATED |
| 11 | UNPICKED_ASSEMBLE_NO_SKU |
| 13 | UNPICKED_FILTER_LOW_RELEVANCE |
| 14 | UNPICKED_FILTER_INACTIVE_ADS |
| 16 | UNPICKED_RANK_LOW_ECPM_SCORE |
| 18 | UNPICKED_RANK_LOW_BID_PRICE |

#### `ads[*].placement` (广告位)

| Value | Meaning |
|-------|---------|
| 3 | Shop Ads Search (manual mode, placement_3 / PLACEMENT_SHOP_SEARCH_ID) |
| 20 | Shop Ads Search (simple mode, old) |
| 2003 | Shop Ads Search (simple mode, migrated / PLACEMENT_SIMPLE_MODE_SHOP_SEARCH_MIGR) |
| 33 | Live Ads |
| 2030 | Shop Ads Recommendation / Discovery |
| 3327 | Live Ads (variant) |
| 3328 | Live Ads (variant) |

#### `ext_info` JSON keys (常用 key)

| Key | Type | Meaning |
|-----|------|---------|
| bucket_id | string | AB 实验 bucket ID |
| init_bid_price | string/number | 初始出价 |
| target_roi | string/number | Target ROI |
| aov | string/number | 客单价预估 |
| pcr | string/number | 预估 CVR (pCVR) |
| pctr | string/number | 预估 CTR (pCTR) |
| bidding_info | JSON | 出价信息 (MinBidCap, MaxBidCap, BidPriceFromVespa, BidPriceCalculated, BidPriceAfterCapping) |
| pid_status | int | PID 状态 (2=冷启动) |
| item_type | int | rcmd_items 中的商品类型 (3=I2I) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 'ID','MY','PH','SG','TH','TW','VN','BR'
- `grass_date`: `date'YYYY-MM-DD'` 格式, 通常单日分析或 7 天窗口 (`between date'...' and date'...'`)
- `h`: `between ${start_hour} and ${end_hour}`, 常见范围 0-23, 单独分析时用 `h >= 14` 等
- `ads_info.placement IN (2003)` — Shop Ads Search (simple mode)
- `ads_info.placement IN (3, 2003)` — Shop Ads Search (all)
- `ads_info.placement IN (2003, 2030)` — Shop Ads Search + Discovery
- `ads_info.rank = 1` — 只取排名第一的广告 (top 1)
- `ads_info.reason IN (1)` — 只取 PICKED 的广告
- `get_json_object(ext_info, '$.bucket_id') IN ('196475','196476','196477','197054')` — AB bucket 过滤
- `get_json_object(ads_info.ext_info, '$.pid_status') = 2` — 冷启动状态过滤
- `ab_sign`: `regexp_extract(ab_sign, 'pid_bucket=(\\d+)', 1)` 或 `split(ab_sign, '\\|m\\|')` 提取实验分组

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| request_id | string | 请求唯一标识 | - | - |
| session_id | string | 会话 ID | - | - |
| timestamp | int | Unix 时间戳 | - | - |
| ab_sign | string | AB 实验签名 (含 bucket_id, group_id 等) | - | - |
| user_id | bigint | 用户 ID | - | - |
| region | string | 地区 (数据内的 region 字段) | - | - |
| platform | int | 平台类型 | - | - |
| query | string | 原始搜索词 | - | - |
| proc_query | string | 处理后的搜索词 | - | - |
| ads | array\<struct\> | 召回广告列表 (见子结构) | - | - |
| ext_info | string | 请求级扩展信息 (JSON) | - | - |
| grass_region | string | [PARTITION] 地区分区 (ID/MY/PH/SG/TH/TW/VN/BR) | - | - |
| grass_date | date | [PARTITION] 日期分区 | - | - |
| h | int | [PARTITION] 小时分区 (0-23) | - | - |

### ads 数组元素结构 (ads_info)

| Field | Type | Description |
|-------|------|-------------|
| ads_id | string | 广告 ID |
| shop_id | bigint | 店铺 ID |
| bid_price | string | 出价 |
| deduction_price | string | 扣费价 |
| match_type | int | 匹配类型 |
| reason | int | Pick/Unpick 原因 (见枚举映射) |
| placement | int | 广告位 (见枚举映射) |
| bid_keyword | string | 竞价关键词 |
| recall_queue | string | 召回队列名称 |
| rank | int | 排序位置 |
| score | double | 排序分数 |
| top_vouchers | string | 优惠券信息 |
| top_items | array\<struct\<item_id:bigint, ext_info:string\>\> | 顶部推荐商品 |
| rcmd_items | array\<struct\<item_id:bigint, ext_info:string\>\> | 推荐商品列表 |
| top_item_ids | array\<bigint\> | 顶部商品 ID 列表 |
| ext_info | string | 广告级扩展信息 (含 pid_status 等) |
