-- task_code: data_paidadsmart.studio_5807534  asset_id: 5807534
--drop table dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live;
CREATE EXTERNAL TABLE if not exists dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live (
  `user_id` bigint COMMENT 'user_id',
  `common_feature` string COMMENT 'common_feature',
  `app_version` string COMMENT 'app_version',
  `item_id` bigint COMMENT 'item_id',
  `location` bigint COMMENT 'location',
  `if_ads_item` int COMMENT 'if_ads_item',

  `ads_impr_cnt` bigint COMMENT 'ads_impr_cnt',
  `ads_click_cnt` bigint COMMENT 'ads_click_cnt',
  `ads_direct_order_cnt` bigint COMMENT 'ads_direct_order_cnt',
  `ads_broad_order_cnt` bigint COMMENT 'ads_broad_order_cnt',
  `ads_direct_gmv` decimal(25, 10) COMMENT 'ads_direct_gmv',
  `ads_broad_gmv` decimal(25, 10) COMMENT 'ads_broad_gmv',
  `ads_revenue` decimal(25, 10) COMMENT 'ads_revenue',
  `ads_gmv_usd` decimal(25, 10) COMMENT 'ads_gmv_usd',
  `ads_broad_gmv_usd` decimal(25, 10) COMMENT 'ads_broad_gmv_usd',
  `ads_revenue_usd` decimal(25, 10) COMMENT 'ads_revenue_usd',
  `ads_gmv_200_cap_usd` decimal(25, 10) COMMENT 'ads_gmv_200_cap_usd',
  `ads_gmv_500_cap_usd` decimal(25, 10) COMMENT 'ads_gmv_500_cap_usd',
  `ads_broad_gmv_200_cap_usd` decimal(25, 10) COMMENT 'ads_broad_gmv_200_cap_usd',
  `ads_broad_gmv_500_cap_usd` decimal(25, 10) COMMENT 'ads_broad_gmv_500_cap_usd',
  `ads_atc_cnt` bigint COMMENT 'ads_atc_cnt',
  `ads_commision_fee` decimal(25, 10) COMMENT 'ads_commision_fee',
  `ads_commision_fee_usd` decimal(25, 10) COMMENT 'ads_commision_fee_usd',

  `ads_deduction_click_cnt` bigint COMMENT 'ads_deduction_click_cnt',
  `ads_deduction_impression_cnt` bigint COMMENT 'ads_deduction_impression_cnt',
  `ads_live_view_cnt` bigint COMMENT 'ads_live_view_cnt',
  `ads_live_view_duration` bigint COMMENT 'ads_live_view_duration',
  `ads_live_item_click_cnt` bigint COMMENT 'ads_live_item_click_cnt',
  `ads_broad_item_sold_cnt` bigint COMMENT 'ads_broad_item_sold_cnt',
  `ads_direct_item_sold_cnt` bigint COMMENT 'ads_direct_item_sold_cnt',

  `omni_entry_impr_ads_cnt` bigint COMMENT 'omni_entry_impr_ads_cnt',
  `omni_entry_impr_organic_cnt` bigint COMMENT 'omni_entry_impr_organic_cnt',
  `omni_entry_impr_cnt` bigint COMMENT 'omni_entry_impr_cnt',
  `omni_entry_click_ads_cnt` bigint COMMENT 'omni_entry_click_ads_cnt',
  `omni_entry_click_organic_cnt` bigint COMMENT 'omni_entry_click_organic_cnt',
  `omni_entry_click_cnt` bigint COMMENT 'omni_entry_click_cnt',
  `omni_item_impr_ads_cnt` bigint COMMENT 'omni_item_impr_ads_cnt',
  `omni_item_impr_organic_cnt` bigint COMMENT 'omni_item_impr_organic_cnt',
  `omni_item_impr_cnt` bigint COMMENT 'omni_item_impr_cnt',
  `omni_item_click_ads_cnt` bigint COMMENT 'omni_item_click_ads_cnt',
  `omni_item_click_organic_cnt` bigint COMMENT 'omni_item_click_organic_cnt',
  `omni_item_click_cnt` bigint COMMENT 'omni_item_click_cnt',
  `omni_ads_ppv_cnt` bigint COMMENT 'omni_ads_ppv_cnt',
  `omni_organic_ppv_cnt` bigint COMMENT 'omni_organic_ppv_cnt',
  `omni_ppv_cnt` bigint COMMENT 'omni_ppv_cnt',
  `omni_ads_atc_cnt` bigint COMMENT 'omni_ads_atc_cnt',
  `omni_organic_atc_cnt` bigint COMMENT 'omni_organic_atc_cnt',
  `omni_atc_cnt` bigint COMMENT 'omni_atc_cnt',
  `omni_stay_time` bigint COMMENT 'omni_stay_time',
  `omni_ads_stay_time` bigint COMMENT 'omni_ads_stay_time',
  `omni_organic_stay_time` bigint COMMENT 'omni_organic_stay_time',

  `omni_ads_order_cnt` decimal(25, 10) COMMENT 'omni_ads_order_cnt',
  `omni_organic_order_cnt` decimal(25, 10) COMMENT 'omni_organic_order_cnt',
  `omni_order_cnt` decimal(25, 10) COMMENT 'omni_order_cnt',
  `omni_ads_gmv` decimal(25, 10) COMMENT 'omni_ads_gmv',
  `omni_organic_gmv` decimal(25, 10) COMMENT 'omni_organic_gmv',
  `omni_gmv` decimal(25, 10) COMMENT 'omni_gmv',
  `omni_ads_gmv_usd` decimal(25, 10) COMMENT 'omni_ads_gmv_usd',
  `omni_organic_gmv_usd` decimal(25, 10) COMMENT 'omni_organic_gmv_usd',
  `omni_gmv_usd` decimal(25, 10) COMMENT 'omni_gmv_usd',
  `omni_ads_commission_fee` decimal(25, 10) COMMENT 'omni_ads_commission_fee',
  `omni_organic_commission_fee` decimal(25, 10) COMMENT 'omni_organic_commission_fee',
  `omni_commission_fee` decimal(25, 10) COMMENT 'omni_commission_fee',
  `omni_ads_commission_fee_usd` decimal(25, 10) COMMENT 'omni_ads_commission_fee_usd',
  `omni_organic_commission_fee_usd` decimal(25, 10) COMMENT 'omni_organic_commission_fee_usd',
  `omni_commission_fee_usd` decimal(25, 10) COMMENT 'omni_commission_fee_usd',

  `omni_item_sold_cnt` bigint COMMENT 'omni_item_sold_cnt',
  `omni_ads_item_sold_cnt` bigint COMMENT 'omni_ads_item_sold_cnt',
  `omni_organic_item_sold_cnt` bigint COMMENT 'omni_organic_item_sold_cnt',
  
  `content_live_ads_view_cnt` bigint COMMENT 'content_live_ads_view_cnt',
  `content_live_ads_view_duration` bigint COMMENT 'content_live_ads_view_duration',
  `content_live_ads_item_click_cnt` bigint COMMENT 'content_live_ads_item_click_cnt',
  `content_live_ads_direct_order_cnt` bigint COMMENT 'content_live_ads_direct_order_cnt',
  `content_live_ads_direct_item_sold_cnt` bigint COMMENT 'content_live_ads_direct_item_sold_cnt',
  `content_live_ads_direct_gmv` decimal(25, 10) COMMENT 'content_live_ads_direct_gmv',
  `content_live_ads_direct_gmv_usd` decimal(25, 10) COMMENT 'content_live_ads_direct_gmv_usd',
  `content_live_ads_broad_order_cnt` bigint COMMENT 'content_live_ads_broad_order_cnt',
  `content_live_ads_broad_item_sold_cnt` bigint COMMENT 'content_live_ads_broad_item_sold_cnt',
  `content_live_ads_broad_gmv` decimal(25, 10) COMMENT 'content_live_ads_broad_gmv',
  `content_live_ads_broad_gmv_usd` decimal(25, 10) COMMENT 'content_live_ads_broad_gmv_usd',
  `ads_revenue_roi2` decimal(25, 10) COMMENT 'ads_revenue_roi2',
  `ads_revenue_usd_roi2` decimal(25, 10)  COMMENT 'ads_revenue_usd_roi2',
  `if_roi1_item` int COMMENT 'if_roi1_item',
  `if_roi2_item` int COMMENT 'if_roi2_item',
  `if_new_product_boost` int COMMENT 'if_new_product_boost',
  `if_simple2_item` int COMMENT 'if_simple2_item', 
  shop_id bigint comment 'shop_id'
  )
COMMENT 'paid_ads_dws_advertise_user_exp_common_feature_performance_1d'
PARTITIONED BY (
  `tz_type` string,
  `grass_region` string,
  `grass_date` date)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  '${HIVE_PATH}/dws_advertise_user_exp_common_feature_performance_1d';


-- order_commission 
-- order_id level
--create or replace temporary view order_commission_base
cache table order_commission_base
as
select  sum(commission_fee_usd) as commission_fee_usd, 
  sum(commission_fee) as commission_fee,
  sum(gmv) as gmv,sum(gmv_usd) as gmv_usd,order_id
from mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
where tz_type = 'local'
and grass_date = date('${grass_date}') 
and grass_region = upper('${region}')
and is_placed=1
and is_bi_excluded = 0 
group by order_id;

--ads_base_with_commission_fee
create or replace temporary view ads_base_info
as
  select grass_region,user_id,entrance,placement,app_version,ads_info.order_id,shop_id,
      item_id,location, impression_cnt, click_cnt, order_cnt, broad_order_cnt, ads_order_gmv_local,
      expenditure_amt_local,  broad_gmv_amt_local, add_to_cart_cnt, add_to_cart_without_clicks_cnt,
      raw_click_cnt,deduct_impression,view,view_duration,product_click,broad_item_cnt,ads_item_sold_cnt,
      commission_fee_usd,commission_fee,order_commission_gmv,order_commission_gmv_usd
  from
    (
      select grass_region,user_id,entrance,placement,shop_id,
              case when app_version is null then 'null'
                  when length(app_version)>5 then app_version
                  else concat(substr(app_version,1,1) , '.' , substr(app_version,2,2) , '.' , substr(app_version,4,2))
              end as app_version,order_id,
              case when item_id is null then -1 else item_id end as item_id,
              case when location is null then -1 else location end as location,
              impression_cnt,click_cnt,order_cnt,broad_order_cnt,ads_order_gmv_local,
        expenditure_amt_local,
        broad_gmv_amt_local,add_to_cart_cnt,add_to_cart_without_clicks_cnt,
        raw_click_cnt,deduct_impression,view,view_duration,product_click,broad_item_cnt,ads_item_sold_cnt
        from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where grass_date =  date('${grass_date}') 
        and grass_region=upper('${region}')
        and user_id>0
        and order_id is not null
    ) ads_info
    LEFT OUTER JOIN 
    (
      select order_id,commission_fee_usd, commission_fee, 
        gmv as order_commission_gmv , gmv_usd as order_commission_gmv_usd
      from order_commission_base
    ) order_commission_info
    ON ads_info.order_id = order_commission_info.order_id 

union all 
  select grass_region,user_id,entrance,placement,
          case when app_version is null then 'null'
              when length(app_version)>5 then app_version
              else concat(substr(app_version,1,1) , '.' , substr(app_version,2,2) , '.' , substr(app_version,4,2))
          end as app_version,order_id,shop_id,
          case when item_id is null then -1 else item_id end as item_id,
          case when location is null then -1 else location end as location,
          impression_cnt,click_cnt,order_cnt,broad_order_cnt,ads_order_gmv_local,
          expenditure_amt_local,
          broad_gmv_amt_local,add_to_cart_cnt,add_to_cart_without_clicks_cnt,
          raw_click_cnt,deduct_impression,view,view_duration,product_click,broad_item_cnt,ads_item_sold_cnt,
          null as commission_fee_usd, null as commission_fee,
          null as order_commission_gmv, null as order_commission_gmv_usd
    from mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where grass_date =  date('${grass_date}') 
    and grass_region=upper('${region}')
    and user_id>0
    and order_id is null;

--ads_performance_base
--create or replace temporary view ads_performance_base
cache table ads_performance_base
as
select grass_region,user_id, common_feature, app_version, item_id, location,shop_id,
  SUM(impression_cnt) as ads_impr_cnt,
  SUM(raw_click_cnt) as ads_click_cnt,
  SUM(order_cnt) as ads_direct_order_cnt,
  SUM(broad_order_cnt) as ads_broad_order_cnt,
  SUM(ads_direct_gmv) as ads_direct_gmv,
  SUM(ads_broad_gmv) as ads_broad_gmv,
  SUM(ads_revenue) as ads_revenue,
  SUM(ads_gmv_usd) as ads_gmv_usd,
  SUM(ads_broad_gmv_usd) as ads_broad_gmv_usd,
  SUM(ads_revenue_usd) as ads_revenue_usd,
  SUM(ads_gmv_200_cap_usd) as ads_gmv_200_cap_usd,
  SUM(ads_gmv_500_cap_usd) as ads_gmv_500_cap_usd,
  SUM(ads_broad_gmv_200_cap_usd) as ads_broad_gmv_200_cap_usd,
  SUM(ads_broad_gmv_500_cap_usd) as ads_broad_gmv_500_cap_usd,
  SUM(ads_atc_cnt) as ads_atc_cnt,
  SUM(ads_commision_fee) as ads_commision_fee,
  SUM(ads_commision_fee_usd) as ads_commision_fee_usd,
  SUM(click_cnt) as ads_deduction_click_cnt,
  SUM(deduct_impression) as ads_deduction_impression_cnt,
  SUM(view) as ads_live_view_cnt,
  SUM(view_duration) as ads_live_view_duration,
  SUM(product_click) as ads_live_item_click_cnt,
  SUM(broad_item_cnt) as ads_broad_item_sold_cnt,
  SUM(ads_item_sold_cnt) as ads_direct_item_sold_cnt,
  SUM(case when placement=40 then ads_revenue else 0 end) as ads_revenue_roi2,
  SUM(case when placement=40 then ads_revenue_usd else 0 end) as ads_revenue_usd_roi2
from 
(
  select ads_base.grass_region,user_id,placement,shop_id,
    coalesce(common_feature_mapping1.common_feature, 'Others') as common_feature,
    app_version,ads_base.item_id,location,
    impression_cnt,click_cnt,order_cnt,broad_order_cnt,
    expenditure_amt_local as ads_revenue,
    ads_order_gmv_local as ads_direct_gmv,
    (ads_order_gmv_local / order_commission_gmv) * commission_fee as ads_commision_fee,
    broad_gmv_amt_local as ads_broad_gmv,
    expenditure_amt_local/exchange_rate as ads_revenue_usd,
    ads_order_gmv_local/exchange_rate as ads_gmv_usd,
    (ads_order_gmv_local / exchange_rate / order_commission_gmv_usd) * commission_fee_usd as ads_commision_fee_usd,
    broad_gmv_amt_local/exchange_rate as ads_broad_gmv_usd,
    case when (ads_order_gmv_local/exchange_rate > 200) then 200 else ads_order_gmv_local/exchange_rate end as ads_gmv_200_cap_usd,
    case when (ads_order_gmv_local/exchange_rate > 500) then 500 else ads_order_gmv_local/exchange_rate end as ads_gmv_500_cap_usd,
    case when (broad_gmv_amt_local/exchange_rate > 200) then 200 else broad_gmv_amt_local/exchange_rate end as ads_broad_gmv_200_cap_usd,
    case when (broad_gmv_amt_local/exchange_rate > 500) then 500 else broad_gmv_amt_local/exchange_rate end as ads_broad_gmv_500_cap_usd,
    COALESCE(add_to_cart_cnt, 0) + COALESCE(add_to_cart_without_clicks_cnt,0) as ads_atc_cnt,
    raw_click_cnt,deduct_impression,view,view_duration,product_click,broad_item_cnt,ads_item_sold_cnt
  from
  (
    select * from ads_base_info
  ) ads_base
  LEFT OUTER JOIN 
  (
    select entrance,common_feature 
    from mp_paidads.dim_common_feature_mapping_v2__reg_s0_live
  ) common_feature_mapping1
  ON ads_base.entrance = common_feature_mapping1.entrance 
  LEFT OUTER JOIN 
  (
      select * from mp_order.dim_exchange_rate__reg_s0_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}')
  ) exchange_rate
  ON ads_base.grass_region = exchange_rate.grass_region

  union all 

  select ads_base.grass_region,user_id,placement,shop_id,
    'Platform' as common_feature,
    app_version,ads_base.item_id,location,
    impression_cnt,click_cnt,order_cnt,broad_order_cnt,
    expenditure_amt_local as ads_revenue,
    ads_order_gmv_local as ads_direct_gmv,
    (ads_order_gmv_local / order_commission_gmv) * commission_fee as ads_commision_fee,
    broad_gmv_amt_local as ads_broad_gmv,
    expenditure_amt_local/exchange_rate as ads_revenue_usd,
    ads_order_gmv_local/exchange_rate as ads_gmv_usd,
    (ads_order_gmv_local / exchange_rate / order_commission_gmv_usd) * commission_fee_usd as ads_commision_fee_usd,
    broad_gmv_amt_local/exchange_rate as ads_broad_gmv_usd,
    case when (ads_order_gmv_local/exchange_rate > 200) then 200 else ads_order_gmv_local/exchange_rate end as ads_gmv_200_cap_usd,
    case when (ads_order_gmv_local/exchange_rate > 500) then 500 else ads_order_gmv_local/exchange_rate end as ads_gmv_500_cap_usd,
    case when (broad_gmv_amt_local/exchange_rate > 200) then 200 else broad_gmv_amt_local/exchange_rate end as ads_broad_gmv_200_cap_usd,
    case when (broad_gmv_amt_local/exchange_rate > 500) then 500 else broad_gmv_amt_local/exchange_rate end as ads_broad_gmv_500_cap_usd,
    COALESCE(add_to_cart_cnt, 0) + COALESCE(add_to_cart_without_clicks_cnt,0) as ads_atc_cnt,
    raw_click_cnt,deduct_impression,view,view_duration,product_click,broad_item_cnt,ads_item_sold_cnt
  from
  (
    select * from ads_base_info
  ) ads_base
  LEFT OUTER JOIN 
  (
      select * from mp_order.dim_exchange_rate__reg_s0_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}')
  ) exchange_rate
  ON ads_base.grass_region = exchange_rate.grass_region
) 
group by grass_region,user_id,common_feature,app_version,item_id,location,shop_id;


--create or replace temporary view ads_performance_base
cache table ads_item_flag
as 
select common_feature, item_id, 1 as if_ads_item
from(
  select common_feature,item_id, sum(ads_impr_cnt) as c
  from ads_performance_base
  group by common_feature,item_id
  having c > 0
);

--create or replace temporary view flags
cache table ads_item_type_flag
as 
select item_id, common_feature, 
  if(roi1_item_imp > 0, 1, 0) as if_roi1_item,
  if(roi2_item_imp > 0, 1, 0) as if_roi2_item,
  if(new_product_boost_imp > 0, 1, 0) as if_new_product_boost,
  if(simple2_item_imp > 0, 1, 0) as if_simple2_item
from(
    select item_id,common_feature,sum(roi1_item_imp) as roi1_item_imp, 
          sum(roi2_item_imp) as roi2_item_imp,sum(new_product_boost_imp) as new_product_boost_imp,
          sum(simple2_item_imp) as simple2_item_imp
    from (
      select item_id,coalesce(common_feature, 'Others') as common_feature,
            roi1_item_imp,roi2_item_imp,new_product_boost_imp,simple2_item_imp
      from
      (
        select item_id,entrance,sum(roi1_item_imp) as roi1_item_imp, 
          sum(roi2_item_imp) as roi2_item_imp,sum(new_product_boost_imp) as new_product_boost_imp,
          sum(simple2_item_imp) as simple2_item_imp
        from(
          select item_id,entrance,
            case when (pricing_type in (1,2,3,4,7,8)) then impression_cnt else 0 end as roi1_item_imp,
            case when (placement in (40)) then impression_cnt else 0 end as roi2_item_imp,
            case when (pricing_type in (13) or new_product_boost_stage in (1,2)) then impression_cnt else 0 end as new_product_boost_imp,
            case when (pricing_type in (15)) then impression_cnt else 0 end as simple2_item_imp
          from mp_paidads.dwd_advertise_performance_di__reg_s0_live
            where grass_date =  date('${grass_date}') 
            and grass_region=upper('${region}')
        ) group by item_id,entrance
      ) ads_base
      LEFT OUTER JOIN 
      (
        select entrance,common_feature 
        from mp_paidads.dim_common_feature_mapping_v2__reg_s0_live
      ) common_feature_mapping1
      ON ads_base.entrance = common_feature_mapping1.entrance 
    ) group by item_id,common_feature
) 

union all

select item_id, common_feature, 
  if(roi1_item_imp > 0, 1, 0) as if_roi1_item,
  if(roi2_item_imp > 0, 1, 0) as if_roi2_item,
  if(new_product_boost_imp > 0, 1, 0) as if_new_product_boost,
  if(simple2_item_imp > 0, 1, 0) as if_simple2_item
from(
  select item_id, common_feature, sum(roi1_item_imp) as roi1_item_imp, 
    sum(roi2_item_imp) as roi2_item_imp,
    sum(new_product_boost_imp) as new_product_boost_imp,
    sum(simple2_item_imp) as simple2_item_imp
  from(
      select item_id, 'Platform' as common_feature,
        case when (pricing_type in (1,2,3,4,7,8)) then impression_cnt else 0 end as roi1_item_imp,
        case when (placement in (40)) then impression_cnt else 0 end as roi2_item_imp,
        case when (pricing_type in (13) or new_product_boost_stage in (1,2)) then impression_cnt else 0 end as new_product_boost_imp,
        case when (pricing_type in (15)) then impression_cnt else 0 end as simple2_item_imp
      from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where grass_date =  date('${grass_date}') 
        and grass_region=upper('${region}')
  ) group by item_id,common_feature
)
;


-- omni org && ads entry_point imp / click
--create or replace temporary view omni_entry_point_operation
cache table omni_entry_point_operation
as
select grass_region,user_id,common_feature,app_version,item_id,location,shop_id,
sum(case when is_ads = true and operation='impression' then 1 else 0 end) as omni_entry_impr_ads_cnt,
sum(case when (is_ads != true or is_ads is null) and operation='impression' then 1 else 0 end) as omni_entry_impr_organic_cnt,
sum(case when operation='impression' then 1 else 0 end) as omni_entry_impr_cnt,
sum(case when is_ads = true and operation='click' then 1 else 0 end) as omni_entry_click_ads_cnt,
sum(case when (is_ads != true or is_ads is null) and operation='click' then 1 else 0 end) as omni_entry_click_organic_cnt,
sum(case when operation='click' then 1 else 0 end) as omni_entry_click_cnt
from (
  select operation,user_id,common_property.is_ads as is_ads,grass_region,shop_id,
  case when app_version is null then 'null' else app_version end as app_version,
  case when item_id is null then -1 else item_id end as item_id,
  case when location_property.location is null then -1 else location_property.location end as location,
    case
      when (feature_detail like '%-shop_item'and feature_group = 'Search') or feature_detail = 'search-shop' then 'Search Shop'
      when module = 'Image Search' then 'Image Search'
      when feature_group = 'You May Also Like' then 'You May Also Like'
      when feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
      when feature_group = 'Cart Recommendation' then 'Cart Recommendation'
      when feature = 'mpp_ymal-order_list' then 'My Purchase Page Recommendation'
      when feature = 'odp_ymal-order_detail' then 'Order Detail Page Recommendation'
      when module = 'Daily Discover' then 'Daily Discover'
      when feature_group = 'Video' then 'Video'
      when feature_group = 'Games' then 'Games'
      when module = 'Global Search' then 'Global Search'
      when feature_group = 'Live Streaming' then 'Live Streaming'
      when feature_detail = 'me-you_may_also_like-item' then 'Me YMAL'
      when feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
      when feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
      when feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
      else 'Others'
  end as common_feature
  from traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live
  where grass_date =  date('${grass_date}') 
  and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
  and operation in ('impression', 'click')
) group by grass_region,user_id,common_feature,app_version,item_id,location,shop_id;


-- omni org && ads item imp / click
--create or replace temporary view omni_item_operation_base
cache table omni_item_operation_base
as
select grass_region,user_id,common_feature,app_version,item_id,location,shop_id,
sum(case when is_ads = true and operation='impression' then 1 else 0 end) as omni_item_impr_ads_cnt,
sum(case when (is_ads != true or is_ads is null) and operation='impression' then 1 else 0 end) as omni_item_impr_organic_cnt,
sum(case when operation='impression' then 1 else 0 end) as omni_item_impr_cnt,
sum(case when is_ads = true and operation='click' then 1 else 0 end) as omni_item_click_ads_cnt,
sum(case when (is_ads != true or is_ads is null) and operation='click' then 1 else 0 end) as omni_item_click_organic_cnt,
sum(case when operation='click' then 1 else 0 end) as omni_item_click_cnt
from(
  select operation,grass_region,user_id,app_version,item_id,is_ads,shop_id,
      case when location is null then -1 else location end as location,common_feature
  from (
      --step 0
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      case when ((feature_detail like '%-shop_item' and feature_group = 'Search') 
            or (feature_group in (
                'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                and source1.feature_detail = 'search-shop'))
           then source1.common_property.is_ads
      else common_property.is_ads end as is_ads,
      location_property.location as location,
      case
          when (
            (feature_detail like '%-shop_item' and feature_group = 'Search') 
            or (feature_group in (
                'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                and source1.feature_detail = 'search-shop')
           ) then 'Search Shop'
          when ((module = 'Global Search'))then 'Global Search'
          when ((module = 'Image Search'))then 'Image Search'
          when ((feature_group = 'You May Also Like')) then 'You May Also Like'
          when (feature_group = 'Live Streaming') then 'Live Streaming'
          when feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
          when feature_group = 'Cart Recommendation' then 'Cart Recommendation'
          when ((feature='mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
          when feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
          when ((module = 'Daily Discover'))then 'Daily Discover'
          when feature_group = 'Games' then 'Games'
          when feature_group = 'Video' and video_property.is_ymal_item=1 then 'Video YMAL'
          when feature_group = 'Video' then 'Video'
          when feature_detail = 'me-you_may_also_like-item' then 'Me YMAL'
          when feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
          when feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
          when feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
          when feature_detail = 'order_shipping_info-you_may_also_like-item' then 'Shipping Info Page YMAL'
          else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation in ('impression', 'click')

      union all

      --step 1
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      source1.common_property.is_ads as is_ads,
      source1.location_property.location as location,
      case
        when ((source1.module = 'Global Search'))then 'Global Search'
        when ((source1.module = 'Image Search'))then 'Image Search'
        when ((source1.feature_group = 'You May Also Like')) then 'You May Also Like'
        when (source1.feature_group = 'Live Streaming') then 'Live Streaming'
        when ((source1.feature = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
        when ((source1.module = 'Daily Discover'))then 'Daily Discover'
        when source1.feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
        when source1.feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
        when source1.feature_group = 'Games' then 'Games'
        when source1.feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
        when source1.feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
        when source1.feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
        else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation in ('impression', 'click')

      union all
      --step 2
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      source2.common_property.is_ads as is_ads,
      source2.location_property.location as location,
      case
        when ((source2.module = 'Global Search'))then 'Global Search'
        when ((source2.module = 'Image Search'))then 'Image Search'
        when ((source2.feature_group = 'You May Also Like')) then 'You May Also Like'
        when (source2.feature_group = 'Live Streaming') then 'Live Streaming'
        when ((source2.feature = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
        when ((source2.module = 'Daily Discover'))then 'Daily Discover'
        when source2.feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
        when source2.feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
        when source2.feature_group = 'Games' then 'Games'
        when source2.feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
        when source2.feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
        when source2.feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
        else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation in ('impression', 'click')

      union all
      --all steps
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      (common_property.is_ads or source1.common_property.is_ads or source2.common_property.is_ads) as is_ads,
      coalesce(location_property.location, source1.location_property.location , source2.location_property.location) as location,
      'Platform' as common_feature
      from traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation in ('impression', 'click')
  ) where common_feature != 'Others'
  )
group by grass_region,user_id,app_version,item_id,common_feature,shop_id,location;


-- omni org && ads ppv && stay_time
--create or replace temporary view omni_ppv_stay_time_base
cache table omni_ppv_stay_time_base
as
select grass_region,user_id,app_version,item_id,common_feature,location,shop_id,
SUM(case when is_ads=true and operation='view' then 1 else 0 end) as omni_ads_ppv_cnt,
SUM(case when (is_ads != true or is_ads is null) and operation='view' then 1 else 0 end) as omni_organic_ppv_cnt,
SUM(case when operation='view' then 1 else 0 end) as omni_ppv_cnt,
SUM(case when is_ads=true then page_duration else 0 end) as omni_ads_stay_time,
SUM(case when (is_ads != true or is_ads is null)  then page_duration else 0 end) as omni_organic_stay_time,
SUM(page_duration) as omni_stay_time
from(
  select operation,grass_region,user_id,app_version,item_id,is_ads,page_duration,operation,shop_id,
      case when location is null then -1 else location end as location,common_feature
  from (
      --step 0
      select operation,grass_region,user_id,page_duration,operation,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      case when (
            (feature_detail like '%-shop_item' and feature_group = 'Search') 
            or (feature_group in (
                'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                and source1.feature_detail = 'search-shop')
           ) then source1.common_property.is_ads
      else last_item_click.common_property.is_ads end as is_ads,
      location_property.location as location,
      case
          when (
            (feature_detail like '%-shop_item' and feature_group = 'Search') 
            or (feature_group in (
                'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                and source1.feature_detail = 'search-shop')
           ) then 'Search Shop'
          when ((last_item_click.module = 'Global Search'))then 'Global Search'
          when ((last_item_click.module = 'Image Search'))then 'Image Search'
          when ((feature_group = 'You May Also Like')) then 'You May Also Like'
          when (feature_group = 'Live Streaming') then 'Live Streaming'
          when feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
          when feature_group = 'Cart Recommendation' then 'Cart Recommendation'
          when ((feature='mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
          when feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
          when ((last_item_click.module = 'Daily Discover'))then 'Daily Discover'
          when feature_group = 'Games' then 'Games'
          when feature_group = 'Video' then 'Video'
          when feature_detail = 'me-you_may_also_like-item' then 'Me YMAL'
          when feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
          when feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
          when feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
          else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') and is_back = false
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0

      union all

      --step 1
      select operation,grass_region,user_id,page_duration,operation,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      source1.common_property.is_ads as is_ads,
      source1.location_property.location as location,
      case
        when ((source1.module = 'Global Search'))then 'Global Search'
        when ((source1.module = 'Image Search'))then 'Image Search'
        when ((source1.feature_group = 'You May Also Like')) then 'You May Also Like'
        when (source1.feature_group = 'Live Streaming') then 'Live Streaming'
        when ((source1.feature = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
        when ((source1.module = 'Daily Discover'))then 'Daily Discover'
        when source1.feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
        when source1.feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
        when source1.feature_group = 'Games' then 'Games'
        when source1.feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
        when source1.feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
        when source1.feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
        else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') and is_back = false
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0

      union all
      --step 2
      select operation,grass_region,user_id,page_duration,operation,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      source2.common_property.is_ads as is_ads,
      source2.location_property.location as location,
      case
        when ((source2.module = 'Global Search'))then 'Global Search'
        when ((source2.module = 'Image Search'))then 'Image Search'
        when ((source2.feature_group = 'You May Also Like')) then 'You May Also Like'
        when (source2.feature_group = 'Live Streaming') then 'Live Streaming'
        when ((source2.feature = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
        when ((source2.module = 'Daily Discover'))then 'Daily Discover'
        when source2.feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
        when source2.feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
        when source2.feature_group = 'Games' then 'Games'
        when source2.feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
        when source2.feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
        when source2.feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
        else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') and is_back = false
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0

      union all
      --all steps
      select operation,grass_region,user_id,page_duration,operation,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      (common_property.is_ads or source1.common_property.is_ads or source2.common_property.is_ads) as is_ads,
      coalesce(location_property.location, source1.location_property.location , source2.location_property.location) as location,
      'Platform' as common_feature
      from traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') and is_back = false
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
  ) where common_feature != 'Others'
  )
group by grass_region,user_id,app_version,item_id,common_feature,shop_id,location
;

-- omni org && ads atc
--create or replace temporary view omni_atc_base
cache table omni_atc_base
as
select grass_region,user_id,app_version,item_id,common_feature,location,shop_id,
SUM(case when is_ads=true and operation='action_add_to_cart_success' then 1 else 0 end) as omni_ads_atc_cnt,
SUM(case when (is_ads != true or is_ads is null) and operation='action_add_to_cart_success' then 1 else 0 end) as omni_organic_atc_cnt,
SUM(case when operation='action_add_to_cart_success' then 1 else 0 end) as omni_atc_cnt
from(
  select operation,grass_region,user_id,app_version,item_id,is_ads,shop_id,
      case when location is null then -1 else location end as location,common_feature
  from (
      --step 0
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      case when (
            (feature_detail like '%-shop_item' and feature_group = 'Search') 
            or (feature_group in (
                'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                and source1.feature_detail = 'search-shop')
           ) then source1.common_property.is_ads
      else last_item_click.common_property.is_ads end as is_ads,
      location_property.location as location,
      case
          when (
            (feature_detail like '%-shop_item' and feature_group = 'Search') 
            or (feature_group in (
                'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                and source1.feature_detail = 'search-shop')
           ) then 'Search Shop'
          when ((last_item_click.module = 'Global Search'))then 'Global Search'
          when ((last_item_click.module = 'Image Search'))then 'Image Search'
          when ((feature_group = 'You May Also Like')) then 'You May Also Like'
          when (feature_group = 'Live Streaming') then 'Live Streaming'
          when feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
          when feature_group = 'Cart Recommendation' then 'Cart Recommendation'
          when ((feature='mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
          when feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
          when ((last_item_click.module = 'Daily Discover'))then 'Daily Discover'
          when feature_group = 'Games' then 'Games'
          when feature_group = 'Video' then 'Video'
          when feature_detail = 'me-you_may_also_like-item' then 'Me YMAL'
          when feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
          when feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
          when feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
          else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation='action_add_to_cart_success'

      union all

      --step 1
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      source1.common_property.is_ads as is_ads,
      source1.location_property.location as location,
      case
        when ((source1.module = 'Global Search'))then 'Global Search'
        when ((source1.module = 'Image Search'))then 'Image Search'
        when ((source1.feature_group = 'You May Also Like')) then 'You May Also Like'
        when (source1.feature_group = 'Live Streaming') then 'Live Streaming'
        when ((source1.feature = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
        when ((source1.module = 'Daily Discover'))then 'Daily Discover'
        when source1.feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
        when source1.feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
        when source1.feature_group = 'Games' then 'Games'
        when source1.feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
        when source1.feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
        when source1.feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
        else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation='action_add_to_cart_success'

      union all
      --step 2
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      source2.common_property.is_ads as is_ads,
      source2.location_property.location as location,
      case
        when ((source2.module = 'Global Search'))then 'Global Search'
        when ((source2.module = 'Image Search'))then 'Image Search'
        when ((source2.feature_group = 'You May Also Like')) then 'You May Also Like'
        when (source2.feature_group = 'Live Streaming') then 'Live Streaming'
        when ((source2.feature = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
        when ((source2.module = 'Daily Discover'))then 'Daily Discover'
        when source2.feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
        when source2.feature='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
        when source2.feature_group = 'Games' then 'Games'
        when source2.feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
        when source2.feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
        when source2.feature_detail = 'shop-you_may_also_like-item' then 'Shop YMAL'
        else 'Others'
      end as common_feature
      from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation='action_add_to_cart_success'

      union all
      --all steps
      select operation,grass_region,user_id,shop_id,
      case when app_version is null then 'null' else app_version end as app_version,
      case when item_id is null then -1 else item_id end as item_id,
      (common_property.is_ads or source1.common_property.is_ads or source2.common_property.is_ads) as is_ads,
      coalesce(location_property.location, source1.location_property.location , source2.location_property.location) as location,
      'Platform' as common_feature
      from traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live
      where grass_date =  date('${grass_date}') 
      and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      and operation='action_add_to_cart_success'
  ) where common_feature != 'Others'
  )
group by grass_region,user_id,app_version,item_id,common_feature,shop_id,location
;



-- omni org && ads order/gmv 
--create or replace temporary view omni_order_gmv_base
--drop table omni_order_gmv_base;
cache table omni_order_gmv_base
as
select grass_region,user_id,app_version,item_id,common_feature,location,shop_id,
SUM(case when is_ads=true then order_fraction*atc_prorate*first_touchpoint_item else 0 end) as omni_ads_order_cnt,
SUM(case when (is_ads != true or is_ads is null) then order_fraction*atc_prorate*first_touchpoint_item else 0 end) as omni_organic_order_cnt,
SUM(order_fraction*atc_prorate*first_touchpoint_item) as omni_order_cnt,
SUM(case when is_ads=true then gmv*atc_prorate*first_touchpoint_item else 0 end) as omni_ads_gmv,
SUM(case when (is_ads != true or is_ads is null) then gmv*atc_prorate*first_touchpoint_item else 0 end) as omni_organic_gmv,
SUM(gmv*atc_prorate*first_touchpoint_item) as omni_gmv,
SUM(case when is_ads=true then gmv_usd*atc_prorate*first_touchpoint_item else 0 end) as omni_ads_gmv_usd,
SUM(case when (is_ads != true or is_ads is null) then gmv_usd*atc_prorate*first_touchpoint_item else 0 end) as omni_organic_gmv_usd,
SUM(gmv_usd*atc_prorate*first_touchpoint_item) as omni_gmv_usd,
SUM(case when is_ads=true then omni_commission_fee*atc_prorate*first_touchpoint_item else 0 end) as omni_ads_commission_fee,
SUM(case when (is_ads != true or is_ads is null) then omni_commission_fee*atc_prorate*first_touchpoint_item else 0 end) as omni_organic_commission_fee,
SUM(omni_commission_fee*atc_prorate*first_touchpoint_item) as omni_commission_fee,
SUM(case when is_ads=true then omni_commission_fee_usd*atc_prorate*first_touchpoint_item else 0 end) as omni_ads_commission_fee_usd,
SUM(case when (is_ads != true or is_ads is null) then omni_commission_fee_usd*atc_prorate*first_touchpoint_item else 0 end) as omni_organic_commission_fee_usd,
SUM(omni_commission_fee_usd*atc_prorate*first_touchpoint_item) as omni_commission_fee_usd,
SUM(case when is_ads=true then item_amount*atc_prorate*first_touchpoint_item else 0 end) as omni_ads_item_sold_cnt,
SUM(case when (is_ads != true or is_ads is null) then item_amount*atc_prorate*first_touchpoint_item else 0 end) as omni_organic_item_sold_cnt,
SUM(item_amount*atc_prorate*first_touchpoint_item) as omni_item_sold_cnt
from(
  select grass_region,user_id,app_version,item_id,is_ads,gmv_usd,gmv,item_amount,shop_id,
      case when location is null then -1 else location end as location,common_feature,
      atc_prorate,first_touchpoint_item,order_fraction,omni_commission_fee,omni_commission_fee_usd
  from (
    select grass_region,user_id,item_amount,shop_id,
    case when app_version is null then 'null' else app_version end as app_version,
    case when item_id is null then -1 else item_id end as item_id,gmv_usd,gmv,is_ads,
      atc_prorate,first_touchpoint_item,order_fraction,common_feature,location,
      (gmv / order_commission_gmv) * commission_fee as omni_commission_fee,
      (gmv_usd / order_commission_gmv_usd) * commission_fee_usd as omni_commission_fee_usd
    from
      (
        --step 0
        select grass_region,user_id,app_version,order_item_id as item_id,item_amount,shop_id,
              gmv_usd,gmv,atc_prorate,first_touchpoint_item,order_fraction,order_id,
        case when (
              (feature_detail_omni like '%-shop_item' and feature_group_omni = 'Search') 
              or (feature_group_omni in (
                  'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                  and source1_feature_detail_omni = 'search-shop')
            ) then source1_common_property.is_ads
        else click_common_property.is_ads end as is_ads,
        click_location_property.location as location,
        case
            when (
              (feature_detail_omni like '%-shop_item' and feature_group_omni = 'Search') 
              or (feature_group_omni in (
                  'Shop Main Browsing','Shop','Shop Other Recommendations','Shop Product Tab','Shop Recommended For You')
                  and source1_feature_detail_omni = 'search-shop')
            ) then 'Search Shop'
            when ((module = 'Global Search'))then 'Global Search'
            when ((module = 'Image Search'))then 'Image Search'
            
            when ((feature_group_omni = 'You May Also Like')) then 'You May Also Like'
            when (feature_group_omni = 'Live Streaming') then 'Live Streaming'
            when feature_group_omni = 'Order Successful Recommendation' then 'Order Successful Recommendation'
            when feature_group_omni = 'Cart Recommendation' then 'Cart Recommendation'
            when ((feature_omni='mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
            when feature_omni='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
            when ((module = 'Daily Discover'))then 'Daily Discover'
            when feature_group_omni = 'Games' then 'Games'
            when feature_group_omni = 'Video' then 'Video'
            when feature_detail_omni = 'me-you_may_also_like-item' then 'Me YMAL'
            when feature_omni = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
            when feature_omni = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
            when feature_detail_omni = 'shop-you_may_also_like-item' then 'Shop YMAL'
            else 'Others'
        end as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
          where grass_date =  date('${grass_date}') 
          and grass_region=upper('${region}') and tz_type = 'local' and user_id>0

        union all

        --step 1
        select grass_region,user_id,app_version,order_item_id as item_id,item_amount,shop_id,
              gmv_usd,gmv,atc_prorate,first_touchpoint_item,order_fraction,order_id,
        source1_common_property.is_ads as is_ads,
        source1_location_property.location as location,
        case
          when ((source1_module = 'Global Search'))then 'Global Search'
          when ((source1_module = 'Image Search'))then 'Image Search'
          when ((source1_feature_group_omni = 'You May Also Like')) then 'You May Also Like'
          when (source1_feature_group_omni = 'Live Streaming') then 'Live Streaming'
          when ((source1_feature_omni = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
          when ((source1_module = 'Daily Discover'))then 'Daily Discover'
          when source1_feature_group_omni = 'Order Successful Recommendation' then 'Order Successful Recommendation'
          when source1_feature_omni='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
          when source1_feature_group_omni = 'Games' then 'Games'
          when source1_feature_omni = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
          when source1_feature_omni = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
          when source1_feature_detail_omni = 'shop-you_may_also_like-item' then 'Shop YMAL'
          else 'Others'
        end as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
          where grass_date =  date('${grass_date}') 
          and grass_region=upper('${region}') and tz_type = 'local' and user_id>0

        union all
        --step 2
        select grass_region,user_id,app_version,order_item_id as item_id,item_amount,shop_id,
              gmv_usd,gmv,atc_prorate,first_touchpoint_item,order_fraction,order_id,
        source2_common_property.is_ads as is_ads,
        source2_location_property.location as location,
        case
          when ((source2_module = 'Global Search'))then 'Global Search'
          when ((source2_module = 'Image Search'))then 'Image Search'
          when ((source2_feature_group_omni = 'You May Also Like')) then 'You May Also Like'
          when (source2_feature_group_omni = 'Live Streaming') then 'Live Streaming'
          when ((source2_feature_omni = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
          when ((source2_module = 'Daily Discover'))then 'Daily Discover'
          when source2_feature_group_omni = 'Order Successful Recommendation' then 'Order Successful Recommendation'
          when source2_feature_omni ='odp_ymal-order_detail' then 'Order Detail Page Recommendation'
          when source2_feature_group_omni = 'Games' then 'Games'
          when source2_feature_omni = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
          when source2_feature_omni = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
          when source2_feature_detail_omni = 'shop-you_may_also_like-item' then 'Shop YMAL'
          else 'Others'
        end as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
          where grass_date =  date('${grass_date}') 
          and grass_region=upper('${region}') and tz_type = 'local' and user_id>0

        union all
        --all steps
        select grass_region,user_id,app_version,order_item_id as item_id,item_amount,shop_id,
              gmv_usd,gmv,atc_prorate,first_touchpoint_item,order_fraction,order_id,
        (click_common_property.is_ads or source1_common_property.is_ads or source2_common_property.is_ads) as is_ads,
        coalesce(click_location_property.location, source1_location_property.location , source2_location_property.location) as location,
        'Platform' as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
          where grass_date =  date('${grass_date}') 
          and grass_region=upper('${region}') and tz_type = 'local' and user_id>0
      ) omni_order_info
      LEFT OUTER JOIN 
      (
        select order_id,commission_fee_usd, commission_fee, 
          gmv as order_commission_gmv , gmv_usd as order_commission_gmv_usd
        from order_commission_base
      ) order_commission_info
      ON omni_order_info.order_id = order_commission_info.order_id  
  ) where common_feature != 'Others'
  )
group by grass_region,user_id,app_version,item_id,common_feature,shop_id,location
;

--content live metrics
create or replace temporary view content_live_details
as
select grass_date,
grass_region,
order_platform as platform,
app_version,
order_item_id as item_id,
order_buyer_id as user_id,
order_shop_id as shop_id,
-1 as location,
'Live Streaming' as common_feature,
sum(case when (order_cal_type='direct'  and order_other_supply='omni')
  then ls_order_fraction else 0 end) as content_live_ads_direct_order_cnt,
sum(case when (order_cal_type='direct'  and order_other_supply='omni')
  then item_amount else 0 end) as content_live_ads_direct_item_sold_cnt,
sum(case when (order_cal_type='direct'  and order_other_supply='omni')
  then gmv else 0 end) as content_live_ads_direct_gmv,
sum(case when (order_cal_type='direct'  and order_other_supply='omni')
  then gmv_usd else 0 end) as content_live_ads_direct_gmv_usd,
sum(case when ((order_cal_type='indirect' )
      or (order_cal_type='direct'  and order_other_supply='omni'))
  then ls_order_fraction else 0 end) as content_live_ads_broad_order_cnt,
sum(case when ((order_cal_type='indirect' )
      or (order_cal_type='direct'  and order_other_supply='omni'))
  then item_amount else 0 end) as content_live_ads_broad_item_sold_cnt,
sum(case when ((order_cal_type='indirect' )
      or (order_cal_type='direct'  and order_other_supply='omni'))
  then gmv else 0 end) as content_live_ads_broad_gmv,
sum(case when ((order_cal_type='indirect' )
      or (order_cal_type='direct'  and order_other_supply='omni'))
  then gmv_usd else 0 end) as content_live_ads_broad_gmv_usd
from mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di
where grass_date =  date('${grass_date}') 
and grass_region=upper('${region}')
and tz_type='local'
and from_source_page='streaming_room'
and is_content_directly_related=1
group by 1,2,3,4,5,6,7;

--content only metrics
create or replace temporary view content_user_view_click
as
select grass_date,
grass_region,
platform,
app_version,
user_id,
shop_id,
count(distinct case when (operation='view') then event_id else null end)  as content_live_ads_view_cnt,
count(distinct case when ((operation='click') and ((target_type = 'buy_now')
          or  (target_type = 'atc')
          or  (target_type = 'add_to_cart_button')
          or  (target_type = 'item')
          or  (page_section[0]= 'related_product_list' and target_type = 'buy_now_button')
          or  (page_section[0]= 'item_card' and target_type = 'buy_now_button' )
          or  (page_section[0]= 'item_card' )
          or  (page_section[0]= 'display_window' and target_type = 'buy_button')
          or  (page_section[0]='related_product_list' and target_type = 'arrow')
          or  (page_section[0]='cmt_instant_atc' and target_type = 'buy_now_button')
          or  (page_section[0]='display_window' and target_type = 'right_arrow_button')
          or  (page_section[0]='item_cart' and target_type = 'arrow' )
          or  (target_type = 'float_item_comment' )
          )) then event_id else null end)  as content_live_ads_item_click_cnt,
-1 as item_id,
-1 as location,
'Live Streaming' as common_feature
from livestream.ls_mart_dwd_traffic_ls_session_view_detail_di
where grass_date =  date('${grass_date}') 
and user_id is not null
and grass_region=upper('${region}')
and tz_type='local'
and operation='view'
and page_type='streaming_room'
group by 1,2,3,4,5,6;

--content only metrics
create or replace temporary view content_user_view_duration
as
select t1.grass_date,
t1.grass_region,
t1.user_id,
t2.platform,
t2.app_version,
t2.shop_id,
sum(duration_b) as content_live_ads_view_duration,
-1 as item_id,
-1 as location,
'Live Streaming' as common_feature
from (
select
    grass_date,
    grass_region,
    viewer_id as user_id,
    view_event_id,
    duration_b
from livestream.ls_mart_dwd_view_streaming_detail_di 
where grass_date =  date('${grass_date}') 
and grass_region=upper('${region}')
and tz_type = 'local'
)t1
left join (
select grass_date,
grass_region,
event_id,
user_id,
app_version,
platform,
shop_id
from livestream.ls_mart_dwd_traffic_ls_session_view_detail_di 
where grass_date =  date('${grass_date}') 
and grass_region=upper('${region}')
and tz_type = 'local'
and operation='view'
and page_type='streaming_room'
and (user_id >0 or user_id is not null)
)t2
on t1.grass_date=t2.grass_date
and t1.grass_region=t2.grass_region
and t1.view_event_id=t2.event_id
group by 1,2,3,4,5,6;

--create or replace temporary view content_live_metrics_all
cache table content_live_metrics_all
as
select coalesce(t3.user_id,t4.user_id) as user_id,
  coalesce(t3.common_feature,t4.common_feature) as common_feature,
  coalesce(t3.app_version,t4.app_version) as app_version,
  coalesce(t3.item_id,t4.item_id) as item_id,
  coalesce(t3.location,t4.location) as location,
  coalesce(t3.shop_id,t4.shop_id) as shop_id,

  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt,
  content_live_ads_direct_order_cnt,content_live_ads_broad_order_cnt,
  content_live_ads_direct_item_sold_cnt,content_live_ads_broad_item_sold_cnt,
  content_live_ads_direct_gmv,content_live_ads_broad_gmv,
  content_live_ads_direct_gmv_usd,content_live_ads_broad_gmv_usd
from 
(
  select 
  coalesce(t1.user_id,t2.user_id) as user_id,
  coalesce(t1.common_feature,t2.common_feature) as common_feature,
  coalesce(t1.app_version,t2.app_version) as app_version,
  coalesce(t1.item_id,t2.item_id) as item_id,
  coalesce(t1.location,t2.location) as location,
  coalesce(t1.shop_id,t2.shop_id) as shop_id,
  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt
from 
  (
  select * from content_user_view_click
  ) t1
  FULL JOIN
  (
    select * from content_user_view_duration
  ) t2
  ON  t1.user_id = t2.user_id
  AND t1.common_feature = t2.common_feature
  AND t1.app_version <=> t2.app_version
  AND t1.item_id = t2.item_id
  AND t1.location = t2.location
  and t1.shop_id <=> t2.shop_id
)t3 FULL JOIN(
    select * from content_live_details
)  t4
ON  t3.user_id = t4.user_id
AND t3.common_feature = t4.common_feature
AND t3.app_version <=> t4.app_version
AND t3.item_id = t4.item_id
AND t3.location = t4.location
and t3.shop_id <=> t4.shop_id;


create or replace temporary view omni_imp_clk
as
select 
  coalesce(t1.user_id,t2.user_id) as user_id,
  coalesce(t1.common_feature,t2.common_feature) as common_feature,
  coalesce(t1.app_version,t2.app_version) as app_version,
  coalesce(t1.item_id,t2.item_id) as item_id,
  coalesce(t1.location,t2.location) as location,
  coalesce(t1.shop_id,t2.shop_id) as shop_id,

  omni_entry_impr_ads_cnt,omni_entry_impr_organic_cnt, omni_entry_impr_cnt,
  omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt,

  omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt,
  omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt
from 
  (
  select * from omni_entry_point_operation
  ) t1
  FULL JOIN
  (
    select * from omni_item_operation_base
  ) t2
  ON  t1.user_id = t2.user_id
  AND t1.common_feature = t2.common_feature
  AND t1.app_version <=> t2.app_version
  AND t1.item_id = t2.item_id
  AND t1.location = t2.location
  and t1.shop_id <=> t2.shop_id;

create or replace temporary view omni_ppv_atc
as
select 
  coalesce(t3.user_id,t4.user_id) as user_id,
  coalesce(t3.common_feature,t4.common_feature) as common_feature,
  coalesce(t3.app_version,t4.app_version) as app_version,
  coalesce(t3.item_id,t4.item_id) as item_id,
  coalesce(t3.location,t4.location) as location,
  coalesce(t3.shop_id,t4.shop_id) as shop_id,
  omni_ads_ppv_cnt, omni_organic_ppv_cnt, omni_ppv_cnt,
  omni_ads_atc_cnt, omni_organic_atc_cnt, omni_atc_cnt,
  omni_ads_stay_time, omni_organic_stay_time, omni_stay_time,
  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt,
  content_live_ads_direct_order_cnt,content_live_ads_broad_order_cnt,
  content_live_ads_direct_item_sold_cnt,content_live_ads_broad_item_sold_cnt,
  content_live_ads_direct_gmv,content_live_ads_broad_gmv,
  content_live_ads_direct_gmv_usd,content_live_ads_broad_gmv_usd
from 
(
select 
  coalesce(t1.user_id,t2.user_id) as user_id,
  coalesce(t1.common_feature,t2.common_feature) as common_feature,
  coalesce(t1.app_version,t2.app_version) as app_version,
  coalesce(t1.item_id,t2.item_id) as item_id,
  coalesce(t1.location,t2.location) as location,
  coalesce(t1.shop_id,t2.shop_id) as shop_id,
  omni_ads_ppv_cnt, omni_organic_ppv_cnt, omni_ppv_cnt,
  omni_ads_atc_cnt, omni_organic_atc_cnt, omni_atc_cnt,
  omni_ads_stay_time, omni_organic_stay_time, omni_stay_time
from 
  (
  select * from omni_ppv_stay_time_base
  ) t1
  FULL JOIN
  (
    select * from omni_atc_base
  ) t2
  ON  t1.user_id = t2.user_id
  AND t1.common_feature = t2.common_feature
  AND t1.app_version <=> t2.app_version
  AND t1.item_id = t2.item_id
  AND t1.location = t2.location
  and t1.shop_id <=> t2.shop_id
) t3
  FULL JOIN
(
select * from content_live_metrics_all
) t4
ON  t3.user_id = t4.user_id
AND t3.common_feature = t4.common_feature
AND t3.app_version <=> t4.app_version
AND t3.item_id = t4.item_id
AND t3.location = t4.location
and t3.shop_id <=> t4.shop_id;

create or replace temporary view omni_imp_clk_ppv_atc_order_gmv
as
select coalesce(t3.user_id,t4.user_id) as user_id,
  coalesce(t3.common_feature,t4.common_feature) as common_feature,
  coalesce(t3.app_version,t4.app_version) as app_version,
  coalesce(t3.item_id,t4.item_id) as item_id,
  coalesce(t3.location,t4.location) as location,
  coalesce(t3.shop_id,t4.shop_id) as shop_id,
  omni_entry_impr_ads_cnt,omni_entry_impr_organic_cnt, omni_entry_impr_cnt,
  omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt,

  omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt,
  omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt,
  omni_ads_ppv_cnt, omni_organic_ppv_cnt, omni_ppv_cnt,
  omni_ads_atc_cnt, omni_organic_atc_cnt, omni_atc_cnt,
  omni_ads_stay_time, omni_organic_stay_time, omni_stay_time,
  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt,
  content_live_ads_direct_order_cnt,content_live_ads_broad_order_cnt,
  content_live_ads_direct_item_sold_cnt,content_live_ads_broad_item_sold_cnt,
  content_live_ads_direct_gmv,content_live_ads_broad_gmv,
  content_live_ads_direct_gmv_usd,content_live_ads_broad_gmv_usd,
  omni_ads_order_cnt, omni_organic_order_cnt, omni_order_cnt,
  omni_ads_gmv, omni_organic_gmv, omni_gmv, omni_ads_gmv_usd, omni_organic_gmv_usd, omni_gmv_usd,
  omni_ads_commission_fee, omni_organic_commission_fee, omni_commission_fee,
  omni_ads_commission_fee_usd, omni_organic_commission_fee_usd, omni_commission_fee_usd,
  omni_item_sold_cnt,omni_ads_item_sold_cnt,omni_organic_item_sold_cnt
from 
  (select 
  coalesce(t1.user_id,t2.user_id) as user_id,
  coalesce(t1.common_feature,t2.common_feature) as common_feature,
  coalesce(t1.app_version,t2.app_version) as app_version,
  coalesce(t1.item_id,t2.item_id) as item_id,
  coalesce(t1.location,t2.location) as location,
  coalesce(t1.shop_id,t2.shop_id) as shop_id,
  omni_entry_impr_ads_cnt,omni_entry_impr_organic_cnt, omni_entry_impr_cnt,
  omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt,

  omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt,
  omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt,
  omni_ads_ppv_cnt, omni_organic_ppv_cnt, omni_ppv_cnt,
  omni_ads_atc_cnt, omni_organic_atc_cnt, omni_atc_cnt,
  omni_ads_stay_time, omni_organic_stay_time, omni_stay_time,
  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt,
  content_live_ads_direct_order_cnt,content_live_ads_broad_order_cnt,
  content_live_ads_direct_item_sold_cnt,content_live_ads_broad_item_sold_cnt,
  content_live_ads_direct_gmv,content_live_ads_broad_gmv,
  content_live_ads_direct_gmv_usd,content_live_ads_broad_gmv_usd
from 
  (
  select * from omni_imp_clk
  ) t1
  FULL JOIN
  (
    select * from omni_ppv_atc
  ) t2
  ON  t1.user_id = t2.user_id
  AND t1.common_feature = t2.common_feature
  AND t1.app_version <=> t2.app_version
  AND t1.item_id = t2.item_id
  AND t1.location = t2.location
  and t1.shop_id <=> t2.shop_id
) t3
  FULL JOIN
  (
    select * from omni_order_gmv_base
  ) t4
  ON  t3.user_id = t4.user_id
  AND t3.common_feature = t4.common_feature
  AND t3.app_version <=> t4.app_version
  AND t3.item_id = t4.item_id
  AND t3.location = t4.location
  and t3.shop_id <=> t4.shop_id;


insert overwrite table dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live 
partition (tz_type='local', grass_region, grass_date)
select user_id,full_table.common_feature,app_version,full_table.item_id,location,
  coalesce(if_ads_item, 0) as if_ads_item,
  --paidads metrics
  ads_impr_cnt, ads_click_cnt,ads_direct_order_cnt,ads_broad_order_cnt, ads_direct_gmv,
  ads_broad_gmv, ads_revenue, ads_gmv_usd, ads_broad_gmv_usd, ads_revenue_usd, ads_gmv_200_cap_usd,
  ads_gmv_500_cap_usd, ads_broad_gmv_200_cap_usd, ads_broad_gmv_500_cap_usd, ads_atc_cnt,
  ads_commision_fee, ads_commision_fee_usd, ads_deduction_click_cnt, ads_deduction_impression_cnt, ads_live_view_cnt,
  ads_live_view_duration, ads_live_item_click_cnt, ads_broad_item_sold_cnt, ads_direct_item_sold_cnt,

  --omini metrics
  omni_entry_impr_ads_cnt,omni_entry_impr_organic_cnt, omni_entry_impr_cnt,
  omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt,

  omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt,
  omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt,

  omni_ads_ppv_cnt, omni_organic_ppv_cnt, omni_ppv_cnt,

  omni_ads_atc_cnt, omni_organic_atc_cnt, omni_atc_cnt,
  omni_ads_stay_time, omni_organic_stay_time, omni_stay_time,
  omni_ads_order_cnt, omni_organic_order_cnt, omni_order_cnt,
  omni_ads_gmv, omni_organic_gmv, omni_gmv, omni_ads_gmv_usd, omni_organic_gmv_usd, omni_gmv_usd,
  omni_ads_commission_fee, omni_organic_commission_fee, omni_commission_fee,
  omni_ads_commission_fee_usd, omni_organic_commission_fee_usd, omni_commission_fee_usd,
  omni_item_sold_cnt,omni_ads_item_sold_cnt,omni_organic_item_sold_cnt,
  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt,
  content_live_ads_direct_order_cnt,
  content_live_ads_direct_item_sold_cnt,
  content_live_ads_direct_gmv,
  content_live_ads_direct_gmv_usd,
  content_live_ads_broad_order_cnt,
  content_live_ads_broad_item_sold_cnt,
  content_live_ads_broad_gmv,
  content_live_ads_broad_gmv_usd,
  ads_revenue_roi2,
  ads_revenue_usd_roi2,
  if_roi1_item,
  if_roi2_item,
  if_new_product_boost,
  if_simple2_item,
  full_table.shop_id as shop_id,
  upper('${region}') as grass_region,
  date('${grass_date}')  as grass_date
from (
select 
  -- dimension
  coalesce(t1.user_id,t2.user_id) as user_id,
  coalesce(t1.common_feature,t2.common_feature) as common_feature,
  coalesce(t1.app_version,t2.app_version) as app_version,
  coalesce(t1.item_id,t2.item_id) as item_id,
  coalesce(t1.location,t2.location) as location,
  coalesce(t1.shop_id,t2.shop_id) as shop_id,

  --paidads metrics
  ads_impr_cnt, ads_click_cnt,ads_direct_order_cnt,ads_broad_order_cnt, ads_direct_gmv,
  ads_broad_gmv, ads_deduction_click_cnt, ads_deduction_impression_cnt, ads_live_view_cnt,
  ads_live_view_duration, ads_live_item_click_cnt, ads_broad_item_sold_cnt, ads_direct_item_sold_cnt,
  ads_revenue, ads_gmv_usd, ads_broad_gmv_usd, ads_revenue_usd, ads_gmv_200_cap_usd,
  ads_gmv_500_cap_usd, ads_broad_gmv_200_cap_usd, ads_broad_gmv_500_cap_usd, ads_atc_cnt,
  ads_commision_fee, ads_commision_fee_usd,

  --omini metrics
  omni_entry_impr_ads_cnt,omni_entry_impr_organic_cnt, omni_entry_impr_cnt,
  omni_entry_click_ads_cnt, omni_entry_click_organic_cnt, omni_entry_click_cnt,

  omni_item_impr_ads_cnt, omni_item_impr_organic_cnt, omni_item_impr_cnt,
  omni_item_click_ads_cnt, omni_item_click_organic_cnt, omni_item_click_cnt,

  omni_ads_ppv_cnt, omni_organic_ppv_cnt, omni_ppv_cnt,

  omni_ads_atc_cnt, omni_organic_atc_cnt, omni_atc_cnt,
  omni_ads_stay_time, omni_organic_stay_time, omni_stay_time,
  omni_ads_order_cnt, omni_organic_order_cnt, omni_order_cnt,
  omni_ads_gmv, omni_organic_gmv, omni_gmv, omni_ads_gmv_usd, omni_organic_gmv_usd, omni_gmv_usd,
  omni_ads_commission_fee, omni_organic_commission_fee, omni_commission_fee,
  omni_ads_commission_fee_usd, omni_organic_commission_fee_usd, omni_commission_fee_usd,
  omni_item_sold_cnt,omni_ads_item_sold_cnt,omni_organic_item_sold_cnt,
  content_live_ads_view_cnt,content_live_ads_view_duration,content_live_ads_item_click_cnt,
  content_live_ads_direct_order_cnt,content_live_ads_broad_order_cnt,
  content_live_ads_direct_item_sold_cnt,content_live_ads_broad_item_sold_cnt,
  content_live_ads_direct_gmv,content_live_ads_broad_gmv,
  content_live_ads_direct_gmv_usd,content_live_ads_broad_gmv_usd,
  ads_revenue_roi2,ads_revenue_usd_roi2
  from 
  (
    select * from ads_performance_base where common_feature != 'Others'
  ) t1
  FULL JOIN
  (
    select * from omni_imp_clk_ppv_atc_order_gmv where common_feature != 'Others'
  ) t2
  ON  t1.user_id = t2.user_id
  AND t1.common_feature = t2.common_feature
  AND t1.app_version <=> t2.app_version
  AND t1.item_id = t2.item_id
  AND t1.location = t2.location
  and t1.shop_id <=> t2.shop_id
) full_table
left join ads_item_flag
on full_table.item_id = ads_item_flag.item_id
and full_table.common_feature = ads_item_flag.common_feature
left join ads_item_type_flag
on full_table.item_id = ads_item_type_flag.item_id
and full_table.common_feature = ads_item_type_flag.common_feature
;