-- task_code: data_paidadsmart.studio_10399630  asset_id: 10399630
create external table if not exists ads_new_pc2_rate_exp_1d__reg_s0_live (
    scenario_tag string
    ,exp_group_id bigint
    ,domain string
    ,omni_gmv_usd_1d double
    ,estimate_mp_revenue_usd_1d double
    ,estimate_mandatory_commission_fee_usd_1d double
    ,estimate_local_c2c_mandatory_commission_fee_usd_1d double
    ,estimate_local_mall_mandatory_commission_fee_usd_1d double
    ,estimate_cb_mandatory_commission_fee_usd_1d double
    ,estimate_optional_commission_fee_usd_1d double
    ,estimate_local_c2c_optional_commission_fee_usd_1d double
    ,estimate_local_mall_optional_commission_fee_usd_1d double
    ,estimate_cb_optional_commission_fee_usd_1d double
    ,estimate_handling_fee_usd_1d double
    ,estimate_seller_handling_fee_usd_1d double
    ,estimate_buyer_handling_fee_usd_1d double
    ,estimate_promotion_excl_3pl_usd_1d double
    ,estimate_logst_prm_usd_1d double
    ,estimate_item_card_prm_usd_1d double
    ,estimate_voucher_prm_usd_1d double
    ,estimate_coin_prm_usd_1d double
    ,proxy_pc2_usd_1d double
    ,adjusted_proxy_pc2_usd_1d double
    ,paid_ads_revenue_usd_1d double
    ,paid_ads_broad_gmv_usd_1d double
    ,paid_ads_voucher_ads_part_amt_usd_1d double
    ,local_pc2_usd_1d double
    ,estimate_3pl_margin_usd_1d double
    ,rsf_and_rts_usd_1d double
    ,gross_transaction_fee_usd_1d double
    ,true_pc2_usd_1d double
    ,other_revenue_usd_1d double
    ,adjusted_proxy_pc2_exp_usd_1d double
    ,paid_ads_net_revenue_usd_1d double
)
partitioned by
    (
        grass_region string comment 'grass_region'
        ,grass_date date comment 'grass_date'
    ) stored as PARQUET location '${HIVE_PATH}/ads_new_pc2_rate_exp_1d__reg_s0_live'
;

create or replace temporary view abtest_user_group as (
    select
        local_date as grass_date
        ,grass_region
        ,user_id
        ,exp_group_id
        ,'RCMD_Ads' as domain
    from srdi_mart.dim_sr_data_warehouse_abtest_user_group
    where grass_region = upper('${region}')
    and local_date between date('${grass_date_7day}') and date('${grass_date}')
    and is_dim_join = 1
    and is_rcmd_whitelist = 1
    and user_id > 0
    group by 1,2,3,4
    union all
    select
        local_date as grass_date
        ,grass_region
        ,user_id
        ,exp_group_id
        ,'Search' as domain
    from srdi_mart.dim_sr_data_warehouse_abtest_user_group
    where grass_region = upper('${region}')
    and local_date between date('${grass_date_7day}') and date('${grass_date}')
    and is_assignment_log = 1
    and is_search_whitelist = 1
    and user_id > 0
    group by 1,2,3,4
);

create or replace temporary view common_feature_user_item_pc2 as (
    select 
        scenario_tag
        ,user_id
        ,grass_date
        ,sum(omni_gmv_usd_1d) as omni_gmv_usd_1d
        ,sum(estimate_mp_revenue_usd_1d) as estimate_mp_revenue_usd_1d
        ,sum(estimate_mandatory_commission_fee_usd_1d) as estimate_mandatory_commission_fee_usd_1d
        ,sum(estimate_local_c2c_mandatory_commission_fee_usd_1d) as estimate_local_c2c_mandatory_commission_fee_usd_1d
        ,sum(estimate_local_mall_mandatory_commission_fee_usd_1d) as estimate_local_mall_mandatory_commission_fee_usd_1d
        ,sum(estimate_cb_mandatory_commission_fee_usd_1d) as estimate_cb_mandatory_commission_fee_usd_1d
        ,sum(estimate_optional_commission_fee_usd_1d) as estimate_optional_commission_fee_usd_1d
        ,sum(estimate_local_c2c_optional_commission_fee_usd_1d) as estimate_local_c2c_optional_commission_fee_usd_1d
        ,sum(estimate_local_mall_optional_commission_fee_usd_1d) as estimate_local_mall_optional_commission_fee_usd_1d
        ,sum(estimate_cb_optional_commission_fee_usd_1d) as estimate_cb_optional_commission_fee_usd_1d
        ,sum(estimate_handling_fee_usd_1d) as estimate_handling_fee_usd_1d
        ,sum(estimate_seller_handling_fee_usd_1d) as estimate_seller_handling_fee_usd_1d
        ,sum(estimate_buyer_handling_fee_usd_1d) as estimate_buyer_handling_fee_usd_1d
        ,sum(estimate_promotion_excl_3pl_usd_1d) as estimate_promotion_excl_3pl_usd_1d
        ,sum(estimate_logst_prm_usd_1d) as estimate_logst_prm_usd_1d
        ,sum(estimate_item_card_prm_usd_1d) as estimate_item_card_prm_usd_1d
        ,sum(estimate_voucher_prm_usd_1d) as estimate_voucher_prm_usd_1d
        ,sum(estimate_coin_prm_usd_1d) as estimate_coin_prm_usd_1d
        ,sum(proxy_pc2_usd_1d) as proxy_pc2_usd_1d
        ,sum(adjusted_proxy_pc2_usd_1d) as adjusted_proxy_pc2_usd_1d
        ,sum(paid_ads_revenue_usd_1d) as paid_ads_revenue_usd_1d
        ,sum(paid_ads_broad_gmv_usd_1d) as paid_ads_broad_gmv_usd_1d
        ,sum(paid_ads_voucher_ads_part_amt_usd_1d) as paid_ads_voucher_ads_part_amt_usd_1d
        ,sum(adjusted_proxy_pc2_exp_usd_1d) as adjusted_proxy_pc2_exp_usd_1d
        ,sum(paid_ads_net_revenue_usd_1d) as paid_ads_net_revenue_usd_1d
    from (
        --rename&itself
        select 
            case when a.common_feature = 'Order Detail Page Recommendation' then 'Order Detail Page YMAL'
                when a.common_feature = 'My Purchase Page Recommendation' then 'My Purchase Page YMAL'
                when a.common_feature = 'Shipping Info Page YMAL' then 'SIP YMAL'
                else a.common_feature end as scenario_tag
            ,a.user_id
            ,a.item_id
            ,a.omni_gmv_usd_1d
            ,a.estimate_mp_revenue_usd_1d
            ,a.estimate_mandatory_commission_fee_usd_1d
            ,a.estimate_local_c2c_mandatory_commission_fee_usd_1d
            ,a.estimate_local_mall_mandatory_commission_fee_usd_1d
            ,a.estimate_cb_mandatory_commission_fee_usd_1d
            ,a.estimate_optional_commission_fee_usd_1d
            ,a.estimate_local_c2c_optional_commission_fee_usd_1d
            ,a.estimate_local_mall_optional_commission_fee_usd_1d
            ,a.estimate_cb_optional_commission_fee_usd_1d
            ,a.estimate_handling_fee_usd_1d
            ,a.estimate_seller_handling_fee_usd_1d
            ,a.estimate_buyer_handling_fee_usd_1d
            ,a.estimate_promotion_excl_3pl_usd_1d
            ,a.estimate_logst_prm_usd_1d
            ,a.estimate_item_card_prm_usd_1d
            ,a.estimate_voucher_prm_usd_1d
            ,a.estimate_coin_prm_usd_1d
            ,a.proxy_pc2_usd_1d
            ,a.adjusted_proxy_pc2_usd_1d
            ,a.paid_ads_revenue_usd_1d
            ,a.paid_ads_broad_gmv_usd_1d
            ,a.paid_ads_voucher_ads_part_amt_usd_1d
            ,a.adjusted_proxy_pc2_exp_usd_1d
            ,a.paid_ads_net_revenue_usd_1d
            ,a.grass_date 
        from mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live a
        where a.grass_region = upper('${region}')
        and a.grass_date between date('${grass_date_7day}') and date('${grass_date}')
        and a.tz_type='local'
        union all
        --Cart Unify
        select 
            'Cart Unify' as scenario_tag
            ,user_id
            ,item_id
            ,omni_gmv_usd_1d
            ,estimate_mp_revenue_usd_1d
            ,estimate_mandatory_commission_fee_usd_1d
            ,estimate_local_c2c_mandatory_commission_fee_usd_1d
            ,estimate_local_mall_mandatory_commission_fee_usd_1d
            ,estimate_cb_mandatory_commission_fee_usd_1d
            ,estimate_optional_commission_fee_usd_1d
            ,estimate_local_c2c_optional_commission_fee_usd_1d
            ,estimate_local_mall_optional_commission_fee_usd_1d
            ,estimate_cb_optional_commission_fee_usd_1d
            ,estimate_handling_fee_usd_1d
            ,estimate_seller_handling_fee_usd_1d
            ,estimate_buyer_handling_fee_usd_1d
            ,estimate_promotion_excl_3pl_usd_1d
            ,estimate_logst_prm_usd_1d
            ,estimate_item_card_prm_usd_1d
            ,estimate_voucher_prm_usd_1d
            ,estimate_coin_prm_usd_1d
            ,proxy_pc2_usd_1d
            ,adjusted_proxy_pc2_usd_1d
            ,paid_ads_revenue_usd_1d
            ,paid_ads_broad_gmv_usd_1d
            ,paid_ads_voucher_ads_part_amt_usd_1d
            ,adjusted_proxy_pc2_exp_usd_1d
            ,paid_ads_net_revenue_usd_1d
            ,grass_date 
        from mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date between date('${grass_date_7day}') and date('${grass_date}')
        and tz_type='local'
        and common_feature in ('Cart Recommendation','Order Successful Recommendation','Order Detail Page Recommendation','My Purchase Page Recommendation','Me YMAL','Shop YMAL','Shipping Info Page YMAL','Buy Again (Me Page)')
        union all
        --RCMD Unify
        select 
            'RCMD Unify' as scenario_tag
            ,user_id
            ,item_id
            ,omni_gmv_usd_1d
            ,estimate_mp_revenue_usd_1d
            ,estimate_mandatory_commission_fee_usd_1d
            ,estimate_local_c2c_mandatory_commission_fee_usd_1d
            ,estimate_local_mall_mandatory_commission_fee_usd_1d
            ,estimate_cb_mandatory_commission_fee_usd_1d
            ,estimate_optional_commission_fee_usd_1d
            ,estimate_local_c2c_optional_commission_fee_usd_1d
            ,estimate_local_mall_optional_commission_fee_usd_1d
            ,estimate_cb_optional_commission_fee_usd_1d
            ,estimate_handling_fee_usd_1d
            ,estimate_seller_handling_fee_usd_1d
            ,estimate_buyer_handling_fee_usd_1d
            ,estimate_promotion_excl_3pl_usd_1d
            ,estimate_logst_prm_usd_1d
            ,estimate_item_card_prm_usd_1d
            ,estimate_voucher_prm_usd_1d
            ,estimate_coin_prm_usd_1d
            ,proxy_pc2_usd_1d
            ,adjusted_proxy_pc2_usd_1d
            ,paid_ads_revenue_usd_1d
            ,paid_ads_broad_gmv_usd_1d
            ,paid_ads_voucher_ads_part_amt_usd_1d
            ,adjusted_proxy_pc2_exp_usd_1d
            ,paid_ads_net_revenue_usd_1d
            ,grass_date 
        from mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date between date('${grass_date_7day}') and date('${grass_date}')
        and tz_type='local'
        and common_feature in ('Cart Recommendation','Order Successful Recommendation','Order Detail Page Recommendation','My Purchase Page Recommendation','Me YMAL','Shop YMAL','Shipping Info Page YMAL','Buy Again (Me Page)','You May Also Like','Daily Discover')
        union all
        --Search_RCMD
        select 
            'Search_RCMD' as scenario_tag
            ,user_id
            ,item_id
            ,omni_gmv_usd_1d
            ,estimate_mp_revenue_usd_1d
            ,estimate_mandatory_commission_fee_usd_1d
            ,estimate_local_c2c_mandatory_commission_fee_usd_1d
            ,estimate_local_mall_mandatory_commission_fee_usd_1d
            ,estimate_cb_mandatory_commission_fee_usd_1d
            ,estimate_optional_commission_fee_usd_1d
            ,estimate_local_c2c_optional_commission_fee_usd_1d
            ,estimate_local_mall_optional_commission_fee_usd_1d
            ,estimate_cb_optional_commission_fee_usd_1d
            ,estimate_handling_fee_usd_1d
            ,estimate_seller_handling_fee_usd_1d
            ,estimate_buyer_handling_fee_usd_1d
            ,estimate_promotion_excl_3pl_usd_1d
            ,estimate_logst_prm_usd_1d
            ,estimate_item_card_prm_usd_1d
            ,estimate_voucher_prm_usd_1d
            ,estimate_coin_prm_usd_1d
            ,proxy_pc2_usd_1d
            ,adjusted_proxy_pc2_usd_1d
            ,paid_ads_revenue_usd_1d
            ,paid_ads_broad_gmv_usd_1d
            ,paid_ads_voucher_ads_part_amt_usd_1d
            ,adjusted_proxy_pc2_exp_usd_1d
            ,paid_ads_net_revenue_usd_1d
            ,grass_date 
        from mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date between date('${grass_date_7day}') and date('${grass_date}')
        and tz_type='local'
        and common_feature in ('Cart Recommendation','Order Successful Recommendation','Order Detail Page Recommendation','My Purchase Page Recommendation','Me YMAL','Shop YMAL','Shipping Info Page YMAL','Buy Again (Me Page)','You May Also Like','Daily Discover','Global Search')
        union all
        --DD_PP Unify
        select 
            'DD_PP Unify' as scenario_tag
            ,user_id
            ,item_id
            ,omni_gmv_usd_1d
            ,estimate_mp_revenue_usd_1d
            ,estimate_mandatory_commission_fee_usd_1d
            ,estimate_local_c2c_mandatory_commission_fee_usd_1d
            ,estimate_local_mall_mandatory_commission_fee_usd_1d
            ,estimate_cb_mandatory_commission_fee_usd_1d
            ,estimate_optional_commission_fee_usd_1d
            ,estimate_local_c2c_optional_commission_fee_usd_1d
            ,estimate_local_mall_optional_commission_fee_usd_1d
            ,estimate_cb_optional_commission_fee_usd_1d
            ,estimate_handling_fee_usd_1d
            ,estimate_seller_handling_fee_usd_1d
            ,estimate_buyer_handling_fee_usd_1d
            ,estimate_promotion_excl_3pl_usd_1d
            ,estimate_logst_prm_usd_1d
            ,estimate_item_card_prm_usd_1d
            ,estimate_voucher_prm_usd_1d
            ,estimate_coin_prm_usd_1d
            ,proxy_pc2_usd_1d
            ,adjusted_proxy_pc2_usd_1d
            ,paid_ads_revenue_usd_1d
            ,paid_ads_broad_gmv_usd_1d
            ,paid_ads_voucher_ads_part_amt_usd_1d
            ,adjusted_proxy_pc2_exp_usd_1d
            ,paid_ads_net_revenue_usd_1d
            ,grass_date 
        from mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date between date('${grass_date_7day}') and date('${grass_date}')
        and tz_type='local'
        and common_feature in ('Cart Recommendation','Order Successful Recommendation','Order Detail Page Recommendation','My Purchase Page Recommendation','Me YMAL','Shop YMAL','Shipping Info Page YMAL','Buy Again (Me Page)','Daily Discover')
    ) t
    group by scenario_tag,user_id,grass_date 
);

insert overwrite table ads_new_pc2_rate_exp_1d__reg_s0_live partition (grass_region, grass_date)
select 
    a.scenario_tag
    ,b.exp_group_id
    ,b.domain
    ,sum(a.omni_gmv_usd_1d) as omni_gmv_usd_1d
    ,sum(a.estimate_mp_revenue_usd_1d) as estimate_mp_revenue_usd_1d
    ,sum(a.estimate_mandatory_commission_fee_usd_1d) as estimate_mandatory_commission_fee_usd_1d
    ,sum(a.estimate_local_c2c_mandatory_commission_fee_usd_1d) as estimate_local_c2c_mandatory_commission_fee_usd_1d
    ,sum(a.estimate_local_mall_mandatory_commission_fee_usd_1d) as estimate_local_mall_mandatory_commission_fee_usd_1d
    ,sum(a.estimate_cb_mandatory_commission_fee_usd_1d) as estimate_cb_mandatory_commission_fee_usd_1d
    ,sum(a.estimate_optional_commission_fee_usd_1d) as estimate_optional_commission_fee_usd_1d
    ,sum(a.estimate_local_c2c_optional_commission_fee_usd_1d) as estimate_local_c2c_optional_commission_fee_usd_1d
    ,sum(a.estimate_local_mall_optional_commission_fee_usd_1d) as estimate_local_mall_optional_commission_fee_usd_1d
    ,sum(a.estimate_cb_optional_commission_fee_usd_1d) as estimate_cb_optional_commission_fee_usd_1d
    ,sum(a.estimate_handling_fee_usd_1d) as estimate_handling_fee_usd_1d
    ,sum(a.estimate_seller_handling_fee_usd_1d) as estimate_seller_handling_fee_usd_1d
    ,sum(a.estimate_buyer_handling_fee_usd_1d) as estimate_buyer_handling_fee_usd_1d
    ,sum(a.estimate_promotion_excl_3pl_usd_1d) as estimate_promotion_excl_3pl_usd_1d
    ,sum(a.estimate_logst_prm_usd_1d) as estimate_logst_prm_usd_1d
    ,sum(a.estimate_item_card_prm_usd_1d) as estimate_item_card_prm_usd_1d
    ,sum(a.estimate_voucher_prm_usd_1d) as estimate_voucher_prm_usd_1d
    ,sum(a.estimate_coin_prm_usd_1d) as estimate_coin_prm_usd_1d
    ,sum(a.proxy_pc2_usd_1d) as proxy_pc2_usd_1d
    ,sum(a.adjusted_proxy_pc2_usd_1d) as adjusted_proxy_pc2_usd_1d
    ,sum(a.paid_ads_revenue_usd_1d) as paid_ads_revenue_usd_1d
    ,sum(a.paid_ads_broad_gmv_usd_1d) as paid_ads_broad_gmv_usd_1d
    ,sum(a.paid_ads_voucher_ads_part_amt_usd_1d) as paid_ads_voucher_ads_part_amt_usd_1d
    ,sum(c.local_pc2_usd_1d) as local_pc2_usd_1d
    ,sum(c.estimate_3pl_margin_usd_1d) as estimate_3pl_margin_usd_1d
    ,sum(c.rsf_and_rts_usd_1d) as rsf_and_rts_usd_1d
    ,sum(c.gross_transaction_fee_usd_1d) as gross_transaction_fee_usd_1d
    ,sum(c.true_pc2_usd_1d) as true_pc2_usd_1d
    ,sum(c.other_revenue_usd_1d) as other_revenue_usd_1d
    ,sum(a.adjusted_proxy_pc2_exp_usd_1d) as adjusted_proxy_pc2_exp_usd_1d
    ,sum(a.paid_ads_net_revenue_usd_1d) as paid_ads_net_revenue_usd_1d
    ,upper('${region}') as grass_region
    ,a.grass_date
from common_feature_user_item_pc2 a
left join (
    select 
        user_id
        ,local_pc2_usd_1d
        ,estimate_3pl_margin_usd_1d
        ,rsf_and_rts_usd_1d
        ,gross_transaction_fee_usd_1d
        ,true_pc2_usd_1d
        ,other_revenue_usd_1d
        ,grass_date
    from mp_paidads.dws_user_pc2_1d__reg_s0_live
    where grass_region = upper('${region}')
    and grass_date between date('${grass_date_7day}') and date('${grass_date}')
    and tz_type='local'
) c
on a.user_id = c.user_id
and a.grass_date = c.grass_date
and a.scenario_tag = 'Platform'
join abtest_user_group b
on a.user_id = b.user_id 
and a.grass_date = b.grass_date
group by a.scenario_tag,b.exp_group_id,a.grass_date,b.domain
;