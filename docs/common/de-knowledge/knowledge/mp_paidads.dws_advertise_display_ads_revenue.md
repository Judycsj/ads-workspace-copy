<!-- ads-workspace-gdoc-sync: gdoc_id=1yALdfJf0LpHUIJ7cT-XP27eJdZcnOMoP6EwrlVw5qfY gdoc_url=https://docs.google.com/document/d/1yALdfJf0LpHUIJ7cT-XP27eJdZcnOMoP6EwrlVw5qfY/edit -->

# mp_paidads.dws_advertise_display_ads_revenue

**分层：** DWS（数据服务层）
**主键：** `ads_id, entrance, pricing_type, placement, grass_region, grass_date`
**分区：** `tz_type / grass_region / grass_date`
**更新频率：** 每日（按自然日全量覆写当天分区）
**引用频次：** 3 次（候选表范围内下游引用）

---

## 业务描述

本表汇聚展示广告（Display Ads）的每日流量与收入数据，以广告 ID、入口、计价类型、广告位为最细粒度，统计展示次数、点击次数及对应的广告收入（本地货币与美元双口径），是展示广告变现分析的核心宽表。

典型使用场景包括：展示广告日常营收报表、CPM / eCPM 趋势监控、广告主投放绩效追踪、广告位盈利评估，以及跨地区横向对比分析。各地区按本地时区参数化调度，数据口径一致，可直接在 `grass_region` 维度上进行跨区汇总或对比。

本表仅覆盖 `placement = 9` 的展示广告流量，并通过汇率表将本地货币金额转换为美元，同时过滤掉预算已结束的广告（`budget_end_datetime < grass_date`），确保收入数据的有效性与可比性。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。`local` 表示按各地区本地时区聚合的数据，是日常分析的标准口径。⚠️ 查询时必须显式指定此字段（通常取 `tz_type = 'local'`），否则将跨时区重复计算同一天的广告数据 |
| `grass_region` | string | 地区代码分区，大写存储（如 `MX`、`TH`、`ID` 等）。各地区由参数化调度独立写入，查询时应明确指定以避免全表扫描 |
| `grass_date` | date | 数据日期分区，对应广告曝光/点击发生的自然日（本地时区）。每日全量覆写当天分区 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一个展示广告投放单元 |
| `campaign_id` | bigint | 广告活动 ID，标识广告所属的投放活动（Campaign） |
| `shop_id` | bigint | 广告主店铺 ID，关联自 `dim_display_ads` 维表；当广告 ID 在维表中无匹配记录时可能为 NULL。⚠️ ETL 注释标注"now is fixed value, to be change"，未来口径可能变更，使用时需关注版本更新 |
| `entrance` | int | 广告入口位置，即买家点击或曝光发生的入口枚举值。枚举定义参见 [AdsEntrance Proto](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L317) |
| `pricing_type` | int | 广告计价模式枚举值（如 CPM、CPC 等）。枚举定义参见 [AdsPricingType Proto](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L269) |
| `placement` | int | 广告位枚举值。本表数据经过 `placement = 9` 过滤，实际写入值固定为 `9`（展示广告位）。枚举定义参见 [Proto 定义](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L148) |
| `budget_start_datetime` | string | 广告预算的开始日期时间，字符串格式存储，记录该广告投放预算的生效起始时间 |
| `budget_end_datetime` | string | 广告预算的结束日期时间，字符串格式存储。⚠️ ETL 中使用 `substr(cast(budget_end_datetime as string), 0, 11) >= grass_date` 进行过滤，本表只保留预算未到期的广告记录；字段为字符串类型，日期比较需使用 `substr` 或显式转换 |

---

### 指标：展示广告流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 当日广告展示总次数，来源于上游日志表 `impression` 字段的 SUM 聚合 |
| `click_cnt` | bigint | 当日广告点击次数，已排除欺诈点击（fraud excluded），统计来源为 `non_fraud_click`，仅适用于 SHOP_CMP 及展示广告（DISPLAY Ads）。⚠️ 可能包含重复点击（duplicates），不等同于去重用户点击数 |

---

### 指标：广告收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_cpm_local` | decimal(38,10) | 估算 CPM（每千次展示费用），本地货币单位。ETL 中由原始 `cpm` 字段除以 100000 取最大值后保留两位小数：`round(max(cpm) / 100000, 2)`。⚠️ 该字段为每组的预计算 CPM 费率，**不可直接 SUM**；多行汇总时应以 `expense_amt_local / impression_cnt * 1000` 重新推算加权 CPM |
| `estimate_cpm_usd` | decimal(38,10) | 估算 CPM，美元单位。计算方式为 `round(cpm_local / 100000 / exchange_rate, 2)`。⚠️ 同上，**不可直接 SUM**；且依赖当日汇率，跨日汇总时需回溯原始本地货币口径再统一换算 |
| `expense_amt_local` | decimal(38,10) | 广告总支出金额，本地货币单位。计算方式为 `round(cpm_local * impression_cnt / 100000, 2)`，即 CPM × 展示量。可直接 SUM 进行跨广告/跨日汇总 |
| `expense_amt_usd` | decimal(38,10) | 广告总支出金额，美元单位。计算方式为 `round(cpm_local * impression_cnt / 100000 / exchange_rate, 2)`。可直接 SUM，但⚠️ 汇率取自当日 `dim_exchange_rate`，跨日汇总结果受汇率波动影响，与统一基准日汇率换算的结果可能存在偏差 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，缺少任意一个将导致全分区扫描，产生严重性能问题并可能引发跨地区/跨时区数据重复：

| 分区字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 会扫描所有时区分区，数据重复计算 |
| `grass_region` | `grass_region = 'XX'`（大写地区码） | 全地区扫描，数据量激增且含无关地区数据 |
| `grass_date` | `grass_date = '2025-01-01'` 或范围过滤 | 全量历史扫描，严重影响查询性能 |

示例最佳实践：
```sql
SELECT *
FROM mp_paidads.dws_advertise_display_ads_revenue
WHERE tz_type = 'local'
  AND grass_region = 'TH'
  AND grass_date = '2025-01-01'
```

---

### 不可直接 SUM 的字段

| 字段 | 错误用法 | 正确计算方式 |
|------|----------|-------------|
| `estimate_cpm_local` | `SUM(estimate_cpm_local)` | 加权 CPM = `SUM(expense_amt_local) / SUM(impression_cnt) * 1000` |
| `estimate_cpm_usd` | `SUM(estimate_cpm_usd)` | 加权 CPM = `SUM(expense_amt_usd) / SUM(impression_cnt) * 1000` |
| `expense_amt_usd` | 跨日 SUM 时需注意 | 跨日 SUM 结果受各日汇率影响，如需固定汇率口径需基于 `expense_amt_local` 统一换算 |

> `impression_cnt`、`click_cnt`、`expense_amt_local` 可以直接 SUM 进行聚合。

---

### 时效性说明

本表每日全量覆写当天分区（`grass_date = 调度日期`）。由于 ETL 过滤条件为 `budget_end_datetime >= grass_date`，历史分区中的数据不会因预算到期而被回刷——**历史分区数据一经写入即固定**。如需查询最新当日数据，请取最近已完成调度的 `grass_date` 分区，避免查询当天尚未调度完成的分区导致数据不完整。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 广告原始日志，提供展示次数（`impression`）、非欺诈点击（`non_fraud_click`）、CPM 价格（`cpm`）等核心流量与计价字段；过滤条件：`placement = 9`、`slot_id IS NOT NULL` |
| `mkplpaidads_data.dim_display_ads__reg_s3_live` | 展示广告维表，提供广告的 `shop_id`、`budget_start_datetime`、`budget_end_datetime` 等广告属性字段 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对美元汇率（`exchange_rate`），用于将本地货币金额换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_ads_report_hi__reg_s0_live
  │  过滤: placement=9, slot_id IS NOT NULL
  │  聚合: GROUP BY ads_id, entrance, pricing_type, placement, grass_region, campaign_id
  │  输出: impression_cnt, click_cnt, cpm_local (max)
  │
  ├─── LEFT JOIN ────────────────────────────────────────────────────────────┐
  │                                                                          │
  │                          mkplpaidads_data.dim_display_ads__reg_s3_live   │
  │                            ON ads_id | 补充: shop_id, budget_datetime    │
  │                                                                          │
  └──────────────────────────────────────────────────── display_ads_traffic  │
                                                                             │
  LEFT JOIN ─────────────────────────────────────────────────────────────────┘
       │
       │  mp_order.dim_exchange_rate__reg_s0_live
       │  ON grass_region | 补充: exchange_rate
       │
       ▼
  [计算] expense_amt_local = round(cpm * imp / 100000, 2)
         expense_amt_usd   = round(cpm * imp / 100000 / exchange_rate, 2)
         estimate_cpm_local = round(cpm / 100000, 2)
         estimate_cpm_usd   = round(cpm / 100000 / exchange_rate, 2)
       │
  [过滤] budget_end_datetime >= grass_date （过滤已过期广告）
       │
       ▼
  INSERT OVERWRITE
  dws_advertise_display_ads_revenue__reg_s0_live
  PARTITION (tz_type='local', grass_region=${region}, grass_date=${grass_date})
```

> **计算引擎：** Hive SQL，结果以 Parquet 格式写入 HDFS，并通过 `ALTER TABLE ADD PARTITION` 注册分区元数据。调度由 `data_paidadsmart.studio_6014176` 任务按地区参数化驱动，各地区独立调度、独立写入对应分区。

---

### 关键 CTE 说明

本 ETL 无显式 CTE，主要逻辑由内联子查询实现：

| 子查询 | 来源表 | 作用 |
|--------|--------|------|
| `display_ads_traffic` | `ods_log_ads_report_hi__reg_s0_live` | 过滤展示广告日志（placement=9，slot_id 非空），按广告维度聚合展示量、点击量、CPM |
| `display_ads` | `dim_display_ads__reg_s3_live` | 关联广告维表，补充 shop_id 及预算时间范围 |
| `exchange_rate_info` | `dim_exchange_rate__reg_s0_live` | 关联当日汇率，用于本地货币→美元换算 |

---

### 注意事项

1. **placement 固定过滤**：上游日志写入时已过滤 `placement = 9`，本表仅含展示广告位数据，**不含搜索广告、推荐广告等其他 placement 类型**，跨广告类型对比分析时需注意口径差异。

2. **CPM 精度处理**：原始日志中 `cpm` 字段以"微分"存储（需除以 100000 还原为实际货币单位），ETL 中已完成转换并保留两位小数，下游直接使用 `estimate_cpm_local` / `expense_amt_local` 即可，**不需要再次除以 100000**。

3. **预算到期过滤**：ETL 通过 `substr(cast(budget_end_datetime as string), 0, 11) >= grass_date` 过滤已结束预算的广告，导致当日有展示记录但预算已到期的广告不会写入本表，可能造成与原始日志聚合值的差异。

4. **LEFT JOIN 导致的 NULL 值**：`shop_id`、`budget_start_datetime`、`budget_end_datetime` 均通过 LEFT JOIN 从维表补充，若广告 ID 在维表中无对应记录（如广告已下线或数据延迟），上述字段将为 NULL，聚合前需酌情处理。

5. **汇率时点依赖**：`expense_amt_usd` 使用当日汇率换算，历史数据写入后不随汇率变动而更新，跨日累加 USD 金额时存在多汇率混合问题，建议在需要统一汇率口径的场景中基于 `expense_amt_local` 重新换算。

6. **参数化调度**：ETL 模板中 `${region}`、`${timezone}`、`${grass_date}` 均为调度参数，实际生产中各地区独立触发，最终数据以 `(tz_type, grass_region, grass_date)` 三级分区区分，**本表覆盖所有已配置地区**，非单一市场数据。

---

*文档生成时间：2026-04-22*