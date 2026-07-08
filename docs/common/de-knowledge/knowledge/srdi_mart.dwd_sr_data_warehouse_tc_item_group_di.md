<!-- ads-workspace-gdoc-sync: gdoc_id=1LhkcFUojebwsl_fjR05pMLOs4le2cELSS5Y1kR8BY9w gdoc_url=https://docs.google.com/document/d/1LhkcFUojebwsl_fjR05pMLOs4le2cELSS5Y1kR8BY9w/edit -->

# srdi_mart.dwd_sr_data_warehouse_tc_item_group_di

**分层：** DWD（明细数据层）
**主键：** `rule_id` + `item_group_id` + `shop_id` + `item_id`（分区内唯一）
**分区：** `grass_region`（区域）/ `local_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 44 次

---

## 业务描述

本表存储搜推（SR）业务中**投放规则与商品分组**的每日最新快照明细数据，是对小时级明细表 `dwd_sr_data_warehouse_tc_item_group_hi` 的日级去重汇聚结果。

**核心业务场景：**
- 记录某条投放规则（`rule_id`）下，特定店铺（`shop_id`）中各商品（`item_id`）所属商品分组（`item_group_id`）的当天最新状态。
- 反映商品分组的生效状态、所属场景（`scenes`）、分组目标（`target_group`）以及规则时效窗口（`rule_start_time` / `rule_end_time`）。
- 通过取当天最后一条小时快照（`rn=1`）去重，确保每个 `(rule_id, item_group_id, shop_id, item_id)` 组合在日分区内仅保留一条最新记录；同时以窗口函数取当天 `item_group_if_ongoing` 的最大值，反映该组合在当天是否曾处于进行中状态。

**适合回答的问题：**
- 某天某区域下，某规则/店铺/商品的商品分组归属及状态是什么？
- 某商品分组当天是否仍在生效（`item_group_if_ongoing`）？
- 某规则下涉及哪些场景（`scenes`）和分组目标（`target_group`）？
- 某任务（`task_status`）在指定日期的商品覆盖范围？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识，如 `TH`、`PH`、`VN` 等，用于多区域分区隔离 |
| `local_date` | date | 业务本地日期，数据所属的日分区 |

### 维度：规则与商品分组标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `rule_id` | bigint | 投放规则 ID，与商品分组共同构成去重主键 |
| `item_group_id` | string | 商品分组 ID；源表过滤条件保证该字段非空（或 target_type=5） |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |

### 维度：分组属性与场景

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_group` | int | 分组目标类型，标识商品分组所属的目标类别 |
| `scenes` | string | 投放场景标识，如搜索、推荐等场景 |
| `item_group_target` | string | 商品分组的具体目标描述或配置信息 |

### 维度：时间与状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_group_start_time` | bigint | 商品分组生效开始时间（Unix 时间戳，毫秒或秒级，以上游为准） |
| `rule_start_time` | bigint | 规则生效开始时间（Unix 时间戳） |
| `rule_end_time` | bigint | 规则生效结束时间（Unix 时间戳） |
| `mtime` | bigint | 记录最后修改时间（Unix 时间戳），对应小时快照中当天最新一条的 mtime |
| `task_status` | int | 任务状态码，标识当前投放任务所处阶段或状态 |

### 指标：分组进行状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_group_if_ongoing` | int | 商品分组当天是否处于进行中状态；由 ETL 取同一 `(rule_id, item_group_id, shop_id, item_id)` 在当天所有小时快照中 `item_group_if_ongoing` 的 **最大值**，即当天任意时刻曾生效则为 1 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则将触发全表扫描：
  ```sql
  WHERE grass_region = '<目标区域>'
    AND local_date = '<目标日期>'
  ```
- `grass_region` 为多区域分区，查询时务必明确指定目标区域，避免跨区域扫描。

### 不可直接 SUM / AVG 的字段

| 字段 | 原因 |
|------|------|
| `item_group_if_ongoing` | 该字段为当天历史最大值派生指标（非原始事实），多行聚合 SUM 无业务意义，应作为状态标志使用（`= 1` / `= 0`） |
| `rule_start_time` / `rule_end_time` / `item_group_start_time` / `mtime` | 时间戳字段，直接 SUM/AVG 无意义，应用于范围过滤或时间差计算 |

### 时效性说明

- 本表为 **日级快照表**（`_di` 后缀），每天 INSERT OVERWRITE 全量覆盖当日分区。
- 每个分区内每个主键组合 `(rule_id, item_group_id, shop_id, item_id)` **仅保留当天最新一条**小时快照记录（按 `local_hour` 降序取第 1 条）。
- 数据反映的是截至当天最后一次更新的状态，**不保留历史变更过程**，如需变更历史请查询上游小时表 `dwd_sr_data_warehouse_tc_item_group_hi`。
- 数据通常在当日 ETL 完成后可用，存在一定延迟，不适用于实时场景。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwd_sr_data_warehouse_tc_item_group_hi` | 小时级商品分组明细表，提供当天所有小时快照数据；ETL 从中筛选当日分区数据，去重后写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_tc_item_group_hi
  （小时级明细，当日分区 + 目标区域过滤）
        │
        ▼
  临时视图：item_group_${grass_region_without_quote}
  ├── row_number() 按 (rule_id, item_group_id, shop_id, item_id) 分组，local_hour 降序排名
  └── max(item_group_if_ongoing) 按同维度分组取当天最大值
        │
        ▼（取 rn = 1，即每组最新一条）
srdi_mart.dwd_sr_data_warehouse_tc_item_group_di
  （日级最新快照，INSERT OVERWRITE 指定分区）
```

### 关键步骤

1. **Statement 1 — 创建临时视图**
   - 从上游小时表读取指定 `grass_region` 和 `local_date` 的数据。
   - 过滤条件：`target_type = 5 OR item_group_id IS NOT NULL`，排除脏数据（2023-11-15 起上游已不产生脏数据）。
   - 使用 `ROW_NUMBER()` 窗口函数，按 `(rule_id, item_group_id, shop_id, item_id)` 分组，按 `local_hour DESC` 排序，生成行号 `rn`，用于保留最新小时快照。
   - 使用 `MAX(item_group_if_ongoing)` 窗口函数，按同一分组取当天进行中状态最大值，命名为 `today_item_group_if_ongoing`。

2. **Statement 2 — INSERT OVERWRITE 写目标分区**
   - 从临时视图筛选 `rn = 1`，即每个主键组合当天最新一条记录。
   - 将 `today_item_group_if_ongoing` 映射为目标字段 `item_group_if_ongoing`。
   - 以 `INSERT OVERWRITE` 方式写入目标表指定分区（`grass_region` + `local_date`），覆盖当日已有数据。

### 注意事项

- **单写入文件**：本表仅有 1 个 ETL 文件，无 multi-writer 风险，分区写入逻辑唯一。
- **参数化分区**：SQL 中使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 等运行时参数，需由调度框架正确注入，否则将导致分区混乱或查询条件失效。
- **INSERT OVERWRITE 幂等性**：每次运行会覆盖目标分区，重跑安全，但需保证上游小时表在 ETL 触发前已完成当日所有小时数据写入，否则 `rn=1` 取到的最新小时可能不完整。
- **脏数据过滤**：上游过滤条件 `target_type=5 or item_group_id is not null` 为历史兼容逻辑，2023-11-15 后上游已无脏数据，但过滤条件仍保留以防万一。

---

*文档生成时间：2026-05-17*