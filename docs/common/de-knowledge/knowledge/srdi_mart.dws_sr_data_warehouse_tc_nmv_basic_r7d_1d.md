<!-- ads-workspace-gdoc-sync: gdoc_id=1C3xS7W36eDo3N8mIusUBjDlE9JLFLB2pG1-hSGSVy60 gdoc_url=https://docs.google.com/document/d/1C3xS7W36eDo3N8mIusUBjDlE9JLFLB2pG1-hSGSVy60/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_r7d_1d

**分层：** DWS（数据汇总层）
**主键：** `shop_id` + `item_id` + `model_id` + `user_id` + `is_ads` + `source1_is_ads` + `source2_is_ads` + `feature_detail` + `source1_feature_detail` + `source2_feature_detail` + `feature_group` + `reporting_business_line` + `reporting_module` + `reporting_object` + `source1_feature_group` + `source1_reporting_business_line` + `source1_reporting_module` + `source1_reporting_object` + `source2_feature_group` + `source2_reporting_business_line` + `source2_reporting_module` + `source2_reporting_object` + `local_date` + `local_hour` + `grass_region`
**分区：** `grass_region`（静态分区，按地区）、`local_date`（动态分区，按日期）、`local_hour`（动态分区，按小时）
**更新频率：** 每日一次（`INSERT OVERWRITE`，覆盖写入）
**访问频次：** 234 次

---

## 业务描述

本表为搜推数仓（SRDI）中**搜索与推荐场景下商品交易 NMV（Net Merchandise Value，净成交额）的近 7 日滚动汇总宽表**，属于 DWS 层轻度聚合结果。

每次调度时，以 `local_date` 为基准，向前滑动覆盖最近 8 天（`date_sub(local_date, 7)` ~ `local_date`，共 8 个自然日）的明细数据，对净订单数量（`net_order_cnt`）、本币 NMV（`nmv`）及本地货币 NMV（`nmv_local`）进行 SUM 聚合，同时保留来源链路的维度标签（含 source1、source2 两路归因维度）。

**核心业务场景：**
- 搜推商品在近 7 日内的交易贡献分析；
- 按广告（`is_ads`）、来源特征组（`feature_group`）、业务线（`reporting_business_line`）等维度拆解 NMV 表现；
- 多归因链路（source1 / source2）对比分析，评估不同归因口径下的业务价值；
- 跨地区（`grass_region`）的 NMV 汇总与横向对比。

**适合回答的问题：**
- 过去 7 天特定店铺 / 商品 / 用户在搜推场景下贡献了多少净成交额？
- 广告流量与自然流量在近 7 日的 NMV 差异如何？
- 不同 `feature_group` / `reporting_module` 来源的 NMV 分布情况？
- 多归因口径下（source1 vs. source2）同一订单的 NMV 归因差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区标识（如 SG、MY、TH 等），静态分区，由调度参数 `${grass_region}` 注入 |
| `local_date` | date | 数据所属本地日期，动态分区；本表以该字段为窗口基准，覆盖范围为 `[local_date-7, local_date]` |
| `local_hour` | int | 数据所属本地小时（0–23），动态分区，保留来自明细层的小时粒度 |

### 维度：交易主体

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | SKU/规格 ID |
| `user_id` | bigint | 用户 ID |

### 维度：广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 最终归因口径下是否为广告流量 |
| `source1_is_ads` | boolean | source1 归因链路下是否为广告流量 |
| `source2_is_ads` | boolean | source2 归因链路下是否为广告流量 |

### 维度：特征与来源标签（最终归因口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 特征明细标签，标识触发该交易的具体特征项 |
| `feature_group` | string | 特征组标签，`feature_detail` 的上层归组 |
| `reporting_business_line` | string | 报表业务线维度，用于区分不同业务口径 |
| `reporting_module` | string | 报表模块维度，如搜索、推荐等子模块 |
| `reporting_object` | string | 报表对象维度，标识具体的报表统计对象 |

### 维度：特征与来源标签（source1 归因口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `source1_feature_detail` | string | source1 归因链路下的特征明细标签 |
| `source1_feature_group` | string | source1 归因链路下的特征组标签 |
| `source1_reporting_business_line` | string | source1 归因链路下的报表业务线 |
| `source1_reporting_module` | string | source1 归因链路下的报表模块 |
| `source1_reporting_object` | string | source1 归因链路下的报表对象 |

### 维度：特征与来源标签（source2 归因口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `source2_feature_detail` | string | source2 归因链路下的特征明细标签 |
| `source2_feature_group` | string | source2 归因链路下的特征组标签 |
| `source2_reporting_business_line` | string | source2 归因链路下的报表业务线 |
| `source2_reporting_module` | string | source2 归因链路下的报表模块 |
| `source2_reporting_object` | string | source2 归因链路下的报表对象 |

### 指标：交易汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `net_order_cnt` | double | 近 7 日净订单数（退款后净值），由上游明细 SUM 聚合得到 |
| `nmv` | double | 近 7 日净成交额（美元或平台基准币种），由上游明细 SUM 聚合得到 |
| `nmv_local` | double | 近 7 日净成交额（本地货币），由上游明细 SUM 聚合得到 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：本表为分区表，查询时必须显式指定 `grass_region`，否则将触发全分区扫描，产生大量 I/O 开销。
2. **`local_date`**：须明确过滤目标日期。注意：本表每个 `local_date` 分区内已包含该日期向前滑动 8 天（含当天）的汇总数据，**不要跨多个 `local_date` 分区累加同一个自然日的指标，会导致重复计数**。如需某一天的近 7 日汇总，仅取 `local_date = '目标日期'` 即可。
3. **`local_hour`**（按需）：如仅关注每日全量数据，建议确认目标 `local_hour` 值后再过滤，避免将同一天不同小时的数据重复叠加。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `net_order_cnt` | 已为近 7 日预聚合值；跨多个 `local_date` 分区求和将产生重复计算（滑动窗口重叠） |
| `nmv` | 同上，跨 `local_date` 分区叠加会导致重复计算 |
| `nmv_local` | 同上，跨 `local_date` 分区叠加会导致重复计算 |

### 时效性说明

- 本表为 **`r7d`（近 7 日滚动窗口）** 聚合表，每个 `local_date` 分区数据覆盖 `[local_date - 7, local_date]` 共 8 个自然日的汇总，**并非单日增量数据**。
- 调度频率为每日一次，通常在 T 日完成 T-1 数据的写入，时效性为 **T+1**（准实时）。
- `local_hour` 字段保留自上游明细层，用于区分日内不同时间段写入的批次，查询时需结合实际业务场景确认是否需要聚合所有小时。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 搜推平台 NMV 明细层，提供订单级别的净成交额、净订单数及全部维度标签，是本表唯一直接来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform_nmv
    │
    │  过滤：grass_region 匹配 & local_date BETWEEN [local_date-7, local_date]
    │
    ▼
GROUP BY 所有维度字段 + local_date + local_hour
    │
    │  聚合：SUM(net_order_cnt)、SUM(nmv)、SUM(nmv_local)
    │
    ▼
srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_r7d_1d
（INSERT OVERWRITE，按 grass_region 静态分区 + local_date/local_hour 动态分区覆盖写入）
```

### 关键步骤

1. **数据筛选**：从 `dwd_sr_data_warehouse_platform_nmv` 按 `grass_region` 和近 8 天日期范围（`date_sub(${local_date}, 7)` ~ `${local_date}`）过滤出目标明细数据。
2. **维度分组**：以 `shop_id`、`item_id`、`model_id`、`user_id`、三路广告标识（`is_ads`、`source1_is_ads`、`source2_is_ads`）、三套归因链路的特征与来源标签（共 15 个维度字段）以及 `local_date`、`local_hour` 共 25 个字段进行 GROUP BY。
3. **指标聚合**：对 `net_order_cnt`、`nmv`、`nmv_local` 分别执行 `SUM`，得到近 7 日汇总指标。
4. **目标表写入**：以 `INSERT OVERWRITE … PARTITION(grass_region = ${grass_region}, local_date, local_hour)` 覆盖写入目标表对应分区，同一 `grass_region` + `local_date` + `local_hour` 分区的历史数据将被完全替换。

### 注意事项

- **单 ETL 文件，无 multi-writer 风险**：本表仅有一个 ETL 文件写入，不存在多文件并发写同一分区的冲突问题。
- **`INSERT OVERWRITE` 覆盖写入**：每次调度会覆盖当前 `grass_region` 下所有动态生成的 `local_date`/`local_hour` 分区，若上游 DWD 数据修复后需重跑，直接重跑当日任务即可完成分区替换。
- **滑动窗口重叠**：`r7d` 窗口设计导致相邻两天的分区数据存在 7 天的数据重叠，下游使用时须严格限定单一 `local_date` 分区，禁止跨分区对指标字段求和。
- **`local_hour` 粒度保留**：本表保留了来自明细层的小时粒度，若上游存在日内多批次写入，同一 `local_date` 下可能存在多个 `local_hour` 值，汇总时需注意是否需要合并所有小时。
- **参数依赖**：`${grass_region}` 和 `${local_date}` 为调度传入参数，DDL 或手动执行时需确保参数正确赋值，否则可能导致分区写错或数据缺失。

---

*文档生成时间：2026-05-17*