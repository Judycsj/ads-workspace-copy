<!-- ads-workspace-gdoc-sync: gdoc_id=1KCJZftQPb5tR4y8DgwwcQ9per4ceFJu5D1qDz-gDRzk gdoc_url=https://docs.google.com/document/d/1KCJZftQPb5tR4y8DgwwcQ9per4ceFJu5D1qDz-gDRzk/edit -->

# Columns: mkplpaidads_search_ads_ads_debug.full_link_diagnose_general_ads_metrics

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 ads_id/campaign_id 聚合时需使用 MAX 或 SUM(DISTINCT)，不可直接 SUM：
- `shop_valid_budget_usd_1d`, `shop_ads_rev_usd_1d` -- 店铺级，同一 shop 下多 ads 共享
- `campaign_valid_budget_usd_1d`, `campaign_ads_rev_usd_1d` -- 推广组级，同一 campaign 下多 ads 共享
- `if_campaign_waste`, `if_campaign_hit` -- campaign 级别标识，跨 ads 需 MAX
- `target_roi` -- 推广组设置，跨 ads 需 MAX
- `active_hour` -- 广告当天活跃小时数，跨 region 不可直接 SUM

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| scene | search | 搜索广告 |
| scene | dd | Daily Discover |
| scene | ymal | You May Also Like |
| scene | pp | Post Purchase |
| scene | game | 游戏场景 |
| product_type | manual | 手动出价 (placement 0,1,2,5) |
| product_type | roi2 | ROI 出价 (placement 40) |
| product_type | simple_roi2 | 简易ROI出价 (placement 50) |
| product_type | roi | 旧ROI类型 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: `'ID','TH','PH','VN','BR','MY','TW','SG'` (标准8区，~100% 查询)
- `grass_date`: `BETWEEN today() - 60 AND today()` (近60天) / `DATE('${1_DAYS_AGO}')` (T+1生产)
- `scene`: `('dd', 'ymal', 'search')` (诊断查询) / `('search', 'dd')` (基础信息)
- `product_type`: `('roi2', 'simple_roi2')` (ROI广告) / `('roi2', 'simple_roi2', 'manual')` (全类型)
- `campaign_valid_budget_usd_1d > 0` (过滤无预算广告)
- `day(grass_date) <> month(grass_date)` (排除大促日 day=month 的异常数据)
- `shop_level2_global_be_category is not null and shop_level2_global_be_category != ''` (品类非空)

## Top 20 Most Queried Columns

<!-- ANALYSIS_PLACEHOLDER -->

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告ID | - | - |
| item_id | bigint | 商品ID | - | - |
| shop_id | bigint | 店铺ID | - | - |
| campaign_id | bigint | 推广组ID | - | - |
| scene | string | 广告场景 (search/dd/ymal/pp/game) | - | - |
| product_type | string | 出价类型 (manual/roi2/simple_roi2) | - | - |
| shop_level1_global_be_category | string | 店铺一级品类 | - | - |
| shop_level2_global_be_category | string | 店铺二级品类 | - | - |
| ad_recall_cnt | bigint | 广告召回候选数 | - | - |
| ad_recall_info_cnt | bigint | 广告召回通过信息过滤数 | - | - |
| ad_recall_prerank_cnt | bigint | 广告召回通过预排序候选数 | - | - |
| recall_num | bigint | 召回总量 | - | - |
| ads_recall_num | bigint | 广告级召回量 | - | - |
| org_recall_num | bigint | 原始召回量 | - | - |
| prerank_num | bigint | 预排序量 | - | - |
| rank_num | bigint | 精排量 | - | - |
| mixrank_num | bigint | 重排量 | - | - |
| dispatch_num | bigint | 下发量 | - | - |
| ads_recall_info_passrate | double | 召回信息过滤通过率 | - | - |
| ads_prerank_passrate | double | 预排序通过率 | - | - |
| prerank_passrate | double | 预排序整体通过率 | - | - |
| rank_passrate | double | 精排通过率 | - | - |
| mixrank_passrate | double | 重排通过率 | - | - |
| dispatch_passrate | double | 下发通过率 | - | - |
| idx_status | string | 索引状态/原因 (reason) | - | - |
| reason_with_cnt | string | 索引原因详情 (含计数) | - | - |
| cnt | bigint | 请求计数 | - | - |
| ads_prerank_score | double | 广告级预排序分 | - | - |
| ads_prerank_pctr | double | 广告级预排序 pCTR | - | - |
| ads_prerank_pcr | double | 广告级预排序 pCVR | - | - |
| ads_prerank_position | double | 广告级预排序位置 | - | - |
| ads_prerank_bidprice | double | 广告级预排序出价 | - | - |
| prerank_score | double | 预排序总分 | - | - |
| prerank_pctr | double | 预排序 pCTR | - | - |
| prerank_pcr | double | 预排序 pCVR | - | - |
| prerank_position | double | 预排序位置 | - | - |
| prerank_bidprice | double | 预排序出价 | - | - |
| rank_pctr | double | 精排 pCTR | - | - |
| rank_pcr | double | 精排 pCVR | - | - |
| rank_broad_pcr | double | 精排 broad pCVR | - | - |
| rank_relevance_score | double | 精排相关性分 | - | - |
| rank_ecpm | double | 精排 eCPM | - | - |
| rank_score | double | 精排总分 | - | - |
| rank_position | double | 精排位置 | - | - |
| rank_bid_price | double | 精排出价 | - | - |
| rank_item_price | double | 精排商品价格 | - | - |
| direct_pcr | double | 直接转化率 (模型特征) | - | - |
| direct_pcr_1d | double | 1天直接转化率 | - | - |
| direct_pgmv_7d | double | 7天直接 GMV | - | - |
| shop_pcr | double | 店铺转化率 | - | - |
| shop_pcr_1d | double | 1天店铺转化率 | - | - |
| shop_pgmv_7d | double | 7天店铺 GMV | - | - |
| broad_pcr_v | double | broad 转化率 v | - | - |
| broad_pgmv_7d | double | 7天 broad GMV | - | - |
| avg_sold_count | double | 平均销量 | - | - |
| pid_coef | double | 商品ID系数 | - | - |
| cold_start_boost | double | 冷启动加成 | - | - |
| target_cir | double | 目标 CIR | - | - |
| target_roi | double | 目标 ROI | - | - |
| padvv | double | 广告价值预测 | - | - |
| mixrank_score | double | 重排总分 | - | - |
| mixrank_pctr | double | 重排 pCTR | - | - |
| mixrank_pcr | double | 重排 pCVR | - | - |
| mixrank_position | double | 重排位置 | - | - |
| mixrank_bid_price | double | 重排出价 | - | - |
| mixrank_estimated_gmv | double | 重排预估 GMV | - | - |
| mixrank_target_roi | double | 重排目标 ROI | - | - |
| deduction_price | double | 扣费价格 | - | - |
| shop_valid_budget_usd_1d | double | 店铺当日有效预算 (USD) | - | - |
| shop_ads_rev_usd_1d | double | 店铺当日广告收入 (USD) | - | - |
| shop_budget_used_ratio | double | 店铺预算使用率 (%) | - | - |
| campaign_valid_budget_usd_1d | double | 推广组当日有效预算 (USD) | - | - |
| campaign_ads_rev_usd_1d | double | 推广组当日广告收入 (USD) | - | - |
| campaign_budget_used_ratio | double | 推广组预算使用率 (%) | - | - |
| if_campaign_waste | int | 推广组是否浪费预算 | - | - |
| if_campaign_hit | int | 推广组是否触达预算上限 | - | - |
| ads_rev_usd_1d | double | 广告当日收入 (USD) | - | - |
| ads_impression_1d | bigint | 广告当日曝光量 | - | - |
| ads_click_1d | bigint | 广告当日点击量 | - | - |
| direct_order_1d | bigint | 直接订单量 | - | - |
| broad_order_1d | bigint | 泛化订单量 | - | - |
| direct_gmv_usd_1d | double | 直接GMV (USD) | - | - |
| broad_gmv_usd_1d | double | 泛化GMV (USD) | - | - |
| ctr | double | 点击率 (ads_click_1d / ads_impression_1d) | - | - |
| cr | double | 转化率 (broad_order_1d / ads_click_1d) | - | - |
| grass_date | date | 数据日期 [PARTITION] | - | - |
| grass_region | string | 地区 [PARTITION] | - | - |
