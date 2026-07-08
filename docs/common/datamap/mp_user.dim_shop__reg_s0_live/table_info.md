<!-- ads-workspace-gdoc-sync: gdoc_id=1GXSa2CbgM85fGRJgxnqd5e8njg79UxsZ7aPyGb9t_t4 gdoc_url=https://docs.google.com/document/d/1GXSa2CbgM85fGRJgxnqd5e8njg79UxsZ7aPyGb9t_t4/edit -->

# mp_user.dim_shop__reg_s0_live

## Description

- **Desc:** Shop-level dimension table from `mp_user` database, providing core shop attributes such as shop status, seller type flags (official/preferred/managed/CB), shop name, rating, creation time, and user mapping. This is an upstream dimension table NOT owned by Ads team — used extensively as a JOIN source to enrich ads data with shop-level attributes.
- **Granularity:** daily x shop_id x region (one row per shop per region per day)
- **Use Case:**
  - Ads Advertiser Dimension enrichment (dim_advertiser workflow): shop_status, is_official_shop, is_managed_shop, is_preferred_shop, is_cb_shop
  - Shop Ads budget suggestion pipeline: enumerate all shops as a base population
  - Cold start / new shop analysis: filter newly created shops via create_datetime
  - Target Audience pipelines: filter effective shops (status=1, user_status=1)
  - Brand Ads keyword relevance: identify official shops (is_official_shop=1) for keyword ingestion
  - Display Ads whitelist: get shop_name for whitelist enrichment
  - Net Ads Revenue pipelines: indirectly via dim_advertiser for is_cb_shop flag
  - Seller type classification for reporting (Official Store / Cross Border / Preferred / Managed / Others)
- **Update Frequency:** Daily (upstream, not managed by Ads team)

## Key Metrics

This is a dimension table — no additive metrics. Key attributes used as enrichment:
- is_official_shop, is_preferred_shop, is_preferred_plus_shop, is_managed_shop — seller tier flags
- is_cb_shop — cross-border seller flag
- status — shop status (1=active)
- user_status — user account status
- rating_star — shop rating score
- shop_name — shop display name

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: shop_id, user_id, is_official_shop, is_cb_shop, status

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region, tz_type |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (8 regions + MX in some queries) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | mp_user (upstream, not Ads team) |
| Business Domain | User/Shop |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 218 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
