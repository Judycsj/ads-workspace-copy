<!-- ads-workspace-gdoc-sync: gdoc_id=1NXHiBj10_SxvqdWBU-AXJXdRg3Q8KQKrfpIjPRU8nXE gdoc_url=https://docs.google.com/document/d/1NXHiBj10_SxvqdWBU-AXJXdRg3Q8KQKrfpIjPRU8nXE/edit -->

# Columns: mkplpaidads_search_ads.ods_brand_ads_search_volume_imp_cnt

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。`imp_count` 是按 `grass_date x grass_region` 粒度聚合后的值，跨区域/日期聚合时可直接用 `SUM()`。

### 枚举值映射 (Value Mappings)

无。该表仅包含数值型流量指标，无枚举维度列。

### 常见 WHERE 值 (Common Filter Values)

- **`grass_region`**:
  - `('ID','TH','PH','VN','TW','SG','MY','BR')` — 8 个标准区域 (~80% 查询)
  - `('ID', 'TH', 'PH', 'VN', 'TW', 'SG', 'MY')` — 7 区域（不含 BR，用于非 US 场景）
  - `('BR')` — 仅巴西（用于 budget2order_gmv_us 场景）
  - 动态参数: `in ({REGIONS_SQL})` (reward_cali_data)
- **`grass_date`**:
  - 范围查询: `grass_date >= date_sub(current_date, N) AND grass_date <= date_sub(current_date, M)` (~60% 查询)
  - 模板变量: `grass_date >= "${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-30d')}"` (workflow 调度)
  - `BETWEEN date(...) AND date(...)` (subsidy target)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| imp_count | bigint | 每日每区域自然搜索曝光总量（count(*) from raw traffic） | - | - |
| grass_date | string | 日期分区 (yyyy-MM-dd) | - | - |
| grass_region | string | 区域分区 (ID/TH/PH/VN/TW/SG/MY/BR) | - | - |
