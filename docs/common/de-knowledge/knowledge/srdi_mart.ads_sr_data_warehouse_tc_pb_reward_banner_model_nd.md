<!-- ads-workspace-gdoc-sync: gdoc_id=1WUspbciHnC3DuKHWs7MQhjN2ZMUglmIOBOZ0n6nc7LE gdoc_url=https://docs.google.com/document/d/1WUspbciHnC3DuKHWs7MQhjN2ZMUglmIOBOZ0n6nc7LE/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_reward_banner_model_nd

**分层：** ADS（应用数据层）
**主键：** `local_date` + `grass_region` + `shop_id` + `model_id` + `data_range`
**分区：** `local_date`（日期）、`grass_region`（站点/大区）
**更新频率：** 每日一次，按分区覆盖写入
**引用频次 / 访问频次：** 317

---

## 业务描述

本表面向 TC（Top Creator / 顶级内容营销）品牌付费（PB）激励横幅（Reward Banner）模型效果分析场景，记录各店铺下每个推荐模型在多个回溯时间窗口（1d / 7d / 30d / 90d / 180d / 365d）内的曝光、订单及 GMV 累计汇总，并为每个店铺 × 时间窗口维度按曝光量降序生成模型排名与分页信息。

**核心业务场景：**
- 评估不同推荐模型在激励横幅位置的短期与长期表现；
- 为运营提供各店铺模型排行榜，支持按时间窗口选取最优模型；
- 支持分页展示，便于前端或报表产品加载各店铺的模型排序列表。

**适合回答的问题举例：**
- 某店铺过去 30 天哪个推荐模型的曝光量最高？
- 某站点各店铺模型在 7 天窗口下的 GMV 排名如何？
- 某模型在不同时间窗口下的订单转化趋势？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据统计基准日期（分区键），对应 ETL 执行日期 `${local_date}` |
| `grass_region` | string | 站点 / 大区标识（分区键），如 ID、MY、TH 等 |

### 维度：店铺与模型标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `model_id` | bigint | 推荐模型 ID，标识激励横幅所使用的具体模型 |
| `data_range` | string | 统计时间窗口，取值为 `'1d'`、`'7d'`、`'30d'`、`'90d'`、`'180d'`、`'365d'` |

### 指标：排名与分页

| 字段 | 类型 | 说明 |
|---|---|---|
| `rank_num` | bigint | 模型在同一店铺 × 时间窗口内，按曝光量（`imp_cnt_nd`）降序的排名；曝光量相同时按 `model_id` 降序决定顺序；由 `ROW_NUMBER()` 窗口函数生成 |
| `page_num` | bigint | 基于 `rank_num` 的分页编号，每页 10 条，由 `CEIL(rank_num / 10)` 计算得出 |

### 指标：核心业务指标（多时间窗口累计）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_nd` | bigint | 对应 `data_range` 时间窗口内的累计曝光次数（SUM 自 DWS 层日粒度数据） |
| `order_cnt_nd` | bigint | 对应 `data_range` 时间窗口内的累计订单数（SUM 自 DWS 层日粒度数据） |
| `gmv_nd` | double | 对应 `data_range` 时间窗口内的累计 GMV（SUM 自 DWS 层日粒度数据） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则全分区扫描代价极高。通常取最新日期：
  ```sql
  WHERE local_date = '2024-xx-xx'
  ```
- **`grass_region`**：建议同时指定，避免跨站点混合计算：
  ```sql
  AND grass_region = 'ID'
  ```
- **`data_range`**：分析时需明确指定时间窗口，否则同一模型将出现 6 条重复记录（对应 6 个时间窗口），导致指标虚高：
  ```sql
  AND data_range = '7d'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `rank_num` | 窗口函数派生的排名值，对多行求和无业务意义 |
| `page_num` | 由 `rank_num` 计算的分页编号，不可聚合 |
| `imp_cnt_nd` / `order_cnt_nd` / `gmv_nd` | 已是对应时间窗口的预聚合累计值；若跨 `data_range` 行进行 SUM，将导致重复计算（各窗口数据有时间重叠） |

### 时效性说明

- 本表为 `*_nd`（N-day 多窗口）表，每天全量覆盖写入当日分区，历史分区不再更新。
- 数据通常于每日 ETL 完成后可用，时效性为 **T+1**（以上游 DWS 层就绪时间为准）。
- 各 `data_range` 窗口均以当日（`local_date`）为终点向前回溯，时间范围完全依赖当日执行结果，不支持任意历史区间的滚动重算（历史分区不重写）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_reward_banner_model_1d` | 提供每日粒度的店铺 × 模型曝光、订单、GMV 明细，作为多时间窗口累计计算的基础数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_reward_banner_model_1d
  └─ [base_data_view] 过滤近 365 天数据
       └─ [period_data_view] UNION ALL 6 个时间窗口（1d/7d/30d/90d/180d/365d）聚合
            └─ 窗口函数生成 rank_num、page_num
                 └─ INSERT OVERWRITE → ads_sr_data_warehouse_tc_pb_reward_banner_model_nd
```

### 关键步骤

**Step 1 — 临时视图 `base_data_view`**

从 DWS 层日粒度表中读取 `local_date` 在 `[local_date - 364, local_date]` 范围内的数据，保留 `shop_id`、`model_id`、`imp_cnt`、`order_cnt`、`gmv`、`local_date`、`grass_region` 字段，作为后续多窗口聚合的数据底座。

**Step 2 — 临时视图 `period_data_view`**

对 `base_data_view` 按以下 6 个时间窗口分别执行 `GROUP BY shop_id, model_id, grass_region` 的 SUM 聚合，并通过 `UNION ALL` 合并：

| data_range | 时间范围 |
|---|---|
| `1d` | `local_date` 单天 |
| `7d` | `[local_date - 6, local_date]` |
| `30d` | `[local_date - 29, local_date]` |
| `90d` | `[local_date - 89, local_date]` |
| `180d` | `[local_date - 179, local_date]` |
| `365d` | `[local_date - 364, local_date]` |

每行同时携带 `local_date`（固定为当前执行日期）和 `data_range` 标识。

**Step 3 — INSERT OVERWRITE 写目标分区**

从 `period_data_view` 中选取全部字段，并通过以下两个窗口函数追加排名与分页信息：
- `ROW_NUMBER() OVER(PARTITION BY shop_id, data_range ORDER BY imp_cnt_nd DESC, model_id DESC)` → `rank_num`
- `CEIL(rank_num / 10)` → `page_num`

以 `INSERT OVERWRITE ... PARTITION(local_date = ${local_date}, grass_region = ${grass_region})` 方式写入目标表指定分区。

### 注意事项

- **单文件写入，无 multi-writer 问题**：本表仅有 1 个 ETL 文件，分区写入不存在并发竞争风险。
- **分区覆盖写入**：每次执行对 `local_date` + `grass_region` 组合分区做全量覆盖（`INSERT OVERWRITE`），重跑幂等安全。
- **上游数据完整性依赖**：`base_data_view` 一次性读取近 365 天数据，若 DWS 层历史分区存在缺失或延迟，将影响较长窗口（90d/180d/365d）的准确性。
- **窗口函数排名跳出风险**：`ROW_NUMBER()` 不产生并列排名，曝光量相同时由 `model_id DESC` 决定顺序，消费端需注意排名连续性。
- **`page_num` 依赖 `rank_num` 计算**：ETL 中 `page_num` 使用嵌套 `ROW_NUMBER()` 表达式（即 `CEIL(ROW_NUMBER().../ 10)`），并非引用已命名列，需注意 SQL 引擎对此表达式的求值一致性。

---

*文档生成时间：2026-05-17*