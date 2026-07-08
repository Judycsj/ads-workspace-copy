-- task_code: data_paidadsmart.studio_9865901  asset_id: 9865901
create table if not exists ads_sc_new_product_boost_new_item_daily__reg_s0_live (
    item_id bigint
    ,shop_id bigint
    ,ctime bigint
    ,pred_score_final double
    ,is_high_quality_item tinyint
    ,cspu_type bigint
    ,item_priority string
    ,is_high_priority_item tinyint
)
comment 'The data scope includes items were created within the past 30 days, with item_status = 1.'
partitioned by
    (grass_region string, grass_date date) stored as PARQUET 
    location "${HIVE_PATH}/ads_sc_new_product_ads/new_item"
;

create table if not exists ads_sc_new_product_boost_high_quality_item_daily__reg_s0_live (
    key string
    ,value string
    ,item_id bigint
    ,shop_id bigint
    ,ctime bigint
    ,pred_score_final double
)
comment 'The data scope includes items were created within the past 30 days, with item_status = 1 and pred_score_final>=0.8'
partitioned by
    (grass_region string, grass_date date) stored as PARQUET 
    location "${HIVE_PATH}/ads_sc_new_product_ads/high_quality_item"
;

create table if not exists ads_sc_new_product_boost_high_quality_shop_daily__reg_s0_live (
    key string
    ,value string
    ,shop_id bigint
    ,item_list array < struct < item_id: bigint ,ctime: bigint > >
)
comment 'The data scope is consistent with ads_sc_new_product_boost_high_quality_item_daily__reg_s0_live, including shop_id and the corresponding item_list.'
partitioned by
    (grass_region string, grass_date date) STORED AS PARQUET 
    location "${HIVE_PATH}/ads_sc_new_product_ads/high_quality_shop"
;

-- new item, only for analysis
insert overwrite table ads_sc_new_product_boost_new_item_daily__reg_s0_live partition (grass_region, grass_date)
select
    a.item_id
    ,shop_id
    ,ctime
    ,pred_score_final
    ,case
        when b.pred_score_final is null then null
        when b.pred_score_final >= 0.8 then 1
        else 0
    end as is_high_quality_item
    ,cspu_type
    ,case 
        when cspu_type in (1,4) then 'P0'
        when cspu_type in (3,6) then 'P1'
        when cspu_type in (2,8) then 'P2'
    end as item_priority
    ,case 
        when cspu_type in (1,4) then 1
        when coalesce(b.pred_score_final, 0) >= 0.8 then 1
        else 0
    end as is_high_priority_item
    ,upper('${region}') as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from
    (
        SELECT 
            d.item_id,
            d.shop_id,
            d.create_timestamp AS ctime,
            d.grass_region
        FROM mp_item.rt_dim_item__reg_s0_live d
        LEFT ANTI JOIN (
            SELECT item_id
            FROM mp_item.dim_item_label_with_level__reg_s0_live
            WHERE grass_date = date('${BIZ_YESTERDAY}')
            AND grass_region = upper('${region}')
            AND label_id IN (841356053736030, 843249807227517, 298553329)
        ) lbl
        ON d.item_id = lbl.item_id
        WHERE d.status = 1
        AND d.grass_region = upper('${region}')
        AND date(d.create_datetime) >= date('${PREV_30D}')
    ) a
    left join (
        select
            item_id
            ,pred_score_final
        from szci_traffic.new_item_model_score_reg_live_for_ads
        where
            grass_region = upper('${region}')
            and grass_date = date('${BIZ_YESTERDAY}')
    ) b on a.item_id = b.item_id
    left join(
        select item_id, cspu_type
        from srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type
        where
            grass_region = upper('${region}')
            and local_date = date('${BIZ_YESTERDAY}')
    )c on a.item_id = c.item_id
;


-- hight quality item, need to write to redis
create or replace temporary function marshal_item as 'com.shopee.deepdata.warehouse.hive.udf.MarshalNPAItem' ;

insert overwrite table ads_sc_new_product_boost_high_quality_item_daily__reg_s0_live partition (grass_region, grass_date)
select
    concat('item_', grass_region, '_', item_id, ':npa') as key
    ,marshal_item (
        item_id
        ,ctime
    ) as value
    ,item_id
    ,shop_id
    ,ctime
    ,pred_score_final
    ,grass_region
    ,grass_date
from ads_sc_new_product_boost_new_item_daily__reg_s0_live
where grass_region = upper('${region}')
and grass_date = date('${BIZ_YESTERDAY}')
and is_high_priority_item = 1
;

-- shop_data, need to write to redis
create or replace temporary function marshal_shop as 'com.shopee.deepdata.warehouse.hive.udf.MarshalNPAShop' ;

insert overwrite ads_sc_new_product_boost_high_quality_shop_daily__reg_s0_live partition (grass_region, grass_date)
select
    concat('shop_', grass_region, '_', shop_id, ':npa') as key
    ,marshal_shop (shop_id, to_json(item_list)) as value
    ,shop_id
    ,item_list
    ,grass_region
    ,grass_date
from
    (
        select
            shop_id
            ,collect_list(item_struct) as item_list
            ,upper('${region}') as grass_region
            ,date('${BIZ_YESTERDAY}') as grass_date
        from
            (
                select
                    shop_id
                    ,struct (item_id, ctime) as item_struct
                    ,row_number() over (
                        partition by shop_id
                        order by ctime asc
                    ) as item_rank
                from ads_sc_new_product_boost_high_quality_item_daily__reg_s0_live
                where
                    grass_region = upper('${region}')
                    and grass_date = date('${BIZ_YESTERDAY}')
                distribute by shop_id
                sort by ctime asc
            )
        where item_rank <= 500
        group by shop_id

    )
;