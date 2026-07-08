-- task_code: data_paidadsmart.studio_8134615  asset_id: 8134615
create external table if not exists ads_advertise_alarm_key_metrics_1d__reg_s0_live
(
    shop_id bigint comment 'shop_id'
    ,seller_name string comment 'shop name'
    ,advertiser_tier string comment 'advertiser_tier'
    ,seller_tier string comment 'seller_tier'
    ,shop_level1_global_be_category string
    ,shop_level2_global_be_category string
    ,campaign_id bigint
    ,ads_id bigint
    ,item_id bigint
    ,pricing_type int
    ,placement int
    ,main_product_type string
    ,product_type string
    ,sub_product_type string
    ,traffic_type string
    ,entry_point string
    ,entrance int
    ,shop_valid_budget_usd_1d double
    ,shop_ads_rev_usd_1d double
    ,campaign_valid_budget_usd_1d double
    ,campaign_ads_rev_usd_1d double
    ,if_campaign_hit tinyint
    ,if_campaign_waste tinyint
    ,ads_rev_usd_1d double
    ,ads_impression_1d bigint
    ,ads_click_1d bigint
    ,direct_order_1d bigint
    ,broad_order_1d bigint
    ,direct_gmv_usd_1d double
    ,broad_gmv_usd_1d double
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_advertise_alarm_key_metrics_1d'
;

create or replace temporary view ads_perf as 
select 
    shop_id
    ,advertiser_tier
    ,seller_tier
    ,campaign_id
    ,ads_id
    ,item_id
    ,pricing_type
    ,placement
    ,main_product_type
    ,product_type
    ,sub_product_type
    ,traffic_type
    ,entry_point
    ,entrance
    ,sum(ads_expenditure_amt_usd) as ads_rev_usd_1d
    ,sum(impression_cnt) as ads_impression_1d
    ,sum(click_cnt) as ads_click_1d
    ,sum(order_cnt) as direct_order_1d
    ,sum(broad_order_cnt) as broad_order_1d
    ,sum(ads_gmv_usd) as direct_gmv_1d
    ,sum(broad_order_gmv_amt_usd) as broad_gmv_1d
    ,sum(cps_dedup_click_cnt) as cps_dedup_click_cnt
from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
where grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and (is_ads_active = 1 or has_performance = 1)
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14
;


cache table valid_budget OPTIONS ('storageLevel' 'MEMORY_AND_DISK') 
select 
    shop_id
    ,campaign_id
    ,campaign_valid_budget_usd 
    ,account_balance_usd
    ,budget_usd
from mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live
where grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
;

create or replace temporary view shop_info as 
select 
    shop_id
    ,seller_name
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
from mp_paidads.dim_shop_info__reg_s0_live
where grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
;

create or replace temporary view campaign_waste as 
select 
    campaign_id
    ,case when COALESCE(sum(ads_expenditure_amt_usd),0) > 0 and COALESCE(sum(order_cnt),0) = 0 then 1 else 0 end as if_campaign_waste
from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
where grass_date <= date('${grass_date}') 
    and grass_date >= date_sub(date('${grass_date}'),13)
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and (is_ads_active = 1 or has_performance = 1)
group by 1
;

insert overwrite TABLE ads_advertise_alarm_key_metrics_1d__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    a.shop_id
    ,seller_name
    ,advertiser_tier
    ,seller_tier
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
    ,a.campaign_id
    ,ads_id
    ,item_id
    ,pricing_type
    ,placement
    ,main_product_type
    ,product_type
    ,sub_product_type
    ,traffic_type
    ,entry_point
    ,entrance
    ,COALESCE(shop_valid_budget_usd_1d,0) as shop_valid_budget_usd_1d
    ,COALESCE(sum(ads_rev_usd_1d) over(partition by a.shop_id),0) as shop_ads_rev_usd_1d
    ,COALESCE(campaign_valid_budget_usd,0) as campaign_valid_budget_usd
    ,COALESCE(sum(ads_rev_usd_1d) over(partition by a.campaign_id),0) as campaign_ads_rev_usd_1d
    ,case when round(sum(ads_rev_usd_1d) over(partition by a.campaign_id),5)/ round(campaign_valid_budget_usd,5) >= 1 then 1 else 0 end as if_campaign_hit
    ,if_campaign_waste
    ,COALESCE(ads_rev_usd_1d,0.0)
    ,COALESCE(ads_impression_1d,0)
    ,COALESCE(ads_click_1d,0)
    ,COALESCE(direct_order_1d,0)
    ,COALESCE(broad_order_1d,0)
    ,COALESCE(direct_gmv_1d,0.0)
    ,COALESCE(broad_gmv_1d,0.0)
    ,COALESCE(cps_dedup_click_cnt,0)
    ,coalesce(account_balance_usd,0.0)
    ,coalesce(budget_usd,0.0)
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date 
from ads_perf a 
left join valid_budget b 
on a.shop_id = b.shop_id 
and a.campaign_id = b.campaign_id
left join shop_info c 
on a.shop_id = c.shop_id
left join campaign_waste d 
on a.campaign_id = d.campaign_id
left join (select shop_id, sum(campaign_valid_budget_usd) as shop_valid_budget_usd_1d from valid_budget group by 1)f
on a.shop_id = f.shop_id
;