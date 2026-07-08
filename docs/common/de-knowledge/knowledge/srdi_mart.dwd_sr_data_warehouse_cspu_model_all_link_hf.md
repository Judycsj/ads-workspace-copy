<!-- ads-workspace-gdoc-sync: gdoc_id=1iCscwKdsa_LgPXhXYspyxd9pACQznHP_1ReJlphEAa0 gdoc_url=https://docs.google.com/document/d/1iCscwKdsa_LgPXhXYspyxd9pACQznHP_1ReJlphEAa0/edit -->

# srdi_mart.dwd_sr_data_warehouse_cspu_model_all_link_hf

**分层：** DWD（明细数据层）
**主键：** `cspu_id`、`model_id`、`item_id`、`shop_id`（联合标识一条 CSPU-模型-商品-店铺关联链路）
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（hf = hourly full，按小时全量覆盖写入）
**引用频次 / 访问频次：** 494

---

## 业务描述

本表存储搜推（SR）数据仓库中 **CSPU（内容/商品标准化单元）与 Model 之间的有效关联链路**明细，来源于 ODS 层 Paimon 表 `rcmd_feature.ods_sr_data_warehouse_tc_cspu_model_link`，经过时区转换和业务过滤后写入。

**核心业务场景：**
- 为搜推系统提供 CSPU → Model → Item → Shop 的完整关联链路，支撑推荐/搜索的候选召回和链路追踪。
- 通过 `biz_tag` 标识链路的业务属性（竞价、继承、最低价、买家秀等），可用于区分不同来源和策略的关联链路。
- 仅保留状态为有效（`status=1`）且 `cspu_id` 非空的链路，即剔除新品特供/低价不可用以及手动删除的链路记录。

**适合回答的问题：**
- 某 CSPU 在指定时间、地区下关联了哪些 Model、Item、Shop？
- 某 model/item/shop 下当前有效的 CSPU 关联链路有哪些？
- 不同 `biz_tag` 类型的链路数量分布与覆盖情况如何？
- 某草地区域（`grass_region`）下各小时链路数量变化趋势？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 草地区域编码，如 `SG`、`MY` 等，用于区分不同市场分区 |
| `local_date` | date | 本地日期，由 `regional_date`+`regional_hour` 经时区转换（SG → 目标 `grass_region` 时区）后的日期部分 |
| `local_hour` | int | 本地小时，由 `regional_date`+`regional_hour` 经时区转换后的小时部分（0–23） |
| `regional_date` | date | 区域日期（SG 时区），原始调度参数直接透传 |
| `regional_hour` | int | 区域小时（SG 时区），原始调度参数直接透传（0–23） |

### 维度：CSPU-模型-商品-店铺关联链路标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（内容/商品标准化单元）ID；链路中 `cspu_id` 为空时该记录已被过滤（新品特供/低价不可用/手动删除场景） |
| `model_id` | bigint | 关联的商品 Model ID |
| `item_id` | bigint | 关联的商品 Item ID |
| `shop_id` | bigint | 关联的店铺 ID |

### 维度：链路业务属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `biz_tag` | bigint | 链路业务标签，转为二进制按位解读：1=bidding；2=inherit；3=bidding+inherit；4=cheapest；5=bidding+cheapest；6=inherit+cheapest；7=bidding+inherit+cheapest；8=buybox；256/512=new item（新品）；各 bit 可组合叠加 |

### 指标：链路元数据

| 字段 | 类型 | 说明 |
|---|---|---|
| `update_time` | bigint | 链路最后更新时间戳，来源于上游字段 `link_update_time`，单位通常为毫秒级 Unix 时间戳 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤不可省略**：查询时务必同时指定 `grass_region`、`local_date`（或 `regional_date`）、`local_hour`（或 `regional_hour`），否则将触发全分区扫描，导致严重性能问题。
- 推荐过滤模板：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2026-05-17'
    AND regional_hour = 10
  ```
- 若需按本地时间过滤，应使用 `local_date` + `local_hour`，二者均为分区字段，可直接用于过滤。

### 不可直接 SUM 的字段

- **`biz_tag`**：该字段为位掩码（bitmask），数值本身无加和意义，统计各 tag 类型时应使用按位运算（如 `biz_tag & 1 > 0` 判断是否含 bidding），**不可直接 SUM 或 AVG**。
- **`update_time`**：时间戳字段，聚合时应使用 `MAX`/`MIN`，不可 SUM。

### 时效性说明

- 本表为**小时全量表**（hf = hourly full），每小时通过 `INSERT OVERWRITE` 全量覆盖对应分区，查询时应选取最新完成的 `regional_date` + `regional_hour` 分区以获取当前有效链路快照。
- `local_date` / `local_hour` 与 `regional_date` / `regional_hour` 存在时区偏移，跨区域对比时需注意时区对齐。
- 表中数据已过滤 `status ≠ 1` 及 `cspu_id IS NULL` 的记录，不代表全量原始链路，仅反映**当前有效链路快照**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.rcmd_feature.ods_sr_data_warehouse_tc_cspu_model_link` | CSPU-Model 关联链路原始 ODS 表，提供 `cspu_id`、`model_id`、`item_id`、`shop_id`、`biz_tag`、`link_update_time`、`status` 等原始字段 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.rcmd_feature.ods_sr_data_warehouse_tc_cspu_model_link
    │
    ├─ 过滤：grass_region 匹配目标区域 & status = 1 & cspu_id IS NOT NULL
    │
    ├─ 时区转换：(regional_date, regional_hour) [SG时区] → (local_date, local_hour) [grass_region本地时区]
    │
    └─ INSERT OVERWRITE → srdi_mart.dwd_sr_data_warehouse_cspu_model_all_link_hf
```

### 关键步骤

1. **过滤有效链路**：从 ODS 层 Paimon 表中读取指定 `grass_region` 下 `status=1` 的记录，并排除 `cspu_id IS NULL` 的链路（包含新品特供/低价不可用及手动删除场景）。
2. **时区转换**：调用 UDF `date_timezone_convert` 将 SG 时区的 `regional_date`+`regional_hour` 转换为目标 `grass_region` 本地时区，分别派生 `local_date`（date 类型）和 `local_hour`（int 类型）。
3. **字段映射**：将 `link_update_time` 重命名为 `update_time`，其余维度字段直接透传。
4. **分区覆盖写入**：以 `INSERT OVERWRITE` 方式按 `grass_region`、`local_date`、`local_hour`、`regional_date`、`regional_hour` 五级分区写入目标表，实现小时级全量刷新。

### 注意事项

- **单写入文件**：`multi_writer = false`，仅有一个 ETL 文件写入该表，无多路并发写入风险。
- **全量覆盖语义**：`INSERT OVERWRITE` 每次运行会覆盖对应分区的全量数据，回溯历史分区时需确认调度任务已正常完成，避免读取到空分区。
- **`cspu_id` 过滤注意**：业务注释明确说明（20260312 起），非新品特供且非低价可用的 link 其 `cspu_id` 会被置 null，手动删除的记录 `cspu_id` 及其他非 model_id 字段也均为 null；ETL 已统一通过 `cspu_id IS NOT NULL` 过滤，无需下游二次处理。
- **`biz_tag` 位掩码**：字段为多标签位运算编码，下游使用时需按位解析，不可作为普通整型聚合。
- **时区一致性**：`local_date`/`local_hour` 与 `regional_date`/`regional_hour` 共同存在于分区中，跨时区场景下两组分区字段均需正确传入，否则可能导致分区匹配失败。

---

*文档生成时间：2026-05-17*