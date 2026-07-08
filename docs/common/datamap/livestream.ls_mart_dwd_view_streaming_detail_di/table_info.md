<!-- ads-workspace-gdoc-sync: gdoc_id=19nO87Zbf-zNUE4GUk93gPdMusp_PZnMYRhukukvLrCE gdoc_url=https://docs.google.com/document/d/19nO87Zbf-zNUE4GUk93gPdMusp_PZnMYRhukukvLrCE/edit -->

# livestream.ls_mart_dwd_view_streaming_detail_di

## Description

- **Desc:** 直播流观看详情明细表（DWD 层），记录用户每次直播观看事件的详细数据，包含观看者 ID、观看事件 ID、观看时长 (duration_b) 等核心字段
- **Granularity:** event-level（一次观看事件一行，按 grass_date + grass_region 分区）
- **Use Case:**
  - Discovery Ads Live 内容指标计算：提取直播观看时长 (duration_b)，与 session 表 JOIN 获取 platform/app_version/shop_id 维度
  - 用户特征宽表构建：作为 content_live_ads_view_duration 指标的数据源，汇入用户级全链路特征表
- **Update Frequency:** Daily (from table suffix `_di`)

## Key Metrics

- 观看时长类: duration_b（观看时长，SUM 聚合为 content_live_ads_view_duration）

## Key Dimensions

- 分区: grass_date, grass_region
- 时区: tz_type
- 用户: viewer_id
- 事件: view_event_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | - |
| DQC Status | - |
| Table Size | - |

## Business Properties

*未抓取 DataMap，请运行 --source from-di 补充*

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 3 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
