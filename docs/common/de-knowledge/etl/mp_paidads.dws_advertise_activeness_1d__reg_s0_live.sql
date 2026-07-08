-- task_code: data_paidadsmart.studio_2881835  asset_id: 2881835
INSERT OVERWRITE TABLE dws_advertise_activeness_1d__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
SELECT
    ads_id
     ,shop_id
     ,seller_id AS user_id
     ,MIN(first_mm_kw_ads_active_date) AS first_mm_kw_ads_active_date
     ,MIN(first_sm_kw_ads_active_date) AS first_sm_kw_ads_active_date
     ,upper('${region}') AS grass_region
     ,date('${grass_date}')  AS grass_date
FROM (
    SELECT
    ads_id
        ,shop_id
        ,seller_id
        ,CASE
    WHEN placement = 0 THEN grass_date
    END AS first_mm_kw_ads_active_date
        ,CASE
    WHEN placement = 4 THEN grass_date
    END AS first_sm_kw_ads_active_date
        ,CASE
    WHEN placement = 1000 THEN grass_date
    END AS first_boost_kw_ads_active_date
    FROM mp_paidads.dim_advertise__${region}_s0_live
    WHERE grass_date = date('${grass_date}')
    AND is_ads_active = 1
    )
GROUP BY ads_id, shop_id, seller_id;

alter table dws_advertise_activeness_1d__${region}_s0_live add if not exists partition (grass_date = '${grass_date}');