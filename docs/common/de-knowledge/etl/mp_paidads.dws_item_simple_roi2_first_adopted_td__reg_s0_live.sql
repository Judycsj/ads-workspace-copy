-- task_code: data_paidadsmart.studio_7222420  asset_id: 7222420
CREATE EXTERNAL TABLE IF NOT EXISTS dws_item_simple_roi2_first_adopted_td__reg_s0_live
(   
    item_id bigint
    ,shop_id bigint
    ,seller_id bigint
    ,level1_global_be_category_id bigint
    ,level1_global_be_category string
    ,level2_global_be_category_id bigint
    ,level2_global_be_category string
    ,level3_global_be_category_id bigint
    ,level3_global_be_category string
    ,item_first_adopted_date date
    ,is_migrated_item tinyint
)
COMMENT 'simple roi2 item first adopted date'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dws_item_simple_roi2_first_adopted_td__reg_s0_live/'
;

CREATE EXTERNAL TABLE IF NOT EXISTS dws_item_simple_roi2_first_adopted_td__${region}_s0_live
(   
    item_id bigint
    ,shop_id bigint
    ,seller_id bigint
    ,level1_global_be_category_id bigint
    ,level1_global_be_category string
    ,level2_global_be_category_id bigint
    ,level2_global_be_category string
    ,level3_global_be_category_id bigint
    ,level3_global_be_category string
    ,item_first_adopted_date date
    ,is_migrated_item tinyint
)
COMMENT 'simple roi2 item first adopted date'
partitioned by
(
     grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dws_item_simple_roi2_first_adopted_td__reg_s0_live/tz_type=local/grass_region=${upper_region}'
;

insert overwrite table dws_item_simple_roi2_first_adopted_td__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select 
    a.item_id 
    ,shop_id
    ,seller_id
    ,level1_global_be_category_id
    ,level1_global_be_category
    ,level2_global_be_category_id
    ,level2_global_be_category
    ,level3_global_be_category_id
    ,level3_global_be_category
    ,item_first_adopted_date
    ,COALESCE(is_migrated_item, 0) as is_migrated_item
    ,'${upper_region}' as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from 
(
    select 
        item_id 
        ,min(item_first_adopted_date) as item_first_adopted_date
        ,max(is_migrated_item) as is_migrated_item
    from 
    (
        select 
            a.item_id 
            ,item_first_adopted_date
            ,is_migrated_item
        from
        (
            select 
                item_id 
                ,date('${BIZ_YESTERDAY}') as item_first_adopted_date
            from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
            where tz_type = 'local'
            and grass_date = date('${BIZ_YESTERDAY}')
            and grass_region = '${upper_region}'
            and placement = 50
            and item_id > 0
            and impression_cnt > 0
            group by item_id
        )a 
        LEFT OUTER JOIN
        (
            select 
                    item_id 
                    ,1 as is_migrated_item
                from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
                where tz_type = 'local'
                and grass_date = date('${BIZ_YESTERDAY}')
                and grass_region = '${upper_region}'
                and item_id > 0
                and (is_ads_active = 1 or impression_cnt > 0)
                and (pricing_type = 3 or (pricing_type in (4, 8) and placement not in (20,2003,2030)))
                group by item_id
        ) b
        ON a.item_id = b.item_id

        union all 

        select 
            item_id
            ,item_first_adopted_date
            ,is_migrated_item
        from mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live
        where tz_type = 'local'
        and grass_region = '${upper_region}'
        and grass_date = date('${PREV_2D}')
        and item_id > 0
    )
    group by item_id 
)a
LEFT OUTER JOIN
(
    SELECT
        distinct 
        item_id
        ,shop_id
        ,seller_id
        ,level1_global_be_category_id
        ,level1_global_be_category
        ,level2_global_be_category_id
        ,level2_global_be_category
        ,level3_global_be_category_id
        ,level3_global_be_category
    FROM mp_item.dim_item__reg_s0_live
    WHERE tz_type = 'local'
    and grass_date = date('${BIZ_YESTERDAY}')
    and grass_region = '${upper_region}'
) b
ON a.item_id = b.item_id
;

alter table dws_item_simple_roi2_first_adopted_td__${region}_s0_live add if not exists partition (grass_date = "${BIZ_YESTERDAY}");