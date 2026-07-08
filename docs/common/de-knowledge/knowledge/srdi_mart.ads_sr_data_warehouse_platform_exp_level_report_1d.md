<!-- ads-workspace-gdoc-sync: gdoc_id=1FWNChKF7KMGlF8JdgYt-QhwIOz1rxXYKiggCeK0Q2s4 gdoc_url=https://docs.google.com/document/d/1FWNChKF7KMGlF8JdgYt-QhwIOz1rxXYKiggCeK0Q2s4/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_exp_level_report_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region`, `local_date`, `group_id`, `report_business_line`, `report_module`, `report_object`, `platform`, `is_ads`
**分区：** `grass_region`（大区）/ `local_date`（业务日期）
**更新频率：** 每日一次（T+1 全量覆盖写入）
**访问频次：** 538

---

## 业务描述

本表为搜推数仓平台实验（A/B Test）维度的**每日报表层汇总表**，面向业务分析师提供各实验分组在不同平台、业务线、模块、展示位对象下的核心电商漏斗指标（曝光→点击→加购→下单→GMV）。

**核心业务场景：**
- 查看某个 A/B 实验分组（`group_id`）在特定日期、特定大区、特定 platform 下的整体漏斗表现；
- 对比广告流量（`is_ads`）与自然流量在各实验分组的差异；
- 按业务线（Homepage、Feed 等）、模块（Daily Discover 等）、对象（item card 等）下钻分析实验效果；
- 支持 Omni（跨端）归因指标及方差估计（squared_*）用于 A/B 检验显著性计算。

**适合回答的问题：**
- 某实验组在某日 iOS 平台上的 GMV 和订单量是多少？
- 各实验组在 Homepage 业务线的点击率和加购率差异？
- 某实验组相比对照组在某大区的 ppv 是否显著提升（结合 squared_* 字段）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY 等；分区键，查询时必须指定 |
| `local_date` | date | 业务本地日期（当地时区）；分区键，查询时必须指定 |

### 维度：实验与分组标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `group_id` | int | A/B 实验分组 ID（`exp_group_id`），标识实验的对照组或实验组 |

### 维度：报表场景层级

| 字段 | 类型 | 说明 |
|---|---|---|
| `report_business_line` | string | 报表业务线，如 `Homepage`；从 `scenario_tag` 中解析 `business line` 段；`__ALL__` 表示全业务线汇总 |
| `report_module` | string | 报表模块，如 `Daily Discover`；从 `scenario_tag` 中解析 `module` 段；含 `__ALL__` 汇总值 |
| `report_object` | string | 报表展示位对象，如 `item card`；从 `scenario_tag` 中解析 `object` 段；含 `__ALL__` 汇总值 |

### 维度：流量属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，如 iOS、Android 等；含 `__ALL__` 汇总值 |
| `is_ads` | string | 是否广告流量标识；含 `__ALL__` 汇总值 |

### 指标：曝光与点击（计数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（页面级） |
| `imp_uu` | bigint | 曝光去重用户数（UV） |
| `click_cnt` | bigint | 点击次数（页面级） |
| `click_uu` | bigint | 点击去重用户数（UV） |
| `item_imp_cnt` | bigint | 商品卡片曝光次数 |
| `item_click_cnt` | bigint | 商品卡片点击次数 |

### 指标：页面浏览（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 页面浏览次数（已排除 is_back 回退行为），源字段为 `ppv_cnt_exclude_isback` |
| `ppv_uu` | bigint | 页面浏览去重用户数（UV） |

### 指标：转化漏斗（加购/下单/GMV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数 |
| `cart_uu` | bigint | 加购去重用户数（UV） |
| `order_cnt` | double | 下单次数（支持小数，可能为归因加权值） |
| `order_uu` | bigint | 下单去重用户数（UV） |
| `gmv` | double | 成交总金额（Gross Merchandise Value） |
| `pc2_gmv` | double | PC2 口径 GMV（特定归因或结算口径，具体含义以业务定义为准） |

### 指标：Omni 跨端归因

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_imp_cnt` | bigint | 跨端归因曝光次数 |
| `omni_click_cnt` | bigint | 跨端归因点击次数 |

### 指标：方差估计（用于 A/B 显著性检验）

| 字段 | 类型 | 说明 |
|---|---|---|
| `squared_imp_cnt` | bigint | 曝光次数的平方和，用于 Delta 方法方差估计 |
| `squared_click_cnt` | bigint | 点击次数的平方和，用于 Delta 方法方差估计 |
| `squared_ppv_cnt` | bigint | PPV 次数的平方和（已排除 is_back），源字段为 `squared_ppv_cnt_exclude_isback` |
| `squared_order_cnt` | bigint | 下单次数的平方和，用于 Delta 方法方差估计 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：每次查询均须在 WHERE 子句中明确 `grass_region` 和 `local_date`，否则触发全表扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-16'
  ```

### 汇总维度说明（`__ALL__` 语义）

- `platform`、`is_ads`、`report_module`、`report_object` 均含 `__ALL__` 汇总行，代表该维度的全量聚合结果。
- **对同一 `group_id` + `local_date` + `grass_region` 跨维度 SUM 时，须先过滤掉 `__ALL__` 行**，避免重复计算：
  ```sql
  WHERE report_module != '__ALL__'
    AND report_object != '__ALL__'
    AND platform != '__ALL__'
    AND is_ads != '__ALL__'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu` | 去重 UV，跨分组/日期直接 SUM 会重复计数 |
| `squared_*` 系列 | 方差估计辅助字段，须结合统计检验公式使用，不可直接累加作为业务量指标 |
| `gmv`、`pc2_gmv` | 跨 `__ALL__` 维度值 SUM 时会重复；需确认过滤条件后再汇总 |

### 时效性说明

- 本表后缀 `_1d`，为**每日快照表**，每天 T+1 全量覆盖写入当日分区，不保留历史分区变更记录。
- 如需跨日期趋势分析，需在查询中枚举或范围过滤 `local_date`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d` | 提供实验分组维度的平台级基础指标，经场景标签过滤与字段解析后写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d
    │
    │  过滤条件：
    │    target_type = '__ALL__'
    │    feature_detail = '__ALL__'
    │    exp_type = 'assign_log_join'
    │    scenario_tag IN (dpm business line % / dpm reporting object % / dpm module % / __ALL__)
    │
    ▼  字段解析：
    │    scenario_tag → report_business_line / report_module / report_object
    │
    ▼
srdi_mart.ads_sr_data_warehouse_platform_exp_level_report_1d
    PARTITION (grass_region = ${grass_region}, local_date = ${local_date})
```

### 关键步骤

1. **分区过滤**：从 DWS 层基础指标表按 `grass_region`、`local_date` 过滤当日分区数据。
2. **场景维度过滤**：进一步限定 `target_type = '__ALL__'`、`feature_detail = '__ALL__'`、`exp_type = 'assign_log_join'`，仅保留 assign log join 口径的全量场景聚合行；并通过 `scenario_tag` 的 `LIKE` 条件保留 DPM 报表层级标签（business line / module / reporting object）及全量汇总（`__ALL__`）。
3. **场景标签解析**：使用 `CASE WHEN` + `locate` / `substring` 逻辑从 `scenario_tag` 字符串中依次提取 `report_business_line`、`report_module`、`report_object` 三级层级；当 `scenario_tag = '__ALL__'` 或粒度不够细时，对应字段填充 `'__ALL__'`。
4. **字段别名映射**：`ppv_cnt_exclude_isback → ppv_cnt`，`squared_ppv_cnt_exclude_isback → squared_ppv_cnt`，其余字段直接透传。
5. **目标写入**：`INSERT OVERWRITE` 分区写入，每次运行覆盖指定 `grass_region` + `local_date` 分区。

### 注意事项

- **单 Writer**：本表仅一个 ETL 文件写入，无 multi-writer 竞争风险。
- **INSERT OVERWRITE 分区覆盖**：每次按参数 `${grass_region}` + `${local_date}` 覆盖单个分区，重跑幂等安全，但需保证调度参数传入正确的日期与大区。
- **场景标签字符串解析脆弱性**：`report_business_line`、`report_module`、`report_object` 均依赖 `scenario_tag` 的固定格式（`dpm object ... module ... business line ...`），若上游 `scenario_tag` 格式变更，解析结果将出现空值或截断，需关注上游 DWS 层字段格式的一致性。
- **`ppv_cnt` 语义**：本表 `ppv_cnt` 已排除回退（is_back）行为，与部分其他表的 raw ppv_cnt 口径不同，跨表对比时需注意。

---

*文档生成时间：2026-05-17*