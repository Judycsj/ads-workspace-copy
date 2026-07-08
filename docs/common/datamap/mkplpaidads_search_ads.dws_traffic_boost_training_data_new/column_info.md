<!-- ads-workspace-gdoc-sync: gdoc_id=1Wk4mqrk3URU3r-fYu8yNxaRU7x_IQ8n3hGAuwoWx7G8 gdoc_url=https://docs.google.com/document/d/1Wk4mqrk3URU3r-fYu8yNxaRU7x_IQ8n3hGAuwoWx7G8/edit -->

# Columns: mkplpaidads_search_ads.dws_traffic_boost_training_data_new

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段在跨维度聚合时必须使用 MAX 或重新计算，不能直接 SUM：

- `ecpm2_increase_factor` — 是 ecpm2 / base_ecpm2 的比值，跨 coef 或 ads_id 聚合时应从原始 ecpm2 重新计算，不应直接 SUM
- `campaign_daily_budget_local` / `campaign_daily_budget_usd` — 日预算金额，在代码中普遍使用 MAX() 而非 SUM()
- `campaign_valid_budget_local` / `campaign_valid_budget_usd` — 有效预算金额，同样使用 MAX()

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| time_window | '1t' | Per-tick (~15 min), lowest granularity |
| time_window | '1h' | Hourly aggregation |
| time_window | '1d' | Daily aggregation (most commonly used) |
| coef | 10000 | Control/baseline coefficient (reference level) |
| coef | other | Bid multiplier coefficient for replay simulation |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区: 'SG', 'MY', 'ID', 'PH', 'TH', 'VN', 'TW', 'BR'
- `time_window`: '1d' (出现在几乎所有查询中，作为训练和评估的标准粒度)
- `coef = 10000`: 用于提取基线/对照组的 ecpm2 值以计算 ecpm2_increase_factor
- `campaign_daily_budget_local > 0`: 过滤掉预算为 0 的无效记录
- `campaign_valid_budget_local > 0`: 过滤掉无效预算记录

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | Partition: data date (T-1) | - | - |
| grass_region | string | Partition: region/country code | - | - |
| ads_id | bigint | Ad ID | - | - |
| campaign_id | bigint | Campaign ID, used for JOIN with campaign_targets/weights tables | - | - |
| time_window | string | Time aggregation window: '1t', '1h', '1d' | - | - |
| target_timestamp | string | Target timestamp for the aggregation window | - | - |
| coef | bigint | Bid coefficient; 10000 = baseline/control | - | - |
| pv | bigint | Predicted page views / impressions at this coef level | - | - |
| porder | double | Predicted orders at this coef level | - | - |
| pgmv | double | Predicted GMV at this coef level | - | - |
| ecpm2 | double | Estimated eCPM (revenue) at this coef level | - | - |
| ecpm2_increase_factor | double | Ratio of ecpm2 vs baseline (coef=10000); used to compute effective budget | - | - |
| campaign_daily_budget_local | double | Campaign daily budget in local currency | - | - |
| campaign_daily_budget_usd | double | Campaign daily budget in USD | - | - |
| campaign_valid_budget_local | double | Valid campaign budget (after balance check) in local currency | - | - |
| campaign_valid_budget_usd | double | Valid campaign budget (after balance check) in USD | - | - |
