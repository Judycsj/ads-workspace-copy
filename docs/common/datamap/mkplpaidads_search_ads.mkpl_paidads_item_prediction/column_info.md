<!-- ads-workspace-gdoc-sync: gdoc_id=1xI2g4hVpXO4xbO_XiPSF5AK90PT-RDY76a3i-QnJGxA gdoc_url=https://docs.google.com/document/d/1xI2g4hVpXO4xbO_XiPSF5AK90PT-RDY76a3i-QnJGxA/edit -->

# Columns: mkplpaidads_search_ads.mkpl_paidads_item_prediction

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `dt`: Single date filter (`dt = '${BIZ_PRE_DAY}'`), ~90% of queries; occasionally range (`dt between ...`)
- `grass_region`: Standard 8 regions — 'ID', 'TH', 'MY', 'VN', 'SG', 'PH', 'TW', 'BR'; sometimes 4 key markets ('ID', 'TH', 'MY', 'VN')
- `shop_id` + `item_id`: Used together as composite join key for item-level matching

### 派生字段说明 (Derived Field Explanations)

All three metrics are derived from a two-stage GBDT model:
1. **pred_cls**: GBTClassifier output — probability the item gets any order in next 7 days (`p_buy`). Range [0, 1].
2. **order_expected**: GBTRegressor output (stacked on pred_cls features) — expected number of orders in next 7 days. Capped at 40 (CAP * 2). Calculated as `expm1(log1p(actual) prediction)` with log1p target on min(actual, 20).
3. **potential_score**: Normalized score = `1 - exp(-order_expected / 3.0)`. Range asymptotically [0, 1), roughly linear for small values then saturating.

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | Shop ID (business primary key) | - | - |
| item_id | BIGINT | Item ID (business primary key) | - | - |
| pred_cls | DOUBLE | Classification model probability of order (p_buy) | - | - |
| order_expected | DOUBLE | Regression model expected 7-day order count | - | - |
| potential_score | DOUBLE | Normalized potential score: 1 - exp(-order_expected/3.0) | - | - |
| dt [PARTITION] | DATE | Prediction date (writes dt+1 from trainer) | - | - |
| grass_region [PARTITION] | STRING | Region code (ID/TH/MY/VN/SG/PH/TW/BR) | - | - |
