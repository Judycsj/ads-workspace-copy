-- task_code: data_paidadsmart.studio_2873616  asset_id: 2873616
-- UTC-5: MX
SET TIME ZONE 'America/Mexico_City';

INSERT OVERWRITE TABLE dws_advertiser_trd_order_gmv_nd__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  
            dim.shop_id
          , user_id
          , COALESCE(buyer_cnt_1d, 0) AS buyer_cnt_1d
          , COALESCE(buyer_cnt_7d, 0) AS buyer_cnt_7d
          , COALESCE(buyer_cnt_30d, 0) AS buyer_cnt_30d
          , COALESCE(buyer_cnt_60d, 0) AS buyer_cnt_60d
          , COALESCE(buyer_cnt_90d, 0) AS buyer_cnt_90d
          , COALESCE(order_cnt_1d, 0) AS order_cnt_1d
          , COALESCE(order_cnt_7d, 0) AS order_cnt_7d
          , COALESCE(order_cnt_30d, 0) AS order_cnt_30d
          , COALESCE(order_cnt_60d, 0) AS order_cnt_60d
          , COALESCE(order_cnt_90d, 0) AS order_cnt_90d
          , COALESCE(order_item_cnt_1d, 0) AS order_item_cnt_1d
          , COALESCE(order_item_cnt_7d, 0) AS order_item_cnt_7d
          , COALESCE(order_item_cnt_30d, 0) AS order_item_cnt_30d
          , COALESCE(order_item_cnt_60d, 0) AS order_item_cnt_60d
          , COALESCE(order_item_cnt_90d, 0) AS order_item_cnt_90d
          , COALESCE(items_sold_cnt_1d, 0) AS items_sold_cnt_1d
          , COALESCE(items_sold_cnt_7d, 0) AS items_sold_cnt_7d
          , COALESCE(items_sold_cnt_30d, 0) AS items_sold_cnt_30d
          , COALESCE(items_sold_cnt_60d, 0) AS items_sold_cnt_60d
          , COALESCE(items_sold_cnt_90d, 0) AS items_sold_cnt_90d
          , COALESCE(gmv_1d, 0.0) AS gmv_1d
          , COALESCE(gmv_7d, 0.0) AS gmv_7d
          , COALESCE(gmv_30d, 0.0) AS gmv_30d
          , COALESCE(gmv_60d, 0.0) AS gmv_60d
          , COALESCE(gmv_90d, 0.0) AS gmv_90d
          , COALESCE(gmv_usd_1d, 0.0) AS gmv_usd_1d
          , COALESCE(gmv_usd_7d, 0.0) AS gmv_usd_7d
          , COALESCE(gmv_usd_30d, 0.0) AS gmv_usd_30d
          , COALESCE(gmv_usd_60d, 0.0) AS gmv_usd_60d
          , COALESCE(gmv_usd_90d, 0.0) AS gmv_usd_90d
          , dim.grass_region as grass_region
          , date('${grass_date}') AS grass_date
    FROM (
        SELECT shop_id, user_id, grass_region
        FROM mp_paidads.dim_advertiser__reg_s0_live
        WHERE grass_date = DATE('${grass_date}')
        AND grass_region = upper('${region}')
    ) dim
    LEFT JOIN (
        SELECT    shop_id
                , SUM(CASE WHEN is_today = 1 THEN placed_buyer_cnt_1d ELSE 0 END) AS buyer_cnt_1d
                , SUM(CASE WHEN is_7d = 1 THEN  placed_buyer_cnt_1d ELSE 0 END) AS buyer_cnt_7d
                , SUM(CASE WHEN is_30d = 1 THEN placed_buyer_cnt_1d ELSE 0 END) AS buyer_cnt_30d
                , SUM(CASE WHEN is_60d = 1 THEN placed_buyer_cnt_1d ELSE 0 END) AS buyer_cnt_60d
                , SUM(CASE WHEN is_90d = 1 THEN placed_buyer_cnt_1d ELSE 0 END) AS buyer_cnt_90d
                , SUM(CASE WHEN is_today = 1 THEN placed_order_cnt_1d ELSE 0 END) AS order_cnt_1d
                , SUM(CASE WHEN is_7d = 1 THEN  placed_order_cnt_1d ELSE 0 END) AS order_cnt_7d
                , SUM(CASE WHEN is_30d = 1 THEN placed_order_cnt_1d ELSE 0 END) AS order_cnt_30d
                , SUM(CASE WHEN is_60d = 1 THEN placed_order_cnt_1d ELSE 0 END) AS order_cnt_60d
                , SUM(CASE WHEN is_90d = 1 THEN placed_order_cnt_1d ELSE 0 END) AS order_cnt_90d
                , SUM(CASE WHEN is_today = 1 THEN item_amount_1d ELSE 0 END) AS order_item_cnt_1d
                , SUM(CASE WHEN is_7d = 1 THEN  item_amount_1d ELSE 0 END) AS order_item_cnt_7d
                , SUM(CASE WHEN is_30d = 1 THEN item_amount_1d ELSE 0 END) AS order_item_cnt_30d
                , SUM(CASE WHEN is_60d = 1 THEN item_amount_1d ELSE 0 END) AS order_item_cnt_60d
                , SUM(CASE WHEN is_90d = 1 THEN item_amount_1d ELSE 0 END) AS order_item_cnt_90d
                , SUM(CASE WHEN is_today = 1  THEN placed_item_cnt_1d ELSE 0 END) AS items_sold_cnt_1d
                , SUM(CASE WHEN is_7d = 1  THEN placed_item_cnt_1d ELSE 0 END) AS items_sold_cnt_7d
                , SUM(CASE WHEN is_30d = 1 THEN placed_item_cnt_1d ELSE 0 END) AS items_sold_cnt_30d
                , SUM(CASE WHEN is_60d = 1 THEN placed_item_cnt_1d ELSE 0 END) AS items_sold_cnt_60d
                , SUM(CASE WHEN is_90d = 1 THEN placed_item_cnt_1d ELSE 0 END) AS items_sold_cnt_90d
                , SUM(CASE WHEN is_today = 1 THEN  gmv_1d ELSE 0.0 END) AS gmv_1d
                , SUM(CASE WHEN is_7d = 1 THEN  gmv_1d ELSE 0.0 END) AS gmv_7d
                , SUM(CASE WHEN is_30d = 1 THEN gmv_1d ELSE 0.0 END) AS gmv_30d
                , SUM(CASE WHEN is_60d = 1 THEN gmv_1d ELSE 0.0 END) AS gmv_60d
                , SUM(CASE WHEN is_90d = 1 THEN gmv_1d ELSE 0.0 END) AS gmv_90d
                , SUM(CASE WHEN is_today = 1 THEN  gmv_usd_1d ELSE 0.0 END) AS gmv_usd_1d
                , SUM(CASE WHEN is_7d = 1 THEN  gmv_usd_1d ELSE 0.0 END) AS gmv_usd_7d
                , SUM(CASE WHEN is_30d = 1 THEN gmv_usd_1d ELSE 0.0 END) AS gmv_usd_30d
                , SUM(CASE WHEN is_60d = 1 THEN gmv_usd_1d ELSE 0.0 END) AS gmv_usd_60d
                , SUM(CASE WHEN is_90d = 1 THEN gmv_usd_1d ELSE 0.0 END) AS gmv_usd_90d
                , region
        FROM (
            SELECT
                a.shop_id
                , placed_order_cnt_1d
                , placed_buyer_cnt_1d
                , placed_item_cnt_1d
                , gmv_1d
                , gmv_usd_1d
                , item_amount_1d
                , CASE WHEN a.grass_date = DATE('${grass_date}') THEN 1 ELSE 0 END AS is_today
                , CASE WHEN a.grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 6 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_7d
                , CASE WHEN a.grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 29 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_30d
                , CASE WHEN a.grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 59 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_60d
                , CASE WHEN a.grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 89 DAYS) AND DATE('${grass_date}') THEN 1 ELSE 0 END AS is_90d
                , a.grass_region AS region
            FROM (
                SELECT shop_id
                    , placed_order_cnt_1d
                    , placed_buyer_cnt_1d
                    , placed_item_cnt_1d
                    , gmv_1d
                    , gmv_usd_1d
                    , grass_date
                    , grass_region
                FROM mp_order.dws_seller_gmv_1d__reg_s0_live
                WHERE grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 89 DAYS) AND DATE('${grass_date}')
                AND tz_type='local'
                AND grass_region = upper('${region}')
            ) a
            INNER JOIN
            (
                SELECT
                    shop_id
                    , grass_date
                    , grass_region
                    , sum(placed_order_cnt_1d) AS item_amount_1d
                FROM mp_order.dws_item_gmv_1d__reg_s0_live
                WHERE grass_date BETWEEN (DATE('${grass_date}') - INTERVAL 89 DAYS) AND DATE('${grass_date}')
                AND tz_type='local'
                AND grass_region = upper('${region}')
                GROUP BY 1,2,3
            ) b
            ON a.shop_id = b.shop_id
            AND a.grass_date = b.grass_date
            AND a.grass_region = b.grass_region
        )
        GROUP BY shop_id, region
    ) orders
    ON dim.shop_id = orders.shop_id AND dim.grass_region = orders.region;


alter table dws_advertiser_trd_order_gmv_nd__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');