<!-- ads-workspace-gdoc-sync: gdoc_id=1LO4P6L7BnnD3lMD89ryEo3OCOyMjibMGF28e5bbqJao gdoc_url=https://docs.google.com/document/d/1LO4P6L7BnnD3lMD89ryEo3OCOyMjibMGF28e5bbqJao/edit -->

# mp_paidads.dim_local_scs_shop_list

## Description

- **Desc:** Lookup table listing shop_ids classified as "Local SCS" (Supply Chain Services). A simple list maintained externally and consumed by dim_shop_info and dim_advertiser ETL to tag shops for 1P seller classification (`seller_type_1p`).
- **Granularity:** shop_id (one row per SCS shop)
- **Use Case:** 1P seller type classification in dim_shop_info and dim_advertiser ETLs; if a shop_id exists in this table, `seller_type_1p` is set to 'Local SCS' (overriding other classifications like Lovito/SCS)
- **Update Frequency:** Unknown (table is populated externally, not by paidads-alg studio_tasks)

## Key Metrics

This is a pure lookup/dimension list table. No aggregatable metrics. The only value used is the existence check (`local_scs = 1`).

## Key Dimensions

- `shop_id`: Shop identifier (primary key), used for LEFT JOIN lookup

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - (no partition filters observed in code) |
| HDFS Path | - |
| Retention | - |
| Column Count | 1 (shop_id, inferred from usage) |
| Region Coverage | N/A (global list, no region filter applied) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 38 files (all read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
