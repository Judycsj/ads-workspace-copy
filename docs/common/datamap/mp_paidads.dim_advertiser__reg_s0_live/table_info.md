<!-- ads-workspace-gdoc-sync: gdoc_id=1E5F5MxI6Uox_9QqA_BF2AND192YFNJ6-dssgNhPozq8 gdoc_url=https://docs.google.com/document/d/1E5F5MxI6Uox_9QqA_BF2AND192YFNJ6-dssgNhPozq8/edit -->

# mp_paidads.dim_advertiser__reg_s0_live

## Description

- **Desc:** Advertiser dimension table that consolidates ads account info, user/shop attributes, seller classification, and feature adoption flags into a single daily snapshot per advertiser. Joins ads_account_tab with dim_user, dim_shop, dim_exchange_rate, dim_item, dws_shop_listing, dim_shop_ext, and target_audience_group_tab to build a comprehensive advertiser profile.
- **Granularity:** daily x shop_id (advertiser) x region
- **Use Case:** Advertiser dimension lookup for downstream DWS tables (dws_advertiser_account_1d, dws_advertiser_trd_order_gmv_nd, dws_advertiser_credit_expiry_td), dim_shop_info daily enrichment, seller tier classification, campaign surge whitelist generation, incentive strategy (FSS/escrow), advertiser feature adoption analysis (auto-topup, auto-budget-increase, auto-escrow, ROI3 voucher)
- **Update Frequency:** Daily

## Key Metrics

This is a dimension table (no aggregatable metrics). Key attributes include:
- Account: balance, account_status, version_tag
- Feature flags: is_auto_topup_enabled, is_campaign_auto_bid_enabled, is_auto_budget_increase_enabled, is_roi_three_voucher_enabled, is_auto_escrow_enabled, is_auto_ads_solution_enabled, adopt_audience_targeting
- Auto-topup settings: auto_topup_threshold_amt, auto_topup_amt, auto_topup_daily_cap_amt (local + USD)
- Auto-budget-increase settings: auto_budget_increase_daily_cap, auto_budget_increase_percentage, auto_budget_increase_effective_types
- Auto-escrow settings: auto_escrow_additional_fee_rate, auto_escrow_fixed_program_fee_rate
- Shop attributes: is_managed_seller, is_official_shop, is_preferred_shop, is_cb_seller, is_self_mcn, is_cb_sip_affiliated, is_local_sip_affiliated
- Shop categories: shop_level1/2_global_be_category, shop_level1/2_fe_display_category, shop_level1/2_kpi_category

## Key Dimensions

- Partition: tz_type, grass_region, grass_date
- Business: shop_id, user_id, seller_type, seller_type_1p, account_status, shop_status

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (inferred from similar tables) |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | ~50 (48 data columns + 3 partition columns) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, AR |
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

- Studio Tasks References: 794 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
