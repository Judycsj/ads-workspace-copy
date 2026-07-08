<!-- ads-workspace-gdoc-sync: gdoc_id=1MEmeGkXRelmBbWU8480MHdosF7ZY9z7szNMkgTxLRY0 gdoc_url=https://docs.google.com/document/d/1MEmeGkXRelmBbWU8480MHdosF7ZY9z7szNMkgTxLRY0/edit -->

# cncbbi_general.shop_level_shop_info_shopee_td

## Description

- **Desc:** Shop-level information and labeling table from Cncbbi General, containing shop classification attributes such as cross-border (CB) flag, seller type (1P/3P), and SIP affiliation status. Used across the Ads codebase primarily for shop filtering, classification, and exclusion logic.
- **Granularity:** Region x Shop (one row per shop per grass_region)
- **Use Case:**
  - Incentive seller list generation -- exclude CB/1P/SIP shops to identify target advertisers
  - Ads supply data dashboards -- build shop exclusion lists for supply growth analysis
  - Accident compensation -- classify affected shops as CB vs local for rebate calculation
  - AB experiment analysis -- tag shops as 1P (SCS/Lovito) for experiment segmentation
  - Net revenue breakdown -- join with revenue data to split metrics by seller type
- **Update Frequency:** Unknown (not produced by paidads-alg codebase)

## Key Metrics

*(This is a dimension/label table; no metrics are aggregated from it directly.)*

## Key Dimensions

- **Region:** grass_region (standard 8 regions: ID, MY, PH, SG, TH, TW, VN, BR)
- **Shop Identity:** shop_id, seller_type, seller_type_1p
- **Shop Flags:** is_cb_shop, is_1p

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | Standard 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) + others |
| DQC Status | - |
| Table Size | - |

## Business Properties

*Not yet populated. Run `--source from-di` to fill.*

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | Cncbbi General |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 21 files (0 write, 21 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
