-- task_code: data_paidadsmart.studio_2533687  asset_id: 2533687
INSERT OVERWRITE TABLE dwd_advertise_order_attribution_di__reg_s0_live PARTITION (tz_type='local', grass_region = 'BR', grass_date)
    SELECT /*+ REPARTITION(100) */
         order_id
        ,request_id
        ,query
        ,keyword
        ,ads_id
        ,shop_id
        ,item_id
        ,placement
        ,click_timestamp
        ,click_datetime
        ,event_timestamp
        ,event_datetime
        ,paid_timestamp
        ,paid_datetime
        ,confirmed_timestamp
        ,confirmed_datetime
        ,pricing_type
        ,daily_order_cnt
        ,order_cnt
        ,paid_order_cnt
        ,confirmed_order_cnt
        ,ads_order_gmv_local AS ads_order_gmv
        ,(ads_order_gmv_local/exchange_rate) AS ads_order_gmv_usd
        ,ads_item_sold_cnt
        ,broad_order_cnt
        ,broad_gmv_amt_local AS broad_gmv_amt
        ,(broad_gmv_amt_local/exchange_rate) AS broad_gmv_amt_usd
        ,broad_item_cnt
        ,broad_shop_item_click_cnt
        ,broad_shop_item_impression_cnt
        ,match_type
        ,matched_premium_segment_value_id
        ,entrance
        ,grass_date
    FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live a
    LEFT OUTER JOIN (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}') 
    ) ex_rate
    ON a.grass_region = ex_rate.grass_region
    WHERE a.grass_region = upper('${region}')
    AND a.grass_date = DATE('${grass_date}') 
    AND (
        a.order_id is not NULL
        OR a.paid_datetime is not NULL
        OR a.confirmed_datetime is not NULL
    );

    alter table dwd_advertise_order_attribution_di__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');