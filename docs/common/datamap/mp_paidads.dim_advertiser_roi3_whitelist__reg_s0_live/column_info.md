<!-- ads-workspace-gdoc-sync: gdoc_id=1TMq9Jh3OTct3HfZfAvazR0873hIdZxqBwK4jYTSGjP4 gdoc_url=https://docs.google.com/document/d/1TMq9Jh3OTct3HfZfAvazR0873hIdZxqBwK4jYTSGjP4/edit -->

# Columns: mp_paidads.dim_advertiser_roi3_whitelist

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为维度表，无累加指标列。

### 枚举值映射 (Value Mappings)

本表列均为原始值，无 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 固定 `'local'`（写入和查询均使用此值）
- `grass_region`: 标准 8 区 ('TH','VN','BR','TW','ID','MY','MX','SG')；ID 在某些预算控制场景下被排除
- `grass_date`: 通常为 date('${BIZ_YESTERDAY}') 或 date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')
- `shop_id`: 常见排除 `!= 13454791`（某个特定 shop，约 80%+ 查询会过滤）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | ROI3 白名单广告主店铺 ID | - | - |
| whitelist_date | date | 最早加入 ROI3 白名单的日期 | - | - |
| tz_type | string | [PARTITION] 时区类型，固定 'local' | - | - |
| grass_region | string | [PARTITION] 区域（国家代码: TH/VN/BR/TW/ID/MY/MX/SG） | - | - |
| grass_date | date | [PARTITION] 数据日期，T+1 产出 | - | - |
