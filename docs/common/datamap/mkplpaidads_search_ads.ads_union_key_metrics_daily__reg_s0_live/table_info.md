<!-- ads-workspace-gdoc-sync: gdoc_id=11btLYr8dxH6aaa-07wzHnL6Mu_PjTi2hC_4J4zYQkLI gdoc_url=https://docs.google.com/document/d/11btLYr8dxH6aaa-07wzHnL6Mu_PjTi2hC_4J4zYQkLI/edit -->

# mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live

## Description

- **Desc:** 广告诊断统一指标日表 — 将 ads/item/campaign/shop 四个粒度的关键指标 UNION ALL 到一张表，包含广告效果（impression/click/order/GMV）、出价信号（bid/boost/deduction/coef）、模型预估（pctr/pcr/pgmv/padvv/ecpm）、广告漏斗（request→recall→prerank→rank→mixrank）、预算与余额、ROI 与 MPC、自动化功能状态、Campaign 行为变更、商品标签等。是广告诊断（ads-diagnose）的核心数据源，涵盖超收检测（A1）、pCOC 达标率监控、Peer Metrics、ad_tag 位运算过滤等场景。同时供 discovery_ads 和 cold_start 分析使用。存在两个 schema 版本：旧版 117 列（全地区一次性写入）和 with-omni 新版 164 列（单地区分别写入，含 Campaign 行为变更、商品标签、auto 功能等扩展字段）。
- **Granularity:** daily x type (ads/item/campaign/shop) x entrance x pricing_type x ads_id x campaign_id x item_id x shop_id x grass_region
- **Use Case:** 广告诊断全链路漏斗分析（request→recall→rank→mixrank→impression→click→order）、超收检测（A1: 7d cost_ratio > 1.25）、pCOC 达标率监控（campaign/item 维度）、出价系数与预估值分析（coef/pctr/pcr/pgmv/bid_price）、冷启动广告效果追踪（cold_start_dashboard）、预算使用率与充值分析、Campaign 行为变更追踪（pause/stop/budget/troi 调整）、Peer Metrics 对比（ads_agent_peer_metrics_daily）、ad_tag 位运算过滤（如 bit 13 检查）、数据完整性检查（SOP）
- **Update Frequency:** Daily

## Key Metrics

- 效果类 (1D): `revenue_usd`, `advv_usd`, `direct_gmv_usd`, `broad_gmv_usd`, `ads_imp`, `ads_clk`, `ads_direct_order`, `ads_broad_order`
- 效果类 (7D): `revenue_usd_7d`, `advv_usd_7d`, `broad_gmv_usd_7d`, `ads_imp_7d`, `ads_clk_7d`
- 出价信号: `bid_price_sum`, `boost_price_sum`, `gross_deduction_price_sum`, `net_deduction_price_sum`, `coef_sum_by_imp`
- 模型预估 (by imp): `pctr_sum_by_imp`, `pcr_direct_sum_by_imp`, `pcr_broad_sum_by_imp`, `pgmv_direct_sum_by_imp`, `final_pgmv_sum_by_imp`, `ecpm_sum_by_imp`
- 模型预估 (by clk): `pcr_direct_sum_by_clk`, `pgmv_direct_sum_by_clk`, `final_pgmv_sum_by_clk`, `ecpc_sum_by_clk`
- 广告漏斗: `request_cnt`, `after_recall_num`, `ads_after_recall_num`, `org_after_recall_num`, `after_prerank_num`, `after_rank_num`, `after_mixrank_num`
- pCOC 相关: `daily_pgmv_sum_last_7d_clk`, `daily_pay_pgmv_sum_last_7d_clk`, `daily_model_pgmv_sum_last_7d_clk`, `paid_broad_gmv_usd`
- 预算与余额: `valid_budget_campaign`, `daily_budget`, `topup_usd`, `account_balance_shop`
- ROI: `target_roi`, `idx_roi_upperbound`, `final_coef`, `mpc_e_gmv`, `mpc_e_cost`

## Key Dimensions

- 分区: `grass_date`, `grass_region`
- 业务: `type` (ads/item/campaign/shop), `entrance`, `pricing_type`, `plan_bucket_id`
- 实体: `ads_id`, `campaign_id`, `item_id`, `shop_id`
- 分层: `under_bidding_tier_1d/7d`, `campaign_order_tier_1d/7d`, `budget_tier`, `pcoc_tier`, `shop_gmv_tier`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_date (date) / grass_region (string) — 二级分区 |
| HDFS Path | hdfs://R2/projects/mkplpaidads_search_ads/hive/mkplpaidads_search_ads/ads_union_key_metrics_daily__reg_s0_live |
| Retention | Permanent |
| Column Count | 164 数据列 + 2 分区列 (with-omni 新版); 117 数据列 + 2 分区列 (旧版) |
| Region Coverage | ID, PH, SG, TH, TW, MY, VN, BR |
| DQC Status | - |
| Table Size | 8.73 TB |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | qianqian.pu@shopee.com, yuquan.wang@shopee.com |
| Team | mkplpaidads |
| Project | Search Ads(mkplpaidads_search_ads) |
| Business Domain | - |
| DW Layer | ADS |
| Market Region | REG |

## Popularity

- Studio Tasks References: 69 files (27 write, 42 read)
- L7D Query Count: 338
- Completeness: 12.00
- Popularity: 96.80
