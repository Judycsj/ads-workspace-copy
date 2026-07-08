<!-- ads-workspace-gdoc-sync: gdoc_id=1ZLAwJevmMYQKU4mHFHzywR_h9-5MGQkfMN-aa4zV_CQ gdoc_url=https://docs.google.com/document/d/1ZLAwJevmMYQKU4mHFHzywR_h9-5MGQkfMN-aa4zV_CQ/edit -->

# mkplpaidads_search_ads.overall_supply_budget_metrics_daily__reg_s0_live

## Description

- **Desc:** 广告供给侧预算总览日报表，汇总每日活跃广告数、活跃广告主数、Campaign 有效预算、充值金额和账户余额，按 pricing_type 和 budget_type 维度展开（含 CUBE 汇总行 'all'）
- **Granularity:** daily × pricing_type × budget_type × region
- **Use Case:** 供给侧预算健康度监控、广告主活跃度趋势分析、预算充足率诊断、SOP 大盘巡检
- **Update Frequency:** Daily

## Key Metrics

- 活跃广告数: active_ads_cnt
- 活跃广告主数: active_advertiser_cnt
- Campaign 日有效预算: daily_valid_budget
- 充值金额: topup_amt_usd
- 账户余额: account_balance_usd

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: pricing_type, budget_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date, grass_region |
| HDFS Path | hdfs://R2/projects/mkplpaidads_search_ads/hive/mkplpaidads_search_ads/overall_supply_budget_metrics_daily__reg_s0_live |
| Retention | 720 days |
| Column Count | 9 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
| DQC Status | - |
| Table Size | 21.89 MB |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | qianqian.pu@shopee.com |
| Team | mkplpaidads |
| Project | Search Ads (mkplpaidads_search_ads) |
| Business Domain | - |
| DW Layer | - |
| Market Region | REG |

## Popularity

- Studio Tasks References: 4 files
- L7D Query Count: 7
- Completeness: 4.00
- Popularity: 43.80
