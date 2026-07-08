<!-- ads-workspace-gdoc-sync: gdoc_id=1Zc1GLfCwNTIJmkTmdA41QZ6wjT3GicJEk_TQK7SBC9M gdoc_url=https://docs.google.com/document/d/1Zc1GLfCwNTIJmkTmdA41QZ6wjT3GicJEk_TQK7SBC9M/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_reward_banner_model_1d

**分层**：ADS（应用数据层）
**主键**：`shop_id` + `model_id` + `grass_region` + `local_date` + `local_hour`
**分区**：`grass_region` / `local_date` / `local_hour`
**更新频率**：每小时一次（按小时分区写入）
**引用频次 / 访问频次**：7,204 次

---

## 业务描述

本表用于支撑搜推数仓**推广奖励（Reward）Banner 位模型**的每小时统计分析，记录各站点（`grass_region`）下每家店铺（`shop_id`）在指定日期和小时内，处于有效奖励状态的各广告模型（`model_id`）的曝光、成交订单及 GMV 汇总表现，并按店铺维度对模型进行排名和分页编号。

**核心业务场景**：
- 广告主/运营查看特定店铺下奖励 Banner 位各模型的小时粒度表现排行；
- 前端 Banner 列表分页展示：`rank_num` 和 `page_num` 直接支持分页渲染，每页 10 条；
- 模型效果归因与优化：基于 `imp_cnt`、`order_cnt`、`gmv` 对推广模型进行横向对比。

**适合回答的问题**：
- 某店铺在某小时内，哪些推广模型的成交量或 GMV 最高？
- 某推广模型在对应店铺的排名是第几位？属于第几页？
- 特定站点、特定日期小时的奖励 Banner 位模型整体曝光和成交情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据所属本地日期，格式 `YYYY-MM-DD` |
| `grass_region` | string | 站点/大区标识，如 `SG`、`MY`、`ID` 等 |
| `local_hour` | int | 数据所属本地小时（0–23） |

### 维度：店铺与模型标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，推广主体唯一标识 |
| `model_id` | bigint | 推广广告模型 ID |

### 指标：排名与分页

| 字段 | 类型 | 说明 |
|---|---|---|
| `rank_num` | bigint | 模型在所属店铺内的排名，按 `order_cnt DESC → imp_cnt DESC → gmv DESC → model_id DESC` 排序，从 1 开始 |
| `page_num` | bigint | 根据 `rank_num` 计算的分页页码，每页 10 条（`CEIL(rank_num / 10)`） |

### 指标：曝光、成交与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 该模型在指定小时内的曝光次数（聚合自上游 `imp_cnt`） |
| `order_cnt` | bigint | 该模型在指定小时内的成交订单数（聚合自上游 `sold_cnt`） |
| `gmv` | double | 该模型在指定小时内的成交 GMV（货币单位与站点一致） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，避免全站点扫描；
- **`local_date`**：必须指定，为主要时间分区；
- **`local_hour`**：建议同时指定，与前两个分区字段共同构成三级分区，缺少该条件将导致扫描当日全部小时分区；
- 三个分区字段共同决定一次 INSERT OVERWRITE 的写入边界，查询时须同时携带以确保精准定位。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `rank_num` | 窗口函数派生的排名值，跨分区或跨行聚合无业务意义 |
| `page_num` | 由 `rank_num` 衍生的分页编号，聚合后无意义 |

> `imp_cnt`、`order_cnt`、`gmv` 在同一 `grass_region + local_date + local_hour` 分区内已完成店铺-模型维度聚合，跨小时累加时需注意避免重复计数（建议先按 `local_date` 过滤再 GROUP BY 汇总）。

### 时效性说明

- 本表为**小时粒度（`local_hour`）**准实时表，数据在每小时 ETL 任务完成后可查；
- 每次写入为 `INSERT OVERWRITE PARTITION`，同一分区数据**完整覆盖**，不存在增量追加；
- 不建议用最新 `local_hour` 数据与历史小时数据直接跨小时加总，如需天级汇总应聚合当日 0–23 小时全部分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini` | 提供店铺、商品、模型维度的小时粒度曝光、成交订单数、GMV 明细数据；过滤 `model_status IN (1, 2)`（有效奖励状态）后聚合使用 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini
    │  过滤：grass_region、local_date、local_hour、model_status IN (1,2)
    │  聚合：shop_id + item_id + model_id + model_status + full_start_timestamp
    ↓
tmp_order_detail_<grass_region>（Temporary View）
    │  再聚合：shop_id + model_id（去除 item_id 等细粒度维度）
    │  窗口计算：RANK、PAGE（按 shop_id 分区）
    ↓
srdi_mart.ads_sr_data_warehouse_tc_pb_reward_banner_model_1d
    PARTITION(grass_region, local_date, local_hour)
```

### 关键步骤

1. **Statement 1 — 创建 Temporary View `tmp_order_detail_<grass_region>`**
   - 从上游 DWM 表读取指定分区（`grass_region`、`local_date`、`local_hour`）数据；
   - 过滤 `model_status IN (1, 2)`，仅保留有效奖励状态的模型记录；
   - 按 `shop_id + item_id + model_id + model_status + full_start_timestamp` 分组，汇总 `imp_cnt`、`sold_cnt`（映射为 `order_cnt`）、`gmv`。

2. **Statement 2 — INSERT OVERWRITE 写入目标表**
   - 子查询将 Temporary View 按 `shop_id + model_id` 再次聚合，消除 `item_id`、`model_status`、`full_start_timestamp` 维度；
   - 外层使用 `ROW_NUMBER()` 窗口函数，按 `shop_id` 分区，依 `order_cnt DESC → imp_cnt DESC → gmv DESC → model_id DESC` 排序，生成 `rank_num`；
   - `page_num` = `CEIL(rank_num / 10)`，每页 10 条；
   - 以 `INSERT OVERWRITE … PARTITION(grass_region, local_date, local_hour)` 全量覆盖写入目标分区。

### 注意事项

- **单一 Writer**：该表由单个 ETL 文件写入，无 multi-writer 风险；
- **分区覆盖语义**：每次运行对指定 `(grass_region, local_date, local_hour)` 三元组分区执行完整覆盖，重跑安全，但需确保参数一致；
- **参数化站点**：SQL 使用 `${grass_region}` 和 `${grass_region_without_quote}` 两个参数，Temporary View 名称含站点后缀，支持同一 Spark Session 内多站点并发执行而不互相干扰；
- **model_status 过滤**：仅保留状态为 1 或 2 的模型，目标表不包含其他状态的模型数据，下游使用时无需再过滤。

---

*文档生成时间：2026-05-17*