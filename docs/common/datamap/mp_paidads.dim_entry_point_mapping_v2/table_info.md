<!-- ads-workspace-gdoc-sync: gdoc_id=1HzLeBYH8qHgdzw0Pt_XefmLq4w5r76krUQ3iG67M4g0 gdoc_url=https://docs.google.com/document/d/1HzLeBYH8qHgdzw0Pt_XefmLq4w5r76krUQ3iG67M4g0/edit -->

# mp_paidads.dim_entry_point_mapping_v2

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-15 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/datamap/mp_paidads.dim_entry_point_mapping_v2/table_info.md)

## Description

- **Desc:** 广告入口映射维度表，将数值型 entrance ID 映射到可读的 entry_point 名称和 traffic_type 分类。是广告数据分析中最常用的维度映射表之一，几乎所有涉及入口维度的分析都会 JOIN 此表。
- **Granularity:** entrance (入口 ID) 级别，一个 entrance 对应一个 entry_point + traffic_type 组合
- **Use Case:** 广告诊断指标表 (ads_advertise_key_metrics_daily) 中按场景分类、Take Rate 报表按入口聚合、TMS 追踪数据关联场景名称、Click Deduction 分析按 traffic_type 分组、广告效果分析按 entry_point 聚合
- **Update Frequency:** 低频更新（维度表，新增入口时更新）

## Key Metrics

此表为纯维度映射表，不含度量指标。

## Key Dimensions

- 映射维度: entrance, entry_point, traffic_type, sub_entrance, common_feature

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | 无分区（维度表） |
| HDFS Path | - |
| Retention | - |
| Column Count | ≥5 (entrance, entry_point, traffic_type, sub_entrance, common_feature) |
| Region Coverage | 全局（不按地域分区） |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 77 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
