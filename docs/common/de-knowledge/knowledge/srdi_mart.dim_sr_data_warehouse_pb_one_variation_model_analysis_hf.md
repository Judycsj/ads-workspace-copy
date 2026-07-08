<!-- ads-workspace-gdoc-sync: gdoc_id=1aiaLOYV-D2ZmvcKrWilLCAaPphUjMVagz5LXasdjl4Y gdoc_url=https://docs.google.com/document/d/1aiaLOYV-D2ZmvcKrWilLCAaPphUjMVagz5LXasdjl4Y/edit -->

# srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf

**分层：** dim（维度层）
**主键：** `grass_region` + `local_date` + `local_hour` + `cspu_id` + `model_id` + `item_id` + `shop_id`
**分区：** `grass_region`（大区）/ `local_date`（日期）/ `local_hour`（小时）
**更新频率：** 小时级（hf = hourly frequency），每小时更新一次
**引用频次 / 访问频次：** 2884 次
**Multi-writer：** 是（2 个 ETL 文件分别写入不同区域分区）

---

## 业务描述

本表为搜推数仓（SRDI）**价格段（PB）单规格商品模型分析**的小时级维度快照表，记录各大区、各小时粒度下，单规格（one variation）商品最小价格单元（cspu）与所属模型、商品、店铺、业务类型的关联关系。

**核心业务场景：**
- 支持搜索/推荐算法在小时级维度上分析各区域单规格商品的模型挂载情况；
- 对原始 dump 数据的小时缺口进行补全（使用最近真实小时数据填充），保证每天 0–23 小时均有覆盖；
- 作为下游模型分析、商品召回、策略评估等任务的基础维度宽表。

**适合回答的问题：**
- 某区域某天某小时内，哪些 cspu/item/shop 关联了哪些模型？
- 某 cspu 在某大区当天各小时的业务类型是什么？
- 某 model_id 在特定小时挂载了哪些单规格商品？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），ETL 按大区分别写入对应分区 |
| `local_date` | date | 本地日期，ETL 按天分区写入 |
| `local_hour` | int | 本地小时（0–23）；经补全算法处理，保证每天 24 个小时分区均有数据 |

### 维度：商品与模型关联标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 最小价格单元 ID（Cheapest SKU Price Unit），单规格商品的价格维度标识 |
| `model_id` | bigint | 商品模型 ID，对应商品的规格/型号维度 |
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `business_type` | int | 业务类型标识；当同一 (cspu_id, model_id, item_id, shop_id, local_hour) 组合存在多条记录时，取 `max(business_type)` 作为代表值（仅适用于亚洲区 ETL 路径） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region`、`local_date`**，否则将触发全表扫描，读取所有大区和日期分区，代价极高。
- 如需查询特定小时数据，同时过滤 `local_hour`。

```sql
-- 推荐写法示例
SELECT *
FROM srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01'
  AND local_hour = 10;
```

### 不可直接 SUM / 聚合的字段

- **`business_type`**：该字段为枚举/标识类型，取 `max` 聚合仅用于 ETL 去重，业务查询中不应对其求和或均值，应作为过滤/分组维度使用。
- **`local_hour`**：分区字段，经过补全算法映射（`flag_hour`），不代表原始 dump 的真实小时，对其做算术聚合无业务意义。

### 时效性说明

- 本表为**小时级快照表**（hf = hourly frequency），每小时调度一次，存在一定延迟，非实时。
- ETL 核心逻辑包含**小时补全**：若某大区当天部分小时未成功 dump 数据，会用距离该小时最近的真实数据小时填充，确保 0–23 小时全覆盖。因此，`local_hour` 对应的数据可能并非该精确小时的原始数据，而是最近有效小时的数据复制。
- 非亚洲区（nonasian）数据由独立 ETL 文件从 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf_import_nonasian` 导入，无小时补全逻辑，直接透传原始数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf` | 亚洲区主数据源，提供单规格商品最小价格单元的分钟级明细数据，ETL 按 `grass_region` 和 `local_date` 过滤后聚合至小时粒度 |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf_import_nonasian` | 非亚洲区数据导入源，直接提供已处理的非亚洲大区小时级维度数据，透传写入目标表 |

---

## ETL 逻辑摘要

### 数据流

```
[亚洲区路径]
dwd_sr_data_warehouse_pb_one_variation_model_minf
    → cheapest_<region>（按 cspu/model/item/shop/hour 去重，取 max business_type）
    → flag_hour_list_<region>（生成 0~23 小时枚举列表）
    → real_hour_list_<region>（提取当天实际存在的小时列表）
    → complement_hour_list_<region>（将 flag_hour 映射至最近 real_hour，实现小时补全）
    → INSERT OVERWRITE → dim_sr_data_warehouse_pb_one_variation_model_analysis_hf

[非亚洲区路径]
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf_import_nonasian
    → INSERT OVERWRITE → dim_sr_data_warehouse_pb_one_variation_model_analysis_hf
```

### 关键步骤

**ETL 文件 1（亚洲区，含小时补全）：**

1. **`cheapest_<region>`（Temporary View）**
   从 `dwd_sr_data_warehouse_pb_one_variation_model_minf` 按 `grass_region` 和 `local_date` 过滤，以 `(cspu_id, model_id, item_id, shop_id, local_hour)` 为粒度分组，取 `max(business_type)` 完成去重。

2. **`flag_hour_list_<region>`（Temporary View）**
   使用 `LATERAL VIEW EXPLODE(array(0..23))` 生成包含 0 到 23 的完整小时枚举序列，作为补全基准。

3. **`real_hour_list_<region>`（Temporary View）**
   从 `cheapest_<region>` 中提取当天实际存在数据的小时列表（`distinct local_hour`）。

4. **`complement_hour_list_<region>`（Temporary View）**
   将 `flag_hour_list` 与 `real_hour_list` 做笛卡尔积，计算每个 `flag_hour` 与所有 `real_hour` 的差值绝对值，通过 `ROW_NUMBER() OVER (PARTITION BY flag_hour ORDER BY abs(diff) ASC)` 取最近的 `real_hour`，实现缺失小时的就近补全映射。

5. **INSERT OVERWRITE（目标写入）**
   将 `cheapest_<region>` 与 `complement_hour_list_<region>` 按 `a.local_hour = b.real_hour` LEFT JOIN，将 `flag_hour` 作为输出 `local_hour`，覆盖写入目标表对应 `(grass_region, local_date)` 的所有小时分区。

**ETL 文件 2（非亚洲区，直接导入）：**

1. **INSERT OVERWRITE（目标写入）**
   直接从 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf_import_nonasian` 按 `grass_region` 和 `local_date` 过滤，将 `local_hour` 原样透传，覆盖写入目标表对应分区，无补全逻辑。

### 注意事项

- **Multi-writer 风险**：两个 ETL 文件分别负责亚洲区和非亚洲区的分区写入，均使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date, local_hour)`，需确保两个任务在不同 `grass_region` 分区上串行或隔离执行，避免分区数据互相覆盖。
- **小时补全假设**：补全算法要求当天至少存在一个成功 dump 的小时（即 `real_hour_list` 不为空），否则全天 24 小时分区将无法写入有效数据。ETL 注释明确说明此前提：*"本算法假定一天之内，至少有一个 20 分钟，此 region 成功 dump 下来"*。
- **`business_type` 聚合语义**：ETL 中对 `business_type` 取 `max` 是为了在 cspu+model+item+shop+hour 维度上消除重复，并非业务层面的最大值含义，下游使用时需注意。
- **参数化执行**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}`、`${schema}` 均为运行时参数，每次调度按实际大区和日期注入，Temporary View 命名也带有大区后缀以避免多并发冲突。

---

*文档生成时间：2026-05-17*