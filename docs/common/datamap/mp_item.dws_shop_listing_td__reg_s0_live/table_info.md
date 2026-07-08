<!-- ads-workspace-gdoc-sync: gdoc_id=1doFabt1JhthLHi_r6P0PMAprVAIqQHxSNmwVHYBIdAI gdoc_url=https://docs.google.com/document/d/1doFabt1JhthLHi_r6P0PMAprVAIqQHxSNmwVHYBIdAI/edit -->

# mp_item.dws_shop_listing_td__reg_s0_live

## Description

- **Desc:** Shop-level listing dimension table from mp_item, providing each shop's category classification (L1/L2 global BE category, FE display category, KPI category) and active item count. Widely used as a dimension lookup table to enrich shop-level analysis with category information.
- **Granularity:** daily x shop_id x region
- **Use Case:** dim_advertiser category enrichment, dim_shop_info category lookup, Search Brand Ads CPM calculation (L1/L2 category-level ROI), Incentive strategy wide table (shop activity & category), BD Center shop listing sync to StarRocks, Feature engineering (scoring feature category)
- **Update Frequency:** Daily

## Key Metrics

- active_item_cnt: number of active (listed) items per shop

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: shop_id, shop_level1_global_be_category_id, shop_level2_global_be_category_id, shop_level1_global_be_category, shop_level2_global_be_category

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | - |
| Retention | - |
| Column Count | ~15+ (exact DDL not in paidads-alg codebase) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 299 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
