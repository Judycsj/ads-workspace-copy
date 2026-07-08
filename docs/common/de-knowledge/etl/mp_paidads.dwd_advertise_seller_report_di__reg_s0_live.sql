-- task_code: data_paidadsmart.studio_8035180  asset_id: 8035180
-- const (
--         TrackingOperationType_IMPRESSION               TrackingOperationType = 1
--         TrackingOperationType_CLICK                    TrackingOperationType = 2
--         TrackingOperationType_VIEW                     TrackingOperationType = 3
--         TrackingOperationType_ADD_TO_CART              TrackingOperationType = 4
--         TrackingOperationType_PLACE_ORDER              TrackingOperationType = 5
--         TrackingOperationType_SHOP_IMPRESSION          TrackingOperationType = 1001
--         TrackingOperationType_SHOP_CLICK               TrackingOperationType = 1002
--         TrackingOperationType_SHOP_BANNER_IMPRESSION   TrackingOperationType = 1003
--         TrackingOperationType_CLOSE_BANNER             TrackingOperationType = 6
--         TrackingOperationType_REPORT_DISLIKE           TrackingOperationType = 7
--         TrackingOperationType_REPORT_INAPPROPRIATE     TrackingOperationType = 8
--         TrackingOperationType_REPORT_IRRELEVANT        TrackingOperationType = 9
--         TrackingOperationType_REPORT_IMPRESSION        TrackingOperationType = 10
--         TrackingOperationType_SHOP_SCROLL              TrackingOperationType = 11
--         TrackingOperationType_SHOP_VIEW                TrackingOperationType = 12
--         TrackingOperationType_LIVE_VIEW                TrackingOperationType = 13
--         TrackingOperationType_PRODUCT_CLICK            TrackingOperationType = 14
--         TrackingOperationType_LIVE_VIEW_PING           TrackingOperationType = 15
--         TrackingOperationType_EXIT_STREAM              TrackingOperationType = 16
--         TrackingOperationType_SHOP_ITEM_IMPRESSION     TrackingOperationType = 17
--         TrackingOperationType_MORE_SHOP_CLICK          TrackingOperationType = 18
--         TrackingOperationType_ENTRY_IMPRESSION         TrackingOperationType = 19
--         TrackingOperationType_ENTRY_CLICK              TrackingOperationType = 20
--         TrackingOperationType_VIDEO_VIEW               TrackingOperationType = 21
--         TrackingOperationType_VIDEO_PLAY_TIME          TrackingOperationType = 22
--         TrackingOperationType_VIDEO_PLAY_COMPLETE      TrackingOperationType = 23
--         TrackingOperationType_PDP_VIEW                 TrackingOperationType = 24
--         TrackingOperationType_SHOP_LIVE_VIEW           TrackingOperationType = 25
--         TrackingOperationType_SHOP_LIVE_VIEW_PING      TrackingOperationType = 26
--         TrackingOperationType_SHOP_VIDEO_PLAY          TrackingOperationType = 27
--         TrackingOperationType_SHOP_VIDEO_PLAY_TIME     TrackingOperationType = 28
--         TrackingOperationType_SHOP_VIDEO_PLAY_COMPLETE TrackingOperationType = 29
-- )
---------------------------------------------------------- Tracking Item ---------------------------------------------------------- 

-- Step 1: Create the tracking_item_general view
CREATE OR REPLACE TEMPORARY VIEW tracking_item_general AS
SELECT 
    COALESCE(
        item.internal.deduction_info.placement,
        Case when COALESCE (CAST(get_json_object(item.json_data, '$.placement') AS INT),CAST(get_json_object(json_data, '$.placement') AS INT)) = 7 then 7 end
    ) AS coalesce_placement,
    COALESCE(
        CAST(get_json_object(item.json_data, '$.entrance') AS INT),
        CAST(get_json_object(json_data, '$.entrance') AS INT)
    ) AS coalesce_entrance,
    COALESCE(
        CAST(get_json_object(item.json_data, '$.pricing_type') AS INT),
        CAST(get_json_object(json_data, '$.pricing_type') AS INT)
    ) AS coalesce_pricing_type,
    userid AS user_id,
    item.adsid AS ads_id,
    item.itemid AS item_id,
    item.campaignid AS campaign_id,
    item.shopid AS shop_id,
    CAST(NULL AS BIGINT) AS account_id,
    CAST(NULL AS BIGINT) AS affiliate_id,
    COALESCE(
        CAST(get_json_object(item.json_data, '$.ta_group_id') AS INT),
        CAST(get_json_object(json_data, '$.ta_group_id') AS INT)
    ) AS group_id,
    item.ads_keyword AS keyword,
    item.match_type AS match_type,
    item.traffic_source AS traffic_source,
    json_data,
    item.json_data AS item_json_data,
    item.internal AS internal,
    item.`query` AS item_query,
    item.location_in_ads AS location_in_ads,
    item.request_id AS raw_request_id,
    item.internal.duplicate_label AS duplicate_label,
    item.internal.event_id AS event_id,
    item.internal.deduction_info.deduction_price AS deduction_price,
    item.internal.deduction_info.is_ocpm AS is_ocpm,
    operation,
    country AS region,
    `timestamp` AS event_timestamp
FROM mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
LATERAL VIEW EXPLODE(items) AS item
WHERE 
    grass_date = '${BIZ_YESTERDAY}'
    -- AND grass_region = 'PH'                                                 --TODO: remove
    AND operation IN (1, 2, 21) -- CLICK, IMPRESSION, VIDEO_VIEW
    AND items IS NOT NULL AND SIZE(items) > 0
    -- isAds
    AND item.adsid IS NOT NULL AND item.adsid > 0;

-- Step 2: Create the tracking_item_general_with_handler view
CREATE OR REPLACE TEMPORARY VIEW tracking_item_general_with_handler AS
SELECT 
    CASE 
        WHEN coalesce_placement IN (0, 4, 4400) THEN 'keyword'
        WHEN coalesce_placement IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
        WHEN coalesce_placement IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
        WHEN coalesce_placement IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
        WHEN coalesce_placement = 9 THEN 'display'
        WHEN coalesce_placement = 65 THEN 'banner'
        WHEN coalesce_placement IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
        WHEN coalesce_placement IN (40, 50) THEN 'roi2'
        WHEN coalesce_placement = 45 THEN 'shop_cpm'
        WHEN coalesce_placement = 54 THEN 'video'
    END AS handler
    ,ROW_NUMBER() over(PARTITION BY region ,operation ,internal.duplicate_label ,event_timestamp ,user_id ,ads_id ,item_id ,location_in_ads ,coalesce_placement ,item_json_data ,json_data ,raw_request_id ,event_id ORDER BY event_timestamp) AS rn  --offline random selection
    ,*
FROM tracking_item_general
WHERE
    -- handlerByPlacement 
    coalesce_placement IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
    -- util.ValidCountry(country)
    AND region in ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
    -- validateTracking
    AND user_id > 0
;

-- Step 3: Create the tracking_item view
CREATE OR REPLACE TEMPORARY VIEW tracking_item_with_placement AS
SELECT 
    coalesce_entrance AS entrance,
    CASE 
        WHEN (handler = 'keyword' and keyword = 'wkdaelpmissisiht' AND coalesce_placement IN (0, 4400)) THEN 4
        ELSE coalesce_placement
    END AS placement,
    coalesce_pricing_type AS pricing_type,
    user_id,
    ads_id,
    item_id,
    campaign_id,
    shop_id,
    account_id,
    affiliate_id,
    case when (handler in ('keyword', 'boost','roi2','targeting','shop')) then `group_id` end as `group_id`,
    CASE 
        WHEN handler = 'keyword' THEN
            CASE WHEN coalesce_placement =4 THEN 'wkdaelpmissisiht' ELSE keyword END
        WHEN (handler = 'boost' AND coalesce_placement IN (1000, 1200)) THEN keyword
        WHEN handler = 'roi2' THEN keyword
    END AS keyword,
    CASE 
        WHEN handler in ('keyword', 'roi2') THEN match_type
        WHEN (handler = 'boost' AND coalesce_placement IN (1000, 1200)) THEN match_type
    END AS match_type,
    CASE WHEN handler IN ('keyword','roi2') THEN item_query.keyword
         WHEN handler IN ('boost') AND coalesce_placement IN (1000, 1200) THEN item_query.keyword END AS `query`,
    location_in_ads,
    deduction_price,
    is_ocpm,
    operation,
    region,
    event_timestamp,
    handler,
    traffic_source,
    json_data,
    item_json_data,
    internal
FROM tracking_item_general_with_handler
WHERE rn = 1
;

CREATE OR REPLACE TEMPORARY VIEW tracking_item AS
SELECT  CASE WHEN (handler IN ('keyword','targeting') AND traffic_source = 4 AND placement IN (44,4400,4401,4402,4405)) THEN 1 END AS new_boost
       ,*
FROM tracking_item_with_placement;

---------------------------------------------------------- Tracking Shop ---------------------------------------------------------- 

-- Step 1: Create the tracking_shop_general view
CREATE OR REPLACE TEMPORARY VIEW tracking_shop_general AS
SELECT 
    COALESCE(
        shop.internal.deduction_info.placement,
        shop.internal.cpm_deduction_info.placement,
        CASE 
            WHEN (CAST(get_json_object(shop.json_data, '$.placement') AS INT) = 7 OR CAST(get_json_object(json_data, '$.placement') AS INT) = 7) THEN 7
            ELSE 0
        END
    ) AS coalesce_placement,
    COALESCE(
        CAST(get_json_object(shop.json_data, '$.entrance') AS INT),
        CAST(get_json_object(json_data, '$.entrance') AS INT)
    ) AS coalesce_entrance,
    COALESCE(
        CAST(get_json_object(shop.json_data, '$.pricing_type') AS INT),
        CAST(get_json_object(json_data, '$.pricing_type') AS INT)
    ) AS coalesce_pricing_type,
    userid AS user_id,
    COALESCE(
        CAST(get_json_object(shop.json_data, '$.ads_id') AS INT),
        CAST(get_json_object(json_data, '$.ads_id') AS INT)
    ) AS ads_id,
    CAST(NULL AS BIGINT) AS item_id,
    COALESCE(
        CAST(get_json_object(shop.json_data, '$.campaign_id') AS INT),
        CAST(get_json_object(json_data, '$.campaign_id') AS INT)
    ) AS campaign_id,
    shop.shopid AS shop_id,
    CAST(NULL AS BIGINT) AS account_id,
    CAST(NULL AS BIGINT) AS affiliate_id,
    COALESCE(
        CAST(get_json_object(shop.json_data, '$.ta_group_id') AS INT),
        CAST(get_json_object(json_data, '$.ta_group_id') AS INT)
    ) AS group_id,
    COALESCE(
        get_json_object(shop.json_data, '$.ads_keyword'),
        get_json_object(json_data, '$.ads_keyword')
    ) AS keyword,
    COALESCE(
        CAST(get_json_object(shop.json_data, '$.match_type') AS INT),
        CAST(get_json_object(json_data, '$.match_type') AS INT)
    ) AS match_type,
    COALESCE(
        get_json_object(shop.json_data, '$.query'),
        get_json_object(json_data, '$.query')
    ) AS `query`,
    CAST(NULL AS BIGINT) AS new_boost,
    json_data,
    shop.json_data AS shop_json_data,
    CAST(NULL AS STRING) AS raw_request_id,
    shop.internal.duplicate_label AS duplicate_label,
    shop.internal.event_id AS event_id,
    shop.internal.deduction_info.deduction_price AS deduction_price,
    shop.internal AS internal,
    CAST(NULL AS BIGINT) AS location_in_ads,
    shop.internal.deduction_info.is_ocpm AS is_ocpm,
    operation,
    shop.ls_session_id AS ls_session_id,
    country AS region,
    `timestamp` AS event_timestamp
FROM mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
LATERAL VIEW EXPLODE(shops) AS shop
WHERE 
    grass_date = '${BIZ_YESTERDAY}'
    -- AND grass_region = 'PH'                                                 --TODO: remove
    AND operation IN (1001, 1002) -- SHOP_CLICK, SHOP_IMPRESSION
    AND shops IS NOT NULL AND SIZE(shops) > 0;

-- Step 2: Create the tracking_shop_general_with_handler view
CREATE OR REPLACE TEMPORARY VIEW tracking_shop_general_with_handler AS
SELECT 
    CASE 
        WHEN coalesce_placement IN (0, 4, 4400) THEN 'keyword'
        WHEN coalesce_placement IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
        WHEN coalesce_placement IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
        WHEN coalesce_placement IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
        WHEN coalesce_placement = 9 THEN 'display'
        WHEN coalesce_placement = 65 THEN 'banner'
        WHEN coalesce_placement IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
        WHEN coalesce_placement IN (40, 50) THEN 'roi2'
        WHEN coalesce_placement = 45 THEN 'shop_cpm'
        WHEN coalesce_placement = 54 THEN 'video'
    END AS handler
    ,ROW_NUMBER() over(PARTITION BY region ,operation ,internal.duplicate_label ,event_timestamp ,user_id ,ads_id ,item_id ,location_in_ads ,coalesce_placement ,shop_json_data ,json_data ,raw_request_id ,event_id ORDER BY event_timestamp) AS rn  --offline random selection
    ,*
FROM tracking_shop_general
WHERE 
    coalesce_placement IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
    AND ads_id IS NOT NULL AND ads_id > 0
    -- util.ValidCountry(country)
    AND region in ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
    -- validateTracking
    AND user_id > 0;

-- Step 3: Create the tracking_shop view
CREATE OR REPLACE TEMPORARY VIEW tracking_shop AS
SELECT 
    coalesce_entrance AS entrance,
    coalesce_placement AS placement,
    coalesce_pricing_type AS pricing_type,
    user_id,
    ads_id,
    item_id,
    campaign_id,
    shop_id,
    account_id,
    affiliate_id,
    CASE WHEN handler = 'shop_cpm' THEN ls_session_id END AS ls_session_id,
    CASE WHEN handler IN ('keyword', 'boost','roi2','targeting','shop') THEN group_id END AS group_id,
    CASE 
        WHEN handler = 'shop' THEN
            CASE WHEN coalesce_placement in (20,2003,2030) then  '' else keyword end
        WHEN handler = 'shop_cpm' then keyword
    END AS keyword,
    CASE WHEN handler in ('shop','shop_cpm') THEN match_type END AS match_type,
    CASE WHEN handler in ('shop','shop_cpm') THEN `query` END AS `query`,
    new_boost,
    location_in_ads,
    deduction_price,
    is_ocpm,
    operation,
    region,
    event_timestamp,
    handler,
    json_data,
    shop_json_data,
    internal
FROM tracking_shop_general_with_handler
WHERE rn = 1
;

---------------------------------------------------------- Tracking Video ---------------------------------------------------------- 


-- Step 1: Create the tracking_video_general view
CREATE OR REPLACE TEMPORARY VIEW tracking_video_general AS
SELECT 
    COALESCE(
        video.internal.cpm_deduction_info.placement,
        placement  -- Ensure this uses the correct table alias
    ) AS coalesce_placement,
    entrance,
    CAST(get_json_object(video.json_data, '$.pricing_type') AS INT) AS coalesce_pricing_type,
    userid AS user_id,
    video.ads_id,
    CAST(NULL AS BIGINT) AS item_id,
    CAST(get_json_object(video.json_data, '$.campaign_id') AS INT) AS campaign_id,
    video.shop_id AS shop_id,
    CAST(get_json_object(video.json_data, '$.account_id') AS INT) AS account_id,
    CAST(NULL AS BIGINT) AS affiliate_id,
    CAST(NULL AS BIGINT) AS group_id,
    CAST(NULL AS STRING) AS keyword,
    CAST(NULL AS BIGINT) AS match_type,
    CAST(NULL AS STRING) AS `query`,
    CAST(NULL AS BIGINT) AS new_boost,
    json_data,
    video.json_data AS video_json_data,
    video.internal AS internal,
    internal_label,
    video.location_in_ads AS location_in_ads,
    video.duration AS view_duration,
    video.request_id AS raw_request_id,
    video.internal.duplicate_label AS duplicate_label,
    video.internal.event_id AS event_id,
    operation,
    country AS region,
    `timestamp` AS event_timestamp
FROM mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
LATERAL VIEW EXPLODE(videos) AS video
WHERE
    grass_date = '${BIZ_YESTERDAY}'
    -- AND grass_region = 'PH'                                                 --TODO: remove
    AND operation IN (1,2,14,21,22) -- CLICK,IMPRESSION,PRODUCT_CLICK,VIDEO_VIEW,VIDEO_PLAY_TIME
    AND videos IS NOT NULL AND SIZE(videos) > 0
    AND video.ads_id IS NOT NULL AND video.ads_id > 0;

-- Step 2: Create the tracking_video_general_with_handler view
CREATE OR REPLACE TEMPORARY VIEW tracking_video_general_with_handler AS
SELECT 
    CASE 
        WHEN coalesce_placement IN (0, 4, 4400) THEN 'keyword'
        WHEN coalesce_placement IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
        WHEN coalesce_placement IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
        WHEN coalesce_placement IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
        WHEN coalesce_placement = 9 THEN 'display'
        WHEN coalesce_placement = 65 THEN 'banner'
        WHEN coalesce_placement IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
        WHEN coalesce_placement IN (40, 50) THEN 'roi2'
        WHEN coalesce_placement = 45 THEN 'shop_cpm'
        WHEN coalesce_placement = 54 THEN 'video'
    END AS handler
    ,ROW_NUMBER() over(PARTITION BY region ,operation ,internal.duplicate_label ,event_timestamp ,user_id ,ads_id ,item_id ,location_in_ads ,coalesce_placement ,video_json_data ,json_data ,raw_request_id ,event_id ORDER BY event_timestamp) AS rn  --offline random selection
    ,*
FROM tracking_video_general
WHERE 
    coalesce_placement IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
    -- util.ValidCountry(country)
    AND region in ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
    -- validateTracking
    AND user_id > 0;

-- Step 3: Create the tracking_video view
CREATE OR REPLACE TEMPORARY VIEW tracking_video AS
SELECT 
    CAST(entrance AS INT) AS entrance,
    CAST(coalesce_placement AS INT) AS placement,
    coalesce_pricing_type AS pricing_type,
    user_id,
    ads_id,
    item_id,
    campaign_id,
    shop_id,
    account_id,
    affiliate_id,
    group_id,
    keyword,
    match_type,
    query,
    new_boost,
    location_in_ads,
    view_duration,
    operation,
    region,
    event_timestamp,
    handler,
    json_data,
    video_json_data,
    internal,
    internal_label
FROM tracking_video_general_with_handler
WHERE rn = 1
;
---------------------------------------------------------- Insert Into ---------------------------------------------------------- 

INSERT overwrite  TABLE dwd_advertise_seller_report_di__reg_s0_live partition(grass_region, handler, grass_date)
select /*+ REPARTITION(2000, grass_region,handler, grass_date,user_id) */
    *
from(
    SELECT 
        0 AS source,  -- source:tracking
        0 AS sub_source,
        operation,
        entrance,
        placement,
        pricing_type,
        user_id,
        ads_id,
        item_id,
        campaign_id,
        shop_id,
        account_id,
        affiliate_id,
        `group_id`,
        keyword,
        match_type,
        region,
        event_timestamp,
        CASE WHEN operation = 2 THEN 1 ELSE 0 END AS raw_click,
        CASE 
            WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0) AND handler in ('boost','keyword','roi2','targeting')) THEN 1 --TODO: delete duplicated fitler
        END AS raw_imp,
        CASE WHEN handler IN ('boost','keyword','roi2','targeting') THEN location_in_ads END AS location_in_ads,
        CASE 
            WHEN (operation = 2 AND handler in ('boost','keyword','roi2','targeting') AND (internal.frauds IS NULL OR SIZE(internal.frauds) = 0)) THEN 1 
        END AS non_fraud_click,
        CASE WHEN (operation = 1 AND is_ocpm AND handler in ('boost','keyword','roi2','targeting')) then deduction_price end AS cpm,
        CASE WHEN (operation = 1 AND is_ocpm AND handler in ('boost','keyword','roi2','targeting')) then deduction_price end AS cost_by_cpm,
        NULL AS shop_item_impression,
        NULL AS shop_item_click,
        NULL AS `view`,
        case when (operation = 21 and handler in ('boost','display','keyword','livestream','roi2','targeting')) then 1
            end as video_view,
        NULL AS pageview,
        CASE WHEN (operation = 2 AND is_ocpm AND handler in ('boost','keyword','roi2','targeting') AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END  AS click,
        NULL AS `cost`,
        NULL AS `order`,
        NULL AS order_amount,
        NULL AS order_gmv,
        NULL AS broad_order,
        NULL AS broad_item_count,
        NULL AS broad_gmv,
        NULL AS checkout,
        CASE WHEN (operation = 2 AND handler in ('boost','keyword','roi2','targeting') AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS dedup_click,
        `query`,
        new_boost,
        NULL AS ls_session_id,
        CASE 
            WHEN (operation = 1 AND handler in ('boost','keyword','roi2','targeting') AND (internal.frauds IS NULL OR SIZE(internal.frauds) = 0)) THEN 1 
            ELSE 0 
        END AS non_fraud_impression,
        NULL AS view_duration,
        NULL AS product_click,
        CASE 
            WHEN (operation =2 AND handler IN ('keyword','targeting','boost','roi2','shop')) THEN deduction_price 
            WHEN (operation =1 AND is_ocpm AND handler IN ('keyword','targeting','boost','roi2','shop')) THEN deduction_price 
        END AS raw_expense,
        NULL AS impression,
        NULL AS expected_revenue,
        NULL AS expense_paid_credit_without_expiry,
        NULL AS expense_paid_credit_with_expiry,
        NULL AS expense_free_credit_without_expiry,
        NULL AS expense_free_credit_with_expiry,
        NULL AS daily_order,
        NULL AS daily_gmv,
        NULL AS broad_shop_item_imp,
        NULL AS broad_shop_item_click,
        NULL AS add_to_cart,
        NULL AS paid_order_gmv,
        NULL AS paid_broad_gmv,
        NULL AS paid_broad_order,
        NULL AS paid_order,
        NULL AS paid_checkout,
        NULL AS paid_broad_order_amount,
        NULL AS paid_order_amount,
        -- CASE 
        --     WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0) AND handler in ('boost','keyword','roi2','targeting')) THEN 1
        --     ELSE 0 
        -- END AS dedup_impression,
        region AS grass_region,
        concat('tracking-',handler) AS handler,
        DATE(from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss')) AS grass_date
    FROM tracking_item

    UNION ALL

    SELECT 
        0 AS source,  -- source:tracking
        1 AS sub_source,
        operation,
        entrance,
        placement,
        pricing_type,
        user_id,
        ads_id,
        item_id,
        campaign_id,
        shop_id,
        account_id,
        affiliate_id,
        `group_id`,
        keyword,
        match_type,
        region,
        event_timestamp,
        CASE WHEN operation = 1002 THEN 1 ELSE 0 END AS raw_click,
        CASE WHEN operation = 1001 THEN 1 ELSE 0 END AS raw_imp,
        CAST(NULL AS BIGINT) AS location_in_ads,  -- location_in_ads
        CASE 
            WHEN (operation = 1002 AND handler in ('shop', 'shop_cpm') AND (internal.frauds IS NULL OR SIZE(internal.frauds) = 0)) THEN 1 
            ELSE 0 
        END AS non_fraud_click,
        CASE 
            WHEN (operation = 1001 AND handler in ('shop', 'shop_cpm')) THEN internal.cpm_deduction_info.cpm
        END AS cpm,
        CASE 
            WHEN (operation = 1001 AND handler in ('shop', 'shop_cpm')) THEN CAST(internal.cpm_deduction_info.cpm AS DOUBLE) / 1000
        END AS cost_by_cpm,
        NULL AS shop_item_impression,
        NULL AS shop_item_click,
        NULL AS `view`,
        NULL AS video_view,
        NULL AS pageview,
        CASE WHEN (operation = 1002 AND is_ocpm AND handler in ('shop', 'shop_cpm') AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS click,
        NULL AS `cost`,
        NULL AS `order`,
        NULL AS order_amount,
        NULL AS order_gmv,
        NULL AS broad_order,
        NULL AS broad_item_count,
        NULL AS broad_gmv,
        NULL AS checkout,
        CASE WHEN (operation = 1002 AND handler in ('shop', 'shop_cpm') AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS dedup_click,
        `query`,
        new_boost,
        ls_session_id,
        CASE WHEN (operation = 1001 AND handler in ('shop', 'shop_cpm') AND (internal.frauds is null or SIZE(internal.frauds) = 0)) THEN 1 ELSE 0 END AS non_fraud_impression,
        NULL AS view_duration,
        NULL AS product_click,
        CASE 
            WHEN (operation = 1002 AND handler in ('shop', 'shop_cpm')) THEN deduction_price 
            WHEN (operation = 1001 AND handler in ('shop', 'shop_cpm')) THEN CAST(internal.cpm_deduction_info.cpm AS DOUBLE) / 1000
        END AS raw_expense,
        NULL AS impression,
        NULL AS expected_revenue,
        NULL AS expense_paid_credit_without_expiry,
        NULL AS expense_paid_credit_with_expiry,
        NULL AS expense_free_credit_without_expiry,
        NULL AS expense_free_credit_with_expiry,
        NULL AS daily_order,
        NULL AS daily_gmv,
        NULL AS broad_shop_item_imp,
        NULL AS broad_shop_item_click,
        NULL AS add_to_cart,
        NULL AS paid_order_gmv,
        NULL AS paid_broad_gmv,
        NULL AS paid_broad_order,
        NULL AS paid_order,
        NULL AS paid_checkout,
        NULL AS paid_broad_order_amount,
        NULL AS paid_order_amount,  
        -- CASE WHEN operation = 1001 THEN 1 ELSE 0 END  AS dedup_impression,      
        region AS grass_region,
        concat('tracking-',handler) AS handler,
        DATE(from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss')) AS grass_date
    FROM tracking_shop

    UNION ALL

    SELECT 
        0 AS source,  -- source:tracking
        2 AS sub_source,
        operation,
        entrance,
        placement,
        pricing_type,
        user_id,
        ads_id,
        item_id,
        campaign_id,
        shop_id,
        account_id,
        affiliate_id,
        `group_id`,
        keyword,
        match_type,
        region,
        event_timestamp,
        CASE WHEN operation = 2 THEN 1 ELSE 0 END AS raw_click,
        CASE 
            WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 
            ELSE 0 
        END AS raw_imp,
        CASE WHEN handler = 'video' THEN location_in_ads END AS location_in_ads,
        CASE 
            WHEN (operation = 2 AND (internal_label.frauds is null or SIZE(internal_label.frauds) = 0)) THEN 1 
            ELSE 0 
        END AS non_fraud_click,
        CASE 
            WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN internal.cpm_deduction_info.cpm
        END AS cpm,
        CASE 
            WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN CAST(internal.cpm_deduction_info.cpm AS DOUBLE) / 1000
        END AS cost_by_cpm,
        NULL AS shop_item_impression,
        NULL AS shop_item_click,
        NULL AS `view`,
        CASE 
            WHEN (operation = 21 AND handler = 'video' ) THEN 1
        END AS video_view,
        NULL AS pageview,
        NULL AS click,
        NULL AS `cost`,
        NULL AS `order`,
        NULL AS order_amount,
        NULL AS order_gmv,
        NULL AS broad_order,
        NULL AS broad_item_count,
        NULL AS broad_gmv,
        NULL AS checkout,
        CASE WHEN (operation = 2 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS dedup_click,
        `query`,
        new_boost,
        NULL AS ls_session_id,
        CASE 
            WHEN (operation = 1 AND (internal_label.frauds is null or SIZE(internal_label.frauds) = 0)) THEN 1 
            ELSE 0 
        END AS non_fraud_impression,
        CASE WHEN (operation = 22 AND handler = 'video') THEN view_duration END AS view_duration,
        CASE WHEN (operation = 14 AND handler = 'video' AND (internal.duplicate_label IS NULL OR internal.duplicate_label <=0)) THEN 1 ELSE 0 END AS product_click,
        CASE 
            WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN CAST(internal.cpm_deduction_info.cpm AS DOUBLE) / 1000
        END AS raw_expense,
        NULL AS impression,
        NULL AS expected_revenue,
        NULL AS expense_paid_credit_without_expiry,
        NULL AS expense_paid_credit_with_expiry,
        NULL AS expense_free_credit_without_expiry,
        NULL AS expense_free_credit_with_expiry,
        NULL AS daily_order,
        NULL AS daily_gmv,
        NULL AS broad_shop_item_imp,
        NULL AS broad_shop_item_click,
        NULL AS add_to_cart,
        NULL AS paid_order_gmv,
        NULL AS paid_broad_gmv,
        NULL AS paid_broad_order,
        NULL AS paid_order,
        NULL AS paid_checkout,
        NULL AS paid_broad_order_amount,
        NULL AS paid_order_amount,
        -- CASE 
        --     WHEN (operation = 1 AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 
        --     ELSE 0 
        -- END AS dedup_impression,
        region AS grass_region,
        concat('tracking-',handler) AS handler,
        DATE(from_unixtime(event_timestamp, 'yyyy-MM-dd HH:mm:ss')) AS grass_date
    FROM tracking_video
);