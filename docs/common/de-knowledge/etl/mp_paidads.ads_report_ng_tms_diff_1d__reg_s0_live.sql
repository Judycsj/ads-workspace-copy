-- task_code: data_paidadsmart.studio_7459238  asset_id: 7459238
create external table if not exists ads_report_ng_tms_diff_1d__reg_s0_live
(
    user_id  bigint
    ,ads_entrance  bigint
    ,ads_placement bigint
    ,page_type string
    ,page_section string
    ,target_type string
    ,platform string
    ,app_version string
    ,rn_ver string
    ,entry_point string
    ,traffic_type string
    ,sub_product_type string
    ,product_type string
    ,main_product_type string
    ,feature_detail string
    ,feature_group string
    ,feature string
    ,module string
    ,object string
    ,scenario string
    ,entry_point_total_impression_cnt bigint 
    ,entry_point_total_click_cnt bigint
    ,entry_point_ads_impression_cnt bigint
    ,entry_point_ads_click_cnt bigint
    ,ads_deduplicated_impression_cnt bigint
    ,ads_raw_click_cnt bigint
    ,ads_deduct_click_cnt bigint
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_report_ng_tms_diff_1d'
;

set time zone '${timezone}';

cache table report_ng OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select
    grass_region
    ,user_id
    ,entrance as ads_entrance
    ,placement as ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_version as app_ver
    ,slot_id
    ,ads_id
    ,pricing_type
    ,case when placement = 9 then ifnull (click_before_deduction_cnt, 0) when pricing_type = 20 then ifnull (cps_dedup_click, 0) else ifnull (click_cnt, 0) end as ads_deduct_click
    ,ifnull (impression_cnt, 0)as ads_deduplicated_impression
    ,ifnull (raw_click_cnt, 0) as ads_raw_click
    ,ifnull(cps_dedup_click,0) as cps_dedup_click
from mp_paidads.dwd_advertise_performance_di__reg_s0_live
where
    grass_region = upper('${region}')
    and   grass_date = DATE('${grass_date}')
    -- and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    -- and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
    -- and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
    and ads_id > 0
;

create or replace temporary view report_ng_cpc as
select
    user_id
    ,ads_entrance
    ,ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_ver as app_version
    ,pricing_type
    ,sum(ads_deduct_click) as ads_deduct_click
    ,sum(ads_deduplicated_impression) as ads_deduplicated_impression
    ,sum(ads_raw_click) as ads_raw_click
    ,sum(cps_dedup_click) as cps_dedup_click
from report_ng
where ads_placement not in (9)
group by 1, 2, 3, 4, 5, 6,7,8,9
;

create or replace temporary view report_ng_display as
select
    user_id
    ,ads_entrance
    ,ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_ver
    ,ads_id
    ,pricing_type
    ,sum(ads_deduct_click) as ads_deduct_click
    ,sum(ads_deduplicated_impression) as ads_deduplicated_impression
    ,sum(ads_raw_click) as ads_raw_click
    ,sum(cps_dedup_click) as cps_dedup_click
from report_ng
where ads_placement in (9)
    and slot_id is not null
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
;

create or replace temporary view display_ads as
select
    ads_id
    ,shop_id
    ,budget_start_datetime
    ,budget_end_datetime
from mkplpaidads_data.dim_display_ads__reg_s3_live
where
    grass_date = DATE('${grass_date}')
    and tz_type = 'local'
    and grass_region = upper('${region}')
;

create or replace temporary view display_perf as
select 
    user_id
    ,ads_entrance
    ,ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_ver as app_version
    ,pricing_type
    ,sum(ads_deduct_click) as ads_deduct_click
    ,sum(ads_deduplicated_impression) as ads_deduplicated_impression
    ,sum(ads_raw_click) as ads_raw_click
    ,sum(cps_dedup_click) as cps_dedup_click
from report_ng_display a 
left join display_ads b 
on a.ads_id = b.ads_id
where substr(cast(budget_end_datetime as string), 0, 11) >= DATE('${grass_date}')
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
;

create or replace temporary view tms as
select 
    user_id
    ,platform
    ,rn_version
    ,app_version
    ,search_property.scenario as scenario
    ,page_type
    ,page_section
    ,target_type
    ,module
    ,feature_detail
    ,feature_group
    ,feature
    ,object
    ,case when page_type = 'search' and page_section is null and target_type in ('item', 'video', 'livestream', 'related_search') and (search_property.scenario is null or search_property.scenario not in ('PAGE_SHOP','PAGE_SHOP_SEARCH','PAGE_SHOP_CATEGORY','PAGE_SHOP_CATEGORY_SEARCH')) then 'Global Search'
              when module = 'Image Search' then 'Image Search'
              when feature_group = 'You May Also Like' then 'You May Also Like'
              when feature_detail = 'me-you_may_also_like-item' then 'Me You May Also Like'
              when feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
              when feature = 'mpp_ymal-order_list' then 'My Purchase Page Recommendation'
              when feature = 'odp_ymal-order_detail' then 'Order Detail Page Recommendation'
              when feature_group = 'Cart Recommendation' then 'Cart Recommendation'
              when module = 'Daily Discover' then 'Daily Discover External'
              else 'Undefined'
         end as entry_point 
    ,sum(case when operation = 'impression' then 1 else 0 end) as entry_point_total_impression
    ,sum(case when operation = 'click' then 1 else 0 end) as entry_point_total_click
    ,sum(case when operation = 'impression' and common_property.is_ads = 1 then 1 else 0 end) as entry_point_ads_impression
    ,sum(case when operation = 'click' and common_property.is_ads = 1  then 1 else 0 end) as entry_point_ads_click
from traffic_omni_oa.dwd_scenario_event_log_hi__reg
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and user_id > 0
    and user_id is not null 
    and operation in ('impression', 'click')
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14
;

create or replace temporary view tms_item as
select 
    user_id
    ,platform
    ,rn_version
    ,app_version
    ,search_property.scenario as scenario
    ,page_type
    ,page_section
    ,target_type
    ,module
    ,feature_detail
    ,feature_group
    ,feature
    ,object
    ,case when feature_detail in ('video-mix_feed_page-comment_product-buynow_click',
        'video-mix_feed_page-comment_product-atc_click',
        'video-mix_feed_page-anchor_product-video_product_impression',
        'video-mix_feed_page-comment_product-video_product_click',
        'video-mix_feed_page-anchor_product-buynow_click',
        'video-mix_feed_page-anchor_product-video_product_click',
        'video-mix_feed_page-anchor_product-atc_click',
        'video-mix_feed_page-mix_feed_item_click',
        'video-mix_feed_page-comment_product-video_product_impression') and location_property.location > 0 and source1.feature_detail='home-daily_discover-item_mix_feed_card'
    then 'Daily Discover Mix Feed Internal' 
          when feature_detail = 'shop-you_may_also_like-item' then 'Shop You May Also Like'
          when feature = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
          when feature = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
          when feature_group = 'Video' and video_property.is_ymal_item = 1 then 'Video You May Also Like'
          else 'Undefined' end as entry_point
    ,sum(case when operation = 'impression' then 1 else 0 end) as entry_point_total_impression
    ,sum(case when operation = 'click' then 1 else 0 end) as entry_point_total_click
    ,sum(case when operation = 'impression' and common_property.is_ads = 1 then 1 else 0 end) as entry_point_ads_impression
    ,sum(case when operation = 'click' and common_property.is_ads = 1  then 1 else 0 end) as entry_point_ads_click
from traffic_omni_oa.dwd_item_event_log_hi__reg_sensitive_live
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and user_id > 0
    and user_id is not null 
    and operation in ('impression', 'click')
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14
;

create or replace temporary view traffic_mapping as
select 
entry_point
,entrance
,traffic_type
from mp_paidads.dim_entry_point_mapping_v2
group by 1,2,3
;

create or replace temporary view product_type_mapping as 
select pricing_type
    ,placement
    ,sub_product_type
    ,product_type
    ,main_product_type
from mp_paidads.dim_product_type_mapping__reg_s0_live 
group by 1,2,3,4,5
;


create or replace temporary view tms_all as
select 
    user_id
    ,platform
    ,rn_version
    ,app_version
    ,scenario
    ,page_type
    ,page_section
    ,target_type
    ,module
    ,feature_detail
    ,feature_group
    ,feature
    ,object
    ,a.entry_point as entry_point
    ,COALESCE(traffic_type, 'Undefined') as traffic_type
    ,entry_point_total_impression
    ,entry_point_total_click
    ,entry_point_ads_impression
    ,entry_point_ads_click
from 
(select * from tms_item where entry_point not in ('Undefined')
union all 
select * from tms
union all 
select user_id
    ,platform
    ,rn_version
    ,app_version
    ,scenario
    ,page_type
    ,page_section
    ,target_type
    ,module
    ,feature_detail
    ,feature_group
    ,feature
    ,object
    ,'Shop' as entry_point
    ,entry_point_total_impression
    ,entry_point_total_click
    ,entry_point_ads_impression
    ,entry_point_ads_click 
from tms where entry_point in ('Global Search')
)a 
left join 
(
select 
    entry_point
    ,traffic_type
from traffic_mapping
group by 1,2
)b 
on a.entry_point = b.entry_point
;



create or replace temporary view report_all as
select 
    user_id
    ,ads_entrance
    ,ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_version
    ,entry_point
    ,COALESCE(traffic_type, 'Undefined') as traffic_type
    ,COALESCE(sub_product_type, 'others') as sub_product_type
    ,COALESCE(product_type, 'others') as product_type
    ,COALESCE(main_product_type, 'Others') as main_product_type
    ,sum(ads_deduct_click) as ads_deduct_click
    ,sum(ads_deduplicated_impression) as ads_deduplicated_impression
    ,sum(ads_raw_click) as ads_raw_click
    ,sum(cps_dedup_click) as cps_dedup_click
from 
(select * from report_ng_cpc
union all 
select * from display_perf
)a 
left join traffic_mapping b 
on a.ads_entrance = b.entrance
left join product_type_mapping c 
on a.ads_placement = c.placement
and a.pricing_type = c.pricing_type
group by 1,2,3,4,5,6,7,8,9,10,11,12,13
;



insert overwrite table ads_report_ng_tms_diff_1d__reg_s0_live partition (tz_type='local', grass_region, grass_date)
select 
    user_id
    ,ads_entrance
    ,ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_version
    ,rn_ver
    ,entry_point
    ,traffic_type
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,feature_detail
    ,feature_group
    ,feature
    ,module
    ,object
    ,scenario
    ,sum(entry_point_total_impression) as entry_point_total_impression_cnt
    ,sum(entry_point_total_click) as entry_point_total_click_cnt
    ,sum(entry_point_ads_impression) as entry_point_ads_impression_cnt
    ,sum(entry_point_ads_click) as entry_point_ads_click_cnt
    ,sum(ads_deduplicated_impression) as ads_deduplicated_impression_cnt
    ,sum(ads_raw_click) as ads_raw_click_cnt
    ,sum(ads_deduct_click) as ads_deduct_click_cnt
    ,sum(cps_dedup_click) as cps_dedup_click
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date   
from
(select 
    user_id
    ,ads_entrance
    ,ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,case when platform = 0 then 'unknown'
        when platform = 1 then 'ios_web'
        when platform = 2 then 'ios_app'
        when platform = 3 then 'android_web'
        when platform = 4 then 'android_app'
        when platform = 5 then 'pc_mall'
        when platform = 6 then 'ios_lite'
        when platform = 7 then 'android_lite'
        when platform = 8 then 'platform_reserved'
        when platform = 9 then 'android_app_lite'
        when platform = 99 then 'xiapi'
        when platform = 128 then 'others' end as platform
    ,app_version 
    ,null as rn_ver
    ,entry_point
    ,traffic_type
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,null as feature_detail
    ,null as feature_group
    ,null as feature
    ,null as module
    ,null as object
    ,null as scenario
    ,case when entry_point in ('Game', 'Shop Game','Voucher Master Recommendation ') then ads_deduplicated_impression else 0 end as entry_point_total_impression
    ,case when entry_point in ('Game', 'Shop Game','Voucher Master Recommendation ') then ads_deduct_click else 0 end as entry_point_total_click
    ,case when entry_point in ('Game', 'Shop Game','Voucher Master Recommendation ') then ads_deduplicated_impression else 0 end as entry_point_ads_impression
    ,case when entry_point in ('Game', 'Shop Game','Voucher Master Recommendation ') then ads_deduct_click else 0 end as entry_point_ads_click
    ,ads_deduct_click
    ,ads_deduplicated_impression
    ,ads_raw_click
    ,cps_dedup_click
from report_all 
where traffic_type not in ('Video','Livestream') and main_product_type not in ('Video Ads', 'Live Ads')
union all  
select 
    user_id
    ,null as ads_entrance
    ,null as ads_placement
    ,page_type
    ,page_section
    ,target_type
    ,platform
    ,app_version
    ,rn_version as rn_ver
    ,entry_point
    ,traffic_type
    ,null as sub_product_type
    ,null as product_type
    ,null as main_product_type
    ,feature_detail
    ,feature_group
    ,feature
    ,module
    ,object
    ,scenario
    ,entry_point_total_impression
    ,entry_point_total_click
    ,entry_point_ads_impression
    ,entry_point_ads_click
    ,0 as ads_deduct_click
    ,0 as ads_deduplicated_impression
    ,0 as ads_raw_click
    ,0 as cps_dedup_click
from tms_all 
)t
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
;