<!-- ads-workspace-gdoc-sync: gdoc_id=1eD_Br5OQj-bjoAOgYeQNDd8NexiUppycIzuL5SAu5Qc gdoc_url=https://docs.google.com/document/d/1eD_Br5OQj-bjoAOgYeQNDd8NexiUppycIzuL5SAu5Qc/edit -->

# srdi_mart.dwd_sr_data_warehouse_ni_all_cspu_link_hf

**分层：** DWD（数据明细层）
**主键：** `cspu_id` + `model_id` + `item_id` + `shop_id` + `biz_tag` + `grass_region` + `regional_date` + `regional_hour`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（hf = hourly full）
**访问频次：** 2243

---

## 业务描述

本表存储搜推数仓中**新品特供（New Item，NI）CSPU 与模型/商品/店铺的关联关系**明细数据，属于 DWD 层小时级全量快照表。

数据来源于 Paimon ODS 层的 CSPU-Model 链路表，经过时区转换（SG → 目标草地区域）、状态过滤（仅保留有效链路 `status=1`）、以及 NI 业务标签过滤（`biz_tag & 512 > 0`，即未退场的新品特供 CSPU）后写入。

**核心业务场景：**
- 追踪新品特供 CSPU 与推荐模型、商品 item、店铺之间的实时链路关系；
- 为搜推推荐系统提供"当前哪些 CSPU 仍在新品特供链路中"的基础维度数据；
- 区分"包含退场（`biz_tag=256`）"与"不包含退场（`biz_tag=512`）"两种 NI CSPU 识别口径，本表仅保留不包含退场口径（`biz_tag & 512 > 0`）。

**适合回答的问题：**
- 指定草地区域、指定小时内，哪些 CSPU 处于新品特供有效链路中？
- 某个 CSPU 关联的模型 ID、商品 ID、店铺 ID 是什么？
- 新品特供链路最近一次更新时间是何时？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 草地区域标识（如 `SG`、`MY` 等），用于多区域分区隔离 |
| `local_date` | date | 目标草地区域本地日期，由 SG 时区的 `regional_date`+`regional_hour` 转换而来 |
| `local_hour` | int | 目标草地区域本地小时，由 SG 时区转换而来 |
| `regional_date` | date | SG 时区原始日期，ETL 调度参数透传 |
| `regional_hour` | int | SG 时区原始小时，ETL 调度参数透传 |

### 维度：CSPU 与关联实体标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `cspu_id` | bigint | CSPU（Campaign SPU）唯一标识；MPI 流控链路的 CSPU 可能被置 null，本表已过滤掉 null 值 |
| `model_id` | bigint | 关联的推荐模型 ID |
| `item_id` | bigint | 关联的商品 ID |
| `shop_id` | bigint | 关联的店铺 ID |

### 维度：业务标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `biz_tag` | bigint | 业务标签位掩码。本表仅保留 `biz_tag & 512 > 0` 的记录，即不包含退场的新品特供 CSPU；`biz_tag=256` 表示包含退场口径（已排除）；`biz_tag=512` 表示不包含退场口径 |

### 指标：链路时效信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `update_time` | bigint | 链路最近更新时间戳（来源字段 `link_update_time`），用于追踪链路数据的最新变更时刻 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪（强制）**：查询时务必指定 `grass_region`、`regional_date`、`regional_hour`（或 `local_date`、`local_hour`）以避免全表扫描。示例：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2026-05-17'
    AND regional_hour = 10
  ```
- 本表每小时执行一次全量覆盖写入（`INSERT OVERWRITE`），**每个分区只保留当前小时的最新快照**，使用时应明确指定目标时间分区。

### 不可直接 SUM 的字段

- `biz_tag`：位掩码字段，不可直接聚合求和，需使用位运算（`& 512`、`& 256`）进行过滤或分类。
- `update_time`：时间戳，聚合时应使用 `MAX` / `MIN`，而非 `SUM`。

### 时效性说明

- 本表为**小时级全量快照**（hf = hourly full），数据反映上游 Paimon ODS 表在对应小时的最新状态。
- `local_date` / `local_hour` 为目标区域本地时间，`regional_date` / `regional_hour` 为 SG 时区时间，跨时区分析时注意区分两组时间字段的语义。
- 数据准实时，存在 ETL 调度延迟，不代表绝对实时状态。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `paimon.rcmd_feature.ods_sr_data_warehouse_tc_cspu_model_link` | 原始 CSPU-Model 链路 ODS 表，提供 CSPU、模型、商品、店铺关联关系及业务标签、链路更新时间等全量数据 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.rcmd_feature.ods_sr_data_warehouse_tc_cspu_model_link
    │
    ├─ 过滤：grass_region IN (${grass_region}) AND status = 1
    ├─ 过滤：cspu_id IS NOT NULL
    ├─ 过滤：biz_tag & 512 > 0（保留不含退场的新品特供）
    ├─ 时区转换：SG → 目标 grass_region 本地时间（local_date / local_hour）
    │
    └─▶ srdi_mart.dwd_sr_data_warehouse_ni_all_cspu_link_hf
         分区：grass_region / local_date / local_hour / regional_date / regional_hour
```

### 关键步骤

1. **过滤有效链路**：从 ODS 层 CSPU-Model 链路表中筛选指定草地区域（`grass_region`）且状态有效（`status=1`）的记录。
2. **排除 null CSPU**：过滤掉 `cspu_id IS NULL` 的记录，规避 MPI 流控场景及手动删除导致的脏数据。
3. **NI 口径过滤**：仅保留 `biz_tag & 512 > 0` 的记录，即"不包含退场"口径的新品特供 CSPU（排除 `biz_tag=256` 包含退场口径）。
4. **时区转换**：调用 `date_timezone_convert` 函数，将 SG 时区的 `${regional_date}` / `${regional_hour}` 转换为目标草地区域的本地日期（`local_date`）和本地小时（`local_hour`）。
5. **全量覆盖写入**：使用 `INSERT OVERWRITE` 按分区全量刷新目标表，保证每小时数据的幂等性。

### 注意事项

- **单 Writer**：本表仅由单个 ETL 文件写入（`multi_writer=false`），无多源合并风险。
- **全量覆盖语义**：每次调度均执行 `INSERT OVERWRITE`，同一分区的历史数据会被完全替换，不支持增量追加。
- **biz_tag 口径变更（2026-03-12）**：NI CSPU 的识别方式已更新，`biz_tag=256` 为包含退场口径，`biz_tag=512` 为不包含退场口径，本表固定使用后者，下游使用时需注意口径一致性。
- **时区字段双轨**：表中同时存在 SG 时区（`regional_date`/`regional_hour`）和本地时区（`local_date`/`local_hour`）两套时间字段，跨区域联查时需明确使用哪套时间口径。
- **分区字段数量多**：五个分区字段同时存在，查询时建议优先指定 `grass_region` + `regional_date` + `regional_hour` 以最大化分区裁剪效率。

---

*文档生成时间：2026-05-17*