<!-- ads-workspace-gdoc-sync: gdoc_id=1y0GNPWOAxqQamLoGERUP-bIPxdv96Bg6l2HBOmHL7Wg gdoc_url=https://docs.google.com/document/d/1y0GNPWOAxqQamLoGERUP-bIPxdv96Bg6l2HBOmHL7Wg/edit -->

# traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live

## Description

- **Desc:** Omni traffic product page view detail table (daily). Records user product page view events with page duration, ad/organic classification, and multi-step click attribution (step0/step1/step2/stepall) for computing omni PPV and stay time metrics.
- **Granularity:** daily x region x tz_type x event (user + item + session)
- **Use Case:**
  - Omni PPV (product page views) computation split by ads vs organic traffic
  - Omni stay time (page_duration) aggregation by common_feature
  - Multi-step attribution: step0 (direct click), step1 (source1), step2 (source2), stepall (any step)
  - Common feature classification (Search Shop, Global Search, You May Also Like, Daily Discover, etc.)
- **Update Frequency:** Daily

## Key Metrics

- 流量类: page_duration (stay time), PPV count (operation='view')
- 分类类: is_ads (from last_item_click/source common_property), common_feature classification

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 用户/商品: user_id, item_id, shop_id
- 行为: operation (view/click/impression), is_back
- 归因: step0/step1/step2/stepall (multi-step click attribution)
- 流量分类: common_feature (derived from feature_detail, feature_group, feature, module)
- 平台: app_version, platform
- 位置: location_property.location
- 曝光/点击归因: last_item_click.*, source1.*, source2.*, common_property.is_ads

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region, tz_type |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | multi-region (8 standard regions: ID, MY, PH, SG, TH, TW, VN, BR) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |
| Sensitivity | reg_sensitive_live |

## Popularity

- Studio Tasks References: 3 files (manual_tasks, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
