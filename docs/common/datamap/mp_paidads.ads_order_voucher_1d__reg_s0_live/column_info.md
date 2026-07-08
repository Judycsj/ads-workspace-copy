<!-- ads-workspace-gdoc-sync: gdoc_id=1-yA3LWU1eVZk39DTzdWvYypxwxZej_mjQsZOVlBNJU4 gdoc_url=https://docs.google.com/document/d/1-yA3LWU1eVZk39DTzdWvYypxwxZej_mjQsZOVlBNJU4/edit -->

# Columns: mp_paidads.ads_order_voucher_1d__reg_s0_live

## Column Usage Notes

### Non-Additive Fields

No SUM(DISTINCT) patterns detected for this table. All voucher amount fields are at order_id x item_id granularity and can be directly summed within the same partition granularity.

### Value Mappings

| Column | Value | Meaning |
|--------|-------|---------|
| match_voucher_click_pricing_type | 11, 15, 24, 25, 27 | ROI3 / Cofund eligible pricing types |
| match_voucher_click_pricing_type | 29 | Package Non-Ads pricing type |
| match_voucher_click_placement | 40, 50 | Voucher-eligible placements (from perf_di broad_order_cnt > 0 filter) |
| non_ads_type | 1 | Nominated for package non-ads (active campaign period) |
| non_ads_type | 2 | Other (default) |
| oa_event_source | 1 | ADS |
| oa_event_source | 2 | ORGANIC |

### Common Filter Values

- `tz_type`: 'local' (~95% queries, dominant usage) / 'regional' (used in some production workflows)
- `grass_region`: standard 8 regions ('ID','MY','PH','SG','TH','TW','VN','BR')
- `ads_voucher_id`: > 0 (filter for ads voucher orders only, most common pattern)
- `ads_voucher_amt_usd`: > 0 (alternative filter for ads voucher cost queries)
- `match_voucher_click_pricing_type`: IN (11, 15, 24, 25, 27) — ROI3 cofund performance analysis

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| order_id | bigint | - | - | - |
| shop_id | bigint | - | - | - |
| item_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| seller_voucher_id | bigint | - | - | - |
| ads_voucher_id | bigint | - | - | - |
| fsv_voucher_id | bigint | - | - | - |
| platform_voucher_id | bigint | - | - | - |
| order_place_datetime | string | - | - | - |
| order_paid_datetime | string | - | - | - |
| item_price_usd | bigint | Item price in USD (unit: 1e-5, need /1e5 for actual USD) | - | - |
| ab_sign | string | AB test sign from order-attributed perf_di record | - | - |
| plan_bucket_list | array\<bigint\> | - | - | - |
| platform_voucher_amt_usd | decimal(25,10) | Platform voucher amount in USD | - | - |
| seller_voucher_amt_usd | decimal(25,10) | Seller voucher amount in USD (includes ads voucher) | - | - |
| ads_voucher_amt_usd | decimal(25,10) | Ads voucher amount in USD (= seller_voucher_amt_usd when ads_voucher_id matched) | - | - |
| fsv_voucher_amt_usd | decimal(25,10) | Free shipping voucher amount in USD | - | - |
| pricing_type | int | Pricing type from order-attributed perf_di record | - | - |
| placement | bigint | Placement from order-attributed perf_di record | - | - |
| ads_id | bigint | Ads ID from order-attributed perf_di record | - | - |
| voucher_details_json | string | JSON details from matched voucher click | - | - |
| match_voucher_click_datetime | string | Datetime of matched voucher click (within 48h before order) | - | - |
| match_voucher_click_ads_id | bigint | Ads ID from matched voucher click | - | - |
| match_voucher_click_pricing_type | int | Pricing type from matched voucher click | - | - |
| match_voucher_click_placement | bigint | Placement from matched voucher click | - | - |
| match_voucher_click_ab_sign | string | AB sign from matched voucher click (used for strategy/model experiment tagging) | - | - |
| match_voucher_click_entrance | bigint | Entrance from matched voucher click | - | - |
| voucher_cofund_ratio | double | Platform co-fund ratio from bid_rerank_trace ($.platform_spend_ratio) | - | - |
| entrance | bigint | Entrance from order-attributed perf_di record | - | - |
| platform_voucher_amt_local | decimal(25,10) | Platform voucher amount in local currency | - | - |
| seller_voucher_amt_local | decimal(25,10) | Seller voucher amount in local currency | - | - |
| ads_voucher_amt_local | decimal(25,10) | Ads voucher amount in local currency | - | - |
| fsv_voucher_amt_local | decimal(25,10) | Free shipping voucher amount in local currency | - | - |
| net_sv_rebate_by_seller_amt_local | decimal(25,10) | Net seller voucher rebate by seller in local currency | - | - |
| net_sv_rebate_by_seller_amt_usd | decimal(25,10) | Net seller voucher rebate by seller in USD | - | - |
| net_sv_rebate_by_external_amt_local | decimal(25,10) | Net seller voucher rebate by external in local currency | - | - |
| net_sv_rebate_by_external_amt_usd | decimal(25,10) | Net seller voucher rebate by external in USD | - | - |
| net_pv_rebate_by_seller_amt_local | decimal(25,10) | Net platform voucher rebate by seller in local currency | - | - |
| net_pv_rebate_by_seller_amt_usd | decimal(25,10) | Net platform voucher rebate by seller in USD | - | - |
| net_pv_rebate_by_external_amt_local | decimal(25,10) | Net platform voucher rebate by external in local currency | - | - |
| net_pv_rebate_by_external_amt_usd | decimal(25,10) | Net platform voucher rebate by external in USD | - | - |
| platform_order_gmv_amt_local | decimal(25,10) | Platform order GMV in local currency | - | - |
| platform_order_gmv_amt_usd | decimal(25,10) | Platform order GMV in USD | - | - |
| non_ads_type | tinyint | 1=nominated package non-ads, 2=other | - | - |
| package_request_id | bigint | Package request ID (only when non_ads_type=1) | - | - |
| package_co_fund_ratio | double | Package co-fund ratio (only when non_ads_type=1) | - | - |
| gross_ads_voucher_amt | decimal(25,10) | Gross ads voucher amount in local (sv_rebate_by_shopee_amt, newer schema) | - | - |
| gross_ads_voucher_amt_usd | decimal(25,10) | Gross ads voucher amount in USD (newer schema) | - | - |
| seller_gmv_amt | decimal(25,10) | Seller GMV in local currency (newer schema) | - | - |
| seller_gmv_amt_usd | decimal(25,10) | Seller GMV in USD (newer schema) | - | - |
| match_voucher_click_campaign_id | bigint | Campaign ID from matched voucher click (newer schema) | - | - |
| match_voucher_click_algo_json_data | string | Algo JSON data from matched voucher click (newer schema) | - | - |
| match_voucher_click_entrance_group | string | Entrance group from matched voucher click (newer schema) | - | - |
| oa_event_source | int | Event source: 1=ADS, 2=ORGANIC (newer schema) | - | - |
| match_voucher_click_page_type | string | Page type from matched voucher click (newer schema) | - | - |
| match_voucher_click_page_section | string | Page section from matched voucher click (newer schema) | - | - |
| match_voucher_click_target_type | string | Target type from matched voucher click (newer schema) | - | - |
| tz_type | string | [PARTITION] Timezone type: 'local' or 'regional' | - | - |
| grass_region | string | [PARTITION] Region code: ID, MY, PH, SG, TH, TW, VN, BR | - | - |
| grass_date | date | [PARTITION] Business date | - | - |
