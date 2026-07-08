<!-- ads-workspace-gdoc-sync: gdoc_id=1doiBgJeasPJoOIhMQyBPdu7MtRKomiF9GfmmPGaYZ8A gdoc_url=https://docs.google.com/document/d/1doiBgJeasPJoOIhMQyBPdu7MtRKomiF9GfmmPGaYZ8A/edit -->

# mp_mgmt.dws_order_item_rev_di__reg_s0_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_mgmt.dws_order_item_rev_di__reg_s0_live`
- canonical_table: `mp_mgmt.dws_order_item_rev_di__reg_s0_live`
- resolution: `describe:exact`
- source: `datasuite_describe`
- business_docs: `pc2_metrics`

## 使用边界

- 这张表只在命中的业务文档显式声明时作为外部表使用。
- 字段、类型和分区过滤以本文件记录的 DataMap/DESCRIBE 元数据为准。
- 不要把这张表自动加入广告数仓主候选表集合；它只补充业务链路排查。

## 分区和过滤

- inferred_partition_keys: `grass_date`, `grass_region`
- required_filters: `grass_date`, `grass_region`

## 字段列表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `order_id` | `bigint` | order id |
| `item_id` | `bigint` | item id |
| `model_id` | `bigint` | model id |
| `bundle_order_item_id` | `bigint` | Whether item is in a bundle order |
| `group_id` | `bigint` | A unique group ID to distinguish groups of items in Cart |
| `buyer_id` | `bigint` | unique userid of the buyer |
| `shop_id` | `bigint` | unique id of the shop |
| `mtsku_item_id` | `bigint` | mtsku item id |
| `mtsku_model_id` | `bigint` | mtsku model id |
| `is_official_shop` | `bigint` | whether the order is from official shop shop |
| `is_cb_shop` | `bigint` | Whether the order is from a cross border shop |
| `is_managed_shop` | `bigint` | Whether the order is from a managed shop |
| `is_supermarket_shop` | `tinyint` | whether this order is placed from a supermarket shop |
| `is_preferred_shop` | `tinyint` | whether the order is from preferred shop or star seller |
| `is_net_order` | `bigint` | Whether the order is a net order, this is calculated based on the order |
| `is_sbs_order` | `tinyint` | whether the order is an sbs order |
| `is_bi_excluded_order` | `bigint` | is bi excluded order |
| `is_bi_excluded_rev_prm` | `bigint` | is bi excluded revenue prm |
| `is_oms_exclude` | `bigint` | is oms exclude |
| `is_refund_amount_adjustable` | `bigint` | is refund amount adjustable |
| `is_returned_item` | `bigint` | is returned item |
| `is_local_sip_affiliated` | `bigint` | is local sip affiliated |
| `is_flash_sale` | `bigint` | If the item purchased is part of a flash sale deal |
| `is_shopee_paylater` | `tinyint` | is_shopee_paylater: 0->no, 1->yes |
| `is_shopee_pay` | `tinyint` | is_shopee_pay: 0->no, 1->yes |
| `is_web_checkout` | `tinyint` | whether the order was checked out from web portal (web include PC and Mobile Web) |
| `order_be_status_id` | `bigint` | order back end status id |
| `order_fraction` | `double` | Order fraction of the order item |
| `net_order_fraction` | `double` | Net order fraction of the order item |
| `estimate_net_order_fraction` | `double` | Estimate net order fraction of the order item |
| `item_promotion_type_id` | `bigint` | provide the item promotion type id of the item purchased |
| `bi_exclude_reason` | `varchar` | order exclude reason |
| `shop_type` | `varchar` | shop type |
| `sip_type` | `varchar` | CB-SIP、Local-SIP、Non-SIP |
| `g2n_seller_classification` | `varchar` | seller type indicator for g2n including Mall, Preferred, CB, Normal |
| `create_timestamp` | `bigint` | property@epoch time of the order when its created |
| `create_datetime` | `varchar` | Datetime of the order when its created(local time in string) |
| `pay_datetime` | `varchar` | pay_datetime is not null then is_paid,otherwise unpaid |
| `escrow_verified_timestamp` | `bigint` | property@escrow verified timestamp |
| `local_create_date` | `date` | local create date |
| `local_escrow_verified_date` | `date` | local escrow verified date |
| `regional_create_date` | `date` | regional create date |
| `regional_escrow_verified_date` | `date` | regional escrow verified date |
| `checkout_channel_id` | `bigint` | Indicates which platform is the checkout performed on 0: App 1: Mobile Web 2: PC Web 3: lite app (ID only) |
| `payment_be_channel_id` | `bigint` | pk@The id of the backend payment channel |
| `payment_channel_name` | `varchar` | The payment channel selected by the buyer for the checkout |
| `payment_l1_mapping` | `varchar` | Payment L1 Mapping: L1 Category used to group payment method |
| `payment_l2_mapping` | `varchar` | Payment L2 Mapping: L2 Category used to group payment method |
| `global_be_category_id` | `bigint` | Root global be category ID of the item |
| `kpi_categories` | `array(array(varchar))` | kpi category structure of the item |
| `fe_display_categories` | `array(array(varchar))` | front end display category structure of the item |
| `level1_global_be_category` | `varchar` | main global be category name of the item |
| `level1_global_be_category_id` | `bigint` | Level 1 global be category ID of the item |
| `level2_global_be_category` | `varchar` | sub global be category name of the item |
| `level2_global_be_category_id` | `bigint` | Level 2 global be category ID of the item |
| `gmv` | `decimal(25,10)` | The gross merchandise value of the order |
| `gmv_usd` | `decimal(25,10)` | The gross merchandise value of the order in USD |
| `nmv` | `decimal(25,10)` | The net merchandise value of the order |
| `nmv_usd` | `decimal(25,10)` | The net merchandise value of the order in USD |
| `insurance_premium_by_buyer_amt` | `decimal(25,10)` | amount of premium buyer pays for insurance for item |
| `insurance_premium_by_buyer_amt_usd` | `decimal(25,10)` | amount of premium buyer pays for insurance for item in usd |
| `comm_fee_perc` | `decimal(25,10)` | commission fee multiplier |
| `serv_fee_perc` | `decimal(25,10)` | service fee multiplier |
| `cc_fee_perc` | `decimal(25,10)` | cc fee multiplier |
| `commission_base_amt` | `decimal(25,10)` | commission base amount |
| `commission_base_amt_usd` | `decimal(25,10)` | commission base amount in USD |
| `commission_fee` | `decimal(25,10)` | commission fee |
| `commission_fee_usd` | `decimal(25,10)` | commission fee in USD |
| `net_commission_fee` | `decimal(25,10)` | net commission fee |
| `net_commission_fee_usd` | `decimal(25,10)` | net commission fee in USD |
| `service_fee` | `decimal(25,10)` | service fee |
| `service_fee_usd` | `decimal(25,10)` | service fee usd |
| `net_service_fee` | `decimal(25,10)` | net service fee |
| `net_service_fee_usd` | `decimal(25,10)` | net service fee usd |
| `buyer_service_fee` | `decimal(25,10)` | buyer service fee |
| `buyer_service_fee_usd` | `decimal(25,10)` | buyer service fee usd |
| `net_buyer_service_fee` | `decimal(25,10)` | net buyer service fee |
| `net_buyer_service_fee_usd` | `decimal(25,10)` | net buyer service fee usd |
| `seller_txn_fee` | `decimal(25,10)` | seller transaction fee |
| `seller_txn_fee_usd` | `decimal(25,10)` | seller transaction fee in usd |
| `net_seller_txn_fee` | `decimal(25,10)` | net seller transaction fee |
| `net_seller_txn_fee_usd` | `decimal(25,10)` | net seller transaction fee in usd |
| `buyer_txn_fee` | `decimal(25,10)` | buyer transaction fee |
| `buyer_txn_fee_usd` | `decimal(25,10)` | buyer transaction fee in usd |
| `net_buyer_txn_fee` | `decimal(25,10)` | net buyer transaction fee |
| `net_buyer_txn_fee_usd` | `decimal(25,10)` | net buyer transaction fee in usd |
| `estimate_nmv` | `decimal(25,10)` | estimate net gmv |
| `estimate_nmv_usd` | `decimal(25,10)` | estimate net gmv in usd |
| `estimate_net_commission_fee_ex_vat_amt` | `decimal(25,10)` | estimate net commission fee exclude vat amt |
| `estimate_net_commission_fee_ex_vat_amt_usd` | `decimal(25,10)` | estimate net commission fee exclude vat amt in usd |
| `estimate_net_service_fee_ex_vat_amt` | `decimal(25,10)` | estimate net service fee exclude vat_amt |
| `estimate_net_service_fee_ex_vat_amt_usd` | `decimal(25,10)` | estimate net service fee exclude vat_amt in usd |
| `estimate_net_buyer_txn_fee_ex_vat_amt` | `decimal(25,10)` | estimate net buyer txn fee exclude vat amt |
| `estimate_net_buyer_txn_fee_ex_vat_amt_usd` | `decimal(25,10)` | estimate net buyer txn fee exclude vat amt in usd |
| `estimate_net_seller_txn_fee_ex_vat_amt` | `decimal(25,10)` | estimate net seller txn fee exclude vat amt |
| `estimate_net_seller_txn_fee_ex_vat_amt_usd` | `decimal(25,10)` | estimate net seller txn fee exclude vat amt in usd |
| `estimate_net_buyer_service_fee_ex_vat_amt` | `decimal(25,10)` | estimate net buyer service fee exclude vat amt |
| `estimate_net_buyer_service_fee_ex_vat_amt_usd` | `decimal(25,10)` | estimate net buyer service fee exclude vat amt in usd |
| `gross_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross commission fee in usd |
| `net_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net commission fee in usd |
| `estimate_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net commission fee in usd |
| `gross_sip_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross sip commission fee in usd |
| `net_sip_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net sip commission fee in usd |
| `estimate_sip_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net sip commission fee in usd |
| `gross_sbs_outright_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross sbs outright commission fee in usd |
| `net_sbs_outright_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net sbs outright commission fee in usd |
| `estimate_sbs_outright_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net sbs outright commission fee usd 1d |
| `gross_sls_plus_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross sls plus commission fee in usd |
| `net_sls_plus_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net sls plus commission fee in usd |
| `estimate_sls_plus_commission_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net sls plus commission fee in usd |
| `gross_commission_fee_ex_usd_level2` | `decimal(25,10)` | Aggregated gross commission fees excluded from upper-level metrics; designed to accommodate future exclusions, includes SLS+ commission fee. |
| `net_commission_fee_ex_usd_level2` | `decimal(25,10)` | Aggregated net commission fees excluded from upper-level metrics; designed to accommodate future exclusions, includes SLS+ commission fee. |
| `estimate_commission_fee_ex_usd_level2` | `decimal(25,10)` | Aggregated estimate commission fees excluded from upper-level metrics; designed to accommodate future exclusions, includes SLS+ commission fee. |
| `gross_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross service fee in usd |
| `net_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net service fee in usd |
| `estimate_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net service fee in usd |
| `gross_sas_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross sas service fee in usd |
| `net_sas_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net sas service fee in usd |
| `estimate_sas_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net sas service fee in usd |
| `gross_massive_pck_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross massive pck service fee in usd |
| `net_massive_pck_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net_massive_pck_service_fee_usd_level2 |
| `estimate_massive_pck_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate_massive_pck_service_fee_usd_level2 |
| `gross_fss_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross fss service fee in usd |
| `net_fss_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net fss service fee in usd |
| `estimate_fss_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate net fss service fee in usd |
| `gross_ccb_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross CCB service fee in USD |
| `net_ccb_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net CCB service fee in USD |
| `estimate_ccb_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated CCB service fee in USD |
| `gross_fsc_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross FSC service fee in USD |
| `net_fsc_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net FSC service fee in USD |
| `estimate_fsc_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated FSC service fee in USD |
| `gross_adsellerate_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross AdSellerate service fee reclass in USD |
| `net_adsellerate_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net AdSellerate service fee reclass in USD |
| `estimate_adsellerate_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated AdSellerate service fee reclass in USD |
| `gross_payment_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross payment service fee reclass in USD |
| `net_payment_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net payment service fee reclass in USD |
| `estimate_payment_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated payment service fee reclass in USD |
| `gross_biaya_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross Biaya service fee reclass in USD |
| `net_biaya_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net Biaya service fee reclass in USD |
| `estimate_biaya_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated Biaya service fee reclass in USD |
| `gross_service_fee_ex_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross service fee excluding USD |
| `net_service_fee_ex_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net service fee excluding USD |
| `estimate_service_fee_ex_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated service fee excluding USD |
| `gross_sip_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross SIP service fee in USD |
| `net_sip_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net SIP service fee in USD |
| `estimate_sip_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated SIP service fee in USD |
| `gross_sbs_outright_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross SBS outright service fee in USD |
| `net_sbs_outright_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net SBS outright service fee in USD |
| `estimate_sbs_outright_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated SBS outright service fee in USD |
| `gross_buyer_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross buyer service fee reclass in USD |
| `net_buyer_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net buyer service fee reclass in USD |
| `estimate_buyer_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated buyer service fee reclass in USD |
| `gross_shopee_supermarket_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross Shopee Supermarket service fee in USD,only for SG,will not impact the final metrics,just list here so that we can look up data |
| `net_shopee_supermarket_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net Shopee Supermarket service fee in USD,only for SG,will not impact the final metrics,just list here so that we can look up data |
| `estimate_shopee_supermarket_service_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated Shopee Supermarket service fee in USD,only for SG,will not impact the final metrics,just list here so that we can look up data |
| `gross_fixed_order_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross fixed order fee in USD |
| `net_fixed_order_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net fixed order fee in USD |
| `estimate_fixed_order_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimate fixed order fee in USD |
| `gross_sip_fixed_order_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown, gross SIP fixed order fee in USD |
| `net_sip_fixed_order_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown, net SIP fixed order fee in USD |
| `estimate_sip_fixed_order_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown, estimate SIP fixed order fee in USD |
| `gross_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross seller transaction fee in USD |
| `net_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net seller transaction fee in USD |
| `estimate_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated seller transaction fee in USD |
| `gross_seller_spl_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross seller SPL transaction fee in USD |
| `net_seller_spl_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net seller SPL transaction fee in USD |
| `estimate_seller_spl_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated seller SPL transaction fee in USD |
| `gross_sip_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross SIP seller transaction fee in USD |
| `net_sip_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net SIP seller transaction fee in USD |
| `estimate_sip_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated seller SPL transaction fee in USD |
| `gross_sbs_outright_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross SBS outright seller transaction fee in USD |
| `net_sbs_outright_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net SBS outright seller transaction fee in USD |
| `estimate_sbs_outright_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated SBS outright seller transaction fee in USD |
| `gross_buyer_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,gross buyer transaction fee in USD |
| `net_buyer_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,net buyer transaction fee in USD |
| `estimate_buyer_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,estimated buyer transaction fee in USD |
| `gross_buyer_spl_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,Gross buyer special transaction fee in USD |
| `net_buyer_spl_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,Net buyer special transaction fee in USD |
| `estimate_buyer_spl_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,Estimated buyer special transaction fee in USD |
| `gross_invoice_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,Gross invoice seller transaction fee in USD |
| `net_invoice_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,Net invoice seller transaction fee in USD |
| `estimate_invoice_seller_txn_fee_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,Estimated invoice seller transaction fee in USD |
| `gross_fss_commission_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,partial fss commission fee is parked under gross service fee in USD |
| `net_fss_commission_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,partial fss commission fee is parked under net service fee in USD |
| `estimate_fss_commission_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,partial fss commission fee is parked under estimate service fee in USD |
| `gross_commission_fee_adjustment_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,for BR put the gross_amount_usd in adjustment field |
| `net_commission_fee_adjustment_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,for BR put the net_amount_usd in adjustment field |
| `estimate_commission_fee_adjustment_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,for BR put the estimate_amount_usd in adjustment field |
| `gross_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,some gross service fee need to be reclass include(cpf_service_fee,spp_service_fe,per_item_service_fee) from |
| `net_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,some net service fee need to be reclass |
| `estimate_service_fee_reclass_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,some estimate service fee need to be reclass |
| `gross_other_revenue_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,other revenue usd,included gross BR CB FX spread and TW invoice seller transaction fee |
| `net_other_revenue_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,other revenue usd,included net BR CB FX spread and TW invoice seller transaction fee |
| `estimate_other_revenue_usd_level2` | `decimal(25,10)` | PC1 level2 breakdown,other revenue usd,included estimate BR CB FX spread and TW invoice seller transaction fee |
| `gross_per_item_fbs_handling_fee_usd_level3` | `decimal(25,10)` | PC1 level3 breakdown,Gross FBS handling fee in USD |
| `net_per_item_fbs_handling_fee_usd_level3` | `decimal(25,10)` | PC1 level3 breakdown,Net FBS handling fee in USD |
| `estimate_per_item_fbs_handling_fee_usd_level3` | `decimal(25,10)` | PC1 level3 breakdown,Estimated per item FBS handling fee in USD |
| `gross_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross mandatory commission fee in USD |
| `net_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net mandatory commission fee in USD |
| `estimate_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated mandatory commission fee in USD |
| `gross_local_c2c_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross local C2C mandatory commission fee in USD |
| `net_local_c2c_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net local C2C mandatory commission fee in USD |
| `estimate_local_c2c_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated local C2C mandatory commission fee in USD |
| `gross_local_mall_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross local mall mandatory commission fee in USD |
| `net_local_mall_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net local mall mandatory commission fee in USD |
| `estimate_local_mall_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated local mall mandatory commission fee in USD |
| `gross_cb_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross CB mandatory commission fee in USD |
| `net_cb_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net CB mandatory commission fee in USD |
| `estimate_cb_mandatory_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated CB mandatory commission fee in USD |
| `gross_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross optional commission fee in USD |
| `net_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net optional commission fee in USD |
| `estimate_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated optional commission fee in USD |
| `gross_local_c2c_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross local C2C optional commission fee in USD |
| `net_local_c2c_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net local C2C optional commission fee in USD |
| `estimate_local_c2c_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated local C2C optional commission fee in USD |
| `gross_local_mall_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross local mall optional commission fee in USD |
| `net_local_mall_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net local mall optional commission fee in USD |
| `estimate_local_mall_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated local mall optional commission fee in USD |
| `gross_cb_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross CB optional commission fee in USD |
| `net_cb_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net CB optional commission fee in USD |
| `estimate_cb_optional_commission_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated CB optional commission fee in USD |
| `gross_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross seller handling fee in USD |
| `net_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net seller handling fee in USD |
| `estimate_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated seller handling fee in USD |
| `gross_local_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross local seller handling fee in USD |
| `net_local_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net local seller handling fee in USD |
| `estimate_local_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated local seller handling fee in USD |
| `gross_cb_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross CB seller handling fee in USD |
| `net_cb_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net CB seller handling fee in USD |
| `estimate_cb_seller_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated CB seller handling fee in USD |
| `gross_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross buyer handling fee in USD |
| `net_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net buyer handling fee in USD |
| `estimate_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated buyer handling fee in USD |
| `gross_local_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross local buyer handling fee in USD |
| `net_local_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net local buyer handling fee in USD |
| `estimate_local_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated local buyer handling fee in USD |
| `gross_cb_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Gross CB buyer handling fee in USD |
| `net_cb_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Net CB buyer handling fee in USD |
| `estimate_cb_buyer_handling_fee_usd_level1` | `decimal(25,10)` | PC1 level1 breakdown,Estimated CB buyer handling fee in USD |
| `gmv_g2n_ratio` | `double` | The GMV G2N ratio field is used for calculating topline metrics. |
| `order_g2n_ratio` | `double` | The Order G2N ratio field is used for calculating topline metrics. |
| `is_livestream_order` | `tinyint` | Whether the order comes from livestreaming |
| `is_video_order` | `tinyint` | Whether the order comes from video |
| `cancel_datetime` | `varchar` | The `cancel_datetime` column records the date and time when an order item was canceled. The field’s data unit is date and time, formatted as YYYY-MM-DD HH:MM:SS. |
| `is_est_rev` | `integer` | It is used to adjust whether the gross value should be subject to the G2N ratio. |
| `mandatory_fee_g2n_ratio` | `double` | the G2N ratio for Mandatory Commission Fee |
| `optional_fee_g2n_ratio` | `double` | the G2N ratio for Optional Commission Fee |
| `transaction_fee_g2n_ratio` | `double` | the G2N ratio for Transaction Commission Fee |
| `purchase_type` | `varchar` | purchase type of the item, enums: Outright, Consignment, Fulfilment (now only for Local SBS and Local SCS, CN SCS and Lovito will be null) |
| `business_type` | `varchar` | enums: Local SCS; CN SCS; Lovito; Local SBS. null means non-special shops |
| `fulfilment_source` | `varchar` | The `fulfilment_source` column indicates the origin from which the order item is fulfilled. Enum value: FULFILLED_BY_SHOPEE, FULFILLED_BY_CB_SELLER, FULFILLED_BY_LOCAL_SELLER |
| `is_virtual_sku` | `tinyint` | Whether the order item is a virtual sku |
| `comms_vat` | `double` | The commission VAT amount for the order item |
| `handling_vat` | `double` | The handling VAT amount for the order item |
| `gross_item_tax_amt` | `decimal(25,10)` | The gross item tax amount for the order item |
| `gross_item_tax_amt_usd` | `decimal(25,10)` | The gross item tax amount for the order item in USD |
| `net_item_tax_amt` | `decimal(25,10)` | The net item tax amount for the order item |
| `net_item_tax_amt_usd` | `decimal(25,10)` | The net item tax amount for the order item in USD |
| `item_price_before_discount_pp` | `decimal(25,10)` | the price that the item origianlly listed, doesn’t include any promotion and include tax, in local currency |
| `item_price_before_discount_pp_usd` | `decimal(25,10)` | the price that the item origianlly listed, doesn’t include any promotion and include tax, in USD |
| `item_amount` | `decimal(25,10)` | The `item_amount` column represents the total number of items included in the order. This field is essential for inventory management and order processing, as it helps in determining the quantity of products involved in a transaction. The field’s data unit is a count of items. |
| `level3_global_be_category_id` | `bigint` | The unique identifier for the level 3 global business entity category of the order item, used for categorizing products in a hierarchical structure for better inventory management and reporting. |
| `level4_global_be_category_id` | `bigint` | The unique identifier for the level 4 global business entity category of the order item, used for categorizing products in a hierarchical structure for better inventory management and reporting. |
| `ams_om_marketing_rev_usd_ex_vat_usd` | `decimal(25,10)` | OMS marketing revenue charged to sellers under AMS, representing the per-sale OM fee (in USD) for successful and fraud-cleared orders. |
| `warehouse_code` | `varchar` | This column represents the code of the warehouse where the order item is stored or processed. It is used to identify the specific warehouse location associated with the order item, facilitating inventory management and logistics operations. Specify the foreign key relationship with the dimension table that contains warehouse details, ensuring accurate map... |
| `updated_warehouse_code` | `varchar` | Identifies the updated warehouse code associated with the order item, indicating the specific warehouse responsible for fulfilling the order. Links to the dimension table containing warehouse details for inventory and logistics management. |
| `order_sn` | `varchar` | Represents the unique order serial number associated with the order item, crucial for identifying and linking order items to their respective orders. This column is a foreign key that references the dimension table containing detailed information about orders. |
| `split_factor` | `double` | Represents the factor used to split the order into order item for allocation or distribution purposes. This field’s data unit is a decimal, between 0 to 1 |
| `item_price_pp` | `decimal(25,10)` | the price that deduct item promotion from item_price_before_discount_pp, and include tax, in local currency |
| `item_price_pp_usd` | `decimal(25,10)` | the price that deduct item promotion from item_price_before_discount_pp, and include tax, in USD |
| `settlement_price` | `decimal(25,10)` | The final price at which the order item is settled after accounting for discounts, promotions, and applicable fees The field’s data unit is in local currency |
| `return_refund_paid_datetime` | `varchar` | The `return_refund_paid_datetime` column captures the date and time when a refund for a returned item was paid to the buyer. This field is crucial for tracking the refund process and ensuring accurate financial reconciliation. The data unit for this column is date and time, formatted as YYYY-MM-DD HH:MM:SS. |
| `return_accepted_datetime` | `varchar` | The `return_accepted_datetime` column records the date and time when a return request for an order item was accepted. This field is essential for monitoring the return process and managing customer service interactions. The data unit for this column is date and time, formatted as YYYY-MM-DD HH:MM:SS. |
| `payment_method_id` | `bigint` | A unique identifier for the payment method used to complete the transaction for the order item, essential for processing payments and tracking transaction types. This column serves as a foreign key referencing the dimension table(mp_order.dim_payment_method__reg_s0_live) that contains details of payment methods |
| `payment_method` | `varchar` | name of payment method, this is roughly detail of backend payment channel. Get from mp_order.dim_payment_method__reg_s0_live |
| `estimate_shipping_rebate_by_seller_amt` | `decimal(25,10)` | The estimated amount of shipping rebate provided by the seller to the buyer, which reduces the overall shipping cost for the buyer. The data unit is in the local currency. |
| `grass_region` | `varchar` | partition key |
| `grass_date` | `date` | partition key, yyyy-MM-dd |

## 解析日志

- `mp_mgmt.dws_order_item_rev_di__reg_s0_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_mgmt.dws_order_item_rev_di__reg_s0_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
