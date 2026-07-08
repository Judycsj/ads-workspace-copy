<!-- ads-workspace-gdoc-sync: gdoc_id=1XpHuRRAiUPnRkLo1HnvZQTcX3mYRuI05_1tfXkN8D_k gdoc_url=https://docs.google.com/document/d/1XpHuRRAiUPnRkLo1HnvZQTcX3mYRuI05_1tfXkN8D_k/edit -->

# srdi_mart.ads_sr_data_warehouse_homepage_user_duration_1d

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `local_date`
**分区**：`grass_region`（大区）、`local_date`（业务日期）
**更新频率**：每日一次（T+1）
**引用频次 / 访问频次**：63

---

## 业务描述

本表记录搜推（Search & Recommendation）数仓**首页各模块用户时长**的每日汇总数据，以大区（`grass_region`）和业务日期（`local_date`）为粒度，聚合来自 DWS 层的用户时长明细，输出全平台及各页面模块（封面流、小视频流、直播流、混合流、商品详情页等）的总时长指标。

**核心业务场景**

- 监控首页各内容模块（封面流、Minifeed、视频流、直播流、Mixfeed 等）对用户注意力的占比情况；
- 分析用户从内容模块跳转至商品详情页（PDP）的时长分布，评估内容到商品的转化效率；
- 追踪视频/商品卡片落地直播间的用户时长，衡量短视频与直播场景的联动效果；
- 提供大区维度的时长趋势，支持跨区域运营对比分析。

**适合回答的典型问题**

- 某大区某日，首页各模块（封面流 / 视频流 / 直播流 / 混合流）的用户总时长分别是多少？
- Minifeed / Mixfeed 模块跳转 PDP 页面的时长占全平台时长的比例如何变化？
- 视频模块落地直播间的用户时长趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY、TH 等；所有查询必须指定该分区 |
| `local_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`；所有查询必须指定该分区 |

---

### 维度：汇总粒度

> 本表无独立维度字段，业务粒度由分区字段 `grass_region` + `local_date` 共同确定。

---

### 指标：全平台总时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_duration_1d` | double | 全平台首页用户总时长（秒），为所有模块时长的汇总基准 |

---

### 指标：首页内容模块时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_cover_duration_1d` | double | 首页封面流（Cover Feed）模块用户时长（秒） |
| `dd_minifeed_duration_1d` | double | 首页 Minifeed 模块用户时长（秒） |
| `dd_video_duration_1d` | double | 首页短视频流（Video Feed）模块用户时长（秒） |
| `dd_live_duration_1d` | double | 首页直播流（Live Feed）模块用户时长（秒） |
| `dd_mixfeed_duration_1d` | double | 首页混合流（Mixfeed）模块用户时长（秒） |

---

### 指标：内容模块跳转 PDP 页面时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_pdp_duration_1d` | double | 首页整体跳转商品详情页（PDP）的用户时长（秒） |
| `dd_minifeed_pdp_duraion_1d` | double | Minifeed 模块跳转 PDP 的用户时长（秒）；注意字段名原始存在拼写错误（`duraion`） |
| `dd_video_pdp_duration_1d` | double | 视频流模块跳转 PDP 的用户时长（秒） |
| `dd_live_pdp_duration_1d` | double | 直播流模块跳转 PDP 的用户时长（秒） |
| `dd_mixfeed_pdp_duration_1d` | double | 混合流模块跳转 PDP 的用户时长（秒） |

---

### 指标：内容模块落地直播间时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_video_landing_livestream_duration_1d` | double | 视频流模块落地（跳转）直播间的用户时长（秒） |
| `dd_item_mix_landing_livestream_duration_1d` | double | 商品混合卡片落地直播间的用户时长（秒） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须显式指定**，缺少任一分区条件将触发全表扫描，影响性能并可能返回错误数据：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-01'
  ```
- 若需跨大区汇总，请在 `WHERE` 中枚举所有目标 `grass_region` 值（`IN` 语法），避免遗漏分区剪枝。

### 不可直接 SUM 的字段

- 本表所有指标字段（`double` 类型）均为**分区内的预聚合总和**（来自 DWS 层 `SUM` 汇总）。
- **跨多日或跨多大区的时长合计**：可对 `dd_*_duration_1d` 字段直接 `SUM`，结果有意义。
- **计算各模块时长占比**（如模块时长 / `platform_duration_1d`）：需在查询层做除法，**不可将比值字段直接累加**。

### 字段拼写注意

- `dd_minifeed_pdp_duraion_1d` 字段名中存在历史拼写错误（`duraion` 而非 `duration`），使用时须与 DataMap snapshot 保持一致，切勿自行纠正字段名。

### 时效性说明

- 本表为 `_1d` 后缀的**日粒度表**，每日 T+1 覆盖写入当日分区；
- 数据覆盖逻辑为 `INSERT OVERWRITE PARTITION`，每次调度会完整重写指定 `grass_region` + `local_date` 分区；
- 查询最新数据时，建议先确认目标分区已落地（可通过分区元数据或调度状态确认）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_homepage_user_duration_1d` | DWS 层首页用户时长明细表，按用户粒度或更细粒度存储各模块时长，本表对其进行全量 SUM 聚合后写入 ADS 层 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_homepage_user_duration_1d
    │  WHERE grass_region = ${grass_region}
    │        AND local_date = ${local_date}
    │  SUM 所有时长指标字段
    ▼
srdi_mart.ads_sr_data_warehouse_homepage_user_duration_1d
    partition(grass_region, local_date)
```

### 关键步骤

| 步骤 | 说明 |
|---|---|
| **Step 1：读取 DWS 数据** | 从 `dws_sr_data_warehouse_homepage_user_duration_1d` 按 `grass_region` + `local_date` 过滤，读取当日分区所有行 |
| **Step 2：SUM 聚合** | 对全部 13 个时长指标字段执行 `SUM`，将用户级或更细粒度数据聚合为大区+日期单行汇总 |
| **Step 3：写入目标分区** | `INSERT OVERWRITE PARTITION(grass_region, local_date)` 覆盖写入目标表对应分区，确保幂等性 |

### 注意事项

- **单一写入源**：本表仅有 1 个 ETL 文件，无 multi-writer 风险，分区内数据来源唯一。
- **分区覆盖写入**：每次调度以 `INSERT OVERWRITE` 方式写入，重跑安全，不会产生重复数据。
- **字段拼写不一致**：`dd_minifeed_pdp_duraion_1d`（`duraion` 拼写错误）在 DWS 源表和 ADS 目标表中均已存在，ETL SQL 保持原样透传，上下游已对齐，修复需同步变更两层表结构及 ETL 逻辑。
- **参数化执行**：`${schema}`、`${grass_region}`、`${local_date}` 为调度参数，按大区+日期逐分区触发调度。

---

*文档生成时间：2026-05-17*