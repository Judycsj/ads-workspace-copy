<!-- ads-workspace-gdoc-sync: gdoc_id=1Slq8jKzPM8F8Z0hnwiXGs9peNTApOA9CE8k343ohq5w gdoc_url=https://docs.google.com/document/d/1Slq8jKzPM8F8Z0hnwiXGs9peNTApOA9CE8k343ohq5w/edit -->

# video.video_mart_dws_user_watch_basic_aggr_1d

## Description

- **Desc:** 用户视频观看行为基础聚合表（DWS层），记录每个用户每天在每个视频上的播放次数和观看时长等基本指标。属于 Shopee Video 数据仓库的汇总层，按天+地域+用户+视频粒度聚合。
- **Granularity:** daily x grass_region x user_id x video_id
- **Use Case:**
  - Discovery Ads: 计算 Video Entry Point 的广告曝光量和总曝光量（按 entry_point/ads_id 聚合 video_play_cnt_ntl_1d）
  - Search Ads (Content Ads): 基于视频播放量对关联商品进行视频排名和索引推荐（Top 10 视频 per item）
  - I2V Swing Score: 构建 user-to-item 二分图，计算 swing 分数（通过 video_id 和 user_id 关联）
- **Update Frequency:** Daily (推测)

## Key Metrics

- 播放类: video_play_cnt_ntl_1d, video_view_duration_ntl_1d
- 广告标识: is_item_ads, video_ads_type (用于区分广告曝光 vs 自然曝光)

## Key Dimensions

- 分区: grass_date, grass_region
- 用户: user_id
- 视频: video_id
- 内容分类: content_type, tz_type
- 来源/流量: sv_source_page, current_page, video_flow_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (从 WHERE 条件推断) |
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

- Studio Tasks References: 5 files (0 write, 5 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
