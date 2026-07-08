<!-- ads-workspace-gdoc-sync: gdoc_id=1n_kRm3jjvdMgAfHhzWKRlgElmQ5XmQeMbXaeSN8_GT4 gdoc_url=https://docs.google.com/document/d/1n_kRm3jjvdMgAfHhzWKRlgElmQ5XmQeMbXaeSN8_GT4/edit -->

# Columns: mp_paidads.dim_advertiser_tier_threshold__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

*来自 SQL 代码中的 CASE-WHEN 提取（40个文件一致）*

| Column | Value | Meaning |
|--------|-------|---------|
| advertiser_tier | large_advertiser | 大广告主 |
| advertiser_tier | medium_advertiser | 中广告主 |
| advertiser_tier | small_advertiser | 小广告主 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') — 按站点区分，覆盖 ID, MY, PH, SG, TH, TW, VN, BR, MX 9个地区

### 业务语义说明

- `min_value_usd` 为对应 tier 的最小花费阈值（USD）。广告主的实际花费与阈值比较后确定其层级。
- 该表为非分区维度表（按 grass_region 过滤，无 grass_date 分区），与 `dim_seller_tier_threshold__reg_s0_live` 结构对称。
- 使用模式：`MAX(CASE WHEN advertiser_tier = 'xxx' THEN min_value_usd END)` 将行转列，提取各层级阈值后在 JOIN 中使用。

## All Columns

*从 SQL 代码推理的列名和类型；DDL 未在代码库中找到*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| advertiser_tier | string | 广告主层级名称 | - | - |
| min_value_usd | double | 该层级最低花费阈值（USD） | - | - |
| grass_region | string | 站点/地区 | - | - |
