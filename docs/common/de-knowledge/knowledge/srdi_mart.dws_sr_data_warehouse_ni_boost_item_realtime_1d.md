<!-- ads-workspace-gdoc-sync: gdoc_id=1wX7BCW8eeY_-zWHd4bv_1SyAHzySN8u3jnSVWkqH4Hs gdoc_url=https://docs.google.com/document/d/1wX7BCW8eeY_-zWHd4bv_1SyAHzySN8u3jnSVWkqH4Hs/edit -->

# srdi_mart.dws_sr_data_warehouse_ni_boost_item_realtime_1d

**分层**: DWS（数据服务层）
**主键**: `grass_region` + `regional_date` + `item_id` + `exp_tag` + `window_end`
**分区**: `grass_region`，`regional_date`
**更新频率**: 实时准实时，每 10 分钟滚动窗口写入一次（Flink Streaming）
**访问频次**: 4499 次

---

## 业务描述

本表面向**新商品加速（New Item Boost）** 业务场景，记录各站点商品在推荐场景下的实时用户行为汇总指标。数据来源于多地区的 Kafka 用户行为流，经 Flink 流计算以 10 分钟为单位滚动聚合，写入 Paimon 存储。

**核心业务场景：**
- 监控"新商品加速"实验组（T1）与对照组（C1）商品在推荐场景中的实时曝光、点击及归因订单表现。
- 覆盖推荐核心流量场景：**猜你喜欢（You May Also Like）**、**首页每日发现（Homepage Daily Discover）**、**购后推荐（Post Purchase）**。
- 支持按实验分组（`exp_tag`）快速评估新商品加速策略的实时效果。

**适合回答的问题：**
- 某商品今日在各推荐场景下实时曝光/点击/成单量如何？
- 实验组 T1 与对照组 C1 的实时 CTR、转化率对比如何？
- 指定大区、指定日期内新商品加速相关指标的小时级/分钟级趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/站点标识，如 ID、VN、PH、TH、MY |
| `regional_date` | string | 事件本地日期，格式 `yyyy-MM-dd`，由事件 `log_timestamp` 转换而来 |

### 维度：商品与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `exp_tag` | string | 实验分组标签。`T1`：命中各大区新商品加速实验组；`C1`：命中全局对照实验（AB 378802）；`OTHER`：未命中上述实验 |
| `window_end` | bigint | 10 分钟滚动窗口的结束时间，Unix 时间戳（秒），由 Flink TUMBLE 窗口 `window_end` 转换而来 |

### 指标：推荐场景用户行为汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `explore_imp_cnt` | bigint | 窗口内商品曝光次数，统计 `operation='impression'` 的事件数 |
| `explore_click_cnt` | bigint | 窗口内商品点击次数，统计 `operation='click'` 的事件数 |
| `explore_order_cnt` | double | 窗口内归因订单数，来源于 `operation='omni_order'` 事件的 `attribution_cnt` 之和 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪**：查询时务必同时指定 `grass_region` 和 `regional_date`，避免全表扫描。示例：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2025-12-18'
  ```
- 如需跨大区汇总，需显式枚举 `grass_region IN ('ID','VN','PH','TH','MY')`，不可省略该分区条件。

### 不可直接 SUM 的字段

- **`window_end`**（时间戳维度）：为窗口边界标识，不应对其进行 SUM，应用于 GROUP BY 或时间范围过滤。
- **CTR、转化率等比率指标**：本表未预计算比率，如需 CTR 请在查询侧计算 `SUM(explore_click_cnt) / SUM(explore_imp_cnt)`，不可对行级比率先 AVG 再汇总。
- **`explore_order_cnt`**（double 类型）：为归因订单数累加值，跨窗口 SUM 时注意浮点精度问题；已含归因权重分摊，不等同于自然订单数。

### 时效性说明

- 本表为**实时准实时表**，由 Flink Streaming 作业持续写入，数据延迟约为 **10 分钟**（TUMBLE 窗口粒度）+ Kafka 消费延迟。
- `regional_date` 当日数据会随 Flink 作业持续追加，查询当日数据时结果为不完整的累计值，不代表全天终态。
- 历史日期数据在窗口关闭后即为终态，不再更新。
- 水位线（Watermark）设置为 `kafka_time - 10s`，极端情况下存在少量乱序数据被丢弃的风险，实际数值略低于完整值。

---

## 数据来源

| 上游表 / 数据源 | 用途 |
|---|---|
| Kafka Topic：`srdi.user_behavior_id` / `srdi.user_behavior_vn` / `srdi.user_behavior_ph` / `srdi.user_behavior_my` / `srdi.user_behavior_th` | 多大区用户行为原始事件流，包含曝光、点击、归因订单事件 |
| `paimon.srdi_mart.dim_sr_data_warehouse_fd_mapping_scenario_lookup` | 场景维度 Lookup 表，用于过滤推荐业务场景（猜你喜欢、首页每日发现、购后推荐） |

---

## ETL 逻辑摘要

### 数据流

```
Kafka 多大区 user_behavior Topic
        │
        ▼
  UDF 解析 PB 格式（NewItemBoostParseUb）
        │
        ▼
  temporary view: user_behavior_parse
  （过滤非广告、有效 item、主要卡片类型；打标实验分组 exp_tag）
        │
        ▼
  Lookup Join: dim_sr_data_warehouse_fd_mapping_scenario_lookup
  （圈选猜你喜欢 / 每日发现 / 购后推荐三大推荐场景）
        │
        ▼
  temporary view: user_behavior_filter
        │
        ▼
  TUMBLE 滚动窗口聚合（10 分钟）
        │
        ▼
  INSERT INTO paimon.srdi_mart.dws_sr_data_warehouse_ni_boost_item_realtime_1d
```

### 关键步骤

1. **UDF 注册**：注册自定义函数 `NewItemBoostParseUb`，用于将 Kafka 消息体中的 Protobuf 二进制数据解析为结构化字段（含 `item_id`、`grass_region`、`ab_list`、`operation`、`attribution_cnt`、`feature_detail` 等）。

2. **Kafka Source 定义**：以 `kafka_time`（Kafka 消息时间戳元数据）作为事件时间，Watermark 容忍 10 秒乱序；仅消费 `kafka_key` 中 operation 为 `impression`、`click`、`omni_order` 且来源为 `RCMD` 的消息。

3. **`user_behavior_parse` 视图**：
   - 过滤条件：排除广告（`is_ads=false or null`）、过滤 `item_id>0`、限定主要卡片类型（`target_type='item'` 或首页每日发现相关 feed 卡片）。
   - 实验分组打标（`exp_tag`）：按各大区对应的 AB 实验 ID 判定 T1/C1/OTHER。
   - 行为量化：`imp_cnt`、`click_cnt`、`order_cnt` 转为数值标志位或归因值。

4. **`user_behavior_filter` 视图**：与场景 Lookup 维表进行 `FOR SYSTEM_TIME AS OF proc_time` 的 Lookup Join，通过 `feature_detail` + `grass_region` 关联，仅保留三大推荐业务场景的事件；Lookup 表启用全量缓存（`lookup.cache = FULL`，最长保留 1 天，最大 2G 内存）。

5. **窗口聚合写入**：使用 `TUMBLE(TABLE user_behavior_filter, DESCRIPTOR(kafka_time), INTERVAL '10' MINUTES)` 定义 10 分钟不重叠滚动窗口，按 `(window_start, window_end, exp_tag, item_id, grass_region, regional_date)` 分组聚合三项指标，`window_end` 转为 Unix 时间戳后写入目标 Paimon 表。

### 注意事项

- **单 Writer**：本表仅由一个 Flink 作业写入（`multi_writer=false`），无多 writer 并发冲突风险。
- **Paimon 存储**：目标表为 Paimon 格式，支持流式追加与分区管理，查询需使用兼容 Paimon 的引擎（如 Spark、Flink SQL）。
- **场景 Lookup 缓存一致性**：`dim_sr_data_warehouse_fd_mapping_scenario_lookup` 的缓存刷新周期为 1 天，若场景映射配置在 1 天内发生变更，缓存更新前的数据可能采用旧映射逻辑，存在少量场景归因偏差。
- **`regional_date` 跨日边界**：`regional_date` 由 `log_timestamp` 按本地时间转换，Kafka 乱序或时区差异可能导致极少量事件落入相邻日期分区，跨日对比时需关注边界数据。
- **`explore_order_cnt` 类型**：字段类型为 double，源于 `attribution_cnt`（归因权重），非整数订单计数，聚合时需注意浮点累积误差。

---

*文档生成时间：2026-05-17*