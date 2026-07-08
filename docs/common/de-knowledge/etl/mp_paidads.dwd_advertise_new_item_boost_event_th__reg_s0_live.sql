-- task_code: data_paidadsmart.studio_8170260  asset_id: 8170260
create external table if not exists dwd_advertise_new_item_boost_event_th__reg_s0_live
(
    ads_id bigint
    ,broad_order bigint
    ,timestamp bigint
)
partitioned by
(
    grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
    ,h int comment 'hour'
)
stored as PARQUET
location '${HIVE_PATH}/dwd_advertise_new_item_boost_event_th';

REFRESH TABLE mp_paidads.ods_log_ads_report_hi__reg_s0_live;

INSERT OVERWRITE TABLE dwd_advertise_new_item_boost_event_th__reg_s0_live
partition (grass_region, grass_date, h)

select /*+ REPARTITION(10) */ 
ads_id,broad_order,timestamp,
grass_region,
date"${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1h')}" as grass_date,
${bizTimeFormatter(BIZ_TIME,'H','-1h')} as h
from (
select 
ads_id,broad_order,timestamp,
grass_region
from mp_paidads.ods_log_ads_report_hi__reg_s0_live
where h = ${bizTimeFormatter(BIZ_TIME,'H','-1h')}
    and grass_date = date"${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1h')}"
    and pricing_type=13
    and broad_order>0
    and timestamp > 0
    
union all 

select 
ads_id,broad_order,timestamp,
grass_region
from mp_paidads.dwd_advertise_new_item_boost_event_th__reg_s0_live
where h = ${bizTimeFormatter(BIZ_TIME,'H','-2h')}
    and grass_date = date"${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-2h')}"
)
;