-- task_code: data_paidadsmart.studio_9346441  asset_id: 9346441
create external table if not exists ads_order_voucher_1d__reg_s0_live (
    order_id    bigint
    ,shop_id    bigint
    ,item_id    bigint
    ,user_id    bigint
    ,seller_voucher_id      bigint
    ,ads_voucher_id         bigint
    ,fsv_voucher_id         bigint
    ,platform_voucher_id    bigint
    ,order_place_datetime   string
    ,order_paid_datetime    string
    ,item_price_usd         bigint
    ,ab_sign                string
    ,plan_bucket_list       array<bigint>
    ,platform_voucher_amt_usd   decimal(25,10)
    ,seller_voucher_amt_usd     decimal(25,10)
    ,ads_voucher_amt_usd        decimal(25,10)
    ,fsv_voucher_amt_usd        decimal(25,10)
    ,pricing_type   int
    ,placement  bigint
    ,ads_id     bigint

    ,voucher_details_json           string
    ,match_voucher_click_datetime   string
    ,match_voucher_click_ads_id     bigint
    ,match_voucher_click_pricing_type  int
    ,match_voucher_click_placement  bigint
    ,match_voucher_click_ab_sign    string
    ,match_voucher_click_entrance   bigint
    ,voucher_cofund_ratio           double
    ,entrance bigint

    ,platform_voucher_amt_local decimal(25,10)
    ,seller_voucher_amt_local decimal(25,10)
    ,ads_voucher_amt_local decimal(25,10)
    ,fsv_voucher_amt_local decimal(25,10)
    ,net_sv_rebate_by_seller_amt_local decimal(25,10)
    ,net_sv_rebate_by_seller_amt_usd decimal(25,10)
    ,net_sv_rebate_by_external_amt_local decimal(25,10)
    ,net_sv_rebate_by_external_amt_usd decimal(25,10)
    ,net_pv_rebate_by_seller_amt_local decimal(25,10)
    ,net_pv_rebate_by_seller_amt_usd decimal(25,10)
    ,net_pv_rebate_by_external_amt_local decimal(25,10)
    ,net_pv_rebate_by_external_amt_usd decimal(25,10)
    ,platform_order_gmv_amt_local decimal(25,10)
    ,platform_order_gmv_amt_usd decimal(25,10)
    ,non_ads_type tinyint
    ,package_request_id   bigint
    ,package_co_fund_ratio double

)PARTITIONED BY
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date date comment 'grass_date'
)
STORED AS parquet
LOCATION "${HIVE_PATH}/ads_order_voucher_1d"
;

create or replace temporary view order_voucher as 
    select
        a.order_id
        ,a.shop_id
        ,a.item_id
        ,a.user_id
        ,a.seller_voucher_id
        ,d.ads_voucher_id
        ,a.fsv_voucher_id
        ,a.platform_voucher_id
        ,a.order_place_datetime
        ,a.order_place_timestamp
        ,a.order_paid_datetime

        ,b.item_price_usd
        ,c.ab_sign
        ,c.plan_bucket_list
        ,c.entrance
        
        ,pricing_type
        ,placement
        ,ads_id

        ,a.platform_voucher_amt_usd
        ,a.platform_voucher_amt_local
        ,a.seller_voucher_amt_usd
        ,a.seller_voucher_amt_local
        ,if(d.ads_voucher_id is not null,seller_voucher_amt_usd,null) as ads_voucher_amt_usd
        ,if(d.ads_voucher_id is not null,seller_voucher_amt_local,null) as ads_voucher_amt_local
        ,fsv_voucher_amt_usd
        ,fsv_voucher_amt_local
        
        ,net_sv_rebate_by_seller_amt_local
        ,net_sv_rebate_by_seller_amt_usd
        ,net_sv_rebate_by_external_amt_local
        ,net_sv_rebate_by_external_amt_usd
        ,net_pv_rebate_by_seller_amt_local
        ,net_pv_rebate_by_seller_amt_usd
        ,net_pv_rebate_by_external_amt_local
        ,net_pv_rebate_by_external_amt_usd
        ,platform_order_gmv_amt_local
        ,platform_order_gmv_amt_usd
    from (
        select order_id,item_id,shop_id,buyer_id as user_id
            ,max(sv_promotion_id) as seller_voucher_id
            ,max(fsv_promotion_id) as fsv_voucher_id
            ,max(pv_promotion_id) as platform_voucher_id
            ,max(create_datetime) as order_place_datetime
            ,max(create_timestamp) as order_place_timestamp
            ,max(pay_datetime) as order_paid_datetime
            ,sum(net_sv_rebate_by_shopee_amt) as seller_voucher_amt_local
            ,sum(net_sv_rebate_by_shopee_amt_usd) as seller_voucher_amt_usd
            ,sum(net_pv_rebate_by_shopee_amt) as platform_voucher_amt_local
            ,sum(net_pv_rebate_by_shopee_amt_usd) as platform_voucher_amt_usd
            ,sum(net_sv_rebate_by_seller_amt) as net_sv_rebate_by_seller_amt_local
            ,sum(net_sv_rebate_by_seller_amt_usd) as net_sv_rebate_by_seller_amt_usd
            ,sum(net_sv_rebate_by_external_amt) as net_sv_rebate_by_external_amt_local
            ,sum(net_sv_rebate_by_external_amt_usd) as net_sv_rebate_by_external_amt_usd
            ,sum(net_pv_rebate_by_seller_amt) as net_pv_rebate_by_seller_amt_local
            ,sum(net_pv_rebate_by_seller_amt_usd) as net_pv_rebate_by_seller_amt_usd
            ,sum(net_pv_rebate_by_external_amt) as net_pv_rebate_by_external_amt_local
            ,sum(net_pv_rebate_by_external_amt_usd) as net_pv_rebate_by_external_amt_usd
            ,sum(gmv) as platform_order_gmv_amt_local
            ,sum(gmv_usd) as platform_order_gmv_amt_usd
            ,sum(coalesce(actual_shipping_rebate_by_shopee_amt_usd,0) + coalesce(shipping_discount_by_3pl_to_seller_amt_usd,0) + coalesce(actual_shipping_rebate_by_seller_amt_usd,0)) as fsv_voucher_amt_usd
            ,sum(coalesce(actual_shipping_rebate_by_shopee_amt,0) + coalesce(shipping_discount_by_3pl_to_seller_amt,0) + coalesce(actual_shipping_rebate_by_seller_amt,0)) as fsv_voucher_amt_local
        from mp_order.dwd_order_item_all_ent_df
        where grass_region = upper('${region}') and grass_date >= date('${grass_date}') and tz_type = 'local' and date(create_datetime) = date('${grass_date}')
            and (net_sv_rebate_by_shopee_amt_usd >0 or net_pv_rebate_by_shopee_amt_usd> 0 or actual_shipping_rebate_by_shopee_amt_usd>0 
            or shipping_discount_by_3pl_to_seller_amt_usd>0 or actual_shipping_rebate_by_seller_amt_usd>0 )
        group by 1,2,3,4
    ) a  left join(
        select item_id,price_usd as item_price_usd
        from  mkplpaidads_data.item_price__reg_s0_live
        where country = upper('${region}') and dt >= date_sub(date('${grass_date}'),3)
            and dt = (select max(dt) as dt from mkplpaidads_data.item_price__reg_s0_live where country = upper('${region}')and dt >= date_sub(date('${grass_date}'),3))
    )b on a.item_id = b.item_id
    left join (
        select order_id,origin_item_id,max(ab_sign) as ab_sign,max(plan_bucket_list) as plan_bucket_list,max(pricing_type) as pricing_type,max(placement) as placement
        ,max(ads_id) as ads_id
            ,max(entrance) as entrance
        from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where grass_region = upper('${region}') and grass_date =  date('${grass_date}') and tz_type = 'local'
        and broad_order_cnt >0 and placement in (40,50)
        group by 1,2
    ) c on a.order_id = c.order_id and a.item_id = c.origin_item_id
    left join (
        select promotion_id as ads_voucher_id,voucher_groups
        from mp_voucher.dim_voucher__reg_live
        where grass_region = upper('${region}') and grass_date =  date('${grass_date}') and tz_type = 'local'
        and array_contains(voucher_groups,'ADS-ROI') and is_seller_voucher = 1 
    ) d on a.seller_voucher_id = d.ads_voucher_id
;

create or replace temporary view click_oa as 
    select 
        user_id
        ,shop_id
        ,coalesce(deduct_timestamp,timestamp) as deduct_timestamp
        ,cast(get_json_object(bid_rerank_trace, '$.platform_spend_ratio') as double) as voucher_cofund_ratio
        ,cast(get_json_object(bid_rerank_trace,'$.bid_voucher_id') as bigint) as bid_voucher_id
        ,voucher_details_json
        ,from_unixtime(coalesce(deduct_timestamp,timestamp), 'yyyy-MM-dd HH:mm:ss') as match_voucher_click_datetime
        ,ads_id as match_voucher_click_ads_id
        ,pricing_type as match_voucher_click_pricing_type
        ,placement as match_voucher_click_placement
        ,ab_sign as match_voucher_click_ab_sign
        ,entrance as match_voucher_click_entrance
        ,bid_rerank_trace
    from mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where grass_region = upper('${region}') 
    and grass_date between date('${PREV_3D}') and date('${grass_date}') 
    and tz_type = 'local'
    and (click_cnt > 0 or raw_click_cnt>0 or raw_impression>0 or impression_cnt>0 or deduct_impression>0)
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13
;

create or replace temporary view voucher_package_info as (
    select 
        ads_id 
        ,a.shop_id 
        ,case 
            when 
                is_nominated_for_package_non_ads = 1 
                and to_date(from_utc_timestamp(to_utc_timestamp(cast(campaign_start_time as timestamp),'Asia/Singapore'), '${timezone}')) <= date('${grass_date}') 
                and to_date(from_utc_timestamp(to_utc_timestamp(cast(campaign_end_time as timestamp),'Asia/Singapore'), '${timezone}')) >= date('${grass_date}') 
            then 1 
            else 2 
        end as non_ads_type
        ,package_request_id
        ,cast(co_fund_ratio as double) / 100000 as package_co_fund_ratio
    from(
        select 
            ads_id 
            ,shop_id 
            ,is_nominated_for_package_non_ads
            ,is_organic_non_ads
        from mp_paidads.dim_advertise__reg_s0_live
        where tz_type = 'local' 
        and grass_region = upper('${region}') 
        and grass_date = date('${grass_date}') 
        and pricing_type = 29
        and (is_nominated_for_package_non_ads = 1 or is_organic_non_ads = 1)
        group by 1,2,3,4
    ) a
    left join (
        select 
            shop_id
            ,package_request_id
            ,co_fund_ratio
            ,campaign_start_time
            ,campaign_end_time
        from mp_paidads.shopee_ads_${region}_${db_type}__ads_voucher_package_tab__reg_continuous_s0_live
    ) b 
    on a.shop_id = b.shop_id

);


insert overwrite table ads_order_voucher_1d__reg_s0_live partition (tz_type = 'local',grass_region='${upper_region}', grass_date='${grass_date}')
select 
    order_id
    ,a.shop_id
    ,item_id
    ,user_id
    ,seller_voucher_id
    ,ads_voucher_id
    ,fsv_voucher_id
    ,platform_voucher_id
    ,order_place_datetime
    ,order_paid_datetime 
    ,item_price_usd
    ,ab_sign
    ,plan_bucket_list
    ,platform_voucher_amt_usd
    ,seller_voucher_amt_usd
    ,ads_voucher_amt_usd
    ,fsv_voucher_amt_usd
    ,pricing_type
    ,placement
    ,a.ads_id

    ,voucher_details_json
    ,match_voucher_click_datetime
    ,match_voucher_click_ads_id
    ,match_voucher_click_pricing_type
    ,match_voucher_click_placement
    ,match_voucher_click_ab_sign
    ,match_voucher_click_entrance
    ,voucher_cofund_ratio
    ,bid_rerank_trace
    ,entrance

    ,platform_voucher_amt_local
    ,seller_voucher_amt_local
    ,ads_voucher_amt_local
    ,fsv_voucher_amt_local
    ,net_sv_rebate_by_seller_amt_local
    ,net_sv_rebate_by_seller_amt_usd
    ,net_sv_rebate_by_external_amt_local
    ,net_sv_rebate_by_external_amt_usd
    ,net_pv_rebate_by_seller_amt_local
    ,net_pv_rebate_by_seller_amt_usd
    ,net_pv_rebate_by_external_amt_local
    ,net_pv_rebate_by_external_amt_usd
    ,platform_order_gmv_amt_local
    ,platform_order_gmv_amt_usd
    ,non_ads_type
    ,case when non_ads_type = 1 then package_request_id end as package_request_id
    ,case when non_ads_type = 1 then package_co_fund_ratio end as package_co_fund_ratio
from (
    select *
    from (
        select order_voucher.*
            ,voucher_details_json
            ,match_voucher_click_datetime
            ,match_voucher_click_ads_id
            ,match_voucher_click_pricing_type
            ,match_voucher_click_placement
            ,match_voucher_click_ab_sign
            ,match_voucher_click_entrance
            ,voucher_cofund_ratio
            ,bid_rerank_trace
            ,row_number() over (partition by order_voucher.order_id,order_voucher.item_id,order_voucher.user_id,order_voucher.shop_id,order_voucher.ads_voucher_id order by click_oa.deduct_timestamp desc) as rn
        from order_voucher
        left join click_oa
        on order_voucher.user_id = click_oa.user_id 
            and order_voucher.ads_voucher_id = click_oa.bid_voucher_id 
            and order_voucher.shop_id = click_oa.shop_id
            and order_place_timestamp - deduct_timestamp <= 48*3600
            and order_place_timestamp - deduct_timestamp >= 0
    )t
    where rn = 1
) a 
left join voucher_package_info b 
on a.match_voucher_click_ads_id = b.ads_id 
;