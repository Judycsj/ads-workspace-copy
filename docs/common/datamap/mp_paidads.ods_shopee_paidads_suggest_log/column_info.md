<!-- ads-workspace-gdoc-sync: gdoc_id=1OcxHoKpDnPkuzmPcNZ9oUJTjRo5a4-3xaPKg5IQxwk8 gdoc_url=https://docs.google.com/document/d/1OcxHoKpDnPkuzmPcNZ9oUJTjRo5a4-3xaPKg5IQxwk8/edit -->

# Columns: mp_paidads.ods_shopee_paidads_suggest_log

## Column Usage Notes

### 价格字段转换公式

- `price` 为本地货币 * 100000，显示出价用 `price * 1.0 / 100000`
- extinfo_v2 内 `$.bid_price_extinfo.*` 中 bid_price_for_impr / bid_price_for_order / item_price 同理需 `/ 100000`

### JSON 字段解析 (extinfo_v2)

extinfo_v2 包含 bid_price_extinfo 子对象，通过 `json_extract_scalar` 提取:

```sql
CAST(json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.ecr') AS double) AS ecr
CAST(json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.item_price') AS bigint) * 1.0 / 100000 AS item_price
CAST(json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.target_cir') AS double) AS target_cir
CAST(json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.bid_price_for_impr') AS bigint) * 1.0 / 100000 AS bid_price_for_impr
CAST(json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.bid_price_for_order') AS bigint) * 1.0 / 100000 AS bid_price_for_order
```

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| stage | 0 | Suggest bid (建议出价) |
| stage | 1 | Applied bid (实际应用出价) |
| bid_version | v1 | 旧版 suggest bid 算法 |
| bid_version | v2 | 新版 suggest bid 算法 |
| placement | 0 | Search Ads 搜索广告 |
| page | 0 | 旧版页面 |
| page | 5 | 新版页面 |
| is_already_applied | 0 | 未被应用 |
| is_already_applied | 1 | 已被应用 |
| use_default_price | 0 | 使用 suggested price |
| use_default_price | 1 | 使用 default price |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID' (最多) / 'TW' / 'SG' / 'MY' / 'TH' / 'VN' / 'PH' / 'BR' / 'MX' / 'CO' / 'CL'
- `placement`: 0 (所有查询都用 0 — Search Ads)
- `stage`: 0 (suggest bid 分布分析) / 1 (applied bid 效果分析)
- `bid_version`: 'v1' / 'v2'
- `tz_type`: 'local' (ROI3 分析场景) / 'regional'
- `price`: 20000000 (ID 最小 bid 检测) / 100000 (TW 最小 bid) / 40000000 (VN) / 4000 (SG) / 6000 (MY) / 40000 (PH) / 11000 (BR)
- `page`: 5 (新版页面 applied bid) / 0 (旧版)
- `keyword`: IN 列表常用于特定关键词排查
- `mod(shop_id, 241)` 条件用于 whitelist 灰度分桶

<!-- ANALYSIS_PLACEHOLDER -->

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 | - | - |
| grass_region | string | 分区地区 | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| ads_id | bigint | 广告 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| keyword | string | 关键词 | - | - |
| query | string | 搜索 query | - | - |
| bid_version | string | 出价版本 (v1/v2) | - | - |
| stage | int | 出价阶段 (0=suggest, 1=applied) | - | - |
| page | int | 页面版本 (0/5) | - | - |
| placement | int | 广告位 (0=Search Ads) | - | - |
| price | bigint | 出价价格 (本地货币*100000) | - | - |
| extinfo_v2 | string | JSON 扩展信息 (bid_price_extinfo) | - | - |
| event_datetime | timestamp | 事件时间 | - | - |
| is_already_applied | int | 是否已被卖家应用 (0/1) | - | - |
| use_default_price | int | 是否使用默认价格 (0/1) | - | - |
| tz_type | string | 时区类型 (local/regional) | - | - |
