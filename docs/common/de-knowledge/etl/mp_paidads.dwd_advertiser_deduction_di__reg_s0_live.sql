-- task_code: data_paidadsmart.studio_11243725  asset_id: 11243725
set time zone '${timezone}';

create or replace temporary view cpc_detail as
select deduct_unique_id,ads_id,user_id
    ,shop_id,placement,item_id
    ,order_id
    ,order_type
    ,ads_credit_id
    ,deduction_amt / 100000.0 as deduction_amt
    ,credit_amt_before_deduct
    ,credit_amt_after_deduct
    ,effective_type
    ,consumption_type
    ,credit_topup_type
    ,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword

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
    ,get_json_object(decoded_extinfo, '$.requestId') as request_id

    ,cast(get_json_object(decoded_extinfo, '$.deductionInfo.deductionPrice') as bigint) / 100000.0 as deduction_price
    ,cast(get_json_object(decoded_extinfo, '$.voucherDeductionPrice') as bigint) / 100000.0 as voucher_deduction_price
    ,cast(get_json_object(decoded_extinfo, '$.trafficSource') as int) as traffic_source
    ,cast(get_json_object(decoded_extinfo, '$.deductTimestamp') as bigint) as deduct_timestamp
    ,cast(get_json_object(decoded_extinfo, '$.clickTimestamp') as bigint) as click_timestamp
    ,cast(get_json_object(decoded_extinfo, '$.cpsTotalExpense') as bigint) / 100000.0  as cps_total_expenditure_amt
    ,cast(get_json_object(decoded_extinfo, '$.cpsAvailableBudget') as bigint) / 100000.0  as cps_available_budget
    ,cast(get_json_object(decoded_extinfo, '$.validBalance') as bigint) / 100000.0  as valid_balance_amt
    ,cast(get_json_object(decoded_extinfo, '$.availableBalance') as bigint) / 100000.0  as available_balance_amt

    ,cast(get_json_object(decoded_extinfo,'$.entrance') as int) as entrance
    ,cast(get_json_object(decoded_extinfo,'$.pricingType') as int) as pricing_type
    ,cast(get_json_object(decoded_extinfo,'$.campaignid') as bigint) as campaign_id
    ,cast(get_json_object(decoded_extinfo, '$.subEntrance') as int) as sub_entrance
from (
select deduct_unique_id,ads_id,user_id
    ,shop_id,placement,item_id
    ,cast(ads_credit.orderId as bigint) as order_id
    ,cast(ads_credit.orderType as bigint) as order_type
    ,cast(ads_credit.adsCreditId as bigint) as ads_credit_id
    ,cast(ads_credit.balanceBefore as bigint)- cast(ads_credit.balanceAfter as bigint) as deduction_amt
    ,cast(ads_credit.balanceBefore as bigint)/ 100000.0  as credit_amt_before_deduct
    ,cast(ads_credit.balanceAfter  as bigint)/ 100000.0   as credit_amt_after_deduct
    ,cast(ads_credit.effectiveType as int)   as effective_type
    ,cast(ads_credit.consumptionType as int) as consumption_type

    ,case when ads_credit.mainType=2 and ads_credit.withExpiry=false then 1
        when ads_credit.mainType in (2,5) and ads_credit.withExpiry=true then 2
        when ads_credit.mainType in (3,5) and ads_credit.withExpiry=false then 3
        when ads_credit.mainType=3 and ads_credit.withExpiry=true then 4 else null end as credit_topup_type
    ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
    ,'${upper_region}' as grass_region
from (
    select  deduct_unique_id,ads_id,user_id,ads_credits
        ,shop_id,placement,item_id,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
    from (
        select deduct_unique_id,adsid as ads_id,userid as user_id
            ,shopid as shop_id
            ,placement
            ,itemid as item_id
            ,FROM_JSON(get_json_object(decoded_extinfo, '$.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string,consumptionType:int>>') AS ads_credits
            ,decoded_extinfo,id,timestamp,operation,acc_before_balance/ pow(10,5) as acc_before_balance ,acc_after_balance/ pow(10,5) as acc_after_balance,keyword
        from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
        where  grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local' and operation in (1,15)
    )
)translog_tab
lateral view explode(ads_credits) as ads_credit
union all
select deduct_unique_id,adsid as ads_id,userid as user_id
    ,shopid as shop_id,placement,itemid as item_id
    ,null as order_id
    ,null as order_type
    ,null as ads_credit_id
    ,price as deduction_amt
    ,null as credit_amt_before_deduct
    ,null as credit_amt_after_deduct
    ,null as effective_type
    ,null as consumption_type
    
    ,1 as credit_topup_type
    ,decoded_extinfo,id,timestamp,operation,acc_before_balance/ pow(10,5) as acc_before_balance ,acc_after_balance/ pow(10,5) as acc_after_balance,keyword
    ,'${upper_region}' as grass_region
from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
where   grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local' and operation in (1,15)
    and price >0
) base 
;
 
 
create or replace temporary view cpm_detail as
select deduct_unique_id
        ,ads_id
        ,user_id
        ,shop_id,placement,item_id,entrance
        ,order_id
        ,order_type
        ,ads_credit_id
        ,deduction_amt / 100000.0 as deduction_amt
        ,credit_amt_before_deduct
        ,credit_amt_after_deduct
        ,effective_type
        ,consumption_type
        ,credit_topup_type
        ,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword

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
        ,get_json_object(decoded_extinfo, '$.requestId') as request_id

        ,cast(get_json_object(decoded_extinfo, '$.deductionInfo.deductionPrice') as bigint) / 100000.0 as deduction_price
        ,cast(get_json_object(decoded_extinfo, '$.voucherDeductionPrice') as bigint) / 100000.0 as voucher_deduction_price
        ,cast(get_json_object(decoded_extinfo, '$.trafficSource') as int) as traffic_source
        ,cast(get_json_object(decoded_extinfo, '$.deductTimestamp') as bigint) as deduct_timestamp
        ,cast(get_json_object(decoded_extinfo, '$.clickTimestamp') as bigint) as click_timestamp
        ,cast(get_json_object(decoded_extinfo, '$.cpsTotalExpense') as bigint) / 100000.0  as cps_total_expenditure_amt
        ,cast(get_json_object(decoded_extinfo, '$.cpsAvailableBudget') as bigint) / 100000.0  as cps_available_budget
        ,cast(get_json_object(decoded_extinfo, '$.validBalance') as bigint) / 100000.0  as valid_balance_amt
        ,cast(get_json_object(decoded_extinfo, '$.availableBalance') as bigint) / 100000.0  as available_balance_amt

        ,cast(get_json_object(decoded_extinfo,'$.pricingType') as int) as pricing_type
        ,cast(get_json_object(decoded_extinfo,'$.campaignid') as bigint) as campaign_id
        ,cast(get_json_object(decoded_extinfo, '$.subEntrance') as int) as sub_entrance
from (
select translog_tab.deduct_unique_id
        ,translog_tab.adsid as ads_id
        ,translog_event.user_id
        ,translog_event.entrance as entrance
        ,shop_id,placement,item_id
        ,order_id
        ,order_type
        ,ads_credit_id
        ,credit_amt_before_deduct
        ,credit_amt_after_deduct
        ,effective_type
        ,consumption_type
        ,round((adjusted_cost * 1.000000 / total_cost)*deduction_amt,5) as deduction_amt
        ,credit_topup_type
        ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
        ,'${upper_region}' as grass_region
from (
    select  deduct_unique_id,adsid,price,total_cost
        ,cast(ads_credit.orderId as bigint) as order_id
        ,cast(ads_credit.orderType as bigint) as order_type
        ,cast(ads_credit.adsCreditId as bigint) as ads_credit_id
        ,cast(ads_credit.balanceBefore as bigint)- cast(ads_credit.balanceAfter as bigint) as deduction_amt
        ,cast(ads_credit.balanceBefore as bigint)/ 100000.0  as credit_amt_before_deduct
        ,cast(ads_credit.balanceAfter  as bigint)/ 100000.0   as credit_amt_after_deduct
        ,cast(ads_credit.effectiveType as int)   as effective_type
        ,cast(ads_credit.consumptionType as int) as consumption_type

        ,case when ads_credit.mainType=2 and ads_credit.withExpiry=false then 1
            when ads_credit.mainType=2 and ads_credit.withExpiry=true then 2
            when ads_credit.mainType=3 and ads_credit.withExpiry=false then 3
            when ads_credit.mainType=3 and ads_credit.withExpiry=true then 4 else null end as credit_topup_type
        ,shop_id,placement,item_id
        ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
    from (
        select deduct_unique_id,adsid,price,total_cost
            ,case when size(ads_credits)>0 then ads_credits when size(frozen_ads_credits)>0 then frozen_ads_credits else null end as ads_credits
            ,shop_id,placement,item_id
            ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
        from (
            select deduct_unique_id,adsid,price,dai_after_balance-dai_before_balance as total_cost
                ,FROM_JSON(get_json_object(decoded_extinfo, '$.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string,consumptionType:int>>') AS ads_credits
                ,FROM_JSON(get_json_object(decoded_extinfo, '$.frozen.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string,consumptionType:int>>') AS frozen_ads_credits
                ,shopid as shop_id
                ,placement
                ,itemid as item_id
                ,decoded_extinfo,id,timestamp,operation,acc_before_balance/ pow(10,5) as acc_before_balance ,acc_after_balance/ pow(10,5) as acc_after_balance,keyword
            from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
            where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local' and operation = 11
        )
    )lateral view EXPLODE(ads_credits) as  ads_credit
)translog_tab
left join (
    select deduct_unique_id,adsid,imp_cost_detail.user_id,imp_cost_detail.adjusted_cost,cpm_detail.entrance as entrance
    from (
        select distinct translog.deduct_unique_id as deduct_unique_id
            ,translog.adsid as adsid
            ,imp_cost_details
            ,cpm_event_details_str
        from mp_paidads.ods_log_translog_event_hi__reg_s0_live
        where grass_region = '${upper_region}'
        and   grass_date >= DATE('${grass_date}') and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
        and   translog.timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
        and   translog.timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
        and translog.operation =11
    )lateral view POSEXPLODE(from_json(cpm_event_details_str, 'array<struct<user_id:bigint, entrance:int>>')) cpm_details pos1,  cpm_detail
    lateral view POSEXPLODE(imp_cost_details) imp_cost_details pos2,  imp_cost_detail
    where pos1 = pos2
)translog_event on translog_tab.deduct_unique_id=translog_event.deduct_unique_id and translog_tab.adsid=translog_event.adsid
union all
select translog_tab.deduct_unique_id
        ,translog_tab.adsid as ads_id
        ,translog_event.user_id
        ,translog_event.entrance as entrance
        ,shop_id,placement,item_id
        ,null as order_id
        ,null as order_type
        ,null as ads_credit_id
        ,null as credit_amt_before_deduct
        ,null as credit_amt_after_deduct
        ,null as effective_type
        ,null as consumption_type
        
        ,round((price)  * (adjusted_cost * 1.000000 / total_cost), 5) as deduction_amt
        ,1 as credit_topup_type
        ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
        ,'${upper_region}' as grass_region
from(
    select deduct_unique_id,adsid,price,dai_after_balance-dai_before_balance as total_cost
        ,shopid as shop_id
        ,placement
        ,itemid as item_id
        ,decoded_extinfo,id,timestamp,operation,acc_before_balance/ pow(10,5) as acc_before_balance ,acc_after_balance/ pow(10,5) as acc_after_balance,keyword
    from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
    where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local' and operation = 11
        and price >0
)translog_tab
left join (
    select deduct_unique_id,adsid,imp_cost_detail.user_id,imp_cost_detail.adjusted_cost,cpm_detail.entrance as entrance
    from (
        select distinct translog.deduct_unique_id as deduct_unique_id
            ,translog.adsid as adsid
            ,imp_cost_details
            ,cpm_event_details_str
        from mp_paidads.ods_log_translog_event_hi__reg_s0_live
        where grass_region = '${upper_region}'
        and   grass_date >= DATE('${grass_date}') and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
        and   translog.timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
        and   translog.timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
        and translog.operation =11
    )lateral view POSEXPLODE(from_json(cpm_event_details_str, 'array<struct<user_id:bigint, entrance:int>>')) cpm_details pos1,  cpm_detail
    lateral view POSEXPLODE(imp_cost_details) imp_cost_details pos2,  imp_cost_detail
    where pos1 = pos2
)translog_event on translog_tab.deduct_unique_id=translog_event.deduct_unique_id and translog_tab.adsid=translog_event.adsid
) base 
where deduction_amt>0 and deduction_amt is not null
;

create or replace temporary view cpm_fix as
select deduct_unique_id
    ,ads_id
    ,null as user_id
    ,shop_id,placement,item_id,entrance
    ,order_id
    ,order_type
    ,ads_credit_id
    ,deduction_amt
    ,credit_amt_before_deduct
    ,credit_amt_after_deduct
    ,effective_type
    ,consumption_type
    ,credit_topup_type
    ,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword

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
    ,get_json_object(decoded_extinfo, '$.requestId') as request_id

    ,cast(get_json_object(decoded_extinfo, '$.deductionInfo.deductionPrice') as bigint) / 100000.0 as deduction_price
    ,cast(get_json_object(decoded_extinfo, '$.voucherDeductionPrice') as bigint) / 100000.0 as voucher_deduction_price
    ,cast(get_json_object(decoded_extinfo, '$.trafficSource') as int) as traffic_source
    ,cast(get_json_object(decoded_extinfo, '$.deductTimestamp') as bigint) as deduct_timestamp
    ,cast(get_json_object(decoded_extinfo, '$.clickTimestamp') as bigint) as click_timestamp
    ,cast(get_json_object(decoded_extinfo, '$.cpsTotalExpense') as bigint) / 100000.0  as cps_total_expenditure_amt
    ,cast(get_json_object(decoded_extinfo, '$.cpsAvailableBudget') as bigint) / 100000.0  as cps_available_budget
    ,cast(get_json_object(decoded_extinfo, '$.validBalance') as bigint) / 100000.0  as valid_balance_amt
    ,cast(get_json_object(decoded_extinfo, '$.availableBalance') as bigint) / 100000.0  as available_balance_amt

    ,cast(get_json_object(decoded_extinfo,'$.pricingType') as int) as pricing_type
    ,cast(get_json_object(decoded_extinfo,'$.campaignid') as bigint) as campaign_id
    ,cast(get_json_object(decoded_extinfo, '$.subEntrance') as int) as sub_entrance
from (
select translog_tab.deduct_unique_id
    ,translog_tab.shop_id
    ,translog_tab.ads_id
    ,null as entrance
    ,translog_tab.placement
    ,translog_tab.order_id
    ,translog_tab.order_type
    ,translog_tab.ads_credit_id
    ,translog_tab.credit_amt_before_deduct
    ,translog_tab.credit_amt_after_deduct
    ,translog_tab.effective_type
    ,translog_tab.consumption_type
    ,translog_tab.credit_topup_type
    ,translog_tab.item_id
    ,translog_tab.deduction_amt / 100000.0 - coalesce(translog_event.deduction_amt,0.0) as deduction_amt
    ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
from (
    select  
        deduct_unique_id,adsid as ads_id
        ,cast(ads_credit.orderId as bigint) as order_id
        ,cast(ads_credit.orderType as bigint) as order_type
        ,cast(ads_credit.adsCreditId as bigint) as ads_credit_id
        ,cast(ads_credit.balanceBefore as bigint)- cast(ads_credit.balanceAfter as bigint) as deduction_amt
        ,cast(ads_credit.balanceBefore as bigint)/ 100000.0  as credit_amt_before_deduct
        ,cast(ads_credit.balanceAfter  as bigint)/ 100000.0   as credit_amt_after_deduct
        ,cast(ads_credit.effectiveType as int)   as effective_type
        ,cast(ads_credit.consumptionType as int) as consumption_type
        ,case when ads_credit.mainType=2 and ads_credit.withExpiry=true then 2
            when ads_credit.mainType=3 and ads_credit.withExpiry=false then 3
            when ads_credit.mainType=3 and ads_credit.withExpiry=true then 4 else null end as credit_topup_type
        ,shop_id,placement,item_id,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
    from (
        select deduct_unique_id,adsid,price,total_cost
            ,case when size(ads_credits)>0 then ads_credits when size(frozen_ads_credits)>0 then frozen_ads_credits else null end as ads_credits
            ,shop_id,placement,item_id,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
        from (
            select deduct_unique_id,adsid,price,dai_after_balance-dai_before_balance as total_cost
                ,FROM_JSON(get_json_object(decoded_extinfo, '$.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string,consumptionType:int>>') AS ads_credits
                ,FROM_JSON(get_json_object(decoded_extinfo, '$.frozen.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string,consumptionType:int>>') AS frozen_ads_credits
                ,shopid as shop_id
                ,placement
                ,itemid as item_id
                ,decoded_extinfo,id,timestamp,operation,acc_before_balance/ pow(10,5) as acc_before_balance ,acc_after_balance/ pow(10,5) as acc_after_balance,keyword
            from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
            where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local' and operation = 11
        )
    )lateral view EXPLODE(ads_credits) as  ads_credit
    where not (ads_credit.mainType=2 and ads_credit.withExpiry=false)
) translog_tab 
left join (
    select deduct_unique_id,ads_id,order_id,order_type,ads_credit_id,sum(deduction_amt) as deduction_amt
    from cpm_detail
    where credit_topup_type not in (1)
    group by deduct_unique_id,ads_id,order_id,order_type,ads_credit_id
)translog_event on translog_tab.deduct_unique_id = translog_event.deduct_unique_id and translog_tab.ads_id = translog_event.ads_id and translog_tab.order_id=translog_event.order_id and translog_tab.order_type=translog_event.order_type and translog_tab.ads_credit_id=translog_event.ads_credit_id
where translog_tab.credit_topup_type is not null and (translog_tab.deduction_amt / 100000.0 - coalesce(translog_event.deduction_amt,0.0) >= 0.00001 or translog_event.deduction_amt is null)
union all 
select translog_tab.deduct_unique_id
    ,translog_tab.shop_id
    ,translog_tab.ads_id
    ,null as entrance
    ,translog_tab.placement
    ,null as order_id
    ,null as order_type
    ,null as ads_credit_id
    ,null as credit_amt_before_deduct
    ,null as credit_amt_after_deduct
    ,null as effective_type
    ,null as consumption_type
    ,1 as credit_topup_type
    ,translog_tab.item_id
    ,translog_tab.entry_1 / 100000.0 - coalesce(translog_event.deduction_amt,0.0) as deduction_amt
    ,decoded_extinfo,id,timestamp,operation,acc_before_balance,acc_after_balance,keyword
from (
    select deduct_unique_id,adsid as ads_id
        ,shopid as shop_id
        ,placement
        ,itemid as item_id
        ,aggregate(filter(FROM_JSON(get_json_object(decoded_extinfo, '$.paidFreeExpirySummary.entries'), 'array<struct<type:BIGINT,amount:string>>'), x-> x.type = 1),0L, (acc, x) -> acc + cast(x.amount as bigint)) as entry_1
        ,decoded_extinfo,id,timestamp,operation,acc_before_balance / 100000.0 as acc_before_balance ,acc_after_balance/ 100000.0 as acc_after_balance,keyword
    from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
    where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local' and operation = 11
)translog_tab
left join (
    select  deduct_unique_id,ads_id,sum(deduction_amt) as deduction_amt
    from cpm_detail
    where credit_topup_type =1
    group by deduct_unique_id,ads_id
)translog_event on translog_tab.deduct_unique_id=translog_event.deduct_unique_id and translog_tab.ads_id=translog_event.ads_id
where translog_tab.entry_1 >0 and (translog_tab.entry_1 / 100000.0 - coalesce(translog_event.deduction_amt,0.0) >= 0.00001 or translog_event.deduction_amt is null)
)base
where deduction_amt>0 and deduction_amt is not null
;


create or replace temporary view deduction_di as
select id
    ,shop_id
    ,user_id
    ,ads_id
    ,campaign_id
    ,placement
    ,item_id
    ,deduction_amt
    ,timestamp
    ,acc_before_balance
    ,acc_after_balance
    ,order_id as topup_order_id
    ,credit_amt_before_deduct
    ,credit_amt_after_deduct
    ,credit_topup_type

    ,match_type
    ,recall_type
    ,expected_price_deduction
    ,user_query
    ,sort_type
    ,pdp_item_id
    ,pdp_shop_id
    ,pctr
    ,bid_price
    ,second_ads_ecpm
    ,second_ads_id
    ,ab_sign
    ,keyword

    ,order_type as credit_order_type
    ,entrance
    ,pricing_type
    ,sub_entrance
    ,request_id
    ,operation
    ,effective_type
    ,ads_credit_id
    ,deduct_unique_id
    ,deduction_price
    ,voucher_deduction_price
    ,traffic_source
    ,deduct_timestamp
    ,click_timestamp
    ,cps_total_expenditure_amt
    ,cps_available_budget
    ,valid_balance_amt
    ,available_balance_amt
    ,consumption_type
    ,'${upper_region}' as grass_region
from cpc_detail
union all
select id
    ,shop_id
    ,user_id
    ,ads_id
    ,campaign_id
    ,placement
    ,item_id
    ,deduction_amt
    ,timestamp
    ,acc_before_balance
    ,acc_after_balance
    ,order_id as topup_order_id
    ,credit_amt_before_deduct
    ,credit_amt_after_deduct
    ,credit_topup_type

    ,match_type
    ,recall_type
    ,expected_price_deduction
    ,user_query
    ,sort_type
    ,pdp_item_id
    ,pdp_shop_id
    ,pctr
    ,bid_price
    ,second_ads_ecpm
    ,second_ads_id
    ,ab_sign
    ,keyword

    ,order_type as credit_order_type
    ,entrance
    ,pricing_type
    ,sub_entrance
    ,request_id
    ,operation
    ,effective_type
    ,ads_credit_id
    ,deduct_unique_id
    ,deduction_price
    ,voucher_deduction_price
    ,traffic_source
    ,deduct_timestamp
    ,click_timestamp
    ,cps_total_expenditure_amt
    ,cps_available_budget
    ,valid_balance_amt
    ,available_balance_amt
    ,consumption_type
    ,'${upper_region}' as grass_region
from cpm_detail
union all 
select id
    ,shop_id
    ,user_id
    ,ads_id
    ,campaign_id
    ,placement
    ,item_id
    ,deduction_amt
    ,timestamp
    ,acc_before_balance
    ,acc_after_balance
    ,order_id as topup_order_id
    ,credit_amt_before_deduct
    ,credit_amt_after_deduct
    ,credit_topup_type

    ,match_type
    ,recall_type
    ,expected_price_deduction
    ,user_query
    ,sort_type
    ,pdp_item_id
    ,pdp_shop_id
    ,pctr
    ,bid_price
    ,second_ads_ecpm
    ,second_ads_id
    ,ab_sign
    ,keyword

    ,order_type as credit_order_type
    ,entrance
    ,pricing_type
    ,sub_entrance
    ,request_id
    ,operation
    ,effective_type
    ,ads_credit_id
    ,deduct_unique_id
    ,deduction_price
    ,voucher_deduction_price
    ,traffic_source
    ,deduct_timestamp
    ,click_timestamp
    ,cps_total_expenditure_amt
    ,cps_available_budget
    ,valid_balance_amt
    ,available_balance_amt
    ,consumption_type
    ,'${upper_region}' as grass_region
from cpm_fix
;

insert overwrite table dwd_advertiser_deduction_di__reg_s0_live partition (tz_type = 'local', grass_region='${upper_region}', grass_date='${grass_date}')
select  deduction_di.id
    ,deduction_di.shop_id
    ,deduction_di.user_id
    ,deduction_di.ads_id
    ,deduction_di.campaign_id
    ,deduction_di.placement
    ,advertise.ads_type
    ,advertise.ads_status
    ,deduction_di.keyword
    ,deduction_di.item_id
    ,deduction_di.deduction_amt
    ,deduction_di.deduction_amt / exrate.exchange_rate as deduction_amt_usd
    ,deduction_di.timestamp as event_timestamp
    ,from_unixtime(deduction_di.timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
    ,deduction_di.acc_before_balance
    ,deduction_di.acc_after_balance

    ,deduction_di.topup_order_id
    ,deduction_di.credit_amt_before_deduct
    ,deduction_di.credit_amt_after_deduct
    ,deduction_di.credit_topup_type
    ,if(deduction_di.credit_topup_type =1,'paid credit without expiry',credit_tab.credit_topup_type_name) as credit_topup_type_name

    ,credit_tab.program_name
    ,credit_tab.program_start_timestamp
    ,credit_tab.original_topup_credit_amt
    ,credit_tab.topup_expiry_start_timestamp
    ,credit_tab.topup_expiry_end_timestamp
    ,credit_tab.topup_expired_today
    ,credit_tab.sub_type

    ,deduction_di.match_type
    ,deduction_di.recall_type
    ,deduction_di.expected_price_deduction
    ,deduction_di.user_query
    ,deduction_di.sort_type
    ,deduction_di.pdp_item_id
    ,deduction_di.pdp_shop_id
    ,deduction_di.pctr
    ,deduction_di.bid_price
    ,deduction_di.second_ads_ecpm
    ,deduction_di.second_ads_id
    ,deduction_di.ab_sign

    ,credit_tab.credit_order_type
    ,credit_tab.credit_order_type_name
    ,credit_tab.topup_create_timestamp
    ,deduction_di.entrance
    ,deduction_di.pricing_type
    ,deduction_di.sub_entrance

    ,sub_type_name as credit_topup_sub_type_name
    ,deduction_di.request_id
    ,deduction_di.operation
    ,deduction_di.effective_type
    ,deduction_di.ads_credit_id
    ,deduction_di.deduct_unique_id
    ,credit_tab.credit_reason
    ,deduction_di.deduction_price
    ,deduction_di.voucher_deduction_price
    ,advertiser.seller_type_1p
    ,advertiser.seller_type
    ,deduction_di.deduction_price / exrate.exchange_rate as deduction_price_usd
    ,deduction_di.voucher_deduction_price / exrate.exchange_rate as voucher_deduction_price_usd

    ,deduction_di.traffic_source
    ,deduction_di.deduct_timestamp
    ,deduction_di.click_timestamp
    ,credit_tab.is_package_topup
    ,credit_tab.is_voucher_topup
    ,credit_tab.credit_program_id
    ,credit_tab.credit_operator
    ,credit_tab.voucher_id
    ,deduction_di.cps_total_expenditure_amt
    ,deduction_di.cps_available_budget
    ,deduction_di.valid_balance_amt
    ,deduction_di.available_balance_amt
    ,deduction_di.consumption_type
from deduction_di
left join (
    select shop_id,seller_type_1p,seller_type
    from mp_paidads.dim_advertiser__reg_s0_live
    where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local'
) advertiser on deduction_di.shop_id = advertiser.shop_id
LEFT JOIN (
    SELECT ads_id,campaign_id,ads_status,placement,ads_type,item_id,seller_id AS user_id,pricing_type
    FROM mp_paidads.dim_advertise__reg_s0_live
    WHERE grass_region = '${upper_region}' AND grass_date = DATE('${grass_date}')
) advertise ON deduction_di.ads_id = advertise.ads_id AND deduction_di.placement = advertise.placement
left join (
    select  grass_region
        ,order_id
        ,order_type as credit_order_type
        ,ads_credit_id
        ,credit_topup_type
        ,credit_topup_type_name
        ,credit_program_name as program_name
        ,credit_program_start_timestamp as program_start_timestamp
        
        ,credit_topup_expiry_start_timestamp as topup_expiry_start_timestamp
        ,credit_topup_expiry_end_timestamp as topup_expiry_end_timestamp
        ,credit_topup_sub_type as sub_type
        ,credit_topup_sub_type_name as sub_type_name
        ,is_credit_topup_expired_today as topup_expired_today
        
        ,order_type_name as credit_order_type_name
        ,topup_create_timestamp
        ,credit_reason
        ,is_package_topup
        ,is_voucher_topup
        ,credit_program_id
        ,credit_operator
        ,voucher_id
        ,max(topup_amt) as original_topup_credit_amt
    from    mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
    where   grass_region = '${upper_region}' and tz_type = 'local' and grass_date = date('${grass_date}')
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21
)credit_tab on deduction_di.topup_order_id = credit_tab.order_id
        and deduction_di.credit_order_type = credit_tab.credit_order_type
        and deduction_di.grass_region = credit_tab.grass_region
        and deduction_di.credit_topup_type = credit_tab.credit_topup_type
        and deduction_di.ads_credit_id <=> credit_tab.ads_credit_id
left join (
    select grass_region,exchange_rate
    from mp_order.dim_exchange_rate__reg_s0_live
    where grass_region = '${upper_region}' and grass_date = date('${grass_date}')
) exrate on deduction_di.grass_region = exrate.grass_region
;