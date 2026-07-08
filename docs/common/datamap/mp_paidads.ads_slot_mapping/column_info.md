<!-- ads-workspace-gdoc-sync: gdoc_id=1r1GdbkhIPNUKsvkMtsEkQxwuMQGdR_l1j-EldIk6GNM gdoc_url=https://docs.google.com/document/d/1r1GdbkhIPNUKsvkMtsEkQxwuMQGdR_l1j-EldIk6GNM/edit -->

# Columns: mp_paidads.ads_slot_mapping

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未从代码中识别出非累加字段。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0 | Search |
| placement | 2 | Daily Discover |
| placement | 5 | You May Also Like |
| platform | mobile | 移动端 |

### 常见 WHERE 值 (Common Filter Values)

- `placement`: 0 (Search 场景，fill rate workflow)
- `platform`: 'mobile' (移动端)
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')
- `grass_date`: 取 max(grass_date) 最新分区

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 [PARTITION] | - | - |
| grass_region | string | 站点 | - | - |
| placement | int | 广告位类型 (0=Search, 2=Daily Discover, 5=You May Also Like) | - | - |
| platform | string | 平台 (mobile) | - | - |
| location | bigint | 页面位置编号 (0-300) | - | - |
