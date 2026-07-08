create external table if not exists dim_shop_info_monthly__reg_s0_live
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
from    mp_user.dim_shop__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'
;

create or replace temporary view  msbenchmark as
select  cast(shop_id as bigint) as shop_id
        ,principal_type
from    regma_general.shop_attributes
where   grass_region = upper('${region}')
group by 1, 2
;


create or replace temporary view dim_advertiser as
select  shop_id
        ,shop_level1_global_be_category
        ,shop_level2_global_be_category
        ,(case when shop_level1_global_be_category in ('Audio','Cameras & Drones','Computers & Accessories', 'Gaming & Consoles','Home Appliances','Mobile & Gadgets' ) then 'EL'
                  when shop_level1_global_be_category in ('Baby & Kids Fashion', 'Fashion Accessories', 'Men Bags',
                                                            'Men Clothes', 'Men Shoes', 'Muslim Fashion',
                                                            'Travel & Luggage', 'Watches', 'Women Bags', 'Women Clothes',
                                                            'Women Shoes') then 'Fashion'
                  when shop_level1_global_be_category in ('Beauty','Food & Beverages','Health','Mom & Baby','Pets') then 'FMCG'
                  when shop_level1_global_be_category in ('Automobiles','Books & Magazines','Hobbies & Collections','Home & Living',
                                                           'Motorcycles', 'Sports & Outdoors','Stationery', 'Tickets, Vouchers & Services' ) then 'Lifestyle'
                  end) as cluster
        ,account_create_datetime
        ,is_cb_seller
        ,is_official_shop
        ,is_preferred_shop
        ,is_managed_seller
from    mp_paidads.dim_advertiser__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = '${grass_date}'
  and tz_type = 'local'   ;

create or replace temporary view seller_info as
select  a.shop_id as shop_id
        ,shop_name as seller_name
        ,shop_level1_global_be_category
        ,shop_level2_global_be_category
        ,case   when is_official_shop = 1 THEN 'Official Store'
                when is_cb_seller = 1 THEN 'Cross Border'
                when is_managed_seller = 1 THEN 'Managed Seller'
                when is_preferred_shop = 1 THEN 'Preferred Seller'
                when is_preferred_plus_shop = 1 THEN 'Preferred Plus Seller'
                ELSE 'Others'
         end as seller_type
        ,cluster
        ,1 as is_principal
        ,principal_type
        ,is_cb_seller
        ,account_create_datetime
        ,is_official_shop
        ,is_preferred_shop
        ,is_managed_seller
from   shop  a
left join dim_advertiser b
on      a.shop_id = b.shop_id
left join msbenchmark c
on      a.shop_id = c.shop_id
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
        and   grass_date = '${grass_date}'
    and tz_type = 'local' and gmv_usd_td > 0
) a
full join
(
    select shop_id,gmv_usd_td from mp_order.dws_seller_gmv_td__reg_s0_live where grass_region = upper('${region}') and grass_date = date_trunc('month', '${grass_date}') - interval '1' day
    and tz_type = 'local' and gmv_usd_td > 0
) b
on a.shop_id = b.shop_id
left join
(
    select shop_id,gmv_usd_td from mp_order.dws_seller_gmv_td__reg_s0_live where grass_region = upper('${region}') and grass_date = date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day
    and tz_type = 'local' and gmv_usd_td > 0
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
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_region = upper('${region}') and grass_date = '${grass_date}'
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) a
full join
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_region = upper('${region}') and grass_date = date_trunc('month', '${grass_date}') - interval '1' day
    group by 1
    -- and td_ads_expenditure_amt_usd > 0
) b
on a.shop_id = b.shop_id
left join
(
    select shop_id,sum(expenditure_amt_usd_td) as expenditure_amt_usd_td
    from mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live where grass_region = upper('${region}') and grass_date = date_trunc('month', date_trunc('month', '${grass_date}') - interval '1' day) - interval '1' day
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
from
    mp_paidads.dim_advertise__reg_s0_live
where
    grass_region = upper('${region}')
    and grass_date >= date(date_trunc('month', '${grass_date}'))
    and grass_date <= '${grass_date}'
    and tz_type = 'local'
group by shop_id
)a;

create or replace temporary view platform_order as
select
    a.shop_id as shop_id
    ,case when PERCENT_RANK() over (partition by shop_level1_global_be_category order by platform_gmv_usd asc) >= 0.9 then 1 else 0 end as key_seller_90
    ,case when PERCENT_RANK() over (partition by shop_level1_global_be_category order by platform_gmv_usd asc) >= 0.95 then 1 else 0 end as key_seller_95
from
(select
    shop_id
    ,sum(gmv_usd_1d) as platform_gmv_usd
from mp_order.dws_item_gmv_1d__reg_s0_live
where grass_region = upper('${region}')
    and grass_date >= date(date_trunc('month', '${grass_date}'))
    and   grass_date <= '${grass_date}'
    and tz_type = 'local'
group by shop_id
)a
left join dim_advertiser b
on a.shop_id = b.shop_id
;

create or replace temporary view adoption_tag as
select
    shop_id
    ,campaign_valid_budget_usd
    ,campaign_valid_budget_usd_last_1m
    ,campaign_valid_budget_usd_last_2m
    ,target2_campaign_valid_budget_usd
    ,target2_campaign_valid_budget_usd_last_1m
    ,target2_campaign_valid_budget_usd_last_2m
    ,simple2_campaign_valid_budget_usd
    ,simple2_campaign_valid_budget_usd_last_1m
    ,simple2_campaign_valid_budget_usd_last_2m
    ,auto_campaign_valid_budget_usd
    ,auto_campaign_valid_budget_usd_last_1m
    ,auto_campaign_valid_budget_usd_last_2m
    ,manual_campaign_valid_budget_usd
    ,manual_campaign_valid_budget_usd_last_1m
    ,manual_campaign_valid_budget_usd_last_2m
    ,case when (campaign_valid_budget_usd / campaign_valid_budget_usd_last_1m) - 1 <= -0.7 then 'churn'
        when (campaign_valid_budget_usd / campaign_valid_budget_usd_last_1m) - 1 > -0.7 and (campaign_valid_budget_usd / campaign_valid_budget_usd_last_1m) - 1 < 0 then 'drop'
        when (campaign_valid_budget_usd / campaign_valid_budget_usd_last_1m) - 1 >= 0 then 'uplift' end as seller_adoption_tag_m1
    ,case when (campaign_valid_budget_usd / campaign_valid_budget_usd_last_2m) - 1 <= -0.7 then 'churn'
        when (campaign_valid_budget_usd / campaign_valid_budget_usd_last_2m) - 1 > -0.7 and (campaign_valid_budget_usd / campaign_valid_budget_usd_last_2m) - 1 < 0 then 'drop'
        when (campaign_valid_budget_usd / campaign_valid_budget_usd_last_2m) - 1 >= 0 then 'uplift' end as seller_adoption_tag_m2

    ,case when (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_1m) - 1 <= -0.7 then 'churn'
        when (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_1m) - 1 > -0.7 and (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_1m) - 1 < 0 then 'drop'
        when (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_1m) - 1 >= 0 then 'uplift' end as seller_target2_adoption_tag_m1
    ,case when (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_2m) - 1 <= -0.7 then 'churn'
        when (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_2m) - 1 > -0.7 and (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_2m) - 1 < 0 then 'drop'
        when (target2_campaign_valid_budget_usd / target2_campaign_valid_budget_usd_last_2m) - 1 >= 0 then 'uplift' end as seller_target2_adoption_tag_m2

    ,case when (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_1m) - 1 <= -0.7 then 'churn'
        when (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_1m) - 1 > -0.7 and (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_1m) - 1 < 0 then 'drop'
        when (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_1m) - 1 >= 0 then 'uplift' end as seller_simple2_adoption_tag_m1
    ,case when (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_2m) - 1 <= -0.7 then 'churn'
        when (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_2m) - 1 > -0.7 and (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_2m) - 1 < 0 then 'drop'
        when (simple2_campaign_valid_budget_usd / simple2_campaign_valid_budget_usd_last_2m) - 1 >= 0 then 'uplift' end as seller_simple2_adoption_tag_m2

    ,case when (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_1m) - 1 <= -0.7 then 'churn'
        when (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_1m) - 1 > -0.7 and (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_1m) - 1 < 0 then 'drop'
        when (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_1m) - 1 >= 0 then 'uplift' end as seller_auto_adoption_tag_m1
    ,case when (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_2m) - 1 <= -0.7 then 'churn'
        when (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_2m) - 1 > -0.7 and (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_2m) - 1 < 0 then 'drop'
        when (auto_campaign_valid_budget_usd / auto_campaign_valid_budget_usd_last_2m) - 1 >= 0 then 'uplift' end as seller_auto_adoption_tag_m2

    ,case when (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_1m) - 1 <= -0.7 then 'churn'
        when (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_1m) - 1 > -0.7 and (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_1m) - 1 < 0 then 'drop'
        when (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_1m) - 1 >= 0 then 'uplift' end as seller_manual_adoption_tag_m1
    ,case when (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_2m) - 1 <= -0.7 then 'churn'
        when (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_2m) - 1 > -0.7 and (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_2m) - 1 < 0 then 'drop'
        when (manual_campaign_valid_budget_usd / manual_campaign_valid_budget_usd_last_2m) - 1 >= 0 then 'uplift' end as seller_manual_adoption_tag_m2
from
(select
    shop_id
    ,COALESCE(avg(case when grass_date >= date_trunc('month', '${grass_date}') and grass_date <= date'${grass_date}' then campaign_valid_budget_usd else null end),0) as campaign_valid_budget_usd
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '1' month) and grass_date < date_trunc('month', '${grass_date}') then campaign_valid_budget_usd else null end),0) as campaign_valid_budget_usd_last_1m
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '2' month) and grass_date < date(date_trunc('month', '${grass_date}') - interval '1' month) then campaign_valid_budget_usd else null end),0) as campaign_valid_budget_usd_last_2m

    ,COALESCE(avg(case when grass_date >= date_trunc('month', '${grass_date}') and grass_date <= date'${grass_date}' and target2_campaign_valid_budget_usd > 0 then target2_campaign_valid_budget_usd else null end),0) as target2_campaign_valid_budget_usd
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '1' month) and grass_date < date_trunc('month', '${grass_date}') and target2_campaign_valid_budget_usd > 0 then target2_campaign_valid_budget_usd else null end),0) as target2_campaign_valid_budget_usd_last_1m
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '2' month) and grass_date < date(date_trunc('month', '${grass_date}') - interval '1' month) and target2_campaign_valid_budget_usd > 0 then target2_campaign_valid_budget_usd else null end),0) as target2_campaign_valid_budget_usd_last_2m

    ,COALESCE(avg(case when grass_date >= date_trunc('month', '${grass_date}') and grass_date <= date'${grass_date}' and simple2_campaign_valid_budget_usd > 0 then simple2_campaign_valid_budget_usd else null end),0) as simple2_campaign_valid_budget_usd
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '1' month) and grass_date < date_trunc('month', '${grass_date}') and simple2_campaign_valid_budget_usd > 0 then simple2_campaign_valid_budget_usd else null end),0) as simple2_campaign_valid_budget_usd_last_1m
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '2' month) and grass_date < date(date_trunc('month', '${grass_date}') - interval '1' month) and simple2_campaign_valid_budget_usd > 0 then simple2_campaign_valid_budget_usd else null end),0) as simple2_campaign_valid_budget_usd_last_2m

    ,COALESCE(avg(case when grass_date >= date_trunc('month', '${grass_date}') and grass_date <= date'${grass_date}' and auto_campaign_valid_budget_usd > 0 then auto_campaign_valid_budget_usd else null end),0) as auto_campaign_valid_budget_usd
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '1' month) and grass_date < date_trunc('month', '${grass_date}')  and auto_campaign_valid_budget_usd > 0 then auto_campaign_valid_budget_usd else null end),0) as auto_campaign_valid_budget_usd_last_1m
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '2' month) and grass_date < date(date_trunc('month', '${grass_date}') - interval '1' month)  and auto_campaign_valid_budget_usd > 0 then auto_campaign_valid_budget_usd else null end),0) as auto_campaign_valid_budget_usd_last_2m

    ,COALESCE(avg(case when grass_date >= date_trunc('month', '${grass_date}') and grass_date <= date'${grass_date}' and manual_campaign_valid_budget_usd > 0 then manual_campaign_valid_budget_usd else null end),0) as manual_campaign_valid_budget_usd
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '1' month) and grass_date < date_trunc('month', '${grass_date}')  and manual_campaign_valid_budget_usd > 0 then manual_campaign_valid_budget_usd else null end),0) as manual_campaign_valid_budget_usd_last_1m
    ,COALESCE(avg(case when grass_date >= date(date_trunc('month', '${grass_date}') - interval '2' month) and grass_date < date(date_trunc('month', '${grass_date}') - interval '1' month)  and manual_campaign_valid_budget_usd > 0 then manual_campaign_valid_budget_usd else null end),0) as manual_campaign_valid_budget_usd_last_2m

from
(select
    shop_id
    ,grass_date
    ,sum(campaign_valid_budget_usd) as campaign_valid_budget_usd
    ,sum(case when main_product_type = 'Product Ads' and sub_product_type = 'roi2.0' then campaign_valid_budget_usd else 0 end) as target2_campaign_valid_budget_usd
    ,sum(case when main_product_type = 'Product Ads' and sub_product_type = 'roi2.0 simple' then campaign_valid_budget_usd else 0 end) as simple2_campaign_valid_budget_usd
    ,sum(case when main_product_type = 'Product Ads' and product_type in ('Item Boost', 'Simple Mode', 'Auto Boost') then campaign_valid_budget_usd else 0 end) as auto_campaign_valid_budget_usd
    ,sum(case when main_product_type = 'Product Ads' and product_type = 'Manual Mode' then campaign_valid_budget_usd else 0 end) as manual_campaign_valid_budget_usd
from mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live
where tz_type = 'local'
and grass_region = upper('${region}')
and grass_date >= date(date_trunc('month', '${grass_date}') - interval '2' month)
    and   grass_date <= date'${grass_date}'
group by 1,2
)a
where campaign_valid_budget_usd > 0
group by 1
)t
;

insert overwrite table dim_shop_info_monthly__reg_s0_live partition (tz_type = 'local',grass_region,grass_date)
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
    ,COALESCE(seller_adoption_tag_m1,'uplift')
    ,COALESCE(seller_adoption_tag_m2,'uplift')
    ,COALESCE(seller_target2_adoption_tag_m1,'uplift')
    ,COALESCE(seller_target2_adoption_tag_m2,'uplift')
    ,COALESCE(seller_simple2_adoption_tag_m1,'uplift')
    ,COALESCE(seller_simple2_adoption_tag_m2,'uplift')
    ,COALESCE(seller_auto_adoption_tag_m1,'uplift')
    ,COALESCE(seller_auto_adoption_tag_m2,'uplift')
    ,COALESCE(seller_manual_adoption_tag_m1,'uplift')
    ,COALESCE(seller_manual_adoption_tag_m2,'uplift')
    ,campaign_valid_budget_usd_last_1m
    ,campaign_valid_budget_usd_last_2m
    ,target2_campaign_valid_budget_usd
    ,target2_campaign_valid_budget_usd_last_1m
    ,target2_campaign_valid_budget_usd_last_2m
    ,simple2_campaign_valid_budget_usd
    ,simple2_campaign_valid_budget_usd_last_1m
    ,simple2_campaign_valid_budget_usd_last_2m
    ,auto_campaign_valid_budget_usd
    ,auto_campaign_valid_budget_usd_last_1m
    ,auto_campaign_valid_budget_usd_last_2m
    ,manual_campaign_valid_budget_usd
    ,manual_campaign_valid_budget_usd_last_1m
    ,manual_campaign_valid_budget_usd_last_2m
    ,campaign_valid_budget_usd
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
left join adoption_tag f
on a.shop_id = f.shop_id;
