<!-- ads-workspace-gdoc-sync: gdoc_id=1STybSIarNo05VWICh9viBovWoriMArr0d4wISZkv5lI gdoc_url=https://docs.google.com/document/d/1STybSIarNo05VWICh9viBovWoriMArr0d4wISZkv5lI/edit -->

# traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live

## Description

- **Desc:** Omni-channel Add-to-Cart (ATC) event-level raw data table. Captures every ATC action (`action_add_to_cart_success`) with full click context (up to 3-step source chain), ads/organic attribution, and item-level details. Serves as the foundational data source for ATC conversion tracking across all traffic entry points (Search, YMAL, Daily Discover, Live Streaming, Video, etc.).
- **Granularity:** Event-level (one row per ATC action per user per item per shop)
- **Use Case:**
  - Display Ads ATC 7c_1v conversion attribution (join with ads click/impression data)
  - Omni-channel ATC aggregation (ads vs organic split by common_feature/entry_point)
  - Search traffic ATC event statistics for data warehouse pipelines
  - Omni attributions: classify ATC by traffic source (step0/step1/step2/all steps)
- **Update Frequency:** Daily (di = daily increment)

## Key Metrics

- 加购类: atc_cnt (COUNT event_id), atc_units (SUM item_quantity), atc_gmv (SUM item_quantity * item_price)
- 广告归因: omni_ads_atc_cnt / omni_organic_atc_cnt (基于 common_property.is_ads)

## Key Dimensions

- 分区: grass_date, grass_region (sensitive regions)
- 用户: user_id
- 商品: item_id
- 店铺: shop_id
- 来源属性: common_feature (ads entry point 归类), operation, page_type, step_type
- 广告标记: common_property.is_ads, source1.common_property.is_ads, source2.common_property.is_ads
- 定位: location_property.location
- 设备: platform, rn_version, app_version

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | Sensitive regions (likely ID, MY, PH, SG, TH, TW, VN, BR) |
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

- Studio Tasks References: 21 files (0 write, 21 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
