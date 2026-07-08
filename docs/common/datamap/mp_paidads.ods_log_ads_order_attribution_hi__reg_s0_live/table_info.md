<!-- ads-workspace-gdoc-sync: gdoc_id=1vzEt3emxqOweResPZeJSlVVnDAM8um9XQ8CaaZ4f08I gdoc_url=https://docs.google.com/document/d/1vzEt3emxqOweResPZeJSlVVnDAM8um9XQ8CaaZ4f08I/edit -->

# mp_paidads.ods_log_ads_order_attribution_hi__reg_s0_live

## Description

- **Desc:** 广告订单归因 ODS 日志表。存储广告点击与用户下单的归因关联数据，每条记录是一个订单商品（order item）与一次广告点击的配对，由上游日志 pipeline 写入，数据仓库通过 add_partition 同步分区。包含订单详情（item struct）、广告点击详情（click struct），以及归因标记（new/broad/checkout）。
- **Granularity:** event level (per order_item x ad_click), partitioned hourly per region
- **Use Case:**
  1. 广告订单归因（Order Attribution）— 将下单事件关联到广告点击，输出为 dwd_advertise_order_attribution_event_di__reg_s0_live
  2. 订单 GMV 校验 — 对比 ads_report 表与 OA 表的 GMV 差异
  3. 订单-点击时间差分析 — 分析下单时间与广告点击时间的分布
  4. 广告效果归因分析 — 关联 tracking_item 表，拆分 entrance 维度效果
- **Update Frequency:** Hourly (per partition h), 上游日志实时写入

## Key Metrics

- 订单量: order count (new=true), broad order count (new=true), direct order count (new=true AND broad=false), daily order count (D0 order)
- GMV 类: price * amount (order GMV), direct/broad/daily order GMV
- 归因标记: new (新归因订单), broad (broad match 归因), checkout (已结算)
- 订单属性: amount (购买件数), price (商品单价)

## Key Dimensions

- 分区: grass_region, grass_date, h
- 点击维度 (click struct): ads_id, campaign_id, entrance, entry_point, placement, pricing_type, shop_id, request_id
- 订单维度 (item struct): userid, orderid, shopid, itemid, modelid

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (Hive SerDe) |
| Partition Columns | grass_region (string), grass_date (date), h (int) |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hdfs/prod/logs/ods_log_ads_order_attribution_hi__reg_s0_live |
| Retention | 1825d (5 years) |
| Column Count | 14 (top-level, excluding partitions) |
| Region Coverage | MY, SG, TH, ID, VN, PH, TW, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 20 files (2 write, 18 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
