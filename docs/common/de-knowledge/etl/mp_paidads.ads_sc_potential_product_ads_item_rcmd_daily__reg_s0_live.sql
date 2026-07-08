-- task_code: data_paidadsmart.studio_9155525  asset_id: 9155525
create external table if not exists ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live (
    key string 
    ,value string
    ,item_id bigint
    ,shop_id bigint
    ,good_potential_score int
    ,low_price_score int
    ,l1_cat bigint
    ,l2_cat bigint
    ,l3_cat bigint 
    ,ctrcr_7d double 
    ,gmv_usd_7d double
    ,order_cnt_7d double
    ,order_growth_rate double
    ,impression_7d bigint 
    ,ctrcr_p50 double
    ,gmv_p90 double
    ,gmv_p60 double
    ,order_growth_p60 double
    ,order_p80 double
) comment '${SCHEMA}.rcmd_v2_max_gmv' partitioned by (
    grass_region string
    ,grass_date date comment 'date'
) stored as parquet location "${HIVE_PATH}/ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live"
;



create external table if not exists ads_sc_potential_product_ads_item_temp__reg (
    item_id bigint
    ,shop_id bigint
    ,l1_cat bigint
    ,l2_cat bigint
    ,l3_cat bigint 
    ,final_cat bigint 
    ,ctrcr_7d double 
    ,gmv_usd_7d double
    ,avg_order_7d double
    ,order_cnt_7d double
    ,avg_order_cnt_14d double
    ,order_growth_rate double
    ,impression_7d  bigint 
    ,click_7d bigint 

) comment '${SCHEMA}.rcmd_v2_max_gmv' partitioned by (
    grass_region string
    ,grass_date date comment 'date'
) stored as parquet location "${HIVE_PATH}/ads_sc_potential_product_ads_item_temp"
;

REFRESH TABLE traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live;

cache table campaign_days OPTIONS ('storageLevel' 'MEMORY_ONLY') as ( 
    SELECT 
        case 
            when campaign_7d < 7 then sequence(date('${PREV_7D}'), date('${BIZ_YESTERDAY}'))
            else  sequence(date('${PREV_14D}'), date('${PREV_8D}'))
        end as grass_date_7D
        ,case 
            when campaign_7d < 7 then sequence(date('${PREV_14D}'), date('${PREV_8D}'))
            else  sequence(date('${PREV_21D}'), date('${PREV_15D}'))
        end as grass_date_14D
        ,case when campaign_7d < 7 then campaign_7d else campaign_14d end as campaign_days_7d
        ,case when campaign_7d < 7 then campaign_14d else campaign_21d end as campaign_days_14d
    from(
        select  
            sum(if(date(campaign_day) between date('${PREV_7D}') and date('${BIZ_YESTERDAY}'),1,0)) as campaign_7d
            ,sum(if(date(campaign_day) between date('${PREV_14D}') and date('${PREV_8D}'),1,0)) as campaign_14d
            ,sum(if(date(campaign_day) between date('${PREV_21D}') and date('${PREV_15D}'),1,0)) as campaign_21d
        FROM mp_paidads.dim_campaign_day__reg_s0_live 
        WHERE grass_region = upper('${region}') 
        AND grass_date = date'${BIZ_YESTERDAY}'
    )
);

insert overwrite table ads_sc_potential_product_ads_item_temp__reg partition (grass_region, grass_date)
select 
    a.item_id
    ,b.shop_id
    ,l1_cat
    ,l2_cat
    ,l3_cat
    ,case 
        when l3_cat > 0 then l3_cat
        when l2_cat > 0 then l2_cat
        else l1_cat
    end as final_cat
    ,round(ctrcr, 5) as ctrcr_7d
    ,round(gmv_usd_7d, 5) as gmv_usd_7d
    ,round(avg_order_7d, 5) as avg_order_7d
    ,round(order_cnt_7d, 5) as order_cnt_7d
    ,round(avg_order_cnt_14d, 5) as avg_order_cnt_14d
    ,round(case when avg_order_cnt_14d > 0 and avg_order_7d > avg_order_cnt_14d then avg_order_7d / avg_order_cnt_14d - 1 end, 5) as order_growth_rate
    ,impression_7d
    ,click_7d
    ,upper('${region}') as grass_region
    ,date'${BIZ_YESTERDAY}' as grass_date
from 
    (
         --从 omni 取 platform order/GMV & CXR
        select
            item_id
            ,sum(click_cnt) as click_7d
            ,sum(impression_cnt) as impression_7d
            ,sum(gmv_usd) as gmv_usd_7d
            ,sum(if(date_type = 1, order_cnt,0)) as order_cnt_7d
            ,sum(if(date_type = 1, order_cnt,0)) / (7 - (select campaign_days_7d from campaign_days)) as avg_order_7d
            ,sum(if(date_type = 1, order_cnt,0)) / sum(impression_cnt) as ctrcr 
            ,sum(if(date_type = 2, order_cnt,0)) / (7 - (select campaign_days_14d from campaign_days)) as avg_order_cnt_14d
        from
            (
                --从 omni 取 platform order/GMV & CTRCR
                select
                    item_id
                    ,sum(item_click_cnt_1d) as click_cnt
                    ,sum(item_impr_cnt_1d) as impression_cnt
                    ,sum(gmv_usd_1d) as gmv_usd
                    ,sum(order_1d) as order_cnt
                    ,1 as date_type
                    -- ,cast(sum(order_1d) as double) / sum(item_click_cnt_1d) as cr
                    -- ,cast(sum(item_click_cnt_1d) as double) / sum(item_impr_cnt_1d) as ctr
                from traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live
                where grass_region = upper('${region}')
                    and local_date in (
                        select explode(grass_date_7D) 
                        from campaign_days
                    )
                    and local_date not in ( 
                        select campaign_day 
                        from mp_paidads.dim_campaign_day__reg_s0_live 
                        where grass_date = date'${BIZ_YESTERDAY}'  
                        and campaign_day >= date('${PREV_21D}') 
                        and grass_region = upper('${region}')
                    )
                    and item_id > 0
                    and (order_1d > 0 or item_click_cnt_1d > 0 or item_impr_cnt_1d > 0)
                group by 1

                union all 

                select
                    item_id
                    ,null as click_cnt
                    ,null as impression_cnt
                    ,null as gmv_usd
                    ,coalesce(sum(order_1d), 0) as order_cnt
                    -- ,null as cr
                    -- ,null as ctr
                    ,2 as date_type
                from traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live
                where grass_region = upper('${region}')
                    and local_date in (
                        select explode(grass_date_14D) 
                        from campaign_days
                    )
                    and local_date not in ( 
                        select campaign_day 
                        from mp_paidads.dim_campaign_day__reg_s0_live 
                        where grass_date = date'${BIZ_YESTERDAY}'  
                        and campaign_day >= date('${PREV_21D}') 
                        and grass_region = upper('${region}')
                    )
                    and item_id > 0
                    and order_1d > 0
                group by 1
            ) 
            -- left join campaign_days on 1=1

        group by 1
        having sum(if(date_type = 1, order_cnt,0)) > 0
        -- and sum(if(date_type = 1 , click_cnt,0)) > 0
        -- and sum(if(date_type = 1, impression_cnt,0)) >= 100
    )a 

    join (
        --取 item维表取 分层信息，商品价格
        select distinct
            itemid as item_id
            ,shopid as shop_id
            ,coalesce(cat1, 0) as l1_cat
            ,coalesce(cat2, 0) as l2_cat
            ,coalesce(cat3, 0) as l3_cat
            ,price
            ,sku_status
        from mkplpaidads_data.rcmd_score_stats
        where
            dt = '${BIZ_TODAY}'
            and country = upper('${region}')
            and cat1 > 0
            and sku_status
    ) b 
    on a.item_id = b.item_id

    left join (
        select distinct item_id
        from mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live
        where grass_region = upper('${region}')
        and grass_date = date('${BIZ_TODAY}')
        and h = ${hour}
    ) c
    on a.item_id = c.item_id

    left join(
        select distinct item_id 
        from szci_antifraud.brushing_detection_abnormal_item_online_di
        where  grass_region = upper('${region}')
        and grass_date = (
            select max(grass_date) 
            from szci_antifraud.brushing_detection_abnormal_item_online_di
            where  grass_region = upper('${region}')
            and grass_date >= date('${PREV_7D}')
        )
    )d
    on a.item_id = d.item_id

    
    where c.item_id is null
    and d.item_id is null

;

create or replace temporary view category_data as (
    select 
        l3_cat as cat_id
        ,approx_percentile(case when impression_7d >= 100 and click_7d > 0 then ctrcr_7d end, 0.5)  as ctrcr_p50
        ,approx_percentile(gmv_usd_7d, 0.9) as gmv_p90
        ,approx_percentile(gmv_usd_7d, 0.6)  as gmv_p60
        ,approx_percentile(case when order_growth_rate > 0 then order_growth_rate end, 0.6) as order_growth_p60
        ,approx_percentile(order_cnt_7d, 0.8) as order_p80
    from mp_paidads.ads_sc_potential_product_ads_item_temp__reg
    where grass_region = upper('${region}')
    and grass_date = date('${BIZ_YESTERDAY}')
    and l3_cat > 0
    group by l3_cat

    union all 

    select 
        l2_cat as cat_id
        ,approx_percentile(case when impression_7d >= 100 and click_7d > 0 then ctrcr_7d end, 0.5)  as ctrcr_p50
        ,approx_percentile(gmv_usd_7d, 0.9) as gmv_p90
        ,approx_percentile(gmv_usd_7d, 0.6)  as gmv_p60
        ,approx_percentile(case when order_growth_rate > 0 then order_growth_rate end, 0.6) as order_growth_p60
        ,approx_percentile(order_cnt_7d, 0.8) as order_p80
    from mp_paidads.ads_sc_potential_product_ads_item_temp__reg
    where grass_region = upper('${region}')
    and grass_date = date('${BIZ_YESTERDAY}')
    and l2_cat > 0
    group by l2_cat

    union all 

    select 
        l1_cat as cat_id
        ,approx_percentile(case when impression_7d >= 100 and click_7d > 0 then ctrcr_7d end, 0.5)  as ctrcr_p50
        ,approx_percentile(gmv_usd_7d, 0.9) as gmv_p90
        ,approx_percentile(gmv_usd_7d, 0.6)  as gmv_p60
        ,approx_percentile(case when order_growth_rate > 0 then order_growth_rate end, 0.6) as order_growth_p60
        ,approx_percentile(order_cnt_7d, 0.8) as order_p80
    from mp_paidads.ads_sc_potential_product_ads_item_temp__reg
    where grass_region = upper('${region}')
    and grass_date = date('${BIZ_YESTERDAY}')
    and l1_cat > 0
    group by l1_cat
)
;

CREATE OR REPLACE TEMPORARY FUNCTION marshal_item as 'com.shopee.deepdata.warehouse.hive.udf.MarshalItemPotential' ;

insert overwrite table ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live partition (grass_region, grass_date)
select 
    CONCAT('item_', grass_region, '_', item_id, ':potential_product') AS key 
    ,marshal_item(item_id, CAST(good_potential_score AS bigint), CAST(low_price_score AS bigint)) AS value
    ,*
from (
    select
        coalesce(a.item_id, b.item_id) as item_id
        ,coalesce(a.shop_id, b.shop_id) as shop_id
        ,coalesce(good_potential , 0) as good_potential_score
        ,coalesce(low_price_potential , 0) as low_price_score
        ,l1_cat
        ,l2_cat
        ,l3_cat
        ,ctrcr_7d 
        ,gmv_usd_7d
        ,order_cnt_7d
        ,order_growth_rate
        -- for test
        ,impression_7d
        ,ctrcr_p50
        ,gmv_p90
        ,gmv_p60
        ,order_growth_p60
        ,order_p80
        ,upper('${region}') as grass_region
        ,date('${BIZ_YESTERDAY}') as grass_date
    from (
        select 
            item_id 
            ,shop_id 
            ,a.l1_cat
            ,a.l2_cat
            ,a.l3_cat
            ,a.final_cat
            ,ctrcr_7d
            ,gmv_usd_7d
            ,order_cnt_7d
            ,order_growth_rate
            ,impression_7d
            ,ctrcr_p50
            ,gmv_p90
            ,gmv_p60
            ,order_growth_p60
            ,order_p80
            ,1 as good_potential
        from mp_paidads.ads_sc_potential_product_ads_item_temp__reg a
        left join category_data on a.final_cat = category_data.cat_id
        where a.grass_region = upper('${region}')
            and a.grass_date = date('${BIZ_YESTERDAY}')
            and impression_7d >= 100 
            and click_7d > 0 
            and avg_order_7d > coalesce(avg_order_cnt_14d, 0) 
            and
            (
                case 
                    when avg_order_cnt_14d > 0 then (ctrcr_7d >= ctrcr_p50 and gmv_usd_7d >= gmv_p60 and gmv_usd_7d <= gmv_p90 and order_growth_rate >= order_growth_p60)
                            
                    else (ctrcr_7d >= ctrcr_p50 and  gmv_usd_7d >= gmv_p60 and gmv_usd_7d <= gmv_p90 and order_cnt_7d >= order_p80)   
                end
            ) = true
    ) a
    full join 
    (
        select d.item_id, shop_id, 1 as low_price_potential
        from (
            select distinct item_id, shop_id
            from srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf
            where grass_region = upper('${region}')
            and local_date = date('${BIZ_YESTERDAY}')
            and item_id > 0
        )d
        left join (
            select distinct item_id
            from mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live
            where grass_region = upper('${region}')
            and grass_date = date('${BIZ_TODAY}')
            and h =  (
                select max(h)
                from mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live
                where grass_region = upper('${region}')
                and grass_date = date('${BIZ_TODAY}')
            )
        ) c
        on d.item_id = c.item_id
        where c.item_id is null
    )b
    on a.item_id = b.item_id
)
;