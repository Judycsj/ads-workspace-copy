<!-- ads-workspace-gdoc-sync: gdoc_id=1JrQKaaBV8AJ_uryG6kCFbqOpB4YS4gJGaLG3FyNn17Y gdoc_url=https://docs.google.com/document/d/1JrQKaaBV8AJ_uryG6kCFbqOpB4YS4gJGaLG3FyNn17Y/edit -->

# mp_foa.dim_search_domain_map__reg_live

## Description

- **Desc:** Search domain 到 page type 的维度映射表，由 FOA 团队维护。提供 `scenario_key`->`mapped_page_type` 的映射关系，用于流量曝点/点击数据的页面分类。
- **Granularity:** daily x region
- **Use Case:**
  - Take Rate 日报 — 将 traffic impression/click 数据中的 `scenario_key` 映射为 `mapped_page_type`，用于 entry_point 分类
  - 全量 region 覆盖 (BR/CL/CO/ID/MX/MY/PH/SG/TH/TW/VN)
- **Update Frequency:** 未知（paidads-alg 代码库中未找到生产逻辑，由 FOA 团队维护）

## Key Metrics

无（纯维度映射表，不包含度量值）

## Key Dimensions

- 映射键: scenario_key, mapped_page_type
- 分区: grass_date, grass_region

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region（代码引用推断） |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | BR, CL, CO, ID, MX, MY, PH, SG, TH, TW, VN（11 个 region） |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - (FOA) |
| Business Domain | - |
| DW Layer | - (dim) |

## Popularity

- Studio Tasks References: 18 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
