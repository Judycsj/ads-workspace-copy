<!-- ads-workspace-gdoc-sync: gdoc_id=1-07WB8Mz7NhJzeFtbaRIFxGNJ_jx67pAVtPBA2_uG50 gdoc_url=https://docs.google.com/document/d/1-07WB8Mz7NhJzeFtbaRIFxGNJ_jx67pAVtPBA2_uG50/edit -->

# Columns: mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。所有指标字段均为可累加（每日明细级别），无 SUM(DISTINCT) 或 MAX 限制。

- `hit_total_budget` / `hit_daily_budget` 为 tinyint (0/1)，应通过 SUM 聚合统计撞线 campaign 数
- `total_quota_local` / `total_deduction` 为 campaign 级别的累计值，跨 campaign 聚合可直接 SUM

### 枚举值映射 (Value Mappings)

无。表中无 CASE-WHEN 枚举映射列。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (绝大多数查询使用 local 时区)
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR') + 'MX'
- `grass_date`: 按日分区，支持范围查询
- `daily_quota_local > 0`: 过滤有限预算 campaign（排除无限预算）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| campaign_id | bigint | campaign_id | - | - |
| total_quota_local | double | total_quota_local | - | - |
| total_deduction | double | total_deduction | - | - |
| hit_total_budget | tinyint | hit_total_budget | - | - |
| daily_quota_local | double | daily_quota_local | - | - |
| daily_deduction | double | daily_deduction | - | - |
| hit_daily_budget | tinyint | hit_daily_budget | - | - |
| tz_type | string | tz_type [PARTITION] | - | - |
| grass_region | string | grass_region [PARTITION] | - | - |
| grass_date | DATE | grass_date [PARTITION] | - | - |
