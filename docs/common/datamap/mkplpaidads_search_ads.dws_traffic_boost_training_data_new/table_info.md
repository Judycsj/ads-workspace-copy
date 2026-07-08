<!-- ads-workspace-gdoc-sync: gdoc_id=1TvPTrCawll1ng-Dd2MwqsPfVzufW18fDWBS3ZLGg8cE gdoc_url=https://docs.google.com/document/d/1TvPTrCawll1ng-Dd2MwqsPfVzufW18fDWBS3ZLGg8cE/edit -->

# mkplpaidads_search_ads.dws_traffic_boost_training_data_new

## Description

- **Desc:** Traffic Boost replay log training data, containing simulated campaign performance at different bid coefficient (coef) levels. Built from real-time bidding replay logs to model the relationship between ad spend and outcomes (orders/GMV) for traffic boost campaigns.
- **Granularity:** daily x region x ads_id x coef x time_window
- **Use Case:**
  - Model training data: fitting budget-to-outcome saturation curves (exponential, power law, etc.)
  - Campaign performance calibration: computing ecpm2 increase factors relative to baseline (coef=10000)
  - Budget optimization: estimating optimal daily budget to maximize orders/GMV within constraints
  - Historical feature enrichment: joining posterior predictions for black-box model training
  - B2X evaluation: comparing simulated vs actual order/GMV performance across coefficient levels
- **Update Frequency:** Daily (T-1)

## Key Metrics

- 模拟效果类: porder (predicted orders), pgmv (predicted GMV), pv (predicted impressions), ecpm2 (estimated revenue)
- 预算类: campaign_daily_budget_local, campaign_daily_budget_usd, campaign_valid_budget_local, campaign_valid_budget_usd
- 乘数类: ecpm2_increase_factor (ecpm2 ratio vs baseline coef=10000)
- 参数类: coef (bid coefficient), time_window (aggregation window)

## Key Dimensions

- 分区: grass_date, grass_region
- 实体: ads_id, campaign_id
- 参数: coef (bid coefficient, 10000 = baseline), time_window ('1t', '1h', '1d')

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | 14 (12 data + 2 partition) |
| Region Coverage | 8 regions: SG, MY, ID, PH, TH, VN, TW, BR |
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

- Studio Tasks References: 64 files (1 write, 63 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
