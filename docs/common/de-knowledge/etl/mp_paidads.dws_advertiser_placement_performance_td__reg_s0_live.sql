-- task_code: data_paidadsmart.studio_3860626  asset_id: 3860626
create external table if not exists dws_advertiser_placement_performance_td__reg_s0_live
(
    shop_id bigint 
    ,placement bigint
    ,impression_cnt_td bigint
    ,click_cnt_td bigint
    ,order_cnt_td bigint
    ,ads_items_sold_cnt_td bigint
    ,ads_gmv_amt_local_td double
    ,ads_gmv_amt_usd_td double 
    ,expenditure_amt_local_td double
    ,expenditure_amt_usd_td double
    ,broad_gmv_amt_usd_td double
)
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${path}'
;

INSERT OVERWRITE TABLE dws_advertiser_placement_performance_td__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  
           shop_id
           ,placement
           ,sum(impression_cnt_td) as impression_cnt_td
           ,sum(click_cnt_td) as click_cnt_td
           ,sum(order_cnt_td) as order_cnt_td
           ,sum(ads_items_sold_cnt_td) as ads_items_sold_cnt_td
           ,sum(ads_gmv_amt_local_td) as ads_gmv_amt_local_td
           ,sum(ads_gmv_amt_usd_td) as ads_gmv_amt_usd_td
           ,sum(expenditure_amt_local_td) as expenditure_amt_local_td
           ,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td
           ,sum(broad_gmv_amt_usd_td) as broad_gmv_amt_usd_td
           ,upper('${region}') as grass_region
          ,date('${grass_date}')  AS grass_date
    FROM (
        SELECT
           shop_id
           ,placement
           ,sum(impression_cnt_1d) as impression_cnt_td
           ,sum(click_cnt_1d) as click_cnt_td
           ,sum(order_cnt_1d) as order_cnt_td
           ,sum(ads_items_sold_cnt_1d) as ads_items_sold_cnt_td
           ,sum(ads_gmv_amt_local_1d) as ads_gmv_amt_local_td
           ,sum(ads_gmv_amt_usd_1d) as ads_gmv_amt_usd_td
           ,sum(expenditure_amt_local_1d) as expenditure_amt_local_td
           ,sum(expenditure_amt_usd_1d) as expenditure_amt_usd_td
           ,sum(broad_gmv_amt_usd_1d) as broad_gmv_amt_usd_td
        FROM mp_paidads.dws_advertise_performance_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
        and tz_type = 'local'
        group by shop_id,placement

        UNION ALL

        SELECT
           shop_id
           ,placement
           ,impression_cnt_td
           ,click_cnt_td
           ,order_cnt_td
           ,ads_items_sold_cnt_td
           ,ads_gmv_amt_local_td
           ,ads_gmv_amt_usd_td
           ,expenditure_amt_local_td
           ,expenditure_amt_usd_td
           ,broad_gmv_amt_usd_td
        FROM mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date_sub(date('${grass_date}'), 1)
        and tz_type = 'local'
    )
    GROUP BY shop_id,placement;

-- alter table dws_advertiser_performance_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");