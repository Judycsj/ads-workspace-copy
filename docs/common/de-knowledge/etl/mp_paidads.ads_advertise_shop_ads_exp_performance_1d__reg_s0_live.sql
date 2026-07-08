-- task_code: data_paidadsmart.studio_6557648  asset_id: 6557648
--drop table ads_advertise_shop_ads_exp_performance_1d__reg_s0_live;
CREATE EXTERNAL TABLE if not exists ads_advertise_shop_ads_exp_performance_1d__reg_s0_live (
  exp_id	string	,
  placement	int	,
  pricing_type	int	,
  platform	string	,
  entrance	int	,
  `location`	int	,

  add_to_cart_cnt	bigint	,
  click_cnt	bigint	,
  raw_click_cnt	bigint	,
  impression_cnt	bigint	,

  direct_order_cnt	bigint	,
  direct_gmv	decimal(25, 10)	,
  direct_gmv_usd	decimal(25, 10)	,
  direct_item_sold_cnt	bigint	,
  broad_order_cnt	bigint	,
  broad_gmv	decimal(25, 10)	,
  broad_gmv_usd	decimal(25, 10)	,
  broad_item_sold_cnt	bigint	,
  checkout_cnt	bigint	,

  revenue	decimal(25, 10)	,
  revenue_usd	decimal(25, 10)	,
  rev_free_credit_with_expiry	decimal(25, 10)	,
  rev_free_credit_without_expiry	decimal(25, 10)	,
  rev_paid_credit_with_expiry	decimal(25, 10)	,
  rev_paid_credit_without_expiry	decimal(25, 10)	,

  shop_relevant_impr_cnt	bigint	,
  shop_somewhat_impr_cnt	bigint	,
  shop_irrelevant_impr_cnt	bigint ,
  shop_non_popular_keyword_relevant_impr_cnt bigint,
  shop_non_popular_keyword_somewhat_impr_cnt bigint,
  shop_non_popular_keyword_irrelevant_impr_cnt bigint
  )
COMMENT 'ads_advertise_shop_ads_exp_performance_1d__reg_s0_live'
PARTITIONED BY (
  `tz_type` string,
  `grass_region` string,
  `grass_date` date)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  '${HIVE_PATH}/ads_advertise_shop_ads_exp_performance_1d__reg_s0_live';


-- Shop Ads Exp
create or replace temporary view shop_ads_exp_base_performance
as 

select entrance, placement, platform, pricing_type, location, exp_id,shop_recall_type,
  
    sum(add_to_cart_cnt) as add_to_cart_cnt
    ,sum(raw_click_cnt) as raw_click_cnt
    ,sum(click_cnt) as click_cnt
    ,sum(impression_cnt) as impression_cnt

    ,sum(order_cnt) as direct_order_cnt
    ,sum(ads_order_gmv_local) as direct_order_gmv_local
    ,sum(ads_order_gmv_usd) as direct_order_gmv_usd
    ,sum(ads_item_sold_cnt) as direct_item_sold_cnt
    ,sum(broad_order_cnt) as broad_order_cnt
    ,sum(broad_gmv_amt_local) as broad_order_gmv_local
    ,sum(broad_gmv_amt_usd) as broad_order_gmv_usd
    ,sum(broad_item_cnt) as broad_item_sold_cnt
    ,sum(checkout_cnt) as checkout_cnt

    ,sum(expenditure_amt_local) as revenue
    ,sum(expenditure_amt_usd) as revenue_usd
    ,sum(expense_free_credit_with_expiry) as expense_free_credit_with_expiry
    ,sum(expense_free_credit_without_expiry) as expense_free_credit_without_expiry
    ,sum(expense_paid_credit_with_expiry) as expense_paid_credit_with_expiry
    ,sum(expense_paid_credit_without_expiry) as expense_paid_credit_without_expiry
    ,sum(if(pricing_type in (1,2), expenditure_amt_usd ,broad_gmv_amt_usd*coalesce(target_cir,0))) as broad_advv
    ,sum(if(pricing_type in (1,2), expenditure_amt_usd ,ads_order_gmv_usd*coalesce(target_cir,0))) as direct_advv
from
(
  select *, EXPLODE(filter(split(ab_signs[1], '\\|'), x->length(x)>0)) as exp_id
  from(
    SELECT case when ab_sign like '%new_ab_sign%' then split(ab_sign, '\\|new_ab_sign\\|') else split(ab_sign, '\\|m\\|') end as ab_signs, 
    
      entrance, placement, platform, pricing_type, location,shop_recall_type,target_cir,
    
      add_to_cart_cnt,raw_click_cnt,click_cnt,impression_cnt,

      order_cnt,ads_order_gmv_local,ads_order_gmv_usd, ads_item_sold_cnt,
      broad_order_cnt, broad_gmv_amt_local, broad_gmv_amt_usd,broad_item_cnt,checkout_cnt,

      expenditure_amt_local,expenditure_amt_usd,
      expense_free_credit_with_expiry,expense_free_credit_without_expiry,
      expense_paid_credit_with_expiry,expense_paid_credit_without_expiry
      
    FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
    WHERE placement in (3,2003,2030,20)
    and grass_date = '${grass_date}'
    and grass_region=upper('${region}') and ab_sign is not null

  )
  where size(ab_signs)>1
)
group by entrance, placement, platform, pricing_type, location, exp_id,shop_recall_type;


create or replace temporary view shop_ads_trace_info
as
select request_id,
  ab_sign,
  session_id,
  e.ads_id,
  e.shop_id,
  user_id,
  explode(e.top_items) as item,
  query.keyword as keyword
  from (
      select
          request_id
          ,session_id
          ,user_id
          ,explode (ads) as e
          ,ab_sign
      from mp_paidads.ods_log_trace_shop_ads_hi__reg_s0_live
      where grass_region=upper('${region}')
        and   grass_date >= DATE('${grass_date}')
        and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
        and   timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
        and   timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
          and ads is not null
  ) as a
  inner join 
  (
    select ads_request_id, first(query) as query
    from mkplpaidads_data.dwd_advertise_tracking_shop_hi__reg_s0_live
    where grass_region=upper('${region}')
      and   grass_date >= DATE('${grass_date}')
      and   grass_date <= DATE_ADD(DATE('${grass_date}'), 1)
      and   timestamp < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))
      and   timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}'), 'Asia/Singapore'))
      and   ads_placement in (3,2003,2030,20)
    group by ads_request_id
  ) as b 
  on a.request_id = b.ads_request_id
;

create or replace temporary view shop_ads_request_rele_score
as

select EXPLODE(filter(split(ab_signs[1], '\\|'), x->length(x)>0)) as exp_id,*
  ,upper('${region}') as grass_region
from (
  select
      --from shop_trace_log
      case when temp.ab_sign like '%new_ab_sign%' then split(temp.ab_sign, '\\|new_ab_sign\\|') else split(temp.ab_sign, '\\|m\\|') end as ab_signs,
      b.impression_cnt ,
      temp.request_id,
      cast(get_json_object(temp.item.ext_info, '$.final_relevance_score') as double) as final_relevance_score,
      cast(get_json_object(temp.item.ext_info, '$.rank') as int) as item_rank,
      b.pricing_type,
      b.placement,
      b.entrance,
      b.location,
      b.platform,
      b.shop_recall_type
  from shop_ads_trace_info as temp
  inner join
  mp_paidads.dwd_advertise_performance_di__reg_s0_live as b 
  on
    (
          temp.request_id = b.request_id and
          temp.ads_id = b.ads_id
      )
  where get_json_object(temp.item.ext_info, '$.rank') <= 3
  and b.impression_cnt > 0
  and b.grass_date = '${grass_date}'
  and b.grass_region=upper('${region}')
  and b.placement in  (3,2003,2030,20)
  and temp.keyword in (
      select keyword from mkplpaidads_brand_ads.shopads_popular_keyword 
      where dt = '${grass_date}'
            and country=upper('${region}')
  )
)
;


create or replace temporary view shop_ads_exp_revelance
as
select 
    entrance, placement, platform, pricing_type, location, exp_id,shop_recall_type,
    sum(if(relevant >= 1, 1, 0)) as shop_relevant_impr_cnt,
    sum(if(relevant = 0 and (somewhat=2 or somewhat=3), 1, 0))  as shop_somewhat_impr_cnt,
    sum(if(relevant  = 0 and somewhat<=1, 1, 0)) as shop_irrelevant_impr_cnt
from (
  select
      entrance, placement, platform, pricing_type, location, exp_id,request_id,shop_recall_type,
      sum(if(final_relevance_score < b.min, 1, 0)) as irre_count,
      sum(if(final_relevance_score >= b.min and final_relevance_score < b.max, 1, 0)) as somewhat,
      sum(if(final_relevance_score >= b.max, 1, 0)) as  relevant
  from shop_ads_request_rele_score a
  inner join mp_paidads.dim_shop_ads_relevance_threshold__reg_s0_live b
  on a.grass_region = b.grass_region
  where impression_cnt > 0
  and item_rank <= 3
  group by entrance, placement, platform, pricing_type, location, exp_id,request_id,shop_recall_type
) where (irre_count + somewhat + relevant) == 3
group by entrance, placement, platform, pricing_type, location, exp_id,shop_recall_type
;


create or replace temporary view shop_ads_request_rele_score_non_popular_keyword
as

select EXPLODE(filter(split(ab_signs[1], '\\|'), x->length(x)>0)) as exp_id,*
  ,upper('${region}') as grass_region
from (
  select
      --from shop_trace_log
      case when temp.ab_sign like '%new_ab_sign%' then split(temp.ab_sign, '\\|new_ab_sign\\|') else split(temp.ab_sign, '\\|m\\|') end as ab_signs,
      b.impression_cnt ,
      temp.request_id,
      cast(get_json_object(temp.item.ext_info, '$.final_relevance_score') as double) as final_relevance_score,
      cast(get_json_object(temp.item.ext_info, '$.rank') as int) as item_rank,
      b.pricing_type,
      b.placement,
      b.entrance,
      b.location,
      b.platform,
      b.shop_recall_type
  from shop_ads_trace_info as temp
  inner join
  mp_paidads.dwd_advertise_performance_di__reg_s0_live as b 
  on
    (
          temp.request_id = b.request_id and
          temp.ads_id = b.ads_id
      )
  where get_json_object(temp.item.ext_info, '$.rank') <= 3
  and b.impression_cnt > 0
  and b.grass_date = '${grass_date}'
  and b.grass_region=upper('${region}')
  and b.placement in  (3,2003,2030,20)
  and temp.keyword not in (
      select keyword from mkplpaidads_brand_ads.shopads_popular_keyword 
      where dt = '${grass_date}'
            and country=upper('${region}')
  )
)
;


create or replace temporary view shop_ads_exp_revelance_non_popular_keyword
as
select 
    entrance, placement, platform, pricing_type, location, exp_id,shop_recall_type,
    sum(if(relevant >= 1, 1, 0)) as shop_non_popular_keyword_relevant_impr_cnt,
    sum(if(relevant = 0 and (somewhat=2 or somewhat=3), 1, 0))  as shop_non_popular_keyword_somewhat_impr_cnt,
    sum(if(relevant  = 0 and somewhat<=1, 1, 0)) as shop_non_popular_keyword_irrelevant_impr_cnt
from (
  select
      entrance, placement, platform, pricing_type, location, exp_id,request_id,shop_recall_type,
      sum(if(final_relevance_score < b.min, 1, 0)) as irre_count,
      sum(if(final_relevance_score >= b.min and final_relevance_score < b.max, 1, 0)) as somewhat,
      sum(if(final_relevance_score >= b.max, 1, 0)) as  relevant
  from shop_ads_request_rele_score_non_popular_keyword a
  inner join mp_paidads.dim_shop_ads_relevance_threshold__reg_s0_live b
  on a.grass_region = b.grass_region
  where impression_cnt > 0
  and item_rank <= 3
  group by entrance, placement, platform, pricing_type, location, exp_id,request_id,shop_recall_type
) where (irre_count + somewhat + relevant) == 3
group by entrance, placement, platform, pricing_type, location, exp_id,shop_recall_type
;






insert overwrite table ads_advertise_shop_ads_exp_performance_1d__reg_s0_live 
partition (tz_type='local', grass_region, grass_date)
select  /*+ REPARTITION(10) */
  a.exp_id, a.placement,a.pricing_type,  a.platform, a.entrance, a.location, 
  
    add_to_cart_cnt,click_cnt,raw_click_cnt,impression_cnt

    ,direct_order_cnt,direct_order_gmv_local,direct_order_gmv_usd,direct_item_sold_cnt
    ,broad_order_cnt,broad_order_gmv_local, broad_order_gmv_usd,broad_item_sold_cnt,checkout_cnt

    ,revenue,revenue_usd,expense_free_credit_with_expiry,expense_free_credit_without_expiry
    ,expense_paid_credit_with_expiry,expense_paid_credit_without_expiry,

    shop_relevant_impr_cnt, shop_somewhat_impr_cnt, shop_irrelevant_impr_cnt,
    shop_non_popular_keyword_relevant_impr_cnt,shop_non_popular_keyword_somewhat_impr_cnt,shop_non_popular_keyword_irrelevant_impr_cnt,
    a.shop_recall_type,broad_advv,direct_advv,
    upper('${region}') as grass_region,
    date('${grass_date}')  as grass_date
from 
shop_ads_exp_base_performance a
left join
shop_ads_exp_revelance b
on coalesce(a.entrance, -1) = coalesce(b.entrance, -1)
and coalesce(a.placement, -1) = coalesce(b.placement, -1)
and coalesce(a.platform, -1) = coalesce(b.platform, -1)
and coalesce(a.pricing_type, -1) = coalesce(b.pricing_type, -1)
and coalesce(a.location, -1) = coalesce(b.location, -1)
and a.exp_id = b.exp_id
and coalesce(a.shop_recall_type,-1) = coalesce(b.shop_recall_type,-1)
left join
shop_ads_exp_revelance_non_popular_keyword c
on coalesce(a.entrance, -1) = coalesce(c.entrance, -1)
and coalesce(a.placement, -1) = coalesce(c.placement, -1)
and coalesce(a.platform, -1) = coalesce(c.platform, -1)
and coalesce(a.pricing_type, -1) = coalesce(c.pricing_type, -1)
and coalesce(a.location, -1) = coalesce(c.location, -1)
and a.exp_id = c.exp_id
and coalesce(a.shop_recall_type,-1) = coalesce(c.shop_recall_type,-1)
;