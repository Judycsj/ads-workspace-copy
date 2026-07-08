<!-- ads-workspace-gdoc-sync: gdoc_id=1xOS7BRxrbBKFFAF3wDLhRRolH7E735EgvvWq0z1b6dY gdoc_url=https://docs.google.com/document/d/1xOS7BRxrbBKFFAF3wDLhRRolH7E735EgvvWq0z1b6dY/edit -->

# mp_item.dim_item__reg_s0_live

## Description

- **Desc:** Shopee platform-level item dimension table, providing item attributes including category hierarchy, pricing, stock, sales, brand, shop info, and item status. Owned by the platform data team (mp_item), widely used across Ads workflows as a core dimension lookup table.
- **Granularity:** daily x item_id x grass_region
- **Use Case:** Item attribute enrichment for ads bidding/targeting models, category-based analysis (L1-L4 category), brand keyword generation, pass-rate model feature extraction, ROI/CIR targeting, item-level price and stock filtering, potential buyer audience building
- **Update Frequency:** Daily

## Key Metrics

This is a dimension table; it does not contain aggregatable metrics. Key attribute fields used as measures:
- price / price_usd — item price (local currency / USD)
- stock — current stock level
- last_30days_sold_cnt — 30-day sold count (used as order_30d_cnt)
- discount_pct — discount percentage

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Category: level1_global_be_category_id, level2_global_be_category_id, level3_global_be_category_id, level4_global_be_category_id
- Item identity: item_id, shop_id, name
- Item status: status, shop_status, seller_status
- Brand: global_brand_details (struct: id, name, local_name, local_synonyms)
- Shop: shop_name, seller_name, is_official_shop
- Pricing: price, price_usd, discount_pct
- Shipping: is_free_shipping
- Lifecycle: create_datetime

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Hive (VIRTUAL_VIEW — UNION ALL of 15 regional tables) |
| Partition Columns | grass_date, grass_region, tz_type |
| HDFS Path | - (virtual view) |
| Retention | Permanent |
| Column Count | - (no DDL found in codebase; virtual view) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (standard 8 regions + MX/US in some workflows) |
| DQC Status | SUCCESS |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | siping.ying@shopee.com, kenneth.kohtk@shopee.com |
| Technical PIC | yali.guo@shopee.com, siping.ying@shopee.com |
| Team | regdedw1 |
| Project | data_itemmart |
| Business Domain | Marketplace - Core |
| Data Mart | Item Mart |
| DW Layer | DIM |
| Market Region | REG |
| L7D Query Count | 126,458 |

## Popularity

- Studio Tasks References: 1072 files
- L7D Query Count: 126,458
- Completeness: 95.46
- Popularity: 100.00
