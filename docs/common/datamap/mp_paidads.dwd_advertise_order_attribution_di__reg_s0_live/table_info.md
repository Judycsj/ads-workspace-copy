<!-- ads-workspace-gdoc-sync: gdoc_id=1fkwo3bYW7zA2r_L6rzt7xg-dtsqbVJV-BteBBk_Vreg gdoc_url=https://docs.google.com/document/d/1fkwo3bYW7zA2r_L6rzt7xg-dtsqbVJV-BteBBk_Vreg/edit -->

# mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live

## Description

- **Desc:** 广告订单归因明细表，从 dwd_advertise_performance_di 提取有订单/支付/确认事件的数据，JOIN 汇率表转换为 USD。记录广告点击到订单的归因明细，含直接订单 (direct/ads) 和广义订单 (broad) 两类指标。
- **Granularity:** daily x tz_type x grass_region x (order_id, request_id, ads_id, item_id, shop_id, placement, query, keywords, match_type, pricing_type, entrance)
- **Use Case:**
  - 上游聚合表输入：dws_advertise_order_attribution_1d（订单归因 1d 汇总）、dws_advertise_query_gmv_event_1d（query 维度 GMV/事件表）
  - 订单效果分析：按 ads_id/placement/region 统计直接订单量与 GMV
  - 数据质量校验：prod 与 dev 环境对比，验证订单归因准确性
  - ROI2 广告效果分析：按 entrance/placement=40 聚合订单数据
- **Update Frequency:** Daily（按 region 分区写入，scheduled_tasks workflow）

## Key Metrics

- 订单类: daily_order_cnt, order_cnt, paid_order_cnt, confirmed_order_cnt
- GMV 类: ads_gmv_amt_local, ads_gmv_amt_usd (via exchange_rate), broad_order_gmv_amt_local, broad_order_gmv_amt_usd
- 商品类: ads_items_sold_cnt, broad_order_item_cnt
- 泛曝光/点击: broad_shopitem_click_cnt, broad_shopitem_impression_cnt

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 广告标识: ads_id, placement, item_id, shop_id
- 请求: request_id, query, keywords
- 归因: match_type, matched_premium_segment_value_id, pricing_type, entrance
- 时间戳: click_timestamp/click_datetime, event_timestamp/event_datetime, paid_timestamp/paid_datetime, confirmed_timestamp/confirmed_datetime

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dwd_advertise_order_attribution_di |
| Retention | - |
| Column Count | 33 (DDL columns) |
| Region Coverage | SG, MY, PH, ID, TH, TW, VN, MX, BR, CO, CL (plus US regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 18 files (14 read, 4 write - region-specific INSERTs in OA workflow)
- L7D Query Count: -
- Completeness: -
- Popularity: -
