<!-- ads-workspace-gdoc-sync: gdoc_id=1GGyBp4T8r85_1gmEI8Z7CGCDK_OY6yKfpsHTsVcR1x0 gdoc_url=https://docs.google.com/document/d/1GGyBp4T8r85_1gmEI8Z7CGCDK_OY6yKfpsHTsVcR1x0/edit -->

# Columns: mkplpaidads_search_ads.dws_training_data_with_cluster

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为 per-(campaign_id, coef, grass_region, grass_date) 粒度，大部分字段跨 campaign 聚合时不可直接 SUM：

- `ecpm2_increase_factor` — 相对于 coef=10000 基线的 eCPM 比率，跨 campaign 不具可加性
- `porder`, `pgmv` — replay log 预测值，仅在同一 campaign/coef 下有意义

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| coef | 10000 | 基线预算（budget = seller_budget_local），用于 PCOC 校准和 uplift 参考 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: `('ID','TH','PH','VN','TW','SG','MY','BR')` — 标准 8 区（~100% 查询）
- `grass_date`: 日期范围过滤，训练窗口通常 `t-14 至 t-1`（14 天），部分曲线拟合用 `t-30 至 t-1`（30 天）
- `coef = 10000`: 用于基线预测和评估（PCOC 校准、uplift 计算）
- `seller_budget_local > 0`: 过滤无预算 campaign（~80% 查询）
- `campaign_id > 0`: 排除无效 ID（~50% 查询）
- `porder > 0` / `pgmv > 0`: 评估查询中的效果过滤

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告 ID | - | - |
| campaign_id | bigint | 广告系列 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| l1_cat_id | bigint | 一级商品类目 ID | - | - |
| l2_cat_id | bigint | 二级商品类目 ID（用于 cluster 聚合） | - | - |
| coef | bigint | 预算乘数系数（10000=基线） | - | - |
| porder | double | Replay log 预测订单数 | - | - |
| pgmv | double | Replay log 预测 GMV | - | - |
| ecpm2 | double | eCPM 成本（老版本中直接用作 budget） | - | - |
| ecpm2_increase_factor | double | 相对 coef=10000 基线的 eCPM 放大因子 | - | - |
| seller_budget_local | double | 商户本地币日预算 | - | - |
| grass_date | date | 数据日期 [PARTITION] | - | - |
| grass_region | string | 地区 [PARTITION] | - | - |
