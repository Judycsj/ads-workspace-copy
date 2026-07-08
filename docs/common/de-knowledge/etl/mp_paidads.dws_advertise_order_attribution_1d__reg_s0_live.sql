-- task_code: data_paidadsmart.studio_2535711  asset_id: 2535711
INSERT OVERWRITE TABLE dws_advertise_order_attribution_1d__reg_s0_live PARTITION (tz_type='local', grass_region='BR', grass_date)
    SELECT 
         order_id
        ,request_id
        ,query
        ,keywords
        ,ads_id
        ,shop_id
        ,item_id
        ,placement
        ,click_datetime
        ,event_datetime
        ,sum(daily_order_cnt)
        ,sum(order_cnt)
        ,sum(ads_gmv_amt_local)
        ,sum(ads_gmv_amt_usd)
        ,sum(ads_items_sold_cnt)
        ,sum(broad_order_cnt)
        ,sum(broad_order_gmv_amt_local)
        ,sum(broad_order_gmv_amt_usd)
        ,sum(broad_order_item_cnt)
        ,sum(broad_shopitem_click_cnt)
        ,sum(broad_shopitem_impression_cnt)
        ,grass_date
    FROM mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}') 
    AND order_id is not NULL
    GROUP BY order_id, request_id, query, keywords, ads_id, shop_id, item_id, placement, click_datetime, event_datetime, grass_region, grass_date;

  alter table dws_advertise_order_attribution_1d__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');