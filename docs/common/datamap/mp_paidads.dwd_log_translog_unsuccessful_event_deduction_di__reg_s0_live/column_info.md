<!-- ads-workspace-gdoc-sync: gdoc_id=1G_fLkILF3NIPfjcl10UXMuMAcuSaK2TyeEPzHYPt0I8 gdoc_url=https://docs.google.com/document/d/1G_fLkILF3NIPfjcl10UXMuMAcuSaK2TyeEPzHYPt0I8/edit -->

# Columns: mp_paidads.dwd_log_translog_unsuccessful_event_deduction_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `price` — 单条预期扣费金额（本地货币，分），跨 event 聚合时需按业务逻辑 SUM 或取条件聚合
- `adjusted_cost` — 单条实际调整后成本，不可直接跨维度累加

### 常见 WHERE 值 (Common Filter Values)

- `deduct_type`: 1 (CPC 扣费失败) / 2 (CPM 扣费失败) — CPC 场景通常只取 `= 1`
- `pricing_type`:
  - 排除 Manual/Live Ads: `not in (5, 6, 9, 10, 14)` — 用于 Product Ads 收入归因
  - Search Ads: `in (11, 15, 24, 25, 27)` — 用于 Search Ads AB 实验分析
- `status`: `<> 1` 或 `(= 1 AND campaign_balance_by_date.daily_balance = daily_quota)` — 区分"扣费失败"与"余额不足的扣费失败"

### 金额单位说明

- `price` 和 `adjusted_cost` 以本地货币**分**为单位存储
- 转 USD: `(price - adjusted_cost) / 100000.0 / nullif(exchange_rate, 0)` — 除以 100000（分化成元/标准单位），再除以汇率

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | string | 数据日期（分区列） | - | - |
| grass_region | string | 站点（分区列） | - | - |
| user_id | string | 商家用户 ID | - | - |
| campaign_id | string | 广告计划 ID | - | - |
| shop_id | string | 店铺 ID | - | - |
| pricing_type | int | 出价类型 | - | - |
| deduct_type | int | 扣费类型: 1=CPC, 2=CPM | - | - |
| entrance | int | 入口点 | - | - |
| placement | int | 广告位 | - | - |
| price | bigint | 预期扣费金额（本地货币分） | - | - |
| adjusted_cost | bigint | 实际调整后成本（本地货币分） | - | - |
| status | int | 扣费状态: 1=正常/其他=失败 | - | - |
| campaign_balance_by_date | struct | 计划当日余额信息，含 daily_balance | - | - |
| daily_quota | bigint | 当日预算配额 | - | - |
