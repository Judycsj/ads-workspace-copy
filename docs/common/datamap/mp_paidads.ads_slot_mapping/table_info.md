<!-- ads-workspace-gdoc-sync: gdoc_id=14loujs8TAdWzt5rKMNP-qPC1AZBVKqj4GFdpa0EuPM0 gdoc_url=https://docs.google.com/document/d/14loujs8TAdWzt5rKMNP-qPC1AZBVKqj4GFdpa0EuPM0/edit -->

# mp_paidads.ads_slot_mapping

## Description

- **Desc:** 广告位映射表，存储各站点(grass_region)下不同 placement 类型的广告位位置(location)映射关系。用于判断某个页面位置（location）是否属于广告位(ad slot)，是 fill-rate 计算等下游分析的核心维表。
- **Granularity:** daily x grass_region x placement x location x platform
- **Use Case:**
  - Search 场景 keyword fill rate 计算：通过 JOIN 判断 impression/click 的 location 是否落在 ad slot 范围内（`dws_advertise_keyword_fill_rate_1d` workflow）
  - 流量质量分析：结合 AB 实验分析 ad slot 曝光分布
  - Ad-hoc 查询：查看最新日期各 region 的 slot 数量（playground）
- **Update Frequency:** Daily

## Key Metrics

本表为维表(Dim table)，不存储业务指标。

## Key Dimensions

- 分区: grass_date
- 业务: grass_region, placement, platform, location

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | 标准 8 区 (ID, MY, PH, SG, TH, TW, VN, BR) |
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

- Studio Tasks References: 4 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
