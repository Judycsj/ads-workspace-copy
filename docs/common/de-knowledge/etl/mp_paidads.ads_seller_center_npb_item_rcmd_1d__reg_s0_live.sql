-- task_code: data_paidadsmart.studio_7729803  asset_id: 7729803
-- drop table ads_seller_center_npb_item_rcmd_1d__reg_s0_live;

CREATE EXTERNAL TABLE IF NOT EXISTS ads_seller_center_npb_item_rcmd_1d__reg_s0_live
(
    key STRING
    ,value STRING
    ,shop_id BIGINT
    ,item_id BIGINT
    ,l30d_sold BIGINT
    ,stock BIGINT
    ,time_added BIGINT
    ,price BIGINT
    ,rcmd_npb_type int 
    ,rcmd_npb_score DOUBLE
    ,ado DOUBLE
)
PARTITIONED BY
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date date comment 'grass_date'
)
STORED AS parquet
LOCATION "${HIVE_PATH}/ads_seller_center_npb_item_rcmd_1d"
;


create or replace temporary view base_item_90 as 
-- create table base_item_90 as
select a.item_id
        ,a.shop_id
        ,a.create_day_cnt
        ,a.create_timestamp as time_added
        ,b.npb_score as rcmd_npb_score
        ,c.platform_order_avg as ado
        -- ,c.platform_order_acc
        ,d.stock
        ,d.price
        ,d.l30d_sold
        ,case when create_day_cnt <= 10 and platform_order_acc=0 and npb_score >= 0.5 then 1 
            when create_day_cnt <= 20 and platform_order_acc>=1 and platform_order_acc <= 20 and platform_order_avg >=0.3 and npb_score >= 0.5 then 2 
            else 3 end as rcmd_npb_type
from (
    select
        item_id
        ,shop_id
        ,create_timestamp
        ,round((unix_timestamp(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${today}',' ', '00:00:00'), 'Asia/Singapore'),'${timezone}')) - unix_timestamp(create_datetime)) / 86400, 4) as create_day_cnt
        ,grass_region
    from mp_item.rt_dim_item__reg_s0_live
    where
        status = 1
        and grass_region = upper('${region}')
        and date(create_datetime) >= (FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${today}',' ', '00:00:00'), 'Asia/Singapore'),'${timezone}') - interval 90 days) --调度时间转local，并减20天
        and create_datetime <= FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT('${today}',' ', '00:00:00'), 'Asia/Singapore'),'${timezone}')
        and item_id not in (
                select distinct item_id 
                from mp_item.dim_item_label_with_level__reg_s0_live
                WHERE grass_date = DATE('${grass_date}') and grass_region = upper('${region}') and label_id in (841356053736030, 843249807227517, 298553329))
)a 
left join (
    select item_id,shop_id,pred_score as npb_score
    from(
        select item_id,shop_id,pred_score
            ,ROW_NUMBER() over(partition by item_id,shop_id order by create_date desc) as rn  
        from szci_traffic.new_item_card_online_item_predict_score_10d_replace_rcmd
        where grass_region = upper('${region}')
            and create_date between date('${PREV_20D}') and date('${grass_date}')
    )
    where rn = 1
)b on a.item_id = b.item_id and a.shop_id = b.shop_id
left join (
    select item_id,platform_order_avg,platform_order_acc
    from mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live
    where tz_type = 'local' and grass_date = DATE('${today}') and grass_region = upper('${region}') and h=1
)c on a.item_id = c.item_id
left join (
    select shopid as shop_id
            ,itemid as item_id
            ,stock
            ,price
            ,l30d_sold
    from mkplpaidads_data.rcmd_score_stats
    where country = upper('${region}') and dt = '${today}'
)d on a.shop_id = d.shop_id AND a.item_id = d.item_id
;


CREATE OR REPLACE TEMPORARY FUNCTION marshal_item as 'com.shopee.deepdata.warehouse.hive.udf.MarshalNpbItem' ;

INSERT OVERWRITE ads_seller_center_npb_item_rcmd_1d__reg_s0_live PARTITION (tz_type='local',grass_date, grass_region)
select CONCAT('item_', upper('${region}'), '_', item_id, ':new_product_boost') AS key 
      ,marshal_item(item_id,CAST(l30d_sold as int),CAST(stock as int),time_added,price,rcmd_npb_type) as value
      ,shop_id
      ,item_id
      ,l30d_sold
      ,stock
      ,time_added
      ,price
      ,rcmd_npb_type
      ,rcmd_npb_score
      ,ado
      ,create_day_cnt
      ,upper('${region}') as grass_region
      ,date('${grass_date}') as grass_date
from base_item_90
;