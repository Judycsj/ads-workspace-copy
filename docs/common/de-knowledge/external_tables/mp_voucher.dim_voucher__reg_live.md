<!-- ads-workspace-gdoc-sync: gdoc_id=1ULn4xf_5DBxieUpqur8UlbMM4N5LswN5vPD4RScwbOY gdoc_url=https://docs.google.com/document/d/1ULn4xf_5DBxieUpqur8UlbMM4N5LswN5vPD4RScwbOY/edit -->

# mp_voucher.dim_voucher__reg_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_voucher.dim_voucher__reg_live`
- canonical_table: `mp_voucher.dim_voucher__reg_live`
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
| `promotion_id` | `bigint` | pk@Unique identifier for a voucher promotion aka voucher_id. This column is name promotion_id instead of voucher_id as it was named as such in the old voucher DB table. Each record presents all the configurations for a voucher promotion. Note that user voucher claimed by an user is found in mp_voucher.dwd_user_voucher_claim_di/df__{cid}_live |
| `voucher_name` | `varchar` | voucher_property@Name of voucher promotion |
| `voucher_description` | `varchar` | voucher_property@Detail description as shown in voucher promotion TnC |
| `voucher_business_domain_id` | `integer` | voucher_property@Business domain that voucher promotion is used for. Business domain is more granular then business line. e.g. voucher_business_line = `BUSINESS_LINE_CREDIT`, voucher_business_domain can be (`BUSINESS_DOMAIN_CASHLOAN_BUYER`, `BUSINESS_DOMAIN_CASHLOAN_SELLER`, `BUSINESS_DOMAIN_SPAYLATER`) \|voucher_v2_tab.business_domain \|enum BusinessDoma... |
| `voucher_business_domain` | `varchar` | voucher_property@voucher_business_domain_id in text. See voucher_business_domain_id column description |
| `voucher_business_line_id` | `integer` | voucher_property@Business line that voucher promotion is used for. Business domain is more granular then business line. e.g. voucher_business_line = `BUSINESS_LINE_CREDIT`, voucher_business_domain can be (`BUSINESS_DOMAIN_CASHLOAN_BUYER`, `BUSINESS_DOMAIN_CASHLOAN_SELLER`, `BUSINESS_DOMAIN_SPAYLATER`) \|voucher_v2_tab.business_line \|enum BusinessLine { B... |
| `voucher_business_line` | `varchar` | voucher_property@voucher_business_line_id in text. See voucher_business_line_id column description |
| `shop_id` | `bigint` | fk@Seller shop id. If 0 means this is not a seller voucher promotion. |
| `is_seller_voucher` | `tinyint` | voucher_property@Whether this is a seller voucher promotion |
| `voucher_status_id` | `integer` | voucher_property@Voucher promotion status id \|voucher_v2_tab.voucher_status \|enum PromotionStatus { PROMOTION_STATUS_DISABLED = 0 PROMOTION_STATUS_ENABLED = 1 PROMOTION_STATUS_DELETED = 2 PROMOTION_STATUS_FULLY_REDEEMED = 3 } |
| `voucher_status` | `varchar` | voucher_property@voucher_status_id in text. See voucher_status_id column description |
| `bms_project_code` | `varchar` | voucher_property@Budget management system (BMS) project code |
| `voucher_create_source_id` | `integer` | voucher_property@Voucher promotion create caller source id \|N/A \| enum CallerSource { SRC_ADMIN_PORTAL = 1 SRC_SELLER_CENTER = 2 SRC_SHOP_FOLLOW = 3 SRC_WEB_CHAT = 4 SRC_ORDER_SERVICE = 5 SRC_GAME = 6 SRC_FRAUD = 7 SRC_DIGITAL_PURCHASE = 8 SRC_SHOPEEPAY = 9 SRC_AIRPAY = 10 SRC_REFERRAL = 11 SRC_MARKETING = 12 SRC_GROWTH = 13 SRC_WSA = 14; // shopee Mark... |
| `voucher_create_source` | `varchar` | voucher_property@voucher_create_source_id in text. See voucher_create_source_id column description |
| `voucher_groups` | `array(varchar)` | voucher_property@Voucher groups that this voucher promotion belongs to. This is an extended feature of voucher label which provides another way for clients to identify groups of voucher promotions that are meant for a certain purpose. |
| `voucher_risk_code` | `varchar` | voucher_property@Voucher fraud risk code. See enum column for definition. \|W00: Block High Risk Buyers/Sellers B00: Block High/Mid Risk Buyers/Sellers G20: Dont Block Any User |
| `is_smart_voucher` | `tinyint` | voucher_property@Whether this is a smart voucher (Smart ads voucher or Smart reg voucher or Smart seller voucher)\|if(is_smart_voucher_tmp = 1 or is_smart_ads_voucher = 1, 1, 0) |
| `is_smart_ads_voucher` | `tinyint` | voucher_property@Whether this is a smart ads voucher\|if(array_contains(transform(voucher_groups, x -> regexp_like(x, `(?i)ads-roi`)), true), 1, 0) |
| `is_smart_reg_voucher` | `tinyint` | voucher_property@Whether this is a smart reg voucher\|if(array_contains(transform(voucher_groups, x -> regexp_like(x, `(?i)smart`) and regexp_like(x, `(?i)voucher`) and regexp_like(x, `(?i)reg`)), true), 1, 0) |
| `is_smart_seller_voucher` | `tinyint` | voucher_property@Whether this is an OFFICIAL smart seller voucher CREATED VIA SELLER CENTER. i.e. voucher_groups contains `SMART_SELLER_VOUCHER`.\|if(array_contains(transform(voucher_groups, x -> regexp_like(x, `(?i)smart_seller_voucher`)), true), 1, 0) |
| `voucher_package_id` | `bigint` | voucher_property@Unique identifier for a voucher package. This field identifies which package this voucher promotion belongs to. This is for smart seller vouchers. 1 voucher_package_id can be linked to n promotion_id.\|mp_rule.package_id |
| `is_dynamic_voucher` | `tinyint` | voucher_property@Whether this is a dynamic voucher promotion. Dynamic vouchers have varying reward information per user voucher under the same promotion ID.\|if(mp_rule.dynamic_rule is not null, 1, 0) |
| `dynamic_voucher_type_id` | `integer` | voucher_property@Dynamic voucher type identifier from promotion level dynamic_rule \|mp_rule.dynamic_rule.dynamic_voucher_type \|enum DynamicVoucherType { DYNAMIC_VOUCHER_TYPE_NONE = 0 DYNAMIC_VOUCHER_TYPE_REWARD = 1 DYNAMIC_VOUCHER_TYPE_REWARD_ITEM = 2 } |
| `dynamic_voucher_reward_sub_type_id` | `integer` | voucher_property@Dynamic voucher reward sub type identifier from promotion level dynamic_rule \|mp_rule.dynamic_rule.reward_sub_type \|enum RewardSubType { REWRAD_SUB_TYPE_NONE = 0 REWRAD_SUB_TYPE_FIXED = 1 REWRAD_SUB_TYPE_PERCENTAGE = 2 } |
| `is_multi_voucher_code` | `tinyint` | voucher_property@Whether voucher promotion is multiple voucher code type. |
| `single_voucher_code` | `varchar` | voucher_property@Voucher code for single voucher code type voucher promotion. This value is null if is_multiple_voucher_code = 1. |
| `multi_voucher_code_prefix` | `varchar` | voucher_property@Voucher code prefix for multiple voucher code type voucher promotion. Fully qualified voucher codes are generated from this prefix. Total length of generated voucher code depends on multi_voucher_code_suffix_len. Voucher code dispatch/claim by users are fully qualified voucher codes, not the prefix. This value is null if is_multiple_vouch... |
| `voucher_code_or_prefix` | `varchar` | voucher_property@Voucher code for single voucher code type OR voucher prefix for multiple voucher code type voucher promotion. |
| `multi_voucher_code_suffix_len` | `bigint` | voucher_property@Voucher code suffix length for mutiple voucher code type voucher promotion. |
| `voucher_claim_start_timestamp` | `bigint` | voucher_property@Voucher promotion FE claim start unix time. For SPP business line (voucher_business_line_id = 6), this is the start of the voucher template period. |
| `voucher_claim_start_datetime` | `varchar` | voucher_property@Voucher promotion FE claim start local datetime in string. For SPP business line (voucher_business_line_id = 6), this is the start of the voucher template period. |
| `voucher_claim_end_timestamp` | `bigint` | voucher_property@Voucher promotion FE claim end unix time For SPP business line (voucher_business_line_id = 6), this is the end of the voucher template period. |
| `voucher_claim_end_datetime` | `varchar` | voucher_property@Voucher promotion FE claim end local datetime in string. For SPP business line (voucher_business_line_id = 6), this is the end of the voucher template period. |
| `is_voucher_usage_period_fixed` | `tinyint` | voucher_property@Whether user voucher promotion usage period is fixed. For SPP business line (voucher_business_line_id = 6), this is the redemption period option type. |
| `voucher_usage_start_timestamp` | `bigint` | voucher_property@Voucher promotion usage start unix time. For SPP business line (voucher_business_line_id = 6), this is the start of the voucher redemption period. |
| `voucher_usage_start_datetime` | `varchar` | voucher_property@Voucher promotion usage start local datetime in string. For SPP business line (voucher_business_line_id = 6), this is the start of the voucher redemption period. |
| `voucher_usage_end_timestamp` | `bigint` | voucher_property@Voucher promotion usage end unix time. For SPP business line (voucher_business_line_id = 6), this is the end of the voucher redemption period. |
| `voucher_usage_end_datetime` | `varchar` | voucher_property@Voucher promotion usage end local datetime in string. For SPP business line (voucher_business_line_id = 6), this is the end of the voucher redemption period. |
| `is_voucher_expired` | `tinyint` | voucher_property@Whether voucher promotion is expired. |
| `is_voucher_valid` | `tinyint` | voucher_property@Whether voucher promotion is valid. Note definition: Valid = not expired + voucher_status is active. Purpose of this field is for users to filter voucher promotions that are still valid for user targeting. |
| `voucher_valid_duration_in_secs` | `bigint` | voucher_property@For non-fixed voucher usage period voucher promotion only. For SPP business line (voucher_business_line_id = 6), this is the voucher redemption duration. User voucher usage end time = user claim time + voucher_valid_duration_in_secs Value is null if is_voucher_usage_period_fixed = 1. |
| `is_early_display_voucher` | `tinyint` | voucher_property@Whether this is an early display voucher. If you want to filter Early Bird Seller Voucher (EBSV), use this logic: is_seller_voucher = 1and is_early_display_voucher = 1 |
| `voucher_early_display_start_timestamp` | `bigint` | voucher_property@Voucher promotion early display unix start time |
| `voucher_early_display_start_datetime` | `varchar` | voucher_property@Voucher promotion early display local start time in string |
| `is_dispatchable_by_shopee` | `tinyint` | voucher_property@Whether user vouchers can be dispatched by shopee system. Always 0 for multi voucher code voucher promotions. |
| `is_claimable_on_fe_channels` | `tinyint` | voucher_property@Whether user vouchers can be claimed from FE channels. Always 0 for multi voucher code voucher promotions. |
| `is_claimable_via_voucher_code` | `tinyint` | voucher_property@Whether user vouchers can be claimed by voucher code. Always 1 for multi voucher code voucher promotions. |
| `voucher_create_timestamp` | `bigint` | voucher_property@Voucher promotion create unix time |
| `voucher_create_datetime` | `varchar` | voucher_property@Voucher promotion create local datetime in string |
| `voucher_last_update_timestamp` | `bigint` | voucher_property@Voucher promotion last update unix time |
| `voucher_last_update_datetime` | `varchar` | voucher_property@Voucher promotion last update local datetime in string |
| `mp_voucher_settings` | `row(mp_voucher_type varchar, is_mp_plaform_voucher tinyint, voucher_purpose_id integer, voucher_purpose varchar, voucher_usecase_id integer, voucher_usecase varchar, is_seller_a...` | voucher_property@Marketplace voucher only settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `voucher_quota_settings` | `row(voucher_quota_type_id integer, voucher_quota_type varchar, user_voucher_claim_dispatch_cnt bigint, user_voucher_claim_dispatch_quota_cnt bigint, user_voucher_usage_cnt bigin...` | voucher_property@Voucher quota related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `voucher_reward_settings` | `row(voucher_reward_type_id integer, voucher_reward_type varchar, discount_rule_type varchar, fixed_discount_amt decimal(25,10), max_fixed_discount_amt decimal(25,10), discount_p...` | voucher_property@Voucher reward related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `product_usage_rules` | `row(is_all_products tinyint, include_shop_type_ids array(bigint), exclude_shop_type_ids array(bigint), include_fe_category_ids array(bigint), exclude_fe_category_ids array(bigin...` | voucher_property@Voucher product usage rules related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `user_usage_rules` | `row(is_all_users tinyint, is_by_user_segment tinyint, user_segment_name varchar, is_auto_dispatch_user_voucher tinyint, is_by_user_registration_time tinyint, user_registration_s...` | voucher_property@Voucher user usage rules related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `payment_usage_rules` | `row(is_all_payment_methods tinyint, is_allow_giro tinyint, is_allow_bank_giro tinyint, is_allow_shopee_pay_giro tinyint, is_allow_shopee_pay tinyint, is_allow_shopee_pay_only ti...` | voucher_property@Voucher payment usage rules related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `logistics_usage_rules` | `row(is_all_logistic_channels tinyint, is_all_shipping_promotion_rules tinyint, include_logistic_channel_ids array(bigint), exclude_logistic_channel_ids array(bigint), include_sh...` | voucher_property@Voucher logistic usage rules related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `other_usage_rules` | `row(is_exclude_blacklisted_phone_prefix tinyint, is_for_new_device_fingerprint_only tinyint, is_allow_ios tinyint, is_allow_android tinyint, is_allow_web tinyint, is_allow_meta_...` | voucher_property@Voucher other usage rules related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `fe_display_settings` | `row(branding_color_code_type varchar, is_do_not_display tinyint, is_display_default_pages tinyint, is_display_order_paid_page tinyint, is_display_feed_page tinyint, is_display_l...` | voucher_property@Voucher fe display related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `pn_settings` | `row(pn_reminder_mins_before_valid integer, is_pn_enabled tinyint, is_update_voucher_activity_to_friends tinyint, pn_content row(ar_title varchar, ar_content varchar, push_conten...` | voucher_property@Voucher private notification related settings. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `voucher_combined_extra_info` | `row(_decoded_distribution_rule varchar, _decoded_reward varchar, _decoded_extra_info varchar, _decoded_internal_extra_info varchar)` | voucher_property@Voucher extra info. Details: https://docs.google.com/spreadsheets/d/1GZKBbpFhYpw0qLL3xDSv55IYNJIqh6_zsHHUQjDfZ-w/edit?gid=1602660985#gid=1602660985 |
| `_combined_corrupt_json` | `row(has_corrupt_json tinyint, has_distribution_rule_corrupt_json tinyint, has_reward_corrupt_json tinyint, has_extra_info_corrupt_json tinyint, has_internal_extra_info_corrupt_j...` | internal@Column IS NOT meant to be used by external users! Voucher mart internal audit column to monitor from_json conversion error. Note that from_json conversion error does not affect json data in voucher_combined_extra_info, we do this conversion as an intermediate step in dim_voucher code so that we can select fields by dot notation instead of having... |
| `is_global_voucher` | `tinyint` | voucher_property@Whether this voucher promotion is added to global voucher wallet. Note that if is_multi_voucher_code = 1, only 1 particular voucher_code is added to global voucher wallet. See global_voucher_code to find out the specific voucher_code that is added. |
| `global_voucher_add_timestamp` | `bigint` | voucher_property@Unix time when this voucher voucher promotion was added to global voucher wallet |
| `global_voucher_add_datetime` | `varchar` | voucher_property@Local time in string when this voucher voucher promotion was added to global voucher wallet |
| `tz_type` | `varchar` | partition@tz_type of datetime columns. When `local`, refer to marketplace.dim_timezone__reg_live for timezone used for each region. When `regional`, Asia/Singapore timezone is used.\|N/A\|local only for this table |
| `grass_region` | `varchar` | partition@region\|N/A\|SG,MY,ID,TH,PH,TW,VN,BR,CL,CO,MX |
| `grass_date` | `date` | partition@Data event date Note: 1. This is a daily (D-1) full snapshot data table meaning each grass_date partition contains all historical data up till 23:59:59hrs in local timezone on this date 2. Use create_datetime column to filter event data by creation datetime. create_datetime datatype is intentionally set as string instead of timestamp to avoid un... |

## 解析日志

- `mp_voucher.dim_voucher__reg_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_voucher.dim_voucher__reg_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在
