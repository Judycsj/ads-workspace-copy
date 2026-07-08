<!-- ads-workspace-gdoc-sync: gdoc_id=1gHZ4TGmL2YfS0M3oayRFgpxq7ECJWqNVwZsqsrVjW1Y gdoc_url=https://docs.google.com/document/d/1gHZ4TGmL2YfS0M3oayRFgpxq7ECJWqNVwZsqsrVjW1Y/edit -->

# Columns: mkplpaidads_search_ads.overall_supply_budget_metrics_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无明显非累加字段。topup_amt_usd 和 account_balance_usd 在上游已按 shop_id 去重（MAX），本表中为 SUM 后的汇总值。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 'all' | CUBE 汇总行（所有 pricing_type） |
| pricing_type | '1' | CPC Manual |
| pricing_type | '2' | CPC Auto |
| budget_type | 'all' | CUBE 汇总行（所有 budget_type） |
| budget_type | 'limited' | budget_usd < 9999999999 |
| budget_type | 'unlimited' | budget_usd = 9999999999 |

### 常见 WHERE 值 (Common Filter Values)

- `pricing_type`: 'all' (汇总行) / 具体 pricing_type 值
- `budget_type`: 'all' (汇总行) / 'limited' / 'unlimited'
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| pricing_type | string | - | 14/28/60 | all |
| budget_type | string | - | 14/28/60 | unlimited |
| active_ads_cnt | bigint | - | 14/28/60 | 7423984 |
| active_advertiser_cnt | bigint | - | 14/28/60 | 300650 |
| daily_valid_budget | double | - | 14/28/60 | 8729842.34 |
| topup_amt_usd | double | - | 14/28/60 | 4515678.50 |
| account_balance_usd | double | - | 14/28/60 | 16608045.27 |
| grass_date | date | [PARTITION] | 14/28/60 | 2026-06-13 |
| grass_region | string | [PARTITION] | 14/28/60 | - |

*MAX values sampled from grass_date=2026-06-13, grass_region=ID*
