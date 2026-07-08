<!-- ads-workspace-gdoc-sync: gdoc_id=1Hqp1ppLxcPdssnunbtwK6pg7vWExDOwR2Vz3qu28Ixk gdoc_url=https://docs.google.com/document/d/1Hqp1ppLxcPdssnunbtwK6pg7vWExDOwR2Vz3qu28Ixk/edit -->

# Columns: mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

Account-level fields are duplicated across campaign rows for the same shop_id. When aggregating to shop level, use MAX instead of SUM:
- `account_balance_usd` -- same value for all campaigns of the same shop, use MAX
- `account_balance_last1d_usd` -- same value for all campaigns of the same shop, use MAX
- `account_valid_budget_usd` -- same value for all campaigns of the same shop, use MAX
- `account_expenditure_usd` -- same value for all campaigns of the same shop, use MAX
- `is_auto_topup_enabled` -- same value for all campaigns of the same shop, use MAX
- `topup_amt_usd` -- same value for all campaigns of the same shop, use MAX
- `expired_amt_usd` -- same value for all campaigns of the same shop, use MAX

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'local'` (~95% of queries) -- almost all analysis uses local timezone
- `budget_usd`: `!= 9999999999` -- filters out unlimited budget campaigns (9999999999 = no limit)
- `campaign_status`: `= 1` -- active campaigns only
- `has_ads_active`: `= 1` -- campaigns with active ads
- `pricing_type`: `IN (9, 10, 14)` (Live Ads) / `IN (11, 15)` (ROI2 + Simple) / `= 11` (ROI2 only)
- `main_product_type`: `NOT IN ('Shop Ads', 'Live Ads', 'Video Ads', 'Brand Ads')` -- budget supply analysis excludes these
- `grass_region`: Standard 8+1 regions: `'ID','MY','PH','SG','TH','TW','VN','BR'` (MX added for US)

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | - [PARTITION] | 5996/11018/21826 |  |
| 2 | grass_region | string | - [PARTITION] | 5996/11018/21825 |  |
| 3 | campaign_valid_budget_usd | double | calculated valid budget on campaign level. calculate logic see PRD: https://confluence.shopee.io/pages/viewpage.action?pageId=2210788142 | 5280/9631/18816 | 16639.652321233796 |
| 4 | campaign_id | bigint | - | 4171/7886/15783 | 53445488 |
| 5 | tz_type | string | - [PARTITION] | 4595/7864/15344 |  |
| 6 | shop_id | bigint | - | 2976/5393/10210 | 1786944860 |
| 7 | ads_expenditure_usd | double | sum expenditure on campaign level | 2523/4614/8875 | 1127.5618429899146 |
| 8 | budget_usd | double | campaign daily budget ( USD currency) more details see: Calculation Logic | 2261/4122/8515 | 9999999999 |
| 9 | pricing_type | int | - | 2408/4082/6961 | 27 |
| 10 | campaign_strategy_valid_budget_usd | double | only for live ads, takes from quota_split.daily_available_quota. more details see: see PRD: https://confluence.shopee.io/pages/viewpage.action?pageId=2210788142 | 889/1884/3743 | 9592.770970994978 |
| 11 | account_balance_usd | double | The account balance at the end of day | 1095/1945/3405 | 386504.04526003555 |
| 12 | main_product_type | string | - | 356/822/2148 | Video Ads |
| 13 | account_expenditure_usd | double | sum expenditure on advertiser account level | 717/1121/1751 | 10007.374886296222 |
| 14 | account_valid_budget_usd | double | calculated valid budget on advertiser account level | 409/883/1719 | 39228.113450662444 |
| 15 | product_type | string | - | 229/505/1634 | Video Ads |
| 16 | campaign_status | tinyint | campaign status, details see `Enumeration` | 174/338/1155 | 3 |
| 17 | sub_product_type | string | - | 130/289/1143 | video_roi2.0 |
| 18 | seller_tier | string | - | 121/246/599 | small_seller |
| 19 | is_auto_topup_enabled | tinyint | takes from mp_paidads.dim_advertiser__reg_s0_live | 112/180/330 | 1 |
| 20 | shop_level0_global_be_category | string | - | 65/130/308 | Other |

### 查询频率分析

Top 20 高频查询字段呈现以下主题分布：

1. **分区键**（3 个）：`grass_date`、`grass_region`、`tz_type` 查询量最高（L30D 15K-22K），几乎所有查询都需要按日期、地区和时区过滤。
2. **预算与花费**（6 个）：`campaign_valid_budget_usd`（18.8K）、`budget_usd`（8.5K）、`ads_expenditure_usd`（8.9K）、`campaign_strategy_valid_budget_usd`（3.7K）、`account_balance_usd`（3.4K）、`account_valid_budget_usd`（1.7K）-- 预算有效性计算是本表核心用途。
3. **主键与关联键**（3 个）：`campaign_id`（15.8K）、`shop_id`（10.2K）、`pricing_type`（7.0K）-- 用于 JOIN 和分组聚合。
4. **广告产品类型**（3 个）：`main_product_type`（2.1K）、`product_type`（1.6K）、`sub_product_type`（1.1K）-- 按广告产品维度分析预算。
5. **卖家与广告主属性**（4 个）：`campaign_status`（1.2K）、`seller_tier`（599）、`is_auto_topup_enabled`（330）、`shop_level0_global_be_category`（308）-- 辅助维度筛选。
6. **账户级花费**（1 个）：`account_expenditure_usd`（1.8K）-- 用于账户级预算利用率计算。

> MAX(column): MAX() aggregated values from grass_date=2026-03-29, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| campaign_id | bigint | - | 4171/7886/15783 | 53445488 |
| campaign_status | tinyint | campaign status, details see `Enumeration` | 174/338/1155 | 3 |
| shop_id | bigint | - | 2976/5393/10210 | 1786944860 |
| is_auto_topup_enabled | tinyint | takes from mp_paidads.dim_advertiser__reg_s0_live | 112/180/330 | 1 |
| has_ads_active | tinyint | has ads active in the campaign | 30/78/207 | 1 |
| budget_usd | double | campaign daily budget ( USD currency) more details see: Calculation Logic | 2261/4122/8515 | 9999999999 |
| ads_expenditure_usd | double | sum expenditure on campaign level | 2523/4614/8875 | 1127.5618429899146 |
| expired_amt_usd | double | The account expired credit amount for the day. | 2/3/31 | 6327.862368900001 |
| topup_amt_usd | double | The account topup amount for the day. | 2/4/32 | 7909.8279621 |
| account_balance_usd | double | The account balance at the end of day | 1095/1945/3405 | 386504.04526003555 |
| account_balance_last1d_usd | double | The account balance at the end of the previous day | 9/19/63 | 396814.36469052796 |
| account_expenditure_usd | double | sum expenditure on advertiser account level | 717/1121/1751 | 10007.374886296222 |
| campaign_valid_budget_usd | double | calculated valid budget on campaign level. calculate logic see PRD: https://confluence.shopee.io/pages/viewpage.action?pageId=2210788142 | 5280/9631/18816 | 16639.652321233796 |
| account_valid_budget_usd | double | calculated valid budget on advertiser account level | 409/883/1719 | 39228.113450662444 |
| campaign_start_datetime | string | campaign_start_datetime | 10/37/91 | 2026-03-31 00:00:00 |
| campaign_end_datetime | string | campaign_end_datetime | 2/3/31 | 2035-10-31 23:59:59 |
| campaign_total_budget_usd | double | campaign total budget ( USD currency) 0 means 'no limit' | 34/70/231 | 2372.9483884 |
| campaign_strategy_valid_budget_usd | double | only for live ads, takes from quota_split.daily_available_quota. more details see: see PRD: https://confluence.shopee.io/pages/viewpage.action?pageId=2210788142 | 889/1884/3743 | 9592.770970994978 |
| pricing_type | int | - | 2408/4082/6961 | 27 |
| is_cb_seller | tinyint | if this seller is a cross board seller | 2/4/32 | 1 |
| seller_type | string | - | 2/4/32 | VNCB |
| seller_type_1p | string | - | 2/3/31 | Unknown |
| is_cb_sip_affiliated | tinyint | - | 2/3/31 | 1 |
| is_local_sip_affiliated | tinyint | - | 2/3/31 | 1 |
| main_product_type | string | - | 356/822/2148 | Video Ads |
| product_type | string | - | 229/505/1634 | Video Ads |
| sub_product_type | string | - | 130/289/1143 | video_roi2.0 |
| seller_tier | string | - | 121/246/599 | small_seller |
| advertiser_tier | string | - | 65/130/302 | small_advertiser |
| shop_level1_global_be_category | string | - | 65/130/302 | Women Shoes |
| shop_level0_global_be_category | string | - | 65/130/308 | Other |
| tz_type | string | - [PARTITION] | 4595/7864/15344 |  |
| grass_region | string | - [PARTITION] | 5996/11018/21825 |  |
| grass_date | date | - [PARTITION] | 5996/11018/21826 |  |
