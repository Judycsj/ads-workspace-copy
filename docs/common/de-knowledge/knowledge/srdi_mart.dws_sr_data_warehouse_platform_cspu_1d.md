<!-- ads-workspace-gdoc-sync: gdoc_id=1kFismrviPOSTIMhWbWl3-cdwanCZkgfchUsHJtzVtoQ gdoc_url=https://docs.google.com/document/d/1kFismrviPOSTIMhWbWl3-cdwanCZkgfchUsHJtzVtoQ/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_cspu_1d

**分层：** DWS（数据汇总层）
**主键：** `cspu_id`（在分区 `grass_region` + `local_date` 内唯一）
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1 批量覆写）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表以 **CSPU（Component SPU，组件级标准产品单元）** 为粒度，汇总搜索推荐数据仓库平台在各大区单日的核心行为指标，包括曝光次数、点击次数与订单数。

**核心业务场景：**
- 评估各大区各 CSPU 的每日曝光、点击及转化表现；
- 支持搜推效果分析，如 CTR（点击率）、CVR（转化率）的上层计算；
- 作为搜推 DWS 层宽表，为下游 ADS 层报表和策略分析提供标准化汇总数据。

**适合回答的典型问题：**
- 某大区某天某 CSPU 的曝光量、点击量和订单数分别是多少？
- 各 CSPU 在不同大区的每日流量及转化情况如何？
- 哪些 CSPU 在指定日期的订单贡献最高？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 ID、MY、TH 等，用于数据分区隔离 |
| `local_date` | date | 业务日期（本地时区），数据统计所属自然日 |

### 维度：CSPU 标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（Component SPU）的唯一标识，为本表最细粒度的分析维度 |

### 指标：搜推行为汇总指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 当日曝光次数；通过 CSPU → item_id 映射后，对 `dwd_sr_data_warehouse_platform` 中 `operation='impression'` 的记录按 CSPU 汇总求和 |
| `click_cnt` | bigint | 当日点击次数；通过 CSPU → item_id 映射后，对 `dwd_sr_data_warehouse_platform` 中 `operation='click'` 的记录按 CSPU 汇总求和 |
| `order_cnt` | double | 当日订单数；通过 CSPU → model_id 映射后，对 `dwd_sr_data_warehouse_platform` 中 `operation='order'` 的记录按 CSPU 汇总求和 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将跨大区全量扫描，性能极差且可能返回混合大区数据。
- **`local_date`**：必须指定，本表为每日分区表，不限定日期将导致全量历史扫描。

```sql
-- 推荐写法
WHERE grass_region = 'ID'
  AND local_date = '2025-05-17'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt`、`click_cnt`、`order_cnt` | 字段本身已是 CSPU 粒度的日汇总值，跨多日 SUM 时需确认业务语义；跨大区 SUM 通常无意义，应按 `grass_region` 分组 |
| CTR / CVR 等比率 | 本表未存储比率字段，需用 `click_cnt / imp_cnt` 等手动计算；**不可对多行比率直接求均值** |

> ⚠️ `order_cnt` 类型为 `double`，来源于对 `operation_cnt` 的 `SUM` 聚合，数值通常为整数，但比较时注意浮点精度问题，避免使用 `=` 精确匹配。

### 时效性说明

- 本表为 **每日快照（`_1d` 后缀）**，每次写入使用 `INSERT OVERWRITE` 按分区覆盖，仅反映单日数据。
- 无滚动窗口语义（不是 `_nd` / `_td`），如需多日趋势需在查询层自行聚合多个 `local_date` 分区。
- 数据通常在 T+1 产出，不反映实时或准实时数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | CSPU 维度关联表，提供 `cspu_id → model_id → item_id` 的映射关系 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜推平台行为明细表（DWD 层），提供 `impression`、`click`、`order` 等操作的明细记录，包含 `item_id`、`model_id`、`operation`、`operation_cnt` 等字段 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf   ──┐
                                                        ├──► all_cspu_model (tmp view)
dwd_sr_data_warehouse_platform (impression/click)    ──► civ_data (tmp view)    ──┐
                                                                                   ├──► INSERT OVERWRITE
dwd_sr_data_warehouse_platform (order)               ──► order_data (tmp view)  ──┘
                                                          dws_sr_data_warehouse_platform_cspu_1d
```

### 关键步骤

1. **Statement 1 — 临时视图 `all_cspu_model`**
   - 从 CSPU 维度表中按 `grass_region` 和 `local_date` 过滤，获取当日 `cspu_id`、`model_id`、`item_id` 三者的关联关系（按三字段 GROUP BY 去重）。

2. **Statement 2 — 临时视图 `civ_data`**
   - 从 DWD 行为明细表中过滤 `operation IN ('impression', 'click')`，按 `item_id` 汇总得到每个 item 的曝光数 `imp_cnt` 和点击数 `click_cnt`。

3. **Statement 3 — 临时视图 `order_data`**
   - 从 DWD 行为明细表中过滤 `operation = 'order'`，按 `model_id` 汇总得到每个 model 的订单数 `order_cnt`。

4. **Statement 4 — INSERT OVERWRITE 写目标表**
   - 通过 UNION ALL 将两路数据合并后，按 `cspu_id` 汇总：
     - **订单路径**：`all_cspu_model` LEFT JOIN `order_data`（on `model_id`），按 `cspu_id` 聚合 `order_cnt`，曝光/点击置 0；
     - **曝光点击路径**：`all_cspu_model`（先对 `cspu_id + item_id` 去重）LEFT JOIN `civ_data`（on `item_id`），按 `cspu_id` 聚合 `imp_cnt` 和 `click_cnt`，订单置 0；
   - 最终对 UNION ALL 结果再次按 `cspu_id` SUM，得到每个 CSPU 汇总后的三项指标。
   - 以 `INSERT OVERWRITE ... PARTITION (grass_region, local_date)` 形式覆写目标分区。

### 注意事项

- **LEFT JOIN 语义**：两路均使用 LEFT JOIN，未匹配到行为数据的 CSPU 仍会出现在结果中，对应指标为 0（而非 NULL）。
- **item_id 去重**：曝光点击路径在 JOIN 前先对 `cspu_id + item_id` 去重（内层 GROUP BY），避免同一 item 被多个 model 映射导致重复计数。
- **model_id 多对多**：一个 `cspu_id` 可关联多个 `model_id`，订单路径对 `model_id` 维度的汇总结果再按 `cspu_id` 聚合，需注意上游维度表数据质量（重复关联可能导致虚增）。
- **分区覆写**：使用 `INSERT OVERWRITE PARTITION`，每次执行会完整替换对应 `(grass_region, local_date)` 分区数据，重跑安全，无多写风险（`multi_writer = false`）。
- **`${schema}` 参数化**：目标表 schema 通过变量注入，部署时需确认变量值与物理表 schema 一致。

---

*文档生成时间：2026-05-18*