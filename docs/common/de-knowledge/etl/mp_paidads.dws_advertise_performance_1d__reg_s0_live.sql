-- task_code: data_paidadsmart.studio_2522554  asset_id: 2522554
create or replace temporary view     dim 
as
SELECT
    dim.ads_id
    ,dim.placement
    ,dim.item_id
    ,dim.shop_id
    ,dim.grass_region
    ,dim.ads_type
    ,dim.seller_id
    ,dim.item_name
    ,dim.seller_name
    ,dim.pricing_type
    ,dim.campaign_id
    ,ex.exchange_rate
    ,array_min(FROM_JSON(filter_segments_age_list, 'array<bigint>')) AS filter_segments_age_start
    ,array_max(FROM_JSON(filter_segments_age_list, 'array<bigint>')) AS filter_segments_age_end
    ,filter_segments_gender_list
    ,filter_segments_location_list
    ,premium_segments_behavior_list
    ,filter_segments_category_list
FROM mp_paidads.dim_advertise__reg_s0_live dim
LEFT OUTER JOIN mp_order.dim_exchange_rate__reg_s0_live ex
ON dim.grass_region = ex.grass_region
WHERE dim.grass_region = upper('${region}')
AND ex.grass_region = upper('${region}')
AND dim.grass_date = date('${grass_date}') 
AND ex.grass_date = date('${grass_date}') ;

create or replace temporary view revenue
as
SELECT
    rev.ads_id
     ,rev.placement
     ,ads_type
     ,entrance
     ,shop_id
     ,seller_id
     ,item_id
     ,rev.pricing_type
     ,rev.campaign_id
     ,traffic_source 
     ,expenditure_amt_local_1d
     ,expenditure_amt_usd_1d
     ,tz_type
     ,DATE('${grass_date}') AS grass_date
FROM (
    select tz_type
        ,ads_id
        ,placement
        ,entrance
        ,pricing_type
        ,campaign_id
        ,traffic_source
        ,SUM(expenditure_amt_local) AS expenditure_amt_local_1d
        ,SUM(expenditure_amt_usd) AS expenditure_amt_usd_1d
    from (
        SELECT tz_type
            ,ads_id
            ,placement
            ,entrance
            ,pricing_type
            ,campaign_id
            -- in order to align with report_ng
            ,case when traffic_source=0 then null else traffic_source end as traffic_source
            ,COALESCE(total_expenditure_amt_local_1d,0.0) AS expenditure_amt_local
            ,COALESCE(total_expenditure_amt_usd_1d,0.0) AS expenditure_amt_usd
        FROM mp_paidads.dws_advertise_revenue_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
    ) group by tz_type,ads_id,placement,entrance,pricing_type,campaign_id,traffic_source
 ) rev
left join
dim
on rev.ads_id = dim.ads_id and rev.placement = dim.placement;


create or replace temporary view  base_oa as
SELECT
    order_id
    ,request_id
    ,query
    ,keyword
    ,ads_id
    ,shop_id
    ,item_id
    ,placement
    ,click_timestamp
    ,click_datetime
    ,event_timestamp
    ,event_datetime
    ,paid_timestamp
    ,paid_datetime
    ,confirmed_timestamp
    ,confirmed_datetime
    ,pricing_type
    ,daily_order_cnt
    ,order_cnt
    ,paid_order_cnt
    ,confirmed_order_cnt
    ,ads_order_gmv_local AS ads_order_gmv
    ,(ads_order_gmv_local/exchange_rate) AS ads_order_gmv_usd
    ,ads_item_sold_cnt
    ,broad_order_cnt
    ,broad_gmv_amt_local AS broad_gmv_amt
    ,(broad_gmv_amt_local/exchange_rate) AS broad_gmv_amt_usd
    ,broad_item_cnt
    ,broad_shop_item_click_cnt
    ,broad_shop_item_impression_cnt
    ,match_type
    ,matched_premium_segment_value_id
    ,entrance
    ,a.grass_region
    ,a.grass_date
    ,tz_type
FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live a
LEFT OUTER JOIN (
    SELECT
        grass_region
        ,grass_date
        ,exchange_rate
    FROM mp_order.dim_exchange_rate__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date >= date('${grass_date}')  - interval '1' day
    AND grass_date <= date('${grass_date}')
) ex_rate
ON a.grass_region = ex_rate.grass_region
and a.grass_date = ex_rate.grass_date
WHERE a.grass_region = upper('${region}')
and a.grass_date >= date('${grass_date}')  - interval '1' day
and a.grass_date <= date('${grass_date}')
AND (
    a.order_id is not NULL
    OR a.paid_datetime is not NULL
    OR a.confirmed_datetime is not NULL
);

create or replace temporary view oa as
SELECT
    tz_type
    ,base_oa.ads_id
    ,base_oa.grass_region
    ,base_oa.placement
    ,coalesce(base_oa.item_id, dim.item_id) as item_id
    ,keyword
    ,coalesce(base_oa.shop_id, dim.shop_id) as shop_id
    ,query
    ,coalesce(base_oa.pricing_type, dim.pricing_type) as pricing_type
    ,paid_order_cnt
    ,confirmed_order_cnt
    ,paid_datetime
    ,confirmed_datetime
    ,CASE
       WHEN base_oa.placement in (0,3,4,1000,1200) THEN COALESCE(base_oa.match_type, 0)
       ELSE 0
    END AS match_type
    ,CASE
        WHEN matched_premium_segment_value_id='0' THEN 'buyer_segment_behaviour_general_audience'
        WHEN matched_premium_segment_value_id='1' THEN 'buyer_segment_behaviour_view_in_shop'
        WHEN matched_premium_segment_value_id='2' THEN 'buyer_segment_behaviour_cart_in_shop'
        WHEN matched_premium_segment_value_id='3' THEN 'buyer_segment_behaviour_order_in_shop'
        WHEN matched_premium_segment_value_id='4' THEN 'buyer_segment_behaviour_like_in_shop'
        WHEN matched_premium_segment_value_id='10' THEN 'buyer_segment_behaviour_view_similar_item'
     END AS matched_premium_segment_value
    ,entrance
FROM base_oa
LEFT OUTER JOIN dim
ON (base_oa.ads_id = dim.ads_id
    AND base_oa.placement = dim.placement
    AND base_oa.grass_region = dim.grass_region
)
WHERE base_oa.grass_date >= date('${grass_date}')  - interval '1' day
and base_oa.grass_date <= date('${grass_date}')
AND (paid_datetime is not NULL OR confirmed_datetime is not NULL)
;



create or replace temporary view base_local as
SELECT
    campaign_id
    ,ads_id
    ,grass_region
    ,placement
    ,item_id
    ,keyword
    ,shop_id
    ,query
    ,match_type
    ,pricing_type
    ,matched_premium_segment_value
    ,entrance
    ,`location`
    ,traffic_source
    ,SUM(location_in_ads) AS location_in_ads
    ,SUM(impression_cnt) AS impression_cnt
    ,SUM(click_cnt) AS click_cnt
    ,SUM(click_before_deduction_cnt) AS click_before_deduction_cnt
    --,SUM(expenditure_amt_local) AS expenditure_amt_local
    ,SUM(daily_order_cnt) AS daily_order_cnt
    ,SUM(order_cnt) AS order_cnt
    ,SUM(checkout_cnt) AS checkout_cnt
    ,SUM(ads_item_sold_cnt) AS ads_item_sold_cnt
    ,SUM(ads_order_gmv_local) AS ads_order_gmv_local
    ,SUM(broad_order_cnt) AS broad_order_cnt
    ,SUM(broad_item_cnt) AS broad_item_cnt
    ,SUM(broad_gmv_amt_local) AS broad_gmv_amt_local
    ,SUM(shop_item_click_cnt) AS shop_item_click_cnt
    ,SUM(shop_item_impression_cnt) AS shop_item_impression_cnt
    ,SUM(broad_shop_item_click_cnt) AS broad_shop_item_click_cnt
    ,SUM(broad_shop_item_impression_cnt) AS broad_shop_item_impression_cnt
    ,SUM(add_to_cart_cnt) AS add_to_cart_cnt
    ,SUM(add_to_cart_without_clicks_cnt) AS add_to_cart_without_clicks_cnt
    ,SUM(broad_add_to_cart_cnt) AS broad_add_to_cart_cnt
    ,SUM(view) AS view_cnt
    ,SUM(product_click) AS product_click_cnt
    ,SUM(video_play_complete) as video_play_complete
    ,SUM(video_play_3s_cnt) as video_play_3s_cnt		
    ,SUM(video_play_5s_cnt) as video_play_5s_cnt		
    ,SUM(video_view) as video_view					
    ,SUM(view_duration) as view_duration
    ,SUM(deduplicated_click) as deduplicated_click
    ,SUM(cps_dedup_click) as cps_dedup_click
    ,SUM(deduct_order) as deduct_order	
    ,SUM(expense_rebate_free_credit_without_expiry) as expense_rebate_free_credit_without_expiry
    ,SUM(imp_attr_paid_order_cnt) as imp_attr_paid_order_cnt
    ,SUM(imp_attr_paid_order_item_sold_cnt) as imp_attr_paid_order_item_sold_cnt
    ,SUM(imp_attr_paid_order_gmv) as imp_attr_paid_order_gmv
    ,SUM(imp_attr_paid_order_gmv_usd) as imp_attr_paid_order_gmv_usd
    ,SUM(paid_order_item_sold_cnt) as paid_order_item_sold_cnt
    ,SUM(paid_broad_order_cnt) as paid_broad_order_cnt
    ,SUM(paid_broad_order_gmv) as paid_broad_order_gmv
    ,SUM(paid_broad_order_item_sold_cnt) as paid_broad_order_item_sold_cnt
    ,SUM(paid_broad_gmv_usd) as paid_broad_gmv_usd
    ,SUM(paid_checkout_cnt) as paid_checkout_cnt
    ,SUM(paid_agent_checkout_cnt) as paid_agent_checkout_cnt
    ,SUM(paid_no_click_order_item_sold_cnt) as paid_no_click_order_item_sold_cnt
    ,SUM(paid_no_click_order_gmv) as paid_no_click_order_gmv
    ,SUM(paid_no_click_order_cnt) as paid_no_click_order_cnt
    ,SUM(paid_no_click_order_gmv_usd) as paid_no_click_order_gmv_usd
    ,SUM(no_click_gmv_usd) as no_click_gmv_usd
from    (
    SELECT
    base_local.ads_id
    ,COALESCE(base_local.campaign_id, dim.campaign_id) AS campaign_id
    --careful , campaign_id may be empty, so group by will add more records
    ,broad_gmv_amt_local
    ,broad_item_cnt
    ,broad_order_cnt
    ,broad_shop_item_click_cnt
    ,broad_shop_item_impression_cnt
    ,case when base_local.placement in (3327, 3328, 3337, 3338, 3339) 
        then raw_click_cnt else click_cnt end as click_cnt
    --,expenditure_amt_local
    ,daily_order_cnt
    ,impression_cnt
    ,COALESCE(base_local.item_id, dim.item_id) AS item_id
    ,keyword
    ,location_in_ads
    ,coalesce(base_local.pricing_type, dim.pricing_type) as pricing_type
    ,CASE
       WHEN base_local.placement in (0,3,4,1000,1200) THEN COALESCE(match_type, 0)
       ELSE 0
    END AS match_type
    ,order_cnt
    ,checkout_cnt
    ,ads_item_sold_cnt
    ,ads_order_gmv_local
    ,base_local.placement
    ,query
    ,click_before_deduction_cnt
    ,COALESCE(base_local.shop_id, dim.shop_id) AS shop_id
    ,shop_item_click_cnt
    ,shop_item_impression_cnt
    ,CASE
        WHEN matched_premium_segment_value_id='0' THEN 'buyer_segment_behaviour_general_audience'
        WHEN matched_premium_segment_value_id='1' THEN 'buyer_segment_behaviour_view_in_shop'
        WHEN matched_premium_segment_value_id='2' THEN 'buyer_segment_behaviour_cart_in_shop'
        WHEN matched_premium_segment_value_id='3' THEN 'buyer_segment_behaviour_order_in_shop'
        WHEN matched_premium_segment_value_id='4' THEN 'buyer_segment_behaviour_like_in_shop'
        WHEN matched_premium_segment_value_id='10' THEN 'buyer_segment_behaviour_view_similar_item'
     END AS matched_premium_segment_value
    ,event_timestamp
    ,event_datetime
    ,base_local.grass_region
    ,entrance
    ,add_to_cart_cnt
    ,add_to_cart_without_clicks_cnt
    ,broad_add_to_cart_cnt
    ,base_local.`location`
    ,`view`
    ,product_click
    ,traffic_source
    ,video_play_complete 
    ,video_play_3s_cnt		
    ,video_play_5s_cnt		
    ,video_view					
    ,view_duration
    ,deduplicated_click
    ,cps_dedup_click
    ,deduct_order
    ,expense_rebate_free_credit_without_expiry / 100000.0 as expense_rebate_free_credit_without_expiry
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_item_sold_cnt
    ,imp_attr_paid_order_gmv
    ,imp_attr_paid_order_gmv_usd
    ,paid_order_item_sold_cnt
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv
    ,paid_broad_order_item_sold_cnt
    ,paid_broad_gmv_usd
    ,paid_checkout_cnt
    ,paid_agent_checkout_cnt
    ,paid_no_click_order_item_sold_cnt
    ,paid_no_click_order_gmv
    ,paid_no_click_order_cnt
    ,paid_no_click_order_gmv_usd
    ,no_click_gmv_usd
FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live base_local
LEFT OUTER JOIN dim
ON (base_local.ads_id = dim.ads_id
    AND base_local.placement = dim.placement
    AND base_local.grass_region = dim.grass_region
)
WHERE base_local.grass_region = upper('${region}')
AND base_local.grass_date = date('${grass_date}')
) t1
where   grass_region = upper('${region}')
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
;

create or replace temporary view full_oa_local
as 
SELECT
    base_local.ads_id AS ads_id
    ,base_local.placement AS placement
    --ads_id placement can not be empty 
    ,dim.ads_type AS ads_type
    ,COALESCE(base_local.campaign_id, dim.campaign_id)AS campaign_id
    ,base_local.keyword AS keywords
    ,COALESCE(base_local.match_type, 0) AS match_type
    ,COALESCE(base_local.item_id, dim.item_id) AS item_id
    ,dim.item_name AS item_name
    ,dim.shop_id AS shop_id
    ,dim.seller_id AS seller_id
    ,dim.seller_name AS seller_name
    ,base_local.query AS query
    ,base_local.pricing_type AS pricing_type
    ,base_local.impression_cnt AS impression_cnt
    ,base_local.click_cnt AS click_cnt
    ,base_local.order_cnt AS order_cnt
    ,base_local.checkout_cnt AS checkout_cnt
    ,base_local.ads_item_sold_cnt AS ads_items_sold_cnt
    ,base_local.ads_order_gmv_local AS ads_gmv_amt_local
    ,(base_local.ads_order_gmv_local / dim.exchange_rate) AS ads_gmv_amt_usd
    --,base_local.expenditure_amt_local
    --,(base_local.expenditure_amt_local / dim.exchange_rate) AS expenditure_amt_usd
    ,(location_in_ads / impression_cnt + 1) AS avg_ads_ranks
    ,base_local.broad_shop_item_click_cnt AS broad_shopitem_click_cnt
    ,base_local.broad_shop_item_impression_cnt AS broad_shopitem_impression_cnt
    ,base_local.broad_item_cnt AS broad_order_item_cnt
    ,base_local.broad_gmv_amt_local AS broad_order_gmv_amt_local
    ,(base_local.broad_gmv_amt_local / dim.exchange_rate) AS broad_order_gmv_amt_usd
    ,base_local.broad_order_cnt AS broad_order_cnt
    ,base_local.shop_item_impression_cnt AS shopitem_impression_cnt
    ,base_local.shop_item_click_cnt AS shopitem_click_cnt
    ,base_local.click_before_deduction_cnt AS click_before_deduction_cnt
    ,base_local.daily_order_cnt AS daily_order_cnt
    ,paid_order_cnt
    ,paid_order_cnt_ytd
    ,confirmed_order_cnt
    ,confirmed_order_cnt_ytd
    ,base_local.matched_premium_segment_value
    ,filter_segments_age_start
    ,filter_segments_age_end
    ,filter_segments_gender_list
    ,filter_segments_location_list
    ,premium_segments_behavior_list
    ,filter_segments_category_list
    ,base_local.entrance as entrance
    ,base_local.add_to_cart_cnt as add_to_cart_cnt
    ,base_local.add_to_cart_without_clicks_cnt as add_to_cart_without_clicks_cnt
    ,base_local.broad_add_to_cart_cnt as broad_add_to_cart_cnt
    ,base_local.`location` as `location`
    ,view_cnt
    ,product_click_cnt
    ,traffic_source
    ,base_local.video_play_complete 
    ,base_local.video_play_3s_cnt		
    ,base_local.video_play_5s_cnt		
    ,base_local.video_view					
    ,base_local.view_duration	
    ,base_local.deduplicated_click
    ,base_local.cps_dedup_click
    ,base_local.deduct_order	
    ,base_local.expense_rebate_free_credit_without_expiry	
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_item_sold_cnt
    ,imp_attr_paid_order_gmv
    ,imp_attr_paid_order_gmv_usd
    ,paid_order_item_sold_cnt
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv
    ,paid_broad_order_item_sold_cnt
    ,paid_broad_gmv_usd
    ,paid_checkout_cnt
    ,paid_agent_checkout_cnt
    ,paid_no_click_order_item_sold_cnt
    ,paid_no_click_order_gmv
    ,paid_no_click_order_cnt
    ,paid_no_click_order_gmv_usd
    ,no_click_gmv_usd
    ,base_local.grass_region AS grass_region
    ,DATE('${grass_date}') AS grass_date
FROM base_local
LEFT OUTER JOIN dim
ON (base_local.ads_id = dim.ads_id
    AND base_local.placement = dim.placement
    AND base_local.grass_region = dim.grass_region
)
LEFT OUTER JOIN (
SELECT
    ads_id
    ,grass_region
    ,placement
    ,item_id
    ,keyword
    ,shop_id
    ,query
    ,pricing_type
    ,match_type
    ,matched_premium_segment_value
    ,entrance
    ,sum(case when date(paid_datetime) = DATE('${grass_date}') then paid_order_cnt else 0 end) as paid_order_cnt
    ,sum(case when date(paid_datetime) = DATE('${grass_date}') - interval '1' day then paid_order_cnt else 0 end) as paid_order_cnt_ytd
FROM oa
WHERE (date(paid_datetime) = DATE('${grass_date}') OR date(paid_datetime) = DATE('${grass_date}') - interval '1' day)
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
) oa1
ON (base_local.ads_id = oa1.ads_id
    AND base_local.grass_region = oa1.grass_region
    AND base_local.placement = oa1.placement
    AND COALESCE(base_local.item_id,0) = COALESCE(oa1.item_id,0)
    AND COALESCE(base_local.keyword,'') = COALESCE(oa1.keyword,'')
    AND COALESCE(base_local.query,'') = COALESCE(oa1.query,'')
    AND base_local.match_type = oa1.match_type
    AND COALESCE(base_local.matched_premium_segment_value,'') = COALESCE(oa1.matched_premium_segment_value,'')
    AND COALESCE(base_local.entrance, 0) = COALESCE(oa1.entrance, 0)
    AND base_local.pricing_type <=> oa1.pricing_type
)
LEFT OUTER JOIN (
SELECT
    ads_id
    ,grass_region
    ,placement
    ,item_id
    ,keyword
    ,shop_id
    ,query
    ,pricing_type
    ,match_type
    ,matched_premium_segment_value
    ,entrance
    ,sum(case when date(confirmed_datetime) = DATE('${grass_date}') then confirmed_order_cnt else 0 end) as confirmed_order_cnt
    ,sum(case when date(confirmed_datetime) = DATE('${grass_date}') - interval '1' day then confirmed_order_cnt else 0 end) as confirmed_order_cnt_ytd
FROM oa
WHERE (date(confirmed_datetime) = DATE('${grass_date}') OR date(confirmed_datetime) = DATE('${grass_date}') - interval '1' day)
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
) oa2
ON (base_local.ads_id = oa2.ads_id
    AND base_local.grass_region = oa2.grass_region
    AND base_local.placement = oa2.placement
    AND COALESCE(base_local.item_id,0) = COALESCE(oa2.item_id,0)
    AND COALESCE(base_local.keyword,'') = COALESCE(oa2.keyword,'')
    AND COALESCE(base_local.query,'') = COALESCE(oa2.query,'')
    AND base_local.match_type = oa2.match_type
    AND COALESCE(base_local.matched_premium_segment_value,'') = COALESCE(oa2.matched_premium_segment_value,'')
    AND COALESCE(base_local.entrance, 0) = COALESCE(oa2.entrance, 0)
    AND base_local.pricing_type <=> oa2.pricing_type
)
;

INSERT OVERWRITE TABLE dws_advertise_performance_1d__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
select 
    coalesce(oa.ads_id, revenue.ads_id) as ads_id,
    coalesce(oa.placement, revenue.placement) as placement,
    coalesce(oa.ads_type, revenue.ads_type) as ads_type,
    coalesce(oa.shop_id, revenue.shop_id) as shop_id,
    coalesce(oa.seller_id, revenue.seller_id) as seller_id,
     impression_cnt_1d
     ,click_cnt_1d
     ,order_cnt_1d
     ,paid_order_cnt_ytd_1d
     ,confirmed_order_cnt_ytd_1d
     ,ads_items_sold_cnt_1d
     ,ads_gmv_amt_local_1d
     ,ads_gmv_amt_usd_1d
     ,expenditure_amt_local_1d
     ,expenditure_amt_usd_1d
     ,coalesce(oa.entrance, revenue.entrance) as entrance
     ,broad_gmv_amt_local_1d
     ,broad_gmv_amt_usd_1d
     ,avg_ads_ranks ,broad_shop_item_click_cnt_1d ,broad_shop_item_impression_cnt_1d ,broad_order_item_cnt_1d ,broad_order_cnt_1d ,
     direct_shop_item_impression_cnt_1d ,direct_shop_item_click_cnt_1d ,paid_order_cnt_1d ,confirmed_order_cnt_1d ,checkout_cnt_1d ,
     direct_add_to_cart_cnt_1d ,add_to_cart_without_clicks_cnt_1d ,broad_add_to_cart_cnt_1d ,view_cnt_1d ,product_click_cnt_1d ,
     case when(coalesce(oa.placement, revenue.placement) in (44,4400,4401,4402,4405) and coalesce(oa.traffic_source, revenue.traffic_source) in (4)) then 1 else 0 end as new_boost ,
     coalesce(oa.pricing_type, revenue.pricing_type) as pricing_type,
     coalesce(oa.campaign_id, revenue.campaign_id) as campaign_id,
     coalesce(oa.item_id, revenue.item_id) as item_id,
     coalesce(oa.traffic_source, revenue.traffic_source) as traffic_source
     ,video_play_complete
     ,video_play_3s_cnt
     ,video_play_5s_cnt
     ,video_view
     ,view_duration
     ,deduplicated_click as deduplicated_click_cnt
     ,cps_dedup_click as cps_dedup_click_cnt
     ,deduct_order as deduct_order_cnt
     ,expense_rebate_free_credit_without_expiry
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_item_sold_cnt
    ,imp_attr_paid_order_gmv
    ,imp_attr_paid_order_gmv_usd
    ,paid_order_item_sold_cnt
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv
    ,paid_broad_order_item_sold_cnt
    ,paid_broad_gmv_usd
    ,paid_checkout_cnt
    ,paid_agent_checkout_cnt
    ,paid_no_click_order_item_sold_cnt
    ,paid_no_click_order_gmv
    ,paid_no_click_order_cnt
    ,paid_no_click_order_gmv_usd
    ,no_click_gmv_usd
     ,upper('${region}') AS grass_region
     ,DATE('${grass_date}') AS grass_date
from
(
    select ads_id,placement,ads_type,entrance,item_id,
            shop_id,seller_id,pricing_type,campaign_id,traffic_source,
        SUM(impression_cnt) as impression_cnt_1d,
        SUM(click_cnt) as click_cnt_1d,
        SUM(order_cnt) as order_cnt_1d,
        SUM(paid_order_cnt_ytd) as paid_order_cnt_ytd_1d,
        SUM(confirmed_order_cnt_ytd) as confirmed_order_cnt_ytd_1d,
        SUM(ads_items_sold_cnt) as ads_items_sold_cnt_1d,
        SUM(ads_gmv_amt_local) as ads_gmv_amt_local_1d,
        SUM(ads_gmv_amt_usd) as ads_gmv_amt_usd_1d,
        SUM(broad_order_gmv_amt_local) as broad_gmv_amt_local_1d,
        SUM(broad_order_gmv_amt_usd) as broad_gmv_amt_usd_1d,
        SUM(avg_ads_ranks) as avg_ads_ranks,
        SUM(broad_shopitem_click_cnt) as broad_shop_item_click_cnt_1d,
        SUM(broad_shopitem_impression_cnt) as broad_shop_item_impression_cnt_1d,
        SUM(broad_order_item_cnt) as broad_order_item_cnt_1d,
        SUM(broad_order_cnt) as broad_order_cnt_1d,
        SUM(shopitem_impression_cnt) as direct_shop_item_impression_cnt_1d,
        SUM(shopitem_click_cnt) as direct_shop_item_click_cnt_1d,
        SUM(paid_order_cnt) as paid_order_cnt_1d,
        SUM(confirmed_order_cnt) as confirmed_order_cnt_1d,
        SUM(checkout_cnt) as checkout_cnt_1d,
        SUM(add_to_cart_cnt) as direct_add_to_cart_cnt_1d,
        SUM(add_to_cart_without_clicks_cnt) as add_to_cart_without_clicks_cnt_1d,
        SUM(broad_add_to_cart_cnt) as broad_add_to_cart_cnt_1d,
        SUM(view_cnt) as view_cnt_1d,
        SUM(product_click_cnt) as product_click_cnt_1d,
        SUM(video_play_complete ) as video_play_complete ,
        SUM(video_play_3s_cnt) as video_play_3s_cnt,
        SUM(video_play_5s_cnt) as video_play_5s_cnt,
        SUM(video_view) as video_view,
        SUM(view_duration) as view_duration,
        SUM(deduplicated_click) as deduplicated_click,
        SUM(cps_dedup_click) as cps_dedup_click,
        SUM(deduct_order) as deduct_order,
        SUM(expense_rebate_free_credit_without_expiry) as expense_rebate_free_credit_without_expiry
        ,SUM(imp_attr_paid_order_cnt) as imp_attr_paid_order_cnt
        ,SUM(imp_attr_paid_order_item_sold_cnt) as imp_attr_paid_order_item_sold_cnt
        ,SUM(imp_attr_paid_order_gmv) as imp_attr_paid_order_gmv
        ,SUM(imp_attr_paid_order_gmv_usd) as imp_attr_paid_order_gmv_usd
        ,SUM(paid_order_item_sold_cnt) as paid_order_item_sold_cnt
        ,SUM(paid_broad_order_cnt) as paid_broad_order_cnt
        ,SUM(paid_broad_order_gmv) as paid_broad_order_gmv
        ,SUM(paid_broad_order_item_sold_cnt) as paid_broad_order_item_sold_cnt
        ,SUM(paid_broad_gmv_usd) as paid_broad_gmv_usd
        ,SUM(paid_checkout_cnt) as paid_checkout_cnt
        ,SUM(paid_agent_checkout_cnt) as paid_agent_checkout_cnt
        ,SUM(paid_no_click_order_item_sold_cnt) as paid_no_click_order_item_sold_cnt
        ,SUM(paid_no_click_order_gmv) as paid_no_click_order_gmv
        ,SUM(paid_no_click_order_cnt) as paid_no_click_order_cnt
        ,SUM(paid_no_click_order_gmv_usd) as paid_no_click_order_gmv_usd
        ,SUM(no_click_gmv_usd) as no_click_gmv_usd
    from full_oa_local
    group by 1,2,3,4,5,6,7,8,9,10
) oa
full join 
(
    select * from revenue
    where tz_type='local'
)revenue
on oa.ads_id <=> revenue.ads_id
and oa.placement <=> revenue.placement
and oa.entrance <=> revenue.entrance
and oa.item_id <=> revenue.item_id
and oa.pricing_type <=> revenue.pricing_type
and oa.campaign_id <=> revenue.campaign_id
and oa.traffic_source <=> revenue.traffic_source
-- one ads can have multi pricing_type and campaign_id 
-- is that it can change anytime, so db will have one, and tracking have 2
;

set time zone 'Asia/Singapore'
;
create or replace temporary view  base_regional as
SELECT
    campaign_id
    ,ads_id
    ,grass_region
    ,placement
    ,item_id
    ,keyword
    ,shop_id
    ,query
    ,match_type
    ,pricing_type
    ,matched_premium_segment_value
    ,entrance
    ,`location`
    ,traffic_source
    ,SUM(location_in_ads) AS location_in_ads
    ,SUM(impression_cnt) AS impression_cnt
    ,SUM(click_cnt) AS click_cnt
    ,SUM(click_before_deduction_cnt) AS click_before_deduction_cnt
    --,SUM(expenditure_amt_local) AS expenditure_amt_local
    ,SUM(daily_order_cnt) AS daily_order_cnt
    ,SUM(order_cnt) AS order_cnt
    ,SUM(checkout_cnt) AS checkout_cnt
    ,SUM(ads_item_sold_cnt) AS ads_item_sold_cnt
    ,SUM(ads_order_gmv_local) AS ads_order_gmv_local
    ,SUM(broad_order_cnt) AS broad_order_cnt
    ,SUM(broad_item_cnt) AS broad_item_cnt
    ,SUM(broad_gmv_amt_local) AS broad_gmv_amt_local
    ,SUM(shop_item_click_cnt) AS shop_item_click_cnt
    ,SUM(shop_item_impression_cnt) AS shop_item_impression_cnt
    ,SUM(broad_shop_item_click_cnt) AS broad_shop_item_click_cnt
    ,SUM(broad_shop_item_impression_cnt) AS broad_shop_item_impression_cnt
    ,SUM(add_to_cart_cnt) AS add_to_cart_cnt
    ,SUM(add_to_cart_without_clicks_cnt) AS add_to_cart_without_clicks_cnt
    ,SUM(broad_add_to_cart_cnt) AS broad_add_to_cart_cnt
    ,SUM(view) AS view_cnt
    ,SUM(product_click) AS product_click_cnt
    ,SUM(video_play_complete) AS video_play_complete
    ,SUM(video_play_3s_cnt) AS video_play_3s_cnt	
    ,SUM(video_play_5s_cnt) AS video_play_5s_cnt	
    ,SUM(video_view) AS video_view	
    ,SUM(view_duration) AS view_duration	
    ,SUM(deduplicated_click) as deduplicated_click
    ,SUM(cps_dedup_click) as cps_dedup_click
    ,SUM(deduct_order) as deduct_order	
    ,SUM(expense_rebate_free_credit_without_expiry) as expense_rebate_free_credit_without_expiry	
    ,SUM(imp_attr_paid_order_cnt) as imp_attr_paid_order_cnt
    ,SUM(imp_attr_paid_order_item_sold_cnt) as imp_attr_paid_order_item_sold_cnt
    ,SUM(imp_attr_paid_order_gmv) as imp_attr_paid_order_gmv
    ,SUM(imp_attr_paid_order_gmv_usd) as imp_attr_paid_order_gmv_usd
    ,SUM(paid_order_item_sold_cnt) as paid_order_item_sold_cnt
    ,SUM(paid_broad_order_cnt) as paid_broad_order_cnt
    ,SUM(paid_broad_order_gmv) as paid_broad_order_gmv
    ,SUM(paid_broad_order_item_sold_cnt) as paid_broad_order_item_sold_cnt
    ,SUM(paid_broad_gmv_usd) as paid_broad_gmv_usd
    ,SUM(paid_checkout_cnt) as paid_checkout_cnt
    ,SUM(paid_agent_checkout_cnt) as paid_agent_checkout_cnt
    ,SUM(paid_no_click_order_item_sold_cnt) as paid_no_click_order_item_sold_cnt
    ,SUM(paid_no_click_order_gmv) as paid_no_click_order_gmv
    ,SUM(paid_no_click_order_cnt) as paid_no_click_order_cnt
    ,SUM(paid_no_click_order_gmv_usd) as paid_no_click_order_gmv_usd
    ,SUM(no_click_gmv_usd) as no_click_gmv_usd
from    (
    SELECT
    base_regional.ads_id
    ,COALESCE(base_regional.campaign_id, dim.campaign_id) AS campaign_id
    --careful , campaign_id may be empty, so group by will add more records
    ,broad_gmv_amt_local
    ,broad_item_cnt
    ,broad_order_cnt
    ,broad_shop_item_click_cnt
    ,broad_shop_item_impression_cnt
    ,case when base_regional.placement in (3327, 3328, 3337, 3338, 3339) 
        then raw_click_cnt else click_cnt end as click_cnt
    --,expenditure_amt_local
    ,daily_order_cnt
    ,impression_cnt
    ,COALESCE(base_regional.item_id, dim.item_id) AS item_id
    ,keyword
    ,location_in_ads
    ,coalesce(base_regional.pricing_type, dim.pricing_type) as pricing_type
    ,CASE
       WHEN base_regional.placement in (0,3,4,1000,1200) THEN COALESCE(match_type, 0)
       ELSE 0
    END AS match_type
    ,order_cnt
    ,checkout_cnt
    ,ads_item_sold_cnt
    ,ads_order_gmv_local
    ,base_regional.placement
    ,query
    ,click_before_deduction_cnt
    ,COALESCE(base_regional.shop_id, dim.shop_id) AS shop_id
    ,shop_item_click_cnt
    ,shop_item_impression_cnt
    ,CASE
        WHEN matched_premium_segment_value_id='0' THEN 'buyer_segment_behaviour_general_audience'
        WHEN matched_premium_segment_value_id='1' THEN 'buyer_segment_behaviour_view_in_shop'
        WHEN matched_premium_segment_value_id='2' THEN 'buyer_segment_behaviour_cart_in_shop'
        WHEN matched_premium_segment_value_id='3' THEN 'buyer_segment_behaviour_order_in_shop'
        WHEN matched_premium_segment_value_id='4' THEN 'buyer_segment_behaviour_like_in_shop'
        WHEN matched_premium_segment_value_id='10' THEN 'buyer_segment_behaviour_view_similar_item'
     END AS matched_premium_segment_value
    ,event_timestamp
    ,event_datetime
    ,base_regional.grass_region
    ,entrance
    ,add_to_cart_cnt
    ,add_to_cart_without_clicks_cnt
    ,broad_add_to_cart_cnt
    ,base_regional.`location`
    ,`view`
    ,product_click
    ,traffic_source
    ,video_play_complete 
    ,video_play_3s_cnt		
    ,video_play_5s_cnt		
    ,video_view					
    ,view_duration
    ,deduplicated_click
    ,cps_dedup_click
    ,deduct_order	
    ,expense_rebate_free_credit_without_expiry / 100000.0 as expense_rebate_free_credit_without_expiry
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_item_sold_cnt
    ,imp_attr_paid_order_gmv
    ,imp_attr_paid_order_gmv_usd
    ,paid_order_item_sold_cnt
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv
    ,paid_broad_order_item_sold_cnt
    ,paid_broad_gmv_usd
    ,paid_checkout_cnt
    ,paid_agent_checkout_cnt
    ,paid_no_click_order_item_sold_cnt
    ,paid_no_click_order_gmv
    ,paid_no_click_order_cnt
    ,paid_no_click_order_gmv_usd
    ,no_click_gmv_usd
FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live base_regional
LEFT OUTER JOIN dim
ON (base_regional.ads_id = dim.ads_id
    AND base_regional.placement = dim.placement
    AND base_regional.grass_region = dim.grass_region
)
WHERE base_regional.grass_region = upper('${region}')
AND base_regional.grass_date BETWEEN DATE_SUB(DATE('${grass_date}'), 1) AND DATE('${grass_date}')
AND   timestamp >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
AND   timestamp < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
) t2
where   grass_region = upper('${region}')
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
;

create or replace temporary view full_oa_regional
as 
SELECT
    base_regional.ads_id AS ads_id
    ,base_regional.placement AS placement
    ,dim.ads_type AS ads_type
    ,COALESCE(base_regional.campaign_id, dim.campaign_id) AS campaign_id
    ,base_regional.keyword AS keywords
    ,COALESCE(base_regional.match_type, 0) AS match_type
    ,COALESCE(base_regional.item_id, dim.item_id) AS item_id
    ,dim.item_name AS item_name
    ,dim.shop_id AS shop_id
    ,dim.seller_id AS seller_id
    ,dim.seller_name AS seller_name
    ,base_regional.query AS query
    ,base_regional.pricing_type AS pricing_type
    ,base_regional.impression_cnt AS impression_cnt
    ,base_regional.click_cnt AS click_cnt
    ,base_regional.order_cnt AS order_cnt
    ,base_regional.checkout_cnt AS checkout_cnt
    ,base_regional.ads_item_sold_cnt AS ads_items_sold_cnt
    ,base_regional.ads_order_gmv_local AS ads_gmv_amt_local
    ,(base_regional.ads_order_gmv_local / dim.exchange_rate) AS ads_gmv_amt_usd
    --,base_regional.expenditure_amt_local
    --,(base_regional.expenditure_amt_local / dim.exchange_rate) AS expenditure_amt_usd
    ,(location_in_ads / impression_cnt + 1) AS avg_ads_ranks
    ,base_regional.broad_shop_item_click_cnt AS broad_shopitem_click_cnt
    ,base_regional.broad_shop_item_impression_cnt AS broad_shopitem_impression_cnt
    ,base_regional.broad_item_cnt AS broad_order_item_cnt
    ,base_regional.broad_gmv_amt_local AS broad_order_gmv_amt_local
    ,(base_regional.broad_gmv_amt_local / dim.exchange_rate) AS broad_order_gmv_amt_usd
    ,base_regional.broad_order_cnt AS broad_order_cnt
    ,base_regional.shop_item_impression_cnt AS shopitem_impression_cnt
    ,base_regional.shop_item_click_cnt AS shopitem_click_cnt
    ,base_regional.click_before_deduction_cnt AS click_before_deduction_cnt
    ,base_regional.daily_order_cnt AS daily_order_cnt
    ,null as paid_order_cnt
    ,null as paid_order_cnt_ytd
    ,null as confirmed_order_cnt
    ,null as confirmed_order_cnt_ytd
    ,base_regional.matched_premium_segment_value
    ,filter_segments_age_start
    ,filter_segments_age_end
    ,filter_segments_gender_list
    ,filter_segments_location_list
    ,premium_segments_behavior_list
    ,filter_segments_category_list
    ,base_regional.entrance as entrance
    ,base_regional.add_to_cart_cnt as add_to_cart_cnt
    ,base_regional.add_to_cart_without_clicks_cnt as add_to_cart_without_clicks_cnt
    ,base_regional.broad_add_to_cart_cnt as broad_add_to_cart_cnt
    ,base_regional.`location` as `location`
    ,view_cnt
    ,product_click_cnt
    ,traffic_source
    ,video_play_complete 
    ,video_play_3s_cnt		
    ,video_play_5s_cnt		
    ,video_view					
    ,view_duration
    ,deduplicated_click
    ,cps_dedup_click
    ,deduct_order		
    ,expense_rebate_free_credit_without_expiry	
    ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_item_sold_cnt
    ,imp_attr_paid_order_gmv
    ,imp_attr_paid_order_gmv_usd
    ,paid_order_item_sold_cnt
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv
    ,paid_broad_order_item_sold_cnt
    ,paid_broad_gmv_usd
    ,paid_checkout_cnt	
    ,paid_agent_checkout_cnt
    ,paid_no_click_order_item_sold_cnt
    ,paid_no_click_order_gmv
    ,paid_no_click_order_cnt
    ,paid_no_click_order_gmv_usd
    ,no_click_gmv_usd
    ,base_regional.grass_region AS grass_region
    ,DATE('${grass_date}') AS grass_date
FROM base_regional
LEFT OUTER JOIN dim
ON (base_regional.ads_id = dim.ads_id
    AND base_regional.placement = dim.placement
    AND base_regional.grass_region = dim.grass_region
)
;


INSERT OVERWRITE TABLE dws_advertise_performance_1d__reg_s0_live PARTITION (tz_type='regional', grass_region, grass_date)
select 
    coalesce(oa.ads_id, revenue.ads_id) as ads_id,
    coalesce(oa.placement, revenue.placement) as placement,
    coalesce(oa.ads_type, revenue.ads_type) as ads_type,
    coalesce(oa.shop_id, revenue.shop_id) as shop_id,
    coalesce(oa.seller_id, revenue.seller_id) as seller_id,
     impression_cnt_1d
     ,click_cnt_1d
     ,order_cnt_1d
     ,paid_order_cnt_ytd_1d
     ,confirmed_order_cnt_ytd_1d
     ,ads_items_sold_cnt_1d
     ,ads_gmv_amt_local_1d
     ,ads_gmv_amt_usd_1d
     ,expenditure_amt_local_1d
     ,expenditure_amt_usd_1d
     ,coalesce(oa.entrance, revenue.entrance) as entrance
     ,broad_gmv_amt_local_1d
     ,broad_gmv_amt_usd_1d
     ,avg_ads_ranks ,broad_shop_item_click_cnt_1d ,broad_shop_item_impression_cnt_1d ,broad_order_item_cnt_1d ,broad_order_cnt_1d
     ,direct_shop_item_impression_cnt_1d ,direct_shop_item_click_cnt_1d ,paid_order_cnt_1d ,confirmed_order_cnt_1d ,checkout_cnt_1d
     ,direct_add_to_cart_cnt_1d ,add_to_cart_without_clicks_cnt_1d ,broad_add_to_cart_cnt_1d ,view_cnt_1d ,product_click_cnt_1d
     ,case when(coalesce(oa.placement, revenue.placement) in (44,4400,4401,4402,4405) and coalesce(oa.traffic_source, revenue.traffic_source) in (4)) then 1 else 0 end as new_boost
     ,coalesce(oa.pricing_type, revenue.pricing_type) as pricing_type
     ,coalesce(oa.campaign_id, revenue.campaign_id) as campaign_id
     ,coalesce(oa.item_id, revenue.item_id) as item_id
     ,coalesce(oa.traffic_source, revenue.traffic_source) as traffic_source
     ,video_play_complete
     ,video_play_3s_cnt
     ,video_play_5s_cnt
     ,video_view
     ,view_duration
     ,deduplicated_click as deduplicated_click_cnt
     ,cps_dedup_click as cps_dedup_click_cnt
     ,deduct_order as deduct_order_cnt
     ,expense_rebate_free_credit_without_expiry
     ,imp_attr_paid_order_cnt
    ,imp_attr_paid_order_item_sold_cnt
    ,imp_attr_paid_order_gmv
    ,imp_attr_paid_order_gmv_usd
    ,paid_order_item_sold_cnt
    ,paid_broad_order_cnt
    ,paid_broad_order_gmv
    ,paid_broad_order_item_sold_cnt
    ,paid_broad_gmv_usd
    ,paid_checkout_cnt
    ,paid_agent_checkout_cnt
    ,paid_no_click_order_item_sold_cnt
    ,paid_no_click_order_gmv
    ,paid_no_click_order_cnt
    ,paid_no_click_order_gmv_usd
    ,no_click_gmv_usd
     ,upper('${region}') AS grass_region
     ,DATE('${grass_date}') AS grass_date
from
(
    select ads_id,placement,ads_type,entrance,item_id,
            shop_id,seller_id,pricing_type,campaign_id,traffic_source,
        SUM(impression_cnt) as impression_cnt_1d,
        SUM(click_cnt) as click_cnt_1d,
        SUM(order_cnt) as order_cnt_1d,
        SUM(paid_order_cnt_ytd) as paid_order_cnt_ytd_1d,
        SUM(confirmed_order_cnt_ytd) as confirmed_order_cnt_ytd_1d,
        SUM(ads_items_sold_cnt) as ads_items_sold_cnt_1d,
        SUM(ads_gmv_amt_local) as ads_gmv_amt_local_1d,
        SUM(ads_gmv_amt_usd) as ads_gmv_amt_usd_1d,
        SUM(broad_order_gmv_amt_local) as broad_gmv_amt_local_1d,
        SUM(broad_order_gmv_amt_usd) as broad_gmv_amt_usd_1d,
        SUM(avg_ads_ranks) as avg_ads_ranks,
        SUM(broad_shopitem_click_cnt) as broad_shop_item_click_cnt_1d,
        SUM(broad_shopitem_impression_cnt) as broad_shop_item_impression_cnt_1d,
        SUM(broad_order_item_cnt) as broad_order_item_cnt_1d,
        SUM(broad_order_cnt) as broad_order_cnt_1d,
        SUM(shopitem_impression_cnt) as direct_shop_item_impression_cnt_1d,
        SUM(shopitem_click_cnt) as direct_shop_item_click_cnt_1d,
        SUM(paid_order_cnt) as paid_order_cnt_1d,
        SUM(confirmed_order_cnt) as confirmed_order_cnt_1d,
        SUM(checkout_cnt) as checkout_cnt_1d,
        SUM(add_to_cart_cnt) as direct_add_to_cart_cnt_1d,
        SUM(add_to_cart_without_clicks_cnt) as add_to_cart_without_clicks_cnt_1d,
        SUM(broad_add_to_cart_cnt) as broad_add_to_cart_cnt_1d,
        SUM(view_cnt) as view_cnt_1d,
        SUM(product_click_cnt) as product_click_cnt_1d,
        SUM(video_play_complete) AS video_play_complete,
        SUM(video_play_3s_cnt) AS video_play_3s_cnt,
        SUM(video_play_5s_cnt) AS video_play_5s_cnt,
        SUM(video_view) AS video_view,
        SUM(view_duration) AS view_duration,
        SUM(deduplicated_click) as deduplicated_click,
        SUM(cps_dedup_click) as cps_dedup_click,
        SUM(deduct_order) as deduct_order,
        SUM(expense_rebate_free_credit_without_expiry) as expense_rebate_free_credit_without_expiry
        ,SUM(imp_attr_paid_order_cnt) as imp_attr_paid_order_cnt
        ,SUM(imp_attr_paid_order_item_sold_cnt) as imp_attr_paid_order_item_sold_cnt
        ,SUM(imp_attr_paid_order_gmv) as imp_attr_paid_order_gmv
        ,SUM(imp_attr_paid_order_gmv_usd) as imp_attr_paid_order_gmv_usd
        ,SUM(paid_order_item_sold_cnt) as paid_order_item_sold_cnt
        ,SUM(paid_broad_order_cnt) as paid_broad_order_cnt
        ,SUM(paid_broad_order_gmv) as paid_broad_order_gmv
        ,SUM(paid_broad_order_item_sold_cnt) as paid_broad_order_item_sold_cnt
        ,SUM(paid_broad_gmv_usd) as paid_broad_gmv_usd
        ,SUM(paid_checkout_cnt) as paid_checkout_cnt
        ,SUM(paid_agent_checkout_cnt) as paid_agent_checkout_cnt
        ,SUM(paid_no_click_order_item_sold_cnt) as paid_no_click_order_item_sold_cnt
        ,SUM(paid_no_click_order_gmv) as paid_no_click_order_gmv
        ,SUM(paid_no_click_order_cnt) as paid_no_click_order_cnt
        ,SUM(paid_no_click_order_gmv_usd) as paid_no_click_order_gmv_usd
        ,SUM(no_click_gmv_usd) as no_click_gmv_usd
    from full_oa_regional
    group by 1,2,3,4,5,6,7,8,9,10
) oa
full join 
(
    select * from revenue
    where tz_type='regional'
)revenue
on oa.ads_id <=> revenue.ads_id
and oa.placement <=> revenue.placement
and oa.entrance <=> revenue.entrance
and oa.item_id <=> revenue.item_id
and oa.pricing_type <=> revenue.pricing_type
and oa.campaign_id <=> revenue.campaign_id
and oa.traffic_source <=> revenue.traffic_source
-- one ads can have multi pricing_type and campaign_id 
-- is that it can change anytime, so db will have one, and tracking have 2
;

alter table dws_advertise_performance_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");