<!-- ads-workspace-gdoc-sync: gdoc_id=1Q_upJDXQgqvrJ5wlmynIABPdIa1c9BInu67LMhSvKJk gdoc_url=https://docs.google.com/document/d/1Q_upJDXQgqvrJ5wlmynIABPdIa1c9BInu67LMhSvKJk/edit -->

# livestream.ls_mart_dwd_traffic_ls_session_impression_detail_di

## Description

- **Desc:** Livestream 直播间 traffic 曝光明细表（DWD 层，天级增量）。记录用户在直播场景各页面位置（page_type × page_section × target_type）的曝光事件（impression），包含推荐算法标识（CHAN:ADS / dispatch:ads）用于区分广告流量与自然流量。由 Livestream 团队产出，Ads 团队消费用于 Tracker 指标计算和 Shop 级别分析。
- **Granularity:** Daily × grass_region × tz_type × operation × ls_session_id × user_id ×曝光事件
- **Use Case:**
  1. **Live Ads Tracker - Organic 指标**: 计算各 streamer 的自然曝光量（按 page_type/page_section/target_type 分类）、DAU，汇总到 ads_livestream_tracker_org_metric_1d
  2. **Live Ads Tracker - Ads 指标**: 判定 streamer 当天是否有 Live Ads 曝光（has_imp），用于 active_live_ads_streamer_cnt 计算
  3. **Shop-level 性能分析**: 计算 shop 维度的曝光（含广告曝光）、点击，用于 bidding metrics dashboard 和 ROAS calibration
  4. **分来源曝光分析**: 按 from_source（tab / home / pdp_nonseller / fullmode_slide / autolanding 等）分类统计曝光量和广告曝光量
  5. **模型分值分析**: 从 data 字段提取推荐模型（RNKMOD）的 CTR/CVR/WD 分值，按 region×date 做分位数分析
- **Update Frequency:** Daily（由 Livestream 团队调度）

## Key Metrics

- **曝光类**: 总曝光量、自然曝光量（org_imp_cnt）、广告曝光量（org_imp_ads_cnt）、推荐曝光量（org_rcmd_imp_cnt）
- **用户类**: DAU（曝光去重 user_id）、推荐 DAU、广告 DAU
- **流量来源分类**: alltab / home / lp_topscroll / dd / pdp_nonseller / fullmode_slide / autolanding 等位置曝光

## Key Dimensions

- **分区**: tz_type, grass_region, grass_date
- **业务**: page_type, page_section (array), target_type, operation
- **实体**: streamer_id, user_id, ls_session_id
- **流量标识**: data.recommendation_info (CHAN:ADS / dispatch:ads), data.ls_track_id (QUE:ADS)
- **事件元信息**: data.type, data.from_source

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在代码库中找到) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (DDL 未在代码库中找到) |
| Region Coverage | ID, VN, TH, MY, PH, TW, SG (7 regions) + possibly BR |
| DQC Status | - |
| Table Size | - |

> **Note**: 该表由 Livestream 团队产出，DDL 不在 Ads 团队的 paidads-alg 代码库中。建议运行 `--source from-di` 补充 Technical Properties 和 Business Properties。

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 46 files (42 workflows + 4 manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
