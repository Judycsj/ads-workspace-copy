<!-- ads-workspace-gdoc-sync: gdoc_id=1ybGX4wyPRREIKtOPRgtQgWJpuJv2MLR4uydhFyeIl4U gdoc_url=https://docs.google.com/document/d/1ybGX4wyPRREIKtOPRgtQgWJpuJv2MLR4uydhFyeIl4U/edit -->

# mkplpaidads_search_ads.ads_seller_key_metrics_daily__reg_s0_live

## Description

- **Desc:** Shop-level aggregated key metrics for Search Ads, grouped daily by shop and entrance (traffic scene). Derived from `ads_advertise_key_metrics_daily` by rolling up ad-level data to shop level. Includes revenue, GMV, order counts, impression/click metrics, deduction data, bidding model features, pipeline flow counts, budget/topup info, and seller attribute snapshots.
- **Granularity:** daily x shop_id x entrance x grass_region
- **Use Case:**
  - OKR Take Rate daily report -- shop-level revenue and GMV aggregation
  - Search Ads union metrics (type='shop') -- feeds into `ads_union_key_metrics_daily` alongside ads/item/campaign levels
  - Ads diagnosis -- shop health monitoring (budget, tier, bidding status)
  - Seller feature analysis -- auto topup, rapid boost, campaign surge, budget change behavior
  - Omni-channel GMV analysis with scene-level breakdown (BR omni_us variant)
- **Update Frequency:** Daily (scheduled workflows per region)

## Key Metrics

- 收入类: revenue_usd, advv_usd, ultra_core_rev, ultra_core_advv
- GMV类: direct_gmv_usd, broad_gmv_usd, noimp_gmv, total_gmv, mpc_e_gmv, mpc_e_cost, total_seller_gmv_usd
- Paid GMV: paid_broad_gmv_usd, paid_broad_gmv_usd_7d, model_broad_gmv_usd
- 订单类: ads_direct_order, ads_broad_order, ads_order_cnt, total_order, ads_paid_order, ads_paid_order_7d
- 曝光/点击: ads_imp, ads_clk, ads_imp_cnt, ads_clk_cnt, raw_ads_imp, raw_ads_clk, deduct_imp, deduplicated_click, resp_ads_imp
- 曝光/点击(7d): ads_imp_7d, ads_clk_7d
- 全站流量: total_imp, total_clk
- 扣费类: expect_deduction_price_sum_raw, expect_deduction_price_sum_valid, gross_deduction_price_sum, net_deduction_price_sum, raw_deduction_cnt, valid_deduction_cnt
- 出价/模型特征: bid_price_sum, boost_price_sum, troi_sum_by_imp, troi_max_by_imp (MAX), troi_min_by_imp (MIN), pctr_sum_by_imp, pcr_direct_sum_by_imp, pcr_direct_fail_imp_cnt, pcr_broad_sum_by_imp, pgmv_direct_sum_by_imp, pgmv_broad_sum_by_imp, final_pgmv_sum_by_imp, padvv_sum_by_imp, ecpm_sum_by_imp, coef_sum_by_imp, coef_min_by_imp (MIN), coef_max_by_imp (MAX)
- 点击维度模型: pcr_direct_sum_by_clk, pcr_broad_sum_by_clk, pgmv_direct_sum_by_clk, pgmv_broad_sum_by_clk, final_pgmv_sum_by_clk, padvv_sum_by_clk, ecpc_sum_by_clk
- Pipeline流量: request_cnt, after_recall_num, ads_after_recall_num, org_after_recall_num, after_prerank_num, after_rank_num, after_mixrank_num
- 7日预估类: daily_advv_sum_last_7d_clk (废弃), daily_pgmv_direct_sum_last_7d_clk (废弃), daily_pgmv_broad_sum_last_7d_clk (废弃), daily_padvv_sum_last_7d_clk, daily_pgmv_sum_last_7d_clk, daily_pay_pgmv_sum_last_7d_clk, daily_model_pgmv_sum_last_7d_clk
- 预算/Topup: valid_budget_campaign (MAX - shop级属性), topup_usd (MAX), manual_free_credit_topup_amt_1d (MAX), account_balance_shop (MAX), daily_budget (MAX), rt_remain_budget_sum_by_imp, rt_remain_budget_min_by_imp (MIN), rt_remain_budget_max_by_imp (MAX)
- 计数: ads_cnt, campaign_cnt, shop_cnt, item_cnt, sold_cnt_sum_by_imp, item_price_sum_by_imp, stock
- 开关类: is_active_after_20pm (MAX), is_rapid_boost_on (MAX), is_auto_topup_enabled (MAX), is_auto_escrow_enabled (MAX), is_auto_budget_increase_enabled (MAX), is_roi_three_voucher_enabled (MAX), is_campaign_surge_enabled (MAX)
- 操作行为: campaign_pause_cnt, campaign_stop_cnt, troi_increase_cnt, troi_decrease_cnt, troi_mode_switch_cnt, finite_budget_increase_cnt, finite_budget_decrease_cnt, unlimited_budget_on_cnt, unlimited_budget_off_cnt

## Key Dimensions

- 分区: grass_date, grass_region
- 核心维度: entrance (流量入口/场景), shop_id
- Shop分类: shop_level1_global_be_category, shop_level2_global_be_category
- 分层标签: under_bidding_tier_1d, under_bidding_tier_7d, campaign_order_tier_1d, campaign_order_tier_7d, budget_tier, hit_valid_budget_tier, hit_daily_budget_tier, hit_account_balance_tier, pcoc_tier
- Auto策略: auto_topup_daily_cap_amt_usd, auto_topup_amt_usd, auto_topup_threshold_amt_usd, auto_escrow_fixed_program_fee_rate, auto_escrow_additional_fee_rate, auto_budget_increase_percentage, auto_budget_increase_daily_cap
- 商品标签: hot_item_tag, potential_item_tag, new_item_tag, winner_item_tag, cheapest_item_tag
- 预算变更方向: troi_change_direction, budget_change_direction
- 名称: campaign_name (MAX), item_name (MAX), shop_name (MAX)
- 其他: ad_tag (bitwise flag), target_roi (MAX), idx_roi_upperbound (MAX), final_coef (MAX), gmv_after_23pm (MAX), active_hour (MAX), tc_imp_count
- 注意: pricing_type, ads_id, campaign_id, item_id, plan_bucket_id 在 shop 级别为 null

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | USING parquet |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | 163 |
| Region Coverage | ID, PH, SG, TH, TW, MY, VN, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 44 files (19 write, 25 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
