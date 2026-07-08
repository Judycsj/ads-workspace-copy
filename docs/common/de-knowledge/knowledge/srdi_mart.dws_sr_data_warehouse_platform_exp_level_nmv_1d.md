<!-- ads-workspace-gdoc-sync: gdoc_id=1jQvVypLPLkzgqQxAvSbw4_qMAAQ9tz5_bZhzr7tAXUU gdoc_url=https://docs.google.com/document/d/1jQvVypLPLkzgqQxAvSbw4_qMAAQ9tz5_bZhzr7tAXUU/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_nmv_1d

**分层：** DWS（数据仓库服务层）
**主键：** `exp_type` + `grass_region` + `local_date` + `exp_group_id` + `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `target_type` + `abs_tier_180d`
**分区：** `exp_type` / `grass_region` / `local_date`（三级分区）
**更新频率：** 每日全量覆盖（`INSERT OVERWRITE`）
**引用频次/访问频次：** 3023

---

## 业务描述

本表为搜推（Search & Recommendation）数仓平台级别的**实验组（A/B Test）GMV / 订单指标宽表**，粒度为「实验组 × 维度组合 × 自然日」。

核心业务场景：
- **A/B 实验效果评估**：将用户的实验分组信息（`exp_group_id`）与其产生的净 GMV（`nmv`）、净订单数（`net_order_cnt`）、下单 UU 数（`net_order_uu`）关联，支持实验组间的指标对比。
- **多维度拆解**：支持按平台（`platform`）、是否广告（`is_ads`）、业务场景标签（`scenario_tag`）、曝光位（`feature_detail`）、目标类型（`target_type`）、用户价值分层（`abs_tier_180d`）进行细粒度分析。
- **搜推场景覆盖**：通过 DPM（Data Platform Mapping）模块标签体系，覆盖搜索（Global Search）、推荐（Daily Discover、User Scenario 等）等核心流量场景。

适合回答的典型问题：
- 某实验组在特定场景下相比对照组 GMV 变化了多少？
- 不同用户价值层（`abs_tier_180d`）在实验中的订单转化表现如何？
- 某平台/渠道的实验组下单 UU 差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验类型分区键；当前 ETL 写入值固定为 `'dim_join'`，表示维度关联模式 |
| `grass_region` | string | 大区/区域分区键，如 `SG`、`MY` 等，对应业务运营大区 |
| `local_date` | date | 业务日期分区键，即订单归属的自然日 |

### 维度：实验与平台维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，标识用户所属实验组 |
| `platform` | string | 用户下单平台；无平台信息时聚合为 `'__ALL__'` |
| `is_ads` | string | 是否广告流量，字符串类型（`'true'`/`'false'`）；维度聚合时为 `'__ALL__'` |

### 维度：场景与位置维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 曝光位标识，格式通常为 `PageType-模块-目标类型` 的连字符拼接；全场景聚合时为 `'__ALL__'` |
| `scenario_tag` | string | 业务场景标签，由 DPM 模块/报表对象/业务线等拼接生成（如 `dpm module Global Search business line Search`）；全场景聚合时为 `'__ALL__'` |
| `target_type` | string | 目标类型，从 `feature_detail` 按 `-` 分割提取（优先取第三段，次取第二段）；全场景聚合时为 `'__ALL__'` |

### 维度：用户分层维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `abs_tier_180d` | string | 用户近 180 天 GMV 价值分层，来源于 `dim_sr_data_warehouse_user_label`，取订单日 D-1 的标签；`abs_tier_180d = 0` 的用户被过滤；无分层信息时填 `'0'`，维度聚合时为 `'__ALL__'` |

### 指标：订单与 GMV 指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 净 GMV（Net Merchandise Value），实验组内该维度组合的净成交金额之和 |
| `net_order_cnt` | double | 净订单数，实验组内该维度组合的净订单量之和 |
| `net_order_uu` | bigint | 产生净订单的用户数（下单 UU），由 `net_order_cnt > 0` 时标记为 1 后按实验组聚合得到 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须全部显式指定**，以避免全表扫描：
  ```sql
  WHERE exp_type = 'dim_join'
    AND grass_region = '<目标大区>'
    AND local_date = '<目标日期>'
  ```
- `exp_type` 当前仅有 `'dim_join'` 一个有效值，查询时仍需显式写出。
- `local_date` 为日粒度分区，查询多日数据时使用 `BETWEEN` 范围过滤并注意数据量。

### 不可直接 SUM 的字段

- **`net_order_uu`**：为去重用户数（UU），本表已按实验组级别预聚合，跨实验组或跨维度直接 `SUM` 会导致重复计数，需结合业务含义确认聚合口径。
- **跨维度组合聚合**：本表包含多个 `GROUPING SETS` 产生的预聚合行（含 `'__ALL__'` 占位符），直接对全表 `SUM` 会导致重复叠加。查询时必须在 `WHERE` 或 `GROUP BY` 中明确指定 `feature_detail`、`scenario_tag`、`target_type`、`platform`、`is_ads`、`abs_tier_180d` 的具体取值或 `'__ALL__'` 层级，确保每行数据仅被计算一次。

### 时效性说明

- 本表为 **1d（每日）** 粒度表，`local_date` 对应业务自然日，T+1 更新。
- ETL 在计算 `abs_tier_180d` 用户标签时，使用订单日 **D-1** 的标签数据（即 `date_add(local_date, -1)`），存在一天的标签滞后。
- 实验分组信息（`user_exp`）取 **当日及过去 7 天**（`-7d ~ 0d`）的 Assignment Log，仅保留已分配且在白名单内的用户。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 原始平台级 NMV 明细数据，提供用户维度的订单数、GMV 及 DPM 场景标签字段 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，提供用户实验组 ID（`exp_group_id`）及 Assignment Log 信息 |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 用户标签维度表，提供用户近 180 天 GMV 价值分层（`abs_tier_180d`） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform_nmv          ──┐
                                               ├─→ [DPM 标签拼接 & 过滤] ──→ base_table
dim_sr_data_warehouse_user_label            ──┤                               │
                                               │                               ├─→ raw_data（按 feature_detail 维度展开，含 source1/source2）
dim_sr_data_warehouse_abtest_user_group     ──┘                               ├─→ dws_all_tag（全场景 __ALL__，含 abs_tier_180d）
                                                                               └─→ dws_tag（全场景 __ALL__ + 场景标签展开，含 abs_tier_180d）
                                                                                         │
                                                                               [cube_table：GROUPING SETS 多维预聚合]
                                                                                         │
                                                                               [uu_data：打标 net_order_uu]
                                                                                         │
                                                                               [map_data：metrics 打包为 array]
                                                                                         │
                                                                               [metric_table：exp_sum UDF 按实验组聚合]
                                                                                         │
                                                                               [explode_metric_table：展开实验组指标]
                                                                                         │
                                              INSERT OVERWRITE → dws_sr_data_warehouse_platform_exp_level_nmv_1d
```

### 关键步骤

1. **`user_exp`（临时视图）**：从 A/B 实验分组表读取过去 7 天内，已分配（`is_assignment_log=1`）且在推荐白名单（`is_rcmd_whitelist=1`）的用户实验组列表（`collect_list(exp_group_id)`）。

2. **`dwd_raw`（临时视图）**：从 DWD 层 NMV 表读取原始数据，对 DPM 报表对象（业务线/模块/报告对象/映射分组）进行字符串拼接标准化，生成主路径及 source1、source2 两条归因路径的场景标签字段，同时提取页面类型（`mapped_page_type`）。

3. **`concat_data_raw` / `concat_data`（临时视图）**：将各路径的场景标签用逗号拼接为字符串，再 `split` 转回数组，便于后续 `filter`/`explode` 操作。

4. **`base_table`（临时视图）**：对 `scenario_tags` 数组进行白名单过滤，仅保留符合 DPM 场景标识规则（含 `DA_` 前缀或属于指定模块）的标签，同时规范 `platform`（null 转 `'null'`）和 `is_ads`（强转 string）。

5. **`raw_data`（临时视图）**：通过三路 `UNION ALL` 分别处理主路径（`feature_detail`）、source1（不同于主路径时追加）、source2（不同于主路径及 source1 时追加），按用户+维度粒度预聚合订单数和 GMV。

6. **`dim_user`（临时视图）**：从用户标签表读取 D-1 到 D-8 的 `abs_tier_180d` 分层标签，过滤掉 `abs_tier_180d = 0` 的用户。

7. **`dws_all_tag` / `dws_tag`（临时视图）**：分别构建全场景（`feature_detail='__ALL__'`、`scenario_tag='__ALL__'`）的聚合视图，通过 LEFT JOIN 关联用户分层，`dws_tag` 额外对三路场景标签取并集（`array_union`）并展开。

8. **`filter_tag_data`（临时视图）**：从 `raw_data` 中提取 `target_type`（按 `-` 分割 `feature_detail` 的第三或第二段）。

9. **`cube_table`（临时视图）**：通过三路 `UNION ALL` + `GROUPING SETS` 生成多维预聚合结果，覆盖 `feature_detail`×`is_ads`×`platform`×`scenario_tag`×`abs_tier_180d` 的各维度组合（含 null 占位以支持 `__ALL__` 后续 `coalesce`）。

10. **`uu_data`（临时视图）**：在 `cube_table` 基础上打标 `net_order_uu`（`net_order_cnt > 0` 时为 1，否则为 0）。

11. **`map_data`（临时视图）**：将 `net_order_uu`、`net_order_cnt`、`nmv` 打包为 `metrics` 数组，为实验组 UDF 汇总做准备。

12. **`metric_table`（临时视图）**：与 `user_exp` INNER JOIN，调用自定义聚合函数 `exp_sum` 按实验组 ID 批量累加 `metrics` 数组，同时对各维度 `null` 值 `coalesce` 为 `'__ALL__'`。

13. **`explode_metric_table`（临时视图）**：对 `exp_sum` 输出的实验组指标结构体数组 `LATERAL VIEW EXPLODE`，还原为每实验组一行，提取 `exp_group_id`、`net_order_uu`（cast bigint）、`net_order_cnt`、`nmv`。

14. **`INSERT OVERWRITE`（写目标表）**：按 `exp_type='dim_join'`、`grass_region`、`local_date` 三级分区覆盖写入目标表。

### 注意事项

- **多维预聚合行共存**：`cube_table` 通过 `GROUPING SETS` 生成含 `'__ALL__'` 占位符的多层聚合行，目标表中同一 `local_date` 下存在不同维度粒度的行，查询时必须通过维度字段精确过滤，否则会重复计算指标。
- **单 Writer，多大区串/并行**：ETL 通过模板变量 `${grass_region}` / `${grass_region_without_quote}` 参数化，每次执行写入特定大区分区，`INSERT OVERWRITE PARTITION(exp_type, grass_region, local_date)` 为动态分区覆盖，不同大区之间互不干扰。
- **`exp_sum` 为自定义 UDF**：该函数负责按实验组 ID 聚合 metrics 数组，非标准 Spark SQL 函数，使用时依赖相应 JAR 包注册，直接查询目标表无需关注此依赖。
- **用户标签时间偏移**：`dim_user` 取 D-1 标签（`date_add(local_date, -1)`）与订单日关联，分析时需注意 `abs_tier_180d` 反映的是订单前一天的用户价值分层状态。
- **source1/source2 归因去重**：`raw_data` 在合并三路归因路径时有显式去重逻辑（`source1_feature_detail != feature_detail`，`source2_feature_detail != source1_feature_detail and source2_feature_detail != feature_detail`），避免同一归因路径重复计入。

---

*文档生成时间：2026-05-17*