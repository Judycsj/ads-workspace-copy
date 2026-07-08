-- task_code: data_paidadsmart.studio_7514020  asset_id: 7514020
insert overwrite table dws_item_simple_roi2_npb_created_nd__reg_s0_live partition (tz_type, grass_region, grass_date)
select 
    item.item_id
    ,item.create_datetime
    ,item.create_timestamp
    ,sum(if(date(item.create_datetime)>= date_sub(item_metric.grass_date,10),item_metric.imp_cnt_1d,0)) as imp_cnt_acc
    ,sum(if(date(item.create_datetime)>= date_sub(item_metric.grass_date,10),item_metric.click_cnt_1d,0)) as click_cnt_acc
    ,sum(if(date(item.create_datetime)>= date_sub(item_metric.grass_date,20),item_metric.atc_cnt_1d,0)) as atc_cnt_acc
    ,'local' as tz_type
    ,'${grass_region}' as grass_region
    ,cast('${grass_date}' as date) as grass_date
from 
    (
        select
            item_id
            ,create_datetime
            ,create_timestamp
        from mp_item.rt_dim_item__reg_s0_live
        where
            status = 1
            and grass_region = '${grass_region}'
            --近20天创建的item
            and date(create_datetime) >= date_sub(DATE(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${grass_date}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}')), 20) --调度时间转local，并减20天
            and date(create_datetime) <= date(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${grass_date}', ' ', lpad('${BIZ_H}', 2, 0), ':00:00'), 'Asia/Singapore'),'${timezone}'))
    ) item
left join
    (
        select
            item_id
            ,imp_cnt_1d
            ,click_cnt_1d
            ,atc_cnt_1d
            ,grass_region
            ,grass_date
        from traffic.dws_item_metric_1d__reg_live
        where
            grass_region = '${grass_region}'
            and grass_date >= date_sub('${grass_date}',20)
            and grass_date <= date('${grass_date}')
    ) item_metric
on item.item_id = item_metric.item_id
and date(item.create_datetime) <= item_metric.grass_date
group by     
    item.item_id
    ,item.create_datetime
    ,item.create_timestamp