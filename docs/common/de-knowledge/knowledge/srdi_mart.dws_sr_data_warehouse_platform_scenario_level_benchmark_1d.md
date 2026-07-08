<!-- ads-workspace-gdoc-sync: gdoc_id=1j3wwvMqtRdlMf0s0j-0veqeSrknbhGwnXCv2CtVfIFo gdoc_url=https://docs.google.com/document/d/1j3wwvMqtRdlMf0s0j-0veqeSrknbhGwnXCv2CtVfIFo/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_level_benchmark_1d

**分层：** DWS（数据仓库服务层）
**主键：** `grass_region` + `local_date` + `platform` + `is_ads` + `login_type` + `feature_detail` + `scenario_tag`
**分区：** `grass_region`（站点大区）、`local_date`（业务日期）
**更新频率：** 每日（T+1 全量覆盖写入）
**访问频次：** 10,240 次

---

## 业务描述

本表是搜索与推荐（SR）数据仓库平台的**场景级别基准汇总宽表**，以「大区 × 日期 × 平台 × 广告标识 × 登录状态 × 流量来源 × 场景标签」为粒度，汇总核心漏斗行为指标与交易转化指标。

**核心业务场景：**
- 各平台（iOS / Android / Web 等）搜推流量的每日健康度基准监控
- 广告流量（`is_ads=true`）与自然流量（`is_ads=false`）的分渠道效果对比
- 登录 / 未登录用户的行为差异分析
- 场景标签（`scenario_tag`）维度下的漏斗拆解（曝光 → 点击 → 加购 → 下单 → GMV）
- ATC（加购）当日及 3 日内的延迟转化追踪
- 多来源（`feature_detail`、`source1_feature_detail`、`source2_feature_detail`）归因聚合

**适合回答的典型问题：**
- 某站点某天各平台的搜推 CTR / 加购率 / 转化率是多少？
- 广告流量与自然流量在各场景标签下的 GMV 贡献差异？
- 加购行为在当天和 3 天内分别带来了多少订单和 GMV？
- 登录用户与未登录用户的曝光点击行为对比？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识，如 `SG`、`MY`、`TH` 等，用于多地区数据分区隔离 |
| `local_date` | date | 业务本地日期（T 日），每日分区 |

### 维度：流量来源与场景标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 流量来源平台，如 `iOS`、`Android`、`Web` 等 |
| `is_ads` | boolean | 是否为广告流量；`true` 表示广告，`false` 表示自然流量；原始字段为 `null` 时默认取 `false` |
| `login_type` | string | 用户登录状态；`user_id > 0` 时为 `login`，否则为 `no_login` |
| `feature_detail` | string | 流量来源 feature 标识；`__ALL__` 表示全量汇总；支持主来源（`feature_detail`）、一级来源（`source1_feature_detail`）、二级来源（`source2_feature_detail`）的多归因展开 |
| `scenario_tag` | string | 场景标签，通过对主场景标签（`scenario_tags`）及 source1/source2 场景标签取并集后 EXPLODE 展开；`__ALL__` 表示全量汇总，空字符串表示未命中任何场景标签 |

### 指标：曝光与点击行为

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 总曝光次数（含商品与非商品曝光） |
| `item_imp_cnt` | bigint | 商品曝光次数；仅统计 `target_type = 'item'` 的曝光，由 `feature_detail` 第三段（或第二段）决定 target_type |
| `click_cnt` | bigint | 总点击次数 |
| `item_click_cnt` | bigint | 商品点击次数；仅统计 `target_type = 'item'` 的点击 |
| `ppv_cnt` | bigint | 商品详情页（PDP）浏览次数 |
| `ppv_cnt_exclude_isback` | bigint | 排除回退（is_back）行为后的 PDP 浏览次数 |
| `view_cnt` | bigint | 页面浏览次数（view 行为计数） |

### 指标：加购行为

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数（Add-to-Cart） |

### 指标：订单与 GMV

| 字段名 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单量（当日直接成单） |
| `gmv` | double | 当日直接成交 GMV |
| `pc2_gmv` | double | PC2 口径 GMV（特定归因口径下的 GMV，通常为 post-click 二阶段归因） |

### 指标：ATC 延迟转化

| 字段名 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | 加购当日内完成下单的订单数 |
| `atc_same_day_gmv` | double | 加购当日内完成下单对应的 GMV |
| `atc_within_3day_order_cnt` | double | 加购 3 日内完成下单的订单数（含当日） |
| `atc_within_3day_gmv` | double | 加购 3 日内完成下单对应的 GMV（含当日） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必填分区键，查询时务必指定具体站点大区，否则将触发全分区扫描，影响性能。
- **`local_date`**：必填分区键，建议明确指定日期范围，避免大范围扫描。

```sql
-- 推荐写法示例
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

- **`atc_same_day_order_cnt`、`atc_within_3day_order_cnt`、`atc_same_day_gmv`、`atc_within_3day_gmv`**：这些 ATC 延迟转化指标在多个维度（`feature_detail`、`scenario_tag`）间存在多归因展开，跨维度 SUM 会导致重复计算。跨维度对比时应选取特定 `feature_detail` 或使用 `__ALL__` 汇总行，不可对不同 `scenario_tag` 或 `feature_detail` 的行做无约束求和。
- **`order_cnt`、`gmv`、`pc2_gmv`**：同理，由于 `scenario_tag` 通过 EXPLODE 展开（一条记录可能属于多个 scenario_tag），跨 `scenario_tag` 求和会造成重复。若需全量汇总，应使用 `scenario_tag = '__ALL__'` 且 `feature_detail = '__ALL__'` 的行。
- **衍生比率指标**（如 CTR = `click_cnt / imp_cnt`、CVR 等）：不在本表存储，需在查询层自行计算，不可直接聚合。

### `scenario_tag` 与 `feature_detail` 的多值展开说明

- `scenario_tag = '__ALL__'` 且 `feature_detail = '__ALL__'`：全量汇总行，适合看整体基准数据。
- `scenario_tag` 为具体值：该记录已通过 EXPLODE 展开，一个用户行为事件可能同时命中多个 scenario_tag，各 tag 行之间存在重叠，**不可跨 scenario_tag 求和**。
- `feature_detail` 支持主来源及 source1、source2 的多归因展开，跨 feature_detail 汇总同样存在重叠风险。

### 时效性说明

- 本表为 **`_1d` 后缀**的每日快照表，数据为 T 日全量覆盖（`INSERT OVERWRITE PARTITION`），通常在 T+1 产出。
- 不包含近 N 天滚动窗口，若需要趋势分析需自行跨日期聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 核心上游明细宽表，提供用户 × 商品级别的行为事件数据（曝光、点击、加购、下单、PDP 浏览等），以及 feature_detail、scenario_tags、source1/source2 归因信息 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_platform_user_item
    ↓ 过滤 grass_region、local_date、operation IN('view','impression','click','ppv','cart','order')
    ↓ 按 platform / is_ads / login_type / feature_detail / scenario_tags / source 维度聚合
[CACHE] raw_data（带 union_scenario_tags）
    ↓ 5路 UNION ALL 多粒度展开（全量汇总行 + scenario_tag 展开 + source归因展开）
[CACHE] base_table（中间聚合结果）
    ↓ 最终按 platform / is_ads / login_type / feature_detail / scenario_tag 聚合
INSERT OVERWRITE → srdi_mart.dws_sr_data_warehouse_platform_scenario_level_benchmark_1d
```

### 关键步骤

**Step 1 — `raw_data` Temporary View（CACHE TABLE）**

从上游 DWM 表过滤当日当区数据，按 `platform`、`is_ads`（null 默认 false）、`login_type`（user_id 判断）、`feature_detail`、`source1_feature_detail`、`source2_feature_detail`、`target_type`（feature_detail 按 `-` 分割第3/2段）、`scenario_tags`、`source1_scenario_tags`、`source2_scenario_tags` 分组，预聚合各行为指标 SUM，并构建 `union_scenario_tags`（三路 scenario_tags 取并集）。结果缓存至内存+磁盘（`MEMORY_AND_DISK_SER`）。

**Step 2 — `base_table` Temporary View（CACHE TABLE，5路 UNION ALL）**

基于 `raw_data` 构建多粒度中间结果，5路分支含义如下：

| 分支 | feature_detail | scenario_tag 来源 | 说明 |
|---|---|---|---|
| 1 | `__ALL__` | `__ALL__` | 全维度汇总行（无场景/来源细分） |
| 2 | `__ALL__` | EXPLODE(`union_scenario_tags`) | 仅按场景标签细分，来源汇总 |
| 3 | `feature_detail`（主归因） | EXPLODE(`scenario_tags`) | 主来源 × 主场景标签 |
| 4 | `source1_feature_detail` | EXPLODE(`source1_scenario_tags`) | source1 归因展开（排除与主来源相同的情况） |
| 5 | `source2_feature_detail` | EXPLODE(`source2_scenario_tags`) | source2 归因展开（排除与主来源、source1 相同的情况） |

每路均输出 `item_imp_cnt`（`target_type = 'item'` 的曝光）和 `item_click_cnt`（`target_type = 'item'` 的点击）。结果缓存至内存+磁盘。

**Step 3 — INSERT OVERWRITE 写目标表**

从 `base_table` 按 `platform`、`is_ads`、`login_type`、`feature_detail`、`scenario_tag` 再次聚合（合并因多路 UNION 可能产生的重复 key），以 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 全量写入目标表。

### 注意事项

- **单 writer，无 multi-writer 风险**：该表仅有一个 ETL 文件写入，无多文件并发写入问题。
- **分区覆盖写入**：每次执行为 `INSERT OVERWRITE` 指定分区，同一 `grass_region` + `local_date` 的历史数据会被完全替换，回溯补数安全。
- **scenario_tag 与 feature_detail 的重复计数设计**：多路 UNION ALL 是有意为之的多归因设计，目的是支持不同下钻维度的独立聚合查询，查询时必须按业务语义选取合适的维度组合，避免双重计数。
- **空值处理**：`is_ads` 原始为 null 时统一映射为 `false`；`scenario_tag` 原始为 null 时映射为空字符串 `''`；`source1_feature_detail`、`source2_feature_detail` 为 null 时对应分支会被 `WHERE IS NOT NULL` 过滤，不会产生空行。
- **CACHE TABLE 依赖**：`base_table` 依赖 `raw_data` 缓存，两者均使用带大区参数的动态命名（`_${grass_region_without_quote}` 后缀），多地区并发执行时需确保 Spark Session 隔离，避免缓存命名冲突。

---

*文档生成时间：2026-05-17*