<!-- ads-workspace-gdoc-sync: gdoc_id=1rjzUtuvmwsdcWibfgjPb0UVQ4zl2DtEKtWXMDhR9y4o gdoc_url=https://docs.google.com/document/d/1rjzUtuvmwsdcWibfgjPb0UVQ4zl2DtEKtWXMDhR9y4o/edit -->

# Columns: mp_item.dim_item__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a dimension table — all fields are non-additive attributes. No SUM(DISTINCT) patterns detected since there are no metrics to aggregate.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| status | 1 | Active item (commonly filtered) |
| shop_status | 1 | Active shop |
| seller_status | 1 | Active seller |
| is_free_shipping | 1 | Free shipping enabled |
| is_official_shop | 1 | Official/branded shop |
| tz_type | 'local' | Local timezone (most common, ~90% queries) |
| tz_type | 'regional' | Regional timezone (less common) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~90% of queries) — standard for item dimension lookups
- `grass_region`: Standard 8 regions ('ID','MY','PH','SG','TH','TW','VN','BR'); some workflows include 'MX','US'
- `grass_date`: Almost always yesterday / `date('${BIZ_PRE_DAY}')` — single day lookup
- `status`: 1 (active items only) — very common filter
- `shop_status`: 1 (active shop) — often combined with `status = 1`
- `seller_status`: 1 (active seller) — often combined with `status = 1` and `shop_status = 1`
- `price_usd`: > 0 (filter out zero-price items)
- `global_brand_details`: IS NOT NULL (brand ads workflows)
- `is_official_shop`: 1 (brand/official shop workflows)
- `level1_global_be_category_id`: IS NOT NULL (category-based analysis)

## All Columns

Source: DataMap (from-di), 103 columns total.

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | pk@item id | - | - |
| mtsku_item_id | bigint | property@ID of mtsku item | - | - |
| shop_id | bigint | property@ID of the shop | - | - |
| shop_name | string | property@Name of the shop | - | - |
| seller_id | bigint | property@User ID of seller | - | - |
| seller_name | string | property@User name of seller | - | - |
| seller_status | bigint | property@Status of seller.When seller_status =1, it indicates that the seller is normal. | - | - |
| shop_status | bigint | property@Status of shop | - | - |
| is_holiday_mode | tinyint | tag@Whether the shop is on holiday mode. When is_holiday_mode is 0 or null, it indicates that this day is not in holiday. | - | - |
| is_official_shop | tinyint | tag@Whether the shop is official shop | - | - |
| is_ccb_shop | tinyint | tag@Whether the shop is cashback shop | - | - |
| is_cnls | tinyint | tag@whether shop is china local seller shop | - | - |
| shop_tags | struct | property@shop flags. is_official_shop: official shop, is_ccb_shop: coin cashback shop, is_supermarket_shop: shopee supermarket, is_preferred_shop: preferred, is_preferred_plus_shop: preferred plus,... | - | - |
| is_bi_excluded_shop | tinyint | tag@whether shop is bi excluded shop | - | - |
| name | string | property@name of item | - | - |
| condition | bigint | property@condition of item | - | - |
| create_timestamp | bigint | property@item create unixtime | - | - |
| create_datetime | string | property@item create local datetime in yyyy-MM-dd HH:mm:ss | - | - |
| status | bigint | tag@Status of item. When status = 1, it indicates that this item is normal. | - | - |
| rating_score | decimal(25,10) | property@Average rating score of the item | - | - |
| rating_total_cnt | bigint | property@Total count of ratings on the item | - | - |
| rating_with_comment_cnt | bigint | property@Count of ratings with comment | - | - |
| rating_with_media_cnt | bigint | property@Count of ratings with media | - | - |
| comment_cnt | bigint | deprecated. property@Total count of comments on the items | - | - |
| sold_cnt | bigint | property@Sold count of item after cleaning logic by BE | - | - |
| last_30days_sold_cnt | bigint | property@last 30days Sold count of item | - | - |
| price | decimal(25,10) | property@Price of the item around midnight local time (lowest price of all models) | - | - |
| price_usd | decimal(25,10) | property@Price of the item around midnight local time in USD | - | - |
| price_max | decimal(25,10) | property@Max price among all models around midnight local time | - | - |
| price_max_usd | decimal(25,10) | property@Max price among all models around midnight local time in USD | - | - |
| price_before_discount | decimal(25,10) | property@Price of the item before discount around midnight local time | - | - |
| price_before_discount_usd | decimal(25,10) | property@Price before discount in USD | - | - |
| price_before_discount_max | decimal(25,10) | property@Max price of item before discount among all models | - | - |
| price_before_discount_max_usd | decimal(25,10) | property@Max price before discount in USD | - | - |
| shopee_rebate_amt | decimal(25,10) | property@Amount of rebate provided by Shopee for seller item promotion (local currency) | - | - |
| shopee_rebate_amt_usd | decimal(25,10) | property@Amount of rebate in USD | - | - |
| discount_pct | decimal(25,10) | property@Discount percentage of the item | - | - |
| display_discount_pct | decimal(25,10) | property@Display Discount Percentage on Front End | - | - |
| stock | bigint | property@Stock of the item displayed | - | - |
| estimated_days_to_ship | bigint | property@Item level estimated days to ship | - | - |
| weight | decimal(25,10) | property@Weight of the item (KG) | - | - |
| dim_width | decimal(25,10) | property@Width of the item (cm) | - | - |
| dim_length | decimal(25,10) | property@Length of the item (cm) | - | - |
| dim_height | decimal(25,10) | property@Height of the item (cm) | - | - |
| dim_unit | bigint | property@Unit of item dimension | - | - |
| size_chart | string | property@hash of size chart image | - | - |
| size_chart_template_id | bigint | property@id of size chart template | - | - |
| transparent_background_image | string | property@hash of transparent background image | - | - |
| is_pre_order | tinyint | tag@Whether if the item is a pre-order item | - | - |
| is_virtual_sku | bigint | tag@Whether item is a virtual package SKU | - | - |
| has_lowest_price_guarantee | bigint | property@indicate if item has lowest price guarantee | - | - |
| min_purchase_quantity | bigint | property@minimum purchase quantity of item | - | - |
| item_order_level_overall_purchase_limit | bigint | property@item order level overall purchase limit | - | - |
| modify_timestamp | bigint | property@item modify unixtime | - | - |
| modify_datetime | string | property@item modify local datetime in yyyy-MM-dd HH:mm:ss | - | - |
| item_serial_no | string | property@serial number/sku of the item | - | - |
| shipping_info | string | property@Shipping channels information (JSON structure) | - | - |
| gtin | string | property@GTIN global trade identifier | - | - |
| item_flag | bigint | property@flag of item | - | - |
| is_free_shipping | tinyint | tag@Whether the item supports free shipping | - | - |
| is_cod | tinyint | tag@Whether the product supports Cash on Delivery | - | - |
| is_sbs | tinyint | tag@Whether the item is serviced by shopee | - | - |
| is_cc | tinyint | tag@is credit card label | - | - |
| is_cc_instalment | tinyint | tag@is credit card instalment label | - | - |
| is_non_cc_instalment | tinyint | tag@is non credit card instalment label | - | - |
| is_domestic_stocked | tinyint | tag@is domestic stocked label | - | - |
| is_overseas_stocked | tinyint | tag@is overseas stocked label | - | - |
| is_adult | tinyint | tag@is adult label | - | - |
| is_dangerous_goods | tinyint | property@is dangerous goods label. Maintained by seller. | - | - |
| level1_global_be_category_id | bigint | property@Level 1 global backend category ID | - | - |
| level2_global_be_category_id | bigint | property@Level 2 global backend category ID | - | - |
| level3_global_be_category_id | bigint | property@Level 3 global backend category ID | - | - |
| level4_global_be_category_id | bigint | property@Level 4 global backend category ID | - | - |
| level5_global_be_category_id | bigint | property@Level 5 global backend category ID | - | - |
| level1_global_be_category | string | property@Level 1 global backend category name | - | - |
| level2_global_be_category | string | property@Level 2 global backend category name | - | - |
| level3_global_be_category | string | property@Level 3 global backend category name | - | - |
| level4_global_be_category | string | property@Level 4 global backend category name | - | - |
| level5_global_be_category | string | property@Level 5 global backend category name | - | - |
| global_be_category_id | bigint | property@Global backend category id of the leaf node | - | - |
| global_be_category | string | property@Global backend category name of the leaf node | - | - |
| global_be_category_level | bigint | property@Global backend category level of the leaf node | - | - |
| global_be_category_details | struct | property@global category details including id, name, local name | - | - |
| global_brand_details | struct | property@global brand columns including id, name, local_name, local_synonyms | - | - |
| global_attribute_details | struct | property@global attribute details input by seller or created by algo | - | - |
| fe_display_categories | array | property@List of FE display category id:name paths | - | - |
| kpi_categories | array | property@List of KPI category id:name paths | - | - |
| tier_variation | array | property@All model variation details | - | - |
| std_tier_variation | array | property@All model standard variation details | - | - |
| scenario | tinyint | property@scenario, COMMON=0; LIVESKU=1 | - | - |
| br_invoice_option | struct | property@invoice info for BR | - | - |
| ssp_id | bigint | deprecated. property@standard product id | - | - |
| authorised_brand_id | bigint | property@Authorised Resellers Brand ID | - | - |
| touch_timestamp | bigint | property@touch_timestamp, initialized by ctime, modified by boost time | - | - |
| is_wholesale_available | tinyint | tag@is wholesale available | - | - |
| is_spu_vsku | tinyint | tag@is spu vsku item | - | - |
| item_installation_service_info | string | property@item installation service info | - | - |
| dangerous_goods_categorization | bigint | 1:DG A 2:DG B 3:DG C 4:DG D. Data after 2025/12/02 | - | - |
| is_shopee_dangerous_goods | tinyint | property@is shopee dangerous goods. Maintained by shopee. Data after 2026/04/08 | - | - |
| tz_type | string | Partition@timezone type for the data | - | - |
| grass_region | string | Partition@region | - | - |
| grass_date | date | Partition@event happen date | - | - |
| is_cb_shop | tinyint | partition@Whether shop is cross border shop | - | - |
