<!-- ads-workspace-gdoc-sync: gdoc_id=1xQL_1m2AomtHTB9LG0p7_Bn8vKw9S3WQqcdx38Uzlzk gdoc_url=https://docs.google.com/document/d/1xQL_1m2AomtHTB9LG0p7_Bn8vKw9S3WQqcdx38Uzlzk/edit -->

# srdi_mart.dws_sr_data_warehouse_search_user_stickness_1d

**分层：** dws_search
**主键：** grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 346

---

## 业务描述

本表用于衡量**搜索用户粘性（Search User Stickiness）**，通过在同一分区内同时记录 DAU、WAU、MAU 三个活跃周期的去重用户数，支持对搜索渗透率及用户留存粘性的日常监控与趋势分析。

**核心业务场景：**

- 计算搜索 DAU/MAU、搜索 WAU/MAU 等粘性比率，衡量搜索功能对 Shopee 用户的吸引程度；
- 对比 `search_*` 与 `shopee_*` 系列指标，评估搜索在整体平台活跃用户中的渗透率；
- 支持各大区（grass_region）的横向对比及时序趋势分析。

**适合回答的典型问题：**

- 今日某大区搜索 DAU 是多少？搜索 DAU/MAU 粘性比率是多少？
- 过去一周搜索 WAU 占 Shopee WAU 的渗透率如何变化？
- 各大区搜索用户活跃周期分布如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY、TH 等，用于区分不同市场分区 |
| `local_date` | date | 数据日期（本地日期），每日一个分区，对应 DAU 的统计日期 |

### 维度：无额外维度字段

> 本表为高度聚合的宽表，分区字段即唯一粒度维度，每个 (grass_region, local_date) 组合对应一行汇总数据。

### 指标：搜索活跃用户数

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_dau` | bigint | 当日（local_date）在 Shopee 平台有搜索行为的去重用户数（Daily Active Users with search） |
| `search_wau` | bigint | 近 7 日（local_date 向前推 6 天，含当日）有搜索行为的去重用户数（Weekly Active Users with search） |
| `search_mau` | bigint | 近 30 日（local_date 向前推 29 天，含当日）有搜索行为的去重用户数（Monthly Active Users with search） |

### 指标：Shopee 平台整体活跃用户数

| 字段 | 类型 | 说明 |
|---|---|---|
| `shopee_dau` | bigint | 当日（local_date）Shopee 平台全体去重活跃用户数（Daily Active Users，不限是否有搜索行为） |
| `shopee_wau` | bigint | 近 7 日 Shopee 平台全体去重活跃用户数（Weekly Active Users） |
| `shopee_mau` | bigint | 近 30 日 Shopee 平台全体去重活跃用户数（Monthly Active Users） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 分区过滤条件**，否则将触发全表扫描，导致查询超时或资源超额消耗。示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-06-01'
  ```
- 若需跨日期聚合，请明确限定日期范围（`local_date BETWEEN ... AND ...`）。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `search_dau` / `shopee_dau` | 跨日期 SUM 无业务意义；跨分区的去重用户数需回溯明细层重新去重，不可简单累加 |
| `search_wau` / `shopee_wau` | WAU 为近 7 日窗口去重值，相邻日期存在用户重叠，跨行 SUM 会重复计数 |
| `search_mau` / `shopee_mau` | MAU 为近 30 日窗口去重值，同上，跨行 SUM 无意义 |

> **粘性比率**（如 DAU/MAU）需在查询层自行计算：`search_dau / search_mau`，本表不预存比率字段。

### 时效性说明

- 本表为**每日快照表**（`_1d` 后缀），`local_date` 分区代表当日数据，通常在 T+1 的固定时间窗口内完成写入。
- WAU 和 MAU 指标均为**滑动窗口**预聚合结果（分别对应近 7 日和近 30 日），并非自然周/月统计，每日刷新。
- 不建议用本表的 MAU 字段与外部自然月口径的 MAU 数据直接对比。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_user_activeness_1d` | 提供用户粒度的每日活跃记录（含 `user_id`、`if_search` 搜索标识、`local_date`），作为计算 DAU/WAU/MAU 的明细基础，取近 30 日数据缓存后按窗口聚合 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_user_activeness_1d
    （近 30 日 × 当前 grass_region）
        │
        ▼
  CACHE TABLE（近 30 日全量用户活跃明细）
        │
   ┌────┴────┬────────────┐
   ▼         ▼            ▼
 DAU 视图  WAU 视图    MAU 视图
(当日)   (近 7 日)   (近 30 日)
   └────┬────┴────────────┘
        ▼
  LEFT JOIN 横向拼接
        │
        ▼
  INSERT OVERWRITE 目标分区
  srdi_mart.dws_sr_data_warehouse_search_user_stickness_1d
  PARTITION(grass_region, local_date)
```

### 关键步骤

1. **CACHE TABLE（数据预加载）**
   - 从上游 `dws_sr_data_warehouse_user_activeness_1d` 读取指定 `grass_region` 近 30 日（`date_sub(local_date, 29)` 至 `local_date`）的用户活跃明细，缓存到内存中供后续多次复用。

2. **Temporary View：`user_activeness_dau_*`（DAU 计算）**
   - 筛选 `local_date = ${local_date}`（当日）；
   - `search_dau`：`COUNT(DISTINCT user_id) WHERE if_search = true`；
   - `shopee_dau`：`COUNT(DISTINCT user_id)`（全体活跃用户）。

3. **Temporary View：`user_activeness_wau_*`（WAU 计算）**
   - 筛选 `local_date >= date_sub(${local_date}, 6)`（近 7 日）；
   - `search_wau` / `shopee_wau` 逻辑同上，窗口扩展至 7 日。

4. **Temporary View：`user_activeness_mau_*`（MAU 计算）**
   - 使用缓存全量数据（近 30 日），不额外过滤日期；
   - `search_mau` / `shopee_mau` 逻辑同上，窗口扩展至 30 日。

5. **INSERT OVERWRITE（写入目标表）**
   - 将三个 Temporary View 通过 `LEFT JOIN`（无 ON 条件，即笛卡尔积横向拼接，每个视图均只输出一行汇总）合并为单行结果；
   - 以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 方式写入目标分区，实现幂等性。

### 注意事项

- **单写入器（single writer）**：该表仅由一个 ETL 文件写入，不存在多写竞争风险。
- **分区覆盖写（OVERWRITE）**：每次执行对指定 `(grass_region, local_date)` 分区做全量覆盖，具有幂等性，可安全重跑。
- **LEFT JOIN 无 ON 条件**：DAU/WAU/MAU 三个视图各自输出恰好一行（全聚合），`LEFT JOIN` 等价于笛卡尔积横向合并，逻辑正确；但若上游数据为空导致某视图输出零行，对应字段将为 NULL，需关注数据完整性。
- **CACHE TABLE 生命周期**：缓存表在同一 Spark Session 内有效，五个 statement 共享同一 Session，缓存可正常复用；若 Session 中断则缓存失效，需完整重跑。
- **滑动窗口边界**：WAU 统计区间为 `[local_date-6, local_date]`（7 天），MAU 统计区间为 `[local_date-29, local_date]`（30 天），与自然周/自然月不一致，使用时须注意口径对齐。

---

*文档生成时间：2026-05-17*