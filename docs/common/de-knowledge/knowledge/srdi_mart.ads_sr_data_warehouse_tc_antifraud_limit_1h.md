<!-- ads-workspace-gdoc-sync: gdoc_id=1aLgdNLsacKemFs5i-lzXI798WUR7tiTe4_4yb7joEes gdoc_url=https://docs.google.com/document/d/1aLgdNLsacKemFs5i-lzXI798WUR7tiTe4_4yb7joEes/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_antifraud_limit_1h

**分层**：ADS（应用数据层）
**主键**：`shop_id` + `grass_date` + `hour`（分区内唯一）
**分区**：`grass_region`（大区）/ `grass_date`（本地日期）/ `hour`（本地小时）
**更新频率**：每小时覆盖写（INSERT OVERWRITE）
**引用频次 / 访问频次**：854

---

## 业务描述

本表面向搜推（Search & Recommendation）业务的**反欺诈（Anti-Fraud）限流**场景，以小时粒度输出当前周期内**真实订单量已超过 OVL（Order Volume Limit，订单量上限）** 的店铺快照。

核心业务场景：

- **反欺诈限流判断**：将每个店铺当日累计真实成单量（`order_cnt`）与其限流上限（`order_ovl`）进行比对，筛选出超限店铺，供下游风控/搜推策略实时调用，触发降权或屏蔽逻辑。
- **小时级监控**：每小时滚动更新，可在当天内持续追踪超限店铺状态变化。

适合回答的问题：

- 当前小时，哪些店铺的订单量已超过反欺诈限流上限？
- 某大区某天某小时内，超限店铺的实际成单量与限流阈值分别是多少？
- 超限店铺列表的最新刷新时间是何时？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识（如 SG、MY 等），与业务调度参数 `${grass_region}` 对应 |
| `grass_date` | date | 店铺本地日期（由 `dws_sr_data_warehouse_tc_antifraud_ovl_1h` 的 `local_date` 写入） |
| `hour` | int | 店铺本地小时（由 `dws_sr_data_warehouse_tc_antifraud_ovl_1h` 的 `local_hour` 写入） |

### 维度：店铺标识与时间

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺唯一标识 |
| `update_time` | bigint | 数据更新时间戳（毫秒级 Unix 时间戳），来源于上游 OVL 汇总表，反映该限流阈值记录的最新更新时间 |

### 指标：反欺诈限流核心指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_ovl` | double | 该店铺的订单量限流上限（Order Volume Limit），来源于 `dws_sr_data_warehouse_tc_antifraud_ovl_1h` |
| `order_cnt` | bigint | 截至当前小时，该店铺在本地日期内的累计真实成单量（仅统计 `omni_order` 操作类型），来源于 `rcmd_feature.dws_sr_data_warehouse_tc_pb_realtime_feature_5min` 聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将全分区扫描，产生极大 I/O 开销。
- **`grass_date`**：必须指定目标日期，避免读取历史全量分区。
- **`hour`**：建议同时指定，以精准定位某一小时的超限快照；如需当天最新状态，取 `max(hour)` 对应分区。

示例：
```sql
SELECT shop_id, order_cnt, order_ovl
FROM srdi_mart.ads_sr_data_warehouse_tc_antifraud_limit_1h
WHERE grass_region = 'SG'
  AND grass_date   = '2024-06-01'
  AND hour         = 14;
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `order_ovl` | 限流阈值，属于店铺维度配置值，跨小时或跨店铺 SUM 无业务意义 |
| `order_cnt` | 为店铺当日累计量（非增量），不同小时分区的 `order_cnt` 存在数据包含关系，跨小时 SUM 会重复计算 |
| `update_time` | 时间戳，不可聚合求和 |

### 时效性说明

- 本表为**小时级准实时表**，每整点前后调度写入，数据存在约 **分钟级延迟**（取决于上游 5min 级特征表的就绪时间）。
- `order_cnt` 覆盖的时间范围为：**前一自然日 00:00 至当前区域小时**（跨越自然日边界做时区转换后聚合），已在 ETL 内完成全天累计，**下游不可再跨小时累加**。
- 表中仅保留**超限店铺**（`order_cnt > order_ovl`），未超限店铺不会出现在本表中，使用时请注意数据的过滤语义。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dws_sr_data_warehouse_tc_antifraud_ovl_1h` | 提供店铺维度的反欺诈订单量限流上限（`order_ovl`）及时间维度字段（`local_date`、`local_hour`、`update_time`） |
| `rcmd_feature.dws_sr_data_warehouse_tc_pb_realtime_feature_5min` | 提供 5 分钟粒度的实时订单事件明细，经时区转换与聚合后得到各店铺当日累计成单量（`order_cnt`） |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_antifraud_ovl_1h  (T1: 店铺限流上限)
        │
        ├─── JOIN on shop_id + local_date
        │
rcmd_feature.dws_sr_data_warehouse_tc_pb_realtime_feature_5min
        │  → 时区转换(regional → local_date)
        │  → 过滤 omni_order 操作
        │  → SUM(order_cnt) 按 shop_id + local_date 聚合  (T2: 当日累计订单量)
        │
        └─── WHERE T2.order_cnt > COALESCE(T1.order_ovl, 0)
                   ↓
srdi_mart.ads_sr_data_warehouse_tc_antifraud_limit_1h
```

### 关键步骤

1. **子查询 T1**：从 `dws_sr_data_warehouse_tc_antifraud_ovl_1h` 按 `grass_region`、`regional_date`、`regional_hour` 过滤，获取当前调度周期内各店铺的限流上限快照。

2. **子查询 T2**：从 5min 实时特征表读取订单事件，过滤条件为：
   - 大区匹配 `grass_region`；
   - 时间范围覆盖：**前一自然日全天（regional_hour 0–23）+ 当前自然日截至当前小时**；
   - 操作类型为 `omni_order`；
   - 对每条记录做时区转换，将区域时间（`regional_date + regional_hour`）转换为目标大区本地日期（`local_date`）；
   - 按 `shop_id + local_date` 分组，SUM `order_cnt`，得到店铺当日累计成单量。

3. **JOIN + 过滤**：T1 与 T2 按 `shop_id + local_date` 做 INNER JOIN，并通过 `WHERE T2.order_cnt > COALESCE(T1.order_ovl, 0)` 仅保留已超过限流阈值的店铺。

4. **INSERT OVERWRITE**：结果按 `grass_region`（静态）+ `grass_date`、`hour`（动态，来自 `local_date`、`local_hour`）覆盖写入目标分区。

### 注意事项

- **单 Writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无并发写入风险。
- **分区覆盖语义**：使用 `INSERT OVERWRITE … PARTITION (grass_region = ${grass_region}, grass_date, hour)` 动态分区覆盖，每次调度仅覆盖当前 `grass_region + grass_date + hour` 对应的分区，历史分区不受影响。
- **时区转换依赖**：`date_timezone_convert` 函数将区域时间转换为本地时间，时区参数为固定 `'SG'` → `grass_region`，若大区时区配置变更需同步评估影响。
- **`order_ovl` 为 NULL 的处理**：ETL 使用 `COALESCE(T1.order_ovl, 0)` 兜底，若某店铺尚未配置限流上限，则任意正成单量均视为超限，下游使用时需关注此边界情况。
- **仅包含超限记录**：本表不是全量店铺快照，只有 `order_cnt > order_ovl` 的店铺才会写入，查询时不可用于判断"某店铺未超限"。

---

*文档生成时间：2026-05-17*