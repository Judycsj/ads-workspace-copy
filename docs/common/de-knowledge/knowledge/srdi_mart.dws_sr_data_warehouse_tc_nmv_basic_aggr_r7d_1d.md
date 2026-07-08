<!-- ads-workspace-gdoc-sync: gdoc_id=1_tMEYTeay1FOhUh4R_xkr6U3wwx4cHATQ4YDywP5D_E gdoc_url=https://docs.google.com/document/d/1_tMEYTeay1FOhUh4R_xkr6U3wwx4cHATQ4YDywP5D_E/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_aggr_r7d_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `local_hour` + `mapping_general` + `is_item_card` + `is_ads` + `shop_id` + `item_id` + `model_id` + `user_id`
**分区：** `grass_region`（大区）/ `local_date`（本地日期）/ `local_hour`（本地小时）
**更新频率：** 每日一次（1d），覆盖写入（INSERT OVERWRITE）
**访问频次：** 2251 次

---

## 业务描述

本表用于汇总搜索与推荐（Search & Recommendation）各核心场景下，商品在 **最近 7 天滚动窗口（R7D）** 内的基础 NMV（Net Merchandise Value，已完成净交易额）及净订单量明细数据，按大区、日期、小时、场景、广告标识、商品层级粒度存储。

**核心业务场景：**
- 衡量搜索（Search）、每日发现（Daily Discover）、"你可能也喜欢"（You May Also Like）、购后推荐（Post Purchase）、店铺（Shop）、视频（Video）、直播（Live Streaming）等场景对整体 NMV 的贡献；
- 支持 S&R 全渠道汇总口径（`S&R__ALL__`）及平台全量口径（`__ALL__`）的 NMV 归因分析；
- 支持广告 vs 自然流量 NMV 拆分、商品卡（Item Card）与非商品卡流量归因对比；
- 为下游报表、BI 看板及 ADS 层提供预聚合基础数据，减少重复计算。

**适合回答的问题举例：**
- 某大区过去 7 天各场景（Search/Daily Discover/…）的 NMV 与净订单量各是多少？
- 广告流量与自然流量在各场景的 NMV 占比如何？
- 商品卡（`is_item_card=true`）归因的 NMV 相比非商品卡归因差异多大？
- 特定商品（`item_id`）或店铺（`shop_id`）在 S&R 渠道的近 7 天 GMV 贡献？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 `MY`、`TH`、`ID` 等），Spark 作业按大区分别写入各分区 |
| `local_date` | date | 本地日期，ETL 每日产出当天分区；R7D 滚动窗口数据落在该分区字段下 |
| `local_hour` | int | 本地小时（0–23），数据来源保留小时粒度以支持小时级分析 |

### 维度：场景与流量标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 流量场景归因标签。枚举值：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop`、`Video`、`Live Streaming`、`S&R__ALL__`（S&R 全渠道汇总）、`__ALL__`（平台全量） |
| `is_ads` | boolean | 是否为广告流量。`true` 表示订单由广告流量归因，`false` 表示自然流量 |
| `is_item_card` | string | 是否为商品卡归因。`'true'` 表示直接归因（主归因/primary），`'false'` 表示从 source1/source2 复制归因（间接归因）；注意该字段类型为 string 而非 boolean |

### 维度：商品与用户

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | SKU/型号 ID（商品子规格维度） |
| `user_id` | bigint | 用户 ID，买家维度；结合其他维度可做用户级归因分析 |

### 指标：NMV 与订单量

| 字段 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 净交易额（美元/标准币种），近 7 天滚动窗口内的原始明细值，来自上游基础明细表；**不可对跨 `local_date` 直接 SUM**（窗口数据存在重叠） |
| `nmv_local` | double | 净交易额（本地货币），含义同 `nmv`，以下单大区本地货币计价；**同样不可跨分区直接 SUM** |
| `net_order_cnt` | double | 净订单数（退款后）；为 double 类型，可能含小数权重；**不可跨 `local_date` 直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须指定大区，避免全分区扫描，例如：
   ```sql
   WHERE grass_region = 'MY'
   ```
2. **`local_date`**：本表为 R7D 滚动窗口预聚合表，**每个 `local_date` 分区内的数据已涵盖该日期往前 7 天的订单**。查询特定日期时需仅取单天分区，否则会产生重复计数：
   ```sql
   AND local_date = '2024-01-07'
   ```
3. **`local_hour`**：若只需日粒度汇总，注意该字段来自原始数据，应根据需要聚合或指定小时范围。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `nmv`、`nmv_local`、`net_order_cnt` | R7D 滚动窗口，相邻 `local_date` 分区数据高度重叠（共享 6 天），**跨多个 `local_date` SUM 会造成重复计算**；仅在单一 `local_date` 分区内聚合有效 |
| `nmv`、`nmv_local`、`net_order_cnt`（`is_item_card` 维度） | `is_item_card='false'` 的行是对 source1/source2 归因场景的复制行（copy order log），与 `is_item_card='true'` 的行存在**同一笔订单被多行记录**的情况；若需全口径 NMV 请勿同时 SUM 两类数据，需明确业务口径选择 `is_item_card` 的过滤条件 |
| 不同 `mapping_general` 聚合 | `S&R__ALL__` 和 `__ALL__` 与细分场景（`Search`、`Daily Discover` 等）均为独立行，**跨 `mapping_general` SUM 会产生重复计算**；请按业务口径单独选取某一 `mapping_general` 值 |

### 时效性说明

- 本表为 **R7D（最近 7 天滚动）** 预聚合表，每日产出代表以 `local_date` 为基准日往前推 7 天的订单汇总，**不是当天增量数据**。
- 数据通常 T+1 产出（依赖上游 `dws_sr_data_warehouse_tc_nmv_basic_r7d_1d` 就绪后触发）。
- 若需趋势分析（如 7 天环比），应取每个 `local_date` 分区的独立快照值，**而非连续多天的累加**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_r7d_1d` | 核心上游表，提供商品级、用户级、小时粒度的 R7D NMV 明细及多路归因字段（primary / source1 / source2），本表所有场景数据均来源于此 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_r7d_1d
    │
    ▼
[traffic_data_raw]          ← 按 grass_region 过滤，取近 8 天数据（date-7 ~ date）
    │
    ├──► [every_scene_data_raw_step1/2]   ← 常规场景（Search/DD/YMAL/PP/Shop）
    ├──► [video_and_live_data_raw_step1/2] ← 视频/直播场景
    ├──► [sr_data_raw_step1/2]             ← S&R 全渠道汇总口径（S&R__ALL__）
    └──► [platform_data_raw_step2]          ← 平台全量口径（__ALL__）
            │
            ▼  UNION ALL
srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_aggr_r7d_1d
（INSERT OVERWRITE，按 grass_region / local_date / local_hour 分区）
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `traffic_data_raw` | 从上游表读取指定大区、`date-7` 至 `date` 范围的原始明细，保留多路归因字段（primary/source1/source2） |
| Step 2a | `every_scene_data_raw_step1` | 将 `reporting_business_line/module/object` 映射为 `mapping_general` 场景标签（Search、DD、YMAL、PP、Shop），同时过滤掉无关行以减小数据量 |
| Step 3a | `every_scene_data_raw_step2` | UNION ALL 三路数据：① primary 归因（`is_item_card='true'`）；② source1 归因复制（`is_item_card='false'`，场景不重叠时追加）；③ source2 归因复制（同理，场景不重叠时追加） |
| Step 2b | `video_and_live_data_raw_step1` | 筛选 `feature_group in ('Video','Live Streaming')` 及 source1/source2 中的 Live Streaming 数据，映射场景 |
| Step 3b | `video_and_live_data_raw_step2` | 同 Step 3a 逻辑，生成视频/直播三路 UNION ALL |
| Step 2c | `sr_data_raw_step1` | 将 Search（Global Search+Image Search）、Daily Discover、User Scenario 统一归入 `S&R__ALL__` 口径 |
| Step 3c | `sr_data_raw_step2` | 同 Step 3a 逻辑，生成 `S&R__ALL__` 三路 UNION ALL |
| Step 4 | `platform_data_raw_step2` | 直接取全量 `traffic_data_raw` 数据，`mapping_general='__ALL__'`，`is_item_card='true'`，代表平台全量口径 |
| Final | INSERT OVERWRITE | 将四个 step2 视图 UNION ALL 后写入目标表，按 `grass_region / local_date / local_hour` 动态分区覆盖写入 |

### 注意事项

1. **多路归因复制行（Copy Order Log）**：source1、source2 归因场景的订单行会被**复制**追加到目标表中（`is_item_card='false'`），目的是将间接归因场景的 NMV 也纳入对应场景统计。使用时必须通过 `is_item_card` 字段明确业务口径，否则同一笔订单会被重复统计。
2. **去重保护逻辑**：source1/source2 复制行均有 `source_mapping_general != mapping_general`（及 source2 额外满足 `!= source1_mapping_general`）的判断，确保同一笔订单不在同一场景被重复计入，但跨场景仍可重复。
3. **`mapping_general` 互斥性**：不同 `mapping_general` 值（如 `Search`、`S&R__ALL__`、`__ALL__`）均独立存行，不可跨值聚合，否则计重。
4. **参数化大区**：ETL 使用 `${grass_region}` / `${grass_region_without_quote}` 参数化执行，每次仅处理单一大区，多大区需多次作业写入，但当前配置为 `multi_writer: false`（单文件单次执行）。
5. **INSERT OVERWRITE 覆盖策略**：每次执行按大区全量覆盖对应 `grass_region` 下的 `local_date`/`local_hour` 分区，重跑安全，但需保证上游数据完整后再触发。

---

*文档生成时间：2026-05-17*