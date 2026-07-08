<!-- ads-workspace-gdoc-sync: gdoc_id=1kgI8J58PWAvauuZlrVjQciiKVGx21SrPGLiOLBQoEYc gdoc_url=https://docs.google.com/document/d/1kgI8J58PWAvauuZlrVjQciiKVGx21SrPGLiOLBQoEYc/edit -->

# mp_paidads.dws_advertiser_trd_order_gmv_nd__reg_s0_live

## Description

- **Desc:** 广告主全店交易订单滚动 GMV 与订单数汇总表（DWS 层），以 shop_id 为粒度聚合过去 1/7/30/60/90 天的买家数、订单数、订单商品件数、售出商品件数、GMV（本地货币/USD），由 mp_order 域两张卖家 GMV 表 JOIN 后按 shop_id×grass_region 聚合，LEFT JOIN dim_advertiser 补齐 user_id 等维度。
- **Granularity:** daily x grass_region x shop_id (tz_type 固定为 'local')
- **Use Case:**
  - ads_advertiser_mkt_1d 广告主市场日报：通过 user_id + grass_region LEFT JOIN 获取广告主全平台 GMV 和订单指标
  - 广告主级别全店交易日报/周报/月报分析
  - 广告主全店 GMV 趋势和滚动窗口指标计算
- **Update Frequency:** Daily (workflow: data_warehouse_us/dws/dws_advertiser_trd_order_gmv_nd)

## Key Metrics

- 买家类: buyer_cnt_1d, buyer_cnt_7d, buyer_cnt_30d, buyer_cnt_60d, buyer_cnt_90d
- 订单类: order_cnt_1d, order_cnt_7d, order_cnt_30d, order_cnt_60d, order_cnt_90d
- 订单商品件数: order_item_cnt_1d, order_item_cnt_7d, order_item_cnt_30d, order_item_cnt_60d, order_item_cnt_90d
- 售出商品件数: items_sold_cnt_1d, items_sold_cnt_7d, items_sold_cnt_30d, items_sold_cnt_60d, items_sold_cnt_90d
- GMV (本币): gmv_1d, gmv_7d, gmv_30d, gmv_60d, gmv_90d
- GMV (USD): gmv_usd_1d, gmv_usd_7d, gmv_usd_30d, gmv_usd_60d, gmv_usd_90d

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 实体: shop_id, user_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dws_advertiser_trd_order_gmv_nd |
| Retention | - |
| Column Count | 35 |
| Region Coverage | MX, BR, CO, CL (US regions, tz_type='local' only) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 9 files (4 write, 5 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
