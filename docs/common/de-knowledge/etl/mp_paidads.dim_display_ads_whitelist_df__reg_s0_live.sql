-- task_code: data_paidadsmart.studio_2813171  asset_id: 2813171
create external table if not exists dim_display_ads_whitelist_df__reg_s0_live
(
    shop_id bigint comment 'shop_id'
    ,shop_name string comment 'shop_name'
    ,status bigint comment 'Whitelist or dewhitelist'
    ,create_timestamp bigint comment 'ctime'
    ,modified_timestamp bigint comment 'mtime'
    ,create_datetime string comment 'Local time in YYYY-MM-DD HH:MM:SS format'
    ,modified_datetime string comment 'Local time in YYYY-MM-DD HH:MM:SS format'
    ,operator string comment 'operator email'
) 
partitioned by
(
    grass_region string
)
stored as parquet
location '${HIVE_PATH}/dim_display_ads_whitelist_df'
;

-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='BR') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=BR';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='ID') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=ID';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='TH') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=TH';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='MY') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=MY';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='PH') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=PH';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='SG') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=SG';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='TW') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=TW';
-- alter table dim_display_ads_whitelist_df__reg_s0_live add if not exists partition (grass_region='VN') location '${HIVE_PATH}/dim_display_ads_whitelist_df/grass_region=VN';

-- insert overwrite table dim_display_ads_whitelist_df__reg_s0_live partition (grass_region)
-- select  a.shopid
--         ,b.shop_name
--         ,status
--         ,ctime
--         ,mtime
--         ,create_datetime
--         ,modified_timestamp
--         ,operator
--         ,grass_region
-- from    (	-- UTC-3: BR 
--     -- SET TIME ZONE 'America/Araguaina';
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'America/Araguaina') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'America/Araguaina') as modified_timestamp
--             ,operator
--             ,'BR' as grass_region
--     from    mp_paidads.shopee_ads_br_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     -- UTC+7: ID, TH, VN 
--     --  SET TIME ZONE 'Asia/Jakarta';
--     union all 
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Jakarta') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Jakarta') as modified_timestamp
--             ,operator
--             ,'ID' as grass_region
--     from    mp_paidads.shopee_ads_id_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     union all 
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Jakarta') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Jakarta') as modified_timestamp
--             ,operator
--             ,'TH' as grass_region
--     from    mp_paidads.shopee_ads_th_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     union all 
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Jakarta') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Jakarta') as modified_timestamp
--             ,operator
--             ,'VN' as grass_region
--     from    mp_paidads.shopee_ads_vn_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     union all 
--     -- UTC+8: SG,MY,PH,TW
--     -- SET TIME ZONE 'Asia/Singapore';
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as modified_timestamp
--             ,operator
--             ,'SG' as grass_region
--     from    mp_paidads.shopee_ads_sg_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     union all 
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as modified_timestamp
--             ,operator
--             ,'MY' as grass_region
--     from    mp_paidads.shopee_ads_my_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     union all 
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as modified_timestamp
--             ,operator
--             ,'PH' as grass_region
--     from    mp_paidads.shopee_ads_ph_db__display_ads_whitelist_tab__reg_continuous_s0_live
--     union all 
--     select  shopid
--             ,'' as shop_name
--             ,status
--             ,ctime
--             ,mtime
--             ,from_utc_timestamp(from_unixtime(ctime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as create_datetime
--             ,from_utc_timestamp(from_unixtime(mtime, 'yyyy-MM-dd HH:mm:ss'), 'Asia/Singapore') as modified_timestamp
--             ,operator
--             ,'TW' as grass_region
--     from    mp_paidads.shopee_ads_tw_db__display_ads_whitelist_tab__reg_continuous_s0_live
-- ) a
-- left join (
--     select  shop_id
--             ,shop_name
--     from    mp_user.dim_shop__reg_s0_live
--     where   tz_type = 'local'
--       and   grass_date = DATE('${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1d')}')
-- ) b
-- on      a.shopid = b.shop_id
-- ;