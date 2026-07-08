<!-- ads-workspace-gdoc-sync: gdoc_id=1gsRHDYi7QBGBsPJa-EyQYybAmCshW2pdIYq-CpDr2WQ gdoc_url=https://docs.google.com/document/d/1gsRHDYi7QBGBsPJa-EyQYybAmCshW2pdIYq-CpDr2WQ/edit -->

# mp_paidads.dws_item_simple_roi2_npb_created_nd

**分层**：DWS（数据汇总层）
**主键**：`item_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（按地区参数化执行）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表面向付费广告智能投放（PaidAds Smart）场景，以**新品/新上架商品（New Product Baseline，NPB）**为分析对象，统计商品自创建之日起在特定时间窗口内积累的大盘流量指标，包括曝光数（近 10 天）、点击数（近 10 天）和加购数（近 20 天）。表名中 `created_nd` 表示口径限定在"创建后 N 天内"的累计统计，`roi2` 暗示该指标体系服务于广告 ROI 二期建模与评估链路。

核心使用场景为：广告系统在为新品制定投放策略时，需要参考商品在平台大盘上的自然流量表现（曝光、点击、加购），以此评估商品的市场潜力、完善 ROI 预测模型，并用于 NPB 投放策略的冷启动决策。

本表按地区与本地日期分区，各地区按本地时区参数化调度，数据口径为商品创建后至统计日的滚动累计值，仅覆盖统计日前 20 天内新创建的在售商品（`status = 1`），可直接关联广告系统宽表使用。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识，当前固定写入 `'local'`，表示数据口径采用各地区本地时区。查询时**必须指定**以避免全表扫描 |
| `grass_region` | string | 地区编码（如 `MY`、`TH`、`VN` 等），各地区独立调度写入。查询时**必须指定** |
| `grass_date` | date | 数据统计日期（本地时区），对应调度参数 `${grass_date}`。查询时**必须指定** |

### 维度：商品基础属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，本表主键，来源于 `mp_item.rt_dim_item__reg_s0_live` |
| `create_datetime` | string | 商品创建时间（本地时区字符串格式），用于计算商品生命周期窗口的起点 |
| `create_timestamp` | bigint | 商品创建时间的 Unix 时间戳（毫秒或秒，取决于上游定义），可用于精确时序排序 ⚠️ 时间戳精度需结合上游表确认，勿直接与秒级/毫秒级时间混用 |

### 指标：平台大盘累计流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_impression_cnt_10d` | bigint | 商品自创建日起、统计日前 10 天内的大盘累计曝光次数（`imp_cnt_1d` 按日滚动累加）。仅统计 `grass_date - 10 <= create_date` 期间的每日数据 ⚠️ 为时间窗口内的累计聚合值，跨行 SUM 会导致重复计数，多日对比需单独取对应分区值 |
| `platform_click_cnt_10d` | bigint | 商品自创建日起、统计日前 10 天内的大盘累计点击次数（`click_cnt_1d` 按日滚动累加），时间窗口与曝光字段一致 ⚠️ 同上，为累计值，不可跨 `grass_date` 分区直接 SUM |
| `platform_atc_cnt_20d` | bigint | 商品自创建日起、统计日前 20 天内的大盘累计加购次数（`atc_cnt_1d` 按日滚动累加），时间窗口为近 20 天 ⚠️ 窗口为 20 天，与曝光/点击（10 天）口径不一致，混用时需注意分母差异；同样不可跨 `grass_date` 分区直接 SUM |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致性能劣化并可能产生数据重复：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前表只写入 `'local'`，不加此过滤仍会扫描所有分区 |
| `grass_region` | `grass_region = 'XX'`（填入目标地区） | 各地区数据独立存储，不限定则返回所有地区数据，结果集膨胀 |
| `grass_date` | `grass_date = '${目标日期}'` | 指标为截至该日期的累计值，不限定则返回所有历史快照，导致重复计数 |

**遗漏后果**：未指定 `grass_date` 会将多日快照叠加，所有累计指标（曝光/点击/加购）均会被错误累加，严重高估实际数值。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确使用方式 |
|------|------|-------------|
| `platform_impression_cnt_10d` | 每日分区均为从商品创建起滚动累计的快照值，跨多个 `grass_date` SUM 会重复累加同一商品同一天的曝光 | 固定单一 `grass_date` 分区，再对多个 `item_id` SUM |
| `platform_click_cnt_10d` | 同上 | 同上 |
| `platform_atc_cnt_20d` | 同上，且时间窗口为 20 天，与曝光/点击窗口不同，比率计算时分子分母时间口径不匹配 | 固定单一 `grass_date` 分区使用；计算 CTR、ATC Rate 等比率时注意字段时间窗口不一致 |
| `create_timestamp` | 时间戳精度（秒 / 毫秒）需与使用场景对齐 | 用前确认上游精度，必要时做单位换算 |

### 时效性说明

本表指标为截至 `grass_date` 的**滚动累计快照**，建议始终取**最新已完成调度的分区日期**（即 T-1 日）的数据作为当前状态参考。若需观察商品流量随时间的变化趋势，应对同一 `item_id` 在不同 `grass_date` 下的值分别查询，而非跨分区 SUM。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_item.rt_dim_item__reg_s0_live` | 提供商品维度信息，包括 `item_id`、`create_datetime`、`create_timestamp`；按 `status = 1` 过滤在售商品，按创建时间过滤近 20 天内新品 |
| `traffic.dws_item_metric_1d__reg_live` | 提供商品每日大盘流量指标（`imp_cnt_1d`、`click_cnt_1d`、`atc_cnt_1d`），取统计日前 20 天内的每日数据，与商品维表 LEFT JOIN 后按时间窗口条件累加 |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.rt_dim_item__reg_s0_live
  │  过滤：status=1，grass_region，
  │         create_datetime 在近20天内（本地时区）
  │
  │  (item 子查询)
  │  输出：item_id, create_datetime, create_timestamp
  │
  └──── LEFT JOIN（on item_id，create_datetime <= grass_date）
  │
traffic.dws_item_metric_1d__reg_live
  │  过滤：grass_region，grass_date in [grass_date-20, grass_date]
  │
  │  (item_metric 子查询)
  │  输出：item_id, imp_cnt_1d, click_cnt_1d, atc_cnt_1d, grass_date
  │
  ▼
按 item_id, create_datetime, create_timestamp GROUP BY
  │
  │  条件累加：
  │    imp_cnt_acc   → create_date >= grass_date-10 时累计
  │    click_cnt_acc → create_date >= grass_date-10 时累计
  │    atc_cnt_acc   → create_date >= grass_date-20 时累计
  │
  ▼
dws_item_simple_roi2_npb_created_nd__reg_s0_live
  分区写入：tz_type='local' / grass_region / grass_date
```

### 关键 CTE 说明

本 ETL 无显式 CTE，核心逻辑通过两个子查询实现：

| 子查询别名 | 来源表 | 作用 |
|-----------|--------|------|
| `item` | `mp_item.rt_dim_item__reg_s0_live` | 筛选指定地区、统计日前 20 天内新创建的在售商品，获取商品 ID 及创建时间信息 |
| `item_metric` | `traffic.dws_item_metric_1d__reg_live` | 获取近 20 天内每日商品大盘流量数据（曝光/点击/加购），供后续按时间窗口条件聚合 |

### 注意事项

1. **时间窗口不对称**：曝光与点击的累计窗口为**近 10 天**（`grass_date - 10`），加购的累计窗口为**近 20 天**（`grass_date - 20`）。三个指标的分母时间范围不一致，直接相除计算 ATC Rate 等比率时口径存在偏差，需业务侧对齐口径再使用。

2. **创建时间过滤的时区转换**：`item` 子查询中，商品创建时间的过滤上界通过 `BIZ_H` 参数将调度时间（Asia/Singapore）转换为各地区本地时区，确保不同地区的"当天"边界正确对齐，各地区按本地时区参数化调度。

3. **LEFT JOIN 语义**：商品维表与流量数据使用 LEFT JOIN，若某商品在创建后尚无流量记录（新品冷启动），三项累计指标将为 `0`（`SUM(IF(..., val, 0))`），不会产生 NULL，可直接用于数值计算。

4. **`insert overwrite` 写入模式**：每次调度全量覆盖对应分区，同一 `grass_date` 分区的数据不存在增量追加，重跑任务不会产生重复数据。

5. **仅覆盖在售商品**：`status = 1` 过滤确保下架或删除商品不进入本表，若商品在创建后 20 天内改变状态，其历史分区数据不会被追溯更新。

---

*文档生成时间：2026-04-22*