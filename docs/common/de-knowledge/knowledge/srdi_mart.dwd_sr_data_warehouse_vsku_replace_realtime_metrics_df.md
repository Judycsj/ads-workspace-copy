<!-- ads-workspace-gdoc-sync: gdoc_id=1tCfWpLPmn6tAQpil4CwKt8qTrDZZdtuBmjYIDAYXhKM gdoc_url=https://docs.google.com/document/d/1tCfWpLPmn6tAQpil4CwKt8qTrDZZdtuBmjYIDAYXhKM/edit -->

# srdi_mart.dwd_sr_data_warehouse_vsku_replace_realtime_metrics_df

**分层：** DWD（明细数据层）
**主键：** `vitem_id`, `cspu_id`（联合唯一，分区内）
**分区：** `grass_region`（区域）/ `regional_date`（业务日期）
**更新频率：** 按区域、按日期分区覆盖写入（INSERT OVERWRITE），准实时/每日刷新
**引用频次/访问频次：** 35

---

## 业务描述

本表为搜推数仓（SRDI）中，针对 **虚拟 SKU（vSKU）替换场景的实时行为指标明细表**，存储各区域下每个虚拟商品（`vitem_id`）与对应标准品（`cspu_id`）之间，在不同时间窗口（当日、近 3 日、近 7 日）内的**曝光（Impression）与点击（Click）行为数组指标**，以及版本和标签的附加属性信息。

**核心业务场景：**
- vSKU 替换策略效果评估：通过多时间粒度的曝光与点击数组，分析 vSKU 替换后的用户行为趋势；
- 搜推召回/排序模型特征生成：`version_array`、`tag_array` 及各窗口行为序列作为 vSKU 维度特征输入；
- 跨区域（`grass_region`）的 vSKU 行为对比分析。

**适合回答的问题：**
- 某 vSKU 在指定区域、指定日期下，最近 1/3/7 天的曝光与点击序列分布如何？
- 特定 cspu 关联的 vSKU 替换行为指标是什么？
- 哪些 vSKU 的版本或标签满足特定条件，且具有较高的近期点击量？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识，如 `ID`、`MY` 等，Shopee 多区域分区键 |
| `regional_date` | date | 业务日期（本地日期），数据刷新对应的分区日期 |

### 维度：vSKU 与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品 ID（Virtual Item ID），vSKU 替换场景的核心维度 |
| `cspu_id` | bigint | 标准品 ID（Canonical SPU），vitem 关联的标准商品单元 |

### 维度：版本与标签属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `version_array` | array\<bigint\> | vSKU 关联的版本号数组，用于标识不同替换策略或模型版本 |
| `tag_array` | array\<string\> | vSKU 关联的标签数组，描述商品属性、替换规则标签等 |

### 指标：曝光行为（多时间窗口）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_array` | array\<bigint\> | 当日曝光次数数组，按某维度细分的曝光序列（不可直接 SUM 数组元素跨行聚合） |
| `imp_cnt_3d_array` | array\<bigint\> | 近 3 日曝光次数数组，滚动 3 天窗口的曝光行为序列 |
| `imp_cnt_7d_array` | array\<bigint\> | 近 7 日曝光次数数组，滚动 7 天窗口的曝光行为序列 |

### 指标：点击行为（多时间窗口）

| 字段 | 类型 | 说明 |
|---|---|---|
| `clk_cnt_array` | array\<bigint\> | 当日点击次数数组，按某维度细分的点击序列（不可直接 SUM 数组元素跨行聚合） |
| `clk_cnt_3d_array` | array\<bigint\> | 近 3 日点击次数数组，滚动 3 天窗口的点击行为序列 |
| `clk_cnt_7d_array` | array\<bigint\> | 近 7 日点击次数数组，滚动 7 天窗口的点击行为序列 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：该表为多区域分区表，未指定会导致全分区扫描，产生极大的计算资源消耗。
- **必须指定 `regional_date`**：每次 INSERT OVERWRITE 按日期分区刷新，查询时应明确指定日期，避免扫描历史全量分区。
- 推荐查询模板：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2026-05-17'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt_array`、`clk_cnt_array` | Array 类型，存储细分维度序列，不可跨行直接 SUM；如需汇总应使用 `aggregate` / `transform` + `REDUCE` 等数组函数处理 |
| `imp_cnt_3d_array`、`clk_cnt_3d_array` | 同上，且为预聚合的滚动 3 天窗口数组，已包含历史累积，不可与当日数组叠加 SUM |
| `imp_cnt_7d_array`、`clk_cnt_7d_array` | 同上，滚动 7 天窗口预聚合，存在时间窗口重叠，跨分区叠加会造成重复计数 |
| `version_array`、`tag_array` | Array 类型，为描述性属性，不具备加和语义 |

### 时效性说明

- 本表为**准实时日刷新**表（`_df` 后缀），每日按 `grass_region` + `regional_date` 分区覆盖写入。
- `*_3d_array`、`*_7d_array` 字段为上游 ODS 层滚动窗口预聚合结果，**不代表当日增量**，使用时注意时间窗口语义。
- 如需最新数据，应始终使用最新 `regional_date` 分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.srdi_mart.ods_sr_data_warehouse_vsku_replace_realtime_metrics` | 直接数据来源，提供 vSKU 替换场景的实时行为指标原始数据，包含各时间窗口的曝光与点击数组及维度属性 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.srdi_mart.ods_sr_data_warehouse_vsku_replace_realtime_metrics
    │  （按 grass_region 过滤）
    ▼
srdi_mart.dwd_sr_data_warehouse_vsku_replace_realtime_metrics_df
    （INSERT OVERWRITE PARTITION grass_region=?, regional_date=?）
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Step 1 | INSERT OVERWRITE | 直接从 ODS Paimon 实时表按 `grass_region` 过滤，全量抽取当日分区数据，覆盖写入目标表对应 `(grass_region, regional_date)` 分区 |

**核心逻辑说明：**
- ETL 为单步骤、无中间 Temporary View，逻辑简洁，属于 ODS → DWD 的直通（Pass-through）模式；
- 分区参数 `${grass_region}` 和 `${local_date}` 由调度任务运行时动态注入；
- 写入前无额外过滤、清洗或聚合，字段一一映射。

### 注意事项

- **单文件单 Writer**：`multi_writer = false`，该表仅由一个 ETL 文件写入，无多 Writer 并发冲突风险；
- **INSERT OVERWRITE 语义**：每次运行将覆盖对应 `(grass_region, regional_date)` 分区的全部数据，重跑安全，但注意避免参数错误导致错误分区被覆盖；
- **上游为 Paimon 实时表**：上游 ODS 表基于 Paimon 存储引擎，支持实时更新；下游本表为快照，数据时效性取决于调度触发频率；
- **`grass_region` 参数双重使用**：SQL 中 `grass_region` 既作为分区写入键（PARTITION 子句），又作为 WHERE 过滤条件，二者须保持一致，否则可能导致分区写入数据与过滤条件不匹配。

---

*文档生成时间：2026-05-17*