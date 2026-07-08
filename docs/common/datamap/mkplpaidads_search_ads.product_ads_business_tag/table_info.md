<!-- ads-workspace-gdoc-sync: gdoc_id=1Qa5FFpEywo_23mQhNJKRBbu-eDiHFPgeQIH0r0ls8kk gdoc_url=https://docs.google.com/document/d/1Qa5FFpEywo_23mQhNJKRBbu-eDiHFPgeQIH0r0ls8kk/edit -->

# mkplpaidads_search_ads.product_ads_business_tag

## Description

- **Desc:** 广告计划业务标签表。根据广告计划的出单表现、商品新鲜度、广告主历史等维度，为 Product Ads (ROI2/Simple) 的 campaign_id 打上业务标签（冷启动、空耗、空耗承接期、新品、新广告主等），供下游选品策略、出价调节和模型训练使用。
- **Granularity:** daily x campaign_id x pricing_type x business_tag x grass_region
- **Use Case:**
  - 冷启动选品 (passrate) — 筛选 npb/cold_start/empty_order_expand 标签的 campaign，接入潜力模型选品
  - Reserve 策略 — 按 business_tag (npb/cold_start) 分标签做覆盖率计算和分桶
  - 冷启动 Dashboard — 按标签维度查看 campaign 分布
- **Update Frequency:** Daily (workflow `libratags_productads_data_1d_bidding`)

## Key Metrics

- 无汇总指标列 — 该表仅包含 campaign_id 标识和分区分组维度，不具备数值度量列。
- 核心信息隐含在 business_tag 分区值中，每个标签代表一个业务判定结论。

## Key Dimensions

- 数据列: campaign_id (BIGINT) — 广告计划 ID
- 分区: grass_date (STRING) — 日期分区, grass_region (STRING) — 地区分区, pricing_type (INT) — 计费类型, business_tag (STRING) — 业务标签

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | pricing_type (INT), business_tag (STRING), grass_date (STRING), grass_region (STRING) |
| HDFS Path | - |
| Retention | - |
| Column Count | 1 data column + 4 partition columns |
| Region Coverage | ID, MY, VN, TH, PH, SG, TW, BR (8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 38 files (32 write, 6 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
