<!-- ads-workspace-gdoc-sync: gdoc_id=1y8atMkbCeTuiFiYkZD4Z1Ot49wSscvhVEFLjGnhHhcw gdoc_url=https://docs.google.com/document/d/1y8atMkbCeTuiFiYkZD4Z1Ot49wSscvhVEFLjGnhHhcw/edit -->

# mp_paidads.ads_report_ng_data_quality_1h

**分层**：ADS（应用数据服务层）
**主键**：`grass_region, entrance, grass_date, h`
**分区**：`grass_date`（日期，yyyy-MM-dd）、`h`（小时，0-23）
**更新频率**：每小时调度一次（T+1 小时）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是付费广告系统（Paid Ads）针对广告曝光日志底表 `ods_log_ads_report_hi` 的**逐小时数据质量监控表**，用于追踪各地区、各广告入口下关键字段的完整性状况。每个分区（`grass_date` + `h`）存储当前小时的汇总统计快照，覆盖 `pricing_type`、`ads_id`、`shop_id`、`placement`、`entrance`、`request_id` 等核心业务字段的总行数、非空行数与 NULL 行数。

本表的核心使用场景包括：**数据质量告警**（自动检测字段 NULL 率超阈值）、**日志链路完整性验证**（对比各小时 `row_count` 是否符合预期水位）、以及**上游数据管道健康度看板**。通过将 `*_null_count` 除以 `row_count`，可快速计算任意字段在某小时、某地区、某广告入口维度下的缺失率，从而定位异常数据来源。

各地区按本地时区参数化调度，确保 `h` 分区对应各市场的本地小时。本表属于数仓末端监控表，不用于业务指标统计，仅服务于数据质量治理场景。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 分区键，数据业务日期，格式 yyyy-MM-dd |
| `h` | int | 分区键，小时（0-23），对应各地区本地时区的小时分区 |

### 维度：地区与广告入口

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码（如 MY、TH、VN 等），对应上游日志的市场归属，由参数化调度注入 |
| `entrance` | int | 广告入口类型编码，标识广告曝光发生的页面/场景入口（如搜索、首页、类目页等） |

### 指标：数据行数总量

| 字段 | 类型 | 说明 |
|------|------|------|
| `row_count` | bigint | 当前小时分区内，该 `grass_region` + `entrance` 组合对应的原始日志总行数，即 `COUNT(1)` |

### 指标：字段完整性统计

| 字段 | 类型 | 说明 |
|------|------|------|
| `pricing_type__column_count` | bigint | `pricing_type` 字段非空行数（`COUNT(pricing_type)`，NULL 值不计入）|
| `pricing_type_null_count` | bigint | `pricing_type` 字段为 NULL 的行数。⚠️ NULL 率需用 `pricing_type_null_count / row_count` 计算，不可直接 SUM 多行后作比率 |
| `ads_id__column_count` | bigint | `ads_id` 字段非空行数 |
| `ads_id_null_count` | bigint | `ads_id` 字段为 NULL 的行数。⚠️ NULL 率需用 `ads_id_null_count / row_count` 计算，跨维度聚合时分子分母需分别 SUM 后再相除 |
| `shop_id__column_count` | bigint | `shop_id` 字段非空行数 |
| `shop_id_null_count` | bigint | `shop_id` 字段为 NULL 的行数。⚠️ 同上，不可直接 SUM 后作比率 |
| `placement__column_count` | bigint | `placement` 字段非空行数 |
| `placement_null_count` | bigint | `placement` 字段为 NULL 的行数。⚠️ 同上，不可直接 SUM 后作比率 |
| `entrance__column_count` | bigint | `entrance` 字段非空行数（`COUNT(entrance)`，用于校验 `entrance` 维度本身是否存在 NULL） |
| `entrance_null_count` | bigint | `entrance` 字段为 NULL 的行数。⚠️ 注意：`entrance` 同时作为 GROUP BY 维度，若其本身存在 NULL，会产生一条 `entrance IS NULL` 的分组行，此字段用于识别该情形 |
| `request_id__column_count` | bigint | `request_id` 字段非空行数 |
| `request_id_null_count` | bigint | `request_id` 字段为 NULL 的行数。⚠️ 同上，不可直接 SUM 后作比率 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定 `grass_date` 和 `h` 两个分区字段**，否则将触发全表扫描，覆盖所有历史日期与小时分区，导致资源浪费与查询超时。

```sql
-- 推荐写法：指定具体日期和小时
WHERE grass_date = '2026-04-22'
  AND h = 10
```

如需分析某一天的全天汇总，应明确指定 `grass_date` 并对 `h` 做范围过滤（0-23）：

```sql
WHERE grass_date = '2026-04-22'
  AND h BETWEEN 0 AND 23
```

此外，建议按需过滤 `grass_region` 和 `entrance`，避免跨地区混合聚合导致口径错误。

### 不可直接 SUM 的字段

本表所有 `*_null_count` 字段均为**分组内的绝对计数**，不代表任何比率，跨维度聚合时须分别累加后再计算：

| 场景 | 错误做法 | 正确做法 |
|------|----------|----------|
| 计算某字段 NULL 率 | `SUM(ads_id_null_count) / SUM(ads_id_null_count + ads_id__column_count)` 直接对比率求均值 | `SUM(ads_id_null_count) / SUM(row_count)` |
| 汇总多个 entrance 的 NULL 率 | 对各行 NULL 率求 AVG | 先 `SUM(ads_id_null_count)`，再除以 `SUM(row_count)` |
| 校验数据完整性 | 仅看 `*__column_count` | 对比 `*__column_count + *_null_count` 与 `row_count` 是否一致 |

> **完整性校验公式**：`pricing_type__column_count + pricing_type_null_count = row_count`（对任意字段均成立，可用于验证统计口径）

### 时效性说明

- 本表按小时调度，每个 `(grass_date, h)` 分区在对应小时结束后约 1 小时内写入，**数据存在约 1 小时的延迟**。
- 查询最新数据时，请勿直接查询当前小时分区，应查询 **当前时间 - 1 小时** 对应的分区，确保数据已完整写入。
- 采用 `INSERT OVERWRITE` 写入模式，同一分区可被重跑覆盖，数据具有幂等性，无重复累加风险。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 广告曝光原始日志小时表，提供 `pricing_type`、`ads_id`、`shop_id`、`placement`、`entrance`、`request_id` 等字段，是本表唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_ads_report_hi__reg_s0_live
  （过滤条件：grass_date = ${BIZ_DT} AND h = ${BIZ_H}）
           │
           │  GROUP BY grass_region, grass_date, h, entrance
           │
           ├─ COUNT(1)                          → row_count
           ├─ COUNT(pricing_type)               → pricing_type__column_count
           ├─ SUM(CASE WHEN pricing_type IS NULL THEN 1 ELSE 0 END) → pricing_type_null_count
           ├─ COUNT(ads_id)                     → ads_id__column_count
           ├─ SUM(CASE WHEN ads_id IS NULL ...)  → ads_id_null_count
           ├─ COUNT(shop_id)                    → shop_id__column_count
           ├─ SUM(CASE WHEN shop_id IS NULL ...) → shop_id_null_count
           ├─ COUNT(placement)                  → placement__column_count
           ├─ SUM(CASE WHEN placement IS NULL ...)→ placement_null_count
           ├─ COUNT(entrance)                   → entrance__column_count
           ├─ SUM(CASE WHEN entrance IS NULL ...) → entrance_null_count
           ├─ COUNT(request_id)                 → request_id__column_count
           └─ SUM(CASE WHEN request_id IS NULL ...)→ request_id_null_count
                          │
                          ▼
  mp_paidads.ads_report_ng_data_quality_1h__reg_s0_live
          （INSERT OVERWRITE PARTITION(grass_date, h)）
```

### 注意事项

1. **无 CTE 结构**：本 ETL 为单层 `SELECT ... FROM ... WHERE ... GROUP BY` 逻辑，无中间 CTE，结构简洁，逻辑清晰。

2. **分区写入幂等**：使用 `INSERT OVERWRITE ... PARTITION(grass_date, h)` 写入，每次调度仅覆盖当前小时分区，历史分区不受影响，支持安全重跑。

3. **NULL 统计口径**：`*__column_count` 使用 `COUNT(字段名)` 统计（SQL 标准：NULL 不计入 COUNT），`*_null_count` 使用 `SUM(CASE WHEN ... IS NULL THEN 1 ELSE 0 END)` 显式统计，两者之和应严格等于 `row_count`，可用此等式做数据质量自检。

4. **entrance 字段的双重角色**：`entrance` 同时是 GROUP BY 的分组维度和被监控的质量字段。若上游数据中 `entrance` 本身存在 NULL 值，则会产生一条 `entrance = NULL` 的分组行，`entrance_null_count` 字段可识别此类异常，使用时需留意。

5. **参数化调度**：ETL 通过 `${BIZ_DT}`、`${BIZ_H}`、`${region}`、`${timezone}` 等参数化变量调度，各地区按本地时区独立运行，SQL 中出现的具体地区或时区值均为调度模板实例，不代表本表仅覆盖单一地区。

6. **存储格式**：表以 Parquet 列式格式存储，对聚合查询友好，建议查询时利用列裁剪只读取所需字段。

---

*文档生成时间：2026-04-22*