-- task_code: data_paidadsmart.studio_10315857  asset_id: 10315857
--step0 cm table 
create or replace temporary view central_base as
select
    grass_date
    ,order_id
    ,item_id
    ,model_id
    ,group_id
    ,bundle_order_item_id
    -- table has is_cb_shop and is_official_shop flags, can also group by accordingly without using local_c2c/local_mall/cb_xx fields
    ,coalesce(estimate_mandatory_commission_fee_usd_level1, 0) as estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
    ,coalesce(estimate_local_c2c_mandatory_commission_fee_usd_level1, 0) as estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
    ,coalesce(estimate_local_mall_mandatory_commission_fee_usd_level1, 0) as estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
    ,coalesce(estimate_cb_mandatory_commission_fee_usd_level1, 0) as estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
    ,coalesce(estimate_optional_commission_fee_usd_level1, 0) as estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
    ,coalesce(estimate_local_c2c_optional_commission_fee_usd_level1, 0) as estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
    ,coalesce(estimate_local_mall_optional_commission_fee_usd_level1, 0) as estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
    ,coalesce(estimate_cb_optional_commission_fee_usd_level1, 0) as estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
    ,coalesce(estimate_buyer_handling_fee_usd_level1, 0) + coalesce(estimate_seller_handling_fee_usd_level1, 0) as handling_fee_usd -- Handling Fees
    ,coalesce(estimate_seller_handling_fee_usd_level1, 0) as estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
    ,coalesce(estimate_buyer_handling_fee_usd_level1, 0) as estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
    -- todo1  ?check other revenue source?
    ,estimate_other_revenue_usd_level2 -- Other Revenue                            
from mp_mgmt.dws_order_item_rev_di__reg_s0_live
where
    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
    and grass_region = upper('${region}')
    and is_bi_excluded_rev_prm = 0
;

create or replace temporary view rebate_base as
select
    grass_date
    ,order_id
    ,item_id
    ,model_id
    ,group_id
    ,bundle_order_item_id
    ,coalesce(estimate_net_total_item_voucher_logst_prm_usd_level1, 0) as estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
    ,coalesce(estimate_net_total_logst_prm_usd_level1, 0) as estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
    ,coalesce(estimate_net_total_item_card_prm_usd_level1, 0) as estimate_net__total_item_card_prm_usd_level1 -- Item PRM
    ,coalesce(estimate_net_total_voucher_prm_usd_level1, 0) as estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
    ,coalesce(estimate_net_total_coin_prm_usd_level1, 0) as estimate_net__total_coin_prm_usd_level1 -- Coin PRM
from mp_mgmt.dws_order_item_rebate_di__reg_s0_live
where
    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
    and grass_region = upper('${region}')
    and is_bi_excluded_rev_prm = 0
;

--step1 omni table 
create or replace temporary view omni_base as
select
    grass_date
    ,order_id
    ,item_id
    ,model_id
    ,group_id
    ,bundle_order_item_id
    ,user_id
    ,common_feature
    ,sum(coalesce(gmv_usd*atc_prorate*first_touchpoint_item, 0)) as gmv_usd
from
    (
        --step 0
        select
            grass_date
            ,grass_region
            ,user_id
            ,order_item_id as item_id
            ,order_model_id as model_id
            ,group_id
            ,bundle_order_item_id
            ,shop_id
            ,gmv_usd
            ,gmv
            ,atc_prorate
            ,first_touchpoint_item
            ,order_fraction
            ,order_id
            ,case
                when (
                    (
                        feature_detail_omni like '%-shop_item'
                            and feature_group_omni = 'Search'
                    )
                        or (
                        feature_group_omni in (
                            'Shop Main Browsing'
                            ,'Shop'
                            ,'Shop Other Recommendations'
                            ,'Shop Product Tab'
                            ,'Shop Recommended For You'
                        )
                            and source1_feature_detail_omni = 'search-shop'
                    )
                )
                    then source1_common_property.is_ads
                else click_common_property.is_ads
            end as is_ads
            ,click_location_property.location as location
            ,case
                when (
                    (
                        feature_detail_omni like '%-shop_item'
                            and feature_group_omni = 'Search'
                    )
                        or (
                        feature_group_omni in (
                            'Shop Main Browsing'
                            ,'Shop'
                            ,'Shop Other Recommendations'
                            ,'Shop Product Tab'
                            ,'Shop Recommended For You'
                        )
                            and source1_feature_detail_omni = 'search-shop'
                    )
                )
                    then 'Search Shop'
                when ((module = 'Global Search')) then 'Global Search'
                when ((module = 'Image Search')) then 'Image Search'
                when ((feature_group_omni = 'You May Also Like')) then 'You May Also Like'
                when (feature_group_omni = 'Live Streaming') then 'Live Streaming'
                when feature_group_omni = 'Order Successful Recommendation' then 'Order Successful Recommendation'
                when feature_group_omni = 'Cart Recommendation' then 'Cart Recommendation'
                when ((feature_omni = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
                when feature_omni = 'odp_ymal-order_detail' then 'Order Detail Page Recommendation'
                when ((module = 'Daily Discover')) then 'Daily Discover'
                when feature_group_omni = 'Games' then 'Games'
                when feature_group_omni = 'Video' then 'Video'
                when feature_detail_omni = 'me-you_may_also_like-item' then 'Me YMAL'
                when feature_omni = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
                when feature_omni = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
                when feature_detail_omni = 'shop-you_may_also_like-item' then 'Shop YMAL'
                when feature_group_omni = 'Buy Again (Me Page)' and business_line='Rcmd' and module='User Scenario' then 'Buy Again (Me Page)'
                else 'Others'
            end as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type = 'local'
            and user_id > 0
        union all
        --step 1
        select
            grass_date
            ,grass_region
            ,user_id
            ,order_item_id as item_id
            ,order_model_id as model_id
            ,group_id
            ,bundle_order_item_id
            ,shop_id
            ,gmv_usd
            ,gmv
            ,atc_prorate
            ,first_touchpoint_item
            ,order_fraction
            ,order_id
            ,source1_common_property.is_ads as is_ads
            ,source1_location_property.location as location
            ,case
                when ((source1_module = 'Global Search')) then 'Global Search'
                when ((source1_module = 'Image Search')) then 'Image Search'
                when ((source1_feature_group_omni = 'You May Also Like')) then 'You May Also Like'
                when (source1_feature_group_omni = 'Live Streaming') then 'Live Streaming'
                when ((source1_feature_omni = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
                when ((source1_module = 'Daily Discover')) then 'Daily Discover'
                when source1_feature_group_omni = 'Order Successful Recommendation' then 'Order Successful Recommendation'
                when source1_feature_omni = 'odp_ymal-order_detail' then 'Order Detail Page Recommendation'
                when source1_feature_group_omni = 'Games' then 'Games'
                when source1_feature_omni = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
                when source1_feature_omni = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
                when source1_feature_detail_omni = 'shop-you_may_also_like-item' then 'Shop YMAL'
                else 'Others'
            end as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type = 'local'
            and user_id > 0
        union all
        --step 2
        select
            grass_date
            ,grass_region
            ,user_id
            ,order_item_id as item_id
            ,order_model_id as model_id
            ,group_id
            ,bundle_order_item_id
            ,shop_id
            ,gmv_usd
            ,gmv
            ,atc_prorate
            ,first_touchpoint_item
            ,order_fraction
            ,order_id
            ,source2_common_property.is_ads as is_ads
            ,source2_location_property.location as location
            ,case
                when ((source2_module = 'Global Search')) then 'Global Search'
                when ((source2_module = 'Image Search')) then 'Image Search'
                when ((source2_feature_group_omni = 'You May Also Like')) then 'You May Also Like'
                when (source2_feature_group_omni = 'Live Streaming') then 'Live Streaming'
                when ((source2_feature_omni = 'mpp_ymal-order_list')) then 'My Purchase Page Recommendation'
                when ((source2_module = 'Daily Discover')) then 'Daily Discover'
                when source2_feature_group_omni = 'Order Successful Recommendation' then 'Order Successful Recommendation'
                when source2_feature_omni = 'odp_ymal-order_detail' then 'Order Detail Page Recommendation'
                when source2_feature_group_omni = 'Games' then 'Games'
                when source2_feature_omni = 'voucher-voucher_landing' then 'Voucher Landing Recommendation'
                when source2_feature_omni = 'crm_omni_attri-hot_deals_landing' then 'Hot Deals Landing Recommendation'
                when source2_feature_detail_omni = 'shop-you_may_also_like-item' then 'Shop YMAL'
                else 'Others'
            end as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type = 'local'
            and user_id > 0
        union all
        --all steps
        select
            grass_date
            ,grass_region
            ,user_id
            ,order_item_id as item_id
            ,order_model_id as model_id
            ,group_id
            ,bundle_order_item_id
            ,shop_id
            ,gmv_usd
            ,gmv
            ,atc_prorate
            ,first_touchpoint_item
            ,order_fraction
            ,order_id
            ,(
                click_common_property.is_ads
                or source1_common_property.is_ads
                or source2_common_property.is_ads
            ) as is_ads
            ,coalesce(
                click_location_property.location
                ,source1_location_property.location
                ,source2_location_property.location
            ) as location
            ,'Platform' as common_feature
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type = 'local'
            and user_id > 0
    ) group by 1,2,3,4,5,6,7,8
;

--step1.5 make common_feature
create or replace temporary view omni_central_rebate_base as
select
    omni.grass_date
    ,omni.user_id
    ,omni.item_id
    ,omni.common_feature
    ,sum(omni_gmv_usd) as omni_gmv_usd
    ,sum(estimate_mandatory_commission_fee_usd_level1_1d) as estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
    ,sum(estimate_local_c2c_mandatory_commission_fee_usd_level1_1d) as estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
    ,sum(estimate_local_mall_mandatory_commission_fee_usd_level1_1d) as estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
    ,sum(estimate_cb_mandatory_commission_fee_usd_level1_1d) as estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
    ,sum(estimate_optional_commission_fee_usd_level1_1d) as estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
    ,sum(estimate_local_c2c_optional_commission_fee_usd_level1_1d) as estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
    ,sum(estimate_local_mall_optional_commission_fee_usd_level1_1d) as estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
    ,sum(estimate_cb_optional_commission_fee_usd_level1_1d) as estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
    ,sum(handling_fee_usd) as handling_fee_usd -- Handling Fees
    ,sum(estimate_seller_handling_fee_usd_level1_1d) as estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
    ,sum(estimate_buyer_handling_fee_usd_level1_1d) as estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
    ,sum(estimate_net__total_item_voucher_logst_prm_usd_level1) as estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
    ,sum(estimate_net__total_logst_prm_usd_level1) as estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
    ,sum(estimate_net__total_item_card_prm_usd_level1) as estimate_net__total_item_card_prm_usd_level1 -- Item PRM
    ,sum(estimate_net__total_voucher_prm_usd_level1) as estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
    ,sum(estimate_net__total_coin_prm_usd_level1) as estimate_net__total_coin_prm_usd_level1 -- Coin PRM
from
    (
        select
            grass_date
            ,order_id
            ,item_id
            ,model_id
            ,group_id
            ,bundle_order_item_id
            ,user_id
            ,gmv_usd as omni_gmv_usd
            ,common_feature
        from omni_base
    ) omni
    left join (
        select
            *
        from central_base
    ) central on omni.order_id = central.order_id
    and omni.item_id = central.item_id
    and omni.model_id = central.model_id
    and omni.group_id = central.group_id
    and omni.bundle_order_item_id = central.bundle_order_item_id
    and omni.grass_date = central.grass_date
    left join (
        select
            *
        from rebate_base
    ) rebate on omni.order_id = rebate.order_id
    and omni.item_id = rebate.item_id
    and omni.model_id = rebate.model_id
    and omni.group_id = rebate.group_id
    and omni.bundle_order_item_id = rebate.bundle_order_item_id
    and omni.grass_date = rebate.grass_date
group by 1, 2, 3, 4
;

--step2 performance_table left join dim_common_feture get ads performance
create or replace temporary view ads_base as
select
    grass_date
    ,user_id
    ,common_feature
    ,item_id
    ,sum(coalesce(expenditure_amt_usd,0)) as paid_ads_revenue_usd_1d
    ,sum(coalesce(broad_gmv_amt_usd,0)) as paid_ads_broad_gmv_usd_1d
from
    (
        select
            grass_date
            ,user_id
            ,item_id
            ,coalesce(common_feature_mapping1.common_feature, 'Others') as common_feature
            ,coalesce(expenditure_amt_usd, 0) as expenditure_amt_usd
            ,coalesce(broad_gmv_amt_usd, 0) as broad_gmv_amt_usd
        from
            (
                select
                    grass_date
                    ,user_id
                    ,item_id
                    ,entrance
                    ,expenditure_amt_usd
                    ,broad_gmv_amt_usd
                from mp_paidads.dwd_advertise_performance_di__reg_s0_live
                where
                    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
                    and grass_region = upper('${region}')
                    and (expenditure_amt_usd>0 or broad_gmv_amt_usd>0)
            ) ads_base
            left outer join (
                select
                    entrance
                    ,common_feature
                from mp_paidads.dim_common_feature_mapping_v2__reg_s0_live
            ) common_feature_mapping1 on ads_base.entrance = common_feature_mapping1.entrance
        union all
        select
            grass_date
            ,user_id
            ,item_id
            ,'Platform' as common_feature
            ,expenditure_amt_usd
            ,broad_gmv_amt_usd
        from
            (
                select
                    grass_date
                    ,user_id
                    ,item_id
                    ,entrance
                    ,coalesce(expenditure_amt_usd, 0) as expenditure_amt_usd
                    ,coalesce(broad_gmv_amt_usd, 0) as broad_gmv_amt_usd
                from mp_paidads.dwd_advertise_performance_di__reg_s0_live
                where
                    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
                    and grass_region = upper('${region}')
                    and (expenditure_amt_usd>0 or broad_gmv_amt_usd>0)
            )
    )
group by 1,2,3,4
;

--step2.5 user_net_rev_table left join dim_common_feture get net ads rev
create or replace temporary view net_rev_base as
select
    grass_date
    ,user_id
    ,common_feature
    ,item_id
    ,sum(coalesce(net_ads_revenue_usd_1d,0)) as paid_ads_net_revenue_usd_1d
from
    (
        select
            grass_date
            ,user_id
            ,item_id
            ,coalesce(common_feature_mapping1.common_feature, 'Others') as common_feature
            ,coalesce(net_ads_revenue_usd_1d, 0) as net_ads_revenue_usd_1d
        from
            (
                select
                    grass_date
                    ,user_id
                    ,item_id
                    ,entrance
                    ,net_ads_revenue_usd_1d
                from mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live
                where
                    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
                    and grass_region = upper('${region}')
                    and tz_type='local'
            ) ads_base
            left outer join (
                select
                    entrance
                    ,common_feature
                from mp_paidads.dim_common_feature_mapping_v2__reg_s0_live
            ) common_feature_mapping1 on ads_base.entrance = common_feature_mapping1.entrance
        union all
        select
            grass_date
            ,user_id
            ,item_id
            ,'Platform' as common_feature
            ,net_ads_revenue_usd_1d
        from
            (
                select
                    grass_date
                    ,user_id
                    ,item_id
                    ,entrance
                    ,net_ads_revenue_usd_1d
                from mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live
                where
                    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
                    and grass_region = upper('${region}')
                    and tz_type='local'
            )
    )
group by 1,2,3,4
;

--step3 ads_voucher left join dim_common_feture get ads voucher
create or replace temporary view ads_voucher_base as
select
    grass_date
    ,user_id
    ,common_feature
    ,item_id
    ,sum(coalesce(ads_voucher_ads_part_amt_usd, 0)) as paid_ads_voucher_ads_part_amt_usd_1d
from
    (
        select
            grass_date
            ,user_id
            ,item_id
            ,coalesce(common_feature_mapping1.common_feature, 'Others') as common_feature
            ,ads_voucher_ads_part_amt_usd
        from
            (
                select
                    grass_date
                    ,user_id
                    ,match_voucher_click_entrance as entrance
                    ,item_id
                    ,ads_voucher_amt_usd * (1 - coalesce(voucher_cofund_ratio, 0)) as ads_voucher_ads_part_amt_usd
                from mp_paidads.ads_order_voucher_1d__reg_s0_live
                where
                    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
                    and grass_region = upper('${region}') and tz_type='local'
            ) ads_base
            left outer join (
                select
                    entrance
                    ,common_feature
                from mp_paidads.dim_common_feature_mapping_v2__reg_s0_live
            ) common_feature_mapping1 on ads_base.entrance = common_feature_mapping1.entrance
        union all
        select
            grass_date
            ,user_id
            ,item_id
            ,'Platform' as common_feature
            ,ads_voucher_ads_part_amt_usd
        from
            (
                select
                    grass_date
                    ,user_id
                    ,match_voucher_click_entrance as entrance
                    ,item_id
                    ,ads_voucher_amt_usd * (1 - coalesce(voucher_cofund_ratio, 0)) as ads_voucher_ads_part_amt_usd
                from mp_paidads.ads_order_voucher_1d__reg_s0_live
                where
                    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
                    and grass_region = upper('${region}') and tz_type='local'
            )
    )
group by 1,2,3,4
;

--step4 pc2
--drop table real_pc2;
cache table real_pc2 as
select
    all_base.grass_date as grass_date
    ,user_id
    ,all_base.item_id as item_id
    ,common_feature
    ,level2_global_be_category_id
    ,omni_gmv_usd
    ,estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
    ,estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
    ,estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
    ,estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
    ,estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
    ,estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
    ,estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
    ,estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
    ,handling_fee_usd -- Handling Fees
    ,estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
    ,estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
    ,estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
    ,estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
    ,estimate_net__total_item_card_prm_usd_level1 -- Item PRM
    ,estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
    ,estimate_net__total_coin_prm_usd_level1 -- Coin PRM
    ,pc2
    ,coalesce(paid_ads_revenue_usd_1d,0) as paid_ads_revenue_usd_1d
    ,coalesce(paid_ads_broad_gmv_usd_1d,0) as paid_ads_broad_gmv_usd_1d
    ,coalesce(paid_ads_voucher_ads_part_amt_usd_1d,0) as paid_ads_voucher_ads_part_amt_usd_1d
    ,coalesce(paid_ads_net_revenue_usd_1d,0) as paid_ads_net_revenue_usd_1d
    
from
(
    select
        grass_date
        ,user_id
        ,item_id
        ,common_feature
        ,SUM(omni_gmv_usd) as omni_gmv_usd
        ,SUM(estimate_mandatory_commission_fee_usd_level1_1d) as estimate_mandatory_commission_fee_usd_level1_1d  -- Mandatory Commissions
        ,SUM(estimate_local_c2c_mandatory_commission_fee_usd_level1_1d) as  estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
        ,SUM(estimate_local_mall_mandatory_commission_fee_usd_level1_1d) as estimate_local_mall_mandatory_commission_fee_usd_level1_1d  -- Mall Mandatory Commissions
        ,SUM(estimate_cb_mandatory_commission_fee_usd_level1_1d) as estimate_cb_mandatory_commission_fee_usd_level1_1d  -- CB Mandatory Commissions
        ,SUM(estimate_optional_commission_fee_usd_level1_1d) as estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
        ,SUM(estimate_local_c2c_optional_commission_fee_usd_level1_1d) as estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
        ,SUM(estimate_local_mall_optional_commission_fee_usd_level1_1d) as estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
        ,SUM(estimate_cb_optional_commission_fee_usd_level1_1d) as estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
        ,SUM(handling_fee_usd) as handling_fee_usd -- Handling Fees
        ,SUM(estimate_seller_handling_fee_usd_level1_1d) as estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
        ,SUM(estimate_buyer_handling_fee_usd_level1_1d) as estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
        ,SUM(estimate_net__total_item_voucher_logst_prm_usd_level1) as estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
        ,SUM(estimate_net__total_logst_prm_usd_level1) as estimate_net__total_logst_prm_usd_level1  -- Logistic PRM
        ,SUM(estimate_net__total_item_card_prm_usd_level1) as estimate_net__total_item_card_prm_usd_level1 -- Item PRM
        ,SUM(estimate_net__total_voucher_prm_usd_level1) as estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
        ,SUM(estimate_net__total_coin_prm_usd_level1) as estimate_net__total_coin_prm_usd_level1 -- Coin PRM
        ,SUM(estimate_mandatory_commission_fee_usd_level1_1d + estimate_optional_commission_fee_usd_level1_1d + handling_fee_usd + coalesce(paid_ads_net_revenue_usd_1d,0) - coalesce(paid_ads_voucher_ads_part_amt_usd_1d,0)) as pc2
        ,SUM(coalesce(paid_ads_revenue_usd_1d,0)) as paid_ads_revenue_usd_1d
        ,SUM(coalesce(paid_ads_broad_gmv_usd_1d,0)) as paid_ads_broad_gmv_usd_1d
        ,SUM(coalesce(paid_ads_voucher_ads_part_amt_usd_1d,0)) as paid_ads_voucher_ads_part_amt_usd_1d
        ,SUM(coalesce(paid_ads_net_revenue_usd_1d,0)) as paid_ads_net_revenue_usd_1d
        
    from
        (
            select
                grass_date
                ,user_id
                ,item_id
                ,common_feature
                ,omni_gmv_usd
                ,estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
                ,estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
                ,estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
                ,estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
                ,estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
                ,estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
                ,estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
                ,estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
                ,handling_fee_usd -- Handling Fees
                ,estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
                ,estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
                ,estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
                ,estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
                ,estimate_net__total_item_card_prm_usd_level1 -- Item PRM
                ,estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
                ,estimate_net__total_coin_prm_usd_level1 -- Coin PRM
                ,0 as paid_ads_revenue_usd_1d
                ,0 as paid_ads_broad_gmv_usd_1d
                ,0 as paid_ads_voucher_ads_part_amt_usd_1d
                ,0 as paid_ads_net_revenue_usd_1d
            from omni_central_rebate_base
        
        union all 
            select
                grass_date
                ,user_id
                ,item_id
                ,common_feature
                ,0 as omni_gmv_usd
                ,0 as estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
                ,0 as estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
                ,0 as estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
                ,0 as estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
                ,0 as estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
                ,0 as estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
                ,0 as estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
                ,0 as estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
                ,0 as handling_fee_usd -- Handling Fees
                ,0 as estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
                ,0 as estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
                ,0 as estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
                ,0 as estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
                ,0 as estimate_net__total_item_card_prm_usd_level1 -- Item PRM
                ,0 as estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
                ,0 as estimate_net__total_coin_prm_usd_level1 -- Coin PRM
                ,paid_ads_revenue_usd_1d
                ,paid_ads_broad_gmv_usd_1d
                ,0 as paid_ads_voucher_ads_part_amt_usd_1d
                ,0 as paid_ads_net_revenue_usd_1d
            from ads_base

        union all 
            select
                grass_date
                ,user_id
                ,item_id
                ,common_feature
                ,0 as omni_gmv_usd
                ,0 as estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
                ,0 as estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
                ,0 as estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
                ,0 as estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
                ,0 as estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
                ,0 as estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
                ,0 as estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
                ,0 as estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
                ,0 as handling_fee_usd -- Handling Fees
                ,0 as estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
                ,0 as estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
                ,0 as estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
                ,0 as estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
                ,0 as estimate_net__total_item_card_prm_usd_level1 -- Item PRM
                ,0 as estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
                ,0 as estimate_net__total_coin_prm_usd_level1 -- Coin PRM
                ,0 as paid_ads_revenue_usd_1d
                ,0 as paid_ads_broad_gmv_usd_1d
                ,0 as paid_ads_voucher_ads_part_amt_usd_1d
                ,paid_ads_net_revenue_usd_1d
            from net_rev_base


        union all 
            select
                grass_date
                ,user_id
                ,item_id
                ,common_feature
                ,0 as omni_gmv_usd
                ,0 as estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
                ,0 as estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
                ,0 as estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
                ,0 as estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
                ,0 as estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
                ,0 as estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
                ,0 as estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
                ,0 as estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
                ,0 as handling_fee_usd -- Handling Fees
                ,0 as estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
                ,0 as estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
                ,0 as estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
                ,0 as estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
                ,0 as estimate_net__total_item_card_prm_usd_level1 -- Item PRM
                ,0 as estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
                ,0 as estimate_net__total_coin_prm_usd_level1 -- Coin PRM
                ,0 as paid_ads_revenue_usd_1d
                ,0 as paid_ads_broad_gmv_usd_1d
                ,paid_ads_voucher_ads_part_amt_usd_1d
                ,0 as paid_ads_net_revenue_usd_1d
            from ads_voucher_base
            where paid_ads_voucher_ads_part_amt_usd_1d > 0
        ) group by 1,2,3,4
) all_base
    left join (
        select
            grass_date
            ,item_id
            ,level2_global_be_category_id
        from mp_item.dim_item__reg_s0_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type = 'local'
    ) item
    on all_base.item_id = item.item_id and all_base.grass_date = item.grass_date
;

create or replace temporary view item_pc2 as
select
    grass_date
    ,item_id
    ,level2_global_be_category_id
    ,sum(pc2) / sum(omni_gmv_usd) as item_pc2_rate
from real_pc2
where common_feature='Platform'
group by 1,2,3
;

create or replace temporary view category_pc2 as
select
    grass_date
    ,level2_global_be_category_id
    ,sum(pc2) / sum(omni_gmv_usd) as category_pc2_rate
from real_pc2
where common_feature='Platform'
group by 1,2
;

create or replace temporary view local_category_pc2 as
select
    grass_date
    ,level2_global_be_category_id
    ,sum(distinct pc2_rate) as local_category_pc2_rate
    ,sum(distinct pc2_rate_exp_v2) as local_pc2_rate_exp_v2
from traffic_omni_oa.dim_item_pc2_rate_map__reg_live
where
    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
    and grass_region = upper('${region}')
    and tz_type = 'local'
    group by 1,2
;

create or replace temporary view adjusted_item_pc2 as
select
   item.grass_date as grass_date
    ,item_id
    ,item_pc2_rate * (local_category_pc2_rate / category_pc2_rate) as adjusted_proxy_pc2_rate
    ,item_pc2_rate * (local_pc2_rate_exp_v2 / category_pc2_rate) as adjusted_proxy_pc2_rate_exp
from
    (
        select
            grass_date
            ,item_id
            ,level2_global_be_category_id
            ,item_pc2_rate
        from item_pc2
    ) item
    left join (
        select
            grass_date
            ,level2_global_be_category_id
            ,category_pc2_rate
        from category_pc2
    ) category on item.level2_global_be_category_id = category.level2_global_be_category_id and item.grass_date = category.grass_date
    left join (
        select
            grass_date
            ,level2_global_be_category_id
            ,local_category_pc2_rate
            ,local_pc2_rate_exp_v2
        from local_category_pc2
    ) as local_category on item.level2_global_be_category_id = local_category.level2_global_be_category_id and item.grass_date = local_category.grass_date
;

--step4 Adjusted Proxy PC2   left join dim_item get category info
create or replace temporary view output as
select
    common_feature
    ,user_id
    ,real.item_id
    ,omni_gmv_usd
    ,estimate_mandatory_commission_fee_usd_level1_1d + estimate_optional_commission_fee_usd_level1_1d + handling_fee_usd + paid_ads_net_revenue_usd_1d as estimate_mp_revenue_usd_1d
    ,estimate_mandatory_commission_fee_usd_level1_1d -- Mandatory Commissions
    ,estimate_local_c2c_mandatory_commission_fee_usd_level1_1d -- MP Mandatory Commissions
    ,estimate_local_mall_mandatory_commission_fee_usd_level1_1d -- Mall Mandatory Commissions
    ,estimate_cb_mandatory_commission_fee_usd_level1_1d -- CB Mandatory Commissions
    ,estimate_optional_commission_fee_usd_level1_1d -- Optional Commissions
    ,estimate_local_c2c_optional_commission_fee_usd_level1_1d -- MP Optional Commissions
    ,estimate_local_mall_optional_commission_fee_usd_level1_1d -- Mall Optional Commissions
    ,estimate_cb_optional_commission_fee_usd_level1_1d -- CB Optional Commissions
    ,handling_fee_usd -- Handling Fees
    ,estimate_seller_handling_fee_usd_level1_1d -- Seller Handling Fees
    ,estimate_buyer_handling_fee_usd_level1_1d -- Buyer Handling Fees
    ,estimate_net__total_item_voucher_logst_prm_usd_level1 -- PRM excl. 3PL Margin
    ,estimate_net__total_logst_prm_usd_level1 -- Logistic PRM
    ,estimate_net__total_item_card_prm_usd_level1 -- Item PRM
    ,estimate_net__total_voucher_prm_usd_level1 -- Voucher PRM
    ,estimate_net__total_coin_prm_usd_level1 -- Coin PRM
    ,estimate_mandatory_commission_fee_usd_level1_1d + estimate_optional_commission_fee_usd_level1_1d + handling_fee_usd + paid_ads_net_revenue_usd_1d - paid_ads_voucher_ads_part_amt_usd_1d as pc2
    ,omni_gmv_usd * adjusted_proxy_pc2_rate as adjusted_proxy_pc2_usd_1d
    ,paid_ads_revenue_usd_1d
    ,paid_ads_broad_gmv_usd_1d
    ,paid_ads_voucher_ads_part_amt_usd_1d
    ,paid_ads_net_revenue_usd_1d
    ,omni_gmv_usd * adjusted_proxy_pc2_rate_exp as adjusted_proxy_pc2_exp_usd_1d
    ,upper('${region}') as grass_region
    ,real.grass_date as grass_date
from
    (
        select
            *
        from real_pc2
        where common_feature!='Others'
    ) as real
    left join (
        select
            *
        from adjusted_item_pc2
    ) adjusted_item 
    on real.item_id = adjusted_item.item_id and real.grass_date = adjusted_item.grass_date
;


insert overwrite table dws_common_feature_user_item_pc2_1d__reg_s0_live partition (tz_type='local', grass_region, grass_date)
select
    *
from output 
;