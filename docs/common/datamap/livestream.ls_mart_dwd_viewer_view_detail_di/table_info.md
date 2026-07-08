<!-- ads-workspace-gdoc-sync: gdoc_id=12tM-5YzKjofVuRUvrvHVjM2E3bbK04In7s4HzC2Wy0Q gdoc_url=https://docs.google.com/document/d/12tM-5YzKjofVuRUvrvHVjM2E3bbK04In7s4HzC2Wy0Q/edit -->

# livestream.ls_mart_dwd_viewer_view_detail_di

## Description

- **Desc:** 直播用户观看事件明细表 (Livestream Viewer View Detail Table)。记录用户在直播间的每一次观看(view)事件，包含用户、主播、会话、场景来源和推荐渠道等元信息。`data` 字段为 JSON，存储推荐链路信息（recommendation_info）和来源渠道（from_source），是区分推荐流量来源（自然推荐 vs 广告推荐）的核心依据。
- **Granularity:** daily x region x tz_type x event (event-level detail)
- **Use Case:**
  - 直播广告场景分析：通过 `data.recommendation_info` 识别广告推荐（CHAN:ADS）vs 自然推荐，计算推荐 DAU/观看/时长
  - 直播自然流量表现：按 scene 分类统计观看量、推荐观看量、广告推荐观看量
  - 用户行为归因：通过 `ls_session_id` + `user_id` + `event_id` 关联观看时长表 (`ls_mart_dwd_view_streaming_detail_di`)
  - 直播会话流量分析：关联 session 维度表 (`ls_mart_dim_ls_session`) 获取直播间完整流量画像
- **Update Frequency:** Daily (推测，由上游 ODS 表每日更新)

## Key Metrics

- 观看次数: `COUNT(1)` 按场景/主播聚合
- 推荐观看: `COUNT(IF(scene NOT IN ('','non','livestream_pdp','livestream_game'), 1, NULL))`
- 广告推荐观看: `COUNT(IF(if_ads=1 AND scene NOT IN ('','non','livestream_pdp','livestream_game'), 1, NULL))`
- 推荐 DAU: `COUNT(DISTINCT user_id)` with `if_rcmd=1`
- 广告推荐 DAU: `COUNT(DISTINCT CASE WHEN if_ads=1 THEN user_id END)`

## Key Dimensions

- 分区: `grass_date`, `grass_region`, `tz_type`
- 主播: `streamer_id`
- 用户: `user_id`
- 会话: `ls_session_id`
- 场景: `scene` — 区分全屏滑动(slide/livestream_fullscreen)、自动落地(livestream_default_tab)、视频页(livestream_video_*)等
- 推荐来源: `data.recommendation_info` — 区分 CHAN:ADS (广告) / dispatch:ads / 自然推荐等
- 推荐入口: `data.from_source` — 落地来源信息

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (未在代码库中找到 DDL) |
| Partition Columns | grass_date (DATE), grass_region (STRING), tz_type (STRING) — inferred from WHERE clauses |
| HDFS Path | - |
| Retention | - |
| Column Count | ~11 (inferred from SELECT columns) |
| Region Coverage | ID, VN, TH, MY, PH, TW, SG, BR (standard 8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 27 files (16 workflows, 1 scheduled, 10+ manual)
- L7D Query Count: -
- Completeness: -
- Popularity: -
