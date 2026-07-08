<!-- ads-workspace-gdoc-sync: gdoc_id=1vE7KjBqy6XoWG3hyP8bnwHreHARVPkEF-sOZUnC8iMs gdoc_url=https://docs.google.com/document/d/1vE7KjBqy6XoWG3hyP8bnwHreHARVPkEF-sOZUnC8iMs/edit -->

# mkplpaidads_search_ads.ads_campaign_key_metrics_daily__reg_s0_live

## Description

- **Desc:** Search Ads 广告 campaign 粒度关键指标天表。从 `ads_advertise_key_metrics_daily__reg_s0_live`（ad 粒度）按 campaign 维度聚合，包含收入、出价、扣费、投中预估、链路漏斗、模型预估、Omni 渠道等多维度指标，并派生 under_bidding / budget / pcoc 等分层标签。
- **Granularity:** daily x campaign_id x entrance x pricing_type x region
- **Use Case:**
  - Search Ads campaign 粒度出价诊断与 bid tier 分析
  - Campaign 预算分层与预算命中率监控
  - PCOC 模型预估准确性评估
  - Campaign 操作行为分析（暂停/停止/tROI调整/预算变更）
  - 大盘 overall key metrics 表的底层数据源（通过 grouping sets 聚合）
- **Update Frequency:** Daily (workflow 调度)

## Key Metrics

- 收入类: revenue_usd, advv_usd, direct_gmv_usd, broad_gmv_usd, noimp_gmv
- 7天回溯: revenue_usd_7d, advv_usd_7d, ads_broad_order_7d, broad_gmv_usd_7d, ads_imp_7d, ads_clk_7d
- 效果类: ads_direct_order, ads_broad_order, ads_imp, ads_clk, ads_order_cnt, ads_gmv_usd
- 扣费类: bid_price_sum, boost_price_sum, expect_deduction_price_sum_raw/valid, gross_deduction_price_sum, net_deduction_price_sum, raw_deduction_cnt, valid_deduction_cnt
- 投中数据: troi_sum_by_imp, rt_remain_budget_sum_by_imp, sold_cnt_sum_by_imp, item_price_sum_by_imp, coef_sum_by_imp
- 预估类: pctr_sum_by_imp, pcr_direct/broad_sum_by_imp/clk, pgmv_direct/broad_sum_by_imp/clk, final_pgmv_sum_by_imp/clk, padvv_sum_by_imp/clk, ecpm/ecpc_sum
- 链路漏斗: request_cnt, after_recall_num, ads_after_recall_num, org_after_recall_num, after_prerank_num, after_rank_num, after_mixrank_num
- 模型预估: daily_advv_sum_last_7d_clk, daily_pgmv_direct/broad_sum_last_7d_clk, daily_pgmv_sum_last_7d_clk
- 预算/余额: valid_budget_campaign, daily_budget, topup_usd, manual_free_credit_topup_amt_1d, account_balance_shop
- Ultra Core: ultra_core_rev, ultra_core_advv
- 店铺运营: shop_adopts_gms, is_rapid_boost_on, is_auto_topup_enabled, auto_topup_daily_cap_amt_usd, is_auto_escrow_enabled, is_auto_budget_increase_enabled, is_campaign_surge_enabled
- Campaign 操作: campaign_pause_cnt, campaign_stop_cnt, troi_increase_cnt, troi_decrease_cnt, troi_mode_switch_cnt, finite_budget_increase_cnt, finite_budget_decrease_cnt, unlimited_budget_on_cnt, unlimited_budget_off_cnt, max_budget_decrease_magnitude
- Paid Order 类: ads_paid_order, ads_paid_order_7d, paid_broad_gmv_usd, paid_broad_gmv_usd_7d, model_broad_gmv_usd
- Item 标签: hot_item_tag, potential_item_tag, new_item_tag, winner_item_tag, cheapest_item_tag
- 综合渠道: total_imp, total_clk, total_order, total_gmv, resp_ads_imp, total_add_to_cart_cnt, ads_imp_cnt, ads_clk_cnt
- 计数: ads_cnt, campaign_cnt, shop_cnt, item_cnt

## Key Dimensions

- 分区: grass_date, grass_region
- 核心维度: campaign_id, entrance, pricing_type
- 店铺属性: shop_id, shop_level1_global_be_category, shop_level2_global_be_category
- 分层标签: under_bidding_tier_1d/7d, campaign_order_tier_1d/7d, budget_tier, hit_valid_budget_tier, hit_daily_budget_tier, hit_account_balance_tier, pcoc_tier

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (USING parquet) |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | 164 (含 is_ocpm, 2026-06-09 ALTER TABLE 新增) |
| Schema Alter History | 2026-04-28: +33 BR 扩展列 (seller ops/ads ops); 2026-05-20: +3 名称列; 2026-06-02: +total_seller_gmv_usd; 2026-06-09: +is_ocpm |
| Region Coverage | ID, PH, SG, TH, TW, MY, VN, BR (from WHERE grass_region IN) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 51 files (19 write + 4 schema alter + 28 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
