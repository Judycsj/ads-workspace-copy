-- task_code: data_paidadsmart.studio_2736097  asset_id: 2736097
cache table dim OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  user_id
        ,user_name
        ,shop_id
        ,language
        ,status
        ,grass_region AS country
        ,create_datetime
        ,modify_datetime
        ,beetalk_userid
        ,account_create_datetime
        ,account_modify_datetime
        ,account_status
        ,is_seller
        ,is_cb_seller
        ,is_managed_seller
        ,is_official_shop
        ,is_preferred_shop
        ,is_auto_topup_enabled
        ,is_campaign_auto_bid_enabled
        ,shop_level1_global_be_category
        ,shop_level1_fe_display_category
        ,shop_level1_kpi_category
        ,shop_level2_global_be_category
        ,shop_level2_fe_display_category
        ,shop_level2_kpi_category
        ,is_self_mcn
        ,grass_region
        ,tt AS tz_type
from    mp_paidads.dim_advertiser__reg_s0_live
lateral view EXPLODE(ARRAY('local', 'regional')) AS tt
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;

cache table active OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
            ,grass_region
            ,COUNT(DISTINCT ads_id) AS active_ads_cnt
    from    mp_paidads.dim_advertise__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}')
      and   is_ads_active = 1
      and pricing_type!=29
    group by shop_id, grass_region
    having  COUNT(distinct ads_id) >= 1;

cache table first_active OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
            ,grass_region
            ,first_mm_kw_ads_active_date
            ,first_sm_kw_ads_active_date
    from    mp_paidads.dws_advertiser_first_active_td__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}');

cache table balance OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
            ,low_threshold
            ,low_threshold_usd
            ,is_reach_threshold
            ,grass_region
    from    mp_paidads.dws_advertiser_account_td__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}');

cache table cat1 OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  tz_type
            ,grass_region
            ,shop_id
            ,lower(level1_global_be_category.level1_global_be_category) AS level1_global_be_category
            ,SUM(ads_expenditure_amt_local) AS l1cat_ads_expenditure_amt_1d
            ,SUM(ads_expenditure_amt_usd) AS l1cat_ads_expenditure_amt_usd_1d
            ,SUM(ads_gmv_local) AS l1cat_ads_gmv_amt_1d
            ,SUM(ads_gmv_usd) l1cat_ads_gmv_amt_usd_1d
    from    mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}')
    group by 1, 2, 3, 4;

cache table cat2 OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  tz_type
            ,grass_region
            ,shop_id
            ,lower(level2_global_be_category.level2_global_be_category) AS level2_global_be_category
            ,SUM(ads_expenditure_amt_local) AS l2cat_ads_expenditure_amt_1d
            ,SUM(ads_expenditure_amt_usd) AS l2cat_ads_expenditure_amt_usd_1d
            ,SUM(ads_gmv_local) AS l2cat_ads_gmv_amt_1d
            ,SUM(ads_gmv_usd) l2cat_ads_gmv_amt_usd_1d
    from    mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}')
    group by 1, 2, 3, 4;

cache table  plat OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  user_id
        ,grass_region
        ,order_item_cnt_1d
        ,order_item_cnt_7d
        ,order_item_cnt_30d
        ,order_item_cnt_60d
        ,order_item_cnt_90d
        ,items_sold_cnt_1d
        ,items_sold_cnt_7d
        ,items_sold_cnt_30d
        ,items_sold_cnt_60d
        ,items_sold_cnt_90d
        ,gmv_1d
        ,gmv_7d
        ,gmv_30d
        ,gmv_60d
        ,gmv_90d
        ,gmv_usd_1d
        ,gmv_usd_7d
        ,gmv_usd_30d
        ,gmv_usd_60d
        ,gmv_usd_90d
from    mp_paidads.dws_advertiser_trd_order_gmv_nd__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;

cache table td OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
            ,last_active_date
            ,grass_region
            ,tz_type
    from    mp_paidads.dws_advertiser_active_status_td__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}');

cache table topup1d OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
        ,total_topup_amt
        ,total_topup_amt_usd
        ,manual_topup_amt
        ,manual_topup_amt_usd
        ,manual_free_credit_topup_amt
        ,manual_free_credit_topup_amt_usd
        ,manual_paid_credit_topup_amt
        ,manual_paid_credit_topup_amt_usd
        ,auto_topup_amt_local AS auto_topup_amt
        ,auto_topup_amt_usd
        ,normal_amt_local
        ,normal_amt_usd
        ,seller_mission_topup_amt
        ,seller_mission_topup_amt_usd
        ,srm_topup_amt
        ,srm_topup_amt_usd
        ,neg_topup_amt
        ,neg_topup_amt_usd
        ,tz_type
        ,grass_region AS region
from    mp_paidads.dws_advertiser_topup_1d__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;

cache table topupnd OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
        ,total_topup_amt_7d
        ,total_topup_amt_30d
        ,total_topup_amt_60d
        ,total_topup_amt_usd_7d
        ,total_topup_amt_usd_30d
        ,total_topup_amt_usd_60d
        ,manual_topup_amt_7d
        ,manual_topup_amt_30d
        ,manual_topup_amt_60d
        ,manual_topup_amt_usd_7d
        ,manual_topup_amt_usd_30d
        ,manual_topup_amt_usd_60d
        ,manual_free_credit_topup_amt_7d
        ,manual_free_credit_topup_amt_30d
        ,manual_free_credit_topup_amt_60d
        ,manual_free_credit_topup_amt_usd_7d
        ,manual_free_credit_topup_amt_usd_30d
        ,manual_free_credit_topup_amt_usd_60d
        ,manual_paid_credit_topup_amt_7d
        ,manual_paid_credit_topup_amt_30d
        ,manual_paid_credit_topup_amt_60d
        ,manual_paid_credit_topup_amt_usd_7d
        ,manual_paid_credit_topup_amt_usd_30d
        ,manual_paid_credit_topup_amt_usd_60d
        ,auto_topup_amt_7d
        ,auto_topup_amt_30d
        ,auto_topup_amt_60d
        ,auto_topup_amt_usd_7d
        ,auto_topup_amt_usd_30d
        ,auto_topup_amt_usd_60d
        ,normal_amt_local_7d
        ,normal_amt_local_30d
        ,normal_amt_local_60d
        ,normal_amt_usd_7d
        ,normal_amt_usd_30d
        ,normal_amt_usd_60d
        ,seller_mission_topup_amt_7d
        ,seller_mission_topup_amt_30d
        ,seller_mission_topup_amt_60d
        ,seller_mission_topup_amt_usd_7d
        ,seller_mission_topup_amt_usd_30d
        ,seller_mission_topup_amt_usd_60d
        ,srm_topup_amt_7d
        ,srm_topup_amt_30d
        ,srm_topup_amt_60d
        ,srm_topup_amt_usd_7d
        ,srm_topup_amt_usd_30d
        ,srm_topup_amt_usd_60d
        ,neg_topup_amt_7d
        ,neg_topup_amt_30d
        ,neg_topup_amt_60d
        ,neg_topup_amt_usd_7d
        ,neg_topup_amt_usd_30d
        ,neg_topup_amt_usd_60d
        ,tz_type
        ,grass_region AS region
from    mp_paidads.dws_advertiser_topup_nd__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;

cache table ads_perf OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
        ,tz_type
        ,grass_region
        ,SUM(impression_cnt_1d) AS impression_cnt_1d
        ,SUM(impression_cnt_7d) AS impression_cnt_7d
        ,SUM(impression_cnt_30d) AS impression_cnt_30d
        ,SUM(impression_cnt_60d) AS impression_cnt_60d
        ,SUM(impression_cnt_90d) AS impression_cnt_90d
        ,SUM(click_cnt_1d) AS click_cnt_1d
        ,SUM(click_cnt_7d) AS click_cnt_7d
        ,SUM(click_cnt_30d) AS click_cnt_30d
        ,SUM(click_cnt_60d) AS click_cnt_60d
        ,SUM(click_cnt_90d) AS click_cnt_90d
        ,SUM(order_cnt_1d) AS order_cnt_1d
        ,SUM(order_cnt_7d) AS order_cnt_7d
        ,SUM(order_cnt_30d) AS order_cnt_30d
        ,SUM(order_cnt_60d) AS order_cnt_60d
        ,SUM(order_cnt_90d) AS order_cnt_90d
        ,SUM(paid_order_cnt_ytd_1d) AS paid_order_cnt_ytd_1d
        ,SUM(confirmed_order_cnt_ytd_1d) AS confirmed_order_cnt_ytd_1d
        ,SUM(ads_items_sold_cnt_1d) AS ads_items_sold_cnt_1d
        ,SUM(ads_items_sold_cnt_7d) AS ads_items_sold_cnt_7d
        ,SUM(ads_items_sold_cnt_30d) AS ads_items_sold_cnt_30d
        ,SUM(ads_items_sold_cnt_60d) AS ads_items_sold_cnt_60d
        ,SUM(ads_items_sold_cnt_90d) AS ads_items_sold_cnt_90d
        ,SUM(ads_gmv_amt_local_1d) AS ads_gmv_amt_local_1d
        ,SUM(ads_gmv_amt_local_7d) AS ads_gmv_amt_local_7d
        ,SUM(ads_gmv_amt_local_30d) AS ads_gmv_amt_local_30d
        ,SUM(ads_gmv_amt_local_60d) AS ads_gmv_amt_local_60d
        ,SUM(ads_gmv_amt_local_90d) AS ads_gmv_amt_local_90d
        ,SUM(ads_gmv_amt_usd_1d) AS ads_gmv_amt_usd_1d
        ,SUM(ads_gmv_amt_usd_7d) AS ads_gmv_amt_usd_7d
        ,SUM(ads_gmv_amt_usd_30d) AS ads_gmv_amt_usd_30d
        ,SUM(ads_gmv_amt_usd_60d) AS ads_gmv_amt_usd_60d
        ,SUM(ads_gmv_amt_usd_90d) AS ads_gmv_amt_usd_90d
        ,SUM(expenditure_amt_local_1d) AS expenditure_amt_local_1d
        ,SUM(expenditure_amt_local_7d) AS expenditure_amt_local_7d
        ,SUM(expenditure_amt_local_30d) AS expenditure_amt_local_30d
        ,SUM(expenditure_amt_local_60d) AS expenditure_amt_local_60d
        ,SUM(expenditure_amt_local_90d) AS expenditure_amt_local_90d
        ,SUM(expenditure_amt_usd_1d) AS expenditure_amt_usd_1d
        ,SUM(expenditure_amt_usd_7d) AS expenditure_amt_usd_7d
        ,SUM(expenditure_amt_usd_30d) AS expenditure_amt_usd_30d
        ,SUM(expenditure_amt_usd_60d) AS expenditure_amt_usd_60d
        ,SUM(expenditure_amt_usd_90d) AS expenditure_amt_usd_90d
from    mp_paidads.dws_advertise_performance_nd__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
group by shop_id, tz_type, grass_region
;

cache table bal OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
        ,grass_region
        ,tz_type
        ,free_credit_w_expiry_eod_balance_amt_td
        ,free_credit_w_expiry_eod_balance_amt_usd_td
        ,free_credit_wo_expiry_eod_balance_amt_td
        ,free_credit_wo_expiry_eod_balance_amt_usd_td
        ,paid_credit_w_expiry_eod_balance_amt_td
        ,paid_credit_w_expiry_eod_balance_amt_usd_td
        ,paid_credit_wo_expiry_eod_balance_amt_td
        ,paid_credit_wo_expiry_eod_balance_amt_usd_td
        ,paid_credit_wo_expiry_sod_balance_amt_td
        ,paid_credit_wo_expiry_sod_balance_amt_usd_td
        ,total_eod_balance_td
        ,total_eod_balance_usd_td
from    mp_paidads.dws_advertiser_balance_td__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;

cache table credit OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
        ,grass_region
        ,tz_type
        ,manual_free_credit_expired_amt_td
        ,manual_free_credit_expired_amt_usd_td
        ,manual_paid_credit_expired_amt_td
        ,manual_paid_credit_expired_amt_usd_td
        ,seller_mission_free_credit_expired_amt_td
        ,seller_mission_free_credit_expired_amt_usd_td
        ,seller_mission_paid_credit_expired_amt_td
        ,seller_mission_paid_credit_expired_amt_usd_td
        ,srm_free_credit_expired_amt_td
        ,srm_free_credit_expired_amt_usd_td
        ,srm_paid_credit_expired_amt_td
        ,srm_paid_credit_expired_amt_usd_td
        ,total_free_credit_expired_amt_td
        ,total_free_credit_expired_amt_usd_td
        ,total_paid_credit_expired_amt_td
        ,total_paid_credit_expired_amt_usd_td
from    mp_paidads.dws_advertiser_credit_expiry_td__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;
create or replace temporary view checkout_cnt as
select  tz_type
            ,grass_region
            ,shop_id
            ,SUM(checkout_cnt) AS checkout_cnt
    from    mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = DATE('${grass_date}')
    group by 1, 2, 3;

cache table deduction_1d OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  shop_id
        ,STRUCT(paid_expenditure_wo_expiry_amt_local_1d     AS paid_expenditure_wo_expiry_amt_local, paid_expenditure_wo_expiry_amt_usd_1d      AS paid_expenditure_wo_expiry_amt_usd, paid_expenditure_w_expiry_amt_local_1d     AS paid_expenditure_w_expiry_amt_local, paid_expenditure_w_expiry_amt_usd_1d       AS paid_expenditure_w_expiry_amt_usd, free_expenditure_wo_expiry_amt_local_1d    AS free_expenditure_wo_expiry_amt_local, free_expenditure_wo_expiry_amt_usd_1d      AS free_expenditure_wo_expiry_amt_usd, free_expenditure_w_expiry_amt_local_1d     AS free_expenditure_w_expiry_amt_local, free_expenditure_w_expiry_amt_usd_1d       AS free_expenditure_w_expiry_amt_usd) AS paid_free_ads_expenditure_struct_1d
        ,paid_expenditure_wo_expiry_amt_local_1d
        ,paid_expenditure_wo_expiry_amt_usd_1d
        ,paid_expenditure_w_expiry_amt_local_1d
        ,paid_expenditure_w_expiry_amt_usd_1d
        ,free_expenditure_wo_expiry_amt_local_1d
        ,free_expenditure_wo_expiry_amt_usd_1d
        ,free_expenditure_w_expiry_amt_local_1d
        ,free_expenditure_w_expiry_amt_usd_1d
        ,grass_region
        ,tz_type
from    mp_paidads.dws_advertiser_deduction_1d__reg_s0_live
where   grass_region = upper('${region}')
  and   grass_date = DATE('${grass_date}')
;
cache table ads_broad_nd OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
select  tz_type
        ,grass_region
        ,shop_id 
        ,SUM(CASE WHEN is_today = 1 THEN broad_order_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_usd_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_order_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_usd_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_order_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_usd_30d
        ,SUM(CASE WHEN is_60d = 1 THEN broad_order_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_usd_60d
        ,SUM(CASE WHEN is_90d = 1 THEN broad_order_gmv_amt_usd ELSE 0.0 END ) AS ads_broad_gmv_usd_90d
        ,SUM(CASE WHEN is_today = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_1d
        ,SUM(CASE WHEN is_7d = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_7d
        ,SUM(CASE WHEN is_30d = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_30d
        ,SUM(CASE WHEN is_60d = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_60d
        ,SUM(CASE WHEN is_90d = 1 THEN broad_order_cnt ELSE 0 END ) AS ads_broad_order_90d
FROM (
    SELECT  tz_type
            ,grass_region
            ,shop_id
            ,broad_order_gmv_amt_usd
            ,broad_order_cnt
            ,CASE WHEN grass_date = '${grass_date}' THEN 1 ELSE 0 END AS is_today
            ,CASE WHEN grass_date BETWEEN (DATE '${grass_date}' - INTERVAL 6 DAYS) AND DATE '${grass_date}' THEN 1 ELSE 0 END AS is_7d
            ,CASE WHEN grass_date BETWEEN (DATE '${grass_date}' - INTERVAL 29 DAYS) AND DATE '${grass_date}' THEN 1 ELSE 0 END AS is_30d
            ,CASE WHEN grass_date BETWEEN (DATE '${grass_date}' - INTERVAL 59 DAYS) AND DATE '${grass_date}'  THEN 1 ELSE 0 END AS is_60d
            ,CASE WHEN grass_date BETWEEN (DATE '${grass_date}' - INTERVAL 89 DAYS) AND DATE '${grass_date}' THEN 1 ELSE 0 END AS is_90d
            ,grass_date
            ,grass_region
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 89 DAYS) AND DATE('${grass_date}')
)
GROUP BY 1, 2, 3
;

insert overwrite table ads_advertiser_mkt_1d__reg_s0_live partition (tz_type, grass_region, grass_date)
select  dim.user_id
        ,dim.user_name
        ,dim.shop_id
        ,dim.language
        ,dim.status
        ,dim.country
        ,dim.create_datetime
        ,dim.modify_datetime
        ,dim.beetalk_userid
        ,dim.account_create_datetime
        ,dim.account_modify_datetime
        ,dim.account_status
        ,dim.is_seller
        ,dim.is_cb_seller
        ,dim.is_managed_seller
        ,dim.is_official_shop
        ,dim.is_preferred_shop
        ,case   when topup1d.shop_id is not null then 1
                else 0
         end as has_topup
        ,topup1d.total_topup_amt as total_topup_amt_1d
        ,topupnd.total_topup_amt_7d
        ,topupnd.total_topup_amt_30d
        ,topupnd.total_topup_amt_60d
        ,topup1d.total_topup_amt_usd as total_topup_amt_usd_1d
        ,topupnd.total_topup_amt_usd_7d
        ,topupnd.total_topup_amt_usd_30d
        ,topupnd.total_topup_amt_usd_60d
        ,topup1d.manual_topup_amt as manual_topup_amt_1d
        ,topupnd.manual_topup_amt_7d
        ,topupnd.manual_topup_amt_30d
        ,topupnd.manual_topup_amt_60d
        ,topup1d.manual_topup_amt_usd as manual_topup_amt_usd_1d
        ,topupnd.manual_topup_amt_usd_7d
        ,topupnd.manual_topup_amt_usd_30d
        ,topupnd.manual_topup_amt_usd_60d
        ,topup1d.manual_free_credit_topup_amt as manual_free_credit_topup_amt_1d
        ,topupnd.manual_free_credit_topup_amt_7d
        ,topupnd.manual_free_credit_topup_amt_30d
        ,topupnd.manual_free_credit_topup_amt_60d
        ,topup1d.manual_free_credit_topup_amt_usd as manual_free_credit_topup_amt_usd_1d
        ,topupnd.manual_free_credit_topup_amt_usd_7d
        ,topupnd.manual_free_credit_topup_amt_usd_30d
        ,topupnd.manual_free_credit_topup_amt_usd_60d
        ,topup1d.manual_paid_credit_topup_amt as manual_paid_credit_topup_amt_1d
        ,topupnd.manual_paid_credit_topup_amt_7d
        ,topupnd.manual_paid_credit_topup_amt_30d
        ,topupnd.manual_paid_credit_topup_amt_60d
        ,topup1d.manual_paid_credit_topup_amt_usd as manual_paid_credit_topup_amt_usd_1d
        ,topupnd.manual_paid_credit_topup_amt_usd_7d
        ,topupnd.manual_paid_credit_topup_amt_usd_30d
        ,topupnd.manual_paid_credit_topup_amt_usd_60d
        ,topup1d.auto_topup_amt as auto_topup_amt_1d
        ,topupnd.auto_topup_amt_7d
        ,topupnd.auto_topup_amt_30d
        ,topupnd.auto_topup_amt_60d
        ,topup1d.auto_topup_amt_usd as auto_topup_amt_usd_1d
        ,topupnd.auto_topup_amt_usd_7d
        ,topupnd.auto_topup_amt_usd_30d
        ,topupnd.auto_topup_amt_usd_60d
        ,topup1d.normal_amt_local as normal_topup_amt_1d
        ,topupnd.normal_amt_local_7d
        ,topupnd.normal_amt_local_30d
        ,topupnd.normal_amt_local_60d
        ,topup1d.normal_amt_usd as normal_topup_amt_usd_1d
        ,topupnd.normal_amt_usd_7d
        ,topupnd.normal_amt_usd_30d
        ,topupnd.normal_amt_usd_60d
        ,topup1d.seller_mission_topup_amt as seller_mission_topup_amt_1d
        ,topupnd.seller_mission_topup_amt_7d
        ,topupnd.seller_mission_topup_amt_30d
        ,topupnd.seller_mission_topup_amt_60d
        ,topup1d.seller_mission_topup_amt_usd as seller_mission_topup_amt_usd_1d
        ,topupnd.seller_mission_topup_amt_usd_7d
        ,topupnd.seller_mission_topup_amt_usd_30d
        ,topupnd.seller_mission_topup_amt_usd_60d
        ,topup1d.srm_topup_amt as srm_topup_amt_1d
        ,topupnd.srm_topup_amt_7d
        ,topupnd.srm_topup_amt_30d
        ,topupnd.srm_topup_amt_60d
        ,topup1d.srm_topup_amt_usd as srm_topup_amt_usd_1d
        ,topupnd.srm_topup_amt_usd_7d
        ,topupnd.srm_topup_amt_usd_30d
        ,topupnd.srm_topup_amt_usd_60d
        ,topup1d.neg_topup_amt as neg_topup_amt_1d
        ,topupnd.neg_topup_amt_7d
        ,topupnd.neg_topup_amt_30d
        ,topupnd.neg_topup_amt_60d
        ,topup1d.neg_topup_amt_usd as neg_topup_amt_usd_1d
        ,topupnd.neg_topup_amt_usd_7d
        ,topupnd.neg_topup_amt_usd_30d
        ,topupnd.neg_topup_amt_usd_60d
        ,case   when COALESCE(active.active_ads_cnt, 0) >= 1 then 1
                else 0
         end as has_active_ads
        ,case   when ads_perf.impression_cnt_1d + ads_perf.click_cnt_1d + ads_perf.expenditure_amt_local_1d + ads_perf.ads_gmv_amt_local_1d + ads_perf.order_cnt_1d > 0 then 1
                else 0
         end as has_performance
        ,case   when COALESCE(active.active_ads_cnt, 0) >= 1 then 1
                when ads_perf.impression_cnt_1d + ads_perf.click_cnt_1d + ads_perf.expenditure_amt_local_1d + ads_perf.ads_gmv_amt_local_1d + ads_perf.order_cnt_1d > 0 then 1
                else 0
         end as is_active_ads_seller
        ,balance.low_threshold
        ,balance.low_threshold_usd
        ,COALESCE(balance.is_reach_threshold, 0) as is_reach_low_threshold
        ,impression_cnt_1d
        ,impression_cnt_7d
        ,impression_cnt_30d
        ,impression_cnt_60d
        ,impression_cnt_90d
        ,click_cnt_1d
        ,click_cnt_7d
        ,click_cnt_30d
        ,click_cnt_60d
        ,click_cnt_90d
        ,expenditure_amt_local_1d
        ,expenditure_amt_local_7d
        ,expenditure_amt_local_30d
        ,expenditure_amt_local_60d
        ,expenditure_amt_local_90d
        ,expenditure_amt_usd_1d
        ,expenditure_amt_usd_7d
        ,expenditure_amt_usd_30d
        ,expenditure_amt_usd_60d
        ,expenditure_amt_usd_90d
        ,ads_gmv_amt_local_1d
        ,ads_gmv_amt_local_7d
        ,ads_gmv_amt_local_30d
        ,ads_gmv_amt_local_60d
        ,ads_gmv_amt_local_90d
        ,ads_gmv_amt_usd_1d
        ,ads_gmv_amt_usd_7d
        ,ads_gmv_amt_usd_30d
        ,ads_gmv_amt_usd_60d
        ,ads_gmv_amt_usd_90d
        ,ads_perf.order_cnt_1d
        ,ads_perf.order_cnt_7d
        ,ads_perf.order_cnt_30d
        ,ads_perf.order_cnt_60d
        ,ads_perf.order_cnt_90d
        ,ads_perf.paid_order_cnt_ytd_1d
        ,ads_perf.confirmed_order_cnt_ytd_1d
        ,plat.order_item_cnt_1d as platform_order_cnt_1d
        ,plat.order_item_cnt_7d as platform_order_cnt_7d
        ,plat.order_item_cnt_30d as platform_order_cnt_30d
        ,plat.order_item_cnt_60d as platform_order_cnt_60d
        ,plat.order_item_cnt_90d as platform_order_cnt_90d
        ,ads_items_sold_cnt_1d
        ,ads_items_sold_cnt_7d
        ,ads_items_sold_cnt_30d
        ,ads_items_sold_cnt_60d
        ,ads_items_sold_cnt_90d
        ,plat.items_sold_cnt_1d as platform_items_sold_cnt_1d
        ,plat.items_sold_cnt_7d as platform_items_sold_cnt_7d
        ,plat.items_sold_cnt_30d as platform_items_sold_cnt_30d
        ,plat.items_sold_cnt_60d as platform_items_sold_cnt_60d
        ,plat.items_sold_cnt_90d as platform_items_sold_cnt_90d
        ,plat.gmv_1d as platform_gmv_amt_1d
        ,plat.gmv_7d as platform_gmv_amt_7d
        ,plat.gmv_30d as platform_gmv_amt_30d
        ,plat.gmv_60d as platform_gmv_amt_60d
        ,plat.gmv_90d as platform_gmv_amt_90d
        ,plat.gmv_usd_1d as platform_gmv_usd_amt_1d
        ,plat.gmv_usd_7d as platform_gmv_usd_amt_7d
        ,plat.gmv_usd_30d as platform_gmv_usd_amt_30d
        ,plat.gmv_usd_60d as platform_gmv_usd_amt_60d
        ,plat.gmv_usd_90d as platform_gmv_usd_amt_90d
        ,cat1.l1cat_ads_expenditure_amt_1d
        ,cat1.l1cat_ads_expenditure_amt_usd_1d
        ,cat1.l1cat_ads_gmv_amt_1d
        ,cat1.l1cat_ads_gmv_amt_usd_1d
        ,cat2.l2cat_ads_expenditure_amt_1d
        ,cat2.l2cat_ads_expenditure_amt_usd_1d
        ,cat2.l2cat_ads_gmv_amt_1d
        ,cat2.l2cat_ads_gmv_amt_usd_1d
        ,bal.free_credit_w_expiry_eod_balance_amt_td
        ,bal.free_credit_w_expiry_eod_balance_amt_usd_td
        ,bal.free_credit_wo_expiry_eod_balance_amt_td
        ,bal.free_credit_wo_expiry_eod_balance_amt_usd_td
        ,bal.paid_credit_w_expiry_eod_balance_amt_td
        ,bal.paid_credit_w_expiry_eod_balance_amt_usd_td
        ,bal.paid_credit_wo_expiry_eod_balance_amt_td
        ,bal.paid_credit_wo_expiry_eod_balance_amt_usd_td
        ,bal.paid_credit_wo_expiry_sod_balance_amt_td
        ,bal.paid_credit_wo_expiry_sod_balance_amt_usd_td
        ,bal.total_eod_balance_td
        ,bal.total_eod_balance_usd_td
        ,credit.manual_free_credit_expired_amt_td
        ,credit.manual_free_credit_expired_amt_usd_td
        ,credit.manual_paid_credit_expired_amt_td
        ,credit.manual_paid_credit_expired_amt_usd_td
        ,credit.seller_mission_free_credit_expired_amt_td
        ,credit.seller_mission_free_credit_expired_amt_usd_td
        ,credit.seller_mission_paid_credit_expired_amt_td
        ,credit.seller_mission_paid_credit_expired_amt_usd_td
        ,credit.srm_free_credit_expired_amt_td
        ,credit.srm_free_credit_expired_amt_usd_td
        ,credit.srm_paid_credit_expired_amt_td
        ,credit.srm_paid_credit_expired_amt_usd_td
        ,credit.total_free_credit_expired_amt_td
        ,credit.total_free_credit_expired_amt_usd_td
        ,credit.total_paid_credit_expired_amt_td
        ,credit.total_paid_credit_expired_amt_usd_td
        ,cast(td.last_active_date as DATE) as last_active_date
        ,cast(first_active.first_mm_kw_ads_active_date as DATE) as first_mm_kw_ads_active_date
        ,cast(first_active.first_sm_kw_ads_active_date as DATE) as first_sm_kw_ads_active_date
        ,dim.is_auto_topup_enabled
        ,dim.is_campaign_auto_bid_enabled
        ,dim.shop_level1_global_be_category
        ,dim.shop_level1_fe_display_category
        ,dim.shop_level1_kpi_category
        ,dim.shop_level2_global_be_category
        ,dim.shop_level2_fe_display_category
        ,dim.shop_level2_kpi_category
        ,checkout_cnt
        ,to_json(deduction_1d.paid_free_ads_expenditure_struct_1d) as paid_free_ads_expenditure_struct_1d
        ,deduction_1d.paid_expenditure_wo_expiry_amt_local_1d
        ,deduction_1d.paid_expenditure_wo_expiry_amt_usd_1d
        ,deduction_1d.paid_expenditure_w_expiry_amt_local_1d
        ,deduction_1d.paid_expenditure_w_expiry_amt_usd_1d
        ,deduction_1d.free_expenditure_wo_expiry_amt_local_1d
        ,deduction_1d.free_expenditure_wo_expiry_amt_usd_1d
        ,deduction_1d.free_expenditure_w_expiry_amt_local_1d
        ,deduction_1d.free_expenditure_w_expiry_amt_usd_1d
        ,ads_broad_nd.ads_broad_gmv_usd_1d
        ,ads_broad_nd.ads_broad_gmv_usd_7d
        ,ads_broad_nd.ads_broad_gmv_usd_30d
        ,ads_broad_nd.ads_broad_gmv_usd_60d
        ,ads_broad_nd.ads_broad_gmv_usd_90d
        ,ads_broad_nd.ads_broad_order_1d
        ,ads_broad_nd.ads_broad_order_7d
        ,ads_broad_nd.ads_broad_order_30d
        ,ads_broad_nd.ads_broad_order_60d
        ,ads_broad_nd.ads_broad_order_90d
        ,dim.is_self_mcn
        ,dim.tz_type
        ,dim.grass_region as grass_region
        ,DATE('${grass_date}') as grass_date
from    dim
left outer join  active
on      (
        dim.shop_id = active.shop_id
    and dim.grass_region = active.grass_region
)
left outer join  first_active
on      (
        dim.shop_id = first_active.shop_id
    and dim.grass_region = first_active.grass_region
)
left outer join plat
on      (
        dim.user_id = plat.user_id
    and dim.grass_region = plat.grass_region
)
left outer join  balance
on      (
        dim.shop_id = balance.shop_id
    and dim.grass_region = balance.grass_region
)
left outer join topup1d
on      (
        dim.shop_id = topup1d.shop_id
    and dim.grass_region = topup1d.region
    and dim.tz_type = topup1d.tz_type
)
left outer join topupnd
on      (
        dim.shop_id = topupnd.shop_id
    and dim.grass_region = topupnd.region
    and dim.tz_type = topupnd.tz_type
)
left outer join ads_perf
on      (
        dim.shop_id = ads_perf.shop_id
    and dim.grass_region = ads_perf.grass_region
    and dim.tz_type = ads_perf.tz_type
)
left outer join cat1
on      (
        dim.shop_id = cat1.shop_id
    and dim.grass_region = cat1.grass_region
    and dim.tz_type = cat1.tz_type
    and lower(dim.shop_level1_global_be_category) = lower(cat1.level1_global_be_category)
)
left outer join cat2
on      (
        dim.shop_id = cat2.shop_id
    and dim.grass_region = cat2.grass_region
    and dim.tz_type = cat2.tz_type
    and lower(dim.shop_level2_global_be_category) = lower(cat2.level2_global_be_category)
)
left outer join td
on      (
        dim.shop_id = td.shop_id
    and dim.grass_region = td.grass_region
    and dim.tz_type = td.tz_type
)
left outer join bal
on      (
        dim.shop_id = bal.shop_id
    and dim.grass_region = bal.grass_region
    and dim.tz_type = bal.tz_type
)
left outer join credit
on      (
        dim.shop_id = credit.shop_id
    and dim.grass_region = credit.grass_region
    and dim.tz_type = credit.tz_type
)
left outer join checkout_cnt
on      (
        dim.shop_id = checkout_cnt.shop_id
    and dim.grass_region = checkout_cnt.grass_region
    and dim.tz_type = checkout_cnt.tz_type
)
left outer join deduction_1d
on      (
        dim.shop_id = deduction_1d.shop_id
    and dim.grass_region = deduction_1d.grass_region
    and dim.tz_type = deduction_1d.tz_type
)
left outer join ads_broad_nd
on (
        dim.shop_id = ads_broad_nd.shop_id
    and dim.grass_region = ads_broad_nd.grass_region
    and dim.tz_type = ads_broad_nd.tz_type
)
;

alter table ads_advertiser_mkt_1d__${region}_s0_live add if not exists partition(grass_date = "${grass_date}")
;