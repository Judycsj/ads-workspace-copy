<!-- ads-workspace-gdoc-sync: gdoc_id=12eD622H_YuzG-LrvfXJq3QErwFANRIq_xu_cWZCpfok gdoc_url=https://docs.google.com/document/d/12eD622H_YuzG-LrvfXJq3QErwFANRIq_xu_cWZCpfok/edit -->

# mp_mgmt.dws_order_item_rebate_di__reg_s0_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_mgmt.dws_order_item_rebate_di__reg_s0_live`
- canonical_table: `mp_mgmt.dws_order_item_rebate_di__reg_s0_live`
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
| `is_official_shop` | `bigint` | whether the order is from official shop shop |
| `is_cb_shop` | `bigint` | Whether the order is from a cross border shop |
| `is_managed_shop` | `bigint` | Whether the order is from a managed shop |
| `is_supermarket_shop` | `tinyint` | whether this order is placed from a supermarket shop |
| `is_preferred_shop` | `tinyint` | whether the order is from preferred shop or star seller |
| `is_net_order` | `tinyint` | Whether the order is a net order, this is calculated based on the order |
| `is_sbs_order` | `tinyint` | whether the order is an sbs order |
| `is_net_order_new` | `tinyint` | whether the order is an net order |
| `is_net_order_new_coin` | `tinyint` | whether the order is an net order for coin |
| `is_bi_excluded_order` | `tinyint` | is bi excluded order |
| `is_bi_excluded_rev_prm` | `tinyint` | is bi excluded revenue prm |
| `is_flash_sale` | `tinyint` | If the item purchased is part of a flash sale deal |
| `is_shopee_paylater` | `tinyint` | is_shopee_paylater: 0->no, 1->yes |
| `is_shopee_pay` | `tinyint` | is_shopee_pay: 0->no, 1->yes |
| `is_pick_up` | `tinyint` | use is_pickup to calculate shipping rebate |
| `is_bank` | `tinyint` | whether the payment of order is bank or not |
| `is_web_checkout` | `tinyint` | Whether the order is checked out from the web |
| `create_datetime` | `varchar` | property@local datetime of the order when its created, local time in string |
| `order_fe_status` | `varchar` | property@order status in front end |
| `order_be_status` | `varchar` | property@order status in back end |
| `is_returned_item` | `tinyint` | tag@is a successfully returned item |
| `item_promotion_source` | `varchar` | property@source of item level promotion |
| `has_lowest_price_guarantee` | `tinyint` | property@whether item has lowest price guarantee or not |
| `is_sv_all_payment_method` | `tinyint` | is sv all payment method |
| `is_sv_allow_shopee_pay` | `tinyint` | is_sv_allow_shopee_pay |
| `is_sv_allow_shopee_pay_only` | `tinyint` | is_sv_allow_shopee_pay_only |
| `is_sv_allow_shopee_paylater` | `tinyint` | is_sv_allow_shopee_paylater |
| `is_sv_allow_shopee_paylater_only` | `tinyint` | is_sv_allow_shopee_paylater_only |
| `is_sv_allow_bank` | `tinyint` | is_sv_allow_bank |
| `is_sv_allow_bank_only` | `tinyint` | is_sv_allow_bank_only |
| `is_sv_allow_seamoney_only` | `tinyint` | is_sv_allow_seamoney_only |
| `is_pv_all_payment_method` | `tinyint` | is_pv_all_payment_method |
| `is_pv_allow_shopee_pay` | `tinyint` | is_pv_allow_shopee_pay |
| `is_pv_allow_shopee_pay_only` | `tinyint` | is_pv_allow_shopee_pay_only |
| `is_pv_allow_shopee_paylater` | `tinyint` | is_pv_allow_shopee_paylater |
| `is_pv_allow_shopee_paylater_only` | `tinyint` | is_pv_allow_shopee_paylater_only |
| `is_pv_allow_bank` | `tinyint` | is_pv_allow_bank |
| `is_pv_allow_bank_only` | `tinyint` | is_pv_allow_bank_only |
| `is_pv_allow_seamoney_only` | `tinyint` | is_pv_allow_seamoney_only |
| `is_fsv_all_payment_method` | `tinyint` | is_fsv_all_payment_method |
| `is_fsv_allow_shopee_pay` | `tinyint` | is_fsv_allow_shopee_pay |
| `is_fsv_allow_shopee_pay_only` | `tinyint` | is_fsv_allow_shopee_pay_only |
| `is_fsv_allow_shopee_paylater` | `tinyint` | is_fsv_allow_shopee_paylater |
| `is_fsv_allow_shopee_paylater_only` | `tinyint` | is_fsv_allow_shopee_paylater_only |
| `is_fsv_allow_bank` | `tinyint` | is_fsv_allow_shopee_paylater_only |
| `is_fsv_allow_bank_only` | `tinyint` | is_fsv_allow_bank_only |
| `is_fsv_allow_seamoney_only` | `tinyint` | is_fsv_allow_seamoney_only |
| `is_paid` | `tinyint` | pay_datetime is not null then is_paid,otherwise unpaid |
| `is_local_sip_affiliated` | `tinyint` | is local sip affiliated |
| `is_fss_order` | `integer` | is fss order |
| `is_cod_order` | `integer` | 0: Not a cash-on-delivery order, 1: Order is a cash-on-delivery order |
| `is_bcl_voucher` | `integer` | 0: Not a BCL voucher order, 1: Order is a BCL voucher order, BCL(Buyer Cash Loan) |
| `is_trade_in_bonus` | `integer` | 1: order has trade in bonus, 0: order has no trade in bonus |
| `shop_type` | `varchar` | CB、MP、Mall |
| `sip_type` | `varchar` | the type of the sip_type:CB-SIP、Local-SIP、Non-SIP |
| `bi_exclude_reason` | `varchar` | Reasons for excluding orders |
| `checkout_channel_id` | `bigint` | The channel id of order is checked out |
| `payment_channel` | `varchar` | The payment channel for orders |
| `payment_be_channel_id` | `bigint` | property@payment backend channel id |
| `payment_l1_mapping` | `varchar` | property@L1 Category used to group payment method |
| `payment_l2_mapping` | `varchar` | property@L2 Category used to group payment method |
| `item_promotion_type_id` | `bigint` | provide the item promotion type id of the item purchased |
| `pv_promotion_id` | `bigint` | Promotion ID of platform voucher used for the order |
| `sv_promotion_id` | `bigint` | Promotion ID of seller voucher used for the order |
| `fsv_promotion_id` | `bigint` | Promotion ID of free shipping voucher used for the order |
| `item_promotion_id` | `bigint` | Promotion ID of the item for price related promotion |
| `card_promotion_id` | `bigint` | Promotion ID for payment channel promotion |
| `logistics_channel_promotion_rule_id` | `bigint` | logistics_channel_promotion_rule_id |
| `pv_rebate_program_type` | `varchar` | program type of rebate is shopee voucher |
| `sv_rebate_program_type` | `varchar` | program type of rebate is seller voucher |
| `fsv_rebate_program_type` | `varchar` | program type of rebate is free shipping voucher |
| `item_rebate_program_type` | `varchar` | program type of rebate is item |
| `card_rebate_program_type` | `varchar` | program type of rebate is card |
| `pv_rebate_payment_type` | `varchar` | Payment type of rebate is production voucher |
| `sv_rebate_payment_type` | `varchar` | Payment type of rebate is Seller voucher |
| `fsv_rebate_payment_type` | `varchar` | Payment type of rebate is Free shipping voucher |
| `global_be_category_id` | `bigint` | Root global be category ID of the item |
| `level1_global_be_category_id` | `bigint` | CLevel 1 global be category ID of the item |
| `level1_global_be_category` | `varchar` | property@global be category name in level 1 |
| `level2_global_be_category_id` | `bigint` | CLevel 2 global be category ID of the item |
| `level2_global_be_category` | `varchar` | property@global be category name in level 2 |
| `fe_display_categories` | `array(array(varchar))` | front end display category structure of the item |
| `kpi_categories` | `array(array(varchar))` | kpi category sturcture of the item |
| `escrow_verified_timestamp` | `bigint` | property@escrow verified unix timestamp |
| `local_create_date` | `date` | local create date |
| `local_escrow_verified_date` | `date` | local escrow verified date |
| `regional_create_date` | `date` | regional create date |
| `regional_escrow_verified_date` | `date` | regional escrow verified date |
| `order_fraction` | `double` | Order fraction of the order item |
| `cancel_datetime` | `varchar` | Order cancel datetime |
| `return_refund_paid_datetime` | `varchar` | Order return refund paid datetime |
| `return_accepted_datetime` | `varchar` | Order return accepted datetime |
| `shipping_channel_id` | `bigint` | The shipping channel id of the order |
| `fulfilment_channel_id` | `bigint` | The fulfilment channel id of the order |
| `actual_buyer_paid_shipping_fee` | `decimal(35,10)` | shipping fee paid by buyer |
| `actual_buyer_paid_shipping_fee_usd` | `decimal(35,10)` | shipping fee paid by buyer in usd |
| `buyer_paid_shipping_fee` | `decimal(35,10)` | shipping fee paid by buyer, if the order is not yet shipped, this field will be estimated shipping fee |
| `buyer_paid_shipping_fee_usd` | `decimal(35,10)` | shipping fee paid by buyer in usd, if the order is not yet shipped, this field will be estimated shipping fee in usd |
| `estimate_shipping_rebate_by_shopee_amt` | `decimal(35,10)` | estimated shipping rebate by shopee, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `estimate_shipping_rebate_by_shopee_amt_usd` | `decimal(35,10)` | estimated shipping rebate by shopee in usd, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `estimate_shipping_rebate_by_seller_amt` | `decimal(35,10)` | estimated shipping rebate by seller, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `estimate_shipping_rebate_by_seller_amt_usd` | `decimal(35,10)` | estimated shipping rebate by seller in usd, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `actual_shipping_rebate_by_shopee_amt` | `double` | shipping rebate by shopee, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `actual_shipping_rebate_by_shopee_amt_usd` | `double` | shipping rebate by shopee in usd, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `actual_shipping_rebate_by_seller_amt` | `double` | shipping rebate by seller, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `actual_shipping_rebate_by_seller_amt_usd` | `double` | shipping rebate by seller in usd, if the order is not yet shipped, this field will be estimated shipping rebate based on current shipping fee and promotion |
| `estimate_net_total_item_voucher_logst_prm_usd_level1` | `double` | estimate_net_total_item_voucher_logst_prm_usd_level1 |
| `estimate_net_total_logst_prm_usd_level1` | `double` | estimate_net_total_logst_prm_usd_level1 |
| `estimate_net_total_item_card_prm_usd_level1` | `double` | estimate_net_total_item_card_prm_usd_level1 |
| `estimate_net_total_voucher_prm_usd_level1` | `double` | estimate_net_total_voucher_prm_usd_level1 |
| `estimate_net_total_coin_prm_usd_level1` | `double` | estimate_net_total_coin_prm_usd_level1 |
| `net_total_item_voucher_logst_prm_usd_level1` | `double` | net_total_item_voucher_logst_prm_usd_level1 |
| `net_total_logst_prm_usd_level1` | `double` | net_total_logst_prm_usd_level1 |
| `net_total_item_card_prm_usd_level1` | `double` | net_total_item_card_prm_usd_level1 |
| `net_total_voucher_prm_usd_level1` | `double` | net_total_voucher_prm_usd_level1 |
| `net_total_coin_prm_usd_level1` | `double` | net_total_coin_prm_usd_level1 |
| `gross_total_item_voucher_logst_prm_usd_level1` | `double` | gross_total_item_voucher_logst_prm_usd_level1 |
| `gross_total_logst_prm_usd_level1` | `double` | gross_total_logst_prm_usd_level1 |
| `gross_total_item_card_prm_usd_level1` | `double` | gross_total_item_card_prm_usd_level1 |
| `gross_total_voucher_prm_usd_level1` | `double` | gross_total_voucher_prm_usd_level1 |
| `gross_total_coin_prm_usd_level1` | `double` | gross_total_coin_prm_usd_level1 |
| `estimate_net_logst_rebate_usd_level2` | `double` | estimate_net_logst_rebate_usd_level2 |
| `estimate_net_logst_rebate_ex_usd_level2` | `double` | estimate_net_logst_rebate_ex_usd_level2 |
| `estimate_net_logst_rebate_incl_usd_level2` | `double` |  |
| `estimate_net_government_subsidy_logst_rebate_ex_usd_level3` | `double` | estimate_net_government_subsidy_logst_rebate_ex_usd_level3 |
| `estimate_net_giftcard_logst_rebate_ex_usd_level3` | `double` | estimate_net_giftcard_logst_rebate_ex_usd_level3 |
| `estimate_net_cosponsored_logst_rebate_ex_usd_level3` | `double` | estimate_net_cosponsored_logst_rebate_ex_usd_level3 |
| `estimate_net_logst_rebate_by_shopee_pay_usd_level3` | `double` | estimate_net_logst_rebate_by_shopee_pay_usd_level3 |
| `estimate_net_logst_rebate_ex_by_shopee_paylater_usd_level3` | `double` | estimate_net_logst_rebate_ex_by_shopee_paylater_usd_level3 |
| `estimate_net_logst_rebate_ex_by_bank_usd_level3` | `double` | estimate_net_logst_rebate_ex_by_bank_usd_level3 |
| `estimate_net_pv_rebate_usd_level2` | `double` | estimate_net_logst_rebate_ex_by_bank_usd_level3 |
| `estimate_net_pv_rebate_ex_usd_level2` | `double` | estimate_net_pv_rebate_ex_usd_level2 |
| `estimate_net_pv_rebate_incl_usd_level2` | `double` | estimate_net_pv_rebate_incl_usd_level2 |
| `estimate_net_government_subsidy_pv_rebate_ex_usd_level3` | `double` | estimate_net_government_subsidy_pv_rebate_ex_usd_level3 |
| `estimate_net_giftcard_pv_rebate_ex_usd_level3` | `double` | estimate_net_giftcard_pv_rebate_ex_usd_level3 |
| `estimate_net_cosponsored_pv_rebate_ex_usd_level3` | `double` | estimate_net_pv_rebate_by_shopee_pay_usd_level3 |
| `estimate_net_pv_rebate_by_shopee_pay_usd_level3` | `double` | estimate_net_pv_rebate_by_shopee_pay_usd_level3 |
| `estimate_net_pv_rebate_ex_by_shopee_paylater_usd_level3` | `double` | estimate_net_pv_rebate_ex_by_shopee_paylater_usd_level3 |
| `estimate_net_pv_rebate_ex_by_bank_usd_level3` | `double` | estimate_net_pv_rebate_ex_by_bank_usd_level3 |
| `estimate_net_sv_rebate_usd_level2` | `double` | estimate_net_sv_rebate_usd_level2 |
| `estimate_net_sv_rebate_ex_usd_level2` | `double` | estimate_net_sv_rebate_ex_usd_level2 |
| `estimate_net_sv_rebate_incl_usd_level2` | `double` | estimate_net_sv_rebate_incl_usd_level2 |
| `estimate_net_government_subsidy_sv_rebate_ex_usd_level3` | `double` | estimate_net_government_subsidy_sv_rebate_ex_usd_level3 |
| `estimate_net_giftcard_sv_rebate_ex_usd_level3` | `double` | estimate_net_giftcard_sv_rebate_ex_usd_level3 |
| `estimate_net_cosponsored_sv_rebate_ex_usd_level3` | `double` | estimate_net_cosponsored_sv_rebate_ex_usd_level3 |
| `estimate_net_sv_rebate_by_shopee_pay_usd_level3` | `double` | estimate_net_sv_rebate_by_shopee_pay_usd_level3 |
| `estimate_net_sv_rebate_ex_by_shopee_paylater_usd_level3` | `double` | estimate_net_sv_rebate_ex_by_shopee_paylater_usd_level3 |
| `estimate_net_sv_rebate_ex_by_bank_usd_level3` | `double` | estimate_net_sv_rebate_ex_by_bank_usd_level3 |
| `estimate_net_item_rebate_usd_level2` | `double` | estimate_net_item_rebate_usd_level2 |
| `estimate_net_item_rebate_ex_usd_level2` | `double` | estimate_net_item_rebate_ex_usd_level2 |
| `estimate_net_item_rebate_incl_usd_level2` | `double` | estimate_net_item_rebate_incl_usd_level2 |
| `estimate_net_government_subsidy_item_rebate_ex_usd_level3` | `double` | estimate_net_government_subsidy_item_rebate_ex_usd_level3 |
| `estimate_net_cosponsored_item_rebate_ex_usd_level3` | `double` | estimate_net_cosponsored_item_rebate_ex_usd_level3 |
| `estimate_net_trade_in_bonus_item_rebate_usd_level3` | `double` |  |
| `estimate_net_pix_item_rebate_incl_usd_level3` | `double` | estimate_net_pix_item_rebate_incl_usd_level3 |
| `estimate_net_card_rebate_usd_level2` | `double` | estimate_net_card_rebate_usd_level2 |
| `estimate_net_card_rebate_ex_usd_level2` | `double` | estimate_net_card_rebate_ex_usd_level2 |
| `estimate_net_cosponsored_card_rebate_ex_usd_level3` | `double` | estimate_net_cosponsored_card_rebate_ex_usd_level3 |
| `estimate_net_card_rebate_by_shopee_pay_usd_level3` | `double` |  |
| `estimate_net_card_rebate_by_shopee_paylater_usd_level3` | `double` |  |
| `estimate_net_card_rebate_by_bank_usd_level3` | `double` |  |
| `estimate_net_basic_coin_earn_usd_level2` | `double` | estimate_net_basic_coin_earn_usd_level2 |
| `estimate_net_card_coin_earn_usd_level2` | `double` |  |
| `estimate_net_card_coin_earn_ex_by_bank_usd_level3` | `double` |  |
| `estimate_net_card_coin_earn_ex_by_shopee_pay_usd_level3` | `double` |  |
| `estimate_net_card_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` |  |
| `estimate_net_pv_coin_earn_usd_level2` | `double` | estimate_net_pv_coin_earn_usd_level2 |
| `estimate_net_pv_coin_earn_ex_usd_level2` | `double` | estimate_net_pv_coin_earn_ex_usd_level2 |
| `estimate_net_pv_coin_earn_incl_usd_level2` | `double` | estimate_net_pv_coin_earn_incl_usd_level2 |
| `estimate_net_government_subsidy_pv_coin_earn_ex_usd_level3` | `double` | estimate_net_government_subsidy_pv_coin_earn_ex_usd_level3 |
| `estimate_net_giftcard_pv_coin_earn_ex_usd_level3` | `double` | estimate_net_giftcard_pv_coin_earn_ex_usd_level3 |
| `estimate_net_cosponsored_pv_coin_earn_ex_usd_level3` | `double` | estimate_net_cosponsored_pv_coin_earn_ex_usd_level3 |
| `estimate_net_pv_coin_earn_by_shopee_pay_usd_level3` | `double` | estimate_net_pv_coin_earn_by_shopee_pay_usd_level3 |
| `estimate_net_pv_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` | estimate_net_pv_coin_earn_ex_by_shopee_paylater_usd_level3 |
| `estimate_net_pv_coin_earn_ex_by_bank_usd_level3` | `double` | estimate_net_pv_coin_earn_ex_by_bank_usd_level3 |
| `estimate_net_sv_coin_earn_usd_level2` | `double` | estimate_net_sv_coin_earn_usd_level2 |
| `estimate_net_sv_coin_earn_ex_usd_level2` | `double` | estimate_net_sv_coin_earn_ex_usd_level2 |
| `estimate_net_sv_coin_earn_incl_usd_level2` | `double` | estimate_net_sv_coin_earn_incl_usd_level2 |
| `estimate_net_government_subsidy_sv_coin_earn_ex_usd_level3` | `double` | estimate_net_government_subsidy_sv_coin_earn_ex_usd_level3 |
| `estimate_net_giftcard_sv_coin_earn_ex_usd_level3` | `double` | estimate_net_giftcard_sv_coin_earn_ex_usd_level3 |
| `estimate_net_cosponsored_sv_coin_earn_ex_usd_level3` | `double` | estimate_net_cosponsored_sv_coin_earn_ex_usd_level3 |
| `estimate_net_sv_coin_earn_by_shopee_pay_usd_level3` | `double` | estimate_net_sv_coin_earn_by_shopee_pay_usd_level3 |
| `estimate_net_sv_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` | estimate_net_sv_coin_earn_ex_by_shopee_paylater_usd_level3 |
| `estimate_net_sv_coin_earn_ex_by_bank_usd_level3` | `double` | estimate_net_sv_coin_earn_ex_by_bank_usd_level3 |
| `net_logst_rebate_usd_level2` | `double` | net_logst_rebate_usd_level2 |
| `net_logst_rebate_ex_usd_level2` | `double` | net_logst_rebate_ex_usd_level2 |
| `net_logst_rebate_incl_usd_level2` | `double` |  |
| `net_government_subsidy_logst_rebate_ex_usd_level3` | `double` | net_government_subsidy_logst_rebate_ex_usd_level3 |
| `net_giftcard_logst_rebate_ex_usd_level3` | `double` | net_giftcard_logst_rebate_ex_usd_level3 |
| `net_cosponsored_logst_rebate_ex_usd_level3` | `double` | net_cosponsored_logst_rebate_ex_usd_level3 |
| `net_logst_rebate_by_shopee_pay_usd_level3` | `double` | net_logst_rebate_by_shopee_pay_usd_level3 |
| `net_logst_rebate_ex_by_shopee_paylater_usd_level3` | `double` | net_logst_rebate_ex_by_shopee_paylater_usd_level3 |
| `net_logst_rebate_ex_by_bank_usd_level3` | `double` | net_logst_rebate_ex_by_bank_usd_level3 |
| `net_pv_rebate_usd_level2` | `double` | net_pv_rebate_usd_level2 |
| `net_pv_rebate_ex_usd_level2` | `double` | net_pv_rebate_ex_usd_level2 |
| `net_pv_rebate_incl_usd_level2` | `double` | net_pv_rebate_incl_usd_level2 |
| `net_government_subsidy_pv_rebate_ex_usd_level3` | `double` | net_government_subsidy_pv_rebate_ex_usd_level3 |
| `net_giftcard_pv_rebate_ex_usd_level3` | `double` | net_giftcard_pv_rebate_ex_usd_level3 |
| `net_cosponsored_pv_rebate_ex_usd_level3` | `double` | net_cosponsored_pv_rebate_ex_usd_level3 |
| `net_pv_rebate_by_shopee_pay_usd_level3` | `double` | net_pv_rebate_by_shopee_pay_usd_level3 |
| `net_pv_rebate_ex_by_shopee_paylater_usd_level3` | `double` | net_pv_rebate_ex_by_shopee_paylater_usd_level3 |
| `net_pv_rebate_ex_by_bank_usd_level3` | `double` | net_pv_rebate_ex_by_bank_usd_level3 |
| `net_sv_rebate_usd_level2` | `double` | net_sv_rebate_usd_level2 |
| `net_sv_rebate_ex_usd_level2` | `double` | net_sv_rebate_ex_usd_level2 |
| `net_sv_rebate_incl_usd_level2` | `double` | net_sv_rebate_incl_usd_level2 |
| `net_government_subsidy_sv_rebate_ex_usd_level3` | `double` | net_government_subsidy_sv_rebate_ex_usd_level3 |
| `net_giftcard_sv_rebate_ex_usd_level3` | `double` | net_giftcard_sv_rebate_ex_usd_level3 |
| `net_cosponsored_sv_rebate_ex_usd_level3` | `double` | net_cosponsored_sv_rebate_ex_usd_level3 |
| `net_sv_rebate_by_shopee_pay_usd_level3` | `double` | net_sv_rebate_by_shopee_pay_usd_level3 |
| `net_sv_rebate_ex_by_shopee_paylater_usd_level3` | `double` | net_sv_rebate_ex_by_shopee_paylater_usd_level3 |
| `net_sv_rebate_ex_by_bank_usd_level3` | `double` | net_sv_rebate_ex_by_bank_usd_level3 |
| `net_item_rebate_usd_level2` | `double` | net_item_rebate_usd_level2 |
| `net_item_rebate_ex_usd_level2` | `double` | net_item_rebate_ex_usd_level2 |
| `net_item_rebate_incl_usd_level2` | `double` | net_item_rebate_incl_usd_level2 |
| `net_government_subsidy_item_rebate_ex_usd_level3` | `double` | net_government_subsidy_item_rebate_ex_usd_level3 |
| `net_cosponsored_item_rebate_ex_usd_level3` | `double` | net_cosponsored_item_rebate_ex_usd_level3 |
| `net_trade_in_bonus_item_rebate_usd_level3` | `double` |  |
| `net_pix_item_rebate_incl_usd_level3` | `double` | net_pix_item_rebate_incl_usd_level3 |
| `net_card_rebate_usd_level2` | `double` | net_card_rebate_usd_level2 |
| `net_card_rebate_ex_usd_level2` | `double` | net_card_rebate_ex_usd_level2 |
| `net_cosponsored_card_rebate_ex_usd_level3` | `double` | net_cosponsored_card_rebate_ex_usd_level3 |
| `net_card_rebate_by_shopee_pay_usd_level3` | `double` |  |
| `net_card_rebate_by_shopee_paylater_usd_level3` | `double` |  |
| `net_card_rebate_by_bank_usd_level3` | `double` |  |
| `net_basic_coin_earn_usd_level2` | `double` | net_basic_coin_earn_usd_level2 |
| `net_card_coin_earn_usd_level2` | `double` |  |
| `net_card_coin_earn_ex_by_bank_usd_level3` | `double` |  |
| `net_card_coin_earn_ex_by_shopee_pay_usd_level3` | `double` |  |
| `net_card_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` |  |
| `net_pv_coin_earn_usd_level2` | `double` | net_pv_coin_earn_usd_level2 |
| `net_pv_coin_earn_ex_usd_level2` | `double` | net_pv_coin_earn_ex_usd_level2 |
| `net_pv_coin_earn_incl_usd_level2` | `double` | net_pv_coin_earn_incl_usd_level2 |
| `net_government_subsidy_pv_coin_earn_ex_usd_level3` | `double` | net_government_subsidy_pv_coin_earn_ex_usd_level3 |
| `net_giftcard_pv_coin_earn_ex_usd_level3` | `double` | net_giftcard_pv_coin_earn_ex_usd_level3 |
| `net_cosponsored_pv_coin_earn_ex_usd_level3` | `double` | net_cosponsored_pv_coin_earn_ex_usd_level3 |
| `net_pv_coin_earn_by_shopee_pay_usd_level3` | `double` | net_pv_coin_earn_by_shopee_pay_usd_level3 |
| `net_pv_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` | net_pv_coin_earn_ex_by_shopee_paylater_usd_level3 |
| `net_pv_coin_earn_ex_by_bank_usd_level3` | `double` | net_pv_coin_earn_ex_by_bank_usd_level3 |
| `net_sv_coin_earn_usd_level2` | `double` | net_sv_coin_earn_usd_level2 |
| `net_sv_coin_earn_ex_usd_level2` | `double` | net_sv_coin_earn_ex_usd_level2 |
| `net_sv_coin_earn_incl_usd_level2` | `double` | net_sv_coin_earn_incl_usd_level2 |
| `net_government_subsidy_sv_coin_earn_ex_usd_level3` | `double` | net_government_subsidy_sv_coin_earn_ex_usd_level3 |
| `net_giftcard_sv_coin_earn_ex_usd_level3` | `double` | net_giftcard_sv_coin_earn_ex_usd_level3 |
| `net_cosponsored_sv_coin_earn_ex_usd_level3` | `double` | net_cosponsored_sv_coin_earn_ex_usd_level3 |
| `net_sv_coin_earn_by_shopee_pay_usd_level3` | `double` | net_sv_coin_earn_by_shopee_pay_usd_level3 |
| `net_sv_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` | net_sv_coin_earn_ex_by_shopee_paylater_usd_level3 |
| `net_sv_coin_earn_ex_by_bank_usd_level3` | `double` | net_sv_coin_earn_ex_by_bank_usd_level3 |
| `net_invoice_fee_tax_saving_usd_level2` | `decimal(35,10)` |  |
| `net_coin_used_cash_amt_usd_level2` | `decimal(35,10)` | net_coin_used_cash_amt_usd_level2 |
| `gross_logst_rebate_usd_level2` | `double` | gross_logst_rebate_usd_level2 |
| `gross_logst_rebate_ex_usd_level2` | `double` | gross_logst_rebate_ex_usd_level2 |
| `gross_logst_rebate_incl_usd_level2` | `double` |  |
| `gross_government_subsidy_logst_rebate_ex_usd_level3` | `double` | gross_government_subsidy_logst_rebate_ex_usd_level3 |
| `gross_giftcard_logst_rebate_ex_usd_level3` | `double` | gross_giftcard_logst_rebate_ex_usd_level3 |
| `gross_cosponsored_logst_rebate_ex_usd_level3` | `double` | gross_cosponsored_logst_rebate_ex_usd_level3 |
| `gross_logst_rebate_by_shopee_pay_usd_level3` | `double` | gross_logst_rebate_by_shopee_pay_usd_level3 |
| `gross_logst_rebate_ex_by_shopee_paylater_usd_level3` | `double` | gross_logst_rebate_ex_by_shopee_paylater_usd_level3 |
| `gross_logst_rebate_ex_by_bank_usd_level3` | `double` | gross_logst_rebate_ex_by_bank_usd_level3 |
| `gross_pv_rebate_usd_level2` | `double` | gross_pv_rebate_usd_level2 |
| `gross_pv_rebate_ex_usd_level2` | `double` | gross_pv_rebate_ex_usd_level2 |
| `gross_pv_rebate_incl_usd_level2` | `double` | gross_pv_rebate_incl_usd_level2 |
| `gross_government_subsidy_pv_rebate_ex_usd_level3` | `double` | gross_government_subsidy_pv_rebate_ex_usd_level3 |
| `gross_giftcard_pv_rebate_ex_usd_level3` | `double` | gross_giftcard_pv_rebate_ex_usd_level3 |
| `gross_cosponsored_pv_rebate_ex_usd_level3` | `double` | gross_cosponsored_pv_rebate_ex_usd_level3 |
| `gross_pv_rebate_by_shopee_pay_usd_level3` | `double` | gross_pv_rebate_by_shopee_pay_usd_level3 |
| `gross_pv_rebate_ex_by_shopee_paylater_usd_level3` | `double` | gross_pv_rebate_ex_by_shopee_paylater_usd_level3 |
| `gross_pv_rebate_ex_by_bank_usd_level3` | `double` | gross_pv_rebate_ex_by_bank_usd_level3 |
| `gross_sv_rebate_usd_level2` | `double` | gross_sv_rebate_usd_level2 |
| `gross_sv_rebate_ex_usd_level2` | `double` | gross_sv_rebate_ex_usd_level2 |
| `gross_sv_rebate_incl_usd_level2` | `double` | gross_sv_rebate_incl_usd_level2 |
| `gross_government_subsidy_sv_rebate_ex_usd_level3` | `double` | gross_government_subsidy_sv_rebate_ex_usd_level3 |
| `gross_giftcard_sv_rebate_ex_usd_level3` | `double` | gross_giftcard_sv_rebate_ex_usd_level3 |
| `gross_cosponsored_sv_rebate_ex_usd_level3` | `double` | gross_cosponsored_pv_rebate_ex_usd_level3 |
| `gross_sv_rebate_by_shopee_pay_usd_level3` | `double` | gross_sv_rebate_by_shopee_pay_usd_level3 |
| `gross_sv_rebate_ex_by_shopee_paylater_usd_level3` | `double` | gross_sv_rebate_ex_by_shopee_paylater_usd_level3 |
| `gross_sv_rebate_ex_by_bank_usd_level3` | `double` | gross_sv_rebate_ex_by_bank_usd_level3 |
| `gross_item_rebate_usd_level2` | `double` | gross_item_rebate_usd_level2 |
| `gross_item_rebate_ex_usd_level2` | `double` | gross_item_rebate_ex_usd_level2 |
| `gross_item_rebate_incl_usd_level2` | `double` | gross_item_rebate_incl_usd_level2 |
| `gross_government_subsidy_item_rebate_ex_usd_level3` | `double` | gross_government_subsidy_item_rebate_ex_usd_level3 |
| `gross_cosponsored_item_rebate_ex_usd_level3` | `double` | gross_cosponsored_item_rebate_ex_usd_level3 |
| `gross_trade_in_bonus_item_rebate_usd_level3` | `double` |  |
| `gross_pix_item_rebate_incl_usd_level3` | `double` | gross_pix_item_rebate_incl_usd_level3 |
| `gross_card_rebate_usd_level2` | `double` | gross_giftcard_sv_rebate_ex_usd_level3 |
| `gross_card_rebate_ex_usd_level2` | `double` | gross_card_rebate_ex_usd_level2 |
| `gross_cosponsored_card_rebate_ex_usd_level3` | `double` | gross_cosponsored_card_rebate_ex_usd_level3 |
| `gross_card_rebate_by_shopee_pay_usd_level3` | `double` |  |
| `gross_card_rebate_by_shopee_paylater_usd_level3` | `double` |  |
| `gross_card_rebate_by_bank_usd_level3` | `double` |  |
| `gross_basic_coin_earn_usd_level2` | `double` | gross_basic_coin_earn_usd_level2 |
| `gross_card_coin_earn_usd_level2` | `double` |  |
| `gross_card_coin_earn_ex_by_bank_usd_level3` | `double` |  |
| `gross_card_coin_earn_ex_by_shopee_pay_usd_level3` | `double` |  |
| `gross_card_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` |  |
| `gross_pv_coin_earn_usd_level2` | `double` | gross_pv_coin_earn_usd_level2 |
| `gross_pv_coin_earn_ex_usd_level2` | `double` | gross_pv_coin_earn_ex_usd_level2 |
| `gross_pv_coin_earn_incl_usd_level2` | `double` | gross_pv_coin_earn_incl_usd_level2 |
| `gross_government_subsidy_pv_coin_earn_ex_usd_level3` | `double` | gross_government_subsidy_pv_coin_earn_ex_usd_level3 |
| `gross_giftcard_pv_coin_earn_ex_usd_level3` | `double` | gross_giftcard_pv_coin_earn_ex_usd_level3 |
| `gross_cosponsored_pv_coin_earn_ex_usd_level3` | `double` | gross_cosponsored_pv_coin_earn_ex_usd_level3 |
| `gross_pv_coin_earn_by_shopee_pay_usd_level3` | `double` | gross_pv_coin_earn_by_shopee_pay_usd_level3 |
| `gross_pv_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` | gross_pv_coin_earn_ex_by_shopee_paylater_usd_level3 |
| `gross_pv_coin_earn_ex_by_bank_usd_level3` | `double` | gross_pv_coin_earn_ex_by_bank_usd_level3 |
| `gross_sv_coin_earn_usd_level2` | `double` | gross_sv_coin_earn_usd_level2 |
| `gross_sv_coin_earn_ex_usd_level2` | `double` | gross_sv_coin_earn_ex_usd_level2 |
| `gross_sv_coin_earn_incl_usd_level2` | `double` | gross_sv_coin_earn_incl_usd_level2 |
| `gross_government_subsidy_sv_coin_earn_ex_usd_level3` | `double` | gross_government_subsidy_sv_coin_earn_ex_usd_level3 |
| `gross_giftcard_sv_coin_earn_ex_usd_level3` | `double` | gross_giftcard_sv_coin_earn_ex_usd_level3 |
| `gross_cosponsored_sv_coin_earn_ex_usd_level3` | `double` | gross_cosponsored_sv_coin_earn_ex_usd_level3 |
| `gross_sv_coin_earn_by_shopee_pay_usd_level3` | `double` | gross_sv_coin_earn_by_shopee_pay_usd_level3 |
| `gross_sv_coin_earn_ex_by_shopee_paylater_usd_level3` | `double` | gross_sv_coin_earn_ex_by_shopee_paylater_usd_level3 |
| `gross_sv_coin_earn_ex_by_bank_usd_level3` | `double` | gross_sv_coin_earn_ex_by_bank_usd_level3 |
| `gross_invoice_fee_tax_saving_usd_level2` | `decimal(35,10)` |  |
| `gross_coin_used_cash_amt_usd_level2` | `decimal(35,10)` | gross_coin_used_cash_amt_usd_level2 |
| `is_livestream_order` | `tinyint` | whether the order comes from livestreaming |
| `is_video_order` | `tinyint` | whether the order comes from video |
| `complete_datetime` | `varchar` | The date and time when the order item was officially completed. The field’s data unit is in the format YYYY-MM-DD HH:MM:SS. |
| `complete_timestamp` | `bigint` | The `complete_timestamp` column records the timestamp indicating when the order item was completed. The field’s data unit is recorded in Unix epoch format, which represents the number of seconds that have elapsed since January 1, 1970 (midnight UTC/GMT). |
| `grass_region` | `varchar` | region name |
| `grass_date` | `date` | order create date |

## 解析日志

- `mp_mgmt.dws_order_item_rebate_di__reg_s0_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_mgmt.dws_order_item_rebate_di__reg_s0_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
