<!-- ads-workspace-gdoc-sync: gdoc_id=1mlPhZ4A41JZN7a-3QmJcFmnsktHZvEE5CO8n6fE0qQk gdoc_url=https://docs.google.com/document/d/1mlPhZ4A41JZN7a-3QmJcFmnsktHZvEE5CO8n6fE0qQk/edit -->

# srdi_mart.dws_sr_data_warehouse_search_exp_level_other_scenario_metrics_1d

**分层：** dws_search
**主键：** `exp_group_id` + `scenario_tag` + `platform` + `is_ads` + `grass_region` + `local_date`
**分区：** `grass_region`（站点）/ `local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次 / 访问频次：** 1507

---

## 业务描述

本表为搜推数仓（SRDI）**实验组级别 × 非搜索核心场景（Other Scenario）** 的每日汇总指标宽表，聚焦于 Discovery Ads（DA）系列推荐场景及搜索联合曝光场景下的实验效果评估。

**核心业务场景：**
- 以 A/B 实验分组（`exp_group_id`）为核心维度，统计各实验组在不同推荐场景（Daily Discover、YMAL 系列、Cart Recommendation 等）下的用户行为指标。
- 支持按站点（`grass_region`）、平台（`platform`）、广告标识（`is_ads`）进行多维度切分分析。
- 提供去除极端值（99.5% 分位）的稳健指标，用于降低异常用户对实验结论的干扰。

**适合回答的问题：**
- 某实验组在 DA_Daily Discover 场景下，昨日的曝光 UV、点击 UV、GMV 分别是多少？
- 剔除 99.5% 异常用户后，各实验组的 GMV（`gmv_995`）、订单数（`order_cnt_995`）是否有显著差异？
- 各场景下广告与自然流量（`is_ads`）的转化效果对比如何？
- iOS 与 Android 平台在推荐场景下的 PDP 访问（`ppv_cnt_exclude_isback`）差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/国家地区标识，如 `ID`、`TH`、`MY` 等，所有查询必须指定此分区 |
| `local_date` | date | 业务日期（本地时间），格式 `yyyy-MM-dd`，所有查询必须指定此分区 |

---

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，来源于实验白名单用户分配日志；`__ALL__` 场景汇总时为全量 |
| `scenario_tag` | string | 推荐场景标签。`'dpm module Global Search business line Search'` 被规范化为 `'Search'`；`'__ALL__'` 表示直接流量全场景聚合。枚举值包括：`Search`、`DA_Daily Discover`、`DA_You May Also Like`、`DA_Cart_Unify`、`DA_Buy Again (Me Page)`、`DA_Cart Recommendation`、`DA_odp_ymal-order_detail`、`DA_Order Successful Recommendation`、`DA_mpp_ymal-order_list`、`DA_Me YMAL`、`DA_Shop YMAL`、`DA_Shop_Unify`、`dpm_HP_DD + dpm_Global Search`、`dpm_PDP_YMAL + dpm_Global Search`、`dpm_PP_YMAL + dpm_Global Search`、`__ALL__` |
| `platform` | string | 客户端平台，如 `iOS`、`Android` 等；`__ALL__` 表示跨平台聚合；来源缺失时填充为 `unknown` |
| `is_ads` | string | 是否广告流量，字符串类型，取值 `'true'`/`'false'`；`'__ALL__'` 表示广告+自然流量合并；来源缺失时填充为 `'false'` |

---

### 指标：曝光与点击（原始）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 实验组用户在该场景下的总曝光次数（含异常用户） |
| `imp_uu` | bigint | 有效曝光用户数（UV），统计 `imp_cnt > 0` 且 `user_id > 0` 的去重用户数 |
| `click_cnt` | bigint | 实验组用户在该场景下的总点击次数 |
| `click_uu` | bigint | 有效点击用户数（UV），统计 `click_cnt > 0` 且 `user_id > 0` 的去重用户数 |
| `item_imp_cnt` | bigint | 商品维度曝光次数，仅统计 `target_type = 'item'` 的曝光 |
| `item_click_cnt` | bigint | 商品维度点击次数，仅统计 `target_type = 'item'` 的点击 |

---

### 指标：页面访问

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt_exclude_isback` | bigint | PDP（商品详情页）访问次数，已排除 isback（返回行为）的干扰，来源于 `ppv_cnt` 字段 |
| `ppv_uu` | bigint | 有效 PDP 访问用户数（UV），统计 `ppv_cnt > 0` 且 `user_id > 0` 的去重用户数 |

---

### 指标：购物车与订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | double | 实验组用户在该场景下的加购次数 |
| `atc_uu` | bigint | 有效加购用户数（UV），即 `cart_uu`，统计 `cart_cnt > 0` 且 `user_id > 0` 的去重用户数 |
| `order_cnt` | double | 实验组用户在该场景下的下单次数（含异常用户） |
| `order_uu` | bigint | 有效下单用户数（UV），统计 `order_cnt > 0` 且 `user_id > 0` 的去重用户数 |

---

### 指标：GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 实验组用户在该场景下的总 GMV（含异常用户） |

---

### 指标：去除极端值（99.5% 分位稳健指标）

> 以下指标均基于用户人均 GMV（ABS）的 99.5% 分位阈值（`abs_995`）过滤，仅保留 `abs <= abs_995` 的正常用户，用于消除极端值对实验结论的干扰。阈值来源于 `srdi_mart.ads_rcmd_platform_scenario_level_outlier_di`。

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu_995` | bigint | 剔除极端用户后的曝光 UV，`COUNT DISTINCT` 计算，**不可直接 SUM** |
| `imp_cnt_995` | bigint | 剔除极端用户后的曝光次数 |
| `order_cnt_995` | double | 剔除极端用户后的订单数 |
| `gmv_995` | double | 剔除极端用户后的 GMV |
| `pc2_gmv_995` | double | 剔除极端用户后的 PC2（二次确认）GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则会触发全表扫描，造成性能问题及资源浪费。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```
- 若需分析特定场景，应同时过滤 `scenario_tag`，避免聚合语义混乱（`__ALL__` 行与明细行会重叠计数）。
- 需区分广告与自然流量时，务必过滤 `is_ads`；`is_ads = '__ALL__'` 与具体取值行存在包含关系，不可同时聚合。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`atc_uu`、`order_uu` | 去重 UV 指标，跨维度直接 SUM 会导致用户重复计数 |
| `imp_uu_995` | `COUNT DISTINCT` 派生指标，跨维度直接 SUM 同样存在重复计数风险 |
| `scenario_tag = '__ALL__'` 的所有行 | 已是全场景预聚合结果，与明细场景行叠加会导致双重计数 |
| `platform = '__ALL__'` / `is_ads = '__ALL__'` 的行 | GROUPING SETS 预聚合产生，与明细维度行不可混合 SUM |

### 时效性说明

- 本表为 **天级（1d）** 快照表，每日 T+1 全量覆盖写入（`INSERT OVERWRITE PARTITION`）。
- 数据反映的是指定 `local_date` 当天的累计行为，无滚动窗口语义。
- 若需多日趋势，需按 `local_date` 遍历查询后在业务层汇总（注意 UV 类字段跨日不可直接相加）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维表，筛选实验白名单用户（`is_assignment_log = 1 AND is_search_whitelist = 1`）及其对应的 `exp_group_id` |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 用户级别平台 × 场景行为基准表，提供各场景的曝光、点击、PDP、加购、订单、GMV 等原始指标 |
| `srdi_mart.ads_rcmd_platform_scenario_level_outlier_di` | 推荐场景级别异常用户阈值表，提供各场景 99.5% 分位的人均 GMV（ABS）阈值，用于极端用户过滤 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group          ─────────────────────────────────┐
                                                                                   ▼
dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d                 res_data
  → (场景过滤 + UNION ALL 直接流量) → dws_user_benchmark                        ↓
  → EXPLODE(dedup_scenario_tags)   → tracking                     INSERT OVERWRITE
  → GROUPING SETS 多维聚合          → cube_table                   目标表
  → LEFT JOIN abs_995阈值           → cube_table_with_abs
ads_rcmd_platform_scenario_level_outlier_di → outlier_agg ─────────┘
```

### 关键步骤

**Step 1 — `selected_user_exps`（临时视图）**
从实验用户分组维表中筛选指定站点、日期的实验白名单用户（`is_assignment_log = 1 AND is_search_whitelist = 1`），获取 `user_id` → `exp_group_id` 的映射关系。

**Step 2 — `dws_user_benchmark`（临时视图）**
从用户行为基准表中，以 `UNION ALL` 方式生成两类数据：
- **场景明细行**：过滤 `dedup_scenario_tags` 与目标场景列表有交集的用户，保留原有 `dedup_scenario_tags`（取交集），按 `is_ads`、`platform`、`user_id`、`dedup_scenario_tags` 聚合指标。
- **全场景汇总行**（`__ALL__`）：仅对 `is_direct = true` 的用户，将 `dedup_scenario_tags` 固定为 `ARRAY('__ALL__')`，做跨场景汇总。

**Step 3 — `tracking`（临时视图）**
对 `dws_user_benchmark` 的 `dedup_scenario_tags` 数组执行 `LATERAL VIEW EXPLODE`，展开为单行单场景记录，同时将 `'dpm module Global Search business line Search'` 规范化为 `'Search'`，并按 `is_ads`、`platform`、`user_id`、`scenario_tag` 聚合指标。

**Step 4 — `cube_table`（临时视图）**
使用 `GROUPING SETS` 对 `is_ads` 和 `platform` 做多维预聚合（4 种组合），生成含 `__ALL__` 的多维 Cube，并计算用户人均 GMV（`abs = gmv / order_cnt`）用于后续极端值判定。

**Step 5 — `outlier_agg`（临时视图）**
从异常用户阈值表中读取各场景、各 `is_ads` 维度的 99.5% 分位 ABS 阈值（`abs_995`），并将 `feature_group` 名称映射为目标表使用的 `scenario_tag` 枚举值。

**Step 6 — `cube_table_with_abs`（临时视图）**
将 `cube_table` 与 `outlier_agg` 进行 `LEFT JOIN`（关联条件：`scenario_tag`、`is_ads`，且 `platform = '__ALL__'`），为每条用户记录打上 `below_995` 标记（`abs <= abs_995` 则为 1）。

**Step 7 — `res_data`（临时视图）**
将 `cube_table_with_abs` 与实验用户映射（`selected_user_exps`）做 `INNER JOIN`，只保留实验白名单用户，并按 `exp_group_id`、`is_ads`、`platform`、`scenario_tag` 分组，聚合输出所有 UV 类、次数类及 99.5% 稳健指标。

**Step 8 — INSERT OVERWRITE（写目标表）**
从 `res_data` 中按列映射写入目标表（注意 `ppv_cnt` → `ppv_cnt_exclude_isback`，`cart_uu` → `atc_uu`），使用 `REPARTITION(100)` 控制输出文件数，按 `grass_region` + `local_date` 分区覆盖写入。

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表仅由一个 ETL 文件写入，不存在多 Writer 并发写同一分区的问题。
- **`INSERT OVERWRITE PARTITION`**：每次运行会完全覆盖指定 `grass_region` + `local_date` 分区的数据，重跑安全，但注意不要误触发跨分区写入。
- **`GROUPING SETS` 产生 `__ALL__` 行**：`platform`、`is_ads` 值为 `__ALL__` 的行是预聚合产物，查询时若不过滤将导致与明细行重复计数。
- **`abs_995` 阈值关联维度**：异常值阈值仅在 `platform = '__ALL__'` 粒度上存在，`LEFT JOIN` 时固定以全平台维度关联，因此各平台明细行的 `below_995` 标记与全平台口径一致，非平台独立计算。
- **`__ALL__` 场景的直接流量口径**：`dedup_scenario_tags = ARRAY('__ALL__')` 仅来自 `is_direct = true` 的用户，与场景明细行的用户范围不同，跨场景对比时需注意口径差异。
- **`imp_uu_995` 为 `COUNT DISTINCT`**：该字段在 `res_data` 中通过 `COUNT(DISTINCT IF(below_995 = 1 AND imp_cnt > 0, user_id, NULL))` 计算，是真实去重 UV，跨分组聚合时不可直接 SUM。

---

*文档生成时间：2026-05-17*