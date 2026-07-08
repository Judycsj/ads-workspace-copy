<!-- ads-workspace-gdoc-sync: gdoc_id=1uht258Mbcazw3AzniqrCJk7hcNDJX-MiD0VtaWPSH3M gdoc_url=https://docs.google.com/document/d/1uht258Mbcazw3AzniqrCJk7hcNDJX-MiD0VtaWPSH3M/edit -->

# mp_paidads.dim_common_feature_mapping_v2

## Description

- **Desc:** 入口代码 (entrance) 到特征类别名称 (common_feature) 的维度映射表。将广告效果数据按入口点归类为可读的特征类别（如 Search Shop、You May Also Like 等），供下游分析报表按 common_feature 维度聚合时 LEFT JOIN 使用。
- **Granularity:** One row per `entrance` value (entrance-to-feature mapping)
- **Use Case:**
  - 用户级别 AB 实验：按 common_feature 维度聚合广告点击/曝光/订单/GMV 指标
  - 广告特征分类标签：将 dwd_advertise_performance_di 的 entrance 值转换为 common_feature，便于分特征分析
  - 全站广告分析 (omni)：与 traffic_omni_oa 的表 JOIN 时提供特征维度
  - PC2 (placement/campaign) 优化：用户-商品级别的 common_feature 调权分析
- **Update Frequency:** 未在代码库中找到生产逻辑（推测为手工维护或独立管道更新）

## Key Metrics

该表为纯维度映射表，不含度量指标。

## Key Dimensions

- **entrance**: 入口点代码 (int/bigint)，作为 JOIN 键与 dwd_advertise_performance_di 等其他表关联
- **common_feature**: 特征类别名称 (string)，如 Search Shop、You May Also Like、Live Streaming 等

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - (dim 表，无分区或通过全表扫描使用) |
| HDFS Path | - |
| Retention | - |
| Column Count | ~2 (entrance, common_feature; 从 SQL 引用推断) |
| Region Coverage | 全地域 (multi-region，各地区使用同一份映射) |
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

- Studio Tasks References: 14 files (14 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
