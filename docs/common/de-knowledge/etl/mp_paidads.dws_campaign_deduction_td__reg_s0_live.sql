-- task_code: data_paidadsmart.studio_2892471  asset_id: 2892471
INSERT OVERWRITE TABLE dws_campaign_deduction_td__reg_s0_live PARTITION (tz_type='local', grass_region, grass_date)
    SELECT  
            campaign_id
           ,SUM(deduction) AS deduction
           ,SUM(deduction_usd) AS deduction_usd
           ,grass_region
          ,date('${grass_date}')  AS grass_date
    FROM (
        SELECT
            campaign_id
            ,sum(total_expenditure_amt_local_1d) as deduction
            ,sum(total_expenditure_amt_usd_1d) as deduction_usd
            ,grass_region
        FROM mp_paidads.dws_advertise_revenue_1d__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date('${grass_date}') 
        and tz_type = 'local'
        group by campaign_id,grass_region

        UNION ALL

        SELECT
            campaign_id
           ,deduction
           ,deduction_usd
           ,grass_region
        FROM mp_paidads.dws_campaign_deduction_td__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = date_sub(date('${grass_date}'), 1)
    )
    GROUP BY campaign_id, grass_region;

alter table dws_campaign_deduction_td__${region}_s0_live add if not exists partition (grass_date = "${grass_date}");