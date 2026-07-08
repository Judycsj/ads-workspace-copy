<!-- ads-workspace-gdoc-sync: gdoc_id=1fP0FjLFRhJv-JBzuehvGeYyDSPQ6mZrxImYZfVURSg8 gdoc_url=https://docs.google.com/document/d/1fP0FjLFRhJv-JBzuehvGeYyDSPQ6mZrxImYZfVURSg8/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_level_nmv_1d

**分层：** DWS（数据汇总层）
**主键：** `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `target_type` + `local_date` + `grass_region`
**分区：** `grass_region`（站点大区）、`local_date`（本地日期）
**更新频率：** 每日（T+1）
**访问频次：** 13,755 次

---

## 业务描述

本表是搜推数仓（SRDI）平台 × 场景标签粒度的 NMV（Net Merchandise Value，净商品交易额）汇总宽表，覆盖近 30 天滚动窗口数据。

核心业务场景：

- **搜推场景归因分析**：基于 DPM（数据管理平台）的多级 Mapping 体系（业务线 → 模块 → Reporting Object → Feature Group → Algo Tag → 页面类型），将用户下单行为拆解到具体场景标签（`scenario_tag`），支持跨场景的归因对比与贡献度分析。
- **平台 & 广告维度拆解**：支持按平台（`platform`）、是否广告（`is_ads`）对 NMV、订单量、下单 UU 进行多维度分析。
- **多来源流量聚合**：同一笔订单可能来自主触点（`feature_detail`）、来源 1（`source1_feature_detail`）、来源 2（`source2_feature_detail`）等多路归因；ETL 通过 `UNION ALL` 将三路归因去重合并，避免遗漏。
- **Cube 预聚合**：通过 `GROUPING SETS` 预先生成 `platform`、`is_ads` 等维度的全组合（含 `__ALL__` 汇总值），下游可直接过滤使用，无需额外聚合。

适合回答的典型问题：

- 某站点某日、某场景标签下的 NMV 和净订单量是多少？
- 广告流量 vs 自然流量在各页面场景的 NMV 占比？
- 各平台（App / Web / 小程序等）在不同 DPM 模块下的下单 UU 趋势？
- 特定 `feature_detail` 入口的近 30 天 NMV 变化？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 MY、TH、SG 等），分区键，查询时必须指定 |
| `local_date` | date | 本地业务日期，分区键，每日写入，查询时必须指定范围 |

### 维度：场景与入口标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 流量入口特征标识（如 `PageType-Module-TargetType` 格式）；汇总行取 `__ALL__` |
| `scenario_tag` | string | DPM 体系下的场景标签，包含业务线、模块、Reporting Object、Feature Group、Algo Tag、页面类型等多种粒度；汇总行取 `__ALL__` |
| `target_type` | string | 目标类型，从 `feature_detail` 按 `-` 分隔后第 3 段（不存在时取第 2 段）提取；汇总行取 `__ALL__`，无效入口取 `null` |

### 维度：平台与广告标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 用户访问平台（如 App、Web 等）；`null` 原始值存为 `null`，Cube 汇总行取 `__ALL__` |
| `is_ads` | string | 是否广告流量，`true` / `false` 字符串；Cube 汇总行取 `__ALL__` |

### 指标：交易核心指标

| 字段名 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 净商品交易额（Net Merchandise Value），单位与上游一致；对应维度组合下的 `SUM(nmv)` |
| `net_order_cnt` | double | 净订单数，对应维度组合下的 `SUM(net_order_cnt)` |
| `net_order_uu` | bigint | 净下单唯一用户数（去重 UU）；统计条件：`net_order_cnt > 0 AND user_id > 0` 时计 1，否则为 `null`，再求 `SUM` 得到 UU 数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，查询时**必须指定**，否则触发全表扫描，影响性能且可能跨站污染结果。
- **`local_date`**：分区字段，**必须指定日期或日期范围**。表内存储近 30 天滚动数据（上游读取 `[local_date - 30, local_date]`），请勿假设数据覆盖更长时间跨度。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `net_order_uu` | 预聚合去重 UU，跨行 SUM 会重复计数 | 选取唯一维度组合的单行值，或在 `feature_detail = '__ALL__'` 等汇总行读取 |
| `nmv` / `net_order_cnt` | 表中同时存在明细行与 `__ALL__` 汇总行，直接 SUM 会导致重复计算 | 查询时需固定 `platform`、`is_ads`、`feature_detail`、`scenario_tag`、`target_type` 取单一值，避免混合明细行与汇总行 |

### Cube 汇总行使用说明

- 维度值为 `__ALL__` 表示该维度的全量汇总，ETL 通过 `GROUPING SETS` 预生成，**不要**将明细行与 `__ALL__` 行混合聚合。
- 例如，查询某站点全平台 NMV 总量，应使用 `platform = '__ALL__' AND is_ads = '__ALL__'` 过滤，而非对所有 `platform` 值求 SUM。

### 时效性说明

- 本表为 **T+1 日刷新**的每日汇总表（`_1d` 后缀），当日最新数据通常于次日产出。
- 上游窗口为近 **30 天滚动**，单次 ETL 执行会覆盖写入指定分区，历史分区数据以最近一次写入为准。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 搜推平台 NMV 明细宽表，提供用户级订单数据、多路归因字段（`feature_detail` / `source1_*` / `source2_*`）及 DPM Mapping 结果，是本表唯一上游 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform_nmv
    │  (过滤指定 grass_region 和近 30 天日期范围)
    ▼
dwd_raw               ← DPM 字段拼接（业务线/模块/Object/Group/Algo/Page）
    ▼
concat_data_raw       ← 将多个 DPM 字段 concat_ws 为逗号字符串
    ▼
concat_data           ← split 字符串转 array，得 scenario_tags / source1_scenario_tags / source2_scenario_tags
    ▼
base_table            ← 字段规范化（platform null→'null'，is_ads 转 string）
    ▼
raw_data              ← UNION ALL 三路归因（主 + source1 + source2，去重排重）
filter_tag_data       ← 从 feature_detail 提取 target_type
cube_table            ← GROUPING SETS Cube 预聚合（含 __ALL__ 汇总逻辑）
    ▼
INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_platform_scenario_level_nmv_1d
PARTITION (grass_region, local_date)
```

### 关键步骤

1. **`dwd_raw`（Temporary View）**：从上游 DWD 表读取近 30 天数据，对 DPM 各层级字段（`reporting_business_line`、`reporting_module`、`reporting_object`、`feature_group`、`algo_tag`）拼接前缀标识，并从 `feature_detail` 提取 `mapped_page_type`；对 `source1_*`、`source2_*` 归因字段做同样处理。

2. **`concat_data_raw` → `concat_data`（Temporary Views）**：将主归因和两路 source 归因的多个 DPM 标签字段分别用 `concat_ws(',', ...)` 拼成逗号字符串，再 `split` 回 array，得到 `scenario_tags`、`source1_scenario_tags`、`source2_scenario_tags`，供后续 `EXPLODE` 展开。

3. **`base_table`（Temporary View）**：统一字段规范：`platform` 空值填充 `'null'`，`is_ads` 强转 string。

4. **`raw_data`（Temporary View）**：三路 `UNION ALL` 归因合并：
   - 主归因：`feature_detail IS NOT NULL` 且 `scenario_tags` 非空；
   - Source1：`source1_feature_detail` 非空且**不等于** `feature_detail`；
   - Source2：`source2_feature_detail` 非空且**不等于** `feature_detail` 及 `source1_feature_detail`；
   - 每路按 `(platform, is_ads, feature_detail, user_id, scenario_tags, local_date)` 预聚合。

5. **`dws_all_tag` / `dws_tag`（Temporary Views）**：分别生成 `__ALL__` 场景汇总行（全量合并）和基于三路 `array_union` 联合标签的用户级汇总，供 Cube 最终合并使用。

6. **`filter_tag_data`（Temporary View）**：从 `feature_detail` 按 `-` 分隔提取第 3 段（不存在时取第 2 段）作为 `target_type`。

7. **`cube_table`（Temporary View）**：三段 `UNION ALL` + `GROUPING SETS` 组合：
   - 明细归因数据（`raw_data`）× `LATERAL VIEW EXPLODE(scenario_tags)`，按 `is_ads`、`platform` 8 种组合展开；
   - `dws_all_tag` 全量 `__ALL__` 行按 4 种组合展开；
   - `dws_tag` 联合标签行 `LATERAL VIEW EXPLODE(union_scenario_tags)` 按 4 种组合展开。

8. **`INSERT OVERWRITE`（最终写入）**：对 `cube_table` 再次聚合，`null` 维度值替换为 `__ALL__`（对应 Cube 的汇总维度），并计算最终指标：
   - `net_order_uu`：`SUM(IF(net_order_cnt > 0 AND user_id > 0, 1, NULL))` 去重近似 UU；
   - `net_order_cnt`：`SUM(net_order_cnt)`；
   - `nmv`：`SUM(nmv)`；
   - 以 `PARTITION(grass_region, local_date)` 动态分区写入。

### 注意事项

- **单 Writer**：`etl_file_count = 1`，无多 Writer 竞争风险，分区写入安全。
- **动态分区覆盖**：`INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 为动态分区写入，每次执行会覆盖对应 `grass_region` + `local_date` 分区，历史分区不受影响。
- **参数化执行**：SQL 中 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}` 为运行时参数，实际执行时由调度系统注入，`grass_region_without_quote` 用于 Temporary View 命名（避免特殊字符）。
- **重复计算风险**：`raw_data` 中三路 `UNION ALL` 依赖 `source1_feature_detail != feature_detail` 等条件去重，若上游数据三路归因字段异常相同，可能导致指标低估，上游数据质量需保证。
- **NMV 重复归因**：三路归因均含 `SUM(nmv)`，同一笔订单在三个归因入口均计入 NMV，属业务设计（多触点归因），下游使用时需注意跨 `feature_detail` 聚合会存在重复计算。
- **近 30 天窗口**：每次写入覆盖当日分区，但上游读取范围为 `[local_date-30, local_date]`，若中间某日未运行，历史分区数据不会自动补齐。

---

*文档生成时间：2026-05-17*