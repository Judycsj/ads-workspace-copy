<!-- ads-workspace-gdoc-sync: gdoc_id=1eIQRJLbgXA1P0WSTQ5HDRHep2K8kVPPfUTGQyt16Tvc gdoc_url=https://docs.google.com/document/d/1eIQRJLbgXA1P0WSTQ5HDRHep2K8kVPPfUTGQyt16Tvc/edit -->

# mkplpaidads_search_ads.daily_target2_algo_dim_ads

## Description

- **Desc:** Target ROI2 (pricing_type=11) 搜索广告的天级别 ads 维度算法宽表。每行代表一个 ROI2 搜索广告在某天某区域的表现，包含基础属性（ads_id, campaign_id, shop_id）、预计算的分层标签（status_tag, budget_tier, cost_tier, order_tier, achive_tag_1d）、1d/7d 核心指标（曝光/点击/消耗/GMV/advv），以及 995 分位数截断后的指标和 bid/advertiser delta 派生指标。由 `ads_advertise_roi2_key_metrics_daily__reg_s0_live` + `index_ads_info_log` 每日生产。
- **Granularity:** daily x ads_id x grass_region
- **Use Case:**
  - Target ROI2 算法出价日常监控（bucket_data_monitor / bidding_daily_report）
  - 广告分 bucket/plan/预算层/订单层/达标标签的效果分析（target_ads_bucket_exp, ads_bucket_target_perf）
  - 算法达成率 A/B 实验效果评估（target_achieve_exp）
  - MPC PCOC 校准效果分析（mpc_ts_cali）
  - ROI2 模型训练特征数据 join（train_data）
  - 多层级聚合报告（perf_ana_by_tag, roi2_perf_overall）
- **Update Frequency:** Daily（每日 T+1 调度，SEA 八区和 BR 分别写入）

## Key Metrics

- 消耗类: cost_usd_1d, cost_usd_7d, cost_usd_1d_net, valid_budget_usd
- 效果类: impression_1d, click_1d, broad_order_1d, broad_gmv_usd_1d
- 广告价值类: advv_usd_1d, advv_usd_7d, cpa_usd, target_roi
- 截断类: broad_gmv_usd_1d_995, advv_usd_1d_995（995分位数 capped）
- 派生类: delta_advv（日均超额advv）, delta_cost（日均超额消耗）

## Key Dimensions

- 分区: grass_date, grass_region
- 广告标识: ads_id, campaign_id, item_id, shop_id
- 投放属性: placement, pricing_type, target_roi
- 分桶: ad_bucket (ads_id % 1103 % 10), plan_id, plan_id_l2
- 分层标签: status_tag, hit_budget_flag, budget_tier, cost_tier, order_tier, achive_tag_1d, achive_tag_7d

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | 32 (base) / 34 (Spark version with achive_tag_7d + plan_id_l2) |
| Region Coverage | ID, SG, TH, PH, TW, MY, VN, BR（BR 与其他区域分区日期偏移 -1 天） |
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

- Studio Tasks References: 40 files (5 write, 35 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
