<!-- ads-workspace-gdoc-sync: gdoc_id=1DBAeYjtfMw9yIZcLCekTDwuUb7qJPqDHrL1maCw-Xds gdoc_url=https://docs.google.com/document/d/1DBAeYjtfMw9yIZcLCekTDwuUb7qJPqDHrL1maCw-Xds/edit -->

# mp_paidads.dim_advertiser_roi3_whitelist

## Description

- **Desc:** ROI3 (Target ROI 出价) 广告主白名单维度表。记录哪些 shop_id 开启了 ROI3 券功能（`is_roi_three_voucher_enabled > 0`），以及最早加入白名单的日期。每日快照，全量累加历史。
- **Granularity:** shop_id x grass_region (tz_type 固定为 'local')
- **Use Case:**
  - ROI3 券效果分析：通过 shop_id 过滤 dwd_advertise_performance_di 数据，计算 ROI3 广告的曝光/点击/收入/GMV 等指标，支持按 pricing_type / exp_tag / discount_tag 等维度下钻
  - ROI3 扣费 & 提权监控：分析 bid_rerank_trace 中的 deduction/boost 数据，对比 base vs exp 组的 uplift 效果
  - ROI3 预算控制：按 region 维度（exclude ID）统计 ROI3 广告消耗、平台券成本、商家出资等
  - CTR pcoc 分析：按 shop_id 过滤后做 CTR 校准分析，按 discount/cate/region 等维度拆分
  - Cofund 出资效果：区分 platform_spend_ratio > 0 的 cofund 曝光，计算平台出资 ROI
- **Update Frequency:** Daily (workflow 调度，T+1 产出)

## Key Metrics

本表为维度表，无指标列。下游分析中常见派生指标：
- 收入类: troi2_rev (expenditure_amt_usd), voucher_rev, cofund_rev
- 曝光类: troi2_imps, voucher_imps, cofund_imps
- GMV 类: troi2_bd_gmv, troi2_direct_gmv, troi2_platform_gmv, voucher_broad_gmv
- 广告价值: troi2_bd_advv (broad_gmv * target_cir)
- ROIs: 多种 ROIs (rev_roi, advv_roi, gmv_roi, platform_*_roi)
- 效率: CPM, GPM, advv_per_imps

## Key Dimensions

- 分区: grass_date, grass_region, tz_type (固定 'local')
- 业务: shop_id, whitelist_date

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (external table) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | ${HIVE_PATH}/dim_advertiser_roi3_whitelist__reg_s0_live/ |
| Retention | - |
| Column Count | 2 (shop_id, whitelist_date) + 3 partitions |
| Region Coverage | TH, VN, BR, TW, ID, MY, MX, SG (8 regions) |
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

- Studio Tasks References: 254 files (8 write, 246 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
