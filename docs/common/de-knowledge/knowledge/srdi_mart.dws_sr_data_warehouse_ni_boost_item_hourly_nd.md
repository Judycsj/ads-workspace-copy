<!-- ads-workspace-gdoc-sync: gdoc_id=1T3qvryUT43BJ8qBAdgPdzDjpuxqTbtF6lrGa4yx_Lac gdoc_url=https://docs.google.com/document/d/1T3qvryUT43BJ8qBAdgPdzDjpuxqTbtF6lrGa4yx_Lac/edit -->

# srdi_mart.dws_sr_data_warehouse_ni_boost_item_hourly_nd

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `exp_tag` + `item_id`
**分区：** `grass_region`（站点大区）/ `regional_date`（业务日期）/ `regional_hour`（业务小时）
**更新频率：** 小时级（每小时覆写对应分区）
**引用频次 / 访问频次：** 5783

---

## 业务描述

本表面向搜推**新商品（New Item）Boost 策略**，以**商品 × 实验桶 × 小时**为粒度，汇总当前时刻可用的新商品在 Explore（发现/推荐）场景下的全链路曝光、点击和成单数据，同时携带全平台总体曝光量，供策略评估与实时监控使用。

**核心业务场景：**
- 新商品 Boost 效果的小时级近实时监控（上线后 90 个自然日内持续追踪）
- 实验桶（`exp_tag`）维度的 Boost 策略 A/B 对比分析
- 拼接离线最大可用分区与实时增量数据，实现"离线 + 实时"无缝衔接，降低数据延迟

**适合回答的问题：**
- 当前小时内，各站点新商品在 Explore 场景的曝光/点击/成单情况如何？
- 指定实验桶下，某商品的 Boost 效果是否达到预期？
- 新商品从上线到第 90 天内，各小时的流量趋势如何变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 SG、MY 等），写入时由 ETL 参数 `${grass_region}` 注入 |
| `regional_date` | date | 业务日期（按区域本地时间），对应 ETL 调度的目标日期分区 |
| `regional_hour` | int | 业务小时（0–23），对应 ETL 调度的目标小时分区 |

### 维度：商品与实验信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，来自新商品 Pool（上线后 90 个自然日内） |
| `exp_tag` | string | 实验桶标识（如 `T1`），标识该商品所属的 Boost 策略实验组；只保留 `T%` 开头的策略桶 |
| `create_time` | bigint | 商品创建时间戳（Unix 秒），来源于 `dim_sr_data_warehouse_item.item_create_timestamp` |

### 指标：曝光、点击与成单

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_imp_cnt` | bigint | 全平台累计曝光次数（不区分实验桶，由实时增量数据按 `item_id` 汇总后与离线数据加和得到） |
| `explore_imp_cnt` | bigint | Explore 场景下指定实验桶的曝光次数（离线 + 实时合并累计） |
| `explore_click_cnt` | bigint | Explore 场景下指定实验桶的点击次数（离线 + 实时合并累计） |
| `explore_order_cnt` | double | Explore 场景下指定实验桶的成单数（离线 + 实时合并累计；double 类型以支持加权/归因结果） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段过滤不可省略**，至少需指定 `grass_region` 和 `regional_date`，以避免全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-01-01'
    AND regional_hour = 10  -- 按需指定；如需当天最新数据，取 max(regional_hour)
  ```
- `regional_date` 为 `date` 类型，请使用日期字面量（如 `DATE '2025-01-01'`）或正确格式的字符串，避免隐式转换。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `platform_imp_cnt` | 为**预聚合**的全平台曝光数，跨多个 `regional_hour` 或多个 `exp_tag` 直接 SUM 会产生重复计数 |
| `explore_imp_cnt` / `explore_click_cnt` / `explore_order_cnt` | 均为离线 + 实时**合并累计值**，跨小时直接 SUM 存在重叠，应取最新小时分区的值代表当日截至该时刻的累计量 |
| 点击率 / 转化率等派生比率 | 需用 `explore_click_cnt / explore_imp_cnt` 等方式在查询层计算，不可对比率类结果再次聚合 |

### 时效性说明

- 本表为**小时级近实时表**（`_hourly_nd` 后缀），每小时覆写（`INSERT OVERWRITE`）对应分区。
- 指标值为**从离线最大可用分区起点到当前小时的累计值**，并非当小时增量。
- 新商品窗口为**上线后 90 个自然日内**（基于 `item_create_timestamp` 按东八区自然日计算），第 91 天起商品不再出现在本表。
- `_nd` 后缀含义：数据为近实时（Near-realtime + Daily offset）拼合窗口，非单日快照；**取最新 `regional_hour` 分区即为当日最新累计**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_item` | 获取新商品 Pool：筛选 90 日内创建的商品及其创建时间戳，作为本表的商品维度基础 |
| `srdi_mart.dws_sr_data_warehouse_ni_boost_explore_item_nd` | 离线历史基准数据：取离线最大可用分区的 Explore 场景各指标，作为累计基线 |
| `paimon.srdi_mart.dws_sr_data_warehouse_ni_boost_item_realtime_1d` | 实时增量数据：补充离线最大可用分区之后、到当前时刻之间的 Explore 场景增量指标 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_item         → all_new_item（新商品 Pool，90日内）
                                                          ↘
dws_ni_boost_explore_item_nd       → offline_data          → merged_data → INSERT OVERWRITE 目标表
                                                          ↗
dws_ni_boost_item_realtime_1d      → realtime_raw → realtime_data
```

### 关键步骤

1. **Step 1 — `all_new_item`（Temporary View）**
   从 `dim_sr_data_warehouse_item` 读取维度表最新可用分区，过滤出上线 90 日内的新商品，并 explode 赋予实验桶标签 `T1`，形成新商品 Pool。

2. **Step 2 — `offline_data`（Temporary View）**
   从离线汇总表 `dws_sr_data_warehouse_ni_boost_explore_item_nd` 读取**严格小于目标日期的最大分区**，取出各实验桶的全量指标作为离线基线。

3. **Step 3 — `realtime_raw`（Temporary View）**
   从 Paimon 实时表读取**离线最大分区之后、到目标日期之间**的所有日期增量数据，实现与离线的无缝衔接（不支持天内 backfill，下游取最新可用分区）。

4. **Step 4 — `realtime_data`（Temporary View）**
   对 `realtime_raw` 进行二次加工：
   - 过滤保留 `exp_tag LIKE 'T%'` 的策略桶数据；
   - 通过自关联按 `item_id` 聚合所有桶的 `explore_imp_cnt` 得到 `platform_imp_cnt`（全平台曝光）；
   - Left join 补充 `platform_imp_cnt` 字段。

5. **Step 5 — `merged_data`（Temporary View）**
   将 `offline_data` 与 `realtime_data` 通过 `UNION ALL` 合并后，按 `(exp_tag, item_id)` 分组 SUM，得到离线 + 实时的完整累计指标。

6. **Step 6 — INSERT OVERWRITE（写目标表）**
   以 `all_new_item`（新商品 Pool）为驱动，Left join `merged_data` 补充指标，写入目标表指定的 `(grass_region, regional_date, regional_hour)` 分区。新商品 Pool 中未命中指标的商品，指标字段写入 NULL。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 并发冲突风险。
- **分区覆写**：每次执行为 `INSERT OVERWRITE` 指定单一 `(grass_region, regional_date, regional_hour)` 三级分区，不影响其他分区数据。
- **离线基线分区选取**：两处均使用 `max_pt(..., "regional_date<${regional_date}")` 确保不读取当天离线分区（当天离线尚未产出），与实时数据的左边界严格对齐，避免重复计算。
- **`platform_imp_cnt` 拼凑逻辑**：实时部分的 `platform_imp_cnt` 是通过对实时原始数据按 `item_id` 跨桶 SUM 推算的，并非真实全平台曝光上报值；离线部分则直接来自上游离线表，两者语义需注意区分。
- **新商品窗口边界**：`datediff < 90` 基于东八区自然日，第 91 天首个小时起商品将从 Pool 中消失，对应小时分区不再产出该商品记录。

---

*文档生成时间：2026-05-17*