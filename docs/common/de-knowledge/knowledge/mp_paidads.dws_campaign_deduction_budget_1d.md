<!-- ads-workspace-gdoc-sync: gdoc_id=1dtD1XURBt0BE9YksxiG_EzDJwz3-BTLL_85amFZ6nS4 gdoc_url=https://docs.google.com/document/d/1dtD1XURBt0BE9YksxiG_EzDJwz3-BTLL_85amFZ6nS4/edit -->

# mp_paidads.dws_campaign_deduction_budget_1d

**分层**：DWS（数据汇总层）
**主键**：`campaign_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 调度）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表以广告 Campaign 为粒度，汇总每个 Campaign 在指定日期的**扣费金额与预算达成情况**，覆盖日预算和总预算两个维度。每行记录一个 Campaign 在某一天（本地时区）的日扣费额、截止当日的累计总扣费额，以及与日预算、总预算的对比结果（是否触达预算上限）。

本表主要用于广告投放的**预算监控与超预算告警**场景：运营和算法团队可通过 `hit_daily_budget`、`hit_total_budget` 标识，快速识别当天触达预算上限的 Campaign，进而触发限流或调价策略；也可对 `daily_deduction` 与 `daily_quota_local`、`total_deduction` 与 `total_quota_local` 进行比较，分析预算消耗进度与预算利用率。

各地区按本地时区参数化调度，确保不同市场的日期切分与当地业务日历对齐，适合跨地区统一口径的预算执行分析。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。各地区按本地时区调度写入，当前写入值为 `'local'`，查询时建议始终指定 `tz_type = 'local'` 以避免全表扫描。 |
| `grass_region` | string | 国家/地区分区，大写字母代码（如 `'MX'`、`'BR'`）。通过调度参数 `${region}` 参数化覆盖所有地区。 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`，对应本地时区下的业务日期。 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_id` | bigint | 营销活动（Campaign）唯一标识，来源于 `dim_campaign__reg_s0_live`，为本表主键之一。 |

### 指标：预算配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_quota_local` | double | Campaign 日预算，单位为本地货币。若 Campaign 未设置日预算则为 `NULL`，业务上可视为无日预算限制（即不限量）。⚠️ 为配置值而非度量值，多 Campaign 聚合时不应直接 SUM，需结合业务语义判断是否需要加总。 |
| `total_quota_local` | double | Campaign 总预算，单位为本地货币。若 Campaign 未设置总预算则为 `NULL`，业务上可视为无总预算限制。⚠️ 同 `daily_quota_local`，为配置值，聚合时需注意语义。 |

### 指标：扣费金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_deduction` | double | 当日广告扣费金额（本地货币），由 `dws_advertise_revenue_1d` 中 `total_expenditure_amt_local_1d` 按 `campaign_id` 汇总而来，反映该 Campaign 在 `grass_date` 当天的实际消耗。 |
| `total_deduction` | double | 截止 `grass_date` 当日的广告累计总扣费金额（本地货币），来源于 `dws_campaign_deduction_td__reg_s0_live`。⚠️ 该字段为截止当日的累计值（td = to-date），跨日期聚合时不可直接 SUM，否则会重复累加历史扣费；如需统计某时间段总扣费，应取时间段末尾日期的 `total_deduction` 值，或改用 `daily_deduction` 逐日加总。 |

### 指标：预算触达标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `hit_daily_budget` | tinyint | 是否触达日预算上限。`1` = 当日扣费已达或超过日预算（`daily_deduction >= daily_quota_local`）；`0` = 未触达；`0` = 日预算未设置（`daily_quota_local` 为 NULL 或 0）。⚠️ 未设置预算时返回 `0` 而非 `NULL`，统计触达率时需区分"未设置预算"与"未触达"两种 `0` 的语义，建议结合 `daily_quota_local IS NULL` 条件过滤。 |
| `hit_total_budget` | tinyint | 是否触达总预算上限。`1` = 累计扣费已达或超过总预算（`total_deduction >= total_quota_local`）；`0` = 未触达；`0` = 总预算未设置（`total_quota_local` 为 NULL 或 0）。⚠️ 同 `hit_daily_budget`，未设置预算与未触达均为 `0`，使用时需注意区分。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致查询性能严重下降并产生不必要的计算费用：

| 分区字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前 ETL 仅写入 `local` 分区，遗漏此条件会导致全分区扫描，且结果不受影响但性能极差 |
| `grass_region` | `grass_region = 'XX'`（大写） | 必须使用**大写**地区码，如 `'MX'`、`'BR'`；遗漏将扫描所有地区数据 |
| `grass_date` | `grass_date = '2024-01-01'` 或 `grass_date between ... and ...` | 必须指定日期范围；遗漏将扫描全量历史分区 |

**示例：**
```sql
SELECT campaign_id, daily_deduction, hit_daily_budget
FROM mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live
WHERE tz_type       = 'local'
  AND grass_region  = 'MX'
  AND grass_date    = '2024-01-01';
```

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确做法 |
|------|------|----------|
| `total_deduction` | 为截止当日的累计值（td），跨日期 SUM 会重复累加历史消耗 | 若需统计某周期总扣费，取该周期**最后一天**的 `total_deduction`；或改用 `daily_deduction` 按天加总 |
| `daily_quota_local` | 为 Campaign 配置的预算上限，非当日实际消耗；NULL 表示未设置预算 | 不应直接聚合加总；比较预算利用率时用 `daily_deduction / daily_quota_local` |
| `total_quota_local` | 同上，为总预算配置值，NULL 表示不限预算 | 不应直接聚合加总；比较进度时用 `total_deduction / total_quota_local` |
| `hit_daily_budget` / `hit_total_budget` | `0` 混淆"未设置预算"与"未触达"两种语义 | 统计触达率时，分母应排除 `quota IS NULL OR quota = 0` 的 Campaign，即：`SUM(hit_daily_budget) / COUNT(CASE WHEN daily_quota_local > 0 THEN 1 END)` |

### 时效性说明

- `total_deduction` 来源于 `dws_campaign_deduction_td__reg_s0_live`（td = to-date，截止当日累计），其含义与 `grass_date` 强绑定。若需获取某 Campaign 截止昨日的累计扣费，应取 `grass_date = <昨日>` 分区的记录，**不要跨多个日期分区对该字段求和**。
- 本表每日 T+1 调度，当天最新数据在次日写入，查询实时数据请参考上游流式或更高频次的数据源。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_campaign__reg_s0_live` | 提供 Campaign 维度信息（`campaign_id`、`daily_quota_local`、`total_quota_local`、`grass_region`），作为主驱动表确保所有活跃 Campaign 均有记录 |
| `mp_paidads.dws_campaign_deduction_td__reg_s0_live` | 提供截止当日的 Campaign 累计总扣费（`total_deduction`），通过 LEFT JOIN 关联 |
| `mp_paidads.dws_advertise_revenue_1d__reg_s0_live` | 提供广告位级别的当日消耗明细（`total_expenditure_amt_local_1d`），按 `campaign_id` 聚合后得到 `daily_deduction` |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_campaign__reg_s0_live
  (campaign_id, daily_quota_local,
   total_quota_local, grass_region)
           │
           │  LEFT JOIN (on campaign_id & grass_region)
           │
mp_paidads.dws_campaign_deduction_td__reg_s0_live
  (campaign_id, deduction AS total_deduction)
           │
           │  LEFT JOIN (on campaign_id)
           │
mp_paidads.dws_advertise_revenue_1d__reg_s0_live
  (campaign_id,
   SUM(total_expenditure_amt_local_1d) AS daily_deduction)
           │
           ▼
  [派生计算]
  hit_total_budget = CASE WHEN total_quota_local IS NULL OR =0 THEN 0
                          WHEN total_quota_local - total_deduction <= 0 THEN 1
                          ELSE 0 END
  hit_daily_budget = CASE WHEN daily_quota_local IS NULL OR =0 THEN 0
                          WHEN daily_quota_local - daily_deduction <= 0 THEN 1
                          ELSE 0 END
           │
           ▼
mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live
  partition(tz_type='local', grass_region, grass_date)
```

> **调度引擎**：Hive SQL，INSERT OVERWRITE 幂等写入，按 `${region}`、`${grass_date}` 参数化多地区调度。

### 关键 CTE 说明

本 ETL 未使用命名 CTE，以内联子查询形式组织逻辑：

| 子查询别名 | 来源表 | 作用 |
|------------|--------|------|
| `dim_campaign_tab` | `dim_campaign__reg_s0_live` | 拉取指定地区、日期的所有 Campaign 及其预算配置，作为驱动表保证 Campaign 全量覆盖 |
| `t_deduction` | `dws_campaign_deduction_td__reg_s0_live` | 获取截止当日的 Campaign 累计扣费（`total_deduction`），LEFT JOIN 确保无扣费记录的 Campaign 仍保留 |
| `d_deduction` | `dws_advertise_revenue_1d__reg_s0_live` | 按 `campaign_id` 汇总当日广告位明细消耗，得到 `daily_deduction`，LEFT JOIN 确保零消耗 Campaign 仍保留 |

### 注意事项

1. **预算未设置时标识为 0 而非 NULL**：`hit_daily_budget` 和 `hit_total_budget` 在预算字段为 NULL 或 0 时均输出 `0`，与"有预算但未触达"的 `0` 语义相同。业务上需通过 `daily_quota_local IS NOT NULL AND daily_quota_local > 0` 过滤来区分。

2. **LEFT JOIN 导致扣费字段可能为 NULL**：若某 Campaign 当日无任何消耗记录，`daily_deduction` 和 `total_deduction` 将为 `NULL`（而非 `0`）。在计算差值或比率时需用 `COALESCE(daily_deduction, 0)` 处理。

3. **`total_deduction` 的 td 语义**：该字段来自 `dws_campaign_deduction_td`（to-date 累计），代表从投放开始到 `grass_date` 当天为止的历史总消耗，**跨日期聚合时禁止直接 SUM**（详见查询使用须知）。

4. **地区参数化调度**：ETL 中出现的 `upper('${region}')` 为调度模板变量，实际运行时替换为各地区大写代码，本表通过统一后缀 `__reg_s0_live` 将所有地区数据写入同一张分区表，各地区按本地时区独立调度。

5. **INSERT OVERWRITE 幂等性**：每次调度对指定 `(tz_type, grass_region, grass_date)` 分区执行覆盖写入，重跑安全，不会产生数据重复。

---

*文档生成时间：2026-05-20*