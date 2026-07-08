-- task_code: data_paidadsmart.studio_2648380  asset_id: 2648380
-- UTC+8: SG,MY,PH,TW
SET TIME ZONE 'Asia/Singapore';

add jar hdfs://R2/projects/mkplpaidads_data/hdfs/udf/muyu.gao/paidads-data-warehouse-udf-1.0.4.jar;
CREATE or replace TEMPORARY FUNCTION get_topup_type as 'com.shopee.deepdata.warehouse.hive.udf.GetTopupType';
CREATE or replace TEMPORARY FUNCTION decode_extinfo as 'com.shopee.deepdata.warehouse.hive.udf.AdsCreditExtinfoDecodeUDF';


CREATE or replace TEMPORARY VIEW topup AS
(
    select  
    shop_id
    ,user_id
    ,order_id
    ,status AS svs_topup_status
    ,create_timestamp AS topup_create_timestamp
    ,create_datetime AS topup_create_datetime
    ,CASE
        WHEN a.order_type = 10 THEN (-1.0) * topup_amount
        ELSE topup_amount
    END AS topup_amt
    ,a.order_type
    ,b.order_type_name
    ,CASE WHEN date(create_datetime) = DATE('${grass_date}') THEN 1 ELSE 0 END AS is_topup_today
    ,package_id AS pckg_id
    ,original_price AS pckg_original_amt
    ,package_expiry_timestamp AS pckg_expiry_timestamp
    ,package_expiry_datetime AS pckg_expiry_datetime
    ,discount_price AS pckg_paid_amt
    ,voucher_id
    ,voucher_amount AS voucher_discount_amt
    ,voucher_expiry_timestamp
    ,voucher_expiry_datetime
    ,notified
    ,svs_entity_type
    ,svs_entity_id
    ,ads_package_id
    ,grass_region
FROM 
(
    SELECT
        orderid as order_id
        , order_type
        , userid as user_id
        , shopid as shop_id
        , amount / 100000.0 AS topup_amount
        , status
        , cast(notified as bigint)
        , order_time AS credit_approved_timestamp
        , CASE
            WHEN order_time = 0 THEN NULL
            ELSE from_unixtime(order_time, 'yyyy-MM-dd HH:mm:ss')
          END AS credit_approved_datetime
        , order_time AS create_timestamp
        , CASE
            WHEN order_time = 0 THEN NULL
            ELSE from_unixtime(order_time, 'yyyy-MM-dd HH:mm:ss')
          END AS create_datetime
        , discount_price / 100000.0 AS discount_price
        , original_price / 100000.0 AS original_price
        , package_expiry AS package_expiry_timestamp
        , CASE
            WHEN package_expiry = 0 THEN NULL 
            ELSE from_unixtime(package_expiry, 'yyyy-MM-dd HH:mm:ss')
          END AS package_expiry_datetime
        , package_id
        , voucher_id
        , voucher_amount / 100000.0 AS voucher_amount
        , voucher_expiry AS voucher_expiry_timestamp
        , CASE
            WHEN voucher_expiry = 0 THEN NULL
            ELSE from_unixtime(voucher_expiry, 'yyyy-MM-dd HH:mm:ss')
          END AS voucher_expiry_datetime
        ,CAST(get_json_object(decoded_extinfo, '$.svsEntityType') AS int) AS svs_entity_type 
        ,CAST(get_json_object(decoded_extinfo, '$.svsEntityId') AS bigint) AS svs_entity_id
        , ads_package_id
        , ucase('${region}') as grass_region
    FROM mp_paidads.ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live 
    WHERE tz_type='local'
          and grass_date = date('${grass_date}')
          and   grass_region = upper('${region}')
          and   order_time < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
)a left join (
    select cast(order_type as int) as order_type,order_type_name
    from mp_paidads.dim_translog_order_type_mapping__reg_s0_live
)b on a.order_type = b.order_type
WHERE  order_id > 0
);

--get credit subtype df
CREATE or replace TEMPORARY VIEW subtype AS
(
    select id
    ,ucase('${region}') as grass_region
    ,FIRST(subtype_name) AS sub_type_name
FROM mp_paidads.shopee_ads_${region}_central_db__promotion_paid_ads_manual_credit_subtype_tab__reg_continuous_s0_live
WHERE  ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
        AND id is not NULL
GROUP BY id
);

--get manual credit df 
CREATE or replace TEMPORARY VIEW manual AS
(
    SELECT
    reason AS credit_reason
    ,operator AS credit_operator
    ,ctime AS manual_credit_create_timestamp
    ,from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss') as manual_credit_create_datetime
    ,mtime AS manual_credit_approved_timestamp
    ,from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss') AS manual_credit_approved_datetime
    ,status AS credit_topup_status
    ,order_id as topup_order_id
    ,CASE WHEN amount < 0 THEN 10 ELSE order_type END AS credit_order_type
    ,main_type
    ,CASE
        WHEN main_type = 2 THEN 'paid credit'
        WHEN main_type = 3 THEN 'free credit'
     ELSE NULL END AS main_type_name
    ,subtype as sub_type
    ,sub_type_name
    ,program_name AS credit_program_name
    ,program_start_time AS credit_program_start_timestamp
    ,from_unixtime(program_start_time, 'yyyy-MM-dd HH:mm:ss') AS credit_program_start_datetime
    ,program_id AS credit_program_id
    ,effective_type as manual_credit_effective_type
    ,null as ads_revenue_push_type
    ,null as seller_investment_type
    ,cast(get_json_object(_decoded_extinfo, '$.seller_investment_amount') as bigint) / 100000.0 as seller_investment_amount
    ,ucase('${region}') as grass_region
FROM mp_paidads.shopee_ads_${region}_ultimate_shard_db__promotion_paid_ads_manual_credit_tab__reg_continuous_s0_live a
LEFT JOIN subtype
ON (
    a.subtype = subtype.id
)
WHERE  a.ctime <= UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
);

--get credit df 
CREATE or replace TEMPORARY VIEW credit AS
(
    select
    order_id
    ,order_type
    ,main_type
    ,CASE
        WHEN main_type = 2 THEN 'paid credit'
        WHEN main_type = 3 THEN 'free credit'
     ELSE NULL END AS main_type_name
    ,sub_type
    ,sub_type_name
    ,amount / 100000.0 AS ads_credit_topup_amt
    ,balance / 100000.0 AS credit_balance_amt
    ,start_timestamp AS credit_topup_expiry_start_timestamp
    ,start_datetime AS credit_topup_expiry_start_datetime
    ,end_timestamp AS credit_topup_expiry_end_timestamp
    ,end_datetime AS credit_topup_expiry_end_datetime
    ,ads_credit_modify_timestamp AS credit_modify_timestamp
    ,ads_credit_modify_datetime AS credit_modify_datetime
    ,CASE WHEN date(end_datetime) = DATE('${grass_date}') THEN 1 ELSE 0 END
     AS is_credit_topup_expired_today
    ,CASE WHEN date(end_datetime) < DATE('${grass_date}') THEN 1 ELSE 0 END
     AS is_credit_topup_expired
    ,ads_credit_extinfo
    ,effective_type
    ,ads_credit_id
    ,consumption_type
    ,a.grass_region
FROM (
    select
        order_id
        , order_type
        , user_id
        , shop_id
        , amount
        , balance
        , main_type
        , subtype as sub_type
        , start_time AS start_timestamp
        , from_unixtime(start_time, 'yyyy-MM-dd HH:mm:ss') as start_datetime
        , end_time AS end_timestamp
        , CASE
            WHEN (end_time = 0 OR end_time is NULL) THEN NULL
            ELSE from_unixtime(end_time, 'yyyy-MM-dd HH:mm:ss')
          END as end_datetime
        , ctime AS ads_credit_create_timestamp
        , from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss') as ads_credit_create_datetime
        , mtime AS ads_credit_modify_timestamp
        , from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss') as ads_credit_modify_datetime
        ,decode_extinfo(base64(extinfo)) as ads_credit_extinfo
        ,effective_type
        ,ads_credit_id
        ,consumption_type
        , upper('${region}') AS grass_region 
    FROM mp_paidads.shopee_ads_${region}_ultimate_shard_db__ads_credit_tab__reg_continuous_s0_live
    WHERE ctime <= UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
) a 
LEFT JOIN subtype
ON (
    a.sub_type = subtype.id
    AND a.grass_region = subtype.grass_region
)
);

-- get exrate df
CREATE or replace TEMPORARY VIEW exrate AS
(
    SELECT
        grass_region
        ,exchange_rate
    FROM mp_order.dim_exchange_rate__reg_s0_live
    WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
);

-- get exrate df
CREATE or replace TEMPORARY VIEW exrate_his AS
(
    SELECT
        grass_region
        ,grass_date
        ,exchange_rate as exchange_rate_his
    FROM mp_order.dim_exchange_rate__reg_s0_live
    WHERE grass_region = upper('${region}')
);

-- get credit topup
CREATE or replace TEMPORARY VIEW topup_credit AS
(
    SELECT
    topup.shop_id as shop_id
    ,topup.user_id as user_id
    ,topup.order_id as order_id
    ,topup.svs_topup_status as svs_topup_status
    ,topup.topup_create_timestamp as topup_create_timestamp
    ,topup.topup_create_datetime as topup_create_datetime
    ,case when topup.order_type = 16 or topup.pckg_id > 0 then credit.ads_credit_topup_amt else topup.topup_amt end as topup_amt
    ,case when topup.order_type = 16 or topup.pckg_id > 0 then credit.ads_credit_topup_amt / exchange_rate else (topup.topup_amt / exchange_rate) end AS topup_amt_usd
    ,topup.order_type as order_type
    ,topup.order_type_name as order_type_name
    ,topup.is_topup_today
    ,case when topup.order_type = 7 then 3
          when topup.order_type in (2,4,28) then 1
          when topup.order_type = 6 and coalesce(credit.main_type,0) = 0 then 1
          when coalesce(credit.main_type,manual.main_type,0) = 2 and coalesce(credit.credit_topup_expiry_end_timestamp,0) = 0 then 1
          when coalesce(credit.main_type,manual.main_type,0) = 2 and coalesce(credit.credit_topup_expiry_end_timestamp,0) > 0 then 2
          when coalesce(credit.main_type,manual.main_type,0) = 3 and coalesce(credit.credit_topup_expiry_end_timestamp,0) = 0 then 3
          when coalesce(credit.main_type,manual.main_type,0) = 3 and coalesce(credit.credit_topup_expiry_end_timestamp,0) > 0 then 4
    end AS credit_topup_type
    ,case when topup.order_type = 7 then 'free credit without expiry'
          when topup.order_type in (2,4,28) then 'paid credit without expiry'
          when topup.order_type = 6 and coalesce(credit.main_type,0) = 0 then 'paid credit without expiry'
          when coalesce(credit.main_type,manual.main_type,0) = 2 and coalesce(credit.credit_topup_expiry_end_timestamp,0) = 0 then 'paid credit without expiry'
          when coalesce(credit.main_type,manual.main_type,0) = 2 and coalesce(credit.credit_topup_expiry_end_timestamp,0) > 0 then 'paid credit with expiry'
          when coalesce(credit.main_type,manual.main_type,0) = 3 and coalesce(credit.credit_topup_expiry_end_timestamp,0) = 0 then 'free credit without expiry'
          when coalesce(credit.main_type,manual.main_type,0) = 3 and coalesce(credit.credit_topup_expiry_end_timestamp,0) > 0 then 'free credit with expiry'
    end AS credit_topup_type_name
    ,topup.pckg_id as pckg_id
    ,topup.pckg_original_amt as pckg_original_amt
    ,(topup.pckg_original_amt / exchange_rate) AS pckg_original_amt_usd
    ,topup.pckg_expiry_timestamp as pckg_expiry_timestamp
    ,topup.pckg_expiry_datetime as pckg_expiry_datetime
    ,topup.pckg_paid_amt as pckg_paid_amt
    ,(topup.pckg_paid_amt / exchange_rate) AS pckg_paid_amt_usd
    ,topup.voucher_id as voucher_id
    ,topup.voucher_discount_amt as voucher_discount_amt
    ,(topup.voucher_discount_amt / exchange_rate) AS voucher_discount_amt_usd
    ,topup.voucher_expiry_timestamp as voucher_expiry_timestamp
    ,topup.voucher_expiry_datetime as voucher_expiry_datetime
    ,CASE WHEN topup.pckg_id > 0 THEN 1 ELSE 0 END AS is_package_topup
    ,CASE WHEN topup.voucher_id > 0 THEN 1 ELSE 0 END AS is_voucher_topup
    ,topup.notified as notified
    ,manual.manual_credit_create_timestamp as manual_credit_create_timestamp
    ,manual.manual_credit_create_datetime as manual_credit_create_datetime
    ,manual.manual_credit_approved_timestamp as manual_credit_approved_timestamp
    ,manual.manual_credit_approved_datetime as manual_credit_approved_datetime
    ,manual.credit_reason as credit_reason
    ,manual.credit_operator as credit_operator
    ,manual.credit_program_name as credit_program_name
    ,manual.credit_program_start_timestamp as credit_program_start_timestamp
    ,manual.credit_program_start_datetime as credit_program_start_datetime
    ,manual.credit_topup_status as credit_topup_status
    ,manual.credit_program_id as credit_program_id
    ,CASE WHEN topup.order_type in (3, 10, 14) THEN manual.main_type
          WHEN topup.order_type = 6 and credit.main_type is null THEN 2
          ELSE credit.main_type
     END AS credit_topup_main_type
    ,CASE WHEN topup.order_type in (3, 10, 14) THEN manual.main_type_name
          WHEN topup.order_type = 6 and credit.main_type is null THEN 'paid credit'
          ELSE credit.main_type_name
     END AS credit_topup_main_type_name
    ,CASE WHEN topup.order_type in (3, 10, 14) THEN manual.sub_type
          ELSE credit.sub_type
     END AS credit_topup_sub_type
    ,CASE WHEN topup.order_type in (3, 10, 14) THEN manual.sub_type_name
          ELSE credit.sub_type_name
     END AS credit_topup_sub_type_name
    ,credit.credit_balance_amt as credit_balance_amt
    ,credit.credit_balance_amt / exchange_rate AS credit_balance_amt_usd
    ,credit.credit_topup_expiry_start_timestamp as credit_topup_expiry_start_timestamp
    ,credit.credit_topup_expiry_start_datetime as credit_topup_expiry_start_datetime
    ,credit.credit_topup_expiry_end_timestamp as credit_topup_expiry_end_timestamp
    ,credit.credit_topup_expiry_end_datetime as credit_topup_expiry_end_datetime
    ,credit.credit_modify_timestamp as credit_modify_timestamp
    ,credit.credit_modify_datetime as credit_modify_datetime
    ,credit.is_credit_topup_expired_today as is_credit_topup_expired_today
    ,credit.is_credit_topup_expired as is_credit_topup_expired
    ,case when topup.order_type = 16 then credit.ads_credit_topup_amt / exchange_rate_his else (topup.topup_amt / exchange_rate_his) end AS topup_amt_usd_his
    ,(topup.pckg_original_amt / exchange_rate_his) AS pckg_original_amt_usd_his
    ,(topup.pckg_paid_amt / exchange_rate_his) AS pckg_paid_amt_usd_his
    ,(topup.voucher_discount_amt / exchange_rate_his) AS voucher_discount_amt_usd_his
    ,credit.credit_balance_amt / exchange_rate_his AS credit_balance_amt_usd_his
    ,svs_entity_type
    ,svs_entity_id
    ,ads_credit_extinfo
    ,effective_type
    ,manual_credit_effective_type
    ,ads_credit_id
    ,ads_revenue_push_type
    ,seller_investment_type
    ,seller_investment_amount
    ,ads_package_id
    ,consumption_type
    ,topup.grass_region as grass_region
    ,DATE('${grass_date}')  AS grass_date
FROM topup
LEFT JOIN manual
ON (topup.order_id = manual.topup_order_id
    AND topup.order_type = manual.credit_order_type
    AND topup.grass_region = manual.grass_region
)
LEFT JOIN credit
ON (topup.order_id = credit.order_id
    AND topup.order_type = credit.order_type
    AND topup.grass_region = credit.grass_region
)
LEFT JOIN  exrate
ON topup.grass_region = exrate.grass_region
left JOIN  exrate_his
on topup.grass_region = exrate_his.grass_region
and substring(topup.topup_create_datetime,1,11) = exrate_his.grass_date
);

CREATE or replace TEMPORARY VIEW manual_topup_action AS
select * from
(select 
    credit_id
    ,operator
    ,action_type
    ,ROW_NUMBER() over(partition by credit_id order by ctime desc) as rank
FROM mp_paidads.shopee_ads_${region}_ultimate_shard_db__ads_manual_topup_action_history_tab__reg_continuous_s0_live a
WHERE  a.ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))
)a
where rank = 1
;



INSERT OVERWRITE TABLE dwd_advertiser_credit_topup_df__reg_s0_live partition(tz_type='local', grass_region, grass_date)
select  
        shop_id
        ,user_id
        ,order_id
        ,svs_topup_status
        ,topup_create_timestamp
        ,topup_create_datetime
        ,topup_amt_split as topup_amt
        ,topup_amt_usd_split as topup_amt_usd
        ,order_type
        ,order_type_name
        ,is_topup_today
        ,credit_topup_type_split as credit_topup_type
        ,credit_topup_type_name_split as credit_topup_type_name
        ,pckg_id
        ,pckg_original_amt
        ,pckg_original_amt_usd
        ,pckg_expiry_timestamp
        ,pckg_expiry_datetime
        ,pckg_paid_amt
        ,pckg_paid_amt_usd
        ,voucher_id
        ,voucher_discount_amt
        ,voucher_discount_amt_usd
        ,voucher_expiry_timestamp
        ,voucher_expiry_datetime
        ,is_package_topup
        ,is_voucher_topup
        ,manual_credit_create_timestamp
        ,manual_credit_create_datetime
        ,manual_credit_approved_timestamp
        ,manual_credit_approved_datetime
        ,credit_reason
        ,credit_operator
        ,credit_program_name
        ,credit_program_start_timestamp
        ,credit_program_start_datetime
        ,credit_topup_status
        ,credit_topup_main_type_split as credit_topup_main_type 
        ,credit_topup_main_type_name_split as credit_topup_main_type_name
        ,credit_topup_sub_type
        ,credit_topup_sub_type_name
        ,credit_balance_amt_split as credit_balance_amt
        ,credit_balance_amt_usd_split as credit_balance_amt_usd
        ,credit_topup_expiry_start_timestamp
        ,credit_topup_expiry_start_datetime
        ,credit_topup_expiry_end_timestamp
        ,credit_topup_expiry_end_datetime
        ,credit_modify_timestamp
        ,credit_modify_datetime
        ,is_credit_topup_expired_today
        ,is_credit_topup_expired
        ,topup_amt_usd_his_split as topup_amt_usd_his
        ,pckg_original_amt_usd_his
        ,pckg_paid_amt_usd_his
        ,voucher_discount_amt_usd_his
        ,credit_balance_amt_usd_his_split as credit_balance_amt_usd_his
        ,notified
        ,credit_program_id
        ,svs_entity_type
        ,svs_entity_id
        ,ads_credit_extinfo
        ,effective_type
        ,manual_credit_effective_type
        ,ads_credit_id
        ,ads_revenue_push_type
        ,seller_investment_type
        ,seller_investment_amount
        ,case when order_type in (3,10,14) then operator end as operator
        ,case when order_type in (3,10,14) then action_type end as action_type
        ,ads_package_id
        ,consumption_type
        ,grass_region
        ,grass_date
from
(
    
    select 
        *
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0 then pckg_paid_amt 
         when is_voucher_topup = 1 and voucher_discount_amt > 0 then topup_amt - voucher_discount_amt 
         else topup_amt end as topup_amt_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0 then pckg_paid_amt_usd 
         when is_voucher_topup = 1 and voucher_discount_amt > 0 then topup_amt_usd - voucher_discount_amt_usd 
         else topup_amt_usd end as topup_amt_usd_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0 then pckg_paid_amt_usd_his 
         when is_voucher_topup = 1 and voucher_discount_amt > 0 then topup_amt_usd_his - voucher_discount_amt_usd_his 
         else topup_amt_usd_his end as topup_amt_usd_his_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 then 2 
         when is_voucher_topup = 1 then 1 
         else credit_topup_type end as credit_topup_type_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 then 'paid credit with expiry' 
         when is_voucher_topup = 1 then 'paid credit without expiry' 
         else credit_topup_type_name end as credit_topup_type_name_split
        ,case when (credit_topup_main_type = 5 and is_package_topup = 1) or is_voucher_topup = 1 then 2 
         else credit_topup_main_type end as credit_topup_main_type_split
        ,case when (credit_topup_main_type = 5 and is_package_topup = 1) or is_voucher_topup = 1 then 'paid credit' 
         else credit_topup_main_type_name end as credit_topup_main_type_name_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0 then least(credit_balance_amt, pckg_paid_amt) 
         when is_voucher_topup = 1 and voucher_discount_amt > 0 then null
         else credit_balance_amt end as credit_balance_amt_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0 then least(credit_balance_amt_usd, pckg_paid_amt_usd) 
         when is_voucher_topup = 1 and voucher_discount_amt > 0 then null
         else credit_balance_amt_usd end as credit_balance_amt_usd_split
        ,case when credit_topup_main_type = 5 and is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0 then least(credit_balance_amt_usd_his, pckg_paid_amt_usd_his) 
         when is_voucher_topup = 1 and voucher_discount_amt > 0 then null
         else credit_balance_amt_usd_his end as credit_balance_amt_usd_his_split
    from 
        topup_credit

    union all 

    select 
        *
        ,case when is_package_topup = 1 then pckg_original_amt - pckg_paid_amt 
         when is_voucher_topup = 1 then voucher_discount_amt 
         else topup_amt end as topup_amt_split
        ,case when is_package_topup = 1 then pckg_original_amt_usd - pckg_paid_amt_usd 
         when is_voucher_topup = 1 then voucher_discount_amt_usd 
         else topup_amt_usd end as topup_amt_usd_split
        ,case when is_package_topup = 1 then pckg_original_amt_usd_his - pckg_paid_amt_usd_his 
         when is_voucher_topup = 1 then voucher_discount_amt_usd_his 
         else topup_amt_usd_his end as topup_amt_usd_his_split
        ,case when is_package_topup = 1 or (is_voucher_topup = 1 and credit_topup_expiry_end_timestamp > 0) then 4 
         when is_voucher_topup = 1 and not (credit_topup_expiry_end_timestamp > 0) then 3 
         else credit_topup_type end as credit_topup_type_split
        ,case when is_package_topup = 1 or (is_voucher_topup = 1 and credit_topup_expiry_end_timestamp > 0) then 'free credit with expiry' 
         when is_voucher_topup = 1 and not (credit_topup_expiry_end_timestamp > 0) then 'free credit without expiry' 
         else credit_topup_type_name end as credit_topup_type_name_split
        ,3  as credit_topup_main_type_split
        ,'free credit' as credit_topup_main_type_name_split
        ,case when is_package_topup = 1 then greatest(credit_balance_amt - pckg_paid_amt, 0) 
         else credit_balance_amt end as credit_balance_amt_split
        ,case when is_package_topup = 1 then greatest(credit_balance_amt_usd - pckg_paid_amt_usd, 0) 
         else credit_balance_amt_usd end as credit_balance_amt_usd_split
        ,case when is_package_topup = 1 then greatest(credit_balance_amt_usd_his - pckg_paid_amt_usd_his, 0) 
         else credit_balance_amt_usd_his end as credit_balance_amt_usd_his_split
    from 
        topup_credit
    where   (credit_topup_main_type = 5 and
        is_package_topup = 1 and pckg_original_amt - pckg_paid_amt > 0)

        OR (is_voucher_topup = 1 and voucher_discount_amt > 0)
        
)t
left join manual_topup_action b 
on t.order_id = b.credit_id;

alter table dwd_advertiser_credit_topup_df__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");