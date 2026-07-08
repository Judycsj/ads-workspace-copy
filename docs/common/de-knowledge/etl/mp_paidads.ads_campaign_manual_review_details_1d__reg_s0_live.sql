-- task_code: data_paidadsmart.studio_9327876  asset_id: 9327876
create external table if not exists ads_campaign_manual_review_details_1d__reg_s0_live
(
    shop_id bigint comment 'shop_id'
    ,campaign_id bigint comment 'campaign_id'
    ,rebate_generated_date string comment 'rebate_generated_date'
    ,is_manual_review tinyint comment 'is_manual_review'
    ,no_rebate_type int comment 'no need rebate reason'
    ,final_rebate_status int comment 'rebare status'
    ,final_rebate_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,final_rebate_amt_usd double 
    ,broad_order_cnt bigint
    ,broad_gmv_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,broad_gmv_amt_usd double
    ,expenditure_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,expenditure_amt_usd double
    ,advv_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,advv_amt_usd double
    ,roi_ratio double
    ,original_rebate_amt bigint comment 'original_rebate_value=expenditure_usd-advv_usd/0.9,local currency, *10^5 (as platform need)'
    ,original_rebate_amt_usd double
    ,expected_rebate_amt bigint comment 'local currency, *10^5 (as platform need)'
    ,expected_rebate_amt_usd double
    ,region_expected_rebate_amt_usd double comment 'expected_rebate_amt_usd by region level'
    ,target_roi2_region_net_ads_expenditure_amt_usd double
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_campaign_manual_review_details_1d__reg_s0_live'
;

set time zone '${timezone}';

create or replace temporary view manual_review as
select 
    shopid as shop_id
    ,campaign_id
    ,from_unixtime(log_date, 'yyyy-MM-dd') as rebate_generated_date
    ,rebate_history_status as final_rebate_status
    ,amount as final_rebate_amt
    ,case when get_json_object(_decoded_extinfo,'$.had_manual_review') = 'true' then 1 else 0 end as is_manual_review
    ,cast(get_json_object(_decoded_extinfo,'$.no_rebate_type') as int) as no_rebate_type
    ,upper('${region}') as grass_region
from mp_paidads.shopee_ads_rebate_${region}_db__campaign_rebate_history_tab__reg_continuous_s0_live
where from_unixtime(mtime, 'yyyy-MM-dd') = DATE('${grass_date}')
;

create or replace temporary view auto_rebate_detail as
select 
    campaign_id
    ,broad_order_cnt
    ,broad_gmv_amt
    ,broad_gmv_usd
    ,expenditure_amt
    ,expenditure_amt_usd
    ,advv_amt
    ,advv_amt_usd
    ,roi_ratio
    ,original_rebate_amt
    ,original_rebate_usd
    ,expected_rebate_amt
    ,expected_rebate_usd
    ,region_expected_rebate_amt_usd
    ,target_roi2_region_net_ads_expenditure_amt_usd
    ,grass_date
from mp_paidads.ads_campaign_auto_rebate_details_1d__reg_s0_live
where grass_date >= date_sub(DATE('${grass_date}'),10)
and grass_date <= DATE('${grass_date}')
and grass_region = upper('${region}')
;

create or replace temporary view rate as
select 
    grass_region
    ,exchange_rate
from mp_order.dim_exchange_rate__reg_s0_live
where grass_date = DATE('${grass_date}')
and grass_region = upper('${region}')
;

insert overwrite table ads_campaign_manual_review_details_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select 
    shop_id 
    ,a.campaign_id  as campaign_id
    ,rebate_generated_date 
    ,is_manual_review 
    ,no_rebate_type 
    ,final_rebate_status 
    ,final_rebate_amt 
    ,final_rebate_amt / (100000.0 * exchange_rate) as final_rebate_amt_usd 
    ,broad_order_cnt 
    ,broad_gmv_amt 
    ,broad_gmv_usd 
    ,expenditure_amt 
    ,expenditure_amt_usd 
    ,advv_amt 
    ,advv_amt_usd 
    ,roi_ratio 
    ,original_rebate_amt 
    ,original_rebate_usd 
    ,expected_rebate_amt 
    ,expected_rebate_usd 
    ,region_expected_rebate_amt_usd 
    ,target_roi2_region_net_ads_expenditure_amt_usd 
    ,upper('${region}')
    ,DATE('${grass_date}')
from manual_review a 
left join auto_rebate_detail b 
on a.campaign_id = b.campaign_id 
and a.rebate_generated_date = b.grass_date
left join rate c 
on a.grass_region = c.grass_region 
;