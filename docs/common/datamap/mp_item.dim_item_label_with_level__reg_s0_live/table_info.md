<!-- ads-workspace-gdoc-sync: gdoc_id=1h6AsNtWmqf2HlpY7VXEPV8TDXGC3cK6pN5ggmU1NUcg gdoc_url=https://docs.google.com/document/d/1h6AsNtWmqf2HlpY7VXEPV8TDXGC3cK6pN5ggmU1NUcg/edit -->

# mp_item.dim_item_label_with_level__reg_s0_live

## Description

- **Desc:** 商品标签层级维表，存储商品(item)关联的标签(label)及其层级(level)信息，由 mp_item 团队维护。
- **Granularity:** daily x grass_region x tz_type x item_id x label_id
- **Use Case:**
  1. **Blacklist Filtering (黑名单过滤)**: 在 NPB/NPA 商品推荐、卖家中心推荐、商品竞争力评分等工作流中，通过 `label_id IN (841356053736030, 843249807227517, 298553329)` 排除特定标签商品
  2. **Creative Enrichment (创意富集)**: 在 Creative Producer (s2pro) 工作流中，通过 `label_id = 1002164 AND deleted = 0` 获取商品的"original"标签信息，用于创意素材特征提取
- **Update Frequency:** Daily

## Key Metrics

N/A — 该表为维度表（dim table），主要用于标签查询过滤，不包含聚合指标。

## Key Dimensions

| Dimension | Description |
|-----------|-------------|
| label_id | 标签ID，核心过滤维度。已知值: 841356053736030, 843249807227517, 298553329 (黑名单); 1002164 (original) |
| item_id | 商品ID |
| shop_id | 卖家ID |
| deleted | 软删除标记 (0=正常) |
| grass_date | 分区日期 |
| grass_region | 分区区域 (如 SG, MY, TH, VN, TW, PH, ID, BR, MX, CL, CO, AR) |
| tz_type | 时区类型 (local) |

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, MY, TH, VN, TW, PH, ID, BR, MX, CL, CO, AR (11+ regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 50 files (0 write, 50 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
