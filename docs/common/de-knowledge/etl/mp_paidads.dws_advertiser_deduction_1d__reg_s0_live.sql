-- task_code: data_paidadsmart.studio_2668374  asset_id: 2668374
INSERT OVERWRITE TABLE dws_advertiser_deduction_1d__reg_s0_live PARTITION (tz_type='local', grass_region='${upper_region}', grass_date = '${grass_date}')
    SELECT
        /*+ MAPJOIN(exrate)*/
        shop_id
        ,paid_expenditure_wo_expiry_amt_local AS paid_expenditure_wo_expiry_amt_local_1d
        ,cast(paid_expenditure_wo_expiry_amt_local as double) / exrate.exchange_rate AS paid_expenditure_wo_expiry_amt_usd_1d
        ,paid_expenditure_w_expiry_amt_local AS paid_expenditure_w_expiry_amt_local_1d
        ,cast(paid_expenditure_w_expiry_amt_local as double) / exrate.exchange_rate AS paid_expenditure_w_expiry_amt_usd_1d
        ,free_expenditure_wo_expiry_amt_local AS free_expenditure_wo_expiry_amt_local_1d
        ,cast(free_expenditure_wo_expiry_amt_local as double) / exrate.exchange_rate AS free_expenditure_wo_expiry_amt_usd_1d
        ,free_expenditure_w_expiry_amt_local AS free_expenditure_w_expiry_amt_local_1d
        ,cast(free_expenditure_w_expiry_amt_local as double) / exrate.exchange_rate AS free_expenditure_w_expiry_amt_usd_1d
    FROM (
        select shop_id,grass_region
            ,coalesce(sum(expense_free_credit_with_expiry)/ 100000.0,0.0) as free_expenditure_w_expiry_amt_local
            ,coalesce(sum(expense_free_credit_without_expiry)/ 100000.0,0.0) as free_expenditure_wo_expiry_amt_local
            ,coalesce(sum(expense_paid_credit_with_expiry)/ 100000.0,0.0) as paid_expenditure_w_expiry_amt_local
            ,coalesce(sum(expense_paid_credit_without_expiry)/ 100000.0,0.0) as paid_expenditure_wo_expiry_amt_local
        from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where   grass_region = upper('${region}') and grass_date = DATE('${grass_date}') and expenditure_amt_local>0
        group by 1,2
    ) a
    LEFT OUTER JOIN
    (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
    ) exrate
    ON a.grass_region = exrate.grass_region;

INSERT OVERWRITE TABLE dws_advertiser_deduction_1d__reg_s0_live PARTITION (tz_type='regional', grass_region='${upper_region}', grass_date = '${grass_date}')
    SELECT
        /*+ MAPJOIN(exrate)*/
        shop_id
        ,paid_expenditure_wo_expiry_amt_local AS paid_expenditure_wo_expiry_amt_local_1d
        ,cast(paid_expenditure_wo_expiry_amt_local as double) / exrate.exchange_rate AS paid_expenditure_wo_expiry_amt_usd_1d
        ,paid_expenditure_w_expiry_amt_local AS paid_expenditure_w_expiry_amt_local_1d
        ,cast(paid_expenditure_w_expiry_amt_local as double) / exrate.exchange_rate AS paid_expenditure_w_expiry_amt_usd_1d
        ,free_expenditure_wo_expiry_amt_local AS free_expenditure_wo_expiry_amt_local_1d
        ,cast(free_expenditure_wo_expiry_amt_local as double) / exrate.exchange_rate AS free_expenditure_wo_expiry_amt_usd_1d
        ,free_expenditure_w_expiry_amt_local AS free_expenditure_w_expiry_amt_local_1d
        ,cast(free_expenditure_w_expiry_amt_local as double) / exrate.exchange_rate AS free_expenditure_w_expiry_amt_usd_1d
    FROM (
        select shop_id,grass_region
            ,coalesce(sum(expense_free_credit_with_expiry)/ 100000.0,0.0) as free_expenditure_w_expiry_amt_local
            ,coalesce(sum(expense_free_credit_without_expiry)/ 100000.0,0.0) as free_expenditure_wo_expiry_amt_local
            ,coalesce(sum(expense_paid_credit_with_expiry)/ 100000.0,0.0) as paid_expenditure_w_expiry_amt_local
            ,coalesce(sum(expense_paid_credit_without_expiry)/ 100000.0,0.0) as paid_expenditure_wo_expiry_amt_local
        from mp_paidads.dwd_advertise_performance_di__reg_s0_live
        where grass_region = '${upper_region}'
            and grass_date >= date_sub(DATE('${grass_date}'),1) and grass_date <= DATE('${grass_date}')
            and timestamp >= to_unix_timestamp('${grass_date}', 'yyyy-MM-dd')
            and timestamp < to_unix_timestamp(DATE_ADD(DATE('${grass_date}'), 1), 'yyyy-MM-dd') and expenditure_amt_local>0
        group by 1,2
    ) a
    LEFT OUTER JOIN
    (
        SELECT
            grass_region
            ,exchange_rate
        FROM mp_order.dim_exchange_rate__reg_s0_live
        WHERE grass_region = upper('${region}')
        AND grass_date = DATE('${grass_date}')
    ) exrate
    ON a.grass_region = exrate.grass_region;

alter table dws_advertiser_deduction_1d__${region}_s0_live add if not exists partition(grass_date = "${grass_date}")
;