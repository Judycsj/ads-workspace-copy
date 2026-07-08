-- task_code: data_paidadsmart.studio_3050657  asset_id: 3050657
create external table if not exists dws_campaign_deduction_budget_1d__reg_s0_live
(
    campaign_id bigint comment 'campaign_id'
    ,total_quota_local double comment 'total_quota_local'
    ,total_deduction double comment 'total_deduction'
    ,hit_total_budget tinyint comment 'hit_total_budget'
    ,daily_quota_local double comment 'daily_quota_local'
    ,daily_deduction double comment 'daily_deduction'
    ,hit_daily_budget tinyint comment 'hit_daily_budget'
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${path}'
;

create external table if not exists dws_campaign_deduction_budget_1d__${region}_s0_live
(
    campaign_id bigint comment 'campaign_id'
    ,total_quota_local double comment 'total_quota_local'
    ,total_deduction double comment 'total_deduction'
    ,hit_total_budget tinyint comment 'hit_total_budget'
    ,daily_quota_local double comment 'daily_quota_local'
    ,daily_deduction double comment 'daily_deduction'
    ,hit_daily_budget tinyint comment 'hit_daily_budget'
) 
partitioned by
(
    grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${path}/tz_type=local/grass_region=${upper_region}'
;

insert overwrite table dws_campaign_deduction_budget_1d__reg_s0_live partition (tz_type = 'local', grass_region, grass_date)
select  dim_campaign_tab.campaign_id
        ,total_quota_local
        ,total_deduction
        -- if total_quota_local is not set, then null, can treat total quota as maxvalue
        ,case   when (total_quota_local is null or total_quota_local = 0) then 0
                when (total_quota_local - total_deduction <= 0) then 1
                else 0
         end as hit_total_budget
        ,daily_quota_local
        ,daily_deduction
        -- if daily_quota_local is not set, then null, can treat total quota as maxvalue
        ,case   when (daily_quota_local is null or daily_quota_local = 0) then 0
                when (daily_quota_local - daily_deduction <= 0) then 1
                else 0
         end as hit_daily_budget
        ,dim_campaign_tab.grass_region as grass_region
        ,date('${grass_date}') as grass_date
from    (
    select  campaign_id
            ,total_quota_local
            ,daily_quota_local
            ,grass_region
    from    mp_paidads.dim_campaign__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = date('${grass_date}')
) dim_campaign_tab
left outer join (
    -- total deduction
    select  campaign_id
            ,deduction AS total_deduction
            ,grass_region AS region
    from    mp_paidads.dws_campaign_deduction_td__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = date('${grass_date}')
) t_deduction
on      dim_campaign_tab.campaign_id = t_deduction.campaign_id
  and   dim_campaign_tab.grass_region = t_deduction.region
left outer join (
    -- daily deduction
    select  campaign_id
            ,sum(total_expenditure_amt_local_1d) AS daily_deduction
    from    mp_paidads.dws_advertise_revenue_1d__reg_s0_live
    where   grass_region = upper('${region}')
      and   grass_date = date('${grass_date}')
      and tz_type = 'local'
      group by 1
) d_deduction
on      dim_campaign_tab.campaign_id = d_deduction.campaign_id
;

alter table dws_campaign_deduction_budget_1d__${region}_s0_live add if not exists partition (grass_date = "${grass_date}")
;