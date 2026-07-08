<!-- ads-workspace-gdoc-sync: gdoc_id=1YjsLwCHv_jwL2ZMTBFG0n8l5TbVt2qBI8W9jbJbp2xo gdoc_url=https://docs.google.com/document/d/1YjsLwCHv_jwL2ZMTBFG0n8l5TbVt2qBI8W9jbJbp2xo/edit -->

# mp_paidads.dws_advertiser_topup_1d

**分层**：DWS（数据汇总层）
**主键**：`seller_id`（即 `user_id`）、`shop_id`、`tz_type`、`grass_region`、`grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：130 次（候选表范围内）

---

## 业务描述

本表以**广告主（seller）× 店铺（shop）× 日期**为粒度，汇总各地区广告主在单日内的广告余额充值行为，包括充值总金额、各类充值方式（手动、自动、正常、SRM 激励、Seller Mission）、充值次数、首次/最近充值时间戳，以及按信用额类型（付费/免费、有效期有无）拆分的充值金额。

本表是广告变现域充值分析的核心宽表，广泛用于：广告主充值健康度监控、充值漏斗分析、SRM 系统激励效果评估、广告预算规划报表、以及广告主生命周期（首次充值节点）挖掘等场景。下游引用频次高达 130 次，是 Paid Ads 数仓中使用最频繁的 DWS 层表之一。

ETL 支持 `local`（按各地区本地日期）和 `regional`（按新加坡时区）双时区视角，满足不同报表口径的查询需求。各地区通过参数化调度覆盖，时区随地区配置自动对应，无需手工切换。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。`local` = 按本地时区统计当日数据；`regional` = 按新加坡时区（SGT）统计当日数据。⚠️ 查询时**必须**指定该分区，否则同一笔充值会被重复计算（double counting） |
| `grass_region` | string | 地区分区，如 `TW`、`ID`、`MY` 等，存储为大写。⚠️ 查询时**必须**指定，避免全表扫描跨地区读取 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`。⚠️ 查询时**必须**指定，避免全表扫描 |

---

### 维度：主键与广告主属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_id` | bigint | 广告主 ID（对应 ETL 中的 `user_id`） |
| `shop_id` | bigint | 店铺 ID |

---

### 指标：充值总量

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_topup_amt` | double | 当日充值总金额（本地货币），含所有类型充值 |
| `total_topup_amt_usd` | double | 当日充值总金额（USD） |
| `topup_times_cnt` | bigint | 当日充值总次数，基于 `order_id` 去重计数，含自动、手动、正常等所有类型 |

---

### 指标：手动充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `manual_topup_amt` | double | 手动充值总金额（本地货币，`order_type=3`） |
| `manual_topup_amt_usd` | double | 手动充值总金额（USD） |
| `manual_topup_times_cnt` | bigint | 手动充值次数，基于 `order_id` 去重计数 |
| `manual_free_credit_topup_amt` | double | 手动充值中免费信用额金额（本地货币，`credit_topup_type` in 3,4） |
| `manual_free_credit_topup_amt_usd` | double | 手动充值中免费信用额金额（USD） |
| `manual_paid_credit_topup_amt` | double | 手动充值中付费信用额金额（本地货币，`credit_topup_type` in 1,2） |
| `manual_paid_credit_topup_amt_usd` | double | 手动充值中付费信用额金额（USD） |

---

### 指标：自动充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_topup_amt_local` | double | 自动充值总金额（本地货币，`order_type=4`） |
| `auto_topup_amt_usd` | double | 自动充值总金额（USD） |
| `auto_topup_times_cnt` | bigint | 自动充值次数，基于 `order_id` 去重计数 |

---

### 指标：正常充值（Normal Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `normal_amt_local` | double | 正常充值总金额（本地货币，`order_type` in 2,6） |
| `normal_amt_usd` | double | 正常充值总金额（USD） |
| `normal_topup_times_cnt` | bigint | 正常充值次数，基于 `order_id` 去重计数 |
| `normal_svs_topup_amt_local` | double | 通过 Shopee App 平台（SVS 渠道，`order_type=6`）的正常充值金额（本地货币） |
| `normal_svs_topup_amt_usd` | double | 通过 Shopee App 平台（SVS 渠道）的正常充值金额（USD） |
| `normal_order_topup_amt_local` | double | 通过 Shopee Mall 信用额（`order_type=2`）的正常充值金额（本地货币） |
| `normal_order_topup_amt_usd` | double | 通过 Shopee Mall 信用额的正常充值金额（USD） |

---

### 指标：SRM 激励充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `srm_topup_amt` | double | SRM 系统触发的 QSS（Quick Sales Solution）充值金额（本地货币，`order_type=9`） |
| `srm_topup_amt_usd` | double | SRM QSS 充值金额（USD） |
| `srm_topup_times_cnt` | bigint | SRM 充值次数，基于 `order_id` 去重计数 |
| `seller_mission_topup_amt` | double | SRM 系统触发的 Seller Mission 充值金额（本地货币，`order_type=8`） |
| `seller_mission_topup_amt_usd` | double | SRM Seller Mission 充值金额（USD） |

---

### 指标：负向充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `neg_topup_amt` | double | 负向充值金额（本地货币，`order_type=10`），代表退款/冲销等反向操作，值通常为负数 |
| `neg_topup_amt_usd` | double | 负向充值金额（USD） |

---

### 指标：按信用额类型（付费/免费 × 有无有效期）拆分

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_wo_expiry_topup_amt_local` | double | 付费且无过期时间的充值金额（本地货币，`credit_topup_type=1`） |
| `paid_wo_expiry_topup_amt_usd` | double | 付费且无过期时间的充值金额（USD） |
| `paid_w_expiry_topup_amt_local` | double | 付费且有过期时间的充值金额（本地货币，`credit_topup_type=2`） |
| `paid_w_expiry_topup_amt_usd` | double | 付费且有过期时间的充值金额（USD） |
| `free_wo_expiry_topup_amt_local` | double | 免费且无过期时间的充值金额（本地货币，`credit_topup_type=3`） |
| `free_wo_expiry_topup_amt_usd` | double | 免费且无过期时间的充值金额（USD） |
| `free_w_expiry_topup_amt_local` | double | 免费且有过期时间的充值金额（本地货币，`credit_topup_type=4`） |
| `free_w_expiry_topup_amt_usd` | double | 免费且有过期时间的充值金额（USD） |

---

### 指标：充值时间戳

| 字段 | 类型 | 说明 |
|------|------|------|
| `first_topup_timestamp` | bigint | 广告主当日所有类型充值中最早一笔的时间戳（Unix 秒级）。⚠️ 为当日 MIN 值，不代表历史首次充值 |
| `last_topup_timestamp` | bigint | 广告主当日所有类型充值中最晚一笔的时间戳（Unix 秒级）。⚠️ 同上，仅为当日 MAX 值 |
| `first_manual_topup_timestamp` | bigint | 当日手动充值中最早一笔的时间戳（Unix 秒级）。⚠️ 仅为当日范围内 MIN |
| `last_manual_topup_timestamp` | bigint | 当日手动充值中最晚一笔的时间戳（Unix 秒级） |
| `first_auto_topup_timestamp` | bigint | 当日自动充值中最早一笔的时间戳（Unix 秒级）。⚠️ 仅为当日范围内 MIN |
| `last_auto_topup_timestamp` | bigint | 当日自动充值中最晚一笔的时间戳（Unix 秒级） |
| `first_normal_topup_timestamp` | bigint | 当日正常充值中最早一笔的时间戳（Unix 秒级）。⚠️ 仅为当日范围内 MIN |
| `last_normal_topup_timestamp` | bigint | 当日正常充值中最晚一笔的时间戳（Unix 秒级） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，遗漏任意一个将触发全分区扫描，导致查询超时或费用激增：

| 分区字段 | 推荐写法示例 | 遗漏后果 |
|----------|------------|---------|
| `tz_type` | `tz_type = 'local'` | 同一笔充值被 `local` 和 `regional` 两个分区各计一次，导致金额/次数双倍 |
| `grass_region` | `grass_region = 'ID'` | 跨所有地区全量扫描，查询极慢且结果混杂多地区数据 |
| `grass_date` | `grass_date = '2025-04-01'` | 读取全历史数据，查询超时且结果无意义 |

> **`tz_type` 选择建议**：业务报表以本地日历为准时使用 `local`；需要与新加坡总部时区对齐时使用 `regional`。两者**不可混合 SUM**，必须在同一查询中固定一个值。

---

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确使用方式 |
|------|---------|------------|
| 所有 `*_timestamp` 字段（8 个） | 存储的是当日 MIN/MAX 时间戳，多行直接聚合无业务意义 | 若需跨多日的"首次充值"，应取 `MIN(first_topup_timestamp)`；最近充值取 `MAX(last_topup_timestamp)` |
| `neg_topup_amt` / `neg_topup_amt_usd` | 值本身为负数，与其他正向充值字段混合 SUM 时会自动抵消；若单独分析退款规模需取绝对值 | 分析净充值时：`total_topup_amt + neg_topup_amt`（已含符号）；分析退款规模时：`ABS(neg_topup_amt)` 或 `SUM(neg_topup_amt) * -1` |
| `manual_free_credit_topup_amt` + `manual_paid_credit_topup_amt` | 两者之和应等于 `manual_topup_amt`；若直接对外层再 SUM 须确认粒度一致 | 加总验证：`manual_free_credit_topup_amt + manual_paid_credit_topup_amt = manual_topup_amt` |

---

### 时效性说明

- 本表按**日调度（T+1）**写入，`grass_date = T` 的数据在 T+1 日调度完成后可用。
- 所有时间戳字段（`first_*_timestamp`、`last_*_timestamp`）仅反映**当日分区内**的最早/最晚充值，**不代表广告主历史生命周期中的首次/最近充值**。若需计算历史首次充值时间，需跨日期分区取全历史最小值，建议基于 `mp_paidads.dwd_advertiser_credit_topup_df` 明细层直接计算，或取本表历史分区的 `MIN(first_topup_timestamp)`。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主充值明细事实表（DWD 层），提供逐笔充值记录，包括 `order_type`、`credit_topup_type`、`topup_amt`、`topup_amt_usd`、`topup_create_timestamp` 等核心字段 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
              │
              │  WHERE grass_region = upper('${region}')
              │        AND grass_date = '${grass_date}'
              │
     ┌────────┴─────────┐
     │                  │
  tz_type='local'   tz_type='regional'
  按本地日期过滤       按 SGT 时间戳过滤
  (topup_create_       (from_unixtime(
   datetime 日期         topup_create_timestamp)
   = grass_date)         日期 = grass_date)
     │                  │
     └────────┬─────────┘
              │ UNION ALL
              ▼
          base (临时视图)
    [按 tz_type, shop_id, user_id, grass_region 聚合]
    - SUM 各类型充值金额（本地 & USD）
    - COUNT DISTINCT order_id → 各类充值次数
    - MIN/MAX topup_create_timestamp → 首次/最近时间戳
    - 按 credit_topup_type 拆分四类信用额金额
              │
              ▼
  dws_advertiser_topup_1d__reg_s0_live
  PARTITION (tz_type, grass_region, grass_date)
  [INSERT OVERWRITE，按地区 & 日期全量覆盖写入]
```

### 关键 CTE 说明

| CTE/视图 | 来源表 | 作用 |
|----------|--------|------|
| `base` | `dwd_advertiser_credit_topup_df__reg_s0_live` | 将 `local` 和 `regional` 两个时区视角通过 UNION ALL 合并为统一明细集，同时派生 `topup_category_name`（按 `order_type` 映射充值类型标签：normal / negative / srm / auto / sellermission / manual） |

### 注意事项

1. **双时区 UNION 带来的数据量翻倍**：`base` 视图通过 `UNION ALL` 合并两套口径，同一笔充值记录在底层各出现一次，分别打上 `local` 和 `regional` 标签。查询本表时**必须过滤 `tz_type`**，否则所有金额和次数都会被翻倍统计。

2. **`order_type` 映射规则**：ETL 中 `topup_category_name` 的映射为：
   - `order_type in (2, 6)` → `normal`
   - `order_type = 10` → `negative`
   - `order_type = 9` → `srm`
   - `order_type = 4` → `auto`
   - `order_type = 8` → `sellermission`
   - `order_type = 3` → `manual`
   - 其他 → `NULL`（不归入任何分类，但仍计入 `total_topup_amt`）

3. **`credit_topup_type` 与充值性质**：
   - `1` = 付费、无有效期
   - `2` = 付费、有有效期
   - `3` = 免费、无有效期
   - `4` = 免费、有有效期

4. **`regional` 时区 SQL 注释**：ETL 中 `regional` 分支存在注释 `-- should use sg timezone?`，说明该分支的时区逻辑（使用 `from_unixtime` 转换后按 SGT 日期过滤）**曾存在争议**，使用 `regional` 分区数据时需关注是否符合业务预期口径。

5. **参数化调度**：`${region}`、`${grass_date}` 均为调度系统注入的运行时参数，本表通过统一模板覆盖所有支持地区，各地区按本地时区参数化调度，非单地区表。

6. **`neg_topup_amt` 已含符号**：负向充值金额在 ETL 中直接 SUM，值本身为负。计算净充值额时无需额外取反，直接 `total_topup_amt + neg_topup_amt` 即可（实为 `total_topup_amt - |neg_topup_amt|`）。

---

*文档生成时间：2026-04-22*