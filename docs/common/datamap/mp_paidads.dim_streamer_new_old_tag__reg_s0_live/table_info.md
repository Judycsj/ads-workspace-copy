<!-- ads-workspace-gdoc-sync: gdoc_id=16pF1on-BUaeBJP2Lb8RzHIW_E0URKMTIKmIYZpvXoP0 gdoc_url=https://docs.google.com/document/d/16pF1on-BUaeBJP2Lb8RzHIW_E0URKMTIKmIYZpvXoP0/edit -->

# mp_paidads.dim_streamer_new_old_tag__reg_s0_live

## Description

- **Desc:** 直播带货主（streamer）新旧标签维度表，存储每个带货主的多维标签和分层信息，包括新老广告主状态（today/month）、新老直播主状态、GMV 分层、直播 GMV 分层、收入分层、首末开播/投广日期、当日是否开播/产生收入等。上游数据来自 livestream 维表、广告主直播效果表、广告主直播累计收入表、卖家 GMV 表、直播主有机表现表。
- **Granularity:** daily x streamer_id x region
- **Update Frequency:** Daily

## Key Metrics

此表为维度表（dim），不含聚合指标。核心标签字段：
- 新老状态: today_new_advertiser_status, month_new_advertiser_status, new_ls_streamer_status
- 分层: advertiser_gmv_tier, advertiser_ls_gmv_tier, advertiser_rev_tier
- 活跃标识: is_streaming_today, is_rev_today

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 主播: streamer_id, streamer_type
- 店铺: shop_id, shop_level1_global_be_category, shop_level2_global_be_category
- 日期: streamer_first_streaming_date, streamer_last_streaming_date, streamer_first_live_ads_date, streamer_last_live_ads_date

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | ${HIVE_PATH}/dim_streamer_new_old_tag |
| Retention | - |
| Column Count | 17 + 3 partition |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 7 files (write) + 6 files (read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
