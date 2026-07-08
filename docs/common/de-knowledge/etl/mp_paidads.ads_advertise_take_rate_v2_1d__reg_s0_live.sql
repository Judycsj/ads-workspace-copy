-- task_code: data_paidadsmart.studio_6717539  asset_id: 6717539
create external table if not exists ads_advertise_take_rate_v2_1d__reg_s0_live
(
    entry_point string
    ,entry_point_imp bigint
    ,ads_imp bigint
    ,ads_order bigint
    ,ads_click bigint
    ,raw_ads_rev_usd double
    ,ads_rev_usd double
    ,ads_gmv_usd double
    ,platform_imp bigint
    ,platform_gmv double
    ,platform_nmv double
    ,platform_gmv_excl_testorder double
    ,pricing_type int
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_advertise_take_rate_v2_1d'
;

set time zone '${time_zone}';

cache table item_imp 
select 
    grass_region
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
          when feature_detail = 'order_shipping_info-you_may_also_like-item' then 'Shipping Info Page You May Also Like'
          else 'Undefined' end as entry_point
    ,count(1) as entry_point_imp
from traffic_omni_oa.dwd_item_event_log_hi__reg_sensitive_live
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and user_id > 0
    and user_id is not null 
    and operation = 'impression'
group by 1,2
;

create or replace temporary view platform_imp as 
select 
    grass_region
    ,sum(entry_point_imp) as platform_imp
from item_imp
group by 1
;
/*
cache table livestream_imp 
select 
    grass_region
    ,lptab_view_pv_1d
    ,lptab_ads_view_pv_1d
    ,homepage_view_pv_1d
    ,homepage_ads_view_pv_1d
    ,single_view_pv_1d
    ,single_ads_view_pv_1d
    ,autolanding_view_pv_1d
    ,autolanding_ads_view_pv_1d
    ,video_view_pv_1d
    ,video_ads_view_pv_1d
from livestream.ls_mart_ads_app_ls_ad_civ_overview_1d
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
;

--todo 1

create or replace temporary view livestream_pv as
select 
    grass_region
    ,'Livestream Discovery' entry_point
    ,lptab_view_pv_1d as entry_point_imp
    ,lptab_ads_view_pv_1d as ads_imp
from livestream_imp
union all
select 
    grass_region
    ,'Livestream Homepage' entry_point
    ,homepage_view_pv_1d as entry_point_imp
    ,homepage_ads_view_pv_1d as ads_imp
from livestream_imp
union all
select 
    grass_region
    ,'Livestream For You' entry_point
    ,single_view_pv_1d as entry_point_imp
    ,single_ads_view_pv_1d as ads_imp
from livestream_imp
union all
select 
    grass_region
    ,'Livestream Autolanding' entry_point
    ,autolanding_view_pv_1d as entry_point_imp
    ,autolanding_ads_view_pv_1d as ads_imp
from livestream_imp
union all
select 
    grass_region
    ,'Livestream Video Feed' entry_point
    ,video_view_pv_1d as entry_point_imp
    ,video_ads_view_pv_1d as ads_imp
from livestream_imp
;
*/

cache table scenario_event OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select 
    grass_region
    ,search_property.scenario as scenario
    ,page_type
    ,page_section
    ,target_type
    ,module
    ,feature_detail
    ,feature_group
    ,feature
    ,object
from traffic_omni_oa.dwd_scenario_event_log_hi__reg
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
    and user_id > 0
    and user_id is not null 
    and operation = 'impression'
;

cache table  bi_imp OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select 
     grass_region
        ,case when page_type = 'search' and page_section is null and target_type in ('item', 'video', 'livestream', 'related_search') and (scenario is null or scenario not in ('PAGE_SHOP','PAGE_SHOP_SEARCH','PAGE_SHOP_CATEGORY','PAGE_SHOP_CATEGORY_SEARCH')) then 'Global Search'
              when module = 'Image Search' then 'Image Search'
              when feature_group = 'You May Also Like' and target_type not in ('video') then 'You May Also Like' 
              when feature_group = 'You May Also Like' and target_type in ('video') then 'YMAL Video External'
              when feature_detail = 'me-you_may_also_like-item' then 'Me You May Also Like'
              when feature_group = 'Order Successful Recommendation' then 'Order Successful Recommendation'
              when feature = 'mpp_ymal-order_list' then 'My Purchase Page Recommendation'
              when feature = 'odp_ymal-order_detail' then 'Order Detail Page Recommendation'
              when feature_group = 'Cart Recommendation' then 'Cart Recommendation'
              when module = 'Daily Discover' then 'Daily Discover External'
              else 'Undefined'
         end as entry_point
        ,count(1) as entry_point_imp
from scenario_event
group by 1,2
;

create or replace temporary view platform_gmv as
select
    grass_region
    ,cast(sum(gmv_usd) as double) as gmv_usd
    ,cast(sum(nmv_usd) as double) as nmv_usd
    ,sum(case when is_bi_excluded = 0 then gmv_usd else 0 end) as gmv_excl_testorder
from mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and is_placed = 1
    and tz_type = 'local'
group by 1
;


cache table entrance_mapping 
select 
entry_point
,entrance
,traffic_type
from mp_paidads.dim_entry_point_mapping_v2
where (sub_entrance is null or sub_entrance = '')
group by 1,2,3
;

create or replace temporary view traffic_mapping as 
select entry_point
    ,traffic_type 
from entrance_mapping 
group by 1,2
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

create or replace temporary view performance_di as
select 
    a.grass_region as grass_region
    ,shop_id
    ,COALESCE(entry_point,'Undefined') as entry_point
    ,a.pricing_type as pricing_type
    ,COALESCE(sub_product_type,'others') as sub_product_type
    ,COALESCE(product_type,'Others') as product_type
    ,COALESCE(main_product_type,'Others') as main_product_type
    ,sum(raw_click) as raw_click
    ,sum(ads_click) as ads_click
    ,sum(ads_imp) as ads_imp
    ,sum(ads_gmv / exchange_rate) as ads_gmv_usd
    ,sum(ads_order_cnt) as ads_order_cnt
from
(select
    grass_region
    ,shop_id
    ,entrance
    ,case when placement in (45,46) then COALESCE(pricing_type,0) else pricing_type 
        end as pricing_type
    ,sub_entrance
    ,placement
    --,sum(case when pricing_type in (9,10,14,19) then ifnull (raw_click, 0) 
    --        when pricing_type = 20 then ifnull (cps_dedup_click, 0)  else ifnull (click, 0) end) as ads_click
    ,sum(ifnull (raw_click, 0)) as raw_click
    ,sum(case
            when is_ocpm = true then coalesce(deduplicated_click, 0)
            else coalesce(click, 0)
        end) as ads_click
    ,sum(ifnull (impression, 0)) as ads_imp
    ,sum(ifnull (order_gmv, 0) / 100000.0) as ads_gmv
    ,sum(ifnull (order, 0)) as ads_order_cnt
from mp_paidads.ods_log_ads_report_hi__reg_s0_live
where
    grass_region = upper('${region}')
    and   grass_date >= DATE('${grass_date}')
    and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
    and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
    and ads_id > 0
    and (placement != 9 or placement is null)
    and pricing_type!=29
group by 1, 2, 3, 4, 5, 6
)a 
left join 
(
    select  grass_region
        ,exchange_rate
from    mp_order.dim_exchange_rate__reg_s0_live
where     grass_region = upper('${region}')
    and   grass_date = DATE('${grass_date}')
)b 
on a.grass_region = b.grass_region
left join entrance_mapping d 
on a.entrance = d.entrance
left join product_type_mapping c 
on a.placement = c.placement 
and a.pricing_type = c.pricing_type
group by 1,2,3,4,5,6,7
;

cache table net_revenue 
select 
    shop_id 
    ,entrance
    ,case when placement in (45,46) then COALESCE(pricing_type,0) else pricing_type 
        end as pricing_type
    ,placement
    ,grass_region
    ,sum(net_ads_revenue_usd_1d) as net_ads_rev_usd
    ,sum(gross_ads_revenue_usd_1d) as gross_ads_rev_usd
    ,sum(COALESCE(others_free_credit_expired_amt_usd_1d,0.0) + COALESCE(paid_credit_expire_amt_usd_1d,0.0)) as expired_amt_usd
    ,sum(free_ads_revenue_amt_usd_1d) as free_ads_rev_usd
    ,sum(COALESCE(net_ads_revenue_usd_1d,0.0) - COALESCE(sip_free_credit_revenue_usd_1d)) as net_ads_rev_excl_sip_usd_1d
    ,COALESCE(sum(sip_free_credit_revenue_usd_1d),0.0) as sip_free_credit_revenue_usd_1d
from mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
where grass_date = date('${grass_date}')
and grass_region = upper('${region}')
and tz_type = 'local'
group by 1,2,3,4,5
;

create or replace temporary view deduction_di as
select 
    grass_region
    ,shop_id
    ,entrance
    ,case when placement in (45,46) then COALESCE(pricing_type,0) else pricing_type 
        end as pricing_type
    ,placement
    ,sum(deduction_amt_usd) as deduction_amt_usd
from    mp_paidads.dwd_advertiser_deduction_di__reg_s0_live
where   grass_region = upper('${region}')
    and grass_date = date('${grass_date}')
    and ads_id > 0
group by 1,2,3,4,5
;


create or replace temporary view deduction_amt as
select 
    grass_region
    ,shop_id
    ,t.pricing_type as pricing_type
    ,COALESCE(entry_point, 'Undefined') as entry_point
    ,COALESCE(sub_product_type,'others') as sub_product_type
    ,COALESCE(product_type,'Others') as product_type
    ,COALESCE(main_product_type,'Others') as main_product_type
    ,sum(ads_rev_usd) as ads_rev_usd
    ,sum(net_ads_rev_usd) as net_ads_rev_usd
    ,sum(gross_ads_rev_usd) as gross_ads_rev_usd
    ,sum(expired_amt_usd) as expired_amt_usd
    ,sum(free_ads_rev_usd) as free_ads_rev_usd
    ,sum(net_ads_rev_excl_sip_usd_1d) as net_ads_rev_excl_sip_usd_1d
    ,sum(sip_free_credit_revenue_usd_1d) as sip_free_credit_revenue_usd_1d
from 
(select  coalesce(a.grass_region,b.grass_region) as grass_region
    ,coalesce(a.shop_id,b.shop_id) as shop_id
    ,coalesce(a.pricing_type,b.pricing_type) as pricing_type
    ,coalesce(a.entrance,b.entrance) as entrance
    ,coalesce(a.placement,b.placement) as placement
    ,deduction_amt_usd as ads_rev_usd
    ,net_ads_rev_usd
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
from    deduction_di a
full join (select * from net_revenue where entrance <> 6 or entrance is null) b 
on a.shop_id = b.shop_id 
and a.pricing_type <=> b.pricing_type
and a.entrance <=> b.entrance
and a.placement <=> b.placement
)t 
left join entrance_mapping c 
on t.entrance = c.entrance
left join product_type_mapping c 
on t.placement = c.placement 
and t.pricing_type = c.pricing_type
group by 1,2,3,4,5,6,7
;



create or replace temporary view ads_performance as
select
    coalesce(a.shop_id,b.shop_id)  as shop_id
    ,coalesce(a.entry_point,b.entry_point, 'Undefined')  as entry_point
    ,coalesce(a.grass_region,b.grass_region)  as grass_region
    ,coalesce(a.pricing_type,b.pricing_type)  as pricing_type
    ,coalesce(a.sub_product_type,b.sub_product_type)  as sub_product_type
    ,coalesce(a.product_type,b.product_type)  as product_type
    ,coalesce(a.main_product_type,b.main_product_type)  as main_product_type
    ,ifnull(ads_rev_usd, 0) as ads_rev_usd
    ,ifnull(raw_click, 0) as raw_click
    ,ifnull(ads_click, 0) as ads_click
    ,ifnull(ads_imp, 0) as ads_imp
    ,ifnull(ads_gmv_usd, 0) as ads_gmv_usd
    ,ifnull(ads_order_cnt, 0) as ads_order_cnt
    ,ifnull(net_ads_rev_usd, 0) as net_ads_rev_usd
    ,ifnull(gross_ads_rev_usd, 0) as gross_ads_rev_usd
    ,ifnull(expired_amt_usd, 0) as expired_amt_usd
    ,ifnull(free_ads_rev_usd, 0) as free_ads_rev_usd
    ,ifnull(net_ads_rev_excl_sip_usd_1d, 0) as net_ads_rev_excl_sip_usd_1d
    ,ifnull(sip_free_credit_revenue_usd_1d, 0) as sip_free_credit_revenue_usd_1d
from
    performance_di a
full join deduction_amt b
    on a.shop_id <=> b.shop_id
    and a.entry_point <=> b.entry_point
    and a.pricing_type <=> b.pricing_type
    and a.sub_product_type <=> b.sub_product_type
    and a.product_type <=> b.product_type
    and a.main_product_type <=> b.main_product_type
;

create or replace temporary view tax as
select 
    grass_region
    ,max(case when metric_type = 'cb_paid_ads_revenue' then vat_rate else 0.0 end) as cb_tax
    ,max(case when metric_type = 'local_paid_ads_revenue' then vat_rate else 0.0 end) as local_tax
from regbida_keyreports.dim_vat_rate 
where grass_region = upper('${region}')
and grass_date in (select max(grass_date) as grass_date from regbida_keyreports.dim_vat_rate where grass_region = upper('${region}'))
and metric_type in ('cb_paid_ads_revenue', 'local_paid_ads_revenue') 
group by 1;

create or replace temporary view dim_shop as
select
    shop_id
    ,is_cb_seller as is_cb_shop
    ,seller_type_1p
    ,seller_type
from mp_paidads.dim_advertiser__reg_s0_live
where
    grass_date = data_infra.max_pt('mp_paidads.dim_advertiser__reg_s0_live','grass_date','grass_region = "${upper_region}"')
    and grass_region = upper('${region}')
    and tz_type = 'local'
;

create or replace temporary view ads_vat as
select
    *
    ,raw_ads_rev_usd / (1 + tax_rate) as ads_rev_usd
from
    (
        select
            a.shop_id as shop_id
            ,a.grass_region as grass_region
            ,a.entry_point as entry_point
            ,pricing_type
            ,sub_product_type
            ,product_type
            ,main_product_type
            ,case
                when is_cb_shop = 1 then cb_tax
                else local_tax
            end as tax_rate
            ,is_cb_shop
            ,ads_rev_usd as raw_ads_rev_usd
            ,raw_click
            ,ads_click
            ,ads_imp
            ,ads_gmv_usd
            ,ads_order_cnt as ads_order
            ,seller_type_1p
            ,net_ads_rev_usd
            ,gross_ads_rev_usd
            ,expired_amt_usd
            ,free_ads_rev_usd
            ,net_ads_rev_excl_sip_usd_1d
            ,sip_free_credit_revenue_usd_1d
        from
            ads_performance a
            left join dim_shop b 
            on a.shop_id = b.shop_id
            left join tax c 
            on a.grass_region = c.grass_region
    ) t
;

create or replace temporary view video_vv as 
select 
    grass_region
    ,case when sv_source_page = 'iaa_dd_video_card' and current_page in ('common_video_feed_page','dd_video_new_landing_page') and video_flow_type = 'internal' and content_type = 'shopee_video' then 'DD Internal Video'
        when sv_source_page = 'home_video_module' and current_page = 'common_video_trending_page' and video_flow_type = 'internal' then 'HP Internal Video'
        when sv_source_page = 'video_tab' and current_page = 'trending_page' then 'Video Trending Tab' 
        when sv_source_page = 'iaa_srp_video_card' and current_page = 'common_video_feed_page' and video_flow_type = 'internal' then 'SRP Internal Video'
        when sv_source_page = 'iaa_dd_mix_item' and current_page = 'mix_feed_page' and content_type = 'shopee_video' and video_flow_type = 'internal' then 'Daily Discover Mix Feed Video Internal'
        when sv_source_page = 'iaa_ymal_video_card' and current_page = 'common_video_feed_page' and content_type = 'shopee_video' and video_flow_type = 'internal' then 'YMAL_FEED_VIDEO_ADS'
        else 'Undefined'
    end as entry_point
    ,ads_id
    ,sum(case when is_item_ads = 1 or video_ads_type in ('product_ads','video_ads') then video_play_cnt_ntl_1d else 0 end) as ads_imp
    ,sum(video_play_cnt_ntl_1d) as entry_point_imp
from video.video_mart_dws_user_watch_basic_aggr_1d
where grass_region = upper('${region}')
    and grass_date = date('${grass_date}')
    and tz_type = 'local'
    and video_play_cnt_ntl_1d > 0
group by 1,2,3
;

create or replace temporary view video_ep_imp as 
select 
    entry_point
    ,grass_region
    ,sum(entry_point_imp) as entry_point_imp
from video_vv
where entry_point not in ('Undefined')
group by 1,2
;

create or replace temporary view dim_advertise as 
select
    ads_id
    ,max(main_product_type) as main_product_type
    ,max(product_type) as product_type
    ,max(sub_product_type) as sub_product_type
    ,max(pricing_type) as pricing_type
from mp_paidads.dim_advertise__reg_s0_live
where
    grass_region = upper('${region}')
    and grass_date = date('${grass_date}')
    and tz_type = 'local'
group by 1
;

create or replace temporary view video_ads_imp as 
select 
    entry_point
    ,grass_region
    ,main_product_type
    ,product_type
    ,sub_product_type
    ,pricing_type
    ,sum(ads_imp) as ads_imp
from (select * from video_vv where ads_imp > 0 and entry_point not in ('Undefined')) a 
left join dim_advertise b 
on a.ads_id = b.ads_id
group by 1,2,3,4,5,6
;

create or replace temporary view display_ads_metrics as
select 
    grass_region
    ,shop_id
    ,entry_point
    ,t.pricing_type as pricing_type
    ,COALESCE(sub_product_type,'others') as sub_product_type
    ,COALESCE(product_type,'Others') as product_type
    ,COALESCE(main_product_type,'Others') as main_product_type
    ,ads_imp
    ,ads_order
    ,ads_click
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_gmv_usd
    ,net_ads_rev_usd
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
from
(select 
    coalesce(a.grass_region,b.grass_region) as grass_region
    ,coalesce(a.shop_id, b.shop_id) as shop_id
    ,'Display' as entry_point
    ,coalesce(a.pricing_type,b.pricing_type) as pricing_type
    ,coalesce(a.placement,b.placement) as placement
    ,ads_imp
    ,ads_order
    ,ads_click
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_gmv_usd
    ,net_ads_rev_usd
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
from
(select
    grass_region
    ,shop_id
    ,pricing_type
    ,placement
    ,sum(impression_cnt) as ads_imp
    ,null as ads_order
    ,sum(click_cnt) as ads_click
    ,sum(expense_amt_usd / 1000.0) as raw_ads_rev_usd
    ,sum(expense_amt_usd / 1000.0) as ads_rev_usd
    ,null as ads_gmv_usd
from mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live
where grass_date = date('${grass_date}')
and grass_region = upper('${region}')
and tz_type = 'local'
group by 1, 2, 3, 4
)a 
full join 
(
    select * from net_revenue where entrance = 6
)b 
on a.shop_id = b.shop_id
and a.pricing_type <=> b.pricing_type
and a.placement <=> b.placement
)t
left join product_type_mapping c 
on t.placement = c.placement 
and t.pricing_type = c.pricing_type
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


cache table ads_base
select 
    grass_region
    ,a.entry_point as entry_point
    ,a.pricing_type as pricing_type
    ,is_cb_shop 
    ,seller_type_1p
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,seller_type
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,sum(raw_ads_rev_usd) as raw_ads_rev_usd
    ,sum(ads_rev_usd) as ads_rev_usd
    --,sum(ads_click) as ads_click
    --,sum(case when traffic_type in ('Video', 'Livestream') or main_product_type in ('Video Ads', 'Live Ads') or a.entry_point in ('Daily Discover Mix Feed Video Internal','YMAL_FEED_VIDEO_ADS','DD Internal Video') then 0 else ads_imp end) as ads_imp
    ,sum(case when traffic_type= 'Livestream' and main_product_type='Live Ads' then raw_click --mingtou
            when traffic_type= 'Livestream' and main_product_type!='Live Ads' then 0 --antou
            else ads_click end) as ads_click

    ,sum(case when traffic_type in ('Video') or main_product_type in ('Video Ads') or a.entry_point in ('Daily Discover Mix Feed Video Internal','YMAL_FEED_VIDEO_ADS','DD Internal Video') then 0 
            when traffic_type= 'Livestream' and main_product_type='Live Ads' then ads_imp 
            when traffic_type= 'Livestream' and main_product_type!='Live Ads' then 0 
            else ads_imp end) as ads_imp
    ,sum(ads_gmv_usd) as ads_gmv_usd
    ,sum(ads_order) as ads_order
    ,sum(net_ads_rev_usd) as net_ads_rev_usd
    ,sum(gross_ads_rev_usd) as gross_ads_rev_usd
    ,sum(expired_amt_usd) as expired_amt_usd
    ,sum(free_ads_rev_usd) as free_ads_rev_usd
    ,sum(net_ads_rev_excl_sip_usd_1d) as net_ads_rev_excl_sip_usd_1d
    ,sum(sip_free_credit_revenue_usd_1d) as sip_free_credit_revenue_usd_1d
from
(select
    grass_region
    ,entry_point
    ,pricing_type
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,shop_id
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,raw_click
    ,ads_click
    ,ads_imp
    ,ads_gmv_usd
    ,ads_order
    ,net_ads_rev_usd
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
from ads_vat 
union all 
select
    grass_region
    ,entry_point
    ,pricing_type
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,shop_id
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_click as raw_click
    ,ads_click
    ,ads_imp
    ,ads_gmv_usd
    ,ads_order
    ,net_ads_rev_usd
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
from display_ads_metrics 
)a
left join dim_shop b 
on a.shop_id = b.shop_id 
left join dim_shop_ext c 
on a.shop_id = c.shop_id 
left join traffic_mapping d 
on a.entry_point = d.entry_point
group by 1,2,3,4,5,6,7,8,9,10,11
;

create or replace temporary view dim_voucher as 
select 
    promotion_id
from mp_voucher.dim_voucher__reg_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
AND is_seller_voucher = 1 
-- and voucher_status_id = 1
and array_contains(voucher_groups,'ADS-ROI')
;

cache table net_order OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select 
    grass_region
    ,order_id
    ,a.promotion_id as promotion_id
    ,item_id
    ,net_sv_rebate_by_shopee_amt
    ,net_sv_rebate_by_shopee_amt_usd
from 
(select 
    grass_region
    , order_id
    , sv_promotion_id as promotion_id
    , item_id
    , sum(net_sv_rebate_by_shopee_amt) as net_sv_rebate_by_shopee_amt
    , sum(net_sv_rebate_by_shopee_amt_usd) as net_sv_rebate_by_shopee_amt_usd
    from mp_order.dwd_order_item_all_ent_df
where grass_date >= date('${grass_date}') and grass_region = upper('${region}') and tz_type = 'local'
and date(create_datetime) = date('${grass_date}')
and net_sv_rebate_by_shopee_amt > 0
group by 1,2,3,4
)a
join dim_voucher b 
on a.promotion_id = b.promotion_id
;

create or replace temporary view ads_order as 
select 
    grass_region
    ,order_id
    ,origin_item_id as item_id
    ,promotion_id
    ,COALESCE(entry_point,'Undefined') as entry_point
    ,COALESCE(traffic_type, 'Undefined') as traffic_type
    ,a.pricing_type as pricing_type
    ,COALESCE(sub_product_type,'others') as sub_product_type
    ,COALESCE(product_type,'Others') as product_type
    ,COALESCE(main_product_type,'Others') as main_product_type
    ,is_cb_shop 
    ,seller_type_1p
    ,seller_type
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
from
(select 
    grass_region
    ,shop_id
    ,entrance
    ,placement
    ,pricing_type
    ,order_id
    ,origin_item_id
    ,voucher_detail.promotion_id as promotion_id
from mp_paidads.dwd_advertise_performance_di__reg_s0_live 
LATERAL VIEW explode(from_json(voucher_details_json,'array<struct<promotion_id:bigint,voucher_code:string,groups:array<string>,reward_discount:bigint>>')) tmp AS voucher_detail
where grass_date = date('${grass_date}')
and grass_region = upper('${region}') and tz_type = 'local'
and pricing_type!=29
and size(from_json(voucher_details_json,'array<struct<promotion_id:bigint,voucher_code:string,groups:array<string>,reward_discount:bigint>>')) > 0 and (broad_order_cnt > 0 or broad_gmv_amt_local > 0)
group by 1,2,3,4,5,6,7,8
)a 
left join entrance_mapping b 
on a.entrance = b.entrance
left join product_type_mapping c 
on a.placement = c.placement 
and a.pricing_type = c.pricing_type
left join dim_shop d 
on a.shop_id = d.shop_id 
left join dim_shop_ext e 
on a.shop_id = e.shop_id
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;

create or replace temporary view ads_voucher as 
select 
    a.grass_region as grass_region
    ,entry_point
    ,traffic_type
    ,pricing_type
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,is_cb_shop 
    ,seller_type_1p
    ,seller_type
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,sum(net_sv_rebate_by_shopee_amt) as ads_voucher_ads_nmv_cost
    ,sum(net_sv_rebate_by_shopee_amt_usd) as ads_voucher_ads_nmv_cost_usd
from ads_order a 
join net_order b 
on a.item_id = b.item_id
and a.order_id = b.order_id 
and a.promotion_id = b.promotion_id
and a.grass_region = b.grass_region
group by 1,2,3,4,5,6,7,8,9,10,11,12
;

create or replace temporary view all_ads_metrics as
select
    grass_region
    ,entry_point
    ,pricing_type
    ,is_cb_shop 
    ,seller_type_1p
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,seller_type
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,sum(raw_ads_rev_usd) as raw_ads_rev_usd
    ,sum(ads_rev_usd) as ads_rev_usd
    ,sum(ads_click) as ads_click
    ,sum(ads_imp) as ads_imp
    ,sum(ads_gmv_usd) as ads_gmv_usd
    ,sum(ads_order) as ads_order
    ,sum(net_ads_rev_usd) as net_ads_rev_usd
    ,sum(gross_ads_rev_usd) as gross_ads_rev_usd
    ,sum(expired_amt_usd) as expired_amt_usd
    ,sum(free_ads_rev_usd) as free_ads_rev_usd
    ,sum(net_ads_rev_excl_sip_usd_1d) as net_ads_rev_excl_sip_usd_1d
    ,sum(sip_free_credit_revenue_usd_1d) as sip_free_credit_revenue_usd_1d
    ,sum(ads_voucher_ads_nmv_cost) as ads_voucher_ads_nmv_cost
    ,sum(ads_voucher_ads_nmv_cost_usd) as ads_voucher_ads_nmv_cost_usd
from
(select
    grass_region
    ,entry_point
    ,pricing_type
    ,is_cb_shop 
    ,seller_type_1p
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,seller_type
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_click
    ,ads_imp
    ,ads_gmv_usd
    ,ads_order
    ,net_ads_rev_usd
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
    ,0 as ads_voucher_ads_nmv_cost
    ,0 as ads_voucher_ads_nmv_cost_usd
from ads_base
union all 
/*
select
    grass_region
    ,entry_point
    ,null as pricing_type
    ,null as is_cb_shop
    ,null as seller_type_1p
    ,null as sub_product_type
    ,null as product_type
    ,null as main_product_type
    ,null as seller_type
    ,null as is_cb_sip_affiliated
    ,null as is_local_sip_affiliated
    ,0 as raw_ads_rev_usd
    ,0 as ads_rev_usd
    ,0 as ads_click
    ,ads_imp
    ,0 as ads_gmv_usd
    ,0 as ads_order
    ,0 as net_ads_rev_usd
    ,0 as gross_ads_rev_usd
    ,0 as expired_amt_usd
    ,0 as free_ads_rev_usd
    ,0 as net_ads_rev_excl_sip_usd_1d
    ,0 as sip_free_credit_revenue_usd_1d
    ,0 as ads_voucher_ads_nmv_cost
    ,0 as ads_voucher_ads_nmv_cost_usd
from livestream_pv
union all 
*/
select
    grass_region
    ,entry_point
    ,pricing_type
    ,null as is_cb_shop
    ,null as seller_type_1p
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,null as seller_type
    ,null as is_cb_sip_affiliated
    ,null as is_local_sip_affiliated
    ,0 as raw_ads_rev_usd
    ,0 as ads_rev_usd
    ,0 as ads_click
    ,ads_imp
    ,0 as ads_gmv_usd
    ,0 as ads_order
    ,0 as net_ads_rev_usd
    ,0 as gross_ads_rev_usd
    ,0 as expired_amt_usd
    ,0 as free_ads_rev_usd
    ,0 as net_ads_rev_excl_sip_usd_1d
    ,0 as sip_free_credit_revenue_usd_1d
    ,0 as ads_voucher_ads_nmv_cost
    ,0 as ads_voucher_ads_nmv_cost_usd
from video_ads_imp
union all 
select
    grass_region
    ,entry_point
    ,pricing_type
    ,is_cb_shop 
    ,seller_type_1p
    ,sub_product_type
    ,product_type
    ,main_product_type
    ,seller_type
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,0 as raw_ads_rev_usd
    ,0 as ads_rev_usd
    ,0 as ads_click
    ,0 as ads_imp
    ,0 as ads_gmv_usd
    ,0 as ads_order
    ,0 as net_ads_rev_usd
    ,0 as gross_ads_rev_usd
    ,0 as xpired_amt_usd
    ,0 as ree_ads_rev_usd
    ,0 as net_ads_rev_excl_sip_usd_1d
    ,0 as ip_free_credit_revenue_usd_1d
    ,ads_voucher_ads_nmv_cost
    ,ads_voucher_ads_nmv_cost_usd
from ads_voucher
)t 
group by 1,2,3,4,5,6,7,8,9,10,11
;

create or replace temporary view entry_point_imp as
select  grass_region
    ,entry_point
    ,sum(entry_point_imp) as entry_point_imp
from    bi_imp
group by 1, 2
union all
select 
    grass_region
    ,entry_point
    ,sum(ads_imp) as entry_point_imp
from ads_base
where entry_point in ('Game', 'Shop Game','Voucher Master Recommendation ')
group by 1,2
union all
select 
    grass_region
    ,entry_point
    ,entry_point_imp
from item_imp
where entry_point not in ('Undefined')
union all
/*
select 
    grass_region
    ,entry_point
    ,entry_point_imp
from livestream_pv
union all
*/
select 
    grass_region
    ,entry_point
    ,entry_point_imp
from video_ep_imp
union all 
select 
    grass_region
    ,'Shop' as entry_point
    ,sum(entry_point_imp) as entry_point_imp
from bi_imp
where entry_point in ('Global Search')
group by 1,2
;

create or replace temporary view nmv as 
select 
    grass_region
    ,sum(antifraud_gmv_usd * first_touchpoint_item * atc_prorate) as platform_antifraud_gmv_usd
    ,sum(antifraud_gmv * first_touchpoint_item * atc_prorate) as platform_antifraud_gmv
    ,sum(antifraud_order_fraction * first_touchpoint_item * atc_prorate) as platform_antifraud_order_fraction
    --old
    ,sum(pay_gmv_usd * first_touchpoint_item * atc_prorate) as platform_paid_gmv_usd
    ,sum(pay_gmv * first_touchpoint_item * atc_prorate) as platform_paid_gmv
    ,sum(pay_order_fraction * first_touchpoint_item * atc_prorate) as platform_paid_order_fraction
    --new cod confirmed
    ,sum(case when is_cod=1 then confirm_gmv_usd * first_touchpoint_item * atc_prorate
           else  pay_gmv_usd * first_touchpoint_item * atc_prorate end) as platform_paid_with_confirmed_cod_gmv_usd
    ,sum(case when is_cod=1 then confirm_gmv * first_touchpoint_item * atc_prorate
           else pay_gmv  * first_touchpoint_item * atc_prorate end) as platform_paid_with_confirmed_cod_gmv
    ,sum(case when is_cod=1 then confirm_order_fraction * first_touchpoint_item * atc_prorate
           else pay_order_fraction * first_touchpoint_item * atc_prorate end) as platform_paid_order_with_confirmed_cod_fraction
    --new cod placed
    ,sum(case when is_cod=1 then gmv_usd * first_touchpoint_item * atc_prorate
           else pay_gmv_usd  * first_touchpoint_item * atc_prorate end) as platform_paid_with_placed_cod_gmv_usd
    ,sum(case when is_cod=1 then gmv * first_touchpoint_item * atc_prorate
           else pay_gmv  * first_touchpoint_item * atc_prorate end) as platform_paid_with_placed_cod_gmv
    ,sum(case when is_cod=1 then order_fraction * first_touchpoint_item * atc_prorate
           else pay_order_fraction  * first_touchpoint_item * atc_prorate end) as platform_paid_order_with_placed_cod_fraction 

    ,sum(confirm_gmv_usd * first_touchpoint_item * atc_prorate) as platform_confirmed_gmv_usd
    ,sum(confirm_gmv * first_touchpoint_item * atc_prorate) as platform_confirmed_gmv
    ,sum(confirm_order_fraction * first_touchpoint_item * atc_prorate) as platform_confirmed_order_fraction

    ,sum(complete_gmv_usd * first_touchpoint_item * atc_prorate) as platform_complete_gmv_usd
    ,sum(complete_gmv * first_touchpoint_item * atc_prorate) as platform_complete_gmv
    ,sum(complete_order_fraction * first_touchpoint_item * atc_prorate) as platform_complete_order_fraction
    ,sum(cancel_gmv_usd * first_touchpoint_item * atc_prorate) as platform_cancel_gmv_usd
    ,sum(cancel_gmv * first_touchpoint_item * atc_prorate) as platform_cancel_gmv
    ,sum(cancel_order_fraction * first_touchpoint_item * atc_prorate) as platform_cancel_order_fraction
    ,sum(return_gmv_usd * first_touchpoint_item * atc_prorate) as platform_return_gmv_usd
    ,sum(return_gmv * first_touchpoint_item * atc_prorate) as platform_return_gmv
    ,sum(return_order_fraction * first_touchpoint_item * atc_prorate) as platform_return_order_fraction
    ,sum(case when is_net_order = 1 then order_fraction * first_touchpoint_item * atc_prorate else 0 end) as platform_net_order_fraction
    ,sum(nmv * first_touchpoint_item * atc_prorate) as omni_platform_nmv
    ,sum(nmv_usd * first_touchpoint_item * atc_prorate) as omni_platform_nmv_usd
from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg
where  grass_date = date('${grass_date}')
and grass_region = upper('${region}')
and tz_type = 'local'
group by 1
;


create or replace temporary view net_voucher as 
select 
    grass_region
    ,sum(net_sv_rebate_by_shopee_amt) as ads_voucher_omni_platform_nmv_cost
    ,sum(net_sv_rebate_by_shopee_amt_usd) as ads_voucher_omni_platform_nmv_cost_usd
from net_order
group by 1
;

create or replace temporary view livestream_imp as 
select 
    grass_region,
    live_total_entry_point_imp,
    live_total_ads_imp
from mp_paidads.ads_take_rate_livestream_performance_1d__reg_s0_live
where  grass_date = date('${grass_date}')
and grass_region = upper('${region}')
and tz_type = 'local'
;

create or replace temporary view ads_voucher_info as 
select a.grass_region,
    sum(ads_voucher_ads_part_amt_usd) as ads_voucher_ads_part_amt_usd,
    sum(ads_voucher_ads_part_amt_usd* exchange_rate ) as ads_voucher_ads_part_amt
from
(
    select 
        grass_region
        ,ads_voucher_amt_usd * (1-coalesce(voucher_cofund_ratio,0)) as ads_voucher_ads_part_amt_usd
    from mp_paidads.ads_order_voucher_1d__reg_s0_live
    where  grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
)a
left join 
(
    select  grass_region
        ,exchange_rate
from    mp_order.dim_exchange_rate__reg_s0_live
where     grass_region = upper('${region}')
    and   grass_date = DATE('${grass_date}')
)b 
on a.grass_region = b.grass_region
group by 1
;



cache table output OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select
    coalesce(b.entry_point, a.entry_point) as entry_point
    ,entry_point_imp
    ,ads_imp
    ,ads_order
    ,ads_click
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_gmv_usd
    ,platform_imp
    ,gmv_usd as platform_gmv
    ,nmv_usd as platform_nmv
    ,gmv_excl_testorder as platform_gmv_excl_testorder
    ,a.pricing_type as pricing_type
    ,is_cb_shop 
    ,seller_type_1p
    ,net_ads_rev_usd
    ,COALESCE(traffic_type, 'Undefined') as traffic_type
    ,COALESCE(sub_product_type, 'others') as sub_product_type
    ,COALESCE(product_type, 'others') as product_type
    ,COALESCE(main_product_type, 'Others') as main_product_type
    ,COALESCE(seller_type, 'Unknown') as seller_type
    ,gross_ads_rev_usd
    ,expired_amt_usd
    ,free_ads_rev_usd
    ,net_ads_rev_excl_sip_usd_1d
    ,sip_free_credit_revenue_usd_1d
    ,is_cb_sip_affiliated
    ,is_local_sip_affiliated
    ,platform_antifraud_gmv_usd
    ,platform_antifraud_gmv
    ,platform_antifraud_order_fraction
    ,platform_paid_gmv_usd
    ,platform_paid_gmv
    ,platform_paid_order_fraction
    ,platform_confirmed_gmv_usd
    ,platform_confirmed_gmv
    ,platform_confirmed_order_fraction
    ,platform_complete_gmv_usd
    ,platform_complete_gmv
    ,platform_complete_order_fraction
    ,platform_cancel_gmv_usd
    ,platform_cancel_gmv
    ,platform_cancel_order_fraction
    ,platform_return_gmv_usd
    ,platform_return_gmv
    ,platform_return_order_fraction
    ,platform_net_order_fraction
    ,omni_platform_nmv
    ,omni_platform_nmv_usd
    ,ads_voucher_omni_platform_nmv_cost
    ,ads_voucher_omni_platform_nmv_cost_usd
    ,ads_voucher_ads_nmv_cost
    ,ads_voucher_ads_nmv_cost_usd
    
    ,platform_paid_with_confirmed_cod_gmv_usd
    ,platform_paid_with_confirmed_cod_gmv
    ,platform_paid_order_with_confirmed_cod_fraction
    
    ,platform_paid_with_placed_cod_gmv_usd
    ,platform_paid_with_placed_cod_gmv
    ,platform_paid_order_with_placed_cod_fraction 

    ,live_total_entry_point_imp
    ,live_total_ads_imp
    ,ads_voucher_ads_part_amt_usd
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date   
from
    all_ads_metrics a
full outer join entry_point_imp b
    on a.grass_region = b.grass_region
    and a.entry_point = b.entry_point
left join platform_imp c
    on a.grass_region = c.grass_region
    or b.grass_region = c.grass_region  
left join platform_gmv d
    on a.grass_region = d.grass_region
    or b.grass_region = d.grass_region
left join traffic_mapping e 
on coalesce(a.entry_point,b.entry_point) = e.entry_point
left join nmv f 
on coalesce(a.grass_region,b.grass_region) = f.grass_region
left join net_voucher g 
on coalesce(a.grass_region,b.grass_region) = g.grass_region
left join livestream_imp h
on coalesce(a.grass_region,b.grass_region) = h.grass_region
left join ads_voucher_info i 
on coalesce(a.grass_region,b.grass_region) = i.grass_region
;

insert overwrite table ads_advertise_take_rate_v2_1d__reg_s0_live partition (tz_type='local', grass_region, grass_date)
select
    *
from output 
;