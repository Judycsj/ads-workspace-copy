-- asset_id: 7038005  fragment: 1/2
set hoodie.parquet.max.file.size = 536870912;
set hoodie.parquet.small.file.limit = 536870912;
set hoodie.bucket.index.num.buckets = 5000;
set hoodie.bucket.index.max.num.buckets = 7000;
insert overwrite table dwd_ads_request_performance_di__reg_s0_live partition (grass_region, grass_date)
    select
        t1.ads_id
        ,t1.campaign_id
        ,t1.item_id
        ,t1.user_id
        ,t1.ads_request_id as request_id
        ,t1.shop_id
        ,cast(t1.ads_entrance as bigint) as entrance
        ,cast(t1.pricing_type as int) as pricing_type
        ,cast(t1.ads_placement as bigint) as placement
        ,cast(coalesce(t1.click_cnt, 0) as bigint) as click_cnt
        ,cast(coalesce(t1.impression_cnt, 0) as bigint) as impression_cnt
        ,cast(0 as bigint) as deduct_click_cnt
        ,cast(0 as bigint) as deduct_impression_cnt
        ,cast(0 as double) as expenditure_amt_local
        ,cast(0 as double) as expenditure_amt_usd
        ,cast(0 as bigint) as broad_order_cnt
        ,cast(0 as bigint) as broad_item_cnt
        ,cast(0 as double) as broad_gmv_amt_local
        ,cast(0 as double) as broad_gmv_amt_usd
        ,cast(0 as bigint) as daily_order_cnt
        ,cast(0 as bigint) as daily_item_cnt
        ,cast(0 as double) as daily_gmv_amt_local
        ,cast(0 as double) as daily_gmv_amt_usd
        ,cast(0 as bigint) as direct_order_cnt
        ,cast(0 as bigint) as direct_item_cnt
        ,cast(0 as double) as direct_gmv_amt_local
        ,cast(0 as double) as direct_gmv_amt_usd
        ,cast(t1.pCTR as double) as pCTR
        ,cast(t1.pCR as double) as pCR
        ,cast(t1.direct_pcr as double) as direct_pcr
        ,cast(t1.broad_pcr as double) as broad_pcr
        ,cast(t1.rank_score as double) as rank_score
        ,cast(t1.rank as bigint) as rank
        ,cast(t1.item_price as double) as item_price
        ,cast(t1.sold_cnt_per_order as bigint) as sold_cnt_per_order
        ,cast(t1.target_cir as double) as target_cir
        ,cast(t1.bidprice as double) as bidprice
        ,cast(t1.deduction_price as double) as deduction_price
        ,cast(t1.pcr_1d as double) as pcr_1d
        ,cast(t1.pcr_delay as double) as pcr_delay
        ,cast(t1.pcr_shop as double) as pcr_shop
        ,t1.sub_entrance
        ,cast(0 as bigint) as broad_order_1d
        ,cast(t1.dedup_impression_cnt as bigint) as dedup_impression_cnt
        ,cast(t1.dedup_click_cnt as bigint) as dedup_click_cnt
        ,cast(0 as bigint) as acct_cnt
        ,cast(t1.organic_location as bigint) as organic_location
        ,cast(t1.new_product_boost_coef as double) as new_product_boost_coef
        ,cast(t1.new_product_boost_stage as bigint) as new_product_boost_stage
        ,cast(t1.new_product_boost_tier as bigint) as new_product_boost_tier
        ,cast(t1.pctr_v as double) as pctr_v
        ,cast(t1.pcr_v as double) as pcr_v
        ,cast(t1.broad_pcr_v as double) as broad_pcr_v
        ,cast(t1.bid_price_0 / 100000.0 as double) as bid_price_0
        ,cast(t1.bid_voucher_id as bigint) as bid_voucher_id
        ,cast(t1.voucher_deduction_price / 100000.0 as double) as voucher_deduction_price
        ,cast(t1.deduction_price_0 / 100000.0 as double) as deduction_price_0
        ,cast(t1.is_auto_claimed_just_now as int) as is_auto_claimed_just_now
        ,t1.item_voucher
        ,cast(t1.display_ads_voucher_label as int) as display_ads_voucher_label
        ,cast(0 as bigint) as pdp_view
        ,cast(0 as bigint) as ads_voucher_auto_claimed
        ,cast(0 as bigint) as paid_order_cnt
        ,cast(0 as bigint) as paid_order_cnt_24h
        ,t1.ab_sign
        ,cast(0 as double) as paid_order_gmv_local
        ,cast(0 as double) as paid_order_gmv_usd
        ,cast(0 as double) as paid_order_gmv_local_24h
        ,cast(0 as double) as paid_order_gmv_usd_24h
        ,t1.algo_json_data
        ,cast(0 as bigint) as broad_order_cnt_24h
        ,cast(0 as double) as broad_order_gmv_usd_24h
        ,cast(0 as double) as broad_order_gmv_local_24h
        ,cast(0 as bigint) as direct_order_cnt_24h
        ,cast(0 as double) as direct_order_gmv_usd_24h
        ,cast(0 as double) as direct_order_gmv_local_24h
        ,cast(0 as bigint) as broad_order_cnt_4d
        ,cast(0 as double) as broad_order_gmv_usd_4d
        ,cast(0 as double) as broad_order_gmv_local_4d
        ,cast(0 as bigint) as direct_order_cnt_4d
        ,cast(0 as double) as direct_order_gmv_usd_4d
        ,cast(0 as double) as direct_order_gmv_local_4d
        ,cast(0 as bigint) as cps_dedup_click
        ,cast(0 as bigint) as deduct_order_cnt
        ,t1.first_impression_timestamp
        ,t1.first_click_timestamp
        ,t1.bid_rerank_trace
        ,t1.pid_coef
        ,t1.uni_pcr_model_name
        ,cast(t1.item_price_shop as double) as item_price_shop
        ,cast(t1.avg_sold_cnt_shop as double) as avg_sold_cnt_shop
        ,cast(t1.avg_sold_cnt_item as double) as avg_sold_cnt_item
        ,cast(null as array<bigint>) as plan_bucket_list
        ,cast(0 as bigint) as paid_broad_order_cnt
        ,cast(0 as double) as paid_broad_order_gmv_local
        ,cast(0 as double) as paid_broad_order_gmv_usd
        ,t2.level1_global_be_category
        ,t2.level1_global_be_category_id
        ,t2.level2_global_be_category
        ,t2.level2_global_be_category_id
        ,cast(0 as bigint) as deduplicated_click
        ,cast(0 as bigint) as broad_order_cnt_1h
        ,cast(0 as double) as broad_order_gmv_usd_1h
        ,cast(0 as double) as broad_order_gmv_local_1h
        ,cast(0 as bigint) as direct_order_cnt_1h
        ,cast(0 as double) as direct_order_gmv_usd_1h
        ,cast(0 as double) as direct_order_gmv_local_1h
        ,null as entrance_group
        ,null as is_ocpm
        ,null as page_type
        ,null as target_type
        ,null as query
        ,null as keyword
        ,null as raw_request_id
        ,null as video_id
        ,null as deduct_unique_id
        ,null as deduction_reason
        ,null as image_id
        ,cast(0 as bigint) as page_view
        ,t1.grass_region
        ,t1.grass_date
    from
        (
            select
                ads_id
                ,campaign_id
                ,item_id
                ,user_id
                ,ads_request_id
                ,shop_id
                ,ads_entrance
                ,pricing_type
                ,ads_placement
                ,sum(
                    case
                        when operation = 2 then 1
                        else 0
                    end
                ) as click_cnt
                ,sum(
                    case
                        when operation = 1 then 1
                        else 0
                    end
                ) as impression_cnt
                ,max(cast(get_json_object(item_json_data, '$.pCTR') as double)) as pCTR
                ,max(cast(get_json_object(item_json_data, '$.pCR') as double)) as pCR
                ,max(
                    cast(
                        get_json_object(
                            get_json_object(item_json_data, '$.extra_json')
                            ,'$.direct_pcr'
                        ) as double
                    )
                ) as direct_pcr
                ,max(
                    cast(get_json_object(item_json_data, '$.broad_pcr') as double)
                ) as broad_pcr
                ,max(
                    cast(get_json_object(item_json_data, '$.rank_score') as double)
                ) as rank_score
                ,max(cast(get_json_object(item_json_data, '$.rank') as bigint)) as rank
                ,max(item_price) as item_price
                ,max(sold_cnt_per_order) as sold_cnt_per_order
                ,max(target_cir) as target_cir
                ,max(internal.deduction_info.bidprice) as bidprice
                ,max(internal.deduction_info.deduction_price) as deduction_price
                ,max(cast(get_json_object(item_json_data, '$.pcr_1d') as double)) as pcr_1d
                ,max(
                    cast(get_json_object(item_json_data, '$.pcr_delay') as double)
                ) as pcr_delay
                ,max(
                    cast(get_json_object(item_json_data, '$.pcr_shop') as double)
                ) as pcr_shop
                ,max(sub_entrance) as sub_entrance
                ,sum(
                    case
                        when duplicate_label is null and operation = 1 then 1
                        else 0
                    end
                ) as dedup_impression_cnt
                ,sum(
                    case
                        when duplicate_label is null and operation = 2 then 1
                        else 0
                    end
                ) as dedup_click_cnt
                ,max(organic_location) as organic_location
                ,max(get_json_object (item_json_data, '$.new_product_boost_coef')) as new_product_boost_coef
                ,max(new_product_boost_stage) as new_product_boost_stage
                ,max(get_json_object (
                    get_json_object (item_json_data, '$.extra_json')
                    ,'$.new_product_boost_tier'
                )) as new_product_boost_tier
                ,max(get_json_object(item_json_data, '$.pctr_v')) as pctr_v
                ,max(get_json_object(item_json_data, '$.pcr_v')) as pcr_v
                ,max(get_json_object(item_json_data, '$.broad_pcr_v')) as broad_pcr_v
                ,max(get_json_object(item_json_data, '$.bid_price_0')) as bid_price_0
                ,max(bid_voucher_id) as bid_voucher_id
                ,max(voucher_deduction_price) as voucher_deduction_price
                ,max(get_json_object(item_json_data, '$.deduction_price_0')) as deduction_price_0
                ,max(is_auto_claimed_just_now) as is_auto_claimed_just_now
                ,max(item_voucher) as item_voucher
                ,max(item_voucher.display_ads_voucher_label) as display_ads_voucher_label
                ,max(ab_sign) as ab_sign
                ,max(algo_json_data) as algo_json_data
                ,min(if(operation = 1,timestamp, null)) as first_impression_timestamp
                ,min(if(operation = 2,timestamp, null)) as first_click_timestamp
                ,max(bid_rerank_trace) as bid_rerank_trace
                ,max(cast(get_json_object(item_json_data, '$.pid_coef') as double)) as pid_coef
                ,max(uni_pcr_model_name) as uni_pcr_model_name
                ,max(item_price_shop) as item_price_shop
                ,max(avg_sold_cnt_shop) as avg_sold_cnt_shop
                ,max(avg_sold_cnt_item) as avg_sold_cnt_item
                ,grass_region
                ,case when grass_region in ('${region}') then DATE(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT(grass_date, ' ', lpad(h, 2, 0), ':00:00'), 'UTC+08:00'), 'Asia/Jakarta'))
                    end as grass_date
            from mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live
            where
                grass_region in ('${region}')
                and grass_date >= date('${grass_date}')
                and grass_date <= DATE_ADD(date('${grass_date}'),1)
                and case when grass_region in ('${region}') then DATE(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT(grass_date, ' ', lpad(h, 2, 0), ':00:00'), 'UTC+08:00'), 'Asia/Jakarta'))
                    end = date('${grass_date}')
                and operation in (1, 2, 3)
                and fraud_type = ''
                and ads_id > 0
            group by
                ads_id
                ,campaign_id
                ,item_id
                ,user_id
                ,ads_request_id
                ,shop_id
                ,ads_entrance
                ,pricing_type
                ,ads_placement
                ,grass_region
                ,case when grass_region in ('${region}') then DATE(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(CONCAT(grass_date, ' ', lpad(h, 2, 0), ':00:00'), 'UTC+08:00'), 'Asia/Jakarta'))
                    end
        ) t1
        left join
        (
            select
                grass_region
                ,item_id
                ,level1_global_be_category
                ,level1_global_be_category_id
                ,level2_global_be_category
                ,level2_global_be_category_id
            from mp_item.dim_item__reg_s0_live
            where
                grass_date = date '${grass_date}'
                and grass_region in ('${region}')
        ) t2
        on t1.grass_region = t2.grass_region
        and t1.item_id = t2.item_id
;

-- ===next asset===

-- asset_id: 6615014  fragment: 2/2
set hoodie.schema.on.read.enable=true;
set time zone ${timezone}
;

create or replace temporary view exchange_rate as
select
    grass_region
    ,exchange_rate
from mp_order.dim_exchange_rate__reg_s0_live
where
    grass_region in ('${region}')
    and grass_date = date('${grass_date}')
;

create or replace temporary view source as (
    select
        null as _hoodie_commit_time
        ,null as _hoodie_commit_seqno
        ,null as _hoodie_record_key
        ,null as _hoodie_partition_path
        ,null as _hoodie_file_name
        ,ads_id
        ,campaign_id
        ,item_id
        ,user_id
        ,request_id
        ,shop_id
        ,cast(entrance as bigint) as entrance
        ,cast(pricing_type as int) as pricing_type
        ,cast(placement as bigint) as placement
        ,cast(0 as bigint) as click_cnt
        ,cast(0 as bigint) as impression_cnt
        ,cast(coalesce(deduct_click_cnt, 0) as bigint) as deduct_click_cnt
        ,cast(coalesce(deduct_impression_cnt, 0) as bigint) as deduct_impression_cnt
        ,cast(coalesce(expenditure_amt_local, 0) as double) as expenditure_amt_local
        ,cast(coalesce(expenditure_amt_local / exchange_rate, 0) as double) as expenditure_amt_usd
        ,cast(coalesce(broad_order_cnt, 0) as bigint) as broad_order_cnt
        ,cast(coalesce(broad_item_cnt, 0) as bigint) as broad_item_cnt
        ,cast(coalesce(broad_gmv_amt_local, 0) as double) as broad_gmv_amt_local
        ,cast(coalesce(broad_gmv_amt_local / exchange_rate, 0) as double) as broad_gmv_amt_usd
        ,cast(coalesce(daily_order_cnt, 0) as bigint) as daily_order_cnt
        ,cast(coalesce(daily_item_cnt, 0) as bigint) as daily_item_cnt
        ,cast(coalesce(daily_gmv_amt_local, 0) as double) as daily_gmv_amt_local
        ,cast(coalesce(daily_gmv_amt_local / exchange_rate, 0) as double) as daily_gmv_amt_usd
        ,cast(coalesce(direct_order_cnt, 0) as bigint) as direct_order_cnt
        ,cast(coalesce(direct_item_cnt, 0) as bigint) as direct_item_cnt
        ,cast(coalesce(direct_gmv_amt_local, 0) as double) as direct_gmv_amt_local
        ,cast(coalesce(direct_gmv_amt_local / exchange_rate, 0) as double) as direct_gmv_amt_usd
        ,cast(0 as double) as pCTR
        ,cast(0 as double) as pCR
        ,cast(0 as double) as direct_pcr
        ,cast(0 as double) as broad_pcr
        ,cast(0 as double) as rank_score
        ,cast(0 as bigint) as rank
        ,cast(0 as double) as item_price
        ,cast(0 as bigint) as sold_cnt_per_order
        ,cast(0 as double) as target_cir
        ,cast(0 as double) as bidprice
        ,cast(0 as double) as deduction_price
        ,cast(0 as double) as pcr_1d
        ,cast(0 as double) as pcr_delay
        ,cast(0 as double) as pcr_shop
        ,null as sub_entrance
        ,cast(coalesce(broad_order_1d,0) as bigint) as broad_order_1d
        ,cast(0 as bigint) as dedup_impression_cnt
        ,cast(0 as bigint) as dedup_click_cnt
        ,if(base.grass_date = '${grass_date}',1,0) as acct_cnt
        ,cast(location as bigint) as organic_location
        ,cast(new_product_boost_coef as double) as new_product_boost_coef
        ,cast(new_product_boost_stage as bigint) as new_product_boost_stage
        ,cast(0 as bigint) as new_product_boost_tier
        ,cast(0 as double) as pctr_v
        ,cast(0 as double) as pcr_v
        ,cast(0 as double) as broad_pcr_v
        ,cast(0 as double) as bid_price_0
        ,cast(0 as double) as voucher_price
        ,cast(0 as bigint) as bid_voucher_id
        ,cast(0 as double) as voucher_deduction_price
        ,cast(0 as double) as deduction_price_0
        ,cast(0 as int) as is_auto_claimed_just_now
        ,null as item_voucher
        ,cast(0 as int) as display_ads_voucher_label
        ,cast(COALESCE(pdp_view,0) as bigint) as pdp_view
        ,cast(COALESCE(ads_voucher_auto_claimed,0) as bigint) as ads_voucher_auto_claimed
        ,cast(COALESCE(paid_order_cnt,0) as bigint) as paid_order_cnt
        ,cast(COALESCE(paid_order_cnt_24h,0) as bigint) as paid_order_cnt_24h
        ,null as ab_sign
        ,cast(COALESCE(paid_order_gmv_local,0) as double) as paid_order_gmv_local
        ,cast(COALESCE(paid_order_gmv_local / exchange_rate,0) as double) as paid_order_gmv_usd
        ,cast(COALESCE(paid_order_gmv_local_24h,0) as double) as paid_order_gmv_local_24h
        ,cast(COALESCE(paid_order_gmv_local_24h / exchange_rate,0) as double) as paid_order_gmv_usd_24h
        ,null as algo_json_data
        ,cast(COALESCE(broad_order_cnt_24h, 0) as bigint) as broad_order_cnt_24h
        ,cast(COALESCE(broad_order_gmv_local_24h / exchange_rate, 0) as double) as broad_order_gmv_usd_24h
        ,cast(COALESCE(broad_order_gmv_local_24h, 0) as double) as broad_order_gmv_local_24h
        ,cast(COALESCE(direct_order_cnt_24h, 0) as bigint) as direct_order_cnt_24h
        ,cast(COALESCE(direct_order_gmv_local_24h / exchange_rate, 0) as double) as direct_order_gmv_usd_24h
        ,cast(COALESCE(direct_order_gmv_local_24h, 0) as double) as direct_order_gmv_local_24h
        ,cast(COALESCE(broad_order_cnt_4d, 0) as bigint) as broad_order_cnt_4d
        ,cast(COALESCE(broad_order_gmv_local_4d / exchange_rate, 0) as double) as broad_order_gmv_usd_4d
        ,cast(COALESCE(broad_order_gmv_local_4d, 0) as double) as broad_order_gmv_local_4d
        ,cast(COALESCE(direct_order_cnt_4d, 0) as bigint) as direct_order_cnt_4d
        ,cast(COALESCE(direct_order_gmv_local_4d / exchange_rate, 0) as double) as direct_order_gmv_usd_4d
        ,cast(COALESCE(direct_order_gmv_local_4d, 0) as double) as direct_order_gmv_local_4d
        ,cast(COALESCE(cps_dedup_click, 0) as bigint) as cps_dedup_click
        ,cast(COALESCE(deduct_order_cnt, 0) as bigint) as deduct_order_cnt
        ,null as first_impression_timestamp
        ,null as first_click_timestamp
        ,null as bid_rerank_trace
        ,null as pid_coef
        ,null as uni_pcr_model_name
        ,cast(0 as double) as item_price_shop
        ,cast(0 as double) as avg_sold_cnt_shop
        ,cast(0 as double) as avg_sold_cnt_item
        ,cast(plan_bucket_list as array<bigint>) as plan_bucket_list
        ,cast(coalesce(paid_broad_order_cnt,0) as bigint) as paid_broad_order_cnt
        ,cast(coalesce(paid_broad_order_gmv_local,0) as double) as paid_broad_order_gmv_local
        ,cast(coalesce(paid_broad_order_gmv_usd,0) as double) as paid_broad_order_gmv_usd
        ,null as level1_global_be_category
        ,null as level1_global_be_category_id
        ,null as level2_global_be_category
        ,null as level2_global_be_category_id
        ,cast(coalesce(deduplicated_click,0) as bigint) as deduplicated_click
        ,cast(COALESCE(broad_order_cnt_1h, 0) as bigint) as broad_order_cnt_1h
        ,cast(COALESCE(broad_order_gmv_usd_1h, 0) as double) as broad_order_gmv_usd_1h
        ,cast(COALESCE(broad_order_gmv_local_1h, 0) as double) as broad_order_gmv_local_1h
        ,cast(COALESCE(direct_order_cnt_1h, 0) as bigint) as direct_order_cnt_1h
        ,cast(COALESCE(direct_order_gmv_usd_1h, 0) as double) as direct_order_gmv_usd_1h
        ,cast(COALESCE(direct_order_gmv_local_1h, 0) as double) as direct_order_gmv_local_1h
        ,entrance_group
        ,is_ocpm
        ,page_type
        ,target_type
        ,query
        ,keyword
        ,raw_request_id
        ,video_id
        ,deduct_unique_id
        ,deduction_reason
        ,image_id
        ,cast(page_view as bigint) as page_view
        ,base.grass_date
        ,base.grass_region
    from
        (
            select
                ads_id
                ,campaign_id
                ,item_id
                ,user_id
                ,request_id
                ,shop_id
                ,entrance
                ,pricing_type
                ,placement
                ,sum(`click_cnt`) as deduct_click_cnt
                ,sum(deduct_impression) as deduct_impression_cnt
                ,sum(coalesce(expenditure_amt_local, expense_by_cpm)) as expenditure_amt_local
                ,sum(`broad_order_cnt`) as broad_order_cnt
                ,sum(`broad_item_cnt`) as broad_item_cnt
                ,sum(`broad_gmv_amt_local`) as broad_gmv_amt_local
                ,sum(`daily_order_cnt`) as daily_order_cnt
                ,sum(`daily_order_amount`) as daily_item_cnt
                ,sum(`daily_gmv_amt_local`) as daily_gmv_amt_local
                ,sum(`order_cnt`) as direct_order_cnt
                ,sum(`ads_item_sold_cnt`) as direct_item_cnt
                ,sum(`ads_order_gmv_local`) as direct_gmv_amt_local
                ,sum(broad_order_1d) as broad_order_1d
                ,max(location) as location
                ,max(new_product_boost_coef) as new_product_boost_coef
                ,max(new_product_boost_stage) as new_product_boost_stage
                ,sum(page_view) as pdp_view
                ,max(ads_voucher_auto_claimed) as ads_voucher_auto_claimed
                ,sum(paid_order_cnt) as paid_order_cnt
                ,sum(if(paid_timestamp - coalesce(click_timestamp,imp_timestamp) <= 24 * 3600, paid_order_cnt, 0)) as paid_order_cnt_24h
                ,sum(paid_order_gmv_local) as paid_order_gmv_local
                ,sum(if(paid_timestamp - coalesce(click_timestamp,imp_timestamp) <= 24 * 3600, paid_order_gmv_local, 0)) as paid_order_gmv_local_24h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 24 * 3600, broad_order_cnt, 0)) as broad_order_cnt_24h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 24 * 3600, broad_gmv_amt_local, 0)) as broad_order_gmv_local_24h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 24 * 3600, order_cnt, 0)) as direct_order_cnt_24h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 24 * 3600, ads_order_gmv_local, 0)) as direct_order_gmv_local_24h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 4 * 24 * 3600, broad_order_cnt, 0)) as broad_order_cnt_4d
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 4 * 24 * 3600, broad_gmv_amt_local, 0)) as broad_order_gmv_local_4d
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 4 * 24 * 3600, order_cnt, 0)) as direct_order_cnt_4d
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 4 * 24 * 3600, ads_order_gmv_local, 0)) as direct_order_gmv_local_4d
                ,sum(cps_dedup_click) as cps_dedup_click
                ,sum(deduct_order) as deduct_order_cnt
                ,max(plan_bucket_list) as plan_bucket_list
                ,sum(paid_broad_order_cnt) as paid_broad_order_cnt
                ,sum(paid_broad_order_gmv) as paid_broad_order_gmv_local
                ,sum(paid_broad_gmv_usd) as paid_broad_order_gmv_usd
                ,sum(deduplicated_click) as deduplicated_click
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 3600, broad_order_cnt, 0)) as broad_order_cnt_1h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 3600, broad_gmv_amt_local, 0)) as broad_order_gmv_local_1h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 3600, broad_gmv_amt_usd, 0)) as broad_order_gmv_usd_1h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 3600, order_cnt, 0)) as direct_order_cnt_1h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 3600, ads_order_gmv_local, 0)) as direct_order_gmv_local_1h
                ,sum(if(event_timestamp - coalesce(click_timestamp,imp_timestamp) <= 3600, ads_order_gmv_usd, 0)) as direct_order_gmv_usd_1h
                ,max(entrance_group) as entrance_group
                ,max(is_ocpm) as is_ocpm
                ,max(page_type) as page_type
                ,max(target_type) as target_type
                ,max(query) as query
                ,max(keyword) as keyword
                ,max(raw_request_id) as raw_request_id
                ,max(video_id) as video_id
                ,max(deduct_unique_id) as deduct_unique_id
                ,max(deduction_reason) as deduction_reason
                ,max(image_id) as image_id
                ,sum(page_view) as page_view
                ,case
                    when (broad_order_cnt is not null or paid_broad_order_cnt is not null or COALESCE(deduct_order,0) > 0) or broad_gmv_amt_local > 0 or paid_broad_order_gmv > 0 or daily_order_amount > 0  then from_unixtime(coalesce(click_timestamp,imp_timestamp), 'yyyy-MM-dd')
                    else grass_date
                end as grass_date
                ,grass_region
            from mp_paidads.dwd_advertise_performance_di__reg_s0_live
            where
                tz_type = 'local'
                and grass_region in ('${region}')
                and grass_date = date('${grass_date}')
                and item_id is not null
                and (
                    (click_cnt = 1 or page_view = 1 or cps_dedup_click = 1 or deduct_impression > 0 or deduplicated_click = 1)
                    or ((broad_order_cnt = 1 or paid_broad_order_cnt = 1 or broad_gmv_amt_local > 0 or paid_broad_order_gmv > 0 or deduct_order = 1)
                        --paid归因在某一天分区会存在近30天的数据，这里只计算近7天数据就好
                        and from_unixtime(coalesce(click_timestamp,imp_timestamp), 'yyyy-MM-dd') >= date_sub('${grass_date}', 7)
                        and from_unixtime(coalesce(click_timestamp,imp_timestamp), 'yyyy-MM-dd') <= '${grass_date}'
                    )
                )
            group by
                ads_id
                ,campaign_id
                ,item_id
                ,user_id
                ,request_id
                ,shop_id
                ,entrance
                ,pricing_type
                ,placement
                ,case
                    when (broad_order_cnt is not null or paid_broad_order_cnt is not null or COALESCE(deduct_order,0) > 0) or broad_gmv_amt_local > 0 or paid_broad_order_gmv > 0 or daily_order_amount > 0  then from_unixtime(coalesce(click_timestamp,imp_timestamp), 'yyyy-MM-dd')
                    else grass_date
                end
                ,grass_region
        ) base
        left join exchange_rate on base.grass_region = exchange_rate.grass_region
)
;

merge into dwd_ads_request_performance_di__reg_s0_live as target using source on target.grass_date = source.grass_date
and target.grass_region = source.grass_region
and target.request_id = source.request_id
and target.ads_id = source.ads_id
and target.user_id = source.user_id
and target.entrance = source.entrance
and target.placement = source.placement when matched then UPDATE SET target.deduct_click_cnt = target.deduct_click_cnt + source.deduct_click_cnt
,target.deduct_impression_cnt = target.deduct_impression_cnt + source.deduct_impression_cnt
,target.expenditure_amt_local = target.expenditure_amt_local + source.expenditure_amt_local
,target.expenditure_amt_usd = target.expenditure_amt_usd + source.expenditure_amt_usd
,target.broad_order_cnt = target.broad_order_cnt + source.broad_order_cnt
,target.broad_item_cnt = target.broad_item_cnt + source.broad_item_cnt
,target.broad_gmv_amt_local = target.broad_gmv_amt_local + source.broad_gmv_amt_local
,target.broad_gmv_amt_usd = target.broad_gmv_amt_usd + source.broad_gmv_amt_usd
,target.daily_order_cnt = target.daily_order_cnt + source.daily_order_cnt
,target.daily_item_cnt = target.daily_item_cnt + source.daily_item_cnt
,target.daily_gmv_amt_local = target.daily_gmv_amt_local + source.daily_gmv_amt_local
,target.daily_gmv_amt_usd = target.daily_gmv_amt_usd + source.daily_gmv_amt_usd
,target.direct_order_cnt = target.direct_order_cnt + source.direct_order_cnt
,target.direct_item_cnt = target.direct_item_cnt + source.direct_item_cnt
,target.direct_gmv_amt_local = target.direct_gmv_amt_local + source.direct_gmv_amt_local
,target.direct_gmv_amt_usd = target.direct_gmv_amt_usd + source.direct_gmv_amt_usd
,target.broad_order_1d = target.broad_order_1d + source.broad_order_1d
,target.pdp_view = target.pdp_view + source.pdp_view
,target.ads_voucher_auto_claimed = source.ads_voucher_auto_claimed
,target.paid_order_cnt = target.paid_order_cnt + source.paid_order_cnt
,target.paid_order_cnt_24h = target.paid_order_cnt_24h + source.paid_order_cnt_24h
,target.paid_order_gmv_local = target.paid_order_gmv_local + source.paid_order_gmv_local
,target.paid_order_gmv_usd = target.paid_order_gmv_usd + source.paid_order_gmv_usd
,target.paid_order_gmv_local_24h = target.paid_order_gmv_local_24h + source.paid_order_gmv_local_24h
,target.paid_order_gmv_usd_24h = target.paid_order_gmv_usd_24h + source.paid_order_gmv_usd_24h
,target.broad_order_cnt_24h = target.broad_order_cnt_24h + source.broad_order_cnt_24h
,target.broad_order_gmv_usd_24h = target.broad_order_gmv_usd_24h + source.broad_order_gmv_usd_24h
,target.broad_order_gmv_local_24h = target.broad_order_gmv_local_24h + source.broad_order_gmv_local_24h
,target.direct_order_cnt_24h = target.direct_order_cnt_24h + source.direct_order_cnt_24h
,target.direct_order_gmv_usd_24h = target.direct_order_gmv_usd_24h + source.direct_order_gmv_usd_24h
,target.direct_order_gmv_local_24h = target.direct_order_gmv_local_24h + source.direct_order_gmv_local_24h
,target.broad_order_cnt_4d = target.broad_order_cnt_4d + source.broad_order_cnt_4d
,target.broad_order_gmv_usd_4d = target.broad_order_gmv_usd_4d + source.broad_order_gmv_usd_4d
,target.broad_order_gmv_local_4d = target.broad_order_gmv_local_4d + source.broad_order_gmv_local_4d
,target.direct_order_cnt_4d = target.direct_order_cnt_4d + source.direct_order_cnt_4d
,target.direct_order_gmv_usd_4d = target.direct_order_gmv_usd_4d + source.direct_order_gmv_usd_4d
,target.direct_order_gmv_local_4d = target.direct_order_gmv_local_4d + source.direct_order_gmv_local_4d
,target.cps_dedup_click = target.cps_dedup_click + source.cps_dedup_click
,target.deduct_order_cnt = target.deduct_order_cnt + source.deduct_order_cnt
,target.plan_bucket_list = source.plan_bucket_list
,target.entrance_group = source.entrance_group
,target.is_ocpm = source.is_ocpm
,target.page_type = source.page_type
,target.target_type = source.target_type
,target.query = source.query
,target.keyword = source.keyword
,target.raw_request_id = source.raw_request_id
,target.video_id = source.video_id
,target.deduct_unique_id = source.deduct_unique_id
,target.deduction_reason = source.deduction_reason
,target.image_id = source.image_id
-------当天是否回溯标示，acct_cnt>1 代表有回溯
,target.acct_cnt = target.acct_cnt + source.acct_cnt
,target.paid_broad_order_cnt = target.paid_broad_order_cnt + source.paid_broad_order_cnt
,target.paid_broad_order_gmv_local = target.paid_broad_order_gmv_local + source.paid_broad_order_gmv_local
,target.paid_broad_order_gmv_usd = target.paid_broad_order_gmv_usd + source.paid_broad_order_gmv_usd
,target.deduplicated_click = target.deduplicated_click + source.deduplicated_click
,target.broad_order_cnt_1h = target.broad_order_cnt_1h + source.broad_order_cnt_1h
,target.broad_order_gmv_usd_1h = target.broad_order_gmv_usd_1h + source.broad_order_gmv_usd_1h
,target.broad_order_gmv_local_1h = target.broad_order_gmv_local_1h + source.broad_order_gmv_local_1h
,target.direct_order_cnt_1h = target.direct_order_cnt_1h + source.direct_order_cnt_1h
,target.direct_order_gmv_usd_1h = target.direct_order_gmv_usd_1h + source.direct_order_gmv_usd_1h
,target.direct_order_gmv_local_1h = target.direct_order_gmv_local_1h + source.direct_order_gmv_local_1h
,target.page_view = target.page_view + source.page_view
when not matched then
insert *
;
