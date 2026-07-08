<!-- ads-workspace-gdoc-sync: gdoc_id=1IQcNAvOymXh3trgO4FN7b7ZGdBeB5GIYMy2q23WZ4z8 gdoc_url=https://docs.google.com/document/d/1IQcNAvOymXh3trgO4FN7b7ZGdBeB5GIYMy2q23WZ4z8/edit -->

# srdi_mart.dim_sr_data_warehouse_category_gmv_outlier

**分层：** dim（维度层）
**主键：** `grass_region` + `local_date` + `feature_group` + `is_ads` + `category_tag`
**分区：** `grass_region`、`local_date`
**更新频率：** 每日（按日期分区覆盖写入）
**访问频次：** 3,627 次

---

## 业务描述

本表用于存储各大区（`grass_region`）、各日期下，按**商品 GMV 分布**计算得到的 **99.5 百分位异常值阈值（Outlier Threshold）**，供下游搜索/推荐（SR）数仓的 GMV 指标计算在去异常值时使用。

核心业务场景：
- 在计算订单 GMV 聚合指标前，需要识别并过滤掉极端高 GMV 的异常订单，本表提供了按类目标签（`category_tag`：高 GMV 类目 / 低 GMV 类目）、场景特征组（`feature_group`）、是否广告（`is_ads`）三个维度组合下的 GMV 第 99.5 百分位数，作为截断上界。
- 支持回答的典型问题：
  - "当前大区 + 日期下，高 GMV 类目广告场景的 GMV 异常值阈值是多少？"
  - "某特征组（如某推荐场景）的 pc2_gmv 99.5 分位截断值是多少？"
  - "全场景汇总（`__ALL__`）下，低 GMV 类目的 GMV 异常值上限是多少？"

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`TH`、`VN` 等；分区写入，查询时必须指定 |
| `local_date` | date | 业务日期（本地日期）；分区写入，查询时必须指定 |

### 维度：类目与场景标签

| 字段名 | 类型 | 说明 |
|---|---|---|
| `category_tag` | string | 商品类目 GMV 等级标签，取值为 `'high gmv'`（高 GMV 类目）或 `'low gmv'`（低 GMV 类目），依据商品所属一级全球 BE 类目是否在高 GMV 类目白名单中判定 |
| `feature_group` | string | 场景特征组标签，来源于订单的 reporting 维度（business_line / module / object / algo_tag 等）展开后的 tag 字符串；特殊值 `'__ALL__'` 表示全场景汇总行 |
| `is_ads` | string | 是否为广告订单，取值为 `'true'`、`'false'`；特殊值 `'__ALL__'`（NULL 被 COALESCE 替换）表示广告与非广告的汇总行，由 CUBE 聚合生成 |

### 指标：GMV 异常值阈值

| 字段名 | 类型 | 说明 |
|---|---|---|
| `gmv_995pct` | double | 下单 GMV（`place_order_gmv`）正值部分的第 99.5 百分位近似值（`approx_percentile`），仅统计 GMV > 0 的订单；用于识别 GMV 异常高订单的截断上界 |
| `pc2_gmv_995pct` | double | PC2 口径 GMV（`pc2_gmv`）正值部分的第 99.5 百分位近似值（`approx_percentile`），仅统计 pc2_gmv > 0 的订单；与 `gmv_995pct` 口径对应 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`**，否则将触发全分区扫描，严重影响查询性能甚至读取到历史脏数据。

```sql
WHERE grass_region = 'ID'
  AND local_date = '2024-01-01'
```

- 若仅需特定场景，建议同时过滤 `feature_group`、`is_ads`、`category_tag` 以缩小扫描范围。
- `is_ads = '__ALL__'` 表示广告+非广告汇总行，`feature_group = '__ALL__'` 表示全场景汇总行，使用时需明确区分聚合粒度，避免重复计算。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `gmv_995pct` | 分位数，多行之间不可直接 SUM / AVG，无物理意义 |
| `pc2_gmv_995pct` | 同上，分位数，不可跨行加总 |

> `gmv_995pct` 和 `pc2_gmv_995pct` 是通过 `approx_percentile` 计算的近似百分位数，属于**统计汇总值**，下游应直接作为阈值参与条件过滤或比较，而非再次参与聚合运算。

### CUBE 生成的汇总行注意事项

- 本表使用 `CUBE(is_ads)` 生成多粒度聚合行，因此同一 `(grass_region, local_date, feature_group, category_tag)` 组合下存在以下两行：
  - `is_ads = 'true'` 或 `'false'`：具体广告/非广告维度
  - `is_ads = '__ALL__'`：广告+非广告合并统计
- 下游使用时需通过 `is_ads` 精确过滤，避免行重复导致指标重算。

### 时效性说明

- 本表为**每日 T+1 维度快照表**，数据反映当日订单 GMV 分布。
- 写入方式为 `INSERT OVERWRITE PARTITION`，每次执行完整覆盖对应分区，无增量累积语义。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_high_gmv_category` | 提供高 GMV 类目白名单列表，用于判定商品属于 `high gmv` 还是 `low gmv`；取最新 `update_date` 的一条记录 |
| `srdi_mart.dim_sr_data_warehouse_item` | 提供商品维度信息，关联 `item_id` 获取 `level1_global_be_category`（一级全球 BE 类目） |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供订单明细事实数据，包含 `place_order_gmv`、`pc2_gmv`、`is_ads`、reporting 维度字段等，过滤 `operation = 'order'` |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_high_gmv_category   dim_sr_data_warehouse_item
              ↓ (取最新高GMV类目白名单)              ↓ (获取商品一级类目)
         [Temp View: dim_high_gmv_cate]    [Temp View: dim_item]
                              ↘                  ↙
                    dwd_sr_data_warehouse_platform
                              ↓ (JOIN + 打标 + 构建场景tag)
                    [Temp View: dws_order]
                              ↓ (EXPLODE feature_groups + CUBE聚合 + approx_percentile)
         dim_sr_data_warehouse_category_gmv_outlier
```

### 关键步骤

**Step 1 — Temporary View `dim_high_gmv_cate`**
- 从 `srdi_mart.dim_sr_data_warehouse_high_gmv_category` 读取当前大区的高 GMV 类目配置。
- 使用 `ROW_NUMBER() OVER (PARTITION BY grass_region ORDER BY update_date DESC)` 取最新一条记录。
- 将 `category` 字符串解析为数组（`transform + split + trim + translate`），得到高 GMV 类目数组 `high_gmv_category`。

**Step 2 — Temporary View `dim_item`**
- 从 `srdi_mart.dim_sr_data_warehouse_item` 按 `grass_region` 和 `local_date` 过滤，获取 `item_id → level1_global_be_category` 映射关系。

**Step 3 — Temporary View `dws_order`**
- 以 `dwd_sr_data_warehouse_platform`（过滤 `operation = 'order'`、指定大区和日期）为主表。
- LEFT JOIN `dim_item` 获取商品一级类目；CROSS JOIN `dim_high_gmv_cate` 获取高 GMV 类目数组。
- 打标：`category_tag = if(array_contains(high_gmv_category, level1_global_be_category), 'high gmv', 'low gmv')`。
- 构建 `feature_groups` 数组（UNION ALL 两段）：
  - **第一段**：使用 `build_scenario_tags` UDF 基于 reporting_business_line / module / object / algo_tag 三路 source 展开并合并，生成多维场景 tag 数组。
  - **第二段**：强制使用 `ARRAY('__ALL__')` 代表全场景汇总行。
- 按 `is_ads`、`order_id`、`item_id`、`category_tag`、`feature_groups` 分组，SUM `place_order_gmv` 和 `pc2_gmv`。

**Step 4 — INSERT OVERWRITE（写目标表）**
- 对 `dws_order` 使用 `LATERAL VIEW EXPLODE(feature_groups) AS feature_group` 展开场景 tag。
- 使用 `CUBE(is_ads)` 生成 `is_ads` 维度的全量聚合组合（含 `__ALL__` 汇总行）。
- 计算 `approx_percentile(if(gmv>0, gmv, NULL), 0.995)` 和 `approx_percentile(if(pc2_gmv>0, pc2_gmv, NULL), 0.995)` 作为输出指标。
- 以 `INSERT OVERWRITE TABLE ... PARTITION (grass_region, local_date)` 方式写入目标分区。

### 注意事项

- **单 Writer**：本表只有一个 ETL 文件写入，无 multi-writer 风险。
- **分区覆盖写入**：每次执行将完整覆盖 `(grass_region, local_date)` 分区，重跑幂等性好，但若多个大区并发执行需确保分区隔离，避免互相覆盖。
- **近似百分位**：`approx_percentile` 为 Spark 近似算法，结果存在微小误差，不等同于精确 `percentile`，下游使用时应知晓该精度限制。
- **高 GMV 类目白名单时效性**：`dim_sr_data_warehouse_high_gmv_category` 取最新 `update_date` 记录，若当日白名单未更新则复用历史最新配置，可能导致 `category_tag` 打标与实际业务配置存在滞后。
- **`build_scenario_tags` UDF 依赖**：场景 tag 构建依赖自定义 UDF，若 UDF 版本变更可能影响 `feature_group` 的枚举值，需关注版本一致性。
- **CUBE 行膨胀**：`CUBE(is_ads)` 会使输出行数翻倍（含汇总行），下游查询时需通过 `is_ads` 精确过滤，防止指标被重复统计。

---

*文档生成时间：2026-05-17*