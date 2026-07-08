<!-- ads-workspace-gdoc-sync: gdoc_id=1h2Cj0ELN6lYCGijbot7xmR03O7A5LuLJIoW5DAFliIY gdoc_url=https://docs.google.com/document/d/1h2Cj0ELN6lYCGijbot7xmR03O7A5LuLJIoW5DAFliIY/edit -->

# Columns: mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `start_of_day_balance`, `start_of_day_balance_usd`: 这些是账户在当日开始时的快照值（余额），不能跨天直接 SUM 聚合。跨天查询应取最新日期的值。
- `end_of_day_balance`, `end_of_day_balance_usd`: 这些是账户在当日结束时的快照值（余额），不能跨天直接 SUM 聚合。跨天查询应取最新日期的值。

余额字段的正确使用方式：
- 单日查询：直接取 `start_of_day_balance` / `end_of_day_balance`
- 跨天趋势：按 `dt` GROUP BY 后取每天的余额值，不可 SUM
- 余额变化量：`end_of_day_balance - start_of_day_balance` 可反映当天的净变化

### 汇率转换说明

所有 `_usd` 后缀字段（`top_up_amount_usd`, `start_of_day_balance_usd`, `end_of_day_balance_usd`）通过 `原币金额 / exchange_rate` 计算得出，汇率来自 `mp_order.dim_exchange_rate__reg_s0_live`（取 `${yesterday}` 的汇率）。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| order_type | (int) | Credit order type, from upstream `ads_credit_tab.order_type` |
| main_type | (int) | Credit top-up main type, from upstream `ads_credit_tab.main_type` |

注：order_type 和 main_type 的具体枚举值定义在上游表 `mp_paidads.shopee_ads_*_shard_db__ads_credit_tab__reg_continuous_s0_live` 中，本表未在代码中枚举其含义。

### 常见 WHERE 值 (Common Filter Values)

- `dt`: `"${yesterday}"` (生产写入), `"9999-01-01"` (临时 SOD 分区), `'${grass_date}'` (查询)
- `grass_region`: 覆盖 11 个区域 — `('SG','MY','PH','TW','TH','VN','ID','BR','AR','CO','CL','MX')`
  - UTC+8: `SG`, `MY`, `PH`, `TW`
  - UTC+7: `TH`, `VN`, `ID`
  - UTC-3: `AR`, `BR`
  - UTC-5: `CO`
  - UTC-6: `MX`
  - UTC-4: `CL`
- `order_id IS NOT NULL` / `order_id IS NULL`: 区分信用订单记录（有 order_id）和纯账户余额快照记录（无 order_id）

### 生产两步写入策略

该表采用 SOD/EOD 两步写入：

1. **SOD（Start of Day）**: 在 T 日的 H+1 时刻运行，将 T 日的 start_of_day_balance 写入临时分区 `dt="9999-01-01"`。数据来源：
   - `ads_credit` 表: 过去的所有 credit 订单（含 order_id）
   - `ads_account` 表: 当前账户余额（无 order_id）
   - 转换为 USD 金额后写入

2. **EOD（End of Day）**: 在 T+1 日的 H+0 时刻运行，读取 `dt="9999-01-01"` 分区的 SOD 数据，与当日最新的 `ads_credit`/`ads_account` 数据合并计算 end_of_day_balance，最终写入正式日期分区 `dt="${yesterday}"`。

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 广告主/用户 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| order_id | bigint | 信用订单 ID（账户余额行此值为 NULL） | - | - |
| order_type | bigint | 信用订单类型 | - | - |
| main_type | bigint | 信用充值主类型 | - | - |
| credit_expiry_time | bigint | 信用过期时间（unix timestamp），来自 ads_credit_tab.end_time；已过期的在 SOD/EOD 中 balance 置为 0 | - | - |
| top_up_amount | decimal(25,10) | 充值金额（当地货币），来自 ads_credit_tab.amount | - | - |
| top_up_amount_usd | decimal(25,10) | 充值金额（USD），= top_up_amount / exchange_rate | - | - |
| start_of_day_balance | decimal(25,10) | 当日起始余额（当地货币） | - | - |
| start_of_day_balance_usd | decimal(25,10) | 当日起始余额（USD），= start_of_day_balance / exchange_rate | - | - |
| end_of_day_balance | decimal(25,10) | 当日结束余额（当地货币） | - | - |
| end_of_day_balance_usd | decimal(25,10) | 当日结束余额（USD），= end_of_day_balance / exchange_rate | - | - |
| dt | string | 日期分区 [PARTITION] | - | - |
| grass_region | string | 区域分区 [PARTITION] | - | - |

<!-- ANALYSIS_PLACEHOLDER -->
