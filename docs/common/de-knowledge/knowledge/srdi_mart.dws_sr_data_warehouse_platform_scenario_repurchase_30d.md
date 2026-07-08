<!-- ads-workspace-gdoc-sync: gdoc_id=181bOXNUjjZEbb9QGdyEqCk9X9nEkb9C7MwqEd1zNgU8 gdoc_url=https://docs.google.com/document/d/181bOXNUjjZEbb9QGdyEqCk9X9nEkb9C7MwqEd1zNgU8/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_repurchase_30d

**分层**: DWS（数据汇总层）
**主键**: `grass_region` + `local_date` + `scenario_tag`
**分区**: `grass_region`（大区）, `local_date`（日期）
**更新频率**: 每日调度，按大区分区写入
**访问频次**: 1015 次

---

## 业务描述

本表统计搜推数仓平台下，**各业务场景标签（scenario_tag）的用户复购率**，提供 **7 日复购率** 和 **30 日复购率** 两个维度的衡量指标。

**核心业务场景**：

- 以用户在过去 30 天内的下单行为为基础，衡量不同场景标签下用户的回购黏性；
- 7 日复购率：衡量在第 T-7 天有下单的用户，在 T-6 至 T 日内是否再次下单的比例；
- 30 日复购率：衡量在第 T-30 天有下单的用户，在 T-29 至 T 日内是否再次下单的比例；
- 支持对全部场景（`scenario_tag = '__ALL__'`）和单一场景标签分别统计。

**适合回答的问题**：

- 某大区某场景标签的用户 7 日 / 30 日复购率趋势如何？
- 哪些场景标签对用户复购黏性贡献最高？
- 跨场景标签横向对比复购率表现？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `'SG'`、`'MY'` 等；写入时由调度参数 `${grass_region}` 注入 |
| `local_date` | date | 指标归属日期；7 日复购率对应 `local_date = T-7`，30 日复购率对应 `local_date = T-30` |

### 维度：业务场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 场景标签，来源于用户订单关联的场景标签数组展开；`'__ALL__'` 表示全场景汇总 |

### 指标：复购率

| 字段 | 类型 | 说明 |
|---|---|---|
| `repurchase_rate_a7` | double | 7 日复购率：在 T-7 有下单的用户中，T-6 至 T 日内再次下单的用户占比；写入 `local_date = T-7` 分区，`repurchase_rate_a30` 置 null |
| `repurchase_rate_a30` | double | 30 日复购率：在 T-30 有下单的用户中，T-29 至 T 日内再次下单的用户占比；写入 `local_date = T-30` 分区，`repurchase_rate_a7` 置 null |

### Hudi 内部字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `_hoodie_commit_seqno` | string | Hudi 提交序列号，框架内部字段，业务查询无需关注 |
| `_hoodie_commit_time` | string | Hudi 提交时间戳，框架内部字段，业务查询无需关注 |
| `_hoodie_file_name` | string | Hudi 文件名，框架内部字段，业务查询无需关注 |
| `_hoodie_partition_path` | string | Hudi 分区路径，框架内部字段，业务查询无需关注 |
| `_hoodie_record_key` | string | Hudi 记录主键，框架内部字段，业务查询无需关注 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **务必指定 `grass_region` 分区**，避免全分区扫描，例如：
   ```sql
   WHERE grass_region = 'SG'
   ```
2. **务必指定 `local_date` 分区**，避免跨日期全量扫描，例如：
   ```sql
   AND local_date = '2024-01-01'
   ```
3. 同一行中 `repurchase_rate_a7` 与 `repurchase_rate_a30` 互斥（一个有值另一个为 null），需按业务语义分别过滤：
   ```sql
   AND repurchase_rate_a7 IS NOT NULL   -- 查 7 日复购率
   -- 或
   AND repurchase_rate_a30 IS NOT NULL  -- 查 30 日复购率
   ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `repurchase_rate_a7` | 比率指标（去重用户数之比），跨场景 / 跨日期直接 SUM 无业务意义，需重新基于明细计算 |
| `repurchase_rate_a30` | 同上，比率指标，不可跨维度累加 |

> ⚠️ 如需合并多个 `scenario_tag` 或多个 `local_date` 下的复购率，请回溯上游 `srdi_mart.dwm_sr_data_warehouse_platform_user_item` 重新聚合，或在业务层进行加权处理。

### 时效性说明

- 本表为 **每日批量调度**，T 日产出数据对应的分区日期为 **T-7**（7 日复购率）和 **T-30**（30 日复购率），非当天日期；
- 查询时注意 `local_date` 含义与实际运行日期存在偏移，勿误作"当日"数据使用；
- 表采用 Hudi 格式存储，回填历史数据时若新数据为 null 而旧数据不为 null，旧数据不会被覆盖，需手动清除 HDFS 文件后重跑。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 提供用户粒度的每日订单行为及场景标签数组（`scenario_tags`、`source1_scenario_tags`、`source2_scenario_tags`），作为复购率计算的基础明细数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_platform_user_item
    │  过滤 grass_region、近 30 天、operation='order' 且 order_cnt>0
    ▼
user_dwm_${grass_region_without_quote}（临时视图）
    │  多来源 scenario_tags 合并为 union_scenario_tags
    ▼
explode_data_${grass_region_without_quote}（临时视图）
    │  EXPLODE 展开 scenario_tag；GROUPING SETS 生成单场景及全场景汇总
    │  按窗口统计各用户在 a7/a30 基准日和后续窗口的下单次数
    ▼
result_${grass_region_without_quote}（CACHE TABLE）
    │  按 scenario_tag 聚合，计算 repurchase_rate_a7 和 repurchase_rate_a30
    ▼
srdi_mart.dws_sr_data_warehouse_platform_scenario_repurchase_30d
    （UNION ALL 分别写入 local_date=T-7 和 local_date=T-30 两个分区）
```

### 关键步骤

**Step 1 — 临时视图 `user_dwm`**

从 `dwm_sr_data_warehouse_platform_user_item` 中取指定 `grass_region`、近 30 天、`operation='order'` 且 `order_cnt > 0` 的记录，将三个来源的场景标签数组通过 `array_union` 合并为 `union_scenario_tags`，按 `(local_date, user_id, union_scenario_tags)` 分组。

**Step 2 — 临时视图 `explode_data`**

对 `union_scenario_tags` 进行 `LATERAL VIEW EXPLODE` 展开为单个 `scenario_tag`，使用 `GROUPING SETS ((user_id, scenario_tag), (user_id))` 同时生成单场景和全场景（`__ALL__`）两个粒度；在用户 × 场景粒度上，按四个时间窗口分别统计下单天数：
- `order_a6_a0`：T-6 至 T（7 日窗口后段）
- `order_a29_a0`：T-29 至 T（30 日窗口后段）
- `order_a7`：T-7 单日（7 日基准日）
- `order_a30`：T-30 单日（30 日基准日）

**Step 3 — CACHE TABLE `result`**

按 `scenario_tag` 聚合，分别计算：
- `repurchase_rate_a7 = count(在 T-7 有单 且 T-6~T 也有单的用户) / count(在 T-7 有单的用户)`
- `repurchase_rate_a30 = count(在 T-30 有单 且 T-29~T 也有单的用户) / count(在 T-30 有单的用户)`

CACHE 加速后续两次读取。

**Step 4 — INSERT INTO 目标表**

使用 `UNION ALL` 将结果写入两个不同的 `local_date` 分区：
- 第一路：写 `repurchase_rate_a7` 不为 null 的行，`repurchase_rate_a30` 置 null，`local_date = T-7`；
- 第二路：写 `repurchase_rate_a30` 不为 null 的行，`repurchase_rate_a7` 置 null，`local_date = T-30`；
- 分区路径为动态分区 `PARTITION(grass_region=${grass_region}, local_date)`。

### 注意事项

1. **单 writer**：本表仅有 1 个 ETL 文件写入，无多 writer 并发冲突风险；
2. **互斥列设计**：`repurchase_rate_a7` 与 `repurchase_rate_a30` 在同一行中始终一个为 null，是刻意的宽表设计，查询时需按需过滤非 null 列；
3. **Hudi 回填风险**：回填历史数据时，若旧分区数据不为 null 但新数据为 null，Hudi 不会覆盖旧值；需手动清除对应 HDFS 分区文件后重新执行 ETL；
4. **分区日期偏移**：`local_date` 分区为 T-7 或 T-30，不代表调度运行的当天日期，运维和查询均需注意偏移换算；
5. **参数化 Region**：SQL 中使用 `${grass_region}` 和 `${grass_region_without_quote}` 两种形式，前者用于 WHERE 过滤和分区写入，后者用于临时视图命名，调度时需保证两个参数值一致。

---

*文档生成时间：2026-05-17*