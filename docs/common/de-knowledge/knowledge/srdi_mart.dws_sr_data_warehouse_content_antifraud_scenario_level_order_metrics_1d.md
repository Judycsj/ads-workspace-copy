<!-- ads-workspace-gdoc-sync: gdoc_id=1wobfB1v8ztW8n7qmiT7F17z876BqcuPdqzy4ALq8jRY gdoc_url=https://docs.google.com/document/d/1wobfB1v8ztW8n7qmiT7F17z876BqcuPdqzy4ALq8jRY/edit -->

# srdi_mart.dws_sr_data_warehouse_content_antifraud_scenario_level_order_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `scenario` + `is_ads` + `antifraud_tag`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE），覆盖范围为当日及过去 14 天滚动窗口
**引用频次 / 访问频次：** 4

---

## 业务描述

本表为搜推数仓内容反欺诈场景下的**场景级别订单指标汇总日表**，面向搜索/推荐不同业务场景（`scenario`），按反欺诈标签（`antifraud_tag`）和广告标识（`is_ads`）维度聚合订单量与 GMV，用于评估各场景中反欺诈策略的拦截效果及其对下单行为的影响。

**核心业务场景：**
- 反欺诈标签划分下，各搜推场景（搜索、推荐等）的订单规模与交易金额对比分析；
- 广告流量与自然流量在不同反欺诈标签下的订单结构分析；
- 支持对反欺诈策略的效果评估，例如识别高风险流量对 GMV 的影响占比；
- 多日期区间（近 15 天滚动窗口）趋势观察。

**适合回答的问题举例：**
- 某站点某日，各反欺诈标签下搜索场景与推荐场景的订单量和 GMV 分别是多少？
- 广告流量中被标记为高风险的订单占比如何？
- 不同反欺诈标签对应的 GMV 结构在近两周内的变化趋势？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域标识，如 `TH`、`VN`、`ID` 等，用于区分不同国家/地区市场 |
| `local_date` | date | 业务日期（本地日期），ETL 覆盖当日及过去 14 天共 15 天窗口 |

### 维度：场景与反欺诈标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario` | string | 业务场景标识，区分搜索、推荐等不同流量来源场景 |
| `is_ads` | string | 是否为广告流量标识，用于区分广告投放流量与自然流量 |
| `antifraud_tag` | int | 反欺诈标签，标识流量或订单的风险等级/类别，由反欺诈模型或规则输出 |

### 指标：订单与交易金额

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单量，由上游用户-商品粒度明细表的 `order_cnt` 按维度聚合求和得出 |
| `gmv` | double | 成交金额（Gross Merchandise Value），由上游用户-商品粒度明细表的 `gmv` 按维度聚合求和得出，单位与上游一致 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：该字段为分区键之一，查询时必须指定具体站点区域，否则将触发全分区扫描，严重影响性能。
- **`local_date`**：该字段为分区键之一，查询时必须指定日期范围。需注意每次写入覆盖的是过去 15 天（`[local_date - 14, local_date]`）的数据，最新分区数据代表当日最新聚合结果。

```sql
-- 推荐写法示例
WHERE grass_region = 'TH'
  AND local_date = '2026-05-17'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_cnt` | 已为预聚合指标（场景 + 广告标识 + 反欺诈标签维度下的汇总值），跨维度直接 SUM 前需确认分析粒度与聚合键对齐，避免重复计数 |
| `gmv` | 同上，已为预聚合求和值，跨维度汇总时需注意口径一致性 |

### 时效性说明

- 本表为每日调度写入，通常在 T+1 可查询到 T 日数据。
- ETL 每次执行会以 `INSERT OVERWRITE` 方式覆盖写入 `[local_date - 14, local_date]` 区间内所有日期的分区，历史 15 天数据每日滚动刷新，**不宜依赖历史分区的历史快照做对比**（历史分区会被覆盖）。
- 若需要更细粒度（用户-商品级别）分析，请使用上游表 `srdi_mart.dws_sr_data_warehouse_content_antifraud_user_item_level_order_metrics_1d`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_content_antifraud_user_item_level_order_metrics_1d` | 用户-商品粒度的反欺诈订单明细，按 `scenario`、`is_ads`、`antifraud_tag`、`local_date` 维度聚合 `order_cnt` 和 `gmv` 后写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_content_antifraud_user_item_level_order_metrics_1d
    （用户-商品粒度明细，近15天滚动窗口）
        │
        │ GROUP BY scenario, is_ads, antifraud_tag, local_date
        │ SUM(order_cnt), SUM(gmv)
        ▼
srdi_mart.dws_sr_data_warehouse_content_antifraud_scenario_level_order_metrics_1d
    （场景粒度汇总，INSERT OVERWRITE 分区写入）
```

### 关键步骤

| 步骤 | 说明 |
|---|---|
| **过滤** | 从上游明细表筛选指定 `grass_region`，并限定 `local_date` 在 `[local_date - 14, local_date]` 15 天滚动窗口内 |
| **聚合** | 按 `scenario`、`is_ads`、`antifraud_tag`、`local_date` 分组，分别对 `order_cnt` 和 `gmv` 执行 `SUM` 聚合，从用户-商品粒度上卷至场景粒度 |
| **写入** | 以 `INSERT OVERWRITE` 方式按 `grass_region` 静态分区 + `local_date` 动态分区写入目标表，一次性覆盖写入 15 个日期分区 |

### 注意事项

- **多分区批量覆盖风险**：每次调度执行会覆盖写入过去 15 天的所有日期分区，若调度中途失败，可能造成部分日期分区数据缺失或不一致，需关注调度幂等性和数据完整性校验。
- **单一写入来源**：本表为单 ETL 文件写入（`multi_writer = false`），无多路写入并发风险。
- **动态分区模式**：`local_date` 采用动态分区，需确保 Spark/Hive 会话开启 `hive.exec.dynamic.partition=true` 及 `hive.exec.dynamic.partition.mode=nonstrict`。
- **上游依赖**：本表强依赖上游 `dws_sr_data_warehouse_content_antifraud_user_item_level_order_metrics_1d`，若上游数据延迟或质量异常，将直接影响本表准确性。

---

*文档生成时间：2026-05-17*