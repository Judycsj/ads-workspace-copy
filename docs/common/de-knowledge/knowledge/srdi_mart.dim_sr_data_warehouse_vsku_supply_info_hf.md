<!-- ads-workspace-gdoc-sync: gdoc_id=1KVrlEkM-vAkTkHzCT2hZR5v24c6Lw4WtkuGT_ZH1H6k gdoc_url=https://docs.google.com/document/d/1KVrlEkM-vAkTkHzCT2hZR5v24c6Lw4WtkuGT_ZH1H6k/edit -->

# srdi_mart.dim_sr_data_warehouse_vsku_supply_info_hf

**分层：** DIM（维度层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `model_id`
**分区：** `grass_region` / `regional_date` / `regional_hour`
**更新频率：** 小时级（每小时刷新一次，取上游 ODS 表最新可用分区）
**访问频次：** 504 次

---

## 业务描述

本表存储各地区（草根大区）下虚拟 SKU（vSKU）的供给价格信息，按小时粒度分区存储。数据来源于上游 ODS 供给信息宽表，经解析 JSON 字段、提取促销结果中的供给价格后写入。

**核心业务场景：**
- 搜索、推荐、广告（SRDI）场景中，实时/准实时获取各 vSKU 的当前供给价格，用于召回、排序、出价等模块的价格特征输入。
- 通过旁路 Kafka 写入（`kafka.srdi_mart.dim_srdi_vsku_supply_info_hf`），支持下游流式消费；同时通过 Hive 分区写入支持批式查询。

**适合回答的问题：**
- 某地区某小时内，特定 model 的供给价格是多少？
- 当前最新分区中，各 model 的供给价格分布情况？
- 跨时间维度对比某 model 的供给价格变化趋势（小时粒度）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 草根大区标识（如 `SG`、`MY`、`TH` 等），用于多地区数据隔离分区 |
| `regional_date` | date | 数据所属的地区本地日期，格式 `yyyy-MM-dd` |
| `regional_hour` | int | 数据所属的地区本地小时（0–23），与 `regional_date` 联合定位具体数据批次 |

### 维度：vSKU 标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `model_id` | bigint | 虚拟 SKU 的 model 唯一标识，对应商品的具体规格（vSKU 粒度） |

### 指标：供给价格

| 字段 | 类型 | 说明 |
|------|------|------|
| `supply_price` | double | vSKU 的供给价格（单位：元/当地货币主单位），由上游 ODS 的 `supply_info` JSON 字段中 `display_promo_result.item_promo_infos[0].model_promo_infos[0].main.price.supply_price` 提取，原始值为 bigint（精度 100000），除以 100000 后转为 double |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定三个分区字段**：`grass_region`、`regional_date`、`regional_hour`，缺少任一条件均会导致全表扫描，严重影响性能。
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-01-01'
    AND regional_hour = 10
  ```
- 每次 ETL 写入时取的是上游 ODS **最新可用分区**（非一定等于调度时间对应分区），实际数据时间可能略滞后于调度触发时间，查询时应注意分区时效。

### 不可直接 SUM 的字段

- **`supply_price`**：为单个 model 的价格点，跨 model 直接 SUM 无业务意义；如需汇总分析，应结合具体业务场景使用 `AVG`、`PERCENTILE` 等聚合方式，并明确分组维度。

### 时效性说明

- 本表为**小时级准实时维度表**（`_hf` 后缀表示 hourly frequency），每小时调度一次。
- ETL 逻辑中使用"最大可用分区"策略写入：若上游 ODS 某小时数据未就绪，本表该分区可能沿用最近一次成功分区的数据，查询时需注意数据是否为预期小时的真实快照。
- 旁路 Kafka 写入路径（流式消费）与 Hive 分区写入路径（批式查询）共用同一批数据，数据一致。
- 上游 ODS 仅保留约一个月数据，本表历史数据深度受此限制。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.ods_sr_data_warehouse_vsku_supply_info_hf` | 原始供给信息宽表，包含各 vSKU 的 `supply_info` JSON 字段，提供 model 级别的促销价格原始数据 |

---

## ETL 逻辑摘要

### 数据流

```
ods_sr_data_warehouse_vsku_supply_info_hf
    ↓ [取最新可用分区]
    ↓ [解析 supply_info JSON，提取 supply_price，除以 100000]
    → Temporary View: new_supply_info_${grass_region}
        ├─→ kafka.srdi_mart.dim_srdi_vsku_supply_info_hf （Kafka 旁路写入，流式消费）
        └─→ srdi_mart.dim_sr_data_warehouse_vsku_supply_info_hf （Hive 分区写入）
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|------|------|------|
| Step 1：获取最新分区 | SET 变量 | 在上游 ODS 表中查询 `regional_date >= ${regional_date}` 范围内的最大 `regional_date + regional_hour` 组合，赋值给变量 `last_partition_${grass_region}`，防止错误回刷导致线上数据问题 |
| Step 2：构建中间视图 | CREATE TEMPORARY VIEW | 以 Step 1 解析出的最新分区日期和小时过滤 ODS 数据，通过 `get_json_object` 提取 `supply_info` 中的 `supply_price`（bigint 原始值），除以 100000 转换为 double，生成临时视图 `new_supply_info_${grass_region}` |
| Step 3：Kafka 旁路写入 | INSERT INTO | 将临时视图数据写入 Kafka 外表 `kafka.srdi_mart.dim_srdi_vsku_supply_info_hf`，支持下游实时消费（含 `model_id`、`supply_price`、`grass_region`、`regional_date`、`regional_hour` 五字段） |
| Step 4：Hive 分区写入 | INSERT OVERWRITE | 将临时视图数据按 `(grass_region, regional_date, regional_hour)` 三级分区覆盖写入目标表，仅写入 `model_id` 和 `supply_price` 两个非分区字段 |

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表仅有 1 个 ETL 文件写入，不存在多文件并发写同一分区的竞争问题。
- **Kafka 写入依赖特殊 Spark Conf**：Kafka 外表写入需在 Spark job 中配置 `spark.sql.catalog.kafka.enabled=true` 及对应 `group.id`，否则 Step 3 将失败。Kafka 表结构变更需删表重建并提前周知下游消费方。
- **分区写入策略**：目标 Hive 分区由调度参数 `${regional_date}` 和 `${regional_hour}` 决定，但实际读取的 ODS 数据分区为动态取到的最新分区，两者可能不一致（即写入分区 ≠ 数据实际分区），查询时需关注分区语义。
- **JSON 路径脆弱性**：`supply_price` 依赖固定 JSON 路径 `item_promo_infos[0].model_promo_infos[0].main.price.supply_price`，若上游 JSON 结构变更或数组为空，将导致该字段为 NULL，下游使用时需做空值处理。
- **ODS 数据保留周期约一个月**，ETL 中虽通过 `regional_date >= ${regional_date}` 缩小扫描范围，但若调度参数传入历史日期超出 ODS 保留期，将无法获取正确分区数据。

---

*文档生成时间：2026-05-17*