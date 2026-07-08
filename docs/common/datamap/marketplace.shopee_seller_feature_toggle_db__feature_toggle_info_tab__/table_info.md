<!-- ads-workspace-gdoc-sync: gdoc_id=1tPzh-_6hyYfc4fwLfMOJt47BKfohDf1qZ0Izuo9EwIQ gdoc_url=https://docs.google.com/document/d/1tPzh-_6hyYfc4fwLfMOJt47BKfohDf1qZ0Izuo9EwIQ/edit -->

# marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__

## Description

- **Desc:** Seller feature toggle configuration table from Marketplace platform. Stores feature toggle definitions including feature keys, status, and feature modes. Used by Ads team to identify whitelisted features (e.g., auto-rebate, ROAS protection) via feature_key lookup. This is a region-sharded table (suffix `__{region}_df`).
- **Granularity:** feature_id (one row per feature toggle entry)
- **Use Case:** ROI2/MPD auto-rebate whitelist construction, feature toggle status check for product_ads_gms_auto_rebate / product_ads_gms_mpd_roas_protection
- **Update Frequency:** Continuous (snapshot table, `_df` suffix indicates daily full dump)

## Key Metrics

- Not applicable (dimension/config table, no numeric metrics)

## Key Dimensions

- feature_key: Feature identifier string (e.g., 'product_ads_gms_auto_rebate', 'product_ads_gms_mpd_roas_protection')
- feature_status: Toggle status (1 = enabled)
- feature_id: Feature unique ID, used to JOIN with feature_toggle_tag_mapping_tab
- feature_mode: Toggle mode (2, 4, 5 observed in queries — e.g., ModeOpenToNone, GrayScaleByShopId)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - (region-sharded table, no standard partition) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, CO, CL (inferred from workflow regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | Marketplace |
| Business Domain | Seller Feature Toggle |
| DW Layer | ODS (raw config snapshot) |

## Popularity

- Studio Tasks References: 11 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
