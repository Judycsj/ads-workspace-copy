<!-- ads-workspace-gdoc-sync: gdoc_id=1-8hguzM-zXLyvnmem_ywpdJWrbHF7y9v6H6la8ebxGk gdoc_url=https://docs.google.com/document/d/1-8hguzM-zXLyvnmem_ywpdJWrbHF7y9v6H6la8ebxGk/edit -->

# mp_paidads.dws_advertise_livestream_performance_1d__reg_s0_live

## Description

- **Desc:** 直播广告效果 DWS 层宽表，按 ads_id + placement + pricing_type + campaign_id + entrance + item_id + streamer_id 粒度聚合每日直播广告的表现数据（曝光、点击、订单、GMV、消耗等），同时包含 YTD 累计订单和主播/账户维度信息。由 dwd_livestream_performance_di 天级增量表按 region 聚合产出，支持 regional 和 local 双时区。
- **Granularity:** daily x ads_id x placement x pricing_type x campaign_id x entrance x item_id x streamer_id x target_affiliate_id x account_id
- **Use Case:**
  - 直播广告主市场报表 (ads_livestream_advertise_mkt_1d) -- 产出每日直播主广告维度 OKR 指标
  - 直播广告效果指标宽表 (ads_advertise_livestream_metrics_1d) -- 聚合 affiliate + 自有直播广告表现，产出冷启动状态、目标 ROI、出价活跃时长等
  - 直播广告主维度表现表 (dws_advertiser_livestream_performance_1d) -- 按 shop_id + streamer 聚合
  - 直播广告 7 日滚动表现表 (dws_advertise_livestream_performance_nd) -- 近 7 日滚动聚合
  - 直播广告市场汇总表 (ads_livestream_mkt_1d) -- 同 ads_livestream_advertise_mkt_1d
- **Update Frequency:** Daily (T+1 batch)

## Key Metrics

- 曝光类: impression_cnt, deduct_impression_cnt, non_fraud_impression_cnt
- 互动类: click_cnt, view_cnt, product_click_cnt, add_to_cart_cnt, view_duration
- 有效观看: effective_view_cnt (COUNT DISTINCT, 跨维度不可直接 SUM)
- 订单类: order_cnt, ads_items_sold_cnt, broad_order_cnt, paid_order_cnt, confirmed_order_cnt, checkout_cnt, broad_item_sold_cnt
- GMV 类: ads_gmv_amt, ads_gmv_amt_usd, broad_ads_gmv_amt, broad_ads_gmv_amt_usd
- 消耗类: ads_expenditure, ads_expenditure_usd, ads_expenditure_vat_local, ads_expenditure_vat_usd
- YTD 累计: paid_order_ytd_cnt, confirmed_order_ytd_cnt

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 广告标识: ads_id, placement, pricing_type, campaign_id, entrance, sub_entrance
- 商品: item_id
- 主播/账户: streamer_id, streamer_type, target_affiliate_id, account_id
- 店铺: shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | ${HIVE_PATH}/dws_livestream_performance_1d |
| Retention | - |
| Column Count | 38 |
| Region Coverage | VN, TW, TH, SG, PH, MY, ID (8 regions, regional + local timezone each) |
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

- Studio Tasks References: 52 files (8 write, 44 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
