<!-- ads-workspace-gdoc-sync: gdoc_id=1thCqWzKiWvpbkX_DGRpNwjIO_vx_xvduY_1kH0cY-8U gdoc_url=https://docs.google.com/document/d/1thCqWzKiWvpbkX_DGRpNwjIO_vx_xvduY_1kH0cY-8U/edit -->

# srdi_mart.dwd_sr_data_warehouse_cspu_info_hf

**分层：** DWD（明细数据层）
**主键：** `cspu_id`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（hf = hourly frequency）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表是 SRDI 搜推数仓中 **CSPU（标准产品单元，Canonical SPU）** 的小时级明细宽表，记录各区域 CSPU 的完整属性快照，包括分类归属、标题图片、标签、有效状态、代表性商品与店铺绑定关系，以及创建/更新时间戳等信息。

**核心业务场景：**

- 下游搜推特征工程中获取 CSPU 基础属性（标题、图片、分类、标签等）
- 跨时区分析：通过同时保留区域时间（`regional_date/regional_hour`）和本地时间（`local_date/local_hour`）支持多时区对齐
- CSPU 有效性筛查（`is_valid`），过滤失效数据
- 追踪 CSPU 与代表性 SPU/商品/店铺的绑定关系

**适合回答的问题：**

- 某区域某小时内有哪些有效 CSPU？其分类、标题、图片是什么？
- 某 CSPU 关联的代表性商品（`typical_item_id`）和店铺（`typical_shop_id`）是什么？
- 某 CSPU 的业务标签（`biz_tag`）和来源（`source`）如何分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识（如 SG、MY、TH 等），用于多区域数据隔离；INSERT OVERWRITE 按此字段分区写入 |
| `local_date` | date | CSPU 数据对应的本地日期，由区域时间（SG）转换至目标 `grass_region` 时区后得到 |
| `local_hour` | int | CSPU 数据对应的本地小时（0–23），与 `local_date` 同步转换自区域时间 |
| `regional_date` | date | 原始区域日期（SG 时区），来自 ETL 参数 `${regional_date}` |
| `regional_hour` | int | 原始区域小时（SG 时区），来自 ETL 参数 `${regional_hour}` |

### 维度：CSPU 标识与基础属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU 唯一标识，表主键 |
| `cspu_key` | string | CSPU 的业务键，用于外部系统关联或去重 |
| `cspu_profile` | string | CSPU 的结构化属性描述（通常为 JSON/序列化格式） |
| `cspu_title` | string | CSPU 展示标题 |
| `cspu_value` | string | CSPU 价值属性，具体含义依业务场景而定 |
| `cspu_image` | string | CSPU 主图 URL |
| `cat_id` | int | CSPU 所属类目 ID |
| `source` | string | CSPU 数据来源标识（如不同导入渠道或生产方式） |
| `biz_tag` | bigint | 业务标签，用于标记 CSPU 的业务属性或流量场景 |
| `is_valid` | int | CSPU 有效状态标记，通常 1 表示有效，0 表示无效 |

### 维度：代表性商品与店铺绑定

| 字段 | 类型 | 说明 |
|---|---|---|
| `typical_model_id` | bigint | 与该 CSPU 绑定的代表性 Model ID（SKU 层级） |
| `typical_item_id` | bigint | 与该 CSPU 绑定的代表性商品 Item ID |
| `typical_shop_id` | bigint | 与该 CSPU 绑定的代表性店铺 Shop ID |

### 指标：时间戳

| 字段 | 类型 | 说明 |
|---|---|---|
| `create_time` | bigint | CSPU 记录创建时间戳（Unix 毫秒或秒），ODS 中为 NULL 的记录已被过滤 |
| `update_time` | bigint | CSPU 记录最后更新时间戳（Unix 毫秒或秒） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将全量扫描所有区域分区，导致性能问题。示例：`WHERE grass_region = 'SG'`
- **`local_date` 或 `regional_date`**：必须指定日期分区，避免全表扫描。推荐以 `local_date` 过滤本地时区业务场景，以 `regional_date` 过滤需与 SG 时区对齐的场景。
- **`local_hour` 或 `regional_hour`**：小时级表每小时一个分区，查询时建议同步指定小时范围，精确锁定所需数据切片。
- **`is_valid`**：业务分析时通常需要加 `is_valid = 1` 过滤无效 CSPU。

### 不可直接 SUM 的字段

- `create_time`、`update_time`：时间戳，无加和语义，仅用于排序、过滤、比较。
- `biz_tag`：业务标签编码，为 bigint 类型但不具有数值累加含义，应视为枚举值使用 `GROUP BY` 或 `IN` 过滤。
- `cat_id`：类目 ID，同为编码字段，不可 SUM。

### 时效性说明

- 本表为**小时级快照表**（hf = hourly frequency），每小时由 ETL Job 以 `INSERT OVERWRITE` 方式覆写对应分区，同一分区内数据为当次全量覆盖快照。
- 每次写入以 ETL 参数 `${regional_date}` + `${regional_hour}`（SG 时间）为基准，转换后写入对应 `local_date` / `local_hour` 分区。
- 数据时效通常存在 1 小时内延迟，不适合用于实时场景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.srdi_mart.ods_sr_data_warehouse_cspu_info` | ODS 层 CSPU 原始明细数据，提供所有 CSPU 属性字段；按 `grass_region` 过滤并剔除 `create_time IS NULL` 的脏数据后写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.srdi_mart.ods_sr_data_warehouse_cspu_info
        │
        │ 过滤：grass_region IN (${grass_region})
        │        AND create_time IS NOT NULL
        │
        ▼
时区转换：regional_date/regional_hour (SG) → local_date/local_hour (目标区域)
        │
        ▼
srdi_mart.dwd_sr_data_warehouse_cspu_info_hf
（INSERT OVERWRITE，按 grass_region + local_date + local_hour + regional_date + regional_hour 分区）
```

### 关键步骤

1. **数据读取与过滤**：从 ODS Paimon 表中读取指定 `grass_region` 的 CSPU 数据，并过滤掉 `create_time IS NULL` 的记录（ODS 中存在当前值为 NULL 的异常数据）。

2. **时区转换**：使用 UDF `date_timezone_convert` 将区域基准时间（SG，`${regional_date}` + `${regional_hour}`）转换为目标 `grass_region` 对应的本地时间，分别派生 `local_date`（日期格式）和 `local_hour`（整型小时）。

3. **分区写入**：以 `INSERT OVERWRITE` 方式覆写目标表对应分区（`grass_region` 为静态分区，其余四个字段为动态分区），保证幂等性。

### 注意事项

- **单一 Writer**：该表仅有 1 个 ETL 文件写入，无 multi-writer 风险，分区边界清晰。
- **INSERT OVERWRITE 幂等性**：重跑同一 `grass_region` + 时间参数组合时，会覆盖对应分区历史数据，需注意避免重跑非预期历史分区。
- **`create_time IS NULL` 过滤**：ETL 注释明确说明 ODS 中存在 `current` 为 NULL 的情况，过滤后下游不会收到 `create_time` 为 NULL 的记录，使用时无需再次判空。
- **时区转换依赖 UDF**：`date_timezone_convert` 为平台自定义函数，若在非标准 Spark 环境中执行需确认 UDF 已注册。
- **`grass_region` 静态分区**：`grass_region` 为静态分区参数 `${grass_region}`，每次 ETL 运行仅写入单一区域，多区域需多次调度。

---

*文档生成时间：2026-05-18*