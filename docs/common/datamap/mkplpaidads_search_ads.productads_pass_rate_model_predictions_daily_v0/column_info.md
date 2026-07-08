<!-- ads-workspace-gdoc-sync: gdoc_id=1_S-06-DJMQ8eA0iGtA6dSHXBiv_BCXH5zVvOI1uXgH4 gdoc_url=https://docs.google.com/document/d/1_S-06-DJMQ8eA0iGtA6dSHXBiv_BCXH5zVvOI1uXgH4/edit -->

# Columns: mkplpaidads_search_ads.productads_pass_rate_model_predictions_daily_v0

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

{None identified — each row is a unique prediction for one ads_id, so SUM/COUNT is additive.}

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| model_type | lightgbm_ranker_7d1o / lightgbm_ranker_7d1o_v1 | NPB ranking model (7-day window, 1 order threshold) |
| model_type | lightgbm_ranker_7d3o | Cold start ranking model (7-day window, 3 order threshold) |
| model_type | lightgbm_ranker | Generic ranker (dashboard use) |
| model_type | classification_7d3o / lightgbm_classifier_7d3o_v2 | Cold start/empty order classifier (7-day, 3 order) |
| model_type | classification_7d1o | NPB classifier (7-day, 1 order) |
| grass_region | ID, TH, MY, VN, PH, SG, TW, BR | Standard Asian regions + Brazil |
| rank_group_keys (derived) | `concat(element_at(split(rank_group_keys, '-'), -2), '-', element_at(split(rank_group_keys, '-'), -1))` | Simplified group key (last 2 segments) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 通常取 1-8 天前的日期 (`date('${BIZ_PRE_DAY}')` 或 `date('${ISO_8DAY_AGO}')`)
- `grass_region`: `IN ('ID','TH','MY','VN','PH','SG','TW','BR')` (全量 Asian) 或单个地区如 `'TW'`
- `model_type`: 按业务场景筛选:
  - `LIKE '%lightgbm_ranker_7d1o%'` — NPB reserve
  - `LIKE '%lightgbm_ranker_7d3o%'` — Cold start reserve
  - `= 'lightgbm_ranker'` — Dashboard
  - `= 'classification_7d3o'` / `= 'classification_7d1o'` — Classifier analysis
  - `IN ('lightgbm_classifier_7d3o_v2', 'lightgbm_ranker_7d1o_v1')` — TW 出坡率分析

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| feature_shaps_map | array<struct<col_name:string, shap_value:double>> | SHAP 特征重要性，按 shap_value 降序排列 | - | - |
| rank_group_keys | string | 排名分组键（如品类-子品类-关键词组合） | - | - |
| prediction | float | 模型预测分数（ranker: ranking score; classifier: pass probability） | - | - |
| cls_proba | double | 分类器获胜类别概率（仅 classifier 有值，ranker 恒为 0.0） | - | - |
| grass_date | date | 数据日期（分区列） | - | - |
| grass_region | string | 地区（分区列） | - | - |
| model_type | string | 模型类型（分区列） | - | - |
