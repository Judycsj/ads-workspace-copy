-- task_code: data_paidadsmart.studio_7431782  asset_id: 7431782
SET hoodie.write.concurrency.mode=optimistic_concurrency_control;
SET hoodie.cleaner.policy.failed.writes=LAZY;
SET hoodie.write.lock.provider=org.apache.hudi.client.transaction.lock.FileSystemBasedLockProvider;
SET hoodie.write.lock.filesystem.path=${HIVE_PATH}/dwd_request_livestream_rank_pcoc_hi__reg_s0_live/lock/6h;
SET hoodie.clean.automatic=FALSE;

create or replace temporary view rank_pcr as 
select 
    request_id
    ,user_id
    ,placement
    ,ads_id
    ,ls_session_id
    ,streamer_id
    ,streamer_type
    ,pctr
    ,pcr
    ,pcr_orig
    ,local_date
    ,local_h
    ,grass_region
from mp_paidads.temp_request_livestream_rank_pcr_hi
where grass_region = upper('${region}')
and grass_date = date('${DT_1H}') 
and h = hour(to_timestamp('${TS_1H}', 'yyyy-MM-dd HH'))
;

create or replace temporary view report_ng_request as
select 
    request_id 
    ,ads_id
    ,sum(case when grass_date = date('${DT_1H}') and h = hour(to_timestamp('${TS_1H}', 'yyyy-MM-dd HH')) then view else 0 end) as view_cnt_1h 
    ,sum(case when grass_date = date('${DT_1H}') and h = hour(to_timestamp('${TS_1H}', 'yyyy-MM-dd HH')) then checkout else 0 end) as checkout_cnt_1h
    ,sum(case when grass_date = date('${DT_1H}') and h = hour(to_timestamp('${TS_1H}', 'yyyy-MM-dd HH')) then cost / 100000.0 else 0 end) as ads_rev_local_1h
    ,sum(case when to_timestamp(concat(grass_date,' ',h),'yyyy-MM-dd H') <= to_timestamp('${TS_3H}', 'yyyy-MM-dd HH') then view else 0 end) as view_cnt_3h 
    ,sum(case when to_timestamp(concat(grass_date,' ',h),'yyyy-MM-dd H') <= to_timestamp('${TS_3H}', 'yyyy-MM-dd HH') then checkout else 0 end) as checkout_cnt_3h
    ,sum(case when to_timestamp(concat(grass_date,' ',h),'yyyy-MM-dd H') <= to_timestamp('${TS_3H}', 'yyyy-MM-dd HH') then cost / 100000.0 else 0 end) as ads_rev_local_3h
    ,sum(view) as view_cnt_6h 
    ,sum(checkout) as checkout_cnt_6h
    ,sum(cost) / 100000.0 as ads_rev_local_6h
from mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live
where grass_region = upper('${region}')
and grass_date between date('${DT_1H}') and date('${DT_6H}')
and to_timestamp(concat(grass_date,' ',h),'yyyy-MM-dd H') >= to_timestamp('${TS_1H}', 'yyyy-MM-dd HH')
and to_timestamp(concat(grass_date,' ',h),'yyyy-MM-dd H') <= to_timestamp('${TS_6H}', 'yyyy-MM-dd HH')
and (view > 0 or checkout > 0 or cost > 0)
group by 1,2
;

create or replace temporary view dim_exchage_rate as
select 
    grass_region
    ,exchange_rate
from mp_order.dim_exchange_rate__reg_s0_live
where grass_region = upper('${region}')
and   grass_date = DATE('${BIZ_YESTERDAY}')
;

create or replace temporary view output as 
select 
    a.ads_id  as ads_id
    ,user_id 
    ,a.request_id 
    ,ls_session_id 
    ,streamer_id 
    ,streamer_type 
    ,placement 
    ,pctr 
    ,pcr 
    ,checkout_cnt_1h 
    ,checkout_cnt_3h 
    ,checkout_cnt_6h 
    ,null as checkout_cnt_24h 
    ,null as checkout_cnt_7d 
    ,view_cnt_1h 
    ,view_cnt_3h 
    ,view_cnt_6h 
    ,null as view_cnt_24h 
    ,null as view_cnt_7d 
    ,ads_rev_local_1h / exchange_rate as ads_rev_usd_1h 
    ,ads_rev_local_3h / exchange_rate as ads_rev_usd_3h 
    ,ads_rev_local_6h / exchange_rate as ads_rev_usd_6h 
    ,null as ads_rev_usd_24h 
    ,null as ads_rev_usd_7d 
    ,pcr_orig
    ,a.grass_region as grass_region
    ,local_date as grass_date
    ,local_h as h
from rank_pcr a 
join report_ng_request b 
on a.request_id = b.request_id
and a.ads_id = b.ads_id
left join dim_exchage_rate c 
on a.grass_region = c.grass_region
;

merge into dwd_request_livestream_rank_pcoc_hi__reg_s0_live as t0 using 
(select   
    ads_id
    ,user_id 
    ,request_id 
    ,ls_session_id 
    ,streamer_id 
    ,streamer_type 
    ,placement 
    ,pctr 
    ,pcr 
    ,checkout_cnt_1h 
    ,checkout_cnt_3h 
    ,checkout_cnt_6h 
    ,checkout_cnt_24h 
    ,checkout_cnt_7d 
    ,view_cnt_1h 
    ,view_cnt_3h 
    ,view_cnt_6h 
    ,view_cnt_24h 
    ,view_cnt_7d 
    ,ads_rev_usd_1h 
    ,ads_rev_usd_3h 
    ,ads_rev_usd_6h 
    ,ads_rev_usd_24h 
    ,ads_rev_usd_7d 
    ,pcr_orig
    ,grass_region
    ,grass_date
    ,h
from output 
) as s0 
on  t0.h = s0.h
and t0.grass_region = s0.grass_region 
and t0.grass_date = s0.grass_date 
and t0.ads_id = s0.ads_id 
and t0.user_id = s0.user_id
and t0.request_id = s0.request_id
and t0.ls_session_id = s0.ls_session_id
and t0.placement = s0.placement
and t0.streamer_id = s0.streamer_id
and t0.streamer_type = s0.streamer_type
when matched then UPDATE SET t0.checkout_cnt_3h = s0.checkout_cnt_3h
,t0.view_cnt_3h = s0.view_cnt_3h
,t0.ads_rev_usd_3h = s0.ads_rev_usd_3h
,t0.checkout_cnt_6h = s0.checkout_cnt_6h
,t0.view_cnt_6h = s0.view_cnt_6h
,t0.ads_rev_usd_6h = s0.ads_rev_usd_6h
when not matched then
insert *
;