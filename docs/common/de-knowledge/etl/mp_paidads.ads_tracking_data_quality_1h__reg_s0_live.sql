-- task_code: data_paidadsmart.studio_7130645  asset_id: 7130645
-- drop table ads_tracking_data_quality_1h__reg_s0_live;




CREATE TABLE IF NOT EXISTS ads_tracking_data_quality_1h__reg_s0_live (
    grass_region string,
    entrance string,
    row_count bigint,
    pricing_type__column_count bigint,
    pricing_type_null_count bigint,
    ads_id__column_count bigint,
    ads_id_null_count bigint,
    item_id__column_count bigint,
    item_id_null_count bigint,
    shop_id__column_count bigint,
    shop_id_null_count bigint,
    placement__column_count bigint,
    placement_null_count bigint,
    entrance__column_count bigint,
    entrance_null_count bigint,
    request_id__column_count bigint,
    request_id_null_count bigint
)
COMMENT 'table for ads_tracking_data_quality_1h__reg_s0_live'
PARTITIONED BY (
    grass_date date COMMENT 'partition key, yyyy-MM-dd',
    h int COMMENT 'partition key'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/ads_tracking_data_quality_1h__reg_s0_live';

create or replace temporary view tracking_base
as
select
    grass_region,
    grass_date,
    h,
    COALESCE(get_json_object(item.json_data, '$.entrance'), get_json_object(json_data, '$.entrance')) as entrance,
    get_json_object(item.json_data, '$.pricing_type') as pricing_type,
    item.adsid as ads_id,
    item.itemid as item_id
    ,item.shopid as shop_id
    ,COALESCE(item.internal.deduction_info.placement, cast(get_json_object(item.json_data, '$.placement') as bigint), cast(get_json_object(json_data, '$.placement') as bigint)) as placement
    ,COALESCE(get_json_object(item.json_data, '$.request_id'), get_json_object(json_data, '$.request_id')) as request_id
from mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
lateral view explode(items)  as item
where grass_date = date '${BIZ_DT}' and h = ${BIZ_H} and operation in (1,2) and item.adsid > 0;


INSERT OVERWRITE TABLE ads_tracking_data_quality_1h__reg_s0_live PARTITION (grass_date, h)
select
    grass_region,
    entrance,
    count(1) as row_count
    ,count(pricing_type) as pricing_type__column_count
    ,sum(
        case
            when pricing_type is null then 1
            else 0
        end
    ) as pricing_type_null_count
    ,count(ads_id) as ads_id__column_count
    ,sum(
        case
            when ads_id is null then 1
            else 0
        end
    ) as ads_id_null_count
    ,count(item_id) as item_id__column_count
    ,sum(
        case
            when item_id <= 0  then 1
            else 0
        end
    ) as item_id_null_count
    ,count(shop_id) as shop_id__column_count
    ,sum(
        case
            when shop_id <= 0 then 1
            else 0
        end
    ) as shop_id_null_count
    ,count(placement) as placement__column_count
    ,sum(
        case
            when placement < 0 then 1
            else 0
        end
    ) as placement_null_count
    ,count(entrance) as entrance__column_count
    ,sum(
        case
            when entrance is null then 1
            else 0
        end
    ) as entrance_null_count
    ,count(request_id) as request_id__column_count
    ,sum(
        case
            when request_id is null then 1
            else 0
        end
    ) as request_id_null_count
    ,grass_date
    ,h
from tracking_base
group by grass_region, grass_date, h, entrance;


-- select * from ads_tracking_data_quality_1h__reg_s0_live;