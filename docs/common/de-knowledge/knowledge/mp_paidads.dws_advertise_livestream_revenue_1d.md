<!-- ads-workspace-gdoc-sync: gdoc_id=17Em_8ia2ksexjTVowy8Ga1XA4FO0gSOW-9hyoX5Wegg gdoc_url=https://docs.google.com/document/d/17Em_8ia2ksexjTVowy8Ga1XA4FO0gSOW-9hyoX5Wegg/edit -->

# mp_paidads.dws_advertise_livestream_revenue_1d

**分层**：DWS（数据汇总层）
**主键**：`ads_id` + `placement` + `campaign_id` + `shop_id` + `target_affiliate_id` + `item_id` + `entrance` + `sub_entrance` + `pricing_type` + `streamer_id` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1，按各地区本地时区参数化调度）
**引用频次**：15 次（候选表范围内）

---

## 业务描述

本表是直播广告收入的日粒度汇总宽表，以广告（`ads_id`）为核心，按广告维度（广告位、活动、店铺、商品、主播、计价模式、入口等）统计每日广告支出金额，同时拆分付费信用/免费信用、含到期/不含到期四个维度，并提供本地货币与美元双口径。

主要应用于广告消耗分析、直播投流效率评估、广告 ROI 计算等场景。下游报表、看板或 ADS 层宽表可直接从本表获取已汇聚好的日级消耗数据，避免从明细层（DWD）重复进行 GROUP BY 聚合，显著提升查询性能。

本表覆盖所有已开放付费广告的市场，各地区按本地时区参数化调度独立写入对应分区，是直播广告数据链路中衔接 DWD 明细与 ADS/应用层的核心中间层。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前写入值为 `'local'`，表示按各地区本地时区统计。查询时**必须指定**，否则将扫描全表所有分区 |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'` 等，标识数据所属市场。查询时**必须指定**，否则将跨地区扫描 |
| `grass_date` | date | 数据统计日期（本地时区），格式 `YYYY-MM-DD`。查询时**必须指定**，避免全量扫描 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告唯一 ID |
| `campaign_id` | bigint | 广告活动 ID，一个 campaign 下可包含多个广告 |
| `placement` | bigint | 广告位标识，枚举值定义参见 [beeshop_ads.proto#L148](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L148) |
| `shop_id` | bigint | 广告所属店铺 ID |
| `target_affiliate_id` | bigint | MCN 场景下广告实际使用方的用户 ID（affiliate user_id）。若 `target_affiliate_id = account_id`，表示卖家或 KOL 自用；若不相等，则表示由 MCN 代创建，使用方为对应达人 |
| `item_id` | bigint | 推广商品 ID |
| `entrance` | int | 广告入口枚举值，定义参见 [beeshop_ads.proto#L317](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L317) |
| `sub_entrance` | int | 广告子入口，与 `entrance` 配合使用，进一步区分流量入口 |
| `pricing_type` | int | 广告计价模式枚举值。常见取值：1=MANUAL_MODE_CPC、2=ENHANCED_CPC、9=LIVE_STREAM_MAX_VIEW、10=LIVE_STREAM_MAX_GMV、14=LIVE_STREAM_TARGET_ROAS 等，完整枚举见字段注释 |
| `streamer_id` | bigint | 直播主播 ID，关联本场直播的主播 |

### 指标：广告总支出

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_expenditure_amt_local_1d` | double | 当日广告总支出（本地货币），= 付费有效期支出 + 付费无有效期支出 + 免费有效期支出 + 免费无有效期支出。来源于上游已转换为元单位的汇总值 |
| `total_expenditure_amt_usd_1d` | double | 当日广告总支出（美元），计算口径同上，通过汇率换算得到 |

### 指标：付费信用支出（无有效期）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_wo_expiry_amt_local_1d` | double | 当日无有效期付费信用支出（本地货币）。上游原始数据以"百万分之一"为单位存储，ETL 中已除以 100000 完成单位换算 |
| `paid_expenditure_wo_expiry_amt_usd_1d` | double | 当日无有效期付费信用支出（美元），= `paid_expenditure_wo_expiry_amt_local_1d` / 汇率 |

### 指标：付费信用支出（有有效期）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_w_expiry_amt_local_1d` | double | 当日有有效期付费信用支出（本地货币）。上游原始数据已除以 100000 完成单位换算 |
| `paid_expenditure_w_expiry_amt_usd_1d` | double | 当日有有效期付费信用支出（美元），= `paid_expenditure_w_expiry_amt_local_1d` / 汇率 |

### 指标：免费信用支出（无有效期）

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_expenditure_wo_expiry_amt_local_1d` | double | 当日无有效期免费信用支出（本地货币）。上游原始数据已除以 100000 完成单位换算 |
| `free_expenditure_wo_expiry_amt_usd_1d` | double | 当日无有效期免费信用支出（美元），= `free_expenditure_wo_expiry_amt_local_1d` / 汇率 ⚠️ 字段 comment 中货币描述标注为"本地货币"，与字段名（`_usd`）不符，实际 ETL 逻辑已正确换算为美元，使用时以字段名（USD）为准 |
| `free_expenditure_w_expiry_amt_local_1d` | double | 当日有有效期免费信用支出（本地货币）。上游原始数据已除以 100000 完成单位换算 |
| `free_expenditure_w_expiry_amt_usd_1d` | double | 当日有有效期免费信用支出（美元），= `free_expenditure_w_expiry_amt_local_1d` / 汇率 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，产生巨大的计算资源浪费并可能造成数据重复：

| 过滤字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | `tz_type = 'local'` | 若未来新增其他时区类型分区，数据将被重复计算 |
| `grass_region` | `grass_region = 'MY'` | 跨所有市场全量扫描，数据混杂且性能极差 |
| `grass_date` | `grass_date = '2024-01-01'` 或 `grass_date between ... and ...` | 全量历史数据扫描，资源消耗极高 |

> **推荐写法**：
> ```sql
> WHERE tz_type = 'local'
>   AND grass_region = 'MY'
>   AND grass_date = '2024-01-01'
> ```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确计算方式 |
|------|---------|-------------|
| `total_expenditure_amt_local_1d` | 已由 ETL 预聚合为 4 类支出之和，跨 `grass_date` 多分区 SUM 可正常使用；但跨地区 SUM 时需注意货币单位不统一（各地区为本地货币） | 跨地区汇总请改用 `total_expenditure_amt_usd_1d` |
| `total_expenditure_amt_usd_1d` | 汇率快照为写入当日汇率，不同日期汇率不同 | 历史趋势比较时注意汇率波动影响，不宜直接与当前汇率换算结果对比 |
| `paid_expenditure_wo_expiry_amt_usd_1d`、`paid_expenditure_w_expiry_amt_usd_1d`、`free_expenditure_wo_expiry_amt_usd_1d`、`free_expenditure_w_expiry_amt_usd_1d` | 均通过当日汇率快照计算，分项之和应与 `total_expenditure_amt_usd_1d` 一致，但不同日期的 USD 金额因汇率快照不同存在可比性差异 | 跨日汇总时以本地货币分项汇总后统一换算，或直接使用 `total_expenditure_amt_usd_1d` |

### 时效性说明

本表为 T+1 日级数据，数据以 `grass_date` 分区写入，每日调度完成后当日分区数据即为最终值（当日分区会被 `INSERT OVERWRITE` 覆盖写入，保证幂等）。查询最新数据时，应取**昨日分区**（`grass_date = current_date - 1`），当日分区在调度完成前可能不存在或数据不完整。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告绩效明细日表，提供广告维度及各类信用支出原始金额（单位：百万分之一），过滤 `ads_expenditure > 0` 后按广告维度聚合 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对美元的汇率快照，用于将本地货币支出换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live
  │  过滤: grass_region = '${upper_region}'
  │         grass_date = '${grass_date}'
  │         ads_expenditure > 0
  │  聚合: GROUP BY ads_id, placement, campaign_id, shop_id,
  │               target_affiliate_id, item_id, entrance,
  │               sub_entrance, pricing_type, streamer_id, grass_region
  │  计算: SUM(expense_*_credit_*) * 1.0 / 100000  → 本地货币元单位
  │
  ▼
  子查询 a（各维度日汇总，本地货币）
  │
  ├── LEFT JOIN ──────────────────────────────────────────────┐
  │                                                           │
  │                              mp_order.dim_exchange_rate__reg_s0_live
  │                               过滤: grass_region = '${upper_region}'
  │                                     grass_date = '${grass_date}'
  │                               提供: exchange_rate（本地货币/USD）
  │                                                           │
  ◀──────────────────────────────────────────────────────────┘
  │  换算: expense_local / exchange_rate → USD 金额
  │
  ▼
mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live
  写入分区: tz_type='local', grass_region='${upper_region}', grass_date='${grass_date}'
  写入方式: INSERT OVERWRITE（幂等覆盖）
  存储格式: PARQUET
```

### 关键 CTE 说明

本 ETL 无显式 CTE，核心逻辑通过一层子查询（别名 `a`）实现：

| 子查询/步骤 | 来源表 | 作用 |
|------------|--------|------|
| 子查询 `a` | `dwd_livestream_performance_di__reg_s0_live` | 过滤有效广告支出（`ads_expenditure > 0`），按广告全维度 GROUP BY 聚合；将原始信用字段（存储单位为 1/100000）乘以系数换算为真实本地货币金额 |
| LEFT JOIN `exrate` | `dim_exchange_rate__reg_s0_live` | 关联当日汇率，将本地货币分项金额换算为 USD；使用 `MAPJOIN` 将汇率表广播，避免 Shuffle 提升性能 |
| INSERT OVERWRITE | — | 写入目标分区，幂等覆盖，支持重跑 |

### 注意事项

1. **单位换算陷阱**：上游 `dwd_livestream_performance_di` 中各信用支出字段（`expense_paid_credit_without_expiry` 等）的原始单位为 **1/100000**，ETL 中通过 `* 1.00000 / 100000` 换算为元单位后存入本表。`total_expenditure_amt_local_1d` 和 `total_expenditure_amt_usd_1d` 来自上游已经是元单位的 `ads_expenditure` / `ads_expenditure_usd` 字段，未经除法换算，两套口径需注意来源一致性。

2. **汇率快照时效**：USD 金额均基于 `grass_date` 当日汇率快照计算，历史数据的 USD 金额不会随汇率变动而更新。若需以当前汇率重算，须用本地货币字段重新换算。

3. **LEFT JOIN 与 NULL 汇率**：若某地区某日汇率缺失，`exrate.exchange_rate` 为 NULL，所有 `_usd_1d` 字段将为 NULL，但本地货币字段不受影响。查询时如发现 USD 字段大量为 NULL，需排查汇率表是否存在数据缺失。

4. **双表结构设计**：ETL 中创建了两张外表：`__reg_s0_live`（含 `tz_type`、`grass_region` 分区，全量汇总表）和 `__${region}_s0_live`（仅含 `grass_date` 分区，指向同一 HDFS 路径下的地区子目录）。两张表共享同一份 PARQUET 文件，区别仅在于分区视图的粒度，下游查询优先使用 `__reg_s0_live` 版本以保持跨地区一致性。

5. **过滤条件 `ads_expenditure > 0`**：本表仅包含当日有实际消耗的广告记录，消耗为 0 的广告不会出现在本表中，分析广告活跃度时需注意此口径。

---

*文档生成时间：2026-04-22*