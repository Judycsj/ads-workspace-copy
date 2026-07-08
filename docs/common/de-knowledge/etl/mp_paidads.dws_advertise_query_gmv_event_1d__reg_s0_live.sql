-- task_code: data_paidadsmart.studio_2518275  asset_id: 2518275
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


create or replace temporary view dim_product_campaign as
select * from
(SELECT
    campaign_id
    ,shop_id
    ,product_placement
    ,row_number() over(partition by campaign_id,shop_id order by campaign_modify_datetime) as rank  
from mp_paidads.dim_product_campaign__reg_s0_live
WHERE grass_region = upper('${region}')
AND grass_date = date('${grass_date}') 
)where rank = 1
;

create or replace temporary view  oa as
SELECT
    tz_type
    ,oa.ads_id
    ,oa.grass_region
    ,oa.placement
    ,oa.item_id
    ,keywords as keyword
    ,oa.shop_id
    ,query
    ,dim.pricing_type
    ,paid_order_cnt
    ,confirmed_order_cnt
    ,paid_datetime
    ,confirmed_datetime
    ,CASE
       WHEN oa.placement in (0,3,4,1000,1200) THEN COALESCE(oa.match_type, 0)
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
FROM mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live oa
LEFT OUTER JOIN dim
ON (oa.ads_id = dim.ads_id
    AND oa.placement = dim.placement
    AND COALESCE(oa.item_id, 0) = dim.item_id
    AND oa.shop_id = dim.shop_id
    AND oa.grass_region = dim.grass_region
)
WHERE oa.grass_date >= date('${grass_date}')  - interval '1' day
and oa.grass_date <= date('${grass_date}')
AND (paid_datetime is not NULL OR confirmed_datetime is not NULL)
;

create or replace temporary view base as
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
    ,new_boost
    ,SUM(location_in_ads) AS location_in_ads
    ,SUM(impression_cnt) AS impression_cnt
    ,SUM(click_cnt) AS click_cnt
    ,SUM(click_before_deduction_cnt) AS click_before_deduction_cnt
    ,SUM(expenditure_amt_local) AS expenditure_amt_local
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
from    (
    SELECT
    base_local.ads_id
    ,campaign_id
    ,broad_gmv_amt_local
    ,broad_item_cnt
    ,broad_order_cnt
    ,broad_shop_item_click_cnt
    ,broad_shop_item_impression_cnt
    ,case when base_local.placement in (3327, 3328, 3337, 3338, 3339) then raw_click_cnt else click_cnt end as click_cnt
    ,expenditure_amt_local
    ,daily_order_cnt
    ,impression_cnt
    ,COALESCE(base_local.item_id, 0) AS item_id
    ,keyword
    ,location_in_ads
    ,dim.pricing_type
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
    ,base_local.shop_id
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
    ,view
    ,product_click
    ,new_boost
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
FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live base_local
LEFT OUTER JOIN dim
ON (base_local.ads_id = dim.ads_id
    AND base_local.placement = dim.placement
    AND COALESCE(base_local.item_id, 0) = dim.item_id
    AND base_local.shop_id = dim.shop_id
    AND base_local.grass_region = dim.grass_region
)
WHERE base_local.grass_region = upper('${region}')
AND base_local.grass_date = date('${grass_date}')
) t1
where   grass_region = upper('${region}')
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
;

set time zone 'Asia/Singapore'
;

create or replace temporary view  base_reg as
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
    ,new_boost
    ,SUM(location_in_ads) AS location_in_ads
    ,SUM(impression_cnt) AS impression_cnt
    ,SUM(click_cnt) AS click_cnt
    ,SUM(click_before_deduction_cnt) AS click_before_deduction_cnt
    ,SUM(expenditure_amt_local) AS expenditure_amt_local
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
from    (
    SELECT
    base_regional.ads_id
    ,campaign_id
    ,broad_gmv_amt_local
    ,broad_item_cnt
    ,broad_order_cnt
    ,broad_shop_item_click_cnt
    ,broad_shop_item_impression_cnt
    ,case when base_regional.placement in (3327, 3328, 3337, 3338, 3339) then raw_click_cnt else click_cnt end as click_cnt
    ,expenditure_amt_local
    ,daily_order_cnt
    ,impression_cnt
    ,COALESCE(base_regional.item_id, 0) AS item_id
    ,keyword
    ,dim.pricing_type
    ,location_in_ads
    ,CASE
       WHEN base_regional.placement in (0,3,4) THEN COALESCE(match_type, 0)
       ELSE 0
    END AS match_type
    ,order_cnt
    ,checkout_cnt
    ,ads_item_sold_cnt
    ,ads_order_gmv_local
    ,base_regional.placement
    ,query
    ,click_before_deduction_cnt
    ,base_regional.shop_id
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
    ,view
    ,product_click
    ,new_boost
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
FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live base_regional
LEFT OUTER JOIN dim
ON (base_regional.ads_id = dim.ads_id
    AND base_regional.placement = dim.placement
    AND COALESCE(base_regional.item_id, 0) = dim.item_id
    AND base_regional.shop_id = dim.shop_id
    AND base_regional.grass_region = dim.grass_region
)
WHERE base_regional.grass_region = upper('${region}')
AND base_regional.grass_date BETWEEN DATE_SUB(DATE('${grass_date}'), 1) AND DATE('${grass_date}')
AND   coalesce(timestamp, event_timestamp) >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
AND   coalesce(timestamp,event_timestamp) < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
) t2
where   grass_region = upper('${region}')
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
;

insert overwrite table dws_advertise_query_gmv_event_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
SELECT
    -- /*+MAPJOIN(oa1,oa2)*/
    base.ads_id AS ads_id
    ,base.placement AS placement
    ,dim.ads_type AS ads_type
    ,base.keyword AS keywords
    ,COALESCE(base.match_type, 0) AS match_type
    ,base.item_id AS item_id
    ,dim.item_name AS item_name
    ,base.shop_id AS shop_id
    ,dim.seller_id AS seller_id
    ,dim.seller_name AS seller_name
    ,base.query AS query
    ,base.pricing_type AS pricing_type
    ,base.impression_cnt AS impression_cnt
    ,base.click_cnt AS click_cnt
    ,base.order_cnt AS order_cnt
    ,base.checkout_cnt AS checkout_cnt
    ,base.ads_item_sold_cnt AS ads_items_sold_cnt
    ,base.ads_order_gmv_local AS ads_gmv_amt_local
    ,(base.ads_order_gmv_local / ex.exchange_rate) AS ads_gmv_amt_usd
    ,base.expenditure_amt_local
    ,(base.expenditure_amt_local / ex.exchange_rate) AS expenditure_amt_usd
    ,(location_in_ads / impression_cnt + 1) AS avg_ads_ranks
    ,base.broad_shop_item_click_cnt AS broad_shopitem_click_cnt
    ,base.broad_shop_item_impression_cnt AS broad_shopitem_impression_cnt
    ,base.broad_item_cnt AS broad_order_item_cnt
    ,base.broad_gmv_amt_local AS broad_order_gmv_amt_local
    ,(base.broad_gmv_amt_local / ex.exchange_rate) AS broad_order_gmv_amt_usd
    ,base.broad_order_cnt AS broad_order_cnt
    ,base.shop_item_impression_cnt AS shopitem_impression_cnt
    ,base.shop_item_click_cnt AS shopitem_click_cnt
    ,base.click_before_deduction_cnt AS click_before_deduction_cnt
    ,base.daily_order_cnt AS daily_order_cnt
    ,paid_order_cnt
    ,paid_order_cnt_ytd
    ,confirmed_order_cnt
    ,confirmed_order_cnt_ytd
    ,base.matched_premium_segment_value
    ,filter_segments_age_start
    ,filter_segments_age_end
    ,filter_segments_gender_list
    ,filter_segments_location_list
    ,premium_segments_behavior_list
    ,filter_segments_category_list
    ,base.entrance as entrance
    ,base.add_to_cart_cnt as add_to_cart_cnt
    ,base.add_to_cart_without_clicks_cnt as add_to_cart_without_clicks_cnt
    ,base.broad_add_to_cart_cnt as broad_add_to_cart_cnt
    ,base.`location` as `location`
    ,product_placement
    ,view_cnt
    ,product_click_cnt
    ,base.new_boost
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
    ,base.grass_region AS grass_region
    ,DATE('${grass_date}') AS grass_date
FROM base
LEFT OUTER JOIN dim
ON (base.ads_id = dim.ads_id
    AND base.placement = dim.placement
    AND base.item_id = dim.item_id
    AND base.shop_id = dim.shop_id
    AND base.grass_region = dim.grass_region
    AND base.pricing_type <=> dim.pricing_type
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
ON (base.ads_id = oa1.ads_id
    AND base.grass_region = oa1.grass_region
    AND base.placement = oa1.placement
    AND COALESCE(base.item_id,0) = COALESCE(oa1.item_id,0)
    AND COALESCE(base.keyword,'') = COALESCE(oa1.keyword,'')
    AND base.shop_id = oa1.shop_id
    AND COALESCE(base.query,'') = COALESCE(oa1.query,'')
    AND base.match_type = oa1.match_type
    AND COALESCE(base.matched_premium_segment_value,'') = COALESCE(oa1.matched_premium_segment_value,'')
    AND COALESCE(base.entrance, 0) = COALESCE(oa1.entrance, 0)
    AND base.pricing_type <=> oa1.pricing_type
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
ON (base.ads_id = oa2.ads_id
    AND base.grass_region = oa2.grass_region
    AND base.placement = oa2.placement
    AND COALESCE(base.item_id,0) = COALESCE(oa2.item_id,0)
    AND COALESCE(base.keyword,'') = COALESCE(oa2.keyword,'')
    AND base.shop_id = oa2.shop_id
    AND COALESCE(base.query,'') = COALESCE(oa2.query,'')
    AND base.match_type = oa2.match_type
    AND COALESCE(base.matched_premium_segment_value,'') = COALESCE(oa2.matched_premium_segment_value,'')
    AND COALESCE(base.entrance, 0) = COALESCE(oa2.entrance, 0)
    AND base.pricing_type <=> oa2.pricing_type
)
left join dim_product_campaign 
on base.shop_id = dim_product_campaign.shop_id
and base.campaign_id = dim_product_campaign.campaign_id
LEFT OUTER JOIN 
(
  select grass_region,exchange_rate
  from mp_order.dim_exchange_rate__reg_s0_live
  where grass_date = date('${grass_date}')
  and grass_region = upper('${region}')
) ex
ON base.grass_region = ex.grass_region;
;
;

insert overwrite table dws_advertise_query_gmv_event_1d__reg_s0_live partition (tz_type = 'regional', grass_region, grass_date)
select   base_reg.ads_id as ads_id
        ,base_reg.placement as placement
        ,dim.ads_type as ads_type
        ,base_reg.keyword as keywords
        ,COALESCE(base_reg.match_type, 0) as match_type
        ,base_reg.item_id as item_id
        ,dim.item_name as item_name
        ,base_reg.shop_id as shop_id
        ,dim.seller_id as seller_id
        ,dim.seller_name as seller_name
        ,base_reg.query as query
        ,base_reg.pricing_type as pricing_type
        ,base_reg.impression_cnt as impression_cnt
        ,base_reg.click_cnt as click_cnt
        ,base_reg.order_cnt as order_cnt
        ,base_reg.checkout_cnt as checkout_cnt
        ,base_reg.ads_item_sold_cnt as ads_items_sold_cnt
        ,base_reg.ads_order_gmv_local as ads_gmv_amt_local
        ,(base_reg.ads_order_gmv_local / ex.exchange_rate) as ads_gmv_amt_usd
        ,base_reg.expenditure_amt_local
        ,(base_reg.expenditure_amt_local / ex.exchange_rate) as expenditure_amt_usd
        ,(location_in_ads / impression_cnt + 1) as avg_ads_ranks
        ,base_reg.broad_shop_item_click_cnt as broad_shopitem_click_cnt
        ,base_reg.broad_shop_item_impression_cnt as broad_shopitem_impression_cnt
        ,base_reg.broad_item_cnt as broad_order_item_cnt
        ,base_reg.broad_gmv_amt_local as broad_order_gmv_amt_local
        ,(base_reg.broad_gmv_amt_local / ex.exchange_rate) as broad_order_gmv_amt_usd
        ,base_reg.broad_order_cnt as broad_order_cnt
        ,base_reg.shop_item_impression_cnt as shopitem_impression_cnt
        ,base_reg.shop_item_click_cnt as shopitem_click_cnt
        ,base_reg.click_before_deduction_cnt as click_before_deduction_cnt
        ,base_reg.daily_order_cnt as daily_order_cnt
        ,null as paid_order_cnt
        ,null as paid_order_cnt_ytd
        ,null as confirmed_order_cnt
        ,null as confirmed_order_cnt_ytd
        ,matched_premium_segment_value
        ,filter_segments_age_start
        ,filter_segments_age_end
        ,filter_segments_gender_list
        ,filter_segments_location_list
        ,premium_segments_behavior_list
        ,filter_segments_category_list
        ,entrance
        ,base_reg.add_to_cart_cnt as add_to_cart_cnt
        ,base_reg.add_to_cart_without_clicks_cnt as add_to_cart_without_clicks_cnt
        ,base_reg.broad_add_to_cart_cnt as broad_add_to_cart_cnt
        ,base_reg.`location` as `location`
        ,product_placement
        ,view_cnt
        ,product_click_cnt
        ,base_reg.new_boost
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
        ,base_reg.grass_region AS grass_region
        ,DATE('${grass_date}') as grass_date
from    base_reg
left outer join dim
on      (
        base_reg.ads_id = dim.ads_id
    and base_reg.placement = dim.placement
    and base_reg.item_id = dim.item_id
    and base_reg.shop_id = dim.shop_id
    and base_reg.grass_region = dim.grass_region
    and base_reg.pricing_type <=> dim.pricing_type
)
left join dim_product_campaign 
on base_reg.shop_id = dim_product_campaign.shop_id
and base_reg.campaign_id = dim_product_campaign.campaign_id
LEFT OUTER JOIN 
(
  select grass_region,exchange_rate
  from mp_order.dim_exchange_rate__reg_s0_live
  where grass_date = date('${grass_date}')
  and grass_region = upper('${region}')
) ex
ON base_reg.grass_region = ex.grass_region;
;

alter table dws_advertise_query_gmv_event_1d__${region}_s0_live add if not exists partition(grass_date = "${grass_date}")
;