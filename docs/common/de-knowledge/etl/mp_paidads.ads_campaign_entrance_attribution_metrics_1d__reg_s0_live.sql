-- task_code: data_paidadsmart.studio_9229393  asset_id: 9229393
create external table if not exists ads_campaign_entrance_attribution_metrics_1d__reg_s0_live
(
    campaign_id bigint comment 'campaign_id'
    ,shop_id bigint comment 'shop_id'
    ,user_id bigint comment 'user_id'
    ,main_product_type string comment 'ads product type'
    ,campaign_create_datetime string comment 'campaign创建时间'
    ,campaign_create_timestamp bigint comment 'campaign创建时间戳'
    ,api_creation_method int comment 'campaign创建api entry point'
    ,platform string comment '创建平台 如web,shopee app'
    ,click_event_id string comment '关联到的入口点击埋点的TMS click_event_id'
    ,click_feature_detail string comment'关联到的入口点击埋点的page_type-page_section-target_type'
    ,click_event_timestamp bigint comment'关联到的入口点击事件的时间戳'
    ,click_event_datetime string comment'关联到的入口点击事件的时间'
    ,entrance_feature string comment '关联到的入口的名称'
    ,entrance_feature_group string comment '关联到的入口的分组'
    ,net_expenditure_amt_usd_1d double comment 'net ads revenue'
    ,active_ads_item_cnt_excl_1p_sip bigint comment '该campaign的非1p和sip商家的active item cnt'
    ,active_ads_item_cnt bigint comment '该campaign的active item cnt'
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/ads_campaign_entrance_attribution_metrics_1d__reg_s0_live'
;

create or replace temporary view  new_campaign as 
select 
    campaign_id
    ,user_id
    ,campaign_create_datetime
    ,campaign_create_timestamp
    ,api_creation_method
    ,main_product_type
    ,platform
    ,click_event_id
    ,click_feature_detail
    ,click_event_timestamp
    ,click_event_datetime
    ,entrance_feature
    ,entrance_feature_group
from dim_campaign_entrance_attribution__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

create or replace temporary view  campaign_rev as 
select
    campaign_id
    ,shop_id
    ,item_id
    ,sum(net_ads_revenue_usd_1d) as net_expenditure_amt_usd_1d
from mp_paidads.ads_advertise_mkt_1d__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and date(ads_create_datetime) = DATE('${grass_date}')
and (
        is_ads_active = 1
        or has_performance = 1
    )
and placement in (0, 2, 3, 5, 40, 50, 1200, 1202, 1205, 2003)
and tz_type = 'local'
group by 1,2,3
;

create or replace temporary view  item_supply as
select
    item_id 
    ,case when is_active_ads_item = 1 and seller_type_1p not in ('Lovito', 'SCS')
        and (platform_placed_order_cnt_30d > 0)
        and (ads_expenditure_amt_usd_1d > 0 or ads_impression_cnt_1d > 0)
        and is_sip_shop = 0
        and shop_id not in (1173241077 ,1206023866 ,1195230934 ,1200824394 ,50662979,851157471)  
        then 1 else 0 end as is_active_excl_1p_sip     
from mp_paidads.ads_item_supply_1d__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
;

insert overwrite table ads_campaign_entrance_attribution_metrics_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select 
    a.campaign_id 
    ,shop_id 
    ,user_id
    ,main_product_type
    ,campaign_create_datetime
    ,campaign_create_timestamp
    ,api_creation_method
    ,platform
    ,click_event_id
    ,click_feature_detail
    ,click_event_timestamp
    ,click_event_datetime
    ,entrance_feature
    ,entrance_feature_group
    ,sum(net_expenditure_amt_usd_1d) as net_expenditure_amt_usd_1d
    ,count(distinct case when b.is_active_excl_1p_sip = 1 then b.item_id else null end) as active_ads_item_cnt_excl_1p_sip
    ,count(distinct b.item_id) as active_item_cnt
    ,upper('${region}')
    ,DATE('${grass_date}')
from campaign_rev a 
left join item_supply b 
on a.item_id = b.item_id
left join new_campaign c 
on a.campaign_id = c.campaign_id
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14
;