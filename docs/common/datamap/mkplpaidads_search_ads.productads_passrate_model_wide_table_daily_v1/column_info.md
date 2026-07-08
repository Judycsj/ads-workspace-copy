<!-- ads-workspace-gdoc-sync: gdoc_id=1abDN9okHcRYtaR-EIIqEefArUoffeyOUb8AQSGBb3h0 gdoc_url=https://docs.google.com/document/d/1abDN9okHcRYtaR-EIIqEefArUoffeyOUb8AQSGBb3h0/edit -->

# Columns: mkplpaidads_search_ads.productads_passrate_model_wide_table_daily_v1

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| item_type | cold_start | Cold start item (new items with no historic performance data) |
| item_type | empty_order_expand | Empty order expansion item (items with no recent orders) |
| grass_region | ID | Indonesia |
| grass_region | TH | Thailand |
| grass_region | MY | Malaysia |
| grass_region | VN | Vietnam |
| grass_region | SG | Singapore |
| grass_region | PH | Philippines |
| grass_region | TW | Taiwan |
| grass_region | BR | Brazil |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: `IN ('ID','TH','MY','VN','SG','PH','TW')` -- Asian markets (passrate model training/inference); `IN ('BR')` -- Brazil (US task); `IN ('ID','TH','MY','VN','SG','PH','TW','BR')` -- all 8 regions (reserve strategy)
- `grass_date`: single day `= date('YYYY-MM-DD')` or range `BETWEEN date() AND date()`
- `item_type`: `'cold_start'` (reserve strategy cold start candidate selection) / `'empty_order_expand'` (reserve strategy empty order expansion)
- `pricing_type`: not directly filtered on wide table; used via upstream joins (`IN (11,15)` for Product Ads; `IN (24,25,27)` for GMS)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| pricing_type | int | Pricing type ID (from ads features table) | - | - |
| ads_id | bigint | Ad group ID | - | - |
| shop_id | bigint | Shop ID | - | - |
| item_id | bigint | Item ID | - | - |
| l1_cat | bigint | Level-1 category ID | - | - |
| l2_cat | bigint | Level-2 category ID | - | - |
| discount | double | Item discount (from item features) | - | - |
| free_shipping | boolean | Free shipping flag (from item features) | - | - |
| creation_elapsed_duration | double | Days since item creation | - | - |
| stock | int | Stock quantity | - | - |
| cspu_type | bigint | CSPU type ID | - | - |
| is_p0_cspu_type | int | Is P0 priority CSPU type flag | - | - |
| platform_impression_cnt_7d | double | Platform impression count (7-day window) | - | - |
| platform_click_cnt_7d | double | Platform click count (7-day window) | - | - |
| platform_atc_cnt_7d | double | Platform add-to-cart count (7-day window) | - | - |
| platform_order_cnt_7d | double | Platform order count (7-day window) | - | - |
| platform_impression_cnt_14d | double | Platform impression count (14-day window) | - | - |
| platform_click_cnt_14d | double | Platform click count (14-day window) | - | - |
| platform_atc_cnt_14d | double | Platform add-to-cart count (14-day window) | - | - |
| platform_order_cnt_14d | double | Platform order count (14-day window) | - | - |
| platform_impression_cnt_30d | double | Platform impression count (30-day window) | - | - |
| platform_click_cnt_30d | double | Platform click count (30-day window) | - | - |
| platform_atc_cnt_30d | double | Platform add-to-cart count (30-day window) | - | - |
| platform_order_cnt_30d | double | Platform order count (30-day window) | - | - |
| platform_ctr_7d | double | Platform CTR = click / impression (7-day) | - | - |
| platform_cr_7d | double | Platform CVR = order / click (7-day) | - | - |
| platform_atc_cr_7d | double | Platform ATC rate = atc / click (7-day) | - | - |
| platform_ctr_14d | double | Platform CTR (14-day window) | - | - |
| platform_cr_14d | double | Platform CVR (14-day window) | - | - |
| platform_atc_cr_14d | double | Platform ATC rate (14-day window) | - | - |
| platform_ctr_30d | double | Platform CTR (30-day window) | - | - |
| platform_cr_30d | double | Platform CVR (30-day window) | - | - |
| platform_atc_cr_30d | double | Platform ATC rate (30-day window) | - | - |
| platform_ctcvr_7d | double | Platform CTCVR = order / impression (7-day) | - | - |
| platform_ctcvr_14d | double | Platform CTCVR (14-day window) | - | - |
| platform_ctcvr_30d | double | Platform CTCVR (30-day window) | - | - |
| create_time | date | Item creation date | - | - |
| campaign_daily_quota_usd | double | Campaign daily budget quota (USD) | - | - |
| price_usd | double | Bid price (USD) | - | - |
| target_roi | double | Target ROI for campaign bidding | - | - |
| cpa | double | Cost per action | - | - |
| l1_campaign_daily_quota_usd_percentile | double | L1 category campaign daily quota percentile | - | - |
| l1_price_usd_percentile | double | L1 category bid price percentile | - | - |
| l1_troi_percentile | double | L1 category target ROI percentile | - | - |
| l1_cpa_percentile | double | L1 category CPA percentile | - | - |
| l1_l2_campaign_daily_quota_usd_percentile | double | L1+L2 category campaign daily quota percentile | - | - |
| l1_l2_price_usd_percentile | double | L1+L2 category bid price percentile | - | - |
| l1_l2_troi_percentile | double | L1+L2 category target ROI percentile | - | - |
| l1_l2_cpa_percentile | double | L1+L2 category CPA percentile | - | - |
| ads_total_impression_cnt_7d | bigint | Ads total impression count (7-day window) | - | - |
| ads_total_click_cnt_7d | bigint | Ads total click count (7-day window) | - | - |
| ads_total_add_to_cart_cnt_7d | bigint | Ads total ATC count (7-day window) | - | - |
| ads_total_order_cnt_7d | bigint | Ads total order count (7-day window) | - | - |
| ads_total_impression_cnt_14d | bigint | Ads total impression count (14-day window) | - | - |
| ads_total_click_cnt_14d | bigint | Ads total click count (14-day window) | - | - |
| ads_total_add_to_cart_cnt_14d | bigint | Ads total ATC count (14-day window) | - | - |
| ads_total_order_cnt_14d | bigint | Ads total order count (14-day window) | - | - |
| ads_total_impression_cnt_30d | bigint | Ads total impression count (30-day window) | - | - |
| ads_total_click_cnt_30d | bigint | Ads total click count (30-day window) | - | - |
| ads_total_add_to_cart_cnt_30d | bigint | Ads total ATC count (30-day window) | - | - |
| ads_total_order_cnt_30d | bigint | Ads total order count (30-day window) | - | - |
| ads_ctr_7d | double | Ads CTR = click / impression (7-day) | - | - |
| ads_ctr_14d | double | Ads CTR (14-day window) | - | - |
| ads_ads_ctr_30d | double | Ads CTR (30-day window) | - | - |
| ads_atc_cr_7d | double | Ads ATC rate = atc / click (7-day) | - | - |
| ads_atc_cr_14d | double | Ads ATC rate (14-day window) | - | - |
| ads_atc_cr_30d | double | Ads ATC rate (30-day window) | - | - |
| ads_cr_7d | double | Ads CVR = order / click (7-day) | - | - |
| ads_cr_14d | double | Ads CVR (14-day window) | - | - |
| ads_cr_30d | double | Ads CVR (30-day window) | - | - |
| ads_ctcvr_7d | double | Ads CTCVR = order / impression (7-day) | - | - |
| ads_ctcvr_14d | double | Ads CTCVR (14-day window) | - | - |
| ads_ctcvr_30d | double | Ads CTCVR (30-day window) | - | - |
| ads_first_delivery_date | date | Ads first delivery date | - | - |
| delivery_elapsed_duration | double | Days since ads first delivery | - | - |
| item_type | string | Item type tag: cold_start / empty_order_expand (from valid items table) | - | - |
| campaign_id | bigint | Campaign ID (from valid items table) | - | - |
| avg_pctr_7d | double | Avg predicted CTR score (7-day, from score model) | - | - |
| avg_pcr_7d | double | Avg predicted CVR score (7-day, from score model) | - | - |
| avg_pctcvr_7d | double | Avg predicted CTCVR score (7-day, from score model) | - | - |
| avg_pctr_14d | double | Avg predicted CTR score (14-day, from score model) | - | - |
| avg_pcr_14d | double | Avg predicted CVR score (14-day, from score model) | - | - |
| avg_pctcvr_14d | double | Avg predicted CTCVR score (14-day, from score model) | - | - |
| grass_date | date | [PARTITION] Data partition date | - | - |
| grass_region | string | [PARTITION] Region code (ID/TH/MY/VN/SG/PH/TW/BR) | - | - |
