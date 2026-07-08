<!-- ads-workspace-gdoc-sync: gdoc_id=1J6Wxw3mPOG_Tm1wv2oIPTltwp_3DcCU2eVyq4u5UIgk gdoc_url=https://docs.google.com/document/d/1J6Wxw3mPOG_Tm1wv2oIPTltwp_3DcCU2eVyq4u5UIgk/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_benchmark_1d

**分层**：DWS（数据汇总层）
**主键**：`grass_region` + `local_date` + `exp_type` + `platform` + `feature_detail` + `is_ads` + `exp_group_id` + `scenario_tag` + `login_type`
**分区**：`grass_region`（站点/区域）、`local_date`（业务日期）、`exp_type`（实验类型，枚举值：`traffic` / `assign_log_join` / `dim_join`）
**更新频率**：每日（T+1）
**访问频次**：856

---

## 业务描述

本表为搜索与推荐（SR）数据仓库平台的**实验层级基准指标宽表**，按平台、实验分组、功能详情、场景标签、是否广告、登录状态等维度，聚合每日各核心电商指标（曝光、点击、加购、订单、GMV 等），用于支撑 A/B 实验效果评估与对比分析。

**核心业务场景**：
- 搜索/推荐 A/B 实验的日常效果监控与指标对比（流量实验、分配日志关联实验、维度关联实验）
- 按实验分组（`exp_group_id`）对比不同策略在曝光、点击、转化、GMV 等核心指标上的差异
- 区分登录（`login`）与未登录（`no_login`）用户的实验表现
- 分析广告（`is_ads`）与自然流量的实验效果差异
- 支持跨平台（`platform`）、跨场景（`scenario_tag`）的实验基准数据拉取

**适合回答的问题**：
- 某实验组在某平台上的点击率、转化率、GMV 是否优于对照组？
- 登录与未登录用户在实验中的行为差异如何？
- 某功能特性（`feature_detail`）上线后当日/3日内加购订单及 GMV 变化如何？
- `dim_join` 类型实验与 `traffic` 类型实验的指标平方项（用于方差计算）如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `SG`、`MY` 等，按区域分区 |
| `local_date` | date | 业务日期（本地时间），数据统计日期，按天分区 |
| `exp_type` | string | 实验类型，枚举值：`traffic`（流量实验）、`assign_log_join`（分配日志关联实验）、`dim_join`（维度关联实验） |

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 流量平台，如 Android、iOS、PC 等；已过滤聚合值 `__ALL__` |
| `feature_detail` | string | 功能特性详情标识，标记具体实验特性；`__ALL__` 表示全量汇总（已按规则过滤） |
| `is_ads` | boolean | 是否广告流量，`true` 表示广告，`false` 表示自然流量；源字段为字符串，ETL 中转换为 boolean |
| `exp_group_id` | int | 实验分组 ID，标识 A/B 实验中的对照组或实验组 |
| `scenario_tag` | string | 场景标签，标识搜索或推荐的具体业务场景 |
| `login_type` | string | 用户登录状态，枚举值：`login`（登录用户）、`no_login`（未登录用户）；仅 `traffic` 类型同时包含两类，其余 exp_type 仅含 `login` |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（按 login_type 拆分后的登录/未登录曝光量） |
| `click_cnt` | bigint | 点击次数 |
| `item_imp_cnt` | bigint | 商品曝光次数 |
| `item_click_cnt` | bigint | 商品点击次数 |
| `omni_imp_cnt` | bigint | 全渠道（Omni）曝光次数；仅 `assign_log_join` 和 `dim_join` 类型有值，`traffic` 类型为 NULL |
| `omni_click_cnt` | bigint | 全渠道（Omni）点击次数；仅 `assign_log_join` 和 `dim_join` 类型有值，`traffic` 类型为 NULL |
| `ppv_cnt` | bigint | 页面访问量（Page View 数） |
| `ppv_cnt_exclude_isback` | bigint | 排除返回行为后的页面访问量 |

### 指标：加购与订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数 |
| `order_cnt` | double | 下单数 |
| `atc_same_day_order_cnt` | double | 加购后当日内产生的订单数（ATC 同日订单） |
| `atc_within_3day_order_cnt` | double | 加购后 3 日内产生的订单数 |

### 指标：成交金额（GMV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 总成交金额（Gross Merchandise Value） |
| `atc_same_day_gmv` | double | 加购后当日内产生的成交金额 |
| `atc_within_3day_gmv` | double | 加购后 3 日内产生的成交金额 |
| `pc2_gmv` | double | PC2 口径成交金额（特定归因口径 GMV） |

### 指标：方差计算辅助（平方项）

| 字段 | 类型 | 说明 |
|---|---|---|
| `squared_imp_cnt` | bigint | 曝光数的平方和，用于 A/B 实验方差估计；仅 `dim_join` 类型有值，其余类型为 NULL |
| `squared_click_cnt` | bigint | 点击数的平方和，用于 A/B 实验方差估计；仅 `dim_join` 类型有值，其余类型为 NULL |
| `squared_order_cnt` | bigint | 订单数的平方和，用于 A/B 实验方差估计；仅 `dim_join` 类型有值，其余类型为 NULL |
| `squared_ppv_cnt_exclude_isback` | bigint | 排除返回行为的 PV 平方和，用于 A/B 实验方差估计；仅 `dim_join` 类型有值，其余类型为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定分区字段**，建议同时过滤三个分区列以避免全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
    AND exp_type = 'traffic'
  ```
- `exp_type` 决定数据语义，不同 `exp_type` 分区的数据由不同 ETL 写入，混合查询前需充分理解各类型差异。
- `login_type` 区分登录/未登录用户，汇总全体用户指标时需对 `login_type IN ('login', 'no_login')` 进行 SUM 聚合，且仅适用于 `exp_type = 'traffic'`；`assign_log_join` 与 `dim_join` 分区仅含 `login` 数据。

### 不可直接 SUM 的字段

- `order_cnt`、`gmv`、`atc_same_day_order_cnt`、`atc_within_3day_order_cnt`、`atc_same_day_gmv`、`atc_within_3day_gmv`、`pc2_gmv` 等均为 double 类型的预聚合值，跨 `login_type` 汇总时需明确是否应累加（`traffic` 类型登录+未登录拆分后可 SUM；跨 `exp_type` 绝对不可 SUM）。
- **点击率、转化率等比率指标**：本表不直接存储比率，需自行用分子/分母字段计算，不可对多行比率求平均。
- **平方项字段**（`squared_*`）：用于统计方差计算，不可直接业务解读或求和后做业务指标使用，仅适用于 `exp_type = 'dim_join'` 分区。
- `omni_imp_cnt`、`omni_click_cnt`：在 `exp_type = 'traffic'` 分区下恒为 NULL，查询前需过滤对应 `exp_type`。
- `squared_*` 系列字段：在 `exp_type = 'traffic'` 和 `exp_type = 'assign_log_join'` 分区下恒为 NULL。

### 时效性说明

- 本表为 **T+1 日更新**的每日快照表（`_1d` 后缀），`local_date` 为业务统计日期，查询最新数据需使用前一日日期。
- `atc_within_3day_*` 系列字段为 **3 日窗口归因指标**，统计的是加购后 3 日内的转化，当日数据因归因窗口未关闭可能不完整，建议延迟 3 天后查询此类字段。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d` | 三个 ETL 的统一数据源，提供平台级实验基础指标（含登录/全量分层原始度量值），按 `exp_type`、`grass_region`、`local_date` 分区读取 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d
    │
    ├─[ETL 1] exp_type='traffic'         → 拆分 login / no_login（差值法），omni/squared 字段置 NULL
    ├─[ETL 2] exp_type='assign_log_join' → 仅取 login 数据，填充 omni 字段，squared 字段置 NULL
    └─[ETL 3] exp_type='dim_join'        → 仅取 login 数据，填充 omni 与 squared 全部字段
                                                    ↓
        srdi_mart.dws_sr_data_warehouse_platform_exp_level_benchmark_1d
```

### 关键步骤

**ETL 1（`exp_type='traffic'`）**
- 从上游表过滤 `exp_type = 'traffic'`，排除 `is_ads = '__ALL__'`、`platform = '__ALL__'` 的汇总行。
- 按维度过滤规则（`feature_detail` 与 `target_type`、`scenario_tag` 的组合条件）精细控制写入粒度，避免重复聚合。
- 执行 `UNION ALL`：
  - 第一分支：直接取 `*_login_cnt` / `*_login` 字段，`login_type = 'login'`。
  - 第二分支：用全量字段减去登录字段（差值法）得到未登录量，`login_type = 'no_login'`。
- `omni_imp_cnt`、`omni_click_cnt` 及全部 `squared_*` 字段置为 NULL。
- `INSERT OVERWRITE` 写入目标表 `exp_type = 'traffic'` 分区。

**ETL 2（`exp_type='assign_log_join'`）**
- 从上游表过滤 `exp_type = 'assign_log_join'`，维度过滤规则与 ETL 1 相同。
- 仅取 `*_login_cnt` / `*_login` 字段，`login_type` 固定为 `'login'`，无未登录拆分。
- 填充 `omni_imp_cnt`、`omni_click_cnt` 字段（来自上游同名字段）。
- 全部 `squared_*` 字段置为 NULL。
- `INSERT OVERWRITE` 写入目标表 `exp_type = 'assign_log_join'` 分区。

**ETL 3（`exp_type='dim_join'`）**
- 从上游表过滤 `exp_type = 'dim_join'`，维度过滤规则与 ETL 1 相同。
- 仅取 `*_login_cnt` / `*_login` 字段，`login_type` 固定为 `'login'`，无未登录拆分。
- 填充 `omni_imp_cnt`、`omni_click_cnt` 及全部 `squared_*` 字段（均来自上游同名字段）。
- `INSERT OVERWRITE` 写入目标表 `exp_type = 'dim_join'` 分区。

### 注意事项

1. **Multi-writer 并发写入**：三个 ETL 文件分别负责不同 `exp_type` 分区，理论上可并行执行，但均使用 `INSERT OVERWRITE` 写特定分区，需确保调度框架在分区级别做隔离，避免同一分区被并发覆盖。
2. **`traffic` 类型特有 no_login 数据**：仅 `exp_type = 'traffic'` 分区存在 `login_type = 'no_login'` 的行，其他分区不含未登录数据，跨类型汇总时须注意口径对齐。
3. **NULL 字段随 `exp_type` 变化**：`omni_*` 在 `traffic` 分区为 NULL；`squared_*` 在 `traffic` 和 `assign_log_join` 分区均为 NULL，查询时勿对这些字段跨分区聚合。
4. **维度过滤组合逻辑**：上游表按维度组合预聚合了多个粒度，ETL 通过 `feature_detail`、`target_type`、`scenario_tag` 的三段式条件过滤，保证写入本表的数据粒度不重叠，下游直接使用本表无需再次去重。
5. **`is_ads` 类型转换**：上游字段为字符串 `'true'`/`'false'`，ETL 中使用 `if(is_ads = 'true', true, false)` 转换为 boolean，下游查询需使用 boolean 类型过滤（如 `is_ads = true`）。

---

*文档生成时间：2026-05-17*