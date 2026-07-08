<!-- ads-workspace-gdoc-sync: gdoc_id=1VO4Q7oAKhv8dtNt0NIfbUk4scZ_jdf54MIN0CYkz0e8 gdoc_url=https://docs.google.com/document/d/1VO4Q7oAKhv8dtNt0NIfbUk4scZ_jdf54MIN0CYkz0e8/edit -->

# mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live

## Description

- **Desc:** 广告主 × 广告位天级累计表现（TD = To-Date）。从 `dws_advertise_performance_1d` 按 shop_id + placement 粒度聚合 1d 数据，并与前一天 TD 数据 UNION ALL 后再次聚合，实现滚动累计。是所有广告主/广告位维度报表的核心上游表。
- **Granularity:** daily x shop_id x placement x grass_region x tz_type
- **Use Case:**
  - 广告主分层（advertiser_tier）：按月至今累计支出分档 large/medium/small/micro
  - 广告主活跃状态（advertiser_status）：new/churn/existing/reactivated 判断
  - 卖家全量指标日报（ads_advertiser_seller_all_metrics_1d）：按 placement 拆分收入和 GMV
  - 卖家全量指标月报（monthly）：月末 snapshot
  - Shop Info 维表：advertiser_tier、advertiser_status 维度字段
- **Update Frequency:** Daily（调度 workflow，各 region 独立运行）

## Key Metrics

- 花费类: expenditure_amt_usd_td, expenditure_amt_local_td
- GMV 类: ads_gmv_amt_usd_td, ads_gmv_amt_local_td, broad_gmv_amt_usd_td
- 效果类: impression_cnt_td, click_cnt_td, order_cnt_td, ads_items_sold_cnt_td

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 业务: shop_id, placement

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | ${path} (动态配置) |
| Retention | - |
| Column Count | 14 (11 data + 3 partition) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX (含 local/regional) |
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

- Studio Tasks References: 106 files (11 write, 95 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
