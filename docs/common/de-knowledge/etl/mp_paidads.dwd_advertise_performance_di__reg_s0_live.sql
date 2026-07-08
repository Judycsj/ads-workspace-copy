-- task_code: data_paidadsmart.studio_2508375  asset_id: 2508375
add jar hdfs://R2/projects/data_paidadsmart/hdfs/udf/paidads-data-warehouse-udf-1.0.63.jar;
CREATE OR REPLACE TEMPORARY FUNCTION bid_info_decode_func as  'com.shopee.deepdata.warehouse.hive.udf.BiddingInfoDecodeUDF';
CREATE OR REPLACE TEMPORARY FUNCTION decode_func as  'com.shopee.deepdata.warehouse.hive.udf.TranslogExtinfoDecodeUDF';
CREATE OR REPLACE TEMPORARY FUNCTION decode_buyer_func as  'com.shopee.deepdata.warehouse.hive.udf.BuyerSegementDecodeUDF';
create temporary function decode_video_id as 'com.shopee.data.video.udf.DecodeContentid' using jar 'hdfs://R2/projects/video/hdfs/udf/data-mart-udf-1.0-SNAPSHOT.jar';


create or replace temporary view report_ng_view as 
select  *
    from    mp_paidads.ods_log_ads_report_hi__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date >= DATE('${grass_date}')
      and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
      and   timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
      and   timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
      and   placement not in (3327, 3328, 33, 3337, 3338, 3339, 3342, 3348) 
      and cost is null
;


create or replace temporary view livestream_report_ng as 
select  *
from    mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live
where   grass_region = upper('${region}')
      and   grass_date >= DATE('${grass_date}')
      and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
      and   timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
      and   timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
      and   placement in (3327, 3328, 33, 3337, 3338, 3339, 3342, 3348) and  deduct_impression is null
;

create or replace temporary view cpm_deduction as 
select 
    ads_id,timestamp,shop_id,account_id,grass_region,deduct_unique_id,placement,deduct_timestamp,streamer_id, -- translog_db
    campaign_id,bid_type,entry_point,pricing_type, -- translog_db extinfo 

    search_scenario,search_entrance,search_mid,creator_id,video_id, location_in_ads,
    v_model_id, v_item_id, model_id, item_id, is_preselected_vmodel,-- translog_event 


    --cpm_detial``
    cpm_detail.user_id as user_id,
    coalesce(cpm_detail.target_type, target_type) as target_type,
    coalesce(cpm_detail.platform, platform) as platform,
    coalesce(cpm_detail.page_type, page_type) as page_type,
    coalesce(cpm_detail.page_section, page_section) as page_section,
    coalesce(cpm_detail.ls_session_id, ls_session_id) as ls_session_id,
    coalesce(cpm_detail.sub_entrance,sub_entrance) as sub_entrance,

    cpm_detail.is_ocpm as is_ocpm,
    cpm_detail.entrance as entrance,

    cpm_detail.app_version as app_version,
    imp_cost_detail.adjusted_cost as cost,
    imp_cost_detail.credit_cost as credit_cost,
    imp_cost_detail.balance_cost as balance_cost,
    cpm_detail.vvid as vv_id,
    cpm_detail.shop_recall_type as shop_recall_type,
    case when placement = 45 then cpm_detail.algo_json_data else algo_json_data end as algo_json_data,

    --item_json_data
    coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.target_cir') as double),
        cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.target_cir') as double),
        cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.target_cir') as double),
        cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.target_cir') as double),
        cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.target_cir') as double)) as target_cir,

   coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.item_price') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.item_price') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.item_price') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.item_price') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.item_price') as bigint)) as item_price,

    coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.ad_tag') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.ad_tag') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.ad_tag') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.ad_tag') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.ad_tag') as bigint)) as ad_tag,

    --shop_json_data, root_ads_data_str
    cast(coalesce(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.match_type'),  GET_JSON_OBJECT(root_ads_data_str, '$.match_type')) as bigint) as match_type,
    coalesce(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.query'),  GET_JSON_OBJECT(root_ads_data_str, '$.query')) as query,
    coalesce(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.ads_keyword'),  GET_JSON_OBJECT(root_ads_data_str, '$.ads_keyword')) as keyword,
    
    coalesce(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.request_id'),
        GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.request_id'),
        GET_JSON_OBJECT(cpm_detail.live_json_data, '$.request_id'),
        GET_JSON_OBJECT(cpm_detail.video_json_data, '$.request_id'),
        GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.request_id')) as request_id,

    cast(coalesce(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.brand_max_target_type'),  
              GET_JSON_OBJECT(root_ads_data_str, '$.brand_max_target_type')) as int) as brand_max_target_type,
      
    cast(coalesce(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.keywords_group_type'), 
         GET_JSON_OBJECT(root_ads_data_str, '$.keywords_group_type')) as int ) as keywords_group_type,
    cast(coalesce(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.brand_max_ads_type'),  
              GET_JSON_OBJECT(root_ads_data_str, '$.brand_max_ads_type')) as int) as brand_max_ads_type,
    cast(coalesce(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.package_request_id'),  
              GET_JSON_OBJECT(root_ads_data_str, '$.package_request_id')) as bigint) as package_request_id,
    cast(coalesce(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.package_request_asset_id'),  
              GET_JSON_OBJECT(root_ads_data_str, '$.package_request_asset_id')) as bigint) as package_request_asset_id,

    coalesce(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.ab_sign'),
        GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.ab_sign'),
        GET_JSON_OBJECT(cpm_detail.live_json_data, '$.ab_sign'),
        GET_JSON_OBJECT(cpm_detail.video_json_data, '$.ab_sign'),
        GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.ab_sign')) as signature,

    case when(placement in (45)) then 
      cast(coalesce(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.creative_id'),  GET_JSON_OBJECT(root_ads_data_str, '$.creative_id')) as bigint )
      else null end as creative_id,

    case when(placement in (45)) then 
      cast(coalesce(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.creative_algo'),  GET_JSON_OBJECT(root_ads_data_str, '$.creative_algo')) as int)
      else null end as creative_algo,
    
    coalesce(from_json(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.plan_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.plan_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.plan_bucket_list'), 'array<bigint>') ,
      from_json(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.plan_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.plan_bucket_list'), 'array<bigint>') ) as plan_bucket_list,

    coalesce(from_json(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.traffic_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.traffic_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.traffic_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.traffic_bucket_list'), 'array<bigint>'),
      from_json(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.traffic_bucket_list'), 'array<bigint>')) as traffic_bucket_list,

    coalesce(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.bid_rerank_trace'),
      GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.bid_rerank_trace'),
      GET_JSON_OBJECT(cpm_detail.live_json_data, '$.bid_rerank_trace'),
      GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.bid_rerank_trace'),
      GET_JSON_OBJECT(cpm_detail.video_json_data, '$.bid_rerank_trace')) as bid_rerank_trace,

    coalesce(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.uni_pcr_model_name'),
        GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.uni_pcr_model_name'),
        GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.uni_pcr_model_name'),
        GET_JSON_OBJECT(cpm_detail.live_json_data, '$.uni_pcr_model_name'),
        GET_JSON_OBJECT(cpm_detail.video_json_data, '$.uni_pcr_model_name')) as uni_pcr_model_name,

    coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.item_price_shop') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.item_price_shop') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.item_price_shop') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.item_price_shop') as bigint),
        cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.item_price_shop') as bigint)) as item_price_shop,

    coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.avg_sold_cnt_shop') as double),
        cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.avg_sold_cnt_shop') as double),
        cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.avg_sold_cnt_shop') as double),
        cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.avg_sold_cnt_shop') as double),
        cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.avg_sold_cnt_shop') as double)) as avg_sold_cnt_shop,

    coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.avg_sold_cnt_item') as double),
       cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.avg_sold_cnt_item') as double),
       cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.avg_sold_cnt_item') as double),
       cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.avg_sold_cnt_item') as double),
       cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.avg_sold_cnt_item') as double)) as avg_sold_cnt_item,

    coalesce(cast(GET_JSON_OBJECT(cpm_detail.item_json_data, '$.boost_deduction_price') as double), 
          cast(GET_JSON_OBJECT(cpm_detail.banner_json_data, '$.boost_deduction_price') as double),
          cast(GET_JSON_OBJECT(cpm_detail.shop_json_data, '$.boost_deduction_price') as double),
          cast(GET_JSON_OBJECT(cpm_detail.video_json_data, '$.boost_deduction_price') as double),
          cast(GET_JSON_OBJECT(cpm_detail.live_json_data, '$.boost_deduction_price') as double)) as boost_deduction_price,

    round(paid_free_map[1]  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_paid_credit_without_expiry,
    round(paid_free_map[2]  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_paid_credit_with_expiry,
    round(paid_free_map[3]  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_free_credit_without_expiry,
    round(paid_free_map[4]  * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost), 0) as expense_free_credit_with_expiry,
    round(expense_rebate_free_credit_without_expiry * (imp_cost_detail.adjusted_cost * 1.00000 / total_cost),0) as expense_rebate_free_credit_without_expiry,

    --fixed
    deduct_impression,
    0 as deduction_reason

from
  (
    select 
      --from translog_db
      translog_db.adsid as ads_id, 

      timestamp,
      shopid as shop_id, 
      account_id,
      acc_user_id as streamer_id,
      placement,
      translog_db.grass_region as grass_region,
      translog_db.deduct_unique_id as deduct_unique_id,
      dai_after_balance-dai_before_balance as total_cost,
      acc_before_balance,
      acc_after_balance,
      price,


      --from translog_db extinfo
      cast(get_json_object(decoded_extinfo, '$.campaignid') as bigint) as campaign_id,
      cast(get_json_object(decoded_extinfo, '$.lsSessionId') as bigint) as ls_session_id,
      get_json_object(decoded_extinfo, '$.bidType') as bid_type,
      get_json_object(decoded_extinfo, '$.requestId') as request_id,
      get_json_object(decoded_extinfo, '$.entryPoint') as entry_point,
      -- cast(get_json_object(decoded_extinfo, '$.entrance') as bigint) as entrance,
      cast(get_json_object(decoded_extinfo, '$.pricingType') as int) as pricing_type,
      get_json_object(decoded_extinfo, '$.adsCredits') as ads_credits,
      cast(get_json_object(decoded_extinfo, '$.deductTimestamp') as bigint) as deduct_timestamp,
      paid_free_map,
      expense_rebate_free_credit_without_expiry,

      --from translog_event
      page_type,
      page_section,
      sub_entrance,
      target_type,
      platform,
      imp_cost_details, 
      root_ads_data_str,
      search_scenario,
      search_entrance,
      search_mid,
      cpm_event_details_str,
      video_creator_id as creator_id,
      video_id,
      location_in_ads,
      v_model_id,
      v_item_id,
      item_id,
      model_id,
      algo_json_data,
      is_preselected_vmodel,

      --fixed
      1 as deduct_impression

    from (
      select *
      from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
      where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
      and tz_type='local'
      and operation = 11
    ) as translog_db
    left join
    (
      select deduct_unique_id, adsid,map_from_entries(COLLECT_LIST(paid_free)) as paid_free_map  from (
        select deduct_unique_id, adsid,named_struct("type",type, "amount",amount) as paid_free from (
          select deduct_unique_id,adsid,deduction_info.type as type, sum(cast(deduction_info.amount as bigint)) as amount
          from (
            select deduct_unique_id,adsid,deduction_info, deduction_info.type
            from (
              select deduct_unique_id,adsid,FROM_JSON( get_json_object(decoded_extinfo, '$.paidFreeExpirySummary.entries'), 'array<
                            struct<
                                type:BIGINT,
                                amount:string
                            >
                        >') as deduction_infos
                from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
                where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
                and tz_type='local'
                and operation = 11
            ) lateral view explode(deduction_infos) as deduction_info
          ) group by deduct_unique_id,adsid,deduction_info.type
        )
      ) group by deduct_unique_id,adsid
    ) as translog_paid_free
    on translog_db.deduct_unique_id = translog_paid_free.deduct_unique_id and translog_db.adsid = translog_paid_free.adsid
    left join (
      select deduct_unique_id,adsid,sum(cast(ads_credit.balanceBefore as bigint) - cast(ads_credit.balanceAfter as bigint)) as expense_rebate_free_credit_without_expiry
      from (
          select  deduct_unique_id,adsid                                                                                                                                                                                                                
              ,FROM_JSON(get_json_object(decoded_extinfo, '$.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string>>') AS ads_credits
          from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
          where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
              and tz_type='local' and operation = 11
      )lateral view explode(ads_credits) as ads_credit
      where ads_credit.orderType = 19
      group by deduct_unique_id,adsid
    ) translog_rebate 
    on translog_db.deduct_unique_id = translog_rebate.deduct_unique_id and translog_db.adsid = translog_rebate.adsid
    left join 
    (
      select translog.deduct_unique_id as deduct_unique_id,translog.adsid as adsid,translog.itemid as item_id,*
      from (
        select distinct *
        from mp_paidads.ods_log_translog_event_hi__reg_s0_live
        where   grass_region = upper('${region}')
        and   grass_date >= DATE('${grass_date}')
        and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
        and   translog.timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
        and   translog.timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
        and translog.operation in (11)
      )
    ) as translog_event
    on translog_db.deduct_unique_id = translog_event.deduct_unique_id and translog_db.adsid = translog_event.adsid
) lateral view POSEXPLODE(FROM_JSON(cpm_event_details_str, 'array<
                  struct<
                      user_id:BIGINT,
                      event_ts:BIGINT,
                      uniq_id:BIGINT,
                      cpm:BIGINT,
                      live_json_data:string,
                      rn_ver:string,
                      platform:int,
                      app_version:string,
                      event_id:string,
                      shop_recall_type:bigint,
                      target_type:string,
                      shop_json_data:string,
                      vvid:string,
                      video_json_data:string,
                      algo_json_data:string,
                      banner_json_data:string,
                      sub_entrance:int,
                      ls_session_id:bigint,
                      page_section:string,
                      page_type:string,
                      item_json_data:string,
                      is_ocpm:boolean,
                      entrance:int
                  >
              >')) cpm_details pos1,  cpm_detail
  lateral view POSEXPLODE(imp_cost_details) imp_cost_details pos2,  imp_cost_detail
where pos1=pos2
;


-- fix translog_event cpm records loss issue
-- use translog_db to extract revenue and dimensions
create or replace temporary view cpm_deduction_issue_fix as 
select 
    translog_db.adsid as ads_id, 

    timestamp,
    shopid as shop_id, 
    account_id,
    acc_user_id as streamer_id,
    placement,
    translog_db.grass_region as grass_region,
    translog_db.deduct_unique_id as deduct_unique_id,
    case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end as cost,

    cast(get_json_object(decoded_extinfo, '$.campaignid') as bigint) as campaign_id,
    cast(get_json_object(decoded_extinfo, '$.lsSessionId') as bigint) as ls_session_id,
    get_json_object(decoded_extinfo, '$.bidType') as bid_type,
    get_json_object(decoded_extinfo, '$.requestId') as request_id,
    get_json_object(decoded_extinfo, '$.entryPoint') as entry_point,
    -- cast(get_json_object(decoded_extinfo, '$.entrance') as bigint) as entrance,
    cast(get_json_object(decoded_extinfo, '$.pricingType') as int) as pricing_type,
    cast(get_json_object(decoded_extinfo, '$.deductTimestamp') as bigint) as deduct_timestamp,


    round(paid_free_map[1]  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_paid_credit_without_expiry,
    
    round(paid_free_map[2]  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_paid_credit_with_expiry,
    round(paid_free_map[3]  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_free_credit_without_expiry,
    round(paid_free_map[4]  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_free_credit_with_expiry,
    round(expense_rebate_free_credit_without_expiry  * ((case when(translog_event.cost is null) then translog_db.cost
      else translog_db.cost - translog_event.cost end) * 1.00000 / translog_db.cost), 0) as expense_rebate_free_credit_without_expiry,

    --fixed
    case when(translog_event.cost is null) then cast(get_json_object(decoded_extinfo, '$.batchCnt') as bigint) 
      else cast(get_json_object(decoded_extinfo, '$.batchCnt') as bigint) - cnt end as deduct_impression,
    0 as deduction_reason
      

from (
      select *, dai_after_balance-dai_before_balance as cost
      from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
      where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
      and tz_type='local'
      and operation = 11
    ) as translog_db
    left join
    (
      select deduct_unique_id,adsid, map_from_entries(COLLECT_LIST(paid_free)) as paid_free_map  from (
        select deduct_unique_id,adsid, named_struct("type",type, "amount",amount) as paid_free from (
          select deduct_unique_id,adsid,deduction_info.type as type, sum(cast(deduction_info.amount as bigint)) as amount
          from (
            select deduct_unique_id,adsid, deduction_info, deduction_info.type
            from (
              select deduct_unique_id,adsid,FROM_JSON( get_json_object(decoded_extinfo, '$.paidFreeExpirySummary.entries'), 'array<
                            struct<
                                type:BIGINT,
                                amount:string
                            >
                        >') as deduction_infos
                from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
                where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
                and tz_type='local'
                and operation = 11
            ) lateral view explode(deduction_infos) as deduction_info
          ) group by deduct_unique_id,adsid,deduction_info.type
        )
      ) group by deduct_unique_id,adsid
    ) as translog_paid_free
    on translog_db.deduct_unique_id = translog_paid_free.deduct_unique_id and translog_db.adsid = translog_paid_free.adsid
    left join (
      select deduct_unique_id,adsid,sum(cast(ads_credit.balanceBefore as bigint) - cast(ads_credit.balanceAfter as bigint)) as expense_rebate_free_credit_without_expiry
      from (
          select  deduct_unique_id,adsid                                                                                                                                                                                                                
              ,FROM_JSON(get_json_object(decoded_extinfo, '$.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string>>') AS ads_credits
          from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
          where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
              and tz_type='local' and operation = 11
      )lateral view explode(ads_credits) as ads_credit
      where ads_credit.orderType = 19
      group by deduct_unique_id,adsid
    ) translog_rebate 
    on translog_db.deduct_unique_id = translog_rebate.deduct_unique_id and translog_db.adsid = translog_rebate.adsid
    left join 
    (
      select deduct_unique_id,ads_id, sum(cost) as cost, count(*) as cnt
      from cpm_deduction
      group by deduct_unique_id,ads_id
    ) translog_event
on translog_db.deduct_unique_id = translog_event.deduct_unique_id and translog_db.adsid = translog_event.ads_id
where (translog_db.cost != translog_event.cost or translog_event.cost is null)
;

create or replace temporary view cpc_cps_deduction as 
select * ,  
case when operation =15 and ROW_NUMBER() over (partition by order_id,item_id, order_item_id order by timestamp) = 1 then 1 else 0 end as deduct_order
from (
select 
  --from translog_db
  translog_db.adsid as ads_id, 
  itemid as item_id,
  timestamp,
  shopid as shop_id, 
  placement,
  operation,
  translog_db.grass_region as grass_region,
  --coalesce(paid_free_map[1],0)+coalesce(paid_free_map[2],0)+coalesce(paid_free_map[3],0)+coalesce(paid_free_map[4],0) as cost,
  dai_after_balance - dai_before_balance as cost,

  case when (placement in (4)) then "wkdaelpmissisiht" 
    when (placement in (20,2003,2030)) then ""
    else keyword  end as keyword, 

  userid as user_id,
  translog_db.deduct_unique_id,


  --from translog_db extinfo
  cast(get_json_object(decoded_extinfo, '$.campaignid') as bigint) as campaign_id,
  cast(get_json_object(decoded_extinfo, '$.matchType') as bigint) as match_type,
  get_json_object(decoded_extinfo, '$.query.keyword') as query,
  get_json_object(decoded_extinfo, '$.bidType') as bid_type,
  get_json_object(decoded_extinfo, '$.requestId') as request_id,
  get_json_object(decoded_extinfo, '$.entryPoint') as entry_point,
  cast(get_json_object(decoded_extinfo, '$.entrance') as bigint) as entrance,
  cast(get_json_object(decoded_extinfo, '$.pricingType') as int) as pricing_type,
  cast(get_json_object(decoded_extinfo, '$.deductTimestamp') as bigint) as deduct_timestamp,
  cast(get_json_object(decoded_extinfo, '$.clickTimestamp') as bigint) as click_timestamp,
  cast(get_json_object(decoded_extinfo, '$.orderId') as bigint) as order_id,
  cast(get_json_object(decoded_extinfo, '$.orderItemId') as bigint) as order_item_id,
  cast(paid_free_map[1] as bigint) as expense_paid_credit_without_expiry,
  cast(paid_free_map[2] as bigint) as expense_paid_credit_with_expiry,
  cast(paid_free_map[3] as bigint) as expense_free_credit_without_expiry,
  cast(paid_free_map[4] as bigint) as expense_free_credit_with_expiry,
  expense_rebate_free_credit_without_expiry,


  --from translog_event
  platform,
  app_version,
  cast(case when placement in (3,20,2003,2030) then get_json_object(decoded_extinfo, '$.shopTraceInfo.clickArea')
    else click_area end as int) as click_area,
  location,
  video_id,
  display_video_id,
  rn_ver,
  raw_request_id,
  display_ad_tag,
  sub_entrance,
  traffic_source,
  case when traffic_source=4 and placement in (44,4400,4401,4402,4405) then 1 else null end as new_boost,
  click_event_id,
  page_type,
  page_section,
  target_type,
  search_scenario,
  search_entrance,
  search_mid,
  is_preselected_vmodel,

  sort_by,
  transform(translog_event_decoded_extinfo.buyerSegments, x->FROM_JSON(decode_buyer_func(base64(x)), '
                struct<
                    segmentTypeId:int,
                    info:array<
                          struct< segmentValueId:string>>
                >')) as buyer_segments,
  voucher_details,
  location_in_ads,
  case when placement in (40,50) then ctx_item_type else null end as ctx_item_type,
  v_model_id,
  v_item_id,
  model_id,
  algo_json_data,

  click_time_daily_budget,
  dai_after_balance-dai_before_balance as expected_revenue,
  original_deduct_id as original_deduct_unique_id,
  original_order_timestamp,
  (dai_after_balance-dai_before_balance)-(coalesce(paid_free_map[1],0)+coalesce(paid_free_map[2],0)+coalesce(paid_free_map[3],0)+coalesce(paid_free_map[4],0))as receivable_revenue,

  cast(get_json_object(decoded_extinfo, '$.expectDeductPrice') as bigint) as raw_expense,
  case when placement in (40,50) then translog_event.livestream_props.ls_session_id end as ls_session_id,
  case when placement in (40,50) then translog_event.livestream_props.streamer_id end as streamer_id,

  --from translog_event str_data
  COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.global_cat_ids') , GET_JSON_OBJECT(root_ads_data_str, '$.global_cat_ids')) as global_cat_ids,
  
  case when placement in (3) then 
        cast(GET_JSON_OBJECT(GET_JSON_OBJECT(coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.extra_json'),  GET_JSON_OBJECT(root_ads_data_str, '$.extra_json')),'$.creative_details'), '$.creative_algo') as int)
    when placement in (20,2003,2030) then cast(COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.creative_algo') , GET_JSON_OBJECT(root_ads_data_str, '$.creative_algo')) as int)
    when placement in (0,1,2,5) then 
        cast(GET_JSON_OBJECT(GET_JSON_OBJECT(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.extra_json'),  GET_JSON_OBJECT(root_ads_data_str, '$.extra_json')),'$.creative_details'), '$.creative_algo') as int)
    else cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.creative_algo') , GET_JSON_OBJECT(root_ads_data_str, '$.creative_algo')) as int) end as creative_algo,

  case when placement in (3,20,2003,2030) then cast(COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.creative_id') , GET_JSON_OBJECT(root_ads_data_str, '$.creative_id')) as bigint)
      else cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.creative_id') , GET_JSON_OBJECT(root_ads_data_str, '$.creative_id')) as bigint) end as creative_id,


  COALESCE(cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.target_cir') , GET_JSON_OBJECT(root_ads_data_str, '$.target_cir')) as double),
      from_json(from_json(get_json_object(get_json_object(item_ads_data_str, '$.extra_json'), '$.bid-infos'),
      'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
      'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').target_cir) as target_cir,


  case when placement in (3,20,2003,2030) then COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.ta_matched_tag_ids') , GET_JSON_OBJECT(root_ads_data_str, '$.ta_matched_tag_ids'))
      else COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.ta_matched_tag_ids') , GET_JSON_OBJECT(root_ads_data_str, '$.ta_matched_tag_ids')) end as ta_matched_tag_ids,
  cast(case when placement in (3,20,2003,2030) then COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.ta_premium_rate') , GET_JSON_OBJECT(root_ads_data_str, '$.ta_premium_rate'))
      else COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.ta_premium_rate') , GET_JSON_OBJECT(root_ads_data_str, '$.ta_premium_rate')) end as bigint) as ta_premium_rate,
  COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.gmv_boost') , GET_JSON_OBJECT(root_ads_data_str, '$.gmv_boost')) as gmv_boost,
  case when placement in (3,20,2003,2030) then COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.ab_sign') , GET_JSON_OBJECT(root_ads_data_str, '$.ab_sign'))
      else  COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.ab_sign') , GET_JSON_OBJECT(root_ads_data_str, '$.ab_sign')) end as signature,
  cast(case when placement in (3,20,2003,2030) then COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.ta_group_id') , GET_JSON_OBJECT(root_ads_data_str, '$.ta_group_id'))
      else COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.ta_group_id') , GET_JSON_OBJECT(root_ads_data_str, '$.ta_group_id')) end as bigint) as ta_group_id,
  COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.cold_start_boost') , GET_JSON_OBJECT(root_ads_data_str, '$.cold_start_boost')) as cold_start_boost,
  cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.attr_data_type') , GET_JSON_OBJECT(root_ads_data_str, '$.attr_data_type')) as int) as attr_data_type,
      
  COALESCE(cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.item_price') , GET_JSON_OBJECT(root_ads_data_str, '$.item_price')) as bigint),
      from_json(from_json(get_json_object(get_json_object(item_ads_data_str, '$.extra_json'), '$.bid-infos'),
      'array<struct<bidding_extra_json:string>>')[0].bidding_extra_json,
      'struct<avg_sold_cnt:double, bid_coef_array:string,init_bid_price:bigint,item_price:bigint, pid_coef:double, target_cir:double >').item_price) as item_price,

  cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.new_product_boost_coef') , GET_JSON_OBJECT(root_ads_data_str, '$.new_product_boost_coef')) as double) as new_product_boost_coef,
  cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.new_product_boost_stage') , GET_JSON_OBJECT(root_ads_data_str, '$.new_product_boost_stage')) as int) as new_product_boost_stage,
  cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.bid_voucher_id') , GET_JSON_OBJECT(root_ads_data_str, '$.bid_voucher_id')) as bigint) as bid_voucher_id,
  cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.voucher_deduction_price') , GET_JSON_OBJECT(root_ads_data_str, '$.voucher_deduction_price')) as bigint) as voucher_deduction_price,
  cast(COALESCE(GET_JSON_OBJECT(item_ads_data_str, '$.deduction_price_0') , GET_JSON_OBJECT(root_ads_data_str, '$.deduction_price_0')) as bigint) as deduction_price_0,

  case when placement in (3,20,2003,2030) then from_json(coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.plan_bucket_list'),  GET_JSON_OBJECT(root_ads_data_str, '$.plan_bucket_list')),'array<bigint>')
    else from_json(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.plan_bucket_list'),  GET_JSON_OBJECT(root_ads_data_str, '$.plan_bucket_list')),'array<bigint>') end as plan_bucket_list,
  case when placement in (3,20,2003,2030) then from_json(coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.traffic_bucket_list'),  GET_JSON_OBJECT(root_ads_data_str, '$.traffic_bucket_list')),'array<bigint>')
    else from_json(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.traffic_bucket_list'),  GET_JSON_OBJECT(root_ads_data_str, '$.traffic_bucket_list')),'array<bigint>') end as traffic_bucket_list,
  case when placement in (3,20,2003,2030) then coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.bid_rerank_trace'),  GET_JSON_OBJECT(root_ads_data_str, '$.bid_rerank_trace'))
    else coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.bid_rerank_trace'),  GET_JSON_OBJECT(root_ads_data_str, '$.bid_rerank_trace')) end as bid_rerank_trace,
  case when placement in (3,20,2003,2030) then coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.uni_pcr_model_name'),  GET_JSON_OBJECT(root_ads_data_str, '$.uni_pcr_model_name'))
    else coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.uni_pcr_model_name'),  GET_JSON_OBJECT(root_ads_data_str, '$.uni_pcr_model_name')) end as uni_pcr_model_name,
  cast(case when placement in (3,20,2003,2030) then coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.item_price_shop'),  GET_JSON_OBJECT(root_ads_data_str, '$.item_price_shop'))
    else coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.item_price_shop'),  GET_JSON_OBJECT(root_ads_data_str, '$.item_price_shop')) end as bigint) as item_price_shop,
  cast(case when placement in (3,20,2003,2030) then coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.avg_sold_cnt_shop'),  GET_JSON_OBJECT(root_ads_data_str, '$.avg_sold_cnt_shop')) 
    else coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.avg_sold_cnt_shop'),  GET_JSON_OBJECT(root_ads_data_str, '$.avg_sold_cnt_shop')) end as double) as avg_sold_cnt_shop,
  cast(case when placement in (3,20,2003,2030) then coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.avg_sold_cnt_item'),  GET_JSON_OBJECT(root_ads_data_str, '$.avg_sold_cnt_item'))
    else coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.avg_sold_cnt_item'),  GET_JSON_OBJECT(root_ads_data_str, '$.avg_sold_cnt_item')) end as double) as avg_sold_cnt_item,
  cast(case when placement in (3,20,2003,2030) then coalesce(GET_JSON_OBJECT(shop_ads_data_str, '$.ad_tag'),  GET_JSON_OBJECT(root_ads_data_str, '$.ad_tag'))
    else coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.ad_tag'),  GET_JSON_OBJECT(root_ads_data_str, '$.ad_tag')) end as bigint) as ad_tag,
  case when placement in (40,50) then cast(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.original_ads_itemid'),GET_JSON_OBJECT(root_ads_data_str, '$.original_ads_itemid')) as bigint) end as original_itemid,
  case when placement in (40,50) then cast(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.mapped_ads_itemid'),GET_JSON_OBJECT(root_ads_data_str, '$.mapped_ads_itemid')) as bigint) end as mapped_ads_itemid,
  case when placement in (3,20,2003,2030) then 0
      else coalesce(cast(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.deduction_reason'),  GET_JSON_OBJECT(root_ads_data_str, '$.deduction_reason')) as int),0) end as deduction_reason,

  coalesce(cast(coalesce(GET_JSON_OBJECT(item_ads_data_str, '$.boost_deduction_price'),  GET_JSON_OBJECT(root_ads_data_str, '$.boost_deduction_price')) as double),0) as boost_deduction_price,
  
  --fixed
  case when operation =1 then 1 else 0 end  as click

from (
  select *
  from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
   where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
      and tz_type='local'
  and operation in (1,15)
) as translog_db
left join 
(
  select translog.deduct_unique_id as deduct_unique_id,translog.adsid as adsid,
         from_json(decode_func(base64(translog.extinfo)), 'struct <
                buyerSegments:array<binary>
                >') as translog_event_decoded_extinfo, *
  from (
      select distinct *
      from mp_paidads.ods_log_translog_event_hi__reg_s0_live
      where  grass_region = upper('${region}')
      and   grass_date >= DATE('${grass_date}')
      and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
      and   translog.timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
      and   translog.timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
      and translog.operation in (1,15)
  )
) as translog_event
on translog_db.deduct_unique_id = translog_event.deduct_unique_id and translog_db.adsid = translog_event.adsid
left join
(
  select deduct_unique_id,adsid, map_from_entries(COLLECT_LIST(paid_free)) as paid_free_map  from (
    select deduct_unique_id,adsid, named_struct("type",type, "amount",amount) as paid_free from (
      select deduct_unique_id,adsid,deduction_info.type as type, sum(cast(deduction_info.amount as bigint)) as amount
      from (
        select deduct_unique_id,adsid, deduction_info, deduction_info.type
        from (
          select deduct_unique_id,adsid,FROM_JSON( get_json_object(decoded_extinfo, '$.paidFreeExpirySummary.entries'), 'array<
                        struct<
                            type:BIGINT,
                            amount:string
                        >
                    >') as deduction_infos
            from    mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
            where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
             and tz_type='local'
             and operation in (1,15)
        ) lateral view explode(deduction_infos) as deduction_info
      ) group by deduct_unique_id,adsid,deduction_info.type
    )
  ) group by deduct_unique_id,adsid
) as translog_paid_free
on translog_db.deduct_unique_id = translog_paid_free.deduct_unique_id and translog_db.adsid = translog_paid_free.adsid
left join (
  select deduct_unique_id,adsid,sum(cast(ads_credit.balanceBefore as bigint) - cast(ads_credit.balanceAfter as bigint)) as expense_rebate_free_credit_without_expiry
  from (
      select  deduct_unique_id,adsid                                                                                                                                                                                                                
          ,FROM_JSON(get_json_object(decoded_extinfo, '$.adsCredits'),'array<struct<orderId:string,orderType:int,balanceBefore:string,balanceAfter:string,mainType:int,withExpiry:boolean,effectiveType:int,adsCreditId:string>>') AS ads_credits
      from mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live
      where   grass_date = DATE('${grass_date}') and grass_region = upper('${region}')
          and tz_type='local' and operation in (1,15)
  )lateral view explode(ads_credits) as ads_credit
  where ads_credit.orderType = 19
  group by deduct_unique_id,adsid
) translog_rebate 
on translog_db.deduct_unique_id = translog_rebate.deduct_unique_id and translog_db.adsid = translog_rebate.adsid
)
;

create or replace temporary view base as 
select 
*
from
(select  ads_id
        ,broad_gmv / 100000.0 as broad_gmv_amt_local
        ,broad_item_count as broad_item_cnt
        ,broad_order as broad_order_cnt
        ,broad_shop_item_click as broad_shop_item_click_cnt
        ,broad_shop_item_imp as broad_shop_item_impression_cnt
        ,campaign_id
        ,click as click_cnt
        ,click_timestamp
        ,from_unixtime(click_timestamp, 'yyyy-MM-dd HH:mm:ss') as click_datetime
        ,cost / 100000.0 as expenditure_amt_local
        ,daily_order as daily_order_cnt
        ,daily_gmv / 100000.0 as daily_gmv_amt_local
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,impression as impression_cnt
        ,item_id
        ,keyword
        ,location_in_ads
        ,CASE
             WHEN placement in (0,3,4,1000,1200) THEN COALESCE(match_type, 0)
             ELSE match_type
         END AS match_type
        ,order as order_cnt
        ,checkout as checkout_cnt
        ,order_amount as ads_item_sold_cnt
        ,order_gmv / 100000.0 as ads_order_gmv_local
        ,order_id
        ,placement
        ,query
        ,raw_click as click_before_deduction_cnt
        ,user_id
        ,request_id
        ,shop_id
        ,shop_item_click as shop_item_click_cnt
        ,shop_item_impression as shop_item_impression_cnt
        ,to_json(bs) as matched_premium_segment
        ,bs.segment_type_id as matched_premium_segment_type_id
        ,bs.info[0].segment_value_id as matched_premium_segment_value_id
        ,timestamp
        ,event_timestamp
        ,from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
        ,case   when cod = true then 1
                else 0
         end as is_cod
        ,confirmed_order as confirmed_order_cnt
        ,paid_order as paid_order_cnt
        ,paid_timestamp
        ,from_unixtime(paid_timestamp, 'yyyy-MM-dd HH:mm:ss') as paid_datetime
        ,confirmed_timestamp
        ,from_unixtime(confirmed_timestamp, 'yyyy-MM-dd HH:mm:ss') as confirmed_datetime
        ,signature as ab_sign
        ,entrance as entrance
        ,pricing_type as pricing_type
        ,add_to_cart as add_to_cart_cnt
        ,add_to_cart_without_click as add_to_cart_without_clicks_cnt
        ,broad_add_to_cart as broad_add_to_cart_cnt
        ,raw_request_id
        ,location
        ,platform
        ,raw_click as raw_click_cnt
        ,null as search_origin_bid_price_local
        ,null as search_bid_type
        ,sub_entrance
        ,video_id
        ,creative_id
        ,image_id
        ,null as search_capped_price
        ,account_id
        ,ls_session_id
        ,view
        ,view_duration
        ,product_click
        ,deduct_impression
        ,non_fraud_impression
        ,cpm 
        ,cost_by_cpm as expense_by_cpm
        ,click_area
        ,display_video_id
        ,ta_group_id  
        ,ta_matched_tag_ids
        ,ta_premium_rate 
        ,origin_ids.item_id as origin_item_id
        ,app_ver as app_version
        ,origin_bid_price
        ,raw_expense
        ,daily_order_amount
        ,slot_id
        ,click_event_id
        ,page_type
        ,page_section
        ,target_type
        ,search_scenario
        ,search_entrance
        ,search_mid
        ,attr_data_type
        ,sort_by
        ,new_boost
        ,traffic_source
        ,video_view
        ,display_ads_tag
        ,broad_order_1d
        ,deduct_unique_id
        ,target_cir
        ,item_price
        ,grass_region
        ,vv_id
        ,creator_id
        ,video_play_complete
        ,raw_impression
        ,raw_product_click
        ,decode_video_id(video_id) as decoded_video_id
        ,new_product_boost_coef
        ,new_product_boost_stage
        ,bid_voucher_id
        ,voucher_deduction_price / 100000.0 as voucher_deduction_price
        ,(COALESCE(deduction_price_0,0) + COALESCE(voucher_deduction_price,0)) / 100000.0 as deduction_price
        ,voucher_details
        ,ads_voucher_auto_claimed
        ,pageview as page_view
        ,ctx_item_type
        ,v_model_id
        ,v_item_id
        ,model_id
        ,order_item_has_spu_vmodel
        ,paid_order_gmv / 100000.0 as paid_order_gmv
        ,algo_json_data
        ,null as deduct_timestamp
        ,deduct_order
        ,cps_dedup_click
        ,deduplicated_click
        ,null as click_time_daily_budget
        ,null as expected_revenue
        ,null as original_deduct_unique_id
        ,null as original_order_timestamp
        ,null as receivable_revenue
        ,creative_algo
        ,shop_recall_type
        ,no_click_order
        ,no_click_item_count
        ,no_click_gmv / 100000.0 as no_click_gmv
        ,bid_rerank_trace  
        ,uni_pcr_model_name
        ,item_price_shop
        ,avg_sold_cnt_shop
        ,avg_sold_cnt_item
        ,plan_bucket_list
        ,expense_rebate_free_credit_without_expiry
        ,ad_tag
        ,streamer_id
        ,original_itemid
        ,mapped_ads_itemid
        ,duplicate_label

        ,imp_attr_order as imp_attr_order_cnt
        ,imp_attr_order_amount as imp_attr_order_item_sold_cnt
        ,imp_attr_order_gmv / 100000.0 as imp_attr_order_gmv
        ,imp_attr_agent_order as imp_attr_agent_order_cnt
        ,imp_attr_agent_order_amount as imp_attr_agent_item_sold_cnt
        ,imp_attr_agent_order_gmv / 100000.0 as imp_attr_agent_order_gmv
        ,shop_exp_tag

        ,imp_attr_paid_order as imp_attr_paid_order_cnt
        ,imp_attr_paid_order_amount as imp_attr_paid_order_item_sold_cnt
        ,imp_attr_paid_order_gmv / 100000.0 as imp_attr_paid_order_gmv
        ,paid_order_amount as paid_order_item_sold_cnt
        ,paid_broad_order as paid_broad_order_cnt
        ,paid_broad_gmv / 100000.0 as paid_broad_order_gmv
        ,paid_broad_order_amount as paid_broad_order_item_sold_cnt
        ,paid_checkout as paid_checkout_cnt

        ,paid_agent_checkout as paid_agent_checkout_cnt
        ,paid_no_click_order_amount as paid_no_click_order_item_sold_cnt
        ,paid_no_click_order_gmv / 100000.0 as paid_no_click_order_gmv
        ,paid_no_click_order as paid_no_click_order_cnt
        ,shop_view
        ,shop_video_play
        ,shop_video_play_complete
        ,shop_video_play_time
        ,shop_video_click
        ,brand_max_target_type
        ,imp_timestamp
        ,null as agent_order_cnt
        ,null as agent_order_item_sold_cnt
        ,null as agent_order_gmv
        ,null as agent_checkout_cnt

        ,null as paid_agent_order_cnt
        ,null as paid_agent_order_item_sold_cnt
        ,null as paid_agent_order_gmv  
        ,traffic_bucket_list
        ,is_ocpm
        ,deduction_reason
        ,keywords_group_type
        ,brand_max_ads_type
        ,package_request_id
        ,package_request_asset_id
        ,non_fraud_click
        ,boost_deduction_price
        ,is_preselected_vmodel
from    report_ng_view
lateral view outer EXPLODE(buyer_segments) as bs

union all 

select  ads_id
        ,broad_gmv / 100000.0 as broad_gmv_amt_local
        ,broad_item_count as broad_item_cnt
        ,broad_order as broad_order_cnt
        ,broad_shop_item_click as broad_shop_item_click_cnt
        ,broad_shop_item_imp as broad_shop_item_impression_cnt
        ,campaign_id
        ,click as click_cnt
        ,click_timestamp
        ,from_unixtime(click_timestamp, 'yyyy-MM-dd HH:mm:ss') as click_datetime
        ,cost / 100000.0 as expenditure_amt_local
        ,daily_order as daily_order_cnt
        ,daily_gmv / 100000.0 as daily_gmv_amt_local
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,impression as impression_cnt
        ,item_id
        ,keyword
        ,location_in_ads
        ,CASE
             WHEN placement in (0,3,4,1000,1200) THEN COALESCE(match_type, 0)
             ELSE match_type
         END AS match_type
        ,order as order_cnt
        ,checkout as checkout_cnt
        ,order_amount as ads_item_sold_cnt
        ,order_gmv / 100000.0 as ads_order_gmv_local
        ,order_id
        ,placement
        ,query
        ,raw_click as click_before_deduction_cnt
        ,user_id
        ,request_id
        ,shop_id
        ,shop_item_click as shop_item_click_cnt
        ,shop_item_impression as shop_item_impression_cnt
        ,to_json(bs) as matched_premium_segment
        ,bs.segment_type_id as matched_premium_segment_type_id
        ,bs.info[0].segment_value_id as matched_premium_segment_value_id
        ,timestamp
        ,event_timestamp
        ,from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss') as event_datetime
        ,case   when cod = true then 1
                else 0
         end as is_cod
        ,confirmed_order as confirmed_order_cnt
        ,paid_order as paid_order_cnt
        ,paid_timestamp
        ,from_unixtime(paid_timestamp, 'yyyy-MM-dd HH:mm:ss') as paid_datetime
        ,confirmed_timestamp
        ,from_unixtime(confirmed_timestamp, 'yyyy-MM-dd HH:mm:ss') as confirmed_datetime
        ,signature as ab_sign
        ,entrance as entrance
        ,pricing_type as pricing_type
        ,add_to_cart as add_to_cart_cnt
        ,add_to_cart_without_click as add_to_cart_without_clicks_cnt
        ,broad_add_to_cart as broad_add_to_cart_cnt
        ,raw_request_id
        ,location
        ,platform
        ,raw_click as raw_click_cnt
        ,null as search_origin_bid_price_local
        ,null as search_bid_type
        ,sub_entrance
        ,video_id
        ,creative_id
        ,image_id
        ,null as search_capped_price
        ,account_id
        ,ls_session_id
        ,view
        ,view_duration
        ,product_click
        ,deduct_impression
        ,non_fraud_impression
        ,cpm 
        ,cost_by_cpm as expense_by_cpm
        ,click_area
        ,null as display_video_id
        ,ta_group_id  
        ,ta_matched_tag_ids
        ,ta_premium_rate 
        ,origin_ids.item_id as origin_item_id
        ,app_ver as app_version
        ,origin_bid_price
        ,raw_expense
        ,daily_order_amount
        ,slot_id
        ,null as click_event_id
        ,page_type
        ,page_section
        ,target_type
        ,null as search_scenario
        ,null as search_entrance
        ,null as search_mid
        ,attr_data_type
        ,null as sort_by
        ,null as new_boost
        ,null as traffic_source
        ,null as video_view
        ,null as display_ads_tag
        ,null as broad_order_1d
        ,deduct_unique_id
        ,target_cir
        ,null as item_price
        ,grass_region
        ,null as vv_id
        ,null as creator_id
        ,null as video_play_complete
        ,null as raw_impression
        ,null as raw_product_click
        ,decode_video_id(video_id) as decoded_video_id
        ,null as new_product_boost_coef
        ,null as new_product_boost_stage
        ,null as bid_voucher_id
        ,null as voucher_deduction_price
        ,null as deduction_price
        ,null as voucher_details
        ,null as ads_voucher_auto_claimed
        ,null as page_view
        ,null as ctx_item_type
        ,null as v_model_id
        ,null as v_item_id
        ,model_id
        ,null as order_item_has_spu_vmodel
        ,paid_order_gmv / 100000.0 as paid_order_gmv
        ,algo_json_data
        ,null as deduct_timestamp
        ,null as deduct_order
        ,null as cps_dedup_click
        ,null as deduplicated_click
        ,null as click_time_daily_budget
        ,null as expected_revenue
        ,null as original_deduct_unique_id
        ,null as original_order_timestamp
        ,null as receivable_revenue
        ,creative_algo
        ,null as shop_recall_type
        ,null as no_click_order
        ,null as no_click_item_count
        ,null as no_click_gmv
        ,null as bid_rerank_trace  
        ,null as uni_pcr_model_name
        ,null as item_price_shop
        ,null as avg_sold_cnt_shop
        ,null as avg_sold_cnt_item
        ,plan_bucket_list
        ,null as expense_rebate_free_credit_without_expiry
        ,null as ad_tag
        ,streamer_id
        ,null as original_itemid
        ,null as mapped_ads_itemid
        ,null as duplicate_label
        ,imp_attr_order as imp_attr_order_cnt
        ,imp_attr_order_amount as imp_attr_order_item_sold_cnt
        ,imp_attr_order_gmv / 100000.0 as imp_attr_order_gmv
        ,imp_attr_agent_order as imp_attr_agent_order_cnt
        ,imp_attr_agent_order_amount as imp_attr_agent_item_sold_cnt
        ,imp_attr_agent_order_gmv / 100000.0 as imp_attr_agent_order_gmv
        ,shop_exp_tag

        ,imp_attr_paid_order as imp_attr_paid_order_cnt
        ,imp_attr_paid_order_amount as imp_attr_paid_order_item_sold_cnt
        ,imp_attr_paid_order_gmv / 100000.0 as imp_attr_paid_order_gmv
        ,paid_order_amount as paid_order_item_sold_cnt
        ,paid_broad_order as paid_broad_order_cnt
        ,paid_broad_gmv / 100000.0 as paid_broad_order_gmv
        ,paid_broad_order_amount as paid_broad_order_item_sold_cnt
        ,paid_checkout as paid_checkout_cnt

        ,paid_agent_checkout as paid_agent_checkout_cnt
        ,paid_no_click_order_amount as paid_no_click_order_item_sold_cnt
        ,paid_no_click_order_gmv / 100000.0 as paid_no_click_order_gmv
        ,paid_no_click_order as paid_no_click_order_cnt
        ,null as shop_view
        ,null as shop_video_play
        ,null as shop_video_play_complete
        ,null as shop_video_play_time
        ,null as shop_video_click
        ,null as brand_max_target_type
        ,imp_timestamp
        ,agent_order as agent_order_cnt
        ,agent_order_amount as agent_order_item_sold_cnt
        ,agent_order_gmv / 100000.0 as agent_order_gmv
        ,agent_checkout as agent_checkout_cnt

        ,paid_agent_order as paid_agent_order_cnt
        ,paid_agent_order_amount as paid_agent_order_item_sold_cnt
        ,paid_agent_order_gmv / 100000.0 as paid_agent_order_gmv
        ,null as traffic_bucket_list
        ,null as is_ocpm
        ,deduction_reason
        ,null as keywords_group_type
        ,null as brand_max_ads_type
        ,null as package_request_id
        ,null as package_request_asset_id
        ,non_fraud_click
        ,null as boost_deduction_price
        ,null as is_preselected_vmodel
from    livestream_report_ng
lateral view outer EXPLODE(buyer_segments) as bs

union all 

--cpm deduction
select  ads_id
        ,null as broad_gmv_amt_local
        ,null as broad_item_cnt
        ,null as broad_order_cnt
        ,null as broad_shop_item_click_cnt
        ,null as broad_shop_item_impression_cnt
        ,campaign_id
        ,null as click_cnt
        ,null as click_timestamp
        ,null as click_datetime
        ,cost / 100000.0 as expenditure_amt_local
        ,null as daily_order_cnt
        ,null as daily_gmv_amt_local
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,null as impression_cnt
        ,item_id
        ,keyword
        ,location_in_ads
        ,match_type
        ,null as order_cnt
        ,null as checkout_cnt
        ,null as ads_item_sold_cnt
        ,null ads_order_gmv_local
        ,null as order_id
        ,placement
        ,query
        ,null as click_before_deduction_cnt
        ,user_id
        ,request_id
        ,shop_id
        ,null as shop_item_click_cnt
        ,null as shop_item_impression_cnt
        ,null as matched_premium_segment
        ,null as matched_premium_segment_type_id
        ,null as matched_premium_segment_value_id
        ,timestamp
        ,null as event_timestamp
        ,null as event_datetime
        ,null as is_cod
        ,null as confirmed_order_cnt
        ,null as paid_order_cnt
        ,null as paid_timestamp
        ,null as paid_datetime
        ,null as confirmed_timestamp
        ,null as confirmed_datetime
        ,signature as ab_sign
        ,entrance as entrance
        ,pricing_type
        ,null as add_to_cart_cnt
        ,null as add_to_cart_without_clicks_cnt
        ,null as broad_add_to_cart_cnt
        ,null as raw_request_id
        ,null as location
        ,platform
        ,null as raw_click_cnt
        ,null as search_origin_bid_price_local
        ,null as search_bid_type
        ,sub_entrance
        ,video_id
        ,creative_id
        ,null as image_id
        ,null as search_capped_price
        ,account_id
        ,ls_session_id
        ,null as view
        ,null as view_duration
        ,null as product_click
        ,deduct_impression
        ,null as non_fraud_impression
        ,null as cpm 
        ,null as expense_by_cpm
        ,null as click_area
        ,null as display_video_id
        ,null as ta_group_id  
        ,null as ta_matched_tag_ids
        ,null as ta_premium_rate 
        ,null as origin_item_id
        ,app_version
        ,null as origin_bid_price
        ,null as raw_expense
        ,null as daily_order_amount
        ,null as slot_id
        ,null as click_event_id
        ,page_type
        ,page_section
        ,target_type 
        ,search_scenario
        ,search_entrance
        ,search_mid 
        ,null as attr_data_type
        ,null as sort_by
        ,null as new_boost
        ,null as traffic_source
        ,null as video_view
        ,null as display_ads_tag
        ,null as broad_order_1d
        ,deduct_unique_id
        ,target_cir
        ,item_price
        ,grass_region
        ,vv_id
        ,creator_id
        ,null as video_play_complete
        ,null as raw_impression
        ,null as raw_product_click
        ,decode_video_id(video_id) as decoded_video_id
        ,null as new_product_boost_coef
        ,null as new_product_boost_stage
        ,null as bid_voucher_id
        ,null as voucher_deduction_price
        ,null as deduction_price
        ,null as voucher_details
        ,null as ads_voucher_auto_claimed
        ,null as page_view
        ,null as ctx_item_type
        ,v_model_id
        ,v_item_id
        ,model_id
        ,null as order_item_has_spu_vmodel
        ,null as paid_order_gmv
        ,algo_json_data
        ,deduct_timestamp
        ,null as deduct_order
        ,null as cps_dedup_click
        ,null as deduplicated_click
        ,null as click_time_daily_budget
        ,null as expected_revenue
        ,null as original_deduct_unique_id
        ,null as original_order_timestamp
        ,null as receivable_revenue
        ,creative_algo
        ,shop_recall_type
        ,null as no_click_order
        ,null as no_click_item_count
        ,null as no_click_gmv
        ,bid_rerank_trace  
        ,uni_pcr_model_name
        ,item_price_shop
        ,avg_sold_cnt_shop
        ,avg_sold_cnt_item
        ,plan_bucket_list
        ,expense_rebate_free_credit_without_expiry
        ,ad_tag
        ,streamer_id
        ,null as original_itemid
        ,null as mapped_ads_itemid
        ,null as duplicate_label
        ,null as imp_attr_order_cnt
        ,null as imp_attr_order_item_sold_cnt
        ,null as imp_attr_order_gmv
        ,null as imp_attr_agent_order_cnt
        ,null as imp_attr_agent_item_sold_cnt
        ,null as imp_attr_agent_order_gmv
        ,null as shop_exp_tag

        ,null as imp_attr_paid_order_cnt
        ,null as imp_attr_paid_order_item_sold_cnt
        ,null as imp_attr_paid_order_gmv
        ,null as paid_order_item_sold_cnt
        ,null as paid_broad_order_cnt
        ,null as paid_broad_order_gmv
        ,null as paid_broad_order_item_sold_cnt
        ,null as paid_checkout_cnt

        ,null as paid_agent_checkout_cnt
        ,null as paid_no_click_order_item_sold_cnt
        ,null as paid_no_click_order_gmv
        ,null as paid_no_click_order_cnt
        ,null as shop_view
        ,null as shop_video_play
        ,null as shop_video_play_complete
        ,null as shop_video_play_time
        ,null as shop_video_click
        ,brand_max_target_type
        ,null as imp_timestamp

        ,null as agent_order_cnt
        ,null as agent_order_item_sold_cnt
        ,null as agent_order_gmv
        ,null as agent_checkout_cnt

        ,null as paid_agent_order_cnt
        ,null as paid_agent_order_item_sold_cnt
        ,null as paid_agent_order_gmv  
        ,traffic_bucket_list
        ,is_ocpm
        ,deduction_reason
        ,keywords_group_type
        ,brand_max_ads_type
        ,package_request_id
        ,package_request_asset_id
        ,null as non_fraud_click
        ,boost_deduction_price
        ,is_preselected_vmodel
from    cpm_deduction

union all 

--cpm deduction issue fix
select  ads_id
        ,null as broad_gmv_amt_local
        ,null as broad_item_cnt
        ,null as broad_order_cnt
        ,null as broad_shop_item_click_cnt
        ,null as broad_shop_item_impression_cnt
        ,campaign_id
        ,null as click_cnt
        ,null as click_timestamp
        ,null as click_datetime
        ,cost / 100000.0 as expenditure_amt_local
        ,null as daily_order_cnt
        ,null as daily_gmv_amt_local
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,null as impression_cnt
        ,null as item_id
        ,null as keyword
        ,null as location_in_ads
        ,null as match_type
        ,null as order_cnt
        ,null as checkout_cnt
        ,null as ads_item_sold_cnt
        ,null ads_order_gmv_local
        ,null as order_id
        ,placement
        ,null as query
        ,null as click_before_deduction_cnt
        ,null as user_id
        ,request_id
        ,shop_id
        ,null as shop_item_click_cnt
        ,null as shop_item_impression_cnt
        ,null as matched_premium_segment
        ,null as matched_premium_segment_type_id
        ,null as matched_premium_segment_value_id
        ,timestamp
        ,null as event_timestamp
        ,null as event_datetime
        ,null as is_cod
        ,null as confirmed_order_cnt
        ,null as paid_order_cnt
        ,null as paid_timestamp
        ,null as paid_datetime
        ,null as confirmed_timestamp
        ,null as confirmed_datetime
        ,null as ab_sign
        ,null as entrance
        ,pricing_type
        ,null as add_to_cart_cnt
        ,null as add_to_cart_without_clicks_cnt
        ,null as broad_add_to_cart_cnt
        ,null as raw_request_id
        ,null as location
        ,null as platform
        ,null as raw_click_cnt
        ,null as search_origin_bid_price_local
        ,null as search_bid_type
        ,null as sub_entrance
        ,null as video_id
        ,null as creative_id
        ,null as image_id
        ,null as search_capped_price
        ,account_id
        ,ls_session_id
        ,null as view
        ,null as view_duration
        ,null as product_click
        ,deduct_impression
        ,null as non_fraud_impression
        ,null as cpm 
        ,null as expense_by_cpm
        ,null as click_area
        ,null as display_video_id
        ,null as ta_group_id  
        ,null as ta_matched_tag_ids
        ,null as ta_premium_rate 
        ,null as origin_item_id
        ,null as app_version
        ,null as origin_bid_price
        ,null as raw_expense
        ,null as daily_order_amount
        ,null as slot_id
        ,null as click_event_id
        ,null as page_type
        ,null as page_section
        ,null as target_type
        ,null as search_scenario
        ,null as search_entrance
        ,null as search_mid
        ,null as attr_data_type
        ,null as sort_by
        ,null as new_boost
        ,null as traffic_source
        ,null as video_view
        ,null as display_ads_tag
        ,null as broad_order_1d
        ,deduct_unique_id
        ,null as target_cir
        ,null as item_price
        ,grass_region
        ,null as vv_id
        ,null as creator_id
        ,null as video_play_complete
        ,null as raw_impression
        ,null as raw_product_click
        ,null as decoded_video_id
        ,null as new_product_boost_coef
        ,null as new_product_boost_stage
        ,null as bid_voucher_id
        ,null as voucher_deduction_price
        ,null as deduction_price
        ,null as voucher_details
        ,null as ads_voucher_auto_claimed
        ,null as page_view
        ,null as ctx_item_type
        ,null as v_model_id
        ,null as v_item_id
        ,null as model_id
        ,null as order_item_has_spu_vmodel
        ,null as paid_order_gmv
        ,null as algo_json_data
        ,deduct_timestamp
        ,null as deduct_order
        ,null as cps_dedup_click
        ,null as deduplicated_click
        ,null as click_time_daily_budget
        ,null as expected_revenue
        ,null as original_deduct_unique_id
        ,null as original_order_timestamp
        ,null as receivable_revenue
        ,null as creative_algo
        ,null as shop_recall_type
        ,null as no_click_order
        ,null as no_click_item_count
        ,null as no_click_gmv
        ,null as bid_rerank_trace  
        ,null as uni_pcr_model_name
        ,null as item_price_shop
        ,null as avg_sold_cnt_shop
        ,null as avg_sold_cnt_item
        ,null as plan_bucket_list
        ,expense_rebate_free_credit_without_expiry
        ,null as ad_tag
        ,streamer_id
        ,null as original_itemid
        ,null as mapped_ads_itemid
        ,null as duplicate_label
        ,null as imp_attr_order_cnt
        ,null as imp_attr_order_item_sold_cnt
        ,null as imp_attr_order_gmv
        ,null as imp_attr_agent_order_cnt
        ,null as imp_attr_agent_item_sold_cnt
        ,null as imp_attr_agent_order_gmv
        ,null as shop_exp_tag

        ,null as imp_attr_paid_order_cnt
        ,null as imp_attr_paid_order_item_sold_cnt
        ,null as imp_attr_paid_order_gmv
        ,null as paid_order_item_sold_cnt
        ,null as paid_broad_order_cnt
        ,null as paid_broad_order_gmv
        ,null as paid_broad_order_item_sold_cnt
        ,null as paid_checkout_cnt

        ,null as paid_agent_checkout_cnt
        ,null as paid_no_click_order_item_sold_cnt
        ,null as paid_no_click_order_gmv
        ,null as paid_no_click_order_cnt
        ,null as shop_view
        ,null as shop_video_play
        ,null as shop_video_play_complete
        ,null as shop_video_play_time
        ,null as shop_video_click
        ,null as brand_max_target_type
        ,null as imp_timestamp

        ,null as agent_order_cnt
        ,null as agent_order_item_sold_cnt
        ,null as agent_order_gmv
        ,null as agent_checkout_cnt

        ,null as paid_agent_order_cnt
        ,null as paid_agent_order_item_sold_cnt
        ,null as paid_agent_order_gmv  
        ,null as traffic_bucket_list
        ,null as is_ocpm
        ,deduction_reason
        ,null as keywords_group_type
        ,null as brand_max_ads_type
        ,null as package_request_id
        ,null as package_request_asset_id
        ,null as non_fraud_click
        ,null as boost_deduction_price
        ,null as is_preselected_vmodel
from    cpm_deduction_issue_fix

union all 

select  ads_id
        ,null as broad_gmv_amt_local
        ,null as broad_item_cnt
        ,null as broad_order_cnt
        ,null as broad_shop_item_click_cnt
        ,null as broad_shop_item_impression_cnt
        ,campaign_id
        ,click as click_cnt
        ,click_timestamp
        ,from_unixtime(click_timestamp, 'yyyy-MM-dd HH:mm:ss') as  click_datetime
        ,cost / 100000.0 as expenditure_amt_local
        ,null as daily_order_cnt
        ,null as daily_gmv_amt_local
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,null as impression_cnt
        ,item_id
        ,keyword
        ,location_in_ads
        ,match_type
        ,null as order_cnt
        ,null as checkout_cnt
        ,null as ads_item_sold_cnt
        ,null as ads_order_gmv_local
        ,null as order_id
        ,placement
        ,query
        ,null as click_before_deduction_cnt
        ,user_id
        ,request_id
        ,shop_id
        ,null as shop_item_click_cnt
        ,null as shop_item_impression_cnt
        ,to_json(bs) as matched_premium_segment
        ,bs.segmentTypeId as matched_premium_segment_type_id
        ,bs.info[0].segmentValueId as matched_premium_segment_value_id
        ,timestamp
        ,null as event_timestamp
        ,null as event_datetime
        ,null as is_cod
        ,null as confirmed_order_cnt
        ,null as paid_order_cnt
        ,null as paid_timestamp
        ,null as paid_datetime
        ,null as confirmed_timestamp
        ,null as confirmed_datetime
        ,signature as ab_sign
        ,entrance as entrance
        ,pricing_type
        ,null as add_to_cart_cnt
        ,null as add_to_cart_without_clicks_cnt
        ,null as broad_add_to_cart_cnt
        ,raw_request_id
        ,location
        ,platform
        ,null as raw_click_cnt
        ,null as search_origin_bid_price_local
        ,null as search_bid_type
        ,sub_entrance
        ,video_id
        ,creative_id
        ,null as image_id
        ,null as search_capped_price
        ,null as account_id
        ,ls_session_id
        ,null as view
        ,null as view_duration
        ,null as product_click
        ,null as deduct_impression
        ,null as non_fraud_impression
        ,null as cpm 
        ,null as  expense_by_cpm
        ,click_area
        ,display_video_id
        ,ta_group_id  
        ,from_json(ta_matched_tag_ids, 'array <int>') as ta_matched_tag_ids
        ,ta_premium_rate 
        ,null as  origin_item_id
        ,app_version
        ,null as origin_bid_price
        ,raw_expense
        ,null as daily_order_amount
        ,null as slot_id
        ,click_event_id
        ,page_type
        ,page_section
        ,target_type
        ,search_scenario
        ,search_entrance
        ,search_mid
        ,attr_data_type
        ,sort_by
        ,new_boost
        ,traffic_source
        ,null as video_view
        ,display_ad_tag as display_ads_tag
        ,null as broad_order_1d
        ,deduct_unique_id
        ,target_cir
        ,item_price
        ,grass_region
        ,null as vv_id
        ,null as creator_id
        ,null as video_play_complete
        ,null as raw_impression
        ,null as raw_product_click
        ,decode_video_id(video_id) as decoded_video_id
        ,new_product_boost_coef
        ,new_product_boost_stage
        ,bid_voucher_id
        ,voucher_deduction_price / 100000.0 as voucher_deduction_price
        ,(COALESCE(deduction_price_0,0) + COALESCE(voucher_deduction_price,0)) / 100000.0 as deduction_price
        ,voucher_details
        ,null as ads_voucher_auto_claimed
        ,null as page_view
        ,ctx_item_type
        ,v_model_id
        ,v_item_id
        ,model_id
        ,null as order_item_has_spu_vmodel
        ,null as paid_order_gmv
        ,algo_json_data
        ,deduct_timestamp
        ,deduct_order
        ,null as cps_dedup_click
        ,null as deduplicated_click
        ,click_time_daily_budget
        ,expected_revenue
        ,original_deduct_unique_id
        ,original_order_timestamp
        ,receivable_revenue
        ,creative_algo
        ,null as shop_recall_type
        ,null as no_click_order
        ,null as no_click_item_count
        ,null as no_click_gmv
        ,bid_rerank_trace  
        ,uni_pcr_model_name
        ,item_price_shop
        ,avg_sold_cnt_shop
        ,avg_sold_cnt_item
        ,plan_bucket_list
        ,expense_rebate_free_credit_without_expiry
        ,ad_tag
        ,streamer_id
        ,original_itemid
        ,mapped_ads_itemid
        ,null as duplicate_label
        ,null as imp_attr_order_cnt
        ,null as imp_attr_order_item_sold_cnt
        ,null as imp_attr_order_gmv
        ,null as imp_attr_agent_order_cnt
        ,null as imp_attr_agent_item_sold_cnt
        ,null as imp_attr_agent_order_gmv
        ,null as shop_exp_tag

        ,null as imp_attr_paid_order_cnt
        ,null as imp_attr_paid_order_item_sold_cnt
        ,null as imp_attr_paid_order_gmv
        ,null as paid_order_item_sold_cnt
        ,null as paid_broad_order_cnt
        ,null as paid_broad_order_gmv
        ,null as paid_broad_order_item_sold_cnt
        ,null as paid_checkout_cnt

        ,null as paid_agent_checkout_cnt
        ,null as paid_no_click_order_item_sold_cnt
        ,null as paid_no_click_order_gmv
        ,null as paid_no_click_order_cnt
        ,null as shop_view
        ,null as shop_video_play
        ,null as shop_video_play_complete
        ,null as shop_video_play_time
        ,null as shop_video_click
        ,null as brand_max_target_type
        ,null as imp_timestamp

        ,null as agent_order_cnt
        ,null as agent_order_item_sold_cnt
        ,null as agent_order_gmv
        ,null as agent_checkout_cnt

        ,null as paid_agent_order_cnt
        ,null as paid_agent_order_item_sold_cnt
        ,null as paid_agent_order_gmv  
        ,traffic_bucket_list
        ,null as is_ocpm
        ,deduction_reason
        ,null as keywords_group_type
        ,null as brand_max_ads_type
        ,null as package_request_id
        ,null as package_request_asset_id
        ,null as non_fraud_click
        ,boost_deduction_price
        ,is_preselected_vmodel
from    cpc_cps_deduction
lateral view outer EXPLODE(buyer_segments) as bs
)
;

create or replace temporary view dim 
as
SELECT
    dim.adsid as ads_id
    ,dim.shopid as shop_id
    ,dim.grass_region
    ,ex.exchange_rate
FROM 
(
    select adsid, shopid ,upper('${region}') as grass_region
    from mp_paidads.shopee_ads_${region}_shard_db__advertisement_tab__reg_continuous_s0_live 
    group by  adsid, shopid
)  dim
LEFT OUTER JOIN 
(
  select grass_region,exchange_rate
  from mp_order.dim_exchange_rate__reg_s0_live
  where grass_date = date('${grass_date}')
  and grass_region = upper('${region}')
) ex
ON dim.grass_region = ex.grass_region;

create or replace temporary view target_audience_info 
as 
select campaignid as campaign_id, shopid as shop_id, groupid as ta_group_id,
flatten(filter(from_json(_decoded_extinfo, 'struct<option_tags:array<
                struct<option:int, tag_id_list:array<int>>>>').option_tags.tag_id_list, x -> x IS NOT NULL)) as tag_ids 
from mp_paidads.shopee_ads_${region}_shard_db__target_audience_group_tab__reg_continuous_s0_live;

INSERT OVERWRITE TABLE dwd_advertise_performance_di__reg_s0_live partition (tz_type='local', grass_region, grass_date)
    select
     a.ads_id
        ,broad_gmv_amt_local
        ,broad_item_cnt
        ,broad_order_cnt
        ,broad_shop_item_click_cnt
        ,broad_shop_item_impression_cnt
        ,a.campaign_id
        ,click_cnt
        ,click_timestamp
        ,click_datetime
        ,expenditure_amt_local
        ,daily_order_cnt
        ,daily_gmv_amt_local
        ,expense_free_credit_with_expiry
        ,expense_free_credit_without_expiry
        ,expense_paid_credit_with_expiry
        ,expense_paid_credit_without_expiry
        ,impression_cnt
        ,a.item_id
        ,keyword
        ,location_in_ads
        ,match_type
        ,order_cnt
        ,checkout_cnt
        ,ads_item_sold_cnt
        ,ads_order_gmv_local
        ,order_id
        ,a.placement
        ,query
        ,click_before_deduction_cnt
        ,user_id
        ,request_id
        --fix shop_id is null bug
        ,coalesce(a.shop_id, c.shop_id) as shop_id
        ,shop_item_click_cnt
        ,shop_item_impression_cnt
        ,matched_premium_segment
        ,matched_premium_segment_type_id
        ,matched_premium_segment_value_id
        ,event_timestamp
        ,event_datetime
        ,is_cod
        ,confirmed_order_cnt
        ,paid_order_cnt
        ,paid_timestamp
        ,paid_datetime
        ,confirmed_timestamp
        ,confirmed_datetime
        ,ab_sign
        ,entrance
        ,a.pricing_type
        ,add_to_cart_cnt
        ,add_to_cart_without_clicks_cnt
        ,broad_add_to_cart_cnt
        ,raw_request_id
        ,location
        ,platform
        ,raw_click_cnt
        ,search_origin_bid_price_local
        ,search_bid_type
        ,sub_entrance
        ,expenditure_amt_local / exchange_rate as expenditure_amt_usd
        ,ads_order_gmv_local / exchange_rate as ads_order_gmv_usd
        ,video_id
        ,creative_id
        ,image_id
        ,search_capped_price
        ,account_id
        ,ls_session_id
        ,view
        ,view_duration
        ,product_click
        ,deduct_impression
        ,non_fraud_impression
        ,cpm 
        ,expense_by_cpm
        ,click_area
        ,display_video_id
        ,a.ta_group_id  
        ,ta_matched_tag_ids
        ,ta_premium_rate 
        ,origin_item_id
        ,tag_ids
        ,CASE 
          -- 处理空值
          WHEN app_version IS NULL THEN NULL
          
          -- 处理已经包含点号的格式
          WHEN app_version RLIKE '^[0-9]+\\.[0-9]+\\.[0-9]+$' THEN app_version
    
          -- 处理5位数字的情况 (如 31007)
          WHEN app_version RLIKE '^[0-9]{5}$' THEN 
            CONCAT_WS('.', 
              SUBSTR(app_version, 1, 1),    -- 第一位作为主版本号
              SUBSTR(app_version, 2, 2),    -- 直接截取第2-3位作为次版本号
              SUBSTR(app_version, 4, 2)     -- 直接截取第4-5位作为修订号
            )

          -- 其他异常情况保持原样
          ELSE app_version
        END AS app_version
        ,origin_bid_price
        ,raw_expense
        ,daily_order_amount
        ,slot_id
        ,click_event_id
        ,page_type
        ,page_section
        ,target_type
        ,search_scenario
        ,search_entrance
        ,search_mid
        ,attr_data_type
        ,sort_by
        ,new_boost
        ,traffic_source
        ,video_view
        ,display_ads_tag
        ,broad_order_1d
        ,deduct_unique_id
        ,target_cir
        ,item_price
        ,vv_id
        ,creator_id
        ,video_play_complete
        ,raw_impression
        ,raw_product_click
        ,if(view_duration*1.000/1000 >= 3,1,0) as video_play_3s_cnt
        ,if(view_duration*1.000/1000 >= 5,1,0) as video_play_5s_cnt
        ,decoded_video_id
        ,new_product_boost_coef
        ,new_product_boost_stage
        ,bid_voucher_id
        ,voucher_deduction_price
        ,deduction_price
        ,null as voucher_details
        ,ads_voucher_auto_claimed
        ,page_view
        ,ctx_item_type
        ,v_model_id
        ,v_item_id
        ,model_id
        ,order_item_has_spu_vmodel
        ,paid_order_gmv as paid_order_gmv_local
        ,paid_order_gmv/ exchange_rate as paid_order_gmv_usd
        ,algo_json_data
        ,deduct_timestamp
        ,deduct_order
        ,cps_dedup_click
        ,deduplicated_click
        ,broad_gmv_amt_local / exchange_rate as broad_gmv_amt_usd
        ,from_unixtime(deduct_timestamp, 'yyyy-MM-dd HH:mm:ss') as deduct_datetime
        ,click_time_daily_budget
        ,expected_revenue
        ,original_deduct_unique_id
        ,original_order_timestamp
        ,receivable_revenue
        ,creative_algo
        ,shop_recall_type
        ,no_click_order
        ,no_click_item_count
        ,no_click_gmv
        ,bid_info_decode_func(bid_rerank_trace) as bid_rerank_trace  
        ,uni_pcr_model_name
        ,item_price_shop / 100000.0 as item_price_shop
        ,avg_sold_cnt_shop
        ,avg_sold_cnt_item
        ,plan_bucket_list
        ,cast(get_json_object(bid_info_decode_func(bid_rerank_trace),'$.idx_roi_upper_bound') as double) as roi_upper_bound
        ,ad_tag 
        ,(ad_tag & 140737488355328) > 0 as rapid_boost_toggle
        ,if((ad_tag & 4398046511104) > 0, 'cold start','mature') AS rapid_boost_state
        ,expense_rebate_free_credit_without_expiry
        ,to_json(voucher_details) as voucher_details_json
        ,original_itemid
        ,mapped_ads_itemid
        ,duplicate_label
        ,streamer_id
        ,imp_attr_order_cnt
        ,imp_attr_order_item_sold_cnt
        ,imp_attr_order_gmv
        ,imp_attr_order_gmv / exchange_rate as imp_attr_order_gmv_usd
        ,imp_attr_agent_order_cnt
        ,imp_attr_agent_item_sold_cnt
        ,imp_attr_agent_order_gmv
        ,imp_attr_agent_order_gmv / exchange_rate as imp_attr_agent_order_gmv_usd
        ,shop_exp_tag

        ,imp_attr_paid_order_cnt
        ,imp_attr_paid_order_item_sold_cnt
        ,imp_attr_paid_order_gmv
        ,imp_attr_paid_order_gmv / exchange_rate as imp_attr_paid_order_gmv_usd
        ,paid_order_item_sold_cnt
        ,paid_broad_order_cnt
        ,paid_broad_order_gmv
        ,paid_broad_order_item_sold_cnt
        ,paid_broad_order_gmv / exchange_rate as paid_broad_gmv_usd
        ,timestamp
        ,paid_checkout_cnt

        ,paid_agent_checkout_cnt
        ,paid_no_click_order_item_sold_cnt
        ,paid_no_click_order_gmv
        ,paid_no_click_order_cnt
        ,shop_view
        ,shop_video_play
        ,shop_video_play_complete
        ,shop_video_play_time
        ,shop_video_click
        ,brand_max_target_type
        ,imp_timestamp
        ,paid_no_click_order_gmv / exchange_rate as paid_no_click_order_gmv_usd
        ,no_click_gmv / exchange_rate as no_click_gmv_usd
        ,agent_order_cnt
        ,agent_order_item_sold_cnt
        ,agent_order_gmv
        ,agent_order_gmv / exchange_rate as agent_order_gmv_usd
        ,agent_checkout_cnt

        ,paid_agent_order_cnt
        ,paid_agent_order_item_sold_cnt
        ,paid_agent_order_gmv  
        ,paid_agent_order_gmv / exchange_rate as paid_agent_order_gmv_usd
        ,traffic_bucket_list
        ,is_ocpm
        ,deduction_reason
        ,keywords_group_type
        ,brand_max_ads_type
        ,package_request_id
        ,package_request_asset_id
        ,non_fraud_click
        ,(ad_tag & 2097152) > 0 as campaign_surge_toggle
        ,boost_deduction_price
        ,is_preselected_vmodel
        ,upper('${region}') as grass_region
        ,date('${grass_date}') as grass_date
from    base a
left join dim c 
on a.grass_region = c.grass_region
and a.ads_id = c.ads_id
left join target_audience_info d
on a.campaign_id = d.campaign_id
and a.shop_id = d.shop_id
and a.ta_group_id = d.ta_group_id
;