<!-- ads-workspace-gdoc-sync: gdoc_id=1aGcLoWYw5dZY2Bfn8oDdYeb-8nQj-rD7QX-RaS8dedE gdoc_url=https://docs.google.com/document/d/1aGcLoWYw5dZY2Bfn8oDdYeb-8nQj-rD7QX-RaS8dedE/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_ni_newitem_90d_pool_di

**分层：** ADS（应用数据层）
**主键：** `item_id`（分区内唯一，结合 `grass_region` + `local_date`）
**分区：** `grass_region`（站点/区域）、`local_date`（本地日期）
**更新频率：** 每日全量刷新（Daily Overwrite）
**访问频次：** 3,889 次

---

## 业务描述

本表为**搜推数仓 TC 站点新品 90 天候选池**日增量表，记录在各大区（`grass_region`）当前分区日期（`local_date`）时，上线时间在最近 90 天以内（即创建日期介于 `local_date - 89` 至 `local_date` 之间）的有效在售商品，并标注其是否为付费广告投放商品（ROI2 广告位）。

**核心业务场景：**
- 为搜索、推荐召回模块提供新品候选池，支持新品流量扶持策略。
- 区分广告投放（`ads`）与自然流量（`org`）新品，辅助效果归因与策略差异化。
- 结合商品上线天数（`create_diff_days`）支持新品生命周期分析与阶梯流量分配。

**适合回答的问题：**
- 某站点某天新品池中共有多少商品？其中广告/自然商品各占多少？
- 某类目（`level1_global_be_category`）下近 90 天新品数量及分布如何？
- 某商品上线第几天？是否正在进行 ROI2 广告投放？
- 某店铺（`shop_id`）当前有多少新品进入候选池？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `MY`、`TH`、`ID` 等；每个分区对应一个站点 |
| `local_date` | date | 本地日期分区，即数据统计日期（ETL 调度日期） |

### 维度：商品基本信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | string | 商品 ID，商品的唯一标识 |
| `shop_id` | string | 店铺 ID，商品所属店铺 |
| `level1_global_be_category` | string | 商品一级全球后端类目，用于大类目维度分析 |

### 维度：广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_type` | string | 广告类型标识：`ads` 表示该商品当前存在 ROI2（placement 40 或 50）广告投放；`org` 表示纯自然流量商品 |

### 维度：商品创建时间信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `create_date` | date | 商品创建日期（精确到天），由 `create_datetime` 截取前 10 位转换而来 |
| `create_datetime` | string | 商品创建时间（精确到秒级字符串，格式 `yyyy-MM-dd HH:mm:ss`） |
| `create_diff_days` | int | 商品从创建日期至当前分区日期（`local_date`）的天数差，即商品上线天数；范围为 0～89 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定两个分区字段**，避免全表扫描：
  ```sql
  WHERE grass_region = 'MY'
    AND local_date = '2025-05-16'
  ```
- 若需要跨站点查询，建议枚举 `grass_region IN (...)` 而非省略该条件。
- 本表每日全量 Overwrite 当天分区，若需历史数据应明确指定历史 `local_date`，不同日期的候选池数据独立、不累积。

### 不可直接 SUM 的字段

- `create_diff_days`：为单商品的天数差，跨商品聚合应使用 `AVG`、`MAX`、`MIN` 等，直接 `SUM` 无业务意义。
- `ads_type`：枚举型字符串，聚合时需先 `CASE WHEN` 转换为数值再统计。

### 时效性说明

- 本表属于 **`_di`（每日增量覆写）** 类型，每日调度完成后当日分区数据可用，通常于次日凌晨完成前一自然日的数据写入。
- `create_diff_days` 的计算以分区 `local_date` 为基准，跨日读取同一商品时该值会随分区日期变化。
- 新品候选池窗口固定为 **90 天**（`create_diff_days` 在 0 至 89 之间），超过 90 天的商品不会出现在任意分区中。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_item.dim_item__reg_s0_live` | 商品维度主表，提供商品 ID、店铺、类目、创建时间、在售状态等基础信息；以 `tz_type = 'local'`、`status = 1` 过滤出当日有效在售商品，并限制创建时间在近 90 天内 |
| `paimon.mp_paidads.dim_active_item__reg_s0_live` | 付费广告活跃商品表，提供当前处于 ROI2 广告投放（placement 40/50）的商品列表，用于标注 `ads_type` |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.dim_item__reg_s0_live
        │  过滤：站点 + 日期 + 在售 + 90天新品
        ▼
  newitem_candidate（临时视图）
        │
        │   LEFT JOIN（on item_id）
        │
paimon.mp_paidads.dim_active_item__reg_s0_live
        │  过滤：站点 + placement IN (40, 50)
        ▼
  ads_active_item（临时视图）
        │
        ▼
  INSERT OVERWRITE → ads_sr_data_warehouse_tc_ni_newitem_90d_pool_di
                      partition(grass_region, local_date)
```

### 关键步骤

**Step 1 — 创建临时视图 `newitem_candidate`**
从商品维度主表中筛选当日（`grass_date = local_date`）、指定站点（`grass_region`）、本地时区（`tz_type = 'local'`）、在售（`status = 1`）且创建日期在近 90 天内（`create_date BETWEEN local_date - 89 AND local_date`）的商品，计算 `create_date`（截取日期部分）和 `create_diff_days`（与 `local_date` 的天数差）。

**Step 2 — 创建临时视图 `ads_active_item`**
从 Paimon 付费广告活跃商品表中筛选指定站点、广告位为 40 或 50（ROI2 广告位）的商品，按 `item_id` 分组取最大 `ads_id`，得到当前有效广告投放商品集合。

**Step 3 — 写入目标表**
将 `newitem_candidate` 与 `ads_active_item` 按 `item_id` 做左连接（LEFT JOIN），若命中广告商品则 `ads_type = 'ads'`，否则 `ads_type = 'org'`，结果以 `INSERT OVERWRITE` 写入目标表对应分区（`grass_region`、`local_date`）。

### 注意事项

- **单 writer，无 multi-writer 风险**：整个 ETL 仅一个 SQL 文件写入该表，不存在多文件并发写入同一分区的问题。
- **分区覆写（OVERWRITE）**：每次调度对目标分区全量重写，重跑时幂等安全，但调度期间读取该分区的查询可能存在短暂数据空窗期。
- **广告数据来源为 Paimon 实时表**：`dim_active_item__reg_s0_live` 为实时/近实时表，调度时间点不同可能导致广告标注结果存在微小差异，需关注 Paimon 表的数据延迟情况。
- **`create_diff_days` 动态性**：该字段值依赖 `local_date` 参数，同一商品在不同日期分区中该值不同，跨分区对比时需注意。
- **模板参数**：SQL 中 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 均为调度系统注入的运行时参数，文档阅读时视为分区对应值即可。

---

*文档生成时间：2026-05-17*