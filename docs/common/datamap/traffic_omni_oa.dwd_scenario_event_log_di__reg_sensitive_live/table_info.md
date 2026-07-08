<!-- ads-workspace-gdoc-sync: gdoc_id=15WV973QBxb11tR9rm-W1OjIYkyQuja5JgXuoVCUX5Lo gdoc_url=https://docs.google.com/document/d/15WV973QBxb11tR9rm-W1OjIYkyQuja5JgXuoVCUX5Lo/edit -->

# traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live

## Description

- **Desc:** Omni 全流量场景 (Scenario) 级别事件日志明细表，记录所有 Shopee 流量入口中用户的曝光 (impression) 和点击 (click) 事件，属于 entry_point 级别（非 item 级别），支持按 feature/module/feature_group 等属性进行分类归因。
- **Granularity:** 事件级别 (event-level) -- 每条记录代表一次 imp/click 事件 x user x entry_point/feature
- **Use Case:**
  - Omni Organic Metrics 日表（dws_organic_metrics_1d）：按 common_feature/entry_point 聚合 entry_point 级别的 imp/click，拆分 ads vs organic，下钻到 user/shop/location 粒度
  - AB 实验用户特征性能分析（dws_advertise_user_exp_common_feature_performance_1d）：将 entry_point 级流量与广告效果、订单 GMV 关联，按 user_id/feature 计算实验指标
  - Take Rate 报表（ads_advertise_take_rate_v2_1d）：聚合 platform 级 imp/click/DAU，用于计算平台整体 Take Rate
  - Organic vs Ads 对比分析：区分付费广告和自然流量的差异
- **Update Frequency:** Daily (由 traffic 团队生产)

## Key Metrics

- 入口流量类 (aggregated via SUM(CASE WHEN)): omni_entry_impr_ads_cnt, omni_entry_impr_organic_cnt, omni_entry_impr_cnt, omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt
- 平台聚合级: platform_imp, platform_click, platform_dau

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 事件属性: operation (impression/click)
- 广告标识: common_property.is_ads
- 用户/商品: user_id, shop_id, app_version, item_id
- 位置: location_property.location
- 页面/模块: platform, rn_version, search_property.scenario, page_type, page_section, target_type, module, feature_detail, feature_group, feature, object
- 流量入口衍生: entry_point (CASE-WHEN), common_feature (CASE-WHEN 映射)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL not in ads codebase, managed by traffic_omni team) |
| Partition Columns | grass_date, grass_region, tz_type (inferred from usage) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (run --source from-di to supplement) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL (8+3 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

> 未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD (明细事实表) |

## Popularity

- Studio Tasks References: 71 files (0 write, 71 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
