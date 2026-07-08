<!-- ads-workspace-gdoc-sync: gdoc_id=1glE97JAviijNt6ax7c8O27JQj5JXxOdkTYk9wjrD0qI gdoc_url=https://docs.google.com/document/d/1glE97JAviijNt6ax7c8O27JQj5JXxOdkTYk9wjrD0qI/edit -->

# Columns: mp_mgmt.dws_order_item_rebate_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未从代码库中识别到 SUM(DISTINCT) 模式，该表所有字段均可直接 SUM。

### 枚举值映射 (Value Mappings)

未从代码库中识别到重复出现的 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 30-day rolling window (`date('${grass_date_30day}')` to `date('${grass_date}')`)
  - regional variant 额外使用 `regional_create_date` 过滤 (`>= ${grass_date_30day}`, `< date_add(${grass_date}, 1)`)
- `grass_region`: 标准 9 区，`upper('${region}')` ('ID','MY','PH','SG','TH','TW','VN','BR','MX')
- `is_bi_excluded_rev_prm`: 固定 `= 0`，排除 BI 标记为需要过滤的 rev/prm 数据

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | - | 分区日期 | - | - |
| grass_region | - | 地区 | - | - |
| order_id | - | 订单 ID | - | - |
| item_id | - | 商品 ID | - | - |
| model_id | - | 型号 ID | - | - |
| group_id | - | 团购 ID | - | - |
| bundle_order_item_id | - | 捆绑商品订单项 ID | - | - |
| is_bi_excluded_rev_prm | - | BI 排除标记 (1=排除) | - | - |
| regional_create_date | - | 地区创建日期 (用于时间对齐) | - | - |
| estimate_net_total_item_voucher_logst_prm_usd_level1 | - | Item Voucher + Logistics PRM 净额 (不含 3PL Margin) | - | - |
| estimate_net_total_logst_prm_usd_level1 | - | 纯 Logistics PRM 净额 | - | - |
| estimate_net_total_item_card_prm_usd_level1 | - | Item Card PRM 净额 | - | - |
| estimate_net_total_voucher_prm_usd_level1 | - | Voucher PRM 净额 | - | - |
| estimate_net_total_coin_prm_usd_level1 | - | Coin PRM 净额 | - | - |
