<!-- ads-workspace-gdoc-sync: gdoc_id=1Ik6IPmqefeMwhQUlrmCRx2c2iUt2qMPevOBAT7-4S60 gdoc_url=https://docs.google.com/document/d/1Ik6IPmqefeMwhQUlrmCRx2c2iUt2qMPevOBAT7-4S60/edit -->

# mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live

## Description

- **Desc:** 广告关键词/搜索词级别的 DWS 表现汇总表，聚合每个 (ads_id, placement, keyword, query, pricing_type, item_id, shop_id) 组合的曝光、点击、订单、GMV 和花费指标。同时包含广告归因效果和全店(broad)归因效果两类指标。
- **Granularity:** daily x ads_id x placement x keyword x query x pricing_type x item_id x shop_id x region (tz_type='local')
- **Use Case:**
  - 下游 `dws_advertise_keyword_performance_1d` 的数据源（关键词级别汇总）
  - 下游 `dws_advertise_item_performance_1d` 的数据源（商品级别汇总）
  - 下游 `ads_advertise_mkt_1d` 的数据源（广告快照 + 冷启动分析）
  - 新广告 7d/14d 冷启动效果追踪
  - Spark 资源配置参考（job sizing）
- **Update Frequency:** Daily（按 region 分区调度：MX/CO/CL/BR）

## Key Metrics

- 效果类: impression_cnt, click_cnt, order_cnt, checkout_cnt, ads_items_sold_cnt
- 花费类: expenditure_amt_local, expenditure_amt_usd
- 收入类: ads_gmv_amt_local, ads_gmv_amt_usd
- 排名类: avg_ads_ranks
- 全店(broad)效果: broad_shopitem_click_cnt, broad_shopitem_impression_cnt, broad_order_item_cnt, broad_order_gmv_amt_local, broad_order_gmv_amt_usd, broad_order_cnt
- 店铺商品效果: shopitem_impression_cnt, shopitem_click_cnt
- 下单漏斗: daily_order_cnt, paid_order_cnt, paid_order_cnt_ytd, confirmed_order_cnt, confirmed_order_cnt_ytd
- 加购类: add_to_cart_cnt, add_to_cart_without_clicks_cnt, broad_add_to_cart_cnt
- 去重点击: click_before_deduction_cnt
- 受众定向: matched_premium_segment_value, filter_segments_age_start, filter_segments_age_end, filter_segments_gender_list, filter_segments_location_list, premium_segments_behavior_list, filter_segments_category_list

## Key Dimensions

- 分区: grass_date, grass_region, tz_type (always 'local')
- 广告标识: ads_id, placement, ads_type, pricing_type, entrance
- 商品/店铺: item_id, item_name, shop_id, seller_id, seller_name
- 关键词: keywords, query, match_type
- Campaign: product_placement (from dim_product_campaign)
- 地理位置: location
- Boost: new_boost

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dws_advertise_query_gmv_event_1d |
| Retention | - |
| Column Count | 56 (53 data + 3 partition) |
| Region Coverage | MX, CO, CL, BR (4 regions, workflow instances) |
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

- Studio Tasks References: 15 files (4 write, 11 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
