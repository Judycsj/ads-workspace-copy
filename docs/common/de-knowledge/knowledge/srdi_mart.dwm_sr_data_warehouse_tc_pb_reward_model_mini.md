<!-- ads-workspace-gdoc-sync: gdoc_id=1v1mqD-OfcfnYkp8vQG4aKcVr4Ip4LVwVec4sw7e3VRg gdoc_url=https://docs.google.com/document/d/1v1mqD-OfcfnYkp8vQG4aKcVr4Ip4LVwVec4sw7e3VRg/edit -->

# srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini

**分层：** DWM（数据仓库中间层）
**主键：** `shop_id` + `item_id` + `model_id` + `model_status` + `full_start_timestamp` + `grass_region` + `regional_date` + `regional_hour` + `regional_minute`
**分区：** `grass_region` / `regional_date` / `regional_hour` / `regional_minute` / `local_date` / `local_hour`
**更新频率：** 准实时，按分钟级分区滚动覆写（`INSERT OVERWRITE`），每次写入覆盖当前 `grass_region` + `regional_date` + `regional_hour` + `regional_minute` 分区
**访问频次：** 21,831 次

---

## 业务描述

本表用于 **Search & Recommendation（搜推）价格竞价（Price Bidding，PB）Reward Model** 的实时/准实时效果评估。以分钟级粒度聚合每个店铺-商品-竞价模型维度下的**曝光量、成交量及 GMV**，为奖励模型训练与在线评估提供核心特征和标签数据。

**核心业务场景：**
- 竞价模型（Reward Model）在线效果监控：追踪各 model 在不同 region、不同时段的曝光与转化表现；
- 奖励信号生成：GMV 与成交数据作为 RL/Bandit 类竞价模型的 reward 信号；
- 赢家模型（Winner Model）归因：仅聚合当前流量状态为活跃（`traffic_status in (1,2)`）且唯一变体（`is_winner=1`）的竞价模型数据，保证归因口径一致。

**适合回答的问题：**
- 某地区某小时某分钟窗口内，各竞价模型的曝光量和成交量分别是多少？
- 某 `shop_id` + `item_id` 组合在当前激活模型下的 GMV 贡献如何？
- 不同模型状态（`model_status`）下的转化效率对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY 等），数据按 region 隔离写入 |
| `regional_date` | date | 区域标准时间日期（SG 时区），分区调度基准日期 |
| `regional_hour` | int | 区域标准时间小时（0–23） |
| `regional_minute` | int | 区域标准时间分钟（调度起始分钟，窗口覆盖该分钟起 +15 分钟内的事件） |
| `local_date` | date | 目标 region 本地时间日期，由 `regional_date`+`regional_hour` 经时区转换得到 |
| `local_hour` | int | 目标 region 本地时间小时，由 `regional_date`+`regional_hour` 经时区转换得到 |

### 维度：竞价模型与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | 竞价奖励模型 ID，来自赢家模型表 |
| `model_status` | int | 模型流量状态，对应上游 `traffic_status`（1=实验，2=上线） |
| `full_start_timestamp` | bigint | 模型生效的完整起始时间戳（Unix 毫秒/秒），用于标识模型版本 |

### 指标：曝光与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 窗口内商品在当前竞价模型下的曝光次数（`operation='impression'` 事件聚合），订单事件贡献为 0 |
| `sold_cnt` | bigint | 窗口内商品在当前竞价模型下的付费成交件数（`operation='paid_order'` 事件聚合），曝光事件贡献为 0 |
| `gmv` | double | 窗口内成交 GMV，计算方式为 `paid_sold_cnt × bid_price`（赢家模型出价），曝光事件贡献为 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须同时指定 `grass_region`、`regional_date`、`regional_hour`、`regional_minute`**，缺少任一分区条件将触发全表扫描，严重影响性能。
- `local_date` / `local_hour` 亦为分区字段，可配合本地时区查询使用，但不能替代 `grass_region` 过滤。

```sql
-- 推荐过滤写法
WHERE grass_region = 'SG'
  AND regional_date = '2025-01-01'
  AND regional_hour = 10
  AND regional_minute = 30
```

### 不可直接 SUM 的字段

| 字段 | 风险说明 |
|---|---|
| `gmv` | 由 `paid_sold_cnt × bid_price` 派生而来，跨分区（跨分钟窗口）SUM 时注意窗口重叠问题；曝光行该字段为 0，勿与成交行混合统计后再求比率 |
| `imp_cnt` / `sold_cnt` | 曝光行与订单行在 UNION ALL 后合并聚合，单行值含义不同（一行仅有一类非零），跨维度 SUM 前需确认业务口径 |
| `model_status` / `full_start_timestamp` | 维度字段，不应进行数值聚合 |

### 时效性说明

- 本表为**分钟级准实时表**，`regional_minute` 分区表示调度窗口起始分钟，实际覆盖事件为 `[regional_minute, regional_minute + 15]` 分钟范围内的数据。
- 每次调度以 `INSERT OVERWRITE` 覆写当前分区，读取时需关注分区是否已写入完毕（存在短暂的写入中间态）。
- 上游 `dwd_*_minf` 表取的是当前 `regional_hour` 内 `max(regional_minute)` 分区，存在一定延迟，赢家模型数据非严格实时。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `rcmd_feature.dws_sr_data_warehouse_tc_pb_realtime_feature_5min` | 实时特征事件流，提供曝光（`impression`）和付费订单（`paid_order`）行为事件及 `imp_cnt`、`paid_sold_cnt`、`model_id` 等字段 |
| `srdi_mart.dwd_sr_data_warehouse_tc_pb_winner_model_minf` | PB 赢家竞价模型明细，提供 `model_id`、`traffic_status`、`full_start_timestamp`、`bid_price` 等模型元信息；取当前小时内 `max(regional_minute)` 分区 |
| `srdi_mart.dwd_sr_data_warehouse_tc_pb_one_variation_minf` | PB 单一变体明细，过滤 `is_winner=1` 确保商品-模型归因唯一性；取当前小时内 `max(regional_minute)` 分区 |

---

## ETL 逻辑摘要

### 数据流

```
rcmd_feature.dws_sr_data_warehouse_tc_pb_realtime_feature_5min（impression + paid_order）
        │
        ├─── INNER JOIN ──► dwd_sr_data_warehouse_tc_pb_winner_model_minf（traffic_status in 1,2）
        │                         （COLLECT_SET + explode 展开 model_list）
        ├─── INNER JOIN ──► dwd_sr_data_warehouse_tc_pb_one_variation_minf（is_winner=1）
        │
        ├─ 曝光分支：imp_cnt, sold_cnt=0, gmv=0
        │
        └─ 订单分支：imp_cnt=0, sold_cnt=paid_sold_cnt, gmv=paid_sold_cnt×bid_price
                │
           UNION ALL
                │
           GROUP BY shop_id, item_id, model_id, status/model_status, full_start_timestamp
                │
           INSERT OVERWRITE dwm_sr_data_warehouse_tc_pb_reward_model_mini（附加分区字段）
```

### 关键步骤

1. **曝光分支（Impression Branch）**
   - 从实时特征表过滤 `operation = 'impression'`，取 `regional_minute` 至 `regional_minute + 15` 窗口内的曝光事件（T1）。
   - 从赢家模型表取当前小时最新分区（`max(regional_minute)`），过滤 `traffic_status in (1, 2)`，通过 `COLLECT_SET` 将同一 `shop_id`+`item_id` 下的多个 model 聚合为列表，再 `LATERAL VIEW EXPLODE` 展开为多行（T2）。
   - 从单一变体表取最新分区中 `is_winner=1` 的 `shop_id`+`item_id` 组合（T3）。
   - T1 INNER JOIN T2 ON `shop_id`+`item_id`，再 INNER JOIN T3 ON `shop_id`+`item_id`，确保仅保留有赢家变体的商品。
   - 输出：`imp_cnt=T1.imp_cnt`，`sold_cnt=0`，`gmv=0`。

2. **订单分支（Paid Order Branch）**
   - 从实时特征表过滤 `operation = 'paid_order'`，取相同分钟窗口内的付费订单事件（T1，含 `model_id`）。
   - 从赢家模型表取最新分区，按 `shop_id`+`item_id`+`model_id` 聚合取 `max(bid_price)`、`max(traffic_status)`、`max(full_start_timestamp)`（T2）。
   - 从单一变体表取最新分区中 `is_winner=1` 的 `shop_id`+`item_id`+`model_id` 组合（T3）。
   - T1 INNER JOIN T2 ON `shop_id`+`item_id`+`model_id`，再 INNER JOIN T3 ON `shop_id`+`item_id`+`model_id`，三键关联保证 model 维度一致。
   - 输出：`imp_cnt=0`，`sold_cnt=T1.paid_sold_cnt`，`gmv=paid_sold_cnt × bid_price`。

3. **合并与聚合（UNION ALL + GROUP BY）**
   - 两个分支 UNION ALL 合并后，按 `shop_id`、`item_id`、`model_id`、`status/model_status`、`full_start_timestamp` 分组，对 `imp_cnt`、`sold_cnt`、`gmv` 执行 `SUM` 聚合。

4. **分区字段计算与写入**
   - 追加 `grass_region`、`regional_date`、`regional_hour`、`regional_minute` 作为参数注入。
   - `local_date` 和 `local_hour` 通过 `date_timezone_convert(regional_date, regional_hour, 'SG', grass_region, format)` 从 SG 时区转换为目标 region 本地时区。
   - 以 `INSERT OVERWRITE` 写入目标表对应分区。

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表仅有 1 个 ETL 文件写入，无并发写入竞争问题。
- **`max(regional_minute)` 延迟风险**：赢家模型表和单一变体表均取当前小时内最新 `regional_minute` 分区，若上游分区延迟，JOIN 结果可能使用上一批次的模型状态，存在数据滞后。
- **`bid_price` 精度**：GMV 计算依赖 `max(bid_price)`，多条记录取最大值的策略需注意是否与业务口径一致。
- **曝光分支 model 展开**：曝光事件通过 `COLLECT_SET + EXPLODE` 将一个商品关联的多个模型展开为多行，可能导致曝光事件被放大；分析时需注意 `imp_cnt` 在 model 维度的多行归因语义。
- **`INSERT OVERWRITE` 覆写**：每次调度覆写当前分区，若调度重跑，旧数据会被替换，适合幂等重跑但不适合增量追加场景。

---

*文档生成时间：2026-05-17*