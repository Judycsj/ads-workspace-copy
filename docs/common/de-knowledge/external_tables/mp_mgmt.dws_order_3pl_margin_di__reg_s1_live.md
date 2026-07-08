<!-- ads-workspace-gdoc-sync: gdoc_id=1RVy9ul7QvE7HNVSOQtMvtb9vl4XuVUyDz0a9Z-_kMxw gdoc_url=https://docs.google.com/document/d/1RVy9ul7QvE7HNVSOQtMvtb9vl4XuVUyDz0a9Z-_kMxw/edit -->

# mp_mgmt.dws_order_3pl_margin_di__reg_s1_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live`
- canonical_table: `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live`
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
| `order_id` | `bigint` | Primary Key, unique ID of order |
| `order_sn` | `varchar` | Order Serial Number |
| `create_datetime` | `date` | Create date time for this order in local timezone |
| `order_termination_date` | `date` | Order completion date time |
| `sls_order_id` | `bigint` | Order_id from SLS Mart |
| `sls_pickup_date` | `date` | The earliest timestamp of the order that was picked |
| `sls_delivered_date` | `date` | The earliest timestamp of the order that was delivered |
| `is_net_order` | `tinyint` | Whether the order is a net order |
| `is_cb_shop` | `tinyint` | Whether the shop is cross border |
| `is_fss_order` | `tinyint` | whether the order is a fss order ,only applicable to BR |
| `is_spx` | `tinyint` | whether the order is delivered by SPX |
| `is_bi_excluded` | `tinyint` | is excluded by bi team |
| `bi_exclude_reason` | `varchar` | bi exclude reason |
| `order_type` | `varchar` | Order type local/cb lm locally fulfilled/cb |
| `shop_type` | `varchar` | CB、MP、Mall |
| `net_to_gross_logst_g2n_ratio` | `double` | used for computing estimate value |
| `local_create_date` | `date` | This field is for calculating local tz_type. |
| `regional_create_date` | `date` | This field is for calculating regional tz_type. |
| `fsv_promotion_id` | `bigint` | Free Shipping Voucher promotion id |
| `promotion_id` | `bigint` | promotion_id is from mp_voucher.dim_voucher__reg_s0_live |
| `reward_type` | `varchar` | Whether is free_shipping_voucher |
| `is_fsv_all_payment_method` | `tinyint` | Whether the free shipping voucher applied in the order allows all payment methods 0: Voucher has payment restrictions1: Voucher allows all payment methods |
| `is_fsv_allow_shopee_pay` | `tinyint` | Whether the free shipping voucher applied in the order allows ShopeePay payment method 0: Voucher does not allow ShopeePay payment method 1: Voucher allows ShopeePay payment method, may allow other payment methods too |
| `is_fsv_allow_shopee_pay_only` | `tinyint` | Whether the free shipping voucher applied in the order allows ShopeePay payment method only 0: Voucher is not restricted to ShopeePay only i.e. the voucher allows other payment methods and may or may not allow ShopeePay 1: Voucher is restricted to ShopeePay only, no other payment methods are allowed |
| `is_fsv_allow_shopee_paylater` | `tinyint` | Whether the free shipping voucher applied in the order allows ShopeePayLater payment method 0: Voucher does not allow ShopeePayLater payment method 1: Voucher allows ShopeePayLater payment method, may allow other payment methods too |
| `is_fsv_allow_shopee_paylater_only` | `tinyint` | Whether the free shipping voucher applied in the order allows ShopeePayLater payment method only 0: Voucher is not restricted to ShopeePayLater only i.e. the voucher allows other payment methods and may or may not allow ShopeePayLater 1: Voucher is restricted to ShopeePayLater only, no other payment methods are allowed |
| `is_fsv_allow_bank` | `tinyint` | Whether the free shipping voucher applied in the order allows SeaBank payment method 0: Voucher does not allow SeaBank payment method 1: Voucher allows SeaBank payment method, may allow other payment methods too |
| `is_fsv_allow_bank_only` | `tinyint` | Whether the free shipping voucher applied in the order allows SeaBank payment method only 0: Voucher is not restricted to SeaBank only i.e. the voucher allows other payment methods and may or may not allow SeaBank 1: Voucher is restricted to SeaBank only, no other payment methods are allowed |
| `is_fsv_allow_seamoney_only` | `tinyint` | Whether the free shipping voucher applied in the order allows ShopeePay / ShopeePayLater / SeaBank payment methods only 0: Voucher is not restricted to ShopeePay / ShopeePayLater / SeaBank only i.e. the voucher allows other payment methods 1: Voucher is restricted to ShopeePay / ShopeePayLater / SeaBank only, no other payment methods are allowed; This inc... |
| `is_shopee_pay` | `tinyint` | Whether the order is paid using ShopeePay 0: Order is paid using payment methods other than ShopeePay 1: Order is paid using ShopeePay |
| `is_shopee_paylater` | `tinyint` | Whether the order is paid using ShopeePayLater 0: Order is paid using payment methods other than ShopeePayLater 1: Order is paid using ShopeePayLater |
| `shipping_method_id` | `bigint` | id of shipping_method |
| `shipping_channel_id` | `bigint` | This field identifies the specific shipping channel used for an order |
| `shipping_carrier` | `varchar` | shipping_carrier |
| `actual_shipping_carrier` | `varchar` | actual_shipping_carrier |
| `fulfilment_shipping_method_id` | `bigint` | property@fulfilment_shipping_method_id |
| `fulfilment_channel_id` | `bigint` | property@id of fulfilment_channel |
| `fulfilment_shipping_carrier` | `varchar` | property@fulfilment channel name |
| `payment_method` | `varchar` | The type of payment method |
| `seller_shipping_address_state` | `varchar` | seller shipping address state |
| `is_seller_cover_shipping_fee` | `tinyint` | is seller cover this shipping fee |
| `is_escrow_includes_asf` | `tinyint` | This indicates if the order escrow amount (amount buyer pays for an order held by shopee) includes the actual shipping fee(ASF).If it does not include ASF, seller will deal with 3PL. If it does include ASF, shopee will deal with 3PL. more detail: https://confluence.shopee.io/x/gREtGg |
| `estimate_shipping_fee` | `decimal(25,10)` | ESF is the estimated total shipping fee in local currency that a 3PL will charge to a seller for an order |
| `estimate_shipping_fee_usd` | `decimal(25,10)` | ESF is the estimated total shipping fee in USD that a 3PL will charge to a seller for an order |
| `buyer_paid_shipping_fee` | `decimal(25,10)` | BPSF is the shipping cost paid in local currency by the buyer when a buyer places an order |
| `buyer_paid_shipping_fee_usd` | `decimal(25,10)` | BPSF is the shipping cost paid in USD by the buyer when a buyer places an order |
| `estimate_shipping_rebate_by_shopee_amt` | `decimal(25,10)` | This is the estimated amount that shopee will help seller offset shipping costs of an order(local currency) |
| `estimate_shipping_rebate_by_shopee_amt_usd` | `decimal(25,10)` | This is the estimated amount that shopee will help seller offset shipping costs of an order(USD) |
| `estimate_shipping_rebate_by_seller_amt` | `decimal(25,10)` | The estimate rebate amount with respect to shipping fee that seller needs to cover for (or earn from) the shipping costs at the point of order checkout.(local currency) |
| `estimate_shipping_rebate_by_seller_amt_usd` | `decimal(25,10)` | The estimate rebate amount with respect to shipping fee that seller needs to cover for (or earn from) the shipping costs at the point of order checkout.(USD) |
| `estimated_seamoney_prm_ratio` | `double` | This field represents the estimate promotion ratio provided by SeaMoney during a transaction |
| `actual_shipping_fee_raw` | `decimal(25,10)` | Raw data:ASF is the actual total shipping fee that a 3PL will charge to a seller for an order in local currency |
| `actual_shipping_fee_raw_usd` | `decimal(25,10)` | Raw data:ASF is the actual total shipping fee that a 3PL will charge to a seller for an order in USD |
| `actual_shipping_fee` | `decimal(25,10)` | Recalculated:ASF is the actual total shipping fee that a 3PL will charge to a seller for an order in local currency |
| `actual_shipping_fee_usd` | `decimal(25,10)` | Recalculated:ASF is the actual total shipping fee that a 3PL will charge to a seller for an order in USD |
| `actual_buyer_paid_shipping_fee` | `decimal(25,10)` | BPSF is the shipping cost paid by the buyer when a buyer places an order in local currency |
| `actual_buyer_paid_shipping_fee_usd` | `decimal(25,10)` | BPSF is the shipping cost paid by the buyer when a buyer places an order in USD |
| `actual_shipping_rebate_by_shopee_amt` | `decimal(25,10)` | This is the actual amount that shopee will help seller offset shipping costs of an order in local currency |
| `actual_shipping_rebate_by_shopee_amt_usd` | `decimal(25,10)` | This is the actual amount that shopee will help seller offset shipping costs of an order in USD |
| `actual_shipping_rebate_by_seller_amt` | `decimal(25,10)` | The actual rebate amount with respect to shipping fee that seller needs to cover for (or earn from) the shipping costs at the point of order checkout in local currency |
| `actual_shipping_rebate_by_seller_amt_usd` | `decimal(25,10)` | The actual rebate amount with respect to shipping fee that seller needs to cover for (or earn from) the shipping costs at the point of order checkout in USD |
| `shipping_discount_by_3pl_amt` | `decimal(25,10)` | The shipping discount amount is provided by 3pl in local currency |
| `shipping_discount_by_3pl_amt_usd` | `decimal(25,10)` | The shipping discount amount is provided by 3pl in USD |
| `actual_seamoney_prm_ratio` | `double` | This field represents the actual promotion ratio provided by SeaMoney during a transaction |
| `finbill_3pl_esf_less_cod_insurance_amt` | `decimal(25,10)` | finbill_3pl_esf_less_cod_insurance |
| `finbill_3pl_esf_less_cod_insurance_amt_usd` | `decimal(25,10)` | finbill_3pl_esf_less_cod_insurance_usd |
| `actual_3pl_asf_finbill_recon_amt` | `decimal(25,10)` | actual_3pl_asf_finbill_recon |
| `actual_3pl_asf_finbill_recon_amt_usd` | `decimal(25,10)` | actual_3pl_asf_finbill_recon_usd |
| `cashback_rate` | `decimal(25,10)` | Cashback from 3PL is based on invoice from 3PL to Shopee. Doesn’t takes place during checkout, order fulfilment, or escrow process. |
| `seller_cashback_usd` | `decimal(25,10)` | seller_cashback_usd |
| `finbill_3pl_asf_total_fee` | `decimal(25,10)` | finbill_3pl_asf_total_fee |
| `finbill_3pl_asf_shopee_cost_less_cod_insurance` | `decimal(25,10)` | finbill_3pl_asf_shopee_cost_less_cod_insurance |
| `recon_shopee_cost_less_cod_insurance` | `decimal(25,10)` | recon_shopee_cost_less_cod_insurance |
| `recon_provider_cost_less_cod_insurance` | `decimal(25,10)` | recon_provider_cost_less_cod_insurance |
| `recon_agree_amount_less_cod_insurance` | `decimal(25,10)` | recon_agree_amount_less_cod_insurance |
| `finbill_3pl_esf_total_fee` | `decimal(25,10)` | finbill_3pl_esf_total_fee |
| `tpl_margin_usd_pickup` | `decimal(25,10)` | tpl_margin_usd_pickup |
| `tpl_margin_usd_actual` | `decimal(25,10)` | tpl_margin_usd_actual |
| `est_tpl_margin_usd_pickup` | `decimal(25,10)` | est_tpl_margin_usd_pickup |
| `est_tpl_margin_usd_actual` | `decimal(25,10)` | est_tpl_margin_usd_actual |
| `final_recon_pickup_fee` | `decimal(25,10)` | final_recon_pickup_fee |
| `final_recon_pickup_fee_usd` | `decimal(25,10)` | final_recon_pickup_fee_usd |
| `cpo_gross` | `decimal(25,10)` | cpo_gross |
| `offline_adjustment_amount` | `decimal(25,10)` | Amount for manual offline adjustment of excess shipping fees for returned or failed deliveries in Vietnam |
| `offline_adjustment_amount_usd` | `decimal(25,10)` | Same as above (USD) |
| `buyer_paid_shipping_fee_raw` | `decimal(25,10)` | BPSF in local currency (excluding adjustment) |
| `buyer_paid_shipping_fee_raw_usd` | `decimal(25,10)` | BPSF in USD (excluding adjustment) |
| `estimate_shipping_fee_raw` | `decimal(25,10)` | Estimated 3PL fee in local currency (excluding adjustment) |
| `estimate_shipping_fee_raw_usd` | `decimal(25,10)` | Estimated 3PL fee in USD (excluding adjustment) |
| `actual_buyer_paid_shipping_fee_raw` | `decimal(25,10)` | Actual BPSF in local currency (excluding adjustment) |
| `actual_buyer_paid_shipping_fee_raw_usd` | `decimal(25,10)` | Actual BPSF in USD (excluding adjustment) |
| `logst_g2n_ratio` | `double` | used for computing estimate value |
| `is_paid_order` | `tinyint` | is_paid_order |
| `is_delivered` | `tinyint` | is_delivered |
| `is_be_available` | `tinyint` | is_be_available |
| `local_sls_pickup_date` | `date` | The earliest timestamp of the order that was picked(Local date_time) |
| `final_recon_cashback_fee` | `decimal(25,10)` | Cashback fee amount finalized after reconciliation |
| `final_recon_cashback_fee_usd` | `decimal(25,10)` | Cashback fee amount finalized after reconciliation(USD) |
| `shopee_food_subsidies_usd` | `decimal(25,10)` | Shopee food subsidies for VN |
| `rts_shipping_fee_by_seller` | `decimal(25,10)` | RTS fee that is passed on to seller |
| `rts_shipping_fee_by_seller_usd` | `decimal(25,10)` | RTS fee that is passed on to seller, in USD |
| `finbill_3pl_rts_fee` | `decimal(25,10)` | System calculated RTS fee when the forward delivery fails to reach buyer |
| `finbill_3pl_rts_fee_usd` | `decimal(25,10)` | System calculated RTS fee when the forward delivery fails to reach buyer, in USD |
| `recon_provider_cost_rts_fee` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the forward delivery fails to reach buyer. This is the invoice amount uploaded by user |
| `recon_provider_cost_rts_fee_usd` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the forward delivery fails to reach buyer. This is the invoice amount uploaded by user, in USD |
| `recon_agreed_rts_fee` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the forward delivery fails to reach buyer. This is the agreed upon amount between Shopee and 3PL |
| `recon_agreed_rts_fee_usd` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the forward delivery fails to reach buyer. This is the agreed upon amount between Shopee and 3PL, in USD |
| `final_recon_rts_fee` | `decimal(25,10)` | Final RTS fee charged by 3PL to Shopee when the forward delivery fails to reach buyer |
| `final_recon_rts_fee_usd` | `decimal(25,10)` | Final RTS fee charged by 3PL to Shopee when the forward delivery fails to reach buyer, in USD |
| `finbill_3pl_reverse_rts_fee` | `decimal(25,10)` | System calculated RTS fee when the reverse delivery fails to reach seller |
| `finbill_3pl_reverse_rts_fee_usd` | `decimal(25,10)` | System calculated RTS fee when the reverse delivery fails to reach seller, in usd |
| `recon_reverse_provider_cost_rts_fee` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the reverse delivery fails to reach seller. This is the invoice amount uploaded by user |
| `recon_reverse_provider_cost_rts_fee_usd` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the reverse delivery fails to reach seller. This is the invoice amount uploaded by user, in usd |
| `recon_reverse_agreed_rts_fee` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the reverse delivery fails to reach seller. This is the agreed upon amount between Shopee and 3PL |
| `recon_reverse_agreed_rts_fee_usd` | `decimal(25,10)` | RTS fee charged by 3PL to Shopee when the reverse delivery fails to reach seller. This is the agreed upon amount between Shopee and 3PL, in usd |
| `final_recon_reverse_rts_fee` | `decimal(25,10)` | Final RTS fee charged by 3PL to Shopee when the reverse delivery fails to reach seller |
| `final_recon_reverse_rts_fee_usd` | `decimal(25,10)` | Final RTS fee charged by 3PL to Shopee when the reverse delivery fails to reach seller, in usd |
| `total_recon_rts_fee` | `decimal(25,10)` | Total RTS fee charged by 3PL to Shopee for failed delivery |
| `total_recon_rts_fee_usd` | `decimal(25,10)` | Total RTS fee charged by 3PL to Shopee for failed delivery, in usd |
| `cashback_rts_fee` | `decimal(25,10)` | Cashback given by 3PL to Shopee for RTS delivery |
| `cashback_rts_fee_usd` | `decimal(25,10)` | Cashback given by 3PL to Shopee for RTS delivery, in usd |
| `net_rts_fee` | `decimal(25,10)` | Net RTS fee borne by Shopee after cashback and seller cost passing |
| `net_rts_fee_usd` | `decimal(25,10)` | Net RTS fee borne by Shopee after cashback and seller cost passing, in usd |
| `is_3pl_margin` | `integer` | 1: this order is in 3pl margin order scope. 0: this order is not in 3pl margin order scope |
| `is_rts` | `integer` | 1: this order is in rts order scope. 0: this order is not in rts order scope |
| `shop_id` | `bigint` | A unique identifier for the shop associated with the order item |
| `buyer_id` | `bigint` | This column represents a unique identifier for the buyer who placed the order item. |
| `is_spx_instant` | `tinyint` | Whether the order is a shopee food order |
| `cancel_date` | `date` | cancel time for a order |
| `parcel_create_date` | `date` | parcel ticket create time for a order |
| `gross_fe_shipping_fee_usd` | `decimal(25,10)` | gross_fe_shipping_fee_usd |
| `net_fe_shipping_fee_usd` | `decimal(25,10)` | net_fe_shipping_fee_usd |
| `estimate_net_fe_shipping_fee_usd` | `decimal(25,10)` | estimate_net_fe_shipping_fee_usd(valid amount logic) |
| `gross_3pl_billables_usd` | `decimal(25,10)` | gross_3pl_billables_usd (original value, without cpo) |
| `net_3pl_billables_usd` | `decimal(25,10)` | net_fe_shipping_fee_usd |
| `estimate_net_3pl_billables_usd` | `decimal(25,10)` | estimate_net_3pl_billables_usd (valid amount logic) |
| `local_3pl_asf_value_pickup_amt` | `decimal(25,10)` | local_3pl_asf_value_pickup_amt |
| `local_3pl_asf_value_pickup_amt_usd` | `decimal(25,10)` | local_3pl_asf_value_pickup_amt_usd |
| `local_3pl_asf_value_delivered_amt` | `decimal(25,10)` | local_3pl_asf_value_delivered_amt |
| `local_3pl_asf_value_delivered_amt_usd` | `decimal(25,10)` | local_3pl_asf_value_delivered_amt_usd |
| `gross_cashback_usd` | `decimal(25,10)` | gross_cashback_usd |
| `net_cashback_usd` | `decimal(25,10)` | net_cashback_usd |
| `estimate_net_cashback_usd` | `decimal(25,10)` | estimate_net_cashback_usd |
| `estimate_net_penalty_fee_usd` | `decimal(25,10)` | estimate_net_penalty_fee_usd |
| `gross_3pl_margin_usd` | `decimal(25,10)` | gross_3pl_margin_usd |
| `net_3pl_margin_usd` | `decimal(25,10)` | net_3pl_margin_usd |
| `estimate_net_3pl_margin_usd` | `decimal(25,10)` | estimate_net_3pl_margin_usd (valid amount logic) |
| `estimate_net_3pl_billables_g2n_value_usd` | `decimal(25,10)` | estimate_net_3pl_billables_g2n_value_usd |
| `gross_billable_cashback_usd` | `decimal(25,10)` | gross_billable_cashback_usd |
| `net_billable_cashback_usd` | `decimal(25,10)` | net_billable_cashback_usd |
| `estimate_net_billable_cashback_usd` | `decimal(25,10)` | estimate_net_billable_cashback_usd |
| `cashback_allocation_rate` | `decimal(35,10)` | cashback order level allocation rate |
| `recon_cashback_usd_order` | `decimal(35,10)` | order level recon cashback usd |
| `marketing_sponsor_from_3pl_usd_order` | `decimal(35,10)` | order level manual cashback usd |
| `grass_region` | `varchar` | partition key |
| `grass_date` | `date` | partition key, yyyy-MM-dd |

## 解析日志

- `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
