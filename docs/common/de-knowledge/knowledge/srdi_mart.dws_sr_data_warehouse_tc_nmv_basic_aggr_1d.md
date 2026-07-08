<!-- ads-workspace-gdoc-sync: gdoc_id=11XfHQObTt5opBtYkxAtAM_8LoH2Q1VjxT1fb6TcmBOo gdoc_url=https://docs.google.com/document/d/11XfHQObTt5opBtYkxAtAM_8LoH2Q1VjxT1fb6TcmBOo/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_aggr_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `local_hour` + `is_ads` + `is_item_card` + `mapping_general` + `shop_id` + `item_id` + `model_id` + `user_id`
**分区：** `grass_region`（大区）/ `local_date`（日期）/ `local_hour`（小时）
**更新频率：** 每日调度（覆盖写，按分区 INSERT OVERWRITE）
**访问频次：** 46 次

---

## 业务描述

本表是搜推（Search & Recommendation）数仓在**成交金额（NMV）**维度的基础聚合宽表，以**大区 × 日期 × 小时 × 场景 × 商品/店铺/用户**为粒度，汇总各场景下的 NMV 及净下单量数据，数据窗口覆盖当前调度日期前 30 天。

**核心业务场景：**

- 各搜推场景（Search、Daily Discover、You May Also Like、Post Purchase、Shop、Video、Live Streaming、S&R ALL、Platform ALL）的 GMV/NMV 分析与归因
- 搜索广告（is_ads）与自然流量的 NMV 对比
- 商品卡片（is_item_card）与非商品卡片来源订单的 NMV 拆分
- 多归因来源（直接归因 + source1 + source2）的订单补录，避免跨场景重复统计
- 大区、场景、商品、店铺、用户维度的 NMV 下钻分析

**适合回答的问题：**

- 某大区在某日某时段搜索场景下各商品的 NMV 是多少？
- 广告 vs 自然流量在 Daily Discover 场景的净成交额差异？
- 商品卡片来源订单与非商品卡片来源订单的 NMV 占比？
- 平台整体 NMV 趋势与各场景 NMV 的归因拆解？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 TW、MY、TH 等），每次写入覆盖单一大区分区 |
| `local_date` | date | 本地日期，格式 `yyyy-MM-dd`，数据范围为调度日期前 30 天至调度当日 |
| `local_hour` | int | 本地小时（0–23），与 `local_date` 共同确定时间粒度 |

### 维度：场景与商品卡片标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 是否为广告流量。`true` = 广告，`false` = 自然流量；来源包含直接归因及 source1/source2 归因链路 |
| `is_item_card` | string | 是否为商品卡片直接归因。`'true'` = 主归因（item card 直接成交），`'false'` = 由 source1 或 source2 归因补录的订单拷贝 |
| `mapping_general` | string | 场景聚合标签，枚举值：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop`、`Video`、`Live Streaming`、`S&R__ALL__`（搜推总览）、`__ALL__`（全平台） |

### 维度：实体标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | SKU/型号 ID |
| `user_id` | bigint | 用户 ID |

### 指标：成交金额与订单量

| 字段 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 净成交金额（NMV），以平台基准货币计价；由上游明细表直接传递，未经聚合压缩 |
| `nmv_local` | double | 净成交金额本地货币版本，以各大区本地货币计价 |
| `net_order_cnt` | double | 净下单量（净订单数，已扣除取消/退款等），以浮点数类型存储 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：该字段为一级分区，缺少此过滤会触发全表扫描。
- **必须指定 `local_date` 范围**：`local_date` 为二级分区，建议明确指定日期范围，避免读取全部 30 天历史数据。
- **建议指定 `local_hour`**：如仅需日粒度分析，需对 `local_hour` 进行 GROUP BY 或在已知范围内过滤。

```sql
-- 推荐写法示例
WHERE grass_region = 'TW'
  AND local_date = '2025-05-16'
  -- 如需全天则不过滤 local_hour，但须在 GROUP BY 中聚合
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `nmv` / `nmv_local` / `net_order_cnt` | 多归因场景下存在**订单拷贝（order copy）机制**：同一笔订单因 source1、source2 归因被复制写入多条记录（`is_item_card = 'false'`），跨 `is_item_card` 或跨 `mapping_general` 直接 SUM 会导致**重复计算**。需根据业务口径选取 `is_item_card = 'true'`（仅直接归因）或明确知悉归因逻辑后再汇总。 |

> ⚠️ **重要提示**：`is_item_card = 'false'` 的记录为 source1/source2 归因的订单拷贝，用于多场景归因分析。若要计算平台总 NMV，应使用 `mapping_general = '__ALL__'` 且 `is_item_card = 'true'` 的数据，或使用上游明细表。

### 时效性说明

- 本表为 **T+1 日聚合**，每日调度后更新；`local_hour` 粒度数据仍为前日汇总，非实时。
- 每次写入以 `INSERT OVERWRITE PARTITION(grass_region, local_date, local_hour)` 覆盖，仅保证调度当日前 **30 天**窗口内数据完整。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_1d` | 搜推成交 NMV 明细宽表，提供逐行归因数据（含 feature_detail、reporting_business_line、reporting_module、reporting_object 及 source1/source2 多归因字段），是本表唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_1d
    │  (过滤指定大区，取近30天数据)
    ▼
traffic_data_raw                    -- 原始流量数据暂存
    │
    ├──► every_scene_data  step1→step2   -- 常规电商场景（Search/DD/YMAL/PP/Shop）
    ├──► video_and_live_data step1→step2 -- 视频/直播场景（Video/Live Streaming）
    ├──► sr_data step1→step2             -- 搜推总览（S&R__ALL__）
    └──► platform_data step2             -- 全平台（__ALL__，全量透传）
    │
    ▼ UNION ALL
srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_aggr_1d
    (INSERT OVERWRITE，按 grass_region/local_date/local_hour 分区覆盖写)
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| **Step 1** | `traffic_data_raw` | 从上游明细表读取指定大区近 30 天数据，保留归因维度（feature_group、reporting_* 系列）及 source1/source2 归因链路字段 |
| **Step 2** | `every_scene_data_raw_step1` | 将 reporting_business_line/module/object 映射为 `mapping_general` 场景标签（Search、Daily Discover、You May Also Like、Post Purchase、Shop），过滤不在以上场景的记录以缩减数据量 |
| **Step 3** | `every_scene_data_raw_step2` | 构造三路 UNION：① `is_item_card='true'`（主归因）；② `is_item_card='false'` 拷贝 source1 归因（source1_mapping_general ≠ mapping_general，防止重复）；③ `is_item_card='false'` 拷贝 source2 归因（source2 ≠ mapping_general 且 ≠ source1，防止重复） |
| **Step 4** | `video_and_live_data_raw_step1` | 从 `traffic_data_raw` 过滤 feature_group 为 Video/Live Streaming 的数据，映射 mapping_general |
| **Step 5** | `video_and_live_data_raw_step2` | 同 Step 3 逻辑，构造 Video/Live Streaming 的三路 UNION，附加 source1/source2 归因拷贝 |
| **Step 6** | `sr_data_raw_step1` | 将 Search（Global Search + Image Search）、Daily Discover、User Scenario 统一映射为 `S&R__ALL__`，作为搜推大盘口径 |
| **Step 7** | `sr_data_raw_step2` | 同 Step 3 逻辑，构造 S&R__ALL__ 的三路 UNION |
| **Step 8** | `platform_data_raw_step2` | 全量透传 `traffic_data_raw`，`is_item_card='true'`、`mapping_general='__ALL__'`，用于全平台口径 NMV 统计 |
| **Step 9（写入）** | — | 四路数据 UNION ALL 后以 `INSERT OVERWRITE TABLE ... PARTITION(grass_region, local_date, local_hour)` 写入目标表，按分区覆盖 |

### 注意事项

- **订单拷贝去重逻辑**：source1 和 source2 归因的订单拷贝通过 `source_mapping_general != mapping_general`（及 `source2_mapping_general != source1_mapping_general`）条件防止同一笔订单在同一场景内重复写入，但跨场景（如同时命中 Search 和 S&R__ALL__）本质上是有意为之的多场景归因，查询时须明确过滤 `mapping_general`。
- **单文件单大区写入**：ETL 为单 writer（`multi_writer: false`），每次执行针对一个 `grass_region` 分区进行 `INSERT OVERWRITE`，多大区并发调度时各自覆盖独立分区，互不干扰。
- **Shop 场景 is_item_card 说明**：ETL 注释明确指出 `is_item_card='false'` 中 Shop 场景的归因仅作补录用途，"only non_item_card is not right"，使用 Shop 场景的非 item card 数据时需谨慎。
- **S&R__ALL__ 与各子场景不可叠加**：`S&R__ALL__` 是对 Search/DD/User Scenario 的汇总聚合口径，与 `every_scene_data`（Search、Daily Discover 等子场景）存在数据重叠，不可直接 SUM 混用。

---

*文档生成时间：2026-05-17*