<!-- ads-workspace-gdoc-sync: gdoc_id=1PxuEId-E5HPgPvkOXNgMR51pKtsmERfmFGC5uBWyr2I gdoc_url=https://docs.google.com/document/d/1PxuEId-E5HPgPvkOXNgMR51pKtsmERfmFGC5uBWyr2I/edit -->

# Columns: mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为 ODS 层原始事件日志表，每行代表一次广告事件（曝光/点击/扣费等），
所有指标字段（impression, click, cost, order, gmv 等）均为事件层级可直接 SUM 聚合。

### 枚举值映射 (Value Mappings)

**placement 枚举**（从代码注释和 WHERE 条件提取）:

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 33, 3327, 3328, 3337, 3338, 3339, 3342, 3348 | Live Ads CPM placements |
| placement | 40, 50 | ROI2 / Live Stream placements |
| placement | 0, 1, 2, 5 | Targeting (CPC) |
| placement | 3, 20, 2003, 2030 | Shop Ads (CPC) |
| placement | 4 | Keyword Ads (CPC) |
| placement | 10, 1000, 1001, 1002, 1005, 12, 1200, 1201, 1202, 1205 | Boost Ads (CPC) |
| placement | 44, 4400, 4401, 4402, 4405 | New Product Boost |
| placement | 7, 45, 46 | Shop CPM |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 11 区 ('ID','TH','VN','SG','TW','MY','PH','BR','MX','CO','CL')
- `grass_date`: 通常指定单日或日期范围
- `h`: 小时分区，范围 0-23
- `placement in (3327, 3328, 33, 3337, 3338, 3339, 3342, 3348)`: Live Ads CPM 专用
- `placement not in (3327, 3328, 33, 3337, 3338, 3339, 3342, 3348)`: 排除 Live Ads CPM（用于非直播广告查询）
- `deduct_impression is null`: 非 CPM 扣费曝光（report_ng 数据）
- `deduct_impression > 0`: CPM 扣费曝光
- `click = 1 / click is null / click > 0`: 区分点击事件
- `view > 0` / `checkout > 0` / `cost > 0` / `order > 0`: 过滤有效事件
- `timestamp` 区间: 按 region 时区转换过滤（如 `timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'YYYY-MM-DD', 'Asia/Jakarta'), 'Asia/Singapore'))`）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | - | - | - |
| item_id | bigint | - | - | - |
| shop_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| account_id | bigint | - | - | - |
| ls_session_id | bigint | - | - | - |
| campaign_id | bigint | - | - | - |
| entry_point | int | - | - | - |
| entrance | int | - | - | - |
| placement | int | - | - | - |
| country | string | - | - | - |
| timestamp | bigint | - | - | - |
| keyword | string | - | - | - |
| query | string | - | - | - |
| match_type | int | - | - | - |
| order_id | bigint | - | - | - |
| model_id | bigint | - | - | - |
| request_id | string | - | - | - |
| bundle | boolean | - | - | - |
| signature | string | - | - | - |
| bid_type | int | - | - | - |
| location | int | - | - | - |
| slot_id | int | - | - | - |
| app_ver | string | - | - | - |
| platform | int | - | - | - |
| cod | boolean | - | - | - |
| click_timestamp | bigint | - | - | - |
| paid_order | int | - | - | - |
| confirmed_order | int | - | - | - |
| paid_timestamp | int | - | - | - |
| confirmed_timestamp | int | - | - | - |
| buyer_segments | array<struct<segment_type_id:int,info:array<struct<segment_value_id:string>>>> | - | - | - |
| buyer_segments_string | string | - | - | - |
| pricing_type | int | - | - | - |
| date | int | - | - | - |
| click | bigint | - | - | - |
| raw_click | bigint | - | - | - |
| impression | bigint | - | - | - |
| add_to_cart | bigint | - | - | - |
| location_in_ads | bigint | - | - | - |
| order | bigint | - | - | - |
| daily_order | bigint | - | - | - |
| order_amount | bigint | - | - | - |
| order_gmv | bigint | - | - | - |
| cost | bigint | - | - | - |
| raw_expense | bigint | - | - | - |
| daily_order_amount | bigint | - | - | - |
| broad_order | bigint | - | - | - |
| broad_item_count | bigint | - | - | - |
| broad_gmv | bigint | - | - | - |
| shop_item_click | bigint | - | - | - |
| broad_shop_item_click | bigint | - | - | - |
| shop_item_impression | bigint | - | - | - |
| broad_shop_item_imp | bigint | - | - | - |
| expense_free_credit_with_expiry | bigint | - | - | - |
| expense_free_credit_without_expiry | bigint | - | - | - |
| expense_paid_credit_with_expiry | bigint | - | - | - |
| expense_paid_credit_without_expiry | bigint | - | - | - |
| checkout | bigint | - | - | - |
| click_area | int | - | - | - |
| daily_gmv | bigint | - | - | - |
| cost_by_cpm | bigint | - | - | - |
| cpm | bigint | - | - | - |
| non_fraud_click | bigint | - | - | - |
| broad_add_to_cart | bigint | - | - | - |
| add_to_cart_without_click | bigint | - | - | - |
| pcr | double | - | - | - |
| pctr | double | - | - | - |
| rank_bid | double | - | - | - |
| pvr_boost | double | - | - | - |
| match_boost | double | - | - | - |
| rank_score | double | - | - | - |
| organic_value | double | - | - | - |
| broad_match_value | double | - | - | - |
| lite_pctr | double | - | - | - |
| lite_pcr | double | - | - | - |
| raw_request_id | string | - | - | - |
| origin_bid_price | double | - | - | - |
| creative_id | bigint | - | - | - |
| image_id | string | - | - | - |
| video_id | string | - | - | - |
| global_cat_ids | array<int> | - | - | - |
| creative_algo | int | - | - | - |
| target_cir | double | - | - | - |
| imp_user_id | bigint | - | - | - |
| pageview_user_id | bigint | - | - | - |
| sub_entrance | bigint | - | - | - |
| pageview | bigint | - | - | - |
| view | bigint | - | - | - |
| view_duration | bigint | - | - | - |
| product_click | bigint | - | - | - |
| deduct_impression | bigint | - | - | - |
| non_fraud_impression | bigint | - | - | - |
| report_id | string | - | - | - |
| origin_ids | struct<item_id:bigint,index:int,order_item_item_id:bigint,order_item_snapshot_id:bigint,order_item_group_id:bigint> | - | - | - |
| grass_region | string | [PARTITION] - | - | - |
| grass_date | date | [PARTITION] - | - | - |
| h | int | [PARTITION] - | - | - |
