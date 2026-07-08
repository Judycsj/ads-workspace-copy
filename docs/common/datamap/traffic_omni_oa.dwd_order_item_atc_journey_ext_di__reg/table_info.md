<!-- ads-workspace-gdoc-sync: gdoc_id=1JnTfGX21JY760mrSaw29Veerprb00f-Vw7ADRMMSiI4 gdoc_url=https://docs.google.com/document/d/1JnTfGX21JY760mrSaw29Veerprb00f-Vw7ADRMMSiI4/edit -->

# traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg

## Description

- **Desc:** Omni-channel order item ATC (add-to-cart) journey attribution detail table. Records the full touchpoint journey from item impression/click to ATC to order, with multi-step attribution (step0/step1/step2/stepall) and proration weights (`atc_prorate`, `first_touchpoint_item`). Used as the core data source for calculating platform-level GMV/NMV metrics with omni-channel attribution in organic metrics and take rate pipelines.
- **Granularity:** daily x region
- **Use Case:**
  - DWS Organic Metrics generation (dws_organic_metrics_1d__reg_s0_live) -- attributed platform GMV by entry_point x common_feature
  - Take Rate V2 calculation (ads_advertise_take_rate_v2_1d__reg_s0_live) -- platform NMV metrics for take rate
  - Ad-hoc platform NMV breakdown by region
- **Update Frequency:** Daily (upstream ETL, not found in studio_tasks)

## Key Metrics

- 归因订单: `order_fraction * first_touchpoint_item * atc_prorate` (ads/ organic/ total, 3-way split)
- 归因GMV: `gmv * first_touchpoint_item * atc_prorate` (ads/ organic/ total, local + USD)
- 归因商品销量: `item_amount * first_touchpoint_item * atc_prorate` (ads/ organic/ total)
- Platform GMV stages: antifraud, paid, confirmed, complete, cancel, return (each with usd/local/order_fraction)
- COD adjusted GMV: paid_with_confirmed_cod, paid_with_placed_cod
- Platform NMV: `nmv * first_touchpoint_item * atc_prorate`, `nmv_usd * first_touchpoint_item * atc_prorate`
- Platform net order: `CASE WHEN is_net_order = 1 THEN order_fraction * first_touchpoint_item * atc_prorate END`
- 归因佣金: `(gmv / order_commission_gmv) * commission_fee * atc_prorate * first_touchpoint_item` (ads/ organic/ total)

## Key Dimensions

- 分区: `grass_date`, `grass_region`, `tz_type`
- 业务: `user_id`, `order_item_id`, `order_id`, `order_model_id`, `group_id`, `bundle_order_item_id`, `shop_id`, `app_version`
- 归因权重: `atc_prorate`, `first_touchpoint_item`, `step_num_item`, `step_num`
- 归因步骤: step0 (直接点击), step1 (上一跳), step2 (上两跳), stepall (全路径)
- 触点属性: `feature_group_omni`, `feature_omni`, `feature_detail_omni`, `module`, `business_line`, `object`
- 点击来源: `click_common_property.is_ads`, `click_location_property.location`, `click_page_type`, `click_feature_group_omni`...
- 上游来源: `source1_common_property.is_ads`, `source1_feature_group_omni`, `source1_location_property.location`, `source2_*` 同理
- 订单状态: `is_cod`, `is_net_order`
- AB实验: `exp_version`, `exp_group`, `ab_test`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL not found in studio_tasks) |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | - (multi-region, used with SG/ID/MY/PH/TH/TW/VN/BR) |
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

- Studio Tasks References: 19 files (0 write, 19 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
