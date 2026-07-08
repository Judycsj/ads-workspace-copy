<!-- ads-workspace-gdoc-sync: gdoc_id=1mMjHSqsN4nLiuL-9QsVjYfs4Brr32AAxgS2uHnHPE2U gdoc_url=https://docs.google.com/document/d/1mMjHSqsN4nLiuL-9QsVjYfs4Brr32AAxgS2uHnHPE2U/edit -->

# livestream.ls_mart_dim_streamer

## Description

- **Desc:** 直播主播维度表，提供主播的 streamer_id 到 streamer_type 和 streamer_shop_id (shop_id) 的映射关系，用于将广告效果数据按主播类型（KOL/Seller/MCN）进行归因和分类分析。
- **Granularity:** daily x grass_region x streamer_id
- **Use Case:**
  1. Live Ads Tracker -- 按主播类型(streamer_type) x 出价类型(pricing_type)分解直播广告表现指标，计算各分组的消耗、曝光、GMV、订单等
  2. 出价分析(bidding analysis) -- 将 bidding log 与 streamer_type 关联，分析 KOL/Seller/MCN 的出价达成率和 ROI 分布
  3. Take Rate 分析 -- 通过 streamer_type 分组计算不同主播类型的广告 take rate
  4. 预算分析(budget analysis) -- 按 KOL/Seller/MCN 分组追踪预算消耗率和上限触达率
  5. GMV 延迟转化模型 -- 筛选 KOL 或非 KOL 主播，构建分国家的 GMV 延迟预估特征
  6. PCOC 校准分析 -- 关联 streamer_type 和 shop_id 分析预估偏差
- **Update Frequency:** Daily

## Key Metrics

本表为维度表，不直接产出指标。下游查询通过关联本表获取 streamer_type 后聚合以下指标：
- 收入类: ads_rev_usd, ads_expenditure_usd, net_ads_revenue_usd_1d
- 效果类: impression, view, click, order, order_gmv_usd, broad_gmv_usd
- 预算类: campaign_strategy_valid_budget_usd, budget_or_balance_exhausted

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 业务: streamer_type (核心分类维度), streamer_id, streamer_shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date (推断: daily) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, VN, TH, MY, PH, TW, SG |
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

- Studio Tasks References: 63 files (63 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
