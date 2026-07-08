-- task_code: data_paidadsmart.studio_9895864  asset_id: 9895864
-- blacklist
create external table if not exists dim_roi2_auto_rebate_blacklist__reg_s0_live 
(
	shop_id BIGINT comment 'shop_id'
	,blacklist_date date comment '黑名单日期'
) 
partitioned by
(
    grass_region string comment 'region'
    ,grass_date DATE comment 'date'
)
stored as parquet
location "${HIVE_PATH}/dim_roi2_auto_rebate_blacklist__reg_s0_live"
;

INSERT OVERWRITE TABLE dim_roi2_auto_rebate_blacklist__reg_s0_live PARTITION (grass_region, grass_date)
select entity_id as shop_id
    ,date(create_datetime) as blacklist_date
    ,upper('${region}') as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from mp_seller.dim_seller_tag_entity__reg_live 
where grass_region = UPPER('${region}') and grass_date = date('${BIZ_YESTERDAY}') and is_valid=1 and entity_type='ENTITY_TYPE_SHOP' and tag_name = '1P_SIP'
;