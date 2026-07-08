-- task_code: data_paidadsmart.studio_2924881  asset_id: 2924881
CREATE OR REPLACE TEMPORARY VIEW base as(
    SELECT
        distinct keyword
        , placement
        , keyword_status AS status
        , create_timestamp
        , create_datetime
        , event_timestamp AS modified_timestamp
        , event_datetime AS modified_datetime
        , ads_id
        , shop_id
        , match_type
        , keyword_bid_price_local AS bid_price_local
        , keyword_bid_price_usd AS bid_price_usd
        , date '${grass_date}' AS grass_date
    FROM
        mp_paidads.dwd_advertise_audit_di__${region}_s0_live
    WHERE grass_date = date '${grass_date}'
    AND   keyword is not NULL
    AND   keyword_bid_price_local is not NULL
);


INSERT OVERWRITE TABLE dws_advertise_keyword_price_1d__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
SELECT
    a.keyword
     , a.ads_id
     , a.shop_id
     , c.placement
     , c.status
     , c.match_type
     , c.create_timestamp
     , c.create_datetime
     , c.modified_timestamp AS last_modified_timestamp
     , c.modified_datetime AS last_modified_datetime
     , b.bid_price_local AS first_bid_price_local
     , b.bid_price_usd AS first_bid_price_usd
     , c.bid_price_local AS last_bid_price_local
     , c.bid_price_usd AS last_bid_price_usd
     , a.avg_bid_price_local
     , a.avg_bid_price_usd
     , a.bid_price_change_cnt
     , upper('${region}') AS grass_region
     , date '${grass_date}' AS grass_date
FROM
    (
        SELECT
            shop_id
             , ads_id
             , keyword
             , SUM(distinct bid_price_local)/(COUNT(distinct bid_price_local) * 1.0) AS avg_bid_price_local
             , SUM(distinct bid_price_usd)/(COUNT(distinct bid_price_usd) * 1.0) AS avg_bid_price_usd
             , COUNT(distinct bid_price_local) AS bid_price_change_cnt
        FROM base
        GROUP BY 1,2,3
    ) a
        INNER JOIN
    (
        SELECT
            keyword
             , ads_id
             , shop_id
             , bid_price_local
             , bid_price_usd
             , ROW_NUMBER() OVER(PARTITION BY shop_id, ads_id, keyword
                                ORDER BY modified_timestamp) AS keyword_rank_first
        FROM base
    ) b
    ON a.shop_id = b.shop_id
        AND a.ads_id  = b.ads_id
        AND a.keyword = b.keyword
        INNER JOIN
    (
        SELECT
            keyword
             , ads_id
             , shop_id
             , placement
             , status
             , create_timestamp
             , create_datetime
             , modified_timestamp
             , modified_datetime
             , match_type
             , bid_price_local
             , bid_price_usd
             , ROW_NUMBER() OVER(PARTITION BY shop_id, ads_id, keyword
                              ORDER BY modified_timestamp desc) AS keyword_rank_last
        FROM base
    ) c
    ON a.shop_id = c.shop_id
        AND a.ads_id  = c.ads_id
        AND a.keyword = c.keyword
WHERE b.keyword_rank_first = 1
  AND   c.keyword_rank_last = 1
;

alter table dws_advertise_keyword_price_1d__${region}_s0_live add if not exists partition (grass_date = '${grass_date}');