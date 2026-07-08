<!-- ads-workspace-gdoc-sync: gdoc_id=1-ZZY4-60T8mKnW1yHuCk6D2FgaJPDcLMK9mSKPoDTnE gdoc_url=https://docs.google.com/document/d/1-ZZY4-60T8mKnW1yHuCk6D2FgaJPDcLMK9mSKPoDTnE/edit -->

# mkplpaidads_search_ads.ads_item_key_metrics_daily__reg_s0_live

## Description

- **Desc:** Search Ads 商品粒度核心指标日表。有两套生产工作流: (1) qq 版本: 从 ads_advertise_key_metrics_daily (广告粒度) 按 `item_id + entrance + grass_region + grass_date` 聚合; (2) with_omni 版本: 自读上日分区 + FULL OUTER JOIN omni_core_key_metrics_merge_daily (补全链路流量) + dws_omni_item_shop_entrance_metrics_daily (补卖家 GMV) + LEFT JOIN dim_omni_item_shop_attr_daily (补商品/店铺名称和标签)。覆盖搜索广告全链路漏斗、出价扣费、模型分、预算和店铺/商品属性等维度的商品级数据。
- **Granularity:** daily x item_id x entrance x grass_region (每行代表某天某地区某入口下的某商品汇总)
- **Use Case:**
  - 搜索广告诊断分析 (arrive_pcoc 等, 验证 PCOC 预估有效性)
  - 作为 ads_union_key_metrics_daily 的 item 类型数据源 (UNION ALL 聚合, 与 ads/campaign/shop 类型并列)
  - 商品粒度的广告效果分析 (营收、订单、ROI、新增/爆品分析)
  - 商品粒度的预算/消耗/出价/扣费分析
  - with_omni 版本支持全链路 (含自然) 指标分析 (total_imp, total_order, total_gmv, total_add_to_cart_cnt)
- **Update Frequency:** Daily (`${ISO_YESTERDAY}` 分区, workflow 调度, 各地区并行写入)

## Key Metrics

- 收入类: revenue_usd, advv_usd, direct_gmv_usd, broad_gmv_usd, noimp_gmv
- 7日累计: revenue_usd_7d, advv_usd_7d, ads_broad_order_7d, broad_gmv_usd_7d, ads_imp_7d, ads_clk_7d
- 订单类: ads_direct_order, ads_broad_order, ads_order_cnt, total_order, ads_paid_order, ads_paid_order_7d
- 曝光/点击: ads_imp, ads_clk, ads_imp_cnt, ads_clk_cnt, total_imp, total_clk, raw_ads_imp, raw_ads_clk, deduplicated_click
- 漏斗: request_cnt, after_recall_num, ads_after_recall_num, org_after_recall_num, after_prerank_num, after_rank_num, after_mixrank_num, resp_ads_imp
- 出价/扣费: bid_price_sum, boost_price_sum, expect_deduction_price_sum_raw/valid, gross_deduction_price_sum, net_deduction_price_sum, raw_deduction_cnt, valid_deduction_cnt
- 模型分/预估 (by_imp): troi_sum/max/min_by_imp, rt_remain_budget_sum/min/max_by_imp, pctr_sum_by_imp, pcr_direct/broad_sum_by_imp, pgmv_direct/broad_sum_by_imp, final_pgmv_sum_by_imp, padvv_sum_by_imp, ecpm_sum_by_imp, sold_cnt_sum_by_imp, item_price_sum_by_imp, coef_sum/min/max_by_imp
- 模型分/预估 (by_clk): pcr_direct/broad_sum_by_clk, pgmv_direct/broad_sum_by_clk, final_pgmv_sum_by_clk, padvv_sum_by_clk, ecpc_sum_by_clk
- 预算相关: valid_budget_campaign, topup_usd, daily_budget, account_balance_shop, manual_free_credit_topup_amt_1d, rt_daily_budget_min_by_imp
- 商品属性: target_roi, idx_roi_upperbound, ultra_core_rev, ultra_core_advv, final_coef, mpc_e_gmv, mpc_e_cost, stock
- 派生指标: pcoc_tier, ad_tag (bit位提取)
- 商品/店铺标签: shop_adopts_gms, shop_gmv_tier, hot_item_tag, potential_item_tag, new_item_tag, winner_item_tag, cheapest_item_tag
- PaaS/自动化: is_rapid_boost_on, is_auto_topup_enabled, auto_topup_*, is_auto_escrow_enabled, auto_escrow_*, is_auto_budget_increase_enabled, auto_budget_increase_*, is_roi_three_voucher_enabled, is_campaign_surge_enabled
- 操作统计: campaign_pause/stop_cnt, troi_increase/decrease/mode_switch_cnt, finite_budget_increase/decrease_cnt, unlimited_budget_on/off_cnt, max_budget_decrease_magnitude, troi_change_direction, budget_change_direction
- 全链路 (omni): total_add_to_cart_cnt, total_seller_gmv_usd
- 近期GMV: daily_padvv_sum_last_7d_clk, daily_pgmv_sum_last_7d_clk, daily_pay_pgmv_sum_last_7d_clk, daily_model_pgmv_sum_last_7d_clk
- Paid: paid_broad_gmv_usd, paid_broad_gmv_usd_7d, model_broad_gmv_usd

## Key Dimensions

- 分区: grass_date, grass_region
- 核心维度: entrance, item_id, shop_id
- 分类: shop_level1_global_be_category, shop_level2_global_be_category
- Tier维度: under_bidding_tier_1d/7d, campaign_order_tier_1d/7d, budget_tier, hit_valid_budget_tier, hit_daily_budget_tier, hit_account_balance_tier, pcoc_tier
- 名称: campaign_name, item_name, shop_name
- (qq 版本中为 null, 保留用于 union 对齐): plan_bucket_id, pricing_type, ads_id, campaign_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | parquet |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | 163 (最新 DDL, 含多次 ALTER TABLE ADD COLUMNS 扩展) |
| Region Coverage | ID, PH, SG, TH, TW, MY, VN, BR (标准8地区, 含 qq_us 和 with_omni_us BR 变体) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap, 请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 32 files (19 write, 13 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
