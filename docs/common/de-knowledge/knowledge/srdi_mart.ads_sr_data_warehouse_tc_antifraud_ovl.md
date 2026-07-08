<!-- ads-workspace-gdoc-sync: gdoc_id=19zPvyqaIOcsntsK_6vVB802cFrhDeDYCWKZ2Zl3GN7Y gdoc_url=https://docs.google.com/document/d/19zPvyqaIOcsntsK_6vVB802cFrhDeDYCWKZ2Zl3GN7Y/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_antifraud_ovl

**分层：** ADS（应用数据层）
**主键：** `shop_id`（在指定 `grass_region` 分区内唯一）
**分区：** `grass_region`（大区/站点）
**更新频率：** 按区域调度，每次取上游小时表最新快照覆盖写入（准实时，跟随上游 1h 粒度更新）
**引用频次/访问频次：** 404

---

## 业务描述

本表是**搜推（Search & Recommendation）数仓**中针对**TC（平台）反欺诈（Anti-Fraud）**场景的**店铺级别应用层宽表**，以覆盖写（OVERWRITE）方式维护各大区最新快照数据。

核心业务场景包括：

- **店铺反欺诈风控决策支撑**：汇总各店铺近 28 天平均订单量、当前订单限额比例及订单超额（OVL）状态，为平台反欺诈系统提供实时/准实时的风控输入特征。
- **订单异常监控**：识别订单行为明显偏离历史基线（28 天均值）的店铺，辅助判断刷单、异常流量等欺诈行为。
- **订单限额管理**：追踪各店铺的订单限额使用百分比（`order_limit_percentage`）及超额状态（`order_ovl`），支持触发限流或告警策略。

适合回答的问题示例：

- 某大区下哪些店铺当前订单量已超出限额？
- 各店铺近 28 天平均日订单量基线是多少？
- 当前时刻各店铺的订单限额使用率分布如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/站点标识（如 ID、MY、TH 等），作为物理分区键，每个分区存储该区域最新快照 |

### 维度：店铺标识与元信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺唯一标识，表内在同一 `grass_region` 分区下唯一 |
| `update_time` | bigint | 数据更新时间戳（毫秒或秒级 Unix timestamp），来源于上游 DWS 表，反映该条记录的最后更新时刻 |

### 指标：反欺诈订单风控指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_order_cnt_28d` | double | 店铺近 28 天平均订单量，作为订单行为基线，用于衡量当前订单与历史水平的偏离程度 |
| `order_limit_percentage` | double | 当前订单量占订单限额的百分比（比率型指标，取值通常在 [0, 1] 或百分制），反映店铺的限额使用程度 |
| `order_ovl` | double | 订单超额量或超额状态值，表示当前订单量超出限额的程度，用于触发反欺诈限流或告警 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region` 分区过滤**：查询时**必须**指定 `grass_region`，否则将触发全分区扫描，导致性能严重下降。示例：
  ```sql
  WHERE grass_region = 'ID'
  ```
- 本表为**最新快照表**（每次 OVERWRITE），无日期分区，查询即得各区域当前最新数据，无需额外过滤日期。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_limit_percentage` | 比率型指标，跨店铺直接 SUM 无业务含义，聚合需使用加权均值或分布统计 |
| `avg_order_cnt_28d` | 预聚合均值指标，跨店铺直接 SUM 不等于整体均值，需结合原始订单量重新计算 |
| `order_ovl` | 含义为超额程度/状态值，直接 SUM 前需确认字段业务语义（是否为可累加量） |

### 时效性说明

- 本表为**准实时快照表**，上游 `dws_sr_data_warehouse_tc_antifraud_ovl_1h` 为 1 小时粒度小时表，ETL 每次取近 3 天内最新日期的最新小时分区数据覆盖写入。
- 数据延迟通常在 **1 小时以内**，具体以 `update_time` 字段为准。
- 若上游连续 3 天无新数据（异常情况），ETL 可能写入过期数据，使用时建议校验 `update_time` 是否符合预期。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_antifraud_ovl_1h` | 核心来源表，提供小时粒度的店铺反欺诈订单指标，ETL 从中取最新日期+最新小时的数据写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_antifraud_ovl_1h
        │
        ├─ [Step 1] 取近 3 天内最新本地日期 → max_date_view
        │
        ├─ [Step 2] 在最新日期下取最新小时 → max_hour_view
        │
        └─ [Step 3] 按 (max_date, max_hour) 过滤后
                    INSERT OVERWRITE → ads_sr_data_warehouse_tc_antifraud_ovl
                    partition (grass_region = ${grass_region})
```

### 关键步骤

| 步骤 | 操作 | 说明 |
|---|---|---|
| Statement 1 | 创建临时视图 `max_date_view_${grass_region_without_quote}` | 在上游 1h 表中，取指定 `grass_region` 近 3 天（`date_sub(local_date, 3)` 至 `local_date`）内的最大本地日期，解决上游可能存在的延迟或补数据场景 |
| Statement 2 | 创建临时视图 `max_hour_view_${grass_region_without_quote}` | 在 Step 1 得到的最新日期下，取该日期内最大的 `local_hour`，确保读取最新小时分区 |
| Statement 3 | `INSERT OVERWRITE TABLE ... PARTITION (grass_region = ${grass_region})` | 将上游表中满足 `(max_date, max_hour)` 条件的店铺维度及指标字段覆盖写入目标表对应大区分区，实现快照刷新 |

### 注意事项

- **单一写入方**：本表仅有 1 个 ETL 文件，无 multi-writer 风险；各大区通过参数 `${grass_region}` 隔离，分区间互不影响。
- **OVERWRITE 写入**：每次执行均覆盖整个 `grass_region` 分区，不保留历史版本，历史溯源需查上游 DWS 1h 表。
- **日期兜底逻辑**：`max_date` 查询范围为近 3 天，当上游当天数据未就绪时，ETL 会自动回退到近 3 天内最近一次有数据的日期+小时，避免空跑，但可能导致数据短暂滞后。
- **参数依赖**：ETL 依赖运行时参数 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`，调度时需确保参数正确注入。
- **字段顺序**：INSERT 语句显式指定字段列顺序（`shop_id, update_time, avg_order_cnt_28d, order_limit_percentage, order_ovl`），与目标表 DDL 字段顺序解耦，Schema 变更时需同步检查。

---

*文档生成时间：2026-05-17*