<!-- ads-workspace-gdoc-sync: gdoc_id=1F_E-0HwzJagxhFD8R2Uh9ManPwEOFTS8NyCk1Grb0sc gdoc_url=https://docs.google.com/document/d/1F_E-0HwzJagxhFD8R2Uh9ManPwEOFTS8NyCk1Grb0sc/edit -->

# Columns: mp_paidads.dwd_advertise_seller_report_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

*未在代码库中发现 SUM(DISTINCT) 模式，所有指标字段均为 SUM() 可累加。*

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0,3,4 | Search / Query Ads |
| placement | 9,45,65 | Brand Ads |
| placement | 33,3327,3328,3337,3338,3339,3342,3348,54 | Live / Video Ads |
| tz_type | local | All references use local timezone |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 11 个标准区域 ('ID','TH','VN','SG','MY','PH','TW','MX','CO','CL','BR')
- `tas_type`: 'local' (所有下游任务均以此读取)
- `placement`: 按广告类型过滤 (见枚举映射)
- `grass_date`: 按 `DATE('${grass_date}')` 参数化过滤，跨天场景使用 `OR DATE('${today_date}')`
- `event_timestamp`: 额外的时间戳范围过滤确保精确

## All Columns

*列名和类型从代码库 SQL 使用推断，未在代码库中找到 DDL。标注 "bigint" 的指标字段可能实际为 double/bigint。Description 和 Query 频率待 from-di 补充。*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| event_timestamp | bigint | 事件发生时间戳 (Unix seconds) | - | - |
| placement | int | 广告投放位置 ID | - | - |
| pricing_type | int | 计费类型 | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| ads_id | bigint | 广告 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| campaign_id | bigint | 活动 ID | - | - |
| account_id | bigint | 账户 ID (Live/Video Ads 场景) | - | - |
| group_id | bigint | TA Group ID (关键词广告分组) | - | - |
| new_boost | int | 是否为新增推广 | - | - |
| affiliate_id | bigint | 联盟/达人 ID (Live Ads 场景) | - | - |
| ls_session_id | bigint | 直播会话 ID (Live Ads 场景) | - | - |
| match_type | int | 关键词匹配类型 | - | - |
| keyword | string | 关键词 | - | - |
| query | string | 搜索词 | - | - |
| source | string/bigint | 数据来源标识 | - | - |
| sub_source | string/bigint | 数据子来源标识 | - | - |
| handler | string | 处理器标识 | - | - |
| user_id | bigint | 用户 ID (用于 bitmap 去重) | - | - |
| raw_imp | bigint | 原始展示数 (Tracking) | - | - |
| raw_click | bigint | 原始点击数 (Tracking) | - | - |
| non_fraud_click | bigint | 非欺诈点击数 (Tracking) | - | - |
| non_fraud_impression | bigint | 非欺诈展示数 (Tracking) | - | - |
| dedup_click | bigint | 去重点击数 (Tracking) | - | - |
| product_click | bigint | 商品点击数 (Tracking) | - | - |
| video_view | bigint | 视频观看次数 (Tracking) | - | - |
| view | bigint | 视图数 (Tracking) | - | - |
| view_duration | bigint | 观看时长 (Tracking) | - | - |
| cpm | bigint | 千次展示费用 (Tracking) | - | - |
| cost_by_cpm | bigint | 按 CPM 计费的费用 (Tracking) | - | - |
| location_in_ads | bigint | 广告位置 (Tracking) | - | - |
| raw_expense | bigint | 原始支出 (Tracking) | - | - |
| shop_item_impression | bigint | 店铺商品展示数 7 天归因 (Reporting) | - | - |
| shop_item_click | bigint | 店铺商品点击数 (Reporting) | - | - |
| pageview | bigint | 店内页面浏览数 (Reporting) | - | - |
| broad_shop_item_imp | bigint | 广泛归因店铺商品展示数 (Reporting) | - | - |
| broad_shop_item_click | bigint | 广泛归因店铺商品点击数 (Reporting) | - | - |
| add_to_cart | bigint | 加入购物车次数 (Reporting) | - | - |
| click | bigint | 计费点击数 (Translog) | - | - |
| cost | bigint | 总费用 (Translog) | - | - |
| impression | bigint | 计费展示数 (Translog) | - | - |
| deduct_order | bigint | 扣费订单数 (Translog) | - | - |
| expected_revenue | bigint | 预期收入 (Translog) | - | - |
| expense_free_credit_with_expiry | bigint | 有过期时间的免费信用额度支出 (Translog) | - | - |
| expense_free_credit_without_expiry | bigint | 无过期时间的免费信用额度支出 (Translog) | - | - |
| expense_paid_credit_with_expiry | bigint | 有过期时间的付费信用额度支出 (Translog) | - | - |
| expense_paid_credit_without_expiry | bigint | 无过期时间的付费信用额度支出 (Translog) | - | - |
| `order` | bigint | 订单数 (Order) | - | - |
| order_amount | bigint | 订单商品数 (Order) | - | - |
| order_gmv | bigint | 订单 GMV (Order) | - | - |
| broad_order | bigint | 广泛归因订单数 (Order) | - | - |
| broad_item_count | bigint | 广泛归因商品数 (Order) | - | - |
| broad_gmv | bigint | 广泛归因 GMV (Order) | - | - |
| checkout | bigint | 结算次数 (Order) | - | - |
| daily_order | bigint | 当日订单数 (Order) | - | - |
| daily_gmv | bigint | 当日 GMV (Order) | - | - |
| paid_broad_gmv | bigint | 已支付广泛归因 GMV (Order) | - | - |
| paid_order_gmv | bigint | 已支付订单 GMV (Order) | - | - |
| paid_broad_order | bigint | 已支付广泛归因订单数 (Order) | - | - |
| paid_order | bigint | 已支付订单数 (Order) | - | - |
| paid_checkout | bigint | 已支付结算次数 (Order) | - | - |
| paid_broad_order_amount | bigint | 已支付广泛归因订单商品数 (Order) | - | - |
| paid_order_amount | bigint | 已支付订单商品数 (Order) | - | - |
| tz_type [PARTITION] | string | 时区类型，所有下游仅使用 'local' | - | - |
| grass_region [PARTITION] | string | 地区 (ID/TH/VN/SG/MY/PH/TW/MX/CO/CL/BR) | - | - |
| grass_date [PARTITION] | date | 数据日期 | - | - |
