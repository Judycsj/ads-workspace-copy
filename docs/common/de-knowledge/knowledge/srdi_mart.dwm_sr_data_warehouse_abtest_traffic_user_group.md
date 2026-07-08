<!-- ads-workspace-gdoc-sync: gdoc_id=1FPMXHaazjFDF9hjQZB0xJ3SJkOPU2WknweQK9vjxUAA gdoc_url=https://docs.google.com/document/d/1FPMXHaazjFDF9hjQZB0xJ3SJkOPU2WknweQK9vjxUAA/edit -->

# srdi_mart.dwm_sr_data_warehouse_abtest_traffic_user_group

**分层：** DWM（数据仓库中间层）
**主键：** `user_id`, `device_id`, `exp_group_id`, `grass_region`, `local_date`
**分区：** `grass_region`（大区）/ `local_date`（业务日期）
**更新频率：** 每日调度，按分区覆盖写入
**访问频次：** 194

---

## 业务描述

本表用于沉淀搜索与推荐（SR）A/B 实验平台中，各实验分组（experiment group）下有效流量用户的去重明细快照。每行代表某个大区、某天、某用户（或设备）归属于某一实验组的唯一记录。

**核心业务场景：**

- A/B 实验效果分析：快速圈定指定实验组的用户/设备样本，支撑后续行为指标的关联计算。
- 实验流量质量稽查：通过去重后的用户-设备-分组组合，核查分流是否存在污染或异常。
- 跨地区实验覆盖分析：按 `grass_region` 统计各大区实验流量规模。

**适合回答的问题举例：**

- 某天某大区，实验组 X 共有多少唯一用户/设备进入实验？
- 某用户/设备在哪些实验组中出现？
- 各实验组之间是否存在用户重叠？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、TW、MY 等），用于分区隔离不同地区数据 |
| `local_date` | date | 业务日期，数据所属的本地自然日，格式 `yyyy-MM-dd` |

### 维度：用户与设备标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 平台用户 ID；未登录用户可能为 NULL 或 0，需结合 `device_id` 联合识别用户 |
| `device_id` | string | 设备 ID；匿名流量的唯一识别符，与 `user_id` 共同构成流量主体 |

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，标识用户所命中的实验桶；ETL 已过滤 `exp_group_id <= 0` 的无效/未命中记录 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：查询时务必指定日期，否则将全量扫描所有历史分区，产生极高的计算与 I/O 开销。
- **`grass_region`**：建议同时指定大区，精准命中分区，避免跨区全扫描。

```sql
-- 推荐写法
where grass_region = 'SG'
  and local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

- 本表不包含度量指标字段，所有字段均为维度/标识字段。
- 对用户数/设备数进行统计时，应使用 `COUNT(DISTINCT user_id)` 或 `COUNT(DISTINCT device_id)`，**不可直接 COUNT(\*)** 作为去重用户数（同一用户可能命中多个实验组，跨组聚合时会重复计数）。
- 跨多天聚合时，需注意同一用户在不同日期均会产生记录，应在明确时间范围后再做去重。

### 时效性说明

- 本表为 **每日 T+1 快照表**，`local_date` 分区对应前一自然日数据，不提供实时或小时级数据。
- 每次调度以 `INSERT OVERWRITE` 方式写入，当日分区数据会被完整覆盖，历史分区不受影响。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_abtest_traffic_user_group` | A/B 实验流量用户分组明细层（DWD），提供原始的用户-设备-实验组命中记录，是本表唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_abtest_traffic_user_group  （DWD 明细层）
    │
    │  ① 按大区与日期分区过滤
    │  ② 剔除无效实验组（exp_group_id <= 0）
    │  ③ GROUP BY 去重，保留唯一用户-设备-实验组组合
    │
    ▼
srdi_mart.dwm_sr_data_warehouse_abtest_traffic_user_group  （DWM 中间层）
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| 1 | INSERT OVERWRITE | 直接从 DWD 表读取数据，按 `grass_region` 和 `local_date` 动态分区覆盖写入目标表 |
| 2 | 分区过滤 | `WHERE grass_region IN (${grass_region}) AND local_date = ${local_date}`，仅处理调度参数指定的大区和日期 |
| 3 | 有效性过滤 | `AND exp_group_id > 0`，排除未命中实验或异常的占位分组记录 |
| 4 | 去重聚合 | `GROUP BY user_id, device_id, exp_group_id, grass_region, local_date`，消除 DWD 层同一组合的重复行，产出用户粒度去重快照 |

### 注意事项

- **单 Writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无并发写入风险。
- **动态分区覆盖**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 动态写入，每次调度只覆盖参数指定的分区，历史分区安全。
- **参数依赖**：`${grass_region}` 支持多值（`IN` 语法），`${local_date}` 为单日期；若调度参数异常（如大区列表为空），可能导致分区写入为空或 SQL 解析报错，需在调度平台做参数校验。
- **去重语义**：ETL 使用 `GROUP BY` 而非 `DISTINCT`，在无聚合函数的情况下两者语义等价，但需注意 DWD 层若存在 `user_id`/`device_id` 同时为 NULL 的记录，NULL 值会被视为同一 GROUP，可能产生非预期的合并。

---

*文档生成时间：2026-05-17*