<!-- ads-workspace-gdoc-sync: gdoc_id=1Zv8-m8G-JAuHS0t60kEN5OKm2E1Tpqv0yz0HXjm6m0Q gdoc_url=https://docs.google.com/document/d/1Zv8-m8G-JAuHS0t60kEN5OKm2E1Tpqv0yz0HXjm6m0Q/edit -->

# mp_paidads.ads_tracking_data_quality_1h

**分层**：ADS（应用数据服务层）
**主键**：`grass_region, entrance, grass_date, h`
**分区**：`grass_date`（日期分区）、`h`（小时分区）
**更新频率**：每小时调度一次
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是付费广告追踪日志的**数据质量监控宽表**，以每小时为粒度，统计广告曝光/点击追踪日志（`ods_log_ads_tracking_hi`）中各关键字段的非空率与异常值比例。表中记录了每个地区（`grass_region`）、每个广告入口（`entrance`）在特定小时内的日志总行数，以及 `pricing_type`、`ads_id`、`item_id`、`shop_id`、`placement`、`entrance`、`request_id` 等核心字段的有效值计数与缺失/异常计数。

本表的典型使用场景包括：**日志质量大盘监控**（如每小时自动巡检各字段空值率是否超阈值）、**广告数据链路告警**（当某小时某字段空值率骤升时触发报警）、以及**追踪日志问题定位**（按 `entrance` 下钻分析哪类广告入口数据质量较差）。各地区按本地时区参数化调度，确保各市场质量数据在本地业务时间维度下可比。

本表是付费广告数据治理的核心监控资产，帮助数据工程和业务团队快速感知上游追踪日志的数据健康状态，是数据质量 SLA 保障的重要依据。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 业务日期分区，格式 `yyyy-MM-dd`，对应追踪日志的本地日期 |
| `h` | int | 小时分区，取值 0–23，对应业务日期内的小时粒度 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识（如 `SG`、`MY`、`TH` 等），各地区通过 `${region}` 参数化调度写入 |
| `entrance` | string | 广告入口标识，从追踪日志 JSON 中提取（优先取 `item.json_data.entrance`，兜底取根层 `json_data.entrance`），用于区分不同广告展示入口 |

---

### 指标：日志行数总量

| 字段 | 类型 | 说明 |
|------|------|------|
| `row_count` | bigint | 当前分区（地区 + 日期 + 小时 + 入口）内，过滤 `operation IN (1,2)` 且 `adsid > 0` 后的追踪日志总条数，作为分母基准 ⚠️ 不同 `entrance` 的 `row_count` 可求和得到地区小时总量，但需注意过滤条件（`adsid > 0`）已排除无效广告日志 |

---

### 指标：pricing_type 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `pricing_type__column_count` | bigint | `pricing_type` 字段非 NULL 的记录数（即 `COUNT(pricing_type)`） |
| `pricing_type_null_count` | bigint | `pricing_type` 字段为 NULL 的记录数 ⚠️ 空值率需用 `pricing_type_null_count / row_count` 计算，不可直接 SUM 后比较 |

---

### 指标：ads_id 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id__column_count` | bigint | `ads_id` 字段非 NULL 的记录数（即 `COUNT(ads_id)`） |
| `ads_id_null_count` | bigint | `ads_id` 字段为 NULL 的记录数 ⚠️ 注意上游过滤已限定 `adsid > 0`，此处 NULL 通常来源于 JSON 解析异常；空值率需用 `ads_id_null_count / row_count` 计算 |

---

### 指标：item_id 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id__column_count` | bigint | `item_id` 字段非 NULL 的记录数（即 `COUNT(item_id)`） |
| `item_id_null_count` | bigint | `item_id <= 0` 的记录数 ⚠️ 此字段语义为"无效值计数"而非严格 NULL 计数——ETL 中判断条件为 `item_id <= 0`，包含零值与负值，口径与其他字段的 NULL 判断不同，对比时需特别注意 |

---

### 指标：shop_id 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id__column_count` | bigint | `shop_id` 字段非 NULL 的记录数（即 `COUNT(shop_id)`） |
| `shop_id_null_count` | bigint | `shop_id <= 0` 的记录数 ⚠️ 与 `item_id_null_count` 相同，判断条件为 `shop_id <= 0`（非严格 NULL），含零值与负值，代表无效店铺 ID 数量 |

---

### 指标：placement 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `placement__column_count` | bigint | `placement` 字段非 NULL 的记录数（即 `COUNT(placement)`） |
| `placement_null_count` | bigint | `placement < 0` 的记录数 ⚠️ 判断条件为 `placement < 0`（负数为异常），不含零值；`placement = 0` 视为合法值，口径与其他字段不同，需注意 |

---

### 指标：entrance 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `entrance__column_count` | bigint | `entrance` 字段非 NULL 的记录数（即 `COUNT(entrance)`） |
| `entrance_null_count` | bigint | `entrance` 字段为 NULL 的记录数 ⚠️ `entrance` 同时作为分组维度；当 `entrance` 为 NULL 时，该组数据仍会产生一行记录（`entrance = NULL`），统计其自身空值需结合 `entrance_null_count` 与 `entrance__column_count` 判断 |

---

### 指标：request_id 字段质量

| 字段 | 类型 | 说明 |
|------|------|------|
| `request_id__column_count` | bigint | `request_id` 字段非 NULL 的记录数（即 `COUNT(request_id)`） |
| `request_id_null_count` | bigint | `request_id` 字段为 NULL 的记录数 ⚠️ 空值率需用 `request_id_null_count / row_count` 计算，`request_id` 缺失通常意味着请求链路追踪断裂，对归因分析影响较大 |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 类型 | 说明 | 遗漏后果 |
|----------|------|------|----------|
| `grass_date` | 分区 | **必须指定**，格式 `yyyy-MM-dd`，例：`grass_date = date '2026-04-22'` | 遗漏将触发全量分区扫描，扫描数据量巨大，严重影响性能 |
| `h` | 分区 | 建议同时指定，例：`h = 10`；若需分析全天数据，可省略但应明确 `grass_date` | 仅指定 `grass_date` 不指定 `h` 会扫描当天 24 个小时分区，数据量较大 |
| `grass_region` | 维度 | 建议在需要单地区分析时指定，避免跨地区数据混合 | 多地区数据叠加可能导致质量指标失真 |

**推荐最小过滤示例**：
```sql
WHERE grass_date = date '2026-04-22'
  AND h = 10
  AND grass_region = 'SG'
```

---

### 不可直接 SUM 的字段

本表所有 `_null_count` 与 `__column_count` 字段在**跨 entrance 聚合**时可直接 SUM（因原始数据按 entrance 分组，SUM 还原后仍为正确总量）。但以下场景需注意正确计算方式：

| 字段 / 派生指标 | 错误用法 | 正确计算方式 |
|----------------|----------|-------------|
| 各字段空值率 | 直接对 `null_count` 与 `column_count` 做比值 | 先 SUM `null_count`，再 SUM `row_count`，最后相除：`SUM(xxx_null_count) / SUM(row_count)` |
| `item_id_null_count` | 当作 NULL 值计数使用 | 实为 `item_id <= 0` 计数（含零值、负值），表示无效 item_id，语义是"无效值"而非"缺失值" |
| `shop_id_null_count` | 当作 NULL 值计数使用 | 实为 `shop_id <= 0` 计数，与 `item_id_null_count` 口径相同，表示无效 shop_id |
| `placement_null_count` | 与其他字段 null_count 类比 | 实为 `placement < 0` 计数（`placement = 0` 属合法值），三类字段异常判断标准不统一，横向对比时需区分 |

---

### 时效性说明

本表按小时双分区（`grass_date + h`）写入，数据产出依赖上游 `ods_log_ads_tracking_hi` 的到达情况。查询最新质量状态时，应取**已完成调度的最近小时分区**，避免使用尚未写入完毕的当前小时分区，否则 `row_count` 偏低将导致空值率虚高。各地区因时区不同，同一 UTC 时刻对应的本地 `h` 值存在差异，跨地区比较时需注意时区对齐。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` | 广告追踪原始日志表（ODS 层，按小时分区），提供追踪事件明细，包含 `items` 数组（explode 后逐条分析字段质量） |

---

## ETL 逻辑摘要

### 数据流

```
mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
  │
  │  过滤条件：
  │    grass_date = ${BIZ_DT}
  │    h = ${BIZ_H}
  │    operation IN (1, 2)   -- 仅保留曝光/点击事件
  │    item.adsid > 0         -- 排除无效广告
  │
  │  LATERAL VIEW EXPLODE(items) AS item
  │    提取字段：entrance, pricing_type, ads_id,
  │              item_id, shop_id, placement, request_id
  │
  ▼
[CTE: tracking_base]  -- 字段标准化与 JSON 解析（含 COALESCE 兜底逻辑）
  │
  │  GROUP BY grass_region, grass_date, h, entrance
  │
  │  聚合计算：
  │    COUNT(1)                    → row_count
  │    COUNT(field)                → field__column_count
  │    SUM(CASE WHEN ... THEN 1)   → field_null_count（各字段异常判断逻辑不同）
  │
  ▼
mp_paidads.ads_tracking_data_quality_1h__reg_s0_live
  （INSERT OVERWRITE，按 grass_date + h 双分区写入）
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `tracking_base` | `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` | 对追踪日志进行预处理：EXPLODE `items` 数组展开为行级数据，使用 `COALESCE` 对 `entrance`、`placement`、`request_id` 等字段做多层 JSON 路径兜底解析（优先取 `item.json_data` 内字段，兜底取根层 `json_data`），统一字段命名后供下游聚合使用 |

---

### 注意事项

1. **字段解析优先级**：`entrance`、`placement`、`request_id` 均使用 `COALESCE` 多路径兜底，ETL 中优先从 `item.json_data` 提取，失败后从根层 `json_data` 提取。这意味着同一字段可能来自不同 JSON 路径，若两路径均为 NULL 才计入 null_count，问题排查时需关注具体来源。

2. **异常值判断口径不统一**：
   - `pricing_type`、`ads_id`、`entrance`、`request_id`：判断条件为 `IS NULL`（严格空值）
   - `item_id`、`shop_id`：判断条件为 `<= 0`（含零值与负值，表示无效 ID）
   - `placement`：判断条件为 `< 0`（负数才异常，零值合法）
   
   跨字段横向对比空值率时，必须理解上述口径差异，避免误判。

3. **上游过滤已生效**：ETL 在读取上游时已过滤 `operation IN (1,2)` 和 `adsid > 0`，本表数据**不包含** operation 为其他值或 adsid 为 0/负数的日志，`row_count` 反映的是过滤后的有效事件数，而非上游原始总量。

4. **INSERT OVERWRITE 写入模式**：每次调度按 `(grass_date, h)` 覆盖写入，若上游数据在同一小时内有补数或重跑，本表对应分区会被完整覆盖，历史分区不受影响。

5. **参数化调度**：`${BIZ_DT}` 和 `${BIZ_H}` 为调度框架注入的业务日期和小时参数；`${region}` 和 `${timezone}` 控制地区与时区，各地区独立调度，互不干扰。文档中出现的任何具体地区代码仅为模板实例，本表覆盖所有已接入付费广告追踪的地区。

---

*文档生成时间：2026-04-22*