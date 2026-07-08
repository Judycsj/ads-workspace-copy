<!-- ads-workspace-gdoc-sync: gdoc_id=18wOZFpzP_Iw4ZRTs_HV2XjQf6arJTG90-NTmkEmmrqw gdoc_url=https://docs.google.com/document/d/18wOZFpzP_Iw4ZRTs_HV2XjQf6arJTG90-NTmkEmmrqw/edit -->

# srdi_mart.dws_sr_data_warehouse_ni_boost_item_cspu_1d

**分层：** DWS（数据汇总层）
**主键：** `item_id`（分区内唯一）
**分区：** `grass_region`（大区）/ `regional_date`（业务日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 122 次

---

## 业务描述

本表用于统计**新品（上架 90 天内的商品）**在搜索推荐场景下，通过 **CSPU（内容标准产品单元）** 维度汇聚的曝光、点击、成单数据。

核心业务场景如下：

- **新品 Boost 效果评估**：仅统计至少被一个 CSPU 覆盖的新品 item，并将其对应所有 CSPU 的流量指标加总到 item 粒度，衡量新品在 CSPU 体系下的整体曝光、点击、转化表现。
- **CSPU 覆盖率分析**：通过 INNER JOIN 过滤，仅保留有 CSPU 挂载的新品，可间接反映新品 CSPU 覆盖情况。
- **搜推 Boost 策略效果验证**：数据来源限定 `exp_tag = 'C1'`，对应特定实验标签下的流量，可用于实验组效果评估。

**适合回答的问题：**

- 某大区某天，新品中有 CSPU 覆盖的 item，其曝光/点击/成单量各是多少？
- 某 item 被多个 CSPU 覆盖时，合并后的流量指标如何？
- 新品在 CSPU Boost 策略（C1 实验标签）下的转化漏斗数据是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY、TH 等，用于多区域数据隔离 |
| `regional_date` | date | 业务日期，对应数据所属的自然日（即 ETL 参数 `local_date`） |

### 维度：商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，为分区内的统计粒度主键；仅包含上架 90 天内且至少被一个 CSPU 覆盖的新品 |

### 指标：CSPU 维度汇聚的流量指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt` | bigint | 该 item 关联的所有 CSPU 的曝光次数之和；若 CSPU 无流量数据则计为 0（`COALESCE` 处理） |
| `cspu_click_cnt` | bigint | 该 item 关联的所有 CSPU 的点击次数之和；若 CSPU 无流量数据则计为 0 |
| `cspu_order_cnt` | double | 该 item 关联的所有 CSPU 的成单数量之和；若 CSPU 无流量数据则计为 0 |

> **注意**：指标为 item 粒度的汇聚结果（先按 CSPU 聚合，再按 item 汇总），反映的是该 item 所有挂载 CSPU 的流量合计，而非 item 自身的直接曝光/点击量。

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则将触发全分区扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-01-01'
  ```
- `regional_date` 类型为 `date`，查询时注意传入正确的日期格式（`'yyyy-MM-dd'`）。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `cspu_imp_cnt` | 已是 item 粒度的预聚合指标，跨分区（多日）汇总需确认业务口径是否允许简单累加 |
| `cspu_click_cnt` | 同上 |
| `cspu_order_cnt` | 同上；类型为 `double`，跨分区求和需注意精度问题 |

- 若需计算点击率（CTR）、转化率（CVR）等比率指标，**不可**直接对比率字段求均值，需用分子/分母分别汇总后再计算。

### 时效性说明

- 本表为 **`_1d` 天级快照表**，每个分区仅保存当日数据，不做累计（`_td`）或滑窗（`_nd`）处理。
- 数据于次日（T+1）产出，不具备实时或准实时能力。
- **覆盖范围限制**：仅包含在 `regional_date` 当日，`item_create_timestamp` 距该日不足 90 天的新品，超龄商品不在本表中。
- **实验标签限制**：上游数据来源限定 `exp_tag = 'C1'`，非该实验标签下的流量不纳入统计。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，用于筛选上架 90 天内的新品 `item_id` |
| `srdi_mart.dwd_sr_data_warehouse_cspu_model_all_link_hf` | CSPU 与 item 的关联明细表，用于获取 item 到 CSPU 的映射关系 |
| `srdi_mart.dws_sr_data_warehouse_ni_boost_offline_common_1d` | 新品 Boost 离线通用汇总表，提供 item 粒度的曝光、点击、成单指标（限定 `exp_tag = 'C1'`） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_item          → [筛选新品 item_id]
                                              ↓
dwd_sr_data_warehouse_cspu_model_all_link_hf → [获取 CSPU-item 映射]
                                              ↓
dws_sr_data_warehouse_ni_boost_offline_common_1d (exp_tag='C1') → [获取 item 流量指标]
                                              ↓
                          [CSPU 粒度聚合流量] → [item 粒度汇总]
                                              ↓
          dws_sr_data_warehouse_ni_boost_item_cspu_1d（INSERT OVERWRITE）
```

### 关键步骤

1. **Statement 1 — Temporary View `all_new_item`**
   从 `dim_sr_data_warehouse_item` 中筛选当日（`local_date`）指定大区（`grass_region`）内、上架时间距当日不足 90 天的商品，得到新品 `item_id` 集合。

2. **Statement 2 — Temporary View `all_cspu_link`**
   从 `dwd_sr_data_warehouse_cspu_model_all_link_hf` 中获取当日指定大区的 CSPU 与 item 的关联关系（`cspu_id`, `item_id`），按 `cspu_id, item_id` 去重。

3. **Statement 3 — Temporary View `item_data`**
   从 `dws_sr_data_warehouse_ni_boost_offline_common_1d` 中获取 item 粒度的曝光、点击、成单数据，过滤条件为指定大区、日期，且 `exp_tag = 'C1'`。

4. **Statement 4 — Temporary View `cspu_data`**
   将 `all_cspu_link` LEFT JOIN `item_data`，按 `cspu_id` 聚合，得到每个 CSPU 的曝光、点击、成单汇总值。使用 `COALESCE(..., 0)` 保证 LEFT JOIN 后无流量的 CSPU 指标为 0 而非 NULL，语义为"已被 CSPU 覆盖但无流量时，指标视为 0"。

5. **Statement 5 — INSERT OVERWRITE（写入目标表）**
   - 将 `all_new_item` INNER JOIN `all_cspu_link`，仅保留**至少被一个 CSPU 覆盖的新品 item**（INNER JOIN 起过滤作用）。
   - 结果再 LEFT JOIN `cspu_data`，按 `item_id` 聚合，将该 item 关联的所有 CSPU 的流量指标汇总到 item 粒度。
   - 以 `INSERT OVERWRITE ... PARTITION (grass_region, regional_date)` 方式写入目标表。

### 注意事项

- **单写入源**：本表由单一 ETL 文件写入（`multi_writer = false`），无多 writer 并发冲突风险。
- **分区覆写**：每次执行采用 `INSERT OVERWRITE` 按 `(grass_region, regional_date)` 分区写入，重跑时会覆盖当日当区数据，具有幂等性。
- **INNER JOIN 过滤语义**：新品与 CSPU 关联使用 INNER JOIN，因此未被任何 CSPU 覆盖的新品 item **不会出现在本表中**，查询时需注意覆盖范围。
- **指标语义双重聚合**：流量指标经过"item → CSPU 聚合"再"CSPU → item 汇总"两次聚合，最终 `cspu_imp_cnt` 等字段代表的是 item 所挂载 CSPU 维度的流量合计，而非 item 自身直接流量，使用时需注意与其他 item 直接流量表的口径差异。
- **`exp_tag = 'C1'` 硬编码**：实验标签在 ETL 中硬编码，若实验标签变更或需纳入其他实验，需同步修改 ETL 逻辑。

---

*文档生成时间：2026-05-17*