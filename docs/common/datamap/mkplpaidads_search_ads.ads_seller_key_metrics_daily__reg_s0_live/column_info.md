<!-- ads-workspace-gdoc-sync: gdoc_id=13bdyPrZFhvYC1B-v7vEELrj9_66dWCC3UN0PM-Ep1P0 gdoc_url=https://docs.google.com/document/d/13bdyPrZFhvYC1B-v7vEELrj9_66dWCC3UN0PM-Ep1P0/edit -->

# Columns: mkplpaidads_search_ads.ads_seller_key_metrics_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段跨 entrance/shop_id 聚合时不能直接 SUM，需使用 MAX/MIN 或保持对应维度：

**MAX 取值（shop级别属性，仅在同 shop 内有效）：**
- `shop_level1_global_be_category`, `shop_level2_global_be_category`
- `under_bidding_tier_1d`, `under_bidding_tier_7d`
- `campaign_order_tier_1d`, `campaign_order_tier_7d`
- `budget_tier`, `hit_valid_budget_tier`, `hit_daily_budget_tier`, `hit_account_balance_tier`
- `pcoc_tier`
- `valid_budget_campaign`, `topup_usd`, `manual_free_credit_topup_amt_1d`, `account_balance_shop`
- `target_roi`, `idx_roi_upperbound`, `final_coef`
- `gmv_after_23pm`, `active_hour`, `is_active_after_20pm`, `daily_budget`
- `shop_adopts_gms`, `shop_gmv_tier`
- `is_rapid_boost_on`, `is_auto_topup_enabled`, `auto_topup_daily_cap_amt_usd`, `auto_topup_amt_usd`, `auto_topup_threshold_amt_usd`
- `is_auto_escrow_enabled`, `auto_escrow_fixed_program_fee_rate`, `auto_escrow_additional_fee_rate`
- `is_auto_budget_increase_enabled`, `auto_budget_increase_percentage`, `auto_budget_increase_daily_cap`
- `is_roi_three_voucher_enabled`, `is_campaign_surge_enabled`
- `max_budget_decrease_magnitude`, `troi_change_direction`, `budget_change_direction`
- `campaign_name`, `item_name`, `shop_name`
- `hot_item_tag`, `potential_item_tag`, `new_item_tag`, `winner_item_tag`, `cheapest_item_tag`

**MIN 取值：**
- `troi_min_by_imp`, `rt_remain_budget_min_by_imp`, `coef_min_by_imp`

**MAX 取值（特殊）：**
- `troi_max_by_imp`, `rt_remain_budget_max_by_imp`, `coef_max_by_imp`

**ad_tag** — 从上游 ad_tag 做 bitwise OR (MAX 后做位运算)，跨 shop 聚合无意义

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pcoc_tier | null | 无数据 |
| pcoc_tier | overpcoc | 7日GMV > 实际GMV x 1.2 |
| pcoc_tier | fulfillmentpcoc | 7日GMV 在实际GMV的 0.8-1.2 之间 |
| pcoc_tier | underpcoc | 7日GMV < 实际GMV x 0.8 |

| Column | Value | Meaning |
|--------|-------|---------|
| entrance (scene) | DD | Daily Discover |
| entrance (scene) | YMAL | You May Also Like |
| entrance (scene) | PP | Cart/Order/Shop Recommendations |
| entrance (scene) | SEARCH | Global Search / Image Search |
| entrance (scene) | GAME | Games / Voucher Master |
| entrance (scene) | LIVESTREAM | Live Streaming |
| entrance (scene) | SHOP | Search Shop |
| entrance (scene) | SHOP_GAME | Shop Game |
| entrance (scene) | IN_SHOP | Shop browsing pages |
| entrance (scene) | VIDEO | Video |
| entrance (scene) | other | Others / null |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 ('ID','PH','SG','TH','TW','MY','VN','BR')
- `grass_date`: `date('${ISO_YESTERDAY}')` 或固定日期如 `date'2025-12-21'`
- `pricing_type != 0` — 排除 pricing_type=0 的数据（union metrics 中使用）
- 分区过滤几乎在所有查询中都会使用

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string | 流量入口/场景 | - | - |
| plan_bucket_id | string | 策略桶ID (shop级为 null) | - | - |
| pricing_type | string | 出价类型 (shop级为 null) | - | - |
| ads_id | bigint | 广告ID (shop级为 null) | - | - |
| campaign_id | bigint | 计划ID (shop级为 null) | - | - |
| item_id | bigint | 商品ID (shop级为 null) | - | - |
| shop_id | bigint | 店铺ID | - | - |
| shop_level1_global_be_category | string | Shop一级类目 (MAX) | - | - |
| shop_level2_global_be_category | string | Shop二级类目 (MAX) | - | - |
| under_bidding_tier_1d | string | 1日低出价分层 (MAX) | - | - |
| under_bidding_tier_7d | string | 7日低出价分层 (MAX) | - | - |
| campaign_order_tier_1d | string | 1日计划订单分层 (MAX) | - | - |
| campaign_order_tier_7d | string | 7日计划订单分层 (MAX) | - | - |
| budget_tier | string | 预算分层 (MAX) | - | - |
| hit_valid_budget_tier | string | 有效预算命中分层 (MAX) | - | - |
| hit_daily_budget_tier | string | 日预算命中分层 (MAX) | - | - |
| hit_account_balance_tier | string | 账户余额命中分层 (MAX) | - | - |
| pcoc_tier | string | PCOC分层 (CASE-WHEN计算) | - | - |
| revenue_usd | double | 广告收入 (USD) | - | - |
| advv_usd | double | 广告花费 (USD) | - | - |
| direct_gmv_usd | double | 直接GMV (USD) | - | - |
| broad_gmv_usd | double | 泛GMV (USD) | - | - |
| noimp_gmv | double | 无曝光GMV | - | - |
| ads_direct_order | int | 广告直接订单数 | - | - |
| ads_broad_order | int | 广告泛订单数 | - | - |
| ads_imp | bigint | 广告曝光数 (SUM) | - | - |
| ads_clk | bigint | 广告点击数 (SUM) | - | - |
| revenue_usd_7d | double | 7日广告收入 (USD) | - | - |
| advv_usd_7d | double | 7日广告花费 (USD) | - | - |
| ads_broad_order_7d | double | 7日泛订单数 | - | - |
| broad_gmv_usd_7d | double | 7日泛GMV (USD) | - | - |
| ads_imp_7d | bigint | 7日广告曝光 | - | - |
| ads_clk_7d | bigint | 7日广告点击 | - | - |
| bid_price_sum | double | 出价总和 | - | - |
| boost_price_sum | double | Boost出价总和 | - | - |
| expect_deduction_price_sum_raw | double | 预期扣费总额(原始) | - | - |
| expect_deduction_price_sum_valid | double | 预期扣费总额(有效) | - | - |
| gross_deduction_price_sum | double | 毛扣费总额 | - | - |
| net_deduction_price_sum | double | 净扣费总额 | - | - |
| raw_deduction_cnt | int | 原始扣费次数 | - | - |
| valid_deduction_cnt | int | 有效扣费次数 | - | - |
| troi_sum_by_imp | double | 按曝光的目标ROI总和 | - | - |
| troi_max_by_imp | double | 按曝光的目标ROI最大值 | - | - |
| troi_min_by_imp | double | 按曝光的目标ROI最小值 | - | - |
| rt_remain_budget_sum_by_imp | double | 实时剩余预算总和 | - | - |
| rt_remain_budget_min_by_imp | double | 实时剩余预算最小值 | - | - |
| rt_remain_budget_max_by_imp | double | 实时剩余预算最大值 | - | - |
| sold_cnt_sum_by_imp | double | 按曝光的销量总和 | - | - |
| item_price_sum_by_imp | double | 按曝光的商品价格总和 | - | - |
| coef_sum_by_imp | double | 按曝光的系数字和 | - | - |
| coef_min_by_imp | double | 按曝光的最小系数 | - | - |
| coef_max_by_imp | double | 按曝光的最大系数 | - | - |
| pctr_sum_by_imp | double | 按曝光的pCTR总和 | - | - |
| pcr_direct_sum_by_imp | double | 按曝光的直接pCVR总和 | - | - |
| pcr_direct_fail_imp_cnt | bigint | pCVR直接预估失败曝光数 | - | - |
| pcr_broad_sum_by_imp | double | 按曝光的泛pCVR总和 | - | - |
| pgmv_direct_sum_by_imp | double | 按曝光的直接pGMV总和 | - | - |
| pgmv_broad_sum_by_imp | double | 按曝光的泛pGMV总和 | - | - |
| final_pgmv_sum_by_imp | double | 按曝光的最终pGMV总和 | - | - |
| padvv_sum_by_imp | double | 按曝光的pADVV总和 | - | - |
| ecpm_sum_by_imp | double | 按曝光的eCPM总和 | - | - |
| pcr_direct_sum_by_clk | double | 按点击的直接pCVR总和 | - | - |
| pcr_broad_sum_by_clk | double | 按点击的泛pCVR总和 | - | - |
| pgmv_direct_sum_by_clk | double | 按点击的直接pGMV总和 | - | - |
| pgmv_broad_sum_by_clk | double | 按点击的泛pGMV总和 | - | - |
| final_pgmv_sum_by_clk | double | 按点击的最终pGMV总和 | - | - |
| padvv_sum_by_clk | double | 按点击的pADVV总和 | - | - |
| ecpc_sum_by_clk | double | 按点击的eCPC总和 | - | - |
| request_cnt | bigint | 请求数 | - | - |
| after_recall_num | bigint | 召回后候选数 | - | - |
| ads_after_recall_num | bigint | 广告召回后候选数 | - | - |
| org_after_recall_num | bigint | 自然召回后候选数 | - | - |
| after_prerank_num | bigint | 粗排后候选数 | - | - |
| after_rank_num | bigint | 精排后候选数 | - | - |
| after_mixrank_num | bigint | 混排后候选数 | - | - |
| daily_advv_sum_last_7d_clk | bigint | 7日按点击ADVV预估总和 (废弃) | - | - |
| daily_pgmv_direct_sum_last_7d_clk | bigint | 7日按点击直接pGMV预估总和 (废弃) | - | - |
| daily_pgmv_broad_sum_last_7d_clk | bigint | 7日按点击泛pGMV预估总和 (废弃) | - | - |
| ads_cnt | int | 运营中广告数 | - | - |
| campaign_cnt | int | 运营中计划数 | - | - |
| shop_cnt | int | 店铺数 (固定为1) | - | - |
| item_cnt | int | 运营中商品数 | - | - |
| valid_budget_campaign | double | 有效预算计划 (MAX) | - | - |
| topup_usd | double | 充值金额 (USD, MAX) | - | - |
| manual_free_credit_topup_amt_1d | double | 手动免费信用充值金额 (MAX) | - | - |
| account_balance_shop | double | 店铺账户余额 (MAX) | - | - |
| ads_imp_cnt | bigint | 广告曝光数(全量) | - | - |
| ads_clk_cnt | bigint | 广告点击数(全量) | - | - |
| ads_order_cnt | bigint | 广告订单数(全量) | - | - |
| ads_gmv_usd | double | 广告GMV(全量, USD) | - | - |
| total_imp | bigint | 全站曝光数 | - | - |
| total_clk | bigint | 全站点击数 | - | - |
| total_order | bigint | 全站订单数 | - | - |
| total_gmv | double | 全站GMV (USD) | - | - |
| target_roi | double | 目标ROI (MAX) | - | - |
| idx_roi_upperbound | double | ROI index上限 (MAX) | - | - |
| ultra_core_rev | double | Ultra Core收入 | - | - |
| ultra_core_advv | double | Ultra Core广告花费 | - | - |
| final_coef | double | 最终系数 (MAX) | - | - |
| mpc_e_gmv | double | MPC预估GMV | - | - |
| mpc_e_cost | double | MPC预估花费 | - | - |
| gmv_after_23pm | double | 23点后GMV (MAX) | - | - |
| active_hour | int | 活跃小时数 (MAX) | - | - |
| is_active_after_20pm | tinyint | 是否20点后活跃 (MAX) | - | - |
| daily_budget | double | 日预算 (MAX) | - | - |
| bid_rerank_trace_null_cnt | bigint | bid_rerank_trace为空次数 | - | - |
| raw_ads_imp | bigint | 原始广告曝光 | - | - |
| raw_ads_clk | bigint | 原始广告点击 | - | - |
| deduct_imp | bigint | 扣费曝光 | - | - |
| deduplicated_click | bigint | 去重点击 | - | - |
| daily_padvv_sum_last_7d_clk | double | 7日按点击pADVV预估总和 | - | - |
| daily_pgmv_sum_last_7d_clk | double | 7日按点击pGMV预估总和 | - | - |
| ad_tag | bigint | 广告标签 (bitwise组合, 位34/50/56/57/61) | - | - |
| tc_imp_count | bigint | TC曝光数 | - | - |
| rt_daily_budget_min_by_imp | double | 实时日预算(按曝光最小值) | - | - |
| daily_pay_pgmv_sum_last_7d_clk | double | 7日按点击付费pGMV预估总和 | - | - |
| paid_broad_gmv_usd | double | 付费泛GMV (USD) | - | - |
| paid_broad_gmv_usd_7d | double | 7日付费泛GMV (USD) | - | - |
| daily_model_pgmv_sum_last_7d_clk | double | 7日按点击模型pGMV预估总和 | - | - |
| ads_paid_order | bigint | 广告付费订单数 | - | - |
| ads_paid_order_7d | bigint | 7日广告付费订单数 | - | - |
| model_broad_gmv_usd | double | 模型泛GMV (USD) | - | - |
| resp_ads_imp | bigint | 响应广告曝光 | - | - |
| total_add_to_cart_cnt | bigint | 全站加购数 | - | - |
| shop_adopts_gms | tinyint | Shop是否启用智能投放 (MAX) | - | - |
| shop_gmv_tier | int | Shop GMV分层 (MAX) | - | - |
| hot_item_tag | tinyint | 热销品标签 (MAX) | - | - |
| potential_item_tag | tinyint | 潜力品标签 (MAX) | - | - |
| new_item_tag | tinyint | 新品标签 (MAX) | - | - |
| winner_item_tag | tinyint | 爆品标签 (MAX) | - | - |
| cheapest_item_tag | tinyint | 最低价品标签 (MAX) | - | - |
| stock | bigint | 库存 (SUM) | - | - |
| is_rapid_boost_on | tinyint | 是否开启快速Boost (MAX) | - | - |
| is_auto_topup_enabled | tinyint | 是否开启自动充值 (MAX) | - | - |
| auto_topup_daily_cap_amt_usd | double | 自动充值每日上限 (MAX) | - | - |
| auto_topup_amt_usd | double | 自动充值金额 (MAX) | - | - |
| auto_topup_threshold_amt_usd | double | 自动充值阈值 (MAX) | - | - |
| is_auto_escrow_enabled | tinyint | 是否开启自动Escrow (MAX) | - | - |
| auto_escrow_fixed_program_fee_rate | double | 自动Escrow固定费率 (MAX) | - | - |
| auto_escrow_additional_fee_rate | double | 自动Escrow附加费率 (MAX) | - | - |
| is_auto_budget_increase_enabled | tinyint | 是否开启自动提预算 (MAX) | - | - |
| auto_budget_increase_percentage | double | 自动提预算比例 (MAX) | - | - |
| auto_budget_increase_daily_cap | double | 自动提预算每日上限 (MAX) | - | - |
| is_roi_three_voucher_enabled | tinyint | 是否开启ROI3券 (MAX) | - | - |
| campaign_pause_cnt | int | 计划暂停次数 | - | - |
| campaign_stop_cnt | int | 计划停止次数 | - | - |
| troi_increase_cnt | int | tROI上调次数 | - | - |
| troi_decrease_cnt | int | tROI下调次数 | - | - |
| troi_mode_switch_cnt | int | tROI模式切换次数 | - | - |
| finite_budget_increase_cnt | int | 有限预算上调次数 | - | - |
| finite_budget_decrease_cnt | int | 有限预算下调次数 | - | - |
| unlimited_budget_on_cnt | int | 无限预算开启次数 | - | - |
| unlimited_budget_off_cnt | int | 无限预算关闭次数 | - | - |
| max_budget_decrease_magnitude | double | 最大预算下调幅度 (MAX) | - | - |
| troi_change_direction | string | tROI变更方向 (shop级为null) | - | - |
| budget_change_direction | string | 预算变更方向 (shop级为null) | - | - |
| is_campaign_surge_enabled | tinyint | 是否开启Campaign Surge (MAX) | - | - |
| campaign_name | string | 计划名称 (MAX) | - | - |
| item_name | string | 商品名称 (MAX) | - | - |
| shop_name | string | 店铺名称 (MAX) | - | - |
| total_seller_gmv_usd | double | 全站Seller GMV (USD, omni维度) | - | - |
| grass_date | date | 日期分区 | - | - |
| grass_region | string | 区域分区 | - | - |
