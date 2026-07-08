<!-- ads-workspace-gdoc-sync: gdoc_id=16t10L-nAVeA3nPE7dafCOrp5v4yviuX48SVGsFFyBdM gdoc_url=https://docs.google.com/document/d/16t10L-nAVeA3nPE7dafCOrp5v4yviuX48SVGsFFyBdM/edit -->

# srdi_mart.dws_sr_data_warehouse_ni_boost_item_cspu_nd

**分层**：DWS（数据汇总层）
**主键**：`item_id`（在指定分区内唯一）
**分区**：`grass_region`（大区）、`regional_date`（业务日期）
**更新频率**：每日一次（T+1，按分区覆盖写入）
**访问频次**：1496 次

---

## 业务描述

本表为搜推数仓（SRDI）商品 CSPU 维度的近 N 天（`_nd`）汇总宽表，服务于**推荐/搜索 NI Boost 特征工程**场景。

表中记录了每个商品（`item_id`）在当前分区日期往前最多 **7 个有效数据天**内的曝光、点击、成单等核心行为累计指标，以及实际覆盖的有效天数。

**核心业务场景：**
- 为推荐/搜索 Boost 策略提供 CSPU 维度的短期行为特征；
- 评估商品近期热度与转化能力，支持商品质量分/流量调控；
- 下游特征平台按大区+日期读取，拼接到商品实时/离线特征向量中。

**适合回答的问题举例：**
- 某商品在某大区最近 7 个有覆盖天内的累计曝光 / 点击 / 成单是多少？
- 该商品近 30 天内实际有数据的天数（覆盖天数）是几天？
- 不同大区商品的短期转化率分布如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识（如 SG、MY 等），与数据生产区域对应 |
| `regional_date` | date | 业务日期分区，即数据计算基准日期（当天） |

### 维度：商品维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，为该分区内的统计主体 |

### 指标：近 7 有效天 CSPU 行为累计指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `cspu_imp_cnt_7d` | bigint | 近 7 有效天内商品 CSPU 曝光次数累计值，由日表 `cspu_imp_cnt` 求和得到 |
| `cspu_click_cnt_7d` | bigint | 近 7 有效天内商品 CSPU 点击次数累计值，由日表 `cspu_click_cnt` 求和得到 |
| `cspu_order_cnt_7d` | double | 近 7 有效天内商品 CSPU 成单数累计值，由日表 `cspu_order_cnt` 求和得到 |
| `cspu_cover_days` | int | 近 30 天内该商品实际存在数据的天数（最多取 7 天），反映数据覆盖置信度 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必同时指定 `grass_region` 和 `regional_date` 两个分区字段**，否则会触发全表扫描，影响性能并消耗大量资源：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2024-01-01'
  ```
- 若需跨日期分析，建议在分区层面限制范围而非拉取全量分区。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `cspu_cover_days` | 为"有数据天数计数"派生字段，跨 `item_id` 或跨日期叠加无业务意义，需结合具体分析场景谨慎处理 |
| `cspu_order_cnt_7d` | 类型为 `double`，跨分区（日期）累加存在重复计数风险，每个分区已是 7 天窗口的累计值 |
| `cspu_imp_cnt_7d`、`cspu_click_cnt_7d` | 同上，跨日期分区直接 SUM 会导致数据重叠计算（滑动窗口指标） |

> ⚠️ 所有 `_7d` 结尾的指标均为**滑动窗口累计值**，每日分区之间存在数据重叠，**不能跨 `regional_date` 分区直接求和**。

### 时效性说明

- 本表为 **`_nd` 后缀**的近 N 天汇总表，每日由 ETL 全量覆盖写入当日分区；
- 计算窗口为：取 `regional_date` 往前 30 天内有数据的天，**最多选取最近 7 天**（`row_number <= 7`），并非固定自然日窗口；
- `cspu_cover_days` 小于 7 时表明该商品近期数据稀疏，对应指标置信度相对较低；
- 通常在 T+1 凌晨完成当日分区写入，使用时请确认目标分区已产出。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dws_sr_data_warehouse_ni_boost_item_cspu_1d` | 商品 CSPU 每日粒度明细汇总表，提供 `cspu_imp_cnt`、`cspu_click_cnt`、`cspu_order_cnt` 等日级行为指标，作为本表聚合的原始数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_ni_boost_item_cspu_1d
    │  过滤：grass_region 匹配、regional_date 在 [local_date-29, local_date]
    │  窗口排序：按 item_id 分组，regional_date 倒序取 rn <= 7
    ▼
  中间子查询（最近 7 有效日数据）
    │  group by item_id
    │  sum(cspu_imp_cnt)   → cspu_imp_cnt_7d
    │  sum(cspu_click_cnt) → cspu_click_cnt_7d
    │  sum(cspu_order_cnt) → cspu_order_cnt_7d
    │  count(regional_date) → cspu_cover_days
    ▼
srdi_mart.dws_sr_data_warehouse_ni_boost_item_cspu_nd
    （PARTITION: grass_region = ${grass_region}, regional_date = ${local_date}）
```

### 关键步骤

1. **分区过滤**：从日表读取当前大区（`grass_region`）、近 30 天（`regional_date BETWEEN date_add(local_date, -29) AND local_date`）的全量数据；
2. **有效天排序**：使用 `ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY regional_date DESC)` 对每个商品按日期倒序编号，保留最近有数据的天次；
3. **取最近 7 有效天**：`WHERE rn <= 7`，确保在数据稀疏时仍能尽量凑够 7 天置信窗口；
4. **聚合写入**：按 `item_id` 分组，对曝光/点击/成单求和，对有效天计数，以 `INSERT OVERWRITE` 方式写入目标分区。

### 注意事项

- **单一写入器**：本表仅有 1 个 ETL 文件写入，无 multi-writer 并发风险；
- **INSERT OVERWRITE 覆盖写入**：每次执行会覆盖目标大区+日期分区，重跑安全，但需避免同一分区并发执行；
- **30 天候选窗口 vs. 7 天有效窗口**：先从 30 天候选范围内按时间倒序选最近 7 天，非固定自然日 7 天，日表中缺失的日期不会被计入（跳过），`cspu_cover_days` 可用于判断实际覆盖情况；
- **`cspu_order_cnt_7d` 为 double 类型**：源自日表中可能存在分数级别订单（如部分归因），下游使用时注意精度处理。

---

*文档生成时间：2026-05-17*