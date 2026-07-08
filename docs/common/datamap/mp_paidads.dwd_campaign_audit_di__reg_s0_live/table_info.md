<!-- ads-workspace-gdoc-sync: gdoc_id=1KaLpQhK_NrdaMkHtYc9HbT6DfG_-BVw-VzNiuKPLO-4 gdoc_url=https://docs.google.com/document/d/1KaLpQhK_NrdaMkHtYc9HbT6DfG_-BVw-VzNiuKPLO-4/edit -->

# mp_paidads.dwd_campaign_audit_di__reg_s0_live

## Description

- **Desc:** Campaign audit event log (daily increment). Captures all audit/operation events on campaigns including budget changes, target ROI modifications, campaign status changes (pause/stop), and rapid boost toggle events. Each row represents one audit event with before/after snapshot values in JSON (`old_data`/`new_data`) and typed columns. Data sourced from 3 upstream CDC tables (campaign_audit_tab, product_campaign_audit_tab, ad_audit_event_tab) joined on event_id, with protobuf-decoded extinfo for ROI/budget extraction.
- **Granularity:** Event level (one row per audit event), partitioned by `tz_type` x `grass_region` x `grass_date`
- **Use Case:**
  1. Incentive wide table — count advertiser operational activities (budget/tROI/boost changes per shop/campaign)
  2. LTV model monitoring — detect whether a seller made manual operations in a time window
  3. Search hourly bid monitoring — track ROI value changes at hourly granularity by joining on campaign + hour
  4. Seller diagnosis — count pause/stop campaign events for diagnosis reporting
  5. Index log vs audit table ROI diff validation — cross-check ROI values between real-time index logs and audit trail
  6. Manual-to-ROI2 upgrade analysis — detect API-based campaign upgrades (`platform=98`)
  7. Rapid boost ROI trend analysis — track ROI/budget change directions (increase/decrease)
  8. Campaign fraud detection — detect abnormal budget operations (< min_budget), rapid pause/resume within 60s
  9. Ads index status monitoring — detect budget/tROI changes as index status events (status=1/2), expand to ads granularity
- **Update Frequency:** Daily (tag `_di_` indicates daily increment)

## Key Metrics

- 操作计数: budget_operation_cnt, troi_operation_cnt, boost_operation_cnt (COUNT DISTINCT of event_id by audit_event)
- 暂停/停止: pause_ads_cnt_1d, stop_ads_cnt_1d, has_pause, has_stop
- ROI 变化: target_direction (decrease/increase), target_change (roi_two_target_value_new - roi_two_target_value_old)
- 预算变化: budget_direction (decrease/increase, from old_data/new_data JSON)
- 卖家操作标识: have_seller_ops (operator NOT LIKE 'System')

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 实体: shop_id, campaign_id, user_id
- 事件类型: audit_event (1/2/3/4/5/6/8/9/49/50/63/64/90/91)
- 操作者: operator, operator_id
- 平台: platform (98 = API/platform-based)
- 时间: event_timestamp, event_datetime

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | ${HIVE_PATH}/dwd_campaign_audit_di__reg_s0_live |
| Retention | - |
| Column Count | 25 |
| Region Coverage | BR, ID, MY, PH, SG, TH, TW, VN (8 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD (Data Warehouse Detail) |

## Popularity

- Studio Tasks References: 90+ files (9 write, ~81 read; from `data_paidadsmart`, `mkplpaidads_search_ads`, `mkplpaidads_discovery_ads`, `mkplpaidads_brand_ads`, `mkplpaidads_data`)
- L7D Query Count: -
- Completeness: -
- Popularity: -
