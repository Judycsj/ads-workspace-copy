<!-- ads-workspace-gdoc-sync: gdoc_id=1K_G87dikzseHH-k43zlepxEH7BrjYep0vopzAxF0oBg gdoc_url=https://docs.google.com/document/d/1K_G87dikzseHH-k43zlepxEH7BrjYep0vopzAxF0oBg/edit -->

# mp_item.dim_item__reg_s0_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_item.dim_item__reg_s0_live`
- canonical_table: `mp_item.dim_item__reg_s0_live`
- resolution: `describe:exact`
- source: `datasuite_describe`
- business_docs: `pc2_metrics`

## 使用边界

- 这张表只在命中的业务文档显式声明时作为外部表使用。
- 字段、类型和分区过滤以本文件记录的 DataMap/DESCRIBE 元数据为准。
- 不要把这张表自动加入广告数仓主候选表集合；它只补充业务链路排查。

## 分区和过滤

- inferred_partition_keys: `grass_date`, `grass_region`, `tz_type`
- required_filters: `grass_date`, `grass_region`, `tz_type`

## 字段列表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `item_id` | `bigint` | pk@item id \| source: item_v5_tab.item_id \| |
| `mtsku_item_id` | `bigint` | property@ID of mtsku item \| source: item_v5_tab.extinfo.mtsku_item_id \| |
| `shop_id` | `bigint` | property@ID of the shop \| source: item_v5_tab.shop_id \| |
| `shop_name` | `varchar` | property@Name of the shop \|mp_user.dim_shop.shop_id \| |
| `seller_id` | `bigint` | property@User ID of seller \|mp_user.dim_shop.seller_id \| |
| `seller_name` | `varchar` | property@User name of seller \|mp_user.dim_shop.user_name \| |
| `seller_status` | `bigint` | property@Status of seller \|mp_user.dim_shop.user_status \| |
| `shop_status` | `bigint` | property@Status of shop \|mp_user.dim_shop.status \| |
| `is_holiday_mode` | `tinyint` | tag@Whether the shop is on holiday mode \|mp_user.dim_shop.is_holiday_mode \| 0 , 1 |
| `is_official_shop` | `tinyint` | tag@Whether the shop is official shop \|mp_user.dim_shop.is_official_shop \| 0 , 1 |
| `is_ccb_shop` | `tinyint` | tag@Whether the shop is cashback shop \|mp_user.dim_shop.is_ccb_shop \|0 , 1 |
| `is_cnls` | `tinyint` | tag@whether shop is china local seller shop \|mp_user.dim_shop.is_cnls \|0 , 1 |
| `shop_tags` | `row(is_official_shop tinyint, is_ccb_shop tinyint, is_supermarket_shop tinyint, is_preferred_shop tinyint, is_preferred_plus_shop tinyint, is_fss_shop tinyint, is_fbs tinyint)` | property@shop flags. is_official_shop: official shop, is_ccb_shop: coin cashback shop, is_supermarket_shop: shopee supermarket, is_preferred_shop: preferred, is_preferred_plus_shop: preferred plus, is_fss_shop: free shipping special, is_fbs: fulfilled by shopee \|mp_user.dim_shop shop tags \| |
| `is_bi_excluded_shop` | `tinyint` | tag@whether shop is bi excluded shop \|mp_user.dim_shop.is_bi_excluded \|0 , 1 |
| `name` | `varchar` | property@name of item \| source: item_v5_tab.name \| |
| `condition` | `bigint` | property@condition of item \| source: item_v5_tab.condition \| 0 or -1: NOT_SET; 1: NEW_WITH_TAGS; 2: NEW_WITHOUT_TAGS; 3: NEW_WITH_DEFECTS; 4: USED; 5: NEW_OTHERS; 6: SED_LIKE_NEW; 7: USED_GOOD; 8: USED_ACCEPTABLE; 9: USED_WITH_DEFECTS |
| `create_timestamp` | `bigint` | property@item create unixtime \| source: item_v5_tab.ctime \| |
| `create_datetime` | `varchar` | property@item create local datetime in yyyy-MM-dd HH:mm:ss \| source: item_v5_tab.ctime \| |
| `status` | `bigint` | tag@Status of item \| source: item_v5_tab.status \| 0: ITEM_DELETE // EK: user delete; 1: ITEM_NORMAL; 2: ITEM_REVIEWING // Banned item is updated, under review; 3: ITEM_BANNED // Item quality issue, suspended by Shopee; 4: ITEM_INVALID // EK: BE delete, also known as ADMIN_DELETED. Item has serious quality issue and need to be deleted immediately; 5: ITE... |
| `rating_score` | `decimal(25,10)` | property@Average rating score of the item \| source: item_v5_tab.extinfo.item_rating.rating_star \| |
| `rating_total_cnt` | `bigint` | property@Total count of ratings on the item \|sum(item_v5_tab.extinfo.item_rating.rating_count) \| |
| `rating_with_comment_cnt` | `bigint` | property@Count of ratings with comment \|coalesce(item_v5_tab.extinfo.item_rating_rcount_with_context, 0) \| |
| `rating_with_media_cnt` | `bigint` | property@Count of ratings with media \|coalesce(item_v5_tab.extinfo.item_rating_rcount_with_image, 0) \| |
| `comment_cnt` | `bigint` | property@Total count of comments on the items. //Deprecated. \| source: item_v5_tab.extinfo.comment_cnt \| |
| `sold_cnt` | `bigint` | property@Total Sold count of item after cleaning logic by BE (e.g. remove order brushing) \|item_v5_tab.sold \| |
| `last_30days_sold_cnt` | `bigint` | property@last 30days Sold count of item \|item_v5_tab.extinfo.last_30days_sold_cnt \| |
| `price` | `decimal(25,10)` | property@Price of the item around midnight local time (the lowest price of all models is stored if there are multiple models for the item) *This could include promotion price (e.g. flash sale) if the item is under promotion when the snapshot is taken \|item_price_snapshot.price_min \| |
| `price_usd` | `decimal(25,10)` | property@Price of the item around midnight local time in USD \|item_price_snapshot.price_min / exchange rate \| |
| `price_max` | `decimal(25,10)` | property@Max price among all models around midnight local time \|item_price_snapshot.price_max \| |
| `price_max_usd` | `decimal(25,10)` | property@Max price among all models around midnight local time in USD \|price_max / exchange rate \| |
| `price_before_discount` | `decimal(25,10)` | property@Price of the item before discount around midnight local time (the lowest price of all models is stored if there are multiple models for the item) \|min(item_price_snapshot.price_detail.prices[].normal_price) where normal price is the price of the model before discount \| |
| `price_before_discount_usd` | `decimal(25,10)` | property@Price of the item before discount around midnight local time in USD \|price_before_discount / exchange_rate \| |
| `price_before_discount_max` | `decimal(25,10)` | property@Max price of item before discount among all models around midnight local time \|item_price_snapshot.price_detail.item_aggregated_price_info.normal_price_max \| |
| `price_before_discount_max_usd` | `decimal(25,10)` | property@Max price of item before discount among all models around midnight local time in USD \|price_before_discount_max / exchange_rate \| |
| `shopee_rebate_amt` | `decimal(25,10)` | property@Amount of rebate provided by Shopee for the seller item promotion (local currency) \| source: item_v5_tab.extinfo.rebate_price \| |
| `shopee_rebate_amt_usd` | `decimal(25,10)` | property@Amount of rebate provided by Shopee for the seller item promotion in USD \|shopee_rebate_amt / exchange_rate \| |
| `discount_pct` | `decimal(25,10)` | property@Discount percentage of the item (if there are multiple models, this is for the model with the lowest price) \|price_before_discount- price / price_before_discount *100 \| |
| `display_discount_pct` | `decimal(25,10)` | property@Display Discount Percentage on Front End \|item_price_snapshot.price_detail.item_aggregated_price_info.discount \| |
| `stock` | `bigint` | property@Stock of the item displayed \|item_stock_snapshot.stock_detail.aggregated_stock_info.total_display_stock \| |
| `estimated_days_to_ship` | `bigint` | property@Item level estimated days to ship. max(model level estimated_days to ship) \| source: item_v5_tab.extinfo.estimated_days \| |
| `weight` | `decimal(25,10)` | property@Weight of the item recorded in the system for shipping fee calculation (Not the actual measurement of the item). Unit: KG \| source: item_v5_tab.extinfo.weight \| |
| `dim_width` | `decimal(25,10)` | property@Width of the item recorded in the system for shipping fee calculation (Not the actual measurement of the item). Unit: cm \| source: item_v5_tab.extinfo.dimensions.width \| |
| `dim_length` | `decimal(25,10)` | property@Length of the item recorded in the system for shipping fee calculation (Not the actual measurement of the item). Unit: cm \| source: item_v5_tab.extinfo.dimensions.height \| |
| `dim_height` | `decimal(25,10)` | property@Height of the item recorded in the system for shipping fee calculation (Not the actual measurement of the item). Unit: cm \| source: item_v5_tab.extinfo.dimensions.length \| |
| `dim_unit` | `bigint` | property@Unit of the item recorded in the system for shipping fee calculation (Not the actual measurement of the item) if applicable \| source: item_v5_tab.extinfo.dimensions.unit \| |
| `size_chart` | `varchar` | property@hash of size chart image. image hash can be used to create the url to link to the actual image: https://cf.shopee.sg/file/<image hash> \| source: item_v5_tab.extinfo.size_chart \| |
| `size_chart_template_id` | `bigint` | property@id of size chart template. use to join with dim_size_chart \|item_v5_tab.extinfo.size_chart_template_id \| |
| `transparent_background_image` | `varchar` | property@hash of transparent background image. image hash can be used to create the url to link to the actual image: https://cf.shopee.{region url}/file/<image hash> \| source: item_v5_tab.extinfo.transparent_background_image \| |
| `is_pre_order` | `tinyint` | tag@Whether if the item is a pre-order item \| source: item_v5_tab.extinfo.is_pre_order \|0 , 1 |
| `is_virtual_sku` | `bigint` | tag@Whether item is a virtual sku \|WHEN item_flag&2048=2048 THEN 1 ELSE 0 \|0 , 1 |
| `has_lowest_price_guarantee` | `bigint` | property@indicate if item has lowest price guarantee \| source: item_v5_tab.extinfo.has_lowest_price_guarantee \|0 , 1 |
| `min_purchase_quantity` | `bigint` | property@minimum purchase quantity of item \|coalesce(item_v5_tab.extinfo.min_purchase_limit, 0) \| |
| `item_order_level_overall_purchase_limit` | `bigint` | property@item order level overall purchase limit \|coalesce(item_v5_tab.extinfo.order_max_purchase_limit, 0) \| |
| `modify_timestamp` | `bigint` | property@item modify unixtime \| source: item_v5_tab.mtime \| |
| `modify_datetime` | `varchar` | property@item modify local datetime in yyyy-MM-dd HH:mm:ss \| source: item_v5_tab.mtime \| |
| `item_serial_no` | `varchar` | property@serial number/ sku of the item \| source: item_v5_tab.sku \| |
| `shipping_info` | `varchar` | property@Shipping channels information of the item \| source: item_v5_tab.extinfo.logistics_info \| |
| `gtin` | `varchar` | property@GTIN is a global trade identifier that is input by the seller when they upload an item. It is a basic item level attribute that usually always exist for certain brands \| source: item_v5.extinfo.gtin \| |
| `item_flag` | `bigint` | property@Use product labels instead, flag is deprecating. flag of item \| source: item_v5.flag \|https://apidocs.shopeemobile.com/coreserver/#ItemFlags |
| `is_free_shipping` | `tinyint` | tag@Whether the item supports free shipping \| source: item_v5_tab.flag \|0 , 1 |
| `is_cod` | `tinyint` | tag@Whether the product supports Cash on Delivery. Available for all regions ( -Only works for ID MY TW and TH- Expired) \|label_id=844931086908638 in product label \|0 , 1 |
| `is_sbs` | `tinyint` | tag@Whether the item is serviced by shopee \|WHEN (item_flag&268435456 = 268435456 OR item_flag&536870912 = 536870912) THEN 1 ELSE 0 \|0 , 1 |
| `is_cc` | `tinyint` | tag@is credit card label \|label_id=844931064601283 in product label \| |
| `is_cc_instalment` | `tinyint` | tag@is credit card instalment label \|label_id=844931046478970 in product label \| |
| `is_non_cc_instalment` | `tinyint` | tag@is non credit card instalment label \|label_id=844931026694327 in product label \| |
| `is_domestic_stocked` | `tinyint` | tag@is domestic stocked label \|name LIKE %location_domestic_stocked% in product label \| |
| `is_overseas_stocked` | `tinyint` | tag@is overseas stocked label \|name LIKE %location_overseas_stocked% in product label \| |
| `is_adult` | `tinyint` | tag@is adult label \|label_id=843249807227517 in product label \| |
| `is_dangerous_goods` | `tinyint` | property@is dangerous goods label \|coalesce(item_v5.extinfo.dangerous_goods, 0) \| |
| `level1_global_be_category_id` | `bigint` | property@Level 1 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid \| |
| `level2_global_be_category_id` | `bigint` | property@Level 2 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid \| |
| `level3_global_be_category_id` | `bigint` | property@Level 3 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid \| |
| `level4_global_be_category_id` | `bigint` | property@Level 4 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid \| |
| `level5_global_be_category_id` | `bigint` | property@Level 5 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid \| |
| `level1_global_be_category` | `varchar` | property@Level 1 global backend category ID of the item i.e. Main gloal backend category \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `level2_global_be_category` | `varchar` | property@Level 2 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `level3_global_be_category` | `varchar` | property@Level 3 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `level4_global_be_category` | `varchar` | property@Level 4 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `level5_global_be_category` | `varchar` | property@Level 5 global backend category name of the item \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `global_be_category_id` | `bigint` | property@Global backend category id of the leaf node \| source: item_v5_tab.extinfo.global_cat.catid \| |
| `global_be_category` | `varchar` | property@Global backend category name of the leaf node \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `global_be_category_level` | `bigint` | property@Global backend category level of the leaf node \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `global_be_category_details` | `row(global_be_category_local_name varchar, global_be_category_multi_lang_values array(row(lang varchar, value varchar)), level1_global_be_category_local_name varchar, level1_glo...` | property@global brand columns including id, name, local name and synonyms. local_name: local language name of be_category, multi_lang_values: different language names of be_category \| source: item_v5_tab.extinfo.global_cat.catid join mp_item.dim_global_be_category \| |
| `global_brand_details` | `row(id bigint, name varchar, local_name varchar, local_synonyms array(varchar))` | property@global brand columns including id, name, local name and synonyms. id: brand_id, name: brand_name, local_name: local language brand name, local_synonyms: alternative local language brand names \| source: item_v5_tab.extinfo.global_brand.global_brand_id join shopee_item_global_brand_db__global_brand_tab \| |
| `global_attribute_details` | `row(seller_input array(row(id bigint, name varchar, status_id tinyint, type_id bigint, format_type_id bigint, multi_lang_values array(row(lang varchar, value varchar)), cb_displ...` | property@global attribute details input by seller or created by ds algorithm. seller_input: attribute is input by seller, algo: attribute is created by ds algo. id: bigint, name: attribute name, status_id: attribute status id, type_id: refer to enum, format_type_id: refer to enum, multi_lang_values.lang: different language code, multi_lang_values.value: d... |
| `fe_display_categories` | `array(array(varchar))` | property@List of FE display category id:name (KV pair) paths of the itemStructure: [[FE_cat_level1_id : FE_cat_level1_name, ...FE_cat_level5_id : FE_cat_level5_name], [FE_cat_level1_id : FE_cat_level1_name, ...FE_cat_level3_id : FE_cat_level3_name]]. KV pair is stored as string \| source: item_v5.extinfo.fe_cat_paths.fe_cat_ids join mp_item.dim_fe_display... |
| `kpi_categories` | `array(array(varchar))` | property@List of KPI category id:name (KV pair) paths of the itemStructure: [[KPI_cat_level1_id : KPI_cat_level1_name, ...KPI_cat_level5_id : KPI_cat_level5_name], [KPI_cat_level1_id : KPI_cat_level1_name, ...KPI_cat_level3_id : KPI_cat_level3_name]]. KV pair is stored as string \| source: item_v5.extinfo.kpi_fe_cat_paths.fe_cat_ids join mp_item.dim_kpi_c... |
| `tier_variation` | `array(row(name varchar, options array(varchar), images array(varchar), properties array(row(name varchar, image varchar, color varchar)), type integer))` | property@All model variation details. name: name of variation e.g. size, options: options of variation e.g. XL, images: images hash of variation, properties.name: not used, properties.image: not used, properties.color: not used, type: type of variation \| source: item_v5.extinfo.tier_variation \| |
| `std_tier_variation` | `array(row(std_name row(id bigint, value varchar), std_sub_type row(id bigint, value varchar), std_options array(row(id bigint, value varchar)), images array(varchar), properties...` | property@All model standard variation details. std_name: std name of variation e.g. size, std_options: options of variation e.g. XL, images: images hash of variation, properties.name: not used, properties.image: not used, properties.color: not used, type: type of variation \| source: item_v5.extinfo.std_tier_variation \| |
| `scenario` | `tinyint` | property@scenario, COMMON = 0; LIVESKU = 1; \| source: item_v5.extinfo.scenario \| |
| `br_invoice_option` | `row(ncm varchar, same_state_cfop varchar, diff_state_cfop varchar, csosn varchar, origin varchar, cest varchar, measurement_unit varchar)` | property@invoice info, includes CSOCN, CEST,CFOP, among others. \| source: item_v5.extinfo.br_invoice_option \| |
| `ssp_id` | `bigint` | property@standard product id \| source: item_v5_tab.extinfo.ssp_id \| |
| `authorised_brand_id` | `bigint` | property@Authorised Resellers Brand ID \| source: item_v5_tab.extinfo.authorised_brand_id \| |
| `touch_timestamp` | `bigint` | property@touch_timestamp \| source: item_v5.touch_timestamp \| The touch time is initialized by ctime, modified by boost time. |
| `is_wholesale_available` | `tinyint` | tag@is_wholesale_available \|source: can_use_wholesale \|is wholesale available |
| `is_spu_vsku` | `tinyint` | tag@is_spu_vsku \|source: product label id = 1978603 \|the item is spu vsku item or used to be spu vsku item |
| `item_installation_service_info` | `varchar` | propertyitem_installation_service_info \| source: item_v5_tab.extinfo.item_installation_service_info \| |
| `dangerous_goods_categorization` | `bigint` | 1:DG A 2:DG B 3: DG C 4:DF D |
| `is_shopee_dangerous_goods` | `tinyint` | property@is shopee dangerous goods. Maintained by shopee. Correspond with column dangerous_goods_categorization |
| `tz_type` | `varchar` | Partition@timezone type for the data, refer https://sites.google.com/shopee.com/shopee-data-mart/general-data-mart-knowledge/useful-information/data-mart-marker-data-mart-running-schedule \|N/A \|local/ regional |
| `grass_region` | `varchar` | Partition@region \|N/A \|ID, TH, VN, SG, MY, TW, PH, BR, MX, CO, CL |
| `grass_date` | `date` | Partition@grass date \|N/A \|YYYY-mm-dd |
| `is_cb_shop` | `tinyint` | partition@Whether shop is cross border shop \|mp_user.dim_shop.is_cb_shop \| |

## 解析日志

- `mp_item.dim_item__reg_s0_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_item.dim_item__reg_s0_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
