<!-- ads-workspace-gdoc-sync: gdoc_id=1wGse2nEv_ywhRNcSk7P2AamC7ovU2_FtxgSqw4rqjxg gdoc_url=https://docs.google.com/document/d/1wGse2nEv_ywhRNcSk7P2AamC7ovU2_FtxgSqw4rqjxg/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_search_replace_monitoring_nd

**分层：** DWD  
**主键：** `grass_region` + `local_date` + `exp_tag` + `cspu_id` + `item_id` + `version_date`  
**分区：** `grass_region`（大区）、`local_date`（本地日期）  
**更新频率：** 每日（Daily，当日任务须在运行当日完成，否则自动终止）  
**访问频次：** 1436 次  

---

## 业务描述

本表是搜索替换（Search Replace）实验中 **preferred 状态组合的监控回退记录累计表**，属于 PB（Preferred/Base）实验框架下的质量管控层。

**核心业务场景：**
- 持续跟踪处于 `preferred` 状态的（`exp_tag`、`cspu_id`、`item_id`）组合，判断其近 7 天（实际约 6 天 22 小时）的曝光/点击表现是否劣于 `control` 组对应的 cspu 指标。
- 对表现变差（CTR 下降）的 preferred 组合进行版本标记，触发监控回退（rollback）机制，并以累计追加方式记录每一次触发事件。
- 限制单个组合 key 的最大回退次数（当前阈值：10 次），防止反复震荡升级。

**适合回答的问题：**
- 某大区、某日期下，哪些 `(exp_tag, cspu_id, item_id)` 组合被触发了监控回退？
- 某组合 key 历史上共被回退了多少次（`version_date` 去重计数）？
- 某次回退对应的版本号（`version_date`）是什么，便于与上游探索版本对齐？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `SG`、`MY` 等，每次写入时按分区隔离 |
| `local_date` | date | 本地日期（按各大区本地时间结算），对应任务运行日的前一日监控指标日期 |

### 维度：实验与商品组合标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_tag` | string | 实验分组标签，标识该组合所属的实验流量桶（如 `preferred`、`control` 等） |
| `cspu_id` | bigint | CSPU（标准商品单元）ID，替换实验中的候选商品标识 |
| `item_id` | bigint | 原始商品 ID，被替换的目标商品标识 |

### 指标：监控回退版本记录

| 字段 | 类型 | 说明 |
|---|---|---|
| `version_date` | int | 回退版本号，格式为 `YYYYMMDD`（取任务运行日 +1 天转整型），标识本次回退触发的版本；历史分区中同一组合 key 的 `version_date` 去重计数即为累计回退次数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：每次查询须指定具体大区，避免全表扫描。
- **`local_date`**：本表是累计记录表，每个分区存储截至该日期的全量回退记录（历史分区 + 当日新增）。查询最新状态时须使用 `max(local_date)` 或指定明确日期，**不可跨分区直接聚合**（否则会重复计算历史记录）。

示例：
```sql
WHERE grass_region = 'SG'
  AND local_date = '2025-08-07'
```

### 不可直接 SUM 的字段

- **`version_date`** 是版本号标识，数值无求和意义；统计回退次数应使用 `COUNT(DISTINCT version_date)` 按 `(exp_tag, cspu_id, item_id)` 分组。
- 本表不存储 CTR、曝光量、点击量等流量指标，无需担心此类聚合问题；流量指标存储于上游实时指标表。

### 时效性说明

- 表名后缀 `_nd` 表示近 N 天滑动窗口，实际 ETL 计算的是约 **6 天 22 小时**的增量指标差值（注释明确说明比 7 天少 2 小时）。
- 任务设有运行时限：**必须在调度当日完成**，超时则任务自动终止（自杀机制），当日若无数据产出则该分区缺失。
- 配置有 DQC warning 监控，检测升级数量波动异常。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf` | 提供 preferred 和 base 流量的分小时累计曝光/点击 nd 指标，用于计算近 7 天增量 CTR |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_status_hf` | 提供各组合 key 当前及历史的探索状态（`preferred`/`control` 等），用于筛选满足存续天数条件的 preferred 组合 |
| `srdi_mart.dwd_sr_data_warehouse_pb_search_replace_monitoring_nd` | 自引用，读取上一个已完成分区的历史回退记录，用于合并追加及限制回退次数 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_..._realtime_metrics_hf（最新分区）  ──┐
dwd_sr_..._realtime_metrics_hf（7天前分区）  ──┼──► 计算 7 天增量 CTR
                                               │
dwd_sr_..._status_hf（当日最新）              ──┤
dwd_sr_..._status_hf（7天前）                 ──┼──► 筛选持续 preferred ≥ 7 天的组合
                                               │
dwd_sr_..._monitoring_nd（上一分区，自引用）  ──┤──► 合并历史回退记录
                                               │
                                               ▼
                      dwd_sr_..._monitoring_nd（INSERT OVERWRITE 当日分区）
```

### 关键步骤

1. **计算最新/最早分区标识（SET 变量）**  
   - `max_partition`：定位当日 `local_date` 在实时指标表中可用的最大小时分区（`local_date_HH` 格式）。  
   - `min_partition`：定位 `local_date - 6` 天在实时指标表中可用的最小小时分区，两者相减构成近 7 天窗口。

2. **构建指标快照视图 `max_` / `min_`**  
   - 分别从实时指标表取最新分区和最早分区的数据，按 `(exp_tag, cspu_id, item_id, version_date)` 聚合 preferred 和 base（cspu）两类流量的累计曝光/点击 nd 值。

3. **构建 7 天前 preferred 状态视图 `preferred_day_cnt_`**  
   - 从状态表读取 `local_date - 7` 那天最大小时分区中状态为 `preferred` 的组合，用于验证"在 7 天前就已经是 preferred"的条件。

4. **构建当前 preferred 状态视图 `current_preferred_`**  
   - 从状态表读取当日最新分区中仍处于 `preferred` 状态、且 `version_date` 早于 `local_date - 6`（防止 7 天内多次探索的极端情形）的组合。

5. **构建历史监控记录视图 `last_monitoring_`**  
   - 自引用本表，取 `local_date` 之前最近一个有效分区，获取已有的回退记录，并统计每个组合 key 的历史回退次数（`version_cnt_` 视图）。

6. **构建待升级列表视图 `update_version_list_`**  
   - Inner join `current_preferred_` 与 `preferred_day_cnt_`，确保组合 key 持续 preferred ≥ 7 天。  
   - Left join 最新/最早指标快照，计算近 7 天增量曝光和点击。  
   - 过滤条件：preferred CTR < cspu（base）CTR，且两者曝光量均 > 0，确保数据完整性。  
   - 过滤历史回退次数 ≥ 10 次的组合，限制最大回退次数。  
   - `version_date` 赋值为任务运行日 +1 天的整型（`YYYYMMDD`），`join_key_date` 为当日整型，用于防止同日重复触发。

7. **INSERT OVERWRITE 目标分区**  
   - Full outer join `last_monitoring_`（历史记录）与 `update_version_list_`（新增回退）：  
     - 历史记录与新增记录通过 `(item_id, cspu_id, exp_tag)` + `version_date = join_key_date` 关联，若昨日日期已存在则不重复写入。  
   - 合并结果写入目标表当日分区，形成全量累计快照。

### 注意事项

- **单 writer**：本表无多文件并发写入（`multi_writer: false`），不存在分区冲突风险。
- **自引用依赖**：ETL 依赖本表上一分区数据（`last_monitoring_` 视图），若历史分区缺失（如首次运行或任务超时自杀），则历史记录为空，本次仅写入新增回退记录，不会报错但会丢失历史累计。
- **时间限制**：任务设有当日完成的硬性约束，调度延迟超限会导致分区缺失，需关注 DQC 告警。
- **分区写入方式**：`INSERT OVERWRITE PARTITION(grass_region, local_date)`，每次覆盖写当日分区，同一分区重跑幂等。
- **版本号说明**：`version_date` 数值由 ETL 运行时动态生成（`date_add(local_date, 1)` 转整型），与上游状态表的 `version_date` 含义不同，仅作为本表内部的版本标识。

---

*文档生成时间：2026-05-17*