-- task_code: data_paidadsmart.studio_8878261  asset_id: 8878261
create external table if not exists ads_sc_potential_product_ads_item_ado_hourly__reg_s0_live (
    key string 
    ,item_id bigint
    ,l7d bigint comment 'platform order count within last 7 days'
) comment 'scope: potential product item; value: sum of L7d platform order count; hourly updated' partitioned by (
    grass_region string
    ,grass_date date comment 'date'
    ,h tinyint comment 'hour'
) stored as parquet location "${HIVE_PATH}/ads_sc_potential_product_ads_item_ado_hourly__reg_s0_live"
;

create or replace temporary view product_item_rcmd as (
    SELECT t.grass_region
        ,t.item_id
    FROM mp_paidads.ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live t
    JOIN (
        select grass_region, max(grass_date) AS latest_date
        from mp_paidads.ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live
        where grass_region in ('SG', 'MY', 'PH', 'TW', 'ID', 'TH', 'VN', 'BR')
        and grass_date >= date('${PREV_7D}')
        group by grass_region
    ) latest
    ON t.grass_date = latest.latest_date
    and t.grass_region = latest.grass_region
    where t.grass_date >= date('${PREV_7D}')
);

insert overwrite table ads_sc_potential_product_ads_item_ado_hourly__reg_s0_live partition (grass_region, grass_date,h)
select
    concat('item_ado_data:', item.grass_region, '_', item.item_id) as key
    ,item.item_id
    ,coalesce(platform_order_cnt_7d, 0) as l7d
    ,item.grass_region
    ,date('${BIZ_DT}') as grass_date
    ,cast('${BIZ_H}' as tinyint) as h
from product_item_rcmd item
left join (
    select 
        grass_region
        ,item_id 
        ,sum(platform_order_cnt) as platform_order_cnt_7d
    from (
        --实时订单
        select
            grass_region
            ,item_id
            ,count(distinct order_id) as platform_order_cnt
        from mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live
        where
            order_be_status_id in (1,2,4,6,7,8,9,10,11,12,13,14,15,16)
            and grass_region in ('SG', 'MY', 'PH', 'TW', 'ID', 'TH', 'VN', 'BR')
            and create_timestamp > unix_timestamp(date_sub(date('${BIZ_DT}'),2))
            and create_timestamp <= unix_timestamp(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'))
        group by 1, 2

        union all

        --离线订单
        select 
            grass_region
            ,item_id
            ,count(distinct order_id) as platform_order_cnt
        from mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp
        where 
            grass_region in ('SG', 'MY', 'PH', 'TW', 'ID', 'TH', 'VN', 'BR')
            and grass_date = date'${PREV_2D}'
            and create_timestamp >= unix_timestamp(CONCAT(date_sub(date('${BIZ_DT}'),7), ' ', lpad('${BIZ_H}', 2, 0), ':00:00'))
            and create_timestamp <= unix_timestamp(date_sub(date('${BIZ_DT}'),2))
        group by 1 , 2
    )
    group by grass_region
            ,item_id
) o 
on item.grass_region = o.grass_region
and item.item_id = o.item_id
;