<!-- ads-workspace-gdoc-sync: gdoc_id=1c_aTUItV48AMZSGOweQttNZYqmOwSKdW8kdfmtolJQ8 gdoc_url=https://docs.google.com/document/d/1c_aTUItV48AMZSGOweQttNZYqmOwSKdW8kdfmtolJQ8/edit -->

# Columns: mp_paidads.dws_advertise_performance_nd__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段为 COALESCE 计算的比率指标，跨 ads_id/shop_id 聚合时不可直接 SUM，需从基础指标重新计算：

- `ctr_1d`, `ctr_7d`, `ctr_30d`, `ctr_60d`, `ctr_90d` -- COALESCE(click_cnt / impression_cnt, 0.0)
- `cir_1d`, `cir_7d`, `cir_30d`, `cir_60d`, `cir_90d` -- COALESCE(expenditure / ads_gmv, 0.0)
- `cr_1d`, `cr_7d`, `cr_30d`, `cr_60d`, `cr_90d` -- COALESCE(order_cnt / click_cnt, 0.0)
- `cpc_local_1d`, `cpc_local_7d`, `cpc_local_30d`, `cpc_local_60d`, `cpc_local_90d` -- COALESCE(expenditure_local / click_cnt, 0.0)
- `cpc_usd_1d`, `cpc_usd_7d`, `cpc_usd_30d`, `cpc_usd_60d`, `cpc_usd_90d` -- COALESCE(expenditure_usd / click_cnt, 0.0)
- `roi_1d`, `roi_7d`, `roi_30d`, `roi_60d`, `roi_90d` -- COALESCE(ads_gmv / expenditure, 0.0)
- `broad_roi_1d`, `broad_roi_7d`, `broad_roi_30d`, `broad_roi_60d`, `broad_roi_90d` -- COALESCE(broad_gmv / expenditure, 0.0)

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0, 4, 1000, 1200 | Manual Search ADS (Keyword) |
| placement | 3 | Manual Shop ADS |
| placement | 20 | Shop Simple ADS (生产逻辑: if placement=20, ads_type='shop_simple') |
| tz_type | local | 本地时区 |
| tz_type | regional | 区域时区 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (常用 ~70% 查询) / 'regional'
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR') + MX/CO/CL (US)
- `grass_date`: 单日快照 `= DATE('${grass_date}')` 最常见; L7D 范围 `BETWEEN date_sub('${grass_date}',6) AND date'${grass_date}'`; 滚动窗口 `BETWEEN (DATE - 89 DAYS) AND DATE`
- `pricing_type != 29` 在生产逻辑中用于过滤 (从上游 1d 表读取时)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | BIGINT | ads id | - | - |
| placement | BIGINT | ads placement | - | - |
| ads_type | STRING | ads_type (placement=20时设为 shop_simple) | - | - |
| shop_id | BIGINT | shop id | - | - |
| seller_id | BIGINT | seller id | - | - |
| impression_cnt_1d | BIGINT | impression times in 1 days | - | - |
| impression_cnt_7d | BIGINT | impression times in 7 days | - | - |
| impression_cnt_30d | BIGINT | impression times in 30 days | - | - |
| impression_cnt_60d | BIGINT | impression times in 60 days | - | - |
| impression_cnt_90d | BIGINT | impression times in 90 days | - | - |
| click_cnt_1d | BIGINT | click cnt in 1 days | - | - |
| click_cnt_7d | BIGINT | click cnt in 7 days | - | - |
| click_cnt_30d | BIGINT | click cnt in 30 days | - | - |
| click_cnt_60d | BIGINT | click cnt in 60 days | - | - |
| click_cnt_90d | BIGINT | click cnt in 90 days | - | - |
| order_cnt_1d | BIGINT | place order cnt cos this ads in 1 days | - | - |
| order_cnt_7d | BIGINT | place order cnt cos this ads in 7 days | - | - |
| order_cnt_30d | BIGINT | place order cnt cos this ads in 30 days | - | - |
| order_cnt_60d | BIGINT | place order cnt cos this ads in 60 days | - | - |
| order_cnt_90d | BIGINT | place order cnt cos this ads in 90 days | - | - |
| paid_order_cnt_ytd_1d | BIGINT | paid order cnt ytd 1d | - | - |
| confirmed_order_cnt_ytd_1d | BIGINT | confirmed order cnt ytd 1d | - | - |
| ads_items_sold_cnt_1d | BIGINT | ads items sold cnt 1d | - | - |
| ads_items_sold_cnt_7d | BIGINT | ads items sold cnt 7d | - | - |
| ads_items_sold_cnt_30d | BIGINT | ads items sold cnt 30d | - | - |
| ads_items_sold_cnt_60d | BIGINT | ads items sold cnt 60d | - | - |
| ads_items_sold_cnt_90d | BIGINT | ads items sold cnt 90d | - | - |
| ads_gmv_amt_local_1d | DOUBLE | ads gmv amt local 1d | - | - |
| ads_gmv_amt_local_7d | DOUBLE | ads gmv amt local 7d | - | - |
| ads_gmv_amt_local_30d | DOUBLE | ads gmv amt local 30d | - | - |
| ads_gmv_amt_local_60d | DOUBLE | ads gmv amt local 60d | - | - |
| ads_gmv_amt_local_90d | DOUBLE | ads gmv amt local 90d | - | - |
| ads_gmv_amt_usd_1d | DOUBLE | ads gmv amt in usd 1d | - | - |
| ads_gmv_amt_usd_7d | DOUBLE | ads gmv amt in usd 7d | - | - |
| ads_gmv_amt_usd_30d | DOUBLE | ads gmv amt in usd 30d | - | - |
| ads_gmv_amt_usd_60d | DOUBLE | ads gmv amt in usd 60d | - | - |
| ads_gmv_amt_usd_90d | DOUBLE | ads gmv amt in usd 90d | - | - |
| expenditure_amt_local_1d | DOUBLE | expenditure amt local 1d | - | - |
| expenditure_amt_local_7d | DOUBLE | expenditure amt local 7d | - | - |
| expenditure_amt_local_30d | DOUBLE | expenditure amt local 30d | - | - |
| expenditure_amt_local_60d | DOUBLE | expenditure amt local 60d | - | - |
| expenditure_amt_local_90d | DOUBLE | expenditure amt local 90d | - | - |
| expenditure_amt_usd_1d | DOUBLE | expenditure amt usd 1d | - | - |
| expenditure_amt_usd_7d | DOUBLE | expenditure amt usd 7d | - | - |
| expenditure_amt_usd_30d | DOUBLE | expenditure amt usd 30d | - | - |
| expenditure_amt_usd_60d | DOUBLE | expenditure amt usd 60d | - | - |
| expenditure_amt_usd_90d | DOUBLE | expenditure amt usd 90d | - | - |
| ctr_1d | DOUBLE | Click-Through Rate in 1 days | - | - |
| ctr_7d | DOUBLE | Click-Through Rate in 7 days | - | - |
| ctr_30d | DOUBLE | Click-Through Rate in 30 days | - | - |
| ctr_60d | DOUBLE | Click-Through Rate in 60 days | - | - |
| ctr_90d | DOUBLE | Click-Through Rate in 90 days | - | - |
| cir_1d | DOUBLE | Cost-Income Rate in 1 days | - | - |
| cir_7d | DOUBLE | Cost-Income Rate in 7 days | - | - |
| cir_30d | DOUBLE | Cost-Income Rate in 30 days | - | - |
| cir_60d | DOUBLE | Cost-Income Rate in 60 days | - | - |
| cir_90d | DOUBLE | Cost-Income Rate in 90 days | - | - |
| cr_1d | DOUBLE | Conversion Rate in 1 days | - | - |
| cr_7d | DOUBLE | Conversion Rate in 7 days | - | - |
| cr_30d | DOUBLE | Conversion Rate in 30 days | - | - |
| cr_60d | DOUBLE | Conversion Rate in 60 days | - | - |
| cr_90d | DOUBLE | Conversion Rate in 90 days | - | - |
| cpc_local_1d | DOUBLE | Cost Per Click local in 1 days | - | - |
| cpc_local_7d | DOUBLE | Cost Per Click local in 7 days | - | - |
| cpc_local_30d | DOUBLE | Cost Per Click local in 30 days | - | - |
| cpc_local_60d | DOUBLE | Cost Per Click local in 60 days | - | - |
| cpc_local_90d | DOUBLE | Cost Per Click local in 90 days | - | - |
| cpc_usd_1d | DOUBLE | Cost Per Click USD in 1 days | - | - |
| cpc_usd_7d | DOUBLE | Cost Per Click USD in 7 days | - | - |
| cpc_usd_30d | DOUBLE | Cost Per Click USD in 30 days | - | - |
| cpc_usd_60d | DOUBLE | Cost Per Click USD in 60 days | - | - |
| cpc_usd_90d | DOUBLE | Cost Per Click USD in 90 days | - | - |
| roi_1d | DOUBLE | Return on Investment in 1 days | - | - |
| roi_7d | DOUBLE | Return on Investment in 7 days | - | - |
| roi_30d | DOUBLE | Return on Investment in 30 days | - | - |
| roi_60d | DOUBLE | Return on Investment in 60 days | - | - |
| roi_90d | DOUBLE | Return on Investment in 90 days | - | - |
| broad_gmv_amt_local_1d | DOUBLE | broad gmv amt local 1d | - | - |
| broad_gmv_amt_local_7d | DOUBLE | broad gmv amt local 7d | - | - |
| broad_gmv_amt_local_30d | DOUBLE | broad gmv amt local 30d | - | - |
| broad_gmv_amt_local_60d | DOUBLE | broad gmv amt local 60d | - | - |
| broad_gmv_amt_local_90d | DOUBLE | broad gmv amt local 90d | - | - |
| broad_gmv_amt_usd_1d | DOUBLE | broad gmv amt usd 1d | - | - |
| broad_gmv_amt_usd_7d | DOUBLE | broad gmv amt usd 7d | - | - |
| broad_gmv_amt_usd_30d | DOUBLE | broad gmv amt usd 30d | - | - |
| broad_gmv_amt_usd_60d | DOUBLE | broad gmv amt usd 60d | - | - |
| broad_gmv_amt_usd_90d | DOUBLE | broad gmv amt usd 90d | - | - |
| broad_roi_1d | DOUBLE | broad roi 1d | - | - |
| broad_roi_7d | DOUBLE | broad roi 7d | - | - |
| broad_roi_30d | DOUBLE | broad roi 30d | - | - |
| broad_roi_60d | DOUBLE | broad roi 60d | - | - |
| broad_roi_90d | DOUBLE | broad roi 90d | - | - |
| broad_order_cnt_1d | BIGINT | broad order cnt 1d | - | - |
| broad_order_cnt_7d | BIGINT | broad order cnt 7d | - | - |
| broad_order_cnt_30d | BIGINT | broad order cnt 30d | - | - |
| broad_order_cnt_60d | BIGINT | broad order cnt 60d | - | - |
| broad_order_cnt_90d | BIGINT | broad order cnt 90d | - | - |
| ads_deduct_impression_cnt_1d | BIGINT | ads deduct impression cnt 1d | - | - |
| ads_deduct_impression_cnt_7d | BIGINT | ads deduct impression cnt 7d | - | - |
| ads_deduct_impression_cnt_30d | BIGINT | ads deduct impression cnt 30d | - | - |
| ads_deduct_impression_cnt_60d | BIGINT | ads deduct impression cnt 60d | - | - |
| ads_deduct_impression_cnt_90d | BIGINT | ads deduct impression cnt 90d | - | - |
| tz_type | STRING | timezone type (partition) | - | - |
| grass_region | STRING | grass region (partition) | - | - |
| grass_date | DATE | grass date (partition) | - | - |
