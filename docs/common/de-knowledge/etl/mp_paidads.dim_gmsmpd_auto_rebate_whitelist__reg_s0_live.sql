-- task_code: data_paidadsmart.studio_10113178  asset_id: 10113178
-- whitelist
create external table if not exists dim_gmsmpd_auto_rebate_whitelist__reg_s0_live 
(
	shop_id BIGINT comment 'shop_id'
	,whitelist_date date comment '开白日期'
    ,type int comment '1:gms whitelist, 2:mpd whitelist, 3:sellers gms ads contain a campaign_tag, 4:auto escrow,5:weekly_rebate_rules'
    ,feature_mode tinyint comment 'ModeOpenToAll = 1,ModeWhiteList = 2,ModeBlackList = 3,ModeOpenToNone = 4,GrayScaleByShopId = 5'
) 
partitioned by
(
    grass_region string comment 'region'
    ,grass_date DATE comment 'date'
)
stored as parquet
location "${HIVE_PATH}/dim_gmsmpd_auto_rebate_whitelist__reg_s0_live"
;

create or replace temporary view campaign_tag as 
select shop_id,grass_date
from mp_paidads.dim_campaign__reg_s0_live
where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and tz_type = 'local' and campaign_tag = 1
group by 1,2
;

INSERT OVERWRITE TABLE dim_gmsmpd_auto_rebate_whitelist__reg_s0_live PARTITION (grass_region='${upper_region}', grass_date='${grass_date}')
select a.shop_id
    ,least(a.whitelist_date,b.whitelist_date) as whitelist_date
    ,2 as type
    ,1 as feature_mode --open to all
from (
    select shop_id,DATE('${grass_date}') as whitelist_date
    from mp_paidads.dim_advertiser__reg_s0_live
    where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null 
)a  left join (
    select shop_id
        ,whitelist_date
    from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
    where grass_date = DATE('${PREV_2D}') and grass_region = UPPER('${region}') and type = 2
)b on a.shop_id = b.shop_id
union all 

--gms whitelist
select t1.shop_id
    ,coalesce(t2.whitelist_date,t1.whitelist_date) as whitelist_date
    ,1 as type
    ,feature_mode
from (
    select toggle_list.shop_id,toggle_list.whitelist_date,toggle_status.feature_mode
    from (
        select feature_id,feature_mode
        from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
        where feature_key in ('product_ads_gms_auto_rebate')
        and feature_status = 1
    ) toggle_status inner join(
        select -- 白名单,ModeOpenToNone,GrayScaleByShopId
            c.shop_id
            ,date(date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss')) as whitelist_date
            ,feature_mode
        from 
        (
            select feature_id,feature_mode
            from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
            where feature_key in ('product_ads_gms_auto_rebate')
            and feature_status = 1 and feature_mode in (2,4,5)
        ) a
        inner join 
        (
            select tag_id, feature_id, ctime
            from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
            where feature_toggle_tag_mapping_status != 3
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

        union all 

        --open to all
        select shop_id,DATE('${grass_date}') as whitelist_date,1 as feature_mode
        from mp_paidads.dim_advertiser__reg_s0_live
        where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null and is_auto_escrow_enabled = 1

        union all 

        -- blacklist
        select all_shop.shop_id,DATE('${grass_date}') as whitelist_date,3 as feature_mode
        from (
            select shop_id
            from mp_paidads.dim_advertiser__reg_s0_live
            where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null and is_auto_escrow_enabled = 1
        ) all_shop left join (
            select c.shop_id
            from 
            (
                select feature_id
                from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
                where feature_key in ('product_ads_gms_auto_rebate')
                and feature_status = 1 and feature_mode = 3
            ) a
            inner join 
            (
                select tag_id, feature_id, ctime
                from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
                where feature_toggle_tag_mapping_status != 3
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
        ) blacklist on all_shop.shop_id = blacklist.shop_id
        where blacklist.shop_id is null
    )toggle_list on toggle_status.feature_mode = toggle_list.feature_mode left join (
        select shop_id
        from mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live
        where grass_region = upper('${region}') and grass_date = DATE('${grass_date}')
    )roi2_blacklist on toggle_list.shop_id = roi2_blacklist.shop_id
    where roi2_blacklist.shop_id is null
)t1 inner join (
    select shop_id
        from mp_paidads.dim_advertiser__reg_s0_live
        where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null and is_auto_escrow_enabled = 1
)escrow on t1.shop_id = escrow.shop_id left join (
    select shop_id
        ,whitelist_date
    from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
    where grass_date = DATE('${PREV_2D}') and grass_region = UPPER('${region}') and type = 1
)t2 on t1.shop_id = t2.shop_id
union all

--campaign tag whitelist
select a.shop_id
        ,coalesce(b.whitelist_date,a.whitelist_date) as whitelist_date
        ,3 as type
        ,null as feature_mode
from (
    select shop_id
        ,grass_date as whitelist_date
    from campaign_tag
)a left join (
    select shop_id
        ,whitelist_date
    from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
    where grass_date = DATE('${PREV_2D}') and grass_region = UPPER('${region}') and type = 3
)b on a.shop_id = b.shop_id
union all

--escrow whitelist
select t1.shop_id
    ,coalesce(t2.whitelist_date,t1.whitelist_date) as whitelist_date
    ,4 as type
    ,feature_mode
from (
    select toggle_list.shop_id,toggle_list.whitelist_date,toggle_status.feature_mode
    from (
        select feature_id,feature_mode
        from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
        where feature_key in ('ads_atu_escrow')
        and feature_status = 1
    ) toggle_status inner join(
        select -- 白名单,ModeOpenToNone,GrayScaleByShopId
            c.shop_id
            ,date(date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss')) as whitelist_date
            ,feature_mode
        from 
        (
            select feature_id,feature_mode
            from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
            where feature_key in ('ads_atu_escrow')
            and feature_status = 1 and feature_mode in (2,4,5)
        ) a
        inner join 
        (
            select tag_id, feature_id, ctime
            from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
            where feature_toggle_tag_mapping_status != 3
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

        union all 

        --open to all
        select shop_id,DATE('${grass_date}') as whitelist_date,1 as feature_mode
        from mp_paidads.dim_advertiser__reg_s0_live
        where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null

        union all 

        -- blacklist
        select all_shop.shop_id,DATE('${grass_date}') as whitelist_date,3 as feature_mode
        from (
            select shop_id
            from mp_paidads.dim_advertiser__reg_s0_live
            where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null
        ) all_shop left join (
            select c.shop_id
            from 
            (
                select feature_id
                from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
                where feature_key in ('ads_atu_escrow')
                and feature_status = 1 and feature_mode = 3
            ) a
            inner join 
            (
                select tag_id, feature_id, ctime
                from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
                where feature_toggle_tag_mapping_status != 3
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
        ) blacklist on all_shop.shop_id = blacklist.shop_id
        where blacklist.shop_id is null
    )toggle_list on toggle_status.feature_mode = toggle_list.feature_mode
)t1 left join (
    select shop_id
        ,whitelist_date
    from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
    where grass_date = DATE('${PREV_2D}') and grass_region = UPPER('${region}') and type = 4
)t2 on t1.shop_id = t2.shop_id
union all

-- weekly_rebate_rules whitelist
select t1.shop_id
    ,coalesce(t2.whitelist_date,t1.whitelist_date) as whitelist_date
    ,5 as type
    ,feature_mode
from (
    select toggle_list.shop_id,toggle_list.whitelist_date,toggle_status.feature_mode
    from (
        select feature_id,feature_mode
        from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
        where feature_key in ('weekly_rebate_rules')
        and feature_status = 1
    ) toggle_status inner join(
        select -- 白名单,ModeOpenToNone,GrayScaleByShopId
            c.shop_id
            ,date(date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss')) as whitelist_date
            ,feature_mode
        from 
        (
            select feature_id,feature_mode
            from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
            where feature_key in ('weekly_rebate_rules')
            and feature_status = 1 and feature_mode in (2,4,5)
        ) a
        inner join 
        (
            select tag_id, feature_id, ctime
            from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
            where feature_toggle_tag_mapping_status != 3
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

        union all 

        --open to all
        select shop_id,DATE('${grass_date}') as whitelist_date,1 as feature_mode
        from mp_paidads.dim_advertiser__reg_s0_live
        where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null

        union all 

        -- blacklist
        select all_shop.shop_id,DATE('${grass_date}') as whitelist_date,3 as feature_mode
        from (
            select shop_id
            from mp_paidads.dim_advertiser__reg_s0_live
            where grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and shop_id is not null
        ) all_shop left join (
            select c.shop_id
            from 
            (
                select feature_id
                from marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df 
                where feature_key in ('weekly_rebate_rules')
                and feature_status = 1 and feature_mode = 3
            ) a
            inner join 
            (
                select tag_id, feature_id, ctime
                from marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df
                where feature_toggle_tag_mapping_status != 3
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
        ) blacklist on all_shop.shop_id = blacklist.shop_id
        where blacklist.shop_id is null
    )toggle_list on toggle_status.feature_mode = toggle_list.feature_mode
)t1 left join (
    select shop_id
        ,whitelist_date
    from mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
    where grass_date = DATE('${PREV_2D}') and grass_region = UPPER('${region}') and type = 5
)t2 on t1.shop_id = t2.shop_id
;