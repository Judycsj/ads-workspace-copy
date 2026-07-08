<!-- ads-workspace-gdoc-sync: gdoc_id=1apF6n9aixE6XtI08NmJTIEbIW6cZokshc2GPT9Pkzik gdoc_url=https://docs.google.com/document/d/1apF6n9aixE6XtI08NmJTIEbIW6cZokshc2GPT9Pkzik/edit -->

# livestream.ls_mart_dim_ls_session

## Description

- **Desc:** 直播场次维度表（Live Session Dimension），来自 livestream 数据集市，记录每次直播的基础元信息，包括主播、店铺、起止时间、直播时长等。在广告场景中，主要用于将直播广告效果数据与直播场次关联，筛选满足时长条件的有效直播场次。
- **Granularity:** 每行 = 一个 `ls_session_id` per `grass_date` per `grass_region` per `tz_type`
- **Use Case:**
  - 直播广告 ROI 分析：筛选 >=2 小时的直播场次，计算广告 GMV/Revenue/Order
  - 直播场次广告渗透率统计：计算投广告的直播场次占整体直播的比例
  - 主播活跃度跟踪：通过 `streamer_id` + `grass_date` 判断主播当日是否开播
  - 直播广告效果归因：通过 `ls_session_id` 将曝光/点击/订单与直播场次关联
- **Update Frequency:** Daily（推测）

## Key Metrics

本表是维度表，不包含度量指标。下游查询中常用的聚合指标：
- `count(distinct ls_session_id)` — 直播场次数
- `ls_session_duration / 3600000` — 直播时长（小时）

## Key Dimensions

- 分区维度: grass_date, grass_region, tz_type
- 业务维度: ls_session_id, streamer_id, streamer_shop_id (shop_id)
- 时间维度: start_time, end_time, start_timestamp

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在代码库中找到，表属于 livestream 命名空间) |
| Partition Columns | grass_date, grass_region, tz_type (推测) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, VN, TH, MY, PH, TW, SG, BR (从实际查询推断) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | Livestream |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 4 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
