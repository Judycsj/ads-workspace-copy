-- task_code: data_paidadsmart.studio_2850871  asset_id: 2850871
create or replace temporary view global_be_category as 
SELECT
        level1_global_be_category.level1_global_be_category_id AS level1_global_be_category_id
        ,level1_global_be_category.level1_global_be_category AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31
    UNION ALL
    SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,level2_global_be_category.level2_global_be_category_id AS level2_global_be_category_id
        ,level2_global_be_category.level2_global_be_category AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31
    UNION ALL
    SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,level3_global_be_category.level3_global_be_category_id AS level3_global_be_category_id
        ,level3_global_be_category.level3_global_be_category AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31;

create or replace temporary view fe_display_category as 
SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,level1_fe_display_category.level1_fe_display_category_id AS level1_fe_display_category_id
        ,level1_fe_display_category.level1_fe_display_category AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    LATERAL VIEW OUTER EXPLODE(level1_fe_display_category_list) AS level1_fe_display_category
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31
    UNION ALL
    SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,level2_fe_display_category.level2_fe_display_category_id AS level2_fe_display_category_id
        ,level2_fe_display_category.level2_fe_display_category AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    LATERAL VIEW OUTER EXPLODE(level2_fe_display_category_list) AS level2_fe_display_category
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31
    UNION ALL
    SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,level3_fe_display_category.level3_fe_display_category_id AS level3_fe_display_category_id
        ,level3_fe_display_category.level3_fe_display_category AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    LATERAL VIEW OUTER EXPLODE(level3_fe_display_category_list) AS level3_fe_display_category
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31;

create or replace temporary view kpi_category as 
SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,level1_kpi_category.level1_kpi_category_id AS level1_kpi_category_id
        ,level1_kpi_category.level1_kpi_category AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    LATERAL VIEW OUTER EXPLODE(level1_kpi_category_list) AS level1_kpi_category
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31
    UNION ALL
    SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,level2_kpi_category.level2_kpi_category_id AS level2_kpi_category_id
        ,level2_kpi_category.level2_kpi_category AS level2_kpi_category
        ,NULL AS level3_kpi_category_id
        ,NULL AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    LATERAL VIEW OUTER EXPLODE(level2_kpi_category_list) AS level2_kpi_category
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31
    UNION ALL
    SELECT
        NULL AS level1_global_be_category_id
        ,NULL AS level1_global_be_category
        ,NULL AS level2_global_be_category_id
        ,NULL AS level2_global_be_category
        ,NULL AS level3_global_be_category_id
        ,NULL AS level3_global_be_category
        ,NULL AS level1_fe_display_category_id
        ,NULL AS level1_fe_display_category
        ,NULL AS level2_fe_display_category_id
        ,NULL AS level2_fe_display_category
        ,NULL AS level3_fe_display_category_id
        ,NULL AS level3_fe_display_category
        ,NULL AS level1_kpi_category_id
        ,NULL AS level1_kpi_category
        ,NULL AS level2_kpi_category_id
        ,NULL AS level2_kpi_category
        ,level3_kpi_category.level3_kpi_category_id AS level3_kpi_category_id
        ,level3_kpi_category.level3_kpi_category AS level3_kpi_category
        ,sum(ads_expenditure_amt_local) AS category_ads_expenditure_amt_1d
        ,sum(ads_expenditure_amt_usd) AS category_ads_expenditure_amt_usd_1d
        ,sum(click_cnt) AS category_ads_click_cnt_1d
        ,sum(impression_cnt) AS category_ads_impression_cnt_1d
        ,sum(order_cnt) AS category_ads_order_cnt_1d
        ,sum(broad_order_cnt) AS category_ads_broad_order_cnt_1d
        ,sum(ads_gmv_local) AS category_ads_gmv_amt_1d
        ,sum(ads_gmv_usd) AS category_ads_gmv_amt_usd_1d
        ,sum(broad_order_gmv_amt_local) AS category_ads_broad_gmv_amt_1d
        ,sum(broad_order_gmv_amt_usd) AS category_ads_broad_gmv_amt_usd_1d
        ,tz_type
        ,grass_region
        ,grass_date
    FROM mp_paidads.ads_advertise_mkt_1d__reg_s0_live
    LATERAL VIEW OUTER EXPLODE(level3_kpi_category_list) AS level3_kpi_category
    WHERE grass_region = upper('${region}')
    AND grass_date = DATE('${grass_date}')
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,30,31;

INSERT OVERWRITE TABLE ads_category_performance_1d__reg_s0_live PARTITION (tz_type, grass_region, grass_date)
    SELECT  
        *
    FROM (
        select * from global_be_category
        UNION ALL
        select * from fe_display_category
        UNION ALL
        select * from kpi_category
    );

alter table ads_category_performance_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");