<!-- ads-workspace-gdoc-sync: gdoc_id=1xhj36uCOtBbMdH5_P8lPKk7B1jdCumbKWuPPCgMRCwg gdoc_url=https://docs.google.com/document/d/1xhj36uCOtBbMdH5_P8lPKk7B1jdCumbKWuPPCgMRCwg/edit -->

# traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live

## Description

- **Desc:** Omni 全流量 Item 级别事件日志明细表，记录所有 Shopee 流量入口中用户对商品 (item) 的曝光 (impression) 和点击 (click) 事件，支持多步归因 (step0/step1/step2/stepall)，区分付费 (ads) 和自然 (organic) 流量。
- **Granularity:** 事件级别 (event-level) -- 每条记录代表一次 imp/click 事件 × user × item × entry_point
- **Use Case:**
  - Omni Organic Metrics 日表：按 common_feature/entry_point 聚合 imp/click，拆分 ads vs organic，下钻到 user/item/shop 粒度
  - AB 实验用户特征性能分析：将 item 级别流量与广告效果、订单 GMV 关联，按 user_id/feature 计算实验指标
  - Live Ads Tracker 平台指标：聚合 platform 级别 imp/click/DAU
  - Seller Report (ROI2)：按 shop/business_line/module 维度聚合流量指标
  - Image Search 流量分析：过滤 feature_detail like 'image_search-%' 分析图片搜索场景
- **Update Frequency:** Daily (由 traffic 团队生产)

## Key Metrics

- 流量类: omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt, omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt
- 入口级流量: omni_entry_impr_ads_cnt, omni_entry_impr_organic_cnt, omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt
- 平台级: platform_imp, platform_click, platform_dau
- Seller Report: total_impression_cnt, total_click_cnt, total_ads_impression_cnt, total_ads_click_cnt

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 事件属性: operation (impression/click), event_type, target_type, business_line
- 归因属性: common_property.is_ads, source1.*, source2.*
- 用户/商品: user_id, item_id, shop_id, ads_id
- 页面/模块: page_type, page_section, module, feature, feature_group, feature_detail, object
- 流量入口衍生物: entry_point, common_feature (CASE-WHEN 映射)
- 平台/版本: platform, app_version, rn_version
- 位置/搜索: location_property.location, search_property.scenario, search_property.image_source

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

- Studio Tasks References: 46 files (0 write, 46 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
