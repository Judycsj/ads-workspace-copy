<!-- ads-workspace-gdoc-sync: gdoc_id=1wGb5PXVGaYC-_DYpo7fmK395XgqZr-BC9YcSwsOf6wY gdoc_url=https://docs.google.com/document/d/1wGb5PXVGaYC-_DYpo7fmK395XgqZr-BC9YcSwsOf6wY/edit -->

# Columns: mkplpaidads_brand_ads.search_brand_ads_impression_forecast

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表无常规的 SUM DISTINCT 模式。`forecast_impression_count` 是 region 级聚合值，跨 region 聚合时直接 SUM 即可。
跨 dt（预测版本）聚合时需注意：不同 dt 的预测值代表不同时间点的预测快照，取最新 dt 即可（`dt = max_dt`）。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| country_name | ID | Indonesia |
| country_name | TH | Thailand |
| country_name | PH | Philippines |
| country_name | VN | Vietnam |
| country_name | TW | Taiwan |
| country_name | BR | Brazil |
| country_name | SG | Singapore |
| country_name | MY | Malaysia |

### 常见 WHERE 值 (Common Filter Values)

- `dt`: 取最新预测 `"${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1d')}"` (~70% 查询)，或回溯 `-3d`/`-8d` 用于准确度评估
- `country_name` (别名 grass_region): 标准 8 区 ('ID','TH','PH','VN','TW','BR','SG','MY')
- `forecast_date`: 预测区间 `>= +0d` to `<= +730d`（recall 场景），或 `>= -7d` to `<= -1d`（评估场景）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| country_name | string | 国家/区域代码，别名为 grass_region | - | - |
| dt | string | 分区列：预测生成日期，格式 yyyy-MM-dd | - | - |
| forecast_date | date/string | 被预测的目标日期 | - | - |
| forecast_impression_count | bigint | region 级别的预估展现量 | - | - |
