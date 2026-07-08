<!-- ads-workspace-gdoc-sync: gdoc_id=1AtpdVMuaSwpKdXrPfapQ0eNenMZv3h7EQfd-mGe5zAU gdoc_url=https://docs.google.com/document/d/1AtpdVMuaSwpKdXrPfapQ0eNenMZv3h7EQfd-mGe5zAU/edit -->

# mp_voucher.dwd_user_voucher_claim_df__reg_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_voucher.dwd_user_voucher_claim_df__reg_live`
- canonical_table: `mp_voucher.dwd_user_voucher_claim_df__reg_live`
- resolution: `describe:exact`
- source: `datasuite_describe`
- business_docs: `roi3_ads_voucher`

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
| `id` | `bigint` | pk@Unique identifier for voucher wallet. Can be taken as user voucher claim event id Each record represents a voucher claim event. A claim could be initiated by buyers via clicks on our app or via voucher code. It could also be initiated by sellers/shopee via dispatch. A special case is global vouchers. Global voucher does not need to be claimed and CANNO... |
| `promotion_id` | `bigint` | pk@Unique identifier for voucher promotion\|voucher_wallet_v3_tab.promotion_id |
| `user_id` | `bigint` | pk@Unique identifier for buyer.\|voucher_wallet_v3_tab.user_id |
| `voucher_code` | `varchar` | pk@Voucher code in text\|voucher_wallet_v3_tab.voucher_code |
| `shop_id` | `bigint` | voucher_property@Unique identifier of a shop. This field is more than 0 for seller vouchers ONLY.\|voucher_wallet_v3_tab.shop_id |
| `voucher_business_domain_id` | `integer` | voucher_property@voucher business domain \|voucher_wallet_v3_tab.voucher_market_type \|enum BusinessDomain { BUSINESS_DOMAIN_MARKETPLACE = 1; BUSINESS_DOMAIN_DIGITAL_PURCHASE = 2; BUSINESS_DOMAIN_CASHLOAN_BUYER = 3; BUSINESS_DOMAIN_OFFLINE_PAYMENT = 4; BUSINESS_DOMAIN_CASHLOAN_SELLER = 5; BUSINESS_DOMAIN_SHOPEE_EXPRESS = 6; BUSINESS_DOMAIN_SHOPEE_FOOD = 8... |
| `voucher_business_domain` | `varchar` | voucher_property@voucher business domain in text \|voucher_wallet_v3_tab.voucher_market_type \|enum BusinessDomain { BUSINESS_DOMAIN_MARKETPLACE = 1; BUSINESS_DOMAIN_DIGITAL_PURCHASE = 2; BUSINESS_DOMAIN_CASHLOAN_BUYER = 3; BUSINESS_DOMAIN_OFFLINE_PAYMENT = 4; BUSINESS_DOMAIN_CASHLOAN_SELLER = 5; BUSINESS_DOMAIN_SHOPEE_EXPRESS = 6; BUSINESS_DOMAIN_SHOPEE_... |
| `voucher_reward_type_id` | `tinyint` | voucher_property@Voucher reward type \|voucher_wallet_v3_tab.reward_type_id \|enum VoucherRewardType { VOUCHER_REWARD_PRODUCT_DISCOUNT = 0 VOUCHER_REWARD_COIN_CASHBACK = 1 VOUCHER_REWARD_FREE_SHIPPING = 2 VOUCHER_REWARD_PREPAID_CASHBACK = 3 VOUCHER_REWARD_PREPAID_COIN_CASHBACK = 4 VOUCHER_REWARD_PREPAID_DISCOUNT = 5 VOUCHER_REWARD_SHIPPING_FEE = 6 VOUCHER... |
| `voucher_reward_type` | `varchar` | voucher_property@Voucher reward type in text \|voucher_wallet_v3_tab.reward_type \|enum VoucherRewardType { VOUCHER_REWARD_PRODUCT_DISCOUNT = 0 VOUCHER_REWARD_COIN_CASHBACK = 1 VOUCHER_REWARD_FREE_SHIPPING = 2 VOUCHER_REWARD_PREPAID_CASHBACK = 3 VOUCHER_REWARD_PREPAID_COIN_CASHBACK = 4 VOUCHER_REWARD_PREPAID_DISCOUNT = 5 VOUCHER_REWARD_SHIPPING_FEE = 6 VO... |
| `voucher_use_type_id` | `integer` | voucher_property@voucher use type \|voucher_wallet_v3_tab.use_type \|enum UseType { USE_TYPE_PRIVATE = 0; USE_TYPE_PUBLIC = 1; } |
| `voucher_use_type` | `varchar` | voucher_property@voucher use type in text \|voucher_wallet_v3_tab.use_type \|enum UseType { USE_TYPE_PRIVATE = 0; USE_TYPE_PUBLIC = 1; } |
| `is_seller_voucher` | `tinyint` | voucher_property@Whether this is a seller voucher\|if(shop_id>0, 1, 0)\|1: True, 0: False |
| `marketplace_voucher_type` | `varchar` | voucher_property@ Marketplace Voucher Type \|dwd_voucher_claim_di.business_domain_id,shop_id,voucher_reward_type_id \|PV: Shopee Voucher/Platform Voucher SV: Seller Voucher FSV: Free Shipping Voucher null: voucher_business_domain_id != 1 |
| `voucher_purpose_id` | `tinyint` | voucher_property@Voucher purpose \|dim_voucher.purpose_id \|enum VoucherPurpose { VOUCHER_PURPOSE_WELCOME = 1 // welcome voucher VOUCHER_PURPOSE_REFERRAL = 2 // referral voucher VOUCHER_PURPOSE_SHOP_FOLLOW = 3 // shop follow voucher VOUCHER_PURPOSE_SHOP_GAME = 4 // shop game voucher VOUCHER_PURPOSE_SELLER_MEMBER_FREE_GIFT = 5 // seller member free gift vo... |
| `voucher_purpose` | `varchar` | voucher_property@Voucher purpose in text \|dim_voucher.purpose \|enum VoucherPurpose { VOUCHER_PURPOSE_WELCOME = 1 // welcome voucher VOUCHER_PURPOSE_REFERRAL = 2 // referral voucher VOUCHER_PURPOSE_SHOP_FOLLOW = 3 // shop follow voucher VOUCHER_PURPOSE_SHOP_GAME = 4 // shop game voucher VOUCHER_PURPOSE_SELLER_MEMBER_FREE_GIFT = 5 // seller member free gi... |
| `voucher_usecase_id` | `integer` | voucher_property@Voucher usecase identifier. This is used to identify the specific use case or scenario for which the voucher is created. |
| `voucher_usecase` | `varchar` | voucher_property@Voucher usecase in text format. This describes the specific use case or scenario for which the voucher is created. |
| `is_early_display_voucher` | `tinyint` | voucher_property@Whether this voucher is displayed earlier than its claim start time\|1: True, 0: False |
| `is_global_voucher` | `tinyint` | voucher_property@Whether this is a global voucher or preloaded voucher\|dim_voucher.is_global_voucher\|1: True, 0: False |
| `is_valid_period_fixed` | `tinyint` | voucher_property@Whether usage validity period is fixed.\|dim_voucher.is_valid_period_fixed\|1: True, 0: False |
| `valid_duration_in_secs` | `bigint` | voucher_property@Duration in sec user voucher is valid since claimed\|dim_voucher.valid_duration |
| `voucher_claim_start_timestamp` | `bigint` | voucher_property@Unix time when users can start claiming this voucher\|dim_voucher.claim_start_time |
| `voucher_claim_start_datetime` | `varchar` | voucher_property@Datetime in local timezone when users can start claiming this voucher\|dim_voucher.claim_start_time |
| `voucher_claim_end_timestamp` | `bigint` | voucher_property@Unix time when users can no longer claim this voucher\|dim_voucher.claim_end_time |
| `voucher_claim_end_datetime` | `varchar` | voucher_property@Datetime in local timezone when users can no longer claim this voucher\|dim_voucher.claim_end_time |
| `voucher_usage_start_timestamp` | `bigint` | voucher_property@Unix time when users can start using this voucher\|dim_voucher.start_time |
| `voucher_usage_start_datetime` | `varchar` | voucher_property@Datetime in local timezone when users can start using this voucher\|dim_voucher.start_time |
| `voucher_usage_end_timestamp` | `bigint` | voucher_property@Unix time when users can no longer use this voucher\|dim_voucher.end_time |
| `voucher_usage_end_datetime` | `varchar` | voucher_property@Datetime in local timezone when users can no longer use this voucher\|dim_voucher.end_time |
| `user_registration_timestamp` | `bigint` | buyer_property@Unix time where buyer joins shopee\|shopee_account_v2_db__account_tab.dim_user__reg_s0_live.registration_timestamp |
| `user_registration_datetime` | `varchar` | buyer_property@Datetime in local timezone where buyer joins shopee\|shopee_account_v2_db__account_tab.dim_user__reg_s0_live.registration_datetime |
| `user_business_id` | `bigint` | buyer_property@business_id that users belong to, Shopee, SPX, Food etc etc\|shopee_account_v2_db__account_tab.business_id\| 0 or null -> Shopee buyer 1 -> ShopeePay merchant 2 -> Shopee food driver 3 -> Shopee Express driver 4 -> Shopee Express seller 5 -> Shopee Logistics portal 6 -> Seller Mainsub |
| `is_mp_user` | `tinyint` | Marketplace User = 1, else 0 |
| `user_voucher_claim_dispatch_timestamp` | `bigint` | user_voucher_property@Unix time where this user voucher is saved in user voucher wallet. This is considered user voucher claim/dispatched time.\|voucher_wallet_v3_tab.ctime |
| `user_voucher_claim_dispatch_datetime` | `varchar` | user_voucher_property@Datetime in local timezone where this user voucher is saved in user voucher wallet. This is considered user voucher claim/dispatched time.\|voucher_wallet_v3_tab.ctime |
| `user_voucher_usage_start_timestamp` | `bigint` | user_voucher_property@User voucher usage validity start unix time. If is_valid_period_fixed = 0, this equals final start_timestamp.\|voucher_wallet_v3_tab.start_time |
| `user_voucher_usage_start_datetime` | `varchar` | user_voucher_property@User voucher usage validity start datetime in local timezone. If is_valid_period_fixed = 0, this equals final start_datetime.\|voucher_wallet_v3_tab.start_time |
| `user_voucher_usage_end_timestamp` | `bigint` | user_voucher_property@User voucher usage validity end unix time. If is_valid_period_fixed = 0, this equals final end_timestamp.\|voucher_wallet_v3_tab.end_time |
| `user_voucher_usage_end_datetime` | `varchar` | user_voucher_property@User voucher usage validity end datetime in local timezone. If is_valid_period_fixed = 0, this equals final end_datetime.\|voucher_wallet_v3_tab.end_time |
| `final_user_voucher_usage_start_timestamp` | `bigint` | promotion start timestamp / voucher validity start timestamp |
| `final_user_voucher_usage_start_datetime` | `varchar` | promotion start datetime / voucher validity start datetime |
| `final_user_voucher_usage_end_timestamp` | `bigint` | promotion end timestamp / voucher validity end timestamp |
| `final_user_voucher_usage_end_datetime` | `varchar` | promotion end datetime / voucher validity end datetime |
| `user_voucher_reference_id` | `varchar` | user_voucher_property@Use voucher reference id - an dentifier to keep track of where a user voucher is purchased/issued from\|voucher_wallet_v3_tab.reference_id |
| `user_voucher_distribution_method_id` | `bigint` | user_voucher_property@Distribution method (in id) that this user voucher was acquired from Note that this is a new column added by BE in late 2022. Official launch of the column was Jan 2022. Data wise, we see this distribution_method_id/distribution_method = null up till Mar 2023. All records should have distribution_method_id/distribution_method from Ap... |
| `user_voucher_distribution_method` | `varchar` | user_voucher_property@Distribution method (in text) that this user voucher was acquired from \|voucher_distribution_method_enum_view.distribution_method \|VOUCHER_DISTRIBUTION_METHOD_ALL = 0 -> Only for global voucher. See below for details step1: Ops create a global voucher (admin) step2: Ops dispatch a global voucher to all, BE insert a row in globalvou... |
| `user_voucher_dispatch_source_id` | `integer` | user_voucher_property@Source identifier for dispatched vouchers. This indicates which system or process initiated the voucher dispatch. |
| `is_user_voucher_random_code` | `boolean` | user_voucher_property@Whether generated voucher code is totally random Note that there are 3 ways of generating voucher_code: 1. Manual/hard-coded by operator 2. Generate from prefix and suffix length 3. Generate the entire voucher code randomly \|case _decoded_extinfo.is_random_code when true then 1 when false then 0 else null end as is_random_code \|1:... |
| `is_randomly_generated_voucher_code` | `tinyint` | logic@to deterimine whether the voucher code is generated - based on the presence of the reference id |
| `user_voucher_ticket_cnt` | `bigint` | user_voucher_property@Usage limit per user voucher. If this is more than 1 then this user voucher could be used multiple times.\|voucher_wallet_v3_tab.total_count |
| `user_voucher_ticket_used_cnt` | `bigint` | user_voucher_property@Latest usage count for this user voucher. Refer to total_count to find out how many times this user voucher could be used.\|voucher_wallet_v3_tab.used_count |
| `user_voucher_status_id` | `tinyint` | user_voucher_property@User voucher status 1. Note that status has nothing to do with validity period of a voucher promotion. e.g. If a voucher promotion has ended, the status would NOT change automatically to disabled. 2. Note that this status is for an user voucher. The voucher promotion (in dim_voucher) has its own status. Both status have to be enabled... |
| `user_voucher_status` | `varchar` | user_voucher_property@User voucher status in text 1. Note that status has nothing to do with validity period of a voucher promotion. e.g. If a voucher promotion has ended, the status would NOT change automatically to disabled. 2. Note that this status is for an user voucher. The voucher promotion (in dim_voucher) has its own status. Both status have to be... |
| `user_voucher_extra_info` | `varchar` | user_voucher_property@User voucher extra info. Stores miscellanenous extra fields, see enum section to see what fields are available. \|message UserVoucherExtInfo { optional uint32 distribution_method = 1; optional bool is_random_code = 2; optional uint32 distribution_source = 3; optional int64 last_usage_time = 4; // latest usage time among all the uses... |
| `is_user_voucher_expired` | `tinyint` | user_voucher_property@voucher_expiration, if 1 mean already expired, else 0 |
| `is_user_voucher_expire_today` | `tinyint` | user_voucher_property@voucher_expiration, if 1 mean voucher is expired on tdy, else 0 |
| `is_user_voucher_usable` | `tinyint` | user_voucher_property@voucher_usability, if 1 mean still usable, else 0 |
| `is_deleted` | `tinyint` | user_voucher_property@voucher_archival, if 1 mean voucher is already deleted else 0 |
| `is_failed_claim` | `tinyint` | user_voucher_property@voucher_claim, if the deletion event happened on the same day or the day before create date, potentially it is a failed claim |
| `tz_type` | `varchar` | partition@tz_type of datetime columns. When `local`, refer to marketplace.dim_timezone__reg_live for timezone used for each region. When `regional`, Asia/Singapore timezone is used. \|N/A \|local only for this table |
| `grass_region` | `varchar` | partition@region |
| `grass_date` | `date` | partition@Data archival date, date `9999-01-01` means the data is not archived yet i.e. Users can still find user voucher in their voucher wallet. Note: 1. This is a daily (D-1) full snapshot data table meaning each grass_date partition contains all historical event data up till 23:59:59hrs in local timezone on this date 2. Note that grass_date for this t... |
| `is_mp_voucher` | `tinyint` | partition@Whether this is a marketplace user voucher transaction\|if(voucher_business_domain = 1, 1, 0)\|1: true, 0: false |
| `is_dynamic_voucher` | `tinyint` | user_voucher_property@Whether this user voucher has dynamic reward scheme. Dynamic vouchers have varying reward information per user voucher under the same promotion ID.\|if(dynamic_user_voucher_extra_info is not null, 1, 0) |
| `dynamic_voucher_type_id` | `integer` | voucher_property@Dynamic voucher type identifier from promotion level dynamic_rule. Inherited from dim_voucher__reg_live.\|dim_voucher__reg_live.dynamic_voucher_type_id\|enum DynamicVoucherType { DYNAMIC_VOUCHER_TYPE_NONE = 0, DYNAMIC_VOUCHER_TYPE_REWARD = 1, DYNAMIC_VOUCHER_TYPE_REWARD_ITEM = 2 } |
| `dynamic_voucher_reward_sub_type_id` | `integer` | voucher_property@Dynamic voucher reward sub type identifier from promotion level dynamic_rule. Inherited from dim_voucher__reg_live.\|dim_voucher__reg_live.dynamic_voucher_reward_sub_type_id\|enum RewardSubType { REWRAD_SUB_TYPE_NONE = 0, REWRAD_SUB_TYPE_FIXED = 1, REWRAD_SUB_TYPE_PERCENTAGE = 2 } |
| `dynamic_user_voucher_extra_info` | `varchar` | user_voucher_property@Decoded JSON string containing dynamic_user_voucher_rule from extra_info field. Contains user-specific reward scheme information that varies per user voucher for dynamic vouchers. Decoded using mp_voucher.user_voucher_extrainfo_to_json() UDF.\|mp_voucher.user_voucher_extrainfo_to_json(get_json_object(_decoded_extinfo, "$.extra_info")... |
| `dynamic_user_voucher_reward_scheme` | `row(min_spend_amt decimal(25,10), fixed_discount_amt decimal(25,10), discount_pct decimal(25,10), discount_cap_amt decimal(25,10))` | user_voucher_property@User-specific dynamic reward scheme information. Contains reward details that vary per user for dynamic vouchers. Decoded from dynamic_user_voucher_rule.reward_rule in UserVoucherExtraInfo. Raw integer values are divided by powers of 10 to convert to actual amounts: min_spend_amt/fixed_discount_amt/discount_cap_amt divided by pow(10,... |
| `dynamic_user_voucher_product_rule` | `row(item row(shop_id bigint, item_id bigint))` | user_voucher_property@User-specific dynamic product scope information. Contains product scope details that vary per user for dynamic vouchers. Decoded from dynamic_user_voucher_rule.product_rule in UserVoucherExtraInfo.\|decoded from dynamic_user_voucher_rule.product_rule |

## 解析日志

- `mp_voucher.dwd_user_voucher_claim_df__reg_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_voucher.dwd_user_voucher_claim_df__reg_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
