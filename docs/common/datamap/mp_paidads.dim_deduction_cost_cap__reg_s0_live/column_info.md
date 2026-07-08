<!-- ads-workspace-gdoc-sync: gdoc_id=1XWDIS-pr4yhhGPdYahyC6etju6wuJElxZr1-goA_OYk gdoc_url=https://docs.google.com/document/d/1XWDIS-pr4yhhGPdYahyC6etju6wuJElxZr1-goA_OYk/edit -->

# Columns: mp_paidads.dim_deduction_cost_cap__reg_s0_live

*DDL not found in codebase; columns inferred from JOIN/WHERE usage patterns.*

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| date_type | campaign_day | 广告计划日（每月15日、25日、月末最后一天） |
| date_type | normal_day | 普通日（非计划日） |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') — 8 区标准地域 ('ID','MY','PH','SG','TH','TW','VN','BR')

### 类型转换提示

该表的 pricing_type、placement、cost_cap_max 列在 JOIN 时需要 CAST：
- `CAST(b.pricing_type AS INT)` — 与扣费流水的 pricing_type (int) 匹配
- `CAST(b.placement AS INT)` — 与扣费流水的 placement (bigint) 匹配
- `CAST(b.cost_cap_max AS DOUBLE)` — 用于数值比较（单位：本地货币 x 10^5）

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | string | 地域分区键 | - | - |
| pricing_type | string | 计费类型（扣费维度） | - | - |
| placement | string | 广告位（扣费维度） | - | - |
| date_type | string | 日期类型：campaign_day / normal_day | - | - |
| cost_cap_max | string | 单次扣费金额上限（本地货币单位） | - | - |
