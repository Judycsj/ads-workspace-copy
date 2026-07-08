-- task_code: data_paidadsmart.studio_10404482  asset_id: 10404482
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
    
    ,sum(coalesce(gmv_usd*atc_prorate*first_touchpoint_item, 0)) as gmv_usd
    ,sum(coalesce(pc2_usd*atc_prorate*first_touchpoint_item, 0)) as local_pc2_usd
from
    (
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
            ,pc2_usd
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
        from traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type = 'local'
            and user_id > 0
    ) group by 1,2,3,4,5,6,7
;

--step1.5 make 
create or replace temporary view omni_central_rebate_base as
select
    omni.grass_date
    ,omni.user_id
    ,omni.item_id
    ,sum(omni_gmv_usd) as omni_gmv_usd
    ,sum(local_pc2_usd) as local_pc2_usd
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
            ,local_pc2_usd
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
group by 1, 2, 3
;

--step2 performance_table left join dim_common_feture get ads performance
create or replace temporary view ads_base as
select
    grass_date
    ,user_id
    ,item_id
    ,sum(coalesce(expenditure_amt_usd,0)) as paid_ads_revenue_usd_1d
    ,sum(coalesce(broad_gmv_amt_usd,0)) as paid_ads_broad_gmv_usd_1d
from
    (
        select
            grass_date
            ,user_id
            ,item_id
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
group by 1,2,3
;

--step2.5 user_net_rev_table left join dim_common_feture get net ads rev
create or replace temporary view net_rev_base as
select
    grass_date
    ,user_id
    ,item_id
    ,sum(coalesce(net_ads_revenue_usd_1d,0)) as paid_ads_net_revenue_usd_1d
from
    (
        select
            grass_date
            ,user_id
            ,item_id
            ,net_ads_revenue_usd_1d
        from mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live
        where
            grass_date between date('${grass_date_30day}') and date('${grass_date}') 
            and grass_region = upper('${region}')
            and tz_type='local'
            
    )
group by 1,2,3
;

--step3 ads_voucher left join dim_common_feture get ads voucher
create or replace temporary view ads_voucher_base as
select
    grass_date
    ,user_id
    
    ,item_id
    ,sum(coalesce(ads_voucher_ads_part_amt_usd, 0)) as paid_ads_voucher_ads_part_amt_usd_1d
from
    (
        select
            grass_date
            ,user_id
            ,item_id
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
group by 1,2,3
;

--step4 pc2
--drop table real_pc2;
cache table real_pc2 as
select
    all_base.grass_date as grass_date
    ,user_id
    ,all_base.item_id as item_id
    ,level2_global_be_category_id
    ,omni_gmv_usd
    ,local_pc2_usd
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
        ,SUM(omni_gmv_usd) as omni_gmv_usd
        ,SUM(local_pc2_usd) as local_pc2_usd
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
                ,omni_gmv_usd
                ,local_pc2_usd
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
                
                ,0 as omni_gmv_usd
                ,0 as local_pc2_usd
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
                
                ,0 as omni_gmv_usd
                ,0 as local_pc2_usd
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
                
                ,0 as omni_gmv_usd
                ,0 as local_pc2_usd
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
        ) group by 1,2,3
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
group by 1,2,3
;

create or replace temporary view category_pc2 as
select
    grass_date
    ,level2_global_be_category_id
    ,sum(pc2) / sum(omni_gmv_usd) as category_pc2_rate
from real_pc2
group by 1,2
;

create or replace temporary view local_category_pc2 as
select
    grass_date
    ,level2_global_be_category_id
    ,sum(distinct pc2_rate) as local_category_pc2_rate
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
        from local_category_pc2
    ) as local_category on item.level2_global_be_category_id = local_category.level2_global_be_category_id and item.grass_date = local_category.grass_date
;

create or replace temporary view margin_base as
select
    grass_date
    ,buyer_id as user_id
    ,SUM(coalesce(estimate_net_3pl_margin_usd, 0)) as estimate_net__3pl_margin_usd -- 3PL Margin
from mp_mgmt.dws_order_3pl_margin_di__reg_s1_live
where
    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
    and grass_region = upper('${region}')
    group by 1,2
;

create or replace temporary view other_rev_base as
select
    grass_date
    ,grass_region
    ,SUM(coalesce(other_revenue_usd_1d, 0)) as other_revenue_usd_1d -- other rev
from mp_mgmt.ads_mgmtview_pl_1d__reg_live
where
    grass_date between date('${grass_date_30day}') and date('${grass_date}') 
    and grass_region = upper('${region}')
        and tz_type='local'
    and business_line='shopee'
    group by 1,2
;

--rts_rfs_transaction_fee
create or replace temporary view rsf_rts_base as
select other_rev.grass_date as grass_date,
    other_rev.grass_region as grass_region,
    rsf_and_rts_usd / valid_user_cnt as rsf_and_rts_usd_1d,
    gross_transaction_fee_usd / valid_user_cnt as gross_transaction_fee_usd_1d,
    other_revenue_usd_1d / valid_user_cnt  as other_revenue_usd_1d
from
(
    select grass_date,grass_region
        ,other_revenue_usd_1d
    from 
    other_rev_base
) other_rev
left join 
(
        select grass_date,
            sum(case when omni_gmv_usd>0 then 1 else 0 end) as valid_user_cnt
        from (
            select grass_date, user_id,sum(omni_gmv_usd) as omni_gmv_usd
            from real_pc2
            group by 1,2
        )
        group by 1
) user_info
on other_rev.grass_date = user_info.grass_date
left join 
(
    SELECT 
        t.grass_region as grass_region,
        t.rsf_and_rts_usd / day(last_day(concat(t.year_to_month, '-01'))) as rsf_and_rts_usd,
        t.gross_transaction_fee_usd / day(last_day(concat(t.year_to_month, '-01'))) as gross_transaction_fee_usd
    FROM (
        SELECT 
            *,
            row_number() OVER (ORDER BY year_to_month DESC) as month_rank
        FROM mp_paidads.dim_rsf_rts_transaction_fee_mf__reg_s0_live
        WHERE grass_region = upper('${region}')
            and year_to_month IN (
                substr(date('${grass_date}') , 1, 7), 
                substr(add_months(date('${grass_date}') , -1), 1, 7),
                substr(add_months(date('${grass_date}') , -2), 1, 7)
            )
    ) t
    WHERE t.month_rank = 1
)  rsf_rts
on other_rev.grass_region = rsf_rts.grass_region
;



--step4 Adjusted Proxy PC2   left join dim_item get category info
create or replace temporary view output as
select
    user_base.user_id as user_id
    ,omni_gmv_usd
    ,local_pc2_usd
    ,estimate_mandatory_commission_fee_usd_level1_1d + estimate_optional_commission_fee_usd_level1_1d + handling_fee_usd + coalesce(case when(omni_gmv_usd > 0) then other_revenue_usd_1d else 0 end, 0) as estimate_mp_revenue_usd_1d
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
    ,coalesce(adjusted_proxy_pc2, 0) as adjusted_proxy_pc2
    ,paid_ads_revenue_usd_1d
    ,paid_ads_broad_gmv_usd_1d
    ,paid_ads_voucher_ads_part_amt_usd_1d
    ,coalesce(estimate_net__3pl_margin_usd, 0) as estimate_net__3pl_margin_usd
    ,coalesce(case when(omni_gmv_usd > 0) then rsf_and_rts_usd_1d else 0 end, 0) as rsf_and_rts_usd_1d
    ,coalesce(case when(omni_gmv_usd > 0) then gross_transaction_fee_usd_1d else 0 end, 0) as gross_transaction_fee_usd_1d
    ,estimate_mandatory_commission_fee_usd_level1_1d + estimate_optional_commission_fee_usd_level1_1d + handling_fee_usd + coalesce(case when(omni_gmv_usd > 0) then other_revenue_usd_1d else 0 end, 0)
         - estimate_net__total_item_voucher_logst_prm_usd_level1 + coalesce(estimate_net__3pl_margin_usd, 0) - coalesce(case when(omni_gmv_usd > 0) then rsf_and_rts_usd_1d else 0 end, 0) - coalesce(case when(omni_gmv_usd > 0) then gross_transaction_fee_usd_1d else 0 end, 0) as true_pc2
    ,coalesce(case when(omni_gmv_usd > 0) then other_revenue_usd_1d else 0 end, 0) as other_revenue_usd_1d
    ,paid_ads_net_revenue_usd_1d
    ,upper('${region}') as grass_region
    ,user_base.grass_date as grass_date
from
(
    select 
        real.grass_date as grass_date
        ,user_id
        ,SUM(omni_gmv_usd) as omni_gmv_usd
        ,SUM(local_pc2_usd) as local_pc2_usd
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
        ,SUM(pc2) as pc2
        ,SUM(omni_gmv_usd * adjusted_proxy_pc2_rate) as adjusted_proxy_pc2
        ,SUM(paid_ads_revenue_usd_1d) as paid_ads_revenue_usd_1d
        ,SUM(paid_ads_broad_gmv_usd_1d) as paid_ads_broad_gmv_usd_1d
        ,SUM(paid_ads_voucher_ads_part_amt_usd_1d) as paid_ads_voucher_ads_part_amt_usd_1d
        ,SUM(paid_ads_net_revenue_usd_1d) as paid_ads_net_revenue_usd_1d
        
    from
        (
            select
                *
            from real_pc2
        ) as real
        left join (
            select
                *
            from adjusted_item_pc2
        ) adjusted_item 
        on real.item_id = adjusted_item.item_id and real.grass_date = adjusted_item.grass_date
    group by 1,2
) user_base
left join (
    select * from rsf_rts_base
) rsf_rts
on user_base.grass_date = rsf_rts.grass_date
left join (
    select * from margin_base
)margin
on user_base.user_id = margin.user_id and user_base.grass_date = margin.grass_date
;




insert overwrite table dws_user_pc2_1d__reg_s0_live partition (tz_type='local', grass_region, grass_date)
select
    *
from output 
;