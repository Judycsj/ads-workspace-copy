-- task_code: data_paidadsmart.studio_9019382  asset_id: 9019382
CREATE EXTERNAL TABLE IF NOT EXISTS ads_item_supply_1d__reg_s0_live(
    shop_id         bigint comment "id of shop"
    ,item_id        bigint comment "id of item"
    ,is_sip_shop    tinyint	comment "is_local_sip_affiliated or is_cb_sip_affiliated. is_local_sip_affiliated: if parent shop is local shop; is_cb_sip_affiliated:if parent shop is cb shop."
    ,is_cb_shop     tinyint comment "whether the shop is a CB shop"
    ,seller_type_1p string	comment "seller who has a cross boarder listing or shop"
    ,is_active_ads_item tinyint comment "is_ads_active = 1 or has_performance = 1"
    ,level1_global_be_category	struct<level1_global_be_category_id:bigint,level1_global_be_category:string> comment "First-level category"
    ,level2_global_be_category	struct<level2_global_be_category_id:bigint,level2_global_be_category:string> comment "Second-level category"
    ,level3_global_be_category	struct<level3_global_be_category_id:bigint,level3_global_be_category:string> comment "Third-level category"
    ,ads_expenditure_amt_usd_1d	double comment "Advertising expenses, before tax, excluding expired, not flated"
    ,ads_impression_cnt_1d      bigint comment "the sum of ads impression within 1d"
    ,ads_deduct_click_cnt_1d	bigint comment "the sum of ads deduct click within 1d"
    ,ads_cps_click_cnt_1d       bigint comment "the sum of ads cps click within 1d"
    ,ads_direct_order_cnt_1d	bigint comment "the sum of ads direct order within 1d"
    ,ads_broad_order_cnt_1d	    bigint comment "the sum of ads broad order within 1d"
    ,ads_direct_order_gmv_usd_1d    double comment "the sum of ads direct order gmv within 1d in usd currency"
    ,ads_direct_order_gmv_1d	    double comment "the sum of ads direct order gmv within 1d in local currency"
    ,ads_broad_order_gmv_usd_1d	    double comment "the sum of ads broad order gmv within 1d in usd currency"
    ,ads_broad_order_gmv_1d	        double comment "the sum of ads broad order gmv within 1d in local currency"
    ,platform_placed_order_cnt_30d  bigint comment "the sum of platform placed order within 30d"
    ,platform_gmv_usd_30d decimal(25,10) comment "the sum of platform gmv within 30d in usd currency"
    ,platform_gmv_30d	  decimal(25,10) comment "the sum of platform gmv within 30d in local currency"
    ,platform_impression_cnt_30d bigint comment "the sum of platform impression within 30d"
)
PARTITIONED BY
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date date comment 'grass_date'
)
STORED AS parquet
LOCATION "${HIVE_PATH}/ads_item_supply_1d"
;

INSERT OVERWRITE TABLE ads_item_supply_1d__reg_s0_live PARTITION (tz_type = 'local', grass_region, grass_date)
select base_item.shop_id        
    ,base_item.item_id       
    ,if(is_cb_sip_affiliated=1 or is_local_sip_affiliated = 1,1,0) as is_sip_shop   
    ,is_cb_shop    
    ,seller_type_1p
    ,if(is_ads_active = 1 or has_performance = 1,1,0) as is_active_ads_item
    ,level1_global_be_category	
    ,level2_global_be_category	
    ,level3_global_be_category	
    ,ads_expenditure_amt_usd_1d
    ,ads_impression_cnt_1d   
    ,ads_deduct_click_cnt_1d	
    ,ads_cps_click_cnt_1d       
    ,ads_direct_order_cnt_1d	
    ,ads_broad_order_cnt_1d	    
    ,ads_direct_order_gmv_usd_1d
    ,ads_direct_order_gmv_1d	
    ,ads_broad_order_gmv_usd_1d	
    ,ads_broad_order_gmv_1d
    ,platform_placed_order_cnt_30d
    ,platform_gmv_usd_30d
    ,platform_gmv_30d
    ,platform_impression_cnt_30d
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
from (
    select shop_id,item_id
        ,placed_order_cnt_30d as platform_placed_order_cnt_30d
        ,gmv_30d as platform_gmv_30d
        ,gmv_usd_30d as platform_gmv_usd_30d
    from mp_order.dws_item_gmv_nd__reg_s0_live
    where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and tz_type = 'local'
        and placed_order_cnt_30d>0
) base_item
left join(
    select shop_id
        ,is_cb_shop
    from mp_seller.dim_shop_ext__reg_s0_live
    where   grass_region = upper('${region}') and grass_date = date('${grass_date}') and tz_type = 'local'   
)dim_shop on base_item.shop_id = dim_shop.shop_id
left join (
    select shop_id,item_id
        ,seller_type_1p
        ,is_cb_sip_affiliated
        ,is_local_sip_affiliated
        ,level1_global_be_category
        ,level2_global_be_category
        ,level3_global_be_category
        ,max(has_performance) as has_performance
        ,max(is_ads_active) as is_ads_active
        ,sum(ads_expenditure_amt_usd)   as ads_expenditure_amt_usd_1d
        ,sum(impression_cnt)            as ads_impression_cnt_1d
        ,sum(click_cnt)                 as ads_deduct_click_cnt_1d
        ,sum(cps_dedup_click_cnt)       as ads_cps_click_cnt_1d
        ,sum(order_cnt)                 as ads_direct_order_cnt_1d
        ,sum(broad_order_cnt)           as ads_broad_order_cnt_1d
        ,sum(ads_gmv_usd)               as ads_direct_order_gmv_usd_1d
        ,sum(ads_gmv_local)             as ads_direct_order_gmv_1d
        ,sum(broad_order_gmv_amt_usd)   as ads_broad_order_gmv_usd_1d
        ,sum(broad_order_gmv_amt_local) as ads_broad_order_gmv_1d
        ,sum(ads_expenditure_amt_local) as ads_expenditure_amt_1d
    from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    WHERE grass_region = upper('${region}') AND grass_date = date('${grass_date}') and tz_type = 'local'
    group by shop_id,item_id,seller_type_1p,is_cb_sip_affiliated,is_local_sip_affiliated,level1_global_be_category,level2_global_be_category,level3_global_be_category
    having (max(has_performance) = 1 or max(is_ads_active) = 1)
)ads_metric_caled on base_item.shop_id = ads_metric_caled.shop_id and base_item.item_id = ads_metric_caled.item_id
left join (
    select item_id
       ,sum(imp_cnt) as platform_impression_cnt_30d
   from srdi_mart.dws_sr_data_warehouse_platform_item_level_benchmark_1d
   where local_date between date('${PREV_30D}') and date('${grass_date}')
       and feature_detail = '__ALL__'
       and scenario_tag = '__ALL__'
       and grass_region = upper('${region}')
   group by item_id
)platform_impr on base_item.item_id = platform_impr.item_id
;