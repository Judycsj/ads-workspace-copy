-- task_code: data_paidadsmart.studio_5654373  asset_id: 5654373
create external table if not exists dim_product_campaign__reg_s0_live(
    campaign_id bigint
    ,shop_id bigint
    ,user_id bigint
    ,campaign_create_datetime string
    ,campaign_modify_datetime string
    ,product_selection int
    ,product_placement int
    ,bidding_strategy int
    ,campaign_create_timestamp bigint
    ,campaign_modify_timestamp bigint
    ,creative boolean
    ,ecpc boolean 
    ,search struct<keyword_ads_id:bigint>
    ,target struct<daily_discover:struct<price:bigint,status:int>,you_may_also_like:struct<price:bigint,status:int>>
)partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dim_product_campaign/'
;


CREATE OR REPLACE TEMPORARY VIEW product_campaign_tab_df AS
(
    SELECT
        id
        , campaignid AS campaign_id
        , shopid AS shop_id
        , userid AS user_id
        , ctime AS campaign_create_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(ctime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as campaign_create_datetime
        , mtime AS campaign_modify_timestamp
        , date_format(from_utc_timestamp(to_utc_timestamp(cast(mtime as timestamp),'Asia/Singapore'), '${timezone}'), 'yyyy-MM-dd HH:mm:ss') as campaign_modify_datetime
        , product_selection
        , product_placement
        , bidding_strategy
        , from_json(_decoded_extinfo, 'struct<search:struct<keyword_ads_id:bigint>,target:struct<daily_discover:struct<price:bigint,status:int>,you_may_also_like:struct<price:bigint,status:int>>,creative:boolean,ecpc:boolean,has_item_boost:boolean>') as decoded_extinfo
    FROM mp_paidads.shopee_ads_${region}_db__product_campaign_tab__reg_continuous_s0_live
    WHERE ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
);

INSERT OVERWRITE TABLE dim_product_campaign__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  campaign_id
            ,shop_id
            ,user_id
            ,campaign_create_datetime
            ,campaign_modify_datetime
            ,product_selection
            ,product_placement
            ,bidding_strategy
            ,campaign_create_timestamp
            ,campaign_modify_timestamp
            ,decoded_extinfo.creative as creative
            ,decoded_extinfo.ecpc as ecpc
            ,decoded_extinfo.search as search
            ,decoded_extinfo.target as target
            ,upper('${region}') AS grass_region
            ,DATE('${grass_date}') as grass_date
    FROM product_campaign_tab_df
;

alter table dim_product_campaign__${region}_s0_live add if not exists partition (grass_date= '${grass_date}');