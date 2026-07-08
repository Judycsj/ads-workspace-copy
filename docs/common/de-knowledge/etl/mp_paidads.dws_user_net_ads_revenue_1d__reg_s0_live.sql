-- task_code: data_paidadsmart.studio_10551306  asset_id: 10551306
create external table if not exists dws_user_net_ads_revenue_1d__reg_s0_live
(
    shop_id	bigint
    ,user_id	bigint
    ,ads_id	bigint
    ,item_id	bigint
    ,campaign_id	bigint
    ,entrance	int
    ,placement	int
    ,pricing_type	int
    ,sub_entrance	bigint
    ,credit_order_type	bigint
    ,credit_order_type_name	string
    ,credit_reason	string
    ,credit_topup_sub_type	bigint
    ,credit_topup_sub_type_name	string
    ,credit_program_id	bigint
    ,credit_program_name	string
    ,credit_topup_type	int
    ,credit_topup_type_name	string
    ,entry_point	string
    ,entry_point_v2	string
    ,traffic_type	string
    ,sub_product_type	string
    ,product_type	string
    ,main_product_type	string
    ,raw_gross_ads_revenue_usd_1d	double
    ,gross_ads_revenue_usd_1d	double
    ,net_ads_revenue_usd_1d	double

    ,paid_credit_revenue_usd_1d	double
    ,raw_paid_credit_revenue_usd_1d	double
    ,others_free_credit_revenue_usd_1d	double
    ,raw_others_free_credit_revenue_usd_1d	double
    ,tax_paid_on_free_credit_revenue_usd_1d	double
    ,free_credit_deduction_amt_usd_1d	double
    ,free_ads_revenue_amt_usd_1d	double
    ,sip_free_credit_revenue_usd_1d	double
    ,scs_free_credit_revenue_usd_1d	double
    ,lovito_free_credit_revenue_usd_1d	double
    ,gov_free_credit_revenue_usd_1d	double

    ,paid_credit_expired_amt_usd_1d	double
    ,others_free_credit_expired_amt_usd_1d	double
    ,raw_display_ads_revenue_usd_1d double
    ,display_ads_revenue_usd_1d	double
) 
partitioned by
(
    tz_type string comment 'tz_type'
    ,grass_region string comment 'grass_region'
    ,grass_date DATE comment 'grass_date'
)
stored as PARQUET
location '${HIVE_PATH}/dws_user_net_ads_revenue_1d'
;

create or replace temporary view deduction_di as
select shop_id
    ,user_id
    ,ads_id
    ,entrance
    ,placement
    ,pricing_type
    ,topup_order_id
    ,credit_order_type
    ,credit_topup_type
    ,deduction_amt_usd
    ,sub_entrance
    ,item_id
    ,campaign_id
from mp_paidads.dwd_advertiser_deduction_di__reg_s0_live
where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local'
;

cache table ratio_citi 
select  substr(create_datetime,1,10) as create_date
        ,sum(if(COALESCE(payment_be_channel_id,0) not in (100061, 100062, 100064, 100065, 100066, 100067, 100068, 100069, 100070, 100071, 100072, 100073, 100074, 100075, 100076, 100077, 100078, 100079, 100080, 101420), gmv_usd, 0)) / sum(gmv_usd) as cb_citi_ratio
from    mp_order.dwd_order_item_all_ent_df__br_s0_live
where  grass_date >= date('${grass_date}')
      and   grass_region = '${upper_region}'
      and   date(create_datetime) = date('${grass_date}')
      and   tz_type = 'local'
      and   is_bi_excluded = 0
      and   order_be_status_id != 1
      and   is_net_order = 1
      and   is_cb_shop = 1
      and gmv_usd != 0 -- new filter to prevent division 0 error
group by 1
;

create or replace temporary view tax as
select
    grass_date
    ,max(case when metric_type = 'cb_paid_ads_revenue' then vat_rate else 0.0 end) as cb_paid_tax
    ,max(case when metric_type = 'local_paid_ads_revenue' then vat_rate else 0.0 end) as local_paid_tax
    ,max(case when metric_type = 'cb_free_ads_revenue' then vat_rate else 0.0 end) as cb_free_tax
    ,max(case when metric_type = 'local_free_ads_revenue' then vat_rate else 0.0 end) as local_free_tax
from regbida_keyreports.dim_vat_rate 
where grass_region = '${upper_region}'
and metric_type in ('cb_paid_ads_revenue', 'local_paid_ads_revenue','local_free_ads_revenue', 'cb_free_ads_revenue') 
group by 1;
 
create or replace temporary view dim_advertiser as
select  shop_id,is_cb_seller as is_cb_shop
from  mp_paidads.dim_advertiser__reg_s0_live
where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local'
;
 
create or replace temporary view topup_df as
select
    shop_id
    ,order_id
    ,order_type as credit_order_type
    ,order_type_name as credit_order_type_name
    ,credit_topup_type
    ,credit_topup_type_name
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,credit_reason
    ,is_credit_topup_expired
    ,credit_balance_amt_usd
    ,is_credit_topup_expired_today
    ,COALESCE(from_unixtime(topup_create_timestamp, 'yyyy-MM-dd HH:mm:ss'),grass_date) as topup_create_datetime
    
    ,if(credit_program_name = 'NNWH Seller Drive'
                or credit_program_name = 'cncb seller wallet program'
                or lower(credit_program_name) like '%[gov fund]%'
                or credit_reason in ('2022-04-11-free-ads-MY-High Potential Brands-1', '2022-04-11-free-ads-PH-High Potential Brands-1', '2022-04-11-free-ads-SG-High Potential Brands-1', '2022-04-11-free-ads-TH-High Potential Brands-1', '2022-04-11-free-ads-VN-High Potential Brands-1', '2022-04-11-free-ads-TW-High Potential Brands-1')
                or lower(credit_reason) like '%[gov fund]%'
                or lower(credit_reason) like '%gvmt fund%', 1, 0) as is_taxable_ads
    ,case when (
                                    credit_program_name = 'NNWH Seller Drive'
                                or  credit_program_name = 'cncb seller wallet program'
                                or  lower(credit_program_name) like '%[gov fund]%'
                                or  credit_reason in ('2022-04-11-free-ads-MY-High Potential Brands-1', '2022-04-11-free-ads-PH-High Potential Brands-1', '2022-04-11-free-ads-SG-High Potential Brands-1', '2022-04-11-free-ads-TH-High Potential Brands-1', '2022-04-11-free-ads-VN-High Potential Brands-1', '2022-04-11-free-ads-TW-High Potential Brands-1')
                                or  lower(credit_reason) like '%[gov fund]%'
                                or  lower(credit_reason) like '%gvmt fund%'
                            ) then 'gov'
            when (credit_topup_sub_type_name = 'ads spending growth' and lower(credit_program_name) like '%-lovito-monthly ads self top up%') 
                or (credit_topup_sub_type_name = 'ads spending growth'
                        and lower(credit_program_name) like '%-lovito-monthly ads platform top up%'
                        and date(topup_create_datetime) < '2025-01-01') then 'lovito'
            when (
                                    (
                                            credit_topup_sub_type_name = 'sip ads drive'
                                        and lower(credit_program_name) like'%sip%'
                                    )
                                or  (
                                            credit_topup_sub_type_name = 'refund - others'
                                        and credit_program_name = 'SIP compansation'
                                    )
                                or  (
                                            credit_topup_sub_type_name = 'ads spending growth'
                                        and credit_program_name = 'Venus project'
                                    )
                            )
                        and not ((credit_topup_sub_type_name = 'reward for non-ads features' and credit_program_name in('[Free credits] - SGCB SIP LPP rebate Sep batch', '[Free credits] - SGCB SIP LPP rebate Sept batch 1'))
            or (credit_topup_sub_type_name = 'ads spending growth' and credit_program_name in('ID SIP - SMT sponsor budget', 'SIP Quick Start Project'))) then 'SIP'
            when (   
                        (
                            credit_topup_type in (3, 4)
                        and credit_topup_sub_type_name = 'ads spending growth'
                        and lower(credit_program_name) like '%-scs-monthly ads self top up%'
                        )
                    or (
                            credit_topup_sub_type_name in ('ads spending growth','reward for non-ads features')
                        and lower(credit_program_name) like '%-local-scs self top up%'
                        )
                    or  (
                            credit_topup_type in (3, 4)
                        and credit_topup_sub_type_name = 'ads spending growth'
                        and lower(credit_program_name) like '%-vn-local-scs-project ads self top up%'
                        )
                    or (
                            credit_topup_type in (3, 4)
                        and credit_topup_sub_type_name = 'reward for non-ads features'
                        and lower(credit_program_name) like '%local scs project%'
                        )
                    or (credit_topup_sub_type_name = 'ads spending growth'
                        and lower(credit_program_name) like '%-scs-monthly ads platform top up%'
                        and date(topup_create_datetime) < '2025-01-01')
             ) then 'SCS' else 'others' end as gov_order_type
    ,grass_date
    ,grass_region
from mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
where   grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local'
;
 
 
create or replace temporary view gov_order as
select 
    order_id
    ,credit_order_type
    ,credit_order_type_name
    ,credit_topup_type
    ,credit_topup_type_name
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,credit_reason
    ,gov_order_type
    ,is_taxable_ads
    ,topup_create_datetime
from    topup_df
group by 1,2,3,4,5,6,7,8,9,10,11,12,13
;
 


 
create or replace temporary view deduction_amt as
select 
    shop_id
    ,user_id
    ,ads_id
    ,item_id
    ,campaign_id
    ,entrance
    ,placement
    ,pricing_type
    ,sub_entrance
    ,credit_order_type
    ,credit_order_type_name
    ,credit_reason
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,credit_topup_type
    ,credit_topup_type_name
    
    ,sum(case when credit_topup_type in (1,2) and is_cb_shop = 1 then deduction_amt_usd * (1- paid_tax_rate) * cb_citi_ratio + deduction_amt_usd * (1-cb_citi_ratio) 
              when credit_topup_type in (1,2) and is_cb_shop = 0 then deduction_amt_usd * (1 - paid_tax_rate)
              else 0.0 end) as paid_credit_revenue_usd_1d
    ,sum(case when credit_topup_type in (1,2) then deduction_amt_usd else 0.0 end) as raw_paid_credit_revenue_usd_1d
    ,sum(case when credit_topup_type in (3, 4) and gov_order_type in ('SCS','SIP','lovito','gov') and is_cb_shop = 1 and is_taxable_ads = 1 then deduction_amt_usd * (1- paid_tax_rate) * cb_citi_ratio + deduction_amt_usd * (1-cb_citi_ratio) 
              when credit_topup_type in (3, 4) and gov_order_type in ('SCS','SIP','lovito','gov') and is_cb_shop = 0 and is_taxable_ads = 1 then deduction_amt_usd * (1 - paid_tax_rate)
              when credit_topup_type in (3, 4) and gov_order_type in ('SCS','SIP','lovito','gov') and is_taxable_ads = 0 then deduction_amt_usd 
              else 0.0 end) as others_free_credit_revenue_usd_1d
    ,sum(case when credit_topup_type in (3, 4) and gov_order_type in ('SCS','SIP','lovito','gov') then deduction_amt_usd else 0.0 end) as raw_others_free_credit_revenue_usd_1d  
    ,sum(case when credit_topup_type in (3, 4) and  gov_order_type not in ('SCS','SIP','lovito','gov')
                  then
                       case when '${upper_region}' = 'ID' then deduction_amt_usd * free_tax_rate /  (1 + free_tax_rate)
                            when '${upper_region}' = 'TH' and topup_create_datetime < '2022-05-01' then deduction_amt_usd / (1 + free_tax_rate)
                            else 0.0 end
             else 0.0 end) as tax_paid_on_free_credit_revenue_usd_1d  
    ,sum(case when (credit_topup_type in (3, 4) and gov_order_type not in ('SCS','SIP','lovito','gov')) then deduction_amt_usd else 0.0 end) as free_credit_deduction_amt_usd_1d
    ,sum(case when credit_topup_type in (3, 4) and gov_order_type = 'SCS' and is_cb_shop = 1 and is_taxable_ads = 1 then deduction_amt_usd * (1- paid_tax_rate) * cb_citi_ratio + deduction_amt_usd * (1-cb_citi_ratio) 
              when credit_topup_type in (3, 4) and gov_order_type = 'SCS' and is_cb_shop = 0 and is_taxable_ads = 1 then deduction_amt_usd * (1 - paid_tax_rate)
              when credit_topup_type in (3, 4) and gov_order_type = 'SCS' and is_taxable_ads = 0 then deduction_amt_usd 
              else 0.0 end) as scs_free_credit_revenue_usd_1d
    ,sum(case when credit_topup_type in (3, 4) and gov_order_type = 'SIP' and is_cb_shop = 1 and is_taxable_ads = 1 then deduction_amt_usd * (1- paid_tax_rate) * cb_citi_ratio + deduction_amt_usd * (1-cb_citi_ratio) 
              when credit_topup_type in (3, 4) and gov_order_type = 'SIP' and is_cb_shop = 0 and is_taxable_ads = 1 then deduction_amt_usd * (1 - paid_tax_rate)
              when credit_topup_type in (3, 4) and gov_order_type = 'SIP' and is_taxable_ads = 0 then deduction_amt_usd 
              else 0.0 end) as sip_free_credit_revenue_usd_1d
    ,sum(case when credit_topup_type in (3, 4) and gov_order_type = 'lovito' and is_cb_shop = 1 and is_taxable_ads = 1 then deduction_amt_usd * (1- paid_tax_rate) * cb_citi_ratio + deduction_amt_usd * (1-cb_citi_ratio) 
              when credit_topup_type in (3, 4) and gov_order_type = 'lovito' and is_cb_shop = 0 and is_taxable_ads = 1 then deduction_amt_usd * (1 - paid_tax_rate)
              when credit_topup_type in (3, 4) and gov_order_type = 'lovito' and is_taxable_ads = 0 then deduction_amt_usd 
              else 0.0 end) as lovito_free_credit_revenue_usd_1d
    ,sum(case when credit_topup_type in (3, 4) and gov_order_type = 'gov' and is_cb_shop = 1 and is_taxable_ads = 1 then deduction_amt_usd * (1- paid_tax_rate) * cb_citi_ratio + deduction_amt_usd * (1-cb_citi_ratio) 
              when credit_topup_type in (3, 4) and gov_order_type = 'gov' and is_cb_shop = 0 and is_taxable_ads = 1 then deduction_amt_usd * (1 - paid_tax_rate)
              when credit_topup_type in (3, 4) and gov_order_type = 'gov' and is_taxable_ads = 0 then deduction_amt_usd 
              else 0.0 end) as gov_free_credit_revenue_usd_1d
from
(select 
    a.shop_id as shop_id
    ,user_id
    ,ads_id
    ,item_id
    ,campaign_id
    ,entrance
    ,placement
    ,pricing_type
    ,topup_order_id
    ,deduction_amt_usd
    ,coalesce(topup_create_datetime,'${grass_date}') as topup_create_datetime
    ,is_cb_shop
    ,sub_entrance
    ,COALESCE(case when is_cb_shop = 1 then cb_paid_tax else local_paid_tax end,0.0) as paid_tax_rate
    ,COALESCE(case when is_cb_shop = 1 then cb_free_tax else local_free_tax end,0.0) as free_tax_rate
    ,COALESCE(gov_order_type,'others') as gov_order_type
    ,a.credit_order_type
    ,b.credit_order_type_name
    ,credit_reason
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,a.credit_topup_type as credit_topup_type
    ,credit_topup_type_name
    ,is_taxable_ads
    ,cb_citi_ratio
from deduction_di a 
left join gov_order b 
on a.topup_order_id = b.order_id
and a.credit_order_type = b.credit_order_type
and a.credit_topup_type = b.credit_topup_type
left join dim_advertiser c 
on a.shop_id = c.shop_id
left join tax d 
on least(substr(b.topup_create_datetime,1,10), '${grass_date}') = d.grass_date
left join ratio_citi e
on date('${grass_date}') = date(e.create_date)
)t
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
;


create or replace temporary view expiry_credit_cal as
select sum(case when credit_topup_type = 2 and is_cb_shop = 1  then credit_balance_amt_usd * (1- tax_rate) * cb_citi_ratio + credit_balance_amt_usd * (1-cb_citi_ratio) 
                  when credit_topup_type = 2 and is_cb_shop = 0  then credit_balance_amt_usd * (1 - tax_rate)
                  else 0.0 end) as paid_credit_expired_amt_usd_1d
        ,sum(case when credit_topup_type = 4 and gov_order_type in ('SCS','SIP','lovito','gov') and is_cb_shop = 1 and is_taxable_ads = 1 then credit_balance_amt_usd * (1- tax_rate) * cb_citi_ratio + credit_balance_amt_usd * (1-cb_citi_ratio) 
                  when credit_topup_type = 4 and gov_order_type in ('SCS','SIP','lovito','gov') and is_cb_shop = 0 and is_taxable_ads = 1 then credit_balance_amt_usd * (1 - tax_rate)
                  when credit_topup_type = 4 and gov_order_type in ('SCS','SIP','lovito','gov') and is_taxable_ads = 0 then credit_balance_amt_usd 
                  else 0.0 end) as others_free_credit_expired_amt_usd_1d
from
(select  credit_balance_amt_usd
        ,COALESCE(case when is_cb_shop = 1 then cb_paid_tax else local_paid_tax end,0.0) as tax_rate
        ,COALESCE(gov_order_type,'others') as gov_order_type
        ,credit_topup_type
        ,is_taxable_ads  
        ,cb_citi_ratio   
        ,is_cb_shop
from topup_df a
left join dim_advertiser c on a.shop_id = c.shop_id
left join tax d on least(substr(a.topup_create_datetime,1,10), '${grass_date}') = d.grass_date
left join ratio_citi e on a.grass_date = date(e.create_date)
where a.is_credit_topup_expired_today = 1
)t
;

create or replace temporary view expiry_credit as
select user_id
    ,paid_credit_expired_amt_usd_1d/count(*) over() as paid_credit_expired_amt_usd_1d
    ,others_free_credit_expired_amt_usd_1d/count(*) over() as others_free_credit_expired_amt_usd_1d
from (
    select user_id
    from deduction_di 
    group by 1
)a cross join expiry_credit_cal b
;

 
create or replace temporary view raw_display_ads_reveune as
select shop_id
    ,display_ads_traffic.ads_id
    ,user_id
    ,entrance
    ,0 as sub_entrance
    ,pricing_type
    ,placement
    ,campaign_id
    ,SUM(case when grass_date >= date('2022-10-26') then round(cpm_local * impression_cnt / 100000 / exchange_rate, 2)/1000.00 else round(cpm_local * impression_cnt / 100000 / exchange_rate, 2)/100000.00/1000.00 end) as raw_display_ads_revenue_usd_1d
from
    (
        select
            ads_id
            ,user_id
            ,entrance
            ,pricing_type
            ,placement
            ,grass_region
            ,campaign_id
            ,grass_date
            ,sum(impression_cnt) as impression_cnt
            ,max(cpm) as cpm_local
        from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local'
            and placement = 9 and slot_id is not null
            and (
                not (
                    (ads_id = 19473362)
                    and (timestamp >= 1663688089)
                )
            )
        group by 1, 2, 3, 4, 5, 6,7,8
    ) display_ads_traffic
    left join (
        select
            ads_id
            ,shop_id
            ,budget_start_datetime
            ,budget_end_datetime
        from mkplpaidads_data.dim_display_ads__reg_s3_live
        where grass_date = date('${grass_date}') and grass_region = '${upper_region}' and tz_type = 'local'
    ) display_ads on display_ads.ads_id = display_ads_traffic.ads_id
    left join (
        select
            grass_region
            ,exchange_rate
        from mp_order.dim_exchange_rate__reg_s0_live
        where grass_date = DATE('${grass_date}')
    ) exchange_rate_info on display_ads_traffic.grass_region = exchange_rate_info.grass_region
where substr(budget_start_datetime,1,10) <= '${grass_date}' and substr(budget_end_datetime,1,10) >= '${grass_date}'
group by 1,2,3,4,5,6,7,8
;

create or replace temporary view display_ads_reveune as 
select 
    a.shop_id as shop_id 
    ,6 as entrance
    ,0 as sub_entrance
    ,9 as placement
    ,6 as pricing_type
    ,case when is_cb_shop = 1 then display_ads_revenue_usd * (1 - cb_paid_tax) 
          when is_cb_shop = 0 or is_cb_shop is null then display_ads_revenue_usd * (1 - local_paid_tax) 
          else 0 end as display_ads_revenue_usd_1d
from
(select  cast(shop_id as bigint) as shop_id
    ,data_campanha as grass_date
    ,6 as entrance
    ,0 as sub_entrance
    ,9 as placement
    ,6 as pricing_type
    ,SUM(asset_price_usd) as display_ads_revenue_usd
from  brbi_bdseller.mks_bp_fpa_daily
where grass_month >= date('2023-01-01')
      and  data_campanha = DATE('${grass_date}')
      and  asset_type = 'display ads'
group by 1,2
)a 
left join dim_advertiser c 
on a.shop_id = c.shop_id
left join tax d 
on a.grass_date = d.grass_date
;

 
create or replace temporary view base as
select
    shop_id 
    ,user_id
    ,ads_id
    ,item_id
    ,campaign_id
    ,entrance
    ,placement
    ,pricing_type
    ,sub_entrance
    ,credit_order_type
    ,credit_order_type_name
    ,credit_reason
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,credit_topup_type
    ,credit_topup_type_name

    ,coalesce(sum(paid_credit_revenue_usd_1d),0.0)  as paid_credit_revenue_usd_1d
    ,coalesce(sum(raw_paid_credit_revenue_usd_1d),0.0)  as raw_paid_credit_revenue_usd_1d
    ,coalesce(sum(others_free_credit_revenue_usd_1d),0.0)  as others_free_credit_revenue_usd_1d
    ,coalesce(sum(raw_others_free_credit_revenue_usd_1d),0.0)  as raw_others_free_credit_revenue_usd_1d
    ,coalesce(sum(tax_paid_on_free_credit_revenue_usd_1d),0.0) as tax_paid_on_free_credit_revenue_usd_1d
    ,coalesce(sum(free_credit_deduction_amt_usd_1d),0.0) as free_credit_deduction_amt_usd_1d

    ,coalesce(sum(scs_free_credit_revenue_usd_1d),0.0) as scs_free_credit_revenue_usd_1d
    ,coalesce(sum(sip_free_credit_revenue_usd_1d),0.0)  as sip_free_credit_revenue_usd_1d
    ,coalesce(sum(lovito_free_credit_revenue_usd_1d),0.0)  as lovito_free_credit_revenue_usd_1d
    ,coalesce(sum(gov_free_credit_revenue_usd_1d),0.0)  as gov_free_credit_revenue_usd_1d
    
    ,coalesce(sum(paid_credit_expired_amt_usd_1d),0.0)  as paid_credit_expired_amt_usd_1d
    ,coalesce(sum(others_free_credit_expired_amt_usd_1d),0.0)  as others_free_credit_expired_amt_usd_1d
    ,coalesce(sum(display_ads_revenue_usd_1d),0.0)  as display_ads_revenue_usd_1d
    ,coalesce(sum(raw_display_ads_revenue_usd_1d),0.0)  as raw_display_ads_revenue_usd_1d
from
(select
    shop_id 
    ,user_id
    ,ads_id
    ,item_id
    ,campaign_id
    ,entrance
    ,placement
    ,pricing_type
    ,sub_entrance
    ,credit_order_type
    ,credit_order_type_name
    ,credit_reason
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,credit_topup_type
    ,credit_topup_type_name

    ,paid_credit_revenue_usd_1d
    ,raw_paid_credit_revenue_usd_1d
    ,others_free_credit_revenue_usd_1d
    ,raw_others_free_credit_revenue_usd_1d
    ,tax_paid_on_free_credit_revenue_usd_1d
    ,free_credit_deduction_amt_usd_1d
    ,scs_free_credit_revenue_usd_1d
    ,sip_free_credit_revenue_usd_1d
    ,lovito_free_credit_revenue_usd_1d
    ,gov_free_credit_revenue_usd_1d

    ,null as paid_credit_expired_amt_usd_1d
    ,null as others_free_credit_expired_amt_usd_1d
    ,null as display_ads_revenue_usd_1d
    ,null as raw_display_ads_revenue_usd_1d

from deduction_amt
union all
select
    null as shop_id 
    ,user_id
    ,null as ads_id
    ,null as item_id
    ,null as campaign_id
    ,null as entrance
    ,null as placement
    ,null as pricing_type
    ,null as sub_entrance
    ,null as credit_order_type
    ,null as credit_order_type_name
    ,null as credit_reason
    ,null as credit_topup_sub_type
    ,null as credit_topup_sub_type_name
    ,null as credit_program_id
    ,null as credit_program_name
    ,null as credit_topup_type
    ,null as credit_topup_type_name

    ,null as paid_credit_revenue_usd_1d
    ,null as raw_paid_credit_revenue_usd_1d
    ,null as others_free_credit_revenue_usd_1d
    ,null as raw_others_free_credit_revenue_usd_1d
    ,null as tax_paid_on_free_credit_revenue_usd_1d
    ,null as free_credit_deduction_amt_usd_1d
    ,null as scs_free_credit_revenue_usd_1d
    ,null as sip_free_credit_revenue_usd_1d
    ,null as lovito_free_credit_revenue_usd_1d
    ,null as gov_free_credit_revenue_usd_1d

    ,paid_credit_expired_amt_usd_1d
    ,others_free_credit_expired_amt_usd_1d
    ,null as display_ads_revenue_usd_1d
    ,null as raw_display_ads_revenue_usd_1d
from expiry_credit
union all
select
    shop_id 
    ,null as user_id
    ,null as ads_id
    ,null as item_id
    ,null as campaign_id
    ,entrance
    ,placement
    ,pricing_type
    ,sub_entrance
    ,null as credit_order_type
    ,null as credit_order_type_name
    ,null as credit_reason
    ,null as credit_topup_sub_type
    ,null as credit_topup_sub_type_name
    ,null as credit_program_id
    ,null as credit_program_name
    ,null as credit_topup_type
    ,null as credit_topup_type_name

    ,null as paid_credit_revenue_usd_1d
    ,null as raw_paid_credit_revenue_usd_1d
    ,null as others_free_credit_revenue_usd_1d
    ,null as raw_others_free_credit_revenue_usd_1d
    ,null as tax_paid_on_free_credit_revenue_usd_1d
    ,null as free_credit_deduction_amt_usd_1d
    ,null as scs_free_credit_revenue_usd_1d
    ,null as sip_free_credit_revenue_usd_1d
    ,null as lovito_free_credit_revenue_usd_1d
    ,null as gov_free_credit_revenue_usd_1d

    ,null as paid_credit_expired_amt_usd_1d
    ,null as others_free_credit_expired_amt_usd_1d
    ,display_ads_revenue_usd_1d
    ,0 as raw_display_ads_revenue_usd_1d
from display_ads_reveune
union all 
select
    shop_id 
    ,user_id
    ,ads_id
    ,null as item_id
    ,null as campaign_id
    ,entrance
    ,placement
    ,pricing_type
    ,sub_entrance
    ,null as credit_order_type
    ,null as credit_order_type_name
    ,null as credit_reason
    ,null as credit_topup_sub_type
    ,null as credit_topup_sub_type_name
    ,null as credit_program_id
    ,null as credit_program_name
    ,null as credit_topup_type
    ,null as credit_topup_type_name

    ,null as paid_credit_revenue_usd_1d
    ,null as raw_paid_credit_revenue_usd_1d
    ,null as others_free_credit_revenue_usd_1d
    ,null as raw_others_free_credit_revenue_usd_1d
    ,null as tax_paid_on_free_credit_revenue_usd_1d
    ,null as free_credit_deduction_amt_usd_1d
    ,null as scs_free_credit_revenue_usd_1d
    ,null as sip_free_credit_revenue_usd_1d
    ,null as lovito_free_credit_revenue_usd_1d
    ,null as gov_free_credit_revenue_usd_1d

    ,null as paid_credit_expired_amt_usd_1d
    ,null as others_free_credit_expired_amt_usd_1d
    ,null as display_ads_revenue_usd_1d
    ,raw_display_ads_revenue_usd_1d
from raw_display_ads_reveune
)a
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
;

 
create or replace temporary view sub_entrance_mapping as
select entry_point ,entrance ,sub_entrance
from mp_paidads.dim_entry_point_mapping
where sub_entrance > 0
;
 
create or replace temporary view entrance_mapping as
select entry_point ,entrance
from mp_paidads.dim_entry_point_mapping
where (sub_entrance is null or sub_entrance = '')
group by 1,2
;
 
create or replace temporary view entrance_mapping_v2 as
select entry_point as entry_point_v2 ,entrance ,traffic_type
from mp_paidads.dim_entry_point_mapping_v2
group by 1,2,3
;
 
create or replace temporary view product_type_mapping as
select pricing_type ,placement ,sub_product_type ,product_type ,main_product_type
from mp_paidads.dim_product_type_mapping__reg_s0_live 
group by 1,2,3,4,5
;
 
insert overwrite table dws_user_net_ads_revenue_1d__reg_s0_live partition (tz_type = 'local', grass_region='${upper_region}', grass_date = '${grass_date}')
select
    shop_id 
    ,user_id
    ,ads_id
    ,item_id
    ,campaign_id
    ,a.entrance
    ,a.placement
    ,a.pricing_type
    ,a.sub_entrance
    ,credit_order_type
    ,credit_order_type_name
    ,credit_reason
    ,credit_topup_sub_type
    ,credit_topup_sub_type_name
    ,credit_program_id
    ,credit_program_name
    ,credit_topup_type
    ,credit_topup_type_name
    ,COALESCE(b.entry_point,c.entry_point,'Undefined') as entry_point
    ,COALESCE(entry_point_v2,'Undefined') as entry_point_v2
    ,COALESCE(traffic_type,'Undefined') as traffic_type
    ,COALESCE(sub_product_type,'others') as sub_product_type
    ,COALESCE(product_type,'others') as product_type
    ,COALESCE(main_product_type,'Others') as main_product_type
    ,raw_paid_credit_revenue_usd_1d + raw_display_ads_revenue_usd_1d + raw_others_free_credit_revenue_usd_1d + free_credit_deduction_amt_usd_1d as raw_gross_ads_revenue_usd_1d
    ,paid_credit_revenue_usd_1d + display_ads_revenue_usd_1d + others_free_credit_revenue_usd_1d + paid_credit_expired_amt_usd_1d + others_free_credit_expired_amt_usd_1d + free_credit_deduction_amt_usd_1d as gross_ads_revenue_usd_1d
    ,paid_credit_revenue_usd_1d + display_ads_revenue_usd_1d + others_free_credit_revenue_usd_1d + paid_credit_expired_amt_usd_1d + others_free_credit_expired_amt_usd_1d - tax_paid_on_free_credit_revenue_usd_1d as net_ads_revenue_usd_1d
    
    ,paid_credit_revenue_usd_1d
    ,raw_paid_credit_revenue_usd_1d
    ,others_free_credit_revenue_usd_1d
    ,raw_others_free_credit_revenue_usd_1d
    ,tax_paid_on_free_credit_revenue_usd_1d
    ,free_credit_deduction_amt_usd_1d
    ,free_credit_deduction_amt_usd_1d + tax_paid_on_free_credit_revenue_usd_1d as free_ads_revenue_amt_usd_1d
    ,sip_free_credit_revenue_usd_1d
    ,scs_free_credit_revenue_usd_1d
    ,lovito_free_credit_revenue_usd_1d
    ,gov_free_credit_revenue_usd_1d

    ,paid_credit_expired_amt_usd_1d
    ,others_free_credit_expired_amt_usd_1d
    ,raw_display_ads_revenue_usd_1d
    ,display_ads_revenue_usd_1d
from base a 
left join sub_entrance_mapping b on a.entrance = b.entrance and a.sub_entrance = b.sub_entrance
left join entrance_mapping c on a.entrance = c.entrance
left join entrance_mapping_v2 d on a.entrance = d.entrance
left join product_type_mapping e on a.pricing_type = e.pricing_type and a.placement = e.placement
;