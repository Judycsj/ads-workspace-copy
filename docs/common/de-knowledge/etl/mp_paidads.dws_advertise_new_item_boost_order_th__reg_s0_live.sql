-- task_code: data_paidadsmart.studio_6377529  asset_id: 6377529
create external table if not exists dws_advertise_new_item_boost_order_th__reg_s0_live
(
    ads_id bigint
    ,item_id bigint
    ,start_timestamp bigint
    ,ads_order_cnt_th bigint
    ,paused_hours bigint
)
partitioned by
(
    grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
    ,h int comment 'hour'
)
stored as PARQUET
location '${HIVE_PATH}/dws_advertise_new_item_boost_order_th__reg_s0_live';

-- step1: get all placement=44 
CREATE OR REPLACE TEMPORARY VIEW new_item_boost_ads_all AS
select adsid,campaignid,status,itemid,ctime,mtime
from mp_paidads.shopee_ads_${region}_shard_db__advertisement_tab__reg_continuous_s0_live
where placement=44
;

CREATE OR REPLACE TEMPORARY VIEW campaign_all AS
select campaignid,start_time,end_time,status as campaign_status
     from mp_paidads.shopee_ads_${region}_shard_db__campaign_tab__reg_continuous_s0_live
;

-- step2: get ads real status
-- normal == ads nromal && campaign normal &&  start_time < time < end_time
CREATE OR REPLACE TEMPORARY VIEW new_item_boost_ads_status AS
select ads_id, case when(status = 1 and campaign_status = 1) then 1 else 0 end as status
,itemid as item_id,ctime,mtime
from 
(
    select adsid as ads_id, status,campaignid,itemid,ctime,mtime
    from new_item_boost_ads_all 
) a
left join 
(
    select campaignid,start_time,end_time,
    case when(start_time < unix_timestamp() and (unix_timestamp() < end_time or end_time=0) and campaign_status=1)
    then 1 else 0 end as campaign_status
    from campaign_all
) b
on a.campaignid = b.campaignid
;

-- step3: get ads last_paused_hours and start_timestamp
CREATE OR REPLACE TEMPORARY VIEW new_item_boost_ads AS
select a.ads_id as ads_id,item_id, last_paused_hours,status,
case when(status != 1) then COALESCE(last_paused_hours, 0) + 1 else 0 end as paused_hours,
case when(status = 1 and last_paused_hours > 24*7) then mtime
else COALESCE(start_timestamp, ctime) end as start_timestamp
from
(
    select ads_id, status, item_id,ctime,mtime
    from new_item_boost_ads_status
    
) a
left join 
(
    select ads_id, paused_hours as last_paused_hours, start_timestamp
    from mp_paidads.dws_advertise_new_item_boost_order_th__reg_s0_live
    where h = ${bizTimeFormatter(BIZ_TIME,'H','-2h')}
    and grass_date = date"${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-2h')}"
    and grass_region = upper('${region}')
) b
on a.ads_id = b.ads_id
;

-- step4: get all pricing_type=13 orders
CREATE OR REPLACE TEMPORARY VIEW new_item_boost_ads_orders AS
select ads_id,broad_order,timestamp
from mp_paidads.dwd_advertise_new_item_boost_event_th__reg_s0_live
where h = ${bizTimeFormatter(BIZ_TIME,'H','-1h')}
    and grass_date = date"${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1h')}"
    and grass_region = upper('${region}');

-- step5:
-- if ads not normal and paused_hours > 7*24 then 0 as ads_order_cnt_th
INSERT OVERWRITE TABLE dws_advertise_new_item_boost_order_th__reg_s0_live
partition (grass_region, grass_date, h)
select ads_id,item_id,start_timestamp,
case when(status != 1 and last_paused_hours > 24*7) then 0 else ads_order_cnt_th end as ads_order_cnt_th,
paused_hours,
upper('${region}') as grass_region,
date("${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1h')}") as grass_date,
${bizTimeFormatter(BIZ_TIME,'H','-1h')} as h
from
(
    select ads_id,item_id,start_timestamp,last_paused_hours, paused_hours,status,
    sum(case when(start_timestamp<timestamp) then broad_order else 0 end) as ads_order_cnt_th
    from 
    (
        select a.ads_id,item_id,start_timestamp,broad_order,timestamp,last_paused_hours, paused_hours,status
        from
        (
            select ads_id,item_id,start_timestamp,last_paused_hours, paused_hours,status
            from new_item_boost_ads
        ) a
        left join 
        (
            select ads_id,broad_order,timestamp
            from new_item_boost_ads_orders
        ) b
        on a.ads_id = b.ads_id
    ) group by ads_id,item_id,start_timestamp,last_paused_hours, paused_hours,status
)
;