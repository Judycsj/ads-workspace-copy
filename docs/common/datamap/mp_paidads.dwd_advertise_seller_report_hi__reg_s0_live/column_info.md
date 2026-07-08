<!-- ads-workspace-gdoc-sync: gdoc_id=1TpjJ33Vc7zXi7ntvl-k-ELMoimHWRql1OXRQYMzGNWk gdoc_url=https://docs.google.com/document/d/1TpjJ33Vc7zXi7ntvl-k-ELMoimHWRql1OXRQYMzGNWk/edit -->

# Columns: mp_paidads.dwd_advertise_seller_report_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为明细层（每小时、每个事件一条记录），所有指标字段理论上均可直接 SUM。但需注意：
- `cpm`, `cost_by_cpm` — 仅部分 handler 有值，直接 SUM 可得到总量
- 跨 source 聚合时需明确数据来源含义（同一 placement 可能有多源数据）

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| source | 0 | Tracking |
| source | 1 | Translog |
| source | 3 | Display Tracking |
| source | 4 | Livestream Tracking |
| source | 5 | Reportng |
| sub_source | 0 | Tracking Item |
| sub_source | 1 | Tracking Shop |
| sub_source | 2 | Tracking Video |
| sub_source | 3 | Display Tracking Banner |
| sub_source | 4 | Livestream Tracking |
| handler | tracking-keyword | Keyword ads tracking |
| handler | tracking-targeting | Targeting ads tracking |
| handler | tracking-shop | Shop ads tracking |
| handler | tracking-boost | Boost ads tracking |
| handler | tracking-display | Display ads tracking |
| handler | tracking-livestream | Livestream tracking |
| handler | tracking-roi2 | ROI2 tracking |
| handler | tracking-shop_cpm | Shop CPM tracking |
| handler | tracking-video | Video ads tracking |
| handler | display_tracking-keyword | Display tracking keyword |
| handler | display_tracking-targeting | Display tracking targeting |
| handler | display_tracking-shop | Display tracking shop |
| handler | display_tracking-boost | Display tracking boost |
| handler | display_tracking-display | Display tracking display |
| handler | display_tracking-shop_cpm | Display tracking shop_cpm |
| handler | display_tracking-banner | Display tracking banner |
| handler | livestream_tracking-* | Livestream tracking by handler |
| handler | translog-keyword | Translog keyword |
| handler | translog-targeting | Translog targeting |
| handler | translog-shop | Translog shop |
| handler | translog-boost | Translog boost |
| handler | translog-display | Translog display |
| handler | translog-livestream | Translog livestream |
| handler | translog-roi2 | Translog ROI2 |
| handler | translog-shop_cpm | Translog shop CPM |
| handler | translog-video | Translog video |
| handler | translog-banner | Translog banner |
| handler | reportng | Reportng source |
| operation | 1 | Impression |
| operation | 2 | Click |
| operation | 11 | CPM impression (translog) |
| operation | 13 | View |
| operation | 14 | Product click |
| operation | 15 | Watch duration (translog) |
| operation | 21 | Video view |
| operation | 22 | Video view duration |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'SG','MY','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR' (total 12 regions)
- `h`: 0-23 (hourly partition)
- `source`: 0 (tracking, for click/imp events), 1 (translog, for cost/revenue), 5 (reportng, for order/GMV)
- `handler`: for tracking source, format 'tracking-{type}'; for translog source, format 'translog-{type}'

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| source | INT | 数据来源: 0=tracking, 1=translog, 3=display_tracking, 4=livestream_tracking, 5=reportng | - | - |
| sub_source | INT | 子来源: 0=item, 1=shop, 2=video, 3=banner, 4=livestream | - | - |
| operation | INT | 操作类型: 1=impression, 2=click, 11=cpm imp, 13=view, 14=product_click, 15=duration, 21=video_view, 22=video_duration, 1001=shop_imp, 1002=shop_click | - | - |
| entrance | INT | 入口ID | - | - |
| placement | INT | 广告位ID | - | - |
| pricing_type | INT | 出价类型 | - | - |
| user_id | BIGINT | 用户ID | - | - |
| ads_id | BIGINT | 广告ID | - | - |
| item_id | BIGINT | 商品ID | - | - |
| campaign_id | BIGINT | 广告活动ID | - | - |
| shop_id | BIGINT | 店铺ID | - | - |
| account_id | BIGINT | 账户ID | - | - |
| affiliate_id | BIGINT | 联盟用户ID | - | - |
| group_id | BIGINT | TA分组ID | - | - |
| keyword | STRING | 关键词 | - | - |
| match_type | INT | 匹配类型 | - | - |
| region | STRING | 地区（原始值，非分区列） | - | - |
| event_timestamp | BIGINT | 事件时间戳 | - | - |
| raw_click | INT | 原始点击数 | - | - |
| raw_imp | INT | 原始曝光数 | - | - |
| location_in_ads | BIGINT | 广告内位置 | - | - |
| non_fraud_click | INT | 非作弊点击数 | - | - |
| cpm | DOUBLE | CPM 出价 (unit: 1/100000) | - | - |
| cost_by_cpm | DOUBLE | CPM单次成本 = cpm / 1000 | - | - |
| shop_item_impression | BIGINT | 店铺商品曝光数 (reportng) | - | - |
| shop_item_click | BIGINT | 店铺商品点击数 (reportng) | - | - |
| view | INT | 浏览数 (operation=13) | - | - |
| video_view | INT | 视频浏览数 (operation=21) | - | - |
| pageview | BIGINT | 页面浏览数 (reportng) | - | - |
| click | INT | OCPM去重点击 (translog/tracking) | - | - |
| cost | BIGINT | 总消耗 = sum of 4 credit types (translog) | - | - |
| order | BIGINT | 订单数 (reportng) | - | - |
| order_amount | BIGINT | 订单金额 (reportng) | - | - |
| order_gmv | BIGINT | 订单GMV (reportng) | - | - |
| broad_order | BIGINT | 泛订单数 (reportng) | - | - |
| broad_item_count | BIGINT | 泛商品数 (reportng) | - | - |
| broad_gmv | BIGINT | 泛GMV (reportng) | - | - |
| checkout | BIGINT | 结账数 (reportng) | - | - |
| dedup_click | INT | 去重点击 (tracking) | - | - |
| query | STRING | 搜索query | - | - |
| new_boost | INT | 新Boost标识 (1=新boost) | - | - |
| ls_session_id | BIGINT | 直播场次ID | - | - |
| non_fraud_impression | INT | 非作弊曝光数 | - | - |
| view_duration | BIGINT | 观看时长 (ms) | - | - |
| product_click | INT | 商品点击 (operation=14) | - | - |
| raw_expense | DOUBLE | 原始消耗 (deduction_price 或 cpm/1000) | - | - |
| impression | INT | 曝数 (translog: SIZE(imp_cost_details)) | - | - |
| expected_revenue | BIGINT | 预期收入 (translog: dai_after - dai_before) | - | - |
| expense_paid_credit_without_expiry | BIGINT | 付费不过期信用金支出 | - | - |
| expense_paid_credit_with_expiry | BIGINT | 付费过期信用金支出 | - | - |
| expense_free_credit_without_expiry | BIGINT | 免费不过期信用金支出 | - | - |
| expense_free_credit_with_expiry | BIGINT | 免费过期信用金支出 | - | - |
| daily_order | BIGINT | 日订单 (reportng) | - | - |
| daily_gmv | BIGINT | 日GMV (reportng) | - | - |
| broad_shop_item_imp | BIGINT | 泛店铺商品曝光 (reportng) | - | - |
| broad_shop_item_click | BIGINT | 泛店铺商品点击 (reportng) | - | - |
| add_to_cart | BIGINT | 加购数 (reportng) | - | - |
| paid_order_gmv | BIGINT | 已支付订单GMV (reportng) | - | - |
| paid_broad_gmv | BIGINT | 已支付泛GMV (reportng) | - | - |
| paid_broad_order | BIGINT | 已支付泛订单 (reportng) | - | - |
| paid_order | BIGINT | 已支付订单 (reportng) | - | - |
| paid_checkout | BIGINT | 已支付结账 (reportng) | - | - |
| paid_broad_order_amount | BIGINT | 已支付泛订单金额 (reportng) | - | - |
| paid_order_amount | BIGINT | 已支付订单金额 (reportng) | - | - |
| handler | STRING | 数据源-类型复合标识 (e.g. 'tracking-keyword', 'translog-roi2') | - | - |
| grass_region | STRING | 地区分区列 | - | - |
| grass_date | DATE | 日期分区列 | - | - |
| h | BIGINT | 小时分区列 (0-23) | - | - |
