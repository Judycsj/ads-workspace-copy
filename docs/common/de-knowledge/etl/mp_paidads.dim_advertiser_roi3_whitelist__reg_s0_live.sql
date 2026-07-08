-- task_code: data_paidadsmart.studio_7785682  asset_id: 7785682
CREATE EXTERNAL TABLE IF NOT EXISTS dim_advertiser_roi3_whitelist__reg_s0_live
(   
    shop_id bigint
    ,whitelist_date date
)
COMMENT 'simple roi2 item first adopted date'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dim_advertiser_roi3_whitelist__reg_s0_live/'
;


insert overwrite table dim_advertiser_roi3_whitelist__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select 
    shop_id
    ,whitelist_date
    ,upper('${region}') as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from 
(
    select 
        shop_id 
        ,min(whitelist_date) as whitelist_date
    from 
    (
       
        select 
            shop_id 
            ,date('${BIZ_YESTERDAY}') as whitelist_date
        from mp_paidads.dim_advertiser__reg_s0_live
        where tz_type = 'local'
        and grass_date = date('${BIZ_YESTERDAY}')
        and grass_region = upper('${region}')
        and shop_id > 0
        and is_roi_three_voucher_enabled > 0
        group by shop_id
        

        union all 

        select 
            shop_id
            ,whitelist_date
        from mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live
        where tz_type = 'local'
        and grass_region = upper('${region}')
        and grass_date = date('${PREV_2D}')
    )
    group by shop_id 
)
;

create or replace view dim_advertiser_roi3_whitelist__${region}_s0_live as 
select *
from dim_advertiser_roi3_whitelist__reg_s0_live
where grass_region = upper('${region}')
;