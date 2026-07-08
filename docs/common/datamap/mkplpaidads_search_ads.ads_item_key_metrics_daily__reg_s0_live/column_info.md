<!-- ads-workspace-gdoc-sync: gdoc_id=1sEKEnZhpJTK_P8TcNYAc_Yr08Au5-SqwSpfr1SZ5ND4 gdoc_url=https://docs.google.com/document/d/1sEKEnZhpJTK_P8TcNYAc_Yr08Au5-SqwSpfr1SZ5ND4/edit -->

# Columns: mkplpaidads_search_ads.ads_item_key_metrics_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

从 GROUP BY item_id 聚合逻辑识别 --- 这些字段使用 MAX/MIN/COALESCE 而非 SUM:

- `shop_id`, `shop_level1_global_be_category`, `shop_level2_global_be_category` (MAX, 同一 item 取主导 shop)
- `under_bidding_tier_1d`, `under_bidding_tier_7d` (MAX, 枚举tier)
- `campaign_order_tier_1d`, `campaign_order_tier_7d` (MAX, 枚举tier)
- `budget_tier`, `hit_valid_budget_tier`, `hit_daily_budget_tier`, `hit_account_balance_tier` (MAX)
- `target_roi`, `idx_roi_upperbound` (MAX)
- `valid_budget_campaign`, `topup_usd`, `manual_free_credit_topup_amt_1d`, `account_balance_shop` (MAX)
- `daily_budget` (MAX)
- `final_coef` (MAX)
- `gmv_after_23pm`, `active_hour`, `is_active_after_20pm` (MAX)
- `troi_max_by_imp`, `troi_min_by_imp` (MAX/MIN)
- `rt_remain_budget_min_by_imp`, `rt_remain_budget_max_by_imp` (MIN/MAX)
- `rt_daily_budget_min_by_imp` (MIN)
- `coef_min_by_imp`, `coef_max_by_imp` (MIN/MAX)
- `sold_cnt_sum_by_imp`, `item_price_sum_by_imp` (SUM, imp级)
- `shop_adopts_gms`, `shop_gmv_tier`, `hot_item_tag`, `potential_item_tag`, `new_item_tag`, `winner_item_tag`, `cheapest_item_tag` (MAX/COALESCE, 商品级标签)
- `stock` (MAX/COALESCE, 商品级库存)
- `is_rapid_boost_on`, `is_auto_topup_enabled`, `is_auto_escrow_enabled`, `is_auto_budget_increase_enabled`, `is_roi_three_voucher_enabled`, `is_campaign_surge_enabled` (MAX, 商品级开关)
- `auto_topup_daily_cap_amt_usd`, `auto_topup_amt_usd`, `auto_topup_threshold_amt_usd` (MAX)
- `auto_escrow_fixed_program_fee_rate`, `auto_escrow_additional_fee_rate` (MAX)
- `auto_budget_increase_percentage`, `auto_budget_increase_daily_cap` (MAX)
- `campaign_pause_cnt`, `campaign_stop_cnt`, `troi_increase_cnt`, `troi_decrease_cnt`, `troi_mode_switch_cnt` (MAX)
- `finite_budget_increase_cnt`, `finite_budget_decrease_cnt`, `unlimited_budget_on_cnt`, `unlimited_budget_off_cnt` (MAX)
- `max_budget_decrease_magnitude`, `troi_change_direction`, `budget_change_direction` (MAX)
- `campaign_name`, `item_name`, `shop_name` (MAX, 名称维度)

**跨粒度聚合注意事项**:
- 跨 item_id 聚合时: 以上 MAX/MIN 字段不能直接 SUM, 需重新按 target 粒度聚合
- `shop_cnt`, `item_cnt`: qq 版本固定为 1 (因为 GROUP BY item_id, 每行代表一个 item), 跨 item 聚合时需 COUNT(DISTINCT) 而非 SUM
- `ads_cnt`: qq 版本 SUM(ads_cnt) 从广告级聚合, 跨 item 聚合时可 SUM

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pcoc_tier | null | 数据不足 (daily_pgmv_sum_last_7d_clk 或 broad_gmv_usd 为 null/0) |
| pcoc_tier | overpcoc | daily_pgmv_sum_last_7d_clk / broad_gmv_usd > 1.2 |
| pcoc_tier | fulfillmentpcoc | ratio 在 [0.8, 1.2] |
| pcoc_tier | underpcoc | ratio < 0.8 |
| under_bidding_tier_1d | under_bid | simple2: broad_gmv > rev*sug_roi_upper / target2: rev < advv*0.8 |
| under_bidding_tier_1d | full_fill | simple2: broad_gmv in [rev*sug_roi_lower, rev*sug_roi_upper] / target2: rev in [advv*0.8, advv*1.2] |
| under_bidding_tier_1d | over_bid | simple2: broad_gmv < rev*sug_roi_lower / target2: rev > advv*1.2 |
| campaign_order_tier_1d | above5o | ads_broad_order >= 5 |
| campaign_order_tier_1d | above1o | ads_broad_order >= 1 |
| campaign_order_tier_1d | zeroOrder | ads_broad_order = 0 |

**entrance 映射 (with_omni 版本, 从 omni_core_key_metrics_merge_daily.common_feature 映射)**:

| entrance | common_feature |
|----------|---------------|
| DD | Daily Discover |
| YMAL | You May Also Like |
| PP | Cart Recommendation, Hot Deals Landing Recommendation, My Purchase Page Recommendation, Order Detail Page Recommendation, Order Successful Recommendation, Shipping Info Page YMAL, Shop YMAL, Video YMAL, Voucher Landing Recommendation |
| SEARCH | Global Search, Image Search |
| GAME | Games, Voucher Master |
| LIVESTREAM | Live Streaming, Livestream Game |
| SHOP | Search Shop |
| SHOP_GAME | Shop Game |
| IN_SHOP | From the Same Shop, Shop Main Browsing, Shop Other Recommendations, Shop Product Tab, Shop Recommended For You |
| other | null 或未匹配的所有值 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: `date('${ISO_YESTERDAY}')` (~90% 生产查询) / `DATE 'YYYY-MM-DD'` (手动分析)
- `grass_region`: `in ('ID','PH','SG','TH','TW','MY','VN','BR')` (qq 版本 8地区全量) / 单地区 `'SG'` (with_omni 版本单地区写入)
- `entrance`: `IN ('Search')` (arrive_pcoc 分析) / 不滤波 (union ALL 场景)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string | 入口/场景 (DD/YMAL/PP/SEARCH/GAME/LIVESTREAM/SHOP/SHOP_GAME/IN_SHOP/VIDEO/other) | - | - |
| plan_bucket_id | string | 计划分桶ID (qq 版本为 null, 保留用于 union 对齐) | - | - |
| pricing_type | string | 出价类型 (qq 版本为 null, 保留用于 union 对齐) | - | - |
| ads_id | bigint | 广告ID (qq 版本为 null, 保留用于 union 对齐) | - | - |
| campaign_id | bigint | 计划ID (qq 版本为 null, 保留用于 union 对齐) | - | - |
| item_id | bigint | 商品ID (核心维度) | - | - |
| shop_id | bigint | 店铺ID (MAX, 同一item取主导shop) | - | - |
| shop_level1_global_be_category | string | 店铺一级类目 | - | - |
| shop_level2_global_be_category | string | 店铺二级类目 | - | - |
| under_bidding_tier_1d | string | 1日出价tier (under_bid/full_fill/over_bid) | - | - |
| under_bidding_tier_7d | string | 7日出价tier | - | - |
| campaign_order_tier_1d | string | 1日订单tier (above5o/above1o/zeroOrder) | - | - |
| campaign_order_tier_7d | string | 7日订单tier | - | - |
| budget_tier | string | 预算tier | - | - |
| hit_valid_budget_tier | string | 命中有效预算tier | - | - |
| hit_daily_budget_tier | string | 命中日预算tier | - | - |
| hit_account_balance_tier | string | 命中账户余额tier | - | - |
| pcoc_tier | string | PCOC tier (null/overpcoc/fulfillmentpcoc/underpcoc) | - | - |
| revenue_usd | double | 广告消耗 USD | - | - |
| advv_usd | double | 广告价值 USD | - | - |
| direct_gmv_usd | double | 直接GMV USD | - | - |
| broad_gmv_usd | double | 宽口径GMV USD | - | - |
| noimp_gmv | double | 无曝光GMV | - | - |
| ads_direct_order | int | 直接订单数 | - | - |
| ads_broad_order | int | 宽口径订单数 | - | - |
| ads_imp | bigint | 广告曝光数 | - | - |
| ads_clk | bigint | 广告点击数 | - | - |
| revenue_usd_7d | double | 近7日广告消耗 USD | - | - |
| advv_usd_7d | double | 近7日广告价值 USD | - | - |
| ads_broad_order_7d | double | 近7日宽口径订单数 | - | - |
| broad_gmv_usd_7d | double | 近7日宽口径GMV USD | - | - |
| ads_imp_7d | bigint | 近7日广告曝光数 | - | - |
| ads_clk_7d | bigint | 近7日广告点击数 | - | - |
| bid_price_sum | double | 出价总和 | - | - |
| boost_price_sum | double | Boost出价总和 | - | - |
| expect_deduction_price_sum_raw | double | 期望扣费(raw)总和 | - | - |
| expect_deduction_price_sum_valid | double | 期望扣费(valid)总和 | - | - |
| gross_deduction_price_sum | double | 毛扣费总和 | - | - |
| net_deduction_price_sum | double | 净扣费总和 | - | - |
| raw_deduction_cnt | int | 原始扣费次数 | - | - |
| valid_deduction_cnt | int | 有效扣费次数 | - | - |
| troi_sum_by_imp | double | TROI (imp级) 累加 | - | - |
| troi_max_by_imp | double | TROI (imp级) 最大值 | - | - |
| troi_min_by_imp | double | TROI (imp级) 最小值 | - | - |
| rt_remain_budget_sum_by_imp | double | 实时剩余预算(imp级)累加 | - | - |
| rt_remain_budget_min_by_imp | double | 实时剩余预算(imp级)最小值 | - | - |
| rt_remain_budget_max_by_imp | double | 实时剩余预算(imp级)最大值 | - | - |
| sold_cnt_sum_by_imp | double | 售出数量(imp级)累加 | - | - |
| item_price_sum_by_imp | double | 商品价格(imp级)累加 | - | - |
| coef_sum_by_imp | double | 系数(imp级)累加 | - | - |
| coef_min_by_imp | double | 系数(imp级)最小值 | - | - |
| coef_max_by_imp | double | 系数(imp级)最大值 | - | - |
| pctr_sum_by_imp | double | pCTR (imp级)累加 | - | - |
| pcr_direct_sum_by_imp | double | pCR direct (imp级)累加 | - | - |
| pcr_direct_fail_imp_cnt | bigint | pCR direct 失败曝光数 | - | - |
| pcr_broad_sum_by_imp | double | pCR broad (imp级)累加 | - | - |
| pgmv_direct_sum_by_imp | double | pGMV direct (imp级)累加 | - | - |
| pgmv_broad_sum_by_imp | double | pGMV broad (imp级)累加 | - | - |
| final_pgmv_sum_by_imp | double | final pGMV (imp级)累加 | - | - |
| padvv_sum_by_imp | double | pADVV (imp级)累加 | - | - |
| ecpm_sum_by_imp | double | eCPM (imp级)累加 | - | - |
| pcr_direct_sum_by_clk | double | pCR direct (clk级)累加 | - | - |
| pcr_broad_sum_by_clk | double | pCR broad (clk级)累加 | - | - |
| pgmv_direct_sum_by_clk | double | pGMV direct (clk级)累加 | - | - |
| pgmv_broad_sum_by_clk | double | pGMV broad (clk级)累加 | - | - |
| final_pgmv_sum_by_clk | double | final pGMV (clk级)累加 | - | - |
| padvv_sum_by_clk | double | pADVV (clk级)累加 | - | - |
| ecpc_sum_by_clk | double | eCPC (clk级)累加 | - | - |
| request_cnt | bigint | 请求数 | - | - |
| after_recall_num | bigint | 召回后数量 | - | - |
| ads_after_recall_num | bigint | 广告召回后数量 | - | - |
| org_after_recall_num | bigint | 自然召回后数量 | - | - |
| after_prerank_num | bigint | 粗排后数量 | - | - |
| after_rank_num | bigint | 精排后数量 | - | - |
| after_mixrank_num | bigint | 混排后数量 | - | - |
| daily_advv_sum_last_7d_clk | bigint | 近7日按点击累加的ADVV (已废弃) | - | - |
| daily_pgmv_direct_sum_last_7d_clk | bigint | 近7日按点击累加的direct pGMV (已废弃) | - | - |
| daily_pgmv_broad_sum_last_7d_clk | bigint | 近7日按点击累加的broad pGMV (已废弃) | - | - |
| ads_cnt | int | 广告数 (qq版本 SUM 从广告级聚合) | - | - |
| campaign_cnt | int | 计划数 | - | - |
| shop_cnt | int | 店铺数 (qq版本固定值1, 跨item聚合需COUNT DISTINCT) | - | - |
| item_cnt | int | 商品数 (qq版本固定值1, 跨item聚合需COUNT DISTINCT) | - | - |
| valid_budget_campaign | double | 有效预算计划金额 | - | - |
| topup_usd | double | 充值金额 USD | - | - |
| manual_free_credit_topup_amt_1d | double | 人工免费信用充值金额1日 | - | - |
| account_balance_shop | double | 店铺账户余额 | - | - |
| ads_imp_cnt | bigint | 广告曝光数 (omni汇总, with_omni 版本来自 omni_core) | - | - |
| ads_clk_cnt | bigint | 广告点击数 (omni汇总, with_omni 版本来自 omni_core) | - | - |
| ads_order_cnt | bigint | 广告订单数 (omni汇总, with_omni 版本来自 omni_core) | - | - |
| ads_gmv_usd | double | 广告GMV USD (omni汇总, with_omni 版本来自 omni_core) | - | - |
| total_imp | bigint | 总曝光数(含自然, with_omni 版本来自 omni_core) | - | - |
| total_clk | bigint | 总点击数(含自然, with_omni 版本来自 omni_core) | - | - |
| total_order | bigint | 总订单数(含自然, with_omni 版本来自 omni_core) | - | - |
| total_gmv | double | 总GMV(含自然, with_omni 版本来自 omni_core) | - | - |
| target_roi | double | 目标ROI | - | - |
| idx_roi_upperbound | double | 索引ROI上界 | - | - |
| ultra_core_rev | double | UltraCore 收入 | - | - |
| ultra_core_advv | double | UltraCore 广告价值 | - | - |
| final_coef | double | 最终系数 | - | - |
| mpc_e_gmv | double | MPC预估GMV | - | - |
| mpc_e_cost | double | MPC预估消耗 | - | - |
| gmv_after_23pm | double | 23点后GMV | - | - |
| active_hour | int | 活跃时段 | - | - |
| is_active_after_20pm | tinyint | 20点后是否活跃 | - | - |
| daily_budget | double | 日预算 | - | - |
| bid_rerank_trace_null_cnt | bigint | bid_rerank_trace为空次数 | - | - |
| raw_ads_imp | bigint | 原始广告曝光数 | - | - |
| raw_ads_clk | bigint | 原始广告点击数 | - | - |
| deduct_imp | bigint | 扣费曝光数 | - | - |
| deduplicated_click | bigint | 去重点击 | - | - |
| daily_padvv_sum_last_7d_clk | double | 近7日按点击累加的pADVV | - | - |
| daily_pgmv_sum_last_7d_clk | double | 近7日按点击累加的final pGMV (PCOC 核心指标) | - | - |
| ad_tag | bigint | 广告标签 (bit位: qq版本 34+50+61; with_omni 版本 34+50+56+57+61) | - | - |
| tc_imp_count | bigint | TC曝光数 | - | - |
| rt_daily_budget_min_by_imp | double | 实时日预算(imp级)最小值 | - | - |
| daily_pay_pgmv_sum_last_7d_clk | double | 近7日按点击累加的paid pGMV | - | - |
| paid_broad_gmv_usd | double | Paid宽口径GMV | - | - |
| paid_broad_gmv_usd_7d | double | 近7日Paid宽口径GMV | - | - |
| daily_model_pgmv_sum_last_7d_clk | double | 近7日模型pGMV累加 | - | - |
| ads_paid_order | bigint | Paid订单数 | - | - |
| ads_paid_order_7d | bigint | 近7日Paid订单数 | - | - |
| model_broad_gmv_usd | double | 模型宽口径GMV | - | - |
| resp_ads_imp | bigint | 曝光回包广告数 | - | - |
| total_add_to_cart_cnt | bigint | 总加购数 (with_omni 版本来自 omni_core) | - | - |
| shop_adopts_gms | tinyint | 店铺是否采用GMS | - | - |
| shop_gmv_tier | int | 店铺GMV tier (with_omni 版本 COALESCE(attr, t) 优先取属性表) | - | - |
| hot_item_tag | tinyint | 热销品标签 | - | - |
| potential_item_tag | tinyint | 潜力品标签 | - | - |
| new_item_tag | tinyint | 新品标签 | - | - |
| winner_item_tag | tinyint | 爆品标签 | - | - |
| cheapest_item_tag | tinyint | 最低价品标签 | - | - |
| stock | bigint | 库存量 (with_omni 版本 COALESCE(attr, t) 优先取属性表) | - | - |
| is_rapid_boost_on | tinyint | 是否开启RapidBoost | - | - |
| is_auto_topup_enabled | tinyint | 是否开启自动充值 | - | - |
| auto_topup_daily_cap_amt_usd | double | 自动充值日上限 USD | - | - |
| auto_topup_amt_usd | double | 自动充值金额 USD | - | - |
| auto_topup_threshold_amt_usd | double | 自动充值阈值 USD | - | - |
| is_auto_escrow_enabled | tinyint | 是否开启自动托管 | - | - |
| auto_escrow_fixed_program_fee_rate | double | 自动托管固定费率 | - | - |
| auto_escrow_additional_fee_rate | double | 自动托管附加费率 | - | - |
| is_auto_budget_increase_enabled | tinyint | 是否开启自动提预算 | - | - |
| auto_budget_increase_percentage | double | 自动提预算百分比 | - | - |
| auto_budget_increase_daily_cap | double | 自动提预算日上限 | - | - |
| is_roi_three_voucher_enabled | tinyint | 是否开启ROI3券 | - | - |
| campaign_pause_cnt | int | 计划暂停次数 | - | - |
| campaign_stop_cnt | int | 计划停止次数 | - | - |
| troi_increase_cnt | int | TROI上调次数 | - | - |
| troi_decrease_cnt | int | TROI下调次数 | - | - |
| troi_mode_switch_cnt | int | TROI模式切换次数 | - | - |
| finite_budget_increase_cnt | int | 有限预算上调次数 | - | - |
| finite_budget_decrease_cnt | int | 有限预算下调次数 | - | - |
| unlimited_budget_on_cnt | int | 无限预算开启次数 | - | - |
| unlimited_budget_off_cnt | int | 无限预算关闭次数 | - | - |
| max_budget_decrease_magnitude | double | 最大预算下调幅度 | - | - |
| troi_change_direction | string | TROI变更方向 | - | - |
| budget_change_direction | string | 预算变更方向 | - | - |
| is_campaign_surge_enabled | tinyint | 是否开启Campaign Surge | - | - |
| campaign_name | string | 计划名称 (qq 版本为 null, with_omni 版本来自 dim_omni_item_shop_attr_daily) | - | - |
| item_name | string | 商品名称 (with_omni 版本来自 dim_omni_item_shop_attr_daily) | - | - |
| shop_name | string | 店铺名称 (with_omni 版本来自 dim_omni_item_shop_attr_daily) | - | - |
| total_seller_gmv_usd | double | 卖家总GMV USD (with_omni 版本来自 dws_omni_item_shop_entrance_metrics_daily) | - | - |
| grass_date | date | 分区列: 数据日期 | - | - |
| grass_region | string | 分区列: 地区 | - | - |
