create external table if not exists `dws_advertise_request_benchmark_advv_1d__reg_s0_live` (
  `feature_groups` ARRAY<STRING> COMMENT 'Ads Feature group. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `user_id` BIGINT COMMENT 'Unique user ID. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `request_id` STRING COMMENT 'Unique identifier for the request. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `product_types` ARRAY<STRING> COMMENT 'Product type. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ads_id` BIGINT COMMENT 'Unique ID for ads. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `item_id` BIGINT COMMENT 'Unique identifier of an item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `campaign_id` BIGINT COMMENT 'Unique identifier of an campaign. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `pricing_type` INT COMMENT 'Pricing type. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `placement` BIGINT COMMENT 'Placement. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `attr_data_type` INT COMMENT 'Attr Data Type. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `entrance` INT COMMENT 'ADS entrance. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sub_entrance` INT COMMENT 'ADS sub entrance. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `location` BIGINT COMMENT 'Dispaly location of a target. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sort_by` STRING COMMENT 'Sorting options that the user chose. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `target_type` STRING COMMENT 'Target type. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `revenue_usd_1d` DOUBLE COMMENT 'Revenue in USD from mp_paidads. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `broad_gmv_usd_1d` DOUBLE COMMENT 'Broad order gmv of ads item in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ads_gmv_usd_1d` DOUBLE COMMENT 'Narrow order gmv of ads item in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `avg_target_cir_1d` DOUBLE COMMENT 'Target cir. Source_table: [mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live]',
  `direct_advv_cost_usd_1d` DOUBLE COMMENT 'Direct cost of ads item in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `broad_advv_cost_usd_1d` DOUBLE COMMENT 'Broad cost of ads item in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `direct_advv_gmv_usd_1d` DOUBLE COMMENT 'Direct advv gmv. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `broad_advv_gmv_usd_1d` DOUBLE COMMENT 'Broad advv gmv. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ads_click_cnt_1d` BIGINT COMMENT 'Click count of ads item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ads_imp_cnt_1d` BIGINT COMMENT 'Impression count of ads item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ads_order_cnt_1d` DOUBLE COMMENT 'Order count of ads item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ads_broad_order_cnt_1d` DOUBLE COMMENT 'Broad Order count of ads item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `padvv_usd_1d` DOUBLE COMMENT 'Padvv. Source_table: [mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live]',
  `ads_location_cnt_1d` DOUBLE COMMENT 'Ads total location. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `broad_advv_cost_excl_outlier_usd_1d` DOUBLE COMMENT 'Broad advv cost excl outlier. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `broad_advv_cost_usd_7d` DOUBLE COMMENT 'Broad advv cost 7d. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `page_type` STRING COMMENT 'Page type (image_search, search, shop, me etc.). Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `page_section` STRING COMMENT 'Page section (search, rcmd, search, you_may_also_lick etc.). Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `plan_bucket_list` ARRAY<BIGINT> COMMENT 'Group IDs (BucketID) of the advertising plan belonging to the experiment. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `deepadvv_usd_1d` DOUBLE COMMENT 'Deepadvv for roi2.0_simple. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live, mp_paidads.ads_advertise_mkt_1d__reg_s0_live]. Calculation Logic: broad_gmv_usd_1d / campaign_broad_roi_7d',
  `top20_ads_location_cnt_1d` DOUBLE COMMENT 'Ads total location for top 20 locations. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `platform` STRING COMMENT 'Platform (ios_web, ios_app, android_web, android_app, pc_web, other). Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `main_product_types` ARRAY<STRING> COMMENT 'Main product types (__ALL__ and roi1.0 / roi2.0 / roi3.0 / others). Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `bid_voucher_id` BIGINT COMMENT 'Bid voucher ID. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]. Calculation Logic: extracted from bid_rerank_trace.bid_voucher_id',
  `voucher_types` ARRAY<STRING> COMMENT 'Voucher type array (__ALL__, roi3.0, no_voucher, ...). Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `decoded_video_id` BIGINT COMMENT 'Decoded video ID for video ads. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `deduction_reason` INT COMMENT 'Deduction reason. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `voucher_details_json` STRING COMMENT 'ROI3 Voucher details. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sum_deduction_price_usd_1d` DOUBLE COMMENT 'Deduction price in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `deduction_price_cnt_1d` DOUBLE COMMENT 'Count of deduction item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sum_cpc_deduction_price_usd_1d` DOUBLE COMMENT 'CPC deduction price in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `cpc_deduction_price_cnt_1d` DOUBLE COMMENT 'Count of CPC deduction item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sum_ocpm_deduction_price_usd_1d` DOUBLE COMMENT 'OCPM deduction price in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ocpm_deduction_price_cnt_1d` DOUBLE COMMENT 'Count of OCPM deduction item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sum_bid_price_usd_1d` DOUBLE COMMENT 'Bid price in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `bid_price_cnt_1d` DOUBLE COMMENT 'Count of bid item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sum_cpc_bid_price_usd_1d` DOUBLE COMMENT 'CPC bid price in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `cpc_bid_price_cnt_1d` DOUBLE COMMENT 'Count of CPC bid item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `sum_ocpm_bid_price_usd_1d` DOUBLE COMMENT 'OCPM bid price in usd. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]',
  `ocpm_bid_price_cnt_1d` DOUBLE COMMENT 'Count of OCPM bid item. Source_table: [mp_paidads.dwd_advertise_performance_di__reg_s0_live]'
)
COMMENT 'ADS domain request_id, ads_id level benchmark table.'
partitioned by (
    grass_region string comment 'grass_region'
    ,grass_date date comment 'grass_date'
)
stored as PARQUET location '${HIVE_PATH}/dws_advertise_request_benchmark_advv_1d__reg_s0_live'
;


create or replace temporary view advertise_tracking_item as
select
    user_id
    ,campaign_id
    ,ads_id
    ,ads_request_id
    ,item_id
    ,ads_entrance
    ,pricing_type
    ,ads_placement

    ,max(coalesce(cast(target_cir as double)
            , cast(get_json_object(item_json_data, '$.target_cir') as double))
        ) as target_cir
    ,max(cast(if(operation=2,get_json_object(item_json_data, '$.padvv'),null) as double)) as padvv
    ,max(
        case when operation = 1 and get_json_object(bid_rerank_trace, '$.bid_voucher_id') is not null
             then item_voucher.display_ads_voucher_label
        end
    ) as display_ads_voucher_label
from
    mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live
where
    grass_date = date('${grass_date}')
    and grass_region = upper('${region}')
    and ads_id > 0
    and ads_placement != 54 -- exclude video ads 明投
    and pricing_type != 29 -- exclude 原生发券商品
group by
    1,2,3,4,5,6,7,8;

--sql_divide_splitter--

create or replace temporary view advertise_tracking_item_video as
select
    user_id
    ,campaign_id
    ,ads_id
    ,ads_request_id
    ,cast(video_id as bigint) as video_id
    ,ads_entrance
    ,pricing_type
    ,ads_placement

    ,max(coalesce(cast(target_cir as double)
            , cast(get_json_object(video_json_data, '$.target_cir') as double))
        ) as target_cir
    ,null as padvv
from
    mp_paidads.dwd_request_tracking_video_hi__reg_s0_live
where
    grass_region = upper('${region}')
    and grass_date >= DATE('${grass_date}')
    and grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    and timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
    and timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
    and ads_placement = 54 -- only include video ads 明投
    and delivery_type = 0 -- 0: 明投，1: 暗投 (目前只有明投)
    and cast(video_id as bigint) > 0
group by
    1,2,3,4,5,6,7,8;

--sql_divide_splitter--

create or replace temporary view exchange_rate as
select
    avg(cast(exchange_rate as double)) as fx
from
    mp_order.dim_exchange_rate__reg_s0_live
where
    grass_region = upper('${region}')
    and grass_date = date('${grass_date}');

--sql_divide_splitter--

create or replace temporary view campaign_roi as
select
    campaign_id
    ,sum(broad_order_gmv_amt_usd) / sum(ads_expenditure_amt_usd) as campaign_broad_roi_7d
from (
    select
        ads.ads_id
        ,ads.pricing_type
        ,ads.campaign_id
        ,expenditure_amt_usd as ads_expenditure_amt_usd
        ,broad_order_gmv_amt_usd
        ,coalesce(event.tz_type, 'local') as tz_type
        ,ads.grass_date
    FROM (
        select
            ads_id
            ,placement
            ,case when placement in (45,46) then coalesce(pricing_type,0) else pricing_type end as pricing_type
            ,campaign_id
            ,grass_date
        from mp_paidads.dim_advertise__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date between date_add(date('${grass_date}'), -6) and date('${grass_date}')
    ) ads
    left outer join (
        select
            ads_id
            ,placement
            ,new_boost
            ,entrance
            ,tz_type
            ,grass_date
            ,sum(expenditure_amt_usd_1d) as expenditure_amt_usd
            ,sum(broad_gmv_amt_usd_1d) as broad_order_gmv_amt_usd
        from mp_paidads.dws_advertise_performance_1d__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date between date_add(date('${grass_date}'), -6) and date('${grass_date}')
        group by ads_id
                ,placement
                ,new_boost
                ,entrance
                ,tz_type
                ,grass_date
    ) event
    on ads.ads_id = event.ads_id
    and ads.placement = event.placement
    and ads.grass_date = event.grass_date
)
where
    tz_type = 'local'
    and pricing_type = 15
group by 1;

--sql_divide_splitter--

create or replace temporary view product_type_mapping as
select
    cast(pricing_type as int) as pricing_type
    ,cast(placement as int) as placement
    ,sub_product_type
    ,product_type
    ,main_product_type
from mp_paidads.dim_product_type_mapping__reg_s0_live
group by 1,2,3,4,5
;

--sql_divide_splitter--

create or replace temporary view dws_ads_parsed as
select
    user_id
    ,item_id
    ,decoded_video_id
    ,campaign_id
    ,ads_id
    ,request_id
    ,pricing_type
    ,attr_data_type
    ,placement
    ,entrance
    ,sub_entrance
    ,location
    ,sort_by
    ,page_type
    ,page_section
    ,target_type
    ,plan_bucket_list
    ,platform
    ,broad_gmv_amt_local
    ,expenditure_amt_usd
    ,ads_order_gmv_usd
    ,click_cnt
    ,raw_click_cnt
    ,product_click
    ,impression_cnt
    ,order_cnt
    ,broad_order_cnt
    ,target_cir
    ,cast(get_json_object(bid_rerank_trace, '$.bid_voucher_id') as bigint) as bid_voucher_id
    ,deduction_reason
    ,voucher_details_json
    ,is_ocpm
    ,deduplicated_click
    ,ctx_item_type
    ,is_preselected_vmodel
    ,case
        when coalesce(is_ocpm, false) = false and click_cnt > 0 then cast(get_json_object(bid_rerank_trace, '$.adjusted_bid_price') as double)
        when is_ocpm = true and deduct_impression > 0 then cast(get_json_object(bid_rerank_trace, '$.adjusted_bid_price') as double)
           * cast(get_json_object(bid_rerank_trace, '$.pctr') as double)
    end as bid_price

    ,case
        when (coalesce(is_ocpm, false) = false and click_cnt > 0) or (is_ocpm = true and deduct_impression > 0) then expenditure_amt_usd
    end as deduction_price_usd

    ,case
        when coalesce(is_ocpm, false) = false and click_cnt > 0 then cast(get_json_object(bid_rerank_trace, '$.adjusted_bid_price') as double)
    end as cpc_bid_price

    ,case
        when coalesce(is_ocpm, false) = false and click_cnt > 0 then expenditure_amt_usd
    end as cpc_deduction_price_usd

    ,case
        when is_ocpm = true and deduct_impression > 0 then cast(get_json_object(bid_rerank_trace, '$.adjusted_bid_price') as double)
           * cast(get_json_object(bid_rerank_trace, '$.pctr') as double)
    end as ocpm_bid_price

    ,case
        when is_ocpm = true and deduct_impression > 0 then expenditure_amt_usd
    end as ocpm_deduction_price_usd
from
    mp_paidads.dwd_advertise_performance_di__reg_s0_live
where
    grass_region = upper('${region}')
    and grass_date = date('${grass_date}')
    and tz_type = 'local'
    and ads_id > 0
    and pricing_type != 29 -- exclude 原生发券商品
;

--sql_divide_splitter--

create or replace temporary view dws_ads_performance as
select
    case
        when b.product_type = 'ROI2.0' then array('roi2.0', '__ALL__')
        when b.product_type is not null and b.product_type <> 'ROI2.0' then array(b.product_type, '__ALL__')
        else array('others', '__ALL__')
    end as main_product_types
    ,case
        when a.pricing_type = 4 and COALESCE(attr_data_type, 999) != 1 then array('simple_ocpc', '__ALL__')
        when a.pricing_type = 4 and attr_data_type=1 then array('simple_ocpc', 'simple_mode_boost', '__ALL__')
        when a.pricing_type = 8 and COALESCE(attr_data_type, 999) != 1 then array('simple_roas', '__ALL__')
        when a.pricing_type = 8 and attr_data_type=1 then array('simple_roas', 'simple_mode_boost', '__ALL__')
        when (a.pricing_type = 11) then array('roi2.0_target (cpc)', 'roi2.0_target', '__ALL__')
        when (a.pricing_type = 15 and attr_data_type not in (0,1)) then array('roi2.0_simple', '__ALL__')
        when a.pricing_type=15 and attr_data_type=1 then array('roi2.0_simple', 'roi2.0_simple (organic)', '__ALL__')
        when a.pricing_type=15 and (attr_data_type=0 or attr_data_type is null) then array('roi2.0_simple', 'roi2.0_simple (ads)', '__ALL__')
        when a.pricing_type = 20 then array('roi2.0_target (cps)', 'roi2.0_target', '__ALL__')
        when b.sub_product_type is not null then array(b.sub_product_type, '__ALL__')
        else array('others', '__ALL__')
    end as product_types
    ,case
        when entrance = 1 and COALESCE(sub_entrance,999) != 310104 then array('Search', 'Search_RCMD', '__ALL__')
        when entrance = 1 and sub_entrance = 310104 then array('Search', 'Search_RCMD', 'video_search_pdp_external#video_search_external#video_search#video_rcmd_all#video_all#ads_general', '__ALL__')
        when entrance = 3 and COALESCE(sub_entrance,999) != 310103 then array('Daily Discover', 'DD_PP Unify', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 3 and sub_entrance = 310103 then array('Daily Discover', 'DD_PP Unify', 'video_ymal_dd_external#dd_video_external#dd_video#video_rcmd_core#video_rcmd_all#video_all#ads_general#dd_external_and_trending_internal_all', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance in (25,31,32) then array('Daily Discover', 'DD_PP Unify', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance in (4) then array('You May Also Like', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 8 then array('Cart Recommendation', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 9 then array('Order Successful Recommendation', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 10 then array('Order Detail Page YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 11 then array('My Purchase Page YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 40 then array('Me YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 45 then array('Shop YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 50 then array('video_landing#video_search_internal#video_search#video_rcmd_all#video_all#ads_general', '__ALL__')
        when entrance = 54 then array('video_search_pdp_external#floating_window_landing_external#floating_window_landing#video_rcmd_all#video_all', '__ALL__') -- pdp 外流
        when entrance = 55 then array('video_landing#floating_window_landing_internal#floating_window_landing#video_rcmd_all#video_all#ads_general', '__ALL__') -- pdp 内流
        when entrance = 56 then array('Daily Discover', 'DD_PP Unify', 'video_landing#mixfeed_internal_video#mixfeed_internal#mixfeed_video#mixfeed_all#ads_general', 'RCMD Unify', 'Search_RCMD', '__ALL__') -- minifeed
        when entrance = 57 then array('SIP YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 58 then array('You May Also Like', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', 'video_landing#video_ymal_internal#video_ymal#video_rcmd_all#video_all#ads_general', '__ALL__') --ymal 内流

        when entrance = 29 then array('video_landing#video_trending#video_rcmd_core#trending_video_internal_all#trending_hp_internal#video_rcmd_all#video_all#ads_video_feed#ads_general#dd_external_and_trending_internal_all', '__ALL__') -- video trending
        when entrance = 34 then array('Daily Discover', 'DD_PP Unify', 'video_landing#dd_video_internal#trending_video_internal_all#dd_video#video_rcmd_core#video_rcmd_all#video_all#ads_video_feed#ads_general#dd_external_and_trending_internal_all', 'RCMD Unify', 'Search_RCMD', '__ALL__') -- dd video内流
        when entrance = 36 then array('video_landing#homepage_video_external#homepage_video#video_rcmd_core#video_rcmd_all#video_all', '__ALL__') --homepage video外流
        when entrance = 33 then array('video_landing#homepage_video_internal#trending_video_internal_all#trending_hp_internal#homepage_video#video_rcmd_core#video_rcmd_all#video_all#ads_video_feed#ads_general#dd_external_and_trending_internal_all', '__ALL__') --homepage video内流
        when entrance in (27,28,37,38,39,42,48) and a.placement in (3327,3328,3337,3338,3339,3342,3348) then array('Livestream', '__ALL__')
        when entrance in (7,12,13,14,15,16,17,18,19,20,21,22,26,41,43) then array('Game', '__ALL__')
        when entrance = 62 then array('You May Also Like', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', 'video_ymal_dd_external#video_ymal_external#video_ymal#video_rcmd_all#video_all#ads_general', '__ALL__')

        when entrance = 63 then array('video_mpp_external#video_mpp#video_all#ads_general', 'My Purchase Page YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 64 then array('video_mpp_internal#video_mpp#video_all#ads_general', 'My Purchase Page YMAL', 'Cart Unify', 'DD_PP Unify', 'YMAL_Cart', 'RCMD Unify', 'Search_RCMD', '__ALL__')
        when entrance = 65 then array('Shop Main Browsing', 'Shop_Unify', '__ALL__')
        when entrance = 66 then array('Shop Product Tab', 'Shop_Unify', '__ALL__')
        when entrance in (67,68) then array('Shop Recommended For You', 'Shop_Unify', '__ALL__')
        when entrance = 69 then array('Shop Category Tab', 'Shop_Unify', '__ALL__')
        when entrance in (70,71) then array('Shop Hot Deals', 'Shop_Unify', '__ALL__')
        when entrance = 72 then array('Shop Campaign Tab Just For You', 'Shop_Unify', '__ALL__')
        when entrance = 73 then array('Shop Just For You', 'Shop_Unify', '__ALL__')
        when entrance = 74 then array('From the Same Shop', 'Shop_Unify', '__ALL__')
        else array('others', '__ALL__')
    end as feature_groups
    ,user_id
    ,item_id
    ,decoded_video_id
    ,campaign_id
    ,ads_id
    ,request_id
    ,a.pricing_type
    ,attr_data_type
    ,a.placement
    ,entrance
    ,sub_entrance
    ,location
    ,sort_by
    ,page_type
    ,page_section
    ,target_type
    ,plan_bucket_list
    ,platform
    ,bid_voucher_id
    ,deduction_reason
    ,voucher_details_json

    ,sum(coalesce(broad_gmv_amt_local,0)) as broad_gmv_local
    ,sum(coalesce(expenditure_amt_usd,0)) as revenue_usd_1d
    ,sum(coalesce(ads_order_gmv_usd,0)) as ads_gmv_usd_1d
    ,sum(coalesce(
        case
            when ctx_item_type = 2 and coalesce(is_preselected_vmodel, false) = false then 0  -- vitem but is not first card then do not account
            when a.placement = 54 and a.pricing_type in (16,17,21) then product_click
            when entrance in (27,28,37,38,39,42,48) and a.placement in (3327,3328,3337,3338,3339,3342,3348) then raw_click_cnt
            when is_ocpm = true then coalesce(deduplicated_click, 0)
            else click_cnt
        end,0)) as ads_click_cnt_1d
    ,sum(coalesce(
        case when ctx_item_type = 2 and coalesce(is_preselected_vmodel, false) = false then 0  -- vitem but is not first card then do not account
            else impression_cnt
        end,0)) as ads_imp_cnt_1d
    ,sum(coalesce(order_cnt,0)) as ads_order_cnt_1d
    ,sum(coalesce(broad_order_cnt,0)) as ads_broad_order_cnt_1d
    ,sum(if(impression_cnt>0,location,0)) as ads_location
    ,sum(coalesce(broad_gmv_amt_local,0)*coalesce(target_cir,0)) as broad_advv_cost_7d_local
    ,sum(if(impression_cnt>0 and location<=19,location,0)) as top20_ads_location

    ,sum(deduction_price_usd) as deduction_price_usd
    ,sum(cpc_deduction_price_usd) as cpc_deduction_price_usd
    ,sum(ocpm_deduction_price_usd) as ocpm_deduction_price_usd
    ,sum(bid_price) as bid_price
    ,sum(cpc_bid_price) as cpc_bid_price
    ,sum(ocpm_bid_price) as ocpm_bid_price
from
    dws_ads_parsed as a
left join product_type_mapping as b
on a.pricing_type = b.pricing_type
and a.placement = b.placement
group by
    b.product_type,b.sub_product_type,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24;

--sql_divide_splitter--

create or replace temporary view dws_ads_performance_joined as
select
    a.*
    ,null as sum_ads_click_cnt

    ,target_cir
    ,padvv
    ,null as display_ads_voucher_label
    ,null as campaign_broad_roi_7d
from
    dws_ads_performance as a
    left join advertise_tracking_item_video as b
    on a.user_id = b.user_id
    and a.ads_id = b.ads_id
    and a.decoded_video_id = b.video_id
    and a.campaign_id = b.campaign_id
    and a.request_id = b.ads_request_id
    and a.entrance = b.ads_entrance
    and a.pricing_type = b.pricing_type
    and a.placement = b.ads_placement
where
    a.pricing_type in (16, 17, 21)

union all
select
    a.*
    ,sum(ads_click_cnt_1d) over (partition by a.user_id, a.request_id, feature_groups, product_types, a.ads_id, a.item_id, a.campaign_id) as sum_ads_click_cnt

    ,target_cir
    ,padvv
    ,display_ads_voucher_label
    ,campaign_broad_roi_7d
from
    dws_ads_performance as a
    left join advertise_tracking_item as b
        on a.user_id = b.user_id
        and a.ads_id = b.ads_id
        and a.item_id = b.item_id
        and a.campaign_id = b.campaign_id
        and a.request_id = b.ads_request_id
        and a.entrance = b.ads_entrance
        and a.pricing_type = b.pricing_type
        and a.placement = b.ads_placement
    left join campaign_roi as c
        on a.campaign_id = c.campaign_id
where
    a.pricing_type = 15

union all
select
    a.*
    ,sum(ads_click_cnt_1d) over (partition by a.user_id, a.request_id, feature_groups, product_types, a.ads_id, a.item_id, a.campaign_id) as sum_ads_click_cnt

    ,target_cir
    ,padvv
    ,display_ads_voucher_label
    ,null as campaign_broad_roi_7d
FROM
    dws_ads_performance as a
    left join advertise_tracking_item as b
        on a.user_id = b.user_id
        and a.ads_id = b.ads_id
        and a.item_id = b.item_id
        and a.campaign_id = b.campaign_id
        and a.request_id = b.ads_request_id
        and a.entrance = b.ads_entrance
        and a.pricing_type = b.pricing_type
        and a.placement = b.ads_placement
where
    a.pricing_type not in (15, 16, 17, 21)
;

--sql_divide_splitter--

insert overwrite table dws_advertise_request_benchmark_advv_1d__reg_s0_live
partition (
    grass_region
    ,grass_date
)
select
/*+ BROADCAST(b) */
    feature_groups
    ,user_id
    ,request_id
    ,product_types
    ,ads_id
    ,item_id
    ,a.campaign_id
    ,pricing_type
    ,placement
    ,attr_data_type
    ,entrance
    ,sub_entrance
    ,location
    ,sort_by
    ,target_type

    ,sum(revenue_usd_1d) as revenue_usd_1d
    ,sum(broad_gmv_local/ nullif(fx, 0)) as broad_gmv_usd_1d
    ,sum(ads_gmv_usd_1d) as ads_gmv_usd_1d
    ,avg(target_cir) as avg_target_cir_1d
    ,case when pricing_type in (1, 2, 3, 13, 16) then sum(revenue_usd_1d)
        else sum(ads_gmv_usd_1d*coalesce(target_cir,0)) end as direct_advv_cost_usd_1d
    ,case when pricing_type in (1, 2, 3, 13, 16) then sum(revenue_usd_1d)
        else sum(broad_gmv_local / nullif(fx, 0) * coalesce(target_cir,0)) end as broad_advv_cost_usd_1d
    ,case when pricing_type in (1, 2, 3, 13, 16) then sum(ads_gmv_usd_1d)
        else sum(if(coalesce(target_cir,0)= 0, 0, revenue_usd_1d/target_cir)) end as direct_advv_gmv_usd_1d
    ,case when pricing_type in (1, 2, 3, 13, 16) then sum(broad_gmv_local)/avg(fx)
        else sum(if(coalesce(target_cir,0)= 0, 0, revenue_usd_1d/target_cir)) end as broad_advv_gmv_usd_1d

    ,sum(ads_click_cnt_1d) as ads_click_cnt_1d
    ,sum(ads_imp_cnt_1d) as ads_imp_cnt_1d
    ,sum(ads_order_cnt_1d) as ads_order_cnt_1d
    ,sum(ads_broad_order_cnt_1d) as ads_broad_order_cnt_1d
    ,case when pricing_type in (16, 17, 21) then null
        else sum(if(sum_ads_click_cnt>0,coalesce(padvv / nullif(fx, 0),0),0))/100000 end as padvv_usd_1d
    ,sum(ads_location) as ads_location_cnt_1d
    ,case when pricing_type in (1, 2, 3, 13, 16) then sum(revenue_usd_1d)
        else sum(if(target_cir<50,broad_gmv_local / nullif(fx, 0) * coalesce(target_cir,0),0)) end as broad_advv_cost_excl_outlier_usd_1d
    ,case when pricing_type in (1, 2, 3, 13, 16) then sum(revenue_usd_1d)
        else sum(broad_advv_cost_7d_local)/avg(fx) end as broad_advv_cost_usd_7d
    ,page_type
    ,page_section
    ,plan_bucket_list
    ,case when pricing_type = 15 then sum(if(coalesce(campaign_broad_roi_7d, 0) = 0, 0, broad_gmv_local / nullif(fx * campaign_broad_roi_7d, 0)))
        else null end as deepadvv_usd_1d
    ,sum(top20_ads_location) as top20_ads_location_cnt_1d
    ,case
        when platform = 1 then 'ios_web'
        when platform = 2 then 'ios_app'
        when platform = 3 then 'android_web'
        when platform = 4 then 'android_app'
        when platform = 5 then 'pc_web'
        when platform = 9 then 'android_app_lite'
        when platform is null then null
        else 'other'
    end as platform
    ,main_product_types
    ,bid_voucher_id
    ,case
        when pricing_type not in (11,15) then array('__ALL__')
        when pricing_type in (11,15) and bid_voucher_id is not null and coalesce(max(display_ads_voucher_label), 999) != 1 then array('roi3.0', '__ALL__')
        when pricing_type in (11,15) and bid_voucher_id is not null and max(display_ads_voucher_label) = 1 then array('roi3.0_display', 'roi3.0', '__ALL__')
        else array('no_voucher', '__ALL__')
    end as voucher_types
    ,decoded_video_id
    ,deduction_reason
    ,voucher_details_json

    -- deduct
    ,sum(deduction_price_usd) as sum_deduction_price_usd_1d
    ,count(deduction_price_usd) as deduction_price_cnt_1d
    ,sum(cpc_deduction_price_usd) as sum_cpc_deduction_price_usd_1d
    ,count(cpc_deduction_price_usd) as cpc_deduction_price_cnt_1d
    ,sum(ocpm_deduction_price_usd) as sum_ocpm_deduction_price_usd_1d
    ,count(ocpm_deduction_price_usd) as ocpm_deduction_price_cnt_1d

    -- bid
    ,sum(bid_price/nullif(100000*fx,0)) as sum_bid_price_usd_1d
    ,count(bid_price) as bid_price_cnt_1d
    ,sum(cpc_bid_price/nullif(100000*fx,0)) as sum_cpc_bid_price_usd_1d
    ,count(cpc_bid_price) as cpc_bid_price_cnt_1d
    ,sum(ocpm_bid_price/nullif(100000*fx,0)) as sum_ocpm_bid_price_usd_1d
    ,count(ocpm_bid_price) as ocpm_bid_price_cnt_1d

    --partition
    ,upper('${region}') as grass_region
    ,date('${grass_date}') as grass_date
FROM
    dws_ads_performance_joined as a
left join exchange_rate as b
group by
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,32,33,34,37,38,39,41,42,43;
