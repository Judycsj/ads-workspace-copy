<!-- ads-workspace-gdoc-sync: gdoc_id=1IhT8BKltyGHFm4TnZtwHQMD8jH2-7pEqJVQH-6SsXKg gdoc_url=https://docs.google.com/document/d/1IhT8BKltyGHFm4TnZtwHQMD8jH2-7pEqJVQH-6SsXKg/edit -->

# Columns: mkplpaidads_search_ads.ads_advertise_key_metrics_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段来自 `static_ads_info_metrics` 通过 MAX() 聚合,跨 entrance/pricing_type 聚合时需谨慎处理:

- `valid_budget_campaign`, `topup_usd`, `manual_free_credit_topup_amt_1d`, `account_balance_shop` — 来自 static info,一个 ads_id 下多个 pricing_type 取 MAX,跨维度 SUM 可能重复
- `target_roi`, `idx_roi_upperbound`, `ultra_core_rev`, `ultra_core_advv`, `final_coef`, `mpc_e_gmv`, `mpc_e_cost`, `gmv_after_23pm` — 同上,per ads_id x pricing_type static info
- `active_hour`, `is_active_after_20pm`, `daily_budget` — 同上,per ads_id static info
- `shop_adopts_gms`, `shop_gmv_tier`, `hot_item_tag`, `potential_item_tag`, `new_item_tag`, `winner_item_tag`, `cheapest_item_tag`, `stock` — item/shop 属性,跨 entrance 聚合可能重复
- `total_seller_gmv_usd` — 来自 seller 聚合表,per item x shop x entrance,跨 ads 聚合需用 SUM(DISTINCT) 或先 GROUP BY 到正确粒度
- `ads_imp_cnt`, `ads_clk_cnt`, `ads_order_cnt`, `ads_gmv_usd`, `total_imp`, `total_clk`, `total_order`, `total_gmv`, `total_add_to_cart_cnt` — 来自 omni 表 (部分 region),per item x shop x entrance,跨 ads 聚合可能重复

### 枚举值映射 (Value Mappings)

#### under_bidding_tier_1d / under_bidding_tier_7d (出价饱和度)

| Column | Value | Meaning |
|--------|-------|---------|
| under_bidding_tier_1d/7d | under_bid | 曝光不足 (GMV/Revenue 低于 ROI target) |
| under_bidding_tier_1d/7d | full_fill | 出价饱满 (GMV/Revenue 在 ROI target 范围) |
| under_bidding_tier_1d/7d | over_bid | 出价偏高 (Revenue 高于 Advv) |

#### campaign_order_tier_1d / campaign_order_tier_7d (订单层级)

| Column | Value | Meaning |
|--------|-------|---------|
| campaign_order_tier_1d/7d | above5o | 5单及以上 |
| campaign_order_tier_1d/7d | above1o | 1-4单 |
| campaign_order_tier_1d/7d | zeroOrder | 零单 |

#### budget_tier (预算层级)

| Column | Value | Meaning |
|--------|-------|---------|
| budget_tier | large | 预算充足 (>3x 预期单均花费) |
| budget_tier | middle | 预算中等 (>1x 预期单均花费) |
| budget_tier | small | 预算不足 |

#### hit_valid_budget_tier / hit_daily_budget_tier / hit_account_balance_tier (预算命中)

| Column | Value | Meaning |
|--------|-------|---------|
| hit_*_tier | has_hit_budget | 已命中 (>97% 消耗) |
| hit_*_tier | no_hit_budget | 未命中 |

#### pcoc_tier (PCOC 校准层级)

| Column | Value | Meaning |
|--------|-------|---------|
| pcoc_tier | overpcoc | 预估偏高 (PCOC ratio > 1.2) |
| pcoc_tier | fulfillmentpcoc | 预估合理 (0.8 ~ 1.2) |
| pcoc_tier | underpcoc | 预估偏低 (< 0.8) |
| pcoc_tier | null | 无数据 (GMV 或 rate 为空/0) |

#### entrance / scene (入口场景)

从代码中的分类逻辑推断:

| Column | Value | Meaning |
|--------|-------|---------|
| entrance | DD | Daily Discover |
| entrance | YMAL | You May Also Like |
| entrance | SEARCH | Global Search / Image Search |
| entrance | PP | Personalized Page (Cart/Order/Shipping/Voucher Rec) |
| entrance | GAME | Games / Voucher Master |
| entrance | LIVESTREAM | Live Streaming / Livestream Game |
| entrance | SHOP | Search Shop |
| entrance | SHOP_GAME | Shop Game |
| entrance | IN_SHOP | In-Shop Recommendations |
| entrance | VIDEO | Video |
| entrance | other | Others (default fallback) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 单 region ('SG') / 6 regions ('TH','PH','VN','MY','TW','SG') / 7 regions + BR / 8 regions ('TH','PH','VN','MY','TW','SG','ID','BR')
- `grass_date`: `date('${ISO_YESTERDAY}')` (~90% 查询) / `date'YYYY-MM-DD'` (手动分析) / range: `between date'...' - interval N days and date'...'`
- `entrance`: 'DD', 'YMAL', 'SEARCH' (DQC 和核心分析场景)
- `pricing_type`: '11', '15' (受 omni 覆盖率监控的 pricing type)
- `ads_id > 0` — 排除无效广告

### 废弃字段

以下字段标注为 "废弃",代码中始终写入 null:

- `daily_advv_sum_last_7d_clk` — 废弃 (被 `daily_padvv_sum_last_7d_clk` 替代)
- `daily_pgmv_direct_sum_last_7d_clk` — 废弃
- `daily_pgmv_broad_sum_last_7d_clk` — 废弃

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string | 入口场景 (scene),如 DD/YMAL/SEARCH/PP 等 | - | - |
| plan_bucket_id | string | plan bucket 列表,逗号分隔 | - | - |
| pricing_type | string | 出价类型 | - | - |
| ads_id | bigint | 广告 ID | - | - |
| campaign_id | bigint | 广告系列 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| shop_level1_global_be_category | string | 店铺一级全球类目 | - | - |
| shop_level2_global_be_category | string | 店铺二级全球类目 | - | - |
| under_bidding_tier_1d | string | 1 日出价饱和度层级 | - | - |
| under_bidding_tier_7d | string | 7 日出价饱和度层级 | - | - |
| campaign_order_tier_1d | string | 1 日 campaign 订单层级 | - | - |
| campaign_order_tier_7d | string | 7 日 campaign 订单层级 | - | - |
| budget_tier | string | 预算层级 (large/middle/small) | - | - |
| hit_valid_budget_tier | string | 是否命中有效预算 | - | - |
| hit_daily_budget_tier | string | 是否命中日预算 | - | - |
| hit_account_balance_tier | string | 是否命中账户余额 | - | - |
| pcoc_tier | string | PCOC 校准层级 | - | - |
| revenue_usd | double | 收入 USD (1d) | - | - |
| advv_usd | double | 广告价值 USD (1d) | - | - |
| direct_gmv_usd | double | 直接 GMV USD (1d) | - | - |
| broad_gmv_usd | double | 泛 GMV USD (1d) | - | - |
| noimp_gmv | double | 无曝光 GMV USD (1d) | - | - |
| ads_direct_order | int | 广告直接订单数 (1d) | - | - |
| ads_broad_order | int | 广告泛订单数 (1d) | - | - |
| ads_imp | bigint | 广告曝光数 (1d) | - | - |
| ads_clk | bigint | 广告点击数 (1d,去重) | - | - |
| revenue_usd_7d | double | 收入 USD (7d) | - | - |
| advv_usd_7d | double | 广告价值 USD (7d) | - | - |
| ads_broad_order_7d | double | 泛订单数 (7d) | - | - |
| broad_gmv_usd_7d | double | 泛 GMV USD (7d) | - | - |
| ads_imp_7d | bigint | 曝光数 (7d) | - | - |
| ads_clk_7d | bigint | 点击数 (7d) | - | - |
| bid_price_sum | double | 出价总合 (换算 USD) | - | - |
| boost_price_sum | double | 加价总合 (换算 USD) | - | - |
| expect_deduction_price_sum_raw | double | 预期扣费总合 (raw,换算 USD) | - | - |
| expect_deduction_price_sum_valid | double | 预期扣费总合 (valid,换算 USD) | - | - |
| gross_deduction_price_sum | double | 毛扣费总合 (换算 USD) | - | - |
| net_deduction_price_sum | double | 净扣费总合 (已支付信用金,换算 USD) | - | - |
| raw_deduction_cnt | int | 原始扣费次数 | - | - |
| valid_deduction_cnt | int | 有效扣费次数 | - | - |
| troi_sum_by_imp | double | target ROI 倒数 SUM (by imp) | - | - |
| troi_max_by_imp | double | target ROI 倒数 MAX (by imp) | - | - |
| troi_min_by_imp | double | target ROI 倒数 MIN (by imp) | - | - |
| rt_remain_budget_sum_by_imp | double | 实时剩余预算 SUM (by imp,换算 USD) | - | - |
| rt_remain_budget_min_by_imp | double | 实时剩余预算 MIN (by imp,换算 USD) | - | - |
| rt_remain_budget_max_by_imp | double | 实时剩余预算 MAX (by imp,换算 USD) | - | - |
| sold_cnt_sum_by_imp | double | 商品销量 SUM (by imp) | - | - |
| item_price_sum_by_imp | double | 商品价格 SUM (by imp,换算 USD) | - | - |
| coef_sum_by_imp | double | PID 系数 SUM (by imp) | - | - |
| coef_min_by_imp | double | PID 系数 MIN (by imp) | - | - |
| coef_max_by_imp | double | PID 系数 MAX (by imp) | - | - |
| pctr_sum_by_imp | double | pCTR SUM (by imp) | - | - |
| pcr_direct_sum_by_imp | double | pCVR direct SUM (by imp) | - | - |
| pcr_direct_fail_imp_cnt | bigint | pCVR direct <=0 的曝光数 | - | - |
| pcr_broad_sum_by_imp | double | pCVR broad SUM (by imp) | - | - |
| pgmv_direct_sum_by_imp | double | pGMV direct SUM (by imp,换算 USD) | - | - |
| pgmv_broad_sum_by_imp | double | pGMV broad SUM (by imp,换算 USD) | - | - |
| final_pgmv_sum_by_imp | double | final pGMV SUM (by imp,换算 USD) | - | - |
| padvv_sum_by_imp | double | pAdvv SUM (by imp,换算 USD) | - | - |
| ecpm_sum_by_imp | double | eCPM SUM (by imp,换算 USD) | - | - |
| pcr_direct_sum_by_clk | double | pCVR direct SUM (by clk) | - | - |
| pcr_broad_sum_by_clk | double | pCVR broad SUM (by clk) | - | - |
| pgmv_direct_sum_by_clk | double | pGMV direct SUM (by clk,换算 USD) | - | - |
| pgmv_broad_sum_by_clk | double | pGMV broad SUM (by clk,换算 USD) | - | - |
| final_pgmv_sum_by_clk | double | final pGMV SUM (by clk,换算 USD) | - | - |
| padvv_sum_by_clk | double | pAdvv SUM (by clk,换算 USD) | - | - |
| ecpc_sum_by_clk | double | eCPC SUM (by clk,换算 USD) | - | - |
| request_cnt | bigint | 请求数 | - | - |
| after_recall_num | bigint | 召回后数量 | - | - |
| ads_after_recall_num | bigint | 广告召回后数量 | - | - |
| org_after_recall_num | bigint | 自然召回后数量 | - | - |
| after_prerank_num | bigint | 粗排后数量 | - | - |
| after_rank_num | bigint | 精排后数量 | - | - |
| after_mixrank_num | bigint | 混排后数量 | - | - |
| daily_advv_sum_last_7d_clk | bigint | (废弃) | - | - |
| daily_pgmv_direct_sum_last_7d_clk | bigint | (废弃) | - | - |
| daily_pgmv_broad_sum_last_7d_clk | bigint | (废弃) | - | - |
| ads_cnt | int | 广告数 (per row = 1) | - | - |
| campaign_cnt | int | 广告系列数 (per row = 1) | - | - |
| shop_cnt | int | 店铺数 (per row = 1) | - | - |
| item_cnt | int | 商品数 (per row = 1) | - | - |
| valid_budget_campaign | double | 有效 campaign 预算 USD | - | - |
| topup_usd | double | 充值金额 USD | - | - |
| manual_free_credit_topup_amt_1d | double | 手动免费 credit 充值 1d | - | - |
| account_balance_shop | double | 店铺账户余额 USD | - | - |
| ads_imp_cnt | bigint | Omni 广告曝光数 (跨平台) | - | - |
| ads_clk_cnt | bigint | Omni 广告点击数 (跨平台) | - | - |
| ads_order_cnt | bigint | Omni 广告订单数 (跨平台) | - | - |
| ads_gmv_usd | double | Omni 广告 GMV USD (跨平台) | - | - |
| total_imp | bigint | Omni 总曝光 (含自然) | - | - |
| total_clk | bigint | Omni 总点击 (含自然) | - | - |
| total_order | bigint | Omni 总订单 (含自然) | - | - |
| total_gmv | double | Omni 总 GMV (含自然) | - | - |
| target_roi | double | Target ROI | - | - |
| idx_roi_upperbound | double | Index ROI 上界 | - | - |
| ultra_core_rev | double | Ultra Core Revenue (换算 USD) | - | - |
| ultra_core_advv | double | Ultra Core Advv (换算 USD) | - | - |
| final_coef | double | Final PID coefficient | - | - |
| mpc_e_gmv | double | MPC estimated GMV (换算 USD) | - | - |
| mpc_e_cost | double | MPC estimated Cost (换算 USD) | - | - |
| gmv_after_23pm | double | 23 点后 GMV (换算 USD) | - | - |
| active_hour | int | 活跃小时数 | - | - |
| is_active_after_20pm | tinyint | 20 点后是否活跃 | - | - |
| daily_budget | double | 日预算 USD | - | - |
| bid_rerank_trace_null_cnt | bigint | bid_rerank_trace 为空的曝光数 | - | - |
| raw_ads_imp | bigint | 原始曝光数 (未去重) | - | - |
| raw_ads_clk | bigint | 原始点击数 (未去重) | - | - |
| deduct_imp | bigint | 扣费曝光数 | - | - |
| deduplicated_click | bigint | 去重点击 (同 ads_clk) | - | - |
| daily_padvv_sum_last_7d_clk | double | 校准后 pAdvv 7d SUM (by clk,换算 USD) | - | - |
| daily_pgmv_sum_last_7d_clk | double | 校准后 pGMV 7d SUM (by clk,换算 USD) | - | - |
| ad_tag | bigint | 广告标签 (bitmask,用于冷启等判断) | - | - |
| tc_imp_count | bigint | 冷启曝光数 (ad_tag bit 34 或 56) | - | - |
| rt_daily_budget_min_by_imp | double | 实时日预算 MIN (当天 respond,换算 USD) | - | - |
| daily_pay_pgmv_sum_last_7d_clk | double | 校准后 Pay pGMV 7d SUM (by clk,换算 USD) | - | - |
| paid_broad_gmv_usd | double | 已支付泛 GMV USD (1d) | - | - |
| paid_broad_gmv_usd_7d | double | 已支付泛 GMV USD (7d) | - | - |
| daily_model_pgmv_sum_last_7d_clk | double | 校准后 Model pGMV 7d SUM (by clk,换算 USD) | - | - |
| ads_paid_order | bigint | 广告已支付订单数 (1d) | - | - |
| ads_paid_order_7d | bigint | 广告已支付订单数 (7d) | - | - |
| model_broad_gmv_usd | double | 模型预估泛 GMV USD (1d) | - | - |
| resp_ads_imp | bigint | 当日 respond 的广告曝光数 | - | - |
| total_add_to_cart_cnt | bigint | Omni 总加购数 | - | - |
| shop_adopts_gms | tinyint | 店铺是否使用 GMS | - | - |
| shop_gmv_tier | int | 店铺 GMV 层级 | - | - |
| hot_item_tag | tinyint | 热销单品标签 | - | - |
| potential_item_tag | tinyint | 潜力单品标签 | - | - |
| new_item_tag | tinyint | 新品标签 | - | - |
| winner_item_tag | tinyint | Winner 单品标签 | - | - |
| cheapest_item_tag | tinyint | 最低价单品标签 | - | - |
| stock | bigint | 库存 | - | - |
| is_rapid_boost_on | tinyint | 是否开启 Rapid Boost | - | - |
| is_auto_topup_enabled | tinyint | 是否启用自动充值 | - | - |
| auto_topup_daily_cap_amt_usd | double | 自动充值日上限 USD | - | - |
| auto_topup_amt_usd | double | 自动充值金额 USD | - | - |
| auto_topup_threshold_amt_usd | double | 自动充值阈值 USD | - | - |
| is_auto_escrow_enabled | tinyint | 是否启用自动 Escrow | - | - |
| auto_escrow_fixed_program_fee_rate | double | 自动 Escrow 固定费率 | - | - |
| auto_escrow_additional_fee_rate | double | 自动 Escrow 附加费率 | - | - |
| is_auto_budget_increase_enabled | tinyint | 是否启用自动预算提升 | - | - |
| auto_budget_increase_percentage | double | 自动预算提升比例 | - | - |
| auto_budget_increase_daily_cap | double | 自动预算提升日上限 | - | - |
| is_roi_three_voucher_enabled | tinyint | 是否启用 ROI3 voucher | - | - |
| campaign_pause_cnt | int | 暂停次数 | - | - |
| campaign_stop_cnt | int | 停止次数 | - | - |
| troi_increase_cnt | int | TROI 上调次数 | - | - |
| troi_decrease_cnt | int | TROI 下调次数 | - | - |
| troi_mode_switch_cnt | int | TROI 模式切换次数 | - | - |
| finite_budget_increase_cnt | int | 有限预算上调次数 | - | - |
| finite_budget_decrease_cnt | int | 有限预算下调次数 | - | - |
| unlimited_budget_on_cnt | int | 开启无限预算次数 | - | - |
| unlimited_budget_off_cnt | int | 关闭无限预算次数 | - | - |
| max_budget_decrease_magnitude | double | 最大预算下调幅度 | - | - |
| troi_change_direction | string | TROI 变动方向 | - | - |
| budget_change_direction | string | 预算变动方向 | - | - |
| is_campaign_surge_enabled | tinyint | 是否启用 Campaign Surge | - | - |
| campaign_name | string | 广告系列名称 (仅部分 region 有) | - | - |
| item_name | string | 商品名称 (仅部分 region 有) | - | - |
| shop_name | string | 店铺名称 (仅部分 region 有) | - | - |
| total_seller_gmv_usd | double | 卖家总 GMV USD (omni,跨平台) | - | - |
| is_ocpm | tinyint | 是否 oCPM 广告 | - | - |
| grass_date | date | [PARTITION] 数据日期 | - | - |
| grass_region | string | [PARTITION] 国家/区域 (TH,PH,VN,MY,TW,SG,ID,BR) | - | - |
