<!-- ads-workspace-gdoc-sync: gdoc_id=12g-7-2yQHWfsMgSm_l8fdwv5qtBSE6dAcAm9bxlbViw gdoc_url=https://docs.google.com/document/d/12g-7-2yQHWfsMgSm_l8fdwv5qtBSE6dAcAm9bxlbViw/edit -->

# mp_paidads.dws_advertise_request_benchmark_advv_1d__reg_s0_live

## Description

- **Desc:** ADS domain request_id x ads_id level benchmark table. Contains per-request-per-ads metrics including revenue, GMV, click/impression counts, as well as multi-dimensional attributes (feature groups, product types, voucher types, platform, page info). Also includes deduction/bid pricing breakouts (CPC vs OCPM). Serves as the base benchmark table for AB test analysis, outlier detection, and video experiment metrics.
- **Granularity:** daily x grass_region x request_id x ads_id x feature_groups x product_types (one row per unique combination of these dimensions)
- **Use Case:**
  1. Search & RCMD AB test card-type level advv metrics analysis (exploding feature_groups, product_types, voucher_types, card_types)
  2. Video ads AB test analysis at product_type x feature_group level
  3. Platform-wide ads outlier detection -- computing percentile-based average basket size (ABS) outliers per feature_group
  4. Deep advv (roi2.0_simple) and budget supply metrics computation
- **Update Frequency:** Daily

## Key Metrics

- 收入与GMV: revenue_usd_1d, broad_gmv_usd_1d, ads_gmv_usd_1d
- 成本: direct_advv_cost_usd_1d, broad_advv_cost_usd_1d, broad_advv_cost_excl_outlier_usd_1d, broad_advv_cost_usd_7d
- GMV: direct_advv_gmv_usd_1d, broad_advv_gmv_usd_1d
- 效果: ads_click_cnt_1d, ads_imp_cnt_1d, ads_order_cnt_1d, ads_broad_order_cnt_1d
- 位置: ads_location_cnt_1d, top20_ads_location_cnt_1d
- 目标CIR: avg_target_cir_1d
- 深度广告价值: deepadvv_usd_1d (roi2.0_simple), padvv_usd_1d
- 扣费: sum_deduction_price_usd_1d, sum_cpc_deduction_price_usd_1d, sum_ocpm_deduction_price_usd_1d
- 出价: sum_bid_price_usd_1d, sum_cpc_bid_price_usd_1d, sum_ocpm_bid_price_usd_1d
- 计数类: deduction_price_cnt_1d, cpc_deduction_price_cnt_1d, ocpm_deduction_price_cnt_1d, bid_price_cnt_1d, cpc_bid_price_cnt_1d, ocpm_bid_price_cnt_1d

## Key Dimensions

- 分区: grass_region, grass_date
- 广告特征: feature_groups, product_types, main_product_types, voucher_types
- 广告属性: pricing_type, placement, attr_data_type
- 入口: entrance, sub_entrance
- 页面: page_type, page_section
- 位置: location
- 平台: platform
- 广告实体: ads_id, item_id, campaign_id, user_id, request_id
- 排序: sort_by
- 目标类型: target_type
- 实验: plan_bucket_list
- 视频: decoded_video_id
- 扣费: deduction_reason, voucher_details_json
- 出价券: bid_voucher_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_region (string), grass_date (date) |
| HDFS Path | ${HIVE_PATH}/dws_advertise_request_benchmark_advv_1d__reg_s0_live |
| Retention | - |
| Column Count | 56 |
| Region Coverage | All regions (${region} parameterized, upper-cased) |
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

- Studio Tasks References: 5 files (1 write, 4 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
