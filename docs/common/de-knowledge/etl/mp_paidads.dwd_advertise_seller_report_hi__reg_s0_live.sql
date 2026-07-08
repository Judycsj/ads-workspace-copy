-- task_code: data_paidadsmart.studio_11248134  asset_id: 11248134
-- 广告卖家报告明细层 - 小时级别调度
-- DWD层: 汇总tracking, translog, reportng等多个数据源的广告数据
ADD JAR 'hdfs://R2/projects/mkplpaidads_data/hdfs/udf/muyu.gao/paidads-data-warehouse-udf-1.0.5.jar';
CREATE OR REPLACE TEMPORARY FUNCTION JSON_FROM_PROTOBUF AS 'com.shopee.deepdata.warehouse.hive.udf.TranslogExtinfoDecodeUDF';

-- ============================================
-- Display Tracking Banner 数据处理
-- 处理banner相关的广告追踪数据
-- ============================================
CREATE OR REPLACE TEMPORARY VIEW display_tracking_banner AS
SELECT 
    COALESCE(
        CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT),
        placement
    ) AS coalesce_placement,
    CAST(GET_JSON_OBJECT(banner.json_data, '$.entrance') AS INT) AS coalesce_entrance,
    CAST(GET_JSON_OBJECT(banner.json_data, '$.pricing_type') AS INT) AS coalesce_pricing_type,
    userid AS user_id,
    CAST(GET_JSON_OBJECT(banner.json_data, '$.ads_id') AS BIGINT) AS ads_id,
    CAST(NULL AS BIGINT) AS item_id,
    CAST(GET_JSON_OBJECT(banner.json_data, '$.campaign_id') AS INT) AS campaign_id,
    CAST(GET_JSON_OBJECT(banner.json_data, '$.shop_id') AS INT) AS shop_id,
    CAST(NULL AS BIGINT) AS account_id,
    CAST(NULL AS BIGINT) AS affiliate_id,
    CAST(NULL AS BIGINT) AS group_id,
    search_props.prefill_keyword AS keyword,
    CAST(NULL AS INT) AS match_type,
    CAST(NULL AS BIGINT) AS location_in_ads,
    operation,
    country AS region,
    timestamp AS event_timestamp,
    CASE 
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (0, 4, 4400) THEN 'keyword'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) = 9 THEN 'display'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) = 65 THEN 'banner'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (40, 50) THEN 'roi2'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) = 45 THEN 'shop_cpm'
        WHEN COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) = 54 THEN 'video'
    END AS handler,
    banner,
    internal_label
FROM mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live
WHERE grass_region = UPPER('${region}')
  AND grass_date = '${BIZ_DT}'
  AND h = '${BIZ_H}'
  AND operation IN (1, 2, 13, 21)
  AND banner IS NOT NULL
  AND CAST(GET_JSON_OBJECT(banner.json_data, '$.ads_id') AS INT) IS NOT NULL
  AND CAST(GET_JSON_OBJECT(banner.json_data, '$.ads_id') AS INT) > 0
  AND COALESCE(CAST(GET_JSON_OBJECT(banner.json_data, '$.placement') AS INT), placement) IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54, 65)
  AND country IN ('my','sg','th','id','vn','ph','tw','br','mx','co','cl', 'ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL', 'AR','ALL')
  AND userid > 0;

-- ============================================
-- Livestream Tracking 数据处理
-- 处理直播广告追踪数据
-- US 地区没有 Livestream Tracking 数据
-- ============================================
CREATE OR REPLACE TEMPORARY VIEW livestream_tracking_data AS
SELECT 
    COALESCE(live.internal.cpm_deduction_info.placement, placement) AS coalesce_placement,
    entrance AS coalesce_entrance,
    CAST(GET_JSON_OBJECT(live.json_data, '$.pricing_type') AS INT) AS pricing_type,
    userid AS user_id,
    live.ads_id AS ads_id,
    CAST(NULL AS BIGINT) AS item_id,
    CAST(GET_JSON_OBJECT(live.json_data, '$.campaign_id') AS INT) AS campaign_id,
    CAST(GET_JSON_OBJECT(live.json_data, '$.shop_id') AS INT) AS shop_id,
    CAST(GET_JSON_OBJECT(live.json_data, '$.account_id') AS INT) AS account_id,
    CASE 
        WHEN CAST(GET_JSON_OBJECT(live.json_data, '$.target_affiliate_user_id') AS INT) = 0 OR CAST(GET_JSON_OBJECT(live.json_data, '$.target_affiliate_user_id') AS INT) IS NULL
        THEN CAST(GET_JSON_OBJECT(live.json_data, '$.account_id') AS INT)
        ELSE CAST(GET_JSON_OBJECT(live.json_data, '$.target_affiliate_user_id') AS INT)
    END AS affiliate_id,
    CAST(NULL AS BIGINT) AS group_id,
    CAST(NULL AS STRING) AS keyword,
    CAST(NULL AS INT) AS match_type,
    live.ls_session_id AS ls_session_id,
    CAST(NULL AS BIGINT) AS location_in_ads,
    live.duration AS view_duration,
    operation,
    country AS region,
    timestamp AS event_timestamp,
    CASE 
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (0, 4, 4400) THEN 'keyword'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) = 9 THEN 'display'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (40, 50) THEN 'roi2'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) = 45 THEN 'shop_cpm'
        WHEN COALESCE(live.internal.cpm_deduction_info.placement, placement) = 54 THEN 'video'
    END AS handler,
    live.internal AS internal
FROM mp_paidads.ods_log_livestream_ads_tracking__reg_s0_live
LATERAL VIEW EXPLODE(livestreams) AS live
WHERE grass_region = UPPER('${region}')
  AND grass_date = '${BIZ_DT}'
  AND h = '${BIZ_H}'
  AND operation IN (1, 2, 13, 14, 15, 21)
  AND livestreams IS NOT NULL
  AND SIZE(livestreams) > 0
  AND live.ads_id IS NOT NULL
  AND live.ads_id > 0
  AND COALESCE(live.internal.cpm_deduction_info.placement, placement) IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
  AND country IN ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
  AND userid > 0;

-- ============================================
-- Tracking Item 数据处理
-- 处理商品级别的追踪数据
-- ============================================
CREATE OR REPLACE TEMPORARY VIEW tracking_item_data AS
SELECT 
    coalesce_entrance AS entrance,
    CASE 
        WHEN (handler = 'keyword' AND keyword = 'wkdaelpmissisiht' AND coalesce_placement IN (0, 4400)) THEN 4
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
    CASE WHEN (handler IN ('keyword', 'boost','roi2','targeting','shop')) THEN `group_id` END AS `group_id`,
    CASE 
        WHEN handler = 'keyword' THEN
            CASE WHEN coalesce_placement = 4 THEN 'wkdaelpmissisiht' ELSE keyword END
        WHEN (handler = 'boost' AND coalesce_placement IN (1000, 1200)) THEN keyword
        WHEN handler = 'roi2' THEN keyword
    END AS keyword,
    CASE 
        WHEN handler IN ('keyword', 'roi2') THEN match_type
        WHEN (handler = 'boost' AND coalesce_placement IN (1000, 1200)) THEN match_type
    END AS match_type,
    CASE 
        WHEN handler IN ('keyword','roi2') THEN item_query.keyword
        WHEN handler IN ('boost') AND coalesce_placement IN (1000, 1200) THEN item_query.keyword 
    END AS `query`,
    CASE WHEN handler IN ('keyword', 'boost', 'roi2', 'targeting') THEN location_in_ads END AS location_in_ads,
    deduction_price,
    is_ocpm,
    operation,
    region,
    event_timestamp,
    handler,
    traffic_source,
    internal,
    CASE 
        WHEN (handler IN ('keyword','targeting') AND traffic_source = 4 AND 
              CASE WHEN (handler = 'keyword' AND keyword = 'wkdaelpmissisiht' AND coalesce_placement IN (0, 4400)) THEN 4 ELSE coalesce_placement END IN (44, 4400, 4401, 4402, 4405)) 
        THEN 1 
    END AS new_boost
FROM (
    SELECT 
        COALESCE(
            item.internal.deduction_info.placement,
            CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END
        ) AS coalesce_placement,
        COALESCE(
            CAST(GET_JSON_OBJECT(item.json_data, '$.entrance') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.entrance') AS INT)
        ) AS coalesce_entrance,
        COALESCE(
            CAST(GET_JSON_OBJECT(item.json_data, '$.pricing_type') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.pricing_type') AS INT)
        ) AS coalesce_pricing_type,
        userid AS user_id,
        item.adsid AS ads_id,
        item.itemid AS item_id,
        item.campaignid AS campaign_id,
        item.shopid AS shop_id,
        CAST(NULL AS BIGINT) AS account_id,
        CAST(NULL AS BIGINT) AS affiliate_id,
        COALESCE(
            CAST(GET_JSON_OBJECT(item.json_data, '$.ta_group_id') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.ta_group_id') AS INT)
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
        `timestamp` AS event_timestamp,
        CASE 
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (0, 4, 4400) THEN 'keyword'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) = 9 THEN 'display'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) = 65 THEN 'banner'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (40, 50) THEN 'roi2'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) = 45 THEN 'shop_cpm'
            WHEN COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) = 54 THEN 'video'
        END AS handler,
        -- Flink 使用 Redis TTL=3600s 的滚动窗口去重（可跨小时边界捕获重复事件）；
        -- Spark 使用 ROW_NUMBER() 在当前小时分区（h）内去重，无法处理跨小时边界的重复事件。
        -- 对于极少数在整点边界前后重复到达的事件，两者结果可能存在细微差异，属于可接受的设计差异。
        ROW_NUMBER() OVER (
            PARTITION BY country, operation, item.internal.duplicate_label, `timestamp`, userid, item.adsid, item.itemid, item.location_in_ads, 
                         COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END), 
                         item.json_data, json_data, item.request_id, item.internal.event_id 
            ORDER BY `timestamp`
        ) AS rn
    FROM mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
    LATERAL VIEW EXPLODE(items) AS item
    WHERE grass_region = UPPER('${region}')
      AND grass_date = '${BIZ_DT}'
      AND h = '${BIZ_H}'
      AND operation IN (1, 2, 21)
      AND items IS NOT NULL
      AND SIZE(items) > 0
      AND item.adsid IS NOT NULL
      AND item.adsid > 0
      AND COALESCE(item.internal.deduction_info.placement, CASE WHEN COALESCE(CAST(GET_JSON_OBJECT(item.json_data, '$.placement') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT)) = 7 THEN 7 END) IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 65, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
      AND country IN ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
      AND userid > 0
) item_with_rn
WHERE rn = 1;

-- ============================================
-- Tracking Shop 数据处理
-- 处理店铺级别的追踪数据
-- ============================================
CREATE OR REPLACE TEMPORARY VIEW tracking_shop_data AS
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
            CASE WHEN coalesce_placement IN (20, 2003, 2030) THEN '' ELSE keyword END
        WHEN handler = 'shop_cpm' THEN keyword
    END AS keyword,
    CASE WHEN handler IN ('shop','shop_cpm') THEN match_type END AS match_type,
    CASE WHEN handler IN ('shop','shop_cpm') THEN `query` END AS `query`,
    new_boost,
    CAST(NULL AS BIGINT) AS location_in_ads,
    deduction_price,
    is_ocpm,
    operation,
    region,
    event_timestamp,
    handler,
    internal
FROM (
    SELECT 
        COALESCE(
            shop.internal.deduction_info.placement,
            shop.internal.cpm_deduction_info.placement,
            CASE 
                WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7
                ELSE 0
            END
        ) AS coalesce_placement,
        COALESCE(
            CAST(GET_JSON_OBJECT(shop.json_data, '$.entrance') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.entrance') AS INT)
        ) AS coalesce_entrance,
        COALESCE(
            CAST(GET_JSON_OBJECT(shop.json_data, '$.pricing_type') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.pricing_type') AS INT)
        ) AS coalesce_pricing_type,
        userid AS user_id,
        COALESCE(
            CAST(GET_JSON_OBJECT(shop.json_data, '$.ads_id') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.ads_id') AS INT)
        ) AS ads_id,
        CAST(NULL AS BIGINT) AS item_id,
        COALESCE(
            CAST(GET_JSON_OBJECT(shop.json_data, '$.campaign_id') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.campaign_id') AS INT)
        ) AS campaign_id,
        shop.shopid AS shop_id,
        CAST(NULL AS BIGINT) AS account_id,
        CAST(NULL AS BIGINT) AS affiliate_id,
        COALESCE(
            CAST(GET_JSON_OBJECT(shop.json_data, '$.ta_group_id') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.ta_group_id') AS INT)
        ) AS group_id,
        COALESCE(
            GET_JSON_OBJECT(shop.json_data, '$.ads_keyword'),
            GET_JSON_OBJECT(json_data, '$.ads_keyword')
        ) AS keyword,
        COALESCE(
            CAST(GET_JSON_OBJECT(shop.json_data, '$.match_type') AS INT),
            CAST(GET_JSON_OBJECT(json_data, '$.match_type') AS INT)
        ) AS match_type,
        COALESCE(
            GET_JSON_OBJECT(shop.json_data, '$.query'),
            GET_JSON_OBJECT(json_data, '$.query')
        ) AS `query`,
        CAST(NULL AS BIGINT) AS new_boost,
        json_data,
        shop.json_data AS shop_json_data,
        CAST(NULL AS STRING) AS raw_request_id,
        shop.internal.duplicate_label AS duplicate_label,
        shop.internal.event_id AS event_id,
        shop.internal.deduction_info.deduction_price AS deduction_price,
        shop.internal AS internal,
        shop.internal.deduction_info.is_ocpm AS is_ocpm,
        operation,
        shop.ls_session_id AS ls_session_id,
        country AS region,
        `timestamp` AS event_timestamp,
        CASE 
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (0, 4, 4400) THEN 'keyword'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) = 9 THEN 'display'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) = 65 THEN 'banner'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (40, 50) THEN 'roi2'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) = 45 THEN 'shop_cpm'
            WHEN COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) = 54 THEN 'video'
        END AS handler,
        -- Flink 使用 Redis TTL=3600s 的滚动窗口去重（可跨小时边界捕获重复事件）；
        -- Spark 使用 ROW_NUMBER() 在当前小时分区（h）内去重，无法处理跨小时边界的重复事件。
        -- 对于极少数在整点边界前后重复到达的事件，两者结果可能存在细微差异，属于可接受的设计差异。
        ROW_NUMBER() OVER (
            PARTITION BY country, operation, shop.internal.duplicate_label, `timestamp`, userid, 
                         COALESCE(CAST(GET_JSON_OBJECT(shop.json_data, '$.ads_id') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.ads_id') AS INT)), 
                         CAST(NULL AS BIGINT), CAST(NULL AS BIGINT),
                         COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END),
                         shop.json_data, json_data, CAST(NULL AS STRING), shop.internal.event_id 
            ORDER BY `timestamp`
        ) AS rn
    FROM mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
    LATERAL VIEW EXPLODE(shops) AS shop
    WHERE grass_region = UPPER('${region}')
      AND grass_date = '${BIZ_DT}'
      AND h = '${BIZ_H}'
      AND operation IN (1001, 1002)
      AND shops IS NOT NULL
      AND SIZE(shops) > 0
      AND COALESCE(CAST(GET_JSON_OBJECT(shop.json_data, '$.ads_id') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.ads_id') AS INT)) IS NOT NULL
      AND COALESCE(CAST(GET_JSON_OBJECT(shop.json_data, '$.ads_id') AS INT), CAST(GET_JSON_OBJECT(json_data, '$.ads_id') AS INT)) > 0
      AND COALESCE(shop.internal.deduction_info.placement, shop.internal.cpm_deduction_info.placement, CASE WHEN (CAST(GET_JSON_OBJECT(shop.json_data, '$.placement') AS INT) = 7 OR CAST(GET_JSON_OBJECT(json_data, '$.placement') AS INT) = 7) THEN 7 ELSE 0 END) IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 65, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
      AND country IN ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
      AND userid > 0
) shop_with_rn
WHERE rn = 1;

-- ============================================
-- Tracking Video 数据处理
-- 处理视频广告追踪数据
-- ============================================
CREATE OR REPLACE TEMPORARY VIEW tracking_video_data AS
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
    `query`,
    new_boost,
    CASE WHEN handler = 'video' THEN location_in_ads END AS location_in_ads,
    CASE WHEN (operation = 22 AND handler = 'video') THEN view_duration END AS view_duration,
    operation,
    region,
    event_timestamp,
    handler,
    internal,
    internal_label
FROM (
    SELECT 
        COALESCE(video.internal.cpm_deduction_info.placement, placement) AS coalesce_placement,
        entrance,
        CAST(GET_JSON_OBJECT(video.json_data, '$.pricing_type') AS INT) AS coalesce_pricing_type,
        userid AS user_id,
        video.ads_id,
        CAST(NULL AS BIGINT) AS item_id,
        CAST(GET_JSON_OBJECT(video.json_data, '$.campaign_id') AS INT) AS campaign_id,
        video.shop_id AS shop_id,
        CAST(GET_JSON_OBJECT(video.json_data, '$.account_id') AS INT) AS account_id,
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
        `timestamp` AS event_timestamp,
        CASE 
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (0, 4, 4400) THEN 'keyword'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) = 9 THEN 'display'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) = 65 THEN 'banner'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (40, 50) THEN 'roi2'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) = 45 THEN 'shop_cpm'
            WHEN COALESCE(video.internal.cpm_deduction_info.placement, placement) = 54 THEN 'video'
        END AS handler,
        -- Flink 使用 Redis TTL=3600s 的滚动窗口去重（可跨小时边界捕获重复事件）；
        -- Spark 使用 ROW_NUMBER() 在当前小时分区（h）内去重，无法处理跨小时边界的重复事件。
        -- 对于极少数在整点边界前后重复到达的事件，两者结果可能存在细微差异，属于可接受的设计差异。
        ROW_NUMBER() OVER (
            PARTITION BY country, operation, video.internal.duplicate_label, `timestamp`, userid, video.ads_id, 
                         CAST(NULL AS BIGINT), video.location_in_ads,
                         COALESCE(video.internal.cpm_deduction_info.placement, placement),
                         video.json_data, json_data, video.request_id, video.internal.event_id 
            ORDER BY `timestamp`
        ) AS rn
    FROM mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
    LATERAL VIEW EXPLODE(videos) AS video
    WHERE grass_region = UPPER('${region}')
      AND grass_date = '${BIZ_DT}'
      AND h = '${BIZ_H}'
      AND operation IN (1, 2, 14, 21, 22)
      AND videos IS NOT NULL
      AND SIZE(videos) > 0
      AND video.ads_id IS NOT NULL
      AND video.ads_id > 0
      AND COALESCE(video.internal.cpm_deduction_info.placement, placement) IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 65, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54)
      AND country IN ('my','sg','th','id','vn','ph','tw','br','mx','co','cl','ar','MY','SG','TH','ID','VN','PH','TW','BR','MX','CO','CL','AR','ALL')
      AND userid > 0
) video_with_rn
WHERE rn = 1;

-- ============================================
-- Translog 数据处理
-- 处理交易日志数据, 计算cost等关键指标
-- ============================================
CREATE OR REPLACE TEMPORARY VIEW translog_report_data AS
SELECT 
    entrance,
    placement,
    pricing_type,
    user_id,
    ads_id,
    item_id,
    campaign_id,
    shop_id,
    CASE WHEN handler IN ('livestream','video','banner') THEN account_id END AS account_id,
    CASE 
        WHEN handler IN ('livestream') AND (target_affiliate_user_id IS NULL OR target_affiliate_user_id = 0) THEN account_id
        WHEN handler IN ('livestream') THEN target_affiliate_user_id
    END AS affiliate_id,
    CASE
        WHEN handler IN ('boost','keyword','roi2', 'targeting') THEN 
            COALESCE(
                CAST(GET_JSON_OBJECT(item_ads_data_str, '$.ta_group_id') AS INT),
                CAST(GET_JSON_OBJECT(root_ads_data_str, '$.ta_group_id') AS INT)
            )
        WHEN handler IN ('shop') THEN 
            COALESCE(
                CAST(GET_JSON_OBJECT(shop_ads_data_str, '$.ta_group_id') AS INT),
                CAST(GET_JSON_OBJECT(root_ads_data_str, '$.ta_group_id') AS INT)
            )
        ELSE CAST(NULL AS BIGINT)
    END AS group_id,
    CASE
        WHEN handler IN ('keyword') THEN 
            CASE WHEN (placement = 4) THEN 'wkdaelpmissisiht' ELSE keyword END
        WHEN handler IN ('roi2', 'banner') THEN keyword
        WHEN handler IN ('boost') THEN 
            CASE WHEN (placement IN (1200, 1000)) THEN keyword END
        WHEN handler IN ('shop') THEN 
            CASE WHEN (placement IN (20, 2003, 2030)) THEN '' ELSE keyword END
        WHEN handler IN ('shop_cpm') THEN 
            COALESCE(
                GET_JSON_OBJECT(shop_ads_data_str, '$.ads_keyword'),
                GET_JSON_OBJECT(root_ads_data_str, '$.ads_keyword')
            )
        ELSE CAST(NULL AS STRING)
    END AS keyword,
    CASE
        WHEN handler IN ('keyword','roi2', 'shop') THEN match_type
        WHEN handler IN ('boost') AND placement IN (1000, 1200) THEN match_type
        WHEN handler IN ('shop_cpm') THEN 
            COALESCE(
                CAST(GET_JSON_OBJECT(shop_ads_data_str, '$.match_type') AS INT),
                CAST(GET_JSON_OBJECT(root_ads_data_str, '$.match_type') AS INT)
            )
        ELSE CAST(NULL AS INT)
    END AS match_type,
    CASE 
        WHEN handler IN ('boost') AND placement IN (1000, 1200) THEN GET_JSON_OBJECT(`query`, '$.keyword')
        WHEN handler IN ('keyword','roi2','shop') THEN GET_JSON_OBJECT(`query`, '$.keyword')
        WHEN handler IN ('shop_cpm') THEN COALESCE(GET_JSON_OBJECT(shop_ads_data_str, '$.query'), GET_JSON_OBJECT(root_ads_data_str, '$.query')) 
    END AS `query`,
    CASE 
        WHEN (handler IN ('keyword','targeting') AND traffic_source = 4 AND placement IN (44, 4400, 4401, 4402, 4405)) THEN 1 
    END AS new_boost,
    CASE WHEN handler IN ('livestream','shop_cpm') THEN ls_session_id END AS ls_session_id,
    region,
    event_timestamp,
    handler,
    cost,
    expected_revenue,
    expense_paid_credit_without_expiry,
    expense_paid_credit_with_expiry,
    expense_free_credit_without_expiry,
    expense_free_credit_with_expiry,
    deduct_click_cnt,
    deduct_imp_cnt,
    CASE WHEN handler IN ('keyword','boost','roi2','targeting') THEN location_in_ads END AS location_in_ads,
    grass_date,
    h
FROM (
    SELECT 
        CASE 
            WHEN placement IN (0, 4, 4400) THEN 'keyword'
            WHEN placement IN (1, 2, 5, 8, 801, 802, 805, 4401, 4402, 4405) THEN 'targeting'
            WHEN placement IN (3, 7, 20, 2003, 2030, 46) THEN 'shop'
            WHEN placement IN (1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205) THEN 'boost'
            WHEN placement IN (9) THEN 'display'
            WHEN placement IN (65) THEN 'banner'
            WHEN placement IN (3327, 3328, 3337, 3338, 3339, 3342, 3348) THEN 'livestream'
            WHEN placement IN (40, 50) THEN 'roi2'
            WHEN placement IN (45) THEN 'shop_cpm'
            WHEN placement IN (54) THEN 'video'
        END AS handler,
        expense_paid_credit_without_expiry + expense_paid_credit_with_expiry + expense_free_credit_without_expiry + expense_free_credit_with_expiry AS cost,
        ROW_NUMBER() OVER (PARTITION BY region, shop_id, translog.deduct_unique_id ORDER BY event_timestamp ASC) AS rn,
        entrance,
        placement,
        pricing_type,
        user_id,
        ads_id,
        item_id,
        campaign_id,
        shop_id,
        account_id,
        keyword,
        match_type,
        root_ads_data_str,
        item_ads_data_str,
        shop_ads_data_str,
        region,
        event_timestamp,
        location_in_ads,
        expected_revenue,
        expense_paid_credit_without_expiry,
        expense_paid_credit_with_expiry,
        expense_free_credit_without_expiry,
        expense_free_credit_with_expiry,
        deduct_click_cnt,
        deduct_imp_cnt,
        target_affiliate_user_id,
        `query`,
        ls_session_id,
        traffic_source,
        grass_date,
        h
    FROM (
        SELECT 
            BIGINT(entrance) AS entrance,
            translog.placement AS placement,
            BIGINT(pricing_type) AS pricing_type,
            translog.userid AS user_id,
            translog.adsid AS ads_id,
            translog.itemid AS item_id,
            BIGINT(campaign_id) AS campaign_id,
            translog.shopid AS shop_id,
            translog.account_id AS account_id,
            translog.keyword AS keyword,
            BIGINT(match_type) AS match_type,
            root_ads_data_str,
            item_ads_data_str,
            shop_ads_data_str,
            translog,
            region,
            translog.`timestamp` AS event_timestamp,
            location_in_ads,
            AGGREGATE(FILTER(entries_arr, x -> x.type = 1), BIGINT(0), (acc, x) -> acc + BIGINT(x.amount)) AS expense_paid_credit_without_expiry,
            AGGREGATE(FILTER(entries_arr, x -> x.type = 2), BIGINT(0), (acc, x) -> acc + BIGINT(x.amount)) AS expense_paid_credit_with_expiry,
            AGGREGATE(FILTER(entries_arr, x -> x.type = 3), BIGINT(0), (acc, x) -> acc + BIGINT(x.amount)) AS expense_free_credit_without_expiry,
            AGGREGATE(FILTER(entries_arr, x -> x.type = 4), BIGINT(0), (acc, x) -> acc + BIGINT(x.amount)) AS expense_free_credit_with_expiry,
            expected_revenue,
            deduct_click_cnt,
            deduct_imp_cnt,
            BIGINT(target_affiliate_user_id) AS target_affiliate_user_id,
            `query`,
            BIGINT(ls_session_id) AS ls_session_id,
            traffic_source,
            grass_date,
            h
        FROM (
            SELECT  
                JSON_FROM_PROTOBUF(GET_JSON_OBJECT(TO_JSON(translog_src.translog), '$.extinfo')) AS extinfo,
                translog_src.translog,
                translog_src.root_ads_data_str,
                translog_src.item_ads_data_str,
                translog_src.shop_ads_data_str,
                CASE WHEN translog_src.translog.operation IN (1, 15) THEN translog_src.translog.dai_after_balance - translog_src.translog.dai_before_balance ELSE 0 END AS expected_revenue,
                CASE WHEN translog_src.translog.operation = 1 THEN 1 END AS deduct_click_cnt,
                CASE WHEN translog_src.translog.operation = 11 THEN SIZE(translog_src.imp_cost_details) END AS deduct_imp_cnt,
                extinfo_parsed.entrance,
                extinfo_parsed.pricing_type,
                extinfo_parsed.campaign_id,
                extinfo_parsed.match_type,
                FROM_JSON(GET_JSON_OBJECT(extinfo_parsed.paid_free_expiry_summary, '$.entries'), 'array<struct<type:int,amount:string>>') AS entries_arr,
                extinfo_parsed.target_affiliate_user_id,
                extinfo_parsed.`query`,
                extinfo_parsed.ls_session_id,
                translog_src.location_in_ads,
                translog_src.traffic_source,
                translog_src.grass_region AS region,
                translog_src.grass_date,
                translog_src.h
            FROM mp_paidads.ods_log_translog_event_hi__reg_s0_live translog_src
            LATERAL VIEW JSON_TUPLE(
                JSON_FROM_PROTOBUF(GET_JSON_OBJECT(TO_JSON(translog_src.translog), '$.extinfo')),
                'entrance', 'pricingType', 'campaignid', 'matchType', 'paidFreeExpirySummary',
                'targetAffiliateUserId', 'query', 'lsSessionId'
            ) extinfo_parsed AS entrance, pricing_type, campaign_id, match_type, paid_free_expiry_summary,
              target_affiliate_user_id, `query`, ls_session_id
            WHERE grass_region = UPPER('${region}')
              AND grass_date = '${BIZ_DT}'
              AND h = '${BIZ_H}'
              AND translog_src.translog.operation IN (1, 11, 15)
        ) translog_detail
    ) translog_general
) translog_with_handler
WHERE placement IN (0, 1, 2, 3, 4, 5, 7, 8, 9, 20, 40, 801, 802, 805, 1000, 1001, 1002, 1005, 1200, 1201, 1202, 1205, 2003, 2030, 3327, 3328, 3337, 3338, 3339, 3342, 3348, 46, 4400, 4401, 4402, 4405, 45, 50, 54, 65)
  AND rn = 1;

-- ============================================
-- 最终INSERT语句
-- 汇总所有数据源到目标表
-- ============================================
INSERT OVERWRITE TABLE dwd_advertise_seller_report_hi__reg_s0_live 
PARTITION (grass_region, grass_date, h)

-- Display Tracking Banner数据
SELECT 
    3 AS source,
    3 AS sub_source,
    operation,
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
    group_id,
    keyword,
    match_type,
    region,
    event_timestamp,
    CASE WHEN operation = 2 THEN 1 ELSE 0 END AS raw_click,
    CASE WHEN operation = 1 THEN 1 ELSE 0 END AS raw_imp,
    location_in_ads,
    CASE WHEN (operation = 2 AND handler IN ('display', 'shop_cpm', 'banner') AND (banner.banner_internal.frauds IS NULL OR SIZE(banner.banner_internal.frauds) <= 0)) THEN 1 ELSE 0 END AS non_fraud_click,
    CASE WHEN (operation = 1 AND handler IN ('display', 'banner')) THEN banner.banner_internal.cpm END AS cpm,
    CASE WHEN (operation = 1 AND handler IN ('display','banner')) THEN banner.banner_internal.cpm / 1000 END AS cost_by_cpm,
    NULL AS shop_item_impression,
    NULL AS shop_item_click,
    CASE WHEN operation = 13 THEN 1 END AS `view`,
    CASE WHEN (operation = 21 AND handler IN ('boost','display','keyword','livestream','roi2','targeting', 'banner')) THEN 1 END AS video_view,
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
    CASE WHEN (operation = 2 AND handler in ('display', 'shop_cpm', 'banner') AND (banner.banner_internal.duplicate_label IS NULL OR banner.banner_internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS dedup_click,
    NULL AS `query`,
    NULL AS new_boost,
    NULL AS ls_session_id,
    NULL AS non_fraud_impression,
    NULL AS view_duration,
    NULL AS product_click,
    CASE WHEN (operation = 1 AND handler IN ('display','banner')) THEN banner.banner_internal.cpm / 1000 END AS raw_expense,
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
    CONCAT('display_tracking-', handler) AS handler,
    region AS grass_region,
    TO_DATE('${BIZ_DT}', 'yyyy-MM-dd') AS grass_date,
    CAST('${BIZ_H}' AS BIGINT) AS h
FROM display_tracking_banner

UNION ALL

-- Livestream Tracking数据
SELECT 
    4 AS source,
    4 AS sub_source,
    operation,
    CAST(coalesce_entrance AS INT) AS entrance,
    coalesce_placement AS placement,
    pricing_type,
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
    region,
    event_timestamp,
    CASE WHEN operation = 2 THEN 1 ELSE 0 END AS raw_click,
    CASE WHEN operation = 1 THEN 1 ELSE 0 END AS raw_imp,
    location_in_ads,
    CASE WHEN (operation = 2 AND handler in ('boost','display','keyword','livestream','roi2','targeting') AND (internal.frauds IS NULL OR SIZE(internal.frauds) <= 0)) THEN 1 END AS non_fraud_click,
    CASE WHEN (operation = 1 AND handler = 'livestream') THEN internal.cpm_deduction_info.cpm END AS cpm,
    CASE WHEN (operation = 1 AND handler = 'livestream') THEN internal.cpm_deduction_info.cpm / 1000 END AS cost_by_cpm,
    NULL AS shop_item_impression,
    NULL AS shop_item_click,
    CASE WHEN (operation = 13 AND handler IN ('boost','display','keyword','livestream','roi2','targeting')) THEN 1 END AS `view`,
    CASE WHEN (operation = 21 AND handler IN ('boost','display','keyword','livestream','roi2','targeting')) THEN 1 END AS video_view,
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
    CASE WHEN operation = 2 THEN 1 ELSE 0 END AS dedup_click,
    NULL AS `query`,
    NULL AS new_boost,
    ls_session_id,
    CASE WHEN (operation = 1 AND handler IN ('boost','display','keyword','livestream','roi2','targeting') AND (internal.frauds IS NULL OR CARDINALITY(internal.frauds) = 0)) THEN 1 ELSE 0 END AS non_fraud_impression,
    CASE WHEN (operation = 15 AND handler IN ('boost','display','keyword','livestream','roi2','targeting')) THEN view_duration END AS view_duration,
    CASE WHEN (operation = 14) THEN 1 END AS product_click,
    CASE WHEN (operation = 1 AND handler = 'livestream') THEN internal.cpm_deduction_info.cpm / 1000 END AS raw_expense,
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
    CONCAT('livestream_tracking-', handler) AS handler,
    region AS grass_region,
    TO_DATE('${BIZ_DT}', 'yyyy-MM-dd') AS grass_date,
    CAST('${BIZ_H}' AS BIGINT) AS h
FROM livestream_tracking_data

UNION ALL

-- Reportng数据
SELECT  
    5 AS source,
    NULL AS sub_source,
    NULL AS operation,
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
    ta_group_id AS group_id,
    keyword,
    match_type,
    country AS region,
    `timestamp` AS event_timestamp,
    NULL AS raw_click,
    NULL AS raw_imp,
    NULL AS location_in_ads,
    NULL AS non_fraud_click,
    NULL AS cpm,
    NULL AS cost_by_cpm,
    shop_item_impression,
    shop_item_click,
    NULL AS `view`,
    NULL AS video_view,
    pageview,
    NULL AS click,
    NULL AS `cost`,
    `order`,
    order_amount,
    order_gmv,
    broad_order,
    broad_item_count,
    broad_gmv,
    checkout,
    NULL AS dedup_click,
    `query`,
    new_boost,
    ls_session_id,
    NULL AS non_fraud_impression,
    NULL AS view_duration,
    NULL AS product_click,
    NULL AS raw_expense,
    NULL AS impression,
    NULL AS expected_revenue,
    NULL AS expense_paid_credit_without_expiry,
    NULL AS expense_paid_credit_with_expiry,
    NULL AS expense_free_credit_without_expiry,
    NULL AS expense_free_credit_with_expiry,
    daily_order,
    daily_gmv,
    broad_shop_item_imp,
    broad_shop_item_click,
    add_to_cart,
    paid_broad_gmv,
    paid_order_gmv,
    paid_broad_order,
    paid_order,
    paid_checkout,
    paid_broad_order_amount,
    paid_order_amount,
    'reportng' AS handler,
    country AS grass_region,
    grass_date,
    h
FROM mp_paidads.ods_log_ads_report_hi__reg_s0_live
WHERE grass_region = UPPER('${region}')
  AND grass_date = '${BIZ_DT}'
  AND h = '${BIZ_H}'
  AND (
       (shop_item_impression IS NOT NULL AND shop_item_impression <> 0) 
    OR (shop_item_click IS NOT NULL AND shop_item_click <> 0) 
    OR (pageview IS NOT NULL AND pageview <> 0) 
    OR (broad_shop_item_imp IS NOT NULL AND broad_shop_item_imp <> 0) 
    OR (broad_shop_item_click IS NOT NULL AND broad_shop_item_click <> 0) 
    OR (add_to_cart IS NOT NULL AND add_to_cart <> 0)
    OR (`order` IS NOT NULL AND `order` <> 0)
    OR (`order_amount` IS NOT NULL AND `order_amount` <> 0)
    OR (`order_gmv` IS NOT NULL AND `order_gmv` <> 0)
    OR (`broad_order` IS NOT NULL AND `broad_order` <> 0)
    OR (`broad_gmv` IS NOT NULL AND `broad_gmv` <> 0)
    OR (`broad_item_count` IS NOT NULL AND `broad_item_count` <> 0)
    OR (`checkout` IS NOT NULL AND `checkout` <> 0)
    OR (`daily_order` IS NOT NULL AND `daily_order` <> 0)
    OR (`daily_gmv` IS NOT NULL AND `daily_gmv` <> 0)
    OR (`paid_broad_gmv` IS NOT NULL AND `paid_broad_gmv` <> 0)
    OR (`paid_order_gmv` IS NOT NULL AND `paid_order_gmv` <> 0)
    OR (`paid_broad_order` IS NOT NULL AND `paid_broad_order` <> 0)
    OR (`paid_order` IS NOT NULL AND `paid_order` <> 0)
    OR (`paid_checkout` IS NOT NULL AND `paid_checkout` <> 0)
    OR (`paid_broad_order_amount` IS NOT NULL AND `paid_broad_order_amount` <> 0)
    OR (`paid_order_amount` IS NOT NULL AND `paid_order_amount` <> 0)
  )

UNION ALL

-- Tracking Item数据
SELECT 
    0 AS source,
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
        ELSE 0 
    END AS raw_imp,
    CASE WHEN handler IN ('boost','keyword','roi2','targeting') THEN location_in_ads END AS location_in_ads,
    CASE
        WHEN (operation = 2 AND handler in ('boost','keyword','roi2','targeting') AND (internal.frauds IS NULL OR SIZE(internal.frauds) = 0)) THEN 1 
        ELSE 0 
    END AS non_fraud_click,
    CASE WHEN (operation = 1 AND is_ocpm AND handler in ('boost','keyword','roi2','targeting')) then deduction_price end AS cpm,
    CASE WHEN (operation = 1 AND is_ocpm AND handler in ('boost','keyword','roi2','targeting')) then deduction_price end AS cost_by_cpm,
    NULL AS shop_item_impression,
    NULL AS shop_item_click,
    NULL AS `view`,
    CASE WHEN (operation = 21 AND handler IN ('boost','display','keyword','livestream','roi2','targeting')) THEN 1 END AS video_view,
    NULL AS pageview,
    CASE WHEN (operation = 2 AND is_ocpm AND handler in ('boost','keyword','roi2','targeting') AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS click,
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
    CONCAT('tracking-', handler) AS handler,
    region AS grass_region,
    TO_DATE('${BIZ_DT}', 'yyyy-MM-dd') AS grass_date,
    CAST('${BIZ_H}' AS BIGINT) AS h
FROM tracking_item_data

UNION ALL

-- Tracking Shop数据
SELECT 
    0 AS source,
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
    CAST(NULL AS BIGINT) AS location_in_ads,
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
    CONCAT('tracking-', handler) AS handler,
    region AS grass_region,
    TO_DATE('${BIZ_DT}', 'yyyy-MM-dd') AS grass_date,
    CAST('${BIZ_H}' AS BIGINT) AS h
FROM tracking_shop_data

UNION ALL

-- Tracking Video数据
SELECT 
    0 AS source,
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
        WHEN (operation = 21 AND handler = 'video') THEN 1
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
    CASE WHEN (operation = 14 AND handler = 'video' AND (internal.duplicate_label IS NULL OR internal.duplicate_label <= 0)) THEN 1 ELSE 0 END AS product_click,
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
    CONCAT('tracking-', handler) AS handler,
    region AS grass_region,
    TO_DATE('${BIZ_DT}', 'yyyy-MM-dd') AS grass_date,
    CAST('${BIZ_H}' AS BIGINT) AS h
FROM tracking_video_data

UNION ALL

-- Translog数据
SELECT  
    1 AS source,
    CAST(NULL AS INT) AS sub_source,
    CAST(NULL AS INT) AS operation,
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
    group_id,
    keyword,
    match_type,
    region,
    event_timestamp,
    NULL AS raw_click,
    NULL AS raw_imp,
    location_in_ads,
    NULL AS non_fraud_click,
    NULL AS cpm,
    NULL AS cost_by_cpm,
    NULL AS shop_item_impression,
    NULL AS shop_item_click,
    NULL AS `view`,
    NULL AS video_view,
    NULL AS pageview,
    deduct_click_cnt AS click,
    cost,
    NULL AS `order`,
    NULL AS order_amount,
    NULL AS order_gmv,
    NULL AS broad_order,
    NULL AS broad_item_count,
    NULL AS broad_gmv,
    NULL AS checkout,
    NULL AS dedup_click,
    `query`,
    new_boost,
    ls_session_id,
    NULL AS non_fraud_impression,
    NULL AS view_duration,
    NULL AS product_click,
    NULL AS raw_expense,
    deduct_imp_cnt AS impression,
    expected_revenue,
    expense_paid_credit_without_expiry,
    expense_paid_credit_with_expiry,
    expense_free_credit_without_expiry,
    expense_free_credit_with_expiry,
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
    CONCAT('translog-', handler) AS handler,
    region AS grass_region,
    grass_date,
    h
FROM translog_report_data;