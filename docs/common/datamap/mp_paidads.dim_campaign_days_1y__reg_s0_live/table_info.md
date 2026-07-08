<!-- ads-workspace-gdoc-sync: gdoc_id=1cROuN1O_vqe5UYD6qb58NVLPWAixWD7EFqpJlCQ1g8E gdoc_url=https://docs.google.com/document/d/1cROuN1O_vqe5UYD6qb58NVLPWAixWD7EFqpJlCQ1g8E/edit -->

# mp_paidads.dim_campaign_days_1y__reg_s0_live

## Description

- **Desc:** Campaign day dimension table. Pre-calculates all campaign days for a rolling 2-year window (365 days before to 366 days after BIZ_TIME) across 9 Shopee regions. Campaign days occur on specific dates each month (1st, 15th, 18th, 25th, 30th) plus palindrome dates (01-01, 02-02 etc.), each mapped to a subset of regions via CASE-WHEN.
- **Granularity:** grass_region x campaign_day
- **Use Case:**
  1. Exclude campaign days from baseline metrics in ROI2 before/after adoption analysis (campaign days have inflated performance)
  2. Identify upcoming campaign day and recent campaign history for ROAS/budget suggestions in Seller Center
  3. Determine whether a given date is a campaign day for spend/revenue normalization
- **Update Frequency:** Daily

## Key Metrics

*This is a pure dimension table with no metrics.*

## Key Dimensions

- `grass_region`: Region code — ID, MY, PH, SG, TH, VN, TW, BR, MX
- `campaign_day`: Specific campaign date (maps to a date on the calendar)
- `campaign_type`: Campaign schedule type (1-6, see Column Usage Notes for mapping)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | None (dimension table, full refresh) |
| HDFS Path | `${HIVE_PATH}/dim_campaign_days_1y__reg_s0_live/` |
| Retention | Full overwrite each run |
| Column Count | 3 |
| Region Coverage | ID, MY, PH, SG, TH, VN, TW, BR, MX |
| DQC Status | - |
| Table Size | - |

## Business Properties

*未抓取 DataMap，请运行 --source from-di 补充*

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 35 files (1 write, 34 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
