<!-- ads-workspace-gdoc-sync: gdoc_id=18SbmJw0DbagRiDwSO1yHMHH6YU6SjhY-7B5q7a5F9ls gdoc_url=https://docs.google.com/document/d/18SbmJw0DbagRiDwSO1yHMHH6YU6SjhY-7B5q7a5F9ls/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_level_view_page_duration_1d

**分层**：DWS（数据汇总层）
**主键**：`grass_region` + `local_date` + `scenario_tag` + `source_level` + `page_tag` + `source1_page_tag` + `source2_page_tag`
**分区**：`grass_region`（大区）, `local_date`（业务日期）
**更新频率**：每日全量覆盖（INSERT OVERWRITE，按分区写入）
**引用频次 / 访问频次**：340

---

## 业务描述

本表是**搜推数仓平台**针对**数据仓库场景（Data Warehouse Platform）** 的页面停留时长汇总宽表，粒度为「大区 × 业务日期 × 场景 × 来源层级 × 页面路径」。

数据来源于明细层 `dwd_sr_data_warehouse_view_page_duration_di`，仅保留分析有效日志（`is_analysis_log = 1`）且停留时长大于 0 的记录，按场景、页面及来源层级聚合用户数（UV）与总停留时长。

**核心业务场景：**
- 分析不同场景（`scenario_tag`）下各页面的用户访问量与停留时长分布；
- 通过来源层级（`source_level`）及来源页面链路（`source1_page_tag`、`source2_page_tag`）追踪用户页面跳转路径及其时长贡献；
- 支持大区维度的日粒度页面体验分析。

**适合回答的问题：**
- 某大区某日，各场景下哪个页面的用户停留时长最长？
- 用户从哪个来源页面跳转到当前页面的停留时长更高？
- 不同来源层级的页面访问量（UV）和时长趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，用于数据分区隔离，例如 CN、US 等 |
| `local_date` | date | 业务日期，数据统计所属的本地日期，格式 `yyyy-MM-dd` |

### 维度：场景与页面路径

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 场景标签，标识用户所处的业务场景，如搜索、推荐等 |
| `source_level` | int | 来源层级，标识当前页面在跳转链路中的层级深度 |
| `page_tag` | string | 当前页面标签，标识用户实际访问的页面 |
| `source1_page_tag` | string | 一级来源页面标签，当前页面的直接上游来源页面 |
| `source2_page_tag` | string | 二级来源页面标签，当前页面的二跳上游来源页面 |

### 指标：用户访问量与停留时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `uv` | bigint | 独立访问用户数（按 `user_id` 去重计数），统计周期为当日 |
| `duration` | double | 页面总停留时长之和（单位与明细层一致，通常为秒），由明细层 `duration` 字段 SUM 汇总而来 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪**：查询时务必同时指定 `grass_region` 和 `local_date`，避免全表扫描。示例：
  ```sql
  WHERE grass_region = 'CN'
    AND local_date = '2025-01-01'
  ```
- 如需跨日期汇总，建议明确列出日期范围（`local_date BETWEEN ... AND ...`），并确认每个分区均已产出。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `uv` | 去重指标，跨分组/日期直接 SUM 会导致重复计数，需回退明细层重新去重或使用近似聚合 |

- `duration` 为普通加和指标，在同一分区内跨维度聚合时可直接 SUM；但若需计算**人均时长**等派生指标，需注意分子分母口径一致性。

### 时效性说明

- 本表为 **日粒度（`_1d`）** 表，数据 T+1 产出，不反映当日实时数据。
- 每次写入为 `INSERT OVERWRITE` 按分区覆盖，历史分区数据不会被当日写入影响。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_view_page_duration_di` | 页面停留时长明细层，提供用户级别的场景、页面、来源链路及停留时长原始记录，是本表唯一上游 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_view_page_duration_di  （明细层，用户粒度）
        │
        │  过滤：grass_region、local_date 分区命中
        │         is_analysis_log = 1（仅保留分析有效日志）
        │         duration > 0（过滤无效停留）
        │
        ▼
  按 scenario_tag、source_level、page_tag、
     source1_page_tag、source2_page_tag 聚合
        │
        │  count(distinct user_id) → uv
        │  sum(duration)           → duration
        │
        ▼
srdi_mart.dws_sr_data_warehouse_platform_scenario_level_view_page_duration_1d
  （目标表，分区写入 grass_region + local_date）
```

### 关键步骤

1. **分区过滤**：从明细层读取指定 `grass_region` 和 `local_date` 分区数据。
2. **质量过滤**：
   - `is_analysis_log = 1`：仅保留标记为有效分析日志的记录，剔除无效/测试行为；
   - `duration > 0`：排除停留时长为零或负值的异常记录。
3. **维度聚合**：按 `scenario_tag`、`source_level`、`page_tag`、`source1_page_tag`、`source2_page_tag` 五维分组。
4. **指标计算**：
   - `count(distinct user_id)` → `uv`（去重用户数）；
   - `sum(duration)` → `duration`（累计停留时长）。
5. **分区写入**：`INSERT OVERWRITE` 写入目标表对应 `(grass_region, local_date)` 分区，支持幂等重跑。

### 注意事项

- **单一写入源**：本表仅有 1 个 ETL 文件、1 个写入分支，无 multi-writer 风险。
- **幂等重跑**：采用 `INSERT OVERWRITE PARTITION` 模式，同一分区重复运行不会产生数据重叠，重跑安全。
- **`uv` 的跨分区一致性**：`uv` 为分区内去重 UV，跨日期或跨大区汇总时不可直接累加，需从明细层重新计算。
- **`duration > 0` 过滤**：ETL 已在明细层基础上再次过滤，与明细层行数可能存在差异，对比时需注意口径。

---

*文档生成时间：2026-05-17*