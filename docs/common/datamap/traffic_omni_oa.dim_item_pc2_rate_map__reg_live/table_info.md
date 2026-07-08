<!-- ads-workspace-gdoc-sync: gdoc_id=1iqcFIOxX8jdYLiyT2txMyzhzdaW0hoJwnBl1VliYfnw gdoc_url=https://docs.google.com/document/d/1iqcFIOxX8jdYLiyT2txMyzhzdaW0hoJwnBl1VliYfnw/edit -->

# traffic_omni_oa.dim_item_pc2_rate_map__reg_live

## Description

- **Desc:** Item-level PC2 (Platform Contribution 2) rate lookup table. Maps each item to its calibrated PC2 rate at the category level, used as a reference/benchmark for adjusting locally computed PC2 rates in downstream revenue attribution workflows.
- **Granularity:** item_id x grass_date x grass_region x tz_type (one rate per item per day per region per timezone)
- **Use Case:**
  - PC2 Rate Adjustment: Adjust locally computed item_pc2_rate against category-level benchmark rates (ratio or additive adjustment)
  - Revenue Attribution: Used in `dws_common_feature_user_item_pc2_1d` and `dws_user_pc2_1d` workflows to compute adjusted proxy PC2 revenue
  - Category Benchmarking: Provides category-level reference PC2 rates for item-level rate calibration
- **Update Frequency:** Daily (read by daily PC2 workflows; write source is external to this repo)

## Key Metrics

This is a dimension/mapping table; the key values are:

- **Rate**: `pc2_rate` -- Calibrated PC2 rate for each item
- **Rate v2**: `pc2_rate_exp_v2` -- Experimental PC2 rate (used in multiplicative adjustment variant)

## Key Dimensions

- **Partition**: grass_date, grass_region, tz_type
- **Lookup Key**: item_id
- **Category**: level2_global_be_category_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL not found in codebase; run --source from-di) |
| Partition Columns | grass_date, grass_region, tz_type (inferred from WHERE clauses) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | BR, ID, MX, MY, PH, SG, TH, TW, VN (all 9 regions in codebase) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 38 files (0 write, 38 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
