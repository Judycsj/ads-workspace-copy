-- task_code: data_paidadsmart.studio_2705550  asset_id: 2705550
CREATE OR REPLACE TEMPORARY VIEW ads_create_within_14d AS (
    select
         a.ads_id
        ,a.placement
        ,a.ads_create_datetime
        ,b.impression_cnt
        ,b.order_cnt
        ,b.broad_order_cnt
        ,a.grass_date
    from(
        select
             grass_date
            ,ads_id
            ,placement
            ,ads_create_datetime
        from mp_paidads.dim_advertise__reg_s0_live
        WHERE grass_region = upper('${region}')
        and   grass_date <= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')
        and   grass_date >= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-14d')}')
        and   placement in (0, 2, 3, 4, 5, 802, 805, 1000, 1002, 1005, 1200, 1202, 1205, 20, 54)
        and   ads_create_datetime <= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')
        and   ads_create_datetime >= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-14d')}')
    ) a
    left join
    (
        select
              grass_date
             ,ads_id
             ,placement
             ,sum(impression_cnt_1d) as impression_cnt
             ,sum(order_cnt_1d) as order_cnt
             ,sum(broad_order_cnt_1d) as broad_order_cnt
        from    mp_paidads.dws_advertise_performance_1d__reg_s0_live
        where   grass_region = upper('${region}')
        and  grass_date <= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')
        and   grass_date >= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-14d')}')
        and   tz_type = 'local'
        and   placement in (0, 2, 3, 4, 5, 802, 805, 1000, 1002, 1005, 1200, 1202, 1205, 20, 54)
        group by grass_date, ads_id, placement
    ) b
    on  a.grass_date = b.grass_date
    and a.ads_id = b.ads_id
    and a.placement = b.placement
)
;

CREATE OR REPLACE TEMPORARY VIEW  cold_start_7d AS (
    select
          ads_id
         ,placement
         ,case
            when order_cnt_7d > 0 then 'Order success'
            when order_cnt_7d = 0 and broad_order_cnt_7d > 0 then 'Broad order success'
            when order_cnt_7d = 0 and broad_order_cnt_7d = 0 and impression_cnt_7d <= 3000 then 'In progress'
            when order_cnt_7d = 0 and broad_order_cnt_7d = 0 and impression_cnt_7d <= 9000 then 'Unsuccess'
            when order_cnt_7d = 0 and broad_order_cnt_7d = 0 and impression_cnt_7d > 9000 then 'Low quality'
        end as cold_start_status_7d
        ,order_cnt_7d as first_7d_order_count
    from (
        select  ads_id
             ,placement
             ,sum(coalesce(impression_cnt, 0)) as impression_cnt_7d
             ,sum(coalesce(order_cnt, 0)) as order_cnt_7d
             ,sum(coalesce(broad_order_cnt, 0)) as broad_order_cnt_7d
        from    ads_create_within_14d
        where grass_date <= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')
        and   grass_date >= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-7d')}')
        and   ads_create_datetime <= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')
        and   ads_create_datetime >= date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-7d')}')
        group by ads_id, placement
    )
)
;

CREATE OR REPLACE TEMPORARY VIEW cold_start_14d AS (
    select
          ads_id
         ,placement
         ,case
            when order_cnt_14d > 0 then 'Order success'
            when order_cnt_14d = 0 and broad_order_cnt_14d > 0 then 'Broad order success'
            when order_cnt_14d = 0 and broad_order_cnt_14d = 0 and impression_cnt_14d <= 3000 then 'In progress'
            when order_cnt_14d = 0 and broad_order_cnt_14d = 0 and impression_cnt_14d <= 9000 then 'Unsuccess'
            when order_cnt_14d = 0 and broad_order_cnt_14d = 0 and impression_cnt_14d > 9000 then 'Low quality'
        end as cold_start_status_14d
        ,order_cnt_14d as first_14d_order_count
    from (
        select  ads_id
             ,placement
             ,sum(coalesce(impression_cnt, 0)) as impression_cnt_14d
             ,sum(coalesce(order_cnt, 0)) as order_cnt_14d
             ,sum(coalesce(broad_order_cnt, 0)) as broad_order_cnt_14d
        from    ads_create_within_14d
        group by ads_id, placement
    )
)
;

-- -- only for the first run and fist backfill
-- CREATE OR REPLACE TEMPORARY VIEW first_order_begin AS (
--     select  ads_id
--             ,placement
--             ,min(grass_date) as first_order_date
--     from ads_create_within_14d
--     where order_cnt > 0
--     group by  ads_id, placement
-- )
-- ;

-- for schedule task
CREATE OR REPLACE TEMPORARY VIEW first_order AS (
    select  pre_day.ads_id
            ,pre_day.placement
            ,coalesce(pre_day.first_order_date, current_day.first_order_date) as first_order_date
    from (
        select ads_id
            ,placement
            ,first_order_date
        from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
            AND grass_date = date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-2d')}')
            AND tz_type = 'local'
            and placement in (0, 2, 3, 4, 5, 802, 805, 1000, 1002, 1005, 1200, 1202, 1205, 20, 54)
            and ads_create_datetime >= date('2023-03-10')
        GROUP BY ads_id, placement, first_order_date
    ) pre_day
    left join
    (
        select ads_id
            ,placement
            ,DATE('${grass_date}') as first_order_date
        from mp_paidads.dws_advertise_performance_1d__reg_s0_live
        where   grass_region = upper('${region}')
            and grass_date = date('${grass_date}')
            and tz_type = 'local'
            and placement in (0, 2, 3, 4, 5, 802, 805, 1000, 1002, 1005, 1200, 1202, 1205, 20, 54)
            and order_cnt_1d > 0
        group by 1,2
    ) current_day
    on pre_day.ads_id = current_day.ads_id
    and pre_day.placement = current_day.placement
);


CREATE OR REPLACE TEMPORARY VIEW ads_info AS 
SELECT   ads_id
        ,placement
        ,new_boost
        ,entrance
        ,tz_type
        ,SUM(impression_cnt_1d) AS impression_cnt
        ,SUM(click_cnt_1d) AS click_cnt
        ,SUM(order_cnt_1d) AS order_cnt
        ,SUM(ads_items_sold_cnt_1d) AS ads_items_sold_cnt
        ,SUM(ads_gmv_amt_local_1d) AS ads_gmv_amt_local
        ,SUM(ads_gmv_amt_usd_1d) AS ads_gmv_amt_usd
        ,SUM(expenditure_amt_local_1d) AS expenditure_amt_local
        ,SUM(expenditure_amt_usd_1d) AS expenditure_amt_usd
        ,SUM(avg_ads_ranks * impression_cnt_1d) AS avg_ads_ranks
        ,SUM(broad_shop_item_click_cnt_1d) AS broad_shopitem_click_cnt
        ,SUM(broad_shop_item_impression_cnt_1d) AS broad_shopitem_impression_cnt
        ,SUM(broad_order_item_cnt_1d) AS broad_order_item_cnt
        ,SUM(broad_gmv_amt_local_1d) AS broad_order_gmv_amt_local
        ,SUM(broad_gmv_amt_usd_1d) AS broad_order_gmv_amt_usd
        ,SUM(broad_order_cnt_1d) AS broad_order_cnt
        ,SUM(direct_shop_item_impression_cnt_1d) AS shopitem_impression_cnt
        ,SUM(direct_shop_item_click_cnt_1d) AS shopitem_click_cnt
        ,SUM(paid_order_cnt_1d) AS paid_order_cnt
        ,SUM(paid_order_cnt_ytd_1d) AS paid_order_cnt_ytd
        ,SUM(confirmed_order_cnt_1d) AS confirmed_order_cnt
        ,SUM(confirmed_order_cnt_ytd_1d) AS confirmed_order_cnt_ytd
        ,SUM(checkout_cnt_1d) AS checkout_cnt
        ,SUM(direct_add_to_cart_cnt_1d) AS add_to_cart_cnt
        ,SUM(add_to_cart_without_clicks_cnt_1d) AS add_to_cart_without_clicks_cnt
        ,SUM(broad_add_to_cart_cnt_1d) AS broad_add_to_cart_cnt
        ,SUM(view_cnt_1d) AS view_cnt
        ,SUM(product_click_cnt_1d) AS product_click_cnt
        ,SUM(video_play_complete) AS video_play_complete
        ,SUM(video_play_3s_cnt) AS video_play_3s_cnt
        ,SUM(video_play_5s_cnt) AS video_play_5s_cnt
        ,SUM(video_view) AS video_view
        ,SUM(view_duration) AS view_duration
        ,SUM(deduplicated_click_cnt) as deduplicated_click_cnt
        ,SUM(cps_dedup_click_cnt) as cps_dedup_click_cnt
        ,SUM(deduct_order_cnt) as deduct_order_cnt
        ,SUM(expense_rebate_free_credit_without_expiry) as expense_rebate_free_credit_without_expiry
        ,SUM(imp_attr_paid_order_cnt) as imp_attr_paid_order_cnt
        ,SUM(imp_attr_paid_order_item_sold_cnt) as imp_attr_paid_order_item_sold_cnt
        ,SUM(imp_attr_paid_order_gmv) as imp_attr_paid_order_gmv
        ,SUM(imp_attr_paid_order_gmv_usd) as imp_attr_paid_order_gmv_usd
        ,SUM(paid_order_item_sold_cnt) as paid_order_item_sold_cnt
        ,SUM(paid_broad_order_cnt) as paid_broad_order_cnt
        ,SUM(paid_broad_order_gmv) as paid_broad_order_gmv
        ,SUM(paid_broad_order_item_sold_cnt) as paid_broad_order_item_sold_cnt
        ,SUM(paid_broad_order_gmv_usd) as paid_broad_order_gmv_usd
        ,SUM(paid_checkout_cnt) as paid_checkout_cnt
        ,SUM(paid_agent_checkout_cnt) as paid_agent_checkout_cnt
        ,SUM(paid_no_click_order_item_sold_cnt) as paid_no_click_order_item_sold_cnt
        ,SUM(paid_no_click_order_gmv) as paid_no_click_order_gmv
        ,SUM(paid_no_click_order_cnt) as paid_no_click_order_cnt
        ,SUM(paid_no_click_order_gmv_usd) as paid_no_click_order_gmv_usd
        ,SUM(no_click_gmv_usd) as no_click_gmv_usd
FROM mp_paidads.dws_advertise_performance_1d__reg_s0_live
WHERE grass_region = upper('${region}')
AND grass_date = DATE('${grass_date}')
GROUP BY ads_id
        ,placement
        ,new_boost
        ,entrance
        ,tz_type;

CREATE OR REPLACE TEMPORARY VIEW traffic_mapping AS        
select 
entrance
,entry_point
,traffic_type
from mp_paidads.dim_entry_point_mapping_v2
group by 1,2,3
;

create or replace temporary view dim_shop_ext as
select shop_id
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
from mp_seller.dim_shop_ext__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   
;

create or replace temporary view dim_item as
select item_id
,shop_id
,price_usd
,level4_global_be_category
from mp_item.dim_item__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   
;

create or replace temporary view advertiser_tier_threshold as
select 
    cast(max(case when advertiser_tier = 'large_advertiser' then min_value_usd end) as int) as larger_advertiser_min_value
    ,cast(max(case when advertiser_tier = 'medium_advertiser' then min_value_usd end) as int) as medium_advertiser_min_value
    ,cast(max(case when advertiser_tier = 'small_advertiser' then min_value_usd end) as int) as small_advertiser_min_value
from mp_paidads.dim_advertiser_tier_threshold__reg_s0_live
where grass_region = upper('${region}')
;

create or replace temporary view seller_tier_threshold as
select 
    cast(max(case when seller_tier = 'large_seller' then min_value_usd end) as int) as larger_seller_min_value
    ,cast(max(case when seller_tier = 'medium_seller' then min_value_usd end) as int) as medium_seller_min_value
    ,cast(max(case when seller_tier = 'small_seller' then min_value_usd end) as int) as small_seller_min_value
from mp_paidads.dim_seller_tier_threshold__reg_s0_live
where grass_region = upper('${region}')
;

create or replace temporary view seller_tier as
select 
a.shop_id,
case when coalesce(a.gmv_usd_td,0)-coalesce(b.gmv_usd_td,0) >= larger_seller_min_value then 'large_seller'
        when coalesce(a.gmv_usd_td,0)-coalesce(b.gmv_usd_td,0) >= medium_seller_min_value and coalesce(a.gmv_usd_td,0)-coalesce(b.gmv_usd_td,0) < larger_seller_min_value then 'medium_seller'
        when coalesce(a.gmv_usd_td,0)-coalesce(b.gmv_usd_td,0) >= small_seller_min_value and coalesce(a.gmv_usd_td,0)-coalesce(b.gmv_usd_td,0) < medium_seller_min_value then 'small_seller'
        else 'micro_seller'
        end as seller_tier
from 
(
    select shop_id,gmv_usd_td from mp_order.dws_seller_gmv_td__reg_s0_live where grass_region = upper('${region}')
        and   grass_date = date_trunc('month', '${grass_date}') - interval '1' day
    and tz_type = 'local' and gmv_usd_td > 0
) a 
full join 
(
    select shop_id,gmv_usd_td from mp_order.dws_seller_gmv_td__reg_s0_live where grass_region = upper('${region}') 
    and grass_date = date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day
    and tz_type = 'local' and gmv_usd_td > 0
) b 
on a.shop_id = b.shop_id
left join seller_tier_threshold d 
on 1=1
;


create or replace temporary view advertiser_tier as
select 
    a.shop_id as shop_id
    ,case when coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) >= larger_advertiser_min_value then 'large_advertiser'
        when coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) >= medium_advertiser_min_value and coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) < larger_advertiser_min_value then 'medium_advertiser'
        when coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) >= small_advertiser_min_value and coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) < medium_advertiser_min_value then 'small_advertiser'
        else 'micro_advertiser'
        end as advertiser_tier
from 
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td 
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_region = upper('${region}') and tz_type = 'local'
    and grass_date = date_trunc('month', '${grass_date}') - interval '1' day
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) a 
full join 
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td  
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_region = upper('${region}') and tz_type = 'local'
    and grass_date = date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) b
on a.shop_id = b.shop_id
left join advertiser_tier_threshold d 
on 1=1
;

CREATE OR REPLACE TEMPORARY VIEW net_revenue AS
select 
    ads_id
    ,placement
    ,new_boost
    ,entrance
    ,tz_type
    ,sum(net_ads_revenue_usd_1d) as net_ads_revenue_usd_1d
    ,sum(free_ads_revenue_amt_usd_1d) as free_ads_revenue_amt_usd_1d
    ,sum(gross_ads_revenue_usd_1d) as gross_ads_revenue_usd_1d
from mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
where grass_region = upper('${region}')
AND grass_date = DATE('${grass_date}')
and ads_id is not null
GROUP BY ads_id
        ,placement
        ,new_boost
        ,entrance
        ,tz_type
;

INSERT OVERWRITE TABLE ads_advertise_mkt_1d__reg_s0_live PARTITION (tz_type, grass_region, grass_date)
    SELECT  
            ads.ads_id
            ,ads.shop_id
            ,ads.seller_id
            ,ads.pricing_type
            ,ads.campaign_id
            ,campaign_status
            ,campaign_status_text
            ,campaign_start_datetime
            ,campaign_end_datetime
            ,total_quota_local      AS campaign_total_quota_local
            ,total_quota_usd        AS campaign_total_quota_usd
            ,daily_quota_local      AS campaign_daily_quota_local
            ,daily_quota_usd        AS campaign_daily_quota_usd
            ,ads.placement
            ,ads.ads_type
            ,ads_create_datetime
            ,ads.item_id
            ,ads.item_name
            ,impression_cnt
            ,click_cnt
            ,order_cnt
            ,ads_items_sold_cnt
            ,ads_gmv_amt_local      AS ads_gmv_local
            ,ads_gmv_amt_usd        AS ads_gmv_usd
            ,expenditure_amt_local  AS ads_expenditure_amt_local
            ,expenditure_amt_usd    AS ads_expenditure_amt_usd
            ,CASE
                WHEN COALESCE(impression_cnt,0) > 0 THEN avg_ads_ranks / impression_cnt
                ELSE 0.0
            END                     AS avg_ads_ranks
            ,shopitem_impression_cnt
            ,shopitem_click_cnt
            ,broad_shopitem_click_cnt
            ,broad_shopitem_impression_cnt
            ,broad_order_item_cnt
            ,broad_order_gmv_amt_local
            ,broad_order_gmv_amt_usd
            ,broad_order_cnt
            ,paid_order_cnt
            ,paid_order_cnt_ytd
            ,confirmed_order_cnt
            ,confirmed_order_cnt_ytd
            ,checkout_cnt
            ,is_ads_active
            -------------------------------------------------------------------
            --  has_ads_performance = 1 if the following criteria is fulfilled:
            --  ads_impression > 0, OR
            --  ads_click > 0, OR
            --  ads_expenditure > 0, OR
            --  ads_order > 0, OR
            --  ads_gmv > 0
            --  Otherwise, has_ads_performance = 0
            -------------------------------------------------------------------
            ,CASE
                WHEN
                    COALESCE(impression_cnt, 0)
                    + COALESCE(click_cnt, 0)
                    + COALESCE(cps_dedup_click_cnt, 0)
                    + COALESCE(expenditure_amt_local, 0.0)
                    + COALESCE(order_cnt,0) + COALESCE(ads_gmv_amt_local,0) > 0.0
                THEN 1 ELSE 0
            END AS has_performance
            ,null as hit_daily_budget
            ,null as hit_total_budget
            ,is_cb_seller
            ,level1_global_be_category
            ,level1_fe_display_category_list
            ,level1_kpi_category_list
            ,level2_global_be_category
            ,level2_fe_display_category_list
            ,level2_kpi_category_list
            ,level3_global_be_category
            ,level3_fe_display_category_list
            ,level3_kpi_category_list
            ,shop_level1_global_be_category
            ,shop_level1_fe_display_category
            ,shop_level1_kpi_category
            ,add_to_cart_cnt
            ,add_to_cart_without_clicks_cnt
            ,broad_add_to_cart_cnt
            ,COALESCE(broad_order_gmv_amt_local / expenditure_amt_local, 0.0) as broad_roi
            ,cold_start_7d.cold_start_status_7d
            ,cold_start_14d.cold_start_status_14d
            ,cold_start_7d.first_7d_order_count
            ,cold_start_14d.first_14d_order_count
            ,first_order_date
            ,view_cnt
            ,product_click_cnt
            ,event.new_boost as new_boost
            ,ta_group_id
            ,target_premium_rate
            ,tag_ids
            ,event.entrance as entrance
            ,COALESCE(entry_point,'Undefined') as entry_point
            ,COALESCE(traffic_type,'Undefined') as traffic_type
            ,COALESCE(sub_product_type,'others') as sub_product_type
            ,COALESCE(product_type,'others') as product_type
            ,COALESCE(main_product_type,'Others') as main_product_type
            ,video_play_complete
            ,video_play_3s_cnt
            ,video_play_5s_cnt
            ,video_view
            ,view_duration
            ,COALESCE(seller_type,'Unknown') as seller_type
            ,COALESCE(seller_type_1p,'Unknown') as seller_type_1p
            ,COALESCE(is_cb_sip_affiliated,0) as is_cb_sip_affiliated
            ,COALESCE(is_local_sip_affiliated,0) as is_local_sip_affiliated
            ,price_usd
            ,level4_global_be_category
            ,coalesce(seller_tier, 'micro_seller')
            ,coalesce(advertiser_tier, 'micro_advertiser')
            ,net_ads_revenue_usd_1d
            ,free_ads_revenue_amt_usd_1d
            ,gross_ads_revenue_usd_1d
            ,deduplicated_click_cnt
            ,cps_dedup_click_cnt
            ,deduct_order_cnt
            ,potential_product_type
            ,ads_status
            ,expense_rebate_free_credit_without_expiry
            ,imp_attr_paid_order_cnt
            ,imp_attr_paid_order_item_sold_cnt
            ,imp_attr_paid_order_gmv
            ,imp_attr_paid_order_gmv_usd
            ,paid_order_item_sold_cnt
            ,paid_broad_order_cnt
            ,paid_broad_order_gmv
            ,paid_broad_order_item_sold_cnt
            ,paid_broad_order_gmv_usd
            ,paid_checkout_cnt
            ,paid_agent_checkout_cnt
            ,paid_no_click_order_item_sold_cnt
            ,paid_no_click_order_gmv
            ,paid_no_click_order_cnt
            ,paid_no_click_order_gmv_usd
            ,no_click_gmv_usd
            ,COALESCE(event.tz_type, 'local') as tz_type
            ,ads.grass_region as grass_region
            ,DATE('${grass_date}') as grass_date
    FROM (
        SELECT   ads_id
                ,ads_status
                ,ads_create_datetime
                ,placement
                ,ads_type
                ,shop_id
                ,seller_id
                ,case when placement in (45,46) then COALESCE(pricing_type,0) else pricing_type end as pricing_type
                ,item_id
                ,item_name
                ,campaign_id
                ,campaign_status
                ,campaign_status_text
                ,total_quota_local
                ,total_quota_usd
                ,daily_quota_local
                ,daily_quota_usd
                ,campaign_start_datetime
                ,campaign_end_datetime
                ,is_ads_active
                ,level1_global_be_category
                ,level1_fe_display_category_list
                ,level1_kpi_category_list
                ,level2_global_be_category
                ,level2_fe_display_category_list
                ,level2_kpi_category_list
                ,level3_global_be_category
                ,level3_fe_display_category_list
                ,level3_kpi_category_list
                ,ta_group_id
                ,target_premium_rate
                ,tag_ids
                ,sub_product_type
                ,product_type
                ,main_product_type
                ,potential_product_type
                ,grass_region
                ,grass_date
        FROM mp_paidads.dim_advertise__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
        AND pricing_type != 29
    ) ads
    LEFT OUTER JOIN (
        select * from ads_info
    ) event
    ON (ads.ads_id = event.ads_id
        AND ads.placement = event.placement)
    LEFT OUTER JOIN (
        SELECT
            shop_id
            ,is_cb_seller
            ,shop_level1_global_be_category
            ,shop_level1_fe_display_category
            ,shop_level1_kpi_category
            ,seller_type
            ,seller_type_1p
            ,grass_region
        FROM mp_paidads.dim_advertiser__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
    ) advertiser
    ON ads.shop_id = advertiser.shop_id
    AND ads.grass_region = advertiser.grass_region
    LEFT OUTER JOIN cold_start_7d
    ON  ads.ads_id = cold_start_7d.ads_id
    AND ads.placement = cold_start_7d.placement
    LEFT OUTER JOIN cold_start_14d
    ON  ads.ads_id = cold_start_14d.ads_id
    AND ads.placement = cold_start_14d.placement
    -- -- for first run and first backfill day
    -- LEFT OUTER JOIN first_order_begin
    -- ON  ads.ads_id = first_order_begin.ads_id
    -- AND ads.placement = first_order_begin.placement
    -- for schedul task
    LEFT OUTER JOIN first_order
    ON  ads.ads_id = first_order.ads_id
    AND ads.placement = first_order.placement
    left join traffic_mapping 
    on event.entrance = traffic_mapping.entrance
    left join dim_shop_ext 
    on ads.shop_id = dim_shop_ext.shop_id
    left join dim_item 
    on ads.shop_id = dim_item.shop_id
    and ads.item_id = dim_item.item_id
    left join advertiser_tier 
    on ads.shop_id = advertiser_tier.shop_id
    left join seller_tier 
    on ads.shop_id = seller_tier.shop_id
    left join net_revenue
    on ads.ads_id = net_revenue.ads_id
    AND ads.placement = net_revenue.placement
    and event.entrance = net_revenue.entrance
    and event.new_boost = net_revenue.new_boost
    and event.tz_type = net_revenue.tz_type
;

alter table ads_advertise_mkt_1d__${region}_s0_live add if not exists PARTITION(grass_date="${grass_date}");