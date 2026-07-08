<!-- ads-workspace-gdoc-sync: gdoc_id=1Kx2IaniduOsL6EZkqp_reb7LTjwotnq8SBo4RFF4B0Y gdoc_url=https://docs.google.com/document/d/1Kx2IaniduOsL6EZkqp_reb7LTjwotnq8SBo4RFF4B0Y/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d

**分层：** DWS（数据汇总层）
**主键：** `cspu_id`（分区内唯一）
**分区：** `grass_region`（大区）/ `local_date`（本地日期）
**更新频率：** 每日一次（T+1 分区覆盖写入）
**访问频次：** 51,271 次

---

## 业务描述

本表为搜推数仓（SRDI）**TC 品牌商品（PB CSPU）维度的每日汇总宽表**，以 CSPU（平台商品单元）为粒度，汇聚各大区每日的归因订单量数据，同时标注 CSPU 所归属的价格率档位模型（PR Rate）。

**核心业务场景：**
- 品牌商品（PB）CSPU 维度的成交效果分析
- 按大区、日期下钻的 CSPU 粒度订单贡献评估
- 搜推流量与 TC 订单的归因链路核查
- 输出给下游指标层或报表层进行 CSPU 排名、趋势分析

**适合回答的问题举例：**
- 某大区某日各 CSPU 的订单量分别是多少？
- 哪些 CSPU 在特定时间段内订单贡献最高？
- 各 CSPU 对应的价格率档位（PR Rate）是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`MY`、`TH` 等，每个分区写入一个大区的数据 |
| `local_date` | date | 本地业务日期（按大区本地时区），对应数据的自然日 |

### 维度：CSPU 商品维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（平台商品单元）ID，表内核心维度键，分区内唯一 |
| `cspu_pr_rate` | string | CSPU 的价格率档位标识；当前 ETL 中固定值为 `'80p80r'`，表示该 CSPU 归属于 80th Precision / 80th Recall 价格率模型档位 |

### 指标：订单归因指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | CSPU 维度的归因订单量；由订单分数（`order_fraction`）× ATC 归因比例（`atc_prorate`）× 首触点 Item 权重（`first_touchpoint_item`）加权求和后，按 CSPU 下属的所有 model 聚合得到；无归因数据时默认为 `0` |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 分区过滤**，否则将触发全量分区扫描，严重影响查询性能并产生高资源消耗。

```sql
-- 推荐写法
WHERE grass_region = 'ID'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_cnt` | 字段本身已经是加权归因聚合值（`order_fraction × atc_prorate × first_touchpoint_item` 的汇总），跨分区（多日/多大区）SUM 时需确认业务口径是否允许简单累加；不可跨 CSPU 做 SUM 后反推单 CSPU 值 |
| `cspu_pr_rate` | 字符串标签字段，ETL 中通过 `MAX` 聚合取值，不具备数值加总意义 |

### 时效性说明

- 本表为 **日级快照表（`_1d` 后缀）**，每日覆盖写入（`INSERT OVERWRITE`）对应大区与日期的分区。
- 数据反映的是指定 `local_date` 按大区本地时区的当日业务数据，**不包含历史累计**。
- 查询多日趋势需在应用层按 `local_date` 聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 提供 CSPU 与 Model 的关联关系及 PR Rate 档位信息，用于构建 CSPU → Model 映射 |
| `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | 提供 TC 订单明细，包含订单分数、ATC 归因比例、首触点归因权重，用于计算各 Model 维度的归因订单量 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf
        （CSPU-Model 映射 + PR Rate）
                    │
                    ▼
        [Temp View] all_cspu_model
                    │
                    │  LEFT JOIN on model_id
                    │
        [Temp View] order
                    ▲
                    │
dwd_order_item_atc_journey_di__reg_sensitive_live
        （订单归因明细，按 model_id 聚合）
                    │
                    ▼
    INSERT OVERWRITE 目标分区
dws_sr_data_warehouse_tc_pb_cspu_level_1d
        (grass_region, local_date)
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Statement 1 | Temporary View `all_cspu_model` | 从 CSPU-Model 关联维表中按大区和日期过滤，获取 `cspu_id`、`model_id` 对应关系，并固定写入 `cspu_pr_rate = '80p80r'`；以 `(cspu_id, model_id)` 去重聚合 |
| Statement 2 | Temporary View `order` | 从订单归因明细表中按大区和日期过滤（限定 `tz_type='local'` 保证本地时区口径），对 `order_model_id` 分组，计算加权归因订单量 `sum(order_fraction × atc_prorate × first_touchpoint_item)` |
| Statement 3 | INSERT OVERWRITE | 以 `all_cspu_model` 为主表，LEFT JOIN `order` 表（关联键为 `model_id`），按 `cspu_id` 聚合：`order_cnt` 取 `coalesce(sum(order_cnt), 0)`，`cspu_pr_rate` 取 `max(cspu_pr_rate)`，分区覆盖写入目标表 |

### 注意事项

- **单 Writer：** 本表仅有 1 个 ETL 文件写入，无 multi-writer 竞争风险。
- **分区覆盖写入：** 每次执行对指定 `(grass_region, local_date)` 分区执行 `INSERT OVERWRITE`，同一分区重跑安全，不会产生数据重复。
- **LEFT JOIN 保全 CSPU：** 以 CSPU-Model 映射为驱动表，保证即使当日无订单的 CSPU 也会出现在结果中，`order_cnt` 默认填 `0`，避免漏数。
- **`cspu_pr_rate` 固定值风险：** 当前 ETL 中 PR Rate 被硬编码为 `'80p80r'`，若未来档位策略变更需同步修改 ETL，否则该字段将持续输出旧值。
- **`tz_type='local'` 过滤：** 订单表按本地时区过滤，与 `local_date` 分区语义保持一致，跨时区场景需注意此过滤条件。

---

*文档生成时间：2026-05-17*