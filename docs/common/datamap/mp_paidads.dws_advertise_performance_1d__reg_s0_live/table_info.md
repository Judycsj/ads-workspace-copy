<!-- ads-workspace-gdoc-sync: gdoc_id=1jnxQX220NizOjixBQRWiHWTzZWPCJQFbnQxxUVUeQps gdoc_url=https://docs.google.com/document/d/1jnxQX220NizOjixBQRWiHWTzZWPCJQFbnQxxUVUeQps/edit -->

# mp_paidads.dws_advertise_performance_1d__reg_s0_live

## Description

- **Desc:** 广告日粒度效果宽表（DWS 层），聚合 `dwd_advertise_performance_di` 的曝光/点击/订单/GMV 及 `dws_advertise_revenue_1d` 的消耗数据，按 ads_id × placement × entrance × pricing_type × campaign_id × item_id × traffic_source 粒度生成每日效果快照。是整个 Paid Ads 数据体系中被引用最多的表，几乎所有下游 ADS/DWS 表和离线分析都基于此表构建。
- **Granularity:** daily × ads_id × placement × entrance × pricing_type × campaign_id × item_id × traffic_source × region × tz_type
- **Use Case:** ROI/Take Rate 日报计算、广告效果漏斗分析（曝光→点击→订单→GMV）、Boost/Traffic Subsidy 策略效果评估、Campaign Surge DID 分析、Shop Ads 采纳漏斗、冷启动标签分析、Seller Center 诊断、广告主大盘报表生产
- **Update Frequency:** Daily（每日调度，per-region 分区写入，同时生成 local 和 regional 两个 tz_type 分区）

## Key Metrics

- 消耗: expenditure_amt_usd_1d, expenditure_amt_local_1d
- 直接 GMV: ads_gmv_amt_usd_1d, ads_gmv_amt_local_1d
- 宽口径 GMV: broad_gmv_amt_usd_1d, broad_gmv_amt_local_1d
- 曝光/点击: impression_cnt_1d, click_cnt_1d, deduplicated_click_cnt
- 直接订单: order_cnt_1d, ads_items_sold_cnt_1d
- 宽口径订单: broad_order_cnt_1d, broad_order_item_cnt_1d
- 已付款订单: paid_order_cnt_1d, paid_order_cnt_ytd_1d, paid_broad_order_cnt, paid_broad_order_gmv / paid_broad_order_gmv_usd
- 购物车: direct_add_to_cart_cnt_1d, broad_add_to_cart_cnt_1d, add_to_cart_without_clicks_cnt_1d
- 视频: video_play_complete, video_play_3s_cnt, video_play_5s_cnt, video_view, view_duration
- CPS: cps_dedup_click_cnt, deduct_order_cnt
- 返利: expense_rebate_free_credit_without_expiry
- 曝光归因: imp_attr_paid_order_cnt, imp_attr_paid_order_gmv / imp_attr_paid_order_gmv_usd
- 无点击订单: paid_no_click_order_cnt, paid_no_click_order_gmv / paid_no_click_order_gmv_usd

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 广告: ads_id, placement, entrance, pricing_type, campaign_id, item_id
- 店铺: shop_id, seller_id
- 广告类型: ads_type, new_boost, traffic_source
- 辅助: rapid_boost_toggle, is_ocpm, deduct_impression

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Hive (Spark SQL) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/dws_advertise_performance_1d |
| Retention | 730 |
| Column Count | 67 (64 data + 3 partition) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL (SEA + LATAM) |
| DQC Status | WARNING |
| Table Size | 3.89 TB |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | renjie.xia@shopee.com, zhangyawei@shopee.com |
| Team | mkplpaidads |
| Business Domain | Marketplace - Paid Ads |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 395 files
- L7D Query Count: 2,133
- Completeness: 73.45
- Popularity: 100.00
