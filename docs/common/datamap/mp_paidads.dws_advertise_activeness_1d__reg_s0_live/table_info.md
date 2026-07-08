<!-- ads-workspace-gdoc-sync: gdoc_id=1DZ7Jx-rCtKtompvgjetP1jSXmmIzxoHgpFCk9hAXmho gdoc_url=https://docs.google.com/document/d/1DZ7Jx-rCtKtompvgjetP1jSXmmIzxoHgpFCk9hAXmho/edit -->

# mp_paidads.dws_advertise_activeness_1d__reg_s0_live

## Description

- **Desc:** 广告主关键词广告激活日期表。从 dim_advertise 表中提取广告主首次投放关键词广告（MM Keyword / SM Keyword）的日期，用于分析广告主的广告激活行为。
- **Granularity:** daily x ads_id x shop_id x user_id x grass_region
- **Use Case:**
  - 追踪广告主各广告的首次关键词广告激活日期
  - 区分 Myammar Marketing (MM) Keyword 和 Search Marketing (SM) Keyword 两种关键词广告类型的首次激活时间
  - 按地区和日期分析广告激活活跃度
- **Update Frequency:** Daily

## Key Metrics

- 激活日期类: first_mm_kw_ads_active_date, first_sm_kw_ads_active_date

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 业务: ads_id, shop_id, user_id (seller_id)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dws_advertise_activeness_1d |
| Retention | - |
| Column Count | 8 |
| Region Coverage | VN, TW, TH, SG, PH, MY, MX, ID, CO, CL, BR (11 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 19 files (19 write, 0 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
