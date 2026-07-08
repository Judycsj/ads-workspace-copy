<!-- ads-workspace-gdoc-sync: gdoc_id=1MMKVs15_73Dt9659F-LCNeu3lHMtn9JYXxhFuYw7UJc gdoc_url=https://docs.google.com/document/d/1MMKVs15_73Dt9659F-LCNeu3lHMtn9JYXxhFuYw7UJc/edit -->

# Columns: mp_paidads.dws_advertise_activeness_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。所有字段均为维度或日期类型，可直接使用。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement (上游 dim_advertise) | 0 | MM Keyword Ads (Myanmar Marketing) |
| placement (上游 dim_advertise) | 4 | SM Keyword Ads (Search Marketing) |
| placement (上游 dim_advertise) | 1000 | Boost Keyword Ads |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (所有数据均为 local 时区)
- `grass_region`: 标准 11 区 ('VN','TW','TH','SG','PH','MY','MX','ID','CO','CL','BR')

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | BIGINT | id for ads | - | - |
| shop_id | BIGINT | shopid | - | - |
| user_id | BIGINT | userid (seller_id) | - | - |
| first_mm_kw_ads_active_date | DATE | 首次 Myammar Marketing 关键词广告激活日期 | - | - |
| first_sm_kw_ads_active_date | DATE | 首次 Search Marketing 关键词广告激活日期 | - | - |
| tz_type | STRING | 时区类型 | - | - |
| grass_region | STRING | 地区 | - | - |
| grass_date | DATE | 分区日期 | - | - |
