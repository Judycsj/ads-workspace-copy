-- task_code: data_paidadsmart.studio_2660347  asset_id: 2660347
set time zone 'America/Araguaina';
INSERT OVERWRITE TABLE dwd_advertiser_transaction_di__reg_s0_live PARTITION (tz_type='local', grass_region='${upper_region}', grass_date='${grass_date}')
select id
    ,shopid as shop_id
    ,if(operation=11,cpm.user_id, coalesce(translog.userid,advertise.user_id)) as user_id
    ,adsid as ads_id
    ,coalesce(advertise.campaign_id,cast(get_json_object(decoded_extinfo,'$.campaignid') as bigint)) as campaign_id
    ,coalesce(advertise.placement,translog.placement) as placement
    ,advertise.ads_type as ads_type
    ,advertise.ads_status as ads_status
    ,keyword as keywords
    ,advertise.item_id as item_id
    ,price / pow(10,5)  AS price_local
    ,cast(operation as tinyint) as event_code
    ,CASE  WHEN operation = 1  THEN 'deduction'
        WHEN operation = 2  THEN 'topup_from_order'
        WHEN operation = 3  THEN 'topup_manual'
        WHEN operation = 4  THEN 'topup_wallet'
        WHEN operation = 5  THEN 'deduct_order'
        WHEN operation = 6  THEN 'topup_svs'
        WHEN operation = 8  THEN 'topup_from_seller_mission'
        WHEN operation = 9  THEN 'topup_from_srm'
        WHEN operation = 10 THEN 'topup_negative'
        WHEN operation = 11 THEN 'deduct_imp'
        ELSE NULL END AS event_type
    ,timestamp as event_timestamp
    ,from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
    ,acc_before_balance / pow(10,5) AS acc_before_balance_local
    ,acc_after_balance / pow(10,5) AS acc_after_balance_local
    ,dai_before_balance / pow(10,5) AS dai_before_balance_local
    ,dai_after_balance / pow(10,5) AS dai_after_balance_local
    ,coalesce(get_json_object(decoded_extinfo, '$.adsCredits'),get_json_object(decoded_extinfo, '$.frozen.adsCredits')) AS deduction_details
    ,cast(get_json_object(decoded_extinfo,'$.matchType') as int) as match_type
    ,cast(get_json_object(decoded_extinfo,'$.recallType') as int) as recall_type
    ,cast(get_json_object(decoded_extinfo,'$.expectDeductPrice') as bigint) as expected_price_deduction
    ,get_json_object(decoded_extinfo,'$.query.keyword') as user_query
    ,cast(get_json_object(decoded_extinfo,'$.query.sorttype') as int) as sort_type
    ,cast(get_json_object(decoded_extinfo,'$.query.itemid') as bigint) as pdp_item_id
    ,cast(get_json_object(decoded_extinfo,'$.query.shopid') as bigint) as pdp_shop_id
    ,cast(get_json_object(decoded_extinfo,'$.deductionInfo.quality') as DOUBLE) as pctr
    ,cast(get_json_object(decoded_extinfo,'$.deductionInfo.bidprice') as BIGINT) as bid_price
    ,cast(get_json_object(decoded_extinfo,'$.deductionInfo.nextScore') as DOUBLE) as second_ads_ecpm
    ,cast(get_json_object(decoded_extinfo,'$.deductionInfo.nextAdsid') as BIGINT) as second_ads_id
    ,get_json_object(decoded_extinfo,'$.deductionInfo.algoName') as ab_sign
    ,null as topup_order_id
    ,get_json_object(decoded_extinfo,'$.paidFreeExpirySummary') paid_free_expiry_summary
    ,null as topup_sign
    ,status
    ,if(operation=11,cpm.entrance, cast(get_json_object(decoded_extinfo,'$.entrance') as int)) as entrance
    ,coalesce(cast(get_json_object(decoded_extinfo,'$.pricingType') as int),advertise.pricing_type) as pricing_type
    ,decoded_extinfo
    ,account_id
    ,translog.deduct_unique_id
from (
    select *
    from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
    where grass_region = '${upper_region}' and grass_date = date('${grass_date}') and tz_type = 'local'
        and keyword != 'system_dummy_negative_deduction'
) translog left join(
    select translog.deduct_unique_id as deduct_unique_id
        ,translog.adsid as ads_id
        ,cpm_detail.user_id as user_id
        ,cpm_detail.entrance as entrance
    from mp_paidads.ods_log_translog_event_hi__reg_s0_live
    lateral view EXPLODE(FROM_JSON(cpm_event_details_str, 'array<struct<user_id:BIGINT,entrance:int>>')) t as cpm_detail
    where   grass_region = '${upper_region}'
    and   grass_date >= DATE('${grass_date}') and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    and   translog.timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
    and   translog.timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
    and translog.operation =11
) cpm on translog.operation =11 and translog.deduct_unique_id=cpm.deduct_unique_id and translog.adsid=cpm.ads_id
LEFT JOIN (
        SELECT ads_id,campaign_id,ads_status,placement,ads_type,item_id,seller_id AS user_id,pricing_type
        FROM mp_paidads.dim_advertise__reg_s0_live
        WHERE grass_region = '${upper_region}' AND grass_date = DATE('${grass_date}')
) advertise ON translog.adsid = advertise.ads_id AND translog.placement = advertise.placement
;

alter table dwd_advertiser_transaction_di__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");