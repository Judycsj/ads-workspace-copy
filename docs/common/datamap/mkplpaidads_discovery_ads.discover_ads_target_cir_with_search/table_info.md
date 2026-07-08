<!-- ads-workspace-gdoc-sync: gdoc_id=12ymuDx-7zOHUZ-7eDI7HcdaVRVShGnS-cUII4U6wFv8 gdoc_url=https://docs.google.com/document/d/12ymuDx-7zOHUZ-7eDI7HcdaVRVShGnS-cUII4U6wFv8/edit -->

# mkplpaidads_discovery_ads.discover_ads_target_cir_with_search

## Description

- **Desc:** Discovery Ads 目标 CIR（Cost-to-Income Ratio）表，按 placement x 类目（L1/L2）粒度计算并融合 Discovery 广告和 Search 广告的 target CIR，为下游 bidding 出价策略提供品类级目标成本收入比。
- **Granularity:** daily x placement (802/805) x category (L1/L2)
- **Use Case:**
  1. Discovery Ads bidding 目标 CIR 生成（生产例行）
  2. DWS target CIR 宽表生产，供出价系统使用
  3. AB 实验分析（DD、YMAL 实验），按 AB tag 评估品类 CIR 表现
  4. 品类级广告效果分析（按 L1/L2 类目 + 入口 + AB tag）
  5. Shop 级 ROAS 报表（结合 shop 维度）
- **Update Frequency:** Daily (30-day rolling window, T-2 snapshot)

## Key Metrics

- 收入成本比: final_l1_target_cir, final_l2_target_cir, discovery_l1_target_cir, discovery_l2_target_cir, search_l1_target_cir, search_l2_target_cir
- 订单量: discovery_l1_order, discovery_l2_order, search_l1_order, search_l2_order

## Key Dimensions

- 分区: grass_date, grass_region
- 核心: placement, version, l1_id, l1_name, l2_id, l2_name

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date (date), grass_region (varchar) |
| HDFS Path | - |
| Retention | - |
| Column Count | 17 (15 data + 2 partition) |
| Region Coverage | BR, ID, MY, PH, SG, TH, TW, VN (8 regions) |
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

- Studio Tasks References: 37 files (1 write, 36 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
