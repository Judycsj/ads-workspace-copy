<!-- ads-workspace-gdoc-sync: gdoc_id=1Fy_16IxSnpPjdHv3Djkz9L6SbP1cTQf6ttcCUfdOEAc gdoc_url=https://docs.google.com/document/d/1Fy_16IxSnpPjdHv3Djkz9L6SbP1cTQf6ttcCUfdOEAc/edit -->

# traffic_omni_oa.dwd_item_event_log_hi__reg_sensitive_live

## Description

- **Desc:** Omni 全流量 Item 级别事件日志小时表，记录所有 Shopee 流量入口中用户对商品 (item) 的曝光 (impression) 和点击 (click) 事件。与日表 (di) 版本相比，多了 `grass_hour` 字段支持基于当地时区的小时级精确过滤，用于 Take Rate 计算的入口级曝光统计和 TMS 差异报表。
- **Granularity:** 小时级事件 (hourly-event-level) -- 每条记录代表一次 imp/click 事件 x 小时 x user x item
- **Use Case:**
  - Take Rate v2 入口曝光统计：按 entry_point 聚合入口级曝光 (entry_point_imp)，用于计算平台各入口的 Take Rate
  - TMS Diff 报表：按 user_id/entry_point/feature 维度聚合 item 级别的曝光和点击，区分付费 (ads) 和自然 (organic) 流量，与 Report NG 数据做差异对比
  - Organic Metrics 小时表：通过 union all step0/1/2/stepall 实现多步归因，按 common_feature/entry_point 拆分 ads vs organic 流入量
- **Update Frequency:** Hourly (由 traffic 团队生产)

## Key Metrics

- 入口曝光: entry_point_imp, entry_point_total_impression, entry_point_ads_impression
- 入口点击: entry_point_ads_click, entry_point_total_click
- Item 级流量: omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt, omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt
- 平台级: platform_imp

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 时间维度: grass_hour (小时)
- 事件属性: operation (impression/click), target_type
- 归因属性: common_property.is_ads, source1.*, source2.*
- 用户/商品: user_id, item_id, shop_id
- 页面/模块: page_type, page_section, module, feature, feature_group, feature_detail, object
- 流量入口衍生物: entry_point, common_feature (CASE-WHEN 映射)
- 平台/版本: platform, app_version, rn_version
- 场景/位置: search_property.scenario, location_property.location
- 视频属性: video_property.is_ymal_item

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

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 40 files (0 write, 40 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
