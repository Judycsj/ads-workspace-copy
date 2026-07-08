-- task_code: data_paidadsmart.studio_7017799  asset_id: 7017799
create external table if not exists ads_advertise_roi2_key_metrics_daily__reg_s0_live (
    ads_id bigint
    ,placement bigint
    ,campaign_id bigint
    ,shop_id bigint
    ,item_id bigint
    ,ads_create_datetime string
    ,is_active_ads tinyint
    ,is_new_ads tinyint
    ,target_roi double
    ,is_valid_roi string
    ,suggest_value_1 double
    ,suggest_value_2 double
    ,suggest_value_3 double
    ,roi_ratio_group string
    ,is_limited_budget tinyint
    ,roi2_valid_budget_usd double
    ,roi2_ads_revenue_usd double
    ,roi2_ads_click_cnt bigint
    ,roi2_ads_impression_cnt bigint
    ,roi2_broad_gmv_usd double
    ,roi2_broad_order_cnt bigint
    ,roi2_direct_gmv_usd double
    ,roi2_direct_order_cnt bigint
    ,roi2_ads_revenue_14d_usd double
    ,roi2_advv_14d_usd double
    ,has_roi3_bid_voucher_impression tinyint
    ,has_roi3_best_voucher_impression tinyint
    ,has_roi3_voucher_impression tinyint
    ,roi3_ads_revenue_usd double
    ,roi3_voucher_revenue_usd double
    ,roi3_ads_click_cnt bigint
    ,roi3_ads_voucher_click_cnt bigint
    ,roi3_ads_impression_cnt bigint
    ,roi3_ads_voucher_impression_cnt bigint
    ,roi3_broad_gmv_usd double
    ,roi3_broad_order_cnt bigint
    ,roi3_direct_gmv_usd double
    ,roi3_direct_order_cnt bigint
    ,pricing_type int
    ,level1_global_be_category struct<level1_global_be_category_id:bigint,level1_global_be_category:string>
    ,level2_global_be_category struct<level2_global_be_category_id:bigint,level2_global_be_category:string>
    ,level3_global_be_category struct<level3_global_be_category_id:bigint,level3_global_be_category:string>
    ,seller_type_1p string
    ,is_cb_shop tinyint
    ,is_cb_sip_affiliated tinyint
    ,is_local_sip_affiliated tinyint
    ,roi_ratio_group_7d string 
    ,roi2_ads_revenue_7d_usd double 
    ,roi2_advv_7d_usd double
    ,roi2_cpa_usd double
    ,roi2_cps_dedup_click_cnt bigint 
    ,ads_status bigint 
    ,campaign_status tinyint
    ,roi2_advv_1d_usd double
    ,roi2_broad_order_cnt_7d bigint 
    ,roi2_direct_order_cnt_7d bigint 
    ,roi2_valid_budget_usd_7d double
    ,roi2_cpa_usd_7d double
    ,is_rapid_boost_toggle_on_7d tinyint
    ,roi_ratio_group_7d_for_rapid_boost string 
    ,seller_setting_roi_ratio_group_7d_for_rapid_boost string 
    ,seller_setting_roi_ratio_group_7d string 
    ,roi2_broad_gmv_usd_7d double
    ,is_cold_start_stage tinyint
    ,roi2_paid_broad_gmv_usd_1d double
    ,roi2_paid_broad_order_cnt_1d bigint
    ,roi2_paid_advv_usd_1d double
    ,roi2_paid_broad_gmv_usd_7d double
    ,roi2_paid_broad_order_cnt_7d bigint
    ,roi2_paid_advv_usd_7d double
    ,is_ocpm_1d tinyint
    ,is_rapid_boost_toggle_on_1d tinyint
) 
comment 'key metrics for roi2 ads. Granularity: grass_region, grass_date, ads_id'
partitioned by
(
    tz_type string comment 'timezone type'
    ,grass_region string comment 'partition key'
    ,grass_date date comment 'partition key, yyyy-MM-dd'
) stored as PARQUET location '${HIVE_PATH}/ads_advertise_roi2_key_metrics_daily__reg_s0_live/'
;

create or replace temporary view roi2_ads_1d as (
    select
        ads_id
        ,placement
        ,pricing_type
        ,campaign_id
        ,shop_id
        ,item_id
        ,ads_create_datetime
        ,level1_global_be_category
        ,level2_global_be_category
        ,level3_global_be_category
        ,seller_type_1p
        ,is_cb_seller as is_cb_shop
        ,is_cb_sip_affiliated
        ,is_local_sip_affiliated
        ,ads_status
        ,campaign_status
        ,sum(ads_expenditure_amt_usd) as roi2_ads_revenue_usd
        ,sum(deduplicated_click_cnt) as roi2_ads_click_cnt
        ,sum(impression_cnt) as roi2_ads_impression_cnt
        ,sum(broad_order_gmv_amt_usd) as roi2_broad_gmv_usd
        ,sum(broad_order_cnt) as roi2_broad_order_cnt
        ,sum(ads_gmv_usd) as roi2_direct_gmv_usd
        ,sum(order_cnt) as roi2_direct_order_cnt
        ,max(is_ads_active) as is_ads_active
        ,max(has_performance) as has_performance
        ,sum(cps_dedup_click_cnt) as roi2_cps_dedup_click_cnt
        ,sum(paid_broad_order_cnt) as roi2_paid_broad_order_cnt
        ,sum(paid_broad_order_gmv_usd) as roi2_paid_broad_gmv_usd
    from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where
        tz_type = 'local'
        and grass_date = date('${BIZ_YESTERDAY}')
        and grass_region = upper('${region}')
        and placement = 40
        and pricing_type <> 29
        and (is_ads_active = 1 or has_performance > 0 or broad_order_cnt > 0)
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
)
;

create or replace temporary view roi3_tracking as (
    SELECT 
        ads_id
        ,pricing_type
        ,sum(if(operation = 1 and bid_voucher_id > 0, 1, 0)) as roi3_bid_voucher_impression_cnt
        ,sum(if(operation = 1 and is_roi3_best_voucher = 1, 1, 0)) as roi3_best_voucher_impression_cnt
        ,sum(if(operation = 1 and item_voucher.display_ads_voucher_label > 0, 1, 0 )) as roi3_ads_voucher_impression_cnt
        ,sum(if(operation = 2 and item_voucher.display_ads_voucher_label > 0, 1, 0 )) as roi3_ads_voucher_click_cnt
    from mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live
    where grass_region = upper('${region}')
    and grass_date = date('${BIZ_YESTERDAY}')
    and operation in (1 , 2)
    and ads_id > 0
    and ads_placement = 40
    and pricing_type <> '29'
    and (bid_voucher_id > 0 or is_roi3_best_voucher = 1 or item_voucher.display_ads_voucher_label > 0)
    group by ads_id, pricing_type
);

create or replace temporary view roi2_ads_nd as (
    select
        ads_id 
        ,pricing_type
        ,ads_rev_14d as roi2_ads_revenue_14d_usd
        ,advv_14d as roi2_advv_14d_usd
        ,case 
            when advv_14d = 0 and ads_rev_14d > 0 then 'no gmv'
            when advv_14d > 0 and ads_rev_14d = 0 then 'no rev'
            when roi_ratio < 0.5 then '0-0.5'
            when roi_ratio < 0.75 then '0.5-0.75'
            when roi_ratio < 1 then '0.75-1'
            when roi_ratio < 1.25 then '1-1.25'
            when roi_ratio < 2 then '1.25-2'
            when roi_ratio >= 2 then '2+'
            else 'no data'
        end as roi_ratio_group
        ,ads_rev_7d as roi2_ads_revenue_7d_usd
        ,advv_7d as roi2_advv_7d_usd
        ,case 
            when advv_7d = 0 and ads_rev_7d > 0 then 'no gmv'
            when advv_7d > 0 and ads_rev_7d = 0 then 'no rev'
            when roi_ratio_7d < 0.5 then '0-0.5'
            when roi_ratio_7d < 0.8 then '0.5-0.8'
            when roi_ratio_7d < 1 then '0.8-1'
            when roi_ratio_7d <= 1.2 then '1-1.2'
            when roi_ratio_7d < 2 then '1.2-2'
            when roi_ratio_7d >= 2 then '2+'
            else 'no data'
        end as roi_ratio_group_7d
        ,impression_cnt_14d
        ,advv_1d as roi2_advv_1d_usd
        ,broad_order_cnt_7d
        ,direct_order_cnt_7d
        ,roi2_cpa_usd
        ,roi2_cpa_usd_7d
        ,roi3_ads_revenue_usd
        ,roi3_ads_click_cnt
        ,roi3_ads_impression_cnt
        ,roi3_broad_gmv_usd
        ,roi3_broad_order_cnt
        ,roi3_direct_gmv_usd
        ,roi3_direct_order_cnt
        ,roi3_voucher_revenue_usd
        ,is_rapid_boost_toggle_on_7d
        ,case 
            when is_rapid_boost_toggle_on_7d = 0 then null
            when coalesce(broad_gmv_amt_usd_7d,0) = 0 and ads_rev_7d > 0 then 'no gmv'
            when broad_gmv_amt_usd_7d > 0 and coalesce(ads_rev_7d,0) = 0 then 'no rev'
            when roi_ratio_7d_for_rapid < 0.7 then '0-0.7'
            when roi_ratio_7d_for_rapid < 1 then '0.7-1'
            when roi_ratio_7d_for_rapid >= 1 then '1+'
            else 'no data'
        end as roi_ratio_group_7d_for_rapid_boost
        ,broad_gmv_amt_usd_7d as roi2_broad_gmv_usd_7d
        ,paid_broad_gmv_amt_usd_7d as roi2_paid_broad_gmv_usd_7d
        ,paid_broad_order_cnt_7d as roi2_paid_broad_order_cnt_7d
        ,paid_advv_7d as roi2_paid_advv_usd_7d
        ,paid_advv_1d as roi2_paid_advv_usd_1d
        
        ,coalesce(is_ocpm, 0) as is_ocpm_1d
        ,coalesce(is_rapid_boost_toggle_on, 0) as is_rapid_boost_toggle_on_1d
    from
        (
            select 
                ads_id 
                ,pricing_type
                ,sum(if(a.grass_date >= date('${PREV_14D}'),coalesce(broad_gmv_amt_usd * target_cir, 0), 0 )) as advv_14d 
                ,sum(if(a.grass_date >= date('${PREV_14D}'),coalesce(expenditure_amt_usd, 0), 0 )) as ads_rev_14d
                ,sum(if(a.grass_date >= date('${PREV_14D}'),coalesce(broad_gmv_amt_local * target_cir, 0), 0 )) / sum(if(a.grass_date >= date('${PREV_14D}'),coalesce(expenditure_amt_local, 0), 0)) as roi_ratio 
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(broad_gmv_amt_usd * target_cir, 0), 0 )) as advv_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(broad_gmv_amt_usd , 0), 0 )) as broad_gmv_amt_usd_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(expenditure_amt_usd, 0), 0)) as ads_rev_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(broad_gmv_amt_local * target_cir, 0), 0)) / sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(expenditure_amt_local, 0), 0)) as roi_ratio_7d
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}'), coalesce(broad_gmv_amt_usd * target_cir, 0), 0 )) as advv_1d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(broad_order_cnt, 0), 0)) as broad_order_cnt_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(order_cnt, 0), 0)) as direct_order_cnt_7d
                ,sum(if(a.grass_date between date('${PREV_15D}') and date('${PREV_2D}'), impression_cnt, 0)) as impression_cnt_14d
                ,avg(if(a.grass_date = date('${BIZ_YESTERDAY}') and impression_cnt > 0, target_cir * item_price/ 100000.0 / exchange_rate, null)) as roi2_cpa_usd
                ,avg(if(a.grass_date >= date('${PREV_7D}') and impression_cnt > 0, target_cir * item_price/ 100000.0 / exchange_rate, null)) as roi2_cpa_usd_7d

                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, expenditure_amt_usd, 0)) as roi3_ads_revenue_usd
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, expenditure_amt_usd * voucher_deduction_price / deduction_price, 0)) as roi3_voucher_revenue_usd
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, click_cnt, 0)) as roi3_ads_click_cnt
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, impression_cnt, 0)) as roi3_ads_impression_cnt
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, broad_gmv_amt_usd, 0))  as roi3_broad_gmv_usd
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, broad_order_cnt, 0)) as roi3_broad_order_cnt
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, ads_order_gmv_usd, 0)) as roi3_direct_gmv_usd
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}') and get_json_object(bid_rerank_trace,'$.bid_voucher_id') is not null, order_cnt, 0)) as roi3_direct_order_cnt

                ,max(if(a.grass_date >= date('${PREV_7D}') and rapid_boost_toggle = true, 1, 0)) as is_rapid_boost_toggle_on_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(broad_gmv_amt_local / roi_upper_bound, 0), 0)) / sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(expenditure_amt_local, 0), 0)) as roi_ratio_7d_for_rapid

                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(paid_broad_gmv_usd , 0), 0 )) as paid_broad_gmv_amt_usd_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(paid_broad_order_cnt, 0), 0)) as paid_broad_order_cnt_7d
                ,sum(if(a.grass_date >= date('${PREV_7D}'), coalesce(paid_broad_gmv_usd * target_cir, 0), 0 )) as paid_advv_7d
                ,sum(if(a.grass_date = date('${BIZ_YESTERDAY}'), coalesce(paid_broad_gmv_usd * target_cir, 0), 0 )) as paid_advv_1d

                ,max(case when a.grass_date = date('${BIZ_YESTERDAY}') and is_ocpm = true then 1 end) as is_ocpm
                ,max(case when a.grass_date = date('${BIZ_YESTERDAY}') and rapid_boost_toggle = true then 1 end) as is_rapid_boost_toggle_on
            from mp_paidads.dwd_advertise_performance_di__reg_s0_live a 
            left join mp_order.dim_exchange_rate__reg_s0_live ex
            ON a.grass_region = ex.grass_region
            and a.grass_date = ex.grass_date
            where a.tz_type = 'local'
            and a.grass_date between date('${PREV_15D}') and date('${BIZ_YESTERDAY}')
            and a.grass_region = upper('${region}') 
            and placement = 40
            and pricing_type <> 29
            group by 1, 2
        ) 
)
;

create or replace temporary view perf_cold_start_stage as
select 
    ads_id 
    ,is_cold_start_stage
from
(    select 
        ads_id
        ,bit_get(ad_tag, 34) as is_cold_start_stage
        ,row_number() over(partition by ads_id order by `timestamp` desc) as imp_rank
    from mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where grass_region = upper('${region}')
        and grass_date = date('${BIZ_YESTERDAY}')
        and tz_type = 'local'
        and placement = 40
        and pricing_type <> 29
        and impression_cnt > 0
)
where imp_rank = 1
;

INSERT OVERWRITE TABLE ads_advertise_roi2_key_metrics_daily__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    a.ads_id
    ,a.placement
    ,a.campaign_id
    ,a.shop_id
    ,a.item_id
    ,a.ads_create_datetime
    ,if(is_ads_active =1 or has_performance = 1, 1, 0) as is_active_ads
    ,if(COALESCE(impression_cnt_14d, 0) = 0, 1, 0) as is_new_ads
    ,target_roi
    ,case when suggest_value_3 is null then 'null'
        when target_roi <= suggest_value_3 * 1.25 then 'valid'
        else 'higher'
    end as is_valid_roi
    ,suggest_value_1
    ,suggest_value_2
    ,suggest_value_3
    ,roi_ratio_group
    ,is_limited_budget
    ,roi2_valid_budget_usd
    ,roi2_ads_revenue_usd
    ,roi2_ads_click_cnt
    ,roi2_ads_impression_cnt
    ,roi2_broad_gmv_usd
    ,roi2_broad_order_cnt
    ,roi2_direct_gmv_usd
    ,roi2_direct_order_cnt
    ,roi2_ads_revenue_14d_usd
    ,roi2_advv_14d_usd
    ,if(roi3_bid_voucher_impression_cnt > 0, 1, 0) as has_roi3_bid_voucher_impression
    ,if(roi3_best_voucher_impression_cnt > 0, 1, 0) as has_roi3_best_voucher_impression
    ,if(roi3_ads_voucher_impression_cnt > 0, 1, 0) as has_roi3_voucher_impression
    ,roi3_ads_revenue_usd
    ,roi3_voucher_revenue_usd
    ,roi3_ads_click_cnt
    ,roi3_ads_voucher_click_cnt
    ,roi3_ads_impression_cnt
    ,roi3_ads_voucher_impression_cnt
    ,roi3_broad_gmv_usd
    ,roi3_broad_order_cnt
    ,roi3_direct_gmv_usd
    ,roi3_direct_order_cnt
    ,a.pricing_type
    ,level1_global_be_category
    ,level2_global_be_category
    ,level3_global_be_category
    ,seller_type_1p
    ,is_cb_shop
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,roi_ratio_group_7d
    ,roi2_ads_revenue_7d_usd
    ,roi2_advv_7d_usd
    ,roi2_cpa_usd
    ,roi2_cps_dedup_click_cnt
    ,ads_status
    ,campaign_status
    ,roi2_advv_1d_usd
    ,broad_order_cnt_7d as roi2_broad_order_cnt_7d
    ,direct_order_cnt_7d as roi2_direct_order_cnt_7d
    ,roi2_valid_budget_usd_7d
    ,roi2_cpa_usd_7d
    ,coalesce(is_rapid_boost_toggle_on_7d, 0) as is_rapid_boost_toggle_on_7d
    ,roi_ratio_group_7d_for_rapid_boost
    ,case 
            when is_rapid_boost_toggle_on_7d = 0 then null
            when coalesce(roi2_broad_gmv_usd_7d,0) = 0 and roi2_ads_revenue_7d_usd > 0 then 'no gmv'
            when roi2_broad_gmv_usd_7d > 0 and coalesce(roi2_ads_revenue_7d_usd,0) = 0 then 'no rev'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd < 0.7 then '0-0.7'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd < 1 then '0.7-1'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd >= 1 then '1+'
            else 'no data'
        end as seller_setting_roi_ratio_group_7d_for_rapid_boost
    ,case 
            when coalesce(roi2_broad_gmv_usd_7d,0) = 0 and roi2_ads_revenue_7d_usd > 0 then 'no gmv'
            when roi2_broad_gmv_usd_7d > 0 and coalesce(roi2_ads_revenue_7d_usd,0) = 0 then 'no rev'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd < 0.5 then '0-0.5'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd < 0.8 then '0.5-0.8'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd < 1 then '0.8-1'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd <= 1.2 then '1-1.2'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd < 2 then '1.2-2'
            when roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd >= 2 then '2+'
            else 'no data'
        end as seller_setting_roi_ratio_group_7d
    ,coalesce(roi2_broad_gmv_usd_7d,0) as roi2_broad_gmv_usd_7d
    ,is_cold_start_stage

    ,roi2_paid_broad_gmv_usd as roi2_paid_broad_gmv_usd_1d
    ,roi2_paid_broad_order_cnt as roi2_paid_broad_order_cnt_1d
    ,roi2_paid_advv_usd_1d
    ,roi2_paid_broad_gmv_usd_7d
    ,roi2_paid_broad_order_cnt_7d
    ,roi2_paid_advv_usd_7d

    ,is_ocpm_1d
    ,is_rapid_boost_toggle_on_1d

    ,upper('${region}') as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from roi2_ads_1d a 
left join roi2_ads_nd b 
on a.ads_id = b.ads_id
and a.pricing_type = b.pricing_type 
left join (
    select 
        campaign_id
        ,sum(if(grass_date = date('${BIZ_YESTERDAY}'), campaign_valid_budget_usd, null)) as roi2_valid_budget_usd
        ,sum(campaign_valid_budget_usd) as roi2_valid_budget_usd_7d
        -- ,if(budget_usd = 9999999999, 0, 1) as is_limited_budget
        ,max(case when grass_date = date('${BIZ_YESTERDAY}') then if(budget_usd = 9999999999, 0, 1) end) as is_limited_budget
    from mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live 
    where tz_type = 'local'
    and grass_date between  date('${PREV_7D}') and date('${BIZ_YESTERDAY}')
    and grass_region = upper('${region}')
    group by 1
) c 
on a.campaign_id = c.campaign_id 
left join (
    select  campaign_id
            ,roi_two as target_roi
            ,final_value_list[0] as suggest_value_1
            ,final_value_list[1] as suggest_value_2
            ,final_value_list[2] as suggest_value_3
    from    mp_paidads.dim_campaign__reg_s0_live
    where   grass_date = date('${BIZ_YESTERDAY}')
        and   grass_region = upper('${region}')
        and   tz_type = 'local'
) d
on a.campaign_id = d.campaign_id 
left join  roi3_tracking e
on a.ads_id = e.ads_id
and a.pricing_type = e.pricing_type 
left join perf_cold_start_stage f 
on a.ads_id = f.ads_id

;