<!-- ads-workspace-gdoc-sync: gdoc_id=1aeRRjbK4bBvYLIAN-aPErPEdUmSzbvWzK7Sfg8O66FE gdoc_url=https://docs.google.com/document/d/1aeRRjbK4bBvYLIAN-aPErPEdUmSzbvWzK7Sfg8O66FE/edit -->

# srdi_mart.dwd_sr_data_warehouse_rcmd_fll_sampled_user_impression_1d

**分层：** DWD（数据明细层）
**主键：** `user_id` + `item_id` + `event_time` + `scenario_tag`（联合唯一标识一条曝光记录）
**分区：** `grass_region`（大区/国家）、`regional_date`（业务日期）
**更新频率：** 每日（T+1）全量覆盖写入（INSERT OVERWRITE）
**引用频次/访问频次：** 1754

---

## 业务描述

本表记录推荐系统（FLL 频道）**抽样用户**在各推荐场景下的商品曝光明细数据，粒度为**每条曝光事件**（用户 × 商品 × 场景 × 时间）。

数据来源于 `srdi_rt.ods_fll_rcmd` 原始日志，仅保留 `sample_info.user_sampled = true` 的用户，并对推荐列表进行展开（explode），每个被曝光的商品单独成行。当前覆盖以下两个推荐业务场景：

| 原始 bundle | 场景标签（scenario_tag） | 业务描述 |
|---|---|---|
| `daily_discover_main` | `DA_Daily Discover` | 首页每日发现推荐流 |
| `product_detail_page` | `DA_You May Also Like` | 商品详情页猜你喜欢推荐 |

**核心业务场景：**
- 分析推荐系统中抽样用户的曝光行为，支持曝光量、曝光用户数、曝光商品数等指标的计算基础；
- 支持推荐算法效果评估，如曝光→点击→转化漏斗分析；
- 支持按场景（Daily Discover vs. You May Also Like）拆分的推荐效果对比分析。

**适合回答的问题：**
- 某日某大区，抽样用户在推荐场景下共曝光了哪些商品？
- 每个推荐场景的曝光 UV / 曝光 PV 分别是多少？
- 某商品在推荐场景下的曝光用户分布情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/国家标识，如 `SG`、`MY`、`PH` 等，对应 FLL 原始日志中的 `country` 字段 |
| `regional_date` | date | 业务日期（分区日期），数据所属的自然日 |

### 维度：用户与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，来源于 FLL 推荐日志，仅覆盖已抽样用户（`sample_info.user_sampled = true`） |
| `item_id` | bigint | 被曝光的商品 ID，由推荐结果列表（`data[].item_id`）explode 展开后逐行记录 |
| `scenario_tag` | string | 推荐场景标签，由原始 `bundle` 字段映射而来：`DA_Daily Discover`（首页推荐）或 `DA_You May Also Like`（详情页推荐） |

### 指标：事件时间

| 字段 | 类型 | 说明 |
|---|---|---|
| `event_time` | bigint | 曝光事件发生的时间戳（Unix 时间戳，毫秒或秒级，来源于 FLL 日志中的 `timestamp` 字段） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤必须显式指定**，查询时务必同时指定 `grass_region` 和 `regional_date`，否则将触发全表扫描，造成资源浪费：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2024-01-01'
  ```
- 如需跨区域或跨日期汇总，建议以枚举方式列举分区值，避免无谓的分区裁剪失效。

### 不可直接 SUM 的字段

- **`event_time`**：时间戳字段，无业务加总意义，不可 SUM；如需计算时间范围，应使用 `MIN` / `MAX`。
- **曝光 UV（去重用户数）**：本表为明细表，如需计算曝光用户数须使用 `COUNT(DISTINCT user_id)`，不可直接 SUM 行数代替。
- **曝光商品去重数**：同理，需使用 `COUNT(DISTINCT item_id)`。

### 抽样说明

- 本表仅包含**抽样用户**（`sample_info.user_sampled = true`）的曝光数据，**不代表全量用户行为**，在做绝对量估算时需考虑抽样比例进行还原，直接与全量表对比时需注意口径差异。

### 时效性说明

- 表名后缀 `_1d` 表示按自然日粒度产出；
- 每日 T+1 调度，当日数据通常在次日写入完成；
- 采用 `INSERT OVERWRITE` 按分区覆盖写入，历史分区数据不会被追加，重跑同一分区是幂等操作。

### 场景过滤

- 当前仅保留 `bundle in ('daily_discover_main', 'product_detail_page')` 对应的两个场景，其他推荐场景的曝光数据**不在本表范围内**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_rcmd` | FLL 推荐原始日志，提供用户 ID、推荐结果列表（含 item_id）、事件时间戳、bundle 场景标识及用户抽样标记 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_rcmd
  │
  │  过滤：regional_date、country（对应 grass_region）、user_sampled=true
  │  提取：user_id、items（item_id 列表）、timestamp、bundle
  ▼
临时视图 fll_parse_${grass_region_without_quote}
  │
  │  explode(items) → 展开为单条 item 曝光记录
  │  bundle 映射 → scenario_tag
  │  过滤：仅保留两个目标 bundle
  ▼
srdi_mart.dwd_sr_data_warehouse_rcmd_fll_sampled_user_impression_1d
  （分区：grass_region + regional_date，REPARTITION(1000) 写入）
```

### 关键步骤

1. **Statement 1 — 创建临时视图 `fll_parse_*`**
   - 从 `srdi_rt.ods_fll_rcmd` 读取指定大区（`country`）、指定日期（`regional_date`）的数据；
   - 过滤条件 `sample_info.user_sampled = true`，仅保留抽样用户；
   - 提取 `user_id`、推荐列表数组 `transform(data, x -> x.item_id) AS items`、事件时间戳 `timestamp as event_time`、场景标识 `biz_info.rcmd_info.bundle`。

2. **Statement 2 — INSERT OVERWRITE 写入目标表**
   - 基于临时视图，使用 `LATERAL VIEW EXPLODE(items) AS item_id` 将推荐列表展开为单行记录；
   - 通过 `CASE WHEN` 将 `bundle` 映射为 `scenario_tag`；
   - 过滤仅保留 `bundle in ('daily_discover_main', 'product_detail_page')`；
   - 使用 `REPARTITION(1000)` 控制输出文件数；
   - 以 `INSERT OVERWRITE ... PARTITION(grass_region=..., regional_date=...)` 覆盖写入目标分区。

### 注意事项

- **单一写入器（single writer）**：本表仅由一个 ETL 文件写入，无多写入器并发冲突风险。
- **分区覆盖写入**：每次运行以 INSERT OVERWRITE 形式写入指定 `grass_region` + `regional_date` 分区，重跑幂等，但会清空该分区的原有数据，需防止误传分区参数导致数据丢失。
- **参数化分区**：SQL 中使用 `${grass_region}`、`${regional_date}`、`${grass_region_without_quote}` 等模板变量，调度时须正确传参，`grass_region_without_quote` 用于临时视图命名（避免引号在标识符中非法）。
- **大文件输出**：`REPARTITION(1000)` 固定输出 1000 个文件，如数据量较小可能产生大量小文件，需关注存储效率；如数据量大幅增长则可能需要调整。
- **仅覆盖两个 bundle**：ETL 逻辑中硬编码了场景白名单，如新增推荐场景需同步修改 ETL 代码及映射规则。

---

*文档生成时间：2026-05-17*