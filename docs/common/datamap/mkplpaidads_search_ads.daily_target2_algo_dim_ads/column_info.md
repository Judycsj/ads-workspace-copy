<!-- ads-workspace-gdoc-sync: gdoc_id=1zWAjDC9ZVmQHRafxAPDB0fgRnIeoOTS2RcMP57AcKyI gdoc_url=https://docs.google.com/document/d/1zWAjDC9ZVmQHRafxAPDB0fgRnIeoOTS2RcMP57AcKyI/edit -->

# Columns: mkplpaidads_search_ads.daily_target2_algo_dim_ads

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `target_roi` -- ads 级别的 target ROI 设定值，跨 ads 聚合时应使用 AVG 而非 SUM
- `cpa_usd` -- ads 级别的 CPA（Cost Per Action），跨 ads 聚合时应使用 AVG 而非 SUM

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| status_tag | normal | 正常投放 |
| status_tag | cold | 冷启动期 |
| status_tag | empty | 空耗广告 |
| status_tag | npb | NPB 破零期 |
| status_tag | new_advertiser_ads | 新投广 |
| hit_budget_flag | 0 | 未触及预算上限 |
| hit_budget_flag | 1 | 消耗 > 0.9 * 有效预算 |
| budget_tier | Large | 有效预算 >= 3 * CPA |
| budget_tier | Middle | CPA <= 有效预算 < 3 * CPA |
| budget_tier | Small | 有效预算 < CPA |
| budget_tier | no cpa | CPA = 0（无历史 CPA） |
| cost_tier | Large | 消耗 >= 3 * CPA |
| cost_tier | Middle | CPA <= 消耗 < 3 * CPA |
| cost_tier | Small | 消耗 < CPA |
| cost_tier | no cpa | CPA = 0 |
| order_tier | gt3o | 成交单数 >= 3 |
| order_tier | 1-3o | 1 <= 成交单数 < 3 |
| order_tier | lt1o | 消耗 < CPA |
| order_tier | no order | 成交单数 = 0 |
| achive_tag_1d | achive_1d | 1d 达成（0.8 <= advv/cost <= 1.2） |
| achive_tag_1d | over_bid_1d | 1d 超投（advv/cost < 0.8） |
| achive_tag_1d | under_1d | 1d 欠投（advv/cost > 1.2） |
| achive_tag_1d | no_gmv_1d | 1d 无 advv |
| achive_tag_7d | achive_7d | 7d 达成（0.8 <= advv_7d/cost_7d <= 1.2） |
| achive_tag_7d | over_bid_7d | 7d 超投（advv_7d/cost_7d < 0.8） |
| achive_tag_7d | under_7d | 7d 欠投（advv_7d/cost_7d > 1.2） |
| achive_tag_7d | no_gmv_7d | 7d 无 advv |

### 常见 WHERE 值 (Common Filter Values)

- **分区过滤**: `grass_date between date('...') and date('...')` 为日期范围查询；BR 区域日期偏移 -1 天（`date_add('day', -1, date('...'))`）
- **`status_tag`**: `'normal'` (绝大多数查询排除 cold/empty/npb/new_advertiser_ads，只分析正常投放广告)
- **`pricing_type`**: `11` (Target ROI2，核心过滤条件); 偶尔与 `15` (Simple) 组合
- **`placement`**: `40` (搜索广告位)
- **`grass_region`**: `'ID','SG','TH','PH','TW','MY','VN','BR'` 标准八区
- **`plan_id`**: `9910-9919` 范围（plan bucket）；`9911` = base, `9914` = timewindow
- **`budget_tier`**: `!= 'no cpa'` (排除无效 CPA 的广告)
- **`ad_bucket`**: `in (0,1,2,4,5,6)` 分桶过滤

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告 ID（主键） | - | - |
| ad_bucket | integer | 广告分桶 hash（ads_id % 1103 % 10） | - | - |
| plan_id | integer | 计划 ID（一级计划分桶标识） | - | - |
| plan_id_l2 | integer | 二级计划分桶标识（Spark 版本额外列） | - | - |
| item_id | bigint | 商品 ID | - | - |
| campaign_id | bigint | 广告计划 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| placement | bigint | 广告位（40=搜索） | - | - |
| pricing_type | integer | 出价类型（11=Target ROI2） | - | - |
| target_roi | double | 目标 ROI 值 | - | - |
| status_tag | string | 广告状态标签（normal/cold/empty/npb/new_advertiser_ads） | - | - |
| hit_budget_flag | integer | 是否触及预算上限（0/1） | - | - |
| budget_tier | string | 预算分层（Large/Middle/Small/no cpa） | - | - |
| cost_tier | string | 消耗分层（Large/Middle/Small/no cpa） | - | - |
| order_tier | string | 订单分层（gt3o/1-3o/lt1o/no order） | - | - |
| achive_tag_1d | string | 1d 达成标签 | - | - |
| achive_tag_7d | string | 7d 达成标签（Spark 版本额外列） | - | - |
| cpa_usd | double | CPA (USD) | - | - |
| valid_budget_usd | double | 有效预算 (USD) | - | - |
| impression_1d | bigint | 1d 曝光次数 | - | - |
| click_1d | bigint | 1d 点击次数 | - | - |
| cost_usd_1d | double | 1d 消耗 (USD) | - | - |
| advv_usd_1d | double | 1d 广告价值 (USD, advv) | - | - |
| broad_order_1d | bigint | 1d 宽口径成交单数 | - | - |
| broad_gmv_usd_1d | double | 1d 宽口径 GMV (USD) | - | - |
| cost_usd_7d | double | 7d 累计消耗 (USD) | - | - |
| advv_usd_7d | double | 7d 累计广告价值 (USD) | - | - |
| delta_advv | double | 日均超额 advv（(advv_7d - cost_7d)/7 if positive） | - | - |
| delta_cost | double | 日均超额消耗（(cost_7d - advv_7d)/7 if positive） | - | - |
| cost_usd_1d_net | double | 1d 净消耗（min(advv_usd_1d, cost_usd_1d)） | - | - |
| broad_gmv_usd_1d_995 | double | 995 分位数截断的 1d 宽口径 GMV | - | - |
| advv_usd_1d_995 | double | 995 分位数截断的 1d 广告价值 | - | - |
| grass_date | date | 数据日期（分区列） | - | - |
| grass_region | string | 区域（分区列） | - | - |
