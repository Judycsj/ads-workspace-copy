<!-- ads-workspace-gdoc-sync: gdoc_id=11ErEjofiA9RI6NFh3V7L4utbnKOFoYCy9lB4cXUVM9Q gdoc_url=https://docs.google.com/document/d/11ErEjofiA9RI6NFh3V7L4utbnKOFoYCy9lB4cXUVM9Q/edit -->

# srdi_mart.dwd_sr_data_warehouse_ssp_item_link_hf

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `item_id` + `spu_id` + `scene`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（hf = hourly frequency）
**引用频次 / 访问频次：** 335

---

## 业务描述

本表存储搜推（SR）数仓中 **SSP（Supply-Side Platform）商品链接关系**的小时级明细数据，来源于 ODS 层 Paimon 实时表 `rcmd_feature.ods_sr_data_warehouse_ssp_item_link`，经过时区转换、JSON 字段解析、SPU 列表展开及场景过滤后写入。

**核心业务场景：**
- 记录每个 SKU（`item_id`）在特定小时内与 SPU（`spu_id`）的关联关系，并标注所属店铺（`shop_id`）及适用推荐场景（`scene`）。
- 仅保留 `scene & 4 > 0` 的记录，即只存储**专供 SRA（Search Recommendation Ads / Scene Recommendation Algorithm）使用**的商品链接。
- 支持跨时区分析：同时保留新加坡区域时间（`regional_date` / `regional_hour`）与本地时间（`local_date` / `local_hour`）两套时间维度。

**适合回答的问题：**
- 某区域、某小时内哪些 SKU 与 SPU 存在有效的 SRA 推荐链接关系？
- 某店铺下各 SPU 在指定小时的商品关联覆盖情况？
- SRA 场景下 SKU-SPU 映射关系的时序变化趋势？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `SG`、`MY`、`TH` 等，用于多区域数据隔离 |
| `local_date` | date | 本地日期，由新加坡区域时间（`regional_date` + `regional_hour`）转换至目标 `grass_region` 时区后的日期 |
| `local_hour` | int | 本地小时，由区域时间转换至目标 `grass_region` 时区后的小时（0–23） |
| `regional_date` | date | 新加坡（SG）区域日期，ETL 调度参数直接写入 |
| `regional_hour` | int | 新加坡（SG）区域小时，ETL 调度参数直接写入（0–23） |

### 维度：商品与店铺标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | SKU ID，商品最小销售单元标识 |
| `shop_id` | bigint | 店铺 ID，`item_id` 所属店铺 |
| `spu_id` | bigint | SPU ID，从 ODS 表 `spu_infos` 数组展开后的 JSON 字段 `$.spu_id` 解析而来 |
| `scene` | bigint | 推荐场景标识，从 `spu_infos` 数组展开后的 JSON 字段 `$.scene` 解析而来；已过滤为 `scene & 4 > 0`（仅保留 SRA 场景） |

### 指标：记录时效

| 字段 | 类型 | 说明 |
|---|---|---|
| `update_time` | bigint | 记录在上游 ODS 表中的最后更新时间戳（毫秒或秒级 Unix 时间戳，以上游定义为准） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须显式指定**，至少包含以下分区字段组合，否则将触发全表扫描：
  ```sql
  WHERE grass_region = 'XX'
    AND regional_date = '2025-01-01'
    AND regional_hour = 10
  ```
- `local_date` / `local_hour` 为时区转换后的本地时间分区，若按本地时间查询可改用这两列作为过滤条件，但需同时指定 `grass_region`。
- 本表**仅包含 `scene & 4 > 0` 的记录**，查询时无需再次添加该过滤条件，但需了解此前提，避免误以为是全量场景数据。

### 不可直接 SUM / 聚合的字段

- `scene`：为位掩码（bitmask）标志位字段，直接求和无业务意义，需使用位运算（`&`）进行场景判断。
- `update_time`：时间戳语义字段，直接 SUM 无意义，应取 `MAX` / `MIN` 判断数据时效。

### 时效性说明

- 本表为**小时级（hourly）更新**，数据通常延迟 1–2 小时可查。
- 每次写入使用 `INSERT OVERWRITE`，按分区覆盖，同一分区数据具有幂等性。
- `regional_date` + `regional_hour` 是以新加坡时间为基准的调度时间，`local_date` + `local_hour` 是各区域本地时间，跨时区对比分析时注意区分。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.rcmd_feature.ods_sr_data_warehouse_ssp_item_link` | 提供 SKU-SPU 原始关联数据，含 `item_id`、`shop_id`、`spu_infos`（JSON 数组）、`update_time`，按 `grass_region` 过滤后展开 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.rcmd_feature.ods_sr_data_warehouse_ssp_item_link
  │
  ├─ [1] 按 grass_region 过滤，排除 spu_infos 为 NULL 的记录
  ├─ [2] LATERAL VIEW EXPLODE(spu_infos) 将 SPU 数组展开为多行
  ├─ [3] 解析 JSON：get_json_object 提取 spu_id、scene
  ├─ [4] 场景过滤：scene & 4 > 0，仅保留 SRA 适用记录
  ├─ [5] 时区转换：regional_date + regional_hour (SG) → local_date + local_hour (grass_region)
  │
  └─▶ srdi_mart.dwd_sr_data_warehouse_ssp_item_link_hf
        INSERT OVERWRITE 按分区写入
```

### 关键步骤

1. **数据读取与预过滤**
   直接从 ODS Paimon 表读取，使用 `WHERE grass_region IN (${grass_region}) AND spu_infos IS NOT NULL` 过滤目标区域及非空数组记录。

2. **SPU 数组展开**
   使用 `LATERAL VIEW EXPLODE(spu_infos) AS spu_info` 将每个 SKU 对应的多个 SPU 展开为独立行，实现一对多关系的行化。

3. **JSON 字段解析**
   - `spu_id`：`CAST(get_json_object(spu_info, '$.spu_id') AS bigint)`
   - `scene`：`CAST(get_json_object(spu_info, '$.scene') AS int)`

4. **SRA 场景过滤**
   外层 `WHERE scene & 4 > 0`，通过位运算过滤，仅保留适用于 SRA 的商品链接记录。

5. **时区转换**
   - `local_date`：`date(date_timezone_convert(${regional_date}, ${regional_hour}, 'SG', ${grass_region}, "yyyy-MM-dd"))`
   - `local_hour`：`CAST(date_timezone_convert(${regional_date}, ${regional_hour}, 'SG', ${grass_region}, "HH") AS int)`

6. **分区覆盖写入**
   使用 `INSERT OVERWRITE ... PARTITION(grass_region = ${grass_region}, local_date, local_hour, regional_date, regional_hour)` 动态分区方式写入目标表。

### 注意事项

- **单一写入来源**：本表为单 ETL 文件写入（`multi_writer = false`），无多路并发写入风险。
- **分区覆盖语义**：`INSERT OVERWRITE` 模式，同一调度周期重跑对相同分区安全幂等，但需避免跨分区参数错误导致错误覆盖。
- **位掩码场景字段**：`scene` 字段采用位标志设计，ETL 已在写入前过滤 `scene & 4 > 0`，下游若有其他场景需求请勿复用本表，应回溯 ODS 层。
- **时区转换依赖 UDF**：`date_timezone_convert` 为自定义 UDF，若部署环境缺失该函数将导致 ETL 失败；`local_date` / `local_hour` 的准确性依赖该 UDF 的正确性。
- **`spu_infos` 为空保护**：ETL 已过滤 `spu_infos IS NOT NULL`，但若上游字段为空字符串或空数组，需关注 ODS 层数据质量。

---

*文档生成时间：2026-05-17*