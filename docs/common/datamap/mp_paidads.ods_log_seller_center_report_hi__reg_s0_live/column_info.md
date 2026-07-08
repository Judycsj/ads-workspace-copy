<!-- ads-workspace-gdoc-sync: gdoc_id=1fOVR9F1HZLyWigMkdzywD2_4NDcIaWopJGZNZHO9CLw gdoc_url=https://docs.google.com/document/d/1fOVR9F1HZLyWigMkdzywD2_4NDcIaWopJGZNZHO9CLw/edit -->

# Columns: mp_paidads.ods_log_seller_center_report_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

当前代码库中所有引用均为 SUM 聚合，未发现 SUM(DISTINCT) 模式。

注意：由于此表是事件级 ODS 日志，每条记录即一个事件，所有指标字段天然可累加。下游聚合表（如 ads_seller_center_*_15min）通过 GROUP BY 维度 SUM 即可。

### 数据源分层

表中的字段来自 4 个不同的数据源，在 SQL 中使用注释进行了标记：

| 数据源 | 来源 | 典型字段 |
|--------|------|----------|
| tracking | 客户端埋点上报 | raw_imp, location_in_ads, cpm, video_view, view, cost_by_cpm, non_fraud_click, dedup_click, raw_click, non_fraud_impression, product_click, view_duration, raw_expense |
| reporting | 服务端上报 | shop_item_impression, shop_item_click, pageview, broad_shop_item_imp, broad_shop_item_click, add_to_cart |
| translog | 结算流水 | click, cost, impression, expected_revenue, expense_* (4种 credit type) |
| order | 订单服务 | order, order_amount, order_gmv, broad_order, broad_item_count, broad_gmv, checkout, daily_order, daily_gmv, paid_* |

### 枚举值映射 (Value Mappings)

从代码库 CASE-WHEN 和 WHERE 条件中提取，需 2+ 文件出现：

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0,3,4 | Search Ads (Query report) |
| placement | 9,45,65 | Brand Ads |
| placement | 33,3327,3328,3337,3338,3339,3342,3348,54 | Live Video Ads |
| pricing_type | 20 | CPS (Cost Per Sale) |
| operation | 1 | click |
| operation | 2 | order (for CPS) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 按区域过滤，标准 `'${region}'` 变量（包括 MY, SG, TH, ID, VN, PH, TW, BR, MX）
- `grass_date`: `DATE('${grass_date}') OR DATE('${today_date}')` — 跨天查询模式（T+1 含当天）
- `grass_date = '${BIZ_YESTERDAY}'` — diff 检查用昨日数据
- `DATE(from_unixtime(event_timestamp, ...)) >= DATE('${grass_date}')` — 时间戳范围过滤
- `group_id IS NOT NULL AND group_id <> 0` — TA Group 报表专用过滤
- `query IS NOT NULL OR LENGTH(query) > 0` — Query 报表专用过滤
- `placement IN (...)` — 各报表按 placement 过滤不同广告位

## All Columns

> DDL 无列定义（schema-inferred from Parquet），以下字段从代码库 SQL 引用中提取。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| event_timestamp | bigint | Unix 事件时间戳 | - | - |
| placement | int | 广告投放位置 ID | - | - |
| pricing_type | int | 计费类型 | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| ads_id | bigint | 广告 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| campaign_id | bigint | 活动 ID | - | - |
| account_id | bigint | 账户 ID | - | - |
| group_id | bigint | TA 分组 ID | - | - |
| new_boost | int | 是否新增推广 | - | - |
| affiliate_id | bigint | 联盟 ID | - | - |
| ls_session_id | bigint | 直播会话 ID | - | - |
| match_type | int | 匹配类型（Search Ads） | - | - |
| keyword | string | 关键词（Search Ads） | - | - |
| query | string | 搜索词（Search Ads） | - | - |
| user_id | bigint | 用户 ID | - | - |
| operation | int | 操作类型（1=click, 2=order） | - | - |
| source | int | 数据来源标识 | - | - |
| sub_source | int | 数据子来源标识 | - | - |
| raw_imp | bigint | 原始展示次数（tracking） | - | - |
| location_in_ads | bigint | 广告位置 | - | - |
| cpm | bigint | 千次展示费用 | - | - |
| video_view | bigint | 视频观看次数 | - | - |
| view | bigint | 视图数 | - | - |
| cost_by_cpm | bigint | 按 CPM 计费费用 | - | - |
| non_fraud_click | bigint | 非欺诈点击数 | - | - |
| dedup_click | bigint | 去重点击数 | - | - |
| raw_click | bigint | 原始点击数 | - | - |
| non_fraud_impression | bigint | 非欺诈展示数 | - | - |
| product_click | bigint | 商品点击数 | - | - |
| view_duration | bigint | 观看时长 | - | - |
| raw_expense | bigint | 原始支出 | - | - |
| shop_item_impression | bigint | 店铺商品展示数（7 天归因） | - | - |
| shop_item_click | bigint | 店铺商品点击数（7 天归因） | - | - |
| pageview | bigint | 店铺页面浏览数 | - | - |
| broad_shop_item_imp | bigint | 广泛归因商品展示 | - | - |
| broad_shop_item_click | bigint | 广泛归因商品点击 | - | - |
| add_to_cart | bigint | 加入购物车次数 | - | - |
| click | bigint | 计费点击数（translog） | - | - |
| cost | bigint | 总费用（translog） | - | - |
| impression | bigint | 计费展示数（translog） | - | - |
| expected_revenue | bigint | 预期收入 | - | - |
| expense_free_credit_with_expiry | bigint | 有过期时间的免费信用额度支出 | - | - |
| expense_free_credit_without_expiry | bigint | 无过期时间的免费信用额度支出 | - | - |
| expense_paid_credit_with_expiry | bigint | 有过期时间的付费信用额度支出 | - | - |
| expense_paid_credit_without_expiry | bigint | 无过期时间的付费信用额度支出 | - | - |
| order | bigint | 订单数 | - | - |
| order_amount | bigint | 订单商品数（item_count） | - | - |
| order_gmv | bigint | 订单 GMV | - | - |
| broad_order | bigint | 广泛归因订单数 | - | - |
| broad_item_count | bigint | 广泛归因商品数 | - | - |
| broad_gmv | bigint | 广泛归因 GMV | - | - |
| checkout | bigint | 结算次数 | - | - |
| daily_order | bigint | 当日订单数 | - | - |
| daily_gmv | bigint | 当日 GMV | - | - |
| paid_broad_gmv | bigint | 付费广泛归因 GMV | - | - |
| paid_order_gmv | bigint | 付费订单 GMV | - | - |
| paid_broad_order | bigint | 付费广泛归因订单数 | - | - |
| paid_order | bigint | 付费订单数 | - | - |
| paid_checkout | bigint | 付费结算次数 | - | - |
| paid_broad_order_amount | bigint | 付费广泛归因订单商品数 | - | - |
| paid_order_amount | bigint | 付费订单商品数 | - | - |
| grass_region | string | 区域分区键 [PARTITION] | - | - |
| grass_date | date | 日期分区键 [PARTITION] | - | - |
| h | int | 小时分区键 [PARTITION] | - | - |
