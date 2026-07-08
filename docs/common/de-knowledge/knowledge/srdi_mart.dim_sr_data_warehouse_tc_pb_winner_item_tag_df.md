<!-- ads-workspace-gdoc-sync: gdoc_id=1i6EU2vEo2EQVymQ4B5zsoTNXtY8c7Fg45ME3Mhhh9yA gdoc_url=https://docs.google.com/document/d/1i6EU2vEo2EQVymQ4B5zsoTNXtY8c7Fg45ME3Mhhh9yA/edit -->

# srdi_mart.dim_sr_data_warehouse_tc_pb_winner_item_tag_df

**分层：** dim（维度层）
**主键：** `item_id` + `shop_id`（分区内唯一）
**分区：** `grass_region`（站点/区域），`local_date`（业务日期）
**更新频率：** 每日（Daily，按分区 INSERT OVERWRITE 全量覆写）
**引用频次/访问频次：** 3

---

## 业务描述

本表用于标记"TC 竞价（Price Beating / PB）获胜商品"的维度标签，记录在指定区域和日期下，满足 **PB 获胜质量门槛** 的商品（`item_id`）及其所属店铺（`shop_id`）。

**核心业务场景：**
- 识别在竞价场景中持续获胜（连续 3 天全天获胜）且具备一定订单体量的优质 PB 商品，为后续推荐、搜索排序或运营策略提供打标数据。
- 作为维度快照表，下游可通过 JOIN 快速筛选出当日符合 PB 获胜条件的商品集合。

**适合回答的问题：**
- 某区域某日有哪些商品/店铺满足 PB 获胜条件？
- 哪些 `item_id` 在近 3 天内每天均为竞价获胜日，且订单占比或日均订单量达标？
- 某店铺下有哪些商品被打上了 PB Winner 标签？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `PH`、`TH`、`VN` 等，ETL 按区域分区写入 |
| `local_date` | date | 业务日期（本地时间），数据覆盖截止该日期的近 30 天窗口 |

### 维度：PB 获胜商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，PB 获胜商品的唯一标识 |
| `shop_id` | bigint | 店铺 ID，商品所属店铺 |

---

## 查询使用须知

1. **必须过滤分区字段**：查询时务必同时指定 `grass_region` 和 `local_date`，否则将触发全表扫描，影响性能且可能产生跨区域/跨日期数据混用：
   ```sql
   WHERE grass_region = 'PH'
     AND local_date = '2024-01-01'
   ```

2. **表仅记录满足门槛的商品**：本表为 **白名单快照**，未出现在当日分区的商品即表示未通过 PB 获胜门槛，下游 JOIN 时应注意 INNER JOIN 与 LEFT JOIN 语义的差异。

3. **主键说明**：同一分区内 `(item_id, shop_id)` 为唯一组合（ETL 最终以 `GROUP BY item_id, shop_id` 去重），但单个 `item_id` 在极端场景下理论上可能关联多个 `shop_id`（如商品被多店铺关联），使用时需关注业务场景是否需要进一步限定 `shop_id`。

4. **不可直接 COUNT/SUM 跨分区数据做趋势分析**：本表每日分区为全量覆写快照，跨日期的商品数量趋势分析需按 `local_date` 分组统计，不可将多日分区数据简单堆叠后 COUNT DISTINCT。

5. **时效性**：本表为 T+1 日更新，`local_date` 对应的分区在次日 ETL 完成后可用，不反映当日实时状态。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_winner_order_1d` | 提供近 30 天各 CSPU/Model/Item 的竞价获胜状态（`is_win_day`）及订单量（`order_cnt`），用于计算连续获胜模型、商品订单占比和 CSPU 日均订单量 |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 提供 CSPU → Model → Item → Shop 的关联映射关系，取当日最新小时分区数据，用于将模型维度标签下推到商品和店铺粒度 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_tc_pb_winner_order_1d  (近30天流量/订单数据)
    │
    ├──► win_3d_models        (过滤近3天每天均为获胜日的 model_id)
    ├──► item_order           (汇总商品近30天总订单及获胜订单)
    └──► cspu_ado             (汇总 CSPU 近30天日均订单量)
                                        │
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf  (CSPU-Model-Item-Shop映射)
    │
    └──► all_cspu_model       (取当日最新小时快照)
                                        │
                          INNER JOIN win_3d_models (仅保留连续3天获胜的 model)
                          LEFT JOIN item_order     (补充商品订单指标)
                          LEFT JOIN cspu_ado       (补充 CSPU 日均订单指标)
                                        │
                              质量门槛过滤 & GROUP BY item_id, shop_id
                                        │
                    INSERT OVERWRITE dim_sr_data_warehouse_tc_pb_winner_item_tag_df
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `l30d_traffic` | 从 `dws_sr_data_warehouse_tc_pb_winner_order_1d` 提取当日起近 30 天（`date_sub(local_date, 29)` 至 `local_date`）的流量与订单数据，按指定区域过滤 |
| 2 | `win_3d_models` | 在近 30 天数据中进一步筛选最近 3 天（`date_sub(local_date, 2)` 至 `local_date`），按 `model_id` + `local_date` 聚合后，仅保留 3 天 `is_win_day` 均为 1（`sum(is_win_day) = 3`）的 `model_id` |
| 3 | `item_order` | 按 `item_id` 汇总近 30 天总订单量（`item_order_l30d`）及获胜日订单量（`winner_order_l30d`），用于计算获胜订单占比 |
| 4 | `cspu_ado` | 按 `cspu_id` 汇总近 30 天订单量除以 30，得到 CSPU 日均订单量（`cspu_ado`），作为无历史订单商品的兜底判断指标 |
| 5 | `all_cspu_model` | 从 CSPU 关联分析小时快照表取当日（`local_date`）最新小时（`max(local_hour)`）的 CSPU-Model-Item-Shop 映射全量数据 |
| 6 | INSERT OVERWRITE | 将 `all_cspu_model` 与 `win_3d_models` INNER JOIN（模型必须连续 3 天获胜），再 LEFT JOIN 订单指标，应用质量门槛过滤：**若商品有历史订单（`item_order_l30d > 0`），则要求获胜订单占比 ≥ 30%；否则要求 CSPU 日均订单量 ≥ 5**，最后按 `item_id, shop_id` 去重后写入目标表分区 |

### 注意事项

1. **质量门槛双分支逻辑**：过滤条件为 `CASE WHEN item_order_l30d > 0 THEN winner_order_l30d / item_order_l30d >= 0.3 ELSE cspu_ado >= 5 END`，新商品（无近 30 天订单）走 CSPU 日均订单兜底路径，存量商品走获胜订单占比路径，两条路径互斥。
2. **小时分区取最新**：`all_cspu_model` 依赖子查询 `max(local_hour)` 动态获取最新小时快照，若当日 `dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` 数据尚未产出或分区缺失，会导致 ETL 异常或结果为空。
3. **单 writer，无并发写入风险**：本表仅有 1 个 ETL 文件，`multi_writer = false`，无多文件并发写入同一分区的风险。
4. **分区全量覆写**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 方式，每次执行会覆盖对应分区的全部数据，重跑安全，但需确保上游数据完整后再触发。
5. **参数化区域**：SQL 使用 `${grass_region}` 和 `${grass_region_without_quote}` 两种形式（前者用于 WHERE 条件值，后者用于 view 命名避免特殊字符），调度时需同时传入两个参数。

---

*文档生成时间：2026-05-17*