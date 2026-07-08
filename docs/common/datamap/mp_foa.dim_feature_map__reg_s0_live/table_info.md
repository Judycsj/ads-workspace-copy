<!-- ads-workspace-gdoc-sync: gdoc_id=1xvdE77dZk2sbWorZW5KDLCWjBM_FIGnUKWF3wOqZkFk gdoc_url=https://docs.google.com/document/d/1xvdE77dZk2sbWorZW5KDLCWjBM_FIGnUKWF3wOqZkFk/edit -->

# mp_foa.dim_feature_map__reg_s0_live

## Description

- **Desc:** Feature map dimension table. Maps feature_detail (a concatenated key in the format `page_type-page_section-target_type`) to feature_group and feature names. Used as a lookup for classifying platform traffic impressions into entry_points (Search, Daily Discover, You May Also Like, Livestream, etc.).
- **Granularity:** daily x grass_region
- **Use Case:**
  - Platform traffic impression classification (Take Rate workflow -- bi_imp / bi_click views)
  - Entry point mapping for ads metrics aggregation
  - Feature-to-traffic category mapping in ClickHouse materialized views
- **Update Frequency:** Daily (partitioned by grass_date; consumers always query latest partition via `max(grass_date)` subquery)

## Key Metrics

N/A -- this is a pure dimension/lookup table with no metrics.

## Key Dimensions

- **feature_detail**: Concatenated feature key in `page_type-page_section-target_type` format (e.g. `search-global_search-item`)
- **feature_group**: High-level feature group name (Search, You May Also Like, Live Streaming, Rcmd Others, etc.)
- **feature**: Individual feature name
- **grass_region**: Region code (upper case, e.g., 'SG', 'MY', 'ID')
- **grass_date**: Partition date

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region (inferred from usage) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, MY, PH, TW, VN, ID, TH, BR, MX, CO, CL (inferred from Take Rate workflow regions) |
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

- Studio Tasks References: 20 files (18 read from workflows, 2 from manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
