<!-- ads-workspace-gdoc-sync: gdoc_id=1G1qvdQXXQ84S85IkDn_aq3z2x8kSHu2sq01jbRjsGbk gdoc_url=https://docs.google.com/document/d/1G1qvdQXXQ84S85IkDn_aq3z2x8kSHu2sq01jbRjsGbk/edit -->

# mp_paidads.dws_livestream_revenue_1d

**分层**：DWS（数据汇总层）
**主键**：`ads_id` + `placement` + `campaign_id` + `shop_id` + `target_affiliate_id` + `item_id` + `entrance` + `sub_entrance` + `pricing_type` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1 调度）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表记录**直播广告（Livestream Ads）**维度下，各广告主按天汇总的广告支出明细，涵盖总支出、付费信用额度支出（有/无有效期）与免费信用额度支出（有/无有效期）两大口径，以及本地货币与 USD 双币种金额。表的核心价值在于为直播广告投放效果分析、广告主账单核对、信用额度消耗监控等场景提供统一的日粒度基础数据。

使用场景包括：广告运营日常监控（各广告账户/活动/商品维度的日消耗拆分）、财务结算（区分付费信用与免费信用的支出金额）、以及跨地区汇总分析（通过 `grass_region` 与 `tz_type` 组合筛选）。表按 `tz_type`（时区口径）和 `grass_region`（市场大区）双维度分区，各地区按本地时区参数化调度，确保各市场数据口径一致。

数据来源于 DWD 层直播表现明细表，经过按广告维度聚合、汇率换算（本地币 → USD）后写入，是下游直播广告收入报表和 ADS 层指标的重要数据来源。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区口径类型。`local` 表示按各地区本地时区统计，`regional` 表示按区域时区统计。**每次查询必须指定此字段以避免跨分区全表扫描。** |
| `grass_region` | string | 市场大区代码（大写），如 `SG`、`MY`、`ID` 等。通过调度参数 `${upper_region}` 参数化覆盖所有地区。 |
| `grass_date` | date | 数据日期（本地时区口径），格式 `yyyy-MM-dd`。用于定位每日分区，查询时必须指定。 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一条广告投放记录。 |
| `campaign_id` | bigint | 广告活动 ID，所属推广计划。 |
| `shop_id` | bigint | 店铺 ID，广告主对应的店铺。 |
| `target_affiliate_id` | bigint | 目标联盟 ID（达人/主播 ID），直播带货场景中关联的主播账号。 |
| `item_id` | bigint | 商品 ID，直播中被推广的商品。 |
| `placement` | bigint | 广告版位 ID，标识广告展示的具体位置/版位。 |
| `entrance` | int | 流量入口类型编码，标识用户进入直播间的来源入口。 |
| `sub_entrance` | int | 流量子入口类型编码，对 `entrance` 的进一步细分。 |
| `pricing_type` | int | 计价类型编码，如 CPM、CPC、CPL 等广告计费模式。 |

---

### 指标：总广告支出

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_expenditure_amt_local_1d` | double | 当日广告总支出金额（本地货币），包含付费信用与免费信用支出之和。来源于 DWD 层 `ads_expenditure` 字段直接聚合。 |
| `total_expenditure_amt_usd_1d` | double | 当日广告总支出金额（USD），由 DWD 层 `ads_expenditure_usd` 字段直接聚合得到。 |

---

### 指标：付费信用额度支出

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_wo_expiry_amt_local_1d` | double | 当日**无有效期**付费信用额度支出（本地货币）。原始值以分（/100000）存储，ETL 已换算为标准货币单位。⚠️ 跨行 SUM 可直接使用，但注意 USD 字段由本字段除以汇率得到，跨地区汇总时应使用各地区本地币分别汇总后再换算，避免汇率混用。 |
| `paid_expenditure_wo_expiry_amt_usd_1d` | double | 当日**无有效期**付费信用额度支出（USD），由本地币金额除以当日汇率换算得到。⚠️ 跨地区直接 SUM 时存在汇率口径不一致风险，建议以本地币字段为基础重新换算后汇总。 |
| `paid_expenditure_w_expiry_amt_local_1d` | double | 当日**有有效期**付费信用额度支出（本地货币）。原始值已由 ETL 从分制换算为标准货币单位。 |
| `paid_expenditure_w_expiry_amt_usd_1d` | double | 当日**有有效期**付费信用额度支出（USD），由本地币除以当日汇率换算得到。⚠️ 跨地区直接 SUM 时存在汇率口径不一致风险，建议以本地币字段为基础重新换算后汇总。 |

---

### 指标：免费信用额度支出

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_expenditure_wo_expiry_amt_local_1d` | double | 当日**无有效期**免费信用额度支出（本地货币）。原始值已由 ETL 从分制换算为标准货币单位。 |
| `free_expenditure_wo_expiry_amt_usd_1d` | double | 当日**无有效期**免费信用额度支出（USD），由本地币除以当日汇率换算得到。⚠️ 跨地区直接 SUM 时存在汇率口径不一致风险，建议以本地币字段为基础重新换算后汇总。 |
| `free_expenditure_w_expiry_amt_local_1d` | double | 当日**有有效期**免费信用额度支出（本地货币）。原始值已由 ETL 从分制换算为标准货币单位。 |
| `free_expenditure_w_expiry_amt_usd_1d` | double | 当日**有有效期**免费信用额度支出（USD），由本地币除以当日汇率换算得到。⚠️ 跨地区直接 SUM 时存在汇率口径不一致风险，建议以本地币字段为基础重新换算后汇总。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下三个分区字段，缺少任何一个将导致全表扫描，引发严重性能问题：

| 分区字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | `tz_type = 'local'`（推荐，按本地时区口径） | 扫描所有时区分区，数据重复计入 |
| `grass_region` | `grass_region = 'SG'` | 扫描所有地区分区，数据量成倍放大 |
| `grass_date` | `grass_date = '2025-01-01'` 或 `grass_date BETWEEN ... AND ...` | 全量历史扫描，严重拖慢查询 |

> **特别说明**：`tz_type` 和 `grass_region` 两个字段在分区路径中同时存在。若仅分析本地时区口径，固定使用 `tz_type = 'local'`；若需对比两种口径，需明确说明并分别查询，避免将 `local` 与 `regional` 数据混合 SUM 造成双重计算。

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确处理方式 |
|------|----------|-------------|
| `paid_expenditure_wo_expiry_amt_usd_1d` | 由各地区本地币除以各自汇率得到，跨地区直接 SUM 存在汇率口径不一致 | 先按地区分别聚合本地币字段，再统一使用当期汇率换算为 USD 后汇总 |
| `paid_expenditure_w_expiry_amt_usd_1d` | 同上 | 同上 |
| `free_expenditure_wo_expiry_amt_usd_1d` | 同上 | 同上 |
| `free_expenditure_w_expiry_amt_usd_1d` | 同上 | 同上 |

> **注意**：所有 `_local_1d` 后缀的本地货币指标字段在同一 `grass_region` 分区内可直接 SUM；`total_expenditure_amt_usd_1d` 同样存在跨地区汇总的汇率口径问题，建议跨地区场景统一使用本地币重新换算。

### 时效性说明

- 本表为 **T+1** 调度，`grass_date = D` 的分区数据在 D+1 写入完成。
- 查询最新数据时，应取 `grass_date = CURRENT_DATE - 1`；若调度存在延迟，避免直接使用 `MAX(grass_date)` 替代固定日期，以防误取不完整分区数据。
- ETL 从 DWD 层拉取数据时覆盖 `[grass_date - 1, grass_date]` 两天窗口，通过 `event_timestamp` 精确过滤当日事件，最终写入为 `grass_date` 当日分区，数据口径为完整自然日。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告表现 DWD 明细表，提供广告支出、信用额度消耗等原始明细数据，按广告维度聚合后写入本表 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于将本地币金额换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live
  │  WHERE grass_region = '${upper_region}'
  │        AND ads_expenditure > 0
  │        AND grass_date IN [grass_date-1, grass_date]
  │        AND event_timestamp IN [grass_date 00:00:00, grass_date+1 00:00:00)
  │  GROUP BY ads_id, placement, campaign_id, shop_id, target_affiliate_id,
  │           item_id, entrance, sub_entrance, pricing_type, streamer_id, grass_region
  │  （金额字段 × 1.0 / 100000 换算为标准货币单位）
  │
  ├──────────────────────────────────────────────┐
  │                                              │
  │                          mp_order.dim_exchange_rate__reg_s0_live
  │                            WHERE grass_region = '${upper_region}'
  │                                  AND grass_date = '${grass_date}'
  │
  └──── LEFT JOIN ON grass_region ──────────────►│
                                                 │
                                    本地币 / exchange_rate → USD 字段
                                                 │
                                                 ▼
                    dws_advertise_livestream_revenue_1d__reg_s0_live
                    PARTITION (tz_type='regional', grass_region='${upper_region}',
                               grass_date='${grass_date}')
                    （同步写入 local 分区路径：tz_type=local/grass_region=${upper_region}）
```

### 关键 CTE 说明

本 ETL 无显式 CTE，采用内联子查询结构：

| 子查询别名 | 来源表 | 作用 |
|-----------|--------|------|
| `a`（内层子查询） | `dwd_livestream_performance_di__reg_s0_live` | 按广告维度（ads_id、placement、campaign_id 等）聚合明细数据，金额字段从整数分制（/100000）换算为标准货币单位 |
| `exrate`（JOIN 子查询） | `dim_exchange_rate__reg_s0_live` | 提取当日该地区的本地币对 USD 汇率，通过 MAPJOIN 广播小表方式 JOIN |

### 注意事项

1. **金额单位换算**：DWD 层的信用额度类字段（`expense_paid_credit_*`、`expense_free_credit_*`）以整数形式存储（单位为分的 1/1000，即实际值 × 100000），ETL 中乘以 `1.00000/100000` 换算为标准货币单位后写入本表。`total_expenditure_amt_local_1d` 和 `total_expenditure_amt_usd_1d` 来自 DWD 层已换算字段，口径可能与信用额度字段略有差异，使用时需注意总额与分项的数值口径是否一致。

2. **USD 换算方式**：USD 字段均通过 `本地币 / exchange_rate` 计算得到（除法换算），而非乘法，需确认汇率维表中 `exchange_rate` 字段的定义为"1 USD = N 本地币"口径。

3. **LEFT JOIN 汇率表**：与汇率表为 LEFT OUTER JOIN，若当日汇率数据缺失，USD 字段将为 NULL，下游使用 USD 字段时需注意 NULL 处理。

4. **event_timestamp 过滤逻辑**：DWD 层 `grass_date` 为分区字段，ETL 额外通过 `event_timestamp` 精确过滤事件发生时间在当日范围内，避免跨天事件归属错误。查询 DWD 层时涉及 `grass_date - 1` 的分区是为了捕获事件时间跨日的数据。

5. **参数化调度**：ETL 通过 `${region}`、`${upper_region}`、`${grass_date}` 等参数化调度，覆盖所有地区，各地区按本地时区独立运行，不同地区数据写入不同 `grass_region` 分区，不存在数据互相覆盖的问题。

6. **`streamer_id` 字段说明**：ETL SQL 中 GROUP BY 和 SELECT 列表均包含 `streamer_id`，但本表 DDL 字段列表中未见该字段，推测为 ETL 中间计算字段或已在最终写入时被映射到 `target_affiliate_id`，使用时请以表实际字段为准。

---

*文档生成时间：2026-05-20*