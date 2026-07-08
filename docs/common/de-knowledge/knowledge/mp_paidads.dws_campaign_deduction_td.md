<!-- ads-workspace-gdoc-sync: gdoc_id=1ULu1HsdEKl_0YI4_DVjWrll7ELLVSSselUMYuhxeSLE gdoc_url=https://docs.google.com/document/d/1ULu1HsdEKl_0YI4_DVjWrll7ELLVSSselUMYuhxeSLE/edit -->

# mp_paidads.dws_campaign_deduction_td

**分层：** DWS（数据汇总层）
**主键：** `campaign_id` + `grass_region` + `grass_date` + `tz_type`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（增量追加新分区，累计历史汇总）
**引用频次：** 1 次（候选表范围内）

---

## 业务描述

本表存储各广告活动（Campaign）自投放开始至指定日期的**累计广告扣费金额**（To-Date，TD），同时提供本地货币与 USD 两种口径，方便跨地区横向对比及本地财务结算双重使用场景。

该表采用"当日增量 + 前日累计"叠加的累积模式：每日调度时，从日粒度明细表中抽取当日新增扣费，与前一日的累计值合并后重新写入当前分区，形成滚动累计的 TD 数据。因此，**任意一个 `grass_date` 分区中的数据均代表截止该日的所有历史扣费之和**，可直接用于趋势分析、ROI 核算及预算消耗监控。

各地区通过参数化调度独立运行，按本地时区切割日期边界，确保各市场数据口径一致，适用于广告投放效果复盘、预算执行追踪及跨国投放报表场景。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。当前 ETL 固定写入 `'local'`（本地时区），查询时建议显式指定 `tz_type = 'local'` 以避免全表扫描。 |
| `grass_region` | string | 国家/地区分区，大写字母代码（如 `'MX'`、`'BR'`）。各地区独立调度写入。 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`，表示截止该日的累计数据。 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_id` | bigint | 广告活动 ID，营销活动的唯一标识。与分区字段共同构成本表主键。 |

### 指标：累计广告扣费

| 字段 | 类型 | 说明 |
|------|------|------|
| `deduction` | double | 截止当日（`grass_date`）该 Campaign 的累计广告扣费总额，**本地货币**计价。⚠️ 本字段为 TD 累计值，跨日期分区对同一 Campaign 直接 SUM 将导致重复叠加，仅应取所需日期的单一分区值。 |
| `deduction_usd` | double | 截止当日（`grass_date`）该 Campaign 的累计广告扣费总额，**USD** 计价。⚠️ 同上，为 TD 累计值，跨日期分区 SUM 会造成数据重复，应取单一分区值。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致查询耗时剧增并产生不必要的计算费用：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前 ETL 仅写入 `'local'` 分区，遗漏此条件将扫描全部 tz_type 分区（含历史脏数据风险） |
| `grass_region` | `grass_region = 'XX'`（大写） | 按业务所需地区过滤，遗漏将扫描所有地区分区 |
| `grass_date` | `grass_date = '2025-xx-xx'` | 指定所需日期，遗漏将返回所有历史累计分区的重复叠加数据，结果完全失真 |

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确使用方式 |
|------|------|-------------|
| `deduction` | TD 累计字段，每个 `grass_date` 分区已包含历史所有数据之和。跨多个日期分区 SUM 会对同一天的消耗重复累加。 | 仅取**单一** `grass_date` 分区，直接读取该字段值作为截止该日的累计扣费；若需计算某时间段内的**增量消耗**，应用 `T 日的值 - (T-1) 日的值`。 |
| `deduction_usd` | 同上，USD 口径的 TD 累计字段。 | 同 `deduction`，取单日分区或做差值计算。 |

### 时效性说明

本表每日调度完成后，当日分区（`grass_date = T`）即为最新的截止当日累计数据。查询最新状态时，应取**当前调度已完成的最新 `grass_date`** 分区，而非使用 `MAX(grass_date)` 跨分区聚合（会引发全表扫描）。建议由调度系统将最新业务日期作为参数传入查询，避免动态计算分区值。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_revenue_1d__reg_s0_live` | 日粒度广告收入/扣费明细表，提供当日新增的 `total_expenditure_amt_local_1d`（本地货币扣费）和 `total_expenditure_amt_usd_1d`（USD 扣费），按 `campaign_id` 汇总后作为当日增量 |
| `mp_paidads.dws_campaign_deduction_td__reg_s0_live`（自身） | 读取前一日（`grass_date - 1`）的累计扣费作为历史基数，与当日增量 UNION ALL 后叠加，实现滚动累计 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_revenue_1d__reg_s0_live
  (grass_date = T, tz_type = 'local', grass_region = '${REGION}')
  └─► 按 campaign_id + grass_region GROUP BY
      SUM(total_expenditure_amt_local_1d) → deduction [当日增量]
      SUM(total_expenditure_amt_usd_1d)  → deduction_usd [当日增量]
                          │
                          │ UNION ALL
                          │
mp_paidads.dws_campaign_deduction_td__reg_s0_live（自身回溯）
  (grass_date = T-1, grass_region = '${REGION}')
  └─► deduction, deduction_usd [T-1 日累计基数]
                          │
                          ▼
              外层 GROUP BY campaign_id + grass_region
              SUM(deduction), SUM(deduction_usd)
                          │
                          ▼
  INSERT OVERWRITE PARTITION (tz_type='local', grass_region, grass_date=T)
  mp_paidads.dws_campaign_deduction_td__reg_s0_live
```

### 关键 CTE 说明

本 ETL 无显式 CTE，核心逻辑通过内层子查询（`UNION ALL` 子查询）实现：

| 子查询层 | 来源表 | 作用 |
|----------|--------|------|
| 子查询分支 1 | `dws_advertise_revenue_1d__reg_s0_live` | 取当日（`grass_date = T`）各 Campaign 扣费明细并按 `campaign_id + grass_region` 汇总，得到当日增量扣费 |
| 子查询分支 2 | `dws_campaign_deduction_td__reg_s0_live`（自身） | 取前一日（`grass_date = T-1`）的 TD 累计扣费，作为历史基数 |
| 外层聚合 | 上述 UNION ALL 结果 | 将当日增量与前日累计再次 GROUP BY SUM，得到截止 T 日的最新累计值，覆盖写入当日分区 |

### 注意事项

1. **累计模式（TD）的本质**：每日 ETL 以"前日累计 + 当日增量"的方式滚动生成新分区，因此历史分区数据不会被回刷修正。若上游 `dws_advertise_revenue_1d` 发生历史数据补录，需从补录日期起逐日重跑本表 ETL，否则历史累计值将出现断层。

2. **自引用写入风险**：ETL 在读取本表前日分区的同时，对当日分区执行 `INSERT OVERWRITE`，两者分区不同，无写读冲突，但重跑历史日期时需注意分区覆盖顺序，避免因误操作导致累计链断裂。

3. **地区代码大写**：`grass_region` 存储为大写字符串（ETL 中使用 `upper('${region}')`），查询时过滤条件应使用大写，如 `grass_region = 'MX'`，小写将命中空分区。

4. **参数化调度覆盖全地区**：ETL 中出现的具体地区代码和时区仅为调度模板的参数化实例，`__reg_s0_live` 后缀表明通过 `${region}` 参数为每个地区独立调度，各地区按本地时区参数化调度，本表覆盖所有已上线地区。

5. **`tz_type` 当前仅有 `local` 分区**：ETL 硬编码 `PARTITION (tz_type='local', ...)`，若后续新增 UTC 口径分区，需确认 ETL 是否扩展，查询前建议确认可用分区值。

---

*文档生成时间：2026-05-20*