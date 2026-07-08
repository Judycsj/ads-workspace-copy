-- task_code: data_paidadsmart.studio_2528642  asset_id: 2528642
insert overwrite table dws_advertise_item_performance_1d__reg_s0_live partition (tz_type, grass_region, grass_date)
select  shop_id
        ,user_name
        ,item_id
        ,ads_id
        ,placement
        ,item_name
        ,impression_cnt_1d
        ,click_cnt_1d
        ,expenditure_amt_local_1d
        ,expenditure_amt_usd_1d
        ,COALESCE(expenditure_amt_local_1d / click_cnt_1d, 0.0) as cpc_local_1d
        ,COALESCE(expenditure_amt_usd_1d / click_cnt_1d, 0.0) as cpc_usd_1d
        ,order_cnt_1d
        ,ads_gmv_amt_local_1d
        ,ads_gmv_amt_usd_1d
        ,COALESCE(click_cnt_1d / impression_cnt_1d, 0.0) as ctr_1d
        ,COALESCE(order_cnt_1d / click_cnt_1d, 0.0) as cr_1d
        ,COALESCE(expenditure_amt_local_1d / ads_gmv_amt_local_1d, 0.0) as cir_1d
        ,avg_ads_ranks_1d
        ,tz_type
        ,grass_region
        ,date('${grass_date}') as grass_date
from    (
    select  shop_id
            ,item_id AS item_id
            ,item_name
            ,ads_id
            ,placement
            ,user_name
            ,SUM(CASE WHEN is_today = 1 THEN impression_cnt ELSE 0 END) AS impression_cnt_1d
            ,SUM(CASE WHEN is_today = 1 THEN click_cnt ELSE 0 END) AS click_cnt_1d
            ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_local ELSE 0.0 END) AS expenditure_amt_local_1d
            ,SUM(CASE WHEN is_today = 1 THEN expenditure_amt_usd ELSE 0.0 END) AS expenditure_amt_usd_1d
            ,SUM(CASE WHEN is_today = 1 THEN order_cnt ELSE 0 END) AS order_cnt_1d
            ,SUM(CASE WHEN is_today = 1 THEN ads_gmv_amt_local ELSE 0.0 END) AS ads_gmv_amt_local_1d
            ,SUM(CASE WHEN is_today = 1 THEN ads_gmv_amt_usd ELSE 0.0 END) AS ads_gmv_amt_usd_1d
            ,AVG(CASE WHEN is_today = 1 THEN avg_ads_ranks END) AS avg_ads_ranks_1d
            ,tz_type
            ,grass_region
            ,grass_date
    from    (
        select  shop_id AS shop_id
                ,item_id
                ,item_name
                ,ads_id
                ,placement
                ,seller_name AS user_name
                ,COALESCE(impression_cnt, 0) AS impression_cnt
                ,COALESCE(click_cnt, 0) AS click_cnt
                ,COALESCE(expenditure_amt_local, 0.0) AS expenditure_amt_local
                ,COALESCE(expenditure_amt_usd, 0.0) AS expenditure_amt_usd
                ,COALESCE(order_cnt, 0) AS order_cnt
                ,COALESCE(ads_gmv_amt_local, 0.0) AS ads_gmv_amt_local
                ,COALESCE(ads_gmv_amt_usd, 0.0) AS ads_gmv_amt_usd
                ,COALESCE(avg_ads_ranks, 0.0) AS avg_ads_ranks
                ,case   when grass_date = date('${grass_date}') THEN 1
                        ELSE 0
                 end as is_today
                ,tz_type
                ,grass_date
                ,grass_region
        from    mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live
        where   grass_region = upper('${region}')
          and   grass_date = date('${grass_date}')
    ) t
    where   grass_date = date('${grass_date}')
    group by 1, 2, 3, 4, 5, 6, tz_type, grass_region, grass_date
) parquet_group_by_advertise_query_gmv_event_1d
;

alter table dws_advertise_item_performance_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");