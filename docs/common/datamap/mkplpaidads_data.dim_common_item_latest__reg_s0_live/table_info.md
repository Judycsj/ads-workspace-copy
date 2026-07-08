<!-- ads-workspace-gdoc-sync: gdoc_id=1xzpWQNipwO57Sdu8y2OWHXY4DB8wPmBmVyS79SvtQh8 gdoc_url=https://docs.google.com/document/d/1xzpWQNipwO57Sdu8y2OWHXY4DB8wPmBmVyS79SvtQh8/edit -->

# mkplpaidads_data.dim_common_item_latest__reg_s0_live

## Description

- **Desc:** Common item dimension table providing the latest snapshot of item-level static attributes across all regions -- including category hierarchy (L1-L5), pricing, ratings, images, brand, tier variations, and stock info. Serves as the authoritative item dimension source for ads algorithm feature engineering, model training data, and analytics pipelines.
- **Granularity:** item_id x grass_region (latest snapshot per region)
- **Use Case:**
  - ML feature generation: item static features for search/display/shop ads models (category, price, ratings, brand)
  - Click/tracking data enrichment: LEFT JOIN item_id to enrich click logs with item metadata (dwd_wide_item_tracking)
  - Rcmd Score pipeline: item-level stats and ROI scoring for seller item recommendation
  - GNN behavior dataset: item attributes for graph neural network training data
  - Image embedding: item images as input for embedding generation
  - Keyword behavior feature: visible item filter (status = 1) for search keyword-item stats
  - Category uplift analysis: item-to-category mapping for voucher uplift feature computation
  - Item quality/coverage analysis: null ratio checks, price distribution, stock reconciliation
- **Update Frequency:** Daily (latest snapshot)

## Key Metrics

This is a dimension table -- no aggregatable metrics. Key dimensions provided:

- Category: level1~5_global_be_category_id (L1-L5 global BE category hierarchy)
- Pricing: price, price_usd, price_min, price_max, discount_pct
- Ratings: rating_star, rating_good/normal/bad_cnt, liked_cnt, sold_cnt, comment_cnt
- Brand: global_brand_id, global_brand
- Images: images (array), tier_variations
- Item status: status, shop_status, is_free_shipping, actual_stock
- Metadata: create_datetime, modify_datetime, create_timestamp, modify_timestamp

## Key Dimensions

- **Partition:** dt (string/date), grass_region (string) -- region-level snapshot
- **Primary key:** (item_id, grass_region) -- item_id is unique per region
- **Business keys:** shop_id, item_id, level1~5_global_be_category_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | dt, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | ~30+ (from codebase usage) |
| Region Coverage | SG, MY, TH, PH, TW, ID, VN, BR, MX, CO, CL, AR |
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

- Studio Tasks References: 267 files (267 read, 5 write -- all derived table copies)
- L7D Query Count: -
- Completeness: -
- Popularity: -
