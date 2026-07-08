<!-- ads-workspace-gdoc-sync: gdoc_id=1ScHkfbuyb12mLgDd8PZgYAGNqobgAsqSx3CEeuXz8uk gdoc_url=https://docs.google.com/document/d/1ScHkfbuyb12mLgDd8PZgYAGNqobgAsqSx3CEeuXz8uk/edit -->

# mp_paidads.dws_advertise_item_performance_1d

**分层**：DWS（数据服务层 / 轻度汇总层）
**主键**：`shop_id + item_id + ads_id + placement + tz_type + grass_region + grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 调度，按各地区本地时区参数化驱动）
**引用频次**：0（末端 ADS 层输出表，未被其他候选表直接引用）

---

## 业务描述

本表以「广告商品（Ads Item）」为粒度，汇总每日广告投放的核心曝光、点击、消耗与 GMV 绩效指标，是付费广告（Paid Ads）分析域的日粒度宽表。每行记录代表某个店铺下某条广告在某个投放位（placement）当日的综合表现，覆盖从曝光漏斗顶端到最终成交的完整链路数据。

本表适用于广告主日报、广告效果归因、ROI 分析（CIR/ROAS）、投放位置优化等典型业务场景。分析师可直接以商品粒度横向比较不同广告位的 CTR、CR、CPC 和 CIR，也可按店铺或广告 ID 上卷至更高层次进行汇总分析。

本表通过 `tz_type`、`grass_region`、`grass_date` 三级分区组织数据，各地区按本地时区参数化调度独立写入，保证跨地区对比时口径统一；比率类指标（CTR、CR、CIR、CPC）已在 ETL 中预计算，使用时需注意不可直接跨行 SUM，应回归分子/分母重新计算。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区，标识数据所使用的时区口径（如 `local` 代表各地区本地时区）。查询时**必须指定**，否则触发全表扫描并导致重复计数。 |
| `grass_region` | string | 国家/地区分区，大写字母代码（如 `MX`、`BR`、`TH`）。各地区按参数化调度独立写入，查询时**必须指定**。 |
| `grass_date` | date | 日期分区，数据所属自然日（本地时区）。格式 `yyyy-MM-dd`，查询时**必须指定**。 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 卖家店铺 ID，唯一标识一个店铺。 |
| `user_name` | string | 卖家用户名（来源字段 `seller_name`）。 |
| `item_id` | bigint | 广告投放的商品 ID。 |
| `ads_id` | bigint | 广告计划 ID，唯一标识一条广告。 |
| `placement` | bigint | 广告投放位置 ID，标识广告展示的页面/位置类型。 |
| `item_name` | string | 广告商品名称。⚠️ 为文本维度字段，聚合时请使用 `item_id` 作为 GROUP BY 键，商品名称可能随时间变动。 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt_1d` | bigint | 当日广告商品曝光次数，来源于 `dws_advertise_query_gmv_event_1d`，按 `is_today=1` 过滤后汇总。 |
| `click_cnt_1d` | bigint | 当日广告商品点击次数，同上。 |
| `avg_ads_ranks_1d` | double | 当日广告在页面中的平均排名位置，值越小排名越靠前。⚠️ 为均值字段，跨行聚合需用加权均值（以 `impression_cnt_1d` 为权重）重新计算，不可直接 SUM 或 AVG。 |
| `ctr_1d` | double | 当日点击率（Click-Through Rate），计算逻辑：`click_cnt_1d / impression_cnt_1d`，分母为 0 时取 0.0。⚠️ 为预计算比率，不可直接 SUM，需用 `SUM(click_cnt_1d) / SUM(impression_cnt_1d)` 重新计算。 |

---

### 指标：消耗与成本

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local_1d` | double | 当日广告消耗金额（本地币种），来源于 `dws_advertise_query_gmv_event_1d`。 |
| `expenditure_amt_usd_1d` | double | 当日广告消耗金额（USD），同上。 |
| `cpc_local_1d` | double | 当日每次点击费用（本地币种），计算逻辑：`expenditure_amt_local_1d / click_cnt_1d`，分母为 0 时取 0.0。⚠️ 为预计算比率，不可直接 SUM，需用 `SUM(expenditure_amt_local_1d) / SUM(click_cnt_1d)` 重新计算。 |
| `cpc_usd_1d` | double | 当日每次点击费用（USD），计算逻辑：`expenditure_amt_usd_1d / click_cnt_1d`，分母为 0 时取 0.0。⚠️ 为预计算比率，不可直接 SUM，需用 `SUM(expenditure_amt_usd_1d) / SUM(click_cnt_1d)` 重新计算。 |

---

### 指标：成交与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt_1d` | bigint | 当日广告带来的订单量，来源于 `dws_advertise_query_gmv_event_1d`。 |
| `ads_gmv_amt_local_1d` | double | 当日广告带来的商品 GMV（本地币种），来源于 `dws_advertise_query_gmv_event_1d`。 |
| `ads_gmv_amt_usd_1d` | double | 当日广告带来的商品 GMV（USD），同上。 |
| `cr_1d` | double | 当日转化率（Conversion Rate），计算逻辑：`order_cnt_1d / click_cnt_1d`，分母为 0 时取 0.0。⚠️ 为预计算比率，不可直接 SUM，需用 `SUM(order_cnt_1d) / SUM(click_cnt_1d)` 重新计算。 |
| `cir_1d` | double | 当日广告费用占比（Cost In Return），计算逻辑：`expenditure_amt_local_1d / ads_gmv_amt_local_1d`，分母为 0 时取 0.0，值越低表示广告 ROI 越高。⚠️ 为预计算比率，不可直接 SUM，需用 `SUM(expenditure_amt_local_1d) / SUM(ads_gmv_amt_local_1d)` 重新计算。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全量分区扫描，造成性能问题并产生跨时区/跨地区重复数据：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `grass_region` | `grass_region = 'MX'`（按实际地区填写大写代码） | 扫描全地区数据，结果重复；多地区混合无法对比 |
| `grass_date` | `grass_date = '2026-04-21'` | 扫描全历史数据，性能极差 |
| `tz_type` | `tz_type = 'local'`（绝大多数业务场景使用本地时区口径） | 同一天数据被不同时区口径重复统计，指标虚高 |

**示例**：
```sql
SELECT
    shop_id,
    item_id,
    SUM(impression_cnt_1d)     AS impression_cnt,
    SUM(click_cnt_1d)          AS click_cnt,
    SUM(expenditure_amt_usd_1d) AS expenditure_usd,
    SUM(ads_gmv_amt_usd_1d)    AS gmv_usd,
    SUM(expenditure_amt_usd_1d) / NULLIF(SUM(click_cnt_1d), 0) AS cpc_usd
FROM mp_paidads.dws_advertise_item_performance_1d__reg_s0_live
WHERE grass_region = 'MX'
  AND grass_date   = '2026-04-21'
  AND tz_type      = 'local'
GROUP BY shop_id, item_id;
```

---

### 不可直接 SUM 的字段

以下字段均为 ETL 预计算的比率/均值，**跨行聚合时不能直接 `SUM()` 或 `AVG()`**，必须回归分子分母重新计算：

| 字段 | 错误用法 | 正确用法 |
|------|----------|----------|
| `ctr_1d` | `SUM(ctr_1d)` | `SUM(click_cnt_1d) / NULLIF(SUM(impression_cnt_1d), 0)` |
| `cr_1d` | `SUM(cr_1d)` | `SUM(order_cnt_1d) / NULLIF(SUM(click_cnt_1d), 0)` |
| `cir_1d` | `SUM(cir_1d)` | `SUM(expenditure_amt_local_1d) / NULLIF(SUM(ads_gmv_amt_local_1d), 0)` |
| `cpc_local_1d` | `SUM(cpc_local_1d)` | `SUM(expenditure_amt_local_1d) / NULLIF(SUM(click_cnt_1d), 0)` |
| `cpc_usd_1d` | `SUM(cpc_usd_1d)` | `SUM(expenditure_amt_usd_1d) / NULLIF(SUM(click_cnt_1d), 0)` |
| `avg_ads_ranks_1d` | `AVG(avg_ads_ranks_1d)` | `SUM(avg_ads_ranks_1d * impression_cnt_1d) / NULLIF(SUM(impression_cnt_1d), 0)`（加权均值） |

> **提示**：上述字段在行级明细查询（不做跨行聚合）时可直接读取使用，无需重算。

---

### 时效性说明

本表为 **T+1 日调度**，每天写入前一自然日（本地时区）的完整数据。查询最新数据时，应取 **`grass_date = CURRENT_DATE - 1`**（昨日分区），当天分区数据通常在次日调度完成后才可用。不存在 YTD/TD 累计字段，所有指标均为单日（`_1d`）口径，多日汇总需在查询层自行跨日期求和。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live` | 唯一上游表，提供广告商品粒度的曝光、点击、消耗、订单、GMV 及排名明细事件数据，按地区和日期分区过滤后作为本表原始输入 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live
  │
  │  WHERE grass_region = upper('${region}')
  │    AND grass_date   = date('${grass_date}')
  │  标记 is_today 标志（grass_date = 目标日期 → 1, 否则 → 0）
  │  COALESCE 空值填充为 0
  │
  ▼
[内层子查询] 明细行标记层
  │
  │  WHERE grass_date = date('${grass_date}')
  │  GROUP BY shop_id, item_id, item_name, ads_id, placement,
  │           user_name, tz_type, grass_region, grass_date
  │  SUM(CASE WHEN is_today=1 THEN ... ELSE 0 END) → 各原子指标 _1d
  │  AVG(CASE WHEN is_today=1 THEN avg_ads_ranks END) → avg_ads_ranks_1d
  │
  ▼
[外层主查询] 比率指标预计算层
  │
  │  COALESCE(expenditure / click, 0.0)   → cpc_local_1d / cpc_usd_1d
  │  COALESCE(click / impression, 0.0)    → ctr_1d
  │  COALESCE(order / click, 0.0)         → cr_1d
  │  COALESCE(expenditure_local / gmv_local, 0.0) → cir_1d
  │
  ▼
INSERT OVERWRITE
  dws_advertise_item_performance_1d__${region}_s0_live
  PARTITION (tz_type, grass_region, grass_date)
  │
  ▼
ALTER TABLE ... ADD IF NOT EXISTS PARTITION (grass_date = "${grass_date}")
```

---

### 关键 CTE 说明

本 ETL 无显式 CTE（WITH 子句），使用嵌套子查询实现两层处理：

| 子查询别名 | 来源表 | 作用 |
|------------|--------|------|
| `t`（内层最深层） | `dws_advertise_query_gmv_event_1d__reg_s0_live` | 读取原始事件数据，进行空值填充（COALESCE）并打上 `is_today` 标志位，区分目标日期与其他日期数据 |
| `parquet_group_by_advertise_query_gmv_event_1d`（中间层） | 内层 `t` | 按广告商品维度聚合，使用条件 SUM/AVG 提取目标日指标，输出原子累加指标（`_1d` 后缀） |
| 外层主查询 | 中间层 | 在聚合结果上计算派生比率字段（CTR、CR、CIR、CPC），写入最终分区表 |

---

### 注意事项

1. **`is_today` 标志的作用**：ETL 内层对来源表按 `grass_date = 目标日期` 做过滤，同时打上 `is_today` 标志用于条件聚合，避免窗口数据混入当日汇总。实际两层过滤均指向同一分区，`is_today` 永远为 1，属于防御性编程设计，不影响结果口径。

2. **比率字段分母为 0 时取 0.0**：`ctr_1d`、`cr_1d`、`cir_1d`、`cpc_local_1d`、`cpc_usd_1d` 均使用 `COALESCE(分子/分母, 0.0)` 处理除零，当无点击（`click_cnt_1d = 0`）或无 GMV 时相关比率字段为 0 而非 NULL，**在过滤"有效投放"时请使用原子计数字段（如 `click_cnt_1d > 0`）作为条件，而非比率字段 > 0**。

3. **`INSERT OVERWRITE` 写入模式**：每次调度对目标分区执行覆盖写入，同一分区重跑是幂等的，不会产生重复数据。

4. **`avg_ads_ranks_1d` 的来源**：来源于上游表中已聚合的 `avg_ads_ranks`，在本表中对该字段再次做 `AVG(CASE WHEN is_today=1 THEN avg_ads_ranks END)`，属于对均值的二次均值，可能存在精度损失；如需精确排名分析，建议追溯至上游明细事件层。

5. **调度参数化**：SQL 中的 `${region}`、`${grass_date}`、`${timezone}` 均为调度模板参数，各地区独立触发一次调度任务，最终产出以 `grass_region` 分区隔离的多地区数据。文档中出现的具体代码值仅为模板示例，本表覆盖所有已上线地区。

---

*文档生成时间：2026-04-22*