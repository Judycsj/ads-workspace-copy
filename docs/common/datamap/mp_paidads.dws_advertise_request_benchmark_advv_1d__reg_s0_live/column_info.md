<!-- ads-workspace-gdoc-sync: gdoc_id=1tNvkXR57oFpeFSqBl_2n_vRCoEyQ6cIFeI8dpj5fJHY gdoc_url=https://docs.google.com/document/d/1tNvkXR57oFpeFSqBl_2n_vRCoEyQ6cIFeI8dpj5fJHY/edit -->

# Columns: mp_paidads.dws_advertise_request_benchmark_advv_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段在跨 feature_groups/product_types 聚合时必须使用 MAX 或从更细粒度先 SUM 再聚合：

跨维度聚合时需用 MAX/SUM DISTINCT (在 request_id x ads_id 级别这些值在 explode 后重复):
- `sum_deduction_price_usd_1d`, `deduction_price_cnt_1d`
- `sum_cpc_deduction_price_usd_1d`, `cpc_deduction_price_cnt_1d`
- `sum_ocpm_deduction_price_usd_1d`, `ocpm_deduction_price_cnt_1d`
- `sum_bid_price_usd_1d`, `bid_price_cnt_1d`
- `sum_cpc_bid_price_usd_1d`, `cpc_bid_price_cnt_1d`
- `sum_ocpm_bid_price_usd_1d`, `ocpm_bid_price_cnt_1d`
- `padvv_usd_1d`

原因: 这些字段在 explode(feature_groups) 和 explode(product_types) 时会被复制多份，直接 SUM 会导致重复计算。Read 文件和 Write 文件内部使用 MAX 或窗口函数去重处理。

### 枚举值映射 (Value Mappings)

**platform:**

| Value | Meaning |
|-------|---------|
| 1 | ios_web |
| 2 | ios_app |
| 3 | android_web |
| 4 | android_app |
| 5 | pc_web |
| 9 | android_app_lite |
| other | other |

**feature_groups (ARRAY<STRING>):**

| Value | Meaning |
|-------|---------|
| Search | Search entrance |
| Search_RCMD | Search/RCMD convergence |
| Daily Discover | Daily Discover entrance |
| DD_PP Unify | DD + PP unified |
| RCMD Unify | RCMD unified |
| You May Also Like | YMAL entrance |
| YMAL_Cart | YMAL + Cart convergence |
| Cart Recommendation | Cart entrance |
| Cart Unify | Cart unified |
| Order Successful Recommendation | Order success entrance |
| Order Detail Page YMAL | Order detail YMAL |
| My Purchase Page YMAL | Purchase page YMAL |
| Me YMAL | Me page YMAL |
| Shop YMAL | Shop YMAL |
| SIP YMAL | SIP YMAL |
| Shop Main Browsing | Shop main browsing |
| Shop Product Tab | Shop product tab |
| Shop Recommended For You | Shop recommended |
| Shop Category Tab | Shop category tab |
| Shop Hot Deals | Shop hot deals |
| Shop Campaign Tab Just For You | Shop campaign JFY |
| Shop Just For You | Shop JFY |
| From the Same Shop | Same shop cross-sell |
| Shop_Unify | Shop unified |
| Game | Game ads |
| Livestream | Livestream ads |
| video_* | Various video ads placements |
| others | Uncategorized |
| __ALL__ | Aggregation sentinel |

**product_types (ARRAY<STRING>):**

| Value | Meaning |
|-------|---------|
| simple_ocpc | Simple OCPC (pricing_type=4) |
| simple_mode_boost | Simple mode boost (pricing_type=4/8, attr_data_type=1) |
| simple_roas | Simple ROAS (pricing_type=8) |
| roi2.0_target (cpc) | ROI2.0 target CPC (pricing_type=11) |
| roi2.0_target (cps) | ROI2.0 target CPS (pricing_type=20) |
| roi2.0_target | ROI2.0 target (parent of cpc/cps) |
| roi2.0_simple | ROI2.0 simple (pricing_type=15) |
| roi2.0_simple (ads) | ROI2.0 simple ads-only (attr_data_type=0/null) |
| roi2.0_simple (organic) | ROI2.0 simple organic (attr_data_type=1) |
| ROI2.0 | ROI2.0 parent |
| others | Other product types |
| __ALL__ | Aggregation sentinel |

**voucher_types (ARRAY<STRING>):**

| Value | Meaning |
|-------|---------|
| roi3.0 | ROI3.0 voucher (pricing_type in (11,15), bid_voucher_id not null, display_ads_voucher_label != 1) |
| roi3.0_display | ROI3.0 display voucher (display_ads_voucher_label = 1) |
| no_voucher | No voucher (pricing_type in (11,15), bid_voucher_id is null) |
| __ALL__ | Aggregation sentinel |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') -- all queries use this pattern
- `grass_date`: date('${grass_date}') -- daily partition filter
- `user_id > 0`: filters invalid user IDs (used in Search/RCMD AB tests)
- `user_id in (select user_id from user_exp)`: AB test whitelist filter
- 注: pricing_type/entrance filtering is implicit via feature_groups array - queries filter at the array level rather than by raw columns

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| feature_groups | ARRAY<STRING> | Ads Feature group | - | - |
| user_id | BIGINT | Unique user ID | - | - |
| request_id | STRING | Unique identifier for the request | - | - |
| product_types | ARRAY<STRING> | Product type | - | - |
| ads_id | BIGINT | Unique ID for ads | - | - |
| item_id | BIGINT | Unique identifier of an item | - | - |
| campaign_id | BIGINT | Unique identifier of a campaign | - | - |
| pricing_type | INT | Pricing type | - | - |
| placement | BIGINT | Placement | - | - |
| attr_data_type | INT | Attr Data Type | - | - |
| entrance | INT | ADS entrance | - | - |
| sub_entrance | INT | ADS sub entrance | - | - |
| location | BIGINT | Display location of a target | - | - |
| sort_by | STRING | Sorting options that the user chose | - | - |
| target_type | STRING | Target type | - | - |
| revenue_usd_1d | DOUBLE | Revenue in USD from mp_paidads | - | - |
| broad_gmv_usd_1d | DOUBLE | Broad order gmv of ads item in usd | - | - |
| ads_gmv_usd_1d | DOUBLE | Narrow order gmv of ads item in usd | - | - |
| avg_target_cir_1d | DOUBLE | Target cir | - | - |
| direct_advv_cost_usd_1d | DOUBLE | Direct cost of ads item in usd | - | - |
| broad_advv_cost_usd_1d | DOUBLE | Broad cost of ads item in usd | - | - |
| direct_advv_gmv_usd_1d | DOUBLE | Direct advv gmv | - | - |
| broad_advv_gmv_usd_1d | DOUBLE | Broad advv gmv | - | - |
| ads_click_cnt_1d | BIGINT | Click count of ads item | - | - |
| ads_imp_cnt_1d | BIGINT | Impression count of ads item | - | - |
| ads_order_cnt_1d | DOUBLE | Order count of ads item | - | - |
| ads_broad_order_cnt_1d | DOUBLE | Broad Order count of ads item | - | - |
| padvv_usd_1d | DOUBLE | Padvv | - | - |
| ads_location_cnt_1d | DOUBLE | Ads total location | - | - |
| broad_advv_cost_excl_outlier_usd_1d | DOUBLE | Broad advv cost excl outlier | - | - |
| broad_advv_cost_usd_7d | DOUBLE | Broad advv cost 7d | - | - |
| page_type | STRING | Page type (image_search, search, shop, me etc.) | - | - |
| page_section | STRING | Page section (search, rcmd, you_may_also_lick etc.) | - | - |
| plan_bucket_list | ARRAY<BIGINT> | Group IDs (BucketID) of the advertising plan belonging to the experiment | - | - |
| deepadvv_usd_1d | DOUBLE | Deepadvv for roi2.0_simple | - | - |
| top20_ads_location_cnt_1d | DOUBLE | Ads total location for top 20 locations | - | - |
| platform | STRING | Platform (ios_web, ios_app, android_web, android_app, pc_web, other) | - | - |
| main_product_types | ARRAY<STRING> | Main product types | - | - |
| bid_voucher_id | BIGINT | Bid voucher ID | - | - |
| voucher_types | ARRAY<STRING> | Voucher type array | - | - |
| decoded_video_id | BIGINT | Decoded video ID for video ads | - | - |
| deduction_reason | INT | Deduction reason | - | - |
| voucher_details_json | STRING | ROI3 Voucher details | - | - |
| sum_deduction_price_usd_1d | DOUBLE | Deduction price in usd | - | - |
| deduction_price_cnt_1d | DOUBLE | Count of deduction item | - | - |
| sum_cpc_deduction_price_usd_1d | DOUBLE | CPC deduction price in usd | - | - |
| cpc_deduction_price_cnt_1d | DOUBLE | Count of CPC deduction item | - | - |
| sum_ocpm_deduction_price_usd_1d | DOUBLE | OCPM deduction price in usd | - | - |
| ocpm_deduction_price_cnt_1d | DOUBLE | Count of OCPM deduction item | - | - |
| sum_bid_price_usd_1d | DOUBLE | Bid price in usd | - | - |
| bid_price_cnt_1d | DOUBLE | Count of bid item | - | - |
| sum_cpc_bid_price_usd_1d | DOUBLE | CPC bid price in usd | - | - |
| cpc_bid_price_cnt_1d | DOUBLE | Count of CPC bid item | - | - |
| sum_ocpm_bid_price_usd_1d | DOUBLE | OCPM bid price in usd | - | - |
| ocpm_bid_price_cnt_1d | DOUBLE | Count of OCPM bid item | - | - |
