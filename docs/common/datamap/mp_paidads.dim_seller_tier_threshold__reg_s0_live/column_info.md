<!-- ads-workspace-gdoc-sync: gdoc_id=1995bS2sUkB62jUoHXT7eHHDxt00qhX8VgZ2uatQIv4o gdoc_url=https://docs.google.com/document/d/1995bS2sUkB62jUoHXT7eHHDxt00qhX8VgZ2uatQIv4o/edit -->

# Columns: mp_paidads.dim_seller_tier_threshold__reg_s0_live

> Note: No DDL found in codebase. Column names and types inferred from SQL usage. Run `--source from-di` for authoritative schema.

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| seller_tier | large_seller | Large seller threshold row |
| seller_tier | medium_seller | Medium seller threshold row |
| seller_tier | small_seller | Small seller threshold row |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: Always filtered with `upper('${region}')` -- all 8 standard regions (ID, MY, PH, SG, TH, TW, VN, BR, MX)
- No filter on `grass_date` or `tz_type` -- the table appears to be non-partitioned or the thresholds are region-scoped only

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| seller_tier | string | Tier label (large_seller / medium_seller / small_seller) | - | - |
| min_value_usd | double | Minimum USD GMV threshold for the tier | - | - |
