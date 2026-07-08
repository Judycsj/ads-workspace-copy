<!-- ads-workspace-gdoc-sync: gdoc_id=1a-1I3pXlLC4_ncJnTmZw8N4BnPivQ37vZnh10WrTtEU gdoc_url=https://docs.google.com/document/d/1a-1I3pXlLC4_ncJnTmZw8N4BnPivQ37vZnh10WrTtEU/edit -->

# sgbi_general.smart_abt_user_split

## Description

- **Desc:** AB test user split table for Smart Ads / Smart Voucher experiments, mapping users to experiment groups on a daily basis. Managed by SG BI team as an upstream table -- no write logic found in paidads-alg codebase.
- **Granularity:** daily x exp_group x user_id
- **Use Case:**
  - Smart Voucher user blacklist generation: identify users in experiment/control groups for voucher targeting
  - User group tag validation: verify cohort sizes and group assignments
  - AB test group assignment: map `exp_group` to business group names (`mp_plus_ads` / `control`) for downstream analysis
- **Update Frequency:** Daily (referenced via `max(grass_date)` pattern in all queries)

## Key Metrics

- 用户类: user_cnt (COUNT DISTINCT user_id)

## Key Dimensions

- 分区: grass_date
- 业务: exp_group (mapped to group_name: mp_plus_ads / control), grass_region (always 'SG' in codebase usage)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG (all codebase references hardcode 'SG' for grass_region) |
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

- Studio Tasks References: 12 files (0 write, 12 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
