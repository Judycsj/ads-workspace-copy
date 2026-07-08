-- task_code: data_paidadsmart.studio_6557484  asset_id: 6557484
--drop table dws_advertise_ads_exp_performance_1d__reg_s0_live;
CREATE EXTERNAL TABLE if not exists dws_advertise_ads_exp_performance_1d__reg_s0_live (
  `user_id` bigint COMMENT 'user_id',
  `entrance` int COMMENT 'entrance',
  `exp_id` string COMMENT 'exp_id',
  `placement` int COMMENT 'placement',
  `platform` int COMMENT 'platform',
  `outlier_label` string COMMENT 'outlier_label',

  `add_to_cart` bigint COMMENT 'add_to_cart',
  `ads_click_cnt` bigint COMMENT 'ads_click_cnt',
  `ads_gmv_usd` decimal(25, 10) COMMENT 'ads_gmv_usd',
  `ads_order_cnt` bigint COMMENT 'ads_order_cnt',

  `ads_revenue_usd` decimal(25, 10) COMMENT 'ads_revenue_usd',
  `broad_gmv_usd` decimal(25, 10) COMMENT 'broad_gmv_usd',
  `broad_order_cnt` bigint COMMENT 'broad_order_cnt',
  `impressions` bigint COMMENT 'impressions',
  `raw_clicks` bigint COMMENT 'raw_clicks',
  `shop_ads_outlier_label` string COMMENT 'shop_ads_outlier_label',
  `game_ads_outlier_label` string COMMENT 'game_ads_outlier_label',
  `search_ads_outlier_label` string COMMENT 'search_ads_outlier_label',
  `live_ads_outlier_label` string COMMENT 'live_ads_outlier_label',

  video_play_3s_cnt		bigint	comment 'no. of the video was played for more than 3s',
  video_play_5s_cnt		bigint	comment 'no. of the video was played for more than 5s',
  video_view					bigint	comment 'video_view',
  view_duration				bigint	comment	'view_duration',
  video_play_complete	bigint	comment 'no. of completed video views',
  deduct_impression	bigint	comment 'deduct_impression',
  product_click					bigint	comment 'no. of product clicks',
  deduplicated_click_cnt_1d bigint comment 'deduplicated_click'
  )
COMMENT 'paid_ads_dws_advertise_ads_exp_performance_1d'
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
  '${HIVE_PATH}/dws_advertise_ads_exp_performance_1d';



--https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=%5BTD%5D+Cross+traffic+Abtest
-- discover and video
cache table discovery_ads_ab as
SELECT split(ab_sign, '\\|p\\|') as ab_signs,user_id, entrance, placement, platform, add_to_cart_cnt,
          click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
          broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, upper('${region}') as grass_region
          ,video_play_3s_cnt
          ,video_play_5s_cnt
          ,video_view
          ,view_duration
          ,video_play_complete
          ,deduct_impression
          ,product_click
          ,deduplicated_click
      FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
      WHERE entrance not in (1, 5, 6, 23, 24, 27, 28) 
      and placement not in (3,2003)
      and grass_date = '${grass_date}'
      and grass_region=upper('${region}') and ab_sign is not null 
;

create or replace temporary view ads_exp_base_info
as
--Search Ads and Display Ads
select user_id, entrance, placement, platform, add_to_cart_cnt,
    click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
    broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, grass_region,
    EXPLODE(filter(split(replace(replace(replace(ab_signs[1], 'o', ''), 'm', ''), 'p', ''), '\\|'), x->length(x)>0)) as real_ab,
    video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
    ,deduplicated_click
from(
  SELECT split(ab_sign, '\\|r\\|') as ab_signs, user_id, entrance, placement, platform, add_to_cart_cnt,
      click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
      broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, upper('${region}') as grass_region,
      video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
      ,deduplicated_click
  FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
  WHERE entrance in (1, 5, 6, 23, 24, 27, 28) 
  and tz_type = 'local'
  and placement not in (3,2003)
  and grass_date = '${grass_date}'
  and grass_region=upper('${region}') and ab_sign is not null
)
where size(ab_signs)>1 

union all

--Discovery Ads and video ads
select user_id, entrance, placement, platform, add_to_cart_cnt,
    click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
    broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, grass_region, concat_ws('@', service_indicator, single_ab) as real_ab ,
    video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
    ,deduplicated_click
from(
  select split_ab[0] as service_indicator , EXPLODE(split(split_ab[1], ',')) as single_ab, 
    user_id, entrance, placement, platform, add_to_cart_cnt,
      click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
      broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, grass_region,
      video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
      ,deduplicated_click
  from(
    select split(ab_signs, '@') as split_ab,user_id, entrance, placement, platform, add_to_cart_cnt,
        click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd,
        video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click,
        broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, deduplicated_click, grass_region
    from(
      SELECT EXPLODE(filter(split(ab_signs[0], '#'), x->instr(x, '@')>0)) as ab_signs,user_id, entrance, placement, platform, add_to_cart_cnt,
          click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
          broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, 
          video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
          ,deduplicated_click,upper('${region}') as grass_region
      FROM discovery_ads_ab
    )
  )
)

union all 
--Discovery Ads Cross traffic Abtest
SELECT user_id, entrance, placement, platform, add_to_cart_cnt,
       click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
       broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, upper('${region}') as grass_region, 
       EXPLODE(filter(split(split(ab_signs[1],'\\|bkt\\|')[0], '\\|'),x->length(x)>0))  as real_ab,
       video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
       ,deduplicated_click
from discovery_ads_ab
where size(ab_signs) > 1

union all 

-- Shop Ads
select user_id, entrance, placement, platform, add_to_cart_cnt,
    click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
    broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, grass_region,
    EXPLODE(filter(split(ab_signs[1], '\\|'), x->length(x)>0)) as real_ab,
    video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
    ,deduplicated_click
from(
  SELECT split(ab_sign, '\\|m\\|') as ab_signs, user_id, entrance, placement, platform, add_to_cart_cnt,
      click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
      broad_order_cnt, broad_gmv_amt_local, impression_cnt, raw_click_cnt, upper('${region}') as grass_region ,
      video_play_3s_cnt,video_play_5s_cnt,video_view,view_duration,video_play_complete,deduct_impression,product_click
      ,deduplicated_click
  FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
  WHERE placement in (3,2003)
  and grass_date = '${grass_date}'
  and grass_region=upper('${region}') and ab_sign is not null
)
where size(ab_signs)>1 

;


create or replace temporary view platfrom_base_info
as
select user_id,
      case when(bucket_id<=1) then 'top_05_percent'
        when(bucket_id<=2) then 'top_1_percent'
      else 'bottom_99_percent' end as outlier_label,gmv_usd
from (
  select ntile(200) over (order by gmv_usd desc) as bucket_id,user_id,gmv_usd
  from(
    select  buyer_id as user_id,sum(gmv_usd) as gmv_usd
    from mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
    where tz_type = 'local'
    and grass_date = date('${grass_date}') 
    and grass_region = upper('${region}')
    and is_placed=1
    and is_bi_excluded = 0 
    group by buyer_id
  )
);


create or replace temporary view shop_ads_rank_info as
select user_id,
      case when(bucket_id<=1) then 'top_05_percent'
        when(bucket_id<=2) then 'top_1_percent'
      else 'bottom_99_percent' end as shop_ads_outlier_label
from (
  select ntile(200) over (order by gmv desc) as bucket_id,user_id
  from(
      SELECT user_id, sum(broad_gmv_amt_local) as gmv
      FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
      WHERE placement in (3,2003)
      and grass_date = '${grass_date}'
      and grass_region=upper('${region}')
      group by user_id
      having sum(broad_gmv_amt_local) > 0
  )
);

create or replace temporary view game_ads_rank_info as
select user_id,
      case when(bucket_id<=1) then 'top_05_percent'
        when(bucket_id<=2) then 'top_1_percent'
      else 'bottom_99_percent' end as game_ads_outlier_label
from (
  select ntile(200) over (order by gmv desc) as bucket_id,user_id
  from(
      SELECT user_id, sum(broad_gmv_amt_local) as gmv
      FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
      WHERE placement in (2030)
      and grass_date = '${grass_date}'
      and grass_region=upper('${region}')
      group by user_id
      having sum(broad_gmv_amt_local) > 0
  )
);

create or replace temporary view search_ads_rank_info as
select user_id,
      case when(bucket_id<=1) then 'top_05_percent'
        when(bucket_id<=2) then 'top_1_percent'
      else 'bottom_99_percent' end as search_ads_outlier_label
from (
  select ntile(200) over (order by gmv desc) as bucket_id,user_id
  from(
      SELECT user_id, sum(broad_gmv_amt_local) as gmv
      FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
      WHERE placement in (0,4,1000,1200)
      and grass_date = '${grass_date}'
      and grass_region=upper('${region}')
      group by user_id
      having sum(broad_gmv_amt_local) > 0
  )
);

create or replace temporary view live_ads_rank_info as
select user_id,
      case when(bucket_id<=1) then 'top_05_percent'
        when(bucket_id<=2) then 'top_1_percent'
      else 'bottom_99_percent' end as live_ads_outlier_label
from (
  select ntile(200) over (order by gmv desc) as bucket_id,user_id
  from(
      SELECT user_id, sum(broad_gmv_amt_local) as gmv
      FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live 
      WHERE placement in (3327, 3328, 3337, 3338, 3339, 3342)
      and grass_date = '${grass_date}'
      and grass_region=upper('${region}')
      group by user_id
      having sum(broad_gmv_amt_local) > 0
  )
);

create or replace temporary view ads_exp_info
as
select ads_base.user_id, entrance, exp_id, placement, platform, outlier_label,
add_to_cart_cnt,ads_click_cnt,ads_gmv_usd,ads_order_cnt,ads_revenue_usd,
broad_gmv_local / exchange_rate as broad_gmv_usd,broad_order_cnt,
impression_cnt,raw_click_cnt,
shop_ads_outlier_label,game_ads_outlier_label,search_ads_outlier_label,live_ads_outlier_label
,ads_base.video_play_3s_cnt		   
,ads_base.video_play_5s_cnt		 
,ads_base.video_view					 
,ads_base.view_duration				 
,ads_base.video_play_complete	 
,ads_base.deduct_impression
,ads_base.product_click			
,ads_base.deduplicated_click_cnt_1d	
from (
  select user_id, entrance, real_ab as exp_id, placement, platform, 
  COALESCE(outlier_label, 'bottom_99_percent') as outlier_label, grass_region,
  sum(add_to_cart_cnt) as add_to_cart_cnt,
  sum(click_cnt) as ads_click_cnt,
  sum(ads_order_gmv_usd) as ads_gmv_usd,
  sum(order_cnt) as ads_order_cnt,
  sum(expenditure_amt_usd) as ads_revenue_usd,
  sum(broad_gmv_amt_local) as broad_gmv_local,
  sum(broad_order_cnt) as broad_order_cnt,
  sum(impression_cnt) as impression_cnt,
  sum(raw_click_cnt) as raw_click_cnt,
  sum(video_play_3s_cnt) as video_play_3s_cnt,
  sum(video_play_5s_cnt) as video_play_5s_cnt,
  sum(video_view) as video_view,
  sum(view_duration) as view_duration,
  sum(video_play_complete) as video_play_complete,
  sum(deduct_impression) as deduct_impression,
  sum(product_click) as product_click,
  sum(deduplicated_click) as deduplicated_click_cnt_1d
  from (
    select a.user_id as user_id, entrance, placement, platform, add_to_cart_cnt,
        click_cnt, ads_order_gmv_usd,order_cnt, expenditure_amt_usd, 
        broad_order_cnt, broad_gmv_amt_local, impression_cnt, 
        raw_click_cnt, grass_region, real_ab, outlier_label
        ,video_play_3s_cnt
        ,video_play_5s_cnt
        ,video_view
        ,view_duration
        ,video_play_complete
        ,deduct_impression
        ,product_click
        ,deduplicated_click
    from 
    ads_exp_base_info a
    left join 
    platfrom_base_info b
    on a.user_id = b.user_id
  ) group by user_id, entrance, placement, platform, real_ab, outlier_label,grass_region
) ads_base
LEFT OUTER JOIN 
(
    select * from mp_order.dim_exchange_rate__reg_s0_live
    where grass_date =  date('${grass_date}') 
    and grass_region=upper('${region}')
) exchange_rate
ON ads_base.grass_region = exchange_rate.grass_region
LEFT OUTER JOIN shop_ads_rank_info
ON ads_base.user_id = shop_ads_rank_info.user_id
LEFT OUTER JOIN game_ads_rank_info
ON ads_base.user_id = game_ads_rank_info.user_id
LEFT OUTER JOIN search_ads_rank_info
ON ads_base.user_id = search_ads_rank_info.user_id
LEFT OUTER JOIN live_ads_rank_info
ON ads_base.user_id = live_ads_rank_info.user_id
;


insert overwrite table dws_advertise_ads_exp_performance_1d__reg_s0_live 
partition (tz_type='local', grass_region, grass_date)
select
  user_id
  ,entrance
  ,exp_id
  ,placement
  ,platform
  ,outlier_label

  ,add_to_cart_cnt
  ,ads_click_cnt
  ,ads_gmv_usd
  ,ads_order_cnt

  ,ads_revenue_usd
  ,broad_gmv_usd
  ,broad_order_cnt
  ,impression_cnt
  ,raw_click_cnt
  ,shop_ads_outlier_label
  ,game_ads_outlier_label
  ,search_ads_outlier_label
  ,live_ads_outlier_label

  ,video_play_3s_cnt
  ,video_play_5s_cnt
  ,video_view
  ,view_duration
  ,video_play_complete
  ,deduct_impression
  ,product_click
  ,deduplicated_click_cnt_1d
  ,upper('${region}') as grass_region
  ,date('${grass_date}')  as grass_date
from ads_exp_info
;