-- https://docs.starrocks.io/docs/3.5/sql-reference/sql-functions/hive_bitmap_udf/
ADD JAR 'hdfs://R2/projects/data_paidadsmart/hdfs/udf/yanzhao.deng/hive-udf-1.0.0.jar';
CREATE TEMPORARY FUNCTION bitmap_agg AS 'com.starrocks.hive.udf.UDAFBitmapAgg';
CREATE TEMPORARY FUNCTION bitmap_to_base64 AS 'com.starrocks.hive.udf.UDFBitmapToBase64';


INSERT INTO
    mp_paidads.`dws_shop_item_order_ads_performance_1d__${region}_s0_live` PARTITION (grass_region = '${upper_region}', grass_date = '${BIZ_YESTERDAY}')
SELECT
    shop_id,
    item_id,
    CAST(NULL AS TIMESTAMP) AS ads_sequence_timestamp,
    CAST(NULL AS BIGINT) AS click_cnt_1d,
    CAST(NULL AS BIGINT) AS impression_cnt_1d,
    CAST(NULL AS DECIMAL(20, 4)) AS expenditure_amt_1d,
    CAST(NULL AS BIGINT) AS checkout_cnt_1d,
    CAST(NULL AS BIGINT) AS direct_order_cnt_1d,
    CAST(NULL AS DECIMAL(20, 4)) AS direct_order_gmv_amt_1d,
    CAST(NULL AS BIGINT) AS broad_order_cnt_1d,
    CAST(NULL AS DECIMAL(20, 4)) AS broad_order_gmv_amt_1d,
    CAST(NULL AS DECIMAL(20, 4)) AS search_expenditure_amt_1d,
    CAST(NULL AS DECIMAL(20, 4)) AS discovery_expenditure_amt_1d,
    current_timestamp() AS order_sequence_timestamp,
    bitmap_to_base64 (bitmap_agg (order_id)) AS order_id_bitmap_base64_1d,
    SUM(seller_gmv) AS seller_gmv_amt_1d
FROM
    mp_order.`dwd_order_item_place_pay_complete_di__${region}_s0_live`
WHERE
    tz_type = 'local'
    AND grass_region = upper('${region}')
    AND grass_date = '${BIZ_YESTERDAY}'
    AND is_placed = 1
    AND shop_id IS NOT NULL
    AND item_id IS NOT NULL
GROUP BY
    shop_id,
    item_id;
