-- task_code: data_paidadsmart.studio_2926322  asset_id: 2926322
CREATE OR REPLACE TEMPORARY VIEW base as(
    SELECT
        COALESCE(a.keyword, b.keyword) AS keyword
        , COALESCE(a.ads_id, b.ads_id) AS ads_id
        , COALESCE(a.shop_id, b.shop_id) AS shop_id
        , COALESCE(a.placement, b.placement) AS placement
        , COALESCE(a.status, b.status) AS status
        , COALESCE(a.match_type, b.match_type) AS match_type
        , COALESCE(a.create_timestamp, b.create_timestamp) AS create_timestamp
        , COALESCE(a.create_datetime, b.create_datetime) AS create_datetime
        , COALESCE(b.keyword_create_timestamp, a.last_modified_timestamp) AS keyword_create_timestamp
        , COALESCE(b.keyword_create_datetime, a.last_modified_datetime) AS keyword_create_datetime
        , COALESCE(a.last_modified_timestamp, b.last_modified_timestamp) AS last_modified_timestamp
        , COALESCE(a.last_modified_datetime, b.last_modified_datetime) AS last_modified_datetime
        , CASE
            WHEN a.last_bid_price_local IS NULL THEN b.min_bid_price_local
            WHEN b.min_bid_price_local IS NULL THEN a.last_bid_price_local
            WHEN a.last_bid_price_local < b.min_bid_price_local THEN a.last_bid_price_local
            ELSE b.min_bid_price_local
        END AS min_bid_price_local
        , CASE
            WHEN a.last_bid_price_usd IS NULL THEN b.min_bid_price_usd
            WHEN b.min_bid_price_usd IS NULL THEN a.last_bid_price_usd
            WHEN a.last_bid_price_usd < b.min_bid_price_usd THEN a.last_bid_price_usd
            ELSE b.min_bid_price_usd
        END AS min_bid_price_usd
        , CASE
            WHEN a.last_bid_price_local IS NULL THEN b.max_bid_price_local
            WHEN b.max_bid_price_local IS NULL THEN a.last_bid_price_local
            WHEN a.last_bid_price_local > b.max_bid_price_local THEN a.last_bid_price_local
            ELSE b.max_bid_price_local
        END AS max_bid_price_local
        , CASE
            WHEN a.last_bid_price_usd IS NULL THEN b.max_bid_price_usd
            WHEN b.max_bid_price_usd IS NULL THEN a.last_bid_price_usd
            WHEN a.last_bid_price_usd > b.max_bid_price_usd THEN a.last_bid_price_usd
            ELSE b.max_bid_price_usd
        END AS max_bid_price_usd
        , COALESCE(b.initial_bid_price_local, a.first_bid_price_local) AS initial_bid_price_local
        , COALESCE(b.initial_bid_price_usd, a.first_bid_price_usd) AS initial_bid_price_usd
        , a.first_bid_price_local AS first_bid_price_local
        , a.first_bid_price_usd AS first_bid_price_usd
        , COALESCE(a.last_bid_price_local, b.last_bid_price_local) AS last_bid_price_local
        , COALESCE(a.last_bid_price_usd, b.last_bid_price_usd) AS last_bid_price_usd
        , CASE
            WHEN a.avg_bid_price_local IS NULL THEN b.avg_bid_price_local
            WHEN b.avg_bid_price_local IS NULL THEN a.avg_bid_price_local
            ELSE (b.avg_bid_price_local*b.bid_price_change_cnt +
                a.avg_bid_price_local*a.bid_price_change_cnt)/(b.bid_price_change_cnt+a.bid_price_change_cnt)
        END AS avg_bid_price_local
        , CASE
            WHEN a.avg_bid_price_usd IS NULL THEN b.avg_bid_price_usd
            WHEN b.avg_bid_price_usd IS NULL THEN a.avg_bid_price_usd
            ELSE (b.avg_bid_price_usd*b.bid_price_change_cnt +
                a.avg_bid_price_usd*a.bid_price_change_cnt)/(b.bid_price_change_cnt+a.bid_price_change_cnt)
        END AS avg_bid_price_usd
        , CASE
            WHEN a.bid_price_change_cnt IS NULL THEN b.bid_price_change_cnt
            WHEN b.bid_price_change_cnt IS NULL THEN a.bid_price_change_cnt
            ELSE a.bid_price_change_cnt + b.bid_price_change_cnt
        END AS bid_price_change_cnt
        ,'${grass_date}' AS grass_date
    FROM
    (
        SELECT
            keyword
            , ads_id
            , shop_id
            , placement
            , status
            , match_type
            , create_timestamp
            , create_datetime
            , last_modified_timestamp
            , last_modified_datetime
            , first_bid_price_local
            , first_bid_price_usd
            , last_bid_price_local
            , last_bid_price_usd
            , avg_bid_price_local
            , avg_bid_price_usd
            , bid_price_change_cnt
        FROM mp_paidads.dws_advertise_keyword_price_1d__${region}_s0_live
        WHERE grass_date = '${grass_date}'
    ) a
    FULL OUTER JOIN
    (
        SELECT
            keyword
            , ads_id
            , shop_id
            , placement
            , status
            , match_type
            , create_timestamp
            , create_datetime
            , keyword_create_timestamp
            , keyword_create_datetime
            , last_modified_timestamp
            , last_modified_datetime
            , min_bid_price_local
            , min_bid_price_usd
            , max_bid_price_local
            , max_bid_price_usd
            , initial_bid_price_local
            , initial_bid_price_usd
            , first_bid_price_local
            , first_bid_price_usd
            , last_bid_price_local
            , last_bid_price_usd
            , avg_bid_price_local
            , avg_bid_price_usd
            , bid_price_change_cnt
        FROM mp_paidads.dws_advertise_keyword_price_td__${region}_s0_live
        WHERE grass_date = '${day_before_grass_date}'
    ) b
    ON a.shop_id = b.shop_id
        AND a.ads_id = b.ads_id
        AND a.keyword = b.keyword
);

INSERT OVERWRITE TABLE dws_advertise_keyword_price_td__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
SELECT
    distinct keyword
           , base.ads_id
           , base.shop_id
           , placement
           , status
           , match_type
           , b.is_ads_active
           , create_timestamp
           , create_datetime
           , keyword_create_timestamp
           , keyword_create_datetime
           , last_modified_timestamp
           , last_modified_datetime
           , min_bid_price_local
           , min_bid_price_usd
           , max_bid_price_local
           , max_bid_price_usd
           , initial_bid_price_local
           , initial_bid_price_usd
           , first_bid_price_local
           , first_bid_price_usd
           , last_bid_price_local
           , last_bid_price_usd
           , avg_bid_price_local
           , avg_bid_price_usd
           , bid_price_change_cnt
           , upper('${region}') AS grass_region
           , date('${grass_date}') AS grass_date
FROM base
LEFT JOIN (
    SELECT
        ads_id
         , shop_id
         , is_ads_active
    FROM mp_paidads.dim_advertise__${region}_s0_live
    WHERE grass_date = date'${grass_date}'
) b
ON base.ads_id = b.ads_id
    AND base.shop_id = b.shop_id
;

alter table dws_advertise_keyword_price_td__${region}_s0_live add if not exists partition (grass_date = '${grass_date}');