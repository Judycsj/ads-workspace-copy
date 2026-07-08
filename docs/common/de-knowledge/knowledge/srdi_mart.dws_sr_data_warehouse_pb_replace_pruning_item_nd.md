<!-- ads-workspace-gdoc-sync: gdoc_id=1KYRc1l2cH9ReKJ4OWlxrGWesYDoSvw4Ed29OhhYd2_A gdoc_url=https://docs.google.com/document/d/1KYRc1l2cH9ReKJ4OWlxrGWesYDoSvw4Ed29OhhYd2_A/edit -->

# srdi_mart.dws_sr_data_warehouse_pb_replace_pruning_item_nd

**分层**：DWS（数据服务层）
**主键**：`item_id` + `mapping_general` + `grass_region` + `local_date`
**分区**：`grass_region`（站点/大区），`local_date`（业务日期）
**更新频率**：每日调度（T+1），覆盖写入（INSERT OVERWRITE）
**引用/访问频次**：1563 次

---

## 业务描述

本表用于支撑搜推数仓中 **PB（Pricing Bridge / 替换品）替换剪枝** 场景下的商品维度近 7 日滚动聚合分析。

核心业务场景为：在商品替换（replace）策略中，评估某一 `item_id` 与其所属 `mapping_general`（CSPU 映射组）之间的曝光、点击、下单表现，以及排除自身干扰和广告干扰后的同组竞品表现，从而为替换剪枝决策提供数据依据。

**适合回答的典型问题**：
- 过去 7 天内，某商品（item）在其 mapping_general 组内的曝光/点击/订单量分别是多少？
- 该 mapping_general 组整体（含/不含自身、含/不含广告）的流量表现如何？
- 某商品与其替换候选组的表现差异（用于剪枝阈值判断）？
- 过去 7 天内，该商品-映射关系实际出现了多少天（`last7d_day_cnt`）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `ID`、`TH` 等，用于分区隔离多站点数据 |
| `local_date` | date | 业务日期（本地时区），即聚合窗口的结束日期（含当天） |

### 维度：商品与映射关系

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，替换剪枝评估的核心粒度 |
| `mapping_general` | string | CSPU 映射组标识，表示 item 所归属的替换候选组（同组商品互为替换候选） |

### 指标：近 7 日窗口覆盖天数

| 字段 | 类型 | 说明 |
|---|---|---|
| `last7d_day_cnt` | int | 过去 7 天内该 `item_id` + `mapping_general` 组合实际出现的天数（`count(distinct local_date)`），不要求当天有曝光，反映该替换关系的活跃时间跨度 |

### 指标：商品自身近 7 日曝光/点击/订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt_7d` | bigint | 商品自身近 7 日累计曝光次数 |
| `item_click_cnt_7d` | bigint | 商品自身近 7 日累计点击次数 |
| `item_order_cnt_7d` | double | 商品自身近 7 日累计订单量 |

### 指标：CSPU 映射组（全量）近 7 日曝光/点击/订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt_7d` | bigint | mapping_general 组内所有商品（含自身、含广告）近 7 日累计曝光次数 |
| `cspu_click_cnt_7d` | bigint | mapping_general 组内所有商品（含自身、含广告）近 7 日累计点击次数 |
| `cspu_order_cnt_7d` | double | mapping_general 组内所有商品（含自身、含广告）近 7 日累计订单量 |

### 指标：CSPU 映射组（排除自身）近 7 日曝光/点击/订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_exclude_self_imp_cnt_7d` | bigint | mapping_general 组内排除当前 item 自身后，其余商品（含广告）近 7 日累计曝光次数 |
| `cspu_exclude_self_click_cnt_7d` | bigint | mapping_general 组内排除当前 item 自身后，其余商品（含广告）近 7 日累计点击次数 |
| `cspu_exclude_self_order_cnt_7d` | double | mapping_general 组内排除当前 item 自身后，其余商品（含广告）近 7 日累计订单量 |

### 指标：CSPU 映射组（排除自身及广告）近 7 日曝光/点击/订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_exclude_self_ads_imp_cnt_7d` | bigint | mapping_general 组内排除当前 item 自身及广告流量后，其余自然流量商品近 7 日累计曝光次数 |
| `cspu_exclude_self_ads_click_cnt_7d` | bigint | mapping_general 组内排除当前 item 自身及广告流量后，其余自然流量商品近 7 日累计点击次数 |
| `cspu_exclude_self_ads_order_cnt_7d` | double | mapping_general 组内排除当前 item 自身及广告流量后，其余自然流量商品近 7 日累计订单量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：表按站点分区存储，跨站点查询需显式枚举或 `WHERE grass_region = 'XX'`，避免全表扫描。
- **必须指定 `local_date`**：表按日期分区存储，查询时须明确指定目标日期，避免读取所有历史分区。
- 示例过滤：`WHERE grass_region = 'ID' AND local_date = '2025-05-16'`

### 时效性说明

- 本表为 **`_nd` 后缀**的滚动近 N 天聚合表（此处 N=7），每个分区 `(grass_region, local_date)` 存储的是以 `local_date` 为结束日、向前滚动 7 天（`date_sub(local_date, 6)` 至 `local_date`，共 7 天）的汇总结果。
- **不可将多个 `local_date` 分区的数据直接累加**，否则会造成时间窗口重叠导致重复计数。若需分析趋势，应选取连续不重叠的日期快照（如每隔 7 天取一个分区）或回溯到上游明细表 `dws_sr_data_warehouse_pb_item_cspu_metrics_1d`。
- 数据更新频率为每日 T+1，当天数据通常于次日可用。

### 不可直接 SUM 的字段

- **`last7d_day_cnt`**：已是 `count(distinct local_date)` 的去重聚合结果，跨分区或跨 item 直接 `SUM` 无业务意义，需结合业务场景重新定义聚合逻辑。
- **`*_order_cnt_7d`（double 类型）**：订单量字段为 double 类型（上游可能含小数权重），跨分区 SUM 前需注意时间窗口重叠问题（见上文时效性说明）。
- 所有 `cspu_*` 类指标（全量/排除自身/排除自身及广告）在同一分区内可按 `item_id` 维度汇总，但需注意同一 `mapping_general` 组内不同 `item_id` 行的 `cspu_*` 指标存在组级重叠，**不可对同一 `mapping_general` 下所有 `item_id` 行的 `cspu_*` 指标直接 SUM**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_pb_item_cspu_metrics_1d` | 提供 item × mapping_general 粒度的每日曝光、点击、订单明细指标，本表对其按站点分区近 7 天窗口滚动聚合 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_pb_item_cspu_metrics_1d
    （过滤：grass_region = ${grass_region}，local_date in [local_date-6, local_date]）
        ↓ GROUP BY mapping_general, item_id
srdi_mart.dws_sr_data_warehouse_pb_replace_pruning_item_nd
    （分区：grass_region = ${grass_region}, local_date = ${local_date}）
```

### 关键步骤

1. **过滤上游明细表**：从 `dws_sr_data_warehouse_pb_item_cspu_metrics_1d` 中筛选目标站点（`grass_region`）及近 7 天日期范围（`date_sub(local_date, 6)` ≤ `local_date` ≤ `local_date`）的数据。
2. **分组聚合**：以 `(mapping_general, item_id)` 为分组键，执行以下聚合：
   - `count(distinct local_date)` → `last7d_day_cnt`（统计该关系在 7 天内实际出现的天数）
   - `sum(item_imp_cnt / item_click_cnt / item_order_cnt)` → 商品自身 7 日汇总指标
   - `sum(cspu_imp_cnt / cspu_click_cnt / cspu_order_cnt)` → 映射组全量 7 日汇总指标
   - `sum(cspu_exclude_self_*)` → 映射组排除自身 7 日汇总指标
   - `sum(cspu_exclude_self_ads_*)` → 映射组排除自身及广告 7 日汇总指标
3. **写入目标分区**：`INSERT OVERWRITE` 写入目标表对应 `(grass_region, local_date)` 分区，覆盖当次调度结果。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 并发写入风险。
- **覆盖写入**：每次调度对目标分区执行 `INSERT OVERWRITE`，同一分区重跑安全，幂等性良好。
- **`last7d_day_cnt` 注释说明**：ETL SQL 注释明确指出，统计出现天数时无需限制当日 imp > 0，强调只要该 item-mapping_general 关系在 7 天窗口内存在记录即计入，与是否产生实际曝光无关，下游使用时需注意该语义。
- **时区一致性**：`local_date` 为本地时区日期，需确保上游表与调度参数的时区设置一致，避免时间窗口错位。
- **上游依赖**：本表强依赖 `dws_sr_data_warehouse_pb_item_cspu_metrics_1d` 的每日分区就绪，若上游延迟则本表数据同步延迟。

---

*文档生成时间：2026-05-17*