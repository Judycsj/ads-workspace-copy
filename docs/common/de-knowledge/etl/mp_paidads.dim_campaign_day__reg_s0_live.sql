-- task_code: data_paidadsmart.studio_8464778  asset_id: 8464778
CREATE EXTERNAL TABLE IF NOT EXISTS dim_campaign_day__reg_s0_live
(
    id bigint comment 'id in campaign_day_tab'
    ,campaign_name string comment 'campaign name'
    ,start_time bigint comment 'campaign start timestamp'
    ,end_time bigint comment 'campaign end timestamp'
    ,campaign_day date comment 'campaign day'
)
COMMENT 'real campaign day'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
LOCATION '${HIVE_PATH}/dim_campaign_day__reg_s0_live/'
;

insert overwrite table dim_campaign_day__reg_s0_live partition (tz_type='local', grass_region, grass_date)
select
    id
    ,campaign_name
    ,start_time
    ,end_time
    ,explode (
        sequence(
            date(from_utc_timestamp(to_utc_timestamp(cast(start_time as timestamp), 'Asia/Singapore'),'${timezone}'))
            ,date(from_utc_timestamp(to_utc_timestamp(cast(end_time as timestamp), 'Asia/Singapore'),'${timezone}'))
            ,interval 1 day
        )
    ) as camapign_day
    ,upper('${region}') as grass_region
    ,date('${BIZ_YESTERDAY}') as grass_date
from mp_paidads.shopee_ads_${region}_db__campaign_day_tab__reg_continuous_s0_live
where COALESCE(cast(get_json_object(_decoded_extinfo, '$.is_not_campaign_day') as boolean), false) = false
;