<!-- ads-workspace-gdoc-sync: gdoc_id=1yi4VMm5Mr6dend1tcAm9y2aKhyddROKet_Jr8wtw2XI gdoc_url=https://docs.google.com/document/d/1yi4VMm5Mr6dend1tcAm9y2aKhyddROKet_Jr8wtw2XI/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_view_page_duration_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `scenario_tag` + `exp_type` + `experiment_id` + `exp_group_id` + `page_tag` + `source1_page_tag` + `source2_page_tag`
**分区：** `grass_region`（区域）, `local_date`（日期）
**更新频率：** 每日（T+1 调度，按分区覆盖写入）
**引用频次/访问频次：** 1325

---

## 业务描述

本表为搜推数仓平台实验组级别页面浏览时长汇总表，以**实验分组（exp_group）**为最细粒度，统计各 A/B 实验组用户在平台内不同页面场景下的**日浏览时长**与**日活用户数（DAU）**。

**核心业务场景：**

- **Search（搜索场景）**：统计搜索白名单命中用户，在各页面标签维度下的搜索浏览时长与 DAU，用于评估搜索实验效果。
- **RCMD/DD（推荐场景）**：统计推荐白名单命中用户，在各页面标签维度下的推荐浏览时长与 DAU，用于评估推荐实验效果。
- **Platform（平台整体）**：聚合全平台（`scenario_tag = 'platform'`）层面的浏览时长与 DAU，分别对应搜索实验组和推荐实验组，衡量实验对平台整体大盘的影响。

**适合回答的问题：**

- 某个实验组（或实验）用户当日在特定页面（`page_tag`）下的总浏览时长是多少？
- 实验期间各组 DAU 对比如何？
- 搜索/推荐/平台整体场景下，各实验分组的人均浏览时长差异？
- 控制组与实验组在特定页面路径（`source1_page_tag` / `source2_page_tag`）下的留存时长对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域分区，例如 `sg`、`my` 等，查询时必须指定 |
| `local_date` | date | 本地日期分区，格式 `yyyy-MM-dd`，查询时必须指定 |

### 维度：实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | 实验 ID，由实验分组维表关联得出；若该 exp_group 未匹配到实验则为 NULL |
| `exp_group_id` | int | A/B 实验分组 ID，来源于 ABTest 用户分组维表 |
| `exp_type` | string | 实验关联方式：`assign_log_join`（基于搜索分配日志）/ `dim_join`（基于推荐维表） |

### 维度：场景与页面

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 业务场景标签：`search`（搜索）/ `dd`（推荐）/ `platform`（平台整体） |
| `page_tag` | string | 当前页面标签；`__ALL__` 表示该用户所有页面聚合；平台场景下固定为 `null` |
| `source1_page_tag` | string | 来源一级页面标签；`__ALL__` 表示全量聚合；平台场景下固定为 `null` |
| `source2_page_tag` | string | 来源二级页面标签；`__ALL__` 表示全量聚合；平台场景下固定为 `null` |

### 指标：浏览时长与活跃用户

| 字段 | 类型 | 说明 |
|---|---|---|
| `duration` | double | 该实验分组在对应页面/场景下的**总浏览时长**（毫秒），已过滤单用户单日超过 86400000ms（24小时）的异常数据 |
| `dau` | bigint | 该实验分组在对应页面/场景下的**日活用户数**（即 duration > 0 的用户计数），为预聚合去重指标 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，查询时必须同时指定，否则触发全表扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'sg'
    AND local_date = '2025-01-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 风险 | 正确处理方式 |
|---|---|---|
| `dau` | 预聚合去重指标，跨 `page_tag` / `source1_page_tag` / `source2_page_tag` 直接 SUM 会导致**重复计数**（同一用户在多个页面均被计入） | 若需全页面 DAU，应筛选 `page_tag = '__ALL__'` 的行 |
| `duration` | 同理，`__ALL__` 行已包含明细行之和，混合聚合会**重复累加** | 应在同一粒度下聚合，或仅使用 `__ALL__` 行 |

### `page_tag` 取值说明

- 明细行：具体页面标签字符串（如 `search`、`minifeed`）或 `null`（原始为 NULL 时 coalesce 处理）
- 汇总行：`__ALL__`，代表该用户所有页面的汇总，仅存在于 `scenario_tag IN ('search', 'dd')` 的数据中
- `scenario_tag = 'platform'` 时，`page_tag`、`source1_page_tag`、`source2_page_tag` 固定为字符串 `null`

### 时效性说明

- 表名后缀 `_1d` 表示**日粒度快照**，每日调度产出前一自然日数据
- 数据通过 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 写入，具备**幂等性**，重跑安全

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_view_page_duration_di` | 明细层页面浏览时长记录，按 `scenario_tag`（search / dd / platform）分别读取，提取用户级别 duration |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | ABTest 用户分组维表，分别按 `is_search_whitelist` 和 `is_rcmd_whitelist` 过滤，获取搜索/推荐场景命中用户的实验分组归属 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验分组元数据维表，提供 `exp_group_id` → `experiment_id` 的映射关系 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_view_page_duration_di
        │
        ├─ scenario_tag='search' ──► user_duration_search_raw
        │                                  │ (+ __ALL__ 汇总行)
        │                            user_duration_search
        │                                  │ inner join user_exp_search
        │                            exp_duration_search
        │
        ├─ scenario_tag='dd'     ──► user_duration_rcmd_raw
        │                                  │ (+ __ALL__ 汇总行)
        │                            user_duration_rcmd
        │                                  │ inner join user_exp_rcmd
        │                            exp_duration_rcmd
        │
        └─ scenario_tag='platform' ► user_duration_platform
                                           │ inner join (user_exp_search UNION user_exp_rcmd)
                                     exp_duration_platform
                                                    │
dim_sr_data_warehouse_abtest_user_group ────────────┘
dim_sr_data_warehouse_abtest_group ──► experiment_id_mapping
                                                    │
                           UNION ALL 三路结果 left join experiment_id_mapping
                                                    │
                               INSERT OVERWRITE 目标表
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `user_exp_search` | 从 ABTest 用户分组维表过滤 `is_assignment_log=1 AND is_search_whitelist=1`，获取搜索实验命中用户及其 `exp_group_id` |
| 2 | `user_exp_rcmd` | 同上，过滤 `is_rcmd_whitelist=1`，获取推荐实验命中用户及其 `exp_group_id` |
| 3 | `user_duration_search_raw` | 从 DWD 层读取 `scenario_tag='search'` 的有效记录（`is_analysis_log=1 AND duration>0`），按用户+页面维度聚合，并过滤单用户单日超 24 小时异常值 |
| 4 | `user_duration_search` | 在明细基础上 UNION ALL 追加 `page_tag='__ALL__'` 的用户级全页面汇总行 |
| 5 | `exp_duration_search` | 与 `user_exp_search` inner join，聚合至实验分组粒度，产出 `scenario_tag='search'`、`exp_type='assign_log_join'` 的分组统计 |
| 6 | `user_duration_rcmd_raw` | 同步骤 3，处理 `scenario_tag='dd'` 数据 |
| 7 | `user_duration_rcmd` | 同步骤 4，追加推荐场景 `__ALL__` 汇总行 |
| 8 | `exp_duration_rcmd` | 与 `user_exp_rcmd` inner join，产出 `scenario_tag='dd'`、`exp_type='dim_join'` 的分组统计 |
| 9 | `user_duration_platform` | 读取 `scenario_tag='platform'` 数据，按用户聚合总时长 |
| 10 | `exp_duration_platform` | 与搜索+推荐两套实验用户合并后 inner join，同时产出 `assign_log_join` 和 `dim_join` 两种 `exp_type` 的平台指标，`page_tag` 等维度固定为 `'null'` |
| 11 | `experiment_id_mapping` | 从实验分组元数据维表获取 `exp_group_id` → `experiment_id` 映射（仅含搜索或推荐白名单分组） |
| 12 | INSERT OVERWRITE | 将三路结果 UNION ALL 后，left join `experiment_id_mapping` 补充 `experiment_id`，写入目标表对应分区 |

### 注意事项

- **单写入文件**：该表仅由单个 ETL 文件驱动（`multi_writer=false`），无多路写入竞争风险。
- **分区覆盖写入**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，重跑时覆盖当日分区，幂等安全。
- **异常值过滤**：搜索和推荐场景均在 raw 层通过 `HAVING duration < 86400000` 过滤单用户单日超 24 小时的异常数据；平台场景在 join 后通过 `WHERE t1.duration < 86400000` 过滤，逻辑层级略有差异，需注意。
- **`experiment_id` 可能为 NULL**：目标表通过 left join 关联实验 ID，若某 `exp_group_id` 在当日实验维表中无匹配记录（非搜索也非推荐白名单），则 `experiment_id` 为 NULL。
- **`__ALL__` 行与明细行共存**：`page_tag = '__ALL__'` 为预聚合汇总行，与明细行在同一张表中并存，聚合查询时需严格区分，避免重复计算。
- **平台场景页面维度固定**：`scenario_tag='platform'` 的所有记录，`page_tag`、`source1_page_tag`、`source2_page_tag` 固定写入字符串 `'null'`，而非 SQL NULL，过滤时需使用 `= 'null'` 而非 `IS NULL`。

---

*文档生成时间：2026-05-17*