-- task_code: data_paidadsmart.studio_4438974  asset_id: 4438974
create external table if not exists dim_shop_info__reg_s0_live
(   shop_id bigint
    ,seller_name string
    ,shop_level1_global_be_category string
    ,shop_level2_global_be_category string
    ,seller_type string
    ,cluster string
    ,is_principal  tinyint
    ,principal_type string
    ,is_cb_seller tinyint
    ,account_create_datetime string
    ,is_official_shop tinyint
    ,is_preferred_shop tinyint
    ,is_managed_seller tinyint
    ,seller_status string
    ,seller_tier string
    ,advertiser_status string
    ,advertiser_tier string
    ,ads_placement_type string
    ,key_seller_90 tinyint
    ,key_seller_95 tinyint
    ,is_cb_sip_affiliated tinyint
    ,is_local_sip_affiliated tinyint
    ,is_sip_primary tinyint
    ,cb_seller_type string
    ,seller_type_1p string
    ,seller_active_ads_placement_type array<string>
    ,seller_revenue_for_tier_usd double
    ,seller_platform_gmv_for_tier_usd double
    ,shop_level1_fe_display_category_id bigint
    ,user_id bigint
)partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${path}'
;
create or replace temporary view shop as
select  shop_id
        ,shop_name   
        ,is_preferred_plus_shop
        ,is_cb_shop  as is_cb_seller
        ,is_official_shop 
        ,is_preferred_shop 
        ,is_managed_shop as is_managed_seller
        ,user_id
from    mp_user.dim_shop__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   
group by 1,2,3,4,5,6,7,8
;

create or replace temporary view  msbenchmark as
select  cast(shop_id as bigint) as shop_id
        ,principal_type
from    regma_general.shop_attributes
where   grass_region = upper('${region}')
group by 1, 2
;

cache table  shop_listing OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  
    shop_id
    , first(shop_level1_global_be_category) as shop_level1_global_be_category
    , first(shop_level2_global_be_category) as shop_level2_global_be_category
    , first(shop_level1_fe_display_category_id) as shop_level1_fe_display_category_id
FROM mp_item.dws_shop_listing_td__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   
group by 1
;

create or replace temporary view dim_advertiser as 
select  shop_id
        ,account_create_datetime 
from    mp_paidads.dim_advertiser__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   
;

create or replace temporary view seller_info as
select  a.shop_id as shop_id
        ,shop_name as seller_name
        ,shop_level1_global_be_category
        ,shop_level2_global_be_category
        ,shop_level1_fe_display_category_id
        ,case   when is_official_shop = 1 THEN 'Official Store'
                when is_cb_seller = 1 THEN 'Cross Border'
                when is_managed_seller = 1 THEN 'Managed Seller'
                when is_preferred_shop = 1 THEN 'Preferred Seller'
                when is_preferred_plus_shop = 1 THEN 'Preferred Plus Seller'
                ELSE 'Others'
         end as seller_type
        ,(case when shop_level1_global_be_category in ('Audio','Cameras & Drones','Computers & Accessories', 'Gaming & Consoles','Home Appliances','Mobile & Gadgets' ) then 'EL'
                  when shop_level1_global_be_category in ('Baby & Kids Fashion', 'Fashion Accessories', 'Men Bags', 
                                                            'Men Clothes', 'Men Shoes', 'Muslim Fashion', 
                                                            'Travel & Luggage', 'Watches', 'Women Bags', 'Women Clothes',
                                                            'Women Shoes') then 'Fashion'
                  when shop_level1_global_be_category in ('Beauty','Food & Beverages','Health','Mom & Baby','Pets') then 'FMCG'
                  when shop_level1_global_be_category in ('Automobiles','Books & Magazines','Hobbies & Collections','Home & Living',
                                                           'Motorcycles', 'Sports & Outdoors','Stationery', 'Tickets, Vouchers & Services' ) then 'Lifestyle'
                  end) as cluster
        ,1 as is_principal  
        ,principal_type
        ,is_cb_seller
        ,account_create_datetime
        ,is_official_shop
        ,is_preferred_shop
        ,is_managed_seller
        ,user_id
from    shop  a
left join dim_advertiser b
on      a.shop_id = b.shop_id
left join msbenchmark c
on      a.shop_id = c.shop_id
left join shop_listing d
on      a.shop_id = d.shop_id
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

create or replace temporary view seller_status as
select 
a.shop_id,
case 
    when coalesce(b.gmv_usd_td,0) = 0 then 'new'
    when (b.gmv_usd_td-coalesce(c.gmv_usd_td,0)) > 0 and (a.gmv_usd_td-b.gmv_usd_td) = 0 then 'churn'
    when (b.gmv_usd_td-coalesce(c.gmv_usd_td,0)) > 0 and (a.gmv_usd_td-b.gmv_usd_td) > 0 then 'existing'
    when c.gmv_usd_td > 0 and (b.gmv_usd_td-coalesce(c.gmv_usd_td,0)) = 0 and (a.gmv_usd_td-b.gmv_usd_td) > 0 then 'reactivated' 
    when (b.gmv_usd_td-coalesce(c.gmv_usd_td,0)) = 0 and (a.gmv_usd_td-b.gmv_usd_td) = 0 then 'churned_before'
    else 'others'
end as seller_status
,case when coalesce(a.gmv_usd_td,0)-coalesce(b.gmv_usd_td,0) >= larger_seller_min_value then 'large_seller'
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
    select shop_id,gmv_usd_td from mp_order.dws_seller_gmv_td__reg_s0_live where grass_date = date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day and grass_region = upper('${region}')
    and tz_type = 'local' and gmv_usd_td > 0
) b 
on a.shop_id = b.shop_id
left join 
(
    select shop_id,gmv_usd_td from mp_order.dws_seller_gmv_td__reg_s0_live where grass_date = date_trunc('month', date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day) - interval '1' day
    and tz_type = 'local' and gmv_usd_td > 0 and grass_region = upper('${region}')
) c
on a.shop_id = c.shop_id
left join seller_tier_threshold d 
on 1=1;

create or replace temporary view advertiser_status as
select 
    a.shop_id as shop_id,
    case when coalesce(a.expenditure_amt_usd_td,0) > 0 and coalesce(b.expenditure_amt_usd_td,0) = 0 then 'new'
        when (coalesce(b.expenditure_amt_usd_td,0)-coalesce(c.expenditure_amt_usd_td,0)) > 0 and (coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0)) = 0 then 'churn'
        when (coalesce(b.expenditure_amt_usd_td,0)-coalesce(c.expenditure_amt_usd_td,0)) > 0 and (coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0)) > 0 then 'existing'
        when coalesce(c.expenditure_amt_usd_td,0) > 0 and (coalesce(b.expenditure_amt_usd_td,0)-coalesce(c.expenditure_amt_usd_td,0)) = 0 and (coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0)) > 0 then 'reactivated' 
        when coalesce(c.expenditure_amt_usd_td,0) > 0 and (coalesce(b.expenditure_amt_usd_td,0)-coalesce(c.expenditure_amt_usd_td,0)) = 0 and (coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0)) = 0 then 'churned_before'
        when coalesce(c.expenditure_amt_usd_td,0) = 0 and coalesce(b.expenditure_amt_usd_td,0) = 0 and coalesce(a.expenditure_amt_usd_td,0) = 0 then 'never_activated'
    else 'others'
    end as advertiser_status
    ,case when coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) >= larger_advertiser_min_value then 'large_advertiser'
        when coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) >= medium_advertiser_min_value and coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) < larger_advertiser_min_value then 'medium_advertiser'
        when coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) >= small_advertiser_min_value and coalesce(a.expenditure_amt_usd_td,0)-coalesce(b.expenditure_amt_usd_td,0) < medium_advertiser_min_value then 'small_advertiser'
        else 'micro_advertiser'
        end as advertiser_tier
from 
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td 
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_date = date_trunc('month', '${grass_date}') - interval '1' day and grass_region = upper('${region}')
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) a 
full join 
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td  
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_date = date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day and grass_region = upper('${region}')
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) b 
on a.shop_id = b.shop_id
left join 
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td  
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_date = date_trunc('month', date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day) - interval '1' day and grass_region = upper('${region}')
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) c
on a.shop_id = c.shop_id
left join advertiser_tier_threshold d 
on 1=1
;

create or replace temporary view seller_ads_placement_type as
select  shop_id
        ,case when search_ads_cnt > 0 and  discovery_ads_cnt > 0 and shop_ads_cnt > 0  and itemboost_ads_cnt > 0 and autoboost_ads_cnt > 0 then 'full_ads'
             when search_ads_cnt > 0 and  discovery_ads_cnt > 0 and shop_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'search_discovery_shop_auto'
             when search_ads_cnt > 0 and  discovery_ads_cnt > 0 and shop_ads_cnt > 0  and itemboost_ads_cnt > 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'search_discovery_shop_item'
             when search_ads_cnt > 0 and  discovery_ads_cnt > 0 and itemboost_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(shop_ads_cnt,0) = 0 then 'search_discovery_item_auto'
             when  search_ads_cnt > 0 and  shop_ads_cnt > 0 and itemboost_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(discovery_ads_cnt,0) = 0 then 'search_shop_item_auto'
             when  discovery_ads_cnt > 0 and  shop_ads_cnt > 0 and itemboost_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 then 'discovery_shop_item_auto'
             when  search_ads_cnt > 0 and  discovery_ads_cnt > 0 and shop_ads_cnt > 0 and ifnull(autoboost_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'search_discovery_shop'
             when  search_ads_cnt > 0 and  discovery_ads_cnt > 0 and itemboost_ads_cnt > 0 and ifnull(autoboost_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 then 'search_discovery_item'
             when  search_ads_cnt > 0 and  discovery_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(shop_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'search_discovery_auto'
             when  search_ads_cnt > 0 and  itemboost_ads_cnt > 0 and shop_ads_cnt > 0 and ifnull(autoboost_ads_cnt,0) = 0 and ifnull(discovery_ads_cnt,0) = 0 then 'search_shop_item'
             when  search_ads_cnt > 0 and  autoboost_ads_cnt > 0 and shop_ads_cnt > 0 and ifnull(itemboost_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 then 'search_shop_auto'
             when  search_ads_cnt > 0 and  autoboost_ads_cnt > 0 and itemboost_ads_cnt > 0 and ifnull(shop_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 then 'search_item_auto'
             when  discovery_ads_cnt > 0 and  shop_ads_cnt > 0 and itemboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'discovery_shop_item'
             when  discovery_ads_cnt > 0 and  shop_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'discovery_shop_auto'
             when  discovery_ads_cnt > 0 and  itemboost_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 then 'discovery_item_auto'
             when  shop_ads_cnt > 0 and  itemboost_ads_cnt > 0 and autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 then 'shop_item_auto'
             when  search_ads_cnt > 0 and  discovery_ads_cnt > 0 and ifnull(shop_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'search_discovery'
             when  search_ads_cnt > 0 and  shop_ads_cnt > 0 and ifnull(discovery_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'search_shop'
             when  search_ads_cnt > 0 and  itemboost_ads_cnt > 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 then 'search_item'
             when  search_ads_cnt > 0 and  autoboost_ads_cnt > 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 then 'search_auto'
             when  discovery_ads_cnt > 0 and  shop_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'discovery_shop'
             when  discovery_ads_cnt > 0 and  itemboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'discovery_item'
             when  discovery_ads_cnt > 0 and  autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'discovery_auto'
             when  shop_ads_cnt > 0 and  itemboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'shop_item'
             when  shop_ads_cnt > 0 and  autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'shop_auto'
             when  itemboost_ads_cnt > 0 and  autoboost_ads_cnt > 0 and ifnull(search_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(shop_ads_cnt,0) = 0 then 'item_auto'
             when  search_ads_cnt > 0 and (ifnull(discovery_ads_cnt,0) = 0) and ifnull(shop_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'search_only'
             when  discovery_ads_cnt > 0 and (ifnull(search_ads_cnt,0) = 0) and ifnull(shop_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'discovery_only'
             when  shop_ads_cnt > 0 and (ifnull(search_ads_cnt,0) = 0) and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'shop_only'
             when  itemboost_ads_cnt > 0 and (ifnull(search_ads_cnt,0) = 0) and ifnull(shop_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(autoboost_ads_cnt,0) = 0 then 'item_only'
             when  autoboost_ads_cnt > 0 and (ifnull(search_ads_cnt,0) = 0) and ifnull(shop_ads_cnt,0) = 0 and  ifnull(discovery_ads_cnt,0) = 0 and ifnull(itemboost_ads_cnt,0) = 0 then 'auto_only'
             else 'no_related_ads'
             end as ads_placement_type
        ,seller_active_ads_placement_type
        ,seller_revenue_for_tier_usd
from
(select shop_id
    ,count(distinct case when placement in (0,4) then ads_id end) as search_ads_cnt
    ,count(distinct case when placement = 0 then ads_id end) as search_manual_ads_cnt
    ,count(distinct case when placement = 4 then ads_id end) as search_simple_ads_cnt
    ,count(distinct case when placement in (2,5,802,805) then ads_id end) as discovery_ads_cnt
    ,count(distinct case when placement = 2 then ads_id end) as dd_manual_ads_cnt
    ,count(distinct case when placement in (802) then ads_id end) as dd_simple_ads_cnt
    ,count(distinct case when placement = 5 then ads_id end) as ymal_manual_ads_cnt
    ,count(distinct case when placement in (805) then ads_id end) as ymal_simple_ads_cnt
    ,sum(case when placement = 3 then 1 end) as shop_ads_cnt
    ,count(distinct case when placement in (1000,1002,1005) then ads_id end) as itemboost_ads_cnt
    ,count(distinct case when placement in (1200,1202,1205) then ads_id end) as autoboost_ads_cnt
    ,COLLECT_SET(case when has_performance > 0 and (is_ads_active = 1 or campaign_status = 1) then product_type else null end) as seller_active_ads_placement_type
    ,sum(ads_expenditure_amt_usd) as seller_revenue_for_tier_usd
from 
    mp_paidads.ads_advertise_mkt_1d__reg_s0_live
where 
    grass_region = upper('${region}')
    and grass_date = '${grass_date}'
    and tz_type = 'local'
group by shop_id
)a;

create or replace temporary view platform_order as
select 
    a.shop_id as shop_id
    ,case when PERCENT_RANK() over (partition by shop_level1_global_be_category order by platform_gmv_usd asc) >= 0.9 then 1 else 0 end as key_seller_90
    ,case when PERCENT_RANK() over (partition by shop_level1_global_be_category order by platform_gmv_usd asc) >= 0.95 then 1 else 0 end as key_seller_95
    ,platform_gmv_usd as seller_platform_gmv_for_tier_usd
from
(select 
    shop_id
    ,sum(gmv_usd_1d) as platform_gmv_usd
from mp_order.dws_seller_gmv_1d__reg_s0_live
where grass_region = upper('${region}')
    and   grass_date = '${grass_date}'
    and tz_type = 'local'
group by shop_id
)a
left join shop_listing b
on a.shop_id = b.shop_id
;

create or replace temporary view shop_ext as
select shop_id
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,is_sip_primary
from mp_seller.dim_shop_ext__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   
group by 1,2,3,4
;

CREATE OR REPLACE TEMPORARY VIEW seller_1p AS
select 
    COALESCE(a.shop_id, b.shop_id, c.shop_id) as shop_id
    ,b.seller_type as cb_seller_type
    ,case
        when a.seller_name = 'Lovito - GGP' then 'Lovito'
        when a.seller_name = 'Flock project - GGP' then 'SCS'
        when c.local_scs = 1 then 'Local SCS'
        when b.seller_type = 'CNCB' then 'Others'
        else 'Unknown'
    end as seller_type_1p
from 
    (    
    select
        shop_id
        ,seller_name
    FROM mp_cb.dim_shop__reg_live
    WHERE tz_type = 'local'
    and grass_region = upper('${region}')
    AND grass_date = '${grass_date}'
    )a
    full join (
    select
        shop_id
        ,seller_type
    from mp_cb.dim_shop_ext__reg_live
    WHERE tz_type = 'local'
    and grass_region = upper('${region}')
    AND grass_date = '${grass_date}'
    )b 
    on a.shop_id = b.shop_id
    left join
    (
        select 
            shop_id 
            ,1 as local_scs
        from mp_paidads.dim_local_scs_shop_list
    )c 
    on a.shop_id = c.shop_id
;

insert overwrite table dim_shop_info__reg_s0_live partition (tz_type = 'local',grass_region,grass_date)
select 
    a.shop_id shop_id
    ,seller_name
    ,shop_level1_global_be_category
    ,shop_level2_global_be_category
    ,seller_type
    ,cluster
    ,is_principal  
    ,case when is_cb_seller = 1 AND principal_type IS NULL THEN 'Cross Border'
                    ELSE COALESCE(principal_type, 'Local Brand')
             end as principal_type
    ,is_cb_seller
    ,account_create_datetime
    ,is_official_shop
    ,is_preferred_shop
    ,is_managed_seller
    ,coalesce(seller_status, 'churned_before')
    ,coalesce(seller_tier, 'micro_seller')
    ,coalesce(advertiser_status, 'never_activated') 
    ,coalesce(advertiser_tier, 'micro_advertiser')
    ,coalesce(ads_placement_type, 'no_related_ads')
    ,coalesce(key_seller_90,0)
    ,coalesce(key_seller_95,0)
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,is_sip_primary
    ,cb_seller_type
    ,coalesce(seller_type_1p,'Unknown') as  seller_type_1p
    ,seller_active_ads_placement_type
    ,seller_revenue_for_tier_usd
    ,seller_platform_gmv_for_tier_usd
    ,coalesce(shop_level1_fe_display_category_id, 0) as shop_level1_fe_display_category_id
    ,user_id
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
from seller_info a 
left join seller_status b 
on a.shop_id = b.shop_id 
left join advertiser_status c
on a.shop_id = c.shop_id
left join seller_ads_placement_type d 
on a.shop_id = d.shop_id
left join platform_order e 
on a.shop_id = e.shop_id
left join shop_ext f 
on a.shop_id = f.shop_id
left join seller_1p g 
on a.shop_id = g.shop_id;

create or replace view dim_shop_info__${region}_s0_live as 
select *
from mp_paidads.dim_shop_info__reg_s0_live
where grass_region = upper('${region}')
;