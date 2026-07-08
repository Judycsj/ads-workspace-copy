-- task_code: data_paidadsmart.studio_2896572  asset_id: 2896572
INSERT OVERWRITE TABLE dws_advertiser_first_active_td__reg_s0_live partition (tz_type='local', grass_region, grass_date)
SELECT
    shop_id
    ,user_id
    ,MIN(first_mm_kw_ads_active_date) AS first_mm_kw_ads_active_date
    ,MIN(first_sm_kw_ads_active_date) AS first_sm_kw_ads_active_date
    ,upper('${region}') AS grass_region
    ,date('${grass_date}') AS grass_date
FROM
(
    SELECT
        shop_id
        ,user_id
        ,first_mm_kw_ads_active_date
        ,first_sm_kw_ads_active_date
    FROM mp_paidads.dws_advertise_activeness_1d__${region}_s0_live
    WHERE grass_date = '${grass_date}'

    UNION ALL

    SELECT
        shop_id
        ,user_id
        ,first_mm_kw_ads_active_date
        ,first_sm_kw_ads_active_date
    FROM mp_paidads.dws_advertiser_first_active_td__${region}_s0_live
    WHERE grass_date = '${day_before_grass_date}'
)
GROUP BY shop_id, user_id;

alter table dws_advertiser_first_active_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");