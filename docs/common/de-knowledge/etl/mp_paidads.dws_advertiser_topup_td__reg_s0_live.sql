-- task_code: data_paidadsmart.studio_2884830  asset_id: 2884830
INSERT OVERWRITE TABLE dws_advertiser_topup_td__reg_s0_live PARTITION (tz_type, grass_region, grass_date)
    SELECT   /*+ MAPJOIN(b)*/
              COALESCE(a.shop_id, b.shop_id) AS shop_id
             ,COALESCE(a.seller_id, b.seller_id) AS seller_id
             ,COALESCE(a.total_topup_amt, 0.0) + COALESCE(b.total_topup_amt, 0.0) AS total_topup_amt
             ,COALESCE(a.total_topup_amt_usd, 0.0) + COALESCE(b.total_topup_amt_usd, 0.0) AS total_topup_amt_usd
             ,COALESCE(a.manual_topup_amt, 0.0) + COALESCE(b.manual_topup_amt, 0.0) AS manual_topup_amt
             ,COALESCE(a.manual_topup_amt_usd, 0.0) + COALESCE(b.manual_topup_amt_usd, 0.0) AS manual_topup_amt_usd
             ,COALESCE(a.auto_topup_amt_local, 0.0) + COALESCE(b.auto_topup_amt_local, 0.0) AS auto_topup_amt_local
             ,COALESCE(a.auto_topup_amt_usd, 0.0) + COALESCE(b.auto_topup_amt_usd, 0.0) AS auto_topup_amt_usd
             ,COALESCE(a.normal_amt_local, 0.0) + COALESCE(b.normal_amt_local, 0.0) AS normal_amt_local
             ,COALESCE(a.normal_amt_usd, 0.0) + COALESCE(b.normal_amt_usd, 0.0) AS normal_amt_usd
             ,COALESCE(a.seller_mission_topup_amt, 0.0) + COALESCE(b.seller_mission_topup_amt, 0.0) AS seller_mission_topup_amt
             ,COALESCE(a.seller_mission_topup_amt_usd, 0.0) + COALESCE(b.seller_mission_topup_amt_usd, 0.0) AS seller_mission_topup_amt_usd
             ,COALESCE(a.srm_topup_amt, 0.0) + COALESCE(b.srm_topup_amt, 0.0) AS srm_topup_amt
             ,COALESCE(a.srm_topup_amt_usd, 0.0) + COALESCE(b.srm_topup_amt_usd, 0.0) AS srm_topup_amt_usd
             ,COALESCE(a.neg_topup_amt, 0.0) + COALESCE(b.neg_topup_amt, 0.0) AS neg_topup_amt
             ,COALESCE(a.neg_topup_amt_usd, 0.0) + COALESCE(b.neg_topup_amt_usd, 0.0) AS neg_topup_amt_usd
             ,COALESCE(b.first_topup_timestamp, a.first_topup_timestamp) AS first_topup_timestamp
             ,COALESCE(b.first_manual_topup_timestamp, a.first_manual_topup_timestamp) AS first_manual_topup_timestamp
             ,COALESCE(b.first_normal_topup_timestamp, a.first_normal_topup_timestamp) AS first_normal_topup_timestamp
             ,COALESCE(b.first_auto_topup_timestamp, a.first_auto_topup_timestamp) AS first_auto_topup_timestamp
             ,COALESCE(a.last_topup_timestamp, b.last_topup_timestamp) AS last_topup_timestamp
             ,COALESCE(a.last_manual_topup_timestamp, b.last_manual_topup_timestamp) AS last_manual_topup_timestamp
             ,COALESCE(a.last_auto_topup_timestamp, b.last_auto_topup_timestamp) AS last_auto_topup_timestamp
             ,COALESCE(a.last_normal_topup_timestamp, b.last_normal_topup_timestamp) AS last_normal_topup_timestamp
             ,COALESCE(a.topup_times_cnt, 0) + COALESCE(b.topup_times_cnt, 0) AS topup_times_cnt
             ,COALESCE(a.manual_topup_times_cnt, 0) + COALESCE(b.manual_topup_times_cnt, 0) AS manual_topup_times_cnt
             ,COALESCE(a.auto_topup_times_cnt, 0) + COALESCE(b.auto_topup_times_cnt, 0) AS auto_topup_times_cnt
             ,COALESCE(a.normal_topup_times_cnt, 0) + COALESCE(b.normal_topup_times_cnt, 0) AS normal_topup_times_cnt
             ,COALESCE(a.srm_topup_times_cnt, 0) + COALESCE(b.srm_topup_times_cnt, 0) AS srm_topup_times_cnt
             ,COALESCE(a.tz_type, b.tz_type) AS tz_type
             ,COALESCE(a.region, b.region) AS grass_region
             ,date('${grass_date}')  AS grass_date
    FROM
    (
        SELECT   shop_id
                ,seller_id
                ,total_topup_amt
                ,total_topup_amt_usd
                ,manual_topup_amt
                ,manual_topup_amt_usd
                ,auto_topup_amt_local
                ,auto_topup_amt_usd
                ,normal_amt_local
                ,normal_amt_usd
                ,seller_mission_topup_amt
                ,seller_mission_topup_amt_usd
                ,srm_topup_amt
                ,srm_topup_amt_usd
                ,neg_topup_amt
                ,neg_topup_amt_usd
                ,first_topup_timestamp
                ,first_manual_topup_timestamp
                ,first_normal_topup_timestamp
                ,first_auto_topup_timestamp
                ,last_topup_timestamp
                ,last_manual_topup_timestamp
                ,last_auto_topup_timestamp
                ,last_normal_topup_timestamp
                ,topup_times_cnt
                ,manual_topup_times_cnt
                ,auto_topup_times_cnt
                ,normal_topup_times_cnt
                ,srm_topup_times_cnt
                ,grass_region AS region
                ,tz_type
        FROM mp_paidads.dws_advertiser_topup_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
    ) a
    FULL OUTER JOIN
    (
        SELECT   shop_id
                ,seller_id
                ,total_topup_amt
                ,total_topup_amt_usd
                ,manual_topup_amt
                ,manual_topup_amt_usd
                ,auto_topup_amt_local
                ,auto_topup_amt_usd
                ,normal_amt_local
                ,normal_amt_usd
                ,seller_mission_topup_amt
                ,seller_mission_topup_amt_usd
                ,srm_topup_amt
                ,srm_topup_amt_usd
                ,neg_topup_amt
                ,neg_topup_amt_usd
                ,first_topup_timestamp
                ,first_manual_topup_timestamp
                ,first_normal_topup_timestamp
                ,first_auto_topup_timestamp
                ,last_topup_timestamp
                ,last_manual_topup_timestamp
                ,last_auto_topup_timestamp
                ,last_normal_topup_timestamp
                ,topup_times_cnt
                ,manual_topup_times_cnt
                ,auto_topup_times_cnt
                ,normal_topup_times_cnt
                ,srm_topup_times_cnt
                ,grass_region AS region
                ,tz_type
        FROM mp_paidads.dws_advertiser_topup_td__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date_sub(date('${grass_date}'), 1)
    ) b
    ON a.shop_id = b.shop_id
    AND a.region = b.region
    AND a.seller_id <=> b.seller_id
    AND a.tz_type = b.tz_type;

alter table dws_advertiser_topup_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");