-- task_code: data_paidadsmart.studio_10764701  asset_id: 10764701
create external table if not exists dim_advertiser_escrow_whitelist__reg_s0_live
(
	shop_id bigint  
	,whitelist_date date 
) 
partitioned by
(
    grass_region string comment 'region'
    ,grass_date DATE comment 'date'
)
stored as parquet
location "${HIVE_PATH}/dim_advertiser_escrow_whitelist__reg_s0_live"
;

INSERT OVERWRITE TABLE dim_advertiser_escrow_whitelist__reg_s0_live PARTITION (grass_region, grass_date)
select shop_id
    ,min(whitelist_date) as whitelist_date
    ,upper('${region}') as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from (
    select shop_id
        ,whitelist_date
    from dim_advertiser_escrow_whitelist__reg_s0_live
    where grass_date = DATE('${PREV_2D}') and grass_region = UPPER('${region}')
    
    union all 

    select 
        shop_id 
        ,date(date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss')) as whitelist_date
    from 
    (
        select feature_id
        from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
        where grass_date = DATE('${BIZ_YESTERDAY}')
        and feature_key in ('ads_atu_escrow')
        and feature_status = 1
    ) a
    inner join 
    (
        select tag_id, feature_id, ctime
        from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
        where grass_date = DATE('${BIZ_YESTERDAY}')
        and feature_toggle_tag_mapping_status != 3
    )b
    on a.feature_id = b.feature_id
    inner join 
    (
        select shop_id, tag_id
        from marketplace.shopee_seller_shop_tag_mapping_latam_${region}_db__shop_tag_mapping_tab__reg_continuous_s0_live
        where region = UPPER('${region}')
        and shop_tag_mapping_status = 1
        group by shop_id, tag_id
    )c
    on b.tag_id = c.tag_id
)
group by shop_id
;