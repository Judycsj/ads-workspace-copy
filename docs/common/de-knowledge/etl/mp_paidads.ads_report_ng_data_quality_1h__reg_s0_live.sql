-- task_code: data_paidadsmart.studio_7129275  asset_id: 7129275
-- drop table ads_report_ng_data_quality_1h__reg_s0_live;

CREATE TABLE IF NOT EXISTS ads_report_ng_data_quality_1h__reg_s0_live (
    grass_region string,
    entrance int,
    row_count bigint,
    pricing_type__column_count bigint,
    pricing_type_null_count bigint,
    ads_id__column_count bigint,
    ads_id_null_count bigint,
    shop_id__column_count bigint,
    shop_id_null_count bigint,
    placement__column_count bigint,
    placement_null_count bigint,
    entrance__column_count bigint,
    entrance_null_count bigint,
    request_id__column_count bigint,
    request_id_null_count bigint
)
COMMENT 'table for ads_report_ng_data_quality_1h__reg_s0_live'
PARTITIONED BY (
    grass_date date COMMENT 'partition key, yyyy-MM-dd',
    h int COMMENT 'partition key'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/ads_report_ng_data_quality_1h__reg_s0_live';


INSERT OVERWRITE TABLE ads_report_ng_data_quality_1h__reg_s0_live PARTITION (grass_date, h)
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
    ,count(shop_id) as shop_id__column_count
    ,sum(
        case
            when shop_id is null then 1
            else 0
        end
    ) as shop_id_null_count
    ,count(placement) as placement__column_count
    ,sum(
        case
            when placement is null then 1
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
from mp_paidads.ods_log_ads_report_hi__reg_s0_live
where grass_date = date '${BIZ_DT}' and h = ${BIZ_H}
group by grass_region, grass_date, h, entrance;

-- select *
-- from ads_report_ng_data_quality_1h__reg_s0_live;