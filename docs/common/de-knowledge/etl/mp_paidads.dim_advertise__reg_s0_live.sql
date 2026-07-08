-- task_code: data_paidadsmart.studio_2623793  asset_id: 2623793
-- in order to prevent file do not exist problem caused by small files compact
refresh table mp_paidads.ods_log_shop_ads_index_hi__reg_s0_live;

CREATE OR REPLACE TEMPORARY VIEW advertise_tab_df AS
(
    SELECT campaignid AS campaign_id
        , shopid AS shop_id
        , userid AS user_id
        , adsid AS ads_id
        , itemid AS item_id
        , create_timestamp
        , create_datetime
        , modify_timestamp
        , modify_datetime
        , status
        , placement
        ,extinfo_keywords as keywords
        ,extinfo_target_price as target_price
        ,extinfo_target_premium_rate as target_premium_rate 
        ,extinfo_target_base_price as target_base_price
        , extinfo_target_segments
        ,extinfo_target_roi as target_roi
        ,case when extinfo_target_roi=0 then 1 else 0 end as target_roi_type
        ,extinfo_shop_customisation_display_title as shop_customisation_display_title
        ,extinfo_shop_customisation_image_url as shop_customisation_image_url
        ,extinfo_shop_customisation_collection_id as shop_customisation_collection_id
        ,extinfo_banner_image_uri_pc as banner_image_uri_pc
        ,extinfo_banner_image_image_uri_app as banner_image_image_uri_app
        ,extinfo_banner_keywords as banner_keywords
        ,extinfo_banner_landing_page_url as  banner_landing_page_url
        , boost_id
        , boost_package_id
        , boost_price
        , boost_days
        , boost_est_views
        , extinfo_pricing_type as pricing_type
        , auto_boost_algo_status
        , target_affiliate_user_id
        ,post_id
        ,video_id
        ,first_delivery_timestamp
        ,date_format(from_utc_timestamp(to_utc_timestamp(cast(first_delivery_timestamp as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as first_delivery_datetime
        ,potential_product_type
        ,search_brand_package_order_id
        ,is_nominated_for_package_non_ads
        ,is_organic_non_ads
        ,brand_max_type
        ,brand_max_package_request_id
        , grass_region
        , DATE('${grass_date}') AS grass_date
    FROM (
        SELECT
          campaignid
        , shopid
        , userid
        , adsid
        , itemid
        , ctime AS create_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as create_datetime
        , mtime AS modify_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(mtime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as modify_datetime
        , status
        , CASE 
            WHEN placement = 8      THEN ARRAY(801,802,805)
            WHEN placement = 10     THEN ARRAY(1000,1001,1002,1005) 
            WHEN placement = 12     THEN ARRAY(1200,1202,1205)
            WHEN placement = 20     THEN ARRAY(20,2003,2030) -- 20 和 2003，2030会同时存在
            WHEN placement = 33     THEN ARRAY(33,3327,3328,3337,3338,3339,3342,3348) 
            WHEN placement = 44     THEN ARRAY(4400,4401,4402,4405)
            ELSE ARRAY(placement) 
          END AS placement_array
        , CASE
            WHEN SIZE(decoded_extinfo.keywords) > 0 THEN to_json(decoded_extinfo.keywords)
            ELSE NULL
          END AS extinfo_keywords
        , CAST(decoded_extinfo.target.price AS BIGINT) / 100000.0 AS extinfo_target_price
        , decoded_extinfo.target.premium_rate AS extinfo_target_premium_rate
        , CAST(decoded_extinfo.target.base_price AS DOUBLE) / 100000.0 AS extinfo_target_base_price
        , CASE
            WHEN SIZE(decoded_extinfo.target.segments) > 0 THEN to_json(decoded_extinfo.target.segments)
            ELSE NULL
          END AS extinfo_target_segments
        , cast(decoded_extinfo.target_roi as int) AS extinfo_target_roi
        , decoded_extinfo.shop_customisation.display_title AS extinfo_shop_customisation_display_title
        , decoded_extinfo.shop_customisation.image_url AS extinfo_shop_customisation_image_url
        , CAST(decoded_extinfo.shop_customisation.collection_id AS BIGINT) AS extinfo_shop_customisation_collection_id
        , decoded_extinfo.banner.image_uri_pc AS extinfo_banner_image_uri_pc
        , decoded_extinfo.banner.image_uri_app AS extinfo_banner_image_image_uri_app
        , CASE
            WHEN SIZE(decoded_extinfo.banner.keywords) > 0 THEN concat_ws(',', decoded_extinfo.banner.keywords)
            ELSE NULL
          END AS extinfo_banner_keywords
        , decoded_extinfo.banner.landing_page_url AS extinfo_banner_landing_page_url
        , CAST(decoded_extinfo.boost.id AS BIGINT) as boost_id
        , CAST(decoded_extinfo.boost.package_id AS BIGINT) as boost_package_id
        , CAST(decoded_extinfo.boost.price AS DOUBLE) as boost_price
        , CAST(decoded_extinfo.boost.days AS INT) as boost_days
        , CAST(decoded_extinfo.boost.est_views AS BIGINT) as boost_est_views
        , CAST(decoded_extinfo.pricing_type AS INT) as extinfo_pricing_type
        , CAST(decoded_extinfo.auto_boost.algo_status AS INT) as auto_boost_algo_status
        , CAST(decoded_extinfo.live_stream.target_affiliate_user_id AS BIGINT) as target_affiliate_user_id
        , CAST(decoded_extinfo.video.post_id AS BIGINT) as post_id
        , decoded_extinfo.video.video_id as video_id
        , CAST(decoded_extinfo.first_delivery_time.value AS BIGINT) as first_delivery_timestamp
        , CAST(decoded_extinfo.potential_product.`type` as int) as potential_product_type
        , decoded_extinfo.search_brand.package_order_id as search_brand_package_order_id
        , CAST(decoded_extinfo.non_ads_info.is_nominated_for_package as tinyint) as is_nominated_for_package_non_ads
        , CAST(decoded_extinfo.non_ads_info.is_organic as tinyint) as is_organic_non_ads
        ,decoded_extinfo.brand_max.brand_max_type as brand_max_type
        ,cast(decoded_extinfo.brand_max.package_request_id as bigint) as brand_max_package_request_id
        , ucase('${region}') as grass_region
      FROM(
        SELECT 
           campaignid
          , shopid
          , userid
          , adsid
          , itemid
          , ctime
          , mtime
          , status
          , placement
          , from_json(_decoded_extinfo, 'struct<keywords:array<
                                                    struct<
                                                    keyword:string,
                                                    price:string,
                                                    status:int,
                                                    match_type:int,
                                                    algorithm:string
                                                >>,
                                                target:struct<
                                                    price:string,
                                                    premium_rate:int,
                                                    base_price:string,
                                                    segments:array<struct<
                                                    segment_type_id:int,
                                                    segment_cluster_id:array<string>,
                                                    segment_premium_rate:string,
                                                    final_bid_price:string
                                                    >>
                                                >,
                                                target_roi:int,
                                                shop_customisation:struct<
                                                    display_title:string,
                                                    image_url:string,
                                                    collection_id:string
                                                >,
                                                banner:struct<
                                                    image_uri_pc:string,
                                                    image_uri_app:string,
                                                    keywords:array<string>,
                                                    landing_page_url:string
                                                >,
                                                display:struct<
                                                    image_pc:string,
                                                    image_mobile:string,
                                                    item_id:array<string>,
                                                    l1_cat_id:string,
                                                    under_promotion:boolean,
                                                    promo_discount_value:string,
                                                    promo_discount_unit:string,
                                                    copywriting_text:string,
                                                    target_url:string
                                                >,
                                                boost:struct<
                                                    id:string,
                                                    package_id:int,
                                                    price:string,
                                                    days:int,
                                                    est_views:string
                                                >,
                                                pricing_type:int,
                                                delivery:struct<
                                                    entry_points:array<int>,
                                                    entrances:array<int>
                                                >,
                                                auto_boost:struct<
                                                    algo_status:int
                                                >,
                                                live_stream:struct<
                                                    objective:int,
                                                    cpm:string,
                                                    target_affiliate_user_id:string
                                                >,
                                                search_brand:struct<
                                                    package_order_id:string
                                                >,
                                                 video:struct<
                                                    objective:int,
                                                    post_id:string,
                                                    video_id:string
                                                >,
                                                first_delivery_time:struct<
                                                    value:string
                                                >,
                                                potential_product:struct<
                                                    type:string,
                                                    last_refresh_time:string
                                                >,
                                                brand_max:struct<
                                                    brand_max_type:int,
                                                    package_request_id:string
                                                >,
                                                non_ads_info:struct<
                                                    is_nominated_for_package:boolean,
                                                    is_organic:boolean
                                                >
                                            >') AS decoded_extinfo
            from(                               
                select /*+ REPARTITION(1000) */  
                    campaignid
                    , shopid
                    , userid
                    , adsid
                    , itemid
                    , ctime
                    , mtime
                    , status
                    , placement
                    , _decoded_extinfo
                FROM mp_paidads.shopee_ads_${region}_${db_type}__advertisement_tab__reg_continuous_s0_live
                WHERE ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
            )
        )
    )
    lateral view explode(placement_array) as placement
);

cache table  ads_item_ids OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
SELECT DISTINCT item_id
FROM (
    SELECT /*+ REPARTITION(1000) */ itemid AS item_id
    FROM mp_paidads.shopee_ads_${region}_${db_type}__advertisement_tab__reg_continuous_s0_live
    WHERE itemid IS NOT NULL
) ;


CREATE OR REPLACE TEMPORARY VIEW fe_display_category AS
SELECT
  d.item_id
  ,COLLECT_LIST(
    STRUCT(
      d.level1_fe_display_category_id,
      d.level1_fe_display_category,
      d.level1_fe_display_category_fraction_factor
    )
  ) FILTER (
    WHERE d.fe_display_category_level = 1
      AND d.level1_fe_display_category_id IS NOT NULL
  ) AS level1_fe_display_category_list

  ,COLLECT_LIST(
    STRUCT(
      d.level2_fe_display_category_id,
      d.level2_fe_display_category,
      d.level2_fe_display_category_fraction_factor
    )
  ) FILTER (
    WHERE d.fe_display_category_level = 2
      AND d.level2_fe_display_category_id IS NOT NULL
  ) AS level2_fe_display_category_list

  ,COLLECT_LIST(
    STRUCT(
      d.level3_fe_display_category_id,
      d.level3_fe_display_category,
      d.level3_fe_display_category_fraction_factor
    )
  ) FILTER (
    WHERE d.fe_display_category_level = 3
      AND d.level3_fe_display_category_id IS NOT NULL
  ) AS level3_fe_display_category_list
FROM mp_item.dwd_item_fe_display_category_factor_df__reg_s0_live d
INNER JOIN ads_item_ids a ON d.item_id = a.item_id
WHERE d.grass_region = upper('${region}')
  AND d.grass_date = DATE('${grass_date}')
  AND (
       (d.fe_display_category_level = 1 AND d.level1_fe_display_category_id IS NOT NULL)
    OR (d.fe_display_category_level = 2 AND d.level2_fe_display_category_id IS NOT NULL)
    OR (d.fe_display_category_level = 3 AND d.level3_fe_display_category_id IS NOT NULL)
  )
GROUP BY d.item_id;


CREATE OR REPLACE TEMPORARY VIEW kpi_category AS
SELECT
  d.item_id
  ,COLLECT_LIST(
    STRUCT(
      d.level1_kpi_category_id,
      d.level1_kpi_category,
      d.level1_kpi_category_fraction_factor
    )
  ) FILTER (
    WHERE d.kpi_category_level = 1 AND d.level1_kpi_category_id IS NOT NULL
  ) AS level1_kpi_category_list

  ,COLLECT_LIST(
    STRUCT(
      d.level2_kpi_category_id,
      d.level2_kpi_category,
      d.level2_kpi_category_fraction_factor
    )
  ) FILTER (
    WHERE d.kpi_category_level = 2 AND d.level2_kpi_category_id IS NOT NULL
  ) AS level2_kpi_category_list

  ,COLLECT_LIST(
    STRUCT(
      d.level3_kpi_category_id,
      d.level3_kpi_category,
      d.level3_kpi_category_fraction_factor
    )
  ) FILTER (
    WHERE d.kpi_category_level = 3 AND d.level3_kpi_category_id IS NOT NULL
  ) AS level3_kpi_category_list
FROM mp_item.dwd_item_kpi_category_factor_df__reg_s0_live d
INNER JOIN ads_item_ids a ON d.item_id = a.item_id
WHERE d.grass_region = upper('${region}')
  AND d.grass_date = DATE('${grass_date}')
  AND (
       (d.kpi_category_level = 1 AND d.level1_kpi_category_id IS NOT NULL)
    OR (d.kpi_category_level = 2 AND d.level2_kpi_category_id IS NOT NULL)
    OR (d.kpi_category_level = 3 AND d.level3_kpi_category_id IS NOT NULL)
  )
GROUP BY d.item_id;

CREATE OR REPLACE TEMPORARY VIEW ads_item_info AS
(
    SELECT
            ads_id
           ,status AS ads_status
           ,create_datetime
           ,placement
           ,CASE
                WHEN placement = 0          THEN 'keyword:search'
                WHEN placement = 1          THEN 'targeting:similar_product'
                WHEN placement = 2          THEN 'targeting:daily_discover'
                WHEN placement = 3          THEN 'keyword:shop'
                WHEN placement = 4          THEN 'keyword:simple_mode'
                WHEN placement = 5          THEN 'targeting:ymal'
                WHEN placement = 7          THEN 'keyword:banner'
                WHEN placement = 8          THEN 'targeting:simple_mode_all'
                WHEN placement = 801        THEN 'targeting:simple_mode_sp'
                WHEN placement = 802        THEN 'targeting:simple_mode_dd'
                WHEN placement = 805        THEN 'targeting:simple_mode_ymal'
                WHEN placement = 10         THEN 'boost:all'
                WHEN placement = 1000       THEN 'boost:search'
                WHEN placement = 1001       THEN 'boost:similar_product'
                WHEN placement = 1002       THEN 'boost:daily_discover'
                WHEN placement = 1005       THEN 'boost:ymal'
                WHEN placement = 1200       THEN 'auto_boost:search'
                WHEN placement = 1202       THEN 'auto_boost:daily_discover'
                WHEN placement = 1205       THEN 'auto_boost:ymal'
                WHEN placement = 20         THEN 'shop_simple'
                ELSE NULL
            END AS ads_type
           ,campaign_id
           ,ads_info.shop_id
           ,user_id     AS seller_id
           ,user_name   AS seller_name
           ,language
           ,ads_info.item_id
        --    ,item_info.item_name
           ,ads_info.grass_region
           ,level1_fe_display_category_list
           ,level1_kpi_category_list
           ,level2_fe_display_category_list
           ,level2_kpi_category_list
           ,level3_fe_display_category_list
           ,level3_kpi_category_list
           ,boost_id
           ,boost_package_id
           ,boost_price
           ,boost_days
           ,boost_est_views
           ,pricing_type
           ,target_roi
           ,target_roi_type
           ,auto_boost_algo_status
           ,create_timestamp
            ,modify_timestamp
            ,modify_datetime
            ,keywords
            ,target_price
            ,target_premium_rate 
            ,target_base_price
            ,shop_customisation_display_title
            ,shop_customisation_image_url
            ,shop_customisation_collection_id
            ,banner_image_uri_pc
            ,banner_image_image_uri_app
            ,banner_keywords
            ,banner_landing_page_url
            ,target_affiliate_user_id
            ,post_id
            ,video_id
            ,first_delivery_timestamp
            ,first_delivery_datetime
            ,potential_product_type
            ,search_brand_package_order_id
            ,is_nominated_for_package_non_ads
            ,is_organic_non_ads
            ,brand_max_type
            ,brand_max_package_request_id
    FROM
    (
        SELECT  ads_id
               ,a.user_id
               ,status
               ,create_datetime
               ,placement
               ,shop_id
               ,user_name
               ,language
               ,item_id
               ,campaign_id
               ,a.grass_region
               ,boost_id
               ,boost_package_id
               ,boost_price
               ,boost_days
               ,boost_est_views
               ,pricing_type
               ,target_roi
               ,target_roi_type
               ,auto_boost_algo_status
               ,create_timestamp
                ,modify_timestamp
                ,modify_datetime
                ,keywords
                ,target_price
                ,target_premium_rate 
                ,target_base_price
                ,shop_customisation_display_title
                ,shop_customisation_image_url
                ,shop_customisation_collection_id
                ,banner_image_uri_pc
                ,banner_image_image_uri_app
                ,banner_keywords
                ,banner_landing_page_url
                ,target_affiliate_user_id
                ,post_id
                ,video_id
                ,first_delivery_timestamp
                ,first_delivery_datetime
                ,potential_product_type
                ,search_brand_package_order_id
                ,is_nominated_for_package_non_ads
                ,is_organic_non_ads
                ,brand_max_type
                ,brand_max_package_request_id
        FROM advertise_tab_df a
        LEFT JOIN
        (
            SELECT user_id ,user_name , null AS language
            FROM  mp_user.dim_user__reg_s0_live
            WHERE grass_region = upper('${region}')
            AND grass_date = date('${grass_date}')
        ) advertiser
        ON a.user_id = advertiser.user_id 
    ) ads_info
    LEFT OUTER JOIN fe_display_category
    ON ads_info.item_id = fe_display_category.item_id
    LEFT OUTER JOIN kpi_category
    ON ads_info.item_id = kpi_category.item_id
);

-- join campaign info
CREATE OR REPLACE TEMPORARY VIEW ads_campaign_info AS
(
    SELECT   ads_item_info.ads_id
            ,ads_status
            ,ads_item_info.create_datetime
            ,ads_item_info.placement
            ,ads_type
            ,ads_item_info.shop_id
            ,seller_id
            ,seller_name
            ,language
            ,item_id
            -- ,item_name
            ,ads_item_info.campaign_id
            ,campaign_status
            ,campaign_status_text
            ,total_quota_local
            ,total_quota_usd
            ,daily_quota_local
            ,daily_quota_usd
            ,campaign_start_datetime
            ,campaign_end_datetime
            ,ads_item_info.grass_region
            ,level1_fe_display_category_list
            ,level1_kpi_category_list
            ,level2_fe_display_category_list
            ,level2_kpi_category_list
            ,level3_fe_display_category_list
            ,level3_kpi_category_list
            ,boost_id
            ,boost_package_id
            ,boost_price
            ,boost_days
            ,boost_est_views
            ,COALESCE(pricing_type, 0) as pricing_type
            ,target_roi
            ,target_roi_type
            ,auto_boost_algo_status
            ,daily_available_quota
            ,split_budget_version
            ,is_budget_split
            ,create_timestamp
            ,modify_timestamp
            ,modify_datetime
            ,keywords
            ,target_price
            ,target_premium_rate 
            ,target_base_price
            ,shop_customisation_display_title
            ,shop_customisation_image_url
            ,shop_customisation_collection_id
            ,banner_image_uri_pc
            ,banner_image_image_uri_app
            ,banner_keywords
            ,banner_landing_page_url
            ,target_affiliate_user_id
            ,post_id
            ,video_id
            ,first_delivery_timestamp
            ,first_delivery_datetime
            ,potential_product_type
            ,search_brand_package_order_id
            ,is_nominated_for_package_non_ads
            ,is_organic_non_ads
            ,brand_max_type
            ,brand_max_package_request_id
    FROM ads_item_info
    LEFT JOIN
    (
        SELECT shop_id
              ,campaign_id
              ,grass_region
              ,campaign_status
              ,campaign_status_text
              ,campaign_start_datetime
              ,campaign_end_datetime
              ,total_quota_local
              ,total_quota_usd
              ,daily_quota_local
              ,daily_quota_usd
        FROM mp_paidads.dim_campaign__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}')
    ) campaign
    ON  ads_item_info.shop_id = campaign.shop_id
    AND ads_item_info.campaign_id = campaign.campaign_id
    AND ads_item_info.grass_region = campaign.grass_region
    LEFT JOIN
    (
        SELECT campaign_id
              ,grass_region
              ,single_quota.placement as placement
              ,cast(single_quota.daily_available_quota as bigint) as daily_available_quota
              ,single_quota.version as split_budget_version
              ,case when (single_quota.version=0) then 0 else 1 end as is_budget_split
        -- need change to prod
        FROM mp_paidads.dim_campaign__reg_s0_live
        lateral view explode(quota_splits) e as single_quota
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}')
        AND single_quota.placement in (1002, 1000, 1005)
    ) campaign_split_quota
    ON  ads_item_info.campaign_id = campaign_split_quota.campaign_id
    AND ads_item_info.grass_region = campaign_split_quota.grass_region
    AND ads_item_info.placement = campaign_split_quota.placement
);

cache table  shop_index OPTIONS ('storageLevel' 'MEMORY_AND_DISK')
SELECT  ads_id
        ,placement
        ,source
        ,kind
        ,exact_bid_keyword
        ,start_time 
        ,timestamp
        ,operation
        ,grass_region
FROM mp_paidads.ods_log_shop_ads_index_hi__reg_s0_live
WHERE grass_region = upper('${region}')
    AND   grass_date >= DATE('${grass_date}')
    AND   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
    AND   DATE(from_utc_timestamp(to_utc_timestamp(cast(timestamp as timestamp),'Asia/Singapore'), '${timezone}')) < DATE_ADD(DATE('${grass_date}'), 1)
    AND   DATE(from_utc_timestamp(to_utc_timestamp(cast(timestamp as timestamp),'Asia/Singapore'), '${timezone}')) >= DATE('${grass_date}')
    AND operation = 'INDEX'
;

create or replace temporary view product_type_mapping as 
select pricing_type
    ,placement
    ,sub_product_type
    ,product_type
    ,main_product_type
from mp_paidads.dim_product_type_mapping__reg_s0_live 
group by 1,2,3,4,5
;

create or replace temporary view dim_video_state as 
select content_id, state
from video.video_mart_dim_content
where grass_date = DATE('${grass_date}')
and grass_region = upper('${region}')
and content_type = 'shopee_video'
group by 1,2
;

CREATE OR REPLACE TEMPORARY VIEW dim_advertise_temp AS
(
    SELECT ads_campaign_info.ads_id
           ,ads_status
           ,create_datetime AS ads_create_datetime
           ,ads_campaign_info.placement
           ,ads_type
           ,ads_campaign_info.shop_id
           ,seller_id
           ,seller_name
           ,language
           ,ads_campaign_info.item_id
           ,item_name
           ,campaign_id
           ,campaign_status
           ,campaign_status_text
           ,total_quota_local
           ,total_quota_usd
           ,daily_quota_local
           ,daily_quota_usd
           ,campaign_start_datetime
           ,campaign_end_datetime
           ,CASE WHEN has_active_record is NULL or to_date(campaign_start_datetime) > DATE('${grass_date}') or to_date(campaign_end_datetime) < DATE('${grass_date}') THEN 0 ELSE 1 END AS is_ads_active
           ,level1_global_be_category
           ,level1_fe_display_category_list
           ,level1_kpi_category_list
           ,level2_global_be_category
           ,level2_fe_display_category_list
           ,level2_kpi_category_list
           ,level3_global_be_category
           ,level3_fe_display_category_list
           ,level3_kpi_category_list
            ,0 as is_segment_ad
            ,null as filter_segments_age_list
            ,null as filter_segments_gender_list
            ,null as filter_segments_location_list
            ,null as premium_segments_behavior_list
            ,null as filter_segments_category_list
           ,boost_id
           ,boost_package_id
           ,boost_price
           ,boost_days
           ,boost_est_views
           ,ads_campaign_info.pricing_type as pricing_type
           ,target_roi
           ,target_roi_type
           ,auto_boost_algo_status
           ,daily_available_quota
           ,split_budget_version
           ,is_budget_split
           ,create_timestamp as ads_create_timestamp
            ,modify_timestamp as ads_modify_timestamp
            ,modify_datetime as ads_modify_datetime
            ,keywords
            ,target_price
            ,target_premium_rate 
            ,target_base_price
            ,shop_customisation_display_title
            ,shop_customisation_image_url
            ,shop_customisation_collection_id
            ,banner_image_uri_pc
            ,banner_image_image_uri_app
            ,banner_keywords
            ,banner_landing_page_url
            ,ta_group_id
            ,ta_premium_rate
            ,tag_ids
            ,target_affiliate_user_id
            ,post_id
            ,video_id
            ,COALESCE(sub_product_type,'others') as sub_product_type
            ,COALESCE(product_type,'others') as product_type
            ,COALESCE(main_product_type,'Others') as main_product_type
            ,dim_video_state.state as video_status
            ,first_delivery_timestamp
            ,first_delivery_datetime
            ,potential_product_type
            ,item_create_datetime
            ,search_brand_package_order_id
            ,is_nominated_for_package_non_ads
            ,is_organic_non_ads
            ,brand_max_type
            ,brand_max_package_request_id
            ,upper('${region}') as grass_region
            ,DATE('${grass_date}') as grass_date
    FROM ads_campaign_info
    LEFT OUTER JOIN
    (
        SELECT  ads_id
                ,grass_region
                ,placement
                ,1 as has_active_record
        FROM mp_paidads.ods_shopee_paidads_index_log 
        WHERE grass_region = upper('${region}')
        AND grass_date in (date'${PREV_2D}', date'${grass_date}')
        AND operation = 'INDEX'
        group by 1,2,3
        UNION ALL 
        select ads_id
            ,grass_region
            ,placement
            ,1 as has_active_record
        from  shop_index
        where operation = 'INDEX'
            and start_time <= timestamp
        GROUP BY 1,2,3
        UNION ALL 
        select
            ads_id
            ,grass_region
            ,placement
            ,1 as has_active_record
        from
        (
            select
                ads_id
                ,grass_region
                ,case when placement = 33 then array(33,3327,3328,3337,3338,3339,3342,3348) else array(placement) end as placement_array
            from shop_index
            where
                source in ('INDEX_TOOL_BATCH_TRIGGER', 'GDS_CREATE', 'GDS_UPDATE_ADS','GDS_UPDATE')
                and kind = 'LiveStreamAds'
                and cardinality(
                    filter (
                        exact_bid_keyword
                        ,x -> x.key = 'session_id'
                        and not x.value = '0'
                    )
                ) > 0
            group by 1, 2, 3
            union all
            select
                ads_id
                ,grass_region
                ,case when placement = 33 then array(33,3327,3328,3337,3338,3339,3342,3348) else array(placement) end as placement_array
            from shop_index
            where
                source = 'LIVE_STREAM_STREAMER_ONLINE'
                and kind = 'LiveStreamAds'
                and start_time <= timestamp
            group by 1, 2, 3
        ) ls_index 
        lateral view explode (placement_array) as placement
        group by 1,2,3
    ) index
    ON  ads_campaign_info.ads_id = index.ads_id
    AND ads_campaign_info.grass_region = index.grass_region
    AND ads_campaign_info.placement = index.placement
    LEFT OUTER JOIN
    (
        SELECT
             STRUCT(
                level1_global_be_category_id AS level1_global_be_category_id
                ,level1_global_be_category AS level1_global_be_category
            ) AS level1_global_be_category
            ,STRUCT(
                level2_global_be_category_id AS level2_global_be_category_id
                ,level2_global_be_category AS level2_global_be_category
            ) AS level2_global_be_category
            ,STRUCT(
                level3_global_be_category_id AS level3_global_be_category_id
                ,level3_global_be_category AS level3_global_be_category
            ) AS level3_global_be_category
            ,item_id
            ,shop_id
            ,create_datetime as item_create_datetime
            ,name as item_name
        FROM mp_item.dim_item__reg_s0_live 
        WHERE tz_type = 'local'
        AND grass_date = DATE('${grass_date}')
        AND grass_region = upper('${region}')
    ) category
    ON ads_campaign_info.item_id = category.item_id
    LEFT OUTER JOIN
    (
        select campaignid, shopid, groupid as ta_group_id, premium_rate as ta_premium_rate, null as tag_ids
            -- flatten(filter(from_json(_decoded_extinfo, 'struct<option_tags:array<
            --         struct<option:int, tag_id_list:array<int>>>>').option_tags.tag_id_list, x -> x IS NOT NULL)) as tag_ids 
        from mp_paidads.shopee_ads_${region}_${db_type}__target_audience_group_tab__reg_continuous_s0_live
    ) target_audience
    ON ads_campaign_info.campaign_id = target_audience.campaignid   
    AND ads_campaign_info.shop_id = target_audience.shopid
    left join product_type_mapping 
    on ads_campaign_info.pricing_type = product_type_mapping.pricing_type
    and ads_campaign_info.placement = product_type_mapping.placement
    left join dim_video_state
    on ads_campaign_info.post_id = dim_video_state.content_id
);



INSERT OVERWRITE TABLE dim_advertise__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT ads_id
           ,first(ads_status)
           ,first(ads_create_datetime)
           ,placement
           ,first(ads_type)
           ,first(shop_id)
           ,first(seller_id)
           ,first(seller_name)
           ,first(language)
           ,first(item_id)
           ,first(item_name)
           ,first(campaign_id)
           ,first(campaign_status)
           ,first(campaign_status_text)
           ,first(total_quota_local)
           ,first(total_quota_usd)
           ,first(daily_quota_local)
           ,first(daily_quota_usd)
           ,first(campaign_start_datetime)
           ,first(campaign_end_datetime)
           ,first(is_ads_active)
           ,first(level1_global_be_category)
           ,first(level1_fe_display_category_list)
           ,first(level1_kpi_category_list)
           ,first(level2_global_be_category)
           ,first(level2_fe_display_category_list)
           ,first(level2_kpi_category_list)
           ,first(level3_global_be_category)
           ,first(level3_fe_display_category_list)
           ,first(level3_kpi_category_list)
           ,first(is_segment_ad)
           ,first(filter_segments_age_list)
           ,first(filter_segments_gender_list)
           ,first(filter_segments_location_list)
           ,first(premium_segments_behavior_list)
           ,first(filter_segments_category_list)
           ,first(boost_id)
           ,first(boost_package_id)
           ,first(boost_price)
           ,first(boost_days)
           ,first(boost_est_views)
           ,first(pricing_type)
           ,first(auto_boost_algo_status)
           ,first(daily_available_quota)
           ,first(split_budget_version)
           ,first(is_budget_split)
           ,first(target_roi)
           ,first(target_roi_type)
           ,first(ads_create_timestamp)
            ,first(ads_modify_timestamp)
            ,first(ads_modify_datetime)
            ,first(keywords)
            ,first(target_price)
            ,first(target_premium_rate)
            ,first(target_base_price)
            ,first(shop_customisation_display_title)
            ,first(shop_customisation_image_url)
            ,first(shop_customisation_collection_id)
            ,first(banner_image_uri_pc)
            ,first(banner_image_image_uri_app)
            ,first(banner_keywords)
            ,first(banner_landing_page_url)
            ,first(ta_group_id)
            ,first(ta_premium_rate)
            ,first(tag_ids)
            ,first(target_affiliate_user_id)
            ,first(sub_product_type)
            ,first(product_type)
            ,first(main_product_type)
            ,first(post_id)
            ,first(video_id)
            ,first(video_status)
            ,first(first_delivery_timestamp)
            ,first(first_delivery_datetime)
            ,first(potential_product_type)
            ,first(item_create_datetime)
            ,first(search_brand_package_order_id)
            ,first(is_nominated_for_package_non_ads)
            ,first(is_organic_non_ads)
            ,first(brand_max_type)
            ,first(brand_max_package_request_id)
            ,first(grass_region)
            ,first(grass_date)
    from dim_advertise_temp
    group by ads_id,placement;

alter table dim_advertise__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');