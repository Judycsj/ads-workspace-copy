<!-- ads-workspace-gdoc-sync: gdoc_id=1fA3Xei38zsBiEkp7zKPcWxIFG802ETj-UTkW8q41ZNM gdoc_url=https://docs.google.com/document/d/1fA3Xei38zsBiEkp7zKPcWxIFG802ETj-UTkW8q41ZNM/edit -->

# srdi_mart.dwd_sr_data_warehouse_rcmd_fll_sampled_user_order_1d

**分层：** DWD（明细数据层）
**主键：** `user_id` + `item_id` + `order_id` + `scenario_tag` + `recall_event_time` + `order_event_time`
**分区：** `grass_region`（大区）/ `regional_date`（业务日期）
**更新频率：** 每日一次（T+1 全量覆写，`INSERT OVERWRITE`）
**访问频次：** 1676 次

---

## 业务描述

本表存储 **FLL（Feed Link Layer）推荐场景下抽样用户的订单明细数据**，记录在 `DA_Daily Discover`（每日发现）和 `DA_You May Also Like`（猜你喜欢）两个推荐场景中，有过曝光记录的用户所产生的订单行为。

表中每行代表一条"用户 × 商品 × 订单 × 场景"的归因记录，通过将订单数据与同一用户的 FLL 曝光记录进行关联，建立推荐曝光到订单转化的数据链路。

**核心业务场景：**
- 推荐系统 FLL 场景的订单归因分析
- 推荐召回效果评估（曝光 → 转化路径还原）
- 按推荐场景拆分的 GMV、订单量统计

**适合回答的问题：**
- FLL 推荐场景（每日发现 / 猜你喜欢）带来了多少订单？
- 被 FLL 推荐曝光的用户，其后续下单行为分布如何？
- 各大区、各场景的推荐订单转化明细是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `SG`、`MY`、`TH` 等；每个分区对应一个大区 |
| `regional_date` | date | 业务日期（大区本地时间），格式 `yyyy-MM-dd` |

### 维度：用户与订单标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，同时作为曝光与订单的关联键 |
| `item_id` | bigint | 商品 ID |
| `order_id` | bigint | 订单 ID |
| `scenario_tag` | string | 推荐场景标签。枚举值：`DA_Daily Discover`、`DA_You May Also Like`（具体场景）；或 `__ALL__`（所有 FLL 场景汇总行，由 ETL 补充生成） |

### 指标：时间戳

| 字段 | 类型 | 说明 |
|---|---|---|
| `recall_event_time` | bigint | FLL 曝光事件时间（Unix 秒级时间戳），来源于抽样用户曝光表的 `event_time` |
| `order_event_time` | bigint | 订单事件时间（Unix 秒级时间戳），由平台事件表的 `event_timestamp / 1000` 转换得到 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能。
- **`regional_date`**：必须指定，建议使用具体日期或有限日期范围，避免全量扫描。

```sql
-- 示例：查询新加坡 2024-01-01 的 FLL 推荐订单
WHERE grass_region = 'SG'
  AND regional_date = '2024-01-01'
```

### 不可直接 SUM / COUNT 的注意事项

- **`scenario_tag = '__ALL__'` 与具体场景行存在数据重叠**：ETL 中同时写入了按场景拆分的明细行和汇总行（`__ALL__`），同一 `order_id` 在表中会出现多条记录（至少 1 条具体场景 + 1 条 `__ALL__`）。
  - 若需统计各场景订单数，需 **过滤 `scenario_tag != '__ALL__'`**。
  - 若需汇总所有 FLL 场景总体订单数（去重），建议 **仅使用 `scenario_tag = '__ALL__'`** 的行，或在具体场景行上做 `COUNT(DISTINCT order_id)`。
  - **切勿对所有 `scenario_tag` 行直接 `COUNT` 或 `SUM` 而不加过滤**，否则会导致重复计算。

- **`recall_event_time`**：为曝光时间，与 `order_event_time` 的差值可用于计算归因时间窗口，但本表未对归因时间差做限制，使用时需按业务需求自行过滤时间差范围。

### 时效性说明

- 本表为 **T+1 日更新**，每日对指定分区执行 `INSERT OVERWRITE`，仅包含当日业务数据，不累计历史窗口（`_1d` 后缀）。
- 不含 `_nd`、`_td` 类型的滑动窗口或累计逻辑。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_rcmd_fll_sampled_user_impression_1d` | 提供 FLL 场景抽样用户的曝光事件时间（`recall_event_time`），过滤场景为 `DA_Daily Discover` 和 `DA_You May Also Like` |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供平台侧订单事件明细，含 `algo_tag`、`source1_algo_tag`、`source2_algo_tag` 等推荐标签字段，过滤 `operation = 'order'` |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_rcmd_fll_sampled_user_impression_1d  ──┐
  （FLL 场景曝光，按 user_id + event_time 去重）              │
                                                             ├─ INNER JOIN on user_id ──> dwd_joined
dwd_sr_data_warehouse_platform                               │
  （平台订单事件，过滤 operation='order' 且含推荐标签）        ┘
                                                             │
                                               explode(union_scenario_tags) ──> 按场景拆分行
                                                             +
                                               补充 scenario_tag='__ALL__' 汇总行
                                                             │
                                       INSERT OVERWRITE ──> 目标表（按 grass_region + regional_date 分区）
```

### 关键步骤

1. **Statement 1 — `fll_impression` 临时视图**
   从曝光明细表中提取指定大区和日期内，场景为 `DA_Daily Discover` 或 `DA_You May Also Like` 的用户曝光记录，按 `user_id` + `event_time`（即 `recall_event_time`）去重（`GROUP BY`）。

2. **Statement 2 — `dwd_base` 临时视图**
   从平台事件表中提取订单事件（`operation = 'order'`），要求至少有一个推荐标签（`algo_tag` / `source1_algo_tag` / `source2_algo_tag`）不为空。对三个来源的标签字段分别使用 `filter` 函数，仅保留属于目标场景的标签值，并将 `event_timestamp` 除以 1000 转为秒级时间戳。

3. **Statement 3 — `dwd_joined` 临时视图**
   将订单数据（`dwd_base`）与曝光数据（`fll_impression`）按 `user_id` 做 `INNER JOIN`，保留双方均有记录的用户，并使用 `array_union` 合并三个来源的场景标签数组为 `union_scenario_tags`。

4. **Statement 4 — INSERT OVERWRITE 写目标表**
   分两段 `UNION ALL` 写入目标分区：
   - **第一段**：`LATERAL VIEW EXPLODE(union_scenario_tags)` 将每行的场景标签数组展开为多行，每行对应一个具体场景，并做 `GROUP BY` 去重。
   - **第二段**：不展开场景标签，统一写入 `scenario_tag = '__ALL__'`，代表所有 FLL 场景的汇总行。

### 注意事项

- **数据重叠风险**：因 `UNION ALL` 同时写入具体场景行和 `__ALL__` 汇总行，同一 `order_id` 必然在表中出现多条记录，下游查询须明确区分使用场景。
- **INNER JOIN 语义**：仅保留当天有 FLL 曝光记录的用户订单，无曝光记录的用户订单不会出现在本表中；`recall_event_time` 与 `order_event_time` 的先后关系未在 ETL 中强制约束，使用时需业务侧自行判断归因合理性。
- **单一写入文件**：本表仅有 1 个 ETL 文件，无 multi-writer 问题，分区写入策略为 `INSERT OVERWRITE`，每次运行覆盖对应 `grass_region` + `regional_date` 分区。
- **参数化执行**：SQL 中使用 `${grass_region}`、`${grass_region_without_quote}`、`${regional_date}`、`${schema}` 等参数，每次调度按大区和日期参数化执行。

---

*文档生成时间：2026-05-17*