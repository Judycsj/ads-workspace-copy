<!-- ads-workspace-gdoc-sync: gdoc_id=15jLJXMEKLHo3Tzar2TPXgaIRoTmkxZnmYwuws2h3BmM gdoc_url=https://docs.google.com/document/d/15jLJXMEKLHo3Tzar2TPXgaIRoTmkxZnmYwuws2h3BmM/edit -->

# mp_item.rt_dim_item__reg_s0_live

## Description

- **Desc:** Real-time item dimension table, providing item identity and lifecycle timestamps (create_datetime, create_timestamp). A lightweight dimension table owned by the mp_item platform data team, used primarily for filtering recently created active items in ROI2 daily performance pipelines and validating ads index coverage.
- **Granularity:** item_id x grass_region (daily snapshot)
- **Use Case:** ROI2 newly-created item performance tracking (accumulated imp/click/ATC within N days of creation), ads index coverage validation (checking if indexed items exist in item dimension), item lifecycle filtering by creation date and active status
- **Update Frequency:** Daily (real-time dimension, updated daily)

## Key Metrics

This is a dimension table; it does not contain aggregatable metrics. Key attribute fields:
- create_datetime — item creation local datetime (used for lifecycle window filtering)
- create_timestamp — item creation unix timestamp
- status — item active status (1 = active, used as primary filter)

## Key Dimensions

- item_id — item unique identifier (primary key)
- grass_region — partition column, region code
- status — item active status (1 = active)
- create_datetime — item creation datetime (used in date range filters)
- modify_datetime — item last modification datetime

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (no DDL found in codebase; likely VIRTUAL_VIEW UNION ALL of regional tables) |
| Partition Columns | grass_region (inferred from SQL usage) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (no DDL found in codebase) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO (inferred from workflow region variants) |
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

- Studio Tasks References: 11 files (10 read/write workflows, 1 manual task)
- L7D Query Count: -
- Completeness: -
- Popularity: -
