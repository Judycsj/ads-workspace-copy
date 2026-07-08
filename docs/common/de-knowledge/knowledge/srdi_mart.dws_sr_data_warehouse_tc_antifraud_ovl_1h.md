<!-- ads-workspace-gdoc-sync: gdoc_id=1VAZo9Lpb4-OZ43SBQVh_GNoin9rhKeIaPTj1h0Pj4m4 gdoc_url=https://docs.google.com/document/d/1VAZo9Lpb4-OZ43SBQVh_GNoin9rhKeIaPTj1h0Pj4m4/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_antifraud_ovl_1h

**分层：** DWS（数据汇总层）
**主键：** `shop_id`（在给定分区组合下唯一）
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 每小时调度一次（1h 粒度，按小时分区写入）
**访问频次：** 5,768 次

---

## 业务描述

本表用于搜推反欺诈（Anti-Fraud）场景下的**店铺订单超限（Order Overshoot / OVL）监控**，服务于 TC（Transaction Compliance / 交易合规）风控链路。

核心业务场景：
- 针对处于**惩罚状态（`punishment_status = 1`）**的店铺，结合其订单限额比例（`order_limit_percentage`）与近 28 天（实际取第 2～29 天）平均日单量（`avg_order_cnt_28d`），计算该店铺在当前限流政策下的**预期超限订单量（`order_ovl`）**。
- 支持反欺诈系统按小时快照式评估各区域受罚店铺的订单风险敞口。

适合回答的问题：
- 当前某区域内哪些店铺处于订单惩罚状态，其限流比例是多少？
- 结合历史平均单量，各受罚店铺的预期超限订单量（风险量）有多大？
- 某时间点（小时粒度）各店铺的反欺诈订单超限快照数据是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/区域标识（如 SG、MY 等），与上游数据 `region` 对应，是本表最顶层分区键 |
| `local_date` | date | 本地日期，由 `regional_date` + `regional_hour` 按 SG→目标区域时区转换得到 |
| `local_hour` | int | 本地小时，由 `regional_date` + `regional_hour` 按 SG→目标区域时区转换得到 |
| `regional_date` | date | 调度基准日期（新加坡时区，SG），即任务运行时的 `regional_date` 参数 |
| `regional_hour` | int | 调度基准小时（新加坡时区，SG），即任务运行时的 `regional_hour` 参数 |

### 维度：店铺信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，受罚店铺的唯一标识，来源于反欺诈惩罚表（`punishment_status = 1`） |
| `update_time` | bigint | 记录更新时间戳（Unix 毫秒或秒级），来源于上游惩罚表的 `update_time` 字段，反映惩罚状态的最新变更时间 |

### 指标：订单限额与超限分析

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_limit_percentage` | double | 订单限额比例（%），由上游惩罚表中 `order_limit`（万分比）除以 10000 再乘以 100 换算而来，取值范围 0～100 |
| `avg_order_cnt_28d` | double | 近 28 天平均日订单量（实际计算窗口为 `local_date` 前第 2～29 天，共 28 天），来源于 `mp_order.dws_seller_gmv_1d__reg_s0_live` 表的 `placed_order_cnt_1d` 字段均值；若该店铺在订单表无历史数据则为 NULL |
| `order_ovl` | double | 预期超限订单量，计算公式：`order_limit_percentage / 100 × avg_order_cnt_28d`（`avg_order_cnt_28d` 为 NULL 时以 0 计），表示在当前限流比例下，历史均量对应的预计超限量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必指定 `grass_region`**：本表按区域分区写入，跨区 UNION 查询会触发全分区扫描，开销极大。
- **务必指定 `regional_date` + `regional_hour`（或 `local_date` + `local_hour`）**：表为小时级快照，不限定时间分区会读取全量历史数据，产生重复计数并严重拉升计算成本。
- 推荐过滤姿势：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-01-01'
    AND regional_hour = 10
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_limit_percentage` | 比率类字段，跨店铺/时间直接 SUM 无业务意义 |
| `avg_order_cnt_28d` | 预聚合均值（28 天 AVG），再次 SUM/AVG 会产生统计误差 |
| `order_ovl` | 由比率 × 均值派生，跨时间分区 SUM 会导致重复累计（同一店铺多个小时快照叠加） |

> **时效性说明：** 本表为**小时级快照表**，每个 `(grass_region, regional_date, regional_hour)` 分区代表该时刻的全量受罚店铺状态，分析时应选取最新分区或明确指定目标时间窗口，避免跨分区累加造成多重计数。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `${table}`（反欺诈惩罚表，运行时参数传入） | 提供处于惩罚状态（`punishment_status = 1`）店铺的 `shop_id`、`order_limit`（万分比限额）、`update_time` |
| `mp_order.dws_seller_gmv_1d__reg_s0_live` | 提供店铺近 28 天（`local_date` 前第 2～29 天）本地时区日粒度下单量 `placed_order_cnt_1d`，用于计算历史均量 |

---

## ETL 逻辑摘要

### 数据流

```
反欺诈惩罚表（参数化）
  └─ 过滤 punishment_status=1 & region=grass_region
  └─ 换算 order_limit → order_limit_percentage
          ↓
      LEFT JOIN（on shop_id）
          ↑
mp_order.dws_seller_gmv_1d__reg_s0_live
  └─ 过滤 tz_type='local' & grass_region & 近28天窗口
  └─ 按 shop_id 聚合 AVG(placed_order_cnt_1d) → avg_order_cnt_28d
          ↓
  计算 order_ovl = order_limit_percentage/100 × COALESCE(avg_order_cnt_28d, 0)
  时区转换 regional_date/regional_hour(SG) → local_date/local_hour(目标区域)
          ↓
INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_tc_antifraud_ovl_1h
  PARTITION(grass_region, local_date, local_hour, regional_date, regional_hour)
```

### 关键步骤

1. **子查询 T1（惩罚店铺信息）**
   - 从参数化的反欺诈惩罚表中筛选 `punishment_status = 1` 且 `region = ${grass_region}` 的记录。
   - 将 `order_limit`（存储为万分比整数）转换为百分比形式：`1.0 * order_limit / 10000 * 100`，即 `order_limit / 100`，输出为 `order_limit_percentage`。

2. **子查询 T2（历史日单量均值）**
   - 从 `mp_order.dws_seller_gmv_1d__reg_s0_live` 读取本地时区（`tz_type = 'local'`）下，日期范围为 `[date_sub(local_date, 29), date_sub(local_date, 2)]`（共 28 天，排除最近 1 天）的记录。
   - 按 `shop_id` 分组，计算 `avg(placed_order_cnt_1d)` 作为 `avg_order_cnt_28d`。

3. **JOIN 与指标计算**
   - T1 LEFT JOIN T2 on `shop_id`，确保即使无历史订单数据的受罚店铺也保留记录（`avg_order_cnt_28d` 为 NULL）。
   - 计算 `order_ovl = order_limit_percentage / 100 * COALESCE(placed_order_cnt_1d, 0)`。

4. **时区转换**
   - 调用 `date_timezone_convert` 函数，将 SG 基准的 `(regional_date, regional_hour)` 转换为目标区域的 `local_date`、`local_hour`，写入动态分区。

5. **INSERT OVERWRITE 写入**
   - 以 `grass_region` 为静态分区，其余四个时间分区字段为动态分区，覆盖写入目标表。

### 注意事项

- **单 Writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无并发写入冲突风险。
- **动态分区写入**：`local_date`、`local_hour`、`regional_date`、`regional_hour` 均为动态分区，执行时需确保 Spark/Hive 动态分区参数（`hive.exec.dynamic.partition.mode = nonstrict`）已开启。
- **参数依赖**：`${table}`、`${grass_region}`、`${regional_date}`、`${regional_hour}`、`${local_date}`、`${schema}` 均为运行时注入参数，SQL 本身不含硬编码值，调度时须确保参数正确传递。
- **`avg_order_cnt_28d` 字段命名歧义**：DataMap 字段名为 `avg_order_cnt_28d`，但 ETL 中实际来源列名为 `placed_order_cnt_1d`（取均值），语义一致，属别名映射，无数据质量风险。
- **`order_ovl` 中 NULL 处理**：使用 `COALESCE(T2.placed_order_cnt_1d, 0)` 保证无历史订单店铺的超限量为 0 而非 NULL，但 `avg_order_cnt_28d` 字段本身仍会存储 NULL，两者行为不一致，使用时需注意。
- **近 28 天窗口边界**：历史窗口为 `[local_date - 29天, local_date - 2天]`，有意排除最近 1 天数据，可能存在 T+1 延迟影响，使用时须知晓窗口定义。

---

*文档生成时间：2026-05-17*