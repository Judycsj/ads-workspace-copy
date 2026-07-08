<!-- ads-workspace-gdoc-sync: gdoc_id=1EKB24D-yqIkcXaltBu-2QBNx20Shsibhby0suY-VJs4 gdoc_url=https://docs.google.com/document/d/1EKB24D-yqIkcXaltBu-2QBNx20Shsibhby0suY-VJs4/edit -->

# srdi_mart.dws_sr_data_warehouse_pb_replace_pruning_item_manual_7d

**分层：** DWS（数据汇总层）
**主键：** `item_id` + `mapping_general` + `grass_region` + `local_date`
**分区：** `grass_region`（站点大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1，按分区覆盖写入）
**访问频次：** 1545 次

---

## 业务描述

本表服务于**搜推价格带（PB，Price Band）替换剪枝（Pruning）商品的人工规则筛选**场景。其核心目的是汇总商品（Item）在过去 7 天内，在**搜索（Search）与推荐（RCMD）**两个业务场景下的曝光、点击、下单等行为指标，以及其所属 CSPU（标准商品单元）的整体及排除自身后的聚合指标，为下游剪枝决策提供数据支撑。

**过滤条件说明：**
- 仅保留**非 7 日内新品**（上线超过 7 天）的商品，以排除新品对剪枝判断的干扰。
- 按 `mapping_general`（`RCMD` / `Search`）分场景分别统计，支持下游分场景自关联分析。

**适合回答的典型问题：**
- 某商品在过去 7 天内，在搜索或推荐场景下分别获得了多少曝光、点击和订单？
- 该商品所属 CSPU 内的其他商品（排除自身）在同场景下的表现如何？
- 排除广告流量后，CSPU 内同场景非自身商品的自然流量表现如何？
- 某商品近 7 天内有多少天有行为数据（`last7d_day_cnt`），是否达到剪枝阈值？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区，如 `SG`、`MY`、`TH` 等，查询时必须指定 |
| `local_date` | date | 业务日期（本地时区），ETL 每日刷新，查询时必须指定 |

### 维度：商品与场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，主维度键 |
| `mapping_general` | string | 业务场景标识，取值为 `RCMD`（推荐：含 You May Also Like、Daily Discover、Post Purchase）或 `Search`（搜索：Global Search），不会为 null；设计上保证了每个 item 按场景独立展开，便于下游自关联 |

### 指标：商品自身 7 天行为汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `last7d_day_cnt` | int | 过去 7 天内，商品在该场景下有行为数据（来自 CSPU-Item 关系映射展开）的去重天数，可用于判断商品是否持续有效曝光 |
| `item_imp_cnt_7d` | bigint | 商品自身过去 7 天曝光次数（含广告）|
| `item_click_cnt_7d` | bigint | 商品自身过去 7 天点击次数（含广告）|
| `item_order_cnt_7d` | double | 商品自身过去 7 天下单量（含广告）|

### 指标：同 CSPU 全量商品 7 天行为汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_imp_cnt_7d` | bigint | 该商品所属 CSPU 下所有商品（含自身）过去 7 天的汇总曝光次数（含广告）|
| `cspu_click_cnt_7d` | bigint | 该商品所属 CSPU 下所有商品（含自身）过去 7 天的汇总点击次数（含广告）|
| `cspu_order_cnt_7d` | double | 该商品所属 CSPU 下所有商品（含自身）过去 7 天的汇总下单量（含广告）|

### 指标：同 CSPU 排除自身后商品 7 天行为汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_exclude_self_imp_cnt_7d` | bigint | CSPU 内排除当前商品自身后，其余商品过去 7 天的汇总曝光次数（含广告）|
| `cspu_exclude_self_click_cnt_7d` | bigint | CSPU 内排除当前商品自身后，其余商品过去 7 天的汇总点击次数（含广告）|
| `cspu_exclude_self_order_cnt_7d` | double | CSPU 内排除当前商品自身后，其余商品过去 7 天的汇总下单量（含广告）|

### 指标：同 CSPU 排除自身及广告流量后商品 7 天行为汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_exclude_self_ads_imp_cnt_7d` | bigint | CSPU 内排除当前商品自身后，其余商品过去 7 天的自然流量（排除广告，`is_ads != 'true'`）汇总曝光次数 |
| `cspu_exclude_self_ads_click_cnt_7d` | bigint | CSPU 内排除当前商品自身后，其余商品过去 7 天的自然流量汇总点击次数 |
| `cspu_exclude_self_ads_order_cnt_7d` | double | CSPU 内排除当前商品自身后，其余商品过去 7 天的自然流量汇总下单量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，必须在 `WHERE` 子句中精确指定，否则触发全表扫描。
- **`local_date`**：分区字段，必须在 `WHERE` 子句中精确指定，该表为每日快照，通常取最新业务日期。

```sql
-- 正确示例
SELECT *
FROM srdi_mart.dws_sr_data_warehouse_pb_replace_pruning_item_manual_7d
WHERE grass_region = 'SG'
  AND local_date = '2024-01-15';
```

### 不可直接 SUM 的字段

- **`cspu_imp_cnt_7d`、`cspu_click_cnt_7d`、`cspu_order_cnt_7d`**：同一 CSPU 下不同商品行对应的 CSPU 汇总值在 ETL 中已通过两次去重聚合计算，不同 `item_id` 行之间存在指标重叠，**不可跨 `item_id` 直接累加**。
- **`cspu_exclude_self_*` 系列字段**：同上，属于商品视角的派生聚合指标，不同 `item_id` 行之间不可直接 SUM，否则会重复计算。
- **`last7d_day_cnt`**：为商品粒度的统计天数，多行累加无业务意义，**不可跨行 SUM**。
- **时效性说明**：本表为 **近 7 天滚动窗口汇总快照**（`*_7d` 后缀），每个分区 `local_date` 对应以该日期为终点的过去 7 天行为数据。跨 `local_date` 分区 SUM 会导致时间窗口重叠、重复计数，**不建议跨分区累加指标字段**。

### 其他注意事项

- 本表已在 ETL 中过滤掉**上线不足 7 天的新品**（`create_diff_days < 7`），下游无需再次过滤。
- `mapping_general` 字段保证非 null，取值固定为 `RCMD` 或 `Search`，分场景分析时可直接过滤。
- 表中 `item_id` 与 `mapping_general` 的组合为行粒度，即同一商品在两个场景下各有一行。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 获取当日 CSPU-Item 映射关系（一日关系横展为 7 天），构建 7 天内商品-CSPU 关联基础 |
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 获取过去 7 天（`date_sub(local_date, 6)` 至 `local_date`）的搜索与推荐场景曝光、点击、下单明细行为数据 |
| `mp_item.dim_item__reg_s0_live` | 获取商品注册信息（创建时间），用于过滤上线不足 7 天的新品 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf  ──┐
                                                        ├─→ all_cspu_item（1日关系×7天×2场景）
                                                        │
dwm_sr_data_warehouse_tc_ab_all_cards ─────────────────┼─→ imp_click（7天行为聚合）
                                                        │
                                                        ├─→ base（left join）
                                                        │
                                                        ├─→ self_join（CSPU维度自关联笛卡尔积）
                                                        │
                                                        ├─→ item_cspu_metrics（两次去重聚合）
                                                        │
mp_item.dim_item__reg_s0_live ─────────────────────────┼─→ exclude_new_item（非新品过滤）
                                                        │
                                                        └─→ INSERT OVERWRITE 目标表
```

### 关键步骤

**Step 1 — `all_cspu_item`（临时视图）**
从 CSPU-Item 关系表取当日映射关系，通过 `explode(transform(array(0..6), x -> date_sub(local_date, x)))` 将单日关系横展为 7 个日期，再通过 `explode(array('RCMD','Search'))` 展开为两个场景，形成 7天 × 2场景 的 CSPU-Item 基础笛卡尔积。

**Step 2 — `imp_click`（临时视图）**
从行为明细宽表中提取过去 7 天内（`between date_sub(local_date, 6) and local_date`）Search 和 RCMD 场景的 `omni_impression`/`omni_click`/`order` 事件，按 `local_date + item_id + mapping_general` 聚合曝光、点击、下单，同时区分广告与自然流量（`is_ads='true'` 时置零得到自然流量指标 `org_*`）。

**Step 3 — `base`（临时视图）**
将 `all_cspu_item` 与 `imp_click` 按 `local_date + item_id + mapping_general` 进行 **LEFT JOIN**，保留所有有 CSPU 关系的商品（即使过去 7 天内无行为数据）。

**Step 4 — `self_join`（临时视图）**
将 `base` 与自身进行 **CSPU 维度自关联**（`a.cspu_id = b.cspu_id`，同 `local_date` 和 `mapping_general`），获取同 CSPU 内所有商品的行为指标，形成以 `item_id`（a 侧）为主体、`same_cspu_item_id`（b 侧）为 CSPU 内对比商品的展开结果。

**Step 5 — `item_cspu_metrics`（临时视图）**
对 `self_join` 结果进行**两轮去重聚合**：
- 第一轮：按 `local_date + item_id + same_cspu_item_id + mapping_general` 分组，用 `MAX` 去除同一商品对在多 CSPU 下重复出现的指标重复；
- 第二轮：按 `local_date + item_id + mapping_general` 分组，对 item 侧指标取 `MAX`，对 CSPU 侧指标取 `SUM`，并通过 `if(item_id = same_cspu_item_id, 0, cspu_*)` 计算排除自身的 CSPU 指标，以及排除广告的自然流量指标。

**Step 6 — `exclude_new_item`（临时视图）**
从商品注册表中计算商品创建时间距统计日期的天数差，过滤出 `create_diff_days >= 7` 的非新品集合（使用前一天的 `grass_date` 以保证数据稳定性）。

**Step 7 — INSERT OVERWRITE（最终写入）**
将 `item_cspu_metrics` 按 `mapping_general + item_id` 做 7 天汇总（`SUM` 各日指标，`COUNT DISTINCT local_date` 得 `last7d_day_cnt`），与 `exclude_new_item` 做 **INNER JOIN** 过滤新品，最终以 `PARTITION(grass_region, local_date)` 覆盖写入目标表。

### 注意事项

- **单写入器（non multi-writer）**：当前仅一个 ETL 文件写入本表，无并发写入风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，每次运行仅覆盖当日当区分区，历史分区不受影响，支持重跑。
- **CSPU-Item 关系使用当日快照**：表中 7 天行为数据基于**当日 CSPU-Item 关系**横展，而非历史每天的关系快照，因此若 CSPU-Item 映射关系发生变化，历史行为的归因可能与实际略有偏差。
- **LEFT JOIN 保留零行为商品**：`base` 视图采用 LEFT JOIN，即使某商品在过去 7 天内无任何曝光/点击/下单行为，仍会出现在最终结果中（指标为 null 或 0），下游使用时需注意对 null 值的处理。
- **新品过滤依赖前一天的商品维表**：`exclude_new_item` 使用 `grass_date = date_add(local_date, -1)` 的商品数据，以规避当天数据可能未就绪的问题，过滤时效存在约一天的滞后。
- **自关联计算代价较高**：`self_join` 步骤为 CSPU 维度笛卡尔积展开，ETL 注释中已标注可通过调整为 INNER JOIN 进行优化，实际运行时应关注数据量规模。

---

*文档生成时间：2026-05-17*