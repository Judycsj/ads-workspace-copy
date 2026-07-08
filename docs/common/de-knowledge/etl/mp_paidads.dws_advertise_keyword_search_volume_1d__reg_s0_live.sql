-- task_code: data_paidadsmart.studio_2851956  asset_id: 2851956
add jar hdfs://R2/projects/mkplpaidads_data/hdfs/udf/muyu.gao/fill_rate/paidads-data-warehouse-udf-1.0.0.jar
;

create or replace temporary function get_full_signature_udf as 'com.shopee.deepdata.warehouse.hive.udf.GetFullSignatureUDF'
;

create external table if not exists dws_advertise_keyword_search_volume_1d__reg_s0_live
(
    keyword String comment 'keyword'
    ,search_volume bigint comment 'search_volume'
    ,search_volume_percentile string comment 'search_volume_percentile'
    ,req_w_ads_imp_cnt bigint comment 'number of request with ads impression'
    ,req_w_ads_imp_pct double comment 'req_w_ads_imp_pct'
) 
comment 'dws_advertise_keyword_search_volume_1d'
partitioned by
(
    tz_type String
    ,grass_region String
    ,grass_date DATE
)
stored as PARQUET
location '${path}'
;

create external table if not exists dws_advertise_keyword_search_volume_1d__${region}_s0_live
(
    keyword String comment 'keyword'
    ,search_volume bigint comment 'search_volume'
    ,search_volume_percentile string comment 'search_volume_percentile'
    ,req_w_ads_imp_cnt bigint comment 'number of request with ads impression'
    ,req_w_ads_imp_pct double comment 'req_w_ads_imp_pct'
) 
comment 'dws_advertise_keyword_search_volume_1d'
partitioned by
(
    grass_date DATE
)
stored as PARQUET
location '${path}/tz_type=local/grass_region=${upper_region}'
;

insert overwrite table dws_advertise_keyword_search_volume_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select  keyword
        ,search_volume
        ,(case  when search_volume_percentile >= 0 and search_volume_percentile < 0.1 then 'p0'
                when search_volume_percentile >= 0.1 and search_volume_percentile < 0.2 then 'p10'
                when search_volume_percentile >= 0.2 and search_volume_percentile < 0.3 then 'p20'
                when search_volume_percentile >= 0.3 and search_volume_percentile < 0.4 then 'p30'
                when search_volume_percentile >= 0.4 and search_volume_percentile < 0.5 then 'p40'
                when search_volume_percentile >= 0.5 and search_volume_percentile < 0.6 then 'p50'
                when search_volume_percentile >= 0.6 and search_volume_percentile < 0.7 then 'p60'
                when search_volume_percentile >= 0.7 and search_volume_percentile < 0.8 then 'p70'
                when search_volume_percentile >= 0.8 and search_volume_percentile < 0.9 then 'p80'
                when search_volume_percentile >= 0.9 and search_volume_percentile < 0.95 then 'p90'
                when search_volume_percentile >= 0.95 and search_volume_percentile < 0.99 then 'p95'
                when search_volume_percentile >= 0.99 then 'p99'
          end) as search_volume_percentile
          ,req_w_ads_imp_cnt
          ,coalesce(req_w_ads_imp_pct, 0.0) as req_w_ads_imp_pct
          ,grass_region
          ,date('${grass_date}') as grass_date
from    (
    select  keyword
            ,search_volume
            ,PERCENT_RANK() over (partition by grass_region order by search_volume asc) as search_volume_percentile
            ,req_w_ads_imp_cnt
            ,req_w_ads_imp_cnt * 1.00 /search_volume as req_w_ads_imp_pct
            ,grass_region           
    from    (
        select  keyword
                ,count(distinct request_id) as search_volume
                ,count(distinct case when ads_imp > 0 then request_id else null end) as req_w_ads_imp_cnt
                ,grass_region
        from    (
            select  grass_region
                    ,keyword
                    ,request_id
                    ,sum(case when is_ads = 'true' then impress_cnt_direct_lead else 0 end) as ads_imp
            from    (
                select  grass_region
                        ,get_json_object(get_json_object(step1_data, '$.search_FE.search_params'), '$.keyword') as keyword
                        ,get_json_object(get_json_object(step1_data, '$.search_info'), '$.request_id') as request_id
                        ,coalesce(get_json_object(get_json_object(step1_data_property, '$.common_params'), '$.is_ads'), get_json_object(get_json_object(step1_data_property, '$.search_params.search_info'), '$.is_ads'), 'false') as is_ads
                        ,impress_cnt_direct_lead
                        ,ab_test
                from    mp_foa.dwd_eventid_impress_di__reg_s0_live
                where   grass_date = date('${grass_date}') 
                  and   grass_region = upper('${region}')
                  and   platform in ('ios_app', 'android_app')
                  and   step1_feature_detail in ('global_search-item','search_in_pdp-item','search_in_subcategory-item')  
                  and   get_full_signature_udf(split(ab_test, '@')[1]) != 'DS2'
                  and   target_type = 'item'
                  and   user_id > 0
                  
            ) a
            group by grass_region, keyword, request_id
        ) t
        group by grass_region, keyword
    ) search_volume
) output
;

alter table dws_advertise_keyword_search_volume_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}")
;