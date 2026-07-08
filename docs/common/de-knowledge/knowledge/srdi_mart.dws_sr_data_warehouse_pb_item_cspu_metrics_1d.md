<!-- ads-workspace-gdoc-sync: gdoc_id=18lx-6V3ylwW2bWeIqNedjqUboxy4b6RUVG-VSoSAGxw gdoc_url=https://docs.google.com/document/d/18lx-6V3ylwW2bWeIqNedjqUboxy4b6RUVG-VSoSAGxw/edit -->

# srdi_mart.dws_sr_data_warehouse_pb_item_cspu_metrics_1d

**分层：** DWS（数据服务层）
**主键：** `item_id` + `mapping_general` + `grass_region` + `local_date`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 122 次

---

## 业务描述

本表为搜推数仓（SRDI）PB（推荐/搜索）场景下，商品（item）维度按 CSPU（同款商品集合）聚合的日粒度宽表。

核心业务场景：
- **CSPU 竞争分析**：同一 CSPU 下，某 item 与其他同款商品之间的流量竞争关系分析。每条记录代表某个 item 在某个 CSPU 映射分组下，自身的展现/点击/成交指标，以及同 CSPU 内所有商品（含/不含自身）的汇总指标。
- **同款流量归因**：用于衡量某商品在同款竞争格局中的份额，如计算 item 自身指标占 CSPU 整体的比例。
- **广告与自然流量对比**：通过 `cspu_exclude_self_ads_*` 系列字段区分广告流量与全量流量，支持广告效果评估。

适合回答的典型问题：
- 某商品在某天的展现量、点击量、成交量是多少？
- 与同款商品相比，该商品占 CSPU 整体流量的份额是多少？
- 去除自身后，同 CSPU 其他商品（自然流量 / 广告流量）的汇总表现如何？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域标识，如 ID、MY 等，用于数据分区隔离 |
| `local_date` | date | 业务日期（本地时区），数据统计口径的自然日 |

### 维度：商品与 CSPU 映射

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，为分析主体 |
| `mapping_general` | string | CSPU 映射分组标识，标记同款商品的归属分组；上游保证该字段不为 null，用作自关联键之一 |

### 指标：item 自身指标

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt` | bigint | item 自身在当日的总展现次数（取自上游，去重后取 max） |
| `item_click_cnt` | bigint | item 自身在当日的总点击次数（取自上游，去重后取 max） |
| `item_order_cnt` | double | item 自身在当日的总成交单量（取自上游，去重后取 max） |

### 指标：CSPU 全量汇总指标（含 item 自身）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt` | bigint | 同 CSPU 下所有商品（含 item 自身）的展现次数之和；同款商品在不同 cspu_id 下重复出现时已做去重 |
| `cspu_click_cnt` | bigint | 同 CSPU 下所有商品（含 item 自身）的点击次数之和；同上去重逻辑 |
| `cspu_order_cnt` | double | 同 CSPU 下所有商品（含 item 自身）的成交单量之和；同上去重逻辑 |

### 指标：CSPU 排除自身后的全量指标

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_exclude_self_imp_cnt` | bigint | 同 CSPU 下排除 item 自身后，其他商品的展现次数之和（全量流量，含广告） |
| `cspu_exclude_self_click_cnt` | bigint | 同 CSPU 下排除 item 自身后，其他商品的点击次数之和（全量流量，含广告） |
| `cspu_exclude_self_order_cnt` | double | 同 CSPU 下排除 item 自身后，其他商品的成交单量之和（全量流量，含广告） |

### 指标：CSPU 排除自身后的自然流量指标（去广告）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_exclude_self_ads_imp_cnt` | bigint | 同 CSPU 下排除 item 自身后，其他商品的自然流量展现次数之和（对应上游 `org_imp_cnt`，即去除广告后的展现） |
| `cspu_exclude_self_ads_click_cnt` | bigint | 同 CSPU 下排除 item 自身后，其他商品的自然流量点击次数之和（对应上游 `org_click_cnt`） |
| `cspu_exclude_self_ads_order_cnt` | double | 同 CSPU 下排除 item 自身后，其他商品的自然流量成交单量之和（对应上游 `org_order_cnt`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（必须）**：查询时务必同时指定 `grass_region` 和 `local_date`，避免全表扫描。例如：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-01-01'
  ```
- 如需多日分析，建议使用 `local_date BETWEEN ... AND ...`，并明确 `grass_region`。

### 不可直接跨行 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_imp_cnt` / `item_click_cnt` / `item_order_cnt` | item 自身指标经过两次 `MAX` 去重，跨 `mapping_general` 直接 SUM 会导致重复计数 |
| `cspu_imp_cnt` / `cspu_click_cnt` / `cspu_order_cnt` | 同款商品可能映射到多个 `mapping_general` 分组，跨 `mapping_general` SUM 同样存在重复 |
| `cspu_exclude_self_*` 系列 | 同上，均为预聚合派生指标，跨分组求和无业务意义且会重复 |

> ⚠️ 如需汇总某 `item_id` 的整体指标，建议先确认其 `mapping_general` 是否唯一，再决定是否可以 SUM；通常应在单一 `(item_id, mapping_general)` 粒度下使用本表指标。

### 时效性说明

- 本表为 **T+1 日更新**，每日写入前一业务日数据，`local_date` 为统计自然日（本地时区）。
- 分区采用 `INSERT OVERWRITE` 写入，每次刷新覆盖对应 `(grass_region, local_date)` 分区，数据可重跑幂等。
- 本表无近 N 天滚动窗口，如需多日趋势，需自行在查询层对 `local_date` 进行聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_pb_itemcspu_1d` | 提供 item 维度的 cspu_id、展现/点击/成交（全量及自然流量）等基础日粒度指标，是本表唯一直接上游 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_pb_itemcspu_1d
        │  过滤指定 grass_region + local_date
        ▼
  base_view（临时视图）
        │  以 cspu_id + mapping_general 做自关联（笛卡尔积展开同款商品）
        ▼
  self_join_view（临时视图）
        │  两层聚合去重 + 条件求和（排除自身 / 区分广告流量）
        ▼
  srdi_mart.dws_sr_data_warehouse_pb_item_cspu_metrics_1d
       （INSERT OVERWRITE 目标分区）
```

### 关键步骤

**Step 1 — 创建基础临时视图 `base_${grass_region_without_quote}`**
- 从上游表 `dws_sr_data_warehouse_pb_itemcspu_1d` 过滤当日、当区数据，保留所有字段。

**Step 2 — 创建自关联临时视图 `self_join_${grass_region_without_quote}`**
- 对基础视图进行**自关联**（LEFT JOIN），关联键为 `cspu_id` + `mapping_general`。
- 关联结果：每个 item（a）与同 CSPU 下所有 item（b，含自身）做笛卡尔积展开，形成 `(item_id, same_cspu_item_id)` 行对。
- 注：一个 `item_id` 可能因覆盖多个 `cspu_id` 而在多行出现，此处通过 `GROUP BY` 做初步聚合。

**Step 3 — INSERT OVERWRITE 写目标表（两层聚合去重）**
- **内层聚合**（`GROUP BY item_id, same_cspu_item_id, mapping_general`）：
  - item 自身指标取 `MAX`（第一次去重：同款商品在不同 `cspu_id` 下重复相遇时消除冗余）。
  - 同 CSPU 伙伴商品指标也取 `MAX`（消除同样原因导致的重复）。
- **外层聚合**（`GROUP BY item_id, mapping_general`）：
  - item 自身指标再取 `MAX`（第二次去重：消除因笛卡尔积展开引入的行冗余）。
  - CSPU 全量指标取 `SUM`（汇总同 CSPU 下所有伙伴商品）。
  - `cspu_exclude_self_*`：通过 `IF(item_id = same_cspu_item_id, 0, cspu_*_cnt)` 排除 item 自身贡献后 SUM。
  - `cspu_exclude_self_ads_*`：同逻辑但使用上游 `org_*` 字段（自然流量口径，去广告）。

### 注意事项

1. **双重去重必要性**：上游 item 可能映射多个 `cspu_id`，导致自关联后同一 `(item_id, same_cspu_item_id)` 在不同 `cspu_id` 下重复出现，ETL 通过两层 `MAX` + `SUM` 消除重复，业务侧不应在本表外再对 item 指标做简单 SUM。
2. **`mapping_general` 不为 null**：上游已保证该字段不出现 null，关联键有效性由上游负责，本表无额外兜底逻辑。
3. **分区写入幂等**：采用 `INSERT OVERWRITE PARTITION (grass_region, local_date)`，支持按分区重跑，不影响其他分区数据。
4. **single writer**：本表仅有一个 ETL 文件写入，无多 writer 冲突风险。
5. **`ads` 系列字段命名歧义**：字段名含 `ads` 实际含义为**去广告后的自然流量**（对应上游 `org_*` 字段），并非广告流量本身，使用时注意区分。

---

*文档生成时间：2026-05-17*