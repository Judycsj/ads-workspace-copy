<!-- ads-workspace-gdoc-sync: gdoc_id=1ITqZdlmOqNCFP6ial8sOimQ-4wMXqRbjpEtQrs2PKYA gdoc_url=https://docs.google.com/document/d/1ITqZdlmOqNCFP6ial8sOimQ-4wMXqRbjpEtQrs2PKYA/edit -->

# Columns: mpi_data_mart.dws_a180_user_basic_predict_tags_df

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未在代码库中发现 SUM(DISTINCT) 模式，该表为标签表，跨维度聚合通常使用 MAX() 取最新值。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| predict_gender | Male | 男性 (编码: 2, 102002, '1') |
| predict_gender | Female | 女性 (编码: 1, 102001, '2') |
| predict_age_group | 1 | 18-24岁 (编码: 101001, "18~24") |
| predict_age_group | 2 | 25-34岁 (编码: 101002, "25~34") |
| predict_age_group | 3,4 | 35岁及以上 (编码: 101003, "35+") |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') — 通常为 ID, SG, MY, VN, TH, PH, TW, BR, CO, CL, MX 等标准区域码
- `grass_date`: date'${yesterday}' (workflow调度) / date'${BIZ_PRE_DAY}' (品牌广告) / 硬编码日期 (adhoc分析)
- `predict_gender is not null` — 排除无性别标签用户
- `predict_age_group is not null` — 排除无年龄标签用户
- `predict_ip_city is not null` — 排除无IP城市用户

## All Columns

> 注意: 未在代码库中找到 CREATE TABLE DDL，以下列为从 SQL 查询中观察到的字段。类型为推测值，准确类型需运行 --source from-di 补充。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户ID | - | - |
| predict_age_group | int | 预测年龄组 (1=18-24, 2=25-34, 3/4=35+) | - | - |
| predict_gender | string | 预测性别 (Male/Female) | - | - |
| predict_income_level | string | 预测收入水平 | - | - |
| predict_ip_city | string | 预测IP所在城市 | - | - |
| grass_region | string [PARTITION] | 区域分区列 | - | - |
| grass_date | date [PARTITION] | 日期分区列 | - | - |
