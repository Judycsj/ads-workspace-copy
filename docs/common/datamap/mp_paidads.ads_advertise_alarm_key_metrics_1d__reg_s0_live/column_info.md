<!-- ads-workspace-gdoc-sync: gdoc_id=13c-EJeVRrA-ySL82FIHdYqgZR6nTVlIcNHiRnRIq3ys gdoc_url=https://docs.google.com/document/d/13c-EJeVRrA-ySL82FIHdYqgZR6nTVlIcNHiRnRIq3ys/edit -->

# Columns: mp_paidads.ads_advertise_alarm_key_metrics_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 shop_id/campaign_id 聚合时不能直接 SUM，必须用 MAX 或 SUM(DISTINCT)：
- `shop_valid_budget_usd_1d` -- 同一 shop 下所有行共享该值，聚合时用 `MAX()` 或 `SUM(DISTINCT ...)`（下游 usage: `max(shop_valid_budget_usd_1d)`, `first(shop_valid_budget_usd_1d)`）
- `campaign_valid_budget_usd_1d` -- 同一 campaign 下所有行共享该值，聚合时用 `MAX()`（下游 usage: `max(campaign_valid_budget_usd_1d)`）
- `shop_ads_rev_usd_1d` -- 由 window function `SUM(ads_rev_usd_1d) OVER(PARTITION BY shop_id)` 计算，同一 shop 各行相同，聚合时用 `AVG()` 或 `MAX()`
- `campaign_ads_rev_usd_1d` -- 由 window function `SUM(ads_rev_usd_1d) OVER(PARTITION BY campaign_id)` 计算，同一 campaign 各行相同，聚合时用 `MAX()`（下游 usage: `max(campaign_ads_rev_usd_1d)`）
- `account_balance_usd` -- 同 campaign 共享，聚合时用 `MAX()`
- `budget_usd` -- 同 campaign 共享，聚合时用 `MAX()`

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0,1,2,5 | Manual (manual bidding) |
| placement | 40 | ROI2 |
| placement | 50 | Simple ROI2 |
| traffic_type | Search | Search ads (mapped to 'search') |
| traffic_type | Daily Discover | Discovery ads (mapped to 'dd') |
| traffic_type | You May Also Like | YMAL (mapped to 'ymal') |
| traffic_type | Post Purchase | Post Purchase (mapped to 'pp') |
| traffic_type | Game | Game ads (mapped to 'game') |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询使用 local timezone)
- `grass_region`: 标准 8 区 ('BR','ID','MY','PH','SG','TH','TW','VN')，部分也包含 'MX','CO','CL'
- `placement`: 40,50 (ROI/SIMPLE_ROI2, 发现广告低预算监控)
- `campaign_valid_budget_usd_1d > 0` (过滤无效 campaign)
- `(is_ads_active = 1 or has_performance = 1)` (上游 ads_advertise_mkt 过滤条件)
- `grass_date` 范围查询: date('${grass_date}'), date_sub(date('${grass_date}'), N) 用于日报/周报对比
- campaign_waste 计算: 过去 14 天 (`grass_date >= date_sub(date('${grass_date}'), 13)`)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | shop_id | - | - |
| seller_name | string | shop name | - | - |
| advertiser_tier | string | advertiser_tier | - | - |
| seller_tier | string | seller_tier | - | - |
| shop_level1_global_be_category | string | 一级全球 BE 类目 | - | - |
| shop_level2_global_be_category | string | 二级全球 BE 类目 | - | - |
| campaign_id | bigint | 广告系列 ID | - | - |
| ads_id | bigint | 广告 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| pricing_type | int | 出价类型 | - | - |
| placement | int | 投放位 (0/1/2/5=Manual, 40=ROI2, 50=Simple ROI2) | - | - |
| main_product_type | string | 主产品类型 | - | - |
| product_type | string | 产品类型 | - | - |
| sub_product_type | string | 子产品类型 | - | - |
| traffic_type | string | 流量类型 (Search/Daily Discover/YMAL/Post Purchase/Game) | - | - |
| entry_point | string | 入口点 | - | - |
| entrance | int | 入口编码 | - | - |
| shop_valid_budget_usd_1d | double | 店铺当日有效预算 USD | - | - |
| shop_ads_rev_usd_1d | double | 店铺当日广告收入 USD | - | - |
| campaign_valid_budget_usd_1d | double | 广告系列当日有效预算 USD | - | - |
| campaign_ads_rev_usd_1d | double | 广告系列当日广告收入 USD | - | - |
| if_campaign_hit | tinyint | campaign 预算是否命中 (0/1, ads_rev/budget>=1) | - | - |
| if_campaign_waste | tinyint | campaign 是否浪费 (0/1, 有花费无订单连续14天) | - | - |
| ads_rev_usd_1d | double | 当日广告收入 USD | - | - |
| ads_impression_1d | bigint | 当日曝光数 | - | - |
| ads_click_1d | bigint | 当日点击数 | - | - |
| direct_order_1d | bigint | 当日直接订单数 | - | - |
| broad_order_1d | bigint | 当日广义订单数 | - | - |
| direct_gmv_usd_1d | double | 当日直接 GMV USD | - | - |
| broad_gmv_usd_1d | double | 当日广义 GMV USD | - | - |
| cps_dedup_click_cnt_1d | bigint | 当日 CPS 去重点击数 (ALTER TABLE 新增) | - | - |
| account_balance_usd | double | 账户余额 USD (ALTER TABLE 新增) | - | - |
| budget_usd | double | 总预算 USD (ALTER TABLE 新增) | - | - |

*Note: Columns with `(ALTER TABLE 新增)` were added after initial table creation via separate ALTER statements. Query frequency and MAX values pending from-di run.*
