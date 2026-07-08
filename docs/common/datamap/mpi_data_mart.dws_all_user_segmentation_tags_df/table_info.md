<!-- ads-workspace-gdoc-sync: gdoc_id=1NVm5JyMptg1FldoB5DyiEcI_9XidajGrqvaKdv0mjmU gdoc_url=https://docs.google.com/document/d/1NVm5JyMptg1FldoB5DyiEcI_9XidajGrqvaKdv0mjmU/edit -->

# mpi_data_mart.dws_all_user_segmentation_tags_df

## Description

- **Desc:** User segmentation tags table providing user-level tagging signals (e.g. active status). Produced by the MPI data mart team. The paidads-alg team reads this table exclusively to filter active 30-day users (`a30_user='Yes'`) for target audience downstream workflows. One row per user per day per region.
- **Granularity:** daily x user_id x grass_region
- **Use Case:** Target Audience user profile building (active user filter), Target Audience potential new buyer identification (filter candidates to active users only)
- **Update Frequency:** Daily

## Key Metrics

- User Activity: a30_user flag ('Yes' filter in all downstream queries)

## Key Dimensions

- Partition: grass_region, grass_date
- Entity: user_id
- Segmentation: a30_user

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, CL, CO, MX (inferred from downstream region files) |
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

- Studio Tasks References: 27 files (24 workflows + 3 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
