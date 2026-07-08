<!-- ads-workspace-gdoc-sync: gdoc_id=1yihjW8C9UrGu_QodnJkmuZ0YWlZyy5Oy9Is78wNA3Rc gdoc_url=https://docs.google.com/document/d/1yihjW8C9UrGu_QodnJkmuZ0YWlZyy5Oy9Is78wNA3Rc/edit -->

# livestream.ls_mart_dwd_traffic_ls_session_view_detail_di

## Description

- **Desc:** 直播流量 Session 级别的用户浏览明细表，记录用户在直播间内的每次操作事件（view/click），包含用户身份、主播信息、场景来源、操作类型和目标类型等维度。属于 livestream 域的 DWD 层，由 Live Streaming 团队生产，用于下游广告效果归因和内容电商指标计算。
- **Granularity:** daily x grass_region x event (每行 = 一次用户操作事件)
- **Use Case:**
  - 直播广告 CVR 模型训练样本构造（提取广告曝光 view 事件，关联广告点击下单数据生成训练集）
  - 内容电商全渠道归因（直播广告带来的 view/click 指标聚合，区分 ads vs organic）
  - 直播观看时长计算（通过 view_event_id 关联 duration 表）
- **Update Frequency:** Daily

## Key Metrics

*此表为明细事件表，本身不含聚合指标。下游通过以下聚合方式使用：*
- 流量类: COUNT(DISTINCT event_id) for view/click counts
- 时长类: SUM(duration_b) via JOIN with ls_mart_dwd_view_streaming_detail_di
- CVR 特征: regexp_extract(data, ...) 提取模型分（RNKMOD, ADSRNKMOD）、请求ID（REQID）、广告频道标记（CHAN:ADS）

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 业务: page_type (streaming_room), operation (view/click), scene, streamer_id, shop_id
- 用户: user_id, app_version, platform
- 事件: event_id, ls_session_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | Multi-region (ID confirmed, likely standard 8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 4 files (2 unique logical tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
