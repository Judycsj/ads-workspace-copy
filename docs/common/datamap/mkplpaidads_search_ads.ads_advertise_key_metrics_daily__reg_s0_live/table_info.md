<!-- ads-workspace-gdoc-sync: gdoc_id=1Kii1RMyTluSDuVdMR_whztTVX2jryQlH2lCtkEzxq_o gdoc_url=https://docs.google.com/document/d/1Kii1RMyTluSDuVdMR_whztTVX2jryQlH2lCtkEzxq_o/edit -->

# mkplpaidads_search_ads.ads_advertise_key_metrics_daily__reg_s0_live

## Description

- **Desc:** Search Ads 广告粒度的核心指标日表,覆盖收入、GMV、订单、曝光点击、扣费、出价模型预估、全链路漏斗、预算状态、货品标签、自动化功能等全维度指标。是 Search Ads 诊断体系的底层基础表,向上汇总为 campaign / seller / item / union 聚合表
- **Granularity:** daily x grass_region x ads_id x pricing_type x entrance (scene)
- **Use Case:**
  - Search Ads 广告级核心指标日常监控与诊断 (ads_diagnosis 下游)
  - Campaign / Seller / Item / Union 聚合表的源数据
  - 出价 ROI、预算命中、PCOC 校准分析
  - DQC 数据质量监控 (覆盖率指标)
  - 广告分析 SOP 与手动排查
- **Update Frequency:** Daily (每日 T+1 调度,按 region 分 task 写入)

## Key Metrics

- 收入与花费类: revenue_usd, advv_usd, revenue_usd_7d, advv_usd_7d
- GMV 类: direct_gmv_usd, broad_gmv_usd, broad_gmv_usd_7d, noimp_gmv, paid_broad_gmv_usd, paid_broad_gmv_usd_7d, model_broad_gmv_usd
- 订单类: ads_direct_order, ads_broad_order, ads_broad_order_7d, ads_paid_order, ads_paid_order_7d
- 曝光点击类: ads_imp, ads_clk, ads_imp_7d, ads_clk_7d, raw_ads_imp, raw_ads_clk, deduct_imp, deduplicated_click, resp_ads_imp
- 扣费类: expect_deduction_price_sum_raw, expect_deduction_price_sum_valid, gross_deduction_price_sum, net_deduction_price_sum, raw_deduction_cnt, valid_deduction_cnt, bid_price_sum, boost_price_sum
- 出价模型 (by imp): troi_sum_by_imp, troi_max_by_imp, troi_min_by_imp, coef_sum_by_imp, coef_min_by_imp, coef_max_by_imp, pctr_sum_by_imp, pcr_direct_sum_by_imp, pcr_broad_sum_by_imp, pcr_direct_fail_imp_cnt
- 预估 GMV (by imp): pgmv_direct_sum_by_imp, pgmv_broad_sum_by_imp, final_pgmv_sum_by_imp, padvv_sum_by_imp, ecpm_sum_by_imp
- 出价模型 (by clk): pcr_direct_sum_by_clk, pcr_broad_sum_by_clk, pgmv_direct_sum_by_clk, pgmv_broad_sum_by_clk, final_pgmv_sum_by_clk, padvv_sum_by_clk, ecpc_sum_by_clk
- 全链路漏斗: request_cnt, after_recall_num, ads_after_recall_num, org_after_recall_num, after_prerank_num, after_rank_num, after_mixrank_num
- 预算相关: rt_remain_budget_sum_by_imp, rt_remain_budget_min_by_imp, rt_remain_budget_max_by_imp, rt_daily_budget_min_by_imp
- 货品信息: sold_cnt_sum_by_imp, item_price_sum_by_imp, stock, shop_gmv_tier, hot_item_tag, potential_item_tag, new_item_tag, winner_item_tag, cheapest_item_tag
- PCOC 校准: daily_padvv_sum_last_7d_clk, daily_pgmv_sum_last_7d_clk, daily_pay_pgmv_sum_last_7d_clk, daily_model_pgmv_sum_last_7d_clk
- Omni 跨平台: ads_imp_cnt, ads_clk_cnt, ads_order_cnt, ads_gmv_usd, total_imp, total_clk, total_order, total_gmv, total_add_to_cart_cnt, total_seller_gmv_usd
- 层级标签: under_bidding_tier_1d, under_bidding_tier_7d, campaign_order_tier_1d, campaign_order_tier_7d, budget_tier, hit_valid_budget_tier, hit_daily_budget_tier, hit_account_balance_tier, pcoc_tier
- 静态属性: target_roi, idx_roi_upperbound, ultra_core_rev, ultra_core_advv, final_coef, mpc_e_gmv, mpc_e_cost, gmv_after_23pm, active_hour, is_active_after_20pm, daily_budget, valid_budget_campaign, topup_usd, account_balance_shop, manual_free_credit_topup_amt_1d, shop_adopts_gms
- 自动化功能: is_rapid_boost_on, is_auto_topup_enabled, auto_topup_daily_cap_amt_usd, auto_topup_amt_usd, auto_topup_threshold_amt_usd, is_auto_escrow_enabled, auto_escrow_fixed_program_fee_rate, auto_escrow_additional_fee_rate, is_auto_budget_increase_enabled, auto_budget_increase_percentage, auto_budget_increase_daily_cap, is_roi_three_voucher_enabled
- Campaign 变更: campaign_pause_cnt, campaign_stop_cnt, troi_increase_cnt, troi_decrease_cnt, troi_mode_switch_cnt, finite_budget_increase_cnt, finite_budget_decrease_cnt, unlimited_budget_on_cnt, unlimited_budget_off_cnt, max_budget_decrease_magnitude, troi_change_direction, budget_change_direction, is_campaign_surge_enabled
- 名称: campaign_name, item_name, shop_name
- 计数: ads_cnt, campaign_cnt, shop_cnt, item_cnt
- 其他: tc_imp_count (冷启曝光数), ad_tag, bid_rerank_trace_null_cnt, is_ocpm

## Key Dimensions

- **分区**: grass_date (date), grass_region (string) — 范围覆盖 TH, PH, VN, MY, TW, SG, ID, BR 8 个国家
- **业务维度**: entrance (scene / entry point), pricing_type, entrance
- **ID 维度**: ads_id, campaign_id, item_id, shop_id
- **层级标签 (tier)**: under_bidding_tier_1d, under_bidding_tier_7d, campaign_order_tier_1d, campaign_order_tier_7d, budget_tier, hit_valid_budget_tier, hit_daily_budget_tier, hit_account_balance_tier, pcoc_tier
- **店铺/货品属性**: shop_level1_global_be_category, shop_level2_global_be_category, plan_bucket_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | 166 (164 data + 2 partition) |
| Region Coverage | TH, PH, VN, MY, TW, SG, ID, BR (8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap,请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 76 files (22 write, 54 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
