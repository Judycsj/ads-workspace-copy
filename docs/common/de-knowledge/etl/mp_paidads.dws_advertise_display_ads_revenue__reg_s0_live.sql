-- task_code: data_paidadsmart.studio_6014176  asset_id: 6014176
create external table if not exists dws_advertise_display_ads_revenue__reg_s0_live (
    ads_id bigint comment 'ads_id'
    ,entrance int
    ,pricing_type int
    ,placement int
    ,shop_id bigint comment 'shop_id'
    ,budget_start_datetime string comment 'budget_start_date'
    ,budget_end_datetime string comment 'budget_end_date'
    ,impression_cnt bigint comment 'impression_cnt'
    ,estimate_cpm_local decimal(38, 10) comment 'estimate_cpm_local'
    ,estimate_cpm_usd decimal(38, 10) comment 'estimate_cpm_usd'
    ,expense_amt_local decimal(38, 10) comment 'expense_amt_local'
    ,expense_amt_usd decimal(38, 10) comment 'expense_amt_usd'
    ,click_cnt bigint
    ,campaign_id bigint
) comment '${SCHEMA}.dws_brand_tracking_ads_1d_reg' partitioned by (
    tz_type string,
    grass_region string,
    grass_date date comment 'date'
) stored as parquet location "${HIVE_PATH}/dws_advertise_display_ads_revenue"
;
set time zone '${timezone}';
create external table if not exists dws_advertise_display_ads_revenue__${region}_s0_live (
    ads_id bigint comment 'ads_id'
    ,entrance int
    ,pricing_type int
    ,placement int
    ,shop_id bigint comment 'shop_id'
    ,budget_start_datetime string comment 'budget_start_date'
    ,budget_end_datetime string comment 'budget_end_date'
    ,impression_cnt bigint comment 'impression_cnt'
    ,estimate_cpm_local decimal(38, 10) comment 'estimate_cpm_local'
    ,estimate_cpm_usd decimal(38, 10) comment 'estimate_cpm_usd'
    ,expense_amt_local decimal(38, 10) comment 'expense_amt_local'
    ,expense_amt_usd decimal(38, 10) comment 'expense_amt_usd'
    ,click_cnt bigint
    ,campaign_id bigint
)  partitioned by (
    grass_date date comment 'date'
) stored as parquet location "${HIVE_PATH}/dws_advertise_display_ads_revenue/tz_type=local/grass_region=MX"
;


insert overwrite table dws_advertise_display_ads_revenue__${region}_s0_live partition (grass_date)
select
    display_ads_traffic.ads_id
    ,entrance
    ,pricing_type
    ,placement
    -- now is fixed value, to be change
    ,shop_id
    ,budget_start_datetime
    ,budget_end_datetime
    -- change percision
    ,impression_cnt
    ,round(cpm_local / 100000, 2) as cpm_local
    ,round(cpm_local / 100000 / exchange_rate, 2) as cpm_usd
    ,round(cpm_local * impression_cnt / 100000, 2) as expense_amt_local
    ,round(cpm_local * impression_cnt / 100000 / exchange_rate, 2) as expense_amt_usd
    ,click_cnt
    ,campaign_id
    ,DATE('${grass_date}') as grass_date
from
    (
        select
            ads_id
            ,entrance
            ,pricing_type
            ,placement
            ,grass_region
            ,campaign_id
            ,sum(impression) as impression_cnt
            ,sum(non_fraud_click) as click_cnt
            ,max(cpm) as cpm_local
        from mp_paidads.ods_log_ads_report_hi__reg_s0_live
        where
            grass_region = upper('${region}')
            and   grass_date >= DATE('${grass_date}')
            and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
            and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) < DATE_ADD(DATE('${grass_date}'), 1)
            and   DATE(from_unixtime(timestamp, 'yyyy-MM-dd HH:mm:ss')) >= DATE('${grass_date}')
            and placement = 9
            and slot_id is not null
            -- in order to filter some imp
        group by 1, 2, 3, 4, 5, 6
    ) display_ads_traffic
    left join (
        select
            ads_id
            ,shop_id
            ,budget_start_datetime
            ,budget_end_datetime
        from mkplpaidads_data.dim_display_ads__reg_s3_live
        where
            grass_date = DATE('${grass_date}')
            and tz_type = 'local'
            and grass_region = upper('${region}')
    ) display_ads on display_ads.ads_id = display_ads_traffic.ads_id
    left join (
        select
            grass_region
            ,exchange_rate
        from mp_order.dim_exchange_rate__reg_s0_live
        where grass_date = DATE('${grass_date}')
    ) exchange_rate_info on display_ads_traffic.grass_region = exchange_rate_info.grass_region
where
    substr(cast(budget_end_datetime as string), 0, 11) >= DATE('${grass_date}')
;

alter table dws_advertise_display_ads_revenue__reg_s0_live add if not exists partition (grass_region = 'MX',tz_type = 'local',grass_date = "${grass_date}")
;