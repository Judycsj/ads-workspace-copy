<!-- ads-workspace-gdoc-sync: gdoc_id=15exkuunCCfa1ts0RYUZ_5t-_JTc4tNgKGKyuxY3bams gdoc_url=https://docs.google.com/document/d/15exkuunCCfa1ts0RYUZ_5t-_JTc4tNgKGKyuxY3bams/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_reward_banner_model_1d

**分层：** DWS（数据仓库汇总层）
**主键：** `shop_id` + `item_id` + `model_id` + `local_date` + `grass_region`
**分区：** `local_date`（日期分区）、`grass_region`（大区分区）
**更新频率：** 每日一次（T+1）
**访问频次：** 312 次

---

## 业务描述

本表汇总了 **TC（Topeka Campaign）激励广告（Reward Banner）** 场景下，各店铺（`shop_id`）、商品（`item_id`）、模型（`model_id`） 粒度的**每日投放效果指标**，包含曝光次数、订单数和 GMV。

数据来源于中间层 `dwm_sr_data_warehouse_tc_pb_reward_model_mini`，经聚合并过滤有效模型状态（`model_status IN (1, 2)`）后写入本表，仅保留有效店铺（`shop_id > 0`）。

**核心业务场景：**
- 分析激励广告不同模型在各大区的每日投放表现
- 评估商品维度的曝光→成单转化效率
- 提供店铺、商品、模型多维度的日粒度 GMV 归因

**适合回答的问题示例：**
- 某大区某日各模型的曝光量和成单量是多少？
- 哪些商品/店铺在激励 Banner 场景下 GMV 贡献最高？
- 不同模型在多个大区之间的效果对比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据日期（业务日期分区，格式 `YYYY-MM-DD`） |
| `grass_region` | string | 大区标识（如 `SG`、`MY`、`TH` 等），与业务地域对应 |

### 维度：店铺 / 商品 / 模型

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，ETL 已过滤 `shop_id > 0`，仅保留有效店铺 |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | 激励广告投放模型 ID，对应推荐/定价等算法模型 |

### 指标：曝光与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数，由上游 `imp_cnt` 按 `shop_id`、`item_id`、`model_id` 聚合求和 |
| `order_cnt` | bigint | 订单数，由上游 `sold_cnt` 聚合求和后重命名 |
| `gmv` | double | 成交金额（GMV），由上游 `gmv` 聚合求和，单位与上游一致（通常为本地货币） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：查询时必须指定，避免全量扫描。示例：`WHERE local_date = '2024-06-01'`。
- **`grass_region`**：本表为双分区结构，建议同时指定大区，进一步缩减扫描范围。示例：`AND grass_region = 'SG'`。

### 不可直接 SUM 的字段

- 本表所有指标（`imp_cnt`、`order_cnt`、`gmv`）均为**单日维度聚合值**，在同一分区内可直接 `SUM` 进行店铺/商品/模型间的横向汇总。
- **跨日汇总**时需明确 `local_date` 范围，避免重复计数；`gmv` 为 `double` 类型，汇总时注意精度问题。
- **转化率**（如 CVR = `order_cnt / imp_cnt`）不可直接对多行比率求平均，应先汇总分子分母再计算。

### 时效性说明

- 本表为 **`_1d` 日粒度表**，每日调度写入前一自然日数据（T+1 更新）。
- 数据不包含历史累计（无 `_td` 窗口），如需多日趋势分析需跨分区查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini` | 提供激励广告模型明细数据，包含曝光、成单、GMV 及模型状态字段，经过滤（`model_status IN (1, 2)`）和聚合后写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini
    │
    │  过滤：grass_region = ${grass_region}
    │        local_date   = ${local_date}
    │        model_status IN (1, 2)
    │
    ▼
tmp_union_detail_${grass_region_without_quote}（Temporary View）
    │  GROUP BY shop_id, item_id, model_id
    │  SUM(imp_cnt), SUM(sold_cnt) AS order_cnt, SUM(gmv)
    │
    │  过滤：shop_id > 0
    ▼
srdi_mart.dws_sr_data_warehouse_tc_pb_reward_banner_model_1d
    PARTITION(local_date, grass_region)
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Step 1 | Temporary View | 创建 `tmp_union_detail_${grass_region_without_quote}`，从上游 DWM 表按大区、日期过滤，仅保留 `model_status IN (1, 2)` 的有效模型记录，并按 `shop_id`、`item_id`、`model_id` 三维聚合 `imp_cnt`、`sold_cnt`（重命名为 `order_cnt`）、`gmv` |
| Step 2 | INSERT OVERWRITE | 将 Temporary View 结果写入目标表，追加过滤条件 `shop_id > 0` 排除无效店铺，以 `local_date` + `grass_region` 双分区 OVERWRITE 写入 |

### 注意事项

- **单一 Writer**：本表仅有 1 个 ETL 文件写入，无多 Writer 并发冲突风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE PARTITION` 模式，每次调度会覆盖指定 `local_date` + `grass_region` 分区的全量数据，重跑历史分区安全。
- **参数化大区**：SQL 通过 `${grass_region}`（带引号，用于 WHERE 条件）和 `${grass_region_without_quote}`（不带引号，用于 View 命名）两个参数控制大区，调度时需同时传入。
- **模型状态过滤**：仅保留 `model_status IN (1, 2)` 的记录，状态含义由上游 DWM 表定义，若上游状态枚举变更需同步评估本表覆盖范围。
- **字段重命名**：上游字段 `sold_cnt` 在本表中以 `order_cnt` 呈现，跨层联查时需注意字段映射。

---

*文档生成时间：2026-05-17*