<!-- ads-workspace-gdoc-sync: gdoc_id=1Xm0wKbXRt3b1jiUU13kHpRE9pr1luRTl7dOSIstblLs gdoc_url=https://docs.google.com/document/d/1Xm0wKbXRt3b1jiUU13kHpRE9pr1luRTl7dOSIstblLs/edit -->

# Columns: mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live

> MAX(column) 采样条件: grass_date='2026-06-13', grass_region='SG'

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为实体级明细表（每行 = 一个 ads/item/campaign/shop），无需 SUM(DISTINCT) 去重。但跨 `type` 聚合时注意：同一 `item_id` 在 type='ads' 和 type='item' 中分别出现，需按 `type` 过滤避免重复计数。

**Deprecated 列**（with-omni 新版 DDL 中标记为"废弃"，旧版仍保留）:
- `daily_advv_sum_last_7d_clk` (bigint) -- 已被 `daily_padvv_sum_last_7d_clk` (double) 替代
- `daily_pgmv_direct_sum_last_7d_clk` (bigint) -- 已废弃
- `daily_pgmv_broad_sum_last_7d_clk` (bigint) -- 已被 `daily_pgmv_sum_last_7d_clk` (double) 替代

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| type | ads | 广告级别 |
| type | item | 商品级别 |
| type | campaign | 计划级别 |
| type | shop | 店铺级别 |
| pricing_type | 11 | Target ROI2 |
| pricing_type | 15 | Simple ROI2 |
| pricing_type | 24, 25, 27 | 新 ROI 类型 |
| entrance | SEARCH | 搜索入口 |
| entrance | DD | Daily Discover 入口 |
| entrance | YMAL | You May Also Like 入口 |
| entrance | PP | Post Purchase 入口 |
| entrance | Daily Discover | DD 全称（部分文件使用） |
| entrance | You May Also Like | YMAL 全称（部分文件使用） |

### 常见 WHERE 值 (Common Filter Values)

- `type`: `'ads'` (广告级分析) / `'item'` (商品级 pCOC) / `'campaign'` (计划级 pCOC、超收检测、达标率) / `'shop'` (店铺级)
- `pricing_type`: `'11', '24', '25', '27', '15'` (ROI 类广告，pCOC 分析最常用) / `11, 15` (整数格式，部分文件使用) / `!= 0` (写入时 ads 排除 type=0)
- `entrance`: `'SEARCH', 'DD', 'YMAL', 'PP'` (pCOC 分析常用四入口，缩写格式) / `'Daily Discover', 'You May Also Like', 'Search', 'Post Purchase'` (全称格式)
- `grass_region`: `'ID','PH','SG','TH','TW','MY','VN','BR'` (标准 8 区)
- `ads_clk > 0`: pCOC 分析中过滤有点击的广告
- `item_id > 0` / `ads_id > 0`: 过滤有效实体
- `ad_tag`: `CAST(ad_tag AS BIGINT) & 8192 = 8192` (bit 13 检查，discovery_ads 场景)
- `campaign_id = X AND grass_date >= DATE(...) - 7`: Diagnosis campaign 定位，跨 7 天查找

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|-------------|------|-------------|-----------------|-------------|
| 1 | grass_date [PARTITION] | date | - | 480/2509/3268 | - |
| 2 | grass_region [PARTITION] | string | - | 480/2504/3258 | - |
| 3 | type | string | - | 468/2491/3244 | shop |
| 4 | item_id | bigint | - | 429/2374/3086 | 58162165867 |
| 5 | shop_id | bigint | - | 422/2375/3081 | 58154808683 |
| 6 | total_gmv | double | - | 397/2297/2948 | 80210.10 |
| 7 | total_order | bigint | - | 389/2268/2914 | 2304 |
| 8 | total_add_to_cart_cnt | bigint | - | 389/2266/2908 | 8290 |
| 9 | shop_level1_global_be_category | string | - | 389/2266/2901 | Women Shoes |
| 10 | shop_level2_global_be_category | string | - | 389/2266/2901 | Writing & Correction |
| 11 | shop_gmv_tier | int | - | 389/2266/2840 | 5 |
| 12 | pricing_type | string | - | 355/1670/2254 | 9 |
| 13 | campaign_id | bigint | - | 359/1666/2234 | 55774053 |
| 14 | entrance | string | - | 337/1643/2196 | other |
| 15 | ads_id | bigint | - | 343/1613/2146 | 115783479 |
| 16 | plan_bucket_id | string | - | 309/1569/2090 | 9919,9929 |
| 17 | ads_order_cnt | bigint | - | 317/1560/2080 | 1190 |
| 18 | ads_gmv_usd | double | - | 317/1553/2058 | 16459.65 |
| 19 | ads_imp_cnt | bigint | - | 310/1546/2051 | 1047428 |
| 20 | ads_clk_cnt | bigint | - | 310/1546/2051 | 15837 |

### 查询频率分析

**高频核心列** (L30D > 3000):
- `grass_date` (3268) / `grass_region` (3258) — 分区列，几乎所有查询必带
- `type` (3244) — 实体类型过滤，区分 ads/item/campaign/shop 分析场景
- `item_id` (3086) / `shop_id` (3081) — 实体关联键，用于 JOIN 或 GROUP BY

**高频业务列** (L30D 2000-3000):
- `total_gmv` (2948) / `total_order` (2914) / `total_add_to_cart_cnt` (2908) — 电商效果指标，诊断面板核心展示
- `shop_level1/2_global_be_category` (2901) / `shop_gmv_tier` (2840) — 商品品类和店铺分层，用于切片分析
- `entrance` (2196) / `pricing_type` (2254) / `campaign_id` (2234) / `ads_id` (2146) — 业务过滤和实体定位
- `plan_bucket_id` (2090) / `ads_imp_cnt` (2051) / `ads_clk_cnt` (2051) / `total_imp` (2051) / `total_clk` (2051) — 诊断面板展示列
- `ads_order_cnt` (2080) / `ads_gmv_usd` (2058) — 广告效果聚合指标
- `hot_item_tag` / `potential_item_tag` / `new_item_tag` / `stock` (1982) — 商品标签和库存，诊断面板展示

**中频分析列** (L30D 1500-2000):
- `campaign_name` / `item_name` / `shop_name` (1884-1885) — 名称展示列
- `revenue_usd` (1752) / `broad_gmv_usd` (1758) / `advv_usd` (1642) — 收入/GMV/成本核心三指标
- `ads_clk` (1680) / `paid_broad_gmv_usd` (1635) / `ads_broad_order` (1625) — 效果分析
- `ads_imp` (1597) / `direct_gmv_usd` (1579) / `ads_direct_order` (1580) — 直接归因指标
- `total_seller_gmv_usd` (1597) — 卖家总 GMV
- `daily_budget` (1581) / `target_roi` (1573) / `valid_budget_campaign` (1575) / `topup_usd` (1568) — 预算与 ROI 设置

**低频专业列** (L30D < 1000):
- `daily_pgmv_sum_last_7d_clk` (814) / `daily_model_pgmv_sum_last_7d_clk` (780) / `daily_pay_pgmv_sum_last_7d_clk` (773) / `daily_padvv_sum_last_7d_clk` (750) — pCOC 计算专用列，仅 pCOC 达标率监控使用
- 出价信号、模型预估 (by imp/clk)、广告漏斗等列 (710-724) — 仅诊断写入或深度分析使用

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| type | string | - | 468/2491/3244 | shop |
| entrance | string | - | 337/1643/2196 | other |
| plan_bucket_id | string | - | 309/1569/2090 | 9919,9929 |
| pricing_type | string | - | 355/1670/2254 | 9 |
| ads_id | bigint | - | 343/1613/2146 | 115783479 |
| campaign_id | bigint | - | 359/1666/2234 | 55774053 |
| item_id | bigint | - | 429/2374/3086 | 58162165867 |
| shop_id | bigint | - | 422/2375/3081 | 58154808683 |
| shop_level1_global_be_category | string | - | 389/2266/2901 | Women Shoes |
| shop_level2_global_be_category | string | - | 389/2266/2901 | Writing & Correction |
| under_bidding_tier_1d | string | - | 165/455/710 | under_bid |
| under_bidding_tier_7d | string | - | 165/449/703 | under_bid |
| campaign_order_tier_1d | string | - | 166/450/704 | zeroOrder |
| campaign_order_tier_7d | string | - | 165/449/703 | zeroOrder |
| budget_tier | string | - | 166/450/705 | small |
| hit_valid_budget_tier | string | - | 166/451/705 | no_hit_budget |
| hit_daily_budget_tier | string | - | 166/451/705 | no_hit_budget |
| hit_account_balance_tier | string | - | 173/458/712 | no_hit_budget |
| pcoc_tier | string | - | 165/449/704 | underpcoc |
| revenue_usd | double | - | 310/1304/1752 | 19393.60 |
| advv_usd | double | - | 273/1229/1642 | 19393.60 |
| direct_gmv_usd | double | - | 245/1172/1579 | 83821.90 |
| broad_gmv_usd | double | - | 308/1308/1758 | 101498.62 |
| noimp_gmv | double | - | 165/449/717 | 6944.83 |
| ads_direct_order | int | - | 245/1174/1580 | 1688 |
| ads_broad_order | int | - | 255/1198/1625 | 2204 |
| ads_imp | bigint | - | 246/1179/1597 | 2339497 |
| ads_clk | bigint | - | 272/1235/1680 | 680968 |
| revenue_usd_7d | double | - | 165/449/710 | 178302.90 |
| advv_usd_7d | double | - | 165/449/710 | 178302.90 |
| ads_broad_order_7d | double | - | 165/449/710 | 23575.0 |
| broad_gmv_usd_7d | double | - | 165/449/710 | 1293602.19 |
| ads_imp_7d | bigint | - | 165/449/710 | 16398579 |
| ads_clk_7d | bigint | - | 165/449/710 | 4816117 |
| bid_price_sum | double | - | 165/450/711 | 615768.05 |
| boost_price_sum | double | - | 165/449/717 | 53026.05 |
| expect_deduction_price_sum_raw | double | - | 165/449/710 | 40289.11 |
| expect_deduction_price_sum_valid | double | - | 165/449/710 | 40289.11 |
| gross_deduction_price_sum | double | - | 165/449/720 | 19393.60 |
| net_deduction_price_sum | double | - | 165/449/720 | 1803532021.92 |
| raw_deduction_cnt | int | - | 165/449/710 | 680968 |
| valid_deduction_cnt | int | - | 165/449/710 | 669900 |
| troi_sum_by_imp | double | - | 166/453/724 | 14925078.44 |
| troi_max_by_imp | double | - | 165/449/710 | 149.80 |
| troi_min_by_imp | double | - | 165/449/710 | 50.00 |
| rt_remain_budget_sum_by_imp | double | - | 165/450/711 | 1252435960.62 |
| rt_remain_budget_min_by_imp | double | - | 165/449/710 | 86642.07 |
| rt_remain_budget_max_by_imp | double | - | 165/449/710 | 93787.50 |
| sold_cnt_sum_by_imp | double | - | 165/449/714 | 2059275.47 |
| item_price_sum_by_imp | double | - | 165/449/717 | 32742287.49 |
| coef_sum_by_imp | double | - | 165/450/718 | 5809107.94 |
| coef_min_by_imp | double | - | 165/449/710 | 16.0 |
| coef_max_by_imp | double | - | 165/449/710 | 16.0 |
| pctr_sum_by_imp | double | - | 165/452/724 | 30015.27 |
| pcr_direct_sum_by_imp | double | - | 165/451/712 | 22747.57 |
| pcr_direct_fail_imp_cnt | bigint | - | 165/449/711 | 2339497 |
| pcr_broad_sum_by_imp | double | - | 165/449/715 | 36623.96 |
| pgmv_direct_sum_by_imp | double | - | 165/449/710 | 371852.18 |
| pgmv_broad_sum_by_imp | double | - | 165/449/710 | 610555.13 |
| final_pgmv_sum_by_imp | double | - | 165/449/718 | 78037352.38 |
| padvv_sum_by_imp | double | - | 165/449/710 | 420072.18 |
| ecpm_sum_by_imp | double | - | 165/450/718 | 20580.64 |
| pcr_direct_sum_by_clk | double | - | 165/449/710 | 1487.10 |
| pcr_broad_sum_by_clk | double | - | 165/450/715 | 1919.44 |
| pgmv_direct_sum_by_clk | double | - | 165/449/710 | 31407.29 |
| pgmv_broad_sum_by_clk | double | - | 165/450/711 | 36098.76 |
| final_pgmv_sum_by_clk | double | - | 165/449/710 | 23433901.42 |
| padvv_sum_by_clk | double | - | 165/450/711 | 38933.16 |
| ecpc_sum_by_clk | double | - | 165/450/711 | 5112.18 |
| request_cnt | bigint | - | 165/449/714 | 13273453 |
| after_recall_num | bigint | - | 165/449/719 | 13254424 |
| ads_after_recall_num | bigint | - | 165/449/710 | 4872858 |
| org_after_recall_num | bigint | - | 165/449/710 | 9606636 |
| after_prerank_num | bigint | - | 165/449/714 | 4310196 |
| after_rank_num | bigint | - | 165/449/714 | 1110138 |
| after_mixrank_num | bigint | - | 165/449/719 | 101577 |
| daily_advv_sum_last_7d_clk | bigint | - | 165/449/710 | NULL |
| daily_pgmv_direct_sum_last_7d_clk | bigint | - | 165/449/710 | NULL |
| daily_pgmv_broad_sum_last_7d_clk | bigint | - | 165/449/710 | NULL |
| ads_cnt | int | - | 165/449/710 | 3102 |
| campaign_cnt | int | - | 165/449/711 | 3102 |
| shop_cnt | int | - | 165/449/710 | 1 |
| item_cnt | int | - | 165/449/710 | 3002 |
| valid_budget_campaign | double | - | 245/1170/1575 | 28961.52 |
| topup_usd | double | - | 245/1170/1568 | 5323.94 |
| manual_free_credit_topup_amt_1d | double | - | 165/449/710 | 197248.68 |
| account_balance_shop | double | - | 165/450/711 | 197248.68 |
| ads_imp_cnt | bigint | - | 310/1546/2051 | 1047428 |
| ads_clk_cnt | bigint | - | 310/1546/2051 | 15837 |
| ads_order_cnt | bigint | - | 317/1560/2080 | 1190 |
| ads_gmv_usd | double | - | 317/1553/2058 | 16459.65 |
| total_imp | bigint | - | 310/1546/2051 | 1627276 |
| total_clk | bigint | - | 310/1546/2051 | 39268 |
| total_order | bigint | - | 389/2268/2914 | 2304 |
| total_gmv | double | - | 397/2297/2948 | 80210.10 |
| target_roi | double | - | 245/1172/1573 | 50.0 |
| idx_roi_upperbound | double | - | 165/450/711 | 70.0 |
| ultra_core_rev | double | - | 165/449/710 | 161897.83 |
| ultra_core_advv | double | - | 165/449/710 | 199250.97 |
| final_coef | double | - | 165/450/714 | 8.28 |
| mpc_e_gmv | double | - | 165/449/710 | 294267292.10 |
| mpc_e_cost | double | - | 165/449/710 | 63294090.91 |
| gmv_after_23pm | double | - | 165/449/710 | 2047.37 |
| active_hour | int | - | 165/450/712 | 24 |
| is_active_after_20pm | tinyint | - | 165/449/710 | 1 |
| daily_budget | double | - | 253/1179/1581 | 9999999999 |
| bid_rerank_trace_null_cnt | bigint | - | 165/449/710 | 717963 |
| raw_ads_imp | bigint | - | 245/1170/1568 | 2339497 |
| raw_ads_clk | bigint | - | 245/1170/1568 | 680968 |
| deduct_imp | bigint | - | 165/449/710 | 709636 |
| deduplicated_click | bigint | - | 169/454/715 | 680968 |
| daily_padvv_sum_last_7d_clk | double | - | 184/488/750 | 5910760.46 |
| daily_pgmv_sum_last_7d_clk | double | - | 201/519/814 | 26326423.40 |
| ad_tag | bigint | - | 165/449/710 | 9079401986461270033 |
| tc_imp_count | bigint | - | 165/449/710 | 79658 |
| rt_daily_budget_min_by_imp | double | - | 165/449/710 | 86849.80 |
| daily_pay_pgmv_sum_last_7d_clk | double | - | 182/482/773 | 39061.73 |
| paid_broad_gmv_usd | double | - | 262/1203/1635 | 96811.16 |
| paid_broad_gmv_usd_7d | double | - | 165/449/710 | 1223331.90 |
| daily_model_pgmv_sum_last_7d_clk | double | - | 183/487/780 | 36690.89 |
| ads_paid_order | bigint | - | 245/1170/1568 | 2116 |
| ads_paid_order_7d | bigint | - | 165/449/710 | 22878 |
| model_broad_gmv_usd | double | - | 165/449/710 | 33530.67 |
| resp_ads_imp | bigint | - | 165/449/710 | 2337213 |
| total_add_to_cart_cnt | bigint | - | 389/2266/2908 | 8290 |
| shop_adopts_gms | tinyint | - | 245/1170/1568 | 1 |
| shop_gmv_tier | int | - | 389/2266/2840 | 5 |
| hot_item_tag | tinyint | - | 309/1545/1982 | 1 |
| potential_item_tag | tinyint | - | 309/1545/1982 | 1 |
| new_item_tag | tinyint | - | 309/1545/1982 | 1 |
| winner_item_tag | tinyint | - | 165/449/710 | NULL |
| cheapest_item_tag | tinyint | - | 165/449/710 | NULL |
| stock | bigint | - | 309/1545/1982 | 9683812449 |
| is_rapid_boost_on | tinyint | - | 245/1170/1568 | 1 |
| is_auto_topup_enabled | tinyint | - | 245/1170/1568 | 1 |
| auto_topup_daily_cap_amt_usd | double | - | 165/449/710 | 7829.32 |
| auto_topup_amt_usd | double | - | 165/449/710 | 7829.32 |
| auto_topup_threshold_amt_usd | double | - | 165/449/710 | 54.81 |
| is_auto_escrow_enabled | tinyint | - | 245/1170/1568 | 1 |
| auto_escrow_fixed_program_fee_rate | double | - | 165/449/710 | 0.05 |
| auto_escrow_additional_fee_rate | double | - | 165/449/710 | 0.5 |
| is_auto_budget_increase_enabled | tinyint | - | 245/1170/1568 | 1 |
| auto_budget_increase_percentage | double | - | 165/449/710 | 300.0 |
| auto_budget_increase_daily_cap | double | - | 165/449/710 | 5.0 |
| is_roi_three_voucher_enabled | tinyint | - | 165/449/710 | 1 |
| campaign_pause_cnt | int | - | 165/449/710 | 1152 |
| campaign_stop_cnt | int | - | 165/449/710 | 105 |
| troi_increase_cnt | int | - | 165/449/710 | 399 |
| troi_decrease_cnt | int | - | 165/449/710 | 391 |
| troi_mode_switch_cnt | int | - | 165/449/710 | 165 |
| finite_budget_increase_cnt | int | - | 165/449/710 | 544 |
| finite_budget_decrease_cnt | int | - | 165/449/710 | 222 |
| unlimited_budget_on_cnt | int | - | 165/449/710 | 9 |
| unlimited_budget_off_cnt | int | - | 165/449/710 | 261 |
| max_budget_decrease_magnitude | double | - | 165/449/710 | 0.984 |
| troi_change_direction | string | - | 165/449/703 | unchanged |
| budget_change_direction | string | - | 165/449/703 | unchanged |
| is_campaign_surge_enabled | tinyint | - | 245/1170/1568 | 1 |
| campaign_name | string | - | 309/1550/1885 | (long string) |
| item_name | string | - | 309/1549/1884 | (long string) |
| shop_name | string | - | 309/1549/1884 | (emoji string) |
| total_seller_gmv_usd | double | - | 228/1597/1597 | 2558572.34 |
| grass_date [PARTITION] | date | - | 480/2509/3268 | - |
| grass_region [PARTITION] | string | - | 480/2504/3258 | - |
