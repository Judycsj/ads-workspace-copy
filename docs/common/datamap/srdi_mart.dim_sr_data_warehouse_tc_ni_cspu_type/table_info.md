<!-- ads-workspace-gdoc-sync: gdoc_id=1vQLKy4LYQSbXntViKMqLGIjsF5hieoWa8HOQ_k4j4gw gdoc_url=https://docs.google.com/document/d/1vQLKy4LYQSbXntViKMqLGIjsF5hieoWa8HOQ_k4j4gw/edit -->

# srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type

## Description

- **Desc:** SRDI mart 维度表，存储商品(item)级别的 CSPU (Category-Specific Product Unit) 类型分类信息。CSPU 类型用于描述商品在供需匹配中的状态（高需高供、高需低供、低需现有、新 CSPU、无 CSPU 等）。P0 CSPU 类型（type 1 和 4）标记为高优先级商品。
- **Granularity:** daily × grass_region × item_id (每条记录为一个特定区域下的商品 CSPU 分类)
- **Use Case:**
  1. **Product Ads passrate 模型特征工程**: 为 passrate 模型构建商品特征宽表时，LEFT JOIN 获取每个商品的 cspu_type 和是否 P0 的标记
  2. **Product Ads passrate dashboard 分析**: 按 reserve_criteria / rank_tier × pricing_type 计算 CSPU 类型分布（JSON 格式），监控各分组下 CSPU 构成
  3. **P0 CSPU 占比监控**: 通过 `is_p0_cspu_type` 指标计算各分组下高优先级 CSPU 商品占比
- **Update Frequency:** Daily（推测，来自 SRDI 上游数据管道）

## Key Metrics

本表为维度表，不包含度量指标。下游使用 `cspu_type` 和 `is_p0_cspu_type` 进行分组统计。

## Key Dimensions

- 分区: `local_date`
- 业务: `grass_region`, `item_id`
- 核心: `cspu_type` (CSPU 分类类型)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | local_date (推测) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, TH, MY, VN, PH, SG, TW, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 6 files (6 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
