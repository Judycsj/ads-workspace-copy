-- task_code: data_paidadsmart.studio_7501973  asset_id: 7501973
create or replace temporary view item_order as 
select
    item_id
    ,create_datetime
    ,create_timestamp
    ,count(distinct order_id) as platform_order_acc
    ,round((unix_timestamp(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')) - unix_timestamp(create_datetime)) / 86400, 4) as create_day_cnt
    ,count(distinct order_id) / round((unix_timestamp(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')) - unix_timestamp(create_datetime)) / 86400, 4) as platform_order_avg
    ,grass_region
    ,cast(grass_date as date) as grass_date
    ,cast(h as tinyint) as h
from
    (
        select
            item.item_id
            ,item.create_datetime
            ,item.create_timestamp
            ,o.order_id
            ,item.grass_region
            ,item.grass_date
            ,item.h
        from
            (
                select
                    item_id
                    ,create_datetime
                    ,create_timestamp
                    ,grass_region
                    ,'${BIZ_DT}' as grass_date
                    ,'${BIZ_H}' as h
                from mp_item.rt_dim_item__reg_s0_live
                where
                    status = 1
                    and grass_region = '${grass_region}'
                    and date(create_datetime) >= date_sub(DATE(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')), 20) --调度时间转local，并减20天
                    and create_datetime <= FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')
            ) item
            left join (
                --实时订单
                select
                    order_be_status_id
                    ,item_id
                    ,order_id
                    ,create_timestamp
                    ,create_datetime
                    ,grass_region
                    ,grass_date
                from mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live
                where
                    order_be_status_id in (1,2,4,6,7,8,9,10,11,12,13,14,15,16)
                    and grass_region = '${grass_region}'
                    and date(create_datetime) >= date_sub(DATE(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')), 5) --调度时间转local，实时订单
                    and create_datetime <= FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${BIZ_DT}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')
                union all
                --离线订单
                select 
                    order_be_status_id
                    ,item_id
                    ,order_id
                    ,create_timestamp
                    ,create_datetime
                    ,grass_region
                    ,grass_date
                from mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp
                where 
                    grass_region = '${grass_region}'
                    and grass_date = '${grass_date}'
            ) o on item.item_id = o.item_id
            and item.grass_region = o.grass_region
            and o.create_datetime >= item.create_datetime
            and UNIX_TIMESTAMP(o.create_datetime) <= (UNIX_TIMESTAMP(item.create_datetime) + 1728000) --item创建后20天内订单
    )
group by item_id, create_datetime, create_timestamp, grass_region, grass_date, h
;

create or replace temporary view item_imp as 
select 
    item_id,
    platform_impression_cnt_10d,
    platform_click_cnt_10d
from mp_paidads.dws_item_simple_roi2_npb_created_nd__reg_s0_live
where grass_region = '${grass_region}'
and grass_date = date'${grass_date}'
;

insert overwrite table ads_simple_roi2_npb_item_hi__reg_s0_live partition (tz_type, grass_region, grass_date,h)
select 
    t1.item_id
    ,t1.create_datetime
    ,t1.create_timestamp
    ,COALESCE(t2.platform_impression_cnt_10d, 0) as platform_impression_acc
    ,COALESCE(t2.platform_click_cnt_10d, 0) as platform_click_acc
    ,t1.platform_order_acc
    ,t1.create_day_cnt
    ,t1.platform_order_avg
    ,'local' as tz_type
    ,t1.grass_region
    ,t1.grass_date
    ,t1.h
from item_order t1
left join item_imp t2
on t1.item_id = t2.item_id
;