<!-- ads-workspace-gdoc-sync: gdoc_id=18mfvhk-aXYBuhTFiSL6P5JtgZU_Sp6UK6q3na8YRYhc gdoc_url=https://docs.google.com/document/d/18mfvhk-aXYBuhTFiSL6P5JtgZU_Sp6UK6q3na8YRYhc/edit -->

# traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live

## Description

- **Desc:** Order-item level ATC (Add-to-Cart) journey attribution table, recording each order's touchpoint journey from impression/click to purchase. Provides multi-touchpoint attribution (click, source1, source2) with omni-channel feature classification and prorated GMV/order allocation.
- **Granularity:** daily x region x order_item x touchpoint_journey (order-item-ATC grain with multi-touchpoint attribution)
- **Use Case:** Platform GMV/order tracking by entrance (Search/DD/YMAL/Live/Video), AB test common feature performance analysis, ads vs organic attribution, item-level GMV for bidding, keyword-level GMV for SBA forecast, revenue PC2 attribution, ads diagnosis entrance metrics
- **Update Frequency:** Daily

## Key Metrics

- GMV: gmv_usd, gmv, place_sellergmv_usd
- Order: order_fraction, item_amount
- Attribution weights: atc_prorate, first_touchpoint_item, last_touchpoint_item

Derived (computed from above):
- Platform GMV USD: `SUM(gmv_usd * atc_prorate * first_touchpoint_item)`
- Platform Order: `SUM(order_fraction * atc_prorate * first_touchpoint_item)`
- Item Sold Count: `SUM(item_amount * atc_prorate * first_touchpoint_item)`

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 归因: first_touchpoint_item, last_touchpoint_item, atc_prorate
- 入口: feature_group_omni, feature_omni, feature_detail_omni, module, business_line
- 多触点: source1_feature_group_omni, source1_feature_detail_omni, source2_feature_group_omni, source2_feature_detail_omni
- 广告: click_common_property.is_ads, source1_common_property.is_ads, source2_common_property.is_ads
- 位置: click_common_property.entrance, click_location_property.location
- 搜索: click_search_property.keyword, click_search_property.image_source
- 视频: click_video_property.request_id
- 用户/商品: user_id, order_item_id, shop_id, order_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (外部表，非 Paid Ads 团队管理) |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | - (需运行 from-di 补充) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | Traffic / Omni OA |
| Business Domain | Order Attribution |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 185 files (142 workflows, 10 scheduled_tasks, 33 manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
