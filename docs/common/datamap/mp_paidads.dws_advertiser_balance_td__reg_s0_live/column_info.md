<!-- ads-workspace-gdoc-sync: gdoc_id=1zHvADNQhNnaW43Dce1hlAKYmVVkMR9Yi3_IKrgBImpY gdoc_url=https://docs.google.com/document/d/1zHvADNQhNnaW43Dce1hlAKYmVVkMR9Yi3_IKrgBImpY/edit -->

# Columns: mp_paidads.dws_advertiser_balance_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表已是 shop_id x tz_type x grass_region x grass_date 粒度，所有余额字段在该粒度下可以直接 SUM 聚合多个店铺。注意：
- `total_eod_balance_td` 是通过四种信用额度求和的派生字段，聚合时不应再次与子项相加
- 产品线余额字段独立于主余额字段，与 total_eod_balance_td 无加总关系

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | 'local' | 本地时区（唯一已知取值） |
| main_type (upstream) | 2 | Paid credit (付费额度) |
| main_type (upstream) | 3 | Free credit (免费额度) |
| effective_type (upstream) | 1 | ROI2 (ROI2产品线) |
| effective_type (upstream) | 2 | Livestream (直播产品线) |
| effective_type (upstream) | 3 | Search Brand (搜索品牌产品线) |
| credit_topup_type (upstream) | 1 | Voucher topup (代金券充值) |
| credit_topup_type (upstream) | 2 | Paid credit in package topup (套餐中的付费额度) |
| credit_topup_type (upstream) | 3 | Free credit (wo expiry) in voucher topup (代金券中的免费额度-无期限) |
| credit_topup_type (upstream) | 4 | Free credit (w expiry) in package topup (套餐中的免费额度-有期限) |
| is_package_topup (upstream) | 1 | Package topup (套餐充值) |
| is_voucher_topup (upstream) | 1 | Voucher topup (代金券充值) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR') + US 区域 ('MX','CO','CL','AR')
- `tz_type`: 'local' (主要取值)
- `grass_date`: 通常查询 T-1（如 `date('${grass_date}')` 或 `current_date - interval '1' day`）
- `shop_id`: 特定广告主调试时使用的过滤

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | Shop ID (店铺ID) | - | - |
| free_credit_w_expiry_eod_balance_amt_td | DOUBLE | 免费有期限额度日末余额(本地币) | - | - |
| free_credit_w_expiry_eod_balance_amt_usd_td | DOUBLE | 免费有期限额度日末余额(USD) | - | - |
| free_credit_wo_expiry_eod_balance_amt_td | DOUBLE | 免费无期限额度日末余额(本地币) | - | - |
| free_credit_wo_expiry_eod_balance_amt_usd_td | DOUBLE | 免费无期限额度日末余额(USD) | - | - |
| paid_credit_w_expiry_eod_balance_amt_td | DOUBLE | 付费有期限额度日末余额(本地币) | - | - |
| paid_credit_w_expiry_eod_balance_amt_usd_td | DOUBLE | 付费有期限额度日末余额(USD) | - | - |
| paid_credit_wo_expiry_eod_balance_amt_td | DOUBLE | 付费无期限额度日末余额(本地币) | - | - |
| paid_credit_wo_expiry_eod_balance_amt_usd_td | DOUBLE | 付费无期限额度日末余额(USD) | - | - |
| paid_credit_wo_expiry_sod_balance_amt_td | DOUBLE | 付费无期限额度期初余额(本地币) | - | - |
| paid_credit_wo_expiry_sod_balance_amt_usd_td | DOUBLE | 付费无期限额度期初余额(USD) | - | - |
| total_eod_balance_td | DOUBLE | 总日末余额(本地币) = 四种信用额度的总和 | - | - |
| total_eod_balance_usd_td | DOUBLE | 总日末余额(USD) | - | - |
| roi2_eod_balance_amt_td | DOUBLE | ROI2产品线日末余额(本地币) | - | - |
| roi2_eod_balance_amt_usd_td | DOUBLE | ROI2产品线日末余额(USD) | - | - |
| livestream_eod_balance_amt_td | DOUBLE | 直播产品线日末余额(本地币) | - | - |
| livestream_eod_balance_usd_amt_td | DOUBLE | 直播产品线日末余额(USD) | - | - |
| search_brand_eod_balance_amt_td | DOUBLE | 搜索品牌产品线日末余额(本地币) | - | - |
| search_brand_eod_balance_usd_amt_td | DOUBLE | 搜索品牌产品线日末余额(USD) | - | - |
| tz_type | STRING | 时区类型 [PARTITION] | - | - |
| grass_region | STRING | 区域 [PARTITION] | - | - |
| grass_date | DATE | 日期 [PARTITION] | - | - |
