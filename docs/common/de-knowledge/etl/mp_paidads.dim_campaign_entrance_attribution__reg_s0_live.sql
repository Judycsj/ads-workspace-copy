-- task_code: data_paidadsmart.studio_9208286  asset_id: 9208286
-- drop table dim_campaign_entrance_attribution__reg_s0_live;
create external table if not exists dim_campaign_entrance_attribution__reg_s0_live
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
) comment 'only include campaign create on grass_date'
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
) 
stored as PARQUET
location '${HIVE_PATH}/dim_campaign_entrance_attribution__reg_s0_live'
;

set time zone '${timezone}';


create or replace temporary view mapping as 
select  
    api_enum  as api_creation_method
    ,entrance_group as entrance_feature_group
    ,entrance_feature
    ,entrance_tracking_points as tracking_feature
    ,entrance_tracking_points_restriction as restriction
    ,platform
from mp_paidads.dim_campaign_entrance_mapping__reg_s0_live
group by 1,2,3,4,5,6
;

create or replace temporary view  product_campaign  as 
select 
    campaign_id
    ,main_product_type
from mp_paidads.dim_advertise__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
and main_product_type = 'Product Ads'
group by 1,2
;

--product ads
create or replace temporary view  new_campaign  as 
select 
    a.campaign_id
    ,main_product_type
    ,b.shop_id 
    ,user_id
    ,campaign_create_datetime
    ,campaign_create_timestamp
    ,api_creation_method
    ,be_creation_platform
    ,is_cb_shop
from 
product_campaign a 
join
(select 
    campaign_id
    ,shop_id 
    ,user_id
    ,campaign_create_datetime
    ,campaign_create_timestamp
    ,creation_entry_point as api_creation_method
    ,creation_platform as be_creation_platform
from mp_paidads.dim_campaign__reg_s0_live
where grass_region = upper('${region}')
and grass_date = DATE('${grass_date}')
and tz_type = 'local'
and date(campaign_create_datetime) = DATE('${grass_date}')
)b
on a.campaign_id = b.campaign_id
left join (
    select shop_id,is_cb_shop
    FROM  mp_user.dim_shop__reg_s0_live
    WHERE grass_region = upper('${region}')
        AND grass_date = '${grass_date}'
        AND tz_type = 'local'
    group by 1,2
)c on b.shop_id = c.shop_id
;

create or replace temporary view  all_tracking as 
select 'Web' as platform
    ,shop_id
    ,user_id
    ,event_id as click_event_id
    ,event_timestamp as click_event_timestamp
    ,from_unixtime(event_timestamp / 1000) as click_event_datetime
    ,CONCAT_WS('-',page_type,  page_section[0], target_type) as click_feature_detail
    ,cast(get_json_object(data, '$.boost_status') as int) as boost_status
    ,cast(get_json_object(data, '$.boost_type') as int) as boost_type
    ,get_json_object(data, '$.card_type') as card_type
    ,get_json_object(data, '$.button_action') as button_action
    ,get_json_object(data, '$.banner_loc') as banner_loc
    ,get_json_object(data, '$.banner_type') as banner_type
    -- ,get_json_object(data,'$.is_single_item') as is_single_item
    ,get_json_object(data,'$.card_type_id') as card_type_id
    ,get_json_object(data,'$.click_type') as click_type
    ,get_json_object(data,'$.ads_create_ads_list.ads_potential_product_type') as ads_potential_product_type
    ,get_json_object(data,'$.ads_diagnosis_card_list.click_type') as ads_diagnosis_card_list_click_type
    ,get_json_object(data,'$.operation_content') as operation_content
    ,get_json_object(data,'$.ads_create_ads_list_compeleted.campaign_id') as ads_create_ads_list_compeleted_campaign_id
    ,get_json_object(data,'$.ads_diagnosis_card_list_compeleted.campaign_id') as ads_diagnosis_card_list_compeleted_campaign_id
    ,get_json_object(data,'$.page_type') as page_type
    ,get_json_object(data,'$.click_button') as click_button
    ,get_json_object(data,'$.source') as source
    ,get_json_object(data,'$.tool') as tool
    ,get_json_object(data, '$.ad_card_button') as ad_card_button
    ,get_json_object(data,'$.card_info.card_type') as card_info_card_type
    ,get_json_object(data, '$.btn_type') as btn_type
from traffic.sellercenter_dwd_click_di__reg_live
where grass_region in (upper('${region}'), 'OTHER')
and grass_date <= DATE('${grass_date}')
and  grass_date >=  date_sub(DATE('${grass_date}'), 1)
and tz_type = 'local'
-- and CONCAT_WS('-',page_type,  page_section[0], target_type) in (select tracking_feature from mapping)
-- group by 1,2,3,4,5,6,7,8,9,10,11,12
union all 
select 'Shopee APP' as platform
    ,shop_id
    ,userid as user_id
    ,event_id as click_event_id
    ,event_timestamp as click_event_timestamp
    ,from_unixtime(event_timestamp / 1000) as click_event_datetime
    ,CONCAT_WS('-',page_type,  page_section[0], target_type) as click_feature_detail
    ,cast(get_json_object(data, '$.boost_status') as int) as boost_status
    ,cast(get_json_object(data, '$.boost_type') as int) as boost_type
    ,get_json_object(data, '$.card_type') as card_type
    ,get_json_object(data, '$.button_action') as button_action
    ,get_json_object(data, '$.banner_loc') as banner_loc
    ,get_json_object(data, '$.banner_type') as banner_type
    -- ,get_json_object(data,'$.is_single_item') as is_single_item
    ,get_json_object(data,'$.card_type_id') as card_type_id
    ,get_json_object(data,'$.click_type') as click_type
    ,get_json_object(data,'$.ads_create_ads_list.ads_potential_product_type') as ads_potential_product_type
    ,get_json_object(data,'$.ads_diagnosis_card_list.click_type') as ads_diagnosis_card_list_click_type
    ,get_json_object(data,'$.operation_content') as operation_content
    ,get_json_object(data,'$.ads_create_ads_list_compeleted.campaign_id') as ads_create_ads_list_compeleted_campaign_id
    ,get_json_object(data,'$.ads_diagnosis_card_list_compeleted.campaign_id') as ads_diagnosis_card_list_compeleted_campaign_id
    ,get_json_object(data,'$.page_type') as page_type
    ,get_json_object(data,'$.click_button') as click_button
    ,get_json_object(data,'$.source') as source
    ,get_json_object(data,'$.tool') as tool
    ,get_json_object(data, '$.ad_card_button') as ad_card_button
    ,get_json_object(data,'$.card_info.card_type') as card_info_card_type
    ,get_json_object(data, '$.btn_type') as btn_type
from traffic.shopee_traffic_dwd_click_hi__reg_s1_live
where grass_region = upper('${region}')
and local_date <= DATE('${grass_date}')
and  local_date >=  date_sub(DATE('${grass_date}'), 1)
-- and CONCAT_WS('-',page_type,  page_section[0], target_type) in (select tracking_feature from mapping)
-- group by 1,2,3,4,5,6,7,8,9,10,11,12
union all 
select 'Seller APP' as platform
    ,shop_id
    ,user_id
    ,event_id as click_event_id
    ,event_timestamp as click_event_timestamp
    ,from_unixtime(event_timestamp / 1000) as click_event_datetime
    ,CONCAT_WS('-',page_type,  page_section[0], target_type) as click_feature_detail
    ,cast(get_json_object(data, '$.boost_status') as int) as boost_status
    ,cast(get_json_object(data, '$.boost_type') as int) as boost_type
    ,get_json_object(data, '$.card_type') as card_type
    ,get_json_object(data, '$.button_action') as button_action
    ,get_json_object(data, '$.banner_loc') as banner_loc
    ,get_json_object(data, '$.banner_type') as banner_type
    -- ,get_json_object(data,'$.is_single_item') as is_single_item
    ,get_json_object(data,'$.card_type_id') as card_type_id
    ,get_json_object(data,'$.click_type') as click_type
    ,get_json_object(data,'$.ads_create_ads_list.ads_potential_product_type') as ads_potential_product_type
    ,get_json_object(data,'$.ads_diagnosis_card_list.click_type') as ads_diagnosis_card_list_click_type
    ,get_json_object(data,'$.operation_content') as operation_content
    ,get_json_object(data,'$.ads_create_ads_list_compeleted.campaign_id') as ads_create_ads_list_compeleted_campaign_id
    ,get_json_object(data,'$.ads_diagnosis_card_list_compeleted.campaign_id') as ads_diagnosis_card_list_compeleted_campaign_id
    ,get_json_object(data,'$.page_type') as page_type
    ,get_json_object(data,'$.click_button') as click_button
    ,get_json_object(data,'$.source') as source
    ,get_json_object(data,'$.tool') as tool
    ,get_json_object(data, '$.ad_card_button') as ad_card_button
    ,get_json_object(data,'$.card_info.card_type') as card_info_card_type
    ,get_json_object(data, '$.btn_type') as btn_type
from traffic.seller_dwd_all_di__reg_live
where grass_region in (upper('${region}'), 'OTHER')
    and grass_date <= DATE('${grass_date}') and grass_date >=  date_sub(DATE('${grass_date}'), 1)
    and tz_type = 'local'
    and operation='click' and app_id = 286
;

create or replace temporary view  creation_tracking as 
select 
    shop_id
    ,user_id
    ,click_event_id
    ,click_event_timestamp
    ,click_event_datetime
    ,click_feature_detail
    ,api_creation_method
    ,entrance_feature_group
    ,entrance_feature
    ,tracking_feature
    ,restriction
    ,a.platform
from all_tracking a
join
(select * from mapping where tracking_feature not in ('-','')) b 
on 
a.click_feature_detail = b.tracking_feature  and a.platform=b.platform and
(b.restriction in ('-','')  or (b.restriction = 'boost_type=2' and a.boost_type = 2)
or (b.restriction like 'boost_type=1' and a.boost_type = 1) 
or (b.restriction like 'boost_status=2' and a.boost_status = 2)
or (b.restriction like 'boost_status=1' and a.boost_status = 1)
or (b.restriction like 'button_action=Create' and a.button_action = 'Create')
or (b.restriction like 'card_type=potential_item' and a.card_type = 'potential_item')
or (b.restriction like 'banner_loc=under 1st level tab && banner_type=Ads_Complete_Ads_Task_to_win_free_credit_banner' and a.banner_loc = 'under 1st level tab' and a.banner_type = 'Ads_Complete_Ads_Task_to_win_free_credit_banner')
or (b.restriction like 'banner_loc=under 1st level tab && banner_type=Ads_Attract_New_Advertiser_banner' and a.banner_loc = 'under 1st level tab' and a.banner_type = 'Ads_Attract_New_Advertiser_banner')
or (b.restriction like 'banner_loc=under 1st level tab && banner_type=Ads_Manual_Mode_Migration_Tool_banner' and a.banner_loc = 'under 1st level tab' and a.banner_type = 'Ads_Manual_Mode_Migration_Tool_banner') 
or (b.restriction like 'click_type=check_ads_details' and a.click_type = 'check_ads_details')
or (b.restriction like 'ads_potential_product_type is not null' and a.ads_potential_product_type is not null)
or (b.restriction like 'ads_diagnosis_card_list.click_type=adopt' and a.ads_diagnosis_card_list_click_type = 'adopt')
or (b.restriction like 'operation_content in (CREATED_GMV_MAX_ADS,OPTIMISE_ADS)' and a.operation_content in ('CREATED_GMV_MAX_ADS','OPTIMISE_ADS'))
or (b.restriction like 'ads_create_ads_list_compeleted is not null && campaign_id is not null' and a.ads_create_ads_list_compeleted_campaign_id is not null)
or (b.restriction like 'ads_diagnosis_card_list_compeleted is not null && campaign_id is not null' and a.ads_diagnosis_card_list_compeleted_campaign_id is not null)
or (b.restriction like 'page_type=no_active_ads_item && click_button=boost_now && source=boost_button' and a.page_type='no_active_ads_item' and a.click_button= 'boost_now' and a.source='boost_button')
or (b.restriction like 'click_button=check_ads_detail && source=boost_button' and a.click_button = 'check_ads_detail' and a.source='boost_button')
or (b.restriction like 'page_type=no_active_ads_item && click_button=boost_now && source=diagnosis_page' and a.page_type ='no_active_ads_item' and a.click_button = 'boost_now' and a.source='diagnosis_page')
or (b.restriction like 'page_type=no_active_ads_item && click_button=boost_now && source=more_page' and a.page_type ='no_active_ads_item' and a.click_button = 'boost_now' and a.source='more_page')
or (b.restriction like 'page_type=no_active_ads_item && click_button=boost_now && source=detail_page' and a.page_type ='no_active_ads_item' and a.click_button = 'boost_now' and a.source='detail_page')
or (b.restriction like 'click_button=check_ads_detail && source=diagnosis_page' and a.click_button = 'check_ads_detail' and a.source='diagnosis_page')
or (b.restriction like 'click_button=check_ads_detail && source=more_page' and a.click_button = 'check_ads_detail' and a.source='more_page')
or (b.restriction like 'click_button=check_ads_detail && source=detail_page' and a.click_button = 'check_ads_detail' and a.source='detail_page')
or (b.restriction like 'banner_type=ads_gms_create_restart_banner && source=3' and a.banner_type = 'ads_gms_create_restart_banner' and a.source = '3')
or (b.restriction like 'banner_type=ads_qss_sign_up_banner && source=3' and a.banner_type = 'ads_qss_sign_up_banner' and a.source = '3')
or (b.restriction like 'banner_type=ads_gms_create_restart_banner && source=7' and a.banner_type = 'ads_gms_create_restart_banner' and a.source = '7')
or (b.restriction like 'banner_type=ads_qss_sign_up_banner && source=7' and a.banner_type = 'ads_qss_sign_up_banner' and a.source = '7')
or (b.restriction like 'tool=ads_create_gmv_max' and a.tool = 'ads_create_gmv_max')
or (b.restriction like 'tool=ads_top_up' and a.tool = 'ads_top_up')
or (b.restriction like 'banner_type=ads_gms_create_restart_banner && source=3 && click_button=view_details' and a.banner_type = 'ads_gms_create_restart_banner' and a.source = '3'and a.click_button ='view_details')
or (b.restriction like 'banner_type=ads_qss_sign_up_banner && source=3 && click_button=view_ads_details' and a.banner_type = 'ads_qss_sign_up_banner' and a.source = '3' and a.click_button ='view_ads_details')
or (b.restriction like 'banner_type=ads_gms_create_restart_banner && source=7 && click_button=view_details' and a.banner_type = 'ads_gms_create_restart_banner' and a.source = '7' and a.click_button ='view_details')
or (b.restriction like 'banner_type=ads_qss_sign_up_banner && source=7 && click_button=view_ads_details' and a.banner_type = 'ads_qss_sign_up_banner' and a.source = '7' and a.click_button ='view_ads_details')
or (b.restriction like 'card_type_id=ads_gmv_max_create_potential_products && ad_card_button=1' and a.card_type_id = 'ads_gmv_max_create_potential_products' and ad_card_button = '1') 
or (b.restriction like 'card_type_id in (ads_qss_1_create,ads_qss_2_create) && ad_card_button=1' and a.card_type_id in ('ads_qss_1_create','ads_qss_2_create') and ad_card_button = '1') 
or (b.restriction like 'card_type_id in (ads_qss_1_create,ads_qss_2_create)' and a.card_type_id in ('ads_qss_1_create','ads_qss_2_create'))
or (b.restriction like 'card_type_id=ads_gmv_max_create_potential_products' and a.card_type_id = 'ads_gmv_max_create_potential_products')
or (b.restriction like 'card_info.card_type=create_product_gms_campaign_action' and a.card_info_card_type = 'create_product_gms_campaign_action') 
or (b.restriction like 'card_info.card_type=create_product_gms_campaign_announcement' and a.card_info_card_type = 'create_product_gms_campaign_announcement') 
or (b.restriction like 'btn_type=1' and a.btn_type = '1')
)
;

create or replace temporary view  view_tracking as 
select shop_id
    ,user_id
    ,page_type as last_view_page_type
    ,event_timestamp as last_view_event_timestamp
    ,from_unixtime(event_timestamp / 1000) as last_view_event_datetime
from traffic.sellercenter_dwd_view_di__reg_live a 
where a.grass_region in (upper('${region}'), 'OTHER')
    and a.grass_date <= DATE('${grass_date}') and a.grass_date >=  date_sub(DATE('${grass_date}'), 1)
    and a.tz_type = 'local'  
group by 1,2,3,4,5
;

create or replace temporary view  seller_center_entrance_salt as 
select 
    *
from
(select 
    campaign_id
    ,a.shop_id as shop_id
    ,a.user_id as user_id
    ,main_product_type
    ,campaign_create_datetime
    ,campaign_create_timestamp
    ,a.api_creation_method as api_creation_method
    ,click_event_id
    ,click_event_timestamp
    ,click_event_datetime
    ,click_feature_detail
    ,entrance_feature_group
    ,entrance_feature
    ,platform
    ,be_creation_platform
    ,is_cb_shop
    ,row_number() over(partition by campaign_id,a.api_creation_method,cast(rand() * 100 as int) order by click_event_timestamp desc) as rank
from new_campaign a 
left join creation_tracking b 
on (a.shop_id = b.shop_id
or a.user_id = b.user_id)
and a.api_creation_method = b.api_creation_method
and b.click_event_timestamp / 1000 between a.campaign_create_timestamp - 86400 and a.campaign_create_timestamp+60
)t 
where rank = 1
;

create or replace temporary view  view_oa_salt as 
select 
    *
from
(select 
    campaign_id
    ,a.shop_id as shop_id
    ,a.user_id as user_id
    ,api_creation_method
    ,last_view_page_type
    ,last_view_event_timestamp
    ,last_view_event_datetime
    ,row_number() over(partition by campaign_id,a.api_creation_method,cast(rand() * 100 as int) order by last_view_event_timestamp desc) as view_rank
from new_campaign a 
left join view_tracking c
on (a.shop_id = c.shop_id
or a.user_id = c.user_id)
and c.last_view_event_timestamp / 1000 between a.campaign_create_timestamp - 86400 and a.campaign_create_timestamp+60
where a.be_creation_platform=1 -- 'PLATFORM_PC'
)t 
where view_rank =1
;


create or replace temporary view  seller_center_entrance as 
select 
     click_oa.campaign_id
    ,click_oa.shop_id
    ,click_oa.user_id
    ,click_oa.main_product_type
    ,click_oa.campaign_create_datetime
    ,click_oa.campaign_create_timestamp
    ,click_oa.api_creation_method
    ,click_event_id
    ,click_event_timestamp
    ,click_event_datetime
    ,click_feature_detail
    ,entrance_feature_group
    ,entrance_feature
    ,click_oa.platform
    ,click_oa.be_creation_platform
    ,click_oa.is_cb_shop
    ,last_view_page_type
    ,last_view_event_timestamp
    ,last_view_event_datetime
from (
    select 
        *
    from
    (select 
        campaign_id
        ,shop_id
        ,user_id
        ,main_product_type
        ,campaign_create_datetime
        ,campaign_create_timestamp
        ,api_creation_method
        ,click_event_id
        ,click_event_timestamp
        ,click_event_datetime
        ,click_feature_detail
        ,entrance_feature_group
        ,entrance_feature
        ,platform
        ,be_creation_platform
        ,is_cb_shop
        ,row_number() over(partition by campaign_id,api_creation_method order by click_event_timestamp desc) as global_click_rank
    from seller_center_entrance_salt
    )
    where global_click_rank = 1
) click_oa left join (
    select 
        *
    from
    (select 
        campaign_id
        ,shop_id
        ,user_id
        ,api_creation_method
        ,last_view_page_type
        ,last_view_event_timestamp
        ,last_view_event_datetime
        ,row_number() over(partition by campaign_id,api_creation_method order by last_view_event_timestamp desc) as global_view_rank
    from view_oa_salt
    )
    where global_view_rank = 1
)view_oa on click_oa.campaign_id = view_oa.campaign_id
;

create or replace temporary view result as 
select 
    campaign_id
    ,shop_id 
    ,user_id
    ,main_product_type
    ,campaign_create_datetime
    ,campaign_create_timestamp
    ,a.api_creation_method as api_creation_method
    ,coalesce(a.platform,b.platform) as platform
    ,click_event_id
    ,click_feature_detail
    ,click_event_timestamp
    ,click_event_datetime
    ,coalesce(a.entrance_feature,b.entrance_feature) as entrance_feature
    ,coalesce(a.entrance_feature_group,b.entrance_feature_group) as entrance_feature_group
    ,be_creation_platform
    ,is_cb_shop
    ,last_view_page_type
    ,last_view_event_timestamp
    ,last_view_event_datetime
from seller_center_entrance a
left join (select api_creation_method
    ,entrance_feature_group
    ,entrance_feature
    ,platform from mapping where tracking_feature in ('-','')) b 
on a.api_creation_method = b.api_creation_method
;


insert overwrite table dim_campaign_entrance_attribution__reg_s0_live partition(tz_type = 'local',grass_region,grass_date)
select 
    campaign_id
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
    ,be_creation_platform
    ,is_cb_shop
    ,last_view_page_type
    ,last_view_event_timestamp
    ,last_view_event_datetime
    ,upper('${region}') as grass_region
    ,DATE('${grass_date}') as grass_date
from 
    result
;