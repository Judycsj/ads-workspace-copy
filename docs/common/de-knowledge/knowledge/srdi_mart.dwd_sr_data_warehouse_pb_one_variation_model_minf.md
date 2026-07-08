<!-- ads-workspace-gdoc-sync: gdoc_id=1jTeci9AlxQFxcb7mIlrGisz_hDLS7kUBl3sj6_rN4n0 gdoc_url=https://docs.google.com/document/d/1jTeci9AlxQFxcb7mIlrGisz_hDLS7kUBl3sj6_rN4n0/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf

**分层**：DWD（数据明细层）
**主键**：`grass_region` + `regional_date` + `regional_hour` + `regional_minute` + `model_id`（推断）
**分区**：`grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour` / `regional_minute`
**更新频率**：分钟级（按 `regional_minute` 分区，准实时写入）
**引用频次 / 访问频次**：9,655 次

---

## 业务描述

本表是搜推数仓（SRDI）**商品价格 & Buybox 状态明细宽表**，以分钟粒度记录各站点每个 `model`（变体/SKU 维度）的最新价格快照及是否处于 Buybox 状态。

**核心业务场景**：
- **Buybox 竞价分析**：追踪各站点各时刻哪些 `model` 占据 Buybox，用于竞价策略优化与监控。
- **实时价格监控**：以分钟级快照还原商品历史价格走势，支持搜推算法特征的近实时消费。
- **低质商品过滤**：在入表前已剔除 `cspu_tag=8`（低质 CSPU）及 `model_id=0`（已被删除的最低价 model），保障下游数据质量。
- **本地时间维度对齐**：通过时区转换将新加坡标准时间（SG）映射为各站点本地时间，方便各区域业务方按本地时间分析数据。

**适合回答的问题**：
- 某站点某分钟某商品的价格是多少？是否占据 Buybox？
- 某 CSPU 下各 model 的价格分布与 Buybox 占比随时间的变化趋势？
- 某店铺在特定时间窗口内 Buybox 持有情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域代码，如 `PH`、`TH`、`SG` 等 |
| `local_date` | date | 各站点本地日期，由新加坡时间（`regional_date`/`regional_hour`）经时区转换而来 |
| `local_hour` | int | 各站点本地小时（0–23），与 `local_date` 同步时区转换 |
| `regional_date` | date | 数据产生时的新加坡（SG）日期，来源于调度参数 `${regional_date}` |
| `regional_hour` | int | 数据产生时的新加坡（SG）小时，来源于调度参数 `${regional_hour}` |
| `regional_minute` | int | 数据产生时的新加坡（SG）分钟，来源于调度参数 `${regional_minute}` |

### 维度：商品与店铺标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_id` | bigint | 商品变体（model/SKU）ID；`model_id=0` 在 ETL 中已过滤，不会出现在表中 |
| `item_id` | bigint | 商品 ID（listing 层级） |
| `cspu_id` | bigint | 标准商品单元（CSPU）ID，用于跨店铺同款商品聚合 |
| `shop_id` | bigint | 店铺 ID |

### 维度：商品属性标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_tag` | int | CSPU 标签标识；`cspu_tag=8` 为低质 CSPU，ETL 中已过滤，不会出现在表中 |
| `business_type` | int | 商品业务类型，来源于上游 `ods_sr_data_warehouse_pb_one_variation`，具体枚举值参考上游定义 |

### 指标：价格与 Buybox 状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `price` | double | 该 model 在当前时刻的价格快照；为瞬时值，**不可直接跨分区 SUM/AVG** |
| `is_buybox` | int | 是否占据 Buybox：`1` 表示是，`0` 表示否。通过与 `ods_sr_data_warehouse_vsku_model_mapping`（`status=1`）关联得出；关联成功则为 1，否则为 0 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段必填**：查询时务必指定 `grass_region` 及时间分区（`regional_date` 或 `local_date`），避免全表扫描。分区粒度为分钟级，历史分区数量极大。
2. **推荐同时指定 `regional_hour` 和 `regional_minute`** 以精确定位目标快照分区，否则可能扫描大量分区。
3. **使用本地时间时**：应同时过滤 `local_date` + `local_hour` 而非仅依赖 `regional_date`，以避免跨日时区偏差。

### 不可直接 SUM / AVG 的字段

| 字段 | 原因 |
|---|---|
| `price` | 分钟级价格快照，同一 `model_id` 在多个时间分区均有记录，直接 SUM 无业务意义，应先指定时间点再取值 |
| `is_buybox` | 瞬时状态标记，跨分区累加无意义；统计 Buybox 占比应在确定时间范围内按分钟聚合后计算比率 |

### 时效性说明

- 本表为**分钟级准实时快照表**，每分钟由调度任务以 `INSERT OVERWRITE` 方式刷新对应分区。
- 每个分区（`regional_date` + `regional_hour` + `regional_minute`）代表一个独立时刻的全量快照，**不累积历史**。
- 最新分区数据可能存在分钟级延迟，依赖上游 Paimon 表的数据到达情况。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.rcmd_feature.ods_sr_data_warehouse_pb_one_variation` | 主表，提供各站点 model 维度的价格、CSPU、店铺、业务类型等核心属性 |
| `paimon.srdi_mart.ods_sr_data_warehouse_vsku_model_mapping` | 关联表，用于判断 `model_id` 是否处于 Buybox 状态（`status=1` 的有效映射记录），并在构建时剔除指定 live test vitem |

---

## ETL 逻辑摘要

### 数据流

```
paimon.rcmd_feature.ods_sr_data_warehouse_pb_one_variation  (主数据源)
          │
          │  LEFT JOIN（on grass_region + model_id）
          │
paimon.srdi_mart.ods_sr_data_warehouse_vsku_model_mapping   (Buybox 判断，status=1，剔除 live test vitem)
          │
          ▼
   [Temporary View: vmodel]  —— 有效 Buybox model_id 集合（按 grass_region + model_id 去重）
          │
          ▼
srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf
（INSERT OVERWRITE，按分区写入）
```

### 关键步骤

**Step 1 — 构建 Temporary View `vmodel`（Buybox 有效 model 集合）**

从 `ods_sr_data_warehouse_vsku_model_mapping` 中筛选 `status=1` 的记录，并按站点排除特定 live test vitem（PH 排除 3 个、TH 排除 3 个），以 `grass_region + model_id` 分组去重，得到各站点当前有效的 Buybox model 集合。

**Step 2 — INSERT OVERWRITE 写目标表**

以 `ods_sr_data_warehouse_pb_one_variation`（别名 `a`）为主表，LEFT JOIN `vmodel`（别名 `b`）：
- 过滤条件：`a.model_id > 0`（剔除已删除的最低价 model）；`cspu_tag <> 8`（剔除低质 CSPU）。
- 计算 `is_buybox`：若 `b.model_id IS NOT NULL`（LEFT JOIN 命中）则为 `1`，否则为 `0`。
- 计算本地时间：调用 `date_timezone_convert` 将调度参数 `${regional_date}`/`${regional_hour}` 从 SG 时区转换为各站点本地 `local_date` 和 `local_hour`。
- 分区字段 `regional_date`、`regional_hour`、`regional_minute` 直接来源于调度参数 `${regional_date}`、`${regional_hour}`、`${regional_minute}`。
- 使用 `INSERT OVERWRITE … PARTITION(grass_region, local_date, local_hour, regional_date, regional_hour, regional_minute)` 动态覆盖写入。

### 注意事项

1. **单 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险。
2. **动态分区覆盖**：`INSERT OVERWRITE` 配合动态分区，每次调度仅覆盖当次调度参数对应的分钟分区，不影响历史分区数据。
3. **调度参数依赖**：`${regional_date}`、`${regional_hour}`、`${regional_minute}` 为必传调度参数，参数缺失或错误将导致分区写入位置异常。
4. **时区转换函数**：`date_timezone_convert` 为自定义 UDF，若各站点时区配置有变更，`local_date` / `local_hour` 可能出现偏差，需关注 UDF 版本一致性。
5. **live test 数据剔除**：PH 和 TH 站点有硬编码的 live test vitem_id 黑名单，如 live test 范围变更需同步更新 ETL SQL。
6. **上游 Paimon 表时效性**：目标表分钟级时效性强依赖于两张上游 Paimon 表的数据新鲜度，需监控上游表的写入延迟。

---

*文档生成时间：2026-05-17*