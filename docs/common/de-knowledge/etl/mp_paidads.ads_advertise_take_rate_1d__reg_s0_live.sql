create external table if not exists ads_advertise_take_rate_1d__reg_s0_live
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
)
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_advertise_take_rate_1d'
;

create or replace temporary view page_mapping as
select scenario_key
    , mapped_page_type
from mp_foa.dim_search_domain_map__reg_live
where grass_date in (select max(grass_date) as grass_date from mp_foa.dim_search_domain_map__reg_live where grass_region = upper('${region}'))
  and   grass_region = upper('${region}')
group by 1,2
;

create or replace temporary view feature_mapping as
select feature_detail
    ,feature_group as step1_feature_group
    ,feature as step1_feature
from mp_foa.dim_feature_map__reg_s0_live
where grass_date in (select max(grass_date) as grass_date from mp_foa.dim_feature_map__reg_s0_live where grass_region = upper('${region}'))
  and   grass_region = upper('${region}')
group by 1,2,3
;

create or replace temporary view omimi_mapping as
select
        mapped_page_type
        ,page_section
        ,target_type
        ,reporting_business_line
        ,reporting_module
    from traffic_omni_oa.dim_atlas_feature_business_details_map__reg_live
    where grass_date = date('${grass_date}')
    and  operation = 'impression' and page_section != '*'
    group by 1,2,3,4,5
;

create or replace temporary view omimi_mapping_1 as
select
        mapped_page_type
        ,target_type
        ,reporting_business_line
        ,reporting_module
    from traffic_omni_oa.dim_atlas_feature_business_details_map__reg_live
    where grass_date = date('${grass_date}')
    and  operation = 'impression' and page_section = '*'
    group by 1,2,3,4
;

cache table  bi_imp OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select
     grass_region
        ,case when rs.target_type = 'item' and step1_feature_group = 'Search' and step1_feature_detail in ('global_search-item', 'search_in_pdp-item', 'search_in_subcategory-item', 'search_in_mall-item','search-item') then 'Search'
              when rs.target_type = 'item' and step1_feature_group = 'Search' and step1_feature_detail in ('image_search-item','image_search-original_item-item','image_search-rcmd-item','image_search-search-item') then 'Image Search'
              when rs.target_type = 'item' and step1_feature_group = 'Search' then 'Search Others'
              when rs.target_type = 'item' and step1_feature_group = 'You May Also Like' and bnd_recommendation_section = 'product_detail_page' then 'You May Also Like'
              when rs.target_type = 'item' and step1_feature_detail = 'me-you_may_also_like-item' then 'Me You May Also Like'
              when rs.target_type = 'item' and step1_feature_group = 'You May Also Like' then 'You May Also Like Others'
              when rs.target_type = 'item' and step1_feature_group = 'Rcmd Others' and step1_feature_detail = 'order_list-you_may_also_like-item' then 'My Purchase Page Recommendation'
              when rs.target_type = 'item' and step1_feature_group = 'Rcmd Others' and step1_feature_detail = 'order_detail-you_may_also_like-item' then 'Order Detail Page Recommendation'
              when rs.target_type = 'item' and step1_feature_group = 'Live Streaming' and step1_feature_detail in ('streaming_room-display_window-item','streaming_room-related_product_list-item') then 'Livestream Streaming Room'
              when rs.target_type = 'item' and step1_feature_group = 'Live Streaming' then 'Livestream Others'
              when (coalesce(omini.reporting_business_line,omini_1.reporting_business_line) = 'Homepage' and coalesce(omini.reporting_module,omini_1.reporting_module) = 'Daily Discover') or (mini_feed_tag in ('video-mix_feed_page-anchor_product-atc_click','video-mix_feed_page-anchor_product-buynow_click','video-mix_feed_page-anchor_product-video_product_click','video-mix_feed_page-anchor_product-video_product_impression','video-mix_feed_page-comment_product-video_product_impression','video-mix_feed_page-mix_feed_item_click')) then 'Daily Discover'
              when rs.target_type = 'item' and step1_feature_group != 'Daily Discover' then step1_feature_group
              else 'exclued'
         end as entry_point
        ,sum(cnt) as entry_point_imp
from
(		select
             CASE
                WHEN CONCAT_WS('-',  COALESCE(mapped_page_type, page_type), page_section, target_type) = '' THEN NULL
                ELSE CONCAT_WS('-',  COALESCE(mapped_page_type, page_type), page_section, target_type)
            END AS step1_feature_detail
            ,grass_region
            ,bnd_recommendation_section
            ,COALESCE(mapped_page_type, page_type) as mapped_page_type
            ,page_section
            ,target_type
            ,CONCAT_WS('-',  page_type, current_page, trigger_mode, target_type) as mini_feed_tag
            ,cnt
        from
        (
            select
                 page_type,page_section,target_type
                ,rcmd_args['bundle']    	as bnd_recommendation_section
                ,search_args['scenario_key']    	as scenario_key
                ,get_json_object(data, '$.params.trigger_mode') as trigger_mode
                ,get_json_object(data, '$.position.current_page') as current_page
                ,grass_region
                ,count(1) as cnt
            from traffic.dwd_impression_hi__reg_live
            where
                regional_date = date('${grass_date}')
                and grass_region = upper('${region}')
                and user_id > 0
                -- and target_type = 'item'
                -- and domain_type not in ('other')
                -- and coalesce(domain, '') not like '%xiapibuy.com%'
            group by 1,2,3,4,5,6,7,8
        ) imp
        left join page_mapping on imp.scenario_key = page_mapping.scenario_key
) rs
left join feature_mapping on rs.step1_feature_detail=feature_mapping.feature_detail
left join omimi_mapping omini
on rs.mapped_page_type =  omini.mapped_page_type and coalesce(CONCAT_WS('-',  rs.page_section),'') =  coalesce(omini.page_section,'') and rs.target_type =  omini.target_type
left join omimi_mapping_1 omini_1
on rs.mapped_page_type =  omini_1.mapped_page_type and rs.target_type =  omini_1.target_type
group by 1,2
;

-- create or replace temporary view bi_imp as
-- select
--     grass_date
--     ,entry_point
--     ,entry_point_imp
-- from traffic_imp
-- where   entry_point != 'Daily Discover'
-- union all
-- -- add vedio and livestream traffic in DD platform imp
-- select
--     grass_date
--     ,'Daily Discover' as entry_point
--     ,sum(impr_cnt_1d) as entry_point_imp
-- from traffic_omni_oa.dws_business_module_traffic_order_metrics_1d__reg_sensitive_live
-- where
--     grass_date = date('${grass_date}')
--     and grass_region = upper('${region}')
--     and tz_type = 'local'
--     and business_line = 'Homepage'
--     and module in ('Daily Discover')
--     and object in ('all')
-- group by 1, 2
-- ;

create or replace temporary view platform_imp as
select
    grass_region
    ,sum(entry_point_imp) as platform_imp
from bi_imp
where entry_point not in ('exclued')
group by 1
;

create or replace temporary view platform_gmv as
select
    grass_region
    ,cast(sum(gmv_usd) as double) as gmv_usd
    ,cast(sum(nmv_usd) as double) as nmv_usd
    ,sum(case when is_bi_excluded = 0 then gmv_usd else 0 end) as gmv_excl_testorder
from mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
where
    grass_region = upper('${region}')
    and   grass_date BETWEEN DATE_SUB(DATE('${grass_date}'), 1) AND DATE('${grass_date}')
    AND   create_timestamp >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
    AND   create_timestamp < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
    and is_placed = 1
    and tz_type = 'local'
group by 1
;

create or replace temporary view performance_di as
select
    a.grass_region as grass_region
    ,shop_id
    ,entrance
    ,sub_entrance
    ,pricing_type
    ,ads_click
    ,ads_imp
    ,ads_gmv / exchange_rate as ads_gmv_usd
    ,ads_order_cnt
from
(select
    grass_region
    ,shop_id
    ,entrance
    ,sub_entrance
    ,case when placement = 40 then 11 else pricing_type end as pricing_type
    ,sum(case when placement in (3327, 3328, 3337, 3338, 3339) then ifnull (raw_click, 0) else ifnull (click, 0) end) as ads_click
    ,sum(ifnull (impression, 0)) as ads_imp
    ,sum(ifnull (order_gmv, 0) / 100000.0) as ads_gmv
    ,sum(ifnull (order, 0)) as ads_order_cnt
from mp_paidads.ods_log_ads_report_hi__reg_s0_live
where
    grass_region = upper('${region}')
    and   grass_date = DATE('${grass_date}')
    and ads_id > 0
    and placement not in (9)
group by 1, 2, 3, 4, 5
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
    ,is_cb_shop
    ,is_official_shop
    ,is_managed_shop
from mp_user.dim_shop__reg_s0_live
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and tz_type = 'local'
;

create or replace temporary view video_vv as
select
    'video' as entry_point
    ,sum(case when is_item_ads = 1 then video_play_cnt_ntl_1d else 0 end) as ads_imp
    ,sum(video_play_cnt_ntl_1d) as entry_point_imp
from video.video_mart_dws_user_watch_basic_aggr_1d
where grass_region = upper('${region}')
    and grass_date = date('${grass_date}')
    and tz_type = 'local'
group by 1
;

create or replace temporary view video_sub_entrance as
select translog.adsid as ads_id
    ,translog.userid as user_id
    ,translog.timestamp as event_timestamp
    ,sub_entrance
from mp_paidads.ods_log_translog_event_hi__reg_s0_live
where
    grass_region = upper('${region}')
    and   grass_date = DATE('${grass_date}')
    -- and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    -- and   DATE(from_unixtime(translog.timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
    -- and   DATE(from_unixtime(translog.timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
    and sub_entrance = 310103
group by 1,2,3,4
;

create or replace temporary view deduction_di as
select
    grass_region
    ,shop_id
    ,sub_entrance
    ,placement
    ,entrance
    ,pricing_type
    ,deduction_amt_usd
from
(select  grass_region
    ,shop_id
    ,deduction_amt_usd
    ,ads_id
    ,user_id
    ,event_timestamp
    ,placement
    ,entrance
    ,case when placement = 40 then 11 else pricing_type end as pricing_type
from    mp_paidads.dwd_advertiser_deduction_di__reg_s0_live
where   grass_region = upper('${region}')
    and   grass_date BETWEEN DATE_SUB(DATE('${grass_date}'), 1) AND DATE('${grass_date}')
    AND   event_timestamp >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
    AND   event_timestamp < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd')
    and ads_id > 0
    and placement not in (9)
)a
left join video_sub_entrance b
on a.ads_id = b.ads_id
and a.user_id = b.user_id
and a.event_timestamp = b.event_timestamp
;

create or replace temporary view deduction_amt as
select  grass_region
    ,shop_id
    ,entrance
    ,sub_entrance
    ,pricing_type
    ,sum(deduction_amt_usd) as ads_rev_usd
from    deduction_di
group by 1,2,3,4,5
;

create or replace temporary view ads_revenue as
select
    coalesce(a.shop_id,b.shop_id)  as shop_id
    ,coalesce(a.entrance,b.entrance)  as entrance
    ,coalesce(a.sub_entrance,b.sub_entrance)  as sub_entrance
    ,coalesce(a.grass_region,b.grass_region)  as grass_region
    ,coalesce(a.pricing_type,b.pricing_type)  as pricing_type
    ,ifnull(ads_rev_usd, 0) as ads_rev_usd
    ,ifnull(ads_click, 0) as ads_click
    ,ifnull(ads_imp, 0) as ads_imp
    ,ifnull(ads_gmv_usd, 0) as ads_gmv_usd
    ,ifnull(ads_order_cnt, 0) as ads_order_cnt
from
    performance_di a
full join deduction_amt b
    on a.shop_id = b.shop_id
    and a.entrance <=> b.entrance
    and a.pricing_type <=> b.pricing_type
    and a.sub_entrance <=> b.sub_entrance
;


create or replace temporary view sub_entrance_mapping as
select
entry_point
,cast(entrance as int) as entrance
,cast(sub_entrance as bigint) as sub_entrance
from mp_paidads.dim_entry_point_mapping
where  sub_entrance > 0
;


create or replace temporary view entrance_mapping as
select
entry_point
,cast(entrance as int) as entrance
from mp_paidads.dim_entry_point_mapping
where  (sub_entrance is null or sub_entrance = '')
group by 1,2
;

create or replace temporary view ads_revenue_entry_point as
select
    shop_id
    ,a.entrance as entrance
    ,a.sub_entrance as sub_entrance
    ,grass_region
    ,pricing_type
    ,COALESCE(b.entry_point, c.entry_point,'Undefined') as entry_point
    ,ads_rev_usd
    ,ads_click
    ,ads_imp
    ,ads_gmv_usd
    ,ads_order_cnt
from ads_revenue a
left join sub_entrance_mapping b
on a.entrance = b.entrance
and a.sub_entrance = b.sub_entrance
left join entrance_mapping c
on a.entrance = c.entrance
;

create or replace temporary view ads_vat as
select
    grass_region
    ,entry_point
    ,pricing_type
    ,sum(ads_rev_usd) as raw_ads_rev_usd
    ,sum(ads_rev_usd / (1 + tax_rate)) as ads_rev_usd
    ,sum(ads_click) as ads_click
    ,sum(ads_imp) as ads_imp
    ,sum(ads_gmv_usd) as ads_gmv_usd
    ,sum(ads_order_cnt) as ads_order
from
    (
        select
            a.grass_region as grass_region
            ,a.entry_point as entry_point
            ,case
                when is_cb_shop = 1 then cb_tax
                else local_tax
            end as tax_rate
            ,pricing_type
            ,sum(ads_rev_usd) as ads_rev_usd
            ,sum(ads_click) as ads_click
            ,sum(ads_imp) as ads_imp
            ,sum(ads_gmv_usd) as ads_gmv_usd
            ,sum(ads_order_cnt) as ads_order_cnt

        from
            ads_revenue_entry_point a
            left join dim_shop b
            on a.shop_id = b.shop_id
            left join tax c
            on a.grass_region = c.grass_region
        group by 1,2,3,4
    ) t
group by 1,2,3
;


create or replace temporary view display_ads_metrics as
select
    grass_region
    ,'Display' as entry_point
    ,6 as pricing_type
    ,sum(impression_cnt) as ads_imp
    ,null as ads_order
    ,sum(click_cnt) as ads_click
    ,sum(expense_amt_usd / 1000.0) as raw_ads_rev_usd
    ,sum(expense_amt_usd / 1000.0) as ads_rev_usd
    ,null as ads_gmv_usd
from mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live
where grass_date = date('${grass_date}')
and grass_region = upper('${region}')
and tz_type = 'regional'
group by 1, 2
;

create or replace temporary view ads_metrics as
select
    grass_region
    ,entry_point
    ,pricing_type
    ,sum(raw_ads_rev_usd) as raw_ads_rev_usd
    ,sum(ads_rev_usd) as ads_rev_usd
    ,sum(ads_click) as ads_click
    ,sum(ads_imp) as ads_imp
    ,sum(ads_gmv_usd) as ads_gmv_usd
    ,sum(ads_order) as ads_order
from
(select
    grass_region
    ,entry_point
    ,pricing_type
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_click
    ,ads_imp
    ,ads_gmv_usd
    ,ads_order
from ads_vat
union all
select
    grass_region
    ,entry_point
    ,pricing_type
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_click
    ,ads_imp
    ,ads_gmv_usd
    ,ads_order
from display_ads_metrics
)t
group by 1,2,3
;

create or replace temporary view entry_point_imp as
select  grass_region
    ,entry_point
    ,sum(entry_point_imp) as entry_point_imp
from    bi_imp
where   entry_point in ('Search', 'Daily Discover', 'You May Also Like', 'My Purchase Page Recommendation',
                'Order Detail Page Recommendation','Order Successful Recommendation', 'Cart Recommendation',
                'Livestream Streaming Room','Livestream Others', 'Image Search','Me You May Also Like')
group by 1, 2
union all
select  grass_region
    ,'Shop' as entry_point
    ,sum(entry_point_imp) as entry_point_imp
from    bi_imp
where   entry_point in ('Search')
group by 1, 2
union all
select
    grass_region
    ,entry_point
    ,sum(ads_imp) as entry_point_imp
from ads_metrics
where entry_point in ('Game', 'Shop Game')
group by 1,2
;


cache table  bi_click OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select
     grass_region
        ,case when rs.target_type = 'item' and step1_feature_group = 'Search' and step1_feature_detail in ('global_search-item', 'search_in_pdp-item', 'search_in_subcategory-item', 'search_in_mall-item','search-item') then 'Search'
              when rs.target_type = 'item' and step1_feature_group = 'Search' and step1_feature_detail in ('image_search-item','image_search-original_item-item','image_search-rcmd-item','image_search-search-item') then 'Image Search'
              when rs.target_type = 'item' and step1_feature_group = 'Search' then 'Search Others'
              when rs.target_type = 'item' and step1_feature_group = 'You May Also Like' and bnd_recommendation_section = 'product_detail_page' then 'You May Also Like'
              when rs.target_type = 'item' and step1_feature_detail = 'me-you_may_also_like-item' then 'Me You May Also Like'
              when rs.target_type = 'item' and step1_feature_group = 'You May Also Like' then 'You May Also Like Others'
              when rs.target_type = 'item' and step1_feature_group = 'Rcmd Others' and step1_feature_detail = 'order_list-you_may_also_like-item' then 'My Purchase Page Recommendation'
              when rs.target_type = 'item' and step1_feature_group = 'Rcmd Others' and step1_feature_detail = 'order_detail-you_may_also_like-item' then 'Order Detail Page Recommendation'
              when rs.target_type = 'item' and step1_feature_group = 'Live Streaming' and step1_feature_detail in ('streaming_room-display_window-item','streaming_room-related_product_list-item') then 'Livestream Streaming Room'
              when rs.target_type = 'item' and step1_feature_group = 'Live Streaming' then 'Livestream Others'
              when (coalesce(omini.reporting_business_line,omini_1.reporting_business_line) = 'Homepage' and coalesce(omini.reporting_module,omini_1.reporting_module) = 'Daily Discover') or (mini_feed_tag in ('video-mix_feed_page-anchor_product-atc_click','video-mix_feed_page-anchor_product-buynow_click','video-mix_feed_page-anchor_product-video_product_click','video-mix_feed_page-anchor_product-video_product_impression','video-mix_feed_page-comment_product-video_product_impression','video-mix_feed_page-mix_feed_item_click')) then 'Daily Discover'
              when rs.target_type = 'item' and step1_feature_group != 'Daily Discover' then step1_feature_group
              else 'exclued'
         end as entry_point
        ,sum(cnt) as entry_point_click
from
(		select
             CASE
                WHEN CONCAT_WS('-',  COALESCE(mapped_page_type, page_type), page_section, target_type) = '' THEN NULL
                ELSE CONCAT_WS('-',  COALESCE(mapped_page_type, page_type), page_section, target_type)
            END AS step1_feature_detail
            ,grass_region
            ,bnd_recommendation_section
            ,COALESCE(mapped_page_type, page_type) as mapped_page_type
            ,page_section
            ,target_type
            ,CONCAT_WS('-',  page_type, current_page, trigger_mode, target_type) as mini_feed_tag
            ,cnt
        from
        (
            select
                 page_type,page_section,target_type
                ,rcmd_args['bundle']    	as bnd_recommendation_section
                ,search_args['scenario_key']    	as scenario_key
                ,get_json_object(data, '$.params.trigger_mode') as trigger_mode
                ,get_json_object(data, '$.position.current_page') as current_page
                ,grass_region
                ,count(1) as cnt
            from traffic.dwd_click_hi__reg_live
            where
                regional_date = date('${grass_date}')
                and grass_region = upper('${region}')
                and user_id > 0
                -- and target_type = 'item'
                -- and domain_type not in ('other')
                -- and coalesce(domain, '') not like '%xiapibuy.com%'
            group by 1,2,3,4,5,6,7,8
        ) imp
        left join page_mapping on imp.scenario_key = page_mapping.scenario_key
) rs
left join feature_mapping on rs.step1_feature_detail=feature_mapping.feature_detail
left join omimi_mapping omini
on rs.mapped_page_type =  omini.mapped_page_type and coalesce(CONCAT_WS('-',  rs.page_section),'') =  coalesce(omini.page_section,'') and rs.target_type =  omini.target_type
left join omimi_mapping_1 omini_1
on rs.mapped_page_type =  omini_1.mapped_page_type and rs.target_type =  omini_1.target_type
group by 1,2
;

create or replace temporary view entry_point_click as
select  grass_region
    ,entry_point
    ,sum(entry_point_click) as entry_point_click
from    bi_click
where   entry_point in ('Search', 'Daily Discover', 'You May Also Like', 'My Purchase Page Recommendation',
                'Order Detail Page Recommendation','Order Successful Recommendation', 'Cart Recommendation',
                'Livestream Streaming Room','Livestream Others', 'Image Search','Me You May Also Like')
group by 1, 2
union all
select  grass_region
    ,'Shop' as entry_point
    ,sum(entry_point_click) as entry_point_click
from    bi_click
where   entry_point in ('Search')
group by 1, 2
union all
select
    grass_region
    ,entry_point
    ,sum(ads_click) as entry_point_click
from ads_metrics
where entry_point in ('Game', 'Shop Game')
group by 1,2
;

insert overwrite table ads_advertise_take_rate_1d__reg_s0_live partition (tz_type='regional', grass_region, grass_date)
select
    coalesce(b.entry_point, a.entry_point,e.entry_point) as entry_point
    ,case when e.entry_point = 'video' then e.entry_point_imp else b.entry_point_imp end as entry_point_imp
    ,case when e.entry_point = 'video' then e.ads_imp else a.ads_imp end as ads_imp
    ,ads_order
    ,ads_click
    ,raw_ads_rev_usd
    ,ads_rev_usd
    ,ads_gmv_usd
    ,platform_imp
    ,gmv_usd as platform_gmv
    ,nmv_usd as platform_nmv
    ,gmv_excl_testorder as platform_gmv_excl_testorder
    ,pricing_type
    ,entry_point_click
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date

from
    ads_metrics a
full outer join entry_point_imp b
    on a.grass_region = b.grass_region
    and a.entry_point = b.entry_point
left join platform_imp c
    on a.grass_region = c.grass_region
    or b.grass_region = c.grass_region
left join platform_gmv d
    on a.grass_region = d.grass_region
    or b.grass_region = d.grass_region
full outer join video_vv e
 on coalesce(b.entry_point, a.entry_point) = e.entry_point
left join entry_point_click f
on coalesce(b.entry_point, a.entry_point) = f.entry_point
;
