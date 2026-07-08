<!-- ads-workspace-gdoc-sync: gdoc_id=1_qUlVTLtVXtgotlwshWLk41KyqXxl-GWsrOgNO8x4-M gdoc_url=https://docs.google.com/document/d/1_qUlVTLtVXtgotlwshWLk41KyqXxl-GWsrOgNO8x4-M/edit -->

# regma_general.shop_attributes

## Description

- **Desc:** RegMa 团队的店铺属性维度表，维护店铺的 principal_type（主营类型）等信息。Ads 数据仓库通过 `msbenchmark` 临时视图读取该表，获取店铺的 principal_type 字段用于维度构建。
- **Granularity:** shop_id x grass_region（从 `GROUP BY shop_id, principal_type` 推断，无日期分区故为快照表）
- **Use Case:**
  - dim_shop_info/dim_shop_info_daily 维度构建：为每日店铺信息表提供 principal_type 字段
  - dim_shop_info_monthly/dim_shop_info_1m 月维度构建：为月度店铺信息表提供 principal_type 字段
  - Principal Type 推导：与 is_cb_seller 结合，区分 'Cross Border' / 'Local Brand' 店铺类型
- **Update Frequency:** 未知（上游表，studio_tasks 中无生产调度逻辑）

## Key Metrics

无（维度表，不包含指标字段）

## Key Dimensions

- 店铺维度: shop_id, principal_type
- 地域分区: grass_region

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | - |
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

- Studio Tasks References: 40 files (all read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
