<!-- ads-workspace-gdoc-sync: gdoc_id=1MTPb7ZEK8zViCMVZTVHvzskwRPiftUq8UHqMqgGzams gdoc_url=https://docs.google.com/document/d/1MTPb7ZEK8zViCMVZTVHvzskwRPiftUq8UHqMqgGzams/edit -->

# Columns: marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

Not applicable — this is a dimension/config table with no numeric aggregation fields.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| feature_status | 1 | Enabled |
| feature_mode | 2 | ModeOpenToNone (inferred from code comment) |
| feature_mode | 4 | (specific mode, see feature toggle docs) |
| feature_mode | 5 | GrayScaleByShopId (inferred from code comment) |

### 常见 WHERE 值 (Common Filter Values)

- `feature_key`: 'product_ads_gms_auto_rebate' (auto-rebate whitelist), 'product_ads_gms_mpd_roas_protection' (ROI2/MPD ROAS protection whitelist)
- `feature_status`: 1 (enabled, used in all observed queries)
- `feature_mode`: IN (2, 4, 5) — used when filtering for specific toggle modes

## All Columns

> DDL not found in codebase (external Marketplace table). Columns below are inferred from SQL usage.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| feature_id | bigint (inferred) | Feature toggle unique ID, used to JOIN with tag_mapping_tab | - | - |
| feature_key | string (inferred) | Feature identifier string (e.g., 'product_ads_gms_auto_rebate') | - | - |
| feature_status | int (inferred) | Toggle status: 1 = enabled | - | - |
| feature_mode | int (inferred) | Toggle mode: 2/4/5 observed | - | - |
