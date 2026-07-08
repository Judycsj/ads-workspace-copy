<!-- ads-workspace-gdoc-sync: gdoc_id=13_a0EPO5VTJ75U-gSWX9ZoOM_mmj-CPhTfLOgkOWNyw gdoc_url=https://docs.google.com/document/d/13_a0EPO5VTJ75U-gSWX9ZoOM_mmj-CPhTfLOgkOWNyw/edit -->

# Columns: mkplpaidads_discovery_ads.discover_ads_target_cir_with_search

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表以 daily x placement x category 为粒度，各 target_cir 列均为比率值，跨 placement/类目聚合时应使用 AVG 或按对应 order 列加权平均，不可直接 SUM。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 802 | Discovery Ads (Simplified) |
| placement | 805 | Discovery Ads (YMAL/DD) |
| placement | 2 | Discovery legacy (mapped to 802) |
| placement | 5 | Discovery legacy (mapped to 805) |
| placement | 0, 4 | Search Ads |

### 常见 WHERE 值 (Common Filter Values)

- `placement`: 802, 805 (Discovery) -- 80%+ 查询；802, 805, 4, 0, 2, 5 (全量 DWS)
- `grass_region`: 'BR','ID','MY','PH','SG','TH','TW','VN' (标准 8 区)
- `version`: '6' (fixed constant in production)
- `grass_date`: `select max(grass_date)` (取最新分区) 或 `between date'...' and date'...'` (date range)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| version | varchar | 版本号 (固定 '6') | - | - |
| placement | bigint | 广告位 (802/805 Discovery, 0/4 Search) | - | - |
| l1_id | bigint | 一级类目 ID | - | - |
| l1_name | varchar | 一级类目名称 | - | - |
| l2_id | bigint | 二级类目 ID | - | - |
| l2_name | varchar | 二级类目名称 | - | - |
| discovery_l1_order | bigint | Discovery L1 类目近 30 天订单数 | - | - |
| discovery_l1_target_cir | double | Discovery L1 类目 target CIR (cost/gmv) | - | - |
| discovery_l2_order | bigint | Discovery L2 类目近 30 天订单数 | - | - |
| discovery_l2_target_cir | double | Discovery L2 类目 target CIR (cost/gmv) | - | - |
| search_l1_order | bigint | Search L1 类目近 30 天订单数 | - | - |
| search_l1_target_cir | double | Search L1 类目 target CIR (cost/gmv) | - | - |
| search_l2_order | bigint | Search L2 类目近 30 天订单数 | - | - |
| search_l2_target_cir | double | Search L2 类目 target CIR (cost/gmv) | - | - |
| final_l1_target_cir | double | 融合后的 L1 target CIR (Discovery+Search 按区域加权) | - | - |
| final_l2_target_cir | double | 融合后的 L2 target CIR (Discovery+Search 按区域加权) | - | - |
| grass_date | date | 数据分区日期 | - | - |
| grass_region | varchar | 国家/区域 (BR/ID/MY/PH/SG/TH/TW/VN) | - | - |
