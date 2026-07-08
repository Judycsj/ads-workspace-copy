<!-- ads-workspace-gdoc-sync: gdoc_id=1lrZ6NEFt6P2UkeoZaCFPELV_eK42Gh1yeSZ2Rgd9ubs gdoc_url=https://docs.google.com/document/d/1lrZ6NEFt6P2UkeoZaCFPELV_eK42Gh1yeSZ2Rgd9ubs/edit -->

# mp_order.dws_seller_gmv_1d__reg_s0_live

## Description

- **Desc:** 商家（seller）维度每日 GMV 与订单交易指标事实表。由 mp_order 团队生产，ads 团队作为下游消费者使用。
- **Granularity:** daily x seller (shop_id) x region (grass_region) x tz_type
- **Use Case:**
  - 商家分级打标（key_seller_90/95 flag），用于 dim_shop_info 灯塔表生产
  - Advertiser 维度滚动窗口订单/GMV 指标计算（dws_advertiser_trd_order_gmv_nd）
  - 商家 Take Rate 分析（净广告收入 / 商家 GMV）
  - 平台全站 GMV 监控（按 region x date 汇总）
  - L30D 店铺画像分析（与用户、店铺属性表 JOIN）
- **Update Frequency:** Daily (推断自 workflow 调度)

## Key Metrics

- GMV 类: gmv_1d (本地币种), gmv_usd_1d (USD)
- 订单量: placed_order_cnt_1d
- 买家数: placed_buyer_cnt_1d
- 商品数: placed_item_cnt_1d

## Key Dimensions

- 主键: shop_id
- 分区: tz_type, grass_region, grass_date
- 业务维度: shop_id (关联 dim_shop_info 获取 seller_type, cluster, seller_tier 等)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL (多地区) |
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

- Studio Tasks References: 42 files (39 workflow + 3 manual)
- L7D Query Count: -
- Completeness: -
- Popularity: -
