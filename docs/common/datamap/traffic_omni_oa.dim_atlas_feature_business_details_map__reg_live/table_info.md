<!-- ads-workspace-gdoc-sync: gdoc_id=1jmksHp8uR09T13eisecEtacP4VMAblNF_IvdIKMJaoo gdoc_url=https://docs.google.com/document/d/1jmksHp8uR09T13eisecEtacP4VMAblNF_IvdIKMJaoo/edit -->

# traffic_omni_oa.dim_atlas_feature_business_details_map__reg_live

## Description

- **Desc:** Atlas 特征-业务详情映射维度表，将页面特征（page_type/feature）映射到 Omni 频道标准化的 business_line 和 module 上，用于流量归因和入口分类。
- **Granularity:** daily x mapped_page_type x page_section x target_type x operation
- **Use Case:**
  - **Take Rate Entry Point 分类**: 在 `ads_advertise_take_rate_1d` 生产中，将原始曝光/点击的页面特征映射到 `reporting_business_line` 和 `reporting_module`，核心用于识别 "Daily Discover" (Homepage) 入口
  - **ClickHouse 物化视图**: 在 `ods_log_imp_sum_tz_mv` 物化视图中，为曝光数据补充 business_line/module 维度
  - **多区域部署**: 覆盖 SG/MY/PH/TW/VN/ID/TH/BR/MX/CO/CL 等所有区域，各区域使用统一的 JOIN 模式
- **Update Frequency:** Daily

## Key Metrics

此表为维度映射表，不包含业务指标。下游表中关联此表产生的指标包括：
- 流量类: entry_point_imp, entry_point_click
- 收入类: ads_rev_usd, raw_ads_rev_usd
- 平台类: platform_gmv, platform_imp

## Key Dimensions

- 分区: grass_date
- 映射键: mapped_page_type, page_section, target_type, operation
- 业务属性: reporting_business_line, reporting_module

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date (推测) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, MY, PH, TW, VN, ID, TH, BR, MX, CO, CL (全区域) |
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

- Studio Tasks References: 19 files (0 write, 19 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
