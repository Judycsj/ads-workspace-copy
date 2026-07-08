<!-- ads-workspace-gdoc-sync: gdoc_id=1qaN0t27Zz6Aq2KIW6Pf-_vp8g9IjM1x0nfxFTmONMTc gdoc_url=https://docs.google.com/document/d/1qaN0t27Zz6Aq2KIW6Pf-_vp8g9IjM1x0nfxFTmONMTc/edit -->

# mp_order.dwd_order_item_all_ent_df__reg_s0_live

## Description

- **Desc:** 订单商品全量明细表（DWD 层），包含所有历史订单商品的完整信息，是订单域最核心的基础宽表。涵盖 GMV/NMV、佣金费用、品类信息、订单状态、支付渠道、优惠券、退货取消标记等字段。服务端按 region 分区，数据由 mp_order 数据管线生产。
- **Granularity:** daily x region (grass_date + grass_region + tz_type)
- **Use Case:**
  - Shop Take Rate 计算 — 按店铺聚合 GMV 以计算广告收入占比（dws_shop_take_rate_nd__reg_s0_live）
  - Net Ads Revenue — CB Citi 支付渠道比例计算（dws_advertise_net_ads_revenue_1d__reg_s0_live）
  - Order Escrow — 托管结算订单商品收入（dwd_order_escrow_di__reg_s0_live）
  - 竞价模型 organic order CDF — 按品类分桶统计自然单量（organic_order_data_daily）
  - 佣金费率计算 — 商品维度佣金/服务费回刷（item_commission_stat_non_1p）
  - 店铺评分统计 — 已评价订单数量统计（rating_count_daily_reg）
- **Update Frequency:** Daily（由 mp_order 上游管线保证）

## Key Metrics

- 交易类: gmv, gmv_usd, seller_gmv, seller_gmv_usd, seller_nmv, seller_nmv_usd
- 佣金类: commission_base_amt_usd, commission_fee_usd, service_fee_usd
- 订单类: order_id (COUNT DISTINCT), order_cnt

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 商品/店铺: shop_id, item_id, buyer_id
- 品类: level1_global_be_category_id, level1_global_be_category
- 订单状态: order_item_status, order_be_status_id, order_fe_status, is_bi_excluded
- 支付/优惠券: payment_be_channel_id, pv_promotion_id, sv_promotion_id
- 跨境: is_cb_shop
- 退货/取消: is_returned_item, cancelled_qty

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在 paidads-alg 代码库中找到，由 mp_order 数据管线维护) |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, SG, TH, PH, TW, MY, VN, BR (标准 8 区) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 43 files (43 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
